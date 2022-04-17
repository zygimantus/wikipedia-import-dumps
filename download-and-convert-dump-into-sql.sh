read -p "Enter wiki name [en]: " WIKI_NAME
WIKI_NAME=${WIKI_NAME:-en}
read -p "Enter your name [20220401]: " WIKI_DATE
WIKI_DATE=${WIKI_DATE:-20220401}
DUMP_NAME="$WIKI_NAME-$WIKI_DATE-pages-articles-multistream"

mkdir $DUMP_NAME
cp import-sql-into-mysql.sh $DUMP_NAME
cd $DUMP_NAME

wget "https://dumps.wikimedia.org/$WIKI_NAME/$WIKI_DATE/$DUMP_NAME.xml.bz2"

# Download patched mwdumper version and pre/post import SQL scripts
wget "https://github.com/pirate/wikipedia-mirror/raw/master/bin/mwdumper-1.26.jar"
wget "https://github.com/pirate/wikipedia-mirror/raw/master/preimport.sql"
wget "https://github.com/pirate/wikipedia-mirror/raw/master/postimport.sql"

# Decompress the XML dump using all available cores and 10GB of memory
pbzip2 -v -d -k -m10000 "$DUMP_NAME.xml.bz2"

# Convert the XML file into a SQL file using mwdumper
java -server \
    -jar ./mwdumper-1.26.jar \
    --format=sql:1.5 \
    "$DUMP_NAME.xml" \
> wikipedia.sql

# Split the generated SQL file into compressed chunks
split --additional-suffix=".sql" --lines=1000 wikipedia.sql
for partial in $(ls *.sql); do
    zstd -z $partial
done
