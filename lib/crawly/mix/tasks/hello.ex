defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply runs the Hello.say/0 function"
  def run(url) do
    # IO.inspect(name, label: :test)
    # calling our Hello.say() function from earlier
    # :application.start(:app)
    HTTPoison.start()
    resp = HTTPoison.get(url)
    Crawly.Application.start(:test, :test)
    resp
    Mix.shell().info([:green, "Check your digested files"])

    # IO.puts("Use response #{inspect(resp)}")
    # Crawly.EngineSup.start_manager(BlogEsl)
    # 'Elixir.IEx.CLI'.local_start()
    # IEx.Server.start(:test, {})
  end
end
