alias AppAnimal.{NetworkBuilder,System}

defmodule System.TopologyTest do
  use ClusterCase, async: true

  # Weird message passing shapes

  test "a sequence of clusters with a loop (repeated clusters)" do
    n = 3

    send_n_times =
      fn _pulse, mutable ->
        mutated =
          %{mutable | pids: [self() | mutable.pids],
                      count: mutable.count - 1}
        if mutated.count >= 0,
           do: pulse(mutated.pids, mutated),
           else: no_pulse(mutated)
      end


    first = C.circular(:first, send_n_times, initial_value: %{pids: [], count: n})

    a = animal(fn builder ->
      NetworkBuilder.trace(builder, [first, :first])
      NetworkBuilder.trace(builder, [:first, forward_to_test()])
    end)

    send_test_pulse(a, to: :first, carrying: :nothing)

    assert_test_receives([pid])
    assert_test_receives([^pid, ^pid])
    assert_test_receives([^pid, ^pid, ^pid])
  end
end
