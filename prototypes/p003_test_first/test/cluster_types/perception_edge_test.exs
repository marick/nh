alias AppAnimal.{Cluster}

defmodule Cluster.PerceptionEdgeTest do
  use ScenarioCase, async: true


  test "edges serve only to fan out" do
#    _builder = compatibly_start_link(NetworkBuilder.Process, :ok)

    provocation take_action(focus_on_paragraph: :no_data)

    aa = scenario do
      respond_to_action(:focus_on_paragraph,
                        by_sending_cluster(:paragraph_text, "some text"))

      cluster(C.perception_edge(:paragraph_text))
      branch(at: :paragraph_text,
             with: [C.linear(:reverser, &String.reverse/1),
                    :fan_in |> forward_to_test])

      branch(at: :paragraph_text,
             with: [C.linear(:joiner, &(&1 <> &1)),
                    :fan_in])

    end

    assert_test_receives("some textsome text", from: :fan_in)
    assert_test_receives("txet emos", from: :fan_in)

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

#    dbg Add.network(Process.get(:p_network_builder))


  #

  #   Add.after(:paragraph_text, [C.linear(:reverser, &String.reverse/1),
  #                               :fan_in |> forward_to_test]

#  end


  #   start(take_action(focus_on_paragraph: :no_data))

  #   respond_to_action(:focus_on_paragraph,
  #                     by_sending_cluster(:paragraph_text, "some text"))

  #   Add.cluster(builder, C.perception_edge(:paragraph_text))

  #   Add.branch(builder, at: :paragraph_text,
  #                       with: [C.linear(:reverser, &String.reverse/1),
  #                              forward_to_test(:fan_in)])

  #   Add.branch(builder, at: :paragraph_text,
  #                       with: [C.linear(:joiner, &(&1 <> &1)),
  #                              :fan_in])

  #   aa = AppAnimal.from_network(builder)

  #   Process.get(:app_animal_test_affordances).(aa)
  #   Process.get(:app_animal_test_start).(aa)

  #   assert_test_receives("some textsome text", from: :fan_in)
  #   assert_test_receives("txet emos", from: :fan_in)

  #   log = ActivityLogger.get_log(aa.p_logger)

  #   assert_causal_chain(log, [
  #     action_taken(:focus_on_paragraph),
  #     [paragraph_text: "some text"],
  #     [reverser: "txet emos"]
  #   ])

  #   assert_causal_chain(log, [
  #     action_taken(:focus_on_paragraph),
  #     [paragraph_text: "some text"],
  #     [joiner: "some textsome text"],
  #   ])
  end
end
