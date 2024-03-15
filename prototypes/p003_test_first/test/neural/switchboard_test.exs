defmodule AppAnimal.Neural.SwitchboardTest do
  use ClusterCase, async: true
  alias AppAnimal.Neural.ActivityLogger
  alias Neural.Switchboard, as: UT
  alias AppAnimal.Cluster.Make
  
  ## The switchboard is mostly tested via the different kinds of clusters.

  def given(trace_or_network), do: AppAnimal.switchboard(trace_or_network)

  test "the switchboard has a log" do
    IO.puts("=== #{Pretty.Module.minimal(__MODULE__)} (around line #{__ENV__.line}) " <>
              "prints log entries.")
    IO.puts("=== By doing so, I hope to catch cases where log printing breaks.")

    trace = [Make.circular(:first, & &1+1),
             Make.linear(:second, & &1+1),
             to_test()]
    a = AppAnimal.enliven(trace)

    ActivityLogger.spill_log_to_terminal(a.logger_pid)
    UT.external_pulse(a.switchboard_pid, to: :first, carrying: 0)
    assert_test_receives(2)
    
    [first, second] = ActivityLogger.get_log(a.logger_pid)
    assert_fields(first, name: :first,
                         pulse_data: 1)
    assert_fields(second, name: :second,
                          pulse_data: 2)
  end

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
      Network.trace([first, first])
      |> Network.extend(at: :first, with: [to_test()])
    
    given(network)
    |> Switchboard.external_pulse(to: :first, carrying: :nothing)
    
    assert_test_receives([pid])
    assert_test_receives([^pid, ^pid])
    assert_test_receives([^pid, ^pid, ^pid])
  end
end
