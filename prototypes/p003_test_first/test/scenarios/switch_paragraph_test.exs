defmodule AppAnimal.Scenarios.SwitchParagraphTest do
  use ClusterCase, async: true

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
    #   Build.independent([notice_paragraph_change, react_to_paragraph_change])
    #   |> Build.independent([scanned_text, edge_detector, big_edit?, endpoint()])
    
  end

  @tag :skip
  test "simple run-through" do
    
  end
end
