defmodule Blueprint.Plot.Label do
    def to_label({ mod, fun, arity }), do: "#{mod}.#{fun}/#{arity}"
    def to_label(mod), do: to_string(mod)

    def strip_namespace(label, namespace \\ "Elixir"), do: String.replace_prefix(label, namespace <> ".", "")
end
