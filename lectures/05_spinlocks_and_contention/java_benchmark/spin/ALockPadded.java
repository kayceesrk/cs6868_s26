package spin;

/**
 * Anderson lock with padding to prevent false sharing
 */
import java.util.concurrent.locks.Lock;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicBoolean;
import java.lang.ThreadLocal;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.TimeUnit;

public class ALockPadded implements Lock {
  // Padded slot to prevent false sharing
  static class PaddedBoolean {
    volatile boolean value;
    // Padding to fill cache line (64 bytes typical)
    // 1 boolean + 7 longs = 8 + 56 = 64 bytes
    long p1, p2, p3, p4, p5, p6, p7;

    PaddedBoolean(boolean val) {
      this.value = val;
    }
  }

  ThreadLocal<Integer> mySlotIndex = new ThreadLocal<Integer> (){
    protected Integer initialValue() {
      return 0;
    }
  };
  AtomicInteger tail;
  PaddedBoolean[] flag;
  int size;

  public ALockPadded(int capacity) {
    size = capacity;
    tail = new AtomicInteger(0);
    flag = new PaddedBoolean[capacity];
    for (int i = 0; i < capacity; i++) {
      flag[i] = new PaddedBoolean(i == 0);
    }
  }

  public void lock() {
    int slot = tail.getAndIncrement() % size;
    mySlotIndex.set(slot);
    while (!flag[slot].value) {}; // spin
  }

  public void unlock() {
    int slot = mySlotIndex.get();
    flag[slot].value = false;
    flag[(slot + 1) % size].value = true;
  }

  public Condition newCondition() {
    throw new UnsupportedOperationException();
  }
  public boolean tryLock(long time, TimeUnit unit) {
    throw new UnsupportedOperationException();
  }
  public boolean tryLock() {
    throw new UnsupportedOperationException();
  }
  public void lockInterruptibly() throws InterruptedException {
    throw new UnsupportedOperationException();
  }
}
