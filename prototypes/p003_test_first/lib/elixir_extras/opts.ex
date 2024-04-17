defmodule AppAnimal.Extras.Opts do
  @moduledoc """
  Utilities for Keyword lists used for named arguments (usually called `opts` in Elixir).
  """

  def replace_key(opts, maybe_present, replacement) do
    case Keyword.pop_first(opts, maybe_present, :no_such_value) do
      {:no_such_value, _} ->
        opts
      {value, new_opts} -> 
        Keyword.put(new_opts, replacement, value)
    end
  end

  def replace_keys(opts, replacements) do
    Enum.reduce(replacements, opts, fn {key, value}, acc ->
      replace_key(acc, key, value)
    end)
  end

  def copy(opts, new_key, from_existing: old_key) do
    case Keyword.fetch(opts, old_key) do
      {:ok, value} -> 
        Keyword.put_new(opts, new_key, value)
      :error ->
        opts
    end
  end

  def required!(opts, keys) when is_list(keys) do
    for k <- keys, do: Keyword.fetch!(opts, k)
  end
end
