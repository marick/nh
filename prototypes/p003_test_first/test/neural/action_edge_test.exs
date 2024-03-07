defmodule AppAnimal.Neural.ActionEdgeTest do
  use ClusterCase, async: true
  alias Neural.ActivityLogger

  test "action edges call into the affordances" do
    
    a =
      Network.trace([Cluster.action_edge(:focus_on_new_paragraph)])
      |> AppAnimal.enliven()

    ActivityLogger.spill_log_to_terminal(a.logger_pid)
    Switchboard.external_pulse(a.switchboard_pid,
                               to: :focus_on_new_paragraph, carrying: :nothing)
    Process.sleep(300)
    [only_entry] = ActivityLogger.get_log(a.logger_pid)
    only_entry
    |> assert_fields(name: :focus_on_new_paragraph,
                     pulse_data: :nothing)
    IO.inspect("=====  continue in #{__MODULE__}")
  end
end
