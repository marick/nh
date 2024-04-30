alias AppAnimal.{Scenario,Cluster}

defmodule Cluster.FocusOnNewParagraphTest do
  use Scenario.Case, async: true
  alias System.Pulse

  @tag :skip
  test "scenario" do

    provocation send_test_pulse(to: :focus_on_paragraph, carrying: :paragraph_id_of_some_sort)

    # separate functions so I can write them in the order they happen.

    something_has_been_noticed = fn _paragraph_id ->
      :unfinished_body
      # send notice to timer to delay for 50, then send Pulse(timer, id)
      # stash paragraph id
      # no_result
    end

    query_paragraph = fn ->
      :unfinished_body
      # act like an action
    end

    _calc = fn
      %Pulse{type: :timer_finished} = _pulse -> query_paragraph.()
      paragraph_id -> something_has_been_noticed.(paragraph_id)
    end

    animal =
      configuration do
        unordered [C.delay(:running, Duration.seconds(3)),
                   C.delay(:unused, Duration.seconds(3))]

        # trace [C.focus_shift(:focus_on_paragraph, calc, movement_time: 10)]

        fan_out(from: :focus_on_paragraph, for_cluster_type: :suppress, to: [:running, :unused])

        respond_to_action(:paragraph_shape,
                          by_sending_cluster(:paragraph_shape, "a shape"))

        trace [C.perception_edge(:paragraph_summary), forward_to_test()]
      end

    Animal.send_test_pulse(animal, to: :running, carrying: "occupy yourself")

    refute_receive(_)

    Animal.send_test_pulse(animal, to: :focus_on_paragraph, carrying: "paragraph 3")
    assert_test_receives("a shape")
  end
end
