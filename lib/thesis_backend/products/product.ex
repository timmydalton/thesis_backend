defmodule ThesisBackend.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  alias ThesisBackend.Products.Product

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "products" do
    field :name, :string
    field :description, :string
    field :display_id, :string
    field :total_sold, :integer
    field :slug, :string
    field :product_attributes, {:array, :map}
    field :image, :string
    field :is_removed, :boolean, default: false
    field :is_hidden, :boolean, default: false

    timestamps()
  end

  def changeset(%Product{} = product, attrs) do
    product
    |> cast(attrs, [
      :name,
      :description,
      :display_id,
      :total_sold,
      :slug,
      :product_attributes,
      :image,
      :is_removed,
      :is_hidden
    ])
    |> unique_constraint(:display_id,
      name: :products_display_id_index,
      message: "display_id_taken"
    )
    |> unique_constraint(:slug,
      name: :products_slug_index,
      message: "slug_taken"
    )
  end

  def to_json(%Product{} = product) do
    Map.take(product, [
      :name,
      :description,
      :display_id,
      :total_sold,
      :slug,
      :product_attributes,
      :image,
      :is_removed,
      :is_hidden
    ])
  end

  def to_json(products) when is_list(products) do
    Enum.map(products, &to_json(&1))
  end

  def to_json(product) when is_map(product), do: to_json(struct(Product, product))

  def to_json(_), do: nil
end
