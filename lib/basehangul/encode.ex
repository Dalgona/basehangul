defmodule BaseHangul.Encode do
  @moduledoc false

  use Bitwise

  @padchr [0xC8, 0xE5]

  @spec encode_chunk(binary()) :: binary()
  def encode_chunk(x) do
    {tbits, n_bytes} = repack_8to10(x)
    euc_list = to_euclist(tbits, n_bytes, [])

    :iconv.convert("euc-kr", "utf-8", euc_list)
  end

  @spec repack_8to10(binary()) :: {[integer()], integer()}
  defp repack_8to10(bin) when byte_size(bin) <= 5 do
    size = byte_size(bin)
    pad_size = 8 * (5 - size)
    padded = bin <> <<0::size(pad_size)>>
    tbit_packed = for <<tbit::10 <- padded>>, do: tbit

    {tbit_packed, size}
  end

  @spec to_euclist([integer()], integer(), [integer()]) :: [integer()]
  defp to_euclist(ords, n_bytes, acc)

  defp to_euclist([], _n_bytes, acc) do
    acc |> Enum.reverse() |> List.flatten()
  end

  defp to_euclist([ord], n_bytes, acc) do
    euc =
      cond do
        ord == 0 and n_bytes < 4 -> @padchr
        n_bytes == 4 -> get_euc(ord >>> 8 ||| 1024)
        :else -> get_euc(ord)
      end

    to_euclist([], n_bytes, [euc | acc])
  end

  defp to_euclist([ord | ords] = list, n_bytes, acc) do
    euc =
      if ord == 0 and n_bytes <= 4 - length(list) do
        @padchr
      else
        get_euc(ord)
      end

    to_euclist(ords, n_bytes, [euc | acc])
  end

  @spec get_euc(integer()) :: [integer()]
  defp get_euc(ord) when ord <= 1027 do
    [0xB0 + div(ord, 94), 0xA1 + rem(ord, 94)]
  end
end
