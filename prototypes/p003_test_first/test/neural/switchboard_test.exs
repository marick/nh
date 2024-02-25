defmodule AppAnimal.Neural.SwitchboardTest do
  use ExUnit.Case, async: true
  alias AppAnimal.Neural
  alias Neural.Switchboard, as: UT
  # import FlowAssertions.TabularA

  test "startup" do

    test_pid = self()
    handle_pulse = fn _switchboard, pulse_data ->
      send(test_pid, pulse_data)
    end
    
    cluster = Neural.CircularCluster.new(:some_cluster, handle_pulse)
    network = %{some_cluster: cluster}

    state = %UT{environment: "irrelevant", network: network}
    switchboard = start_link_supervised!({UT, state})
    UT.send_pulse(via: switchboard, carrying: "pulse data", to: :some_cluster)
    assert_receive("pulse data")
  end
end
