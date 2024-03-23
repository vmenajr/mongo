# Atlas Search Index File
Recently, I found myself trying to understand how an autocomple index works. For example: how do the analyzer and tokenizer interact. I decided to go to the source: The index files.

Now, for obvious reasons, the Atlas Search Index files are not available to me.  But never fear: [Atlas Local Development is here!](https://www.mongodb.com/blog/post/introducing-local-development-experience-atlas-search-vector-search-atlas-cli)

That blog post explains everything you need to get started so I won't go over it again. Instead, let's get to the good stuff.

## Setup
- First, we need to spin up our local test
```console
atlas deployments setup --type local
```
- Make sure it's up
```console
atlas deployments list && podman ps -a
```
- We need to setup the database with some data. Simply running mongosh should connect us.
```console
mongosh
```
- And we're just going to add some text to collection `c` in the default database `test`
```console
db.c.insertMany([
  { "name": "The Matrix Revolutions" },
  { "name": "A man, a plan, a canal, panama!" },
  { "name": "One flew over the cuckoo's nest" },
  { "name": "No gracias, soy alergico a los crustaceos" }
])
```
- Finally, we need to build an index.  The index will use the name "default" since we didn't specify it.
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
- I guess we should make sure it's ready
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
It's a volume. This is great because we can use a different container to mount that volume read-only without having to disrupt the existing deployment.  I'll be using a pylucene container (more on that later).  Big shout out to [coady](https://github.com/coady/lupyne) who builds and maintains those on docker hub.
```console
podman run --name pylucene --rm --interactive --tty --volume $(pwd):/usr/src --volumes-from=mongot-test:ro docker.io/coady/pylucene bash
```
The container is a bit thin so let's at least a few handy tools on there
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
Looks promising.

## Brute force
Now for the hammer.  We know we added certain sentences and we specified edgeGram(3,5) so let's see if we can find `matri` based on "The Matrix"
```
root@c93381d609f8:/var/lib/mongot# xxd -a 65fef63ad01ab701c9b08a78_f5_u0_a0/_0.cfs | grep -C 1 matri
00000b10: 2063 6d61 6e6d 616e 206d 616e 2061 6d61   cmanman man ama
00000b20: 746d 6174 726d 6174 7269 6e65 736e 6573  tmatrmatrinesnes
00000b30: 746e 6f6e 6f20 6e6f 2067 6e6f 2067 726f  tnono no gno gro
```
It's in there alright.  Let's reconstrut the tokens based on our understanding of edgeGram(3,5).
```
mat
matr
matri
```
