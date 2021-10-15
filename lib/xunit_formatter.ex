defmodule XUnitFormatter do
  @moduledoc """
  Documentation for `XUnitFormatter`.
  """

  use GenServer
  defstruct test_cases: %{}, config: %{}, date: nil

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
  def handle_cast(msg, state) do
    IO.inspect(msg, label: "xunit_formatter handle_cast")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:suite_started, opts}, state) do
    # the suite has started with the specified options to the runner.
    {:noreply, state}
  end

  @impl true
  def handle_cast({:suite_finished, %{async: _, load: _, run: _}}, state) do
    # the suite has finished. Returns several measurements in microseconds for running the suite
    {:noreply, state}
  end

  @impl true
  def handle_cast({:module_started, test_module = %ExUnit.TestModule{}}, state) do
    # a test module has started. See ExUnit.TestModule for details.
    {:noreply, state}
  end

  @impl true
  def handle_cast({:module_finished, test_module = %ExUnit.TestModule{}}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast({:test_started, test = %ExUnit.Test{}}, state) do
    # a test has started. See ExUnit.Test for details.
    {:noreply, state}
  end

  @impl true
  def handle_cast({:test_finished, test = %ExUnit.Test{}}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast({:sigquit, [test = %ExUnit.Test{} | test_module = %ExUnit.TestModule{}]}, state) do
    # the VM is going to shutdown. It receives the test cases (or test module in case of setup_all) still running.
    {:noreply, state}
  end

  # Deprecated casts
  @impl true
  def handle_cast({:case_started, _test_module}, state), do: {:noreply, state}
  @impl true
  def handle_cast({:case_finished, _test_module}, state), do: {:noreply, state}
end
