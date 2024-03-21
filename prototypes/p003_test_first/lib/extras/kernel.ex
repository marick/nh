defmodule AppAnimal.Extras.Kernel do
  use Private
  
  def constantly(value), do: fn _ -> value end
  
  def pi([{tag, value}]), do: IO.puts "#{tag}: #{inspect value}"


  def deeply_put(s_struct, lens_name, value) when is_atom(lens_name),
      do: deeply_put(s_struct, lookup_lens(s_struct, lens_name), value)
  def deeply_put(s_struct, lens, value),
      do: Lens.put(lens, s_struct, value)

  def deeply_get_only(s_struct, lens_name) when is_atom(lens_name),
      do: deeply_get_only(s_struct, lookup_lens(s_struct, lens_name))
  def deeply_get_only(s_struct, lens),
      do: Lens.one!(lens, s_struct)

  def deeply_get_all(s_struct, lens_name) when is_atom(lens_name),
      do: deeply_get_all(s_struct, lookup_lens(s_struct, lens_name))
  def deeply_get_all(s_struct, lens),
      do: Lens.to_list(lens, s_struct)

  def deeply_map(s_struct, lens_name, f) when is_atom(lens_name),
      do: deeply_map(s_struct, lookup_lens(s_struct, lens_name), f)
  def deeply_map(s_struct, lens, f),
      do: Lens.map(lens, s_struct, f)

  def deeply_side_effect(s_struct, lens_name, f) when is_atom(lens_name),
      do: deeply_side_effect(s_struct, lookup_lens(s_struct, lens_name), f)
  def deeply_side_effect(s_struct, lens, f),
      do: Lens.each(lens, s_struct, f)

  private do
    def lookup_lens(s_struct, lens_name), do: apply(s_struct.__struct__, lens_name, [])
  end
end
