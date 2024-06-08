defmodule ThesisBackend.Categories do
  import Ecto.Query, warn: false
  import ThesisBackend.Guards

  alias ThesisBackend.Categories.Category
  alias ThesisBackend.{Repo, CategoryService, Tools}

  def create_or_update(get, create, update) do
    case get.() do
      {:error, _} -> create.()
      {:ok, v} -> update.(v)
    end
  end

  def create_category(attrs) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  def get_category_by_id(id) when is_empty(id), do: Tools.get_record(nil)

  def get_category_by_id(id) do
    Category
    |> where([c], c.id == ^id and not c.is_removed)
    |> Repo.one()
    |> Tools.get_record()
  end

  def get_all_category(params) do
    {page, limit} = Tools.get_page_limit_from_params(params)
    offset = (page - 1) * limit
    term = params["term"]

    query =
      Category
      |> where([c], not c.is_removed)

    query = if Tools.is_empty?(term), do: query, else: where(query, [c], ilike(c.name, ^"%#{term}%"))

    data =
      query
      |> offset([c], ^offset)
      |> limit([c], ^limit)
      |> order_by([c], fragment("position asc, inserted_at desc"))
      |> select([c], c)
      |> Repo.all()
      |> Enum.map(fn category -> if !Tools.is_empty?(term), do: Map.put(category, :parent_id, nil), else: category end)

    data = CategoryService.build_tree(data)

    total_entries = Repo.aggregate(query, :count, :id)

    categories = %{
      data: data,
      total_entries: total_entries,
      page: page,
      limit: limit,
      term: term
    }

    {:ok, categories}
  end

  def count_all_products(_params) do
    total_product_visible =
      Product
      |> where([p], p.is_hidden and not p.removed)
      |> Repo.aggregate(:count, :id)

    total_product_hidden =
      Product
      |> where([p], (not p.is_hidden or is_nil(p.is_hidden)) and not p.removed)
      |> Repo.aggregate(:count, :id)


    data = %{
      total_product_visible: total_product_visible,
      total_product_hidden: total_product_hidden
    }
    {:ok, data}
  end

  def get_existed_category_by_name(id, name) do
    Category
    |> where([c], c.id != ^id and c.name == ^name and not c.is_removed)
    |> limit([c], 1)
    |> Repo.one()
    |> Tools.get_record()
  end
end
