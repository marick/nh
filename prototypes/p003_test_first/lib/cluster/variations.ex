alias AppAnimal.Cluster


defmodule Cluster.Variations do
  use AppAnimal


  # ===


  ##

  def send_to_affordances_pid(cluster, affordances_pid) do 
    cluster
    |> Map.update!(:pulse_logic, & Cluster.PulseLogic.put_pid(&1, {:foo, affordances_pid}))
  end

  def send_to_internal_pid(cluster, switchboard_pid) do
    sender = fn carrying: pulse_data ->
      payload = {:distribute_downstream, from: cluster.name, carrying: pulse_data}
      GenServer.cast(switchboard_pid, payload)
    end
    cluster
    |> Map.put(:send_pulse_downstream, sender)
    |> Map.update!(:pulse_logic, & Cluster.PulseLogic.put_pid(&1, {switchboard_pid, :foo}))
  end

  def install_pulse_sender(%{label: :action_edge} = cluster, {_switchboard_pid, affordances_pid}) do
    send_to_affordances_pid(cluster, affordances_pid)
  end

  def install_pulse_sender(cluster, {switchboard_pid, _affordances_pid}) do
    send_to_internal_pid(cluster, switchboard_pid)
  end
end
