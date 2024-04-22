alias AppAnimal.{Network,Building}

defmodule Network.LinearSubnetTest do
  use ClusterCase, async: true
  alias Network.LinearSubnet, as: UT
  alias Building.Parts, as: M

  test "lens for setting router" do
    updated =
      UT.new([M.linear(:first), M.linear(:second)])
      |> A.put(:routers, "added router")

    assert A.get_all(updated, :routers) == ["added router", "added router"]
    assert A.get_only(updated, UT.cluster_named(:first)).router == "added router"
  end
end
