alias AppAnimal.Neural

defmodule Neural.PerceptionEdge do
  use AppAnimal
  
  defstruct [:name,
             type: :perception_edge,
             downstream: [],
             send_pulse_downstream: :installed_by_switchboard
  ]
end

defimpl Neural.Clusterish, for: Neural.PerceptionEdge do
  def install_pulse_sender(cluster, {switchboard_pid, _affordances_pid}),
      do: Neural.Cluster.send_via_pid(cluster, switchboard_pid)

  def ensure_ready(_cluster, started_processes_by_name),
      do: started_processes_by_name
end 
