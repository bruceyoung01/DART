#!/bin/csh

# Data Assimilation Research Testbed -- DART
# Copyright 2004-2007, Data Assimilation Research Section
# University Corporation for Atmospheric Research
# Licensed under the GPL -- www.gpl.org/licenses/gpl.html
#
# <next few lines under version control, do not edit>
# $URL$
# $Id$
# $Revision$
# $Date$

 set FCFLAGS = "-r8 -pc 64"
 \rm -f *.o

 pgf90 -c ${FCFLAGS} grabbufr.f
 pgf90 -o ../exe/grabbufr.x ${FCFLAGS} grabbufr.o ../lib/bufrlib.a
