defmodule AppAnimal.Neural.ActionEdgeTest do
  use ClusterCase, async: true
#  alias Neural.ActionEdge, as: UT

#  def given(trace_or_network), do: AppAnimal.affordances(trace_or_network)

  test "" do

      # Network.trace([Cluster.action_edge(:focus_on_new_paragraph)])
      # |> Network.trace([Cluster.perception_edge(:receive_text_affordance)])
      # |> AppAnimal.enliven()
    

    
    #                  Cluster.linear(:one_calculation,
    #                                 Cluster.only_pulse(after: &String.reverse/1)),
    #                  endpoint()])
    # |> Network.extend(at: :paragraph_text,
    #                   with: [Cluster.linear(:another, Cluster.only_pulse(after: &(&1 <> &1))),
    #                          endpoint()])

    # given(network)
    # |> Affordances.send_spontaneous_affordance(paragraph_text: "some text")

    # assert_test_receives("some textsome text")
    # assert_test_receives("txet emos")
  end
end
