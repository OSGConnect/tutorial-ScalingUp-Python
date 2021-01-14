#!/bin/bash

module load py-scipy/1.1.0-py3.7

python3 ./rosen_brock_brute_opt.py  $1 $2 $3 $4
