defmodule ThesisBackend.Categories do
  import Ecto.Query, warn: false
  import ThesisBackend.Guards

  alias ThesisBackend.Categories.{Category, ProductCategory}
  alias ThesisBackend.{Repo, CategoryService, Tools}
  alias ThesisBackend.Variations.Variation
  alias ThesisBackend.Products.Product

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

  def create_product_category(attrs) do
    %ProductCategory{}
    |> ProductCategory.changeset(attrs)
    |> Repo.insert()
  end

  def update_product_category(%ProductCategory{} = product_category, attrs) do
    product_category
    |> ProductCategory.changeset(attrs)
    |> Repo.update()
  end

  def get_product_category(product_id, category_id) do
    ProductCategory
    |> where(
      [pc],
      pc.product_id == ^product_id and pc.category_id == ^category_id and not pc.is_removed
    )
    |> Repo.one()
    |> Tools.get_record()
  end

  def get_category_by_id(id) when is_empty(id), do: Tools.get_record(nil)

  def get_category_by_id(id) do
    Category
    |> where([c], c.id == ^id and not c.is_removed)
    |> Repo.one()
    |> Tools.get_record()
  end

  def get_category_ids(category_id) do
    category_tree_initial_query =
      Category
      |> where(
        [c],
        c.id == ^category_id and not c.is_removed
      )

    category_tree_recursion_query =
      Category
      |> join(:inner, [c], cte in "cte", on: c.parent_id == cte.id)
      |> where(
        [c],
        not c.is_removed
      )

    category_tree_query =
      category_tree_initial_query
      |> union_all(^category_tree_recursion_query)

    {"cte", Category}
    |> recursive_ctes(true)
    |> with_cte("cte", as: ^category_tree_query)
    |> Repo.all()
    |> Enum.map(& &1.id)
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
      |> where([p], p.is_hidden and not p.is_removed)
      |> Repo.aggregate(:count, :id)

    total_product_hidden =
      Product
      |> where([p], (not p.is_hidden or is_nil(p.is_hidden)) and not p.is_removed)
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

  def create_product_categories(ids_cate_create, product_id) do
    {success, error} =
      Enum.reduce(ids_cate_create, {[], []}, fn el, acc ->
        {s, e} = acc

        attrs = %{
          product_id: product_id,
          category_id: el,
        }

        get = fn ->
          get_product_category(product_id, el)
        end

        create = fn ->
          create_product_category(attrs)
        end

        update = fn product_category ->
          update_product_category(product_category, attrs)
        end

        create_or_update(get, create, update)
        |> case do
          {:ok, product_category} ->
            CategoryService.execute_command(
              "bulk_add_product_to_category",
              %{"ids" => [product_id], "id" => el},
              category: %{}
            )

            {s ++ [product_category.id], e}

          {:error, error} ->
            {s, e ++ [error]}
        end
      end)

    if length(error) == 0,
      do: {:ok, success},
      else: {:error, :create_product_categories_failed}
  end

  def remove_product_categories(ids_cate_rm, product_id) do
    Enum.each(ids_cate_rm, fn el ->
      get = fn ->
        get_product_category(product_id, el)
      end

      create = fn ->
        {:ok, :success}
      end

      update = fn product_category ->
        update_product_category(product_category, %{is_removed: true})
      end

      create_or_update(get, create, update)
      |> case do
        {:ok, product_category} -> product_category
        {:error, error} -> Repo.rollback(error)
      end
    end)

    {:ok, :success}
  end

  def get_products(category_id, params) do
    {:ok, category} = get_category_by_id(category_id)
    limit = Tools.to_int(params["limit"] || "20")
    page = Tools.to_int(params["page"] || "1")
    offset = (page - 1) * limit

    category_ids = get_category_ids(category_id)

    query = Product
      |> join(:left, [p], v in Variation, on: v.product_id == p.id and not v.is_removed)
      |> join(:left, [p],  pc in assoc(p, :categories))
      |> where([p, v, pc], not p.is_removed and pc.category_id in ^category_ids and not pc.is_removed)
      |> order_by([p], desc: p.inserted_at)

    query =
      query
      |> group_by([p], [
        p.id,
        p.name,
        p.is_hidden,
        p.inserted_at,
        p.custom_id,
        p.updated_at,
      ])

    get_total_entries = fn ->
      record =
        query
        |> select([p], %{total: fragment("COUNT(?) OVER ()", p.id)})
        |> Repo.all()
        |> List.first()

      (record || %{})
      |> Map.get(:total)
    end

    query =
      query
      |> select([p, v], %{
        id: p.id,
        name: p.name,
        is_hidden: p.is_hidden,
        inserted_at: p.inserted_at,
        updated_at: p.updated_at,
        custom_id: p.custom_id
      })

    query
      |> offset([p], ^offset)
      |> limit([p], ^limit)

    [data, total_entries] =
      Task.await_many([
        Task.async(fn ->
          Repo.all(query)
        end),
        Task.async(fn ->
          get_total_entries.()
        end)
      ])

    product_ids = Enum.map(data, & &1.id)

    variations =
      Variation
      |> where([v], v.product_id in ^product_ids)
      |> Repo.all()

    data =
      Enum.map(data, fn product ->
        variations = Enum.filter(variations, & &1.product_id == product.id) |> Variation.json()
        Map.put(product, :variations, variations)
      end)

    {:ok, data, total_entries}
  end
end
