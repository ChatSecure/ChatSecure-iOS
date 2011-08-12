/*
 *  Off-the-Record Messaging library
 *  Copyright (C) 2004-2008  Ian Goldberg, Chris Alexander, Nikita Borisov
 *                           <otr@cypherpunks.ca>
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of version 2.1 of the GNU Lesser General
 *  Public License as published by the Free Software Foundation.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifndef __SERIAL_H__
#define __SERIAL_H__

#undef DEBUG

#ifdef DEBUG

#include <stdio.h>

#define debug_data(t,b,l) do { const unsigned char *data = (b); size_t i; \
	fprintf(stderr, "%s: ", (t)); \
	for(i=0;i<(l);++i) { \
	    fprintf(stderr, "%02x", data[i]); \
	} \
	fprintf(stderr, "\n"); \
    } while(0)

#define debug_int(t,b) do { const unsigned char *data = (b); \
	unsigned int v = \
	    (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3]; \
	fprintf(stderr, "%s: %u (0x%x)\n", (t), v, v); \
    } while(0)

#else
#define debug_data(t,b,l)
#define debug_int(t,b)
#endif

#define write_int(x) do { \
	bufp[0] = ((x) >> 24) & 0xff; \
	bufp[1] = ((x) >> 16) & 0xff; \
	bufp[2] = ((x) >> 8) & 0xff; \
	bufp[3] = (x) & 0xff; \
	bufp += 4; lenp -= 4; \
    } while(0)

#define write_mpi(x,nx,dx) do { \
	write_int(nx); \
	gcry_mpi_print(format, bufp, lenp, NULL, (x)); \
	debug_data((dx), bufp, (nx)); \
	bufp += (nx); lenp -= (nx); \
    } while(0)

#define require_len(l) do { \
	if (lenp < (l)) goto invval; \
    } while(0)

#define read_int(x) do { \
	require_len(4); \
	(x) = (bufp[0] << 24) | (bufp[1] << 16) | (bufp[2] << 8) | bufp[3]; \
	bufp += 4; lenp -= 4; \
    } while(0)

#define read_mpi(x) do { \
	size_t mpilen; \
	read_int(mpilen); \
	if (mpilen) { \
	    require_len(mpilen); \
	    gcry_mpi_scan(&(x), GCRYMPI_FMT_USG, bufp, mpilen, NULL); \
	} else { \
	    (x) = gcry_mpi_set_ui(NULL, 0); \
	} \
	bufp += mpilen; lenp -= mpilen; \
    } while(0)

#endif
