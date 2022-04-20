defmodule CrawldisWeb.Repo do
  use Ecto.Repo,
    otp_app: :crawldis_web,
    adapter: Ecto.Adapters.Postgres
end
