defmodule ExBanking.RequestLimiter do
  @moduledoc false
  use GenServer

  @table_name :request_limiter
  @max_requests 10

  @impl true
  def init(_opts) do
    :ets.new(@table_name, [
      :set,
      :named_table,
      :public,
      read_concurrency: true,
      write_concurrency: true
    ])

    {:ok, %{}}
  end

  def start_link(_opts), do: __MODULE__ |> GenServer.start_link([], name: RequestLimiter)

  def track(user), do: RequestLimiter |> GenServer.call({:track, user, 1})
  def release(user), do: RequestLimiter |> GenServer.call({:track, user, -1})

  @impl true
  def handle_call({:track, user, increment}, _from, state) do
    @table_name
    |> :ets.update_counter(user, {2, increment}, {user, 0})
    |> case do
      -1 -> {:reply, {:error, :wrong_arguments}, state}
      count when count > @max_requests -> {:reply, {:error, :too_many_requests_to_user}, state}
      _count -> {:reply, :ok, state}
    end
  end
end
