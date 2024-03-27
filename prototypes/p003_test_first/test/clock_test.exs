alias AppAnimal.Throb

defmodule Throb.UnitsTest do
  use ClusterCase, async: true
  alias Throb.Units, as: UT


  describe "conversions" do
    test "seconds into milliseconds" do
      assert UT.seconds(1) == 1000
      assert UT.seconds(0.1) == 100
    end
  end
  
end
