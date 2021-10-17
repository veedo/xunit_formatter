defprotocol XUnitFormatter.XUnitXML do
  @fallback_to_any true
  def element_name(data)
  def attributes(data)
  def content(data)
  def child_elements(data)
  def xunit_xml(data)
end

defimpl XUnitFormatter.XUnitXML, for: Any do
  alias XUnitFormatter.XUnitXML

  defp map_key_to_xml_key({k, v}),
    do: {to_string(k) |> String.replace("_", "-") |> String.to_atom(), v}

  defp attribute_value_to_xml({k, v}) when is_struct(v), do: {k, XUnitXML.xunit_xml(v)}
  defp attribute_value_to_xml(attr), do: attr
  def attribute_empty?({_k, v}), do: is_nil(v) or v == %{} or v == "" or v == ''
  def element_name(data), do: data.__struct__
  def content(_data), do: []
  def child_elements(_), do: []

  def attributes(data) do
    data
    |> Map.from_struct()
    |> Map.drop(XUnitXML.child_elements(data))
    |> Enum.reject(&attribute_empty?/1)
    |> Enum.map(&map_key_to_xml_key/1)
    |> Enum.map(&attribute_value_to_xml/1)
    |> Enum.into(%{})
  end

  def xunit_xml(data),
    do: {XUnitXML.element_name(data), XUnitXML.attributes(data), XUnitXML.content(data)}
end
