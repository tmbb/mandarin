defmodule BureaucratTest do
  use ExUnit.Case
  doctest Bureaucrat

  test "greets the world" do
    assert Bureaucrat.hello() == :world
  end
end
