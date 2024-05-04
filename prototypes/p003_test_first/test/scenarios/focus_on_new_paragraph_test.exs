alias AppAnimal.{Scenario,Cluster}

defmodule Cluster.FocusOnNewParagraphTest do
  use Scenario.Case, async: true

  @tag :skip
  test "scenario" do
    configuration throb_interval: Duration.seconds(0.02) do
      unordered [C.delay(:running, Duration.seconds(3)),
                 C.delay(:unused, Duration.seconds(3))]

      focus_on_paragraph = C.focus_shift(:focus_on_paragraph,
                                         movement_time: Duration.seconds(0.05),
                                         action_type: :perceive_paragraph_shape)

      fan_out(from: focus_on_paragraph, for_pulse_type: :suppress, to: [:running, :unused])

      respond_to_action(:perceive_paragraph_shape,
                        by_sending_cluster(:paragraph_shape, "a shape"))

      trace [C.perception_edge(:paragraph_shape), forward_to_test()]
    end

    send_test_pulse(to: :running, carrying: "occupy yourself")
    refute_receive(_)

    send_test_pulse(to: :focus_on_paragraph, carrying: :paragraph_id_of_some_sort)

    assert_test_receives("a shape")
  end
end
