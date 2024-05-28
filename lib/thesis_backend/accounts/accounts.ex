defmodule ThesisBackend.Accounts do
  import Ecto.Query, warn: false

  alias ThesisBackend.Accounts.Account
  alias ThesisBackend.{Repo, Token}

  def update_account(user_id, attrs) do
    query =
      from a in Account,
      where: a.id == ^user_id

    query
      |> Repo.one()
      |> case do
        nil ->
          nil
        acc ->
          acc
            |> Account.changeset(attrs)
            |> Repo.update()
      end
  end

  def check_user_exist(username) do
    query =
      from a in Account,
      where: a.username == ^username,
      select: count(a.id)

    query
    |> Repo.one()
  end

  def create_new_account(username, password) do
    password_hash = Bcrypt.hash_pwd_salt(password)

    attrs = %{
      username: username,
      password_hash: password_hash,
      status: 1
    }

    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  def sign_in(username, password) do
    query =
      from a in Account,
      where: a.username == ^username

    user = query
    |> Repo.one()
    |> case do
      nil ->
        nil
      a ->
        a
    end

    if !is_nil(user) && Bcrypt.verify_pass(password, user.password_hash) do
      token = generate_token(user.id)
      user = user
        |> Account.to_json()
        |> Map.put(:access_token, token)

      {:ok, user}
    else
      nil
    end
  end

  def generate_token(user_id) do
    now = NaiveDateTime.utc_now() |> Timex.shift(hours: 7)
    extra_claims = %{"user_id" => user_id, "time" => now}

    token = Token.generate_and_sign!(extra_claims)

    attrs = %{
      access_token: token
    }

    update_account(user_id, attrs)

    token
  end

  def get_account_by_id(id) do
    query =
      from a in Account,
      where: a.id == ^id

    query
    |> Repo.one()
  end
end
