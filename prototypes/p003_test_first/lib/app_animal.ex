defmodule AppAnimal do

  defstruct [:network, :switchboard, :affordances]

  defmacro __using__(_) do
    quote do
      require Logger
      use Private
      alias AppAnimal.Map2
      alias AppAnimal.Pretty
      import AppAnimal.Extras.Tuples
      import AppAnimal.Extras.Kernel
    end
  end
end
