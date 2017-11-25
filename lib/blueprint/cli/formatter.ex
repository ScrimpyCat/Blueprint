defmodule Blueprint.CLI.Formatter do
    def format(ast) do
        Enum.map(ast, fn node ->
            line = Blueprint.CLI.Renderer.render(node)
            case :io.columns() do
                { :ok, width } ->
                    tokenize([line], Enum.sort(fixed_width_inputs(node), &(String.length(&1) > String.length(&2))))
                    |> Enum.filter(&(&1 != ""))
                    |> Enum.reduce("", fn
                        { :fixed, string }, acc -> acc <> string
                        string, acc ->
                            String.split(string, " ")
                            |> Enum.intersperse(" ")
                            |> Enum.chunk_while(acc, fn
                                " ", acc -> { :cont, acc <> " " }
                                word, "" -> { :cont, word }
                                word, acc ->
                                    if String.length(remove_ansi_codes(word)) + String.length(remove_ansi_codes(acc)) >= width do
                                        { :cont, String.trim(acc), word }
                                    else
                                        { :cont, acc <> word }
                                end
                            end, &({ :cont, &1, "" }))
                            |> Enum.join("\n")
                    end)
                _ -> line
            end
        end)
    end

    defp remove_ansi_codes(string), do: String.replace(string, ~r/(\x9b|\x1b\[)[0-?]*[ -\/]*[@-~]/, "")

    defp fixed_width_inputs(ast, inputs \\ [])
    defp fixed_width_inputs(%{ input: [] }, inputs), do: inputs
    defp fixed_width_inputs(ast = %{ __struct__: name }, inputs) when name in [SimpleMarkdown.Attribute.Code, SimpleMarkdown.Attribute.PreformattedCode] do
        [Blueprint.CLI.Renderer.render(ast)|inputs]
    end
    defp fixed_width_inputs(ast = %{}, inputs), do: Enum.reduce(ast.input, inputs, &fixed_width_inputs/2)
    defp fixed_width_inputs(_, inputs), do: inputs

    defp tokenize(tokens, []), do: tokens
    defp tokenize(tokens, [input|inputs]) do
        Enum.reduce(tokens, [], fn
            token, acc when is_tuple(token) -> acc ++ [token]
            string, acc -> acc ++ Enum.intersperse(String.split(string, input), { :fixed, input })
        end)
        |> tokenize(inputs)
    end
end
