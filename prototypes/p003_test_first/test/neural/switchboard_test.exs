defmodule AppAnimal.Neural.SwitchboardTest do
  use ClusterCase, async: true
  alias Neural.NetworkBuilder

  ## The switchboard is mostly tested via the different kinds of clusters.

  test "can separate names into linear and circular clusters" do
    irrelevant_forwarder = fn _, _ -> 5 end


    network = NetworkBuilder.start([linear_cluster(:linear, irrelevant_forwarder),
                                    circular_cluster(:circular, irrelevant_forwarder)])

    [:linear, :circular]
    |> Switchboard.separate(given: network)
    |> assert_equal(%{Neural.LinearCluster => [:linear],
                      Neural.CircularCluster => [:circular]})
  end
end
