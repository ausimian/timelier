defmodule TimelierTest do
  use ExUnit.Case
  use Quixir
  doctest Timelier

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "A reversed list has the same length as the original" do
    ptest original: list() do
      reversed = :lists.reverse(original)
      assert length(reversed) == length(original)
    end
  end
end
