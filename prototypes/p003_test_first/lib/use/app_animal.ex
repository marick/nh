defmodule AppAnimal do
  defmacro __using__(_) do
    quote do
      require Logger
      use Private
      use TypedStruct
      import Lens.Macros
      import AppAnimal.Extras.{TupleX,KernelX,Nesting}

      alias AppAnimal.{Pretty,Duration,Moveable}

      alias AppAnimal.Moveable.MoveableAliases
      alias AppAnimal.KeyConceptAliases

      alias AppAnimal.Extras
      alias Extras.{LensX,Opts}
      alias Extras.DepthAgnostic, as: A
    end
  end
end
