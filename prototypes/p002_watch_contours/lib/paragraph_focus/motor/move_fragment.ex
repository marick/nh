defmodule AppAnimal.ParagraphFocus.Motor.MoveFragment do
  alias AppAnimal.ParagraphFocus.{Environment, Control}
  alias AppAnimal.WithoutReply
  require Logger
  use Private

  @summary %{mechanism: :mover,
             upstream: Control.AttendToFragments,
             downstream: Environment
   }

  def activate({:text, original_fragment_range}) do
    Logger.info("will remove fragment originally at #{inspect original_fragment_range}")

    [@summary, WithoutReply] # go keep from warning about unused aliases.
  end

  def make_paragraph_transformer(original_fragment_range) do
    fn paragraph ->
      with(
        {:ok, _range_to_lift} <-
          grip_fragment(paragraph, at_roughly: original_fragment_range)
        
      ) do
        paragraph
      else
        :error ->
          paragraph
      end
    end
  end

  private do   # the key functions

    # A fragment is gripped if
    # 1. it has not moved too far due to editing in the text before it.
    # 2. there is exactly one fragment within the allowed bounds (search range)
    # 3. it doesn't seem to have been edited (same length as before, does not contain cursor)
    #
    # This is fiddly because of
    # 1. wanting to use start..end ranges but needing a Regex function that returns
    #    (start, length) tuples. Feh.
    # 2. The need to translate from the "coordinate system" of the searchable substring
    #    to the larger containing text. So a `Regex.scan` might locate a gap
    #    at position 5 in the substring, which might correspond to position 55 in the
    #    whole paragraph's text.

    def grip_fragment(%{text: text} = paragraph, at_roughly: original_range) do
      bounds = allowed_range(original_range, String.length(text))

      with(
        {:ok, _..end_of_gap1, start_of_gap2.._} <- two_gaps_within(text, obeying: bounds),
        discovered_range = (end_of_gap1+1)..(start_of_gap2-1),
        :ok <- no_obvious_edits(paragraph, original_range, discovered_range)
      ) do 
        {:ok, discovered_range}
      else
        :error ->
          :error
      end
    end

    def extract_fragment(paragraph, at: fragment_first..fragment_last) do
      first_split_point = fragment_first-1
      second_split_point = fragment_last+2
      
      {shorter, suffix} = String.split_at(paragraph.text, second_split_point)
      {prefix, fragment} = String.split_at(shorter, first_split_point)
      new_text = prefix <> suffix

      cursor = paragraph.cursor
      new_cursor = if cursor <= first_split_point,
                      do: cursor,
                      else: cursor - String.length(fragment)

      {
        %{paragraph | text: new_text, cursor: new_cursor},
        fragment
      }
    end
  end
  
  private do
    # Helpers

    def two_gaps_within(text, obeying: bounds) do
      substring = String.slice(text, bounds)
      case Regex.scan(~r/\n\n+/, substring, return: :index) do
        [[first_gap], [second_gap]] -> 
          tuple_to_range =
            fn {start, length} -> start..(start+length-1) end
          translate =
            fn in_substring_coordinates ->
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

    # Note: do_not_exceed is actually off by one, but that's irrelevant
    # given the need for two newlines past the search bounds.
    def allowed_range(original_start..original_end = range, do_not_exceed) do
      distance = div(Range.size(range), 2) + 2 # we need enough to recognize the gap
      left = max(0, original_start - distance)
      right = min(original_end + distance, do_not_exceed)
      left..right
    end
  end
end
