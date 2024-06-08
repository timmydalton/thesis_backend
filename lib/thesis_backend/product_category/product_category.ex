defmodule ThesisBackend.Categories.ProductCategory do
  use Ecto.Schema
  import Ecto.Changeset

  alias ThesisBackend.Products.Product

  @primary_key {:id, :binary_id, autogenerate: true}
  @non_required_fields [:id, :inserted_at, :updated_at]

  schema "product_categories" do
    field :category_id, :binary_id
    field :is_removed, :boolean, default: false

    field :total_product_hidden, :integer, virtual: true
    field :total_product_visible, :integer, virtual: true

    belongs_to :product, Product, type: Ecto.UUID
    timestamps(type: :naive_datetime_usec)
  end

  def changeset(%__MODULE__{} = product_category, attrs) do
    fields = __schema__(:fields) -- @non_required_fields

    product_category
    |> cast(attrs, fields)
  end

  def json(%__MODULE__{} = product_category) do
    fields = __schema__(:fields)
    data = Map.take(product_category, fields)

    data
  end

  def json(product_categories) when is_list(product_categories) do
    Enum.map(product_categories, &json(&1))
  end

  def json(_), do: nil
end
