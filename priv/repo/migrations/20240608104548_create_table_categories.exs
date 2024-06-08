defmodule ThesisBackend.Repo.Migrations.CreateTableCategories do
  use Ecto.Migration

  def up do
    create table(:categories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :image, :string
      add :is_removed, :boolean, default: false
      add :parent_id, :binary_id
      add :position, :integer
      add :depth, :integer

      timestamps()
    end
  end

  def down do
    drop table(:categories)
  end
end
