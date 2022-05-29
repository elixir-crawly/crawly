defmodule CrawldisPanel.OauthApplications.OauthApplication do
  use Ecto.Schema
  use ExOauth2Provider.Applications.Application, otp_app: :crawldis_panel

  schema "oauth_applications" do
    application_fields()

    timestamps()
  end
end
