alias AppAnimal.Cluster

defmodule Cluster.ClusterTest do
  use ClusterCase, async: true
  alias AppAnimal.Cluster, as: UT

  describe "readiness for messages" do
    test "does nothing for a linear type" do
      linear = linear(:new, constantly(:irrelevant))

      assert UT.ensure_ready(linear) == linear
    end

    test "making a circular cluster ready" do
      circular = circular(:new, constantly(:irrelevant))
      readied = UT.ensure_ready(circular)
      new_pid = readied.shape.pid
      assert is_pid(new_pid)
      assert Process.alive?(new_pid)

      # Note that the created lens is monitored
      Process.exit(new_pid, :kill)

      assert_receive({:DOWN, _, :process, ^new_pid, :killed})
    end

    test "the structure can be made unready" do
      unready = 
        circular(:new, constantly(:irrelevant))
        |> UT.ensure_ready()
        |> UT.unready()
      assert unready.shape.pid == nil
      # Note this is independent of whether the process is actually dead.
    end
    
  end
end
