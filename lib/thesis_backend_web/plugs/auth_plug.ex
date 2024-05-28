defmodule ThesisBackendWeb.Plug.AuthPlug do
  import Plug.Conn

  alias ThesisBackend.Token

  def init(opts), do: opts

  def call(conn, _opts) do
    jwt = for({"authorization", "Bearer " <> jwt} <- conn.req_headers, do: jwt) |> List.first()

    jwt = jwt || conn.req_cookies["jwt"]

    case Token.verify_and_validate(jwt) do
      {:ok, claims} ->
        conn
        |> assign(:claims, claims)

      _ ->
        conn
        |> send_resp(401, "Unauthorized")
        |> halt()
    end
  end
end
