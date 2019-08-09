from __future__ import print_function
import sys
#args
#1. genomename eg. hg19
#2. gtffile or rrnalist or refflat etc.
genome2resource={}
for i in list(map(lambda x:x.strip().split("\t"),open(sys.argv[3]).readlines())):
  if not i[0] in genome2resource:
    genome2resource[i[0]]={}
  genome2resource[i[0]][i[1]]=i[2]
print(genome2resource[sys.argv[1]][sys.argv[2]])
