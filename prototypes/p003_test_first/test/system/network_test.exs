defmodule AppAnimal.System.NetworkTest do
  use ClusterCase, async: true
  alias System.Network, as: UT
  
  defp named(names) when is_list(names),
       do: Enum.map(names, &named/1)
  defp named(name),
       do: circular(name)

  describe "lenses" do
    test "l_cluster_named" do 
      network = UT.new(first: "a cluster")
      assert deeply_get_only(network, UT.l_cluster_named(:first)) == "a cluster"
    end

    test "l_downstream_of" do
      network = UT.new(first: named(:first))
      assert deeply_get_only(network, UT.l_downstream_of(:first)) == []
    end
  end
end
