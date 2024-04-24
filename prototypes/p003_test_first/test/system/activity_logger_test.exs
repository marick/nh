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

  test "there is a terminal log option" do
    IO.puts("\n=== #{Pretty.Module.minimal(__MODULE__)} (around line #{__ENV__.line}) " <>
              "prints log entries.")
    IO.puts("=== By doing so, I hope to catch cases where log printing breaks.")

    a = animal [C.circular(:first, & &1+1),
                C.linear(:second, & &1+1),
                forward_to_test()]

    ActivityLogger.spill_log_to_terminal(a.p_logger)
    send_test_pulse(a, to: :first, carrying: 0)
    assert_test_receives(2)

    [first, second] = ActivityLogger.get_log(a.p_logger)
    assert_fields(first,  name: :first,  pulse_data: 1)
    assert_fields(second, name: :second, pulse_data: 2)
  end

end
