defmodule ThesisBackend.Orders do
  import Ecto.Query, warn: false
  import ThesisBackend.Guards

  alias ThesisBackend.{Repo, Tools}
  alias ThesisBackend.Variations.Variation
  alias ThesisBackend.Products.Product
  alias ThesisBackend.Orders.{Order, OrderItem}

  def create_or_update(get, create, update) do
    case get.() do
      {:error, _} -> create.()
      {:ok, v} -> update.(v)
    end
  end

  def create_order(attrs) when is_map(attrs) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert(returning: true)
  end

  def update_order(%Order{} = order, attrs) do
    order
    |> Order.changeset(attrs)
    |> Repo.update(returning: true)
  end

  def create_order_item(attrs) do
    %OrderItem{}
    |> OrderItem.changeset(attrs)
    |> Repo.insert()
  end

  def update_order_item(%OrderItem{} = order_item, attrs) do
    order_item
    |> OrderItem.changeset(attrs)
    |> Repo.update()
  end

  def get_order_by_id(id) when is_empty(id) do
    {:error, :order_id_not_existed}
  end

  def get_order_item_by_id(id) when is_empty(id) do
    {:error, :order_item_id_not_existed}
  end

  def get_order_item_by_id(id) do
    OrderItem
    |> where([o], o.id == ^id and not o.is_deleted)
    |> Repo.one()
    |> Tools.get_record()
  end

  def get_order_by_id(id) do
    Order
    |> where([o], o.id == ^id)
    |> Repo.one()
    |> Tools.get_record()
  end

  def get_count_order_by_status() do
    count =
      Order
      |> group_by([o], o.status)
      |> select([o], %{status: o.status, total: count(o.id)})
      |> Repo.all()

    {:ok, count}
  end

  def update_orders(id, status) do
    Order
    |> where([o], o.pos_id == ^id)
    |> Repo.update_all(set: [status: status])
    |> Tools.get_record()
  end

  def preload_order(%Order{} = order, opts \\ []) do
    preload_order_items = Keyword.get(opts, :preload_order_items)

    preload_variation =
      Variation
      |> where([v], not v.is_removed)

    preload_order_items_query =
      OrderItem
      |> where([ot], not ot.is_deleted)
      |> order_by([ot], desc: ot.id)
      |> preload([ot], variation: ^preload_variation)

    preload = if preload_order_items, do: [order_items: preload_order_items_query], else: []

    Repo.preload(order, preload)
  end
end
