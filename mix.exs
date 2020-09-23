defmodule CoinFlipper.MixProject do
  use Mix.Project

  def project do
    [
      app: :coin_flipper,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {CoinFlipper.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:decimal, "~> 2.0"},
      {:finch, "~> 0.3"},
      {:jason, "~> 1.2"},
      {:vapor, "~> 0.10"}
    ]
  end
end
