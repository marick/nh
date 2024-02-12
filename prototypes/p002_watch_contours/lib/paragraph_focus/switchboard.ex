defmodule AppAnimal.ParagraphFocus.Switchboard do
  require Logger
  alias AppAnimal.ParagraphFocus.{Control, Motor}
  alias AppAnimal.Neural.WithoutReply


  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end


  def init(:ok) do

  end

  

  def activate_downstream(Control.AttendToEditing, :ok) do
    WithoutReply.activate(Motor.MarkBigEdit, transmitting: :ok)
  end
  
  def activate_downstream(Control.AttendToFragments, small_data) do
    WithoutReply.activate(Motor.MoveFragment, transmitting: small_data)
  end
end
