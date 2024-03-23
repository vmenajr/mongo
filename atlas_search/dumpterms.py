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
