alias AppAnimal.Scenarios


defmodule Scenarios.SwitchParagraphTest do
  use ClusterCase, async: true
  import AppAnimal.Cluster.Make
  alias AppAnimal.Calc.ParagraphGaps

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

  test "simple run-through" do
    IO.puts "======= switch_paragraph_test ============="
    new_paragraph_perception = [
      :notice_new_paragraph |> perception_edge,
      :focus_on_paragraph   |> action_edge,
    ]

    response_to_paragraph_text = [
      :paragraph_text          |> perception_edge,
      :paragraph_structure     |> summarizer(&ParagraphGaps.summarize/1),
      :gap_count               |> summarizer(&ParagraphGaps.gap_count/1),
      :is_big_edit?            |> gate(& &1 >= 2),
      :ignore_same_edit_status |> forward_unique,
      :wait_for_edit_to_stop   |> delay(Duration.seconds(0.1)),
      # :big_edit_wait |> wait_for_quiet(seconds(2))
      # :mark_paragraph_with_big_edit |> action_edge
      to_test()
    ]

    a = 
      trace(new_paragraph_perception)
      |> trace(response_to_paragraph_text)
      |> AppAnimal.enliven

    a.p_affordances
    |> respond_to_action(:focus_on_paragraph,
                         by_sending_cluster(:paragraph_text, "para\n\npara\n\npara"))

    ActivityLogger.spill_log_to_terminal(a.p_logger)
    spontaneous_affordance(a.p_affordances, named: :notice_new_paragraph)

    # assert_test_receives(2)
    # ActivityLogger.get_log(a.p_logger)
  end
end
