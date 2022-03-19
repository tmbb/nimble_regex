defmodule NimbleRegex.PosixExtended.Compiler do
  import NimbleParsec

  alias NimbleRegex.PosixExtended.Parser

  @spec compile_to_combinator(binary) :: list()
  def compile_to_combinator(binary) do
    regex = Parser.regex!(binary)
    parsed_to_combinator(regex)
  end

  def simplify_alternatives(expression) when is_list(expression) do
    Enum.map(expression, &simplify_alternatives/1)
  end

  def simplify_alternatives({:alternatives, expressions}) do
    new_expressions =
      expressions
      |> Enum.map(&simplify_inner_alternatives/1)
      |> List.flatten()

    {:alternatives, new_expressions}
  end

  def simplify_alternatives(other) do
    other
  end

  defp simplify_inner_alternatives({:alternatives, expressions}) do
    inner = Enum.map(expressions, &simplify_inner_alternatives/1)
    List.flatten(inner)
  end

  defp simplify_inner_alternatives(other) do
    other
  end

  def parsed_to_combinator(expressions) when is_list(expressions) do
    combinators = Enum.map(expressions, &parsed_to_combinator/1)
    concat_many(combinators)
  end

  def parsed_to_combinator({:literal_char, c}) do
    utf8_char([c])
  end

  def parsed_to_combinator({:alternatives, expressions}) do
    combinators = Enum.map(expressions, &parsed_to_combinator/1)
    choice(combinators)
  end

  def parsed_to_combinator({:one_or_more, expression}) do
    combinator = parsed_to_combinator(expression)
    times(combinator, min: 1)
  end

  def parsed_to_combinator({:zero_or_more, expression}) do
    combinator = parsed_to_combinator(expression)
    repeat(combinator)
  end

  def parsed_to_combinator({:zero_or_one, expression}) do
    combinator = parsed_to_combinator(expression)
    optional(combinator)
  end

  def parsed_to_combinator({:exact_number_of_repeats, args}) do
    {count, rest} = Keyword.pop(args, :count)
    [expression] = rest

    combinator = parsed_to_combinator(expression)
    times(combinator, min: count, max: count)
  end

  def parsed_to_combinator({:min_and_max_repeats, args}) do
    {min, rest} = Keyword.pop(args, :min)
    {max, rest} = Keyword.pop(rest, :max)
    [expression] = rest

    combinator = parsed_to_combinator(expression)
    times(combinator, min: min, max: max)
  end

  def parsed_to_combinator({:group, args}) do
    combinator = parsed_to_combinator(args)
    combinator
  end

  def parsed_to_combinator({:utf8_character_class, name}) do
    {:ok, char_ranges} = Unicode.Set.to_utf8_char(name)
    utf8_char(char_ranges)
  end

  def parsed_to_combinator({:pcre_character_class, name}) do
    {:ok, char_ranges} = Unicode.Set.to_utf8_char(name)
    utf8_char(char_ranges)
  end

  defp concat_many(combinators) do
    Enum.reduce(combinators, empty(), fn comb, acc ->
      concat(acc, comb)
    end)
  end
end
