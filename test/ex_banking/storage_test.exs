defmodule ExBanking.StorageTest do
  @moduledoc false

  use ExUnit.Case, async: true
  alias ExBanking.Storage

  @first_account "John"
  @second_account "Jane"

  test "Store an user" do
    assert :ok == Storage.set(@first_account, %{"deposits" => [], "withdrawals" => []})
  end

  test "Get a stored user" do
    assert :ok == Storage.set(@first_account, %{"deposits" => [], "withdrawals" => []})
    assert %{"deposits" => [], "withdrawals" => []} == Storage.get(@first_account)
  end

  test "Get a missing user" do
    assert nil == Storage.get(@second_account)
  end
end
