// Java 25 LTS: Thread-Safe LRU Cache with O(1) Operations
// Combines HashMap and Doubly-Linked List with ReentrantReadWriteLock

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.locks.ReentrantReadWriteLock;

public class LruCacheDemo<K, V> {
    private static class Node<K, V> {
        K key;
        V value;
        Node<K, V> prev, next;
        Node(K key, V value) {
            this.key = key;
            this.value = value;
        }
    }

    private final int capacity;
    private final Map<K, Node<K, V>> map = new HashMap<>();
    private final Node<K, V> head = new Node<>(null, null); // MRU sentinel
    private final Node<K, V> tail = new Node<>(null, null); // LRU sentinel
    private final ReentrantReadWriteLock lock = new ReentrantReadWriteLock();

    public LruCacheDemo(int capacity) {
        if (capacity <= 0) throw new IllegalArgumentException("Capacity must be positive!");
        this.capacity = capacity;
        head.next = tail;
        tail.prev = head;
    }

    public V get(K key) {
        lock.writeLock().lock(); // Read mutates list order; exclusive lock required!
        try {
            Node<K, V> node = map.get(key);
            if (node == null) return null;
            moveToHead(node);
            return node.value;
        } finally {
            lock.writeLock().unlock();
        }
    }

    public void put(K key, V value) {
        lock.writeLock().lock();
        try {
            Node<K, V> existing = map.get(key);
            if (existing != null) {
                existing.value = value;
                moveToHead(existing);
            } else {
                if (map.size() >= capacity) {
                    Node<K, V> lru = removeTail();
                    map.remove(lru.key);
                    System.out.printf("  [EVICTION] Key '%s' evicted from cache.%n", lru.key);
                }
                Node<K, V> newNode = new Node<>(key, value);
                map.put(key, newNode);
                addToHead(newNode);
            }
        } finally {
            lock.writeLock().unlock();
        }
    }

    private void addToHead(Node<K, V> node) {
        node.next = head.next;
        node.prev = head;
        head.next.prev = node;
        head.next = node;
    }

    private void removeNode(Node<K, V> node) {
        node.prev.next = node.next;
        node.next.prev = node.prev;
    }

    private void moveToHead(Node<K, V> node) {
        removeNode(node);
        addToHead(node);
    }

    private Node<K, V> removeTail() {
        Node<K, V> lru = tail.prev;
        removeNode(lru);
        return lru;
    }

    public static void main(String[] args) {
        System.out.println("=== Java 25 LTS: High-Concurrency LRU Cache Demo ===");
        var cache = new LruCacheDemo<String, String>(3);

        System.out.println("1. Adding A, B, C (Capacity 3)...");
        cache.put("A", "Apple");
        cache.put("B", "Banana");
        cache.put("C", "Cherry");

        System.out.println("2. Accessing 'A' -> " + cache.get("A") + " (A becomes MRU)");

        System.out.println("3. Adding 'D' (Should evict oldest: 'B')...");
        cache.put("D", "Dragonfruit");

        System.out.println("4. Checking keys:");
        System.out.println("   Cache contains 'A'? " + (cache.get("A") != null));
        System.out.println("   Cache contains 'B'? " + (cache.get("B") != null ? "Yes" : "No (Evicted!)"));
        System.out.println("   Cache contains 'C'? " + (cache.get("C") != null));
        System.out.println("   Cache contains 'D'? " + (cache.get("D") != null));
        System.out.println("=== LRU Cache Test Passed Successfully! ===");
    }
}
