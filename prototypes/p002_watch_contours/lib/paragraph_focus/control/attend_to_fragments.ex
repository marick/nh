defmodule AppAnimal.ParagraphFocus.Control.AttendToFragments do
  use AppAnimal.ParagraphFocus
  import Perceptual.EdgeDetection, only: [edge_string: 1]
  import Control.Util
  alias AppAnimal.Neural.WithoutReply
  use Private
  
  @summary %{mechanism: :gate,
             upstream: Perceptual.EdgeDetection,
             downstream: [Motor.MoveFragment]
   }
  
  def activate(edges) do
    Logger.info("looking for fragments in #{edge_string edges}")
    if has_fragments?(edges) do
      WithoutReply.activate(@summary.downstream,
                            transmitting: first_fragment_range(edges))
    else
      Logger.info("nope")
    end
  end
                
  private do 
    def has_fragments?(edges) do
      text_count(edges) > 2
    end

    def first_fragment_range(edges) do
      edges
      |> Enum.filter(fn {key, _} -> key == :text end)
      |> Enum.at(1)
    end
  end
end
