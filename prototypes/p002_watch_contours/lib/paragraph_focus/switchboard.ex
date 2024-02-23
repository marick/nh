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
      |> cluster(Perceptual.SummarizeEdges,
                 downstream: [Control.AttendToEditing, Control.AttendToFragments])
      
      |> cluster(Motor.MoveFragment, downstream: [Environment])
      |> cluster(Motor.MakeEditTypeExplicit, downstream: [Environment])
      
    {:ok, {network, %{}}}
  end

  def handle_cast([transmit: small_data, to_downstream_of: module], {network, live_clusters}) do
    reducer = fn receiver, live_clusters ->
      small_data
      |> receiver.start_appropriately
      |> possibly_monitor(live_clusters, receiver)
    end
    
    new_live_clusters = Enum.reduce(network[module].downstream, live_clusters, reducer)
    {:noreply, {network, new_live_clusters}}
  end

  def possibly_monitor([monitor: pid], live_clusters, receiver) do
    Process.monitor(pid)
    Map.put(live_clusters, receiver, pid)
  end

  def possibly_monitor(_, live_clusters, _receiver), do: live_clusters


  def handle_info({:DOWN, _, :process, pid, _reason}, {network, live_clusters}) do
    # IO.inspect "noticed #{inspect pid} is down for #{inspect reason}"
    newlive_clusters = Map.reject(live_clusters, fn {_key, value} ->
      value == pid
    end)
    {:noreply, {network, newlive_clusters}}
  end
end
