defmodule AppAnimal.Neural.AffordancesTest do
  use ClusterCase, async: true
  alias Neural.Affordances, as: UT

  def given(trace_or_network), do: AppAnimal.affordances(trace_or_network)

  test "a 'self-generated' affordance" do
    given([perception_edge(:big_paragraph_change), endpoint()])
    |> UT.produce_this_affordance(big_paragraph_change: :no_data)
    assert_test_receives(:no_data)
  end

  test "programming a response to an affordance request" do
    given([perception_edge(:current_paragraph_text), endpoint()])
    |> UT.script([
      response_to(:focus_on_paragraph, affords(current_paragraph_text: "para\n"))
    ])
    |> UT.note_action(focus_on_paragraph: :no_data)

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
