defmodule ThesisBackendWeb.Api.AccountController do
  use ThesisBackendWeb, :controller

  alias ThesisBackend.Accounts
  alias ThesisBackend.Accounts.Account
  alias ThesisBackend.Tools

  def get_account(conn, _params) do
    user = (Map.get(conn.assigns, :account) || %{})
      |> Map.take([:avatar, :email, :first_name, :last_name, :id, :locale, :phone_number, :role, :status, :settings, :username])

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
              |> Account.json()
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

  def update_account(conn, params) do
    user = (Map.get(conn.assigns, :account) || %{})

    if !Tools.is_empty?(user) do
      params = Tools.to_atom_keys_map(params)

      case Accounts.update_account(user.id, params) do
        {:ok, user} ->
          user = user
          |> Account.json()

          {:success, :with_data, user}

        _ ->
          {:failed, :with_reason, "update_failed"}
      end
    else
      {:failed, :with_reason, "no_account"}
    end
  end
end
