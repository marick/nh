alias AppAnimal.System

defmodule System.ThrobTest do
  use ExUnit.Case, async: true
  alias System.Throb, as: UT

  test "seconds into milliseconds" do
    assert UT.seconds(1) == 1000
    assert UT.seconds(0.1) == 100
  end
end
