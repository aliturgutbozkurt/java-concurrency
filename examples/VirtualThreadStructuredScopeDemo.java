// Java 25 LTS: Project Loom Structured Concurrency Demo
// Demonstrates StructuredTaskScope.open() with Joiner.awaitAllSuccessfulOrThrow()

import java.util.concurrent.StructuredTaskScope;
import java.util.concurrent.StructuredTaskScope.Subtask;
import java.util.concurrent.StructuredTaskScope.Joiner;

public class VirtualThreadStructuredScopeDemo {
    public record FlightQuote(String airline, double priceUsd) {}
    public record HotelQuote(String hotelName, double priceUsd) {}
    public record TravelPackage(FlightQuote flight, HotelQuote hotel, double totalUsd) {}

    static FlightQuote queryFlightApi() throws InterruptedException {
        // Simulates remote HTTP I/O latency
        Thread.sleep(120);
        return new FlightQuote("Turkish Airlines TK-1923", 420.0);
    }

    static HotelQuote queryHotelApi() throws InterruptedException {
        // Simulates remote HTTP I/O latency
        Thread.sleep(90);
        return new HotelQuote("The Ritz-Carlton", 580.0);
    }

    public static TravelPackage buildTravelPackage() throws Exception {
        // Java 25 Modern StructuredTaskScope with Joiner
        try (var scope = StructuredTaskScope.open(Joiner.awaitAllSuccessfulOrThrow())) {
            Subtask<FlightQuote> flightTask = scope.fork(VirtualThreadStructuredScopeDemo::queryFlightApi);
            Subtask<HotelQuote> hotelTask = scope.fork(VirtualThreadStructuredScopeDemo::queryHotelApi);

            // Wait for all subtasks to complete or fail
            scope.join();

            FlightQuote flight = flightTask.get();
            HotelQuote hotel = hotelTask.get();
            return new TravelPackage(flight, hotel, flight.priceUsd() + hotel.priceUsd());
        } // Guarantee: No orphaned threads survive the scope boundary!
    }

    public static void main(String[] args) throws Exception {
        System.out.println("=== Java 25 LTS: Structured Concurrency with Virtual Threads Demo ===");
        long start = System.currentTimeMillis();

        TravelPackage pkg = buildTravelPackage();

        long duration = System.currentTimeMillis() - start;
        System.out.printf("Package aggregated successfully in %d ms:%n", duration);
        System.out.println("  Flight: " + pkg.flight().airline() + " ($" + pkg.flight().priceUsd() + ")");
        System.out.println("  Hotel:  " + pkg.hotel().hotelName() + " ($" + pkg.hotel().priceUsd() + ")");
        System.out.println("  Total:  $" + pkg.totalUsd());
        System.out.println("=== Structured Concurrency Demo Passed Successfully! ===");
    }
}
