alias AppAnimal.Duration

defmodule AppAnimal.DurationTestTest do
  use ClusterCase, async: true
  alias Duration, as: UT

  describe "conversions" do
    test "seconds into milliseconds" do
      assert UT.seconds(1) == 1000
      assert UT.seconds(0.1) == 100

      assert UT.quanta(10) == 1000
    end
  end

end
