defmodule AppAnimal.Neural.PerceptionEdge do
  use AppAnimal

  defstruct [:name,
             type: :perception_edge,
             downstream: [],
             send_pulse_downstream: :installed_by_switchboard
  ]
end
