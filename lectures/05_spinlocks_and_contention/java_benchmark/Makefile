# Makefile for Java Lock Benchmarks

# Compiler settings
JAVAC = javac
JAVA = java
JAVAC_FLAGS = -d . -Xlint:unchecked

# Source directories
SPIN_DIR = spin
SRC_FILES = $(wildcard $(SPIN_DIR)/*.java) LockBenchmark.java

# Main class
MAIN_CLASS = LockBenchmark

# Default iterations
ITERATIONS = 50000

.PHONY: all build run clean help

# Default target
all: build

# Build all Java files
build:
	@echo "Compiling Java lock implementations..."
	$(JAVAC) $(JAVAC_FLAGS) $(SRC_FILES)
	@echo "Build complete!"

# Run the benchmark
run: build
	@echo "Running lock benchmarks..."
	@echo ""
	$(JAVA) $(MAIN_CLASS)

# Run with custom iterations
run-custom: build
	@echo "Running lock benchmarks with $(ITERATIONS) iterations..."
	@echo ""
	$(JAVA) $(MAIN_CLASS) $(ITERATIONS)

# Clean compiled files
clean:
	@echo "Cleaning compiled files..."
	rm -f *.class $(SPIN_DIR)/*.class
	@echo "Clean complete!"

# Help target
help:
	@echo "Available targets:"
	@echo "  make build       - Compile all Java files"
	@echo "  make run         - Build and run benchmarks with default iterations"
	@echo "  make run-custom  - Build and run with ITERATIONS=N (e.g., make run-custom ITERATIONS=100000)"
	@echo "  make clean       - Remove all compiled class files"
	@echo "  make help        - Show this help message"
