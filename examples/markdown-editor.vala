/**
 * Markdown Example Application
 *
 * Demonstrates usage of the Markdown module for parsing, writing,
 * and rendering Markdown documents
 */

using Gtk;
using Markdown;

public class MarkdownExample : Gtk.Application {
    private Window window;
    private TextView source_view;
    private TextView preview_view;
    private TextView html_view;
    private Parser parser;
    private Writer writer;
    private HtmlRenderer html_renderer;
    private PangoRenderer gtk_renderer;

    public MarkdownExample() {
        Object(flags: ApplicationFlags.DEFAULT_FLAGS, application_id: "org.gnome.MarkdownApp");
        parser = new Parser();
        writer = new Writer();
        html_renderer = new HtmlRenderer();
        gtk_renderer = new PangoRenderer();
    }

    public override void activate()
    {
        window = new ApplicationWindow(this);
        window.title = "Markdown Editor Example";
        window.set_default_size(1200, 800);
        // window.close_request.connect(Gtk.quit);

        // Main container
        var paned = new Paned(Orientation.HORIZONTAL);
        window.child = paned;

        // Left panel - Source editor
        var source_frame = new Frame("Markdown Source");
        source_view = new TextView();
        source_view.set_wrap_mode(WrapMode.WORD_CHAR);
        source_view.get_buffer().changed.connect(on_source_changed);

        var source_scroll = new ScrolledWindow();
        source_scroll.child = source_view;
        source_frame.child = source_scroll;

        // Right panel - Preview and HTML
        var right_paned = new Paned(Orientation.VERTICAL);

        // Preview
        var preview_frame = new Frame("GTK Preview");
        preview_view = new TextView();
        preview_view.set_wrap_mode(WrapMode.WORD_CHAR);
        preview_view.set_editable(false);

        var preview_scroll = new ScrolledWindow();
        preview_scroll.child = preview_view;
        preview_frame.child = preview_scroll;

        // HTML output
        var html_frame = new Frame("HTML Output");
        html_view = new TextView();
        html_view.set_wrap_mode(WrapMode.WORD_CHAR);
        html_view.set_editable(false);

        var html_scroll = new ScrolledWindow();
        html_scroll.child = html_view;
        html_frame.child = html_scroll;

        right_paned.set_start_child(preview_frame);
        right_paned.set_end_child(html_frame);

        paned.set_start_child(source_frame);
        paned.set_end_child(right_paned);

        paned.set_position(400);
        right_paned.set_position(400);

        load_sample_markdown();
        window.present();
    }

    private void load_sample_markdown() {
        var sample = """---
title: Markdown Example
author: Vala Developer
date: 2026-04-07
---

# Markdown Example Document

This is a **comprehensive** example demonstrating *various* Markdown features.

## Features Supported

### Text Formatting

- **Bold text** using double asterisks
- *Italic text* using single asterisks
- `Inline code` using backticks
- ~~Strikethrough~~ using double tildes (GFM)

### Lists

#### Unordered Lists

- Item 1
- Item 2
- Item 3

#### Ordered Lists

1. First item
2. Second item
3. Third item

#### Task Lists (GFM)

- [x] Completed task
- [ ] Pending task
- [ ] Another pending task

### Code Blocks

```vala
public int main(string[] args) {
    stdout.printf("Hello, World!\\n");
    return 0;
}
```

### Links and Images

Visit [Vala Documentation](https://vala.dev) for more information.

### Blockquotes

> This is a blockquote.
> It can span multiple lines.

### Tables (GFM)

| Name    | Type   | Description |
|---------|--------|-------------|
| Parser  | Class  | Parses Markdown |
| Writer  | Class  | Writes Markdown |
| Renderer| Class  | Renders to HTML |

---

## Conclusion

This module provides comprehensive Markdown support for Vala applications.
""";

        var buffer = source_view.get_buffer();
        buffer.set_text(sample);
    }

    private void on_source_changed() {
        var buffer = source_view.get_buffer();
        TextIter start, end;
        buffer.get_bounds(out start, out end);
        var source = buffer.get_text(start, end, false);

        // Parse the Markdown
        Document? doc = null;
        try {
            doc = parser.parse(source);
        } catch (Error e) {
            preview_view.get_buffer().set_text("Parse error: " + e.message);
            return;
        }

        // Update GTK preview
        var gtk_markup = gtk_renderer.render(doc);
        var css = gtk_renderer.generate_css();
        preview_view.get_buffer().set_text(gtk_markup);

        // Update HTML output
        var html = html_renderer.render(doc);
        html_view.get_buffer().set_text(html);
    }

    public static int main(string[] args) {
        var app = new MarkdownExample();
        app.run(args);
        return 0;
    }
}
