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
    .global	generate_trails
    .type	generate_trails,@function
    .global	pre_compute
    .type	pre_compute,@function

#define REGIHV(i)	$(i+10)
#define REGIHVI(i)	$(i+14)
#define	REGIHV1(i)	$(i+18)
#define REGIHV2(i)	$(i+22)
#define	REGWS(i)	$(i+26)
#define	REGWSI(i)	$(i+30)
#define REGWS1(i)	$(i+34)
#define REGWS2(i)	$(i+38)
#define	REGM(i)		$(i+42)
#define	REGMI(i)	$(i+55)
#define REGM1(i)	$(i+68)
#define REGM2(i)	$(i+81)
#define REGASTART	$94
#define REGBSTART	$95
#define REGCSTART	$96
#define REGA		$97
#define REGB		$98
#define REGC		$99
#define REGLEN		$100
#define REGASTART2	$101
#define REGBSTART2	$102
#define REGCSTART2	$103
#define REGA2		$104
#define REGB2		$105
#define REGC2		$106
#define REGLEN2		$107
#define REGDPMASK	$108
#define REGHBMASK	$109
#define REGMAXLEN	$110
#define REGX    	$111
#define REGY    	$112
#define REGZ    	$113
#define REGW    	$114
#define	REGID		$115

#define	IMADDRAC(i)	i*16+md5_acvec
#define	REGFF		$116
#define	REGFF1		$117
#define	REGPC1		$118
#define	REGPC2		$119
#define	REGPC3		$120
#define REGSELB		$121
#define	REGFFI		$122
#define	REGFF1I		$123
#define	REGPC1I		$124
#define	REGPC2I		$125
#define	REGPC3I		$126
#define REGSELBI	$127

#define REGXA		$122
#define REGXB		$123
#define REGXAB		$124
#define REGWC		$125

// using registers: $0 - $127

#define STOREREG(i)	stqa	$(i),	(i*16)+regstore
#define LOADREG(i)	lqa		$(i),	(i*16)+regstore

pre_compute:
//	$3:	@ihv1
//	$4:	@ihv2
//	$5:	@msg1
//	$6:	@msg2
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
    STOREREG(123)
    STOREREG(124)
    STOREREG(125)
    STOREREG(126)
    STOREREG(127)

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

// precompute working state 1
    ilhu	REGWS1(0),	0xd76a
    lqa		REGPC1,		IMADDRAC(1)
    selb	REGFF,		REGIHV1(3),	REGIHV1(2),	REGIHV1(1)
    iohl	REGWS1(0),	0xa478
    a		REGPC3,		REGM1(0),	REGFF
    lqa		REGPC2,		IMADDRAC(2)
    a		REGWS1(0),	REGIHV1(0),	REGWS1(0)
    or		REGWS1(3),	REGIHV1(3),	REGIHV1(3)
    a		REGWS1(0),	REGWS1(0),	REGPC3
    lqa		REGPC3,		IMADDRAC(3)
    a		REGPC1,		REGM1(1),	REGPC1
    roti	REGWS1(0),	REGWS1(0),	7
    a		REGPC2,		REGPC2,		REGM1(2)
    a		REGWS1(3),	REGWS1(3),	REGPC1
    or		REGWS1(2),	REGIHV1(2),	REGIHV1(2)
    a		REGWS1(0),	REGWS1(0),	REGIHV1(1)
    or		REGWS1(1),	REGIHV1(1),	REGIHV1(1)

    selb	REGFF,		REGWS1(2),	REGIHV1(1),	REGWS1(0)
    a		REGWS1(2),	REGWS1(2),	REGPC2
    a		REGWS1(3),	REGWS1(3),	REGFF
    roti	REGWS1(3),	REGWS1(3),	12
    a		REGPC3,		REGPC3,		REGM1(3)
    lqa		REGPC1,		IMADDRAC(4)
    a		REGWS1(3),	REGWS1(3),	REGWS1(0)

    selb	REGFF,		REGWS1(1),	REGWS1(0),	REGWS1(3)
    a		REGWS1(1),	REGWS1(1),	REGPC3
    a		REGWS1(2),	REGWS1(2),	REGFF
    roti	REGWS1(2),	REGWS1(2),	17
    a		REGPC1,		REGPC1,		REGM1(4)
    lqa		REGPC2,		IMADDRAC(5)
    a		REGWS1(2),	REGWS1(2),	REGWS1(3)

    selb	REGFF,		REGWS1(0),	REGWS1(3),	REGWS1(2)
    a		REGWS1(0),	REGWS1(0),	REGPC1
    a		REGWS1(1),	REGWS1(1),	REGFF
    roti	REGWS1(1),	REGWS1(1),	22
    a		REGPC2,		REGPC2,		REGM1(5)
    lqa		REGPC3,		IMADDRAC(6)
    a		REGWS1(1),	REGWS1(1),	REGWS1(2)

    selb	REGFF,		REGWS1(3),	REGWS1(2),	REGWS1(1)
    a		REGWS1(3),	REGWS1(3),	REGPC2
    a		REGWS1(0),	REGWS1(0),	REGFF
    roti	REGWS1(0),	REGWS1(0),	7
    a		REGPC3,		REGPC3,		REGM1(6)
    lqa		REGPC1,		IMADDRAC(7)
    a		REGWS1(0),	REGWS1(0),	REGWS1(1)

    selb	REGFF,		REGWS1(2),	REGWS1(1),	REGWS1(0)
    a		REGWS1(2),	REGWS1(2),	REGPC3
    a		REGWS1(3),	REGWS1(3),	REGFF
    roti	REGWS1(3),	REGWS1(3),	12
    a		REGPC1,		REGPC1,		REGM1(7)
    lqa		REGPC2,		IMADDRAC(8)
    a		REGWS1(3),	REGWS1(3),	REGWS1(0)

    selb	REGFF,		REGWS1(1),	REGWS1(0),	REGWS1(3)
    a		REGWS1(1),	REGWS1(1),	REGPC1
    a		REGWS1(2),	REGWS1(2),	REGFF
    roti	REGWS1(2),	REGWS1(2),	17
    a		REGPC2,		REGPC2,		REGM1(8)
    lqa		REGPC3,		IMADDRAC(9)
    a		REGWS1(2),	REGWS1(2),	REGWS1(3)

    selb	REGFF,		REGWS1(0),	REGWS1(3),	REGWS1(2)
    a		REGWS1(0),	REGWS1(0),	REGPC2
    a		REGWS1(1),	REGWS1(1),	REGFF
    roti	REGWS1(1),	REGWS1(1),	22
    a		REGPC3,		REGPC3,		REGM1(9)
    lqa		REGPC1,		IMADDRAC(10)
    a		REGWS1(1),	REGWS1(1),	REGWS1(2)

    selb	REGFF,		REGWS1(3),	REGWS1(2),	REGWS1(1)
    a		REGWS1(3),	REGWS1(3),	REGPC3
    a		REGWS1(0),	REGWS1(0),	REGFF
    roti	REGWS1(0),	REGWS1(0),	7
    a		REGPC1,		REGPC1,		REGM1(10)
    lqa		REGPC2,		IMADDRAC(11)
    a		REGWS1(0),	REGWS1(0),	REGWS1(1)

    selb	REGFF,		REGWS1(2),	REGWS1(1),	REGWS1(0)
    a		REGWS1(2),	REGWS1(2),	REGPC1
    a		REGWS1(3),	REGWS1(3),	REGFF
    roti	REGWS1(3),	REGWS1(3),	12
    a		REGPC2,		REGPC2,		REGM1(11)
    lqa		REGPC3,		IMADDRAC(12)
    a		REGWS1(3),	REGWS1(3),	REGWS1(0)

    selb	REGFF,		REGWS1(1),	REGWS1(0),	REGWS1(3)
    a		REGWS1(1),	REGWS1(1),	REGPC2
    a		REGWS1(2),	REGWS1(2),	REGFF
    roti	REGWS1(2),	REGWS1(2),	17
    a		REGPC3,		REGPC3,		REGM1(12)
    lqa		REGPC1,		IMADDRAC(13)
    a		REGWS1(2),	REGWS1(2),	REGWS1(3)

    selb	REGFF,		REGWS1(0),	REGWS1(3),	REGWS1(2)
    a		REGWS1(0),	REGWS1(0),	REGPC3
    a		REGWS1(1),	REGWS1(1),	REGFF
    roti	REGWS1(1),	REGWS1(1),	22
    a		REGWS1(1),	REGWS1(1),	REGWS1(2)

    selb	REGFF,		REGWS1(3),	REGWS1(2),	REGWS1(1)
    a		REGWS1(3),	REGWS1(3),	REGPC1
    a		REGWS1(0),	REGWS1(0),	REGFF
    roti	REGWS1(0),	REGWS1(0),	7
    a		REGWS1(0),	REGWS1(0),	REGWS1(1)

    selb	REGFF,		REGWS1(2),	REGWS1(1),	REGWS1(0)
    a		REGWS1(3),	REGWS1(3),	REGFF

    stqa	REGWS1(0),	 0 + workingstate1
    stqa	REGWS1(1),	16 + workingstate1
    stqa	REGWS1(2),	32 + workingstate1
    stqa	REGWS1(3),	48 + workingstate1

// precompute working state 2
    ilhu	REGWS2(0),	0xd76a
    lqa		REGPC1,		IMADDRAC(1)
    selb	REGFF,		REGIHV2(3),	REGIHV2(2),	REGIHV2(1)
    iohl	REGWS2(0),	0xa478
    a		REGPC3,		REGM2(0),	REGFF
    lqa		REGPC2,		IMADDRAC(2)
    a		REGWS2(0),	REGIHV2(0),	REGWS2(0)
    or		REGWS2(3),	REGIHV2(3),	REGIHV2(3)
    a		REGWS2(0),	REGWS2(0),	REGPC3
    lqa		REGPC3,		IMADDRAC(3)
    a		REGPC1,		REGM2(1),	REGPC1
    roti	REGWS2(0),	REGWS2(0),	7
    a		REGPC2,		REGPC2,		REGM2(2)
    a		REGWS2(3),	REGWS2(3),	REGPC1
    or		REGWS2(2),	REGIHV2(2),	REGIHV2(2)
    a		REGWS2(0),	REGWS2(0),	REGIHV2(1)
    or		REGWS2(1),	REGIHV2(1),	REGIHV2(1)

    selb	REGFF,		REGWS2(2),	REGIHV2(1),	REGWS2(0)
    a		REGWS2(2),	REGWS2(2),	REGPC2
    a		REGWS2(3),	REGWS2(3),	REGFF
    roti	REGWS2(3),	REGWS2(3),	12
    a		REGPC3,		REGPC3,		REGM2(3)
    lqa		REGPC1,		IMADDRAC(4)
    a		REGWS2(3),	REGWS2(3),	REGWS2(0)

    selb	REGFF,		REGWS2(1),	REGWS2(0),	REGWS2(3)
    a		REGWS2(1),	REGWS2(1),	REGPC3
    a		REGWS2(2),	REGWS2(2),	REGFF
    roti	REGWS2(2),	REGWS2(2),	17
    a		REGPC1,		REGPC1,		REGM2(4)
    lqa		REGPC2,		IMADDRAC(5)
    a		REGWS2(2),	REGWS2(2),	REGWS2(3)

    selb	REGFF,		REGWS2(0),	REGWS2(3),	REGWS2(2)
    a		REGWS2(0),	REGWS2(0),	REGPC1
    a		REGWS2(1),	REGWS2(1),	REGFF
    roti	REGWS2(1),	REGWS2(1),	22
    a		REGPC2,		REGPC2,		REGM2(5)
    lqa		REGPC3,		IMADDRAC(6)
    a		REGWS2(1),	REGWS2(1),	REGWS2(2)

    selb	REGFF,		REGWS2(3),	REGWS2(2),	REGWS2(1)
    a		REGWS2(3),	REGWS2(3),	REGPC2
    a		REGWS2(0),	REGWS2(0),	REGFF
    roti	REGWS2(0),	REGWS2(0),	7
    a		REGPC3,		REGPC3,		REGM2(6)
    lqa		REGPC1,		IMADDRAC(7)
    a		REGWS2(0),	REGWS2(0),	REGWS2(1)

    selb	REGFF,		REGWS2(2),	REGWS2(1),	REGWS2(0)
    a		REGWS2(2),	REGWS2(2),	REGPC3
    a		REGWS2(3),	REGWS2(3),	REGFF
    roti	REGWS2(3),	REGWS2(3),	12
    a		REGPC1,		REGPC1,		REGM2(7)
    lqa		REGPC2,		IMADDRAC(8)
    a		REGWS2(3),	REGWS2(3),	REGWS2(0)

    selb	REGFF,		REGWS2(1),	REGWS2(0),	REGWS2(3)
    a		REGWS2(1),	REGWS2(1),	REGPC1
    a		REGWS2(2),	REGWS2(2),	REGFF
    roti	REGWS2(2),	REGWS2(2),	17
    a		REGPC2,		REGPC2,		REGM2(8)
    lqa		REGPC3,		IMADDRAC(9)
    a		REGWS2(2),	REGWS2(2),	REGWS2(3)

    selb	REGFF,		REGWS2(0),	REGWS2(3),	REGWS2(2)
    a		REGWS2(0),	REGWS2(0),	REGPC2
    a		REGWS2(1),	REGWS2(1),	REGFF
    roti	REGWS2(1),	REGWS2(1),	22
    a		REGPC3,		REGPC3,		REGM2(9)
    lqa		REGPC1,		IMADDRAC(10)
    a		REGWS2(1),	REGWS2(1),	REGWS2(2)

    selb	REGFF,		REGWS2(3),	REGWS2(2),	REGWS2(1)
    a		REGWS2(3),	REGWS2(3),	REGPC3
    a		REGWS2(0),	REGWS2(0),	REGFF
    roti	REGWS2(0),	REGWS2(0),	7
    a		REGPC1,		REGPC1,		REGM2(10)
    lqa		REGPC2,		IMADDRAC(11)
    a		REGWS2(0),	REGWS2(0),	REGWS2(1)

    selb	REGFF,		REGWS2(2),	REGWS2(1),	REGWS2(0)
    a		REGWS2(2),	REGWS2(2),	REGPC1
    a		REGWS2(3),	REGWS2(3),	REGFF
    roti	REGWS2(3),	REGWS2(3),	12
    a		REGPC2,		REGPC2,		REGM2(11)
    lqa		REGPC3,		IMADDRAC(12)
    a		REGWS2(3),	REGWS2(3),	REGWS2(0)

    selb	REGFF,		REGWS2(1),	REGWS2(0),	REGWS2(3)
    a		REGWS2(1),	REGWS2(1),	REGPC2
    a		REGWS2(2),	REGWS2(2),	REGFF
    roti	REGWS2(2),	REGWS2(2),	17
    a		REGPC3,		REGPC3,		REGM2(12)
    lqa		REGPC1,		IMADDRAC(13)
    a		REGWS2(2),	REGWS2(2),	REGWS2(3)

    selb	REGFF,		REGWS2(0),	REGWS2(3),	REGWS2(2)
    a		REGWS2(0),	REGWS2(0),	REGPC3
    a		REGWS2(1),	REGWS2(1),	REGFF
    roti	REGWS2(1),	REGWS2(1),	22
    a		REGWS2(1),	REGWS2(1),	REGWS2(2)

    selb	REGFF,		REGWS2(3),	REGWS2(2),	REGWS2(1)
    a		REGWS2(3),	REGWS2(3),	REGPC1
    a		REGWS2(0),	REGWS2(0),	REGFF
    roti	REGWS2(0),	REGWS2(0),	7
    a		REGWS2(0),	REGWS2(0),	REGWS2(1)

    selb	REGFF,		REGWS2(2),	REGWS2(1),	REGWS2(0)
    a		REGWS2(3),	REGWS2(3),	REGFF

    stqa	REGWS2(0),	 0 + workingstate2
    stqa	REGWS2(1),	16 + workingstate2
    stqa	REGWS2(2),	32 + workingstate2
    stqa	REGWS2(3),	48 + workingstate2

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
    LOADREG(123)
    LOADREG(124)
    LOADREG(125)
    LOADREG(126)
    LOADREG(127)

    bi $lr











generate_trails:
// input
//	$3:	@ihv1
//	$4:	@ihv2
//	$5:	@msg1
//	$6:	@msg2
//	$7:	@a,b,c,len,rng,id,distpointmask,maxlen
//	$8:	@buffer
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
    STOREREG(123)
    STOREREG(124)
    STOREREG(125)
    STOREREG(126)
    STOREREG(127)

// load a & b and other stuff
    lqd		REGASTART,	0x00($7)
    lqd		REGBSTART,	0x10($7)
    lqd		REGCSTART,	0x20($7)
    lqd		REGA,		0x30($7)
    lqd		REGB,		0x40($7)
    lqd		REGC,		0x50($7)
    lqd		REGLEN,		0x60($7)
    lqd		REGX,		0x70($7)
    lqd		REGY,		0x80($7)
    lqd		REGZ,		0x90($7)
    lqd		REGW,		0xa0($7)
    lqd		REGID,		0xb0($7)
    lqd		REGDPMASK,	0xc0($7)
    lqd		REGMAXLEN,	0xd0($7)
    lqd		REGHBMASK,	0xe0($7)
    lqd		REGASTART2,	0xf0($7)
    lqd		REGBSTART2,	0x100($7)
    lqd		REGCSTART2,	0x110($7)
    lqd		REGA2,		0x120($7)
    lqd		REGB2,		0x130($7)
    lqd		REGC2,		0x140($7)
    lqd		REGLEN2,	0x150($7)
// load precalculated working states
    lqa		REGWS1(0),	 0 + workingstate1
    lqa		REGWS1(1),	16 + workingstate1
    lqa		REGWS1(2),	32 + workingstate1
    lqa		REGWS1(3),	48 + workingstate1
    lqa		REGWS2(0),	 0 + workingstate2
    lqa		REGWS2(1),	16 + workingstate2
    lqa		REGWS2(2),	32 + workingstate2
    lqa		REGWS2(3),	48 + workingstate2
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
md5compress_loop:
/*** ROUND 1 ***/
/*** ROUND 1 ***/
    clgt	REGSELB,	REGA,	REGB
    lqa		REGPC2,		IMADDRAC(14)
    clgt	REGSELBI,	REGA2,	REGB2
    lqa		REGPC2I,		IMADDRAC(14)
    selb	REGWS(3),	REGWS1(3),	REGWS2(3),	REGSELB
    selb	REGWSI(3),	REGWS1(3),	REGWS2(3),	REGSELBI
    selb	REGWS(0),	REGWS1(0),	REGWS2(0),	REGSELB
    selb	REGWSI(0),	REGWS1(0),	REGWS2(0),	REGSELBI
    a		REGWS(3),	REGWS(3),	REGC
    lqa		REGPC3,		IMADDRAC(15)
    a		REGWSI(3),	REGWSI(3),	REGC2
    lqa		REGPC3I,		IMADDRAC(15)
    selb	REGWS(1),	REGWS1(1),	REGWS2(1),	REGSELB
    selb	REGWSI(1),	REGWS1(1),	REGWS2(1),	REGSELBI
    roti	REGWS(3),	REGWS(3),	12    
    lqa		REGPC1,		IMADDRAC(16)
    roti	REGWSI(3),	REGWSI(3),	12    
    lqa		REGPC1I,		IMADDRAC(16)
    selb	REGWS(2),	REGWS1(2),	REGWS2(2),	REGSELB
    selb	REGWSI(2),	REGWS1(2),	REGWS2(2),	REGSELBI
    a		REGPC2,		REGPC2,		REGA
    a		REGPC2I,		REGPC2I,		REGA2
    a		REGWS(3),	REGWS(3),	REGWS(0)
    a		REGWSI(3),	REGWSI(3),	REGWSI(0)
    a		REGWS(2),	REGWS(2),	REGPC2
    a		REGWSI(2),	REGWSI(2),	REGPC2I
    selb	REGFF,		REGWS(1),	REGWS(0),	REGWS(3)
    selb	REGFFI,		REGWSI(1),	REGWSI(0),	REGWSI(3)
    a		REGPC3,		REGPC3,		REGB
    a		REGPC3I,	REGPC3I,		REGB2
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
    a		REGPC1,		REGPC1,		REGB
    lqa		REGPC2,		IMADDRAC(23)
    a		REGPC1I,		REGPC1I,		REGB2
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
    a		REGPC1,		REGPC1,		REGA
    lqa		REGPC2,		IMADDRAC(26)
    a		REGPC1I,		REGPC1I,		REGA2
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
    a		REGPC1,		REGPC1,		REGC
    lqa		REGPC2,		IMADDRAC(29)
    a		REGPC1I,		REGPC1I,		REGC2
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
    a		REGPC2,		REGPC2,		REGA
    lqa		REGPC3,		IMADDRAC(36)
    a		REGPC2I,		REGPC2I,		REGA2
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
    a		REGPC1,		REGPC1,		REGC
    lqa		REGPC2,		IMADDRAC(41)
    a		REGPC1I,		REGPC1I,		REGC2
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
    a		REGPC1,		REGPC1,		REGB
    lqa		REGPC2,		IMADDRAC(47)
    a		REGPC1I,		REGPC1I,		REGB2
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
    a		REGPC2,		REGPC2,		REGA
    lqa		REGPC3,		IMADDRAC(51)
    a		REGPC2I,		REGPC2I,		REGA2
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
    a		REGPC3,		REGPC3,		REGB
    lqa		REGPC1,		IMADDRAC(58)
    a		REGPC3I,		REGPC3I,		REGB2
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
    a		REGPC2,		REGPC2,		REGC
    lqa		REGPC3,		IMADDRAC(60)
    a		REGPC2I,		REGPC2I,		REGC2
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
    sf		REGB,		REGIHV(2),	REGIHV(3)
    sf		REGB2,		REGIHVI(2),	REGIHVI(3)
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


    sf		REGC,		REGIHV(1),	REGIHV(3)
    sf		REGC2,		REGIHVI(1),	REGIHVI(3)
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
    a		REGWS(2),	REGWS(2),	REGWS(3)
    a		REGWSI(2),	REGWSI(2),	REGWSI(3)

    ai          REGLEN,         REGLEN,         1
    hbra        md5compress_loop_end,           md5compress_loop
    ai		REGLEN2,	REGLEN2,	1
    lnop

    selb	REGFF,		REGFF1,		REGFF,		REGWS(2)
    selb	REGFFI,		REGFF1I,		REGFFI,		REGWSI(2)

    clgt	REGPC3,		REGLEN,		REGMAXLEN
    clgt	REGPC3I,	REGLEN2,	REGMAXLEN
    and		REGPC2,		REGA,		REGDPMASK
    and		REGPC2I,	REGA2,		REGDPMASK
    ceqi	REGPC2,		REGPC2,		0
    ceqi	REGPC2I,	REGPC2I,	0
    or		REGPC3,		REGPC3,		REGPC2
    or		REGPC3I,	REGPC3I,	REGPC2I

    a		REGWS(1),	REGWS(1),	REGFF
    gb		REGPC2,		REGPC3
    a		REGWSI(1),	REGWSI(1),	REGFFI
    gb		REGPC2I,	REGPC3I
    a		REGC,		REGC,		REGWS(3)
    a		REGC2,		REGC2,		REGWSI(3)
    roti	REGWS(1),	REGWS(1),	21
    roti	REGWSI(1),	REGWSI(1),	21
    or		REGPC2,		REGPC2,		REGPC2I
    sf		REGB,		REGWS(2),	REGB
    sf		REGB2,		REGWSI(2),	REGB2
    a		REGB,		REGB,		REGWS(3)
    a		REGB2,		REGB2,		REGWSI(3)
    sf		REGC,		REGWS(2),	REGC
    sf		REGC2,		REGWSI(2),	REGC2
    sf		REGC,		REGWS(1),	REGC
    sf		REGC2,		REGWSI(1),	REGC2
    and		REGC,		REGC,		REGHBMASK
    and		REGC2,		REGC2,		REGHBMASK

md5compress_loop_end:
    brz		REGPC2,		md5compress_loop

    or		REGWS(0),	REGASTART,	REGASTART
    rotqbyi	REGWS(1),	REGBSTART,	12
    or		REGIHV(0),	REGA,		REGA
    fsmbi	REGM(1),	0xF00
    fsmbi	REGM(2),	0xF0
    fsmbi	REGM(3),	0xF
    fsmbi	REGM(0),	0xF000
    selb	REGM(4),	REGWS(0),	REGWS(1),	REGM(1)
    selb	REGM(5),	REGWS(0),	REGWS(1),	REGM(2)
    rotqbyi	REGWS(2),	REGCSTART,	8
    selb	REGM(6),	REGWS(0),	REGWS(1),	REGM(3)
    rotqbyi	REGIHV(1),	REGB,		12
    selb	REGM(7),	REGWS(0),	REGWS(1),	REGM(0)
    rotqbyi	REGIHV(2),	REGC,		8
    xor		REGFF,		REGFF,		REGFF
    lnop
    selb	REGM(4),	REGM(4),	REGWS(2),	REGM(2)
    rotqbyi	REGIHV(3),	REGLEN,		4
    selb	REGM(5),	REGM(5),	REGWS(2),	REGM(3)
    selb	REGM(6),	REGM(6),	REGWS(2),	REGM(0)
    selb	REGM(7),	REGM(7),	REGWS(2),	REGM(1)
    rotqbyi	REGM(5),	REGM(5),	4
    selb	REGM(8),	REGIHV(0),	REGIHV(1),	REGM(1)
    rotqbyi	REGM(6),	REGM(6),	8
    selb	REGM(9),	REGIHV(0),	REGIHV(1),	REGM(2)
    rotqbyi	REGM(7),	REGM(7),	12
    andi	REGPC1,		REGPC3,		32    
    selb	REGM(10),	REGIHV(0),	REGIHV(1),	REGM(3)
    selb	REGM(11),	REGIHV(0),	REGIHV(1),	REGM(0)
    rotqbyi	REGM(12),	REGPC1,		12
    selb	REGM(8),	REGM(8),	REGIHV(2),	REGM(2)
    rotqbyi	REGM(13),	REGPC1,		8
    selb	REGM(9),	REGM(9),	REGIHV(2),	REGM(3)
    rotqbyi	REGM(14),	REGPC1,		4
    selb	REGM(10),	REGM(10),	REGIHV(2),	REGM(0)
    selb	REGM(11),	REGM(11),	REGIHV(2),	REGM(1)
    selb	REGM(10),	REGM(10),	REGIHV(3),	REGM(1)
    selb	REGM(11),	REGM(11),	REGIHV(3),	REGM(2)
    selb	REGM(8),	REGM(8),	REGIHV(3),	REGM(3)
    rotqbyi	REGM(10),	REGM(10),	8
    selb	REGM(9),	REGM(9),	REGIHV(3),	REGM(0)
    rotqbyi	REGM(11),	REGM(11),	12
    andc	REGLEN,		REGLEN,		REGPC3
    lnop
    selb	REGA,		REGA,		REGX,		REGPC3
    rotqbyi	REGM(9),	REGM(9),	4
    selb	REGASTART,	REGASTART,	REGX,		REGPC3
    xor		REGPC2,		REGID,		REGY
    shli    REGXA,		REGX,		5
    stqd	REGM(8),	0($8)
    rotmi   REGXB,		REGX,		-14
    stqd	REGM(4),	16($8)
    a		$8,			$8,			REGPC1  
    selb	REGB,		REGB,		REGPC2,		REGPC3
    selb	REGBSTART,	REGBSTART,	REGPC2,		REGPC3
    stqd	REGM(9),	0($8)
    rotmi   REGWC,		REGW,		-1
    stqd	REGM(5),	16($8)
    a		$8,			$8,			REGM(14)
    rotmi   REGXAB,		REGXA,		-14
    selb	REGC,		REGC,		REGW,		REGPC3
    stqd	REGM(10),	0($8)
    selb	REGCSTART,	REGCSTART,	REGW,		REGPC3
    stqd	REGM(6),	16($8)
    a		$8,			$8,			REGM(13)
    and		REGC,		REGC,		REGHBMASK
    and		REGCSTART,	REGCSTART,	REGHBMASK
    stqd	REGM(11),	0($8)
    xor     REGXA,		REGX,		REGXA
    stqd	REGM(7),	16($8)
    a		$8,			$8,			REGM(12)
    or 		REGX,		REGY,		REGY
    or		REGY,		REGZ,		REGZ
    xor     REGXA,		REGXA,		REGXB
    or 		REGZ,		REGW,		REGW
    xor     REGW,		REGW,		REGWC
    xor     REGXA,		REGXA,		REGXAB
    xor     REGW,		REGW,		REGXA

    or		REGWS(0),	REGASTART2,	REGASTART2
    rotqbyi	REGWS(1),	REGBSTART2,	12
    or		REGIHV(0),	REGA2,		REGA2
    fsmbi	REGM(1),	0xF00
    fsmbi	REGM(2),	0xF0
    fsmbi	REGM(3),	0xF
    fsmbi	REGM(0),	0xF000
    selb	REGM(4),	REGWS(0),	REGWS(1),	REGM(1)
    selb	REGM(5),	REGWS(0),	REGWS(1),	REGM(2)
    rotqbyi	REGWS(2),	REGCSTART2,	8
    selb	REGM(6),	REGWS(0),	REGWS(1),	REGM(3)
    rotqbyi	REGIHV(1),	REGB2,		12
    selb	REGM(7),	REGWS(0),	REGWS(1),	REGM(0)
    rotqbyi	REGIHV(2),	REGC2,		8
    xor		REGFF,		REGFF,		REGFF
    hbra	afterstorejump,	md5compress_loop
    selb	REGM(4),	REGM(4),	REGWS(2),	REGM(2)
    rotqbyi	REGIHV(3),	REGLEN2,		4
    selb	REGM(5),	REGM(5),	REGWS(2),	REGM(3)
    selb	REGM(6),	REGM(6),	REGWS(2),	REGM(0)
    selb	REGM(7),	REGM(7),	REGWS(2),	REGM(1)
    rotqbyi	REGM(5),	REGM(5),	4
    selb	REGM(8),	REGIHV(0),	REGIHV(1),	REGM(1)
    rotqbyi	REGM(6),	REGM(6),	8
    selb	REGM(9),	REGIHV(0),	REGIHV(1),	REGM(2)
    rotqbyi	REGM(7),	REGM(7),	12
    andi	REGPC1,		REGPC3I,	32    
    selb	REGM(10),	REGIHV(0),	REGIHV(1),	REGM(3)
    selb	REGM(11),	REGIHV(0),	REGIHV(1),	REGM(0)
    rotqbyi	REGM(12),	REGPC1,		12
    selb	REGM(8),	REGM(8),	REGIHV(2),	REGM(2)
    rotqbyi	REGM(13),	REGPC1,		8
    selb	REGM(9),	REGM(9),	REGIHV(2),	REGM(3)
    rotqbyi	REGM(14),	REGPC1,		4
    selb	REGM(10),	REGM(10),	REGIHV(2),	REGM(0)
    selb	REGM(11),	REGM(11),	REGIHV(2),	REGM(1)
    selb	REGM(10),	REGM(10),	REGIHV(3),	REGM(1)
    selb	REGM(11),	REGM(11),	REGIHV(3),	REGM(2)
    selb	REGM(8),	REGM(8),	REGIHV(3),	REGM(3)
    rotqbyi	REGM(10),	REGM(10),	8
    selb	REGM(9),	REGM(9),	REGIHV(3),	REGM(0)
    rotqbyi	REGM(11),	REGM(11),	12
    andc	REGLEN2,	REGLEN2,	REGPC3I
    lnop
    selb	REGA2,		REGA2,		REGX,		REGPC3I
    rotqbyi	REGM(9),	REGM(9),	4
    selb	REGASTART2,	REGASTART2,	REGX,		REGPC3I
    xor		REGPC2,		REGID,		REGY
    shli    REGXA,		REGX,		5
    stqd	REGM(8),	0($8)
    rotmi   REGXB,		REGX,		-14
    stqd	REGM(4),	16($8)
    a		$8,			$8,			REGPC1  
    selb	REGB2,		REGB2,		REGPC2,		REGPC3I
    selb	REGBSTART2,	REGBSTART2,	REGPC2,		REGPC3I
    stqd	REGM(9),	0($8)
    rotmi   REGWC,		REGW,		-1
    stqd	REGM(5),	16($8)
    a		$8,			$8,			REGM(14)
    rotmi   REGXAB,		REGXA,		-14
    selb	REGC2,		REGC2,		REGW,		REGPC3I
    stqd	REGM(10),	0($8)
    selb	REGCSTART2,	REGCSTART2,	REGW,		REGPC3I
    stqd	REGM(6),	16($8)
    a		$8,			$8,			REGM(13)
    and		REGC2,		REGC2,		REGHBMASK
    and		REGCSTART2,	REGCSTART2,	REGHBMASK
    stqd	REGM(11),	0($8)
    xor     REGXA,		REGX,		REGXA
    stqd	REGM(7),	16($8)
    a		$8,			$8,			REGM(12)
    or 		REGX,		REGY,		REGY
    clgt	REGPC1,		$8,			$9
    or		REGY,		REGZ,		REGZ
    xor     REGXA,		REGXA,		REGXB
    or 		REGZ,		REGW,		REGW
    xor     REGW,		REGW,		REGWC
    xor     REGXA,		REGXA,		REGXAB
    xor     REGW,		REGW,		REGXA


    
afterstorejump:
    brz		REGPC1,		md5compress_loop

    stqd	REGFF,		0($8)
    stqd	REGFF,		16($8)

    // store state to continue later
    stqd	REGASTART,	0x00($7)
    stqd	REGBSTART,	0x10($7)
    stqd	REGCSTART,	0x20($7)
    stqd	REGA,		0x30($7)
    stqd	REGB,		0x40($7)
    stqd	REGC,		0x50($7)
    stqd	REGLEN,		0x60($7)
    stqd	REGX,		0x70($7)
    stqd	REGY,		0x80($7)
    stqd	REGZ,		0x90($7)
    stqd	REGW,		0xa0($7)
    stqd	REGASTART2,	0xf0($7)
    stqd	REGBSTART2,	0x100($7)
    stqd	REGCSTART2,	0x110($7)
    stqd	REGA2,		0x120($7)
    stqd	REGB2,		0x130($7)
    stqd	REGC2,		0x140($7)
    stqd	REGLEN2,	0x150($7)

    rotqbyi	$3,			$8,			0

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
    LOADREG(123)
    LOADREG(124)
    LOADREG(125)
    LOADREG(126)
    LOADREG(127)

    bi		$lr
    .size	generate_trails,.-generate_trails
