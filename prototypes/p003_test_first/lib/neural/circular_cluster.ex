defmodule AppAnimal.Neural.CircularCluster do
  defstruct [:name, :handle_pulse, downstream: []]

  def new(name, handle_pulse),
      do: %__MODULE__{name: name,
                      handle_pulse: handle_pulse}


  use GenServer

  def init(configuration) do
    {:ok, configuration}
  end

  def handle_call([switchboard: switchboard, handle_pulse: small_data], _from, configuration) do
    apply(configuration.handle_pulse, [switchboard, small_data])
    {:reply, 55, configuration}
  end
end
