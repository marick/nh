defmodule AppAnimal.Extras.DefDeeply do
  @moduledoc """
  `defdeeply` expands into two functions. Consider this:

        defdeeply deeply_put(s_struct, lens, value), do: Lens.put(lens, s_struct, value)

  On the one hand, that simply creates the equivalent `def`:

        def       deeply_put(s_struct, lens, value), do: Lens.put(lens, s_struct, value)

  That allows lens use to follow the
  structure-you're-operating-on-first Elixir convention. Compare:

        Map.put(   struct, :key,   value)
        deeply_put(struct, lens(), value))
        Lens.put  (lens, struct, value)

  The second thing `defdeeply` does is create a same-named
  `deeply_...` function that uses the *name* of the lens function,
  instead of the function itself. Like this:

        struct = %MyStruct{...}
        deeply_put(struct, :lens, value)

  That is equivalent to this call:

        deeply_put(struct, MyStruct.lens(), value)

  Note: the lenses are defined with `def` instead of `deflens`. I don't think that
  matters.
  """

  defmacro defdeeply(head, do: body) do
    case length(elem(head, 2)) do
      3 ->
        defdeeply_3(head, body)
      2 ->
        defdeeply_2(head, body)
    end
  end

  def defdeeply_3(head, body) do
    {name, _meta, [struct_name, lens, arg3]} = head
    new_arg2 = call_to_lookup_lens(struct_name, lens)
    quote do
      def unquote(head) when is_atom(unquote(lens)) do
        unquote(name)(unquote(struct_name),
                      unquote(new_arg2),
                      unquote(arg3))
      end
      def unquote(head), do: unquote(body)
    end
  end

  def defdeeply_2(head, body) do
    {name, _meta, [struct_name, lens]} = head
    new_arg2 = call_to_lookup_lens(struct_name, lens)

    quote do
      def unquote(head) when is_atom(unquote(lens)) do
        unquote(name)(unquote(struct_name),
                      unquote(new_arg2))
      end
      def unquote(head), do: unquote(body)
    end
  end

  def call_to_lookup_lens(struct_name, lens) do
    quote do
      unquote(__MODULE__).lookup_lens(unquote(struct_name),
                                      unquote(lens))
    end
  end

  def lookup_lens(s_struct, lens_name), do: apply(s_struct.__struct__, lens_name, [])
end
