alias AppAnimal.Cluster

defmodule Cluster.CircularTest do
  use ClusterCase, async: true
  alias Cluster.Circular, as: UT
  alias Cluster.Throb

  describe "initialization" do 
    test "with default starting value" do
      cluster = circular(:example, & &1+1)
      state = UT.new(cluster)

      state
      |> assert_fields(calc: cluster.calc,
                       previously: %{})

      assert state.throb == Throb.counting_down_from(Duration.frequent_glance)
    end

    test "with a given starting value" do
      circular(:example, & &1+1, initial_value: 777)
      |> UT.new
      |> assert_field(previously: 777)
    end
  end
end
