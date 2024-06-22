defmodule ThesisBackend.Accounts do
  import Ecto.Query, warn: false

  alias ThesisBackend.Accounts.Account
  alias ThesisBackend.{Repo, Token, Tools}

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
        |> Account.json()
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

  def get_insight_account_time(params) do
    {start_time, end_time} =  {NaiveDateTime.from_iso8601!(params["startTime"]), NaiveDateTime.from_iso8601!(params["endTime"])}
    raw_query = """
      SELECT count(accounts.id), day::date
      FROM
        generate_series(
          date('#{Timex.shift(start_time, hours: 7)}'),
          date('#{Timex.shift(end_time, hours: 7)}'),
          '1 day'::interval
        ) day
      left join (
        select * from accounts
        where accounts.inserted_at >= '#{NaiveDateTime.to_iso8601(start_time)}' and
        accounts.inserted_at <= '#{NaiveDateTime.to_iso8601(end_time)}'
      ) as accounts
      on date(accounts.inserted_at + interval '7' hour) = day
      group by day
      order by day asc
    """

    Tools.convert_result_query_insight(raw_query)
  end
end
