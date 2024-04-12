alias AppAnimal.System
alias System.Network

defmodule Network.Throb do
  @moduledoc """
  Handle network-wide throbbing.

  All activated clusters throb. This module sends out that signal and handles
  process cleanup when the process "ages out".

  Although the "start throbbing" is sent to all active clusters "at the same time",
  there's no sort of synchronization of the clusters.
  """
  
  use AppAnimal

  # Getters  

  def throbbing_names(network), do: Map.keys(network.throbbers_by_name)
  def throbbing_pids(network), do: Map.values(network.throbbers_by_name)

  def throbbing_clusters(network) do
    throbbing_names(network)
    |> Enum.map(& network.clusters_by_name[&1])
  end

  # Working with clusters
  @doc "Cause all active clusters to throb."
  def start_throbbing(network, names) do
    to_start = needs_to_be_started(network, names)
     
    now_started =
      for cluster <- to_start, into: %{} do
        Cluster.start_throbbing(cluster)
      end
    deeply_map(network, :l_throbbers_by_name, & Map.merge(&1, now_started))
  end

  def pid_has_aged_out(network, pid) do
    throbbers = network.throbbers_by_name
    
    [{name, _pid}] = 
      throbbers
      |> Enum.filter(fn {_name, value} -> value == pid end)

    %{network | throbbers_by_name: Map.drop(throbbers, [name])}
  end
  
  def time_to_throb(network) do
    for {_name, pid} <- network.throbbers_by_name do
      GenServer.cast(pid, [throb: 1])
    end
    :no_return_value
  end

  private do 
    def needs_to_be_started(network, names) do
      nameset = MapSet.new(names)
      ignore_irrelevant = deeply_get_all(network, Network.l_irrelevant_names()) |> MapSet.new
      ignore_already = Map.keys(network.throbbers_by_name) |> MapSet.new
      
      nameset
      |> MapSet.difference(ignore_irrelevant)
      |> MapSet.difference(ignore_already)
      |> Enum.map(& network.clusters_by_name[&1])
    end
  end
  
end
