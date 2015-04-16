defmodule Glass do
  use Fsm, initial_state: :empty

  defstate empty do
    defevent fill do          
      next_state(:filled)
    end
  end

  defstate filled do
    defevent drink do
      next_state(:empty)
    end
  end
end
