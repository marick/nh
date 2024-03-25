alias AppAnimal.Cluster.ThrobLogic

defmodule ThrobLogic do
  use TypedStruct
  
  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :current_strength, integer
    field :starting_strength, integer
  end

  def new(start_at), do: %__MODULE__{current_strength: start_at, starting_strength: start_at}
end
