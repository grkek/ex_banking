defmodule ExBanking.RequestLimiterTest do
  @moduledoc false

  use ExUnit.Case, async: true
  alias ExBanking.RequestLimiter

  @first_account "John"
  @second_account "Jane"

  test "Track an user" do
    assert :ok == RequestLimiter.track(@first_account)
  end

  test "Release a tracked user" do
    assert :ok == RequestLimiter.track(@first_account)
    assert :ok == RequestLimiter.release(@first_account)
  end

  test "Release an untracked user" do
    assert {:error, :wrong_arguments} == RequestLimiter.release(@second_account)
  end

  test "Rate limit an user" do
    ExBanking.create_user("limitlessUser")

    Enum.each(1..100, fn _ ->
      spawn(fn -> ExBanking.deposit("limitlessUser", 100.0, "USD") end)
    end)

    assert {:error, :too_many_requests_to_user} == ExBanking.get_balance("limitlessUser", "USD")
  end
end
