/* This file is minor changes for the Data General AViiON intel machines
   i586-dg-dguxR4* (tested on i586-dg-dguxR4.11MU04)
   Done by Ehud Karni, 1998-may-30, ehud@unix.simonwiesel.co.il */

#include "aviion.h"                /* 1st load m88k DGUX definitions */

#define INTEL_DGUX                 /* define for future possible use */

/* Intel machines are LITTLE ENDIAN */
#undef WORDS_BIG_ENDIAN

/* No correction needed for byte addresses */
#undef WORD_MACHINE

#ifndef INTEL386
#define INTEL386                   /* Identify as Intel machine */
#endif

#undef  m88k                       /* It sure is NOT a Motorola machine */

/* INTEL DG/UX needs some extra libs (-lelf ?) */
#define LIBS_MACHINE -lsocket -lnsl
