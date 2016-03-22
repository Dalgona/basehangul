defmodule BaseHangul do
  use Bitwise

  @padchr [0xc8, 0xe5]

  def encode(indev, outdev \\ Process.group_leader()) do
    strm = IO.binstream indev, 5
    Enum.each strm, fn x ->
      IO.write(outdev, :iconv.convert("euc-kr", "utf-8", x |> repack_8to10 |> to_euclist([])))
    end
  end

  def decode(indev, outdev \\ Process.group_leader()) do
    strm = IO.binstream indev, 12
    Enum.each strm, fn x ->
      IO.write(outdev, :iconv.convert("utf-8", "euc-kr", x) |> to_ordlist([]) |> repack_10to8)
    end
  end

  defp repack_8to10(bin) when byte_size(bin) <= 5 do
    sz = byte_size bin
    zpad = 8 * (5 - sz)
    <<bignum::40>> = bin <> <<0::size(zpad)>>
    {(bignum |> repack_8to10_rev([]) |> Enum.reverse), sz}
  end

  defp to_euclist({list, sz}, out) when length(list) > 0 do
    [h|t] = list
    case length(list) do
      4 -> to_euclist({t, sz}, out ++ get_euc(h))
      1 ->
        out ++ (if h == 0 and sz < 4 do @padchr
        else (if sz == 4, do: get_euc(bor(h >>> 8, 1024)), else: get_euc(h)) end)
      _ ->
        to_euclist({t, sz}, out ++ (
          if h == 0 and sz <= (4 - length(list)) do @padchr else get_euc(h) end
        ))
    end
  end

  defp to_ordlist(<<>>, out), do: out
  defp to_ordlist(eucstr, out) do
    <<n1, n2>> <> rest = eucstr
    to_ordlist(rest, out ++ (if [n1, n2] == @padchr do [false] else [get_ord(n1, n2)] end))
  end

  defp repack_10to8(ordlist) do
    tmp = Enum.map ordlist, &(if &1 == false, do: 0, else: &1)
    sz = Enum.find_index ordlist, &(&1==false)
    last = List.last tmp
    case sz do
      x when is_number(x) or (is_nil(x) and last < 1024) ->
        sz = sz || 5
      _ ->
        sz = 4
        tmp = List.update_at tmp, 3, &((&1 - 1024) <<< 8)
    end
    bigint = Enum.reduce(tmp, 0, fn(x, a) -> (a <<< 10) + x end)
    binary_part <<bigint::40>>, 0, sz
  end

  defp repack_8to10_rev(0, list) when length(list) == 4, do: list
  defp repack_8to10_rev(n, list), do: repack_8to10_rev(n >>> 10, list ++ [n &&& 0x3FF])

  defp get_euc(ord), do: [0xb0 + div(ord, 94), 0xa1 + rem(ord, 94)]
  defp get_ord(n1, n2), do: (n1 - 0xb0) * 94 + (n2 - 0xa1)
end
