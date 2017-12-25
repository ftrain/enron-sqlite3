-- This is to run after enron2sqlite.py.

-- We have a table called emails of the form message-id, key, value,
-- extra with about 18mm rows. We want to turn this into normal
-- emails, a table of addresses (so we can explore the social graph),
-- and a full-text search.

BEGIN TRANSACTION;

DROP TABLE IF EXISTS messages;

CREATE TABLE messages (
       id           INTEGER PRIMARY KEY AUTOINCREMENT,
       message_id   STRING,
       subject      TEXT,
       datetime     DATETIME,
       mime_version TEXT,
       email_from   TEXT,
       email_to     TEXT,
       email_cc     TEXT,
       email_bcc    TEXT,              
       content_type TEXT,
       content_transfer_encoding TEXT,
       folder       TEXT,
       origin       TEXT,
       filename     TEXT,
       body         TEXT
);

CREATE INDEX messages_message_id_idx ON messages(message_id);

-- This next thing is ugly but it's really just doing a bunch of
-- self-joins on the messages table.

INSERT INTO messages(
       message_id,
       subject,
       datetime,
       mime_version,
       content_type,
       content_transfer_encoding,
       folder,
       origin,
       filename,
       body,
       email_from,
       email_to,
       email_cc,
       email_bcc
)

SELECT t_message_id.message_id message_id,
       t_subject.value subject,
       t_datetime.value datetime,
       t_mime_version.value mime_version,
       t_content_type.value content_type,
       t_content_transfer_encoding.value content_transfer_encoding,
       t_folder.value folder,     
       t_origin.value origin,
       t_filename.value filename,
       t_body.value body,
       t_from.value email_from,
       t_to.value email_to,
       t_cc.value email_cc,
       t_bcc.value email_bcc         

FROM emails t_message_id
  JOIN emails t_subject ON t_message_id.message_id = t_subject.message_id
  JOIN emails t_body ON t_message_id.message_id = t_body.message_id
  JOIN emails t_folder ON t_message_id.message_id = t_folder.message_id
  JOIN emails t_datetime ON t_message_id.message_id = t_datetime.message_id
  JOIN emails t_mime_version ON t_message_id.message_id = t_mime_version.message_id
  JOIN emails t_content_type ON t_message_id.message_id = t_content_type.message_id
  JOIN emails t_content_transfer_encoding ON t_message_id.message_id = t_content_transfer_encoding.message_id
  JOIN emails t_origin ON t_message_id.message_id = t_origin.message_id
  JOIN emails t_filename ON t_message_id.message_id = t_filename.message_id
  JOIN emails t_from ON t_message_id.message_id = t_from.message_id
  JOIN emails t_to ON t_message_id.message_id = t_to.message_id
  JOIN emails t_cc ON t_message_id.message_id = t_cc.message_id
  JOIN emails t_bcc ON t_message_id.message_id = t_bcc.message_id
  
WHERE t_message_id.field='Message-ID'
  AND t_subject.field = 'Subject'
  AND t_body.field = 'Body'
  AND t_folder.field = 'X-Folder'
  AND t_datetime.field = 'Date'
  AND t_mime_version.field = 'Mime-Version'
  AND t_content_type.field = 'Content-Type'
  AND t_content_transfer_encoding.field = 'Content-Transfer-Encoding'
  AND t_origin.field = 'X-Origin'
  AND t_filename.field = 'X-FileName'
  AND t_from.field = 'From'
  AND t_to.field = 'To'
  AND t_cc.field = 'Cc'
  AND t_bcc.field = 'Bcc'
;



DROP TABLE IF EXISTS addresses;

CREATE TABLE addresses (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       name TEXT,
       email TEXT);

INSERT INTO addresses(email)
       SELECT DISTINCT lower(extra)
       FROM emails
       WHERE field='Parsed-From'
       	     OR field='Parsed-To'
	     OR field='Parsed-Cc'
	     OR field='Parsed-Bcc';

CREATE index address_idx ON addresses(email);


DROP TABLE IF EXISTS messages_addresses;

CREATE TABLE messages_addresses
       (role TEXT,
       	message_id INTEGER,
	address_id INTEGER,
        FOREIGN KEY(message_id) REFERENCES messages(id),
        FOREIGN KEY(address_id) REFERENCES addresses(id));

CREATE INDEX role_idx ON messages_addresses(role);

INSERT INTO messages_addresses
SELECT
       upper(replace(e.field, 'Parsed-', '')),
       m.id,
       a.id
 FROM emails e
 INNER JOIN addresses a ON e.extra = a.email
 INNER JOIN messages m ON e.message_id = m.message_id
 WHERE
	e.field='Parsed-To'
	OR e.field='Parsed-From'
	OR e.field='Parsed-Cc'
	OR e.field='Parsed-Bcc';


DROP TABLE IF EXISTS messages_ft;
CREATE VIRTUAL TABLE messages_ft USING fts4(subject, body);
INSERT INTO messages_ft(docid, subject, body) SELECT id, subject, body FROM messages;

DROP TABLE emails;

COMMIT;

VACUUM;
