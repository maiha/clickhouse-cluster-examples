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

## Roadmap

- [x] standalone server with MergeTree
- [x] standalone server with Merge engine and MergeTree
- [x] cluster Distributed MergeTree
- [x] cluster Distributed Merge and MergeTree
- [x] cluster Merge Distributed MergeTree
- [x] cluster simple replication w/o internal_replication
- [ ] cluster ReplicatedMergeTree with ZooKeeper

## Contributing

1. Fork it (<https://github.com/maiha/clickhouse-cluster-examples/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [maiha](https://github.com/maiha) maiha - creator, maintainer

