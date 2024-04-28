alias AppAnimal.Scenario

defmodule Scenario.CircularTopologyTest do
  use Scenario.Case, async: true

  test "a sequence of clusters with a loop (repeated clusters)" do
    n = 3

    send_n_times =
      fn _pulse, mutable ->
        mutated =
          %{mutable | pids: [self() | mutable.pids],
                      count: mutable.count - 1}
        if mutated.count >= 0,
           do: C.pulse(mutated.pids, mutated),
           else: C.no_pulse(mutated)
      end
    first = C.circular(:first, send_n_times, initial_value: %{pids: [], count: n})

    provocation send_test_pulse(to: :first, carrying: :nothing)

    configuration do
      trace([first, forward_to_test()])
      trace([:first, :first])
    end

    assert_test_receives([pid])
    assert_test_receives([^pid, ^pid])
    assert_test_receives([^pid, ^pid, ^pid])
  end
end
