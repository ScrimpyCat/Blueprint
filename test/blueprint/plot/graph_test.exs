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

    test "A to B with meta field" do
        assert String.trim("""
        digraph G {
          node_1 [label="A",color="black"];
          node_2 [label="B",color="black"];

          node_1 -> node_2 [color="black"];
          node_1 -> node_2 [color="black"];
        }
        """) == Blueprint.Plot.Graph.to_dot([{ A, B, :test }, { A, B }])
    end

    test "A to B custom colours" do
        assert String.trim("""
        digraph G {
          node_1 [label="A",color="red"];
          node_2 [label="B",color="green"];

          node_1 -> node_2 [color="blue"];
        }
        """) == Blueprint.Plot.Graph.to_dot([{ A, B }], styler: fn
            { :node, A } -> [color: "red"]
            { :node, B } -> [color: "green"]
            { :connection, { A, B } } -> [color: "blue"]
        end)
    end

    test "A to B custom colours with meta field" do
        assert String.trim("""
        digraph G {
          node_1 [label="A",color="red"];
          node_2 [label="B",color="green"];

          node_1 -> node_2 [color="white"];
          node_1 -> node_2 [color="blue"];
        }
        """) == Blueprint.Plot.Graph.to_dot([{ A, B, :test }, { A, B }], styler: fn
            { :node, A } -> [color: "red"]
            { :node, B } -> [color: "green"]
            { :connection, { A, B } } -> [color: "blue"]
            { :connection, { A, B, :test } } -> [color: "white"]
        end)
    end

    test "A to B custom label" do
        assert String.trim("""
        digraph G {
          node_1 [label="1",color="black"];
          node_2 [label="2",color="black"];

          node_1 -> node_2 [color="black"];
        }
        """) == Blueprint.Plot.Graph.to_dot([{ A, B }], labeler: fn
            A -> "1"
            B -> "2"
        end)
    end
end
