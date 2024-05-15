defmodule ThesisBackend.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ThesisBackendWeb.Telemetry,
      ThesisBackend.Repo,
      {DNSCluster, query: Application.get_env(:thesis_backend, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ThesisBackend.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ThesisBackend.Finch},
      # Start a worker by calling: ThesisBackend.Worker.start_link(arg)
      # {ThesisBackend.Worker, arg},
      # Start to serve requests, typically the last entry
      ThesisBackendWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ThesisBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ThesisBackendWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
