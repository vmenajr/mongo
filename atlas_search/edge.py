import sys
import lucene
from java.io import StringReader
from org.apache.lucene.analysis.ngram import EdgeNGramTokenizer
from org.apache.lucene.analysis.tokenattributes import CharTermAttribute

if len(sys.argv) <= 1:
  print(f'\nUsage: {sys.argv[0]}, "String to analyze"', file=sys.stderr);
  sys.exit(-1)

# Sample text
text=sys.argv[1]

# Prepare lucene
lucene.initVM(vmargs=['-Djava.awt.headless=true'])

# Create an EdgeNGramTokenizer with desired parameters
tokenizer = EdgeNGramTokenizer(2, 5)

# Set input text for the tokenizer
tokenizer.setReader(StringReader(text))

# Tokenize the text and print the generated edge n-grams
tokenizer.reset()
char_term_attribute = tokenizer.addAttribute(CharTermAttribute.class_)
while tokenizer.incrementToken():
    print('"{}"'.format(char_term_attribute.toString()))

# Close the tokenizer
tokenizer.close()

