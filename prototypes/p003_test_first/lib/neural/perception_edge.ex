alias AppAnimal.Neural

defmodule Neural.PerceptionEdge do
  use AppAnimal
  
  defstruct [:name,
             :handlers,
             type: :perception_edge,
             downstream: [],
             send_pulse_downstream: :installed_by_switchboard
  ]
end

