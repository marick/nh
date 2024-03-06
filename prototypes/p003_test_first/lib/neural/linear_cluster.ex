alias AppAnimal.Neural
alias AppAnimal.Neural.LinearCluster

defmodule LinearCluster do
  use AppAnimal

  defstruct [:name,
             :handlers,
             type: :linear_cluster,
             downstream: [],
             send_pulse_downstream: :installed_by_switchboard]

end

defimpl Neural.Clusterish, for: LinearCluster  do
  def install_pulse_sender(cluster, {switchboard_pid, _affordances_pid}),
      do: Neural.Cluster.send_via_pid(cluster, switchboard_pid)

  def ensure_ready(_cluster, started_processes_by_name),
      do: started_processes_by_name
end 

