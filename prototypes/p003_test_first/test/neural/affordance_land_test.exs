defmodule AppAnimal.Neural.AffordanceLandTest do
  alias AppAnimal.Neural.AffordanceLand
  use ClusterCase, async: true

  test "a simple send downstream" do
    first = affordance(:paragraph_text)
    second = linear_cluster(:edge_detector, forward_pulse_to_test())
    switchboard = switchboard_from_cluster_trace([first, second])


    affordances = start_link_supervised!({AffordanceLand, switchboard: switchboard})
    AffordanceLand.provide_affordance(affordances, named: :paragraph_text,
                                                conveying: "some text")
    assert_receive(["some text", from: :edge_detector])
    
  end
  
  private do
    def forward_pulse_to_test do
      test_pid = self()
      fn data, %{name: name} ->
        send(test_pid, [data, from: name])
        :ok
      end
    end
  end    
  
end
