defmodule Mix.Tasks.Blueprint.Plot.App do
    @shortdoc "Create a application graph"
    @moduledoc """
      Creates a application graph.

        mix blueprint.plot.app [--simple | --complex] [[--lib LIB | --path PATH] ...]

      A `--simple` or `--complex` option can be used to indicate
      the detail of the generated graph.

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
    defp options(["--simple"|args], options), do: options(args, %{ options | detail: :low })
    defp options(["--complex"|args], options), do: options(args, %{ options | detail: :high })

    def run(args) do
        { :ok, _ } = :application.ensure_all_started(:graphvix)

        options = options(args, %{ libs: Path.join(Mix.Project.build_path(), "lib"), detail: :high })
        blueprint = Blueprint.new(options[:libs])

        Blueprint.Plot.application_graph(blueprint, detail: options[:detail])

        Blueprint.close(blueprint)
    end
end
