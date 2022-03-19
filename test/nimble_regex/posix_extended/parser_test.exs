defmodule NimbleRegex.PosixExtended.ParserTest do
  use ExUnit.Case

  alias NimbleRegex.PosixExtended.Parser

  test "start of string" do
    assert Parser.regex!("^") == [start_of_string: []]
  end

  test "inclusive brackets" do
    assert Parser.regex!("[abc]") == [inclusive_bracket: 'abc']
  end

  test "exlusive brackets" do
    assert Parser.regex!("[^abc]") == [exclusive_bracket: 'abc']
  end

  test "group" do
    assert Parser.regex!("(a)") == [group: [literal_char: ?a]]
  end

  test "complex group" do
    assert Parser.regex!("(a[^b])") == [group: [literal_char: ?a, exclusive_bracket: 'b']]
  end

  test "nested group" do
    assert Parser.regex!("((a)((b)c)(((d)e)f))") == [
             group: [
               group: [literal_char: ?a],
               group: [
                 group: [literal_char: ?b],
                 literal_char: ?c
               ],
               group: [
                 group: [
                   group: [literal_char: ?d],
                   literal_char: ?e
                 ],
                 literal_char: ?f
               ]
             ]
           ]
  end

  test "left or right" do
    assert Parser.regex!("a|b") == [alternatives: [literal_char: ?a, literal_char: ?b]]
  end

  test "left or right - multiple" do
    assert Parser.regex!("a|b|c") == [
             alternatives: [
               literal_char: ?a,
               alternatives: [
                 literal_char: ?b,
                 literal_char: ?c
               ]
             ]
           ]
  end

  test "exact repeats" do
    assert Parser.regex!("a{3}") == [
             exact_nr_of_repeats: [
               literal_char: ?a,
               count: 3
             ]
           ]
  end

  test "exact repeats - ensure whitespace insensitivity" do
    assert Parser.regex!("a{ 3}") == [
             exact_nr_of_repeats: [
               literal_char: ?a,
               count: 3
             ]
           ]
  end

  test "min and max repeats" do
    assert Parser.regex!("a{2,5}") == [
             min_and_max_repeats: [
               literal_char: ?a,
               min: 2,
               max: 5
             ]
           ]
  end

  test "unicode character class" do
    assert Parser.regex!("[[:word:]]") == [
             utf8_character_class: "[[:word:]]"
           ]
  end
end
