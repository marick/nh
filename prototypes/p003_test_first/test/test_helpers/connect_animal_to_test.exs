alias AppAnimal.TestHelpers

defmodule TestHelpers.ConnectAnimalToTest do
  use AppAnimal
  alias AppAnimal.ClusterBuilders, as: C
  alias ExUnit.Assertions

  def forward_to_test(name \\ :endpoint) do
    p_test = self()

    # Normally, a pulse is sent *after* calculation. Here, we have the
    # cluster not calculate anything but just send to the test pid.
    # That's because the `System.Router` only knows how to do GenServer-type
    # casting, which is not compatible with `assert_receive`
    kludge_a_calc = fn arg ->
      send(p_test, [arg, from: name])
      :no_result
    end

    C.linear(name, kludge_a_calc, label: :test_endpoint)
  end

  @doc "Receive a pulse from a `to_test` node"
  defmacro assert_test_receives(value, opts \\ [from: :endpoint]) do
    quote do
      [retval, from: _] = Assertions.assert_receive([unquote(value) | unquote(opts)])
      retval
    end
  end

end
