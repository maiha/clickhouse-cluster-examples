# cluster Replicated MergeTree with ZooKeeper

**Replicated** engine shares `INSERT` and `ALTER` queries asynchronously between nodes.

The node receiving the command stores the actual data in its own table, and records the metadata in ZooKeeper. In addition, each node monitors ZooKeeper for update metadata that has occurred within the same fragment. If an INSERT is found, update data is obtained directly from the update node.

- [ZooKeeper](./docker-compose.yml) ( `zk:2181` )
- [1 shard](./config.xml) [2 nodes](./docker-compose.yml) ( `s1:9000`, `s2:9000`, )
- 1 table per 1 node

<!---
https://textik.com/#70c1d375c4225465
-->

```text
 all_logs : Distributed(c1, logs) # <-- 1.WRITE
                             |
 <-------------------------------------------------------------------------->
                   2.WRITE   |
    s1:9000 <----------------+            s2:9000
    +--------------------------------+    +--------------------------------+
    | +----------------------------+ |    | +----------------------------+ |
    | | logs : ReplicatedMergeTree | |    | | logs : ReplicatedMergeTree | |
    | +----------------------------+ |    | +----------------------------+ |
    |  |            ["2018-12-30",1] |    |               ["2018-12-30",1] |
    |  |            ["2018-12-31",2] |    |               ["2018-12-31",2] |
    |  |            ["2019-01-01",3] |    |               ["2019-01-01",3] |
    |  |            ["2019-01-02",4] |    |               ["2019-01-02",4] |
    +--|-----------------------------+    +--------------------------------+
       |         [interserver] s1:9009 <-------------------------------|
       |    (config: interserver_http_host        4. REPLICA SYNC      |
       |             interserver_http_port)                            |
       |  zk:2181                                                      |
       |  +----------------------------------------------------+       |
       |  |      +-----------------------------------------+   |       |
       +-------> | /clickhouse/tables/1/default.logs/block | <---------+
  3.WRITE |      +-----------------------------------------+   |  (monitor)
          | [20181230_5383472499804002539_1700904329733462805] |
          | [20181231_1114583668837677782_7297308974928976135] |
          | [20190101_3142061115699531382_7149022940449705633] |
          | [20190102_1108493909296339633_1780074824470156015] |
          +----------------------------------------------------+
```

## ZooKeeper

- write node setting in `zookeeper` section ([config.xml](./config.xml))

## CLUSTER

- write shard setting `remote_servers` section ([config.xml](./config.xml))

Here we define the `c1` cluster with one shard.
The shard consists of two nodes running on `s1` and` s2`, and operates with redundancy 2 as dual masters of that shard.

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

- (target node)
  1. First, write actual data in its table (acts same as `MergeTree`)
  2. Then, write the metadata as replication table in ZooKeeper

- (nodes in same shard)
  1. monitor replication table in ZooKeeper
  2. synchronize data by connecting to the node directly when new data found
    - config: `interserver_http_host`, `interserver_http_port`

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
