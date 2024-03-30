alias AppAnimal.Extras

defmodule Extras.KeywordXTest do
  use ExUnit.Case, async: true
  use FlowAssertions
  alias Extras.KeywordX, as: UT

  describe "replace key" do 
    test "key is present" do
      actual = UT.replace_key([a: 3, b: 4], :a, :z)
      assert actual == [z: 3, b: 4]
    end

    test "missing key is fine" do
      original = [a: 3, b: 4]
      actual = UT.replace_key(original, :missing, :z)
      assert actual == original
    end
  end

  test "replace keys" do
      actual = UT.replace_keys([a: 3, b: 4, left_alone: 5], b: :bb, a: :aa, missing: :unused)
      assert actual == [aa: 3, bb: 4, left_alone: 5]
    end
end
