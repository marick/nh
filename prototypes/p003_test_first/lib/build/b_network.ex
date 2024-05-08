defmodule AppAnimal.NetworkBuilder do
    @moduledoc """
    A process that makes it more convenient to build a `Network`.

    In scenario tests, it's frequently clearer to interleave
    descriptions of part of a network with descriptions of, say, how
    Affordance Land will respond to an action. Using this builder
    process lets that happen without piping or intermediate variables
    that clutter up a scenario description.

    As a general rule, functions may take either a cluster struct or a
    name (atom).  An atom refers to a cluster that has already been
    created in the growing network. The same cluster may not appear
    twice; later references must use its name. (This is dubious: it
    might be better to allow repeated clusters with a check that a
    later cluster with a given name is structurally identical to the
    first, "establishing", use.)

    In the function documentation, I'll refer to "a mix of clusters
    and names".
    """
    use AppAnimal
    use AppAnimal.StructServer
    alias AppAnimal.Network
    alias Network.Grow

  runs_in_sender do
      @doc :false
    def start_link(_), do: GenServer.start_link(__MODULE__, Network.empty)

      @doc :false
    def network(pid), do: GenServer.call(pid, :get_network)

      @doc """
      Describe one path through a network of clusters.

      The `list` argument is a mix of clusters and names. The first
      cluster will do whatever it does with its incoming pulse and
      send the result to the second, which will process it and send it
      to the third, etc.

      Note that the path needn't start at the "beginning" of a network. You could
      establish a trace from `:b` to `:c` and then later from `:a` to `:b`.

      ## Options
      * `for_pulse_type:` By default, a trace describes how `:default` `Pulses` propagate.
        Use this option to describe how other types of clusters propagate (since a cluster
        may send different pulses to different destinations).
      """
    def trace(pid, list, opts \\ []) do
      GenServer.call(pid, {:apply, :trace, [list, opts]})
      pid
    end

      @doc """
      Add another trace to a cluster.

      Consider this:

          trace(pid, [:a, :b, :c, :d]
          branch(pid, :at :b, with: [:c2, :d2, :e2])

      The result is that a pulse sent downstream from `:a` will be
      split at node `:b` and the results sent to both `:c` and `:c2` (and so downstream).
      """
    def branch(pid, opts) do
      [branch_point, trace] = Opts.required!(opts, [:at, :with])
      trace(pid, [branch_point | trace])
    end

      @doc """
      Establish the existence of a set of clusters.

      This merely puts notes in the network; it doesn't say anything about which pulses
      are sent downstream from any of those clusters.
      """
    def unordered(pid, list) when is_list(list) do
      GenServer.call(pid, {:apply, :unordered, [list]})
      pid
    end

      @doc """
      Establish the existence of a single cluster.

      Typically used to create a cluster that will be named in later
      `trace` etc. commands.
      """
    def cluster(pid, cluster) when is_struct(cluster),
        do: unordered(pid, [cluster])


      @doc """
      Describe N clusters that receive identical pulses from an "upstream" cluster.

      This:

          fan_out(pid, from: :b, to: [:b1, :b2]

      ... says that any pulse produced by `:b` will be sent to both `:b1` and `:b2`.
      """
    def fan_out(pid, opts) do
      GenServer.call(pid, {:apply, :fan_out, [opts]})
    end

    @doc :false
    def install_routers(pid, router),
        do: GenServer.call(pid, {:apply, :install_routers, [router]})
  end

  runs_in_receiver do
    def handle_call(:get_network, _from, s_network),
        do: continue(s_network, returning: s_network)

    def handle_call({:apply, fun_name, rest_args}, _from, s_network) do
      mutated = apply(Grow, fun_name, [s_network | rest_args])
      continue(mutated, returning: :ok)
    end

    unexpected_call()
  end
end
