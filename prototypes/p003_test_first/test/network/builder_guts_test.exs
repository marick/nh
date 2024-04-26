alias AppAnimal.{Network,NetworkBuilder}

# see also NetworkBuilderTest

defmodule NetworkBuilder.GutsTest do
  use ClusterCase, async: true
  alias NetworkBuilder.Guts, as: UT

  describe "handling duplicates" do

    test "a duplicate name is an error" do
      original =
        Network.empty
        |> UT.trace([C.linear(:linear), C.circular(:circular)])

      assert_raise(KeyError,
                   "You attempted to add cluster `:linear`, which already exists", fn ->
        UT.trace(original, [C.linear(:linear)])
      end)
      assert_raise(KeyError,
                   "You attempted to add cluster `:circular`, which already exists", fn ->
        UT.trace(original, [C.circular(:circular)])
      end)
    end

    test "the way to refer to an already-existing cluster is by its name" do
      original =
        Network.empty
        |> UT.trace([C.linear(:first), C.circular(:two_a)])

      updated =
        original
        |> UT.trace([:first, C.circular(:two_b)])

      assert updated.linear_names == MapSet.new([:first])
      assert updated.circular_names == MapSet.new([:two_a, :two_b])

      updated.name_to_downstreams
      |> assert_fields(first: MapSet.new([:two_a, :two_b]),
                       two_a: MapSet.new,
                       two_b: MapSet.new)
    end

    test "it is an error to refer to a cluster that hasn't been added" do
      assert_raise(KeyError,
                   "You referred to `:linear`, but there is no such cluster", fn ->
        UT.trace(Network.empty, [:linear])
      end)
      assert_raise(KeyError,
                   "You referred to `:circular`, but there is no such cluster", fn ->
        UT.trace(Network.empty, [:circular])
      end)
    end

  end
end
