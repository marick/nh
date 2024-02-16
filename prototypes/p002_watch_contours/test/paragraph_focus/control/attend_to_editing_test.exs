defmodule AppAnimal.ParagraphFocus.AttendToEditing do
  use ExUnit.Case
  alias AppAnimal.ParagraphFocus.Perceptual.EdgeSummarizer
  alias AppAnimal.ParagraphFocus.Control.AttendToEditing, as: UT
  import FlowAssertions.TabularA

  test "determining if editing" do
    returns = run_and_assert(
        	&(EdgeSummarizer.edge_structure(&1) |> UT.summarize))

    "abc\n"         |> returns.(:plain_edit)
    "abc\n\ndef"    |> returns.(:big_edit)

    # A fragment is part of a big edit
    "abc\n\nfragment\n\ndef" |> returns.(:big_edit)

    # I'm not sure if it's possible for there to be leading or trailing blanks, but
    # it doesn't make a difference.
    "\n\nabc\n\ndef\n\n"    |> returns.(:big_edit)
  end
    
end

