defmodule CoinFlipper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # Load environment variables from .env file
    Vapor.load!([%Vapor.Provider.Dotenv{}])

    children = [
      random_strategy_bot("BTCUSDT", "0.1", "1", 4..16),
      random_strategy_bot("ETHUSDT", "5", "20", 2..8),
      random_strategy_bot("LINKUSDT", "120", "240", 4..12),
      random_strategy_bot("LENDUSDT", "600", "600", 8..32),
      random_strategy_bot("YFIUSDT", "0.04", "1.2", 12..64),
      {Finch, name: CoinFinch}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CoinFlipper.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp random_strategy_bot(symbol, order_size, max_position_size, signal_interval_range_sec) do
    %{
      id: String.to_atom(symbol),
      start:
        {CoinFlipper.Strategy.Random, :start_link,
         [
           %CoinFlipper.Strategy.Random.Config{
             symbol: symbol,
             order_size: Decimal.new(order_size),
             max_position_size: Decimal.new(max_position_size),
             signal_interval_range_sec: signal_interval_range_sec
           },
           String.to_atom(symbol)
         ]}
    }
  end
end
