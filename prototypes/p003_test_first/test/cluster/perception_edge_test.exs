defmodule AppAnimal.Cluster.PerceptionEdgeTest do
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
    |> script(
      response_to(:focus_on_paragraph, affords(paragraph_text: "some text")))
    |> take_action(focus_on_paragraph: :no_data)

    assert_test_receives("some textsome text")
    assert_test_receives("txet emos")

    log = ActivityLogger.get_log(a.p_logger)

    assert_causal_chain(log, [
      action_taken(:focus_on_paragraph),
      [paragraph_text: "some text"],
      [reverser: "txet emos"]
    ])

    assert_causal_chain(log, [
      action_taken(:focus_on_paragraph),
      [paragraph_text: "some text"],
      [joiner: "some textsome text"],
    ])
  end
end
