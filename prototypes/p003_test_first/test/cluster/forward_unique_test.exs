AppAnimal.Cluster

defmodule Cluster.ForwardUniqueTest do
  use ClusterCase, async: true

  def given(trace_or_network), do: AppAnimal.switchboard(trace_or_network)
  
  test "only unique values pass through" do
    p_switchboard =
      AppAnimal.switchboard([forward_unique(:first), to_test()])
    
    send_test_pulse(p_switchboard, to: :first, carrying: 1)
    assert_test_receives(1)

    # Already saw this one
    send_test_pulse(p_switchboard, to: :first, carrying: 1)
    refute_receive(_)

    # But a new one is sent on
    send_test_pulse(p_switchboard, to: :first, carrying: 2)
    assert_test_receives(2)

    # And is remembered
    send_test_pulse(p_switchboard, to: :first, carrying: 2)
    refute_receive(_)
  end

  @tag :test_uses_sleep
  test "a cluster can age out and start over" do
    alias Cluster.Throb
    throb = Throb.starting(2, on_pulse: &Throb.pulse_increases_lifespan/2)
    first = forward_unique(:first, throb: throb)
    
    p_switchboard =
      AppAnimal.switchboard([first, to_test()],
                            throb_interval: Duration.foreverish)

    # Start at maximum
    send_test_pulse(p_switchboard, to: :first, carrying: "data")
    assert_test_receives("data")
    
    # As usual, a repetition is not forwarded
    send_test_pulse(p_switchboard, to: :first, carrying: "data")
    refute_receive("data")
    
    assert peek_at(p_switchboard, :current_lifespan, of: :first) == 2

    # a normal, decrementing throb
    throb_all_active(p_switchboard)
    assert peek_at(p_switchboard, :current_lifespan, of: :first) == 1

    # decrement to zero - should cause exit
    throb_all_active(p_switchboard)
    throb_all_active(p_switchboard)

    Process.sleep(100)   # Alas, need to wait for process death to be found.

    # A test pulse recreates the process
    send_test_pulse(p_switchboard, to: :first, carrying: "data")
    assert_test_receives("data")
    assert peek_at(p_switchboard, :current_lifespan, of: :first) == 2
  end
end
