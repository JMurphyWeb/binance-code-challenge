defmodule CoinFlipperTest do
  use ExUnit.Case
  doctest CoinFlipper

  test "greets the world" do
    assert CoinFlipper.hello() == :world
  end
end
