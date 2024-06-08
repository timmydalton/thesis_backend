defmodule ThesisBackendWeb.Api.ProductController do
  use ThesisBackendWeb, :controller

  alias Ecto.Multi

  alias ThesisBackend.Tools
  alias ThesisBackend.Products.Product
  alias ThesisBackend.Tags.ProductTag
  alias ThesisBackend.{ Products, Tags, Variations, Repo }

  def all(conn, %{"page" => _page, "limit" => _limit} = params) do
    {page, limit} = Tools.get_page_limit_from_params(params)

    with {:ok, products, total_product} <-
           Products.get_all_products(page, limit) do
      products = Product.json(products)

      json(conn, %{
        success: true,
        products: products,
        total_product: total_product,
        page: page,
        limit: limit
      })
    end
  end

  def create(conn, %{ "product_params" => product_params } = _params) do
    multi =
      Multi.new()
      |> Multi.run(:product, fn _, _ ->
        Products.create_product(product_params)
      end)
      |> Multi.run(:variations, fn _, %{product: product} ->
        Variations.create_or_update_variations(
          product,
          product_params["variations"],
          "create"
        )
      end)

      case Repo.transaction(multi) do
        {:ok, result} ->
          case Products.get_product_by_id(result.product.id) do
            {:ok, product} ->
              {:success, :with_data, "product", Product.json(product)}

            {:error, error} ->
              {:failed, :with_reason, error}
          end

        {:error, :variations, changset, _} ->
          IO.inspect(changset, label: "changesettt")
          message = Tools.get_error_message_from_changeset(changset, :not_get_key)

        {:failed, :with_reason,
          %{message_code: message, message: "Error create_or_update variation"}}

        {:error, :product, changset, _} ->
          IO.inspect(changset, label: "changesettt")
          message = Tools.get_error_message_from_changeset(changset, :not_get_key)

        {:failed, :with_reason,
          %{message_code: message, message: "Error create_or_update product"}}

        {:error, _, changset, _} ->
          message = Tools.get_error_message_from_changeset(changset, :not_get_key)
          {:failed, :with_reason, message}

        {:error, reason} ->
          reason
      end
  end

  # product tag
  def get_all_product_tags(_conn, params) do
    with {:ok, tags} <- Tags.get_all_product_tags() do

      {:success, :with_data, "product_tags", ProductTag.json(tags)}
    end
  end

  def create_or_update_product_tag(_conn, params) do
    name = params["name"]
    id = params["id"] || Ecto.UUID.generate()

    attrs = %{
      "id" => id,
    }

    attrs =
      if params["is_removed"],
        do: Map.put(attrs, "is_removed", params["is_removed"]),
        else: Map.put(attrs, "name", name)

    get = fn -> Tags.get_product_tag_by_id(id) end
    update = fn product_tag -> Tags.update_product_tag(product_tag, attrs) end
    create = fn -> Tags.create_product_tag(attrs) end

    Tags.create_or_update(get, create, update)
    |> case do
      {:ok, product_tag} ->
        Task.async(fn ->
          if params["is_removed"],
            do: Products.update_product_when_remove_tag(id)
        end)

        {:success, :with_data, "product_tag", ProductTag.json(product_tag)}

      _ -> {:failed, :with_reason, "Error create or update tag"}
      end

  end
end
