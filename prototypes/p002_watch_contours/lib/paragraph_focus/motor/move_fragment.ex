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

    def new_end(_text, _original_start.._original_end) do
    end

    # Note: do_not_exceed is actually off by one, but that's irrelevant
    # given the need for two newlines past the search bounds.
    def allowed_range(original_start..original_end = range, do_not_exceed) do
      distance = div(Range.size(range), 2) + 2 # we need enough to recognize the gap
      left = max(0, original_start - distance)
      right = min(original_end + distance, do_not_exceed)
      left..right
    end

    def surrounding_gaps(text, bounds) do
      substring = String.slice(text, bounds)
      case Regex.scan(~r/\n\n+/, substring, return: :index) do
        [[first_gap], [second_gap]] -> 
          tuple_to_range = fn {start, length} -> start..(start+length-1) end
          translate = fn in_substring_coordinates ->
            translation = Enum.at(bounds, 0)
            Range.shift(in_substring_coordinates, translation)
          end
          
          {:ok,
           tuple_to_range.(first_gap) |> translate.(),
           tuple_to_range.(second_gap) |> translate.()
          }
      _ ->
        :error
      end
    end

    def no_obvious_edits(paragraph, original_range, discovered_range) do
      spread_range_to_include_newlines = fn first..last ->
        first-2..last+2
      end
      wider = spread_range_to_include_newlines.(discovered_range)

      cond do
        Range.size(original_range) != Range.size(discovered_range) ->
          :error
        Enum.member?(wider, paragraph.cursor) ->
          :error
        true ->
          :ok
      end
    end

    def grip_fragment(%{text: text} = paragraph, at_roughly: original_range) do
      bounds = allowed_range(original_range, String.length(text))

      with(
        {:ok, _..end_of_gap1, start_of_gap_2.._} <- surrounding_gaps(text, bounds),
        discovered_range = (end_of_gap1+1)..(start_of_gap_2-1),
        :ok <- no_obvious_edits(paragraph, original_range, discovered_range)
      ) do 
        {:ok, discovered_range}
      else
        :error ->
          :error
      end
    end

    # def fragment_range_within_bounds(text, bounds) do
    # end

    # def grab_fragment(paragraph, at_roughly: range) do
    #   with(
    #     {:ok, first_text..last_text} <- accounting_for_edits(paragraph.text, range),
    #     :safely_distant <- cursor_relationship(paragraph, first_text..last_text)
    #   ) do 
    #     {:ok, split_text(paragraph.text, at_exactly: {first_text-1, last_text+1})}
    #   else
    #     _ -> :error
    #   end
    # end
    
    # def cursor_relationship(paragraph, lower_fragment_bound..upper_fragment_bound) do
    #   if paragraph.cursor < lower_fragment_bound - 1
    #      || paragraph.cursor > upper_fragment_bound + 2 do
    #     :safely_distant
    #   else
    #     :too_close
    #   end
    # end

    # @max_tries 4   # tries includes the initial try with no shift.
    # def accounting_for_edits(paragraph, range) do
    #   perhaps_shift(paragraph, range, @max_tries)
    # end

    # def perhaps_shift(_paragraph, _range, 0), do: :error
    
    # def perhaps_shift(paragraph, first..last, remaining_shifts) do
    #   include_buffer = (first-3)..(last+1)
    #   with_buffer = String.slice(paragraph, include_buffer)
    #   if Regex.match?(~r/\n\n[^\n]+\n\n/, with_buffer) do
    #     {:ok, first..last}
    #   else
    #     perhaps_shift(paragraph, (first+1)..(last+1), remaining_shifts - 1)
    #   end
    # end

    # def split_text(text, at_exactly: {first, last}) do
    #   {prefix, remainder} = String.split_at(text, first-1)
    #   {fragment, suffix} = String.split_at(remainder, last-first+1)
    #   [prefix, fragment, suffix]
    # end
  end
end
