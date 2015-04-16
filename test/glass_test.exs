defmodule GlassTest do
  use ExUnit.Case

  test "initial state is empty" do
    assert Glass.new.state == :empty
  end

  test "can't drink from an empty glass" do
    assert_raise FunctionClauseError, fn ->
      Glass.new |> Glass.drink
    end
  end

  test "can drink from a filled glass" do
    x = Glass.new |> Glass.fill |> Glass.drink
    assert x.state == :empty
  end
end
