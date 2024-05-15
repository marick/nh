defmodule AppAnimal.Moveable.MoveableAliases do
  defmacro __using__(_) do
    quote do
      alias AppAnimal.Moveable
      alias Moveable.{Pulse, Action, Delay}
    end
  end

end
