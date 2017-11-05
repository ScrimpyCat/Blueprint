defmodule Blueprint do
    defstruct [:xref]

    def new(path) do
        { :ok, xref } = :xref.start([])

        File.ls!(path)
        |> Enum.each(fn file ->
            lib = Path.join(path, file)
            if File.dir?(lib) do
                :xref.add_application xref, to_charlist(lib)
            end
        end)

        %Blueprint{ xref: xref }
    end

    def close(%Blueprint{ xref: xref }), do: :xref.stop(xref)
end
