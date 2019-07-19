S1 := clickhouse-client --port 9001 -m -n -A
S2 := clickhouse-client --port 9002 -m -n -A

.PHONY : test start stop meta data spec info

start:
	docker-compose up -d

stop:
	docker-compose down -v

meta:
	@$(S1) < meta/logs_2018.sql
	@$(S2) < meta/logs_2018.sql
	@$(S1) < meta/logs_2019.sql
	@$(S2) < meta/logs_2019.sql
	@$(S1) < meta/all_logs_2018.sql
	@$(S2) < meta/all_logs_2018.sql
	@$(S1) < meta/all_logs_2019.sql
	@$(S2) < meta/all_logs_2019.sql
	@$(S1) < meta/all_logs.sql
	@$(S2) < meta/all_logs.sql

data:
	@cat data/2018-1.csv | $(S1) -q 'INSERT INTO logs_2018 FORMAT CSV'
	@cat data/2018-2.csv | $(S2) -q 'INSERT INTO logs_2018 FORMAT CSV'
	@cat data/2019-1.csv | $(S1) -q 'INSERT INTO logs_2019 FORMAT CSV'
	@cat data/2019-2.csv | $(S2) -q 'INSERT INTO logs_2019 FORMAT CSV'
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
	@echo '# DATA(s1:all_logs_2018)'
	@$(S1) -q "SELECT * FROM all_logs_2018 ORDER BY date"
	@echo '# DATA(s1:logs_2018)'
	@$(S1) -q "SELECT * FROM logs_2018 ORDER BY date"
	@echo '# DATA(s2:logs_2018)'
	@$(S2) -q "SELECT * FROM logs_2018 ORDER BY date"
	@echo '# DATA(s1:all_logs_2019)'
	@$(S1) -q "SELECT * FROM all_logs_2019 ORDER BY date"
	@echo '# DATA(s1:logs_2019)'
	@$(S1) -q "SELECT * FROM logs_2019 ORDER BY date"
	@echo '# DATA(s2:logs_2019)'
	@$(S2) -q "SELECT * FROM logs_2019 ORDER BY date"
