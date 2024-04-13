AppAnimal.Cluster

defmodule Cluster.MakeSwitchboardTest do
  use ClusterCase, async: true

  describe "forward_unique" do 
    test "only unique values pass through" do
      pids =
        AppAnimal.enliven([forward_unique(:first), to_test()])
    
      send_test_pulse(pids, to: :first, carrying: 1)
      assert_test_receives(1)

      # Already saw this one
      send_test_pulse(pids, to: :first, carrying: 1)
      refute_receive(_)

      # But a new one is sent on
      send_test_pulse(pids, to: :first, carrying: 2)
      assert_test_receives(2)

      # And is remembered
      send_test_pulse(pids, to: :first, carrying: 2)
      refute_receive(_)
    end

    @tag :test_uses_sleep
    test "a cluster can age out and start over" do
      alias Cluster.Throb

      throb = Throb.counting_down_from(2, on_pulse: &Throb.pulse_increases_lifespan/2)
      first = forward_unique(:first, throb: throb)
    
      pids =
        AppAnimal.enliven([first, to_test()],
                          throb_interval: Duration.foreverish)

      # Start at maximum
      send_test_pulse(pids, to: :first, carrying: "data")
      assert_test_receives("data")
    
      # As usual, a repetition is not forwarded
      send_test_pulse(pids, to: :first, carrying: "data")
      refute_receive("data")
    
      assert peek_at(pids, :current_age, of: :first) == 2

      # a normal, decrementing throb
      throb_all_active(pids)
      assert peek_at(pids, :current_age, of: :first) == 1

      # decrement to zero - should cause exit
      throb_all_active(pids)
      throb_all_active(pids)

      Process.sleep(100)   # Alas, need to wait for process death to be found.

      # A test pulse recreates the process
      send_test_pulse(pids, to: :first, carrying: "data")
      assert_test_receives("data")
      assert peek_at(pids, :current_age, of: :first) == 2
    end
  end

  describe "delay" do
    setup do
      pids =
        [delay(:first, 2), to_test()]
        |> AppAnimal.enliven(throb_interval: Duration.foreverish)
                              
      [pids: pids]
    end
      
    test "delay for some throbs", %{pids: pids} do
      send_test_pulse(pids, to: :first, carrying: "data")
      refute_receive("data")

      # It will take two throbs to get data
      throb_all_active(pids)
      refute_receive(_)

      throb_all_active(pids)
      assert_test_receives("data")
    end

    test "a pulse starts the delay over again", %{pids: pids} do
      send_test_pulse(pids, to: :first, carrying: "data")
      refute_receive("data")

      throb_all_active(pids)
      refute_receive(_)
      assert peek_at(pids, :current_age, of: :first) == 1

      # pulse cancels out throbbing
      send_test_pulse(pids, to: :first, carrying: "replacement data")
      refute_receive(_)
      assert peek_at(pids, :current_age, of: :first) == 0

      throb_all_active(pids)
      refute_receive(_)

      # Note that the replacement data is sent
      throb_all_active(pids)
      assert_test_receives("replacement data")
    end
  end
end
