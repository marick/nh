defmodule AppAnimal.Neural.Cluster do
  alias AppAnimal.Neural

  def circular(name, mutable_initializer, handle_pulse, keys \\ []) do
    handlers = %{
      pulse: handle_pulse,
      initialize: mutable_initializer
    }

    full_keyset =
      Keyword.merge(keys, name: name, handlers: handlers)

    struct(Neural.CircularCluster, full_keyset)
  end

  # This is a very abbreviated version, mainly for tests.
  def circular(name, handle_pulse) when is_function(handle_pulse) do
    circular(name, fn _configuration -> %{} end, handle_pulse)
  end

  def linear(name, handle_pulse) when is_function(handle_pulse) do
    %Neural.LinearCluster{name: name, handlers: %{handle_pulse: handle_pulse}}
  end

  def linear(name, calc: f) do
    linear(name, Neural.LinearCluster.send_downstream(after: f))
  end

  def affordance(name) do
    %Neural.Affordance{name: name}
  end
 end
