defmodule Blueprint.Plot.Graph do
    def to_dot(graph, opts \\ []) do
        label = Keyword.get(opts, :labeler, &Blueprint.Plot.Label.strip_namespace(Blueprint.Plot.Label.to_label(&1)))

        Graphvix.Graph.new(self())
        nodes = Enum.reduce(graph, %{}, fn { a, b }, nodes ->
            nodes = %{ ^a => node_a, ^b => node_b } = case nodes do
                %{ ^a => _ } -> Map.put_new(nodes, b, elem(Graphvix.Node.new(label: label.(b)), 0))
                %{ ^b => _ } -> Map.put_new(nodes, a, elem(Graphvix.Node.new(label: label.(a)), 0))
                %{ ^a => _, ^b => _ } -> nodes
                _ ->
                    Map.put_new(nodes, a, elem(Graphvix.Node.new(label: label.(a)), 0))
                    |> Map.put_new(b, elem(Graphvix.Node.new(label: label.(b)), 0))
            end

            Graphvix.Edge.new(node_a, node_b, color: "black")
            nodes
        end)

        if Keyword.get(opts, :group, false) do
            Enum.reduce(nodes, %{}, fn { mod, node_id }, modules ->
                case modules do
                    %{ ^mod => nodes } -> %{ modules | mod => [node_id|nodes] }
                    _ -> Map.put_new(modules, mod, [node_id])
                end
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
