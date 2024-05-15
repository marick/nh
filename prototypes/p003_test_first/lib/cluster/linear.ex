alias AppAnimal.Cluster

defmodule Cluster.Linear do
  @moduledoc """
  A type of cluster whose `calc` function is run inside a `Task`.
  """
  use AppAnimal
  use MoveableAliases
  @derive [AppAnimal.Clusterish]

  typedstruct enforce: true do
    plugin TypedStructLens

    # Common among "Clusterish" structs (but I don't know a good way to enforce it.)
    field :name, atom  # This is more convenient than :id.
    field :id, Cluster.Identification.t
    field :calc, fun
    field :router, Moveable.Router.t
  end
end
