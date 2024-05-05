alias AppAnimal.{Network,NetworkBuilder}

# see also NetworkBuilderTest

defmodule NetworkBuilder.GutsTest do
  use AppAnimal.Case, async: true
  alias NetworkBuilder.Guts, as: UT

  describe "handling duplicates" do

    test "a duplicate name is an error" do
      original =
        Network.empty
        |> UT.trace([C.linear(:linear), C.circular(:circular)], for_pulse_type: :default)

      assert_raise(KeyError,
                   "You attempted to add cluster `:linear`, which already exists", fn ->
        UT.trace(original, [C.linear(:linear)], for_pulse_type: :default)
      end)
      assert_raise(KeyError,
                   "You attempted to add cluster `:circular`, which already exists", fn ->
        UT.trace(original, [C.circular(:circular)], for_pulse_type: :default)
      end)
    end

    test "the way to refer to an already-existing cluster is by its name" do
      original =
        Network.empty
        |> UT.trace([C.linear(:first), C.circular(:two_a)], for_pulse_type: :default)

      updated =
        original
        |> UT.trace([:first, C.circular(:two_b)], for_pulse_type: :default)

      assert updated.linear_names == MapSet.new([:first])
      assert updated.circular_names == MapSet.new([:two_a, :two_b])

      updated.out_edges
      |> assert_fields(first: %{default: MapSet.new([:two_a, :two_b])},
                       two_a: %{default: MapSet.new},
                       two_b: %{default: MapSet.new})
    end

    test "traces of different cluster types" do
      original =
        Network.empty
        |> UT.trace([C.linear(:first), C.circular(:two_a)], for_pulse_type: :default)

      updated =
        original
        |> UT.trace([:first, C.circular(:two_b)], for_pulse_type: :other)

      assert updated.linear_names == MapSet.new([:first])
      assert updated.circular_names == MapSet.new([:two_a, :two_b])

      updated.out_edges
      |> assert_fields(first: %{default: MapSet.new([:two_a]),
                                other: MapSet.new([:two_b])},
                       two_a: %{default: MapSet.new},
                       two_b: %{other: MapSet.new})
    end

    test "it is an error to refer to a cluster that hasn't been added" do
      assert_raise(KeyError,
                   "You referred to `:linear`, but there is no such cluster", fn ->
        UT.trace(Network.empty, [:linear], for_pulse_type: :default)
      end)
      assert_raise(KeyError,
                   "You referred to `:circular`, but there is no such cluster", fn ->
        UT.trace(Network.empty, [:circular], for_pulse_type: :default)
      end)
    end
  end

  describe "fanning out" do
    test "fanning out to structures" do
      network =
        Network.empty
        |> UT.fan_out(from: C.circular(:root), to: [C.linear(:a), C.linear(:b)])

      assert network.out_edges == %{root: %{default: MapSet.new([:a, :b])}}
    end

    test "fanning out to names" do
      alias AppAnimal.NetworkBuilder, as: NB

      p_builder = start_link_supervised!(NB)
      NB.unordered(p_builder, [C.circular(:root), C.linear(:a)])

      network = NB.network(p_builder)

      updated =
        UT.fan_out(network, from: :root, to: [:a, C.linear(:b)])

      assert updated.out_edges == %{root: %{default: MapSet.new([:a, :b])}}
    end
  end
end
