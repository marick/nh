defmodule AppAnimal.Extras.DefDeeply do
  @moduledoc """
  `defdeeply` expands into two functions. Consider this:

        defdeeply put(s_struct, lens, value), do: Lens.put(lens, s_struct, value)

  On the one hand, that simply creates the equivalent `def`:

        def       put(s_struct, lens, value), do: Lens.put(lens, s_struct, value)

  That allows lens use to follow the
  structure-you're-operating-on-first Elixir convention. Compare:

        Map.put(   struct, :key,   value)
        put(struct, lens(), value))
        Lens.put  (lens, struct, value)

  The second thing `defdeeply` does is create a same-named function
  that uses the *name* of the lens function, instead of the function
  itself. Like this:

        struct = %MyStruct{...}
        put(struct, :lens, value)

  That is equivalent to this call:

        put(struct, MyStruct.lens(), value)

  Note: the lenses are defined with `def` instead of `deflens`. That's because
  this is used to create functions for *using* lenses, not for *defining* them.
  """

  defmacro defdeeply(head, do: body) do
    case length(elem(head, 2)) do
      3 ->
        code_for_three_arg_version(head, body)
      2 ->
        code_for_two_arg_version(head, body)
    end
  end

  defp code_for_three_arg_version(head, body) do
    {name, _meta, [struct_name, lens, arg3]} = head
    lookup = code_to_lookup_lens(struct_name, lens)
    quote do
      def unquote(head) when is_atom(unquote(lens)) do
        unquote(name)(unquote(struct_name),
                      unquote(lookup),
                      unquote(arg3))
      end
      def unquote(head), do: unquote(body)
    end
  end

  defp code_for_two_arg_version(head, body) do
    {name, _meta, [struct_name, lens]} = head
    lookup = code_to_lookup_lens(struct_name, lens)

    quote do
      def unquote(head) when is_atom(unquote(lens)) do
        unquote(name)(unquote(struct_name),
                      unquote(lookup))
      end
      def unquote(head), do: unquote(body)
    end
  end

  defp code_to_lookup_lens(struct_name, lens) do
    quote do
      unquote(__MODULE__).lookup_lens(unquote(struct_name),
                                      unquote(lens))
    end
  end

  def lookup_lens(s_struct, lens_name), do: apply(s_struct.__struct__, lens_name, [])
end
