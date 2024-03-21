alias AppAnimal.Cluster
alias Cluster.Shape

defprotocol Shape do
  @spec can_throb?(Shape.t) :: boolean
  def can_throb?(shape)

  @spec accept_pulse(Shape.t, Cluster.t, pid, any) :: no_return
    def accept_pulse(s_shape, cluster, pid, pulse_data)
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
  def can_throb?(_s_shape), do: true

  def accept_pulse(_s_shape, _cluster, destination_pid, pulse_data) do
    GenServer.cast(destination_pid, [handle_pulse: pulse_data])
  end
end

## 

defmodule Shape.Linear do
  defstruct [] # This is just to create the type. 
  
  def new(opts \\ []), do: struct(__MODULE__, opts)
end

defimpl Shape, for: Shape.Linear do
  alias Cluster.Calc
  
  def can_throb?(_s_shape), do: false

  def accept_pulse(_s_shape, cluster, _destination_pid, pulse_data) do
    Task.start(fn ->
      Calc.run(cluster.calc, on: pulse_data)
      |> Calc.maybe_pulse(& Cluster.send_pulse(cluster, &1))
      :there_is_no_return_value
    end)
  end    
end
