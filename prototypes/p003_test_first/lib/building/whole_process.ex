alias AppAnimal.{Building,Network}
alias Building.Whole

defmodule Whole.Process do

  use AppAnimal
  use AppAnimal.GenServer
  alias Building.Whole.Guts, as: Guts

  runs_in_sender do
    def start_link(_), do: GenServer.start_link(__MODULE__, Network.empty)

    def network(pid), do: GenServer.call(pid, :get_network)
    def trace(pid, list), do: GenServer.call(pid, {:apply, :trace, [list]})
    def unordered(pid, list), do: GenServer.call(pid, {:apply, :unordered, [list]})
  end

  runs_in_receiver do
    def init(network), do: ok(network)

    def handle_call(:get_network, _from, s_network),
        do: continue(s_network, returning: s_network)

    def handle_call({:apply, fun_name, rest_args}, _from, s_network) do
      mutated = apply(Guts, fun_name, [s_network | rest_args])
      continue(mutated, returning: :ok)
    end

    unexpected_call()
  end
end
