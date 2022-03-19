defmodule NimbleRegex.PosixExtended.CompilerTest do
  use ExUnit.Case

  alias NimbleRegex.PosixExtended.Parser
  alias NimbleRegex.PosixExtended.Compiler

  import NimbleParsec

  def simplify_result({:ok, result, rest, _, _, _}), do: {:ok, to_string(result), rest}
  def simplify_result({:error, _result, _rest, _, _, _}), do: :error

  test "simplify" do
    parsed = Parser.regex!("a|b|c")

    assert Compiler.simplify_alternatives(parsed) == [
             alternatives: [
               literal_char: ?a,
               literal_char: ?b,
               literal_char: ?c
             ]
           ]
  end

  defparsec(:comb1, Compiler.parsed_to_combinator("a|b|c"))

  test "example - comb1" do
    assert comb1("a") |> simplify_result() == {:ok, "a", ""}
    assert comb1("b") |> simplify_result() == {:ok, "b", ""}
    assert comb1("c") |> simplify_result() == {:ok, "c", ""}
    assert comb1("x") |> simplify_result() == :error
    assert comb1("xy") |> simplify_result() == :error
  end

  defparsec(:comb2, Compiler.compile_to_combinator("(ax)|b|c"))

  test "example - comb2" do
    assert comb2("a") |> simplify_result() == :error
    assert comb2("b") |> simplify_result() == {:ok, "b", ""}
    assert comb2("c") |> simplify_result() == {:ok, "c", ""}
    assert comb2("ax") |> simplify_result() == {:ok, "ax", ""}
  end

  defparsec(:comb3, Compiler.compile_to_combinator("ax|b"))

  test "example - comb3" do
    assert comb3("a") |> simplify_result() == :error
    assert comb3("ax") |> simplify_result() == {:ok, "ax", ""}
    assert comb3("ab") |> simplify_result() == {:ok, "ab", ""}
    assert comb3("b") |> simplify_result() == :error
  end

  defparsec(:comb4, Compiler.compile_to_combinator("[[:word:]]+"))

  test "example - comb4" do
    assert comb4("ábç") |> simplify_result() == {:ok, "ábç", ""}
  end
end
