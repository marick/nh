defmodule AppAnimal.Neural.SwitchboardTest do
  use ExUnit.Case, async: true
  alias AppAnimal.Neural
  alias Neural.Switchboard, as: UT
  # import FlowAssertions.TabularA
  alias Neural.NetworkBuilder, as: N

  def pulse_to_test do
    test_pid = self()
    fn switchboard: _switchboard, carrying: pulse_data, mutable: state ->
      send(test_pid, pulse_data)
      state
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
    handle_pulse = fn switchboard: switchboard, carrying: pulse_data, mutable: state ->
      UT.send_pulse(switchboard, carrying: pulse_data + 1, from: :first)
      state
    end

    first = N.circular_cluster(:first, handle_pulse)
    second = N.circular_cluster(:second, pulse_to_test())
    switchboard = switchboard_from([first, second])
    
    UT.send_pulse(switchboard, carrying: 1, to: :first)
    assert_receive(2)
  end

  test "succeeding pulses go to the same process" do
    initializer = fn configured_by: _configuration -> [] end
    handle_pulse = fn switchboard: switchboard, carrying: :nothing, mutable: state ->
      new_state = [self() | state]
      UT.send_pulse(switchboard, carrying: new_state, from: :first)
      new_state
    end
    first = N.circular_cluster(:first, initializer, handle_pulse)
    second = N.circular_cluster(:second, pulse_to_test())
    switchboard = switchboard_from([first, second])
    
    UT.send_pulse(switchboard, carrying: :nothing, to: :first)
    [first_pid] = assert_receive(_)

    UT.send_pulse(switchboard, carrying: :nothing, to: :first)
    assert_receive([^first_pid, ^first_pid])
  end

  test "... however, processes 'age out'" do
  end
end
