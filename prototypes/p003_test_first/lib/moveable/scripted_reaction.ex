alias AppAnimal.Moveable

defmodule Moveable.ScriptedReaction do
  @moduledoc """
  Describes how an action turns into a pulse sent to a PerceptionEdge.

  Used for scripting.

  Vaguely related to `Moveable` as it contains one.
  """
  use TypedStruct
  use AppAnimal
  use MoveableAliases

  typedstruct enforce: true do
    field :perception_edge, atom
    field :pulse, Pulse.t
  end

  def new(perception_edge, %Pulse{} = pulse),
      do: %__MODULE__{perception_edge: perception_edge, pulse: pulse}
  def new(perception_edge, data),
      do: new(perception_edge, Pulse.new(data))
end
