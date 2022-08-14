defmodule XUnitFormatterDocTest do
  use ExUnit.Case
  doctest XUnitFormatter
end

defmodule XUnitFormatterStructuresEmptyTest do
  use ExUnit.Case
  alias XUnitFormatter.Struct, as: XStruct

  test "Root document contains proper XML when empty" do
    %XStruct.Document{} |> XUnitFormatter.XUnitXML.xunit_xml() |> IO.inspect()
  end

  test "Empty assembly is still proper XML" do
    %XStruct.Document{assemblies: [%XStruct.Assembly{name: "my_test_assembly", total: 0, collections: []}]} |> XUnitFormatter.XUnitXML.xunit_xml() |> IO.inspect()
  end

  test "Empty collections are still proper XML" do
    %XStruct.Document{
      assemblies: [
        %XStruct.Assembly{name: "my_test_assembly1", total: 1, collections: [
          %XStruct.Collection{name: "TestCaseCollection1"}
        ]},
        %XStruct.Assembly{name: "my_test_assembly2", total: 2, collections: [
          %XStruct.Collection{name: "TestCaseCollection2"},
          %XStruct.Collection{name: "TestCaseCollection3"}
        ]}
      ]
    }
    |> XUnitFormatter.XUnitXML.xunit_xml()
    |> IO.inspect()
  end

  test "All passed/failed/skipped tests are still proper XML" do
    %XStruct.Document{
      assemblies: [
        %XStruct.Assembly{name: "my_test_assembly1", total: 1, collections: [
          %XStruct.Collection{name: "TestCaseCollection1", total: 2, passed: 2, tests: [
            %XStruct.Test{name: "Test1", result: XStruct.Result.struct!(nil)},
            %XStruct.Test{name: "Test2", result: XStruct.Result.struct!(nil)},
          ]}
        ]},
        %XStruct.Assembly{name: "my_test_assembly2", total: 2, collections: [
          %XStruct.Collection{name: "TestCaseCollection2", total: 2, skipped: 2, tests: [
            %XStruct.Test{name: "Test3", result: XStruct.Result.struct!()},
            %XStruct.Test{name: "Test4", result: XStruct.Result.struct!(nil)},
          ]},
          %XStruct.Collection{name: "TestCaseCollection3", total: 1, failed: 1, tests: [
            %XStruct.Test{name: "Test5", result: XStruct.Result.struct!({:failed, [{:somewierderror, :whoknows, []}]})},
          ]}
        ]}
      ]
    }
    |> XUnitFormatter.XUnitXML.xunit_xml()
    |> IO.inspect()
  end
end
