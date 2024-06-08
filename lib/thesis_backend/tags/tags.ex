defmodule ThesisBackend.Tags do
  import Ecto.Query, warn: false

  alias ThesisBackend.{ Tools, Repo }
  alias ThesisBackend.Tags.{ ProductTag }

  def create_or_update(get, create, update) do
    case get.() do
      {:error, _} -> create.()
      {:ok, v} -> update.(v)
    end
  end

  def create_product_tag(attrs) when is_map(attrs) do
    %ProductTag{}
    |> ProductTag.changeset(attrs)
    |> Repo.insert()
  end

  def update_product_tag(%ProductTag{} = product_tag, attrs) do
    product_tag
    |> ProductTag.changeset(attrs)
    |> Repo.update()
  end

  def get_product_tag_by_id(id) do
    ProductTag
    |> where([t], t.id == ^id and not t.is_removed)
    |> Repo.one()
    |> Tools.get_record()
  end

  def get_all_product_tags() do
    ProductTag
    |> where([t], not t.is_removed)
    |> limit(200)
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
    |> Tools.get_record()
  end
end
