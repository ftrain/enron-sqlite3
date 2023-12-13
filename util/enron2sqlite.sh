python3 enron2sqlite.py | pv | sqlite3 ../enron.db
cat post_process.sql | sqlite3 ../enron.db
