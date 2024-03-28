alias AppAnimal.Cluster

defmodule Cluster.ThrobTest do
  use ExUnit.Case, async: true
  use FlowAssertions
  alias Cluster.Throb, as: UT

  describe "simply running down: default behavior" do
    test "a throb runs it down a bit" do
      logic = UT.new(2)
      assert {:continue, new_logic} = UT.throb(logic)

      assert_field(new_logic, current_lifespan: 1)
    end

    test "stop when zero is hit" do
      logic = UT.new(1)
      assert {:stop, new_logic} = UT.throb(logic)

      assert_field(new_logic, current_lifespan: 0)
    end
    
    test "can pack multiple throbs together for testing" do
      logic = UT.new(5)
      assert {:stop, new_logic} = UT.throb(logic, 5)

      assert_field(new_logic, current_lifespan: 0)
    end
    
    test "a pulse does not make a difference" do
      logic = UT.new(1)
      assert logic == UT.note_pulse(logic, :irrelevant_calculated_value)
    end
  end

  describe "pulses increase the lifespan" do
    test "a pulse bumps the current lifespan by one" do
      s_calc = UT.new(2, on_pulse: &UT.pulse_increases_lifespan/2)

      {:continue, s_calc} = UT.throb(s_calc)   # take it below starting value
      assert_field(s_calc, current_lifespan: 1)
        
      UT.note_pulse(s_calc, :irrelevant_calculated_value)
      |> assert_field(current_lifespan: 2)
    end

    test "but it does not go beyond the max" do
      s_calc = UT.new(2, on_pulse: &UT.pulse_increases_lifespan/2)

      {:continue, s_calc} = UT.throb(s_calc)   # take it below starting value
      assert_field(s_calc, current_lifespan: 1)

      s_calc
      |> UT.note_pulse(:irrelevant_calculated_value)
      |> UT.note_pulse(:irrelevant_calculated_value)
      |> UT.note_pulse(:irrelevant_calculated_value)
      |> UT.note_pulse(:irrelevant_calculated_value)
      |> assert_field(current_lifespan: 2)
    end
  end
end
