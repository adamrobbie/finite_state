defmodule Glass do
  use Fsm, initial_state: :empty, inital_data: 0
  @max_volume 10

  defstate empty do
    defevent fill_up do          
      next_state(:filled, @max_volume)
    end
  end

  defstate filled do
    defevent drink_all do
      next_state(:empty, 0)
    end
  end

  # Global Event Handlers
  defevent drink(amount), data: volume do
    new_volume = volume - amount
    cond do
      new_volume <= 0 ->
        next_state(:empty, 0)
      new_volume ->
        next_state(:party, new_volume)
    end
  end

  defevent fill(amount), data: volume do
    new_volume=amount+volume
    cond do
      new_volume > @max_volume ->
        next_state(:filled, @max_volume)
      new_volume ->
        next_state(:party, new_volume)
    end
  end
end
