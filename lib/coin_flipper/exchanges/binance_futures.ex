defmodule CoinFlipper.Exchanges.BinanceFutures do
  @moduledoc "API client for Binance Futures"

  @api_key_header "X-MBX-APIKEY"

  @doc """
  Send a new market order to the exchange.

  Docs: https://binance-docs.github.io/apidocs/futures/en/#new-order-trade
  """
  def create_market_order(symbol, quantity = %Decimal{}) do
    %{
      symbol: symbol,
      quantity: Decimal.abs(quantity),
      side: if(Decimal.positive?(quantity), do: "BUY", else: "SELL"),
      type: "MARKET",
      newOrderRespType: "RESULT"
    }
    |> signed_post("/fapi/v1/order")
  end

  def create_market_order(symbol, quantity) do
    create_market_order(symbol, Decimal.new(quantity))
  end

  defp signed_post(params, path) do
    path
    |> to_url(params)
    |> post("", headers())
  end

  defp to_url(path, params) do
    config(:api_base) <> path <> "?" <> to_payload(params)
  end

  defp to_payload(params) do
    params
    |> Map.put(:timestamp, timestamp())
    |> Map.to_list()
    |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
    |> Enum.join("&")
    |> append_signature()
  end

  defp append_signature(argument_string) do
    signature = :crypto.hmac(:sha256, config(:api_secret), argument_string) |> Base.encode16()
    "#{argument_string}&signature=#{signature}"
  end

  defp timestamp(), do: :os.system_time(:millisecond)

  defp headers(), do: [{@api_key_header, config(:api_key)}]

  def post(url, body, headers \\ []) do
    Finch.build(:post, url, headers, body)
    |> Finch.request(CoinFinch)
    |> case do
      {:ok, %Finch.Response{status: status, body: body}} when status >= 200 and status < 300 ->
        Jason.decode(body)

      {:ok, %Finch.Response{body: body}} ->
        {:error, Jason.decode!(body)}

      {:error, error} ->
        {:error, error}
    end
  end

  def config(:api_base),
    do: System.get_env("BINANCE_API_BASE") || "https://testnet.binancefuture.com"

  def config(:api_key), do: System.get_env("BINANCE_API_KEY")
  def config(:api_secret), do: System.get_env("BINANCE_API_SECRET")
end
