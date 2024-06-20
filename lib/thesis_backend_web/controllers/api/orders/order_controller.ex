defmodule ThesisBackendWeb.Api.OrderController do
  use ThesisBackendWeb, :controller

  alias Ecto.Multi
  alias ThesisBackend.{Tools, Repo, Orders, Variations}
  alias ThesisBackend.Services.OrderService
  alias ThesisBackend.Orders.Order

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
          |> Order.json()

        {:success, :with_data, %{
          "message" => "Order Successfully",
          "data" => order,
        }}

      {:error, :order_items, error, _order_info} ->
        IO.inspect(error)
        {:failed, :with_reason, error}

      reason ->
        IO.inspect("unhandled case")
        {:failed, :with_reason, reason}
    end
  end

  def all(conn, params) do
    with {:ok, orders} <- Orders.get_all_order(params) do
      data = Order.json(orders.data)

      orders =
        Map.merge(orders, %{
          data: data
        })

      {:success, :with_data, "orders", orders}
    end
  end
end
