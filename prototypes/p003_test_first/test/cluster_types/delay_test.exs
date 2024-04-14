AppAnimal.Cluster

defmodule Cluster.DelayTest do
  use ClusterCase, async: true

  describe "delay" do
    setup do
      aa = enliven([delay(:first, 2), to_test()],
                   throb_interval: Duration.foreverish)
      [aa: aa]
    end
      
    test "delay for some throbs", %{aa: aa} do
      send_test_pulse(aa, to: :first, carrying: "data")
      refute_receive("data")

      # It will take two throbs to get data
      throb_all_active(aa)
      refute_receive(_)

      throb_all_active(aa)
      assert_test_receives("data")
    end

    test "a pulse starts the delay over again", %{aa: aa} do
      send_test_pulse(aa, to: :first, carrying: "data")
      refute_receive("data")

      throb_all_active(aa)
      refute_receive(_)
      assert peek_at(aa, :current_age, of: :first) == 1

      # pulse cancels out throbbing
      send_test_pulse(aa, to: :first, carrying: "replacement data")
      refute_receive(_)
      assert peek_at(aa, :current_age, of: :first) == 0

      throb_all_active(aa)
      refute_receive(_)

      # Note that the replacement data is sent
      throb_all_active(aa)
      assert_test_receives("replacement data")
    end
  end
end
