alias AppAnimal.Cluster

defmodule Cluster.Circular do
  @moduledoc """

  Those parts of a `Cluster` that are relevant to the operation of this gensym. Here are
  the fields that are new:

  - throb          - Controls the aging of this cluster and its eventual exit.
                     Initialized from Shape.Circular.max_age.
  - previously     - The part of the state the `calc` function can channged.
                     Initialized from Shape.Circular.initial_value.
  """
  use AppAnimal
  @derive [AppAnimal.Clusterish]

  typedstruct enforce: true do
    plugin TypedStructLens

    field :name, atom  # This is useful for debugging
    field :id, Cluster.Identification.t, default: "default value is temporary"
    field :throb, Cluster.Throb.t
    field :calc, fun
    field :previously, any
    field :router, System.Router.t
  end

  def new(s_cluster) do
    %__MODULE__{name: s_cluster.name,
                calc: s_cluster.calc,
                throb: s_cluster.shape.throb,
                previously: s_cluster.shape.initial_value,
                router: s_cluster.router
  }
  end

  deflens current_age(), do: in_throb(:current_age)
  deflens max_age(), do: in_throb(:max_age)

  private do
    def in_throb(key), do: throb() |> Lens.key(key)
  end
end
