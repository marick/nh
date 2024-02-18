defmodule AppAnimal.ParagraphFocus.Control.AttendToEditing do
  use AppAnimal.ParagraphFocus
  use Neural.Summarizer, switchboard: Switchboard
  import Control.Util, only: [text_count: 1]

  @impl true
  def summarize(edges) do
    if text_count(edges) > 1,
       do: :big_edit,
       else: :plain_edit
  end
  
  @impl true
  def describe_transformation(upstream_data, summary) do
    string = Perceptual.EdgeSummarizer.edge_string(upstream_data)
    Logger.info("#{string} produces `#{inspect summary}`")
  end
end

