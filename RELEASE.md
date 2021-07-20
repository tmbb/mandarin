RELEASE_TYPE: minor

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
      index.html.eex
      ...
  ```

  Manarin will sabe everything according to the following structure.

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
