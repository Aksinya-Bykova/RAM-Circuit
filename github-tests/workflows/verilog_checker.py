import csv
import sys

ref_fname = sys.argv[1]
out_fname = sys.argv[2]

def read_csv(filename):
    with open(filename) as f:
        file_data=csv.reader(f, delimiter='\t')
        headers=next(file_data)
        return [dict(zip(headers,i)) for i in file_data]

ref_table = read_csv(ref_fname)
out_table = read_csv(out_fname)

cmd = {'NOP' : '00', 'PUSH' : '01', 'POP' : '10', 'GET': '11', 'RESET' : '1'}

verdict = True
for i in range(len(ref_table)):
    if ref_table[i]['CLK'] == '1':
        if ref_table[i]['COMMAND'] == cmd['NOP']:
           pass 
        elif ref_table[i]['COMMAND'] == cmd['PUSH']:
            verdict = ref_table[i]['I_DATA'] == out_table[i]['I_DATA']
        elif ref_table[i]['COMMAND'] == cmd['POP'] or ref_table[i]['COMMAND'] == cmd['GET']:
            verdict = ref_table[i]['O_DATA'] == out_table[i]['O_DATA']
    else:
        if ref_table[i]['CLK'] == '0' and ref_fname.find("normal"):
            verdict = ref_table[i]['O_DATA'] == out_table[i]['O_DATA']

    if not verdict:
        print(f"[FAILED] got != expected at time = {ref_table[i]['T']}")
        print(f"expected: {ref_table[i]}")
        print(f"got     : {out_table[i]}")
        exit(1)

print(f"[PASSED] got == expected")
exit(0)

#print(table[141]['COMMAND'], end='\n', sep='\n')

