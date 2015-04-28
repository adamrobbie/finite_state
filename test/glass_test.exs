defmodule GlassTest do
  use ExUnit.Case

  test "initial state is empty" do
    assert Glass.new.state == :empty
  end

  test "can't drink from an empty glass" do
    assert_raise FunctionClauseError, fn ->
      Glass.new |> Glass.drink_all
    end
  end

  test "can drink from a filled glass" do
    x = Glass.new |> Glass.fill_up |> Glass.drink_all
    assert x.state == :empty
  end

  test "can drink multiple times from the glass" do
    x = Glass.new |> Glass.fill_up |> Glass.drink(1) |> Glass.drink(2)
    assert x.data == 7
  end
end
