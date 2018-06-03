import sys


USAGESTR = 'USAGE: python3 ' + sys.argv[0] + ' <listings file> <gdb init file>'

labels = {'GetInput'                  : None,
          'AllocateWorkspace'         : None,
          'RunCode'                   : None,
          'ProgramCounter'            : None,
          'DataPointer'               : None,
          'SectorEnd'                 : None,
          'RunCode.next_instruction'  : None}

INITFILE = """
target remote:1234

set $pcb = %(ProgramCounter)s
set $dpb = %(DataPointer)s
set $code = %(SectorEnd)s
set $GetInput = %(GetInput)s
set $AllocateWorkspace = %(AllocateWorkspace)s
set $RunCode = %(RunCode)s
set $ni = %(RunCode.next_instruction)s

display/1hx $pcb
display/1hx $dpb

break *$GetInput
continue
"""


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(USAGESTR)
        raise ValueError('Unexpected number of arguments')
    with open(sys.argv[1], 'r') as f:
        codelines = f.readlines()
    
    for line in codelines:
        for label in labels:
            if len(line.split()) > 0 and line.split()[-1] == label:
                labels[label] = int(line.split()[0], 16)

    with open(sys.argv[2], 'w') as f:
        f.write(INITFILE % labels)
