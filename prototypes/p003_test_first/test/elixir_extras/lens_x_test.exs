alias AppAnimal.Extras


defmodule Extras.LensXTest do
  use AppAnimal.Case, async: true
  alias Extras.LensX, as: UT
  doctest UT, import: true

  describe "nested_map_leaves" do
    test "success cases" do
      produces = run_and_assert(fn [map, route] ->
        A.get_all(map, UT.nested_map_leaves(route))
      end)

      one_branch = %{a: %{b: 3}}
      [one_branch, [:a, :b]]     |> produces.([3])
      [one_branch, [[:a], [:b]]] |> produces.([3])

      three_by_three = %{
        a: %{aa:   1, bb:   2, cc:   3},
        b: %{aa:  11, bb:  22, cc:  33},
        c: %{aa: 111, bb: 222, cc: 333}
      }

      [three_by_three, [:a, :aa]] |> produces.([1])
      [three_by_three, [[:a, :b], :aa]] |> produces.([1, 11])
      [three_by_three, [[:a, :b], [:aa, :bb]]] |> produces.([1, 2, 11, 22])

      # Don't have to go all the way to the bottom
      deep =  %{
        a: %{aa:  1, bb:  2, cc: %{aaa:  3}},
        b: %{aa: 11, bb: 22, cc: %{aaa: 33}},
      }

      [deep, [[:a, :b], [:aa, :cc]]] |> produces.([1, %{aaa: 3}, 11, %{aaa: 33}])
    end

    test "missing keys" do
      m = %{a: %{b: 1}}

      assert_raise(KeyError, fn ->
        A.get_all(m, UT.nested_map_leaves([:b]))
      end)

      assert_raise(KeyError, fn ->
        A.get_all(m, UT.nested_map_leaves([:a, :c]))
      end)

    end
  end

  describe "ensure_nested_map_leaves" do
    test "normal use" do
      produces = run_and_assert(fn [map, route] ->
        UT.ensure_nested_map_leaves(map, route, :LEAF)
      end)

      [%{a: %{aa: %{}}}, [:a, :aa, :aaa]] |> produces.(%{a: %{aa: %{aaa: :LEAF}}})
      [%{a: %{       }}, [:a, :aa, :aaa]] |> produces.(%{a: %{aa: %{aaa: :LEAF}}})
      [%{             }, [:a, :aa, :aaa]] |> produces.(%{a: %{aa: %{aaa: :LEAF}}})

      # Does not erase existing leaves
      [%{a: %{aa: %{aaa: 1}}}, [:a, :aa, :aaa]] |> produces.(%{a: %{aa: %{aaa: 1}}})

      # Flesh out the tree
      input = %{a: %{aa: %{aaa: 1}},
                b: %{bb: %{}},
                c: %{}}

      input
      |> UT.ensure_nested_map_leaves([[:a, :b, :d], [:aa, :bb], :aaa], :LEAF)
      |> assert_fields(a: %{aa: %{aaa: 1},       # no change
                            bb: %{aaa: :LEAF}},
                       b: %{aa: %{aaa: :LEAF},
                            bb: %{aaa: :LEAF}},
                       c: %{},                   # left alone
                       d: %{aa: %{aaa: :LEAF},
                            bb: %{aaa: :LEAF}})
    end
  end

  describe "mapset lenses" do
    test "mapset_values/0 as an intermediate lens" do
      lens = UT.mapset_values |> Lens.key?(:a)

      input    = MapSet.new([%{a: 1  }, %{a: 2  }, %{a: 3  }, %{vvvv: "unchanged"}])
      expected = MapSet.new([%{a: 100}, %{a: 200}, %{a: 300}, %{vvvv: "unchanged"}])
      assert A.map(input, lens, & &1*100) == expected

      A.get_all(input, lens) |> assert_good_enough(in_any_order([1, 2, 3]))
      assert A.get_all(input, lens |> Lens.filter(& &1 < 2)) == [1]

      assert A.put(input, lens, 3) == MapSet.new([%{a: 3}, %{vvvv: "unchanged"}])
                                      # Note that it collapsed the 3 identical maps
    end

    test "mapset_values/0 as an ending lens" do
      input = MapSet.new([%{a: 1}, %{a: 2}, %{a: 3}])

      input
      |> A.get_all(UT.mapset_values)
      |> assert_good_enough(in_any_order([%{a: 1}, %{a: 2}, %{a: 3}]))

      # The other cases blow up in various ways.
    end


    test "mapset_value_identified_by!/1 as an ending lens; element present" do
      input = MapSet.new([%{a: :X, b: 1}, %{a: :X}, %{a: 3}])

      lens = UT.mapset_value_identified_by(a: :X)

      A.get_all(input, lens)
      |> assert_good_enough(in_any_order([%{a: :X, b: 1}, %{a: :X}]))

      assert A.put(input, lens, 3333) == MapSet.new([3333, %{a: 3}])

      A.map(input, lens, fn map -> Map.put(map, :c, 2) end)
      |> assert_equal(MapSet.new([%{a: :X, b: 1, c: 2}, %{a: :X, c: 2}, %{a: 3}]))
    end


    test "mapset_value_identified_by/1 as an ending lens; element absent" do
      # Really covered by above, but wotthehell, wotthehell, archie.
      input = MapSet.new([%{a: :X, b: 1}])
      lens = UT.mapset_value_identified_by(a: :missing)

      assert A.get_all(input, lens) == []
      assert A.put(input, lens, %{a: :missing}) == input
      assert A.map(input, lens, fn map -> %{map | c: 2} end) == input
    end

    test "mapset_value_identified_by!/1 as an intermediate lens; element present" do
      # Really covered by above, but wotthehell, wotthehell, archie.
      input = MapSet.new([%{a: :X, b: 1}, %{a: :X, b: 2, c: 3}, %{a: :X}, %{a: 3}])

      lens = UT.mapset_value_identified_by(a: :X) |> Lens.key?(:b)

      A.get_all(input, lens)
      |> assert_good_enough(in_any_order([1, 2]))

      actual = A.put(input, lens, 3333)
      expected = MapSet.new([%{a: :X, b: 3333}, %{a: :X, b: 3333, c: 3}, %{a: :X}, %{a: 3}])
      assert actual == expected

      actual = A.map(input, lens, & &1 * 1000)
      expected = MapSet.new([%{a: :X, b: 1000}, %{a: :X, b: 2000, c: 3}, %{a: :X}, %{a: 3}])
      assert actual == expected
    end


    test "mapset_value_identified_by/1 as an intermediate lens; element absent" do
      input = MapSet.new([%{a: 1, b: 2}, %{a: 3}])
      lens = UT.mapset_value_identified_by(a: :X) |> Lens.key?(:b)

      assert A.get_all(input, lens) == []

      assert A.put(input, lens, 3333) == input

      assert A.map(input, lens, & &1 * 1000) == input
    end

    test "doctest would be too cluttered" do
      defmodule Point do
        use AppAnimal

        typedstruct do
          field :x, integer
          field :y, integer
        end

        def new(x, y), do: %__MODULE__{x: x, y: y}
      end

      input =
        # A struct with `:x` and `:y` fields
        [Point.new(0, 0), Point.new(0, 1), Point.new(1, 10)]
        |> MapSet.new

      lens = UT.mapset_value_identified_by(x: 0) |> Lens.key(:y)
      actual = A.map(input, lens, & &1 + 1000)
      assert actual == [Point.new(0, 1000), Point.new(0, 1001), Point.new(1, 10)] |> MapSet.new

      A.get_all(input, lens)
      |> assert_good_enough(in_any_order([0, 1]))
    end
  end

  test "justify the difference between a missing key and one with a nil value" do
    input = MapSet.new [%{a: 1}, %{a: nil, b: 2}, %{}]
    lens = UT.mapset_value_identified_by(a: nil)

    assert A.get_only(input, lens) == %{a: nil, b: 2}
  end

end
