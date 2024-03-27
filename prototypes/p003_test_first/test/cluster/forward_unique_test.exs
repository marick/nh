defmodule AppAnimal.Cluster.ForwardUniqueTest do
  use ClusterCase, async: true

  def given(trace_or_network), do: AppAnimal.switchboard(trace_or_network)
  
  test "only unique values pass through" do
      given([forward_unique(:first), 
             to_test()])
      |> send_test_pulse(to: :first, carrying: 1)

      assert_test_receives(1)
  end
end
