#! /usr/bin/env bash

SPEAR_ROOT=$( cd $( dirname $0 )/.. ; /bin/pwd )
export PYTHONPATH=$SPEAR_ROOT/python:$SPEAR_ROOT/ext/EQ-Py
python $SPEAR_ROOT/test/test.py
