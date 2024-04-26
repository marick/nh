alias AppAnimal.Scenario

defmodule Scenario.ThrobTest do
  use ClusterCase, async: true

  test "actual throbbing / aging-out behavior" do
    first = C.circular(:first, fn _pulse -> self() end,
                       throb: Cluster.Throb.counting_down_from(2))

    a = animal([first, forward_to_test()])

    send_test_pulse(a, to: :first, carrying: :irrelevant)
    first_pid = assert_test_receives(_)

    throb_all_active(a)
    send_test_pulse(a, to: :first, carrying: :irrelevant)
    assert_test_receives(^first_pid)

    throb_all_active(a)
    # Need to make sure there's time to handle the "down" message, else the pulse will
    # be lost. The app_animal must tolerate dropped messages.
    Process.sleep(100)
    send_test_pulse(a, to: :first, carrying: :irrelevant)

    another_pid = assert_test_receives(_)
    refute another_pid == first_pid
  end
end
