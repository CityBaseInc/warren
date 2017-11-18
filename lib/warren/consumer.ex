defmodule Warren.Consumer do

  @moduledoc """
  The `Consumer` module implements a `GenServer` for declaring, registrering, subscribing to and consuming from a single
  exchange <> queue binding in RabbitMQ. The configuration parameters supplied to it define subscription behavior
  """

  use GenServer
  use AMQP

  require Logger

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, [])
  end
#
  def init({config, route}) do
    rabbitmq_connect(config, route)

#    config_map =
#      config
#      |> Enum.into(%{})
#
#    default_config()
#    |> Map.merge(config_map)
#    |> rabbitmq_connect()
  end

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

  def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered, routing_key: routing_key}}, state) do
    %{chan: chan, route: route} = state

    spawn fn -> apply(route.controller, route.action, [chan, tag, redelivered, payload, routing_key]) end

    {:noreply, state}
  end

  def handle_info({:DOWN, _, :process, _pid, _reason}, %{config: config, route: route}) do
    {:ok, state} = rabbitmq_connect(config, route)
    {:noreply, state}
  end

  defp declare_queues(chan, route) do
    Exchange.topic(chan, Atom.to_string(route.exchange))

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
    {:ok, chan, %Warren.Dsl.Route{route | name: queue}}
  end

  defp rabbitmq_connect(config, route) do
    case Connection.open(config[:url]) do
      {:ok, conn} ->
        # Get notifications when the connection goes down
        Process.monitor(conn.pid)
        # Everything else remains the same
        {:ok, chan} = Channel.open(conn)

        {:ok, chan, route} = declare_queues(chan, route)

        Basic.qos(chan, prefetch_count: route.prefetch_count)
        {:ok, _consumer_tag} = Basic.consume(chan, route.name)
        {:ok, %{chan: chan, config: config, route: route}}

      {:error, _} ->
        # Reconnection loop
        :timer.sleep(config[:reconnect_wait])
        rabbitmq_connect(config, route)
    end
  end

  def no_consumer(channel, tag, redelivered, payload, routing_key) do
    raise "No consumer function specified for #{routing_key}"

  rescue
    # Requeue unless it's a redelivered message.
    # This means we will retry consuming a message once in case of exception
    # before we give up and have it moved to the error queue
    #
    # You might also want to catch :exit signal in production code.
    # Make sure you call ack, nack or reject otherwise comsumer will stop
    # receiving messages.
    exception ->
      Basic.reject channel, tag, requeue: not redelivered
      IO.puts "Error converting #{payload} to integer"
  end
end