defmodule AppAnimal.ParagraphFocus.Control.AttendToEditing do
  alias AppAnimal.ParagraphFocus.{Perceptual, Control}
  import Perceptual.EdgeDetection, only: [edge_string: 1]
  import Control.Util
  require Logger

  def activate(earlier_results) do
    Logger.info("*not yet* looking to see if #{edge_string earlier_results} indicates editing")
  end
                
  def editing?(edges) do
    text_count(edges) > 1
  end
  
end
