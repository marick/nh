defmodule FeatureDetectionTest do
  use ExUnit.Case
  alias FeatureDetection, as: F
  import FlowAssertions.TabularA
  import FlowAssertions.MiscA

  describe "utilities" do
    test "decomposition into text and gaps" do
      becomes = run_and_assert(&F.decompose/1)

      # Two or more newlines is a gap
      "abc"             |> becomes.(["abc"])
      "abc\n    def"	|> becomes.(["abc\n    def"])
      "abc\n\n  def"	|> becomes.(["abc", "\n\n", "  def"])
      "abc\n\n\ndef"	|> becomes.(["abc", "\n\n\n", "def"])

      # Newlines at start or end.
      "abc\n\ndef\n"	|> becomes.(["abc", "\n\n", "def\n"])
      "\nabc"           |> becomes.(["\nabc"])
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
      becomes = run_and_assert(&F.classify/1)

      ["\n\n"]                 |> becomes.([:gap])
      ["abc", "\n\n\n", "def"] |> becomes.([:text, :gap, :text])

      # Not fooled by stray newlines
      ["\nabc", "a\nb", "def\n"] |> becomes.([:text, :text, :text])

      # The everpresent boundary case
      [] |> becomes.([])                         
    end

    test "ranges" do
      input = "abc\n\n\ndef\n"
      [text1, gap, text2] = [0..2, 3..5, 6..9] = F.decompose(input) |> F.ranges


      assert String.slice(input, text1) == "abc"
      assert String.slice(input, gap) == "\n\n\n"
      assert String.slice(input, text2) == "def\n"
    end
  end


  test "edge_structure" do
    "part\n\nfragment\n\n\ngap\n"
    |> F.edge_structure
    |> assert_equals([text: 0..3, gap: 4..5, text: 6..13, gap: 14..16, text: 17..20])
  end
end
