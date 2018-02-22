defmodule Blueprint.Application.Module do
    @moduledoc """
      A struct containing contents from a BEAM module useful for
      inspecting.

      By default messages will only be found when servers explicitly
      match. This however can be extended by providing custom server
      matching expressions in the config under the `:servers` key.

      ## Server Match Expressions

      Server match expression should take the form of `{ match, server }`,
      where `match` is the expression to be matched with (against the
      function calls server arg), and `server` is the resulting target
      server.

      The `:servers` key should have a string of the the list of server
      match expressions.

      An example of this could be:

        config :blueprint,
            servers: ~S([
                { { :tuple, _, [{ :atom, _, s }, { :atom, _, :"foo@127.0.0.1" }] }, s }, \# match against a named node, and return whatever server name is bound to 's'
                { { :call, _, { :atom, _, :get_server }, [] }, Foo }, \# match against a get_server/0 function and return Foo as the server
                { _, Bar } \# match any argument and return Bar as the server
            ])
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
    defp messages({ :call, _, { :remote, _, { :atom, _, module }, { :atom, _, fun } }, args = [server_arg|_] }, messages) when module in @server_behaviours and fun in @server_behaviours_sends do
        Application.get_env(:blueprint, :servers, "[]")
        |> Code.string_to_quoted!
        |> Enum.find_value(messages, fn { match, server } ->
            try do
                { server, _ } =
                    quote do
                        case var!(arg) do
                            unquote(match) -> unquote(server)
                        end
                    end
                    |> Code.eval_quoted([arg: server_arg])

                [%Blueprint.Application.Module.Message{
                    target: server,
                    interface: { module, fun, length(args) },
                    args: args #TODO: format
                }|messages]
            rescue
                _ -> nil
            end
        end)
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
