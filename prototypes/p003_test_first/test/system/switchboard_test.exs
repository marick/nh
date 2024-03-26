alias AppAnimal.{System, Network}


defmodule System.SwitchboardTest do
  use ClusterCase, async: true
  alias System.ActivityLogger
  alias Cluster.Make
  
  ## The switchboard is mostly tested via the different kinds of clusters.

  test "the switchboard has a log" do
    IO.puts("=== #{Pretty.Module.minimal(__MODULE__)} (around line #{__ENV__.line}) " <>
              "prints log entries.")
    IO.puts("=== By doing so, I hope to catch cases where log printing breaks.")

    trace = [Make.circular(:first, & &1+1),
             Make.linear(:second, & &1+1),
             to_test()]
    a = AppAnimal.enliven(trace)

    ActivityLogger.spill_log_to_terminal(a.p_logger)
    send_test_pulse(a.p_switchboard, to: :first, carrying: 0)
    assert_test_receives(2)
    
    [first, second] = ActivityLogger.get_log(a.p_logger)
    assert_fields(first, name: :first,
                         pulse_data: 1)
    assert_fields(second, name: :second,
                          pulse_data: 2)
  end

  def given(trace_or_network), do: AppAnimal.switchboard(trace_or_network)

  test "a circular trace" do
    calc = 
      fn _pulse, mutable ->
        mutated = 
          %{mutable | pids: [self() | mutable.pids],
                      count: mutable.count - 1}
        if mutated.count >= 0,
           do: pulse(mutated.pids, mutated),
           else: no_pulse(mutated)
      end
    
    first = circular(:first, calc, initial_value: %{pids: [], count: 3})
    
    network = 
      trace([first, first])
      |> extend(at: :first, with: [to_test()])
    
    given(network)
    |> send_test_pulse(to: :first, carrying: :nothing)
    
    assert_test_receives([pid])
    assert_test_receives([^pid, ^pid])
    assert_test_receives([^pid, ^pid, ^pid])
  end

  test "what happens when a circular cluster 'ages out'" do
    first = circular(:first, fn _pulse -> self() end, starting_lifespan: 2)
    
    a =
      trace([first, to_test()])
      |> AppAnimal.enliven(throb_rate: impossibly_slowly()) 
    
    send_test_pulse(a.p_switchboard, to: :first, carrying: :irrelevant)
    assert_test_receives(pid)

    send(a.p_switchboard, :time_to_throb)
    send_test_pulse(a.p_switchboard, to: :first, carrying: :irrelevant)
    assert_test_receives(^pid)

    send(a.p_switchboard, :time_to_throb)
    # Need to make sure there's time to handle the "down" message, else the pulse will
    # be lost. The app_animal must tolerate dropped messages.
    Process.sleep(100)  
    send_test_pulse(a.p_switchboard, to: :first, carrying: :irrelevant)

    another_pid = assert_test_receives(_)
    refute another_pid == pid
  end
end
