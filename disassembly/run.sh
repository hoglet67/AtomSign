#!/bin/bash -e

export PYTHONPATH=../../py8dis/py8dis:../common:$PATH

python atom_sign.py > atom_sign.asm
beebasm -i atom_sign.asm -v -o atom_sign.bin > atom_sign.log
md5sum atom_sign.orig atom_sign.bin
