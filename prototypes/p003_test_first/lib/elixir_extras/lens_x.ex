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
  Like `Lens.all/0`, but intended for use with a MapSet.

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

       A.to_list(input, lens)
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
  Point at all values of a BiMap.

  Note that `put` is not useful in this case, as BiMaps require all values to be unique.
  If you do `A.put(data, lens, 1)`, all but one of the keys will disappear from the BiMap.
  """
  deflens bimap_all_values() do
    Lens.into(Lens.all |> Lens.at(1), BiMap.new)
  end

  @doc """
  Point at all keys of a BiMap.

  This is useful for descending into complex keys.
  """
  deflens bimap_all_keys() do
    Lens.into(Lens.all |> Lens.at(0), BiMap.new)
  end

  @doc """
  Point at the value of a single BiMap key.

  Missing keys produce nil.
  """
  deflens_raw bimap_key(key) do
    fn bimap, f_get_or_update ->
      bimap_key_guts(key, bimap, f_get_or_update)
    end
  end

  defp bimap_key_guts(key, bimap, f_get_or_update) do
    {gotten, updated} = f_get_or_update.(BiMap.get(bimap, key))
    {[gotten], BiMap.put(bimap, key, updated)}
  end

  @doc """
  Point at the value of a single BiMap key, ignoring missing keys.
  """
  deflens_raw bimap_key?(key) do
    fn bimap, f_get_or_update ->
      if BiMap.has_key?(bimap, key) do
        bimap_key_guts(key, bimap, f_get_or_update)
        {gotten, updated} = f_get_or_update.(BiMap.get(bimap, key))
        {[gotten], BiMap.put(bimap, key, updated)}
      else
        {[], bimap}
      end
    end
  end

  @doc """
  Point at the values of an `Enumeration` of BiMap keys.
  """
  deflens bimap_keys(keys) do
    keys |> Enum.map(&bimap_key/1) |> Lens.multiple
  end

  @doc """
  Point at the values of an `Enumeration` of BiMap keys, ignoring missing keys.
  """
  deflens bimap_keys?(keys) do
    keys |> Enum.map(&bimap_key?/1) |> Lens.multiple
  end

  @doc """
  Differs from `missing` in that the missing key is passed to a `map` function.

  This is useful when adding keys to a map, where the value somehow depends on the key.

     A.map(bimap, LensX.bimap_keys([:a, :b]), fn missing_key ->
       // create a process that remembers the `missing_key` and put it into the
       // BiMap under the `missing_ley`
     end

  """
  deflens_raw bimap_missing_keys(list) do
    fn bimap, f_get_or_update ->
      reducer =
        fn key, {gotten_so_far, updated_so_far} ->
          if BiMap.has_key?(bimap, key) do
            {gotten_so_far, updated_so_far}
          else
            {gotten, updated} = f_get_or_update.(key)
            {[gotten | gotten_so_far], BiMap.put(updated_so_far, key, updated)}
          end
        end

      {gotten_final, updated_final} = Enum.reduce(list, {[], bimap}, reducer)
      {gotten_final, updated_final}
    end
  end


  @doc """
  Easy construction of a lens to multiple locations deep within a tree of map/structs.

  A *multipath* is a list, each of which elements produces a lens.

  * non-lists (typically atoms) create a component with `Lens.key!`.
  * lists use `Lens.keys!`.

  The result is a lens that selects the leaves at the end of a
  branching path through a map structure.

  That is, this:

      cluster_names = [:a, :b, :c]
      multipath = [cluster_names, :calc]
      map_multipath(multipath)

  ... is the same as:

      Lens.keys!(cluster_names) |> Lens.key!(:calc)

  Note that there may be no missing keys. See `ensure_map_multipath/1`.

  If some of your keys are maps, put them inside a singleton map.
  """
  deflens map_multipath!(multipath) do
    reducer = fn
      keys, building_lens when is_list(keys) ->
        Lens.seq(building_lens, Lens.keys!(keys))
      key, building_lens ->
        Lens.seq(building_lens, Lens.key!(key))
    end
    Enum.reduce(multipath, Lens.root, reducer)
  end

  @doc """
  Like `map_multipath!/1`, except lists are not allowed in the path (no branching).

  This perhaps has some use as documentation of intent.
  """

  deflens map_path!(path) do
    precondition no_list_elements?(path)
    map_multipath!(path)
  end

  defp no_list_elements?(enum), do: !Enum.any?(enum, &is_list/1)

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

  Note that the `multipath` argument is not a lens.
  """
  def ensure_map_multipath(map, multipath, leaf_value) do
    scanner = fn
      keys, building_lens when is_list(keys) ->
        Lens.seq(building_lens, Lens.keys(keys))
      key, building_lens ->
        Lens.seq(building_lens, Lens.key(key))
    end

    lenses =
      multipath
      |> Enum.scan(Lens.root, scanner)
      |> Enum.map(& Lens.seq(&1, missing()))

    {intermediate_levels, [leaf]} = Enum.split(lenses, -1)

    Enum.reduce(intermediate_levels, map, fn
      lens, building_map ->
        A.put(building_map, lens, %{})
    end)
    |> A.put(leaf, leaf_value)
  end


  @doc """
  Like `ensure_map_multipath/1`, except lists are not allowed in the path (no branching).

  This perhaps has some use as documentation of intent.
  """
  def ensure_map_path(map, path, leaf_value) do
    precondition no_list_elements?(path)
    ensure_map_multipath(map, path, leaf_value)
  end
end
