defmodule AppAnimal.ParagraphFocus.Control.AttendToEditing do
  use AppAnimal.ParagraphFocus
  use Neural.Gate, switchboard: Switchboard
  import Control.Util
  
  @impl true
  def description_of_check(upstream_data) do
    string = Perceptual.EdgeDetection.edge_string(upstream_data)
    "does #{string} indicate? editing?"
  end
  
  @impl true
  def activate_downstream?(edges) do
    text_count(edges) > 1
  end
  
end

