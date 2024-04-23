alias AppAnimal.Cluster

defmodule Cluster.LinearTest do
  use ClusterCase, async: true
  alias Cluster.Linear, as: UT

  describe "initialization" do
    test "with default starting values" do
      f = & &1+1
      UT.new(name: :a_name, calc: f)
      |> assert_fields(name: :a_name,
                       id: "default value is temporary",
                       calc: f,
                       router: :installed_later)
    end

    test "with a given starting value" do
      f = & &1+1
      UT.new(name: :example, calc: f, id: "replace")
      |> UT.new
      |> assert_field(name: :example,
                      id: "replace")
    end
  end
end
