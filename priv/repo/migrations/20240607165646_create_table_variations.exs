defmodule ThesisBackend.Repo.Migrations.CreateTableVariations do
  use Ecto.Migration

  def up do
    create table(:variations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :fields, {:array, :map}
      add :custom_id, :string
      add :remain_quantity, :integer
      add :retail_price, :integer, default: 0
      add :original_price, :integer, default: 0
      add :images, {:array, :string}
      add :is_hidden, :boolean, default: false
      add :is_removed, :boolean, default: false
      add :product_id, :binary_id, null: false

      timestamps()
    end

    create unique_index(:variations, [:custom_id], where: "is_removed = false")
    create unique_index(:variations, [:product_id, :custom_id], where: "is_removed = false")
    create index(:variations, [:product_id])
  end

  def down do
    drop table(:variations)
  end
end
