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
  def map_key_to_xml_key({k, v}) do
    {
      k |> to_string() |> String.replace("_", "-") |> String.to_atom,
      v
    }
  end
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
    def xunit_xml(data), do: document(element_name(data), content(data)) |> IO.inspect() |> XmlBuilder.generate()
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
    defdelegate xunit_xml(data), to: XUnitFormatter.XUnitXML.Any
    def attributes(data) do
      total = length(data.tests)
      passed = data.tests |> Enum.filter(&(&1.result.result == "Pass")) |> length()
      failed = data.tests |> Enum.filter(&(&1.result.result == "Fail")) |> length()
      skipped = data.tests |> Enum.filter(&(&1.result.result == "Skip")) |> length()
      %{data | total: total, passed: passed, failed: failed, skipped: skipped}
      |> XUnitFormatter.XUnitXML.Any.attributes()
    end

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

  defp to_map({exception_type, message, stack_trace}), do: %{exception_type: exception_type, message: message, stack_trace: stack_trace}
  # TODO: Modify stack format so that paths are relative to root_dir
  defp convert_exception([msg | _]), do: convert_exception(msg)
  defp convert_exception({type, %ExUnit.AssertionError{message: reason}, stack_trace}), do: {type, reason, Exception.format_stacktrace(stack_trace)} |> to_map()
  defp convert_exception({:error, reason, stack_trace}), do: {:error, Exception.message(reason), Exception.format_stacktrace(stack_trace)} |> to_map()
  defp convert_exception({type, reason, stack_trace}) when is_atom(type), do: {type, "#{inspect(reason)}", Exception.format_stacktrace(stack_trace)} |> to_map()
  defp convert_exception({type, reason, stack_trace}), do: {"#{inspect(type)}", "#{inspect(reason)}", Exception.format_stacktrace(stack_trace)} |> to_map()

  @spec struct!(ExUnit.failed()) :: %__MODULE__{}
  def struct!(failure) do
    Kernel.struct!(__MODULE__, convert_exception(failure))
  end

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

defmodule XUnitFormatter.Result do
  defstruct result: "Pass", reason: nil, failure: nil

  def struct!(fields = %{}), do: Kernel.struct!(__MODULE__, fields)
  def struct!(nil), do: %__MODULE__{result: "Pass"}
  def struct!({:failed, reasons}), do: %__MODULE__{result: "Fail", failure: XUnitFormatter.Failure.struct!(reasons)}
  def struct!({:invalid, reasons}), do: %__MODULE__{result: "Skip", reason: reasons}
  def struct!({:excluded, reasons}), do: %__MODULE__{result: "Skip", reason: reasons}
  def struct!({:skipped, reasons}), do: %__MODULE__{result: "Skip", reason: reasons}
  def attributes(%__MODULE__{result: result}), do: %{result: result}
  def content(%__MODULE__{reason: reason, failure: nil}) when not is_nil(reason), do: [reason: {:cdata, reason}]
  def content(%__MODULE__{reason: nil, failure: failure}) when not is_nil(failure), do: [XUnitFormatter.XUnitXML.xunit_xml(failure)]
  def content(_), do: []
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

defmodule XUnitFormatter.Test do
  @enforce_keys [:name]
  defstruct name: nil,
            type: nil,
            method: nil,
            time: nil,
            traits: [],
            result: %XUnitFormatter.Result{}

  defp strip_test_header(title) when not is_binary(title), do: strip_test_header(to_string(title))
  defp strip_test_header(<<"test ", rest::binary>>), do: rest
  defp strip_test_header(rest), do: rest

  def struct!(test = %ExUnit.Test{}) do
    traits =
      test.tags
      |> Map.drop([:test_type, :file, :line, :case, :module, :test])
      |> Enum.reject(&is_nil(elem(&1, 1)))
      |> Enum.map(fn {k,v} -> %XUnitFormatter.Trait{name: k, value: "#{inspect v}"} end)

    Kernel.struct!(__MODULE__, %{
      name: strip_test_header(test.name),
      type: test.tags.test_type,
      method: "#{test.tags.file}:#{test.tags.line}",
      time: test.time / 1_000_000,
      result: XUnitFormatter.Result.struct!(test.state),
      traits: traits
    })
  end

  defimpl XUnitFormatter.XUnitXML do
    defdelegate xunit_xml(data), to: XUnitFormatter.XUnitXML.Any
    def attributes(data) do
      attributes = XUnitFormatter.XUnitXML.Any.attributes(data)
      result_attributes = XUnitFormatter.Result.attributes(data.result)
      Map.merge(attributes, result_attributes)
    end

    def element_name(_), do: :test
    def content(data) do
      trait_content = if is_list(data.traits) and length(data.traits) > 1 do
        [traits: (data.traits |> Enum.map(&XUnitFormatter.XUnitXML.xunit_xml/1))]
      else
        []
      end
      result_content = XUnitFormatter.Result.content(data.result)

      result_content ++ trait_content
    end
    def child_elements(_), do: [:traits, :failure, :reason]
  end
end
