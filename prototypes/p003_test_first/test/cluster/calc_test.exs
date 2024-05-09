alias AppAnimal.Cluster

defmodule Cluster.CalcTest do
  use AppAnimal.Case, async: true
  use MoveableAliases
  alias Cluster.Calc, as: UT

  test "default pulses (only) are unwrapped" do
    becomes = run_and_assert(&UT.pulse_or_pulse_data/1)

    Pulse.new(1) |> becomes.(1)
    Pulse.new(:default, 1) |> becomes.(1)
    Pulse.new(:other, 1) |> becomes.(Pulse.new(:other, 1))
  end


  test "assembling a one-argument function's results (linear case)" do
    becomes = run_and_assert(& UT.assemble_result &1, :there_is_no_state)

    :no_result        |> becomes.({:no_result})
    Pulse.new(5)      |> becomes.({:useful_result, Pulse.new(5)})
    Action.new(:name) |> becomes.({:useful_result, Action.new(:name)})

    # For convenience, a non-pulse, non-action result is wrapped as a default Pulse.
    5                 |> becomes.({:useful_result, Pulse.new(5)})
  end

  test "assembling a one-argument function's results (circular/stateful case)" do
    becomes = run_and_assert(& UT.assemble_result &1, "previous state", :state_does_not_change)

    # Function return values are as above.

    :no_result        |> becomes.({:no_result, "previous state"})
    Pulse.new(5)      |> becomes.({:useful_result, Pulse.new(5), "previous state"})
    Action.new(:name) |> becomes.({:useful_result, Action.new(:name), "previous state"})

    # For convenience, a non-pulse, non-action result is wrapped as a default Pulse.
    5                 |> becomes.({:useful_result, Pulse.new(5), "previous state"})
  end


  test "assembling a TWO-argument function's results (circular/stateful case)" do
    becomes = run_and_assert(& UT.assemble_result &1, "unchanged", :state_may_change)

    :no_result            |> becomes.({:no_result, "unchanged"})
    {:no_result, "new"}   |> becomes.({:no_result, "new"})

    {:useful_result, Pulse.new(5),  "new"} |> becomes.({:useful_result, Pulse.new(5),  "new"})
    {:useful_result, Action.new(5), "new"} |> becomes.({:useful_result, Action.new(5), "new"})

    # Convenience cases
    {:useful_result, 5,  "new"}  |> becomes.({:useful_result, Pulse.new(5),       "new"})

           Pulse.new(5)          |> becomes.({:useful_result, Pulse.new(5),        "unchanged"})
          Action.new(:name)      |> becomes.({:useful_result, Action.new(:name),   "unchanged"})
                     {:ok, 5}    |> becomes.({:useful_result, Pulse.new({:ok, 5}), "unchanged"})
  end

  describe "examples of putting it all together" do
    test "an arity-one function does not get nor change the state" do
      f = fn x -> x+1 end
      actual = UT.run(f, on: Pulse.new(1), with_state: "unchanged")
      assert actual == {:useful_result, Pulse.new(2), "unchanged"}
    end

    test "an arity-one function *may* return `:no_result`" do
      f = fn _ -> :no_result end
      assert UT.run(f, on: Pulse.new(1), with_state: "unchanged") == {:no_result, "unchanged"}
    end


    test "a non-default pulse gets passed whole to the calc function" do
      # a plain value returned produces a :default pulse.
      f = fn
        %Pulse{type: :special, data: data} ->
          data <> data
        default_data ->
          default_data + 1
      end

      special_to_default = UT.run(f, on: Pulse.new(:special, "data"), with_state: "unchanged")
      assert special_to_default == {:useful_result, Pulse.new("datadata"), "unchanged"}

      # Note that the function is dual-purpose: `:default` pulses are unwrapped
      default_to_default = UT.run(f, on: Pulse.new(5), with_state: "unchanged")
      assert default_to_default == {:useful_result, Pulse.new(6), "unchanged"}
    end

    test "an arity-two function may return both pulse data and a next state" do
      f = fn pulse_data, state ->
        {:useful_result, pulse_data+1, [pulse_data | state] }
      end

      assert UT.run(f, on: Pulse.new(1), with_state: []) == {:useful_result, Pulse.new(2), [1]}
    end


    test "a pulse return value is passed verbatim" do
      f = fn %Pulse{type: :special, data:  pulse_data}, state ->
        {:useful_result, Pulse.new(:different, pulse_data+1), [pulse_data | state] }
      end

      actual = UT.run(f, on: Pulse.new(:special, 1), with_state: [])
      assert actual == {:useful_result, Pulse.new(:different, 2), [1]}
    end

    test "function may also return a :no_result and a next state" do
      f = fn _, _ -> {:no_result, "next state"} end

      assert UT.run(f, on: Pulse.new(1), with_state: 2) == {:no_result, "next state"}
    end

    test "or just a plain :no_result" do
      f = fn _, _ -> :no_result end

      assert UT.run(f, on: Pulse.new(1), with_state: "unchanged") == {:no_result, "unchanged"}
    end

    test "without one of the two magic atoms returned, it's interpreted as the pulse value" do
      f = fn pulse_data, state ->
        pulse_data + state + 3
      end

      assert UT.run(f, on: Pulse.new(1), with_state: 2) == {:useful_result, Pulse.new(6), 2}
    end
  end

  test "cast_useful_result" do
    # Not testing Moveable, so inject a sending function
    f_cast = fn moveable, cluster ->
      send(self(), {moveable, cluster})
    end

    UT.cast_useful_result({:no_result}, :cluster_stand_in, f_cast)
    refute_receive(_, 10)  # Note: even if it comes late, some test will fail.

    UT.cast_useful_result({:no_result, :state}, :cluster_stand_in, f_cast)
    refute_receive(_, 10)


    UT.cast_useful_result({:useful_result, 5}, :cluster_stand_in, f_cast)
    assert_receive({5, :cluster_stand_in})

    assert UT.cast_useful_result({:useful_result, 5, :state_ignored}, :cluster_stand_in, f_cast)
    assert_receive({5, :cluster_stand_in})
  end

  test "next_state" do
    assert UT.next_state({:useful_result, "retval", "state"}) == "state"
    assert UT.next_state({:no_result, "state"}) == "state"
  end
end
