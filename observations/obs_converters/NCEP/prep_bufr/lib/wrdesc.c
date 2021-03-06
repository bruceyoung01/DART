/*$$$  SUBPROGRAM DOCUMENTATION BLOCK
C
C SUBPROGRAM:    WRDESC
C   PRGMMR: ATOR             ORG: NP12       DATE: 2004-08-18
C
C ABSTRACT:  GIVEN THE BIT-WISE REPRESENTATION OF A DESCRIPTOR,
C   THIS ROUTINE ADDS IT TO AN ONGOING ARRAY OF DESCRIPTORS, AFTER
C   FIRST MAKING SURE THAT THERE IS ENOUGH ROOM IN THE ARRAY.
C   IF AN ARRAY OVERFLOW OCCURS, THEN AN APPROPRIATE ERROR MESSAGE
C   WILL BE WRITTEN VIA BORT.
C
C PROGRAM HISTORY LOG:
C 2004-08-18  J. ATOR    -- ORIGINAL AUTHOR
C DART $Id$
C
C USAGE:    CALL WRDESC( DESC, DESCARY, NDESCARY )
C   INPUT ARGUMENT LIST:
C     DESC     - INTEGER: BIT-WISE REPRESENTATION OF DESCRIPTOR
C		 TO BE WRITTEN INTO DESCARY
C     DESCARY  - INTEGER: ARRAY OF DESCRIPTORS
C     NDESCARY - INTEGER: NUMBER OF DESCRIPTORS WRITTEN SO FAR
C		 INTO DESCARY
C
C   OUTPUT ARGUMENT LIST:
C     DESCARY  - INTEGER: ARRAY OF DESCRIPTORS
C     NDESCARY - INTEGER: NUMBER OF DESCRIPTORS WRITTEN SO FAR
C		 INTO DESCARY
C
C REMARKS:
C    THIS ROUTINE CALLS:        BORT
C    THIS ROUTINE IS CALLED BY: RESTD
C                               Normally not called by application
C                               programs but it could be.
C
C ATTRIBUTES:
C   LANGUAGE: C
C   MACHINE:  PORTABLE TO ALL PLATFORMS
C
C$$$*/

#include "bufrlib.h"

void wrdesc( f77int desc, f77int descary[], f77int *ndescary )
{
    char errstr[129];

/*
**  Is there room in descary for desc ?
*/
    if ( ( *ndescary + 1 ) < MAXNC ) {
	descary[(*ndescary)++] = desc;
    }
    else {
	sprintf( errstr, "BUFRLIB: WRDESC - EXPANDED SECTION 3 CONTAINS"
			" MORE THAN %d DESCRIPTORS", MAXNC );
	bort( errstr, ( f77int ) strlen( errstr ) );
    }

    return;
}
