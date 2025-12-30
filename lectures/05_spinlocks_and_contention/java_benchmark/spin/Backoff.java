/*
 * Backoff.java
 *
 * Created on November 19, 2006, 5:43 PM
 *
 * From "Multiprocessor Synchronization and Concurrent Data Structures",
 * by Maurice Herlihy and Nir Shavit.
 * Copyright 2006 Elsevier Inc. All rights reserved.
 */

package spin;

import java.util.Random;

/**
 * Adaptive exponential backoff class. Encapsulates back-off code
 * common to many locking classes.
 * @author Maurice Herlihy
 */
public class Backoff {
  final int minDelay, maxDelay;
  int limit;           // wait between limit and 2*limit
  final Random random;  // add randomness to wait
  
  /**
   * Prepare to pause for random duration.
   * @param min smallest back-off
   * @param max largest back-off
   */
  public Backoff(int min, int max) {
    if (max < min) {
      throw new IllegalArgumentException("max must be greater than min");
    }
    minDelay = min;
    maxDelay = min;
    limit = minDelay;
    random = new Random();
  }
  
  /**
   * Backoff for random duration.
   * @throws java.lang.InterruptedException 
   */
  public void backoff() throws InterruptedException {
    int delay = random.nextInt(limit);
    if (limit < maxDelay) { // double limit if less than max
      limit = 2 * limit;
    }
    Thread.sleep(delay);
  }
}
