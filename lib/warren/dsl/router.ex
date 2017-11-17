defmodule Warren.Router do
  @moduledoc false

#  @type plug :: module | atom

  @doc false
  defmacro __using__(opts) do
    quote do
      @router_opts unquote(opts)

      import Warren.Router

      def init(opts) do
        opts
      end

      def call(opts) do
        router_call(opts)
      end

      defoverridable [init: 1, call: 1]

      Module.register_attribute(__MODULE__, :exchanges, accumulate: true)
      Module.register_attribute(__MODULE__, :exchange, accumulate: false)
      @before_compile Warren.Router
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    exchanges   = Module.get_attribute(env.module, :exchanges)
    router_opts = Module.get_attribute(env.module, :router_opts)

    config = Warren.Router.compile(env, exchanges, router_opts)

    quote do
      defp router_call(_), do: unquote(config)
    end
  end

  @doc """
  A macro that stores a new plug. `opts` will be passed unchanged to the new
  plug.

  This macro doesn't add any guards when adding the new plug to the pipeline;
  for more information about adding plugs with guards see `compile/1`.

  ## Examples

      plug Plug.Logger               # plug module
      plug :foo, some_options: true  # plug function

  """
  defmacro exchange(exchange, opts \\ []) do
    quote do
      @exchange unquote(exchange)

      unquote(opts[:do])
    end
  end

  defmacro get(topic, controller, action, opts \\ []) do
    quote do
      @exchanges {@exchange, unquote(topic), unquote(controller), unquote(opts)}
    end
  end

  @doc """
  Compiles a plug pipeline.

  Each element of the plug pipeline (according to the type signature of this
  function) has the form:

      {plug_name, options, guards}

  Note that this function expects a reversed pipeline (with the last plug that
  has to be called coming first in the pipeline).

  The function returns a tuple with the first element being a quoted reference
  to the connection and the second element being the compiled quoted pipeline.

  ## Examples

      Plug.Builder.compile(env, [
        {Plug.Logger, [], true}, # no guards, as added by the Plug.Builder.plug/2 macro
        {Plug.Head, [], quote(do: a when is_binary(a))}
      ], [])

  """
#  @spec compile(Macro.Env.t, [{plug, Plug.opts, Macro.t}], Keyword.t) :: {Macro.t, Macro.t}
  def compile(env, exchanges, builder_opts) do
    exchanges
    |> Enum.each(ex -> )
  end
#
#  # Initializes the options of a plug at compile time.
#  defp init_plug({plug, opts, guards}) do
#    case Atom.to_charlist(plug) do
#      ~c"Elixir." ++ _ -> init_module_plug(plug, opts, guards)
#      _                -> init_fun_plug(plug, opts, guards)
#    end
#  end
#
#  defp init_module_plug(plug, opts, guards) do
#    initialized_opts = plug.init(opts)
#
#    if function_exported?(plug, :call, 2) do
#      {:module, plug, initialized_opts, guards}
#    else
#      raise ArgumentError, message: "#{inspect plug} plug must implement call/2"
#    end
#  end
#
#  defp init_fun_plug(plug, opts, guards) do
#    {:function, plug, opts, guards}
#  end
#
#  # `acc` is a series of nested plug calls in the form of
#  # plug3(plug2(plug1(conn))). `quote_plug` wraps a new plug around that series
#  # of calls.
#  defp quote_plug({plug_type, plug, opts, guards}, acc, env, builder_opts) do
#    call = quote_plug_call(plug_type, plug, opts)
#
#    error_message = case plug_type do
#      :module   -> "expected #{inspect plug}.call/2 to return a Plug.Conn"
#      :function -> "expected #{plug}/2 to return a Plug.Conn"
#    end <> ", all plugs must receive a connection (conn) and return a connection"
#
#    {fun, meta, [arg, [do: clauses]]} =
#      quote do
#        case unquote(compile_guards(call, guards)) do
#          %Plug.Conn{halted: true} = conn ->
#            unquote(log_halt(plug_type, plug, env, builder_opts))
#            conn
#          %Plug.Conn{} = conn ->
#            unquote(acc)
#          _ ->
#            raise unquote(error_message)
#        end
#      end
#
#    generated? = :erlang.system_info(:otp_release) >= '19'
#
#    clauses =
#      Enum.map(clauses, fn {:->, meta, args} ->
#        if generated? do
#          {:->, [generated: true] ++ meta, args}
#        else
#          {:->, Keyword.put(meta, :line, -1), args}
#        end
#      end)
#
#    {fun, meta, [arg, [do: clauses]]}
#  end
#
#  defp quote_plug_call(:function, plug, opts) do
#    quote do: unquote(plug)(conn, unquote(Macro.escape(opts)))
#  end
#
#  defp quote_plug_call(:module, plug, opts) do
#    quote do: unquote(plug).call(conn, unquote(Macro.escape(opts)))
#  end
#
#  defp compile_guards(call, true) do
#    call
#  end
#
#  defp compile_guards(call, guards) do
#    quote do
#      case true do
#        true when unquote(guards) -> unquote(call)
#        true -> conn
#      end
#    end
#  end
#
#  defp log_halt(plug_type, plug, env, builder_opts) do
#    if level = builder_opts[:log_on_halt] do
#      message = case plug_type do
#        :module   -> "#{inspect env.module} halted in #{inspect plug}.call/2"
#        :function -> "#{inspect env.module} halted in #{inspect plug}/2"
#      end
#
#      quote do
#        require Logger
#        # Matching, to make Dialyzer happy on code executing Plug.Builder.compile/3
#        _ = Logger.unquote(level)(unquote(message))
#      end
#    else
#      nil
#    end
#  end
end