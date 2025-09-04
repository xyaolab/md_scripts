#!/bin/bash
## Make sure all files are in the current directory before you run this script.

# Replace the topology file name with the one in your case. No need to have '.prmtop' at the end.
prmtop_complex='XXX_nowat'

prmtop_receptor='receptor'
prmtop_ligand='ligand'
trajin='complex.nc'

# Replace YYY with the residue name or residue number of the ligand
receptor_strip=':YYY' 

# Replace ZZZ with the last residue number of the receptor
ligand_strip=':1-ZZZ'


## DO NOT CHANGE FOLLOWNIG LINES IF YOU DON'T KNOW WHAT YOU ARE DOING ##

rm -rf complex receptor ligand rstfiles

mkdir complex
mkdir receptor
mkdir ligand
mkdir rstfiles

initialize_files () {
    cat > collect_$1.ptraj <<EOF
trajin ${trajin} 
$4 $5
trajout rstfiles/$1 restart multi
go
EOF


    cat > $2.sh <<EOF
#!/bin/bash 

module load ambertools

echo Running on host `hostname`
echo Time is `date`
echo Directory is `pwd`

cpptraj ${prmtop_complex}.prmtop collect_$1.ptraj
EOF

    cat >$1.sh<<EOF
#!/bin/bash 
#SBATCH --job-name=$1
#SBATCH --ntasks=1
#SBATCH --mem=16GB
#SBATCH --time=168:00:00
#SBATCH --error=$1.%J.err
#SBATCH --output=$1.%J.out
##SBATCH --partition=joeyaolab
##SBATCH --gres=gpu

module purge
module load compiler/gcc/11 openmpi/4.1 ambertools/23

echo Time is `date`
echo Directory is `pwd`
echo Reading from \$1 to \$2

date
x=\$1  
total=\$2

while [ \$x -le \$total ]
do

    sander -O -i ../../mmpbsa$6.in -o mmpbsa_c.out -p ../../$3.prmtop -c ../../rstfiles/$1.\${x}
    awk 'NR==6, NR==9 {print}' mdinfo | sed -e 's/1-4 /1-4-/g' | awk '{print \$3,  \$6,  \$9}' | xargs   >> energies_$1.dat

    x=\$((\$x + 1 ))
done
date
EOF

    chmod +x $1.sh
    chmod +x $2.sh

#    qsub $2.sh
    bash $2.sh
}

initialize_files complex c ${prmtop_complex}
initialize_files receptor r ${prmtop_receptor} strip ${receptor_strip}
initialize_files ligand l ${prmtop_ligand} strip ${ligand_strip} _l

cat >mmpbsa.in <<EOF
initial minimization w/ position restraints on DNA, 9.0 cut
 &cntrl
  imin   = 1, ntx  = 1, ipb  = 2, inp = 2, 
 /
 &pb
  epsout=80.0, epsin=1.0, fillratio=2.0,
  radiopt = 0,
 /
EOF

cat >mmpbsa_l.in <<EOF
initial minimization w/ position restraints on DNA, 9.0 cut
 &cntrl
  imin   = 1, ntx  = 1, ipb  = 2, inp = 2, 
 /
 &pb
  epsout=80.0, epsin=1.0, fillratio=4.0,
  radiopt = 0,
 /
EOF
