#!/bin/bash
grep "Search Result" Log/*.out | sort -n -k3 -r
