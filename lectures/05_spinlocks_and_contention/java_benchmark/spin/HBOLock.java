/*
 * HBOLock.java
 *
 * Created on November 12, 2006, 8:58 PM
 *
 * From "The Art of Multiprocessor Programming",
 * by Maurice Herlihy and Nir Shavit.
 * Copyright 2006 Elsevier Inc. All rights reserved.
 */

package spin;

import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
public class HBOLock implements Lock {
  private static final int LOCAL_MIN_DELAY = 8;
  private static final int LOCAL_MAX_DELAY = 256;
  private static final int REMOTE_MIN_DELAY = 256;
  private static final int REMOTE_MAX_DELAY = 1024;
  private static final int FREE = -1;
  AtomicInteger state;
  /**
   * Hierarchical backoff lock
   * @author Maurice Herlihy
   */
  public HBOLock() {
    state = new AtomicInteger(FREE);
  }
  public void lock() {
    int myCluster = ThreadID.getCluster();
    Backoff localBackoff =
        new Backoff(LOCAL_MIN_DELAY, LOCAL_MAX_DELAY);
    Backoff remoteBackoff =
        new Backoff(REMOTE_MIN_DELAY, REMOTE_MAX_DELAY);
    while (true) {
      if (state.compareAndSet(FREE, myCluster)) {
        return;
      }
      int lockState = state.get();
      try {
        if (lockState == myCluster) {
          localBackoff.backoff();
        } else {
          remoteBackoff.backoff();
        }
      } catch (InterruptedException ex) {
      }
    }
  }
  
  public void unlock() {
    state.set(FREE);
  }
  // Any class that implents Lock must provide these methods.
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

