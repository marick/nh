alias AppAnimal.{Cluster,Scenario}

defmodule Cluster.ForwardUniqueTest do
  use Scenario.Case, async: true

  def current_age(name), do: Animal.peek_at(animal(), :current_age, of: name)
  def pulse(name, data), do: Animal.send_test_pulse(animal(), to: name, carrying: data)

  describe "forward_unique" do
    test "only unique values pass through" do

      configuration do: trace([C.forward_unique(:first),
                               forward_to_test()])

      pulse(:first, 1)
      assert_test_receives(1)

      # Already saw this one, so no pulse is sent
      pulse(:first, 1)
      refute_receive(_)

      # But a new value is sent on
      pulse(:first, 2)
      assert_test_receives(2)

      # And is remembered to avoid future duplicates
      pulse(:first, 2)
      refute_receive(_)
    end

    @tag :test_uses_sleep
    test "a cluster can age out and start over" do
      alias Cluster.Throb

      throb = Throb.counting_down_from(2, on_pulse: &Throb.pulse_increases_lifespan/2)
      first = C.forward_unique(:first, throb: throb)

      animal =
        configuration throb_interval: Duration.foreverish do
          trace([first, forward_to_test()])
        end

      # Start at maximum
      pulse(:first, "data")
      assert_test_receives("data")

      # As usual, a repetition is not forwarded
      pulse(:first, "data")
      refute_receive("data")

      assert current_age(:first) == 2

      # a normal, decrementing throb
      Animal.throb_all_active(animal)
      assert current_age(:first) == 1

      # decrement to zero - should cause exit
      Animal.throb_all_active(animal)
      Animal.throb_all_active(animal)

      Process.sleep(10)   # Alas, need to wait for process death to be found.

      # A test pulse recreates the process
      pulse(:first, "data")
      assert_test_receives("data")
      assert current_age(:first) == 2
    end
  end
end
