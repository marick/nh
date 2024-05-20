alias AppAnimal.Moveable

defmodule Moveable.Collection do
  @moduledoc "Collect Moveables together."
  use TypedStruct

  typedstruct enforce: true do
    field :members, MapSet.t(Moveable.t)
  end

  def new(collection), do: %__MODULE__{members: collection}
end

defimpl Moveable, for: Moveable.Collection do
  def cast(collection, cluster) do
    for moveable <- collection.members, do: Moveable.cast(moveable, cluster)
  end
end
