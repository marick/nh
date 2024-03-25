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
    reaction_to_new_paragraph = [
      perception_edge(:notice_new_paragraph),
      action_edge(:focus_on_paragraph),
    ]

#    reaction_to_focus = [focus_on_paragraph: [paragraph_text: "para\n\npara\n\npara"]]
    reaction_to_focus = [focus_on_paragraph: [paragraph_text: "para\n\nparapara"]]

    reaction_to_paragraph_text = [
      perception_edge(:paragraph_text),
      summarizer(:paragraph_structure, &ParagraphGaps.summarize/1),
      summarizer(:gap_count, &ParagraphGaps.gap_count/1),
      gate(:is_big_edit?, & &1 >= 2),
      # linear(:count_gaps, only_pulse(after: fn -> 2 end))
      # delay(:desire_to_mark_paragraph_with_big_edit, 2_000)
      # action_edge(:mark_paragraph_with_big_edit)
      to_test()
    ]


    a = 
      trace(reaction_to_new_paragraph)
      |> trace(reaction_to_paragraph_text)
      |> AppAnimal.enliven

    script(a.p_affordances, reaction_to_focus)

    ActivityLogger.spill_log_to_terminal(a.p_logger)

    GenServer.cast(a.p_affordances, [:produce_this_affordance, notice_new_paragraph: :no_data])

    assert_test_receives(2)
    ActivityLogger.get_log(a.p_logger)
    
    
  end
end
