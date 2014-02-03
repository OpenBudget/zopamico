import csv
import json

out = []

for l in csv.reader(file("../obudget-gae/data/budget/2013_2014/budgets20132014.csv")):
    if l[0] != "2013":
        continue
    if l[1] == "00":
        continue
    out.append({'l1':l[1]+":"+l[2],'l2':l[3].split('-')[-1]+":"+l[4],'l3':l[5].split('-')[-1]+":"+l[6],'l4':l[7].split('-')[-1]+":"+l[8],"value":int(l[11].replace(',',''))})
    
outfile = file('budget.json','w')
outfile.write('window.data=')
json.dump(out,outfile)
outfile.write(';')
        
