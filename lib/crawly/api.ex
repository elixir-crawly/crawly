defmodule Crawly.API.Router do
  @moduledoc """
  Crawly HTTP API. Allows to schedule/stop/get_stats
  of all running spiders.
  """
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  # Simple UI for crawly management
  get "/" do
    running_spiders = Crawly.Engine.running_spiders()

    spiders_list =
      Enum.map(
        Crawly.list_spiders(),
        fn spider ->
          state =
            case Map.get(running_spiders, spider) do
              {_pid, _job_id} -> :running
              nil -> :idle
            end

          spider_name =
            spider
            |> Atom.to_string()
            |> String.replace_leading("Elixir.", "")

          {scraped, scheduled} =
            case state == :running do
              false ->
                {" - ", " -  "}

              true ->
                {:stored_items, num} = Crawly.DataStorage.stats(spider)

                {:stored_requests, scheduled} =
                  Crawly.RequestsStorage.stats(spider)

                {num, scheduled}
            end

          %{
            name: spider_name,
            scheduled: scheduled,
            scraped: scraped,
            state: state
          }
        end
      )

    filename = Path.join(:code.priv_dir(:crawly), "index.html.eex")
    response = EEx.eval_file(filename, data: spiders_list)
    send_resp(conn, 200, response)
  end

  get "/spiders" do
    msg =
      case Crawly.Engine.running_spiders() do
        spiders when map_size(spiders) == 0 ->
          "No spiders are currently running"

        spiders ->
          "Following spiders are running: #{inspect(spiders)}"
      end

    send_resp(conn, 200, msg)
  end

  get "/spiders/:spider_name/schedule" do
    spider_name = String.to_atom("Elixir.#{spider_name}")
    result = Crawly.Engine.start_spider(spider_name)

    msg =
      case result do
        {:error, :spider_already_started} -> "Already started"
        {:error, _} -> "Can't load the spider"
        :ok -> "Started!"
      end

    send_resp(conn, 200, msg)
  end

  get "/spiders/:spider_name/stop" do
    spider_name = String.to_atom("Elixir.#{spider_name}")
    result = Crawly.Engine.stop_spider(spider_name)

    msg =
      case result do
        {:error, :spider_not_found} -> "Not found"
        {:error, :spider_not_running} -> "Spider is not running"
        :ok -> "Stopped!"
      end

    send_resp(conn, 200, msg)
  end

  get "/spiders/:spider_name/scheduled-requests" do
    spider_name = String.to_atom("Elixir.#{spider_name}")
    result = Crawly.RequestsStorage.stats(spider_name)

    msg =
      case result do
        {:error, :storage_worker_not_running} -> "Spider is not running"
        _ -> "#{inspect(result)}"
      end

    send_resp(conn, 200, msg)
  end

  get "/spiders/:spider_name/scraped-items" do
    spider_name = String.to_existing_atom("Elixir.#{spider_name}")
    result = Crawly.DataStorage.stats(spider_name)

    msg =
      case result do
        {:error, _} -> "Spider is not running"
        _ -> "#{inspect(result)}"
      end

    send_resp(conn, 200, msg)
  end

  match _ do
    send_resp(conn, 404, "Oops! Page not found!")
  end
end
