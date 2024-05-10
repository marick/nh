defmodule AppAnimal.Extras.Lens do
  @moduledoc "Additional functions to make lenses, particularly for nested structs or maps."

  use AppAnimal
  import Lens.Macros

  @doc """
  Produces a lens that allows you to do what's effectively `put_new`.

      lens = Lens.keys([:a, :b, :c]) |> LensE.missing

      %{a: 1}
      |> A.put(lens, 5)
      |> assert_equals(%{a: 1, b: 5, c: 5})
  """
  deflens missing(), do: Lens.filter(& &1 == nil)

  @doc """
  Easy construction of multiple "foci" for a nested map or struct.

  Starting at the root of the structure,
  * lists (like `[:a, :b, :c]`) add a `Lens.keys!` to a chain of lens-makers.
  * atoms add a `Lens.key!`

  Thus this:

      cluster_names = [:a, :b, :c]
      nested_map_leaves([cluster_names, :calc])

  ... is the same as:

      Lens.keys!(cluster_names) |> Lens.key!(:calc)

  Note that there may be no missing keys. See `ensure_nested_map_leaves/1`.
  """
  deflens nested_map_leaves(route) do
    reducer = fn
      keys, building_lens when is_list(keys) ->
        Lens.seq(building_lens, Lens.keys!(keys))
      key, building_lens ->
        Lens.seq(building_lens, Lens.key!(key))
    end
    Enum.reduce(route, Lens.root, reducer)
  end

  @doc """
  Ensure there are no missing branches or leaves in a map/struct tree.

  Consider a three-level map. The first level has all the letters from `:a` to `:z`.
  The second level has keys `[:top, :bottom, :charm]`. You want to increment the
  `:top` and `:bottom` values of `[:a, :b, :c]`

  What if `:b` doesn't exist? Or what if `map[:a][:top]` doesn't exist? The solution is:

      twisty_little_paths = [[:a, :b, :c], [:top, :bottom]

      maps
      |> ensure_nested_map_leaves(twisty_little_paths, 0)
      |> A.map(nested_map_leaves(twisty_little_paths), & &1+1)

  Note that the `route` argument is not a lens.
  """
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
