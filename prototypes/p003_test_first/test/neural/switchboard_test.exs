defmodule AppAnimal.Neural.SwitchboardTest do
  use ClusterCase, async: true
  require Neural.Switchboard

  ## The switchboard is mostly tested via the different kinds of clusters.

  test "can separate names into linear and circular clusters" do
    irrelevant_forwarder = fn _, _ -> 5 end

    network = Network.trace([Cluster.linear(:linear, irrelevant_forwarder),
                             Cluster.circular(:circular, irrelevant_forwarder)])

    [:linear, :circular]
    |> Switchboard.separate_by_cluster_type(given: network)
    |> assert_fields(linear: [:linear],
                     circular: [:circular])
  end


  test "succeeding pulses go to the same process" do
    first = Cluster.circular(:first,
                             constantly(%{}),
                             Cluster.one_pulse(after: & &1+1))
    second = Cluster.linear(:second, Cluster.only_pulse(after: & &1+1))
                               
    switchboard = from_trace([first, second, endpoint()])

    IO.puts("=== #{Pretty.Module.minimal(__MODULE__)} (around line #{__ENV__.line}) " <>
              "produces `info` entries, to catch crashes.")
    Switchboard.spill_log_to_terminal(switchboard)

    Switchboard.external_pulse(switchboard, to: :first, carrying: 0)
    assert_test_receives(2)
    
    [first, second] = Switchboard.get_log(switchboard)
    assert_fields(first, name: :first,
                         pulse_data: 1)
    assert_fields(second, name: :second,
                          pulse_data: 2)
  end
end
