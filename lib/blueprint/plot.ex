defmodule Blueprint.Plot do
    @spec application_graph(Blueprint.t, keyword()) :: Blueprint.t
    def application_graph(blueprint = %Blueprint{ xref: xref }, opts \\ []) do
        query = case Keyword.get(opts, :detail, :high) do
            :low -> 'AE ||| A'
            :high -> 'AE | A'
        end

        { :ok, graph } = :xref.q(xref, query)

        Blueprint.Plot.Graph.to_dot(graph, opts)
        |> Blueprint.Plot.Graph.save!("application_graph.dot")

        blueprint
    end

    @spec module_graph(Blueprint.t, keyword()) :: Blueprint.t
    def module_graph(blueprint = %Blueprint{ xref: xref }, opts \\ []) do
        query = case Keyword.get(opts, :detail, :high) do
            :low -> 'ME ||| A'
            :high -> 'ME | A'
        end

        { :ok, graph } = :xref.q(xref, query)

        Blueprint.Plot.Graph.to_dot(graph, opts)
        |> Blueprint.Plot.Graph.save!("module_graph.dot")

        blueprint
    end

    @spec call_graph(Blueprint.t, atom, keyword()) :: Blueprint.t
    def call_graph(blueprint = %Blueprint{ xref: xref }, app, opts \\ []) do
        query = case Keyword.get(opts, :detail, :high) do
            :low -> to_charlist("E ||| #{app}")
            :high -> to_charlist("E | #{app}")
        end

        { :ok, graph } = :xref.q(xref, query)

        Blueprint.Plot.Graph.to_dot(graph, opts)
        |> Blueprint.Plot.Graph.save!("call_graph.dot")

        blueprint
    end
end
