S1 := clickhouse-client --port 9001 -m -n -A
S2 := clickhouse-client --port 9002 -m -n -A

.PHONY : test start stop meta data spec info

start:
	docker-compose up -d

stop:
	docker-compose down -v

meta:
	@$(S1) < meta/logs.sql
	@$(S2) < meta/logs.sql
	@$(S1) < meta/all_logs.sql
	@$(S2) < meta/all_logs.sql

data:
	@cat data/*.csv | $(S1) -q 'INSERT INTO all_logs FORMAT CSV'
	@sleep 1 # wait a moment for async replication

spec:
	@mkdir -p tmp
	@$(S1) -q "SELECT * FROM all_logs FORMAT CSV" | sort > tmp/got.csv
	@cat data/*.csv | sort > tmp/expected.csv
	@diff tmp/got.csv tmp/expected.csv && echo "OK: $@"

test: meta data spec

.PHONY : info
info:
	@echo '# DATA(s1:all_logs)'
	@$(S1) -q "SELECT * FROM all_logs ORDER BY date"
	@echo '# DATA(s1:logs)'
	@$(S1) -q "SELECT * FROM logs ORDER BY date"
	@echo '# DATA(s2:logs)'
	@$(S2) -q "SELECT * FROM logs ORDER BY date"
