defmodule Warren.Consumer do

  @moduledoc """
  The `Consumer` module implements a `GenServer` for declaring, registrering, subscribing to and consuming from a single
  exchange <> queue binding in RabbitMQ. The configuration parameters supplied to it define subscription behavior
  """

  use GenServer
  use AMQP

  require Logger

  def start_link(options) do
    GenServer.start_link(__MODULE__, options, [])
  end

  def init(opts) do
    default_opts()
    |> Map.merge(opts)
    |> rabbitmq_connect()
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
    %{chan: chan, opts: %{consume: consume}} = state

    spawn fn -> consume.(chan, tag, redelivered, payload, routing_key) end

    {:noreply, state}
  end

  defp declare_queues(chan, opts = %{name: name, durable_queues: durable, exchange: exchange}) do
    {:ok, %{queue: queue}} =
      case opts do
        %{:define_error_queue => true, :error_queue_suffix => suffix} ->
          error_queue = name <> "_" <> suffix
          Queue.declare(chan, error_queue, durable: durable)

          # Messages that cannot be delivered to any consumer in the main queue will be routed to the error queue
          Queue.declare(chan, name, durable: durable,
                                      arguments: [{"x-dead-letter-exchange", :longstr, ""},
                                                  {"x-dead-letter-routing-key", :longstr, error_queue}])
        _ ->
          Queue.declare(chan, name, durable: durable)
      end

    Logger.debug fn -> "Declared queue #{queue}" end

    Queue.bind(chan, queue, exchange, [{:routing_key, queue}])
    # todo should the error queue be bound to a routing key too?

    # update the queue name with one returned by the server
    {:ok, chan, %{opts | name: queue}}
  end

  defp rabbitmq_connect(opts) do
    case Connection.open(opts[:url]) do
      {:ok, conn} ->
        # Get notifications when the connection goes down
        Process.monitor(conn.pid)
        # Everything else remains the same
        {:ok, chan} = Channel.open(conn)

        {:ok, chan, opts} = declare_queues(chan, opts)

        Basic.qos(chan, prefetch_count: opts[:prefetch_count])
        {:ok, _consumer_tag} = Basic.consume(chan, opts[:name])
        {:ok, %{chan: chan, opts: opts}}

      {:error, _} ->
        # Reconnection loop
        :timer.sleep(opts[:reconnect_wait])
        rabbitmq_connect(opts)
    end
  end

  def handle_info({:DOWN, _, :process, _pid, _reason}, %{opts: opts}) do
    {:ok, chan} = rabbitmq_connect(opts)
    state = %{opts: opts, chan: chan}
    {:noreply, state}
  end

  defp no_consumer(channel, tag, redelivered, payload, routing_key) do
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

  defp default_opts() do
    %{
      reconnect_wait: 10000,
      define_error_queue: true,
      error_queue_suffix: "_error",
      prefetch_count: 10,
      consumer: &Warren.Consumer.no_consumer/5,
      name: "", # an empty queue name will instruct rabbit to auto-generate a name for this queue and return it
      durable_queues: false
    }
  end
end