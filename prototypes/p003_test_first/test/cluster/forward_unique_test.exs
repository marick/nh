AppAnimal.Cluster

defmodule Cluster.ForwardUniqueTest do
  use ClusterCase, async: true

  def given(trace_or_network), do: AppAnimal.switchboard(trace_or_network)
  
  test "only unique values pass through" do
    p_switchboard =
      AppAnimal.switchboard([forward_unique(:first), 
                             to_test()])
    
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

  @tag :skip
  test "a cluster can age out and start over" do
    p_switchboard =
      AppAnimal.switchboard([forward_unique(:first, starting_lifespan: 1), to_test()],
                            throb_rate: impossibly_slowly())

    send_test_pulse(p_switchboard, to: :first, carrying: "data")


    # A test pulse increases the lifespan
    assert GenServer.call(p_switchboard, forward: :current_strength, to: :first) == 2
  end
end
