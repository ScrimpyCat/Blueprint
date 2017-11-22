defmodule Blueprint.Plot.Style do
    defp value(c) do
        cond do
            c >= ?a and c <= ?z -> (c - ?a) + 1
            c >= ?A and c <= ?Z -> (c - ?A) + 1
            true -> 0
        end
    end

    @spec colourize(String.t) :: String.t
    def colourize(name) do
        hue = round((case to_charlist(name) do
            [c1, c2|_] -> (value(c1) * 26) + value(c2)
            [c1] -> value(c1) * 26
        end) / 2.1125)

        n =
            round(((60 - abs(60 - rem(hue, 120))) / 60) * 255)
            |> Integer.to_string(16)
            |> String.pad_leading(2, "0")

        case round(:math.floor(hue / 60)) do
            0 -> "#ff#{n}00"
            1 -> "##{n}ff00"
            2 -> "#00ff#{n}"
            3 -> "#00#{n}ff"
            4 -> "##{n}00ff"
            5 -> "#ff00#{n}"
            _ -> "#000000"
        end
    end
end
