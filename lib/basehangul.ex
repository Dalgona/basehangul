defmodule BaseHangul do
  @moduledoc ~S"""
  This module provides BaseHangul encoding/decoding functionalities.

  Visit the [GitHub Page](https://github.com/dalgona/basehangul)
  for more information.
  """

  use Bitwise
  alias BaseHangul.Encode

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
    input
    |> chunk_binary(5)
    |> Task.async_stream(&Encode.encode_chunk/1)
    |> Stream.map(&elem(&1, 1))
    |> Enum.join("")
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

  #
  # Internal Functions
  #

  @spec chunk_binary(binary(), pos_integer()) :: Enumerable.t()
  defp chunk_binary(binary, chunk_size) do
    Stream.resource(
      fn -> binary end,
      fn
        "" ->
          {:halt, ""}

        bin when byte_size(bin) < chunk_size ->
          {[bin], ""}

        bin ->
          <<chunk::binary-size(chunk_size), rest::binary>> = bin
          {[chunk], rest}
      end,
      fn _ -> :ok end
    )
  end

  defp decunit(x) do
    :iconv.convert("utf-8", "euc-kr", x) |> to_ordlist([]) |> repack_10to8
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

  defp get_ord(n1, n2) do
    num = (n1 - 0xB0) * 94 + (n2 - 0xA1)

    cond do
      num > 1027 or num < 0 -> raise ArgumentError, message: "Not a valid BaseHangul string"
      true -> num
    end
  end
end
