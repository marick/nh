alias AppAnimal.System

defmodule System.ActivityLoggerTest do
  use AppAnimal.Case, async: true
  alias System.ActivityLogger, as: UT
  alias System.Pulse

  test "basic operations" do
    pid = start_link_supervised!({UT,100})

    a_cluster = C.circular(:a_cluster)
    b_cluster = C.linear(:b_cluster)

    UT.log_pulse_sent(pid, a_cluster, Pulse.new("pulse data"))
    UT.log_pulse_sent(pid, b_cluster, Pulse.new(5))



    assert [%UT.PulseSent{} = a, %UT.PulseSent{} = b] = UT.get_log(pid)
    assert_fields(a, cluster_id: a_cluster.id,
                     pulse: Pulse.new("pulse data"))

    assert_fields(b, cluster_id: b_cluster.id,
                     pulse: Pulse.new(5))
  end

  test "log is circular" do
    pid = start_link_supervised!({UT,2})
    a_cluster = C.circular(:a_cluster)
    b_cluster = C.linear(:b_cluster)
    c_cluster = C.perception_edge(:c_name)

    UT.log_pulse_sent(pid, a_cluster, Pulse.new(1))
    UT.log_pulse_sent(pid, b_cluster, Pulse.new(2))
    UT.log_pulse_sent(pid, c_cluster, Pulse.new(3))

    assert [%UT.PulseSent{} = b, %UT.PulseSent{} = c] = UT.get_log(pid)  # A is pushed off
    assert_fields(b, cluster_id: b_cluster.id,
                     pulse: Pulse.new(2))

    assert_fields(c, cluster_id: c_cluster.id,
                     pulse: Pulse.new(3))
  end

end
