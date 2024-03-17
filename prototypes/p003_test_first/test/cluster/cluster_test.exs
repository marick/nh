alias AppAnimal.Cluster

defmodule Cluster.ClusterTest do
  use ClusterCase, async: true
  alias AppAnimal.Cluster, as: UT

  test "test can_be_active" do
    assert UT.can_be_active?(circular(:name, & &1+1))
    refute UT.can_be_active?(  linear(:name, & &1+1))
  end
end
