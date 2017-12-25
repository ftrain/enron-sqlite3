import email
from email.utils import getaddresses, parsedate_to_datetime
import os
from datetime import datetime

PREFIX = 'INSERT INTO emails (message_id, field, value) VALUES '
PREFIX_EXTRA = 'INSERT INTO emails (message_id, field, value, extra) VALUES '

def clean(s):
    return s.replace("'", "''")

def addresses(field, e_id, vals):
    addrs = getaddresses([vals])
    rev_field = 'Parsed-' + field
    for name, addr in addrs:
        print("{} ('{}','{}','{}','{}');".format(PREFIX_EXTRA, e_id, rev_field, clean(name), clean(addr)))

print("""
CREATE TABLE emails (message_id TEXT, field TEXT, value TEXT, extra TEXT);
CREATE INDEX message_id_idx ON emails(message_id);
CREATE INDEX field_idx ON emails(field);
PRAGMA main.page_size = 4096;
PRAGMA main.cache_size = 10000;
PRAGMA main.locking_mode = EXCLUSIVE;
PRAGMA main.synchronous = NORMAL;
PRAGMA main.journal_mode = WAL;
-- .echo on
-- .bail on
BEGIN TRANSACTION;
""");

for root, dirs, files in os.walk('../maildir', topdown=False):
    for name in files:
        try:
            fname = os.path.join(root, name)
            e = email.message_from_file(open(fname))
            e_id = e.get('Message-ID')
            for k, v in e.items():
                if k=='To' or k=='X-To' or k=='Cc' or k=='X-cc' or k=='Bcc' or k=='From' or k=='X-From':
                    addresses(k, e_id, v)
                    print("{} ('{}','{}','{}');".format(PREFIX, e_id, k, clean(v)))
                elif k=='Date':
                    dt = parsedate_to_datetime(v)
                    iso = dt.isoformat()
                    print("{} ('{}','{}','{}');".format(PREFIX, e_id, k, clean(iso)))
                else:
                    print("{} ('{}','{}','{}');".format(PREFIX, e_id, k, clean(v)))
                    
            print("{} ('{}','{}','{}');".format(PREFIX, e_id,'Body',clean(e.get_payload())))
            
        except Exception as e:
            pass
        # print(e)

print("""
COMMIT;""")

