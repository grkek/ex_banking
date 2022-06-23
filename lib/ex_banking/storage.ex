defmodule ExBanking.Storage do
  @moduledoc false
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: Storage)
  end

  def get(key), do: Agent.get(Storage, &Map.get(&1, key))
  def set(key, value), do: Agent.update(Storage, &Map.put(&1, key, value))
end
