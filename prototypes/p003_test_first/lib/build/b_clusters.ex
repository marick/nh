alias AppAnimal.{ClusterBuilders,System}

defmodule ClusterBuilders do
  use AppAnimal
  alias Cluster.Throb

  def no_pulse(next_state),          do: {:no_result, next_state}
  def pulse(pulse_data, next_state), do: {:useful_result, pulse_data, next_state}
  def pulse_and_save(data),          do: {:useful_result, data, data}

  def circular(name, calc, opts) when is_function(calc) and is_list(opts) do
    opts
    |> Opts.rename(:initial_value, to: :previously)
    |> Opts.add_missing!(name: name, calc: calc)
    |> Opts.add_missing!(id: Cluster.Identification.new(name, :circular))
    |> Opts.add_if_missing(label: :circular,
                           throb: Throb.default,
                           previously: %{})
    |> Opts.add_missing!(router: :must_be_supplied_later)
    |> then(& struct(Cluster.Circular, &1))

  end

  def circular(name, calc     ) when is_function(calc),
      do: circular(name, calc, [])
  def circular(name,      opts) when is_list(opts),
      do: circular(name, &Function.identity/1, opts)

  def circular(name), do: circular(name, [])

  ##

  def linear(name, calc, opts) when is_function(calc) and is_list(opts) do
    opts
    |> Opts.add_missing!(name: name, calc: calc)
    |> Opts.create(       :id, if_present: :label,
                               with: & Cluster.Identification.new(name, &1))
    |> Opts.add_if_missing(id: Cluster.Identification.new(name, :linear))

    |> then(& struct(Cluster.Linear, &1))
  end

  def linear(name, calc) when is_function(calc),
      do: linear(name, calc, [])

  def linear(name, opts) when is_list(opts),
      do: linear(name, &Function.identity/1, opts)

  def linear(name), do: linear(name, &Function.identity/1)


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
      |> Opts.add_if_missing(initial_value: effectively_a_uuid,
                             throb: throb)
      |> Opts.add_missing!(label: :forward_unique)

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

    circular(name, f_stash_pulse_data, throb: throb)
  end



end
