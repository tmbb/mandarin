defmodule MandarinTest do
  use ExUnit.Case
  doctest Mandarin

  test "greets the world" do
    assert Mandarin.hello() == :world
  end
end
