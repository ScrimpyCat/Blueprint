defmodule Blueprint.Mixfile do
    use Mix.Project

    def project do
        [
            app: :blueprint,
            description: "A library to visualize various aspects of your application",
            version: "0.3.0",
            elixir: "~> 1.5",
            start_permanent: Mix.env == :prod,
            deps: deps(),
            package: package(),
            escript: escript(),
            dialyzer: [plt_add_deps: :transitive]
        ]
    end

    # Run "mix help compile.app" to learn about applications.
    def application do
        [extra_applications: [:logger]]
    end

    # Run "mix help deps" to learn about dependencies.
    defp deps do
        [
            { :graphvix, "~> 0.5.0" },
            { :simple_markdown, "~> 0.3" },
            { :simple_markdown_extension_cli, "~> 0.1.3" },
            { :ex_doc, "~> 0.18", only: :dev }
        ]
    end

    defp package do
        [
            maintainers: ["Stefan Johnson"],
            licenses: ["BSD 2-Clause"],
            links: %{ "GitHub" => "https://github.com/ScrimpyCat/Blueprint" }
        ]
    end

    defp escript do
        [
            main_module: Blueprint.CLI,
            strip_beam: false
        ]
    end
end
