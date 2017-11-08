defmodule Blueprint.Plot.Label do
    @spec to_label(atom  | { atom, atom, integer }) :: String.t
    def to_label({ mod, fun, arity }), do: "#{mod}.#{fun}/#{arity}"
    def to_label(mod), do: to_string(mod)

    @spec strip_namespace(String.t, String.t) :: String.t
    def strip_namespace(label, namespace \\ "Elixir"), do: String.replace_prefix(label, namespace <> ".", "")
end
