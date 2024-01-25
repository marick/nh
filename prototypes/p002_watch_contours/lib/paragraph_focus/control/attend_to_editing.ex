defmodule AppAnimal.ParagraphFocus.Control.AttendToEditing do
  alias AppAnimal.ParagraphFocus.{Control, Perceptual, Motor}
  import Control.Util
  alias AppAnimal.WithoutReply
  require Logger

  @summary %{mechanism: :gate,
             upstream: Perceptual.EdgeDetection,
             downstream: [Motor.MarkAsEditing]
   }

  def activate(earlier_results) do
    if editing?(earlier_results) do
      WithoutReply.activate(@summary.downstream)
    else
      Logger.info("nope")
    end
    string = Perceptual.EdgeDetection.edge_string(earlier_results)
    Logger.info("looking to see if #{string} indicates editing")
  end
                
  def editing?(edges) do
    text_count(edges) > 1
  end
  
end
