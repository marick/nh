defmodule AppAnimal.Extras.Lens do
  use AppAnimal
  import Lens.Macros

  deflens missing(), do: Lens.filter(& &1 == nil)

  deflens nested_map_leaves(route) do
    reducer = fn
      keys, building_lens when is_list(keys) ->
        Lens.seq(building_lens, Lens.keys!(keys))
      key, building_lens ->
        Lens.seq(building_lens, Lens.key!(key))
    end

    Enum.reduce(route, Lens.root, reducer)
  end

  def ensure_nested_map_leaves(map, route, leaf_value) do
    scanner = fn
      keys, building_lens when is_list(keys) ->
        Lens.seq(building_lens, Lens.keys(keys))
      key, building_lens ->
        Lens.seq(building_lens, Lens.key(key))
    end

    lenses =
      route
      |> Enum.scan(Lens.root, scanner)
      |> Enum.map(& Lens.seq(&1, missing()))

    {intermediate_levels, [leaf]} = Enum.split(lenses, -1)

    Enum.reduce(intermediate_levels, map, fn
      lens, building_map ->
        A.put(building_map, lens, %{})
    end)
    |> A.put(leaf, leaf_value)
  end
end
