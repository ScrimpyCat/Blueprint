defmodule Blueprint.Application do
    @moduledoc """
      A struct containing contents from an application useful for
      inspecting.
    """

    defstruct [:path, :app, :modules]

    @type app :: { :application, name :: atom, options :: keyword() }
    @type t :: %Blueprint.Application{ path: String.t, app: app, modules: [Blueprint.Application.Module.t] }

    @doc """
      Load the contents of an application at the given path.

      iex> { :application, app, _ } = Blueprint.Application.new(Mix.Project.app_path()).app
      ...> app
      :blueprint
    """
    @spec new(String.t) :: t
    def new(path) do
        ebin_path = Path.join(path, "ebin")

        [app_path] = Path.wildcard(Path.join(ebin_path, "*.app"))
        { :ok, file } = File.open(app_path, [:read])
        { :ok, app } = :io.read(file, '')
        :ok = File.close(file)

        modules =
            Path.wildcard(Path.join(ebin_path, "*.beam"))
            |> Enum.map(&Blueprint.Application.Module.new/1)

        %Blueprint.Application{ path: app_path, app: app, modules: modules }
    end
end
