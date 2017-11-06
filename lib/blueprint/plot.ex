defmodule Blueprint.Plot do
    def application_graph(blueprint = %Blueprint{ xref: xref }, opts \\ []) do
        { :ok, graph } = :xref.q(xref, 'AE | A')

        Blueprint.Plot.Graph.to_dot(graph, opts)
        |> Blueprint.Plot.Graph.save!("application_graph.dot")

        blueprint
    end

    def module_graph(blueprint = %Blueprint{ xref: xref }, opts \\ []) do
        { :ok, graph } = :xref.q(xref, 'ME | A')

        Blueprint.Plot.Graph.to_dot(graph, opts)
        |> Blueprint.Plot.Graph.save!("module_graph.dot")

        blueprint
    end

    def call_graph(blueprint = %Blueprint{ xref: xref }, app, opts \\ []) do
        { :ok, graph } = :xref.q(xref, to_charlist("E | #{app}"))

        Blueprint.Plot.Graph.to_dot(graph, opts)
        |> Blueprint.Plot.Graph.save!("call_graph.dot")

        blueprint
    end
end
