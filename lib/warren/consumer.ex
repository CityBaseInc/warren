defmodule Warren.Consumer do

  @moduledoc """
  The `Consumer` module implements a `GenServer` for declaring, registrering, subscribing to and consuming from a single
  exchange <> queue binding in RabbitMQ. The configuration parameters supplied to it define subscription behavior
  """

  use GenServer
  use AMQP

  require Logger

  alias Warren.Dsl.Route
  alias Warren.Controller
  alias AMQP.Channel

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, [])
  end
#
  def init({config, route}) do
    rabbitmq_connect(config, route)
  end

#  @doc """
#  Flags the message as processed
#  """
#  @spec ack(pid, String.t) :: :ok
#  def ack(pid, tag) do
#    GenServer.cast(pid, {:ack, tag})
#  end
#
#  @doc """
#  Flags a message as unprocessed, and whether the failure was permanent
#  """
#  @spec nack(pid, String.t, boolean) :: :ok
#  def nack(pid, tag, permanent) do
#    GenServer.cast(pid, {:ack, tag})
#  end
#
#  def handle_cast({:ack, tag}, %{chan: chan}) do
#    Basic.ack(chan, tag)
#  end
#
#  def handle_cast({:nack, tag, permanent}, %{chan: chan}) do
#    Basic.reject(chan, tag, permanent)
#  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, state) do
    {:noreply, state}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, state) do
    {:stop, :normal, state}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: consumer_tag}}, state) do
    {:noreply, state}
  end

  def handle_info({:basic_deliver, payload, params}, state) do
    {config = %{chan: chan, route: route}, messages} = state

    t = Task.Supervisor.async_nolink(Warren.Supervisor.task_supervisor(), Controller, :execute, [route, self(), payload, params])

    Logger.debug fn -> ["Task started with pid ", inspect(t.pid), ", reference ", inspect(t.ref)] end

    new_messages =
      messages
      |> Map.put(t.ref, {params[:delivery_tag], params[:redelivered]})

    {:noreply, {config, new_messages}}
  end

  def handle_info({ref, response}, {config = %{chan: channel}, messages}) do
    Logger.debug fn -> ["Received down notification ", inspect(ref), inspect(response)] end

    {delivery_tag, redelivered} = messages[ref]

    case response do
      {:ok} ->
        Basic.ack(channel, delivery_tag)
      {:perm_error} ->
        Basic.reject(channel, delivery_tag, requeue: false)
      _ ->
        Basic.reject(channel, delivery_tag, requeue: !redelivered)
    end

    new_messages =
      messages
      |> Map.delete(ref)

    Logger.debug fn -> ["New message map is", inspect(new_messages)] end

    {:noreply, {config, new_messages}}
  end

  def handle_info({:DOWN, _, :process, pid, reason}, state = {%{config: config, route: route, conn_pid: conn_pid}, messages}) do

    Logger.debug fn -> ["Notification pid is ", inspect(pid), "; Connection pid is ", inspect(conn_pid)] end

    # we only care about DOWN notifications for the connection, not any of the tasks - those are handled up above.
    {:ok, new_state} =
      case pid do
        ^conn_pid -> rabbitmq_connect(config, route, messages)
        _ -> {:ok, state}
      end
    {:noreply, new_state}
  end

  @spec declare_queues(Channel.t, Route.t) :: {:ok, Route.t}
  defp declare_queues(chan, route) do
    Exchange.declare(chan, Atom.to_string(route.exchange), route.exchange_kind)

    {:ok, %{queue: queue}} =
      case route.error_queue do
        nil ->
          Queue.declare(chan, route.name, durable: route.durable)
        error_queue ->
          Queue.declare(chan, error_queue, durable: route.durable)

          # Messages that cannot be delivered to any consumer in the main queue will be routed to the error queue
          Queue.declare(chan, route.name, durable: route.durable,
                                      arguments: [{"x-dead-letter-exchange", :longstr, ""},
                                                  {"x-dead-letter-routing-key", :longstr, error_queue}])
      end

    Logger.debug fn -> "Declared queue #{queue}" end

    Queue.bind(chan, queue, Atom.to_string(route.exchange), [{:routing_key, queue}])
    # todo should the error queue be bound to a routing key too?

    # update the queue name with one returned by the server
    {:ok, chan, %Route{route | name: queue}}
  end

  defp rabbitmq_connect(config, route, messages \\ %{}) do
    case Connection.open(config[:url]) do
      {:ok, conn} ->
        # Get notifications when the connection goes down
        Process.monitor(conn.pid)
        # Everything else remains the same
        {:ok, chan} = Channel.open(conn)

        {:ok, chan, route} = declare_queues(chan, route)

        Basic.qos(chan, prefetch_count: route.prefetch_count)
        {:ok, _consumer_tag} = Basic.consume(chan, route.name)
        {:ok, {%{chan: chan, config: config, route: route, conn_pid: conn.pid}, messages}}

      {:error, _} ->
        # Reconnection loop
        :timer.sleep(config[:reconnect_wait])
        rabbitmq_connect(config, route)
    end
  end
end