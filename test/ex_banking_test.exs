defmodule ExBankingTest do
  @moduledoc false

  use ExUnit.Case, async: true

  @first_account "John"
  @second_account "Jane"

  setup_all do
    ExBanking.create_user(@first_account)
    ExBanking.create_user(@second_account)

    ExBanking.deposit(@first_account, 1000.0, "AUD")
    ExBanking.deposit(@second_account, 1000.0, "AUD")

    :ok
  end

  test "Wrong arguments" do
    assert {:error, :wrong_arguments} == ExBanking.deposit(@first_account, -1.0, "USD")

    assert {:error, :wrong_arguments} ==
             ExBanking.send(@first_account, @second_account, -10.0, "USD")

    assert {:error, :wrong_arguments} == ExBanking.withdraw(@second_account, -10.0, "USD")
  end

  test "Create an user" do
    assert :ok == ExBanking.create_user("user")
  end

  test "User already exists" do
    assert {:error, :user_already_exists} == ExBanking.create_user(@first_account)
  end

  test "Deposit money into account" do
    assert {:ok, _balance} = ExBanking.get_balance(@first_account, "AUD")
    assert {:ok, _balance} = ExBanking.deposit(@first_account, 1000.0, "AUD")
  end

  test "Deposit for an user that does not exist" do
    assert {:error, :user_does_not_exist} == ExBanking.deposit("Non-existing user", 1000.0, "USD")
  end

  test "Withdrawal from the user bank account not enough money" do
    {:ok, balance} = ExBanking.get_balance(@first_account, "AUD")

    assert {:error, :not_enough_money} ==
             ExBanking.withdraw(@first_account, balance + 10.0, "AUD")
  end

  test "Withdrawal from the user bank account" do
    assert {:ok, _amount} = ExBanking.deposit(@first_account, 100.0, "USD")
    assert {:ok, _balance} = ExBanking.withdraw(@first_account, 50.0, "USD")
  end

  test "Withdrawal from an user that does not exists" do
    assert {:error, :user_does_not_exist} == ExBanking.withdraw("Giorgi", 1.0, "USD")
  end

  test "Get balance for an user that does not exist" do
    assert {:error, :user_does_not_exist} == ExBanking.get_balance("Giorgi", "USD")
  end

  test "Get user balance" do
    assert {:ok, _balance} = ExBanking.get_balance(@first_account, "AUD")
  end

  test "Send money from an user with not enough money" do
    assert {:error, :not_enough_money} ==
             ExBanking.send(@first_account, @second_account, 25_000.0, "AUD")
  end

  test "Send money from an user that does not exist" do
    assert {:error, :sender_does_not_exist} ==
             ExBanking.send("Not existing user", @second_account, 10.0, "usd")
  end

  test "Send money to an user that does not exist" do
    assert {:error, :receiver_does_not_exist} ==
             ExBanking.send(@first_account, "Giorgi", 1.0, "AUD")
  end

  test "Send money to an existing user" do
    {:ok, first_balance} = ExBanking.get_balance(@first_account, "AUD")
    {:ok, second_balance} = ExBanking.get_balance(@second_account, "AUD")

    withdraw_amount = 50.0

    assert {:ok, first_balance - withdraw_amount, second_balance + withdraw_amount} ==
             ExBanking.send(@first_account, @second_account, withdraw_amount, "AUD")
  end
end
