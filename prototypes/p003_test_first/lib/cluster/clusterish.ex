alias AppAnimal.Clusterish
alias AppAnimal.System.Router

defprotocol Clusterish do
  @spec name(t) :: atom
  def name(clusterish)

  @spec pid_for(t, System.Moveable.t) :: pid
  def pid_for(clusterish, moveable)
end


defimpl Clusterish, for: Any do
  def name(clusterish), do: clusterish.name
  def pid_for(clusterish, moveable), do: Router.pid_for(clusterish.router, moveable)
end


defmodule Clusterish.Minimal do
  @moduledoc "A clusterish for tests too lazy to construct a cluster"
  use AppAnimal
  @derive [Clusterish]
  typedstruct enforce: true do
    field :router, Router
    field :name, atom
  end

  def new(name, router), do: %__MODULE__{name: name, router: router}
end
