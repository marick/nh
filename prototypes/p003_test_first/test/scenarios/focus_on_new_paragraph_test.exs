alias AppAnimal.{Scenario,Cluster}

defmodule Cluster.FocusOnNewParagraphTest do
  use Scenario.Case, async: true

  test "scenario" do
    rapid_throbs = 20
    long_enough_for_several_throbs = 60
    longer_than_test = 10_000

    animal =
      configuration throb_interval: rapid_throbs do
        # Main flow of control
        cluster C.focus_shift(:focus_on_paragraph,
                              movement_time: long_enough_for_several_throbs,
                              action_type: :perceive_paragraph_shape)

        respond_to_action(:perceive_paragraph_shape,
                          by_sending_cluster(:paragraph_shape, "a shape"))

        trace [C.perception_edge(:paragraph_shape), forward_to_test()]

        # Meanwhile, there are circular clusters perhaps active when the focus shift starts.

        trace [C.delay(:delay1, longer_than_test), forward_to_test(:delay1_result)]
        trace [C.delay(:delay2, longer_than_test), forward_to_test(:delay2_result)]

        # They are suppressed by...
        fan_out(from: :focus_on_paragraph, for_pulse_type: :suppress, to: [:delay1, :delay2])
      end

    # Set up current running clusters

    Animal.send_test_pulse(animal, to: :delay1,
                                   carrying: "hang out until killed")
    # Note delay2 is not running.
    Process.sleep(rapid_throbs * 3) # Give Delay1 some pulses pulses to *not* do anything
    refute_receive(_) # Delay1 hangs on to its pulse.

    # Start things off.

    Animal.send_test_pulse(animal, to: :focus_on_paragraph, carrying: :paragraph_id_of_some_sort)
    assert_test_receives("a shape")

    # Oh, and the running process has been killed.
    assert_test_receives("hang out until killed", from: :delay1_result)

    # But the one that wasn't started is left alone
    refute_receive(_)

  end
end
