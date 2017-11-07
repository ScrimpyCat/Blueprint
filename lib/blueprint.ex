defmodule Blueprint do
    defstruct [:xref]

    defp add_app(_, []), do: :ok
    defp add_app(xref, lib) when is_atom(lib), do: { :ok, _ } = :xref.add_application(xref, :code.lib_dir(lib))
    defp add_app(xref, path) when is_binary(path) do
        if File.exists?(Path.join(path, "ebin")) do
            { :ok, _ } = :xref.add_application(xref, to_charlist(path))
        else
            Path.wildcard(Path.join(path, "*/ebin"))
            |> Enum.each(fn ebin ->
                length = round((bit_size(ebin) / 8) - 4)
                <<lib :: binary-size(length), "ebin">> = ebin

                if File.dir?(lib) do
                    { :ok, _ } = :xref.add_application(xref, to_charlist(lib))
                end
            end)
        end
    end
    defp add_app(xref, [h|t]) do
        add_app(xref, h)
        add_app(xref, t)
    end

    def new(path) do
        { :ok, xref } = :xref.start([])

        add_app(xref, path)

        %Blueprint{ xref: xref }
    end

    def close(%Blueprint{ xref: xref }), do: :xref.stop(xref)
end
