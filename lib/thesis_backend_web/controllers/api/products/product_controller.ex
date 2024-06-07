defmodule ThesisBackendWeb.Api.ProductController do
  use ThesisBackendWeb, :controller

  alias ThesisBackend.Tools
  alias ThesisBackend.Products.Product
  alias ThesisBackend.Products

  def all(conn, %{"page" => _page, "limit" => _limit} = params) do
    {page, limit} = Tools.get_page_limit_from_params(params)

    with {:ok, products, total_product} <-
           Products.get_all_products(page, limit) do
      products = Product.to_json(products)

      json(conn, %{
        success: true,
        products: products,
        total_product: total_product,
        page: page,
        limit: limit
      })
    end
  end
end
