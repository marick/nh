defmodule AppAnimal.ParagraphFocus.Motor.MarkBigEdit do
  alias AppAnimal.ParagraphFocus.{Environment, Control}
  alias AppAnimal.Neural.WithoutReply
  require Logger

  @summary %{mechanism: :mover,
             upstream: Control.AttendToEditing,
             downstream: Environment
   }

  def do_the_start_thing(_small_data), do: activate(:ok)

  def activate(:ok) do
    Logger.info("unimplemented")
    [@summary, WithoutReply] # go keep from warning about unused aliases.
  end
end
