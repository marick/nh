defmodule AppAnimal.Cluster.ActionEdgeTest do
  use ClusterCase, async: true
  alias System.ActivityLogger

  test "action edges call into Affordance Land, prompting messages out" do
    a =
      trace([action_edge(:focus_on_new_paragraph)])
      |> trace([perception_edge(:paragraph_text), to_test()])
      |> AppAnimal.enliven()

    a.p_affordances
    |> respond_to_action(:focus_on_new_paragraph,
                         by_sending_cluster(:paragraph_text, "some text"))

    send_test_pulse(a.p_switchboard,
                    to: :focus_on_new_paragraph, carrying: :nothing)

    assert_test_receives("some text")

    [first, second] = ActivityLogger.get_log(a.p_logger)
    assert_fields(first, name: :focus_on_new_paragraph)
    assert_fields(second, name: :paragraph_text,
                          pulse_data: "some text")
  end
end
