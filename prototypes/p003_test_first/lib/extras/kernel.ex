defmodule AppAnimal.Extras.Kernel do
  use Private
  
  def constantly(value), do: fn _ -> value end
  
  def pi([{tag, value}]), do: IO.puts "#{tag}: #{inspect value}"

  def lens_update(struct, lens_name, f) do
    lens = lookup_lens(struct, lens_name)
    update_in(struct, [lens], f)
  end

  def lens_put(struct, lens_name, value) do
    lens = lookup_lens(struct, lens_name)
    put_in(struct, [lens], value)
  end

  def lens_one!(struct, lens_name) do
    lens = lookup_lens(struct, lens_name)
    Lens.one!(lens, struct)
  end

  private do
    def lookup_lens(struct, lens_name), do: apply(struct.__struct__, lens_name, [])
  end
end
