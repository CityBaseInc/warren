defmodule Warren.Config do
  @moduledoc false
  
  @doc """
  Reads the configuration for module from the given otp app.
  Useful to read a particular value at compilation time.
  """
  def from_env(otp_app, module, defaults) do
    merge(defaults, fetch_config(otp_app, module))
  end

  defp fetch_config(otp_app, module) do
    case Application.fetch_env(otp_app, module) do
      {:ok, conf} -> conf
      :error ->
        IO.puts :stderr, "warning: no configuration found for otp_app " <>
                         "#{inspect otp_app} and module #{inspect module}"
        []
    end
  end

  def merge(config1, config2) do
    Keyword.merge(config1, config2, &merger/3)
  end

  defp merger(_k, v1, v2) do
    if Keyword.keyword?(v1) and Keyword.keyword?(v2) do
      Keyword.merge(v1, v2, &merger/3)
    else
      v2
    end
  end
end