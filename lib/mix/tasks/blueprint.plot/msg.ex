defmodule Mix.Tasks.Blueprint.Plot.Msg do
    @shortdoc "Create a message graph"
    @moduledoc """
      Creates a message graph.

        mix blueprint.plot.msg [APP] [--colour] [[--lib LIB | --path PATH] ...] [-o PATH]

      An `APP` name is provided if the message graph should be
      limited to the given application. Otherwise it will be
      for the entire blueprint (libraries tracked).

      A `--colour` option can be used to generate a coloured
      graph.

      A `-o` option can be used to specify the file to be written.

      As many `--lib` or `--path` options can be provided to
      add additional libraries to the blueprint. If none are
      provided, the blueprint will default to using the
      libraries found in the project's build directory.

      ## Examples

      Generate a graph for the current project:
        mix blueprint.plot.msg

      Generate a graph for the current project's `example` application:
        mix blueprint.plot.msg example

      Generate a graph for the provided libraries:
        mix blueprint.plot.msg --lib example1 --lib example2 --path /example

      Generate a graph of mnesia from the standard erlang runtime:
        mix blueprint.plot.msg --path $(elixir -e 'IO.puts :code.lib_dir') mnesia
    """

    use Mix.Task

    defp options(args, options)
    defp options([], options), do: options
    defp options(["--path"|args], options), do: options({ :path, args }, options)
    defp options(["--lib"|args], options), do: options({ :lib, args }, options)
    defp options({ :path, [app|args] }, options = %{ libs: libs }) when is_list(libs), do: options(args, %{ options | libs: [app|options[:libs]]})
    defp options({ :lib, [app|args] }, options = %{ libs: libs }) when is_list(libs), do: options(args, %{ options | libs: [String.to_atom(app)|options[:libs]]})
    defp options({ :path, [app|args] }, options), do: options(args, %{ options | libs: [app]})
    defp options({ :lib, [app|args] }, options), do: options(args, %{ options | libs: [String.to_atom(app)]})
    defp options(["--colour"|args], options) do
        opts = Map.put(options[:opts], :styler, fn
            { :node, { mod, _, _ } } -> [color: Blueprint.Plot.Style.colourize(Blueprint.Plot.Label.strip_namespace(Blueprint.Plot.Label.to_label((mod))))]
            { :node, mod } -> [color: Blueprint.Plot.Style.colourize(Blueprint.Plot.Label.strip_namespace(Blueprint.Plot.Label.to_label(mod)))]
            { :connection, { { mod, _, _ }, _ } } -> [color: Blueprint.Plot.Style.colourize(Blueprint.Plot.Label.strip_namespace(Blueprint.Plot.Label.to_label(mod))), style: "dashed"]
            { :connection, { mod, _ } } -> [color: Blueprint.Plot.Style.colourize(Blueprint.Plot.Label.strip_namespace(Blueprint.Plot.Label.to_label(mod))), style: "dashed"]
            _ -> [color: "black"]
        end)
        options(args, %{ options | opts: opts })
    end
    defp options(["-o"|args], options), do: options({ :output, args }, options)
    defp options({ :output, [path|args] }, options), do: options(args, %{ options | opts: Map.put(options[:opts], :name, path) })
    defp options([app|args], options), do: options(args, %{ options | app: String.to_atom(app) })

    def run(args) do
        { :ok, _ } = :application.ensure_all_started(:graphvix)

        libs = case Code.ensure_loaded(Mix.Project) do
            { :module, _ } -> Path.join(Mix.Project.build_path(), "lib")
            _ -> []
        end

        options = options(args, %{
            libs: libs,
            opts: %{
                styler: fn
                    { :connection, _ } -> [color: "black", style: "dashed"]
                    _ -> [color: "black"]
                end
            },
            app: nil
        })
        blueprint = Blueprint.new(options[:libs])

        case options do
            %{ app: nil } -> Blueprint.Plot.message_graph(blueprint, Keyword.new(options[:opts]))
            _ -> Blueprint.Plot.message_graph(blueprint, options[:app], Keyword.new(options[:opts]))
        end

        Blueprint.close(blueprint)
    end
end
