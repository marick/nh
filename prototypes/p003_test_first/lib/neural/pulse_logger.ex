defmodule AppAnimal.Neural.PulseLogger do
  use AppAnimal
  use Agent

  def start(buffer_size \\ 100) do
    Logger.put_module_level(__MODULE__, :info)
    Agent.start_link(fn ->  CircularBuffer.new(buffer_size) end, name: __MODULE__)
  end
    

  def log(%{type: type, name: name} = cluster, pulse_data) do
    Logger.debug(inspect(pulse_data), cluster: {type, name})
    Agent.update(__MODULE__, & CircularBuffer.insert(&1, {cluster, pulse_data}))
  end
end



# defmodule Counter do
#   use Agent

#   def value do
#     Agent.get(__MODULE__, & &1)
#   end

#   def increment do
#     Agent.update(__MODULE__, &(&1 + 1))
#   end
# end

