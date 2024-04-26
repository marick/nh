alias AppAnimal.Cluster

defmodule Cluster.ThrobTest do
  use ClusterCase, async: true
  alias Cluster.Throb, as: UT

  describe "setting up a countdown" do
    test "with just a duration" do
      UT.counting_down_from(Duration.quanta(5))
      |> assert_fields(current_age: Duration.quanta(5),
                       max_age: Duration.quanta(5),
                       f_throb: &UT.count_down/2,
                       f_note_pulse: &UT.pulse_does_nothing/2,
                       f_before_stopping: &UT.stop_silently/2)
    end

    test "with a different `on_pulse` value" do
      UT.counting_down_from(Duration.quanta(5), on_pulse: &UT.pulse_increases_lifespan/2)
      |> assert_fields(current_age: Duration.quanta(5),
                       max_age: Duration.quanta(5),
                       f_throb: &UT.count_down/2,
                       f_note_pulse: &UT.pulse_increases_lifespan/2,
                       f_before_stopping: &UT.stop_silently/2)
    end

    test "can also add a before_stopping: value" do
      UT.counting_down_from(Duration.quanta(5),
                            on_pulse: &UT.pulse_increases_lifespan/2,
                            before_stopping: &UT.pulse_current_value/2)
      |> assert_fields(current_age: Duration.quanta(5),
                       max_age: Duration.quanta(5),
                       f_throb: &UT.count_down/2,
                       f_note_pulse: &UT.pulse_increases_lifespan/2,
                       f_before_stopping: &UT.pulse_current_value/2)
    end
  end

  describe "setting up a count-up" do
    test "with just a duration" do
      UT.counting_up_to(Duration.quanta(1))
      |> assert_fields(current_age: Duration.quanta(0),
                       max_age: Duration.quanta(1),
                       f_throb: &UT.count_up/2,
                       f_note_pulse: &UT.pulse_does_nothing/2,
                       f_before_stopping: &UT.stop_silently/2)
    end

    test "with a different `on_pulse` value" do
      UT.counting_up_to(Duration.quanta(5), on_pulse: &UT.pulse_zeroes_lifespan/2)
      |> assert_fields(current_age: Duration.quanta(0),
                       max_age: Duration.quanta(5),
                       f_throb: &UT.count_up/2,
                       f_note_pulse: &UT.pulse_zeroes_lifespan/2,
                       f_before_stopping: &UT.stop_silently/2)
    end

    test "with an `before_stopping` value" do
      UT.counting_up_to(Duration.quanta(5), on_pulse: &UT.pulse_zeroes_lifespan/2,
                                            before_stopping: &UT.pulse_current_value/2)
      |> assert_fields(current_age: Duration.quanta(0),
                       max_age: Duration.quanta(5),
                       f_throb: &UT.count_up/2,
                       f_note_pulse: &UT.pulse_zeroes_lifespan/2,
                       f_before_stopping: &UT.pulse_current_value/2)
    end

  end

  describe "counting down behavior" do
    test "a throb runs it down a bit" do
      throb = UT.counting_down_from(2)
      assert {:continue, new_throb} = UT.count_down(throb)

      assert_field(new_throb, current_age: 1)
    end

    test "stop when zero is hit" do
      throb = UT.counting_down_from(1)
      assert {:stop, new_throb} = UT.count_down(throb)

      assert_field(new_throb, current_age: 0)
    end

    test "can pack multiple count_downs together for testing" do
      throb = UT.counting_down_from(5)
      assert {:stop, new_throb} = UT.count_down(throb, 5)

      assert_field(new_throb, current_age: 0)
    end

    test "a pulse does not make a difference" do
      throb = UT.counting_down_from(1)
      assert throb == UT.note_pulse(throb, :irrelevant_calculated_value)
    end

    test "but a pulse *can* bump the current age by one" do
      throb = UT.counting_down_from(2, on_pulse: &UT.pulse_increases_lifespan/2)

      {:continue, throb} = UT.count_down(throb)   # take it below the starting value
      assert_field(throb, current_age: 1)

      UT.note_pulse(throb, :irrelevant_calculated_value)
      |> assert_field(current_age: 2)
    end

    test "but it will not go beyond the max" do
      throb = UT.counting_down_from(2, on_pulse: &UT.pulse_increases_lifespan/2)

      {:continue, throb} = UT.count_down(throb)   # take it below the starting value
      assert_field(throb, current_age: 1)

      throb
      |> UT.note_pulse(:irrelevant_calculated_value)
      |> UT.note_pulse(:irrelevant_calculated_value)
      |> UT.note_pulse(:irrelevant_calculated_value)
      |> UT.note_pulse(:irrelevant_calculated_value)
      |> assert_field(current_age: 2)
    end
  end


  describe "counting UP behavior" do
    test "a throb runs it up a bit" do
      throb = UT.counting_up_to(2)
      assert {:continue, new_throb} = UT.count_up(throb)

      assert_field(new_throb, current_age: 1)
    end

    test "stop when maximum age is hit" do
      throb = UT.counting_up_to(1)
      assert_field(throb, current_age: 0)
      assert {:stop, new_throb} = UT.count_up(throb)

      assert_field(new_throb, current_age: 1)
    end

    test "can pack multiple count_downs together for testing" do
      throb = UT.counting_up_to(5)
      assert {:stop, new_throb} = UT.count_up(throb, 5)

      assert_field(new_throb, current_age: 5)
    end

    test "a pulse does not make a difference" do
      throb = UT.counting_up_to(1)
      assert throb == UT.note_pulse(throb, :irrelevant_calculated_value)
    end

    test "but a pulse *can* bump the current age back to zero" do
      throb = UT.counting_up_to(2, on_pulse: &UT.pulse_zeroes_lifespan/2)

      {:continue, throb} = UT.count_up(throb)   # take it above zero
      assert_field(throb, current_age: 1)

      UT.note_pulse(throb, :irrelevant_calculated_value)
      |> assert_field(current_age: 0)
    end

    test "later pulses do nothing" do
      throb = UT.counting_up_to(2, on_pulse: &UT.pulse_zeroes_lifespan/2)

      {:continue, throb} = UT.count_up(throb)   # take it below the starting value
      assert_field(throb, current_age: 1)

      throb
      |> UT.note_pulse(:irrelevant_calculated_value)
      |> UT.note_pulse(:irrelevant_calculated_value)
      |> UT.note_pulse(:irrelevant_calculated_value)
      |> UT.note_pulse(:irrelevant_calculated_value)
      |> assert_field(current_age: 0)
    end
  end
end
