defmodule AppAnimal.ParagraphFocus.Motor.MoveFragment do
  alias AppAnimal.ParagraphFocus.{Environment, Control}
  alias AppAnimal.WithoutReply
  require Logger

  @summary %{mechanism: :mover,
             upstream: Control.AttendToFragments,
             downstream: Environment
   }

  def activate({:text, fragment_range}) do
    Logger.info("will remove fragment in range #{inspect fragment_range}")
    [@summary, WithoutReply] # go keep from warning about unused aliases.
  end
end
