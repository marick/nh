defmodule AppAnimal.ParagraphFocus.MoveFragmentTest do
  use ExUnit.Case
  alias AppAnimal.ParagraphFocus.Motor.MoveFragment, as: UT
  import FlowAssertions.TabularA
  import FlowAssertions.MiscA


  test "possibly shifted" do
    returns = run_and_assert(&UT.accounting_for_edits/2)
    #"123\n\n678\n\nbcd"
    ["123\n\n678\n\nbcd", 6..8] |> returns.({:ok, 6..8})

    #"123\n\n678\n\nbcd"
    ["_123\n\n678\n\nbcd", 6..8] |> returns.({:ok, 7..9})  # We tolarate an added char in prefix
    # ^
    
    #"123\n\n678\n\nbcd"
    ["_123_\n\n678\n\nbcd", 6..8] |> returns.({:ok, 8..10}) # ... and two.
    #     ^
    
    #"123\n\n678\n\nbcd"
    ["_12_3_\n\n678\n\nbcd", 6..8] |> returns.({:ok, 9..11}) # ... and three
    #    ^

    # But four is too much of a change: the app_animal should wait.
    #"123\n\n678\n\nbcd"
    ["__12_3_\n\n678\n\nbcd", 6..8] |> returns.(:error)

    # Changes past the end are fine: they don't affect the snippet.
    ["123\n\n678\n\nbcd________________", 6..8] |> returns.({:ok, 6..8})

    # Note that destruction of one of the adjoining newlines is also an error.
    ["123\n678\n\nbcd", 6..8] |> returns.(:error)
    #    ^^
    ["123\n\n678\nbcd", 6..8] |> returns.(:error)
    #            ^^

  end

  describe "grab fragment" do
    test "there's been no change in the paragraph" do 
      %{text: "123\n\n678\n\nbcd", cursor: 1} 
      |> UT.grab_fragment(at_roughly: 6..8)   # this is the range originally seen.
      |> assert_equal({:ok, ["123\n", "\n678\n", "\nbcd"]})
    end

    test "there's been an insertion before the range" do
      %{text: "___123\n\n678\n\nbcd", cursor: 3}
      |> UT.grab_fragment(at_roughly: 6..8)
      |> assert_equal({:ok, ["___123\n", "\n678\n", "\nbcd"]})
    end

    test "too much change" do
      %{text: "__________123\n\n678\n\nbcd", cursor: 10}
      |> UT.grab_fragment(at_roughly: 6..8)
      |> assert_equal(:error)
    end

    @tag :skip
    test "punt if cursor is in the range" do
      %{text: "123\n\n678\n\nbcd", cursor: 7} 
      |> UT.grab_fragment(at_roughly: 6..8)   # this is the range originally seen.
      |> assert_equal(:error)
    end

    @tag :skip
    test "note that a cursor between the two boundary newlines is also rejected"

    @tag :skip
    test "it is the *shifted* range" do
      # Just to explain what's going on:
      # Suppose we have a normal shifted paragraph (with cursor out of the way:
      "___123\n\n678\n\nbcd"
      |> UT.accounting_for_edits(6..8)
      |> ok_content
      |> assert_equals(9..11)

      # Now put the paragraph on the second preceeding newline (between the two)
      # "___123\n\n678\n\nbcd"
      # 
      # |> UT.accounting_for_edits(6..8)
      # |> assert_equal({:ok, ["___123\n", "\n678\n", "\nbcd"]})
      
    end

    @tag :skip
    test "specifically, if it's within the newline-delimiters (starting)" do
    end

    @tag :skip
    test "... and ending"
  end
end

