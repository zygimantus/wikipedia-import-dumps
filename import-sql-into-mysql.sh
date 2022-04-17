# Fix a schema issue that may otherwise cause import bugs
docker-compose exec database \
    mysql --user=wikipedia --password=wikipedia --database=wikipedia \
        "ALTER TABLE page ADD page_counter bigint unsigned NOT NULL default 0;"

# Import the compressed chunks into the database
for partial in $(ls *.sql.zst); do
    zstd -dc preimport.sql.zst $partial postimport.sql.zst \
    | docker-compose exec database \
        mysql --force --user=wikipedia --password=wikipedia --database=wikipedia
done