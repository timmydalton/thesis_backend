defmodule ThesisBackend.Repo.Migrations.CreateOrderOrderItems do
  use Ecto.Migration

  def up do
    create table(:orders) do
      add :account_id, :binary_id
      add :bill_full_name, :string
      add :bill_phone_number, :string
      add :shipping_address, :map
      add :note, :text, default: ""
      add :status, :integer, default: 0
      add :form_data, :map

      add :shipping_fee, :integer, default: 0
      add :transfer_money, :integer, default: 0
      add :cash, :integer, default: 0
      add :invoice_value, :integer, default: 0
      add :display_id, :integer
      add :is_deleted, :boolean, default: false

      timestamps()
    end

    create table(:order_items) do
      add :order_id, :integer
      add :variation_id, :binary_id
      add :variation_info, :map
      add :quantity, :integer
      add :is_deleted, :boolean, default: false

      timestamps()
    end
  end

  def down do
    drop table(:orders)
    drop table(:order_items)
  end
end
