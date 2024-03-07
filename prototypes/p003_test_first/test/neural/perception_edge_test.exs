defmodule AppAnimal.Neural.PerceptionEdgeTest do
  use ClusterCase, async: true

  def given(trace_or_network), do: AppAnimal.affordances(trace_or_network)

  test "edges serve only to fan out" do
    network =
      Network.trace([Cluster.perception_edge(:paragraph_text),
                     Cluster.linear(:reverser,
                                    Cluster.only_pulse(after: &String.reverse/1)),
                     endpoint()])
    |> Network.extend(at: :paragraph_text,
                      with: [Cluster.linear(:joiner, Cluster.only_pulse(after: &(&1 <> &1))),
                             endpoint()])

    a = AppAnimal.enliven(network)
      
    Affordances.send_spontaneous_affordance(a.affordances_pid, paragraph_text: "some text")

    assert_test_receives("some textsome text")
    assert_test_receives("txet emos")

    IO.puts "==TODO== Complete perception-edge-test with an assertion log entry"

    log = ActivityLogger.get_log(a.logger_pid)

    log 
    |> assert_trace([
      # focus_on(:paragraph),
      [paragraph_text: "some text"],
      [reverser: "txet emos"]
    ])

    log
    |> assert_trace([
      #focus_on(:paragraph),
      [paragraph_text: "some text"],
      [joiner: "some textsome text"],
    ])
  end
end
