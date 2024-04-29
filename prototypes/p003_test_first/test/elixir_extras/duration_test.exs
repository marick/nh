alias AppAnimal.Duration

defmodule AppAnimal.DurationTest do
  use AppAnimal.Case, async: true
  alias Duration, as: UT

  describe "conversions" do
    test "seconds into quanta" do
      assert UT.quantum() == 100
      assert UT.quanta(10) == 1000

      assert UT.seconds(1) == 10
      assert UT.seconds(0.1) == 1
    end
  end

end
