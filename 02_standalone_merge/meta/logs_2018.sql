DROP TABLE IF EXISTS logs_2018;

CREATE TABLE logs_2018
(
    `date` Date, 
    `value` UInt32
)
ENGINE = MergeTree(date, date, 8192)
;
