defmodule AppAnimal.ParagraphFocus.MoveFragmentTest do
  use ExUnit.Case
  alias AppAnimal.ParagraphFocus.Motor.MoveFragment, as: UT
  import FlowAssertions.TabularA
  # import FlowAssertions.MiscA
  
  def para(text, cursor \\ 1), do: %{text: text, cursor: cursor}
  
  test "locating a moving fragment" do
    template = "0123456\n\n9abcd\n\ngh\n"
    original_range = 9..13
    
    returns = run_and_assert(fn text ->
      UT.grip_fragment(para(text), at_roughly: original_range)
    end)
    
    template |> returns.({:ok, 9..13})    # well, of course it finds it if it didn't move

    # shift to the right
    move_right = &(String.pad_leading(template, String.length(template) + &1, "_"))
    move_right.(1) |> returns.({:ok, 10..14})

    # shift to the left
    move_left = &(String.split_at(template, &1)) |> elem(1)
    IO.inspect("------")
    IO.inspect(move_left.(1))
    move_left.(1) |> returns.({:ok, 8..12})

  end

  # the search bounds are twice the original fragment (half the fragment on both sides)
  # with enouggh room for two gap characters on either end.
  test "the fragment is allowed to move but not so much" do 
    returns = run_and_assert(&(UT.allowed_range(&1, 100)))

    6..7  |> returns.(3..10)
    6..8  |> returns.(3..11)  # rounds toward zero
    5..8  |> returns.(1..12)

    6..6  |> returns.(4..8)  # silly

    # Don't exceed boundaries
    96..99  |> returns.(92..100)
    1..4  |> returns.(0..8)
  end

  # test "detection of double quotes" do
  #   returns = run_and_assert(fn text -> UT.new_end(text, 4..6) end)


  #   "123456\n\n" |> returns.(6)
  #   "123456\n\n" |> returns.(7)
  #   "123456\n\n" |> returns.(8)

  #   "123\n\n" |> returns.(:error)   # searches from the beginning.
  #   "12\n\n"    |> returns.(:error)   # too short
  #   "1\n\n"     |> returns.(:error)   # ditto

  # end

  # test "possibly shifted" do
  #   returns = run_and_assert(&UT.accounting_for_edits/2)
  #   #"123\n\n678\n\nbcd"
  #   ["123\n\n678\n\nbcd", 6..8] |> returns.({:ok, 6..8})

  #   #"123\n\n678\n\nbcd"
  #   ["_123\n\n678\n\nbcd", 6..8] |> returns.({:ok, 7..9})  # We tolarate an added char in prefix
  #   # ^
    
  #   #"123\n\n678\n\nbcd"
  #   ["_123_\n\n678\n\nbcd", 6..8] |> returns.({:ok, 8..10}) # ... and two.
  #   #     ^
    
  #   #"123\n\n678\n\nbcd"
  #   ["_12_3_\n\n678\n\nbcd", 6..8] |> returns.({:ok, 9..11}) # ... and three
  #   #    ^

  #   # But four is too much of a change: the app_animal should wait.
  #   #"123\n\n678\n\nbcd"
  #   ["__12_3_\n\n678\n\nbcd", 6..8] |> returns.(:error)

  #   # Changes past the end are fine: they don't affect the snippet.
  #   ["123\n\n678\n\nbcd________________", 6..8] |> returns.({:ok, 6..8})

  #   # Note that destruction of one of the adjoining newlines is also an error.
  #   ["123\n678\n\nbcd", 6..8] |> returns.(:error)
  #   #    ^^
  #   ["123\n\n678\nbcd", 6..8] |> returns.(:error)
  #   #            ^^
  # end

  # test "cursor_not_in_way" do
  #   reference = "0\n\n34\n\n7"  #
  #   #             ^1 is safely distant because the character will appear before the \n
  #   #               ^2 is too close: it will split the gap
  #   #                     ^ 6 is too close: ditto
  #   #                       ^7 is safely distant
  #   #
  #   is_judged = run_and_assert(fn cursor_at ->
  #     paragraph = %{text: reference, cursor: cursor_at}
  #     UT.cursor_relationship(paragraph, 3..4)
  #   end)

  #   is_judged.(1, :safely_distant)
  #   2 |> is_judged.(:too_close)
  #   6 |> is_judged.(:too_close)
  #   7 |> is_judged.(:safely_distant)
  # end

  # describe "grab fragment: changes in the paragraph" do
  #   test "there's been no change in the paragraph" do 
  #     %{text: "123\n\n678\n\nbcd", cursor: 1} 
  #     |> UT.grab_fragment(at_roughly: 6..8)   # this is the range originally seen.
  #     |> assert_equal({:ok, ["123\n", "\n678\n", "\nbcd"]})
  #   end

  #   test "there's been an insertion before the range" do
  #     %{text: "___123\n\n678\n\nbcd", cursor: 3}
  #     |> UT.grab_fragment(at_roughly: 6..8)
  #     |> assert_equal({:ok, ["___123\n", "\n678\n", "\nbcd"]})
  #   end

  #   test "too much change" do
  #     %{text: "__________123\n\n678\n\nbcd", cursor: 10}
  #     |> UT.grab_fragment(at_roughly: 6..8)
  #     |> assert_equal(:error)
  #   end
  # end

  # test "grab_fragment respond to cursor position, without text addition" do
  #   text = "123\n\n678\n\nbcd"
  #   successful_split = ["123\n", "\n678\n", "\nbcd"]
    
  #   returns = run_and_assert(fn cursor_at ->
  #     %{text: text, cursor: cursor_at}
  #     |> UT.grab_fragment(at_roughly: 6..8)   # this is the range originally seen.
  #   end)

  #   # within that range
  #   7 |> returns.(:error)

  #   # boundary newlines
  #   4  |> returns.({:ok, successful_split})
  #   5  |> returns.(:error)
  #   10 |> returns.(:error)
  #   11 |> returns.({:ok, successful_split})
  # end


  # test "it is the *shifted* range that matters" do
  #   # Just to explain what's going on:
  #   # Suppose we start with this:
  #   # "1234\n\n7\n\na"
  #   # It would have text range 7..7, and it would reject a cursor within 6..9
    
  #   # However, we make this shift by 3:
  #   right3 = "___1234\n\n7\n\na"
  #   # The forbidden zone is now 9-12
  #   # A successful split is
  #   right_success = ["___1234\n", "\n7\n", "\na"]
    
  #   returns = run_and_assert(fn text, cursor ->
  #     %{text: text, cursor: cursor}
  #     |> UT.grab_fragment(at_roughly: 7..7)
  #   end)

  #   [right3, 8 ] |> returns.({:ok, right_success})
  #   [right3, 9 ] |> returns.(:error)
  #   [right3, 12] |> returns.(:error)
  #   [right3, 13] |> returns.({:ok, right_success})


  #   # Again, we choose this to start with:
  #   # "1234\n\n7\n\na"
  #   # However, we make this shift by deleting three characters:
  #   left3 = "4\n\n7\n\na"
  #   # The forbidden zone is now 1..5
  #   # A successful split is
  #   left_success = ["4\n", "\n7\n", "\na"]

  #   IO.puts "HI"
  #   [left3, 3] |> returns.({:ok, left_success})
    
  # end
end

