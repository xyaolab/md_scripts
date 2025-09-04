#!/bin/bash

num_cores_c=$(awk '/^num_cores=/{sub(/num_cores=/, ""); print}' script_c.in)
num_cores_r=$(awk '/^num_cores=/{sub(/num_cores=/, ""); print}' script_r.in)
num_cores_l=$(awk '/^num_cores=/{sub(/num_cores=/, ""); print}' script_l.in)

rm -f *dat
rm -f *mmpbsa

if [ "$#" -ne 1 ]; then
    echo "Enter output file name"
    exit
fi

#i=0
#j=0
#k=0

for i in $(seq $num_cores_c);do
   cat complex/complex$i/*.dat >>energies_complex.dat
#   ((i+=1))
done
for j in $(seq $num_cores_r);do
   cat receptor/receptor$j/*.dat >>energies_receptor.dat
#   ((j+=1))
done
for k in $(seq $num_cores_l);do
    cat ligand/ligand$k/*.dat >>energies_ligand.dat
#    ((k+=1))
done

awk '{print ($1 + $2 + $3 + $5 + $8 + $4 + $7 + $6 + $10 + $11)}'  energies_complex.dat > PBTOT_complex.dat
awk '{print ($1 + $2 + $3 + $5 + $8 + $4 + $7 + $6 + $10 + $11)}'  energies_receptor.dat > PBTOT_receptor.dat
awk '{print ($1 + $2 + $3 + $5 + $8 + $4 + $7 + $6 + $10 + $11)}'  energies_ligand.dat > PBTOT_ligand.dat

paste PBTOT_complex.dat PBTOT_receptor.dat PBTOT_ligand.dat > energies_c_r_l.dat
awk '{ print $1 - $2 - $3}' energies_c_r_l.dat > MMPBSA_$1.mmpbsa

