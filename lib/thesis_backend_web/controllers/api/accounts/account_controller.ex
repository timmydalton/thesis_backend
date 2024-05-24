defmodule ThesisBackendWeb.Api.AccountController do
  use ThesisBackendWeb, :controller

  def sign_in_account(conn, params) do
    IO.inspect(conn)
    IO.inspect(params)

    {:success, :success_only}
  end
end
