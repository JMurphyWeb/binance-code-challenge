defmodule CoinFlipper.Strategy.Random do
  use GenServer

  defmodule Config do
    defstruct [:symbol, :order_size, :max_position_size, :signal_interval_range_sec]
  end

  def start_link(config = %Config{}, name) do
    GenServer.start_link(__MODULE__, config, name: name)
  end

  @impl true
  def init(config = %Config{}) do
    schedule_next_signal(config)
    {:ok, {config, Decimal.new("0")}}
  end

  @impl true
  def handle_info(:trigger_signal, {config, position_size}) do
    new_position_size = generate_signal(config, position_size)
    schedule_next_signal(config)
    {:noreply, {config, new_position_size}}
  end

  # Schedules next signal according to the configured interval range.
  defp schedule_next_signal(config) do
    delay = config.signal_interval_range_sec |> Enum.random() |> :timer.seconds()
    Process.send_after(self(), :trigger_signal, delay)
    :ok
  end

  @doc "Logic for generating a signal. Updates position size after execution."
  def generate_signal(config, position_size) do
    position_size_ratio = position_size |> Decimal.div(config.max_position_size)

    quantity =
      if Enum.random(0..100)
         |> Decimal.div(100)
         |> Decimal.lt?(position_size_ratio) do
        config.order_size |> Decimal.mult(-1)
      else
        config.order_size
      end

    executed_quantity = execute_signal(config.symbol, quantity)

    Decimal.add(position_size, executed_quantity)
  end

  @doc "EDITME: Entry point for order execution!"
  def execute_signal(symbol, quantity) do
    IO.puts("Please change position size for #{symbol} by #{quantity}")

    quantity
  end
end
