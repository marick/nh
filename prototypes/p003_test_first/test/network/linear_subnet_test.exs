alias AppAnimal.Network

defmodule Network.LinearSubnetTest do
  use ClusterCase, async: true
  alias Network.LinearSubnet, as: UT

  test "lens for setting router" do
    updated =
      UT.new([C.linear(:first), C.linear(:second)])
      |> A.put(:routers, "added router")

    assert A.get_all(updated, :routers) == ["added router", "added router"]
    assert A.get_only(updated, UT.cluster_named(:first)).router == "added router"
  end
end
