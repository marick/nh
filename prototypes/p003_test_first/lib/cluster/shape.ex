alias AppAnimal.Cluster
alias Cluster.Shape

# These are a bit funky as they both hold data particular to one of the two
# cluster shapes and also serve to identify which type of cluster the cluster is.

defmodule Shape.Circular do
  use TypedStruct

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :starting_pulses, integer, default: 20
    field :initial_value, any, default: %{}
  end
  
  def new(opts \\ []), do: struct(__MODULE__, opts)
end

defmodule Shape.Linear do
  defstruct [] # This is just to create the type. 
  
  def new(opts \\ []), do: struct(__MODULE__, opts)
end
