#!/bin/bash

#==================================================
#    FILE:  setup_kg.sh
#
#    USAGE:  ./setup_kg.sh [validation-size] [sample-size]
#
#    DESCRIPTION: downloads kaggle files, extracts zip-files,
#                 creates directories, and moves files
#
#    AUTHOR:  Jonas Pettersson, j.g.f.pettersson@gmail.com
#    CREATED:  31/12/2016
#==================================================


#    FUNCTION:  mv_rand [source-dir] [sample-size] [target-dir]
#    DESCRIPTION: moves [sample-size] number of random files from
#                           [source-dir] to [target-dir]
function mv_rand {
    echo Moving $2 files from $1 to $3
    for i in $(seq 1 $2)
    do
        RANGE=`ls $1 | wc -l`
        rand_idx=$(( ($RANDOM % RANGE) + 1 ))
        mv -i `echo $1$(ls $1 | head -$rand_idx | tail -1)` $3
        echo -ne $i'\r'
    done
    echo -ne '\n'
}

#    FUNCTION:  cp_rand [source-dir] [sample-size] [target-dir]
#    DESCRIPTION: copies [sample-size] number of random files from
#                           [source-dir] to [target-dir]
function cp_rand {
    echo Copying $2 files from $1 to $3
    for i in $(seq 1 $2)
    do
        RANGE=`ls $1 | wc -l`
        rand_idx=$(( ($RANDOM % RANGE) + 1 ))
        cp `echo $1$(ls $1 | head -$rand_idx | tail -1)` $3
        echo -ne $i'\r'
    done
    echo -ne '\n'
}

set -e

if [ "$1" == "-h" ]; then
    echo usage: $0 validation-size sample-size
    exit 0
fi

if [ "$(ls -A ./)" ]; then
    read -n1 -p "Directory is not empty! Proceed? [y,n]" doit
    case $doit in
        y|Y) echo ;;
        n|N) echo; exit 0 ;;
        *) echo; exit 0 ;;
    esac
fi

if [ $# -lt 2 ]
then
    sampleSz=100
    echo sample-size set to 100
elif ! [ $2 -eq $2 2>/dev/null ]
then
    echo $2 is not a valid integer
        echo usage: $0 validation-size sample-size
    exit 1
else
    sampleSz=$2
fi

if [ $# -lt 1 ]
then
    validSz=1000
    echo validation-size set to 1000
elif ! [ $1 -eq $1 2>/dev/null ]
then
    echo $1 is not a valid integer
        echo usage: $0 validation-size sample-size
    exit 1
else
    validSz=$1
fi

# get files from Kaggle (see https://github.com/floydwch/kaggle-cli)
read -n1 -p "Download from kaggle? [y,n]" doit
case $doit in
    y|Y)
	echo
	echo Downloading...
	kg download
	;;
    n|N) echo ;;
    *) echo ;;
esac

# unzip into test / train directories and delete zip-files
read -n1 -p "Unzip? [y,n]" doit
case $doit in
    y|Y)
	echo
	echo Unzipping ...
	unzip -q test.zip
	# mv test_stg1 test
	unzip -q train.zip
	rm -vi test.zip
	rm -vi train.zip
	;;
    n|N) echo ;;
    *) echo ;;
esac

# move all test pics into a subdirectory
read -n1 -p "Move test files to directory unknown? [y,n]" doit
case $doit in
    y|Y)
	echo
	mkdir test/unknown
	mv test/*.jpg test/unknown/
	;;
    n|N) echo ;;
    *) echo ;;
esac

# move training data into separate directories according to class
read -n1 -p "Move cats and dogs original files to subdirectories? [y,n]" doit
case $doit in
    y|Y)
	echo
	mkdir -v train/cats
	mkdir -v train/dogs
	mv train/cat*.jpg train/cats/
	mv train/dog*.jpg train/dogs/
	;;
    n|N) echo ;;
    *) echo ;;
esac

# create directory structure
echo Creating directory structure ...
mkdir -v valid
mkdir -v sample
mkdir -v sample/train
mkdir -v sample/valid

find train/ -type d | tail -n +2 | cut -c7- > dirs.txt
cd valid
xargs mkdir -p < ../dirs.txt
cd ..
cd sample/train
xargs mkdir -p < ../../dirs.txt
cd ../..
cd sample/valid
xargs mkdir -p < ../../dirs.txt
cd ../..

# move a set of validation data to validation directories
for i in `cat dirs.txt`
do
    mv_rand train/$i/ $validSz valid/$i/
done
echo -ne '\n'

# copy a small set of data to sample directories
for i in `cat dirs.txt`
do
    cp_rand train/$i/ $sampleSz sample/train/$i/
done
echo -ne '\n'

for i in `cat dirs.txt`
do
    cp_rand valid/$i/ $sampleSz sample/valid/$i/
done
echo -ne '\n'

# print results
echo -ne '\n'
for i in `cat dirs.txt`
do
    echo train/$i ": " `ls train/$i | wc -l`
    echo valid/$i ": " `ls valid/$i | wc -l`
    echo sample/train/$i ": " `ls sample/train/$i | wc -l`
    echo sample/valid/$i ": " `ls sample/valid/$i | wc -l`
done
