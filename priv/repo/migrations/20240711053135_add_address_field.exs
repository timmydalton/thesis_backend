defmodule ThesisBackend.Repo.Migrations.AddAddressField do
  use Ecto.Migration

  def up do
    alter table(:accounts) do
      add :address, :string
    end
  end

  def down do
    alter table(:accounts) do
      remove :address
    end
  end
end
