DROP TABLE IF EXISTS logs;

CREATE TABLE logs
(
    `date` Date, 
    `value` UInt32
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/default.logs', '{replica}')
PARTITION BY date
ORDER BY tuple()
;
