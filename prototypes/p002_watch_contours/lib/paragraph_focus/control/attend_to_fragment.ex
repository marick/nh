defmodule AppAnimal.ParagraphFocus.Control.AttendToFragment do
  alias AppAnimal.ParagraphFocus.Control
  import Control.Util
  require Logger

  def activate(earlier_results) do
    Logger.info("looking for fragments in #{inspect earlier_results}")
  end
                
  def editing?(edges) do
    text_count(edges) > 1
  end
  
end
