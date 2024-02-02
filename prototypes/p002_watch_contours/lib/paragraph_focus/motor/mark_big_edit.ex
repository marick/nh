defmodule AppAnimal.ParagraphFocus.Motor.MarkBigEdit do
  alias AppAnimal.ParagraphFocus.{Environment, Control}
  alias AppAnimal.Neural.WithoutReply
  require Logger

  @summary %{mechanism: :mover,
             upstream: Control.AttendToEditing,
             downstream: Environment
   }

  def activate() do
    Logger.info("unimplemented")
    [@summary, WithoutReply] # go keep from warning about unused aliases.
  end
end
