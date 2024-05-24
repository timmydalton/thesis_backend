defmodule ThesisBackend.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  alias ThesisBackend.Accounts.Account

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "accounts" do
    field :username, :string
    field :password_hash, :string
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :phone_number, :string
    field :avatar, :string
    field :locale, :string
    field :access_token, :string
    field :refresh_token, :string
    field :status, :integer, default: 1
    field :settings, :map, default: %{}
    field :timezone, :string
    field :utc_offset, :integer
    field :role, :integer
    field :block_reason, :string

    timestamps()
  end

  def changeset(%Account{} = account, attrs) do
    account
    |> cast(attrs, [
      :username,
      :password_hash,
      :first_name,
      :last_name,
      :email,
      :phone_number,
      :avatar,
      :locale,
      :access_token,
      :refresh_token,
      :status,
      :settings,
      :timezone,
      :utc_offset,
      :role,
      :block_reason
    ])
    |> validate_required([:email])
    |> unique_constraint(:email,
      name: :accounts_email_index,
      message: "email_already_taken"
    )
  end

  def strict_changeset(%Account{} = account, attrs) do
    account
    |> changeset(attrs)
    |> cast(attrs, [
      :status,
      :phone_number,
      :email
    ])
  end

  def to_json(%Account{} = account) do
    Map.take(account, [
      :id,
      :username,
      :first_name,

      :last_name,
      :email,
      :phone_number,
      :avatar,
      :locale,
      :access_token,
      :refresh_token,
      :status,
      :settings,
      :timezone,
      :utc_offset,
      :role,
      :block_reason
    ])
  end

  def to_json(account) when is_map(account), do: to_json(struct(Account, account))

  def to_json(_), do: nil
end
