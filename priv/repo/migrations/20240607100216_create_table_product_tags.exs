defmodule ThesisBackend.Repo.Migrations.CreateTableProductTags do
  use Ecto.Migration

  def up do
    create table(:product_tags, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :is_removed, :boolean, default: false

      timestamps()
    end

    create unique_index(:product_tags, [:name], where: "(name IS NOT NULL) AND ((is_removed IS NULL) OR (NOT is_removed))")
  end

  def down do
    drop table(:product_tags)

    drop_if_exists unique_index(:product_tags, [:name], where: "(name IS NOT NULL) AND ((is_removed IS NULL) OR (NOT is_removed))")
  end
end
