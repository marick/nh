defmodule AppAnimal.ParagraphFocus.Control.AttendToEditing do
  use AppAnimal.ParagraphFocus
  use Neural.Gate, switchboard: Switchboard
    import Control.Util, only: [text_count: 1]

  @impl true
  def activate_downstream?(edges) do
    text_count(edges) > 1
  end
  
  @impl true
  def description_of_check(upstream_data) do
    string = Perceptual.EdgeSummarizer.edge_string(upstream_data)
    "does #{string} indicate? editing?"
  end
end

