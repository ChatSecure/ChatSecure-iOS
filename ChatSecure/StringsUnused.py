import json
import os
import codecs

def findUnused(strings_dict,directory):
	unused_keys = []
	for key in strings_dict:
		found = False
		#T raverse directories
		for (dirpath, dirnames, filenames) in os.walk(directory, ):
			# Traverse each file
			for filename in filenames:
				name , ext = os.path.splitext(filename)
				# Only check .h an .m files exclueding Strings.h
				if ((ext == '.h' or ext == '.m' ) and filename != 'Strings.h'):
					filepath = os.path.join(dirpath,filename)
					# Open file and read whole file into memory
					if key in codecs.open(filepath,'r','utf-8').read():
						found = True
						# Once we find one occurrence no need to check anymore files
						break
						break
				
		if (found == False):
			unused_keys.append(key)
	return unused_keys
	
		



def main():

	script_directory = os.path.dirname(os.path.abspath(__file__))
	strings_json_path = os.path.join(script_directory, 'strings.json')

	strings_json_file = open(strings_json_path,'r')
	strings_dict = json.load(strings_json_file)

	unused_keys = findUnused(strings_dict,script_directory)
	print len(unused_keys)
	for key in unused_keys:
		print key + ' - ' + strings_dict[key]['string']



if __name__ == "__main__":
	main()