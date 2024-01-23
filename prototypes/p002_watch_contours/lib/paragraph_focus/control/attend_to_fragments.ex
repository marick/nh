defmodule AppAnimal.ParagraphFocus.Control.AttendToFragments do
  alias AppAnimal.ParagraphFocus.Control
  import Control.Util
  require Logger

  def activate(earlier_results) do
    Logger.info("looking for fragments in #{inspect earlier_results}")
  end
                
  def has_fragments?(edges) do
    text_count(edges) > 2
  end
  
end
