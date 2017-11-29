defmodule Blueprint.CLI do
    @moduledoc """
      Blueprint is a utility that allows you to inspect details
      of your erlang applications.

      usage:
        blueprint [help] <command> [<args>]

      Graphical output commands:
      * `plot` - To create different graphs of the system
    """

    def main(args \\ [])
    def main(["help"|command]), do: help(command)
    def main(["plot"|command]), do: plot(command)
    def main(_), do: help()

    defp help(command  \\ ""), do: IO.puts Blueprint.CLI.Markdown.convert(get_docs(command))

    defp module_for_command(parent, command), do: Module.safe_concat(parent, String.to_atom(String.capitalize(command)))

    @graphs ["app", "mod", "fun", "msg"]
    defp get_docs(["plot", graph]) when graph in @graphs do
        module_for_command(Mix.Tasks.Blueprint.Plot, graph)
        |> get_docs()
        |> String.replace(~r/mix blueprint.plot.#{graph}/, "blueprint plot #{graph}")
    end
    defp get_docs(["plot"]) do
        """
        Plot different graphs.

        * `blueprint plot app` - Plot an appication graph
        * `blueprint plot mod` - Plot a module graph
        * `blueprint plot fun` - Plot a function graph
        * `blueprint plot msg` - Plot a message graph
        """
    end
    defp get_docs(module) when is_atom(module) do
        { _, doc } = Code.get_docs(module, :moduledoc)
        doc
    end
    defp get_docs(_), do: get_docs(__MODULE__)

    defp plot([graph|args]) when graph in @graphs do
        try do
            module_for_command(Mix.Tasks.Blueprint.Plot, graph).run(args)
        rescue
            _ -> help(["plot", graph])
        end
    end
    defp plot(_), do: help()
end
