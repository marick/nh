alias AppAnimal.Neural
alias Neural.LinearCluster

defmodule LinearCluster do
  use AppAnimal

  defstruct [:name,
             :handlers,
             type: :linear_cluster,
             downstream: [],
             send_pulse_downstream: :installed_by_switchboard]

end
