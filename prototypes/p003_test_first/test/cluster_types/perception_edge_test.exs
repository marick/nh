alias AppAnimal.{Cluster,NetworkBuilder}

defmodule Cluster.PerceptionEdgeTest do
  use ClusterCase, async: true


  def start(f) do
    Process.put(:app_animal_test_start, f)
  end

  def take_action(opts) do
    fn aa -> take_action(aa, opts) end
  end

  def respond_to_action(action, canned_response) do
    f = fn aa -> respond_to_action(aa, action, canned_response) end
    Process.put(:app_animal_test_affordances, f)
  end


  test "edges serve only to fan out" do
    builder = start_link_supervised!(NetworkBuilder.Process)


  # scenario(starts_with: take_action(focus_on_paragraph: :no_data)) do

  #   respond_to_action(:focus_on_paragraph,
  #                     by_sending_cluster(:paragraph_text, "some text"))

  #   Add.cluster(C.perception_edge(:paragraph_text))

  #   Add.after(:paragraph_text, [C.linear(:reverser, &String.reverse/1),
  #                               :fan_in |> forward_to_test]

  #   Add.after(:paragraph_text, [C.linear(:joiner, &(&1 <> &1)),
  #                               :fan_in])
  # end


    start(take_action(focus_on_paragraph: :no_data))

    respond_to_action(:focus_on_paragraph,
                      by_sending_cluster(:paragraph_text, "some text"))

    Add.cluster(builder, C.perception_edge(:paragraph_text))

    Add.branch(builder, at: :paragraph_text,
                        with: [C.linear(:reverser, &String.reverse/1),
                               forward_to_test(:fan_in)])

    Add.branch(builder, at: :paragraph_text,
                        with: [C.linear(:joiner, &(&1 <> &1)),
                               :fan_in])

    aa = AppAnimal.from_network(builder)

    Process.get(:app_animal_test_affordances).(aa)
    Process.get(:app_animal_test_start).(aa)

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
  end
end
