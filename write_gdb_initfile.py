import sys


USAGESTR = 'USAGE: python3 ' + sys.argv[0] + ' <listings file> <gdb init file>'

labels = {'GetInput'          : None,
          'AllocateWorkspace' : None,
          'RunCode'           : None,
          'ProgramCounter'    : None,
          'DataPointer'       : None,
          'SectorEnd'         : None,
          'next_instruction'  : None}

INITFILE = """
target remote:1234

set $pcb = {ProgramCounter}
set $dpb = {DataPointer}
set $code = {SectorEnd}
set $GetInput = {GetInput}
set $AllocateWorkspace = {AllocateWorkspace}
set $RunCode = {RunCode}
set $ni = {next_instruction}

break *$GetInput
continue
"""


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(USAGESTR)
        raise ValueError('Unexpected number of arguments')
    with open(sys.argv[1], 'r') as f:
        codelines = f.readlines()
    
    for index, line in enumerate(codelines):
        for label in labels:
            if label+':' in line:
                labels[label] = int(codelines[index+1].split()[1], 16) + 0x7c00

    with open(sys.argv[2], 'w') as f:
        f.write(INITFILE.format(**labels))
