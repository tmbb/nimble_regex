defmodule NimbleRegex.Benchmarks.Speed do
  import NimbleParsec

  alias NimbleRegex.PosixExtended.Compiler

  defparsec(:comb1, Compiler.compile_to_combinator("ab+123"))

  def run() do
    example_regex = ~r/^ab+123$/
    inputs = %{
      "that matches" => "abbbb123",
      "that doesn't match" => "axx123"
    }

    Benchee.run(%{
      "regex" => fn input -> Regex.match?(example_regex, input) end,
      "combinator" => fn input -> comb1(input) end
    }, inputs: inputs)
  end
end

NimbleRegex.Benchmarks.Speed.run()
