defmodule ThesisBackend.Services.OrderService do
  # import ThesisBackend.Guards

  alias ThesisBackend.{Orders, Variations, Tools}

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
        "bill_full_name" => Map.get(params, "first_name", "") <> " " <> Map.get(params, "last_name", ""),
        "bill_phone_number" => params["phone_number"],
        "invoice_value" => invoice_value,
        "note" => params["note"],
        "account_id" => account_id
      })

    get = fn -> Orders.get_order_by_id(params["id"]) end
    create = fn -> Orders.create_order(order_attrs) end
    update = fn order -> Orders.update_order(order, order_attrs) end

    Orders.create_or_update(get, create, update)
  end

  def update_variation_quantity(variation_id, nil, new_quantity),
    do: update_variation_quantity(variation_id, 0, new_quantity)

  def update_variation_quantity(_variation_id, old_quantity, new_quantity)
      when old_quantity == new_quantity,
      do: {:ok, :quantity_not_change}

  def update_variation_quantity(variation_id, old_quantity, new_quantity) do
    with {:ok, variation} <- Variations.get_variation_by_id(variation_id, :hidden) do
      remain_quantity = Tools.to_int(variation.remain_quantity) + old_quantity - new_quantity

      if remain_quantity >= 0 do
        Variations.update_variation(variation, %{remain_quantity: remain_quantity})
      else
        {:error,
         %{
           message_code: 2003,
           message: "remain_quantity_not_enough",
           variation_id: variation.id,
           remain_quantity: variation.remain_quantity
         }}
      end
    else
      error -> error
    end
  end

  def create_or_update_order_items(account, params, order) do
    order_items = (params["order_items"] || [])
      |> Enum.map(fn el ->
        Map.merge(el, %{
          "order_id" => order.id
        })
        end)

    {success, error} =
      order_items
      |> Enum.sort_by(&(&1["variation_info"]["variation_pos_id"]), :desc)
      |> Enum.reduce({[], []}, fn el, {s, e} ->
        get = fn -> Orders.get_order_item_by_id(el["id"]) end
        create = fn -> Orders.create_order_item(el) end
        update = fn item -> Orders.update_order_item(item, el) end

        with {:ok, order_item} <- Orders.create_or_update(get, create, update),
             {:ok, _} <- update_variation_quantity(el["variation_id"], el["old_quantity"], el["quantity"]) do
          {s ++ [order_item], e}
        else
          {:error, changeset} -> {s, e ++ [changeset]}
        end
      end)

    if error == [], do: {:ok, success}, else: {:error, error}
  end
end
