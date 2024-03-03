defmodule AppAnimal.Neural.SwitchboardTest do
  use ClusterCase, async: true
  alias Neural.NetworkBuilder

  ## The switchboard is mostly tested via the different kinds of clusters.

  test "can separate names into linear and circular clusters" do
    irrelevant_forwarder = fn _, _ -> 5 end


    network = NetworkBuilder.independent([Cluster.linear(:linear, irrelevant_forwarder),
                                          Cluster.circular(:circular, irrelevant_forwarder)])

    [:linear, :circular]
    |> Switchboard.separate_by_cluster_type(given: network)
    |> assert_fields(linear: [:linear],
                     circular: [:circular])
  end
end
