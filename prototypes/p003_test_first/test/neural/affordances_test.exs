defmodule AppAnimal.Neural.AffordancesTest do
  use ClusterCase, async: true
  alias Neural.Affordances, as: UT

  def given(trace_or_network), do: AppAnimal.affordances(trace_or_network)

  test "a 'self-generated' affordance" do
    given([Cluster.perception_edge(:big_paragraph_change), endpoint()])
    |> UT.send_spontaneous_affordance(big_paragraph_change: :no_data)
    assert_test_receives(:no_data)
  end

  test "programming a response to an affordance request" do
    given([Cluster.perception_edge(:current_paragraph_text), endpoint()])
    |> UT.program_focus_response(:current_paragraph_text, fn -> "paragraph\n" end)
    |> UT.send_focus_affordance(:current_paragraph_text)
    assert_test_receives("paragraph\n")
  end
end
