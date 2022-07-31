defmodule CrawldisWeb.HomeLive do
  @moduledoc false
  use CrawldisWeb, :live_view
  alias CrawldisPanel.{Cluster, Accounts}
  require Logger
  alias CrawldisWeb.Presence

  def render(assigns) do
    ~H"""
    <section>
      Hello <%= @user.name %>
      <h4>Cluster</h4>
      <div>
        <p>
          Access token: <span><%= @cluster_token.token %></span>
        </p>
        <p>
          URL: <span><%= @url %></span>
        </p>
        <p>
          Connected: <%= @connected_count %>
        </p>
      </div>
      <ul>
        <li>

        </li>
      </ul>
      <button>Add requestor</button>
      </section>
      <section id="crawl-jobs">
        <h4>Crawl Jobs</h4>
        <button phx-click="refresh">
          Refresh
        </button>
        <button phx-click="create_crawl">New crawl</button>
        <ul>
          <%= for job <- @crawl_jobs  do %>
            <li>
              <%= job["id"] %>
              <button phx-click="stop_crawl" phx-value-id={job["id"]}>
              Stop
            </button>
            </li>
          <% end %>
        </ul>
    </section>
    """
  end

  def mount(_params, _session, socket) do
    user =
      case Accounts.list_users() do
        [user] ->
          user

        [] ->
          {:ok, user} = Accounts.create_user(%{name: "My test user"})
          user
      end

    token = Cluster.get_access_token(user)

    token =
      if token == nil do
        Cluster.create_access_token(user)
      else
        token
      end

    # build endpoint url
    url_parts = Application.get_env(:crawldis_web, CrawldisWeb.Endpoint)[:url]
    url = url_parts[:host]

    url =
      if url_parts[:port] do
        url <> ":" <> "#{url_parts[:port]}"
      else
        url
      end

    socket =
      socket
      |> assign(:user, user)
      |> assign(:cluster_token, token)
      |> assign(:url, url)
      |> assign(:connected_count, 0)
      |> assign(:crawl_jobs, [])
      |> do_refresh()

    send(self(), :refresh)
    # subscribe to panel events
    CrawldisWeb.Endpoint.subscribe("cluster:panel")

    {:ok, socket}
  end

  def handle_event("refresh", _params, socket) do
    do_refresh(socket)
    {:noreply, socket}
  end

  def handle_event("create_crawl", params, socket) do
    Logger.debug("Create crawl job triggered, params: #{inspect(params)}")
    # send message to cluster
    CrawldisWeb.Endpoint.broadcast("cluster", "create_crawl", params)
    {:noreply, socket}
  end

  def handle_event("stop_crawl", params, socket) do
    Logger.debug("Stop crawl triggered, params: #{inspect(params)}")
    CrawldisWeb.Endpoint.broadcast("cluster", "stop_crawl", params)

    socket =
      socket
      |> put_flash(:info, "Crawl job stopped")

    {:noreply, socket}
  end

  def handle_info(:refresh, socket) do
    socket = do_refresh(socket)
    Process.send_after(self(), :refresh, 5000)
    {:noreply, socket}
  end

  def handle_info(
        %{event: "reply:create_crawl", payload: %{"job" => job}},
        socket
      ) do
    socket =
      socket
      |> put_flash(:info, "Crawl job created, job id: #{job["id"]}")

    {:noreply, socket}
  end

  def handle_info(
        %{event: "reply:list_crawls", payload: %{"jobs" => jobs}},
        socket
      ) do
    socket = assign(socket, :crawl_jobs, jobs)
    {:noreply, socket}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp do_refresh(socket) do
    connected_count = Presence.list("cluster") |> Map.keys() |> length()
    Logger.debug("Number of connected nodes: #{connected_count}")
    CrawldisWeb.Endpoint.broadcast("cluster", "list_crawls", %{})
    socket |> assign(connected_count: connected_count)
  end
end
