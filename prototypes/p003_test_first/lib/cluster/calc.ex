alias AppAnimal.Cluster

defmodule Cluster.Calc do
  @moduledoc """

  `Calc` is responsible for calling a cluster's "calc" function and
  normalizing or "assembling" the result.

  ### Inputs

  The `calc` function may take one or two arguments.

  In the one argument case, the argument is the `Pulse` the cluster
  just received. However, a `Pulse` of `:default` type has its `data`
  field extracted and sent in instead of the complete pulse. That
  means a simple cluster can use a function like `& &1+1` instead of
  having to unwrap the data itself.

  In the two-argument form, the first argument is the pulse, as
  described above (including unwrapping the `:default` case). The
  second argument is the value of the `previously` field in a
  `Cluster.Circular`. Note that this is not the entirety of the
  state.

  Since a linear cluster has no persistent state, it may not use the
  two-argument form. A circular cluster may use either form. The
  one-argument form is useful for a circular cluster when the state
  has no effect on the calculation and is not to be changed by it.

  ### Assembling the result

  A one-argument function should return one of these values:

  `:no_result`            - there is to be no outgoing pulse or action
  `Moveable.t`            - the result to be sent somewhere. Where depends on
                            the particular type implementing the `Moveable` protocol.

  As a convenience, any other value is wrapped in a :default Pulse.

  A two-argument function is more complicated because both outgoing
  data and changed state may be involved. `:no_result` is used to
  indicate that there will be no `Moveable` sent. There are two
  cases:

  :no_result                - no outgoing data, and the state is unchanged.
  {:no_result, Moveable.t}  - no outgoing data, and the state is changed.

  When there is to be a result, the canonical case is:

  {:useful_result, Moveable.t,  any} - the data is to be sent and the state is
                                       to be changed.

  As in the one-argument case, if the second argument does not implement `Moveable`,
  it is converted into a pulse of `:default` type:

  {:useful_result, any, any} = {:useful_result, Pulse.new(any), any}

  It is also valid to return a single value (Pulse.t, `Action.t`, or
  something else).  That signals that a pulse is to be sent but the
  state is to be left unchanged.

  """
  use AppAnimal
  use KeyConceptAliases
  use MoveableAliases

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

  ####

  @doc "If the tuple contains a useful result, use `Moveable.cast` to send it."
  def cast_useful_result(tuple, s_cluster,
                         # overridden in tests
                         f_send \\ &Moveable.cast/2) when is_tuple(tuple) do
    case elem(tuple, 0) do
      :no_result ->
        :do_nothing
      :useful_result ->
        pulse_data = elem(tuple, 1)
        f_send.(pulse_data, s_cluster)
    end
    tuple
  end

  @doc "Extract the next state from a `Calc` return tuple."
  def just_next_state({:useful_result, _pulse_data, next_state}), do: next_state
  def just_next_state({:no_result, next_state}), do: next_state

  private do
    # Like `just_next_state`, but not used exernally
    def pulse_or_pulse_data(%Pulse{type: :default} = pulse), do: pulse.data
    def pulse_or_pulse_data(%Pulse{              } = pulse), do: pulse


    def assemble_result(calc_result,                 :there_is_no_state) do
      case calc_result do
        :no_result -> {:no_result}
        untagged   -> {:useful_result, ensure_moveable(untagged)}
      end
    end

    def assemble_result(calc_result, previous_state, :state_does_not_change) do
      case calc_result do
        :no_result -> {:no_result,                                previous_state}
        untagged   -> {:useful_result, ensure_moveable(untagged), previous_state}
      end
    end

    def assemble_result(calc_result, previous_state, :state_may_change) do
      case calc_result do
         :no_result              -> {:no_result, previous_state}
        {:no_result, next_state} -> {:no_result, next_state}


        {:useful_result, tagged, next_state}
                                 -> {:useful_result, ensure_moveable(tagged),   next_state}
        untagged
                                 -> {:useful_result, ensure_moveable(untagged), previous_state}
      end
    end

    def ensure_moveable(data) do
      case Moveable.impl_for(data) do
        nil -> Pulse.new(data)
        _ -> data
      end
    end
  end
end
