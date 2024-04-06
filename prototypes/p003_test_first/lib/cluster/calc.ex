alias AppAnimal.{Cluster,System}
alias Cluster.Calc

defmodule Calc do
  @moduledoc """

  `Calc` is responsible for calling a clusters "calc" function and
  normalizing or "assembling" the result.

  ### Inputs

  The function may take one or two arguments.

  In the one argument case, the argument is the `Pulse` the cluster
  just received. However, a `Pulse` of `:default` type has its `data`
  field extracted and sent in instead of the complete pulse. That
  means a simple cluster can use a function like `& &1+1` instead of
  having to unwrap the data itself.

  In the two-argument form, the first argument is the pulse, as
  described above (including unwrapping the `:default` case). The
  second argument is the value of the `previously` field in a
  `CircularProcess.State`. Note that this is not the entirety of the
  state.

  Since a linear cluster has no persistent state, it may not use the
  two-argument form. A circular cluster may use either form. The
  one-argument form is useful for a circular cluster when the state
  has no effect on the calculation and is not to be changed by it.

  ### Assembling the result
  
  In the case of a one-argument function, the two canonical return
  values are:

  `:no_pulse`             - there is to be no outgoing pulse
  `{:pulse, Pulse.t}`     - the pulse is to be sent downstream.

  As a convenience, if the second tuple argument is *not* of type
  `Pulse.t`, it is converted into a pulse of the `:default` type.

  A two-argument function is more complicated because both an outgoing
  pulse and changed state may be involved. `:no_pulse` is used to
  indicate that there will be no pulse sent. There are two cases:

  :no_pulse              - no outgoing pulse, and the state is unchanged.
  {:no_pulse, any}       - no outgoing pulse, and the state is changed.

  When there is to be a pulse, the canonical case is:

  {:pulse, Pulse.t, any} - the pulse is to be sent on and the state is
                           to be changed.

  As in the one-argument case, if the second argument is not a
  `Pulse.t`, it is converted into an argument of a pulse of `:default`
  type.

  It is also valid to return a single value (Pulse.t or something else).
  That signals that a pulse is to be sent but the state is to be left
  unchanged. 
  
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
