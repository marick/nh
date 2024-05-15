alias AppAnimal.Clusterish
alias AppAnimal.Moveable
alias Moveable.{Pulse, Action, Delay}


defprotocol Moveable do
  @spec cast(t, Clusterish.t) :: none
  @doc "Casts a moveable to an appropriate destination, determined by the moveable's type."
  def cast(moveable, cluster)
end

defmodule Moveable.Router do
  use AppAnimal

  typedstruct enforce: true do
    field :map, %{atom => pid}
  end

  def new(map), do: %__MODULE__{map: map}

  def pid_for(s_router, %_name{} = some_struct) do
    s_router.map[some_struct.__struct__]
  end
end

defmodule Moveable.MoveableAliases do
  defmacro __using__(_) do
    quote do
      alias AppAnimal.Moveable
      alias Moveable.{Pulse, Action, Affordance, Delay}
    end
  end
end
