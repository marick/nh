defmodule AppAnimal.ParagraphFocus.MoveFragmentTest do
  use ExUnit.Case
  alias AppAnimal.ParagraphFocus.Motor.MoveFragment, as: UT
  import FlowAssertions.TabularA
  # import FlowAssertions.MiscA
  
  def para(text, cursor \\ 1), do: %{text: text, cursor: cursor}

  describe "locating a moving fragment" do
    
    test "the fragment is not edited" do 
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
      move_left.(1) |> returns.({:ok, 8..12})
      
      # Something can be shifted too far
      move_right.(3) |> returns.(:error)
      move_left.(3) |> returns.(:error)
    end

    test "changes to the fragment: all errors" do
      original_range =             5..13
      template =           "___\n\n123456789\n\n___"
      char_deleted =       "___\n\n12345678\n\n___"
                                           #
      fragment_split =     "___\n\n1234\n\n789\n\n___"
                                       ####
      front_broken =       "___\n123456789\n\n___"
                               ##
      back_broken =        "___\n\n123456789\n___"
                                            ##
      no_fragment_at_all = "_____123456789_____"

      expect_error = fn text ->
        assert UT.grip_fragment(para(text), at_roughly: original_range) == :error
      end
      
      # Just confirm the template works when unchanged
      assert UT.grip_fragment(para(template), at_roughly: original_range) == {:ok, 5..13}
      expect_error.(char_deleted)
      expect_error.(fragment_split)
      expect_error.(front_broken)
      expect_error.(back_broken)
      expect_error.(no_fragment_at_all)
    end


    test "finally, it is suspicious if the cursor is in - or near - the fragment." do
      template =           "_\n\n345\n\n_"
      original_range =           3..5

      judgment = run_and_assert(fn cursor ->
        UT.grip_fragment(para(template, cursor), at_roughly: original_range)
      end)


      0 |> judgment.({:ok, 3..5})
      1 |> judgment.(:error)
      7 |> judgment.(:error)
      8 |> judgment.({:ok, 3..5})
    end
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
end

