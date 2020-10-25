defmodule CoinFlipper.Exchanges.BinanceFutures.BatchOrders do
  use GenServer

  @send_after 10 * 1000

  ####
  #### API
  def new_order(symbol, quantity) do
    GenServer.call(__MODULE__, {:new_order, {symbol, quantity}})
  end

  ####
  #### INTERNAL
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(orders) do
    IO.puts("[#{__MODULE__}] starting")

    {:ok, orders}
  end

  @impl true
  def handle_call({:new_order, order}, _sender_pid, orders) do
    case orders do
      [] ->
        batch_id = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
        Process.send_after(self(), {:batch_timeout, batch_id}, @send_after)

        {:reply, :ok, [{batch_id, [order]}]}

      [{_batch_id, orders}] when length(orders) == 4 ->
        IO.puts("sending batch due to max size")
        :ok = send_batch([order | orders])

        {:reply, :ok, []}

      [{batch_id, orders}] when length(orders) < 4 ->
        {:reply, :ok, [{batch_id, [order | orders]}]}
    end
  end

  @impl true
  def handle_info({:batch_timeout, batch_id}, orders) do
    case orders do
      [{^batch_id, orders}] ->
        IO.puts("sending batch due to timeout")
        :ok = send_batch(orders)

        {:noreply, []}

      _ ->
        # Current batch was already sent as it reached batch limit of 5
        {:noreply, orders}
    end
  end

  defp send_batch(orders) do
    spawn_link(fn ->
      case CoinFlipper.Exchanges.BinanceFutures.create_batch_order(orders) do
        {:ok, responses} ->
          :ok =
            Enum.zip(orders, responses)
            |> Enum.map(&parse_response/1)
            |> Enum.reject(&log_and_reject_error/1)
            |> CoinFlipper.Exchanges.BinanceFutures.Tracker.record_orders()

          :ok

        {:error, body} ->
          IO.puts("API request error: #{inspect(body)}")
          :ok
      end
    end)

    :ok
  end

  defp parse_response({{symbol, quantity}, response}) do
    case response do
      %{"status" => "FILLED", "side" => "BUY", "cumQuote" => cum_quote, "cumQty" => cum_qty} ->
        {:ok, symbol,
         %{
           cum_quote: to_decimal(cum_quote),
           cum_qty: to_decimal(cum_qty)
         }}

      %{"status" => "FILLED", "side" => "SELL", "cumQuote" => cum_quote, "cumQty" => cum_qty} ->
        {:ok, symbol,
         %{
           cum_quote: to_decimal(cum_quote) |> Decimal.negate(),
           cum_qty: to_decimal(cum_qty) |> Decimal.negate()
         }}

      %{"status" => "EXPIRED"} ->
        {:error, symbol, quantity, nil, "Expired"}

      %{"code" => code, "msg" => msg} ->
        {:error, symbol, quantity, code, msg}
    end
  end

  defp to_decimal(binary) when is_binary(binary) do
    {decimal, _} = Decimal.parse(binary)

    decimal
  end

  defp log_and_reject_error(res) do
    case res do
      {:error, symbol, quantity, code, msg} ->
        IO.puts("""
        Order error
          order: #{symbol}
          quantity: #{Decimal.to_string(quantity)}
          code: #{code}
          message: #{msg}
        """)

        true

      _ ->
        false
    end
  end
end
