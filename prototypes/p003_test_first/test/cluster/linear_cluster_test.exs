defmodule AppAnimal.Cluster.LinearClusterTest do
  use ClusterCase, async: true

  def given(trace_or_network), do: AppAnimal.switchboard(trace_or_network)
  
  describe "linear cluster handling: function version: basics" do
    test "a transmission of pulses" do
      
      given([linear(:first, &(&1+1)), 
             to_test()])
      |> send_test_pulse(to: :first, carrying: 1)

      assert_test_receives(2)
    end
  end
  
  describe "handling of a calculation" do
    test "choosing to pulse" do

      given([linear(:first, & &1+1), to_test()])
      |> send_test_pulse(to: :first, carrying: 3)

      assert_test_receives(4)
    end

    test "choosing not to pulse" do
      calc = fn _ -> :no_pulse end

      given(trace([linear(:first, calc), to_test()]))
      |> send_test_pulse(to: :first, carrying: 3)

      refute_receive(_)
    end
  end
end
