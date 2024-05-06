alias AppAnimal.ClusterBuilders

defmodule ClusterBuilders.LinearTest do
  use AppAnimal.Case, async: true

  describe "variants of linear creation" do
    test "only a name is specified" do
      C.linear(:name)
      |> assert_fields(name: :name,
                       id: Cluster.Identification.new(:name, :linear),
                       calc: &Function.identity/1)
    end

    test "can also add a calc function" do
      f = & &1 + 1
      C.linear(:name, f)
      |> assert_fields(name: :name,
                       id: Cluster.Identification.new(:name, :linear),
                       calc: f)
    end

    test ".. or options" do
      C.linear(:name, label: :subtype)
      |> assert_fields(name: :name,
                       id: Cluster.Identification.new(:name, :subtype),
                       calc: &Function.identity/1)
    end

    test ".. or both" do
      f = & &1+1
      C.linear(:name, f, label: :subtype)
      |> assert_fields(name: :name,
                       id: Cluster.Identification.new(:name, :subtype),
                       calc: f)
    end
  end
end
