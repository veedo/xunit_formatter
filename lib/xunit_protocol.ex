defprotocol XUnitFormatter.XUnitXML do
  @fallback_to_any true
  def element_name(data)
  def attributes(data)
  def content(data)
  def child_elements(data)
  def xunit_xml(data)
end

defimpl XUnitFormatter.XUnitXML, for: Any do
  defp map_key_to_xml_key({k, v}) do
    {
      k |> to_string() |> String.replace("_", "-") |> String.to_atom,
      v
    }
  end
  defp attribute_value_to_xml({k, v}) when is_struct(v), do: {k, XUnitFormatter.XUnitXML.xunit_xml(v)}
  defp attribute_value_to_xml(attr), do: attr
  def attribute_empty?({_k, v}), do: is_nil(v) or (v == %{}) or (v == "") or (v == '')

  def element_name(data), do: data.__struct__
  def attributes(data) do
    data
    |> Map.from_struct()
    |> Map.drop(XUnitFormatter.XUnitXML.child_elements(data))
    |> Enum.reject(&attribute_empty?/1)
    |> Enum.map(&map_key_to_xml_key/1)
    |> Enum.map(&attribute_value_to_xml/1)
    |> Enum.into(%{})
  end
  def content(_data), do: []
  def child_elements(_), do: []
  def xunit_xml(data), do: {XUnitFormatter.XUnitXML.element_name(data), XUnitFormatter.XUnitXML.attributes(data), XUnitFormatter.XUnitXML.content(data)}
end
