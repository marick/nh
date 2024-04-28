alias AppAnimal.{System,Scenario}

defmodule System.TerminalLoggingTest do
  use Scenario.Case, async: true
  alias System.ActivityLogger, as: UT
  alias System.Pulse

  test "there is a terminal log option" do
    IO.puts("\n=== #{Pretty.Module.minimal(__MODULE__)} (around line #{__ENV__.line}) " <>
              "prints log entries.")
    IO.puts("=== By doing so, I hope to catch cases where log printing breaks.")

    provocation send_test_pulse(to: :first, carrying: 0)

    configuration terminal_log: true do
      first = C.circular(:first, & &1+1)
      second = C.linear(:second, & &1+1)
      trace [first, second, forward_to_test()]
    end
    assert_test_receives(2)

    [first_entry, second_entry] = UT.get_log(animal().p_logger)

    assert_fields(first_entry, cluster_id: first.id, pulse: Pulse.new(1))
    assert_fields(second_entry, cluster_id: second.id, pulse: Pulse.new(2))
  end
end
