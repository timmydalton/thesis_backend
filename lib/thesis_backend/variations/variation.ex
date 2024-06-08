defmodule ThesisBackend.Variations.Variation do
  use Ecto.Schema
  import Ecto.Changeset

  alias ThesisBackend.Products.Product

  @primary_key {:id, :binary_id, autogenerate: true}
  @non_required_fields [:id, :inserted_at, :updated_at]

  schema "variations" do
    field :fields, {:array, :map}
    field :custom_id, :string
    field :remain_quantity, :integer, default: 0
    field :retail_price, :integer, default: 0
    field :original_price, :integer, default: 0
    field :images, {:array, :string}
    field :is_hidden, :boolean, default: false
    field :is_removed, :boolean, default: false

    belongs_to(:product, Product, type: :binary_id, foreign_key: :product_id)

    timestamps()
  end

  def changeset(%__MODULE__{} = variation, attrs) do
    fields = __schema__(:fields) -- @non_required_fields

    variation
    |> cast(attrs, fields)
    |> unique_constraint([:product_id, :custom_id],
      name: :variations_product_id_custom_id_index,
      match: :prefix,
      message: "8001"
      )
  end

  def json(%__MODULE__{} = variation) do
    fields = __schema__(:fields)
    Map.take(variation, fields)
  end

  def json(variations) when is_list(variations) do
    Enum.map(variations, &json(&1))
  end

  def json(_), do: nil
end
