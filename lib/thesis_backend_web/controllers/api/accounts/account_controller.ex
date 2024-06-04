defmodule ThesisBackendWeb.Api.AccountController do
  use ThesisBackendWeb, :controller

  alias ThesisBackend.Accounts
  alias ThesisBackend.Accounts.Account
  alias ThesisBackend.Tools

  def get_account(conn, _params) do
    user = Map.get(conn.assigns, :account)

    res = if Tools.is_empty?(user), do: %{}, else: user

    {:success, :with_data, res}
  end

  def sign_up_account(_conn, params) do
    username = Map.get(params, "username")
    password = Map.get(params, "password")

    case Accounts.check_user_exist(username) do
      0 ->
        case Accounts.create_new_account(username, password) do
          {:ok, user} ->
            token = Accounts.generate_token(user.id)
            user = user
              |> Account.to_json()
              |> Map.put(:access_token, token)
            {:success, :with_data, user}
          _ ->
            {:failed, :with_reason, "something went wrong"}
        end
      _ ->
        {:failed, :with_reason, "existed"}
    end
  end

  def sign_in_account(_conn, params) do
    username = Map.get(params, "username")
    password = Map.get(params, "password")

    case Accounts.sign_in(username, password) do
      {:ok, user} ->
        {:success, :with_data, user}
      _ ->
        {:failed, :with_reason, "not_found"}
    end
  end
end
