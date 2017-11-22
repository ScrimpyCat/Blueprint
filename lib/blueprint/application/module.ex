defmodule Blueprint.Application.Module do
    @moduledoc """
      A struct containing contents from a BEAM module useful for
      inspecting.
    """

    defstruct [path: nil, beam: nil, name: nil, messages: [], server: nil]

    @type server :: { :named, atom } | nil
    @type t :: %Blueprint.Application.Module{ path: String.t, beam: binary, name: atom, messages: [Blueprint.Application.Module.Message.t], server: server }

    @server_behaviours [GenServer, GenEvent, GenStage, :gen_event, :gen_fsm, :gen_server, :gen_statem, :gen]
    @server_behaviours_sends [:call, :cast]
    defp messages(code, messages \\ [])
    defp messages({ :call, _, { :remote, _, { :atom, _, module }, { :atom, _, fun } }, args = [{ :atom, _ , server }|_] }, messages) when module in @server_behaviours and fun in @server_behaviours_sends do
        [%Blueprint.Application.Module.Message{
            target: server,
            interface: { module, fun, length(args) },
            args: args #TODO: format
        }|messages]
    end
    defp messages([h|t], messages), do: messages(t, messages(h, messages))
    defp messages(code, messages) when is_tuple(code), do: messages(Tuple.to_list(code), messages)
    defp messages(_, messages), do: messages

    @doc """
      Load the contents of a module at the given path.

      iex> Blueprint.Application.Module.new(Path.join(Mix.Project.app_path(), "ebin/Elixir.Blueprint.Application.Module.beam")).name
      Blueprint.Application.Module
    """
    @spec new(String.t) :: t
    def new(path) do
        { :ok, beam } = File.read(path)
        { :ok, { mod, [atoms: atoms] } } = :beam_lib.chunks(beam, [:atoms])
        if Enum.any?(atoms, fn
            { _, module } when module in @server_behaviours -> true
            _ -> false
        end) do
            { :ok, { _, chunks } } = :beam_lib.chunks(beam, [:attributes, :abstract_code])

            server = if Enum.any?(chunks[:attributes], fn
                { :behaviour, behaviours } -> GenServer in behaviours
                _ -> false
            end) do
                #TODO: Workout whether it is a named server, and what that name is
                { :named, mod }
            end

            messages = case chunks[:abstract_code] do
                { :raw_abstract_v1, code } -> messages(code)
                _ -> []
            end

            %Blueprint.Application.Module{ path: path, beam: beam, name: mod, server: server, messages: messages }
        else
            %Blueprint.Application.Module{ path: path, beam: beam, name: mod }
        end
    end
end
