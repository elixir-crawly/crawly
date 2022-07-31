defmodule CrawldisPanel.Cluster do
  @moduledoc false
  alias CrawldisPanel.{
    Repo,
    Accounts.User,
    OauthAccessTokens
  }

  @oauth_config Application.get_env(:crawldis_panel, ExOauth2Provider)
  def get_access_token(%User{} = user) do
    ExOauth2Provider.AccessTokens.get_authorized_tokens_for(user, @oauth_config)
    |> List.first()
  end

  def create_access_token(%User{} = user) do
    ExOauth2Provider.AccessTokens.create_token(user, %{}, @oauth_config)
  end

  def verify_token(token) when is_binary(token) do
    ExOauth2Provider.authenticate_token(token, @oauth_config)
  end
end
