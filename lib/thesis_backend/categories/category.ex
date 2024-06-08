defmodule ThesisBackend.Categories.Category do
  use Ecto.Schema
  import Ecto.Changeset

  # alias ThesisBackend.Categories.ProductCategory
  alias BinaryToUUID
  alias ThesisBackend.Categories.Category

  @non_required_fields [:inserted_at, :updated_at]

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "categories" do
    field(:name, :string)
    field(:image, :string)

    field(:is_removed, :boolean, default: false)
    field(:parent_id, :binary_id)
    field(:position, :integer, default: 0)
    field(:depth, :integer, default: 0)

    field :children, {:array, :map}, virtual: true

    field :total_product_hidden, :integer, virtual: true
    field :total_product_visible, :integer, virtual: true

    # has_many(:product_categories, ProductCategory, foreign_key: :category_id)

    timestamps()
  end

  def changeset(%__MODULE__{} = category, attrs) do
    fields = __schema__(:fields) -- @non_required_fields

    category
    |> cast(attrs, fields)
    |> validate_required([:name])
  end

  def json(category, opts \\ [])
  def json(%__MODULE__{} = category, opts) do
    fields = __schema__(:fields)
    virtual_fields = __schema__(:virtual_fields)

    res = Map.take(category, fields ++ virtual_fields)

    res =
      Map.merge(res, %{
        children: json(category.children || [])
      })

    res
  end

  def json(categories, opts) when is_list(categories) do
    Enum.map(categories, &json(&1, opts))
  end

  def json(category, _opts) when is_map(category), do: category
end
