defprotocol Liquex.Protocol do
  @fallback_to_any true
  @spec render(t) :: any()
  def render(value)
end

defimpl Liquex.Protocol, for: Any do
  def render(nil), do: ""
  def render(value), do: to_string(value)
end
