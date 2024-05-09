alias AppAnimal.{Cluster,System}

defmodule Cluster.Linear do
  use AppAnimal
  use TypedStruct
  @derive [AppAnimal.Clusterish]

  typedstruct enforce: true do
    plugin TypedStructLens

    # Common among "Clusterish" structs (but I don't know a good way to enforce it.)
    field :name, atom  # This is more convenient than :id.
    field :id, Cluster.Identification.t
    field :calc, fun
    field :router, System.Router.t
  end
end
