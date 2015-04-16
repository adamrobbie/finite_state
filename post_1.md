# A Tour of Finite States In Elixir - Part 1

I initially started a blog post on the Erlang `gen_fsm` behavior and how it can be implemented in Elixir.
But, I quickly realized the post was going to be long and a bit complicated, so began to look for alternatives.
I've learned that instead of implementing a finite state machine in its own process responsible for maintaining its own state and dealing with all the extra protocols `gen_fsm` requires, there are ways to implement a finite state machine (FSM) as a data type; as a functional data type at that.

### Definition

For all those that fell asleep during that one particular lecture in Comp Sci II where the professor discussed Finite State Machines because they stayed up the previous night playing Counter Strike: a finite state machine an abstract model of computation. Every Turing Machine includes a FSM. Basically, an FSM is a set of states with interactions between those states, called transitions. For those that like lists, an FSM is:

* A bunch of functions, or things that need to get done.
* A bunch of events, or reasons to call these functions.
* Some piece of data that tracks the “state" this bunch of functions is in.
* Code inside the functions that says how to “transition” or “change” into the next state for further processing.

Armed with this brief introduction, lets do some coding.

### Enter the code

We're going to be using [FSM](https://github.com/sasa1977/fsm).

From the author's exact words:
Unlike `gen_fsm`, the `Fsm` data structure has following benefits:

* It is immutable and side-effect free
* No need to create and manage separate processes
* You can persist it, use it via ets, embed it inside `gen_server` or plain processes

Because I like beer, we're going to model a simple process of drinking from a beer glass. In its initial state, our FSM (a glass) will be empty. It will have 2 states, empty and full. The transitions will be fill the glass and drink the beer. In further posts I will taking this simple FSM and adding more complexity.

Lets test drive our initial state.

```elixir
defmodule GlassTest do
  use ExUnit.Case

  test "initial state is empty" do
    assert Glass.new.state == :empty
  end
end
```

Fail! Lets fix this.

```elixir
defmodule Glass do
  use Fsm, initial_state: :empty
end
```

We're green, woot. Now the rest of the tests.

```elixir
  test "can't drink from an empty glass" do
    assert_raise FunctionClauseError, fn ->
      Glass.new |> Glass.drink
    end
  end

  test "can drink from a filled glass" do
    x = Glass.new |> Glass.fill |> Glass.drink
    assert x.state == :empty
  end
```
Lets define some states with the accompanying transitions. 

```elixir
  ...
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
  ...
```

Running `mix test`, we should have all green tests. Now, if at any time, you can query to state (as we see in the tests) of our FSM be calling the state attribute on the internal record of our FSM. *Sass1977* has implemented a pure functional data structure here that won't mutate or leak state and we can even store it in an ETS table. Every FSM in this context has the concept of "data" attached to it along with its state. Every transition returns a new record of state with this data, a new fsm instance.

### It's closing time, you don't have to go home but you can't read here

I highly recommend heading over the *Sass1977* github repos and checkout his other work and play with FSM more. It is capable of so much more beyond our simple example. In Part 2 of our series of **Finite State Machines in Elixir** we'll be tackling `gen_fsm`.
