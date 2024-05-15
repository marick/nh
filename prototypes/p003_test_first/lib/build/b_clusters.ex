defmodule AppAnimal.ClusterBuilders do
  @moduledoc """
  All the predefined cluster types.
  """

  use AppAnimal
  use KeyConceptAliases
  use MoveableAliases
  alias Cluster.Circular

  section "the two core functions: `circular` and `linear`" do

      @doc """
      Construct a circular cluster.

      The basic format is `circular(name, calc, opts)`. Either or both
      of `calc` and `opts` can be omitted.

      ## Options
      * `initial_value`:   The starting value of the cluster's persistent state. (Default %{})
      * `label`:   Override the default label `circular`.
      * `id`:   A full `Identification` structure; otherwise calculated from the `label`.
      * `throb`:  A `Throb` structure
      * `while_stopping`: A function called when the process is about to stop/exit.
      """
    def circular(name, calc, opts) when is_function(calc) and is_list(opts) do
      opts
      |> Opts.rename(:initial_value, to: :previously)
      |> Opts.rename(:while_stopping, to: :f_while_stopping)
      |> Opts.put_when_needed(previously: %{})
      |> Opts.put_when_needed(label: :circular,
                                         throb: Throb.default,
                                         f_while_stopping: &Circular.stop_silently/1)
      |> Opts.calculate_unless_given(:id, from: :label,
                                          using: & Cluster.Identification.new(name, &1))

      |> Opts.put_missing!(router: :must_be_supplied_later,
                           name: name,
                           calc: calc)

      |> then(& struct(Circular, &1))
    end

    def circular(name, calc     ) when is_function(calc),
        do: circular(name, calc, [])
    def circular(name,      opts) when is_list(opts),
        do: circular(name, &Function.identity/1, opts)

    def circular(name), do: circular(name, [])

    ##

      @doc """
      Construct a linear cluster.

      The basic format is `linear(name, calc, opts)`. Either or both
      of `calc` and `opts` can be omitted.

      ## Options
      * `label`:         Override the default label `linear`.
      * `id`:            A full `Identification` structure; otherwise calculated from the `label`.
      """
    def linear(name, calc, opts) when is_function(calc) and is_list(opts) do
      opts
      |> Opts.put_missing!(name: name, calc: calc)
      |> Opts.put_when_needed(label: :linear)
      |> Opts.calculate_unless_given(:id, from: :label,
                                          using: & Cluster.Identification.new(name, &1))

      |> then(& struct(Cluster.Linear, &1))
    end

    def linear(name, calc) when is_function(calc),
        do: linear(name, calc, [])

    def linear(name, opts) when is_list(opts),
        do: linear(name, &Function.identity/1, opts)

    def linear(name), do: linear(name, &Function.identity/1)
  end


  section "specializations of linear clusters" do

      @doc """
      Handle a pulse that represents an affordance.

      The affordance has the same name as the cluster. The pulse is
      sent on as-is.
      """
    def perception_edge(name) do
      linear(name, label: :perception_edge)
    end

      @doc """
      Send an action into Affordance Land.

      Whatever pulse the cluster receives is wrapped in the action.
      """
    def action_edge(name) do
      linear(name, & Action.new(name, &1),
             label: :action_edge)
    end

      @doc """
      Apply the given function to the received pulse.

      This is really no different than a `linear` cluster, but the `:summarizer` label
      might be useful as documentation of purpose.
      """
    def summarizer(name, calc) do
      linear(name, calc, label: :summarizer)
    end

      @doc """
      Forward data on, but only if the `predicate` is truthy.
      """
    def gate(name, predicate) do
      f = fn pulse_data ->
        if predicate.(pulse_data),
           do: pulse_data,
           else: no_result()
      end

      linear(name, f, label: :gate)
    end
  end

  section "specializations of circular structures" do

      @doc """
      Forward on only the first of a sequence of identical pulses.

      If enough time passes, the cluster will "age out". Thus it is
      possible for the downstream to receive duplicates, but only if
      they are separated by enough time (by default,
      `Duration.frequent_glance`).

      Each new pulses will extend the lifespan by one "throb
      interval", so frequent enough pulses will keep the cluster alive
      indefinitely.

      ## Options
      * `initial_value`: pretend that the cluster has already received a value.
      * `throb`: A `Throb` structure to override default behavior.
      """
    def forward_unique(name, opts \\ []) do
      alias Cluster.Throb

      effectively_a_uuid = :erlang.make_ref()

      throb = Throb.counting_down_from(Duration.frequent_glance,
                                       on_pulse: &Throb.pulse_increases_lifespan/1)

      updated_opts =
        opts
        |> Opts.put_when_needed(initial_value: effectively_a_uuid,
                                throb: throb)
        |> Opts.put_missing!(label: :forward_unique)

      calc = fn pulse_data, previously ->
        if pulse_data == previously,
           do: :no_result,
           else: pulse_and_save_same_value(pulse_data)
      end
      circular(name, calc, updated_opts)
    end

      @doc """
         Retain a value until pulses quiet down.

         The cluster is kept alive by pulses. When it finally ages out,
         it will send its initial value downstream.

         Note that the `:data` in later pulses is ignored. It's
         intended for use in cases where you want to forward on that
         something happened only once it stops happening.
      """
    def delay(name, duration) do
      throb = Throb.counting_up_to(duration,
                                   on_pulse: &Throb.pulse_zeroes_lifespan/1)

      f_stash_pulse_data = fn pulse_data, _previously ->
        {:no_result, pulse_data}
      end

      circular(name, f_stash_pulse_data,
               throb: throb,
               label: :delay,
               while_stopping: &Circular.pulse_saved_state/1)
    end

      @doc """
      Something notable has happened, and it's time to let in-progress work die out
      and request a new affordance.

      The cluster operates in two stages. When it starts, it sends a `Pulse.suppress`
      to downstream clusters and waits for a time.

      When the time has elapsed, an `Action` is sent into Affordance Land. This action
      contains the data from the pulse that prompted this circular cluster to start work.

      I haven't decided what should happen if a second pulse arrives before the movement
      is completed.

      ## Options

      * `movement_time` (required): The time to delay. Think of this as the time it takes
        for the eyeball to shift over to something new.

      * `action_type` (required): The name of the action to be sent. Its `:data` will be
        the data of whatever pulse started
      """
    def focus_shift(name, opts) do
      [movement_time, action_to_take] =
        Opts.required!(opts, [:movement_time, :action_type])

      # This is somewhat awkward. Because of how `Pulse` default structs are stripped
      # down to their data before sent to the `calc` function, the function clause
      # that's first to be exercised has to be listed second.
      calc = fn
        %Pulse{type: :movement_finished, data: focus_on} ->
          Action.new(action_to_take, focus_on)
        focus_on ->
          Moveable.Collection.new([
            Pulse.suppress,
            Delay.new(movement_time, Pulse.new(:movement_finished, focus_on))])
      end

      circular(name, calc, label: :focus_shift)
    end
  end

  section "helper functions for writing `calc` functions" do
    def no_result,                       do: :no_result
    # Maybe more clear for circular cluster:
    def pulse_ignored,                   do: :no_result
    def no_pulse(next_state),            do: {:no_result,                 next_state}
    def pulse(pulse_data, next_state),   do: {:useful_result, pulse_data, next_state}
    def pulse_and_save_same_value(data), do: {:useful_result, data,       data}
  end
end
