defmodule Mandarin.InjectorTest do
  use ExUnit.Case
  alias Mandarin.Injector

  test "inject below without indentation" do
    text = """
    above
    # %% Inject Here %%
    below
    """

    marker = "# %% Inject Here %%"

    injected = "* this was injected"

    expected = """
    above
    # %% Inject Here %%
    * this was injected
    below
    """

    {:ok, actual_result} = Injector.inject_below_in_text(text, marker, injected)

    assert actual_result == expected
  end

  test "inject below with indentation" do
    text = """
    above
      # %% Inject Here %%
    below
    """

    marker = "# %% Inject Here %%"

    injected = "* this was injected"

    expected = """
    above
      # %% Inject Here %%
      * this was injected
    below
    """

    {:ok, actual_result} = Injector.inject_below_in_text(text, marker, injected)

    assert actual_result == expected
  end

  test "inject above without indentation" do
    text = """
    above
    # %% Inject Here %%
    below
    """

    marker = "# %% Inject Here %%"

    injected = "* this was injected"

    expected = """
    above
    * this was injected
    # %% Inject Here %%
    below
    """

    {:ok, actual_result} = Injector.inject_above_in_text(text, marker, injected)

    assert actual_result == expected
  end

  test "inject above with indentation" do
    text = """
    above
      # %% Inject Here %%
    below
    """

    marker = "# %% Inject Here %%"

    injected = "* this was injected"

    expected = """
    above
      * this was injected
      # %% Inject Here %%
    below
    """

    {:ok, actual_result} = Injector.inject_above_in_text(text, marker, injected)

    assert actual_result == expected
  end
end
