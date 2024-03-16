defmodule AppAnimal.Extras.Kernel do
  use Private
  
  def constantly(value), do: fn _ -> value end
  
  def pi([{tag, value}]), do: IO.puts "#{tag}: #{inspect value}"


  def deeply_put(struct, lens_name, value) when is_atom(lens_name),
      do: deeply_put(struct, lookup_lens(struct, lens_name), value)
  def deeply_put(struct, lens, value),
      do: Lens.put(lens, struct, value)

  def deeply_get_only(struct, lens_name) when is_atom(lens_name),
      do: deeply_get_only(struct, lookup_lens(struct, lens_name))
  def deeply_get_only(struct, lens),
      do: Lens.one!(lens, struct)

  def deeply_get_all(struct, lens_name) when is_atom(lens_name),
      do: deeply_get_all(struct, lookup_lens(struct, lens_name))
  def deeply_get_all(struct, lens),
      do: Lens.to_list(lens, struct)

  def deeply_map(struct, lens_name, f) when is_atom(lens_name),
      do: deeply_map(struct, lookup_lens(struct, lens_name), f)
  def deeply_map(struct, lens, f),
      do: Lens.map(lens, struct, f)

  private do
    def lookup_lens(struct, lens_name), do: apply(struct.__struct__, lens_name, [])
  end
end
