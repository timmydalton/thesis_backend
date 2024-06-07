defmodule ThesisBackendWeb.Plug.AccountPlug do
  import Plug.Conn

  alias ThesisBackend.Accounts
  alias ThesisBackend.Accounts.Account
  alias ThesisBackend.Token

  def init(opts), do: opts

  def call(conn, _opts) do
    jwt = for({"authorization", "Bearer " <> jwt} <- conn.req_headers, do: jwt) |> List.first()

    jwt = jwt || conn.req_cookies["jwt"]

    case Token.verify_and_validate(jwt) do
      {:ok, claims} ->
        account_id = Map.get(claims, "user_id")

        if !is_nil(account_id) do
          account = Accounts.get_account_by_id(account_id)
          |> Account.to_json()

          conn
          |> assign(:account, account)
        else
          conn
        end
      _ ->
        conn
    end
  end
end
