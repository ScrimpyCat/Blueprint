defmodule Mix.Tasks.Blueprint.Plot.Mod do
    @shortdoc "Create a module graph"
    @moduledoc """
      Creates a module graph.

        mix blueprint.plot.mod [APP] [--simple | --complex] [--colour] [[--lib LIB | --path PATH] ...] [--messages]

      An `APP` name is provided if the module graph should be
      limited to the given application. Otherwise it will be
      for the entire blueprint (libraries tracked).

      A `--simple` or `--complex` option can be used to indicate
      the detail of the generated graph.

      A '--colour' option can be used to generate a coloured
      graph.

      As many `--lib` or `--path` options can be provided to
      add additional libraries to the blueprint. If none are
      provided, the blueprint will default to using the
      libraries found in the project's build directory.

      A `--messages` option can be used to generate connections
      for messages sent between modules.

      A `--version` option can be used to include version numbers
      in the module nodes.

      ## Examples

      Generate a graph for the current project:
        mix blueprint.plot.mod

      Generate a graph for the current project's `example` application:
        mix blueprint.plot.mod example

      Generate a graph for the provided libraries:
        mix blueprint.plot.mod --lib example1 --lib example2 --path /example

      Generate a simple graph of mnesia from the standard erlang runtime:
        mix blueprint.plot.mod --path $(elixir -e 'IO.puts :code.lib_dir') --simple mnesia
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
    defp options(["--simple"|args], options), do: options(args, %{ options | opts: Map.put(options[:opts], :detail, :low) })
    defp options(["--complex"|args], options), do: options(args, %{ options | opts: Map.put(options[:opts], :detail, :high) })
    defp options(["--messages"|args], options), do: options(args, %{ options | annotations: [:messages|options[:annotations]] })
    defp options(["--version"|args], options), do: options(args, %{ options | annotations: [:version|options[:annotations]] })
    defp options(["--colour"|args], options) do
        opts = Map.put(options[:opts], :styler, fn
            { :node, { mod, _, _ } } -> [color: Blueprint.Plot.Style.colourize(Blueprint.Plot.Label.strip_namespace(Blueprint.Plot.Label.to_label((mod))))]
            { :node, mod } -> [color: Blueprint.Plot.Style.colourize(Blueprint.Plot.Label.strip_namespace(Blueprint.Plot.Label.to_label(mod)))]
            { :connection, { { mod, _, _ }, _ } } -> [color: Blueprint.Plot.Style.colourize(Blueprint.Plot.Label.strip_namespace(Blueprint.Plot.Label.to_label(mod)))]
            { :connection, { mod, _ } } -> [color: Blueprint.Plot.Style.colourize(Blueprint.Plot.Label.strip_namespace(Blueprint.Plot.Label.to_label(mod)))]
            { :connection, { { mod, _, _ }, _, _ } } -> [color: Blueprint.Plot.Style.colourize(Blueprint.Plot.Label.strip_namespace(Blueprint.Plot.Label.to_label(mod)))]
            { :connection, { mod, _, _ } } -> [color: Blueprint.Plot.Style.colourize(Blueprint.Plot.Label.strip_namespace(Blueprint.Plot.Label.to_label(mod)))]
            _ -> [color: "black"]
        end)
        options(args, %{ options | opts: opts })
    end
    defp options([app|args], options), do: options(args, %{ options | app: String.to_atom(app) })

    def run(args) do
        { :ok, _ } = :application.ensure_all_started(:graphvix)

        options = options(args, %{ libs: Path.join(Mix.Project.build_path(), "lib"), opts: %{}, app: nil, annotations: [] })
        blueprint = Blueprint.new(options[:libs])

        case options do
            %{ app: nil } -> Blueprint.Plot.module_graph(blueprint, [{ :annotate, Enum.uniq(options[:annotations]) }|Keyword.new(options[:opts])])
            _ -> Blueprint.Plot.module_graph(blueprint, options[:app], [{ :annotate, Enum.uniq(options[:annotations]) }|Keyword.new(options[:opts])])
        end

        Blueprint.close(blueprint)
    end
end
