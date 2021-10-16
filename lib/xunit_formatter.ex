defmodule XUnitFormatter do
  @moduledoc """
  Documentation for `XUnitFormatter`.
  """

  use GenServer
  defstruct assembly: nil, collection: [], test_cases: [], config: %{}, date: nil

  @impl true
  def init(config) do
    IO.inspect(config, label: "XUnitFormatter init config")
    # raise ArgumentError, config
    # The full ExUnit configuration is passed as the argument to GenServer.init/1 callback when the formatters are started.
    # If you need to do runtime configuration of a formatter, you can add any configuration needed by using ExUnit.configure/1 or ExUnit.start/1,
    # and this will then be included in the options passed to the GenServer.init/1 callback.
    xunit_report_dir = Application.get_env(:xunit_formatter, :report_dir, Mix.Project.app_path())
    if Application.get_env(:xunit_formatter, :autocreate_report_dir?, false) do
      :ok = File.mkdir_p(xunit_report_dir)
    end
    |> IO.inspect(label: "xunit_formatter xunit_report_dir")

    xunit_root_dir = Application.get_env(:xunit_formatter, :root_dir, Mix.Project.app_path())
    |> IO.inspect(label: "xunit_formatter xunit_root_dir")
    config = config |> Keyword.put(:xunit_report_dir, xunit_report_dir) |> Keyword.put(:xunit_root_dir, xunit_root_dir) |> IO.inspect(label: "xunit_formatter init config")
    {:ok, %__MODULE__{config: config, date: DateTime.utc_now()}}
  end

  @impl true
  def handle_cast({:suite_started, opts}, state) do
    # the suite has started with the specified options to the runner.
    IO.inspect({:suite_started, opts}, label: "xunit_formatter handle_cast")
    {:noreply, %{state | assembly: nil}}
  end

  @impl true
  def handle_cast({:suite_finished, %{async: _async, load: load, run: run}}, state) do
    # the suite has finished. Returns several measurements in microseconds for running the suite
    total = run + (load || 0)
    state = put_in(state.assembly.time, total)

    %XUnitFormatter.Document{assemblies: [state.assembly]}
    |> XUnitFormatter.XUnitXML.xunit_xml()
    |> IO.puts()
    {:noreply, state}
  end

  @impl true
  def handle_cast({:module_started, test_module = %ExUnit.TestModule{}}, state) do
    # a test module has started. See ExUnit.TestModule for details.
    IO.inspect({:module_started, test_module}, label: "xunit_formatter handle_cast")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:module_finished, test_module = %ExUnit.TestModule{}}, state) do
    tests =
      test_module.tests
      |> Enum.map(&XUnitFormatter.Test.struct!/1)

    module_time = test_module.tests |> Enum.reduce(0, fn test, acc -> acc + test.time end)
    module_time = module_time / 1_000_000
    collection = %XUnitFormatter.Collection{
      name: "#{inspect test_module.name}",
      time: module_time,
      tests: test
    }
    assembly = if is_nil(state.assembly) do
      name = test_module.file |> Path.rootname(".exs")
      %XUnitFormatter.Assembly{name: name}
    end

    assembly = %{assembly | collections: [collection | assembly.collections]}
    {:noreply, state}
  end

  @impl true
  def handle_cast({:test_started, test = %ExUnit.Test{}}, state) do
    # a test has started. See ExUnit.Test for details.
    IO.inspect({:test_started, test}, label: "xunit_formatter handle_cast")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:test_finished, test = %ExUnit.Test{}}, state) do
    IO.inspect({:test_finished, test}, label: "xunit_formatter handle_cast")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:sigquit, ret}, state) do
    # the VM is going to shutdown. It receives the test cases (or test module in case of setup_all) still running.
    IO.inspect({:sigquit, ret}, label: "xunit_formatter handle_cast")
    {:noreply, state}
  end

  # Deprecated casts
  @impl true
  def handle_cast({:case_started, _test_module}, state), do: {:noreply, state}
  @impl true
  def handle_cast({:case_finished, _test_module}, state), do: {:noreply, state}
end
