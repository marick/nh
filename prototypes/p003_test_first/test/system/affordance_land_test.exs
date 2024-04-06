defmodule AppAnimal.System.AffordanceLandTest do
  use ClusterCase, async: true
  alias System.AffordanceLand, as: UT
  alias System.Pulse

  def given(trace_or_network), do: AppAnimal.affordances(trace_or_network)

  test "a 'self-generated' affordance" do
    given([perception_edge(:big_paragraph_change), to_test()])
    |> UT.cast__produce_spontaneous_affordance(named: :big_paragraph_change, 
                                               pulse: Pulse.new(:no_data))

    assert_test_receives(:no_data)
  end

  test "programming a response to an affordance request" do
    given([perception_edge(:current_paragraph_text), to_test()])
    |> respond_to_action(:focus_on_paragraph,
                         by_sending_cluster(:current_paragraph_text, "para\n"))
    |> take_action(focus_on_paragraph: :no_data)

    assert_test_receives("para\n")
  end
end
