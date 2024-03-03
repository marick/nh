defmodule AppAnimal.Neural.PerceptionEdge do
  use AppAnimal

  defstruct [:name,
             downstream: [],
             send_pulse_downstream: :installed_by_switchboard
  ]
end
