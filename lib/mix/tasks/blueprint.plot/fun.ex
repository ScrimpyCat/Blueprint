defmodule Mix.Tasks.Blueprint.Plot.Fun do
    @shortdoc "Create a function graph"

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
    defp options([app|args], options), do: options(args, %{ options | app: app })

    def run(args) do
        { :ok, _ } = :application.ensure_all_started(:graphvix)

        options = options(args, %{ libs: Path.join(Mix.Project.build_path(), "lib"), detail: :high, app: nil })
        blueprint = Blueprint.new(options[:libs])

        case options do
            %{ app: nil } -> Blueprint.Plot.function_graph(blueprint, detail: options[:detail])
            _ -> Blueprint.Plot.function_graph(blueprint, options[:app], detail: options[:detail])
        end

        Blueprint.close(blueprint)
    end
end
