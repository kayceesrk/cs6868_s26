/*
 * ALock.java
 *
 * Created on January 20, 2006, 11:02 PM
 *
 * From "Multiprocessor Synchronization and Concurrent Data Structures",
 * by Maurice Herlihy and Nir Shavit.
 * Copyright 2006 Elsevier Inc. All rights reserved.
 */

package spin;

/**
 * Anderson lock
 * @author Maurice Herlihy
 */
import java.util.concurrent.locks.Lock;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicBoolean;
import java.lang.ThreadLocal;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.TimeUnit;
public class ALock implements Lock {
  // thread-local variable
  ThreadLocal<Integer> mySlotIndex = new ThreadLocal<Integer> (){
    protected Integer initialValue() {
      return 0;
    }
  };
  AtomicInteger tail;
  AtomicBoolean[] flag;
  int size;
  /**
   * Constructor
   * @param capacity max number of array slots
   */
  public ALock(int capacity) {
    size = capacity;
    tail = new AtomicInteger(0);
    flag = new AtomicBoolean[capacity];
    for (int i = 0; i < capacity; i++) {
      flag[i] = new AtomicBoolean(i == 0);
    }
  }
  public void lock() {
    int slot = tail.getAndIncrement() % size;
    mySlotIndex.set(slot);
    while (!flag[slot].get()) {}; // spin
  }
  public void unlock() {
    int slot = mySlotIndex.get();
    flag[slot].set(false);
    flag[(slot + 1) % size].set(true);
  }
  // any class implementing Lock must provide these methods
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

