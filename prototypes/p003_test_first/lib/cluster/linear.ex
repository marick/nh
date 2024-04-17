alias AppAnimal.{Cluster,System}

defmodule Cluster.Linear do
  use AppAnimal
  use TypedStruct

  typedstruct enforce: true do
    plugin TypedStructLens

    field :name, atom  # This is useful for debugging
    field :calc, fun
    field :router, System.Router.t
  end

  def new(s_struct), do: struct(__MODULE__, Map.from_struct(s_struct))
end

