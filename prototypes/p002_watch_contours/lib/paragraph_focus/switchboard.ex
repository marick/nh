defmodule AppAnimal.Neural.NetworkBuilder do
  def cluster(so_far, module, downstream: atom) when is_atom(atom) do
    cluster(so_far, module, downstream: [atom])
  end

  def cluster(so_far, module, downstream: list) do
    so_far
    |> Map.put(module, %{})
    |> put_in([module, :downstream], list)
  end
end

defmodule AppAnimal.ParagraphFocus.Switchboard do
  use AppAnimal.ParagraphFocus
  import AppAnimal.Neural.NetworkBuilder
  
  def start_link(:ok) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    network = 
      %{}
      |> cluster(Control.AttendToEditing, downstream: Control.RejectSameness)
      |> cluster(Control.RejectSameness, downstream: Motor.MakeEditTypeExplicit)
      |> cluster(Control.AttendToFragments, downstream: Motor.MoveFragment)
      |> cluster(Perceptual.EdgeSummarizer,
                 downstream: [Control.AttendToEditing, Control.AttendToFragments])
      
      |> cluster(Motor.MoveFragment, downstream: [Environment])
      |> cluster(Motor.MakeEditTypeExplicit, downstream: [Environment])
      
    {:ok, {network, MapSet.new}}
  end

  def handle_cast([transmit: small_data, to_downstream_of: module], {network, pids}) do
    reducer = fn receiver, pids ->
      small_data
      |> receiver.start_appropriately
      |> possibly_monitor(pids)
    end
    
    new_pids = Enum.reduce(network[module].downstream, pids, reducer)
    {:noreply, {network, new_pids}}
  end

  def possibly_monitor([monitor: pid], pids) do
    Process.monitor(pid)
    MapSet.put(pids, pid)
  end

  def possibly_monitor(_, pids), do: pids


  def handle_info({:DOWN, _, :process, pid, _reason}, {network, pids}) do
    # IO.inspect "noticed #{inspect pid} is down for #{inspect reason}"
    newpids = MapSet.delete(pids, pid)
    # IO.inspect newpids
    {:noreply, {network, newpids}}
  end
  
end
