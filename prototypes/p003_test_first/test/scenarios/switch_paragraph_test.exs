defmodule AppAnimal.Scenarios.SwitchParagraphTest do
  use ClusterCase, async: true

  setup do
    # Pieces
    #   AffordanceLand can inform downstream of cursor moves into new paragraph
    #   Control.NewParagraph
    #   Affordance can request paragraph text as affordance
    #   EdgeDetector (a Summarizer)
    #   BigEdit? A Gate
    #   BigEditChange?  A repetition remover
    #   BigEditSetter
    #   Accept "make affordance border-shows-edit"
  end

  @tag :skip
  test "simple run-through" do
    
  end
end
