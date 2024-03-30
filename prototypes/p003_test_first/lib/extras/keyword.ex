defmodule AppAnimal.Extras.KeywordX do

  def replace_key(kws, maybe_present, replacement) do
    case Keyword.pop_first(kws, maybe_present, :no_such_value) do
      {:no_such_value, _} ->
        kws
      {value, new_kws} -> 
        Keyword.put(new_kws, replacement, value)
    end
  end

  def replace_keys(kws, replacements) do
    Enum.reduce(replacements, kws, fn {key, value}, acc ->
      replace_key(acc, key, value)
    end)
  end
end
