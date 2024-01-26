defmodule AppAnimal.ParagraphFocus.Motor.MoveFragment do
  alias AppAnimal.ParagraphFocus.{Environment, Control}
  alias AppAnimal.WithoutReply
  require Logger
  use Private

  @summary %{mechanism: :mover,
             upstream: Control.AttendToFragments,
             downstream: Environment
   }

  def activate({:text, fragment_range}) do
    Logger.info("will remove fragment in range #{inspect fragment_range}")
    [@summary, WithoutReply] # go keep from warning about unused aliases.
  end

  private do 

    def grab_fragment(paragraph, at_roughly: range) do
      case accounting_for_edits(paragraph.text, range) do
        {:ok, first_text..last_text} ->
          {:ok, split_text(paragraph.text, at_exactly: {first_text-1, last_text+1})}
        :error ->
          :error
      end
    end
    
    @max_tries 4   # tries includes the initial try with no shift.
    def accounting_for_edits(paragraph, range) do
      perhaps_shift(paragraph, range, @max_tries)
    end

    def perhaps_shift(_paragraph, _range, 0), do: :error
    
    def perhaps_shift(paragraph, first..last, remaining_shifts) do
      include_buffer = (first-3)..(last+1)
      with_buffer = String.slice(paragraph, include_buffer)
      if Regex.match?(~r/\n\n[^\n]+\n\n/, with_buffer) do
        {:ok, first..last}
      else
        perhaps_shift(paragraph, (first+1)..(last+1), remaining_shifts - 1)
      end
    end

    def split_text(text, at_exactly: {first, last}) do
      {prefix, remainder} = String.split_at(text, first-1)
      {fragment, suffix} = String.split_at(remainder, last-first+1)
      [prefix, fragment, suffix]
    end
  end
end
