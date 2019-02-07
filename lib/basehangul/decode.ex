defmodule BaseHangul.Decode do
  @moduledoc false

  use Bitwise

  @padchr [0xC8, 0xE5]

  def decode_chunk(x) do
    :iconv.convert("utf-8", "euc-kr", x) |> to_ordlist([]) |> repack_10to8
  end

  defp repack_10to8(ordlist) do
    tmp = Enum.map(ordlist, &if(&1 == false, do: 0, else: &1))
    sz = Enum.find_index(ordlist, &(&1 == false))
    last = List.last(tmp)

    case sz do
      x when is_number(x) or (is_nil(x) and last < 1024) ->
        sz = sz || 5

      _ ->
        sz = 4
        tmp = List.update_at(tmp, 3, &((&1 - 1024) <<< 8))
    end

    bigint = Enum.reduce(tmp, 0, fn x, a -> (a <<< 10) + x end)
    binary_part(<<bigint::40>>, 0, sz)
  end

  defp to_ordlist(<<>>, out), do: out

  defp to_ordlist(eucstr, out) do
    try do
      <<n1, n2>> <> rest = eucstr

      to_ordlist(
        rest,
        out ++
          if [n1, n2] == @padchr do
            [false]
          else
            [get_ord(n1, n2)]
          end
      )
    rescue
      MatchError -> raise ArgumentError, message: "Not a vaild BaseHangul string"
    end
  end

  defp get_ord(n1, n2) do
    num = (n1 - 0xB0) * 94 + (n2 - 0xA1)

    cond do
      num > 1027 or num < 0 ->
        raise ArgumentError, message: "Not a valid BaseHangul string"

      true ->
        num
    end
  end
end
