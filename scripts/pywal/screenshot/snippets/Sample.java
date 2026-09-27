package pywal.sample;

import java.util.List;

/**
 * Sample exercising every pywal syntax color: comment, doc tag, string,
 * number, modifier, keyword and type.
 */
public class Sample {
  private static final int MAX_RETRIES = 3;

  public static void main(String[] args) {
    // Loop over the retries and print a greeting each time.
    for (int i = 0; i < MAX_RETRIES; i++) {
      String message = "Hello, pywal! (attempt " + i + ")";
      System.out.println(message);
    }

    List<Double> values = List.of(1.5, 2.25, 3.0);
    if (values.isEmpty()) {
      throw new IllegalStateException("no values");
    }
  }
}
