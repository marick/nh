defmodule AppAnimal.Neural.AffordanceLandTest do
  alias AppAnimal.Neural.AffordanceLand
  use ClusterCase, async: true

  test "a simple send downstream" do
    switchboard =
      [affordance(:paragraph_text), endpoint()] |> from_trace()

    affordances = start_link_supervised!({AffordanceLand, switchboard: switchboard})
    AffordanceLand.provide_affordance(affordances, named: :paragraph_text,
                                                   conveying: "some text")
    assert_receive(["some text", from: :endpoint])
  end
end
