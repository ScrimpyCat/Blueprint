defmodule Blueprint.CLI do
    def main(args \\ [])
    def main(["help"|command]), do: IO.puts Blueprint.CLI.Markdown.convert(get_docs(command))

    defp module_for_command(parent, command), do: Module.safe_concat(parent, String.to_atom(String.capitalize(command)))

    @graphs ["app", "mod", "fun", "msg"]
    defp get_docs(["plot", graph]) when graph in @graphs do
        module_for_command(Mix.Tasks.Blueprint.Plot, graph)
        |> get_docs()
    end
    defp get_docs(module) when is_atom(module) do
        { _, doc } = Code.get_docs(module, :moduledoc)
        doc
    end
end
