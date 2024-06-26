# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :thesis_backend,
  ecto_repos: [ThesisBackend.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :thesis_backend, ThesisBackendWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ThesisBackendWeb.ErrorHTML, json: ThesisBackendWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ThesisBackend.PubSub,
  live_view: [signing_salt: "zZLpITAP"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :thesis_backend, ThesisBackend.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  thesis_backend: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.0",
  thesis_backend: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Use Aws.S3
config :ex_aws,
  access_key_id: "OCL8M344IA6L3FSKRC0R",
  secret_access_key: "EqwUIKBRZDbRdtxkABW2bXVckeaVmLPqrmcIGJQ0",
  region: "vn-hn-cmc"

config :ex_aws, :s3,
  scheme: "https://",
  host: "statics.pancake.vn",
  region: "vn-north-vtpv",
  virtual_host: true

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
