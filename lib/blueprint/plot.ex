defmodule Blueprint.Plot do
    alias Graphvix.{ Graph, Node, Edge, Cluster }

    def call_graph(blueprint = %Blueprint{ xref: xref }, app, opts \\ []) do
        { :ok, graph } = :xref.q(xref, to_charlist("E | #{app}"))

        label = Keyword.get(opts, :labeler, &Blueprint.Plot.Label.strip_namespace(Blueprint.Plot.Label.to_label(&1)))

        Graph.new(:call_graph)
        nodes = Enum.reduce(graph, %{}, fn { a, b }, nodes ->
            nodes = %{ ^a => node_a, ^b => node_b } = case nodes do
                %{ ^a => _ } -> Map.put_new(nodes, b, elem(Node.new(label: label.(b)), 0))
                %{ ^b => _ } -> Map.put_new(nodes, a, elem(Node.new(label: label.(a)), 0))
                %{ ^a => _, ^b => _ } -> nodes
                _ ->
                    Map.put_new(nodes, a, elem(Node.new(label: label.(a)), 0))
                    |> Map.put_new(b, elem(Node.new(label: label.(b)), 0))
            end

            Edge.new(node_a, node_b, color: "black")
            nodes
        end)

        if Keyword.get(opts, :group, false) do
            Enum.reduce(nodes, %{}, fn { { mod, _, _ }, node_id }, modules ->
                case modules do
                    %{ ^mod => nodes } -> %{ modules | mod => [node_id|nodes] }
                    _ -> Map.put_new(modules, mod, [node_id])
                end
            end)
            |> Enum.each(fn { _, nodes } ->
                Cluster.new(nodes)
            end)
        end

        Graph.save
        Graph.clear

        blueprint
    end
end
