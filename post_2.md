# A Tour of Finite State Machines in Elixir: Part 2

In my second post in the series on Finite State Machines in Elixir we are going to break out our
pure FSM data structure into its own process, essentially mimicking Erlangs `:gen_fsm` OTP behavior in Elixir.


### Glass.new

First, lets adjust the concept of our state machine. At the present moment we have two possible states with two possible transistions, make a full glass or emtpy the glass. This isn't very much fun, so lets introduce the a 3rd state with some additional transitions to get in and out of that state. Naturally lets introduce the transitions of drink and fill where we can pass in an arbituary amount and and manipulate the amount in the glass. In the previous post I mentioned FSM allows the speicifcaltion of arbituary data and we will be taking advantage of this.

We should adjust our Glass FSM to match our new concept, first with a failing test:

**test/glass_test.exs**

    test "can drink multiple times from the glass" do
      x = Glass.new |> Glass.fill_up |> Glass.drink(1) |> Glass.drink(2)
      assert x.data == 7
    end

This test assumes that we will be able to drink from the glass multiple times until its empty and fill it up mutliple times until its full. I'm going with an erroneous value for the total volume of the glass, setting the `@max_volume` to 10. So we'll add a module attribute to the code and an initial state of 0 using the `FSM` data variable.

**lib/glass_server.ex**

    ...
    use Fsm, initial_state: :empty, inital_data: 0
    @max_volume 10
    ...

Now the existings states and transitions can remain the same but we'll want to add a couple 'global' state transitions to satisify our test.

**lib/glass_server.ex**

    ...
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
      new_volume = amount + volume
      cond do
        new_volume > @max_volume ->
          next_state(:filled, @max_volume)
        new_volume ->
          next_state(:party, new_volume)
      end
    end

Note: normally you want to stay away from global transition events as they can if not thought out properly can get the FSM in an unintended state but it works for our simple example. Purists will tell you that states should be finite and the only way to get in and out of them is through clear and explicit events. Notice the third state we've introduced when the volume isn't full or empty. Its a pretty ambiguous state harking back to classic problem of "Is the glass half empty or half full", but the :party state fits our domain model pretty well, just make sure to put enough thought into your finite state machines.

Running `mix test` we should have passing tests and an updated Glass FSM that we will now back with a process.

### GlassServer.start?

Processes run independently of each other, each using separate memory and communicating with each other by message passing. These processes, while executing different code, do so following a number of common patterns. By examining different examples of Erlang-like concurrency in  a client/server architectures, the generic and specific parts of the code and we extract the generic code to form a process skeleton. In Erlang and Elixir, the most commonly used patterns have been implemented in library modules, commonly referred to as OTP behaviours. `:gen_fsm` is one of these as it offers a standard set of interface functions dealing with the behavior and callbacks necassary to implement.

GenFSM was depreciated in Elixir 0.13 (check), it was decided by the Elixir gods that there existed better --- and easier --- ways to handle FSM's in the language. We are going to implement a standard GenServer process where the state will be a wrapper around our Glass data structure. You'll find seperating the two to be the a prefered design pattern encouraged by Elixir.

We're going to use another library from the talented *Sasa1977*, his ExActor library which will simplify our implementation of a `GenServer` based process. 

**mix.exs**

    deps: [{:exactor, "~> 2.1.0"}, ...]

    mix deps.get

I'm using *ExActor* for a couple of reasons. First, it allows for less code, less code typically means less bugs. Two, it feels as a gentler introduction to OTP behavior, it showcases the Actor/Process design pattern prevalent in Erland /Elixir, its super runtime friendly as its just macros and demonstrates the power of the Elixir Macro system, and third, I'm lazy and wanted to learn a `lix packacge.

Of course, we want to begin by writing a series of tests to confirm our behavior and that our actor acts like an FSM.

**test/glass_server_test.exs**

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


The final product of our glass server:
**lib/glass_server.ex**

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

This will get our tests passing.  Normally, we'd get our tests passing one at a time but for brevity's sake I'm regurgitating all of the code at once. I want to take you through the code line by line, expanding on how the FSM is being used with our ExActor code.

    ...
    use ExActor.GenServer
    ...

will give us the macros necassary for our `GenServer` behavior.

    defstart start_link, do: initial_state(Glass.new)

The `defstart` macro will define our start_link and init function. All we have to do is pass a new instance of the Glass module to our `initial_state` helper function.

Now, the functions to query the state of our process, meaning lets get back the current state of the FSM (make sure not to confuse the state of the FSM with the state of the process, the FSM is essentially the state as a hole of our process), and the current volume stored in the data variable.
    
      ...
      defcall state, state: fsm, do: reply(Glass.state(fsm))
      defcall data, state: fsm, do: reply(Glass.data(fsm))
    end

These are synchronous calls to the server and the caller will expect a result back. `defcall` macro will inject both the public function and the `handle_call` function and would look something like this:

    def state(pid), do: GenServer.call(pid, :state)
    def handle_call(:state, _, state), do: {:reply, state, state}

The following metaprogramming magic will loop through an array of atoms and will define some asynchronous casts to our FSM process.

      for event <- [:fill_up, :drink_all] do
        defcast unquote(event), state: fsm do
          Glass.unquote(event)(fsm)
          |> new_state
        end
      end

Defining the `:fill_up` and the `:drink_all` events as asynchronous calls make sense as we'll know the state of the FSM and shouldn't really care about the state and it will just return an `:ok` to acknowledge the GenServer recieved the message into its process mailbox. `Glass.unquote(event)(fsm)` will get translated to `Glass.fill_up(pid)`

      for event <- [:fill, :drink] do
        defcall unquote(event)(data), state: fsm do
          Glass.unquote(event)(fsm, data)
          |> reply
        end
      end

Very similiar to the `fill_up` and `drink_all` functions we're implementing the new transistions we added earlier. These should be synchronous calls as we do care about the state of our process, hence the `reply` helper function that is essentially a responder provided by ExActor (as is the `new_state` and `initial_state`)

### BlogPost.new |> BlogPost.epilogue

I hope I've showed with the right tools how little code it take to implement a finite state machine backed process in Elixir can be. The macros from ExActor really help to keep the code readable and short. We've touched on alot of concepts here and so I highly encourage you to check out the [Elixir Docs](http://elixir-lang.org/docs/stable/elixir/GenServer.html) and [Mix/OTP getting started](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html) and of course the [ExActor Documentation](http://hexdocs.pm/exactor/)

On the next post in this series, we're going to build on all of this code and show how processes can encapsulate state for us in our programs giving us the power of the concurrent code but that processes can talk to each other thus showing how we can have multiple Finite State Machines talking to each other.
