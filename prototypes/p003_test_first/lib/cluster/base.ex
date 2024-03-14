alias AppAnimal.Cluster


defmodule Cluster.Base do
  use TypedStruct

  typedstruct do
    plugin TypedStructLens

    # Set first thing
    field :label, atom    # only for human readability
    field :name, atom
    
    # The main axes of variation
    field :shape, Cluster.Shape.t
    field :calc, fun
    field :pulse_logic, atom | Cluster.PulseLogic.t, default: :installed_later

    # Set when compiled into a network
    field :downstream, [atom], default: []

    ### These are to be gotten rid of
    field :handlers, %{atom => fun}
    field :send_pulse_downstream, atom | fun, default: :installed_by_switchboard
  end
end

