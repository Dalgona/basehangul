defmodule BaseHangul do
  use Bitwise
  :iconv.load_nif

  defp padchr, do: [0xc8, 0xe5]

  def encode(binary) when is_binary(binary) do
    {:ok, sio} = StringIO.open binary
    sio |> encode
  end

  def encode(indev, outdev \\ Process.group_leader()) do
    strm = IO.binstream indev, 5
    Enum.each strm, fn x ->
      IO.write(
        outdev,
        :iconv.convert("euc-kr", "utf-8", x |> repack_bits |> get_euclist([]))
      )
    end
  end

  defp repack_bits(bin) when byte_size(bin) <= 5 do
    sz = byte_size bin
    {for(<<x <- (bin <> String.duplicate("\0", 5 - sz))>>, do: x)
       |> Enum.reduce(0, fn(x, acc) -> (acc <<< 8) + x end)
       |> repack_rev([])
       |> Enum.reverse, sz}
  end

  defp get_euclist({list, sz}, out) when length(list) > 0 do
    [h|t] = list
    case length(list) do
      4 -> get_euclist({t, sz}, out ++ get_euc(h))
      1 ->
        out ++ (if h == 0 and sz < 4 do padchr
        else
          if sz == 4, do: get_euc(bor(h >>> 8, 1024)), else: get_euc(h)
        end)
      _ ->
        get_euclist({t, sz}, out ++ (
          if h == 0 and sz <= (4 - length(list)) do padchr
          else get_euc(h) end
        ))
    end
  end

  defp repack_rev(0, list) when length(list) == 4, do: list
  defp repack_rev(n, list), do: repack_rev(n >>> 10, list ++ [n &&& 0x3FF])
  defp get_euc(ord), do: [0xb0 + div(ord, 94), 0xa1 + rem(ord, 94)]
end
