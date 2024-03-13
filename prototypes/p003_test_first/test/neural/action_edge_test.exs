defmodule AppAnimal.Neural.ActionEdgeTest do
  use ClusterCase, async: true
  alias Neural.ActivityLogger

  test "action edges call into the affordances" do
    
    a =
      Network.trace([action_edge(:focus_on_new_paragraph)])
      |> Network.trace([perception_edge(:paragraph_text), endpoint()])
      |> AppAnimal.enliven()
    

    Affordances.script(a.affordances_pid, [
      focus_on_new_paragraph: [paragraph_text: "some text"]
    ])

    Switchboard.external_pulse(a.switchboard_pid,
                               to: :focus_on_new_paragraph, carrying: :nothing)
    
    assert_test_receives("some text")
  

    [first, second] = ActivityLogger.get_log(a.logger_pid)
    assert_fields(first, name: :focus_on_new_paragraph)
    assert_fields(second, name: :paragraph_text,
                          pulse_data: "some text")
  end
end
