defmodule Blueprint do
    @moduledoc """
      A blueprint represents a collection of applications that
      are used to understand how they work together.
    """

    defstruct [:xref, :apps]

    @type t :: %Blueprint{ xref: pid, apps: [Blueprint.Application.t] }

    defp load_app(xref, path, apps) do
        case :xref.add_application(xref, to_charlist(path)) do
            { :ok, _ } -> [Blueprint.Application.new(path)|apps]
            _ -> apps
        end
    end

    defp add_app(xref, paths, apps \\ [])
    defp add_app(_, [], apps), do: apps
    defp add_app(xref, lib, apps) when is_atom(lib), do: load_app(xref, to_string(:code.lib_dir(lib)), apps)
    defp add_app(xref, path, apps) when is_binary(path) do
        if File.exists?(Path.join(path, "ebin")) do
            load_app(xref, path, apps)
        else
            Path.wildcard(Path.join(path, "*/ebin"))
            |> Enum.reduce(apps, fn ebin, apps ->
                length = round((bit_size(ebin) / 8) - 4)
                <<lib :: binary-size(length), "ebin">> = ebin

                if File.dir?(lib) do
                    load_app(xref, lib, apps)
                else
                    apps
                end
            end)
        end
    end
    defp add_app(xref, [h|t], apps), do: add_app(xref, t, add_app(xref, h, apps))

    @doc """
      Create a new blueprint.

      Blueprints will represent any applications that are
      added to them. Atoms are interpreted as library names,
      while strings are expected to be valid paths to either
      a library or a collection of libraries.
    """
    @spec new(atom | String.t | [atom | String.t]) :: Blueprint.t
    def new(path) do
        { :ok, xref } = :xref.start([])

        %Blueprint{ xref: xref, apps: add_app(xref, path) }
    end

    @doc """
      Close an active blueprint.
    """
    @spec close(Blueprint.t) :: :ok
    def close(%Blueprint{ xref: xref }) do
        :xref.stop(xref)
        :ok
    end
end
