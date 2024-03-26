alias AppAnimal.Throb

defmodule Throb.CalcTest do
  use ExUnit.Case, async: true
  use FlowAssertions
  alias Throb.Calc, as: UT

  describe "simply running down: default behavior" do
    test "a throb runs it down a bit" do
      logic = UT.new(2)
      assert {:continue, new_logic} = UT.throb(logic)

      assert_field(new_logic, current_strength: 1)
    end

    test "stop when zero is hit" do
      logic = UT.new(1)
      assert {:stop, new_logic} = UT.throb(logic)

      assert_field(new_logic, current_strength: 0)
    end
    
    test "can pack multiple throbs together for testing" do
      logic = UT.new(5)
      assert {:stop, new_logic} = UT.throb(logic, 5)

      assert_field(new_logic, current_strength: 0)
    end
    
    test "a pulse does not make a difference" do
      logic = UT.new(1)
      assert logic == UT.note_pulse(logic, :irrelevant_calculated_value)
    end
  end

  describe "pulses increase the lifespan" do
    test "a pulse bumps the current strength by one" do
      calc = UT.new(2, on_pulse: &UT.pulse_increases_lifespan/2)
      UT.note_pulse(calc, :irrelevant_calculated_value)
      |> assert_field(current_strength: 3)
    end
  end
end
