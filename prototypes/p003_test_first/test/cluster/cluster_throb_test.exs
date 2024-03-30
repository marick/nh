alias AppAnimal.Cluster

defmodule Cluster.ThrobTest do
  use ExUnit.Case, async: true
  use FlowAssertions
  alias Cluster.Throb, as: UT
  alias AppAnimal.Duration

  describe "creation" do
    test "with only defaults" do
      %UT{}
      |> assert_fields(current_lifespan: Duration.frequent_glance,
                       starting_lifespan: Duration.frequent_glance,
                       f_note_pulse: &UT.pulse_does_nothing/2)
    end
    
    test "with just a duration" do
      UT.starting(Duration.quanta(5))
      |> assert_fields(current_lifespan: Duration.quanta(5),
                       starting_lifespan: Duration.quanta(5),
                       f_note_pulse: &UT.pulse_does_nothing/2)
    end
    
    test "with just a function" do
      UT.starting(&UT.pulse_increases_lifespan/2)
      |> assert_fields(current_lifespan: Duration.frequent_glance,
                       starting_lifespan: Duration.frequent_glance,
                       f_note_pulse: &UT.pulse_increases_lifespan/2)
    end

    test "with both arguments" do
      UT.starting(5, on_pulse: &UT.pulse_increases_lifespan/2)
      |> assert_fields(current_lifespan: 5,
                       starting_lifespan: 5,
                       f_note_pulse: &UT.pulse_increases_lifespan/2)
    end
    
  end

  describe "simply running down: default behavior" do
    test "a throb runs it down a bit" do
      logic = UT.starting(2)
      assert {:continue, new_logic} = UT.count_down(logic)

      assert_field(new_logic, current_lifespan: 1)
    end

    test "stop when zero is hit" do
      logic = UT.starting(1)
      assert {:stop, new_logic} = UT.count_down(logic)

      assert_field(new_logic, current_lifespan: 0)
    end
    
    test "can pack multiple count_downs together for testing" do
      logic = UT.starting(5)
      assert {:stop, new_logic} = UT.count_down(logic, 5)

      assert_field(new_logic, current_lifespan: 0)
    end
    
    test "a pulse does not make a difference" do
      logic = UT.starting(1)
      assert logic == UT.note_pulse(logic, :irrelevant_calculated_value)
    end
  end

  describe "pulses increase the lifespan" do
    test "a pulse bumps the current lifespan by one" do
      s_calc = UT.starting(2, on_pulse: &UT.pulse_increases_lifespan/2)

      {:continue, s_calc} = UT.count_down(s_calc)   # take it below starting value
      assert_field(s_calc, current_lifespan: 1)
        
      UT.note_pulse(s_calc, :irrelevant_calculated_value)
      |> assert_field(current_lifespan: 2)
    end

    test "but it does not go beyond the max" do
      s_calc = UT.starting(2, on_pulse: &UT.pulse_increases_lifespan/2)

      {:continue, s_calc} = UT.count_down(s_calc)   # take it below starting value
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
