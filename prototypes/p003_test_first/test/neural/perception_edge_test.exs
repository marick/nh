defmodule AppAnimal.Neural.PerceptionEdgeTest do
  use ClusterCase, async: true

  def given(trace_or_network), do: AppAnimal.affordances(trace_or_network)

  test "edges serve only to fan out" do
    network =
      Network.trace([Cluster.perception_edge(:paragraph_text),
                     Cluster.linear(:one_calculation,
                                    Cluster.only_pulse(after: &String.reverse/1)),
                     endpoint()])
    |> Network.extend(at: :paragraph_text,
                      with: [Cluster.linear(:another, Cluster.only_pulse(after: &(&1 <> &1))),
                             endpoint()])

    given(network)
    |> Affordances.send_spontaneous_affordance(paragraph_text: "some text")

    assert_test_receives("some textsome text")
    assert_test_receives("txet emos")
  end
end
