defmodule ThesisBackendWeb.Plug.AccountPlug do
  import Plug.Conn

  alias ThesisBackend.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    claims = conn.assigns.claims

    account_id = Map.get(claims, "account_id")
    account = Accounts.get_account_by_id(account_id)

    if account do
      conn
      |> assign(:account, account)
    else
      conn
      |> send_resp(401, "Unauthorized")
      |> halt()
    end
  end
end
