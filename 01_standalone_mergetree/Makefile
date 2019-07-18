S1 := clickhouse-client --port 9001 -m -n -A

.PHONY : test start stop meta data spec info

start:
	docker-compose up -d

stop:
	docker-compose down -v

meta:
	@$(S1) < meta/logs.sql

data:
	@cat data/*.csv | $(S1) -q 'INSERT INTO logs FORMAT CSV'

spec:
	@mkdir -p tmp
	@$(S1) -q "SELECT * FROM logs FORMAT CSV" | sort > tmp/got.csv
	@cat data/*.csv | sort > tmp/expected.csv
	@diff tmp/got.csv tmp/expected.csv && echo "OK: $@"

test: meta data spec

.PHONY : info
info:
	@echo '# DATA(s1:logs)'
	@$(S1) -q "SELECT * FROM logs ORDER BY date"
