defmodule CercleApi.Router do
  use CercleApi.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_secure_browser_headers
  end

  pipeline :basic_auth do
    plug BasicAuth, use_config: {:cercleApi, :basic_auth}
  end

  pipeline :api_auth do
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.LoadResource
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

	pipeline :browser_auth do
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource
  end

  pipeline :require_login do
    plug Guardian.Plug.EnsureAuthenticated, handler: CercleApi.GuardianErrorHandler
    plug CercleApi.Plugs.CurrentUser
  end

  pipeline :already_authenticated do
    plug Guardian.Plug.EnsureNotAuthenticated, handler: CercleApi.GuardianAlreadyAuthenticatedHandler
  end

  scope "/", CercleApi do
    pipe_through [:browser, :browser_auth, :already_authenticated]
    get "/", PageController, :index
    get "/login", SessionController, :new
    post "/login", SessionController, :create
    get "/register", RegistrationController, :new
    post "/register", RegistrationController, :create

    get "/forget-password", PasswordController, :forget_password
    post "/reset-password", PasswordController, :reset_password
    get "/password/reset/:password_reset_code/confirm", PasswordController, :confirm
    post "/password/reset/:password_reset_code/confirm", PasswordController, :confirm_submit
  end

  scope "/", CercleApi do
    pipe_through [:browser, :browser_auth, :require_login]

    get "/logout", SessionController, :delete
    get "/settings/profile_edit", SettingsController, :profile_edit
    put "/settings/profile_update", SettingsController, :profile_update
    get "/settings/company_edit", SettingsController, :company_edit
    put "/settings/company_update", SettingsController, :company_update
    get "/settings/team_edit", SettingsController, :team_edit
    put "/settings/team_update", SettingsController, :team_update
    get "/settings/fields_edit", SettingsController, :fields_edit
    put "/settings/fields_update", SettingsController, :fields_update

    get "/contact", ContactController, :index
	  get "/contact/new", ContactController, :new
    get "/contact/:id", ContactController, :show
    
    resources "/board", BoardController
    get "/activity", ActivityController, :index
    get "/import", ContactController, :import
    
  end

  scope "/", CercleApi do
    pipe_through [:api, :api_auth]



    get "/api/v2/timeline_events", APIV2.TimelineEventController, :index
    post "/api/v2/timeline_events", APIV2.TimelineEventController, :create
    
    post "/api/v2/register", APIV2.UserController, :create
    post "/api/v2/login", APIV2.SessionController, :create

    resources "/api/v2/contact", APIV2.ContactController
    put "/api/v2/contact/:id/update_tags", APIV2.ContactController, :update_tags

    resources "/api/v2/companies", APIV2.CompanyController
    resources "/api/v2/organizations", APIV2.OrganizationController
    resources "/api/v2/activity", APIV2.ActivityController
    resources "/api/v2/opportunity", APIV2.OpportunityController
    resources "/api/v2/board", APIV2.BoardController
    resources "/api/v2/board_column", APIV2.BoardColumnController
    
    post "/api/v2/webhook", APIV2.WebhookController, :create
    post "/api/v2/import-data", APIV2.ContactController, :import_data
    post "/api/v2/view_uploaded_data", APIV2.ContactController, :view_uploaded_data
    post "/api/v2/contact_create", APIV2.ContactController, :contact_create
    post "/api/v2/import_organization", APIV2.OrganizationController, :import_organization

  end

	scope "/admin" , CercleApi.Admin,  as: :admin do
    pipe_through :browser # Use the default browser stack
    pipe_through :basic_auth

    resources "/users", UserController
    resources "/companies", CompanyController
    #resources "/company_services", CompanyServiceController
	end
end
