# Changelog

<!-- %% CHANGELOG_ENTRIES %% -->

### 0.4.0 - 2021-07-20 22:34:59

Mandarin now generates web resources according to "vertical slices".
Instead of having

```text
controllers/
  ...
  user_controller.ex
  ...

view/
  ...
  user_view.ex
  ...

templates/
  ...
  user/
    ...
    index.html.eex
    ...
```

Mandarin will save everything according to the following structure.

```text
my_context/
  user/
    user_controller.ex
    user_view.ex
    templates/
      ...
      index.html.eex
      ...
```

