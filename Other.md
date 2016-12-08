BEGIN TRANSACTION;
CREATE TEMPORARY TABLE t1_backup(a,b);
INSERT INTO t1_backup SELECT a,b FROM t1;
DROP TABLE t1;
CREATE TABLE t1(a,b);
INSERT INTO t1 SELECT a,b FROM t1_backup;
DROP TABLE t1_backup;
COMMIT;



PRAGMA schema.journal_mode = DELETE | TRUNCATE | PERSIST | MEMORY | WAL | OFF
  FMResultSet *rs = [_db_read executeQuery:@"PRAGMA user_version"];

 CSLog(@"%@",[_db_read stringForQuery:@"PRAGMA journal_mode = WAL"]);
