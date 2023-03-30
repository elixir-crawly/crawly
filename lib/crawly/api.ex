defmodule Crawly.API.Router do
  @moduledoc """
  Crawly HTTP API. Allows to schedule/stop/get_stats
  of all running spiders.
  """

  require Logger

  use Plug.Router

  @spider_validation_schema %{
    "type" => "object",
    "additionalProperties" => false,
    "required" => ["name", "links_to_follow", "fields", "start_urls"],
    "properties" => %{
      "name" => %{"type" => "string"},
      "base_url" => %{"type" => "string", "format" => "uri"},
      "start_urls" => %{
        "type" => "array",
        "items" => %{"type" => "string", "format" => "uri"}
      },
      "links_to_follow" => %{
        "type" => "array",
        "items" => %{
          "type" => "object",
          "additionalProperties" => false,
          "properties" => %{
            "selector" => %{"type" => "string"},
            "attribute" => %{"type" => "string"}
          }
        }
      },
      "fields" => %{
        "type" => "array",
        "items" => %{
          "type" => "object",
          "additionalProperties" => false,
          "properties" => %{
            "name" => %{"type" => "string"},
            "selector" => %{"type" => "string"}
          }
        }
      }
    }
  }

  plug(Plug.Parsers, parsers: [:urlencoded, :multipart])
  plug(:match)
  plug(:dispatch)

  # Simple UI for crawly management
  get "/" do
    running_spiders = Crawly.Engine.running_spiders()

    spiders_list =
      Enum.map(
        Crawly.list_spiders(),
        fn spider ->
          {crawl_id, state} =
            case Map.get(running_spiders, spider) do
              {_pid, crawl_id} -> {crawl_id, :running}
              nil -> {nil, :idle}
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

          editable? =
            case Crawly.SpidersStorage.get(spider_name) do
              {:error, :not_found} -> false
              {:ok, _value} -> true
              _ -> false
            end

          %{
            name: spider_name,
            crawl_id: crawl_id,
            scheduled: scheduled,
            scraped: scraped,
            state: state,
            editable?: editable?
          }
        end
      )

    response = render_template("list.html.eex", data: spiders_list)
    send_resp(conn, 200, response)
  end

  get "/new" do
    spider_name = Map.get(conn.query_params, "spider_name", "")

    spider_data =
      case spider_name do
        "" ->
          {:ok, ""}

        name ->
          Crawly.SpidersStorage.get(name)
      end

    case spider_data do
      {:error, :not_found} ->
        send_resp(conn, 404, "Page not found")

      {:ok, value} ->
        response =
          render_template("new.html.eex",
            data: %{
              "errors" => "",
              "spider" => value,
              "spider_name" => spider_name
            }
          )

        send_resp(conn, 200, response)
    end
  end

  post "/new" do
    name_from_query_params = Map.get(conn.query_params, "spider_name", "")
    spider_yml = Map.get(conn.body_params, "spider")

    # Validate incoming data with json schema
    validation_result =
      case validate_new_spider_request(spider_yml) do
        {:error, errors} ->
          {:error, "#{inspect(errors)}"}

        %{"name" => spider_name} = yml ->
          # Check if spider already registered, but allow editing spiders
          case {is_spider_registered(spider_name),
                spider_name == name_from_query_params} do
            {true, false} ->
              {:error,
               "Spider with this name already exists. Try editing it instead of overriding"}

            _ ->
              {:ok, yml}
          end
      end

    case validation_result do
      {:ok, %{"name" => spider_name} = _parsed_yml} ->
        :ok = Crawly.SpidersStorage.put(spider_name, spider_yml)

        # Now we can finally load the spider
        Crawly.Utils.load_yml_spider(spider_yml)

        # Now we can redirect to the homepage
        conn
        |> put_resp_header("location", "/")
        |> send_resp(conn.status || 302, "Redirect")

      {:error, errors} ->
        # Show errors and spider
        data = %{"errors" => errors, "spider" => spider_yml}
        response = render_template("new.html.eex", data: data)
        send_resp(conn, 400, response)
    end
  end

  delete "/spider/:spider_name" do
    Crawly.SpidersStorage.delete(spider_name)

    conn
    |> put_resp_header("location", "/")
    |> send_resp(conn.status || 302, "Redirect")
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

  get "/spiders/:spider_name/logs/:crawl_id" do
    spider_name = String.to_existing_atom(spider_name)
    log_file_path = Crawly.Utils.spider_log_path(spider_name, crawl_id)

    case File.exists?(log_file_path) do
      true -> Plug.Conn.send_file(conn, 200, log_file_path)
      false -> send_resp(conn, 404, "Oops! Page not found!")
    end
  end

  get "/spiders/:spider_name/items/:crawl_id" do
    folder =
      Application.get_env(:crawly, :pipelines, [])
      |> Keyword.get(Crawly.Pipelines.WriteToFile, [])
      |> Keyword.get(:folder, "")

    file_paths =
      case File.ls(folder) do
        {:ok, list} ->
          Enum.filter(list, fn path -> String.contains?(path, crawl_id) end)

        {:error, _} ->
          []
      end

    case file_paths do
      [] ->
        send_resp(conn, 404, "Oops! Page not found!")

      [file_path] ->
        full_path = Path.join([folder, file_path])
        Plug.Conn.send_file(conn, 200, full_path)

      other ->
        Logger.error("Could not get correct items file: #{inspect(other)}")
        send_resp(conn, 500, "Unexpected error")
    end
  end

  get "/spiders/:spider_name/requests" do
    spider_name = String.to_atom("Elixir.#{spider_name}")

    result =
      case Crawly.RequestsStorage.requests(spider_name) do
        {:requests, result} ->
          Enum.map(result, fn req ->
            %{url: req.url, headers: inspect(req.headers)}
          end)

        {:error, _} ->
          []
      end

    response =
      render_template("requests_list.html.eex",
        requests: result,
        spider_name: spider_name
      )

    send_resp(conn, 200, response)
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

  get "/load-spiders" do
    loaded_spiders =
      case Crawly.load_spiders() do
        {:ok, spiders} -> spiders
        {:error, :no_spiders_dir} -> []
      end

    send_resp(
      conn,
      200,
      "Loaded following spiders from $SPIDERS_DIR: #{inspect(loaded_spiders)}"
    )
  end

  match _ do
    send_resp(conn, 404, "Oops! Page not found!")
  end

  defp validate_new_spider_request(maybe_yml) do
    with {:ok, yml} <- YamlElixir.read_from_string(maybe_yml),
         :ok <- ExJsonSchema.Validator.validate(@spider_validation_schema, yml) do
      yml
    else
      {:error, _err} = err -> err
    end
  end

  defp is_spider_registered(name) do
    module_name_str = "Elixir." <> name
    module_name = String.to_atom(module_name_str)
    Enum.member?(Crawly.Utils.list_spiders(), module_name)
  end

  defp render_template(template_name, assigns) do
    base_dir = :code.priv_dir(:crawly)
    template = Path.join(base_dir, template_name)
    rendered_template = EEx.eval_file(template, assigns)

    base_template = Path.join(base_dir, "index.html.eex")
    EEx.eval_file(base_template, rendered_template: rendered_template)
  end
end
