defmodule ThesisBackend.Repo.Migrations.CreateFieldCustomItem do
  use Ecto.Migration

  def up do
    alter table(:orders) do
      add :custom_items, {:array, :map}
    end
  end

  def down do
    alter table(:orders) do
      remove :custom_items, {:array, :map}
    end
  end
end
