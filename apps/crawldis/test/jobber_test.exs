defmodule Crawldis.JobberTest do
  use ExUnit.Case
  alias Crawldis.{Jobber, RequestQueue}
  alias Crawldis.Jobber.CrawlJob

  @job %{start_urls: ["http://www.some url.com"]}
  setup do
    Jobber.stop_job(:all)
    RequestQueue.clear_requests()
    :ok
  end

  test "start a job" do
    assert {:ok, %CrawlJob{id: id, start_urls: [_]} } = Jobber.start_job(@job)
    assert [_] = Jobber.list_jobs()
    assert @job = Jobber.get_job(id)
    assert is_binary(id)
    assert RequestQueue.count_requests() > 0
  end

  describe "update" do
    setup [:start_job]

    test "stops a job", %{job: job} do
      # start another job, so should have 1 request in queue after
      start_job([])
      assert RequestQueue.count_requests() == 2
      assert :ok = Jobber.stop_job(job.id)
      :timer.sleep(300)
      assert Jobber.list_jobs() |> length() == 1
      # clears request queue
      assert RequestQueue.count_requests() == 1
    end
  end

  defp start_job(_) do
    {:ok, job}=  Jobber.start_job(@job)
    {:ok, job: job}
  end
end
