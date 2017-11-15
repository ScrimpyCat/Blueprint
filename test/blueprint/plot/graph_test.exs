defmodule Blueprint.Plot.GraphTest do
    use ExUnit.Case
    doctest Blueprint.Plot.Graph

    setup do
        Application.stop(:graphvix)
        Application.start(:graphvix)
    end

    test "A circular reference" do
        assert String.trim("""
        digraph G {
          node_1 [label="A",color="black"];

          node_1 -> node_1 [color="black"];
        }
        """) == Blueprint.Plot.Graph.to_dot([{ A, A }])
    end

    test "A to B" do
        assert String.trim("""
        digraph G {
          node_1 [label="A",color="black"];
          node_2 [label="B",color="black"];

          node_1 -> node_2 [color="black"];
        }
        """) == Blueprint.Plot.Graph.to_dot([{ A, B }])
    end

    test "A to B omni-directional" do
        assert String.trim("""
        digraph G {
          node_1 [label="A",color="black"];
          node_2 [label="B",color="black"];

          node_1 -> node_2 [color="black"];
          node_2 -> node_1 [color="black"];
        }
        """) == Blueprint.Plot.Graph.to_dot([{ A, B }, { B, A }])
    end

end
