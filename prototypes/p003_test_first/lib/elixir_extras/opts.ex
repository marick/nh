defmodule AppAnimal.Extras.Opts do
  @moduledoc """
  Utilities for Keyword lists used for named arguments (usually called `opts` in Elixir).
  """

  use AppAnimal

  @missing_key :unique_7347b976_d636_4521

  defp parse_one(key, {opts, parsed}) when is_atom(key) do
    case Keyword.pop_first(opts, key, @missing_key) do
      {@missing_key, _} ->
        raise(KeyError, term: opts, key: key,
                        message: "required argument #{inspect key} is missing")
      {value, smaller_opts} ->
        {smaller_opts, [value | parsed]}
    end
  end

  defp parse_one({key,default}, {opts, parsed}) do
    case Keyword.pop_first(opts, key, @missing_key) do
      {@missing_key, smaller_opts} ->
        {smaller_opts, [default | parsed]}
      {value, smaller_opts} ->
        {smaller_opts, [value | parsed]}
    end
  end

  def parse(original_opts, descriptions, local_opts \\ [extra_keys: :disallowed]) do
    {remaining_opts, reversed} =
      Enum.reduce(descriptions, {original_opts, []}, &parse_one/2)

    if remaining_opts == [] or Keyword.get(local_opts, :extra_keys) == :allowed do
      Enum.reverse(reversed)
    else
      extra_keys = Keyword.keys(remaining_opts)
      raise(KeyError, term: original_opts,
                      message: "extra keys are not allowed: #{inspect extra_keys}")
    end
  end


  ## Old stuff

  def put_new!(opts, new) do
    precondition all_keys_missing?(opts, Keyword.keys(new))

    opts ++ new
  end

  def all_keys_missing?(opts, keys) do
    m_opts = MapSet.new(Keyword.keys(opts))
    m_keys = MapSet.new(keys)
    MapSet.disjoint?(m_opts, m_keys)
  end








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

  def put_missing!(opts, replacements) do
    already_existing =
      Keyword.keys(replacements)
      |> Enum.filter(& Keyword.has_key?(opts, &1))

    unless already_existing == [],
           do: raise(KeyError, term: opts,
                               message: "keys #{inspect already_existing} are already present")

    provide_default(opts, replacements)
  end

  def provide_default(opts, possible_replacements),
      do: Keyword.merge(possible_replacements, opts)


  @doc """
  Use a `source` key (and perhaps others) to derive a `derived` key"

  Conventionally:

       opts
       |> create(:derived, if_present: :source, with: f)

  1. If `:derived` is already present, the opts are left unchanged.
  2. The same is true if the `source` is missing.
  3. `f` takes the value of the `source` key and
     returns a keyword list with `:derived` linked to the value. (Note that,
     in typical use, the option list is visible inside `f`.
  4. Order is not guaranteed.
  5. The source key/value pair is *not* removed.
  """
  def calculate_unless_given(opts, derived, positional) do
    [source, f] = required!(positional, [:from, :using])
    case Keyword.fetch(opts, source) do
      {:ok, source_value} ->
        opts
        |> Keyword.put_new(derived, f.(source_value))
      :error ->
        opts
    end
  end

  def rename(opts, outer, to: inner) do
    case Keyword.pop_first(opts, outer) do
      {nil, ^opts} ->
        opts
      {value, new_opts} ->
        if Keyword.has_key?(opts, inner) do
          message = "Keys `#{inspect inner}` and `#{inspect outer}` conflict"
          raise(KeyError, term: opts, key: outer, message: message)
        end
        Keyword.put_new(new_opts, inner, value)
    end
  end
end
