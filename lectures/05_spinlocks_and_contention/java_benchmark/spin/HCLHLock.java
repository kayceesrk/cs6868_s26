/*
 * HCLHLock.java
 *
 * Created on April 13, 2006, 9:28 PM
 *
 * From "Multiprocessor Synchronization and Concurrent Data Structures",
 * by Maurice Herlihy and Nir Shavit.
 * Copyright 2006 Elsevier Inc. All rights reserved.
 */

package spin;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;

/**
 * Hierarchical CLH Lock
 * @author Maurice Herlihy
 */
public class HCLHLock implements Lock {
  /**
   * Max number of clusters
   */
  static final int MAX_CLUSTERS = 32;
  /**
   * List of local queues, one per cluster
   */
  List<AtomicReference<QNode>> localQueues;
  /**
   * single global queue
   */
  AtomicReference<QNode> globalQueue;
  /**
   * My current QNode
   */
  ThreadLocal<QNode> currNode = new ThreadLocal<QNode>() {
    protected QNode initialValue() { return new QNode(); };
  };
  /**
   * My predecessor QNode
   */
  ThreadLocal<QNode> predNode = new ThreadLocal<QNode>() {
    protected QNode initialValue() { return null; };
  };
  
  /** Creates a new instance of HCLHLock */
  public HCLHLock() {
    localQueues = new ArrayList<AtomicReference<QNode>>(MAX_CLUSTERS);
    for (int i = 0; i < MAX_CLUSTERS; i++) {
      localQueues.add(new AtomicReference <QNode>());
    }
    QNode head = new QNode();
    globalQueue = new AtomicReference<QNode>(head);
    
  }
  
  public void lock() {
    QNode myNode = currNode.get();
    AtomicReference<QNode> localQueue = localQueues.get(ThreadID.getCluster());
    // splice my QNode into local queue
    QNode myPred = null;
    do {
      myPred = localQueue.get();
    } while (!localQueue.compareAndSet(myPred, myNode));
    if (myPred != null) {
      boolean iOwnLock = myPred.waitForGrantOrClusterMaster();
      if (iOwnLock) {
        // I have the lock. Save QNode just released by previous leader
        predNode.set(myPred);
        return;
      }
    }
    // At this point I am the cluster master.
    // Splice local queue into global queue.
    QNode localTail = null;
    do {
      myPred = globalQueue.get();
      localTail = localQueue.get();
    } while(!globalQueue.compareAndSet(myPred, localTail));
    // inform successor it is the new master
    localTail.setTailWhenSpliced(true);
    // wait for predecessor to release lock
    while (myPred.isSuccessorMustWait()) {};
    // I have the lock. Save QNode just released by previous leader
    predNode.set(myPred);
    return;
  }
  
  public void unlock() {
    QNode myNode = currNode.get();
    myNode.setSuccessorMustWait(false);
    // promote pred node to current
    QNode node = predNode.get();
    node.unlock();
    currNode.set(node);
  }
  
  static class QNode {
    // private boolean tailWhenSpliced;
    private static final int TWS_MASK = 0x80000000;
    // private boolean successorMustWait= false;
    private static final int SMW_MASK = 0x40000000;
    // private int clusterID;
    private static final int CLUSTER_MASK = 0x3FFFFFFF;
    AtomicInteger state;
    public QNode() {
      state = new AtomicInteger(0);
    }
    boolean waitForGrantOrClusterMaster() {
      int myCluster = ThreadID.getCluster();
      while(true) {
        if (getClusterID() == myCluster &&
            !isTailWhenSpliced() &&
            !isSuccessorMustWait()) {
          return true;
        } else if (getClusterID() != myCluster || isTailWhenSpliced()) {
          return false;
        }
      }
    }
    public void unlock() {
      int oldState = 0;
      int newState = ThreadID.getCluster();
      // successorMustWait = true;
      newState |= SMW_MASK;
      // tailWhenSpliced = false;
      newState &= (~TWS_MASK);
      do {
        oldState = state.get();
      } while (! state.compareAndSet(oldState, newState));
    }
    
    public int getClusterID() {
      return state.get() & CLUSTER_MASK;
    }
    
    public void setClusterID(int clusterID) {
      int oldState, newState;
      do {
        oldState = state.get();
        newState = (oldState & ~CLUSTER_MASK) | clusterID;
      } while (! state.compareAndSet(oldState, newState));
    }
    
    public boolean isSuccessorMustWait() {
      return (state.get() & SMW_MASK) != 0;
    }
    
    public void setSuccessorMustWait(boolean successorMustWait) {
      int oldState, newState;
      do {
        oldState = state.get();
        if (successorMustWait) {
          newState = oldState | SMW_MASK;
        } else {
          newState = oldState & ~SMW_MASK;
        }
      } while (! state.compareAndSet(oldState, newState));
    }
    
    public boolean isTailWhenSpliced() {
      return (state.get() & TWS_MASK) != 0;
    }
    
    public void setTailWhenSpliced(boolean tailWhenSpliced) {
      int oldState, newState;
      do {
        oldState = state.get();
        if (tailWhenSpliced) {
          newState = oldState | TWS_MASK;
        } else {
          newState = oldState & ~TWS_MASK;
        }
      } while (! state.compareAndSet(oldState, newState));
    }
    
  }
  
  // superfluous declarations needed to satisfy lock interface
  public void lockInterruptibly() throws InterruptedException {
    throw new UnsupportedOperationException();
  }
  
  public boolean tryLock() {
    throw new UnsupportedOperationException();
  }
  
  public boolean tryLock(long time, TimeUnit unit) throws InterruptedException {
    throw new UnsupportedOperationException();
  }
  
  public Condition newCondition() {
    throw new UnsupportedOperationException();
  }
  
}
