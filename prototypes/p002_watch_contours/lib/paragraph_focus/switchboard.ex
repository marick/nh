defmodule AppAnimal.ParagraphFocus.Switchboard do
  require Logger
  alias AppAnimal.ParagraphFocus.{Control, Motor}
  

  def start_link(:ok) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # gate(Control.AttendToEditing)
  # |> mover(Motor.MarkBigEdit)

  def init(:ok) do
    state = 
      %{}
      |> Map.put(Control.AttendToEditing, %{})
      |> put_in([Control.AttendToEditing, :downstream], [Motor.MarkBigEdit])
      
      |> Map.put(Control.AttendToFragments, %{})
      |> put_in([Control.AttendToFragments, :downstream], [Motor.MoveFragment])
    {:ok, state}
  end

  def handle_cast([transmit: small_data, to_downstream_of: module], state) do
    for receiver <- state[module].downstream do
      runner = fn -> apply(receiver, :activate, [small_data]) end
      Task.start(runner)
    end
    {:noreply, state}
  end
end
