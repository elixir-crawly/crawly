# defmodule Crawly.WorkersSup do
#   use DynamicSupervisor

#   def start_link() do
#     DynamicSupervisor.start_link(__MODULE__, :ok)
#   end

#   def init(:ok) do
#     DynamicSupervisor.init(strategy: :one_for_one)
#   end

#   # def start_worker(name) do

#   # end
# end
