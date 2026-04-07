/**
 * Quick Start Example
 *
 * Demonstrates basic usage of the Markdown module
 */

using Markdown;

public int main(string[] args) {
    // Sample Markdown content
    var markdown_text = """---
title: Quick Start Example
author: Vala Developer
version: 1.0
---

# Introduction

This is a **quick start** example for the *Markdown* module.

## Features

- Parse CommonMark Markdown
- Support GFM extensions
- Handle YAML front matter
- Multiple output formats

### Code Example

```vala
var parser = new Parser();
var doc = parser.parse(markdown);
```

### Links

Visit [Vala Website](https://vala.dev) for more information.

### Task List

- [x] Create parser
- [x] Create writer
- [x] Create renderers
- [ ] Add more features

> This is a blockquote example.

---

## Conclusion

Enjoy using Markdown in Vala!
""";

    stdout.printf("=== Original Markdown ===\n%s\n\n", markdown_text);

    // Parse the Markdown
    var parser = new Parser();
    Document document;

    try {
        document = parser.parse(markdown_text);
    } catch (Error e) {
        stderr.printf("Parse error: %s\n", e.message);
        return 1;
    }

    // Display front matter
    if (document.front_matter.size > 0) {
        stdout.printf("=== Front Matter ===\n");
        foreach (var entry in document.front_matter.entries) {
            stdout.printf("  %s: %s\n", entry.key, entry.value);
        }
        stdout.printf("\n");
    }

    // Convert to HTML
    var html_renderer = new HtmlRenderer();
    var html = html_renderer.render(document);

    stdout.printf("=== HTML Output ===\n%s\n", html);

    // Convert back to Markdown
    var writer = new Writer();
    var rewritten = writer.write(document);

    stdout.printf("=== Rewritten Markdown ===\n%s\n", rewritten);

    // GTK preview
    var gtk_renderer = new PangoRenderer();
    var gtk_markup = gtk_renderer.render(document);
    var gtk_css = gtk_renderer.generate_css();

    stdout.printf("=== GTK Preview Markup ===\n%s\n", gtk_markup);
    stdout.printf("=== GTK CSS ===\n%s\n", gtk_css);

    return 0;
}
