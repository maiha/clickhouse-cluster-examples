CREATE TABLE IF NOT EXISTS all_logs
(
  `date` Date, 
  `value` UInt32
)
ENGINE = Distributed('c1', default, logs, rand())
