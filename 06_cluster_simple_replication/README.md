# cluster simple replication

Just setting `internal_replication` to `false` enables replication.
INSERT data is automatically replicated to all tables in the same shard without any other configuration or introduction of ZooKeeper.

Although this is the easiest replication way, data replication is not guaranteed at the time of WRITE failure, and data integrity is not guaranteed either.

- [2 nodes](./docker-compose.yml) ( `s1:9000`, `s2:9000`, )
- 1 table per 1 node

<!---
https://textik.com/#d853c3e47612defb
-->

```text
 all_logs : Distributed(c1, logs) # (internal_replication=false) <-- WRITE
                            |                  |
 <-------------------------------------------------------------------------->
                            |                  |
   s1:9000 <----------------+   s2:9000 <------+
   +----------------------+     +----------------------+
   | +------------------+ |     | +------------------+ |
   | | logs : MergeTree | |     | | logs : MergeTree | |
   | +------------------+ |     | +------------------+ |
   |     ["2018-12-30",1] |     |     ["2018-12-30",1] |
   |     ["2018-12-31",2] |     |     ["2018-12-31",2] |
   |     ["2019-01-01",3] |     |     ["2019-01-01",3] |
   |     ["2019-01-02",4] |     |     ["2019-01-02",4] |
   +----------------------+     +----------------------+
```

## CLUSTER

The setting of cluster must be written in config file like [config.xml](./config.xml).
Here, we define a `c1` cluster consisting of two nodes.
Those hostnames are `s1` and `s2`.

Here, the shard is defined as internal_replication=false`.

## TABLES

- [all_logs](./meta/all_logs.sql) : `Distributed('c1', default, logs, rand())`
  - s1: [logs](./meta/logs.sql) : `MergeTree`
  - s2: [logs](./meta/logs.sql) : `MergeTree`

## WRITE

`Distributed` engine acts as a proxy server.
So, we can write data to Distributed table, that is `all_logs`.
The data will be automatically written into backup servers too when `internal_replication=false`.

```console
$ cat data/*.csv | clickhouse-client --port 9001 -m -n -A -q 'INSERT INTO all_logs FORMAT CSV'
```

When you write data into one shard table `log` directly, it will not be replicated even if `internal_replication=false`.

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
This is a backup server and the data has already been synchronized automatically by the setting `internal_replication=false`.

```console
$ clickhouse-client --port 9002 -A -q 'SELECT * FROM logs ORDER BY date'
2018-12-30      1
2018-12-31      2
2019-01-01      3
2019-01-02      4
```

## fault tolerance

Data written at node shutdown is automatically synchronized at node recovery.

This is guaranteed for clean anomalies as follows, but in the real case where problems occur during writing or synchronization, this replication method loses data integrity among the nodes.

```console
$ make start
$ make meta

$ docker-compose stop s2

$ make data
$ make info-logs
# DATA(s1:logs)
2018-12-30      1
2018-12-31      2
2019-01-01      3
2019-01-02      4
# DATA(s2:logs)
Code: 210. DB::NetException: Connection refused (localhost:9002)

$ make info-dbms
# /var/lib/clickhouse/data (s1)
/var/lib/clickhouse/data/default/all_logs/default@s2:9000/1.bin
# /var/lib/clickhouse/data (s2)
ERROR: No container found for s2_1

$ docker-compose start s2

$ make info-logs
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

$ make info-logs
# /var/lib/clickhouse/data (s1)
# /var/lib/clickhouse/data (s2)

$ make stop
```
