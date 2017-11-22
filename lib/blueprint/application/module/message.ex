defmodule Blueprint.Application.Module.Message do
    @moduledoc """
      A struct containing contents about a message useful for
      inspecting.
    """

    defstruct [:target, :interface, :args]

    @type t :: %Blueprint.Application.Module.Message{ target: atom, interface: { atom, atom, integer }, args: any }
end
