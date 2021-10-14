defmodule XUnitFormatter.Document do
  import XmlBuilder
  defstruct assemblies: []

  def to_xml(%__MODULE__{assemblies: assemblies}) do
    document(:assemblies, Enum.map(assemblies, &XUnitFormatter.Assembly.to_xml/1))
  end
end

defmodule XUnitFormatter.RunDate do
  @enforce_keys [:year, :month, :day]
  defstruct [:year, :month, :day]

  def to_xml(%__MODULE__{year: yyyy, month: mm, day: dd}) do
    now = DateTime.utc_now()
    yyyy = (yyyy || now.year) |> Integer.to_string() |> String.pad_leading(4, "0")
    mm = (mm || now.month) |> Integer.to_string() |> String.pad_leading(2, "0")
    dd = (dd || now.day) |> Integer.to_string() |> String.pad_leading(2, "0")
    "#{yyyy}-#{mm}-#{dd}"
  end
end

defmodule XUnitFormatter.RunTime do
  @enforce_keys [:hour, :minute, :second]
  defstruct [:hour, :minute, :second]

  def to_xml(%__MODULE__{hour: hh, minute: mm, second: ss}) do
    now = DateTime.utc_now()
    hh = (hh || now.hour) |> Integer.to_string() |> String.pad_leading(2, "0")
    mm = (mm || now.minute) |> Integer.to_string() |> String.pad_leading(2, "0")
    ss = (ss || now.second) |> Integer.to_string() |> String.pad_leading(2, "0")
    "#{hh}:#{mm}:#{ss}"
  end
end

defmodule XUnitFormatter.Assembly do
  import XmlBuilder
  @child_elements [:errors, :collections]
  @enforce_keys [:name, :run_date, :run_time, :total, :collections]
  defstruct name: nil,
            config_file: nil,
            test_framework: :ex_unit,
            environment: nil,
            run_date: nil,
            run_time: nil,
            time: nil,
            total: nil,
            passed: 0,
            failed: 0,
            skipped: 0,
            errors: [],
            collections: []

  defp map_key_to_xml_key({k, v}) when is_atom(k), do: map_key_to_xml_key({to_string(k), v})
  defp map_key_to_xml_key({k, v}) when is_binary(k), do: {String.replace(k, "_", "-"), v}

  def to_xml(assembly = %__MODULE__{}) do
    errors = if is_list(assembly.errors) and length(assembly.errors) > 1 do
      [element(:errors, Enum.map(assembly.errors, &XUnitFormatter.Error.to_xml/1))]
    else
      []
    end
    collections = if is_list(assembly.collections) do
      Enum.map(assembly.collections, &XUnitFormatter.Collection.to_xml/1)
    else
      []
    end
    attrs = assembly |> Map.from_struct() |> Map.drop(@child_elements) |> Enum.reject(&is_nil/1) |> Enum.map(&map_key_to_xml_key/1) |> Enum.into(%{})
    {:assembly, attrs, errors ++ collections}
  end
end

defmodule XUnitFormatter.Collection do
  @child_elements [:tests]
  @enforce_keys [:name]
  defstruct name: nil,
            time: nil,
            total: 0,
            passed: 0,
            failed: 0,
            skipped: 0,
            tests: []

  defp map_key_to_xml_key({k, v}) when is_atom(k), do: map_key_to_xml_key({to_string(k), v})
  defp map_key_to_xml_key({k, v}) when is_binary(k), do: {String.replace(k, "_", "-"), v}

  def to_xml(collection = %__MODULE__{}) do
    tests = if is_list(collection.tests) do
      Enum.map(collection.tests, &XUnitFormatter.Test.to_xml/1)
    else
      []
    end

    attrs = collection |> Map.from_struct() |> Map.drop(@child_elements) |> Enum.reject(&is_nil/1) |> Enum.map(&map_key_to_xml_key/1) |> Enum.into(%{})
    {:collection, attrs, tests}
  end
end

defmodule XUnitFormatter.Failure do
  import XmlBuilder
  @child_elements [:message, :stack_trace]
  defstruct exception_type: nil,
            message: nil,
            stack_trace: nil

  defp map_key_to_xml_key({k, v}) when is_atom(k), do: map_key_to_xml_key({to_string(k), v})
  defp map_key_to_xml_key({k, v}) when is_binary(k), do: {String.replace(k, "_", "-"), v}

  def to_xml(failure = %__MODULE__{}) do
    attrs = failure |> Map.from_struct() |> Map.drop(@child_elements) |> Enum.reject(&is_nil/1) |> Enum.map(&map_key_to_xml_key/1) |> Enum.into(%{})
    element(:failure, attrs, [])
  end
end

defmodule XUnitFormatter.Error do
  import XmlBuilder
  @child_elements [:failure]
  @enforce_keys [:name]
  defstruct name: nil,
            type: nil,
            total: nil,
            passed: nil,
            failed: nil,
            skipped: nil,
            failure: %XUnitFormatter.Failure{}

  defp map_key_to_xml_key({k, v}) when is_atom(k), do: map_key_to_xml_key({to_string(k), v})
  defp map_key_to_xml_key({k, v}) when is_binary(k), do: {String.replace(k, "_", "-"), v}

  def to_xml(error = %__MODULE__{}) do
    attrs = error |> Map.from_struct() |> Map.drop(@child_elements) |> Enum.reject(&is_nil/1) |> Enum.map(&map_key_to_xml_key/1) |> Enum.into(%{})
    element(:error, attrs, [])
  end
end

defmodule XUnitFormatter.Test do
  @child_elements [:traits, :failure, :reason]
  @enforce_keys [:name]
  defstruct name: nil,
            type: nil,
            method: nil,
            time: nil,
            result: nil,
            traits: nil,
            failure: %XUnitFormatter.Failure{},
            reason: ""

  defp map_key_to_xml_key({k, v}) when is_atom(k), do: map_key_to_xml_key({to_string(k), v})
  defp map_key_to_xml_key({k, v}) when is_binary(k), do: {String.replace(k, "_", "-"), v}

  def to_xml(test = %__MODULE__{}) do
    attrs = test |> Map.from_struct() |> Map.drop(@child_elements) |> Enum.reject(&is_nil/1) |> Enum.map(&map_key_to_xml_key/1) |> Enum.into(%{})
    {:test, attrs, []}
  end
end

defmodule XUnitFormatter.Trait do
  defstruct [:name, :value]

  def to_xml(trait = %__MODULE__{}) do
    attrs = trait |> Map.from_struct()
    {:trait, attrs, []}
  end
end
