defmodule AppAnimal.Neural.LinearCluster do
  use AppAnimal

  defstruct [:name,
             :handlers,
             downstream: [],
             send_pulse_downstream: :installed_by_switchboard]


  def send_downstream(after: calc) when is_function(calc, 1) do
    fn pulse_data, configuration ->
      configuration.send_pulse_downstream.(carrying: calc.(pulse_data))
      :there_is_never_a_meaningful_return_value
    end
  end
end
