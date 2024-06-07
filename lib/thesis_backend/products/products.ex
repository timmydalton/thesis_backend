defmodule ThesisBackend.Products do
  import Ecto.Query, warn: false

  alias ThesisBackend.Products.Product
  alias ThesisBackend.{Repo}

  def get_all_products(page \\ 1, limit \\ 20, opts \\ []) do
    offset = (page - 1) * limit

    query =
      from(
        p in Product,
        where: p.is_removed == false
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

    products = Repo.all(query)

    {:ok, products, total_product}
  end
end
