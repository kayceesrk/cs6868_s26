/*
 * TOLock.java
 *
 * Created on January 21, 2006, 12:04 AM
 *
 * From "Multiprocessor Synchronization and Concurrent Data Structures",
 * by Maurice Herlihy and Nir Shavit.
 * Copyright 2006 Elsevier Inc. All rights reserved.
 */

package spin;

import java.util.concurrent.locks.Lock;
import java.util.concurrent.atomic.AtomicReference;
import java.lang.ThreadLocal;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.TimeUnit;

/**
 * Scott Time-out Lock
 * @author Maurice Herlihy
 */
public class TOLock implements Lock{
  static QNode AVAILABLE = new QNode();
  AtomicReference<QNode> tail;
  ThreadLocal<QNode> myNode;
  public TOLock() {
    tail = new AtomicReference<QNode>(null);
    // thread-local field
    myNode = new ThreadLocal<QNode>() {
      protected QNode initialValue() {
        return new QNode();
      }
    };
  }
  
  public boolean tryLock(long time, TimeUnit unit) throws InterruptedException {
    long startTime = System.nanoTime();
    long patience = TimeUnit.NANOSECONDS.convert(time, unit);
    QNode qnode = new QNode();
    myNode.set(qnode);    // remember for unlock
    qnode.pred = null;
    QNode pred = tail.getAndSet(qnode);
    if (pred == null || pred.pred == AVAILABLE) {
      return true;  // lock was free; just return
    }
    while (System.nanoTime() - startTime < patience) {
      QNode predPred = pred.pred;
      if (predPred == AVAILABLE) {
        return true;
      } else if (predPred != null) {  // skip predecessors
        pred = predPred;
      }
    }
    // timed out; reclaim or abandon own node
    if (!tail.compareAndSet(qnode, pred))
      qnode.pred = pred;
    return false;
  }
  public void unlock() {
    QNode qnode = myNode.get();
    if (!tail.compareAndSet(qnode, null))
      qnode.pred = AVAILABLE;
  }
  
  // any class that implements lock must provide these methods
  public void lock() {
    try {
      tryLock(Long.MAX_VALUE, TimeUnit.NANOSECONDS);
    } catch (InterruptedException ex) {
      ex.printStackTrace();
    }
  }
  public Condition newCondition() {
    throw new java.lang.UnsupportedOperationException();
  }
  public boolean tryLock() {
    try {
      return tryLock(0, TimeUnit.NANOSECONDS);
    } catch (InterruptedException ex) {
      return false;
    }
  }
  public void lockInterruptibly() throws InterruptedException {
    throw new java.lang.UnsupportedOperationException();
  }  
  static class QNode {    // Queue node inner class
    public QNode pred = null;
  }
}


