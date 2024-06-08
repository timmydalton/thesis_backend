defmodule ThesisBackend.CategoryService do
  alias ThesisBackend.{Categories, Tools, Repo}

  def execute_command(name, data, opts \\ [])

  def execute_command("create_category", data, opts) do
    attrs = %{
      "id" => data["id"],
      "name" => String.trim(data["name"] || ""),
      "parent_id" => data["parent_id"],
    }

    existed_category =
      Categories.get_existed_category_by_name(attrs["id"], attrs["name"])
      |> case do
        {:ok, v} -> v
        _ -> nil
      end

    cond do
      Tools.is_empty?(attrs["name"]) ->
        {:error, %{message: "Name empty", message_code: 5000}}

      existed_category ->
        {:error, %{message: "Category with name existed", message_code: 5006}}

      true ->
        {:ok, result} = Categories.create_category(attrs)
    end
  end

  def execute_command("name_category", data, opts) do
    category = Keyword.get(opts, :category)

    attrs = %{"name" => String.trim(data["name"])}

    existed_category =
      Categories.get_existed_category_by_name(category.id, attrs["name"])
      |> case do
        {:ok, v} -> v
        _ -> nil
      end

    cond do
      Tools.is_empty?(attrs["name"]) ->
        {:error, %{message: "Name empty", message_code: 5000}}

      existed_category ->
        {:error, %{message: "Category with name existed", message_code: 5006}}

      true ->
        Categories.update_category(category, attrs)
    end
  end

  def execute_command("image_category", data, opts) do
    category = Keyword.get(opts, :category)

    {:ok, result} = Categories.update_category(category, %{image: data["image"]})
  end

  def execute_command("bulk_delete_category", data, opts) do
    data =
      Enum.map(data["ids"], fn el ->
        get = fn ->
          Categories.get_category_by_id(el)
        end

        create = fn ->
          {:ok, :success}
        end

        update = fn category ->
          Categories.update_category(category, %{is_removed: true})
        end

        Categories.create_or_update(get, create, update)
        |> case do
          {:ok, category} -> category
          {:error, error} -> Repo.rollback(error)
        end
      end)

    {:ok, data}
  end

  def execute_command("bulk_add_product_to_category", data, opts) do
    category = Keyword.get(opts, :category)

    pc =
      data["ids"]
      |> Enum.reverse()
      |> Enum.map(fn el ->
        attrs = %{
          product_id: el,
          category_id: data["id"],
        }

        get = fn ->
          Categories.get_product_category(el, data["id"])
        end

        create = fn ->
          Categories.create_product_category(attrs)
        end

        update = fn product_category ->
          {:ok, product_category}
        end

        Categories.create_or_update(get, create, update)
        |> case do
          {:ok, product_category} -> product_category
          {:error, error} -> Repo.rollback(error)
        end
      end)

    {:ok, :success}
  end

  def execute_command("bulk_remove_product_in_category", data, opts) do
    category = Keyword.get(opts, :category)

    pc =
      Enum.map(data["ids"], fn el ->
        get = fn ->
          Categories.get_product_category(el, data["id"])
        end

        create = fn ->
          {:ok, :success}
        end

        update = fn product_category ->
          Categories.update_product_category(product_category, %{is_removed: true})
        end

        Categories.create_or_update(get, create, update)
        |> case do
          {:ok, product_category} -> product_category
          {:error, error} -> Repo.rollback(error)
        end
      end)

    {:ok, :success}
  end

  def build_tree(categories, parent_id \\ nil) do
    categories
    |> Enum.reduce([], fn category, acc ->
      if category.parent_id == parent_id  do
        children = build_tree(categories, category.id)

        category =
          Map.merge(category, %{
            children: children,
          })

        acc ++ [category]
      else
        acc
      end
    end)
  end
end
