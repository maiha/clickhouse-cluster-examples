DROP TABLE IF EXISTS all_logs;

CREATE TABLE all_logs
(
  `date` Date, 
  `value` UInt32
)
ENGINE = Distributed('c1', default, logs, rand())
