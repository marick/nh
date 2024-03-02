defmodule AppAnimal.Neural.AffordanceLandTest do
  use ClusterCase, async: true

  test "a simple send downstream" do
    switchboard =
      [Cluster.affordance(:paragraph_text), endpoint()] |> from_trace()
    out_there = world_connected_to(switchboard)

    affordance_from!(out_there, paragraph_text: "some text")

    assert_receive(["some text", from: :endpoint])
  end
end
