defmodule AppAnimal.Neural.SwitchboardTest do
  use ClusterCase, async: true
  require Neural.Switchboard
  alias Neural.Switchboard, as: UT

  ## The switchboard is mostly tested via the different kinds of clusters.

  def given(trace_or_network), do: AppAnimal.switchboard(trace_or_network)

  
  test "can separate names into linear and circular clusters" do
    irrelevant_forwarder = fn _, _ -> 5 end

    network = Network.trace([Cluster.linear(:linear, irrelevant_forwarder),
                             Cluster.circular(:circular, irrelevant_forwarder)])

    [:linear, :circular]
    |> UT.separate_by_cluster_type(given: network)
    |> assert_fields(linear: [:linear],
                     circular: [:circular])
  end


  test "the switchboard has a log" do
    IO.puts("=== #{Pretty.Module.minimal(__MODULE__)} (around line #{__ENV__.line}) " <>
              "produces `info` entries, to catch crashes.")

    switchboard_pid = 
      given([Cluster.circular(:first,
                              constantly(%{}),
                              Cluster.one_pulse(after: & &1+1)),
             Cluster.linear(:second, Cluster.only_pulse(after: & &1+1)),
             endpoint()])

    UT.spill_log_to_terminal(switchboard_pid)
    UT.external_pulse(switchboard_pid, to: :first, carrying: 0)
    assert_test_receives(2)
    
    [first, second] = UT.get_log(switchboard_pid)
    assert_fields(first, name: :first,
                         pulse_data: 1)
    assert_fields(second, name: :second,
                          pulse_data: 2)
  end
end
