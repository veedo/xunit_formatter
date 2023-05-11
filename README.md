# ExUnit XUnit Formatter

XUnit Formatter for exunit test results.  
The XUnit output format is tailored to work with azure devops, but any XUnit parser will work.  

## Installation

1. Add `exunit_formatter_xunit` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exunit_formatter_xunit, "~> 0.2.0"}
  ]
end
```

2. Add `XUnitFormatter` to the formatters in `test/test_helper.exs`:  

```elixir
ExUnit.configure(formatters: [XUnitFormatter, ExUnit.CLIFormatter])
ExUnit.start
```
`ExUnit.CLIFormatter` also prints the test results to the console. Remove to suppress the console output.

3. Run your tests  

```
$ mix test
........

Finished in 0.2 seconds (0.00s async, 0.2s sync)
8 tests, 0 failures

Randomized with seed 92097
```

The XUnit XML will include any properties tied to the test.  
For these tests the XUnit output looks like:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<assemblies>
  <assembly environment="seed=92097" failed="0" name="apps/conf/test/conf_test.exs" passed="8" run-date="2022-08-14" run-time="22:01:13" skipped="0" test-framework="ex_unit" time="0.227054" total="8">
    <collection failed="0" name="confTest" passed="8" skipped="0" time="0.126521" total="8">
      <test method="Default environment values are accessible." name="Default environment values are accessible." result="Pass" time="0.002856" type="test">
        <traits>
          <trait name="async" value="false"/>
          <trait name="file" value="apps/conf/test/conf_test.exs"/>
          <trait name="line" value="41"/>
          <trait name="testcase" value="5773"/>
        </traits>
      </test>
      <test method="Can supply multiple config files. Overrides in sequential order." name="Can supply multiple config files. Overrides in sequential order." result="Pass" time="0.009926" type="test">
        <traits>
          <trait name="async" value="false"/>
          <trait name="file" value="apps/conf/test/conf_test.exs"/>
          <trait name="line" value="91"/>
        </traits>
      </test>

      .....

    </collection>
  </assembly>
</assemblies>
```

One benefit over other formatters is that all the decorators are recorded.  
For example, for the first test in the example, the test case is tagged:  
```elixir
  @tag testcase: 5773
  test "Default environment values are accessible." do
    ...
  end
```

