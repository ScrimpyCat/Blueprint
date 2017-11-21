defmodule Blueprint.Plot do
    defp add_post_fun(opts, op, default, fun) do
        { _, opts } = Keyword.get_and_update(opts, op, fn
            nil -> { nil, &(fun.(&1, default)) }
            default -> { default, &(fun.(&1, default)) }
        end)

        opts
    end

    defp default_labeler(), do: &Blueprint.Plot.Label.strip_namespace(Blueprint.Plot.Label.to_label(&1))

    defp annotate(graph, _, [], _), do: graph
    defp annotate(graph, blueprint, [h|t], mode), do: annotate(annotate(graph, blueprint, h, mode), blueprint, t, mode)
    defp annotate({ graph, opts }, blueprint, :version, :application) do
        opts = add_post_fun(opts, :labeler, default_labeler(), fn node, labeler ->
            version = Enum.find_value(blueprint.apps, "", fn
                %Blueprint.Application{ app: { :application, ^node, state } } -> to_string([?\n|state[:vsn]])
                _ -> false
            end)
            labeler.(node) <> version
        end)

        { graph, opts }
    end
    defp annotate({ graph, opts }, blueprint, :messages, :module) do
        messages = Enum.reduce(blueprint.apps, graph, fn app, acc ->
            Enum.reduce(app.modules, acc, fn
                %Blueprint.Application.Module{ messages: [] }, acc -> acc
                module, acc ->
                    Enum.reduce(module.messages, acc, fn msg, acc ->
                        [{ module.name, msg.target, :message }|acc]
                    end)
            end)
        end)

        opts = add_post_fun(opts, :styler, fn _ -> [color: "black"] end, fn
            node = { :connection, { _, _, :message } }, styler -> Keyword.merge([style: "dashed"], styler.(node))
            node, styler -> styler.(node)
        end)

        { Enum.uniq(messages), opts }
    end
    defp annotate(graph, _, _, _), do: graph

    @doc """
      Create an application graph.

      Options can be provided to change the resulting graph. These
      options are any that are valid in `Blueprint.Plot.Graph.to_dot/2`
      or any mentioned below:

      * `:detail` - Affects the level of detail of the generated
      graph. Valid values are `:high` or `:low`.
      * `:annotate` - Any additional annotations to be made. Valid
      values are an atom or list of atoms. The currently supported
      annotation options are:
        - `:version` - To display the application's version.
    """
    @spec application_graph(Blueprint.t, keyword()) :: Blueprint.t
    def application_graph(blueprint = %Blueprint{ xref: xref }, opts \\ []) do
        query = case Keyword.get(opts, :detail, :high) do
            :low -> 'AE ||| A'
            :high -> 'AE | A'
        end

        { :ok, graph } = :xref.q(xref, query)

        { graph, opts } = if opts[:annotate] do
            annotate({ graph, opts }, blueprint, opts[:annotate], :application)
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
            annotate({ graph, opts }, blueprint, opts[:annotate], :module)
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

        { graph, opts } = if opts[:annotate] do;
            annotate({ graph, opts }, blueprint, opts[:annotate], :module)
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
            annotate({ graph, opts }, blueprint, opts[:annotate], :function)
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
            annotate({ graph, opts }, blueprint, opts[:annotate], :function)
        else
            { graph, opts }
        end

        Blueprint.Plot.Graph.to_dot(graph, opts)
        |> Blueprint.Plot.Graph.save!("function_graph.dot")

        blueprint
    end

    @doc """
      Create a message graph.

      This can either be for the entire blueprint or for a given
      application.

      Options can be provided to change the resulting graph. These
      options are any that are valid in `Blueprint.Plot.Graph.to_dot/2`.
    """
    @spec message_graph(Blueprint.t, atom | keyword(), keyword()) :: Blueprint.t
    def message_graph(blueprint, app_or_opts \\ [], opts \\ [])
    def message_graph(blueprint, opts, _) when is_list(opts) do
        graph = Enum.uniq(Enum.reduce(blueprint.apps, [], fn app, acc ->
            Enum.reduce(app.modules, acc, fn
                %Blueprint.Application.Module{ messages: [] }, acc -> acc
                module, acc ->
                    Enum.reduce(module.messages, acc, fn msg, acc ->
                        [{ module.name, msg.target }|acc]
                    end)
            end)
        end))

        { graph, opts } = if opts[:annotate] do
            annotate({ graph, opts }, blueprint, opts[:annotate], :message)
        else
            { graph, opts }
        end

        Blueprint.Plot.Graph.to_dot(graph, opts)
        |> Blueprint.Plot.Graph.save!("message_graph.dot")

        blueprint
    end
    def message_graph(blueprint, app, opts) do
        graph =
            Enum.find_value(blueprint.apps, [], fn
                %Blueprint.Application{ app: { :application, ^app, _ }, modules: modules } -> modules
                _ -> false
            end)
            |> Enum.reduce([], fn
                %Blueprint.Application.Module{ messages: [] }, acc -> acc
                module, acc ->
                    Enum.reduce(module.messages, acc, fn msg, acc ->
                        [{ module.name, msg.target }|acc]
                    end)
            end)
            |> Enum.uniq

        { graph, opts } = if opts[:annotate] do
            annotate({ graph, opts }, blueprint, opts[:annotate], :message)
        else
            { graph, opts }
        end

        Blueprint.Plot.Graph.to_dot(graph, opts)
        |> Blueprint.Plot.Graph.save!("message_graph.dot")

        blueprint
    end
end
