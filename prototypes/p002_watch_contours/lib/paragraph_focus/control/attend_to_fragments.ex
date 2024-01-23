defmodule AppAnimal.ParagraphFocus.Control.AttendToFragments do
  alias AppAnimal.ParagraphFocus.{Control, Perceptual, Motor}
  import Control.Util
  require Logger
  alias AppAnimal.WithoutReply

  @mechanism :gate
  @upstream  Perceptual.EdgeDetection
  @downstream Motor.MoveFragment

  def describe() do
    "#{inspect @mechanism} #{__MODULE__} decides on #{inspect @upstream} results, " <>
      "may send to #{inspect @downstream}"
  end

  def activate(earlier_results) do
    Logger.info("looking for fragments in #{inspect earlier_results}")
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
