defmodule CrawldisWeb.StartupTest do
  use CrawldisWeb.ConnCase, async: false

  setup do
    AccountsFixtures.user_fixture()

    {:ok, results} =
      Task.async(CrawldisWeb.Startup, :run, [])
      |> Task.yield()

    {:ok, results}
  end

  test "user should have a cluster access token", %{
    conn: conn,
    created_cluster_tokens: [token]
  } do
    {:ok, view, _html} = live(conn, "/")

    assert render(view) =~ token.token
  end
end
