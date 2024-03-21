defmodule AppAnimal.Neural.ActionEdgeTest do
  use ClusterCase, async: true
  alias Neural.ActivityLogger

  test "action edges call into the affordances" do
    
    a =
      Network.trace([action_edge(:focus_on_new_paragraph)])
      |> Network.trace([perception_edge(:paragraph_text), to_test()])
      |> AppAnimal.enliven()
    
    AffordanceLand.script(a.p_affordances, [
      focus_on_new_paragraph: [paragraph_text: "some text"]
    ])

    send_test_pulse(a.p_switchboard,
                    to: :focus_on_new_paragraph, carrying: :nothing)
    
    assert_test_receives("some text")
  

    [first, second] = ActivityLogger.get_log(a.p_logger)
    assert_fields(first, name: :focus_on_new_paragraph)
    assert_fields(second, name: :paragraph_text,
                          pulse_data: "some text")
  end
end
