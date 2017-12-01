defmodule Warren.Dsl.Router do
  @moduledoc false

  alias Warren.Dsl.Route

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
      Module.register_attribute(__MODULE__, :exchange_kind, accumulate: false)
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


  defmacro exchange(exchange, kind, opts \\ []) do
    do_exchange(exchange, kind, opts)
  end

  defmacro topic(exchange, opts \\ []) do
    do_exchange(exchange, :topic, opts)
  end

  defp do_exchange(exchange, kind, opts \\ []) do
    quote do
      @exchange unquote(exchange)
      @exchange_kind unquote(kind)

      unquote(opts[:do])
    end
  end

  defmacro get(topic, controller, action, opts \\ []) do
    quote do
      @exchanges {@exchange, @exchange_kind, unquote(topic), unquote(controller), unquote(action), unquote(opts)}
    end
  end

  def compile(env, exchanges, builder_opts) do
    exchanges
    |> Enum.map(fn {ex, ex_kind, topic, controller, action, _} -> Macro.escape(Route.build(topic, ex, ex_kind, controller, action)) end)
  end
end