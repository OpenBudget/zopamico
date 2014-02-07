import csv
import json

out = []

def toInt(s):
    if not s.startswith("-"):
        s="0"+s
    s=s.replace(",","")
    return int(s)

#for l in csv.reader(file("../obudget-gae/data/budget/2013_2014/budgets20132014.csv")):
for l in csv.reader(file("../obudget-gae/data/budget/new_2012/execution2012.csv")):
    if l[0] != "2012":
        continue
    if l[1] == "00":
        continue
    l[18] = toInt(l[18])
    l[11] = toInt(l[11])
    if l[18] == 0:
        continue
    out.append( {'l1':l[1]+":"+l[2],
                 'l2':l[3].split('-')[-1]+":"+l[4],
                 'l3':l[5].split('-')[-1]+":"+l[6],
                 'l4':l[7].split('-')[-1]+":"+l[8],
                 "value":l[18],
                 "color":1.0*l[18]/l[11] - 1.0 if l[11] != 0 else 0,
             } )
    
outfile = file('budget2012.json','w')
outfile.write('window.data=')
json.dump(out,outfile)
outfile.write(';')
        
