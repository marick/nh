defmodule AppAnimal.ParagraphFocus.Perceptual.SummarizeEdges do
  use AppAnimal.ParagraphFocus
  use Neural.LinearCluster, switchboard: Switchboard
  use Neural.SummarizeEnvironment, environment: Environment
      
  def describe_summary(summary),
      do: Logger.info("edge structure: #{edge_string summary}")        
  
  def summarize(text), do: edge_structure(text)
  
  def edge_structure(string) do
    # Three passes over the string, whee!
    parts = decompose(string)
    labels = classify(parts)
    ranges = ranges(parts)

    List.zip([labels, ranges])
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


  def edge_string(structure) do
    classifier = fn
      {:text, _} -> "\u25A0"
      {:gap,  _} -> "_"
    end
    
    structure
    |> Enum.map(classifier)
    |> Enum.join
  end
end



