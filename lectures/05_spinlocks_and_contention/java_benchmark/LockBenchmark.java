import java.util.concurrent.locks.Lock;
import java.util.concurrent.atomic.AtomicLong;
import spin.*;

public class LockBenchmark {

    static class Counter {
        private long value = 0;

        public void increment() {
            value++;
        }

        public long get() {
            return value;
        }
    }

    static void benchmarkLock(Lock lock, String name, int threads, int iterations) {
        Counter counter = new Counter();

        Runnable task = () -> {
            for (int i = 0; i < iterations; i++) {
                lock.lock();
                try {
                    counter.increment();
                } finally {
                    lock.unlock();
                }
            }
        };

        Thread[] threadArray = new Thread[threads];

        long start = System.nanoTime();

        for (int i = 0; i < threads; i++) {
            threadArray[i] = new Thread(task);
            threadArray[i].start();
        }

        try {
            for (Thread t : threadArray) {
                t.join();
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        long end = System.nanoTime();
        double elapsed = (end - start) / 1e9;

        long expected = (long) threads * iterations;
        long actual = counter.get();

        double throughput = (threads * iterations) / elapsed;

        System.out.printf("%-20s %6.3fs  %10.0f ops/s  %s%n",
            name, elapsed, throughput,
            (actual == expected ? "✓" : "✗ FAILED"));
    }

    public static void main(String[] args) {
        int iterations = 50000;

        System.out.println("=== Java Spinlock Performance Comparison ===\n");
        System.out.printf("Configuration: %d iterations/thread\n\n", iterations);
        System.out.printf("%-20s %-10s %-15s %s%n", "Lock", "Time", "Throughput", "Correct");
        System.out.println("-".repeat(65));

        for (int threads = 1; threads <= 8; threads++) {
            System.out.printf("\n%d threads:%n", threads);

            benchmarkLock(new TASLock(), "TAS", threads, iterations);
            benchmarkLock(new TTASLock(), "TTAS", threads, iterations);
            benchmarkLock(new BackoffLock(), "Backoff", threads, iterations);
            benchmarkLock(new ALock(threads), "ALock", threads, iterations);
            benchmarkLock(new ALockPadded(threads), "ALock (padded)", threads, iterations);
        }
    }
}
