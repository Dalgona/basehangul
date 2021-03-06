defmodule BaseHangul do
  @moduledoc ~S"""
  This module provides BaseHangul encoding/decoding functionalities.

  Visit the [GitHub Page](https://github.com/dalgona/basehangul)
  for more information.
  """

  alias BaseHangul.{Encode, Decode}

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
    euc_list =
      input
      |> chunk_binary(5)
      |> Task.async_stream(&Encode.encode_chunk/1)
      |> Stream.map(&elem(&1, 1))
      |> Enum.to_list()

    :iconv.convert("euc-kr", "utf-8", euc_list)
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

  @spec decode(binary()) :: binary()
  def decode(input) when is_binary(input) do
    euc_bin = :iconv.convert("utf-8", "euc-kr", input)

    euc_bin
    |> chunk_binary(8)
    |> Task.async_stream(&Decode.decode_chunk/1)
    |> Enum.map(&elem(&1, 1))
    |> aggregate([])
    |> case do
      {:ok, binaries} -> {:ok, Enum.join(binaries, "")}
      {:error, _} = error -> error
    end
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

  @spec aggregate([{:ok, binary()} | {:error, term()}], [binary()]) ::
          {:ok, [binary()]} | {:error, term()}
  defp aggregate(results, acc)

  defp aggregate([], acc), do: {:ok, Enum.reverse(acc)}
  defp aggregate([{:error, _} = error | _], _acc), do: error
  defp aggregate([{:ok, x} | results], acc), do: aggregate(results, [x | acc])
end
