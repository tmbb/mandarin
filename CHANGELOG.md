# Changelog

<!-- %% CHANGELOG_ENTRIES %% -->

### 0.6.0 - 2022-05-25 02:17:18

Updated `forage` dependency version.


### 0.5.0 - 2021-11-24 11:20:17

Mandarin now generates web resources accordinf to "vertical slices".
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
      index.html.heex
      ...
  ```

  Manarin will gennerate everything according to the following structure.

  ```text
  my_context/
    user/
      user_controller.ex
      user_view.ex
      templates/
        ...
        index.html.heex
        ...

  ```


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
    index.html.heex
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
      index.html.heex
      ...
```

