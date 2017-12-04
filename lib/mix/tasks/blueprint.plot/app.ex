defmodule Mix.Tasks.Blueprint.Plot.App do
    @shortdoc "Create an application graph"
    @moduledoc """
      Creates an application graph.

        mix blueprint.plot.app [--simple | --complex] [--colour] [--messages] [--version] [[--lib LIB | --path PATH] ...] [-o PATH]

      A `--simple` or `--complex` option can be used to indicate
      the detail of the generated graph.

      A `--colour` option can be used to generate a coloured
      graph.

      A `--messages` option can be used to generate connections
      for messages sent between applications.

      A `--version` option can be used to include version numbers
      in the application nodes.

      A `-o` option can be used to specify the file to be written.

      As many `--lib` or `--path` options can be provided to
      add additional libraries to the blueprint. If none are
      provided, the blueprint will default to using the
      libraries found in the project's build directory.

      ## Examples

      Generate a graph for the current project:
        mix blueprint.plot.app

      Generate a graph for the provided libraries:
        mix blueprint.plot.app --lib example1 --lib example2 --path /example

      Generate a simple graph of the standard erlang runtime:
        mix blueprint.plot.app --path $(elixir -e 'IO.puts :code.lib_dir') --simple
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
    defp options(["-o"|args], options), do: options({ :output, args }, options)
    defp options({ :output, [path|args] }, options), do: options(args, %{ options | opts: Map.put(options[:opts], :name, path) })

    def run(args) do
        { :ok, _ } = :application.ensure_all_started(:graphvix)

        libs = case Code.ensure_loaded(Mix.Project) do
            { :module, _ } -> Path.join(Mix.Project.build_path(), "lib")
            _ -> []
        end

        options = options(args, %{ libs: libs, opts: %{}, annotations: [] })
        blueprint = Blueprint.new(options[:libs])

        Blueprint.Plot.application_graph(blueprint, [{ :annotate, Enum.uniq(options[:annotations]) }|Keyword.new(options[:opts])])

        Blueprint.close(blueprint)
    end
end
