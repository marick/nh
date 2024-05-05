alias AppAnimal.{Scenario,Cluster}

defmodule Cluster.ActionEdgeTest do
  use Scenario.Case, async: true
  # alias System.ActivityLogger

  test "action edges call into Affordance Land, prompting messages out" do


    provocation send_test_pulse(to: :focus_on_new_paragraph, carrying: :nothing)

    configuration do
      trace [C.action_edge(:focus_on_new_paragraph)]

      respond_to_action(:focus_on_new_paragraph,
                        by_sending("some text", to: :paragraph_text))

      trace [C.perception_edge(:paragraph_text),
             forward_to_test()]
    end

    assert_test_receives("some text")

    IO.puts "A use of the activity log that needs to be updated."
    # [first, second] = ActivityLogger.get_log(alive.p_logger)
    # assert_fields(first, name: :focus_on_new_paragraph)
    # assert_fields(second, name: :paragraph_text,
    #                       pulse_data: "some text")
  end
end
