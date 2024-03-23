defmodule AppAnimal.System.PerceptionEdgeTest do
  use ClusterCase, async: true

  def given(trace_or_network), do: AppAnimal.affordances(trace_or_network)

  test "edges serve only to fan out" do
    network =
      trace([perception_edge(:paragraph_text),
             linear(:reverser, &String.reverse/1),
             to_test()])
      |> extend(at: :paragraph_text,
                with: [linear(:joiner, &(&1 <> &1)),
                       to_test()])

    a = AppAnimal.enliven(network)

    a.p_affordances
    |> script([
      focus_on_paragraph: [paragraph_text: "some text"]
    ])
    |> note_action(focus_on_paragraph: :no_data)

    assert_test_receives("some textsome text")
    assert_test_receives("txet emos")

    log = ActivityLogger.get_log(a.p_logger)

    log 
    |> assert_trace([
      action(:focus_on_paragraph),
      [paragraph_text: "some text"],
      [reverser: "txet emos"]
    ])

    log
    |> assert_trace([
      action(:focus_on_paragraph),
      [paragraph_text: "some text"],
      [joiner: "some textsome text"],
    ])
  end
end
