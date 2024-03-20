alias AppAnimal.Cluster
alias Cluster.Calc

defmodule Calc do

  def run(calc, on: pulse_data, with_state: process_state) when is_function(calc, 1) do
    case calc.(pulse_data) do 
      :no_pulse ->
        {:no_pulse, process_state}
      result -> 
        {:pulse, result, process_state}
    end
  end

  def run(calc, on: pulse_data, with_state: process_state) when is_function(calc, 2) do
    case calc.(pulse_data, process_state) do
      {:pulse, _, _} = verbatim ->
        verbatim
      {:no_pulse, _} = verbatim ->
        verbatim
      :no_pulse ->
        {:no_pulse, process_state}
      singleton_result ->
        {:pulse, singleton_result, process_state}
    end
  end

  def run(calc, on: pulse_data) do
    case calc.(pulse_data) do
      :no_pulse ->
        {:no_pulse}
      singleton_result ->
        {:pulse, singleton_result}
    end
  end


  def maybe_pulse(tuple, pulser) when is_tuple(tuple) do
    case elem(tuple, 0) do
      :no_pulse ->
        :do_nothing
      :pulse -> 
        pulse_data = elem(tuple, 1)
        pulser.(pulse_data)
    end
    tuple
  end

  def next_state({:pulse, _pulse_data, next_state}), do: next_state
  def next_state({:no_pulse, next_state}), do: next_state
end
