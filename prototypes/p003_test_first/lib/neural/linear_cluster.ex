defmodule AppAnimal.Neural.LinearCluster do
  use AppAnimal

  defstruct [:name,
             :handlers,
             type: __MODULE__,
             downstream: [],
             send_pulse_downstream: :installed_by_switchboard]   
end
