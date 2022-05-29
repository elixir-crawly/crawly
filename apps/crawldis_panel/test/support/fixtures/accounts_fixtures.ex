defmodule CrawldisPanel.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `CrawldisWeb.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> CrawldisPanel.Accounts.create_user()

    user
  end
end
