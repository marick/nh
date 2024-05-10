alias AppAnimal.Cluster

defmodule Cluster.Identification do
  @moduledoc """
  Currently, a name and a descriptive label suggesting cluster customizations or uses.
  """
  use TypedStruct

  typedstruct enforce: true do
    field :label, atom
    field :name,  atom
  end

  def new(struct) when is_struct(struct), do: new(Map.from_struct(struct))
  def new(pairs), do: struct(__MODULE__, pairs)
  def new(name, label), do: new(name: name, label: label)
end
