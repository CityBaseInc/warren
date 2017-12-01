defmodule Warren.Controller do
  @moduledoc false

  alias Warren.Consumer
  alias Warren.Dsl.Route
  alias AMQP.Channel

  @doc """
  Asynchronously invokes the specified controller action. The `pid` parameter specifies the pid of the calling
  `Consumer` gen server.
  """
  @spec execute(Route.t, pid, String.t, map) :: Channel.t
  def execute(route, consumer, payload, %{delivery_tag: tag, redelivered: redelivered, routing_key: routing_key}) do

    # Spawn a new process and grab its pid
    apply(route.controller, route.action, [tag, redelivered, payload, routing_key])
#    pid = spawn(fn -> apply(route.controller, route.action, [tag, redelivered, payload, routing_key]) end)
#
#    # Set up a monitor for this pid
#    ref = Process.monitor(pid)
#
#    # Wait for a down message for given ref/pid
#    receive do
#      {:DOWN, ^ref, :process, ^pid, :normal} ->
#        IO.puts "Normal exit from #{inspect pid}"
#        Consumer.ack(consumer, tag)
#      {:DOWN, ^ref, :process, ^pid, msg} ->
#        IO.puts "Received :DOWN from #{inspect pid}"
#        Consumer.nack(consumer, tag, !redelivered)
#    end
  end

end