defmodule AppAnimal.ParagraphFocus.Switchboard do
  require Logger
  alias AppAnimal.ParagraphFocus.{Control, Motor}
  alias AppAnimal.Neural.WithoutReply

  def activate_downstream(Control.AttendToEditing) do
    WithoutReply.activate(Motor.MarkBigEdit)
  end

  def activate_downstream(Control.AttendToFragments, transmitting: small_data) do
    WithoutReply.activate(Motor.MoveFragment, transmitting: small_data)
  end
end
