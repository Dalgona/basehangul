defmodule BaseHangul do
  @moduledoc ~S"""
  This module provides BaseHangul encoding/decoding functionalities.

  Visit the [GitHub Page](https://github.com/dalgona/basehangul)
  for more information.
  """

  use Bitwise

  @padchr [0xC8, 0xE5]

  @doc ~S"""
  Encodes `input` to a BaseHangul string. `input` can be a string or a binary.

  Returns a BaseHangul-encoded string on success.

  ## Examples

      iex> BaseHangul.encode("Hello")
      "낏뗐맸굉"
      iex> BaseHangul.encode(<<1, 2, 3, 4, 5>>)
      "갈걍꺅갉"

  """
  @spec encode(binary()) :: binary()
  def encode(input) when is_binary(input) do
    {:ok, sio} = StringIO.open(input)
    Stream.map(IO.binstream(sio, 5), &encunit(&1)) |> Enum.join("")
  end

  @doc ~S"""
  Decodes BaseHangul-encoded string `input`.

  Returns the decoded result as a string or a binary.

  ## Examples

      iex> BaseHangul.decode("낏뗐맸굉")
      "Hello"
      iex> BaseHangul.decode("갈걍꺅갉")
      <<1, 2, 3, 4, 5>>

  ## Notes

  This function expects a UTF-8 encoded text.
  Passing an invalid BaseHangul-encoded string as an input will result in an
  undefined behavior.

  """
  def decode(input) when is_binary(input) do
    {:ok, sio} = StringIO.open(input)
    Stream.map(IO.binstream(sio, 12), &decunit(&1)) |> Enum.join("")
  end

  defp encunit(x), do: :iconv.convert("euc-kr", "utf-8", x |> repack_8to10 |> to_euclist([]))
  defp decunit(x), do: :iconv.convert("utf-8", "euc-kr", x) |> to_ordlist([]) |> repack_10to8

  defp repack_8to10(bin) when byte_size(bin) <= 5 do
    sz = byte_size(bin)
    zpad = 8 * (5 - sz)
    <<bignum::40>> = bin <> <<0::size(zpad)>>
    {bignum |> repack_8to10_rev([]) |> Enum.reverse(), sz}
  end

  defp to_euclist({list, sz}, out) when length(list) > 0 do
    [h | t] = list

    case length(list) do
      4 ->
        to_euclist({t, sz}, out ++ get_euc(h))

      1 ->
        out ++
          if h == 0 and sz < 4 do
            @padchr
          else
            if sz == 4, do: get_euc(bor(h >>> 8, 1024)), else: get_euc(h)
          end

      _ ->
        to_euclist(
          {t, sz},
          out ++
            if h == 0 and sz <= 4 - length(list) do
              @padchr
            else
              get_euc(h)
            end
        )
    end
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

  defp repack_8to10_rev(0, list) when length(list) == 4, do: list
  defp repack_8to10_rev(n, list), do: repack_8to10_rev(n >>> 10, list ++ [n &&& 0x3FF])

  defp get_euc(ord) do
    cond do
      ord > 1027 -> raise ArgumentError, message: "Character ordinal out of range"
      true -> [0xB0 + div(ord, 94), 0xA1 + rem(ord, 94)]
    end
  end

  defp get_ord(n1, n2) do
    num = (n1 - 0xB0) * 94 + (n2 - 0xA1)

    cond do
      num > 1027 or num < 0 -> raise ArgumentError, message: "Not a valid BaseHangul string"
      true -> num
    end
  end
end
