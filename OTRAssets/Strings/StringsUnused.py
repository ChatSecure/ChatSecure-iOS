#!/usr/bin/env python3

import codecs
import json
import os
import sys


def find_unused(strings_dict: dict, source_dirs: [str]) -> [str]:
    unused_keys = []

    for key in strings_dict:
        found = False
        for directory in source_dirs:
            if found is True:
                break
            # Traverse directories
            for (dirpath, dirnames, filenames) in os.walk(directory, ):
                if found is True:
                    break
                # Traverse each file
                for filename in filenames:
                    if found is True:
                        break
                    name, ext = os.path.splitext(filename)
                    # Only check .h, .m. swift files exclueding OTRStrings file
                    if ext in ['.h', '.m', '.swift'] and name != 'OTRStrings':
                        filepath = os.path.join(dirpath, filename)
                        # Open file and read whole file into memory
                        if key in codecs.open(filepath, 'r', 'utf-8').read():
                            print(f"Found {key} in {filepath}")
                            found = True
                            # Once we find one occurrence no need to check anymore files
                            break
        if found is False:
            print(f"Could not find {key}")
            unused_keys.append(key)
    return unused_keys


def main(argv: [str]) -> int:

    if len(argv) == 0:
        print('StringsUnused.py: Finds unused strings by scanning source directories.')
        print('Usage: python3 ./OTRAssets/Strings/StringsUnused.py ./ChatSecure/Classes/ ./ChatSecureCore/ ./OTRAssets/')
        return 1

    script_directory = os.path.dirname(os.path.abspath(__file__))
    strings_json_path = os.path.join(script_directory, 'strings.json')
    source_dirs = argv
    for source_dir in source_dirs:
        if os.path.isdir(source_dir) is False:
            print(f"Invalid directory: {source_dir}")
            return 1
        else:
            print("Using source directory: {source_dir}")
    
    strings_json_file = open(strings_json_path, 'r+')
    strings_dict = json.load(strings_json_file)

    key_count = len(strings_dict.keys())
    print(f"Started with {key_count} strings.")
    unused_keys = find_unused(strings_dict, source_dirs)
    key_count = len(unused_keys)
    print(f"Found {key_count} unused strings.")
    for key in unused_keys:
        strings_dict.pop(key)
    key_count = len(strings_dict.keys())
    print(f"Finished with {key_count} strings.")
    pretty_unused = "\n".join(sorted(unused_keys))
    print(f"Unused strings:\n{pretty_unused}")

    # Overwrites strings.json with updated dictionary
    # strings_json_file.seek(0)
    # strings_json_file.truncate()
    # json.dump(strings_dict, strings_json_file, sort_keys = True, indent = 4)
    return 0


if __name__ == "__main__":
    main(sys.argv[1:])