defmodule AppAnimal.Cluster.Base do
  use TypedStruct

  typedstruct do
    plugin TypedStructLens
    
    field :name, atom
    field :type, atom
    field :downstream, [atom], default: []
    
    field :handlers, %{atom => fun}
    field :starting_pulses, integer, default: 20
    field :send_pulse_downstream, atom | fun, default: :installed_by_switchboard
  end


  
  # defstruct [:name,
  #            :handlers,
  #            :receives_how,
  #            :type,
  #            downstream: [],
  #            starting_pulses: 20,
  #            send_pulse_downstream: :installed_by_switchboard]
end

