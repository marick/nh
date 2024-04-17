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

  def required!(original_opts, keys) when is_list(keys) do
    reducer = fn key, {values, opts} ->
      case Keyword.pop_first(opts, key) do
        {nil, _} ->
          raise(KeyError, term: original_opts, key: key, 
                          message: "keyword argument #{inspect key} is missing")
        {value, next_opts} ->
          {[value | values], next_opts}
      end
    end
    
    {reversed_values, remaining_opts} =
      Enum.reduce(keys, {[], original_opts}, reducer)

    unless remaining_opts == [] do
      extra_keys = Keyword.keys(remaining_opts)
      raise(KeyError, term: extra_keys,
                      message: "extra keyword arguments: #{inspect extra_keys}")
    end
    
    Enum.reverse(reversed_values)
  end
end
