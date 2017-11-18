defmodule Warren.Dsl.Router do
  @moduledoc false

  alias Warren.Dsl.Route

#  @type plug :: module | atom

  @doc false
  defmacro __using__(opts) do
    quote do
      @router_opts unquote(opts)

      import Warren.Dsl.Router

      def init(opts) do
        opts
      end

      def call(opts) do
        router_call(opts)
      end

      defoverridable [init: 1, call: 1]

      Module.register_attribute(__MODULE__, :exchanges, accumulate: true)
      Module.register_attribute(__MODULE__, :exchange, accumulate: false)
      @before_compile Warren.Dsl.Router
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    exchanges   = Module.get_attribute(env.module, :exchanges)
    router_opts = Module.get_attribute(env.module, :router_opts)

    config = Warren.Dsl.Router.compile(env, exchanges, router_opts)

    quote do
      defp router_call(_), do: unquote(config)
    end
  end

  defmacro exchange(exchange, opts \\ []) do
    quote do
      @exchange unquote(exchange)

      unquote(opts[:do])
    end
  end

  defmacro get(topic, controller, action, opts \\ []) do
    quote do
      @exchanges {@exchange, unquote(topic), unquote(controller), unquote(action), unquote(opts)}
    end
  end

  def compile(env, exchanges, builder_opts) do
    exchanges
    |> Enum.map(fn {ex, topic, controller, action, _opts} -> Macro.escape(Route.build(topic, ex, controller, action)) end)
  end
end