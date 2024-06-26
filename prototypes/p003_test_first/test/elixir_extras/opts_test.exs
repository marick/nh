alias AppAnimal.Extras

defmodule Extras.OptsTest do
  use ExUnit.Case, async: true
  use FlowAssertions
  alias Extras.Opts, as: UT
  doctest UT, import: true

  describe "parse" do
    test "simple case" do
      assert UT.parse([b: 2, a: 1], [:a, :b]) == [1, 2]
    end

    test "missing required key" do
      assert_raise(KeyError, "required argument :b is missing", fn ->
        UT.parse([a: 2], [:a, :b])
      end)
    end

    test "optional values" do
      assert UT.parse([a: 1, c: 3], [:a, b: 2, c: "unused"]) == [1, 2, 3]
    end

    test "unmentioned keys are an error" do
      assert_raise(KeyError, "extra keys are not allowed: [:b, :c]", fn ->
        UT.parse([a: 2, b: 3, c: 4], [:a])
      end)
    end

    test "... unless specifically allowed" do
      assert UT.parse([a: 2, b: 3, c: 4], [:a], extra_keys: :allowed) == [2]
    end
  end

  describe "required!" do
    test "fetches N keys" do
      assert UT.required!([a: 2, b: 3], [:a, :b]) == [2, 3]
    end

    test "key must be present" do
      assert_raise(KeyError, "keyword argument :b is missing", fn ->
        UT.required!([a: 2], [:a, :b])
      end)
    end

    test "extra keys are not allowed" do
      assert_raise(KeyError, "extra keyword arguments: [:b]", fn ->
        UT.required!([a: 2, b: 2], [:a])
      end)
    end
  end

  describe "put_missing!" do
    test "augment an option list" do
      UT.put_missing!([a: 1, z: 444], b: 2, c: 3)
      |> assert_good_enough(in_any_order [a: 1, z: 444, b: 2, c: 3])
    end

    test "it better actually *be* missing" do
      assert_raise(KeyError, "keys [:a] are already present", fn ->
        UT.put_missing!([a: 1], b: 2, a: 3)
      end)
    end
  end

  test "put if needed" do
    UT.put_when_needed([a: 1, z: 444], a: "ignored", b: 3)
    |> assert_good_enough(in_any_order [a: 1, b: 3, z: 444])
  end

  describe "calculating a new key from another key" do
    test "does nothing if the key is not present" do
      f = fn _ -> :do_nothing end
      [a: 1]
      |> UT.calculate_unless_given(:derived, from: :source, using: f)
      |> assert_equals([a: 1])
    end

    test "creates using any key" do
      opts = [aux: 3, source: 1]

      opts
      |> UT.calculate_unless_given(:derived, from: :source, using: fn source ->
        Keyword.fetch!(opts, :aux) + source
      end)
      |> assert_good_enough(in_any_order([aux: 3, source: 1, derived: 4]))
      # Note that the source is not removed
    end

    test "if the 'derived' exists, nothing is done, regardless of source" do
      opts = [aux: 3, source: 1, derived: 4]
      opts
      |> UT.calculate_unless_given(:derived, from: :source, using: &{opts, &1})
      |> assert_good_enough(in_any_order(opts))
    end
  end

  describe "raname outer to: inner" do
    test "the internal key did not exist" do
      opts = [outside: 3]
      opts
      |> UT.rename(:outside, to: :inside)
      |> assert_equal(inside: 3)
    end

    test "the internal key incorrectly exists" do
      opts = [inside: 1, outside: 3]
      assert_raise(KeyError, "Keys `:inside` and `:outside` conflict", fn ->
        UT.rename(opts, :outside, to: :inside)
      end)
    end

    test "it's OK if the external key doesn't exist" do
      opts = [inside: 3]
      assert UT.rename(opts, :outside, to: :inside) == opts

      assert UT.rename(opts, :outside, to: :something_else) == opts
    end
  end

end
