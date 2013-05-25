fileString = "Strings.h"
file = open(fileString,'r')
print file

newFile = open('tempStrings.h', 'w')

lookupDictionary = {}

totalEN = 0;
totalLOC = 0;

for line in file:
	if '#define EN_' in line:
		lineSplitArray = line.split(' ',2)
		if len(lineSplitArray) > 2:
			totalEN+=1
			lookupDictionary[lineSplitArray[1].strip()]=lineSplitArray[2]
			
	if 'NSLocalizedString' in line:
		totalLOC+=1
		commaSplit = line.split(',',1)
		parSplit = commaSplit[0].split('(',1)
		key = parSplit[1].strip()
		newFile.write( '#define a'+str(totalLOC) +' NSLocalizedString('+ lookupDictionary[key].strip() + ' , '+commaSplit[1].strip()+'\n')
		del lookupDictionary[key]
		
	
file.close()

print lookupDictionary
print totalEN
print totalLOC