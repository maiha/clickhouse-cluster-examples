# clickhouse-cluster-examples

ClickHouse offers various cluster topologies. And the concepts of `replication`, `distribution`, `merging` and `sharding`
are very confusing.

Here are some examples of actual setups to represent them to ClickHouse in various ways, using simple schemas and data as belows.

## schema

```sql
CREATE TABLE logs
(
  `date` Date, 
  `value` UInt32
)
ENGINE = MergeTree(date, date, 8192);
```

## data

```
2018-12-30      1
2018-12-31      2
2019-01-01      3
2019-01-02      4
```

## Contributing

1. Fork it (<https://github.com/maiha/clickhouse-cluster-examples/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [maiha](https://github.com/maiha) maiha - creator, maintainer

<!---
[graph]
01: https://textik.com/#98799a1d845a311d
03: https://textik.com/#64ef17979edd8908
04: https://textik.com/#a84780caf2f6ec42
  -->
