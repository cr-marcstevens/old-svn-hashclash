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
    .global	find_collmod
    .type	find_collmod,@function

#define REGIHV(i)	$(i+10)
#define	REGIHV1(i)	$(i+14)
#define REGIHV2(i)	$(i+18)
#define	REGWS(i)	$(i+22)
#define REGWS1(i)	$(i+26)
#define REGWS2(i)	$(i+30)
#define	REGM(i)		$(i+34)
#define REGM1(i)	$(i+47)
#define REGM2(i)	$(i+60)
#define REGASTART	$73
#define REGBSTART	$74
#define REGCSTART	$75
#define REGA		$76
#define REGB		$77
#define REGC		$78
#define REGLEN		$79
#define REGASTART2	$80
#define REGBSTART2	$81
#define REGCSTART2	$82
#define REGA2		$83
#define REGB2		$84
#define REGC2		$85
#define REGLEN2		$86
#define REGMAXLEN	$87
#define REGHBMASK	$88
#define	IMADDRAC(i)	i*16+md5_acvec
#define	REGFF		$89
#define	REGFF1		$90
#define	REGPC1		$91
#define	REGPC2		$92
#define	REGPC3		$93
#define REGSELB		$94

#define	REGWSI(i)	$(i+95)
#define	REGMI(i)	$(i+99)
#define REGFFI		$112
#define REGFF1I		$113
#define REGPC1I		$114
#define REGPC2I		$115
#define REGPC3I		$116
#define REGSELBI	$117
#define REGIHVI(i)	$(i+118)

#define REGREADY	$122

// using registers: $0 - $122

#define STOREREG(i)	stqa	$(i),	(i*16)+regstore
#define LOADREG(i)	lqa		$(i),	(i*16)+regstore



.align 3
find_collmod:
// input
//	$3:	@ihv1
//	$4:	@ihv2mod
//	$5:	@msg1
//	$6:	@msg2
//	$7:	@a,b,len,rng,id,distpointmask,maxlen (ignored)
//	$8:	@buffer
//			blocks of:
//				vec_uint32 a1, b1, len1;
//				vec_uint32 a2, b2, len2;
//			it is assumed that len1 = len2
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
    STOREREG(99)
    STOREREG(100)
    STOREREG(101)
    STOREREG(102)
    STOREREG(103)
    STOREREG(104)
    STOREREG(105)
    STOREREG(106)
    STOREREG(107)
    STOREREG(108)
    STOREREG(109)
    STOREREG(110)
    STOREREG(111)
    STOREREG(112)
    STOREREG(113)
    STOREREG(114)
    STOREREG(115)
    STOREREG(116)
    STOREREG(117)
    STOREREG(118)
    STOREREG(119)
    STOREREG(120)
    STOREREG(121)
    STOREREG(122)
    
// load a & b and other stuff
//				vec_uint32 a1, b1, len1;
//				vec_uint32 a2, b2, len2;

	lqd		REGASTART,	0x00($8)
	lqd		REGASTART2,	0x40($8)
	lqd		REGBSTART,	0x10($8)
	lqd		REGBSTART2,	0x50($8)
	lqd		REGCSTART,	0x20($8)
	lqd		REGCSTART2,	0x60($8)
	lqd		REGLEN,		0x30($8)
	lqd		REGLEN2,	0x70($8)
	
	
	

        
//	REGREADY is -1 for those not ready and 0 for those ready
//  when ready we copy the resp. parts from a1, b1, len to astart, bstart, maxlen
//  after the loop we store these
	
// load precalculated working states
    ceq		REGPC1,		REGASTART,	REGASTART2
    lqa		REGWS1(0),	 0 + workingstate1

    ceq		REGPC2,		REGBSTART,	REGBSTART2
    lqa		REGWS1(1),	16 + workingstate1

    ceq		REGPC3,		REGCSTART,	REGCSTART2
    lqa		REGWS1(2),	32 + workingstate1

    and		REGPC1,		REGPC1,		REGPC2
    lqa		REGWS1(3),	48 + workingstate1

    ceqi	REGPC2,		REGLEN,		0
    lqa		REGWS2(0),	 0 + workingstate2

    and		REGPC1,		REGPC1,		REGPC3
    lqa		REGWS2(1),	16 + workingstate2

    lqa		REGWS2(2),	32 + workingstate2
    lqa		REGWS2(3),	48 + workingstate2

// load ihv1 & ihv2
    or		REGPC1,		REGPC1,		REGPC2
    lqd		REGIHV1(0),	 0($3)

    lqd		REGIHV1(1),	16($3)
    lqd		REGIHV1(2),	32($3)

    nand	REGREADY,	REGPC1,		REGPC1
    lqd		REGIHV1(3),	48($3)
    lqd		REGIHV2(0),	 0($4)
    lqd		REGIHV2(1),	16($4)
    lqd		REGIHV2(2),	32($4)
    lqd		REGIHV2(3),	48($4)

    lqd		REGHBMASK,	0xe0($7)
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
md5compress_loop4mod:

/*** ROUND 1 ***/
/*** ROUND 1 ***/
    clgt	REGSELB,	REGASTART,	REGBSTART
    lqa		REGPC2,		IMADDRAC(14)
    clgt	REGSELBI,	REGASTART2,	REGBSTART2
    lqa		REGPC2I,		IMADDRAC(14)
    selb	REGWS(3),	REGWS1(3),	REGWS2(3),	REGSELB
    selb	REGWSI(3),	REGWS1(3),	REGWS2(3),	REGSELBI
    selb	REGWS(0),	REGWS1(0),	REGWS2(0),	REGSELB
    selb	REGWSI(0),	REGWS1(0),	REGWS2(0),	REGSELBI
    a		REGWS(3),	REGWS(3),	REGCSTART
    lqa		REGPC3,		IMADDRAC(15)
    a		REGWSI(3),	REGWSI(3),	REGCSTART2
    lqa		REGPC3I,		IMADDRAC(15)
    selb	REGWS(1),	REGWS1(1),	REGWS2(1),	REGSELB
    selb	REGWSI(1),	REGWS1(1),	REGWS2(1),	REGSELBI
    roti	REGWS(3),	REGWS(3),	12    
    lqa		REGPC1,		IMADDRAC(16)
    roti	REGWSI(3),	REGWSI(3),	12    
    lqa		REGPC1I,		IMADDRAC(16)
    selb	REGWS(2),	REGWS1(2),	REGWS2(2),	REGSELB
    selb	REGWSI(2),	REGWS1(2),	REGWS2(2),	REGSELBI
    a		REGPC2,		REGPC2,		REGASTART
    a		REGPC2I,		REGPC2I,		REGASTART2
    a		REGWS(3),	REGWS(3),	REGWS(0)
    a		REGWSI(3),	REGWSI(3),	REGWSI(0)
    a		REGWS(2),	REGWS(2),	REGPC2
    a		REGWSI(2),	REGWSI(2),	REGPC2I
    selb	REGFF,		REGWS(1),	REGWS(0),	REGWS(3)
    selb	REGFFI,		REGWSI(1),	REGWSI(0),	REGWSI(3)
    a		REGPC3,		REGPC3,		REGBSTART
    a		REGPC3I,	REGPC3I,		REGBSTART2
    a		REGWS(2),	REGWS(2),	REGFF
    a		REGWSI(2),	REGWSI(2),	REGFFI
    a		REGWS(1),	REGWS(1),	REGPC3
    a		REGWSI(1),	REGWSI(1),	REGPC3I


    roti	REGWS(2),	REGWS(2),	17
    roti	REGWSI(2),	REGWSI(2),	17
    selb	REGM(1),	REGM1(1),	REGM2(1),	REGSELB
    selb	REGMI(1),	REGM1(1),	REGM2(1),	REGSELBI
    selb	REGM(6),	REGM1(6),	REGM2(6),	REGSELB
    selb	REGMI(6),	REGM1(6),	REGM2(6),	REGSELBI
    a		REGPC1,		REGPC1,		REGM(1)
    lqa		REGPC2,		IMADDRAC(17)
    a		REGPC1I,		REGPC1I,		REGMI(1)
    lqa		REGPC2I,		IMADDRAC(17)
    a		REGWS(2),	REGWS(2),	REGWS(3)
    a		REGWSI(2),	REGWSI(2),	REGWSI(3)
    selb	REGM(11),	REGM1(11),	REGM2(11),	REGSELB
    selb	REGMI(11),	REGM1(11),	REGM2(11),	REGSELBI


    selb	REGFF,		REGWS(0),	REGWS(3),	REGWS(2)
    selb	REGFFI,		REGWSI(0),	REGWSI(3),	REGWSI(2)
    a		REGWS(0),	REGWS(0),	REGPC1
    a		REGWSI(0),	REGWSI(0),	REGPC1I
    a		REGWS(1),	REGWS(1),	REGFF
    a		REGWSI(1),	REGWSI(1),	REGFFI
    selb	REGM(0),	REGM1(0),	REGM2(0),	REGSELB
    selb	REGMI(0),	REGM1(0),	REGM2(0),	REGSELBI
    roti	REGWS(1),	REGWS(1),	22
    roti	REGWSI(1),	REGWSI(1),	22
    a		REGPC2,		REGPC2,		REGM(6)
    lqa		REGPC3,		IMADDRAC(18)
    a		REGPC2I,		REGPC2I,		REGMI(6)
    lqa		REGPC3I,		IMADDRAC(18)
    selb	REGM(5),	REGM1(5),	REGM2(5),	REGSELB
    selb	REGMI(5),	REGM1(5),	REGM2(5),	REGSELBI
    selb	REGM(10),	REGM1(10),	REGM2(10),	REGSELB
    selb	REGMI(10),	REGM1(10),	REGM2(10),	REGSELBI
    a		REGWS(1),	REGWS(1),	REGWS(2)
    a		REGWSI(1),	REGWSI(1),	REGWSI(2)
    selb	REGM(4),	REGM1(4),	REGM2(4),	REGSELB
    selb	REGMI(4),	REGM1(4),	REGM2(4),	REGSELBI


/*** ROUND 2 ***/
/*** ROUND 2 ***/


    selb	REGFF,		REGWS(2),	REGWS(1),	REGWS(3)
    selb	REGFFI,		REGWSI(2),	REGWSI(1),	REGWSI(3)
    a		REGWS(3),	REGWS(3),	REGPC2
    a		REGWSI(3),	REGWSI(3),	REGPC2I
    a		REGWS(0),	REGWS(0),	REGFF
    a		REGWSI(0),	REGWSI(0),	REGFFI
    selb	REGM(9),	REGM1(9),	REGM2(9),	REGSELB
    selb	REGMI(9),	REGM1(9),	REGM2(9),	REGSELBI
    roti	REGWS(0),	REGWS(0),	5
    roti	REGWSI(0),	REGWSI(0),	5
    a		REGPC3,		REGPC3,		REGM(11)
    lqa		REGPC1,		IMADDRAC(19)
    a		REGPC3I,		REGPC3I,		REGMI(11)
    lqa		REGPC1I,		IMADDRAC(19)
    selb	REGM(3),	REGM1(3),	REGM2(3),	REGSELB
    selb	REGMI(3),	REGM1(3),	REGM2(3),	REGSELBI
    selb	REGM(8),	REGM1(8),	REGM2(8),	REGSELB
    selb	REGMI(8),	REGM1(8),	REGM2(8),	REGSELBI
    a		REGWS(0),	REGWS(0),	REGWS(1)
    a		REGWSI(0),	REGWSI(0),	REGWSI(1)


    selb	REGFF,		REGWS(1),	REGWS(0),	REGWS(2)
    selb	REGFFI,		REGWSI(1),	REGWSI(0),	REGWSI(2)
    a		REGWS(2),	REGWS(2),	REGPC3
    a		REGWSI(2),	REGWSI(2),	REGPC3I
    a		REGWS(3),	REGWS(3),	REGFF
    a		REGWSI(3),	REGWSI(3),	REGFFI
    selb	REGM(2),	REGM1(2),	REGM2(2),	REGSELB
    selb	REGMI(2),	REGM1(2),	REGM2(2),	REGSELBI
    roti	REGWS(3),	REGWS(3),	9
    roti	REGWSI(3),	REGWSI(3),	9


    a		REGPC1,		REGPC1,		REGM(0)
    lqa		REGPC2,		IMADDRAC(20)
    a		REGPC1I,		REGPC1I,		REGMI(0)
    lqa		REGPC2I,		IMADDRAC(20)
    selb	REGM(7),	REGM1(7),	REGM2(7),	REGSELB
    selb	REGMI(7),	REGM1(7),	REGM2(7),	REGSELBI
    selb	REGM(12),	REGM1(12),	REGM2(12),	REGSELB
    selb	REGMI(12),	REGM1(12),	REGM2(12),	REGSELBI
    a		REGWS(3),	REGWS(3),	REGWS(0)
    a		REGWSI(3),	REGWSI(3),	REGWSI(0)
    selb	REGIHV(0),	REGIHV1(0),	REGIHV2(0),	REGSELB
    selb	REGIHVI(0),	REGIHV1(0),	REGIHV2(0),	REGSELBI


    selb	REGFF,		REGWS(0),	REGWS(3),	REGWS(1)
    selb	REGFFI,		REGWSI(0),	REGWSI(3),	REGWSI(1)
    a		REGWS(1),	REGWS(1),	REGPC1
    a		REGWSI(1),	REGWSI(1),	REGPC1I
    a		REGWS(2),	REGWS(2),	REGFF
    a		REGWSI(2),	REGWSI(2),	REGFFI
    selb	REGIHV(1),	REGIHV1(1),	REGIHV2(1),	REGSELB
    selb	REGIHVI(1),	REGIHV1(1),	REGIHV2(1),	REGSELBI
    roti	REGWS(2),	REGWS(2),	14
    roti	REGWSI(2),	REGWSI(2),	14
    a		REGPC2,		REGPC2,		REGM(5)
    lqa		REGPC3,		IMADDRAC(21)
    a		REGPC2I,		REGPC2I,		REGMI(5)
    lqa		REGPC3I,		IMADDRAC(21)
    selb	REGIHV(2),	REGIHV1(2),	REGIHV2(2),	REGSELB
    selb	REGIHVI(2),	REGIHV1(2),	REGIHV2(2),	REGSELBI
    selb	REGIHV(3),	REGIHV1(3),	REGIHV2(3),	REGSELB
    selb	REGIHVI(3),	REGIHV1(3),	REGIHV2(3),	REGSELBI
    a		REGWS(2),	REGWS(2),	REGWS(3)
    a		REGWSI(2),	REGWSI(2),	REGWSI(3)


    selb	REGFF,		REGWS(3),	REGWS(2),	REGWS(0)
    selb	REGFFI,		REGWSI(3),	REGWSI(2),	REGWSI(0)
    a		REGWS(0),	REGWS(0),	REGPC2
    a		REGWSI(0),	REGWSI(0),	REGPC2I
    a		REGWS(1),	REGWS(1),	REGFF
    a		REGWSI(1),	REGWSI(1),	REGFFI
    roti	REGWS(1),	REGWS(1),	20
    roti	REGWSI(1),	REGWSI(1),	20
    a		REGPC3,		REGPC3,		REGM(10)
    lqa		REGPC1,		IMADDRAC(22)
    a		REGPC3I,		REGPC3I,		REGMI(10)
    lqa		REGPC1I,		IMADDRAC(22)
    a		REGWS(1),	REGWS(1),	REGWS(2)
    a		REGWSI(1),	REGWSI(1),	REGWSI(2)


    selb	REGFF,		REGWS(2),	REGWS(1),	REGWS(3)
    selb	REGFFI,		REGWSI(2),	REGWSI(1),	REGWSI(3)
    a		REGWS(3),	REGWS(3),	REGPC3
    a		REGWSI(3),	REGWSI(3),	REGPC3I
    a		REGWS(0),	REGWS(0),	REGFF
    a		REGWSI(0),	REGWSI(0),	REGFFI
    roti	REGWS(0),	REGWS(0),	5
    roti	REGWSI(0),	REGWSI(0),	5
    a		REGPC1,		REGPC1,		REGBSTART
    lqa		REGPC2,		IMADDRAC(23)
    a		REGPC1I,		REGPC1I,		REGBSTART2
    lqa		REGPC2I,		IMADDRAC(23)
    a		REGWS(0),	REGWS(0),	REGWS(1)
    a		REGWSI(0),	REGWSI(0),	REGWSI(1)


    selb	REGFF,		REGWS(1),	REGWS(0),	REGWS(2)
    selb	REGFFI,		REGWSI(1),	REGWSI(0),	REGWSI(2)
    a		REGWS(2),	REGWS(2),	REGPC1
    a		REGWSI(2),	REGWSI(2),	REGPC1I
    a		REGWS(3),	REGWS(3),	REGFF
    a		REGWSI(3),	REGWSI(3),	REGFFI
    roti	REGWS(3),	REGWS(3),	9
    roti	REGWSI(3),	REGWSI(3),	9
    a		REGPC2,		REGPC2,		REGM(4)
    lqa		REGPC3,		IMADDRAC(24)
    a		REGPC2I,		REGPC2I,		REGMI(4)
    lqa		REGPC3I,		IMADDRAC(24)
    a		REGWS(3),	REGWS(3),	REGWS(0)
    a		REGWSI(3),	REGWSI(3),	REGWSI(0)
    
    
    selb	REGFF,		REGWS(0),	REGWS(3),	REGWS(1)
    selb	REGFFI,		REGWSI(0),	REGWSI(3),	REGWSI(1)
    a		REGWS(1),	REGWS(1),	REGPC2
    a		REGWSI(1),	REGWSI(1),	REGPC2I
    a		REGWS(2),	REGWS(2),	REGFF
    a		REGWSI(2),	REGWSI(2),	REGFFI
    roti	REGWS(2),	REGWS(2),	14
    roti	REGWSI(2),	REGWSI(2),	14
    a		REGPC3,		REGPC3,		REGM(9)
    lqa		REGPC1,		IMADDRAC(25)
    a		REGPC3I,		REGPC3I,		REGMI(9)
    lqa		REGPC1I,		IMADDRAC(25)
    a		REGWS(2),	REGWS(2),	REGWS(3)
    a		REGWSI(2),	REGWSI(2),	REGWSI(3)


    selb	REGFF,		REGWS(3),	REGWS(2),	REGWS(0)
    selb	REGFFI,		REGWSI(3),	REGWSI(2),	REGWSI(0)
    a		REGWS(0),	REGWS(0),	REGPC3
    a		REGWSI(0),	REGWSI(0),	REGPC3I
    a		REGWS(1),	REGWS(1),	REGFF
    a		REGWSI(1),	REGWSI(1),	REGFFI
    roti	REGWS(1),	REGWS(1),	20
    roti	REGWSI(1),	REGWSI(1),	20
    a		REGPC1,		REGPC1,		REGASTART
    lqa		REGPC2,		IMADDRAC(26)
    a		REGPC1I,		REGPC1I,		REGASTART2
    lqa		REGPC2I,		IMADDRAC(26)
    a		REGWS(1),	REGWS(1),	REGWS(2)
    a		REGWSI(1),	REGWSI(1),	REGWSI(2)


    selb	REGFF,		REGWS(2),	REGWS(1),	REGWS(3)
    selb	REGFFI,		REGWSI(2),	REGWSI(1),	REGWSI(3)
    a		REGWS(3),	REGWS(3),	REGPC1
    a		REGWSI(3),	REGWSI(3),	REGPC1I
    a		REGWS(0),	REGWS(0),	REGFF
    a		REGWSI(0),	REGWSI(0),	REGFFI
    roti	REGWS(0),	REGWS(0),	5
    roti	REGWSI(0),	REGWSI(0),	5
    a		REGPC2,		REGPC2,		REGM(3)
    lqa		REGPC3,		IMADDRAC(27)
    a		REGPC2I,		REGPC2I,		REGMI(3)
    lqa		REGPC3I,		IMADDRAC(27)
    a		REGWS(0),	REGWS(0),	REGWS(1)
    a		REGWSI(0),	REGWSI(0),	REGWSI(1)


    selb	REGFF,		REGWS(1),	REGWS(0),	REGWS(2)
    selb	REGFFI,		REGWSI(1),	REGWSI(0),	REGWSI(2)
    a		REGWS(2),	REGWS(2),	REGPC2
    a		REGWSI(2),	REGWSI(2),	REGPC2I
    a		REGWS(3),	REGWS(3),	REGFF
    a		REGWSI(3),	REGWSI(3),	REGFFI
    roti	REGWS(3),	REGWS(3),	9
    roti	REGWSI(3),	REGWSI(3),	9
    a		REGPC3,		REGPC3,		REGM(8)
    lqa		REGPC1,		IMADDRAC(28)
    a		REGPC3I,		REGPC3I,		REGMI(8)
    lqa		REGPC1I,		IMADDRAC(28)
    a		REGWS(3),	REGWS(3),	REGWS(0)
    a		REGWSI(3),	REGWSI(3),	REGWSI(0)


    selb	REGFF,		REGWS(0),	REGWS(3),	REGWS(1)
    selb	REGFFI,		REGWSI(0),	REGWSI(3),	REGWSI(1)
    a		REGWS(1),	REGWS(1),	REGPC3
    a		REGWSI(1),	REGWSI(1),	REGPC3I
    a		REGWS(2),	REGWS(2),	REGFF
    a		REGWSI(2),	REGWSI(2),	REGFFI
    roti	REGWS(2),	REGWS(2),	14
    roti	REGWSI(2),	REGWSI(2),	14
    a		REGPC1,		REGPC1,		REGCSTART
    lqa		REGPC2,		IMADDRAC(29)
    a		REGPC1I,		REGPC1I,		REGCSTART2
    lqa		REGPC2I,		IMADDRAC(29)
    a		REGWS(2),	REGWS(2),	REGWS(3)
    a		REGWSI(2),	REGWSI(2),	REGWSI(3)


    selb	REGFF,		REGWS(3),	REGWS(2),	REGWS(0)
    selb	REGFFI,		REGWSI(3),	REGWSI(2),	REGWSI(0)
    a		REGWS(0),	REGWS(0),	REGPC1
    a		REGWSI(0),	REGWSI(0),	REGPC1I
    a		REGWS(1),	REGWS(1),	REGFF
    a		REGWSI(1),	REGWSI(1),	REGFFI
    roti	REGWS(1),	REGWS(1),	20
    roti	REGWSI(1),	REGWSI(1),	20
    a		REGPC2,		REGPC2,		REGM(2)
    lqa		REGPC3,		IMADDRAC(30)
    a		REGPC2I,		REGPC2I,		REGMI(2)
    lqa		REGPC3I,		IMADDRAC(30)
    a		REGWS(1),	REGWS(1),	REGWS(2)
    a		REGWSI(1),	REGWSI(1),	REGWSI(2)


    selb	REGFF,		REGWS(2),	REGWS(1),	REGWS(3)
    selb	REGFFI,		REGWSI(2),	REGWSI(1),	REGWSI(3)
    a		REGWS(3),	REGWS(3),	REGPC2
    a		REGWSI(3),	REGWSI(3),	REGPC2I
    a		REGWS(0),	REGWS(0),	REGFF
    a		REGWSI(0),	REGWSI(0),	REGFFI
    roti	REGWS(0),	REGWS(0),	5
    roti	REGWSI(0),	REGWSI(0),	5
    a		REGPC3,		REGPC3,		REGM(7)
    lqa		REGPC1,		IMADDRAC(31)
    a		REGPC3I,		REGPC3I,		REGMI(7)
    lqa		REGPC1I,		IMADDRAC(31)
    a		REGWS(0),	REGWS(0),	REGWS(1)
    a		REGWSI(0),	REGWSI(0),	REGWSI(1)


    selb	REGFF,		REGWS(1),	REGWS(0),	REGWS(2)
    selb	REGFFI,		REGWSI(1),	REGWSI(0),	REGWSI(2)
    a		REGWS(2),	REGWS(2),	REGPC3
    a		REGWSI(2),	REGWSI(2),	REGPC3I
    a		REGWS(3),	REGWS(3),	REGFF
    a		REGWSI(3),	REGWSI(3),	REGFFI
    roti	REGWS(3),	REGWS(3),	9
    roti	REGWSI(3),	REGWSI(3),	9
    a		REGPC1,		REGPC1,		REGM(12)
    lqa		REGPC2,		IMADDRAC(32)
    a		REGPC1I,		REGPC1I,		REGMI(12)
    lqa		REGPC2I,		IMADDRAC(32)
    a		REGWS(3),	REGWS(3),	REGWS(0)
    a		REGWSI(3),	REGWSI(3),	REGWSI(0)


    selb	REGFF,		REGWS(0),	REGWS(3),	REGWS(1)
    selb	REGFFI,		REGWSI(0),	REGWSI(3),	REGWSI(1)
    a		REGWS(1),	REGWS(1),	REGPC1
    a		REGWSI(1),	REGWSI(1),	REGPC1I
    a		REGWS(2),	REGWS(2),	REGFF
    a		REGWSI(2),	REGWSI(2),	REGFFI
    roti	REGWS(2),	REGWS(2),	14
    roti	REGWSI(2),	REGWSI(2),	14
    a		REGPC2,		REGPC2,		REGM(5)
    lqa		REGPC3,		IMADDRAC(33)
    a		REGPC2I,		REGPC2I,		REGMI(5)
    lqa		REGPC3I,		IMADDRAC(33)
    a		REGWS(2),	REGWS(2),	REGWS(3)
    a		REGWSI(2),	REGWSI(2),	REGWSI(3)


    selb	REGFF,		REGWS(3),	REGWS(2),	REGWS(0)
    selb	REGFFI,		REGWSI(3),	REGWSI(2),	REGWSI(0)
    a		REGWS(0),	REGWS(0),	REGPC2
    a		REGWSI(0),	REGWSI(0),	REGPC2I
    a		REGWS(1),	REGWS(1),	REGFF
    a		REGWSI(1),	REGWSI(1),	REGFFI
    roti	REGWS(1),	REGWS(1),	20
    roti	REGWSI(1),	REGWSI(1),	20
    xor		REGFF,		REGWS(2),	REGWS(3)
    lqa		REGPC1,		IMADDRAC(34)
    xor		REGFFI,		REGWSI(2),	REGWSI(3)
    lqa		REGPC1I,		IMADDRAC(34)
    a		REGWS(1),	REGWS(1),	REGWS(2)
    a		REGWSI(1),	REGWSI(1),	REGWSI(2)
    a		REGPC3,		REGPC3,		REGM(8)
    a		REGPC3I,		REGPC3I,		REGMI(8)


/*** ROUND 3 ***/
/*** ROUND 3 ***/


    xor		REGFF,		REGFF,		REGWS(1)
    xor		REGFFI,		REGFFI,		REGWSI(1)
    a		REGWS(3),	REGWS(3),	REGPC3
    a		REGWSI(3),	REGWSI(3),	REGPC3I
    a		REGWS(0),	REGWS(0),	REGFF
    a		REGWSI(0),	REGWSI(0),	REGFFI
    xor		REGFF,		REGWS(1),	REGWS(2)
    xor		REGFFI,		REGWSI(1),	REGWSI(2)
    roti	REGWS(0),	REGWS(0),	4
    roti	REGWSI(0),	REGWSI(0),	4
    a		REGPC1,		REGPC1,		REGM(11)
    lqa		REGPC2,		IMADDRAC(35)
    a		REGPC1I,		REGPC1I,		REGMI(11)
    lqa		REGPC2I,		IMADDRAC(35)
    a		REGWS(0),	REGWS(0),	REGWS(1)
    a		REGWSI(0),	REGWSI(0),	REGWSI(1)

    xor		REGFF,		REGFF,		REGWS(0)
    xor		REGFFI,		REGFFI,		REGWSI(0)
    a		REGWS(2),	REGWS(2),	REGPC1
    a		REGWSI(2),	REGWSI(2),	REGPC1I
    a		REGWS(3),	REGWS(3),	REGFF
    a		REGWSI(3),	REGWSI(3),	REGFFI
    xor		REGFF,		REGWS(0),	REGWS(1)
    xor		REGFFI,		REGWSI(0),	REGWSI(1)
    roti	REGWS(3),	REGWS(3),	11
    roti	REGWSI(3),	REGWSI(3),	11
    a		REGPC2,		REGPC2,		REGASTART
    lqa		REGPC3,		IMADDRAC(36)
    a		REGPC2I,		REGPC2I,		REGASTART2
    lqa		REGPC3I,		IMADDRAC(36)
    a		REGWS(3),	REGWS(3),	REGWS(0)
    a		REGWSI(3),	REGWSI(3),	REGWSI(0)

    xor		REGFF,		REGFF,		REGWS(3)
    xor		REGFFI,		REGFFI,		REGWSI(3)
    a		REGWS(1),	REGWS(1),	REGPC2
    a		REGWSI(1),	REGWSI(1),	REGPC2I
    a		REGWS(2),	REGWS(2),	REGFF
    a		REGWSI(2),	REGWSI(2),	REGFFI
    xor		REGFF,		REGWS(3),	REGWS(0)
    xor		REGFFI,		REGWSI(3),	REGWSI(0)
    roti	REGWS(2),	REGWS(2),	16
    roti	REGWSI(2),	REGWSI(2),	16
    a		REGPC3,		REGPC3,		REGM(1)
    lqa		REGPC1,		IMADDRAC(37)
    a		REGPC3I,		REGPC3I,		REGMI(1)
    lqa		REGPC1I,		IMADDRAC(37)
    a		REGWS(2),	REGWS(2),	REGWS(3)
    a		REGWSI(2),	REGWSI(2),	REGWSI(3)

    xor		REGFF,		REGFF,		REGWS(2)
    xor		REGFFI,		REGFFI,		REGWSI(2)
    a		REGWS(0),	REGWS(0),	REGPC3
    a		REGWSI(0),	REGWSI(0),	REGPC3I
    a		REGWS(1),	REGWS(1),	REGFF
    a		REGWSI(1),	REGWSI(1),	REGFFI
    xor		REGFF,		REGWS(2),	REGWS(3)
    xor		REGFFI,		REGWSI(2),	REGWSI(3)
    roti	REGWS(1),	REGWS(1),	23
    roti	REGWSI(1),	REGWSI(1),	23
    a		REGPC1,		REGPC1,		REGM(4)
    lqa		REGPC2,		IMADDRAC(38)
    a		REGPC1I,		REGPC1I,		REGMI(4)
    lqa		REGPC2I,		IMADDRAC(38)
    a		REGWS(1),	REGWS(1),	REGWS(2)
    a		REGWSI(1),	REGWSI(1),	REGWSI(2)

    xor		REGFF,		REGFF,		REGWS(1)
    xor		REGFFI,		REGFFI,		REGWSI(1)
    a		REGWS(3),	REGWS(3),	REGPC1
    a		REGWSI(3),	REGWSI(3),	REGPC1I
    a		REGWS(0),	REGWS(0),	REGFF
    a		REGWSI(0),	REGWSI(0),	REGFFI
    xor		REGFF,		REGWS(1),	REGWS(2)
    xor		REGFFI,		REGWSI(1),	REGWSI(2)
    roti	REGWS(0),	REGWS(0),	4
    roti	REGWSI(0),	REGWSI(0),	4
    a		REGPC2,		REGPC2,		REGM(7)
    lqa		REGPC3,		IMADDRAC(39)
    a		REGPC2I,		REGPC2I,		REGMI(7)
    lqa		REGPC3I,		IMADDRAC(39)
    a		REGWS(0),	REGWS(0),	REGWS(1)
    a		REGWSI(0),	REGWSI(0),	REGWSI(1)


    xor		REGFF,		REGFF,		REGWS(0)
    xor		REGFFI,		REGFFI,		REGWSI(0)
    a		REGWS(2),	REGWS(2),	REGPC2
    a		REGWSI(2),	REGWSI(2),	REGPC2I
    a		REGWS(3),	REGWS(3),	REGFF
    a		REGWSI(3),	REGWSI(3),	REGFFI
    xor		REGFF,		REGWS(0),	REGWS(1)
    xor		REGFFI,		REGWSI(0),	REGWSI(1)
    roti	REGWS(3),	REGWS(3),	11
    roti	REGWSI(3),	REGWSI(3),	11
    a		REGPC3,		REGPC3,		REGM(10)
    lqa		REGPC1,		IMADDRAC(40)
    a		REGPC3I,		REGPC3I,		REGMI(10)
    lqa		REGPC1I,		IMADDRAC(40)
    a		REGWS(3),	REGWS(3),	REGWS(0)
    a		REGWSI(3),	REGWSI(3),	REGWSI(0)


    xor		REGFF,		REGFF,		REGWS(3)
    xor		REGFFI,		REGFFI,		REGWSI(3)
    a		REGWS(1),	REGWS(1),	REGPC3
    a		REGWSI(1),	REGWSI(1),	REGPC3I
    a		REGWS(2),	REGWS(2),	REGFF
    a		REGWSI(2),	REGWSI(2),	REGFFI
    xor		REGFF,		REGWS(3),	REGWS(0)
    xor		REGFFI,		REGWSI(3),	REGWSI(0)
    roti	REGWS(2),	REGWS(2),	16
    roti	REGWSI(2),	REGWSI(2),	16
    a		REGPC1,		REGPC1,		REGCSTART
    lqa		REGPC2,		IMADDRAC(41)
    a		REGPC1I,		REGPC1I,		REGCSTART2
    lqa		REGPC2I,		IMADDRAC(41)
    a		REGWS(2),	REGWS(2),	REGWS(3)
    a		REGWSI(2),	REGWSI(2),	REGWSI(3)

    xor		REGFF,		REGFF,		REGWS(2)
    xor		REGFFI,		REGFFI,		REGWSI(2)
    a		REGWS(0),	REGWS(0),	REGPC1
    a		REGWSI(0),	REGWSI(0),	REGPC1I
    a		REGWS(1),	REGWS(1),	REGFF
    a		REGWSI(1),	REGWSI(1),	REGFFI
    xor		REGFF,		REGWS(2),	REGWS(3)
    xor		REGFFI,		REGWSI(2),	REGWSI(3)
    roti	REGWS(1),	REGWS(1),	23
    roti	REGWSI(1),	REGWSI(1),	23
    a		REGPC2,		REGPC2,		REGM(0)
    lqa		REGPC3,		IMADDRAC(42)
    a		REGPC2I,		REGPC2I,		REGMI(0)
    lqa		REGPC3I,		IMADDRAC(42)
    a		REGWS(1),	REGWS(1),	REGWS(2)
    a		REGWSI(1),	REGWSI(1),	REGWSI(2)

    xor		REGFF,		REGFF,		REGWS(1)
    xor		REGFFI,		REGFFI,		REGWSI(1)
    a		REGWS(3),	REGWS(3),	REGPC2
    a		REGWSI(3),	REGWSI(3),	REGPC2I
    a		REGWS(0),	REGWS(0),	REGFF
    a		REGWSI(0),	REGWSI(0),	REGFFI
    xor		REGFF,		REGWS(1),	REGWS(2)
    xor		REGFFI,		REGWSI(1),	REGWSI(2)
    roti	REGWS(0),	REGWS(0),	4
    roti	REGWSI(0),	REGWSI(0),	4
    a		REGPC3,		REGPC3,		REGM(3)
    lqa		REGPC1,		IMADDRAC(43)
    a		REGPC3I,		REGPC3I,		REGMI(3)
    lqa		REGPC1I,		IMADDRAC(43)
    a		REGWS(0),	REGWS(0),	REGWS(1)
    a		REGWSI(0),	REGWSI(0),	REGWSI(1)

    xor		REGFF,		REGFF,		REGWS(0)
    xor		REGFFI,		REGFFI,		REGWSI(0)
    a		REGWS(2),	REGWS(2),	REGPC3
    a		REGWSI(2),	REGWSI(2),	REGPC3I
    a		REGWS(3),	REGWS(3),	REGFF
    a		REGWSI(3),	REGWSI(3),	REGFFI
    xor		REGFF,		REGWS(0),	REGWS(1)
    xor		REGFFI,		REGWSI(0),	REGWSI(1)
    roti	REGWS(3),	REGWS(3),	11
    roti	REGWSI(3),	REGWSI(3),	11
    a		REGPC1,		REGPC1,		REGM(6)
    lqa		REGPC2,		IMADDRAC(44)
    a		REGPC1I,		REGPC1I,		REGMI(6)
    lqa		REGPC2I,		IMADDRAC(44)
    a		REGWS(3),	REGWS(3),	REGWS(0)
    a		REGWSI(3),	REGWSI(3),	REGWSI(0)

    xor		REGFF,		REGFF,		REGWS(3)
    xor		REGFFI,		REGFFI,		REGWSI(3)
    a		REGWS(1),	REGWS(1),	REGPC1
    a		REGWSI(1),	REGWSI(1),	REGPC1I
    a		REGWS(2),	REGWS(2),	REGFF
    a		REGWSI(2),	REGWSI(2),	REGFFI
    xor		REGFF,		REGWS(3),	REGWS(0)
    xor		REGFFI,		REGWSI(3),	REGWSI(0)
    roti	REGWS(2),	REGWS(2),	16
    roti	REGWSI(2),	REGWSI(2),	16
    a		REGPC2,		REGPC2,		REGM(9)
    lqa		REGPC3,		IMADDRAC(45)
    a		REGPC2I,		REGPC2I,		REGMI(9)
    lqa		REGPC3I,		IMADDRAC(45)
    a		REGWS(2),	REGWS(2),	REGWS(3)
    a		REGWSI(2),	REGWSI(2),	REGWSI(3)

    xor		REGFF,		REGFF,		REGWS(2)
    xor		REGFFI,		REGFFI,		REGWSI(2)
    a		REGWS(0),	REGWS(0),	REGPC2
    a		REGWSI(0),	REGWSI(0),	REGPC2I
    a		REGWS(1),	REGWS(1),	REGFF
    a		REGWSI(1),	REGWSI(1),	REGFFI
    xor		REGFF,		REGWS(2),	REGWS(3)
    xor		REGFFI,		REGWSI(2),	REGWSI(3)
    roti	REGWS(1),	REGWS(1),	23
    roti	REGWSI(1),	REGWSI(1),	23
    a		REGPC3,		REGPC3,		REGM(12)
    lqa		REGPC1,		IMADDRAC(46)
    a		REGPC3I,		REGPC3I,		REGMI(12)
    lqa		REGPC1I,		IMADDRAC(46)
    a		REGWS(1),	REGWS(1),	REGWS(2)
    a		REGWSI(1),	REGWSI(1),	REGWSI(2)

    xor		REGFF,		REGFF,		REGWS(1)
    xor		REGFFI,		REGFFI,		REGWSI(1)
    a		REGWS(3),	REGWS(3),	REGPC3
    a		REGWSI(3),	REGWSI(3),	REGPC3I
    a		REGWS(0),	REGWS(0),	REGFF
    a		REGWSI(0),	REGWSI(0),	REGFFI
    xor		REGFF,		REGWS(1),	REGWS(2)
    xor		REGFFI,		REGWSI(1),	REGWSI(2)
    roti	REGWS(0),	REGWS(0),	4
    roti	REGWSI(0),	REGWSI(0),	4
    a		REGPC1,		REGPC1,		REGBSTART
    lqa		REGPC2,		IMADDRAC(47)
    a		REGPC1I,		REGPC1I,		REGBSTART2
    lqa		REGPC2I,		IMADDRAC(47)
    a		REGWS(0),	REGWS(0),	REGWS(1)
    a		REGWSI(0),	REGWSI(0),	REGWSI(1)

    xor		REGFF,		REGFF,		REGWS(0)
    xor		REGFFI,		REGFFI,		REGWSI(0)
    a		REGWS(2),	REGWS(2),	REGPC1
    a		REGWSI(2),	REGWSI(2),	REGPC1I
    a		REGWS(3),	REGWS(3),	REGFF
    a		REGWSI(3),	REGWSI(3),	REGFFI
    xor		REGFF,		REGWS(0),	REGWS(1)
    xor		REGFFI,		REGWSI(0),	REGWSI(1)
    roti	REGWS(3),	REGWS(3),	11
    roti	REGWSI(3),	REGWSI(3),	11
    a		REGPC2,		REGPC2,		REGM(2)
    lqa		REGPC3,		IMADDRAC(48)
    a		REGPC2I,		REGPC2I,		REGMI(2)
    lqa		REGPC3I,		IMADDRAC(48)
    a		REGWS(3),	REGWS(3),	REGWS(0)
    a		REGWSI(3),	REGWSI(3),	REGWSI(0)

    xor		REGFF,		REGFF,		REGWS(3)
    xor		REGFFI,		REGFFI,		REGWSI(3)
    a		REGWS(1),	REGWS(1),	REGPC2
    a		REGWSI(1),	REGWSI(1),	REGPC2I
    a		REGWS(2),	REGWS(2),	REGFF
    a		REGWSI(2),	REGWSI(2),	REGFFI
    xor		REGFF,		REGWS(3),	REGWS(0)
    xor		REGFFI,		REGWSI(3),	REGWSI(0)
    roti	REGWS(2),	REGWS(2),	16
    roti	REGWSI(2),	REGWSI(2),	16
    a		REGPC3,		REGPC3,		REGM(0)
    lqa		REGPC1,		IMADDRAC(49)
    a		REGPC3I,		REGPC3I,		REGMI(0)
    lqa		REGPC1I,		IMADDRAC(49)
    a		REGWS(2),	REGWS(2),	REGWS(3)
    a		REGWSI(2),	REGWSI(2),	REGWSI(3)

    xor		REGFF,		REGFF,		REGWS(2)
    xor		REGFFI,		REGFFI,		REGWSI(2)
    a		REGWS(0),	REGWS(0),	REGPC3
    a		REGWSI(0),	REGWSI(0),	REGPC3I
    a		REGWS(1),	REGWS(1),	REGFF
    a		REGWSI(1),	REGWSI(1),	REGFFI
    eqv		REGFF1,		REGWS(2),	REGWS(3)
    eqv		REGFF1I,		REGWSI(2),	REGWSI(3)
    roti	REGWS(1),	REGWS(1),	23
    roti	REGWSI(1),	REGWSI(1),	23
    a		REGPC1,		REGPC1,		REGM(7)
    lqa		REGPC2,		IMADDRAC(50)
    a		REGPC1I,		REGPC1I,		REGMI(7)
    lqa		REGPC2I,		IMADDRAC(50)
    nand	REGFF,		REGWS(2),	REGWS(2)
    nand	REGFFI,		REGWSI(2),	REGWSI(2)
    a		REGWS(1),	REGWS(1),	REGWS(2)
    a		REGWSI(1),	REGWSI(1),	REGWSI(2)

/*** ROUND 4 ***/
/*** ROUND 4 ***/

    selb	REGFF,		REGFF1,		REGFF,		REGWS(1)
    selb	REGFFI,		REGFF1I,		REGFFI,		REGWSI(1)
    a		REGWS(3),	REGWS(3),	REGPC1
    a		REGWSI(3),	REGWSI(3),	REGPC1I
    a		REGWS(0),	REGWS(0),	REGFF
    a		REGWSI(0),	REGWSI(0),	REGFFI
    roti	REGWS(0),	REGWS(0),	6
    roti	REGWSI(0),	REGWSI(0),	6
    eqv		REGFF1,		REGWS(1),	REGWS(2)
    eqv		REGFF1I,		REGWSI(1),	REGWSI(2)
    nand	REGFF,		REGWS(1),	REGWS(1)
    nand	REGFFI,		REGWSI(1),	REGWSI(1)
    a		REGPC2,		REGPC2,		REGASTART
    lqa		REGPC3,		IMADDRAC(51)
    a		REGPC2I,		REGPC2I,		REGASTART2
    lqa		REGPC3I,		IMADDRAC(51)
    a		REGWS(0),	REGWS(0),	REGWS(1)
    a		REGWSI(0),	REGWSI(0),	REGWSI(1)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(0)
    selb	REGFFI,		REGFF1I,		REGFFI,		REGWSI(0)
    a		REGWS(2),	REGWS(2),	REGPC2
    a		REGWSI(2),	REGWSI(2),	REGPC2I
    a		REGWS(3),	REGWS(3),	REGFF
    a		REGWSI(3),	REGWSI(3),	REGFFI
    roti	REGWS(3),	REGWS(3),	10
    roti	REGWSI(3),	REGWSI(3),	10
    eqv		REGFF1,		REGWS(0),	REGWS(1)
    eqv		REGFF1I,		REGWSI(0),	REGWSI(1)
    nand	REGFF,		REGWS(0),	REGWS(0)
    nand	REGFFI,		REGWSI(0),	REGWSI(0)
    a		REGPC3,		REGPC3,		REGM(5)
    lqa		REGPC1,		IMADDRAC(52)
    a		REGPC3I,		REGPC3I,		REGMI(5)
    lqa		REGPC1I,		IMADDRAC(52)
    a		REGWS(3),	REGWS(3),	REGWS(0)
    a		REGWSI(3),	REGWSI(3),	REGWSI(0)


    selb	REGFF,		REGFF1,		REGFF,		REGWS(3)
    selb	REGFFI,		REGFF1I,		REGFFI,		REGWSI(3)
    a		REGWS(1),	REGWS(1),	REGPC3
    a		REGWSI(1),	REGWSI(1),	REGPC3I
    a		REGWS(2),	REGWS(2),	REGFF
    a		REGWSI(2),	REGWSI(2),	REGFFI
    roti	REGWS(2),	REGWS(2),	15
    roti	REGWSI(2),	REGWSI(2),	15
    eqv		REGFF1,		REGWS(3),	REGWS(0)
    eqv		REGFF1I,		REGWSI(3),	REGWSI(0)
    nand	REGFF,		REGWS(3),	REGWS(3)
    nand	REGFFI,		REGWSI(3),	REGWSI(3)
    a		REGPC1,		REGPC1,		REGM(12)
    lqa		REGPC2,		IMADDRAC(53)
    a		REGPC1I,		REGPC1I,		REGMI(12)
    lqa		REGPC2I,		IMADDRAC(53)
    a		REGWS(2),	REGWS(2),	REGWS(3)
    a		REGWSI(2),	REGWSI(2),	REGWSI(3)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(2)
    selb	REGFFI,		REGFF1I,		REGFFI,		REGWSI(2)
    a		REGWS(0),	REGWS(0),	REGPC1
    a		REGWSI(0),	REGWSI(0),	REGPC1I
    a		REGWS(1),	REGWS(1),	REGFF
    a		REGWSI(1),	REGWSI(1),	REGFFI
    roti	REGWS(1),	REGWS(1),	21
    roti	REGWSI(1),	REGWSI(1),	21
    eqv		REGFF1,		REGWS(2),	REGWS(3)
    eqv		REGFF1I,		REGWSI(2),	REGWSI(3)
    nand	REGFF,		REGWS(2),	REGWS(2)
    nand	REGFFI,		REGWSI(2),	REGWSI(2)
    a		REGPC2,		REGPC2,		REGM(3)
    lqa		REGPC3,		IMADDRAC(54)
    a		REGPC2I,		REGPC2I,		REGMI(3)
    lqa		REGPC3I,		IMADDRAC(54)
    a		REGWS(1),	REGWS(1),	REGWS(2)
    a		REGWSI(1),	REGWSI(1),	REGWSI(2)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(1)
    selb	REGFFI,		REGFF1I,		REGFFI,		REGWSI(1)
    a		REGWS(3),	REGWS(3),	REGPC2
    a		REGWSI(3),	REGWSI(3),	REGPC2I
    a		REGWS(0),	REGWS(0),	REGFF
    a		REGWSI(0),	REGWSI(0),	REGFFI
    roti	REGWS(0),	REGWS(0),	6
    roti	REGWSI(0),	REGWSI(0),	6
    eqv		REGFF1,		REGWS(1),	REGWS(2)
    eqv		REGFF1I,		REGWSI(1),	REGWSI(2)
    nand	REGFF,		REGWS(1),	REGWS(1)
    nand	REGFFI,		REGWSI(1),	REGWSI(1)
    a		REGPC3,		REGPC3,		REGM(10)
    lqa		REGPC1,		IMADDRAC(55)
    a		REGPC3I,		REGPC3I,		REGMI(10)
    lqa		REGPC1I,		IMADDRAC(55)
    a		REGWS(0),	REGWS(0),	REGWS(1)
    a		REGWSI(0),	REGWSI(0),	REGWSI(1)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(0)
    selb	REGFFI,		REGFF1I,		REGFFI,		REGWSI(0)
    a		REGWS(2),	REGWS(2),	REGPC3
    a		REGWSI(2),	REGWSI(2),	REGPC3I
    a		REGWS(3),	REGWS(3),	REGFF
    a		REGWSI(3),	REGWSI(3),	REGFFI
    roti	REGWS(3),	REGWS(3),	10
    roti	REGWSI(3),	REGWSI(3),	10
    eqv		REGFF1,		REGWS(0),	REGWS(1)
    eqv		REGFF1I,		REGWSI(0),	REGWSI(1)
    nand	REGFF,		REGWS(0),	REGWS(0)
    nand	REGFFI,		REGWSI(0),	REGWSI(0)
    a		REGPC1,		REGPC1,		REGM(1)
    lqa		REGPC2,		IMADDRAC(56)
    a		REGPC1I,		REGPC1I,		REGMI(1)
    lqa		REGPC2I,		IMADDRAC(56)
    a		REGWS(3),	REGWS(3),	REGWS(0)
    a		REGWSI(3),	REGWSI(3),	REGWSI(0)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(3)
    selb	REGFFI,		REGFF1I,		REGFFI,		REGWSI(3)
    a		REGWS(1),	REGWS(1),	REGPC1
    a		REGWSI(1),	REGWSI(1),	REGPC1I
    a		REGWS(2),	REGWS(2),	REGFF
    a		REGWSI(2),	REGWSI(2),	REGFFI
    roti	REGWS(2),	REGWS(2),	15
    roti	REGWSI(2),	REGWSI(2),	15
    eqv		REGFF1,		REGWS(3),	REGWS(0)
    eqv		REGFF1I,		REGWSI(3),	REGWSI(0)
    nand	REGFF,		REGWS(3),	REGWS(3)
    nand	REGFFI,		REGWSI(3),	REGWSI(3)
    a		REGPC2,		REGPC2,		REGM(8)
    lqa		REGPC3,		IMADDRAC(57)
    a		REGPC2I,		REGPC2I,		REGMI(8)
    lqa		REGPC3I,		IMADDRAC(57)
    a		REGWS(2),	REGWS(2),	REGWS(3)
    a		REGWSI(2),	REGWSI(2),	REGWSI(3)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(2)
    selb	REGFFI,		REGFF1I,		REGFFI,		REGWSI(2)
    a		REGWS(0),	REGWS(0),	REGPC2
    a		REGWSI(0),	REGWSI(0),	REGPC2I
    a		REGWS(1),	REGWS(1),	REGFF
    a		REGWSI(1),	REGWSI(1),	REGFFI
    roti	REGWS(1),	REGWS(1),	21
    roti	REGWSI(1),	REGWSI(1),	21
    eqv		REGFF1,		REGWS(2),	REGWS(3)
    eqv		REGFF1I,		REGWSI(2),	REGWSI(3)
    nand	REGFF,		REGWS(2),	REGWS(2)
    nand	REGFFI,		REGWSI(2),	REGWSI(2)
    a		REGPC3,		REGPC3,		REGBSTART
    lqa		REGPC1,		IMADDRAC(58)
    a		REGPC3I,		REGPC3I,		REGBSTART2
    lqa		REGPC1I,		IMADDRAC(58)
    a		REGWS(1),	REGWS(1),	REGWS(2)
    a		REGWSI(1),	REGWSI(1),	REGWSI(2)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(1)
    selb	REGFFI,		REGFF1I,		REGFFI,		REGWSI(1)
    a		REGWS(3),	REGWS(3),	REGPC3
    a		REGWSI(3),	REGWSI(3),	REGPC3I
    a		REGWS(0),	REGWS(0),	REGFF
    a		REGWSI(0),	REGWSI(0),	REGFFI
    roti	REGWS(0),	REGWS(0),	6
    roti	REGWSI(0),	REGWSI(0),	6
    eqv		REGFF1,		REGWS(1),	REGWS(2)
    eqv		REGFF1I,		REGWSI(1),	REGWSI(2)
    nand	REGFF,		REGWS(1),	REGWS(1)
    nand	REGFFI,		REGWSI(1),	REGWSI(1)
    a		REGPC1,		REGPC1,		REGM(6)
    lqa		REGPC2,		IMADDRAC(59)
    a		REGPC1I,		REGPC1I,		REGMI(6)
    lqa		REGPC2I,		IMADDRAC(59)
    a		REGWS(0),	REGWS(0),	REGWS(1)
    a		REGWSI(0),	REGWSI(0),	REGWSI(1)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(0)
    selb	REGFFI,		REGFF1I,		REGFFI,		REGWSI(0)
    a		REGWS(2),	REGWS(2),	REGPC1
    a		REGWSI(2),	REGWSI(2),	REGPC1I
    a		REGWS(3),	REGWS(3),	REGFF
    a		REGWSI(3),	REGWSI(3),	REGFFI
    roti	REGWS(3),	REGWS(3),	10
    roti	REGWSI(3),	REGWSI(3),	10
    eqv		REGFF1,		REGWS(0),	REGWS(1)
    eqv		REGFF1I,		REGWSI(0),	REGWSI(1)
    nand	REGFF,		REGWS(0),	REGWS(0)
    nand	REGFFI,		REGWSI(0),	REGWSI(0)
    a		REGPC2,		REGPC2,		REGCSTART
    lqa		REGPC3,		IMADDRAC(60)
    a		REGPC2I,		REGPC2I,		REGCSTART2
    lqa		REGPC3I,		IMADDRAC(60)
    a		REGWS(3),	REGWS(3),	REGWS(0)
    a		REGWSI(3),	REGWSI(3),	REGWSI(0)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(3)
    selb	REGFFI,		REGFF1I,		REGFFI,		REGWSI(3)
    a		REGWS(1),	REGWS(1),	REGPC2
    a		REGWSI(1),	REGWSI(1),	REGPC2I
    a		REGWS(2),	REGWS(2),	REGFF
    a		REGWSI(2),	REGWSI(2),	REGFFI
    roti	REGWS(2),	REGWS(2),	15
    roti	REGWSI(2),	REGWSI(2),	15
    eqv		REGFF1,		REGWS(3),	REGWS(0)
    eqv		REGFF1I,		REGWSI(3),	REGWSI(0)
    nand	REGFF,		REGWS(3),	REGWS(3)
    nand	REGFFI,		REGWSI(3),	REGWSI(3)
    a		REGPC3,		REGPC3,		REGM(4)
    lqa		REGPC1,		IMADDRAC(61)
    a		REGPC3I,		REGPC3I,		REGMI(4)
    lqa		REGPC1I,		IMADDRAC(61)
    a		REGWS(2),	REGWS(2),	REGWS(3)
    a		REGWSI(2),	REGWSI(2),	REGWSI(3)
    
    selb	REGFF,		REGFF1,		REGFF,		REGWS(2)
    selb	REGFFI,		REGFF1I,		REGFFI,		REGWSI(2)
    a		REGWS(0),	REGWS(0),	REGPC3
    a		REGWSI(0),	REGWSI(0),	REGPC3I
    a		REGWS(1),	REGWS(1),	REGFF
    a		REGWSI(1),	REGWSI(1),	REGFFI
//    sf		REGB,		REGIHV(2),	REGIHV(3)
//    sf		REGB2,		REGIHVI(2),	REGIHVI(3)
    roti	REGWS(1),	REGWS(1),	21
    roti	REGWSI(1),	REGWSI(1),	21
    eqv		REGFF1,		REGWS(2),	REGWS(3)
    eqv		REGFF1I,		REGWSI(2),	REGWSI(3)
    nand	REGFF,		REGWS(2),	REGWS(2)
    nand	REGFFI,		REGWSI(2),	REGWSI(2)
    a		REGPC1,		REGPC1,		REGM(11)
    lqa		REGPC2,		IMADDRAC(62)
    a		REGPC1I,		REGPC1I,		REGMI(11)
    lqa		REGPC2I,		IMADDRAC(62)
    a		REGWS(1),	REGWS(1),	REGWS(2)
    a		REGWSI(1),	REGWSI(1),	REGWSI(2)

    selb	REGFF,		REGFF1,		REGFF,		REGWS(1)
    selb	REGFFI,		REGFF1I,		REGFFI,		REGWSI(1)
    a		REGWS(3),	REGWS(3),	REGPC1
    a		REGWSI(3),	REGWSI(3),	REGPC1I
    a		REGWS(0),	REGWS(0),	REGFF
    a		REGWSI(0),	REGWSI(0),	REGFFI
    roti	REGWS(0),	REGWS(0),	6
    roti	REGWSI(0),	REGWSI(0),	6
    eqv		REGFF1,		REGWS(1),	REGWS(2)
    eqv		REGFF1I,		REGWSI(1),	REGWSI(2)
    nand	REGFF,		REGWS(1),	REGWS(1)
    nand	REGFFI,		REGWSI(1),	REGWSI(1)
    a		REGPC2,		REGPC2,		REGM(2)
    lqa		REGPC1,		IMADDRAC(63)
    a		REGPC2I,		REGPC2I,		REGMI(2)
    lqa		REGPC1I,		IMADDRAC(63)
    a		REGWS(0),	REGWS(0),	REGWS(1)
    a		REGWSI(0),	REGWSI(0),	REGWSI(1)


//    sf		REGC,		REGIHV(1),	REGIHV(3)
//    sf		REGC2,		REGIHVI(1),	REGIHVI(3)
    selb	REGFF,		REGFF1,		REGFF,		REGWS(0)
    selb	REGFFI,		REGFF1I,		REGFFI,		REGWSI(0)
    a		REGWS(2),	REGWS(2),	REGPC2
    a		REGWSI(2),	REGWSI(2),	REGPC2I
    a		REGWS(3),	REGWS(3),	REGFF
    a		REGWSI(3),	REGWSI(3),	REGFFI
    a		REGA,		REGIHV(0),	REGWS(0)
    a		REGA2,		REGIHVI(0),	REGWSI(0)
    roti	REGWS(3),	REGWS(3),	10
    roti	REGWSI(3),	REGWSI(3),	10
    eqv		REGFF1,		REGWS(0),	REGWS(1)
    eqv		REGFF1I,		REGWSI(0),	REGWSI(1)
    nand	REGFF,		REGWS(0),	REGWS(0)
    nand	REGFFI,		REGWSI(0),	REGWSI(0)
    a		REGPC1,		REGPC1,		REGM(9)
    a		REGPC1I,		REGPC1I,		REGMI(9)
    a		REGWS(3),	REGWS(3),	REGWS(0)
    a		REGWSI(3),	REGWSI(3),	REGWSI(0)
    
		a		REGB,		REGIHV(3),		REGWS(3)
		a		REGB2,		REGIHVI(3),		REGWSI(3)


    selb	REGFF,		REGFF1,		REGFF,		REGWS(3)
    selb	REGFFI,		REGFF1I,		REGFFI,		REGWSI(3)
    a		REGWS(1),	REGWS(1),	REGPC1
    a		REGWSI(1),	REGWSI(1),	REGPC1I
    a		REGWS(2),	REGWS(2),	REGFF
    a		REGWSI(2),	REGWSI(2),	REGFFI
    roti	REGWS(2),	REGWS(2),	15
    roti	REGWSI(2),	REGWSI(2),	15

    ai          REGLEN,         REGLEN2,         -1
    hbra        md5compress_loop_end4mod,           md5compress_loop4mod

    ceq		REGPC1,		REGA,		REGA2

    ceqi	REGPC3,		REGLEN,		0

    a		REGWS(2),	REGWS(2),	REGWS(3)
    a		REGWSI(2),	REGWSI(2),	REGWSI(3)

    
		a		REGC,		REGIHV(2),		REGWS(2)
		a		REGC2,		REGIHVI(2),		REGWSI(2)


    ceq		REGPC2,		REGB,		REGB2
    and		REGC,		REGC,		REGHBMASK
    and		REGC2,		REGC2,		REGHBMASK
    and		REGPC1,		REGPC1,		REGPC2

    ceq		REGPC2,		REGC,		REGC2
    and		REGPC1,		REGPC1,		REGPC2
    or		REGPC1,		REGPC1,		REGPC3
    andc	REGREADY,	REGREADY,	REGPC1
    selb	REGASTART,	REGASTART,	REGA,		REGREADY
    selb	REGBSTART,	REGBSTART,	REGB,		REGREADY
    selb	REGCSTART,	REGCSTART,	REGC,		REGREADY
    gb		REGPC3,		REGREADY
    selb	REGASTART2,	REGASTART2,	REGA2,		REGREADY
    selb	REGBSTART2,	REGBSTART2,	REGB2,		REGREADY
    selb	REGCSTART2,	REGCSTART2,	REGC2,		REGREADY
    lnop
    selb	REGLEN2,	REGLEN2,	REGLEN,		REGREADY
    	
md5compress_loop_end4mod:
    brnz	REGPC3,		md5compress_loop4mod

    hbra	afterstorejump4mod,	md5compress_loop4mod

    stqd	REGASTART,	0x00($8)    
    stqd	REGBSTART,	0x10($8)
    stqd	REGCSTART,	0x20($8)
    stqd	REGLEN2,	0x30($8)
    stqd	REGASTART2,	0x40($8)     
    stqd	REGBSTART2,	0x50($8)
    stqd	REGCSTART2,	0x60($8)
    stqd	REGLEN2,	0x70($8)
    ai		$8,			$8,			16*8
    lqd		REGASTART,	0x00($8)
    lqd		REGASTART2,	0x40($8)
    lqd		REGBSTART,	0x10($8)
    lqd		REGBSTART2,	0x50($8)
    lqd		REGCSTART,	0x20($8)
    lqd		REGCSTART2,	0x60($8)
    lqd		REGLEN,		0x30($8)
    lqd		REGLEN2,	0x70($8)
	
    ceq		REGPC1,		REGASTART,	REGASTART2
    ceq		REGPC2,		REGBSTART,	REGBSTART2
    ceq		REGPC3,		REGCSTART,	REGCSTART2
    and		REGPC1,		REGPC1,		REGPC2
    ceqi	REGPC2,		REGLEN,		0
    and		REGPC1,		REGPC1,		REGPC3
    clgt	REGPC3,		$9,			$8	
    or		REGPC1,		REGPC1,		REGPC2
    nand	REGREADY,	REGPC1,		REGPC1

afterstorejump4mod:
    brnz		REGPC3,		md5compress_loop4mod

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
    LOADREG(99)
    LOADREG(100)
    LOADREG(101)
    LOADREG(102)
    LOADREG(103)
    LOADREG(104)
    LOADREG(105)
    LOADREG(106)
    LOADREG(107)
    LOADREG(108)
    LOADREG(109)
    LOADREG(110)
    LOADREG(111)
    LOADREG(112)
    LOADREG(113)
    LOADREG(114)
    LOADREG(115)
    LOADREG(116)
    LOADREG(117)
    LOADREG(118)
    LOADREG(119)
    LOADREG(120)
    LOADREG(121)
    LOADREG(122)

    bi		$lr
    .size	find_collmod,.-find_collmod

