alias AppAnimal.Extras

defmodule Extras.OptsTest do
  use ExUnit.Case, async: true
  use FlowAssertions
  alias Extras.Opts, as: UT

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

  describe "copy" do
    test "when original exists" do 
      actual = UT.copy([a: 3, b: 4], :c, from_existing: :a)
      assert_good_enough(actual, in_any_order([a: 3, b: 4, c: 3]))
    end

    test "when it doesn't" do
      actual = UT.copy([a: 3, b: 4], :c, from_existing: :nonexistent)
      assert actual == [a: 3, b: 4]
    end
  end

  describe "required!" do
    test "fetches N keys" do 
      assert UT.required!([a: 2, b: 3], [:a, :b]) == [2, 3]
    end

    test "key must be present" do
      try do
        UT.required!([a: 2], [:a, :b])
        flunk("missing exception")
      rescue
        error ->
          assert_struct_named(error, KeyError)
          assert error.message == "keyword argument :b is missing"
      end
    end

    test "extra keys are not allowed" do
      try do
        UT.required!([a: 2, b: 2], [:a])
        flunk("missing exception")
      rescue
        error ->
          assert_struct_named(error, KeyError)
          assert error.message == "extra keyword arguments: [:b]"
      end
    end
  end

  describe "add_missing!" do
    test "augment an option list" do
      UT.add_missing!([a: 1, z: 444], b: 2, c: 3)
      |> assert_good_enough(in_any_order [a: 1, z: 444, b: 2, c: 3])
    end
      
    test "it better actually *be* missing" do
      try do 
        UT.add_missing!([a: 1], b: 2, a: 3)
        flunk("unreached")
      rescue
        error ->
          error 
          |> assert_struct_named(KeyError)
          |> assert_fields(term: [a: 1],
                           message: "keys [:a] are already present")
      end
    end
  end

  describe "add_if_missing" do
    test "default if needed" do
      UT.add_if_missing([a: 1, z: 444], a: "ignored", b: 3)
      |> assert_good_enough(in_any_order [a: 1, b: 3, z: 444])
    end
  end
end
