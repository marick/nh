defmodule AppAnimal.Neural.CircularCluster do
  defstruct [:name, :handlers, downstream: [], send_pulse_downstream: :installed_by_switchboard]

  use GenServer

  def init(configuration) do
    {:ok, {configuration, configuration.handlers.initialize.(configuration)}}
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
