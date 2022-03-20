RELEASE_TYPE: minor

Mandarin now generates web resources accordinf to "vertical slices" or "feature folders".
Instead of having this:

```
🗀 hello_web
  🗀 controllers
      foo_controller.ex
      bar_controller.ex
      ...
  🗀 templates
    🗀 foo
        index.html.eex
        ...
    🗀 bar
        index.html.eex
        ...
  🗀 views
      foo_view.eex
      bar_view.eex
      ...
```

You have this:

```
🗀 hello_web
    🗀 foo
        foo_controller.ex
        foo_view.ex
        🗀 templates
            index.html.eex
            ...
    🗀 bar
        bar_controller.ex
        bar_view.ex
        🗀 templates
            index.html.eex
            ...
```
