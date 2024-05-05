defmodule AppAnimal.Scenario.ProcessKludgery do

  @network_builder :network_builder     # get warnings about typos
  def network_builder(), do: Process.get(@network_builder)
  def init_network_builder(v), do: Process.put(@network_builder, v)

  @affordance_thunks :affordance_thunks
  def init_affordance_thunks, do: Process.put(@affordance_thunks, [])
  def affordance_thunks, do: Process.get(@affordance_thunks)
  def append_affordance_thunk(thunk),
      do: Process.put(@affordance_thunks,[thunk | affordance_thunks()])

  @provocation_thunks :provocation_thunks
  def provocation_thunks(thunks),
      do: Process.put(@provocation_thunks, provocation_thunks() ++ thunks)
  def provocation_thunks(), do: Process.get(@provocation_thunks, [])

  @animal :animal
  def make_animal_kludgily_available(aa), do: Process.put(@animal, aa)
  def animal(), do: Process.get(@animal)
end
