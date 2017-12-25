
# Enron Email Dataset in SQLite3

## Huh?
 
I always wanted to poke around this dataset. But mostly this was a learning exercise; I wanted to get good at converting a large arbitary email-like thing into SQLite3. Of course after I was done I did my homework and found that what I needed was already out there and eight hours of work could have been 15 minutes of work. I'll explain both below.

Enron was an energy trading company that did a lot of bad things and got in trouble with the Federal Energy Regulatory Commission. [And then](https://www.technologyreview.com/s/515801/the-immortal-life-of-the-enron-e-mails/)...

> In the name of serving the public’s interest during its investigation of Enron, the federal agency made the controversial decision to post online more than 1.6 million e-mails that Enron executives sent and received from 2000 through 2002. FERC eventually culled the trove to remove the most sensitive and personal data, after receiving complaints (see PDF). Even so, the “Enron e-mail corpus,” as the cleaned-up version is now known, remains the largest public domain database of real e-mails in the world—by far.

To learn more, there's a really good resource at https://enrondata.readthedocs.io/; that gives you everything you need to know about the different forms of the data, how it was used, etc.

## The right way
Two ways to get there!

SQL is here: http://www.ahschulz.de/enron-email-data/
Which I loaded into MySQL, dumped, and imported using mysql2sqlite


CREATE VIRTUAL TABLE messages_ft USING fts4(subject, body);
INSERT INTO messages_ft(docid, subject, body) SELECT mid, subject, body FROM message;


## My way

## Requirements
- 20 spare gigs or thereabouts (the DB is around 5Gb all in when done)
- Download `enron_mail_20150507.tar.gz` from https://www.cs.cmu.edu/~enron/ (https://www.cs.cmu.edu/~enron/enron_mail_20150507.tar.gz)
- Python 3+
- sqlite3
- pv (`brew install pv` or `apt-get install pv`) (not a hard requirement, you can edit it out of the `sh` file, but it's nice to know what's happening with the 3.6 gigs of data you're dumping into SQLite).

## Converting
- $ `tar xfvz enron_mail_20150507.tar.gz`
- This will produce a `maildir` folder
- be running python 3+ (no custom libs needed)
- cd `util/`
- $ `sh enron2sqlite.sh`
- This might take a long time, half hour or an hour. It's doing lots of stuff. It goes through all the mail, expands the addresses, converts the dates, tidies some text, makes a giant SQLite table filled with everything, then it runs some SQL scripts that turn that into a `messages` table, an `addresses` table, and adds full-text search and extrapolates a table of who-sent-to-whom.
- $ `cd ..`

## Using it
- $ `sqlite3 enron.db`
- Or `pip3 install datasette` [Datasette](https://github.com/simonw/datasette) and run `datasette serve enron.db`

I've been doing the above and it's pretty cool.

## Schema

```

```