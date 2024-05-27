defmodule AppAnimal.Extras.DepthAgnostic do
  @moduledoc """
  Lens getter/setter/etc functions that:
  1. Take the structure to work on first, rather than second. This fits better
     with pipelining:

         ... |> A.put(MyStruct.lens(...), 5)

  2. Allows the second argument to be a plain atom. When the first argument is a structure,
     it itself is used to look up the module and the lens function. That allows for
     calls that look a lot like typical `Map` functions that actually use lenses to
     dig deep into a structure.

         struct = %MyStruct{...}
         alias Extras.DepthAgnostic, as: A

         A.put(struct, :lens, value)

         # Same as:

         A.put(struct, MyStruct.lens(), value)

     You have to use the other form when the lens function takes arguments.
  """
  import AppAnimal.Extras.DefDeeply

  defdeeply put(s_struct, lens, value),
            do: Lens.put(lens, s_struct, value)

  defdeeply one!(s_struct, lens),
            do: Lens.one!(lens, s_struct)

  defdeeply to_list(s_struct, lens),
            do: Lens.to_list(lens, s_struct)

  defdeeply map(s_struct, lens, f),
            do: Lens.map(lens, s_struct, f)

  defdeeply each(s_struct, lens, f),
            do: Lens.each(lens, s_struct, f)
end
