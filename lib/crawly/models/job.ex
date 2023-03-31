defmodule Crawly.Models.Job do
  @moduledoc """
  The `Crawly.Models.Job` module defines a struct and functions for managing and updating information about a web scraping job.

  ## Struct

  The `Crawly.Models.Job` struct has the following fields:

  * `id`: a binary representing the unique ID of the job.
  * `spider_name`: a binary representing the name of the spider used for the job.
  * `start`: a DateTime.t representing the time the job started.
  * `end`: a DateTime.t representing the time the job ended. This is `nil` until the job is completed.
  * `scraped_items`: an integer representing the number of items scraped during the job.
  * `stop_reason`: a binary representing the reason the job was stopped, if applicable. This is `nil` until the job is stopped.

  ## Functions

  * `new(crawl_id, spider_name)`: creates a new job with the given `crawl_id` and `spider_name` and stores it in a SimpleStorage instance.
  * `update(crawl_id, total_scraped, stop_reason)`: updates the job with the given `crawl_id` with the total number of items `total_scraped` and the reason `stop_reason`, and stores it in the SimpleStorage instance.
  * `get(crawl_id)`: retrieves the job with the given `crawl_id` from the SimpleStorage instance.
  """
  defstruct id: nil,
            spider_name: nil,
            start: DateTime.utc_now(),
            end: nil,
            scraped_items: 0,
            stop_reason: nil

  @table_name __MODULE__

  @type t :: %__MODULE__{
          id: binary(),
          spider_name: binary(),
          start: DateTime.t(),
          end: DataTime.t(),
          scraped_items: integer(),
          stop_reason: binary()
        }

  @doc """

    Creates a new job with the given `crawl_id` and `spider_name`, and stores it in the SimpleStorage instance.

    ## Examples

        iex> Crawly.Models.Job.new("my-crawl-id", "my-spider")
        :ok

    ## Parameters

    * `crawl_id`: a binary representing the unique ID of the job.
    * `spider_name`: a binary representing the name of the spider used for the job.

    ## Returns

    * `:ok`: if the job was created and stored successfully.
    * `{:error, reason}`: if an error occurred while trying to create or store the job.


  """
  @spec new(term(), atom()) :: :ok | {:error, term()}
  def new(crawl_id, spider_name) do
    spider_name =
      case Atom.to_string(spider_name) do
        "Elixir." <> name -> name
        name -> name
      end

    new_job = %Crawly.Models.Job{id: crawl_id, spider_name: spider_name}

    Crawly.SimpleStorage.put(@table_name, crawl_id, new_job)
  end

  @doc """
    Updates the job with the given `crawl_id` in the SimpleStorage instance with the provided `total_scraped` and `stop_reason`.

    ## Examples

        iex> Crawly.Models.Job.update("my-crawl-id", 100, :finished)
        :ok

    ## Parameters

    * `crawl_id`: a binary representing the unique ID of the job.
    * `total_scraped`: an integer representing the total number of items scraped during the job.
    * `stop_reason`: a term representing the reason why the job was stopped, if applicable.

    ## Returns

    * `:ok`: if the job was successfully updated in the SimpleStorage instance.
    * `{:error, reason}`: a tuple containing the reason why the job could not be updated, such as if it does not exist in the SimpleStorage instance.
  """
  @spec update(String.t(), integer(), term()) :: :ok | {:error, any}
  def update(crawl_id, total_scraped, stop_reason) do
    case Crawly.SimpleStorage.get(@table_name, crawl_id) do
      {:ok, job_item} ->
        new_job_item = %Crawly.Models.Job{
          job_item
          | stop_reason: stop_reason,
            scraped_items: total_scraped,
            end: DateTime.utc_now()
        }

        Crawly.SimpleStorage.put(@table_name, crawl_id, new_job_item)

      {:error, _} ->
        :ok
    end
  end

  @doc """
  Retrieves the job with the given `crawl_id` from the SimpleStorage instance.

    ## Examples

        iex> Crawly.Models.Job.get("my-crawl-id")
        {:ok, %Crawly.Models.Job{
          id: "my-crawl-id",
          spider_name: "my-spider",
          start: ~U[2023-03-31 16:00:00Z],
          end: nil,
          scraped_items: 0,
          stop_reason: nil
        }}

    ## Parameters

    * `crawl_id`: a binary representing the unique ID of the job.

    ## Returns

    * `{:ok, job}`: a tuple containing the retrieved job as a `Crawly.Models.Job` struct if it exists in the SimpleStorage instance.
    * `{:error, reason}`: a tuple containing the reason why the job could not be retrieved, such as if it does not exist in the SimpleStorage instance.
  """
  @spec get(term()) :: {:error, term()} | {:ok, Crawly.Models.Job.t()}
  def get(crawl_id) do
    Crawly.SimpleStorage.get(@table_name, crawl_id)
  end
end
