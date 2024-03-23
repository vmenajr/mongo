# Atlas Search Index File
Recently, I found myself trying to understand how an autocomple index works. For example: how do the analyzer and tokenizer interact. I decided to go to the source: The index files.

Now, for obvious reasons, the Atlas Search Index files are not available to me.  But never fear: [Atlas Local Development is here!](https://www.mongodb.com/blog/post/introducing-local-development-experience-atlas-search-vector-search-atlas-cli). The blog post explains everything you need to get started so I won't go over it again. Instead, let's get to the good stuff.

## Setup
First, we need to spin up our local test
```console
atlas deployments setup test --type local
```

Make sure it's up
```console
atlas deployments list && podman ps -a
```

We need to seed the database with some data. The local deployment defaults make it very easy.
```console
mongosh
```

And we're just going to add some text to collection `c` in the default database `test`
```console
db.c.insertMany([
  { "name": "The Matrix Revolutions" },
  { "name": "A man, a plan, a canal, panama!" },
  { "name": "One flew over the cuckoo's nest" },
  { "name": "No gracias, soy alergico a los crustaceos" }
])
```

Finally, we need to build an index.  The index will use the name "default" since we didn't specify it.
```console
db.c.createSearchIndex({
    "mappings": {
        "dynamic": false,
        "fields": {
            "name": {
                "type": "autocomplete",
                "analyzer": "lucene.standard",
                "tokenization": "edgeGram",
                "minGrams": 3,
                "maxGrams": 5,
                "foldDiacritics": false
            }
        }
    }
})
```

I guess we should make sure it's ready
```console
db.c.getSearchIndexes()
[
  {
    id: '65fef63ad01ab701c9b08a78',
    name: 'default',
    type: 'search',
    status: 'READY',
    queryable: true,
    latestVersion: 0,
    latestDefinition: {
      mappings: {
        dynamic: false,
        fields: {
          name: {
            type: 'autocomplete',
            minGrams: 3,
            maxGrams: 5,
            foldDiacritics: false,
            tokenization: 'edgeGram',
            analyzer: 'lucene.standard'
          }
        }
      }
    }
  }
]
```

## Where are the files?
With that out of the way let's inspect what is running locally. Now, because I'm after the index files I'll use a format that focuses on what's interesting.
```console
podman ps --format "{{.Names}} {{.Mounts}}"
mongod-test [/data/configdb /data/db]
mongot-test [/var/lib/mongot/metrics /var/lib/mongot]
```

OK, looks like our man is `mongot-test` and we're most likely interested in `/var/lib/mongot`.  Now let's figure out where this mount lives
```console
podman inspect mongot-test | jq '.[].Mounts.[] | {Type:.Type,Name:.Name,Mount:.Destination}'
{
  "Type": "volume",
  "Name": "mongot-local-metrics-test",
  "Mount": "/var/lib/mongot/metrics"
}
{
  "Type": "volume",
  "Name": "mongot-local-data-test",
  "Mount": "/var/lib/mongot"
}
```

It's a volume. This is great because we can use a different container to mount that volume read-only without having to disrupt the existing deployment.  I'll be using a pylucene container (more on that later). I'm going to run it alongside the atlas search local deployment and "borrow" it's data volume :smirk:
```console
podman run --name pylucene --rm --interactive --tty --volume $(pwd):/usr/src --volumes-from=mongot-test:ro docker.io/coady/pylucene bash
```

The container is a bit thin so let's add a few handy tools
```console
root@c93381d609f8:/usr/src# apt -y install vim tree ripgrep
```

and now let's see if the data files are present
```console
tree /var/lib/mongot/
/var/lib/mongot/
├── 65fef63ad01ab701c9b08a78_f5_u0_a0
│   ├── _0.cfe
│   ├── _0.cfs
│   ├── _0.si
│   ├── segments_f
│   └── write.lock
├── configJournal.json
├── keyfile
├── metrics
└── trash

4 directories, 7 files
```

That looks promising.

## Brute force
Now for the hammer.  We know we added certain sentences and we specified edgeGram(3,5) so let's see if we can find `matri` based on "The Matrix Revolutions"
```console
root@487c42c5ebf3:/var/lib/mongot# rg --binary matri
65fef63ad01ab701c9b08a78_f5_u0_a0/_0.cfs: binary file matches (found "\0" byte around offset 25)
```

Looks like it's in there. Let's pull all the strings from that file and zoom in on that hit.
```console
root@487c42c5ebf3:/var/lib/mongot# strings -n 3 65fef63ad01ab701c9b08a78_f5_u0_a0/_0.cfs | grep matri
fleflewflew gragracgraciloslos los cmanman man amatmatrmatrinesnestnono no gno groneone one foveoverover panpanapanamplaplanplan revrevorevolsoysoy soy athethe the cthe mV
```

Well that looks like...something :)
Notice I used the `-n 3` parameter to strings.  By default it will look for sequences >=4 and since we used min 3 on edgeGram(3,5) I scoped it lower.  From that mish mash of text it does look like we have tokens for 'Matrix'
```console
matmatrmatri -> mat,matr,matri
```

But where's the rest of the phrase? Probably somewhere else on the file since tokens are deduplicated.

At this point I got tired of manually peeking into the binary and decided to try some scripting.

## Pylucene
Big shout out to @coady who builds and maintains a docker image that makes this a snap: `docker pull coady/pylucene`.
Thanks to the existing docker container I managed to quickly get up and running with this python library and here's what I came up with
```python
import sys
import lucene
from org.apache.lucene import index, store, util
from java.nio.file import Paths

# Prepare lucene
lucene.initVM(vmargs=['-Djava.awt.headless=true'])

# Argument parsing
if len(sys.argv) <= 2:
  print(f'\nUsage: {sys.argv[0]}, "Index path" "fieldName"', file=sys.stderr);
  sys.exit(-1)

indexPath=sys.argv[1]
fieldName=sys.argv[2] #'$type:autocomplete/name'

print ('Path: ', indexPath)
print ('Field: ', fieldName)

# Boilerplate
ireader = index.DirectoryReader.open(store.NIOFSDirectory(Paths.get(indexPath)))
terms = index.MultiTerms.getTerms(ireader,fieldName)
ti = terms.iterator()
pi=None
doc2terms=dict(list())

# Build a map of docId -> terms
for term in util.BytesRefIterator.cast_(ti):
  pi=ti.postings(pi,0)
  while (pi.nextDoc() != pi.NO_MORE_DOCS):
    docId=pi.docID()
    value=term.utf8ToString()
    l=doc2terms.get(docId,list())
    l.append(value)
    doc2terms[docId]=l


# Dump out terms per document
print()
for k in doc2terms.keys():
  doc=ireader.document(k)
  print('Given: \'{}\''.format(doc.get(fieldName)))
  print(doc2terms[k])
  print()

```
Let's take it for spin
```console
python dumpterms.py /var/lib/mongot/65fef63ad01ab701c9b08a78_f5_u0_a0 '$type:autocomplete/name'
Path:  /var/lib/mongot/65fef63ad01ab701c9b08a78_f5_u0_a0
Field:  $type:autocomplete/name

Given: 'A man, a plan, a canal, panama!'
['a', 'a c', 'a ca', 'a can', 'a m', 'a ma', 'a man', 'a p', 'a pl', 'a pla', 'can', 'cana', 'canal', 'man', 'man ', 'man a', 'pan', 'pana', 'panam', 'pla', 'plan', 'plan ']

Given: 'No gracias, soy alergico a los crustaceos'
['a', 'a l', 'a lo', 'a los', 'ale', 'aler', 'alerg', 'cru', 'crus', 'crust', 'gra', 'grac', 'graci', 'los', 'los ', 'los c', 'no', 'no ', 'no g', 'no gr', 'soy', 'soy ', 'soy a']

Given: 'One flew over the cuckoo's nest'
['cuc', 'cuck', 'cucko', 'fle', 'flew', 'flew ', 'nes', 'nest', 'one', 'one ', 'one f', 'ove', 'over', 'over ', 'the', 'the ', 'the c']

Given: 'The Matrix Revolutions'
['mat', 'matr', 'matri', 'rev', 'revo', 'revol', 'the', 'the ', 'the m']
```
Not bad and a whole lot easier than digging around the binary data.

## Dig deeper
TBD
