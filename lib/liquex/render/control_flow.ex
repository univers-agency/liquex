defmodule Liquex.Render.ControlFlow do
  @moduledoc """
  Renders out control blocks such as if, unless, and case
  """

  alias Liquex.Argument
  alias Liquex.Expression

  def render([{tag_name, _} | _] = tag, context) when tag_name in [:if, :unless, :case],
    do: do_render(tag, context)

  defp do_render(list, context, match \\ nil)

  defp do_render([{tag, [expression: expression, contents: contents]} | tail], context, _)
       when tag in [:if, :elsif] do
    if Expression.eval(expression, context) do
      Liquex.render(contents, context)
    else
      do_render(tail, context)
    end
  end

  defp do_render([{:unless, [expression: expression, contents: contents]} | tail], context, _) do
    if Expression.eval(expression, context) do
      do_render(tail, context)
    else
      Liquex.render(contents, context)
    end
  end

  defp do_render([{:else, [contents: contents]} | _tail], context, _),
    do: Liquex.render(contents, context)

  defp do_render([{:case, argument} | tail], context, _) do
    match = Argument.eval(argument, context)
    do_render(tail, context, match)
  end

  defp do_render([], context, _), do: {[], context}

  defp do_render([{:when, [expression: expression, contents: contents]} | tail], context, match) do
    if Argument.eval(expression, context) == match do
      Liquex.render(contents, context)
    else
      do_render(tail, context, match)
    end
  end
end