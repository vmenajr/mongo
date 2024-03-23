# Atlas Search
Recently, I found myself trying to understand how certain tokenization stratergies are implemented. I decided to go to the source: The index files.

Now, for obvious reasons, the Atlas Search Index files are not available to me.  But never fear: [Atlas Local Development is here!](https://www.mongodb.com/blog/post/introducing-local-development-experience-atlas-search-vector-search-atlas-cli)

That blog post explains everything you need to get started so I won't go over it again. Instead, let's get to the good stuff.

## Setup
First, we need to spin up our local test
```console
atlas deployments setup --type local
```
With that out of the way we can inspect what is running. Now because I'm after the index files I'll use a format that focuses on what's interesting.
```console
podman ps --format "{{.Names}} {{.Mounts}}"
mongod-local5415 [/data/configdb /data/db]
mongot-local5415 [/var/lib/mongot/metrics /var/lib/mongot]
```
OK, looks like our man is `mongot-local4515` and we're most likely interested in `/var/lib/mongot`.  Now let's figure out where this mount lives
```console
podman inspect mongot-local5415 | jq '.[].Mounts.[] | {Type:.Type,Name:.Name,Mount:.Destination}'
{
  "Type": "volume",
  "Name": "mongot-local-metrics-local5415",
  "Mount": "/var/lib/mongot/metrics"
}
{
  "Type": "volume",
  "Name": "mongot-local-data-local5415",
  "Mount": "/var/lib/mongot"
}
```



## DISCLAIMER
Official MongoDB Support is **not** provided for this, **use at your own RISK**.

