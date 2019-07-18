S1 := clickhouse-client --port 9001 -m -n -A

.PHONY : test start stop meta data spec info

start:
	docker-compose up -d

stop:
	docker-compose down -v

meta:
	@$(S1) < meta/logs_2018.sql
	@$(S1) < meta/logs_2019.sql
	@$(S1) < meta/logs.sql

data:
	@cat data/2018*.csv | $(S1) -q 'INSERT INTO logs_2018 FORMAT CSV'
	@cat data/2019*.csv | $(S1) -q 'INSERT INTO logs_2019 FORMAT CSV'

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
	@echo '# DATA(s1:logs_2018)'
	@$(S1) -q "SELECT * FROM logs_2018 ORDER BY date"
	@echo '# DATA(s1:logs_2019)'
	@$(S1) -q "SELECT * FROM logs_2019 ORDER BY date"
