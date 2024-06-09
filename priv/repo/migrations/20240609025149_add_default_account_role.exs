defmodule ThesisBackend.Repo.Migrations.AddDefaultAccountRole do
  use Ecto.Migration

  def up do
    alter table(:accounts) do
      remove :role
    end

    alter table(:accounts) do
      add :role, :integer, default: 1, null: false
    end
  end

  def down do
    alter table(:accounts) do
      remove :role
    end

    alter table(:accounts) do
      add :role, :integer
    end
  end
end
