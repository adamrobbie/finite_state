defmodule GlassServerTest do
  use ExUnit.Case

  test "initial server should have a inital state of 0" do
    {:ok, pid} = GlassServer.start_link
    assert GlassServer.state(pid) == :empty
  end

  test "the glass server should be completely fillable" do
    {:ok, pid} = GlassServer.start_link
    GlassServer.fill_up(pid)
    assert GlassServer.data(pid) == 10
    GlassServer.drink_all(pid)
    assert GlassServer.data(pid) == 0
  end

  test "the glass server should be completely empty-able" do
    {:ok, pid} = GlassServer.start_link
    GlassServer.fill_up(pid)
    GlassServer.drink_all(pid)
    assert GlassServer.data(pid) == 0
  end

  test "the glass server should be able to take partial drinks" do
    {:ok, pid} = GlassServer.start_link
    GlassServer.fill_up(pid)
    state = GlassServer.drink(pid, 5)
    assert state.data == 5
  end
end
