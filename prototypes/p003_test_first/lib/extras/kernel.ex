defmodule AppAnimal.Extras.Kernel do
  use Private
  import AppAnimal.Extras.DefDeeply
  
  def constantly(value), do: fn _ -> value end
  
  def pi([{tag, value}]), do: IO.puts "#{tag}: #{inspect value}"

  @doc """
  In addition to reordering the arguments to follow the usual structure-first convention,
  It creates a function that takes a symbol naming a function in the struct argument's
  module. That is, given:

     struct = %MyStruct{...}

  ... `deeply_put(struct, :lens, value)` is the same as:

     deeply_put(struct, MyStruct.lens(), value)
  """
  
  defdeeply deeply_put(s_struct, lens, value),
            do: Lens.put(lens, s_struct, value)
  
  defdeeply deeply_get_only(s_struct, lens),
            do: Lens.one!(lens, s_struct)

  defdeeply deeply_get_all(s_struct, lens),
            do: Lens.to_list(lens, s_struct)
  
  defdeeply deeply_map(s_struct, lens, f),
            do: Lens.map(lens, s_struct, f)

  defdeeply deeply_side_effect(s_struct, lens, f),
            do: Lens.each(lens, s_struct, f)
end
