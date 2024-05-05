alias AppAnimal.Scenario


defmodule Scenario.SwitchParagraphTest do
  use Scenario.Case, async: true
  alias AppAnimal.Perceptions.ParagraphGaps

  setup do
    # Pieces
    #   Affordances can inform downstream of cursor moves into new paragraph
    #   Control.NewParagraph
    #   Affordance can request paragraph text as affordance
    #   EdgeDetector (a Summarizer)
    #   BigEdit? A Gate
    #   BigEditChange?  A repetition remover
    #   BigEditSetter
    #   Accept "make affordance border-shows-edit"

    # notice_paragraph_change = Cluster.perception_edge(:big_paragraph_change)
    # react_to_paragraph_change = Cluster.circular(:paragraph_attention,
    #                                              Cluster.focus_on(:paragraph_text))

    # scanned_text = Cluster.perception_edge(:paragraph_text)
    # edge_detector = Cluster.summarizer(:edge_detector, &ParagraphText.edge_detector)
    # big_edit? = Cluster.gate(:big_edit?)

    # network =
    #   Build.trace([notice_paragraph_change, react_to_paragraph_change])
    #   |> Build.trace([scanned_text, edge_detector, big_edit?, to_test()])
    :ok
  end

  @tag :test_uses_sleep
  test "simple run-through" do
    IO.puts "======= switch_paragraph_test ============="

    provocation  spontaneous_affordance(named: :notice_new_paragraph)

    configuration terminal_log: true do
      # new paragraph perception
      trace([C.perception_edge(:notice_new_paragraph),
             C.action_edge(:focus_on_paragraph)])


      respond_to_action(:focus_on_paragraph,
                        by_sending("para\n\npara\n\npara", to: :paragraph_text))

      [:paragraph_text          |> C.perception_edge,
       :paragraph_structure     |> C.summarizer(&ParagraphGaps.summarize/1),
       :gap_count               |> C.summarizer(&ParagraphGaps.gap_count/1),
       :is_big_edit?            |> C.gate(& &1 >= 2),
       :ignore_same_edit_status |> C.forward_unique,
       :wait_for_edit_to_stop   |> C.delay(Duration.seconds(0.2)),
       # :big_edit_wait |> wait_for_quiet(seconds(2))
       # :mark_paragraph_with_big_edit |> action_edge
       forward_to_test()] |> trace
    end

    Process.sleep(200)
    assert_test_receives(2)
  end
end
