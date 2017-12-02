defmodule Blueprint.Plot.Graph do
    @moduledoc """
      Convenient functions for building simple node dependency
      graphs.
    """

    @type graph_node :: any
    @type meta :: any
    @type connection :: { graph_node, graph_node } | { graph_node, graph_node, meta }
    @type graph :: [connection]
    @type labeler :: (graph_node -> String.t)
    @type styler :: ({ :node, graph_node } | { :connection, connection } -> keyword())
    @type node_cache :: %{ optional(graph_node) => pos_integer }
    @type cluster_type :: :app | :mod

    @spec add_node(node_cache, graph_node, labeler, styler) :: node_cache
    defp add_node(nodes, node, label, styler), do: Map.put_new(nodes, node, elem(Graphvix.Node.new(Keyword.merge([label: label.(node)], styler.({ :node, node }))), 0))

    @spec add_module(%{ optional(graph_node) => [pos_integer] }, graph_node, pos_integer) :: %{ optional(graph_node) => [pos_integer] }
    defp add_module(modules, mod, node_id) do
        case modules do
            %{ ^mod => nodes } -> %{ modules | mod => [node_id|nodes] }
            _ -> Map.put_new(modules, mod, [node_id])
        end
    end

    @spec define_clusters(node_cache, [cluster_type] | cluster_type | nil) :: node_cache
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

    @spec define_nodes(node_cache, graph_node, graph_node, labeler, styler) :: node_cache
    defp define_nodes(nodes, a, b, label, styler) do
        case nodes do
            %{ ^a => _, ^b => _ } -> nodes
            %{ ^a => _ } -> add_node(nodes, b, label, styler)
            %{ ^b => _ } -> add_node(nodes, a, label, styler)
            _ ->
                if(a != b, do: add_node(nodes, a, label, styler), else: nodes)
                |> add_node(b, label, styler)
        end
    end

    @doc """
      Convert a node graph into a DOT graph.

      Options can be provided to change the resulting graph. These
      options are:

      * `:labeler` - A function of type `labeler`, where
      the node is passed to the function and is expected to
      receive a string that will be used on the graph to label it
      as a result.
      * `:styler` - A function of type `styler` where a node
      or connection is passed the function and is expected to
      return any styling changes to overwrite the defaults with.
    """
    @spec to_dot(graph, keyword()) :: String.t
    def to_dot(graph, opts \\ []) do
        styler = Keyword.get(opts, :styler, fn _ -> [color: "black"] end)
        label = Keyword.get(opts, :labeler, &Blueprint.Plot.Label.strip_namespace(Blueprint.Plot.Label.to_label(&1)))

        :ok = Graphvix.Graph.new(__MODULE__)
        nodes = Enum.reduce(graph, %{}, fn
            connection = { a, b }, nodes ->
                nodes = %{ ^a => node_a, ^b => node_b } = define_nodes(nodes, a, b, label, styler)

                Graphvix.Edge.new(node_a, node_b, styler.({ :connection, connection }))
                nodes
            connection = { a, b, _ }, nodes ->
                nodes = %{ ^a => node_a, ^b => node_b } = define_nodes(nodes, a, b, label, styler)

                Graphvix.Edge.new(node_a, node_b, styler.({ :connection, connection }))
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
