defmodule Blueprint.Application do
    defstruct [:path, :app, :modules]

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
