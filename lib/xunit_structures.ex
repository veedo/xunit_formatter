defprotocol XUnitFormatter.XUnitXML do
  @fallback_to_any true
  def element_name(data)
  def attributes(data)
  def content(data)
  def child_elements(data)
  def xunit_xml(data)
end

defimpl XUnitFormatter.XUnitXML, for: Any do
  def element_name(data), do: data.__struct__
  def attributes(data), do: XUnitFormatter.Modifiers.get_attributes(data)
  def content(_data), do: []
  def child_elements(_), do: []
  def xunit_xml(data), do: {XUnitFormatter.XUnitXML.element_name(data), XUnitFormatter.XUnitXML.attributes(data), XUnitFormatter.XUnitXML.content(data)}
end

defmodule XUnitFormatter.Modifiers do
  def map_key_to_xml_key({k, v}) when is_atom(k), do: map_key_to_xml_key({to_string(k), v})
  def map_key_to_xml_key({k, v}) when is_binary(k), do: {String.replace(k, "_", "-"), v}
  def attribute_to_xml({k, v}) when is_struct(v), do: {k, XUnitFormatter.XUnitXML.xunit_xml(v)}
  def attribute_to_xml(attr), do: attr
  def get_attributes(data), do: data |> Map.from_struct() |> Map.drop(XUnitFormatter.XUnitXML.child_elements(data)) |> Enum.reject(&is_nil/1) |> Enum.map(&attribute_to_xml/1) |> Enum.map(&map_key_to_xml_key/1) |> Enum.into(%{})
end

defmodule XUnitFormatter.Document do
  import XmlBuilder
  defstruct assemblies: []

  defimpl XUnitFormatter.XUnitXML do
    defdelegate attributes(data), to: XUnitFormatter.XUnitXML.Any
    defdelegate child_elements(data), to: XUnitFormatter.XUnitXML.Any

    def element_name(_data), do: :assemblies
    def content(data), do: Enum.map(data.assemblies, &XUnitFormatter.XUnitXML.xunit_xml/1)
    def xunit_xml(data), do: document(element_name(data), content(data)) |> XmlBuilder.generate()
  end
end

defmodule XUnitFormatter.RunDate do
  defstruct [:year, :month, :day]

  defimpl XUnitFormatter.XUnitXML do
    defdelegate element_name(data), to: XUnitFormatter.XUnitXML.Any
    defdelegate attributes(data), to: XUnitFormatter.XUnitXML.Any
    defdelegate content(data), to: XUnitFormatter.XUnitXML.Any
    defdelegate child_elements(data), to: XUnitFormatter.XUnitXML.Any

    def xunit_xml(data) do
      now = DateTime.utc_now()
      yyyy = (data.year || now.year) |> Integer.to_string() |> String.pad_leading(4, "0")
      mm = (data.month || now.month) |> Integer.to_string() |> String.pad_leading(2, "0")
      dd = (data.day || now.day) |> Integer.to_string() |> String.pad_leading(2, "0")
      "#{yyyy}-#{mm}-#{dd}"
      end
  end
end

defmodule XUnitFormatter.RunTime do
  defstruct [:hour, :minute, :second]

  defimpl XUnitFormatter.XUnitXML do
    defdelegate element_name(data), to: XUnitFormatter.XUnitXML.Any
    defdelegate attributes(data), to: XUnitFormatter.XUnitXML.Any
    defdelegate content(data), to: XUnitFormatter.XUnitXML.Any
    defdelegate child_elements(data), to: XUnitFormatter.XUnitXML.Any

    def xunit_xml(data) do
      now = DateTime.utc_now()
      hh = (data.hour || now.hour) |> Integer.to_string() |> String.pad_leading(2, "0")
      mm = (data.minute|| now.minute) |> Integer.to_string() |> String.pad_leading(2, "0")
      ss = (data.second || now.second) |> Integer.to_string() |> String.pad_leading(2, "0")
      "#{hh}:#{mm}:#{ss}"
    end
  end
end

defmodule XUnitFormatter.Assembly do
  import XmlBuilder
  @enforce_keys [:name, :total, :collections]
  defstruct name: nil,
            config_file: nil,
            test_framework: :ex_unit,
            environment: nil,
            run_date: %XUnitFormatter.RunDate{},
            run_time: %XUnitFormatter.RunTime{},
            time: nil,
            total: nil,
            passed: 0,
            failed: 0,
            skipped: 0,
            errors: [],
            collections: []

  defimpl XUnitFormatter.XUnitXML do
    defdelegate attributes(data), to: XUnitFormatter.XUnitXML.Any
    defdelegate xunit_xml(data), to: XUnitFormatter.XUnitXML.Any

    def element_name(_), do: :assembly
    def child_elements(_), do: [:errors, :collections]
    def content(assembly) do
      errors = if is_list(assembly.errors) and length(assembly.errors) > 1 do
        [element(:errors, Enum.map(assembly.errors, &XUnitFormatter.XUnitXML.xunit_xml/1))]
      else
        []
      end
      collections = if is_list(assembly.collections) do
        Enum.map(assembly.collections, &XUnitFormatter.XUnitXML.xunit_xml/1)
      else
        []
      end
      errors ++ collections
    end
  end
end

defmodule XUnitFormatter.Collection do
  @enforce_keys [:name]
  defstruct name: nil,
            time: nil,
            total: 0,
            passed: 0,
            failed: 0,
            skipped: 0,
            tests: []
  defimpl XUnitFormatter.XUnitXML do
    defdelegate attributes(data), to: XUnitFormatter.XUnitXML.Any
    defdelegate xunit_xml(data), to: XUnitFormatter.XUnitXML.Any

    def element_name(_), do: :collection
    def content(collection) do
      if is_list(collection.tests) do
        Enum.map(collection.tests, &XUnitFormatter.XUnitXML.xunit_xml/1)
      else
        []
      end
    end
    def child_elements(_), do: [:tests]
  end
end

defmodule XUnitFormatter.Failure do
  defstruct exception_type: nil,
            message: nil,
            stack_trace: nil

  defimpl XUnitFormatter.XUnitXML do
    defdelegate attributes(data), to: XUnitFormatter.XUnitXML.Any
    defdelegate xunit_xml(data), to: XUnitFormatter.XUnitXML.Any

    def element_name(_), do: :failure
    def content(data) do
      [
        message: {:cdata, data.message},
        "stack-trace": {:cdata, data.stack_trace}
      ]
    end
    def child_elements(_), do: [:message, :stack_trace]
  end
end

defmodule XUnitFormatter.Error do
  @enforce_keys [:name]
  defstruct name: nil,
            type: nil,
            total: nil,
            passed: nil,
            failed: nil,
            skipped: nil,
            failure: %XUnitFormatter.Failure{}

  defimpl XUnitFormatter.XUnitXML do
    defdelegate attributes(data), to: XUnitFormatter.XUnitXML.Any
    defdelegate xunit_xml(data), to: XUnitFormatter.XUnitXML.Any

    def element_name(_), do: :error
    def content(data), do: [XUnitFormatter.XUnitXML.xunit_xml(data.failure)]
    def child_elements(_), do: [:failure]
  end

end

defmodule XUnitFormatter.Test do
  @enforce_keys [:name]
  defstruct name: nil,
            type: nil,
            method: nil,
            time: nil,
            result: nil,
            traits: [],
            failure: nil,
            reason: nil

  defimpl XUnitFormatter.XUnitXML do
    defdelegate attributes(data), to: XUnitFormatter.XUnitXML.Any
    defdelegate xunit_xml(data), to: XUnitFormatter.XUnitXML.Any

    def element_name(_), do: :test
    def content(data) do
      if is_list(data.traits) and length(data.traits) > 1 do
        [traits: (data.traits |> Enum.map(&XUnitFormatter.XUnitXML.xunit_xml/1))]
      else
        []
      end
      ++
      if is_nil(data.failure) do
        []
      else
        [failure: (data.failure |> XUnitFormatter.XUnitXML.xunit_xml())]
      end
      ++
      if is_nil(data.reason) do
        []
      else
        [reason: data.reason]
      end
    end
    def child_elements(_), do: [:traits, :failure, :reason]
  end
end

defmodule XUnitFormatter.Trait do
  defstruct [:name, :value]
  defimpl XUnitFormatter.XUnitXML do
    defdelegate attributes(data), to: XUnitFormatter.XUnitXML.Any
    defdelegate content(data), to: XUnitFormatter.XUnitXML.Any
    defdelegate child_elements(data), to: XUnitFormatter.XUnitXML.Any
    defdelegate xunit_xml(data), to: XUnitFormatter.XUnitXML.Any

    def element_name(_), do: :trait
  end
end
