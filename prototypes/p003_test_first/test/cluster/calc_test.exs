alias AppAnimal.Cluster

defmodule Cluster.CalcTest do
  use ExUnit.Case, async: true
  alias Cluster.Calc

  describe "handling of within-process calculation: arity 1 functions" do 
    test "an arity-one function does not get nor change the state" do
      f = fn x -> x+1 end
      assert Calc.run(f, on: 1, with_state: "unchanged") == {:pulse, 2, "unchanged"}
    end

    test "an arity-one function *may* return `:no_pulse`" do
      f = fn _ -> :no_pulse end
      assert Calc.run(f, on: 1, with_state: "unchanged") == {:no_pulse, "unchanged"}
    end
  end

  describe "within-process calculation: arity 2 functions" do
    test "an arity-two function may return both pulse data and a next state" do
      f = fn pulse_data, state ->
        {:pulse, pulse_data+1, [pulse_data | state] }
      end
      
      assert Calc.run(f, on: 1, with_state: []) == {:pulse, 2, [1]}
    end
    
    test "it may also return a :no_pulse and a next state" do
      f = fn _, _ -> {:no_pulse, "next state"} end
      
      assert Calc.run(f, on: 1, with_state: 2) == {:no_pulse, "next state"}
    end
    
    test "or just a plain :no_pulse" do
      f = fn _, _ -> :no_pulse end
      
      assert Calc.run(f, on: 1, with_state: "unchanged") == {:no_pulse, "unchanged"}
    end
    
    test "without one of the two magic atoms returned, it's interpreted as the pulse value" do
      f = fn pulse_data, state ->
        pulse_data + state + 3
      end
      
      assert Calc.run(f, on: 1, with_state: 2) == {:pulse, 6, 2}
    end
  end
  
  describe "a task calculation" do
    test "a plain return turns into a :pulse tuple" do
      f = fn _ -> {:some_random, :tuple} end

      assert Calc.run(f, on: 1) == {:pulse, {:some_random, :tuple}}
    end

    test "a plain :no_pulse turns into a singleton tuple" do
      f = fn _ -> :no_pulse end

      assert Calc.run(f, on: 1) == {:no_pulse}
    end
  end

  test "maybe_pulse" do
    Calc.maybe_pulse({:no_pulse}, & Process.exit(self(), {:crash, &1}))
    Calc.maybe_pulse({:no_pulse, :state}, & Process.exit(self(), {:crash, &1}))

    assert Calc.maybe_pulse({:pulse, 5}, &(send self(), &1)) == {:pulse, 5}
    assert_receive(5)

    assert Calc.maybe_pulse({:pulse, 5, "state"}, &(send self(), &1)) == {:pulse, 5, "state"}
    assert_receive(5)
  end


  test "next_state" do
    assert Calc.next_state({:pulse, "retval", "state"}) == "state"
    assert Calc.next_state({:no_pulse, "state"}) == "state"
  end
end
