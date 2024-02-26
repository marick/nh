defmodule AppAnimal.Neural.CircularCluster do
  defstruct [:name, :handlers, downstream: []]

  use GenServer

  def init(configuration) do
    {:ok, {configuration, configuration.handlers.initialize.(configured_by: configuration)}}
  end

  def handle_cast([switchboard: switchboard, handle_pulse: small_data],
                  {configuration, state}) do
    # IO.inspect configuration.handlers.pulse
    new_state =
      apply(configuration.handlers.pulse,
            [[switchboard: switchboard, carrying: small_data, mutable: state]])
    {:noreply, {configuration, new_state}}
  end
end
