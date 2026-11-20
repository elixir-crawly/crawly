# ExUnit.start()
# e2e tests crawl a local website, see test/e2e/books_crawl_test.exs
ExUnit.start(exclude: [:skip, :e2e], capture_log: true)

# Stop the app after the suite so its dets table (owned by the app's start
# process) is closed cleanly and the next run doesn't have to repair it
ExUnit.after_suite(fn _ -> Application.stop(:crawly) end)
