/*
 * CompositeLock.java
 *
 * Created on April 11, 2006, 9:12 PM
 *
 * From "Multiprocessor Synchronization and Concurrent Data Structures",
 * by Maurice Herlihy and Nir Shavit.
 * Copyright 2006 Elsevier Inc. All rights reserved.
 */

package spin;

import java.lang.UnsupportedOperationException;
import java.util.Random;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicReference;
import java.util.concurrent.atomic.AtomicStampedReference;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;

/**
 * CompositeLock Abortable Lock
 * @author Maurice Herlihy
 */
public class CompositeLock implements Lock{
  private static final int SIZE = 4;
  private static final int MIN_BACKOFF = 1024;
  private static final int MAX_BACKOFF = 256 * MIN_BACKOFF;
  AtomicStampedReference<QNode> tail;
  QNode[] waiting;
  Random random;
  ThreadLocal<QNode> myNode = new ThreadLocal<QNode>() {
    protected QNode initialValue() { return null; };
  };
  
  /**
   * Creates a new instance of CompositeLock
   */
  public CompositeLock() {
    tail = new AtomicStampedReference<QNode>(null, 0);
    random = new Random();
    waiting = new QNode[SIZE];
    for (int i = 0; i < waiting.length; i++) {
      waiting[i] = new QNode();
    }
  }
  
  public void lock() {
    try {
      tryLock(Long.MAX_VALUE, TimeUnit.MILLISECONDS);
    } catch (InterruptedException ex) {
      ex.printStackTrace();
    }
  }
  
  public void lockInterruptibly() throws InterruptedException {
    throw new UnsupportedOperationException();
  }
  
  public boolean tryLock() {
    try {
      return tryLock(0, TimeUnit.MILLISECONDS);
    } catch (InterruptedException ex) {
      return false;
    }
  }
  
  public boolean tryLock(long time, TimeUnit unit) throws InterruptedException {
    long patience = TimeUnit.MILLISECONDS.convert(time, unit);
    long startTime = System.currentTimeMillis();
    Backoff backoff = new Backoff(MIN_BACKOFF, MAX_BACKOFF);
    try {
      QNode node = acquireQNode(backoff, startTime, patience);
      QNode pred = spliceQNode(node, startTime, patience);
      waitForPredecessor(pred, node, startTime, patience);
      return true;
    } catch (TimeoutException e) {
      return false;
    }
  }
  
  public void unlock() {
    QNode acqNode = myNode.get();
    acqNode.state.set(State.RELEASED);
  }
  
  public Condition newCondition() {
    throw new UnsupportedOperationException();
  }
  
  private boolean timeout(long startTime, long patience) {
    return System.currentTimeMillis() - startTime > patience;
  }
  
  private QNode acquireQNode(Backoff backoff, long startTime, long patience)
      throws TimeoutException, InterruptedException {
    QNode node = waiting[random.nextInt(SIZE)];
    QNode currTail;
    int[] currStamp = {0};
    while (true) {
      if (node.state.compareAndSet(State.FREE, State.WAITING)) {
        return node;
      }
      currTail = tail.get(currStamp);
      State state = node.state.get();
      if (state == State.ABORTED || state == State.RELEASED) {
        if (node == currTail) {
          QNode myPred = null;
          if (state == State.ABORTED) {
            myPred = node.pred;
          }
          if (tail.compareAndSet(currTail, myPred,
              currStamp[0], currStamp[0]+1)) {
            node.state.set(State.WAITING);
            return node;
          }
        }
      }
      backoff.backoff();
      if (timeout(patience, startTime)) {
        throw new TimeoutException();
      }
    }
  }
  
  private QNode spliceQNode(QNode node, long startTime, long patience)
      throws TimeoutException {
    QNode currTail;
    int[] currStamp = {0};
    // splice node into queue
    do {
      currTail = tail.get(currStamp);
      if (timeout(startTime, patience)) {
        node.state.set(State.FREE);
        throw new TimeoutException();
      }
    } while (!tail.compareAndSet(currTail, node,
        currStamp[0], currStamp[0]+1));
    return currTail;
  }
  
  private void waitForPredecessor(QNode pred, QNode node, long startTime, long patience)
      throws TimeoutException {
    // wait for predecessor to release lock
    int[] stamp = {0};
    if (pred == null) {
      myNode.set(node);
      return;
    }
    State predState = pred.state.get();
    while (predState != State.RELEASED) {
      if (predState == State.ABORTED) {
        QNode temp = pred;
        pred = pred.pred;
        temp.state.set(State.FREE);
      }
      if (timeout(patience, startTime)) {
        node.pred = pred;
        node.state.set(State.ABORTED);
        throw new TimeoutException();
      }
      predState = pred.state.get();
    }
    pred.state.set(State.FREE);
    myNode.set(node);
    return;
  }
  
  /*
   * Internal classes
   */
  enum State {FREE, WAITING, RELEASED, ABORTED};
  class QNode {
    AtomicReference<State> state;
    QNode pred;
    public QNode() {
      state = new AtomicReference<State>(State.FREE);
    }
  }
}
