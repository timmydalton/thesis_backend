defmodule ThesisBackend.Repo.Migrations.CreateTablePrdCategory do
  use Ecto.Migration

  def up do
    create table(:product_categories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :category_id, :binary_id
      add :is_removed, :boolean, default: false
      add :product_id, :binary_id

      timestamps()
    end

    create unique_index(:product_categories, [:category_id, :product_id], where: "is_removed = false")
  end

  def down do
    drop table(:product_categories)
  end
end
