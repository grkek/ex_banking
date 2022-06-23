# ExBanking

Test task for Elixir developers. Candidate should write a simple banking OTP application in Elixir language.

## Testing
Run the command below to execute the tests.

```
mix test
```

## API Reference
ExBanking module has four different methods which allow the client to `Create`, `Deposit`, `Withdraw` and `Send`

```elixir
# Create an user
ExBanking.create_user("John")

# Deposit money into two accounts
ExBanking.deposit("John", 2500, "USD")
ExBanking.deposit("John", 2500, "AED")

# Check if the balance is affected
ExBanking.get_balance("John", "USD")
ExBanking.get_balance("John", "AED")

# Withdraw money from two accounts
ExBanking.withdraw("John", 1776, "USD")
ExBanking.withdraw("John", 1901, "AED")

# Check if the balance is afffected
ExBanking.get_balance("John", "USD")
ExBanking.get_balance("John", "AED")

# Create another user
ExBanking.create_user("Jane")

# Send the other user some money
ExBanking.send("John", "Jane", 100, "USD")
```