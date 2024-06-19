defmodule ThesisBackend.Orders.OrderItem do
  use Ecto.Schema
  import Ecto.Changeset
  alias ThesisBackend.Variations.Variation
  alias ThesisBackend.Tools
  @non_required_fields [:id, :inserted_at, :updated_at]

  schema "order_items" do
    field :order_id, :integer
    field :variation_info, :map
    field :quantity, :integer
    field :is_deleted, :boolean, default: false

    belongs_to(:variation, Variation, type: :binary_id, foreign_key: :variation_id)
    timestamps()
  end

  def changeset(%__MODULE__{} = order_item, attrs) do
    fields = __schema__(:fields) -- @non_required_fields

    order_item
    |> cast(attrs, fields)
  end

  def json(order_item, opts \\ [])

  def json(%__MODULE__{} = order_item, opts) do
    fields = __schema__(:fields)

    res =
      Map.take(order_item, fields)

    res =
      case Map.fetch(order_item, :variation) do
        {:ok, %Ecto.Association.NotLoaded{}} ->
          res

        {:ok, nil} ->
          res

        {:ok, variation} ->
          variation_info =
            order_item.variation_info

          Map.put(res, :variation_info, variation_info)
          |> Map.put(:product_id, variation.product_id)

        _ ->
          res
      end

    res
  end

  def json(order_items, opts) when is_list(order_items) do
    Enum.map(order_items, &json(&1, opts))
  end

  def json(_, _), do: nil
end
