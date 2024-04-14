defmodule AppAnimal.Cluster.LinearClusterTest do
  use ClusterCase, async: true

  describe "linear cluster handling: function version: basics" do
    test "a transmission of pulses" do

      aa = enliven([linear(:first, &(&1+1)), to_test()])
      send_test_pulse(aa, to: :first, carrying: 1)

      assert_test_receives(2)
    end
  end
  
  describe "handling of a calculation" do
    test "choosing to pulse" do
      function_that_causes_pulse = & &1+1
      aa = enliven([linear(:first, function_that_causes_pulse),
                    to_test()])
      send_test_pulse(aa, to: :first, carrying: 3)

      assert_test_receives(4)
    end

    test "choosing not to pulse" do
      calc = fn _ -> :no_result end

      aa = enliven([linear(:first, calc), to_test()])
      send_test_pulse(aa, to: :first, carrying: 3)

      refute_receive(_)
    end
  end
end
