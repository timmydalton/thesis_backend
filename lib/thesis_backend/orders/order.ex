defmodule ThesisBackend.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset
  alias ThesisBackend.Orders.OrderItem
  alias ThesisBackend.Accounts.Account

  @non_required_fields [:id, :inserted_at, :updated_at]

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "orders" do
    field :bill_full_name, :string
    field :bill_phone_number, :string
    field :shipping_address, :map
    field :note, :string, default: ""
    field :status, :integer, default: 0

    field :shipping_fee, :integer, default: 0
    field :transfer_money, :integer, default: 0
    field :cash, :integer, default: 0
    field :invoice_value, :integer, default: 0
    field :display_id, :integer
    field :is_deleted, :boolean, default: false
    field :payment_method, :integer
    field :custom_items, {:array, :map}

    belongs_to :account, Account, type: Ecto.UUID
    has_many(:order_items, OrderItem, foreign_key: :order_id)

    timestamps()
  end

  def changeset(%__MODULE__{} = order, attrs) do
    fields = __schema__(:fields) -- @non_required_fields

    order
    |> cast(attrs, fields)
  end

  def json(order, opts \\ [])

  def json(%__MODULE__{} = order, opts) do
    selected_fields = Keyword.get(opts, :selected_fields)
    fields = selected_fields || __schema__(:fields)
    data = Map.take(order, fields)

    data =
      case Map.fetch(order, :order_items) do
        {:ok, %Ecto.Association.NotLoaded{}} ->
          data

        {:ok, value} ->
          order_items = OrderItem.json(value, opts)
          Map.put(data, :order_items, order_items)

        :error ->
          data
      end

    data
  end

  def json(orders, opts) when is_list(orders) do
    Enum.map(orders, &json(&1, opts))
  end

  def json(data, _), do: data
end
