CREATE TABLE IF NOT EXISTS all_logs
(
  `date` Date, 
  `value` UInt32
)
ENGINE = Merge(default, '^all_logs_')
