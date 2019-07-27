DROP TABLE IF EXISTS logs;

CREATE TABLE logs
(
    `date` Date, 
    `value` UInt32
)
ENGINE = MergeTree(date, date, 8192)
;
