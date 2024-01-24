defmodule AppAnimal.ParagraphFocus.Control.AttendToEditing do
  alias AppAnimal.ParagraphFocus.{Perceptual, Control}
  alias Perceptual.EdgeDetection
  import Control.Util
  require Logger

  # @summary %{mechanism: :gate,
  #            upstream: EdgeDetection,
  #            downstream: []
  #  }


  def activate(earlier_results) do
    string = EdgeDetection.edge_string(earlier_results)
    Logger.info("*not yet* looking to see if #{string} indicates editing")
  end
                
  def editing?(edges) do
    text_count(edges) > 1
  end
  
end
