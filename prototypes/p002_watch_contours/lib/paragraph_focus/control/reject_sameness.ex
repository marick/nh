defmodule AppAnimal.ParagraphFocus.Control.RejectSameness do
  use AppAnimal.ParagraphFocus
  use Neural.CircularCluster, switchboard: Switchboard
  
  def init(small_data) do
    activate_downstream(small_data)
    Process.send_after(self(), :tick, 400)
    {:ok, small_data}
  end

  def handle_info(:tick, state) do
    {:stop, :normal, state}
  end  
end

