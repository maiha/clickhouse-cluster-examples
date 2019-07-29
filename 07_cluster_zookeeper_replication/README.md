# cluster Replicated MergeTree with ZooKeeper

**Replicated** engine provides replication among servers for `INSERT` and `ALTER` queries.

- [ZooKeeper](./docker-compose.yml) ( `zk:2181` )
- [2 nodes](./docker-compose.yml) ( `s1:9000`, `s2:9000`, )
- 1 table per 1 node

<!---
https://textik.com/#70c1d375c4225465
-->

```text
 all_logs : Distributed(c1, logs) # <-- 1.WRITE
                             |
 <-------------------------------------------------------------------------->
                   2.WRITE   |
    s1:9000 <----------------+          s2:9000
    +--------------------------------+  +--------------------------------+
    | +----------------------------+ |  | +----------------------------+ |
    | | logs : ReplicatedMergeTree | |  | | logs : ReplicatedMergeTree | |
    | +----------------------------+ |  | +----------------------------+ |
    |  |            ["2018-12-30",1] |  |               ["2018-12-30",1] |
    |  |            ["2018-12-31",2] |  |               ["2018-12-31",2] |
    |  |            ["2019-01-01",3] |  |               ["2019-01-01",3] |
    |  |            ["2019-01-02",4] |  |               ["2019-01-02",4] |
    +--|-----------------------------+  +--------------------------------+
       |  zk:2181                                                    |
       |  +----------------------------------------------------+     |
       |  |      +-----------------------------------------+   |     |
       +-------> | /clickhouse/tables/1/default.logs/block | <-------+
  3.WRITE |      +-----------------------------------------+   |  4.SYNC
          | [20181230_5383472499804002539_1700904329733462805] |
          | [20181231_1114583668837677782_7297308974928976135] |
          | [20190101_3142061115699531382_7149022940449705633] |
          | [20190102_1108493909296339633_1780074824470156015] |
          +----------------------------------------------------+
```

## ZooKeeper

- write location of ZooKeeper in [config.xml](./config.xml)

## CLUSTER

The setting of cluster must be written in config file like [config.xml](./config.xml).
Here, we define a `c1` cluster consisting of two nodes.
Those hostnames are `s1` and `s2`.

## TABLES

- [all_logs](./meta/all_logs.sql) : `Distributed('c1', default, logs, rand())`
  - s1: [logs](./meta/logs.sql) : `ReplicatedMergeTree('/clickhouse/tables/{shard}/default.logs', '{replica}')`
  - s2: [logs](./meta/logs.sql) : `ReplicatedMergeTree('/clickhouse/tables/{shard}/default.logs', '{replica}')`

`Replicated` engine takes `zoo_path` and `replica_id` for its parameters.
Here, `{xxx}` is substituted by macro those variables are defined in `<macros>` setting.

- Macro configuration files are mounted by [docker](./docker-compose.yml) for each container.
- [s1.xml](./s1.xml)
- [s2.xml](./s2.xml)

## WRITE

`ReplicatedMergeTree` with `internal_replication=true` works as follows for writing.

1. write the data in his storage (same as `MergeTree`)
2. write the metadata as replication table in ZooKeeper
3. (another nodes in same shard) watch replication table
4. (when new data found) synchronize data by connecting to the node with port 9009

Therefore, data is automatically synchronized within the same shard,
regardless of whether it is written to the Distributed or Replicated table.

```console
$ cat data/*.csv | clickhouse-client --port 9001 -m -n -A -q 'INSERT INTO all_logs FORMAT CSV'
```

or

```console
$ cat data/*.csv | clickhouse-client --port 9001 -m -n -A -q 'INSERT INTO logs FORMAT CSV'
```

## READ

Read from cluster via Distributed table `all_logs`.

```console
$ clickhouse-client --port 9001 -A -q 'SELECT * FROM all_logs ORDER BY date'
2018-12-30      1
2018-12-31      2
2019-01-01      3
2019-01-02      4
```

Read from a shard directly.
The first shard is running at `s1:9000` which is linked to `localhost:9001` in docker.

```console
$ clickhouse-client --port 9001 -A -q 'SELECT * FROM logs ORDER BY date'
2018-12-30      1
2018-12-31      2
2019-01-01      3
2019-01-02      4
```

The second shard is running at `s2:9000` which is linked to `localhost:9002` in docker.

```console
$ clickhouse-client --port 9002 -A -q 'SELECT * FROM logs ORDER BY date'
2018-12-30      1
2018-12-31      2
2019-01-01      3
2019-01-02      4
```

## play on console

```console
$ make start

$ make test
OK: spec

$ make info
# DATA(s1:all_logs)
2018-12-30      1
2018-12-31      2
2019-01-01      3
2019-01-02      4
# DATA(s2:all_logs)
2018-12-30      1
2018-12-31      2
2019-01-01      3
2019-01-02      4
# DATA(s1:logs)
2018-12-30      1
2018-12-31      2
2019-01-01      3
2019-01-02      4
# DATA(s2:logs)
2018-12-30      1
2018-12-31      2
2019-01-01      3
2019-01-02      4

$ make stop
```
