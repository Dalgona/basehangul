defmodule BaseHangul.Decode do
  @moduledoc false

  use Bitwise

  @padchr [0xC8, 0xE5]

  def decode_chunk(x) do
    euc_bytes = for <<b::8 <- :iconv.convert("utf-8", "euc-kr", x)>>, do: b

    case euc_bytes |> Enum.chunk_every(2) |> to_ords([]) do
      {:ok, ords} -> {:ok, repack_10to8(ords)}
      {:error, _} = error -> error
    end
  end

  @spec to_ords([[integer()]], [integer()]) :: {:ok, [integer()]} | {:error, term()}
  defp to_ords(pairs, acc)
  defp to_ords([], acc), do: {:ok, Enum.reverse(acc)}
  defp to_ords([@padchr | pairs], acc), do: to_ords(pairs, [false | acc])

  defp to_ords([[b1, b2] | pairs], acc) do
    case get_ord(b1, b2) do
      {:ok, ord} -> to_ords(pairs, [ord | acc])
      {:error, _} = error -> error
    end
  end

  defp to_ords(_, _acc), do: {:error, :invalid}

  @spec get_ord(integer(), integer()) :: {:ok, integer()} | {:error, term()}
  defp get_ord(n1, n2) do
    case (n1 - 0xB0) * 94 + (n2 - 0xA1) do
      num when num > 1027 or num < 0 -> {:error, :invalid}
      num -> {:ok, num}
    end
  end

  defp repack_10to8(ords) do
    tmp = Enum.map(ords, &if(&1 == false, do: 0, else: &1))
    sz = Enum.find_index(ords, &(&1 == false))
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
end
