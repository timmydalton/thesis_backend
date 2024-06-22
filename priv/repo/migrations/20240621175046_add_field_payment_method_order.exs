defmodule ThesisBackend.Repo.Migrations.AddFieldPaymentMethodOrder do
  use Ecto.Migration

  def up do
    alter table(:orders) do
      add :payment_method, :integer, default: 0
    end
  end

  def down do
    alter table(:orders) do
      remove :payment_method, :integer, default: 0
    end
  end
end
