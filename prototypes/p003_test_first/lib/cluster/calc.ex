alias AppAnimal.{Cluster,System}
alias Cluster.Calc

defmodule Calc do
  @moduledoc """

  Each cluster surrounds a function. It's convenient to describe linear and
  circular clusters separately.

  ### Linear clusters (tasks)

  The function must take a single argument. The canonical two return values are

  For linear clusters:
  `{:no_pulse}`           - there is to be no outgoing pulse
  `{:pulse, pulse_data}`  - the data is to be sent on.

  As a convenience, these two kinds of result are translated into one of the above:

  `:no_pulse`             - `{:no_pulse}`
  any other result        - `{:pulse, pulse_data}`

  ### Circular clusters

  The function may take either one or two argumnets. If one, it's the
  pulse data. If two, the second argument is the current value of the
  mutable state (*not* an entire cluster structure).

  For a single-argument function, the mutable state is left
  unchanged. These are the two kinds of return value:

  `:no_pulse`            - there is to be no outgoing pulse
  any other result       - the data is to be sent on.

  For a two-argument function, the two canonical return values are:

  `{:pulse, pulse_data, next_state}`  - the data is to be sent on and the state updated.
  `{:no_pulse,          next_state}`  - the cluster produces no pulse, but the state is updated.
  
  For convenience, the following two forms are also used:

  `:no_pulse`            - there is no pulse and the state is left unchanged
  any other value        - the value is sent in a pulse, but the state is left unchanged.        

  """
  use AppAnimal
  alias System.Pulse

  def run(calc, on: %Pulse{} = pulse, with_state: previously) when is_function(calc, 1) do
    pulse_or_pulse_data(pulse)
    |> calc.()
    |> assemble_result(previously,    :state_does_not_change)
  end

  def run(calc, on: %Pulse{} = pulse, with_state: previously) when is_function(calc, 2) do
    pulse_or_pulse_data(pulse)
    |> calc.(previously)
    |> assemble_result(previously,    :state_may_change)
  end

  def run(calc, on: %Pulse{} = pulse                        ) when is_function(calc, 1) do
    pulse_or_pulse_data(pulse)
    |> calc.()
    |> assemble_result(               :there_is_no_state)
  end
  
  private do
    def pulse_or_pulse_data(%Pulse{type: :default} = pulse), do: pulse.data
    def pulse_or_pulse_data(%Pulse{              } = pulse), do: pulse

    def assemble_result(calc_result, previous_state, :state_does_not_change) do
      case calc_result do 
        :no_pulse        -> {:no_pulse,                       previous_state}
        %Pulse{} = pulse -> {:pulse,    pulse,                previous_state}
        raw_data         -> {:pulse,    Pulse.new(raw_data),  previous_state}
      end
    end

    def assemble_result(calc_result, previous_state, :state_may_change) do
      case calc_result do
         :no_pulse              ->  {:no_pulse, previous_state}
        {:no_pulse, next_state} ->  {:no_pulse, next_state}
        
        {:pulse, %Pulse{} = pulse, next_state} -> {:pulse, pulse,               next_state}
        {:pulse, raw_data,         next_state} -> {:pulse, Pulse.new(raw_data), next_state}
                 raw_data                      -> {:pulse, Pulse.new(raw_data), previous_state}
      end
    end

    def assemble_result(calc_result,                 :there_is_no_state) do 
      case calc_result do
        :no_pulse        -> {:no_pulse}
        %Pulse{} = pulse -> {:pulse, pulse}
        raw_data         -> {:pulse, Pulse.new(raw_data)}
      end
    end
  end

  ####

  @doc "Use `f_send_pulse` to send pulse data iff the `tuple` argument so indicates."
  def maybe_pulse(tuple, f_send_pulse) when is_tuple(tuple) do
    case elem(tuple, 0) do
      :no_pulse ->
        :do_nothing
      :pulse -> 
        pulse_data = elem(tuple, 1)
        f_send_pulse.(pulse_data)
    end
    tuple
  end

  def next_state({:pulse, _pulse_data, next_state}), do: next_state
  def next_state({:no_pulse, next_state}), do: next_state
end
