alias AppAnimal.{Network,NetworkBuilder}

defmodule NetworkBuilder do

  use AppAnimal
  use AppAnimal.GenServer
  alias NetworkBuilder.Guts, as: Guts

  runs_in_sender do
    def start_link(_), do: GenServer.start_link(__MODULE__, Network.empty)

    def network(pid), do: GenServer.call(pid, :get_network)
    def trace(pid, list) do
      GenServer.call(pid, {:apply, :trace, [list]})
      pid
    end

    def branch(pid, opts) do
      [branch_point, trace] = Opts.required!(opts, [:at, :with])
      trace(pid, [branch_point | trace])
    end

    def unordered(pid, list) when is_list(list) do
      GenServer.call(pid, {:apply, :unordered, [list]})
      pid
    end

    def cluster(pid, cluster) when is_struct(cluster),
        do: unordered(pid, [cluster])
    def install_routers(pid, router),
        do: GenServer.call(pid, {:apply, :install_routers, [router]})
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
