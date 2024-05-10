defmodule AppAnimal.Extras.Opts do
  @moduledoc """
  Utilities for Keyword lists used for named arguments (usually called `opts` in Elixir).

  These functions are not suited for keyword lists that contain duplicate keys.
  """

  use AppAnimal

  @missing_key :unique_7347b976_d636_4521

  section "decomposing keyword lists into individual bindings" do


    @doc """
    Extract option values into individual variables.

    The `descriptions` are a list of individual keywords or {keyword, default} tuples:

        iex> [_a, _b, _c] = parse([a: 1, b: 2], [:a, b: 3333, c: 4444])
        [1, 2, 4444]

    Notice that `:b` in the option list was not overwritten: defaults are not applied
    if the key exists.

    Ordinarily, an error is raised if the `opts` contains an extra key
    (one unmentioned in the `descriptions`:

        [a, b, c] = parse([a: 1, b: 2, fff: 3], [:a, b: 3333, c: 4444])   # error

    That can be overruled with `extra_keys: :allowed`:

        iex> [_a, _b, _c] = parse([a: 1, b: 2, fff: 3], [:a, b: 3333, c: 4444],
        ...>                       extra_keys: :allowed)
        [1, 2, 4444]

    """
    def parse(opts, descriptions, parse_opts \\ [extra_keys: :disallowed]) do
      {remaining_opts, reversed} =
        Enum.reduce(descriptions, {opts, []}, &parse_one/2)

      if remaining_opts == [] or Keyword.get(parse_opts, :extra_keys) == :allowed do
        Enum.reverse(reversed)
      else
        extra_keys = Keyword.keys(remaining_opts)
        raise(KeyError, term: opts,
                        message: "extra keys are not allowed: #{inspect extra_keys}")
      end
    end

    @doc """
    Extract all values from a keyword list into individual variables.

    This is like `parse/3` except that no defaults are allowed.

        iex> [_a, _b] = required!([a: 1, b: 2], [:a, :b])
        [1, 2]

    Like `parse/3`, it insists that all keys in the `opts` be mentioned. Unlike `parse/3`,
    that cannot be overridden.

        required!([a: 1, b: 2, ccccc: 33333], [:a, :b])
    """
    def required!(opts, keys) when is_list(keys) do
      reducer = fn key, {values, opts} ->
        case Keyword.pop_first(opts, key) do
          {nil, _} ->
            raise(KeyError, term: opts, key: key,
                            message: "keyword argument #{inspect key} is missing")
          {value, next_opts} ->
            {[value | values], next_opts}
        end
      end

      {reversed_values, remaining_opts} =
        Enum.reduce(keys, {[], opts}, reducer)

      unless remaining_opts == [] do
        extra_keys = Keyword.keys(remaining_opts)
        raise(KeyError, term: extra_keys,
                        message: "extra keyword arguments: #{inspect extra_keys}")
      end

      Enum.reverse(reversed_values)
    end
  end

  section "constructing new option lists" do
    @doc """
    Add all the key/value tuples from `additions` into `opts`.

        iex> put_missing!([a: 1], [b: 1])
        [a: 1, b: 1]

    This differs from just appending the lists because `put_missing!` insists that the
    two keyword lists not contain any keys in common. (That's what the ! signifies;
    think of it as akin to `Keyword.fetch!/2`.)

    """

    def put_missing!(opts, replacements) do
      already_existing =
        Keyword.keys(replacements)
        |> Enum.filter(& Keyword.has_key?(opts, &1))

      unless already_existing == [],
             do: raise(KeyError, term: opts,
                                 message: "keys #{inspect already_existing} are already present")

      provide_default(opts, replacements)
    end
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


  private do
    def parse_one(key, {opts, parsed}) when is_atom(key) do
      case Keyword.pop_first(opts, key, @missing_key) do
        {@missing_key, _} ->
          raise(KeyError, term: opts, key: key,
                          message: "required argument #{inspect key} is missing")
        {value, smaller_opts} ->
          {smaller_opts, [value | parsed]}
      end
    end

    def parse_one({key,default}, {opts, parsed}) do
      case Keyword.pop_first(opts, key, @missing_key) do
        {@missing_key, smaller_opts} ->
          {smaller_opts, [default | parsed]}
        {value, smaller_opts} ->
          {smaller_opts, [value | parsed]}
      end
    end
  end
end
