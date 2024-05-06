alias AppAnimal.Extras


defmodule Extras.Nesting do

  defmacro section(_comment, do: block) do
    quote do
      unquote(block)
    end
  end
end
