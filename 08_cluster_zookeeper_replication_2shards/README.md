# cluster Replicated MergeTree with ZooKeeper (multiple shards)

This usecase is almost same as "cluster Replicated MergeTree with ZooKeeper"
except cluster consists of 2 shards with 4 nodes.

- [ZooKeeper](./docker-compose.yml) ( `zk:2181` )
- [2 shard](./config.xml) [4 nodes](./docker-compose.yml) ( `s1:9000`, `s2:9000`, `s3:9000`, `s4:9000`, )
- 1 table per 1 node

<!---
https://textik.com/#899737399cc2025d
-->

```text
 all_logs : Distributed(c1, logs) # <-- 1.WRITE
 <---------------------------------------------------------------------------------->
   |      shard: 1
   |      +-------------------------------------------------------------------------+
   |      |   s1:9000                            s2:9000                            |
   |      |   +--------------------------------+ +--------------------------------+ |
   |      |   | +----------------------------+ | | +----------------------------+ | |
   |--------->| | logs : ReplicatedMergeTree | | | | logs : ReplicatedMergeTree | | |
  2.WRITE |   | +----------------------------+ | | +----------------------------+ | |
    (rand)|   |               ["2018-12-31",2] | |               ["2018-12-31",2] | |
   |      |   |               ["2019-01-02",4] | |               ["2019-01-02",4] | |
   |      |   +--------------------------------+ +--------------------------------+ |
   |      |                              s1:9009  <----(replica sync)---->  s2:9009 |
   |      +-------------------------------------------------------------------------+
   |      shard: 2
   |      +-------------------------------------------------------------------------+
   |      |   s3:9000                            s4:9000                            |
   |      |   +--------------------------------+ +--------------------------------+ |
   |      |   | +----------------------------+ | | +----------------------------+ | |
   +--------->| | logs : ReplicatedMergeTree | | | | logs : ReplicatedMergeTree | | |
  2.WRITE |   | +----------------------------+ | | +----------------------------+ | |
    (rand)|   |               ["2018-12-30",1] | |               ["2018-12-30",1] | |
          |   |               ["2019-01-01",3] | |               ["2019-01-01",3] | |
          |   +--------------------------------+ +--------------------------------+ |
          |                              s3:9009  <----(replica sync)---->  s4:9009 |
          +-------------------------------------------------------------------------+
                  zk:2181
                  +-------------------------------------------------------+
                  | +-----------------------------------------+           |
                  | | /clickhouse/tables/1/default.logs/block |           |
                  | +-----------------------------------------+           |
                  |    [20181231_1114583668837677782_7297308974928976135] |
                  |    [20190102_1108493909296339633_1780074824470156015] |
                  | +-----------------------------------------+           |
                  | | /clickhouse/tables/2/default.logs/block |           |
                  | +-----------------------------------------+           |
                  |    [20181230_5383472499804002539_1700904329733462805] |
                  |    [20190101_3142061115699531382_7149022940449705633] |
                  +-------------------------------------------------------+
```

## ZooKeeper

- write node setting in `zookeeper` section ([config.xml](./config.xml))

## CLUSTER

- write shard setting `remote_servers` section ([config.xml](./config.xml))

Here we define the `c1` cluster with 2 shards.
- 1st shard: `s1` and `s2`
- 2nd shard: `s3` and `s4`

## TABLES

- [all_logs](./meta/all_logs.sql) : `Distributed('c1', default, logs, rand())`
  - s1: [logs](./meta/logs.sql) : `ReplicatedMergeTree('/clickhouse/tables/{shard}/default.logs', '{replica}')`
  - s2: [logs](./meta/logs.sql) : `ReplicatedMergeTree('/clickhouse/tables/{shard}/default.logs', '{replica}')`
  - s3: [logs](./meta/logs.sql) : `ReplicatedMergeTree('/clickhouse/tables/{shard}/default.logs', '{replica}')`
  - s4: [logs](./meta/logs.sql) : `ReplicatedMergeTree('/clickhouse/tables/{shard}/default.logs', '{replica}')`

`Replicated` engine takes `zoo_path` and `replica_id` for its parameters.
Here, `{xxx}` is substituted by macro those variables are defined in `<macros>` setting.

- Macro configuration files are mounted by [docker](./docker-compose.yml) for each container.
  - [s1.xml](./s1.xml)
  - [s2.xml](./s2.xml)
  - [s3.xml](./s3.xml)
  - [s4.xml](./s4.xml)

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
$ cat data/2018*.csv | clickhouse-client --port 9001 -m -n -A -q 'INSERT INTO logs FORMAT CSV'
$ cat data/2019*.csv | clickhouse-client --port 9003 -m -n -A -q 'INSERT INTO logs FORMAT CSV'
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
2018-12-30	1
2018-12-31	2
2019-01-01	3
2019-01-02	4
# DATA(s2:all_logs)
2018-12-30	1
2018-12-31	2
2019-01-01	3
2019-01-02	4
# DATA(s3:all_logs)
2018-12-30	1
2018-12-31	2
2019-01-01	3
2019-01-02	4
# DATA(s4:all_logs)
2018-12-30	1
2018-12-31	2
2019-01-01	3
2019-01-02	4
# DATA(s1:logs)
2018-12-31	2
2019-01-02	4
# DATA(s2:logs)
2018-12-31	2
2019-01-02	4
# DATA(s3:logs)
2018-12-30	1
2019-01-01	3
# DATA(s4:logs)
2018-12-30	1
2019-01-01	3

$ make stop
```
