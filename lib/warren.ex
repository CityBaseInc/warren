defmodule Warren do

  @moduledoc """
  Context for Warren
  """

  # Giving credit where due: large parts of the plumbing of this projet are taken from Phoenix

  @callback start_link() :: Supervisor.on_start

  @callback init(:supervisor, config :: Keyword.t) :: {:ok, Keyword.t}

  defmacro __using__(opts) do
    quote do
#      @behaviour Phoenix.Endpoint

      unquote(config(opts))
#      unquote(pubsub())
#      unquote(plug())
      unquote(server())
    end
  end

  defp config(opts) do
    quote do
      @otp_app unquote(opts)[:otp_app] || raise "warren expects :otp_app to be given"
      var!(config) = Warren.Supervisor.config(@otp_app, __MODULE__)
#      var!(code_reloading?) = var!(config)[:code_reloader]

      # Avoid unused variable warnings
#      _ = var!(code_reloading?)

      @doc """
      Callback invoked on endpoint initialization.
      """
      def init(_key, config) do
        {:ok, config}
      end

      def define_routes(opts) do
        raise "warren expects define_routes/1 to be defined"
      end

      defoverridable init: 2, define_routes: 1
    end
  end

  defp server() do
    quote location: :keep, unquote: false do
      @doc false
      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      defoverridable child_spec: 1

      @doc """
      Starts the endpoint supervision tree.
      """
      def start_link(_opts \\ []) do
        Warren.Supervisor.start_link(@otp_app, __MODULE__)
      end
    end
  end
end
