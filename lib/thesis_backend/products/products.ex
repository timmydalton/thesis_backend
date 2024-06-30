defmodule ThesisBackend.Products do
  import Ecto.Query, warn: false

  alias ThesisBackend.Products.Product
  alias ThesisBackend.Variations.Variation
  alias ThesisBackend.Categories.{ProductCategory, Category}
  alias ThesisBackend.{Repo, Tools}

  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert(returning: true)
  end

  def update_product(%Product{} = product, attrs \\ %{}, opts \\ []) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  def get_all_products(page \\ 1, limit \\ 20, opts \\ []) do
    offset = (page - 1) * limit

    query =
      from(
        p in Product,
        where: p.is_removed == false
      )

    preload_variation =
      from(
        v in Variation,
        where: not v.is_removed
      )

    category_preload_query =
      ProductCategory
      |> join(:inner, [pc], c in Category, on: pc.category_id == c.id and not c.is_removed)
      |> where([pc], not pc.is_removed)
      |> select([pc, c], c)

    total_product =
      Repo.all(
        from(
          p in query,
          group_by: p.id,
          select: count("*")
        )
      )
      |> Enum.reduce(0, fn el, acc -> acc + el end)

    query = from(
      p in query,
      preload: [
        variations: ^preload_variation,
        categories: ^category_preload_query
      ],
      order_by: [desc: p.inserted_at]
    )

    products = Repo.all(query)

    {:ok, products, total_product}
  end

  def get_product_by_id(id) do
    variation_preload_query =
      Variation
      |> where([v], v.product_id == ^id and v.is_removed == false)

    category_preload_query =
      ProductCategory
      |> join(:inner, [pc], c in Category, on: pc.category_id == c.id and not c.is_removed)
      |> where([pc], not pc.is_removed)
      |> select([pc, c], c)

    Product
    |> where([p], not p.is_removed and p.id == ^id)
    |> preload(
      variations: ^variation_preload_query,
      categories: ^category_preload_query
    )
    |> Repo.one()
    |> Tools.get_record()
  end

  def remove_product_by_ids(ids) do
    Product
    |> where([p], p.id in ^ids and not p.is_removed)
    |> Repo.update_all(set: [is_removed: true])
  end

  def slugify(term) do
    term
    |> String.replace(String.codepoints("áàãạảAÁÀÃẠẢăắằẵặẳĂẮẰẴẶẲâầấẫậẩÂẤẦẪẬẨ"), "a")
    |> String.replace(String.codepoints("éèẽẹẻEÉÈẼẸẺêếềễệểÊẾỀỄỆỂ"), "e")
    |> String.replace(String.codepoints("íìĩịỉIÍÌĨỊỈ"), "i")
    |> String.replace(String.codepoints("óòõọỏOÓÒÕỌỎôốồỗộổÔỐỒỖỘỔơớờỡợởƠỚỜỠỢỞ"), "o")
    |> String.replace(String.codepoints("úùũụủUÚÙŨỤỦưứừữựửƯỨỪỮỰỬ"), "u")
    |> String.replace(String.codepoints("ýỳỹỵỷYÝỲỸỴỶ"), "y")
    |> String.replace(String.codepoints("dđĐD"), "d")
    |> String.downcase
  end

  def search_product_name(params) do
    limit = Tools.to_int(params["limit"] || "20")
    page = Tools.to_int(params["page"] || "1")
    term = params["term"] || ""
    offset = (page - 1) * limit

    term = slugify(term)

    query = Product
      |> where([p], fragment("vietnamese_unaccent(lower(?)) ILIKE ?", p.name, ^"%#{term}%") and not p.is_removed)
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

    variation_preload_query =
      Variation
      |> where([v], v.is_removed == false)

    category_preload_query =
      ProductCategory
      |> join(:inner, [pc], c in Category, on: pc.category_id == c.id and not c.is_removed)
      |> where([pc], not pc.is_removed)
      |> select([pc, c], c)

    query =
      query
      |> preload([p],
        variations: ^variation_preload_query,
        categories: ^category_preload_query
      )

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

    data =
      Enum.map(data, fn product ->
        Product.json(product)
      end)

    variations =
      Variation
      |> where([v], v.product_id in ^product_ids)
      |> Repo.all()

    {:ok, data, total_entries}
  end
end
