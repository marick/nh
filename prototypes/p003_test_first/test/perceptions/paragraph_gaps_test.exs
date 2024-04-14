alias AppAnimal.Perceptions

defmodule Perceptions.ParagraphGapsTest do
  use ExUnit.Case, async: true
  alias Perceptions.ParagraphGaps, as: UT
  import FlowAssertions.TabularA
  import FlowAssertions.MiscA

  describe "utilities" do
    test "decomposition into text and gaps" do
      becomes = run_and_assert(&UT.decompose/1)

      # Two or more newlines is a gapg      "abc"             |> becomes.(["abc"])
      "abc\n    def"	|> becomes.(["abc\n    def"])
      "abc\n\n  def"	|> becomes.(["abc", "\n\n", "  def"])
      "abc\n\n\ndef"	|> becomes.(["abc", "\n\n\n", "def"])

      # Newlines at start or end.
      "abc\n\ndef\n"	|> becomes.(["abc", "\n\n", "def\n"])
      "\nab"           |> becomes.(["\nab"])
      "\n\nabc"         |> becomes.(["\n\n", "abc"])
      "abc\n\n"         |> becomes.(["abc", "\n\n"])

      # Nothing but gaps
      "\n"              |> becomes.(["\n"])
      "\n\n"            |> becomes.(["\n\n"])
      "\n\n\n"          |> becomes.(["\n\n\n"])

      # Nothing at all
      ""                |> becomes.([])
    end

    test "classify" do
      becomes = run_and_assert(&UT.classify/1)

      ["\n\n"]                 |> becomes.([:gap])
      ["abc", "\n\n\n", "def"] |> becomes.([:text, :gap, :text])

      # Not fooled by stray newlines
      ["\nabc", "a\nb", "def\n"] |> becomes.([:text, :text, :text])

      # The everpresent boundary case
      [] |> becomes.([])                         
    end

    test "ranges" do
      input = "abc\n\n\ndef\n"
      [text1, gap, text2] = [0..2, 3..5, 6..9] = UT.decompose(input) |> UT.ranges

      # Confirm that the ranges cover the characters I expected
      selects = run_and_assert(&(String.slice(input, &1)))
      text1 |> selects.("abc")
      gap   |> selects.("\n\n\n")
      text2 |> selects.("def\n")
    end
  end


  test "gap_structure" do
    "part\n\nfragment\n\n\ngap\n"
    |> UT.gap_structure
    |> assert_equals([text: 0..3, gap: 4..5, text: 6..13, gap: 14..16, text: 17..20])
  end

  test "printing gap structure" do
    returns = fn input, expected ->
      actual = UT.gap_string(input)   # I should really modify flow-assertions to know arity
      assert actual == expected
    end

    meh = "irrelevant"

    [text: meh]                      |> returns.("\u25A0")
    [text: meh, text: meh]           |> returns.("\u25A0\u25A0")
    [text: meh, gap: meh, text: meh] |> returns.("\u25A0_\u25A0")
  end

  test "gap count" do
    "part\n\nfragment\n\n\ngap\n"
    |> UT.gap_structure
    |> UT.gap_count
    |> assert_equals(2)


    "part"
    |> UT.gap_structure
    |> UT.gap_count
    |> assert_equals(0)
  end
end

