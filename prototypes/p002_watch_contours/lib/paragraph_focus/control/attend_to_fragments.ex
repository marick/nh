defmodule AppAnimal.ParagraphFocus.Control.AttendToFragments do
  alias AppAnimal.ParagraphFocus.{Control, Perceptual, Motor}
  import Perceptual.EdgeDetection, only: [edge_string: 1]
  import Control.Util
  require Logger

  @mechanism :gate
  @upstream  Perceptual.EdgeDetection
  @downstream Motor.MoveFragment
  use AppAnimal.NeuralCluster
  alias AppAnimal.WithoutReply


  def activate(earlier_results) do
    Logger.info("looking for fragments in #{edge_string earlier_results}")
    if has_fragments?(earlier_results) do
      WithoutReply.activate(@downstream, on_one: earlier_results)
    else
      Logger.info("nope")
    end
  end
                
  def has_fragments?(edges) do
    text_count(edges) > 2
  end
end
