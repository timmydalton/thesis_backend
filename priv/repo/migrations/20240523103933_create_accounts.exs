defmodule ThesisBackend.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def up do
    create table(:accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :username, :string, null: false
      add :password_hash, :string, null: false
      add :first_name, :string
      add :last_name, :string
      add :email, :string
      add :phone_number, :string
      add :avatar, :string
      add :locale, :string, default: "vi"
      add :access_token, :text
      add :refresh_token, :text
      add :status, :integer
      add :settings, :map
      add :timezone, :string
      add :utc_offset, :integer
      add :role, :integer
      add :block_reason, :text

      timestamps()
    end
  end

  def down do
    drop table(:accounts)
  end
end
