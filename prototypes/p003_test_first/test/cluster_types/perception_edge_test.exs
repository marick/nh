alias AppAnimal.{Cluster,Scenario}

defmodule Cluster.PerceptionEdgeTest do
  use Scenario.Case, async: true

  test "perception edges serve only to fan out" do
    provocation take_action(:focus_on_paragraph)

    configuration do
      respond_to_action(:focus_on_paragraph,
                        by_sending("some text", to: :paragraph_text))

      cluster(C.perception_edge(:paragraph_text))
      branch(at: :paragraph_text,
             with: [:reverser |> C.linear(&String.reverse/1),
                    :to_test |> forward_to_test])

      branch(at: :paragraph_text,
             with: [:joiner |> C.linear(&(&1 <> &1)),
                    :to_test])
    end

    assert_test_receives("some textsome text", from: :to_test)
    assert_test_receives("txet emos", from: :to_test)

    IO.puts("update activity log")



    # Dealing causality is being put off.
    # log = ActivityLogger.get_log(animal().p_logger)

    # assert_causal_chain(log, [
    #   action_taken(:focus_on_paragraph),
    #   [paragraph_text: "some text"],
    #   [reverser: "txet emos"]
    # ])

    # assert_causal_chain(log, [
    #   action_taken(:focus_on_paragraph),
    #   [paragraph_text: "some text"],
    #   [joiner: "some textsome text"],
    # ])
  end
end
