defmodule AppAnimal.Cluster.PerceptionEdgeTest do
  use ClusterCase, async: true

  def given(trace_or_network), do: AppAnimal.affordances(trace_or_network)

  test "edges serve only to fan out" do
    aa =
      trace([perception_edge(:paragraph_text),
             linear(:reverser, &String.reverse/1),
             to_test()])
      |> extend(at: :paragraph_text,
                with: [linear(:joiner, &(&1 <> &1)),
                       to_test()])
      |> AppAnimal.enliven

    respond_to_action(aa, :focus_on_paragraph,
                      by_sending_cluster(:paragraph_text, "some text"))

    take_action(aa, focus_on_paragraph: :no_data)

    assert_test_receives("some textsome text")
    assert_test_receives("txet emos")

    log = ActivityLogger.get_log(aa.p_logger)

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
