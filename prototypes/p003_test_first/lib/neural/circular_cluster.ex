defmodule AppAnimal.Neural.CircularCluster do
  defstruct [:name, :handlers, downstream: []]

  use GenServer

  def init(configuration) do
    {:ok, {configuration, configuration.handlers.initialize.(configuration)}}
  end

  def handle_cast([switchboard: switchboard, handle_pulse: small_data],
                  {configuration, state}) do
    new_state =
      apply(configuration.handlers.pulse, [switchboard, small_data, state])
    {:noreply, {configuration, new_state}}
  end
end
