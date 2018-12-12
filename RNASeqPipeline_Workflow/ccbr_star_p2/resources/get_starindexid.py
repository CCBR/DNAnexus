import sys,os,glob
#args
#1. txt folder
#2. genomename eg. hg19
basefolder=sys.argv[1] # QC or rawQC folder
txts=glob.glob(basefolder+"/*.txt")
read_lengths=[]
for f in txts:
  line=list(filter(lambda x:x.startswith(b'Sequence length'),list(map(lambda x:x.strip(),open(f).readlines()))))[0]
  if b'-' in line:
    read_lengths.append(int(line.split(b'\t')[1].split(b'-')[1]))
  else:
    read_lengths.append(int(line.split(b'\t')[1]))
a=max(read_lengths)-1
allrls=[50,75,100,125,150]
if not a in allrls:
  for rl in allrls:
    if a > rl:
      continue 
    else:
      a=rl
      break
a=str(a)
genome2resource=dict()
for i in list(map(lambda x:x.strip().split("\t"),open("/genome2resources.tsv").readlines())):
  if not i[0] in genome2resource:
    genome2resource[i[0]]=dict()
  genome2resource[i[0]][i[1]]=i[2]
print(genome2resource[sys.argv[2]][a])
