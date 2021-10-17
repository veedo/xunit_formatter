defmodule XUnitFormatter do
  @moduledoc """
  Documentation for `XUnitFormatter`.
  """

  use GenServer
  alias XUnitFormatter.Struct, as: XStruct
  defstruct assembly: nil, collection: [], test_cases: [], skipped: %{}, config: %{}, date: nil

  def expand_exception_paths(test = %ExUnit.Test{state: {:failed, failure}}, cwd, root_dir) do
    %ExUnit.Test{test |
      state: {:failed, Enum.map(failure, &expand_exception_paths(&1, cwd, root_dir))},
      tags: update_in(test.tags, [:file], &Path.relative_to(&1, root_dir))
    }
  end

  def expand_exception_paths(test = %ExUnit.Test{}, _cwd, root_dir), do: %ExUnit.Test{test | tags: update_in(test.tags, [:file], &Path.relative_to(&1, root_dir))}
  def expand_exception_paths({kind, reason, stacktrace}, cwd, root_dir) do
    {kind, reason, Enum.map(stacktrace, &expand_exception_paths(&1, cwd, root_dir))}
  end

  def expand_exception_paths({module, fun, args, path}, cwd, root_dir) do
    {module, fun, args, expand_exception_paths(path, cwd, root_dir)}
  end

  def expand_exception_paths([file: path, line: line], cwd, root_dir) do
    {path, cwd, root_dir}
    if File.exists?(abspath = Path.expand(path, cwd)) do
      [file: Path.relative_to(abspath, root_dir), line: line]
    else
      [file: path, line: line]
    end
  end

  @impl true
  def init(config) do
    xunit_report_dir = Application.get_env(:xunit_formatter, :report_dir, Mix.Project.app_path())
    if Application.get_env(:xunit_formatter, :autocreate_report_dir, false) do
      :ok = File.mkdir_p(xunit_report_dir)
    end

    config =
      config
      |> Keyword.put(:xunit_report_dir, xunit_report_dir)
      |> Keyword.put(:xunit_root_dir, Application.get_env(:xunit_formatter, :root_dir, File.cwd!))
      |> Keyword.put(:xunit_prepend_app_name, Application.get_env(:xunit_formatter, :prepend_app_name, false))
      |> Enum.into(%{})
    {:ok, %__MODULE__{config: config, date: DateTime.utc_now()}}
  end

  @impl true
  def handle_cast({:suite_started, _opts}, state) do
    {:noreply, %{state | assembly: nil}}
  end

  @impl true
  def handle_cast({:suite_finished, %{async: _async, load: load, run: run}}, state) do
    total = (run + (load || 0)) / 1_000_000
    state = put_in(state.assembly.time, total)

    prefix = if state.config.xunit_prepend_app_name, do: "#{Mix.Project.config()[:app]}-", else: ""
    filename = state.config.xunit_report_dir |> Path.join(prefix <> "xunit-report.xml")

    xunit_data = %XStruct.Document{assemblies: [state.assembly]}
    |> XUnitFormatter.XUnitXML.xunit_xml()

    File.write!(filename, xunit_data)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:module_finished, test_module = %ExUnit.TestModule{}}, state) do
    tests =
      (test_module.tests ++ Map.get(state.skipped, test_module.name, []))
      |> Enum.map(&expand_exception_paths(&1, File.cwd!, state.config.xunit_root_dir))
      |> Enum.map(&XStruct.Test.struct!/1)

    module_time = test_module.tests |> Enum.reduce(0, fn test, acc -> acc + test.time end)
    module_time = module_time / 1_000_000
    collection = %XStruct.Collection{
      name: "#{inspect test_module.name}",
      time: module_time,
      tests: tests
    }
    assembly = if is_nil(state.assembly) do
      name = test_module.file |> Path.relative_to(state.config.xunit_root_dir)
      %XStruct.Assembly{name: name, environment: "seed=#{state.config.seed}"}
    else
      state.assembly
    end

    assembly = %{assembly | collections: [collection | assembly.collections]}
    {:noreply, %{state | assembly: assembly}}
  end

  @impl true
  def handle_cast({:sigquit, running_tests_and_modules}, state) do
    # the VM is going to shutdown. It receives the test cases (or test module in case of setup_all) still running.
    IO.inspect({:sigquit, running_tests_and_modules}, label: "xunit_formatter handle_cast")
    {:noreply, state}
  end

  # Un-used casts
  @impl true
  def handle_cast({:module_started, _module = %ExUnit.TestModule{}}, state), do: {:noreply, state}
  @impl true
  def handle_cast({:test_started, _test = %ExUnit.Test{}}, state), do: {:noreply, state}
  @impl true
  def handle_cast({:test_finished, test = %ExUnit.Test{state: {skipped, _}}}, state) when skipped in [:skipped, :excluded, :invalid] do
    skipped_tests_in_module = [test | Map.get(state.skipped, test.module, [])]
    skipped_tests = Map.put(state.skipped, test.module, skipped_tests_in_module)
    {:noreply, %{state | skipped: skipped_tests}}
  end
  @impl true
  def handle_cast({:test_finished, _test = %ExUnit.Test{}}, state), do: {:noreply, state}

  # Deprecated casts
  @impl true
  def handle_cast({:case_started, _test_module}, state), do: {:noreply, state}
  @impl true
  def handle_cast({:case_finished, _test_module}, state), do: {:noreply, state}
end
