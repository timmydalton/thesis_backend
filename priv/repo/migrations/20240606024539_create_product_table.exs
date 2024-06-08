defmodule ThesisBackend.Repo.Migrations.CreateProductTable do
  use Ecto.Migration

  def up do
    create table(:products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :custom_id, :string
      add :total_sold, :integer
      add :product_attributes, {:array, :map}
      add :image, :text
      add :is_removed, :boolean, default: false
      add :is_hidden, :boolean, default: false

      timestamps()
    end

    create unique_index(:products, [:custom_id], where: "is_removed = false")
  end

  def down do
    drop table(:products)
  end
end
