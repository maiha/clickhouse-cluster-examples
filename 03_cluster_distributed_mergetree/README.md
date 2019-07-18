# cluster Distributed MergeTree

**Distributed** engine provides access to remote servers.

- [2 nodes](./docker-compose.yml) ( `s1:9000`, `s2:9000`, )
- 1 table per 1 node

```text
 all_logs : Distributed (cluster)
 <-------------------------------------------------------------->
   +----------------------------------------------------------+
   | s1:9000 (shard)              s2:9000 (shard)             |
   | +------------------------+   +-------------------------+ |
   | |  +------------------+  |   |  +------------------+   | |
   | |  | logs : MergeTree |  |   |  | logs : MergeTree |   | |
   | |  +------------------+  |   |  +------------------+   | |
   | |      ["2018-12-31",2]  |   |      ["2018-12-30",1]   | |
   | |                        |   |      ["2019-01-01",3]   | |
   | |                        |   |      ["2019-01-02",4]   | |
   | +------------------------+   +-------------------------+ |
   +----------------------------------------------------------+
```

## CLUSTER

The setting of cluster must be written in config file like [config.xml](./config.xml).
Here, we define a `c1` cluster consisting of two nodes.
Those hostnames are `s1` and `s2`.

## TABLES

- [all_logs](./meta/all_logs.sql) : `Distributed('c1', default, logs, rand())`
  - s1: [logs](./meta/logs.sql) : `MergeTree(date, date, 8192)`
  - s2: [logs](./meta/logs.sql) : `MergeTree(date, date, 8192)`

## WRITE

`Distributed` with `MergeTree` engine acts as a proxy server.
So, we can write data to Distributed table, that is `all_logs`.

```console
$ cat data/*.csv | clickhouse-client --port 9001 -m -n -A -q 'INSERT INTO all_logs FORMAT CSV'
```

`Distributed` engine send the data to the all shards defined in the cluster
according to **sharding key**. 
Here, data will be sent to random nodes because we define the key as `rand()`.

## READ

Read from cluster via Distributed table.

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
2018-12-31      2
```

The second shard is running at `s2:9000` which is linked to `localhost:9002` in docker.

```console
$ clickhouse-client --port 9002 -A -q 'SELECT * FROM logs ORDER BY date'
2018-12-30      1
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
# DATA(s1:logs)
2018-12-31      2
# DATA(s2:logs)
2018-12-30      1
2019-01-01      3
2019-01-02      4

$ make stop
```
