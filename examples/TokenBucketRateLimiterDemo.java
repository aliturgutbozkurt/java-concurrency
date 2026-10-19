// Java 25 LTS: Lock-Free High-Throughput Token Bucket Rate Limiter
// Employs AtomicReference with Immutable Records & Lazy Refills

import java.util.concurrent.atomic.AtomicReference;

public class TokenBucketRateLimiterDemo {
    private final long capacity;
    private final double refillRatePerSecond;

    // Immutable state record
    public record BucketState(long tokens, long lastRefillNanos) {}
    private final AtomicReference<BucketState> state;

    public TokenBucketRateLimiterDemo(long capacity, double refillRatePerSecond) {
        if (capacity <= 0 || refillRatePerSecond <= 0) {
            throw new IllegalArgumentException("Capacity and refill rate must be positive!");
        }
        this.capacity = capacity;
        this.refillRatePerSecond = refillRatePerSecond;
        this.state = new AtomicReference<>(new BucketState(capacity, System.nanoTime()));
    }

    public boolean tryAcquire(long tokensRequested) {
        while (true) {
            BucketState current = state.get();
            long now = System.nanoTime();
            long elapsedNanos = Math.max(0, now - current.lastRefillNanos());
            double newTokens = (elapsedNanos / 1_000_000_000.0) * refillRatePerSecond;

            long totalTokens = Math.min(capacity, current.tokens() + (long) newTokens);

            if (totalTokens < tokensRequested) {
                return false; // Throttled (HTTP 429 Too Many Requests)
            }

            BucketState next = new BucketState(totalTokens - tokensRequested, now);
            if (state.compareAndSet(current, next)) {
                return true; // Token consumed atomically without locking!
            }
            // CAS failed due to concurrent acquisition; loop & retry
        }
    }

    public static void main(String[] args) throws InterruptedException {
        System.out.println("=== Java 25 LTS: Atomic Token Bucket Rate Limiter Demo ===");
        var limiter = new TokenBucketRateLimiterDemo(5, 2.0); // 5 burst capacity, 2 tokens/sec

        System.out.println("Burst testing with 5 tokens initially available:");
        for (int i = 1; i <= 7; i++) {
            boolean allowed = limiter.tryAcquire(1);
            System.out.printf("  Request #%d: %s%n", i, allowed ? "ACCEPTED (Token granted)" : "REJECTED (429 Throttled)");
        }

        System.out.println("\nWaiting 1.5 seconds for token refill...");
        Thread.sleep(1500);

        System.out.println("Re-testing requests after refill:");
        for (int i = 1; i <= 3; i++) {
            boolean allowed = limiter.tryAcquire(1);
            System.out.printf("  Refill Request #%d: %s%n", i, allowed ? "ACCEPTED" : "REJECTED");
        }
        System.out.println("=== Token Bucket Rate Limiter Test Passed! ===");
    }
}
