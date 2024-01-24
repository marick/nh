defmodule AppAnimal.ParagraphFocus.Perceptual.EdgeDetection do
  use Private
  require Logger
  alias AppAnimal.WithoutReply
  alias AppAnimal.ParagraphFocus.{Environment, Control}
      
  @mechanism :flow_emulator
  @upstream  Environment
  @downstream [Control.AttendToEditing, Control.AttendToFragments]

  def describe() do
    "#{inspect @mechanism} #{__MODULE__} queries #{inspect @upstream}, " <>
      "sends to #{inspect @downstream}"
  end

  def activate() do
    result = GenServer.call(@upstream, {:run_for_result, &edge_structure/1})
    Logger.info("edge structure: #{inspect result}")
    Enum.map(@downstream, fn receiver ->
      WithoutReply.activate(receiver, on_one: result)
    end)
  end
  
  def edge_structure(string) do
    # I could do this with streams if I cared about efficiency
    parts = decompose(string)
    labels = classify(parts)
    ranges = ranges(parts)

    List.zip([labels, ranges])
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
end



