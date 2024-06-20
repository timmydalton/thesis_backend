defmodule ThesisBackendWeb.Api.ProductController do
  use ThesisBackendWeb, :controller

  alias Ecto.Multi

  alias ThesisBackend.Tools
  alias ThesisBackend.Products.Product
  alias ThesisBackend.Tags.ProductTag
  alias ThesisBackend.{ Products, Tags, Variations, Repo, Categories }

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
      |> Multi.run(:product_categories, fn _, %{product: product} ->
        Categories.create_product_categories(product_params["categories"], product.id)
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
          message = Tools.get_error_message_from_changeset(changset, :not_get_key)

        {:failed, :with_reason,
          %{message_code: message, message: "Error create_or_update variation"}}

        {:error, :product, changset, _} ->
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

  def update(conn, %{ "product_params" => product_params } = _params) do
    ids_variation =
      product_params["variations"]
      |> Enum.map(fn el -> el["id"] end)
      |> Enum.filter(fn el -> !Tools.is_empty?(el) end)

    ids_categories = product_params["categories"]

    multi =
      Multi.new()
      |> Multi.run(:product, fn _, _ ->
        Products.get_product_by_id(product_params["product_id"])
      end)
      |> Multi.run(:new_product, fn _, %{product: product} ->
        Products.update_product(product, product_params)
      end)
      |> Multi.run(:ids_variation_rm, fn _, %{product: product} ->
        Variations.get_all_ids_variation_removed(product.id, ids_variation)
      end)
      |> Multi.run(:rm_variations, fn _, %{product: product, ids_variation_rm: ids_variation_rm} ->
        Variations.remove_variation_by_ids(product.id, ids_variation_rm)
      end)
      |> Multi.run(:variations, fn _, %{new_product: new_product} ->
        Variations.create_or_update_variations(
          new_product,
          product_params["variations"],
          "update"
        )
      end)
      |> Multi.run(:rm_categories, fn _, %{product: product} ->
        ids_cate_rm =
          Enum.filter(product.categories, fn el -> !Enum.member?(ids_categories, el.id) end)

        ids_cate_rm = Enum.map(ids_cate_rm, fn el -> el.id end)

        Categories.remove_product_categories(ids_cate_rm, product.id)
      end)
      |> Multi.run(:product_categories, fn _, %{product: product} ->
        id_categories = product.categories |> Enum.map(fn el -> el.id end)

        _ids_cate_create =
          Enum.filter(ids_categories, fn el -> !Enum.member?(id_categories, el) end)

        Categories.create_product_categories(ids_categories, product.id)
      end)

    case Repo.transaction(multi) do
      {:ok, result} ->
        case Products.get_product_by_id(result.new_product.id) do
          {:ok, product} ->
            {:success, :with_data, "product", Product.json(product)}

          {:error, error} ->
            {:failed, :with_reason, error}
        end

      {:error, :product, changset, _} ->
        message = Tools.get_error_message_from_changeset(changset, :not_get_key)

        {:failed, :with_reason,
          %{message_code: message, message: "Error create_or_update product"}}

      {:error, :variations, changset, _} ->
        message = Tools.get_error_message_from_changeset(changset, :not_get_key)

        {:failed, :with_reason,
          %{message_code: message, message: "Error create_or_update variation"}}

      {:error, _, changset, _} ->
        message = Tools.get_error_message_from_changeset(changset, :not_get_key)
        {:failed, :with_reason, message}

      {:error, reason} ->
        reason
    end
  end

  def get_product_by_id(_conn, %{"product_id" => product_id} = _params) do
    with {:ok, product} <- Products.get_product_by_id(product_id) do

      product = Product.json(product)
      {:success, :with_data, "product", product}
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

  def change_hidden(_conn, %{"data" => data} = params) do
    multi =
      Multi.new()
      |> Multi.run(:update, fn _, _ ->
        {errors, products} =
          Enum.reduce(data, {[], []}, fn el, acc ->
            {e, s} = acc

            product = Repo.get_by(Product, %{id: el["product_id"]})

            if product do
              Products.update_product(product, %{is_hidden: el["is_hidden"]})
              |> case do
                {:ok, v} -> {e, s ++ [v]}
                {:error, changeset} -> {e ++ [changeset.errors], s}
              end
            else
              {e ++ [:error], s}
            end
          end)

        if errors == [], do: {:ok, products}, else: {:error, errors}
      end)

    Repo.transaction(multi)
      |> case do
        {:ok, res} ->
          products = Product.json(res.update)

          {:success, :with_data, "products", products}

        _ ->
          {:failed, :with_reason, "Something went wrong!"}
      end
  end

  def remove_products(conn, params) do
    ids = params["ids"]

    multi =
      Multi.new()
      |> Multi.run(:products, fn _, _ ->
        Products.remove_product_by_ids(ids)
        {:ok, :pass}
      end)

    case Repo.transaction(multi) do
      {:ok, res} ->
        Task.async(fn ->
          Variations.remove_variations_by_product_ids(ids)
        end)

        {:success, :success_only}

      _ ->
        {:failed, :with_reason, "Something went wrong!"}
    end
  end

  def get_all_product_by_category(conn, %{"page" => page, "limit" => limit, "category_id" => category_id} = params) do
    with {:ok, products, total_product} <-
      Categories.get_products(category_id, params) do

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
