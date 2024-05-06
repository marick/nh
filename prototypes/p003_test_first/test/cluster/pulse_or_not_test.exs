alias AppAnimal.{Cluster,Scenario}

defmodule Cluster.LinearClusterTest do
  use Scenario.Case, async: true
  alias System.Pulse

  test "choosing to pulse" do
    function_that_causes_pulse = & &1+1

    provocation send_test_pulse(to: :first, carrying: 3)

    configuration do: trace([C.linear(:first, function_that_causes_pulse),
                             forward_to_test()])

    assert_test_receives(4)
  end

  test "choosing to pulse something other than the default type" do
    function_that_causes_pulse = fn count ->
      Pulse.new(:special, count+1)
    end

    provocation send_test_pulse(to: :incrementer, carrying: 3)

    configuration do
      trace([C.linear(:incrementer, function_that_causes_pulse),
             forward_to_test()],
            for_pulse_type: :special)
    end

    assert assert_test_receives(_) == Pulse.new(:special, 4)

  end

  test "choosing not to pulse" do
    calc = fn _ -> :no_result end

    provocation send_test_pulse(to: :first, carrying: 3)

    configuration do: trace([C.linear(:first, calc),
                             forward_to_test()])

    refute_receive(_)
  end
end
