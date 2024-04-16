alias AppAnimal.System

defmodule System.ActivityLoggerTest do
  use ClusterCase, async: true
  alias System.ActivityLogger, as: UT
  alias System.Pulse
  
  test "basic operations" do
    pid = start_link_supervised!({UT,100})
    UT.log_pulse_sent(pid, circular(:a_name), Pulse.new("pulse data"))
    UT.log_pulse_sent(pid, linear(:b_name), Pulse.new(5))


    assert [a, b] = UT.get_log(pid)
    assert a == %UT.PulseSent{cluster_label: :circular, name: :a_name, pulse_data: "pulse data"}
    assert b == %UT.PulseSent{cluster_label: :linear, name: :b_name, pulse_data: 5}
  end

  test "log is circular" do
    pid = start_link_supervised!({UT,2})
    UT.log_pulse_sent(pid, circular(:a_name), Pulse.new(1))
    UT.log_pulse_sent(pid, linear(:b_name), Pulse.new(2))
    UT.log_pulse_sent(pid, perception_edge(:c_name), Pulse.new(3))

    assert [b, c] = UT.get_log(pid)  # A is pushed off
    assert b == %UT.PulseSent{cluster_label: :linear, name: :b_name, pulse_data: 2}
    assert c == %UT.PulseSent{cluster_label: :perception_edge, name: :c_name, pulse_data: 3}
  end

  # The actual working of the terminal log is tested indirectly elsewhere
  test "there is a terminal log option" do
    pid = start_link_supervised!({UT,100})
    UT.spill_log_to_terminal(pid)
    # Just checking that calls are correct
    UT.silence_terminal_log(pid)
  end
  
end
