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

    scope "/store" do
      scope "/products" do
        get "/all", ProductController, :all
        get "/all_by_category", ProductController, :get_all_product_by_category
        get "/:product_id", ProductController, :get_product_by_id
      end

      scope "/categories" do
        get "/all", CategoryController, :all
      end
    end

    scope "/admin" do


      scope "/products" do
        get "/all", ProductController, :all
        post "/create", ProductController, :create
        post "/update", ProductController, :update
        post "/hidden", ProductController, :change_hidden
        post "/remove", ProductController, :remove_products
        get "/:product_id", ProductController, :get_product_by_id

        scope "/product_tags" do
          post "/create_or_update", ProductController, :create_or_update_product_tag
          get "/all", ProductController, :get_all_product_tags
        end
      end

      scope "/categories" do
        get "/all", CategoryController, :all
        post "/create", CategoryController, :create
        post "/update", CategoryController, :update
        post "/delete", CategoryController, :delete
        post "/build_tree", CategoryController, :build_tree
      end

      scope "/content" do
        post "/b64", ContentController, :upload_base64
        post "/upload_file", ContentController, :upload_file
      end
    end
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
