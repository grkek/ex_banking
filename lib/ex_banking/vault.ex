defmodule ExBanking.Vault do
  @moduledoc false
  use GenServer

  alias ExBanking.RequestLimiter
  alias ExBanking.Storage

  @impl true
  def init(_opts), do: {:ok, []}

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: Vault)

  def create_user(user), do: GenServer.call(Vault, {:create, user})

  def deposit(user, amount, currency) do
    case RequestLimiter.track(user) do
      :ok ->
        RequestLimiter.release(user)
        GenServer.call(Vault, {:deposit, user, amount, currency})

      error ->
        RequestLimiter.release(user)
        error
    end
  end

  def withdraw(user, amount, currency) do
    case RequestLimiter.track(user) do
      :ok ->
        RequestLimiter.release(user)
        GenServer.call(Vault, {:withdraw, user, amount, currency})

      error ->
        RequestLimiter.release(user)
        error
    end
  end

  def get_balance(user, currency) do
    case RequestLimiter.track(user) do
      :ok ->
        RequestLimiter.release(user)
        GenServer.call(Vault, {:balance, user, currency})

      error ->
        RequestLimiter.release(user)
        error
    end
  end

  def send(from, to, amount, currency) do
    case [RequestLimiter.track(from), RequestLimiter.track(to)] do
      [:ok, :ok] ->
        release_clients([from, to])
        GenServer.call(Vault, {:send, from, to, amount, currency}, :infinity)

      [:ok, {:error, _}] ->
        release_clients([from, to])
        {:error, :too_many_requests_to_receiver}

      [{:error, _}, _] ->
        release_clients([from, to])
        {:error, :too_many_requests_to_sender}
    end
  end

  @impl true
  def handle_call({:create, user}, _from, state) do
    case Storage.get(user) do
      nil ->
        Storage.set(user, %{"deposits" => [], "withdrawals" => []})
        {:reply, :ok, state}

      _user ->
        {:reply, {:error, :user_already_exists}, state}
    end
  end

  @impl true
  def handle_call({:deposit, user, amount, currency}, _from, state) do
    case Storage.get(user) do
      %{"deposits" => [], "withdrawals" => []} ->
        Storage.set(user, %{"deposits" => [{amount, currency}], "withdrawals" => []})
        {:reply, {:ok, Float.round(amount / 1, 2)}, state}

      %{"deposits" => deposits, "withdrawals" => withdrawals} ->
        balance = account_balance(deposits, currency) - account_balance(withdrawals, currency)

        Storage.set(user, %{
          "deposits" => deposits ++ [{amount, currency}],
          "withdrawals" => withdrawals
        })

        {:reply, {:ok, Float.round(balance + amount, 2)}, state}

      _error ->
        {:reply, {:error, :user_does_not_exist}, state}
    end
  end

  @impl true
  def handle_call({:withdraw, user, amount, currency}, _from, state) do
    case Storage.get(user) do
      %{"deposits" => deposits, "withdrawals" => withdrawals} ->
        balance = account_balance(deposits, currency) - account_balance(withdrawals, currency)

        cond do
          balance >= amount ->
            Storage.set(user, %{
              "deposits" => deposits,
              "withdrawals" => withdrawals ++ [{amount, currency}]
            })

            {:reply, {:ok, Float.round(balance - amount, 2)}, state}

          balance < amount ->
            {:reply, {:error, :not_enough_money}, state}
        end

      _error ->
        {:reply, {:error, :user_does_not_exist}, state}
    end
  end

  @impl true
  def handle_call({:balance, user, currency}, _from, state) do
    case Storage.get(user) do
      %{"deposits" => [], "withdrawals" => []} ->
        {:reply, {:ok, 0.00}, state}

      %{"deposits" => deposits, "withdrawals" => withdrawals} ->
        balance = account_balance(deposits, currency) - account_balance(withdrawals, currency)
        {:reply, {:ok, balance}, state}

      _error ->
        {:reply, {:error, :user_does_not_exist}, state}
    end
  end

  @impl true
  def handle_call({:send, from, to, amount, currency}, _from, state) do
    case Storage.get(from) do
      %{"deposits" => [], "withdrawals" => []} ->
        {:reply, {:error, :not_enough_money}, state}

      %{"deposits" => from_deposits, "withdrawals" => from_withdrawals} ->
        case Storage.get(to) do
          %{"deposits" => to_deposits, "withdrawals" => to_withdrawals} ->
            from_balance =
              account_balance(from_deposits, currency) -
                account_balance(from_withdrawals, currency)

            to_balance =
              account_balance(to_deposits, currency) - account_balance(to_withdrawals, currency)

            cond do
              from_balance >= amount ->
                Storage.set(from, %{
                  "deposits" => from_deposits,
                  "withdrawals" => from_withdrawals ++ [{amount, currency}]
                })

                Storage.set(to, %{
                  "deposits" => to_deposits ++ [{amount, currency}],
                  "withdrawals" => to_withdrawals
                })

                {:reply, {:ok, from_balance - amount, to_balance + amount}, state}

              from_balance < amount ->
                {:reply, {:error, :not_enough_money}, state}
            end

          _error ->
            {:reply, {:error, :receiver_does_not_exist}, state}
        end

      _error ->
        {:reply, {:error, :sender_does_not_exist}, state}
    end
  end

  defp account_balance(account, currency) do
    account
    |> Enum.filter(fn {_amount, account_currency} ->
      String.equivalent?(currency, account_currency)
    end)
    |> Enum.map(fn {amount, _currency} -> amount end)
    |> case do
      [] ->
        0.00

      enum ->
        enum
        |> Enum.reduce(fn amount, acc -> acc + amount end)
        |> Kernel./(1)
    end
  end

  defp release_clients(clients), do: Enum.each(clients, &RequestLimiter.release/1)
end
