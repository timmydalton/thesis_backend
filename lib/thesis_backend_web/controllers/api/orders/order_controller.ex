defmodule ThesisBackend.Api.OrderController do
  use ThesisBackendWeb, :controller

  alias Ecto.Multi
  alias ThesisBackend.{Tools, Orders, Variations}
  alias ThesisBackend.Services.OrderService

  def quick_order(conn, params) do
    multi =
      Multi.new()
      |> Multi.run(:check_remain_quantity_vari, fn _, _ ->
        Variations.check_remain_quantity_variation(params)
      end)
      |> Multi.run(:order, fn _, _ ->
        OrderService.create_or_update_order(conn, nil, params)
      end)
      |> Multi.run(:order_items, fn _, %{order: order} ->
        OrderService.create_or_update_order_items(nil, params, order)
      end)

    case Repo.transaction(multi) do
      {:ok, result} ->
        order =
          result.order
          |> Orders.preload_order(preload_order_items: true)

      {:error, :order_items, error, _order_info} ->
        {:failed, :with_reason, error}

      reason ->
        Tools.log_order_storev2("QUICK_ORDER_ERROR:", %{"reason" => reason , "params" => params})
        {:failed, :with_reason, reason}
  end
end
