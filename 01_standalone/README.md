# standalone server

The simplest topology is to prepare one node with one table.

- 1 node (port: 9001)
- 1 table

```text
 +------------------+ 
 | logs : MergeTree |
 +------------------+
 s1:9001
```

Here, all data is stored in one table, and all operations can be performed directly on that table.

## TABLES

- [logs.sql](./meta/logs.sql)

```text
logs : MergeTree(date, date, 8192)
```

## WRITE

```console
$ cat data/*.csv | clickhouse-client --port 9001 -m -n -A -q 'INSERT INTO logs FORMAT CSV'
```

## READ

```console
$ clickhouse-client --port 9001 -A -q 'SELECT * FROM logs ORDER BY date'
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
# DATA(s1:logs)
2018-12-30      1
2018-12-31      2
2019-01-01      3
2019-01-02      4

$ make stop
```
