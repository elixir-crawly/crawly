defmodule CrawldisWeb.HomeLive do
  @moduledoc false
  use CrawldisWeb, :live_view

  def render assigns do
    ~H"""
    <section>
      <h4>Clusters</h4>
      <ul>
        <li>

        </li>
      </ul>
      <button>Add requestor</button>
    </section>
    <section>
      <h4>Crawl Jobs</h4>
      <button>New crawl job</button>
    </section>
    """
  end
  def mount(_params,_session, socket) do
    {:ok, socket}
  end
end
