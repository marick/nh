defmodule ClusterCase do
  use AppAnimal
  alias AppAnimal.{System, Cluster}
  alias Cluster.Shape
  alias ExUnit.Assertions

  defmacro assert_test_receives(value, opts \\ [from: :endpoint]) do
    quote do 
      [retval, from: _] = Assertions.assert_receive([unquote(value) | unquote(opts)])
      retval
    end
  end

  # The stripping out of `carrying` is a hack because of old behavior.
  def to_test(name \\ :endpoint) do
    filter =
      fn
        [carrying: pulse] -> pulse
        pulse -> pulse
      end

    p_test = self()
    f_outward = fn pulse_data ->
      send(p_test, [pulse_data, from: name])
    end
      
    %Cluster{name: name,
             label: :test_endpoint,
             shape: Shape.Linear.new,
             calc: filter,
             f_outward: f_outward}
  end

  def send_test_pulse(p_switchboard, to: destination_name, carrying: pulse_data) do
    GenServer.cast(p_switchboard,
                   {:distribute_pulse, carrying: pulse_data, to: [destination_name]})
  end

  # About programming affordances

  def response_to(action, response), do: {action, response}
  def affords([{name, data}]), do: {name, data}

  def script(pid, list) do
    GenServer.cast(pid, [script: list])
    pid
  end
  
  def note_action(pid, [{_name, _data}] = action) do
    GenServer.cast(pid, [:note_action, action])
  end
  


  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
      use AppAnimal
      alias AppAnimal.System
      alias System.Switchboard
      alias System.AffordanceLand
      alias System.Network
      alias System.ActivityLogger
      import ClusterCase
      import AppAnimal.TraceAssertions
      use FlowAssertions
      import Cluster.Make
      import Network.Make
    end
  end
end
