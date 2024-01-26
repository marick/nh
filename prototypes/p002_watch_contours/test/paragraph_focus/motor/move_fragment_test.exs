defmodule AppAnimal.ParagraphFocus.MoveFragmentTest do
  use ExUnit.Case
  alias AppAnimal.ParagraphFocus.Motor.MoveFragment, as: UT
  import FlowAssertions.TabularA


  # test "determine fragment bounds" do
  #   originally_perceived = %{text: "123\n\n678\n\nbcd", cursor: 1}
  #   current = originally_perceived
  #   actual = UT.grab_fragment(current, at_roughly: 6..8)
  #   expected = {:ok, ["123\n", "\n678\n", "\nbcd"]}
  #   assert actual == expected
  # end

  test "possibly shifted" do
    returns = run_and_assert(&UT.accounting_for_edits/2)
    #"123\n\n678\n\nbcd"
    ["123\n\n678\n\nbcd", 6..8] |> returns.({:ok, 6..8})

    #"123\n\n678\n\nbcd"
    ["_123\n\n678\n\nbcd", 6..8] |> returns.({:ok, 7..9})  # We tolarate an added char in prefix
    # ^
    
    #"123\n\n678\n\nbcd"
    ["_123_\n\n678\n\nbcd", 6..8] |> returns.({:ok, 8..10}) # ... and two.
    
    #"123\n\n678\n\nbcd"
    ["_12_3_\n\n678\n\nbcd", 6..8] |> returns.({:ok, 9..11}) # ... and three


    # But four is too much of a change: the app_animal should wait.
    #"123\n\n678\n\nbcd"
    ["__12_3_\n\n678\n\nbcd", 6..8] |> returns.(:error)

  end
    
  

end

