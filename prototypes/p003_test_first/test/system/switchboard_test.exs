alias AppAnimal.System


defmodule System.SwitchboardTest do
  use ClusterCase, async: true
  alias System.ActivityLogger

  ## The switchboard is mostly tested via the different kinds of clusters.

  test "the switchboard has a log" do
    IO.puts("\n=== #{Pretty.Module.minimal(__MODULE__)} (around line #{__ENV__.line}) " <>
              "prints log entries.")
    IO.puts("=== By doing so, I hope to catch cases where log printing breaks.")

    a = animal [C.circular(:first, & &1+1),
                C.linear(:second, & &1+1),
                forward_to_test()]

    ActivityLogger.spill_log_to_terminal(a.p_logger)
    send_test_pulse(a, to: :first, carrying: 0)
    assert_test_receives(2)

    [first, second] = ActivityLogger.get_log(a.p_logger)
    assert_fields(first,  name: :first,  pulse_data: 1)
    assert_fields(second, name: :second, pulse_data: 2)
  end


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
      Add.trace(builder, [first, :first])
      Add.trace(builder, [:first, forward_to_test()])
    end)

    send_test_pulse(a, to: :first, carrying: :nothing)

    assert_test_receives([pid])
    assert_test_receives([^pid, ^pid])
    assert_test_receives([^pid, ^pid, ^pid])
  end

  @tag :test_uses_sleep
  test "what happens when a circular cluster 'ages out'" do
#    first = C.circular(:first, fn _pulse -> self() end, max_age: 2) |> dbg

#    a = animal([first, to_test()])

    # send_test_pulse(a, to: :first, carrying: :irrelevant)
    # first_pid = assert_test_receives(_)

    # throb_all_active(a)
    # send_test_pulse(a, to: :first, carrying: :irrelevant)
    # assert_test_receives(^first_pid)

    # throb_all_active(a)
    # # Need to make sure there's time to handle the "down" message, else the pulse will
    # # be lost. The app_animal must tolerate dropped messages.
    # Process.sleep(100)
    # send_test_pulse(a, to: :first, carrying: :irrelevant)

    # another_pid = assert_test_receives(_)
    # refute another_pid == first_pid
  end
end
