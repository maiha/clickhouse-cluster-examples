# cluster Merge Distributed MergeTree

**Merge** engine can connect to `Distributed` engine too.

- [2 nodes](./docker-compose.yml) ( `s1:9000`, `s2:9000`, )
- 2 tables per 1 node ( `logs_2018`, `logs_2019` )

<!---
https://textik.com/#88b014ea2efa5d4c
-->

```text
 all_logs : Merge                                                                  
 <-------------------------------------------------------------------------------->
   |  |           s1:9000                        s2:9000                           
   |  |           +---------------------------+  +---------------------------+     
   |  |           |                           |  |                           |     
   |  +-> all_logs_2018 : Distributed         |  |                           |     
   |      +----------------------------------------------------------------------+ 
   |      |       | +-----------------------+ |  | +-----------------------+ |   | 
   |      |       | | logs_2018 : MergeTree | |  | | logs_2018 : MergeTree | |   | 
   |      |       | +-----------------------+ |  | +-----------------------+ |   | 
   |      |       |          ["2018-12-30",1] |  |          ["2018-12-31",2] |   | 
   |      +----------------------------------------------------------------------+ 
   |              |                           |  |                           |     
   +----> all_logs_2019 : Distributed         |  |                           |     
          +----------------------------------------------------------------------+ 
          |       | +-----------------------+ |  | +-----------------------+ |   | 
          |       | | logs_2019 : MergeTree | |  | | logs_2019 : MergeTree | |   | 
          |       | +-----------------------+ |  | +-----------------------+ |   | 
          |       |          ["2019-01-01",3] |  |          ["2019-01-02",4] |   | 
          +----------------------------------------------------------------------+ 
                  |                           |  |                           |     
                  +---------------------------+  +---------------------------+     
```

## CLUSTER

The setting of cluster must be written in config file like [config.xml](./config.xml).
Here, we define a `c1` cluster consisting of two nodes.
Those hostnames are `s1` and `s2`.

## TABLES

- [all_logs](./meta/all_logs.sql) : `Merge(default, '^all_logs_')`
  - s1: [all_logs_2018](./meta/all_logs_2018.sql) : `Distributed(c1, default, logs_2018)`
    - s1: [logs_2018](./meta/logs_2018.sql) : `MergeTree(date, date, 8192)`
    - s2: [logs_2018](./meta/logs_2018.sql) : `MergeTree(date, date, 8192)`
  - s2: [all_logs_2019](./meta/all_logs_2018.sql) : `Distributed(c1, default, logs_2019)`
    - s1: [logs_2019](./meta/logs_2019.sql) : `MergeTree(date, date, 8192)`
    - s2: [logs_2019](./meta/logs_2019.sql) : `MergeTree(date, date, 8192)`

## WRITE

This `Distributed` table contains `Merge` engine which doesn't accept write data.
So, we must send data to `MergeTree` on each shards manually.

```console
$ cat data/2018-1.csv | clickhouse-client --port 9001 -m -n -A -q 'INSERT INTO logs_2018 FORMAT CSV'
$ cat data/2018-2.csv | clickhouse-client --port 9002 -m -n -A -q 'INSERT INTO logs_2018 FORMAT CSV'
$ cat data/2019-1.csv | clickhouse-client --port 9001 -m -n -A -q 'INSERT INTO logs_2019 FORMAT CSV'
$ cat data/2019-2.csv | clickhouse-client --port 9002 -m -n -A -q 'INSERT INTO logs_2019 FORMAT CSV'
```

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
2018-12-30      1
2019-01-01      3

$ clickhouse-client --port 9001 -A -q 'SELECT * FROM logs_2018 ORDER BY date'
2018-12-30      1

$ clickhouse-client --port 9001 -A -q 'SELECT * FROM logs_2019 ORDER BY date'
2019-01-01      3
```

The second shard is running at `s2:9000` which is linked to `localhost:9002` in docker.

```console
$ clickhouse-client --port 9002 -A -q 'SELECT * FROM logs ORDER BY date'
2018-12-31      2
2019-01-02      4

$ clickhouse-client --port 9002 -A -q 'SELECT * FROM logs_2018 ORDER BY date'
2018-12-31      2

$ clickhouse-client --port 9002 -A -q 'SELECT * FROM logs_2019 ORDER BY date'
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
# DATA(s1:all_logs_2018)
2018-12-30      1
2018-12-31      2
# DATA(s1:logs_2018)
2018-12-30      1
# DATA(s2:logs_2018)
2018-12-31      2
# DATA(s1:all_logs_2019)
2019-01-01      3
2019-01-02      4
# DATA(s1:logs_2019)
2019-01-01      3
# DATA(s2:logs_2019)
2019-01-02      4

$ make stop
```
