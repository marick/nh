defmodule AppAnimal.ParagraphFocus.Switchboard do
  use AppAnimal.ParagraphFocus
  
  def start_link(:ok) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # gate(Control.AttendToEditing)
  # |> mover(Motor.MarkBigEdit)

  def init(:ok) do
    state = 
      %{}
      |> cluster(Environment, downstream: Perceptual.EdgeDetection)
      
      |> cluster(Control.AttendToEditing, downstream: Motor.MarkBigEdit)
      |> cluster(Control.AttendToFragments, downstream: Motor.MoveFragment)
      |> cluster(Perceptual.EdgeDetection,
                 downstream: [Control.AttendToEditing, Control.AttendToFragments])
      
    {:ok, state}
  end

  def cluster(so_far, module, downstream: atom) when is_atom(atom) do
    cluster(so_far, module, downstream: [atom])
  end

  def cluster(so_far, module, downstream: list) do
    so_far
    |> Map.put(module, %{})
    |> put_in([module, :downstream], list)
  end
  
  def handle_cast([transmit: small_data, to_downstream_of: module], state) do
    for receiver <- state[module].downstream do
      runner = fn -> apply(receiver, :activate, [small_data]) end
      Task.start(runner)
    end
    {:noreply, state}
  end
end
