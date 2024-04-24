defmodule AppAnimal.System.AffordanceLandTest do
  use ClusterCase, async: true
  alias System.Pulse

  def given(trace), do: animal(trace).p_affordances

  test "a 'self-generated' affordance" do
    given([C.perception_edge(:big_paragraph_change), forward_to_test()])
    |> spontaneous_affordance(named: :big_paragraph_change, 
                              carrying: Pulse.new("data"))

    assert_test_receives("data")
  end

  test "programming a response to an affordance request" do
    given([C.perception_edge(:current_paragraph_text), forward_to_test()])
    |> respond_to_action(:focus_on_paragraph,
                         by_sending_cluster(:current_paragraph_text, "para\n"))
    |> take_action(focus_on_paragraph: :no_data)

    assert_test_receives("para\n")
  end
end
