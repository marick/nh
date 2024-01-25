defmodule AppAnimal.ParagraphFocus.Motor.MarkAsEditing do
  alias AppAnimal.ParagraphFocus.{Environment, Control}
  alias AppAnimal.WithoutReply
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
