
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	97013103          	ld	sp,-1680(sp) # 80008970 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	1dc78793          	addi	a5,a5,476 # 80006240 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	97c080e7          	jalr	-1668(ra) # 80002aa8 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	c3c080e7          	jalr	-964(ra) # 80001e00 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	440080e7          	jalr	1088(ra) # 80002614 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00003097          	auipc	ra,0x3
    80000214:	842080e7          	jalr	-1982(ra) # 80002a52 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00003097          	auipc	ra,0x3
    800002f6:	80c080e7          	jalr	-2036(ra) # 80002afe <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	36c080e7          	jalr	876(ra) # 800027b2 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	9e078793          	addi	a5,a5,-1568 # 80021e58 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	f12080e7          	jalr	-238(ra) # 800027b2 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	ce8080e7          	jalr	-792(ra) # 80002614 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	260080e7          	jalr	608(ra) # 80001dde <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	22e080e7          	jalr	558(ra) # 80001dde <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	222080e7          	jalr	546(ra) # 80001dde <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	20a080e7          	jalr	522(ra) # 80001dde <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	1ca080e7          	jalr	458(ra) # 80001dde <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	19e080e7          	jalr	414(ra) # 80001dde <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	f38080e7          	jalr	-200(ra) # 80001dce <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	f1c080e7          	jalr	-228(ra) # 80001dce <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	e56080e7          	jalr	-426(ra) # 80002d2a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	3a4080e7          	jalr	932(ra) # 80006280 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	524080e7          	jalr	1316(ra) # 80002408 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	d86080e7          	jalr	-634(ra) # 80001cca <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	db6080e7          	jalr	-586(ra) # 80002d02 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	dd6080e7          	jalr	-554(ra) # 80002d2a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	30e080e7          	jalr	782(ra) # 8000626a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	31c080e7          	jalr	796(ra) # 80006280 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	500080e7          	jalr	1280(ra) # 8000346c <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	b90080e7          	jalr	-1136(ra) # 80003b04 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	b3a080e7          	jalr	-1222(ra) # 80004ab6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	41e080e7          	jalr	1054(ra) # 800063a2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	200080e7          	jalr	512(ra) # 8000218c <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00001097          	auipc	ra,0x1
    80001244:	9f4080e7          	jalr	-1548(ra) # 80001c34 <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <increment_cpu_process_count>:
struct linked_list unused_list = {-1};   // contains all UNUSED process entries.
struct linked_list sleeping_list = {-1}; // contains all SLEEPING processes.
struct linked_list zombie_list = {-1};   // contains all ZOMBIE processes.

void 
increment_cpu_process_count(struct cpu *c){
    8000183e:	1101                	addi	sp,sp,-32
    80001840:	ec06                	sd	ra,24(sp)
    80001842:	e822                	sd	s0,16(sp)
    80001844:	e426                	sd	s1,8(sp)
    80001846:	e04a                	sd	s2,0(sp)
    80001848:	1000                	addi	s0,sp,32
    8000184a:	84aa                	mv	s1,a0
  uint64 curr_count;
  do{
    curr_count = c->proc_cnt;
  }while(cas(&(c->proc_cnt), curr_count, curr_count+1));
    8000184c:	08050913          	addi	s2,a0,128
    curr_count = c->proc_cnt;
    80001850:	0804a583          	lw	a1,128(s1)
  }while(cas(&(c->proc_cnt), curr_count, curr_count+1));
    80001854:	0015861b          	addiw	a2,a1,1
    80001858:	854a                	mv	a0,s2
    8000185a:	00005097          	auipc	ra,0x5
    8000185e:	02c080e7          	jalr	44(ra) # 80006886 <cas>
    80001862:	2501                	sext.w	a0,a0
    80001864:	f575                	bnez	a0,80001850 <increment_cpu_process_count+0x12>
}
    80001866:	60e2                	ld	ra,24(sp)
    80001868:	6442                	ld	s0,16(sp)
    8000186a:	64a2                	ld	s1,8(sp)
    8000186c:	6902                	ld	s2,0(sp)
    8000186e:	6105                	addi	sp,sp,32
    80001870:	8082                	ret

0000000080001872 <print_list>:

void
print_list(struct linked_list lst){
    80001872:	7139                	addi	sp,sp,-64
    80001874:	fc06                	sd	ra,56(sp)
    80001876:	f822                	sd	s0,48(sp)
    80001878:	f426                	sd	s1,40(sp)
    8000187a:	f04a                	sd	s2,32(sp)
    8000187c:	ec4e                	sd	s3,24(sp)
    8000187e:	e852                	sd	s4,16(sp)
    80001880:	e456                	sd	s5,8(sp)
    80001882:	0080                	addi	s0,sp,64
  int curr = lst.head;
    80001884:	4104                	lw	s1,0(a0)
  printf("\n[ ");
    80001886:	00007517          	auipc	a0,0x7
    8000188a:	95250513          	addi	a0,a0,-1710 # 800081d8 <digits+0x198>
    8000188e:	fffff097          	auipc	ra,0xfffff
    80001892:	cfa080e7          	jalr	-774(ra) # 80000588 <printf>
  while(curr != -1){
    80001896:	57fd                	li	a5,-1
    80001898:	02f48a63          	beq	s1,a5,800018cc <print_list+0x5a>
    printf(" %d,", curr);
    8000189c:	00007a97          	auipc	s5,0x7
    800018a0:	944a8a93          	addi	s5,s5,-1724 # 800081e0 <digits+0x1a0>
    curr = proc[curr].next_proc;
    800018a4:	00010a17          	auipc	s4,0x10
    800018a8:	f6ca0a13          	addi	s4,s4,-148 # 80011810 <proc>
    800018ac:	19000993          	li	s3,400
  while(curr != -1){
    800018b0:	597d                	li	s2,-1
    printf(" %d,", curr);
    800018b2:	85a6                	mv	a1,s1
    800018b4:	8556                	mv	a0,s5
    800018b6:	fffff097          	auipc	ra,0xfffff
    800018ba:	cd2080e7          	jalr	-814(ra) # 80000588 <printf>
    curr = proc[curr].next_proc;
    800018be:	033484b3          	mul	s1,s1,s3
    800018c2:	94d2                	add	s1,s1,s4
    800018c4:	16c4a483          	lw	s1,364(s1)
  while(curr != -1){
    800018c8:	ff2495e3          	bne	s1,s2,800018b2 <print_list+0x40>
  }
  printf(" ]\n");
    800018cc:	00007517          	auipc	a0,0x7
    800018d0:	91c50513          	addi	a0,a0,-1764 # 800081e8 <digits+0x1a8>
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	cb4080e7          	jalr	-844(ra) # 80000588 <printf>
}
    800018dc:	70e2                	ld	ra,56(sp)
    800018de:	7442                	ld	s0,48(sp)
    800018e0:	74a2                	ld	s1,40(sp)
    800018e2:	7902                	ld	s2,32(sp)
    800018e4:	69e2                	ld	s3,24(sp)
    800018e6:	6a42                	ld	s4,16(sp)
    800018e8:	6aa2                	ld	s5,8(sp)
    800018ea:	6121                	addi	sp,sp,64
    800018ec:	8082                	ret

00000000800018ee <initialize_list>:


void initialize_list(struct linked_list *lst){
    800018ee:	1101                	addi	sp,sp,-32
    800018f0:	ec06                	sd	ra,24(sp)
    800018f2:	e822                	sd	s0,16(sp)
    800018f4:	e426                	sd	s1,8(sp)
    800018f6:	e04a                	sd	s2,0(sp)
    800018f8:	1000                	addi	s0,sp,32
    800018fa:	84aa                	mv	s1,a0
  acquire(&lst->head_lock);
    800018fc:	00850913          	addi	s2,a0,8
    80001900:	854a                	mv	a0,s2
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	2e2080e7          	jalr	738(ra) # 80000be4 <acquire>
  lst->head = -1;
    8000190a:	57fd                	li	a5,-1
    8000190c:	c09c                	sw	a5,0(s1)
  acquire(&lst->head_lock);
    8000190e:	854a                	mv	a0,s2
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	2d4080e7          	jalr	724(ra) # 80000be4 <acquire>
}
    80001918:	60e2                	ld	ra,24(sp)
    8000191a:	6442                	ld	s0,16(sp)
    8000191c:	64a2                	ld	s1,8(sp)
    8000191e:	6902                	ld	s2,0(sp)
    80001920:	6105                	addi	sp,sp,32
    80001922:	8082                	ret

0000000080001924 <initialize_lists>:

void initialize_lists(void){
    80001924:	7179                	addi	sp,sp,-48
    80001926:	f406                	sd	ra,40(sp)
    80001928:	f022                	sd	s0,32(sp)
    8000192a:	ec26                	sd	s1,24(sp)
    8000192c:	e84a                	sd	s2,16(sp)
    8000192e:	e44e                	sd	s3,8(sp)
    80001930:	e052                	sd	s4,0(sp)
    80001932:	1800                	addi	s0,sp,48
  struct cpu *c;
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001934:	00010497          	auipc	s1,0x10
    80001938:	96c48493          	addi	s1,s1,-1684 # 800112a0 <cpus>
    c->runnable_list = (struct linked_list){-1};
    8000193c:	5a7d                	li	s4,-1
    initlock(&c->runnable_list.head_lock, "cpu_runnable_list - head lock");
    8000193e:	00007997          	auipc	s3,0x7
    80001942:	8b298993          	addi	s3,s3,-1870 # 800081f0 <digits+0x1b0>
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001946:	00010917          	auipc	s2,0x10
    8000194a:	e9a90913          	addi	s2,s2,-358 # 800117e0 <pid_lock>
    c->runnable_list = (struct linked_list){-1};
    8000194e:	0804b423          	sd	zero,136(s1)
    80001952:	0804b823          	sd	zero,144(s1)
    80001956:	0804bc23          	sd	zero,152(s1)
    8000195a:	0a04b023          	sd	zero,160(s1)
    8000195e:	0944a423          	sw	s4,136(s1)
    initlock(&c->runnable_list.head_lock, "cpu_runnable_list - head lock");
    80001962:	85ce                	mv	a1,s3
    80001964:	09048513          	addi	a0,s1,144
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	1ec080e7          	jalr	492(ra) # 80000b54 <initlock>
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001970:	0a848493          	addi	s1,s1,168
    80001974:	fd249de3          	bne	s1,s2,8000194e <initialize_lists+0x2a>
  }
  initlock(&unused_list.head_lock, "unused_list - head lock");
    80001978:	00007597          	auipc	a1,0x7
    8000197c:	89858593          	addi	a1,a1,-1896 # 80008210 <digits+0x1d0>
    80001980:	00007517          	auipc	a0,0x7
    80001984:	f5850513          	addi	a0,a0,-168 # 800088d8 <unused_list+0x8>
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	1cc080e7          	jalr	460(ra) # 80000b54 <initlock>
  initlock(&sleeping_list.head_lock, "sleeping_list - head lock");
    80001990:	00007597          	auipc	a1,0x7
    80001994:	89858593          	addi	a1,a1,-1896 # 80008228 <digits+0x1e8>
    80001998:	00007517          	auipc	a0,0x7
    8000199c:	f6050513          	addi	a0,a0,-160 # 800088f8 <sleeping_list+0x8>
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	1b4080e7          	jalr	436(ra) # 80000b54 <initlock>
  initlock(&zombie_list.head_lock, "zombie_list - head lock");
    800019a8:	00007597          	auipc	a1,0x7
    800019ac:	8a058593          	addi	a1,a1,-1888 # 80008248 <digits+0x208>
    800019b0:	00007517          	auipc	a0,0x7
    800019b4:	f6850513          	addi	a0,a0,-152 # 80008918 <zombie_list+0x8>
    800019b8:	fffff097          	auipc	ra,0xfffff
    800019bc:	19c080e7          	jalr	412(ra) # 80000b54 <initlock>
}
    800019c0:	70a2                	ld	ra,40(sp)
    800019c2:	7402                	ld	s0,32(sp)
    800019c4:	64e2                	ld	s1,24(sp)
    800019c6:	6942                	ld	s2,16(sp)
    800019c8:	69a2                	ld	s3,8(sp)
    800019ca:	6a02                	ld	s4,0(sp)
    800019cc:	6145                	addi	sp,sp,48
    800019ce:	8082                	ret

00000000800019d0 <initialize_proc>:

void
initialize_proc(struct proc *p){
    800019d0:	1141                	addi	sp,sp,-16
    800019d2:	e422                	sd	s0,8(sp)
    800019d4:	0800                	addi	s0,sp,16
  p->next_proc = -1;
    800019d6:	57fd                	li	a5,-1
    800019d8:	16f52623          	sw	a5,364(a0)
  p->prev_proc = -1;
    800019dc:	16f52823          	sw	a5,368(a0)
}
    800019e0:	6422                	ld	s0,8(sp)
    800019e2:	0141                	addi	sp,sp,16
    800019e4:	8082                	ret

00000000800019e6 <isEmpty>:

int
isEmpty(struct linked_list *lst){
    800019e6:	1141                	addi	sp,sp,-16
    800019e8:	e422                	sd	s0,8(sp)
    800019ea:	0800                	addi	s0,sp,16
  return lst->head == -1;
    800019ec:	4108                	lw	a0,0(a0)
    800019ee:	0505                	addi	a0,a0,1
}
    800019f0:	00153513          	seqz	a0,a0
    800019f4:	6422                	ld	s0,8(sp)
    800019f6:	0141                	addi	sp,sp,16
    800019f8:	8082                	ret

00000000800019fa <get_head>:

int 
get_head(struct linked_list *lst){
    800019fa:	1101                	addi	sp,sp,-32
    800019fc:	ec06                	sd	ra,24(sp)
    800019fe:	e822                	sd	s0,16(sp)
    80001a00:	e426                	sd	s1,8(sp)
    80001a02:	e04a                	sd	s2,0(sp)
    80001a04:	1000                	addi	s0,sp,32
    80001a06:	84aa                	mv	s1,a0
  acquire(&lst->head_lock); 
    80001a08:	00850913          	addi	s2,a0,8
    80001a0c:	854a                	mv	a0,s2
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	1d6080e7          	jalr	470(ra) # 80000be4 <acquire>
  int output = lst->head;
    80001a16:	4084                	lw	s1,0(s1)
  release(&lst->head_lock);
    80001a18:	854a                	mv	a0,s2
    80001a1a:	fffff097          	auipc	ra,0xfffff
    80001a1e:	27e080e7          	jalr	638(ra) # 80000c98 <release>
  return output;
}
    80001a22:	8526                	mv	a0,s1
    80001a24:	60e2                	ld	ra,24(sp)
    80001a26:	6442                	ld	s0,16(sp)
    80001a28:	64a2                	ld	s1,8(sp)
    80001a2a:	6902                	ld	s2,0(sp)
    80001a2c:	6105                	addi	sp,sp,32
    80001a2e:	8082                	ret

0000000080001a30 <set_prev_proc>:

void set_prev_proc(struct proc *p, int value){
    80001a30:	1141                	addi	sp,sp,-16
    80001a32:	e422                	sd	s0,8(sp)
    80001a34:	0800                	addi	s0,sp,16
  p->prev_proc = value; 
    80001a36:	16b52823          	sw	a1,368(a0)
}
    80001a3a:	6422                	ld	s0,8(sp)
    80001a3c:	0141                	addi	sp,sp,16
    80001a3e:	8082                	ret

0000000080001a40 <set_next_proc>:

void set_next_proc(struct proc *p, int value){
    80001a40:	1141                	addi	sp,sp,-16
    80001a42:	e422                	sd	s0,8(sp)
    80001a44:	0800                	addi	s0,sp,16
  p->next_proc = value; 
    80001a46:	16b52623          	sw	a1,364(a0)
}
    80001a4a:	6422                	ld	s0,8(sp)
    80001a4c:	0141                	addi	sp,sp,16
    80001a4e:	8082                	ret

0000000080001a50 <append>:

void 
append(struct linked_list *lst, struct proc *p){
    80001a50:	7139                	addi	sp,sp,-64
    80001a52:	fc06                	sd	ra,56(sp)
    80001a54:	f822                	sd	s0,48(sp)
    80001a56:	f426                	sd	s1,40(sp)
    80001a58:	f04a                	sd	s2,32(sp)
    80001a5a:	ec4e                	sd	s3,24(sp)
    80001a5c:	e852                	sd	s4,16(sp)
    80001a5e:	e456                	sd	s5,8(sp)
    80001a60:	0080                	addi	s0,sp,64
    80001a62:	84aa                	mv	s1,a0
    80001a64:	892e                	mv	s2,a1
  acquire(&lst->head_lock);
    80001a66:	00850993          	addi	s3,a0,8
    80001a6a:	854e                	mv	a0,s3
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	178080e7          	jalr	376(ra) # 80000be4 <acquire>
  if(isEmpty(lst)){
    80001a74:	4098                	lw	a4,0(s1)
    80001a76:	57fd                	li	a5,-1
    80001a78:	04f71063          	bne	a4,a5,80001ab8 <append+0x68>
    lst->head = p->proc_ind;
    80001a7c:	17492783          	lw	a5,372(s2)
    80001a80:	c09c                	sw	a5,0(s1)
    // lst->tail = p->proc_ind;
    release(&lst->head_lock);
    80001a82:	854e                	mv	a0,s3
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	214080e7          	jalr	532(ra) # 80000c98 <release>
    // }
    set_next_proc(&proc[lst->tail], p->proc_ind);  // update next proc of the curr tail
    set_prev_proc(p, proc[lst->tail].proc_ind); // update the prev proc of the new proc
    release(&proc[lst->tail].list_lock);
  }
  acquire(&lst->head_lock);
    80001a8c:	854e                	mv	a0,s3
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	156080e7          	jalr	342(ra) # 80000be4 <acquire>
  lst->tail = p->proc_ind;
    80001a96:	17492783          	lw	a5,372(s2)
    80001a9a:	c0dc                	sw	a5,4(s1)
  release(&lst->head_lock);
    80001a9c:	854e                	mv	a0,s3
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	1fa080e7          	jalr	506(ra) # 80000c98 <release>
}
    80001aa6:	70e2                	ld	ra,56(sp)
    80001aa8:	7442                	ld	s0,48(sp)
    80001aaa:	74a2                	ld	s1,40(sp)
    80001aac:	7902                	ld	s2,32(sp)
    80001aae:	69e2                	ld	s3,24(sp)
    80001ab0:	6a42                	ld	s4,16(sp)
    80001ab2:	6aa2                	ld	s5,8(sp)
    80001ab4:	6121                	addi	sp,sp,64
    80001ab6:	8082                	ret
    acquire(&proc[lst->tail].list_lock);
    80001ab8:	40c8                	lw	a0,4(s1)
    80001aba:	19000a93          	li	s5,400
    80001abe:	03550533          	mul	a0,a0,s5
    80001ac2:	17850513          	addi	a0,a0,376
    80001ac6:	00010a17          	auipc	s4,0x10
    80001aca:	d4aa0a13          	addi	s4,s4,-694 # 80011810 <proc>
    80001ace:	9552                	add	a0,a0,s4
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	114080e7          	jalr	276(ra) # 80000be4 <acquire>
    release(&lst->head_lock);
    80001ad8:	854e                	mv	a0,s3
    80001ada:	fffff097          	auipc	ra,0xfffff
    80001ade:	1be080e7          	jalr	446(ra) # 80000c98 <release>
    set_next_proc(&proc[lst->tail], p->proc_ind);  // update next proc of the curr tail
    80001ae2:	40dc                	lw	a5,4(s1)
    80001ae4:	17492703          	lw	a4,372(s2)
  p->next_proc = value; 
    80001ae8:	035787b3          	mul	a5,a5,s5
    80001aec:	97d2                	add	a5,a5,s4
    80001aee:	16e7a623          	sw	a4,364(a5)
    set_prev_proc(p, proc[lst->tail].proc_ind); // update the prev proc of the new proc
    80001af2:	40dc                	lw	a5,4(s1)
    80001af4:	035787b3          	mul	a5,a5,s5
    80001af8:	97d2                	add	a5,a5,s4
    80001afa:	1747a783          	lw	a5,372(a5)
  p->prev_proc = value; 
    80001afe:	16f92823          	sw	a5,368(s2)
    release(&proc[lst->tail].list_lock);
    80001b02:	40c8                	lw	a0,4(s1)
    80001b04:	03550533          	mul	a0,a0,s5
    80001b08:	17850513          	addi	a0,a0,376
    80001b0c:	9552                	add	a0,a0,s4
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	18a080e7          	jalr	394(ra) # 80000c98 <release>
    80001b16:	bf9d                	j	80001a8c <append+0x3c>

0000000080001b18 <remove>:

void 
remove(struct linked_list *lst, struct proc *p){
    80001b18:	7179                	addi	sp,sp,-48
    80001b1a:	f406                	sd	ra,40(sp)
    80001b1c:	f022                	sd	s0,32(sp)
    80001b1e:	ec26                	sd	s1,24(sp)
    80001b20:	e84a                	sd	s2,16(sp)
    80001b22:	e44e                	sd	s3,8(sp)
    80001b24:	e052                	sd	s4,0(sp)
    80001b26:	1800                	addi	s0,sp,48
    80001b28:	892a                	mv	s2,a0
    80001b2a:	84ae                	mv	s1,a1
  acquire(&lst->head_lock);
    80001b2c:	00850993          	addi	s3,a0,8
    80001b30:	854e                	mv	a0,s3
    80001b32:	fffff097          	auipc	ra,0xfffff
    80001b36:	0b2080e7          	jalr	178(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80001b3a:	00092783          	lw	a5,0(s2)
  if(isEmpty(lst)){
    80001b3e:	577d                	li	a4,-1
    80001b40:	0ae78263          	beq	a5,a4,80001be4 <remove+0xcc>
    release(&lst->head_lock);
    panic("list is empty\n");
  }

  if(lst->head == p->proc_ind){ // the required proc is the head
    80001b44:	1744a703          	lw	a4,372(s1)
    80001b48:	0af70b63          	beq	a4,a5,80001bfe <remove+0xe6>
    lst->head = p->next_proc;
    set_prev_proc(&proc[p->next_proc], -1);
    release(&lst->head_lock);
  }
  else{
    if (lst->tail == p->proc_ind) {
    80001b4c:	00492783          	lw	a5,4(s2)
    80001b50:	0ce78d63          	beq	a5,a4,80001c2a <remove+0x112>
      lst->tail = p->prev_proc;
    }
    release(&lst->head_lock); 
    80001b54:	854e                	mv	a0,s3
    80001b56:	fffff097          	auipc	ra,0xfffff
    80001b5a:	142080e7          	jalr	322(ra) # 80000c98 <release>
    acquire(&p->list_lock);
    80001b5e:	17848993          	addi	s3,s1,376
    80001b62:	854e                	mv	a0,s3
    80001b64:	fffff097          	auipc	ra,0xfffff
    80001b68:	080080e7          	jalr	128(ra) # 80000be4 <acquire>
    acquire(&proc[p->prev_proc].list_lock);
    80001b6c:	1704a503          	lw	a0,368(s1)
    80001b70:	19000a13          	li	s4,400
    80001b74:	03450533          	mul	a0,a0,s4
    80001b78:	17850513          	addi	a0,a0,376
    80001b7c:	00010917          	auipc	s2,0x10
    80001b80:	c9490913          	addi	s2,s2,-876 # 80011810 <proc>
    80001b84:	954a                	add	a0,a0,s2
    80001b86:	fffff097          	auipc	ra,0xfffff
    80001b8a:	05e080e7          	jalr	94(ra) # 80000be4 <acquire>
    set_next_proc(&proc[p->prev_proc], p->next_proc);
    80001b8e:	1704a703          	lw	a4,368(s1)
    80001b92:	16c4a783          	lw	a5,364(s1)
  p->next_proc = value; 
    80001b96:	03470733          	mul	a4,a4,s4
    80001b9a:	974a                	add	a4,a4,s2
    80001b9c:	16f72623          	sw	a5,364(a4)
    set_prev_proc(&proc[p->next_proc], p->prev_proc);
    80001ba0:	1704a503          	lw	a0,368(s1)
  p->prev_proc = value; 
    80001ba4:	034787b3          	mul	a5,a5,s4
    80001ba8:	97ca                	add	a5,a5,s2
    80001baa:	16a7a823          	sw	a0,368(a5)
    release(&proc[p->prev_proc].list_lock);
    80001bae:	03450533          	mul	a0,a0,s4
    80001bb2:	17850513          	addi	a0,a0,376
    80001bb6:	954a                	add	a0,a0,s2
    80001bb8:	fffff097          	auipc	ra,0xfffff
    80001bbc:	0e0080e7          	jalr	224(ra) # 80000c98 <release>
    release(&p->list_lock);
    80001bc0:	854e                	mv	a0,s3
    80001bc2:	fffff097          	auipc	ra,0xfffff
    80001bc6:	0d6080e7          	jalr	214(ra) # 80000c98 <release>
  p->next_proc = -1;
    80001bca:	57fd                	li	a5,-1
    80001bcc:	16f4a623          	sw	a5,364(s1)
  p->prev_proc = -1;
    80001bd0:	16f4a823          	sw	a5,368(s1)
  }
  initialize_proc(p);
}
    80001bd4:	70a2                	ld	ra,40(sp)
    80001bd6:	7402                	ld	s0,32(sp)
    80001bd8:	64e2                	ld	s1,24(sp)
    80001bda:	6942                	ld	s2,16(sp)
    80001bdc:	69a2                	ld	s3,8(sp)
    80001bde:	6a02                	ld	s4,0(sp)
    80001be0:	6145                	addi	sp,sp,48
    80001be2:	8082                	ret
    release(&lst->head_lock);
    80001be4:	854e                	mv	a0,s3
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
    panic("list is empty\n");
    80001bee:	00006517          	auipc	a0,0x6
    80001bf2:	67250513          	addi	a0,a0,1650 # 80008260 <digits+0x220>
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	948080e7          	jalr	-1720(ra) # 8000053e <panic>
    lst->head = p->next_proc;
    80001bfe:	16c4a783          	lw	a5,364(s1)
    80001c02:	00f92023          	sw	a5,0(s2)
  p->prev_proc = value; 
    80001c06:	19000713          	li	a4,400
    80001c0a:	02e787b3          	mul	a5,a5,a4
    80001c0e:	00010717          	auipc	a4,0x10
    80001c12:	c0270713          	addi	a4,a4,-1022 # 80011810 <proc>
    80001c16:	97ba                	add	a5,a5,a4
    80001c18:	577d                	li	a4,-1
    80001c1a:	16e7a823          	sw	a4,368(a5)
    release(&lst->head_lock);
    80001c1e:	854e                	mv	a0,s3
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	078080e7          	jalr	120(ra) # 80000c98 <release>
    80001c28:	b74d                	j	80001bca <remove+0xb2>
      lst->tail = p->prev_proc;
    80001c2a:	1704a783          	lw	a5,368(s1)
    80001c2e:	00f92223          	sw	a5,4(s2)
    80001c32:	b70d                	j	80001b54 <remove+0x3c>

0000000080001c34 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001c34:	7139                	addi	sp,sp,-64
    80001c36:	fc06                	sd	ra,56(sp)
    80001c38:	f822                	sd	s0,48(sp)
    80001c3a:	f426                	sd	s1,40(sp)
    80001c3c:	f04a                	sd	s2,32(sp)
    80001c3e:	ec4e                	sd	s3,24(sp)
    80001c40:	e852                	sd	s4,16(sp)
    80001c42:	e456                	sd	s5,8(sp)
    80001c44:	e05a                	sd	s6,0(sp)
    80001c46:	0080                	addi	s0,sp,64
    80001c48:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c4a:	00010497          	auipc	s1,0x10
    80001c4e:	bc648493          	addi	s1,s1,-1082 # 80011810 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001c52:	8b26                	mv	s6,s1
    80001c54:	00006a97          	auipc	s5,0x6
    80001c58:	3aca8a93          	addi	s5,s5,940 # 80008000 <etext>
    80001c5c:	04000937          	lui	s2,0x4000
    80001c60:	197d                	addi	s2,s2,-1
    80001c62:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c64:	00016a17          	auipc	s4,0x16
    80001c68:	faca0a13          	addi	s4,s4,-84 # 80017c10 <tickslock>
    char *pa = kalloc();
    80001c6c:	fffff097          	auipc	ra,0xfffff
    80001c70:	e88080e7          	jalr	-376(ra) # 80000af4 <kalloc>
    80001c74:	862a                	mv	a2,a0
    if(pa == 0)
    80001c76:	c131                	beqz	a0,80001cba <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001c78:	416485b3          	sub	a1,s1,s6
    80001c7c:	8591                	srai	a1,a1,0x4
    80001c7e:	000ab783          	ld	a5,0(s5)
    80001c82:	02f585b3          	mul	a1,a1,a5
    80001c86:	2585                	addiw	a1,a1,1
    80001c88:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001c8c:	4719                	li	a4,6
    80001c8e:	6685                	lui	a3,0x1
    80001c90:	40b905b3          	sub	a1,s2,a1
    80001c94:	854e                	mv	a0,s3
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	4ba080e7          	jalr	1210(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c9e:	19048493          	addi	s1,s1,400
    80001ca2:	fd4495e3          	bne	s1,s4,80001c6c <proc_mapstacks+0x38>
  }
}
    80001ca6:	70e2                	ld	ra,56(sp)
    80001ca8:	7442                	ld	s0,48(sp)
    80001caa:	74a2                	ld	s1,40(sp)
    80001cac:	7902                	ld	s2,32(sp)
    80001cae:	69e2                	ld	s3,24(sp)
    80001cb0:	6a42                	ld	s4,16(sp)
    80001cb2:	6aa2                	ld	s5,8(sp)
    80001cb4:	6b02                	ld	s6,0(sp)
    80001cb6:	6121                	addi	sp,sp,64
    80001cb8:	8082                	ret
      panic("kalloc");
    80001cba:	00006517          	auipc	a0,0x6
    80001cbe:	5b650513          	addi	a0,a0,1462 # 80008270 <digits+0x230>
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	87c080e7          	jalr	-1924(ra) # 8000053e <panic>

0000000080001cca <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001cca:	711d                	addi	sp,sp,-96
    80001ccc:	ec86                	sd	ra,88(sp)
    80001cce:	e8a2                	sd	s0,80(sp)
    80001cd0:	e4a6                	sd	s1,72(sp)
    80001cd2:	e0ca                	sd	s2,64(sp)
    80001cd4:	fc4e                	sd	s3,56(sp)
    80001cd6:	f852                	sd	s4,48(sp)
    80001cd8:	f456                	sd	s5,40(sp)
    80001cda:	f05a                	sd	s6,32(sp)
    80001cdc:	ec5e                	sd	s7,24(sp)
    80001cde:	e862                	sd	s8,16(sp)
    80001ce0:	e466                	sd	s9,8(sp)
    80001ce2:	e06a                	sd	s10,0(sp)
    80001ce4:	1080                	addi	s0,sp,96
  struct proc *p;

  initialize_lists();
    80001ce6:	00000097          	auipc	ra,0x0
    80001cea:	c3e080e7          	jalr	-962(ra) # 80001924 <initialize_lists>

  initlock(&pid_lock, "nextpid");
    80001cee:	00006597          	auipc	a1,0x6
    80001cf2:	58a58593          	addi	a1,a1,1418 # 80008278 <digits+0x238>
    80001cf6:	00010517          	auipc	a0,0x10
    80001cfa:	aea50513          	addi	a0,a0,-1302 # 800117e0 <pid_lock>
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	e56080e7          	jalr	-426(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001d06:	00006597          	auipc	a1,0x6
    80001d0a:	57a58593          	addi	a1,a1,1402 # 80008280 <digits+0x240>
    80001d0e:	00010517          	auipc	a0,0x10
    80001d12:	aea50513          	addi	a0,a0,-1302 # 800117f8 <wait_lock>
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	e3e080e7          	jalr	-450(ra) # 80000b54 <initlock>

  int i = 0;
    80001d1e:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d20:	00010497          	auipc	s1,0x10
    80001d24:	af048493          	addi	s1,s1,-1296 # 80011810 <proc>
      initlock(&p->lock, "proc");
    80001d28:	00006d17          	auipc	s10,0x6
    80001d2c:	568d0d13          	addi	s10,s10,1384 # 80008290 <digits+0x250>
      initlock(&p->list_lock, "list_lock");
    80001d30:	00006c97          	auipc	s9,0x6
    80001d34:	568c8c93          	addi	s9,s9,1384 # 80008298 <digits+0x258>
      p->kstack = KSTACK((int) (p - proc));
    80001d38:	8c26                	mv	s8,s1
    80001d3a:	00006b97          	auipc	s7,0x6
    80001d3e:	2c6b8b93          	addi	s7,s7,710 # 80008000 <etext>
    80001d42:	04000a37          	lui	s4,0x4000
    80001d46:	1a7d                	addi	s4,s4,-1
    80001d48:	0a32                	slli	s4,s4,0xc
  p->next_proc = -1;
    80001d4a:	59fd                	li	s3,-1
      p->proc_ind = i;
      initialize_proc(p);
      append(&unused_list, p); // procinit to admit all UNUSED process entries
    80001d4c:	00007b17          	auipc	s6,0x7
    80001d50:	b84b0b13          	addi	s6,s6,-1148 # 800088d0 <unused_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d54:	00016a97          	auipc	s5,0x16
    80001d58:	ebca8a93          	addi	s5,s5,-324 # 80017c10 <tickslock>
      initlock(&p->lock, "proc");
    80001d5c:	85ea                	mv	a1,s10
    80001d5e:	8526                	mv	a0,s1
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	df4080e7          	jalr	-524(ra) # 80000b54 <initlock>
      initlock(&p->list_lock, "list_lock");
    80001d68:	85e6                	mv	a1,s9
    80001d6a:	17848513          	addi	a0,s1,376
    80001d6e:	fffff097          	auipc	ra,0xfffff
    80001d72:	de6080e7          	jalr	-538(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001d76:	418487b3          	sub	a5,s1,s8
    80001d7a:	8791                	srai	a5,a5,0x4
    80001d7c:	000bb703          	ld	a4,0(s7)
    80001d80:	02e787b3          	mul	a5,a5,a4
    80001d84:	2785                	addiw	a5,a5,1
    80001d86:	00d7979b          	slliw	a5,a5,0xd
    80001d8a:	40fa07b3          	sub	a5,s4,a5
    80001d8e:	e0bc                	sd	a5,64(s1)
      p->proc_ind = i;
    80001d90:	1724aa23          	sw	s2,372(s1)
  p->next_proc = -1;
    80001d94:	1734a623          	sw	s3,364(s1)
  p->prev_proc = -1;
    80001d98:	1734a823          	sw	s3,368(s1)
      append(&unused_list, p); // procinit to admit all UNUSED process entries
    80001d9c:	85a6                	mv	a1,s1
    80001d9e:	855a                	mv	a0,s6
    80001da0:	00000097          	auipc	ra,0x0
    80001da4:	cb0080e7          	jalr	-848(ra) # 80001a50 <append>
      i++;
    80001da8:	2905                	addiw	s2,s2,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80001daa:	19048493          	addi	s1,s1,400
    80001dae:	fb5497e3          	bne	s1,s5,80001d5c <procinit+0x92>
  }
}
    80001db2:	60e6                	ld	ra,88(sp)
    80001db4:	6446                	ld	s0,80(sp)
    80001db6:	64a6                	ld	s1,72(sp)
    80001db8:	6906                	ld	s2,64(sp)
    80001dba:	79e2                	ld	s3,56(sp)
    80001dbc:	7a42                	ld	s4,48(sp)
    80001dbe:	7aa2                	ld	s5,40(sp)
    80001dc0:	7b02                	ld	s6,32(sp)
    80001dc2:	6be2                	ld	s7,24(sp)
    80001dc4:	6c42                	ld	s8,16(sp)
    80001dc6:	6ca2                	ld	s9,8(sp)
    80001dc8:	6d02                	ld	s10,0(sp)
    80001dca:	6125                	addi	sp,sp,96
    80001dcc:	8082                	ret

0000000080001dce <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001dce:	1141                	addi	sp,sp,-16
    80001dd0:	e422                	sd	s0,8(sp)
    80001dd2:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001dd4:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001dd6:	2501                	sext.w	a0,a0
    80001dd8:	6422                	ld	s0,8(sp)
    80001dda:	0141                	addi	sp,sp,16
    80001ddc:	8082                	ret

0000000080001dde <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001dde:	1141                	addi	sp,sp,-16
    80001de0:	e422                	sd	s0,8(sp)
    80001de2:	0800                	addi	s0,sp,16
    80001de4:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001de6:	2781                	sext.w	a5,a5
    80001de8:	0a800513          	li	a0,168
    80001dec:	02a787b3          	mul	a5,a5,a0
  return c;
}
    80001df0:	0000f517          	auipc	a0,0xf
    80001df4:	4b050513          	addi	a0,a0,1200 # 800112a0 <cpus>
    80001df8:	953e                	add	a0,a0,a5
    80001dfa:	6422                	ld	s0,8(sp)
    80001dfc:	0141                	addi	sp,sp,16
    80001dfe:	8082                	ret

0000000080001e00 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001e00:	1101                	addi	sp,sp,-32
    80001e02:	ec06                	sd	ra,24(sp)
    80001e04:	e822                	sd	s0,16(sp)
    80001e06:	e426                	sd	s1,8(sp)
    80001e08:	1000                	addi	s0,sp,32
  push_off();
    80001e0a:	fffff097          	auipc	ra,0xfffff
    80001e0e:	d8e080e7          	jalr	-626(ra) # 80000b98 <push_off>
    80001e12:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001e14:	2781                	sext.w	a5,a5
    80001e16:	0a800713          	li	a4,168
    80001e1a:	02e787b3          	mul	a5,a5,a4
    80001e1e:	0000f717          	auipc	a4,0xf
    80001e22:	48270713          	addi	a4,a4,1154 # 800112a0 <cpus>
    80001e26:	97ba                	add	a5,a5,a4
    80001e28:	6384                	ld	s1,0(a5)
  pop_off();
    80001e2a:	fffff097          	auipc	ra,0xfffff
    80001e2e:	e0e080e7          	jalr	-498(ra) # 80000c38 <pop_off>
  return p;
}
    80001e32:	8526                	mv	a0,s1
    80001e34:	60e2                	ld	ra,24(sp)
    80001e36:	6442                	ld	s0,16(sp)
    80001e38:	64a2                	ld	s1,8(sp)
    80001e3a:	6105                	addi	sp,sp,32
    80001e3c:	8082                	ret

0000000080001e3e <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001e3e:	1141                	addi	sp,sp,-16
    80001e40:	e406                	sd	ra,8(sp)
    80001e42:	e022                	sd	s0,0(sp)
    80001e44:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001e46:	00000097          	auipc	ra,0x0
    80001e4a:	fba080e7          	jalr	-70(ra) # 80001e00 <myproc>
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	e4a080e7          	jalr	-438(ra) # 80000c98 <release>

  if (first) {
    80001e56:	00007797          	auipc	a5,0x7
    80001e5a:	a6a7a783          	lw	a5,-1430(a5) # 800088c0 <first.1753>
    80001e5e:	eb89                	bnez	a5,80001e70 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001e60:	00001097          	auipc	ra,0x1
    80001e64:	ee2080e7          	jalr	-286(ra) # 80002d42 <usertrapret>
}
    80001e68:	60a2                	ld	ra,8(sp)
    80001e6a:	6402                	ld	s0,0(sp)
    80001e6c:	0141                	addi	sp,sp,16
    80001e6e:	8082                	ret
    first = 0;
    80001e70:	00007797          	auipc	a5,0x7
    80001e74:	a407a823          	sw	zero,-1456(a5) # 800088c0 <first.1753>
    fsinit(ROOTDEV);
    80001e78:	4505                	li	a0,1
    80001e7a:	00002097          	auipc	ra,0x2
    80001e7e:	c0a080e7          	jalr	-1014(ra) # 80003a84 <fsinit>
    80001e82:	bff9                	j	80001e60 <forkret+0x22>

0000000080001e84 <allocpid>:
allocpid() {
    80001e84:	1101                	addi	sp,sp,-32
    80001e86:	ec06                	sd	ra,24(sp)
    80001e88:	e822                	sd	s0,16(sp)
    80001e8a:	e426                	sd	s1,8(sp)
    80001e8c:	e04a                	sd	s2,0(sp)
    80001e8e:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001e90:	00007917          	auipc	s2,0x7
    80001e94:	a3490913          	addi	s2,s2,-1484 # 800088c4 <nextpid>
    80001e98:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, nextpid + 1));
    80001e9c:	0014861b          	addiw	a2,s1,1
    80001ea0:	85a6                	mv	a1,s1
    80001ea2:	854a                	mv	a0,s2
    80001ea4:	00005097          	auipc	ra,0x5
    80001ea8:	9e2080e7          	jalr	-1566(ra) # 80006886 <cas>
    80001eac:	2501                	sext.w	a0,a0
    80001eae:	f56d                	bnez	a0,80001e98 <allocpid+0x14>
}
    80001eb0:	8526                	mv	a0,s1
    80001eb2:	60e2                	ld	ra,24(sp)
    80001eb4:	6442                	ld	s0,16(sp)
    80001eb6:	64a2                	ld	s1,8(sp)
    80001eb8:	6902                	ld	s2,0(sp)
    80001eba:	6105                	addi	sp,sp,32
    80001ebc:	8082                	ret

0000000080001ebe <proc_pagetable>:
{
    80001ebe:	1101                	addi	sp,sp,-32
    80001ec0:	ec06                	sd	ra,24(sp)
    80001ec2:	e822                	sd	s0,16(sp)
    80001ec4:	e426                	sd	s1,8(sp)
    80001ec6:	e04a                	sd	s2,0(sp)
    80001ec8:	1000                	addi	s0,sp,32
    80001eca:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	46e080e7          	jalr	1134(ra) # 8000133a <uvmcreate>
    80001ed4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ed6:	c121                	beqz	a0,80001f16 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ed8:	4729                	li	a4,10
    80001eda:	00005697          	auipc	a3,0x5
    80001ede:	12668693          	addi	a3,a3,294 # 80007000 <_trampoline>
    80001ee2:	6605                	lui	a2,0x1
    80001ee4:	040005b7          	lui	a1,0x4000
    80001ee8:	15fd                	addi	a1,a1,-1
    80001eea:	05b2                	slli	a1,a1,0xc
    80001eec:	fffff097          	auipc	ra,0xfffff
    80001ef0:	1c4080e7          	jalr	452(ra) # 800010b0 <mappages>
    80001ef4:	02054863          	bltz	a0,80001f24 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ef8:	4719                	li	a4,6
    80001efa:	05893683          	ld	a3,88(s2)
    80001efe:	6605                	lui	a2,0x1
    80001f00:	020005b7          	lui	a1,0x2000
    80001f04:	15fd                	addi	a1,a1,-1
    80001f06:	05b6                	slli	a1,a1,0xd
    80001f08:	8526                	mv	a0,s1
    80001f0a:	fffff097          	auipc	ra,0xfffff
    80001f0e:	1a6080e7          	jalr	422(ra) # 800010b0 <mappages>
    80001f12:	02054163          	bltz	a0,80001f34 <proc_pagetable+0x76>
}
    80001f16:	8526                	mv	a0,s1
    80001f18:	60e2                	ld	ra,24(sp)
    80001f1a:	6442                	ld	s0,16(sp)
    80001f1c:	64a2                	ld	s1,8(sp)
    80001f1e:	6902                	ld	s2,0(sp)
    80001f20:	6105                	addi	sp,sp,32
    80001f22:	8082                	ret
    uvmfree(pagetable, 0);
    80001f24:	4581                	li	a1,0
    80001f26:	8526                	mv	a0,s1
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	60e080e7          	jalr	1550(ra) # 80001536 <uvmfree>
    return 0;
    80001f30:	4481                	li	s1,0
    80001f32:	b7d5                	j	80001f16 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f34:	4681                	li	a3,0
    80001f36:	4605                	li	a2,1
    80001f38:	040005b7          	lui	a1,0x4000
    80001f3c:	15fd                	addi	a1,a1,-1
    80001f3e:	05b2                	slli	a1,a1,0xc
    80001f40:	8526                	mv	a0,s1
    80001f42:	fffff097          	auipc	ra,0xfffff
    80001f46:	334080e7          	jalr	820(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001f4a:	4581                	li	a1,0
    80001f4c:	8526                	mv	a0,s1
    80001f4e:	fffff097          	auipc	ra,0xfffff
    80001f52:	5e8080e7          	jalr	1512(ra) # 80001536 <uvmfree>
    return 0;
    80001f56:	4481                	li	s1,0
    80001f58:	bf7d                	j	80001f16 <proc_pagetable+0x58>

0000000080001f5a <proc_freepagetable>:
{
    80001f5a:	1101                	addi	sp,sp,-32
    80001f5c:	ec06                	sd	ra,24(sp)
    80001f5e:	e822                	sd	s0,16(sp)
    80001f60:	e426                	sd	s1,8(sp)
    80001f62:	e04a                	sd	s2,0(sp)
    80001f64:	1000                	addi	s0,sp,32
    80001f66:	84aa                	mv	s1,a0
    80001f68:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f6a:	4681                	li	a3,0
    80001f6c:	4605                	li	a2,1
    80001f6e:	040005b7          	lui	a1,0x4000
    80001f72:	15fd                	addi	a1,a1,-1
    80001f74:	05b2                	slli	a1,a1,0xc
    80001f76:	fffff097          	auipc	ra,0xfffff
    80001f7a:	300080e7          	jalr	768(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001f7e:	4681                	li	a3,0
    80001f80:	4605                	li	a2,1
    80001f82:	020005b7          	lui	a1,0x2000
    80001f86:	15fd                	addi	a1,a1,-1
    80001f88:	05b6                	slli	a1,a1,0xd
    80001f8a:	8526                	mv	a0,s1
    80001f8c:	fffff097          	auipc	ra,0xfffff
    80001f90:	2ea080e7          	jalr	746(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001f94:	85ca                	mv	a1,s2
    80001f96:	8526                	mv	a0,s1
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	59e080e7          	jalr	1438(ra) # 80001536 <uvmfree>
}
    80001fa0:	60e2                	ld	ra,24(sp)
    80001fa2:	6442                	ld	s0,16(sp)
    80001fa4:	64a2                	ld	s1,8(sp)
    80001fa6:	6902                	ld	s2,0(sp)
    80001fa8:	6105                	addi	sp,sp,32
    80001faa:	8082                	ret

0000000080001fac <freeproc>:
{
    80001fac:	1101                	addi	sp,sp,-32
    80001fae:	ec06                	sd	ra,24(sp)
    80001fb0:	e822                	sd	s0,16(sp)
    80001fb2:	e426                	sd	s1,8(sp)
    80001fb4:	1000                	addi	s0,sp,32
    80001fb6:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001fb8:	6d28                	ld	a0,88(a0)
    80001fba:	c509                	beqz	a0,80001fc4 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001fbc:	fffff097          	auipc	ra,0xfffff
    80001fc0:	a3c080e7          	jalr	-1476(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001fc4:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001fc8:	68a8                	ld	a0,80(s1)
    80001fca:	c511                	beqz	a0,80001fd6 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001fcc:	64ac                	ld	a1,72(s1)
    80001fce:	00000097          	auipc	ra,0x0
    80001fd2:	f8c080e7          	jalr	-116(ra) # 80001f5a <proc_freepagetable>
  p->pagetable = 0;
    80001fd6:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001fda:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001fde:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001fe2:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001fe6:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001fea:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001fee:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ff2:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ff6:	0004ac23          	sw	zero,24(s1)
  remove(&zombie_list, p); // remove the freed process from the ZOMBIE list
    80001ffa:	85a6                	mv	a1,s1
    80001ffc:	00007517          	auipc	a0,0x7
    80002000:	91450513          	addi	a0,a0,-1772 # 80008910 <zombie_list>
    80002004:	00000097          	auipc	ra,0x0
    80002008:	b14080e7          	jalr	-1260(ra) # 80001b18 <remove>
  append(&unused_list, p); // admit its entry to the UNUSED entry list.
    8000200c:	85a6                	mv	a1,s1
    8000200e:	00007517          	auipc	a0,0x7
    80002012:	8c250513          	addi	a0,a0,-1854 # 800088d0 <unused_list>
    80002016:	00000097          	auipc	ra,0x0
    8000201a:	a3a080e7          	jalr	-1478(ra) # 80001a50 <append>
}
    8000201e:	60e2                	ld	ra,24(sp)
    80002020:	6442                	ld	s0,16(sp)
    80002022:	64a2                	ld	s1,8(sp)
    80002024:	6105                	addi	sp,sp,32
    80002026:	8082                	ret

0000000080002028 <allocproc>:
{
    80002028:	715d                	addi	sp,sp,-80
    8000202a:	e486                	sd	ra,72(sp)
    8000202c:	e0a2                	sd	s0,64(sp)
    8000202e:	fc26                	sd	s1,56(sp)
    80002030:	f84a                	sd	s2,48(sp)
    80002032:	f44e                	sd	s3,40(sp)
    80002034:	f052                	sd	s4,32(sp)
    80002036:	ec56                	sd	s5,24(sp)
    80002038:	e85a                	sd	s6,16(sp)
    8000203a:	e45e                	sd	s7,8(sp)
    8000203c:	0880                	addi	s0,sp,80
  while(!isEmpty(&unused_list)){
    8000203e:	00007717          	auipc	a4,0x7
    80002042:	89272703          	lw	a4,-1902(a4) # 800088d0 <unused_list>
    80002046:	57fd                	li	a5,-1
    80002048:	14f70063          	beq	a4,a5,80002188 <allocproc+0x160>
    p = &proc[get_head(&unused_list)];
    8000204c:	00007a17          	auipc	s4,0x7
    80002050:	884a0a13          	addi	s4,s4,-1916 # 800088d0 <unused_list>
    80002054:	19000b13          	li	s6,400
    80002058:	0000fa97          	auipc	s5,0xf
    8000205c:	7b8a8a93          	addi	s5,s5,1976 # 80011810 <proc>
  while(!isEmpty(&unused_list)){
    80002060:	5bfd                	li	s7,-1
    p = &proc[get_head(&unused_list)];
    80002062:	8552                	mv	a0,s4
    80002064:	00000097          	auipc	ra,0x0
    80002068:	996080e7          	jalr	-1642(ra) # 800019fa <get_head>
    8000206c:	892a                	mv	s2,a0
    8000206e:	036509b3          	mul	s3,a0,s6
    80002072:	015984b3          	add	s1,s3,s5
    acquire(&p->lock);
    80002076:	8526                	mv	a0,s1
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	b6c080e7          	jalr	-1172(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80002080:	4c9c                	lw	a5,24(s1)
    80002082:	c79d                	beqz	a5,800020b0 <allocproc+0x88>
      release(&p->lock);
    80002084:	8526                	mv	a0,s1
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	c12080e7          	jalr	-1006(ra) # 80000c98 <release>
  while(!isEmpty(&unused_list)){
    8000208e:	000a2783          	lw	a5,0(s4)
    80002092:	fd7798e3          	bne	a5,s7,80002062 <allocproc+0x3a>
  return 0;
    80002096:	4481                	li	s1,0
}
    80002098:	8526                	mv	a0,s1
    8000209a:	60a6                	ld	ra,72(sp)
    8000209c:	6406                	ld	s0,64(sp)
    8000209e:	74e2                	ld	s1,56(sp)
    800020a0:	7942                	ld	s2,48(sp)
    800020a2:	79a2                	ld	s3,40(sp)
    800020a4:	7a02                	ld	s4,32(sp)
    800020a6:	6ae2                	ld	s5,24(sp)
    800020a8:	6b42                	ld	s6,16(sp)
    800020aa:	6ba2                	ld	s7,8(sp)
    800020ac:	6161                	addi	sp,sp,80
    800020ae:	8082                	ret
      remove(&unused_list, p); // choose the new process entry to initialize from the UNUSED entry list.
    800020b0:	85a6                	mv	a1,s1
    800020b2:	00007517          	auipc	a0,0x7
    800020b6:	81e50513          	addi	a0,a0,-2018 # 800088d0 <unused_list>
    800020ba:	00000097          	auipc	ra,0x0
    800020be:	a5e080e7          	jalr	-1442(ra) # 80001b18 <remove>
  p->pid = allocpid();
    800020c2:	00000097          	auipc	ra,0x0
    800020c6:	dc2080e7          	jalr	-574(ra) # 80001e84 <allocpid>
    800020ca:	19000a13          	li	s4,400
    800020ce:	034907b3          	mul	a5,s2,s4
    800020d2:	0000fa17          	auipc	s4,0xf
    800020d6:	73ea0a13          	addi	s4,s4,1854 # 80011810 <proc>
    800020da:	9a3e                	add	s4,s4,a5
    800020dc:	02aa2823          	sw	a0,48(s4)
  p->state = USED;
    800020e0:	4785                	li	a5,1
    800020e2:	00fa2c23          	sw	a5,24(s4)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	a0e080e7          	jalr	-1522(ra) # 80000af4 <kalloc>
    800020ee:	8aaa                	mv	s5,a0
    800020f0:	04aa3c23          	sd	a0,88(s4)
    800020f4:	c135                	beqz	a0,80002158 <allocproc+0x130>
  p->pagetable = proc_pagetable(p);
    800020f6:	8526                	mv	a0,s1
    800020f8:	00000097          	auipc	ra,0x0
    800020fc:	dc6080e7          	jalr	-570(ra) # 80001ebe <proc_pagetable>
    80002100:	8a2a                	mv	s4,a0
    80002102:	19000793          	li	a5,400
    80002106:	02f90733          	mul	a4,s2,a5
    8000210a:	0000f797          	auipc	a5,0xf
    8000210e:	70678793          	addi	a5,a5,1798 # 80011810 <proc>
    80002112:	97ba                	add	a5,a5,a4
    80002114:	eba8                	sd	a0,80(a5)
  if(p->pagetable == 0){
    80002116:	cd29                	beqz	a0,80002170 <allocproc+0x148>
  memset(&p->context, 0, sizeof(p->context));
    80002118:	06098513          	addi	a0,s3,96
    8000211c:	0000f997          	auipc	s3,0xf
    80002120:	6f498993          	addi	s3,s3,1780 # 80011810 <proc>
    80002124:	07000613          	li	a2,112
    80002128:	4581                	li	a1,0
    8000212a:	954e                	add	a0,a0,s3
    8000212c:	fffff097          	auipc	ra,0xfffff
    80002130:	bb4080e7          	jalr	-1100(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80002134:	19000793          	li	a5,400
    80002138:	02f90933          	mul	s2,s2,a5
    8000213c:	994e                	add	s2,s2,s3
    8000213e:	00000797          	auipc	a5,0x0
    80002142:	d0078793          	addi	a5,a5,-768 # 80001e3e <forkret>
    80002146:	06f93023          	sd	a5,96(s2)
  p->context.sp = p->kstack + PGSIZE;
    8000214a:	04093783          	ld	a5,64(s2)
    8000214e:	6705                	lui	a4,0x1
    80002150:	97ba                	add	a5,a5,a4
    80002152:	06f93423          	sd	a5,104(s2)
  return p;
    80002156:	b789                	j	80002098 <allocproc+0x70>
    freeproc(p);
    80002158:	8526                	mv	a0,s1
    8000215a:	00000097          	auipc	ra,0x0
    8000215e:	e52080e7          	jalr	-430(ra) # 80001fac <freeproc>
    release(&p->lock);
    80002162:	8526                	mv	a0,s1
    80002164:	fffff097          	auipc	ra,0xfffff
    80002168:	b34080e7          	jalr	-1228(ra) # 80000c98 <release>
    return 0;
    8000216c:	84d6                	mv	s1,s5
    8000216e:	b72d                	j	80002098 <allocproc+0x70>
    freeproc(p);
    80002170:	8526                	mv	a0,s1
    80002172:	00000097          	auipc	ra,0x0
    80002176:	e3a080e7          	jalr	-454(ra) # 80001fac <freeproc>
    release(&p->lock);
    8000217a:	8526                	mv	a0,s1
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	b1c080e7          	jalr	-1252(ra) # 80000c98 <release>
    return 0;
    80002184:	84d2                	mv	s1,s4
    80002186:	bf09                	j	80002098 <allocproc+0x70>
  return 0;
    80002188:	4481                	li	s1,0
    8000218a:	b739                	j	80002098 <allocproc+0x70>

000000008000218c <userinit>:
{
    8000218c:	1101                	addi	sp,sp,-32
    8000218e:	ec06                	sd	ra,24(sp)
    80002190:	e822                	sd	s0,16(sp)
    80002192:	e426                	sd	s1,8(sp)
    80002194:	1000                	addi	s0,sp,32
  p = allocproc();
    80002196:	00000097          	auipc	ra,0x0
    8000219a:	e92080e7          	jalr	-366(ra) # 80002028 <allocproc>
    8000219e:	84aa                	mv	s1,a0
  initproc = p;
    800021a0:	00007797          	auipc	a5,0x7
    800021a4:	e8a7b423          	sd	a0,-376(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800021a8:	03400613          	li	a2,52
    800021ac:	00006597          	auipc	a1,0x6
    800021b0:	78458593          	addi	a1,a1,1924 # 80008930 <initcode>
    800021b4:	6928                	ld	a0,80(a0)
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	1b2080e7          	jalr	434(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    800021be:	6785                	lui	a5,0x1
    800021c0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    800021c2:	6cb8                	ld	a4,88(s1)
    800021c4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800021c8:	6cb8                	ld	a4,88(s1)
    800021ca:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800021cc:	4641                	li	a2,16
    800021ce:	00006597          	auipc	a1,0x6
    800021d2:	0da58593          	addi	a1,a1,218 # 800082a8 <digits+0x268>
    800021d6:	15848513          	addi	a0,s1,344
    800021da:	fffff097          	auipc	ra,0xfffff
    800021de:	c58080e7          	jalr	-936(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800021e2:	00006517          	auipc	a0,0x6
    800021e6:	0d650513          	addi	a0,a0,214 # 800082b8 <digits+0x278>
    800021ea:	00002097          	auipc	ra,0x2
    800021ee:	2c8080e7          	jalr	712(ra) # 800044b2 <namei>
    800021f2:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    800021f6:	478d                	li	a5,3
    800021f8:	cc9c                	sw	a5,24(s1)
  append(&(cpus[0].runnable_list), p); // admit the init process (the first process in the OS) to the first CPU’s list.
    800021fa:	85a6                	mv	a1,s1
    800021fc:	0000f517          	auipc	a0,0xf
    80002200:	12c50513          	addi	a0,a0,300 # 80011328 <cpus+0x88>
    80002204:	00000097          	auipc	ra,0x0
    80002208:	84c080e7          	jalr	-1972(ra) # 80001a50 <append>
  release(&p->lock);
    8000220c:	8526                	mv	a0,s1
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	a8a080e7          	jalr	-1398(ra) # 80000c98 <release>
}
    80002216:	60e2                	ld	ra,24(sp)
    80002218:	6442                	ld	s0,16(sp)
    8000221a:	64a2                	ld	s1,8(sp)
    8000221c:	6105                	addi	sp,sp,32
    8000221e:	8082                	ret

0000000080002220 <growproc>:
{
    80002220:	1101                	addi	sp,sp,-32
    80002222:	ec06                	sd	ra,24(sp)
    80002224:	e822                	sd	s0,16(sp)
    80002226:	e426                	sd	s1,8(sp)
    80002228:	e04a                	sd	s2,0(sp)
    8000222a:	1000                	addi	s0,sp,32
    8000222c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000222e:	00000097          	auipc	ra,0x0
    80002232:	bd2080e7          	jalr	-1070(ra) # 80001e00 <myproc>
    80002236:	892a                	mv	s2,a0
  sz = p->sz;
    80002238:	652c                	ld	a1,72(a0)
    8000223a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000223e:	00904f63          	bgtz	s1,8000225c <growproc+0x3c>
  } else if(n < 0){
    80002242:	0204cc63          	bltz	s1,8000227a <growproc+0x5a>
  p->sz = sz;
    80002246:	1602                	slli	a2,a2,0x20
    80002248:	9201                	srli	a2,a2,0x20
    8000224a:	04c93423          	sd	a2,72(s2)
  return 0;
    8000224e:	4501                	li	a0,0
}
    80002250:	60e2                	ld	ra,24(sp)
    80002252:	6442                	ld	s0,16(sp)
    80002254:	64a2                	ld	s1,8(sp)
    80002256:	6902                	ld	s2,0(sp)
    80002258:	6105                	addi	sp,sp,32
    8000225a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000225c:	9e25                	addw	a2,a2,s1
    8000225e:	1602                	slli	a2,a2,0x20
    80002260:	9201                	srli	a2,a2,0x20
    80002262:	1582                	slli	a1,a1,0x20
    80002264:	9181                	srli	a1,a1,0x20
    80002266:	6928                	ld	a0,80(a0)
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	1ba080e7          	jalr	442(ra) # 80001422 <uvmalloc>
    80002270:	0005061b          	sext.w	a2,a0
    80002274:	fa69                	bnez	a2,80002246 <growproc+0x26>
      return -1;
    80002276:	557d                	li	a0,-1
    80002278:	bfe1                	j	80002250 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000227a:	9e25                	addw	a2,a2,s1
    8000227c:	1602                	slli	a2,a2,0x20
    8000227e:	9201                	srli	a2,a2,0x20
    80002280:	1582                	slli	a1,a1,0x20
    80002282:	9181                	srli	a1,a1,0x20
    80002284:	6928                	ld	a0,80(a0)
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	154080e7          	jalr	340(ra) # 800013da <uvmdealloc>
    8000228e:	0005061b          	sext.w	a2,a0
    80002292:	bf55                	j	80002246 <growproc+0x26>

0000000080002294 <fork>:
{
    80002294:	7139                	addi	sp,sp,-64
    80002296:	fc06                	sd	ra,56(sp)
    80002298:	f822                	sd	s0,48(sp)
    8000229a:	f426                	sd	s1,40(sp)
    8000229c:	f04a                	sd	s2,32(sp)
    8000229e:	ec4e                	sd	s3,24(sp)
    800022a0:	e852                	sd	s4,16(sp)
    800022a2:	e456                	sd	s5,8(sp)
    800022a4:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    800022a6:	00000097          	auipc	ra,0x0
    800022aa:	b5a080e7          	jalr	-1190(ra) # 80001e00 <myproc>
    800022ae:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    800022b0:	00000097          	auipc	ra,0x0
    800022b4:	d78080e7          	jalr	-648(ra) # 80002028 <allocproc>
    800022b8:	14050663          	beqz	a0,80002404 <fork+0x170>
    800022bc:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800022be:	04893603          	ld	a2,72(s2)
    800022c2:	692c                	ld	a1,80(a0)
    800022c4:	05093503          	ld	a0,80(s2)
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	2a6080e7          	jalr	678(ra) # 8000156e <uvmcopy>
    800022d0:	04054663          	bltz	a0,8000231c <fork+0x88>
  np->sz = p->sz;
    800022d4:	04893783          	ld	a5,72(s2)
    800022d8:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    800022dc:	05893683          	ld	a3,88(s2)
    800022e0:	87b6                	mv	a5,a3
    800022e2:	0589b703          	ld	a4,88(s3)
    800022e6:	12068693          	addi	a3,a3,288
    800022ea:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800022ee:	6788                	ld	a0,8(a5)
    800022f0:	6b8c                	ld	a1,16(a5)
    800022f2:	6f90                	ld	a2,24(a5)
    800022f4:	01073023          	sd	a6,0(a4)
    800022f8:	e708                	sd	a0,8(a4)
    800022fa:	eb0c                	sd	a1,16(a4)
    800022fc:	ef10                	sd	a2,24(a4)
    800022fe:	02078793          	addi	a5,a5,32
    80002302:	02070713          	addi	a4,a4,32
    80002306:	fed792e3          	bne	a5,a3,800022ea <fork+0x56>
  np->trapframe->a0 = 0;
    8000230a:	0589b783          	ld	a5,88(s3)
    8000230e:	0607b823          	sd	zero,112(a5)
    80002312:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002316:	15000a13          	li	s4,336
    8000231a:	a03d                	j	80002348 <fork+0xb4>
    freeproc(np);
    8000231c:	854e                	mv	a0,s3
    8000231e:	00000097          	auipc	ra,0x0
    80002322:	c8e080e7          	jalr	-882(ra) # 80001fac <freeproc>
    release(&np->lock);
    80002326:	854e                	mv	a0,s3
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	970080e7          	jalr	-1680(ra) # 80000c98 <release>
    return -1;
    80002330:	5afd                	li	s5,-1
    80002332:	a87d                	j	800023f0 <fork+0x15c>
      np->ofile[i] = filedup(p->ofile[i]);
    80002334:	00003097          	auipc	ra,0x3
    80002338:	814080e7          	jalr	-2028(ra) # 80004b48 <filedup>
    8000233c:	009987b3          	add	a5,s3,s1
    80002340:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002342:	04a1                	addi	s1,s1,8
    80002344:	01448763          	beq	s1,s4,80002352 <fork+0xbe>
    if(p->ofile[i])
    80002348:	009907b3          	add	a5,s2,s1
    8000234c:	6388                	ld	a0,0(a5)
    8000234e:	f17d                	bnez	a0,80002334 <fork+0xa0>
    80002350:	bfcd                	j	80002342 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002352:	15093503          	ld	a0,336(s2)
    80002356:	00002097          	auipc	ra,0x2
    8000235a:	968080e7          	jalr	-1688(ra) # 80003cbe <idup>
    8000235e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002362:	4641                	li	a2,16
    80002364:	15890593          	addi	a1,s2,344
    80002368:	15898513          	addi	a0,s3,344
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	ac6080e7          	jalr	-1338(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002374:	0309aa83          	lw	s5,48(s3)
  release(&np->lock);
    80002378:	854e                	mv	a0,s3
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	91e080e7          	jalr	-1762(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002382:	0000fa17          	auipc	s4,0xf
    80002386:	f1ea0a13          	addi	s4,s4,-226 # 800112a0 <cpus>
    8000238a:	0000f497          	auipc	s1,0xf
    8000238e:	46e48493          	addi	s1,s1,1134 # 800117f8 <wait_lock>
    80002392:	8526                	mv	a0,s1
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	850080e7          	jalr	-1968(ra) # 80000be4 <acquire>
  np->parent = p;
    8000239c:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    800023a0:	8526                	mv	a0,s1
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	8f6080e7          	jalr	-1802(ra) # 80000c98 <release>
  acquire(&np->lock);
    800023aa:	854e                	mv	a0,s3
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	838080e7          	jalr	-1992(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800023b4:	478d                	li	a5,3
    800023b6:	00f9ac23          	sw	a5,24(s3)
  np->last_cpu = p->last_cpu; // case BLNCFLG=OFF -> cpu = parent's cpu 
    800023ba:	16892483          	lw	s1,360(s2)
    800023be:	1699a423          	sw	s1,360(s3)
  struct cpu *c = &cpus[np->last_cpu];
    800023c2:	0a800513          	li	a0,168
    800023c6:	02a484b3          	mul	s1,s1,a0
  increment_cpu_process_count(c);
    800023ca:	009a0533          	add	a0,s4,s1
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	470080e7          	jalr	1136(ra) # 8000183e <increment_cpu_process_count>
  append(&(c->runnable_list), np); // admit the new process to the father’s current CPU’s ready list
    800023d6:	08848513          	addi	a0,s1,136
    800023da:	85ce                	mv	a1,s3
    800023dc:	9552                	add	a0,a0,s4
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	672080e7          	jalr	1650(ra) # 80001a50 <append>
  release(&np->lock);
    800023e6:	854e                	mv	a0,s3
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	8b0080e7          	jalr	-1872(ra) # 80000c98 <release>
}
    800023f0:	8556                	mv	a0,s5
    800023f2:	70e2                	ld	ra,56(sp)
    800023f4:	7442                	ld	s0,48(sp)
    800023f6:	74a2                	ld	s1,40(sp)
    800023f8:	7902                	ld	s2,32(sp)
    800023fa:	69e2                	ld	s3,24(sp)
    800023fc:	6a42                	ld	s4,16(sp)
    800023fe:	6aa2                	ld	s5,8(sp)
    80002400:	6121                	addi	sp,sp,64
    80002402:	8082                	ret
    return -1;
    80002404:	5afd                	li	s5,-1
    80002406:	b7ed                	j	800023f0 <fork+0x15c>

0000000080002408 <scheduler>:
{
    80002408:	715d                	addi	sp,sp,-80
    8000240a:	e486                	sd	ra,72(sp)
    8000240c:	e0a2                	sd	s0,64(sp)
    8000240e:	fc26                	sd	s1,56(sp)
    80002410:	f84a                	sd	s2,48(sp)
    80002412:	f44e                	sd	s3,40(sp)
    80002414:	f052                	sd	s4,32(sp)
    80002416:	ec56                	sd	s5,24(sp)
    80002418:	e85a                	sd	s6,16(sp)
    8000241a:	e45e                	sd	s7,8(sp)
    8000241c:	e062                	sd	s8,0(sp)
    8000241e:	0880                	addi	s0,sp,80
    80002420:	8712                	mv	a4,tp
  int id = r_tp();
    80002422:	2701                	sext.w	a4,a4
  c->proc = 0;
    80002424:	0000fb17          	auipc	s6,0xf
    80002428:	e7cb0b13          	addi	s6,s6,-388 # 800112a0 <cpus>
    8000242c:	0a800793          	li	a5,168
    80002430:	02f707b3          	mul	a5,a4,a5
    80002434:	00fb06b3          	add	a3,s6,a5
    80002438:	0006b023          	sd	zero,0(a3)
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    8000243c:	08878a13          	addi	s4,a5,136
    80002440:	9a5a                	add	s4,s4,s6
          swtch(&c->context, &p->context);
    80002442:	07a1                	addi	a5,a5,8
    80002444:	9b3e                	add	s6,s6,a5
  return lst->head == -1;
    80002446:	8936                	mv	s2,a3
      if(p->state == RUNNABLE) {
    80002448:	0000f997          	auipc	s3,0xf
    8000244c:	3c898993          	addi	s3,s3,968 # 80011810 <proc>
    80002450:	19000a93          	li	s5,400
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002454:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002458:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000245c:	10079073          	csrw	sstatus,a5
    80002460:	4b8d                	li	s7,3
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    80002462:	54fd                	li	s1,-1
    80002464:	08892783          	lw	a5,136(s2)
    80002468:	fe9786e3          	beq	a5,s1,80002454 <scheduler+0x4c>
      p =  &proc[get_head(&c->runnable_list)]; //  pick the first process from the correct CPU’s list.
    8000246c:	8552                	mv	a0,s4
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	58c080e7          	jalr	1420(ra) # 800019fa <get_head>
      if(p->state == RUNNABLE) {
    80002476:	035507b3          	mul	a5,a0,s5
    8000247a:	97ce                	add	a5,a5,s3
    8000247c:	4f9c                	lw	a5,24(a5)
    8000247e:	ff7793e3          	bne	a5,s7,80002464 <scheduler+0x5c>
    80002482:	035504b3          	mul	s1,a0,s5
      p =  &proc[get_head(&c->runnable_list)]; //  pick the first process from the correct CPU’s list.
    80002486:	01348c33          	add	s8,s1,s3
        acquire(&p->lock);
    8000248a:	8562                	mv	a0,s8
    8000248c:	ffffe097          	auipc	ra,0xffffe
    80002490:	758080e7          	jalr	1880(ra) # 80000be4 <acquire>
          remove(&(c->runnable_list), p);
    80002494:	85e2                	mv	a1,s8
    80002496:	8552                	mv	a0,s4
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	680080e7          	jalr	1664(ra) # 80001b18 <remove>
          p->state = RUNNING;
    800024a0:	4791                	li	a5,4
    800024a2:	00fc2c23          	sw	a5,24(s8)
          c->proc = p;
    800024a6:	01893023          	sd	s8,0(s2)
          p->last_cpu = c->cpu_id;
    800024aa:	08492783          	lw	a5,132(s2)
    800024ae:	16fc2423          	sw	a5,360(s8)
          swtch(&c->context, &p->context);
    800024b2:	06048593          	addi	a1,s1,96
    800024b6:	95ce                	add	a1,a1,s3
    800024b8:	855a                	mv	a0,s6
    800024ba:	00000097          	auipc	ra,0x0
    800024be:	7de080e7          	jalr	2014(ra) # 80002c98 <swtch>
          c->proc = 0;
    800024c2:	00093023          	sd	zero,0(s2)
        release(&p->lock);
    800024c6:	8562                	mv	a0,s8
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	7d0080e7          	jalr	2000(ra) # 80000c98 <release>
    800024d0:	bf49                	j	80002462 <scheduler+0x5a>

00000000800024d2 <sched>:
{
    800024d2:	7179                	addi	sp,sp,-48
    800024d4:	f406                	sd	ra,40(sp)
    800024d6:	f022                	sd	s0,32(sp)
    800024d8:	ec26                	sd	s1,24(sp)
    800024da:	e84a                	sd	s2,16(sp)
    800024dc:	e44e                	sd	s3,8(sp)
    800024de:	e052                	sd	s4,0(sp)
    800024e0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800024e2:	00000097          	auipc	ra,0x0
    800024e6:	91e080e7          	jalr	-1762(ra) # 80001e00 <myproc>
    800024ea:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800024ec:	ffffe097          	auipc	ra,0xffffe
    800024f0:	67e080e7          	jalr	1662(ra) # 80000b6a <holding>
    800024f4:	c141                	beqz	a0,80002574 <sched+0xa2>
  asm volatile("mv %0, tp" : "=r" (x) );
    800024f6:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800024f8:	2781                	sext.w	a5,a5
    800024fa:	0a800713          	li	a4,168
    800024fe:	02e787b3          	mul	a5,a5,a4
    80002502:	0000f717          	auipc	a4,0xf
    80002506:	d9e70713          	addi	a4,a4,-610 # 800112a0 <cpus>
    8000250a:	97ba                	add	a5,a5,a4
    8000250c:	5fb8                	lw	a4,120(a5)
    8000250e:	4785                	li	a5,1
    80002510:	06f71a63          	bne	a4,a5,80002584 <sched+0xb2>
  if(p->state == RUNNING)
    80002514:	4c98                	lw	a4,24(s1)
    80002516:	4791                	li	a5,4
    80002518:	06f70e63          	beq	a4,a5,80002594 <sched+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000251c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002520:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002522:	e3c9                	bnez	a5,800025a4 <sched+0xd2>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002524:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002526:	0000f917          	auipc	s2,0xf
    8000252a:	d7a90913          	addi	s2,s2,-646 # 800112a0 <cpus>
    8000252e:	2781                	sext.w	a5,a5
    80002530:	0a800993          	li	s3,168
    80002534:	033787b3          	mul	a5,a5,s3
    80002538:	97ca                	add	a5,a5,s2
    8000253a:	07c7aa03          	lw	s4,124(a5)
    8000253e:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    80002540:	2581                	sext.w	a1,a1
    80002542:	033585b3          	mul	a1,a1,s3
    80002546:	05a1                	addi	a1,a1,8
    80002548:	95ca                	add	a1,a1,s2
    8000254a:	06048513          	addi	a0,s1,96
    8000254e:	00000097          	auipc	ra,0x0
    80002552:	74a080e7          	jalr	1866(ra) # 80002c98 <swtch>
    80002556:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002558:	2781                	sext.w	a5,a5
    8000255a:	033787b3          	mul	a5,a5,s3
    8000255e:	993e                	add	s2,s2,a5
    80002560:	07492e23          	sw	s4,124(s2)
}
    80002564:	70a2                	ld	ra,40(sp)
    80002566:	7402                	ld	s0,32(sp)
    80002568:	64e2                	ld	s1,24(sp)
    8000256a:	6942                	ld	s2,16(sp)
    8000256c:	69a2                	ld	s3,8(sp)
    8000256e:	6a02                	ld	s4,0(sp)
    80002570:	6145                	addi	sp,sp,48
    80002572:	8082                	ret
    panic("sched p->lock");
    80002574:	00006517          	auipc	a0,0x6
    80002578:	d4c50513          	addi	a0,a0,-692 # 800082c0 <digits+0x280>
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	fc2080e7          	jalr	-62(ra) # 8000053e <panic>
    panic("sched locks");
    80002584:	00006517          	auipc	a0,0x6
    80002588:	d4c50513          	addi	a0,a0,-692 # 800082d0 <digits+0x290>
    8000258c:	ffffe097          	auipc	ra,0xffffe
    80002590:	fb2080e7          	jalr	-78(ra) # 8000053e <panic>
    panic("sched running");
    80002594:	00006517          	auipc	a0,0x6
    80002598:	d4c50513          	addi	a0,a0,-692 # 800082e0 <digits+0x2a0>
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	fa2080e7          	jalr	-94(ra) # 8000053e <panic>
    panic("sched interruptible");
    800025a4:	00006517          	auipc	a0,0x6
    800025a8:	d4c50513          	addi	a0,a0,-692 # 800082f0 <digits+0x2b0>
    800025ac:	ffffe097          	auipc	ra,0xffffe
    800025b0:	f92080e7          	jalr	-110(ra) # 8000053e <panic>

00000000800025b4 <yield>:
{
    800025b4:	1101                	addi	sp,sp,-32
    800025b6:	ec06                	sd	ra,24(sp)
    800025b8:	e822                	sd	s0,16(sp)
    800025ba:	e426                	sd	s1,8(sp)
    800025bc:	e04a                	sd	s2,0(sp)
    800025be:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800025c0:	00000097          	auipc	ra,0x0
    800025c4:	840080e7          	jalr	-1984(ra) # 80001e00 <myproc>
    800025c8:	84aa                	mv	s1,a0
    800025ca:	8912                	mv	s2,tp
  acquire(&p->lock);
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	618080e7          	jalr	1560(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800025d4:	478d                	li	a5,3
    800025d6:	cc9c                	sw	a5,24(s1)
  append(&(c->runnable_list), p);
    800025d8:	2901                	sext.w	s2,s2
    800025da:	0a800513          	li	a0,168
    800025de:	02a90933          	mul	s2,s2,a0
    800025e2:	85a6                	mv	a1,s1
    800025e4:	0000f517          	auipc	a0,0xf
    800025e8:	d4450513          	addi	a0,a0,-700 # 80011328 <cpus+0x88>
    800025ec:	954a                	add	a0,a0,s2
    800025ee:	fffff097          	auipc	ra,0xfffff
    800025f2:	462080e7          	jalr	1122(ra) # 80001a50 <append>
  sched();
    800025f6:	00000097          	auipc	ra,0x0
    800025fa:	edc080e7          	jalr	-292(ra) # 800024d2 <sched>
  release(&p->lock);
    800025fe:	8526                	mv	a0,s1
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	698080e7          	jalr	1688(ra) # 80000c98 <release>
}
    80002608:	60e2                	ld	ra,24(sp)
    8000260a:	6442                	ld	s0,16(sp)
    8000260c:	64a2                	ld	s1,8(sp)
    8000260e:	6902                	ld	s2,0(sp)
    80002610:	6105                	addi	sp,sp,32
    80002612:	8082                	ret

0000000080002614 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002614:	7179                	addi	sp,sp,-48
    80002616:	f406                	sd	ra,40(sp)
    80002618:	f022                	sd	s0,32(sp)
    8000261a:	ec26                	sd	s1,24(sp)
    8000261c:	e84a                	sd	s2,16(sp)
    8000261e:	e44e                	sd	s3,8(sp)
    80002620:	1800                	addi	s0,sp,48
    80002622:	89aa                	mv	s3,a0
    80002624:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002626:	fffff097          	auipc	ra,0xfffff
    8000262a:	7da080e7          	jalr	2010(ra) # 80001e00 <myproc>
    8000262e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	5b4080e7          	jalr	1460(ra) # 80000be4 <acquire>
  release(lk);
    80002638:	854a                	mv	a0,s2
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	65e080e7          	jalr	1630(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002642:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002646:	4789                	li	a5,2
    80002648:	cc9c                	sw	a5,24(s1)
  //printf("insert sleep sleep %d\n", p->index); //delete
  append(&sleeping_list, p);
    8000264a:	85a6                	mv	a1,s1
    8000264c:	00006517          	auipc	a0,0x6
    80002650:	2a450513          	addi	a0,a0,676 # 800088f0 <sleeping_list>
    80002654:	fffff097          	auipc	ra,0xfffff
    80002658:	3fc080e7          	jalr	1020(ra) # 80001a50 <append>

  sched();
    8000265c:	00000097          	auipc	ra,0x0
    80002660:	e76080e7          	jalr	-394(ra) # 800024d2 <sched>

  // Tidy up.
  p->chan = 0;
    80002664:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002668:	8526                	mv	a0,s1
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	62e080e7          	jalr	1582(ra) # 80000c98 <release>
  acquire(lk);
    80002672:	854a                	mv	a0,s2
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	570080e7          	jalr	1392(ra) # 80000be4 <acquire>
}
    8000267c:	70a2                	ld	ra,40(sp)
    8000267e:	7402                	ld	s0,32(sp)
    80002680:	64e2                	ld	s1,24(sp)
    80002682:	6942                	ld	s2,16(sp)
    80002684:	69a2                	ld	s3,8(sp)
    80002686:	6145                	addi	sp,sp,48
    80002688:	8082                	ret

000000008000268a <wait>:
{
    8000268a:	715d                	addi	sp,sp,-80
    8000268c:	e486                	sd	ra,72(sp)
    8000268e:	e0a2                	sd	s0,64(sp)
    80002690:	fc26                	sd	s1,56(sp)
    80002692:	f84a                	sd	s2,48(sp)
    80002694:	f44e                	sd	s3,40(sp)
    80002696:	f052                	sd	s4,32(sp)
    80002698:	ec56                	sd	s5,24(sp)
    8000269a:	e85a                	sd	s6,16(sp)
    8000269c:	e45e                	sd	s7,8(sp)
    8000269e:	e062                	sd	s8,0(sp)
    800026a0:	0880                	addi	s0,sp,80
    800026a2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800026a4:	fffff097          	auipc	ra,0xfffff
    800026a8:	75c080e7          	jalr	1884(ra) # 80001e00 <myproc>
    800026ac:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800026ae:	0000f517          	auipc	a0,0xf
    800026b2:	14a50513          	addi	a0,a0,330 # 800117f8 <wait_lock>
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	52e080e7          	jalr	1326(ra) # 80000be4 <acquire>
    havekids = 0;
    800026be:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800026c0:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800026c2:	00015997          	auipc	s3,0x15
    800026c6:	54e98993          	addi	s3,s3,1358 # 80017c10 <tickslock>
        havekids = 1;
    800026ca:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800026cc:	0000fc17          	auipc	s8,0xf
    800026d0:	12cc0c13          	addi	s8,s8,300 # 800117f8 <wait_lock>
    havekids = 0;
    800026d4:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800026d6:	0000f497          	auipc	s1,0xf
    800026da:	13a48493          	addi	s1,s1,314 # 80011810 <proc>
    800026de:	a0bd                	j	8000274c <wait+0xc2>
          pid = np->pid;
    800026e0:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800026e4:	000b0e63          	beqz	s6,80002700 <wait+0x76>
    800026e8:	4691                	li	a3,4
    800026ea:	02c48613          	addi	a2,s1,44
    800026ee:	85da                	mv	a1,s6
    800026f0:	05093503          	ld	a0,80(s2)
    800026f4:	fffff097          	auipc	ra,0xfffff
    800026f8:	f7e080e7          	jalr	-130(ra) # 80001672 <copyout>
    800026fc:	02054563          	bltz	a0,80002726 <wait+0x9c>
          freeproc(np);
    80002700:	8526                	mv	a0,s1
    80002702:	00000097          	auipc	ra,0x0
    80002706:	8aa080e7          	jalr	-1878(ra) # 80001fac <freeproc>
          release(&np->lock);
    8000270a:	8526                	mv	a0,s1
    8000270c:	ffffe097          	auipc	ra,0xffffe
    80002710:	58c080e7          	jalr	1420(ra) # 80000c98 <release>
          release(&wait_lock);
    80002714:	0000f517          	auipc	a0,0xf
    80002718:	0e450513          	addi	a0,a0,228 # 800117f8 <wait_lock>
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	57c080e7          	jalr	1404(ra) # 80000c98 <release>
          return pid;
    80002724:	a09d                	j	8000278a <wait+0x100>
            release(&np->lock);
    80002726:	8526                	mv	a0,s1
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	570080e7          	jalr	1392(ra) # 80000c98 <release>
            release(&wait_lock);
    80002730:	0000f517          	auipc	a0,0xf
    80002734:	0c850513          	addi	a0,a0,200 # 800117f8 <wait_lock>
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	560080e7          	jalr	1376(ra) # 80000c98 <release>
            return -1;
    80002740:	59fd                	li	s3,-1
    80002742:	a0a1                	j	8000278a <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002744:	19048493          	addi	s1,s1,400
    80002748:	03348463          	beq	s1,s3,80002770 <wait+0xe6>
      if(np->parent == p){
    8000274c:	7c9c                	ld	a5,56(s1)
    8000274e:	ff279be3          	bne	a5,s2,80002744 <wait+0xba>
        acquire(&np->lock);
    80002752:	8526                	mv	a0,s1
    80002754:	ffffe097          	auipc	ra,0xffffe
    80002758:	490080e7          	jalr	1168(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000275c:	4c9c                	lw	a5,24(s1)
    8000275e:	f94781e3          	beq	a5,s4,800026e0 <wait+0x56>
        release(&np->lock);
    80002762:	8526                	mv	a0,s1
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
        havekids = 1;
    8000276c:	8756                	mv	a4,s5
    8000276e:	bfd9                	j	80002744 <wait+0xba>
    if(!havekids || p->killed){
    80002770:	c701                	beqz	a4,80002778 <wait+0xee>
    80002772:	02892783          	lw	a5,40(s2)
    80002776:	c79d                	beqz	a5,800027a4 <wait+0x11a>
      release(&wait_lock);
    80002778:	0000f517          	auipc	a0,0xf
    8000277c:	08050513          	addi	a0,a0,128 # 800117f8 <wait_lock>
    80002780:	ffffe097          	auipc	ra,0xffffe
    80002784:	518080e7          	jalr	1304(ra) # 80000c98 <release>
      return -1;
    80002788:	59fd                	li	s3,-1
}
    8000278a:	854e                	mv	a0,s3
    8000278c:	60a6                	ld	ra,72(sp)
    8000278e:	6406                	ld	s0,64(sp)
    80002790:	74e2                	ld	s1,56(sp)
    80002792:	7942                	ld	s2,48(sp)
    80002794:	79a2                	ld	s3,40(sp)
    80002796:	7a02                	ld	s4,32(sp)
    80002798:	6ae2                	ld	s5,24(sp)
    8000279a:	6b42                	ld	s6,16(sp)
    8000279c:	6ba2                	ld	s7,8(sp)
    8000279e:	6c02                	ld	s8,0(sp)
    800027a0:	6161                	addi	sp,sp,80
    800027a2:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800027a4:	85e2                	mv	a1,s8
    800027a6:	854a                	mv	a0,s2
    800027a8:	00000097          	auipc	ra,0x0
    800027ac:	e6c080e7          	jalr	-404(ra) # 80002614 <sleep>
    havekids = 0;
    800027b0:	b715                	j	800026d4 <wait+0x4a>

00000000800027b2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800027b2:	7159                	addi	sp,sp,-112
    800027b4:	f486                	sd	ra,104(sp)
    800027b6:	f0a2                	sd	s0,96(sp)
    800027b8:	eca6                	sd	s1,88(sp)
    800027ba:	e8ca                	sd	s2,80(sp)
    800027bc:	e4ce                	sd	s3,72(sp)
    800027be:	e0d2                	sd	s4,64(sp)
    800027c0:	fc56                	sd	s5,56(sp)
    800027c2:	f85a                	sd	s6,48(sp)
    800027c4:	f45e                	sd	s7,40(sp)
    800027c6:	f062                	sd	s8,32(sp)
    800027c8:	ec66                	sd	s9,24(sp)
    800027ca:	e86a                	sd	s10,16(sp)
    800027cc:	e46e                	sd	s11,8(sp)
    800027ce:	1880                	addi	s0,sp,112
    800027d0:	8c2a                	mv	s8,a0
  struct proc *p;
  struct cpu *c;
  int curr = get_head(&sleeping_list);
    800027d2:	00006517          	auipc	a0,0x6
    800027d6:	11e50513          	addi	a0,a0,286 # 800088f0 <sleeping_list>
    800027da:	fffff097          	auipc	ra,0xfffff
    800027de:	220080e7          	jalr	544(ra) # 800019fa <get_head>

  while(curr != -1) {
    800027e2:	57fd                	li	a5,-1
    800027e4:	08f50e63          	beq	a0,a5,80002880 <wakeup+0xce>
    800027e8:	892a                	mv	s2,a0
    p = &proc[curr];
    800027ea:	19000a93          	li	s5,400
    800027ee:	0000fa17          	auipc	s4,0xf
    800027f2:	022a0a13          	addi	s4,s4,34 # 80011810 <proc>
    curr = p->next_proc;
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800027f6:	4b89                	li	s7,2
        remove(&sleeping_list, p);
        p->state = RUNNABLE;
    800027f8:	4d8d                	li	s11,3
    800027fa:	0a800d13          	li	s10,168

        #ifdef ON
          p->last_cpu = min_cpu_process_count(); // case BLNCFLG=ON -> cpu = CPU with the lowest counter value
        #endif
        c = &cpus[p->last_cpu];
    800027fe:	0000fc97          	auipc	s9,0xf
    80002802:	aa2c8c93          	addi	s9,s9,-1374 # 800112a0 <cpus>
  while(curr != -1) {
    80002806:	5b7d                	li	s6,-1
    80002808:	a801                	j	80002818 <wakeup+0x66>
        increment_cpu_process_count(c);

        append(&(c->runnable_list), p);
      }
      release(&p->lock);
    8000280a:	8526                	mv	a0,s1
    8000280c:	ffffe097          	auipc	ra,0xffffe
    80002810:	48c080e7          	jalr	1164(ra) # 80000c98 <release>
  while(curr != -1) {
    80002814:	07690663          	beq	s2,s6,80002880 <wakeup+0xce>
    p = &proc[curr];
    80002818:	035904b3          	mul	s1,s2,s5
    8000281c:	94d2                	add	s1,s1,s4
    curr = p->next_proc;
    8000281e:	16c4a903          	lw	s2,364(s1)
    if(p != myproc()){
    80002822:	fffff097          	auipc	ra,0xfffff
    80002826:	5de080e7          	jalr	1502(ra) # 80001e00 <myproc>
    8000282a:	fea485e3          	beq	s1,a0,80002814 <wakeup+0x62>
      acquire(&p->lock);
    8000282e:	8526                	mv	a0,s1
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	3b4080e7          	jalr	948(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002838:	4c9c                	lw	a5,24(s1)
    8000283a:	fd7798e3          	bne	a5,s7,8000280a <wakeup+0x58>
    8000283e:	709c                	ld	a5,32(s1)
    80002840:	fd8795e3          	bne	a5,s8,8000280a <wakeup+0x58>
        remove(&sleeping_list, p);
    80002844:	85a6                	mv	a1,s1
    80002846:	00006517          	auipc	a0,0x6
    8000284a:	0aa50513          	addi	a0,a0,170 # 800088f0 <sleeping_list>
    8000284e:	fffff097          	auipc	ra,0xfffff
    80002852:	2ca080e7          	jalr	714(ra) # 80001b18 <remove>
        p->state = RUNNABLE;
    80002856:	01b4ac23          	sw	s11,24(s1)
        c = &cpus[p->last_cpu];
    8000285a:	1684a983          	lw	s3,360(s1)
    8000285e:	03a989b3          	mul	s3,s3,s10
        increment_cpu_process_count(c);
    80002862:	013c8533          	add	a0,s9,s3
    80002866:	fffff097          	auipc	ra,0xfffff
    8000286a:	fd8080e7          	jalr	-40(ra) # 8000183e <increment_cpu_process_count>
        append(&(c->runnable_list), p);
    8000286e:	08898513          	addi	a0,s3,136
    80002872:	85a6                	mv	a1,s1
    80002874:	9566                	add	a0,a0,s9
    80002876:	fffff097          	auipc	ra,0xfffff
    8000287a:	1da080e7          	jalr	474(ra) # 80001a50 <append>
    8000287e:	b771                	j	8000280a <wakeup+0x58>
    }
  }
}
    80002880:	70a6                	ld	ra,104(sp)
    80002882:	7406                	ld	s0,96(sp)
    80002884:	64e6                	ld	s1,88(sp)
    80002886:	6946                	ld	s2,80(sp)
    80002888:	69a6                	ld	s3,72(sp)
    8000288a:	6a06                	ld	s4,64(sp)
    8000288c:	7ae2                	ld	s5,56(sp)
    8000288e:	7b42                	ld	s6,48(sp)
    80002890:	7ba2                	ld	s7,40(sp)
    80002892:	7c02                	ld	s8,32(sp)
    80002894:	6ce2                	ld	s9,24(sp)
    80002896:	6d42                	ld	s10,16(sp)
    80002898:	6da2                	ld	s11,8(sp)
    8000289a:	6165                	addi	sp,sp,112
    8000289c:	8082                	ret

000000008000289e <reparent>:
{
    8000289e:	7179                	addi	sp,sp,-48
    800028a0:	f406                	sd	ra,40(sp)
    800028a2:	f022                	sd	s0,32(sp)
    800028a4:	ec26                	sd	s1,24(sp)
    800028a6:	e84a                	sd	s2,16(sp)
    800028a8:	e44e                	sd	s3,8(sp)
    800028aa:	e052                	sd	s4,0(sp)
    800028ac:	1800                	addi	s0,sp,48
    800028ae:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800028b0:	0000f497          	auipc	s1,0xf
    800028b4:	f6048493          	addi	s1,s1,-160 # 80011810 <proc>
      pp->parent = initproc;
    800028b8:	00006a17          	auipc	s4,0x6
    800028bc:	770a0a13          	addi	s4,s4,1904 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800028c0:	00015997          	auipc	s3,0x15
    800028c4:	35098993          	addi	s3,s3,848 # 80017c10 <tickslock>
    800028c8:	a029                	j	800028d2 <reparent+0x34>
    800028ca:	19048493          	addi	s1,s1,400
    800028ce:	01348d63          	beq	s1,s3,800028e8 <reparent+0x4a>
    if(pp->parent == p){
    800028d2:	7c9c                	ld	a5,56(s1)
    800028d4:	ff279be3          	bne	a5,s2,800028ca <reparent+0x2c>
      pp->parent = initproc;
    800028d8:	000a3503          	ld	a0,0(s4)
    800028dc:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800028de:	00000097          	auipc	ra,0x0
    800028e2:	ed4080e7          	jalr	-300(ra) # 800027b2 <wakeup>
    800028e6:	b7d5                	j	800028ca <reparent+0x2c>
}
    800028e8:	70a2                	ld	ra,40(sp)
    800028ea:	7402                	ld	s0,32(sp)
    800028ec:	64e2                	ld	s1,24(sp)
    800028ee:	6942                	ld	s2,16(sp)
    800028f0:	69a2                	ld	s3,8(sp)
    800028f2:	6a02                	ld	s4,0(sp)
    800028f4:	6145                	addi	sp,sp,48
    800028f6:	8082                	ret

00000000800028f8 <exit>:
{
    800028f8:	7179                	addi	sp,sp,-48
    800028fa:	f406                	sd	ra,40(sp)
    800028fc:	f022                	sd	s0,32(sp)
    800028fe:	ec26                	sd	s1,24(sp)
    80002900:	e84a                	sd	s2,16(sp)
    80002902:	e44e                	sd	s3,8(sp)
    80002904:	e052                	sd	s4,0(sp)
    80002906:	1800                	addi	s0,sp,48
    80002908:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000290a:	fffff097          	auipc	ra,0xfffff
    8000290e:	4f6080e7          	jalr	1270(ra) # 80001e00 <myproc>
    80002912:	89aa                	mv	s3,a0
  if(p == initproc)
    80002914:	00006797          	auipc	a5,0x6
    80002918:	7147b783          	ld	a5,1812(a5) # 80009028 <initproc>
    8000291c:	0d050493          	addi	s1,a0,208
    80002920:	15050913          	addi	s2,a0,336
    80002924:	02a79363          	bne	a5,a0,8000294a <exit+0x52>
    panic("init exiting");
    80002928:	00006517          	auipc	a0,0x6
    8000292c:	9e050513          	addi	a0,a0,-1568 # 80008308 <digits+0x2c8>
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	c0e080e7          	jalr	-1010(ra) # 8000053e <panic>
      fileclose(f);
    80002938:	00002097          	auipc	ra,0x2
    8000293c:	262080e7          	jalr	610(ra) # 80004b9a <fileclose>
      p->ofile[fd] = 0;
    80002940:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002944:	04a1                	addi	s1,s1,8
    80002946:	01248563          	beq	s1,s2,80002950 <exit+0x58>
    if(p->ofile[fd]){
    8000294a:	6088                	ld	a0,0(s1)
    8000294c:	f575                	bnez	a0,80002938 <exit+0x40>
    8000294e:	bfdd                	j	80002944 <exit+0x4c>
  begin_op();
    80002950:	00002097          	auipc	ra,0x2
    80002954:	d7e080e7          	jalr	-642(ra) # 800046ce <begin_op>
  iput(p->cwd);
    80002958:	1509b503          	ld	a0,336(s3)
    8000295c:	00001097          	auipc	ra,0x1
    80002960:	55a080e7          	jalr	1370(ra) # 80003eb6 <iput>
  end_op();
    80002964:	00002097          	auipc	ra,0x2
    80002968:	dea080e7          	jalr	-534(ra) # 8000474e <end_op>
  p->cwd = 0;
    8000296c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002970:	0000f497          	auipc	s1,0xf
    80002974:	e8848493          	addi	s1,s1,-376 # 800117f8 <wait_lock>
    80002978:	8526                	mv	a0,s1
    8000297a:	ffffe097          	auipc	ra,0xffffe
    8000297e:	26a080e7          	jalr	618(ra) # 80000be4 <acquire>
  reparent(p);
    80002982:	854e                	mv	a0,s3
    80002984:	00000097          	auipc	ra,0x0
    80002988:	f1a080e7          	jalr	-230(ra) # 8000289e <reparent>
  wakeup(p->parent);
    8000298c:	0389b503          	ld	a0,56(s3)
    80002990:	00000097          	auipc	ra,0x0
    80002994:	e22080e7          	jalr	-478(ra) # 800027b2 <wakeup>
  acquire(&p->lock);
    80002998:	854e                	mv	a0,s3
    8000299a:	ffffe097          	auipc	ra,0xffffe
    8000299e:	24a080e7          	jalr	586(ra) # 80000be4 <acquire>
  p->xstate = status;
    800029a2:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800029a6:	4795                	li	a5,5
    800029a8:	00f9ac23          	sw	a5,24(s3)
  append(&zombie_list, p); // exit to admit the exiting process to the ZOMBIE list
    800029ac:	85ce                	mv	a1,s3
    800029ae:	00006517          	auipc	a0,0x6
    800029b2:	f6250513          	addi	a0,a0,-158 # 80008910 <zombie_list>
    800029b6:	fffff097          	auipc	ra,0xfffff
    800029ba:	09a080e7          	jalr	154(ra) # 80001a50 <append>
  release(&wait_lock);
    800029be:	8526                	mv	a0,s1
    800029c0:	ffffe097          	auipc	ra,0xffffe
    800029c4:	2d8080e7          	jalr	728(ra) # 80000c98 <release>
  sched();
    800029c8:	00000097          	auipc	ra,0x0
    800029cc:	b0a080e7          	jalr	-1270(ra) # 800024d2 <sched>
  panic("zombie exit");
    800029d0:	00006517          	auipc	a0,0x6
    800029d4:	94850513          	addi	a0,a0,-1720 # 80008318 <digits+0x2d8>
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	b66080e7          	jalr	-1178(ra) # 8000053e <panic>

00000000800029e0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800029e0:	7179                	addi	sp,sp,-48
    800029e2:	f406                	sd	ra,40(sp)
    800029e4:	f022                	sd	s0,32(sp)
    800029e6:	ec26                	sd	s1,24(sp)
    800029e8:	e84a                	sd	s2,16(sp)
    800029ea:	e44e                	sd	s3,8(sp)
    800029ec:	1800                	addi	s0,sp,48
    800029ee:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800029f0:	0000f497          	auipc	s1,0xf
    800029f4:	e2048493          	addi	s1,s1,-480 # 80011810 <proc>
    800029f8:	00015997          	auipc	s3,0x15
    800029fc:	21898993          	addi	s3,s3,536 # 80017c10 <tickslock>
    acquire(&p->lock);
    80002a00:	8526                	mv	a0,s1
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	1e2080e7          	jalr	482(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002a0a:	589c                	lw	a5,48(s1)
    80002a0c:	01278d63          	beq	a5,s2,80002a26 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002a10:	8526                	mv	a0,s1
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	286080e7          	jalr	646(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a1a:	19048493          	addi	s1,s1,400
    80002a1e:	ff3491e3          	bne	s1,s3,80002a00 <kill+0x20>
  }
  return -1;
    80002a22:	557d                	li	a0,-1
    80002a24:	a829                	j	80002a3e <kill+0x5e>
      p->killed = 1;
    80002a26:	4785                	li	a5,1
    80002a28:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002a2a:	4c98                	lw	a4,24(s1)
    80002a2c:	4789                	li	a5,2
    80002a2e:	00f70f63          	beq	a4,a5,80002a4c <kill+0x6c>
      release(&p->lock);
    80002a32:	8526                	mv	a0,s1
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	264080e7          	jalr	612(ra) # 80000c98 <release>
      return 0;
    80002a3c:	4501                	li	a0,0
}
    80002a3e:	70a2                	ld	ra,40(sp)
    80002a40:	7402                	ld	s0,32(sp)
    80002a42:	64e2                	ld	s1,24(sp)
    80002a44:	6942                	ld	s2,16(sp)
    80002a46:	69a2                	ld	s3,8(sp)
    80002a48:	6145                	addi	sp,sp,48
    80002a4a:	8082                	ret
        p->state = RUNNABLE;
    80002a4c:	478d                	li	a5,3
    80002a4e:	cc9c                	sw	a5,24(s1)
    80002a50:	b7cd                	j	80002a32 <kill+0x52>

0000000080002a52 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002a52:	7179                	addi	sp,sp,-48
    80002a54:	f406                	sd	ra,40(sp)
    80002a56:	f022                	sd	s0,32(sp)
    80002a58:	ec26                	sd	s1,24(sp)
    80002a5a:	e84a                	sd	s2,16(sp)
    80002a5c:	e44e                	sd	s3,8(sp)
    80002a5e:	e052                	sd	s4,0(sp)
    80002a60:	1800                	addi	s0,sp,48
    80002a62:	84aa                	mv	s1,a0
    80002a64:	892e                	mv	s2,a1
    80002a66:	89b2                	mv	s3,a2
    80002a68:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a6a:	fffff097          	auipc	ra,0xfffff
    80002a6e:	396080e7          	jalr	918(ra) # 80001e00 <myproc>
  if(user_dst){
    80002a72:	c08d                	beqz	s1,80002a94 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002a74:	86d2                	mv	a3,s4
    80002a76:	864e                	mv	a2,s3
    80002a78:	85ca                	mv	a1,s2
    80002a7a:	6928                	ld	a0,80(a0)
    80002a7c:	fffff097          	auipc	ra,0xfffff
    80002a80:	bf6080e7          	jalr	-1034(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002a84:	70a2                	ld	ra,40(sp)
    80002a86:	7402                	ld	s0,32(sp)
    80002a88:	64e2                	ld	s1,24(sp)
    80002a8a:	6942                	ld	s2,16(sp)
    80002a8c:	69a2                	ld	s3,8(sp)
    80002a8e:	6a02                	ld	s4,0(sp)
    80002a90:	6145                	addi	sp,sp,48
    80002a92:	8082                	ret
    memmove((char *)dst, src, len);
    80002a94:	000a061b          	sext.w	a2,s4
    80002a98:	85ce                	mv	a1,s3
    80002a9a:	854a                	mv	a0,s2
    80002a9c:	ffffe097          	auipc	ra,0xffffe
    80002aa0:	2a4080e7          	jalr	676(ra) # 80000d40 <memmove>
    return 0;
    80002aa4:	8526                	mv	a0,s1
    80002aa6:	bff9                	j	80002a84 <either_copyout+0x32>

0000000080002aa8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002aa8:	7179                	addi	sp,sp,-48
    80002aaa:	f406                	sd	ra,40(sp)
    80002aac:	f022                	sd	s0,32(sp)
    80002aae:	ec26                	sd	s1,24(sp)
    80002ab0:	e84a                	sd	s2,16(sp)
    80002ab2:	e44e                	sd	s3,8(sp)
    80002ab4:	e052                	sd	s4,0(sp)
    80002ab6:	1800                	addi	s0,sp,48
    80002ab8:	892a                	mv	s2,a0
    80002aba:	84ae                	mv	s1,a1
    80002abc:	89b2                	mv	s3,a2
    80002abe:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002ac0:	fffff097          	auipc	ra,0xfffff
    80002ac4:	340080e7          	jalr	832(ra) # 80001e00 <myproc>
  if(user_src){
    80002ac8:	c08d                	beqz	s1,80002aea <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002aca:	86d2                	mv	a3,s4
    80002acc:	864e                	mv	a2,s3
    80002ace:	85ca                	mv	a1,s2
    80002ad0:	6928                	ld	a0,80(a0)
    80002ad2:	fffff097          	auipc	ra,0xfffff
    80002ad6:	c2c080e7          	jalr	-980(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002ada:	70a2                	ld	ra,40(sp)
    80002adc:	7402                	ld	s0,32(sp)
    80002ade:	64e2                	ld	s1,24(sp)
    80002ae0:	6942                	ld	s2,16(sp)
    80002ae2:	69a2                	ld	s3,8(sp)
    80002ae4:	6a02                	ld	s4,0(sp)
    80002ae6:	6145                	addi	sp,sp,48
    80002ae8:	8082                	ret
    memmove(dst, (char*)src, len);
    80002aea:	000a061b          	sext.w	a2,s4
    80002aee:	85ce                	mv	a1,s3
    80002af0:	854a                	mv	a0,s2
    80002af2:	ffffe097          	auipc	ra,0xffffe
    80002af6:	24e080e7          	jalr	590(ra) # 80000d40 <memmove>
    return 0;
    80002afa:	8526                	mv	a0,s1
    80002afc:	bff9                	j	80002ada <either_copyin+0x32>

0000000080002afe <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    80002afe:	715d                	addi	sp,sp,-80
    80002b00:	e486                	sd	ra,72(sp)
    80002b02:	e0a2                	sd	s0,64(sp)
    80002b04:	fc26                	sd	s1,56(sp)
    80002b06:	f84a                	sd	s2,48(sp)
    80002b08:	f44e                	sd	s3,40(sp)
    80002b0a:	f052                	sd	s4,32(sp)
    80002b0c:	ec56                	sd	s5,24(sp)
    80002b0e:	e85a                	sd	s6,16(sp)
    80002b10:	e45e                	sd	s7,8(sp)
    80002b12:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002b14:	00005517          	auipc	a0,0x5
    80002b18:	5b450513          	addi	a0,a0,1460 # 800080c8 <digits+0x88>
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	a6c080e7          	jalr	-1428(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b24:	0000f497          	auipc	s1,0xf
    80002b28:	e4448493          	addi	s1,s1,-444 # 80011968 <proc+0x158>
    80002b2c:	00015917          	auipc	s2,0x15
    80002b30:	23c90913          	addi	s2,s2,572 # 80017d68 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b34:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    80002b36:	00005997          	auipc	s3,0x5
    80002b3a:	7f298993          	addi	s3,s3,2034 # 80008328 <digits+0x2e8>
    printf("%d %s %s", p->pid, state, p->name);
    80002b3e:	00005a97          	auipc	s5,0x5
    80002b42:	7f2a8a93          	addi	s5,s5,2034 # 80008330 <digits+0x2f0>
    printf("\n");
    80002b46:	00005a17          	auipc	s4,0x5
    80002b4a:	582a0a13          	addi	s4,s4,1410 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b4e:	00006b97          	auipc	s7,0x6
    80002b52:	81ab8b93          	addi	s7,s7,-2022 # 80008368 <states.1792>
    80002b56:	a00d                	j	80002b78 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002b58:	ed86a583          	lw	a1,-296(a3)
    80002b5c:	8556                	mv	a0,s5
    80002b5e:	ffffe097          	auipc	ra,0xffffe
    80002b62:	a2a080e7          	jalr	-1494(ra) # 80000588 <printf>
    printf("\n");
    80002b66:	8552                	mv	a0,s4
    80002b68:	ffffe097          	auipc	ra,0xffffe
    80002b6c:	a20080e7          	jalr	-1504(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b70:	19048493          	addi	s1,s1,400
    80002b74:	03248163          	beq	s1,s2,80002b96 <procdump+0x98>
    if(p->state == UNUSED)
    80002b78:	86a6                	mv	a3,s1
    80002b7a:	ec04a783          	lw	a5,-320(s1)
    80002b7e:	dbed                	beqz	a5,80002b70 <procdump+0x72>
      state = "???"; 
    80002b80:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b82:	fcfb6be3          	bltu	s6,a5,80002b58 <procdump+0x5a>
    80002b86:	1782                	slli	a5,a5,0x20
    80002b88:	9381                	srli	a5,a5,0x20
    80002b8a:	078e                	slli	a5,a5,0x3
    80002b8c:	97de                	add	a5,a5,s7
    80002b8e:	6390                	ld	a2,0(a5)
    80002b90:	f661                	bnez	a2,80002b58 <procdump+0x5a>
      state = "???"; 
    80002b92:	864e                	mv	a2,s3
    80002b94:	b7d1                	j	80002b58 <procdump+0x5a>
  }
}
    80002b96:	60a6                	ld	ra,72(sp)
    80002b98:	6406                	ld	s0,64(sp)
    80002b9a:	74e2                	ld	s1,56(sp)
    80002b9c:	7942                	ld	s2,48(sp)
    80002b9e:	79a2                	ld	s3,40(sp)
    80002ba0:	7a02                	ld	s4,32(sp)
    80002ba2:	6ae2                	ld	s5,24(sp)
    80002ba4:	6b42                	ld	s6,16(sp)
    80002ba6:	6ba2                	ld	s7,8(sp)
    80002ba8:	6161                	addi	sp,sp,80
    80002baa:	8082                	ret

0000000080002bac <set_cpu>:

// assign current process to a different CPU. 
int
set_cpu(int cpu_num){
    80002bac:	1101                	addi	sp,sp,-32
    80002bae:	ec06                	sd	ra,24(sp)
    80002bb0:	e822                	sd	s0,16(sp)
    80002bb2:	e426                	sd	s1,8(sp)
    80002bb4:	e04a                	sd	s2,0(sp)
    80002bb6:	1000                	addi	s0,sp,32
    80002bb8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bba:	fffff097          	auipc	ra,0xfffff
    80002bbe:	246080e7          	jalr	582(ra) # 80001e00 <myproc>
  if(cpu_num >= 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL){
    80002bc2:	0004871b          	sext.w	a4,s1
    80002bc6:	479d                	li	a5,7
    80002bc8:	02e7e963          	bltu	a5,a4,80002bfa <set_cpu+0x4e>
    80002bcc:	892a                	mv	s2,a0
    acquire(&p->lock);
    80002bce:	ffffe097          	auipc	ra,0xffffe
    80002bd2:	016080e7          	jalr	22(ra) # 80000be4 <acquire>
    p->last_cpu = cpu_num;
    80002bd6:	16992423          	sw	s1,360(s2)
    release(&p->lock);
    80002bda:	854a                	mv	a0,s2
    80002bdc:	ffffe097          	auipc	ra,0xffffe
    80002be0:	0bc080e7          	jalr	188(ra) # 80000c98 <release>

    yield();
    80002be4:	00000097          	auipc	ra,0x0
    80002be8:	9d0080e7          	jalr	-1584(ra) # 800025b4 <yield>

    return cpu_num;
    80002bec:	8526                	mv	a0,s1
  }
  return -1;
}
    80002bee:	60e2                	ld	ra,24(sp)
    80002bf0:	6442                	ld	s0,16(sp)
    80002bf2:	64a2                	ld	s1,8(sp)
    80002bf4:	6902                	ld	s2,0(sp)
    80002bf6:	6105                	addi	sp,sp,32
    80002bf8:	8082                	ret
  return -1;
    80002bfa:	557d                	li	a0,-1
    80002bfc:	bfcd                	j	80002bee <set_cpu+0x42>

0000000080002bfe <get_cpu>:

// return the current CPU id.
int
get_cpu(void){
    80002bfe:	1141                	addi	sp,sp,-16
    80002c00:	e406                	sd	ra,8(sp)
    80002c02:	e022                	sd	s0,0(sp)
    80002c04:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c06:	fffff097          	auipc	ra,0xfffff
    80002c0a:	1fa080e7          	jalr	506(ra) # 80001e00 <myproc>
  return p->last_cpu;
}
    80002c0e:	16852503          	lw	a0,360(a0)
    80002c12:	60a2                	ld	ra,8(sp)
    80002c14:	6402                	ld	s0,0(sp)
    80002c16:	0141                	addi	sp,sp,16
    80002c18:	8082                	ret

0000000080002c1a <min_cpu>:

int
min_cpu(void){
    80002c1a:	1141                	addi	sp,sp,-16
    80002c1c:	e422                	sd	s0,8(sp)
    80002c1e:	0800                	addi	s0,sp,16
  struct cpu *c, *min_cpu;
// should add an if to insure numberOfCpus>0
  min_cpu = cpus;
    80002c20:	0000e617          	auipc	a2,0xe
    80002c24:	68060613          	addi	a2,a2,1664 # 800112a0 <cpus>
  for(c = cpus + 1; c < &cpus[NCPU] && c != NULL ; c++){
    80002c28:	0000e797          	auipc	a5,0xe
    80002c2c:	72078793          	addi	a5,a5,1824 # 80011348 <cpus+0xa8>
    80002c30:	0000f597          	auipc	a1,0xf
    80002c34:	bb058593          	addi	a1,a1,-1104 # 800117e0 <pid_lock>
    80002c38:	a029                	j	80002c42 <min_cpu+0x28>
    80002c3a:	0a878793          	addi	a5,a5,168
    80002c3e:	00b78a63          	beq	a5,a1,80002c52 <min_cpu+0x38>
    if (c->proc_cnt < min_cpu->proc_cnt)
    80002c42:	0807a683          	lw	a3,128(a5)
    80002c46:	08062703          	lw	a4,128(a2)
    80002c4a:	fee6d8e3          	bge	a3,a4,80002c3a <min_cpu+0x20>
    80002c4e:	863e                	mv	a2,a5
    80002c50:	b7ed                	j	80002c3a <min_cpu+0x20>
        min_cpu = c;
  }
  return min_cpu->cpu_id;   
}
    80002c52:	08462503          	lw	a0,132(a2)
    80002c56:	6422                	ld	s0,8(sp)
    80002c58:	0141                	addi	sp,sp,16
    80002c5a:	8082                	ret

0000000080002c5c <cpu_process_count>:

int
cpu_process_count(int cpu_num){
    80002c5c:	1141                	addi	sp,sp,-16
    80002c5e:	e422                	sd	s0,8(sp)
    80002c60:	0800                	addi	s0,sp,16
  if (cpu_num > 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL) 
    80002c62:	fff5071b          	addiw	a4,a0,-1
    80002c66:	4799                	li	a5,6
    80002c68:	02e7e063          	bltu	a5,a4,80002c88 <cpu_process_count+0x2c>
    return cpus[cpu_num].proc_cnt;
    80002c6c:	0a800793          	li	a5,168
    80002c70:	02f50533          	mul	a0,a0,a5
    80002c74:	0000e797          	auipc	a5,0xe
    80002c78:	62c78793          	addi	a5,a5,1580 # 800112a0 <cpus>
    80002c7c:	953e                	add	a0,a0,a5
    80002c7e:	08052503          	lw	a0,128(a0)
  return -1;
}
    80002c82:	6422                	ld	s0,8(sp)
    80002c84:	0141                	addi	sp,sp,16
    80002c86:	8082                	ret
  return -1;
    80002c88:	557d                	li	a0,-1
    80002c8a:	bfe5                	j	80002c82 <cpu_process_count+0x26>

0000000080002c8c <steal_process>:




void
steal_process(struct cpu *curr_c){  /*
    80002c8c:	1141                	addi	sp,sp,-16
    80002c8e:	e422                	sd	s0,8(sp)
    80002c90:	0800                	addi	s0,sp,16
  }
  p = proc[stolen_process];
  append(&c->runnable_list, p);
  p->last_cpu = c->cpu_id;
  increment_cpu_process_count(c); */
    80002c92:	6422                	ld	s0,8(sp)
    80002c94:	0141                	addi	sp,sp,16
    80002c96:	8082                	ret

0000000080002c98 <swtch>:
    80002c98:	00153023          	sd	ra,0(a0)
    80002c9c:	00253423          	sd	sp,8(a0)
    80002ca0:	e900                	sd	s0,16(a0)
    80002ca2:	ed04                	sd	s1,24(a0)
    80002ca4:	03253023          	sd	s2,32(a0)
    80002ca8:	03353423          	sd	s3,40(a0)
    80002cac:	03453823          	sd	s4,48(a0)
    80002cb0:	03553c23          	sd	s5,56(a0)
    80002cb4:	05653023          	sd	s6,64(a0)
    80002cb8:	05753423          	sd	s7,72(a0)
    80002cbc:	05853823          	sd	s8,80(a0)
    80002cc0:	05953c23          	sd	s9,88(a0)
    80002cc4:	07a53023          	sd	s10,96(a0)
    80002cc8:	07b53423          	sd	s11,104(a0)
    80002ccc:	0005b083          	ld	ra,0(a1)
    80002cd0:	0085b103          	ld	sp,8(a1)
    80002cd4:	6980                	ld	s0,16(a1)
    80002cd6:	6d84                	ld	s1,24(a1)
    80002cd8:	0205b903          	ld	s2,32(a1)
    80002cdc:	0285b983          	ld	s3,40(a1)
    80002ce0:	0305ba03          	ld	s4,48(a1)
    80002ce4:	0385ba83          	ld	s5,56(a1)
    80002ce8:	0405bb03          	ld	s6,64(a1)
    80002cec:	0485bb83          	ld	s7,72(a1)
    80002cf0:	0505bc03          	ld	s8,80(a1)
    80002cf4:	0585bc83          	ld	s9,88(a1)
    80002cf8:	0605bd03          	ld	s10,96(a1)
    80002cfc:	0685bd83          	ld	s11,104(a1)
    80002d00:	8082                	ret

0000000080002d02 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002d02:	1141                	addi	sp,sp,-16
    80002d04:	e406                	sd	ra,8(sp)
    80002d06:	e022                	sd	s0,0(sp)
    80002d08:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002d0a:	00005597          	auipc	a1,0x5
    80002d0e:	68e58593          	addi	a1,a1,1678 # 80008398 <states.1792+0x30>
    80002d12:	00015517          	auipc	a0,0x15
    80002d16:	efe50513          	addi	a0,a0,-258 # 80017c10 <tickslock>
    80002d1a:	ffffe097          	auipc	ra,0xffffe
    80002d1e:	e3a080e7          	jalr	-454(ra) # 80000b54 <initlock>
}
    80002d22:	60a2                	ld	ra,8(sp)
    80002d24:	6402                	ld	s0,0(sp)
    80002d26:	0141                	addi	sp,sp,16
    80002d28:	8082                	ret

0000000080002d2a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002d2a:	1141                	addi	sp,sp,-16
    80002d2c:	e422                	sd	s0,8(sp)
    80002d2e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d30:	00003797          	auipc	a5,0x3
    80002d34:	48078793          	addi	a5,a5,1152 # 800061b0 <kernelvec>
    80002d38:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002d3c:	6422                	ld	s0,8(sp)
    80002d3e:	0141                	addi	sp,sp,16
    80002d40:	8082                	ret

0000000080002d42 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002d42:	1141                	addi	sp,sp,-16
    80002d44:	e406                	sd	ra,8(sp)
    80002d46:	e022                	sd	s0,0(sp)
    80002d48:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002d4a:	fffff097          	auipc	ra,0xfffff
    80002d4e:	0b6080e7          	jalr	182(ra) # 80001e00 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d52:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002d56:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d58:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002d5c:	00004617          	auipc	a2,0x4
    80002d60:	2a460613          	addi	a2,a2,676 # 80007000 <_trampoline>
    80002d64:	00004697          	auipc	a3,0x4
    80002d68:	29c68693          	addi	a3,a3,668 # 80007000 <_trampoline>
    80002d6c:	8e91                	sub	a3,a3,a2
    80002d6e:	040007b7          	lui	a5,0x4000
    80002d72:	17fd                	addi	a5,a5,-1
    80002d74:	07b2                	slli	a5,a5,0xc
    80002d76:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d78:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d7c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d7e:	180026f3          	csrr	a3,satp
    80002d82:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d84:	6d38                	ld	a4,88(a0)
    80002d86:	6134                	ld	a3,64(a0)
    80002d88:	6585                	lui	a1,0x1
    80002d8a:	96ae                	add	a3,a3,a1
    80002d8c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d8e:	6d38                	ld	a4,88(a0)
    80002d90:	00000697          	auipc	a3,0x0
    80002d94:	13868693          	addi	a3,a3,312 # 80002ec8 <usertrap>
    80002d98:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002d9a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d9c:	8692                	mv	a3,tp
    80002d9e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002da0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002da4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002da8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dac:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002db0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002db2:	6f18                	ld	a4,24(a4)
    80002db4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002db8:	692c                	ld	a1,80(a0)
    80002dba:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002dbc:	00004717          	auipc	a4,0x4
    80002dc0:	2d470713          	addi	a4,a4,724 # 80007090 <userret>
    80002dc4:	8f11                	sub	a4,a4,a2
    80002dc6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002dc8:	577d                	li	a4,-1
    80002dca:	177e                	slli	a4,a4,0x3f
    80002dcc:	8dd9                	or	a1,a1,a4
    80002dce:	02000537          	lui	a0,0x2000
    80002dd2:	157d                	addi	a0,a0,-1
    80002dd4:	0536                	slli	a0,a0,0xd
    80002dd6:	9782                	jalr	a5
}
    80002dd8:	60a2                	ld	ra,8(sp)
    80002dda:	6402                	ld	s0,0(sp)
    80002ddc:	0141                	addi	sp,sp,16
    80002dde:	8082                	ret

0000000080002de0 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002de0:	1101                	addi	sp,sp,-32
    80002de2:	ec06                	sd	ra,24(sp)
    80002de4:	e822                	sd	s0,16(sp)
    80002de6:	e426                	sd	s1,8(sp)
    80002de8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002dea:	00015497          	auipc	s1,0x15
    80002dee:	e2648493          	addi	s1,s1,-474 # 80017c10 <tickslock>
    80002df2:	8526                	mv	a0,s1
    80002df4:	ffffe097          	auipc	ra,0xffffe
    80002df8:	df0080e7          	jalr	-528(ra) # 80000be4 <acquire>
  ticks++;
    80002dfc:	00006517          	auipc	a0,0x6
    80002e00:	23450513          	addi	a0,a0,564 # 80009030 <ticks>
    80002e04:	411c                	lw	a5,0(a0)
    80002e06:	2785                	addiw	a5,a5,1
    80002e08:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002e0a:	00000097          	auipc	ra,0x0
    80002e0e:	9a8080e7          	jalr	-1624(ra) # 800027b2 <wakeup>
  release(&tickslock);
    80002e12:	8526                	mv	a0,s1
    80002e14:	ffffe097          	auipc	ra,0xffffe
    80002e18:	e84080e7          	jalr	-380(ra) # 80000c98 <release>
}
    80002e1c:	60e2                	ld	ra,24(sp)
    80002e1e:	6442                	ld	s0,16(sp)
    80002e20:	64a2                	ld	s1,8(sp)
    80002e22:	6105                	addi	sp,sp,32
    80002e24:	8082                	ret

0000000080002e26 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002e26:	1101                	addi	sp,sp,-32
    80002e28:	ec06                	sd	ra,24(sp)
    80002e2a:	e822                	sd	s0,16(sp)
    80002e2c:	e426                	sd	s1,8(sp)
    80002e2e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e30:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002e34:	00074d63          	bltz	a4,80002e4e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002e38:	57fd                	li	a5,-1
    80002e3a:	17fe                	slli	a5,a5,0x3f
    80002e3c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002e3e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002e40:	06f70363          	beq	a4,a5,80002ea6 <devintr+0x80>
  }
}
    80002e44:	60e2                	ld	ra,24(sp)
    80002e46:	6442                	ld	s0,16(sp)
    80002e48:	64a2                	ld	s1,8(sp)
    80002e4a:	6105                	addi	sp,sp,32
    80002e4c:	8082                	ret
     (scause & 0xff) == 9){
    80002e4e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002e52:	46a5                	li	a3,9
    80002e54:	fed792e3          	bne	a5,a3,80002e38 <devintr+0x12>
    int irq = plic_claim();
    80002e58:	00003097          	auipc	ra,0x3
    80002e5c:	460080e7          	jalr	1120(ra) # 800062b8 <plic_claim>
    80002e60:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002e62:	47a9                	li	a5,10
    80002e64:	02f50763          	beq	a0,a5,80002e92 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002e68:	4785                	li	a5,1
    80002e6a:	02f50963          	beq	a0,a5,80002e9c <devintr+0x76>
    return 1;
    80002e6e:	4505                	li	a0,1
    } else if(irq){
    80002e70:	d8f1                	beqz	s1,80002e44 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e72:	85a6                	mv	a1,s1
    80002e74:	00005517          	auipc	a0,0x5
    80002e78:	52c50513          	addi	a0,a0,1324 # 800083a0 <states.1792+0x38>
    80002e7c:	ffffd097          	auipc	ra,0xffffd
    80002e80:	70c080e7          	jalr	1804(ra) # 80000588 <printf>
      plic_complete(irq);
    80002e84:	8526                	mv	a0,s1
    80002e86:	00003097          	auipc	ra,0x3
    80002e8a:	456080e7          	jalr	1110(ra) # 800062dc <plic_complete>
    return 1;
    80002e8e:	4505                	li	a0,1
    80002e90:	bf55                	j	80002e44 <devintr+0x1e>
      uartintr();
    80002e92:	ffffe097          	auipc	ra,0xffffe
    80002e96:	b16080e7          	jalr	-1258(ra) # 800009a8 <uartintr>
    80002e9a:	b7ed                	j	80002e84 <devintr+0x5e>
      virtio_disk_intr();
    80002e9c:	00004097          	auipc	ra,0x4
    80002ea0:	920080e7          	jalr	-1760(ra) # 800067bc <virtio_disk_intr>
    80002ea4:	b7c5                	j	80002e84 <devintr+0x5e>
    if(cpuid() == 0){
    80002ea6:	fffff097          	auipc	ra,0xfffff
    80002eaa:	f28080e7          	jalr	-216(ra) # 80001dce <cpuid>
    80002eae:	c901                	beqz	a0,80002ebe <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002eb0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002eb4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002eb6:	14479073          	csrw	sip,a5
    return 2;
    80002eba:	4509                	li	a0,2
    80002ebc:	b761                	j	80002e44 <devintr+0x1e>
      clockintr();
    80002ebe:	00000097          	auipc	ra,0x0
    80002ec2:	f22080e7          	jalr	-222(ra) # 80002de0 <clockintr>
    80002ec6:	b7ed                	j	80002eb0 <devintr+0x8a>

0000000080002ec8 <usertrap>:
{
    80002ec8:	1101                	addi	sp,sp,-32
    80002eca:	ec06                	sd	ra,24(sp)
    80002ecc:	e822                	sd	s0,16(sp)
    80002ece:	e426                	sd	s1,8(sp)
    80002ed0:	e04a                	sd	s2,0(sp)
    80002ed2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ed4:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ed8:	1007f793          	andi	a5,a5,256
    80002edc:	e3ad                	bnez	a5,80002f3e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ede:	00003797          	auipc	a5,0x3
    80002ee2:	2d278793          	addi	a5,a5,722 # 800061b0 <kernelvec>
    80002ee6:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002eea:	fffff097          	auipc	ra,0xfffff
    80002eee:	f16080e7          	jalr	-234(ra) # 80001e00 <myproc>
    80002ef2:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ef4:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ef6:	14102773          	csrr	a4,sepc
    80002efa:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002efc:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002f00:	47a1                	li	a5,8
    80002f02:	04f71c63          	bne	a4,a5,80002f5a <usertrap+0x92>
    if(p->killed)
    80002f06:	551c                	lw	a5,40(a0)
    80002f08:	e3b9                	bnez	a5,80002f4e <usertrap+0x86>
    p->trapframe->epc += 4;
    80002f0a:	6cb8                	ld	a4,88(s1)
    80002f0c:	6f1c                	ld	a5,24(a4)
    80002f0e:	0791                	addi	a5,a5,4
    80002f10:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f12:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002f16:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f1a:	10079073          	csrw	sstatus,a5
    syscall();
    80002f1e:	00000097          	auipc	ra,0x0
    80002f22:	2e0080e7          	jalr	736(ra) # 800031fe <syscall>
  if(p->killed)
    80002f26:	549c                	lw	a5,40(s1)
    80002f28:	ebc1                	bnez	a5,80002fb8 <usertrap+0xf0>
  usertrapret();
    80002f2a:	00000097          	auipc	ra,0x0
    80002f2e:	e18080e7          	jalr	-488(ra) # 80002d42 <usertrapret>
}
    80002f32:	60e2                	ld	ra,24(sp)
    80002f34:	6442                	ld	s0,16(sp)
    80002f36:	64a2                	ld	s1,8(sp)
    80002f38:	6902                	ld	s2,0(sp)
    80002f3a:	6105                	addi	sp,sp,32
    80002f3c:	8082                	ret
    panic("usertrap: not from user mode");
    80002f3e:	00005517          	auipc	a0,0x5
    80002f42:	48250513          	addi	a0,a0,1154 # 800083c0 <states.1792+0x58>
    80002f46:	ffffd097          	auipc	ra,0xffffd
    80002f4a:	5f8080e7          	jalr	1528(ra) # 8000053e <panic>
      exit(-1);
    80002f4e:	557d                	li	a0,-1
    80002f50:	00000097          	auipc	ra,0x0
    80002f54:	9a8080e7          	jalr	-1624(ra) # 800028f8 <exit>
    80002f58:	bf4d                	j	80002f0a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002f5a:	00000097          	auipc	ra,0x0
    80002f5e:	ecc080e7          	jalr	-308(ra) # 80002e26 <devintr>
    80002f62:	892a                	mv	s2,a0
    80002f64:	c501                	beqz	a0,80002f6c <usertrap+0xa4>
  if(p->killed)
    80002f66:	549c                	lw	a5,40(s1)
    80002f68:	c3a1                	beqz	a5,80002fa8 <usertrap+0xe0>
    80002f6a:	a815                	j	80002f9e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f6c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f70:	5890                	lw	a2,48(s1)
    80002f72:	00005517          	auipc	a0,0x5
    80002f76:	46e50513          	addi	a0,a0,1134 # 800083e0 <states.1792+0x78>
    80002f7a:	ffffd097          	auipc	ra,0xffffd
    80002f7e:	60e080e7          	jalr	1550(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f82:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f86:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f8a:	00005517          	auipc	a0,0x5
    80002f8e:	48650513          	addi	a0,a0,1158 # 80008410 <states.1792+0xa8>
    80002f92:	ffffd097          	auipc	ra,0xffffd
    80002f96:	5f6080e7          	jalr	1526(ra) # 80000588 <printf>
    p->killed = 1;
    80002f9a:	4785                	li	a5,1
    80002f9c:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002f9e:	557d                	li	a0,-1
    80002fa0:	00000097          	auipc	ra,0x0
    80002fa4:	958080e7          	jalr	-1704(ra) # 800028f8 <exit>
  if(which_dev == 2)
    80002fa8:	4789                	li	a5,2
    80002faa:	f8f910e3          	bne	s2,a5,80002f2a <usertrap+0x62>
    yield();
    80002fae:	fffff097          	auipc	ra,0xfffff
    80002fb2:	606080e7          	jalr	1542(ra) # 800025b4 <yield>
    80002fb6:	bf95                	j	80002f2a <usertrap+0x62>
  int which_dev = 0;
    80002fb8:	4901                	li	s2,0
    80002fba:	b7d5                	j	80002f9e <usertrap+0xd6>

0000000080002fbc <kerneltrap>:
{
    80002fbc:	7179                	addi	sp,sp,-48
    80002fbe:	f406                	sd	ra,40(sp)
    80002fc0:	f022                	sd	s0,32(sp)
    80002fc2:	ec26                	sd	s1,24(sp)
    80002fc4:	e84a                	sd	s2,16(sp)
    80002fc6:	e44e                	sd	s3,8(sp)
    80002fc8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fca:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fce:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fd2:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002fd6:	1004f793          	andi	a5,s1,256
    80002fda:	cb85                	beqz	a5,8000300a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fdc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002fe0:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002fe2:	ef85                	bnez	a5,8000301a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002fe4:	00000097          	auipc	ra,0x0
    80002fe8:	e42080e7          	jalr	-446(ra) # 80002e26 <devintr>
    80002fec:	cd1d                	beqz	a0,8000302a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002fee:	4789                	li	a5,2
    80002ff0:	06f50a63          	beq	a0,a5,80003064 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ff4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ff8:	10049073          	csrw	sstatus,s1
}
    80002ffc:	70a2                	ld	ra,40(sp)
    80002ffe:	7402                	ld	s0,32(sp)
    80003000:	64e2                	ld	s1,24(sp)
    80003002:	6942                	ld	s2,16(sp)
    80003004:	69a2                	ld	s3,8(sp)
    80003006:	6145                	addi	sp,sp,48
    80003008:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000300a:	00005517          	auipc	a0,0x5
    8000300e:	42650513          	addi	a0,a0,1062 # 80008430 <states.1792+0xc8>
    80003012:	ffffd097          	auipc	ra,0xffffd
    80003016:	52c080e7          	jalr	1324(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    8000301a:	00005517          	auipc	a0,0x5
    8000301e:	43e50513          	addi	a0,a0,1086 # 80008458 <states.1792+0xf0>
    80003022:	ffffd097          	auipc	ra,0xffffd
    80003026:	51c080e7          	jalr	1308(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    8000302a:	85ce                	mv	a1,s3
    8000302c:	00005517          	auipc	a0,0x5
    80003030:	44c50513          	addi	a0,a0,1100 # 80008478 <states.1792+0x110>
    80003034:	ffffd097          	auipc	ra,0xffffd
    80003038:	554080e7          	jalr	1364(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000303c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003040:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003044:	00005517          	auipc	a0,0x5
    80003048:	44450513          	addi	a0,a0,1092 # 80008488 <states.1792+0x120>
    8000304c:	ffffd097          	auipc	ra,0xffffd
    80003050:	53c080e7          	jalr	1340(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003054:	00005517          	auipc	a0,0x5
    80003058:	44c50513          	addi	a0,a0,1100 # 800084a0 <states.1792+0x138>
    8000305c:	ffffd097          	auipc	ra,0xffffd
    80003060:	4e2080e7          	jalr	1250(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003064:	fffff097          	auipc	ra,0xfffff
    80003068:	d9c080e7          	jalr	-612(ra) # 80001e00 <myproc>
    8000306c:	d541                	beqz	a0,80002ff4 <kerneltrap+0x38>
    8000306e:	fffff097          	auipc	ra,0xfffff
    80003072:	d92080e7          	jalr	-622(ra) # 80001e00 <myproc>
    80003076:	4d18                	lw	a4,24(a0)
    80003078:	4791                	li	a5,4
    8000307a:	f6f71de3          	bne	a4,a5,80002ff4 <kerneltrap+0x38>
    yield();
    8000307e:	fffff097          	auipc	ra,0xfffff
    80003082:	536080e7          	jalr	1334(ra) # 800025b4 <yield>
    80003086:	b7bd                	j	80002ff4 <kerneltrap+0x38>

0000000080003088 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003088:	1101                	addi	sp,sp,-32
    8000308a:	ec06                	sd	ra,24(sp)
    8000308c:	e822                	sd	s0,16(sp)
    8000308e:	e426                	sd	s1,8(sp)
    80003090:	1000                	addi	s0,sp,32
    80003092:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003094:	fffff097          	auipc	ra,0xfffff
    80003098:	d6c080e7          	jalr	-660(ra) # 80001e00 <myproc>
  switch (n) {
    8000309c:	4795                	li	a5,5
    8000309e:	0497e163          	bltu	a5,s1,800030e0 <argraw+0x58>
    800030a2:	048a                	slli	s1,s1,0x2
    800030a4:	00005717          	auipc	a4,0x5
    800030a8:	43470713          	addi	a4,a4,1076 # 800084d8 <states.1792+0x170>
    800030ac:	94ba                	add	s1,s1,a4
    800030ae:	409c                	lw	a5,0(s1)
    800030b0:	97ba                	add	a5,a5,a4
    800030b2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800030b4:	6d3c                	ld	a5,88(a0)
    800030b6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800030b8:	60e2                	ld	ra,24(sp)
    800030ba:	6442                	ld	s0,16(sp)
    800030bc:	64a2                	ld	s1,8(sp)
    800030be:	6105                	addi	sp,sp,32
    800030c0:	8082                	ret
    return p->trapframe->a1;
    800030c2:	6d3c                	ld	a5,88(a0)
    800030c4:	7fa8                	ld	a0,120(a5)
    800030c6:	bfcd                	j	800030b8 <argraw+0x30>
    return p->trapframe->a2;
    800030c8:	6d3c                	ld	a5,88(a0)
    800030ca:	63c8                	ld	a0,128(a5)
    800030cc:	b7f5                	j	800030b8 <argraw+0x30>
    return p->trapframe->a3;
    800030ce:	6d3c                	ld	a5,88(a0)
    800030d0:	67c8                	ld	a0,136(a5)
    800030d2:	b7dd                	j	800030b8 <argraw+0x30>
    return p->trapframe->a4;
    800030d4:	6d3c                	ld	a5,88(a0)
    800030d6:	6bc8                	ld	a0,144(a5)
    800030d8:	b7c5                	j	800030b8 <argraw+0x30>
    return p->trapframe->a5;
    800030da:	6d3c                	ld	a5,88(a0)
    800030dc:	6fc8                	ld	a0,152(a5)
    800030de:	bfe9                	j	800030b8 <argraw+0x30>
  panic("argraw");
    800030e0:	00005517          	auipc	a0,0x5
    800030e4:	3d050513          	addi	a0,a0,976 # 800084b0 <states.1792+0x148>
    800030e8:	ffffd097          	auipc	ra,0xffffd
    800030ec:	456080e7          	jalr	1110(ra) # 8000053e <panic>

00000000800030f0 <fetchaddr>:
{
    800030f0:	1101                	addi	sp,sp,-32
    800030f2:	ec06                	sd	ra,24(sp)
    800030f4:	e822                	sd	s0,16(sp)
    800030f6:	e426                	sd	s1,8(sp)
    800030f8:	e04a                	sd	s2,0(sp)
    800030fa:	1000                	addi	s0,sp,32
    800030fc:	84aa                	mv	s1,a0
    800030fe:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003100:	fffff097          	auipc	ra,0xfffff
    80003104:	d00080e7          	jalr	-768(ra) # 80001e00 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003108:	653c                	ld	a5,72(a0)
    8000310a:	02f4f863          	bgeu	s1,a5,8000313a <fetchaddr+0x4a>
    8000310e:	00848713          	addi	a4,s1,8
    80003112:	02e7e663          	bltu	a5,a4,8000313e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003116:	46a1                	li	a3,8
    80003118:	8626                	mv	a2,s1
    8000311a:	85ca                	mv	a1,s2
    8000311c:	6928                	ld	a0,80(a0)
    8000311e:	ffffe097          	auipc	ra,0xffffe
    80003122:	5e0080e7          	jalr	1504(ra) # 800016fe <copyin>
    80003126:	00a03533          	snez	a0,a0
    8000312a:	40a00533          	neg	a0,a0
}
    8000312e:	60e2                	ld	ra,24(sp)
    80003130:	6442                	ld	s0,16(sp)
    80003132:	64a2                	ld	s1,8(sp)
    80003134:	6902                	ld	s2,0(sp)
    80003136:	6105                	addi	sp,sp,32
    80003138:	8082                	ret
    return -1;
    8000313a:	557d                	li	a0,-1
    8000313c:	bfcd                	j	8000312e <fetchaddr+0x3e>
    8000313e:	557d                	li	a0,-1
    80003140:	b7fd                	j	8000312e <fetchaddr+0x3e>

0000000080003142 <fetchstr>:
{
    80003142:	7179                	addi	sp,sp,-48
    80003144:	f406                	sd	ra,40(sp)
    80003146:	f022                	sd	s0,32(sp)
    80003148:	ec26                	sd	s1,24(sp)
    8000314a:	e84a                	sd	s2,16(sp)
    8000314c:	e44e                	sd	s3,8(sp)
    8000314e:	1800                	addi	s0,sp,48
    80003150:	892a                	mv	s2,a0
    80003152:	84ae                	mv	s1,a1
    80003154:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003156:	fffff097          	auipc	ra,0xfffff
    8000315a:	caa080e7          	jalr	-854(ra) # 80001e00 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000315e:	86ce                	mv	a3,s3
    80003160:	864a                	mv	a2,s2
    80003162:	85a6                	mv	a1,s1
    80003164:	6928                	ld	a0,80(a0)
    80003166:	ffffe097          	auipc	ra,0xffffe
    8000316a:	624080e7          	jalr	1572(ra) # 8000178a <copyinstr>
  if(err < 0)
    8000316e:	00054763          	bltz	a0,8000317c <fetchstr+0x3a>
  return strlen(buf);
    80003172:	8526                	mv	a0,s1
    80003174:	ffffe097          	auipc	ra,0xffffe
    80003178:	cf0080e7          	jalr	-784(ra) # 80000e64 <strlen>
}
    8000317c:	70a2                	ld	ra,40(sp)
    8000317e:	7402                	ld	s0,32(sp)
    80003180:	64e2                	ld	s1,24(sp)
    80003182:	6942                	ld	s2,16(sp)
    80003184:	69a2                	ld	s3,8(sp)
    80003186:	6145                	addi	sp,sp,48
    80003188:	8082                	ret

000000008000318a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000318a:	1101                	addi	sp,sp,-32
    8000318c:	ec06                	sd	ra,24(sp)
    8000318e:	e822                	sd	s0,16(sp)
    80003190:	e426                	sd	s1,8(sp)
    80003192:	1000                	addi	s0,sp,32
    80003194:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003196:	00000097          	auipc	ra,0x0
    8000319a:	ef2080e7          	jalr	-270(ra) # 80003088 <argraw>
    8000319e:	c088                	sw	a0,0(s1)
  return 0;
}
    800031a0:	4501                	li	a0,0
    800031a2:	60e2                	ld	ra,24(sp)
    800031a4:	6442                	ld	s0,16(sp)
    800031a6:	64a2                	ld	s1,8(sp)
    800031a8:	6105                	addi	sp,sp,32
    800031aa:	8082                	ret

00000000800031ac <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800031ac:	1101                	addi	sp,sp,-32
    800031ae:	ec06                	sd	ra,24(sp)
    800031b0:	e822                	sd	s0,16(sp)
    800031b2:	e426                	sd	s1,8(sp)
    800031b4:	1000                	addi	s0,sp,32
    800031b6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031b8:	00000097          	auipc	ra,0x0
    800031bc:	ed0080e7          	jalr	-304(ra) # 80003088 <argraw>
    800031c0:	e088                	sd	a0,0(s1)
  return 0;
}
    800031c2:	4501                	li	a0,0
    800031c4:	60e2                	ld	ra,24(sp)
    800031c6:	6442                	ld	s0,16(sp)
    800031c8:	64a2                	ld	s1,8(sp)
    800031ca:	6105                	addi	sp,sp,32
    800031cc:	8082                	ret

00000000800031ce <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800031ce:	1101                	addi	sp,sp,-32
    800031d0:	ec06                	sd	ra,24(sp)
    800031d2:	e822                	sd	s0,16(sp)
    800031d4:	e426                	sd	s1,8(sp)
    800031d6:	e04a                	sd	s2,0(sp)
    800031d8:	1000                	addi	s0,sp,32
    800031da:	84ae                	mv	s1,a1
    800031dc:	8932                	mv	s2,a2
  *ip = argraw(n);
    800031de:	00000097          	auipc	ra,0x0
    800031e2:	eaa080e7          	jalr	-342(ra) # 80003088 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800031e6:	864a                	mv	a2,s2
    800031e8:	85a6                	mv	a1,s1
    800031ea:	00000097          	auipc	ra,0x0
    800031ee:	f58080e7          	jalr	-168(ra) # 80003142 <fetchstr>
}
    800031f2:	60e2                	ld	ra,24(sp)
    800031f4:	6442                	ld	s0,16(sp)
    800031f6:	64a2                	ld	s1,8(sp)
    800031f8:	6902                	ld	s2,0(sp)
    800031fa:	6105                	addi	sp,sp,32
    800031fc:	8082                	ret

00000000800031fe <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    800031fe:	1101                	addi	sp,sp,-32
    80003200:	ec06                	sd	ra,24(sp)
    80003202:	e822                	sd	s0,16(sp)
    80003204:	e426                	sd	s1,8(sp)
    80003206:	e04a                	sd	s2,0(sp)
    80003208:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000320a:	fffff097          	auipc	ra,0xfffff
    8000320e:	bf6080e7          	jalr	-1034(ra) # 80001e00 <myproc>
    80003212:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003214:	05853903          	ld	s2,88(a0)
    80003218:	0a893783          	ld	a5,168(s2)
    8000321c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003220:	37fd                	addiw	a5,a5,-1
    80003222:	4751                	li	a4,20
    80003224:	00f76f63          	bltu	a4,a5,80003242 <syscall+0x44>
    80003228:	00369713          	slli	a4,a3,0x3
    8000322c:	00005797          	auipc	a5,0x5
    80003230:	2c478793          	addi	a5,a5,708 # 800084f0 <syscalls>
    80003234:	97ba                	add	a5,a5,a4
    80003236:	639c                	ld	a5,0(a5)
    80003238:	c789                	beqz	a5,80003242 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000323a:	9782                	jalr	a5
    8000323c:	06a93823          	sd	a0,112(s2)
    80003240:	a839                	j	8000325e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003242:	15848613          	addi	a2,s1,344
    80003246:	588c                	lw	a1,48(s1)
    80003248:	00005517          	auipc	a0,0x5
    8000324c:	27050513          	addi	a0,a0,624 # 800084b8 <states.1792+0x150>
    80003250:	ffffd097          	auipc	ra,0xffffd
    80003254:	338080e7          	jalr	824(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003258:	6cbc                	ld	a5,88(s1)
    8000325a:	577d                	li	a4,-1
    8000325c:	fbb8                	sd	a4,112(a5)
  }
}
    8000325e:	60e2                	ld	ra,24(sp)
    80003260:	6442                	ld	s0,16(sp)
    80003262:	64a2                	ld	s1,8(sp)
    80003264:	6902                	ld	s2,0(sp)
    80003266:	6105                	addi	sp,sp,32
    80003268:	8082                	ret

000000008000326a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000326a:	1101                	addi	sp,sp,-32
    8000326c:	ec06                	sd	ra,24(sp)
    8000326e:	e822                	sd	s0,16(sp)
    80003270:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003272:	fec40593          	addi	a1,s0,-20
    80003276:	4501                	li	a0,0
    80003278:	00000097          	auipc	ra,0x0
    8000327c:	f12080e7          	jalr	-238(ra) # 8000318a <argint>
    return -1;
    80003280:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003282:	00054963          	bltz	a0,80003294 <sys_exit+0x2a>
  exit(n);
    80003286:	fec42503          	lw	a0,-20(s0)
    8000328a:	fffff097          	auipc	ra,0xfffff
    8000328e:	66e080e7          	jalr	1646(ra) # 800028f8 <exit>
  return 0;  // not reached
    80003292:	4781                	li	a5,0
}
    80003294:	853e                	mv	a0,a5
    80003296:	60e2                	ld	ra,24(sp)
    80003298:	6442                	ld	s0,16(sp)
    8000329a:	6105                	addi	sp,sp,32
    8000329c:	8082                	ret

000000008000329e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000329e:	1141                	addi	sp,sp,-16
    800032a0:	e406                	sd	ra,8(sp)
    800032a2:	e022                	sd	s0,0(sp)
    800032a4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800032a6:	fffff097          	auipc	ra,0xfffff
    800032aa:	b5a080e7          	jalr	-1190(ra) # 80001e00 <myproc>
}
    800032ae:	5908                	lw	a0,48(a0)
    800032b0:	60a2                	ld	ra,8(sp)
    800032b2:	6402                	ld	s0,0(sp)
    800032b4:	0141                	addi	sp,sp,16
    800032b6:	8082                	ret

00000000800032b8 <sys_fork>:

uint64
sys_fork(void)
{
    800032b8:	1141                	addi	sp,sp,-16
    800032ba:	e406                	sd	ra,8(sp)
    800032bc:	e022                	sd	s0,0(sp)
    800032be:	0800                	addi	s0,sp,16
  return fork();
    800032c0:	fffff097          	auipc	ra,0xfffff
    800032c4:	fd4080e7          	jalr	-44(ra) # 80002294 <fork>
}
    800032c8:	60a2                	ld	ra,8(sp)
    800032ca:	6402                	ld	s0,0(sp)
    800032cc:	0141                	addi	sp,sp,16
    800032ce:	8082                	ret

00000000800032d0 <sys_wait>:

uint64
sys_wait(void)
{
    800032d0:	1101                	addi	sp,sp,-32
    800032d2:	ec06                	sd	ra,24(sp)
    800032d4:	e822                	sd	s0,16(sp)
    800032d6:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800032d8:	fe840593          	addi	a1,s0,-24
    800032dc:	4501                	li	a0,0
    800032de:	00000097          	auipc	ra,0x0
    800032e2:	ece080e7          	jalr	-306(ra) # 800031ac <argaddr>
    800032e6:	87aa                	mv	a5,a0
    return -1;
    800032e8:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800032ea:	0007c863          	bltz	a5,800032fa <sys_wait+0x2a>
  return wait(p);
    800032ee:	fe843503          	ld	a0,-24(s0)
    800032f2:	fffff097          	auipc	ra,0xfffff
    800032f6:	398080e7          	jalr	920(ra) # 8000268a <wait>
}
    800032fa:	60e2                	ld	ra,24(sp)
    800032fc:	6442                	ld	s0,16(sp)
    800032fe:	6105                	addi	sp,sp,32
    80003300:	8082                	ret

0000000080003302 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003302:	7179                	addi	sp,sp,-48
    80003304:	f406                	sd	ra,40(sp)
    80003306:	f022                	sd	s0,32(sp)
    80003308:	ec26                	sd	s1,24(sp)
    8000330a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000330c:	fdc40593          	addi	a1,s0,-36
    80003310:	4501                	li	a0,0
    80003312:	00000097          	auipc	ra,0x0
    80003316:	e78080e7          	jalr	-392(ra) # 8000318a <argint>
    8000331a:	87aa                	mv	a5,a0
    return -1;
    8000331c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000331e:	0207c063          	bltz	a5,8000333e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003322:	fffff097          	auipc	ra,0xfffff
    80003326:	ade080e7          	jalr	-1314(ra) # 80001e00 <myproc>
    8000332a:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    8000332c:	fdc42503          	lw	a0,-36(s0)
    80003330:	fffff097          	auipc	ra,0xfffff
    80003334:	ef0080e7          	jalr	-272(ra) # 80002220 <growproc>
    80003338:	00054863          	bltz	a0,80003348 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000333c:	8526                	mv	a0,s1
}
    8000333e:	70a2                	ld	ra,40(sp)
    80003340:	7402                	ld	s0,32(sp)
    80003342:	64e2                	ld	s1,24(sp)
    80003344:	6145                	addi	sp,sp,48
    80003346:	8082                	ret
    return -1;
    80003348:	557d                	li	a0,-1
    8000334a:	bfd5                	j	8000333e <sys_sbrk+0x3c>

000000008000334c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000334c:	7139                	addi	sp,sp,-64
    8000334e:	fc06                	sd	ra,56(sp)
    80003350:	f822                	sd	s0,48(sp)
    80003352:	f426                	sd	s1,40(sp)
    80003354:	f04a                	sd	s2,32(sp)
    80003356:	ec4e                	sd	s3,24(sp)
    80003358:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000335a:	fcc40593          	addi	a1,s0,-52
    8000335e:	4501                	li	a0,0
    80003360:	00000097          	auipc	ra,0x0
    80003364:	e2a080e7          	jalr	-470(ra) # 8000318a <argint>
    return -1;
    80003368:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000336a:	06054563          	bltz	a0,800033d4 <sys_sleep+0x88>
  acquire(&tickslock);
    8000336e:	00015517          	auipc	a0,0x15
    80003372:	8a250513          	addi	a0,a0,-1886 # 80017c10 <tickslock>
    80003376:	ffffe097          	auipc	ra,0xffffe
    8000337a:	86e080e7          	jalr	-1938(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000337e:	00006917          	auipc	s2,0x6
    80003382:	cb292903          	lw	s2,-846(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003386:	fcc42783          	lw	a5,-52(s0)
    8000338a:	cf85                	beqz	a5,800033c2 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000338c:	00015997          	auipc	s3,0x15
    80003390:	88498993          	addi	s3,s3,-1916 # 80017c10 <tickslock>
    80003394:	00006497          	auipc	s1,0x6
    80003398:	c9c48493          	addi	s1,s1,-868 # 80009030 <ticks>
    if(myproc()->killed){
    8000339c:	fffff097          	auipc	ra,0xfffff
    800033a0:	a64080e7          	jalr	-1436(ra) # 80001e00 <myproc>
    800033a4:	551c                	lw	a5,40(a0)
    800033a6:	ef9d                	bnez	a5,800033e4 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800033a8:	85ce                	mv	a1,s3
    800033aa:	8526                	mv	a0,s1
    800033ac:	fffff097          	auipc	ra,0xfffff
    800033b0:	268080e7          	jalr	616(ra) # 80002614 <sleep>
  while(ticks - ticks0 < n){
    800033b4:	409c                	lw	a5,0(s1)
    800033b6:	412787bb          	subw	a5,a5,s2
    800033ba:	fcc42703          	lw	a4,-52(s0)
    800033be:	fce7efe3          	bltu	a5,a4,8000339c <sys_sleep+0x50>
  }
  release(&tickslock);
    800033c2:	00015517          	auipc	a0,0x15
    800033c6:	84e50513          	addi	a0,a0,-1970 # 80017c10 <tickslock>
    800033ca:	ffffe097          	auipc	ra,0xffffe
    800033ce:	8ce080e7          	jalr	-1842(ra) # 80000c98 <release>
  return 0;
    800033d2:	4781                	li	a5,0
}
    800033d4:	853e                	mv	a0,a5
    800033d6:	70e2                	ld	ra,56(sp)
    800033d8:	7442                	ld	s0,48(sp)
    800033da:	74a2                	ld	s1,40(sp)
    800033dc:	7902                	ld	s2,32(sp)
    800033de:	69e2                	ld	s3,24(sp)
    800033e0:	6121                	addi	sp,sp,64
    800033e2:	8082                	ret
      release(&tickslock);
    800033e4:	00015517          	auipc	a0,0x15
    800033e8:	82c50513          	addi	a0,a0,-2004 # 80017c10 <tickslock>
    800033ec:	ffffe097          	auipc	ra,0xffffe
    800033f0:	8ac080e7          	jalr	-1876(ra) # 80000c98 <release>
      return -1;
    800033f4:	57fd                	li	a5,-1
    800033f6:	bff9                	j	800033d4 <sys_sleep+0x88>

00000000800033f8 <sys_kill>:

uint64
sys_kill(void)
{
    800033f8:	1101                	addi	sp,sp,-32
    800033fa:	ec06                	sd	ra,24(sp)
    800033fc:	e822                	sd	s0,16(sp)
    800033fe:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003400:	fec40593          	addi	a1,s0,-20
    80003404:	4501                	li	a0,0
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	d84080e7          	jalr	-636(ra) # 8000318a <argint>
    8000340e:	87aa                	mv	a5,a0
    return -1;
    80003410:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003412:	0007c863          	bltz	a5,80003422 <sys_kill+0x2a>
  return kill(pid);
    80003416:	fec42503          	lw	a0,-20(s0)
    8000341a:	fffff097          	auipc	ra,0xfffff
    8000341e:	5c6080e7          	jalr	1478(ra) # 800029e0 <kill>
}
    80003422:	60e2                	ld	ra,24(sp)
    80003424:	6442                	ld	s0,16(sp)
    80003426:	6105                	addi	sp,sp,32
    80003428:	8082                	ret

000000008000342a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000342a:	1101                	addi	sp,sp,-32
    8000342c:	ec06                	sd	ra,24(sp)
    8000342e:	e822                	sd	s0,16(sp)
    80003430:	e426                	sd	s1,8(sp)
    80003432:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003434:	00014517          	auipc	a0,0x14
    80003438:	7dc50513          	addi	a0,a0,2012 # 80017c10 <tickslock>
    8000343c:	ffffd097          	auipc	ra,0xffffd
    80003440:	7a8080e7          	jalr	1960(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003444:	00006497          	auipc	s1,0x6
    80003448:	bec4a483          	lw	s1,-1044(s1) # 80009030 <ticks>
  release(&tickslock);
    8000344c:	00014517          	auipc	a0,0x14
    80003450:	7c450513          	addi	a0,a0,1988 # 80017c10 <tickslock>
    80003454:	ffffe097          	auipc	ra,0xffffe
    80003458:	844080e7          	jalr	-1980(ra) # 80000c98 <release>
  return xticks;
}
    8000345c:	02049513          	slli	a0,s1,0x20
    80003460:	9101                	srli	a0,a0,0x20
    80003462:	60e2                	ld	ra,24(sp)
    80003464:	6442                	ld	s0,16(sp)
    80003466:	64a2                	ld	s1,8(sp)
    80003468:	6105                	addi	sp,sp,32
    8000346a:	8082                	ret

000000008000346c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000346c:	7179                	addi	sp,sp,-48
    8000346e:	f406                	sd	ra,40(sp)
    80003470:	f022                	sd	s0,32(sp)
    80003472:	ec26                	sd	s1,24(sp)
    80003474:	e84a                	sd	s2,16(sp)
    80003476:	e44e                	sd	s3,8(sp)
    80003478:	e052                	sd	s4,0(sp)
    8000347a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000347c:	00005597          	auipc	a1,0x5
    80003480:	12458593          	addi	a1,a1,292 # 800085a0 <syscalls+0xb0>
    80003484:	00014517          	auipc	a0,0x14
    80003488:	7a450513          	addi	a0,a0,1956 # 80017c28 <bcache>
    8000348c:	ffffd097          	auipc	ra,0xffffd
    80003490:	6c8080e7          	jalr	1736(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003494:	0001c797          	auipc	a5,0x1c
    80003498:	79478793          	addi	a5,a5,1940 # 8001fc28 <bcache+0x8000>
    8000349c:	0001d717          	auipc	a4,0x1d
    800034a0:	9f470713          	addi	a4,a4,-1548 # 8001fe90 <bcache+0x8268>
    800034a4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034a8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034ac:	00014497          	auipc	s1,0x14
    800034b0:	79448493          	addi	s1,s1,1940 # 80017c40 <bcache+0x18>
    b->next = bcache.head.next;
    800034b4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034b6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034b8:	00005a17          	auipc	s4,0x5
    800034bc:	0f0a0a13          	addi	s4,s4,240 # 800085a8 <syscalls+0xb8>
    b->next = bcache.head.next;
    800034c0:	2b893783          	ld	a5,696(s2)
    800034c4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800034c6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034ca:	85d2                	mv	a1,s4
    800034cc:	01048513          	addi	a0,s1,16
    800034d0:	00001097          	auipc	ra,0x1
    800034d4:	4bc080e7          	jalr	1212(ra) # 8000498c <initsleeplock>
    bcache.head.next->prev = b;
    800034d8:	2b893783          	ld	a5,696(s2)
    800034dc:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034de:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034e2:	45848493          	addi	s1,s1,1112
    800034e6:	fd349de3          	bne	s1,s3,800034c0 <binit+0x54>
  }
}
    800034ea:	70a2                	ld	ra,40(sp)
    800034ec:	7402                	ld	s0,32(sp)
    800034ee:	64e2                	ld	s1,24(sp)
    800034f0:	6942                	ld	s2,16(sp)
    800034f2:	69a2                	ld	s3,8(sp)
    800034f4:	6a02                	ld	s4,0(sp)
    800034f6:	6145                	addi	sp,sp,48
    800034f8:	8082                	ret

00000000800034fa <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800034fa:	7179                	addi	sp,sp,-48
    800034fc:	f406                	sd	ra,40(sp)
    800034fe:	f022                	sd	s0,32(sp)
    80003500:	ec26                	sd	s1,24(sp)
    80003502:	e84a                	sd	s2,16(sp)
    80003504:	e44e                	sd	s3,8(sp)
    80003506:	1800                	addi	s0,sp,48
    80003508:	89aa                	mv	s3,a0
    8000350a:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000350c:	00014517          	auipc	a0,0x14
    80003510:	71c50513          	addi	a0,a0,1820 # 80017c28 <bcache>
    80003514:	ffffd097          	auipc	ra,0xffffd
    80003518:	6d0080e7          	jalr	1744(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000351c:	0001d497          	auipc	s1,0x1d
    80003520:	9c44b483          	ld	s1,-1596(s1) # 8001fee0 <bcache+0x82b8>
    80003524:	0001d797          	auipc	a5,0x1d
    80003528:	96c78793          	addi	a5,a5,-1684 # 8001fe90 <bcache+0x8268>
    8000352c:	02f48f63          	beq	s1,a5,8000356a <bread+0x70>
    80003530:	873e                	mv	a4,a5
    80003532:	a021                	j	8000353a <bread+0x40>
    80003534:	68a4                	ld	s1,80(s1)
    80003536:	02e48a63          	beq	s1,a4,8000356a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000353a:	449c                	lw	a5,8(s1)
    8000353c:	ff379ce3          	bne	a5,s3,80003534 <bread+0x3a>
    80003540:	44dc                	lw	a5,12(s1)
    80003542:	ff2799e3          	bne	a5,s2,80003534 <bread+0x3a>
      b->refcnt++;
    80003546:	40bc                	lw	a5,64(s1)
    80003548:	2785                	addiw	a5,a5,1
    8000354a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000354c:	00014517          	auipc	a0,0x14
    80003550:	6dc50513          	addi	a0,a0,1756 # 80017c28 <bcache>
    80003554:	ffffd097          	auipc	ra,0xffffd
    80003558:	744080e7          	jalr	1860(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000355c:	01048513          	addi	a0,s1,16
    80003560:	00001097          	auipc	ra,0x1
    80003564:	466080e7          	jalr	1126(ra) # 800049c6 <acquiresleep>
      return b;
    80003568:	a8b9                	j	800035c6 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000356a:	0001d497          	auipc	s1,0x1d
    8000356e:	96e4b483          	ld	s1,-1682(s1) # 8001fed8 <bcache+0x82b0>
    80003572:	0001d797          	auipc	a5,0x1d
    80003576:	91e78793          	addi	a5,a5,-1762 # 8001fe90 <bcache+0x8268>
    8000357a:	00f48863          	beq	s1,a5,8000358a <bread+0x90>
    8000357e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003580:	40bc                	lw	a5,64(s1)
    80003582:	cf81                	beqz	a5,8000359a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003584:	64a4                	ld	s1,72(s1)
    80003586:	fee49de3          	bne	s1,a4,80003580 <bread+0x86>
  panic("bget: no buffers");
    8000358a:	00005517          	auipc	a0,0x5
    8000358e:	02650513          	addi	a0,a0,38 # 800085b0 <syscalls+0xc0>
    80003592:	ffffd097          	auipc	ra,0xffffd
    80003596:	fac080e7          	jalr	-84(ra) # 8000053e <panic>
      b->dev = dev;
    8000359a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000359e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800035a2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035a6:	4785                	li	a5,1
    800035a8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035aa:	00014517          	auipc	a0,0x14
    800035ae:	67e50513          	addi	a0,a0,1662 # 80017c28 <bcache>
    800035b2:	ffffd097          	auipc	ra,0xffffd
    800035b6:	6e6080e7          	jalr	1766(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800035ba:	01048513          	addi	a0,s1,16
    800035be:	00001097          	auipc	ra,0x1
    800035c2:	408080e7          	jalr	1032(ra) # 800049c6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800035c6:	409c                	lw	a5,0(s1)
    800035c8:	cb89                	beqz	a5,800035da <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035ca:	8526                	mv	a0,s1
    800035cc:	70a2                	ld	ra,40(sp)
    800035ce:	7402                	ld	s0,32(sp)
    800035d0:	64e2                	ld	s1,24(sp)
    800035d2:	6942                	ld	s2,16(sp)
    800035d4:	69a2                	ld	s3,8(sp)
    800035d6:	6145                	addi	sp,sp,48
    800035d8:	8082                	ret
    virtio_disk_rw(b, 0);
    800035da:	4581                	li	a1,0
    800035dc:	8526                	mv	a0,s1
    800035de:	00003097          	auipc	ra,0x3
    800035e2:	f08080e7          	jalr	-248(ra) # 800064e6 <virtio_disk_rw>
    b->valid = 1;
    800035e6:	4785                	li	a5,1
    800035e8:	c09c                	sw	a5,0(s1)
  return b;
    800035ea:	b7c5                	j	800035ca <bread+0xd0>

00000000800035ec <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800035ec:	1101                	addi	sp,sp,-32
    800035ee:	ec06                	sd	ra,24(sp)
    800035f0:	e822                	sd	s0,16(sp)
    800035f2:	e426                	sd	s1,8(sp)
    800035f4:	1000                	addi	s0,sp,32
    800035f6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035f8:	0541                	addi	a0,a0,16
    800035fa:	00001097          	auipc	ra,0x1
    800035fe:	466080e7          	jalr	1126(ra) # 80004a60 <holdingsleep>
    80003602:	cd01                	beqz	a0,8000361a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003604:	4585                	li	a1,1
    80003606:	8526                	mv	a0,s1
    80003608:	00003097          	auipc	ra,0x3
    8000360c:	ede080e7          	jalr	-290(ra) # 800064e6 <virtio_disk_rw>
}
    80003610:	60e2                	ld	ra,24(sp)
    80003612:	6442                	ld	s0,16(sp)
    80003614:	64a2                	ld	s1,8(sp)
    80003616:	6105                	addi	sp,sp,32
    80003618:	8082                	ret
    panic("bwrite");
    8000361a:	00005517          	auipc	a0,0x5
    8000361e:	fae50513          	addi	a0,a0,-82 # 800085c8 <syscalls+0xd8>
    80003622:	ffffd097          	auipc	ra,0xffffd
    80003626:	f1c080e7          	jalr	-228(ra) # 8000053e <panic>

000000008000362a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000362a:	1101                	addi	sp,sp,-32
    8000362c:	ec06                	sd	ra,24(sp)
    8000362e:	e822                	sd	s0,16(sp)
    80003630:	e426                	sd	s1,8(sp)
    80003632:	e04a                	sd	s2,0(sp)
    80003634:	1000                	addi	s0,sp,32
    80003636:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003638:	01050913          	addi	s2,a0,16
    8000363c:	854a                	mv	a0,s2
    8000363e:	00001097          	auipc	ra,0x1
    80003642:	422080e7          	jalr	1058(ra) # 80004a60 <holdingsleep>
    80003646:	c92d                	beqz	a0,800036b8 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003648:	854a                	mv	a0,s2
    8000364a:	00001097          	auipc	ra,0x1
    8000364e:	3d2080e7          	jalr	978(ra) # 80004a1c <releasesleep>

  acquire(&bcache.lock);
    80003652:	00014517          	auipc	a0,0x14
    80003656:	5d650513          	addi	a0,a0,1494 # 80017c28 <bcache>
    8000365a:	ffffd097          	auipc	ra,0xffffd
    8000365e:	58a080e7          	jalr	1418(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003662:	40bc                	lw	a5,64(s1)
    80003664:	37fd                	addiw	a5,a5,-1
    80003666:	0007871b          	sext.w	a4,a5
    8000366a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000366c:	eb05                	bnez	a4,8000369c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000366e:	68bc                	ld	a5,80(s1)
    80003670:	64b8                	ld	a4,72(s1)
    80003672:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003674:	64bc                	ld	a5,72(s1)
    80003676:	68b8                	ld	a4,80(s1)
    80003678:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000367a:	0001c797          	auipc	a5,0x1c
    8000367e:	5ae78793          	addi	a5,a5,1454 # 8001fc28 <bcache+0x8000>
    80003682:	2b87b703          	ld	a4,696(a5)
    80003686:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003688:	0001d717          	auipc	a4,0x1d
    8000368c:	80870713          	addi	a4,a4,-2040 # 8001fe90 <bcache+0x8268>
    80003690:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003692:	2b87b703          	ld	a4,696(a5)
    80003696:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003698:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000369c:	00014517          	auipc	a0,0x14
    800036a0:	58c50513          	addi	a0,a0,1420 # 80017c28 <bcache>
    800036a4:	ffffd097          	auipc	ra,0xffffd
    800036a8:	5f4080e7          	jalr	1524(ra) # 80000c98 <release>
}
    800036ac:	60e2                	ld	ra,24(sp)
    800036ae:	6442                	ld	s0,16(sp)
    800036b0:	64a2                	ld	s1,8(sp)
    800036b2:	6902                	ld	s2,0(sp)
    800036b4:	6105                	addi	sp,sp,32
    800036b6:	8082                	ret
    panic("brelse");
    800036b8:	00005517          	auipc	a0,0x5
    800036bc:	f1850513          	addi	a0,a0,-232 # 800085d0 <syscalls+0xe0>
    800036c0:	ffffd097          	auipc	ra,0xffffd
    800036c4:	e7e080e7          	jalr	-386(ra) # 8000053e <panic>

00000000800036c8 <bpin>:

void
bpin(struct buf *b) {
    800036c8:	1101                	addi	sp,sp,-32
    800036ca:	ec06                	sd	ra,24(sp)
    800036cc:	e822                	sd	s0,16(sp)
    800036ce:	e426                	sd	s1,8(sp)
    800036d0:	1000                	addi	s0,sp,32
    800036d2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036d4:	00014517          	auipc	a0,0x14
    800036d8:	55450513          	addi	a0,a0,1364 # 80017c28 <bcache>
    800036dc:	ffffd097          	auipc	ra,0xffffd
    800036e0:	508080e7          	jalr	1288(ra) # 80000be4 <acquire>
  b->refcnt++;
    800036e4:	40bc                	lw	a5,64(s1)
    800036e6:	2785                	addiw	a5,a5,1
    800036e8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036ea:	00014517          	auipc	a0,0x14
    800036ee:	53e50513          	addi	a0,a0,1342 # 80017c28 <bcache>
    800036f2:	ffffd097          	auipc	ra,0xffffd
    800036f6:	5a6080e7          	jalr	1446(ra) # 80000c98 <release>
}
    800036fa:	60e2                	ld	ra,24(sp)
    800036fc:	6442                	ld	s0,16(sp)
    800036fe:	64a2                	ld	s1,8(sp)
    80003700:	6105                	addi	sp,sp,32
    80003702:	8082                	ret

0000000080003704 <bunpin>:

void
bunpin(struct buf *b) {
    80003704:	1101                	addi	sp,sp,-32
    80003706:	ec06                	sd	ra,24(sp)
    80003708:	e822                	sd	s0,16(sp)
    8000370a:	e426                	sd	s1,8(sp)
    8000370c:	1000                	addi	s0,sp,32
    8000370e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003710:	00014517          	auipc	a0,0x14
    80003714:	51850513          	addi	a0,a0,1304 # 80017c28 <bcache>
    80003718:	ffffd097          	auipc	ra,0xffffd
    8000371c:	4cc080e7          	jalr	1228(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003720:	40bc                	lw	a5,64(s1)
    80003722:	37fd                	addiw	a5,a5,-1
    80003724:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003726:	00014517          	auipc	a0,0x14
    8000372a:	50250513          	addi	a0,a0,1282 # 80017c28 <bcache>
    8000372e:	ffffd097          	auipc	ra,0xffffd
    80003732:	56a080e7          	jalr	1386(ra) # 80000c98 <release>
}
    80003736:	60e2                	ld	ra,24(sp)
    80003738:	6442                	ld	s0,16(sp)
    8000373a:	64a2                	ld	s1,8(sp)
    8000373c:	6105                	addi	sp,sp,32
    8000373e:	8082                	ret

0000000080003740 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003740:	1101                	addi	sp,sp,-32
    80003742:	ec06                	sd	ra,24(sp)
    80003744:	e822                	sd	s0,16(sp)
    80003746:	e426                	sd	s1,8(sp)
    80003748:	e04a                	sd	s2,0(sp)
    8000374a:	1000                	addi	s0,sp,32
    8000374c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000374e:	00d5d59b          	srliw	a1,a1,0xd
    80003752:	0001d797          	auipc	a5,0x1d
    80003756:	bb27a783          	lw	a5,-1102(a5) # 80020304 <sb+0x1c>
    8000375a:	9dbd                	addw	a1,a1,a5
    8000375c:	00000097          	auipc	ra,0x0
    80003760:	d9e080e7          	jalr	-610(ra) # 800034fa <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003764:	0074f713          	andi	a4,s1,7
    80003768:	4785                	li	a5,1
    8000376a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000376e:	14ce                	slli	s1,s1,0x33
    80003770:	90d9                	srli	s1,s1,0x36
    80003772:	00950733          	add	a4,a0,s1
    80003776:	05874703          	lbu	a4,88(a4)
    8000377a:	00e7f6b3          	and	a3,a5,a4
    8000377e:	c69d                	beqz	a3,800037ac <bfree+0x6c>
    80003780:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003782:	94aa                	add	s1,s1,a0
    80003784:	fff7c793          	not	a5,a5
    80003788:	8ff9                	and	a5,a5,a4
    8000378a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000378e:	00001097          	auipc	ra,0x1
    80003792:	118080e7          	jalr	280(ra) # 800048a6 <log_write>
  brelse(bp);
    80003796:	854a                	mv	a0,s2
    80003798:	00000097          	auipc	ra,0x0
    8000379c:	e92080e7          	jalr	-366(ra) # 8000362a <brelse>
}
    800037a0:	60e2                	ld	ra,24(sp)
    800037a2:	6442                	ld	s0,16(sp)
    800037a4:	64a2                	ld	s1,8(sp)
    800037a6:	6902                	ld	s2,0(sp)
    800037a8:	6105                	addi	sp,sp,32
    800037aa:	8082                	ret
    panic("freeing free block");
    800037ac:	00005517          	auipc	a0,0x5
    800037b0:	e2c50513          	addi	a0,a0,-468 # 800085d8 <syscalls+0xe8>
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	d8a080e7          	jalr	-630(ra) # 8000053e <panic>

00000000800037bc <balloc>:
{
    800037bc:	711d                	addi	sp,sp,-96
    800037be:	ec86                	sd	ra,88(sp)
    800037c0:	e8a2                	sd	s0,80(sp)
    800037c2:	e4a6                	sd	s1,72(sp)
    800037c4:	e0ca                	sd	s2,64(sp)
    800037c6:	fc4e                	sd	s3,56(sp)
    800037c8:	f852                	sd	s4,48(sp)
    800037ca:	f456                	sd	s5,40(sp)
    800037cc:	f05a                	sd	s6,32(sp)
    800037ce:	ec5e                	sd	s7,24(sp)
    800037d0:	e862                	sd	s8,16(sp)
    800037d2:	e466                	sd	s9,8(sp)
    800037d4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037d6:	0001d797          	auipc	a5,0x1d
    800037da:	b167a783          	lw	a5,-1258(a5) # 800202ec <sb+0x4>
    800037de:	cbd1                	beqz	a5,80003872 <balloc+0xb6>
    800037e0:	8baa                	mv	s7,a0
    800037e2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037e4:	0001db17          	auipc	s6,0x1d
    800037e8:	b04b0b13          	addi	s6,s6,-1276 # 800202e8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037ec:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800037ee:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037f0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800037f2:	6c89                	lui	s9,0x2
    800037f4:	a831                	j	80003810 <balloc+0x54>
    brelse(bp);
    800037f6:	854a                	mv	a0,s2
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	e32080e7          	jalr	-462(ra) # 8000362a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003800:	015c87bb          	addw	a5,s9,s5
    80003804:	00078a9b          	sext.w	s5,a5
    80003808:	004b2703          	lw	a4,4(s6)
    8000380c:	06eaf363          	bgeu	s5,a4,80003872 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003810:	41fad79b          	sraiw	a5,s5,0x1f
    80003814:	0137d79b          	srliw	a5,a5,0x13
    80003818:	015787bb          	addw	a5,a5,s5
    8000381c:	40d7d79b          	sraiw	a5,a5,0xd
    80003820:	01cb2583          	lw	a1,28(s6)
    80003824:	9dbd                	addw	a1,a1,a5
    80003826:	855e                	mv	a0,s7
    80003828:	00000097          	auipc	ra,0x0
    8000382c:	cd2080e7          	jalr	-814(ra) # 800034fa <bread>
    80003830:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003832:	004b2503          	lw	a0,4(s6)
    80003836:	000a849b          	sext.w	s1,s5
    8000383a:	8662                	mv	a2,s8
    8000383c:	faa4fde3          	bgeu	s1,a0,800037f6 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003840:	41f6579b          	sraiw	a5,a2,0x1f
    80003844:	01d7d69b          	srliw	a3,a5,0x1d
    80003848:	00c6873b          	addw	a4,a3,a2
    8000384c:	00777793          	andi	a5,a4,7
    80003850:	9f95                	subw	a5,a5,a3
    80003852:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003856:	4037571b          	sraiw	a4,a4,0x3
    8000385a:	00e906b3          	add	a3,s2,a4
    8000385e:	0586c683          	lbu	a3,88(a3)
    80003862:	00d7f5b3          	and	a1,a5,a3
    80003866:	cd91                	beqz	a1,80003882 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003868:	2605                	addiw	a2,a2,1
    8000386a:	2485                	addiw	s1,s1,1
    8000386c:	fd4618e3          	bne	a2,s4,8000383c <balloc+0x80>
    80003870:	b759                	j	800037f6 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003872:	00005517          	auipc	a0,0x5
    80003876:	d7e50513          	addi	a0,a0,-642 # 800085f0 <syscalls+0x100>
    8000387a:	ffffd097          	auipc	ra,0xffffd
    8000387e:	cc4080e7          	jalr	-828(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003882:	974a                	add	a4,a4,s2
    80003884:	8fd5                	or	a5,a5,a3
    80003886:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000388a:	854a                	mv	a0,s2
    8000388c:	00001097          	auipc	ra,0x1
    80003890:	01a080e7          	jalr	26(ra) # 800048a6 <log_write>
        brelse(bp);
    80003894:	854a                	mv	a0,s2
    80003896:	00000097          	auipc	ra,0x0
    8000389a:	d94080e7          	jalr	-620(ra) # 8000362a <brelse>
  bp = bread(dev, bno);
    8000389e:	85a6                	mv	a1,s1
    800038a0:	855e                	mv	a0,s7
    800038a2:	00000097          	auipc	ra,0x0
    800038a6:	c58080e7          	jalr	-936(ra) # 800034fa <bread>
    800038aa:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038ac:	40000613          	li	a2,1024
    800038b0:	4581                	li	a1,0
    800038b2:	05850513          	addi	a0,a0,88
    800038b6:	ffffd097          	auipc	ra,0xffffd
    800038ba:	42a080e7          	jalr	1066(ra) # 80000ce0 <memset>
  log_write(bp);
    800038be:	854a                	mv	a0,s2
    800038c0:	00001097          	auipc	ra,0x1
    800038c4:	fe6080e7          	jalr	-26(ra) # 800048a6 <log_write>
  brelse(bp);
    800038c8:	854a                	mv	a0,s2
    800038ca:	00000097          	auipc	ra,0x0
    800038ce:	d60080e7          	jalr	-672(ra) # 8000362a <brelse>
}
    800038d2:	8526                	mv	a0,s1
    800038d4:	60e6                	ld	ra,88(sp)
    800038d6:	6446                	ld	s0,80(sp)
    800038d8:	64a6                	ld	s1,72(sp)
    800038da:	6906                	ld	s2,64(sp)
    800038dc:	79e2                	ld	s3,56(sp)
    800038de:	7a42                	ld	s4,48(sp)
    800038e0:	7aa2                	ld	s5,40(sp)
    800038e2:	7b02                	ld	s6,32(sp)
    800038e4:	6be2                	ld	s7,24(sp)
    800038e6:	6c42                	ld	s8,16(sp)
    800038e8:	6ca2                	ld	s9,8(sp)
    800038ea:	6125                	addi	sp,sp,96
    800038ec:	8082                	ret

00000000800038ee <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800038ee:	7179                	addi	sp,sp,-48
    800038f0:	f406                	sd	ra,40(sp)
    800038f2:	f022                	sd	s0,32(sp)
    800038f4:	ec26                	sd	s1,24(sp)
    800038f6:	e84a                	sd	s2,16(sp)
    800038f8:	e44e                	sd	s3,8(sp)
    800038fa:	e052                	sd	s4,0(sp)
    800038fc:	1800                	addi	s0,sp,48
    800038fe:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003900:	47ad                	li	a5,11
    80003902:	04b7fe63          	bgeu	a5,a1,8000395e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003906:	ff45849b          	addiw	s1,a1,-12
    8000390a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000390e:	0ff00793          	li	a5,255
    80003912:	0ae7e363          	bltu	a5,a4,800039b8 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003916:	08052583          	lw	a1,128(a0)
    8000391a:	c5ad                	beqz	a1,80003984 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000391c:	00092503          	lw	a0,0(s2)
    80003920:	00000097          	auipc	ra,0x0
    80003924:	bda080e7          	jalr	-1062(ra) # 800034fa <bread>
    80003928:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000392a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000392e:	02049593          	slli	a1,s1,0x20
    80003932:	9181                	srli	a1,a1,0x20
    80003934:	058a                	slli	a1,a1,0x2
    80003936:	00b784b3          	add	s1,a5,a1
    8000393a:	0004a983          	lw	s3,0(s1)
    8000393e:	04098d63          	beqz	s3,80003998 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003942:	8552                	mv	a0,s4
    80003944:	00000097          	auipc	ra,0x0
    80003948:	ce6080e7          	jalr	-794(ra) # 8000362a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000394c:	854e                	mv	a0,s3
    8000394e:	70a2                	ld	ra,40(sp)
    80003950:	7402                	ld	s0,32(sp)
    80003952:	64e2                	ld	s1,24(sp)
    80003954:	6942                	ld	s2,16(sp)
    80003956:	69a2                	ld	s3,8(sp)
    80003958:	6a02                	ld	s4,0(sp)
    8000395a:	6145                	addi	sp,sp,48
    8000395c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000395e:	02059493          	slli	s1,a1,0x20
    80003962:	9081                	srli	s1,s1,0x20
    80003964:	048a                	slli	s1,s1,0x2
    80003966:	94aa                	add	s1,s1,a0
    80003968:	0504a983          	lw	s3,80(s1)
    8000396c:	fe0990e3          	bnez	s3,8000394c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003970:	4108                	lw	a0,0(a0)
    80003972:	00000097          	auipc	ra,0x0
    80003976:	e4a080e7          	jalr	-438(ra) # 800037bc <balloc>
    8000397a:	0005099b          	sext.w	s3,a0
    8000397e:	0534a823          	sw	s3,80(s1)
    80003982:	b7e9                	j	8000394c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003984:	4108                	lw	a0,0(a0)
    80003986:	00000097          	auipc	ra,0x0
    8000398a:	e36080e7          	jalr	-458(ra) # 800037bc <balloc>
    8000398e:	0005059b          	sext.w	a1,a0
    80003992:	08b92023          	sw	a1,128(s2)
    80003996:	b759                	j	8000391c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003998:	00092503          	lw	a0,0(s2)
    8000399c:	00000097          	auipc	ra,0x0
    800039a0:	e20080e7          	jalr	-480(ra) # 800037bc <balloc>
    800039a4:	0005099b          	sext.w	s3,a0
    800039a8:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800039ac:	8552                	mv	a0,s4
    800039ae:	00001097          	auipc	ra,0x1
    800039b2:	ef8080e7          	jalr	-264(ra) # 800048a6 <log_write>
    800039b6:	b771                	j	80003942 <bmap+0x54>
  panic("bmap: out of range");
    800039b8:	00005517          	auipc	a0,0x5
    800039bc:	c5050513          	addi	a0,a0,-944 # 80008608 <syscalls+0x118>
    800039c0:	ffffd097          	auipc	ra,0xffffd
    800039c4:	b7e080e7          	jalr	-1154(ra) # 8000053e <panic>

00000000800039c8 <iget>:
{
    800039c8:	7179                	addi	sp,sp,-48
    800039ca:	f406                	sd	ra,40(sp)
    800039cc:	f022                	sd	s0,32(sp)
    800039ce:	ec26                	sd	s1,24(sp)
    800039d0:	e84a                	sd	s2,16(sp)
    800039d2:	e44e                	sd	s3,8(sp)
    800039d4:	e052                	sd	s4,0(sp)
    800039d6:	1800                	addi	s0,sp,48
    800039d8:	89aa                	mv	s3,a0
    800039da:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800039dc:	0001d517          	auipc	a0,0x1d
    800039e0:	92c50513          	addi	a0,a0,-1748 # 80020308 <itable>
    800039e4:	ffffd097          	auipc	ra,0xffffd
    800039e8:	200080e7          	jalr	512(ra) # 80000be4 <acquire>
  empty = 0;
    800039ec:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039ee:	0001d497          	auipc	s1,0x1d
    800039f2:	93248493          	addi	s1,s1,-1742 # 80020320 <itable+0x18>
    800039f6:	0001e697          	auipc	a3,0x1e
    800039fa:	3ba68693          	addi	a3,a3,954 # 80021db0 <log>
    800039fe:	a039                	j	80003a0c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a00:	02090b63          	beqz	s2,80003a36 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a04:	08848493          	addi	s1,s1,136
    80003a08:	02d48a63          	beq	s1,a3,80003a3c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a0c:	449c                	lw	a5,8(s1)
    80003a0e:	fef059e3          	blez	a5,80003a00 <iget+0x38>
    80003a12:	4098                	lw	a4,0(s1)
    80003a14:	ff3716e3          	bne	a4,s3,80003a00 <iget+0x38>
    80003a18:	40d8                	lw	a4,4(s1)
    80003a1a:	ff4713e3          	bne	a4,s4,80003a00 <iget+0x38>
      ip->ref++;
    80003a1e:	2785                	addiw	a5,a5,1
    80003a20:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a22:	0001d517          	auipc	a0,0x1d
    80003a26:	8e650513          	addi	a0,a0,-1818 # 80020308 <itable>
    80003a2a:	ffffd097          	auipc	ra,0xffffd
    80003a2e:	26e080e7          	jalr	622(ra) # 80000c98 <release>
      return ip;
    80003a32:	8926                	mv	s2,s1
    80003a34:	a03d                	j	80003a62 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a36:	f7f9                	bnez	a5,80003a04 <iget+0x3c>
    80003a38:	8926                	mv	s2,s1
    80003a3a:	b7e9                	j	80003a04 <iget+0x3c>
  if(empty == 0)
    80003a3c:	02090c63          	beqz	s2,80003a74 <iget+0xac>
  ip->dev = dev;
    80003a40:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a44:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a48:	4785                	li	a5,1
    80003a4a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a4e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a52:	0001d517          	auipc	a0,0x1d
    80003a56:	8b650513          	addi	a0,a0,-1866 # 80020308 <itable>
    80003a5a:	ffffd097          	auipc	ra,0xffffd
    80003a5e:	23e080e7          	jalr	574(ra) # 80000c98 <release>
}
    80003a62:	854a                	mv	a0,s2
    80003a64:	70a2                	ld	ra,40(sp)
    80003a66:	7402                	ld	s0,32(sp)
    80003a68:	64e2                	ld	s1,24(sp)
    80003a6a:	6942                	ld	s2,16(sp)
    80003a6c:	69a2                	ld	s3,8(sp)
    80003a6e:	6a02                	ld	s4,0(sp)
    80003a70:	6145                	addi	sp,sp,48
    80003a72:	8082                	ret
    panic("iget: no inodes");
    80003a74:	00005517          	auipc	a0,0x5
    80003a78:	bac50513          	addi	a0,a0,-1108 # 80008620 <syscalls+0x130>
    80003a7c:	ffffd097          	auipc	ra,0xffffd
    80003a80:	ac2080e7          	jalr	-1342(ra) # 8000053e <panic>

0000000080003a84 <fsinit>:
fsinit(int dev) {
    80003a84:	7179                	addi	sp,sp,-48
    80003a86:	f406                	sd	ra,40(sp)
    80003a88:	f022                	sd	s0,32(sp)
    80003a8a:	ec26                	sd	s1,24(sp)
    80003a8c:	e84a                	sd	s2,16(sp)
    80003a8e:	e44e                	sd	s3,8(sp)
    80003a90:	1800                	addi	s0,sp,48
    80003a92:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a94:	4585                	li	a1,1
    80003a96:	00000097          	auipc	ra,0x0
    80003a9a:	a64080e7          	jalr	-1436(ra) # 800034fa <bread>
    80003a9e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003aa0:	0001d997          	auipc	s3,0x1d
    80003aa4:	84898993          	addi	s3,s3,-1976 # 800202e8 <sb>
    80003aa8:	02000613          	li	a2,32
    80003aac:	05850593          	addi	a1,a0,88
    80003ab0:	854e                	mv	a0,s3
    80003ab2:	ffffd097          	auipc	ra,0xffffd
    80003ab6:	28e080e7          	jalr	654(ra) # 80000d40 <memmove>
  brelse(bp);
    80003aba:	8526                	mv	a0,s1
    80003abc:	00000097          	auipc	ra,0x0
    80003ac0:	b6e080e7          	jalr	-1170(ra) # 8000362a <brelse>
  if(sb.magic != FSMAGIC)
    80003ac4:	0009a703          	lw	a4,0(s3)
    80003ac8:	102037b7          	lui	a5,0x10203
    80003acc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ad0:	02f71263          	bne	a4,a5,80003af4 <fsinit+0x70>
  initlog(dev, &sb);
    80003ad4:	0001d597          	auipc	a1,0x1d
    80003ad8:	81458593          	addi	a1,a1,-2028 # 800202e8 <sb>
    80003adc:	854a                	mv	a0,s2
    80003ade:	00001097          	auipc	ra,0x1
    80003ae2:	b4c080e7          	jalr	-1204(ra) # 8000462a <initlog>
}
    80003ae6:	70a2                	ld	ra,40(sp)
    80003ae8:	7402                	ld	s0,32(sp)
    80003aea:	64e2                	ld	s1,24(sp)
    80003aec:	6942                	ld	s2,16(sp)
    80003aee:	69a2                	ld	s3,8(sp)
    80003af0:	6145                	addi	sp,sp,48
    80003af2:	8082                	ret
    panic("invalid file system");
    80003af4:	00005517          	auipc	a0,0x5
    80003af8:	b3c50513          	addi	a0,a0,-1220 # 80008630 <syscalls+0x140>
    80003afc:	ffffd097          	auipc	ra,0xffffd
    80003b00:	a42080e7          	jalr	-1470(ra) # 8000053e <panic>

0000000080003b04 <iinit>:
{
    80003b04:	7179                	addi	sp,sp,-48
    80003b06:	f406                	sd	ra,40(sp)
    80003b08:	f022                	sd	s0,32(sp)
    80003b0a:	ec26                	sd	s1,24(sp)
    80003b0c:	e84a                	sd	s2,16(sp)
    80003b0e:	e44e                	sd	s3,8(sp)
    80003b10:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b12:	00005597          	auipc	a1,0x5
    80003b16:	b3658593          	addi	a1,a1,-1226 # 80008648 <syscalls+0x158>
    80003b1a:	0001c517          	auipc	a0,0x1c
    80003b1e:	7ee50513          	addi	a0,a0,2030 # 80020308 <itable>
    80003b22:	ffffd097          	auipc	ra,0xffffd
    80003b26:	032080e7          	jalr	50(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b2a:	0001d497          	auipc	s1,0x1d
    80003b2e:	80648493          	addi	s1,s1,-2042 # 80020330 <itable+0x28>
    80003b32:	0001e997          	auipc	s3,0x1e
    80003b36:	28e98993          	addi	s3,s3,654 # 80021dc0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b3a:	00005917          	auipc	s2,0x5
    80003b3e:	b1690913          	addi	s2,s2,-1258 # 80008650 <syscalls+0x160>
    80003b42:	85ca                	mv	a1,s2
    80003b44:	8526                	mv	a0,s1
    80003b46:	00001097          	auipc	ra,0x1
    80003b4a:	e46080e7          	jalr	-442(ra) # 8000498c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b4e:	08848493          	addi	s1,s1,136
    80003b52:	ff3498e3          	bne	s1,s3,80003b42 <iinit+0x3e>
}
    80003b56:	70a2                	ld	ra,40(sp)
    80003b58:	7402                	ld	s0,32(sp)
    80003b5a:	64e2                	ld	s1,24(sp)
    80003b5c:	6942                	ld	s2,16(sp)
    80003b5e:	69a2                	ld	s3,8(sp)
    80003b60:	6145                	addi	sp,sp,48
    80003b62:	8082                	ret

0000000080003b64 <ialloc>:
{
    80003b64:	715d                	addi	sp,sp,-80
    80003b66:	e486                	sd	ra,72(sp)
    80003b68:	e0a2                	sd	s0,64(sp)
    80003b6a:	fc26                	sd	s1,56(sp)
    80003b6c:	f84a                	sd	s2,48(sp)
    80003b6e:	f44e                	sd	s3,40(sp)
    80003b70:	f052                	sd	s4,32(sp)
    80003b72:	ec56                	sd	s5,24(sp)
    80003b74:	e85a                	sd	s6,16(sp)
    80003b76:	e45e                	sd	s7,8(sp)
    80003b78:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b7a:	0001c717          	auipc	a4,0x1c
    80003b7e:	77a72703          	lw	a4,1914(a4) # 800202f4 <sb+0xc>
    80003b82:	4785                	li	a5,1
    80003b84:	04e7fa63          	bgeu	a5,a4,80003bd8 <ialloc+0x74>
    80003b88:	8aaa                	mv	s5,a0
    80003b8a:	8bae                	mv	s7,a1
    80003b8c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b8e:	0001ca17          	auipc	s4,0x1c
    80003b92:	75aa0a13          	addi	s4,s4,1882 # 800202e8 <sb>
    80003b96:	00048b1b          	sext.w	s6,s1
    80003b9a:	0044d593          	srli	a1,s1,0x4
    80003b9e:	018a2783          	lw	a5,24(s4)
    80003ba2:	9dbd                	addw	a1,a1,a5
    80003ba4:	8556                	mv	a0,s5
    80003ba6:	00000097          	auipc	ra,0x0
    80003baa:	954080e7          	jalr	-1708(ra) # 800034fa <bread>
    80003bae:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003bb0:	05850993          	addi	s3,a0,88
    80003bb4:	00f4f793          	andi	a5,s1,15
    80003bb8:	079a                	slli	a5,a5,0x6
    80003bba:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003bbc:	00099783          	lh	a5,0(s3)
    80003bc0:	c785                	beqz	a5,80003be8 <ialloc+0x84>
    brelse(bp);
    80003bc2:	00000097          	auipc	ra,0x0
    80003bc6:	a68080e7          	jalr	-1432(ra) # 8000362a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bca:	0485                	addi	s1,s1,1
    80003bcc:	00ca2703          	lw	a4,12(s4)
    80003bd0:	0004879b          	sext.w	a5,s1
    80003bd4:	fce7e1e3          	bltu	a5,a4,80003b96 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003bd8:	00005517          	auipc	a0,0x5
    80003bdc:	a8050513          	addi	a0,a0,-1408 # 80008658 <syscalls+0x168>
    80003be0:	ffffd097          	auipc	ra,0xffffd
    80003be4:	95e080e7          	jalr	-1698(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003be8:	04000613          	li	a2,64
    80003bec:	4581                	li	a1,0
    80003bee:	854e                	mv	a0,s3
    80003bf0:	ffffd097          	auipc	ra,0xffffd
    80003bf4:	0f0080e7          	jalr	240(ra) # 80000ce0 <memset>
      dip->type = type;
    80003bf8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003bfc:	854a                	mv	a0,s2
    80003bfe:	00001097          	auipc	ra,0x1
    80003c02:	ca8080e7          	jalr	-856(ra) # 800048a6 <log_write>
      brelse(bp);
    80003c06:	854a                	mv	a0,s2
    80003c08:	00000097          	auipc	ra,0x0
    80003c0c:	a22080e7          	jalr	-1502(ra) # 8000362a <brelse>
      return iget(dev, inum);
    80003c10:	85da                	mv	a1,s6
    80003c12:	8556                	mv	a0,s5
    80003c14:	00000097          	auipc	ra,0x0
    80003c18:	db4080e7          	jalr	-588(ra) # 800039c8 <iget>
}
    80003c1c:	60a6                	ld	ra,72(sp)
    80003c1e:	6406                	ld	s0,64(sp)
    80003c20:	74e2                	ld	s1,56(sp)
    80003c22:	7942                	ld	s2,48(sp)
    80003c24:	79a2                	ld	s3,40(sp)
    80003c26:	7a02                	ld	s4,32(sp)
    80003c28:	6ae2                	ld	s5,24(sp)
    80003c2a:	6b42                	ld	s6,16(sp)
    80003c2c:	6ba2                	ld	s7,8(sp)
    80003c2e:	6161                	addi	sp,sp,80
    80003c30:	8082                	ret

0000000080003c32 <iupdate>:
{
    80003c32:	1101                	addi	sp,sp,-32
    80003c34:	ec06                	sd	ra,24(sp)
    80003c36:	e822                	sd	s0,16(sp)
    80003c38:	e426                	sd	s1,8(sp)
    80003c3a:	e04a                	sd	s2,0(sp)
    80003c3c:	1000                	addi	s0,sp,32
    80003c3e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c40:	415c                	lw	a5,4(a0)
    80003c42:	0047d79b          	srliw	a5,a5,0x4
    80003c46:	0001c597          	auipc	a1,0x1c
    80003c4a:	6ba5a583          	lw	a1,1722(a1) # 80020300 <sb+0x18>
    80003c4e:	9dbd                	addw	a1,a1,a5
    80003c50:	4108                	lw	a0,0(a0)
    80003c52:	00000097          	auipc	ra,0x0
    80003c56:	8a8080e7          	jalr	-1880(ra) # 800034fa <bread>
    80003c5a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c5c:	05850793          	addi	a5,a0,88
    80003c60:	40c8                	lw	a0,4(s1)
    80003c62:	893d                	andi	a0,a0,15
    80003c64:	051a                	slli	a0,a0,0x6
    80003c66:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c68:	04449703          	lh	a4,68(s1)
    80003c6c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003c70:	04649703          	lh	a4,70(s1)
    80003c74:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003c78:	04849703          	lh	a4,72(s1)
    80003c7c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c80:	04a49703          	lh	a4,74(s1)
    80003c84:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c88:	44f8                	lw	a4,76(s1)
    80003c8a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c8c:	03400613          	li	a2,52
    80003c90:	05048593          	addi	a1,s1,80
    80003c94:	0531                	addi	a0,a0,12
    80003c96:	ffffd097          	auipc	ra,0xffffd
    80003c9a:	0aa080e7          	jalr	170(ra) # 80000d40 <memmove>
  log_write(bp);
    80003c9e:	854a                	mv	a0,s2
    80003ca0:	00001097          	auipc	ra,0x1
    80003ca4:	c06080e7          	jalr	-1018(ra) # 800048a6 <log_write>
  brelse(bp);
    80003ca8:	854a                	mv	a0,s2
    80003caa:	00000097          	auipc	ra,0x0
    80003cae:	980080e7          	jalr	-1664(ra) # 8000362a <brelse>
}
    80003cb2:	60e2                	ld	ra,24(sp)
    80003cb4:	6442                	ld	s0,16(sp)
    80003cb6:	64a2                	ld	s1,8(sp)
    80003cb8:	6902                	ld	s2,0(sp)
    80003cba:	6105                	addi	sp,sp,32
    80003cbc:	8082                	ret

0000000080003cbe <idup>:
{
    80003cbe:	1101                	addi	sp,sp,-32
    80003cc0:	ec06                	sd	ra,24(sp)
    80003cc2:	e822                	sd	s0,16(sp)
    80003cc4:	e426                	sd	s1,8(sp)
    80003cc6:	1000                	addi	s0,sp,32
    80003cc8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cca:	0001c517          	auipc	a0,0x1c
    80003cce:	63e50513          	addi	a0,a0,1598 # 80020308 <itable>
    80003cd2:	ffffd097          	auipc	ra,0xffffd
    80003cd6:	f12080e7          	jalr	-238(ra) # 80000be4 <acquire>
  ip->ref++;
    80003cda:	449c                	lw	a5,8(s1)
    80003cdc:	2785                	addiw	a5,a5,1
    80003cde:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ce0:	0001c517          	auipc	a0,0x1c
    80003ce4:	62850513          	addi	a0,a0,1576 # 80020308 <itable>
    80003ce8:	ffffd097          	auipc	ra,0xffffd
    80003cec:	fb0080e7          	jalr	-80(ra) # 80000c98 <release>
}
    80003cf0:	8526                	mv	a0,s1
    80003cf2:	60e2                	ld	ra,24(sp)
    80003cf4:	6442                	ld	s0,16(sp)
    80003cf6:	64a2                	ld	s1,8(sp)
    80003cf8:	6105                	addi	sp,sp,32
    80003cfa:	8082                	ret

0000000080003cfc <ilock>:
{
    80003cfc:	1101                	addi	sp,sp,-32
    80003cfe:	ec06                	sd	ra,24(sp)
    80003d00:	e822                	sd	s0,16(sp)
    80003d02:	e426                	sd	s1,8(sp)
    80003d04:	e04a                	sd	s2,0(sp)
    80003d06:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d08:	c115                	beqz	a0,80003d2c <ilock+0x30>
    80003d0a:	84aa                	mv	s1,a0
    80003d0c:	451c                	lw	a5,8(a0)
    80003d0e:	00f05f63          	blez	a5,80003d2c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d12:	0541                	addi	a0,a0,16
    80003d14:	00001097          	auipc	ra,0x1
    80003d18:	cb2080e7          	jalr	-846(ra) # 800049c6 <acquiresleep>
  if(ip->valid == 0){
    80003d1c:	40bc                	lw	a5,64(s1)
    80003d1e:	cf99                	beqz	a5,80003d3c <ilock+0x40>
}
    80003d20:	60e2                	ld	ra,24(sp)
    80003d22:	6442                	ld	s0,16(sp)
    80003d24:	64a2                	ld	s1,8(sp)
    80003d26:	6902                	ld	s2,0(sp)
    80003d28:	6105                	addi	sp,sp,32
    80003d2a:	8082                	ret
    panic("ilock");
    80003d2c:	00005517          	auipc	a0,0x5
    80003d30:	94450513          	addi	a0,a0,-1724 # 80008670 <syscalls+0x180>
    80003d34:	ffffd097          	auipc	ra,0xffffd
    80003d38:	80a080e7          	jalr	-2038(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d3c:	40dc                	lw	a5,4(s1)
    80003d3e:	0047d79b          	srliw	a5,a5,0x4
    80003d42:	0001c597          	auipc	a1,0x1c
    80003d46:	5be5a583          	lw	a1,1470(a1) # 80020300 <sb+0x18>
    80003d4a:	9dbd                	addw	a1,a1,a5
    80003d4c:	4088                	lw	a0,0(s1)
    80003d4e:	fffff097          	auipc	ra,0xfffff
    80003d52:	7ac080e7          	jalr	1964(ra) # 800034fa <bread>
    80003d56:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d58:	05850593          	addi	a1,a0,88
    80003d5c:	40dc                	lw	a5,4(s1)
    80003d5e:	8bbd                	andi	a5,a5,15
    80003d60:	079a                	slli	a5,a5,0x6
    80003d62:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d64:	00059783          	lh	a5,0(a1)
    80003d68:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d6c:	00259783          	lh	a5,2(a1)
    80003d70:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d74:	00459783          	lh	a5,4(a1)
    80003d78:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d7c:	00659783          	lh	a5,6(a1)
    80003d80:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d84:	459c                	lw	a5,8(a1)
    80003d86:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d88:	03400613          	li	a2,52
    80003d8c:	05b1                	addi	a1,a1,12
    80003d8e:	05048513          	addi	a0,s1,80
    80003d92:	ffffd097          	auipc	ra,0xffffd
    80003d96:	fae080e7          	jalr	-82(ra) # 80000d40 <memmove>
    brelse(bp);
    80003d9a:	854a                	mv	a0,s2
    80003d9c:	00000097          	auipc	ra,0x0
    80003da0:	88e080e7          	jalr	-1906(ra) # 8000362a <brelse>
    ip->valid = 1;
    80003da4:	4785                	li	a5,1
    80003da6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003da8:	04449783          	lh	a5,68(s1)
    80003dac:	fbb5                	bnez	a5,80003d20 <ilock+0x24>
      panic("ilock: no type");
    80003dae:	00005517          	auipc	a0,0x5
    80003db2:	8ca50513          	addi	a0,a0,-1846 # 80008678 <syscalls+0x188>
    80003db6:	ffffc097          	auipc	ra,0xffffc
    80003dba:	788080e7          	jalr	1928(ra) # 8000053e <panic>

0000000080003dbe <iunlock>:
{
    80003dbe:	1101                	addi	sp,sp,-32
    80003dc0:	ec06                	sd	ra,24(sp)
    80003dc2:	e822                	sd	s0,16(sp)
    80003dc4:	e426                	sd	s1,8(sp)
    80003dc6:	e04a                	sd	s2,0(sp)
    80003dc8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003dca:	c905                	beqz	a0,80003dfa <iunlock+0x3c>
    80003dcc:	84aa                	mv	s1,a0
    80003dce:	01050913          	addi	s2,a0,16
    80003dd2:	854a                	mv	a0,s2
    80003dd4:	00001097          	auipc	ra,0x1
    80003dd8:	c8c080e7          	jalr	-884(ra) # 80004a60 <holdingsleep>
    80003ddc:	cd19                	beqz	a0,80003dfa <iunlock+0x3c>
    80003dde:	449c                	lw	a5,8(s1)
    80003de0:	00f05d63          	blez	a5,80003dfa <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003de4:	854a                	mv	a0,s2
    80003de6:	00001097          	auipc	ra,0x1
    80003dea:	c36080e7          	jalr	-970(ra) # 80004a1c <releasesleep>
}
    80003dee:	60e2                	ld	ra,24(sp)
    80003df0:	6442                	ld	s0,16(sp)
    80003df2:	64a2                	ld	s1,8(sp)
    80003df4:	6902                	ld	s2,0(sp)
    80003df6:	6105                	addi	sp,sp,32
    80003df8:	8082                	ret
    panic("iunlock");
    80003dfa:	00005517          	auipc	a0,0x5
    80003dfe:	88e50513          	addi	a0,a0,-1906 # 80008688 <syscalls+0x198>
    80003e02:	ffffc097          	auipc	ra,0xffffc
    80003e06:	73c080e7          	jalr	1852(ra) # 8000053e <panic>

0000000080003e0a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e0a:	7179                	addi	sp,sp,-48
    80003e0c:	f406                	sd	ra,40(sp)
    80003e0e:	f022                	sd	s0,32(sp)
    80003e10:	ec26                	sd	s1,24(sp)
    80003e12:	e84a                	sd	s2,16(sp)
    80003e14:	e44e                	sd	s3,8(sp)
    80003e16:	e052                	sd	s4,0(sp)
    80003e18:	1800                	addi	s0,sp,48
    80003e1a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e1c:	05050493          	addi	s1,a0,80
    80003e20:	08050913          	addi	s2,a0,128
    80003e24:	a021                	j	80003e2c <itrunc+0x22>
    80003e26:	0491                	addi	s1,s1,4
    80003e28:	01248d63          	beq	s1,s2,80003e42 <itrunc+0x38>
    if(ip->addrs[i]){
    80003e2c:	408c                	lw	a1,0(s1)
    80003e2e:	dde5                	beqz	a1,80003e26 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e30:	0009a503          	lw	a0,0(s3)
    80003e34:	00000097          	auipc	ra,0x0
    80003e38:	90c080e7          	jalr	-1780(ra) # 80003740 <bfree>
      ip->addrs[i] = 0;
    80003e3c:	0004a023          	sw	zero,0(s1)
    80003e40:	b7dd                	j	80003e26 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e42:	0809a583          	lw	a1,128(s3)
    80003e46:	e185                	bnez	a1,80003e66 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e48:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e4c:	854e                	mv	a0,s3
    80003e4e:	00000097          	auipc	ra,0x0
    80003e52:	de4080e7          	jalr	-540(ra) # 80003c32 <iupdate>
}
    80003e56:	70a2                	ld	ra,40(sp)
    80003e58:	7402                	ld	s0,32(sp)
    80003e5a:	64e2                	ld	s1,24(sp)
    80003e5c:	6942                	ld	s2,16(sp)
    80003e5e:	69a2                	ld	s3,8(sp)
    80003e60:	6a02                	ld	s4,0(sp)
    80003e62:	6145                	addi	sp,sp,48
    80003e64:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e66:	0009a503          	lw	a0,0(s3)
    80003e6a:	fffff097          	auipc	ra,0xfffff
    80003e6e:	690080e7          	jalr	1680(ra) # 800034fa <bread>
    80003e72:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e74:	05850493          	addi	s1,a0,88
    80003e78:	45850913          	addi	s2,a0,1112
    80003e7c:	a811                	j	80003e90 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003e7e:	0009a503          	lw	a0,0(s3)
    80003e82:	00000097          	auipc	ra,0x0
    80003e86:	8be080e7          	jalr	-1858(ra) # 80003740 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003e8a:	0491                	addi	s1,s1,4
    80003e8c:	01248563          	beq	s1,s2,80003e96 <itrunc+0x8c>
      if(a[j])
    80003e90:	408c                	lw	a1,0(s1)
    80003e92:	dde5                	beqz	a1,80003e8a <itrunc+0x80>
    80003e94:	b7ed                	j	80003e7e <itrunc+0x74>
    brelse(bp);
    80003e96:	8552                	mv	a0,s4
    80003e98:	fffff097          	auipc	ra,0xfffff
    80003e9c:	792080e7          	jalr	1938(ra) # 8000362a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ea0:	0809a583          	lw	a1,128(s3)
    80003ea4:	0009a503          	lw	a0,0(s3)
    80003ea8:	00000097          	auipc	ra,0x0
    80003eac:	898080e7          	jalr	-1896(ra) # 80003740 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003eb0:	0809a023          	sw	zero,128(s3)
    80003eb4:	bf51                	j	80003e48 <itrunc+0x3e>

0000000080003eb6 <iput>:
{
    80003eb6:	1101                	addi	sp,sp,-32
    80003eb8:	ec06                	sd	ra,24(sp)
    80003eba:	e822                	sd	s0,16(sp)
    80003ebc:	e426                	sd	s1,8(sp)
    80003ebe:	e04a                	sd	s2,0(sp)
    80003ec0:	1000                	addi	s0,sp,32
    80003ec2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ec4:	0001c517          	auipc	a0,0x1c
    80003ec8:	44450513          	addi	a0,a0,1092 # 80020308 <itable>
    80003ecc:	ffffd097          	auipc	ra,0xffffd
    80003ed0:	d18080e7          	jalr	-744(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ed4:	4498                	lw	a4,8(s1)
    80003ed6:	4785                	li	a5,1
    80003ed8:	02f70363          	beq	a4,a5,80003efe <iput+0x48>
  ip->ref--;
    80003edc:	449c                	lw	a5,8(s1)
    80003ede:	37fd                	addiw	a5,a5,-1
    80003ee0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ee2:	0001c517          	auipc	a0,0x1c
    80003ee6:	42650513          	addi	a0,a0,1062 # 80020308 <itable>
    80003eea:	ffffd097          	auipc	ra,0xffffd
    80003eee:	dae080e7          	jalr	-594(ra) # 80000c98 <release>
}
    80003ef2:	60e2                	ld	ra,24(sp)
    80003ef4:	6442                	ld	s0,16(sp)
    80003ef6:	64a2                	ld	s1,8(sp)
    80003ef8:	6902                	ld	s2,0(sp)
    80003efa:	6105                	addi	sp,sp,32
    80003efc:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003efe:	40bc                	lw	a5,64(s1)
    80003f00:	dff1                	beqz	a5,80003edc <iput+0x26>
    80003f02:	04a49783          	lh	a5,74(s1)
    80003f06:	fbf9                	bnez	a5,80003edc <iput+0x26>
    acquiresleep(&ip->lock);
    80003f08:	01048913          	addi	s2,s1,16
    80003f0c:	854a                	mv	a0,s2
    80003f0e:	00001097          	auipc	ra,0x1
    80003f12:	ab8080e7          	jalr	-1352(ra) # 800049c6 <acquiresleep>
    release(&itable.lock);
    80003f16:	0001c517          	auipc	a0,0x1c
    80003f1a:	3f250513          	addi	a0,a0,1010 # 80020308 <itable>
    80003f1e:	ffffd097          	auipc	ra,0xffffd
    80003f22:	d7a080e7          	jalr	-646(ra) # 80000c98 <release>
    itrunc(ip);
    80003f26:	8526                	mv	a0,s1
    80003f28:	00000097          	auipc	ra,0x0
    80003f2c:	ee2080e7          	jalr	-286(ra) # 80003e0a <itrunc>
    ip->type = 0;
    80003f30:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f34:	8526                	mv	a0,s1
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	cfc080e7          	jalr	-772(ra) # 80003c32 <iupdate>
    ip->valid = 0;
    80003f3e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f42:	854a                	mv	a0,s2
    80003f44:	00001097          	auipc	ra,0x1
    80003f48:	ad8080e7          	jalr	-1320(ra) # 80004a1c <releasesleep>
    acquire(&itable.lock);
    80003f4c:	0001c517          	auipc	a0,0x1c
    80003f50:	3bc50513          	addi	a0,a0,956 # 80020308 <itable>
    80003f54:	ffffd097          	auipc	ra,0xffffd
    80003f58:	c90080e7          	jalr	-880(ra) # 80000be4 <acquire>
    80003f5c:	b741                	j	80003edc <iput+0x26>

0000000080003f5e <iunlockput>:
{
    80003f5e:	1101                	addi	sp,sp,-32
    80003f60:	ec06                	sd	ra,24(sp)
    80003f62:	e822                	sd	s0,16(sp)
    80003f64:	e426                	sd	s1,8(sp)
    80003f66:	1000                	addi	s0,sp,32
    80003f68:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f6a:	00000097          	auipc	ra,0x0
    80003f6e:	e54080e7          	jalr	-428(ra) # 80003dbe <iunlock>
  iput(ip);
    80003f72:	8526                	mv	a0,s1
    80003f74:	00000097          	auipc	ra,0x0
    80003f78:	f42080e7          	jalr	-190(ra) # 80003eb6 <iput>
}
    80003f7c:	60e2                	ld	ra,24(sp)
    80003f7e:	6442                	ld	s0,16(sp)
    80003f80:	64a2                	ld	s1,8(sp)
    80003f82:	6105                	addi	sp,sp,32
    80003f84:	8082                	ret

0000000080003f86 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f86:	1141                	addi	sp,sp,-16
    80003f88:	e422                	sd	s0,8(sp)
    80003f8a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f8c:	411c                	lw	a5,0(a0)
    80003f8e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f90:	415c                	lw	a5,4(a0)
    80003f92:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f94:	04451783          	lh	a5,68(a0)
    80003f98:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f9c:	04a51783          	lh	a5,74(a0)
    80003fa0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003fa4:	04c56783          	lwu	a5,76(a0)
    80003fa8:	e99c                	sd	a5,16(a1)
}
    80003faa:	6422                	ld	s0,8(sp)
    80003fac:	0141                	addi	sp,sp,16
    80003fae:	8082                	ret

0000000080003fb0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fb0:	457c                	lw	a5,76(a0)
    80003fb2:	0ed7e963          	bltu	a5,a3,800040a4 <readi+0xf4>
{
    80003fb6:	7159                	addi	sp,sp,-112
    80003fb8:	f486                	sd	ra,104(sp)
    80003fba:	f0a2                	sd	s0,96(sp)
    80003fbc:	eca6                	sd	s1,88(sp)
    80003fbe:	e8ca                	sd	s2,80(sp)
    80003fc0:	e4ce                	sd	s3,72(sp)
    80003fc2:	e0d2                	sd	s4,64(sp)
    80003fc4:	fc56                	sd	s5,56(sp)
    80003fc6:	f85a                	sd	s6,48(sp)
    80003fc8:	f45e                	sd	s7,40(sp)
    80003fca:	f062                	sd	s8,32(sp)
    80003fcc:	ec66                	sd	s9,24(sp)
    80003fce:	e86a                	sd	s10,16(sp)
    80003fd0:	e46e                	sd	s11,8(sp)
    80003fd2:	1880                	addi	s0,sp,112
    80003fd4:	8baa                	mv	s7,a0
    80003fd6:	8c2e                	mv	s8,a1
    80003fd8:	8ab2                	mv	s5,a2
    80003fda:	84b6                	mv	s1,a3
    80003fdc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003fde:	9f35                	addw	a4,a4,a3
    return 0;
    80003fe0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003fe2:	0ad76063          	bltu	a4,a3,80004082 <readi+0xd2>
  if(off + n > ip->size)
    80003fe6:	00e7f463          	bgeu	a5,a4,80003fee <readi+0x3e>
    n = ip->size - off;
    80003fea:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fee:	0a0b0963          	beqz	s6,800040a0 <readi+0xf0>
    80003ff2:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ff4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ff8:	5cfd                	li	s9,-1
    80003ffa:	a82d                	j	80004034 <readi+0x84>
    80003ffc:	020a1d93          	slli	s11,s4,0x20
    80004000:	020ddd93          	srli	s11,s11,0x20
    80004004:	05890613          	addi	a2,s2,88
    80004008:	86ee                	mv	a3,s11
    8000400a:	963a                	add	a2,a2,a4
    8000400c:	85d6                	mv	a1,s5
    8000400e:	8562                	mv	a0,s8
    80004010:	fffff097          	auipc	ra,0xfffff
    80004014:	a42080e7          	jalr	-1470(ra) # 80002a52 <either_copyout>
    80004018:	05950d63          	beq	a0,s9,80004072 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000401c:	854a                	mv	a0,s2
    8000401e:	fffff097          	auipc	ra,0xfffff
    80004022:	60c080e7          	jalr	1548(ra) # 8000362a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004026:	013a09bb          	addw	s3,s4,s3
    8000402a:	009a04bb          	addw	s1,s4,s1
    8000402e:	9aee                	add	s5,s5,s11
    80004030:	0569f763          	bgeu	s3,s6,8000407e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004034:	000ba903          	lw	s2,0(s7)
    80004038:	00a4d59b          	srliw	a1,s1,0xa
    8000403c:	855e                	mv	a0,s7
    8000403e:	00000097          	auipc	ra,0x0
    80004042:	8b0080e7          	jalr	-1872(ra) # 800038ee <bmap>
    80004046:	0005059b          	sext.w	a1,a0
    8000404a:	854a                	mv	a0,s2
    8000404c:	fffff097          	auipc	ra,0xfffff
    80004050:	4ae080e7          	jalr	1198(ra) # 800034fa <bread>
    80004054:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004056:	3ff4f713          	andi	a4,s1,1023
    8000405a:	40ed07bb          	subw	a5,s10,a4
    8000405e:	413b06bb          	subw	a3,s6,s3
    80004062:	8a3e                	mv	s4,a5
    80004064:	2781                	sext.w	a5,a5
    80004066:	0006861b          	sext.w	a2,a3
    8000406a:	f8f679e3          	bgeu	a2,a5,80003ffc <readi+0x4c>
    8000406e:	8a36                	mv	s4,a3
    80004070:	b771                	j	80003ffc <readi+0x4c>
      brelse(bp);
    80004072:	854a                	mv	a0,s2
    80004074:	fffff097          	auipc	ra,0xfffff
    80004078:	5b6080e7          	jalr	1462(ra) # 8000362a <brelse>
      tot = -1;
    8000407c:	59fd                	li	s3,-1
  }
  return tot;
    8000407e:	0009851b          	sext.w	a0,s3
}
    80004082:	70a6                	ld	ra,104(sp)
    80004084:	7406                	ld	s0,96(sp)
    80004086:	64e6                	ld	s1,88(sp)
    80004088:	6946                	ld	s2,80(sp)
    8000408a:	69a6                	ld	s3,72(sp)
    8000408c:	6a06                	ld	s4,64(sp)
    8000408e:	7ae2                	ld	s5,56(sp)
    80004090:	7b42                	ld	s6,48(sp)
    80004092:	7ba2                	ld	s7,40(sp)
    80004094:	7c02                	ld	s8,32(sp)
    80004096:	6ce2                	ld	s9,24(sp)
    80004098:	6d42                	ld	s10,16(sp)
    8000409a:	6da2                	ld	s11,8(sp)
    8000409c:	6165                	addi	sp,sp,112
    8000409e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040a0:	89da                	mv	s3,s6
    800040a2:	bff1                	j	8000407e <readi+0xce>
    return 0;
    800040a4:	4501                	li	a0,0
}
    800040a6:	8082                	ret

00000000800040a8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040a8:	457c                	lw	a5,76(a0)
    800040aa:	10d7e863          	bltu	a5,a3,800041ba <writei+0x112>
{
    800040ae:	7159                	addi	sp,sp,-112
    800040b0:	f486                	sd	ra,104(sp)
    800040b2:	f0a2                	sd	s0,96(sp)
    800040b4:	eca6                	sd	s1,88(sp)
    800040b6:	e8ca                	sd	s2,80(sp)
    800040b8:	e4ce                	sd	s3,72(sp)
    800040ba:	e0d2                	sd	s4,64(sp)
    800040bc:	fc56                	sd	s5,56(sp)
    800040be:	f85a                	sd	s6,48(sp)
    800040c0:	f45e                	sd	s7,40(sp)
    800040c2:	f062                	sd	s8,32(sp)
    800040c4:	ec66                	sd	s9,24(sp)
    800040c6:	e86a                	sd	s10,16(sp)
    800040c8:	e46e                	sd	s11,8(sp)
    800040ca:	1880                	addi	s0,sp,112
    800040cc:	8b2a                	mv	s6,a0
    800040ce:	8c2e                	mv	s8,a1
    800040d0:	8ab2                	mv	s5,a2
    800040d2:	8936                	mv	s2,a3
    800040d4:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800040d6:	00e687bb          	addw	a5,a3,a4
    800040da:	0ed7e263          	bltu	a5,a3,800041be <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800040de:	00043737          	lui	a4,0x43
    800040e2:	0ef76063          	bltu	a4,a5,800041c2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040e6:	0c0b8863          	beqz	s7,800041b6 <writei+0x10e>
    800040ea:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040ec:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800040f0:	5cfd                	li	s9,-1
    800040f2:	a091                	j	80004136 <writei+0x8e>
    800040f4:	02099d93          	slli	s11,s3,0x20
    800040f8:	020ddd93          	srli	s11,s11,0x20
    800040fc:	05848513          	addi	a0,s1,88
    80004100:	86ee                	mv	a3,s11
    80004102:	8656                	mv	a2,s5
    80004104:	85e2                	mv	a1,s8
    80004106:	953a                	add	a0,a0,a4
    80004108:	fffff097          	auipc	ra,0xfffff
    8000410c:	9a0080e7          	jalr	-1632(ra) # 80002aa8 <either_copyin>
    80004110:	07950263          	beq	a0,s9,80004174 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004114:	8526                	mv	a0,s1
    80004116:	00000097          	auipc	ra,0x0
    8000411a:	790080e7          	jalr	1936(ra) # 800048a6 <log_write>
    brelse(bp);
    8000411e:	8526                	mv	a0,s1
    80004120:	fffff097          	auipc	ra,0xfffff
    80004124:	50a080e7          	jalr	1290(ra) # 8000362a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004128:	01498a3b          	addw	s4,s3,s4
    8000412c:	0129893b          	addw	s2,s3,s2
    80004130:	9aee                	add	s5,s5,s11
    80004132:	057a7663          	bgeu	s4,s7,8000417e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004136:	000b2483          	lw	s1,0(s6)
    8000413a:	00a9559b          	srliw	a1,s2,0xa
    8000413e:	855a                	mv	a0,s6
    80004140:	fffff097          	auipc	ra,0xfffff
    80004144:	7ae080e7          	jalr	1966(ra) # 800038ee <bmap>
    80004148:	0005059b          	sext.w	a1,a0
    8000414c:	8526                	mv	a0,s1
    8000414e:	fffff097          	auipc	ra,0xfffff
    80004152:	3ac080e7          	jalr	940(ra) # 800034fa <bread>
    80004156:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004158:	3ff97713          	andi	a4,s2,1023
    8000415c:	40ed07bb          	subw	a5,s10,a4
    80004160:	414b86bb          	subw	a3,s7,s4
    80004164:	89be                	mv	s3,a5
    80004166:	2781                	sext.w	a5,a5
    80004168:	0006861b          	sext.w	a2,a3
    8000416c:	f8f674e3          	bgeu	a2,a5,800040f4 <writei+0x4c>
    80004170:	89b6                	mv	s3,a3
    80004172:	b749                	j	800040f4 <writei+0x4c>
      brelse(bp);
    80004174:	8526                	mv	a0,s1
    80004176:	fffff097          	auipc	ra,0xfffff
    8000417a:	4b4080e7          	jalr	1204(ra) # 8000362a <brelse>
  }

  if(off > ip->size)
    8000417e:	04cb2783          	lw	a5,76(s6)
    80004182:	0127f463          	bgeu	a5,s2,8000418a <writei+0xe2>
    ip->size = off;
    80004186:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000418a:	855a                	mv	a0,s6
    8000418c:	00000097          	auipc	ra,0x0
    80004190:	aa6080e7          	jalr	-1370(ra) # 80003c32 <iupdate>

  return tot;
    80004194:	000a051b          	sext.w	a0,s4
}
    80004198:	70a6                	ld	ra,104(sp)
    8000419a:	7406                	ld	s0,96(sp)
    8000419c:	64e6                	ld	s1,88(sp)
    8000419e:	6946                	ld	s2,80(sp)
    800041a0:	69a6                	ld	s3,72(sp)
    800041a2:	6a06                	ld	s4,64(sp)
    800041a4:	7ae2                	ld	s5,56(sp)
    800041a6:	7b42                	ld	s6,48(sp)
    800041a8:	7ba2                	ld	s7,40(sp)
    800041aa:	7c02                	ld	s8,32(sp)
    800041ac:	6ce2                	ld	s9,24(sp)
    800041ae:	6d42                	ld	s10,16(sp)
    800041b0:	6da2                	ld	s11,8(sp)
    800041b2:	6165                	addi	sp,sp,112
    800041b4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041b6:	8a5e                	mv	s4,s7
    800041b8:	bfc9                	j	8000418a <writei+0xe2>
    return -1;
    800041ba:	557d                	li	a0,-1
}
    800041bc:	8082                	ret
    return -1;
    800041be:	557d                	li	a0,-1
    800041c0:	bfe1                	j	80004198 <writei+0xf0>
    return -1;
    800041c2:	557d                	li	a0,-1
    800041c4:	bfd1                	j	80004198 <writei+0xf0>

00000000800041c6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041c6:	1141                	addi	sp,sp,-16
    800041c8:	e406                	sd	ra,8(sp)
    800041ca:	e022                	sd	s0,0(sp)
    800041cc:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800041ce:	4639                	li	a2,14
    800041d0:	ffffd097          	auipc	ra,0xffffd
    800041d4:	be8080e7          	jalr	-1048(ra) # 80000db8 <strncmp>
}
    800041d8:	60a2                	ld	ra,8(sp)
    800041da:	6402                	ld	s0,0(sp)
    800041dc:	0141                	addi	sp,sp,16
    800041de:	8082                	ret

00000000800041e0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800041e0:	7139                	addi	sp,sp,-64
    800041e2:	fc06                	sd	ra,56(sp)
    800041e4:	f822                	sd	s0,48(sp)
    800041e6:	f426                	sd	s1,40(sp)
    800041e8:	f04a                	sd	s2,32(sp)
    800041ea:	ec4e                	sd	s3,24(sp)
    800041ec:	e852                	sd	s4,16(sp)
    800041ee:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800041f0:	04451703          	lh	a4,68(a0)
    800041f4:	4785                	li	a5,1
    800041f6:	00f71a63          	bne	a4,a5,8000420a <dirlookup+0x2a>
    800041fa:	892a                	mv	s2,a0
    800041fc:	89ae                	mv	s3,a1
    800041fe:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004200:	457c                	lw	a5,76(a0)
    80004202:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004204:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004206:	e79d                	bnez	a5,80004234 <dirlookup+0x54>
    80004208:	a8a5                	j	80004280 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000420a:	00004517          	auipc	a0,0x4
    8000420e:	48650513          	addi	a0,a0,1158 # 80008690 <syscalls+0x1a0>
    80004212:	ffffc097          	auipc	ra,0xffffc
    80004216:	32c080e7          	jalr	812(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000421a:	00004517          	auipc	a0,0x4
    8000421e:	48e50513          	addi	a0,a0,1166 # 800086a8 <syscalls+0x1b8>
    80004222:	ffffc097          	auipc	ra,0xffffc
    80004226:	31c080e7          	jalr	796(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000422a:	24c1                	addiw	s1,s1,16
    8000422c:	04c92783          	lw	a5,76(s2)
    80004230:	04f4f763          	bgeu	s1,a5,8000427e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004234:	4741                	li	a4,16
    80004236:	86a6                	mv	a3,s1
    80004238:	fc040613          	addi	a2,s0,-64
    8000423c:	4581                	li	a1,0
    8000423e:	854a                	mv	a0,s2
    80004240:	00000097          	auipc	ra,0x0
    80004244:	d70080e7          	jalr	-656(ra) # 80003fb0 <readi>
    80004248:	47c1                	li	a5,16
    8000424a:	fcf518e3          	bne	a0,a5,8000421a <dirlookup+0x3a>
    if(de.inum == 0)
    8000424e:	fc045783          	lhu	a5,-64(s0)
    80004252:	dfe1                	beqz	a5,8000422a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004254:	fc240593          	addi	a1,s0,-62
    80004258:	854e                	mv	a0,s3
    8000425a:	00000097          	auipc	ra,0x0
    8000425e:	f6c080e7          	jalr	-148(ra) # 800041c6 <namecmp>
    80004262:	f561                	bnez	a0,8000422a <dirlookup+0x4a>
      if(poff)
    80004264:	000a0463          	beqz	s4,8000426c <dirlookup+0x8c>
        *poff = off;
    80004268:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000426c:	fc045583          	lhu	a1,-64(s0)
    80004270:	00092503          	lw	a0,0(s2)
    80004274:	fffff097          	auipc	ra,0xfffff
    80004278:	754080e7          	jalr	1876(ra) # 800039c8 <iget>
    8000427c:	a011                	j	80004280 <dirlookup+0xa0>
  return 0;
    8000427e:	4501                	li	a0,0
}
    80004280:	70e2                	ld	ra,56(sp)
    80004282:	7442                	ld	s0,48(sp)
    80004284:	74a2                	ld	s1,40(sp)
    80004286:	7902                	ld	s2,32(sp)
    80004288:	69e2                	ld	s3,24(sp)
    8000428a:	6a42                	ld	s4,16(sp)
    8000428c:	6121                	addi	sp,sp,64
    8000428e:	8082                	ret

0000000080004290 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004290:	711d                	addi	sp,sp,-96
    80004292:	ec86                	sd	ra,88(sp)
    80004294:	e8a2                	sd	s0,80(sp)
    80004296:	e4a6                	sd	s1,72(sp)
    80004298:	e0ca                	sd	s2,64(sp)
    8000429a:	fc4e                	sd	s3,56(sp)
    8000429c:	f852                	sd	s4,48(sp)
    8000429e:	f456                	sd	s5,40(sp)
    800042a0:	f05a                	sd	s6,32(sp)
    800042a2:	ec5e                	sd	s7,24(sp)
    800042a4:	e862                	sd	s8,16(sp)
    800042a6:	e466                	sd	s9,8(sp)
    800042a8:	1080                	addi	s0,sp,96
    800042aa:	84aa                	mv	s1,a0
    800042ac:	8b2e                	mv	s6,a1
    800042ae:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800042b0:	00054703          	lbu	a4,0(a0)
    800042b4:	02f00793          	li	a5,47
    800042b8:	02f70363          	beq	a4,a5,800042de <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042bc:	ffffe097          	auipc	ra,0xffffe
    800042c0:	b44080e7          	jalr	-1212(ra) # 80001e00 <myproc>
    800042c4:	15053503          	ld	a0,336(a0)
    800042c8:	00000097          	auipc	ra,0x0
    800042cc:	9f6080e7          	jalr	-1546(ra) # 80003cbe <idup>
    800042d0:	89aa                	mv	s3,a0
  while(*path == '/')
    800042d2:	02f00913          	li	s2,47
  len = path - s;
    800042d6:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800042d8:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800042da:	4c05                	li	s8,1
    800042dc:	a865                	j	80004394 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800042de:	4585                	li	a1,1
    800042e0:	4505                	li	a0,1
    800042e2:	fffff097          	auipc	ra,0xfffff
    800042e6:	6e6080e7          	jalr	1766(ra) # 800039c8 <iget>
    800042ea:	89aa                	mv	s3,a0
    800042ec:	b7dd                	j	800042d2 <namex+0x42>
      iunlockput(ip);
    800042ee:	854e                	mv	a0,s3
    800042f0:	00000097          	auipc	ra,0x0
    800042f4:	c6e080e7          	jalr	-914(ra) # 80003f5e <iunlockput>
      return 0;
    800042f8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800042fa:	854e                	mv	a0,s3
    800042fc:	60e6                	ld	ra,88(sp)
    800042fe:	6446                	ld	s0,80(sp)
    80004300:	64a6                	ld	s1,72(sp)
    80004302:	6906                	ld	s2,64(sp)
    80004304:	79e2                	ld	s3,56(sp)
    80004306:	7a42                	ld	s4,48(sp)
    80004308:	7aa2                	ld	s5,40(sp)
    8000430a:	7b02                	ld	s6,32(sp)
    8000430c:	6be2                	ld	s7,24(sp)
    8000430e:	6c42                	ld	s8,16(sp)
    80004310:	6ca2                	ld	s9,8(sp)
    80004312:	6125                	addi	sp,sp,96
    80004314:	8082                	ret
      iunlock(ip);
    80004316:	854e                	mv	a0,s3
    80004318:	00000097          	auipc	ra,0x0
    8000431c:	aa6080e7          	jalr	-1370(ra) # 80003dbe <iunlock>
      return ip;
    80004320:	bfe9                	j	800042fa <namex+0x6a>
      iunlockput(ip);
    80004322:	854e                	mv	a0,s3
    80004324:	00000097          	auipc	ra,0x0
    80004328:	c3a080e7          	jalr	-966(ra) # 80003f5e <iunlockput>
      return 0;
    8000432c:	89d2                	mv	s3,s4
    8000432e:	b7f1                	j	800042fa <namex+0x6a>
  len = path - s;
    80004330:	40b48633          	sub	a2,s1,a1
    80004334:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004338:	094cd463          	bge	s9,s4,800043c0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000433c:	4639                	li	a2,14
    8000433e:	8556                	mv	a0,s5
    80004340:	ffffd097          	auipc	ra,0xffffd
    80004344:	a00080e7          	jalr	-1536(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004348:	0004c783          	lbu	a5,0(s1)
    8000434c:	01279763          	bne	a5,s2,8000435a <namex+0xca>
    path++;
    80004350:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004352:	0004c783          	lbu	a5,0(s1)
    80004356:	ff278de3          	beq	a5,s2,80004350 <namex+0xc0>
    ilock(ip);
    8000435a:	854e                	mv	a0,s3
    8000435c:	00000097          	auipc	ra,0x0
    80004360:	9a0080e7          	jalr	-1632(ra) # 80003cfc <ilock>
    if(ip->type != T_DIR){
    80004364:	04499783          	lh	a5,68(s3)
    80004368:	f98793e3          	bne	a5,s8,800042ee <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000436c:	000b0563          	beqz	s6,80004376 <namex+0xe6>
    80004370:	0004c783          	lbu	a5,0(s1)
    80004374:	d3cd                	beqz	a5,80004316 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004376:	865e                	mv	a2,s7
    80004378:	85d6                	mv	a1,s5
    8000437a:	854e                	mv	a0,s3
    8000437c:	00000097          	auipc	ra,0x0
    80004380:	e64080e7          	jalr	-412(ra) # 800041e0 <dirlookup>
    80004384:	8a2a                	mv	s4,a0
    80004386:	dd51                	beqz	a0,80004322 <namex+0x92>
    iunlockput(ip);
    80004388:	854e                	mv	a0,s3
    8000438a:	00000097          	auipc	ra,0x0
    8000438e:	bd4080e7          	jalr	-1068(ra) # 80003f5e <iunlockput>
    ip = next;
    80004392:	89d2                	mv	s3,s4
  while(*path == '/')
    80004394:	0004c783          	lbu	a5,0(s1)
    80004398:	05279763          	bne	a5,s2,800043e6 <namex+0x156>
    path++;
    8000439c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000439e:	0004c783          	lbu	a5,0(s1)
    800043a2:	ff278de3          	beq	a5,s2,8000439c <namex+0x10c>
  if(*path == 0)
    800043a6:	c79d                	beqz	a5,800043d4 <namex+0x144>
    path++;
    800043a8:	85a6                	mv	a1,s1
  len = path - s;
    800043aa:	8a5e                	mv	s4,s7
    800043ac:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800043ae:	01278963          	beq	a5,s2,800043c0 <namex+0x130>
    800043b2:	dfbd                	beqz	a5,80004330 <namex+0xa0>
    path++;
    800043b4:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800043b6:	0004c783          	lbu	a5,0(s1)
    800043ba:	ff279ce3          	bne	a5,s2,800043b2 <namex+0x122>
    800043be:	bf8d                	j	80004330 <namex+0xa0>
    memmove(name, s, len);
    800043c0:	2601                	sext.w	a2,a2
    800043c2:	8556                	mv	a0,s5
    800043c4:	ffffd097          	auipc	ra,0xffffd
    800043c8:	97c080e7          	jalr	-1668(ra) # 80000d40 <memmove>
    name[len] = 0;
    800043cc:	9a56                	add	s4,s4,s5
    800043ce:	000a0023          	sb	zero,0(s4)
    800043d2:	bf9d                	j	80004348 <namex+0xb8>
  if(nameiparent){
    800043d4:	f20b03e3          	beqz	s6,800042fa <namex+0x6a>
    iput(ip);
    800043d8:	854e                	mv	a0,s3
    800043da:	00000097          	auipc	ra,0x0
    800043de:	adc080e7          	jalr	-1316(ra) # 80003eb6 <iput>
    return 0;
    800043e2:	4981                	li	s3,0
    800043e4:	bf19                	j	800042fa <namex+0x6a>
  if(*path == 0)
    800043e6:	d7fd                	beqz	a5,800043d4 <namex+0x144>
  while(*path != '/' && *path != 0)
    800043e8:	0004c783          	lbu	a5,0(s1)
    800043ec:	85a6                	mv	a1,s1
    800043ee:	b7d1                	j	800043b2 <namex+0x122>

00000000800043f0 <dirlink>:
{
    800043f0:	7139                	addi	sp,sp,-64
    800043f2:	fc06                	sd	ra,56(sp)
    800043f4:	f822                	sd	s0,48(sp)
    800043f6:	f426                	sd	s1,40(sp)
    800043f8:	f04a                	sd	s2,32(sp)
    800043fa:	ec4e                	sd	s3,24(sp)
    800043fc:	e852                	sd	s4,16(sp)
    800043fe:	0080                	addi	s0,sp,64
    80004400:	892a                	mv	s2,a0
    80004402:	8a2e                	mv	s4,a1
    80004404:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004406:	4601                	li	a2,0
    80004408:	00000097          	auipc	ra,0x0
    8000440c:	dd8080e7          	jalr	-552(ra) # 800041e0 <dirlookup>
    80004410:	e93d                	bnez	a0,80004486 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004412:	04c92483          	lw	s1,76(s2)
    80004416:	c49d                	beqz	s1,80004444 <dirlink+0x54>
    80004418:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000441a:	4741                	li	a4,16
    8000441c:	86a6                	mv	a3,s1
    8000441e:	fc040613          	addi	a2,s0,-64
    80004422:	4581                	li	a1,0
    80004424:	854a                	mv	a0,s2
    80004426:	00000097          	auipc	ra,0x0
    8000442a:	b8a080e7          	jalr	-1142(ra) # 80003fb0 <readi>
    8000442e:	47c1                	li	a5,16
    80004430:	06f51163          	bne	a0,a5,80004492 <dirlink+0xa2>
    if(de.inum == 0)
    80004434:	fc045783          	lhu	a5,-64(s0)
    80004438:	c791                	beqz	a5,80004444 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000443a:	24c1                	addiw	s1,s1,16
    8000443c:	04c92783          	lw	a5,76(s2)
    80004440:	fcf4ede3          	bltu	s1,a5,8000441a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004444:	4639                	li	a2,14
    80004446:	85d2                	mv	a1,s4
    80004448:	fc240513          	addi	a0,s0,-62
    8000444c:	ffffd097          	auipc	ra,0xffffd
    80004450:	9a8080e7          	jalr	-1624(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004454:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004458:	4741                	li	a4,16
    8000445a:	86a6                	mv	a3,s1
    8000445c:	fc040613          	addi	a2,s0,-64
    80004460:	4581                	li	a1,0
    80004462:	854a                	mv	a0,s2
    80004464:	00000097          	auipc	ra,0x0
    80004468:	c44080e7          	jalr	-956(ra) # 800040a8 <writei>
    8000446c:	872a                	mv	a4,a0
    8000446e:	47c1                	li	a5,16
  return 0;
    80004470:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004472:	02f71863          	bne	a4,a5,800044a2 <dirlink+0xb2>
}
    80004476:	70e2                	ld	ra,56(sp)
    80004478:	7442                	ld	s0,48(sp)
    8000447a:	74a2                	ld	s1,40(sp)
    8000447c:	7902                	ld	s2,32(sp)
    8000447e:	69e2                	ld	s3,24(sp)
    80004480:	6a42                	ld	s4,16(sp)
    80004482:	6121                	addi	sp,sp,64
    80004484:	8082                	ret
    iput(ip);
    80004486:	00000097          	auipc	ra,0x0
    8000448a:	a30080e7          	jalr	-1488(ra) # 80003eb6 <iput>
    return -1;
    8000448e:	557d                	li	a0,-1
    80004490:	b7dd                	j	80004476 <dirlink+0x86>
      panic("dirlink read");
    80004492:	00004517          	auipc	a0,0x4
    80004496:	22650513          	addi	a0,a0,550 # 800086b8 <syscalls+0x1c8>
    8000449a:	ffffc097          	auipc	ra,0xffffc
    8000449e:	0a4080e7          	jalr	164(ra) # 8000053e <panic>
    panic("dirlink");
    800044a2:	00004517          	auipc	a0,0x4
    800044a6:	32650513          	addi	a0,a0,806 # 800087c8 <syscalls+0x2d8>
    800044aa:	ffffc097          	auipc	ra,0xffffc
    800044ae:	094080e7          	jalr	148(ra) # 8000053e <panic>

00000000800044b2 <namei>:

struct inode*
namei(char *path)
{
    800044b2:	1101                	addi	sp,sp,-32
    800044b4:	ec06                	sd	ra,24(sp)
    800044b6:	e822                	sd	s0,16(sp)
    800044b8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800044ba:	fe040613          	addi	a2,s0,-32
    800044be:	4581                	li	a1,0
    800044c0:	00000097          	auipc	ra,0x0
    800044c4:	dd0080e7          	jalr	-560(ra) # 80004290 <namex>
}
    800044c8:	60e2                	ld	ra,24(sp)
    800044ca:	6442                	ld	s0,16(sp)
    800044cc:	6105                	addi	sp,sp,32
    800044ce:	8082                	ret

00000000800044d0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044d0:	1141                	addi	sp,sp,-16
    800044d2:	e406                	sd	ra,8(sp)
    800044d4:	e022                	sd	s0,0(sp)
    800044d6:	0800                	addi	s0,sp,16
    800044d8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800044da:	4585                	li	a1,1
    800044dc:	00000097          	auipc	ra,0x0
    800044e0:	db4080e7          	jalr	-588(ra) # 80004290 <namex>
}
    800044e4:	60a2                	ld	ra,8(sp)
    800044e6:	6402                	ld	s0,0(sp)
    800044e8:	0141                	addi	sp,sp,16
    800044ea:	8082                	ret

00000000800044ec <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800044ec:	1101                	addi	sp,sp,-32
    800044ee:	ec06                	sd	ra,24(sp)
    800044f0:	e822                	sd	s0,16(sp)
    800044f2:	e426                	sd	s1,8(sp)
    800044f4:	e04a                	sd	s2,0(sp)
    800044f6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800044f8:	0001e917          	auipc	s2,0x1e
    800044fc:	8b890913          	addi	s2,s2,-1864 # 80021db0 <log>
    80004500:	01892583          	lw	a1,24(s2)
    80004504:	02892503          	lw	a0,40(s2)
    80004508:	fffff097          	auipc	ra,0xfffff
    8000450c:	ff2080e7          	jalr	-14(ra) # 800034fa <bread>
    80004510:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004512:	02c92683          	lw	a3,44(s2)
    80004516:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004518:	02d05763          	blez	a3,80004546 <write_head+0x5a>
    8000451c:	0001e797          	auipc	a5,0x1e
    80004520:	8c478793          	addi	a5,a5,-1852 # 80021de0 <log+0x30>
    80004524:	05c50713          	addi	a4,a0,92
    80004528:	36fd                	addiw	a3,a3,-1
    8000452a:	1682                	slli	a3,a3,0x20
    8000452c:	9281                	srli	a3,a3,0x20
    8000452e:	068a                	slli	a3,a3,0x2
    80004530:	0001e617          	auipc	a2,0x1e
    80004534:	8b460613          	addi	a2,a2,-1868 # 80021de4 <log+0x34>
    80004538:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000453a:	4390                	lw	a2,0(a5)
    8000453c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000453e:	0791                	addi	a5,a5,4
    80004540:	0711                	addi	a4,a4,4
    80004542:	fed79ce3          	bne	a5,a3,8000453a <write_head+0x4e>
  }
  bwrite(buf);
    80004546:	8526                	mv	a0,s1
    80004548:	fffff097          	auipc	ra,0xfffff
    8000454c:	0a4080e7          	jalr	164(ra) # 800035ec <bwrite>
  brelse(buf);
    80004550:	8526                	mv	a0,s1
    80004552:	fffff097          	auipc	ra,0xfffff
    80004556:	0d8080e7          	jalr	216(ra) # 8000362a <brelse>
}
    8000455a:	60e2                	ld	ra,24(sp)
    8000455c:	6442                	ld	s0,16(sp)
    8000455e:	64a2                	ld	s1,8(sp)
    80004560:	6902                	ld	s2,0(sp)
    80004562:	6105                	addi	sp,sp,32
    80004564:	8082                	ret

0000000080004566 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004566:	0001e797          	auipc	a5,0x1e
    8000456a:	8767a783          	lw	a5,-1930(a5) # 80021ddc <log+0x2c>
    8000456e:	0af05d63          	blez	a5,80004628 <install_trans+0xc2>
{
    80004572:	7139                	addi	sp,sp,-64
    80004574:	fc06                	sd	ra,56(sp)
    80004576:	f822                	sd	s0,48(sp)
    80004578:	f426                	sd	s1,40(sp)
    8000457a:	f04a                	sd	s2,32(sp)
    8000457c:	ec4e                	sd	s3,24(sp)
    8000457e:	e852                	sd	s4,16(sp)
    80004580:	e456                	sd	s5,8(sp)
    80004582:	e05a                	sd	s6,0(sp)
    80004584:	0080                	addi	s0,sp,64
    80004586:	8b2a                	mv	s6,a0
    80004588:	0001ea97          	auipc	s5,0x1e
    8000458c:	858a8a93          	addi	s5,s5,-1960 # 80021de0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004590:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004592:	0001e997          	auipc	s3,0x1e
    80004596:	81e98993          	addi	s3,s3,-2018 # 80021db0 <log>
    8000459a:	a035                	j	800045c6 <install_trans+0x60>
      bunpin(dbuf);
    8000459c:	8526                	mv	a0,s1
    8000459e:	fffff097          	auipc	ra,0xfffff
    800045a2:	166080e7          	jalr	358(ra) # 80003704 <bunpin>
    brelse(lbuf);
    800045a6:	854a                	mv	a0,s2
    800045a8:	fffff097          	auipc	ra,0xfffff
    800045ac:	082080e7          	jalr	130(ra) # 8000362a <brelse>
    brelse(dbuf);
    800045b0:	8526                	mv	a0,s1
    800045b2:	fffff097          	auipc	ra,0xfffff
    800045b6:	078080e7          	jalr	120(ra) # 8000362a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045ba:	2a05                	addiw	s4,s4,1
    800045bc:	0a91                	addi	s5,s5,4
    800045be:	02c9a783          	lw	a5,44(s3)
    800045c2:	04fa5963          	bge	s4,a5,80004614 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045c6:	0189a583          	lw	a1,24(s3)
    800045ca:	014585bb          	addw	a1,a1,s4
    800045ce:	2585                	addiw	a1,a1,1
    800045d0:	0289a503          	lw	a0,40(s3)
    800045d4:	fffff097          	auipc	ra,0xfffff
    800045d8:	f26080e7          	jalr	-218(ra) # 800034fa <bread>
    800045dc:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045de:	000aa583          	lw	a1,0(s5)
    800045e2:	0289a503          	lw	a0,40(s3)
    800045e6:	fffff097          	auipc	ra,0xfffff
    800045ea:	f14080e7          	jalr	-236(ra) # 800034fa <bread>
    800045ee:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800045f0:	40000613          	li	a2,1024
    800045f4:	05890593          	addi	a1,s2,88
    800045f8:	05850513          	addi	a0,a0,88
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	744080e7          	jalr	1860(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004604:	8526                	mv	a0,s1
    80004606:	fffff097          	auipc	ra,0xfffff
    8000460a:	fe6080e7          	jalr	-26(ra) # 800035ec <bwrite>
    if(recovering == 0)
    8000460e:	f80b1ce3          	bnez	s6,800045a6 <install_trans+0x40>
    80004612:	b769                	j	8000459c <install_trans+0x36>
}
    80004614:	70e2                	ld	ra,56(sp)
    80004616:	7442                	ld	s0,48(sp)
    80004618:	74a2                	ld	s1,40(sp)
    8000461a:	7902                	ld	s2,32(sp)
    8000461c:	69e2                	ld	s3,24(sp)
    8000461e:	6a42                	ld	s4,16(sp)
    80004620:	6aa2                	ld	s5,8(sp)
    80004622:	6b02                	ld	s6,0(sp)
    80004624:	6121                	addi	sp,sp,64
    80004626:	8082                	ret
    80004628:	8082                	ret

000000008000462a <initlog>:
{
    8000462a:	7179                	addi	sp,sp,-48
    8000462c:	f406                	sd	ra,40(sp)
    8000462e:	f022                	sd	s0,32(sp)
    80004630:	ec26                	sd	s1,24(sp)
    80004632:	e84a                	sd	s2,16(sp)
    80004634:	e44e                	sd	s3,8(sp)
    80004636:	1800                	addi	s0,sp,48
    80004638:	892a                	mv	s2,a0
    8000463a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000463c:	0001d497          	auipc	s1,0x1d
    80004640:	77448493          	addi	s1,s1,1908 # 80021db0 <log>
    80004644:	00004597          	auipc	a1,0x4
    80004648:	08458593          	addi	a1,a1,132 # 800086c8 <syscalls+0x1d8>
    8000464c:	8526                	mv	a0,s1
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	506080e7          	jalr	1286(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004656:	0149a583          	lw	a1,20(s3)
    8000465a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000465c:	0109a783          	lw	a5,16(s3)
    80004660:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004662:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004666:	854a                	mv	a0,s2
    80004668:	fffff097          	auipc	ra,0xfffff
    8000466c:	e92080e7          	jalr	-366(ra) # 800034fa <bread>
  log.lh.n = lh->n;
    80004670:	4d3c                	lw	a5,88(a0)
    80004672:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004674:	02f05563          	blez	a5,8000469e <initlog+0x74>
    80004678:	05c50713          	addi	a4,a0,92
    8000467c:	0001d697          	auipc	a3,0x1d
    80004680:	76468693          	addi	a3,a3,1892 # 80021de0 <log+0x30>
    80004684:	37fd                	addiw	a5,a5,-1
    80004686:	1782                	slli	a5,a5,0x20
    80004688:	9381                	srli	a5,a5,0x20
    8000468a:	078a                	slli	a5,a5,0x2
    8000468c:	06050613          	addi	a2,a0,96
    80004690:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004692:	4310                	lw	a2,0(a4)
    80004694:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004696:	0711                	addi	a4,a4,4
    80004698:	0691                	addi	a3,a3,4
    8000469a:	fef71ce3          	bne	a4,a5,80004692 <initlog+0x68>
  brelse(buf);
    8000469e:	fffff097          	auipc	ra,0xfffff
    800046a2:	f8c080e7          	jalr	-116(ra) # 8000362a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046a6:	4505                	li	a0,1
    800046a8:	00000097          	auipc	ra,0x0
    800046ac:	ebe080e7          	jalr	-322(ra) # 80004566 <install_trans>
  log.lh.n = 0;
    800046b0:	0001d797          	auipc	a5,0x1d
    800046b4:	7207a623          	sw	zero,1836(a5) # 80021ddc <log+0x2c>
  write_head(); // clear the log
    800046b8:	00000097          	auipc	ra,0x0
    800046bc:	e34080e7          	jalr	-460(ra) # 800044ec <write_head>
}
    800046c0:	70a2                	ld	ra,40(sp)
    800046c2:	7402                	ld	s0,32(sp)
    800046c4:	64e2                	ld	s1,24(sp)
    800046c6:	6942                	ld	s2,16(sp)
    800046c8:	69a2                	ld	s3,8(sp)
    800046ca:	6145                	addi	sp,sp,48
    800046cc:	8082                	ret

00000000800046ce <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800046ce:	1101                	addi	sp,sp,-32
    800046d0:	ec06                	sd	ra,24(sp)
    800046d2:	e822                	sd	s0,16(sp)
    800046d4:	e426                	sd	s1,8(sp)
    800046d6:	e04a                	sd	s2,0(sp)
    800046d8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800046da:	0001d517          	auipc	a0,0x1d
    800046de:	6d650513          	addi	a0,a0,1750 # 80021db0 <log>
    800046e2:	ffffc097          	auipc	ra,0xffffc
    800046e6:	502080e7          	jalr	1282(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800046ea:	0001d497          	auipc	s1,0x1d
    800046ee:	6c648493          	addi	s1,s1,1734 # 80021db0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046f2:	4979                	li	s2,30
    800046f4:	a039                	j	80004702 <begin_op+0x34>
      sleep(&log, &log.lock);
    800046f6:	85a6                	mv	a1,s1
    800046f8:	8526                	mv	a0,s1
    800046fa:	ffffe097          	auipc	ra,0xffffe
    800046fe:	f1a080e7          	jalr	-230(ra) # 80002614 <sleep>
    if(log.committing){
    80004702:	50dc                	lw	a5,36(s1)
    80004704:	fbed                	bnez	a5,800046f6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004706:	509c                	lw	a5,32(s1)
    80004708:	0017871b          	addiw	a4,a5,1
    8000470c:	0007069b          	sext.w	a3,a4
    80004710:	0027179b          	slliw	a5,a4,0x2
    80004714:	9fb9                	addw	a5,a5,a4
    80004716:	0017979b          	slliw	a5,a5,0x1
    8000471a:	54d8                	lw	a4,44(s1)
    8000471c:	9fb9                	addw	a5,a5,a4
    8000471e:	00f95963          	bge	s2,a5,80004730 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004722:	85a6                	mv	a1,s1
    80004724:	8526                	mv	a0,s1
    80004726:	ffffe097          	auipc	ra,0xffffe
    8000472a:	eee080e7          	jalr	-274(ra) # 80002614 <sleep>
    8000472e:	bfd1                	j	80004702 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004730:	0001d517          	auipc	a0,0x1d
    80004734:	68050513          	addi	a0,a0,1664 # 80021db0 <log>
    80004738:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000473a:	ffffc097          	auipc	ra,0xffffc
    8000473e:	55e080e7          	jalr	1374(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004742:	60e2                	ld	ra,24(sp)
    80004744:	6442                	ld	s0,16(sp)
    80004746:	64a2                	ld	s1,8(sp)
    80004748:	6902                	ld	s2,0(sp)
    8000474a:	6105                	addi	sp,sp,32
    8000474c:	8082                	ret

000000008000474e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000474e:	7139                	addi	sp,sp,-64
    80004750:	fc06                	sd	ra,56(sp)
    80004752:	f822                	sd	s0,48(sp)
    80004754:	f426                	sd	s1,40(sp)
    80004756:	f04a                	sd	s2,32(sp)
    80004758:	ec4e                	sd	s3,24(sp)
    8000475a:	e852                	sd	s4,16(sp)
    8000475c:	e456                	sd	s5,8(sp)
    8000475e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004760:	0001d497          	auipc	s1,0x1d
    80004764:	65048493          	addi	s1,s1,1616 # 80021db0 <log>
    80004768:	8526                	mv	a0,s1
    8000476a:	ffffc097          	auipc	ra,0xffffc
    8000476e:	47a080e7          	jalr	1146(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004772:	509c                	lw	a5,32(s1)
    80004774:	37fd                	addiw	a5,a5,-1
    80004776:	0007891b          	sext.w	s2,a5
    8000477a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000477c:	50dc                	lw	a5,36(s1)
    8000477e:	efb9                	bnez	a5,800047dc <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004780:	06091663          	bnez	s2,800047ec <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004784:	0001d497          	auipc	s1,0x1d
    80004788:	62c48493          	addi	s1,s1,1580 # 80021db0 <log>
    8000478c:	4785                	li	a5,1
    8000478e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004790:	8526                	mv	a0,s1
    80004792:	ffffc097          	auipc	ra,0xffffc
    80004796:	506080e7          	jalr	1286(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000479a:	54dc                	lw	a5,44(s1)
    8000479c:	06f04763          	bgtz	a5,8000480a <end_op+0xbc>
    acquire(&log.lock);
    800047a0:	0001d497          	auipc	s1,0x1d
    800047a4:	61048493          	addi	s1,s1,1552 # 80021db0 <log>
    800047a8:	8526                	mv	a0,s1
    800047aa:	ffffc097          	auipc	ra,0xffffc
    800047ae:	43a080e7          	jalr	1082(ra) # 80000be4 <acquire>
    log.committing = 0;
    800047b2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800047b6:	8526                	mv	a0,s1
    800047b8:	ffffe097          	auipc	ra,0xffffe
    800047bc:	ffa080e7          	jalr	-6(ra) # 800027b2 <wakeup>
    release(&log.lock);
    800047c0:	8526                	mv	a0,s1
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	4d6080e7          	jalr	1238(ra) # 80000c98 <release>
}
    800047ca:	70e2                	ld	ra,56(sp)
    800047cc:	7442                	ld	s0,48(sp)
    800047ce:	74a2                	ld	s1,40(sp)
    800047d0:	7902                	ld	s2,32(sp)
    800047d2:	69e2                	ld	s3,24(sp)
    800047d4:	6a42                	ld	s4,16(sp)
    800047d6:	6aa2                	ld	s5,8(sp)
    800047d8:	6121                	addi	sp,sp,64
    800047da:	8082                	ret
    panic("log.committing");
    800047dc:	00004517          	auipc	a0,0x4
    800047e0:	ef450513          	addi	a0,a0,-268 # 800086d0 <syscalls+0x1e0>
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	d5a080e7          	jalr	-678(ra) # 8000053e <panic>
    wakeup(&log);
    800047ec:	0001d497          	auipc	s1,0x1d
    800047f0:	5c448493          	addi	s1,s1,1476 # 80021db0 <log>
    800047f4:	8526                	mv	a0,s1
    800047f6:	ffffe097          	auipc	ra,0xffffe
    800047fa:	fbc080e7          	jalr	-68(ra) # 800027b2 <wakeup>
  release(&log.lock);
    800047fe:	8526                	mv	a0,s1
    80004800:	ffffc097          	auipc	ra,0xffffc
    80004804:	498080e7          	jalr	1176(ra) # 80000c98 <release>
  if(do_commit){
    80004808:	b7c9                	j	800047ca <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000480a:	0001da97          	auipc	s5,0x1d
    8000480e:	5d6a8a93          	addi	s5,s5,1494 # 80021de0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004812:	0001da17          	auipc	s4,0x1d
    80004816:	59ea0a13          	addi	s4,s4,1438 # 80021db0 <log>
    8000481a:	018a2583          	lw	a1,24(s4)
    8000481e:	012585bb          	addw	a1,a1,s2
    80004822:	2585                	addiw	a1,a1,1
    80004824:	028a2503          	lw	a0,40(s4)
    80004828:	fffff097          	auipc	ra,0xfffff
    8000482c:	cd2080e7          	jalr	-814(ra) # 800034fa <bread>
    80004830:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004832:	000aa583          	lw	a1,0(s5)
    80004836:	028a2503          	lw	a0,40(s4)
    8000483a:	fffff097          	auipc	ra,0xfffff
    8000483e:	cc0080e7          	jalr	-832(ra) # 800034fa <bread>
    80004842:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004844:	40000613          	li	a2,1024
    80004848:	05850593          	addi	a1,a0,88
    8000484c:	05848513          	addi	a0,s1,88
    80004850:	ffffc097          	auipc	ra,0xffffc
    80004854:	4f0080e7          	jalr	1264(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004858:	8526                	mv	a0,s1
    8000485a:	fffff097          	auipc	ra,0xfffff
    8000485e:	d92080e7          	jalr	-622(ra) # 800035ec <bwrite>
    brelse(from);
    80004862:	854e                	mv	a0,s3
    80004864:	fffff097          	auipc	ra,0xfffff
    80004868:	dc6080e7          	jalr	-570(ra) # 8000362a <brelse>
    brelse(to);
    8000486c:	8526                	mv	a0,s1
    8000486e:	fffff097          	auipc	ra,0xfffff
    80004872:	dbc080e7          	jalr	-580(ra) # 8000362a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004876:	2905                	addiw	s2,s2,1
    80004878:	0a91                	addi	s5,s5,4
    8000487a:	02ca2783          	lw	a5,44(s4)
    8000487e:	f8f94ee3          	blt	s2,a5,8000481a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004882:	00000097          	auipc	ra,0x0
    80004886:	c6a080e7          	jalr	-918(ra) # 800044ec <write_head>
    install_trans(0); // Now install writes to home locations
    8000488a:	4501                	li	a0,0
    8000488c:	00000097          	auipc	ra,0x0
    80004890:	cda080e7          	jalr	-806(ra) # 80004566 <install_trans>
    log.lh.n = 0;
    80004894:	0001d797          	auipc	a5,0x1d
    80004898:	5407a423          	sw	zero,1352(a5) # 80021ddc <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000489c:	00000097          	auipc	ra,0x0
    800048a0:	c50080e7          	jalr	-944(ra) # 800044ec <write_head>
    800048a4:	bdf5                	j	800047a0 <end_op+0x52>

00000000800048a6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048a6:	1101                	addi	sp,sp,-32
    800048a8:	ec06                	sd	ra,24(sp)
    800048aa:	e822                	sd	s0,16(sp)
    800048ac:	e426                	sd	s1,8(sp)
    800048ae:	e04a                	sd	s2,0(sp)
    800048b0:	1000                	addi	s0,sp,32
    800048b2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800048b4:	0001d917          	auipc	s2,0x1d
    800048b8:	4fc90913          	addi	s2,s2,1276 # 80021db0 <log>
    800048bc:	854a                	mv	a0,s2
    800048be:	ffffc097          	auipc	ra,0xffffc
    800048c2:	326080e7          	jalr	806(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048c6:	02c92603          	lw	a2,44(s2)
    800048ca:	47f5                	li	a5,29
    800048cc:	06c7c563          	blt	a5,a2,80004936 <log_write+0x90>
    800048d0:	0001d797          	auipc	a5,0x1d
    800048d4:	4fc7a783          	lw	a5,1276(a5) # 80021dcc <log+0x1c>
    800048d8:	37fd                	addiw	a5,a5,-1
    800048da:	04f65e63          	bge	a2,a5,80004936 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800048de:	0001d797          	auipc	a5,0x1d
    800048e2:	4f27a783          	lw	a5,1266(a5) # 80021dd0 <log+0x20>
    800048e6:	06f05063          	blez	a5,80004946 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800048ea:	4781                	li	a5,0
    800048ec:	06c05563          	blez	a2,80004956 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048f0:	44cc                	lw	a1,12(s1)
    800048f2:	0001d717          	auipc	a4,0x1d
    800048f6:	4ee70713          	addi	a4,a4,1262 # 80021de0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800048fa:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048fc:	4314                	lw	a3,0(a4)
    800048fe:	04b68c63          	beq	a3,a1,80004956 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004902:	2785                	addiw	a5,a5,1
    80004904:	0711                	addi	a4,a4,4
    80004906:	fef61be3          	bne	a2,a5,800048fc <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000490a:	0621                	addi	a2,a2,8
    8000490c:	060a                	slli	a2,a2,0x2
    8000490e:	0001d797          	auipc	a5,0x1d
    80004912:	4a278793          	addi	a5,a5,1186 # 80021db0 <log>
    80004916:	963e                	add	a2,a2,a5
    80004918:	44dc                	lw	a5,12(s1)
    8000491a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000491c:	8526                	mv	a0,s1
    8000491e:	fffff097          	auipc	ra,0xfffff
    80004922:	daa080e7          	jalr	-598(ra) # 800036c8 <bpin>
    log.lh.n++;
    80004926:	0001d717          	auipc	a4,0x1d
    8000492a:	48a70713          	addi	a4,a4,1162 # 80021db0 <log>
    8000492e:	575c                	lw	a5,44(a4)
    80004930:	2785                	addiw	a5,a5,1
    80004932:	d75c                	sw	a5,44(a4)
    80004934:	a835                	j	80004970 <log_write+0xca>
    panic("too big a transaction");
    80004936:	00004517          	auipc	a0,0x4
    8000493a:	daa50513          	addi	a0,a0,-598 # 800086e0 <syscalls+0x1f0>
    8000493e:	ffffc097          	auipc	ra,0xffffc
    80004942:	c00080e7          	jalr	-1024(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004946:	00004517          	auipc	a0,0x4
    8000494a:	db250513          	addi	a0,a0,-590 # 800086f8 <syscalls+0x208>
    8000494e:	ffffc097          	auipc	ra,0xffffc
    80004952:	bf0080e7          	jalr	-1040(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004956:	00878713          	addi	a4,a5,8
    8000495a:	00271693          	slli	a3,a4,0x2
    8000495e:	0001d717          	auipc	a4,0x1d
    80004962:	45270713          	addi	a4,a4,1106 # 80021db0 <log>
    80004966:	9736                	add	a4,a4,a3
    80004968:	44d4                	lw	a3,12(s1)
    8000496a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000496c:	faf608e3          	beq	a2,a5,8000491c <log_write+0x76>
  }
  release(&log.lock);
    80004970:	0001d517          	auipc	a0,0x1d
    80004974:	44050513          	addi	a0,a0,1088 # 80021db0 <log>
    80004978:	ffffc097          	auipc	ra,0xffffc
    8000497c:	320080e7          	jalr	800(ra) # 80000c98 <release>
}
    80004980:	60e2                	ld	ra,24(sp)
    80004982:	6442                	ld	s0,16(sp)
    80004984:	64a2                	ld	s1,8(sp)
    80004986:	6902                	ld	s2,0(sp)
    80004988:	6105                	addi	sp,sp,32
    8000498a:	8082                	ret

000000008000498c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000498c:	1101                	addi	sp,sp,-32
    8000498e:	ec06                	sd	ra,24(sp)
    80004990:	e822                	sd	s0,16(sp)
    80004992:	e426                	sd	s1,8(sp)
    80004994:	e04a                	sd	s2,0(sp)
    80004996:	1000                	addi	s0,sp,32
    80004998:	84aa                	mv	s1,a0
    8000499a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000499c:	00004597          	auipc	a1,0x4
    800049a0:	d7c58593          	addi	a1,a1,-644 # 80008718 <syscalls+0x228>
    800049a4:	0521                	addi	a0,a0,8
    800049a6:	ffffc097          	auipc	ra,0xffffc
    800049aa:	1ae080e7          	jalr	430(ra) # 80000b54 <initlock>
  lk->name = name;
    800049ae:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049b2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049b6:	0204a423          	sw	zero,40(s1)
}
    800049ba:	60e2                	ld	ra,24(sp)
    800049bc:	6442                	ld	s0,16(sp)
    800049be:	64a2                	ld	s1,8(sp)
    800049c0:	6902                	ld	s2,0(sp)
    800049c2:	6105                	addi	sp,sp,32
    800049c4:	8082                	ret

00000000800049c6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049c6:	1101                	addi	sp,sp,-32
    800049c8:	ec06                	sd	ra,24(sp)
    800049ca:	e822                	sd	s0,16(sp)
    800049cc:	e426                	sd	s1,8(sp)
    800049ce:	e04a                	sd	s2,0(sp)
    800049d0:	1000                	addi	s0,sp,32
    800049d2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049d4:	00850913          	addi	s2,a0,8
    800049d8:	854a                	mv	a0,s2
    800049da:	ffffc097          	auipc	ra,0xffffc
    800049de:	20a080e7          	jalr	522(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800049e2:	409c                	lw	a5,0(s1)
    800049e4:	cb89                	beqz	a5,800049f6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800049e6:	85ca                	mv	a1,s2
    800049e8:	8526                	mv	a0,s1
    800049ea:	ffffe097          	auipc	ra,0xffffe
    800049ee:	c2a080e7          	jalr	-982(ra) # 80002614 <sleep>
  while (lk->locked) {
    800049f2:	409c                	lw	a5,0(s1)
    800049f4:	fbed                	bnez	a5,800049e6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800049f6:	4785                	li	a5,1
    800049f8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800049fa:	ffffd097          	auipc	ra,0xffffd
    800049fe:	406080e7          	jalr	1030(ra) # 80001e00 <myproc>
    80004a02:	591c                	lw	a5,48(a0)
    80004a04:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a06:	854a                	mv	a0,s2
    80004a08:	ffffc097          	auipc	ra,0xffffc
    80004a0c:	290080e7          	jalr	656(ra) # 80000c98 <release>
}
    80004a10:	60e2                	ld	ra,24(sp)
    80004a12:	6442                	ld	s0,16(sp)
    80004a14:	64a2                	ld	s1,8(sp)
    80004a16:	6902                	ld	s2,0(sp)
    80004a18:	6105                	addi	sp,sp,32
    80004a1a:	8082                	ret

0000000080004a1c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a1c:	1101                	addi	sp,sp,-32
    80004a1e:	ec06                	sd	ra,24(sp)
    80004a20:	e822                	sd	s0,16(sp)
    80004a22:	e426                	sd	s1,8(sp)
    80004a24:	e04a                	sd	s2,0(sp)
    80004a26:	1000                	addi	s0,sp,32
    80004a28:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a2a:	00850913          	addi	s2,a0,8
    80004a2e:	854a                	mv	a0,s2
    80004a30:	ffffc097          	auipc	ra,0xffffc
    80004a34:	1b4080e7          	jalr	436(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004a38:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a3c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a40:	8526                	mv	a0,s1
    80004a42:	ffffe097          	auipc	ra,0xffffe
    80004a46:	d70080e7          	jalr	-656(ra) # 800027b2 <wakeup>
  release(&lk->lk);
    80004a4a:	854a                	mv	a0,s2
    80004a4c:	ffffc097          	auipc	ra,0xffffc
    80004a50:	24c080e7          	jalr	588(ra) # 80000c98 <release>
}
    80004a54:	60e2                	ld	ra,24(sp)
    80004a56:	6442                	ld	s0,16(sp)
    80004a58:	64a2                	ld	s1,8(sp)
    80004a5a:	6902                	ld	s2,0(sp)
    80004a5c:	6105                	addi	sp,sp,32
    80004a5e:	8082                	ret

0000000080004a60 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a60:	7179                	addi	sp,sp,-48
    80004a62:	f406                	sd	ra,40(sp)
    80004a64:	f022                	sd	s0,32(sp)
    80004a66:	ec26                	sd	s1,24(sp)
    80004a68:	e84a                	sd	s2,16(sp)
    80004a6a:	e44e                	sd	s3,8(sp)
    80004a6c:	1800                	addi	s0,sp,48
    80004a6e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a70:	00850913          	addi	s2,a0,8
    80004a74:	854a                	mv	a0,s2
    80004a76:	ffffc097          	auipc	ra,0xffffc
    80004a7a:	16e080e7          	jalr	366(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a7e:	409c                	lw	a5,0(s1)
    80004a80:	ef99                	bnez	a5,80004a9e <holdingsleep+0x3e>
    80004a82:	4481                	li	s1,0
  release(&lk->lk);
    80004a84:	854a                	mv	a0,s2
    80004a86:	ffffc097          	auipc	ra,0xffffc
    80004a8a:	212080e7          	jalr	530(ra) # 80000c98 <release>
  return r;
}
    80004a8e:	8526                	mv	a0,s1
    80004a90:	70a2                	ld	ra,40(sp)
    80004a92:	7402                	ld	s0,32(sp)
    80004a94:	64e2                	ld	s1,24(sp)
    80004a96:	6942                	ld	s2,16(sp)
    80004a98:	69a2                	ld	s3,8(sp)
    80004a9a:	6145                	addi	sp,sp,48
    80004a9c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a9e:	0284a983          	lw	s3,40(s1)
    80004aa2:	ffffd097          	auipc	ra,0xffffd
    80004aa6:	35e080e7          	jalr	862(ra) # 80001e00 <myproc>
    80004aaa:	5904                	lw	s1,48(a0)
    80004aac:	413484b3          	sub	s1,s1,s3
    80004ab0:	0014b493          	seqz	s1,s1
    80004ab4:	bfc1                	j	80004a84 <holdingsleep+0x24>

0000000080004ab6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ab6:	1141                	addi	sp,sp,-16
    80004ab8:	e406                	sd	ra,8(sp)
    80004aba:	e022                	sd	s0,0(sp)
    80004abc:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004abe:	00004597          	auipc	a1,0x4
    80004ac2:	c6a58593          	addi	a1,a1,-918 # 80008728 <syscalls+0x238>
    80004ac6:	0001d517          	auipc	a0,0x1d
    80004aca:	43250513          	addi	a0,a0,1074 # 80021ef8 <ftable>
    80004ace:	ffffc097          	auipc	ra,0xffffc
    80004ad2:	086080e7          	jalr	134(ra) # 80000b54 <initlock>
}
    80004ad6:	60a2                	ld	ra,8(sp)
    80004ad8:	6402                	ld	s0,0(sp)
    80004ada:	0141                	addi	sp,sp,16
    80004adc:	8082                	ret

0000000080004ade <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004ade:	1101                	addi	sp,sp,-32
    80004ae0:	ec06                	sd	ra,24(sp)
    80004ae2:	e822                	sd	s0,16(sp)
    80004ae4:	e426                	sd	s1,8(sp)
    80004ae6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004ae8:	0001d517          	auipc	a0,0x1d
    80004aec:	41050513          	addi	a0,a0,1040 # 80021ef8 <ftable>
    80004af0:	ffffc097          	auipc	ra,0xffffc
    80004af4:	0f4080e7          	jalr	244(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004af8:	0001d497          	auipc	s1,0x1d
    80004afc:	41848493          	addi	s1,s1,1048 # 80021f10 <ftable+0x18>
    80004b00:	0001e717          	auipc	a4,0x1e
    80004b04:	3b070713          	addi	a4,a4,944 # 80022eb0 <ftable+0xfb8>
    if(f->ref == 0){
    80004b08:	40dc                	lw	a5,4(s1)
    80004b0a:	cf99                	beqz	a5,80004b28 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b0c:	02848493          	addi	s1,s1,40
    80004b10:	fee49ce3          	bne	s1,a4,80004b08 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b14:	0001d517          	auipc	a0,0x1d
    80004b18:	3e450513          	addi	a0,a0,996 # 80021ef8 <ftable>
    80004b1c:	ffffc097          	auipc	ra,0xffffc
    80004b20:	17c080e7          	jalr	380(ra) # 80000c98 <release>
  return 0;
    80004b24:	4481                	li	s1,0
    80004b26:	a819                	j	80004b3c <filealloc+0x5e>
      f->ref = 1;
    80004b28:	4785                	li	a5,1
    80004b2a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b2c:	0001d517          	auipc	a0,0x1d
    80004b30:	3cc50513          	addi	a0,a0,972 # 80021ef8 <ftable>
    80004b34:	ffffc097          	auipc	ra,0xffffc
    80004b38:	164080e7          	jalr	356(ra) # 80000c98 <release>
}
    80004b3c:	8526                	mv	a0,s1
    80004b3e:	60e2                	ld	ra,24(sp)
    80004b40:	6442                	ld	s0,16(sp)
    80004b42:	64a2                	ld	s1,8(sp)
    80004b44:	6105                	addi	sp,sp,32
    80004b46:	8082                	ret

0000000080004b48 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b48:	1101                	addi	sp,sp,-32
    80004b4a:	ec06                	sd	ra,24(sp)
    80004b4c:	e822                	sd	s0,16(sp)
    80004b4e:	e426                	sd	s1,8(sp)
    80004b50:	1000                	addi	s0,sp,32
    80004b52:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b54:	0001d517          	auipc	a0,0x1d
    80004b58:	3a450513          	addi	a0,a0,932 # 80021ef8 <ftable>
    80004b5c:	ffffc097          	auipc	ra,0xffffc
    80004b60:	088080e7          	jalr	136(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004b64:	40dc                	lw	a5,4(s1)
    80004b66:	02f05263          	blez	a5,80004b8a <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b6a:	2785                	addiw	a5,a5,1
    80004b6c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b6e:	0001d517          	auipc	a0,0x1d
    80004b72:	38a50513          	addi	a0,a0,906 # 80021ef8 <ftable>
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	122080e7          	jalr	290(ra) # 80000c98 <release>
  return f;
}
    80004b7e:	8526                	mv	a0,s1
    80004b80:	60e2                	ld	ra,24(sp)
    80004b82:	6442                	ld	s0,16(sp)
    80004b84:	64a2                	ld	s1,8(sp)
    80004b86:	6105                	addi	sp,sp,32
    80004b88:	8082                	ret
    panic("filedup");
    80004b8a:	00004517          	auipc	a0,0x4
    80004b8e:	ba650513          	addi	a0,a0,-1114 # 80008730 <syscalls+0x240>
    80004b92:	ffffc097          	auipc	ra,0xffffc
    80004b96:	9ac080e7          	jalr	-1620(ra) # 8000053e <panic>

0000000080004b9a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b9a:	7139                	addi	sp,sp,-64
    80004b9c:	fc06                	sd	ra,56(sp)
    80004b9e:	f822                	sd	s0,48(sp)
    80004ba0:	f426                	sd	s1,40(sp)
    80004ba2:	f04a                	sd	s2,32(sp)
    80004ba4:	ec4e                	sd	s3,24(sp)
    80004ba6:	e852                	sd	s4,16(sp)
    80004ba8:	e456                	sd	s5,8(sp)
    80004baa:	0080                	addi	s0,sp,64
    80004bac:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004bae:	0001d517          	auipc	a0,0x1d
    80004bb2:	34a50513          	addi	a0,a0,842 # 80021ef8 <ftable>
    80004bb6:	ffffc097          	auipc	ra,0xffffc
    80004bba:	02e080e7          	jalr	46(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004bbe:	40dc                	lw	a5,4(s1)
    80004bc0:	06f05163          	blez	a5,80004c22 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004bc4:	37fd                	addiw	a5,a5,-1
    80004bc6:	0007871b          	sext.w	a4,a5
    80004bca:	c0dc                	sw	a5,4(s1)
    80004bcc:	06e04363          	bgtz	a4,80004c32 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004bd0:	0004a903          	lw	s2,0(s1)
    80004bd4:	0094ca83          	lbu	s5,9(s1)
    80004bd8:	0104ba03          	ld	s4,16(s1)
    80004bdc:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004be0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004be4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004be8:	0001d517          	auipc	a0,0x1d
    80004bec:	31050513          	addi	a0,a0,784 # 80021ef8 <ftable>
    80004bf0:	ffffc097          	auipc	ra,0xffffc
    80004bf4:	0a8080e7          	jalr	168(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004bf8:	4785                	li	a5,1
    80004bfa:	04f90d63          	beq	s2,a5,80004c54 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004bfe:	3979                	addiw	s2,s2,-2
    80004c00:	4785                	li	a5,1
    80004c02:	0527e063          	bltu	a5,s2,80004c42 <fileclose+0xa8>
    begin_op();
    80004c06:	00000097          	auipc	ra,0x0
    80004c0a:	ac8080e7          	jalr	-1336(ra) # 800046ce <begin_op>
    iput(ff.ip);
    80004c0e:	854e                	mv	a0,s3
    80004c10:	fffff097          	auipc	ra,0xfffff
    80004c14:	2a6080e7          	jalr	678(ra) # 80003eb6 <iput>
    end_op();
    80004c18:	00000097          	auipc	ra,0x0
    80004c1c:	b36080e7          	jalr	-1226(ra) # 8000474e <end_op>
    80004c20:	a00d                	j	80004c42 <fileclose+0xa8>
    panic("fileclose");
    80004c22:	00004517          	auipc	a0,0x4
    80004c26:	b1650513          	addi	a0,a0,-1258 # 80008738 <syscalls+0x248>
    80004c2a:	ffffc097          	auipc	ra,0xffffc
    80004c2e:	914080e7          	jalr	-1772(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004c32:	0001d517          	auipc	a0,0x1d
    80004c36:	2c650513          	addi	a0,a0,710 # 80021ef8 <ftable>
    80004c3a:	ffffc097          	auipc	ra,0xffffc
    80004c3e:	05e080e7          	jalr	94(ra) # 80000c98 <release>
  }
}
    80004c42:	70e2                	ld	ra,56(sp)
    80004c44:	7442                	ld	s0,48(sp)
    80004c46:	74a2                	ld	s1,40(sp)
    80004c48:	7902                	ld	s2,32(sp)
    80004c4a:	69e2                	ld	s3,24(sp)
    80004c4c:	6a42                	ld	s4,16(sp)
    80004c4e:	6aa2                	ld	s5,8(sp)
    80004c50:	6121                	addi	sp,sp,64
    80004c52:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c54:	85d6                	mv	a1,s5
    80004c56:	8552                	mv	a0,s4
    80004c58:	00000097          	auipc	ra,0x0
    80004c5c:	34c080e7          	jalr	844(ra) # 80004fa4 <pipeclose>
    80004c60:	b7cd                	j	80004c42 <fileclose+0xa8>

0000000080004c62 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c62:	715d                	addi	sp,sp,-80
    80004c64:	e486                	sd	ra,72(sp)
    80004c66:	e0a2                	sd	s0,64(sp)
    80004c68:	fc26                	sd	s1,56(sp)
    80004c6a:	f84a                	sd	s2,48(sp)
    80004c6c:	f44e                	sd	s3,40(sp)
    80004c6e:	0880                	addi	s0,sp,80
    80004c70:	84aa                	mv	s1,a0
    80004c72:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c74:	ffffd097          	auipc	ra,0xffffd
    80004c78:	18c080e7          	jalr	396(ra) # 80001e00 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c7c:	409c                	lw	a5,0(s1)
    80004c7e:	37f9                	addiw	a5,a5,-2
    80004c80:	4705                	li	a4,1
    80004c82:	04f76763          	bltu	a4,a5,80004cd0 <filestat+0x6e>
    80004c86:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c88:	6c88                	ld	a0,24(s1)
    80004c8a:	fffff097          	auipc	ra,0xfffff
    80004c8e:	072080e7          	jalr	114(ra) # 80003cfc <ilock>
    stati(f->ip, &st);
    80004c92:	fb840593          	addi	a1,s0,-72
    80004c96:	6c88                	ld	a0,24(s1)
    80004c98:	fffff097          	auipc	ra,0xfffff
    80004c9c:	2ee080e7          	jalr	750(ra) # 80003f86 <stati>
    iunlock(f->ip);
    80004ca0:	6c88                	ld	a0,24(s1)
    80004ca2:	fffff097          	auipc	ra,0xfffff
    80004ca6:	11c080e7          	jalr	284(ra) # 80003dbe <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004caa:	46e1                	li	a3,24
    80004cac:	fb840613          	addi	a2,s0,-72
    80004cb0:	85ce                	mv	a1,s3
    80004cb2:	05093503          	ld	a0,80(s2)
    80004cb6:	ffffd097          	auipc	ra,0xffffd
    80004cba:	9bc080e7          	jalr	-1604(ra) # 80001672 <copyout>
    80004cbe:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004cc2:	60a6                	ld	ra,72(sp)
    80004cc4:	6406                	ld	s0,64(sp)
    80004cc6:	74e2                	ld	s1,56(sp)
    80004cc8:	7942                	ld	s2,48(sp)
    80004cca:	79a2                	ld	s3,40(sp)
    80004ccc:	6161                	addi	sp,sp,80
    80004cce:	8082                	ret
  return -1;
    80004cd0:	557d                	li	a0,-1
    80004cd2:	bfc5                	j	80004cc2 <filestat+0x60>

0000000080004cd4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004cd4:	7179                	addi	sp,sp,-48
    80004cd6:	f406                	sd	ra,40(sp)
    80004cd8:	f022                	sd	s0,32(sp)
    80004cda:	ec26                	sd	s1,24(sp)
    80004cdc:	e84a                	sd	s2,16(sp)
    80004cde:	e44e                	sd	s3,8(sp)
    80004ce0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004ce2:	00854783          	lbu	a5,8(a0)
    80004ce6:	c3d5                	beqz	a5,80004d8a <fileread+0xb6>
    80004ce8:	84aa                	mv	s1,a0
    80004cea:	89ae                	mv	s3,a1
    80004cec:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cee:	411c                	lw	a5,0(a0)
    80004cf0:	4705                	li	a4,1
    80004cf2:	04e78963          	beq	a5,a4,80004d44 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cf6:	470d                	li	a4,3
    80004cf8:	04e78d63          	beq	a5,a4,80004d52 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cfc:	4709                	li	a4,2
    80004cfe:	06e79e63          	bne	a5,a4,80004d7a <fileread+0xa6>
    ilock(f->ip);
    80004d02:	6d08                	ld	a0,24(a0)
    80004d04:	fffff097          	auipc	ra,0xfffff
    80004d08:	ff8080e7          	jalr	-8(ra) # 80003cfc <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d0c:	874a                	mv	a4,s2
    80004d0e:	5094                	lw	a3,32(s1)
    80004d10:	864e                	mv	a2,s3
    80004d12:	4585                	li	a1,1
    80004d14:	6c88                	ld	a0,24(s1)
    80004d16:	fffff097          	auipc	ra,0xfffff
    80004d1a:	29a080e7          	jalr	666(ra) # 80003fb0 <readi>
    80004d1e:	892a                	mv	s2,a0
    80004d20:	00a05563          	blez	a0,80004d2a <fileread+0x56>
      f->off += r;
    80004d24:	509c                	lw	a5,32(s1)
    80004d26:	9fa9                	addw	a5,a5,a0
    80004d28:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d2a:	6c88                	ld	a0,24(s1)
    80004d2c:	fffff097          	auipc	ra,0xfffff
    80004d30:	092080e7          	jalr	146(ra) # 80003dbe <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d34:	854a                	mv	a0,s2
    80004d36:	70a2                	ld	ra,40(sp)
    80004d38:	7402                	ld	s0,32(sp)
    80004d3a:	64e2                	ld	s1,24(sp)
    80004d3c:	6942                	ld	s2,16(sp)
    80004d3e:	69a2                	ld	s3,8(sp)
    80004d40:	6145                	addi	sp,sp,48
    80004d42:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d44:	6908                	ld	a0,16(a0)
    80004d46:	00000097          	auipc	ra,0x0
    80004d4a:	3c8080e7          	jalr	968(ra) # 8000510e <piperead>
    80004d4e:	892a                	mv	s2,a0
    80004d50:	b7d5                	j	80004d34 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d52:	02451783          	lh	a5,36(a0)
    80004d56:	03079693          	slli	a3,a5,0x30
    80004d5a:	92c1                	srli	a3,a3,0x30
    80004d5c:	4725                	li	a4,9
    80004d5e:	02d76863          	bltu	a4,a3,80004d8e <fileread+0xba>
    80004d62:	0792                	slli	a5,a5,0x4
    80004d64:	0001d717          	auipc	a4,0x1d
    80004d68:	0f470713          	addi	a4,a4,244 # 80021e58 <devsw>
    80004d6c:	97ba                	add	a5,a5,a4
    80004d6e:	639c                	ld	a5,0(a5)
    80004d70:	c38d                	beqz	a5,80004d92 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d72:	4505                	li	a0,1
    80004d74:	9782                	jalr	a5
    80004d76:	892a                	mv	s2,a0
    80004d78:	bf75                	j	80004d34 <fileread+0x60>
    panic("fileread");
    80004d7a:	00004517          	auipc	a0,0x4
    80004d7e:	9ce50513          	addi	a0,a0,-1586 # 80008748 <syscalls+0x258>
    80004d82:	ffffb097          	auipc	ra,0xffffb
    80004d86:	7bc080e7          	jalr	1980(ra) # 8000053e <panic>
    return -1;
    80004d8a:	597d                	li	s2,-1
    80004d8c:	b765                	j	80004d34 <fileread+0x60>
      return -1;
    80004d8e:	597d                	li	s2,-1
    80004d90:	b755                	j	80004d34 <fileread+0x60>
    80004d92:	597d                	li	s2,-1
    80004d94:	b745                	j	80004d34 <fileread+0x60>

0000000080004d96 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d96:	715d                	addi	sp,sp,-80
    80004d98:	e486                	sd	ra,72(sp)
    80004d9a:	e0a2                	sd	s0,64(sp)
    80004d9c:	fc26                	sd	s1,56(sp)
    80004d9e:	f84a                	sd	s2,48(sp)
    80004da0:	f44e                	sd	s3,40(sp)
    80004da2:	f052                	sd	s4,32(sp)
    80004da4:	ec56                	sd	s5,24(sp)
    80004da6:	e85a                	sd	s6,16(sp)
    80004da8:	e45e                	sd	s7,8(sp)
    80004daa:	e062                	sd	s8,0(sp)
    80004dac:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004dae:	00954783          	lbu	a5,9(a0)
    80004db2:	10078663          	beqz	a5,80004ebe <filewrite+0x128>
    80004db6:	892a                	mv	s2,a0
    80004db8:	8aae                	mv	s5,a1
    80004dba:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dbc:	411c                	lw	a5,0(a0)
    80004dbe:	4705                	li	a4,1
    80004dc0:	02e78263          	beq	a5,a4,80004de4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004dc4:	470d                	li	a4,3
    80004dc6:	02e78663          	beq	a5,a4,80004df2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dca:	4709                	li	a4,2
    80004dcc:	0ee79163          	bne	a5,a4,80004eae <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004dd0:	0ac05d63          	blez	a2,80004e8a <filewrite+0xf4>
    int i = 0;
    80004dd4:	4981                	li	s3,0
    80004dd6:	6b05                	lui	s6,0x1
    80004dd8:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004ddc:	6b85                	lui	s7,0x1
    80004dde:	c00b8b9b          	addiw	s7,s7,-1024
    80004de2:	a861                	j	80004e7a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004de4:	6908                	ld	a0,16(a0)
    80004de6:	00000097          	auipc	ra,0x0
    80004dea:	22e080e7          	jalr	558(ra) # 80005014 <pipewrite>
    80004dee:	8a2a                	mv	s4,a0
    80004df0:	a045                	j	80004e90 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004df2:	02451783          	lh	a5,36(a0)
    80004df6:	03079693          	slli	a3,a5,0x30
    80004dfa:	92c1                	srli	a3,a3,0x30
    80004dfc:	4725                	li	a4,9
    80004dfe:	0cd76263          	bltu	a4,a3,80004ec2 <filewrite+0x12c>
    80004e02:	0792                	slli	a5,a5,0x4
    80004e04:	0001d717          	auipc	a4,0x1d
    80004e08:	05470713          	addi	a4,a4,84 # 80021e58 <devsw>
    80004e0c:	97ba                	add	a5,a5,a4
    80004e0e:	679c                	ld	a5,8(a5)
    80004e10:	cbdd                	beqz	a5,80004ec6 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e12:	4505                	li	a0,1
    80004e14:	9782                	jalr	a5
    80004e16:	8a2a                	mv	s4,a0
    80004e18:	a8a5                	j	80004e90 <filewrite+0xfa>
    80004e1a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e1e:	00000097          	auipc	ra,0x0
    80004e22:	8b0080e7          	jalr	-1872(ra) # 800046ce <begin_op>
      ilock(f->ip);
    80004e26:	01893503          	ld	a0,24(s2)
    80004e2a:	fffff097          	auipc	ra,0xfffff
    80004e2e:	ed2080e7          	jalr	-302(ra) # 80003cfc <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e32:	8762                	mv	a4,s8
    80004e34:	02092683          	lw	a3,32(s2)
    80004e38:	01598633          	add	a2,s3,s5
    80004e3c:	4585                	li	a1,1
    80004e3e:	01893503          	ld	a0,24(s2)
    80004e42:	fffff097          	auipc	ra,0xfffff
    80004e46:	266080e7          	jalr	614(ra) # 800040a8 <writei>
    80004e4a:	84aa                	mv	s1,a0
    80004e4c:	00a05763          	blez	a0,80004e5a <filewrite+0xc4>
        f->off += r;
    80004e50:	02092783          	lw	a5,32(s2)
    80004e54:	9fa9                	addw	a5,a5,a0
    80004e56:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e5a:	01893503          	ld	a0,24(s2)
    80004e5e:	fffff097          	auipc	ra,0xfffff
    80004e62:	f60080e7          	jalr	-160(ra) # 80003dbe <iunlock>
      end_op();
    80004e66:	00000097          	auipc	ra,0x0
    80004e6a:	8e8080e7          	jalr	-1816(ra) # 8000474e <end_op>

      if(r != n1){
    80004e6e:	009c1f63          	bne	s8,s1,80004e8c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e72:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e76:	0149db63          	bge	s3,s4,80004e8c <filewrite+0xf6>
      int n1 = n - i;
    80004e7a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004e7e:	84be                	mv	s1,a5
    80004e80:	2781                	sext.w	a5,a5
    80004e82:	f8fb5ce3          	bge	s6,a5,80004e1a <filewrite+0x84>
    80004e86:	84de                	mv	s1,s7
    80004e88:	bf49                	j	80004e1a <filewrite+0x84>
    int i = 0;
    80004e8a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e8c:	013a1f63          	bne	s4,s3,80004eaa <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e90:	8552                	mv	a0,s4
    80004e92:	60a6                	ld	ra,72(sp)
    80004e94:	6406                	ld	s0,64(sp)
    80004e96:	74e2                	ld	s1,56(sp)
    80004e98:	7942                	ld	s2,48(sp)
    80004e9a:	79a2                	ld	s3,40(sp)
    80004e9c:	7a02                	ld	s4,32(sp)
    80004e9e:	6ae2                	ld	s5,24(sp)
    80004ea0:	6b42                	ld	s6,16(sp)
    80004ea2:	6ba2                	ld	s7,8(sp)
    80004ea4:	6c02                	ld	s8,0(sp)
    80004ea6:	6161                	addi	sp,sp,80
    80004ea8:	8082                	ret
    ret = (i == n ? n : -1);
    80004eaa:	5a7d                	li	s4,-1
    80004eac:	b7d5                	j	80004e90 <filewrite+0xfa>
    panic("filewrite");
    80004eae:	00004517          	auipc	a0,0x4
    80004eb2:	8aa50513          	addi	a0,a0,-1878 # 80008758 <syscalls+0x268>
    80004eb6:	ffffb097          	auipc	ra,0xffffb
    80004eba:	688080e7          	jalr	1672(ra) # 8000053e <panic>
    return -1;
    80004ebe:	5a7d                	li	s4,-1
    80004ec0:	bfc1                	j	80004e90 <filewrite+0xfa>
      return -1;
    80004ec2:	5a7d                	li	s4,-1
    80004ec4:	b7f1                	j	80004e90 <filewrite+0xfa>
    80004ec6:	5a7d                	li	s4,-1
    80004ec8:	b7e1                	j	80004e90 <filewrite+0xfa>

0000000080004eca <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004eca:	7179                	addi	sp,sp,-48
    80004ecc:	f406                	sd	ra,40(sp)
    80004ece:	f022                	sd	s0,32(sp)
    80004ed0:	ec26                	sd	s1,24(sp)
    80004ed2:	e84a                	sd	s2,16(sp)
    80004ed4:	e44e                	sd	s3,8(sp)
    80004ed6:	e052                	sd	s4,0(sp)
    80004ed8:	1800                	addi	s0,sp,48
    80004eda:	84aa                	mv	s1,a0
    80004edc:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ede:	0005b023          	sd	zero,0(a1)
    80004ee2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ee6:	00000097          	auipc	ra,0x0
    80004eea:	bf8080e7          	jalr	-1032(ra) # 80004ade <filealloc>
    80004eee:	e088                	sd	a0,0(s1)
    80004ef0:	c551                	beqz	a0,80004f7c <pipealloc+0xb2>
    80004ef2:	00000097          	auipc	ra,0x0
    80004ef6:	bec080e7          	jalr	-1044(ra) # 80004ade <filealloc>
    80004efa:	00aa3023          	sd	a0,0(s4)
    80004efe:	c92d                	beqz	a0,80004f70 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f00:	ffffc097          	auipc	ra,0xffffc
    80004f04:	bf4080e7          	jalr	-1036(ra) # 80000af4 <kalloc>
    80004f08:	892a                	mv	s2,a0
    80004f0a:	c125                	beqz	a0,80004f6a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f0c:	4985                	li	s3,1
    80004f0e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f12:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f16:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f1a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f1e:	00004597          	auipc	a1,0x4
    80004f22:	84a58593          	addi	a1,a1,-1974 # 80008768 <syscalls+0x278>
    80004f26:	ffffc097          	auipc	ra,0xffffc
    80004f2a:	c2e080e7          	jalr	-978(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004f2e:	609c                	ld	a5,0(s1)
    80004f30:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f34:	609c                	ld	a5,0(s1)
    80004f36:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f3a:	609c                	ld	a5,0(s1)
    80004f3c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f40:	609c                	ld	a5,0(s1)
    80004f42:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f46:	000a3783          	ld	a5,0(s4)
    80004f4a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f4e:	000a3783          	ld	a5,0(s4)
    80004f52:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f56:	000a3783          	ld	a5,0(s4)
    80004f5a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f5e:	000a3783          	ld	a5,0(s4)
    80004f62:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f66:	4501                	li	a0,0
    80004f68:	a025                	j	80004f90 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f6a:	6088                	ld	a0,0(s1)
    80004f6c:	e501                	bnez	a0,80004f74 <pipealloc+0xaa>
    80004f6e:	a039                	j	80004f7c <pipealloc+0xb2>
    80004f70:	6088                	ld	a0,0(s1)
    80004f72:	c51d                	beqz	a0,80004fa0 <pipealloc+0xd6>
    fileclose(*f0);
    80004f74:	00000097          	auipc	ra,0x0
    80004f78:	c26080e7          	jalr	-986(ra) # 80004b9a <fileclose>
  if(*f1)
    80004f7c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f80:	557d                	li	a0,-1
  if(*f1)
    80004f82:	c799                	beqz	a5,80004f90 <pipealloc+0xc6>
    fileclose(*f1);
    80004f84:	853e                	mv	a0,a5
    80004f86:	00000097          	auipc	ra,0x0
    80004f8a:	c14080e7          	jalr	-1004(ra) # 80004b9a <fileclose>
  return -1;
    80004f8e:	557d                	li	a0,-1
}
    80004f90:	70a2                	ld	ra,40(sp)
    80004f92:	7402                	ld	s0,32(sp)
    80004f94:	64e2                	ld	s1,24(sp)
    80004f96:	6942                	ld	s2,16(sp)
    80004f98:	69a2                	ld	s3,8(sp)
    80004f9a:	6a02                	ld	s4,0(sp)
    80004f9c:	6145                	addi	sp,sp,48
    80004f9e:	8082                	ret
  return -1;
    80004fa0:	557d                	li	a0,-1
    80004fa2:	b7fd                	j	80004f90 <pipealloc+0xc6>

0000000080004fa4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004fa4:	1101                	addi	sp,sp,-32
    80004fa6:	ec06                	sd	ra,24(sp)
    80004fa8:	e822                	sd	s0,16(sp)
    80004faa:	e426                	sd	s1,8(sp)
    80004fac:	e04a                	sd	s2,0(sp)
    80004fae:	1000                	addi	s0,sp,32
    80004fb0:	84aa                	mv	s1,a0
    80004fb2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004fb4:	ffffc097          	auipc	ra,0xffffc
    80004fb8:	c30080e7          	jalr	-976(ra) # 80000be4 <acquire>
  if(writable){
    80004fbc:	02090d63          	beqz	s2,80004ff6 <pipeclose+0x52>
    pi->writeopen = 0;
    80004fc0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004fc4:	21848513          	addi	a0,s1,536
    80004fc8:	ffffd097          	auipc	ra,0xffffd
    80004fcc:	7ea080e7          	jalr	2026(ra) # 800027b2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004fd0:	2204b783          	ld	a5,544(s1)
    80004fd4:	eb95                	bnez	a5,80005008 <pipeclose+0x64>
    release(&pi->lock);
    80004fd6:	8526                	mv	a0,s1
    80004fd8:	ffffc097          	auipc	ra,0xffffc
    80004fdc:	cc0080e7          	jalr	-832(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004fe0:	8526                	mv	a0,s1
    80004fe2:	ffffc097          	auipc	ra,0xffffc
    80004fe6:	a16080e7          	jalr	-1514(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004fea:	60e2                	ld	ra,24(sp)
    80004fec:	6442                	ld	s0,16(sp)
    80004fee:	64a2                	ld	s1,8(sp)
    80004ff0:	6902                	ld	s2,0(sp)
    80004ff2:	6105                	addi	sp,sp,32
    80004ff4:	8082                	ret
    pi->readopen = 0;
    80004ff6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ffa:	21c48513          	addi	a0,s1,540
    80004ffe:	ffffd097          	auipc	ra,0xffffd
    80005002:	7b4080e7          	jalr	1972(ra) # 800027b2 <wakeup>
    80005006:	b7e9                	j	80004fd0 <pipeclose+0x2c>
    release(&pi->lock);
    80005008:	8526                	mv	a0,s1
    8000500a:	ffffc097          	auipc	ra,0xffffc
    8000500e:	c8e080e7          	jalr	-882(ra) # 80000c98 <release>
}
    80005012:	bfe1                	j	80004fea <pipeclose+0x46>

0000000080005014 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005014:	7159                	addi	sp,sp,-112
    80005016:	f486                	sd	ra,104(sp)
    80005018:	f0a2                	sd	s0,96(sp)
    8000501a:	eca6                	sd	s1,88(sp)
    8000501c:	e8ca                	sd	s2,80(sp)
    8000501e:	e4ce                	sd	s3,72(sp)
    80005020:	e0d2                	sd	s4,64(sp)
    80005022:	fc56                	sd	s5,56(sp)
    80005024:	f85a                	sd	s6,48(sp)
    80005026:	f45e                	sd	s7,40(sp)
    80005028:	f062                	sd	s8,32(sp)
    8000502a:	ec66                	sd	s9,24(sp)
    8000502c:	1880                	addi	s0,sp,112
    8000502e:	84aa                	mv	s1,a0
    80005030:	8aae                	mv	s5,a1
    80005032:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005034:	ffffd097          	auipc	ra,0xffffd
    80005038:	dcc080e7          	jalr	-564(ra) # 80001e00 <myproc>
    8000503c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000503e:	8526                	mv	a0,s1
    80005040:	ffffc097          	auipc	ra,0xffffc
    80005044:	ba4080e7          	jalr	-1116(ra) # 80000be4 <acquire>
  while(i < n){
    80005048:	0d405163          	blez	s4,8000510a <pipewrite+0xf6>
    8000504c:	8ba6                	mv	s7,s1
  int i = 0;
    8000504e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005050:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005052:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005056:	21c48c13          	addi	s8,s1,540
    8000505a:	a08d                	j	800050bc <pipewrite+0xa8>
      release(&pi->lock);
    8000505c:	8526                	mv	a0,s1
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	c3a080e7          	jalr	-966(ra) # 80000c98 <release>
      return -1;
    80005066:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005068:	854a                	mv	a0,s2
    8000506a:	70a6                	ld	ra,104(sp)
    8000506c:	7406                	ld	s0,96(sp)
    8000506e:	64e6                	ld	s1,88(sp)
    80005070:	6946                	ld	s2,80(sp)
    80005072:	69a6                	ld	s3,72(sp)
    80005074:	6a06                	ld	s4,64(sp)
    80005076:	7ae2                	ld	s5,56(sp)
    80005078:	7b42                	ld	s6,48(sp)
    8000507a:	7ba2                	ld	s7,40(sp)
    8000507c:	7c02                	ld	s8,32(sp)
    8000507e:	6ce2                	ld	s9,24(sp)
    80005080:	6165                	addi	sp,sp,112
    80005082:	8082                	ret
      wakeup(&pi->nread);
    80005084:	8566                	mv	a0,s9
    80005086:	ffffd097          	auipc	ra,0xffffd
    8000508a:	72c080e7          	jalr	1836(ra) # 800027b2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000508e:	85de                	mv	a1,s7
    80005090:	8562                	mv	a0,s8
    80005092:	ffffd097          	auipc	ra,0xffffd
    80005096:	582080e7          	jalr	1410(ra) # 80002614 <sleep>
    8000509a:	a839                	j	800050b8 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000509c:	21c4a783          	lw	a5,540(s1)
    800050a0:	0017871b          	addiw	a4,a5,1
    800050a4:	20e4ae23          	sw	a4,540(s1)
    800050a8:	1ff7f793          	andi	a5,a5,511
    800050ac:	97a6                	add	a5,a5,s1
    800050ae:	f9f44703          	lbu	a4,-97(s0)
    800050b2:	00e78c23          	sb	a4,24(a5)
      i++;
    800050b6:	2905                	addiw	s2,s2,1
  while(i < n){
    800050b8:	03495d63          	bge	s2,s4,800050f2 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800050bc:	2204a783          	lw	a5,544(s1)
    800050c0:	dfd1                	beqz	a5,8000505c <pipewrite+0x48>
    800050c2:	0289a783          	lw	a5,40(s3)
    800050c6:	fbd9                	bnez	a5,8000505c <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800050c8:	2184a783          	lw	a5,536(s1)
    800050cc:	21c4a703          	lw	a4,540(s1)
    800050d0:	2007879b          	addiw	a5,a5,512
    800050d4:	faf708e3          	beq	a4,a5,80005084 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050d8:	4685                	li	a3,1
    800050da:	01590633          	add	a2,s2,s5
    800050de:	f9f40593          	addi	a1,s0,-97
    800050e2:	0509b503          	ld	a0,80(s3)
    800050e6:	ffffc097          	auipc	ra,0xffffc
    800050ea:	618080e7          	jalr	1560(ra) # 800016fe <copyin>
    800050ee:	fb6517e3          	bne	a0,s6,8000509c <pipewrite+0x88>
  wakeup(&pi->nread);
    800050f2:	21848513          	addi	a0,s1,536
    800050f6:	ffffd097          	auipc	ra,0xffffd
    800050fa:	6bc080e7          	jalr	1724(ra) # 800027b2 <wakeup>
  release(&pi->lock);
    800050fe:	8526                	mv	a0,s1
    80005100:	ffffc097          	auipc	ra,0xffffc
    80005104:	b98080e7          	jalr	-1128(ra) # 80000c98 <release>
  return i;
    80005108:	b785                	j	80005068 <pipewrite+0x54>
  int i = 0;
    8000510a:	4901                	li	s2,0
    8000510c:	b7dd                	j	800050f2 <pipewrite+0xde>

000000008000510e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000510e:	715d                	addi	sp,sp,-80
    80005110:	e486                	sd	ra,72(sp)
    80005112:	e0a2                	sd	s0,64(sp)
    80005114:	fc26                	sd	s1,56(sp)
    80005116:	f84a                	sd	s2,48(sp)
    80005118:	f44e                	sd	s3,40(sp)
    8000511a:	f052                	sd	s4,32(sp)
    8000511c:	ec56                	sd	s5,24(sp)
    8000511e:	e85a                	sd	s6,16(sp)
    80005120:	0880                	addi	s0,sp,80
    80005122:	84aa                	mv	s1,a0
    80005124:	892e                	mv	s2,a1
    80005126:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005128:	ffffd097          	auipc	ra,0xffffd
    8000512c:	cd8080e7          	jalr	-808(ra) # 80001e00 <myproc>
    80005130:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005132:	8b26                	mv	s6,s1
    80005134:	8526                	mv	a0,s1
    80005136:	ffffc097          	auipc	ra,0xffffc
    8000513a:	aae080e7          	jalr	-1362(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000513e:	2184a703          	lw	a4,536(s1)
    80005142:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005146:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000514a:	02f71463          	bne	a4,a5,80005172 <piperead+0x64>
    8000514e:	2244a783          	lw	a5,548(s1)
    80005152:	c385                	beqz	a5,80005172 <piperead+0x64>
    if(pr->killed){
    80005154:	028a2783          	lw	a5,40(s4)
    80005158:	ebc1                	bnez	a5,800051e8 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000515a:	85da                	mv	a1,s6
    8000515c:	854e                	mv	a0,s3
    8000515e:	ffffd097          	auipc	ra,0xffffd
    80005162:	4b6080e7          	jalr	1206(ra) # 80002614 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005166:	2184a703          	lw	a4,536(s1)
    8000516a:	21c4a783          	lw	a5,540(s1)
    8000516e:	fef700e3          	beq	a4,a5,8000514e <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005172:	09505263          	blez	s5,800051f6 <piperead+0xe8>
    80005176:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005178:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000517a:	2184a783          	lw	a5,536(s1)
    8000517e:	21c4a703          	lw	a4,540(s1)
    80005182:	02f70d63          	beq	a4,a5,800051bc <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005186:	0017871b          	addiw	a4,a5,1
    8000518a:	20e4ac23          	sw	a4,536(s1)
    8000518e:	1ff7f793          	andi	a5,a5,511
    80005192:	97a6                	add	a5,a5,s1
    80005194:	0187c783          	lbu	a5,24(a5)
    80005198:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000519c:	4685                	li	a3,1
    8000519e:	fbf40613          	addi	a2,s0,-65
    800051a2:	85ca                	mv	a1,s2
    800051a4:	050a3503          	ld	a0,80(s4)
    800051a8:	ffffc097          	auipc	ra,0xffffc
    800051ac:	4ca080e7          	jalr	1226(ra) # 80001672 <copyout>
    800051b0:	01650663          	beq	a0,s6,800051bc <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051b4:	2985                	addiw	s3,s3,1
    800051b6:	0905                	addi	s2,s2,1
    800051b8:	fd3a91e3          	bne	s5,s3,8000517a <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800051bc:	21c48513          	addi	a0,s1,540
    800051c0:	ffffd097          	auipc	ra,0xffffd
    800051c4:	5f2080e7          	jalr	1522(ra) # 800027b2 <wakeup>
  release(&pi->lock);
    800051c8:	8526                	mv	a0,s1
    800051ca:	ffffc097          	auipc	ra,0xffffc
    800051ce:	ace080e7          	jalr	-1330(ra) # 80000c98 <release>
  return i;
}
    800051d2:	854e                	mv	a0,s3
    800051d4:	60a6                	ld	ra,72(sp)
    800051d6:	6406                	ld	s0,64(sp)
    800051d8:	74e2                	ld	s1,56(sp)
    800051da:	7942                	ld	s2,48(sp)
    800051dc:	79a2                	ld	s3,40(sp)
    800051de:	7a02                	ld	s4,32(sp)
    800051e0:	6ae2                	ld	s5,24(sp)
    800051e2:	6b42                	ld	s6,16(sp)
    800051e4:	6161                	addi	sp,sp,80
    800051e6:	8082                	ret
      release(&pi->lock);
    800051e8:	8526                	mv	a0,s1
    800051ea:	ffffc097          	auipc	ra,0xffffc
    800051ee:	aae080e7          	jalr	-1362(ra) # 80000c98 <release>
      return -1;
    800051f2:	59fd                	li	s3,-1
    800051f4:	bff9                	j	800051d2 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051f6:	4981                	li	s3,0
    800051f8:	b7d1                	j	800051bc <piperead+0xae>

00000000800051fa <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800051fa:	df010113          	addi	sp,sp,-528
    800051fe:	20113423          	sd	ra,520(sp)
    80005202:	20813023          	sd	s0,512(sp)
    80005206:	ffa6                	sd	s1,504(sp)
    80005208:	fbca                	sd	s2,496(sp)
    8000520a:	f7ce                	sd	s3,488(sp)
    8000520c:	f3d2                	sd	s4,480(sp)
    8000520e:	efd6                	sd	s5,472(sp)
    80005210:	ebda                	sd	s6,464(sp)
    80005212:	e7de                	sd	s7,456(sp)
    80005214:	e3e2                	sd	s8,448(sp)
    80005216:	ff66                	sd	s9,440(sp)
    80005218:	fb6a                	sd	s10,432(sp)
    8000521a:	f76e                	sd	s11,424(sp)
    8000521c:	0c00                	addi	s0,sp,528
    8000521e:	84aa                	mv	s1,a0
    80005220:	dea43c23          	sd	a0,-520(s0)
    80005224:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005228:	ffffd097          	auipc	ra,0xffffd
    8000522c:	bd8080e7          	jalr	-1064(ra) # 80001e00 <myproc>
    80005230:	892a                	mv	s2,a0

  begin_op();
    80005232:	fffff097          	auipc	ra,0xfffff
    80005236:	49c080e7          	jalr	1180(ra) # 800046ce <begin_op>

  if((ip = namei(path)) == 0){
    8000523a:	8526                	mv	a0,s1
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	276080e7          	jalr	630(ra) # 800044b2 <namei>
    80005244:	c92d                	beqz	a0,800052b6 <exec+0xbc>
    80005246:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005248:	fffff097          	auipc	ra,0xfffff
    8000524c:	ab4080e7          	jalr	-1356(ra) # 80003cfc <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005250:	04000713          	li	a4,64
    80005254:	4681                	li	a3,0
    80005256:	e5040613          	addi	a2,s0,-432
    8000525a:	4581                	li	a1,0
    8000525c:	8526                	mv	a0,s1
    8000525e:	fffff097          	auipc	ra,0xfffff
    80005262:	d52080e7          	jalr	-686(ra) # 80003fb0 <readi>
    80005266:	04000793          	li	a5,64
    8000526a:	00f51a63          	bne	a0,a5,8000527e <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000526e:	e5042703          	lw	a4,-432(s0)
    80005272:	464c47b7          	lui	a5,0x464c4
    80005276:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000527a:	04f70463          	beq	a4,a5,800052c2 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000527e:	8526                	mv	a0,s1
    80005280:	fffff097          	auipc	ra,0xfffff
    80005284:	cde080e7          	jalr	-802(ra) # 80003f5e <iunlockput>
    end_op();
    80005288:	fffff097          	auipc	ra,0xfffff
    8000528c:	4c6080e7          	jalr	1222(ra) # 8000474e <end_op>
  }
  return -1;
    80005290:	557d                	li	a0,-1
}
    80005292:	20813083          	ld	ra,520(sp)
    80005296:	20013403          	ld	s0,512(sp)
    8000529a:	74fe                	ld	s1,504(sp)
    8000529c:	795e                	ld	s2,496(sp)
    8000529e:	79be                	ld	s3,488(sp)
    800052a0:	7a1e                	ld	s4,480(sp)
    800052a2:	6afe                	ld	s5,472(sp)
    800052a4:	6b5e                	ld	s6,464(sp)
    800052a6:	6bbe                	ld	s7,456(sp)
    800052a8:	6c1e                	ld	s8,448(sp)
    800052aa:	7cfa                	ld	s9,440(sp)
    800052ac:	7d5a                	ld	s10,432(sp)
    800052ae:	7dba                	ld	s11,424(sp)
    800052b0:	21010113          	addi	sp,sp,528
    800052b4:	8082                	ret
    end_op();
    800052b6:	fffff097          	auipc	ra,0xfffff
    800052ba:	498080e7          	jalr	1176(ra) # 8000474e <end_op>
    return -1;
    800052be:	557d                	li	a0,-1
    800052c0:	bfc9                	j	80005292 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800052c2:	854a                	mv	a0,s2
    800052c4:	ffffd097          	auipc	ra,0xffffd
    800052c8:	bfa080e7          	jalr	-1030(ra) # 80001ebe <proc_pagetable>
    800052cc:	8baa                	mv	s7,a0
    800052ce:	d945                	beqz	a0,8000527e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052d0:	e7042983          	lw	s3,-400(s0)
    800052d4:	e8845783          	lhu	a5,-376(s0)
    800052d8:	c7ad                	beqz	a5,80005342 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052da:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052dc:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800052de:	6c85                	lui	s9,0x1
    800052e0:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800052e4:	def43823          	sd	a5,-528(s0)
    800052e8:	a42d                	j	80005512 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800052ea:	00003517          	auipc	a0,0x3
    800052ee:	48650513          	addi	a0,a0,1158 # 80008770 <syscalls+0x280>
    800052f2:	ffffb097          	auipc	ra,0xffffb
    800052f6:	24c080e7          	jalr	588(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800052fa:	8756                	mv	a4,s5
    800052fc:	012d86bb          	addw	a3,s11,s2
    80005300:	4581                	li	a1,0
    80005302:	8526                	mv	a0,s1
    80005304:	fffff097          	auipc	ra,0xfffff
    80005308:	cac080e7          	jalr	-852(ra) # 80003fb0 <readi>
    8000530c:	2501                	sext.w	a0,a0
    8000530e:	1aaa9963          	bne	s5,a0,800054c0 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005312:	6785                	lui	a5,0x1
    80005314:	0127893b          	addw	s2,a5,s2
    80005318:	77fd                	lui	a5,0xfffff
    8000531a:	01478a3b          	addw	s4,a5,s4
    8000531e:	1f897163          	bgeu	s2,s8,80005500 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005322:	02091593          	slli	a1,s2,0x20
    80005326:	9181                	srli	a1,a1,0x20
    80005328:	95ea                	add	a1,a1,s10
    8000532a:	855e                	mv	a0,s7
    8000532c:	ffffc097          	auipc	ra,0xffffc
    80005330:	d42080e7          	jalr	-702(ra) # 8000106e <walkaddr>
    80005334:	862a                	mv	a2,a0
    if(pa == 0)
    80005336:	d955                	beqz	a0,800052ea <exec+0xf0>
      n = PGSIZE;
    80005338:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000533a:	fd9a70e3          	bgeu	s4,s9,800052fa <exec+0x100>
      n = sz - i;
    8000533e:	8ad2                	mv	s5,s4
    80005340:	bf6d                	j	800052fa <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005342:	4901                	li	s2,0
  iunlockput(ip);
    80005344:	8526                	mv	a0,s1
    80005346:	fffff097          	auipc	ra,0xfffff
    8000534a:	c18080e7          	jalr	-1000(ra) # 80003f5e <iunlockput>
  end_op();
    8000534e:	fffff097          	auipc	ra,0xfffff
    80005352:	400080e7          	jalr	1024(ra) # 8000474e <end_op>
  p = myproc();
    80005356:	ffffd097          	auipc	ra,0xffffd
    8000535a:	aaa080e7          	jalr	-1366(ra) # 80001e00 <myproc>
    8000535e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005360:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005364:	6785                	lui	a5,0x1
    80005366:	17fd                	addi	a5,a5,-1
    80005368:	993e                	add	s2,s2,a5
    8000536a:	757d                	lui	a0,0xfffff
    8000536c:	00a977b3          	and	a5,s2,a0
    80005370:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005374:	6609                	lui	a2,0x2
    80005376:	963e                	add	a2,a2,a5
    80005378:	85be                	mv	a1,a5
    8000537a:	855e                	mv	a0,s7
    8000537c:	ffffc097          	auipc	ra,0xffffc
    80005380:	0a6080e7          	jalr	166(ra) # 80001422 <uvmalloc>
    80005384:	8b2a                	mv	s6,a0
  ip = 0;
    80005386:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005388:	12050c63          	beqz	a0,800054c0 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000538c:	75f9                	lui	a1,0xffffe
    8000538e:	95aa                	add	a1,a1,a0
    80005390:	855e                	mv	a0,s7
    80005392:	ffffc097          	auipc	ra,0xffffc
    80005396:	2ae080e7          	jalr	686(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    8000539a:	7c7d                	lui	s8,0xfffff
    8000539c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000539e:	e0043783          	ld	a5,-512(s0)
    800053a2:	6388                	ld	a0,0(a5)
    800053a4:	c535                	beqz	a0,80005410 <exec+0x216>
    800053a6:	e9040993          	addi	s3,s0,-368
    800053aa:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800053ae:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800053b0:	ffffc097          	auipc	ra,0xffffc
    800053b4:	ab4080e7          	jalr	-1356(ra) # 80000e64 <strlen>
    800053b8:	2505                	addiw	a0,a0,1
    800053ba:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800053be:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800053c2:	13896363          	bltu	s2,s8,800054e8 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800053c6:	e0043d83          	ld	s11,-512(s0)
    800053ca:	000dba03          	ld	s4,0(s11)
    800053ce:	8552                	mv	a0,s4
    800053d0:	ffffc097          	auipc	ra,0xffffc
    800053d4:	a94080e7          	jalr	-1388(ra) # 80000e64 <strlen>
    800053d8:	0015069b          	addiw	a3,a0,1
    800053dc:	8652                	mv	a2,s4
    800053de:	85ca                	mv	a1,s2
    800053e0:	855e                	mv	a0,s7
    800053e2:	ffffc097          	auipc	ra,0xffffc
    800053e6:	290080e7          	jalr	656(ra) # 80001672 <copyout>
    800053ea:	10054363          	bltz	a0,800054f0 <exec+0x2f6>
    ustack[argc] = sp;
    800053ee:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800053f2:	0485                	addi	s1,s1,1
    800053f4:	008d8793          	addi	a5,s11,8
    800053f8:	e0f43023          	sd	a5,-512(s0)
    800053fc:	008db503          	ld	a0,8(s11)
    80005400:	c911                	beqz	a0,80005414 <exec+0x21a>
    if(argc >= MAXARG)
    80005402:	09a1                	addi	s3,s3,8
    80005404:	fb3c96e3          	bne	s9,s3,800053b0 <exec+0x1b6>
  sz = sz1;
    80005408:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000540c:	4481                	li	s1,0
    8000540e:	a84d                	j	800054c0 <exec+0x2c6>
  sp = sz;
    80005410:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005412:	4481                	li	s1,0
  ustack[argc] = 0;
    80005414:	00349793          	slli	a5,s1,0x3
    80005418:	f9040713          	addi	a4,s0,-112
    8000541c:	97ba                	add	a5,a5,a4
    8000541e:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005422:	00148693          	addi	a3,s1,1
    80005426:	068e                	slli	a3,a3,0x3
    80005428:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000542c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005430:	01897663          	bgeu	s2,s8,8000543c <exec+0x242>
  sz = sz1;
    80005434:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005438:	4481                	li	s1,0
    8000543a:	a059                	j	800054c0 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000543c:	e9040613          	addi	a2,s0,-368
    80005440:	85ca                	mv	a1,s2
    80005442:	855e                	mv	a0,s7
    80005444:	ffffc097          	auipc	ra,0xffffc
    80005448:	22e080e7          	jalr	558(ra) # 80001672 <copyout>
    8000544c:	0a054663          	bltz	a0,800054f8 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005450:	058ab783          	ld	a5,88(s5)
    80005454:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005458:	df843783          	ld	a5,-520(s0)
    8000545c:	0007c703          	lbu	a4,0(a5)
    80005460:	cf11                	beqz	a4,8000547c <exec+0x282>
    80005462:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005464:	02f00693          	li	a3,47
    80005468:	a039                	j	80005476 <exec+0x27c>
      last = s+1;
    8000546a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000546e:	0785                	addi	a5,a5,1
    80005470:	fff7c703          	lbu	a4,-1(a5)
    80005474:	c701                	beqz	a4,8000547c <exec+0x282>
    if(*s == '/')
    80005476:	fed71ce3          	bne	a4,a3,8000546e <exec+0x274>
    8000547a:	bfc5                	j	8000546a <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000547c:	4641                	li	a2,16
    8000547e:	df843583          	ld	a1,-520(s0)
    80005482:	158a8513          	addi	a0,s5,344
    80005486:	ffffc097          	auipc	ra,0xffffc
    8000548a:	9ac080e7          	jalr	-1620(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000548e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005492:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005496:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000549a:	058ab783          	ld	a5,88(s5)
    8000549e:	e6843703          	ld	a4,-408(s0)
    800054a2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800054a4:	058ab783          	ld	a5,88(s5)
    800054a8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054ac:	85ea                	mv	a1,s10
    800054ae:	ffffd097          	auipc	ra,0xffffd
    800054b2:	aac080e7          	jalr	-1364(ra) # 80001f5a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800054b6:	0004851b          	sext.w	a0,s1
    800054ba:	bbe1                	j	80005292 <exec+0x98>
    800054bc:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800054c0:	e0843583          	ld	a1,-504(s0)
    800054c4:	855e                	mv	a0,s7
    800054c6:	ffffd097          	auipc	ra,0xffffd
    800054ca:	a94080e7          	jalr	-1388(ra) # 80001f5a <proc_freepagetable>
  if(ip){
    800054ce:	da0498e3          	bnez	s1,8000527e <exec+0x84>
  return -1;
    800054d2:	557d                	li	a0,-1
    800054d4:	bb7d                	j	80005292 <exec+0x98>
    800054d6:	e1243423          	sd	s2,-504(s0)
    800054da:	b7dd                	j	800054c0 <exec+0x2c6>
    800054dc:	e1243423          	sd	s2,-504(s0)
    800054e0:	b7c5                	j	800054c0 <exec+0x2c6>
    800054e2:	e1243423          	sd	s2,-504(s0)
    800054e6:	bfe9                	j	800054c0 <exec+0x2c6>
  sz = sz1;
    800054e8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054ec:	4481                	li	s1,0
    800054ee:	bfc9                	j	800054c0 <exec+0x2c6>
  sz = sz1;
    800054f0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054f4:	4481                	li	s1,0
    800054f6:	b7e9                	j	800054c0 <exec+0x2c6>
  sz = sz1;
    800054f8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054fc:	4481                	li	s1,0
    800054fe:	b7c9                	j	800054c0 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005500:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005504:	2b05                	addiw	s6,s6,1
    80005506:	0389899b          	addiw	s3,s3,56
    8000550a:	e8845783          	lhu	a5,-376(s0)
    8000550e:	e2fb5be3          	bge	s6,a5,80005344 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005512:	2981                	sext.w	s3,s3
    80005514:	03800713          	li	a4,56
    80005518:	86ce                	mv	a3,s3
    8000551a:	e1840613          	addi	a2,s0,-488
    8000551e:	4581                	li	a1,0
    80005520:	8526                	mv	a0,s1
    80005522:	fffff097          	auipc	ra,0xfffff
    80005526:	a8e080e7          	jalr	-1394(ra) # 80003fb0 <readi>
    8000552a:	03800793          	li	a5,56
    8000552e:	f8f517e3          	bne	a0,a5,800054bc <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005532:	e1842783          	lw	a5,-488(s0)
    80005536:	4705                	li	a4,1
    80005538:	fce796e3          	bne	a5,a4,80005504 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000553c:	e4043603          	ld	a2,-448(s0)
    80005540:	e3843783          	ld	a5,-456(s0)
    80005544:	f8f669e3          	bltu	a2,a5,800054d6 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005548:	e2843783          	ld	a5,-472(s0)
    8000554c:	963e                	add	a2,a2,a5
    8000554e:	f8f667e3          	bltu	a2,a5,800054dc <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005552:	85ca                	mv	a1,s2
    80005554:	855e                	mv	a0,s7
    80005556:	ffffc097          	auipc	ra,0xffffc
    8000555a:	ecc080e7          	jalr	-308(ra) # 80001422 <uvmalloc>
    8000555e:	e0a43423          	sd	a0,-504(s0)
    80005562:	d141                	beqz	a0,800054e2 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005564:	e2843d03          	ld	s10,-472(s0)
    80005568:	df043783          	ld	a5,-528(s0)
    8000556c:	00fd77b3          	and	a5,s10,a5
    80005570:	fba1                	bnez	a5,800054c0 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005572:	e2042d83          	lw	s11,-480(s0)
    80005576:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000557a:	f80c03e3          	beqz	s8,80005500 <exec+0x306>
    8000557e:	8a62                	mv	s4,s8
    80005580:	4901                	li	s2,0
    80005582:	b345                	j	80005322 <exec+0x128>

0000000080005584 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005584:	7179                	addi	sp,sp,-48
    80005586:	f406                	sd	ra,40(sp)
    80005588:	f022                	sd	s0,32(sp)
    8000558a:	ec26                	sd	s1,24(sp)
    8000558c:	e84a                	sd	s2,16(sp)
    8000558e:	1800                	addi	s0,sp,48
    80005590:	892e                	mv	s2,a1
    80005592:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005594:	fdc40593          	addi	a1,s0,-36
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	bf2080e7          	jalr	-1038(ra) # 8000318a <argint>
    800055a0:	04054063          	bltz	a0,800055e0 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800055a4:	fdc42703          	lw	a4,-36(s0)
    800055a8:	47bd                	li	a5,15
    800055aa:	02e7ed63          	bltu	a5,a4,800055e4 <argfd+0x60>
    800055ae:	ffffd097          	auipc	ra,0xffffd
    800055b2:	852080e7          	jalr	-1966(ra) # 80001e00 <myproc>
    800055b6:	fdc42703          	lw	a4,-36(s0)
    800055ba:	01a70793          	addi	a5,a4,26
    800055be:	078e                	slli	a5,a5,0x3
    800055c0:	953e                	add	a0,a0,a5
    800055c2:	611c                	ld	a5,0(a0)
    800055c4:	c395                	beqz	a5,800055e8 <argfd+0x64>
    return -1;
  if(pfd)
    800055c6:	00090463          	beqz	s2,800055ce <argfd+0x4a>
    *pfd = fd;
    800055ca:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800055ce:	4501                	li	a0,0
  if(pf)
    800055d0:	c091                	beqz	s1,800055d4 <argfd+0x50>
    *pf = f;
    800055d2:	e09c                	sd	a5,0(s1)
}
    800055d4:	70a2                	ld	ra,40(sp)
    800055d6:	7402                	ld	s0,32(sp)
    800055d8:	64e2                	ld	s1,24(sp)
    800055da:	6942                	ld	s2,16(sp)
    800055dc:	6145                	addi	sp,sp,48
    800055de:	8082                	ret
    return -1;
    800055e0:	557d                	li	a0,-1
    800055e2:	bfcd                	j	800055d4 <argfd+0x50>
    return -1;
    800055e4:	557d                	li	a0,-1
    800055e6:	b7fd                	j	800055d4 <argfd+0x50>
    800055e8:	557d                	li	a0,-1
    800055ea:	b7ed                	j	800055d4 <argfd+0x50>

00000000800055ec <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800055ec:	1101                	addi	sp,sp,-32
    800055ee:	ec06                	sd	ra,24(sp)
    800055f0:	e822                	sd	s0,16(sp)
    800055f2:	e426                	sd	s1,8(sp)
    800055f4:	1000                	addi	s0,sp,32
    800055f6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800055f8:	ffffd097          	auipc	ra,0xffffd
    800055fc:	808080e7          	jalr	-2040(ra) # 80001e00 <myproc>
    80005600:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005602:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005606:	4501                	li	a0,0
    80005608:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000560a:	6398                	ld	a4,0(a5)
    8000560c:	cb19                	beqz	a4,80005622 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000560e:	2505                	addiw	a0,a0,1
    80005610:	07a1                	addi	a5,a5,8
    80005612:	fed51ce3          	bne	a0,a3,8000560a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005616:	557d                	li	a0,-1
}
    80005618:	60e2                	ld	ra,24(sp)
    8000561a:	6442                	ld	s0,16(sp)
    8000561c:	64a2                	ld	s1,8(sp)
    8000561e:	6105                	addi	sp,sp,32
    80005620:	8082                	ret
      p->ofile[fd] = f;
    80005622:	01a50793          	addi	a5,a0,26
    80005626:	078e                	slli	a5,a5,0x3
    80005628:	963e                	add	a2,a2,a5
    8000562a:	e204                	sd	s1,0(a2)
      return fd;
    8000562c:	b7f5                	j	80005618 <fdalloc+0x2c>

000000008000562e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000562e:	715d                	addi	sp,sp,-80
    80005630:	e486                	sd	ra,72(sp)
    80005632:	e0a2                	sd	s0,64(sp)
    80005634:	fc26                	sd	s1,56(sp)
    80005636:	f84a                	sd	s2,48(sp)
    80005638:	f44e                	sd	s3,40(sp)
    8000563a:	f052                	sd	s4,32(sp)
    8000563c:	ec56                	sd	s5,24(sp)
    8000563e:	0880                	addi	s0,sp,80
    80005640:	89ae                	mv	s3,a1
    80005642:	8ab2                	mv	s5,a2
    80005644:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005646:	fb040593          	addi	a1,s0,-80
    8000564a:	fffff097          	auipc	ra,0xfffff
    8000564e:	e86080e7          	jalr	-378(ra) # 800044d0 <nameiparent>
    80005652:	892a                	mv	s2,a0
    80005654:	12050f63          	beqz	a0,80005792 <create+0x164>
    return 0;

  ilock(dp);
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	6a4080e7          	jalr	1700(ra) # 80003cfc <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005660:	4601                	li	a2,0
    80005662:	fb040593          	addi	a1,s0,-80
    80005666:	854a                	mv	a0,s2
    80005668:	fffff097          	auipc	ra,0xfffff
    8000566c:	b78080e7          	jalr	-1160(ra) # 800041e0 <dirlookup>
    80005670:	84aa                	mv	s1,a0
    80005672:	c921                	beqz	a0,800056c2 <create+0x94>
    iunlockput(dp);
    80005674:	854a                	mv	a0,s2
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	8e8080e7          	jalr	-1816(ra) # 80003f5e <iunlockput>
    ilock(ip);
    8000567e:	8526                	mv	a0,s1
    80005680:	ffffe097          	auipc	ra,0xffffe
    80005684:	67c080e7          	jalr	1660(ra) # 80003cfc <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005688:	2981                	sext.w	s3,s3
    8000568a:	4789                	li	a5,2
    8000568c:	02f99463          	bne	s3,a5,800056b4 <create+0x86>
    80005690:	0444d783          	lhu	a5,68(s1)
    80005694:	37f9                	addiw	a5,a5,-2
    80005696:	17c2                	slli	a5,a5,0x30
    80005698:	93c1                	srli	a5,a5,0x30
    8000569a:	4705                	li	a4,1
    8000569c:	00f76c63          	bltu	a4,a5,800056b4 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800056a0:	8526                	mv	a0,s1
    800056a2:	60a6                	ld	ra,72(sp)
    800056a4:	6406                	ld	s0,64(sp)
    800056a6:	74e2                	ld	s1,56(sp)
    800056a8:	7942                	ld	s2,48(sp)
    800056aa:	79a2                	ld	s3,40(sp)
    800056ac:	7a02                	ld	s4,32(sp)
    800056ae:	6ae2                	ld	s5,24(sp)
    800056b0:	6161                	addi	sp,sp,80
    800056b2:	8082                	ret
    iunlockput(ip);
    800056b4:	8526                	mv	a0,s1
    800056b6:	fffff097          	auipc	ra,0xfffff
    800056ba:	8a8080e7          	jalr	-1880(ra) # 80003f5e <iunlockput>
    return 0;
    800056be:	4481                	li	s1,0
    800056c0:	b7c5                	j	800056a0 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800056c2:	85ce                	mv	a1,s3
    800056c4:	00092503          	lw	a0,0(s2)
    800056c8:	ffffe097          	auipc	ra,0xffffe
    800056cc:	49c080e7          	jalr	1180(ra) # 80003b64 <ialloc>
    800056d0:	84aa                	mv	s1,a0
    800056d2:	c529                	beqz	a0,8000571c <create+0xee>
  ilock(ip);
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	628080e7          	jalr	1576(ra) # 80003cfc <ilock>
  ip->major = major;
    800056dc:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800056e0:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800056e4:	4785                	li	a5,1
    800056e6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056ea:	8526                	mv	a0,s1
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	546080e7          	jalr	1350(ra) # 80003c32 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800056f4:	2981                	sext.w	s3,s3
    800056f6:	4785                	li	a5,1
    800056f8:	02f98a63          	beq	s3,a5,8000572c <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800056fc:	40d0                	lw	a2,4(s1)
    800056fe:	fb040593          	addi	a1,s0,-80
    80005702:	854a                	mv	a0,s2
    80005704:	fffff097          	auipc	ra,0xfffff
    80005708:	cec080e7          	jalr	-788(ra) # 800043f0 <dirlink>
    8000570c:	06054b63          	bltz	a0,80005782 <create+0x154>
  iunlockput(dp);
    80005710:	854a                	mv	a0,s2
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	84c080e7          	jalr	-1972(ra) # 80003f5e <iunlockput>
  return ip;
    8000571a:	b759                	j	800056a0 <create+0x72>
    panic("create: ialloc");
    8000571c:	00003517          	auipc	a0,0x3
    80005720:	07450513          	addi	a0,a0,116 # 80008790 <syscalls+0x2a0>
    80005724:	ffffb097          	auipc	ra,0xffffb
    80005728:	e1a080e7          	jalr	-486(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000572c:	04a95783          	lhu	a5,74(s2)
    80005730:	2785                	addiw	a5,a5,1
    80005732:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005736:	854a                	mv	a0,s2
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	4fa080e7          	jalr	1274(ra) # 80003c32 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005740:	40d0                	lw	a2,4(s1)
    80005742:	00003597          	auipc	a1,0x3
    80005746:	05e58593          	addi	a1,a1,94 # 800087a0 <syscalls+0x2b0>
    8000574a:	8526                	mv	a0,s1
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	ca4080e7          	jalr	-860(ra) # 800043f0 <dirlink>
    80005754:	00054f63          	bltz	a0,80005772 <create+0x144>
    80005758:	00492603          	lw	a2,4(s2)
    8000575c:	00003597          	auipc	a1,0x3
    80005760:	04c58593          	addi	a1,a1,76 # 800087a8 <syscalls+0x2b8>
    80005764:	8526                	mv	a0,s1
    80005766:	fffff097          	auipc	ra,0xfffff
    8000576a:	c8a080e7          	jalr	-886(ra) # 800043f0 <dirlink>
    8000576e:	f80557e3          	bgez	a0,800056fc <create+0xce>
      panic("create dots");
    80005772:	00003517          	auipc	a0,0x3
    80005776:	03e50513          	addi	a0,a0,62 # 800087b0 <syscalls+0x2c0>
    8000577a:	ffffb097          	auipc	ra,0xffffb
    8000577e:	dc4080e7          	jalr	-572(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005782:	00003517          	auipc	a0,0x3
    80005786:	03e50513          	addi	a0,a0,62 # 800087c0 <syscalls+0x2d0>
    8000578a:	ffffb097          	auipc	ra,0xffffb
    8000578e:	db4080e7          	jalr	-588(ra) # 8000053e <panic>
    return 0;
    80005792:	84aa                	mv	s1,a0
    80005794:	b731                	j	800056a0 <create+0x72>

0000000080005796 <sys_dup>:
{
    80005796:	7179                	addi	sp,sp,-48
    80005798:	f406                	sd	ra,40(sp)
    8000579a:	f022                	sd	s0,32(sp)
    8000579c:	ec26                	sd	s1,24(sp)
    8000579e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800057a0:	fd840613          	addi	a2,s0,-40
    800057a4:	4581                	li	a1,0
    800057a6:	4501                	li	a0,0
    800057a8:	00000097          	auipc	ra,0x0
    800057ac:	ddc080e7          	jalr	-548(ra) # 80005584 <argfd>
    return -1;
    800057b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800057b2:	02054363          	bltz	a0,800057d8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800057b6:	fd843503          	ld	a0,-40(s0)
    800057ba:	00000097          	auipc	ra,0x0
    800057be:	e32080e7          	jalr	-462(ra) # 800055ec <fdalloc>
    800057c2:	84aa                	mv	s1,a0
    return -1;
    800057c4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800057c6:	00054963          	bltz	a0,800057d8 <sys_dup+0x42>
  filedup(f);
    800057ca:	fd843503          	ld	a0,-40(s0)
    800057ce:	fffff097          	auipc	ra,0xfffff
    800057d2:	37a080e7          	jalr	890(ra) # 80004b48 <filedup>
  return fd;
    800057d6:	87a6                	mv	a5,s1
}
    800057d8:	853e                	mv	a0,a5
    800057da:	70a2                	ld	ra,40(sp)
    800057dc:	7402                	ld	s0,32(sp)
    800057de:	64e2                	ld	s1,24(sp)
    800057e0:	6145                	addi	sp,sp,48
    800057e2:	8082                	ret

00000000800057e4 <sys_read>:
{
    800057e4:	7179                	addi	sp,sp,-48
    800057e6:	f406                	sd	ra,40(sp)
    800057e8:	f022                	sd	s0,32(sp)
    800057ea:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057ec:	fe840613          	addi	a2,s0,-24
    800057f0:	4581                	li	a1,0
    800057f2:	4501                	li	a0,0
    800057f4:	00000097          	auipc	ra,0x0
    800057f8:	d90080e7          	jalr	-624(ra) # 80005584 <argfd>
    return -1;
    800057fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057fe:	04054163          	bltz	a0,80005840 <sys_read+0x5c>
    80005802:	fe440593          	addi	a1,s0,-28
    80005806:	4509                	li	a0,2
    80005808:	ffffe097          	auipc	ra,0xffffe
    8000580c:	982080e7          	jalr	-1662(ra) # 8000318a <argint>
    return -1;
    80005810:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005812:	02054763          	bltz	a0,80005840 <sys_read+0x5c>
    80005816:	fd840593          	addi	a1,s0,-40
    8000581a:	4505                	li	a0,1
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	990080e7          	jalr	-1648(ra) # 800031ac <argaddr>
    return -1;
    80005824:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005826:	00054d63          	bltz	a0,80005840 <sys_read+0x5c>
  return fileread(f, p, n);
    8000582a:	fe442603          	lw	a2,-28(s0)
    8000582e:	fd843583          	ld	a1,-40(s0)
    80005832:	fe843503          	ld	a0,-24(s0)
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	49e080e7          	jalr	1182(ra) # 80004cd4 <fileread>
    8000583e:	87aa                	mv	a5,a0
}
    80005840:	853e                	mv	a0,a5
    80005842:	70a2                	ld	ra,40(sp)
    80005844:	7402                	ld	s0,32(sp)
    80005846:	6145                	addi	sp,sp,48
    80005848:	8082                	ret

000000008000584a <sys_write>:
{
    8000584a:	7179                	addi	sp,sp,-48
    8000584c:	f406                	sd	ra,40(sp)
    8000584e:	f022                	sd	s0,32(sp)
    80005850:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005852:	fe840613          	addi	a2,s0,-24
    80005856:	4581                	li	a1,0
    80005858:	4501                	li	a0,0
    8000585a:	00000097          	auipc	ra,0x0
    8000585e:	d2a080e7          	jalr	-726(ra) # 80005584 <argfd>
    return -1;
    80005862:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005864:	04054163          	bltz	a0,800058a6 <sys_write+0x5c>
    80005868:	fe440593          	addi	a1,s0,-28
    8000586c:	4509                	li	a0,2
    8000586e:	ffffe097          	auipc	ra,0xffffe
    80005872:	91c080e7          	jalr	-1764(ra) # 8000318a <argint>
    return -1;
    80005876:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005878:	02054763          	bltz	a0,800058a6 <sys_write+0x5c>
    8000587c:	fd840593          	addi	a1,s0,-40
    80005880:	4505                	li	a0,1
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	92a080e7          	jalr	-1750(ra) # 800031ac <argaddr>
    return -1;
    8000588a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000588c:	00054d63          	bltz	a0,800058a6 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005890:	fe442603          	lw	a2,-28(s0)
    80005894:	fd843583          	ld	a1,-40(s0)
    80005898:	fe843503          	ld	a0,-24(s0)
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	4fa080e7          	jalr	1274(ra) # 80004d96 <filewrite>
    800058a4:	87aa                	mv	a5,a0
}
    800058a6:	853e                	mv	a0,a5
    800058a8:	70a2                	ld	ra,40(sp)
    800058aa:	7402                	ld	s0,32(sp)
    800058ac:	6145                	addi	sp,sp,48
    800058ae:	8082                	ret

00000000800058b0 <sys_close>:
{
    800058b0:	1101                	addi	sp,sp,-32
    800058b2:	ec06                	sd	ra,24(sp)
    800058b4:	e822                	sd	s0,16(sp)
    800058b6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800058b8:	fe040613          	addi	a2,s0,-32
    800058bc:	fec40593          	addi	a1,s0,-20
    800058c0:	4501                	li	a0,0
    800058c2:	00000097          	auipc	ra,0x0
    800058c6:	cc2080e7          	jalr	-830(ra) # 80005584 <argfd>
    return -1;
    800058ca:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800058cc:	02054463          	bltz	a0,800058f4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800058d0:	ffffc097          	auipc	ra,0xffffc
    800058d4:	530080e7          	jalr	1328(ra) # 80001e00 <myproc>
    800058d8:	fec42783          	lw	a5,-20(s0)
    800058dc:	07e9                	addi	a5,a5,26
    800058de:	078e                	slli	a5,a5,0x3
    800058e0:	97aa                	add	a5,a5,a0
    800058e2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800058e6:	fe043503          	ld	a0,-32(s0)
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	2b0080e7          	jalr	688(ra) # 80004b9a <fileclose>
  return 0;
    800058f2:	4781                	li	a5,0
}
    800058f4:	853e                	mv	a0,a5
    800058f6:	60e2                	ld	ra,24(sp)
    800058f8:	6442                	ld	s0,16(sp)
    800058fa:	6105                	addi	sp,sp,32
    800058fc:	8082                	ret

00000000800058fe <sys_fstat>:
{
    800058fe:	1101                	addi	sp,sp,-32
    80005900:	ec06                	sd	ra,24(sp)
    80005902:	e822                	sd	s0,16(sp)
    80005904:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005906:	fe840613          	addi	a2,s0,-24
    8000590a:	4581                	li	a1,0
    8000590c:	4501                	li	a0,0
    8000590e:	00000097          	auipc	ra,0x0
    80005912:	c76080e7          	jalr	-906(ra) # 80005584 <argfd>
    return -1;
    80005916:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005918:	02054563          	bltz	a0,80005942 <sys_fstat+0x44>
    8000591c:	fe040593          	addi	a1,s0,-32
    80005920:	4505                	li	a0,1
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	88a080e7          	jalr	-1910(ra) # 800031ac <argaddr>
    return -1;
    8000592a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000592c:	00054b63          	bltz	a0,80005942 <sys_fstat+0x44>
  return filestat(f, st);
    80005930:	fe043583          	ld	a1,-32(s0)
    80005934:	fe843503          	ld	a0,-24(s0)
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	32a080e7          	jalr	810(ra) # 80004c62 <filestat>
    80005940:	87aa                	mv	a5,a0
}
    80005942:	853e                	mv	a0,a5
    80005944:	60e2                	ld	ra,24(sp)
    80005946:	6442                	ld	s0,16(sp)
    80005948:	6105                	addi	sp,sp,32
    8000594a:	8082                	ret

000000008000594c <sys_link>:
{
    8000594c:	7169                	addi	sp,sp,-304
    8000594e:	f606                	sd	ra,296(sp)
    80005950:	f222                	sd	s0,288(sp)
    80005952:	ee26                	sd	s1,280(sp)
    80005954:	ea4a                	sd	s2,272(sp)
    80005956:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005958:	08000613          	li	a2,128
    8000595c:	ed040593          	addi	a1,s0,-304
    80005960:	4501                	li	a0,0
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	86c080e7          	jalr	-1940(ra) # 800031ce <argstr>
    return -1;
    8000596a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000596c:	10054e63          	bltz	a0,80005a88 <sys_link+0x13c>
    80005970:	08000613          	li	a2,128
    80005974:	f5040593          	addi	a1,s0,-176
    80005978:	4505                	li	a0,1
    8000597a:	ffffe097          	auipc	ra,0xffffe
    8000597e:	854080e7          	jalr	-1964(ra) # 800031ce <argstr>
    return -1;
    80005982:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005984:	10054263          	bltz	a0,80005a88 <sys_link+0x13c>
  begin_op();
    80005988:	fffff097          	auipc	ra,0xfffff
    8000598c:	d46080e7          	jalr	-698(ra) # 800046ce <begin_op>
  if((ip = namei(old)) == 0){
    80005990:	ed040513          	addi	a0,s0,-304
    80005994:	fffff097          	auipc	ra,0xfffff
    80005998:	b1e080e7          	jalr	-1250(ra) # 800044b2 <namei>
    8000599c:	84aa                	mv	s1,a0
    8000599e:	c551                	beqz	a0,80005a2a <sys_link+0xde>
  ilock(ip);
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	35c080e7          	jalr	860(ra) # 80003cfc <ilock>
  if(ip->type == T_DIR){
    800059a8:	04449703          	lh	a4,68(s1)
    800059ac:	4785                	li	a5,1
    800059ae:	08f70463          	beq	a4,a5,80005a36 <sys_link+0xea>
  ip->nlink++;
    800059b2:	04a4d783          	lhu	a5,74(s1)
    800059b6:	2785                	addiw	a5,a5,1
    800059b8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059bc:	8526                	mv	a0,s1
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	274080e7          	jalr	628(ra) # 80003c32 <iupdate>
  iunlock(ip);
    800059c6:	8526                	mv	a0,s1
    800059c8:	ffffe097          	auipc	ra,0xffffe
    800059cc:	3f6080e7          	jalr	1014(ra) # 80003dbe <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800059d0:	fd040593          	addi	a1,s0,-48
    800059d4:	f5040513          	addi	a0,s0,-176
    800059d8:	fffff097          	auipc	ra,0xfffff
    800059dc:	af8080e7          	jalr	-1288(ra) # 800044d0 <nameiparent>
    800059e0:	892a                	mv	s2,a0
    800059e2:	c935                	beqz	a0,80005a56 <sys_link+0x10a>
  ilock(dp);
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	318080e7          	jalr	792(ra) # 80003cfc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800059ec:	00092703          	lw	a4,0(s2)
    800059f0:	409c                	lw	a5,0(s1)
    800059f2:	04f71d63          	bne	a4,a5,80005a4c <sys_link+0x100>
    800059f6:	40d0                	lw	a2,4(s1)
    800059f8:	fd040593          	addi	a1,s0,-48
    800059fc:	854a                	mv	a0,s2
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	9f2080e7          	jalr	-1550(ra) # 800043f0 <dirlink>
    80005a06:	04054363          	bltz	a0,80005a4c <sys_link+0x100>
  iunlockput(dp);
    80005a0a:	854a                	mv	a0,s2
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	552080e7          	jalr	1362(ra) # 80003f5e <iunlockput>
  iput(ip);
    80005a14:	8526                	mv	a0,s1
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	4a0080e7          	jalr	1184(ra) # 80003eb6 <iput>
  end_op();
    80005a1e:	fffff097          	auipc	ra,0xfffff
    80005a22:	d30080e7          	jalr	-720(ra) # 8000474e <end_op>
  return 0;
    80005a26:	4781                	li	a5,0
    80005a28:	a085                	j	80005a88 <sys_link+0x13c>
    end_op();
    80005a2a:	fffff097          	auipc	ra,0xfffff
    80005a2e:	d24080e7          	jalr	-732(ra) # 8000474e <end_op>
    return -1;
    80005a32:	57fd                	li	a5,-1
    80005a34:	a891                	j	80005a88 <sys_link+0x13c>
    iunlockput(ip);
    80005a36:	8526                	mv	a0,s1
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	526080e7          	jalr	1318(ra) # 80003f5e <iunlockput>
    end_op();
    80005a40:	fffff097          	auipc	ra,0xfffff
    80005a44:	d0e080e7          	jalr	-754(ra) # 8000474e <end_op>
    return -1;
    80005a48:	57fd                	li	a5,-1
    80005a4a:	a83d                	j	80005a88 <sys_link+0x13c>
    iunlockput(dp);
    80005a4c:	854a                	mv	a0,s2
    80005a4e:	ffffe097          	auipc	ra,0xffffe
    80005a52:	510080e7          	jalr	1296(ra) # 80003f5e <iunlockput>
  ilock(ip);
    80005a56:	8526                	mv	a0,s1
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	2a4080e7          	jalr	676(ra) # 80003cfc <ilock>
  ip->nlink--;
    80005a60:	04a4d783          	lhu	a5,74(s1)
    80005a64:	37fd                	addiw	a5,a5,-1
    80005a66:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a6a:	8526                	mv	a0,s1
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	1c6080e7          	jalr	454(ra) # 80003c32 <iupdate>
  iunlockput(ip);
    80005a74:	8526                	mv	a0,s1
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	4e8080e7          	jalr	1256(ra) # 80003f5e <iunlockput>
  end_op();
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	cd0080e7          	jalr	-816(ra) # 8000474e <end_op>
  return -1;
    80005a86:	57fd                	li	a5,-1
}
    80005a88:	853e                	mv	a0,a5
    80005a8a:	70b2                	ld	ra,296(sp)
    80005a8c:	7412                	ld	s0,288(sp)
    80005a8e:	64f2                	ld	s1,280(sp)
    80005a90:	6952                	ld	s2,272(sp)
    80005a92:	6155                	addi	sp,sp,304
    80005a94:	8082                	ret

0000000080005a96 <sys_unlink>:
{
    80005a96:	7151                	addi	sp,sp,-240
    80005a98:	f586                	sd	ra,232(sp)
    80005a9a:	f1a2                	sd	s0,224(sp)
    80005a9c:	eda6                	sd	s1,216(sp)
    80005a9e:	e9ca                	sd	s2,208(sp)
    80005aa0:	e5ce                	sd	s3,200(sp)
    80005aa2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005aa4:	08000613          	li	a2,128
    80005aa8:	f3040593          	addi	a1,s0,-208
    80005aac:	4501                	li	a0,0
    80005aae:	ffffd097          	auipc	ra,0xffffd
    80005ab2:	720080e7          	jalr	1824(ra) # 800031ce <argstr>
    80005ab6:	18054163          	bltz	a0,80005c38 <sys_unlink+0x1a2>
  begin_op();
    80005aba:	fffff097          	auipc	ra,0xfffff
    80005abe:	c14080e7          	jalr	-1004(ra) # 800046ce <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005ac2:	fb040593          	addi	a1,s0,-80
    80005ac6:	f3040513          	addi	a0,s0,-208
    80005aca:	fffff097          	auipc	ra,0xfffff
    80005ace:	a06080e7          	jalr	-1530(ra) # 800044d0 <nameiparent>
    80005ad2:	84aa                	mv	s1,a0
    80005ad4:	c979                	beqz	a0,80005baa <sys_unlink+0x114>
  ilock(dp);
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	226080e7          	jalr	550(ra) # 80003cfc <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005ade:	00003597          	auipc	a1,0x3
    80005ae2:	cc258593          	addi	a1,a1,-830 # 800087a0 <syscalls+0x2b0>
    80005ae6:	fb040513          	addi	a0,s0,-80
    80005aea:	ffffe097          	auipc	ra,0xffffe
    80005aee:	6dc080e7          	jalr	1756(ra) # 800041c6 <namecmp>
    80005af2:	14050a63          	beqz	a0,80005c46 <sys_unlink+0x1b0>
    80005af6:	00003597          	auipc	a1,0x3
    80005afa:	cb258593          	addi	a1,a1,-846 # 800087a8 <syscalls+0x2b8>
    80005afe:	fb040513          	addi	a0,s0,-80
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	6c4080e7          	jalr	1732(ra) # 800041c6 <namecmp>
    80005b0a:	12050e63          	beqz	a0,80005c46 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b0e:	f2c40613          	addi	a2,s0,-212
    80005b12:	fb040593          	addi	a1,s0,-80
    80005b16:	8526                	mv	a0,s1
    80005b18:	ffffe097          	auipc	ra,0xffffe
    80005b1c:	6c8080e7          	jalr	1736(ra) # 800041e0 <dirlookup>
    80005b20:	892a                	mv	s2,a0
    80005b22:	12050263          	beqz	a0,80005c46 <sys_unlink+0x1b0>
  ilock(ip);
    80005b26:	ffffe097          	auipc	ra,0xffffe
    80005b2a:	1d6080e7          	jalr	470(ra) # 80003cfc <ilock>
  if(ip->nlink < 1)
    80005b2e:	04a91783          	lh	a5,74(s2)
    80005b32:	08f05263          	blez	a5,80005bb6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b36:	04491703          	lh	a4,68(s2)
    80005b3a:	4785                	li	a5,1
    80005b3c:	08f70563          	beq	a4,a5,80005bc6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b40:	4641                	li	a2,16
    80005b42:	4581                	li	a1,0
    80005b44:	fc040513          	addi	a0,s0,-64
    80005b48:	ffffb097          	auipc	ra,0xffffb
    80005b4c:	198080e7          	jalr	408(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b50:	4741                	li	a4,16
    80005b52:	f2c42683          	lw	a3,-212(s0)
    80005b56:	fc040613          	addi	a2,s0,-64
    80005b5a:	4581                	li	a1,0
    80005b5c:	8526                	mv	a0,s1
    80005b5e:	ffffe097          	auipc	ra,0xffffe
    80005b62:	54a080e7          	jalr	1354(ra) # 800040a8 <writei>
    80005b66:	47c1                	li	a5,16
    80005b68:	0af51563          	bne	a0,a5,80005c12 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b6c:	04491703          	lh	a4,68(s2)
    80005b70:	4785                	li	a5,1
    80005b72:	0af70863          	beq	a4,a5,80005c22 <sys_unlink+0x18c>
  iunlockput(dp);
    80005b76:	8526                	mv	a0,s1
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	3e6080e7          	jalr	998(ra) # 80003f5e <iunlockput>
  ip->nlink--;
    80005b80:	04a95783          	lhu	a5,74(s2)
    80005b84:	37fd                	addiw	a5,a5,-1
    80005b86:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b8a:	854a                	mv	a0,s2
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	0a6080e7          	jalr	166(ra) # 80003c32 <iupdate>
  iunlockput(ip);
    80005b94:	854a                	mv	a0,s2
    80005b96:	ffffe097          	auipc	ra,0xffffe
    80005b9a:	3c8080e7          	jalr	968(ra) # 80003f5e <iunlockput>
  end_op();
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	bb0080e7          	jalr	-1104(ra) # 8000474e <end_op>
  return 0;
    80005ba6:	4501                	li	a0,0
    80005ba8:	a84d                	j	80005c5a <sys_unlink+0x1c4>
    end_op();
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	ba4080e7          	jalr	-1116(ra) # 8000474e <end_op>
    return -1;
    80005bb2:	557d                	li	a0,-1
    80005bb4:	a05d                	j	80005c5a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005bb6:	00003517          	auipc	a0,0x3
    80005bba:	c1a50513          	addi	a0,a0,-998 # 800087d0 <syscalls+0x2e0>
    80005bbe:	ffffb097          	auipc	ra,0xffffb
    80005bc2:	980080e7          	jalr	-1664(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bc6:	04c92703          	lw	a4,76(s2)
    80005bca:	02000793          	li	a5,32
    80005bce:	f6e7f9e3          	bgeu	a5,a4,80005b40 <sys_unlink+0xaa>
    80005bd2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005bd6:	4741                	li	a4,16
    80005bd8:	86ce                	mv	a3,s3
    80005bda:	f1840613          	addi	a2,s0,-232
    80005bde:	4581                	li	a1,0
    80005be0:	854a                	mv	a0,s2
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	3ce080e7          	jalr	974(ra) # 80003fb0 <readi>
    80005bea:	47c1                	li	a5,16
    80005bec:	00f51b63          	bne	a0,a5,80005c02 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005bf0:	f1845783          	lhu	a5,-232(s0)
    80005bf4:	e7a1                	bnez	a5,80005c3c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bf6:	29c1                	addiw	s3,s3,16
    80005bf8:	04c92783          	lw	a5,76(s2)
    80005bfc:	fcf9ede3          	bltu	s3,a5,80005bd6 <sys_unlink+0x140>
    80005c00:	b781                	j	80005b40 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c02:	00003517          	auipc	a0,0x3
    80005c06:	be650513          	addi	a0,a0,-1050 # 800087e8 <syscalls+0x2f8>
    80005c0a:	ffffb097          	auipc	ra,0xffffb
    80005c0e:	934080e7          	jalr	-1740(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005c12:	00003517          	auipc	a0,0x3
    80005c16:	bee50513          	addi	a0,a0,-1042 # 80008800 <syscalls+0x310>
    80005c1a:	ffffb097          	auipc	ra,0xffffb
    80005c1e:	924080e7          	jalr	-1756(ra) # 8000053e <panic>
    dp->nlink--;
    80005c22:	04a4d783          	lhu	a5,74(s1)
    80005c26:	37fd                	addiw	a5,a5,-1
    80005c28:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c2c:	8526                	mv	a0,s1
    80005c2e:	ffffe097          	auipc	ra,0xffffe
    80005c32:	004080e7          	jalr	4(ra) # 80003c32 <iupdate>
    80005c36:	b781                	j	80005b76 <sys_unlink+0xe0>
    return -1;
    80005c38:	557d                	li	a0,-1
    80005c3a:	a005                	j	80005c5a <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c3c:	854a                	mv	a0,s2
    80005c3e:	ffffe097          	auipc	ra,0xffffe
    80005c42:	320080e7          	jalr	800(ra) # 80003f5e <iunlockput>
  iunlockput(dp);
    80005c46:	8526                	mv	a0,s1
    80005c48:	ffffe097          	auipc	ra,0xffffe
    80005c4c:	316080e7          	jalr	790(ra) # 80003f5e <iunlockput>
  end_op();
    80005c50:	fffff097          	auipc	ra,0xfffff
    80005c54:	afe080e7          	jalr	-1282(ra) # 8000474e <end_op>
  return -1;
    80005c58:	557d                	li	a0,-1
}
    80005c5a:	70ae                	ld	ra,232(sp)
    80005c5c:	740e                	ld	s0,224(sp)
    80005c5e:	64ee                	ld	s1,216(sp)
    80005c60:	694e                	ld	s2,208(sp)
    80005c62:	69ae                	ld	s3,200(sp)
    80005c64:	616d                	addi	sp,sp,240
    80005c66:	8082                	ret

0000000080005c68 <sys_open>:

uint64
sys_open(void)
{
    80005c68:	7131                	addi	sp,sp,-192
    80005c6a:	fd06                	sd	ra,184(sp)
    80005c6c:	f922                	sd	s0,176(sp)
    80005c6e:	f526                	sd	s1,168(sp)
    80005c70:	f14a                	sd	s2,160(sp)
    80005c72:	ed4e                	sd	s3,152(sp)
    80005c74:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c76:	08000613          	li	a2,128
    80005c7a:	f5040593          	addi	a1,s0,-176
    80005c7e:	4501                	li	a0,0
    80005c80:	ffffd097          	auipc	ra,0xffffd
    80005c84:	54e080e7          	jalr	1358(ra) # 800031ce <argstr>
    return -1;
    80005c88:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c8a:	0c054163          	bltz	a0,80005d4c <sys_open+0xe4>
    80005c8e:	f4c40593          	addi	a1,s0,-180
    80005c92:	4505                	li	a0,1
    80005c94:	ffffd097          	auipc	ra,0xffffd
    80005c98:	4f6080e7          	jalr	1270(ra) # 8000318a <argint>
    80005c9c:	0a054863          	bltz	a0,80005d4c <sys_open+0xe4>

  begin_op();
    80005ca0:	fffff097          	auipc	ra,0xfffff
    80005ca4:	a2e080e7          	jalr	-1490(ra) # 800046ce <begin_op>

  if(omode & O_CREATE){
    80005ca8:	f4c42783          	lw	a5,-180(s0)
    80005cac:	2007f793          	andi	a5,a5,512
    80005cb0:	cbdd                	beqz	a5,80005d66 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005cb2:	4681                	li	a3,0
    80005cb4:	4601                	li	a2,0
    80005cb6:	4589                	li	a1,2
    80005cb8:	f5040513          	addi	a0,s0,-176
    80005cbc:	00000097          	auipc	ra,0x0
    80005cc0:	972080e7          	jalr	-1678(ra) # 8000562e <create>
    80005cc4:	892a                	mv	s2,a0
    if(ip == 0){
    80005cc6:	c959                	beqz	a0,80005d5c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005cc8:	04491703          	lh	a4,68(s2)
    80005ccc:	478d                	li	a5,3
    80005cce:	00f71763          	bne	a4,a5,80005cdc <sys_open+0x74>
    80005cd2:	04695703          	lhu	a4,70(s2)
    80005cd6:	47a5                	li	a5,9
    80005cd8:	0ce7ec63          	bltu	a5,a4,80005db0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005cdc:	fffff097          	auipc	ra,0xfffff
    80005ce0:	e02080e7          	jalr	-510(ra) # 80004ade <filealloc>
    80005ce4:	89aa                	mv	s3,a0
    80005ce6:	10050263          	beqz	a0,80005dea <sys_open+0x182>
    80005cea:	00000097          	auipc	ra,0x0
    80005cee:	902080e7          	jalr	-1790(ra) # 800055ec <fdalloc>
    80005cf2:	84aa                	mv	s1,a0
    80005cf4:	0e054663          	bltz	a0,80005de0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005cf8:	04491703          	lh	a4,68(s2)
    80005cfc:	478d                	li	a5,3
    80005cfe:	0cf70463          	beq	a4,a5,80005dc6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d02:	4789                	li	a5,2
    80005d04:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d08:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d0c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d10:	f4c42783          	lw	a5,-180(s0)
    80005d14:	0017c713          	xori	a4,a5,1
    80005d18:	8b05                	andi	a4,a4,1
    80005d1a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d1e:	0037f713          	andi	a4,a5,3
    80005d22:	00e03733          	snez	a4,a4
    80005d26:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d2a:	4007f793          	andi	a5,a5,1024
    80005d2e:	c791                	beqz	a5,80005d3a <sys_open+0xd2>
    80005d30:	04491703          	lh	a4,68(s2)
    80005d34:	4789                	li	a5,2
    80005d36:	08f70f63          	beq	a4,a5,80005dd4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d3a:	854a                	mv	a0,s2
    80005d3c:	ffffe097          	auipc	ra,0xffffe
    80005d40:	082080e7          	jalr	130(ra) # 80003dbe <iunlock>
  end_op();
    80005d44:	fffff097          	auipc	ra,0xfffff
    80005d48:	a0a080e7          	jalr	-1526(ra) # 8000474e <end_op>

  return fd;
}
    80005d4c:	8526                	mv	a0,s1
    80005d4e:	70ea                	ld	ra,184(sp)
    80005d50:	744a                	ld	s0,176(sp)
    80005d52:	74aa                	ld	s1,168(sp)
    80005d54:	790a                	ld	s2,160(sp)
    80005d56:	69ea                	ld	s3,152(sp)
    80005d58:	6129                	addi	sp,sp,192
    80005d5a:	8082                	ret
      end_op();
    80005d5c:	fffff097          	auipc	ra,0xfffff
    80005d60:	9f2080e7          	jalr	-1550(ra) # 8000474e <end_op>
      return -1;
    80005d64:	b7e5                	j	80005d4c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d66:	f5040513          	addi	a0,s0,-176
    80005d6a:	ffffe097          	auipc	ra,0xffffe
    80005d6e:	748080e7          	jalr	1864(ra) # 800044b2 <namei>
    80005d72:	892a                	mv	s2,a0
    80005d74:	c905                	beqz	a0,80005da4 <sys_open+0x13c>
    ilock(ip);
    80005d76:	ffffe097          	auipc	ra,0xffffe
    80005d7a:	f86080e7          	jalr	-122(ra) # 80003cfc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d7e:	04491703          	lh	a4,68(s2)
    80005d82:	4785                	li	a5,1
    80005d84:	f4f712e3          	bne	a4,a5,80005cc8 <sys_open+0x60>
    80005d88:	f4c42783          	lw	a5,-180(s0)
    80005d8c:	dba1                	beqz	a5,80005cdc <sys_open+0x74>
      iunlockput(ip);
    80005d8e:	854a                	mv	a0,s2
    80005d90:	ffffe097          	auipc	ra,0xffffe
    80005d94:	1ce080e7          	jalr	462(ra) # 80003f5e <iunlockput>
      end_op();
    80005d98:	fffff097          	auipc	ra,0xfffff
    80005d9c:	9b6080e7          	jalr	-1610(ra) # 8000474e <end_op>
      return -1;
    80005da0:	54fd                	li	s1,-1
    80005da2:	b76d                	j	80005d4c <sys_open+0xe4>
      end_op();
    80005da4:	fffff097          	auipc	ra,0xfffff
    80005da8:	9aa080e7          	jalr	-1622(ra) # 8000474e <end_op>
      return -1;
    80005dac:	54fd                	li	s1,-1
    80005dae:	bf79                	j	80005d4c <sys_open+0xe4>
    iunlockput(ip);
    80005db0:	854a                	mv	a0,s2
    80005db2:	ffffe097          	auipc	ra,0xffffe
    80005db6:	1ac080e7          	jalr	428(ra) # 80003f5e <iunlockput>
    end_op();
    80005dba:	fffff097          	auipc	ra,0xfffff
    80005dbe:	994080e7          	jalr	-1644(ra) # 8000474e <end_op>
    return -1;
    80005dc2:	54fd                	li	s1,-1
    80005dc4:	b761                	j	80005d4c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005dc6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005dca:	04691783          	lh	a5,70(s2)
    80005dce:	02f99223          	sh	a5,36(s3)
    80005dd2:	bf2d                	j	80005d0c <sys_open+0xa4>
    itrunc(ip);
    80005dd4:	854a                	mv	a0,s2
    80005dd6:	ffffe097          	auipc	ra,0xffffe
    80005dda:	034080e7          	jalr	52(ra) # 80003e0a <itrunc>
    80005dde:	bfb1                	j	80005d3a <sys_open+0xd2>
      fileclose(f);
    80005de0:	854e                	mv	a0,s3
    80005de2:	fffff097          	auipc	ra,0xfffff
    80005de6:	db8080e7          	jalr	-584(ra) # 80004b9a <fileclose>
    iunlockput(ip);
    80005dea:	854a                	mv	a0,s2
    80005dec:	ffffe097          	auipc	ra,0xffffe
    80005df0:	172080e7          	jalr	370(ra) # 80003f5e <iunlockput>
    end_op();
    80005df4:	fffff097          	auipc	ra,0xfffff
    80005df8:	95a080e7          	jalr	-1702(ra) # 8000474e <end_op>
    return -1;
    80005dfc:	54fd                	li	s1,-1
    80005dfe:	b7b9                	j	80005d4c <sys_open+0xe4>

0000000080005e00 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e00:	7175                	addi	sp,sp,-144
    80005e02:	e506                	sd	ra,136(sp)
    80005e04:	e122                	sd	s0,128(sp)
    80005e06:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e08:	fffff097          	auipc	ra,0xfffff
    80005e0c:	8c6080e7          	jalr	-1850(ra) # 800046ce <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e10:	08000613          	li	a2,128
    80005e14:	f7040593          	addi	a1,s0,-144
    80005e18:	4501                	li	a0,0
    80005e1a:	ffffd097          	auipc	ra,0xffffd
    80005e1e:	3b4080e7          	jalr	948(ra) # 800031ce <argstr>
    80005e22:	02054963          	bltz	a0,80005e54 <sys_mkdir+0x54>
    80005e26:	4681                	li	a3,0
    80005e28:	4601                	li	a2,0
    80005e2a:	4585                	li	a1,1
    80005e2c:	f7040513          	addi	a0,s0,-144
    80005e30:	fffff097          	auipc	ra,0xfffff
    80005e34:	7fe080e7          	jalr	2046(ra) # 8000562e <create>
    80005e38:	cd11                	beqz	a0,80005e54 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e3a:	ffffe097          	auipc	ra,0xffffe
    80005e3e:	124080e7          	jalr	292(ra) # 80003f5e <iunlockput>
  end_op();
    80005e42:	fffff097          	auipc	ra,0xfffff
    80005e46:	90c080e7          	jalr	-1780(ra) # 8000474e <end_op>
  return 0;
    80005e4a:	4501                	li	a0,0
}
    80005e4c:	60aa                	ld	ra,136(sp)
    80005e4e:	640a                	ld	s0,128(sp)
    80005e50:	6149                	addi	sp,sp,144
    80005e52:	8082                	ret
    end_op();
    80005e54:	fffff097          	auipc	ra,0xfffff
    80005e58:	8fa080e7          	jalr	-1798(ra) # 8000474e <end_op>
    return -1;
    80005e5c:	557d                	li	a0,-1
    80005e5e:	b7fd                	j	80005e4c <sys_mkdir+0x4c>

0000000080005e60 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e60:	7135                	addi	sp,sp,-160
    80005e62:	ed06                	sd	ra,152(sp)
    80005e64:	e922                	sd	s0,144(sp)
    80005e66:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e68:	fffff097          	auipc	ra,0xfffff
    80005e6c:	866080e7          	jalr	-1946(ra) # 800046ce <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e70:	08000613          	li	a2,128
    80005e74:	f7040593          	addi	a1,s0,-144
    80005e78:	4501                	li	a0,0
    80005e7a:	ffffd097          	auipc	ra,0xffffd
    80005e7e:	354080e7          	jalr	852(ra) # 800031ce <argstr>
    80005e82:	04054a63          	bltz	a0,80005ed6 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005e86:	f6c40593          	addi	a1,s0,-148
    80005e8a:	4505                	li	a0,1
    80005e8c:	ffffd097          	auipc	ra,0xffffd
    80005e90:	2fe080e7          	jalr	766(ra) # 8000318a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e94:	04054163          	bltz	a0,80005ed6 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005e98:	f6840593          	addi	a1,s0,-152
    80005e9c:	4509                	li	a0,2
    80005e9e:	ffffd097          	auipc	ra,0xffffd
    80005ea2:	2ec080e7          	jalr	748(ra) # 8000318a <argint>
     argint(1, &major) < 0 ||
    80005ea6:	02054863          	bltz	a0,80005ed6 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005eaa:	f6841683          	lh	a3,-152(s0)
    80005eae:	f6c41603          	lh	a2,-148(s0)
    80005eb2:	458d                	li	a1,3
    80005eb4:	f7040513          	addi	a0,s0,-144
    80005eb8:	fffff097          	auipc	ra,0xfffff
    80005ebc:	776080e7          	jalr	1910(ra) # 8000562e <create>
     argint(2, &minor) < 0 ||
    80005ec0:	c919                	beqz	a0,80005ed6 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ec2:	ffffe097          	auipc	ra,0xffffe
    80005ec6:	09c080e7          	jalr	156(ra) # 80003f5e <iunlockput>
  end_op();
    80005eca:	fffff097          	auipc	ra,0xfffff
    80005ece:	884080e7          	jalr	-1916(ra) # 8000474e <end_op>
  return 0;
    80005ed2:	4501                	li	a0,0
    80005ed4:	a031                	j	80005ee0 <sys_mknod+0x80>
    end_op();
    80005ed6:	fffff097          	auipc	ra,0xfffff
    80005eda:	878080e7          	jalr	-1928(ra) # 8000474e <end_op>
    return -1;
    80005ede:	557d                	li	a0,-1
}
    80005ee0:	60ea                	ld	ra,152(sp)
    80005ee2:	644a                	ld	s0,144(sp)
    80005ee4:	610d                	addi	sp,sp,160
    80005ee6:	8082                	ret

0000000080005ee8 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ee8:	7135                	addi	sp,sp,-160
    80005eea:	ed06                	sd	ra,152(sp)
    80005eec:	e922                	sd	s0,144(sp)
    80005eee:	e526                	sd	s1,136(sp)
    80005ef0:	e14a                	sd	s2,128(sp)
    80005ef2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ef4:	ffffc097          	auipc	ra,0xffffc
    80005ef8:	f0c080e7          	jalr	-244(ra) # 80001e00 <myproc>
    80005efc:	892a                	mv	s2,a0
  
  begin_op();
    80005efe:	ffffe097          	auipc	ra,0xffffe
    80005f02:	7d0080e7          	jalr	2000(ra) # 800046ce <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f06:	08000613          	li	a2,128
    80005f0a:	f6040593          	addi	a1,s0,-160
    80005f0e:	4501                	li	a0,0
    80005f10:	ffffd097          	auipc	ra,0xffffd
    80005f14:	2be080e7          	jalr	702(ra) # 800031ce <argstr>
    80005f18:	04054b63          	bltz	a0,80005f6e <sys_chdir+0x86>
    80005f1c:	f6040513          	addi	a0,s0,-160
    80005f20:	ffffe097          	auipc	ra,0xffffe
    80005f24:	592080e7          	jalr	1426(ra) # 800044b2 <namei>
    80005f28:	84aa                	mv	s1,a0
    80005f2a:	c131                	beqz	a0,80005f6e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f2c:	ffffe097          	auipc	ra,0xffffe
    80005f30:	dd0080e7          	jalr	-560(ra) # 80003cfc <ilock>
  if(ip->type != T_DIR){
    80005f34:	04449703          	lh	a4,68(s1)
    80005f38:	4785                	li	a5,1
    80005f3a:	04f71063          	bne	a4,a5,80005f7a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f3e:	8526                	mv	a0,s1
    80005f40:	ffffe097          	auipc	ra,0xffffe
    80005f44:	e7e080e7          	jalr	-386(ra) # 80003dbe <iunlock>
  iput(p->cwd);
    80005f48:	15093503          	ld	a0,336(s2)
    80005f4c:	ffffe097          	auipc	ra,0xffffe
    80005f50:	f6a080e7          	jalr	-150(ra) # 80003eb6 <iput>
  end_op();
    80005f54:	ffffe097          	auipc	ra,0xffffe
    80005f58:	7fa080e7          	jalr	2042(ra) # 8000474e <end_op>
  p->cwd = ip;
    80005f5c:	14993823          	sd	s1,336(s2)
  return 0;
    80005f60:	4501                	li	a0,0
}
    80005f62:	60ea                	ld	ra,152(sp)
    80005f64:	644a                	ld	s0,144(sp)
    80005f66:	64aa                	ld	s1,136(sp)
    80005f68:	690a                	ld	s2,128(sp)
    80005f6a:	610d                	addi	sp,sp,160
    80005f6c:	8082                	ret
    end_op();
    80005f6e:	ffffe097          	auipc	ra,0xffffe
    80005f72:	7e0080e7          	jalr	2016(ra) # 8000474e <end_op>
    return -1;
    80005f76:	557d                	li	a0,-1
    80005f78:	b7ed                	j	80005f62 <sys_chdir+0x7a>
    iunlockput(ip);
    80005f7a:	8526                	mv	a0,s1
    80005f7c:	ffffe097          	auipc	ra,0xffffe
    80005f80:	fe2080e7          	jalr	-30(ra) # 80003f5e <iunlockput>
    end_op();
    80005f84:	ffffe097          	auipc	ra,0xffffe
    80005f88:	7ca080e7          	jalr	1994(ra) # 8000474e <end_op>
    return -1;
    80005f8c:	557d                	li	a0,-1
    80005f8e:	bfd1                	j	80005f62 <sys_chdir+0x7a>

0000000080005f90 <sys_exec>:

uint64
sys_exec(void)
{
    80005f90:	7145                	addi	sp,sp,-464
    80005f92:	e786                	sd	ra,456(sp)
    80005f94:	e3a2                	sd	s0,448(sp)
    80005f96:	ff26                	sd	s1,440(sp)
    80005f98:	fb4a                	sd	s2,432(sp)
    80005f9a:	f74e                	sd	s3,424(sp)
    80005f9c:	f352                	sd	s4,416(sp)
    80005f9e:	ef56                	sd	s5,408(sp)
    80005fa0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fa2:	08000613          	li	a2,128
    80005fa6:	f4040593          	addi	a1,s0,-192
    80005faa:	4501                	li	a0,0
    80005fac:	ffffd097          	auipc	ra,0xffffd
    80005fb0:	222080e7          	jalr	546(ra) # 800031ce <argstr>
    return -1;
    80005fb4:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fb6:	0c054a63          	bltz	a0,8000608a <sys_exec+0xfa>
    80005fba:	e3840593          	addi	a1,s0,-456
    80005fbe:	4505                	li	a0,1
    80005fc0:	ffffd097          	auipc	ra,0xffffd
    80005fc4:	1ec080e7          	jalr	492(ra) # 800031ac <argaddr>
    80005fc8:	0c054163          	bltz	a0,8000608a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005fcc:	10000613          	li	a2,256
    80005fd0:	4581                	li	a1,0
    80005fd2:	e4040513          	addi	a0,s0,-448
    80005fd6:	ffffb097          	auipc	ra,0xffffb
    80005fda:	d0a080e7          	jalr	-758(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005fde:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005fe2:	89a6                	mv	s3,s1
    80005fe4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005fe6:	02000a13          	li	s4,32
    80005fea:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005fee:	00391513          	slli	a0,s2,0x3
    80005ff2:	e3040593          	addi	a1,s0,-464
    80005ff6:	e3843783          	ld	a5,-456(s0)
    80005ffa:	953e                	add	a0,a0,a5
    80005ffc:	ffffd097          	auipc	ra,0xffffd
    80006000:	0f4080e7          	jalr	244(ra) # 800030f0 <fetchaddr>
    80006004:	02054a63          	bltz	a0,80006038 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006008:	e3043783          	ld	a5,-464(s0)
    8000600c:	c3b9                	beqz	a5,80006052 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000600e:	ffffb097          	auipc	ra,0xffffb
    80006012:	ae6080e7          	jalr	-1306(ra) # 80000af4 <kalloc>
    80006016:	85aa                	mv	a1,a0
    80006018:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000601c:	cd11                	beqz	a0,80006038 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000601e:	6605                	lui	a2,0x1
    80006020:	e3043503          	ld	a0,-464(s0)
    80006024:	ffffd097          	auipc	ra,0xffffd
    80006028:	11e080e7          	jalr	286(ra) # 80003142 <fetchstr>
    8000602c:	00054663          	bltz	a0,80006038 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006030:	0905                	addi	s2,s2,1
    80006032:	09a1                	addi	s3,s3,8
    80006034:	fb491be3          	bne	s2,s4,80005fea <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006038:	10048913          	addi	s2,s1,256
    8000603c:	6088                	ld	a0,0(s1)
    8000603e:	c529                	beqz	a0,80006088 <sys_exec+0xf8>
    kfree(argv[i]);
    80006040:	ffffb097          	auipc	ra,0xffffb
    80006044:	9b8080e7          	jalr	-1608(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006048:	04a1                	addi	s1,s1,8
    8000604a:	ff2499e3          	bne	s1,s2,8000603c <sys_exec+0xac>
  return -1;
    8000604e:	597d                	li	s2,-1
    80006050:	a82d                	j	8000608a <sys_exec+0xfa>
      argv[i] = 0;
    80006052:	0a8e                	slli	s5,s5,0x3
    80006054:	fc040793          	addi	a5,s0,-64
    80006058:	9abe                	add	s5,s5,a5
    8000605a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000605e:	e4040593          	addi	a1,s0,-448
    80006062:	f4040513          	addi	a0,s0,-192
    80006066:	fffff097          	auipc	ra,0xfffff
    8000606a:	194080e7          	jalr	404(ra) # 800051fa <exec>
    8000606e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006070:	10048993          	addi	s3,s1,256
    80006074:	6088                	ld	a0,0(s1)
    80006076:	c911                	beqz	a0,8000608a <sys_exec+0xfa>
    kfree(argv[i]);
    80006078:	ffffb097          	auipc	ra,0xffffb
    8000607c:	980080e7          	jalr	-1664(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006080:	04a1                	addi	s1,s1,8
    80006082:	ff3499e3          	bne	s1,s3,80006074 <sys_exec+0xe4>
    80006086:	a011                	j	8000608a <sys_exec+0xfa>
  return -1;
    80006088:	597d                	li	s2,-1
}
    8000608a:	854a                	mv	a0,s2
    8000608c:	60be                	ld	ra,456(sp)
    8000608e:	641e                	ld	s0,448(sp)
    80006090:	74fa                	ld	s1,440(sp)
    80006092:	795a                	ld	s2,432(sp)
    80006094:	79ba                	ld	s3,424(sp)
    80006096:	7a1a                	ld	s4,416(sp)
    80006098:	6afa                	ld	s5,408(sp)
    8000609a:	6179                	addi	sp,sp,464
    8000609c:	8082                	ret

000000008000609e <sys_pipe>:

uint64
sys_pipe(void)
{
    8000609e:	7139                	addi	sp,sp,-64
    800060a0:	fc06                	sd	ra,56(sp)
    800060a2:	f822                	sd	s0,48(sp)
    800060a4:	f426                	sd	s1,40(sp)
    800060a6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800060a8:	ffffc097          	auipc	ra,0xffffc
    800060ac:	d58080e7          	jalr	-680(ra) # 80001e00 <myproc>
    800060b0:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800060b2:	fd840593          	addi	a1,s0,-40
    800060b6:	4501                	li	a0,0
    800060b8:	ffffd097          	auipc	ra,0xffffd
    800060bc:	0f4080e7          	jalr	244(ra) # 800031ac <argaddr>
    return -1;
    800060c0:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800060c2:	0e054063          	bltz	a0,800061a2 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800060c6:	fc840593          	addi	a1,s0,-56
    800060ca:	fd040513          	addi	a0,s0,-48
    800060ce:	fffff097          	auipc	ra,0xfffff
    800060d2:	dfc080e7          	jalr	-516(ra) # 80004eca <pipealloc>
    return -1;
    800060d6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800060d8:	0c054563          	bltz	a0,800061a2 <sys_pipe+0x104>
  fd0 = -1;
    800060dc:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800060e0:	fd043503          	ld	a0,-48(s0)
    800060e4:	fffff097          	auipc	ra,0xfffff
    800060e8:	508080e7          	jalr	1288(ra) # 800055ec <fdalloc>
    800060ec:	fca42223          	sw	a0,-60(s0)
    800060f0:	08054c63          	bltz	a0,80006188 <sys_pipe+0xea>
    800060f4:	fc843503          	ld	a0,-56(s0)
    800060f8:	fffff097          	auipc	ra,0xfffff
    800060fc:	4f4080e7          	jalr	1268(ra) # 800055ec <fdalloc>
    80006100:	fca42023          	sw	a0,-64(s0)
    80006104:	06054863          	bltz	a0,80006174 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006108:	4691                	li	a3,4
    8000610a:	fc440613          	addi	a2,s0,-60
    8000610e:	fd843583          	ld	a1,-40(s0)
    80006112:	68a8                	ld	a0,80(s1)
    80006114:	ffffb097          	auipc	ra,0xffffb
    80006118:	55e080e7          	jalr	1374(ra) # 80001672 <copyout>
    8000611c:	02054063          	bltz	a0,8000613c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006120:	4691                	li	a3,4
    80006122:	fc040613          	addi	a2,s0,-64
    80006126:	fd843583          	ld	a1,-40(s0)
    8000612a:	0591                	addi	a1,a1,4
    8000612c:	68a8                	ld	a0,80(s1)
    8000612e:	ffffb097          	auipc	ra,0xffffb
    80006132:	544080e7          	jalr	1348(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006136:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006138:	06055563          	bgez	a0,800061a2 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000613c:	fc442783          	lw	a5,-60(s0)
    80006140:	07e9                	addi	a5,a5,26
    80006142:	078e                	slli	a5,a5,0x3
    80006144:	97a6                	add	a5,a5,s1
    80006146:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000614a:	fc042503          	lw	a0,-64(s0)
    8000614e:	0569                	addi	a0,a0,26
    80006150:	050e                	slli	a0,a0,0x3
    80006152:	9526                	add	a0,a0,s1
    80006154:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006158:	fd043503          	ld	a0,-48(s0)
    8000615c:	fffff097          	auipc	ra,0xfffff
    80006160:	a3e080e7          	jalr	-1474(ra) # 80004b9a <fileclose>
    fileclose(wf);
    80006164:	fc843503          	ld	a0,-56(s0)
    80006168:	fffff097          	auipc	ra,0xfffff
    8000616c:	a32080e7          	jalr	-1486(ra) # 80004b9a <fileclose>
    return -1;
    80006170:	57fd                	li	a5,-1
    80006172:	a805                	j	800061a2 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006174:	fc442783          	lw	a5,-60(s0)
    80006178:	0007c863          	bltz	a5,80006188 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000617c:	01a78513          	addi	a0,a5,26
    80006180:	050e                	slli	a0,a0,0x3
    80006182:	9526                	add	a0,a0,s1
    80006184:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006188:	fd043503          	ld	a0,-48(s0)
    8000618c:	fffff097          	auipc	ra,0xfffff
    80006190:	a0e080e7          	jalr	-1522(ra) # 80004b9a <fileclose>
    fileclose(wf);
    80006194:	fc843503          	ld	a0,-56(s0)
    80006198:	fffff097          	auipc	ra,0xfffff
    8000619c:	a02080e7          	jalr	-1534(ra) # 80004b9a <fileclose>
    return -1;
    800061a0:	57fd                	li	a5,-1
}
    800061a2:	853e                	mv	a0,a5
    800061a4:	70e2                	ld	ra,56(sp)
    800061a6:	7442                	ld	s0,48(sp)
    800061a8:	74a2                	ld	s1,40(sp)
    800061aa:	6121                	addi	sp,sp,64
    800061ac:	8082                	ret
	...

00000000800061b0 <kernelvec>:
    800061b0:	7111                	addi	sp,sp,-256
    800061b2:	e006                	sd	ra,0(sp)
    800061b4:	e40a                	sd	sp,8(sp)
    800061b6:	e80e                	sd	gp,16(sp)
    800061b8:	ec12                	sd	tp,24(sp)
    800061ba:	f016                	sd	t0,32(sp)
    800061bc:	f41a                	sd	t1,40(sp)
    800061be:	f81e                	sd	t2,48(sp)
    800061c0:	fc22                	sd	s0,56(sp)
    800061c2:	e0a6                	sd	s1,64(sp)
    800061c4:	e4aa                	sd	a0,72(sp)
    800061c6:	e8ae                	sd	a1,80(sp)
    800061c8:	ecb2                	sd	a2,88(sp)
    800061ca:	f0b6                	sd	a3,96(sp)
    800061cc:	f4ba                	sd	a4,104(sp)
    800061ce:	f8be                	sd	a5,112(sp)
    800061d0:	fcc2                	sd	a6,120(sp)
    800061d2:	e146                	sd	a7,128(sp)
    800061d4:	e54a                	sd	s2,136(sp)
    800061d6:	e94e                	sd	s3,144(sp)
    800061d8:	ed52                	sd	s4,152(sp)
    800061da:	f156                	sd	s5,160(sp)
    800061dc:	f55a                	sd	s6,168(sp)
    800061de:	f95e                	sd	s7,176(sp)
    800061e0:	fd62                	sd	s8,184(sp)
    800061e2:	e1e6                	sd	s9,192(sp)
    800061e4:	e5ea                	sd	s10,200(sp)
    800061e6:	e9ee                	sd	s11,208(sp)
    800061e8:	edf2                	sd	t3,216(sp)
    800061ea:	f1f6                	sd	t4,224(sp)
    800061ec:	f5fa                	sd	t5,232(sp)
    800061ee:	f9fe                	sd	t6,240(sp)
    800061f0:	dcdfc0ef          	jal	ra,80002fbc <kerneltrap>
    800061f4:	6082                	ld	ra,0(sp)
    800061f6:	6122                	ld	sp,8(sp)
    800061f8:	61c2                	ld	gp,16(sp)
    800061fa:	7282                	ld	t0,32(sp)
    800061fc:	7322                	ld	t1,40(sp)
    800061fe:	73c2                	ld	t2,48(sp)
    80006200:	7462                	ld	s0,56(sp)
    80006202:	6486                	ld	s1,64(sp)
    80006204:	6526                	ld	a0,72(sp)
    80006206:	65c6                	ld	a1,80(sp)
    80006208:	6666                	ld	a2,88(sp)
    8000620a:	7686                	ld	a3,96(sp)
    8000620c:	7726                	ld	a4,104(sp)
    8000620e:	77c6                	ld	a5,112(sp)
    80006210:	7866                	ld	a6,120(sp)
    80006212:	688a                	ld	a7,128(sp)
    80006214:	692a                	ld	s2,136(sp)
    80006216:	69ca                	ld	s3,144(sp)
    80006218:	6a6a                	ld	s4,152(sp)
    8000621a:	7a8a                	ld	s5,160(sp)
    8000621c:	7b2a                	ld	s6,168(sp)
    8000621e:	7bca                	ld	s7,176(sp)
    80006220:	7c6a                	ld	s8,184(sp)
    80006222:	6c8e                	ld	s9,192(sp)
    80006224:	6d2e                	ld	s10,200(sp)
    80006226:	6dce                	ld	s11,208(sp)
    80006228:	6e6e                	ld	t3,216(sp)
    8000622a:	7e8e                	ld	t4,224(sp)
    8000622c:	7f2e                	ld	t5,232(sp)
    8000622e:	7fce                	ld	t6,240(sp)
    80006230:	6111                	addi	sp,sp,256
    80006232:	10200073          	sret
    80006236:	00000013          	nop
    8000623a:	00000013          	nop
    8000623e:	0001                	nop

0000000080006240 <timervec>:
    80006240:	34051573          	csrrw	a0,mscratch,a0
    80006244:	e10c                	sd	a1,0(a0)
    80006246:	e510                	sd	a2,8(a0)
    80006248:	e914                	sd	a3,16(a0)
    8000624a:	6d0c                	ld	a1,24(a0)
    8000624c:	7110                	ld	a2,32(a0)
    8000624e:	6194                	ld	a3,0(a1)
    80006250:	96b2                	add	a3,a3,a2
    80006252:	e194                	sd	a3,0(a1)
    80006254:	4589                	li	a1,2
    80006256:	14459073          	csrw	sip,a1
    8000625a:	6914                	ld	a3,16(a0)
    8000625c:	6510                	ld	a2,8(a0)
    8000625e:	610c                	ld	a1,0(a0)
    80006260:	34051573          	csrrw	a0,mscratch,a0
    80006264:	30200073          	mret
	...

000000008000626a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000626a:	1141                	addi	sp,sp,-16
    8000626c:	e422                	sd	s0,8(sp)
    8000626e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006270:	0c0007b7          	lui	a5,0xc000
    80006274:	4705                	li	a4,1
    80006276:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006278:	c3d8                	sw	a4,4(a5)
}
    8000627a:	6422                	ld	s0,8(sp)
    8000627c:	0141                	addi	sp,sp,16
    8000627e:	8082                	ret

0000000080006280 <plicinithart>:

void
plicinithart(void)
{
    80006280:	1141                	addi	sp,sp,-16
    80006282:	e406                	sd	ra,8(sp)
    80006284:	e022                	sd	s0,0(sp)
    80006286:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006288:	ffffc097          	auipc	ra,0xffffc
    8000628c:	b46080e7          	jalr	-1210(ra) # 80001dce <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006290:	0085171b          	slliw	a4,a0,0x8
    80006294:	0c0027b7          	lui	a5,0xc002
    80006298:	97ba                	add	a5,a5,a4
    8000629a:	40200713          	li	a4,1026
    8000629e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062a2:	00d5151b          	slliw	a0,a0,0xd
    800062a6:	0c2017b7          	lui	a5,0xc201
    800062aa:	953e                	add	a0,a0,a5
    800062ac:	00052023          	sw	zero,0(a0)
}
    800062b0:	60a2                	ld	ra,8(sp)
    800062b2:	6402                	ld	s0,0(sp)
    800062b4:	0141                	addi	sp,sp,16
    800062b6:	8082                	ret

00000000800062b8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800062b8:	1141                	addi	sp,sp,-16
    800062ba:	e406                	sd	ra,8(sp)
    800062bc:	e022                	sd	s0,0(sp)
    800062be:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062c0:	ffffc097          	auipc	ra,0xffffc
    800062c4:	b0e080e7          	jalr	-1266(ra) # 80001dce <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800062c8:	00d5179b          	slliw	a5,a0,0xd
    800062cc:	0c201537          	lui	a0,0xc201
    800062d0:	953e                	add	a0,a0,a5
  return irq;
}
    800062d2:	4148                	lw	a0,4(a0)
    800062d4:	60a2                	ld	ra,8(sp)
    800062d6:	6402                	ld	s0,0(sp)
    800062d8:	0141                	addi	sp,sp,16
    800062da:	8082                	ret

00000000800062dc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800062dc:	1101                	addi	sp,sp,-32
    800062de:	ec06                	sd	ra,24(sp)
    800062e0:	e822                	sd	s0,16(sp)
    800062e2:	e426                	sd	s1,8(sp)
    800062e4:	1000                	addi	s0,sp,32
    800062e6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800062e8:	ffffc097          	auipc	ra,0xffffc
    800062ec:	ae6080e7          	jalr	-1306(ra) # 80001dce <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800062f0:	00d5151b          	slliw	a0,a0,0xd
    800062f4:	0c2017b7          	lui	a5,0xc201
    800062f8:	97aa                	add	a5,a5,a0
    800062fa:	c3c4                	sw	s1,4(a5)
}
    800062fc:	60e2                	ld	ra,24(sp)
    800062fe:	6442                	ld	s0,16(sp)
    80006300:	64a2                	ld	s1,8(sp)
    80006302:	6105                	addi	sp,sp,32
    80006304:	8082                	ret

0000000080006306 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006306:	1141                	addi	sp,sp,-16
    80006308:	e406                	sd	ra,8(sp)
    8000630a:	e022                	sd	s0,0(sp)
    8000630c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000630e:	479d                	li	a5,7
    80006310:	06a7c963          	blt	a5,a0,80006382 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006314:	0001d797          	auipc	a5,0x1d
    80006318:	cec78793          	addi	a5,a5,-788 # 80023000 <disk>
    8000631c:	00a78733          	add	a4,a5,a0
    80006320:	6789                	lui	a5,0x2
    80006322:	97ba                	add	a5,a5,a4
    80006324:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006328:	e7ad                	bnez	a5,80006392 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000632a:	00451793          	slli	a5,a0,0x4
    8000632e:	0001f717          	auipc	a4,0x1f
    80006332:	cd270713          	addi	a4,a4,-814 # 80025000 <disk+0x2000>
    80006336:	6314                	ld	a3,0(a4)
    80006338:	96be                	add	a3,a3,a5
    8000633a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000633e:	6314                	ld	a3,0(a4)
    80006340:	96be                	add	a3,a3,a5
    80006342:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006346:	6314                	ld	a3,0(a4)
    80006348:	96be                	add	a3,a3,a5
    8000634a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000634e:	6318                	ld	a4,0(a4)
    80006350:	97ba                	add	a5,a5,a4
    80006352:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006356:	0001d797          	auipc	a5,0x1d
    8000635a:	caa78793          	addi	a5,a5,-854 # 80023000 <disk>
    8000635e:	97aa                	add	a5,a5,a0
    80006360:	6509                	lui	a0,0x2
    80006362:	953e                	add	a0,a0,a5
    80006364:	4785                	li	a5,1
    80006366:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000636a:	0001f517          	auipc	a0,0x1f
    8000636e:	cae50513          	addi	a0,a0,-850 # 80025018 <disk+0x2018>
    80006372:	ffffc097          	auipc	ra,0xffffc
    80006376:	440080e7          	jalr	1088(ra) # 800027b2 <wakeup>
}
    8000637a:	60a2                	ld	ra,8(sp)
    8000637c:	6402                	ld	s0,0(sp)
    8000637e:	0141                	addi	sp,sp,16
    80006380:	8082                	ret
    panic("free_desc 1");
    80006382:	00002517          	auipc	a0,0x2
    80006386:	48e50513          	addi	a0,a0,1166 # 80008810 <syscalls+0x320>
    8000638a:	ffffa097          	auipc	ra,0xffffa
    8000638e:	1b4080e7          	jalr	436(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006392:	00002517          	auipc	a0,0x2
    80006396:	48e50513          	addi	a0,a0,1166 # 80008820 <syscalls+0x330>
    8000639a:	ffffa097          	auipc	ra,0xffffa
    8000639e:	1a4080e7          	jalr	420(ra) # 8000053e <panic>

00000000800063a2 <virtio_disk_init>:
{
    800063a2:	1101                	addi	sp,sp,-32
    800063a4:	ec06                	sd	ra,24(sp)
    800063a6:	e822                	sd	s0,16(sp)
    800063a8:	e426                	sd	s1,8(sp)
    800063aa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063ac:	00002597          	auipc	a1,0x2
    800063b0:	48458593          	addi	a1,a1,1156 # 80008830 <syscalls+0x340>
    800063b4:	0001f517          	auipc	a0,0x1f
    800063b8:	d7450513          	addi	a0,a0,-652 # 80025128 <disk+0x2128>
    800063bc:	ffffa097          	auipc	ra,0xffffa
    800063c0:	798080e7          	jalr	1944(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063c4:	100017b7          	lui	a5,0x10001
    800063c8:	4398                	lw	a4,0(a5)
    800063ca:	2701                	sext.w	a4,a4
    800063cc:	747277b7          	lui	a5,0x74727
    800063d0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800063d4:	0ef71163          	bne	a4,a5,800064b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800063d8:	100017b7          	lui	a5,0x10001
    800063dc:	43dc                	lw	a5,4(a5)
    800063de:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063e0:	4705                	li	a4,1
    800063e2:	0ce79a63          	bne	a5,a4,800064b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063e6:	100017b7          	lui	a5,0x10001
    800063ea:	479c                	lw	a5,8(a5)
    800063ec:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800063ee:	4709                	li	a4,2
    800063f0:	0ce79363          	bne	a5,a4,800064b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800063f4:	100017b7          	lui	a5,0x10001
    800063f8:	47d8                	lw	a4,12(a5)
    800063fa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063fc:	554d47b7          	lui	a5,0x554d4
    80006400:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006404:	0af71963          	bne	a4,a5,800064b6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006408:	100017b7          	lui	a5,0x10001
    8000640c:	4705                	li	a4,1
    8000640e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006410:	470d                	li	a4,3
    80006412:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006414:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006416:	c7ffe737          	lui	a4,0xc7ffe
    8000641a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000641e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006420:	2701                	sext.w	a4,a4
    80006422:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006424:	472d                	li	a4,11
    80006426:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006428:	473d                	li	a4,15
    8000642a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000642c:	6705                	lui	a4,0x1
    8000642e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006430:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006434:	5bdc                	lw	a5,52(a5)
    80006436:	2781                	sext.w	a5,a5
  if(max == 0)
    80006438:	c7d9                	beqz	a5,800064c6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000643a:	471d                	li	a4,7
    8000643c:	08f77d63          	bgeu	a4,a5,800064d6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006440:	100014b7          	lui	s1,0x10001
    80006444:	47a1                	li	a5,8
    80006446:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006448:	6609                	lui	a2,0x2
    8000644a:	4581                	li	a1,0
    8000644c:	0001d517          	auipc	a0,0x1d
    80006450:	bb450513          	addi	a0,a0,-1100 # 80023000 <disk>
    80006454:	ffffb097          	auipc	ra,0xffffb
    80006458:	88c080e7          	jalr	-1908(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000645c:	0001d717          	auipc	a4,0x1d
    80006460:	ba470713          	addi	a4,a4,-1116 # 80023000 <disk>
    80006464:	00c75793          	srli	a5,a4,0xc
    80006468:	2781                	sext.w	a5,a5
    8000646a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000646c:	0001f797          	auipc	a5,0x1f
    80006470:	b9478793          	addi	a5,a5,-1132 # 80025000 <disk+0x2000>
    80006474:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006476:	0001d717          	auipc	a4,0x1d
    8000647a:	c0a70713          	addi	a4,a4,-1014 # 80023080 <disk+0x80>
    8000647e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006480:	0001e717          	auipc	a4,0x1e
    80006484:	b8070713          	addi	a4,a4,-1152 # 80024000 <disk+0x1000>
    80006488:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000648a:	4705                	li	a4,1
    8000648c:	00e78c23          	sb	a4,24(a5)
    80006490:	00e78ca3          	sb	a4,25(a5)
    80006494:	00e78d23          	sb	a4,26(a5)
    80006498:	00e78da3          	sb	a4,27(a5)
    8000649c:	00e78e23          	sb	a4,28(a5)
    800064a0:	00e78ea3          	sb	a4,29(a5)
    800064a4:	00e78f23          	sb	a4,30(a5)
    800064a8:	00e78fa3          	sb	a4,31(a5)
}
    800064ac:	60e2                	ld	ra,24(sp)
    800064ae:	6442                	ld	s0,16(sp)
    800064b0:	64a2                	ld	s1,8(sp)
    800064b2:	6105                	addi	sp,sp,32
    800064b4:	8082                	ret
    panic("could not find virtio disk");
    800064b6:	00002517          	auipc	a0,0x2
    800064ba:	38a50513          	addi	a0,a0,906 # 80008840 <syscalls+0x350>
    800064be:	ffffa097          	auipc	ra,0xffffa
    800064c2:	080080e7          	jalr	128(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800064c6:	00002517          	auipc	a0,0x2
    800064ca:	39a50513          	addi	a0,a0,922 # 80008860 <syscalls+0x370>
    800064ce:	ffffa097          	auipc	ra,0xffffa
    800064d2:	070080e7          	jalr	112(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800064d6:	00002517          	auipc	a0,0x2
    800064da:	3aa50513          	addi	a0,a0,938 # 80008880 <syscalls+0x390>
    800064de:	ffffa097          	auipc	ra,0xffffa
    800064e2:	060080e7          	jalr	96(ra) # 8000053e <panic>

00000000800064e6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800064e6:	7159                	addi	sp,sp,-112
    800064e8:	f486                	sd	ra,104(sp)
    800064ea:	f0a2                	sd	s0,96(sp)
    800064ec:	eca6                	sd	s1,88(sp)
    800064ee:	e8ca                	sd	s2,80(sp)
    800064f0:	e4ce                	sd	s3,72(sp)
    800064f2:	e0d2                	sd	s4,64(sp)
    800064f4:	fc56                	sd	s5,56(sp)
    800064f6:	f85a                	sd	s6,48(sp)
    800064f8:	f45e                	sd	s7,40(sp)
    800064fa:	f062                	sd	s8,32(sp)
    800064fc:	ec66                	sd	s9,24(sp)
    800064fe:	e86a                	sd	s10,16(sp)
    80006500:	1880                	addi	s0,sp,112
    80006502:	892a                	mv	s2,a0
    80006504:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006506:	00c52c83          	lw	s9,12(a0)
    8000650a:	001c9c9b          	slliw	s9,s9,0x1
    8000650e:	1c82                	slli	s9,s9,0x20
    80006510:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006514:	0001f517          	auipc	a0,0x1f
    80006518:	c1450513          	addi	a0,a0,-1004 # 80025128 <disk+0x2128>
    8000651c:	ffffa097          	auipc	ra,0xffffa
    80006520:	6c8080e7          	jalr	1736(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006524:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006526:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006528:	0001db97          	auipc	s7,0x1d
    8000652c:	ad8b8b93          	addi	s7,s7,-1320 # 80023000 <disk>
    80006530:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006532:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006534:	8a4e                	mv	s4,s3
    80006536:	a051                	j	800065ba <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006538:	00fb86b3          	add	a3,s7,a5
    8000653c:	96da                	add	a3,a3,s6
    8000653e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006542:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006544:	0207c563          	bltz	a5,8000656e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006548:	2485                	addiw	s1,s1,1
    8000654a:	0711                	addi	a4,a4,4
    8000654c:	25548063          	beq	s1,s5,8000678c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006550:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006552:	0001f697          	auipc	a3,0x1f
    80006556:	ac668693          	addi	a3,a3,-1338 # 80025018 <disk+0x2018>
    8000655a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000655c:	0006c583          	lbu	a1,0(a3)
    80006560:	fde1                	bnez	a1,80006538 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006562:	2785                	addiw	a5,a5,1
    80006564:	0685                	addi	a3,a3,1
    80006566:	ff879be3          	bne	a5,s8,8000655c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000656a:	57fd                	li	a5,-1
    8000656c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000656e:	02905a63          	blez	s1,800065a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006572:	f9042503          	lw	a0,-112(s0)
    80006576:	00000097          	auipc	ra,0x0
    8000657a:	d90080e7          	jalr	-624(ra) # 80006306 <free_desc>
      for(int j = 0; j < i; j++)
    8000657e:	4785                	li	a5,1
    80006580:	0297d163          	bge	a5,s1,800065a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006584:	f9442503          	lw	a0,-108(s0)
    80006588:	00000097          	auipc	ra,0x0
    8000658c:	d7e080e7          	jalr	-642(ra) # 80006306 <free_desc>
      for(int j = 0; j < i; j++)
    80006590:	4789                	li	a5,2
    80006592:	0097d863          	bge	a5,s1,800065a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006596:	f9842503          	lw	a0,-104(s0)
    8000659a:	00000097          	auipc	ra,0x0
    8000659e:	d6c080e7          	jalr	-660(ra) # 80006306 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065a2:	0001f597          	auipc	a1,0x1f
    800065a6:	b8658593          	addi	a1,a1,-1146 # 80025128 <disk+0x2128>
    800065aa:	0001f517          	auipc	a0,0x1f
    800065ae:	a6e50513          	addi	a0,a0,-1426 # 80025018 <disk+0x2018>
    800065b2:	ffffc097          	auipc	ra,0xffffc
    800065b6:	062080e7          	jalr	98(ra) # 80002614 <sleep>
  for(int i = 0; i < 3; i++){
    800065ba:	f9040713          	addi	a4,s0,-112
    800065be:	84ce                	mv	s1,s3
    800065c0:	bf41                	j	80006550 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800065c2:	20058713          	addi	a4,a1,512
    800065c6:	00471693          	slli	a3,a4,0x4
    800065ca:	0001d717          	auipc	a4,0x1d
    800065ce:	a3670713          	addi	a4,a4,-1482 # 80023000 <disk>
    800065d2:	9736                	add	a4,a4,a3
    800065d4:	4685                	li	a3,1
    800065d6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800065da:	20058713          	addi	a4,a1,512
    800065de:	00471693          	slli	a3,a4,0x4
    800065e2:	0001d717          	auipc	a4,0x1d
    800065e6:	a1e70713          	addi	a4,a4,-1506 # 80023000 <disk>
    800065ea:	9736                	add	a4,a4,a3
    800065ec:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800065f0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800065f4:	7679                	lui	a2,0xffffe
    800065f6:	963e                	add	a2,a2,a5
    800065f8:	0001f697          	auipc	a3,0x1f
    800065fc:	a0868693          	addi	a3,a3,-1528 # 80025000 <disk+0x2000>
    80006600:	6298                	ld	a4,0(a3)
    80006602:	9732                	add	a4,a4,a2
    80006604:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006606:	6298                	ld	a4,0(a3)
    80006608:	9732                	add	a4,a4,a2
    8000660a:	4541                	li	a0,16
    8000660c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000660e:	6298                	ld	a4,0(a3)
    80006610:	9732                	add	a4,a4,a2
    80006612:	4505                	li	a0,1
    80006614:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006618:	f9442703          	lw	a4,-108(s0)
    8000661c:	6288                	ld	a0,0(a3)
    8000661e:	962a                	add	a2,a2,a0
    80006620:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006624:	0712                	slli	a4,a4,0x4
    80006626:	6290                	ld	a2,0(a3)
    80006628:	963a                	add	a2,a2,a4
    8000662a:	05890513          	addi	a0,s2,88
    8000662e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006630:	6294                	ld	a3,0(a3)
    80006632:	96ba                	add	a3,a3,a4
    80006634:	40000613          	li	a2,1024
    80006638:	c690                	sw	a2,8(a3)
  if(write)
    8000663a:	140d0063          	beqz	s10,8000677a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000663e:	0001f697          	auipc	a3,0x1f
    80006642:	9c26b683          	ld	a3,-1598(a3) # 80025000 <disk+0x2000>
    80006646:	96ba                	add	a3,a3,a4
    80006648:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000664c:	0001d817          	auipc	a6,0x1d
    80006650:	9b480813          	addi	a6,a6,-1612 # 80023000 <disk>
    80006654:	0001f517          	auipc	a0,0x1f
    80006658:	9ac50513          	addi	a0,a0,-1620 # 80025000 <disk+0x2000>
    8000665c:	6114                	ld	a3,0(a0)
    8000665e:	96ba                	add	a3,a3,a4
    80006660:	00c6d603          	lhu	a2,12(a3)
    80006664:	00166613          	ori	a2,a2,1
    80006668:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000666c:	f9842683          	lw	a3,-104(s0)
    80006670:	6110                	ld	a2,0(a0)
    80006672:	9732                	add	a4,a4,a2
    80006674:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006678:	20058613          	addi	a2,a1,512
    8000667c:	0612                	slli	a2,a2,0x4
    8000667e:	9642                	add	a2,a2,a6
    80006680:	577d                	li	a4,-1
    80006682:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006686:	00469713          	slli	a4,a3,0x4
    8000668a:	6114                	ld	a3,0(a0)
    8000668c:	96ba                	add	a3,a3,a4
    8000668e:	03078793          	addi	a5,a5,48
    80006692:	97c2                	add	a5,a5,a6
    80006694:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006696:	611c                	ld	a5,0(a0)
    80006698:	97ba                	add	a5,a5,a4
    8000669a:	4685                	li	a3,1
    8000669c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000669e:	611c                	ld	a5,0(a0)
    800066a0:	97ba                	add	a5,a5,a4
    800066a2:	4809                	li	a6,2
    800066a4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800066a8:	611c                	ld	a5,0(a0)
    800066aa:	973e                	add	a4,a4,a5
    800066ac:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800066b0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800066b4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800066b8:	6518                	ld	a4,8(a0)
    800066ba:	00275783          	lhu	a5,2(a4)
    800066be:	8b9d                	andi	a5,a5,7
    800066c0:	0786                	slli	a5,a5,0x1
    800066c2:	97ba                	add	a5,a5,a4
    800066c4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800066c8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800066cc:	6518                	ld	a4,8(a0)
    800066ce:	00275783          	lhu	a5,2(a4)
    800066d2:	2785                	addiw	a5,a5,1
    800066d4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800066d8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800066dc:	100017b7          	lui	a5,0x10001
    800066e0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800066e4:	00492703          	lw	a4,4(s2)
    800066e8:	4785                	li	a5,1
    800066ea:	02f71163          	bne	a4,a5,8000670c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800066ee:	0001f997          	auipc	s3,0x1f
    800066f2:	a3a98993          	addi	s3,s3,-1478 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800066f6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800066f8:	85ce                	mv	a1,s3
    800066fa:	854a                	mv	a0,s2
    800066fc:	ffffc097          	auipc	ra,0xffffc
    80006700:	f18080e7          	jalr	-232(ra) # 80002614 <sleep>
  while(b->disk == 1) {
    80006704:	00492783          	lw	a5,4(s2)
    80006708:	fe9788e3          	beq	a5,s1,800066f8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000670c:	f9042903          	lw	s2,-112(s0)
    80006710:	20090793          	addi	a5,s2,512
    80006714:	00479713          	slli	a4,a5,0x4
    80006718:	0001d797          	auipc	a5,0x1d
    8000671c:	8e878793          	addi	a5,a5,-1816 # 80023000 <disk>
    80006720:	97ba                	add	a5,a5,a4
    80006722:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006726:	0001f997          	auipc	s3,0x1f
    8000672a:	8da98993          	addi	s3,s3,-1830 # 80025000 <disk+0x2000>
    8000672e:	00491713          	slli	a4,s2,0x4
    80006732:	0009b783          	ld	a5,0(s3)
    80006736:	97ba                	add	a5,a5,a4
    80006738:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000673c:	854a                	mv	a0,s2
    8000673e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006742:	00000097          	auipc	ra,0x0
    80006746:	bc4080e7          	jalr	-1084(ra) # 80006306 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000674a:	8885                	andi	s1,s1,1
    8000674c:	f0ed                	bnez	s1,8000672e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000674e:	0001f517          	auipc	a0,0x1f
    80006752:	9da50513          	addi	a0,a0,-1574 # 80025128 <disk+0x2128>
    80006756:	ffffa097          	auipc	ra,0xffffa
    8000675a:	542080e7          	jalr	1346(ra) # 80000c98 <release>
}
    8000675e:	70a6                	ld	ra,104(sp)
    80006760:	7406                	ld	s0,96(sp)
    80006762:	64e6                	ld	s1,88(sp)
    80006764:	6946                	ld	s2,80(sp)
    80006766:	69a6                	ld	s3,72(sp)
    80006768:	6a06                	ld	s4,64(sp)
    8000676a:	7ae2                	ld	s5,56(sp)
    8000676c:	7b42                	ld	s6,48(sp)
    8000676e:	7ba2                	ld	s7,40(sp)
    80006770:	7c02                	ld	s8,32(sp)
    80006772:	6ce2                	ld	s9,24(sp)
    80006774:	6d42                	ld	s10,16(sp)
    80006776:	6165                	addi	sp,sp,112
    80006778:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000677a:	0001f697          	auipc	a3,0x1f
    8000677e:	8866b683          	ld	a3,-1914(a3) # 80025000 <disk+0x2000>
    80006782:	96ba                	add	a3,a3,a4
    80006784:	4609                	li	a2,2
    80006786:	00c69623          	sh	a2,12(a3)
    8000678a:	b5c9                	j	8000664c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000678c:	f9042583          	lw	a1,-112(s0)
    80006790:	20058793          	addi	a5,a1,512
    80006794:	0792                	slli	a5,a5,0x4
    80006796:	0001d517          	auipc	a0,0x1d
    8000679a:	91250513          	addi	a0,a0,-1774 # 800230a8 <disk+0xa8>
    8000679e:	953e                	add	a0,a0,a5
  if(write)
    800067a0:	e20d11e3          	bnez	s10,800065c2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800067a4:	20058713          	addi	a4,a1,512
    800067a8:	00471693          	slli	a3,a4,0x4
    800067ac:	0001d717          	auipc	a4,0x1d
    800067b0:	85470713          	addi	a4,a4,-1964 # 80023000 <disk>
    800067b4:	9736                	add	a4,a4,a3
    800067b6:	0a072423          	sw	zero,168(a4)
    800067ba:	b505                	j	800065da <virtio_disk_rw+0xf4>

00000000800067bc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800067bc:	1101                	addi	sp,sp,-32
    800067be:	ec06                	sd	ra,24(sp)
    800067c0:	e822                	sd	s0,16(sp)
    800067c2:	e426                	sd	s1,8(sp)
    800067c4:	e04a                	sd	s2,0(sp)
    800067c6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800067c8:	0001f517          	auipc	a0,0x1f
    800067cc:	96050513          	addi	a0,a0,-1696 # 80025128 <disk+0x2128>
    800067d0:	ffffa097          	auipc	ra,0xffffa
    800067d4:	414080e7          	jalr	1044(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800067d8:	10001737          	lui	a4,0x10001
    800067dc:	533c                	lw	a5,96(a4)
    800067de:	8b8d                	andi	a5,a5,3
    800067e0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800067e2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800067e6:	0001f797          	auipc	a5,0x1f
    800067ea:	81a78793          	addi	a5,a5,-2022 # 80025000 <disk+0x2000>
    800067ee:	6b94                	ld	a3,16(a5)
    800067f0:	0207d703          	lhu	a4,32(a5)
    800067f4:	0026d783          	lhu	a5,2(a3)
    800067f8:	06f70163          	beq	a4,a5,8000685a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067fc:	0001d917          	auipc	s2,0x1d
    80006800:	80490913          	addi	s2,s2,-2044 # 80023000 <disk>
    80006804:	0001e497          	auipc	s1,0x1e
    80006808:	7fc48493          	addi	s1,s1,2044 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000680c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006810:	6898                	ld	a4,16(s1)
    80006812:	0204d783          	lhu	a5,32(s1)
    80006816:	8b9d                	andi	a5,a5,7
    80006818:	078e                	slli	a5,a5,0x3
    8000681a:	97ba                	add	a5,a5,a4
    8000681c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000681e:	20078713          	addi	a4,a5,512
    80006822:	0712                	slli	a4,a4,0x4
    80006824:	974a                	add	a4,a4,s2
    80006826:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000682a:	e731                	bnez	a4,80006876 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000682c:	20078793          	addi	a5,a5,512
    80006830:	0792                	slli	a5,a5,0x4
    80006832:	97ca                	add	a5,a5,s2
    80006834:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006836:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000683a:	ffffc097          	auipc	ra,0xffffc
    8000683e:	f78080e7          	jalr	-136(ra) # 800027b2 <wakeup>

    disk.used_idx += 1;
    80006842:	0204d783          	lhu	a5,32(s1)
    80006846:	2785                	addiw	a5,a5,1
    80006848:	17c2                	slli	a5,a5,0x30
    8000684a:	93c1                	srli	a5,a5,0x30
    8000684c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006850:	6898                	ld	a4,16(s1)
    80006852:	00275703          	lhu	a4,2(a4)
    80006856:	faf71be3          	bne	a4,a5,8000680c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000685a:	0001f517          	auipc	a0,0x1f
    8000685e:	8ce50513          	addi	a0,a0,-1842 # 80025128 <disk+0x2128>
    80006862:	ffffa097          	auipc	ra,0xffffa
    80006866:	436080e7          	jalr	1078(ra) # 80000c98 <release>
}
    8000686a:	60e2                	ld	ra,24(sp)
    8000686c:	6442                	ld	s0,16(sp)
    8000686e:	64a2                	ld	s1,8(sp)
    80006870:	6902                	ld	s2,0(sp)
    80006872:	6105                	addi	sp,sp,32
    80006874:	8082                	ret
      panic("virtio_disk_intr status");
    80006876:	00002517          	auipc	a0,0x2
    8000687a:	02a50513          	addi	a0,a0,42 # 800088a0 <syscalls+0x3b0>
    8000687e:	ffffa097          	auipc	ra,0xffffa
    80006882:	cc0080e7          	jalr	-832(ra) # 8000053e <panic>

0000000080006886 <cas>:
    80006886:	100522af          	lr.w	t0,(a0)
    8000688a:	00b29563          	bne	t0,a1,80006894 <fail>
    8000688e:	18c5252f          	sc.w	a0,a2,(a0)
    80006892:	8082                	ret

0000000080006894 <fail>:
    80006894:	4505                	li	a0,1
    80006896:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
