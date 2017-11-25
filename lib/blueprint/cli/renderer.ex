defprotocol Blueprint.CLI.Renderer do
    @fallback_to_any true
    def render(ast)
end

defimpl Blueprint.CLI.Renderer, for: Any do
    def render(%{ input: input }) do
        Blueprint.CLI.Renderer.render(input)
    end
end

defimpl Blueprint.CLI.Renderer, for: List do
    def render(ast) do
        Enum.map(ast, &Blueprint.CLI.Renderer.render/1)
        |> Enum.join(" ")
    end
end

defimpl Blueprint.CLI.Renderer, for: BitString do
    def render(string), do: String.trim(string)
end

defimpl Blueprint.CLI.Renderer, for: SimpleMarkdown.Attribute.LineBreak do
    def render(_), do: "\n"
end

defimpl Blueprint.CLI.Renderer, for: SimpleMarkdown.Attribute.Header do
    def render(%{ input: input, option: size }), do: IO.ANSI.bright <> Blueprint.CLI.Renderer.render(input) <> IO.ANSI.reset
end

defimpl Blueprint.CLI.Renderer, for: SimpleMarkdown.Attribute.PreformattedCode do
    def render(%{ input: input }), do: "\n    " <> IO.ANSI.cyan <> Blueprint.CLI.Renderer.render(input) <> IO.ANSI.reset <> "\n\n"
end

defimpl Blueprint.CLI.Renderer, for: SimpleMarkdown.Attribute.Paragraph do
    def render(%{ input: input }), do: String.trim(Blueprint.CLI.Renderer.render(input)) <> "\n\n"
end

defimpl Blueprint.CLI.Renderer, for: SimpleMarkdown.Attribute.Code do
    def render(%{ input: input }), do: IO.ANSI.cyan <> Blueprint.CLI.Renderer.render(input) <> IO.ANSI.reset
end
