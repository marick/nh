alias AppAnimal.Scenario

defmodule Scenario.ThrobTest do
  use Scenario.Case, async: true

  @tag :test_uses_sleep
  test "actual throbbing / aging-out behavior" do
    first = C.circular(:first, fn _pulse -> self() end,
                       throb: Throb.counting_down_from(2))

    animal =
      configuration do: trace([first, forward_to_test()])

    Animal.send_test_pulse(animal, to: :first, carrying: :irrelevant)
    first_pid = assert_test_receives(_)

    Animal.throb_all_active(animal)
    Animal.send_test_pulse(animal, to: :first, carrying: :irrelevant)
    assert_test_receives(^first_pid)

    Animal.throb_all_active(animal)
    # Need to make sure there's time to handle the "down" message, else the pulse will
    # be lost. The app_animal must tolerate dropped messages.
    Process.sleep(10)
    Animal.send_test_pulse(animal, to: :first, carrying: :irrelevant)

    another_pid = assert_test_receives(_)
    refute another_pid == first_pid
  end
end
