defmodule Blueprint.Application.Module.Message do
    defstruct [:target, :interface, :args]

    @type t :: %Blueprint.Application.Module.Message{ target: atom, interface: { atom, atom, integer }, args: any }
end
