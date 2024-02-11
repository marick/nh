defmodule AppAnimal.ParagraphFocus.Switchboard do
  require Logger
  alias AppAnimal.ParagraphFocus.{Control, Motor}
  alias AppAnimal.Neural.WithoutReply

  def activate_downstream(Control.AttendToEditing) do
    WithoutReply.activate(Motor.MarkBigEdit)
  end


end
