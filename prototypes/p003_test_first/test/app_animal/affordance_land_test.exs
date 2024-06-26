alias AppAnimal.Scenario

defmodule AppAnimal.AffordanceLandTest do
  use Scenario.Case, async: true
  alias AppAnimal.Moveable.Pulse

  test "a 'self-generated' affordance" do
    provocation spontaneous_affordance(named: :big_paragraph_change, 
                                       carrying: Pulse.new("data"))

    configuration do
      trace [C.perception_edge(:big_paragraph_change), forward_to_test()]
    end

    assert_test_receives("data")
  end

  test "programming a response to an affordance request" do
    provocation take_action(:focus_on_paragraph) 

    configuration do
      respond_to_action(:focus_on_paragraph,
                        by_sending( "para\n", to: :current_paragraph_text))
      trace [C.perception_edge(:current_paragraph_text), forward_to_test()]
    end

    assert_test_receives("para\n")
  end
end
