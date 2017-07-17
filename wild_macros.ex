defmodule WildMacros do

  defmacro left..right do
    quote do
      def unquote(left)(), do: unquote(right)
    end
  end

  defmacro left--right do
    quote do
      String.replace(unquote(left), unquote(right), "")
    end
  end
end
