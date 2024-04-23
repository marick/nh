AppAnimal.Cluster

defmodule Cluster.ForwardUniqueTest do
  use ClusterCase, async: true

  describe "forward_unique" do
    test "only unique values pass through" do
      aa = enliven([forward_unique(:first), to_test()])

      send_test_pulse(aa, to: :first, carrying: 1)
      assert_test_receives(1)

      # Already saw this one, so no pulse is sent
      send_test_pulse(aa, to: :first, carrying: 1)
      refute_receive(_)

      # But a new value is sent on
      send_test_pulse(aa, to: :first, carrying: 2)
      assert_test_receives(2)

      # And is remembered to avoid future duplicates
      send_test_pulse(aa, to: :first, carrying: 2)
      refute_receive(_)
    end

    @tag :test_uses_sleep
    test "a cluster can age out and start over" do
      alias Cluster.Throb

      throb = Throb.counting_down_from(2, on_pulse: &Throb.pulse_increases_lifespan/2)
      first = forward_unique(:first, throb: throb)

      aa = enliven([first, to_test()], throb_interval: Duration.foreverish)

      # Start at maximum
      send_test_pulse(aa, to: :first, carrying: "data")
      assert_test_receives("data")

      # As usual, a repetition is not forwarded
      send_test_pulse(aa, to: :first, carrying: "data")
      refute_receive("data")

      assert peek_at(aa, :current_age, of: :first) == 2

      # a normal, decrementing throb
      throb_all_active(aa)
      assert peek_at(aa, :current_age, of: :first) == 1

      # decrement to zero - should cause exit
      throb_all_active(aa)
      throb_all_active(aa)

      Process.sleep(10)   # Alas, need to wait for process death to be found.

      # A test pulse recreates the process
      send_test_pulse(aa, to: :first, carrying: "data")
      assert_test_receives("data")
      assert peek_at(aa, :current_age, of: :first) == 2
    end
  end
end
