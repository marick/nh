defmodule AppAnimal.Cluster.Base do

  defstruct [:name,
             :handlers,
             :receives_how,
             :type,
             downstream: [],
             starting_pulses: 20,
             send_pulse_downstream: :installed_by_switchboard]
end

