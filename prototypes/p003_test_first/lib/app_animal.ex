defmodule AppAnimal do
  defmacro __using__(_) do
    quote do
      require Logger
      use Private
      alias AppAnimal.Map2
      import AppAnimal.Extras.Tuples
    end
  end
end
