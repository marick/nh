defmodule AppAnimal.Cluster.Variants do
  use AppAnimal
  alias AppAnimal.Neural.{CircularCluster, Affordances}

  # defprotocol AppAnimal.Cluster.SendsWhere do
  # end

  # defprotocol AppAnimal.Cluster.ReceivesHow do
  # end
  
  
  
  def ensure_ready(%{type: :circular_cluster} = cluster, started_processes_by_name) do
    case Map.has_key?(started_processes_by_name, cluster.name) do
      true ->
        started_processes_by_name
      false ->
        {:ok, pid} = GenServer.start(CircularCluster, cluster)
        Process.monitor(pid)
        Map.put(started_processes_by_name, cluster.name, pid)
    end
  ;end

  def ensure_ready(_cluster, started_processes_by_name) do
    started_processes_by_name
  end

  ##

  def send_to_affordances_pid(cluster, affordances_pid) do 
    sender = fn carrying: {action_name, _action_data} ->
      Affordances.note_action(affordances_pid, action_name)
    end
    %{cluster | send_pulse_downstream: sender}
  end

  def send_to_internal_pid(cluster, switchboard_pid) do
    sender = fn carrying: pulse_data ->
      payload = {:distribute_downstream, from: cluster.name, carrying: pulse_data}
      GenServer.cast(switchboard_pid, payload)
    end
    %{cluster | send_pulse_downstream: sender}
  end

  def install_pulse_sender(%{type: :action_edge} = cluster, {_switchboard_pid, affordances_pid}) do
    send_to_affordances_pid(cluster, affordances_pid)
  end

  def install_pulse_sender(cluster, {switchboard_pid, _affordances_pid}) do
    send_to_internal_pid(cluster, switchboard_pid)
  end

  ####

  def generic_pulse(%{type: :circular_cluster}, destination_pid, pulse_data) do
    GenServer.cast(destination_pid, [handle_pulse: pulse_data])
  end

  def generic_pulse(cluster, _destination_pid, pulse_data) do
    Task.start(fn ->
      cluster.handlers.handle_pulse.(pulse_data, cluster)
    end)
  end    
end
