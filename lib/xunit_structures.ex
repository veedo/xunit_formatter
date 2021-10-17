defmodule XUnitFormatter.Struct do
  alias XUnitFormatter.XUnitXML

  defmodule Document do
    import XmlBuilder
    defstruct assemblies: []

    defimpl XUnitXML do
      defdelegate attributes(data), to: XUnitXML.Any
      defdelegate child_elements(data), to: XUnitXML.Any

      def element_name(_data), do: :assemblies
      def content(data), do: Enum.map(data.assemblies, &XUnitXML.xunit_xml/1)
      def xunit_xml(data), do: document(element_name(data), content(data)) |> XmlBuilder.generate()
    end
  end

  defmodule RunDate do
    defstruct [:year, :month, :day]

    defimpl XUnitXML do
      defdelegate element_name(data), to: XUnitXML.Any
      defdelegate attributes(data), to: XUnitXML.Any
      defdelegate content(data), to: XUnitXML.Any
      defdelegate child_elements(data), to: XUnitXML.Any

      def xunit_xml(data) do
        now = DateTime.utc_now()
        yyyy = (data.year || now.year) |> Integer.to_string() |> String.pad_leading(4, "0")
        mm = (data.month || now.month) |> Integer.to_string() |> String.pad_leading(2, "0")
        dd = (data.day || now.day) |> Integer.to_string() |> String.pad_leading(2, "0")
        "#{yyyy}-#{mm}-#{dd}"
        end
    end
  end

  defmodule RunTime do
    defstruct [:hour, :minute, :second]

    defimpl XUnitXML do
      defdelegate element_name(data), to: XUnitXML.Any
      defdelegate attributes(data), to: XUnitXML.Any
      defdelegate content(data), to: XUnitXML.Any
      defdelegate child_elements(data), to: XUnitXML.Any

      def xunit_xml(data) do
        now = DateTime.utc_now()
        hh = (data.hour || now.hour) |> Integer.to_string() |> String.pad_leading(2, "0")
        mm = (data.minute|| now.minute) |> Integer.to_string() |> String.pad_leading(2, "0")
        ss = (data.second || now.second) |> Integer.to_string() |> String.pad_leading(2, "0")
        "#{hh}:#{mm}:#{ss}"
      end
    end
  end

  defmodule Assembly do
    import XmlBuilder
    defstruct name: nil,
              config_file: nil,
              test_framework: :ex_unit,
              environment: nil,
              run_date: %RunDate{},
              run_time: %RunTime{},
              time: nil,
              total: nil,
              passed: 0,
              failed: 0,
              skipped: 0,
              errors: [],
              collections: []

    defimpl XUnitXML do
      defdelegate xunit_xml(data), to: XUnitXML.Any

      defp update_assembly_in(assembly = %Assembly{}, path, fun) do
        Kernel.struct!(Assembly, (
          assembly |> Map.from_struct() |> Kernel.update_in(path, fun)
        ))
      end
      def attributes(data) do
        data.collections
        |> Enum.reduce(%{data | total: 0, passed: 0, failed: 0, skipped: 0}, fn collection, acc_assembly ->
          %{total: total, passed: passed, failed: failed, skipped: skipped} = XUnitXML.attributes(collection)

          acc_assembly
          |> update_assembly_in([:total], &(&1 + total))
          |> update_assembly_in([:passed], &(&1 + passed))
          |> update_assembly_in([:failed], &(&1 + failed))
          |> update_assembly_in([:skipped], &(&1 + skipped))
        end)
        |> XUnitXML.Any.attributes()
      end

      def element_name(_), do: :assembly
      def child_elements(_), do: [:errors, :collections]
      def content(assembly) do
        errors = if is_list(assembly.errors) and length(assembly.errors) > 1 do
          [element(:errors, Enum.map(assembly.errors, &XUnitXML.xunit_xml/1))]
        else
          []
        end
        collections = if is_list(assembly.collections) do
          Enum.map(assembly.collections, &XUnitXML.xunit_xml/1)
        else
          []
        end
        errors ++ collections
      end
    end
  end

  defmodule Failure do
    defstruct exception_type: nil,
              message: nil,
              stack_trace: nil

    defp to_map({exception_type, message, stack_trace}), do: %{exception_type: exception_type, message: message, stack_trace: stack_trace}
    defp convert_exception([msg | _]), do: convert_exception(msg)
    defp convert_exception({type, %ExUnit.AssertionError{message: reason}, stack_trace}), do: {type, reason, Exception.format_stacktrace(stack_trace)}
    defp convert_exception({:error, reason, stack_trace}), do: {:error, Exception.message(reason), Exception.format_stacktrace(stack_trace)}
    defp convert_exception({type, reason, stack_trace}) when is_atom(type), do: {type, "#{inspect(reason)}", Exception.format_stacktrace(stack_trace)}
    defp convert_exception({type, reason, stack_trace}), do: {"#{inspect(type)}", "#{inspect(reason)}", Exception.format_stacktrace(stack_trace)}

    @spec struct!(ExUnit.failed()) :: %__MODULE__{}
    def struct!(failure) do
      Kernel.struct!(__MODULE__, failure |> convert_exception() |> to_map())
    end

    defimpl XUnitXML do
      defdelegate attributes(data), to: XUnitXML.Any
      defdelegate xunit_xml(data), to: XUnitXML.Any

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

  defmodule Error do
    @enforce_keys [:name]
    defstruct name: nil,
              type: nil,
              total: nil,
              passed: nil,
              failed: nil,
              skipped: nil,
              failure: %Failure{}

    defimpl XUnitXML do
      defdelegate attributes(data), to: XUnitXML.Any
      defdelegate xunit_xml(data), to: XUnitXML.Any

      def element_name(_), do: :error
      def content(data), do: [XUnitXML.xunit_xml(data.failure)]
      def child_elements(_), do: [:failure]
    end
  end

  defmodule Result do
    defstruct result: "Pass", reason: nil, failure: nil

    def passed?(%__MODULE__{result: result}), do: result == "Pass"
    def failed?(%__MODULE__{result: result}), do: result == "Fail"
    def skipped?(%__MODULE__{result: result}), do: result == "Skip"

    def struct!(fields = %{}), do: Kernel.struct!(__MODULE__, fields)
    def struct!(nil), do: %__MODULE__{result: "Pass"}
    def struct!({:failed, reasons}), do: %__MODULE__{result: "Fail", failure: Failure.struct!(reasons)}
    def struct!({:invalid, reasons}), do: %__MODULE__{result: "Skip", reason: reasons}
    def struct!({:excluded, reasons}), do: %__MODULE__{result: "Skip", reason: reasons}
    def struct!({:skipped, reasons}), do: %__MODULE__{result: "Skip", reason: reasons}
    def attributes(%__MODULE__{result: result}), do: %{result: result}
    def content(%__MODULE__{reason: reason, failure: nil}) when not is_nil(reason), do: [reason: {:cdata, reason}]
    def content(%__MODULE__{reason: nil, failure: failure}) when not is_nil(failure), do: [XUnitXML.xunit_xml(failure)]
    def content(_), do: []

  end

  defmodule Trait do
    defstruct [:name, :value]
    defimpl XUnitXML do
      defdelegate attributes(data), to: XUnitXML.Any
      defdelegate content(data), to: XUnitXML.Any
      defdelegate child_elements(data), to: XUnitXML.Any
      defdelegate xunit_xml(data), to: XUnitXML.Any

      def element_name(_), do: :trait
    end
  end

  defmodule Test do
    @enforce_keys [:name]
    defstruct name: nil,
              type: nil,
              method: nil,
              time: nil,
              traits: [],
              result: %Result{}

    def passed?(%__MODULE__{result: result}), do: Result.passed?(result)
    def failed?(%__MODULE__{result: result}), do: Result.failed?(result)
    def skipped?(%__MODULE__{result: result}), do: Result.skipped?(result)

    defp strip_test_header(title) when not is_binary(title), do: strip_test_header(to_string(title))
    defp strip_test_header(<<"test ", rest::binary>>), do: rest
    defp strip_test_header(rest), do: rest

    defp string_or_inspect(value) do
      try do
        "#{value}"
      rescue
        Protocol.UndefinedError -> "#{inspect value}"
      end
    end

    def struct!(test = %ExUnit.Test{}) do
      traits =
        test.tags
        |> Map.drop([:test_type, :case, :module, :test])
        |> Enum.reject(&XUnitXML.Any.attribute_empty?/1)
        |> Enum.map(fn {k,v} -> %Trait{name: k, value: string_or_inspect(v)} end)

      Kernel.struct!(__MODULE__, %{
        name: strip_test_header(test.name),
        method: strip_test_header(test.name),
        type: test.tags.test_type,
        time: test.time / 1_000_000,
        result: Result.struct!(test.state),
        traits: traits
      })
    end

    defimpl XUnitXML do
      defdelegate xunit_xml(data), to: XUnitXML.Any
      def attributes(data) do
        attributes = XUnitXML.Any.attributes(data)
        result_attributes = Result.attributes(data.result)
        Map.merge(attributes, result_attributes)
      end

      def element_name(_), do: :test
      def content(data) do
        trait_content = if is_list(data.traits) and length(data.traits) > 1 do
          [traits: (data.traits |> Enum.map(&XUnitXML.xunit_xml/1))]
        else
          []
        end
        result_content = Result.content(data.result)

        result_content ++ trait_content
      end
      def child_elements(_), do: [:traits, :failure, :reason]
    end
  end

  defmodule Collection do
    @enforce_keys [:name]
    defstruct name: nil,
              time: nil,
              total: 0,
              passed: 0,
              failed: 0,
              skipped: 0,
              tests: []

    defimpl XUnitXML do
      defdelegate xunit_xml(data), to: XUnitXML.Any
      def attributes(data) do
        %{data | total: Enum.count(data.tests),
        passed: data.tests |> Enum.count(&Test.passed?/1),
        failed: data.tests |> Enum.count(&Test.failed?/1),
        skipped: data.tests |> Enum.count(&Test.skipped?/1)}
        |> XUnitXML.Any.attributes()
      end

      def element_name(_), do: :collection
      def content(collection) do
        if is_list(collection.tests) do
          Enum.map(collection.tests, &XUnitXML.xunit_xml/1)
        else
          []
        end
      end
      def child_elements(_), do: [:tests]
    end
  end
end
