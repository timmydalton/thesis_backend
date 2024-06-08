defmodule ThesisBackend.Tags.ProductTag do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @non_required_fields [:id, :inserted_at, :updated_at]

  schema "product_tags" do
    field :name, :string
    field :is_removed, :boolean, default: false

    timestamps()
  end

  def changeset(%__MODULE__{} = product_tag, attrs) do
    fields = __schema__(:fields) -- @non_required_fields
    product_tag
    |> cast(attrs, fields)
  end

  def json(%__MODULE__{} = product_tag) do
    fields = __schema__(:fields)
    Map.take(product_tag, fields)
  end

  def json(product_tags) when is_list(product_tags) do
    Enum.map(product_tags, &json(&1))
  end

  def json(_), do: nil
end
