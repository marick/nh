defmodule AppAnimal.ParagraphFocus.Control.AttendToFragment do
  alias AppAnimal.ParagraphFocus.Control
  import Control.Util

  def editing?(edges) do
    text_count(edges) > 1
  end
  
end
