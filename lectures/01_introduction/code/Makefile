.PHONY: build clean bench bench-quick bench-full bench-compare bench-seq bench-range bench-counter

LIMIT := 20000000
LIMIT_SMALL := 1000000

build:
	dune build

clean:
	dune clean

# Quick benchmark with 1M (faster iteration)
bench-quick:
	@echo "=== Quick Benchmark ($(LIMIT_SMALL)) ==="
	@hyperfine --warmup 2 \
		--export-markdown results-quick.md \
		'dune exec -- ./prime_sequential.exe $(LIMIT_SMALL)' \
		'dune exec -- ./prime_ranges.exe $(LIMIT_SMALL) 2' \
		'dune exec -- ./prime_ranges.exe $(LIMIT_SMALL) 4' \
		'dune exec -- ./prime_counter.exe $(LIMIT_SMALL) 2' \
		'dune exec -- ./prime_counter.exe $(LIMIT_SMALL) 4'

# Full benchmark with 10M
bench:
	@echo "=== Benchmark ($(LIMIT)) ==="
	@hyperfine --warmup 2 --runs 10 \
		--export-markdown results.md \
		--command-name 'sequential' \
		'dune exec -- ./prime_sequential.exe $(LIMIT)' \
		--command-name 'range-2' \
		'dune exec -- ./prime_ranges.exe $(LIMIT) 2' \
		--command-name 'range-4' \
		'dune exec -- ./prime_ranges.exe $(LIMIT) 4' \
		--command-name 'range-8' \
		'dune exec -- ./prime_ranges.exe $(LIMIT) 8' \
		--command-name 'counter-2' \
		'dune exec -- ./prime_counter.exe $(LIMIT) 2' \
		--command-name 'counter-4' \
		'dune exec -- ./prime_counter.exe $(LIMIT) 4' \
		--command-name 'counter-8' \
		'dune exec -- ./prime_counter.exe $(LIMIT) 8'

# Compare just range vs counter at 4 domains
bench-compare:
	@echo "=== Range vs Counter Comparison (4 domains, $(LIMIT)) ==="
	@hyperfine --warmup 3 --runs 10 \
		--export-markdown results-compare.md \
		--command-name 'range-4' \
		'dune exec -- ./prime_ranges.exe $(LIMIT) 4' \
		--command-name 'counter-4' \
		'dune exec -- ./prime_counter.exe $(LIMIT) 4'

# Individual benchmarks
bench-seq:
	@echo "=== Sequential Benchmark ==="
	@hyperfine --warmup 2 --runs 10 \
		'dune exec -- ./prime_sequential.exe $(LIMIT)'

bench-range:
	@echo "=== Range-based Benchmark ==="
	@hyperfine --warmup 2 --runs 10 \
		--command-name 'range-2' \
		'dune exec -- ./prime_ranges.exe $(LIMIT) 2' \
		--command-name 'range-4' \
		'dune exec -- ./prime_ranges.exe $(LIMIT) 4' \
		--command-name 'range-8' \
		'dune exec -- ./prime_ranges.exe $(LIMIT) 8'

bench-counter:
	@echo "=== Counter-based Benchmark ==="
	@hyperfine --warmup 2 --runs 10 \
		--command-name 'counter-2' \
		'dune exec -- ./prime_counter.exe $(LIMIT) 2' \
		--command-name 'counter-4' \
		'dune exec -- ./prime_counter.exe $(LIMIT) 4' \
		--command-name 'counter-8' \
		'dune exec -- ./prime_counter.exe $(LIMIT) 8'

# Full benchmark suite including scalability tests
bench-full: build
	@echo "=== Full Benchmark Suite ==="
	@echo "Testing $(LIMIT) numbers with multiple domain counts..."
	@hyperfine --warmup 3 --runs 10 \
		--export-json results.json \
		--export-markdown results.md \
		--command-name 'sequential' \
		'dune exec -- ./prime_sequential.exe $(LIMIT)' \
		--command-name 'range-2d' \
		'dune exec -- ./prime_ranges.exe $(LIMIT) 2' \
		--command-name 'range-4d' \
		'dune exec -- ./prime_ranges.exe $(LIMIT) 4' \
		--command-name 'range-8d' \
		'dune exec -- ./prime_ranges.exe $(LIMIT) 8' \
		--command-name 'counter-2d' \
		'dune exec -- ./prime_counter.exe $(LIMIT) 2' \
		--command-name 'counter-4d' \
		'dune exec -- ./prime_counter.exe $(LIMIT) 4' \
		--command-name 'counter-8d' \
		'dune exec -- ./prime_counter.exe $(LIMIT) 8'
	@echo ""
	@echo "Results saved to results.md and results.json"
