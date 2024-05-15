defmodule ThesisBackend.Repo do
  use Ecto.Repo,
    otp_app: :thesis_backend,
    adapter: Ecto.Adapters.Postgres
end
