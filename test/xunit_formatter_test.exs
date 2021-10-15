defmodule XUnitFormatterDocTest do
  use ExUnit.Case
  doctest XUnitFormatter
end

defmodule XUnitFormatterStructuresRootDocumentTest do
  use ExUnit.Case

  test "Root document contains proper XML when empty" do
    %XUnitFormatter.Document{} |> XUnitFormatter.XUnitXML.xunit_xml() |> IO.inspect()
  end

  test "Empty assembly is still proper XML" do
    %XUnitFormatter.Document{assemblies: [%XUnitFormatter.Assembly{name: "my_test_assembly", total: 0, collections: []}]} |> XUnitFormatter.XUnitXML.xunit_xml() |> IO.inspect()
  end

  test "Empty collections is still proper XML" do
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
end
