# Convenience functions for two-level maps. Maybe I should generalize. Plus also
# break out specific tests, as if this were a real API.
defmodule AppAnimal.Map2 do
  def map_within(outer_map, key, f) do
    inner_map = Map.get(outer_map, key)
    changed_map =
      for {k, v} <- inner_map, into: %{} do
        {k, f.(v)}
      end
    Map.put(outer_map, key, changed_map)
  end

  def reject_value_within(outer_map, key, rejected_value) do
    inner_map = Map.get(outer_map, key)
    transformed = 
      for {k, v} <- inner_map,
          v != rejected_value,
          into: %{},
          do: {k, v}
    Map.put(outer_map, key, transformed)
  end
    


  
end
