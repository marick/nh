alias AppAnimal.Perceptions

defmodule Perceptions.ParagraphGaps do
  use AppAnimal

  def describe_summary(summary),
      do: Logger.info("gap structure: #{gap_string summary}")

  def summarize(text), do: gap_structure(text)

  def gap_structure(string) do
    # Three passes over the string, whee!
    parts = decompose(string)
    labels = classify(parts)
    ranges = ranges(parts)

    List.zip([labels, ranges])
  end

  def gap_count(summarized) do
    Keyword.get_values(summarized, :gap) |> length
  end

  private do
    @gap_definition ~r/\n\n+/

    def decompose(string) do
      string
      |> String.split(@gap_definition, include_captures: true)
      |> Enum.reject(&(&1 == ""))
    end

    def classify(decomposed_string) do
      Enum.map(decomposed_string, fn snippet ->
        if String.match?(snippet, @gap_definition) do
          :gap
        else
          :text
        end
      end)
    end

    def ranges(decomposed_string) do
      reducer = fn string, {next_start, ranges} ->
        length = String.length(string)
        next_next_start = next_start + length
        range = next_start..(next_start+length-1)
        {next_next_start, [range | ranges]}
      end

      decomposed_string
      |> Enum.reduce({0, []}, reducer)
      |> elem(1)
      |> Enum.reverse
    end
  end


  def gap_string(structure) do
    classifier = fn
      {:text, _} -> "\u25A0"
      {:gap,  _} -> "_"
    end

    structure
    |> Enum.map(classifier)
    |> Enum.join
  end
end
