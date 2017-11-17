defmodule Warren.Dsl.Route do
  alias Warren.Dsl.Route

  @moduledoc false

  defstruct name: nil, exchange: nil, error_queue: nil, prefetch_count: 10, controller: nil, durable: false

  @type t :: %Route{}

  def build(name, exchange, error_queue, prefetch_count, controller, durable) do
    %Route{
      name: name,
      exchange: exchange,
      error_queue: error_queue,
      prefetch_count: prefetch_count,
      controller: controller,
      durable: durable
    }
  end
  def build(name, exchange, controller), do: %Route {name: name, exchange: exchange, controller: controller}
end