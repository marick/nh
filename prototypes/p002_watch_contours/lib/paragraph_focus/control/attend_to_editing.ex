defmodule AppAnimal.ParagraphFocus.Control.AttendToEditing do
  use AppAnimal.ParagraphFocus
  use AppAnimal.Neural.LinearCluster, switchboard: Switchboard
  import Control.Util
  
  def activate(upstream_results) do
    if editing?(upstream_results) do
      activate_downstream()
    else
      Logger.info("nope")
    end
    string = Perceptual.EdgeDetection.edge_string(upstream_results)
    Logger.info("looking to see if #{string} indicates editing")
  end
                
  def editing?(edges) do
    text_count(edges) > 1
  end
  
end
