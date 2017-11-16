defmodule Blueprint.Plot do
    defp add_post_fun(opts, op, fun) do
        { _, opts } = Keyword.get_and_update(opts, op, fn
            nil ->
                labeler = &Blueprint.Plot.Label.strip_namespace(Blueprint.Plot.Label.to_label(&1))
                { nil, &(fun.(&1, labeler)) }
            labeler -> { labeler, &(fun.(&1, labeler)) }
        end)

        opts
    end

    defp annotate(graph, _, []), do: graph
    defp annotate(graph, blueprint, [h|t]), do: annotate(annotate(graph, blueprint, h), blueprint, t)
    defp annotate({ graph, opts }, blueprint, :version) do
        opts = add_post_fun(opts, :labeler, fn node, labeler ->
            version = Enum.find_value(blueprint.apps, "", fn
                %Blueprint.Application{ app: { :application, ^node, state } } -> to_string([?\n|state[:vsn]])
                _ -> false
            end)
            labeler.(node) <> version
        end)

        { graph, opts }
    end
    defp annotate(graph, _, _), do: graph

    @doc """
      Create an application graph.

      Options can be provided to change the resulting graph. These
      options are any that are valid in `Blueprint.Plot.Graph.to_dot/2`
      or any mentioned below:

      * `:detail` - Affects the level of detail of the generated
      graph. Valid values are `:high` or `:low`.
    """
    @spec application_graph(Blueprint.t, keyword()) :: Blueprint.t
    def application_graph(blueprint = %Blueprint{ xref: xref }, opts \\ []) do
        query = case Keyword.get(opts, :detail, :high) do
            :low -> 'AE ||| A'
            :high -> 'AE | A'
        end

        { :ok, graph } = :xref.q(xref, query)

        { graph, opts } = if opts[:annotate] do
            annotate({ graph, opts }, blueprint, opts[:annotate])
        else
            { graph, opts }
        end

        Blueprint.Plot.Graph.to_dot(graph, opts)
        |> Blueprint.Plot.Graph.save!("application_graph.dot")

        blueprint
    end

    @doc """
      Create a module graph.

      This can either be for the entire blueprint or for a given
      application.

      Options can be provided to change the resulting graph. These
      options are any that are valid in `Blueprint.Plot.Graph.to_dot/2`
      or any mentioned below:

      * `:detail` - Affects the level of detail of the generated
      graph. Valid values are `:high` or `:low`.
    """
    @spec module_graph(Blueprint.t, atom | keyword(), keyword()) :: Blueprint.t
    def module_graph(blueprint, app_or_opts \\ [], opts \\ [])
    def module_graph(blueprint = %Blueprint{ xref: xref }, opts, _) when is_list(opts) do
        query = case Keyword.get(opts, :detail, :high) do
            :low -> 'ME ||| A'
            :high -> 'ME | A'
        end

        { :ok, graph } = :xref.q(xref, query)

        { graph, opts } = if opts[:annotate] do
            annotate({ graph, opts }, blueprint, opts[:annotate])
        else
            { graph, opts }
        end

        Blueprint.Plot.Graph.to_dot(graph, opts)
        |> Blueprint.Plot.Graph.save!("module_graph.dot")

        blueprint
    end
    def module_graph(blueprint = %Blueprint{ xref: xref }, app, opts) do
        query = case Keyword.get(opts, :detail, :high) do
            :low -> to_charlist("ME ||| #{app}")
            :high -> to_charlist("ME | #{app}")
        end

        { :ok, graph } = :xref.q(xref, query)

        { graph, opts } = if opts[:annotate] do
            annotate({ graph, opts }, blueprint, opts[:annotate])
        else
            { graph, opts }
        end

        Blueprint.Plot.Graph.to_dot(graph, opts)
        |> Blueprint.Plot.Graph.save!("module_graph.dot")

        blueprint
    end

    @doc """
      Create a function graph.

      This can either be for the entire blueprint or for a given
      application.

      Options can be provided to change the resulting graph. These
      options are any that are valid in `Blueprint.Plot.Graph.to_dot/2`
      or any mentioned below:

      * `:detail` - Affects the level of detail of the generated
      graph. Valid values are `:high` or `:low`.
    """
    @spec function_graph(Blueprint.t, atom | keyword(), keyword()) :: Blueprint.t
    def function_graph(blueprint, app_or_opts \\ [], opts \\ [])
    def function_graph(blueprint = %Blueprint{ xref: xref }, opts, _) when is_list(opts) do
        query = case Keyword.get(opts, :detail, :high) do
            :low -> 'E ||| A'
            :high -> 'E | A'
        end

        { :ok, graph } = :xref.q(xref, query)

        { graph, opts } = if opts[:annotate] do
            annotate({ graph, opts }, blueprint, opts[:annotate])
        else
            { graph, opts }
        end

        Blueprint.Plot.Graph.to_dot(graph, opts)
        |> Blueprint.Plot.Graph.save!("function_graph.dot")

        blueprint
    end
    def function_graph(blueprint = %Blueprint{ xref: xref }, app, opts) do
        query = case Keyword.get(opts, :detail, :high) do
            :low -> to_charlist("E ||| #{app}")
            :high -> to_charlist("E | #{app}")
        end

        { :ok, graph } = :xref.q(xref, query)

        { graph, opts } = if opts[:annotate] do
            annotate({ graph, opts }, blueprint, opts[:annotate])
        else
            { graph, opts }
        end

        Blueprint.Plot.Graph.to_dot(graph, opts)
        |> Blueprint.Plot.Graph.save!("function_graph.dot")

        blueprint
    end
end
