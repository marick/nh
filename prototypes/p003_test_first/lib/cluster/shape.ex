alias AppAnimal.Cluster
alias Cluster.Shape

# These are a bit funky as they both hold data particular to one of the two
# cluster shapes and also serve to identify which type of cluster the cluster is.

defmodule Shape.Circular do
  use TypedStruct
  alias Cluster.Throb

  typedstruct enforce: true do
    plugin TypedStructLens, prefix: :l_

    field :throb,         Cluster.Throb.t, default: %Cluster.Throb{}
    field :initial_value, any,             default: %{}
  end
  
  def new(opts \\ []) do
    Keyword.pop(opts, :starting_lifespan)
    case Keyword.pop(opts, :starting_lifespan) do
      {nil, _} -> 
        struct(__MODULE__, opts)
      {lifespan, remainder} ->
        Keyword.put(remainder, :throb, Throb.starting(lifespan))
        struct(__MODULE__, Keyword.put(remainder, :throb, Throb.starting(lifespan)))
    end
  end
end

defmodule Shape.Linear do
  defstruct [] # This is just to create the type. 
  
  def new(opts \\ []), do: struct(__MODULE__, opts)
end
