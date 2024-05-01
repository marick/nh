alias AppAnimal.{Cluster,System}

defmodule Cluster.Linear do
  use AppAnimal
  use TypedStruct
  @derive [AppAnimal.Clusterish]

  typedstruct enforce: true do
    plugin TypedStructLens

    field :name, atom  # This is useful for debugging
    field :id, Cluster.Identification.t, default: "default value is temporary"
    field :calc, fun
    field :router, System.Router.t, default: :installed_later
  end

  def new(struct) when is_struct(struct), do: new(Map.from_struct(struct))
  def new(opts), do: struct(__MODULE__, opts)
end
