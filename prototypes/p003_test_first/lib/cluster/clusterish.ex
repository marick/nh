alias AppAnimal.Clusterish
alias AppAnimal.System

defprotocol Clusterish do
  @moduledoc "Functions common to linear and circular clusters."
  @spec name(t) :: atom
  def name(clusterish)

  @spec pid_for(t, System.Moveable.t) :: pid
  def pid_for(clusterish, moveable)
end


defimpl Clusterish, for: Any do
  use AppAnimal

  def name(clusterish), do: clusterish.name
  def pid_for(clusterish, moveable) do
    clusterish
    |> A.get_only(:router)
    |> Moveable.Router.pid_for(moveable)
  end
end


defmodule Clusterish.Minimal do
  @moduledoc "A clusterish for tests too lazy to construct a cluster"
  use AppAnimal
  alias System.Moveable
  @derive [Clusterish]

  typedstruct enforce: true do
    plugin TypedStructLens

    field :router, Moveable.Router
    field :name, atom
  end

  def new(name, router), do: %__MODULE__{name: name, router: router}
end
