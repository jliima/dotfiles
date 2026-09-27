"""Sample exercising every pywal python syntax color: comment, string,
decorator, number, keyword and builtin."""

from dataclasses import dataclass


@dataclass
class Sample:
  retries: int = 3

  def greet(self, name: str) -> None:
    # Loop over the retries and print a greeting each time.
    for i in range(self.retries):
      message = f"Hello, {name}! (attempt {i})"
      print(message)


if __name__ == "__main__":
  values = [1.5, 2.25, 3.0]
  if not values:
    raise ValueError("no values")
  Sample().greet("pywal")
