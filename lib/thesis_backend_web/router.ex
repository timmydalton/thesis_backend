defmodule ThesisBackendWeb.Router do
  use ThesisBackendWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :account do
    plug ThesisBackendWeb.Plug.AccountPlug
  end

  scope "/", ThesisBackendWeb do
    pipe_through :browser
  end

  scope "/api", ThesisBackendWeb.Api do
    pipe_through [:api, :account]

    get "/@me", AccountController, :get_account
  end

  scope "/auth", ThesisBackendWeb.Api do
    pipe_through [:api]

    post "/signup", AccountController, :sign_up_account
    post "/signin", AccountController, :sign_in_account
  end

  # Other scopes may use custom stacks.
  # scope "/api", ThesisBackendWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:thesis_backend, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ThesisBackendWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
