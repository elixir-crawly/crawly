defmodule Crawly.Loggers.SendToUiBackend do
  # TODO: Write doc
  # Initialize the configuration
  def init({__MODULE__, name}) do
    {:ok, configure(name, [])}
  end

  def handle_call({:configure, opts}, %{name: name} = state) do
    {:ok, :ok, configure(name, opts, state)}
  end

  # Handle the flush event
  def handle_event(:flush, state) do
    {:ok, state}
  end

  # Handle any log messages that are sent across
  def handle_event(
        {_level, _group_leader, {Logger, message, _timestamp, metadata}},
        %{destination: {node, module, function}} = state
      ) do
    case Keyword.get(metadata, :crawl_id, nil) do
      nil ->
        :ignore

      crawl_id ->
        :rpc.cast(node, module, function, [crawl_id, message])
    end

    {:ok, state}
  end

  defp configure(name, []) do
    case Application.get_env(:logger, name, []) do
      [] ->
        raise "Destination was not configured"

      config ->
        %{name: name, destination: Keyword.get(config, :destination)}
    end
  end

  # We don't support any re-configuration so far
  defp configure(_name, _opts, state), do: state
end
