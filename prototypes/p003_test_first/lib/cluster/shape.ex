alias AppAnimal.Cluster
alias Cluster.Shape

defprotocol Shape do
  @spec can_be_active?(Shape.t) :: boolean
  def can_be_active?(shape)

  @spec accept_pulse(struct, Cluster.t, pid, any) :: no_return
    def accept_pulse(struct, cluster, pid, pulse_data)
end

##


defmodule Shape.Circular do
  use TypedStruct

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :starting_pulses, integer, default: 20
    field :initial_value, any, default: %{}
  end
  
  def new(opts \\ []), do: struct(__MODULE__, opts)
end

defimpl Shape, for: Shape.Circular do
  def can_be_active?(_struct), do: true

  def accept_pulse(_struct, _cluster, destination_pid, pulse_data) do
    GenServer.cast(destination_pid, [handle_pulse: pulse_data])
  end
end

## 

defmodule Shape.Linear do
  defstruct [:dummy]
  
  def new(opts \\ []), do: struct(__MODULE__, opts)
  
end

defimpl Shape, for: Shape.Linear do
  alias Cluster.PulseLogic
  
  def can_be_active?(_struct), do: false

  def accept_pulse(_struct, cluster, _destination_pid, pulse_data) do
    Task.start(fn ->
      outgoing_data = cluster.calc.(pulse_data)
      PulseLogic.send_pulse(cluster.pulse_logic, outgoing_data)
    end)
  end    
end
