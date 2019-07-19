CREATE TABLE IF NOT EXISTS all_logs_2018
(
  `date` Date, 
  `value` UInt32
)
ENGINE = Distributed('c1', default, logs_2018, rand())
