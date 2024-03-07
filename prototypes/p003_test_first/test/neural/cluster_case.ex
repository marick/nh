defmodule ClusterCase do
  use AppAnimal
  alias AppAnimal.Neural
  alias Neural.Cluster
  alias ExUnit.Assertions

  defmacro assert_test_receives(value, keys \\ [from: :endpoint]) do
    quote do 
      [retval, from: _] = Assertions.assert_receive([unquote(value) | unquote(keys)])
      retval
    end
  end

  def endpoint(name \\ :endpoint) do
    Cluster.linear(name, mkfn__exit_to_test())
  end

  private do
    def mkfn__exit_to_test() do
      test_pid = self()
      fn data, %{name: name} ->
        send(test_pid, [data, from: name])
        :ok
      end
    end
  end

  defmacro __using__(keys) do
    quote do
      use ExUnit.Case, unquote(keys)
      use AppAnimal
      alias AppAnimal.Neural
      alias Neural.Switchboard
      alias Neural.Affordances
      alias Neural.Network
      alias Neural.ActivityLogger
      alias Neural.Cluster
      import ClusterCase
      use FlowAssertions
    end
  end
end
