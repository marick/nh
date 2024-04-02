defmodule AppAnimal.System.AffordanceLandTest do
  use ClusterCase, async: true
  alias System.AffordanceLand, as: UT
  alias System.Pulse

  def given(trace_or_network), do: AppAnimal.affordances(trace_or_network)

  test "a 'self-generated' affordance" do
    given([perception_edge(:big_paragraph_change), to_test()])
    |> UT.cast__produce_affordance(big_paragraph_change: Pulse.new(:no_data))

    assert_test_receives(:no_data)
  end

  test "programming a response to an affordance request" do
    given([perception_edge(:current_paragraph_text), to_test()])
    |> script(
      response_to(:focus_on_paragraph, affords(current_paragraph_text: "para\n"))
    )
    |> take_action(focus_on_paragraph: :no_data)

    assert_test_receives("para\n")
  end

  describe "utilities" do
    test "constructing a script" do
      mutable = %{programmed_responses: []}
      script = [
        response_to(:focus_on_paragraph, affords(affordance: :data)),
        response_to(:other, [affords(other: "more data"),
                             affords(also: "this")])
      ]

      {:noreply, mutated} = UT.handle_cast([script: script], mutable)
      assert mutated.programmed_responses ==
               [focus_on_paragraph: [{:affordance, :data}],
                other:              [{:other, "more data"},
                                     {:also, "this"}]
               ]
    end
  end
end
