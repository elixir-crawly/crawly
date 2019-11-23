defmodule Crawly.DataStorage.StorageBackend do

  @callback init(spider_name) :: {:ok, maybe_io_device}
            when spider_name: atom(),
                 maybe_io_device: File.io_device() | atom()

  @callback write(item, maybe_io_device) :: :ok
            when item: any(),
                 maybe_io_device: File.io_device() | atom()

  @callback close(maybe_io_device) :: :ok
            when maybe_io_device: File.io_device() | atom()

end
