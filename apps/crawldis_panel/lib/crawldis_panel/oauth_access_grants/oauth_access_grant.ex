defmodule CrawldisPanel.OauthAccessGrants.OauthAccessGrant do
  use Ecto.Schema
  use ExOauth2Provider.AccessGrants.AccessGrant, otp_app: :crawldis_panel

  schema "oauth_access_grants" do
    access_grant_fields()

    timestamps()
  end
end
