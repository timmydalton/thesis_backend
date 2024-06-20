defmodule ThesisBackend.Orders do
  import Ecto.Query, warn: false
  import ThesisBackend.Guards

  alias ThesisBackend.{Repo, Tools}
  alias ThesisBackend.Variations.Variation
  alias ThesisBackend.Products.Product
  alias ThesisBackend.Orders.{Order, OrderItem}

  alias Enum.OrderStatus

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

  def get_all_order(params) do
    {page, limit} = Tools.get_page_limit_from_params(params)
    offset = (page - 1) * limit
    term = params["term"]
    status = params["status"]

    filter_options =
      (params["filter_options"] || "")
      |> Jason.decode()
      |> case do
        {:ok, v} -> v
        _ -> %{}
      end

    date_range = filter_options["date_range"] || []

    {start_time, end_time} =
      Tools.get_start_end_time(
        %{
          "start_time" => Enum.at(date_range, 0),
          "end_time" => Enum.at(date_range, 1)
        },
        7
      )

    query = where(Order, [o], true)

    query =
      if start_time && end_time,
        do: where(query, [o], o.inserted_at >= ^start_time and o.inserted_at <= ^end_time),
        else: query

    # use CustomEcto
    count_status_query =
      query
      |> group_by([o], o.status)
      |> select([o], %{status: o.status, total: count(o.id)})

    query =
      if is_empty(status) || status == "-1" do
        where(query, [o], o.status != ^OrderStatus.value(:removed))
      else
        where(query, [o], o.status == ^status)
      end

    preload_variation =
      Variation
      |> where([v], not v.is_removed)

    preload_order_items =
      OrderItem
      |> where([ot], not ot.is_deleted)
      |> order_by([ot], desc: ot.id)
      |> preload([ot], variation: ^preload_variation)

    [data, count_status, total_entries] =
      Task.await_many([
        Task.async(fn ->
          query
          |> offset([o], ^offset)
          |> limit([o], ^limit)
          |> order_by([o], desc: o.inserted_at)
          |> preload([o], [order_items: ^preload_order_items])
          |> Repo.all()
        end),
        Task.async(fn ->
          count_status_query
          |> Repo.all()
        end),
        Task.async(fn ->
          Repo.aggregate(query, :count, :id)
        end)
      ], :infinity)

    orders = %{
      data: data,
      total_entries: total_entries,
      page: page,
      limit: limit,
      term: term,
      count_status: count_status
    }

    {:ok, orders}
  end
end
