defmodule AppAnimal.Neural.PerceptionEdgeTest do
  use ClusterCase, async: true

  test "edges serve only to fan out" do
    network =
      Network.trace([Cluster.perception_edge(:paragraph_text),
                     Cluster.linear(:one_calculation,
                                    Cluster.only_pulse(after: &String.reverse/1)),
                     endpoint()])
    |> Network.extend(at: :paragraph_text,
                      with: [Cluster.linear(:another, Cluster.only_pulse(after: &(&1 <> &1))),
                             endpoint()])
    
    switchboard_pid = switchboard(network: network)
    affordances_pid = affordances(sent_to: switchboard_pid)
    
    Affordances.send_spontaneous_affordance(affordances_pid, paragraph_text: "some text")

    assert_receive(["some textsome text", from: :endpoint])
    assert_receive(["txet emos", from: :endpoint])
  end
end
