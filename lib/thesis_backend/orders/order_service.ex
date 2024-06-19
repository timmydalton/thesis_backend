defmodule ThesisBackend.Services.OrderService do
  import ThesisBackend.Guards

  alias ThesisBackend.{Orders, Variations, Products}
  alias ThesisBackend.Orders.Order

  def create_or_update_order(conn, account, params) do
    account_id = if conn.assigns[:account], do: conn.assigns[:account].id, else: nil

    invoice_value =
      (params["order_items"] || [])
      |> Enum.reduce(0, fn el, acc ->
        quantity = Tools.to_int(el["quantity"] || 0)
        price = el["variation_info"]["retail_price"] || 0

        acc + quantity * Tools.to_int(price)
      end)

    order_attrs =
      Map.take(params, [
        "transfer_money",
        "charged_by_card",
        "cash",
        "form_id",
        "form_data",
        "status",
        "payment_method",
        "shipping_fee"
      ])
      |> Map.merge(%{
        "shipping_address" => params["shipping_address"],
        "bill_full_name" => Map.get(params, "first_name", "") <> " " <> Map.get(params, "last_name", "")),
        "bill_phone_number" => params["phone_number"],
        "invoice_value" => invoice_value,
        "note" => params["note"],
      })

    get = fn -> Orders.get_order_by_id(params["id"]) end
    create = fn -> Orders.create_order(order_attrs) end
    update = fn order -> Orders.update_order(order, order_attrs) end

    Orders.create_or_update(get, create, update)
  end

  def create_or_update_order_items(account, params, order) do
    order_items = params["order_items"]

    product_ids =
      Enum.map(order_items || [], & &1["variation_info"]["product_id"])
      |> Enum.uniq()

    promos = Enum.filter(promos, &(&1.pos_id && &1.type == "coupon"))

    {success, error} =
      order_items
      |> Enum.sort_by(&(&1["variation_info"]["variation_pos_id"]), :desc)
      |> Enum.reduce({[], []}, fn el, {s, e} ->
        get = fn -> Orders.get_order_item_by_id(el["id"]) end
        create = fn -> Orders.create_order_item(el) end
        update = fn item -> Orders.update_order_item(item, el) end

        with {:ok, order_item} <- Orders.create_or_update(get, create, update),
             {:ok, _} <-
               update_variation_quantity(
                 el["variation_id"],
                 el["old_quantity"],
                 el["quantity"]
               ) do
          {s ++ [order_item], e}
        else
          {:error, changeset} -> {s, e ++ [changeset]}
        end
      end)

    if error == [], do: {:ok, success}, else: {:error, error}
  end
end
