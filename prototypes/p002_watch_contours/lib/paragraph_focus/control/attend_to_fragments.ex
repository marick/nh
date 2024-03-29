defmodule AppAnimal.ParagraphFocus.Control.AttendToFragments do
  use AppAnimal.ParagraphFocus
  use Neural.LinearCluster, switchboard: Switchboard
  use Neural.Gate

  import Perceptual.SummarizeEdges, only: [edge_string: 1]
  import Control.Util, only: [text_count: 1]

  private do 
    def has_fragments?(edges) do
      text_count(edges) > 2
    end

    def first_fragment_range(edges) do
      edges
      |> Enum.filter(fn {key, _} -> key == :text end)
      |> Enum.at(1)
    end
  end

  # boilerplate

  @impl true
  def description_of_check(edges) do
    "are there fragments in #{edge_string edges}?"
  end

  @impl true
  def should_send_pulse?(edges), do: has_fragments?(edges)
  @impl true
  def outgoing_data(edges), do: first_fragment_range(edges)
end
  




