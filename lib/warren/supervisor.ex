defmodule Warren.Supervisor do
  @moduledoc false

  require Logger
  use Supervisor

  @doc """
  Starts the endpoint supervision tree.
  """
  def start_link(otp_app, mod) do
    case Supervisor.start_link(__MODULE__, {otp_app, mod}, name: mod) do
      {:ok, _} = ok ->
#        warmup(mod)
        ok
      {:error, _} = error ->
        error
    end
  end

  @doc false
  def init({otp_app, mod}) do
    id = :crypto.strong_rand_bytes(16) |> Base.encode64

    conf =
      case mod.init(:supervisor, [endpoint_id: id] ++ config(otp_app, mod)) do
        {:ok, conf} -> conf
        other -> raise ArgumentError, "expected init/2 callback to return {:ok, config}, got: #{inspect other}"
      end

    server? = server?(conf)

#    if server? and conf[:code_reloader] do
#      Phoenix.CodeReloader.Server.check_symlinks()
#    end

    children =
#      pubsub_children(mod, conf) ++
#      config_children(mod, conf, otp_app) ++
      server_children(mod, conf, server?)
#      watcher_children(mod, conf, server?)

    supervise(children, strategy: :one_for_one)
  end

  defp server_children(mod, conf, server?) do
    if server? do
      server = Module.concat(mod, "Server")
      long_poll = Module.concat(mod, "LongPoll.Supervisor")
      [supervisor(Phoenix.Endpoint.Handler, [conf[:otp_app], mod, [name: server]]),
       supervisor(Phoenix.Transports.LongPoll.Supervisor, [[name: long_poll]])]
    else
      []
    end
  end

  defp defaults(otp_app, _module) do
    [otp_app: otp_app]
  end

  @doc """
  The endpoint configuration used at compile time.
  """
  def config(otp_app, endpoint) do
    Warren.Config.from_env(otp_app, endpoint, defaults(otp_app, endpoint))
  end

  @doc """
  Checks if Endpoint's web server has been configured to start.
  """
  def server?(otp_app, endpoint) when is_atom(otp_app) and is_atom(endpoint) do
    otp_app
    |> config(endpoint)
    |> server?()
  end
  def server?(conf) when is_list(conf) do
    true
#    Keyword.get(conf, :server, Application.get_env(:phoenix, :serve_endpoints, false))
  end
end