defmodule XUnitFormatterDocTest do
  use ExUnit.Case
  doctest XUnitFormatter
end

defmodule XUnitFormatterStructuresEmptyTest do
  use ExUnit.Case

  test "Root document contains proper XML when empty" do
    %XUnitFormatter.Document{} |> XUnitFormatter.XUnitXML.xunit_xml() |> IO.inspect()
  end

  test "Empty assembly is still proper XML" do
    %XUnitFormatter.Document{assemblies: [%XUnitFormatter.Assembly{name: "my_test_assembly", total: 0, collections: []}]} |> XUnitFormatter.XUnitXML.xunit_xml() |> IO.inspect()
  end

  test "Empty collections are still proper XML" do
    %XUnitFormatter.Document{
      assemblies: [
        %XUnitFormatter.Assembly{name: "my_test_assembly1", total: 1, collections: [
          %XUnitFormatter.Collection{name: "TestCaseCollection1"}
        ]},
        %XUnitFormatter.Assembly{name: "my_test_assembly2", total: 2, collections: [
          %XUnitFormatter.Collection{name: "TestCaseCollection2"},
          %XUnitFormatter.Collection{name: "TestCaseCollection3"}
        ]}
      ]
    }
    |> XUnitFormatter.XUnitXML.xunit_xml()
    |> IO.inspect()
  end

  test "All passed/failed/skipped tests are still proper XML" do
    %XUnitFormatter.Document{
      assemblies: [
        %XUnitFormatter.Assembly{name: "my_test_assembly1", total: 1, collections: [
          %XUnitFormatter.Collection{name: "TestCaseCollection1", total: 2, passed: 2, tests: [
            %XUnitFormatter.Test{name: "Test1", result: XUnitFormatter.Result.struct!(nil)},
            %XUnitFormatter.Test{name: "Test2", result: XUnitFormatter.Result.struct!(nil)},
          ]}
        ]},
        %XUnitFormatter.Assembly{name: "my_test_assembly2", total: 2, collections: [
          %XUnitFormatter.Collection{name: "TestCaseCollection2", total: 2, skipped: 2, tests: [
            %XUnitFormatter.Test{name: "Test3", result: XUnitFormatter.Result.struct!()},
            %XUnitFormatter.Test{name: "Test4", result: XUnitFormatter.Result.struct!(nil)},
          ]},
          %XUnitFormatter.Collection{name: "TestCaseCollection3", total: 1, failed: 1, tests: [
            %XUnitFormatter.Test{name: "Test5", result: XUnitFormatter.Result.struct!({:failed, []})},
          ]}
        ]}
      ]
    }
    |> XUnitFormatter.XUnitXML.xunit_xml()
    |> IO.inspect()
  end
end
