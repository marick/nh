alias AppAnimal.Cluster

defmodule Cluster.ClusterTest do
  use ClusterCase, async: true
  alias AppAnimal.Cluster, as: UT

  ## Most of the tests are elsewhere, like in the switchboard tests or the
  ## circular_process tests.

  test "test can_throb" do
    assert UT.can_throb?(circular(:name, & &1+1))
    refute UT.can_throb?(  linear(:name, & &1+1))
  end
end
