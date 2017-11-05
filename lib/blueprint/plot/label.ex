defmodule Blueprint.Plot.Label do
    def to_label({ mod, fun, arity }), do: "#{mod}.#{fun}/#{arity}"

    def strip_namespace(label, namespace \\ "Elixir"), do: String.replace_prefix(label, namespace <> ".", "")
end
