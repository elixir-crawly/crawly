defmodule CrawldisWeb.HomeLiveTest do
  use CrawldisWeb.ConnCase
  use Mimic
  setup :set_mimic_global

  setup do
    user = AccountsFixtures.user_fixture()

    Task.async(CrawldisWeb.Startup, :run, [])
    |> Task.yield()

    cluster_access_token = CrawldisPanel.Cluster.get_access_token(user)

    Crawldis.Utils
    |> stub(:get_panel_config!, fn ->
      %{api_key: cluster_access_token.token, endpoint: "localhost:4002"}
    end)

    Crawldis.Connector.reconnect()
    :timer.sleep(1000)
    {:ok, user: user, cluster_access_token: cluster_access_token}
  end

  test "user has cluster access token", %{
    conn: conn,
    user: user,
    cluster_access_token: %{token: token}
  } do
    {:ok, view, _html} = live(conn, "/")
    assert render(view) =~ token
    assert render(view) =~ user.name
    assert render(view) =~ "Connected: 1"
  end

  test "can add/stop/view crawl jobs", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    view |> element("button", "New crawl") |> render_click()
    :timer.sleep(400)
    assert view |> render() =~ "Crawl job created"

    :timer.sleep(400)

    assert view |> element("#crawl-jobs button", "Stop") |> render_click() =~
             "Crawl job stopped"

    :timer.sleep(400)
    refute has_element?(view, "button", "Stop")
  end
end
