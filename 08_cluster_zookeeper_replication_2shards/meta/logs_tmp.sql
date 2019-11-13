DROP TABLE IF EXISTS logs_tmp;

CREATE TABLE logs_tmp
(
    `date` Date, 
    `value` UInt32
)
ENGINE = MergeTree
PARTITION BY date
ORDER BY tuple()
;
