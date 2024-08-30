import os
import re

def find_structs(file_path):
    with open(file_path, 'r') as file:
        content = file.read()

    struct_pattern = r'struct\s+(\w+)\s*{([^}]*)}'
    structs = re.findall(struct_pattern, content)
    
    return structs

def process_solidity_files(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.sol'):
                file_path = os.path.join(root, file)
                structs = find_structs(file_path)
                
                if structs:
                    print(f"\nFile: {file_path}")
                    for struct_name, struct_content in structs:
                        print(f"  Struct: {struct_name}")
                        for field in struct_content.split(';'):
                            field = field.strip()
                            if field:
                                print(f"    {field}")
                        print()

solidity_project_path = '../src'
process_solidity_files(solidity_project_path)