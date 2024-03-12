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
