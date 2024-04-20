alias AppAnimal.{Cluster,System}

defmodule Cluster.Linear do
  use AppAnimal
  use TypedStruct

  typedstruct enforce: true do
    plugin TypedStructLens

    field :name, atom  # This is useful for debugging
    field :id, Cluster.Identification.t, default: "default value is temporary"
    field :calc, fun
    field :router, System.Router.t
  end

  def new(struct) when is_struct(struct), do: new(Map.from_struct(struct))
  def new(%{} = pairs), do: struct(__MODULE__, pairs)
end

