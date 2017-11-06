defmodule Blueprint.Plot.Graph do
    defp add_node(nodes, node, label), do: Map.put_new(nodes, node, elem(Graphvix.Node.new(label: label.(node)), 0))

    defp add_module(modules, mod, node_id) do
        case modules do
            %{ ^mod => nodes } -> %{ modules | mod => [node_id|nodes] }
            _ -> Map.put_new(modules, mod, [node_id])
        end
    end

    def to_dot(graph, opts \\ []) do
        label = Keyword.get(opts, :labeler, &Blueprint.Plot.Label.strip_namespace(Blueprint.Plot.Label.to_label(&1)))

        Graphvix.Graph.new(self())
        nodes = Enum.reduce(graph, %{}, fn { a, b }, nodes ->
            nodes = %{ ^a => node_a, ^b => node_b } = case nodes do
                %{ ^a => _ } -> add_node(nodes, b, label)
                %{ ^b => _ } -> add_node(nodes, a, label)
                %{ ^a => _, ^b => _ } -> nodes
                _ ->
                    add_node(nodes, a, label)
                    |> add_node(b, label)
            end

            Graphvix.Edge.new(node_a, node_b, color: "black")
            nodes
        end)

        if Keyword.get(opts, :group, false) do
            Enum.reduce(nodes, %{}, fn
                { { mod, _, _ }, node_id }, modules -> add_module(modules, mod, node_id)
                { mod, node_id }, modules -> add_module(modules, mod, node_id)
            end)
            |> Enum.each(fn
                { _, [_] } -> nil
                { _, nodes } -> Graphvix.Cluster.new(nodes)
            end)
        end

        dot = Graphvix.Graph.write
        Graphvix.Graph.clear

        dot
    end

    def save!(dot, path \\ "graph.dot"), do: File.write!(path, dot)
end
