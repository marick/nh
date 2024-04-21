defmodule AppAnimal.Extras.DepthAgnostic do
  use Private
  import AppAnimal.Extras.DefDeeply

  @doc """
  In addition to reordering the arguments to follow the usual structure-first convention,
  It creates a function that takes a symbol naming a function in the struct argument's
  module. That is, given:

     struct = %MyStruct{...}
     alias Extras.DepthAgnostic, as: A

  ... `A.put(struct, :lens, value)` is the same as:

     Lens.put(struct, MyStruct.lens(), value)
  """

  defdeeply put(s_struct, lens, value),
            do: Lens.put(lens, s_struct, value)

  defdeeply get_only(s_struct, lens),
            do: Lens.one!(lens, s_struct)

  defdeeply get_all(s_struct, lens),
            do: Lens.to_list(lens, s_struct)

  defdeeply map(s_struct, lens, f),
            do: Lens.map(lens, s_struct, f)

  defdeeply each(s_struct, lens, f),
            do: Lens.each(lens, s_struct, f)
end
