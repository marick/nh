defmodule AppAnimal.ParagraphFocus.Motor.MoveFragment do
  alias AppAnimal.ParagraphFocus.{Control, Environment}
  # import Control.Util
  require Logger
  # alias AppAnimal.WithoutReply

  @mechanism :environment_changer
  @upstream Control.AttendToFragments
  @downstream Environment

  def describe() do
    "#{inspect @mechanism} #{__MODULE__} decides on #{inspect @upstream} results, " <>
      "may send to #{inspect @downstream}"
  end

  def activate(_expectation) do
    Logger.info("will move the fragment")
  end
end
