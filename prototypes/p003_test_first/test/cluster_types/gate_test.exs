alias AppAnimal.Cluster

defmodule Cluster.GateTest do
  use AppAnimal.Case, async: true

  test "gate" do
    cluster = C.gate(:example, & &1 > 0)

    assert_fields(cluster, id: Identification.new(name: :example, label: :gate),
                           name: :example)

    assert cluster.calc.(0) == :no_result
    assert cluster.calc.(1) == 1
  end
end
