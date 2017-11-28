defmodule Warren.Dsl.Route do
  alias Warren.Dsl.Route

  # Descriptor for a single queue route

  @moduledoc false

  defstruct name: nil, exchange_kind: nil, exchange: nil, error_queue: nil, prefetch_count: 10, controller: nil, durable: false, action: nil

  @type t :: %Route{}
  @type exchange_kind :: :fanout | :direct | :topic | :match | :headers

  @spec build(String.t, atom, atom, String.t, integer, String.t, String.t, boolean) :: Route.t
  def build(name, exchange, exchange_kind, error_queue, prefetch_count, controller, action, durable) do
    %Route{
      name: name,
      exchange: exchange,
      exchange_kind: exchange_kind,
      error_queue: error_queue,
      prefetch_count: prefetch_count,
      controller: controller,
      action: action,
      durable: durable
    }
  end

  @spec build(String.t, atom, exchange_kind, String.t, String.t) :: Route.t
  def build(name, exchange, exchange_kind, controller, action), do: %Route {name: name, exchange: exchange, exchange_kind: exchange_kind, controller: controller, action: action}
end