alias AppAnimal.Cluster

defmodule Cluster.CircularProcessTest do
  use ClusterCase, async: true
  alias Cluster.CircularProcess, as: UT

  describe "initialization" do 
    test "with default starting value" do

      cluster = circular(:example, & &1+1)
      state = UT.State.from_cluster(cluster)

      state
      |> assert_fields(calc: cluster.calc,
                       previously: %{})

      starting_pulses = cluster.shape.starting_pulses
      assert state.timer_logic == %UT.TimerLogic{current_strength: starting_pulses,
                                                 starting_strength: starting_pulses}
    end

    test "with a given starting value" do
      circular(:example, & &1+1, initial_value: 777)
      |> UT.State.from_cluster
      |> assert_field(previously: 777)
    end
  end

  describe "handling of a calculation" do
    test "choosing to pulse, no change to state" do
      calc = fn
        :report_state, state -> state
        pulse_data, _state -> pulse_data + 1
      end

      p_switchboard =
        Network.trace([circular(:first, calc, initial_value: "will be unchanged"), to_test()])
        |> AppAnimal.switchboard

      send_test_pulse(p_switchboard, to: :first, carrying: 3)
      assert_test_receives(4)

      send_test_pulse(p_switchboard, to: :first, carrying: :report_state)
      assert_test_receives("will be unchanged")
    end

    test "choosing to pulse and change state" do
      calc = fn
        :report_state, state -> state
        pulse_data, state -> pulse(pulse_data + 1, [pulse_data | state])
      end

      p_switchboard =
        Network.trace([circular(:first, calc, initial_value: []), to_test()])
        |> AppAnimal.switchboard

      send_test_pulse(p_switchboard, to: :first, carrying: 3)
      assert_test_receives(4)

      send_test_pulse(p_switchboard, to: :first, carrying: :report_state)
      assert_test_receives([3])
    end

    test "choosing not to pulse, state changes" do
      calc = fn
        :report_state, state -> state
        pulse_data, state -> no_pulse([pulse_data | state])
      end

      p_switchboard =
        Network.trace([circular(:first, calc, initial_value: []), to_test()])
        |> AppAnimal.switchboard

      send_test_pulse(p_switchboard, to: :first, carrying: 3)
      refute_receive(_)

      send_test_pulse(p_switchboard, to: :first, carrying: :report_state)
      assert_test_receives([3])
    end      

  end

  describe "counting down via weaken" do
    test "an ordinary call to weaken" do
      state = circular(:example, & &1+1) |> UT.State.from_cluster
            starting_strength = deeply_get_only(state, :l_current_strength)
      assert starting_strength == deeply_get_only(state, :l_starting_strength)
      assert starting_strength > 2
      
      assert {:noreply, next_state} = UT.handle_cast([weaken: 2], state)
      
      assert deeply_get_only(next_state, :l_current_strength) ==
               deeply_get_only(state, :l_current_strength) - 2
    end
    
    test "decreasing down to zero" do
      state = circular(:example, & &1+1) |> UT.State.from_cluster
      starting_strength = deeply_get_only(state, :l_current_strength)

      assert {:stop, :normal, next_state} = UT.handle_cast([weaken: starting_strength], state)
      assert deeply_get_only(next_state, :l_current_strength) == 0
    end
  end
end
