defmodule AppAnimal.Neural.PerceptionEdge do
  use AppAnimal

  defstruct [:name,
             type: __MODULE__,
             downstream: [],
             send_pulse_downstream: :installed_by_switchboard
  ]
end
