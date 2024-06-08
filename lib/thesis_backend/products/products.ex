defmodule ThesisBackend.Products do
  import Ecto.Query, warn: false

  alias ThesisBackend.Products.Product
  alias ThesisBackend.Variations.Variation
  alias ThesisBackend.{Repo, Tools}

  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert(returning: true)
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
        variations: ^preload_variation
      ]
    )

    products = Repo.all(query)

    {:ok, products, total_product}
  end

  def get_product_by_id(id) do
    variation_preload_query =
      Variation
      |> where([v], v.product_id == ^id and v.is_removed == false)

    Product
    |> where([p], not p.is_removed and p.id == ^id)
    |> preload(
      variations: ^variation_preload_query,
    )
    |> Repo.one()
    |> Tools.get_record()
  end
end
