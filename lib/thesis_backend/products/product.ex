defmodule ThesisBackend.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  alias ThesisBackend.Products.Product
  alias ThesisBackend.Variations.Variation

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "products" do
    field :name, :string
    field :description, :string
    field :custom_id, :string
    field :total_sold, :integer
    field :product_attributes, {:array, :map}
    field :image, :string
    field :is_removed, :boolean, default: false
    field :is_hidden, :boolean, default: false

    has_many(:variations, Variation, foreign_key: :product_id)

    timestamps()
  end

  def changeset(%Product{} = product, attrs) do
    product
    |> cast(attrs, [
      :name,
      :description,
      :custom_id,
      :total_sold,
      :product_attributes,
      :image,
      :is_removed,
      :is_hidden
    ])
    |> unique_constraint(:custom_id,
      name: :products_custom_id_index,
      message: "custom_id_taken"
    )
  end

  def json(%Product{} = product) do
    fields = __schema__(:fields) ++ __schema__(:virtual_fields)
    virtual_fields = __schema__(:virtual_fields)

    data = Map.take(product, fields ++ virtual_fields)

    data =
      case Map.fetch(product, :variations) do
        {:ok, %Ecto.Association.NotLoaded{}} ->
          data

        {:ok, value} ->
          variations = Variation.json(value)

          Map.put(data, :variations, variations)

        :error ->
          data
      end

    data
  end

  def json(products) when is_list(products) do
    Enum.map(products, &json(&1))
  end

  def json(product) when is_map(product), do: json(struct(Product, product))

  def json(_), do: nil
end
