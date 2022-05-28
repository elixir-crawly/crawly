defmodule CrawldisPanel.Repo do
  use Ecto.Repo,
    otp_app: :crawldis_panel,
    adapter: Ecto.Adapters.Postgres
end
