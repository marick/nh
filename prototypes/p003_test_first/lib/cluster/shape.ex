alias AppAnimal.Cluster
alias Cluster.Shape

defprotocol Shape do
  @spec can_throb?(Shape.t) :: boolean
  def can_throb?(shape)
end

##

defmodule Shape.Circular do
  use TypedStruct

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :starting_pulses, integer, default: 20
    field :initial_value, any, default: %{}
  end
  
  def new(opts \\ []), do: struct(__MODULE__, opts)
end

defimpl Shape, for: Shape.Circular do
  def can_throb?(_s_shape), do: true
end

## 

defmodule Shape.Linear do
  defstruct [] # This is just to create the type. 
  
  def new(opts \\ []), do: struct(__MODULE__, opts)
end

defimpl Shape, for: Shape.Linear do
  
  def can_throb?(_s_shape), do: false
end
