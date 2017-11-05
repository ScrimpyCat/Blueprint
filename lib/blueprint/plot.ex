defmodule Blueprint.Plot do
    alias Graphvix.{ Graph, Node, Edge, Cluster }

    def call_graph(path, app, opts \\ []) do
        { :ok, xref } = :xref.start([])

        File.ls!(path)
        |> Enum.each(fn file ->
            lib = Path.join(path, file)
            if File.dir?(lib) do
                :xref.add_application xref, to_charlist(lib)
            end
        end)

        { :ok, graph } = :xref.q(xref, to_charlist("E | #{app}"))
        :xref.stop(xref)

        label = Keyword.get(opts, :labeler, &Plot.Label.strip_namespace(Plot.Label.to_label(&1)))

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

        Graph.save
        Graph.clear
    end
end
