alias AppAnimal.{ClusterBuilders,Cluster}

defmodule ClusterBuilders.CircularTest do
  use ExUnit.Case, async: true
  use FlowAssertions
  alias ClusterBuilders, as: UT

  describe "variants of circular creation" do

    test "only a name is specified" do
      UT.circular(:name)
      |> assert_fields(name: :name,
                       id: Cluster.Identification.new(:name, :circular),
                       throb: Cluster.Throb.default,
                       calc: &Function.identity/1,
                       previously: %{})
    end

    test "name and options" do
      UT.circular(:name, previously: 3)
      |> assert_fields(name: :name,
                       id: Cluster.Identification.new(:name, :circular),
                       throb: Cluster.Throb.default,
                       calc: &Function.identity/1,

                       previously: 3)
    end

    test "name and calc" do
      f = & &1+1
      UT.circular(:rounder, f)
      |> assert_fields(name: :rounder,
                       id: Cluster.Identification.new(:rounder, :circular),
                       throb: Cluster.Throb.default,
                       calc: f,
                       previously: %{})
    end


    test "name, calc, and options" do
      alias AppAnimal.Duration
      f = & &1+1
      throb = Cluster.Throb.counting_down_from(Duration.quanta(3))
      UT.circular(:rounder, f, throb: throb, previously: 5)
      |> assert_fields(name: :rounder,
                       id: Cluster.Identification.new(:rounder, :circular),
                       throb: throb,
                       calc: f,
                       previously: 5)
    end
  end
end
