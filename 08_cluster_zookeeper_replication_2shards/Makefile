S1 := clickhouse-client --port 9001 -m -n -A
S2 := clickhouse-client --port 9002 -m -n -A
S3 := clickhouse-client --port 9003 -m -n -A
S4 := clickhouse-client --port 9004 -m -n -A

.PHONY : test start stop meta data1 data2 spec info

all:
	@make -s start test || true
	@make -s stop               # ensures to stop containers

start:
	docker-compose up -d

stop:
	docker-compose down -v

meta:
	@$(S1) < meta/logs.sql
	@$(S2) < meta/logs.sql
	@$(S3) < meta/logs.sql
	@$(S4) < meta/logs.sql
	@$(S1) < meta/all_logs.sql
	@$(S2) < meta/all_logs.sql
	@$(S3) < meta/all_logs.sql
	@$(S4) < meta/all_logs.sql
	@$(S1) < meta/logs_tmp.sql
	@$(S2) < meta/logs_tmp.sql
	@$(S3) < meta/logs_tmp.sql
	@$(S4) < meta/logs_tmp.sql

data1:
	@cat data/1/2018*.csv | $(S1) -q 'INSERT INTO logs FORMAT CSV'
	@cat data/1/2019*.csv | $(S3) -q 'INSERT INTO logs FORMAT CSV'
	@sleep 1 # wait a moment for async replication

data2: data2via3

data2via1:
	@cat data/2/*.csv | $(S1) -q 'INSERT INTO logs_tmp FORMAT CSV'
	@$(S1) -q "ALTER TABLE logs REPLACE PARTITION '2019-01-01' FROM logs_tmp"
	@sleep 1 # wait a moment for async replication

data2via3:
	@cat data/2/*.csv | $(S3) -q 'INSERT INTO logs_tmp FORMAT CSV'
	@$(S3) -q "ALTER TABLE logs REPLACE PARTITION '2019-01-01' FROM logs_tmp"
	@sleep 1 # wait a moment for async replication

spec1:
	@mkdir -p tmp
	@$(S3) -q "SELECT * FROM all_logs FORMAT CSV" | sort > tmp/got.csv
	@cat data/1/*.csv | sort > tmp/expected.csv
	@diff tmp/got.csv tmp/expected.csv && echo "OK: $@"

spec2:
	@mkdir -p tmp
	@$(S3) -q "SELECT * FROM all_logs FORMAT CSV" | sort > tmp/got.csv
	@cat data/2/*.csv data/1/*.csv | sort -u -t, -k1,1 > tmp/expected.csv
	@diff tmp/got.csv tmp/expected.csv && echo "OK: $@"

test: clean meta data1 spec1 data2 spec2

clean: zk-clear

zk-clear:
	@docker-compose exec zk zkCli.sh deleteall /clickhouse/tables > /dev/null || true

.PHONY : info
info:
	@echo '# DATA(s1:all_logs)'
	@$(S1) -q "SELECT * FROM all_logs ORDER BY date" || true
	@echo '# DATA(s2:all_logs)'
	@$(S2) -q "SELECT * FROM all_logs ORDER BY date" || true
	@echo '# DATA(s3:all_logs)'
	@$(S3) -q "SELECT * FROM all_logs ORDER BY date" || true
	@echo '# DATA(s4:all_logs)'
	@$(S4) -q "SELECT * FROM all_logs ORDER BY date" || true
	@echo '# DATA(s1:logs)'
	@$(S1) -q "SELECT * FROM logs ORDER BY date" || true
	@echo '# DATA(s2:logs)'
	@$(S2) -q "SELECT * FROM logs ORDER BY date" || true
	@echo '# DATA(s3:logs)'
	@$(S3) -q "SELECT * FROM logs ORDER BY date" || true
	@echo '# DATA(s4:logs)'
	@$(S4) -q "SELECT * FROM logs ORDER BY date" || true

.PHONY : log1 log2 log3 log4 err1 err2 err3 err4
log1:
	@docker-compose exec -T s1 cat /var/log/clickhouse-server/clickhouse-server.log

log2:
	@docker-compose exec -T s2 cat /var/log/clickhouse-server/clickhouse-server.log

log3:
	@docker-compose exec -T s3 cat /var/log/clickhouse-server/clickhouse-server.log

log4:
	@docker-compose exec -T s4 cat /var/log/clickhouse-server/clickhouse-server.log

err1:
	@docker-compose exec -T s1 cat /var/log/clickhouse-server/clickhouse-server.err.log

err2:
	@docker-compose exec -T s2 cat /var/log/clickhouse-server/clickhouse-server.err.log

err3:
	@docker-compose exec -T s3 cat /var/log/clickhouse-server/clickhouse-server.err.log

err4:
	@docker-compose exec -T s4 cat /var/log/clickhouse-server/clickhouse-server.err.log
