alias AppAnimal.Neural
alias Neural.ActionEdge

defmodule ActionEdge do
  use AppAnimal
  
  defstruct [:name,
             :handlers,
             type: :action_edge,
             downstream: [],
             send_pulse_downstream: :installed_by_switchboard]
end

defimpl Neural.Clusterish, for: ActionEdge do
  def install_pulse_sender(cluster, {_switchboard_pid, affordances_pid}) do
    sender = fn carrying: {action_name, _action_data} ->
      Neural.Affordances.note_action(affordances_pid, action_name)
    end
    %{cluster | send_pulse_downstream: sender}
  end

  def ensure_ready(_cluster, started_processes_by_name),
      do: started_processes_by_name
end 
