defmodule CoinFlipper.Exchanges.BinanceFutures.Tracker do
  use GenServer

  ####
  #### API
  def record_orders(order_batch) do
    GenServer.call(__MODULE__, {:completed, order_batch})
    :ok
  end

  ####
  #### INTERNAL
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    IO.puts("[#{__MODULE__}] starting")

    {:ok, state}
  end

  @impl true
  def handle_call({:completed, completed_batch}, _sender_pid, state) do
    new_state =
      completed_batch
      |> Enum.reduce(state, fn {:ok, symbol, order}, new_state ->
        Map.update(new_state, symbol, [order], fn history -> [order | history] end)
      end)
      |> log_state()

    {:reply, :ok, new_state}
  end

  # NOTE: this does not log the realized profits/loss
  # I wasn't too sure what the calculate/formula was for that but assumed we could
  # gather it from the order history
  defp log_state(state) do
    state
    |> Enum.map(fn {symbol, history} ->
      initial = %{net_spend: 0, owned: 0}

      %{net_spend: net_spend, owned: owned} =
        history
        |> Enum.reduce(initial, fn %{cum_quote: cum_quote, cum_qty: cum_qty}, acc ->
          %{
            net_spend: Decimal.add(acc.net_spend, cum_quote),
            owned: Decimal.add(acc.owned, cum_qty)
          }
        end)

      "#{symbol}: NET SPEND: #{Decimal.to_string(net_spend)}, OWNED: #{Decimal.to_string(owned)}"
    end)
    |> Enum.join("\n")
    |> IO.puts()

    state
  end
end
