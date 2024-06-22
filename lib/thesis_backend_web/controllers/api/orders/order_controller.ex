defmodule ThesisBackendWeb.Api.OrderController do
  use ThesisBackendWeb, :controller

  alias Ecto.Multi
  alias ThesisBackend.{Tools, Repo, Orders, Variations, Accounts}
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

  def get_order_by_time(_conn, params) do
    [insight_order, insight_revenue, insight_account, {:ok, info_order}, {:ok, compare_info_order}]  =
      [
        Task.async(fn ->
          Orders.get_insight_order_time(params)
        end),
        Task.async(fn ->
          Orders.get_insight_revenue_time(params)
        end),
        Task.async(fn ->
          Accounts.get_insight_account_time(params)
        end),
        Task.async(fn ->
          Orders.get_info_orders(params)
        end),
        Task.async(fn ->
          Orders.compare_info_order(params)
        end)
      ]
    |> Enum.map(&Task.await(&1, :infinity))

    data = %{
      insight_order: insight_order,
      insight_revenue: insight_revenue,
      insight_account: insight_account,
      info_order: info_order |> Enum.map(&Order.json(&1, selected_fields: [:id, :status, :ads_source, :invoice_value])),
      compare_info_order: compare_info_order |> Enum.map(&Order.json(&1))
    }

    {:success, :with_data, :insight, data}
  end
end
