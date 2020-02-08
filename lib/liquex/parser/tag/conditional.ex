defmodule Liquex.Parser.Tag.Conditional do
  import NimbleParsec

  alias Liquex.Parser.Tag
  alias Liquex.Parser.Literal

  @spec boolean_expression(NimbleParsec.t()) :: NimbleParsec.t()
  def boolean_expression(combinator \\ empty()) do
    operator =
      choice([
        string("=="),
        string("!="),
        string(">="),
        string("<="),
        string(">"),
        string("<"),
        string("contains")
      ])
      |> map({String, :to_existing_atom, []})

    boolean_operator =
      choice([
        replace(string("and"), :and),
        replace(string("or"), :or)
      ])

    boolean_operation =
      tag(Literal.argument(), :left)
      |> ignore(Literal.whitespace())
      |> unwrap_and_tag(operator, :op)
      |> ignore(Literal.whitespace())
      |> tag(Literal.argument(), :right)
      |> wrap()

    combinator
    |> choice([boolean_operation, Literal.literal(), Literal.argument()])
    |> ignore(Literal.whitespace())
    |> repeat(
      boolean_operator
      |> ignore(Literal.whitespace())
      |> choice([boolean_operation, Literal.literal(), Literal.argument()])
    )
  end

  @spec if_expression(NimbleParsec.t()) :: NimbleParsec.t()
  def if_expression(combinator \\ empty()) do
    if_tag =
      empty()
      |> expression_tag("if")
      |> tag(parsec(:document), :contents)

    combinator
    |> tag(if_tag, :if)
    |> repeat(elsif_tag())
    |> optional(else_tag())
    |> ignore(Tag.tag_directive("endif"))
  end

  @spec unless_expression(NimbleParsec.t()) :: NimbleParsec.t()
  def unless_expression(combinator \\ empty()) do
    combinator
    |> unless_tag()
    |> repeat(elsif_tag())
    |> optional(else_tag())
    |> ignore(Tag.tag_directive("endunless"))
  end

  @spec case_expression(NimbleParsec.t()) :: NimbleParsec.t()
  def case_expression(combinator \\ empty()) do
    when_tag =
      ignore(string("{%"))
      |> ignore(Literal.whitespace())
      |> ignore(string("when"))
      |> ignore(Literal.whitespace(empty(), 1))
      |> tag(Literal.literal(), :expression)
      |> ignore(Literal.whitespace())
      |> ignore(string("%}"))
      |> tag(parsec(:document), :contents)

    case_tag =
      ignore(string("{%"))
      |> ignore(Literal.whitespace())
      |> ignore(string("case"))
      |> ignore(Literal.whitespace(empty(), 1))
      |> concat(Literal.argument())
      |> ignore(Literal.whitespace())
      |> ignore(string("%}"))

    combinator
    |> tag(case_tag, :case)
    |> ignore(Literal.whitespace())
    |> times(tag(when_tag, :when), min: 1)
    |> optional(else_tag())
    |> ignore(Tag.tag_directive("endcase"))
  end

  def else_tag(combinator \\ empty()) do
    combinator
    |> ignore(Tag.tag_directive("else"))
    |> tag(parsec(:document), :contents)
    |> tag(:else)
  end

  defp unless_tag(combinator) do
    combinator
    |> expression_tag("unless")
    |> tag(parsec(:document), :contents)
    |> tag(:unless)
  end

  defp elsif_tag(combinator \\ empty()) do
    combinator
    |> expression_tag("elsif")
    |> tag(parsec(:document), :contents)
    |> tag(:elsif)
  end

  @spec expression_tag(NimbleParsec.t(), String.t()) :: NimbleParsec.t()
  defp expression_tag(combinator, tag_name) do
    combinator
    |> ignore(string("{%"))
    |> ignore(Literal.whitespace())
    |> ignore(string(tag_name))
    |> ignore(Literal.whitespace())
    |> tag(boolean_expression(), :expression)
    |> ignore(Literal.whitespace())
    |> ignore(string("%}"))
  end
end