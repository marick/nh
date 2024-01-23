defmodule AppAnimal.ParagraphFocus.Control.AttendToFragment do
  alias AppAnimal.ParagraphFocus.Control
  import Control.Util
  require Logger

  def activate_on(earlier_results) do
    Logger.info("#{__MODULE__} activated on #{inspect earlier_results}")
  end
                
  def editing?(edges) do
    text_count(edges) > 1
  end
  
end
