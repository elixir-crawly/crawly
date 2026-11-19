# ExUnit.start()
ExUnit.start(exclude: [:skip], capture_log: true)

# Stop the app after the suite so its dets table (owned by the app's start
# process) is closed cleanly and the next run doesn't have to repair it
ExUnit.after_suite(fn _ -> Application.stop(:crawly) end)
