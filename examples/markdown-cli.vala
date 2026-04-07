/**
 * Simple command-line Markdown processor example
 *
 * Usage:
 *   markdown-cli input.md [--output output.html] [--format html|gtk|md]
 */

using Markdown;

public class MarkdownCLI : Object {
    private Parser parser;
    private Writer writer;
    private HtmlRenderer html_renderer;
    private PangoRenderer gtk_renderer;

    public MarkdownCLI() {
        parser = new Parser();
        writer = new Writer();
        html_renderer = new HtmlRenderer();
        gtk_renderer = new PangoRenderer();
    }

    public int run(string[] args) {
        if (args.length < 2) {
            print_usage();
            return 1;
        }

        var input_file = args[1];
        string? output_file = null;
        string format = "html";

        // Parse arguments
        for (int i = 2; i < args.length; i++) {
            if (args[i] == "--output" || args[i] == "-o") {
                if (i + 1 < args.length) {
                    output_file = args[i + 1];
                    i++;
                }
            } else if (args[i] == "--format" || args[i] == "-f") {
                if (i + 1 < args.length) {
                    format = args[i + 1];
                    i++;
                }
            } else if (args[i] == "--help" || args[i] == "-h") {
                print_usage();
                return 0;
            }
        }

        // Read input file
        string content;
        try {
            FileUtils.get_contents(input_file, out content);
        } catch (FileError e) {
            stderr.printf("Error reading file '%s': %s\n", input_file, e.message);
            return 1;
        }

        // Parse Markdown
        Document document;
        try {
            document = parser.parse(content);
        } catch (Error e) {
            stderr.printf("Error parsing Markdown: %s\n", e.message);
            return 1;
        }

        // Print front matter if present
        if (document.front_matter.size > 0) {
            stdout.printf("=== Front Matter ===\n");
            foreach (var entry in document.front_matter.entries) {
                stdout.printf("%s: %s\n", entry.key, entry.value);
            }
            stdout.printf("\n");
        }

        // Render output
        string output;
        switch (format.down()) {
            case "html":
                var html_options = new HtmlOptions();
                html_options.emit_html_wrapper = true;
                html_options.emit_doctype = true;
                var html_renderer_full = new HtmlRenderer(html_options);
                output = html_renderer_full.render(document);
                break;

            case "gtk":
                output = gtk_renderer.render(document);
                stdout.printf("\n=== GTK CSS ===\n%s\n", gtk_renderer.generate_css());
                break;

            case "md":
            case "markdown":
                output = writer.write(document);
                break;

            default:
                stderr.printf("Unknown format: %s\n", format);
                return 1;
        }

        // Write output
        if (output_file != null) {
            try {
                FileUtils.set_contents(output_file, output);
                stdout.printf("Output written to: %s\n", output_file);
            } catch (FileError e) {
                stderr.printf("Error writing file '%s': %s\n", output_file, e.message);
                return 1;
            }
        } else {
            stdout.printf("\n=== Output (%s) ===\n", format.up());
            stdout.printf("%s\n", output);
        }

        return 0;
    }

    private void print_usage() {
        stdout.printf("""
Markdown CLI - A command-line Markdown processor

Usage:
  markdown-cli <input.md> [options]

Options:
  -o, --output <file>  Output file (default: stdout)
  -f, --format <fmt>   Output format: html, gtk, md (default: html)
  -h, --help           Show this help message

Examples:
  markdown-cli README.md -o README.html
  markdown-cli notes.md -f gtk
  markdown-cli document.md -f md -o rewritten.md

""");
    }

    public static int main(string[] args) {
        var cli = new MarkdownCLI();
        return cli.run(args);
    }
}
