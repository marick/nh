alias AppAnimal.Cluster

defmodule Cluster.Circular do
  @moduledoc """
  The structure that serves as state for a circular process.

  # The two fields different from a linear cluster are these:

  - throb          - Controls the aging of this cluster and its eventual exit.
  - previously     - The part of the state the `calc` function can channged.
  """
  use AppAnimal
  @derive [AppAnimal.Clusterish]

  typedstruct enforce: true do
    plugin TypedStructLens

    # You may note that `Linear` consists entirely of the following fields;
    # `Circular` is a superset. I can't think of a a solution that pleases me
    # and works with Elixir.

    field :name, atom  # This is more convenient than `id`
    field :id, Cluster.Identification.t
    field :calc, fun
    field :router, System.Router.t

    field :previously, any
    field :throb, Cluster.Throb.t
  end

  deflens current_age(), do: in_throb(:current_age)
  deflens max_age(), do: in_throb(:max_age)

  private do
    def in_throb(key), do: throb() |> Lens.key!(key)
  end
end
