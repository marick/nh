defmodule AppAnimal do
  defmacro __using__(_) do
    quote do
      require Logger
      use Private
      alias AppAnimal.Map2
      import AppAnimal.Extras.Tuples
      import AppAnimal.Extras.Kernel
    end
  end
end
