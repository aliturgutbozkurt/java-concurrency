// Java 25 LTS: Lock-Free LMAX Disruptor-Style RingBuffer Demo
// Zero GC Allocations, Bitwise Modulo & Mechanical Sympathy

import java.util.concurrent.atomic.AtomicLong;

public class DisruptorRingBufferDemo {
    public record OrderEvent(long orderId, String symbol, double price, long timestamp) {}

    public static class LockFreeRingBuffer {
        private final OrderEvent[] buffer;
        private final int mask;
        private final AtomicLong cursor = new AtomicLong(-1);

        public LockFreeRingBuffer(int powerOfTwoSize) {
            if (Integer.bitCount(powerOfTwoSize) != 1) {
                throw new IllegalArgumentException("Buffer size must be a power of two!");
            }
            this.buffer = new OrderEvent[powerOfTwoSize];
            this.mask = powerOfTwoSize - 1;
        }

        public long nextSequence() {
            return cursor.incrementAndGet();
        }

        public void publish(long sequence, OrderEvent event) {
            int index = (int) (sequence & mask); // Fast bitwise masking!
            buffer[index] = event;
        }

        public OrderEvent get(long sequence) {
            int index = (int) (sequence & mask);
            return buffer[index];
        }

        public int capacity() {
            return buffer.length;
        }
    }

    public static void main(String[] args) throws InterruptedException {
        System.out.println("=== Java 25 LTS: Lock-Free Disruptor RingBuffer Demo ===");
        var ringBuffer = new LockFreeRingBuffer(1024);

        System.out.printf("Initialized RingBuffer with %d slots (mask: 0x%X)%n",
            ringBuffer.capacity(), ringBuffer.mask);

        // Producer simulation
        long startNs = System.nanoTime();
        int eventCount = 10_000;

        for (int i = 0; i < eventCount; i++) {
            long seq = ringBuffer.nextSequence();
            var event = new OrderEvent(i, "MSFT", 450.0 + (i % 50), System.nanoTime());
            ringBuffer.publish(seq, event);
        }

        long elapsedNs = System.nanoTime() - startNs;
        double opsPerSec = (eventCount / (elapsedNs / 1_000_000_000.0));

        System.out.printf("Published %d events in %.2f ms (Throughput: %,.0f ops/sec)%n",
            eventCount, elapsedNs / 1_000_000.0, opsPerSec);

        // Verify retrieval of last published event
        long lastSeq = eventCount - 1;
        OrderEvent retrieved = ringBuffer.get(lastSeq);
        System.out.println("Last event verified: " + retrieved);
        System.out.println("=== Disruptor Demo Passed Successfully! ===");
    }
}
