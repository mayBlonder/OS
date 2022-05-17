
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
    80000068:	1fc78793          	addi	a5,a5,508 # 80006260 <timervec>
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
    80000130:	990080e7          	jalr	-1648(ra) # 80002abc <either_copyin>
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
    800001c8:	c50080e7          	jalr	-944(ra) # 80001e14 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	454080e7          	jalr	1108(ra) # 80002628 <sleep>
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
    80000214:	856080e7          	jalr	-1962(ra) # 80002a66 <either_copyout>
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
    800002f6:	820080e7          	jalr	-2016(ra) # 80002b12 <procdump>
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
    8000044a:	380080e7          	jalr	896(ra) # 800027c6 <wakeup>
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
    800008a4:	f26080e7          	jalr	-218(ra) # 800027c6 <wakeup>
    
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
    80000930:	cfc080e7          	jalr	-772(ra) # 80002628 <sleep>
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
    80000b82:	274080e7          	jalr	628(ra) # 80001df2 <mycpu>
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
    80000bb4:	242080e7          	jalr	578(ra) # 80001df2 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	236080e7          	jalr	566(ra) # 80001df2 <mycpu>
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
    80000bd8:	21e080e7          	jalr	542(ra) # 80001df2 <mycpu>
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
    80000c18:	1de080e7          	jalr	478(ra) # 80001df2 <mycpu>
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
    80000c44:	1b2080e7          	jalr	434(ra) # 80001df2 <mycpu>
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
    80000e9a:	f4c080e7          	jalr	-180(ra) # 80001de2 <cpuid>
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
    80000eb6:	f30080e7          	jalr	-208(ra) # 80001de2 <cpuid>
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
    80000ed8:	e6a080e7          	jalr	-406(ra) # 80002d3e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	3c4080e7          	jalr	964(ra) # 800062a0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	538080e7          	jalr	1336(ra) # 8000241c <scheduler>
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
    80000f48:	d9a080e7          	jalr	-614(ra) # 80001cde <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	dca080e7          	jalr	-566(ra) # 80002d16 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	dea080e7          	jalr	-534(ra) # 80002d3e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	32e080e7          	jalr	814(ra) # 8000628a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	33c080e7          	jalr	828(ra) # 800062a0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	514080e7          	jalr	1300(ra) # 80003480 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	ba4080e7          	jalr	-1116(ra) # 80003b18 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	b4e080e7          	jalr	-1202(ra) # 80004aca <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	43e080e7          	jalr	1086(ra) # 800063c2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	214080e7          	jalr	532(ra) # 800021a0 <userinit>
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
    80001244:	a08080e7          	jalr	-1528(ra) # 80001c48 <proc_mapstacks>
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
    8000185e:	04c080e7          	jalr	76(ra) # 800068a6 <cas>
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
  int h= 0;
  h = lst->head == -1;
    800019ec:	4108                	lw	a0,0(a0)
    800019ee:	0505                	addi	a0,a0,1
  return h;
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
    release(&lst->head_lock);
    80001a82:	854e                	mv	a0,s3
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	214080e7          	jalr	532(ra) # 80000c98 <release>
    release(&lst->head_lock);
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
  h = lst->head == -1;
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
      lst->tail = -1;
    }
    release(&lst->head_lock);
  }
  else{
    if (lst->tail == p->proc_ind) {
    80001b4c:	00492783          	lw	a5,4(s2)
    80001b50:	0ee78763          	beq	a5,a4,80001c3e <remove+0x126>
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
    if(lst->tail == p->proc_ind){
    80001c1e:	00492703          	lw	a4,4(s2)
    80001c22:	1744a783          	lw	a5,372(s1)
    80001c26:	00f70863          	beq	a4,a5,80001c36 <remove+0x11e>
    release(&lst->head_lock);
    80001c2a:	854e                	mv	a0,s3
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	06c080e7          	jalr	108(ra) # 80000c98 <release>
    80001c34:	bf59                	j	80001bca <remove+0xb2>
      lst->tail = -1;
    80001c36:	57fd                	li	a5,-1
    80001c38:	00f92223          	sw	a5,4(s2)
    80001c3c:	b7fd                	j	80001c2a <remove+0x112>
      lst->tail = p->prev_proc;
    80001c3e:	1704a783          	lw	a5,368(s1)
    80001c42:	00f92223          	sw	a5,4(s2)
    80001c46:	b739                	j	80001b54 <remove+0x3c>

0000000080001c48 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001c48:	7139                	addi	sp,sp,-64
    80001c4a:	fc06                	sd	ra,56(sp)
    80001c4c:	f822                	sd	s0,48(sp)
    80001c4e:	f426                	sd	s1,40(sp)
    80001c50:	f04a                	sd	s2,32(sp)
    80001c52:	ec4e                	sd	s3,24(sp)
    80001c54:	e852                	sd	s4,16(sp)
    80001c56:	e456                	sd	s5,8(sp)
    80001c58:	e05a                	sd	s6,0(sp)
    80001c5a:	0080                	addi	s0,sp,64
    80001c5c:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c5e:	00010497          	auipc	s1,0x10
    80001c62:	bb248493          	addi	s1,s1,-1102 # 80011810 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001c66:	8b26                	mv	s6,s1
    80001c68:	00006a97          	auipc	s5,0x6
    80001c6c:	398a8a93          	addi	s5,s5,920 # 80008000 <etext>
    80001c70:	04000937          	lui	s2,0x4000
    80001c74:	197d                	addi	s2,s2,-1
    80001c76:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c78:	00016a17          	auipc	s4,0x16
    80001c7c:	f98a0a13          	addi	s4,s4,-104 # 80017c10 <tickslock>
    char *pa = kalloc();
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	e74080e7          	jalr	-396(ra) # 80000af4 <kalloc>
    80001c88:	862a                	mv	a2,a0
    if(pa == 0)
    80001c8a:	c131                	beqz	a0,80001cce <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001c8c:	416485b3          	sub	a1,s1,s6
    80001c90:	8591                	srai	a1,a1,0x4
    80001c92:	000ab783          	ld	a5,0(s5)
    80001c96:	02f585b3          	mul	a1,a1,a5
    80001c9a:	2585                	addiw	a1,a1,1
    80001c9c:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ca0:	4719                	li	a4,6
    80001ca2:	6685                	lui	a3,0x1
    80001ca4:	40b905b3          	sub	a1,s2,a1
    80001ca8:	854e                	mv	a0,s3
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	4a6080e7          	jalr	1190(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cb2:	19048493          	addi	s1,s1,400
    80001cb6:	fd4495e3          	bne	s1,s4,80001c80 <proc_mapstacks+0x38>
  }
}
    80001cba:	70e2                	ld	ra,56(sp)
    80001cbc:	7442                	ld	s0,48(sp)
    80001cbe:	74a2                	ld	s1,40(sp)
    80001cc0:	7902                	ld	s2,32(sp)
    80001cc2:	69e2                	ld	s3,24(sp)
    80001cc4:	6a42                	ld	s4,16(sp)
    80001cc6:	6aa2                	ld	s5,8(sp)
    80001cc8:	6b02                	ld	s6,0(sp)
    80001cca:	6121                	addi	sp,sp,64
    80001ccc:	8082                	ret
      panic("kalloc");
    80001cce:	00006517          	auipc	a0,0x6
    80001cd2:	5a250513          	addi	a0,a0,1442 # 80008270 <digits+0x230>
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	868080e7          	jalr	-1944(ra) # 8000053e <panic>

0000000080001cde <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001cde:	711d                	addi	sp,sp,-96
    80001ce0:	ec86                	sd	ra,88(sp)
    80001ce2:	e8a2                	sd	s0,80(sp)
    80001ce4:	e4a6                	sd	s1,72(sp)
    80001ce6:	e0ca                	sd	s2,64(sp)
    80001ce8:	fc4e                	sd	s3,56(sp)
    80001cea:	f852                	sd	s4,48(sp)
    80001cec:	f456                	sd	s5,40(sp)
    80001cee:	f05a                	sd	s6,32(sp)
    80001cf0:	ec5e                	sd	s7,24(sp)
    80001cf2:	e862                	sd	s8,16(sp)
    80001cf4:	e466                	sd	s9,8(sp)
    80001cf6:	e06a                	sd	s10,0(sp)
    80001cf8:	1080                	addi	s0,sp,96
  struct proc *p;

  initialize_lists();
    80001cfa:	00000097          	auipc	ra,0x0
    80001cfe:	c2a080e7          	jalr	-982(ra) # 80001924 <initialize_lists>

  initlock(&pid_lock, "nextpid");
    80001d02:	00006597          	auipc	a1,0x6
    80001d06:	57658593          	addi	a1,a1,1398 # 80008278 <digits+0x238>
    80001d0a:	00010517          	auipc	a0,0x10
    80001d0e:	ad650513          	addi	a0,a0,-1322 # 800117e0 <pid_lock>
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	e42080e7          	jalr	-446(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001d1a:	00006597          	auipc	a1,0x6
    80001d1e:	56658593          	addi	a1,a1,1382 # 80008280 <digits+0x240>
    80001d22:	00010517          	auipc	a0,0x10
    80001d26:	ad650513          	addi	a0,a0,-1322 # 800117f8 <wait_lock>
    80001d2a:	fffff097          	auipc	ra,0xfffff
    80001d2e:	e2a080e7          	jalr	-470(ra) # 80000b54 <initlock>

  int i = 0;
    80001d32:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d34:	00010497          	auipc	s1,0x10
    80001d38:	adc48493          	addi	s1,s1,-1316 # 80011810 <proc>
      initlock(&p->lock, "proc");
    80001d3c:	00006d17          	auipc	s10,0x6
    80001d40:	554d0d13          	addi	s10,s10,1364 # 80008290 <digits+0x250>
      initlock(&p->list_lock, "list_lock");
    80001d44:	00006c97          	auipc	s9,0x6
    80001d48:	554c8c93          	addi	s9,s9,1364 # 80008298 <digits+0x258>
      p->kstack = KSTACK((int) (p - proc));
    80001d4c:	8c26                	mv	s8,s1
    80001d4e:	00006b97          	auipc	s7,0x6
    80001d52:	2b2b8b93          	addi	s7,s7,690 # 80008000 <etext>
    80001d56:	04000a37          	lui	s4,0x4000
    80001d5a:	1a7d                	addi	s4,s4,-1
    80001d5c:	0a32                	slli	s4,s4,0xc
  p->next_proc = -1;
    80001d5e:	59fd                	li	s3,-1
      p->proc_ind = i;
      initialize_proc(p);
      append(&unused_list, p); // procinit to admit all UNUSED process entries
    80001d60:	00007b17          	auipc	s6,0x7
    80001d64:	b70b0b13          	addi	s6,s6,-1168 # 800088d0 <unused_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d68:	00016a97          	auipc	s5,0x16
    80001d6c:	ea8a8a93          	addi	s5,s5,-344 # 80017c10 <tickslock>
      initlock(&p->lock, "proc");
    80001d70:	85ea                	mv	a1,s10
    80001d72:	8526                	mv	a0,s1
    80001d74:	fffff097          	auipc	ra,0xfffff
    80001d78:	de0080e7          	jalr	-544(ra) # 80000b54 <initlock>
      initlock(&p->list_lock, "list_lock");
    80001d7c:	85e6                	mv	a1,s9
    80001d7e:	17848513          	addi	a0,s1,376
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	dd2080e7          	jalr	-558(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001d8a:	418487b3          	sub	a5,s1,s8
    80001d8e:	8791                	srai	a5,a5,0x4
    80001d90:	000bb703          	ld	a4,0(s7)
    80001d94:	02e787b3          	mul	a5,a5,a4
    80001d98:	2785                	addiw	a5,a5,1
    80001d9a:	00d7979b          	slliw	a5,a5,0xd
    80001d9e:	40fa07b3          	sub	a5,s4,a5
    80001da2:	e0bc                	sd	a5,64(s1)
      p->proc_ind = i;
    80001da4:	1724aa23          	sw	s2,372(s1)
  p->next_proc = -1;
    80001da8:	1734a623          	sw	s3,364(s1)
  p->prev_proc = -1;
    80001dac:	1734a823          	sw	s3,368(s1)
      append(&unused_list, p); // procinit to admit all UNUSED process entries
    80001db0:	85a6                	mv	a1,s1
    80001db2:	855a                	mv	a0,s6
    80001db4:	00000097          	auipc	ra,0x0
    80001db8:	c9c080e7          	jalr	-868(ra) # 80001a50 <append>
      i++;
    80001dbc:	2905                	addiw	s2,s2,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dbe:	19048493          	addi	s1,s1,400
    80001dc2:	fb5497e3          	bne	s1,s5,80001d70 <procinit+0x92>
  }
}
    80001dc6:	60e6                	ld	ra,88(sp)
    80001dc8:	6446                	ld	s0,80(sp)
    80001dca:	64a6                	ld	s1,72(sp)
    80001dcc:	6906                	ld	s2,64(sp)
    80001dce:	79e2                	ld	s3,56(sp)
    80001dd0:	7a42                	ld	s4,48(sp)
    80001dd2:	7aa2                	ld	s5,40(sp)
    80001dd4:	7b02                	ld	s6,32(sp)
    80001dd6:	6be2                	ld	s7,24(sp)
    80001dd8:	6c42                	ld	s8,16(sp)
    80001dda:	6ca2                	ld	s9,8(sp)
    80001ddc:	6d02                	ld	s10,0(sp)
    80001dde:	6125                	addi	sp,sp,96
    80001de0:	8082                	ret

0000000080001de2 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001de2:	1141                	addi	sp,sp,-16
    80001de4:	e422                	sd	s0,8(sp)
    80001de6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001de8:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001dea:	2501                	sext.w	a0,a0
    80001dec:	6422                	ld	s0,8(sp)
    80001dee:	0141                	addi	sp,sp,16
    80001df0:	8082                	ret

0000000080001df2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001df2:	1141                	addi	sp,sp,-16
    80001df4:	e422                	sd	s0,8(sp)
    80001df6:	0800                	addi	s0,sp,16
    80001df8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001dfa:	2781                	sext.w	a5,a5
    80001dfc:	0a800513          	li	a0,168
    80001e00:	02a787b3          	mul	a5,a5,a0
  return c;
}
    80001e04:	0000f517          	auipc	a0,0xf
    80001e08:	49c50513          	addi	a0,a0,1180 # 800112a0 <cpus>
    80001e0c:	953e                	add	a0,a0,a5
    80001e0e:	6422                	ld	s0,8(sp)
    80001e10:	0141                	addi	sp,sp,16
    80001e12:	8082                	ret

0000000080001e14 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001e14:	1101                	addi	sp,sp,-32
    80001e16:	ec06                	sd	ra,24(sp)
    80001e18:	e822                	sd	s0,16(sp)
    80001e1a:	e426                	sd	s1,8(sp)
    80001e1c:	1000                	addi	s0,sp,32
  push_off();
    80001e1e:	fffff097          	auipc	ra,0xfffff
    80001e22:	d7a080e7          	jalr	-646(ra) # 80000b98 <push_off>
    80001e26:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001e28:	2781                	sext.w	a5,a5
    80001e2a:	0a800713          	li	a4,168
    80001e2e:	02e787b3          	mul	a5,a5,a4
    80001e32:	0000f717          	auipc	a4,0xf
    80001e36:	46e70713          	addi	a4,a4,1134 # 800112a0 <cpus>
    80001e3a:	97ba                	add	a5,a5,a4
    80001e3c:	6384                	ld	s1,0(a5)
  pop_off();
    80001e3e:	fffff097          	auipc	ra,0xfffff
    80001e42:	dfa080e7          	jalr	-518(ra) # 80000c38 <pop_off>
  return p;
}
    80001e46:	8526                	mv	a0,s1
    80001e48:	60e2                	ld	ra,24(sp)
    80001e4a:	6442                	ld	s0,16(sp)
    80001e4c:	64a2                	ld	s1,8(sp)
    80001e4e:	6105                	addi	sp,sp,32
    80001e50:	8082                	ret

0000000080001e52 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001e52:	1141                	addi	sp,sp,-16
    80001e54:	e406                	sd	ra,8(sp)
    80001e56:	e022                	sd	s0,0(sp)
    80001e58:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001e5a:	00000097          	auipc	ra,0x0
    80001e5e:	fba080e7          	jalr	-70(ra) # 80001e14 <myproc>
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	e36080e7          	jalr	-458(ra) # 80000c98 <release>

  if (first) {
    80001e6a:	00007797          	auipc	a5,0x7
    80001e6e:	a567a783          	lw	a5,-1450(a5) # 800088c0 <first.1754>
    80001e72:	eb89                	bnez	a5,80001e84 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001e74:	00001097          	auipc	ra,0x1
    80001e78:	ee2080e7          	jalr	-286(ra) # 80002d56 <usertrapret>
}
    80001e7c:	60a2                	ld	ra,8(sp)
    80001e7e:	6402                	ld	s0,0(sp)
    80001e80:	0141                	addi	sp,sp,16
    80001e82:	8082                	ret
    first = 0;
    80001e84:	00007797          	auipc	a5,0x7
    80001e88:	a207ae23          	sw	zero,-1476(a5) # 800088c0 <first.1754>
    fsinit(ROOTDEV);
    80001e8c:	4505                	li	a0,1
    80001e8e:	00002097          	auipc	ra,0x2
    80001e92:	c0a080e7          	jalr	-1014(ra) # 80003a98 <fsinit>
    80001e96:	bff9                	j	80001e74 <forkret+0x22>

0000000080001e98 <allocpid>:
allocpid() {
    80001e98:	1101                	addi	sp,sp,-32
    80001e9a:	ec06                	sd	ra,24(sp)
    80001e9c:	e822                	sd	s0,16(sp)
    80001e9e:	e426                	sd	s1,8(sp)
    80001ea0:	e04a                	sd	s2,0(sp)
    80001ea2:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001ea4:	00007917          	auipc	s2,0x7
    80001ea8:	a2090913          	addi	s2,s2,-1504 # 800088c4 <nextpid>
    80001eac:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, nextpid + 1));
    80001eb0:	0014861b          	addiw	a2,s1,1
    80001eb4:	85a6                	mv	a1,s1
    80001eb6:	854a                	mv	a0,s2
    80001eb8:	00005097          	auipc	ra,0x5
    80001ebc:	9ee080e7          	jalr	-1554(ra) # 800068a6 <cas>
    80001ec0:	2501                	sext.w	a0,a0
    80001ec2:	f56d                	bnez	a0,80001eac <allocpid+0x14>
}
    80001ec4:	8526                	mv	a0,s1
    80001ec6:	60e2                	ld	ra,24(sp)
    80001ec8:	6442                	ld	s0,16(sp)
    80001eca:	64a2                	ld	s1,8(sp)
    80001ecc:	6902                	ld	s2,0(sp)
    80001ece:	6105                	addi	sp,sp,32
    80001ed0:	8082                	ret

0000000080001ed2 <proc_pagetable>:
{
    80001ed2:	1101                	addi	sp,sp,-32
    80001ed4:	ec06                	sd	ra,24(sp)
    80001ed6:	e822                	sd	s0,16(sp)
    80001ed8:	e426                	sd	s1,8(sp)
    80001eda:	e04a                	sd	s2,0(sp)
    80001edc:	1000                	addi	s0,sp,32
    80001ede:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	45a080e7          	jalr	1114(ra) # 8000133a <uvmcreate>
    80001ee8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001eea:	c121                	beqz	a0,80001f2a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001eec:	4729                	li	a4,10
    80001eee:	00005697          	auipc	a3,0x5
    80001ef2:	11268693          	addi	a3,a3,274 # 80007000 <_trampoline>
    80001ef6:	6605                	lui	a2,0x1
    80001ef8:	040005b7          	lui	a1,0x4000
    80001efc:	15fd                	addi	a1,a1,-1
    80001efe:	05b2                	slli	a1,a1,0xc
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	1b0080e7          	jalr	432(ra) # 800010b0 <mappages>
    80001f08:	02054863          	bltz	a0,80001f38 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001f0c:	4719                	li	a4,6
    80001f0e:	05893683          	ld	a3,88(s2)
    80001f12:	6605                	lui	a2,0x1
    80001f14:	020005b7          	lui	a1,0x2000
    80001f18:	15fd                	addi	a1,a1,-1
    80001f1a:	05b6                	slli	a1,a1,0xd
    80001f1c:	8526                	mv	a0,s1
    80001f1e:	fffff097          	auipc	ra,0xfffff
    80001f22:	192080e7          	jalr	402(ra) # 800010b0 <mappages>
    80001f26:	02054163          	bltz	a0,80001f48 <proc_pagetable+0x76>
}
    80001f2a:	8526                	mv	a0,s1
    80001f2c:	60e2                	ld	ra,24(sp)
    80001f2e:	6442                	ld	s0,16(sp)
    80001f30:	64a2                	ld	s1,8(sp)
    80001f32:	6902                	ld	s2,0(sp)
    80001f34:	6105                	addi	sp,sp,32
    80001f36:	8082                	ret
    uvmfree(pagetable, 0);
    80001f38:	4581                	li	a1,0
    80001f3a:	8526                	mv	a0,s1
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	5fa080e7          	jalr	1530(ra) # 80001536 <uvmfree>
    return 0;
    80001f44:	4481                	li	s1,0
    80001f46:	b7d5                	j	80001f2a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f48:	4681                	li	a3,0
    80001f4a:	4605                	li	a2,1
    80001f4c:	040005b7          	lui	a1,0x4000
    80001f50:	15fd                	addi	a1,a1,-1
    80001f52:	05b2                	slli	a1,a1,0xc
    80001f54:	8526                	mv	a0,s1
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	320080e7          	jalr	800(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001f5e:	4581                	li	a1,0
    80001f60:	8526                	mv	a0,s1
    80001f62:	fffff097          	auipc	ra,0xfffff
    80001f66:	5d4080e7          	jalr	1492(ra) # 80001536 <uvmfree>
    return 0;
    80001f6a:	4481                	li	s1,0
    80001f6c:	bf7d                	j	80001f2a <proc_pagetable+0x58>

0000000080001f6e <proc_freepagetable>:
{
    80001f6e:	1101                	addi	sp,sp,-32
    80001f70:	ec06                	sd	ra,24(sp)
    80001f72:	e822                	sd	s0,16(sp)
    80001f74:	e426                	sd	s1,8(sp)
    80001f76:	e04a                	sd	s2,0(sp)
    80001f78:	1000                	addi	s0,sp,32
    80001f7a:	84aa                	mv	s1,a0
    80001f7c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f7e:	4681                	li	a3,0
    80001f80:	4605                	li	a2,1
    80001f82:	040005b7          	lui	a1,0x4000
    80001f86:	15fd                	addi	a1,a1,-1
    80001f88:	05b2                	slli	a1,a1,0xc
    80001f8a:	fffff097          	auipc	ra,0xfffff
    80001f8e:	2ec080e7          	jalr	748(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001f92:	4681                	li	a3,0
    80001f94:	4605                	li	a2,1
    80001f96:	020005b7          	lui	a1,0x2000
    80001f9a:	15fd                	addi	a1,a1,-1
    80001f9c:	05b6                	slli	a1,a1,0xd
    80001f9e:	8526                	mv	a0,s1
    80001fa0:	fffff097          	auipc	ra,0xfffff
    80001fa4:	2d6080e7          	jalr	726(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001fa8:	85ca                	mv	a1,s2
    80001faa:	8526                	mv	a0,s1
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	58a080e7          	jalr	1418(ra) # 80001536 <uvmfree>
}
    80001fb4:	60e2                	ld	ra,24(sp)
    80001fb6:	6442                	ld	s0,16(sp)
    80001fb8:	64a2                	ld	s1,8(sp)
    80001fba:	6902                	ld	s2,0(sp)
    80001fbc:	6105                	addi	sp,sp,32
    80001fbe:	8082                	ret

0000000080001fc0 <freeproc>:
{
    80001fc0:	1101                	addi	sp,sp,-32
    80001fc2:	ec06                	sd	ra,24(sp)
    80001fc4:	e822                	sd	s0,16(sp)
    80001fc6:	e426                	sd	s1,8(sp)
    80001fc8:	1000                	addi	s0,sp,32
    80001fca:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001fcc:	6d28                	ld	a0,88(a0)
    80001fce:	c509                	beqz	a0,80001fd8 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	a28080e7          	jalr	-1496(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001fd8:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001fdc:	68a8                	ld	a0,80(s1)
    80001fde:	c511                	beqz	a0,80001fea <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001fe0:	64ac                	ld	a1,72(s1)
    80001fe2:	00000097          	auipc	ra,0x0
    80001fe6:	f8c080e7          	jalr	-116(ra) # 80001f6e <proc_freepagetable>
  p->pagetable = 0;
    80001fea:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001fee:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ff2:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ff6:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ffa:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ffe:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80002002:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80002006:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    8000200a:	0004ac23          	sw	zero,24(s1)
  remove(&zombie_list, p); // remove the freed process from the ZOMBIE list
    8000200e:	85a6                	mv	a1,s1
    80002010:	00007517          	auipc	a0,0x7
    80002014:	90050513          	addi	a0,a0,-1792 # 80008910 <zombie_list>
    80002018:	00000097          	auipc	ra,0x0
    8000201c:	b00080e7          	jalr	-1280(ra) # 80001b18 <remove>
  append(&unused_list, p); // admit its entry to the UNUSED entry list.
    80002020:	85a6                	mv	a1,s1
    80002022:	00007517          	auipc	a0,0x7
    80002026:	8ae50513          	addi	a0,a0,-1874 # 800088d0 <unused_list>
    8000202a:	00000097          	auipc	ra,0x0
    8000202e:	a26080e7          	jalr	-1498(ra) # 80001a50 <append>
}
    80002032:	60e2                	ld	ra,24(sp)
    80002034:	6442                	ld	s0,16(sp)
    80002036:	64a2                	ld	s1,8(sp)
    80002038:	6105                	addi	sp,sp,32
    8000203a:	8082                	ret

000000008000203c <allocproc>:
{
    8000203c:	715d                	addi	sp,sp,-80
    8000203e:	e486                	sd	ra,72(sp)
    80002040:	e0a2                	sd	s0,64(sp)
    80002042:	fc26                	sd	s1,56(sp)
    80002044:	f84a                	sd	s2,48(sp)
    80002046:	f44e                	sd	s3,40(sp)
    80002048:	f052                	sd	s4,32(sp)
    8000204a:	ec56                	sd	s5,24(sp)
    8000204c:	e85a                	sd	s6,16(sp)
    8000204e:	e45e                	sd	s7,8(sp)
    80002050:	0880                	addi	s0,sp,80
  while(!isEmpty(&unused_list)){
    80002052:	00007717          	auipc	a4,0x7
    80002056:	87e72703          	lw	a4,-1922(a4) # 800088d0 <unused_list>
    8000205a:	57fd                	li	a5,-1
    8000205c:	14f70063          	beq	a4,a5,8000219c <allocproc+0x160>
    p = &proc[get_head(&unused_list)];
    80002060:	00007a17          	auipc	s4,0x7
    80002064:	870a0a13          	addi	s4,s4,-1936 # 800088d0 <unused_list>
    80002068:	19000b13          	li	s6,400
    8000206c:	0000fa97          	auipc	s5,0xf
    80002070:	7a4a8a93          	addi	s5,s5,1956 # 80011810 <proc>
  while(!isEmpty(&unused_list)){
    80002074:	5bfd                	li	s7,-1
    p = &proc[get_head(&unused_list)];
    80002076:	8552                	mv	a0,s4
    80002078:	00000097          	auipc	ra,0x0
    8000207c:	982080e7          	jalr	-1662(ra) # 800019fa <get_head>
    80002080:	892a                	mv	s2,a0
    80002082:	036509b3          	mul	s3,a0,s6
    80002086:	015984b3          	add	s1,s3,s5
    acquire(&p->lock);
    8000208a:	8526                	mv	a0,s1
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	b58080e7          	jalr	-1192(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80002094:	4c9c                	lw	a5,24(s1)
    80002096:	c79d                	beqz	a5,800020c4 <allocproc+0x88>
      release(&p->lock);
    80002098:	8526                	mv	a0,s1
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	bfe080e7          	jalr	-1026(ra) # 80000c98 <release>
  while(!isEmpty(&unused_list)){
    800020a2:	000a2783          	lw	a5,0(s4)
    800020a6:	fd7798e3          	bne	a5,s7,80002076 <allocproc+0x3a>
  return 0;
    800020aa:	4481                	li	s1,0
}
    800020ac:	8526                	mv	a0,s1
    800020ae:	60a6                	ld	ra,72(sp)
    800020b0:	6406                	ld	s0,64(sp)
    800020b2:	74e2                	ld	s1,56(sp)
    800020b4:	7942                	ld	s2,48(sp)
    800020b6:	79a2                	ld	s3,40(sp)
    800020b8:	7a02                	ld	s4,32(sp)
    800020ba:	6ae2                	ld	s5,24(sp)
    800020bc:	6b42                	ld	s6,16(sp)
    800020be:	6ba2                	ld	s7,8(sp)
    800020c0:	6161                	addi	sp,sp,80
    800020c2:	8082                	ret
      remove(&unused_list, p); // choose the new process entry to initialize from the UNUSED entry list.
    800020c4:	85a6                	mv	a1,s1
    800020c6:	00007517          	auipc	a0,0x7
    800020ca:	80a50513          	addi	a0,a0,-2038 # 800088d0 <unused_list>
    800020ce:	00000097          	auipc	ra,0x0
    800020d2:	a4a080e7          	jalr	-1462(ra) # 80001b18 <remove>
  p->pid = allocpid();
    800020d6:	00000097          	auipc	ra,0x0
    800020da:	dc2080e7          	jalr	-574(ra) # 80001e98 <allocpid>
    800020de:	19000a13          	li	s4,400
    800020e2:	034907b3          	mul	a5,s2,s4
    800020e6:	0000fa17          	auipc	s4,0xf
    800020ea:	72aa0a13          	addi	s4,s4,1834 # 80011810 <proc>
    800020ee:	9a3e                	add	s4,s4,a5
    800020f0:	02aa2823          	sw	a0,48(s4)
  p->state = USED;
    800020f4:	4785                	li	a5,1
    800020f6:	00fa2c23          	sw	a5,24(s4)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800020fa:	fffff097          	auipc	ra,0xfffff
    800020fe:	9fa080e7          	jalr	-1542(ra) # 80000af4 <kalloc>
    80002102:	8aaa                	mv	s5,a0
    80002104:	04aa3c23          	sd	a0,88(s4)
    80002108:	c135                	beqz	a0,8000216c <allocproc+0x130>
  p->pagetable = proc_pagetable(p);
    8000210a:	8526                	mv	a0,s1
    8000210c:	00000097          	auipc	ra,0x0
    80002110:	dc6080e7          	jalr	-570(ra) # 80001ed2 <proc_pagetable>
    80002114:	8a2a                	mv	s4,a0
    80002116:	19000793          	li	a5,400
    8000211a:	02f90733          	mul	a4,s2,a5
    8000211e:	0000f797          	auipc	a5,0xf
    80002122:	6f278793          	addi	a5,a5,1778 # 80011810 <proc>
    80002126:	97ba                	add	a5,a5,a4
    80002128:	eba8                	sd	a0,80(a5)
  if(p->pagetable == 0){
    8000212a:	cd29                	beqz	a0,80002184 <allocproc+0x148>
  memset(&p->context, 0, sizeof(p->context));
    8000212c:	06098513          	addi	a0,s3,96
    80002130:	0000f997          	auipc	s3,0xf
    80002134:	6e098993          	addi	s3,s3,1760 # 80011810 <proc>
    80002138:	07000613          	li	a2,112
    8000213c:	4581                	li	a1,0
    8000213e:	954e                	add	a0,a0,s3
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	ba0080e7          	jalr	-1120(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80002148:	19000793          	li	a5,400
    8000214c:	02f90933          	mul	s2,s2,a5
    80002150:	994e                	add	s2,s2,s3
    80002152:	00000797          	auipc	a5,0x0
    80002156:	d0078793          	addi	a5,a5,-768 # 80001e52 <forkret>
    8000215a:	06f93023          	sd	a5,96(s2)
  p->context.sp = p->kstack + PGSIZE;
    8000215e:	04093783          	ld	a5,64(s2)
    80002162:	6705                	lui	a4,0x1
    80002164:	97ba                	add	a5,a5,a4
    80002166:	06f93423          	sd	a5,104(s2)
  return p;
    8000216a:	b789                	j	800020ac <allocproc+0x70>
    freeproc(p);
    8000216c:	8526                	mv	a0,s1
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	e52080e7          	jalr	-430(ra) # 80001fc0 <freeproc>
    release(&p->lock);
    80002176:	8526                	mv	a0,s1
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	b20080e7          	jalr	-1248(ra) # 80000c98 <release>
    return 0;
    80002180:	84d6                	mv	s1,s5
    80002182:	b72d                	j	800020ac <allocproc+0x70>
    freeproc(p);
    80002184:	8526                	mv	a0,s1
    80002186:	00000097          	auipc	ra,0x0
    8000218a:	e3a080e7          	jalr	-454(ra) # 80001fc0 <freeproc>
    release(&p->lock);
    8000218e:	8526                	mv	a0,s1
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	b08080e7          	jalr	-1272(ra) # 80000c98 <release>
    return 0;
    80002198:	84d2                	mv	s1,s4
    8000219a:	bf09                	j	800020ac <allocproc+0x70>
  return 0;
    8000219c:	4481                	li	s1,0
    8000219e:	b739                	j	800020ac <allocproc+0x70>

00000000800021a0 <userinit>:
{
    800021a0:	1101                	addi	sp,sp,-32
    800021a2:	ec06                	sd	ra,24(sp)
    800021a4:	e822                	sd	s0,16(sp)
    800021a6:	e426                	sd	s1,8(sp)
    800021a8:	1000                	addi	s0,sp,32
  p = allocproc();
    800021aa:	00000097          	auipc	ra,0x0
    800021ae:	e92080e7          	jalr	-366(ra) # 8000203c <allocproc>
    800021b2:	84aa                	mv	s1,a0
  initproc = p;
    800021b4:	00007797          	auipc	a5,0x7
    800021b8:	e6a7ba23          	sd	a0,-396(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800021bc:	03400613          	li	a2,52
    800021c0:	00006597          	auipc	a1,0x6
    800021c4:	77058593          	addi	a1,a1,1904 # 80008930 <initcode>
    800021c8:	6928                	ld	a0,80(a0)
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	19e080e7          	jalr	414(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    800021d2:	6785                	lui	a5,0x1
    800021d4:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    800021d6:	6cb8                	ld	a4,88(s1)
    800021d8:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800021dc:	6cb8                	ld	a4,88(s1)
    800021de:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800021e0:	4641                	li	a2,16
    800021e2:	00006597          	auipc	a1,0x6
    800021e6:	0c658593          	addi	a1,a1,198 # 800082a8 <digits+0x268>
    800021ea:	15848513          	addi	a0,s1,344
    800021ee:	fffff097          	auipc	ra,0xfffff
    800021f2:	c44080e7          	jalr	-956(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800021f6:	00006517          	auipc	a0,0x6
    800021fa:	0c250513          	addi	a0,a0,194 # 800082b8 <digits+0x278>
    800021fe:	00002097          	auipc	ra,0x2
    80002202:	2c8080e7          	jalr	712(ra) # 800044c6 <namei>
    80002206:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    8000220a:	478d                	li	a5,3
    8000220c:	cc9c                	sw	a5,24(s1)
  append(&(cpus[0].runnable_list), p); // admit the init process (the first process in the OS) to the first CPU’s list.
    8000220e:	85a6                	mv	a1,s1
    80002210:	0000f517          	auipc	a0,0xf
    80002214:	11850513          	addi	a0,a0,280 # 80011328 <cpus+0x88>
    80002218:	00000097          	auipc	ra,0x0
    8000221c:	838080e7          	jalr	-1992(ra) # 80001a50 <append>
  release(&p->lock);
    80002220:	8526                	mv	a0,s1
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	a76080e7          	jalr	-1418(ra) # 80000c98 <release>
}
    8000222a:	60e2                	ld	ra,24(sp)
    8000222c:	6442                	ld	s0,16(sp)
    8000222e:	64a2                	ld	s1,8(sp)
    80002230:	6105                	addi	sp,sp,32
    80002232:	8082                	ret

0000000080002234 <growproc>:
{
    80002234:	1101                	addi	sp,sp,-32
    80002236:	ec06                	sd	ra,24(sp)
    80002238:	e822                	sd	s0,16(sp)
    8000223a:	e426                	sd	s1,8(sp)
    8000223c:	e04a                	sd	s2,0(sp)
    8000223e:	1000                	addi	s0,sp,32
    80002240:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002242:	00000097          	auipc	ra,0x0
    80002246:	bd2080e7          	jalr	-1070(ra) # 80001e14 <myproc>
    8000224a:	892a                	mv	s2,a0
  sz = p->sz;
    8000224c:	652c                	ld	a1,72(a0)
    8000224e:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002252:	00904f63          	bgtz	s1,80002270 <growproc+0x3c>
  } else if(n < 0){
    80002256:	0204cc63          	bltz	s1,8000228e <growproc+0x5a>
  p->sz = sz;
    8000225a:	1602                	slli	a2,a2,0x20
    8000225c:	9201                	srli	a2,a2,0x20
    8000225e:	04c93423          	sd	a2,72(s2)
  return 0;
    80002262:	4501                	li	a0,0
}
    80002264:	60e2                	ld	ra,24(sp)
    80002266:	6442                	ld	s0,16(sp)
    80002268:	64a2                	ld	s1,8(sp)
    8000226a:	6902                	ld	s2,0(sp)
    8000226c:	6105                	addi	sp,sp,32
    8000226e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002270:	9e25                	addw	a2,a2,s1
    80002272:	1602                	slli	a2,a2,0x20
    80002274:	9201                	srli	a2,a2,0x20
    80002276:	1582                	slli	a1,a1,0x20
    80002278:	9181                	srli	a1,a1,0x20
    8000227a:	6928                	ld	a0,80(a0)
    8000227c:	fffff097          	auipc	ra,0xfffff
    80002280:	1a6080e7          	jalr	422(ra) # 80001422 <uvmalloc>
    80002284:	0005061b          	sext.w	a2,a0
    80002288:	fa69                	bnez	a2,8000225a <growproc+0x26>
      return -1;
    8000228a:	557d                	li	a0,-1
    8000228c:	bfe1                	j	80002264 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000228e:	9e25                	addw	a2,a2,s1
    80002290:	1602                	slli	a2,a2,0x20
    80002292:	9201                	srli	a2,a2,0x20
    80002294:	1582                	slli	a1,a1,0x20
    80002296:	9181                	srli	a1,a1,0x20
    80002298:	6928                	ld	a0,80(a0)
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	140080e7          	jalr	320(ra) # 800013da <uvmdealloc>
    800022a2:	0005061b          	sext.w	a2,a0
    800022a6:	bf55                	j	8000225a <growproc+0x26>

00000000800022a8 <fork>:
{
    800022a8:	7139                	addi	sp,sp,-64
    800022aa:	fc06                	sd	ra,56(sp)
    800022ac:	f822                	sd	s0,48(sp)
    800022ae:	f426                	sd	s1,40(sp)
    800022b0:	f04a                	sd	s2,32(sp)
    800022b2:	ec4e                	sd	s3,24(sp)
    800022b4:	e852                	sd	s4,16(sp)
    800022b6:	e456                	sd	s5,8(sp)
    800022b8:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    800022ba:	00000097          	auipc	ra,0x0
    800022be:	b5a080e7          	jalr	-1190(ra) # 80001e14 <myproc>
    800022c2:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    800022c4:	00000097          	auipc	ra,0x0
    800022c8:	d78080e7          	jalr	-648(ra) # 8000203c <allocproc>
    800022cc:	14050663          	beqz	a0,80002418 <fork+0x170>
    800022d0:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800022d2:	04893603          	ld	a2,72(s2)
    800022d6:	692c                	ld	a1,80(a0)
    800022d8:	05093503          	ld	a0,80(s2)
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	292080e7          	jalr	658(ra) # 8000156e <uvmcopy>
    800022e4:	04054663          	bltz	a0,80002330 <fork+0x88>
  np->sz = p->sz;
    800022e8:	04893783          	ld	a5,72(s2)
    800022ec:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    800022f0:	05893683          	ld	a3,88(s2)
    800022f4:	87b6                	mv	a5,a3
    800022f6:	0589b703          	ld	a4,88(s3)
    800022fa:	12068693          	addi	a3,a3,288
    800022fe:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002302:	6788                	ld	a0,8(a5)
    80002304:	6b8c                	ld	a1,16(a5)
    80002306:	6f90                	ld	a2,24(a5)
    80002308:	01073023          	sd	a6,0(a4)
    8000230c:	e708                	sd	a0,8(a4)
    8000230e:	eb0c                	sd	a1,16(a4)
    80002310:	ef10                	sd	a2,24(a4)
    80002312:	02078793          	addi	a5,a5,32
    80002316:	02070713          	addi	a4,a4,32
    8000231a:	fed792e3          	bne	a5,a3,800022fe <fork+0x56>
  np->trapframe->a0 = 0;
    8000231e:	0589b783          	ld	a5,88(s3)
    80002322:	0607b823          	sd	zero,112(a5)
    80002326:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    8000232a:	15000a13          	li	s4,336
    8000232e:	a03d                	j	8000235c <fork+0xb4>
    freeproc(np);
    80002330:	854e                	mv	a0,s3
    80002332:	00000097          	auipc	ra,0x0
    80002336:	c8e080e7          	jalr	-882(ra) # 80001fc0 <freeproc>
    release(&np->lock);
    8000233a:	854e                	mv	a0,s3
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	95c080e7          	jalr	-1700(ra) # 80000c98 <release>
    return -1;
    80002344:	5afd                	li	s5,-1
    80002346:	a87d                	j	80002404 <fork+0x15c>
      np->ofile[i] = filedup(p->ofile[i]);
    80002348:	00003097          	auipc	ra,0x3
    8000234c:	814080e7          	jalr	-2028(ra) # 80004b5c <filedup>
    80002350:	009987b3          	add	a5,s3,s1
    80002354:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002356:	04a1                	addi	s1,s1,8
    80002358:	01448763          	beq	s1,s4,80002366 <fork+0xbe>
    if(p->ofile[i])
    8000235c:	009907b3          	add	a5,s2,s1
    80002360:	6388                	ld	a0,0(a5)
    80002362:	f17d                	bnez	a0,80002348 <fork+0xa0>
    80002364:	bfcd                	j	80002356 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002366:	15093503          	ld	a0,336(s2)
    8000236a:	00002097          	auipc	ra,0x2
    8000236e:	968080e7          	jalr	-1688(ra) # 80003cd2 <idup>
    80002372:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002376:	4641                	li	a2,16
    80002378:	15890593          	addi	a1,s2,344
    8000237c:	15898513          	addi	a0,s3,344
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	ab2080e7          	jalr	-1358(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002388:	0309aa83          	lw	s5,48(s3)
  release(&np->lock);
    8000238c:	854e                	mv	a0,s3
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	90a080e7          	jalr	-1782(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002396:	0000fa17          	auipc	s4,0xf
    8000239a:	f0aa0a13          	addi	s4,s4,-246 # 800112a0 <cpus>
    8000239e:	0000f497          	auipc	s1,0xf
    800023a2:	45a48493          	addi	s1,s1,1114 # 800117f8 <wait_lock>
    800023a6:	8526                	mv	a0,s1
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	83c080e7          	jalr	-1988(ra) # 80000be4 <acquire>
  np->parent = p;
    800023b0:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    800023b4:	8526                	mv	a0,s1
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	8e2080e7          	jalr	-1822(ra) # 80000c98 <release>
  acquire(&np->lock);
    800023be:	854e                	mv	a0,s3
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	824080e7          	jalr	-2012(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800023c8:	478d                	li	a5,3
    800023ca:	00f9ac23          	sw	a5,24(s3)
  np->last_cpu = p->last_cpu; // case BLNCFLG=OFF -> cpu = parent's cpu 
    800023ce:	16892483          	lw	s1,360(s2)
    800023d2:	1699a423          	sw	s1,360(s3)
  struct cpu *c = &cpus[np->last_cpu];
    800023d6:	0a800513          	li	a0,168
    800023da:	02a484b3          	mul	s1,s1,a0
  increment_cpu_process_count(c);
    800023de:	009a0533          	add	a0,s4,s1
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	45c080e7          	jalr	1116(ra) # 8000183e <increment_cpu_process_count>
  append(&(c->runnable_list), np); // admit the new process to the father’s current CPU’s ready list
    800023ea:	08848513          	addi	a0,s1,136
    800023ee:	85ce                	mv	a1,s3
    800023f0:	9552                	add	a0,a0,s4
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	65e080e7          	jalr	1630(ra) # 80001a50 <append>
  release(&np->lock);
    800023fa:	854e                	mv	a0,s3
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	89c080e7          	jalr	-1892(ra) # 80000c98 <release>
}
    80002404:	8556                	mv	a0,s5
    80002406:	70e2                	ld	ra,56(sp)
    80002408:	7442                	ld	s0,48(sp)
    8000240a:	74a2                	ld	s1,40(sp)
    8000240c:	7902                	ld	s2,32(sp)
    8000240e:	69e2                	ld	s3,24(sp)
    80002410:	6a42                	ld	s4,16(sp)
    80002412:	6aa2                	ld	s5,8(sp)
    80002414:	6121                	addi	sp,sp,64
    80002416:	8082                	ret
    return -1;
    80002418:	5afd                	li	s5,-1
    8000241a:	b7ed                	j	80002404 <fork+0x15c>

000000008000241c <scheduler>:
{
    8000241c:	715d                	addi	sp,sp,-80
    8000241e:	e486                	sd	ra,72(sp)
    80002420:	e0a2                	sd	s0,64(sp)
    80002422:	fc26                	sd	s1,56(sp)
    80002424:	f84a                	sd	s2,48(sp)
    80002426:	f44e                	sd	s3,40(sp)
    80002428:	f052                	sd	s4,32(sp)
    8000242a:	ec56                	sd	s5,24(sp)
    8000242c:	e85a                	sd	s6,16(sp)
    8000242e:	e45e                	sd	s7,8(sp)
    80002430:	e062                	sd	s8,0(sp)
    80002432:	0880                	addi	s0,sp,80
    80002434:	8712                	mv	a4,tp
  int id = r_tp();
    80002436:	2701                	sext.w	a4,a4
  c->proc = 0;
    80002438:	0000fb17          	auipc	s6,0xf
    8000243c:	e68b0b13          	addi	s6,s6,-408 # 800112a0 <cpus>
    80002440:	0a800793          	li	a5,168
    80002444:	02f707b3          	mul	a5,a4,a5
    80002448:	00fb06b3          	add	a3,s6,a5
    8000244c:	0006b023          	sd	zero,0(a3)
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    80002450:	08878a13          	addi	s4,a5,136
    80002454:	9a5a                	add	s4,s4,s6
          swtch(&c->context, &p->context);
    80002456:	07a1                	addi	a5,a5,8
    80002458:	9b3e                	add	s6,s6,a5
  h = lst->head == -1;
    8000245a:	8936                	mv	s2,a3
      if(p->state == RUNNABLE) {
    8000245c:	0000f997          	auipc	s3,0xf
    80002460:	3b498993          	addi	s3,s3,948 # 80011810 <proc>
    80002464:	19000a93          	li	s5,400
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002468:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000246c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002470:	10079073          	csrw	sstatus,a5
    80002474:	4b8d                	li	s7,3
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    80002476:	54fd                	li	s1,-1
    80002478:	08892783          	lw	a5,136(s2)
    8000247c:	fe9786e3          	beq	a5,s1,80002468 <scheduler+0x4c>
      p =  &proc[get_head(&c->runnable_list)]; //  pick the first process from the correct CPU’s list.
    80002480:	8552                	mv	a0,s4
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	578080e7          	jalr	1400(ra) # 800019fa <get_head>
      if(p->state == RUNNABLE) {
    8000248a:	035507b3          	mul	a5,a0,s5
    8000248e:	97ce                	add	a5,a5,s3
    80002490:	4f9c                	lw	a5,24(a5)
    80002492:	ff7793e3          	bne	a5,s7,80002478 <scheduler+0x5c>
    80002496:	035504b3          	mul	s1,a0,s5
      p =  &proc[get_head(&c->runnable_list)]; //  pick the first process from the correct CPU’s list.
    8000249a:	01348c33          	add	s8,s1,s3
        acquire(&p->lock);
    8000249e:	8562                	mv	a0,s8
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	744080e7          	jalr	1860(ra) # 80000be4 <acquire>
          remove(&(c->runnable_list), p);
    800024a8:	85e2                	mv	a1,s8
    800024aa:	8552                	mv	a0,s4
    800024ac:	fffff097          	auipc	ra,0xfffff
    800024b0:	66c080e7          	jalr	1644(ra) # 80001b18 <remove>
          p->state = RUNNING;
    800024b4:	4791                	li	a5,4
    800024b6:	00fc2c23          	sw	a5,24(s8)
          c->proc = p;
    800024ba:	01893023          	sd	s8,0(s2)
          p->last_cpu = c->cpu_id;
    800024be:	08492783          	lw	a5,132(s2)
    800024c2:	16fc2423          	sw	a5,360(s8)
          swtch(&c->context, &p->context);
    800024c6:	06048593          	addi	a1,s1,96
    800024ca:	95ce                	add	a1,a1,s3
    800024cc:	855a                	mv	a0,s6
    800024ce:	00000097          	auipc	ra,0x0
    800024d2:	7de080e7          	jalr	2014(ra) # 80002cac <swtch>
          c->proc = 0;
    800024d6:	00093023          	sd	zero,0(s2)
        release(&p->lock);
    800024da:	8562                	mv	a0,s8
    800024dc:	ffffe097          	auipc	ra,0xffffe
    800024e0:	7bc080e7          	jalr	1980(ra) # 80000c98 <release>
    800024e4:	bf49                	j	80002476 <scheduler+0x5a>

00000000800024e6 <sched>:
{
    800024e6:	7179                	addi	sp,sp,-48
    800024e8:	f406                	sd	ra,40(sp)
    800024ea:	f022                	sd	s0,32(sp)
    800024ec:	ec26                	sd	s1,24(sp)
    800024ee:	e84a                	sd	s2,16(sp)
    800024f0:	e44e                	sd	s3,8(sp)
    800024f2:	e052                	sd	s4,0(sp)
    800024f4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800024f6:	00000097          	auipc	ra,0x0
    800024fa:	91e080e7          	jalr	-1762(ra) # 80001e14 <myproc>
    800024fe:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	66a080e7          	jalr	1642(ra) # 80000b6a <holding>
    80002508:	c141                	beqz	a0,80002588 <sched+0xa2>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000250a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000250c:	2781                	sext.w	a5,a5
    8000250e:	0a800713          	li	a4,168
    80002512:	02e787b3          	mul	a5,a5,a4
    80002516:	0000f717          	auipc	a4,0xf
    8000251a:	d8a70713          	addi	a4,a4,-630 # 800112a0 <cpus>
    8000251e:	97ba                	add	a5,a5,a4
    80002520:	5fb8                	lw	a4,120(a5)
    80002522:	4785                	li	a5,1
    80002524:	06f71a63          	bne	a4,a5,80002598 <sched+0xb2>
  if(p->state == RUNNING)
    80002528:	4c98                	lw	a4,24(s1)
    8000252a:	4791                	li	a5,4
    8000252c:	06f70e63          	beq	a4,a5,800025a8 <sched+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002530:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002534:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002536:	e3c9                	bnez	a5,800025b8 <sched+0xd2>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002538:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000253a:	0000f917          	auipc	s2,0xf
    8000253e:	d6690913          	addi	s2,s2,-666 # 800112a0 <cpus>
    80002542:	2781                	sext.w	a5,a5
    80002544:	0a800993          	li	s3,168
    80002548:	033787b3          	mul	a5,a5,s3
    8000254c:	97ca                	add	a5,a5,s2
    8000254e:	07c7aa03          	lw	s4,124(a5)
    80002552:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    80002554:	2581                	sext.w	a1,a1
    80002556:	033585b3          	mul	a1,a1,s3
    8000255a:	05a1                	addi	a1,a1,8
    8000255c:	95ca                	add	a1,a1,s2
    8000255e:	06048513          	addi	a0,s1,96
    80002562:	00000097          	auipc	ra,0x0
    80002566:	74a080e7          	jalr	1866(ra) # 80002cac <swtch>
    8000256a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000256c:	2781                	sext.w	a5,a5
    8000256e:	033787b3          	mul	a5,a5,s3
    80002572:	993e                	add	s2,s2,a5
    80002574:	07492e23          	sw	s4,124(s2)
}
    80002578:	70a2                	ld	ra,40(sp)
    8000257a:	7402                	ld	s0,32(sp)
    8000257c:	64e2                	ld	s1,24(sp)
    8000257e:	6942                	ld	s2,16(sp)
    80002580:	69a2                	ld	s3,8(sp)
    80002582:	6a02                	ld	s4,0(sp)
    80002584:	6145                	addi	sp,sp,48
    80002586:	8082                	ret
    panic("sched p->lock");
    80002588:	00006517          	auipc	a0,0x6
    8000258c:	d3850513          	addi	a0,a0,-712 # 800082c0 <digits+0x280>
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	fae080e7          	jalr	-82(ra) # 8000053e <panic>
    panic("sched locks");
    80002598:	00006517          	auipc	a0,0x6
    8000259c:	d3850513          	addi	a0,a0,-712 # 800082d0 <digits+0x290>
    800025a0:	ffffe097          	auipc	ra,0xffffe
    800025a4:	f9e080e7          	jalr	-98(ra) # 8000053e <panic>
    panic("sched running");
    800025a8:	00006517          	auipc	a0,0x6
    800025ac:	d3850513          	addi	a0,a0,-712 # 800082e0 <digits+0x2a0>
    800025b0:	ffffe097          	auipc	ra,0xffffe
    800025b4:	f8e080e7          	jalr	-114(ra) # 8000053e <panic>
    panic("sched interruptible");
    800025b8:	00006517          	auipc	a0,0x6
    800025bc:	d3850513          	addi	a0,a0,-712 # 800082f0 <digits+0x2b0>
    800025c0:	ffffe097          	auipc	ra,0xffffe
    800025c4:	f7e080e7          	jalr	-130(ra) # 8000053e <panic>

00000000800025c8 <yield>:
{
    800025c8:	1101                	addi	sp,sp,-32
    800025ca:	ec06                	sd	ra,24(sp)
    800025cc:	e822                	sd	s0,16(sp)
    800025ce:	e426                	sd	s1,8(sp)
    800025d0:	e04a                	sd	s2,0(sp)
    800025d2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800025d4:	00000097          	auipc	ra,0x0
    800025d8:	840080e7          	jalr	-1984(ra) # 80001e14 <myproc>
    800025dc:	84aa                	mv	s1,a0
    800025de:	8912                	mv	s2,tp
  acquire(&p->lock);
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	604080e7          	jalr	1540(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800025e8:	478d                	li	a5,3
    800025ea:	cc9c                	sw	a5,24(s1)
  append(&(c->runnable_list), p);
    800025ec:	2901                	sext.w	s2,s2
    800025ee:	0a800513          	li	a0,168
    800025f2:	02a90933          	mul	s2,s2,a0
    800025f6:	85a6                	mv	a1,s1
    800025f8:	0000f517          	auipc	a0,0xf
    800025fc:	d3050513          	addi	a0,a0,-720 # 80011328 <cpus+0x88>
    80002600:	954a                	add	a0,a0,s2
    80002602:	fffff097          	auipc	ra,0xfffff
    80002606:	44e080e7          	jalr	1102(ra) # 80001a50 <append>
  sched();
    8000260a:	00000097          	auipc	ra,0x0
    8000260e:	edc080e7          	jalr	-292(ra) # 800024e6 <sched>
  release(&p->lock);
    80002612:	8526                	mv	a0,s1
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	684080e7          	jalr	1668(ra) # 80000c98 <release>
}
    8000261c:	60e2                	ld	ra,24(sp)
    8000261e:	6442                	ld	s0,16(sp)
    80002620:	64a2                	ld	s1,8(sp)
    80002622:	6902                	ld	s2,0(sp)
    80002624:	6105                	addi	sp,sp,32
    80002626:	8082                	ret

0000000080002628 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002628:	7179                	addi	sp,sp,-48
    8000262a:	f406                	sd	ra,40(sp)
    8000262c:	f022                	sd	s0,32(sp)
    8000262e:	ec26                	sd	s1,24(sp)
    80002630:	e84a                	sd	s2,16(sp)
    80002632:	e44e                	sd	s3,8(sp)
    80002634:	1800                	addi	s0,sp,48
    80002636:	89aa                	mv	s3,a0
    80002638:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000263a:	fffff097          	auipc	ra,0xfffff
    8000263e:	7da080e7          	jalr	2010(ra) # 80001e14 <myproc>
    80002642:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	5a0080e7          	jalr	1440(ra) # 80000be4 <acquire>
  release(lk);
    8000264c:	854a                	mv	a0,s2
    8000264e:	ffffe097          	auipc	ra,0xffffe
    80002652:	64a080e7          	jalr	1610(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002656:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000265a:	4789                	li	a5,2
    8000265c:	cc9c                	sw	a5,24(s1)
  //printf("insert sleep sleep %d\n", p->index); //delete
  append(&sleeping_list, p);
    8000265e:	85a6                	mv	a1,s1
    80002660:	00006517          	auipc	a0,0x6
    80002664:	29050513          	addi	a0,a0,656 # 800088f0 <sleeping_list>
    80002668:	fffff097          	auipc	ra,0xfffff
    8000266c:	3e8080e7          	jalr	1000(ra) # 80001a50 <append>

  sched();
    80002670:	00000097          	auipc	ra,0x0
    80002674:	e76080e7          	jalr	-394(ra) # 800024e6 <sched>

  // Tidy up.
  p->chan = 0;
    80002678:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000267c:	8526                	mv	a0,s1
    8000267e:	ffffe097          	auipc	ra,0xffffe
    80002682:	61a080e7          	jalr	1562(ra) # 80000c98 <release>
  acquire(lk);
    80002686:	854a                	mv	a0,s2
    80002688:	ffffe097          	auipc	ra,0xffffe
    8000268c:	55c080e7          	jalr	1372(ra) # 80000be4 <acquire>
}
    80002690:	70a2                	ld	ra,40(sp)
    80002692:	7402                	ld	s0,32(sp)
    80002694:	64e2                	ld	s1,24(sp)
    80002696:	6942                	ld	s2,16(sp)
    80002698:	69a2                	ld	s3,8(sp)
    8000269a:	6145                	addi	sp,sp,48
    8000269c:	8082                	ret

000000008000269e <wait>:
{
    8000269e:	715d                	addi	sp,sp,-80
    800026a0:	e486                	sd	ra,72(sp)
    800026a2:	e0a2                	sd	s0,64(sp)
    800026a4:	fc26                	sd	s1,56(sp)
    800026a6:	f84a                	sd	s2,48(sp)
    800026a8:	f44e                	sd	s3,40(sp)
    800026aa:	f052                	sd	s4,32(sp)
    800026ac:	ec56                	sd	s5,24(sp)
    800026ae:	e85a                	sd	s6,16(sp)
    800026b0:	e45e                	sd	s7,8(sp)
    800026b2:	e062                	sd	s8,0(sp)
    800026b4:	0880                	addi	s0,sp,80
    800026b6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800026b8:	fffff097          	auipc	ra,0xfffff
    800026bc:	75c080e7          	jalr	1884(ra) # 80001e14 <myproc>
    800026c0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800026c2:	0000f517          	auipc	a0,0xf
    800026c6:	13650513          	addi	a0,a0,310 # 800117f8 <wait_lock>
    800026ca:	ffffe097          	auipc	ra,0xffffe
    800026ce:	51a080e7          	jalr	1306(ra) # 80000be4 <acquire>
    havekids = 0;
    800026d2:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800026d4:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800026d6:	00015997          	auipc	s3,0x15
    800026da:	53a98993          	addi	s3,s3,1338 # 80017c10 <tickslock>
        havekids = 1;
    800026de:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800026e0:	0000fc17          	auipc	s8,0xf
    800026e4:	118c0c13          	addi	s8,s8,280 # 800117f8 <wait_lock>
    havekids = 0;
    800026e8:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800026ea:	0000f497          	auipc	s1,0xf
    800026ee:	12648493          	addi	s1,s1,294 # 80011810 <proc>
    800026f2:	a0bd                	j	80002760 <wait+0xc2>
          pid = np->pid;
    800026f4:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800026f8:	000b0e63          	beqz	s6,80002714 <wait+0x76>
    800026fc:	4691                	li	a3,4
    800026fe:	02c48613          	addi	a2,s1,44
    80002702:	85da                	mv	a1,s6
    80002704:	05093503          	ld	a0,80(s2)
    80002708:	fffff097          	auipc	ra,0xfffff
    8000270c:	f6a080e7          	jalr	-150(ra) # 80001672 <copyout>
    80002710:	02054563          	bltz	a0,8000273a <wait+0x9c>
          freeproc(np);
    80002714:	8526                	mv	a0,s1
    80002716:	00000097          	auipc	ra,0x0
    8000271a:	8aa080e7          	jalr	-1878(ra) # 80001fc0 <freeproc>
          release(&np->lock);
    8000271e:	8526                	mv	a0,s1
    80002720:	ffffe097          	auipc	ra,0xffffe
    80002724:	578080e7          	jalr	1400(ra) # 80000c98 <release>
          release(&wait_lock);
    80002728:	0000f517          	auipc	a0,0xf
    8000272c:	0d050513          	addi	a0,a0,208 # 800117f8 <wait_lock>
    80002730:	ffffe097          	auipc	ra,0xffffe
    80002734:	568080e7          	jalr	1384(ra) # 80000c98 <release>
          return pid;
    80002738:	a09d                	j	8000279e <wait+0x100>
            release(&np->lock);
    8000273a:	8526                	mv	a0,s1
    8000273c:	ffffe097          	auipc	ra,0xffffe
    80002740:	55c080e7          	jalr	1372(ra) # 80000c98 <release>
            release(&wait_lock);
    80002744:	0000f517          	auipc	a0,0xf
    80002748:	0b450513          	addi	a0,a0,180 # 800117f8 <wait_lock>
    8000274c:	ffffe097          	auipc	ra,0xffffe
    80002750:	54c080e7          	jalr	1356(ra) # 80000c98 <release>
            return -1;
    80002754:	59fd                	li	s3,-1
    80002756:	a0a1                	j	8000279e <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002758:	19048493          	addi	s1,s1,400
    8000275c:	03348463          	beq	s1,s3,80002784 <wait+0xe6>
      if(np->parent == p){
    80002760:	7c9c                	ld	a5,56(s1)
    80002762:	ff279be3          	bne	a5,s2,80002758 <wait+0xba>
        acquire(&np->lock);
    80002766:	8526                	mv	a0,s1
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	47c080e7          	jalr	1148(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002770:	4c9c                	lw	a5,24(s1)
    80002772:	f94781e3          	beq	a5,s4,800026f4 <wait+0x56>
        release(&np->lock);
    80002776:	8526                	mv	a0,s1
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	520080e7          	jalr	1312(ra) # 80000c98 <release>
        havekids = 1;
    80002780:	8756                	mv	a4,s5
    80002782:	bfd9                	j	80002758 <wait+0xba>
    if(!havekids || p->killed){
    80002784:	c701                	beqz	a4,8000278c <wait+0xee>
    80002786:	02892783          	lw	a5,40(s2)
    8000278a:	c79d                	beqz	a5,800027b8 <wait+0x11a>
      release(&wait_lock);
    8000278c:	0000f517          	auipc	a0,0xf
    80002790:	06c50513          	addi	a0,a0,108 # 800117f8 <wait_lock>
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	504080e7          	jalr	1284(ra) # 80000c98 <release>
      return -1;
    8000279c:	59fd                	li	s3,-1
}
    8000279e:	854e                	mv	a0,s3
    800027a0:	60a6                	ld	ra,72(sp)
    800027a2:	6406                	ld	s0,64(sp)
    800027a4:	74e2                	ld	s1,56(sp)
    800027a6:	7942                	ld	s2,48(sp)
    800027a8:	79a2                	ld	s3,40(sp)
    800027aa:	7a02                	ld	s4,32(sp)
    800027ac:	6ae2                	ld	s5,24(sp)
    800027ae:	6b42                	ld	s6,16(sp)
    800027b0:	6ba2                	ld	s7,8(sp)
    800027b2:	6c02                	ld	s8,0(sp)
    800027b4:	6161                	addi	sp,sp,80
    800027b6:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800027b8:	85e2                	mv	a1,s8
    800027ba:	854a                	mv	a0,s2
    800027bc:	00000097          	auipc	ra,0x0
    800027c0:	e6c080e7          	jalr	-404(ra) # 80002628 <sleep>
    havekids = 0;
    800027c4:	b715                	j	800026e8 <wait+0x4a>

00000000800027c6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800027c6:	7159                	addi	sp,sp,-112
    800027c8:	f486                	sd	ra,104(sp)
    800027ca:	f0a2                	sd	s0,96(sp)
    800027cc:	eca6                	sd	s1,88(sp)
    800027ce:	e8ca                	sd	s2,80(sp)
    800027d0:	e4ce                	sd	s3,72(sp)
    800027d2:	e0d2                	sd	s4,64(sp)
    800027d4:	fc56                	sd	s5,56(sp)
    800027d6:	f85a                	sd	s6,48(sp)
    800027d8:	f45e                	sd	s7,40(sp)
    800027da:	f062                	sd	s8,32(sp)
    800027dc:	ec66                	sd	s9,24(sp)
    800027de:	e86a                	sd	s10,16(sp)
    800027e0:	e46e                	sd	s11,8(sp)
    800027e2:	1880                	addi	s0,sp,112
    800027e4:	8c2a                	mv	s8,a0
  struct proc *p;
  struct cpu *c;
  int curr = get_head(&sleeping_list);
    800027e6:	00006517          	auipc	a0,0x6
    800027ea:	10a50513          	addi	a0,a0,266 # 800088f0 <sleeping_list>
    800027ee:	fffff097          	auipc	ra,0xfffff
    800027f2:	20c080e7          	jalr	524(ra) # 800019fa <get_head>

  while(curr != -1) {
    800027f6:	57fd                	li	a5,-1
    800027f8:	08f50e63          	beq	a0,a5,80002894 <wakeup+0xce>
    800027fc:	892a                	mv	s2,a0
    p = &proc[curr];
    800027fe:	19000a93          	li	s5,400
    80002802:	0000fa17          	auipc	s4,0xf
    80002806:	00ea0a13          	addi	s4,s4,14 # 80011810 <proc>
    curr = p->next_proc;
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000280a:	4b89                	li	s7,2
        remove(&sleeping_list, p);
        p->state = RUNNABLE;
    8000280c:	4d8d                	li	s11,3
    8000280e:	0a800d13          	li	s10,168

        #ifdef ON
          p->last_cpu = min_cpu_process_count(); // case BLNCFLG=ON -> cpu = CPU with the lowest counter value
        #endif
        c = &cpus[p->last_cpu];
    80002812:	0000fc97          	auipc	s9,0xf
    80002816:	a8ec8c93          	addi	s9,s9,-1394 # 800112a0 <cpus>
  while(curr != -1) {
    8000281a:	5b7d                	li	s6,-1
    8000281c:	a801                	j	8000282c <wakeup+0x66>
        increment_cpu_process_count(c);

        append(&(c->runnable_list), p);
      }
      release(&p->lock);
    8000281e:	8526                	mv	a0,s1
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	478080e7          	jalr	1144(ra) # 80000c98 <release>
  while(curr != -1) {
    80002828:	07690663          	beq	s2,s6,80002894 <wakeup+0xce>
    p = &proc[curr];
    8000282c:	035904b3          	mul	s1,s2,s5
    80002830:	94d2                	add	s1,s1,s4
    curr = p->next_proc;
    80002832:	16c4a903          	lw	s2,364(s1)
    if(p != myproc()){
    80002836:	fffff097          	auipc	ra,0xfffff
    8000283a:	5de080e7          	jalr	1502(ra) # 80001e14 <myproc>
    8000283e:	fea485e3          	beq	s1,a0,80002828 <wakeup+0x62>
      acquire(&p->lock);
    80002842:	8526                	mv	a0,s1
    80002844:	ffffe097          	auipc	ra,0xffffe
    80002848:	3a0080e7          	jalr	928(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000284c:	4c9c                	lw	a5,24(s1)
    8000284e:	fd7798e3          	bne	a5,s7,8000281e <wakeup+0x58>
    80002852:	709c                	ld	a5,32(s1)
    80002854:	fd8795e3          	bne	a5,s8,8000281e <wakeup+0x58>
        remove(&sleeping_list, p);
    80002858:	85a6                	mv	a1,s1
    8000285a:	00006517          	auipc	a0,0x6
    8000285e:	09650513          	addi	a0,a0,150 # 800088f0 <sleeping_list>
    80002862:	fffff097          	auipc	ra,0xfffff
    80002866:	2b6080e7          	jalr	694(ra) # 80001b18 <remove>
        p->state = RUNNABLE;
    8000286a:	01b4ac23          	sw	s11,24(s1)
        c = &cpus[p->last_cpu];
    8000286e:	1684a983          	lw	s3,360(s1)
    80002872:	03a989b3          	mul	s3,s3,s10
        increment_cpu_process_count(c);
    80002876:	013c8533          	add	a0,s9,s3
    8000287a:	fffff097          	auipc	ra,0xfffff
    8000287e:	fc4080e7          	jalr	-60(ra) # 8000183e <increment_cpu_process_count>
        append(&(c->runnable_list), p);
    80002882:	08898513          	addi	a0,s3,136
    80002886:	85a6                	mv	a1,s1
    80002888:	9566                	add	a0,a0,s9
    8000288a:	fffff097          	auipc	ra,0xfffff
    8000288e:	1c6080e7          	jalr	454(ra) # 80001a50 <append>
    80002892:	b771                	j	8000281e <wakeup+0x58>
    }
  }
}
    80002894:	70a6                	ld	ra,104(sp)
    80002896:	7406                	ld	s0,96(sp)
    80002898:	64e6                	ld	s1,88(sp)
    8000289a:	6946                	ld	s2,80(sp)
    8000289c:	69a6                	ld	s3,72(sp)
    8000289e:	6a06                	ld	s4,64(sp)
    800028a0:	7ae2                	ld	s5,56(sp)
    800028a2:	7b42                	ld	s6,48(sp)
    800028a4:	7ba2                	ld	s7,40(sp)
    800028a6:	7c02                	ld	s8,32(sp)
    800028a8:	6ce2                	ld	s9,24(sp)
    800028aa:	6d42                	ld	s10,16(sp)
    800028ac:	6da2                	ld	s11,8(sp)
    800028ae:	6165                	addi	sp,sp,112
    800028b0:	8082                	ret

00000000800028b2 <reparent>:
{
    800028b2:	7179                	addi	sp,sp,-48
    800028b4:	f406                	sd	ra,40(sp)
    800028b6:	f022                	sd	s0,32(sp)
    800028b8:	ec26                	sd	s1,24(sp)
    800028ba:	e84a                	sd	s2,16(sp)
    800028bc:	e44e                	sd	s3,8(sp)
    800028be:	e052                	sd	s4,0(sp)
    800028c0:	1800                	addi	s0,sp,48
    800028c2:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800028c4:	0000f497          	auipc	s1,0xf
    800028c8:	f4c48493          	addi	s1,s1,-180 # 80011810 <proc>
      pp->parent = initproc;
    800028cc:	00006a17          	auipc	s4,0x6
    800028d0:	75ca0a13          	addi	s4,s4,1884 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800028d4:	00015997          	auipc	s3,0x15
    800028d8:	33c98993          	addi	s3,s3,828 # 80017c10 <tickslock>
    800028dc:	a029                	j	800028e6 <reparent+0x34>
    800028de:	19048493          	addi	s1,s1,400
    800028e2:	01348d63          	beq	s1,s3,800028fc <reparent+0x4a>
    if(pp->parent == p){
    800028e6:	7c9c                	ld	a5,56(s1)
    800028e8:	ff279be3          	bne	a5,s2,800028de <reparent+0x2c>
      pp->parent = initproc;
    800028ec:	000a3503          	ld	a0,0(s4)
    800028f0:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800028f2:	00000097          	auipc	ra,0x0
    800028f6:	ed4080e7          	jalr	-300(ra) # 800027c6 <wakeup>
    800028fa:	b7d5                	j	800028de <reparent+0x2c>
}
    800028fc:	70a2                	ld	ra,40(sp)
    800028fe:	7402                	ld	s0,32(sp)
    80002900:	64e2                	ld	s1,24(sp)
    80002902:	6942                	ld	s2,16(sp)
    80002904:	69a2                	ld	s3,8(sp)
    80002906:	6a02                	ld	s4,0(sp)
    80002908:	6145                	addi	sp,sp,48
    8000290a:	8082                	ret

000000008000290c <exit>:
{
    8000290c:	7179                	addi	sp,sp,-48
    8000290e:	f406                	sd	ra,40(sp)
    80002910:	f022                	sd	s0,32(sp)
    80002912:	ec26                	sd	s1,24(sp)
    80002914:	e84a                	sd	s2,16(sp)
    80002916:	e44e                	sd	s3,8(sp)
    80002918:	e052                	sd	s4,0(sp)
    8000291a:	1800                	addi	s0,sp,48
    8000291c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000291e:	fffff097          	auipc	ra,0xfffff
    80002922:	4f6080e7          	jalr	1270(ra) # 80001e14 <myproc>
    80002926:	89aa                	mv	s3,a0
  if(p == initproc)
    80002928:	00006797          	auipc	a5,0x6
    8000292c:	7007b783          	ld	a5,1792(a5) # 80009028 <initproc>
    80002930:	0d050493          	addi	s1,a0,208
    80002934:	15050913          	addi	s2,a0,336
    80002938:	02a79363          	bne	a5,a0,8000295e <exit+0x52>
    panic("init exiting");
    8000293c:	00006517          	auipc	a0,0x6
    80002940:	9cc50513          	addi	a0,a0,-1588 # 80008308 <digits+0x2c8>
    80002944:	ffffe097          	auipc	ra,0xffffe
    80002948:	bfa080e7          	jalr	-1030(ra) # 8000053e <panic>
      fileclose(f);
    8000294c:	00002097          	auipc	ra,0x2
    80002950:	262080e7          	jalr	610(ra) # 80004bae <fileclose>
      p->ofile[fd] = 0;
    80002954:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002958:	04a1                	addi	s1,s1,8
    8000295a:	01248563          	beq	s1,s2,80002964 <exit+0x58>
    if(p->ofile[fd]){
    8000295e:	6088                	ld	a0,0(s1)
    80002960:	f575                	bnez	a0,8000294c <exit+0x40>
    80002962:	bfdd                	j	80002958 <exit+0x4c>
  begin_op();
    80002964:	00002097          	auipc	ra,0x2
    80002968:	d7e080e7          	jalr	-642(ra) # 800046e2 <begin_op>
  iput(p->cwd);
    8000296c:	1509b503          	ld	a0,336(s3)
    80002970:	00001097          	auipc	ra,0x1
    80002974:	55a080e7          	jalr	1370(ra) # 80003eca <iput>
  end_op();
    80002978:	00002097          	auipc	ra,0x2
    8000297c:	dea080e7          	jalr	-534(ra) # 80004762 <end_op>
  p->cwd = 0;
    80002980:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002984:	0000f497          	auipc	s1,0xf
    80002988:	e7448493          	addi	s1,s1,-396 # 800117f8 <wait_lock>
    8000298c:	8526                	mv	a0,s1
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	256080e7          	jalr	598(ra) # 80000be4 <acquire>
  reparent(p);
    80002996:	854e                	mv	a0,s3
    80002998:	00000097          	auipc	ra,0x0
    8000299c:	f1a080e7          	jalr	-230(ra) # 800028b2 <reparent>
  wakeup(p->parent);
    800029a0:	0389b503          	ld	a0,56(s3)
    800029a4:	00000097          	auipc	ra,0x0
    800029a8:	e22080e7          	jalr	-478(ra) # 800027c6 <wakeup>
  acquire(&p->lock);
    800029ac:	854e                	mv	a0,s3
    800029ae:	ffffe097          	auipc	ra,0xffffe
    800029b2:	236080e7          	jalr	566(ra) # 80000be4 <acquire>
  p->xstate = status;
    800029b6:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800029ba:	4795                	li	a5,5
    800029bc:	00f9ac23          	sw	a5,24(s3)
  append(&zombie_list, p); // exit to admit the exiting process to the ZOMBIE list
    800029c0:	85ce                	mv	a1,s3
    800029c2:	00006517          	auipc	a0,0x6
    800029c6:	f4e50513          	addi	a0,a0,-178 # 80008910 <zombie_list>
    800029ca:	fffff097          	auipc	ra,0xfffff
    800029ce:	086080e7          	jalr	134(ra) # 80001a50 <append>
  release(&wait_lock);
    800029d2:	8526                	mv	a0,s1
    800029d4:	ffffe097          	auipc	ra,0xffffe
    800029d8:	2c4080e7          	jalr	708(ra) # 80000c98 <release>
  sched();
    800029dc:	00000097          	auipc	ra,0x0
    800029e0:	b0a080e7          	jalr	-1270(ra) # 800024e6 <sched>
  panic("zombie exit");
    800029e4:	00006517          	auipc	a0,0x6
    800029e8:	93450513          	addi	a0,a0,-1740 # 80008318 <digits+0x2d8>
    800029ec:	ffffe097          	auipc	ra,0xffffe
    800029f0:	b52080e7          	jalr	-1198(ra) # 8000053e <panic>

00000000800029f4 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800029f4:	7179                	addi	sp,sp,-48
    800029f6:	f406                	sd	ra,40(sp)
    800029f8:	f022                	sd	s0,32(sp)
    800029fa:	ec26                	sd	s1,24(sp)
    800029fc:	e84a                	sd	s2,16(sp)
    800029fe:	e44e                	sd	s3,8(sp)
    80002a00:	1800                	addi	s0,sp,48
    80002a02:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002a04:	0000f497          	auipc	s1,0xf
    80002a08:	e0c48493          	addi	s1,s1,-500 # 80011810 <proc>
    80002a0c:	00015997          	auipc	s3,0x15
    80002a10:	20498993          	addi	s3,s3,516 # 80017c10 <tickslock>
    acquire(&p->lock);
    80002a14:	8526                	mv	a0,s1
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	1ce080e7          	jalr	462(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002a1e:	589c                	lw	a5,48(s1)
    80002a20:	01278d63          	beq	a5,s2,80002a3a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002a24:	8526                	mv	a0,s1
    80002a26:	ffffe097          	auipc	ra,0xffffe
    80002a2a:	272080e7          	jalr	626(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a2e:	19048493          	addi	s1,s1,400
    80002a32:	ff3491e3          	bne	s1,s3,80002a14 <kill+0x20>
  }
  return -1;
    80002a36:	557d                	li	a0,-1
    80002a38:	a829                	j	80002a52 <kill+0x5e>
      p->killed = 1;
    80002a3a:	4785                	li	a5,1
    80002a3c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002a3e:	4c98                	lw	a4,24(s1)
    80002a40:	4789                	li	a5,2
    80002a42:	00f70f63          	beq	a4,a5,80002a60 <kill+0x6c>
      release(&p->lock);
    80002a46:	8526                	mv	a0,s1
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	250080e7          	jalr	592(ra) # 80000c98 <release>
      return 0;
    80002a50:	4501                	li	a0,0
}
    80002a52:	70a2                	ld	ra,40(sp)
    80002a54:	7402                	ld	s0,32(sp)
    80002a56:	64e2                	ld	s1,24(sp)
    80002a58:	6942                	ld	s2,16(sp)
    80002a5a:	69a2                	ld	s3,8(sp)
    80002a5c:	6145                	addi	sp,sp,48
    80002a5e:	8082                	ret
        p->state = RUNNABLE;
    80002a60:	478d                	li	a5,3
    80002a62:	cc9c                	sw	a5,24(s1)
    80002a64:	b7cd                	j	80002a46 <kill+0x52>

0000000080002a66 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002a66:	7179                	addi	sp,sp,-48
    80002a68:	f406                	sd	ra,40(sp)
    80002a6a:	f022                	sd	s0,32(sp)
    80002a6c:	ec26                	sd	s1,24(sp)
    80002a6e:	e84a                	sd	s2,16(sp)
    80002a70:	e44e                	sd	s3,8(sp)
    80002a72:	e052                	sd	s4,0(sp)
    80002a74:	1800                	addi	s0,sp,48
    80002a76:	84aa                	mv	s1,a0
    80002a78:	892e                	mv	s2,a1
    80002a7a:	89b2                	mv	s3,a2
    80002a7c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a7e:	fffff097          	auipc	ra,0xfffff
    80002a82:	396080e7          	jalr	918(ra) # 80001e14 <myproc>
  if(user_dst){
    80002a86:	c08d                	beqz	s1,80002aa8 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002a88:	86d2                	mv	a3,s4
    80002a8a:	864e                	mv	a2,s3
    80002a8c:	85ca                	mv	a1,s2
    80002a8e:	6928                	ld	a0,80(a0)
    80002a90:	fffff097          	auipc	ra,0xfffff
    80002a94:	be2080e7          	jalr	-1054(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002a98:	70a2                	ld	ra,40(sp)
    80002a9a:	7402                	ld	s0,32(sp)
    80002a9c:	64e2                	ld	s1,24(sp)
    80002a9e:	6942                	ld	s2,16(sp)
    80002aa0:	69a2                	ld	s3,8(sp)
    80002aa2:	6a02                	ld	s4,0(sp)
    80002aa4:	6145                	addi	sp,sp,48
    80002aa6:	8082                	ret
    memmove((char *)dst, src, len);
    80002aa8:	000a061b          	sext.w	a2,s4
    80002aac:	85ce                	mv	a1,s3
    80002aae:	854a                	mv	a0,s2
    80002ab0:	ffffe097          	auipc	ra,0xffffe
    80002ab4:	290080e7          	jalr	656(ra) # 80000d40 <memmove>
    return 0;
    80002ab8:	8526                	mv	a0,s1
    80002aba:	bff9                	j	80002a98 <either_copyout+0x32>

0000000080002abc <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002abc:	7179                	addi	sp,sp,-48
    80002abe:	f406                	sd	ra,40(sp)
    80002ac0:	f022                	sd	s0,32(sp)
    80002ac2:	ec26                	sd	s1,24(sp)
    80002ac4:	e84a                	sd	s2,16(sp)
    80002ac6:	e44e                	sd	s3,8(sp)
    80002ac8:	e052                	sd	s4,0(sp)
    80002aca:	1800                	addi	s0,sp,48
    80002acc:	892a                	mv	s2,a0
    80002ace:	84ae                	mv	s1,a1
    80002ad0:	89b2                	mv	s3,a2
    80002ad2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002ad4:	fffff097          	auipc	ra,0xfffff
    80002ad8:	340080e7          	jalr	832(ra) # 80001e14 <myproc>
  if(user_src){
    80002adc:	c08d                	beqz	s1,80002afe <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002ade:	86d2                	mv	a3,s4
    80002ae0:	864e                	mv	a2,s3
    80002ae2:	85ca                	mv	a1,s2
    80002ae4:	6928                	ld	a0,80(a0)
    80002ae6:	fffff097          	auipc	ra,0xfffff
    80002aea:	c18080e7          	jalr	-1000(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002aee:	70a2                	ld	ra,40(sp)
    80002af0:	7402                	ld	s0,32(sp)
    80002af2:	64e2                	ld	s1,24(sp)
    80002af4:	6942                	ld	s2,16(sp)
    80002af6:	69a2                	ld	s3,8(sp)
    80002af8:	6a02                	ld	s4,0(sp)
    80002afa:	6145                	addi	sp,sp,48
    80002afc:	8082                	ret
    memmove(dst, (char*)src, len);
    80002afe:	000a061b          	sext.w	a2,s4
    80002b02:	85ce                	mv	a1,s3
    80002b04:	854a                	mv	a0,s2
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	23a080e7          	jalr	570(ra) # 80000d40 <memmove>
    return 0;
    80002b0e:	8526                	mv	a0,s1
    80002b10:	bff9                	j	80002aee <either_copyin+0x32>

0000000080002b12 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    80002b12:	715d                	addi	sp,sp,-80
    80002b14:	e486                	sd	ra,72(sp)
    80002b16:	e0a2                	sd	s0,64(sp)
    80002b18:	fc26                	sd	s1,56(sp)
    80002b1a:	f84a                	sd	s2,48(sp)
    80002b1c:	f44e                	sd	s3,40(sp)
    80002b1e:	f052                	sd	s4,32(sp)
    80002b20:	ec56                	sd	s5,24(sp)
    80002b22:	e85a                	sd	s6,16(sp)
    80002b24:	e45e                	sd	s7,8(sp)
    80002b26:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002b28:	00005517          	auipc	a0,0x5
    80002b2c:	5a050513          	addi	a0,a0,1440 # 800080c8 <digits+0x88>
    80002b30:	ffffe097          	auipc	ra,0xffffe
    80002b34:	a58080e7          	jalr	-1448(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b38:	0000f497          	auipc	s1,0xf
    80002b3c:	e3048493          	addi	s1,s1,-464 # 80011968 <proc+0x158>
    80002b40:	00015917          	auipc	s2,0x15
    80002b44:	22890913          	addi	s2,s2,552 # 80017d68 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b48:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    80002b4a:	00005997          	auipc	s3,0x5
    80002b4e:	7de98993          	addi	s3,s3,2014 # 80008328 <digits+0x2e8>
    printf("%d %s %s", p->pid, state, p->name);
    80002b52:	00005a97          	auipc	s5,0x5
    80002b56:	7dea8a93          	addi	s5,s5,2014 # 80008330 <digits+0x2f0>
    printf("\n");
    80002b5a:	00005a17          	auipc	s4,0x5
    80002b5e:	56ea0a13          	addi	s4,s4,1390 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b62:	00006b97          	auipc	s7,0x6
    80002b66:	806b8b93          	addi	s7,s7,-2042 # 80008368 <states.1793>
    80002b6a:	a00d                	j	80002b8c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002b6c:	ed86a583          	lw	a1,-296(a3)
    80002b70:	8556                	mv	a0,s5
    80002b72:	ffffe097          	auipc	ra,0xffffe
    80002b76:	a16080e7          	jalr	-1514(ra) # 80000588 <printf>
    printf("\n");
    80002b7a:	8552                	mv	a0,s4
    80002b7c:	ffffe097          	auipc	ra,0xffffe
    80002b80:	a0c080e7          	jalr	-1524(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b84:	19048493          	addi	s1,s1,400
    80002b88:	03248163          	beq	s1,s2,80002baa <procdump+0x98>
    if(p->state == UNUSED)
    80002b8c:	86a6                	mv	a3,s1
    80002b8e:	ec04a783          	lw	a5,-320(s1)
    80002b92:	dbed                	beqz	a5,80002b84 <procdump+0x72>
      state = "???"; 
    80002b94:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b96:	fcfb6be3          	bltu	s6,a5,80002b6c <procdump+0x5a>
    80002b9a:	1782                	slli	a5,a5,0x20
    80002b9c:	9381                	srli	a5,a5,0x20
    80002b9e:	078e                	slli	a5,a5,0x3
    80002ba0:	97de                	add	a5,a5,s7
    80002ba2:	6390                	ld	a2,0(a5)
    80002ba4:	f661                	bnez	a2,80002b6c <procdump+0x5a>
      state = "???"; 
    80002ba6:	864e                	mv	a2,s3
    80002ba8:	b7d1                	j	80002b6c <procdump+0x5a>
  }
}
    80002baa:	60a6                	ld	ra,72(sp)
    80002bac:	6406                	ld	s0,64(sp)
    80002bae:	74e2                	ld	s1,56(sp)
    80002bb0:	7942                	ld	s2,48(sp)
    80002bb2:	79a2                	ld	s3,40(sp)
    80002bb4:	7a02                	ld	s4,32(sp)
    80002bb6:	6ae2                	ld	s5,24(sp)
    80002bb8:	6b42                	ld	s6,16(sp)
    80002bba:	6ba2                	ld	s7,8(sp)
    80002bbc:	6161                	addi	sp,sp,80
    80002bbe:	8082                	ret

0000000080002bc0 <set_cpu>:

// assign current process to a different CPU. 
int
set_cpu(int cpu_num){
    80002bc0:	1101                	addi	sp,sp,-32
    80002bc2:	ec06                	sd	ra,24(sp)
    80002bc4:	e822                	sd	s0,16(sp)
    80002bc6:	e426                	sd	s1,8(sp)
    80002bc8:	e04a                	sd	s2,0(sp)
    80002bca:	1000                	addi	s0,sp,32
    80002bcc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bce:	fffff097          	auipc	ra,0xfffff
    80002bd2:	246080e7          	jalr	582(ra) # 80001e14 <myproc>
  if(cpu_num >= 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL){
    80002bd6:	0004871b          	sext.w	a4,s1
    80002bda:	479d                	li	a5,7
    80002bdc:	02e7e963          	bltu	a5,a4,80002c0e <set_cpu+0x4e>
    80002be0:	892a                	mv	s2,a0
    acquire(&p->lock);
    80002be2:	ffffe097          	auipc	ra,0xffffe
    80002be6:	002080e7          	jalr	2(ra) # 80000be4 <acquire>
    p->last_cpu = cpu_num;
    80002bea:	16992423          	sw	s1,360(s2)
    release(&p->lock);
    80002bee:	854a                	mv	a0,s2
    80002bf0:	ffffe097          	auipc	ra,0xffffe
    80002bf4:	0a8080e7          	jalr	168(ra) # 80000c98 <release>

    yield();
    80002bf8:	00000097          	auipc	ra,0x0
    80002bfc:	9d0080e7          	jalr	-1584(ra) # 800025c8 <yield>

    return cpu_num;
    80002c00:	8526                	mv	a0,s1
  }
  return -1;
}
    80002c02:	60e2                	ld	ra,24(sp)
    80002c04:	6442                	ld	s0,16(sp)
    80002c06:	64a2                	ld	s1,8(sp)
    80002c08:	6902                	ld	s2,0(sp)
    80002c0a:	6105                	addi	sp,sp,32
    80002c0c:	8082                	ret
  return -1;
    80002c0e:	557d                	li	a0,-1
    80002c10:	bfcd                	j	80002c02 <set_cpu+0x42>

0000000080002c12 <get_cpu>:

// return the current CPU id.
int
get_cpu(void){
    80002c12:	1141                	addi	sp,sp,-16
    80002c14:	e406                	sd	ra,8(sp)
    80002c16:	e022                	sd	s0,0(sp)
    80002c18:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c1a:	fffff097          	auipc	ra,0xfffff
    80002c1e:	1fa080e7          	jalr	506(ra) # 80001e14 <myproc>
  return p->last_cpu;
}
    80002c22:	16852503          	lw	a0,360(a0)
    80002c26:	60a2                	ld	ra,8(sp)
    80002c28:	6402                	ld	s0,0(sp)
    80002c2a:	0141                	addi	sp,sp,16
    80002c2c:	8082                	ret

0000000080002c2e <min_cpu>:

int
min_cpu(void){
    80002c2e:	1141                	addi	sp,sp,-16
    80002c30:	e422                	sd	s0,8(sp)
    80002c32:	0800                	addi	s0,sp,16
  struct cpu *c, *min_cpu;
// should add an if to insure numberOfCpus>0
  min_cpu = cpus;
    80002c34:	0000e617          	auipc	a2,0xe
    80002c38:	66c60613          	addi	a2,a2,1644 # 800112a0 <cpus>
  for(c = cpus + 1; c < &cpus[NCPU] && c != NULL ; c++){
    80002c3c:	0000e797          	auipc	a5,0xe
    80002c40:	70c78793          	addi	a5,a5,1804 # 80011348 <cpus+0xa8>
    80002c44:	0000f597          	auipc	a1,0xf
    80002c48:	b9c58593          	addi	a1,a1,-1124 # 800117e0 <pid_lock>
    80002c4c:	a029                	j	80002c56 <min_cpu+0x28>
    80002c4e:	0a878793          	addi	a5,a5,168
    80002c52:	00b78a63          	beq	a5,a1,80002c66 <min_cpu+0x38>
    if (c->proc_cnt < min_cpu->proc_cnt)
    80002c56:	0807a683          	lw	a3,128(a5)
    80002c5a:	08062703          	lw	a4,128(a2)
    80002c5e:	fee6d8e3          	bge	a3,a4,80002c4e <min_cpu+0x20>
    80002c62:	863e                	mv	a2,a5
    80002c64:	b7ed                	j	80002c4e <min_cpu+0x20>
        min_cpu = c;
  }
  return min_cpu->cpu_id;   
}
    80002c66:	08462503          	lw	a0,132(a2)
    80002c6a:	6422                	ld	s0,8(sp)
    80002c6c:	0141                	addi	sp,sp,16
    80002c6e:	8082                	ret

0000000080002c70 <cpu_process_count>:

int
cpu_process_count(int cpu_num){
    80002c70:	1141                	addi	sp,sp,-16
    80002c72:	e422                	sd	s0,8(sp)
    80002c74:	0800                	addi	s0,sp,16
  if (cpu_num > 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL) 
    80002c76:	fff5071b          	addiw	a4,a0,-1
    80002c7a:	4799                	li	a5,6
    80002c7c:	02e7e063          	bltu	a5,a4,80002c9c <cpu_process_count+0x2c>
    return cpus[cpu_num].proc_cnt;
    80002c80:	0a800793          	li	a5,168
    80002c84:	02f50533          	mul	a0,a0,a5
    80002c88:	0000e797          	auipc	a5,0xe
    80002c8c:	61878793          	addi	a5,a5,1560 # 800112a0 <cpus>
    80002c90:	953e                	add	a0,a0,a5
    80002c92:	08052503          	lw	a0,128(a0)
  return -1;
}
    80002c96:	6422                	ld	s0,8(sp)
    80002c98:	0141                	addi	sp,sp,16
    80002c9a:	8082                	ret
  return -1;
    80002c9c:	557d                	li	a0,-1
    80002c9e:	bfe5                	j	80002c96 <cpu_process_count+0x26>

0000000080002ca0 <steal_process>:




void
steal_process(struct cpu *curr_c){  /*
    80002ca0:	1141                	addi	sp,sp,-16
    80002ca2:	e422                	sd	s0,8(sp)
    80002ca4:	0800                	addi	s0,sp,16
  }
  p = proc[stolen_process];
  append(&c->runnable_list, p);
  p->last_cpu = c->cpu_id;
  increment_cpu_process_count(c); */
    80002ca6:	6422                	ld	s0,8(sp)
    80002ca8:	0141                	addi	sp,sp,16
    80002caa:	8082                	ret

0000000080002cac <swtch>:
    80002cac:	00153023          	sd	ra,0(a0)
    80002cb0:	00253423          	sd	sp,8(a0)
    80002cb4:	e900                	sd	s0,16(a0)
    80002cb6:	ed04                	sd	s1,24(a0)
    80002cb8:	03253023          	sd	s2,32(a0)
    80002cbc:	03353423          	sd	s3,40(a0)
    80002cc0:	03453823          	sd	s4,48(a0)
    80002cc4:	03553c23          	sd	s5,56(a0)
    80002cc8:	05653023          	sd	s6,64(a0)
    80002ccc:	05753423          	sd	s7,72(a0)
    80002cd0:	05853823          	sd	s8,80(a0)
    80002cd4:	05953c23          	sd	s9,88(a0)
    80002cd8:	07a53023          	sd	s10,96(a0)
    80002cdc:	07b53423          	sd	s11,104(a0)
    80002ce0:	0005b083          	ld	ra,0(a1)
    80002ce4:	0085b103          	ld	sp,8(a1)
    80002ce8:	6980                	ld	s0,16(a1)
    80002cea:	6d84                	ld	s1,24(a1)
    80002cec:	0205b903          	ld	s2,32(a1)
    80002cf0:	0285b983          	ld	s3,40(a1)
    80002cf4:	0305ba03          	ld	s4,48(a1)
    80002cf8:	0385ba83          	ld	s5,56(a1)
    80002cfc:	0405bb03          	ld	s6,64(a1)
    80002d00:	0485bb83          	ld	s7,72(a1)
    80002d04:	0505bc03          	ld	s8,80(a1)
    80002d08:	0585bc83          	ld	s9,88(a1)
    80002d0c:	0605bd03          	ld	s10,96(a1)
    80002d10:	0685bd83          	ld	s11,104(a1)
    80002d14:	8082                	ret

0000000080002d16 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002d16:	1141                	addi	sp,sp,-16
    80002d18:	e406                	sd	ra,8(sp)
    80002d1a:	e022                	sd	s0,0(sp)
    80002d1c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002d1e:	00005597          	auipc	a1,0x5
    80002d22:	67a58593          	addi	a1,a1,1658 # 80008398 <states.1793+0x30>
    80002d26:	00015517          	auipc	a0,0x15
    80002d2a:	eea50513          	addi	a0,a0,-278 # 80017c10 <tickslock>
    80002d2e:	ffffe097          	auipc	ra,0xffffe
    80002d32:	e26080e7          	jalr	-474(ra) # 80000b54 <initlock>
}
    80002d36:	60a2                	ld	ra,8(sp)
    80002d38:	6402                	ld	s0,0(sp)
    80002d3a:	0141                	addi	sp,sp,16
    80002d3c:	8082                	ret

0000000080002d3e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002d3e:	1141                	addi	sp,sp,-16
    80002d40:	e422                	sd	s0,8(sp)
    80002d42:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d44:	00003797          	auipc	a5,0x3
    80002d48:	48c78793          	addi	a5,a5,1164 # 800061d0 <kernelvec>
    80002d4c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002d50:	6422                	ld	s0,8(sp)
    80002d52:	0141                	addi	sp,sp,16
    80002d54:	8082                	ret

0000000080002d56 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002d56:	1141                	addi	sp,sp,-16
    80002d58:	e406                	sd	ra,8(sp)
    80002d5a:	e022                	sd	s0,0(sp)
    80002d5c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	0b6080e7          	jalr	182(ra) # 80001e14 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d66:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002d6a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d6c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002d70:	00004617          	auipc	a2,0x4
    80002d74:	29060613          	addi	a2,a2,656 # 80007000 <_trampoline>
    80002d78:	00004697          	auipc	a3,0x4
    80002d7c:	28868693          	addi	a3,a3,648 # 80007000 <_trampoline>
    80002d80:	8e91                	sub	a3,a3,a2
    80002d82:	040007b7          	lui	a5,0x4000
    80002d86:	17fd                	addi	a5,a5,-1
    80002d88:	07b2                	slli	a5,a5,0xc
    80002d8a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d8c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d90:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d92:	180026f3          	csrr	a3,satp
    80002d96:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d98:	6d38                	ld	a4,88(a0)
    80002d9a:	6134                	ld	a3,64(a0)
    80002d9c:	6585                	lui	a1,0x1
    80002d9e:	96ae                	add	a3,a3,a1
    80002da0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002da2:	6d38                	ld	a4,88(a0)
    80002da4:	00000697          	auipc	a3,0x0
    80002da8:	13868693          	addi	a3,a3,312 # 80002edc <usertrap>
    80002dac:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002dae:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002db0:	8692                	mv	a3,tp
    80002db2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002db4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002db8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002dbc:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dc0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002dc4:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002dc6:	6f18                	ld	a4,24(a4)
    80002dc8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002dcc:	692c                	ld	a1,80(a0)
    80002dce:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002dd0:	00004717          	auipc	a4,0x4
    80002dd4:	2c070713          	addi	a4,a4,704 # 80007090 <userret>
    80002dd8:	8f11                	sub	a4,a4,a2
    80002dda:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002ddc:	577d                	li	a4,-1
    80002dde:	177e                	slli	a4,a4,0x3f
    80002de0:	8dd9                	or	a1,a1,a4
    80002de2:	02000537          	lui	a0,0x2000
    80002de6:	157d                	addi	a0,a0,-1
    80002de8:	0536                	slli	a0,a0,0xd
    80002dea:	9782                	jalr	a5
}
    80002dec:	60a2                	ld	ra,8(sp)
    80002dee:	6402                	ld	s0,0(sp)
    80002df0:	0141                	addi	sp,sp,16
    80002df2:	8082                	ret

0000000080002df4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002df4:	1101                	addi	sp,sp,-32
    80002df6:	ec06                	sd	ra,24(sp)
    80002df8:	e822                	sd	s0,16(sp)
    80002dfa:	e426                	sd	s1,8(sp)
    80002dfc:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002dfe:	00015497          	auipc	s1,0x15
    80002e02:	e1248493          	addi	s1,s1,-494 # 80017c10 <tickslock>
    80002e06:	8526                	mv	a0,s1
    80002e08:	ffffe097          	auipc	ra,0xffffe
    80002e0c:	ddc080e7          	jalr	-548(ra) # 80000be4 <acquire>
  ticks++;
    80002e10:	00006517          	auipc	a0,0x6
    80002e14:	22050513          	addi	a0,a0,544 # 80009030 <ticks>
    80002e18:	411c                	lw	a5,0(a0)
    80002e1a:	2785                	addiw	a5,a5,1
    80002e1c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002e1e:	00000097          	auipc	ra,0x0
    80002e22:	9a8080e7          	jalr	-1624(ra) # 800027c6 <wakeup>
  release(&tickslock);
    80002e26:	8526                	mv	a0,s1
    80002e28:	ffffe097          	auipc	ra,0xffffe
    80002e2c:	e70080e7          	jalr	-400(ra) # 80000c98 <release>
}
    80002e30:	60e2                	ld	ra,24(sp)
    80002e32:	6442                	ld	s0,16(sp)
    80002e34:	64a2                	ld	s1,8(sp)
    80002e36:	6105                	addi	sp,sp,32
    80002e38:	8082                	ret

0000000080002e3a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002e3a:	1101                	addi	sp,sp,-32
    80002e3c:	ec06                	sd	ra,24(sp)
    80002e3e:	e822                	sd	s0,16(sp)
    80002e40:	e426                	sd	s1,8(sp)
    80002e42:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e44:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002e48:	00074d63          	bltz	a4,80002e62 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002e4c:	57fd                	li	a5,-1
    80002e4e:	17fe                	slli	a5,a5,0x3f
    80002e50:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002e52:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002e54:	06f70363          	beq	a4,a5,80002eba <devintr+0x80>
  }
}
    80002e58:	60e2                	ld	ra,24(sp)
    80002e5a:	6442                	ld	s0,16(sp)
    80002e5c:	64a2                	ld	s1,8(sp)
    80002e5e:	6105                	addi	sp,sp,32
    80002e60:	8082                	ret
     (scause & 0xff) == 9){
    80002e62:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002e66:	46a5                	li	a3,9
    80002e68:	fed792e3          	bne	a5,a3,80002e4c <devintr+0x12>
    int irq = plic_claim();
    80002e6c:	00003097          	auipc	ra,0x3
    80002e70:	46c080e7          	jalr	1132(ra) # 800062d8 <plic_claim>
    80002e74:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002e76:	47a9                	li	a5,10
    80002e78:	02f50763          	beq	a0,a5,80002ea6 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002e7c:	4785                	li	a5,1
    80002e7e:	02f50963          	beq	a0,a5,80002eb0 <devintr+0x76>
    return 1;
    80002e82:	4505                	li	a0,1
    } else if(irq){
    80002e84:	d8f1                	beqz	s1,80002e58 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e86:	85a6                	mv	a1,s1
    80002e88:	00005517          	auipc	a0,0x5
    80002e8c:	51850513          	addi	a0,a0,1304 # 800083a0 <states.1793+0x38>
    80002e90:	ffffd097          	auipc	ra,0xffffd
    80002e94:	6f8080e7          	jalr	1784(ra) # 80000588 <printf>
      plic_complete(irq);
    80002e98:	8526                	mv	a0,s1
    80002e9a:	00003097          	auipc	ra,0x3
    80002e9e:	462080e7          	jalr	1122(ra) # 800062fc <plic_complete>
    return 1;
    80002ea2:	4505                	li	a0,1
    80002ea4:	bf55                	j	80002e58 <devintr+0x1e>
      uartintr();
    80002ea6:	ffffe097          	auipc	ra,0xffffe
    80002eaa:	b02080e7          	jalr	-1278(ra) # 800009a8 <uartintr>
    80002eae:	b7ed                	j	80002e98 <devintr+0x5e>
      virtio_disk_intr();
    80002eb0:	00004097          	auipc	ra,0x4
    80002eb4:	92c080e7          	jalr	-1748(ra) # 800067dc <virtio_disk_intr>
    80002eb8:	b7c5                	j	80002e98 <devintr+0x5e>
    if(cpuid() == 0){
    80002eba:	fffff097          	auipc	ra,0xfffff
    80002ebe:	f28080e7          	jalr	-216(ra) # 80001de2 <cpuid>
    80002ec2:	c901                	beqz	a0,80002ed2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ec4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ec8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002eca:	14479073          	csrw	sip,a5
    return 2;
    80002ece:	4509                	li	a0,2
    80002ed0:	b761                	j	80002e58 <devintr+0x1e>
      clockintr();
    80002ed2:	00000097          	auipc	ra,0x0
    80002ed6:	f22080e7          	jalr	-222(ra) # 80002df4 <clockintr>
    80002eda:	b7ed                	j	80002ec4 <devintr+0x8a>

0000000080002edc <usertrap>:
{
    80002edc:	1101                	addi	sp,sp,-32
    80002ede:	ec06                	sd	ra,24(sp)
    80002ee0:	e822                	sd	s0,16(sp)
    80002ee2:	e426                	sd	s1,8(sp)
    80002ee4:	e04a                	sd	s2,0(sp)
    80002ee6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ee8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002eec:	1007f793          	andi	a5,a5,256
    80002ef0:	e3ad                	bnez	a5,80002f52 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ef2:	00003797          	auipc	a5,0x3
    80002ef6:	2de78793          	addi	a5,a5,734 # 800061d0 <kernelvec>
    80002efa:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002efe:	fffff097          	auipc	ra,0xfffff
    80002f02:	f16080e7          	jalr	-234(ra) # 80001e14 <myproc>
    80002f06:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002f08:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f0a:	14102773          	csrr	a4,sepc
    80002f0e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f10:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002f14:	47a1                	li	a5,8
    80002f16:	04f71c63          	bne	a4,a5,80002f6e <usertrap+0x92>
    if(p->killed)
    80002f1a:	551c                	lw	a5,40(a0)
    80002f1c:	e3b9                	bnez	a5,80002f62 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002f1e:	6cb8                	ld	a4,88(s1)
    80002f20:	6f1c                	ld	a5,24(a4)
    80002f22:	0791                	addi	a5,a5,4
    80002f24:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f26:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002f2a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f2e:	10079073          	csrw	sstatus,a5
    syscall();
    80002f32:	00000097          	auipc	ra,0x0
    80002f36:	2e0080e7          	jalr	736(ra) # 80003212 <syscall>
  if(p->killed)
    80002f3a:	549c                	lw	a5,40(s1)
    80002f3c:	ebc1                	bnez	a5,80002fcc <usertrap+0xf0>
  usertrapret();
    80002f3e:	00000097          	auipc	ra,0x0
    80002f42:	e18080e7          	jalr	-488(ra) # 80002d56 <usertrapret>
}
    80002f46:	60e2                	ld	ra,24(sp)
    80002f48:	6442                	ld	s0,16(sp)
    80002f4a:	64a2                	ld	s1,8(sp)
    80002f4c:	6902                	ld	s2,0(sp)
    80002f4e:	6105                	addi	sp,sp,32
    80002f50:	8082                	ret
    panic("usertrap: not from user mode");
    80002f52:	00005517          	auipc	a0,0x5
    80002f56:	46e50513          	addi	a0,a0,1134 # 800083c0 <states.1793+0x58>
    80002f5a:	ffffd097          	auipc	ra,0xffffd
    80002f5e:	5e4080e7          	jalr	1508(ra) # 8000053e <panic>
      exit(-1);
    80002f62:	557d                	li	a0,-1
    80002f64:	00000097          	auipc	ra,0x0
    80002f68:	9a8080e7          	jalr	-1624(ra) # 8000290c <exit>
    80002f6c:	bf4d                	j	80002f1e <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002f6e:	00000097          	auipc	ra,0x0
    80002f72:	ecc080e7          	jalr	-308(ra) # 80002e3a <devintr>
    80002f76:	892a                	mv	s2,a0
    80002f78:	c501                	beqz	a0,80002f80 <usertrap+0xa4>
  if(p->killed)
    80002f7a:	549c                	lw	a5,40(s1)
    80002f7c:	c3a1                	beqz	a5,80002fbc <usertrap+0xe0>
    80002f7e:	a815                	j	80002fb2 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f80:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f84:	5890                	lw	a2,48(s1)
    80002f86:	00005517          	auipc	a0,0x5
    80002f8a:	45a50513          	addi	a0,a0,1114 # 800083e0 <states.1793+0x78>
    80002f8e:	ffffd097          	auipc	ra,0xffffd
    80002f92:	5fa080e7          	jalr	1530(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f96:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f9a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f9e:	00005517          	auipc	a0,0x5
    80002fa2:	47250513          	addi	a0,a0,1138 # 80008410 <states.1793+0xa8>
    80002fa6:	ffffd097          	auipc	ra,0xffffd
    80002faa:	5e2080e7          	jalr	1506(ra) # 80000588 <printf>
    p->killed = 1;
    80002fae:	4785                	li	a5,1
    80002fb0:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002fb2:	557d                	li	a0,-1
    80002fb4:	00000097          	auipc	ra,0x0
    80002fb8:	958080e7          	jalr	-1704(ra) # 8000290c <exit>
  if(which_dev == 2)
    80002fbc:	4789                	li	a5,2
    80002fbe:	f8f910e3          	bne	s2,a5,80002f3e <usertrap+0x62>
    yield();
    80002fc2:	fffff097          	auipc	ra,0xfffff
    80002fc6:	606080e7          	jalr	1542(ra) # 800025c8 <yield>
    80002fca:	bf95                	j	80002f3e <usertrap+0x62>
  int which_dev = 0;
    80002fcc:	4901                	li	s2,0
    80002fce:	b7d5                	j	80002fb2 <usertrap+0xd6>

0000000080002fd0 <kerneltrap>:
{
    80002fd0:	7179                	addi	sp,sp,-48
    80002fd2:	f406                	sd	ra,40(sp)
    80002fd4:	f022                	sd	s0,32(sp)
    80002fd6:	ec26                	sd	s1,24(sp)
    80002fd8:	e84a                	sd	s2,16(sp)
    80002fda:	e44e                	sd	s3,8(sp)
    80002fdc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fde:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fe2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fe6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002fea:	1004f793          	andi	a5,s1,256
    80002fee:	cb85                	beqz	a5,8000301e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ff0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ff4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ff6:	ef85                	bnez	a5,8000302e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ff8:	00000097          	auipc	ra,0x0
    80002ffc:	e42080e7          	jalr	-446(ra) # 80002e3a <devintr>
    80003000:	cd1d                	beqz	a0,8000303e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003002:	4789                	li	a5,2
    80003004:	06f50a63          	beq	a0,a5,80003078 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003008:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000300c:	10049073          	csrw	sstatus,s1
}
    80003010:	70a2                	ld	ra,40(sp)
    80003012:	7402                	ld	s0,32(sp)
    80003014:	64e2                	ld	s1,24(sp)
    80003016:	6942                	ld	s2,16(sp)
    80003018:	69a2                	ld	s3,8(sp)
    8000301a:	6145                	addi	sp,sp,48
    8000301c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000301e:	00005517          	auipc	a0,0x5
    80003022:	41250513          	addi	a0,a0,1042 # 80008430 <states.1793+0xc8>
    80003026:	ffffd097          	auipc	ra,0xffffd
    8000302a:	518080e7          	jalr	1304(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    8000302e:	00005517          	auipc	a0,0x5
    80003032:	42a50513          	addi	a0,a0,1066 # 80008458 <states.1793+0xf0>
    80003036:	ffffd097          	auipc	ra,0xffffd
    8000303a:	508080e7          	jalr	1288(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    8000303e:	85ce                	mv	a1,s3
    80003040:	00005517          	auipc	a0,0x5
    80003044:	43850513          	addi	a0,a0,1080 # 80008478 <states.1793+0x110>
    80003048:	ffffd097          	auipc	ra,0xffffd
    8000304c:	540080e7          	jalr	1344(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003050:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003054:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003058:	00005517          	auipc	a0,0x5
    8000305c:	43050513          	addi	a0,a0,1072 # 80008488 <states.1793+0x120>
    80003060:	ffffd097          	auipc	ra,0xffffd
    80003064:	528080e7          	jalr	1320(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003068:	00005517          	auipc	a0,0x5
    8000306c:	43850513          	addi	a0,a0,1080 # 800084a0 <states.1793+0x138>
    80003070:	ffffd097          	auipc	ra,0xffffd
    80003074:	4ce080e7          	jalr	1230(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003078:	fffff097          	auipc	ra,0xfffff
    8000307c:	d9c080e7          	jalr	-612(ra) # 80001e14 <myproc>
    80003080:	d541                	beqz	a0,80003008 <kerneltrap+0x38>
    80003082:	fffff097          	auipc	ra,0xfffff
    80003086:	d92080e7          	jalr	-622(ra) # 80001e14 <myproc>
    8000308a:	4d18                	lw	a4,24(a0)
    8000308c:	4791                	li	a5,4
    8000308e:	f6f71de3          	bne	a4,a5,80003008 <kerneltrap+0x38>
    yield();
    80003092:	fffff097          	auipc	ra,0xfffff
    80003096:	536080e7          	jalr	1334(ra) # 800025c8 <yield>
    8000309a:	b7bd                	j	80003008 <kerneltrap+0x38>

000000008000309c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000309c:	1101                	addi	sp,sp,-32
    8000309e:	ec06                	sd	ra,24(sp)
    800030a0:	e822                	sd	s0,16(sp)
    800030a2:	e426                	sd	s1,8(sp)
    800030a4:	1000                	addi	s0,sp,32
    800030a6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800030a8:	fffff097          	auipc	ra,0xfffff
    800030ac:	d6c080e7          	jalr	-660(ra) # 80001e14 <myproc>
  switch (n) {
    800030b0:	4795                	li	a5,5
    800030b2:	0497e163          	bltu	a5,s1,800030f4 <argraw+0x58>
    800030b6:	048a                	slli	s1,s1,0x2
    800030b8:	00005717          	auipc	a4,0x5
    800030bc:	42070713          	addi	a4,a4,1056 # 800084d8 <states.1793+0x170>
    800030c0:	94ba                	add	s1,s1,a4
    800030c2:	409c                	lw	a5,0(s1)
    800030c4:	97ba                	add	a5,a5,a4
    800030c6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800030c8:	6d3c                	ld	a5,88(a0)
    800030ca:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800030cc:	60e2                	ld	ra,24(sp)
    800030ce:	6442                	ld	s0,16(sp)
    800030d0:	64a2                	ld	s1,8(sp)
    800030d2:	6105                	addi	sp,sp,32
    800030d4:	8082                	ret
    return p->trapframe->a1;
    800030d6:	6d3c                	ld	a5,88(a0)
    800030d8:	7fa8                	ld	a0,120(a5)
    800030da:	bfcd                	j	800030cc <argraw+0x30>
    return p->trapframe->a2;
    800030dc:	6d3c                	ld	a5,88(a0)
    800030de:	63c8                	ld	a0,128(a5)
    800030e0:	b7f5                	j	800030cc <argraw+0x30>
    return p->trapframe->a3;
    800030e2:	6d3c                	ld	a5,88(a0)
    800030e4:	67c8                	ld	a0,136(a5)
    800030e6:	b7dd                	j	800030cc <argraw+0x30>
    return p->trapframe->a4;
    800030e8:	6d3c                	ld	a5,88(a0)
    800030ea:	6bc8                	ld	a0,144(a5)
    800030ec:	b7c5                	j	800030cc <argraw+0x30>
    return p->trapframe->a5;
    800030ee:	6d3c                	ld	a5,88(a0)
    800030f0:	6fc8                	ld	a0,152(a5)
    800030f2:	bfe9                	j	800030cc <argraw+0x30>
  panic("argraw");
    800030f4:	00005517          	auipc	a0,0x5
    800030f8:	3bc50513          	addi	a0,a0,956 # 800084b0 <states.1793+0x148>
    800030fc:	ffffd097          	auipc	ra,0xffffd
    80003100:	442080e7          	jalr	1090(ra) # 8000053e <panic>

0000000080003104 <fetchaddr>:
{
    80003104:	1101                	addi	sp,sp,-32
    80003106:	ec06                	sd	ra,24(sp)
    80003108:	e822                	sd	s0,16(sp)
    8000310a:	e426                	sd	s1,8(sp)
    8000310c:	e04a                	sd	s2,0(sp)
    8000310e:	1000                	addi	s0,sp,32
    80003110:	84aa                	mv	s1,a0
    80003112:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003114:	fffff097          	auipc	ra,0xfffff
    80003118:	d00080e7          	jalr	-768(ra) # 80001e14 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    8000311c:	653c                	ld	a5,72(a0)
    8000311e:	02f4f863          	bgeu	s1,a5,8000314e <fetchaddr+0x4a>
    80003122:	00848713          	addi	a4,s1,8
    80003126:	02e7e663          	bltu	a5,a4,80003152 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000312a:	46a1                	li	a3,8
    8000312c:	8626                	mv	a2,s1
    8000312e:	85ca                	mv	a1,s2
    80003130:	6928                	ld	a0,80(a0)
    80003132:	ffffe097          	auipc	ra,0xffffe
    80003136:	5cc080e7          	jalr	1484(ra) # 800016fe <copyin>
    8000313a:	00a03533          	snez	a0,a0
    8000313e:	40a00533          	neg	a0,a0
}
    80003142:	60e2                	ld	ra,24(sp)
    80003144:	6442                	ld	s0,16(sp)
    80003146:	64a2                	ld	s1,8(sp)
    80003148:	6902                	ld	s2,0(sp)
    8000314a:	6105                	addi	sp,sp,32
    8000314c:	8082                	ret
    return -1;
    8000314e:	557d                	li	a0,-1
    80003150:	bfcd                	j	80003142 <fetchaddr+0x3e>
    80003152:	557d                	li	a0,-1
    80003154:	b7fd                	j	80003142 <fetchaddr+0x3e>

0000000080003156 <fetchstr>:
{
    80003156:	7179                	addi	sp,sp,-48
    80003158:	f406                	sd	ra,40(sp)
    8000315a:	f022                	sd	s0,32(sp)
    8000315c:	ec26                	sd	s1,24(sp)
    8000315e:	e84a                	sd	s2,16(sp)
    80003160:	e44e                	sd	s3,8(sp)
    80003162:	1800                	addi	s0,sp,48
    80003164:	892a                	mv	s2,a0
    80003166:	84ae                	mv	s1,a1
    80003168:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000316a:	fffff097          	auipc	ra,0xfffff
    8000316e:	caa080e7          	jalr	-854(ra) # 80001e14 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003172:	86ce                	mv	a3,s3
    80003174:	864a                	mv	a2,s2
    80003176:	85a6                	mv	a1,s1
    80003178:	6928                	ld	a0,80(a0)
    8000317a:	ffffe097          	auipc	ra,0xffffe
    8000317e:	610080e7          	jalr	1552(ra) # 8000178a <copyinstr>
  if(err < 0)
    80003182:	00054763          	bltz	a0,80003190 <fetchstr+0x3a>
  return strlen(buf);
    80003186:	8526                	mv	a0,s1
    80003188:	ffffe097          	auipc	ra,0xffffe
    8000318c:	cdc080e7          	jalr	-804(ra) # 80000e64 <strlen>
}
    80003190:	70a2                	ld	ra,40(sp)
    80003192:	7402                	ld	s0,32(sp)
    80003194:	64e2                	ld	s1,24(sp)
    80003196:	6942                	ld	s2,16(sp)
    80003198:	69a2                	ld	s3,8(sp)
    8000319a:	6145                	addi	sp,sp,48
    8000319c:	8082                	ret

000000008000319e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000319e:	1101                	addi	sp,sp,-32
    800031a0:	ec06                	sd	ra,24(sp)
    800031a2:	e822                	sd	s0,16(sp)
    800031a4:	e426                	sd	s1,8(sp)
    800031a6:	1000                	addi	s0,sp,32
    800031a8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031aa:	00000097          	auipc	ra,0x0
    800031ae:	ef2080e7          	jalr	-270(ra) # 8000309c <argraw>
    800031b2:	c088                	sw	a0,0(s1)
  return 0;
}
    800031b4:	4501                	li	a0,0
    800031b6:	60e2                	ld	ra,24(sp)
    800031b8:	6442                	ld	s0,16(sp)
    800031ba:	64a2                	ld	s1,8(sp)
    800031bc:	6105                	addi	sp,sp,32
    800031be:	8082                	ret

00000000800031c0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800031c0:	1101                	addi	sp,sp,-32
    800031c2:	ec06                	sd	ra,24(sp)
    800031c4:	e822                	sd	s0,16(sp)
    800031c6:	e426                	sd	s1,8(sp)
    800031c8:	1000                	addi	s0,sp,32
    800031ca:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031cc:	00000097          	auipc	ra,0x0
    800031d0:	ed0080e7          	jalr	-304(ra) # 8000309c <argraw>
    800031d4:	e088                	sd	a0,0(s1)
  return 0;
}
    800031d6:	4501                	li	a0,0
    800031d8:	60e2                	ld	ra,24(sp)
    800031da:	6442                	ld	s0,16(sp)
    800031dc:	64a2                	ld	s1,8(sp)
    800031de:	6105                	addi	sp,sp,32
    800031e0:	8082                	ret

00000000800031e2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800031e2:	1101                	addi	sp,sp,-32
    800031e4:	ec06                	sd	ra,24(sp)
    800031e6:	e822                	sd	s0,16(sp)
    800031e8:	e426                	sd	s1,8(sp)
    800031ea:	e04a                	sd	s2,0(sp)
    800031ec:	1000                	addi	s0,sp,32
    800031ee:	84ae                	mv	s1,a1
    800031f0:	8932                	mv	s2,a2
  *ip = argraw(n);
    800031f2:	00000097          	auipc	ra,0x0
    800031f6:	eaa080e7          	jalr	-342(ra) # 8000309c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800031fa:	864a                	mv	a2,s2
    800031fc:	85a6                	mv	a1,s1
    800031fe:	00000097          	auipc	ra,0x0
    80003202:	f58080e7          	jalr	-168(ra) # 80003156 <fetchstr>
}
    80003206:	60e2                	ld	ra,24(sp)
    80003208:	6442                	ld	s0,16(sp)
    8000320a:	64a2                	ld	s1,8(sp)
    8000320c:	6902                	ld	s2,0(sp)
    8000320e:	6105                	addi	sp,sp,32
    80003210:	8082                	ret

0000000080003212 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80003212:	1101                	addi	sp,sp,-32
    80003214:	ec06                	sd	ra,24(sp)
    80003216:	e822                	sd	s0,16(sp)
    80003218:	e426                	sd	s1,8(sp)
    8000321a:	e04a                	sd	s2,0(sp)
    8000321c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000321e:	fffff097          	auipc	ra,0xfffff
    80003222:	bf6080e7          	jalr	-1034(ra) # 80001e14 <myproc>
    80003226:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003228:	05853903          	ld	s2,88(a0)
    8000322c:	0a893783          	ld	a5,168(s2)
    80003230:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003234:	37fd                	addiw	a5,a5,-1
    80003236:	4751                	li	a4,20
    80003238:	00f76f63          	bltu	a4,a5,80003256 <syscall+0x44>
    8000323c:	00369713          	slli	a4,a3,0x3
    80003240:	00005797          	auipc	a5,0x5
    80003244:	2b078793          	addi	a5,a5,688 # 800084f0 <syscalls>
    80003248:	97ba                	add	a5,a5,a4
    8000324a:	639c                	ld	a5,0(a5)
    8000324c:	c789                	beqz	a5,80003256 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000324e:	9782                	jalr	a5
    80003250:	06a93823          	sd	a0,112(s2)
    80003254:	a839                	j	80003272 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003256:	15848613          	addi	a2,s1,344
    8000325a:	588c                	lw	a1,48(s1)
    8000325c:	00005517          	auipc	a0,0x5
    80003260:	25c50513          	addi	a0,a0,604 # 800084b8 <states.1793+0x150>
    80003264:	ffffd097          	auipc	ra,0xffffd
    80003268:	324080e7          	jalr	804(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000326c:	6cbc                	ld	a5,88(s1)
    8000326e:	577d                	li	a4,-1
    80003270:	fbb8                	sd	a4,112(a5)
  }
}
    80003272:	60e2                	ld	ra,24(sp)
    80003274:	6442                	ld	s0,16(sp)
    80003276:	64a2                	ld	s1,8(sp)
    80003278:	6902                	ld	s2,0(sp)
    8000327a:	6105                	addi	sp,sp,32
    8000327c:	8082                	ret

000000008000327e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000327e:	1101                	addi	sp,sp,-32
    80003280:	ec06                	sd	ra,24(sp)
    80003282:	e822                	sd	s0,16(sp)
    80003284:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003286:	fec40593          	addi	a1,s0,-20
    8000328a:	4501                	li	a0,0
    8000328c:	00000097          	auipc	ra,0x0
    80003290:	f12080e7          	jalr	-238(ra) # 8000319e <argint>
    return -1;
    80003294:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003296:	00054963          	bltz	a0,800032a8 <sys_exit+0x2a>
  exit(n);
    8000329a:	fec42503          	lw	a0,-20(s0)
    8000329e:	fffff097          	auipc	ra,0xfffff
    800032a2:	66e080e7          	jalr	1646(ra) # 8000290c <exit>
  return 0;  // not reached
    800032a6:	4781                	li	a5,0
}
    800032a8:	853e                	mv	a0,a5
    800032aa:	60e2                	ld	ra,24(sp)
    800032ac:	6442                	ld	s0,16(sp)
    800032ae:	6105                	addi	sp,sp,32
    800032b0:	8082                	ret

00000000800032b2 <sys_getpid>:

uint64
sys_getpid(void)
{
    800032b2:	1141                	addi	sp,sp,-16
    800032b4:	e406                	sd	ra,8(sp)
    800032b6:	e022                	sd	s0,0(sp)
    800032b8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800032ba:	fffff097          	auipc	ra,0xfffff
    800032be:	b5a080e7          	jalr	-1190(ra) # 80001e14 <myproc>
}
    800032c2:	5908                	lw	a0,48(a0)
    800032c4:	60a2                	ld	ra,8(sp)
    800032c6:	6402                	ld	s0,0(sp)
    800032c8:	0141                	addi	sp,sp,16
    800032ca:	8082                	ret

00000000800032cc <sys_fork>:

uint64
sys_fork(void)
{
    800032cc:	1141                	addi	sp,sp,-16
    800032ce:	e406                	sd	ra,8(sp)
    800032d0:	e022                	sd	s0,0(sp)
    800032d2:	0800                	addi	s0,sp,16
  return fork();
    800032d4:	fffff097          	auipc	ra,0xfffff
    800032d8:	fd4080e7          	jalr	-44(ra) # 800022a8 <fork>
}
    800032dc:	60a2                	ld	ra,8(sp)
    800032de:	6402                	ld	s0,0(sp)
    800032e0:	0141                	addi	sp,sp,16
    800032e2:	8082                	ret

00000000800032e4 <sys_wait>:

uint64
sys_wait(void)
{
    800032e4:	1101                	addi	sp,sp,-32
    800032e6:	ec06                	sd	ra,24(sp)
    800032e8:	e822                	sd	s0,16(sp)
    800032ea:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800032ec:	fe840593          	addi	a1,s0,-24
    800032f0:	4501                	li	a0,0
    800032f2:	00000097          	auipc	ra,0x0
    800032f6:	ece080e7          	jalr	-306(ra) # 800031c0 <argaddr>
    800032fa:	87aa                	mv	a5,a0
    return -1;
    800032fc:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800032fe:	0007c863          	bltz	a5,8000330e <sys_wait+0x2a>
  return wait(p);
    80003302:	fe843503          	ld	a0,-24(s0)
    80003306:	fffff097          	auipc	ra,0xfffff
    8000330a:	398080e7          	jalr	920(ra) # 8000269e <wait>
}
    8000330e:	60e2                	ld	ra,24(sp)
    80003310:	6442                	ld	s0,16(sp)
    80003312:	6105                	addi	sp,sp,32
    80003314:	8082                	ret

0000000080003316 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003316:	7179                	addi	sp,sp,-48
    80003318:	f406                	sd	ra,40(sp)
    8000331a:	f022                	sd	s0,32(sp)
    8000331c:	ec26                	sd	s1,24(sp)
    8000331e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003320:	fdc40593          	addi	a1,s0,-36
    80003324:	4501                	li	a0,0
    80003326:	00000097          	auipc	ra,0x0
    8000332a:	e78080e7          	jalr	-392(ra) # 8000319e <argint>
    8000332e:	87aa                	mv	a5,a0
    return -1;
    80003330:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003332:	0207c063          	bltz	a5,80003352 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003336:	fffff097          	auipc	ra,0xfffff
    8000333a:	ade080e7          	jalr	-1314(ra) # 80001e14 <myproc>
    8000333e:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003340:	fdc42503          	lw	a0,-36(s0)
    80003344:	fffff097          	auipc	ra,0xfffff
    80003348:	ef0080e7          	jalr	-272(ra) # 80002234 <growproc>
    8000334c:	00054863          	bltz	a0,8000335c <sys_sbrk+0x46>
    return -1;
  return addr;
    80003350:	8526                	mv	a0,s1
}
    80003352:	70a2                	ld	ra,40(sp)
    80003354:	7402                	ld	s0,32(sp)
    80003356:	64e2                	ld	s1,24(sp)
    80003358:	6145                	addi	sp,sp,48
    8000335a:	8082                	ret
    return -1;
    8000335c:	557d                	li	a0,-1
    8000335e:	bfd5                	j	80003352 <sys_sbrk+0x3c>

0000000080003360 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003360:	7139                	addi	sp,sp,-64
    80003362:	fc06                	sd	ra,56(sp)
    80003364:	f822                	sd	s0,48(sp)
    80003366:	f426                	sd	s1,40(sp)
    80003368:	f04a                	sd	s2,32(sp)
    8000336a:	ec4e                	sd	s3,24(sp)
    8000336c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000336e:	fcc40593          	addi	a1,s0,-52
    80003372:	4501                	li	a0,0
    80003374:	00000097          	auipc	ra,0x0
    80003378:	e2a080e7          	jalr	-470(ra) # 8000319e <argint>
    return -1;
    8000337c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000337e:	06054563          	bltz	a0,800033e8 <sys_sleep+0x88>
  acquire(&tickslock);
    80003382:	00015517          	auipc	a0,0x15
    80003386:	88e50513          	addi	a0,a0,-1906 # 80017c10 <tickslock>
    8000338a:	ffffe097          	auipc	ra,0xffffe
    8000338e:	85a080e7          	jalr	-1958(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003392:	00006917          	auipc	s2,0x6
    80003396:	c9e92903          	lw	s2,-866(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000339a:	fcc42783          	lw	a5,-52(s0)
    8000339e:	cf85                	beqz	a5,800033d6 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800033a0:	00015997          	auipc	s3,0x15
    800033a4:	87098993          	addi	s3,s3,-1936 # 80017c10 <tickslock>
    800033a8:	00006497          	auipc	s1,0x6
    800033ac:	c8848493          	addi	s1,s1,-888 # 80009030 <ticks>
    if(myproc()->killed){
    800033b0:	fffff097          	auipc	ra,0xfffff
    800033b4:	a64080e7          	jalr	-1436(ra) # 80001e14 <myproc>
    800033b8:	551c                	lw	a5,40(a0)
    800033ba:	ef9d                	bnez	a5,800033f8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800033bc:	85ce                	mv	a1,s3
    800033be:	8526                	mv	a0,s1
    800033c0:	fffff097          	auipc	ra,0xfffff
    800033c4:	268080e7          	jalr	616(ra) # 80002628 <sleep>
  while(ticks - ticks0 < n){
    800033c8:	409c                	lw	a5,0(s1)
    800033ca:	412787bb          	subw	a5,a5,s2
    800033ce:	fcc42703          	lw	a4,-52(s0)
    800033d2:	fce7efe3          	bltu	a5,a4,800033b0 <sys_sleep+0x50>
  }
  release(&tickslock);
    800033d6:	00015517          	auipc	a0,0x15
    800033da:	83a50513          	addi	a0,a0,-1990 # 80017c10 <tickslock>
    800033de:	ffffe097          	auipc	ra,0xffffe
    800033e2:	8ba080e7          	jalr	-1862(ra) # 80000c98 <release>
  return 0;
    800033e6:	4781                	li	a5,0
}
    800033e8:	853e                	mv	a0,a5
    800033ea:	70e2                	ld	ra,56(sp)
    800033ec:	7442                	ld	s0,48(sp)
    800033ee:	74a2                	ld	s1,40(sp)
    800033f0:	7902                	ld	s2,32(sp)
    800033f2:	69e2                	ld	s3,24(sp)
    800033f4:	6121                	addi	sp,sp,64
    800033f6:	8082                	ret
      release(&tickslock);
    800033f8:	00015517          	auipc	a0,0x15
    800033fc:	81850513          	addi	a0,a0,-2024 # 80017c10 <tickslock>
    80003400:	ffffe097          	auipc	ra,0xffffe
    80003404:	898080e7          	jalr	-1896(ra) # 80000c98 <release>
      return -1;
    80003408:	57fd                	li	a5,-1
    8000340a:	bff9                	j	800033e8 <sys_sleep+0x88>

000000008000340c <sys_kill>:

uint64
sys_kill(void)
{
    8000340c:	1101                	addi	sp,sp,-32
    8000340e:	ec06                	sd	ra,24(sp)
    80003410:	e822                	sd	s0,16(sp)
    80003412:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003414:	fec40593          	addi	a1,s0,-20
    80003418:	4501                	li	a0,0
    8000341a:	00000097          	auipc	ra,0x0
    8000341e:	d84080e7          	jalr	-636(ra) # 8000319e <argint>
    80003422:	87aa                	mv	a5,a0
    return -1;
    80003424:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003426:	0007c863          	bltz	a5,80003436 <sys_kill+0x2a>
  return kill(pid);
    8000342a:	fec42503          	lw	a0,-20(s0)
    8000342e:	fffff097          	auipc	ra,0xfffff
    80003432:	5c6080e7          	jalr	1478(ra) # 800029f4 <kill>
}
    80003436:	60e2                	ld	ra,24(sp)
    80003438:	6442                	ld	s0,16(sp)
    8000343a:	6105                	addi	sp,sp,32
    8000343c:	8082                	ret

000000008000343e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000343e:	1101                	addi	sp,sp,-32
    80003440:	ec06                	sd	ra,24(sp)
    80003442:	e822                	sd	s0,16(sp)
    80003444:	e426                	sd	s1,8(sp)
    80003446:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003448:	00014517          	auipc	a0,0x14
    8000344c:	7c850513          	addi	a0,a0,1992 # 80017c10 <tickslock>
    80003450:	ffffd097          	auipc	ra,0xffffd
    80003454:	794080e7          	jalr	1940(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003458:	00006497          	auipc	s1,0x6
    8000345c:	bd84a483          	lw	s1,-1064(s1) # 80009030 <ticks>
  release(&tickslock);
    80003460:	00014517          	auipc	a0,0x14
    80003464:	7b050513          	addi	a0,a0,1968 # 80017c10 <tickslock>
    80003468:	ffffe097          	auipc	ra,0xffffe
    8000346c:	830080e7          	jalr	-2000(ra) # 80000c98 <release>
  return xticks;
}
    80003470:	02049513          	slli	a0,s1,0x20
    80003474:	9101                	srli	a0,a0,0x20
    80003476:	60e2                	ld	ra,24(sp)
    80003478:	6442                	ld	s0,16(sp)
    8000347a:	64a2                	ld	s1,8(sp)
    8000347c:	6105                	addi	sp,sp,32
    8000347e:	8082                	ret

0000000080003480 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003480:	7179                	addi	sp,sp,-48
    80003482:	f406                	sd	ra,40(sp)
    80003484:	f022                	sd	s0,32(sp)
    80003486:	ec26                	sd	s1,24(sp)
    80003488:	e84a                	sd	s2,16(sp)
    8000348a:	e44e                	sd	s3,8(sp)
    8000348c:	e052                	sd	s4,0(sp)
    8000348e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003490:	00005597          	auipc	a1,0x5
    80003494:	11058593          	addi	a1,a1,272 # 800085a0 <syscalls+0xb0>
    80003498:	00014517          	auipc	a0,0x14
    8000349c:	79050513          	addi	a0,a0,1936 # 80017c28 <bcache>
    800034a0:	ffffd097          	auipc	ra,0xffffd
    800034a4:	6b4080e7          	jalr	1716(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800034a8:	0001c797          	auipc	a5,0x1c
    800034ac:	78078793          	addi	a5,a5,1920 # 8001fc28 <bcache+0x8000>
    800034b0:	0001d717          	auipc	a4,0x1d
    800034b4:	9e070713          	addi	a4,a4,-1568 # 8001fe90 <bcache+0x8268>
    800034b8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034bc:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034c0:	00014497          	auipc	s1,0x14
    800034c4:	78048493          	addi	s1,s1,1920 # 80017c40 <bcache+0x18>
    b->next = bcache.head.next;
    800034c8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034ca:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034cc:	00005a17          	auipc	s4,0x5
    800034d0:	0dca0a13          	addi	s4,s4,220 # 800085a8 <syscalls+0xb8>
    b->next = bcache.head.next;
    800034d4:	2b893783          	ld	a5,696(s2)
    800034d8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800034da:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034de:	85d2                	mv	a1,s4
    800034e0:	01048513          	addi	a0,s1,16
    800034e4:	00001097          	auipc	ra,0x1
    800034e8:	4bc080e7          	jalr	1212(ra) # 800049a0 <initsleeplock>
    bcache.head.next->prev = b;
    800034ec:	2b893783          	ld	a5,696(s2)
    800034f0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034f2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034f6:	45848493          	addi	s1,s1,1112
    800034fa:	fd349de3          	bne	s1,s3,800034d4 <binit+0x54>
  }
}
    800034fe:	70a2                	ld	ra,40(sp)
    80003500:	7402                	ld	s0,32(sp)
    80003502:	64e2                	ld	s1,24(sp)
    80003504:	6942                	ld	s2,16(sp)
    80003506:	69a2                	ld	s3,8(sp)
    80003508:	6a02                	ld	s4,0(sp)
    8000350a:	6145                	addi	sp,sp,48
    8000350c:	8082                	ret

000000008000350e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000350e:	7179                	addi	sp,sp,-48
    80003510:	f406                	sd	ra,40(sp)
    80003512:	f022                	sd	s0,32(sp)
    80003514:	ec26                	sd	s1,24(sp)
    80003516:	e84a                	sd	s2,16(sp)
    80003518:	e44e                	sd	s3,8(sp)
    8000351a:	1800                	addi	s0,sp,48
    8000351c:	89aa                	mv	s3,a0
    8000351e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003520:	00014517          	auipc	a0,0x14
    80003524:	70850513          	addi	a0,a0,1800 # 80017c28 <bcache>
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	6bc080e7          	jalr	1724(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003530:	0001d497          	auipc	s1,0x1d
    80003534:	9b04b483          	ld	s1,-1616(s1) # 8001fee0 <bcache+0x82b8>
    80003538:	0001d797          	auipc	a5,0x1d
    8000353c:	95878793          	addi	a5,a5,-1704 # 8001fe90 <bcache+0x8268>
    80003540:	02f48f63          	beq	s1,a5,8000357e <bread+0x70>
    80003544:	873e                	mv	a4,a5
    80003546:	a021                	j	8000354e <bread+0x40>
    80003548:	68a4                	ld	s1,80(s1)
    8000354a:	02e48a63          	beq	s1,a4,8000357e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000354e:	449c                	lw	a5,8(s1)
    80003550:	ff379ce3          	bne	a5,s3,80003548 <bread+0x3a>
    80003554:	44dc                	lw	a5,12(s1)
    80003556:	ff2799e3          	bne	a5,s2,80003548 <bread+0x3a>
      b->refcnt++;
    8000355a:	40bc                	lw	a5,64(s1)
    8000355c:	2785                	addiw	a5,a5,1
    8000355e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003560:	00014517          	auipc	a0,0x14
    80003564:	6c850513          	addi	a0,a0,1736 # 80017c28 <bcache>
    80003568:	ffffd097          	auipc	ra,0xffffd
    8000356c:	730080e7          	jalr	1840(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003570:	01048513          	addi	a0,s1,16
    80003574:	00001097          	auipc	ra,0x1
    80003578:	466080e7          	jalr	1126(ra) # 800049da <acquiresleep>
      return b;
    8000357c:	a8b9                	j	800035da <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000357e:	0001d497          	auipc	s1,0x1d
    80003582:	95a4b483          	ld	s1,-1702(s1) # 8001fed8 <bcache+0x82b0>
    80003586:	0001d797          	auipc	a5,0x1d
    8000358a:	90a78793          	addi	a5,a5,-1782 # 8001fe90 <bcache+0x8268>
    8000358e:	00f48863          	beq	s1,a5,8000359e <bread+0x90>
    80003592:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003594:	40bc                	lw	a5,64(s1)
    80003596:	cf81                	beqz	a5,800035ae <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003598:	64a4                	ld	s1,72(s1)
    8000359a:	fee49de3          	bne	s1,a4,80003594 <bread+0x86>
  panic("bget: no buffers");
    8000359e:	00005517          	auipc	a0,0x5
    800035a2:	01250513          	addi	a0,a0,18 # 800085b0 <syscalls+0xc0>
    800035a6:	ffffd097          	auipc	ra,0xffffd
    800035aa:	f98080e7          	jalr	-104(ra) # 8000053e <panic>
      b->dev = dev;
    800035ae:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800035b2:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800035b6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035ba:	4785                	li	a5,1
    800035bc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035be:	00014517          	auipc	a0,0x14
    800035c2:	66a50513          	addi	a0,a0,1642 # 80017c28 <bcache>
    800035c6:	ffffd097          	auipc	ra,0xffffd
    800035ca:	6d2080e7          	jalr	1746(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800035ce:	01048513          	addi	a0,s1,16
    800035d2:	00001097          	auipc	ra,0x1
    800035d6:	408080e7          	jalr	1032(ra) # 800049da <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800035da:	409c                	lw	a5,0(s1)
    800035dc:	cb89                	beqz	a5,800035ee <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035de:	8526                	mv	a0,s1
    800035e0:	70a2                	ld	ra,40(sp)
    800035e2:	7402                	ld	s0,32(sp)
    800035e4:	64e2                	ld	s1,24(sp)
    800035e6:	6942                	ld	s2,16(sp)
    800035e8:	69a2                	ld	s3,8(sp)
    800035ea:	6145                	addi	sp,sp,48
    800035ec:	8082                	ret
    virtio_disk_rw(b, 0);
    800035ee:	4581                	li	a1,0
    800035f0:	8526                	mv	a0,s1
    800035f2:	00003097          	auipc	ra,0x3
    800035f6:	f14080e7          	jalr	-236(ra) # 80006506 <virtio_disk_rw>
    b->valid = 1;
    800035fa:	4785                	li	a5,1
    800035fc:	c09c                	sw	a5,0(s1)
  return b;
    800035fe:	b7c5                	j	800035de <bread+0xd0>

0000000080003600 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003600:	1101                	addi	sp,sp,-32
    80003602:	ec06                	sd	ra,24(sp)
    80003604:	e822                	sd	s0,16(sp)
    80003606:	e426                	sd	s1,8(sp)
    80003608:	1000                	addi	s0,sp,32
    8000360a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000360c:	0541                	addi	a0,a0,16
    8000360e:	00001097          	auipc	ra,0x1
    80003612:	466080e7          	jalr	1126(ra) # 80004a74 <holdingsleep>
    80003616:	cd01                	beqz	a0,8000362e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003618:	4585                	li	a1,1
    8000361a:	8526                	mv	a0,s1
    8000361c:	00003097          	auipc	ra,0x3
    80003620:	eea080e7          	jalr	-278(ra) # 80006506 <virtio_disk_rw>
}
    80003624:	60e2                	ld	ra,24(sp)
    80003626:	6442                	ld	s0,16(sp)
    80003628:	64a2                	ld	s1,8(sp)
    8000362a:	6105                	addi	sp,sp,32
    8000362c:	8082                	ret
    panic("bwrite");
    8000362e:	00005517          	auipc	a0,0x5
    80003632:	f9a50513          	addi	a0,a0,-102 # 800085c8 <syscalls+0xd8>
    80003636:	ffffd097          	auipc	ra,0xffffd
    8000363a:	f08080e7          	jalr	-248(ra) # 8000053e <panic>

000000008000363e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000363e:	1101                	addi	sp,sp,-32
    80003640:	ec06                	sd	ra,24(sp)
    80003642:	e822                	sd	s0,16(sp)
    80003644:	e426                	sd	s1,8(sp)
    80003646:	e04a                	sd	s2,0(sp)
    80003648:	1000                	addi	s0,sp,32
    8000364a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000364c:	01050913          	addi	s2,a0,16
    80003650:	854a                	mv	a0,s2
    80003652:	00001097          	auipc	ra,0x1
    80003656:	422080e7          	jalr	1058(ra) # 80004a74 <holdingsleep>
    8000365a:	c92d                	beqz	a0,800036cc <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000365c:	854a                	mv	a0,s2
    8000365e:	00001097          	auipc	ra,0x1
    80003662:	3d2080e7          	jalr	978(ra) # 80004a30 <releasesleep>

  acquire(&bcache.lock);
    80003666:	00014517          	auipc	a0,0x14
    8000366a:	5c250513          	addi	a0,a0,1474 # 80017c28 <bcache>
    8000366e:	ffffd097          	auipc	ra,0xffffd
    80003672:	576080e7          	jalr	1398(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003676:	40bc                	lw	a5,64(s1)
    80003678:	37fd                	addiw	a5,a5,-1
    8000367a:	0007871b          	sext.w	a4,a5
    8000367e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003680:	eb05                	bnez	a4,800036b0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003682:	68bc                	ld	a5,80(s1)
    80003684:	64b8                	ld	a4,72(s1)
    80003686:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003688:	64bc                	ld	a5,72(s1)
    8000368a:	68b8                	ld	a4,80(s1)
    8000368c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000368e:	0001c797          	auipc	a5,0x1c
    80003692:	59a78793          	addi	a5,a5,1434 # 8001fc28 <bcache+0x8000>
    80003696:	2b87b703          	ld	a4,696(a5)
    8000369a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000369c:	0001c717          	auipc	a4,0x1c
    800036a0:	7f470713          	addi	a4,a4,2036 # 8001fe90 <bcache+0x8268>
    800036a4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800036a6:	2b87b703          	ld	a4,696(a5)
    800036aa:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800036ac:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800036b0:	00014517          	auipc	a0,0x14
    800036b4:	57850513          	addi	a0,a0,1400 # 80017c28 <bcache>
    800036b8:	ffffd097          	auipc	ra,0xffffd
    800036bc:	5e0080e7          	jalr	1504(ra) # 80000c98 <release>
}
    800036c0:	60e2                	ld	ra,24(sp)
    800036c2:	6442                	ld	s0,16(sp)
    800036c4:	64a2                	ld	s1,8(sp)
    800036c6:	6902                	ld	s2,0(sp)
    800036c8:	6105                	addi	sp,sp,32
    800036ca:	8082                	ret
    panic("brelse");
    800036cc:	00005517          	auipc	a0,0x5
    800036d0:	f0450513          	addi	a0,a0,-252 # 800085d0 <syscalls+0xe0>
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	e6a080e7          	jalr	-406(ra) # 8000053e <panic>

00000000800036dc <bpin>:

void
bpin(struct buf *b) {
    800036dc:	1101                	addi	sp,sp,-32
    800036de:	ec06                	sd	ra,24(sp)
    800036e0:	e822                	sd	s0,16(sp)
    800036e2:	e426                	sd	s1,8(sp)
    800036e4:	1000                	addi	s0,sp,32
    800036e6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036e8:	00014517          	auipc	a0,0x14
    800036ec:	54050513          	addi	a0,a0,1344 # 80017c28 <bcache>
    800036f0:	ffffd097          	auipc	ra,0xffffd
    800036f4:	4f4080e7          	jalr	1268(ra) # 80000be4 <acquire>
  b->refcnt++;
    800036f8:	40bc                	lw	a5,64(s1)
    800036fa:	2785                	addiw	a5,a5,1
    800036fc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036fe:	00014517          	auipc	a0,0x14
    80003702:	52a50513          	addi	a0,a0,1322 # 80017c28 <bcache>
    80003706:	ffffd097          	auipc	ra,0xffffd
    8000370a:	592080e7          	jalr	1426(ra) # 80000c98 <release>
}
    8000370e:	60e2                	ld	ra,24(sp)
    80003710:	6442                	ld	s0,16(sp)
    80003712:	64a2                	ld	s1,8(sp)
    80003714:	6105                	addi	sp,sp,32
    80003716:	8082                	ret

0000000080003718 <bunpin>:

void
bunpin(struct buf *b) {
    80003718:	1101                	addi	sp,sp,-32
    8000371a:	ec06                	sd	ra,24(sp)
    8000371c:	e822                	sd	s0,16(sp)
    8000371e:	e426                	sd	s1,8(sp)
    80003720:	1000                	addi	s0,sp,32
    80003722:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003724:	00014517          	auipc	a0,0x14
    80003728:	50450513          	addi	a0,a0,1284 # 80017c28 <bcache>
    8000372c:	ffffd097          	auipc	ra,0xffffd
    80003730:	4b8080e7          	jalr	1208(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003734:	40bc                	lw	a5,64(s1)
    80003736:	37fd                	addiw	a5,a5,-1
    80003738:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000373a:	00014517          	auipc	a0,0x14
    8000373e:	4ee50513          	addi	a0,a0,1262 # 80017c28 <bcache>
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	556080e7          	jalr	1366(ra) # 80000c98 <release>
}
    8000374a:	60e2                	ld	ra,24(sp)
    8000374c:	6442                	ld	s0,16(sp)
    8000374e:	64a2                	ld	s1,8(sp)
    80003750:	6105                	addi	sp,sp,32
    80003752:	8082                	ret

0000000080003754 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003754:	1101                	addi	sp,sp,-32
    80003756:	ec06                	sd	ra,24(sp)
    80003758:	e822                	sd	s0,16(sp)
    8000375a:	e426                	sd	s1,8(sp)
    8000375c:	e04a                	sd	s2,0(sp)
    8000375e:	1000                	addi	s0,sp,32
    80003760:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003762:	00d5d59b          	srliw	a1,a1,0xd
    80003766:	0001d797          	auipc	a5,0x1d
    8000376a:	b9e7a783          	lw	a5,-1122(a5) # 80020304 <sb+0x1c>
    8000376e:	9dbd                	addw	a1,a1,a5
    80003770:	00000097          	auipc	ra,0x0
    80003774:	d9e080e7          	jalr	-610(ra) # 8000350e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003778:	0074f713          	andi	a4,s1,7
    8000377c:	4785                	li	a5,1
    8000377e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003782:	14ce                	slli	s1,s1,0x33
    80003784:	90d9                	srli	s1,s1,0x36
    80003786:	00950733          	add	a4,a0,s1
    8000378a:	05874703          	lbu	a4,88(a4)
    8000378e:	00e7f6b3          	and	a3,a5,a4
    80003792:	c69d                	beqz	a3,800037c0 <bfree+0x6c>
    80003794:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003796:	94aa                	add	s1,s1,a0
    80003798:	fff7c793          	not	a5,a5
    8000379c:	8ff9                	and	a5,a5,a4
    8000379e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800037a2:	00001097          	auipc	ra,0x1
    800037a6:	118080e7          	jalr	280(ra) # 800048ba <log_write>
  brelse(bp);
    800037aa:	854a                	mv	a0,s2
    800037ac:	00000097          	auipc	ra,0x0
    800037b0:	e92080e7          	jalr	-366(ra) # 8000363e <brelse>
}
    800037b4:	60e2                	ld	ra,24(sp)
    800037b6:	6442                	ld	s0,16(sp)
    800037b8:	64a2                	ld	s1,8(sp)
    800037ba:	6902                	ld	s2,0(sp)
    800037bc:	6105                	addi	sp,sp,32
    800037be:	8082                	ret
    panic("freeing free block");
    800037c0:	00005517          	auipc	a0,0x5
    800037c4:	e1850513          	addi	a0,a0,-488 # 800085d8 <syscalls+0xe8>
    800037c8:	ffffd097          	auipc	ra,0xffffd
    800037cc:	d76080e7          	jalr	-650(ra) # 8000053e <panic>

00000000800037d0 <balloc>:
{
    800037d0:	711d                	addi	sp,sp,-96
    800037d2:	ec86                	sd	ra,88(sp)
    800037d4:	e8a2                	sd	s0,80(sp)
    800037d6:	e4a6                	sd	s1,72(sp)
    800037d8:	e0ca                	sd	s2,64(sp)
    800037da:	fc4e                	sd	s3,56(sp)
    800037dc:	f852                	sd	s4,48(sp)
    800037de:	f456                	sd	s5,40(sp)
    800037e0:	f05a                	sd	s6,32(sp)
    800037e2:	ec5e                	sd	s7,24(sp)
    800037e4:	e862                	sd	s8,16(sp)
    800037e6:	e466                	sd	s9,8(sp)
    800037e8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037ea:	0001d797          	auipc	a5,0x1d
    800037ee:	b027a783          	lw	a5,-1278(a5) # 800202ec <sb+0x4>
    800037f2:	cbd1                	beqz	a5,80003886 <balloc+0xb6>
    800037f4:	8baa                	mv	s7,a0
    800037f6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037f8:	0001db17          	auipc	s6,0x1d
    800037fc:	af0b0b13          	addi	s6,s6,-1296 # 800202e8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003800:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003802:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003804:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003806:	6c89                	lui	s9,0x2
    80003808:	a831                	j	80003824 <balloc+0x54>
    brelse(bp);
    8000380a:	854a                	mv	a0,s2
    8000380c:	00000097          	auipc	ra,0x0
    80003810:	e32080e7          	jalr	-462(ra) # 8000363e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003814:	015c87bb          	addw	a5,s9,s5
    80003818:	00078a9b          	sext.w	s5,a5
    8000381c:	004b2703          	lw	a4,4(s6)
    80003820:	06eaf363          	bgeu	s5,a4,80003886 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003824:	41fad79b          	sraiw	a5,s5,0x1f
    80003828:	0137d79b          	srliw	a5,a5,0x13
    8000382c:	015787bb          	addw	a5,a5,s5
    80003830:	40d7d79b          	sraiw	a5,a5,0xd
    80003834:	01cb2583          	lw	a1,28(s6)
    80003838:	9dbd                	addw	a1,a1,a5
    8000383a:	855e                	mv	a0,s7
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	cd2080e7          	jalr	-814(ra) # 8000350e <bread>
    80003844:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003846:	004b2503          	lw	a0,4(s6)
    8000384a:	000a849b          	sext.w	s1,s5
    8000384e:	8662                	mv	a2,s8
    80003850:	faa4fde3          	bgeu	s1,a0,8000380a <balloc+0x3a>
      m = 1 << (bi % 8);
    80003854:	41f6579b          	sraiw	a5,a2,0x1f
    80003858:	01d7d69b          	srliw	a3,a5,0x1d
    8000385c:	00c6873b          	addw	a4,a3,a2
    80003860:	00777793          	andi	a5,a4,7
    80003864:	9f95                	subw	a5,a5,a3
    80003866:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000386a:	4037571b          	sraiw	a4,a4,0x3
    8000386e:	00e906b3          	add	a3,s2,a4
    80003872:	0586c683          	lbu	a3,88(a3)
    80003876:	00d7f5b3          	and	a1,a5,a3
    8000387a:	cd91                	beqz	a1,80003896 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000387c:	2605                	addiw	a2,a2,1
    8000387e:	2485                	addiw	s1,s1,1
    80003880:	fd4618e3          	bne	a2,s4,80003850 <balloc+0x80>
    80003884:	b759                	j	8000380a <balloc+0x3a>
  panic("balloc: out of blocks");
    80003886:	00005517          	auipc	a0,0x5
    8000388a:	d6a50513          	addi	a0,a0,-662 # 800085f0 <syscalls+0x100>
    8000388e:	ffffd097          	auipc	ra,0xffffd
    80003892:	cb0080e7          	jalr	-848(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003896:	974a                	add	a4,a4,s2
    80003898:	8fd5                	or	a5,a5,a3
    8000389a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000389e:	854a                	mv	a0,s2
    800038a0:	00001097          	auipc	ra,0x1
    800038a4:	01a080e7          	jalr	26(ra) # 800048ba <log_write>
        brelse(bp);
    800038a8:	854a                	mv	a0,s2
    800038aa:	00000097          	auipc	ra,0x0
    800038ae:	d94080e7          	jalr	-620(ra) # 8000363e <brelse>
  bp = bread(dev, bno);
    800038b2:	85a6                	mv	a1,s1
    800038b4:	855e                	mv	a0,s7
    800038b6:	00000097          	auipc	ra,0x0
    800038ba:	c58080e7          	jalr	-936(ra) # 8000350e <bread>
    800038be:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038c0:	40000613          	li	a2,1024
    800038c4:	4581                	li	a1,0
    800038c6:	05850513          	addi	a0,a0,88
    800038ca:	ffffd097          	auipc	ra,0xffffd
    800038ce:	416080e7          	jalr	1046(ra) # 80000ce0 <memset>
  log_write(bp);
    800038d2:	854a                	mv	a0,s2
    800038d4:	00001097          	auipc	ra,0x1
    800038d8:	fe6080e7          	jalr	-26(ra) # 800048ba <log_write>
  brelse(bp);
    800038dc:	854a                	mv	a0,s2
    800038de:	00000097          	auipc	ra,0x0
    800038e2:	d60080e7          	jalr	-672(ra) # 8000363e <brelse>
}
    800038e6:	8526                	mv	a0,s1
    800038e8:	60e6                	ld	ra,88(sp)
    800038ea:	6446                	ld	s0,80(sp)
    800038ec:	64a6                	ld	s1,72(sp)
    800038ee:	6906                	ld	s2,64(sp)
    800038f0:	79e2                	ld	s3,56(sp)
    800038f2:	7a42                	ld	s4,48(sp)
    800038f4:	7aa2                	ld	s5,40(sp)
    800038f6:	7b02                	ld	s6,32(sp)
    800038f8:	6be2                	ld	s7,24(sp)
    800038fa:	6c42                	ld	s8,16(sp)
    800038fc:	6ca2                	ld	s9,8(sp)
    800038fe:	6125                	addi	sp,sp,96
    80003900:	8082                	ret

0000000080003902 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003902:	7179                	addi	sp,sp,-48
    80003904:	f406                	sd	ra,40(sp)
    80003906:	f022                	sd	s0,32(sp)
    80003908:	ec26                	sd	s1,24(sp)
    8000390a:	e84a                	sd	s2,16(sp)
    8000390c:	e44e                	sd	s3,8(sp)
    8000390e:	e052                	sd	s4,0(sp)
    80003910:	1800                	addi	s0,sp,48
    80003912:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003914:	47ad                	li	a5,11
    80003916:	04b7fe63          	bgeu	a5,a1,80003972 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000391a:	ff45849b          	addiw	s1,a1,-12
    8000391e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003922:	0ff00793          	li	a5,255
    80003926:	0ae7e363          	bltu	a5,a4,800039cc <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000392a:	08052583          	lw	a1,128(a0)
    8000392e:	c5ad                	beqz	a1,80003998 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003930:	00092503          	lw	a0,0(s2)
    80003934:	00000097          	auipc	ra,0x0
    80003938:	bda080e7          	jalr	-1062(ra) # 8000350e <bread>
    8000393c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000393e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003942:	02049593          	slli	a1,s1,0x20
    80003946:	9181                	srli	a1,a1,0x20
    80003948:	058a                	slli	a1,a1,0x2
    8000394a:	00b784b3          	add	s1,a5,a1
    8000394e:	0004a983          	lw	s3,0(s1)
    80003952:	04098d63          	beqz	s3,800039ac <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003956:	8552                	mv	a0,s4
    80003958:	00000097          	auipc	ra,0x0
    8000395c:	ce6080e7          	jalr	-794(ra) # 8000363e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003960:	854e                	mv	a0,s3
    80003962:	70a2                	ld	ra,40(sp)
    80003964:	7402                	ld	s0,32(sp)
    80003966:	64e2                	ld	s1,24(sp)
    80003968:	6942                	ld	s2,16(sp)
    8000396a:	69a2                	ld	s3,8(sp)
    8000396c:	6a02                	ld	s4,0(sp)
    8000396e:	6145                	addi	sp,sp,48
    80003970:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003972:	02059493          	slli	s1,a1,0x20
    80003976:	9081                	srli	s1,s1,0x20
    80003978:	048a                	slli	s1,s1,0x2
    8000397a:	94aa                	add	s1,s1,a0
    8000397c:	0504a983          	lw	s3,80(s1)
    80003980:	fe0990e3          	bnez	s3,80003960 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003984:	4108                	lw	a0,0(a0)
    80003986:	00000097          	auipc	ra,0x0
    8000398a:	e4a080e7          	jalr	-438(ra) # 800037d0 <balloc>
    8000398e:	0005099b          	sext.w	s3,a0
    80003992:	0534a823          	sw	s3,80(s1)
    80003996:	b7e9                	j	80003960 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003998:	4108                	lw	a0,0(a0)
    8000399a:	00000097          	auipc	ra,0x0
    8000399e:	e36080e7          	jalr	-458(ra) # 800037d0 <balloc>
    800039a2:	0005059b          	sext.w	a1,a0
    800039a6:	08b92023          	sw	a1,128(s2)
    800039aa:	b759                	j	80003930 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800039ac:	00092503          	lw	a0,0(s2)
    800039b0:	00000097          	auipc	ra,0x0
    800039b4:	e20080e7          	jalr	-480(ra) # 800037d0 <balloc>
    800039b8:	0005099b          	sext.w	s3,a0
    800039bc:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800039c0:	8552                	mv	a0,s4
    800039c2:	00001097          	auipc	ra,0x1
    800039c6:	ef8080e7          	jalr	-264(ra) # 800048ba <log_write>
    800039ca:	b771                	j	80003956 <bmap+0x54>
  panic("bmap: out of range");
    800039cc:	00005517          	auipc	a0,0x5
    800039d0:	c3c50513          	addi	a0,a0,-964 # 80008608 <syscalls+0x118>
    800039d4:	ffffd097          	auipc	ra,0xffffd
    800039d8:	b6a080e7          	jalr	-1174(ra) # 8000053e <panic>

00000000800039dc <iget>:
{
    800039dc:	7179                	addi	sp,sp,-48
    800039de:	f406                	sd	ra,40(sp)
    800039e0:	f022                	sd	s0,32(sp)
    800039e2:	ec26                	sd	s1,24(sp)
    800039e4:	e84a                	sd	s2,16(sp)
    800039e6:	e44e                	sd	s3,8(sp)
    800039e8:	e052                	sd	s4,0(sp)
    800039ea:	1800                	addi	s0,sp,48
    800039ec:	89aa                	mv	s3,a0
    800039ee:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800039f0:	0001d517          	auipc	a0,0x1d
    800039f4:	91850513          	addi	a0,a0,-1768 # 80020308 <itable>
    800039f8:	ffffd097          	auipc	ra,0xffffd
    800039fc:	1ec080e7          	jalr	492(ra) # 80000be4 <acquire>
  empty = 0;
    80003a00:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a02:	0001d497          	auipc	s1,0x1d
    80003a06:	91e48493          	addi	s1,s1,-1762 # 80020320 <itable+0x18>
    80003a0a:	0001e697          	auipc	a3,0x1e
    80003a0e:	3a668693          	addi	a3,a3,934 # 80021db0 <log>
    80003a12:	a039                	j	80003a20 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a14:	02090b63          	beqz	s2,80003a4a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a18:	08848493          	addi	s1,s1,136
    80003a1c:	02d48a63          	beq	s1,a3,80003a50 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a20:	449c                	lw	a5,8(s1)
    80003a22:	fef059e3          	blez	a5,80003a14 <iget+0x38>
    80003a26:	4098                	lw	a4,0(s1)
    80003a28:	ff3716e3          	bne	a4,s3,80003a14 <iget+0x38>
    80003a2c:	40d8                	lw	a4,4(s1)
    80003a2e:	ff4713e3          	bne	a4,s4,80003a14 <iget+0x38>
      ip->ref++;
    80003a32:	2785                	addiw	a5,a5,1
    80003a34:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a36:	0001d517          	auipc	a0,0x1d
    80003a3a:	8d250513          	addi	a0,a0,-1838 # 80020308 <itable>
    80003a3e:	ffffd097          	auipc	ra,0xffffd
    80003a42:	25a080e7          	jalr	602(ra) # 80000c98 <release>
      return ip;
    80003a46:	8926                	mv	s2,s1
    80003a48:	a03d                	j	80003a76 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a4a:	f7f9                	bnez	a5,80003a18 <iget+0x3c>
    80003a4c:	8926                	mv	s2,s1
    80003a4e:	b7e9                	j	80003a18 <iget+0x3c>
  if(empty == 0)
    80003a50:	02090c63          	beqz	s2,80003a88 <iget+0xac>
  ip->dev = dev;
    80003a54:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a58:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a5c:	4785                	li	a5,1
    80003a5e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a62:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a66:	0001d517          	auipc	a0,0x1d
    80003a6a:	8a250513          	addi	a0,a0,-1886 # 80020308 <itable>
    80003a6e:	ffffd097          	auipc	ra,0xffffd
    80003a72:	22a080e7          	jalr	554(ra) # 80000c98 <release>
}
    80003a76:	854a                	mv	a0,s2
    80003a78:	70a2                	ld	ra,40(sp)
    80003a7a:	7402                	ld	s0,32(sp)
    80003a7c:	64e2                	ld	s1,24(sp)
    80003a7e:	6942                	ld	s2,16(sp)
    80003a80:	69a2                	ld	s3,8(sp)
    80003a82:	6a02                	ld	s4,0(sp)
    80003a84:	6145                	addi	sp,sp,48
    80003a86:	8082                	ret
    panic("iget: no inodes");
    80003a88:	00005517          	auipc	a0,0x5
    80003a8c:	b9850513          	addi	a0,a0,-1128 # 80008620 <syscalls+0x130>
    80003a90:	ffffd097          	auipc	ra,0xffffd
    80003a94:	aae080e7          	jalr	-1362(ra) # 8000053e <panic>

0000000080003a98 <fsinit>:
fsinit(int dev) {
    80003a98:	7179                	addi	sp,sp,-48
    80003a9a:	f406                	sd	ra,40(sp)
    80003a9c:	f022                	sd	s0,32(sp)
    80003a9e:	ec26                	sd	s1,24(sp)
    80003aa0:	e84a                	sd	s2,16(sp)
    80003aa2:	e44e                	sd	s3,8(sp)
    80003aa4:	1800                	addi	s0,sp,48
    80003aa6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003aa8:	4585                	li	a1,1
    80003aaa:	00000097          	auipc	ra,0x0
    80003aae:	a64080e7          	jalr	-1436(ra) # 8000350e <bread>
    80003ab2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003ab4:	0001d997          	auipc	s3,0x1d
    80003ab8:	83498993          	addi	s3,s3,-1996 # 800202e8 <sb>
    80003abc:	02000613          	li	a2,32
    80003ac0:	05850593          	addi	a1,a0,88
    80003ac4:	854e                	mv	a0,s3
    80003ac6:	ffffd097          	auipc	ra,0xffffd
    80003aca:	27a080e7          	jalr	634(ra) # 80000d40 <memmove>
  brelse(bp);
    80003ace:	8526                	mv	a0,s1
    80003ad0:	00000097          	auipc	ra,0x0
    80003ad4:	b6e080e7          	jalr	-1170(ra) # 8000363e <brelse>
  if(sb.magic != FSMAGIC)
    80003ad8:	0009a703          	lw	a4,0(s3)
    80003adc:	102037b7          	lui	a5,0x10203
    80003ae0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ae4:	02f71263          	bne	a4,a5,80003b08 <fsinit+0x70>
  initlog(dev, &sb);
    80003ae8:	0001d597          	auipc	a1,0x1d
    80003aec:	80058593          	addi	a1,a1,-2048 # 800202e8 <sb>
    80003af0:	854a                	mv	a0,s2
    80003af2:	00001097          	auipc	ra,0x1
    80003af6:	b4c080e7          	jalr	-1204(ra) # 8000463e <initlog>
}
    80003afa:	70a2                	ld	ra,40(sp)
    80003afc:	7402                	ld	s0,32(sp)
    80003afe:	64e2                	ld	s1,24(sp)
    80003b00:	6942                	ld	s2,16(sp)
    80003b02:	69a2                	ld	s3,8(sp)
    80003b04:	6145                	addi	sp,sp,48
    80003b06:	8082                	ret
    panic("invalid file system");
    80003b08:	00005517          	auipc	a0,0x5
    80003b0c:	b2850513          	addi	a0,a0,-1240 # 80008630 <syscalls+0x140>
    80003b10:	ffffd097          	auipc	ra,0xffffd
    80003b14:	a2e080e7          	jalr	-1490(ra) # 8000053e <panic>

0000000080003b18 <iinit>:
{
    80003b18:	7179                	addi	sp,sp,-48
    80003b1a:	f406                	sd	ra,40(sp)
    80003b1c:	f022                	sd	s0,32(sp)
    80003b1e:	ec26                	sd	s1,24(sp)
    80003b20:	e84a                	sd	s2,16(sp)
    80003b22:	e44e                	sd	s3,8(sp)
    80003b24:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b26:	00005597          	auipc	a1,0x5
    80003b2a:	b2258593          	addi	a1,a1,-1246 # 80008648 <syscalls+0x158>
    80003b2e:	0001c517          	auipc	a0,0x1c
    80003b32:	7da50513          	addi	a0,a0,2010 # 80020308 <itable>
    80003b36:	ffffd097          	auipc	ra,0xffffd
    80003b3a:	01e080e7          	jalr	30(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b3e:	0001c497          	auipc	s1,0x1c
    80003b42:	7f248493          	addi	s1,s1,2034 # 80020330 <itable+0x28>
    80003b46:	0001e997          	auipc	s3,0x1e
    80003b4a:	27a98993          	addi	s3,s3,634 # 80021dc0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b4e:	00005917          	auipc	s2,0x5
    80003b52:	b0290913          	addi	s2,s2,-1278 # 80008650 <syscalls+0x160>
    80003b56:	85ca                	mv	a1,s2
    80003b58:	8526                	mv	a0,s1
    80003b5a:	00001097          	auipc	ra,0x1
    80003b5e:	e46080e7          	jalr	-442(ra) # 800049a0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b62:	08848493          	addi	s1,s1,136
    80003b66:	ff3498e3          	bne	s1,s3,80003b56 <iinit+0x3e>
}
    80003b6a:	70a2                	ld	ra,40(sp)
    80003b6c:	7402                	ld	s0,32(sp)
    80003b6e:	64e2                	ld	s1,24(sp)
    80003b70:	6942                	ld	s2,16(sp)
    80003b72:	69a2                	ld	s3,8(sp)
    80003b74:	6145                	addi	sp,sp,48
    80003b76:	8082                	ret

0000000080003b78 <ialloc>:
{
    80003b78:	715d                	addi	sp,sp,-80
    80003b7a:	e486                	sd	ra,72(sp)
    80003b7c:	e0a2                	sd	s0,64(sp)
    80003b7e:	fc26                	sd	s1,56(sp)
    80003b80:	f84a                	sd	s2,48(sp)
    80003b82:	f44e                	sd	s3,40(sp)
    80003b84:	f052                	sd	s4,32(sp)
    80003b86:	ec56                	sd	s5,24(sp)
    80003b88:	e85a                	sd	s6,16(sp)
    80003b8a:	e45e                	sd	s7,8(sp)
    80003b8c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b8e:	0001c717          	auipc	a4,0x1c
    80003b92:	76672703          	lw	a4,1894(a4) # 800202f4 <sb+0xc>
    80003b96:	4785                	li	a5,1
    80003b98:	04e7fa63          	bgeu	a5,a4,80003bec <ialloc+0x74>
    80003b9c:	8aaa                	mv	s5,a0
    80003b9e:	8bae                	mv	s7,a1
    80003ba0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003ba2:	0001ca17          	auipc	s4,0x1c
    80003ba6:	746a0a13          	addi	s4,s4,1862 # 800202e8 <sb>
    80003baa:	00048b1b          	sext.w	s6,s1
    80003bae:	0044d593          	srli	a1,s1,0x4
    80003bb2:	018a2783          	lw	a5,24(s4)
    80003bb6:	9dbd                	addw	a1,a1,a5
    80003bb8:	8556                	mv	a0,s5
    80003bba:	00000097          	auipc	ra,0x0
    80003bbe:	954080e7          	jalr	-1708(ra) # 8000350e <bread>
    80003bc2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003bc4:	05850993          	addi	s3,a0,88
    80003bc8:	00f4f793          	andi	a5,s1,15
    80003bcc:	079a                	slli	a5,a5,0x6
    80003bce:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003bd0:	00099783          	lh	a5,0(s3)
    80003bd4:	c785                	beqz	a5,80003bfc <ialloc+0x84>
    brelse(bp);
    80003bd6:	00000097          	auipc	ra,0x0
    80003bda:	a68080e7          	jalr	-1432(ra) # 8000363e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bde:	0485                	addi	s1,s1,1
    80003be0:	00ca2703          	lw	a4,12(s4)
    80003be4:	0004879b          	sext.w	a5,s1
    80003be8:	fce7e1e3          	bltu	a5,a4,80003baa <ialloc+0x32>
  panic("ialloc: no inodes");
    80003bec:	00005517          	auipc	a0,0x5
    80003bf0:	a6c50513          	addi	a0,a0,-1428 # 80008658 <syscalls+0x168>
    80003bf4:	ffffd097          	auipc	ra,0xffffd
    80003bf8:	94a080e7          	jalr	-1718(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003bfc:	04000613          	li	a2,64
    80003c00:	4581                	li	a1,0
    80003c02:	854e                	mv	a0,s3
    80003c04:	ffffd097          	auipc	ra,0xffffd
    80003c08:	0dc080e7          	jalr	220(ra) # 80000ce0 <memset>
      dip->type = type;
    80003c0c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c10:	854a                	mv	a0,s2
    80003c12:	00001097          	auipc	ra,0x1
    80003c16:	ca8080e7          	jalr	-856(ra) # 800048ba <log_write>
      brelse(bp);
    80003c1a:	854a                	mv	a0,s2
    80003c1c:	00000097          	auipc	ra,0x0
    80003c20:	a22080e7          	jalr	-1502(ra) # 8000363e <brelse>
      return iget(dev, inum);
    80003c24:	85da                	mv	a1,s6
    80003c26:	8556                	mv	a0,s5
    80003c28:	00000097          	auipc	ra,0x0
    80003c2c:	db4080e7          	jalr	-588(ra) # 800039dc <iget>
}
    80003c30:	60a6                	ld	ra,72(sp)
    80003c32:	6406                	ld	s0,64(sp)
    80003c34:	74e2                	ld	s1,56(sp)
    80003c36:	7942                	ld	s2,48(sp)
    80003c38:	79a2                	ld	s3,40(sp)
    80003c3a:	7a02                	ld	s4,32(sp)
    80003c3c:	6ae2                	ld	s5,24(sp)
    80003c3e:	6b42                	ld	s6,16(sp)
    80003c40:	6ba2                	ld	s7,8(sp)
    80003c42:	6161                	addi	sp,sp,80
    80003c44:	8082                	ret

0000000080003c46 <iupdate>:
{
    80003c46:	1101                	addi	sp,sp,-32
    80003c48:	ec06                	sd	ra,24(sp)
    80003c4a:	e822                	sd	s0,16(sp)
    80003c4c:	e426                	sd	s1,8(sp)
    80003c4e:	e04a                	sd	s2,0(sp)
    80003c50:	1000                	addi	s0,sp,32
    80003c52:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c54:	415c                	lw	a5,4(a0)
    80003c56:	0047d79b          	srliw	a5,a5,0x4
    80003c5a:	0001c597          	auipc	a1,0x1c
    80003c5e:	6a65a583          	lw	a1,1702(a1) # 80020300 <sb+0x18>
    80003c62:	9dbd                	addw	a1,a1,a5
    80003c64:	4108                	lw	a0,0(a0)
    80003c66:	00000097          	auipc	ra,0x0
    80003c6a:	8a8080e7          	jalr	-1880(ra) # 8000350e <bread>
    80003c6e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c70:	05850793          	addi	a5,a0,88
    80003c74:	40c8                	lw	a0,4(s1)
    80003c76:	893d                	andi	a0,a0,15
    80003c78:	051a                	slli	a0,a0,0x6
    80003c7a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c7c:	04449703          	lh	a4,68(s1)
    80003c80:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003c84:	04649703          	lh	a4,70(s1)
    80003c88:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003c8c:	04849703          	lh	a4,72(s1)
    80003c90:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c94:	04a49703          	lh	a4,74(s1)
    80003c98:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c9c:	44f8                	lw	a4,76(s1)
    80003c9e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003ca0:	03400613          	li	a2,52
    80003ca4:	05048593          	addi	a1,s1,80
    80003ca8:	0531                	addi	a0,a0,12
    80003caa:	ffffd097          	auipc	ra,0xffffd
    80003cae:	096080e7          	jalr	150(ra) # 80000d40 <memmove>
  log_write(bp);
    80003cb2:	854a                	mv	a0,s2
    80003cb4:	00001097          	auipc	ra,0x1
    80003cb8:	c06080e7          	jalr	-1018(ra) # 800048ba <log_write>
  brelse(bp);
    80003cbc:	854a                	mv	a0,s2
    80003cbe:	00000097          	auipc	ra,0x0
    80003cc2:	980080e7          	jalr	-1664(ra) # 8000363e <brelse>
}
    80003cc6:	60e2                	ld	ra,24(sp)
    80003cc8:	6442                	ld	s0,16(sp)
    80003cca:	64a2                	ld	s1,8(sp)
    80003ccc:	6902                	ld	s2,0(sp)
    80003cce:	6105                	addi	sp,sp,32
    80003cd0:	8082                	ret

0000000080003cd2 <idup>:
{
    80003cd2:	1101                	addi	sp,sp,-32
    80003cd4:	ec06                	sd	ra,24(sp)
    80003cd6:	e822                	sd	s0,16(sp)
    80003cd8:	e426                	sd	s1,8(sp)
    80003cda:	1000                	addi	s0,sp,32
    80003cdc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cde:	0001c517          	auipc	a0,0x1c
    80003ce2:	62a50513          	addi	a0,a0,1578 # 80020308 <itable>
    80003ce6:	ffffd097          	auipc	ra,0xffffd
    80003cea:	efe080e7          	jalr	-258(ra) # 80000be4 <acquire>
  ip->ref++;
    80003cee:	449c                	lw	a5,8(s1)
    80003cf0:	2785                	addiw	a5,a5,1
    80003cf2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cf4:	0001c517          	auipc	a0,0x1c
    80003cf8:	61450513          	addi	a0,a0,1556 # 80020308 <itable>
    80003cfc:	ffffd097          	auipc	ra,0xffffd
    80003d00:	f9c080e7          	jalr	-100(ra) # 80000c98 <release>
}
    80003d04:	8526                	mv	a0,s1
    80003d06:	60e2                	ld	ra,24(sp)
    80003d08:	6442                	ld	s0,16(sp)
    80003d0a:	64a2                	ld	s1,8(sp)
    80003d0c:	6105                	addi	sp,sp,32
    80003d0e:	8082                	ret

0000000080003d10 <ilock>:
{
    80003d10:	1101                	addi	sp,sp,-32
    80003d12:	ec06                	sd	ra,24(sp)
    80003d14:	e822                	sd	s0,16(sp)
    80003d16:	e426                	sd	s1,8(sp)
    80003d18:	e04a                	sd	s2,0(sp)
    80003d1a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d1c:	c115                	beqz	a0,80003d40 <ilock+0x30>
    80003d1e:	84aa                	mv	s1,a0
    80003d20:	451c                	lw	a5,8(a0)
    80003d22:	00f05f63          	blez	a5,80003d40 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d26:	0541                	addi	a0,a0,16
    80003d28:	00001097          	auipc	ra,0x1
    80003d2c:	cb2080e7          	jalr	-846(ra) # 800049da <acquiresleep>
  if(ip->valid == 0){
    80003d30:	40bc                	lw	a5,64(s1)
    80003d32:	cf99                	beqz	a5,80003d50 <ilock+0x40>
}
    80003d34:	60e2                	ld	ra,24(sp)
    80003d36:	6442                	ld	s0,16(sp)
    80003d38:	64a2                	ld	s1,8(sp)
    80003d3a:	6902                	ld	s2,0(sp)
    80003d3c:	6105                	addi	sp,sp,32
    80003d3e:	8082                	ret
    panic("ilock");
    80003d40:	00005517          	auipc	a0,0x5
    80003d44:	93050513          	addi	a0,a0,-1744 # 80008670 <syscalls+0x180>
    80003d48:	ffffc097          	auipc	ra,0xffffc
    80003d4c:	7f6080e7          	jalr	2038(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d50:	40dc                	lw	a5,4(s1)
    80003d52:	0047d79b          	srliw	a5,a5,0x4
    80003d56:	0001c597          	auipc	a1,0x1c
    80003d5a:	5aa5a583          	lw	a1,1450(a1) # 80020300 <sb+0x18>
    80003d5e:	9dbd                	addw	a1,a1,a5
    80003d60:	4088                	lw	a0,0(s1)
    80003d62:	fffff097          	auipc	ra,0xfffff
    80003d66:	7ac080e7          	jalr	1964(ra) # 8000350e <bread>
    80003d6a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d6c:	05850593          	addi	a1,a0,88
    80003d70:	40dc                	lw	a5,4(s1)
    80003d72:	8bbd                	andi	a5,a5,15
    80003d74:	079a                	slli	a5,a5,0x6
    80003d76:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d78:	00059783          	lh	a5,0(a1)
    80003d7c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d80:	00259783          	lh	a5,2(a1)
    80003d84:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d88:	00459783          	lh	a5,4(a1)
    80003d8c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d90:	00659783          	lh	a5,6(a1)
    80003d94:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d98:	459c                	lw	a5,8(a1)
    80003d9a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d9c:	03400613          	li	a2,52
    80003da0:	05b1                	addi	a1,a1,12
    80003da2:	05048513          	addi	a0,s1,80
    80003da6:	ffffd097          	auipc	ra,0xffffd
    80003daa:	f9a080e7          	jalr	-102(ra) # 80000d40 <memmove>
    brelse(bp);
    80003dae:	854a                	mv	a0,s2
    80003db0:	00000097          	auipc	ra,0x0
    80003db4:	88e080e7          	jalr	-1906(ra) # 8000363e <brelse>
    ip->valid = 1;
    80003db8:	4785                	li	a5,1
    80003dba:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003dbc:	04449783          	lh	a5,68(s1)
    80003dc0:	fbb5                	bnez	a5,80003d34 <ilock+0x24>
      panic("ilock: no type");
    80003dc2:	00005517          	auipc	a0,0x5
    80003dc6:	8b650513          	addi	a0,a0,-1866 # 80008678 <syscalls+0x188>
    80003dca:	ffffc097          	auipc	ra,0xffffc
    80003dce:	774080e7          	jalr	1908(ra) # 8000053e <panic>

0000000080003dd2 <iunlock>:
{
    80003dd2:	1101                	addi	sp,sp,-32
    80003dd4:	ec06                	sd	ra,24(sp)
    80003dd6:	e822                	sd	s0,16(sp)
    80003dd8:	e426                	sd	s1,8(sp)
    80003dda:	e04a                	sd	s2,0(sp)
    80003ddc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003dde:	c905                	beqz	a0,80003e0e <iunlock+0x3c>
    80003de0:	84aa                	mv	s1,a0
    80003de2:	01050913          	addi	s2,a0,16
    80003de6:	854a                	mv	a0,s2
    80003de8:	00001097          	auipc	ra,0x1
    80003dec:	c8c080e7          	jalr	-884(ra) # 80004a74 <holdingsleep>
    80003df0:	cd19                	beqz	a0,80003e0e <iunlock+0x3c>
    80003df2:	449c                	lw	a5,8(s1)
    80003df4:	00f05d63          	blez	a5,80003e0e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003df8:	854a                	mv	a0,s2
    80003dfa:	00001097          	auipc	ra,0x1
    80003dfe:	c36080e7          	jalr	-970(ra) # 80004a30 <releasesleep>
}
    80003e02:	60e2                	ld	ra,24(sp)
    80003e04:	6442                	ld	s0,16(sp)
    80003e06:	64a2                	ld	s1,8(sp)
    80003e08:	6902                	ld	s2,0(sp)
    80003e0a:	6105                	addi	sp,sp,32
    80003e0c:	8082                	ret
    panic("iunlock");
    80003e0e:	00005517          	auipc	a0,0x5
    80003e12:	87a50513          	addi	a0,a0,-1926 # 80008688 <syscalls+0x198>
    80003e16:	ffffc097          	auipc	ra,0xffffc
    80003e1a:	728080e7          	jalr	1832(ra) # 8000053e <panic>

0000000080003e1e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e1e:	7179                	addi	sp,sp,-48
    80003e20:	f406                	sd	ra,40(sp)
    80003e22:	f022                	sd	s0,32(sp)
    80003e24:	ec26                	sd	s1,24(sp)
    80003e26:	e84a                	sd	s2,16(sp)
    80003e28:	e44e                	sd	s3,8(sp)
    80003e2a:	e052                	sd	s4,0(sp)
    80003e2c:	1800                	addi	s0,sp,48
    80003e2e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e30:	05050493          	addi	s1,a0,80
    80003e34:	08050913          	addi	s2,a0,128
    80003e38:	a021                	j	80003e40 <itrunc+0x22>
    80003e3a:	0491                	addi	s1,s1,4
    80003e3c:	01248d63          	beq	s1,s2,80003e56 <itrunc+0x38>
    if(ip->addrs[i]){
    80003e40:	408c                	lw	a1,0(s1)
    80003e42:	dde5                	beqz	a1,80003e3a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e44:	0009a503          	lw	a0,0(s3)
    80003e48:	00000097          	auipc	ra,0x0
    80003e4c:	90c080e7          	jalr	-1780(ra) # 80003754 <bfree>
      ip->addrs[i] = 0;
    80003e50:	0004a023          	sw	zero,0(s1)
    80003e54:	b7dd                	j	80003e3a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e56:	0809a583          	lw	a1,128(s3)
    80003e5a:	e185                	bnez	a1,80003e7a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e5c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e60:	854e                	mv	a0,s3
    80003e62:	00000097          	auipc	ra,0x0
    80003e66:	de4080e7          	jalr	-540(ra) # 80003c46 <iupdate>
}
    80003e6a:	70a2                	ld	ra,40(sp)
    80003e6c:	7402                	ld	s0,32(sp)
    80003e6e:	64e2                	ld	s1,24(sp)
    80003e70:	6942                	ld	s2,16(sp)
    80003e72:	69a2                	ld	s3,8(sp)
    80003e74:	6a02                	ld	s4,0(sp)
    80003e76:	6145                	addi	sp,sp,48
    80003e78:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e7a:	0009a503          	lw	a0,0(s3)
    80003e7e:	fffff097          	auipc	ra,0xfffff
    80003e82:	690080e7          	jalr	1680(ra) # 8000350e <bread>
    80003e86:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e88:	05850493          	addi	s1,a0,88
    80003e8c:	45850913          	addi	s2,a0,1112
    80003e90:	a811                	j	80003ea4 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003e92:	0009a503          	lw	a0,0(s3)
    80003e96:	00000097          	auipc	ra,0x0
    80003e9a:	8be080e7          	jalr	-1858(ra) # 80003754 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003e9e:	0491                	addi	s1,s1,4
    80003ea0:	01248563          	beq	s1,s2,80003eaa <itrunc+0x8c>
      if(a[j])
    80003ea4:	408c                	lw	a1,0(s1)
    80003ea6:	dde5                	beqz	a1,80003e9e <itrunc+0x80>
    80003ea8:	b7ed                	j	80003e92 <itrunc+0x74>
    brelse(bp);
    80003eaa:	8552                	mv	a0,s4
    80003eac:	fffff097          	auipc	ra,0xfffff
    80003eb0:	792080e7          	jalr	1938(ra) # 8000363e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003eb4:	0809a583          	lw	a1,128(s3)
    80003eb8:	0009a503          	lw	a0,0(s3)
    80003ebc:	00000097          	auipc	ra,0x0
    80003ec0:	898080e7          	jalr	-1896(ra) # 80003754 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ec4:	0809a023          	sw	zero,128(s3)
    80003ec8:	bf51                	j	80003e5c <itrunc+0x3e>

0000000080003eca <iput>:
{
    80003eca:	1101                	addi	sp,sp,-32
    80003ecc:	ec06                	sd	ra,24(sp)
    80003ece:	e822                	sd	s0,16(sp)
    80003ed0:	e426                	sd	s1,8(sp)
    80003ed2:	e04a                	sd	s2,0(sp)
    80003ed4:	1000                	addi	s0,sp,32
    80003ed6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ed8:	0001c517          	auipc	a0,0x1c
    80003edc:	43050513          	addi	a0,a0,1072 # 80020308 <itable>
    80003ee0:	ffffd097          	auipc	ra,0xffffd
    80003ee4:	d04080e7          	jalr	-764(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ee8:	4498                	lw	a4,8(s1)
    80003eea:	4785                	li	a5,1
    80003eec:	02f70363          	beq	a4,a5,80003f12 <iput+0x48>
  ip->ref--;
    80003ef0:	449c                	lw	a5,8(s1)
    80003ef2:	37fd                	addiw	a5,a5,-1
    80003ef4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ef6:	0001c517          	auipc	a0,0x1c
    80003efa:	41250513          	addi	a0,a0,1042 # 80020308 <itable>
    80003efe:	ffffd097          	auipc	ra,0xffffd
    80003f02:	d9a080e7          	jalr	-614(ra) # 80000c98 <release>
}
    80003f06:	60e2                	ld	ra,24(sp)
    80003f08:	6442                	ld	s0,16(sp)
    80003f0a:	64a2                	ld	s1,8(sp)
    80003f0c:	6902                	ld	s2,0(sp)
    80003f0e:	6105                	addi	sp,sp,32
    80003f10:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f12:	40bc                	lw	a5,64(s1)
    80003f14:	dff1                	beqz	a5,80003ef0 <iput+0x26>
    80003f16:	04a49783          	lh	a5,74(s1)
    80003f1a:	fbf9                	bnez	a5,80003ef0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003f1c:	01048913          	addi	s2,s1,16
    80003f20:	854a                	mv	a0,s2
    80003f22:	00001097          	auipc	ra,0x1
    80003f26:	ab8080e7          	jalr	-1352(ra) # 800049da <acquiresleep>
    release(&itable.lock);
    80003f2a:	0001c517          	auipc	a0,0x1c
    80003f2e:	3de50513          	addi	a0,a0,990 # 80020308 <itable>
    80003f32:	ffffd097          	auipc	ra,0xffffd
    80003f36:	d66080e7          	jalr	-666(ra) # 80000c98 <release>
    itrunc(ip);
    80003f3a:	8526                	mv	a0,s1
    80003f3c:	00000097          	auipc	ra,0x0
    80003f40:	ee2080e7          	jalr	-286(ra) # 80003e1e <itrunc>
    ip->type = 0;
    80003f44:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f48:	8526                	mv	a0,s1
    80003f4a:	00000097          	auipc	ra,0x0
    80003f4e:	cfc080e7          	jalr	-772(ra) # 80003c46 <iupdate>
    ip->valid = 0;
    80003f52:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f56:	854a                	mv	a0,s2
    80003f58:	00001097          	auipc	ra,0x1
    80003f5c:	ad8080e7          	jalr	-1320(ra) # 80004a30 <releasesleep>
    acquire(&itable.lock);
    80003f60:	0001c517          	auipc	a0,0x1c
    80003f64:	3a850513          	addi	a0,a0,936 # 80020308 <itable>
    80003f68:	ffffd097          	auipc	ra,0xffffd
    80003f6c:	c7c080e7          	jalr	-900(ra) # 80000be4 <acquire>
    80003f70:	b741                	j	80003ef0 <iput+0x26>

0000000080003f72 <iunlockput>:
{
    80003f72:	1101                	addi	sp,sp,-32
    80003f74:	ec06                	sd	ra,24(sp)
    80003f76:	e822                	sd	s0,16(sp)
    80003f78:	e426                	sd	s1,8(sp)
    80003f7a:	1000                	addi	s0,sp,32
    80003f7c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f7e:	00000097          	auipc	ra,0x0
    80003f82:	e54080e7          	jalr	-428(ra) # 80003dd2 <iunlock>
  iput(ip);
    80003f86:	8526                	mv	a0,s1
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	f42080e7          	jalr	-190(ra) # 80003eca <iput>
}
    80003f90:	60e2                	ld	ra,24(sp)
    80003f92:	6442                	ld	s0,16(sp)
    80003f94:	64a2                	ld	s1,8(sp)
    80003f96:	6105                	addi	sp,sp,32
    80003f98:	8082                	ret

0000000080003f9a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f9a:	1141                	addi	sp,sp,-16
    80003f9c:	e422                	sd	s0,8(sp)
    80003f9e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003fa0:	411c                	lw	a5,0(a0)
    80003fa2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003fa4:	415c                	lw	a5,4(a0)
    80003fa6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003fa8:	04451783          	lh	a5,68(a0)
    80003fac:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003fb0:	04a51783          	lh	a5,74(a0)
    80003fb4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003fb8:	04c56783          	lwu	a5,76(a0)
    80003fbc:	e99c                	sd	a5,16(a1)
}
    80003fbe:	6422                	ld	s0,8(sp)
    80003fc0:	0141                	addi	sp,sp,16
    80003fc2:	8082                	ret

0000000080003fc4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fc4:	457c                	lw	a5,76(a0)
    80003fc6:	0ed7e963          	bltu	a5,a3,800040b8 <readi+0xf4>
{
    80003fca:	7159                	addi	sp,sp,-112
    80003fcc:	f486                	sd	ra,104(sp)
    80003fce:	f0a2                	sd	s0,96(sp)
    80003fd0:	eca6                	sd	s1,88(sp)
    80003fd2:	e8ca                	sd	s2,80(sp)
    80003fd4:	e4ce                	sd	s3,72(sp)
    80003fd6:	e0d2                	sd	s4,64(sp)
    80003fd8:	fc56                	sd	s5,56(sp)
    80003fda:	f85a                	sd	s6,48(sp)
    80003fdc:	f45e                	sd	s7,40(sp)
    80003fde:	f062                	sd	s8,32(sp)
    80003fe0:	ec66                	sd	s9,24(sp)
    80003fe2:	e86a                	sd	s10,16(sp)
    80003fe4:	e46e                	sd	s11,8(sp)
    80003fe6:	1880                	addi	s0,sp,112
    80003fe8:	8baa                	mv	s7,a0
    80003fea:	8c2e                	mv	s8,a1
    80003fec:	8ab2                	mv	s5,a2
    80003fee:	84b6                	mv	s1,a3
    80003ff0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ff2:	9f35                	addw	a4,a4,a3
    return 0;
    80003ff4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ff6:	0ad76063          	bltu	a4,a3,80004096 <readi+0xd2>
  if(off + n > ip->size)
    80003ffa:	00e7f463          	bgeu	a5,a4,80004002 <readi+0x3e>
    n = ip->size - off;
    80003ffe:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004002:	0a0b0963          	beqz	s6,800040b4 <readi+0xf0>
    80004006:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004008:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000400c:	5cfd                	li	s9,-1
    8000400e:	a82d                	j	80004048 <readi+0x84>
    80004010:	020a1d93          	slli	s11,s4,0x20
    80004014:	020ddd93          	srli	s11,s11,0x20
    80004018:	05890613          	addi	a2,s2,88
    8000401c:	86ee                	mv	a3,s11
    8000401e:	963a                	add	a2,a2,a4
    80004020:	85d6                	mv	a1,s5
    80004022:	8562                	mv	a0,s8
    80004024:	fffff097          	auipc	ra,0xfffff
    80004028:	a42080e7          	jalr	-1470(ra) # 80002a66 <either_copyout>
    8000402c:	05950d63          	beq	a0,s9,80004086 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004030:	854a                	mv	a0,s2
    80004032:	fffff097          	auipc	ra,0xfffff
    80004036:	60c080e7          	jalr	1548(ra) # 8000363e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000403a:	013a09bb          	addw	s3,s4,s3
    8000403e:	009a04bb          	addw	s1,s4,s1
    80004042:	9aee                	add	s5,s5,s11
    80004044:	0569f763          	bgeu	s3,s6,80004092 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004048:	000ba903          	lw	s2,0(s7)
    8000404c:	00a4d59b          	srliw	a1,s1,0xa
    80004050:	855e                	mv	a0,s7
    80004052:	00000097          	auipc	ra,0x0
    80004056:	8b0080e7          	jalr	-1872(ra) # 80003902 <bmap>
    8000405a:	0005059b          	sext.w	a1,a0
    8000405e:	854a                	mv	a0,s2
    80004060:	fffff097          	auipc	ra,0xfffff
    80004064:	4ae080e7          	jalr	1198(ra) # 8000350e <bread>
    80004068:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000406a:	3ff4f713          	andi	a4,s1,1023
    8000406e:	40ed07bb          	subw	a5,s10,a4
    80004072:	413b06bb          	subw	a3,s6,s3
    80004076:	8a3e                	mv	s4,a5
    80004078:	2781                	sext.w	a5,a5
    8000407a:	0006861b          	sext.w	a2,a3
    8000407e:	f8f679e3          	bgeu	a2,a5,80004010 <readi+0x4c>
    80004082:	8a36                	mv	s4,a3
    80004084:	b771                	j	80004010 <readi+0x4c>
      brelse(bp);
    80004086:	854a                	mv	a0,s2
    80004088:	fffff097          	auipc	ra,0xfffff
    8000408c:	5b6080e7          	jalr	1462(ra) # 8000363e <brelse>
      tot = -1;
    80004090:	59fd                	li	s3,-1
  }
  return tot;
    80004092:	0009851b          	sext.w	a0,s3
}
    80004096:	70a6                	ld	ra,104(sp)
    80004098:	7406                	ld	s0,96(sp)
    8000409a:	64e6                	ld	s1,88(sp)
    8000409c:	6946                	ld	s2,80(sp)
    8000409e:	69a6                	ld	s3,72(sp)
    800040a0:	6a06                	ld	s4,64(sp)
    800040a2:	7ae2                	ld	s5,56(sp)
    800040a4:	7b42                	ld	s6,48(sp)
    800040a6:	7ba2                	ld	s7,40(sp)
    800040a8:	7c02                	ld	s8,32(sp)
    800040aa:	6ce2                	ld	s9,24(sp)
    800040ac:	6d42                	ld	s10,16(sp)
    800040ae:	6da2                	ld	s11,8(sp)
    800040b0:	6165                	addi	sp,sp,112
    800040b2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040b4:	89da                	mv	s3,s6
    800040b6:	bff1                	j	80004092 <readi+0xce>
    return 0;
    800040b8:	4501                	li	a0,0
}
    800040ba:	8082                	ret

00000000800040bc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040bc:	457c                	lw	a5,76(a0)
    800040be:	10d7e863          	bltu	a5,a3,800041ce <writei+0x112>
{
    800040c2:	7159                	addi	sp,sp,-112
    800040c4:	f486                	sd	ra,104(sp)
    800040c6:	f0a2                	sd	s0,96(sp)
    800040c8:	eca6                	sd	s1,88(sp)
    800040ca:	e8ca                	sd	s2,80(sp)
    800040cc:	e4ce                	sd	s3,72(sp)
    800040ce:	e0d2                	sd	s4,64(sp)
    800040d0:	fc56                	sd	s5,56(sp)
    800040d2:	f85a                	sd	s6,48(sp)
    800040d4:	f45e                	sd	s7,40(sp)
    800040d6:	f062                	sd	s8,32(sp)
    800040d8:	ec66                	sd	s9,24(sp)
    800040da:	e86a                	sd	s10,16(sp)
    800040dc:	e46e                	sd	s11,8(sp)
    800040de:	1880                	addi	s0,sp,112
    800040e0:	8b2a                	mv	s6,a0
    800040e2:	8c2e                	mv	s8,a1
    800040e4:	8ab2                	mv	s5,a2
    800040e6:	8936                	mv	s2,a3
    800040e8:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800040ea:	00e687bb          	addw	a5,a3,a4
    800040ee:	0ed7e263          	bltu	a5,a3,800041d2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800040f2:	00043737          	lui	a4,0x43
    800040f6:	0ef76063          	bltu	a4,a5,800041d6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040fa:	0c0b8863          	beqz	s7,800041ca <writei+0x10e>
    800040fe:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004100:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004104:	5cfd                	li	s9,-1
    80004106:	a091                	j	8000414a <writei+0x8e>
    80004108:	02099d93          	slli	s11,s3,0x20
    8000410c:	020ddd93          	srli	s11,s11,0x20
    80004110:	05848513          	addi	a0,s1,88
    80004114:	86ee                	mv	a3,s11
    80004116:	8656                	mv	a2,s5
    80004118:	85e2                	mv	a1,s8
    8000411a:	953a                	add	a0,a0,a4
    8000411c:	fffff097          	auipc	ra,0xfffff
    80004120:	9a0080e7          	jalr	-1632(ra) # 80002abc <either_copyin>
    80004124:	07950263          	beq	a0,s9,80004188 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004128:	8526                	mv	a0,s1
    8000412a:	00000097          	auipc	ra,0x0
    8000412e:	790080e7          	jalr	1936(ra) # 800048ba <log_write>
    brelse(bp);
    80004132:	8526                	mv	a0,s1
    80004134:	fffff097          	auipc	ra,0xfffff
    80004138:	50a080e7          	jalr	1290(ra) # 8000363e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000413c:	01498a3b          	addw	s4,s3,s4
    80004140:	0129893b          	addw	s2,s3,s2
    80004144:	9aee                	add	s5,s5,s11
    80004146:	057a7663          	bgeu	s4,s7,80004192 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000414a:	000b2483          	lw	s1,0(s6)
    8000414e:	00a9559b          	srliw	a1,s2,0xa
    80004152:	855a                	mv	a0,s6
    80004154:	fffff097          	auipc	ra,0xfffff
    80004158:	7ae080e7          	jalr	1966(ra) # 80003902 <bmap>
    8000415c:	0005059b          	sext.w	a1,a0
    80004160:	8526                	mv	a0,s1
    80004162:	fffff097          	auipc	ra,0xfffff
    80004166:	3ac080e7          	jalr	940(ra) # 8000350e <bread>
    8000416a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000416c:	3ff97713          	andi	a4,s2,1023
    80004170:	40ed07bb          	subw	a5,s10,a4
    80004174:	414b86bb          	subw	a3,s7,s4
    80004178:	89be                	mv	s3,a5
    8000417a:	2781                	sext.w	a5,a5
    8000417c:	0006861b          	sext.w	a2,a3
    80004180:	f8f674e3          	bgeu	a2,a5,80004108 <writei+0x4c>
    80004184:	89b6                	mv	s3,a3
    80004186:	b749                	j	80004108 <writei+0x4c>
      brelse(bp);
    80004188:	8526                	mv	a0,s1
    8000418a:	fffff097          	auipc	ra,0xfffff
    8000418e:	4b4080e7          	jalr	1204(ra) # 8000363e <brelse>
  }

  if(off > ip->size)
    80004192:	04cb2783          	lw	a5,76(s6)
    80004196:	0127f463          	bgeu	a5,s2,8000419e <writei+0xe2>
    ip->size = off;
    8000419a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000419e:	855a                	mv	a0,s6
    800041a0:	00000097          	auipc	ra,0x0
    800041a4:	aa6080e7          	jalr	-1370(ra) # 80003c46 <iupdate>

  return tot;
    800041a8:	000a051b          	sext.w	a0,s4
}
    800041ac:	70a6                	ld	ra,104(sp)
    800041ae:	7406                	ld	s0,96(sp)
    800041b0:	64e6                	ld	s1,88(sp)
    800041b2:	6946                	ld	s2,80(sp)
    800041b4:	69a6                	ld	s3,72(sp)
    800041b6:	6a06                	ld	s4,64(sp)
    800041b8:	7ae2                	ld	s5,56(sp)
    800041ba:	7b42                	ld	s6,48(sp)
    800041bc:	7ba2                	ld	s7,40(sp)
    800041be:	7c02                	ld	s8,32(sp)
    800041c0:	6ce2                	ld	s9,24(sp)
    800041c2:	6d42                	ld	s10,16(sp)
    800041c4:	6da2                	ld	s11,8(sp)
    800041c6:	6165                	addi	sp,sp,112
    800041c8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041ca:	8a5e                	mv	s4,s7
    800041cc:	bfc9                	j	8000419e <writei+0xe2>
    return -1;
    800041ce:	557d                	li	a0,-1
}
    800041d0:	8082                	ret
    return -1;
    800041d2:	557d                	li	a0,-1
    800041d4:	bfe1                	j	800041ac <writei+0xf0>
    return -1;
    800041d6:	557d                	li	a0,-1
    800041d8:	bfd1                	j	800041ac <writei+0xf0>

00000000800041da <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041da:	1141                	addi	sp,sp,-16
    800041dc:	e406                	sd	ra,8(sp)
    800041de:	e022                	sd	s0,0(sp)
    800041e0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800041e2:	4639                	li	a2,14
    800041e4:	ffffd097          	auipc	ra,0xffffd
    800041e8:	bd4080e7          	jalr	-1068(ra) # 80000db8 <strncmp>
}
    800041ec:	60a2                	ld	ra,8(sp)
    800041ee:	6402                	ld	s0,0(sp)
    800041f0:	0141                	addi	sp,sp,16
    800041f2:	8082                	ret

00000000800041f4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800041f4:	7139                	addi	sp,sp,-64
    800041f6:	fc06                	sd	ra,56(sp)
    800041f8:	f822                	sd	s0,48(sp)
    800041fa:	f426                	sd	s1,40(sp)
    800041fc:	f04a                	sd	s2,32(sp)
    800041fe:	ec4e                	sd	s3,24(sp)
    80004200:	e852                	sd	s4,16(sp)
    80004202:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004204:	04451703          	lh	a4,68(a0)
    80004208:	4785                	li	a5,1
    8000420a:	00f71a63          	bne	a4,a5,8000421e <dirlookup+0x2a>
    8000420e:	892a                	mv	s2,a0
    80004210:	89ae                	mv	s3,a1
    80004212:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004214:	457c                	lw	a5,76(a0)
    80004216:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004218:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000421a:	e79d                	bnez	a5,80004248 <dirlookup+0x54>
    8000421c:	a8a5                	j	80004294 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000421e:	00004517          	auipc	a0,0x4
    80004222:	47250513          	addi	a0,a0,1138 # 80008690 <syscalls+0x1a0>
    80004226:	ffffc097          	auipc	ra,0xffffc
    8000422a:	318080e7          	jalr	792(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000422e:	00004517          	auipc	a0,0x4
    80004232:	47a50513          	addi	a0,a0,1146 # 800086a8 <syscalls+0x1b8>
    80004236:	ffffc097          	auipc	ra,0xffffc
    8000423a:	308080e7          	jalr	776(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000423e:	24c1                	addiw	s1,s1,16
    80004240:	04c92783          	lw	a5,76(s2)
    80004244:	04f4f763          	bgeu	s1,a5,80004292 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004248:	4741                	li	a4,16
    8000424a:	86a6                	mv	a3,s1
    8000424c:	fc040613          	addi	a2,s0,-64
    80004250:	4581                	li	a1,0
    80004252:	854a                	mv	a0,s2
    80004254:	00000097          	auipc	ra,0x0
    80004258:	d70080e7          	jalr	-656(ra) # 80003fc4 <readi>
    8000425c:	47c1                	li	a5,16
    8000425e:	fcf518e3          	bne	a0,a5,8000422e <dirlookup+0x3a>
    if(de.inum == 0)
    80004262:	fc045783          	lhu	a5,-64(s0)
    80004266:	dfe1                	beqz	a5,8000423e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004268:	fc240593          	addi	a1,s0,-62
    8000426c:	854e                	mv	a0,s3
    8000426e:	00000097          	auipc	ra,0x0
    80004272:	f6c080e7          	jalr	-148(ra) # 800041da <namecmp>
    80004276:	f561                	bnez	a0,8000423e <dirlookup+0x4a>
      if(poff)
    80004278:	000a0463          	beqz	s4,80004280 <dirlookup+0x8c>
        *poff = off;
    8000427c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004280:	fc045583          	lhu	a1,-64(s0)
    80004284:	00092503          	lw	a0,0(s2)
    80004288:	fffff097          	auipc	ra,0xfffff
    8000428c:	754080e7          	jalr	1876(ra) # 800039dc <iget>
    80004290:	a011                	j	80004294 <dirlookup+0xa0>
  return 0;
    80004292:	4501                	li	a0,0
}
    80004294:	70e2                	ld	ra,56(sp)
    80004296:	7442                	ld	s0,48(sp)
    80004298:	74a2                	ld	s1,40(sp)
    8000429a:	7902                	ld	s2,32(sp)
    8000429c:	69e2                	ld	s3,24(sp)
    8000429e:	6a42                	ld	s4,16(sp)
    800042a0:	6121                	addi	sp,sp,64
    800042a2:	8082                	ret

00000000800042a4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800042a4:	711d                	addi	sp,sp,-96
    800042a6:	ec86                	sd	ra,88(sp)
    800042a8:	e8a2                	sd	s0,80(sp)
    800042aa:	e4a6                	sd	s1,72(sp)
    800042ac:	e0ca                	sd	s2,64(sp)
    800042ae:	fc4e                	sd	s3,56(sp)
    800042b0:	f852                	sd	s4,48(sp)
    800042b2:	f456                	sd	s5,40(sp)
    800042b4:	f05a                	sd	s6,32(sp)
    800042b6:	ec5e                	sd	s7,24(sp)
    800042b8:	e862                	sd	s8,16(sp)
    800042ba:	e466                	sd	s9,8(sp)
    800042bc:	1080                	addi	s0,sp,96
    800042be:	84aa                	mv	s1,a0
    800042c0:	8b2e                	mv	s6,a1
    800042c2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800042c4:	00054703          	lbu	a4,0(a0)
    800042c8:	02f00793          	li	a5,47
    800042cc:	02f70363          	beq	a4,a5,800042f2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042d0:	ffffe097          	auipc	ra,0xffffe
    800042d4:	b44080e7          	jalr	-1212(ra) # 80001e14 <myproc>
    800042d8:	15053503          	ld	a0,336(a0)
    800042dc:	00000097          	auipc	ra,0x0
    800042e0:	9f6080e7          	jalr	-1546(ra) # 80003cd2 <idup>
    800042e4:	89aa                	mv	s3,a0
  while(*path == '/')
    800042e6:	02f00913          	li	s2,47
  len = path - s;
    800042ea:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800042ec:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800042ee:	4c05                	li	s8,1
    800042f0:	a865                	j	800043a8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800042f2:	4585                	li	a1,1
    800042f4:	4505                	li	a0,1
    800042f6:	fffff097          	auipc	ra,0xfffff
    800042fa:	6e6080e7          	jalr	1766(ra) # 800039dc <iget>
    800042fe:	89aa                	mv	s3,a0
    80004300:	b7dd                	j	800042e6 <namex+0x42>
      iunlockput(ip);
    80004302:	854e                	mv	a0,s3
    80004304:	00000097          	auipc	ra,0x0
    80004308:	c6e080e7          	jalr	-914(ra) # 80003f72 <iunlockput>
      return 0;
    8000430c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000430e:	854e                	mv	a0,s3
    80004310:	60e6                	ld	ra,88(sp)
    80004312:	6446                	ld	s0,80(sp)
    80004314:	64a6                	ld	s1,72(sp)
    80004316:	6906                	ld	s2,64(sp)
    80004318:	79e2                	ld	s3,56(sp)
    8000431a:	7a42                	ld	s4,48(sp)
    8000431c:	7aa2                	ld	s5,40(sp)
    8000431e:	7b02                	ld	s6,32(sp)
    80004320:	6be2                	ld	s7,24(sp)
    80004322:	6c42                	ld	s8,16(sp)
    80004324:	6ca2                	ld	s9,8(sp)
    80004326:	6125                	addi	sp,sp,96
    80004328:	8082                	ret
      iunlock(ip);
    8000432a:	854e                	mv	a0,s3
    8000432c:	00000097          	auipc	ra,0x0
    80004330:	aa6080e7          	jalr	-1370(ra) # 80003dd2 <iunlock>
      return ip;
    80004334:	bfe9                	j	8000430e <namex+0x6a>
      iunlockput(ip);
    80004336:	854e                	mv	a0,s3
    80004338:	00000097          	auipc	ra,0x0
    8000433c:	c3a080e7          	jalr	-966(ra) # 80003f72 <iunlockput>
      return 0;
    80004340:	89d2                	mv	s3,s4
    80004342:	b7f1                	j	8000430e <namex+0x6a>
  len = path - s;
    80004344:	40b48633          	sub	a2,s1,a1
    80004348:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000434c:	094cd463          	bge	s9,s4,800043d4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004350:	4639                	li	a2,14
    80004352:	8556                	mv	a0,s5
    80004354:	ffffd097          	auipc	ra,0xffffd
    80004358:	9ec080e7          	jalr	-1556(ra) # 80000d40 <memmove>
  while(*path == '/')
    8000435c:	0004c783          	lbu	a5,0(s1)
    80004360:	01279763          	bne	a5,s2,8000436e <namex+0xca>
    path++;
    80004364:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004366:	0004c783          	lbu	a5,0(s1)
    8000436a:	ff278de3          	beq	a5,s2,80004364 <namex+0xc0>
    ilock(ip);
    8000436e:	854e                	mv	a0,s3
    80004370:	00000097          	auipc	ra,0x0
    80004374:	9a0080e7          	jalr	-1632(ra) # 80003d10 <ilock>
    if(ip->type != T_DIR){
    80004378:	04499783          	lh	a5,68(s3)
    8000437c:	f98793e3          	bne	a5,s8,80004302 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004380:	000b0563          	beqz	s6,8000438a <namex+0xe6>
    80004384:	0004c783          	lbu	a5,0(s1)
    80004388:	d3cd                	beqz	a5,8000432a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000438a:	865e                	mv	a2,s7
    8000438c:	85d6                	mv	a1,s5
    8000438e:	854e                	mv	a0,s3
    80004390:	00000097          	auipc	ra,0x0
    80004394:	e64080e7          	jalr	-412(ra) # 800041f4 <dirlookup>
    80004398:	8a2a                	mv	s4,a0
    8000439a:	dd51                	beqz	a0,80004336 <namex+0x92>
    iunlockput(ip);
    8000439c:	854e                	mv	a0,s3
    8000439e:	00000097          	auipc	ra,0x0
    800043a2:	bd4080e7          	jalr	-1068(ra) # 80003f72 <iunlockput>
    ip = next;
    800043a6:	89d2                	mv	s3,s4
  while(*path == '/')
    800043a8:	0004c783          	lbu	a5,0(s1)
    800043ac:	05279763          	bne	a5,s2,800043fa <namex+0x156>
    path++;
    800043b0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043b2:	0004c783          	lbu	a5,0(s1)
    800043b6:	ff278de3          	beq	a5,s2,800043b0 <namex+0x10c>
  if(*path == 0)
    800043ba:	c79d                	beqz	a5,800043e8 <namex+0x144>
    path++;
    800043bc:	85a6                	mv	a1,s1
  len = path - s;
    800043be:	8a5e                	mv	s4,s7
    800043c0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800043c2:	01278963          	beq	a5,s2,800043d4 <namex+0x130>
    800043c6:	dfbd                	beqz	a5,80004344 <namex+0xa0>
    path++;
    800043c8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800043ca:	0004c783          	lbu	a5,0(s1)
    800043ce:	ff279ce3          	bne	a5,s2,800043c6 <namex+0x122>
    800043d2:	bf8d                	j	80004344 <namex+0xa0>
    memmove(name, s, len);
    800043d4:	2601                	sext.w	a2,a2
    800043d6:	8556                	mv	a0,s5
    800043d8:	ffffd097          	auipc	ra,0xffffd
    800043dc:	968080e7          	jalr	-1688(ra) # 80000d40 <memmove>
    name[len] = 0;
    800043e0:	9a56                	add	s4,s4,s5
    800043e2:	000a0023          	sb	zero,0(s4)
    800043e6:	bf9d                	j	8000435c <namex+0xb8>
  if(nameiparent){
    800043e8:	f20b03e3          	beqz	s6,8000430e <namex+0x6a>
    iput(ip);
    800043ec:	854e                	mv	a0,s3
    800043ee:	00000097          	auipc	ra,0x0
    800043f2:	adc080e7          	jalr	-1316(ra) # 80003eca <iput>
    return 0;
    800043f6:	4981                	li	s3,0
    800043f8:	bf19                	j	8000430e <namex+0x6a>
  if(*path == 0)
    800043fa:	d7fd                	beqz	a5,800043e8 <namex+0x144>
  while(*path != '/' && *path != 0)
    800043fc:	0004c783          	lbu	a5,0(s1)
    80004400:	85a6                	mv	a1,s1
    80004402:	b7d1                	j	800043c6 <namex+0x122>

0000000080004404 <dirlink>:
{
    80004404:	7139                	addi	sp,sp,-64
    80004406:	fc06                	sd	ra,56(sp)
    80004408:	f822                	sd	s0,48(sp)
    8000440a:	f426                	sd	s1,40(sp)
    8000440c:	f04a                	sd	s2,32(sp)
    8000440e:	ec4e                	sd	s3,24(sp)
    80004410:	e852                	sd	s4,16(sp)
    80004412:	0080                	addi	s0,sp,64
    80004414:	892a                	mv	s2,a0
    80004416:	8a2e                	mv	s4,a1
    80004418:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000441a:	4601                	li	a2,0
    8000441c:	00000097          	auipc	ra,0x0
    80004420:	dd8080e7          	jalr	-552(ra) # 800041f4 <dirlookup>
    80004424:	e93d                	bnez	a0,8000449a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004426:	04c92483          	lw	s1,76(s2)
    8000442a:	c49d                	beqz	s1,80004458 <dirlink+0x54>
    8000442c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000442e:	4741                	li	a4,16
    80004430:	86a6                	mv	a3,s1
    80004432:	fc040613          	addi	a2,s0,-64
    80004436:	4581                	li	a1,0
    80004438:	854a                	mv	a0,s2
    8000443a:	00000097          	auipc	ra,0x0
    8000443e:	b8a080e7          	jalr	-1142(ra) # 80003fc4 <readi>
    80004442:	47c1                	li	a5,16
    80004444:	06f51163          	bne	a0,a5,800044a6 <dirlink+0xa2>
    if(de.inum == 0)
    80004448:	fc045783          	lhu	a5,-64(s0)
    8000444c:	c791                	beqz	a5,80004458 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000444e:	24c1                	addiw	s1,s1,16
    80004450:	04c92783          	lw	a5,76(s2)
    80004454:	fcf4ede3          	bltu	s1,a5,8000442e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004458:	4639                	li	a2,14
    8000445a:	85d2                	mv	a1,s4
    8000445c:	fc240513          	addi	a0,s0,-62
    80004460:	ffffd097          	auipc	ra,0xffffd
    80004464:	994080e7          	jalr	-1644(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004468:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000446c:	4741                	li	a4,16
    8000446e:	86a6                	mv	a3,s1
    80004470:	fc040613          	addi	a2,s0,-64
    80004474:	4581                	li	a1,0
    80004476:	854a                	mv	a0,s2
    80004478:	00000097          	auipc	ra,0x0
    8000447c:	c44080e7          	jalr	-956(ra) # 800040bc <writei>
    80004480:	872a                	mv	a4,a0
    80004482:	47c1                	li	a5,16
  return 0;
    80004484:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004486:	02f71863          	bne	a4,a5,800044b6 <dirlink+0xb2>
}
    8000448a:	70e2                	ld	ra,56(sp)
    8000448c:	7442                	ld	s0,48(sp)
    8000448e:	74a2                	ld	s1,40(sp)
    80004490:	7902                	ld	s2,32(sp)
    80004492:	69e2                	ld	s3,24(sp)
    80004494:	6a42                	ld	s4,16(sp)
    80004496:	6121                	addi	sp,sp,64
    80004498:	8082                	ret
    iput(ip);
    8000449a:	00000097          	auipc	ra,0x0
    8000449e:	a30080e7          	jalr	-1488(ra) # 80003eca <iput>
    return -1;
    800044a2:	557d                	li	a0,-1
    800044a4:	b7dd                	j	8000448a <dirlink+0x86>
      panic("dirlink read");
    800044a6:	00004517          	auipc	a0,0x4
    800044aa:	21250513          	addi	a0,a0,530 # 800086b8 <syscalls+0x1c8>
    800044ae:	ffffc097          	auipc	ra,0xffffc
    800044b2:	090080e7          	jalr	144(ra) # 8000053e <panic>
    panic("dirlink");
    800044b6:	00004517          	auipc	a0,0x4
    800044ba:	31250513          	addi	a0,a0,786 # 800087c8 <syscalls+0x2d8>
    800044be:	ffffc097          	auipc	ra,0xffffc
    800044c2:	080080e7          	jalr	128(ra) # 8000053e <panic>

00000000800044c6 <namei>:

struct inode*
namei(char *path)
{
    800044c6:	1101                	addi	sp,sp,-32
    800044c8:	ec06                	sd	ra,24(sp)
    800044ca:	e822                	sd	s0,16(sp)
    800044cc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800044ce:	fe040613          	addi	a2,s0,-32
    800044d2:	4581                	li	a1,0
    800044d4:	00000097          	auipc	ra,0x0
    800044d8:	dd0080e7          	jalr	-560(ra) # 800042a4 <namex>
}
    800044dc:	60e2                	ld	ra,24(sp)
    800044de:	6442                	ld	s0,16(sp)
    800044e0:	6105                	addi	sp,sp,32
    800044e2:	8082                	ret

00000000800044e4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044e4:	1141                	addi	sp,sp,-16
    800044e6:	e406                	sd	ra,8(sp)
    800044e8:	e022                	sd	s0,0(sp)
    800044ea:	0800                	addi	s0,sp,16
    800044ec:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800044ee:	4585                	li	a1,1
    800044f0:	00000097          	auipc	ra,0x0
    800044f4:	db4080e7          	jalr	-588(ra) # 800042a4 <namex>
}
    800044f8:	60a2                	ld	ra,8(sp)
    800044fa:	6402                	ld	s0,0(sp)
    800044fc:	0141                	addi	sp,sp,16
    800044fe:	8082                	ret

0000000080004500 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004500:	1101                	addi	sp,sp,-32
    80004502:	ec06                	sd	ra,24(sp)
    80004504:	e822                	sd	s0,16(sp)
    80004506:	e426                	sd	s1,8(sp)
    80004508:	e04a                	sd	s2,0(sp)
    8000450a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000450c:	0001e917          	auipc	s2,0x1e
    80004510:	8a490913          	addi	s2,s2,-1884 # 80021db0 <log>
    80004514:	01892583          	lw	a1,24(s2)
    80004518:	02892503          	lw	a0,40(s2)
    8000451c:	fffff097          	auipc	ra,0xfffff
    80004520:	ff2080e7          	jalr	-14(ra) # 8000350e <bread>
    80004524:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004526:	02c92683          	lw	a3,44(s2)
    8000452a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000452c:	02d05763          	blez	a3,8000455a <write_head+0x5a>
    80004530:	0001e797          	auipc	a5,0x1e
    80004534:	8b078793          	addi	a5,a5,-1872 # 80021de0 <log+0x30>
    80004538:	05c50713          	addi	a4,a0,92
    8000453c:	36fd                	addiw	a3,a3,-1
    8000453e:	1682                	slli	a3,a3,0x20
    80004540:	9281                	srli	a3,a3,0x20
    80004542:	068a                	slli	a3,a3,0x2
    80004544:	0001e617          	auipc	a2,0x1e
    80004548:	8a060613          	addi	a2,a2,-1888 # 80021de4 <log+0x34>
    8000454c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000454e:	4390                	lw	a2,0(a5)
    80004550:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004552:	0791                	addi	a5,a5,4
    80004554:	0711                	addi	a4,a4,4
    80004556:	fed79ce3          	bne	a5,a3,8000454e <write_head+0x4e>
  }
  bwrite(buf);
    8000455a:	8526                	mv	a0,s1
    8000455c:	fffff097          	auipc	ra,0xfffff
    80004560:	0a4080e7          	jalr	164(ra) # 80003600 <bwrite>
  brelse(buf);
    80004564:	8526                	mv	a0,s1
    80004566:	fffff097          	auipc	ra,0xfffff
    8000456a:	0d8080e7          	jalr	216(ra) # 8000363e <brelse>
}
    8000456e:	60e2                	ld	ra,24(sp)
    80004570:	6442                	ld	s0,16(sp)
    80004572:	64a2                	ld	s1,8(sp)
    80004574:	6902                	ld	s2,0(sp)
    80004576:	6105                	addi	sp,sp,32
    80004578:	8082                	ret

000000008000457a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000457a:	0001e797          	auipc	a5,0x1e
    8000457e:	8627a783          	lw	a5,-1950(a5) # 80021ddc <log+0x2c>
    80004582:	0af05d63          	blez	a5,8000463c <install_trans+0xc2>
{
    80004586:	7139                	addi	sp,sp,-64
    80004588:	fc06                	sd	ra,56(sp)
    8000458a:	f822                	sd	s0,48(sp)
    8000458c:	f426                	sd	s1,40(sp)
    8000458e:	f04a                	sd	s2,32(sp)
    80004590:	ec4e                	sd	s3,24(sp)
    80004592:	e852                	sd	s4,16(sp)
    80004594:	e456                	sd	s5,8(sp)
    80004596:	e05a                	sd	s6,0(sp)
    80004598:	0080                	addi	s0,sp,64
    8000459a:	8b2a                	mv	s6,a0
    8000459c:	0001ea97          	auipc	s5,0x1e
    800045a0:	844a8a93          	addi	s5,s5,-1980 # 80021de0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045a4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045a6:	0001e997          	auipc	s3,0x1e
    800045aa:	80a98993          	addi	s3,s3,-2038 # 80021db0 <log>
    800045ae:	a035                	j	800045da <install_trans+0x60>
      bunpin(dbuf);
    800045b0:	8526                	mv	a0,s1
    800045b2:	fffff097          	auipc	ra,0xfffff
    800045b6:	166080e7          	jalr	358(ra) # 80003718 <bunpin>
    brelse(lbuf);
    800045ba:	854a                	mv	a0,s2
    800045bc:	fffff097          	auipc	ra,0xfffff
    800045c0:	082080e7          	jalr	130(ra) # 8000363e <brelse>
    brelse(dbuf);
    800045c4:	8526                	mv	a0,s1
    800045c6:	fffff097          	auipc	ra,0xfffff
    800045ca:	078080e7          	jalr	120(ra) # 8000363e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045ce:	2a05                	addiw	s4,s4,1
    800045d0:	0a91                	addi	s5,s5,4
    800045d2:	02c9a783          	lw	a5,44(s3)
    800045d6:	04fa5963          	bge	s4,a5,80004628 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045da:	0189a583          	lw	a1,24(s3)
    800045de:	014585bb          	addw	a1,a1,s4
    800045e2:	2585                	addiw	a1,a1,1
    800045e4:	0289a503          	lw	a0,40(s3)
    800045e8:	fffff097          	auipc	ra,0xfffff
    800045ec:	f26080e7          	jalr	-218(ra) # 8000350e <bread>
    800045f0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045f2:	000aa583          	lw	a1,0(s5)
    800045f6:	0289a503          	lw	a0,40(s3)
    800045fa:	fffff097          	auipc	ra,0xfffff
    800045fe:	f14080e7          	jalr	-236(ra) # 8000350e <bread>
    80004602:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004604:	40000613          	li	a2,1024
    80004608:	05890593          	addi	a1,s2,88
    8000460c:	05850513          	addi	a0,a0,88
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	730080e7          	jalr	1840(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004618:	8526                	mv	a0,s1
    8000461a:	fffff097          	auipc	ra,0xfffff
    8000461e:	fe6080e7          	jalr	-26(ra) # 80003600 <bwrite>
    if(recovering == 0)
    80004622:	f80b1ce3          	bnez	s6,800045ba <install_trans+0x40>
    80004626:	b769                	j	800045b0 <install_trans+0x36>
}
    80004628:	70e2                	ld	ra,56(sp)
    8000462a:	7442                	ld	s0,48(sp)
    8000462c:	74a2                	ld	s1,40(sp)
    8000462e:	7902                	ld	s2,32(sp)
    80004630:	69e2                	ld	s3,24(sp)
    80004632:	6a42                	ld	s4,16(sp)
    80004634:	6aa2                	ld	s5,8(sp)
    80004636:	6b02                	ld	s6,0(sp)
    80004638:	6121                	addi	sp,sp,64
    8000463a:	8082                	ret
    8000463c:	8082                	ret

000000008000463e <initlog>:
{
    8000463e:	7179                	addi	sp,sp,-48
    80004640:	f406                	sd	ra,40(sp)
    80004642:	f022                	sd	s0,32(sp)
    80004644:	ec26                	sd	s1,24(sp)
    80004646:	e84a                	sd	s2,16(sp)
    80004648:	e44e                	sd	s3,8(sp)
    8000464a:	1800                	addi	s0,sp,48
    8000464c:	892a                	mv	s2,a0
    8000464e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004650:	0001d497          	auipc	s1,0x1d
    80004654:	76048493          	addi	s1,s1,1888 # 80021db0 <log>
    80004658:	00004597          	auipc	a1,0x4
    8000465c:	07058593          	addi	a1,a1,112 # 800086c8 <syscalls+0x1d8>
    80004660:	8526                	mv	a0,s1
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	4f2080e7          	jalr	1266(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000466a:	0149a583          	lw	a1,20(s3)
    8000466e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004670:	0109a783          	lw	a5,16(s3)
    80004674:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004676:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000467a:	854a                	mv	a0,s2
    8000467c:	fffff097          	auipc	ra,0xfffff
    80004680:	e92080e7          	jalr	-366(ra) # 8000350e <bread>
  log.lh.n = lh->n;
    80004684:	4d3c                	lw	a5,88(a0)
    80004686:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004688:	02f05563          	blez	a5,800046b2 <initlog+0x74>
    8000468c:	05c50713          	addi	a4,a0,92
    80004690:	0001d697          	auipc	a3,0x1d
    80004694:	75068693          	addi	a3,a3,1872 # 80021de0 <log+0x30>
    80004698:	37fd                	addiw	a5,a5,-1
    8000469a:	1782                	slli	a5,a5,0x20
    8000469c:	9381                	srli	a5,a5,0x20
    8000469e:	078a                	slli	a5,a5,0x2
    800046a0:	06050613          	addi	a2,a0,96
    800046a4:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800046a6:	4310                	lw	a2,0(a4)
    800046a8:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800046aa:	0711                	addi	a4,a4,4
    800046ac:	0691                	addi	a3,a3,4
    800046ae:	fef71ce3          	bne	a4,a5,800046a6 <initlog+0x68>
  brelse(buf);
    800046b2:	fffff097          	auipc	ra,0xfffff
    800046b6:	f8c080e7          	jalr	-116(ra) # 8000363e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046ba:	4505                	li	a0,1
    800046bc:	00000097          	auipc	ra,0x0
    800046c0:	ebe080e7          	jalr	-322(ra) # 8000457a <install_trans>
  log.lh.n = 0;
    800046c4:	0001d797          	auipc	a5,0x1d
    800046c8:	7007ac23          	sw	zero,1816(a5) # 80021ddc <log+0x2c>
  write_head(); // clear the log
    800046cc:	00000097          	auipc	ra,0x0
    800046d0:	e34080e7          	jalr	-460(ra) # 80004500 <write_head>
}
    800046d4:	70a2                	ld	ra,40(sp)
    800046d6:	7402                	ld	s0,32(sp)
    800046d8:	64e2                	ld	s1,24(sp)
    800046da:	6942                	ld	s2,16(sp)
    800046dc:	69a2                	ld	s3,8(sp)
    800046de:	6145                	addi	sp,sp,48
    800046e0:	8082                	ret

00000000800046e2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800046e2:	1101                	addi	sp,sp,-32
    800046e4:	ec06                	sd	ra,24(sp)
    800046e6:	e822                	sd	s0,16(sp)
    800046e8:	e426                	sd	s1,8(sp)
    800046ea:	e04a                	sd	s2,0(sp)
    800046ec:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800046ee:	0001d517          	auipc	a0,0x1d
    800046f2:	6c250513          	addi	a0,a0,1730 # 80021db0 <log>
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	4ee080e7          	jalr	1262(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800046fe:	0001d497          	auipc	s1,0x1d
    80004702:	6b248493          	addi	s1,s1,1714 # 80021db0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004706:	4979                	li	s2,30
    80004708:	a039                	j	80004716 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000470a:	85a6                	mv	a1,s1
    8000470c:	8526                	mv	a0,s1
    8000470e:	ffffe097          	auipc	ra,0xffffe
    80004712:	f1a080e7          	jalr	-230(ra) # 80002628 <sleep>
    if(log.committing){
    80004716:	50dc                	lw	a5,36(s1)
    80004718:	fbed                	bnez	a5,8000470a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000471a:	509c                	lw	a5,32(s1)
    8000471c:	0017871b          	addiw	a4,a5,1
    80004720:	0007069b          	sext.w	a3,a4
    80004724:	0027179b          	slliw	a5,a4,0x2
    80004728:	9fb9                	addw	a5,a5,a4
    8000472a:	0017979b          	slliw	a5,a5,0x1
    8000472e:	54d8                	lw	a4,44(s1)
    80004730:	9fb9                	addw	a5,a5,a4
    80004732:	00f95963          	bge	s2,a5,80004744 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004736:	85a6                	mv	a1,s1
    80004738:	8526                	mv	a0,s1
    8000473a:	ffffe097          	auipc	ra,0xffffe
    8000473e:	eee080e7          	jalr	-274(ra) # 80002628 <sleep>
    80004742:	bfd1                	j	80004716 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004744:	0001d517          	auipc	a0,0x1d
    80004748:	66c50513          	addi	a0,a0,1644 # 80021db0 <log>
    8000474c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	54a080e7          	jalr	1354(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004756:	60e2                	ld	ra,24(sp)
    80004758:	6442                	ld	s0,16(sp)
    8000475a:	64a2                	ld	s1,8(sp)
    8000475c:	6902                	ld	s2,0(sp)
    8000475e:	6105                	addi	sp,sp,32
    80004760:	8082                	ret

0000000080004762 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004762:	7139                	addi	sp,sp,-64
    80004764:	fc06                	sd	ra,56(sp)
    80004766:	f822                	sd	s0,48(sp)
    80004768:	f426                	sd	s1,40(sp)
    8000476a:	f04a                	sd	s2,32(sp)
    8000476c:	ec4e                	sd	s3,24(sp)
    8000476e:	e852                	sd	s4,16(sp)
    80004770:	e456                	sd	s5,8(sp)
    80004772:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004774:	0001d497          	auipc	s1,0x1d
    80004778:	63c48493          	addi	s1,s1,1596 # 80021db0 <log>
    8000477c:	8526                	mv	a0,s1
    8000477e:	ffffc097          	auipc	ra,0xffffc
    80004782:	466080e7          	jalr	1126(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004786:	509c                	lw	a5,32(s1)
    80004788:	37fd                	addiw	a5,a5,-1
    8000478a:	0007891b          	sext.w	s2,a5
    8000478e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004790:	50dc                	lw	a5,36(s1)
    80004792:	efb9                	bnez	a5,800047f0 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004794:	06091663          	bnez	s2,80004800 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004798:	0001d497          	auipc	s1,0x1d
    8000479c:	61848493          	addi	s1,s1,1560 # 80021db0 <log>
    800047a0:	4785                	li	a5,1
    800047a2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800047a4:	8526                	mv	a0,s1
    800047a6:	ffffc097          	auipc	ra,0xffffc
    800047aa:	4f2080e7          	jalr	1266(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800047ae:	54dc                	lw	a5,44(s1)
    800047b0:	06f04763          	bgtz	a5,8000481e <end_op+0xbc>
    acquire(&log.lock);
    800047b4:	0001d497          	auipc	s1,0x1d
    800047b8:	5fc48493          	addi	s1,s1,1532 # 80021db0 <log>
    800047bc:	8526                	mv	a0,s1
    800047be:	ffffc097          	auipc	ra,0xffffc
    800047c2:	426080e7          	jalr	1062(ra) # 80000be4 <acquire>
    log.committing = 0;
    800047c6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800047ca:	8526                	mv	a0,s1
    800047cc:	ffffe097          	auipc	ra,0xffffe
    800047d0:	ffa080e7          	jalr	-6(ra) # 800027c6 <wakeup>
    release(&log.lock);
    800047d4:	8526                	mv	a0,s1
    800047d6:	ffffc097          	auipc	ra,0xffffc
    800047da:	4c2080e7          	jalr	1218(ra) # 80000c98 <release>
}
    800047de:	70e2                	ld	ra,56(sp)
    800047e0:	7442                	ld	s0,48(sp)
    800047e2:	74a2                	ld	s1,40(sp)
    800047e4:	7902                	ld	s2,32(sp)
    800047e6:	69e2                	ld	s3,24(sp)
    800047e8:	6a42                	ld	s4,16(sp)
    800047ea:	6aa2                	ld	s5,8(sp)
    800047ec:	6121                	addi	sp,sp,64
    800047ee:	8082                	ret
    panic("log.committing");
    800047f0:	00004517          	auipc	a0,0x4
    800047f4:	ee050513          	addi	a0,a0,-288 # 800086d0 <syscalls+0x1e0>
    800047f8:	ffffc097          	auipc	ra,0xffffc
    800047fc:	d46080e7          	jalr	-698(ra) # 8000053e <panic>
    wakeup(&log);
    80004800:	0001d497          	auipc	s1,0x1d
    80004804:	5b048493          	addi	s1,s1,1456 # 80021db0 <log>
    80004808:	8526                	mv	a0,s1
    8000480a:	ffffe097          	auipc	ra,0xffffe
    8000480e:	fbc080e7          	jalr	-68(ra) # 800027c6 <wakeup>
  release(&log.lock);
    80004812:	8526                	mv	a0,s1
    80004814:	ffffc097          	auipc	ra,0xffffc
    80004818:	484080e7          	jalr	1156(ra) # 80000c98 <release>
  if(do_commit){
    8000481c:	b7c9                	j	800047de <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000481e:	0001da97          	auipc	s5,0x1d
    80004822:	5c2a8a93          	addi	s5,s5,1474 # 80021de0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004826:	0001da17          	auipc	s4,0x1d
    8000482a:	58aa0a13          	addi	s4,s4,1418 # 80021db0 <log>
    8000482e:	018a2583          	lw	a1,24(s4)
    80004832:	012585bb          	addw	a1,a1,s2
    80004836:	2585                	addiw	a1,a1,1
    80004838:	028a2503          	lw	a0,40(s4)
    8000483c:	fffff097          	auipc	ra,0xfffff
    80004840:	cd2080e7          	jalr	-814(ra) # 8000350e <bread>
    80004844:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004846:	000aa583          	lw	a1,0(s5)
    8000484a:	028a2503          	lw	a0,40(s4)
    8000484e:	fffff097          	auipc	ra,0xfffff
    80004852:	cc0080e7          	jalr	-832(ra) # 8000350e <bread>
    80004856:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004858:	40000613          	li	a2,1024
    8000485c:	05850593          	addi	a1,a0,88
    80004860:	05848513          	addi	a0,s1,88
    80004864:	ffffc097          	auipc	ra,0xffffc
    80004868:	4dc080e7          	jalr	1244(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000486c:	8526                	mv	a0,s1
    8000486e:	fffff097          	auipc	ra,0xfffff
    80004872:	d92080e7          	jalr	-622(ra) # 80003600 <bwrite>
    brelse(from);
    80004876:	854e                	mv	a0,s3
    80004878:	fffff097          	auipc	ra,0xfffff
    8000487c:	dc6080e7          	jalr	-570(ra) # 8000363e <brelse>
    brelse(to);
    80004880:	8526                	mv	a0,s1
    80004882:	fffff097          	auipc	ra,0xfffff
    80004886:	dbc080e7          	jalr	-580(ra) # 8000363e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000488a:	2905                	addiw	s2,s2,1
    8000488c:	0a91                	addi	s5,s5,4
    8000488e:	02ca2783          	lw	a5,44(s4)
    80004892:	f8f94ee3          	blt	s2,a5,8000482e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004896:	00000097          	auipc	ra,0x0
    8000489a:	c6a080e7          	jalr	-918(ra) # 80004500 <write_head>
    install_trans(0); // Now install writes to home locations
    8000489e:	4501                	li	a0,0
    800048a0:	00000097          	auipc	ra,0x0
    800048a4:	cda080e7          	jalr	-806(ra) # 8000457a <install_trans>
    log.lh.n = 0;
    800048a8:	0001d797          	auipc	a5,0x1d
    800048ac:	5207aa23          	sw	zero,1332(a5) # 80021ddc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800048b0:	00000097          	auipc	ra,0x0
    800048b4:	c50080e7          	jalr	-944(ra) # 80004500 <write_head>
    800048b8:	bdf5                	j	800047b4 <end_op+0x52>

00000000800048ba <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048ba:	1101                	addi	sp,sp,-32
    800048bc:	ec06                	sd	ra,24(sp)
    800048be:	e822                	sd	s0,16(sp)
    800048c0:	e426                	sd	s1,8(sp)
    800048c2:	e04a                	sd	s2,0(sp)
    800048c4:	1000                	addi	s0,sp,32
    800048c6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800048c8:	0001d917          	auipc	s2,0x1d
    800048cc:	4e890913          	addi	s2,s2,1256 # 80021db0 <log>
    800048d0:	854a                	mv	a0,s2
    800048d2:	ffffc097          	auipc	ra,0xffffc
    800048d6:	312080e7          	jalr	786(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048da:	02c92603          	lw	a2,44(s2)
    800048de:	47f5                	li	a5,29
    800048e0:	06c7c563          	blt	a5,a2,8000494a <log_write+0x90>
    800048e4:	0001d797          	auipc	a5,0x1d
    800048e8:	4e87a783          	lw	a5,1256(a5) # 80021dcc <log+0x1c>
    800048ec:	37fd                	addiw	a5,a5,-1
    800048ee:	04f65e63          	bge	a2,a5,8000494a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800048f2:	0001d797          	auipc	a5,0x1d
    800048f6:	4de7a783          	lw	a5,1246(a5) # 80021dd0 <log+0x20>
    800048fa:	06f05063          	blez	a5,8000495a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800048fe:	4781                	li	a5,0
    80004900:	06c05563          	blez	a2,8000496a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004904:	44cc                	lw	a1,12(s1)
    80004906:	0001d717          	auipc	a4,0x1d
    8000490a:	4da70713          	addi	a4,a4,1242 # 80021de0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000490e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004910:	4314                	lw	a3,0(a4)
    80004912:	04b68c63          	beq	a3,a1,8000496a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004916:	2785                	addiw	a5,a5,1
    80004918:	0711                	addi	a4,a4,4
    8000491a:	fef61be3          	bne	a2,a5,80004910 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000491e:	0621                	addi	a2,a2,8
    80004920:	060a                	slli	a2,a2,0x2
    80004922:	0001d797          	auipc	a5,0x1d
    80004926:	48e78793          	addi	a5,a5,1166 # 80021db0 <log>
    8000492a:	963e                	add	a2,a2,a5
    8000492c:	44dc                	lw	a5,12(s1)
    8000492e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004930:	8526                	mv	a0,s1
    80004932:	fffff097          	auipc	ra,0xfffff
    80004936:	daa080e7          	jalr	-598(ra) # 800036dc <bpin>
    log.lh.n++;
    8000493a:	0001d717          	auipc	a4,0x1d
    8000493e:	47670713          	addi	a4,a4,1142 # 80021db0 <log>
    80004942:	575c                	lw	a5,44(a4)
    80004944:	2785                	addiw	a5,a5,1
    80004946:	d75c                	sw	a5,44(a4)
    80004948:	a835                	j	80004984 <log_write+0xca>
    panic("too big a transaction");
    8000494a:	00004517          	auipc	a0,0x4
    8000494e:	d9650513          	addi	a0,a0,-618 # 800086e0 <syscalls+0x1f0>
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	bec080e7          	jalr	-1044(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000495a:	00004517          	auipc	a0,0x4
    8000495e:	d9e50513          	addi	a0,a0,-610 # 800086f8 <syscalls+0x208>
    80004962:	ffffc097          	auipc	ra,0xffffc
    80004966:	bdc080e7          	jalr	-1060(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000496a:	00878713          	addi	a4,a5,8
    8000496e:	00271693          	slli	a3,a4,0x2
    80004972:	0001d717          	auipc	a4,0x1d
    80004976:	43e70713          	addi	a4,a4,1086 # 80021db0 <log>
    8000497a:	9736                	add	a4,a4,a3
    8000497c:	44d4                	lw	a3,12(s1)
    8000497e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004980:	faf608e3          	beq	a2,a5,80004930 <log_write+0x76>
  }
  release(&log.lock);
    80004984:	0001d517          	auipc	a0,0x1d
    80004988:	42c50513          	addi	a0,a0,1068 # 80021db0 <log>
    8000498c:	ffffc097          	auipc	ra,0xffffc
    80004990:	30c080e7          	jalr	780(ra) # 80000c98 <release>
}
    80004994:	60e2                	ld	ra,24(sp)
    80004996:	6442                	ld	s0,16(sp)
    80004998:	64a2                	ld	s1,8(sp)
    8000499a:	6902                	ld	s2,0(sp)
    8000499c:	6105                	addi	sp,sp,32
    8000499e:	8082                	ret

00000000800049a0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800049a0:	1101                	addi	sp,sp,-32
    800049a2:	ec06                	sd	ra,24(sp)
    800049a4:	e822                	sd	s0,16(sp)
    800049a6:	e426                	sd	s1,8(sp)
    800049a8:	e04a                	sd	s2,0(sp)
    800049aa:	1000                	addi	s0,sp,32
    800049ac:	84aa                	mv	s1,a0
    800049ae:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049b0:	00004597          	auipc	a1,0x4
    800049b4:	d6858593          	addi	a1,a1,-664 # 80008718 <syscalls+0x228>
    800049b8:	0521                	addi	a0,a0,8
    800049ba:	ffffc097          	auipc	ra,0xffffc
    800049be:	19a080e7          	jalr	410(ra) # 80000b54 <initlock>
  lk->name = name;
    800049c2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049c6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049ca:	0204a423          	sw	zero,40(s1)
}
    800049ce:	60e2                	ld	ra,24(sp)
    800049d0:	6442                	ld	s0,16(sp)
    800049d2:	64a2                	ld	s1,8(sp)
    800049d4:	6902                	ld	s2,0(sp)
    800049d6:	6105                	addi	sp,sp,32
    800049d8:	8082                	ret

00000000800049da <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049da:	1101                	addi	sp,sp,-32
    800049dc:	ec06                	sd	ra,24(sp)
    800049de:	e822                	sd	s0,16(sp)
    800049e0:	e426                	sd	s1,8(sp)
    800049e2:	e04a                	sd	s2,0(sp)
    800049e4:	1000                	addi	s0,sp,32
    800049e6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049e8:	00850913          	addi	s2,a0,8
    800049ec:	854a                	mv	a0,s2
    800049ee:	ffffc097          	auipc	ra,0xffffc
    800049f2:	1f6080e7          	jalr	502(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800049f6:	409c                	lw	a5,0(s1)
    800049f8:	cb89                	beqz	a5,80004a0a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800049fa:	85ca                	mv	a1,s2
    800049fc:	8526                	mv	a0,s1
    800049fe:	ffffe097          	auipc	ra,0xffffe
    80004a02:	c2a080e7          	jalr	-982(ra) # 80002628 <sleep>
  while (lk->locked) {
    80004a06:	409c                	lw	a5,0(s1)
    80004a08:	fbed                	bnez	a5,800049fa <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a0a:	4785                	li	a5,1
    80004a0c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a0e:	ffffd097          	auipc	ra,0xffffd
    80004a12:	406080e7          	jalr	1030(ra) # 80001e14 <myproc>
    80004a16:	591c                	lw	a5,48(a0)
    80004a18:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a1a:	854a                	mv	a0,s2
    80004a1c:	ffffc097          	auipc	ra,0xffffc
    80004a20:	27c080e7          	jalr	636(ra) # 80000c98 <release>
}
    80004a24:	60e2                	ld	ra,24(sp)
    80004a26:	6442                	ld	s0,16(sp)
    80004a28:	64a2                	ld	s1,8(sp)
    80004a2a:	6902                	ld	s2,0(sp)
    80004a2c:	6105                	addi	sp,sp,32
    80004a2e:	8082                	ret

0000000080004a30 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a30:	1101                	addi	sp,sp,-32
    80004a32:	ec06                	sd	ra,24(sp)
    80004a34:	e822                	sd	s0,16(sp)
    80004a36:	e426                	sd	s1,8(sp)
    80004a38:	e04a                	sd	s2,0(sp)
    80004a3a:	1000                	addi	s0,sp,32
    80004a3c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a3e:	00850913          	addi	s2,a0,8
    80004a42:	854a                	mv	a0,s2
    80004a44:	ffffc097          	auipc	ra,0xffffc
    80004a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004a4c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a50:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a54:	8526                	mv	a0,s1
    80004a56:	ffffe097          	auipc	ra,0xffffe
    80004a5a:	d70080e7          	jalr	-656(ra) # 800027c6 <wakeup>
  release(&lk->lk);
    80004a5e:	854a                	mv	a0,s2
    80004a60:	ffffc097          	auipc	ra,0xffffc
    80004a64:	238080e7          	jalr	568(ra) # 80000c98 <release>
}
    80004a68:	60e2                	ld	ra,24(sp)
    80004a6a:	6442                	ld	s0,16(sp)
    80004a6c:	64a2                	ld	s1,8(sp)
    80004a6e:	6902                	ld	s2,0(sp)
    80004a70:	6105                	addi	sp,sp,32
    80004a72:	8082                	ret

0000000080004a74 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a74:	7179                	addi	sp,sp,-48
    80004a76:	f406                	sd	ra,40(sp)
    80004a78:	f022                	sd	s0,32(sp)
    80004a7a:	ec26                	sd	s1,24(sp)
    80004a7c:	e84a                	sd	s2,16(sp)
    80004a7e:	e44e                	sd	s3,8(sp)
    80004a80:	1800                	addi	s0,sp,48
    80004a82:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a84:	00850913          	addi	s2,a0,8
    80004a88:	854a                	mv	a0,s2
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	15a080e7          	jalr	346(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a92:	409c                	lw	a5,0(s1)
    80004a94:	ef99                	bnez	a5,80004ab2 <holdingsleep+0x3e>
    80004a96:	4481                	li	s1,0
  release(&lk->lk);
    80004a98:	854a                	mv	a0,s2
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	1fe080e7          	jalr	510(ra) # 80000c98 <release>
  return r;
}
    80004aa2:	8526                	mv	a0,s1
    80004aa4:	70a2                	ld	ra,40(sp)
    80004aa6:	7402                	ld	s0,32(sp)
    80004aa8:	64e2                	ld	s1,24(sp)
    80004aaa:	6942                	ld	s2,16(sp)
    80004aac:	69a2                	ld	s3,8(sp)
    80004aae:	6145                	addi	sp,sp,48
    80004ab0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ab2:	0284a983          	lw	s3,40(s1)
    80004ab6:	ffffd097          	auipc	ra,0xffffd
    80004aba:	35e080e7          	jalr	862(ra) # 80001e14 <myproc>
    80004abe:	5904                	lw	s1,48(a0)
    80004ac0:	413484b3          	sub	s1,s1,s3
    80004ac4:	0014b493          	seqz	s1,s1
    80004ac8:	bfc1                	j	80004a98 <holdingsleep+0x24>

0000000080004aca <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004aca:	1141                	addi	sp,sp,-16
    80004acc:	e406                	sd	ra,8(sp)
    80004ace:	e022                	sd	s0,0(sp)
    80004ad0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004ad2:	00004597          	auipc	a1,0x4
    80004ad6:	c5658593          	addi	a1,a1,-938 # 80008728 <syscalls+0x238>
    80004ada:	0001d517          	auipc	a0,0x1d
    80004ade:	41e50513          	addi	a0,a0,1054 # 80021ef8 <ftable>
    80004ae2:	ffffc097          	auipc	ra,0xffffc
    80004ae6:	072080e7          	jalr	114(ra) # 80000b54 <initlock>
}
    80004aea:	60a2                	ld	ra,8(sp)
    80004aec:	6402                	ld	s0,0(sp)
    80004aee:	0141                	addi	sp,sp,16
    80004af0:	8082                	ret

0000000080004af2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004af2:	1101                	addi	sp,sp,-32
    80004af4:	ec06                	sd	ra,24(sp)
    80004af6:	e822                	sd	s0,16(sp)
    80004af8:	e426                	sd	s1,8(sp)
    80004afa:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004afc:	0001d517          	auipc	a0,0x1d
    80004b00:	3fc50513          	addi	a0,a0,1020 # 80021ef8 <ftable>
    80004b04:	ffffc097          	auipc	ra,0xffffc
    80004b08:	0e0080e7          	jalr	224(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b0c:	0001d497          	auipc	s1,0x1d
    80004b10:	40448493          	addi	s1,s1,1028 # 80021f10 <ftable+0x18>
    80004b14:	0001e717          	auipc	a4,0x1e
    80004b18:	39c70713          	addi	a4,a4,924 # 80022eb0 <ftable+0xfb8>
    if(f->ref == 0){
    80004b1c:	40dc                	lw	a5,4(s1)
    80004b1e:	cf99                	beqz	a5,80004b3c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b20:	02848493          	addi	s1,s1,40
    80004b24:	fee49ce3          	bne	s1,a4,80004b1c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b28:	0001d517          	auipc	a0,0x1d
    80004b2c:	3d050513          	addi	a0,a0,976 # 80021ef8 <ftable>
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	168080e7          	jalr	360(ra) # 80000c98 <release>
  return 0;
    80004b38:	4481                	li	s1,0
    80004b3a:	a819                	j	80004b50 <filealloc+0x5e>
      f->ref = 1;
    80004b3c:	4785                	li	a5,1
    80004b3e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b40:	0001d517          	auipc	a0,0x1d
    80004b44:	3b850513          	addi	a0,a0,952 # 80021ef8 <ftable>
    80004b48:	ffffc097          	auipc	ra,0xffffc
    80004b4c:	150080e7          	jalr	336(ra) # 80000c98 <release>
}
    80004b50:	8526                	mv	a0,s1
    80004b52:	60e2                	ld	ra,24(sp)
    80004b54:	6442                	ld	s0,16(sp)
    80004b56:	64a2                	ld	s1,8(sp)
    80004b58:	6105                	addi	sp,sp,32
    80004b5a:	8082                	ret

0000000080004b5c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b5c:	1101                	addi	sp,sp,-32
    80004b5e:	ec06                	sd	ra,24(sp)
    80004b60:	e822                	sd	s0,16(sp)
    80004b62:	e426                	sd	s1,8(sp)
    80004b64:	1000                	addi	s0,sp,32
    80004b66:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b68:	0001d517          	auipc	a0,0x1d
    80004b6c:	39050513          	addi	a0,a0,912 # 80021ef8 <ftable>
    80004b70:	ffffc097          	auipc	ra,0xffffc
    80004b74:	074080e7          	jalr	116(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004b78:	40dc                	lw	a5,4(s1)
    80004b7a:	02f05263          	blez	a5,80004b9e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b7e:	2785                	addiw	a5,a5,1
    80004b80:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b82:	0001d517          	auipc	a0,0x1d
    80004b86:	37650513          	addi	a0,a0,886 # 80021ef8 <ftable>
    80004b8a:	ffffc097          	auipc	ra,0xffffc
    80004b8e:	10e080e7          	jalr	270(ra) # 80000c98 <release>
  return f;
}
    80004b92:	8526                	mv	a0,s1
    80004b94:	60e2                	ld	ra,24(sp)
    80004b96:	6442                	ld	s0,16(sp)
    80004b98:	64a2                	ld	s1,8(sp)
    80004b9a:	6105                	addi	sp,sp,32
    80004b9c:	8082                	ret
    panic("filedup");
    80004b9e:	00004517          	auipc	a0,0x4
    80004ba2:	b9250513          	addi	a0,a0,-1134 # 80008730 <syscalls+0x240>
    80004ba6:	ffffc097          	auipc	ra,0xffffc
    80004baa:	998080e7          	jalr	-1640(ra) # 8000053e <panic>

0000000080004bae <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004bae:	7139                	addi	sp,sp,-64
    80004bb0:	fc06                	sd	ra,56(sp)
    80004bb2:	f822                	sd	s0,48(sp)
    80004bb4:	f426                	sd	s1,40(sp)
    80004bb6:	f04a                	sd	s2,32(sp)
    80004bb8:	ec4e                	sd	s3,24(sp)
    80004bba:	e852                	sd	s4,16(sp)
    80004bbc:	e456                	sd	s5,8(sp)
    80004bbe:	0080                	addi	s0,sp,64
    80004bc0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004bc2:	0001d517          	auipc	a0,0x1d
    80004bc6:	33650513          	addi	a0,a0,822 # 80021ef8 <ftable>
    80004bca:	ffffc097          	auipc	ra,0xffffc
    80004bce:	01a080e7          	jalr	26(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004bd2:	40dc                	lw	a5,4(s1)
    80004bd4:	06f05163          	blez	a5,80004c36 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004bd8:	37fd                	addiw	a5,a5,-1
    80004bda:	0007871b          	sext.w	a4,a5
    80004bde:	c0dc                	sw	a5,4(s1)
    80004be0:	06e04363          	bgtz	a4,80004c46 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004be4:	0004a903          	lw	s2,0(s1)
    80004be8:	0094ca83          	lbu	s5,9(s1)
    80004bec:	0104ba03          	ld	s4,16(s1)
    80004bf0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004bf4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004bf8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004bfc:	0001d517          	auipc	a0,0x1d
    80004c00:	2fc50513          	addi	a0,a0,764 # 80021ef8 <ftable>
    80004c04:	ffffc097          	auipc	ra,0xffffc
    80004c08:	094080e7          	jalr	148(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004c0c:	4785                	li	a5,1
    80004c0e:	04f90d63          	beq	s2,a5,80004c68 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c12:	3979                	addiw	s2,s2,-2
    80004c14:	4785                	li	a5,1
    80004c16:	0527e063          	bltu	a5,s2,80004c56 <fileclose+0xa8>
    begin_op();
    80004c1a:	00000097          	auipc	ra,0x0
    80004c1e:	ac8080e7          	jalr	-1336(ra) # 800046e2 <begin_op>
    iput(ff.ip);
    80004c22:	854e                	mv	a0,s3
    80004c24:	fffff097          	auipc	ra,0xfffff
    80004c28:	2a6080e7          	jalr	678(ra) # 80003eca <iput>
    end_op();
    80004c2c:	00000097          	auipc	ra,0x0
    80004c30:	b36080e7          	jalr	-1226(ra) # 80004762 <end_op>
    80004c34:	a00d                	j	80004c56 <fileclose+0xa8>
    panic("fileclose");
    80004c36:	00004517          	auipc	a0,0x4
    80004c3a:	b0250513          	addi	a0,a0,-1278 # 80008738 <syscalls+0x248>
    80004c3e:	ffffc097          	auipc	ra,0xffffc
    80004c42:	900080e7          	jalr	-1792(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004c46:	0001d517          	auipc	a0,0x1d
    80004c4a:	2b250513          	addi	a0,a0,690 # 80021ef8 <ftable>
    80004c4e:	ffffc097          	auipc	ra,0xffffc
    80004c52:	04a080e7          	jalr	74(ra) # 80000c98 <release>
  }
}
    80004c56:	70e2                	ld	ra,56(sp)
    80004c58:	7442                	ld	s0,48(sp)
    80004c5a:	74a2                	ld	s1,40(sp)
    80004c5c:	7902                	ld	s2,32(sp)
    80004c5e:	69e2                	ld	s3,24(sp)
    80004c60:	6a42                	ld	s4,16(sp)
    80004c62:	6aa2                	ld	s5,8(sp)
    80004c64:	6121                	addi	sp,sp,64
    80004c66:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c68:	85d6                	mv	a1,s5
    80004c6a:	8552                	mv	a0,s4
    80004c6c:	00000097          	auipc	ra,0x0
    80004c70:	34c080e7          	jalr	844(ra) # 80004fb8 <pipeclose>
    80004c74:	b7cd                	j	80004c56 <fileclose+0xa8>

0000000080004c76 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c76:	715d                	addi	sp,sp,-80
    80004c78:	e486                	sd	ra,72(sp)
    80004c7a:	e0a2                	sd	s0,64(sp)
    80004c7c:	fc26                	sd	s1,56(sp)
    80004c7e:	f84a                	sd	s2,48(sp)
    80004c80:	f44e                	sd	s3,40(sp)
    80004c82:	0880                	addi	s0,sp,80
    80004c84:	84aa                	mv	s1,a0
    80004c86:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c88:	ffffd097          	auipc	ra,0xffffd
    80004c8c:	18c080e7          	jalr	396(ra) # 80001e14 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c90:	409c                	lw	a5,0(s1)
    80004c92:	37f9                	addiw	a5,a5,-2
    80004c94:	4705                	li	a4,1
    80004c96:	04f76763          	bltu	a4,a5,80004ce4 <filestat+0x6e>
    80004c9a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c9c:	6c88                	ld	a0,24(s1)
    80004c9e:	fffff097          	auipc	ra,0xfffff
    80004ca2:	072080e7          	jalr	114(ra) # 80003d10 <ilock>
    stati(f->ip, &st);
    80004ca6:	fb840593          	addi	a1,s0,-72
    80004caa:	6c88                	ld	a0,24(s1)
    80004cac:	fffff097          	auipc	ra,0xfffff
    80004cb0:	2ee080e7          	jalr	750(ra) # 80003f9a <stati>
    iunlock(f->ip);
    80004cb4:	6c88                	ld	a0,24(s1)
    80004cb6:	fffff097          	auipc	ra,0xfffff
    80004cba:	11c080e7          	jalr	284(ra) # 80003dd2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cbe:	46e1                	li	a3,24
    80004cc0:	fb840613          	addi	a2,s0,-72
    80004cc4:	85ce                	mv	a1,s3
    80004cc6:	05093503          	ld	a0,80(s2)
    80004cca:	ffffd097          	auipc	ra,0xffffd
    80004cce:	9a8080e7          	jalr	-1624(ra) # 80001672 <copyout>
    80004cd2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004cd6:	60a6                	ld	ra,72(sp)
    80004cd8:	6406                	ld	s0,64(sp)
    80004cda:	74e2                	ld	s1,56(sp)
    80004cdc:	7942                	ld	s2,48(sp)
    80004cde:	79a2                	ld	s3,40(sp)
    80004ce0:	6161                	addi	sp,sp,80
    80004ce2:	8082                	ret
  return -1;
    80004ce4:	557d                	li	a0,-1
    80004ce6:	bfc5                	j	80004cd6 <filestat+0x60>

0000000080004ce8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ce8:	7179                	addi	sp,sp,-48
    80004cea:	f406                	sd	ra,40(sp)
    80004cec:	f022                	sd	s0,32(sp)
    80004cee:	ec26                	sd	s1,24(sp)
    80004cf0:	e84a                	sd	s2,16(sp)
    80004cf2:	e44e                	sd	s3,8(sp)
    80004cf4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004cf6:	00854783          	lbu	a5,8(a0)
    80004cfa:	c3d5                	beqz	a5,80004d9e <fileread+0xb6>
    80004cfc:	84aa                	mv	s1,a0
    80004cfe:	89ae                	mv	s3,a1
    80004d00:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d02:	411c                	lw	a5,0(a0)
    80004d04:	4705                	li	a4,1
    80004d06:	04e78963          	beq	a5,a4,80004d58 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d0a:	470d                	li	a4,3
    80004d0c:	04e78d63          	beq	a5,a4,80004d66 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d10:	4709                	li	a4,2
    80004d12:	06e79e63          	bne	a5,a4,80004d8e <fileread+0xa6>
    ilock(f->ip);
    80004d16:	6d08                	ld	a0,24(a0)
    80004d18:	fffff097          	auipc	ra,0xfffff
    80004d1c:	ff8080e7          	jalr	-8(ra) # 80003d10 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d20:	874a                	mv	a4,s2
    80004d22:	5094                	lw	a3,32(s1)
    80004d24:	864e                	mv	a2,s3
    80004d26:	4585                	li	a1,1
    80004d28:	6c88                	ld	a0,24(s1)
    80004d2a:	fffff097          	auipc	ra,0xfffff
    80004d2e:	29a080e7          	jalr	666(ra) # 80003fc4 <readi>
    80004d32:	892a                	mv	s2,a0
    80004d34:	00a05563          	blez	a0,80004d3e <fileread+0x56>
      f->off += r;
    80004d38:	509c                	lw	a5,32(s1)
    80004d3a:	9fa9                	addw	a5,a5,a0
    80004d3c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d3e:	6c88                	ld	a0,24(s1)
    80004d40:	fffff097          	auipc	ra,0xfffff
    80004d44:	092080e7          	jalr	146(ra) # 80003dd2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d48:	854a                	mv	a0,s2
    80004d4a:	70a2                	ld	ra,40(sp)
    80004d4c:	7402                	ld	s0,32(sp)
    80004d4e:	64e2                	ld	s1,24(sp)
    80004d50:	6942                	ld	s2,16(sp)
    80004d52:	69a2                	ld	s3,8(sp)
    80004d54:	6145                	addi	sp,sp,48
    80004d56:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d58:	6908                	ld	a0,16(a0)
    80004d5a:	00000097          	auipc	ra,0x0
    80004d5e:	3c8080e7          	jalr	968(ra) # 80005122 <piperead>
    80004d62:	892a                	mv	s2,a0
    80004d64:	b7d5                	j	80004d48 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d66:	02451783          	lh	a5,36(a0)
    80004d6a:	03079693          	slli	a3,a5,0x30
    80004d6e:	92c1                	srli	a3,a3,0x30
    80004d70:	4725                	li	a4,9
    80004d72:	02d76863          	bltu	a4,a3,80004da2 <fileread+0xba>
    80004d76:	0792                	slli	a5,a5,0x4
    80004d78:	0001d717          	auipc	a4,0x1d
    80004d7c:	0e070713          	addi	a4,a4,224 # 80021e58 <devsw>
    80004d80:	97ba                	add	a5,a5,a4
    80004d82:	639c                	ld	a5,0(a5)
    80004d84:	c38d                	beqz	a5,80004da6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d86:	4505                	li	a0,1
    80004d88:	9782                	jalr	a5
    80004d8a:	892a                	mv	s2,a0
    80004d8c:	bf75                	j	80004d48 <fileread+0x60>
    panic("fileread");
    80004d8e:	00004517          	auipc	a0,0x4
    80004d92:	9ba50513          	addi	a0,a0,-1606 # 80008748 <syscalls+0x258>
    80004d96:	ffffb097          	auipc	ra,0xffffb
    80004d9a:	7a8080e7          	jalr	1960(ra) # 8000053e <panic>
    return -1;
    80004d9e:	597d                	li	s2,-1
    80004da0:	b765                	j	80004d48 <fileread+0x60>
      return -1;
    80004da2:	597d                	li	s2,-1
    80004da4:	b755                	j	80004d48 <fileread+0x60>
    80004da6:	597d                	li	s2,-1
    80004da8:	b745                	j	80004d48 <fileread+0x60>

0000000080004daa <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004daa:	715d                	addi	sp,sp,-80
    80004dac:	e486                	sd	ra,72(sp)
    80004dae:	e0a2                	sd	s0,64(sp)
    80004db0:	fc26                	sd	s1,56(sp)
    80004db2:	f84a                	sd	s2,48(sp)
    80004db4:	f44e                	sd	s3,40(sp)
    80004db6:	f052                	sd	s4,32(sp)
    80004db8:	ec56                	sd	s5,24(sp)
    80004dba:	e85a                	sd	s6,16(sp)
    80004dbc:	e45e                	sd	s7,8(sp)
    80004dbe:	e062                	sd	s8,0(sp)
    80004dc0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004dc2:	00954783          	lbu	a5,9(a0)
    80004dc6:	10078663          	beqz	a5,80004ed2 <filewrite+0x128>
    80004dca:	892a                	mv	s2,a0
    80004dcc:	8aae                	mv	s5,a1
    80004dce:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dd0:	411c                	lw	a5,0(a0)
    80004dd2:	4705                	li	a4,1
    80004dd4:	02e78263          	beq	a5,a4,80004df8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004dd8:	470d                	li	a4,3
    80004dda:	02e78663          	beq	a5,a4,80004e06 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dde:	4709                	li	a4,2
    80004de0:	0ee79163          	bne	a5,a4,80004ec2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004de4:	0ac05d63          	blez	a2,80004e9e <filewrite+0xf4>
    int i = 0;
    80004de8:	4981                	li	s3,0
    80004dea:	6b05                	lui	s6,0x1
    80004dec:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004df0:	6b85                	lui	s7,0x1
    80004df2:	c00b8b9b          	addiw	s7,s7,-1024
    80004df6:	a861                	j	80004e8e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004df8:	6908                	ld	a0,16(a0)
    80004dfa:	00000097          	auipc	ra,0x0
    80004dfe:	22e080e7          	jalr	558(ra) # 80005028 <pipewrite>
    80004e02:	8a2a                	mv	s4,a0
    80004e04:	a045                	j	80004ea4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e06:	02451783          	lh	a5,36(a0)
    80004e0a:	03079693          	slli	a3,a5,0x30
    80004e0e:	92c1                	srli	a3,a3,0x30
    80004e10:	4725                	li	a4,9
    80004e12:	0cd76263          	bltu	a4,a3,80004ed6 <filewrite+0x12c>
    80004e16:	0792                	slli	a5,a5,0x4
    80004e18:	0001d717          	auipc	a4,0x1d
    80004e1c:	04070713          	addi	a4,a4,64 # 80021e58 <devsw>
    80004e20:	97ba                	add	a5,a5,a4
    80004e22:	679c                	ld	a5,8(a5)
    80004e24:	cbdd                	beqz	a5,80004eda <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e26:	4505                	li	a0,1
    80004e28:	9782                	jalr	a5
    80004e2a:	8a2a                	mv	s4,a0
    80004e2c:	a8a5                	j	80004ea4 <filewrite+0xfa>
    80004e2e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e32:	00000097          	auipc	ra,0x0
    80004e36:	8b0080e7          	jalr	-1872(ra) # 800046e2 <begin_op>
      ilock(f->ip);
    80004e3a:	01893503          	ld	a0,24(s2)
    80004e3e:	fffff097          	auipc	ra,0xfffff
    80004e42:	ed2080e7          	jalr	-302(ra) # 80003d10 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e46:	8762                	mv	a4,s8
    80004e48:	02092683          	lw	a3,32(s2)
    80004e4c:	01598633          	add	a2,s3,s5
    80004e50:	4585                	li	a1,1
    80004e52:	01893503          	ld	a0,24(s2)
    80004e56:	fffff097          	auipc	ra,0xfffff
    80004e5a:	266080e7          	jalr	614(ra) # 800040bc <writei>
    80004e5e:	84aa                	mv	s1,a0
    80004e60:	00a05763          	blez	a0,80004e6e <filewrite+0xc4>
        f->off += r;
    80004e64:	02092783          	lw	a5,32(s2)
    80004e68:	9fa9                	addw	a5,a5,a0
    80004e6a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e6e:	01893503          	ld	a0,24(s2)
    80004e72:	fffff097          	auipc	ra,0xfffff
    80004e76:	f60080e7          	jalr	-160(ra) # 80003dd2 <iunlock>
      end_op();
    80004e7a:	00000097          	auipc	ra,0x0
    80004e7e:	8e8080e7          	jalr	-1816(ra) # 80004762 <end_op>

      if(r != n1){
    80004e82:	009c1f63          	bne	s8,s1,80004ea0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e86:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e8a:	0149db63          	bge	s3,s4,80004ea0 <filewrite+0xf6>
      int n1 = n - i;
    80004e8e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004e92:	84be                	mv	s1,a5
    80004e94:	2781                	sext.w	a5,a5
    80004e96:	f8fb5ce3          	bge	s6,a5,80004e2e <filewrite+0x84>
    80004e9a:	84de                	mv	s1,s7
    80004e9c:	bf49                	j	80004e2e <filewrite+0x84>
    int i = 0;
    80004e9e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ea0:	013a1f63          	bne	s4,s3,80004ebe <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ea4:	8552                	mv	a0,s4
    80004ea6:	60a6                	ld	ra,72(sp)
    80004ea8:	6406                	ld	s0,64(sp)
    80004eaa:	74e2                	ld	s1,56(sp)
    80004eac:	7942                	ld	s2,48(sp)
    80004eae:	79a2                	ld	s3,40(sp)
    80004eb0:	7a02                	ld	s4,32(sp)
    80004eb2:	6ae2                	ld	s5,24(sp)
    80004eb4:	6b42                	ld	s6,16(sp)
    80004eb6:	6ba2                	ld	s7,8(sp)
    80004eb8:	6c02                	ld	s8,0(sp)
    80004eba:	6161                	addi	sp,sp,80
    80004ebc:	8082                	ret
    ret = (i == n ? n : -1);
    80004ebe:	5a7d                	li	s4,-1
    80004ec0:	b7d5                	j	80004ea4 <filewrite+0xfa>
    panic("filewrite");
    80004ec2:	00004517          	auipc	a0,0x4
    80004ec6:	89650513          	addi	a0,a0,-1898 # 80008758 <syscalls+0x268>
    80004eca:	ffffb097          	auipc	ra,0xffffb
    80004ece:	674080e7          	jalr	1652(ra) # 8000053e <panic>
    return -1;
    80004ed2:	5a7d                	li	s4,-1
    80004ed4:	bfc1                	j	80004ea4 <filewrite+0xfa>
      return -1;
    80004ed6:	5a7d                	li	s4,-1
    80004ed8:	b7f1                	j	80004ea4 <filewrite+0xfa>
    80004eda:	5a7d                	li	s4,-1
    80004edc:	b7e1                	j	80004ea4 <filewrite+0xfa>

0000000080004ede <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ede:	7179                	addi	sp,sp,-48
    80004ee0:	f406                	sd	ra,40(sp)
    80004ee2:	f022                	sd	s0,32(sp)
    80004ee4:	ec26                	sd	s1,24(sp)
    80004ee6:	e84a                	sd	s2,16(sp)
    80004ee8:	e44e                	sd	s3,8(sp)
    80004eea:	e052                	sd	s4,0(sp)
    80004eec:	1800                	addi	s0,sp,48
    80004eee:	84aa                	mv	s1,a0
    80004ef0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ef2:	0005b023          	sd	zero,0(a1)
    80004ef6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004efa:	00000097          	auipc	ra,0x0
    80004efe:	bf8080e7          	jalr	-1032(ra) # 80004af2 <filealloc>
    80004f02:	e088                	sd	a0,0(s1)
    80004f04:	c551                	beqz	a0,80004f90 <pipealloc+0xb2>
    80004f06:	00000097          	auipc	ra,0x0
    80004f0a:	bec080e7          	jalr	-1044(ra) # 80004af2 <filealloc>
    80004f0e:	00aa3023          	sd	a0,0(s4)
    80004f12:	c92d                	beqz	a0,80004f84 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f14:	ffffc097          	auipc	ra,0xffffc
    80004f18:	be0080e7          	jalr	-1056(ra) # 80000af4 <kalloc>
    80004f1c:	892a                	mv	s2,a0
    80004f1e:	c125                	beqz	a0,80004f7e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f20:	4985                	li	s3,1
    80004f22:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f26:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f2a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f2e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f32:	00004597          	auipc	a1,0x4
    80004f36:	83658593          	addi	a1,a1,-1994 # 80008768 <syscalls+0x278>
    80004f3a:	ffffc097          	auipc	ra,0xffffc
    80004f3e:	c1a080e7          	jalr	-998(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004f42:	609c                	ld	a5,0(s1)
    80004f44:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f48:	609c                	ld	a5,0(s1)
    80004f4a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f4e:	609c                	ld	a5,0(s1)
    80004f50:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f54:	609c                	ld	a5,0(s1)
    80004f56:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f5a:	000a3783          	ld	a5,0(s4)
    80004f5e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f62:	000a3783          	ld	a5,0(s4)
    80004f66:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f6a:	000a3783          	ld	a5,0(s4)
    80004f6e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f72:	000a3783          	ld	a5,0(s4)
    80004f76:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f7a:	4501                	li	a0,0
    80004f7c:	a025                	j	80004fa4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f7e:	6088                	ld	a0,0(s1)
    80004f80:	e501                	bnez	a0,80004f88 <pipealloc+0xaa>
    80004f82:	a039                	j	80004f90 <pipealloc+0xb2>
    80004f84:	6088                	ld	a0,0(s1)
    80004f86:	c51d                	beqz	a0,80004fb4 <pipealloc+0xd6>
    fileclose(*f0);
    80004f88:	00000097          	auipc	ra,0x0
    80004f8c:	c26080e7          	jalr	-986(ra) # 80004bae <fileclose>
  if(*f1)
    80004f90:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f94:	557d                	li	a0,-1
  if(*f1)
    80004f96:	c799                	beqz	a5,80004fa4 <pipealloc+0xc6>
    fileclose(*f1);
    80004f98:	853e                	mv	a0,a5
    80004f9a:	00000097          	auipc	ra,0x0
    80004f9e:	c14080e7          	jalr	-1004(ra) # 80004bae <fileclose>
  return -1;
    80004fa2:	557d                	li	a0,-1
}
    80004fa4:	70a2                	ld	ra,40(sp)
    80004fa6:	7402                	ld	s0,32(sp)
    80004fa8:	64e2                	ld	s1,24(sp)
    80004faa:	6942                	ld	s2,16(sp)
    80004fac:	69a2                	ld	s3,8(sp)
    80004fae:	6a02                	ld	s4,0(sp)
    80004fb0:	6145                	addi	sp,sp,48
    80004fb2:	8082                	ret
  return -1;
    80004fb4:	557d                	li	a0,-1
    80004fb6:	b7fd                	j	80004fa4 <pipealloc+0xc6>

0000000080004fb8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004fb8:	1101                	addi	sp,sp,-32
    80004fba:	ec06                	sd	ra,24(sp)
    80004fbc:	e822                	sd	s0,16(sp)
    80004fbe:	e426                	sd	s1,8(sp)
    80004fc0:	e04a                	sd	s2,0(sp)
    80004fc2:	1000                	addi	s0,sp,32
    80004fc4:	84aa                	mv	s1,a0
    80004fc6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004fc8:	ffffc097          	auipc	ra,0xffffc
    80004fcc:	c1c080e7          	jalr	-996(ra) # 80000be4 <acquire>
  if(writable){
    80004fd0:	02090d63          	beqz	s2,8000500a <pipeclose+0x52>
    pi->writeopen = 0;
    80004fd4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004fd8:	21848513          	addi	a0,s1,536
    80004fdc:	ffffd097          	auipc	ra,0xffffd
    80004fe0:	7ea080e7          	jalr	2026(ra) # 800027c6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004fe4:	2204b783          	ld	a5,544(s1)
    80004fe8:	eb95                	bnez	a5,8000501c <pipeclose+0x64>
    release(&pi->lock);
    80004fea:	8526                	mv	a0,s1
    80004fec:	ffffc097          	auipc	ra,0xffffc
    80004ff0:	cac080e7          	jalr	-852(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004ff4:	8526                	mv	a0,s1
    80004ff6:	ffffc097          	auipc	ra,0xffffc
    80004ffa:	a02080e7          	jalr	-1534(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004ffe:	60e2                	ld	ra,24(sp)
    80005000:	6442                	ld	s0,16(sp)
    80005002:	64a2                	ld	s1,8(sp)
    80005004:	6902                	ld	s2,0(sp)
    80005006:	6105                	addi	sp,sp,32
    80005008:	8082                	ret
    pi->readopen = 0;
    8000500a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000500e:	21c48513          	addi	a0,s1,540
    80005012:	ffffd097          	auipc	ra,0xffffd
    80005016:	7b4080e7          	jalr	1972(ra) # 800027c6 <wakeup>
    8000501a:	b7e9                	j	80004fe4 <pipeclose+0x2c>
    release(&pi->lock);
    8000501c:	8526                	mv	a0,s1
    8000501e:	ffffc097          	auipc	ra,0xffffc
    80005022:	c7a080e7          	jalr	-902(ra) # 80000c98 <release>
}
    80005026:	bfe1                	j	80004ffe <pipeclose+0x46>

0000000080005028 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005028:	7159                	addi	sp,sp,-112
    8000502a:	f486                	sd	ra,104(sp)
    8000502c:	f0a2                	sd	s0,96(sp)
    8000502e:	eca6                	sd	s1,88(sp)
    80005030:	e8ca                	sd	s2,80(sp)
    80005032:	e4ce                	sd	s3,72(sp)
    80005034:	e0d2                	sd	s4,64(sp)
    80005036:	fc56                	sd	s5,56(sp)
    80005038:	f85a                	sd	s6,48(sp)
    8000503a:	f45e                	sd	s7,40(sp)
    8000503c:	f062                	sd	s8,32(sp)
    8000503e:	ec66                	sd	s9,24(sp)
    80005040:	1880                	addi	s0,sp,112
    80005042:	84aa                	mv	s1,a0
    80005044:	8aae                	mv	s5,a1
    80005046:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005048:	ffffd097          	auipc	ra,0xffffd
    8000504c:	dcc080e7          	jalr	-564(ra) # 80001e14 <myproc>
    80005050:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005052:	8526                	mv	a0,s1
    80005054:	ffffc097          	auipc	ra,0xffffc
    80005058:	b90080e7          	jalr	-1136(ra) # 80000be4 <acquire>
  while(i < n){
    8000505c:	0d405163          	blez	s4,8000511e <pipewrite+0xf6>
    80005060:	8ba6                	mv	s7,s1
  int i = 0;
    80005062:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005064:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005066:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000506a:	21c48c13          	addi	s8,s1,540
    8000506e:	a08d                	j	800050d0 <pipewrite+0xa8>
      release(&pi->lock);
    80005070:	8526                	mv	a0,s1
    80005072:	ffffc097          	auipc	ra,0xffffc
    80005076:	c26080e7          	jalr	-986(ra) # 80000c98 <release>
      return -1;
    8000507a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000507c:	854a                	mv	a0,s2
    8000507e:	70a6                	ld	ra,104(sp)
    80005080:	7406                	ld	s0,96(sp)
    80005082:	64e6                	ld	s1,88(sp)
    80005084:	6946                	ld	s2,80(sp)
    80005086:	69a6                	ld	s3,72(sp)
    80005088:	6a06                	ld	s4,64(sp)
    8000508a:	7ae2                	ld	s5,56(sp)
    8000508c:	7b42                	ld	s6,48(sp)
    8000508e:	7ba2                	ld	s7,40(sp)
    80005090:	7c02                	ld	s8,32(sp)
    80005092:	6ce2                	ld	s9,24(sp)
    80005094:	6165                	addi	sp,sp,112
    80005096:	8082                	ret
      wakeup(&pi->nread);
    80005098:	8566                	mv	a0,s9
    8000509a:	ffffd097          	auipc	ra,0xffffd
    8000509e:	72c080e7          	jalr	1836(ra) # 800027c6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800050a2:	85de                	mv	a1,s7
    800050a4:	8562                	mv	a0,s8
    800050a6:	ffffd097          	auipc	ra,0xffffd
    800050aa:	582080e7          	jalr	1410(ra) # 80002628 <sleep>
    800050ae:	a839                	j	800050cc <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050b0:	21c4a783          	lw	a5,540(s1)
    800050b4:	0017871b          	addiw	a4,a5,1
    800050b8:	20e4ae23          	sw	a4,540(s1)
    800050bc:	1ff7f793          	andi	a5,a5,511
    800050c0:	97a6                	add	a5,a5,s1
    800050c2:	f9f44703          	lbu	a4,-97(s0)
    800050c6:	00e78c23          	sb	a4,24(a5)
      i++;
    800050ca:	2905                	addiw	s2,s2,1
  while(i < n){
    800050cc:	03495d63          	bge	s2,s4,80005106 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800050d0:	2204a783          	lw	a5,544(s1)
    800050d4:	dfd1                	beqz	a5,80005070 <pipewrite+0x48>
    800050d6:	0289a783          	lw	a5,40(s3)
    800050da:	fbd9                	bnez	a5,80005070 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800050dc:	2184a783          	lw	a5,536(s1)
    800050e0:	21c4a703          	lw	a4,540(s1)
    800050e4:	2007879b          	addiw	a5,a5,512
    800050e8:	faf708e3          	beq	a4,a5,80005098 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050ec:	4685                	li	a3,1
    800050ee:	01590633          	add	a2,s2,s5
    800050f2:	f9f40593          	addi	a1,s0,-97
    800050f6:	0509b503          	ld	a0,80(s3)
    800050fa:	ffffc097          	auipc	ra,0xffffc
    800050fe:	604080e7          	jalr	1540(ra) # 800016fe <copyin>
    80005102:	fb6517e3          	bne	a0,s6,800050b0 <pipewrite+0x88>
  wakeup(&pi->nread);
    80005106:	21848513          	addi	a0,s1,536
    8000510a:	ffffd097          	auipc	ra,0xffffd
    8000510e:	6bc080e7          	jalr	1724(ra) # 800027c6 <wakeup>
  release(&pi->lock);
    80005112:	8526                	mv	a0,s1
    80005114:	ffffc097          	auipc	ra,0xffffc
    80005118:	b84080e7          	jalr	-1148(ra) # 80000c98 <release>
  return i;
    8000511c:	b785                	j	8000507c <pipewrite+0x54>
  int i = 0;
    8000511e:	4901                	li	s2,0
    80005120:	b7dd                	j	80005106 <pipewrite+0xde>

0000000080005122 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005122:	715d                	addi	sp,sp,-80
    80005124:	e486                	sd	ra,72(sp)
    80005126:	e0a2                	sd	s0,64(sp)
    80005128:	fc26                	sd	s1,56(sp)
    8000512a:	f84a                	sd	s2,48(sp)
    8000512c:	f44e                	sd	s3,40(sp)
    8000512e:	f052                	sd	s4,32(sp)
    80005130:	ec56                	sd	s5,24(sp)
    80005132:	e85a                	sd	s6,16(sp)
    80005134:	0880                	addi	s0,sp,80
    80005136:	84aa                	mv	s1,a0
    80005138:	892e                	mv	s2,a1
    8000513a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000513c:	ffffd097          	auipc	ra,0xffffd
    80005140:	cd8080e7          	jalr	-808(ra) # 80001e14 <myproc>
    80005144:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005146:	8b26                	mv	s6,s1
    80005148:	8526                	mv	a0,s1
    8000514a:	ffffc097          	auipc	ra,0xffffc
    8000514e:	a9a080e7          	jalr	-1382(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005152:	2184a703          	lw	a4,536(s1)
    80005156:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000515a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000515e:	02f71463          	bne	a4,a5,80005186 <piperead+0x64>
    80005162:	2244a783          	lw	a5,548(s1)
    80005166:	c385                	beqz	a5,80005186 <piperead+0x64>
    if(pr->killed){
    80005168:	028a2783          	lw	a5,40(s4)
    8000516c:	ebc1                	bnez	a5,800051fc <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000516e:	85da                	mv	a1,s6
    80005170:	854e                	mv	a0,s3
    80005172:	ffffd097          	auipc	ra,0xffffd
    80005176:	4b6080e7          	jalr	1206(ra) # 80002628 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000517a:	2184a703          	lw	a4,536(s1)
    8000517e:	21c4a783          	lw	a5,540(s1)
    80005182:	fef700e3          	beq	a4,a5,80005162 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005186:	09505263          	blez	s5,8000520a <piperead+0xe8>
    8000518a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000518c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000518e:	2184a783          	lw	a5,536(s1)
    80005192:	21c4a703          	lw	a4,540(s1)
    80005196:	02f70d63          	beq	a4,a5,800051d0 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000519a:	0017871b          	addiw	a4,a5,1
    8000519e:	20e4ac23          	sw	a4,536(s1)
    800051a2:	1ff7f793          	andi	a5,a5,511
    800051a6:	97a6                	add	a5,a5,s1
    800051a8:	0187c783          	lbu	a5,24(a5)
    800051ac:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051b0:	4685                	li	a3,1
    800051b2:	fbf40613          	addi	a2,s0,-65
    800051b6:	85ca                	mv	a1,s2
    800051b8:	050a3503          	ld	a0,80(s4)
    800051bc:	ffffc097          	auipc	ra,0xffffc
    800051c0:	4b6080e7          	jalr	1206(ra) # 80001672 <copyout>
    800051c4:	01650663          	beq	a0,s6,800051d0 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051c8:	2985                	addiw	s3,s3,1
    800051ca:	0905                	addi	s2,s2,1
    800051cc:	fd3a91e3          	bne	s5,s3,8000518e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800051d0:	21c48513          	addi	a0,s1,540
    800051d4:	ffffd097          	auipc	ra,0xffffd
    800051d8:	5f2080e7          	jalr	1522(ra) # 800027c6 <wakeup>
  release(&pi->lock);
    800051dc:	8526                	mv	a0,s1
    800051de:	ffffc097          	auipc	ra,0xffffc
    800051e2:	aba080e7          	jalr	-1350(ra) # 80000c98 <release>
  return i;
}
    800051e6:	854e                	mv	a0,s3
    800051e8:	60a6                	ld	ra,72(sp)
    800051ea:	6406                	ld	s0,64(sp)
    800051ec:	74e2                	ld	s1,56(sp)
    800051ee:	7942                	ld	s2,48(sp)
    800051f0:	79a2                	ld	s3,40(sp)
    800051f2:	7a02                	ld	s4,32(sp)
    800051f4:	6ae2                	ld	s5,24(sp)
    800051f6:	6b42                	ld	s6,16(sp)
    800051f8:	6161                	addi	sp,sp,80
    800051fa:	8082                	ret
      release(&pi->lock);
    800051fc:	8526                	mv	a0,s1
    800051fe:	ffffc097          	auipc	ra,0xffffc
    80005202:	a9a080e7          	jalr	-1382(ra) # 80000c98 <release>
      return -1;
    80005206:	59fd                	li	s3,-1
    80005208:	bff9                	j	800051e6 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000520a:	4981                	li	s3,0
    8000520c:	b7d1                	j	800051d0 <piperead+0xae>

000000008000520e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000520e:	df010113          	addi	sp,sp,-528
    80005212:	20113423          	sd	ra,520(sp)
    80005216:	20813023          	sd	s0,512(sp)
    8000521a:	ffa6                	sd	s1,504(sp)
    8000521c:	fbca                	sd	s2,496(sp)
    8000521e:	f7ce                	sd	s3,488(sp)
    80005220:	f3d2                	sd	s4,480(sp)
    80005222:	efd6                	sd	s5,472(sp)
    80005224:	ebda                	sd	s6,464(sp)
    80005226:	e7de                	sd	s7,456(sp)
    80005228:	e3e2                	sd	s8,448(sp)
    8000522a:	ff66                	sd	s9,440(sp)
    8000522c:	fb6a                	sd	s10,432(sp)
    8000522e:	f76e                	sd	s11,424(sp)
    80005230:	0c00                	addi	s0,sp,528
    80005232:	84aa                	mv	s1,a0
    80005234:	dea43c23          	sd	a0,-520(s0)
    80005238:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000523c:	ffffd097          	auipc	ra,0xffffd
    80005240:	bd8080e7          	jalr	-1064(ra) # 80001e14 <myproc>
    80005244:	892a                	mv	s2,a0

  begin_op();
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	49c080e7          	jalr	1180(ra) # 800046e2 <begin_op>

  if((ip = namei(path)) == 0){
    8000524e:	8526                	mv	a0,s1
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	276080e7          	jalr	630(ra) # 800044c6 <namei>
    80005258:	c92d                	beqz	a0,800052ca <exec+0xbc>
    8000525a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000525c:	fffff097          	auipc	ra,0xfffff
    80005260:	ab4080e7          	jalr	-1356(ra) # 80003d10 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005264:	04000713          	li	a4,64
    80005268:	4681                	li	a3,0
    8000526a:	e5040613          	addi	a2,s0,-432
    8000526e:	4581                	li	a1,0
    80005270:	8526                	mv	a0,s1
    80005272:	fffff097          	auipc	ra,0xfffff
    80005276:	d52080e7          	jalr	-686(ra) # 80003fc4 <readi>
    8000527a:	04000793          	li	a5,64
    8000527e:	00f51a63          	bne	a0,a5,80005292 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005282:	e5042703          	lw	a4,-432(s0)
    80005286:	464c47b7          	lui	a5,0x464c4
    8000528a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000528e:	04f70463          	beq	a4,a5,800052d6 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005292:	8526                	mv	a0,s1
    80005294:	fffff097          	auipc	ra,0xfffff
    80005298:	cde080e7          	jalr	-802(ra) # 80003f72 <iunlockput>
    end_op();
    8000529c:	fffff097          	auipc	ra,0xfffff
    800052a0:	4c6080e7          	jalr	1222(ra) # 80004762 <end_op>
  }
  return -1;
    800052a4:	557d                	li	a0,-1
}
    800052a6:	20813083          	ld	ra,520(sp)
    800052aa:	20013403          	ld	s0,512(sp)
    800052ae:	74fe                	ld	s1,504(sp)
    800052b0:	795e                	ld	s2,496(sp)
    800052b2:	79be                	ld	s3,488(sp)
    800052b4:	7a1e                	ld	s4,480(sp)
    800052b6:	6afe                	ld	s5,472(sp)
    800052b8:	6b5e                	ld	s6,464(sp)
    800052ba:	6bbe                	ld	s7,456(sp)
    800052bc:	6c1e                	ld	s8,448(sp)
    800052be:	7cfa                	ld	s9,440(sp)
    800052c0:	7d5a                	ld	s10,432(sp)
    800052c2:	7dba                	ld	s11,424(sp)
    800052c4:	21010113          	addi	sp,sp,528
    800052c8:	8082                	ret
    end_op();
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	498080e7          	jalr	1176(ra) # 80004762 <end_op>
    return -1;
    800052d2:	557d                	li	a0,-1
    800052d4:	bfc9                	j	800052a6 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800052d6:	854a                	mv	a0,s2
    800052d8:	ffffd097          	auipc	ra,0xffffd
    800052dc:	bfa080e7          	jalr	-1030(ra) # 80001ed2 <proc_pagetable>
    800052e0:	8baa                	mv	s7,a0
    800052e2:	d945                	beqz	a0,80005292 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052e4:	e7042983          	lw	s3,-400(s0)
    800052e8:	e8845783          	lhu	a5,-376(s0)
    800052ec:	c7ad                	beqz	a5,80005356 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052ee:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052f0:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800052f2:	6c85                	lui	s9,0x1
    800052f4:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800052f8:	def43823          	sd	a5,-528(s0)
    800052fc:	a42d                	j	80005526 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800052fe:	00003517          	auipc	a0,0x3
    80005302:	47250513          	addi	a0,a0,1138 # 80008770 <syscalls+0x280>
    80005306:	ffffb097          	auipc	ra,0xffffb
    8000530a:	238080e7          	jalr	568(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000530e:	8756                	mv	a4,s5
    80005310:	012d86bb          	addw	a3,s11,s2
    80005314:	4581                	li	a1,0
    80005316:	8526                	mv	a0,s1
    80005318:	fffff097          	auipc	ra,0xfffff
    8000531c:	cac080e7          	jalr	-852(ra) # 80003fc4 <readi>
    80005320:	2501                	sext.w	a0,a0
    80005322:	1aaa9963          	bne	s5,a0,800054d4 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005326:	6785                	lui	a5,0x1
    80005328:	0127893b          	addw	s2,a5,s2
    8000532c:	77fd                	lui	a5,0xfffff
    8000532e:	01478a3b          	addw	s4,a5,s4
    80005332:	1f897163          	bgeu	s2,s8,80005514 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005336:	02091593          	slli	a1,s2,0x20
    8000533a:	9181                	srli	a1,a1,0x20
    8000533c:	95ea                	add	a1,a1,s10
    8000533e:	855e                	mv	a0,s7
    80005340:	ffffc097          	auipc	ra,0xffffc
    80005344:	d2e080e7          	jalr	-722(ra) # 8000106e <walkaddr>
    80005348:	862a                	mv	a2,a0
    if(pa == 0)
    8000534a:	d955                	beqz	a0,800052fe <exec+0xf0>
      n = PGSIZE;
    8000534c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000534e:	fd9a70e3          	bgeu	s4,s9,8000530e <exec+0x100>
      n = sz - i;
    80005352:	8ad2                	mv	s5,s4
    80005354:	bf6d                	j	8000530e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005356:	4901                	li	s2,0
  iunlockput(ip);
    80005358:	8526                	mv	a0,s1
    8000535a:	fffff097          	auipc	ra,0xfffff
    8000535e:	c18080e7          	jalr	-1000(ra) # 80003f72 <iunlockput>
  end_op();
    80005362:	fffff097          	auipc	ra,0xfffff
    80005366:	400080e7          	jalr	1024(ra) # 80004762 <end_op>
  p = myproc();
    8000536a:	ffffd097          	auipc	ra,0xffffd
    8000536e:	aaa080e7          	jalr	-1366(ra) # 80001e14 <myproc>
    80005372:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005374:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005378:	6785                	lui	a5,0x1
    8000537a:	17fd                	addi	a5,a5,-1
    8000537c:	993e                	add	s2,s2,a5
    8000537e:	757d                	lui	a0,0xfffff
    80005380:	00a977b3          	and	a5,s2,a0
    80005384:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005388:	6609                	lui	a2,0x2
    8000538a:	963e                	add	a2,a2,a5
    8000538c:	85be                	mv	a1,a5
    8000538e:	855e                	mv	a0,s7
    80005390:	ffffc097          	auipc	ra,0xffffc
    80005394:	092080e7          	jalr	146(ra) # 80001422 <uvmalloc>
    80005398:	8b2a                	mv	s6,a0
  ip = 0;
    8000539a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000539c:	12050c63          	beqz	a0,800054d4 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800053a0:	75f9                	lui	a1,0xffffe
    800053a2:	95aa                	add	a1,a1,a0
    800053a4:	855e                	mv	a0,s7
    800053a6:	ffffc097          	auipc	ra,0xffffc
    800053aa:	29a080e7          	jalr	666(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800053ae:	7c7d                	lui	s8,0xfffff
    800053b0:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800053b2:	e0043783          	ld	a5,-512(s0)
    800053b6:	6388                	ld	a0,0(a5)
    800053b8:	c535                	beqz	a0,80005424 <exec+0x216>
    800053ba:	e9040993          	addi	s3,s0,-368
    800053be:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800053c2:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800053c4:	ffffc097          	auipc	ra,0xffffc
    800053c8:	aa0080e7          	jalr	-1376(ra) # 80000e64 <strlen>
    800053cc:	2505                	addiw	a0,a0,1
    800053ce:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800053d2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800053d6:	13896363          	bltu	s2,s8,800054fc <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800053da:	e0043d83          	ld	s11,-512(s0)
    800053de:	000dba03          	ld	s4,0(s11)
    800053e2:	8552                	mv	a0,s4
    800053e4:	ffffc097          	auipc	ra,0xffffc
    800053e8:	a80080e7          	jalr	-1408(ra) # 80000e64 <strlen>
    800053ec:	0015069b          	addiw	a3,a0,1
    800053f0:	8652                	mv	a2,s4
    800053f2:	85ca                	mv	a1,s2
    800053f4:	855e                	mv	a0,s7
    800053f6:	ffffc097          	auipc	ra,0xffffc
    800053fa:	27c080e7          	jalr	636(ra) # 80001672 <copyout>
    800053fe:	10054363          	bltz	a0,80005504 <exec+0x2f6>
    ustack[argc] = sp;
    80005402:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005406:	0485                	addi	s1,s1,1
    80005408:	008d8793          	addi	a5,s11,8
    8000540c:	e0f43023          	sd	a5,-512(s0)
    80005410:	008db503          	ld	a0,8(s11)
    80005414:	c911                	beqz	a0,80005428 <exec+0x21a>
    if(argc >= MAXARG)
    80005416:	09a1                	addi	s3,s3,8
    80005418:	fb3c96e3          	bne	s9,s3,800053c4 <exec+0x1b6>
  sz = sz1;
    8000541c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005420:	4481                	li	s1,0
    80005422:	a84d                	j	800054d4 <exec+0x2c6>
  sp = sz;
    80005424:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005426:	4481                	li	s1,0
  ustack[argc] = 0;
    80005428:	00349793          	slli	a5,s1,0x3
    8000542c:	f9040713          	addi	a4,s0,-112
    80005430:	97ba                	add	a5,a5,a4
    80005432:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005436:	00148693          	addi	a3,s1,1
    8000543a:	068e                	slli	a3,a3,0x3
    8000543c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005440:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005444:	01897663          	bgeu	s2,s8,80005450 <exec+0x242>
  sz = sz1;
    80005448:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000544c:	4481                	li	s1,0
    8000544e:	a059                	j	800054d4 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005450:	e9040613          	addi	a2,s0,-368
    80005454:	85ca                	mv	a1,s2
    80005456:	855e                	mv	a0,s7
    80005458:	ffffc097          	auipc	ra,0xffffc
    8000545c:	21a080e7          	jalr	538(ra) # 80001672 <copyout>
    80005460:	0a054663          	bltz	a0,8000550c <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005464:	058ab783          	ld	a5,88(s5)
    80005468:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000546c:	df843783          	ld	a5,-520(s0)
    80005470:	0007c703          	lbu	a4,0(a5)
    80005474:	cf11                	beqz	a4,80005490 <exec+0x282>
    80005476:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005478:	02f00693          	li	a3,47
    8000547c:	a039                	j	8000548a <exec+0x27c>
      last = s+1;
    8000547e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005482:	0785                	addi	a5,a5,1
    80005484:	fff7c703          	lbu	a4,-1(a5)
    80005488:	c701                	beqz	a4,80005490 <exec+0x282>
    if(*s == '/')
    8000548a:	fed71ce3          	bne	a4,a3,80005482 <exec+0x274>
    8000548e:	bfc5                	j	8000547e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005490:	4641                	li	a2,16
    80005492:	df843583          	ld	a1,-520(s0)
    80005496:	158a8513          	addi	a0,s5,344
    8000549a:	ffffc097          	auipc	ra,0xffffc
    8000549e:	998080e7          	jalr	-1640(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800054a2:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800054a6:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800054aa:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800054ae:	058ab783          	ld	a5,88(s5)
    800054b2:	e6843703          	ld	a4,-408(s0)
    800054b6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800054b8:	058ab783          	ld	a5,88(s5)
    800054bc:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054c0:	85ea                	mv	a1,s10
    800054c2:	ffffd097          	auipc	ra,0xffffd
    800054c6:	aac080e7          	jalr	-1364(ra) # 80001f6e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800054ca:	0004851b          	sext.w	a0,s1
    800054ce:	bbe1                	j	800052a6 <exec+0x98>
    800054d0:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800054d4:	e0843583          	ld	a1,-504(s0)
    800054d8:	855e                	mv	a0,s7
    800054da:	ffffd097          	auipc	ra,0xffffd
    800054de:	a94080e7          	jalr	-1388(ra) # 80001f6e <proc_freepagetable>
  if(ip){
    800054e2:	da0498e3          	bnez	s1,80005292 <exec+0x84>
  return -1;
    800054e6:	557d                	li	a0,-1
    800054e8:	bb7d                	j	800052a6 <exec+0x98>
    800054ea:	e1243423          	sd	s2,-504(s0)
    800054ee:	b7dd                	j	800054d4 <exec+0x2c6>
    800054f0:	e1243423          	sd	s2,-504(s0)
    800054f4:	b7c5                	j	800054d4 <exec+0x2c6>
    800054f6:	e1243423          	sd	s2,-504(s0)
    800054fa:	bfe9                	j	800054d4 <exec+0x2c6>
  sz = sz1;
    800054fc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005500:	4481                	li	s1,0
    80005502:	bfc9                	j	800054d4 <exec+0x2c6>
  sz = sz1;
    80005504:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005508:	4481                	li	s1,0
    8000550a:	b7e9                	j	800054d4 <exec+0x2c6>
  sz = sz1;
    8000550c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005510:	4481                	li	s1,0
    80005512:	b7c9                	j	800054d4 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005514:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005518:	2b05                	addiw	s6,s6,1
    8000551a:	0389899b          	addiw	s3,s3,56
    8000551e:	e8845783          	lhu	a5,-376(s0)
    80005522:	e2fb5be3          	bge	s6,a5,80005358 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005526:	2981                	sext.w	s3,s3
    80005528:	03800713          	li	a4,56
    8000552c:	86ce                	mv	a3,s3
    8000552e:	e1840613          	addi	a2,s0,-488
    80005532:	4581                	li	a1,0
    80005534:	8526                	mv	a0,s1
    80005536:	fffff097          	auipc	ra,0xfffff
    8000553a:	a8e080e7          	jalr	-1394(ra) # 80003fc4 <readi>
    8000553e:	03800793          	li	a5,56
    80005542:	f8f517e3          	bne	a0,a5,800054d0 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005546:	e1842783          	lw	a5,-488(s0)
    8000554a:	4705                	li	a4,1
    8000554c:	fce796e3          	bne	a5,a4,80005518 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005550:	e4043603          	ld	a2,-448(s0)
    80005554:	e3843783          	ld	a5,-456(s0)
    80005558:	f8f669e3          	bltu	a2,a5,800054ea <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000555c:	e2843783          	ld	a5,-472(s0)
    80005560:	963e                	add	a2,a2,a5
    80005562:	f8f667e3          	bltu	a2,a5,800054f0 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005566:	85ca                	mv	a1,s2
    80005568:	855e                	mv	a0,s7
    8000556a:	ffffc097          	auipc	ra,0xffffc
    8000556e:	eb8080e7          	jalr	-328(ra) # 80001422 <uvmalloc>
    80005572:	e0a43423          	sd	a0,-504(s0)
    80005576:	d141                	beqz	a0,800054f6 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005578:	e2843d03          	ld	s10,-472(s0)
    8000557c:	df043783          	ld	a5,-528(s0)
    80005580:	00fd77b3          	and	a5,s10,a5
    80005584:	fba1                	bnez	a5,800054d4 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005586:	e2042d83          	lw	s11,-480(s0)
    8000558a:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000558e:	f80c03e3          	beqz	s8,80005514 <exec+0x306>
    80005592:	8a62                	mv	s4,s8
    80005594:	4901                	li	s2,0
    80005596:	b345                	j	80005336 <exec+0x128>

0000000080005598 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005598:	7179                	addi	sp,sp,-48
    8000559a:	f406                	sd	ra,40(sp)
    8000559c:	f022                	sd	s0,32(sp)
    8000559e:	ec26                	sd	s1,24(sp)
    800055a0:	e84a                	sd	s2,16(sp)
    800055a2:	1800                	addi	s0,sp,48
    800055a4:	892e                	mv	s2,a1
    800055a6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800055a8:	fdc40593          	addi	a1,s0,-36
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	bf2080e7          	jalr	-1038(ra) # 8000319e <argint>
    800055b4:	04054063          	bltz	a0,800055f4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800055b8:	fdc42703          	lw	a4,-36(s0)
    800055bc:	47bd                	li	a5,15
    800055be:	02e7ed63          	bltu	a5,a4,800055f8 <argfd+0x60>
    800055c2:	ffffd097          	auipc	ra,0xffffd
    800055c6:	852080e7          	jalr	-1966(ra) # 80001e14 <myproc>
    800055ca:	fdc42703          	lw	a4,-36(s0)
    800055ce:	01a70793          	addi	a5,a4,26
    800055d2:	078e                	slli	a5,a5,0x3
    800055d4:	953e                	add	a0,a0,a5
    800055d6:	611c                	ld	a5,0(a0)
    800055d8:	c395                	beqz	a5,800055fc <argfd+0x64>
    return -1;
  if(pfd)
    800055da:	00090463          	beqz	s2,800055e2 <argfd+0x4a>
    *pfd = fd;
    800055de:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800055e2:	4501                	li	a0,0
  if(pf)
    800055e4:	c091                	beqz	s1,800055e8 <argfd+0x50>
    *pf = f;
    800055e6:	e09c                	sd	a5,0(s1)
}
    800055e8:	70a2                	ld	ra,40(sp)
    800055ea:	7402                	ld	s0,32(sp)
    800055ec:	64e2                	ld	s1,24(sp)
    800055ee:	6942                	ld	s2,16(sp)
    800055f0:	6145                	addi	sp,sp,48
    800055f2:	8082                	ret
    return -1;
    800055f4:	557d                	li	a0,-1
    800055f6:	bfcd                	j	800055e8 <argfd+0x50>
    return -1;
    800055f8:	557d                	li	a0,-1
    800055fa:	b7fd                	j	800055e8 <argfd+0x50>
    800055fc:	557d                	li	a0,-1
    800055fe:	b7ed                	j	800055e8 <argfd+0x50>

0000000080005600 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005600:	1101                	addi	sp,sp,-32
    80005602:	ec06                	sd	ra,24(sp)
    80005604:	e822                	sd	s0,16(sp)
    80005606:	e426                	sd	s1,8(sp)
    80005608:	1000                	addi	s0,sp,32
    8000560a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000560c:	ffffd097          	auipc	ra,0xffffd
    80005610:	808080e7          	jalr	-2040(ra) # 80001e14 <myproc>
    80005614:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005616:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000561a:	4501                	li	a0,0
    8000561c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000561e:	6398                	ld	a4,0(a5)
    80005620:	cb19                	beqz	a4,80005636 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005622:	2505                	addiw	a0,a0,1
    80005624:	07a1                	addi	a5,a5,8
    80005626:	fed51ce3          	bne	a0,a3,8000561e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000562a:	557d                	li	a0,-1
}
    8000562c:	60e2                	ld	ra,24(sp)
    8000562e:	6442                	ld	s0,16(sp)
    80005630:	64a2                	ld	s1,8(sp)
    80005632:	6105                	addi	sp,sp,32
    80005634:	8082                	ret
      p->ofile[fd] = f;
    80005636:	01a50793          	addi	a5,a0,26
    8000563a:	078e                	slli	a5,a5,0x3
    8000563c:	963e                	add	a2,a2,a5
    8000563e:	e204                	sd	s1,0(a2)
      return fd;
    80005640:	b7f5                	j	8000562c <fdalloc+0x2c>

0000000080005642 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005642:	715d                	addi	sp,sp,-80
    80005644:	e486                	sd	ra,72(sp)
    80005646:	e0a2                	sd	s0,64(sp)
    80005648:	fc26                	sd	s1,56(sp)
    8000564a:	f84a                	sd	s2,48(sp)
    8000564c:	f44e                	sd	s3,40(sp)
    8000564e:	f052                	sd	s4,32(sp)
    80005650:	ec56                	sd	s5,24(sp)
    80005652:	0880                	addi	s0,sp,80
    80005654:	89ae                	mv	s3,a1
    80005656:	8ab2                	mv	s5,a2
    80005658:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000565a:	fb040593          	addi	a1,s0,-80
    8000565e:	fffff097          	auipc	ra,0xfffff
    80005662:	e86080e7          	jalr	-378(ra) # 800044e4 <nameiparent>
    80005666:	892a                	mv	s2,a0
    80005668:	12050f63          	beqz	a0,800057a6 <create+0x164>
    return 0;

  ilock(dp);
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	6a4080e7          	jalr	1700(ra) # 80003d10 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005674:	4601                	li	a2,0
    80005676:	fb040593          	addi	a1,s0,-80
    8000567a:	854a                	mv	a0,s2
    8000567c:	fffff097          	auipc	ra,0xfffff
    80005680:	b78080e7          	jalr	-1160(ra) # 800041f4 <dirlookup>
    80005684:	84aa                	mv	s1,a0
    80005686:	c921                	beqz	a0,800056d6 <create+0x94>
    iunlockput(dp);
    80005688:	854a                	mv	a0,s2
    8000568a:	fffff097          	auipc	ra,0xfffff
    8000568e:	8e8080e7          	jalr	-1816(ra) # 80003f72 <iunlockput>
    ilock(ip);
    80005692:	8526                	mv	a0,s1
    80005694:	ffffe097          	auipc	ra,0xffffe
    80005698:	67c080e7          	jalr	1660(ra) # 80003d10 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000569c:	2981                	sext.w	s3,s3
    8000569e:	4789                	li	a5,2
    800056a0:	02f99463          	bne	s3,a5,800056c8 <create+0x86>
    800056a4:	0444d783          	lhu	a5,68(s1)
    800056a8:	37f9                	addiw	a5,a5,-2
    800056aa:	17c2                	slli	a5,a5,0x30
    800056ac:	93c1                	srli	a5,a5,0x30
    800056ae:	4705                	li	a4,1
    800056b0:	00f76c63          	bltu	a4,a5,800056c8 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800056b4:	8526                	mv	a0,s1
    800056b6:	60a6                	ld	ra,72(sp)
    800056b8:	6406                	ld	s0,64(sp)
    800056ba:	74e2                	ld	s1,56(sp)
    800056bc:	7942                	ld	s2,48(sp)
    800056be:	79a2                	ld	s3,40(sp)
    800056c0:	7a02                	ld	s4,32(sp)
    800056c2:	6ae2                	ld	s5,24(sp)
    800056c4:	6161                	addi	sp,sp,80
    800056c6:	8082                	ret
    iunlockput(ip);
    800056c8:	8526                	mv	a0,s1
    800056ca:	fffff097          	auipc	ra,0xfffff
    800056ce:	8a8080e7          	jalr	-1880(ra) # 80003f72 <iunlockput>
    return 0;
    800056d2:	4481                	li	s1,0
    800056d4:	b7c5                	j	800056b4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800056d6:	85ce                	mv	a1,s3
    800056d8:	00092503          	lw	a0,0(s2)
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	49c080e7          	jalr	1180(ra) # 80003b78 <ialloc>
    800056e4:	84aa                	mv	s1,a0
    800056e6:	c529                	beqz	a0,80005730 <create+0xee>
  ilock(ip);
    800056e8:	ffffe097          	auipc	ra,0xffffe
    800056ec:	628080e7          	jalr	1576(ra) # 80003d10 <ilock>
  ip->major = major;
    800056f0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800056f4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800056f8:	4785                	li	a5,1
    800056fa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056fe:	8526                	mv	a0,s1
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	546080e7          	jalr	1350(ra) # 80003c46 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005708:	2981                	sext.w	s3,s3
    8000570a:	4785                	li	a5,1
    8000570c:	02f98a63          	beq	s3,a5,80005740 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005710:	40d0                	lw	a2,4(s1)
    80005712:	fb040593          	addi	a1,s0,-80
    80005716:	854a                	mv	a0,s2
    80005718:	fffff097          	auipc	ra,0xfffff
    8000571c:	cec080e7          	jalr	-788(ra) # 80004404 <dirlink>
    80005720:	06054b63          	bltz	a0,80005796 <create+0x154>
  iunlockput(dp);
    80005724:	854a                	mv	a0,s2
    80005726:	fffff097          	auipc	ra,0xfffff
    8000572a:	84c080e7          	jalr	-1972(ra) # 80003f72 <iunlockput>
  return ip;
    8000572e:	b759                	j	800056b4 <create+0x72>
    panic("create: ialloc");
    80005730:	00003517          	auipc	a0,0x3
    80005734:	06050513          	addi	a0,a0,96 # 80008790 <syscalls+0x2a0>
    80005738:	ffffb097          	auipc	ra,0xffffb
    8000573c:	e06080e7          	jalr	-506(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005740:	04a95783          	lhu	a5,74(s2)
    80005744:	2785                	addiw	a5,a5,1
    80005746:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000574a:	854a                	mv	a0,s2
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	4fa080e7          	jalr	1274(ra) # 80003c46 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005754:	40d0                	lw	a2,4(s1)
    80005756:	00003597          	auipc	a1,0x3
    8000575a:	04a58593          	addi	a1,a1,74 # 800087a0 <syscalls+0x2b0>
    8000575e:	8526                	mv	a0,s1
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	ca4080e7          	jalr	-860(ra) # 80004404 <dirlink>
    80005768:	00054f63          	bltz	a0,80005786 <create+0x144>
    8000576c:	00492603          	lw	a2,4(s2)
    80005770:	00003597          	auipc	a1,0x3
    80005774:	03858593          	addi	a1,a1,56 # 800087a8 <syscalls+0x2b8>
    80005778:	8526                	mv	a0,s1
    8000577a:	fffff097          	auipc	ra,0xfffff
    8000577e:	c8a080e7          	jalr	-886(ra) # 80004404 <dirlink>
    80005782:	f80557e3          	bgez	a0,80005710 <create+0xce>
      panic("create dots");
    80005786:	00003517          	auipc	a0,0x3
    8000578a:	02a50513          	addi	a0,a0,42 # 800087b0 <syscalls+0x2c0>
    8000578e:	ffffb097          	auipc	ra,0xffffb
    80005792:	db0080e7          	jalr	-592(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005796:	00003517          	auipc	a0,0x3
    8000579a:	02a50513          	addi	a0,a0,42 # 800087c0 <syscalls+0x2d0>
    8000579e:	ffffb097          	auipc	ra,0xffffb
    800057a2:	da0080e7          	jalr	-608(ra) # 8000053e <panic>
    return 0;
    800057a6:	84aa                	mv	s1,a0
    800057a8:	b731                	j	800056b4 <create+0x72>

00000000800057aa <sys_dup>:
{
    800057aa:	7179                	addi	sp,sp,-48
    800057ac:	f406                	sd	ra,40(sp)
    800057ae:	f022                	sd	s0,32(sp)
    800057b0:	ec26                	sd	s1,24(sp)
    800057b2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800057b4:	fd840613          	addi	a2,s0,-40
    800057b8:	4581                	li	a1,0
    800057ba:	4501                	li	a0,0
    800057bc:	00000097          	auipc	ra,0x0
    800057c0:	ddc080e7          	jalr	-548(ra) # 80005598 <argfd>
    return -1;
    800057c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800057c6:	02054363          	bltz	a0,800057ec <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800057ca:	fd843503          	ld	a0,-40(s0)
    800057ce:	00000097          	auipc	ra,0x0
    800057d2:	e32080e7          	jalr	-462(ra) # 80005600 <fdalloc>
    800057d6:	84aa                	mv	s1,a0
    return -1;
    800057d8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800057da:	00054963          	bltz	a0,800057ec <sys_dup+0x42>
  filedup(f);
    800057de:	fd843503          	ld	a0,-40(s0)
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	37a080e7          	jalr	890(ra) # 80004b5c <filedup>
  return fd;
    800057ea:	87a6                	mv	a5,s1
}
    800057ec:	853e                	mv	a0,a5
    800057ee:	70a2                	ld	ra,40(sp)
    800057f0:	7402                	ld	s0,32(sp)
    800057f2:	64e2                	ld	s1,24(sp)
    800057f4:	6145                	addi	sp,sp,48
    800057f6:	8082                	ret

00000000800057f8 <sys_read>:
{
    800057f8:	7179                	addi	sp,sp,-48
    800057fa:	f406                	sd	ra,40(sp)
    800057fc:	f022                	sd	s0,32(sp)
    800057fe:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005800:	fe840613          	addi	a2,s0,-24
    80005804:	4581                	li	a1,0
    80005806:	4501                	li	a0,0
    80005808:	00000097          	auipc	ra,0x0
    8000580c:	d90080e7          	jalr	-624(ra) # 80005598 <argfd>
    return -1;
    80005810:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005812:	04054163          	bltz	a0,80005854 <sys_read+0x5c>
    80005816:	fe440593          	addi	a1,s0,-28
    8000581a:	4509                	li	a0,2
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	982080e7          	jalr	-1662(ra) # 8000319e <argint>
    return -1;
    80005824:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005826:	02054763          	bltz	a0,80005854 <sys_read+0x5c>
    8000582a:	fd840593          	addi	a1,s0,-40
    8000582e:	4505                	li	a0,1
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	990080e7          	jalr	-1648(ra) # 800031c0 <argaddr>
    return -1;
    80005838:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000583a:	00054d63          	bltz	a0,80005854 <sys_read+0x5c>
  return fileread(f, p, n);
    8000583e:	fe442603          	lw	a2,-28(s0)
    80005842:	fd843583          	ld	a1,-40(s0)
    80005846:	fe843503          	ld	a0,-24(s0)
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	49e080e7          	jalr	1182(ra) # 80004ce8 <fileread>
    80005852:	87aa                	mv	a5,a0
}
    80005854:	853e                	mv	a0,a5
    80005856:	70a2                	ld	ra,40(sp)
    80005858:	7402                	ld	s0,32(sp)
    8000585a:	6145                	addi	sp,sp,48
    8000585c:	8082                	ret

000000008000585e <sys_write>:
{
    8000585e:	7179                	addi	sp,sp,-48
    80005860:	f406                	sd	ra,40(sp)
    80005862:	f022                	sd	s0,32(sp)
    80005864:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005866:	fe840613          	addi	a2,s0,-24
    8000586a:	4581                	li	a1,0
    8000586c:	4501                	li	a0,0
    8000586e:	00000097          	auipc	ra,0x0
    80005872:	d2a080e7          	jalr	-726(ra) # 80005598 <argfd>
    return -1;
    80005876:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005878:	04054163          	bltz	a0,800058ba <sys_write+0x5c>
    8000587c:	fe440593          	addi	a1,s0,-28
    80005880:	4509                	li	a0,2
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	91c080e7          	jalr	-1764(ra) # 8000319e <argint>
    return -1;
    8000588a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000588c:	02054763          	bltz	a0,800058ba <sys_write+0x5c>
    80005890:	fd840593          	addi	a1,s0,-40
    80005894:	4505                	li	a0,1
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	92a080e7          	jalr	-1750(ra) # 800031c0 <argaddr>
    return -1;
    8000589e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058a0:	00054d63          	bltz	a0,800058ba <sys_write+0x5c>
  return filewrite(f, p, n);
    800058a4:	fe442603          	lw	a2,-28(s0)
    800058a8:	fd843583          	ld	a1,-40(s0)
    800058ac:	fe843503          	ld	a0,-24(s0)
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	4fa080e7          	jalr	1274(ra) # 80004daa <filewrite>
    800058b8:	87aa                	mv	a5,a0
}
    800058ba:	853e                	mv	a0,a5
    800058bc:	70a2                	ld	ra,40(sp)
    800058be:	7402                	ld	s0,32(sp)
    800058c0:	6145                	addi	sp,sp,48
    800058c2:	8082                	ret

00000000800058c4 <sys_close>:
{
    800058c4:	1101                	addi	sp,sp,-32
    800058c6:	ec06                	sd	ra,24(sp)
    800058c8:	e822                	sd	s0,16(sp)
    800058ca:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800058cc:	fe040613          	addi	a2,s0,-32
    800058d0:	fec40593          	addi	a1,s0,-20
    800058d4:	4501                	li	a0,0
    800058d6:	00000097          	auipc	ra,0x0
    800058da:	cc2080e7          	jalr	-830(ra) # 80005598 <argfd>
    return -1;
    800058de:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800058e0:	02054463          	bltz	a0,80005908 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800058e4:	ffffc097          	auipc	ra,0xffffc
    800058e8:	530080e7          	jalr	1328(ra) # 80001e14 <myproc>
    800058ec:	fec42783          	lw	a5,-20(s0)
    800058f0:	07e9                	addi	a5,a5,26
    800058f2:	078e                	slli	a5,a5,0x3
    800058f4:	97aa                	add	a5,a5,a0
    800058f6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800058fa:	fe043503          	ld	a0,-32(s0)
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	2b0080e7          	jalr	688(ra) # 80004bae <fileclose>
  return 0;
    80005906:	4781                	li	a5,0
}
    80005908:	853e                	mv	a0,a5
    8000590a:	60e2                	ld	ra,24(sp)
    8000590c:	6442                	ld	s0,16(sp)
    8000590e:	6105                	addi	sp,sp,32
    80005910:	8082                	ret

0000000080005912 <sys_fstat>:
{
    80005912:	1101                	addi	sp,sp,-32
    80005914:	ec06                	sd	ra,24(sp)
    80005916:	e822                	sd	s0,16(sp)
    80005918:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000591a:	fe840613          	addi	a2,s0,-24
    8000591e:	4581                	li	a1,0
    80005920:	4501                	li	a0,0
    80005922:	00000097          	auipc	ra,0x0
    80005926:	c76080e7          	jalr	-906(ra) # 80005598 <argfd>
    return -1;
    8000592a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000592c:	02054563          	bltz	a0,80005956 <sys_fstat+0x44>
    80005930:	fe040593          	addi	a1,s0,-32
    80005934:	4505                	li	a0,1
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	88a080e7          	jalr	-1910(ra) # 800031c0 <argaddr>
    return -1;
    8000593e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005940:	00054b63          	bltz	a0,80005956 <sys_fstat+0x44>
  return filestat(f, st);
    80005944:	fe043583          	ld	a1,-32(s0)
    80005948:	fe843503          	ld	a0,-24(s0)
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	32a080e7          	jalr	810(ra) # 80004c76 <filestat>
    80005954:	87aa                	mv	a5,a0
}
    80005956:	853e                	mv	a0,a5
    80005958:	60e2                	ld	ra,24(sp)
    8000595a:	6442                	ld	s0,16(sp)
    8000595c:	6105                	addi	sp,sp,32
    8000595e:	8082                	ret

0000000080005960 <sys_link>:
{
    80005960:	7169                	addi	sp,sp,-304
    80005962:	f606                	sd	ra,296(sp)
    80005964:	f222                	sd	s0,288(sp)
    80005966:	ee26                	sd	s1,280(sp)
    80005968:	ea4a                	sd	s2,272(sp)
    8000596a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000596c:	08000613          	li	a2,128
    80005970:	ed040593          	addi	a1,s0,-304
    80005974:	4501                	li	a0,0
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	86c080e7          	jalr	-1940(ra) # 800031e2 <argstr>
    return -1;
    8000597e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005980:	10054e63          	bltz	a0,80005a9c <sys_link+0x13c>
    80005984:	08000613          	li	a2,128
    80005988:	f5040593          	addi	a1,s0,-176
    8000598c:	4505                	li	a0,1
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	854080e7          	jalr	-1964(ra) # 800031e2 <argstr>
    return -1;
    80005996:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005998:	10054263          	bltz	a0,80005a9c <sys_link+0x13c>
  begin_op();
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	d46080e7          	jalr	-698(ra) # 800046e2 <begin_op>
  if((ip = namei(old)) == 0){
    800059a4:	ed040513          	addi	a0,s0,-304
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	b1e080e7          	jalr	-1250(ra) # 800044c6 <namei>
    800059b0:	84aa                	mv	s1,a0
    800059b2:	c551                	beqz	a0,80005a3e <sys_link+0xde>
  ilock(ip);
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	35c080e7          	jalr	860(ra) # 80003d10 <ilock>
  if(ip->type == T_DIR){
    800059bc:	04449703          	lh	a4,68(s1)
    800059c0:	4785                	li	a5,1
    800059c2:	08f70463          	beq	a4,a5,80005a4a <sys_link+0xea>
  ip->nlink++;
    800059c6:	04a4d783          	lhu	a5,74(s1)
    800059ca:	2785                	addiw	a5,a5,1
    800059cc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059d0:	8526                	mv	a0,s1
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	274080e7          	jalr	628(ra) # 80003c46 <iupdate>
  iunlock(ip);
    800059da:	8526                	mv	a0,s1
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	3f6080e7          	jalr	1014(ra) # 80003dd2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800059e4:	fd040593          	addi	a1,s0,-48
    800059e8:	f5040513          	addi	a0,s0,-176
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	af8080e7          	jalr	-1288(ra) # 800044e4 <nameiparent>
    800059f4:	892a                	mv	s2,a0
    800059f6:	c935                	beqz	a0,80005a6a <sys_link+0x10a>
  ilock(dp);
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	318080e7          	jalr	792(ra) # 80003d10 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a00:	00092703          	lw	a4,0(s2)
    80005a04:	409c                	lw	a5,0(s1)
    80005a06:	04f71d63          	bne	a4,a5,80005a60 <sys_link+0x100>
    80005a0a:	40d0                	lw	a2,4(s1)
    80005a0c:	fd040593          	addi	a1,s0,-48
    80005a10:	854a                	mv	a0,s2
    80005a12:	fffff097          	auipc	ra,0xfffff
    80005a16:	9f2080e7          	jalr	-1550(ra) # 80004404 <dirlink>
    80005a1a:	04054363          	bltz	a0,80005a60 <sys_link+0x100>
  iunlockput(dp);
    80005a1e:	854a                	mv	a0,s2
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	552080e7          	jalr	1362(ra) # 80003f72 <iunlockput>
  iput(ip);
    80005a28:	8526                	mv	a0,s1
    80005a2a:	ffffe097          	auipc	ra,0xffffe
    80005a2e:	4a0080e7          	jalr	1184(ra) # 80003eca <iput>
  end_op();
    80005a32:	fffff097          	auipc	ra,0xfffff
    80005a36:	d30080e7          	jalr	-720(ra) # 80004762 <end_op>
  return 0;
    80005a3a:	4781                	li	a5,0
    80005a3c:	a085                	j	80005a9c <sys_link+0x13c>
    end_op();
    80005a3e:	fffff097          	auipc	ra,0xfffff
    80005a42:	d24080e7          	jalr	-732(ra) # 80004762 <end_op>
    return -1;
    80005a46:	57fd                	li	a5,-1
    80005a48:	a891                	j	80005a9c <sys_link+0x13c>
    iunlockput(ip);
    80005a4a:	8526                	mv	a0,s1
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	526080e7          	jalr	1318(ra) # 80003f72 <iunlockput>
    end_op();
    80005a54:	fffff097          	auipc	ra,0xfffff
    80005a58:	d0e080e7          	jalr	-754(ra) # 80004762 <end_op>
    return -1;
    80005a5c:	57fd                	li	a5,-1
    80005a5e:	a83d                	j	80005a9c <sys_link+0x13c>
    iunlockput(dp);
    80005a60:	854a                	mv	a0,s2
    80005a62:	ffffe097          	auipc	ra,0xffffe
    80005a66:	510080e7          	jalr	1296(ra) # 80003f72 <iunlockput>
  ilock(ip);
    80005a6a:	8526                	mv	a0,s1
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	2a4080e7          	jalr	676(ra) # 80003d10 <ilock>
  ip->nlink--;
    80005a74:	04a4d783          	lhu	a5,74(s1)
    80005a78:	37fd                	addiw	a5,a5,-1
    80005a7a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a7e:	8526                	mv	a0,s1
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	1c6080e7          	jalr	454(ra) # 80003c46 <iupdate>
  iunlockput(ip);
    80005a88:	8526                	mv	a0,s1
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	4e8080e7          	jalr	1256(ra) # 80003f72 <iunlockput>
  end_op();
    80005a92:	fffff097          	auipc	ra,0xfffff
    80005a96:	cd0080e7          	jalr	-816(ra) # 80004762 <end_op>
  return -1;
    80005a9a:	57fd                	li	a5,-1
}
    80005a9c:	853e                	mv	a0,a5
    80005a9e:	70b2                	ld	ra,296(sp)
    80005aa0:	7412                	ld	s0,288(sp)
    80005aa2:	64f2                	ld	s1,280(sp)
    80005aa4:	6952                	ld	s2,272(sp)
    80005aa6:	6155                	addi	sp,sp,304
    80005aa8:	8082                	ret

0000000080005aaa <sys_unlink>:
{
    80005aaa:	7151                	addi	sp,sp,-240
    80005aac:	f586                	sd	ra,232(sp)
    80005aae:	f1a2                	sd	s0,224(sp)
    80005ab0:	eda6                	sd	s1,216(sp)
    80005ab2:	e9ca                	sd	s2,208(sp)
    80005ab4:	e5ce                	sd	s3,200(sp)
    80005ab6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005ab8:	08000613          	li	a2,128
    80005abc:	f3040593          	addi	a1,s0,-208
    80005ac0:	4501                	li	a0,0
    80005ac2:	ffffd097          	auipc	ra,0xffffd
    80005ac6:	720080e7          	jalr	1824(ra) # 800031e2 <argstr>
    80005aca:	18054163          	bltz	a0,80005c4c <sys_unlink+0x1a2>
  begin_op();
    80005ace:	fffff097          	auipc	ra,0xfffff
    80005ad2:	c14080e7          	jalr	-1004(ra) # 800046e2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005ad6:	fb040593          	addi	a1,s0,-80
    80005ada:	f3040513          	addi	a0,s0,-208
    80005ade:	fffff097          	auipc	ra,0xfffff
    80005ae2:	a06080e7          	jalr	-1530(ra) # 800044e4 <nameiparent>
    80005ae6:	84aa                	mv	s1,a0
    80005ae8:	c979                	beqz	a0,80005bbe <sys_unlink+0x114>
  ilock(dp);
    80005aea:	ffffe097          	auipc	ra,0xffffe
    80005aee:	226080e7          	jalr	550(ra) # 80003d10 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005af2:	00003597          	auipc	a1,0x3
    80005af6:	cae58593          	addi	a1,a1,-850 # 800087a0 <syscalls+0x2b0>
    80005afa:	fb040513          	addi	a0,s0,-80
    80005afe:	ffffe097          	auipc	ra,0xffffe
    80005b02:	6dc080e7          	jalr	1756(ra) # 800041da <namecmp>
    80005b06:	14050a63          	beqz	a0,80005c5a <sys_unlink+0x1b0>
    80005b0a:	00003597          	auipc	a1,0x3
    80005b0e:	c9e58593          	addi	a1,a1,-866 # 800087a8 <syscalls+0x2b8>
    80005b12:	fb040513          	addi	a0,s0,-80
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	6c4080e7          	jalr	1732(ra) # 800041da <namecmp>
    80005b1e:	12050e63          	beqz	a0,80005c5a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b22:	f2c40613          	addi	a2,s0,-212
    80005b26:	fb040593          	addi	a1,s0,-80
    80005b2a:	8526                	mv	a0,s1
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	6c8080e7          	jalr	1736(ra) # 800041f4 <dirlookup>
    80005b34:	892a                	mv	s2,a0
    80005b36:	12050263          	beqz	a0,80005c5a <sys_unlink+0x1b0>
  ilock(ip);
    80005b3a:	ffffe097          	auipc	ra,0xffffe
    80005b3e:	1d6080e7          	jalr	470(ra) # 80003d10 <ilock>
  if(ip->nlink < 1)
    80005b42:	04a91783          	lh	a5,74(s2)
    80005b46:	08f05263          	blez	a5,80005bca <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b4a:	04491703          	lh	a4,68(s2)
    80005b4e:	4785                	li	a5,1
    80005b50:	08f70563          	beq	a4,a5,80005bda <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b54:	4641                	li	a2,16
    80005b56:	4581                	li	a1,0
    80005b58:	fc040513          	addi	a0,s0,-64
    80005b5c:	ffffb097          	auipc	ra,0xffffb
    80005b60:	184080e7          	jalr	388(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b64:	4741                	li	a4,16
    80005b66:	f2c42683          	lw	a3,-212(s0)
    80005b6a:	fc040613          	addi	a2,s0,-64
    80005b6e:	4581                	li	a1,0
    80005b70:	8526                	mv	a0,s1
    80005b72:	ffffe097          	auipc	ra,0xffffe
    80005b76:	54a080e7          	jalr	1354(ra) # 800040bc <writei>
    80005b7a:	47c1                	li	a5,16
    80005b7c:	0af51563          	bne	a0,a5,80005c26 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b80:	04491703          	lh	a4,68(s2)
    80005b84:	4785                	li	a5,1
    80005b86:	0af70863          	beq	a4,a5,80005c36 <sys_unlink+0x18c>
  iunlockput(dp);
    80005b8a:	8526                	mv	a0,s1
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	3e6080e7          	jalr	998(ra) # 80003f72 <iunlockput>
  ip->nlink--;
    80005b94:	04a95783          	lhu	a5,74(s2)
    80005b98:	37fd                	addiw	a5,a5,-1
    80005b9a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b9e:	854a                	mv	a0,s2
    80005ba0:	ffffe097          	auipc	ra,0xffffe
    80005ba4:	0a6080e7          	jalr	166(ra) # 80003c46 <iupdate>
  iunlockput(ip);
    80005ba8:	854a                	mv	a0,s2
    80005baa:	ffffe097          	auipc	ra,0xffffe
    80005bae:	3c8080e7          	jalr	968(ra) # 80003f72 <iunlockput>
  end_op();
    80005bb2:	fffff097          	auipc	ra,0xfffff
    80005bb6:	bb0080e7          	jalr	-1104(ra) # 80004762 <end_op>
  return 0;
    80005bba:	4501                	li	a0,0
    80005bbc:	a84d                	j	80005c6e <sys_unlink+0x1c4>
    end_op();
    80005bbe:	fffff097          	auipc	ra,0xfffff
    80005bc2:	ba4080e7          	jalr	-1116(ra) # 80004762 <end_op>
    return -1;
    80005bc6:	557d                	li	a0,-1
    80005bc8:	a05d                	j	80005c6e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005bca:	00003517          	auipc	a0,0x3
    80005bce:	c0650513          	addi	a0,a0,-1018 # 800087d0 <syscalls+0x2e0>
    80005bd2:	ffffb097          	auipc	ra,0xffffb
    80005bd6:	96c080e7          	jalr	-1684(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bda:	04c92703          	lw	a4,76(s2)
    80005bde:	02000793          	li	a5,32
    80005be2:	f6e7f9e3          	bgeu	a5,a4,80005b54 <sys_unlink+0xaa>
    80005be6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005bea:	4741                	li	a4,16
    80005bec:	86ce                	mv	a3,s3
    80005bee:	f1840613          	addi	a2,s0,-232
    80005bf2:	4581                	li	a1,0
    80005bf4:	854a                	mv	a0,s2
    80005bf6:	ffffe097          	auipc	ra,0xffffe
    80005bfa:	3ce080e7          	jalr	974(ra) # 80003fc4 <readi>
    80005bfe:	47c1                	li	a5,16
    80005c00:	00f51b63          	bne	a0,a5,80005c16 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c04:	f1845783          	lhu	a5,-232(s0)
    80005c08:	e7a1                	bnez	a5,80005c50 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c0a:	29c1                	addiw	s3,s3,16
    80005c0c:	04c92783          	lw	a5,76(s2)
    80005c10:	fcf9ede3          	bltu	s3,a5,80005bea <sys_unlink+0x140>
    80005c14:	b781                	j	80005b54 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c16:	00003517          	auipc	a0,0x3
    80005c1a:	bd250513          	addi	a0,a0,-1070 # 800087e8 <syscalls+0x2f8>
    80005c1e:	ffffb097          	auipc	ra,0xffffb
    80005c22:	920080e7          	jalr	-1760(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005c26:	00003517          	auipc	a0,0x3
    80005c2a:	bda50513          	addi	a0,a0,-1062 # 80008800 <syscalls+0x310>
    80005c2e:	ffffb097          	auipc	ra,0xffffb
    80005c32:	910080e7          	jalr	-1776(ra) # 8000053e <panic>
    dp->nlink--;
    80005c36:	04a4d783          	lhu	a5,74(s1)
    80005c3a:	37fd                	addiw	a5,a5,-1
    80005c3c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c40:	8526                	mv	a0,s1
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	004080e7          	jalr	4(ra) # 80003c46 <iupdate>
    80005c4a:	b781                	j	80005b8a <sys_unlink+0xe0>
    return -1;
    80005c4c:	557d                	li	a0,-1
    80005c4e:	a005                	j	80005c6e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c50:	854a                	mv	a0,s2
    80005c52:	ffffe097          	auipc	ra,0xffffe
    80005c56:	320080e7          	jalr	800(ra) # 80003f72 <iunlockput>
  iunlockput(dp);
    80005c5a:	8526                	mv	a0,s1
    80005c5c:	ffffe097          	auipc	ra,0xffffe
    80005c60:	316080e7          	jalr	790(ra) # 80003f72 <iunlockput>
  end_op();
    80005c64:	fffff097          	auipc	ra,0xfffff
    80005c68:	afe080e7          	jalr	-1282(ra) # 80004762 <end_op>
  return -1;
    80005c6c:	557d                	li	a0,-1
}
    80005c6e:	70ae                	ld	ra,232(sp)
    80005c70:	740e                	ld	s0,224(sp)
    80005c72:	64ee                	ld	s1,216(sp)
    80005c74:	694e                	ld	s2,208(sp)
    80005c76:	69ae                	ld	s3,200(sp)
    80005c78:	616d                	addi	sp,sp,240
    80005c7a:	8082                	ret

0000000080005c7c <sys_open>:

uint64
sys_open(void)
{
    80005c7c:	7131                	addi	sp,sp,-192
    80005c7e:	fd06                	sd	ra,184(sp)
    80005c80:	f922                	sd	s0,176(sp)
    80005c82:	f526                	sd	s1,168(sp)
    80005c84:	f14a                	sd	s2,160(sp)
    80005c86:	ed4e                	sd	s3,152(sp)
    80005c88:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c8a:	08000613          	li	a2,128
    80005c8e:	f5040593          	addi	a1,s0,-176
    80005c92:	4501                	li	a0,0
    80005c94:	ffffd097          	auipc	ra,0xffffd
    80005c98:	54e080e7          	jalr	1358(ra) # 800031e2 <argstr>
    return -1;
    80005c9c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c9e:	0c054163          	bltz	a0,80005d60 <sys_open+0xe4>
    80005ca2:	f4c40593          	addi	a1,s0,-180
    80005ca6:	4505                	li	a0,1
    80005ca8:	ffffd097          	auipc	ra,0xffffd
    80005cac:	4f6080e7          	jalr	1270(ra) # 8000319e <argint>
    80005cb0:	0a054863          	bltz	a0,80005d60 <sys_open+0xe4>

  begin_op();
    80005cb4:	fffff097          	auipc	ra,0xfffff
    80005cb8:	a2e080e7          	jalr	-1490(ra) # 800046e2 <begin_op>

  if(omode & O_CREATE){
    80005cbc:	f4c42783          	lw	a5,-180(s0)
    80005cc0:	2007f793          	andi	a5,a5,512
    80005cc4:	cbdd                	beqz	a5,80005d7a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005cc6:	4681                	li	a3,0
    80005cc8:	4601                	li	a2,0
    80005cca:	4589                	li	a1,2
    80005ccc:	f5040513          	addi	a0,s0,-176
    80005cd0:	00000097          	auipc	ra,0x0
    80005cd4:	972080e7          	jalr	-1678(ra) # 80005642 <create>
    80005cd8:	892a                	mv	s2,a0
    if(ip == 0){
    80005cda:	c959                	beqz	a0,80005d70 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005cdc:	04491703          	lh	a4,68(s2)
    80005ce0:	478d                	li	a5,3
    80005ce2:	00f71763          	bne	a4,a5,80005cf0 <sys_open+0x74>
    80005ce6:	04695703          	lhu	a4,70(s2)
    80005cea:	47a5                	li	a5,9
    80005cec:	0ce7ec63          	bltu	a5,a4,80005dc4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005cf0:	fffff097          	auipc	ra,0xfffff
    80005cf4:	e02080e7          	jalr	-510(ra) # 80004af2 <filealloc>
    80005cf8:	89aa                	mv	s3,a0
    80005cfa:	10050263          	beqz	a0,80005dfe <sys_open+0x182>
    80005cfe:	00000097          	auipc	ra,0x0
    80005d02:	902080e7          	jalr	-1790(ra) # 80005600 <fdalloc>
    80005d06:	84aa                	mv	s1,a0
    80005d08:	0e054663          	bltz	a0,80005df4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d0c:	04491703          	lh	a4,68(s2)
    80005d10:	478d                	li	a5,3
    80005d12:	0cf70463          	beq	a4,a5,80005dda <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d16:	4789                	li	a5,2
    80005d18:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d1c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d20:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d24:	f4c42783          	lw	a5,-180(s0)
    80005d28:	0017c713          	xori	a4,a5,1
    80005d2c:	8b05                	andi	a4,a4,1
    80005d2e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d32:	0037f713          	andi	a4,a5,3
    80005d36:	00e03733          	snez	a4,a4
    80005d3a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d3e:	4007f793          	andi	a5,a5,1024
    80005d42:	c791                	beqz	a5,80005d4e <sys_open+0xd2>
    80005d44:	04491703          	lh	a4,68(s2)
    80005d48:	4789                	li	a5,2
    80005d4a:	08f70f63          	beq	a4,a5,80005de8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d4e:	854a                	mv	a0,s2
    80005d50:	ffffe097          	auipc	ra,0xffffe
    80005d54:	082080e7          	jalr	130(ra) # 80003dd2 <iunlock>
  end_op();
    80005d58:	fffff097          	auipc	ra,0xfffff
    80005d5c:	a0a080e7          	jalr	-1526(ra) # 80004762 <end_op>

  return fd;
}
    80005d60:	8526                	mv	a0,s1
    80005d62:	70ea                	ld	ra,184(sp)
    80005d64:	744a                	ld	s0,176(sp)
    80005d66:	74aa                	ld	s1,168(sp)
    80005d68:	790a                	ld	s2,160(sp)
    80005d6a:	69ea                	ld	s3,152(sp)
    80005d6c:	6129                	addi	sp,sp,192
    80005d6e:	8082                	ret
      end_op();
    80005d70:	fffff097          	auipc	ra,0xfffff
    80005d74:	9f2080e7          	jalr	-1550(ra) # 80004762 <end_op>
      return -1;
    80005d78:	b7e5                	j	80005d60 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d7a:	f5040513          	addi	a0,s0,-176
    80005d7e:	ffffe097          	auipc	ra,0xffffe
    80005d82:	748080e7          	jalr	1864(ra) # 800044c6 <namei>
    80005d86:	892a                	mv	s2,a0
    80005d88:	c905                	beqz	a0,80005db8 <sys_open+0x13c>
    ilock(ip);
    80005d8a:	ffffe097          	auipc	ra,0xffffe
    80005d8e:	f86080e7          	jalr	-122(ra) # 80003d10 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d92:	04491703          	lh	a4,68(s2)
    80005d96:	4785                	li	a5,1
    80005d98:	f4f712e3          	bne	a4,a5,80005cdc <sys_open+0x60>
    80005d9c:	f4c42783          	lw	a5,-180(s0)
    80005da0:	dba1                	beqz	a5,80005cf0 <sys_open+0x74>
      iunlockput(ip);
    80005da2:	854a                	mv	a0,s2
    80005da4:	ffffe097          	auipc	ra,0xffffe
    80005da8:	1ce080e7          	jalr	462(ra) # 80003f72 <iunlockput>
      end_op();
    80005dac:	fffff097          	auipc	ra,0xfffff
    80005db0:	9b6080e7          	jalr	-1610(ra) # 80004762 <end_op>
      return -1;
    80005db4:	54fd                	li	s1,-1
    80005db6:	b76d                	j	80005d60 <sys_open+0xe4>
      end_op();
    80005db8:	fffff097          	auipc	ra,0xfffff
    80005dbc:	9aa080e7          	jalr	-1622(ra) # 80004762 <end_op>
      return -1;
    80005dc0:	54fd                	li	s1,-1
    80005dc2:	bf79                	j	80005d60 <sys_open+0xe4>
    iunlockput(ip);
    80005dc4:	854a                	mv	a0,s2
    80005dc6:	ffffe097          	auipc	ra,0xffffe
    80005dca:	1ac080e7          	jalr	428(ra) # 80003f72 <iunlockput>
    end_op();
    80005dce:	fffff097          	auipc	ra,0xfffff
    80005dd2:	994080e7          	jalr	-1644(ra) # 80004762 <end_op>
    return -1;
    80005dd6:	54fd                	li	s1,-1
    80005dd8:	b761                	j	80005d60 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005dda:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005dde:	04691783          	lh	a5,70(s2)
    80005de2:	02f99223          	sh	a5,36(s3)
    80005de6:	bf2d                	j	80005d20 <sys_open+0xa4>
    itrunc(ip);
    80005de8:	854a                	mv	a0,s2
    80005dea:	ffffe097          	auipc	ra,0xffffe
    80005dee:	034080e7          	jalr	52(ra) # 80003e1e <itrunc>
    80005df2:	bfb1                	j	80005d4e <sys_open+0xd2>
      fileclose(f);
    80005df4:	854e                	mv	a0,s3
    80005df6:	fffff097          	auipc	ra,0xfffff
    80005dfa:	db8080e7          	jalr	-584(ra) # 80004bae <fileclose>
    iunlockput(ip);
    80005dfe:	854a                	mv	a0,s2
    80005e00:	ffffe097          	auipc	ra,0xffffe
    80005e04:	172080e7          	jalr	370(ra) # 80003f72 <iunlockput>
    end_op();
    80005e08:	fffff097          	auipc	ra,0xfffff
    80005e0c:	95a080e7          	jalr	-1702(ra) # 80004762 <end_op>
    return -1;
    80005e10:	54fd                	li	s1,-1
    80005e12:	b7b9                	j	80005d60 <sys_open+0xe4>

0000000080005e14 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e14:	7175                	addi	sp,sp,-144
    80005e16:	e506                	sd	ra,136(sp)
    80005e18:	e122                	sd	s0,128(sp)
    80005e1a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e1c:	fffff097          	auipc	ra,0xfffff
    80005e20:	8c6080e7          	jalr	-1850(ra) # 800046e2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e24:	08000613          	li	a2,128
    80005e28:	f7040593          	addi	a1,s0,-144
    80005e2c:	4501                	li	a0,0
    80005e2e:	ffffd097          	auipc	ra,0xffffd
    80005e32:	3b4080e7          	jalr	948(ra) # 800031e2 <argstr>
    80005e36:	02054963          	bltz	a0,80005e68 <sys_mkdir+0x54>
    80005e3a:	4681                	li	a3,0
    80005e3c:	4601                	li	a2,0
    80005e3e:	4585                	li	a1,1
    80005e40:	f7040513          	addi	a0,s0,-144
    80005e44:	fffff097          	auipc	ra,0xfffff
    80005e48:	7fe080e7          	jalr	2046(ra) # 80005642 <create>
    80005e4c:	cd11                	beqz	a0,80005e68 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e4e:	ffffe097          	auipc	ra,0xffffe
    80005e52:	124080e7          	jalr	292(ra) # 80003f72 <iunlockput>
  end_op();
    80005e56:	fffff097          	auipc	ra,0xfffff
    80005e5a:	90c080e7          	jalr	-1780(ra) # 80004762 <end_op>
  return 0;
    80005e5e:	4501                	li	a0,0
}
    80005e60:	60aa                	ld	ra,136(sp)
    80005e62:	640a                	ld	s0,128(sp)
    80005e64:	6149                	addi	sp,sp,144
    80005e66:	8082                	ret
    end_op();
    80005e68:	fffff097          	auipc	ra,0xfffff
    80005e6c:	8fa080e7          	jalr	-1798(ra) # 80004762 <end_op>
    return -1;
    80005e70:	557d                	li	a0,-1
    80005e72:	b7fd                	j	80005e60 <sys_mkdir+0x4c>

0000000080005e74 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e74:	7135                	addi	sp,sp,-160
    80005e76:	ed06                	sd	ra,152(sp)
    80005e78:	e922                	sd	s0,144(sp)
    80005e7a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e7c:	fffff097          	auipc	ra,0xfffff
    80005e80:	866080e7          	jalr	-1946(ra) # 800046e2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e84:	08000613          	li	a2,128
    80005e88:	f7040593          	addi	a1,s0,-144
    80005e8c:	4501                	li	a0,0
    80005e8e:	ffffd097          	auipc	ra,0xffffd
    80005e92:	354080e7          	jalr	852(ra) # 800031e2 <argstr>
    80005e96:	04054a63          	bltz	a0,80005eea <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005e9a:	f6c40593          	addi	a1,s0,-148
    80005e9e:	4505                	li	a0,1
    80005ea0:	ffffd097          	auipc	ra,0xffffd
    80005ea4:	2fe080e7          	jalr	766(ra) # 8000319e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ea8:	04054163          	bltz	a0,80005eea <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005eac:	f6840593          	addi	a1,s0,-152
    80005eb0:	4509                	li	a0,2
    80005eb2:	ffffd097          	auipc	ra,0xffffd
    80005eb6:	2ec080e7          	jalr	748(ra) # 8000319e <argint>
     argint(1, &major) < 0 ||
    80005eba:	02054863          	bltz	a0,80005eea <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ebe:	f6841683          	lh	a3,-152(s0)
    80005ec2:	f6c41603          	lh	a2,-148(s0)
    80005ec6:	458d                	li	a1,3
    80005ec8:	f7040513          	addi	a0,s0,-144
    80005ecc:	fffff097          	auipc	ra,0xfffff
    80005ed0:	776080e7          	jalr	1910(ra) # 80005642 <create>
     argint(2, &minor) < 0 ||
    80005ed4:	c919                	beqz	a0,80005eea <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ed6:	ffffe097          	auipc	ra,0xffffe
    80005eda:	09c080e7          	jalr	156(ra) # 80003f72 <iunlockput>
  end_op();
    80005ede:	fffff097          	auipc	ra,0xfffff
    80005ee2:	884080e7          	jalr	-1916(ra) # 80004762 <end_op>
  return 0;
    80005ee6:	4501                	li	a0,0
    80005ee8:	a031                	j	80005ef4 <sys_mknod+0x80>
    end_op();
    80005eea:	fffff097          	auipc	ra,0xfffff
    80005eee:	878080e7          	jalr	-1928(ra) # 80004762 <end_op>
    return -1;
    80005ef2:	557d                	li	a0,-1
}
    80005ef4:	60ea                	ld	ra,152(sp)
    80005ef6:	644a                	ld	s0,144(sp)
    80005ef8:	610d                	addi	sp,sp,160
    80005efa:	8082                	ret

0000000080005efc <sys_chdir>:

uint64
sys_chdir(void)
{
    80005efc:	7135                	addi	sp,sp,-160
    80005efe:	ed06                	sd	ra,152(sp)
    80005f00:	e922                	sd	s0,144(sp)
    80005f02:	e526                	sd	s1,136(sp)
    80005f04:	e14a                	sd	s2,128(sp)
    80005f06:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f08:	ffffc097          	auipc	ra,0xffffc
    80005f0c:	f0c080e7          	jalr	-244(ra) # 80001e14 <myproc>
    80005f10:	892a                	mv	s2,a0
  
  begin_op();
    80005f12:	ffffe097          	auipc	ra,0xffffe
    80005f16:	7d0080e7          	jalr	2000(ra) # 800046e2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f1a:	08000613          	li	a2,128
    80005f1e:	f6040593          	addi	a1,s0,-160
    80005f22:	4501                	li	a0,0
    80005f24:	ffffd097          	auipc	ra,0xffffd
    80005f28:	2be080e7          	jalr	702(ra) # 800031e2 <argstr>
    80005f2c:	04054b63          	bltz	a0,80005f82 <sys_chdir+0x86>
    80005f30:	f6040513          	addi	a0,s0,-160
    80005f34:	ffffe097          	auipc	ra,0xffffe
    80005f38:	592080e7          	jalr	1426(ra) # 800044c6 <namei>
    80005f3c:	84aa                	mv	s1,a0
    80005f3e:	c131                	beqz	a0,80005f82 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f40:	ffffe097          	auipc	ra,0xffffe
    80005f44:	dd0080e7          	jalr	-560(ra) # 80003d10 <ilock>
  if(ip->type != T_DIR){
    80005f48:	04449703          	lh	a4,68(s1)
    80005f4c:	4785                	li	a5,1
    80005f4e:	04f71063          	bne	a4,a5,80005f8e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f52:	8526                	mv	a0,s1
    80005f54:	ffffe097          	auipc	ra,0xffffe
    80005f58:	e7e080e7          	jalr	-386(ra) # 80003dd2 <iunlock>
  iput(p->cwd);
    80005f5c:	15093503          	ld	a0,336(s2)
    80005f60:	ffffe097          	auipc	ra,0xffffe
    80005f64:	f6a080e7          	jalr	-150(ra) # 80003eca <iput>
  end_op();
    80005f68:	ffffe097          	auipc	ra,0xffffe
    80005f6c:	7fa080e7          	jalr	2042(ra) # 80004762 <end_op>
  p->cwd = ip;
    80005f70:	14993823          	sd	s1,336(s2)
  return 0;
    80005f74:	4501                	li	a0,0
}
    80005f76:	60ea                	ld	ra,152(sp)
    80005f78:	644a                	ld	s0,144(sp)
    80005f7a:	64aa                	ld	s1,136(sp)
    80005f7c:	690a                	ld	s2,128(sp)
    80005f7e:	610d                	addi	sp,sp,160
    80005f80:	8082                	ret
    end_op();
    80005f82:	ffffe097          	auipc	ra,0xffffe
    80005f86:	7e0080e7          	jalr	2016(ra) # 80004762 <end_op>
    return -1;
    80005f8a:	557d                	li	a0,-1
    80005f8c:	b7ed                	j	80005f76 <sys_chdir+0x7a>
    iunlockput(ip);
    80005f8e:	8526                	mv	a0,s1
    80005f90:	ffffe097          	auipc	ra,0xffffe
    80005f94:	fe2080e7          	jalr	-30(ra) # 80003f72 <iunlockput>
    end_op();
    80005f98:	ffffe097          	auipc	ra,0xffffe
    80005f9c:	7ca080e7          	jalr	1994(ra) # 80004762 <end_op>
    return -1;
    80005fa0:	557d                	li	a0,-1
    80005fa2:	bfd1                	j	80005f76 <sys_chdir+0x7a>

0000000080005fa4 <sys_exec>:

uint64
sys_exec(void)
{
    80005fa4:	7145                	addi	sp,sp,-464
    80005fa6:	e786                	sd	ra,456(sp)
    80005fa8:	e3a2                	sd	s0,448(sp)
    80005faa:	ff26                	sd	s1,440(sp)
    80005fac:	fb4a                	sd	s2,432(sp)
    80005fae:	f74e                	sd	s3,424(sp)
    80005fb0:	f352                	sd	s4,416(sp)
    80005fb2:	ef56                	sd	s5,408(sp)
    80005fb4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fb6:	08000613          	li	a2,128
    80005fba:	f4040593          	addi	a1,s0,-192
    80005fbe:	4501                	li	a0,0
    80005fc0:	ffffd097          	auipc	ra,0xffffd
    80005fc4:	222080e7          	jalr	546(ra) # 800031e2 <argstr>
    return -1;
    80005fc8:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fca:	0c054a63          	bltz	a0,8000609e <sys_exec+0xfa>
    80005fce:	e3840593          	addi	a1,s0,-456
    80005fd2:	4505                	li	a0,1
    80005fd4:	ffffd097          	auipc	ra,0xffffd
    80005fd8:	1ec080e7          	jalr	492(ra) # 800031c0 <argaddr>
    80005fdc:	0c054163          	bltz	a0,8000609e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005fe0:	10000613          	li	a2,256
    80005fe4:	4581                	li	a1,0
    80005fe6:	e4040513          	addi	a0,s0,-448
    80005fea:	ffffb097          	auipc	ra,0xffffb
    80005fee:	cf6080e7          	jalr	-778(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ff2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ff6:	89a6                	mv	s3,s1
    80005ff8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ffa:	02000a13          	li	s4,32
    80005ffe:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006002:	00391513          	slli	a0,s2,0x3
    80006006:	e3040593          	addi	a1,s0,-464
    8000600a:	e3843783          	ld	a5,-456(s0)
    8000600e:	953e                	add	a0,a0,a5
    80006010:	ffffd097          	auipc	ra,0xffffd
    80006014:	0f4080e7          	jalr	244(ra) # 80003104 <fetchaddr>
    80006018:	02054a63          	bltz	a0,8000604c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000601c:	e3043783          	ld	a5,-464(s0)
    80006020:	c3b9                	beqz	a5,80006066 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006022:	ffffb097          	auipc	ra,0xffffb
    80006026:	ad2080e7          	jalr	-1326(ra) # 80000af4 <kalloc>
    8000602a:	85aa                	mv	a1,a0
    8000602c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006030:	cd11                	beqz	a0,8000604c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006032:	6605                	lui	a2,0x1
    80006034:	e3043503          	ld	a0,-464(s0)
    80006038:	ffffd097          	auipc	ra,0xffffd
    8000603c:	11e080e7          	jalr	286(ra) # 80003156 <fetchstr>
    80006040:	00054663          	bltz	a0,8000604c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006044:	0905                	addi	s2,s2,1
    80006046:	09a1                	addi	s3,s3,8
    80006048:	fb491be3          	bne	s2,s4,80005ffe <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000604c:	10048913          	addi	s2,s1,256
    80006050:	6088                	ld	a0,0(s1)
    80006052:	c529                	beqz	a0,8000609c <sys_exec+0xf8>
    kfree(argv[i]);
    80006054:	ffffb097          	auipc	ra,0xffffb
    80006058:	9a4080e7          	jalr	-1628(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000605c:	04a1                	addi	s1,s1,8
    8000605e:	ff2499e3          	bne	s1,s2,80006050 <sys_exec+0xac>
  return -1;
    80006062:	597d                	li	s2,-1
    80006064:	a82d                	j	8000609e <sys_exec+0xfa>
      argv[i] = 0;
    80006066:	0a8e                	slli	s5,s5,0x3
    80006068:	fc040793          	addi	a5,s0,-64
    8000606c:	9abe                	add	s5,s5,a5
    8000606e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006072:	e4040593          	addi	a1,s0,-448
    80006076:	f4040513          	addi	a0,s0,-192
    8000607a:	fffff097          	auipc	ra,0xfffff
    8000607e:	194080e7          	jalr	404(ra) # 8000520e <exec>
    80006082:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006084:	10048993          	addi	s3,s1,256
    80006088:	6088                	ld	a0,0(s1)
    8000608a:	c911                	beqz	a0,8000609e <sys_exec+0xfa>
    kfree(argv[i]);
    8000608c:	ffffb097          	auipc	ra,0xffffb
    80006090:	96c080e7          	jalr	-1684(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006094:	04a1                	addi	s1,s1,8
    80006096:	ff3499e3          	bne	s1,s3,80006088 <sys_exec+0xe4>
    8000609a:	a011                	j	8000609e <sys_exec+0xfa>
  return -1;
    8000609c:	597d                	li	s2,-1
}
    8000609e:	854a                	mv	a0,s2
    800060a0:	60be                	ld	ra,456(sp)
    800060a2:	641e                	ld	s0,448(sp)
    800060a4:	74fa                	ld	s1,440(sp)
    800060a6:	795a                	ld	s2,432(sp)
    800060a8:	79ba                	ld	s3,424(sp)
    800060aa:	7a1a                	ld	s4,416(sp)
    800060ac:	6afa                	ld	s5,408(sp)
    800060ae:	6179                	addi	sp,sp,464
    800060b0:	8082                	ret

00000000800060b2 <sys_pipe>:

uint64
sys_pipe(void)
{
    800060b2:	7139                	addi	sp,sp,-64
    800060b4:	fc06                	sd	ra,56(sp)
    800060b6:	f822                	sd	s0,48(sp)
    800060b8:	f426                	sd	s1,40(sp)
    800060ba:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800060bc:	ffffc097          	auipc	ra,0xffffc
    800060c0:	d58080e7          	jalr	-680(ra) # 80001e14 <myproc>
    800060c4:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800060c6:	fd840593          	addi	a1,s0,-40
    800060ca:	4501                	li	a0,0
    800060cc:	ffffd097          	auipc	ra,0xffffd
    800060d0:	0f4080e7          	jalr	244(ra) # 800031c0 <argaddr>
    return -1;
    800060d4:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800060d6:	0e054063          	bltz	a0,800061b6 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800060da:	fc840593          	addi	a1,s0,-56
    800060de:	fd040513          	addi	a0,s0,-48
    800060e2:	fffff097          	auipc	ra,0xfffff
    800060e6:	dfc080e7          	jalr	-516(ra) # 80004ede <pipealloc>
    return -1;
    800060ea:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800060ec:	0c054563          	bltz	a0,800061b6 <sys_pipe+0x104>
  fd0 = -1;
    800060f0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800060f4:	fd043503          	ld	a0,-48(s0)
    800060f8:	fffff097          	auipc	ra,0xfffff
    800060fc:	508080e7          	jalr	1288(ra) # 80005600 <fdalloc>
    80006100:	fca42223          	sw	a0,-60(s0)
    80006104:	08054c63          	bltz	a0,8000619c <sys_pipe+0xea>
    80006108:	fc843503          	ld	a0,-56(s0)
    8000610c:	fffff097          	auipc	ra,0xfffff
    80006110:	4f4080e7          	jalr	1268(ra) # 80005600 <fdalloc>
    80006114:	fca42023          	sw	a0,-64(s0)
    80006118:	06054863          	bltz	a0,80006188 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000611c:	4691                	li	a3,4
    8000611e:	fc440613          	addi	a2,s0,-60
    80006122:	fd843583          	ld	a1,-40(s0)
    80006126:	68a8                	ld	a0,80(s1)
    80006128:	ffffb097          	auipc	ra,0xffffb
    8000612c:	54a080e7          	jalr	1354(ra) # 80001672 <copyout>
    80006130:	02054063          	bltz	a0,80006150 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006134:	4691                	li	a3,4
    80006136:	fc040613          	addi	a2,s0,-64
    8000613a:	fd843583          	ld	a1,-40(s0)
    8000613e:	0591                	addi	a1,a1,4
    80006140:	68a8                	ld	a0,80(s1)
    80006142:	ffffb097          	auipc	ra,0xffffb
    80006146:	530080e7          	jalr	1328(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000614a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000614c:	06055563          	bgez	a0,800061b6 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006150:	fc442783          	lw	a5,-60(s0)
    80006154:	07e9                	addi	a5,a5,26
    80006156:	078e                	slli	a5,a5,0x3
    80006158:	97a6                	add	a5,a5,s1
    8000615a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000615e:	fc042503          	lw	a0,-64(s0)
    80006162:	0569                	addi	a0,a0,26
    80006164:	050e                	slli	a0,a0,0x3
    80006166:	9526                	add	a0,a0,s1
    80006168:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000616c:	fd043503          	ld	a0,-48(s0)
    80006170:	fffff097          	auipc	ra,0xfffff
    80006174:	a3e080e7          	jalr	-1474(ra) # 80004bae <fileclose>
    fileclose(wf);
    80006178:	fc843503          	ld	a0,-56(s0)
    8000617c:	fffff097          	auipc	ra,0xfffff
    80006180:	a32080e7          	jalr	-1486(ra) # 80004bae <fileclose>
    return -1;
    80006184:	57fd                	li	a5,-1
    80006186:	a805                	j	800061b6 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006188:	fc442783          	lw	a5,-60(s0)
    8000618c:	0007c863          	bltz	a5,8000619c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006190:	01a78513          	addi	a0,a5,26
    80006194:	050e                	slli	a0,a0,0x3
    80006196:	9526                	add	a0,a0,s1
    80006198:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000619c:	fd043503          	ld	a0,-48(s0)
    800061a0:	fffff097          	auipc	ra,0xfffff
    800061a4:	a0e080e7          	jalr	-1522(ra) # 80004bae <fileclose>
    fileclose(wf);
    800061a8:	fc843503          	ld	a0,-56(s0)
    800061ac:	fffff097          	auipc	ra,0xfffff
    800061b0:	a02080e7          	jalr	-1534(ra) # 80004bae <fileclose>
    return -1;
    800061b4:	57fd                	li	a5,-1
}
    800061b6:	853e                	mv	a0,a5
    800061b8:	70e2                	ld	ra,56(sp)
    800061ba:	7442                	ld	s0,48(sp)
    800061bc:	74a2                	ld	s1,40(sp)
    800061be:	6121                	addi	sp,sp,64
    800061c0:	8082                	ret
	...

00000000800061d0 <kernelvec>:
    800061d0:	7111                	addi	sp,sp,-256
    800061d2:	e006                	sd	ra,0(sp)
    800061d4:	e40a                	sd	sp,8(sp)
    800061d6:	e80e                	sd	gp,16(sp)
    800061d8:	ec12                	sd	tp,24(sp)
    800061da:	f016                	sd	t0,32(sp)
    800061dc:	f41a                	sd	t1,40(sp)
    800061de:	f81e                	sd	t2,48(sp)
    800061e0:	fc22                	sd	s0,56(sp)
    800061e2:	e0a6                	sd	s1,64(sp)
    800061e4:	e4aa                	sd	a0,72(sp)
    800061e6:	e8ae                	sd	a1,80(sp)
    800061e8:	ecb2                	sd	a2,88(sp)
    800061ea:	f0b6                	sd	a3,96(sp)
    800061ec:	f4ba                	sd	a4,104(sp)
    800061ee:	f8be                	sd	a5,112(sp)
    800061f0:	fcc2                	sd	a6,120(sp)
    800061f2:	e146                	sd	a7,128(sp)
    800061f4:	e54a                	sd	s2,136(sp)
    800061f6:	e94e                	sd	s3,144(sp)
    800061f8:	ed52                	sd	s4,152(sp)
    800061fa:	f156                	sd	s5,160(sp)
    800061fc:	f55a                	sd	s6,168(sp)
    800061fe:	f95e                	sd	s7,176(sp)
    80006200:	fd62                	sd	s8,184(sp)
    80006202:	e1e6                	sd	s9,192(sp)
    80006204:	e5ea                	sd	s10,200(sp)
    80006206:	e9ee                	sd	s11,208(sp)
    80006208:	edf2                	sd	t3,216(sp)
    8000620a:	f1f6                	sd	t4,224(sp)
    8000620c:	f5fa                	sd	t5,232(sp)
    8000620e:	f9fe                	sd	t6,240(sp)
    80006210:	dc1fc0ef          	jal	ra,80002fd0 <kerneltrap>
    80006214:	6082                	ld	ra,0(sp)
    80006216:	6122                	ld	sp,8(sp)
    80006218:	61c2                	ld	gp,16(sp)
    8000621a:	7282                	ld	t0,32(sp)
    8000621c:	7322                	ld	t1,40(sp)
    8000621e:	73c2                	ld	t2,48(sp)
    80006220:	7462                	ld	s0,56(sp)
    80006222:	6486                	ld	s1,64(sp)
    80006224:	6526                	ld	a0,72(sp)
    80006226:	65c6                	ld	a1,80(sp)
    80006228:	6666                	ld	a2,88(sp)
    8000622a:	7686                	ld	a3,96(sp)
    8000622c:	7726                	ld	a4,104(sp)
    8000622e:	77c6                	ld	a5,112(sp)
    80006230:	7866                	ld	a6,120(sp)
    80006232:	688a                	ld	a7,128(sp)
    80006234:	692a                	ld	s2,136(sp)
    80006236:	69ca                	ld	s3,144(sp)
    80006238:	6a6a                	ld	s4,152(sp)
    8000623a:	7a8a                	ld	s5,160(sp)
    8000623c:	7b2a                	ld	s6,168(sp)
    8000623e:	7bca                	ld	s7,176(sp)
    80006240:	7c6a                	ld	s8,184(sp)
    80006242:	6c8e                	ld	s9,192(sp)
    80006244:	6d2e                	ld	s10,200(sp)
    80006246:	6dce                	ld	s11,208(sp)
    80006248:	6e6e                	ld	t3,216(sp)
    8000624a:	7e8e                	ld	t4,224(sp)
    8000624c:	7f2e                	ld	t5,232(sp)
    8000624e:	7fce                	ld	t6,240(sp)
    80006250:	6111                	addi	sp,sp,256
    80006252:	10200073          	sret
    80006256:	00000013          	nop
    8000625a:	00000013          	nop
    8000625e:	0001                	nop

0000000080006260 <timervec>:
    80006260:	34051573          	csrrw	a0,mscratch,a0
    80006264:	e10c                	sd	a1,0(a0)
    80006266:	e510                	sd	a2,8(a0)
    80006268:	e914                	sd	a3,16(a0)
    8000626a:	6d0c                	ld	a1,24(a0)
    8000626c:	7110                	ld	a2,32(a0)
    8000626e:	6194                	ld	a3,0(a1)
    80006270:	96b2                	add	a3,a3,a2
    80006272:	e194                	sd	a3,0(a1)
    80006274:	4589                	li	a1,2
    80006276:	14459073          	csrw	sip,a1
    8000627a:	6914                	ld	a3,16(a0)
    8000627c:	6510                	ld	a2,8(a0)
    8000627e:	610c                	ld	a1,0(a0)
    80006280:	34051573          	csrrw	a0,mscratch,a0
    80006284:	30200073          	mret
	...

000000008000628a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000628a:	1141                	addi	sp,sp,-16
    8000628c:	e422                	sd	s0,8(sp)
    8000628e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006290:	0c0007b7          	lui	a5,0xc000
    80006294:	4705                	li	a4,1
    80006296:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006298:	c3d8                	sw	a4,4(a5)
}
    8000629a:	6422                	ld	s0,8(sp)
    8000629c:	0141                	addi	sp,sp,16
    8000629e:	8082                	ret

00000000800062a0 <plicinithart>:

void
plicinithart(void)
{
    800062a0:	1141                	addi	sp,sp,-16
    800062a2:	e406                	sd	ra,8(sp)
    800062a4:	e022                	sd	s0,0(sp)
    800062a6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062a8:	ffffc097          	auipc	ra,0xffffc
    800062ac:	b3a080e7          	jalr	-1222(ra) # 80001de2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062b0:	0085171b          	slliw	a4,a0,0x8
    800062b4:	0c0027b7          	lui	a5,0xc002
    800062b8:	97ba                	add	a5,a5,a4
    800062ba:	40200713          	li	a4,1026
    800062be:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062c2:	00d5151b          	slliw	a0,a0,0xd
    800062c6:	0c2017b7          	lui	a5,0xc201
    800062ca:	953e                	add	a0,a0,a5
    800062cc:	00052023          	sw	zero,0(a0)
}
    800062d0:	60a2                	ld	ra,8(sp)
    800062d2:	6402                	ld	s0,0(sp)
    800062d4:	0141                	addi	sp,sp,16
    800062d6:	8082                	ret

00000000800062d8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800062d8:	1141                	addi	sp,sp,-16
    800062da:	e406                	sd	ra,8(sp)
    800062dc:	e022                	sd	s0,0(sp)
    800062de:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062e0:	ffffc097          	auipc	ra,0xffffc
    800062e4:	b02080e7          	jalr	-1278(ra) # 80001de2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800062e8:	00d5179b          	slliw	a5,a0,0xd
    800062ec:	0c201537          	lui	a0,0xc201
    800062f0:	953e                	add	a0,a0,a5
  return irq;
}
    800062f2:	4148                	lw	a0,4(a0)
    800062f4:	60a2                	ld	ra,8(sp)
    800062f6:	6402                	ld	s0,0(sp)
    800062f8:	0141                	addi	sp,sp,16
    800062fa:	8082                	ret

00000000800062fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800062fc:	1101                	addi	sp,sp,-32
    800062fe:	ec06                	sd	ra,24(sp)
    80006300:	e822                	sd	s0,16(sp)
    80006302:	e426                	sd	s1,8(sp)
    80006304:	1000                	addi	s0,sp,32
    80006306:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006308:	ffffc097          	auipc	ra,0xffffc
    8000630c:	ada080e7          	jalr	-1318(ra) # 80001de2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006310:	00d5151b          	slliw	a0,a0,0xd
    80006314:	0c2017b7          	lui	a5,0xc201
    80006318:	97aa                	add	a5,a5,a0
    8000631a:	c3c4                	sw	s1,4(a5)
}
    8000631c:	60e2                	ld	ra,24(sp)
    8000631e:	6442                	ld	s0,16(sp)
    80006320:	64a2                	ld	s1,8(sp)
    80006322:	6105                	addi	sp,sp,32
    80006324:	8082                	ret

0000000080006326 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006326:	1141                	addi	sp,sp,-16
    80006328:	e406                	sd	ra,8(sp)
    8000632a:	e022                	sd	s0,0(sp)
    8000632c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000632e:	479d                	li	a5,7
    80006330:	06a7c963          	blt	a5,a0,800063a2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006334:	0001d797          	auipc	a5,0x1d
    80006338:	ccc78793          	addi	a5,a5,-820 # 80023000 <disk>
    8000633c:	00a78733          	add	a4,a5,a0
    80006340:	6789                	lui	a5,0x2
    80006342:	97ba                	add	a5,a5,a4
    80006344:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006348:	e7ad                	bnez	a5,800063b2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000634a:	00451793          	slli	a5,a0,0x4
    8000634e:	0001f717          	auipc	a4,0x1f
    80006352:	cb270713          	addi	a4,a4,-846 # 80025000 <disk+0x2000>
    80006356:	6314                	ld	a3,0(a4)
    80006358:	96be                	add	a3,a3,a5
    8000635a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000635e:	6314                	ld	a3,0(a4)
    80006360:	96be                	add	a3,a3,a5
    80006362:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006366:	6314                	ld	a3,0(a4)
    80006368:	96be                	add	a3,a3,a5
    8000636a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000636e:	6318                	ld	a4,0(a4)
    80006370:	97ba                	add	a5,a5,a4
    80006372:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006376:	0001d797          	auipc	a5,0x1d
    8000637a:	c8a78793          	addi	a5,a5,-886 # 80023000 <disk>
    8000637e:	97aa                	add	a5,a5,a0
    80006380:	6509                	lui	a0,0x2
    80006382:	953e                	add	a0,a0,a5
    80006384:	4785                	li	a5,1
    80006386:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000638a:	0001f517          	auipc	a0,0x1f
    8000638e:	c8e50513          	addi	a0,a0,-882 # 80025018 <disk+0x2018>
    80006392:	ffffc097          	auipc	ra,0xffffc
    80006396:	434080e7          	jalr	1076(ra) # 800027c6 <wakeup>
}
    8000639a:	60a2                	ld	ra,8(sp)
    8000639c:	6402                	ld	s0,0(sp)
    8000639e:	0141                	addi	sp,sp,16
    800063a0:	8082                	ret
    panic("free_desc 1");
    800063a2:	00002517          	auipc	a0,0x2
    800063a6:	46e50513          	addi	a0,a0,1134 # 80008810 <syscalls+0x320>
    800063aa:	ffffa097          	auipc	ra,0xffffa
    800063ae:	194080e7          	jalr	404(ra) # 8000053e <panic>
    panic("free_desc 2");
    800063b2:	00002517          	auipc	a0,0x2
    800063b6:	46e50513          	addi	a0,a0,1134 # 80008820 <syscalls+0x330>
    800063ba:	ffffa097          	auipc	ra,0xffffa
    800063be:	184080e7          	jalr	388(ra) # 8000053e <panic>

00000000800063c2 <virtio_disk_init>:
{
    800063c2:	1101                	addi	sp,sp,-32
    800063c4:	ec06                	sd	ra,24(sp)
    800063c6:	e822                	sd	s0,16(sp)
    800063c8:	e426                	sd	s1,8(sp)
    800063ca:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063cc:	00002597          	auipc	a1,0x2
    800063d0:	46458593          	addi	a1,a1,1124 # 80008830 <syscalls+0x340>
    800063d4:	0001f517          	auipc	a0,0x1f
    800063d8:	d5450513          	addi	a0,a0,-684 # 80025128 <disk+0x2128>
    800063dc:	ffffa097          	auipc	ra,0xffffa
    800063e0:	778080e7          	jalr	1912(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063e4:	100017b7          	lui	a5,0x10001
    800063e8:	4398                	lw	a4,0(a5)
    800063ea:	2701                	sext.w	a4,a4
    800063ec:	747277b7          	lui	a5,0x74727
    800063f0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800063f4:	0ef71163          	bne	a4,a5,800064d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800063f8:	100017b7          	lui	a5,0x10001
    800063fc:	43dc                	lw	a5,4(a5)
    800063fe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006400:	4705                	li	a4,1
    80006402:	0ce79a63          	bne	a5,a4,800064d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006406:	100017b7          	lui	a5,0x10001
    8000640a:	479c                	lw	a5,8(a5)
    8000640c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000640e:	4709                	li	a4,2
    80006410:	0ce79363          	bne	a5,a4,800064d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006414:	100017b7          	lui	a5,0x10001
    80006418:	47d8                	lw	a4,12(a5)
    8000641a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000641c:	554d47b7          	lui	a5,0x554d4
    80006420:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006424:	0af71963          	bne	a4,a5,800064d6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006428:	100017b7          	lui	a5,0x10001
    8000642c:	4705                	li	a4,1
    8000642e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006430:	470d                	li	a4,3
    80006432:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006434:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006436:	c7ffe737          	lui	a4,0xc7ffe
    8000643a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000643e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006440:	2701                	sext.w	a4,a4
    80006442:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006444:	472d                	li	a4,11
    80006446:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006448:	473d                	li	a4,15
    8000644a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000644c:	6705                	lui	a4,0x1
    8000644e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006450:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006454:	5bdc                	lw	a5,52(a5)
    80006456:	2781                	sext.w	a5,a5
  if(max == 0)
    80006458:	c7d9                	beqz	a5,800064e6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000645a:	471d                	li	a4,7
    8000645c:	08f77d63          	bgeu	a4,a5,800064f6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006460:	100014b7          	lui	s1,0x10001
    80006464:	47a1                	li	a5,8
    80006466:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006468:	6609                	lui	a2,0x2
    8000646a:	4581                	li	a1,0
    8000646c:	0001d517          	auipc	a0,0x1d
    80006470:	b9450513          	addi	a0,a0,-1132 # 80023000 <disk>
    80006474:	ffffb097          	auipc	ra,0xffffb
    80006478:	86c080e7          	jalr	-1940(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000647c:	0001d717          	auipc	a4,0x1d
    80006480:	b8470713          	addi	a4,a4,-1148 # 80023000 <disk>
    80006484:	00c75793          	srli	a5,a4,0xc
    80006488:	2781                	sext.w	a5,a5
    8000648a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000648c:	0001f797          	auipc	a5,0x1f
    80006490:	b7478793          	addi	a5,a5,-1164 # 80025000 <disk+0x2000>
    80006494:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006496:	0001d717          	auipc	a4,0x1d
    8000649a:	bea70713          	addi	a4,a4,-1046 # 80023080 <disk+0x80>
    8000649e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800064a0:	0001e717          	auipc	a4,0x1e
    800064a4:	b6070713          	addi	a4,a4,-1184 # 80024000 <disk+0x1000>
    800064a8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800064aa:	4705                	li	a4,1
    800064ac:	00e78c23          	sb	a4,24(a5)
    800064b0:	00e78ca3          	sb	a4,25(a5)
    800064b4:	00e78d23          	sb	a4,26(a5)
    800064b8:	00e78da3          	sb	a4,27(a5)
    800064bc:	00e78e23          	sb	a4,28(a5)
    800064c0:	00e78ea3          	sb	a4,29(a5)
    800064c4:	00e78f23          	sb	a4,30(a5)
    800064c8:	00e78fa3          	sb	a4,31(a5)
}
    800064cc:	60e2                	ld	ra,24(sp)
    800064ce:	6442                	ld	s0,16(sp)
    800064d0:	64a2                	ld	s1,8(sp)
    800064d2:	6105                	addi	sp,sp,32
    800064d4:	8082                	ret
    panic("could not find virtio disk");
    800064d6:	00002517          	auipc	a0,0x2
    800064da:	36a50513          	addi	a0,a0,874 # 80008840 <syscalls+0x350>
    800064de:	ffffa097          	auipc	ra,0xffffa
    800064e2:	060080e7          	jalr	96(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800064e6:	00002517          	auipc	a0,0x2
    800064ea:	37a50513          	addi	a0,a0,890 # 80008860 <syscalls+0x370>
    800064ee:	ffffa097          	auipc	ra,0xffffa
    800064f2:	050080e7          	jalr	80(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800064f6:	00002517          	auipc	a0,0x2
    800064fa:	38a50513          	addi	a0,a0,906 # 80008880 <syscalls+0x390>
    800064fe:	ffffa097          	auipc	ra,0xffffa
    80006502:	040080e7          	jalr	64(ra) # 8000053e <panic>

0000000080006506 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006506:	7159                	addi	sp,sp,-112
    80006508:	f486                	sd	ra,104(sp)
    8000650a:	f0a2                	sd	s0,96(sp)
    8000650c:	eca6                	sd	s1,88(sp)
    8000650e:	e8ca                	sd	s2,80(sp)
    80006510:	e4ce                	sd	s3,72(sp)
    80006512:	e0d2                	sd	s4,64(sp)
    80006514:	fc56                	sd	s5,56(sp)
    80006516:	f85a                	sd	s6,48(sp)
    80006518:	f45e                	sd	s7,40(sp)
    8000651a:	f062                	sd	s8,32(sp)
    8000651c:	ec66                	sd	s9,24(sp)
    8000651e:	e86a                	sd	s10,16(sp)
    80006520:	1880                	addi	s0,sp,112
    80006522:	892a                	mv	s2,a0
    80006524:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006526:	00c52c83          	lw	s9,12(a0)
    8000652a:	001c9c9b          	slliw	s9,s9,0x1
    8000652e:	1c82                	slli	s9,s9,0x20
    80006530:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006534:	0001f517          	auipc	a0,0x1f
    80006538:	bf450513          	addi	a0,a0,-1036 # 80025128 <disk+0x2128>
    8000653c:	ffffa097          	auipc	ra,0xffffa
    80006540:	6a8080e7          	jalr	1704(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006544:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006546:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006548:	0001db97          	auipc	s7,0x1d
    8000654c:	ab8b8b93          	addi	s7,s7,-1352 # 80023000 <disk>
    80006550:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006552:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006554:	8a4e                	mv	s4,s3
    80006556:	a051                	j	800065da <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006558:	00fb86b3          	add	a3,s7,a5
    8000655c:	96da                	add	a3,a3,s6
    8000655e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006562:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006564:	0207c563          	bltz	a5,8000658e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006568:	2485                	addiw	s1,s1,1
    8000656a:	0711                	addi	a4,a4,4
    8000656c:	25548063          	beq	s1,s5,800067ac <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006570:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006572:	0001f697          	auipc	a3,0x1f
    80006576:	aa668693          	addi	a3,a3,-1370 # 80025018 <disk+0x2018>
    8000657a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000657c:	0006c583          	lbu	a1,0(a3)
    80006580:	fde1                	bnez	a1,80006558 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006582:	2785                	addiw	a5,a5,1
    80006584:	0685                	addi	a3,a3,1
    80006586:	ff879be3          	bne	a5,s8,8000657c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000658a:	57fd                	li	a5,-1
    8000658c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000658e:	02905a63          	blez	s1,800065c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006592:	f9042503          	lw	a0,-112(s0)
    80006596:	00000097          	auipc	ra,0x0
    8000659a:	d90080e7          	jalr	-624(ra) # 80006326 <free_desc>
      for(int j = 0; j < i; j++)
    8000659e:	4785                	li	a5,1
    800065a0:	0297d163          	bge	a5,s1,800065c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065a4:	f9442503          	lw	a0,-108(s0)
    800065a8:	00000097          	auipc	ra,0x0
    800065ac:	d7e080e7          	jalr	-642(ra) # 80006326 <free_desc>
      for(int j = 0; j < i; j++)
    800065b0:	4789                	li	a5,2
    800065b2:	0097d863          	bge	a5,s1,800065c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065b6:	f9842503          	lw	a0,-104(s0)
    800065ba:	00000097          	auipc	ra,0x0
    800065be:	d6c080e7          	jalr	-660(ra) # 80006326 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065c2:	0001f597          	auipc	a1,0x1f
    800065c6:	b6658593          	addi	a1,a1,-1178 # 80025128 <disk+0x2128>
    800065ca:	0001f517          	auipc	a0,0x1f
    800065ce:	a4e50513          	addi	a0,a0,-1458 # 80025018 <disk+0x2018>
    800065d2:	ffffc097          	auipc	ra,0xffffc
    800065d6:	056080e7          	jalr	86(ra) # 80002628 <sleep>
  for(int i = 0; i < 3; i++){
    800065da:	f9040713          	addi	a4,s0,-112
    800065de:	84ce                	mv	s1,s3
    800065e0:	bf41                	j	80006570 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800065e2:	20058713          	addi	a4,a1,512
    800065e6:	00471693          	slli	a3,a4,0x4
    800065ea:	0001d717          	auipc	a4,0x1d
    800065ee:	a1670713          	addi	a4,a4,-1514 # 80023000 <disk>
    800065f2:	9736                	add	a4,a4,a3
    800065f4:	4685                	li	a3,1
    800065f6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800065fa:	20058713          	addi	a4,a1,512
    800065fe:	00471693          	slli	a3,a4,0x4
    80006602:	0001d717          	auipc	a4,0x1d
    80006606:	9fe70713          	addi	a4,a4,-1538 # 80023000 <disk>
    8000660a:	9736                	add	a4,a4,a3
    8000660c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006610:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006614:	7679                	lui	a2,0xffffe
    80006616:	963e                	add	a2,a2,a5
    80006618:	0001f697          	auipc	a3,0x1f
    8000661c:	9e868693          	addi	a3,a3,-1560 # 80025000 <disk+0x2000>
    80006620:	6298                	ld	a4,0(a3)
    80006622:	9732                	add	a4,a4,a2
    80006624:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006626:	6298                	ld	a4,0(a3)
    80006628:	9732                	add	a4,a4,a2
    8000662a:	4541                	li	a0,16
    8000662c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000662e:	6298                	ld	a4,0(a3)
    80006630:	9732                	add	a4,a4,a2
    80006632:	4505                	li	a0,1
    80006634:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006638:	f9442703          	lw	a4,-108(s0)
    8000663c:	6288                	ld	a0,0(a3)
    8000663e:	962a                	add	a2,a2,a0
    80006640:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006644:	0712                	slli	a4,a4,0x4
    80006646:	6290                	ld	a2,0(a3)
    80006648:	963a                	add	a2,a2,a4
    8000664a:	05890513          	addi	a0,s2,88
    8000664e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006650:	6294                	ld	a3,0(a3)
    80006652:	96ba                	add	a3,a3,a4
    80006654:	40000613          	li	a2,1024
    80006658:	c690                	sw	a2,8(a3)
  if(write)
    8000665a:	140d0063          	beqz	s10,8000679a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000665e:	0001f697          	auipc	a3,0x1f
    80006662:	9a26b683          	ld	a3,-1630(a3) # 80025000 <disk+0x2000>
    80006666:	96ba                	add	a3,a3,a4
    80006668:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000666c:	0001d817          	auipc	a6,0x1d
    80006670:	99480813          	addi	a6,a6,-1644 # 80023000 <disk>
    80006674:	0001f517          	auipc	a0,0x1f
    80006678:	98c50513          	addi	a0,a0,-1652 # 80025000 <disk+0x2000>
    8000667c:	6114                	ld	a3,0(a0)
    8000667e:	96ba                	add	a3,a3,a4
    80006680:	00c6d603          	lhu	a2,12(a3)
    80006684:	00166613          	ori	a2,a2,1
    80006688:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000668c:	f9842683          	lw	a3,-104(s0)
    80006690:	6110                	ld	a2,0(a0)
    80006692:	9732                	add	a4,a4,a2
    80006694:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006698:	20058613          	addi	a2,a1,512
    8000669c:	0612                	slli	a2,a2,0x4
    8000669e:	9642                	add	a2,a2,a6
    800066a0:	577d                	li	a4,-1
    800066a2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800066a6:	00469713          	slli	a4,a3,0x4
    800066aa:	6114                	ld	a3,0(a0)
    800066ac:	96ba                	add	a3,a3,a4
    800066ae:	03078793          	addi	a5,a5,48
    800066b2:	97c2                	add	a5,a5,a6
    800066b4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800066b6:	611c                	ld	a5,0(a0)
    800066b8:	97ba                	add	a5,a5,a4
    800066ba:	4685                	li	a3,1
    800066bc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800066be:	611c                	ld	a5,0(a0)
    800066c0:	97ba                	add	a5,a5,a4
    800066c2:	4809                	li	a6,2
    800066c4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800066c8:	611c                	ld	a5,0(a0)
    800066ca:	973e                	add	a4,a4,a5
    800066cc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800066d0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800066d4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800066d8:	6518                	ld	a4,8(a0)
    800066da:	00275783          	lhu	a5,2(a4)
    800066de:	8b9d                	andi	a5,a5,7
    800066e0:	0786                	slli	a5,a5,0x1
    800066e2:	97ba                	add	a5,a5,a4
    800066e4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800066e8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800066ec:	6518                	ld	a4,8(a0)
    800066ee:	00275783          	lhu	a5,2(a4)
    800066f2:	2785                	addiw	a5,a5,1
    800066f4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800066f8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800066fc:	100017b7          	lui	a5,0x10001
    80006700:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006704:	00492703          	lw	a4,4(s2)
    80006708:	4785                	li	a5,1
    8000670a:	02f71163          	bne	a4,a5,8000672c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000670e:	0001f997          	auipc	s3,0x1f
    80006712:	a1a98993          	addi	s3,s3,-1510 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006716:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006718:	85ce                	mv	a1,s3
    8000671a:	854a                	mv	a0,s2
    8000671c:	ffffc097          	auipc	ra,0xffffc
    80006720:	f0c080e7          	jalr	-244(ra) # 80002628 <sleep>
  while(b->disk == 1) {
    80006724:	00492783          	lw	a5,4(s2)
    80006728:	fe9788e3          	beq	a5,s1,80006718 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000672c:	f9042903          	lw	s2,-112(s0)
    80006730:	20090793          	addi	a5,s2,512
    80006734:	00479713          	slli	a4,a5,0x4
    80006738:	0001d797          	auipc	a5,0x1d
    8000673c:	8c878793          	addi	a5,a5,-1848 # 80023000 <disk>
    80006740:	97ba                	add	a5,a5,a4
    80006742:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006746:	0001f997          	auipc	s3,0x1f
    8000674a:	8ba98993          	addi	s3,s3,-1862 # 80025000 <disk+0x2000>
    8000674e:	00491713          	slli	a4,s2,0x4
    80006752:	0009b783          	ld	a5,0(s3)
    80006756:	97ba                	add	a5,a5,a4
    80006758:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000675c:	854a                	mv	a0,s2
    8000675e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006762:	00000097          	auipc	ra,0x0
    80006766:	bc4080e7          	jalr	-1084(ra) # 80006326 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000676a:	8885                	andi	s1,s1,1
    8000676c:	f0ed                	bnez	s1,8000674e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000676e:	0001f517          	auipc	a0,0x1f
    80006772:	9ba50513          	addi	a0,a0,-1606 # 80025128 <disk+0x2128>
    80006776:	ffffa097          	auipc	ra,0xffffa
    8000677a:	522080e7          	jalr	1314(ra) # 80000c98 <release>
}
    8000677e:	70a6                	ld	ra,104(sp)
    80006780:	7406                	ld	s0,96(sp)
    80006782:	64e6                	ld	s1,88(sp)
    80006784:	6946                	ld	s2,80(sp)
    80006786:	69a6                	ld	s3,72(sp)
    80006788:	6a06                	ld	s4,64(sp)
    8000678a:	7ae2                	ld	s5,56(sp)
    8000678c:	7b42                	ld	s6,48(sp)
    8000678e:	7ba2                	ld	s7,40(sp)
    80006790:	7c02                	ld	s8,32(sp)
    80006792:	6ce2                	ld	s9,24(sp)
    80006794:	6d42                	ld	s10,16(sp)
    80006796:	6165                	addi	sp,sp,112
    80006798:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000679a:	0001f697          	auipc	a3,0x1f
    8000679e:	8666b683          	ld	a3,-1946(a3) # 80025000 <disk+0x2000>
    800067a2:	96ba                	add	a3,a3,a4
    800067a4:	4609                	li	a2,2
    800067a6:	00c69623          	sh	a2,12(a3)
    800067aa:	b5c9                	j	8000666c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800067ac:	f9042583          	lw	a1,-112(s0)
    800067b0:	20058793          	addi	a5,a1,512
    800067b4:	0792                	slli	a5,a5,0x4
    800067b6:	0001d517          	auipc	a0,0x1d
    800067ba:	8f250513          	addi	a0,a0,-1806 # 800230a8 <disk+0xa8>
    800067be:	953e                	add	a0,a0,a5
  if(write)
    800067c0:	e20d11e3          	bnez	s10,800065e2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800067c4:	20058713          	addi	a4,a1,512
    800067c8:	00471693          	slli	a3,a4,0x4
    800067cc:	0001d717          	auipc	a4,0x1d
    800067d0:	83470713          	addi	a4,a4,-1996 # 80023000 <disk>
    800067d4:	9736                	add	a4,a4,a3
    800067d6:	0a072423          	sw	zero,168(a4)
    800067da:	b505                	j	800065fa <virtio_disk_rw+0xf4>

00000000800067dc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800067dc:	1101                	addi	sp,sp,-32
    800067de:	ec06                	sd	ra,24(sp)
    800067e0:	e822                	sd	s0,16(sp)
    800067e2:	e426                	sd	s1,8(sp)
    800067e4:	e04a                	sd	s2,0(sp)
    800067e6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800067e8:	0001f517          	auipc	a0,0x1f
    800067ec:	94050513          	addi	a0,a0,-1728 # 80025128 <disk+0x2128>
    800067f0:	ffffa097          	auipc	ra,0xffffa
    800067f4:	3f4080e7          	jalr	1012(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800067f8:	10001737          	lui	a4,0x10001
    800067fc:	533c                	lw	a5,96(a4)
    800067fe:	8b8d                	andi	a5,a5,3
    80006800:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006802:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006806:	0001e797          	auipc	a5,0x1e
    8000680a:	7fa78793          	addi	a5,a5,2042 # 80025000 <disk+0x2000>
    8000680e:	6b94                	ld	a3,16(a5)
    80006810:	0207d703          	lhu	a4,32(a5)
    80006814:	0026d783          	lhu	a5,2(a3)
    80006818:	06f70163          	beq	a4,a5,8000687a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000681c:	0001c917          	auipc	s2,0x1c
    80006820:	7e490913          	addi	s2,s2,2020 # 80023000 <disk>
    80006824:	0001e497          	auipc	s1,0x1e
    80006828:	7dc48493          	addi	s1,s1,2012 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000682c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006830:	6898                	ld	a4,16(s1)
    80006832:	0204d783          	lhu	a5,32(s1)
    80006836:	8b9d                	andi	a5,a5,7
    80006838:	078e                	slli	a5,a5,0x3
    8000683a:	97ba                	add	a5,a5,a4
    8000683c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000683e:	20078713          	addi	a4,a5,512
    80006842:	0712                	slli	a4,a4,0x4
    80006844:	974a                	add	a4,a4,s2
    80006846:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000684a:	e731                	bnez	a4,80006896 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000684c:	20078793          	addi	a5,a5,512
    80006850:	0792                	slli	a5,a5,0x4
    80006852:	97ca                	add	a5,a5,s2
    80006854:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006856:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000685a:	ffffc097          	auipc	ra,0xffffc
    8000685e:	f6c080e7          	jalr	-148(ra) # 800027c6 <wakeup>

    disk.used_idx += 1;
    80006862:	0204d783          	lhu	a5,32(s1)
    80006866:	2785                	addiw	a5,a5,1
    80006868:	17c2                	slli	a5,a5,0x30
    8000686a:	93c1                	srli	a5,a5,0x30
    8000686c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006870:	6898                	ld	a4,16(s1)
    80006872:	00275703          	lhu	a4,2(a4)
    80006876:	faf71be3          	bne	a4,a5,8000682c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000687a:	0001f517          	auipc	a0,0x1f
    8000687e:	8ae50513          	addi	a0,a0,-1874 # 80025128 <disk+0x2128>
    80006882:	ffffa097          	auipc	ra,0xffffa
    80006886:	416080e7          	jalr	1046(ra) # 80000c98 <release>
}
    8000688a:	60e2                	ld	ra,24(sp)
    8000688c:	6442                	ld	s0,16(sp)
    8000688e:	64a2                	ld	s1,8(sp)
    80006890:	6902                	ld	s2,0(sp)
    80006892:	6105                	addi	sp,sp,32
    80006894:	8082                	ret
      panic("virtio_disk_intr status");
    80006896:	00002517          	auipc	a0,0x2
    8000689a:	00a50513          	addi	a0,a0,10 # 800088a0 <syscalls+0x3b0>
    8000689e:	ffffa097          	auipc	ra,0xffffa
    800068a2:	ca0080e7          	jalr	-864(ra) # 8000053e <panic>

00000000800068a6 <cas>:
    800068a6:	100522af          	lr.w	t0,(a0)
    800068aa:	00b29563          	bne	t0,a1,800068b4 <fail>
    800068ae:	18c5252f          	sc.w	a0,a2,(a0)
    800068b2:	8082                	ret

00000000800068b4 <fail>:
    800068b4:	4505                	li	a0,1
    800068b6:	8082                	ret
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
