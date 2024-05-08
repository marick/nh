alias AppAnimal.Extras

defmodule Extras.LensTest do
  use AppAnimal.Case, async: true
  alias Extras.Lens, as: UT

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
end
