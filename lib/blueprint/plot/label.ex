defmodule Blueprint.Plot.Label do
    @moduledoc """
      Convenient functions for formatting labels for graph
      presentation.
    """

    @doc """
      Convert a module or function call into a formatted string.

        iex> Blueprint.Plot.Label.to_label(:foo)
        "foo"

        iex> Blueprint.Plot.Label.to_label(Foo)
        "Elixir.Foo"

        iex> Blueprint.Plot.Label.to_label(Foo.Bar)
        "Elixir.Foo.Bar"

        iex> Blueprint.Plot.Label.to_label({ :foo, :test, 2 })
        "foo.test/2"

        iex> Blueprint.Plot.Label.to_label({ Foo, :test, 2 })
        "Elixir.Foo.test/2"

        iex> Blueprint.Plot.Label.to_label({ Foo.Bar, :test, 2})
        "Elixir.Foo.Bar.test/2"
    """
    @spec to_label(atom  | { atom, atom, integer }) :: String.t
    def to_label({ mod, fun, arity }), do: "#{mod}.#{fun}/#{arity}"
    def to_label(mod), do: to_string(mod)

    @doc """
      Strip any undesired namespace from the given label.

        iex> Blueprint.Plot.Label.strip_namespace("Elixir.Foo.Bar")
        "Foo.Bar"

        iex> Blueprint.Plot.Label.strip_namespace("Elixir.Foo.Bar", "Elixir.Foo")
        "Bar"
    """
    @spec strip_namespace(String.t, String.t) :: String.t
    def strip_namespace(label, namespace \\ "Elixir"), do: String.replace_prefix(label, namespace <> ".", "")
end
