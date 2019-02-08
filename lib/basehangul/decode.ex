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
  defp to_ords([@padchr | pairs], acc), do: to_ords(pairs, [-1 | acc])

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
    [x | xs] =
      ords
      |> Enum.map(&if(&1 == -1, do: 0, else: &1))
      |> Enum.reverse()

    n_bytes = get_byte_size(ords)
    last = if n_bytes == 4, do: (x - 1024) <<< 8, else: x

    bigint =
      [last | xs]
      |> Enum.reverse()
      |> Enum.reduce(0, fn ord, acc -> (acc <<< 10) + ord end)

    binary_part(<<bigint::40>>, 0, n_bytes)
  end

  @spec get_byte_size([integer()]) :: integer()
  defp get_byte_size(ords) do
    case Enum.reverse(ords) do
      [ord | _] when ord >= 1024 -> 4
      [-1 | _] = list -> list |> Enum.drop_while(& &1 == -1) |> length()
      list when is_list(list) -> 5
    end
  end
end
