defmodule Blueprint.Plot.Graph do
    @moduledoc """
      Convenient functions for building simple node dependency
      graphs.
    """

    defp add_node(nodes, node, label, styler), do: Map.put_new(nodes, node, elem(Graphvix.Node.new(Keyword.merge([label: label.(node)], styler.({ :node, node }))), 0))

    defp add_module(modules, mod, node_id) do
        case modules do
            %{ ^mod => nodes } -> %{ modules | mod => [node_id|nodes] }
            _ -> Map.put_new(modules, mod, [node_id])
        end
    end

    defp define_clusters(nodes, nil), do: nodes
    defp define_clusters(nodes, :mod) do
        Enum.reduce(nodes, %{}, fn
            { { mod, _, _ }, node_id }, modules -> add_module(modules, mod, node_id)
            { mod, node_id }, modules -> add_module(modules, mod, node_id)
        end)
        |> Enum.each(fn
            { _, [_] } -> nil
            { _, nodes } -> Graphvix.Cluster.new(nodes)
        end)
    end
    defp define_clusters(nodes, :app) do
        Enum.reduce(nodes, %{}, fn
            { { mod, _, _ }, node_id }, modules ->
                app = case to_string(mod) do
                    "Elixir." <> m ->
                        [app|_] = String.split(m, ".")
                        app
                    _ -> mod
                end
                add_module(modules, app, node_id)
            { mod, node_id }, modules ->
                app = case to_string(mod) do
                    "Elixir." <> m ->
                        [app|_] = String.split(m, ".")
                        app
                    _ -> mod
                end
                add_module(modules, app, node_id)
        end)
        |> Enum.each(fn
            { _, [_] } -> nil
            { _, nodes } -> Graphvix.Cluster.new(nodes)
        end)
    end
    defp define_clusters(nodes, []), do: nodes
    defp define_clusters(nodes, [h|t]) do
        define_clusters(nodes, h)
        define_clusters(nodes, t)
    end

    @doc """
      Convert a node graph into a DOT graph.

      Options can be provided to change the resulting graph. These
      options are:

      * `:labeler` - A function of type `(any -> String.t)`, where
      the node is passed to the function and is expected to
      receive a string that will be used on the graph to label it
      as a result.
      * `:styler` - A function of type `(node_element | connection_element -> keyword())`
      where `node_element` is of type `{ :node, node :: any }`
      and `connection_element` is of type `{ :connection, { node :: any, node :: any } }`.
    """
    @spec to_dot([{ any, any }], keyword()) :: String.t
    def to_dot(graph, opts \\ []) do
        styler = Keyword.get(opts, :styler, fn _ -> [color: "black"] end)
        label = Keyword.get(opts, :labeler, &Blueprint.Plot.Label.strip_namespace(Blueprint.Plot.Label.to_label(&1)))

        Graphvix.Graph.new(self())
        nodes = Enum.reduce(graph, %{}, fn { a, b }, nodes ->
            nodes = %{ ^a => node_a, ^b => node_b } = case nodes do
                %{ ^a => _, ^b => _ } -> nodes
                %{ ^a => _ } -> add_node(nodes, b, label, styler)
                %{ ^b => _ } -> add_node(nodes, a, label, styler)
                _ ->
                    if(a != b, do: add_node(nodes, a, label, styler), else: nodes)
                    |> add_node(b, label, styler)
            end

            Graphvix.Edge.new(node_a, node_b, styler.({ :connection, { a, b } }))
            nodes
        end)

        define_clusters(nodes, opts[:group])

        dot = Graphvix.Graph.write
        Graphvix.Graph.clear

        dot
    end

    @doc """
      Write the DOT graph to a file.
    """
    @spec save!(String.t, String.t) :: :ok | no_return
    def save!(dot, path \\ "graph.dot"), do: File.write!(path, dot)
end
