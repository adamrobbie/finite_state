defmodule GlassServer do
  use ExActor.GenServer

  defstart start_link, do: initial_state(Glass.new)

  for event <- [:fill_up, :drink_all] do
    defcast unquote(event), state: fsm do
      Glass.unquote(event)(fsm)
      |> new_state
    end
  end

  for event <- [:fill, :drink] do
    defcall unquote(event)(data), state: fsm do
      Glass.unquote(event)(fsm, data)
      |> reply
    end
  end
  
  defcall state, state: fsm, do: reply(Glass.state(fsm))
  defcall data, state: fsm, do: reply(Glass.data(fsm))
end
