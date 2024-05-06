defmodule AppAnimal.ClusterBuilders do
  use AppAnimal
  use KeyConceptAliases
  use MoveableAliases

  section "slightly more pleasant return values" do
    def no_pulse(next_state),          do: {:no_result, next_state}
    def pulse(pulse_data, next_state), do: {:useful_result, pulse_data, next_state}
    def pulse_and_save(data),          do: {:useful_result, data, data}
  end

  section "the two core functions: circular and linear" do

      @doc """
      Construct a circular cluster.

      The basic format is `circular(name, calc, opts)`. Either or both
      of `calc` and `opts` can be omitted.

      ## Options
      * `initial_value`: The starting value of the cluster's persistent state. (Default %{})
      * `label`:         Override the default label `circular`.
      * `id`:            A full `Identification` structure; otherwise calculated from the `label`.
      * `throb`:         A `Throb` structure
      """
    def circular(name, calc, opts) when is_function(calc) and is_list(opts) do
      opts
      |> Opts.rename(:initial_value, to: :previously)
      |> Opts.provide_default(previously: %{})
      |> Opts.provide_default(label: :circular,
                              throb: Throb.default)
      |> Opts.calculate_unless_given(:id, from: :label,
                                          using: & Cluster.Identification.new(name, &1))

      |> Opts.put_missing!(router: :must_be_supplied_later,
                           name: name,
                           calc: calc)

      |> then(& struct(Cluster.Circular, &1))
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
      * `throb`:         A `Throb` structure
      """
    def linear(name, calc, opts) when is_function(calc) and is_list(opts) do
      opts
      |> Opts.put_missing!(name: name, calc: calc)
      |> Opts.provide_default(label: :linear)
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

  ## Specializations

  def perception_edge(name) do
    linear(name, label: :perception_edge)
  end

  def action_edge(name) do
    linear(name, & System.Action.new(name, &1),
           label: :action_edge)
  end

  def summarizer(name, calc) do
    linear(name, calc, label: :summarizer)
  end


  def gate(name, predicate) do
    f = fn pulse_data ->
      if predicate.(pulse_data),
         do: pulse_data,
         else: :no_result
    end

    linear(name, f, label: :gate)
  end

  def forward_unique(name, opts \\ []) do
    alias Cluster.Throb

    effectively_a_uuid = :erlang.make_ref()

    throb = Throb.counting_down_from(Duration.frequent_glance,
                                     on_pulse: &Throb.pulse_increases_lifespan/2)

    updated_opts =
      opts
      |> Opts.provide_default(initial_value: effectively_a_uuid,
                              throb: throb)
      |> Opts.put_missing!(label: :forward_unique)

    calc = fn pulse_data, previously ->
      if pulse_data == previously,
         do: :no_result,
         else: pulse_and_save(pulse_data)
    end
    circular(name, calc, updated_opts)
  end

  def delay(name, duration) do
    throb = Throb.counting_up_to(duration,
                                 on_pulse: &Throb.pulse_zeroes_lifespan/2,
                                 before_stopping: &Throb.pulse_current_value/2)

    f_stash_pulse_data = fn pulse_data, _previously ->
      {:no_result, pulse_data}
    end

    circular(name, f_stash_pulse_data, throb: throb, label: :delay)
  end

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
