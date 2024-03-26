alias AppAnimal.Cluster

defmodule Cluster.ThrobLogicTest do
  use ExUnit.Case, async: true
  use FlowAssertions
  alias Cluster.ThrobLogic, as: UT
  

  describe "simply running down" do
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
    
    test "a pulse does not make a difference" do
      logic = UT.new(1)
      assert logic == UT.note_pulse(logic, :irrelevant_pulse_value)
    end
  end
end
