defmodule ThesisBackendWeb.Api.CategoryController do
  use ThesisBackendWeb, :controller

  alias ThesisBackend.{ Repo, Tools, Categories, CategoryService }
  alias ThesisBackend.Categories.Category

  def all(conn, params) do
    with {:ok, categories} <- Categories.get_all_category(params) do
      data =
        Category.json(categories.data)

      categories = Map.put(categories, :data, data)
      {:success, :with_data, "categories", categories}
    end
  end

  def create(conn, params) do
    execute_command(conn, params)
  end

  def update(conn, params) do
    execute_command(conn, params)
  end

  def delete(conn, params) do
    execute_command(conn, params)
  end

  def execute_command(conn, params) do
    Repo.transaction(fn ->
      Enum.each(params["commands"], fn el ->
        category =
          Categories.get_category_by_id(el["data"]["id"])
          |> case do
            {:ok, value} -> value
            _ -> nil
          end

        CategoryService.execute_command(el["name"], el["data"], category: category)
        |> case do
          {:ok, value} ->
            {:ok, value}

          {:error, error} ->
            Repo.rollback(error)
        end
      end)
    end)
    |> case do
      {:ok, _} ->
        {:success, :with_data, "test", %{}}

      {:error, %Ecto.Changeset{errors: [name: _]}} ->
        {:failed, :with_reason, %{message_code: 5000, message: "Name required"}}

      {:error, %{message: message, message_code: message_code}} ->
        {:failed, :with_reason, %{message_code: message_code, message: message}}

      error ->
        {:failed, :with_reason, "Something went wrong"}
        IO.inspect(error, label: "labelll")
    end
  end

  def build_tree(conn, params) do
    Repo.transaction(fn ->
      tree_data = params["tree_data"] || []

      Enum.each(tree_data, fn el ->
        %{"id" => id, "parent_id" => parent_id} = el

        category =
          Categories.get_category_by_id(id)
          |> case do
            {:ok, value} -> value
            _ -> Repo.rollback(:category_not_existed)
          end

        Categories.update_category(category, %{
          "parent_id" => parent_id,
          "position" => el["position"],
          "depth" => el["depth"] || 0,
        })
        |> case do
          {:ok, v} -> {:ok, v}
          error -> Repo.rollback(error)
        end
      end)
    end)
    |> case do
      {:ok, _} ->
        {:success, :with_data, "test", %{}}
    end
  end
end
