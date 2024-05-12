defmodule AppAnimal.Extras.LensE do
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
  Like `Lens.all/0`, but operations more often produces a MapSet.

  `mapset_values` is pointless without other lenses appended to look
  deeper into the nested structure.

  Consider this lens and this data:

       lens =
         LensE.mapset_values |> Lens.key?(:a)
       input =
         MapSet.new([%{a: 1}, %{a: 2}, %{a: 3}, %{vvvv: "unchanged"}])

  You can now increment the values of all the `:a` values like this:

       A.map(input, lens, & &1*100)
       > MapSet.new([%{a: 100}, %{a: 200}, %{a: 300}, %{vvvv: "unchanged"}])

  Note that the question mark in `Lens.key?` is required, else the
  multiplication function will be called on `nil`.

  `mapset_values` also works reasonably well with `put`. Given the above
  `input` mapset and `lens`,

       A.put(input, 3)

  ... will produce:

       MapSet.new([%{a: 3}, %{vvvv: "unchanged"}]

  Note that the multiple maps with now-identical `:a` values have
  been correctly collapsed into one.

  As is typical for `Lens`, `get` functions return lists rather than
  the base type:

       A.get_all(input, lens)
       > [1, 2, 3]    # MapSet.new([1, 2, 3]) would be better

  """


  deflens mapset_values(), do: Lens.into(Lens.all, MapSet.new)

  # deflens_raw mapset_values do
  #   fn
  #     data, fun ->
  #       dbg {data, fun}
  #       {data, data}
  #   end
  # end


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
