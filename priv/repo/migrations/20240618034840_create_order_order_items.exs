defmodule ThesisBackend.Repo.Migrations.CreateOrderOrderItems do
  use Ecto.Migration

  def up do
    create table(:orders, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, :binary_id
      add :bill_full_name, :string
      add :bill_phone_number, :string
      add :shipping_address, :map
      add :note, :string, default: ""
      add :status, :integer, default: 0

      add :shipping_fee, :integer, default: 0
      add :transfer_money, :integer, default: 0
      add :cash, :integer, default: 0
      add :invoice_value, :integer, default: 0
      add :display_id, :integer
      add :is_deleted, :boolean, default: false

      timestamps()
    end

    create table(:order_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :order_id, :binary_id
      add :variation_id, :binary_id
      add :variation_info, :map
      add :quantity, :integer
      add :is_deleted, :boolean, default: false

      timestamps()
    end

    execute("""
      CREATE OR REPLACE FUNCTION generate_order_display_id() RETURNS trigger
      LANGUAGE plpgsql AS
      $$BEGIN
          SELECT COALESCE(max(display_id)+1, 1) INTO NEW.display_id
            FROM orders;
          RETURN NEW;
      END;$$;
    """)

    execute("""
      CREATE TRIGGER generate_display_id
      BEFORE INSERT ON orders FOR EACH ROW
      EXECUTE PROCEDURE generate_order_display_id();
    """)
  end

  def down do
    drop table(:orders)
    drop table(:order_items)
  end
end
