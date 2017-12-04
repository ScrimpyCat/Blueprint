defmodule Blueprint.Plot do
    @moduledoc """
      Convenience functions for creating different graphs from
      a blueprint.
    """

    @spec add_post_fun(keyword(), atom, fun(), ((any, fun()) -> any)) :: keyword()
    defp add_post_fun(opts, op, default, fun) do
        { _, opts } = Keyword.get_and_update(opts, op, fn
            nil -> { nil, &(fun.(&1, default)) }
            default -> { default, &(fun.(&1, default)) }
        end)

        opts
    end

    @spec default_labeler() :: ((atom  | { atom, atom, integer }) -> String.t)
    defp default_labeler(), do: &Blueprint.Plot.Label.strip_namespace(Blueprint.Plot.Label.to_label(&1))

    @spec annotate({ Blueprint.Plot.Graph.graph, keyword() }, Blueprint.t, [atom] | atom, atom) :: { Blueprint.Plot.Graph.graph, keyword() }
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
    defp annotate({ graph, opts }, blueprint, :version, :module) do
        opts = add_post_fun(opts, :labeler, default_labeler(), fn node, labeler ->
            version = Enum.find_value(blueprint.apps, "", fn
                %Blueprint.Application{ modules: modules } ->
                    Enum.find_value(modules, fn
                        %Blueprint.Application.Module{ name: ^node, beam: beam } ->
                            { :ok, { _, [attributes: attributes ] } } = :beam_lib.chunks(beam, [:attributes])
                            [vsn|_] = attributes[:vsn]
                            "\n" <> to_string(vsn)
                        _ -> false
                    end)
                _ -> false
            end)
            labeler.(node) <> version
        end)

        { graph, opts }
    end
    defp annotate({ graph, opts }, blueprint, :messages, :application) do
        messages = Enum.reduce(blueprint.apps, graph, fn app, acc ->
            Enum.reduce(app.modules, acc, fn
                %Blueprint.Application.Module{ messages: [] }, acc -> acc
                module, acc ->
                    Enum.reduce(module.messages, acc, fn msg, acc ->
                        target = msg.target

                        Enum.find_value(blueprint.apps, acc, fn target_app ->
                            if Enum.any?(target_app.modules, fn
                                %Blueprint.Application.Module{ name: ^target } -> true
                                _ -> false
                            end) do
                                [{ elem(app.app, 1), elem(target_app.app, 1), :message }|acc]
                            end
                        end)
                    end)
            end)
        end)

        opts = add_post_fun(opts, :styler, fn _ -> [color: "black"] end, fn
            node = { :connection, { _, _, :message } }, styler -> Keyword.merge([style: "dashed"], styler.(node))
            node, styler -> styler.(node)
        end)

        { Enum.uniq(messages), opts }
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

    @spec write_graph(atom, Blueprint.Plot.Graph.graph, Blueprint.t, keyword()) :: Blueprint.t
    defp write_graph(type, graph, blueprint, opts) do
        { graph, opts } = if opts[:annotate] do
            annotate({ graph, opts }, blueprint, opts[:annotate], type)
        else
            { graph, opts }
        end

        Blueprint.Plot.Graph.to_dot(graph, opts)
        |> Blueprint.Plot.Graph.save!(to_string(type) <> "_graph.dot")

        blueprint
    end

    @spec query(pid, String.t | atom, String.t | atom, keyword()) :: Blueprint.Plot.Graph.graph
    defp query(xref, left, right, opts) do
        query = case Keyword.get(opts, :detail, :high) do
            :low -> to_charlist("#{left} ||| #{right}")
            :high -> to_charlist("#{left} | #{right}")
        end

        { :ok, graph } = :xref.q(xref, query)

        graph
    end

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
        - `:messages` - To include messages sent between nodes.
    """
    @spec application_graph(Blueprint.t, keyword()) :: Blueprint.t
    def application_graph(blueprint = %Blueprint{ xref: xref }, opts \\ []) do
        write_graph(:application, query(xref, "AE", "A", opts), blueprint, opts)
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
      * `:annotate` - Any additional annotations to be made. Valid
      values are an atom or list of atoms. The currently supported
      annotation options are:
        - `:version` - To display the module's version.
        - `:messages` - To include messages sent between nodes.

    """
    @spec module_graph(Blueprint.t, atom | keyword(), keyword()) :: Blueprint.t
    def module_graph(blueprint, app_or_opts \\ [], opts \\ [])
    def module_graph(blueprint = %Blueprint{ xref: xref }, opts, _) when is_list(opts) do
        write_graph(:module, query(xref, "ME", "A", opts), blueprint, opts)
    end
    def module_graph(blueprint = %Blueprint{ xref: xref }, app, opts) do
        write_graph(:module, query(xref, "ME", app, opts), blueprint, opts)
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
        write_graph(:function, query(xref, "E", "A", opts), blueprint, opts)
    end
    def function_graph(blueprint = %Blueprint{ xref: xref }, app, opts) do
        write_graph(:function, query(xref, "E", app, opts), blueprint, opts)
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

        write_graph(:message, graph, blueprint, opts)
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

        write_graph(:message, graph, blueprint, opts)
    end
end
