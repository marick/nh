defmodule AppAnimal.Neural.ActivityLoggerTest do
  use ClusterCase, async: true
  alias Neural.ActivityLogger, as: UT
  
  test "basic operations" do
    pid = start_link_supervised!({UT,100})
    UT.log_pulse_sent(pid, :a_type, :a_name, "pulse data")
    UT.log_pulse_sent(pid, :b_type, :b_name, 5)


    assert [a, b] = UT.get_log(pid)
    assert a == %UT.PulseSent{cluster_type: :a_type, name: :a_name, pulse_data: "pulse data"}
    assert b == %UT.PulseSent{cluster_type: :b_type, name: :b_name, pulse_data: 5}
  end

  test "there is shorthand useful for tests" do
    pid = start_link_supervised!({UT,100})
    UT.log_pulse_sent(pid, :a_type, :a_name, "pulse data")

    assert [entry] = UT.get_log(pid)
    assert entry == UT.PulseSent.new(:a_type, :a_name, "pulse data")

    assert UT.PulseSent.matches?(entry, :a_type, :a_name)
    assert UT.PulseSent.matches?(entry, :a_name)
  end

  test "log is circular" do
    pid = start_link_supervised!({UT,2})
    UT.log_pulse_sent(pid, :a_type, :a_name, 1)
    UT.log_pulse_sent(pid, :b_type, :b_name, 2)
    UT.log_pulse_sent(pid, :c_type, :c_name, 3)

    assert [b, c] = UT.get_log(pid)  # A is pushed off
    assert b == %UT.PulseSent{cluster_type: :b_type, name: :b_name, pulse_data: 2}
    assert c == %UT.PulseSent{cluster_type: :c_type, name: :c_name, pulse_data: 3}
  end

  # The actual working of the terminal log is tested indirectly elsewhere
  test "there is a terminal log option" do
    pid = start_link_supervised!({UT,100})
    UT.spill_log_to_terminal(pid)
    # Just checking that calls are correct
    UT.silence_terminal_log(pid)
  end
  
end
