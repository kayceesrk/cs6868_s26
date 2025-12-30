/*
 * BackoffLock.java
 *
 * Created on January 20, 2006, 11:02 PM
 *
 * From "Multiprocessor Synchronization and Concurrent Data Structures",
 * by Maurice Herlihy and Nir Shavit.
 * Copyright 2006 Elsevier Inc. All rights reserved.
 */

package spin;

/**
 * Exponential backoff lock
 * @author Maurice Herlihy
 */
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.Condition;
import java.util.Random;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
public class BackoffLock implements Lock {
  private Backoff backoff;
  private Random random = new Random();
  private AtomicBoolean state = new AtomicBoolean(false);  
  private static final int MIN_DELAY = 32;
  private static final int MAX_DELAY = 1024;
  public void lock() {
    Backoff backoff = new Backoff(MIN_DELAY, MAX_DELAY);
    while (true) {
      while (state.get()) {};	// spin
      if (!state.getAndSet(true)) { // try to acquire lock
        return;
      } else {			// backoff on failure
        try {
          backoff.backoff();
        } catch (InterruptedException ex) {
        }
      }
    }
  }  
  public void unlock() {
    state.set(false);
  }
  // Any class implementing Lock must provide these methods
  public Condition newCondition() {
    throw new java.lang.UnsupportedOperationException();
  }
  public boolean tryLock(long time,
      TimeUnit unit)
      throws InterruptedException {
    throw new java.lang.UnsupportedOperationException();
  }
  public boolean tryLock() {
    throw new java.lang.UnsupportedOperationException();
  }
  public void lockInterruptibly() throws InterruptedException {
    throw new java.lang.UnsupportedOperationException();
  }
}
