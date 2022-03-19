defmodule NimbleRegex.ParserHelpers do
  import NimbleParsec

  @whitespace utf8_string(' \t\n\r\f', min: 1)

  def sequence([first_combinator | combinators], opts \\ []) do
    skip = Keyword.get(opts, :skip, @whitespace)

    Enum.reduce(combinators, first_combinator, fn comb, acc ->
      acc
      |> ignore(optional(skip))
      |> concat(comb)
    end)
  end

  @doc false
  def chain_and_tag_helper(rest, args, context, _line, _offset) do
    [expression_tag | rest_of_args] = args

    new_args =
      case expression_tag do
        nil ->
          rest_of_args

        _ ->
          [{expression_tag, Enum.reverse(rest_of_args)}]
      end

    {rest, new_args, context}
  end

  def chain_and_tag(combinator \\ empty(), expression_head, expression_tails) do
    suffix_branches =
      for {combinator, combinator_tag} <- expression_tails do
        combinator |> replace(empty(), combinator_tag)
      end

    full_parser =
      combinator
      |> concat(expression_head)
      |> choice(suffix_branches)

    post_traverse(full_parser, {__MODULE__, :chain_and_tag_helper, []})
  end
end

defmodule NimbleRegex.PosixExtended.Parser do
  import NimbleParsec
  import NimbleRegex.ParserHelpers

  start_of_string = ignore(string("^")) |> tag(:start_of_string)

  end_of_string = ignore(string("$")) |> tag(:end_of_string)

  unicode_character_class =
    string("[[")
    |> repeat(lookahead_not(string("]]")) |> utf8_char([]))
    |> string("]]")
    |> reduce({:to_string, []})
    |> unwrap_and_tag(:utf8_character_class)

  inclusive_bracket =
    ignore(string("["))
    |> times(ascii_char(not: ?]), min: 1)
    |> ignore(string("]"))
    |> tag(:inclusive_bracket)

  exclusive_bracket =
    ignore(string("[^"))
    |> times(utf8_char(not: ?]), min: 1)
    |> ignore(string("]"))
    |> tag(:exclusive_bracket)

  simple_char = Enum.map('[]^+-.$\\()|{}', fn c -> {:not, c} end)

  literal_char = utf8_char(simple_char) |> unwrap_and_tag(:literal_char)

  integer = utf8_string('0123456789', min: 1) |> map({String, :to_integer, []})

  exact_number_of_repeats =
    sequence([
      ignore(string("{")),
      unwrap_and_tag(integer, :count),
      ignore(string("}"))
    ])

  min_and_max_repeats =
    sequence([
      ignore(string("{")),
      unwrap_and_tag(integer, :min),
      ignore(string(",")),
      unwrap_and_tag(integer, :max),
      ignore(string("}"))
    ])

  group =
    ignore(string("("))
    |> repeat(parsec(:expression_parsec))
    |> ignore(string(")"))
    |> tag(:group)

  start_of_expr =
    choice([
      unicode_character_class,
      exclusive_bracket,
      inclusive_bracket,
      literal_char,
      group
    ])

  expression1 =
    start_of_expr
    |> chain_and_tag([
      {ignore(string("+")), :one_or_more},
      {ignore(string("*")), :zero_or_more},
      {ignore(string("?")), :zero_or_one},
      {exact_number_of_repeats, :exact_nr_of_repeats},
      {min_and_max_repeats, :min_and_max_repeats},
      {ignore(empty()), nil}
    ])

  expression =
    expression1
    |> chain_and_tag([
      {ignore(string("|")) |> parsec(:expression_parsec), :alternatives},
      {ignore(empty()), nil}
    ])

  defparsecp(:expression_parsec, expression)

  regex =
    optional(start_of_string)
    |> repeat(expression)
    |> optional(end_of_string)
    |> eos()

  defparsec(:regex_parsec, regex)

  def regex!(text) do
    {:ok, parsed, "", _, _, _} = regex_parsec(text)
    parsed
  end
end
