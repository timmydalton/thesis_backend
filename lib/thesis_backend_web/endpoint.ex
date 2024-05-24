defmodule ThesisBackendWeb.CrossOrigin do
  def get_origins() do
    if System.get_env("MIX_ENV") == "prod" do
      [

      ]
    else
      [
        "http://localhost:5173",
        "https://localhost:5173",
        "http://localhost:24679",
      ]
    end
  end
end

defmodule ThesisBackendWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :thesis_backend

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_thesis_backend_key",
    signing_salt: "D1aunB8N",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  plug Corsica,
    origins: ThesisBackendWeb.CrossOrigin.get_origins(),
    allow_methods: :all,
    max_age: 600,
    allow_headers: :all

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :thesis_backend,
    gzip: false,
    only: ThesisBackendWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :thesis_backend
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug ThesisBackendWeb.Router
end
