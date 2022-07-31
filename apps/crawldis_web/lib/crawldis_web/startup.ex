defmodule CrawldisWeb.Startup do
  @moduledoc """
  Startup actions performed by the web server.
  """
  use Task
  require Logger
  alias CrawldisPanel.{Accounts, Cluster}

  def start_link(_arg) do
    Task.start_link(__MODULE__, :run, [])
  end

  def run() do
    [
      created_cluster_tokens: ensure_each_user_has_cluster_access_token()
    ]
  end

  defp ensure_each_user_has_cluster_access_token do
    for user <- Accounts.list_users(),
        Cluster.get_access_token(user) == nil do
      # create an access token
      Logger.info("Creating cluster access token for #{user.name}")
      {:ok, token} = Cluster.create_access_token(user)
      token
    end
  end
end
