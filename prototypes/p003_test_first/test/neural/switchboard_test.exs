defmodule AppAnimal.Neural.SwitchboardTest do
  use ExUnit.Case, async: true
  alias AppAnimal.Neural
  alias Neural.Switchboard, as: UT
  # import FlowAssertions.TabularA
  alias Neural.NetworkBuilder, as: N

  def pulse_to_test do
    test_pid = self()
    fn _switchboard, pulse_data ->
      send(test_pid, pulse_data)
    end
  end

  def switchboard_from(clusters) when is_list(clusters) do
    network = N.start(clusters)
    state = %UT{environment: "irrelevant", network: network}
    start_link_supervised!({UT, state})
  end    
    
  test "a single-cluster chain" do
    switchboard = switchboard_from([N.circular_cluster(:some_cluster, pulse_to_test())])
    UT.send_pulse(switchboard, carrying: "pulse data", to: :some_cluster)
    assert_receive("pulse data")
  end

  test "a transmission of pulses" do
    first = N.circular_cluster(:first, fn switchboard, pulse_data ->
      UT.send_pulse(switchboard, carrying: pulse_data + 1, from: :first)
    end)

    second = N.circular_cluster(:second, pulse_to_test())

    switchboard = switchboard_from([first, second])
    
    UT.send_pulse(switchboard, carrying: 1, to: :first)
    assert_receive(2)
  end
  
end
