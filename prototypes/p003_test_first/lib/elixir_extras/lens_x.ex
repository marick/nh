defmodule AppAnimal.Extras.LensX do
  @moduledoc "Additional functions to make lenses, particularly for nested structs or maps."

  use AppAnimal
  import Lens.Macros

  @doc """
  Produces a lens that allows you to do what's effectively `put_new`.

      lens = Lens.keys([:a, :b, :c]) |> LensX.missing

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
         LensX.mapset_values |> Lens.key?(:a)
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

  @doc """
  Since mapsets don't have keys, there needs to be a way of identifying focus elements.

  This function has two ways of identifying MapSet entries: by the entries' key/value pairs,
  and by a filter function. The first way is more common.

  Suppose you have a a MapSet of points:

      input =
        # A struct with `:x` and `:y` fields
        [Point.new(0, 0), Point.new(0, 1), Point.new(1, 10)]
        |> MapSet.new

  You can now update all the *y* values for points on the origin like this:

       lens = LensX.mapset_value_identified_by(x: 0) |> Lens.key(:y)
       A.map(input, lens, & &1 + 1000)
       # [Point.new(0, 1000), Point.new(0, 1001), Point.new(1, 0)] |> MapSet.new

  You could do the same thing with an actual function:

       predicate = fn data ->
         Map.has_key?(data, key) && Map.get(data, key) == value
       end
       lens =
         LensX.mapset_value_identified_by(predicate) |> Lens.key(:y)

  That is, in fact, how the shorthand version is implemented.

  Note that there is a distinction between a *missing* key and a key
  that's *present* with the value `nil`. Only the latter will match
  `mapset_value_identified_by(a: nil).

  """

  deflens mapset_value_identified_by([{key, value}]) do
    predicate = fn data ->
      Map.has_key?(data, key) && Map.get(data, key) == value
    end
    mapset_value_identified_by(predicate)
  end

  deflens mapset_value_identified_by(f) do
    Lens.into(mapset_values() |> Lens.filter(f), MapSet.new)
  end

  ### For reference, here's how you do it in one fell swoop, without composing lenses.
  # deflens_raw mapset_value_identified_by([{key, value}]),
  #             do: common__mapset_value_identified_by(& Map.get(&1, key) == value)
  # deflens_raw mapset_value_identified_by(f),
  #             do: common__mapset_value_identified_by(f)

  # defp common__mapset_value_identified_by(f) do
  #   fn data, fun ->
  #     {res, changed} =
  #       Enum.reduce(data, {[], []}, fn item, {res, updated} ->
  #         if f.(item) do
  #           {res_item, updated_item} = fun.(item)
  #           {[res_item | res], [updated_item | updated]}
  #         else
  #           {res, [item | updated]}
  #         end
  #       end)

  #     {res, MapSet.new(changed)}
  #   end
  # end

  @doc """
  Easy construction of a lens to multiple locations deep within a tree of map/structs.

  A *multipath* is a list, each of which elements produces a lens.

  * non-lists (typically atoms) create a component with `Lens.key!`.
  * lists use `Lens.keys!`.

  Thus this:

      cluster_names = [:a, :b, :c]
      multipath = [cluster_names, :calc]
      map_multipath(multipath)

  ... is the same as:

      Lens.keys!(cluster_names) |> Lens.key!(:calc)

  Note that there may be no missing keys. See `ensure_map_multipath/1`.
  """
  deflens map_multipath(route) do
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
      |> ensure_map_multipath(twisty_little_paths, 0)
      |> A.map(map_multipath(twisty_little_paths), & &1+1)

  Note that the `route` argument is not a lens.
  """
  def ensure_map_multipath(map, route, leaf_value) do
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
