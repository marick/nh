alias AppAnimal.Cluster


defmodule Cluster.Base do
  use TypedStruct

  typedstruct do
    plugin TypedStructLens

    # Set first thing
    field :label, atom    # only for human readability
    field :name, atom
    
    # The main axes of variation
    field :topology, Cluster.Variations.Topology.t
    field :calc, fun
    field :propagate, Cluster.Variations.Propagation.t

    # Set when compiled into a network
    field :downstream, [atom], default: []

    ### These are to be gotten rid of
    field :handlers, %{atom => fun}
    field :starting_pulses, integer, default: 20
    field :send_pulse_downstream, atom | fun, default: :installed_by_switchboard
  end
end

