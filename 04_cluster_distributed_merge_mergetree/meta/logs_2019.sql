DROP TABLE IF EXISTS logs_2019;

CREATE TABLE logs_2019
(
    `date` Date, 
    `value` UInt32
)
ENGINE = MergeTree(date, date, 8192)
;
