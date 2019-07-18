# standalone server with Merge engine and MergeTree

By using the **Merge** engine, we can divide it into multiple tables.

- [1 node](./docker-compose.yml) ( `s1:9000` )
- 2 tables

```text
 s1:9000
  +---------------------------------+
  |         logs : Merge            |
  | <-----------------------------> |
  |    +-----------------------+    |
  |    | logs_2018 : MergeTree |    |
  |    +-----------------------+    |
  |             ["2018-12-30",1]    |
  |             ["2018-12-31",2]    |
  |                                 |
  |    +-----------------------+    |
  |    | logs_2019 : MergeTree |    |
  |    +-----------------------+    |
  |             ["2019-01-01",3]    |
  |             ["2019-01-02",4]    |
  |                                 |
  +---------------------------------+
```

By accessing to the merge table, the whole can be treated as one table, and further, individual tables can be manipulated directly. This is useful for replacing data on a per-table basis.

## TABLES

- [logs](./meta/logs.sql) : `Merge(default, '^logs_')`
  - [logs_2018](./meta/logs_2018.sql) : `MergeTree(date, date, 8192)`
  - [logs_2019](./meta/logs_2019.sql) : `MergeTree(date, date, 8192)`

## WRITE

`Merge` engine doesn't accept write data.
So, we must send data to `MergeTree` manually.

```console
$ cat data/2018*.csv | clickhouse-client --port 9001 -m -n -A -q 'INSERT INTO logs_2018 FORMAT CSV'
$ cat data/2019*.csv | clickhouse-client --port 9001 -m -n -A -q 'INSERT INTO logs_2019 FORMAT CSV'
```

## READ

```console
$ clickhouse-client --port 9001 -A -q 'SELECT * FROM logs ORDER BY date'
2018-12-30      1
2018-12-31      2
2019-01-01      3
2019-01-02      4
```

```console
$ clickhouse-client --port 9001 -A -q 'SELECT * FROM logs_2018 ORDER BY date'
2018-12-30      1
2018-12-31      2
```

```console
$ clickhouse-client --port 9001 -A -q 'SELECT * FROM logs_2019 ORDER BY date'
2019-01-01      3
2019-01-02      4
```

## play on console

```console
$ make start

$ make test
OK: spec

$ make info
# DATA(s1:logs)
2018-12-30      1
2018-12-31      2
2019-01-01      3
2019-01-02      4
# DATA(s1:logs_2018)
2018-12-30      1
2018-12-31      2
# DATA(s1:logs_2019)
2019-01-01      3
2019-01-02      4

$ make stop
```
