defmodule AppAnimal.Neural.ActivityLoggerTest do
  use ClusterCase, async: true
  alias Neural.ActivityLogger, as: UT
  
  test "basic operations" do
    pid = start_link_supervised!({UT,100})
    UT.log(pid, :a_type, :a_name, "pulse data")
    UT.log(pid, :b_type, :b_name, 5)


    assert [a, b] = UT.get_log(pid)
    assert a == %UT.Entry{cluster_type: :a_type, name: :a_name, pulse_data: "pulse data"}
    assert b == %UT.Entry{cluster_type: :b_type, name: :b_name, pulse_data: 5}
  end

  test "log is circular" do
    pid = start_link_supervised!({UT,2})
    UT.log(pid, :a_type, :a_name, 1)
    UT.log(pid, :b_type, :b_name, 2)
    UT.log(pid, :c_type, :c_name, 3)

    assert [b, c] = UT.get_log(pid)  # A is pushed off
    assert b == %UT.Entry{cluster_type: :b_type, name: :b_name, pulse_data: 2}
    assert c == %UT.Entry{cluster_type: :c_type, name: :c_name, pulse_data: 3}
  end

  # The actual working of the terminal log is tested indirectly elsewhere
  test "there is a terminal log option" do
    pid = start_link_supervised!({UT,100})
    UT.spill_log_to_terminal(pid, true)
    # Just checking that calls are correct
    UT.spill_log_to_terminal(pid, false)
  end
  
end
