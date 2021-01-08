
```SQL
CREATE EXTERNAL TABLE passenger (
    pclass INT,
    survived BOOLEAN,
    name STRING,
    sex STRING,
    age STRING,
    sibsp INT,
    parch INT,
    ticket STRING,
    fare DOUBLE,
    cabin STRING,
    embarked STRING,
    boat STRING,
    body STRING,
    home STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES ('separatorChar' = '\;', 'escapeChar' = '\\')
LOCATION 's3://jpinsolle-source-titanic-dev/raw-data/passenger/'
TBLPROPERTIES (
    'has_encrypted_data' = 'true',
    'classification'= 'csv',
    'skip.header.line.count' = '1'
);
```