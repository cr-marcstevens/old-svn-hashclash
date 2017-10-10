/**************************************************************************\
|
|    Copyright (C) 2009 Marc Stevens
|
|    This program is free software: you can redistribute it and/or modify
|    it under the terms of the GNU General Public License as published by
|    the Free Software Foundation, either version 3 of the License, or
|    (at your option) any later version.
|
|    This program is distributed in the hope that it will be useful,
|    but WITHOUT ANY WARRANTY; without even the implied warranty of
|    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
|    GNU General Public License for more details.
|
|    You should have received a copy of the GNU General Public License
|    along with this program.  If not, see <http://www.gnu.org/licenses/>.
|
\**************************************************************************/

.text
    .align	3
    .global	reduce_trails
    .type	reduce_trails,@function
    .global	reduce_trails2
    .type	reduce_trails2,@function


#define REGIHV(i)	$(i+20)
#define	REGIHV1(i)	$(i+24)
#define REGIHV2(i)	$(i+28)
#define	REGWS(i)	$(i+32)
#define REGWS1(i)	$(i+36)
#define REGWS2(i)	$(i+40)
#define	REGM(i)		$(i+44)
#define REGM1(i)	$(i+60)
#define REGM2(i)	$(i+76)
#define REGASTART	$10
#define REGBSTART	$11
#define REGCSTART	$96
#define REGA		$12
#define REGB		$13
#define REGC		$97
#define REGLEN		$14
#define REGLEN2		$15
#define REGMAXLEN	$16
#define REGHBMASK	$98
#define	IMADDRAC(i)	i*16+md5_acvec
#define	REGFF		$17
#define	REGFF1		$18
#define	REGPC1		$19
#define	REGPC2		$92
#define	REGPC3		$93
#define REGSELB		$94

#define REGREADY	$95

// using registers: $0 - $98

#define STOREREG(i)	stqa	$(i),	(i*16)+regstore
#define LOADREG(i)	lqa		$(i),	(i*16)+regstore



.align 3
reduce_trails:
// input
//	$3:	@ihv1
//	$4:	@ihv2
//	$5:	@msg1
//	$6:	@msg2
//	$7:	@a,b,len,rng,id,distpointmask,maxlen (ignored)
//	$8:	@buffer
//			blocks of:
//				vec_uint32 a1, b1, len1;
//				vec_uint32 a2, b2, len2;
//			it is assumed that len1 > len2
//				a1,b1 will be processed len1-len2 times
//				and then saved
//	$9:	@bufferend

    STOREREG(80)
    STOREREG(81)
    STOREREG(82)
    STOREREG(83)
    STOREREG(84)
    STOREREG(85)
    STOREREG(86)
    STOREREG(87)
    STOREREG(88)
    STOREREG(89)
    STOREREG(90)
    STOREREG(91)
    STOREREG(92)
    STOREREG(93)
    STOREREG(94)
    STOREREG(95)
    STOREREG(96)
    STOREREG(97)
    STOREREG(98)
    
// load a & b and other stuff
//		vec_uint32 a1, b1, c1, len1;
//		vec_uint32 a2, b2, c2, len2;

	lqd		REGLEN,		0x30($8)	
	lqd		REGLEN2,	0x70($8)
	lqd		REGA,		0x00($8)	
	lqd		REGB,		0x10($8)
	lqd		REGC,		0x20($8)

//	REGREADY is -1 for those not ready and 0 for those ready
//  when ready we copy the resp. parts from a1, b1, len to astart, bstart, maxlen
//  after the loop we store these
	
// load precalculated working states
    lqa		REGWS1(0),	 0 + workingstate1
    lqa		REGWS1(1),	16 + workingstate1
    lqa		REGWS1(2),	32 + workingstate1
    clgt	REGREADY,	REGLEN,		REGLEN2
    lqa		REGWS1(3),	48 + workingstate1
    or		REGASTART,	REGA,		REGA
    lqa		REGWS2(0),	 0 + workingstate2
    or		REGCSTART,	REGC,		REGC
    lqa		REGWS2(1),	16 + workingstate2
    or		REGMAXLEN,	REGLEN,		REGLEN
    lqa		REGWS2(2),	32 + workingstate2
    or		REGBSTART,	REGB,		REGB
    lqa		REGWS2(3),	48 + workingstate2
    lqd         REGHBMASK,      0xe0($7)
// load ihv1 & ihv2
    lqd		REGIHV1(0),	 0($3)
    lqd		REGIHV1(1),	16($3)
    lqd		REGIHV1(2),	32($3)
    lqd		REGIHV1(3),	48($3)
    lqd		REGIHV2(0),	 0($4)
    lqd		REGIHV2(1),	16($4)
    lqd		REGIHV2(2),	32($4)
    lqd		REGIHV2(3),	48($4)
// load msg1 & msg2
    lqd		REGM1(0),	0x00($5)
    lqd		REGM1(1),	0x10($5)
    lqd		REGM1(2),	0x20($5)
    lqd		REGM1(3),	0x30($5)
    lqd		REGM1(4),	0x40($5)
    lqd		REGM1(5),	0x50($5)
    lqd		REGM1(6),	0x60($5)
    lqd		REGM1(7),	0x70($5)
    lqd		REGM1(8),	0x80($5)
    lqd		REGM1(9),	0x90($5)
    lqd		REGM1(10),	0xa0($5)
    lqd		REGM1(11),	0xb0($5)
    lqd		REGM1(12),	0xc0($5)
    lqd		REGM2(0),	0x00($6)
    lqd		REGM2(1),	0x10($6)
    lqd		REGM2(2),	0x20($6)
    lqd		REGM2(3),	0x30($6)
    lqd		REGM2(4),	0x40($6)
    lqd		REGM2(5),	0x50($6)
    lqd		REGM2(6),	0x60($6)
    lqd		REGM2(7),	0x70($6)
    lqd		REGM2(8),	0x80($6)
    lqd		REGM2(9),	0x90($6)
    lqd		REGM2(10),	0xa0($6)
    lqd		REGM2(11),	0xb0($6)
    lqd		REGM2(12),	0xc0($6)


.align	3
md5compress_loop2:
/*** ROUND 1 ***/
    clgt	REGSELB,	REGA,		REGB
    lqa		REGPC2,		IMADDRAC(14)

    selb	REGWS(3),	REGWS1(3),	REGWS2(3),	REGSELB
    rotqbyi	REGM(14),	REGA,		0
    selb	REGWS(0),	REGWS1(0),	REGWS2(0),	REGSELB
    rotqbyi	REGM(13),	REGC,		0
    a		REGWS(3),	REGWS(3),	REGC
    lqa		REGPC3,		IMADDRAC(15)
    selb	REGWS(1),	REGWS1(1),	REGWS2(1),	REGSELB
    rotqbyi	REGM(15),	REGB,		0    
    roti	REGWS(3),	REGWS(3),	12    
    lqa		REGPC1,		IMADDRAC(16)
    selb	REGWS(2),	REGWS1(2),	REGWS2(2),	REGSELB
    a		REGPC2,		REGPC2,		REGM(14)
    a		REGWS(3),	REGWS(3),	REGWS(0)
    a		REGWS(2),	REGWS(2),	REGPC2
    selb	REGFF,		REGWS(1),	REGWS(0),	REGWS(3)
    a		REGPC3,		REGPC3,		REGM(15)
    a		REGWS(2),	REGWS(2),	REGFF
    a		REGWS(1),	REGWS(1),	REGPC3

    roti	REGWS(2),	REGWS(2),	17
    lnop
    selb	REGM(1),	REGM1(1),	REGM2(1),	REGSELB
    selb	REGM(6),	REGM1(6),	REGM2(6),	REGSELB
    a		REGPC1,		REGPC1,		REGM(1)
    lqa		REGPC2,		IMADDRAC(17)
    a		REGWS(2),	REGWS(2),	REGWS(3)
    selb	REGM(11),	REGM1(11),	REGM2(11),	REGSELB

    selb	REGFF,		REGWS(0),	REGWS(3),	REGWS(2)
    a		REGWS(0),	REGWS(0),	REGPC1
    a		REGWS(1),	REGWS(1),	REGFF
    selb	REGM(0),	REGM1(0),	REGM2(0),	REGSELB
    roti	REGWS(1),	REGWS(1),	22
    lnop
    a		REGPC2,		REGPC2,		REGM(6)
    lqa		REGPC3,		IMADDRAC(18)
    selb	REGM(5),	REGM1(5),	REGM2(5),	REGSELB
    selb	REGM(10),	REGM1(10),	REGM2(10),	REGSELB
    a		REGWS(1),	REGWS(1),	REGWS(2)
    selb	REGM(4),	REGM1(4),	REGM2(4),	REGSELB

/*** ROUND 2 ***/

    selb	REGFF,		REGWS(2),	REGWS(1),	REGWS(3)
    a		REGWS(3),	REGWS(3),	REGPC2
    a		REGWS(0),	REGWS(0),	REGFF
    selb	REGM(9),	REGM1(9),	REGM2(9),	REGSELB
    roti	REGWS(0),	REGWS(0),	5
    lnop
    a		REGPC3,		REGPC3,		REGM(11)
    lqa		REGPC1,		IMADDRAC(19)
    selb	REGM(3),	REGM1(3),	REGM2(3),	REGSELB
    selb	REGM(8),	REGM1(8),	REGM2(8),	REGSELB
    a		REGWS(0),	REGWS(0),	REGWS(1)
//    selb	REGM(13),	REGM1(13),	REGM2(13),	REGSELB

    selb	REGFF,		REGWS(1),	REGWS(0),	REGWS(2)
    a		REGWS(2),	REGWS(2),	REGPC3
    a		REGWS(3),	REGWS(3),	REGFF
    selb	REGM(2),	REGM1(2),	REGM2(2),	REGSELB
    roti	REGWS(3),	REGWS(3),	9
//    lnop
    a		REGPC1,		REGPC1,		REGM(0)
    lqa		REGPC2,		IMADDRAC(20)
    selb	REGM(7),	REGM1(7),	REGM2(7),	REGSELB
    selb	REGM(12),	REGM1(12),	REGM2(12),	REGSELB
    a		REGWS(3),	REGWS(3),	REGWS(0)
    selb	REGIHV(0),	REGIHV1(0),	REGIHV2(0),	REGSELB

    selb	REGFF,		REGWS(0),	REGWS(3),	REGWS(1)
    a		REGWS(1),	REGWS(1),	REGPC1
    a		REGWS(2),	REGWS(2),	REGFF
    selb	REGIHV(1),	REGIHV1(1),	REGIHV2(1),	REGSELB
    roti	REGWS(2),	REGWS(2),	14
    lnop
    a		REGPC2,		REGPC2,		REGM(5)
    lqa		REGPC3,		IMADDRAC(21)
    selb	REGIHV(2),	REGIHV1(2),	REGIHV2(2),	REGSELB
    selb	REGIHV(3),	REGIHV1(3),	REGIHV2(3),	REGSELB
    a		REGWS(2),	REGWS(2),	REGWS(3)

    selb	REGFF,		REGWS(3),	REGWS(2),	REGWS(0)
    a		REGWS(0),	REGWS(0),	REGPC2
    a		REGWS(1),	REGWS(1),	REGFF
    roti	REGWS(1),	REGWS(1),	20
    a		REGPC3,		REGPC3,		REGM(10)
    lqa		REGPC1,		IMADDRAC(22)
    a		REGWS(1),	REGWS(1),	REGWS(2)

    selb	REGFF,		REGWS(2),	REGWS(1),	REGWS(3)
    a		REGWS(3),	REGWS(3),	REGPC3
    a		REGWS(0),	REGWS(0),	REGFF
    roti	REGWS(0),	REGWS(0),	5
    a		REGPC1,		REGPC1,		REGM(15)
    lqa		REGPC2,		IMADDRAC(23)
    a		REGWS(0),	REGWS(0),	REGWS(1)

    selb	REGFF,		REGWS(1),	REGWS(0),	REGWS(2)
    a		REGWS(2),	REGWS(2),	REGPC1
    a		REGWS(3),	REGWS(3),	REGFF
    roti	REGWS(3),	REGWS(3),	9
    a		REGPC2,		REGPC2,		REGM(4)
    lqa		REGPC3,		IMADDRAC(24)
    a		REGWS(3),	REGWS(3),	REGWS(0)
    
    selb	REGFF,		REGWS(0),	REGWS(3),	REGWS(1)
    a		REGWS(1),	REGWS(1),	REGPC2
    a		REGWS(2),	REGWS(2),	REGFF
    roti	REGWS(2),	REGWS(2),	14
    a		REGPC3,		REGPC3,		REGM(9)
    lqa		REGPC1,		IMADDRAC(25)
    a		REGWS(2),	REGWS(2),	REGWS(3)

    selb	REGFF,		REGWS(3),	REGWS(2),	REGWS(0)
    a		REGWS(0),	REGWS(0),	REGPC3
    a		REGWS(1),	REGWS(1),	REGFF
    roti	REGWS(1),	REGWS(1),	20
    a		REGPC1,		REGPC1,		REGM(14)
    lqa		REGPC2,		IMADDRAC(26)
    a		REGWS(1),	REGWS(1),	REGWS(2)

    selb	REGFF,		REGWS(2),	REGWS(1),	REGWS(3)
    a		REGWS(3),	REGWS(3),	REGPC1
    a		REGWS(0),	REGWS(0),	REGFF
    roti	REGWS(0),	REGWS(0),	5
    a		REGPC2,		REGPC2,		REGM(3)
    lqa		REGPC3,		IMADDRAC(27)
    a		REGWS(0),	REGWS(0),	REGWS(1)

    selb	REGFF,		REGWS(1),	REGWS(0),	REGWS(2)
    a		REGWS(2),	REGWS(2),	REGPC2
    a		REGWS(3),	REGWS(3),	REGFF
    roti	REGWS(3),	REGWS(3),	9
    a		REGPC3,		REGPC3,		REGM(8)
    lqa		REGPC1,		IMADDRAC(28)
    a		REGWS(3),	REGWS(3),	REGWS(0)

    selb	REGFF,		REGWS(0),	REGWS(3),	REGWS(1)
    a		REGWS(1),	REGWS(1),	REGPC3
    a		REGWS(2),	REGWS(2),	REGFF
    roti	REGWS(2),	REGWS(2),	14
    a		REGPC1,		REGPC1,		REGM(13)
    lqa		REGPC2,		IMADDRAC(29)
    a		REGWS(2),	REGWS(2),	REGWS(3)

    selb	REGFF,		REGWS(3),	REGWS(2),	REGWS(0)
    a		REGWS(0),	REGWS(0),	REGPC1
    a		REGWS(1),	REGWS(1),	REGFF
    roti	REGWS(1),	REGWS(1),	20
    a		REGPC2,		REGPC2,		REGM(2)
    lqa		REGPC3,		IMADDRAC(30)
    a		REGWS(1),	REGWS(1),	REGWS(2)

    selb	REGFF,		REGWS(2),	REGWS(1),	REGWS(3)
    a		REGWS(3),	REGWS(3),	REGPC2
    a		REGWS(0),	REGWS(0),	REGFF
    roti	REGWS(0),	REGWS(0),	5
    a		REGPC3,		REGPC3,		REGM(7)
    lqa		REGPC1,		IMADDRAC(31)
    a		REGWS(0),	REGWS(0),	REGWS(1)

    selb	REGFF,		REGWS(1),	REGWS(0),	REGWS(2)
    a		REGWS(2),	REGWS(2),	REGPC3
    a		REGWS(3),	REGWS(3),	REGFF
    roti	REGWS(3),	REGWS(3),	9
    a		REGPC1,		REGPC1,		REGM(12)
    lqa		REGPC2,		IMADDRAC(32)
    a		REGWS(3),	REGWS(3),	REGWS(0)

    selb	REGFF,		REGWS(0),	REGWS(3),	REGWS(1)
    a		REGWS(1),	REGWS(1),	REGPC1
    a		REGWS(2),	REGWS(2),	REGFF
    roti	REGWS(2),	REGWS(2),	14
    a		REGPC2,		REGPC2,		REGM(5)
    lqa		REGPC3,		IMADDRAC(33)
    a		REGWS(2),	REGWS(2),	REGWS(3)

    selb	REGFF,		REGWS(3),	REGWS(2),	REGWS(0)
    a		REGWS(0),	REGWS(0),	REGPC2
    a		REGWS(1),	REGWS(1),	REGFF
    roti	REGWS(1),	REGWS(1),	20
    xor		REGFF,		REGWS(2),	REGWS(3)
    lqa		REGPC1,		IMADDRAC(34)
    a		REGWS(1),	REGWS(1),	REGWS(2)
    a		REGPC3,		REGPC3,		REGM(8)

/*** ROUND 3 ***/

    xor		REGFF,		REGFF,		REGWS(1)
    a		REGWS(3),	REGWS(3),	REGPC3
    a		REGWS(0),	REGWS(0),	REGFF
    xor		REGFF,		REGWS(1),	REGWS(2)
    roti	REGWS(0),	REGWS(0),	4
    a		REGPC1,		REGPC1,		REGM(11)
    lqa		REGPC2,		IMADDRAC(35)
    a		REGWS(0),	REGWS(0),	REGWS(1)


    xor		REGFF,		REGFF,		REGWS(0)
    a		REGWS(2),	REGWS(2),	REGPC1
    a		REGWS(3),	REGWS(3),	REGFF
    xor		REGFF,		REGWS(0),	REGWS(1)
    roti	REGWS(3),	REGWS(3),	11
    a		REGPC2,		REGPC2,		REGM(14)
    lqa		REGPC3,		IMADDRAC(36)
    a		REGWS(3),	REGWS(3),	REGWS(0)

    xor		REGFF,		REGFF,		REGWS(3)
    a		REGWS(1),	REGWS(1),	REGPC2
    a		REGWS(2),	REGWS(2),	REGFF
    xor		REGFF,		REGWS(3),	REGWS(0)
    roti	REGWS(2),	REGWS(2),	16
    a		REGPC3,		REGPC3,		REGM(1)
    lqa		REGPC1,		IMADDRAC(37)
    a		REGWS(2),	REGWS(2),	REGWS(3)

    xor		REGFF,		REGFF,		REGWS(2)
    a		REGWS(0),	REGWS(0),	REGPC3
    a		REGWS(1),	REGWS(1),	REGFF
    xor		REGFF,		REGWS(2),	REGWS(3)
    roti	REGWS(1),	REGWS(1),	23
    a		REGPC1,		REGPC1,		REGM(4)
    lqa		REGPC2,		IMADDRAC(38)
    a		REGWS(1),	REGWS(1),	REGWS(2)


    xor		REGFF,		REGFF,		REGWS(1)
    a		REGWS(3),	REGWS(3),	REGPC1
    a		REGWS(0),	REGWS(0),	REGFF
    xor		REGFF,		REGWS(1),	REGWS(2)
    roti	REGWS(0),	REGWS(0),	4
    a		REGPC2,		REGPC2,		REGM(7)
    lqa		REGPC3,		IMADDRAC(39)
    a		REGWS(0),	REGWS(0),	REGWS(1)

    xor		REGFF,		REGFF,		REGWS(0)
    a		REGWS(2),	REGWS(2),	REGPC2
    a		REGWS(3),	REGWS(3),	REGFF
    xor		REGFF,		REGWS(0),	REGWS(1)
    roti	REGWS(3),	REGWS(3),	11
    a		REGPC3,		REGPC3,		REGM(10)
    lqa		REGPC1,		IMADDRAC(40)
    a		REGWS(3),	REGWS(3),	REGWS(0)

    xor		REGFF,		REGFF,		REGWS(3)
    a		REGWS(1),	REGWS(1),	REGPC3
    a		REGWS(2),	REGWS(2),	REGFF
    xor		REGFF,		REGWS(3),	REGWS(0)
    roti	REGWS(2),	REGWS(2),	16
    a		REGPC1,		REGPC1,		REGM(13)
    lqa		REGPC2,		IMADDRAC(41)
    a		REGWS(2),	REGWS(2),	REGWS(3)

    xor		REGFF,		REGFF,		REGWS(2)
    a		REGWS(0),	REGWS(0),	REGPC1
    a		REGWS(1),	REGWS(1),	REGFF
    xor		REGFF,		REGWS(2),	REGWS(3)
    roti	REGWS(1),	REGWS(1),	23
    a		REGPC2,		REGPC2,		REGM(0)
    lqa		REGPC3,		IMADDRAC(42)
    a		REGWS(1),	REGWS(1),	REGWS(2)

    xor		REGFF,		REGFF,		REGWS(1)
    a		REGWS(3),	REGWS(3),	REGPC2
    a		REGWS(0),	REGWS(0),	REGFF
    xor		REGFF,		REGWS(1),	REGWS(2)
    roti	REGWS(0),	REGWS(0),	4
    a		REGPC3,		REGPC3,		REGM(3)
    lqa		REGPC1,		IMADDRAC(43)
    a		REGWS(0),	REGWS(0),	REGWS(1)

    xor		REGFF,		REGFF,		REGWS(0)
    a		REGWS(2),	REGWS(2),	REGPC3
    a		REGWS(3),	REGWS(3),	REGFF
    xor		REGFF,		REGWS(0),	REGWS(1)
    roti	REGWS(3),	REGWS(3),	11
    a		REGPC1,		REGPC1,		REGM(6)
    lqa		REGPC2,		IMADDRAC(44)
    a		REGWS(3),	REGWS(3),	REGWS(0)

    xor		REGFF,		REGFF,		REGWS(3)
    a		REGWS(1),	REGWS(1),	REGPC1
    a		REGWS(2),	REGWS(2),	REGFF
    xor		REGFF,		REGWS(3),	REGWS(0)
    roti	REGWS(2),	REGWS(2),	16
    a		REGPC2,		REGPC2,		REGM(9)
    lqa		REGPC3,		IMADDRAC(45)
    a		REGWS(2),	REGWS(2),	REGWS(3)

    xor		REGFF,		REGFF,		REGWS(2)
    a		REGWS(0),	REGWS(0),	REGPC2
    a		REGWS(1),	REGWS(1),	REGFF
    xor		REGFF,		REGWS(2),	REGWS(3)
    roti	REGWS(1),	REGWS(1),	23
    a		REGPC3,		REGPC3,		REGM(12)
    lqa		REGPC1,		IMADDRAC(46)
    a		REGWS(1),	REGWS(1),	REGWS(2)

    xor		REGFF,		REGFF,		REGWS(1)
    a		REGWS(3),	REGWS(3),	REGPC3
    a		REGWS(0),	REGWS(0),	REGFF
    xor		REGFF,		REGWS(1),	REGWS(2)
    roti	REGWS(0),	REGWS(0),	4
    a		REGPC1,		REGPC1,		REGM(15)
    lqa		REGPC2,		IMADDRAC(47)
    a		REGWS(0),	REGWS(0),	REGWS(1)

    xor		REGFF,		REGFF,		REGWS(0)
    a		REGWS(2),	REGWS(2),	REGPC1
    a		REGWS(3),	REGWS(3),	REGFF
    xor		REGFF,		REGWS(0),	REGWS(1)
    roti	REGWS(3),	REGWS(3),	11
    a		REGPC2,		REGPC2,		REGM(2)
    lqa		REGPC3,		IMADDRAC(48)
    a		REGWS(3),	REGWS(3),	REGWS(0)

    xor		REGFF,		REGFF,		REGWS(3)
    a		REGWS(1),	REGWS(1),	REGPC2
    a		REGWS(2),	REGWS(2),	REGFF
    xor		REGFF,		REGWS(3),	REGWS(0)
    roti	REGWS(2),	REGWS(2),	16
    a		REGPC3,		REGPC3,		REGM(0)
    lqa		REGPC1,		IMADDRAC(49)
    a		REGWS(2),	REGWS(2),	REGWS(3)

    xor		REGFF,		REGFF,		REGWS(2)
    a		REGWS(0),	REGWS(0),	REGPC3
    a		REGWS(1),	REGWS(1),	REGFF
    eqv		REGFF1,		REGWS(2),	REGWS(3)
    roti	REGWS(1),	REGWS(1),	23
    a		REGPC1,		REGPC1,		REGM(7)
    lqa		REGPC2,		IMADDRAC(50)
    nand	REGFF,		REGWS(2),	REGWS(2)
    a		REGWS(1),	REGWS(1),	REGWS(2)

/*** ROUND 4 ***/

    selb	REGFF,		REGFF1,		REGFF,		REGWS(1)
    a		REGWS(3),	REGWS(3),	REGPC1
    a		REGWS(0),	REGWS(0),	REGFF
    roti	REGWS(0),	REGWS(0),	6
    eqv		REGFF1,		REGWS(1),	REGWS(2)
    nand	REGFF,		REGWS(1),	REGWS(1)
    a		REGPC2,		REGPC2,		REGM(14)
    lqa		REGPC3,		IMADDRAC(51)
    a		REGWS(0),	REGWS(0),	REGWS(1)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(0)
    a		REGWS(2),	REGWS(2),	REGPC2
    a		REGWS(3),	REGWS(3),	REGFF
    roti	REGWS(3),	REGWS(3),	10
    eqv		REGFF1,		REGWS(0),	REGWS(1)
    nand	REGFF,		REGWS(0),	REGWS(0)
    lnop
    a		REGPC3,		REGPC3,		REGM(5)
    lqa		REGPC1,		IMADDRAC(52)
    a		REGWS(3),	REGWS(3),	REGWS(0)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(3)
    a		REGWS(1),	REGWS(1),	REGPC3
    a		REGWS(2),	REGWS(2),	REGFF
    roti	REGWS(2),	REGWS(2),	15
    eqv		REGFF1,		REGWS(3),	REGWS(0)
    nand	REGFF,		REGWS(3),	REGWS(3)
    lnop
    a		REGPC1,		REGPC1,		REGM(12)
    lqa		REGPC2,		IMADDRAC(53)
    a		REGWS(2),	REGWS(2),	REGWS(3)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(2)
    a		REGWS(0),	REGWS(0),	REGPC1
    a		REGWS(1),	REGWS(1),	REGFF
    roti	REGWS(1),	REGWS(1),	21
    eqv		REGFF1,		REGWS(2),	REGWS(3)
    nand	REGFF,		REGWS(2),	REGWS(2)
    lnop
    a		REGPC2,		REGPC2,		REGM(3)
    lqa		REGPC3,		IMADDRAC(54)
    a		REGWS(1),	REGWS(1),	REGWS(2)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(1)
    a		REGWS(3),	REGWS(3),	REGPC2
    a		REGWS(0),	REGWS(0),	REGFF
    roti	REGWS(0),	REGWS(0),	6
    eqv		REGFF1,		REGWS(1),	REGWS(2)
    nand	REGFF,		REGWS(1),	REGWS(1)
    lnop
    a		REGPC3,		REGPC3,		REGM(10)
    lqa		REGPC1,		IMADDRAC(55)
    a		REGWS(0),	REGWS(0),	REGWS(1)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(0)
    a		REGWS(2),	REGWS(2),	REGPC3
    a		REGWS(3),	REGWS(3),	REGFF
    roti	REGWS(3),	REGWS(3),	10
    eqv		REGFF1,		REGWS(0),	REGWS(1)
    nand	REGFF,		REGWS(0),	REGWS(0)
    lnop
    a		REGPC1,		REGPC1,		REGM(1)
    lqa		REGPC2,		IMADDRAC(56)
    a		REGWS(3),	REGWS(3),	REGWS(0)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(3)
    a		REGWS(1),	REGWS(1),	REGPC1
    a		REGWS(2),	REGWS(2),	REGFF
    roti	REGWS(2),	REGWS(2),	15
    eqv		REGFF1,		REGWS(3),	REGWS(0)
    nand	REGFF,		REGWS(3),	REGWS(3)
    lnop
    a		REGPC2,		REGPC2,		REGM(8)
    lqa		REGPC3,		IMADDRAC(57)
    a		REGWS(2),	REGWS(2),	REGWS(3)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(2)
    a		REGWS(0),	REGWS(0),	REGPC2
    a		REGWS(1),	REGWS(1),	REGFF
    roti	REGWS(1),	REGWS(1),	21
    eqv		REGFF1,		REGWS(2),	REGWS(3)
    nand	REGFF,		REGWS(2),	REGWS(2)
    lnop
    a		REGPC3,		REGPC3,		REGM(15)
    lqa		REGPC1,		IMADDRAC(58)
    a		REGWS(1),	REGWS(1),	REGWS(2)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(1)
    a		REGWS(3),	REGWS(3),	REGPC3
    a		REGWS(0),	REGWS(0),	REGFF
    roti	REGWS(0),	REGWS(0),	6
    eqv		REGFF1,		REGWS(1),	REGWS(2)
    nand	REGFF,		REGWS(1),	REGWS(1)
    lnop
    a		REGPC1,		REGPC1,		REGM(6)
    lqa		REGPC2,		IMADDRAC(59)
    a		REGWS(0),	REGWS(0),	REGWS(1)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(0)
    a		REGWS(2),	REGWS(2),	REGPC1
    a		REGWS(3),	REGWS(3),	REGFF
    roti	REGWS(3),	REGWS(3),	10
    eqv		REGFF1,		REGWS(0),	REGWS(1)
    nand	REGFF,		REGWS(0),	REGWS(0)
    lnop
    a		REGPC2,		REGPC2,		REGM(13)
    lqa		REGPC3,		IMADDRAC(60)
    a		REGWS(3),	REGWS(3),	REGWS(0)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(3)
    a		REGWS(1),	REGWS(1),	REGPC2
    a		REGWS(2),	REGWS(2),	REGFF
    roti	REGWS(2),	REGWS(2),	15
    eqv		REGFF1,		REGWS(3),	REGWS(0)
    nand	REGFF,		REGWS(3),	REGWS(3)
    lnop
    a		REGPC3,		REGPC3,		REGM(4)
    lqa		REGPC1,		IMADDRAC(61)
    a		REGWS(2),	REGWS(2),	REGWS(3)
    
    selb	REGFF,		REGFF1,		REGFF,		REGWS(2)
    a		REGWS(0),	REGWS(0),	REGPC3
    a		REGWS(1),	REGWS(1),	REGFF
    sf		REGB,		REGIHV(2),	REGIHV(3)
    roti	REGWS(1),	REGWS(1),	21
    eqv		REGFF1,		REGWS(2),	REGWS(3)
    nand	REGFF,		REGWS(2),	REGWS(2)
    a		REGPC1,		REGPC1,		REGM(11)
    lqa		REGPC2,		IMADDRAC(62)
    a		REGWS(1),	REGWS(1),	REGWS(2)

    hbra	md5compress_loop_end2,		md5compress_loop2
    ai		REGLEN,		REGLEN,		-1

    selb	REGFF,		REGFF1,		REGFF,		REGWS(1)
    a		REGWS(3),	REGWS(3),	REGPC1
    a		REGWS(0),	REGWS(0),	REGFF
    ceq		REGPC3,		REGLEN,		REGLEN2
    roti	REGWS(0),	REGWS(0),	6
    eqv		REGFF1,		REGWS(1),	REGWS(2)
    nand	REGFF,		REGWS(1),	REGWS(1)
    a		REGPC2,		REGPC2,		REGM(2)
    lqa		REGPC1,		IMADDRAC(63)
    a		REGWS(0),	REGWS(0),	REGWS(1)

    sf		REGC,		REGIHV(1),	REGIHV(3)
    selb	REGFF,		REGFF1,		REGFF,		REGWS(0)
    a		REGWS(2),	REGWS(2),	REGPC2
    a		REGWS(3),	REGWS(3),	REGFF
    a		REGA,		REGIHV(0),	REGWS(0)
    roti	REGWS(3),	REGWS(3),	10
    eqv		REGFF1,		REGWS(0),	REGWS(1)
    nand	REGFF,		REGWS(0),	REGWS(0)
    a		REGPC1,		REGPC1,		REGM(9)
    a		REGWS(3),	REGWS(3),	REGWS(0)

    andc	REGREADY,	REGREADY,	REGPC3
    selb	REGFF,		REGFF1,		REGFF,		REGWS(3)
    a		REGWS(1),	REGWS(1),	REGPC1
    a		REGWS(2),	REGWS(2),	REGFF
    gb		REGPC2,		REGREADY
    roti	REGWS(2),	REGWS(2),	15
    eqv		REGFF1,		REGWS(3),	REGWS(0)
    nand	REGFF,		REGWS(3),	REGWS(3)
    a		REGWS(2),	REGWS(2),	REGWS(3)

    selb	REGMAXLEN,	REGMAXLEN,	REGLEN,		REGPC3
    selb	REGFF,		REGFF1,		REGFF,		REGWS(2)
    selb	REGASTART,	REGASTART,	REGA,		REGPC3
    a		REGWS(1),	REGWS(1),	REGFF
    a		REGC,		REGC,		REGWS(3)
    roti	REGWS(1),	REGWS(1),	21
    sf		REGB,		REGWS(2),	REGB
    sf		REGC,		REGWS(2),	REGC
    a		REGB,		REGB,		REGWS(3)

    sf		REGC,		REGWS(1),	REGC
    selb	REGBSTART,	REGBSTART,	REGB,		REGPC3
    and		REGC,		REGC,		REGHBMASK
    selb	REGCSTART,	REGCSTART,	REGC,		REGPC3
md5compress_loop_end2:
    brnz	REGPC2,		md5compress_loop2

    stqd	REGASTART,	0x00($8)
    stqd	REGBSTART,	0x10($8)
    stqd	REGCSTART,	0x20($8)
    stqd	REGMAXLEN,	0x30($8)

    hbra	afterstorejump2,	md5compress_loop2
    
    ai		$8,		$8,			16*8
    lqd		REGLEN,		0x30($8)
    clgt	REGPC1,		$9,			$8
    lqd		REGLEN2,	0x70($8)
    lqd		REGA,		0x00($8)
    lqd		REGB,		0x10($8)
    lqd		REGC,		0x20($8)

    or		REGMAXLEN,	REGLEN,		REGLEN
    clgt	REGREADY,	REGLEN,		REGLEN2
    or		REGASTART,	REGA,		REGA
    or		REGBSTART,	REGB,		REGB
    or		REGCSTART,	REGC,		REGC

afterstorejump2:
    brnz		REGPC1,		md5compress_loop2

    LOADREG(80)
    LOADREG(81)
    LOADREG(82)
    LOADREG(83)
    LOADREG(84)
    LOADREG(85)
    LOADREG(86)
    LOADREG(87)
    LOADREG(88)
    LOADREG(89)
    LOADREG(90)
    LOADREG(91)
    LOADREG(92)
    LOADREG(93)
    LOADREG(94)
    LOADREG(95)
    LOADREG(96)
    LOADREG(97)
    LOADREG(98)

    bi		$lr
    .size	reduce_trails,.-reduce_trails








.align 3
reduce_trails2:
// input
//	$3:	@ihv1
//	$4:	@ihv2
//	$5:	@msg1
//	$6:	@msg2
//	$7:	@a,b,len,rng,id,distpointmask,maxlen (ignored)
//	$8:	@buffer
//			blocks of:
//				vec_uint32 a1, b1, len1;
//				vec_uint32 a2, b2, len2;
//			it is assumed that len1 > len2
//				a1,b1 will be processed len1-len2 times
//				and then saved
//	$9:	@bufferend

    STOREREG(80)
    STOREREG(81)
    STOREREG(82)
    STOREREG(83)
    STOREREG(84)
    STOREREG(85)
    STOREREG(86)
    STOREREG(87)
    STOREREG(88)
    STOREREG(89)
    STOREREG(90)
    STOREREG(91)
    STOREREG(92)
    STOREREG(93)
    STOREREG(94)
    STOREREG(95)
    STOREREG(96)
    STOREREG(97)
    STOREREG(98)
    
// load a & b and other stuff
//		vec_uint32 a1, b1, c1, len1;
//		vec_uint32 a2, b2, c2, len2;

	lqd		REGLEN,		0x70($8)	
	lqd		REGLEN2,	0x30($8)
	lqd		REGA,		0x40($8)	
	lqd		REGB,		0x50($8)
	lqd		REGC,		0x60($8)

//	REGREADY is -1 for those not ready and 0 for those ready
//  when ready we copy the resp. parts from a1, b1, len to astart, bstart, maxlen
//  after the loop we store these
	
// load precalculated working states
    lqa		REGWS1(0),	 0 + workingstate1
    lqa		REGWS1(1),	16 + workingstate1
    lqa		REGWS1(2),	32 + workingstate1
    clgt	REGREADY,	REGLEN,		REGLEN2
    lqa		REGWS1(3),	48 + workingstate1
    or		REGASTART,	REGA,		REGA
    lqa		REGWS2(0),	 0 + workingstate2
    or		REGCSTART,	REGC,		REGC
    lqa		REGWS2(1),	16 + workingstate2
    or		REGMAXLEN,	REGLEN,		REGLEN
    lqa		REGWS2(2),	32 + workingstate2
    or		REGBSTART,	REGB,		REGB
    lqa		REGWS2(3),	48 + workingstate2
    lqd         REGHBMASK,      0xe0($7)
// load ihv1 & ihv2
    lqd		REGIHV1(0),	 0($3)
    lqd		REGIHV1(1),	16($3)
    lqd		REGIHV1(2),	32($3)
    lqd		REGIHV1(3),	48($3)
    lqd		REGIHV2(0),	 0($4)
    lqd		REGIHV2(1),	16($4)
    lqd		REGIHV2(2),	32($4)
    lqd		REGIHV2(3),	48($4)
// load msg1 & msg2
    lqd		REGM1(0),	0x00($5)
    lqd		REGM1(1),	0x10($5)
    lqd		REGM1(2),	0x20($5)
    lqd		REGM1(3),	0x30($5)
    lqd		REGM1(4),	0x40($5)
    lqd		REGM1(5),	0x50($5)
    lqd		REGM1(6),	0x60($5)
    lqd		REGM1(7),	0x70($5)
    lqd		REGM1(8),	0x80($5)
    lqd		REGM1(9),	0x90($5)
    lqd		REGM1(10),	0xa0($5)
    lqd		REGM1(11),	0xb0($5)
    lqd		REGM1(12),	0xc0($5)
    lqd		REGM2(0),	0x00($6)
    lqd		REGM2(1),	0x10($6)
    lqd		REGM2(2),	0x20($6)
    lqd		REGM2(3),	0x30($6)
    lqd		REGM2(4),	0x40($6)
    lqd		REGM2(5),	0x50($6)
    lqd		REGM2(6),	0x60($6)
    lqd		REGM2(7),	0x70($6)
    lqd		REGM2(8),	0x80($6)
    lqd		REGM2(9),	0x90($6)
    lqd		REGM2(10),	0xa0($6)
    lqd		REGM2(11),	0xb0($6)
    lqd		REGM2(12),	0xc0($6)


.align	3
md5compress_loop3:
/*** ROUND 1 ***/
    clgt	REGSELB,	REGA,		REGB
    lqa		REGPC2,		IMADDRAC(14)

    selb	REGWS(3),	REGWS1(3),	REGWS2(3),	REGSELB
    rotqbyi	REGM(14),	REGA,		0
    selb	REGWS(0),	REGWS1(0),	REGWS2(0),	REGSELB
    rotqbyi	REGM(13),	REGC,		0
    a		REGWS(3),	REGWS(3),	REGC
    lqa		REGPC3,		IMADDRAC(15)
    selb	REGWS(1),	REGWS1(1),	REGWS2(1),	REGSELB
    rotqbyi	REGM(15),	REGB,		0    
    roti	REGWS(3),	REGWS(3),	12    
    lqa		REGPC1,		IMADDRAC(16)
    selb	REGWS(2),	REGWS1(2),	REGWS2(2),	REGSELB
    a		REGPC2,		REGPC2,		REGM(14)
    a		REGWS(3),	REGWS(3),	REGWS(0)
    a		REGWS(2),	REGWS(2),	REGPC2
    selb	REGFF,		REGWS(1),	REGWS(0),	REGWS(3)
    a		REGPC3,		REGPC3,		REGM(15)
    a		REGWS(2),	REGWS(2),	REGFF
    a		REGWS(1),	REGWS(1),	REGPC3

    roti	REGWS(2),	REGWS(2),	17
    lnop
    selb	REGM(1),	REGM1(1),	REGM2(1),	REGSELB
    selb	REGM(6),	REGM1(6),	REGM2(6),	REGSELB
    a		REGPC1,		REGPC1,		REGM(1)
    lqa		REGPC2,		IMADDRAC(17)
    a		REGWS(2),	REGWS(2),	REGWS(3)
    selb	REGM(11),	REGM1(11),	REGM2(11),	REGSELB

    selb	REGFF,		REGWS(0),	REGWS(3),	REGWS(2)
    a		REGWS(0),	REGWS(0),	REGPC1
    a		REGWS(1),	REGWS(1),	REGFF
    selb	REGM(0),	REGM1(0),	REGM2(0),	REGSELB
    roti	REGWS(1),	REGWS(1),	22
    lnop
    a		REGPC2,		REGPC2,		REGM(6)
    lqa		REGPC3,		IMADDRAC(18)
    selb	REGM(5),	REGM1(5),	REGM2(5),	REGSELB
    selb	REGM(10),	REGM1(10),	REGM2(10),	REGSELB
    a		REGWS(1),	REGWS(1),	REGWS(2)
    selb	REGM(4),	REGM1(4),	REGM2(4),	REGSELB

/*** ROUND 2 ***/

    selb	REGFF,		REGWS(2),	REGWS(1),	REGWS(3)
    a		REGWS(3),	REGWS(3),	REGPC2
    a		REGWS(0),	REGWS(0),	REGFF
    selb	REGM(9),	REGM1(9),	REGM2(9),	REGSELB
    roti	REGWS(0),	REGWS(0),	5
    lnop
    a		REGPC3,		REGPC3,		REGM(11)
    lqa		REGPC1,		IMADDRAC(19)
    selb	REGM(3),	REGM1(3),	REGM2(3),	REGSELB
    selb	REGM(8),	REGM1(8),	REGM2(8),	REGSELB
    a		REGWS(0),	REGWS(0),	REGWS(1)
//    selb	REGM(13),	REGM1(13),	REGM2(13),	REGSELB

    selb	REGFF,		REGWS(1),	REGWS(0),	REGWS(2)
    a		REGWS(2),	REGWS(2),	REGPC3
    a		REGWS(3),	REGWS(3),	REGFF
    selb	REGM(2),	REGM1(2),	REGM2(2),	REGSELB
    roti	REGWS(3),	REGWS(3),	9
//    lnop
    a		REGPC1,		REGPC1,		REGM(0)
    lqa		REGPC2,		IMADDRAC(20)
    selb	REGM(7),	REGM1(7),	REGM2(7),	REGSELB
    selb	REGM(12),	REGM1(12),	REGM2(12),	REGSELB
    a		REGWS(3),	REGWS(3),	REGWS(0)
    selb	REGIHV(0),	REGIHV1(0),	REGIHV2(0),	REGSELB

    selb	REGFF,		REGWS(0),	REGWS(3),	REGWS(1)
    a		REGWS(1),	REGWS(1),	REGPC1
    a		REGWS(2),	REGWS(2),	REGFF
    selb	REGIHV(1),	REGIHV1(1),	REGIHV2(1),	REGSELB
    roti	REGWS(2),	REGWS(2),	14
    lnop
    a		REGPC2,		REGPC2,		REGM(5)
    lqa		REGPC3,		IMADDRAC(21)
    selb	REGIHV(2),	REGIHV1(2),	REGIHV2(2),	REGSELB
    selb	REGIHV(3),	REGIHV1(3),	REGIHV2(3),	REGSELB
    a		REGWS(2),	REGWS(2),	REGWS(3)

    selb	REGFF,		REGWS(3),	REGWS(2),	REGWS(0)
    a		REGWS(0),	REGWS(0),	REGPC2
    a		REGWS(1),	REGWS(1),	REGFF
    roti	REGWS(1),	REGWS(1),	20
    a		REGPC3,		REGPC3,		REGM(10)
    lqa		REGPC1,		IMADDRAC(22)
    a		REGWS(1),	REGWS(1),	REGWS(2)

    selb	REGFF,		REGWS(2),	REGWS(1),	REGWS(3)
    a		REGWS(3),	REGWS(3),	REGPC3
    a		REGWS(0),	REGWS(0),	REGFF
    roti	REGWS(0),	REGWS(0),	5
    a		REGPC1,		REGPC1,		REGM(15)
    lqa		REGPC2,		IMADDRAC(23)
    a		REGWS(0),	REGWS(0),	REGWS(1)

    selb	REGFF,		REGWS(1),	REGWS(0),	REGWS(2)
    a		REGWS(2),	REGWS(2),	REGPC1
    a		REGWS(3),	REGWS(3),	REGFF
    roti	REGWS(3),	REGWS(3),	9
    a		REGPC2,		REGPC2,		REGM(4)
    lqa		REGPC3,		IMADDRAC(24)
    a		REGWS(3),	REGWS(3),	REGWS(0)
    
    selb	REGFF,		REGWS(0),	REGWS(3),	REGWS(1)
    a		REGWS(1),	REGWS(1),	REGPC2
    a		REGWS(2),	REGWS(2),	REGFF
    roti	REGWS(2),	REGWS(2),	14
    a		REGPC3,		REGPC3,		REGM(9)
    lqa		REGPC1,		IMADDRAC(25)
    a		REGWS(2),	REGWS(2),	REGWS(3)

    selb	REGFF,		REGWS(3),	REGWS(2),	REGWS(0)
    a		REGWS(0),	REGWS(0),	REGPC3
    a		REGWS(1),	REGWS(1),	REGFF
    roti	REGWS(1),	REGWS(1),	20
    a		REGPC1,		REGPC1,		REGM(14)
    lqa		REGPC2,		IMADDRAC(26)
    a		REGWS(1),	REGWS(1),	REGWS(2)

    selb	REGFF,		REGWS(2),	REGWS(1),	REGWS(3)
    a		REGWS(3),	REGWS(3),	REGPC1
    a		REGWS(0),	REGWS(0),	REGFF
    roti	REGWS(0),	REGWS(0),	5
    a		REGPC2,		REGPC2,		REGM(3)
    lqa		REGPC3,		IMADDRAC(27)
    a		REGWS(0),	REGWS(0),	REGWS(1)

    selb	REGFF,		REGWS(1),	REGWS(0),	REGWS(2)
    a		REGWS(2),	REGWS(2),	REGPC2
    a		REGWS(3),	REGWS(3),	REGFF
    roti	REGWS(3),	REGWS(3),	9
    a		REGPC3,		REGPC3,		REGM(8)
    lqa		REGPC1,		IMADDRAC(28)
    a		REGWS(3),	REGWS(3),	REGWS(0)

    selb	REGFF,		REGWS(0),	REGWS(3),	REGWS(1)
    a		REGWS(1),	REGWS(1),	REGPC3
    a		REGWS(2),	REGWS(2),	REGFF
    roti	REGWS(2),	REGWS(2),	14
    a		REGPC1,		REGPC1,		REGM(13)
    lqa		REGPC2,		IMADDRAC(29)
    a		REGWS(2),	REGWS(2),	REGWS(3)

    selb	REGFF,		REGWS(3),	REGWS(2),	REGWS(0)
    a		REGWS(0),	REGWS(0),	REGPC1
    a		REGWS(1),	REGWS(1),	REGFF
    roti	REGWS(1),	REGWS(1),	20
    a		REGPC2,		REGPC2,		REGM(2)
    lqa		REGPC3,		IMADDRAC(30)
    a		REGWS(1),	REGWS(1),	REGWS(2)

    selb	REGFF,		REGWS(2),	REGWS(1),	REGWS(3)
    a		REGWS(3),	REGWS(3),	REGPC2
    a		REGWS(0),	REGWS(0),	REGFF
    roti	REGWS(0),	REGWS(0),	5
    a		REGPC3,		REGPC3,		REGM(7)
    lqa		REGPC1,		IMADDRAC(31)
    a		REGWS(0),	REGWS(0),	REGWS(1)

    selb	REGFF,		REGWS(1),	REGWS(0),	REGWS(2)
    a		REGWS(2),	REGWS(2),	REGPC3
    a		REGWS(3),	REGWS(3),	REGFF
    roti	REGWS(3),	REGWS(3),	9
    a		REGPC1,		REGPC1,		REGM(12)
    lqa		REGPC2,		IMADDRAC(32)
    a		REGWS(3),	REGWS(3),	REGWS(0)

    selb	REGFF,		REGWS(0),	REGWS(3),	REGWS(1)
    a		REGWS(1),	REGWS(1),	REGPC1
    a		REGWS(2),	REGWS(2),	REGFF
    roti	REGWS(2),	REGWS(2),	14
    a		REGPC2,		REGPC2,		REGM(5)
    lqa		REGPC3,		IMADDRAC(33)
    a		REGWS(2),	REGWS(2),	REGWS(3)

    selb	REGFF,		REGWS(3),	REGWS(2),	REGWS(0)
    a		REGWS(0),	REGWS(0),	REGPC2
    a		REGWS(1),	REGWS(1),	REGFF
    roti	REGWS(1),	REGWS(1),	20
    xor		REGFF,		REGWS(2),	REGWS(3)
    lqa		REGPC1,		IMADDRAC(34)
    a		REGWS(1),	REGWS(1),	REGWS(2)
    a		REGPC3,		REGPC3,		REGM(8)

/*** ROUND 3 ***/

    xor		REGFF,		REGFF,		REGWS(1)
    a		REGWS(3),	REGWS(3),	REGPC3
    a		REGWS(0),	REGWS(0),	REGFF
    xor		REGFF,		REGWS(1),	REGWS(2)
    roti	REGWS(0),	REGWS(0),	4
    a		REGPC1,		REGPC1,		REGM(11)
    lqa		REGPC2,		IMADDRAC(35)
    a		REGWS(0),	REGWS(0),	REGWS(1)


    xor		REGFF,		REGFF,		REGWS(0)
    a		REGWS(2),	REGWS(2),	REGPC1
    a		REGWS(3),	REGWS(3),	REGFF
    xor		REGFF,		REGWS(0),	REGWS(1)
    roti	REGWS(3),	REGWS(3),	11
    a		REGPC2,		REGPC2,		REGM(14)
    lqa		REGPC3,		IMADDRAC(36)
    a		REGWS(3),	REGWS(3),	REGWS(0)

    xor		REGFF,		REGFF,		REGWS(3)
    a		REGWS(1),	REGWS(1),	REGPC2
    a		REGWS(2),	REGWS(2),	REGFF
    xor		REGFF,		REGWS(3),	REGWS(0)
    roti	REGWS(2),	REGWS(2),	16
    a		REGPC3,		REGPC3,		REGM(1)
    lqa		REGPC1,		IMADDRAC(37)
    a		REGWS(2),	REGWS(2),	REGWS(3)

    xor		REGFF,		REGFF,		REGWS(2)
    a		REGWS(0),	REGWS(0),	REGPC3
    a		REGWS(1),	REGWS(1),	REGFF
    xor		REGFF,		REGWS(2),	REGWS(3)
    roti	REGWS(1),	REGWS(1),	23
    a		REGPC1,		REGPC1,		REGM(4)
    lqa		REGPC2,		IMADDRAC(38)
    a		REGWS(1),	REGWS(1),	REGWS(2)


    xor		REGFF,		REGFF,		REGWS(1)
    a		REGWS(3),	REGWS(3),	REGPC1
    a		REGWS(0),	REGWS(0),	REGFF
    xor		REGFF,		REGWS(1),	REGWS(2)
    roti	REGWS(0),	REGWS(0),	4
    a		REGPC2,		REGPC2,		REGM(7)
    lqa		REGPC3,		IMADDRAC(39)
    a		REGWS(0),	REGWS(0),	REGWS(1)

    xor		REGFF,		REGFF,		REGWS(0)
    a		REGWS(2),	REGWS(2),	REGPC2
    a		REGWS(3),	REGWS(3),	REGFF
    xor		REGFF,		REGWS(0),	REGWS(1)
    roti	REGWS(3),	REGWS(3),	11
    a		REGPC3,		REGPC3,		REGM(10)
    lqa		REGPC1,		IMADDRAC(40)
    a		REGWS(3),	REGWS(3),	REGWS(0)

    xor		REGFF,		REGFF,		REGWS(3)
    a		REGWS(1),	REGWS(1),	REGPC3
    a		REGWS(2),	REGWS(2),	REGFF
    xor		REGFF,		REGWS(3),	REGWS(0)
    roti	REGWS(2),	REGWS(2),	16
    a		REGPC1,		REGPC1,		REGM(13)
    lqa		REGPC2,		IMADDRAC(41)
    a		REGWS(2),	REGWS(2),	REGWS(3)

    xor		REGFF,		REGFF,		REGWS(2)
    a		REGWS(0),	REGWS(0),	REGPC1
    a		REGWS(1),	REGWS(1),	REGFF
    xor		REGFF,		REGWS(2),	REGWS(3)
    roti	REGWS(1),	REGWS(1),	23
    a		REGPC2,		REGPC2,		REGM(0)
    lqa		REGPC3,		IMADDRAC(42)
    a		REGWS(1),	REGWS(1),	REGWS(2)

    xor		REGFF,		REGFF,		REGWS(1)
    a		REGWS(3),	REGWS(3),	REGPC2
    a		REGWS(0),	REGWS(0),	REGFF
    xor		REGFF,		REGWS(1),	REGWS(2)
    roti	REGWS(0),	REGWS(0),	4
    a		REGPC3,		REGPC3,		REGM(3)
    lqa		REGPC1,		IMADDRAC(43)
    a		REGWS(0),	REGWS(0),	REGWS(1)

    xor		REGFF,		REGFF,		REGWS(0)
    a		REGWS(2),	REGWS(2),	REGPC3
    a		REGWS(3),	REGWS(3),	REGFF
    xor		REGFF,		REGWS(0),	REGWS(1)
    roti	REGWS(3),	REGWS(3),	11
    a		REGPC1,		REGPC1,		REGM(6)
    lqa		REGPC2,		IMADDRAC(44)
    a		REGWS(3),	REGWS(3),	REGWS(0)

    xor		REGFF,		REGFF,		REGWS(3)
    a		REGWS(1),	REGWS(1),	REGPC1
    a		REGWS(2),	REGWS(2),	REGFF
    xor		REGFF,		REGWS(3),	REGWS(0)
    roti	REGWS(2),	REGWS(2),	16
    a		REGPC2,		REGPC2,		REGM(9)
    lqa		REGPC3,		IMADDRAC(45)
    a		REGWS(2),	REGWS(2),	REGWS(3)

    xor		REGFF,		REGFF,		REGWS(2)
    a		REGWS(0),	REGWS(0),	REGPC2
    a		REGWS(1),	REGWS(1),	REGFF
    xor		REGFF,		REGWS(2),	REGWS(3)
    roti	REGWS(1),	REGWS(1),	23
    a		REGPC3,		REGPC3,		REGM(12)
    lqa		REGPC1,		IMADDRAC(46)
    a		REGWS(1),	REGWS(1),	REGWS(2)

    xor		REGFF,		REGFF,		REGWS(1)
    a		REGWS(3),	REGWS(3),	REGPC3
    a		REGWS(0),	REGWS(0),	REGFF
    xor		REGFF,		REGWS(1),	REGWS(2)
    roti	REGWS(0),	REGWS(0),	4
    a		REGPC1,		REGPC1,		REGM(15)
    lqa		REGPC2,		IMADDRAC(47)
    a		REGWS(0),	REGWS(0),	REGWS(1)

    xor		REGFF,		REGFF,		REGWS(0)
    a		REGWS(2),	REGWS(2),	REGPC1
    a		REGWS(3),	REGWS(3),	REGFF
    xor		REGFF,		REGWS(0),	REGWS(1)
    roti	REGWS(3),	REGWS(3),	11
    a		REGPC2,		REGPC2,		REGM(2)
    lqa		REGPC3,		IMADDRAC(48)
    a		REGWS(3),	REGWS(3),	REGWS(0)

    xor		REGFF,		REGFF,		REGWS(3)
    a		REGWS(1),	REGWS(1),	REGPC2
    a		REGWS(2),	REGWS(2),	REGFF
    xor		REGFF,		REGWS(3),	REGWS(0)
    roti	REGWS(2),	REGWS(2),	16
    a		REGPC3,		REGPC3,		REGM(0)
    lqa		REGPC1,		IMADDRAC(49)
    a		REGWS(2),	REGWS(2),	REGWS(3)

    xor		REGFF,		REGFF,		REGWS(2)
    a		REGWS(0),	REGWS(0),	REGPC3
    a		REGWS(1),	REGWS(1),	REGFF
    eqv		REGFF1,		REGWS(2),	REGWS(3)
    roti	REGWS(1),	REGWS(1),	23
    a		REGPC1,		REGPC1,		REGM(7)
    lqa		REGPC2,		IMADDRAC(50)
    nand	REGFF,		REGWS(2),	REGWS(2)
    a		REGWS(1),	REGWS(1),	REGWS(2)

/*** ROUND 4 ***/

    selb	REGFF,		REGFF1,		REGFF,		REGWS(1)
    a		REGWS(3),	REGWS(3),	REGPC1
    a		REGWS(0),	REGWS(0),	REGFF
    roti	REGWS(0),	REGWS(0),	6
    eqv		REGFF1,		REGWS(1),	REGWS(2)
    nand	REGFF,		REGWS(1),	REGWS(1)
    a		REGPC2,		REGPC2,		REGM(14)
    lqa		REGPC3,		IMADDRAC(51)
    a		REGWS(0),	REGWS(0),	REGWS(1)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(0)
    a		REGWS(2),	REGWS(2),	REGPC2
    a		REGWS(3),	REGWS(3),	REGFF
    roti	REGWS(3),	REGWS(3),	10
    eqv		REGFF1,		REGWS(0),	REGWS(1)
    nand	REGFF,		REGWS(0),	REGWS(0)
    lnop
    a		REGPC3,		REGPC3,		REGM(5)
    lqa		REGPC1,		IMADDRAC(52)
    a		REGWS(3),	REGWS(3),	REGWS(0)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(3)
    a		REGWS(1),	REGWS(1),	REGPC3
    a		REGWS(2),	REGWS(2),	REGFF
    roti	REGWS(2),	REGWS(2),	15
    eqv		REGFF1,		REGWS(3),	REGWS(0)
    nand	REGFF,		REGWS(3),	REGWS(3)
    lnop
    a		REGPC1,		REGPC1,		REGM(12)
    lqa		REGPC2,		IMADDRAC(53)
    a		REGWS(2),	REGWS(2),	REGWS(3)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(2)
    a		REGWS(0),	REGWS(0),	REGPC1
    a		REGWS(1),	REGWS(1),	REGFF
    roti	REGWS(1),	REGWS(1),	21
    eqv		REGFF1,		REGWS(2),	REGWS(3)
    nand	REGFF,		REGWS(2),	REGWS(2)
    lnop
    a		REGPC2,		REGPC2,		REGM(3)
    lqa		REGPC3,		IMADDRAC(54)
    a		REGWS(1),	REGWS(1),	REGWS(2)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(1)
    a		REGWS(3),	REGWS(3),	REGPC2
    a		REGWS(0),	REGWS(0),	REGFF
    roti	REGWS(0),	REGWS(0),	6
    eqv		REGFF1,		REGWS(1),	REGWS(2)
    nand	REGFF,		REGWS(1),	REGWS(1)
    lnop
    a		REGPC3,		REGPC3,		REGM(10)
    lqa		REGPC1,		IMADDRAC(55)
    a		REGWS(0),	REGWS(0),	REGWS(1)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(0)
    a		REGWS(2),	REGWS(2),	REGPC3
    a		REGWS(3),	REGWS(3),	REGFF
    roti	REGWS(3),	REGWS(3),	10
    eqv		REGFF1,		REGWS(0),	REGWS(1)
    nand	REGFF,		REGWS(0),	REGWS(0)
    lnop
    a		REGPC1,		REGPC1,		REGM(1)
    lqa		REGPC2,		IMADDRAC(56)
    a		REGWS(3),	REGWS(3),	REGWS(0)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(3)
    a		REGWS(1),	REGWS(1),	REGPC1
    a		REGWS(2),	REGWS(2),	REGFF
    roti	REGWS(2),	REGWS(2),	15
    eqv		REGFF1,		REGWS(3),	REGWS(0)
    nand	REGFF,		REGWS(3),	REGWS(3)
    lnop
    a		REGPC2,		REGPC2,		REGM(8)
    lqa		REGPC3,		IMADDRAC(57)
    a		REGWS(2),	REGWS(2),	REGWS(3)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(2)
    a		REGWS(0),	REGWS(0),	REGPC2
    a		REGWS(1),	REGWS(1),	REGFF
    roti	REGWS(1),	REGWS(1),	21
    eqv		REGFF1,		REGWS(2),	REGWS(3)
    nand	REGFF,		REGWS(2),	REGWS(2)
    lnop
    a		REGPC3,		REGPC3,		REGM(15)
    lqa		REGPC1,		IMADDRAC(58)
    a		REGWS(1),	REGWS(1),	REGWS(2)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(1)
    a		REGWS(3),	REGWS(3),	REGPC3
    a		REGWS(0),	REGWS(0),	REGFF
    roti	REGWS(0),	REGWS(0),	6
    eqv		REGFF1,		REGWS(1),	REGWS(2)
    nand	REGFF,		REGWS(1),	REGWS(1)
    lnop
    a		REGPC1,		REGPC1,		REGM(6)
    lqa		REGPC2,		IMADDRAC(59)
    a		REGWS(0),	REGWS(0),	REGWS(1)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(0)
    a		REGWS(2),	REGWS(2),	REGPC1
    a		REGWS(3),	REGWS(3),	REGFF
    roti	REGWS(3),	REGWS(3),	10
    eqv		REGFF1,		REGWS(0),	REGWS(1)
    nand	REGFF,		REGWS(0),	REGWS(0)
    lnop
    a		REGPC2,		REGPC2,		REGM(13)
    lqa		REGPC3,		IMADDRAC(60)
    a		REGWS(3),	REGWS(3),	REGWS(0)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(3)
    a		REGWS(1),	REGWS(1),	REGPC2
    a		REGWS(2),	REGWS(2),	REGFF
    roti	REGWS(2),	REGWS(2),	15
    eqv		REGFF1,		REGWS(3),	REGWS(0)
    nand	REGFF,		REGWS(3),	REGWS(3)
    lnop
    a		REGPC3,		REGPC3,		REGM(4)
    lqa		REGPC1,		IMADDRAC(61)
    a		REGWS(2),	REGWS(2),	REGWS(3)
    
    selb	REGFF,		REGFF1,		REGFF,		REGWS(2)
    a		REGWS(0),	REGWS(0),	REGPC3
    a		REGWS(1),	REGWS(1),	REGFF
    sf		REGB,		REGIHV(2),	REGIHV(3)
    roti	REGWS(1),	REGWS(1),	21
    eqv		REGFF1,		REGWS(2),	REGWS(3)
    nand	REGFF,		REGWS(2),	REGWS(2)
    a		REGPC1,		REGPC1,		REGM(11)
    lqa		REGPC2,		IMADDRAC(62)
    a		REGWS(1),	REGWS(1),	REGWS(2)

    hbra	md5compress_loop_end3,		md5compress_loop3
    ai		REGLEN,		REGLEN,		-1

    selb	REGFF,		REGFF1,		REGFF,		REGWS(1)
    a		REGWS(3),	REGWS(3),	REGPC1
    a		REGWS(0),	REGWS(0),	REGFF
    ceq		REGPC3,		REGLEN,		REGLEN2
    roti	REGWS(0),	REGWS(0),	6
    eqv		REGFF1,		REGWS(1),	REGWS(2)
    nand	REGFF,		REGWS(1),	REGWS(1)
    a		REGPC2,		REGPC2,		REGM(2)
    lqa		REGPC1,		IMADDRAC(63)
    a		REGWS(0),	REGWS(0),	REGWS(1)

    sf		REGC,		REGIHV(1),	REGIHV(3)
    selb	REGFF,		REGFF1,		REGFF,		REGWS(0)
    a		REGWS(2),	REGWS(2),	REGPC2
    a		REGWS(3),	REGWS(3),	REGFF
    a		REGA,		REGIHV(0),	REGWS(0)
    roti	REGWS(3),	REGWS(3),	10
    eqv		REGFF1,		REGWS(0),	REGWS(1)
    nand	REGFF,		REGWS(0),	REGWS(0)
    a		REGPC1,		REGPC1,		REGM(9)
    a		REGWS(3),	REGWS(3),	REGWS(0)

    andc	REGREADY,	REGREADY,	REGPC3
    selb	REGFF,		REGFF1,		REGFF,		REGWS(3)
    a		REGWS(1),	REGWS(1),	REGPC1
    a		REGWS(2),	REGWS(2),	REGFF
    gb		REGPC2,		REGREADY
    roti	REGWS(2),	REGWS(2),	15
    eqv		REGFF1,		REGWS(3),	REGWS(0)
    nand	REGFF,		REGWS(3),	REGWS(3)
    a		REGWS(2),	REGWS(2),	REGWS(3)

    selb	REGMAXLEN,	REGMAXLEN,	REGLEN,		REGPC3
    selb	REGFF,		REGFF1,		REGFF,		REGWS(2)
    selb	REGASTART,	REGASTART,	REGA,		REGPC3
    a		REGWS(1),	REGWS(1),	REGFF
    a		REGC,		REGC,		REGWS(3)
    roti	REGWS(1),	REGWS(1),	21
    sf		REGB,		REGWS(2),	REGB
    sf		REGC,		REGWS(2),	REGC
    a		REGB,		REGB,		REGWS(3)

    sf		REGC,		REGWS(1),	REGC
    selb	REGBSTART,	REGBSTART,	REGB,		REGPC3
    and		REGC,		REGC,		REGHBMASK
    selb	REGCSTART,	REGCSTART,	REGC,		REGPC3
md5compress_loop_end3:
    brnz	REGPC2,		md5compress_loop3

    stqd	REGASTART,	0x40($8)
    stqd	REGBSTART,	0x50($8)
    stqd	REGCSTART,	0x60($8)
    stqd	REGMAXLEN,	0x70($8)

    hbra	afterstorejump3,	md5compress_loop3
    
    ai		$8,			$8,			16*8
    lqd		REGLEN,		0x70($8)
    clgt	REGPC1,		$9,			$8
    lqd		REGLEN2,	0x30($8)
    lqd		REGA,		0x40($8)
    lqd		REGB,		0x50($8)
    lqd		REGC,		0x60($8)

    or		REGMAXLEN,	REGLEN,		REGLEN
    clgt	REGREADY,	REGLEN,		REGLEN2
    or		REGASTART,	REGA,		REGA
    or		REGBSTART,	REGB,		REGB
    or		REGCSTART,	REGC,		REGC

afterstorejump3:
    brnz		REGPC1,		md5compress_loop3

    LOADREG(80)
    LOADREG(81)
    LOADREG(82)
    LOADREG(83)
    LOADREG(84)
    LOADREG(85)
    LOADREG(86)
    LOADREG(87)
    LOADREG(88)
    LOADREG(89)
    LOADREG(90)
    LOADREG(91)
    LOADREG(92)
    LOADREG(93)
    LOADREG(94)
    LOADREG(95)
    LOADREG(96)
    LOADREG(97)
    LOADREG(98)

    bi		$lr
    .size	reduce_trails2,.-reduce_trails2








