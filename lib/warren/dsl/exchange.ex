defmodule Warren.Dsl.Exchange do
  alias Warren.Dsl.Exchange

  @moduledoc false

#  # Based heavily on Phoenix.Router.Scope
#
#  @stack :warren_dsl_exchanges
#  @exchanges :warren_dsl_route_exchanges
#
#  defstruct name: nil, queues: []
#
#  @doc """
#  Initializes the exchange.
#  """
#  def init(module) do
#    Module.put_attribute(module, @stack, [%Exchange{}])
#    Module.put_attribute(module, @exchanges, MapSet.new)
#  end
#
#  @doc """
#  Builds a route based on the top of the stack.
#  """
#  def route(module, name, exchange, controller, opts) do
#    queue    = validate_queue(name)
#
#    error_queue = Keyword.get(opts, :error_queue, %{})
#    prefetch_count = Keyword.get(opts, :prefetch_count, %{})
#    durable = Keyword.get(opts, :durable, %{})
#
##    as      = Keyword.get(opts, :as, Phoenix.Naming.resource_name(plug, "Controller"))
#
#    {path, host, alias, as, pipes, private, assigns} =
#      join(module, path, plug, as, private, assigns)
#    Phoenix.Router.Route.build(kind, verb, path, host, alias, plug_opts, as, pipes, private, assigns)
#  end
#
#  @doc """
#  Validates a path is a string and contains a leading prefix.
#  """
#
#  def validate_queue(queue), do: queue
##  def validate_path("/" <> _ = path), do: path
##  def validate_path(path) when is_binary(path) do
##    IO.write :stderr, """
##    warning: router paths should begin with a forward slash, got: #{inspect path}
##    #{Exception.format_stacktrace}
##    """
##
##    "/" <> path
##  end
##  def validate_path(path) do
##    raise ArgumentError, "router paths must be strings, got: #{inspect path}"
##  end
#
#  @doc """
#  Defines the given pipeline.
#  """
#  def pipeline(module, pipe) when is_atom(pipe) do
#    update_pipes module, &MapSet.put(&1, pipe)
#  end
#
#  @doc """
#  Appends the given pipes to the current scope pipe through.
#  """
#  def pipe_through(module, pipes) do
#    pipes = List.wrap(pipes)
#
#    update_stack(module, fn [exchange|stack] ->
#      exchange = put_in exchange.pipes, exchange.pipes ++ pipes
#      [exchange|stack]
#    end)
#  end
#
#  @doc """
#  Pushes an exchangeinto the module stack.
#  """
#  def push(module, name) when is_binary(path) do
#    push(module, name: name)
#  end
#
#  def push(module, opts) when is_list(opts) do
#    name = with name when not is_nil(name) <- Keyword.get(name, :path),
#                name <- validate_path(path),
#                do: name
#
#    exchange = %Exchange{path: path,
#                         queues: []}
#
#    update_stack(module, fn stack -> [exchange|stack] end)
#  end
#
#  @doc """
#  Pops a scope from the module stack.
#  """
#  def pop(module) do
#    update_stack(module, fn [_|stack] -> stack end)
#  end
#
#  @doc """
#  Returns true if the module's definition is currently within a scope block
#  """
#  def inside_scope?(module), do: length(get_stack(module)) > 1
#
#  defp join(module, name) do
#    stack = get_stack(module)
#    {join_path(stack, path), find_host(stack), join_alias(stack, alias),
#     join_as(stack, as), join_pipe_through(stack), join_private(stack, private),
#     join_assigns(stack, assigns)}
#  end
#
#  defp join_path(stack, path) do
#    "/" <>
#      ([Plug.Router.Utils.split(path)|extract(stack, :path)]
#       |> Enum.reverse()
#       |> Enum.concat()
#       |> Enum.join("/"))
#  end
#
#  defp join_alias(stack, alias) when is_atom(alias) do
#    [alias|extract(stack, :alias)]
#    |> Enum.reverse()
#    |> Module.concat()
#  end
#
#  defp join_as(_stack, nil), do: nil
#  defp join_as(stack, as) when is_atom(as) or is_binary(as) do
#    [as|extract(stack, :as)]
#    |> Enum.reverse()
#    |> Enum.join("_")
#  end
#
#  defp join_private(stack, private) do
#    Enum.reduce stack, private, &Map.merge(&1.private, &2)
#  end
#
#  defp join_assigns(stack, assigns) do
#    Enum.reduce stack, assigns, &Map.merge(&1.assigns, &2)
#  end
#
#  defp join_pipe_through(stack) do
#    for scope <- Enum.reverse(stack),
#        item <- scope.pipes,
#        do: item
#  end
#
#  defp find_host(stack) do
#    Enum.find_value(stack, & &1.host)
#  end
#
#  defp extract(stack, attr) do
#    for scope <- stack,
#        item = Map.fetch!(scope, attr),
#        do: item
#  end
#
#  defp get_stack(module) do
#    get_attribute(module, @stack)
#  end
#
#  defp update_stack(module, fun) do
#    update_attribute(module, @stack, fun)
#  end
#
#  defp update_pipes(module, fun) do
#    update_attribute(module, @pipes, fun)
#  end
#
#  defp get_attribute(module, attr) do
#    Module.get_attribute(module, attr) ||
#      raise "Warren router definition was not initialized"
#  end
#
#  defp update_attribute(module, attr, fun) do
#    Module.put_attribute(module, attr, fun.(get_attribute(module, attr)))
#  end
end