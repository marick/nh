alias AppAnimal.Cluster

defmodule Cluster.CircularProcessTest do
  use ClusterCase, async: true
  alias Cluster.CircularProcess, as: UT
  alias Cluster.Make

  describe "initialization" do 
    test "with default starting value" do

      cluster = Make.circular(:example, & &1+1)
      state = UT.State.from_cluster(cluster)

      state
      |> assert_fields(shape: cluster.shape,
                       calc: cluster.calc,
                       pulse_logic: cluster.pulse_logic,
                       previously: %{})

      starting_pulses = cluster.shape.starting_pulses
      assert state.timer_logic == %UT.TimerLogic{current_strength: starting_pulses,
                                                 starting_strength: starting_pulses}
    end


    test "with a given starting value" do
      Make.circular(:example, & &1+1, initial_value: 777)
      |> UT.State.from_cluster
      |> assert_field(previously: 777)
    end
    
  end

  def with_calc(calc, opts \\ []) do
    cluster = Make.circular(:example, calc, opts)
    UT.State.from_cluster(cluster)
  end    

  describe "calculations" do
    test "an arity 1 function gets just the pulse value" do
      # and does not change the state
      state = with_calc(& &1+1)
      assert {:pulse, 2, next_previously} = UT.run_calculation(state, 1)
      assert next_previously == state.previously
    end
    
    test "an arity 2 function gets just the pulse value" do
      state = with_calc(& [&1 | &2], initial_value: [])
      assert {:pulse, [1], next_previously} = UT.run_calculation(state, 1)
      assert next_previously == state.previously
    end

    test "a function can return a tuple containing a new pulse value and a next state" do
      f = fn pulse_data -> pulse(pulse_data+1, :next_value) end

      state = with_calc(f, initial_value: [])
      assert {:pulse, 2, :next_value} = UT.run_calculation(state, 1)
    end
  end

  describe "updating a state" do
    test "no update to be done" do
      state = with_calc(& &1)
      next_state = UT.update_state(state, {:pulse, 1})
      assert next_state == state
    end

    test "the function returns an update" do
      with_calc(& &1)
      |> UT.update_state({:pulse, 1, :the_next_value})
      |> assert_field(previously: :the_next_value)
    end
  end

  describe "handle_pulse, which puts it together" do
    test "init" do
      assert UT.init("state") == {:ok, "state"}
    end

    test "pulse handling" do
      f = fn pulse_data ->
        pulse(pulse_data+1, :next_value)
      end

      state =
        with_calc(f, initial_value: :initial)
        |> Map.put(:pulse_logic, Cluster.PulseLogic.Test.new(:test, self()))
      assert {:noreply, next_state} = UT.handle_cast([handle_pulse: 1], state)
      assert_same_map(next_state, state,
                      except: [previously: :next_value])

      assert_test_receives(2, from: :test)
    end

    test "a process can decline to pulse, but state still gets updated" do
      f = fn _pulse_data -> no_pulse(:next_value) end
      
      state =
        with_calc(f, initial_value: :initial)
        |> Map.put(:pulse_logic, Cluster.PulseLogic.Test.new(:test, self()))
      assert {:noreply, next_state} = UT.handle_cast([handle_pulse: 1], state)
      assert_same_map(next_state, state,
                      except: [previously: :next_value])

      refute_receive(_)
    end
  end

  describe "counting down via weaken" do
    test "an ordinary call to weaken" do
      state = Make.circular(:example, & &1+1) |> UT.State.from_cluster
            starting_strength = lens_one!(state, :_current_strength)
      assert starting_strength == lens_one!(state, :_starting_strength)
      assert starting_strength > 2
      
      assert {:noreply, next_state} = UT.handle_cast([weaken: 2], state)
      
      assert lens_one!(next_state, :_current_strength) ==
               lens_one!(state, :_current_strength) - 2
    end
    
    test "decreasing down to zero" do
      state = Make.circular(:example, & &1+1) |> UT.State.from_cluster
      starting_strength = lens_one!(state, :_current_strength)

      assert {:stop, :normal, next_state} = UT.handle_cast([weaken: starting_strength], state)
      assert lens_one!(next_state, :_current_strength) == 0
    end
  end
end
