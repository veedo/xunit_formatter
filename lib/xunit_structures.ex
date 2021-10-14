defmodule XUnitFormatter.Document do
  @child_elements [:assemblies]
  defstruct assemblies: []
end

defmodule XUnitFormatter.RunDate do
  @enforce_keys [:year, :month, :day]
  defstruct [:year, :month, :day]
end

defmodule XUnitFormatter.RunTime do
  @enforce_keys [:hour, :minute, :second]
  defstruct [:hour, :minute, :second]
end

defmodule XUnitFormatter.Assembly do
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
end

defmodule XUnitFormatter.Collection do
  @child_elements [:tests]
  @enforce_keys [:name]
  defstruct name: nil,
            time: nil,
            total: nil,
            passed: nil,
            failed: nil,
            skipped: nil,
            tests: []
end

defmodule XUnitFormatter.Failure do
  @child_elements [:message, :stack_trace]
  defstruct exception_type: nil,
            message: nil,
            stack_trace: nil
end

defmodule XUnitFormatter.Error do
  @child_elements [:failure]
  @enforce_keys [:name]
  defstruct name: nil,
            type: nil,
            total: nil,
            passed: nil,
            failed: nil,
            skipped: nil,
            failure: %XUnitFormatter.Failure{}
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
end

defmodule XUnitFormatter.Trait do
  defstruct [:name, :value]
end
