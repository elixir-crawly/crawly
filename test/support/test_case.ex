defmodule Crawly.TestCase do
  @moduledoc """
  Shared case template for Crawly tests.

  Crawly tests touch global state: `:meck` mocks are VM-wide, spiders run
  under the application supervisor, and `Crawly.SimpleStorage` is a DETS
  table on disk. Anything a test leaves behind leaks into whichever test
  runs next, which makes failures depend on the random seed.

  Using this template resets that global state before and after every test:

    * stops every running spider
    * unloads all `:meck` mocks
    * clears `Crawly.SimpleStorage`
    * clears the registry of dynamically loaded (e.g. YML) spiders

  Cleanup also runs *before* each test, so files that use this template are
  protected from leftovers of files that don't use it yet.

  Mocks must be created in `setup` (not `setup_all`), because they are
  unloaded after every test.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Crawly.TestCase, only: [reset_global_state: 0]
    end
  end

  setup do
    reset_global_state()
    on_exit(&reset_global_state/0)
    :ok
  end

  @doc """
  Puts global Crawly state back to a clean baseline.
  """
  def reset_global_state() do
    # Stop spiders first: they may still be calling mocked modules, and
    # unloading the mocks under them would send them to real code (and the
    # real network).
    stop_running_spiders()
    unload_mocks()
    clear_simple_storage()
    # YML spiders register themselves in a :persistent_term registry, which
    # outlives SimpleStorage being cleared.
    Crawly.Utils.clear_registered_spiders()
    :ok
  end

  defp stop_running_spiders() do
    Crawly.Engine.running_spiders()
    |> Map.keys()
    |> Enum.each(&Crawly.Engine.stop_spider(&1, :stopped_by_test_case))
  catch
    # The engine may be restarting after a crash in the previous test.
    :exit, _ -> :ok
  end

  defp unload_mocks(), do: :meck.unload()

  defp clear_simple_storage() do
    Crawly.SimpleStorage.clear()
  catch
    :exit, _ -> :ok
  end
end
