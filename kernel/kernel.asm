
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	96013103          	ld	sp,-1696(sp) # 80008960 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	14c78793          	addi	a5,a5,332 # 800061b0 <timervec>
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
    80000130:	914080e7          	jalr	-1772(ra) # 80002a40 <either_copyin>
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
    800001c8:	b0c080e7          	jalr	-1268(ra) # 80001cd0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	36e080e7          	jalr	878(ra) # 80002542 <sleep>
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
    80000210:	00002097          	auipc	ra,0x2
    80000214:	7da080e7          	jalr	2010(ra) # 800029ea <either_copyout>
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
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	7a4080e7          	jalr	1956(ra) # 80002a96 <procdump>
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
    8000044a:	29a080e7          	jalr	666(ra) # 800026e0 <wakeup>
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
    800008a4:	e40080e7          	jalr	-448(ra) # 800026e0 <wakeup>
    
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
    80000930:	c16080e7          	jalr	-1002(ra) # 80002542 <sleep>
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
    80000b82:	130080e7          	jalr	304(ra) # 80001cae <mycpu>
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
    80000bb4:	0fe080e7          	jalr	254(ra) # 80001cae <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	0f2080e7          	jalr	242(ra) # 80001cae <mycpu>
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
    80000bd8:	0da080e7          	jalr	218(ra) # 80001cae <mycpu>
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
    80000c18:	09a080e7          	jalr	154(ra) # 80001cae <mycpu>
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
    80000c44:	06e080e7          	jalr	110(ra) # 80001cae <mycpu>
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
    80000e9a:	e08080e7          	jalr	-504(ra) # 80001c9e <cpuid>
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
    80000eb6:	dec080e7          	jalr	-532(ra) # 80001c9e <cpuid>
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
    80000ed8:	d74080e7          	jalr	-652(ra) # 80002c48 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	314080e7          	jalr	788(ra) # 800061f0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	452080e7          	jalr	1106(ra) # 80002336 <scheduler>
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
    80000f48:	bd0080e7          	jalr	-1072(ra) # 80001b14 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	cd4080e7          	jalr	-812(ra) # 80002c20 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	cf4080e7          	jalr	-780(ra) # 80002c48 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	27e080e7          	jalr	638(ra) # 800061da <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	28c080e7          	jalr	652(ra) # 800061f0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	468080e7          	jalr	1128(ra) # 800033d4 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	af8080e7          	jalr	-1288(ra) # 80003a6c <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	aa2080e7          	jalr	-1374(ra) # 80004a1e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	38e080e7          	jalr	910(ra) # 80006312 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	0ca080e7          	jalr	202(ra) # 80002056 <userinit>
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
    80001244:	83e080e7          	jalr	-1986(ra) # 80001a7e <proc_mapstacks>
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

000000008000183e <inc_cpu>:
struct linked_list unused_list = {-1};   
struct linked_list sleeping_list = {-1}; 
struct linked_list zombie_list = {-1};

void 
inc_cpu(struct cpu *c){
    8000183e:	1101                	addi	sp,sp,-32
    80001840:	ec06                	sd	ra,24(sp)
    80001842:	e822                	sd	s0,16(sp)
    80001844:	e426                	sd	s1,8(sp)
    80001846:	e04a                	sd	s2,0(sp)
    80001848:	1000                	addi	s0,sp,32
    8000184a:	84aa                	mv	s1,a0
  uint64 procs_num;
  do
  {
    procs_num = c->proc_cnt;
  }
  while (cas(&(c->proc_cnt), procs_num, procs_num+1));
    8000184c:	08050913          	addi	s2,a0,128
    procs_num = c->proc_cnt;
    80001850:	0804a583          	lw	a1,128(s1)
  while (cas(&(c->proc_cnt), procs_num, procs_num+1));
    80001854:	0015861b          	addiw	a2,a1,1
    80001858:	854a                	mv	a0,s2
    8000185a:	00005097          	auipc	ra,0x5
    8000185e:	f9c080e7          	jalr	-100(ra) # 800067f6 <cas>
    80001862:	2501                	sext.w	a0,a0
    80001864:	f575                	bnez	a0,80001850 <inc_cpu+0x12>
}
    80001866:	60e2                	ld	ra,24(sp)
    80001868:	6442                	ld	s0,16(sp)
    8000186a:	64a2                	ld	s1,8(sp)
    8000186c:	6902                	ld	s2,0(sp)
    8000186e:	6105                	addi	sp,sp,32
    80001870:	8082                	ret

0000000080001872 <isEmpty>:


int
isEmpty(struct linked_list *lst){
    80001872:	1141                	addi	sp,sp,-16
    80001874:	e422                	sd	s0,8(sp)
    80001876:	0800                	addi	s0,sp,16
  int h= 0;
  h = lst->head == -1;
    80001878:	4108                	lw	a0,0(a0)
    8000187a:	0505                	addi	a0,a0,1
  return h;
}
    8000187c:	00153513          	seqz	a0,a0
    80001880:	6422                	ld	s0,8(sp)
    80001882:	0141                	addi	sp,sp,16
    80001884:	8082                	ret

0000000080001886 <append>:


void 
append(struct linked_list *lst, struct proc *p){
    80001886:	7139                	addi	sp,sp,-64
    80001888:	fc06                	sd	ra,56(sp)
    8000188a:	f822                	sd	s0,48(sp)
    8000188c:	f426                	sd	s1,40(sp)
    8000188e:	f04a                	sd	s2,32(sp)
    80001890:	ec4e                	sd	s3,24(sp)
    80001892:	e852                	sd	s4,16(sp)
    80001894:	e456                	sd	s5,8(sp)
    80001896:	0080                	addi	s0,sp,64
    80001898:	84aa                	mv	s1,a0
    8000189a:	892e                	mv	s2,a1
  acquire(&lst->head_lock);
    8000189c:	00850993          	addi	s3,a0,8
    800018a0:	854e                	mv	a0,s3
    800018a2:	fffff097          	auipc	ra,0xfffff
    800018a6:	342080e7          	jalr	834(ra) # 80000be4 <acquire>
  if(isEmpty(lst)){
    800018aa:	4098                	lw	a4,0(s1)
    800018ac:	57fd                	li	a5,-1
    800018ae:	04f71063          	bne	a4,a5,800018ee <append+0x68>
    lst->head = p->proc_ind;
    800018b2:	17492783          	lw	a5,372(s2) # 1174 <_entry-0x7fffee8c>
    800018b6:	c09c                	sw	a5,0(s1)
    release(&lst->head_lock);
    800018b8:	854e                	mv	a0,s3
    800018ba:	fffff097          	auipc	ra,0xfffff
    800018be:	3de080e7          	jalr	990(ra) # 80000c98 <release>
    release(&lst->head_lock);
    proc[lst->tail].next_proc = p->proc_ind;
    p->prev_proc = proc[lst->tail].proc_ind; 
    release(&proc[lst->tail].list_lock);
  }
  acquire(&lst->head_lock);
    800018c2:	854e                	mv	a0,s3
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	320080e7          	jalr	800(ra) # 80000be4 <acquire>
  lst->tail = p->proc_ind;
    800018cc:	17492783          	lw	a5,372(s2)
    800018d0:	c0dc                	sw	a5,4(s1)
  release(&lst->head_lock);
    800018d2:	854e                	mv	a0,s3
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	3c4080e7          	jalr	964(ra) # 80000c98 <release>
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
    acquire(&proc[lst->tail].list_lock);
    800018ee:	40c8                	lw	a0,4(s1)
    800018f0:	19000a93          	li	s5,400
    800018f4:	03550533          	mul	a0,a0,s5
    800018f8:	17850513          	addi	a0,a0,376
    800018fc:	00010a17          	auipc	s4,0x10
    80001900:	f14a0a13          	addi	s4,s4,-236 # 80011810 <proc>
    80001904:	9552                	add	a0,a0,s4
    80001906:	fffff097          	auipc	ra,0xfffff
    8000190a:	2de080e7          	jalr	734(ra) # 80000be4 <acquire>
    release(&lst->head_lock);
    8000190e:	854e                	mv	a0,s3
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	388080e7          	jalr	904(ra) # 80000c98 <release>
    proc[lst->tail].next_proc = p->proc_ind;
    80001918:	40dc                	lw	a5,4(s1)
    8000191a:	17492703          	lw	a4,372(s2)
    8000191e:	035787b3          	mul	a5,a5,s5
    80001922:	97d2                	add	a5,a5,s4
    80001924:	16e7a623          	sw	a4,364(a5)
    p->prev_proc = proc[lst->tail].proc_ind; 
    80001928:	40dc                	lw	a5,4(s1)
    8000192a:	035787b3          	mul	a5,a5,s5
    8000192e:	97d2                	add	a5,a5,s4
    80001930:	1747a783          	lw	a5,372(a5)
    80001934:	16f92823          	sw	a5,368(s2)
    release(&proc[lst->tail].list_lock);
    80001938:	40c8                	lw	a0,4(s1)
    8000193a:	03550533          	mul	a0,a0,s5
    8000193e:	17850513          	addi	a0,a0,376
    80001942:	9552                	add	a0,a0,s4
    80001944:	fffff097          	auipc	ra,0xfffff
    80001948:	354080e7          	jalr	852(ra) # 80000c98 <release>
    8000194c:	bf9d                	j	800018c2 <append+0x3c>

000000008000194e <remove>:

void 
remove(struct linked_list *lst, struct proc *p){
    8000194e:	7179                	addi	sp,sp,-48
    80001950:	f406                	sd	ra,40(sp)
    80001952:	f022                	sd	s0,32(sp)
    80001954:	ec26                	sd	s1,24(sp)
    80001956:	e84a                	sd	s2,16(sp)
    80001958:	e44e                	sd	s3,8(sp)
    8000195a:	e052                	sd	s4,0(sp)
    8000195c:	1800                	addi	s0,sp,48
    8000195e:	892a                	mv	s2,a0
    80001960:	84ae                	mv	s1,a1
  acquire(&lst->head_lock);
    80001962:	00850993          	addi	s3,a0,8
    80001966:	854e                	mv	a0,s3
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	27c080e7          	jalr	636(ra) # 80000be4 <acquire>
  h = lst->head == -1;
    80001970:	00092783          	lw	a5,0(s2)
  if(isEmpty(lst)){
    80001974:	577d                	li	a4,-1
    80001976:	0ae78263          	beq	a5,a4,80001a1a <remove+0xcc>
    release(&lst->head_lock);
    panic("list is empty\n");
  }

  if(lst->head == p->proc_ind){ // the required proc is the head
    8000197a:	1744a703          	lw	a4,372(s1)
    8000197e:	0af70b63          	beq	a4,a5,80001a34 <remove+0xe6>
      lst->tail = -1;
    }
    release(&lst->head_lock);
  }
  else{
    if (lst->tail == p->proc_ind) {
    80001982:	00492783          	lw	a5,4(s2)
    80001986:	0ee78763          	beq	a5,a4,80001a74 <remove+0x126>
      lst->tail = p->prev_proc;
    }
    release(&lst->head_lock); 
    8000198a:	854e                	mv	a0,s3
    8000198c:	fffff097          	auipc	ra,0xfffff
    80001990:	30c080e7          	jalr	780(ra) # 80000c98 <release>
    acquire(&p->list_lock);
    80001994:	17848993          	addi	s3,s1,376
    80001998:	854e                	mv	a0,s3
    8000199a:	fffff097          	auipc	ra,0xfffff
    8000199e:	24a080e7          	jalr	586(ra) # 80000be4 <acquire>
    acquire(&proc[p->prev_proc].list_lock);
    800019a2:	1704a503          	lw	a0,368(s1)
    800019a6:	19000a13          	li	s4,400
    800019aa:	03450533          	mul	a0,a0,s4
    800019ae:	17850513          	addi	a0,a0,376
    800019b2:	00010917          	auipc	s2,0x10
    800019b6:	e5e90913          	addi	s2,s2,-418 # 80011810 <proc>
    800019ba:	954a                	add	a0,a0,s2
    800019bc:	fffff097          	auipc	ra,0xfffff
    800019c0:	228080e7          	jalr	552(ra) # 80000be4 <acquire>
    proc[p->prev_proc].next_proc = p->next_proc;
    800019c4:	1704a703          	lw	a4,368(s1)
    800019c8:	16c4a783          	lw	a5,364(s1)
    800019cc:	03470733          	mul	a4,a4,s4
    800019d0:	974a                	add	a4,a4,s2
    800019d2:	16f72623          	sw	a5,364(a4)
    proc[p->next_proc].prev_proc = p->prev_proc; 
    800019d6:	1704a503          	lw	a0,368(s1)
    800019da:	034787b3          	mul	a5,a5,s4
    800019de:	97ca                	add	a5,a5,s2
    800019e0:	16a7a823          	sw	a0,368(a5)
    release(&proc[p->prev_proc].list_lock);
    800019e4:	03450533          	mul	a0,a0,s4
    800019e8:	17850513          	addi	a0,a0,376
    800019ec:	954a                	add	a0,a0,s2
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	2aa080e7          	jalr	682(ra) # 80000c98 <release>
    release(&p->list_lock);
    800019f6:	854e                	mv	a0,s3
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>
  }
  p->prev_proc = -1;
    80001a00:	57fd                	li	a5,-1
    80001a02:	16f4a823          	sw	a5,368(s1)
  p->next_proc = -1;
    80001a06:	16f4a623          	sw	a5,364(s1)
}
    80001a0a:	70a2                	ld	ra,40(sp)
    80001a0c:	7402                	ld	s0,32(sp)
    80001a0e:	64e2                	ld	s1,24(sp)
    80001a10:	6942                	ld	s2,16(sp)
    80001a12:	69a2                	ld	s3,8(sp)
    80001a14:	6a02                	ld	s4,0(sp)
    80001a16:	6145                	addi	sp,sp,48
    80001a18:	8082                	ret
    release(&lst->head_lock);
    80001a1a:	854e                	mv	a0,s3
    80001a1c:	fffff097          	auipc	ra,0xfffff
    80001a20:	27c080e7          	jalr	636(ra) # 80000c98 <release>
    panic("list is empty\n");
    80001a24:	00006517          	auipc	a0,0x6
    80001a28:	7b450513          	addi	a0,a0,1972 # 800081d8 <digits+0x198>
    80001a2c:	fffff097          	auipc	ra,0xfffff
    80001a30:	b12080e7          	jalr	-1262(ra) # 8000053e <panic>
    lst->head = p->next_proc;
    80001a34:	16c4a783          	lw	a5,364(s1)
    80001a38:	00f92023          	sw	a5,0(s2)
    proc[p->next_proc].prev_proc = -1;
    80001a3c:	19000713          	li	a4,400
    80001a40:	02e787b3          	mul	a5,a5,a4
    80001a44:	00010717          	auipc	a4,0x10
    80001a48:	dcc70713          	addi	a4,a4,-564 # 80011810 <proc>
    80001a4c:	97ba                	add	a5,a5,a4
    80001a4e:	577d                	li	a4,-1
    80001a50:	16e7a823          	sw	a4,368(a5)
    if(lst->tail == p->proc_ind){
    80001a54:	00492703          	lw	a4,4(s2)
    80001a58:	1744a783          	lw	a5,372(s1)
    80001a5c:	00f70863          	beq	a4,a5,80001a6c <remove+0x11e>
    release(&lst->head_lock);
    80001a60:	854e                	mv	a0,s3
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	236080e7          	jalr	566(ra) # 80000c98 <release>
    80001a6a:	bf59                	j	80001a00 <remove+0xb2>
      lst->tail = -1;
    80001a6c:	57fd                	li	a5,-1
    80001a6e:	00f92223          	sw	a5,4(s2)
    80001a72:	b7fd                	j	80001a60 <remove+0x112>
      lst->tail = p->prev_proc;
    80001a74:	1704a783          	lw	a5,368(s1)
    80001a78:	00f92223          	sw	a5,4(s2)
    80001a7c:	b739                	j	8000198a <remove+0x3c>

0000000080001a7e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001a7e:	7139                	addi	sp,sp,-64
    80001a80:	fc06                	sd	ra,56(sp)
    80001a82:	f822                	sd	s0,48(sp)
    80001a84:	f426                	sd	s1,40(sp)
    80001a86:	f04a                	sd	s2,32(sp)
    80001a88:	ec4e                	sd	s3,24(sp)
    80001a8a:	e852                	sd	s4,16(sp)
    80001a8c:	e456                	sd	s5,8(sp)
    80001a8e:	e05a                	sd	s6,0(sp)
    80001a90:	0080                	addi	s0,sp,64
    80001a92:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a94:	00010497          	auipc	s1,0x10
    80001a98:	d7c48493          	addi	s1,s1,-644 # 80011810 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001a9c:	8b26                	mv	s6,s1
    80001a9e:	00006a97          	auipc	s5,0x6
    80001aa2:	562a8a93          	addi	s5,s5,1378 # 80008000 <etext>
    80001aa6:	04000937          	lui	s2,0x4000
    80001aaa:	197d                	addi	s2,s2,-1
    80001aac:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001aae:	00016a17          	auipc	s4,0x16
    80001ab2:	162a0a13          	addi	s4,s4,354 # 80017c10 <tickslock>
    char *pa = kalloc();
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	03e080e7          	jalr	62(ra) # 80000af4 <kalloc>
    80001abe:	862a                	mv	a2,a0
    if(pa == 0)
    80001ac0:	c131                	beqz	a0,80001b04 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001ac2:	416485b3          	sub	a1,s1,s6
    80001ac6:	8591                	srai	a1,a1,0x4
    80001ac8:	000ab783          	ld	a5,0(s5)
    80001acc:	02f585b3          	mul	a1,a1,a5
    80001ad0:	2585                	addiw	a1,a1,1
    80001ad2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ad6:	4719                	li	a4,6
    80001ad8:	6685                	lui	a3,0x1
    80001ada:	40b905b3          	sub	a1,s2,a1
    80001ade:	854e                	mv	a0,s3
    80001ae0:	fffff097          	auipc	ra,0xfffff
    80001ae4:	670080e7          	jalr	1648(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ae8:	19048493          	addi	s1,s1,400
    80001aec:	fd4495e3          	bne	s1,s4,80001ab6 <proc_mapstacks+0x38>
  }
}
    80001af0:	70e2                	ld	ra,56(sp)
    80001af2:	7442                	ld	s0,48(sp)
    80001af4:	74a2                	ld	s1,40(sp)
    80001af6:	7902                	ld	s2,32(sp)
    80001af8:	69e2                	ld	s3,24(sp)
    80001afa:	6a42                	ld	s4,16(sp)
    80001afc:	6aa2                	ld	s5,8(sp)
    80001afe:	6b02                	ld	s6,0(sp)
    80001b00:	6121                	addi	sp,sp,64
    80001b02:	8082                	ret
      panic("kalloc");
    80001b04:	00006517          	auipc	a0,0x6
    80001b08:	6e450513          	addi	a0,a0,1764 # 800081e8 <digits+0x1a8>
    80001b0c:	fffff097          	auipc	ra,0xfffff
    80001b10:	a32080e7          	jalr	-1486(ra) # 8000053e <panic>

0000000080001b14 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001b14:	711d                	addi	sp,sp,-96
    80001b16:	ec86                	sd	ra,88(sp)
    80001b18:	e8a2                	sd	s0,80(sp)
    80001b1a:	e4a6                	sd	s1,72(sp)
    80001b1c:	e0ca                	sd	s2,64(sp)
    80001b1e:	fc4e                	sd	s3,56(sp)
    80001b20:	f852                	sd	s4,48(sp)
    80001b22:	f456                	sd	s5,40(sp)
    80001b24:	f05a                	sd	s6,32(sp)
    80001b26:	ec5e                	sd	s7,24(sp)
    80001b28:	e862                	sd	s8,16(sp)
    80001b2a:	e466                	sd	s9,8(sp)
    80001b2c:	e06a                	sd	s10,0(sp)
    80001b2e:	1080                	addi	s0,sp,96
  #ifdef ON
    flag = 1;
  #endif


  initlock(sleep_lock, "sleeping_list_head_lock");
    80001b30:	00006597          	auipc	a1,0x6
    80001b34:	6c058593          	addi	a1,a1,1728 # 800081f0 <digits+0x1b0>
    80001b38:	00007517          	auipc	a0,0x7
    80001b3c:	d9050513          	addi	a0,a0,-624 # 800088c8 <sleeping_list+0x8>
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	014080e7          	jalr	20(ra) # 80000b54 <initlock>
  initlock(zombie_lock, "zombie_list_head_lock");
    80001b48:	00006597          	auipc	a1,0x6
    80001b4c:	6c058593          	addi	a1,a1,1728 # 80008208 <digits+0x1c8>
    80001b50:	00007517          	auipc	a0,0x7
    80001b54:	d9850513          	addi	a0,a0,-616 # 800088e8 <zombie_list+0x8>
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	ffc080e7          	jalr	-4(ra) # 80000b54 <initlock>
  initlock(unused_lock, "unused_list_head_lock");
    80001b60:	00006597          	auipc	a1,0x6
    80001b64:	6c058593          	addi	a1,a1,1728 # 80008220 <digits+0x1e0>
    80001b68:	00007517          	auipc	a0,0x7
    80001b6c:	da050513          	addi	a0,a0,-608 # 80008908 <unused_list+0x8>
    80001b70:	fffff097          	auipc	ra,0xfffff
    80001b74:	fe4080e7          	jalr	-28(ra) # 80000b54 <initlock>
  initlock(&pid_lock, "nextpid");
    80001b78:	00006597          	auipc	a1,0x6
    80001b7c:	6c058593          	addi	a1,a1,1728 # 80008238 <digits+0x1f8>
    80001b80:	0000f517          	auipc	a0,0xf
    80001b84:	72050513          	addi	a0,a0,1824 # 800112a0 <pid_lock>
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	fcc080e7          	jalr	-52(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b90:	00006597          	auipc	a1,0x6
    80001b94:	6b058593          	addi	a1,a1,1712 # 80008240 <digits+0x200>
    80001b98:	0000f517          	auipc	a0,0xf
    80001b9c:	72050513          	addi	a0,a0,1824 # 800112b8 <wait_lock>
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	fb4080e7          	jalr	-76(ra) # 80000b54 <initlock>
  int i = 0;
    80001ba8:	4901                	li	s2,0

  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001baa:	00010497          	auipc	s1,0x10
    80001bae:	c6648493          	addi	s1,s1,-922 # 80011810 <proc>
      initlock(&p->lock, "proc");
    80001bb2:	00006d17          	auipc	s10,0x6
    80001bb6:	69ed0d13          	addi	s10,s10,1694 # 80008250 <digits+0x210>
      initlock(&p->list_lock, "list_lock");
    80001bba:	00006c97          	auipc	s9,0x6
    80001bbe:	69ec8c93          	addi	s9,s9,1694 # 80008258 <digits+0x218>
      p->kstack = KSTACK((int) (p - proc));
    80001bc2:	8c26                	mv	s8,s1
    80001bc4:	00006b97          	auipc	s7,0x6
    80001bc8:	43cb8b93          	addi	s7,s7,1084 # 80008000 <etext>
    80001bcc:	04000a37          	lui	s4,0x4000
    80001bd0:	1a7d                	addi	s4,s4,-1
    80001bd2:	0a32                	slli	s4,s4,0xc
      p->proc_ind = i;
      i=i+1;
      p->prev_proc = -1;
    80001bd4:	59fd                	li	s3,-1
      p->next_proc = -1;

      struct linked_list *add_to_unused_list = &unused_list;
      append(add_to_unused_list, p); 
    80001bd6:	00007b17          	auipc	s6,0x7
    80001bda:	d2ab0b13          	addi	s6,s6,-726 # 80008900 <unused_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bde:	00016a97          	auipc	s5,0x16
    80001be2:	032a8a93          	addi	s5,s5,50 # 80017c10 <tickslock>
      initlock(&p->lock, "proc");
    80001be6:	85ea                	mv	a1,s10
    80001be8:	8526                	mv	a0,s1
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	f6a080e7          	jalr	-150(ra) # 80000b54 <initlock>
      initlock(&p->list_lock, "list_lock");
    80001bf2:	85e6                	mv	a1,s9
    80001bf4:	17848513          	addi	a0,s1,376
    80001bf8:	fffff097          	auipc	ra,0xfffff
    80001bfc:	f5c080e7          	jalr	-164(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001c00:	418487b3          	sub	a5,s1,s8
    80001c04:	8791                	srai	a5,a5,0x4
    80001c06:	000bb703          	ld	a4,0(s7)
    80001c0a:	02e787b3          	mul	a5,a5,a4
    80001c0e:	2785                	addiw	a5,a5,1
    80001c10:	00d7979b          	slliw	a5,a5,0xd
    80001c14:	40fa07b3          	sub	a5,s4,a5
    80001c18:	e0bc                	sd	a5,64(s1)
      p->proc_ind = i;
    80001c1a:	1724aa23          	sw	s2,372(s1)
      i=i+1;
    80001c1e:	2905                	addiw	s2,s2,1
      p->prev_proc = -1;
    80001c20:	1734a823          	sw	s3,368(s1)
      p->next_proc = -1;
    80001c24:	1734a623          	sw	s3,364(s1)
      append(add_to_unused_list, p); 
    80001c28:	85a6                	mv	a1,s1
    80001c2a:	855a                	mv	a0,s6
    80001c2c:	00000097          	auipc	ra,0x0
    80001c30:	c5a080e7          	jalr	-934(ra) # 80001886 <append>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c34:	19048493          	addi	s1,s1,400
    80001c38:	fb5497e3          	bne	s1,s5,80001be6 <procinit+0xd2>
    80001c3c:	0000f497          	auipc	s1,0xf
    80001c40:	72448493          	addi	s1,s1,1828 # 80011360 <cpus+0x90>
    80001c44:	00010a17          	auipc	s4,0x10
    80001c48:	c5ca0a13          	addi	s4,s4,-932 # 800118a0 <proc+0x90>
  }

  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    struct linked_list empty_list = (struct linked_list){-1};
    c->runnable_list = empty_list;
    80001c4c:	59fd                	li	s3,-1
    c->proc_cnt = 0;
    struct spinlock *runnable_head = &c->runnable_list.head_lock;
    initlock(runnable_head, "cpu_runnable_list_head_lock");
    80001c4e:	00006917          	auipc	s2,0x6
    80001c52:	61a90913          	addi	s2,s2,1562 # 80008268 <digits+0x228>
    c->runnable_list = empty_list;
    80001c56:	ff34ac23          	sw	s3,-8(s1)
    80001c5a:	fe04ae23          	sw	zero,-4(s1)
    80001c5e:	0004a023          	sw	zero,0(s1)
    80001c62:	0004b423          	sd	zero,8(s1)
    80001c66:	0004b823          	sd	zero,16(s1)
    c->proc_cnt = 0;
    80001c6a:	fe04a823          	sw	zero,-16(s1)
    initlock(runnable_head, "cpu_runnable_list_head_lock");
    80001c6e:	85ca                	mv	a1,s2
    80001c70:	8526                	mv	a0,s1
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	ee2080e7          	jalr	-286(ra) # 80000b54 <initlock>
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001c7a:	0a848493          	addi	s1,s1,168
    80001c7e:	fd449ce3          	bne	s1,s4,80001c56 <procinit+0x142>
  }
}
    80001c82:	60e6                	ld	ra,88(sp)
    80001c84:	6446                	ld	s0,80(sp)
    80001c86:	64a6                	ld	s1,72(sp)
    80001c88:	6906                	ld	s2,64(sp)
    80001c8a:	79e2                	ld	s3,56(sp)
    80001c8c:	7a42                	ld	s4,48(sp)
    80001c8e:	7aa2                	ld	s5,40(sp)
    80001c90:	7b02                	ld	s6,32(sp)
    80001c92:	6be2                	ld	s7,24(sp)
    80001c94:	6c42                	ld	s8,16(sp)
    80001c96:	6ca2                	ld	s9,8(sp)
    80001c98:	6d02                	ld	s10,0(sp)
    80001c9a:	6125                	addi	sp,sp,96
    80001c9c:	8082                	ret

0000000080001c9e <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001c9e:	1141                	addi	sp,sp,-16
    80001ca0:	e422                	sd	s0,8(sp)
    80001ca2:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ca4:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001ca6:	2501                	sext.w	a0,a0
    80001ca8:	6422                	ld	s0,8(sp)
    80001caa:	0141                	addi	sp,sp,16
    80001cac:	8082                	ret

0000000080001cae <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001cae:	1141                	addi	sp,sp,-16
    80001cb0:	e422                	sd	s0,8(sp)
    80001cb2:	0800                	addi	s0,sp,16
    80001cb4:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001cb6:	2781                	sext.w	a5,a5
    80001cb8:	0a800513          	li	a0,168
    80001cbc:	02a787b3          	mul	a5,a5,a0
  return c;
}
    80001cc0:	0000f517          	auipc	a0,0xf
    80001cc4:	61050513          	addi	a0,a0,1552 # 800112d0 <cpus>
    80001cc8:	953e                	add	a0,a0,a5
    80001cca:	6422                	ld	s0,8(sp)
    80001ccc:	0141                	addi	sp,sp,16
    80001cce:	8082                	ret

0000000080001cd0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001cd0:	1101                	addi	sp,sp,-32
    80001cd2:	ec06                	sd	ra,24(sp)
    80001cd4:	e822                	sd	s0,16(sp)
    80001cd6:	e426                	sd	s1,8(sp)
    80001cd8:	1000                	addi	s0,sp,32
  push_off();
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	ebe080e7          	jalr	-322(ra) # 80000b98 <push_off>
    80001ce2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ce4:	2781                	sext.w	a5,a5
    80001ce6:	0a800713          	li	a4,168
    80001cea:	02e787b3          	mul	a5,a5,a4
    80001cee:	0000f717          	auipc	a4,0xf
    80001cf2:	5b270713          	addi	a4,a4,1458 # 800112a0 <pid_lock>
    80001cf6:	97ba                	add	a5,a5,a4
    80001cf8:	7b84                	ld	s1,48(a5)
  pop_off();
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	f3e080e7          	jalr	-194(ra) # 80000c38 <pop_off>
  return p;
}
    80001d02:	8526                	mv	a0,s1
    80001d04:	60e2                	ld	ra,24(sp)
    80001d06:	6442                	ld	s0,16(sp)
    80001d08:	64a2                	ld	s1,8(sp)
    80001d0a:	6105                	addi	sp,sp,32
    80001d0c:	8082                	ret

0000000080001d0e <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001d0e:	1141                	addi	sp,sp,-16
    80001d10:	e406                	sd	ra,8(sp)
    80001d12:	e022                	sd	s0,0(sp)
    80001d14:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001d16:	00000097          	auipc	ra,0x0
    80001d1a:	fba080e7          	jalr	-70(ra) # 80001cd0 <myproc>
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	f7a080e7          	jalr	-134(ra) # 80000c98 <release>

  if (first) {
    80001d26:	00007797          	auipc	a5,0x7
    80001d2a:	b8a7a783          	lw	a5,-1142(a5) # 800088b0 <first.1750>
    80001d2e:	eb89                	bnez	a5,80001d40 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001d30:	00001097          	auipc	ra,0x1
    80001d34:	f30080e7          	jalr	-208(ra) # 80002c60 <usertrapret>
}
    80001d38:	60a2                	ld	ra,8(sp)
    80001d3a:	6402                	ld	s0,0(sp)
    80001d3c:	0141                	addi	sp,sp,16
    80001d3e:	8082                	ret
    first = 0;
    80001d40:	00007797          	auipc	a5,0x7
    80001d44:	b607a823          	sw	zero,-1168(a5) # 800088b0 <first.1750>
    fsinit(ROOTDEV);
    80001d48:	4505                	li	a0,1
    80001d4a:	00002097          	auipc	ra,0x2
    80001d4e:	ca2080e7          	jalr	-862(ra) # 800039ec <fsinit>
    80001d52:	bff9                	j	80001d30 <forkret+0x22>

0000000080001d54 <allocpid>:
allocpid() {
    80001d54:	1101                	addi	sp,sp,-32
    80001d56:	ec06                	sd	ra,24(sp)
    80001d58:	e822                	sd	s0,16(sp)
    80001d5a:	e426                	sd	s1,8(sp)
    80001d5c:	e04a                	sd	s2,0(sp)
    80001d5e:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001d60:	00007917          	auipc	s2,0x7
    80001d64:	b5490913          	addi	s2,s2,-1196 # 800088b4 <nextpid>
    80001d68:	00092483          	lw	s1,0(s2)
  while (cas(&nextpid, pid, nextpid + 1));
    80001d6c:	0014861b          	addiw	a2,s1,1
    80001d70:	85a6                	mv	a1,s1
    80001d72:	854a                	mv	a0,s2
    80001d74:	00005097          	auipc	ra,0x5
    80001d78:	a82080e7          	jalr	-1406(ra) # 800067f6 <cas>
    80001d7c:	2501                	sext.w	a0,a0
    80001d7e:	f56d                	bnez	a0,80001d68 <allocpid+0x14>
}
    80001d80:	8526                	mv	a0,s1
    80001d82:	60e2                	ld	ra,24(sp)
    80001d84:	6442                	ld	s0,16(sp)
    80001d86:	64a2                	ld	s1,8(sp)
    80001d88:	6902                	ld	s2,0(sp)
    80001d8a:	6105                	addi	sp,sp,32
    80001d8c:	8082                	ret

0000000080001d8e <proc_pagetable>:
{
    80001d8e:	1101                	addi	sp,sp,-32
    80001d90:	ec06                	sd	ra,24(sp)
    80001d92:	e822                	sd	s0,16(sp)
    80001d94:	e426                	sd	s1,8(sp)
    80001d96:	e04a                	sd	s2,0(sp)
    80001d98:	1000                	addi	s0,sp,32
    80001d9a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001d9c:	fffff097          	auipc	ra,0xfffff
    80001da0:	59e080e7          	jalr	1438(ra) # 8000133a <uvmcreate>
    80001da4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001da6:	c121                	beqz	a0,80001de6 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001da8:	4729                	li	a4,10
    80001daa:	00005697          	auipc	a3,0x5
    80001dae:	25668693          	addi	a3,a3,598 # 80007000 <_trampoline>
    80001db2:	6605                	lui	a2,0x1
    80001db4:	040005b7          	lui	a1,0x4000
    80001db8:	15fd                	addi	a1,a1,-1
    80001dba:	05b2                	slli	a1,a1,0xc
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	2f4080e7          	jalr	756(ra) # 800010b0 <mappages>
    80001dc4:	02054863          	bltz	a0,80001df4 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001dc8:	4719                	li	a4,6
    80001dca:	05893683          	ld	a3,88(s2)
    80001dce:	6605                	lui	a2,0x1
    80001dd0:	020005b7          	lui	a1,0x2000
    80001dd4:	15fd                	addi	a1,a1,-1
    80001dd6:	05b6                	slli	a1,a1,0xd
    80001dd8:	8526                	mv	a0,s1
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	2d6080e7          	jalr	726(ra) # 800010b0 <mappages>
    80001de2:	02054163          	bltz	a0,80001e04 <proc_pagetable+0x76>
}
    80001de6:	8526                	mv	a0,s1
    80001de8:	60e2                	ld	ra,24(sp)
    80001dea:	6442                	ld	s0,16(sp)
    80001dec:	64a2                	ld	s1,8(sp)
    80001dee:	6902                	ld	s2,0(sp)
    80001df0:	6105                	addi	sp,sp,32
    80001df2:	8082                	ret
    uvmfree(pagetable, 0);
    80001df4:	4581                	li	a1,0
    80001df6:	8526                	mv	a0,s1
    80001df8:	fffff097          	auipc	ra,0xfffff
    80001dfc:	73e080e7          	jalr	1854(ra) # 80001536 <uvmfree>
    return 0;
    80001e00:	4481                	li	s1,0
    80001e02:	b7d5                	j	80001de6 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e04:	4681                	li	a3,0
    80001e06:	4605                	li	a2,1
    80001e08:	040005b7          	lui	a1,0x4000
    80001e0c:	15fd                	addi	a1,a1,-1
    80001e0e:	05b2                	slli	a1,a1,0xc
    80001e10:	8526                	mv	a0,s1
    80001e12:	fffff097          	auipc	ra,0xfffff
    80001e16:	464080e7          	jalr	1124(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001e1a:	4581                	li	a1,0
    80001e1c:	8526                	mv	a0,s1
    80001e1e:	fffff097          	auipc	ra,0xfffff
    80001e22:	718080e7          	jalr	1816(ra) # 80001536 <uvmfree>
    return 0;
    80001e26:	4481                	li	s1,0
    80001e28:	bf7d                	j	80001de6 <proc_pagetable+0x58>

0000000080001e2a <proc_freepagetable>:
{
    80001e2a:	1101                	addi	sp,sp,-32
    80001e2c:	ec06                	sd	ra,24(sp)
    80001e2e:	e822                	sd	s0,16(sp)
    80001e30:	e426                	sd	s1,8(sp)
    80001e32:	e04a                	sd	s2,0(sp)
    80001e34:	1000                	addi	s0,sp,32
    80001e36:	84aa                	mv	s1,a0
    80001e38:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e3a:	4681                	li	a3,0
    80001e3c:	4605                	li	a2,1
    80001e3e:	040005b7          	lui	a1,0x4000
    80001e42:	15fd                	addi	a1,a1,-1
    80001e44:	05b2                	slli	a1,a1,0xc
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	430080e7          	jalr	1072(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e4e:	4681                	li	a3,0
    80001e50:	4605                	li	a2,1
    80001e52:	020005b7          	lui	a1,0x2000
    80001e56:	15fd                	addi	a1,a1,-1
    80001e58:	05b6                	slli	a1,a1,0xd
    80001e5a:	8526                	mv	a0,s1
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	41a080e7          	jalr	1050(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001e64:	85ca                	mv	a1,s2
    80001e66:	8526                	mv	a0,s1
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	6ce080e7          	jalr	1742(ra) # 80001536 <uvmfree>
}
    80001e70:	60e2                	ld	ra,24(sp)
    80001e72:	6442                	ld	s0,16(sp)
    80001e74:	64a2                	ld	s1,8(sp)
    80001e76:	6902                	ld	s2,0(sp)
    80001e78:	6105                	addi	sp,sp,32
    80001e7a:	8082                	ret

0000000080001e7c <freeproc>:
{
    80001e7c:	1101                	addi	sp,sp,-32
    80001e7e:	ec06                	sd	ra,24(sp)
    80001e80:	e822                	sd	s0,16(sp)
    80001e82:	e426                	sd	s1,8(sp)
    80001e84:	1000                	addi	s0,sp,32
    80001e86:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001e88:	6d28                	ld	a0,88(a0)
    80001e8a:	c509                	beqz	a0,80001e94 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	b6c080e7          	jalr	-1172(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001e94:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001e98:	68a8                	ld	a0,80(s1)
    80001e9a:	c511                	beqz	a0,80001ea6 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001e9c:	64ac                	ld	a1,72(s1)
    80001e9e:	00000097          	auipc	ra,0x0
    80001ea2:	f8c080e7          	jalr	-116(ra) # 80001e2a <proc_freepagetable>
  p->pagetable = 0;
    80001ea6:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001eaa:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001eae:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001eb2:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001eb6:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001eba:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ebe:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ec2:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ec6:	0004ac23          	sw	zero,24(s1)
  remove(remove_from_ZOMBIE_list, p); 
    80001eca:	85a6                	mv	a1,s1
    80001ecc:	00007517          	auipc	a0,0x7
    80001ed0:	a1450513          	addi	a0,a0,-1516 # 800088e0 <zombie_list>
    80001ed4:	00000097          	auipc	ra,0x0
    80001ed8:	a7a080e7          	jalr	-1414(ra) # 8000194e <remove>
  append(add_to_UNUSED_list, p); 
    80001edc:	85a6                	mv	a1,s1
    80001ede:	00007517          	auipc	a0,0x7
    80001ee2:	a2250513          	addi	a0,a0,-1502 # 80008900 <unused_list>
    80001ee6:	00000097          	auipc	ra,0x0
    80001eea:	9a0080e7          	jalr	-1632(ra) # 80001886 <append>
}
    80001eee:	60e2                	ld	ra,24(sp)
    80001ef0:	6442                	ld	s0,16(sp)
    80001ef2:	64a2                	ld	s1,8(sp)
    80001ef4:	6105                	addi	sp,sp,32
    80001ef6:	8082                	ret

0000000080001ef8 <allocproc>:
{
    80001ef8:	715d                	addi	sp,sp,-80
    80001efa:	e486                	sd	ra,72(sp)
    80001efc:	e0a2                	sd	s0,64(sp)
    80001efe:	fc26                	sd	s1,56(sp)
    80001f00:	f84a                	sd	s2,48(sp)
    80001f02:	f44e                	sd	s3,40(sp)
    80001f04:	f052                	sd	s4,32(sp)
    80001f06:	ec56                	sd	s5,24(sp)
    80001f08:	e85a                	sd	s6,16(sp)
    80001f0a:	e45e                	sd	s7,8(sp)
    80001f0c:	0880                	addi	s0,sp,80
  while(!(unused_list.head == empty)) {
    80001f0e:	00007917          	auipc	s2,0x7
    80001f12:	9f292903          	lw	s2,-1550(s2) # 80008900 <unused_list>
    80001f16:	57fd                	li	a5,-1
    80001f18:	12f90d63          	beq	s2,a5,80002052 <allocproc+0x15a>
    80001f1c:	19000a93          	li	s5,400
    p = &proc[unused_list.head];
    80001f20:	00010a17          	auipc	s4,0x10
    80001f24:	8f0a0a13          	addi	s4,s4,-1808 # 80011810 <proc>
  while(!(unused_list.head == empty)) {
    80001f28:	00007b97          	auipc	s7,0x7
    80001f2c:	998b8b93          	addi	s7,s7,-1640 # 800088c0 <sleeping_list>
    80001f30:	5b7d                	li	s6,-1
    p = &proc[unused_list.head];
    80001f32:	035909b3          	mul	s3,s2,s5
    80001f36:	014984b3          	add	s1,s3,s4
    acquire(&p->lock);
    80001f3a:	8526                	mv	a0,s1
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	ca8080e7          	jalr	-856(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001f44:	4c9c                	lw	a5,24(s1)
    80001f46:	c79d                	beqz	a5,80001f74 <allocproc+0x7c>
      release(&p->lock);
    80001f48:	8526                	mv	a0,s1
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	d4e080e7          	jalr	-690(ra) # 80000c98 <release>
  while(!(unused_list.head == empty)) {
    80001f52:	040ba903          	lw	s2,64(s7)
    80001f56:	fd691ee3          	bne	s2,s6,80001f32 <allocproc+0x3a>
  return 0;
    80001f5a:	4481                	li	s1,0
}
    80001f5c:	8526                	mv	a0,s1
    80001f5e:	60a6                	ld	ra,72(sp)
    80001f60:	6406                	ld	s0,64(sp)
    80001f62:	74e2                	ld	s1,56(sp)
    80001f64:	7942                	ld	s2,48(sp)
    80001f66:	79a2                	ld	s3,40(sp)
    80001f68:	7a02                	ld	s4,32(sp)
    80001f6a:	6ae2                	ld	s5,24(sp)
    80001f6c:	6b42                	ld	s6,16(sp)
    80001f6e:	6ba2                	ld	s7,8(sp)
    80001f70:	6161                	addi	sp,sp,80
    80001f72:	8082                	ret
      remove(remove_from_unused_list, p); 
    80001f74:	85a6                	mv	a1,s1
    80001f76:	00007517          	auipc	a0,0x7
    80001f7a:	98a50513          	addi	a0,a0,-1654 # 80008900 <unused_list>
    80001f7e:	00000097          	auipc	ra,0x0
    80001f82:	9d0080e7          	jalr	-1584(ra) # 8000194e <remove>
  p->pid = allocpid();
    80001f86:	00000097          	auipc	ra,0x0
    80001f8a:	dce080e7          	jalr	-562(ra) # 80001d54 <allocpid>
    80001f8e:	19000a13          	li	s4,400
    80001f92:	034907b3          	mul	a5,s2,s4
    80001f96:	00010a17          	auipc	s4,0x10
    80001f9a:	87aa0a13          	addi	s4,s4,-1926 # 80011810 <proc>
    80001f9e:	9a3e                	add	s4,s4,a5
    80001fa0:	02aa2823          	sw	a0,48(s4)
  p->state = USED;
    80001fa4:	4785                	li	a5,1
    80001fa6:	00fa2c23          	sw	a5,24(s4)
  p->last_cpu = -1;
    80001faa:	57fd                	li	a5,-1
    80001fac:	16fa2423          	sw	a5,360(s4)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	b44080e7          	jalr	-1212(ra) # 80000af4 <kalloc>
    80001fb8:	8aaa                	mv	s5,a0
    80001fba:	04aa3c23          	sd	a0,88(s4)
    80001fbe:	c135                	beqz	a0,80002022 <allocproc+0x12a>
  p->pagetable = proc_pagetable(p);
    80001fc0:	8526                	mv	a0,s1
    80001fc2:	00000097          	auipc	ra,0x0
    80001fc6:	dcc080e7          	jalr	-564(ra) # 80001d8e <proc_pagetable>
    80001fca:	8a2a                	mv	s4,a0
    80001fcc:	19000793          	li	a5,400
    80001fd0:	02f90733          	mul	a4,s2,a5
    80001fd4:	00010797          	auipc	a5,0x10
    80001fd8:	83c78793          	addi	a5,a5,-1988 # 80011810 <proc>
    80001fdc:	97ba                	add	a5,a5,a4
    80001fde:	eba8                	sd	a0,80(a5)
  if(p->pagetable == 0){
    80001fe0:	cd29                	beqz	a0,8000203a <allocproc+0x142>
  memset(&p->context, 0, sizeof(p->context));
    80001fe2:	06098513          	addi	a0,s3,96 # 1060 <_entry-0x7fffefa0>
    80001fe6:	00010997          	auipc	s3,0x10
    80001fea:	82a98993          	addi	s3,s3,-2006 # 80011810 <proc>
    80001fee:	07000613          	li	a2,112
    80001ff2:	4581                	li	a1,0
    80001ff4:	954e                	add	a0,a0,s3
    80001ff6:	fffff097          	auipc	ra,0xfffff
    80001ffa:	cea080e7          	jalr	-790(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001ffe:	19000793          	li	a5,400
    80002002:	02f90933          	mul	s2,s2,a5
    80002006:	994e                	add	s2,s2,s3
    80002008:	00000797          	auipc	a5,0x0
    8000200c:	d0678793          	addi	a5,a5,-762 # 80001d0e <forkret>
    80002010:	06f93023          	sd	a5,96(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002014:	04093783          	ld	a5,64(s2)
    80002018:	6705                	lui	a4,0x1
    8000201a:	97ba                	add	a5,a5,a4
    8000201c:	06f93423          	sd	a5,104(s2)
  return p;
    80002020:	bf35                	j	80001f5c <allocproc+0x64>
    freeproc(p);
    80002022:	8526                	mv	a0,s1
    80002024:	00000097          	auipc	ra,0x0
    80002028:	e58080e7          	jalr	-424(ra) # 80001e7c <freeproc>
    release(&p->lock);
    8000202c:	8526                	mv	a0,s1
    8000202e:	fffff097          	auipc	ra,0xfffff
    80002032:	c6a080e7          	jalr	-918(ra) # 80000c98 <release>
    return 0;
    80002036:	84d6                	mv	s1,s5
    80002038:	b715                	j	80001f5c <allocproc+0x64>
    freeproc(p);
    8000203a:	8526                	mv	a0,s1
    8000203c:	00000097          	auipc	ra,0x0
    80002040:	e40080e7          	jalr	-448(ra) # 80001e7c <freeproc>
    release(&p->lock);
    80002044:	8526                	mv	a0,s1
    80002046:	fffff097          	auipc	ra,0xfffff
    8000204a:	c52080e7          	jalr	-942(ra) # 80000c98 <release>
    return 0;
    8000204e:	84d2                	mv	s1,s4
    80002050:	b731                	j	80001f5c <allocproc+0x64>
  return 0;
    80002052:	4481                	li	s1,0
    80002054:	b721                	j	80001f5c <allocproc+0x64>

0000000080002056 <userinit>:
{
    80002056:	1101                	addi	sp,sp,-32
    80002058:	ec06                	sd	ra,24(sp)
    8000205a:	e822                	sd	s0,16(sp)
    8000205c:	e426                	sd	s1,8(sp)
    8000205e:	1000                	addi	s0,sp,32
  p = allocproc();
    80002060:	00000097          	auipc	ra,0x0
    80002064:	e98080e7          	jalr	-360(ra) # 80001ef8 <allocproc>
    80002068:	84aa                	mv	s1,a0
  initproc = p;
    8000206a:	00007797          	auipc	a5,0x7
    8000206e:	fca7b323          	sd	a0,-58(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002072:	03400613          	li	a2,52
    80002076:	00007597          	auipc	a1,0x7
    8000207a:	8aa58593          	addi	a1,a1,-1878 # 80008920 <initcode>
    8000207e:	6928                	ld	a0,80(a0)
    80002080:	fffff097          	auipc	ra,0xfffff
    80002084:	2e8080e7          	jalr	744(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80002088:	6785                	lui	a5,0x1
    8000208a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    8000208c:	6cb8                	ld	a4,88(s1)
    8000208e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002092:	6cb8                	ld	a4,88(s1)
    80002094:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002096:	4641                	li	a2,16
    80002098:	00006597          	auipc	a1,0x6
    8000209c:	1f058593          	addi	a1,a1,496 # 80008288 <digits+0x248>
    800020a0:	15848513          	addi	a0,s1,344
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	d8e080e7          	jalr	-626(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800020ac:	00006517          	auipc	a0,0x6
    800020b0:	1ec50513          	addi	a0,a0,492 # 80008298 <digits+0x258>
    800020b4:	00002097          	auipc	ra,0x2
    800020b8:	366080e7          	jalr	870(ra) # 8000441a <namei>
    800020bc:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    800020c0:	478d                	li	a5,3
    800020c2:	cc9c                	sw	a5,24(s1)
  append(l, p);
    800020c4:	85a6                	mv	a1,s1
    800020c6:	0000f517          	auipc	a0,0xf
    800020ca:	29250513          	addi	a0,a0,658 # 80011358 <cpus+0x88>
    800020ce:	fffff097          	auipc	ra,0xfffff
    800020d2:	7b8080e7          	jalr	1976(ra) # 80001886 <append>
  release(&p->lock);
    800020d6:	8526                	mv	a0,s1
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	bc0080e7          	jalr	-1088(ra) # 80000c98 <release>
}
    800020e0:	60e2                	ld	ra,24(sp)
    800020e2:	6442                	ld	s0,16(sp)
    800020e4:	64a2                	ld	s1,8(sp)
    800020e6:	6105                	addi	sp,sp,32
    800020e8:	8082                	ret

00000000800020ea <growproc>:
{
    800020ea:	1101                	addi	sp,sp,-32
    800020ec:	ec06                	sd	ra,24(sp)
    800020ee:	e822                	sd	s0,16(sp)
    800020f0:	e426                	sd	s1,8(sp)
    800020f2:	e04a                	sd	s2,0(sp)
    800020f4:	1000                	addi	s0,sp,32
    800020f6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800020f8:	00000097          	auipc	ra,0x0
    800020fc:	bd8080e7          	jalr	-1064(ra) # 80001cd0 <myproc>
    80002100:	892a                	mv	s2,a0
  sz = p->sz;
    80002102:	652c                	ld	a1,72(a0)
    80002104:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002108:	00904f63          	bgtz	s1,80002126 <growproc+0x3c>
  } else if(n < 0){
    8000210c:	0204cc63          	bltz	s1,80002144 <growproc+0x5a>
  p->sz = sz;
    80002110:	1602                	slli	a2,a2,0x20
    80002112:	9201                	srli	a2,a2,0x20
    80002114:	04c93423          	sd	a2,72(s2)
  return 0;
    80002118:	4501                	li	a0,0
}
    8000211a:	60e2                	ld	ra,24(sp)
    8000211c:	6442                	ld	s0,16(sp)
    8000211e:	64a2                	ld	s1,8(sp)
    80002120:	6902                	ld	s2,0(sp)
    80002122:	6105                	addi	sp,sp,32
    80002124:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002126:	9e25                	addw	a2,a2,s1
    80002128:	1602                	slli	a2,a2,0x20
    8000212a:	9201                	srli	a2,a2,0x20
    8000212c:	1582                	slli	a1,a1,0x20
    8000212e:	9181                	srli	a1,a1,0x20
    80002130:	6928                	ld	a0,80(a0)
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	2f0080e7          	jalr	752(ra) # 80001422 <uvmalloc>
    8000213a:	0005061b          	sext.w	a2,a0
    8000213e:	fa69                	bnez	a2,80002110 <growproc+0x26>
      return -1;
    80002140:	557d                	li	a0,-1
    80002142:	bfe1                	j	8000211a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002144:	9e25                	addw	a2,a2,s1
    80002146:	1602                	slli	a2,a2,0x20
    80002148:	9201                	srli	a2,a2,0x20
    8000214a:	1582                	slli	a1,a1,0x20
    8000214c:	9181                	srli	a1,a1,0x20
    8000214e:	6928                	ld	a0,80(a0)
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	28a080e7          	jalr	650(ra) # 800013da <uvmdealloc>
    80002158:	0005061b          	sext.w	a2,a0
    8000215c:	bf55                	j	80002110 <growproc+0x26>

000000008000215e <min_num_procs_cpu>:
min_num_procs_cpu(void){
    8000215e:	1141                	addi	sp,sp,-16
    80002160:	e422                	sd	s0,8(sp)
    80002162:	0800                	addi	s0,sp,16
  int min_cpu_proc_cnt = min_cpu->proc_cnt;
    80002164:	0000f517          	auipc	a0,0xf
    80002168:	1ec52503          	lw	a0,492(a0) # 80011350 <cpus+0x80>
  for(c = cpus + 1; c < &cpus[NCPU] && c != NULL ; c++){
    8000216c:	0000f797          	auipc	a5,0xf
    80002170:	20c78793          	addi	a5,a5,524 # 80011378 <cpus+0xa8>
    80002174:	0000f617          	auipc	a2,0xf
    80002178:	69c60613          	addi	a2,a2,1692 # 80011810 <proc>
    8000217c:	a039                	j	8000218a <min_num_procs_cpu+0x2c>
    8000217e:	0007051b          	sext.w	a0,a4
    80002182:	0a878793          	addi	a5,a5,168
    80002186:	00c78a63          	beq	a5,a2,8000219a <min_num_procs_cpu+0x3c>
    if (c->proc_cnt < min_cpu_proc_cnt) {
    8000218a:	0807a703          	lw	a4,128(a5)
    8000218e:	0007069b          	sext.w	a3,a4
    80002192:	fed556e3          	bge	a0,a3,8000217e <min_num_procs_cpu+0x20>
    80002196:	872a                	mv	a4,a0
    80002198:	b7dd                	j	8000217e <min_num_procs_cpu+0x20>
} 
    8000219a:	6422                	ld	s0,8(sp)
    8000219c:	0141                	addi	sp,sp,16
    8000219e:	8082                	ret

00000000800021a0 <fork>:
{
    800021a0:	7179                	addi	sp,sp,-48
    800021a2:	f406                	sd	ra,40(sp)
    800021a4:	f022                	sd	s0,32(sp)
    800021a6:	ec26                	sd	s1,24(sp)
    800021a8:	e84a                	sd	s2,16(sp)
    800021aa:	e44e                	sd	s3,8(sp)
    800021ac:	e052                	sd	s4,0(sp)
    800021ae:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021b0:	00000097          	auipc	ra,0x0
    800021b4:	b20080e7          	jalr	-1248(ra) # 80001cd0 <myproc>
    800021b8:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    800021ba:	00000097          	auipc	ra,0x0
    800021be:	d3e080e7          	jalr	-706(ra) # 80001ef8 <allocproc>
    800021c2:	16050863          	beqz	a0,80002332 <fork+0x192>
    800021c6:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800021c8:	0489b603          	ld	a2,72(s3)
    800021cc:	692c                	ld	a1,80(a0)
    800021ce:	0509b503          	ld	a0,80(s3)
    800021d2:	fffff097          	auipc	ra,0xfffff
    800021d6:	39c080e7          	jalr	924(ra) # 8000156e <uvmcopy>
    800021da:	04054663          	bltz	a0,80002226 <fork+0x86>
  np->sz = p->sz;
    800021de:	0489b783          	ld	a5,72(s3)
    800021e2:	04f93423          	sd	a5,72(s2)
  *(np->trapframe) = *(p->trapframe);
    800021e6:	0589b683          	ld	a3,88(s3)
    800021ea:	87b6                	mv	a5,a3
    800021ec:	05893703          	ld	a4,88(s2)
    800021f0:	12068693          	addi	a3,a3,288
    800021f4:	0007b803          	ld	a6,0(a5)
    800021f8:	6788                	ld	a0,8(a5)
    800021fa:	6b8c                	ld	a1,16(a5)
    800021fc:	6f90                	ld	a2,24(a5)
    800021fe:	01073023          	sd	a6,0(a4)
    80002202:	e708                	sd	a0,8(a4)
    80002204:	eb0c                	sd	a1,16(a4)
    80002206:	ef10                	sd	a2,24(a4)
    80002208:	02078793          	addi	a5,a5,32
    8000220c:	02070713          	addi	a4,a4,32
    80002210:	fed792e3          	bne	a5,a3,800021f4 <fork+0x54>
  np->trapframe->a0 = 0;
    80002214:	05893783          	ld	a5,88(s2)
    80002218:	0607b823          	sd	zero,112(a5)
    8000221c:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002220:	15000a13          	li	s4,336
    80002224:	a03d                	j	80002252 <fork+0xb2>
    freeproc(np);
    80002226:	854a                	mv	a0,s2
    80002228:	00000097          	auipc	ra,0x0
    8000222c:	c54080e7          	jalr	-940(ra) # 80001e7c <freeproc>
    release(&np->lock);
    80002230:	854a                	mv	a0,s2
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	a66080e7          	jalr	-1434(ra) # 80000c98 <release>
    return -1;
    8000223a:	5a7d                	li	s4,-1
    8000223c:	a8d9                	j	80002312 <fork+0x172>
      np->ofile[i] = filedup(p->ofile[i]);
    8000223e:	00003097          	auipc	ra,0x3
    80002242:	872080e7          	jalr	-1934(ra) # 80004ab0 <filedup>
    80002246:	009907b3          	add	a5,s2,s1
    8000224a:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    8000224c:	04a1                	addi	s1,s1,8
    8000224e:	01448763          	beq	s1,s4,8000225c <fork+0xbc>
    if(p->ofile[i])
    80002252:	009987b3          	add	a5,s3,s1
    80002256:	6388                	ld	a0,0(a5)
    80002258:	f17d                	bnez	a0,8000223e <fork+0x9e>
    8000225a:	bfcd                	j	8000224c <fork+0xac>
  np->cwd = idup(p->cwd);
    8000225c:	1509b503          	ld	a0,336(s3)
    80002260:	00002097          	auipc	ra,0x2
    80002264:	9c6080e7          	jalr	-1594(ra) # 80003c26 <idup>
    80002268:	14a93823          	sd	a0,336(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000226c:	4641                	li	a2,16
    8000226e:	15898593          	addi	a1,s3,344
    80002272:	15890513          	addi	a0,s2,344
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	bbc080e7          	jalr	-1092(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    8000227e:	03092a03          	lw	s4,48(s2)
  release(&np->lock);
    80002282:	854a                	mv	a0,s2
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	a14080e7          	jalr	-1516(ra) # 80000c98 <release>
  acquire(&wait_lock);
    8000228c:	0000f497          	auipc	s1,0xf
    80002290:	02c48493          	addi	s1,s1,44 # 800112b8 <wait_lock>
    80002294:	8526                	mv	a0,s1
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	94e080e7          	jalr	-1714(ra) # 80000be4 <acquire>
  np->parent = p;
    8000229e:	03393c23          	sd	s3,56(s2)
  release(&wait_lock);
    800022a2:	8526                	mv	a0,s1
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	9f4080e7          	jalr	-1548(ra) # 80000c98 <release>
  acquire(&np->lock);
    800022ac:	854a                	mv	a0,s2
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	936080e7          	jalr	-1738(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800022b6:	478d                	li	a5,3
    800022b8:	00f92c23          	sw	a5,24(s2)
  int last_cpu = p->last_cpu; 
    800022bc:	1689a783          	lw	a5,360(s3)
  np->last_cpu = last_cpu;
    800022c0:	16f92423          	sw	a5,360(s2)
  if (flag == 1)
    800022c4:	00007717          	auipc	a4,0x7
    800022c8:	d6472703          	lw	a4,-668(a4) # 80009028 <flag>
    800022cc:	4785                	li	a5,1
    800022ce:	04f70b63          	beq	a4,a5,80002324 <fork+0x184>
  inc_cpu(&cpus[np->last_cpu]);
    800022d2:	0000f497          	auipc	s1,0xf
    800022d6:	ffe48493          	addi	s1,s1,-2 # 800112d0 <cpus>
    800022da:	16892503          	lw	a0,360(s2)
    800022de:	0a800993          	li	s3,168
    800022e2:	03350533          	mul	a0,a0,s3
    800022e6:	9526                	add	a0,a0,s1
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	556080e7          	jalr	1366(ra) # 8000183e <inc_cpu>
  append(&(cpus[np->last_cpu].runnable_list), np); 
    800022f0:	16892503          	lw	a0,360(s2)
    800022f4:	03350533          	mul	a0,a0,s3
    800022f8:	08850513          	addi	a0,a0,136
    800022fc:	85ca                	mv	a1,s2
    800022fe:	9526                	add	a0,a0,s1
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	586080e7          	jalr	1414(ra) # 80001886 <append>
  release(&np->lock);
    80002308:	854a                	mv	a0,s2
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	98e080e7          	jalr	-1650(ra) # 80000c98 <release>
}
    80002312:	8552                	mv	a0,s4
    80002314:	70a2                	ld	ra,40(sp)
    80002316:	7402                	ld	s0,32(sp)
    80002318:	64e2                	ld	s1,24(sp)
    8000231a:	6942                	ld	s2,16(sp)
    8000231c:	69a2                	ld	s3,8(sp)
    8000231e:	6a02                	ld	s4,0(sp)
    80002320:	6145                	addi	sp,sp,48
    80002322:	8082                	ret
    np->last_cpu = min_num_procs_cpu();
    80002324:	00000097          	auipc	ra,0x0
    80002328:	e3a080e7          	jalr	-454(ra) # 8000215e <min_num_procs_cpu>
    8000232c:	16a92423          	sw	a0,360(s2)
    80002330:	b74d                	j	800022d2 <fork+0x132>
    return -1;
    80002332:	5a7d                	li	s4,-1
    80002334:	bff9                	j	80002312 <fork+0x172>

0000000080002336 <scheduler>:
{
    80002336:	715d                	addi	sp,sp,-80
    80002338:	e486                	sd	ra,72(sp)
    8000233a:	e0a2                	sd	s0,64(sp)
    8000233c:	fc26                	sd	s1,56(sp)
    8000233e:	f84a                	sd	s2,48(sp)
    80002340:	f44e                	sd	s3,40(sp)
    80002342:	f052                	sd	s4,32(sp)
    80002344:	ec56                	sd	s5,24(sp)
    80002346:	e85a                	sd	s6,16(sp)
    80002348:	e45e                	sd	s7,8(sp)
    8000234a:	e062                	sd	s8,0(sp)
    8000234c:	0880                	addi	s0,sp,80
    8000234e:	8712                	mv	a4,tp
  int id = r_tp();
    80002350:	2701                	sext.w	a4,a4
  c->proc = 0;
    80002352:	0a800793          	li	a5,168
    80002356:	02f707b3          	mul	a5,a4,a5
    8000235a:	0000f697          	auipc	a3,0xf
    8000235e:	f4668693          	addi	a3,a3,-186 # 800112a0 <pid_lock>
    80002362:	96be                	add	a3,a3,a5
    80002364:	0206b823          	sd	zero,48(a3)
        remove(&(c->runnable_list), p);
    80002368:	0000fb17          	auipc	s6,0xf
    8000236c:	f68b0b13          	addi	s6,s6,-152 # 800112d0 <cpus>
    80002370:	08878b93          	addi	s7,a5,136
    80002374:	9bda                	add	s7,s7,s6
        swtch(&c->context, &p->context);
    80002376:	07a1                	addi	a5,a5,8
    80002378:	9b3e                	add	s6,s6,a5
    while(!(c->runnable_list.head == -1)) {
    8000237a:	89b6                	mv	s3,a3
      if(p->state == RUNNABLE) {
    8000237c:	0000fa17          	auipc	s4,0xf
    80002380:	494a0a13          	addi	s4,s4,1172 # 80011810 <proc>
    80002384:	19000a93          	li	s5,400
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002388:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000238c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002390:	10079073          	csrw	sstatus,a5
    80002394:	490d                	li	s2,3
    while(!(c->runnable_list.head == -1)) {
    80002396:	0b89a783          	lw	a5,184(s3)
    8000239a:	56fd                	li	a3,-1
      if(p->state == RUNNABLE) {
    8000239c:	03578733          	mul	a4,a5,s5
    800023a0:	9752                	add	a4,a4,s4
    while(!(c->runnable_list.head == -1)) {
    800023a2:	fed783e3          	beq	a5,a3,80002388 <scheduler+0x52>
      if(p->state == RUNNABLE) {
    800023a6:	4f10                	lw	a2,24(a4)
    800023a8:	ff261de3          	bne	a2,s2,800023a2 <scheduler+0x6c>
    800023ac:	035784b3          	mul	s1,a5,s5
      p = &proc[c->runnable_list.head];
    800023b0:	01448c33          	add	s8,s1,s4
        acquire(&p->lock);
    800023b4:	8562                	mv	a0,s8
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	82e080e7          	jalr	-2002(ra) # 80000be4 <acquire>
        remove(&(c->runnable_list), p);
    800023be:	85e2                	mv	a1,s8
    800023c0:	855e                	mv	a0,s7
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	58c080e7          	jalr	1420(ra) # 8000194e <remove>
        p->state = RUNNING;
    800023ca:	4791                	li	a5,4
    800023cc:	00fc2c23          	sw	a5,24(s8)
        c->proc = p;
    800023d0:	0389b823          	sd	s8,48(s3)
        p->last_cpu = c->cpu_id;
    800023d4:	0b49a783          	lw	a5,180(s3)
    800023d8:	16fc2423          	sw	a5,360(s8)
        swtch(&c->context, &p->context);
    800023dc:	06048593          	addi	a1,s1,96
    800023e0:	95d2                	add	a1,a1,s4
    800023e2:	855a                	mv	a0,s6
    800023e4:	00000097          	auipc	ra,0x0
    800023e8:	7d2080e7          	jalr	2002(ra) # 80002bb6 <swtch>
        c->proc = 0;
    800023ec:	0209b823          	sd	zero,48(s3)
        release(&p->lock);
    800023f0:	8562                	mv	a0,s8
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	8a6080e7          	jalr	-1882(ra) # 80000c98 <release>
    800023fa:	bf71                	j	80002396 <scheduler+0x60>

00000000800023fc <sched>:
{
    800023fc:	7179                	addi	sp,sp,-48
    800023fe:	f406                	sd	ra,40(sp)
    80002400:	f022                	sd	s0,32(sp)
    80002402:	ec26                	sd	s1,24(sp)
    80002404:	e84a                	sd	s2,16(sp)
    80002406:	e44e                	sd	s3,8(sp)
    80002408:	e052                	sd	s4,0(sp)
    8000240a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000240c:	00000097          	auipc	ra,0x0
    80002410:	8c4080e7          	jalr	-1852(ra) # 80001cd0 <myproc>
    80002414:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002416:	ffffe097          	auipc	ra,0xffffe
    8000241a:	754080e7          	jalr	1876(ra) # 80000b6a <holding>
    8000241e:	c541                	beqz	a0,800024a6 <sched+0xaa>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002420:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002422:	2781                	sext.w	a5,a5
    80002424:	0a800713          	li	a4,168
    80002428:	02e787b3          	mul	a5,a5,a4
    8000242c:	0000f717          	auipc	a4,0xf
    80002430:	e7470713          	addi	a4,a4,-396 # 800112a0 <pid_lock>
    80002434:	97ba                	add	a5,a5,a4
    80002436:	0a87a703          	lw	a4,168(a5)
    8000243a:	4785                	li	a5,1
    8000243c:	06f71d63          	bne	a4,a5,800024b6 <sched+0xba>
  if(p->state == RUNNING)
    80002440:	4c98                	lw	a4,24(s1)
    80002442:	4791                	li	a5,4
    80002444:	08f70163          	beq	a4,a5,800024c6 <sched+0xca>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002448:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000244c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000244e:	e7c1                	bnez	a5,800024d6 <sched+0xda>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002450:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002452:	0000f917          	auipc	s2,0xf
    80002456:	e4e90913          	addi	s2,s2,-434 # 800112a0 <pid_lock>
    8000245a:	2781                	sext.w	a5,a5
    8000245c:	0a800993          	li	s3,168
    80002460:	033787b3          	mul	a5,a5,s3
    80002464:	97ca                	add	a5,a5,s2
    80002466:	0ac7aa03          	lw	s4,172(a5)
    8000246a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000246c:	2781                	sext.w	a5,a5
    8000246e:	033787b3          	mul	a5,a5,s3
    80002472:	0000f597          	auipc	a1,0xf
    80002476:	e6658593          	addi	a1,a1,-410 # 800112d8 <cpus+0x8>
    8000247a:	95be                	add	a1,a1,a5
    8000247c:	06048513          	addi	a0,s1,96
    80002480:	00000097          	auipc	ra,0x0
    80002484:	736080e7          	jalr	1846(ra) # 80002bb6 <swtch>
    80002488:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000248a:	2781                	sext.w	a5,a5
    8000248c:	033787b3          	mul	a5,a5,s3
    80002490:	97ca                	add	a5,a5,s2
    80002492:	0b47a623          	sw	s4,172(a5)
}
    80002496:	70a2                	ld	ra,40(sp)
    80002498:	7402                	ld	s0,32(sp)
    8000249a:	64e2                	ld	s1,24(sp)
    8000249c:	6942                	ld	s2,16(sp)
    8000249e:	69a2                	ld	s3,8(sp)
    800024a0:	6a02                	ld	s4,0(sp)
    800024a2:	6145                	addi	sp,sp,48
    800024a4:	8082                	ret
    panic("sched p->lock");
    800024a6:	00006517          	auipc	a0,0x6
    800024aa:	dfa50513          	addi	a0,a0,-518 # 800082a0 <digits+0x260>
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	090080e7          	jalr	144(ra) # 8000053e <panic>
    panic("sched locks");
    800024b6:	00006517          	auipc	a0,0x6
    800024ba:	dfa50513          	addi	a0,a0,-518 # 800082b0 <digits+0x270>
    800024be:	ffffe097          	auipc	ra,0xffffe
    800024c2:	080080e7          	jalr	128(ra) # 8000053e <panic>
    panic("sched running");
    800024c6:	00006517          	auipc	a0,0x6
    800024ca:	dfa50513          	addi	a0,a0,-518 # 800082c0 <digits+0x280>
    800024ce:	ffffe097          	auipc	ra,0xffffe
    800024d2:	070080e7          	jalr	112(ra) # 8000053e <panic>
    panic("sched interruptible");
    800024d6:	00006517          	auipc	a0,0x6
    800024da:	dfa50513          	addi	a0,a0,-518 # 800082d0 <digits+0x290>
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	060080e7          	jalr	96(ra) # 8000053e <panic>

00000000800024e6 <yield>:
{
    800024e6:	1101                	addi	sp,sp,-32
    800024e8:	ec06                	sd	ra,24(sp)
    800024ea:	e822                	sd	s0,16(sp)
    800024ec:	e426                	sd	s1,8(sp)
    800024ee:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800024f0:	fffff097          	auipc	ra,0xfffff
    800024f4:	7e0080e7          	jalr	2016(ra) # 80001cd0 <myproc>
    800024f8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	6ea080e7          	jalr	1770(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002502:	478d                	li	a5,3
    80002504:	cc9c                	sw	a5,24(s1)
    80002506:	8792                	mv	a5,tp
  append(&(mycpu()->runnable_list), p);
    80002508:	2781                	sext.w	a5,a5
    8000250a:	0a800513          	li	a0,168
    8000250e:	02a787b3          	mul	a5,a5,a0
    80002512:	85a6                	mv	a1,s1
    80002514:	0000f517          	auipc	a0,0xf
    80002518:	e4450513          	addi	a0,a0,-444 # 80011358 <cpus+0x88>
    8000251c:	953e                	add	a0,a0,a5
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	368080e7          	jalr	872(ra) # 80001886 <append>
  sched();
    80002526:	00000097          	auipc	ra,0x0
    8000252a:	ed6080e7          	jalr	-298(ra) # 800023fc <sched>
  release(&p->lock);
    8000252e:	8526                	mv	a0,s1
    80002530:	ffffe097          	auipc	ra,0xffffe
    80002534:	768080e7          	jalr	1896(ra) # 80000c98 <release>
}
    80002538:	60e2                	ld	ra,24(sp)
    8000253a:	6442                	ld	s0,16(sp)
    8000253c:	64a2                	ld	s1,8(sp)
    8000253e:	6105                	addi	sp,sp,32
    80002540:	8082                	ret

0000000080002542 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002542:	7179                	addi	sp,sp,-48
    80002544:	f406                	sd	ra,40(sp)
    80002546:	f022                	sd	s0,32(sp)
    80002548:	ec26                	sd	s1,24(sp)
    8000254a:	e84a                	sd	s2,16(sp)
    8000254c:	e44e                	sd	s3,8(sp)
    8000254e:	1800                	addi	s0,sp,48
    80002550:	89aa                	mv	s3,a0
    80002552:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002554:	fffff097          	auipc	ra,0xfffff
    80002558:	77c080e7          	jalr	1916(ra) # 80001cd0 <myproc>
    8000255c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	686080e7          	jalr	1670(ra) # 80000be4 <acquire>
  release(lk);
    80002566:	854a                	mv	a0,s2
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	730080e7          	jalr	1840(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002570:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002574:	4789                	li	a5,2
    80002576:	cc9c                	sw	a5,24(s1)

  struct linked_list *add_to_SLEEPING_list = &sleeping_list;
  append(add_to_SLEEPING_list, p);
    80002578:	85a6                	mv	a1,s1
    8000257a:	00006517          	auipc	a0,0x6
    8000257e:	34650513          	addi	a0,a0,838 # 800088c0 <sleeping_list>
    80002582:	fffff097          	auipc	ra,0xfffff
    80002586:	304080e7          	jalr	772(ra) # 80001886 <append>

  sched();
    8000258a:	00000097          	auipc	ra,0x0
    8000258e:	e72080e7          	jalr	-398(ra) # 800023fc <sched>

  // Tidy up.
  p->chan = 0;
    80002592:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002596:	8526                	mv	a0,s1
    80002598:	ffffe097          	auipc	ra,0xffffe
    8000259c:	700080e7          	jalr	1792(ra) # 80000c98 <release>
  acquire(lk);
    800025a0:	854a                	mv	a0,s2
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	642080e7          	jalr	1602(ra) # 80000be4 <acquire>
}
    800025aa:	70a2                	ld	ra,40(sp)
    800025ac:	7402                	ld	s0,32(sp)
    800025ae:	64e2                	ld	s1,24(sp)
    800025b0:	6942                	ld	s2,16(sp)
    800025b2:	69a2                	ld	s3,8(sp)
    800025b4:	6145                	addi	sp,sp,48
    800025b6:	8082                	ret

00000000800025b8 <wait>:
{
    800025b8:	715d                	addi	sp,sp,-80
    800025ba:	e486                	sd	ra,72(sp)
    800025bc:	e0a2                	sd	s0,64(sp)
    800025be:	fc26                	sd	s1,56(sp)
    800025c0:	f84a                	sd	s2,48(sp)
    800025c2:	f44e                	sd	s3,40(sp)
    800025c4:	f052                	sd	s4,32(sp)
    800025c6:	ec56                	sd	s5,24(sp)
    800025c8:	e85a                	sd	s6,16(sp)
    800025ca:	e45e                	sd	s7,8(sp)
    800025cc:	e062                	sd	s8,0(sp)
    800025ce:	0880                	addi	s0,sp,80
    800025d0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025d2:	fffff097          	auipc	ra,0xfffff
    800025d6:	6fe080e7          	jalr	1790(ra) # 80001cd0 <myproc>
    800025da:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800025dc:	0000f517          	auipc	a0,0xf
    800025e0:	cdc50513          	addi	a0,a0,-804 # 800112b8 <wait_lock>
    800025e4:	ffffe097          	auipc	ra,0xffffe
    800025e8:	600080e7          	jalr	1536(ra) # 80000be4 <acquire>
    havekids = 0;
    800025ec:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800025ee:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800025f0:	00015997          	auipc	s3,0x15
    800025f4:	62098993          	addi	s3,s3,1568 # 80017c10 <tickslock>
        havekids = 1;
    800025f8:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025fa:	0000fc17          	auipc	s8,0xf
    800025fe:	cbec0c13          	addi	s8,s8,-834 # 800112b8 <wait_lock>
    havekids = 0;
    80002602:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002604:	0000f497          	auipc	s1,0xf
    80002608:	20c48493          	addi	s1,s1,524 # 80011810 <proc>
    8000260c:	a0bd                	j	8000267a <wait+0xc2>
          pid = np->pid;
    8000260e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002612:	000b0e63          	beqz	s6,8000262e <wait+0x76>
    80002616:	4691                	li	a3,4
    80002618:	02c48613          	addi	a2,s1,44
    8000261c:	85da                	mv	a1,s6
    8000261e:	05093503          	ld	a0,80(s2)
    80002622:	fffff097          	auipc	ra,0xfffff
    80002626:	050080e7          	jalr	80(ra) # 80001672 <copyout>
    8000262a:	02054563          	bltz	a0,80002654 <wait+0x9c>
          freeproc(np);
    8000262e:	8526                	mv	a0,s1
    80002630:	00000097          	auipc	ra,0x0
    80002634:	84c080e7          	jalr	-1972(ra) # 80001e7c <freeproc>
          release(&np->lock);
    80002638:	8526                	mv	a0,s1
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	65e080e7          	jalr	1630(ra) # 80000c98 <release>
          release(&wait_lock);
    80002642:	0000f517          	auipc	a0,0xf
    80002646:	c7650513          	addi	a0,a0,-906 # 800112b8 <wait_lock>
    8000264a:	ffffe097          	auipc	ra,0xffffe
    8000264e:	64e080e7          	jalr	1614(ra) # 80000c98 <release>
          return pid;
    80002652:	a09d                	j	800026b8 <wait+0x100>
            release(&np->lock);
    80002654:	8526                	mv	a0,s1
    80002656:	ffffe097          	auipc	ra,0xffffe
    8000265a:	642080e7          	jalr	1602(ra) # 80000c98 <release>
            release(&wait_lock);
    8000265e:	0000f517          	auipc	a0,0xf
    80002662:	c5a50513          	addi	a0,a0,-934 # 800112b8 <wait_lock>
    80002666:	ffffe097          	auipc	ra,0xffffe
    8000266a:	632080e7          	jalr	1586(ra) # 80000c98 <release>
            return -1;
    8000266e:	59fd                	li	s3,-1
    80002670:	a0a1                	j	800026b8 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002672:	19048493          	addi	s1,s1,400
    80002676:	03348463          	beq	s1,s3,8000269e <wait+0xe6>
      if(np->parent == p){
    8000267a:	7c9c                	ld	a5,56(s1)
    8000267c:	ff279be3          	bne	a5,s2,80002672 <wait+0xba>
        acquire(&np->lock);
    80002680:	8526                	mv	a0,s1
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	562080e7          	jalr	1378(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000268a:	4c9c                	lw	a5,24(s1)
    8000268c:	f94781e3          	beq	a5,s4,8000260e <wait+0x56>
        release(&np->lock);
    80002690:	8526                	mv	a0,s1
    80002692:	ffffe097          	auipc	ra,0xffffe
    80002696:	606080e7          	jalr	1542(ra) # 80000c98 <release>
        havekids = 1;
    8000269a:	8756                	mv	a4,s5
    8000269c:	bfd9                	j	80002672 <wait+0xba>
    if(!havekids || p->killed){
    8000269e:	c701                	beqz	a4,800026a6 <wait+0xee>
    800026a0:	02892783          	lw	a5,40(s2)
    800026a4:	c79d                	beqz	a5,800026d2 <wait+0x11a>
      release(&wait_lock);
    800026a6:	0000f517          	auipc	a0,0xf
    800026aa:	c1250513          	addi	a0,a0,-1006 # 800112b8 <wait_lock>
    800026ae:	ffffe097          	auipc	ra,0xffffe
    800026b2:	5ea080e7          	jalr	1514(ra) # 80000c98 <release>
      return -1;
    800026b6:	59fd                	li	s3,-1
}
    800026b8:	854e                	mv	a0,s3
    800026ba:	60a6                	ld	ra,72(sp)
    800026bc:	6406                	ld	s0,64(sp)
    800026be:	74e2                	ld	s1,56(sp)
    800026c0:	7942                	ld	s2,48(sp)
    800026c2:	79a2                	ld	s3,40(sp)
    800026c4:	7a02                	ld	s4,32(sp)
    800026c6:	6ae2                	ld	s5,24(sp)
    800026c8:	6b42                	ld	s6,16(sp)
    800026ca:	6ba2                	ld	s7,8(sp)
    800026cc:	6c02                	ld	s8,0(sp)
    800026ce:	6161                	addi	sp,sp,80
    800026d0:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800026d2:	85e2                	mv	a1,s8
    800026d4:	854a                	mv	a0,s2
    800026d6:	00000097          	auipc	ra,0x0
    800026da:	e6c080e7          	jalr	-404(ra) # 80002542 <sleep>
    havekids = 0;
    800026de:	b715                	j	80002602 <wait+0x4a>

00000000800026e0 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800026e0:	7119                	addi	sp,sp,-128
    800026e2:	fc86                	sd	ra,120(sp)
    800026e4:	f8a2                	sd	s0,112(sp)
    800026e6:	f4a6                	sd	s1,104(sp)
    800026e8:	f0ca                	sd	s2,96(sp)
    800026ea:	ecce                	sd	s3,88(sp)
    800026ec:	e8d2                	sd	s4,80(sp)
    800026ee:	e4d6                	sd	s5,72(sp)
    800026f0:	e0da                	sd	s6,64(sp)
    800026f2:	fc5e                	sd	s7,56(sp)
    800026f4:	f862                	sd	s8,48(sp)
    800026f6:	f466                	sd	s9,40(sp)
    800026f8:	f06a                	sd	s10,32(sp)
    800026fa:	ec6e                	sd	s11,24(sp)
    800026fc:	0100                	addi	s0,sp,128
  struct proc *p;
  int empty = -1;
  int curr = sleeping_list.head;
    800026fe:	00006497          	auipc	s1,0x6
    80002702:	1c24a483          	lw	s1,450(s1) # 800088c0 <sleeping_list>

  while(curr != empty) {
    80002706:	57fd                	li	a5,-1
    80002708:	0cf48f63          	beq	s1,a5,800027e6 <wakeup+0x106>
    8000270c:	8b2a                	mv	s6,a0
    p = &proc[curr];
    8000270e:	19000a13          	li	s4,400
    80002712:	0000f997          	auipc	s3,0xf
    80002716:	0fe98993          	addi	s3,s3,254 # 80011810 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000271a:	4a89                	li	s5,2
        struct linked_list *remove_from_SLEEPING_list = &sleeping_list;
        remove(remove_from_SLEEPING_list, p);
    8000271c:	00006d97          	auipc	s11,0x6
    80002720:	1a4d8d93          	addi	s11,s11,420 # 800088c0 <sleeping_list>
        p->state = RUNNABLE;
    80002724:	4d0d                	li	s10,3

        if (flag == 1)
    80002726:	00007c97          	auipc	s9,0x7
    8000272a:	902c8c93          	addi	s9,s9,-1790 # 80009028 <flag>
    8000272e:	4c05                	li	s8,1
          p->last_cpu = min_num_procs_cpu();

        inc_cpu(&cpus[p->last_cpu]);
    80002730:	0000fb97          	auipc	s7,0xf
    80002734:	ba0b8b93          	addi	s7,s7,-1120 # 800112d0 <cpus>
    80002738:	a8b1                	j	80002794 <wakeup+0xb4>
    8000273a:	034487b3          	mul	a5,s1,s4
    8000273e:	97ce                	add	a5,a5,s3
    80002740:	f8f43423          	sd	a5,-120(s0)
    80002744:	1687a503          	lw	a0,360(a5)
    80002748:	0a800713          	li	a4,168
    8000274c:	02e50533          	mul	a0,a0,a4
    80002750:	955e                	add	a0,a0,s7
    80002752:	fffff097          	auipc	ra,0xfffff
    80002756:	0ec080e7          	jalr	236(ra) # 8000183e <inc_cpu>
        append(&cpus[p->last_cpu].runnable_list, p);
    8000275a:	f8843783          	ld	a5,-120(s0)
    8000275e:	1687a503          	lw	a0,360(a5)
    80002762:	0a800713          	li	a4,168
    80002766:	02e50533          	mul	a0,a0,a4
    8000276a:	08850513          	addi	a0,a0,136
    8000276e:	85ca                	mv	a1,s2
    80002770:	955e                	add	a0,a0,s7
    80002772:	fffff097          	auipc	ra,0xfffff
    80002776:	114080e7          	jalr	276(ra) # 80001886 <append>
      }
      release(&p->lock);
    8000277a:	854a                	mv	a0,s2
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	51c080e7          	jalr	1308(ra) # 80000c98 <release>
    }
  curr = p->next_proc;
    80002784:	034484b3          	mul	s1,s1,s4
    80002788:	94ce                	add	s1,s1,s3
    8000278a:	16c4a483          	lw	s1,364(s1)
  while(curr != empty) {
    8000278e:	57fd                	li	a5,-1
    80002790:	04f48b63          	beq	s1,a5,800027e6 <wakeup+0x106>
    p = &proc[curr];
    80002794:	03448933          	mul	s2,s1,s4
    80002798:	994e                	add	s2,s2,s3
    if(p != myproc()){
    8000279a:	fffff097          	auipc	ra,0xfffff
    8000279e:	536080e7          	jalr	1334(ra) # 80001cd0 <myproc>
    800027a2:	fea901e3          	beq	s2,a0,80002784 <wakeup+0xa4>
      acquire(&p->lock);
    800027a6:	854a                	mv	a0,s2
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	43c080e7          	jalr	1084(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800027b0:	01892783          	lw	a5,24(s2)
    800027b4:	fd5793e3          	bne	a5,s5,8000277a <wakeup+0x9a>
    800027b8:	02093783          	ld	a5,32(s2)
    800027bc:	fb679fe3          	bne	a5,s6,8000277a <wakeup+0x9a>
        remove(remove_from_SLEEPING_list, p);
    800027c0:	85ca                	mv	a1,s2
    800027c2:	856e                	mv	a0,s11
    800027c4:	fffff097          	auipc	ra,0xfffff
    800027c8:	18a080e7          	jalr	394(ra) # 8000194e <remove>
        p->state = RUNNABLE;
    800027cc:	01a92c23          	sw	s10,24(s2)
        if (flag == 1)
    800027d0:	000ca783          	lw	a5,0(s9)
    800027d4:	f78793e3          	bne	a5,s8,8000273a <wakeup+0x5a>
          p->last_cpu = min_num_procs_cpu();
    800027d8:	00000097          	auipc	ra,0x0
    800027dc:	986080e7          	jalr	-1658(ra) # 8000215e <min_num_procs_cpu>
    800027e0:	16a92423          	sw	a0,360(s2)
    800027e4:	bf99                	j	8000273a <wakeup+0x5a>
  }
}
    800027e6:	70e6                	ld	ra,120(sp)
    800027e8:	7446                	ld	s0,112(sp)
    800027ea:	74a6                	ld	s1,104(sp)
    800027ec:	7906                	ld	s2,96(sp)
    800027ee:	69e6                	ld	s3,88(sp)
    800027f0:	6a46                	ld	s4,80(sp)
    800027f2:	6aa6                	ld	s5,72(sp)
    800027f4:	6b06                	ld	s6,64(sp)
    800027f6:	7be2                	ld	s7,56(sp)
    800027f8:	7c42                	ld	s8,48(sp)
    800027fa:	7ca2                	ld	s9,40(sp)
    800027fc:	7d02                	ld	s10,32(sp)
    800027fe:	6de2                	ld	s11,24(sp)
    80002800:	6109                	addi	sp,sp,128
    80002802:	8082                	ret

0000000080002804 <reparent>:
{
    80002804:	7179                	addi	sp,sp,-48
    80002806:	f406                	sd	ra,40(sp)
    80002808:	f022                	sd	s0,32(sp)
    8000280a:	ec26                	sd	s1,24(sp)
    8000280c:	e84a                	sd	s2,16(sp)
    8000280e:	e44e                	sd	s3,8(sp)
    80002810:	e052                	sd	s4,0(sp)
    80002812:	1800                	addi	s0,sp,48
    80002814:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002816:	0000f497          	auipc	s1,0xf
    8000281a:	ffa48493          	addi	s1,s1,-6 # 80011810 <proc>
      pp->parent = initproc;
    8000281e:	00007a17          	auipc	s4,0x7
    80002822:	812a0a13          	addi	s4,s4,-2030 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002826:	00015997          	auipc	s3,0x15
    8000282a:	3ea98993          	addi	s3,s3,1002 # 80017c10 <tickslock>
    8000282e:	a029                	j	80002838 <reparent+0x34>
    80002830:	19048493          	addi	s1,s1,400
    80002834:	01348d63          	beq	s1,s3,8000284e <reparent+0x4a>
    if(pp->parent == p){
    80002838:	7c9c                	ld	a5,56(s1)
    8000283a:	ff279be3          	bne	a5,s2,80002830 <reparent+0x2c>
      pp->parent = initproc;
    8000283e:	000a3503          	ld	a0,0(s4)
    80002842:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002844:	00000097          	auipc	ra,0x0
    80002848:	e9c080e7          	jalr	-356(ra) # 800026e0 <wakeup>
    8000284c:	b7d5                	j	80002830 <reparent+0x2c>
}
    8000284e:	70a2                	ld	ra,40(sp)
    80002850:	7402                	ld	s0,32(sp)
    80002852:	64e2                	ld	s1,24(sp)
    80002854:	6942                	ld	s2,16(sp)
    80002856:	69a2                	ld	s3,8(sp)
    80002858:	6a02                	ld	s4,0(sp)
    8000285a:	6145                	addi	sp,sp,48
    8000285c:	8082                	ret

000000008000285e <exit>:
{
    8000285e:	7179                	addi	sp,sp,-48
    80002860:	f406                	sd	ra,40(sp)
    80002862:	f022                	sd	s0,32(sp)
    80002864:	ec26                	sd	s1,24(sp)
    80002866:	e84a                	sd	s2,16(sp)
    80002868:	e44e                	sd	s3,8(sp)
    8000286a:	e052                	sd	s4,0(sp)
    8000286c:	1800                	addi	s0,sp,48
    8000286e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002870:	fffff097          	auipc	ra,0xfffff
    80002874:	460080e7          	jalr	1120(ra) # 80001cd0 <myproc>
    80002878:	89aa                	mv	s3,a0
  if(p == initproc)
    8000287a:	00006797          	auipc	a5,0x6
    8000287e:	7b67b783          	ld	a5,1974(a5) # 80009030 <initproc>
    80002882:	0d050493          	addi	s1,a0,208
    80002886:	15050913          	addi	s2,a0,336
    8000288a:	02a79363          	bne	a5,a0,800028b0 <exit+0x52>
    panic("init exiting");
    8000288e:	00006517          	auipc	a0,0x6
    80002892:	a5a50513          	addi	a0,a0,-1446 # 800082e8 <digits+0x2a8>
    80002896:	ffffe097          	auipc	ra,0xffffe
    8000289a:	ca8080e7          	jalr	-856(ra) # 8000053e <panic>
      fileclose(f);
    8000289e:	00002097          	auipc	ra,0x2
    800028a2:	264080e7          	jalr	612(ra) # 80004b02 <fileclose>
      p->ofile[fd] = 0;
    800028a6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800028aa:	04a1                	addi	s1,s1,8
    800028ac:	01248563          	beq	s1,s2,800028b6 <exit+0x58>
    if(p->ofile[fd]){
    800028b0:	6088                	ld	a0,0(s1)
    800028b2:	f575                	bnez	a0,8000289e <exit+0x40>
    800028b4:	bfdd                	j	800028aa <exit+0x4c>
  begin_op();
    800028b6:	00002097          	auipc	ra,0x2
    800028ba:	d80080e7          	jalr	-640(ra) # 80004636 <begin_op>
  iput(p->cwd);
    800028be:	1509b503          	ld	a0,336(s3)
    800028c2:	00001097          	auipc	ra,0x1
    800028c6:	55c080e7          	jalr	1372(ra) # 80003e1e <iput>
  end_op();
    800028ca:	00002097          	auipc	ra,0x2
    800028ce:	dec080e7          	jalr	-532(ra) # 800046b6 <end_op>
  p->cwd = 0;
    800028d2:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800028d6:	0000f497          	auipc	s1,0xf
    800028da:	9e248493          	addi	s1,s1,-1566 # 800112b8 <wait_lock>
    800028de:	8526                	mv	a0,s1
    800028e0:	ffffe097          	auipc	ra,0xffffe
    800028e4:	304080e7          	jalr	772(ra) # 80000be4 <acquire>
  reparent(p);
    800028e8:	854e                	mv	a0,s3
    800028ea:	00000097          	auipc	ra,0x0
    800028ee:	f1a080e7          	jalr	-230(ra) # 80002804 <reparent>
  wakeup(p->parent);
    800028f2:	0389b503          	ld	a0,56(s3)
    800028f6:	00000097          	auipc	ra,0x0
    800028fa:	dea080e7          	jalr	-534(ra) # 800026e0 <wakeup>
  acquire(&p->lock);
    800028fe:	854e                	mv	a0,s3
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	2e4080e7          	jalr	740(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002908:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000290c:	4795                	li	a5,5
    8000290e:	00f9ac23          	sw	a5,24(s3)
  append(&zombie_list, p); 
    80002912:	85ce                	mv	a1,s3
    80002914:	00006517          	auipc	a0,0x6
    80002918:	fcc50513          	addi	a0,a0,-52 # 800088e0 <zombie_list>
    8000291c:	fffff097          	auipc	ra,0xfffff
    80002920:	f6a080e7          	jalr	-150(ra) # 80001886 <append>
  release(&wait_lock);
    80002924:	8526                	mv	a0,s1
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	372080e7          	jalr	882(ra) # 80000c98 <release>
  sched();
    8000292e:	00000097          	auipc	ra,0x0
    80002932:	ace080e7          	jalr	-1330(ra) # 800023fc <sched>
  panic("zombie exit");
    80002936:	00006517          	auipc	a0,0x6
    8000293a:	9c250513          	addi	a0,a0,-1598 # 800082f8 <digits+0x2b8>
    8000293e:	ffffe097          	auipc	ra,0xffffe
    80002942:	c00080e7          	jalr	-1024(ra) # 8000053e <panic>

0000000080002946 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002946:	7179                	addi	sp,sp,-48
    80002948:	f406                	sd	ra,40(sp)
    8000294a:	f022                	sd	s0,32(sp)
    8000294c:	ec26                	sd	s1,24(sp)
    8000294e:	e84a                	sd	s2,16(sp)
    80002950:	e44e                	sd	s3,8(sp)
    80002952:	1800                	addi	s0,sp,48
    80002954:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002956:	0000f497          	auipc	s1,0xf
    8000295a:	eba48493          	addi	s1,s1,-326 # 80011810 <proc>
    8000295e:	00015997          	auipc	s3,0x15
    80002962:	2b298993          	addi	s3,s3,690 # 80017c10 <tickslock>
    acquire(&p->lock);
    80002966:	8526                	mv	a0,s1
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	27c080e7          	jalr	636(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002970:	589c                	lw	a5,48(s1)
    80002972:	01278d63          	beq	a5,s2,8000298c <kill+0x46>
        append(&cpus[p->last_cpu].runnable_list, p);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002976:	8526                	mv	a0,s1
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	320080e7          	jalr	800(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002980:	19048493          	addi	s1,s1,400
    80002984:	ff3491e3          	bne	s1,s3,80002966 <kill+0x20>
  }
  return -1;
    80002988:	557d                	li	a0,-1
    8000298a:	a829                	j	800029a4 <kill+0x5e>
      p->killed = 1;
    8000298c:	4785                	li	a5,1
    8000298e:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002990:	4c98                	lw	a4,24(s1)
    80002992:	4789                	li	a5,2
    80002994:	00f70f63          	beq	a4,a5,800029b2 <kill+0x6c>
      release(&p->lock);
    80002998:	8526                	mv	a0,s1
    8000299a:	ffffe097          	auipc	ra,0xffffe
    8000299e:	2fe080e7          	jalr	766(ra) # 80000c98 <release>
      return 0;
    800029a2:	4501                	li	a0,0
}
    800029a4:	70a2                	ld	ra,40(sp)
    800029a6:	7402                	ld	s0,32(sp)
    800029a8:	64e2                	ld	s1,24(sp)
    800029aa:	6942                	ld	s2,16(sp)
    800029ac:	69a2                	ld	s3,8(sp)
    800029ae:	6145                	addi	sp,sp,48
    800029b0:	8082                	ret
        remove(&sleeping_list, p);
    800029b2:	85a6                	mv	a1,s1
    800029b4:	00006517          	auipc	a0,0x6
    800029b8:	f0c50513          	addi	a0,a0,-244 # 800088c0 <sleeping_list>
    800029bc:	fffff097          	auipc	ra,0xfffff
    800029c0:	f92080e7          	jalr	-110(ra) # 8000194e <remove>
        p->state = RUNNABLE;
    800029c4:	478d                	li	a5,3
    800029c6:	cc9c                	sw	a5,24(s1)
        append(&cpus[p->last_cpu].runnable_list, p);
    800029c8:	1684a783          	lw	a5,360(s1)
    800029cc:	0a800713          	li	a4,168
    800029d0:	02e787b3          	mul	a5,a5,a4
    800029d4:	85a6                	mv	a1,s1
    800029d6:	0000f517          	auipc	a0,0xf
    800029da:	98250513          	addi	a0,a0,-1662 # 80011358 <cpus+0x88>
    800029de:	953e                	add	a0,a0,a5
    800029e0:	fffff097          	auipc	ra,0xfffff
    800029e4:	ea6080e7          	jalr	-346(ra) # 80001886 <append>
    800029e8:	bf45                	j	80002998 <kill+0x52>

00000000800029ea <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029ea:	7179                	addi	sp,sp,-48
    800029ec:	f406                	sd	ra,40(sp)
    800029ee:	f022                	sd	s0,32(sp)
    800029f0:	ec26                	sd	s1,24(sp)
    800029f2:	e84a                	sd	s2,16(sp)
    800029f4:	e44e                	sd	s3,8(sp)
    800029f6:	e052                	sd	s4,0(sp)
    800029f8:	1800                	addi	s0,sp,48
    800029fa:	84aa                	mv	s1,a0
    800029fc:	892e                	mv	s2,a1
    800029fe:	89b2                	mv	s3,a2
    80002a00:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a02:	fffff097          	auipc	ra,0xfffff
    80002a06:	2ce080e7          	jalr	718(ra) # 80001cd0 <myproc>
  if(user_dst){
    80002a0a:	c08d                	beqz	s1,80002a2c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002a0c:	86d2                	mv	a3,s4
    80002a0e:	864e                	mv	a2,s3
    80002a10:	85ca                	mv	a1,s2
    80002a12:	6928                	ld	a0,80(a0)
    80002a14:	fffff097          	auipc	ra,0xfffff
    80002a18:	c5e080e7          	jalr	-930(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002a1c:	70a2                	ld	ra,40(sp)
    80002a1e:	7402                	ld	s0,32(sp)
    80002a20:	64e2                	ld	s1,24(sp)
    80002a22:	6942                	ld	s2,16(sp)
    80002a24:	69a2                	ld	s3,8(sp)
    80002a26:	6a02                	ld	s4,0(sp)
    80002a28:	6145                	addi	sp,sp,48
    80002a2a:	8082                	ret
    memmove((char *)dst, src, len);
    80002a2c:	000a061b          	sext.w	a2,s4
    80002a30:	85ce                	mv	a1,s3
    80002a32:	854a                	mv	a0,s2
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	30c080e7          	jalr	780(ra) # 80000d40 <memmove>
    return 0;
    80002a3c:	8526                	mv	a0,s1
    80002a3e:	bff9                	j	80002a1c <either_copyout+0x32>

0000000080002a40 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a40:	7179                	addi	sp,sp,-48
    80002a42:	f406                	sd	ra,40(sp)
    80002a44:	f022                	sd	s0,32(sp)
    80002a46:	ec26                	sd	s1,24(sp)
    80002a48:	e84a                	sd	s2,16(sp)
    80002a4a:	e44e                	sd	s3,8(sp)
    80002a4c:	e052                	sd	s4,0(sp)
    80002a4e:	1800                	addi	s0,sp,48
    80002a50:	892a                	mv	s2,a0
    80002a52:	84ae                	mv	s1,a1
    80002a54:	89b2                	mv	s3,a2
    80002a56:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a58:	fffff097          	auipc	ra,0xfffff
    80002a5c:	278080e7          	jalr	632(ra) # 80001cd0 <myproc>
  if(user_src){
    80002a60:	c08d                	beqz	s1,80002a82 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002a62:	86d2                	mv	a3,s4
    80002a64:	864e                	mv	a2,s3
    80002a66:	85ca                	mv	a1,s2
    80002a68:	6928                	ld	a0,80(a0)
    80002a6a:	fffff097          	auipc	ra,0xfffff
    80002a6e:	c94080e7          	jalr	-876(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002a72:	70a2                	ld	ra,40(sp)
    80002a74:	7402                	ld	s0,32(sp)
    80002a76:	64e2                	ld	s1,24(sp)
    80002a78:	6942                	ld	s2,16(sp)
    80002a7a:	69a2                	ld	s3,8(sp)
    80002a7c:	6a02                	ld	s4,0(sp)
    80002a7e:	6145                	addi	sp,sp,48
    80002a80:	8082                	ret
    memmove(dst, (char*)src, len);
    80002a82:	000a061b          	sext.w	a2,s4
    80002a86:	85ce                	mv	a1,s3
    80002a88:	854a                	mv	a0,s2
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	2b6080e7          	jalr	694(ra) # 80000d40 <memmove>
    return 0;
    80002a92:	8526                	mv	a0,s1
    80002a94:	bff9                	j	80002a72 <either_copyin+0x32>

0000000080002a96 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    80002a96:	715d                	addi	sp,sp,-80
    80002a98:	e486                	sd	ra,72(sp)
    80002a9a:	e0a2                	sd	s0,64(sp)
    80002a9c:	fc26                	sd	s1,56(sp)
    80002a9e:	f84a                	sd	s2,48(sp)
    80002aa0:	f44e                	sd	s3,40(sp)
    80002aa2:	f052                	sd	s4,32(sp)
    80002aa4:	ec56                	sd	s5,24(sp)
    80002aa6:	e85a                	sd	s6,16(sp)
    80002aa8:	e45e                	sd	s7,8(sp)
    80002aaa:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002aac:	00005517          	auipc	a0,0x5
    80002ab0:	61c50513          	addi	a0,a0,1564 # 800080c8 <digits+0x88>
    80002ab4:	ffffe097          	auipc	ra,0xffffe
    80002ab8:	ad4080e7          	jalr	-1324(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002abc:	0000f497          	auipc	s1,0xf
    80002ac0:	eac48493          	addi	s1,s1,-340 # 80011968 <proc+0x158>
    80002ac4:	00015917          	auipc	s2,0x15
    80002ac8:	2a490913          	addi	s2,s2,676 # 80017d68 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002acc:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    80002ace:	00006997          	auipc	s3,0x6
    80002ad2:	83a98993          	addi	s3,s3,-1990 # 80008308 <digits+0x2c8>
    printf("%d %s %s", p->pid, state, p->name);
    80002ad6:	00006a97          	auipc	s5,0x6
    80002ada:	83aa8a93          	addi	s5,s5,-1990 # 80008310 <digits+0x2d0>
    printf("\n");
    80002ade:	00005a17          	auipc	s4,0x5
    80002ae2:	5eaa0a13          	addi	s4,s4,1514 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ae6:	00006b97          	auipc	s7,0x6
    80002aea:	862b8b93          	addi	s7,s7,-1950 # 80008348 <states.1791>
    80002aee:	a00d                	j	80002b10 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002af0:	ed86a583          	lw	a1,-296(a3)
    80002af4:	8556                	mv	a0,s5
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	a92080e7          	jalr	-1390(ra) # 80000588 <printf>
    printf("\n");
    80002afe:	8552                	mv	a0,s4
    80002b00:	ffffe097          	auipc	ra,0xffffe
    80002b04:	a88080e7          	jalr	-1400(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b08:	19048493          	addi	s1,s1,400
    80002b0c:	03248163          	beq	s1,s2,80002b2e <procdump+0x98>
    if(p->state == UNUSED)
    80002b10:	86a6                	mv	a3,s1
    80002b12:	ec04a783          	lw	a5,-320(s1)
    80002b16:	dbed                	beqz	a5,80002b08 <procdump+0x72>
      state = "???"; 
    80002b18:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b1a:	fcfb6be3          	bltu	s6,a5,80002af0 <procdump+0x5a>
    80002b1e:	1782                	slli	a5,a5,0x20
    80002b20:	9381                	srli	a5,a5,0x20
    80002b22:	078e                	slli	a5,a5,0x3
    80002b24:	97de                	add	a5,a5,s7
    80002b26:	6390                	ld	a2,0(a5)
    80002b28:	f661                	bnez	a2,80002af0 <procdump+0x5a>
      state = "???"; 
    80002b2a:	864e                	mv	a2,s3
    80002b2c:	b7d1                	j	80002af0 <procdump+0x5a>
  }
}
    80002b2e:	60a6                	ld	ra,72(sp)
    80002b30:	6406                	ld	s0,64(sp)
    80002b32:	74e2                	ld	s1,56(sp)
    80002b34:	7942                	ld	s2,48(sp)
    80002b36:	79a2                	ld	s3,40(sp)
    80002b38:	7a02                	ld	s4,32(sp)
    80002b3a:	6ae2                	ld	s5,24(sp)
    80002b3c:	6b42                	ld	s6,16(sp)
    80002b3e:	6ba2                	ld	s7,8(sp)
    80002b40:	6161                	addi	sp,sp,80
    80002b42:	8082                	ret

0000000080002b44 <set_cpu>:

// move process to different CPU. 
int
set_cpu(int cpu_num) {
  int fail = -1;
  if(cpu_num < NCPU) {
    80002b44:	479d                	li	a5,7
    80002b46:	04a7e863          	bltu	a5,a0,80002b96 <set_cpu+0x52>
set_cpu(int cpu_num) {
    80002b4a:	1101                	addi	sp,sp,-32
    80002b4c:	ec06                	sd	ra,24(sp)
    80002b4e:	e822                	sd	s0,16(sp)
    80002b50:	e426                	sd	s1,8(sp)
    80002b52:	1000                	addi	s0,sp,32
    80002b54:	84aa                	mv	s1,a0
   if(cpu_num >= 0) {
     struct cpu *c = &cpus[cpu_num];
     if(c != NULL) {
        acquire(&myproc()->lock);
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	17a080e7          	jalr	378(ra) # 80001cd0 <myproc>
    80002b5e:	ffffe097          	auipc	ra,0xffffe
    80002b62:	086080e7          	jalr	134(ra) # 80000be4 <acquire>
        myproc()->last_cpu = cpu_num;
    80002b66:	fffff097          	auipc	ra,0xfffff
    80002b6a:	16a080e7          	jalr	362(ra) # 80001cd0 <myproc>
    80002b6e:	16952423          	sw	s1,360(a0)
        release(&myproc()->lock);
    80002b72:	fffff097          	auipc	ra,0xfffff
    80002b76:	15e080e7          	jalr	350(ra) # 80001cd0 <myproc>
    80002b7a:	ffffe097          	auipc	ra,0xffffe
    80002b7e:	11e080e7          	jalr	286(ra) # 80000c98 <release>

        // RUNNING -> RUNNABLE
        yield();
    80002b82:	00000097          	auipc	ra,0x0
    80002b86:	964080e7          	jalr	-1692(ra) # 800024e6 <yield>
        return cpu_num;
    80002b8a:	8526                	mv	a0,s1
      }
    }
  }
  return fail;
}
    80002b8c:	60e2                	ld	ra,24(sp)
    80002b8e:	6442                	ld	s0,16(sp)
    80002b90:	64a2                	ld	s1,8(sp)
    80002b92:	6105                	addi	sp,sp,32
    80002b94:	8082                	ret
  return fail;
    80002b96:	557d                	li	a0,-1
}
    80002b98:	8082                	ret

0000000080002b9a <get_cpu>:


// returns current CPU.
int
get_cpu(void){
    80002b9a:	1141                	addi	sp,sp,-16
    80002b9c:	e406                	sd	ra,8(sp)
    80002b9e:	e022                	sd	s0,0(sp)
    80002ba0:	0800                	addi	s0,sp,16

  // If process was not chosen by any cpy the value of myproc()->last_cpu is -1.
  return myproc()->last_cpu;
    80002ba2:	fffff097          	auipc	ra,0xfffff
    80002ba6:	12e080e7          	jalr	302(ra) # 80001cd0 <myproc>
}
    80002baa:	16852503          	lw	a0,360(a0)
    80002bae:	60a2                	ld	ra,8(sp)
    80002bb0:	6402                	ld	s0,0(sp)
    80002bb2:	0141                	addi	sp,sp,16
    80002bb4:	8082                	ret

0000000080002bb6 <swtch>:
    80002bb6:	00153023          	sd	ra,0(a0)
    80002bba:	00253423          	sd	sp,8(a0)
    80002bbe:	e900                	sd	s0,16(a0)
    80002bc0:	ed04                	sd	s1,24(a0)
    80002bc2:	03253023          	sd	s2,32(a0)
    80002bc6:	03353423          	sd	s3,40(a0)
    80002bca:	03453823          	sd	s4,48(a0)
    80002bce:	03553c23          	sd	s5,56(a0)
    80002bd2:	05653023          	sd	s6,64(a0)
    80002bd6:	05753423          	sd	s7,72(a0)
    80002bda:	05853823          	sd	s8,80(a0)
    80002bde:	05953c23          	sd	s9,88(a0)
    80002be2:	07a53023          	sd	s10,96(a0)
    80002be6:	07b53423          	sd	s11,104(a0)
    80002bea:	0005b083          	ld	ra,0(a1)
    80002bee:	0085b103          	ld	sp,8(a1)
    80002bf2:	6980                	ld	s0,16(a1)
    80002bf4:	6d84                	ld	s1,24(a1)
    80002bf6:	0205b903          	ld	s2,32(a1)
    80002bfa:	0285b983          	ld	s3,40(a1)
    80002bfe:	0305ba03          	ld	s4,48(a1)
    80002c02:	0385ba83          	ld	s5,56(a1)
    80002c06:	0405bb03          	ld	s6,64(a1)
    80002c0a:	0485bb83          	ld	s7,72(a1)
    80002c0e:	0505bc03          	ld	s8,80(a1)
    80002c12:	0585bc83          	ld	s9,88(a1)
    80002c16:	0605bd03          	ld	s10,96(a1)
    80002c1a:	0685bd83          	ld	s11,104(a1)
    80002c1e:	8082                	ret

0000000080002c20 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c20:	1141                	addi	sp,sp,-16
    80002c22:	e406                	sd	ra,8(sp)
    80002c24:	e022                	sd	s0,0(sp)
    80002c26:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c28:	00005597          	auipc	a1,0x5
    80002c2c:	75058593          	addi	a1,a1,1872 # 80008378 <states.1791+0x30>
    80002c30:	00015517          	auipc	a0,0x15
    80002c34:	fe050513          	addi	a0,a0,-32 # 80017c10 <tickslock>
    80002c38:	ffffe097          	auipc	ra,0xffffe
    80002c3c:	f1c080e7          	jalr	-228(ra) # 80000b54 <initlock>
}
    80002c40:	60a2                	ld	ra,8(sp)
    80002c42:	6402                	ld	s0,0(sp)
    80002c44:	0141                	addi	sp,sp,16
    80002c46:	8082                	ret

0000000080002c48 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c48:	1141                	addi	sp,sp,-16
    80002c4a:	e422                	sd	s0,8(sp)
    80002c4c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c4e:	00003797          	auipc	a5,0x3
    80002c52:	4d278793          	addi	a5,a5,1234 # 80006120 <kernelvec>
    80002c56:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c5a:	6422                	ld	s0,8(sp)
    80002c5c:	0141                	addi	sp,sp,16
    80002c5e:	8082                	ret

0000000080002c60 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002c60:	1141                	addi	sp,sp,-16
    80002c62:	e406                	sd	ra,8(sp)
    80002c64:	e022                	sd	s0,0(sp)
    80002c66:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c68:	fffff097          	auipc	ra,0xfffff
    80002c6c:	068080e7          	jalr	104(ra) # 80001cd0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c70:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c74:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c76:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002c7a:	00004617          	auipc	a2,0x4
    80002c7e:	38660613          	addi	a2,a2,902 # 80007000 <_trampoline>
    80002c82:	00004697          	auipc	a3,0x4
    80002c86:	37e68693          	addi	a3,a3,894 # 80007000 <_trampoline>
    80002c8a:	8e91                	sub	a3,a3,a2
    80002c8c:	040007b7          	lui	a5,0x4000
    80002c90:	17fd                	addi	a5,a5,-1
    80002c92:	07b2                	slli	a5,a5,0xc
    80002c94:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c96:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c9a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c9c:	180026f3          	csrr	a3,satp
    80002ca0:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002ca2:	6d38                	ld	a4,88(a0)
    80002ca4:	6134                	ld	a3,64(a0)
    80002ca6:	6585                	lui	a1,0x1
    80002ca8:	96ae                	add	a3,a3,a1
    80002caa:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002cac:	6d38                	ld	a4,88(a0)
    80002cae:	00000697          	auipc	a3,0x0
    80002cb2:	13868693          	addi	a3,a3,312 # 80002de6 <usertrap>
    80002cb6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002cb8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002cba:	8692                	mv	a3,tp
    80002cbc:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cbe:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002cc2:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002cc6:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cca:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002cce:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cd0:	6f18                	ld	a4,24(a4)
    80002cd2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002cd6:	692c                	ld	a1,80(a0)
    80002cd8:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002cda:	00004717          	auipc	a4,0x4
    80002cde:	3b670713          	addi	a4,a4,950 # 80007090 <userret>
    80002ce2:	8f11                	sub	a4,a4,a2
    80002ce4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002ce6:	577d                	li	a4,-1
    80002ce8:	177e                	slli	a4,a4,0x3f
    80002cea:	8dd9                	or	a1,a1,a4
    80002cec:	02000537          	lui	a0,0x2000
    80002cf0:	157d                	addi	a0,a0,-1
    80002cf2:	0536                	slli	a0,a0,0xd
    80002cf4:	9782                	jalr	a5
}
    80002cf6:	60a2                	ld	ra,8(sp)
    80002cf8:	6402                	ld	s0,0(sp)
    80002cfa:	0141                	addi	sp,sp,16
    80002cfc:	8082                	ret

0000000080002cfe <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002cfe:	1101                	addi	sp,sp,-32
    80002d00:	ec06                	sd	ra,24(sp)
    80002d02:	e822                	sd	s0,16(sp)
    80002d04:	e426                	sd	s1,8(sp)
    80002d06:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d08:	00015497          	auipc	s1,0x15
    80002d0c:	f0848493          	addi	s1,s1,-248 # 80017c10 <tickslock>
    80002d10:	8526                	mv	a0,s1
    80002d12:	ffffe097          	auipc	ra,0xffffe
    80002d16:	ed2080e7          	jalr	-302(ra) # 80000be4 <acquire>
  ticks++;
    80002d1a:	00006517          	auipc	a0,0x6
    80002d1e:	31e50513          	addi	a0,a0,798 # 80009038 <ticks>
    80002d22:	411c                	lw	a5,0(a0)
    80002d24:	2785                	addiw	a5,a5,1
    80002d26:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002d28:	00000097          	auipc	ra,0x0
    80002d2c:	9b8080e7          	jalr	-1608(ra) # 800026e0 <wakeup>
  release(&tickslock);
    80002d30:	8526                	mv	a0,s1
    80002d32:	ffffe097          	auipc	ra,0xffffe
    80002d36:	f66080e7          	jalr	-154(ra) # 80000c98 <release>
}
    80002d3a:	60e2                	ld	ra,24(sp)
    80002d3c:	6442                	ld	s0,16(sp)
    80002d3e:	64a2                	ld	s1,8(sp)
    80002d40:	6105                	addi	sp,sp,32
    80002d42:	8082                	ret

0000000080002d44 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002d44:	1101                	addi	sp,sp,-32
    80002d46:	ec06                	sd	ra,24(sp)
    80002d48:	e822                	sd	s0,16(sp)
    80002d4a:	e426                	sd	s1,8(sp)
    80002d4c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d4e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002d52:	00074d63          	bltz	a4,80002d6c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002d56:	57fd                	li	a5,-1
    80002d58:	17fe                	slli	a5,a5,0x3f
    80002d5a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002d5c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002d5e:	06f70363          	beq	a4,a5,80002dc4 <devintr+0x80>
  }
}
    80002d62:	60e2                	ld	ra,24(sp)
    80002d64:	6442                	ld	s0,16(sp)
    80002d66:	64a2                	ld	s1,8(sp)
    80002d68:	6105                	addi	sp,sp,32
    80002d6a:	8082                	ret
     (scause & 0xff) == 9){
    80002d6c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002d70:	46a5                	li	a3,9
    80002d72:	fed792e3          	bne	a5,a3,80002d56 <devintr+0x12>
    int irq = plic_claim();
    80002d76:	00003097          	auipc	ra,0x3
    80002d7a:	4b2080e7          	jalr	1202(ra) # 80006228 <plic_claim>
    80002d7e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d80:	47a9                	li	a5,10
    80002d82:	02f50763          	beq	a0,a5,80002db0 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002d86:	4785                	li	a5,1
    80002d88:	02f50963          	beq	a0,a5,80002dba <devintr+0x76>
    return 1;
    80002d8c:	4505                	li	a0,1
    } else if(irq){
    80002d8e:	d8f1                	beqz	s1,80002d62 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d90:	85a6                	mv	a1,s1
    80002d92:	00005517          	auipc	a0,0x5
    80002d96:	5ee50513          	addi	a0,a0,1518 # 80008380 <states.1791+0x38>
    80002d9a:	ffffd097          	auipc	ra,0xffffd
    80002d9e:	7ee080e7          	jalr	2030(ra) # 80000588 <printf>
      plic_complete(irq);
    80002da2:	8526                	mv	a0,s1
    80002da4:	00003097          	auipc	ra,0x3
    80002da8:	4a8080e7          	jalr	1192(ra) # 8000624c <plic_complete>
    return 1;
    80002dac:	4505                	li	a0,1
    80002dae:	bf55                	j	80002d62 <devintr+0x1e>
      uartintr();
    80002db0:	ffffe097          	auipc	ra,0xffffe
    80002db4:	bf8080e7          	jalr	-1032(ra) # 800009a8 <uartintr>
    80002db8:	b7ed                	j	80002da2 <devintr+0x5e>
      virtio_disk_intr();
    80002dba:	00004097          	auipc	ra,0x4
    80002dbe:	972080e7          	jalr	-1678(ra) # 8000672c <virtio_disk_intr>
    80002dc2:	b7c5                	j	80002da2 <devintr+0x5e>
    if(cpuid() == 0){
    80002dc4:	fffff097          	auipc	ra,0xfffff
    80002dc8:	eda080e7          	jalr	-294(ra) # 80001c9e <cpuid>
    80002dcc:	c901                	beqz	a0,80002ddc <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002dce:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002dd2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002dd4:	14479073          	csrw	sip,a5
    return 2;
    80002dd8:	4509                	li	a0,2
    80002dda:	b761                	j	80002d62 <devintr+0x1e>
      clockintr();
    80002ddc:	00000097          	auipc	ra,0x0
    80002de0:	f22080e7          	jalr	-222(ra) # 80002cfe <clockintr>
    80002de4:	b7ed                	j	80002dce <devintr+0x8a>

0000000080002de6 <usertrap>:
{
    80002de6:	1101                	addi	sp,sp,-32
    80002de8:	ec06                	sd	ra,24(sp)
    80002dea:	e822                	sd	s0,16(sp)
    80002dec:	e426                	sd	s1,8(sp)
    80002dee:	e04a                	sd	s2,0(sp)
    80002df0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002df2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002df6:	1007f793          	andi	a5,a5,256
    80002dfa:	e3ad                	bnez	a5,80002e5c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002dfc:	00003797          	auipc	a5,0x3
    80002e00:	32478793          	addi	a5,a5,804 # 80006120 <kernelvec>
    80002e04:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	ec8080e7          	jalr	-312(ra) # 80001cd0 <myproc>
    80002e10:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e12:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e14:	14102773          	csrr	a4,sepc
    80002e18:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e1a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002e1e:	47a1                	li	a5,8
    80002e20:	04f71c63          	bne	a4,a5,80002e78 <usertrap+0x92>
    if(p->killed)
    80002e24:	551c                	lw	a5,40(a0)
    80002e26:	e3b9                	bnez	a5,80002e6c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002e28:	6cb8                	ld	a4,88(s1)
    80002e2a:	6f1c                	ld	a5,24(a4)
    80002e2c:	0791                	addi	a5,a5,4
    80002e2e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e30:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e34:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e38:	10079073          	csrw	sstatus,a5
    syscall();
    80002e3c:	00000097          	auipc	ra,0x0
    80002e40:	2e0080e7          	jalr	736(ra) # 8000311c <syscall>
  if(p->killed)
    80002e44:	549c                	lw	a5,40(s1)
    80002e46:	ebc1                	bnez	a5,80002ed6 <usertrap+0xf0>
  usertrapret();
    80002e48:	00000097          	auipc	ra,0x0
    80002e4c:	e18080e7          	jalr	-488(ra) # 80002c60 <usertrapret>
}
    80002e50:	60e2                	ld	ra,24(sp)
    80002e52:	6442                	ld	s0,16(sp)
    80002e54:	64a2                	ld	s1,8(sp)
    80002e56:	6902                	ld	s2,0(sp)
    80002e58:	6105                	addi	sp,sp,32
    80002e5a:	8082                	ret
    panic("usertrap: not from user mode");
    80002e5c:	00005517          	auipc	a0,0x5
    80002e60:	54450513          	addi	a0,a0,1348 # 800083a0 <states.1791+0x58>
    80002e64:	ffffd097          	auipc	ra,0xffffd
    80002e68:	6da080e7          	jalr	1754(ra) # 8000053e <panic>
      exit(-1);
    80002e6c:	557d                	li	a0,-1
    80002e6e:	00000097          	auipc	ra,0x0
    80002e72:	9f0080e7          	jalr	-1552(ra) # 8000285e <exit>
    80002e76:	bf4d                	j	80002e28 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002e78:	00000097          	auipc	ra,0x0
    80002e7c:	ecc080e7          	jalr	-308(ra) # 80002d44 <devintr>
    80002e80:	892a                	mv	s2,a0
    80002e82:	c501                	beqz	a0,80002e8a <usertrap+0xa4>
  if(p->killed)
    80002e84:	549c                	lw	a5,40(s1)
    80002e86:	c3a1                	beqz	a5,80002ec6 <usertrap+0xe0>
    80002e88:	a815                	j	80002ebc <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e8a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e8e:	5890                	lw	a2,48(s1)
    80002e90:	00005517          	auipc	a0,0x5
    80002e94:	53050513          	addi	a0,a0,1328 # 800083c0 <states.1791+0x78>
    80002e98:	ffffd097          	auipc	ra,0xffffd
    80002e9c:	6f0080e7          	jalr	1776(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ea0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ea4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ea8:	00005517          	auipc	a0,0x5
    80002eac:	54850513          	addi	a0,a0,1352 # 800083f0 <states.1791+0xa8>
    80002eb0:	ffffd097          	auipc	ra,0xffffd
    80002eb4:	6d8080e7          	jalr	1752(ra) # 80000588 <printf>
    p->killed = 1;
    80002eb8:	4785                	li	a5,1
    80002eba:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002ebc:	557d                	li	a0,-1
    80002ebe:	00000097          	auipc	ra,0x0
    80002ec2:	9a0080e7          	jalr	-1632(ra) # 8000285e <exit>
  if(which_dev == 2)
    80002ec6:	4789                	li	a5,2
    80002ec8:	f8f910e3          	bne	s2,a5,80002e48 <usertrap+0x62>
    yield();
    80002ecc:	fffff097          	auipc	ra,0xfffff
    80002ed0:	61a080e7          	jalr	1562(ra) # 800024e6 <yield>
    80002ed4:	bf95                	j	80002e48 <usertrap+0x62>
  int which_dev = 0;
    80002ed6:	4901                	li	s2,0
    80002ed8:	b7d5                	j	80002ebc <usertrap+0xd6>

0000000080002eda <kerneltrap>:
{
    80002eda:	7179                	addi	sp,sp,-48
    80002edc:	f406                	sd	ra,40(sp)
    80002ede:	f022                	sd	s0,32(sp)
    80002ee0:	ec26                	sd	s1,24(sp)
    80002ee2:	e84a                	sd	s2,16(sp)
    80002ee4:	e44e                	sd	s3,8(sp)
    80002ee6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ee8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002eec:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ef0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002ef4:	1004f793          	andi	a5,s1,256
    80002ef8:	cb85                	beqz	a5,80002f28 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002efa:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002efe:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f00:	ef85                	bnez	a5,80002f38 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002f02:	00000097          	auipc	ra,0x0
    80002f06:	e42080e7          	jalr	-446(ra) # 80002d44 <devintr>
    80002f0a:	cd1d                	beqz	a0,80002f48 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f0c:	4789                	li	a5,2
    80002f0e:	06f50a63          	beq	a0,a5,80002f82 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f12:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f16:	10049073          	csrw	sstatus,s1
}
    80002f1a:	70a2                	ld	ra,40(sp)
    80002f1c:	7402                	ld	s0,32(sp)
    80002f1e:	64e2                	ld	s1,24(sp)
    80002f20:	6942                	ld	s2,16(sp)
    80002f22:	69a2                	ld	s3,8(sp)
    80002f24:	6145                	addi	sp,sp,48
    80002f26:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f28:	00005517          	auipc	a0,0x5
    80002f2c:	4e850513          	addi	a0,a0,1256 # 80008410 <states.1791+0xc8>
    80002f30:	ffffd097          	auipc	ra,0xffffd
    80002f34:	60e080e7          	jalr	1550(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002f38:	00005517          	auipc	a0,0x5
    80002f3c:	50050513          	addi	a0,a0,1280 # 80008438 <states.1791+0xf0>
    80002f40:	ffffd097          	auipc	ra,0xffffd
    80002f44:	5fe080e7          	jalr	1534(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002f48:	85ce                	mv	a1,s3
    80002f4a:	00005517          	auipc	a0,0x5
    80002f4e:	50e50513          	addi	a0,a0,1294 # 80008458 <states.1791+0x110>
    80002f52:	ffffd097          	auipc	ra,0xffffd
    80002f56:	636080e7          	jalr	1590(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f5a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f5e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f62:	00005517          	auipc	a0,0x5
    80002f66:	50650513          	addi	a0,a0,1286 # 80008468 <states.1791+0x120>
    80002f6a:	ffffd097          	auipc	ra,0xffffd
    80002f6e:	61e080e7          	jalr	1566(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002f72:	00005517          	auipc	a0,0x5
    80002f76:	50e50513          	addi	a0,a0,1294 # 80008480 <states.1791+0x138>
    80002f7a:	ffffd097          	auipc	ra,0xffffd
    80002f7e:	5c4080e7          	jalr	1476(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f82:	fffff097          	auipc	ra,0xfffff
    80002f86:	d4e080e7          	jalr	-690(ra) # 80001cd0 <myproc>
    80002f8a:	d541                	beqz	a0,80002f12 <kerneltrap+0x38>
    80002f8c:	fffff097          	auipc	ra,0xfffff
    80002f90:	d44080e7          	jalr	-700(ra) # 80001cd0 <myproc>
    80002f94:	4d18                	lw	a4,24(a0)
    80002f96:	4791                	li	a5,4
    80002f98:	f6f71de3          	bne	a4,a5,80002f12 <kerneltrap+0x38>
    yield();
    80002f9c:	fffff097          	auipc	ra,0xfffff
    80002fa0:	54a080e7          	jalr	1354(ra) # 800024e6 <yield>
    80002fa4:	b7bd                	j	80002f12 <kerneltrap+0x38>

0000000080002fa6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002fa6:	1101                	addi	sp,sp,-32
    80002fa8:	ec06                	sd	ra,24(sp)
    80002faa:	e822                	sd	s0,16(sp)
    80002fac:	e426                	sd	s1,8(sp)
    80002fae:	1000                	addi	s0,sp,32
    80002fb0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002fb2:	fffff097          	auipc	ra,0xfffff
    80002fb6:	d1e080e7          	jalr	-738(ra) # 80001cd0 <myproc>
  switch (n) {
    80002fba:	4795                	li	a5,5
    80002fbc:	0497e163          	bltu	a5,s1,80002ffe <argraw+0x58>
    80002fc0:	048a                	slli	s1,s1,0x2
    80002fc2:	00005717          	auipc	a4,0x5
    80002fc6:	4f670713          	addi	a4,a4,1270 # 800084b8 <states.1791+0x170>
    80002fca:	94ba                	add	s1,s1,a4
    80002fcc:	409c                	lw	a5,0(s1)
    80002fce:	97ba                	add	a5,a5,a4
    80002fd0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002fd2:	6d3c                	ld	a5,88(a0)
    80002fd4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002fd6:	60e2                	ld	ra,24(sp)
    80002fd8:	6442                	ld	s0,16(sp)
    80002fda:	64a2                	ld	s1,8(sp)
    80002fdc:	6105                	addi	sp,sp,32
    80002fde:	8082                	ret
    return p->trapframe->a1;
    80002fe0:	6d3c                	ld	a5,88(a0)
    80002fe2:	7fa8                	ld	a0,120(a5)
    80002fe4:	bfcd                	j	80002fd6 <argraw+0x30>
    return p->trapframe->a2;
    80002fe6:	6d3c                	ld	a5,88(a0)
    80002fe8:	63c8                	ld	a0,128(a5)
    80002fea:	b7f5                	j	80002fd6 <argraw+0x30>
    return p->trapframe->a3;
    80002fec:	6d3c                	ld	a5,88(a0)
    80002fee:	67c8                	ld	a0,136(a5)
    80002ff0:	b7dd                	j	80002fd6 <argraw+0x30>
    return p->trapframe->a4;
    80002ff2:	6d3c                	ld	a5,88(a0)
    80002ff4:	6bc8                	ld	a0,144(a5)
    80002ff6:	b7c5                	j	80002fd6 <argraw+0x30>
    return p->trapframe->a5;
    80002ff8:	6d3c                	ld	a5,88(a0)
    80002ffa:	6fc8                	ld	a0,152(a5)
    80002ffc:	bfe9                	j	80002fd6 <argraw+0x30>
  panic("argraw");
    80002ffe:	00005517          	auipc	a0,0x5
    80003002:	49250513          	addi	a0,a0,1170 # 80008490 <states.1791+0x148>
    80003006:	ffffd097          	auipc	ra,0xffffd
    8000300a:	538080e7          	jalr	1336(ra) # 8000053e <panic>

000000008000300e <fetchaddr>:
{
    8000300e:	1101                	addi	sp,sp,-32
    80003010:	ec06                	sd	ra,24(sp)
    80003012:	e822                	sd	s0,16(sp)
    80003014:	e426                	sd	s1,8(sp)
    80003016:	e04a                	sd	s2,0(sp)
    80003018:	1000                	addi	s0,sp,32
    8000301a:	84aa                	mv	s1,a0
    8000301c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000301e:	fffff097          	auipc	ra,0xfffff
    80003022:	cb2080e7          	jalr	-846(ra) # 80001cd0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003026:	653c                	ld	a5,72(a0)
    80003028:	02f4f863          	bgeu	s1,a5,80003058 <fetchaddr+0x4a>
    8000302c:	00848713          	addi	a4,s1,8
    80003030:	02e7e663          	bltu	a5,a4,8000305c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003034:	46a1                	li	a3,8
    80003036:	8626                	mv	a2,s1
    80003038:	85ca                	mv	a1,s2
    8000303a:	6928                	ld	a0,80(a0)
    8000303c:	ffffe097          	auipc	ra,0xffffe
    80003040:	6c2080e7          	jalr	1730(ra) # 800016fe <copyin>
    80003044:	00a03533          	snez	a0,a0
    80003048:	40a00533          	neg	a0,a0
}
    8000304c:	60e2                	ld	ra,24(sp)
    8000304e:	6442                	ld	s0,16(sp)
    80003050:	64a2                	ld	s1,8(sp)
    80003052:	6902                	ld	s2,0(sp)
    80003054:	6105                	addi	sp,sp,32
    80003056:	8082                	ret
    return -1;
    80003058:	557d                	li	a0,-1
    8000305a:	bfcd                	j	8000304c <fetchaddr+0x3e>
    8000305c:	557d                	li	a0,-1
    8000305e:	b7fd                	j	8000304c <fetchaddr+0x3e>

0000000080003060 <fetchstr>:
{
    80003060:	7179                	addi	sp,sp,-48
    80003062:	f406                	sd	ra,40(sp)
    80003064:	f022                	sd	s0,32(sp)
    80003066:	ec26                	sd	s1,24(sp)
    80003068:	e84a                	sd	s2,16(sp)
    8000306a:	e44e                	sd	s3,8(sp)
    8000306c:	1800                	addi	s0,sp,48
    8000306e:	892a                	mv	s2,a0
    80003070:	84ae                	mv	s1,a1
    80003072:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003074:	fffff097          	auipc	ra,0xfffff
    80003078:	c5c080e7          	jalr	-932(ra) # 80001cd0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000307c:	86ce                	mv	a3,s3
    8000307e:	864a                	mv	a2,s2
    80003080:	85a6                	mv	a1,s1
    80003082:	6928                	ld	a0,80(a0)
    80003084:	ffffe097          	auipc	ra,0xffffe
    80003088:	706080e7          	jalr	1798(ra) # 8000178a <copyinstr>
  if(err < 0)
    8000308c:	00054763          	bltz	a0,8000309a <fetchstr+0x3a>
  return strlen(buf);
    80003090:	8526                	mv	a0,s1
    80003092:	ffffe097          	auipc	ra,0xffffe
    80003096:	dd2080e7          	jalr	-558(ra) # 80000e64 <strlen>
}
    8000309a:	70a2                	ld	ra,40(sp)
    8000309c:	7402                	ld	s0,32(sp)
    8000309e:	64e2                	ld	s1,24(sp)
    800030a0:	6942                	ld	s2,16(sp)
    800030a2:	69a2                	ld	s3,8(sp)
    800030a4:	6145                	addi	sp,sp,48
    800030a6:	8082                	ret

00000000800030a8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800030a8:	1101                	addi	sp,sp,-32
    800030aa:	ec06                	sd	ra,24(sp)
    800030ac:	e822                	sd	s0,16(sp)
    800030ae:	e426                	sd	s1,8(sp)
    800030b0:	1000                	addi	s0,sp,32
    800030b2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030b4:	00000097          	auipc	ra,0x0
    800030b8:	ef2080e7          	jalr	-270(ra) # 80002fa6 <argraw>
    800030bc:	c088                	sw	a0,0(s1)
  return 0;
}
    800030be:	4501                	li	a0,0
    800030c0:	60e2                	ld	ra,24(sp)
    800030c2:	6442                	ld	s0,16(sp)
    800030c4:	64a2                	ld	s1,8(sp)
    800030c6:	6105                	addi	sp,sp,32
    800030c8:	8082                	ret

00000000800030ca <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800030ca:	1101                	addi	sp,sp,-32
    800030cc:	ec06                	sd	ra,24(sp)
    800030ce:	e822                	sd	s0,16(sp)
    800030d0:	e426                	sd	s1,8(sp)
    800030d2:	1000                	addi	s0,sp,32
    800030d4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030d6:	00000097          	auipc	ra,0x0
    800030da:	ed0080e7          	jalr	-304(ra) # 80002fa6 <argraw>
    800030de:	e088                	sd	a0,0(s1)
  return 0;
}
    800030e0:	4501                	li	a0,0
    800030e2:	60e2                	ld	ra,24(sp)
    800030e4:	6442                	ld	s0,16(sp)
    800030e6:	64a2                	ld	s1,8(sp)
    800030e8:	6105                	addi	sp,sp,32
    800030ea:	8082                	ret

00000000800030ec <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800030ec:	1101                	addi	sp,sp,-32
    800030ee:	ec06                	sd	ra,24(sp)
    800030f0:	e822                	sd	s0,16(sp)
    800030f2:	e426                	sd	s1,8(sp)
    800030f4:	e04a                	sd	s2,0(sp)
    800030f6:	1000                	addi	s0,sp,32
    800030f8:	84ae                	mv	s1,a1
    800030fa:	8932                	mv	s2,a2
  *ip = argraw(n);
    800030fc:	00000097          	auipc	ra,0x0
    80003100:	eaa080e7          	jalr	-342(ra) # 80002fa6 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003104:	864a                	mv	a2,s2
    80003106:	85a6                	mv	a1,s1
    80003108:	00000097          	auipc	ra,0x0
    8000310c:	f58080e7          	jalr	-168(ra) # 80003060 <fetchstr>
}
    80003110:	60e2                	ld	ra,24(sp)
    80003112:	6442                	ld	s0,16(sp)
    80003114:	64a2                	ld	s1,8(sp)
    80003116:	6902                	ld	s2,0(sp)
    80003118:	6105                	addi	sp,sp,32
    8000311a:	8082                	ret

000000008000311c <syscall>:
// [SYS_cpu_process_count] sys_cpu_process_count,
};

void
syscall(void)
{
    8000311c:	1101                	addi	sp,sp,-32
    8000311e:	ec06                	sd	ra,24(sp)
    80003120:	e822                	sd	s0,16(sp)
    80003122:	e426                	sd	s1,8(sp)
    80003124:	e04a                	sd	s2,0(sp)
    80003126:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003128:	fffff097          	auipc	ra,0xfffff
    8000312c:	ba8080e7          	jalr	-1112(ra) # 80001cd0 <myproc>
    80003130:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003132:	05853903          	ld	s2,88(a0)
    80003136:	0a893783          	ld	a5,168(s2)
    8000313a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000313e:	37fd                	addiw	a5,a5,-1
    80003140:	4759                	li	a4,22
    80003142:	00f76f63          	bltu	a4,a5,80003160 <syscall+0x44>
    80003146:	00369713          	slli	a4,a3,0x3
    8000314a:	00005797          	auipc	a5,0x5
    8000314e:	38678793          	addi	a5,a5,902 # 800084d0 <syscalls>
    80003152:	97ba                	add	a5,a5,a4
    80003154:	639c                	ld	a5,0(a5)
    80003156:	c789                	beqz	a5,80003160 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003158:	9782                	jalr	a5
    8000315a:	06a93823          	sd	a0,112(s2)
    8000315e:	a839                	j	8000317c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003160:	15848613          	addi	a2,s1,344
    80003164:	588c                	lw	a1,48(s1)
    80003166:	00005517          	auipc	a0,0x5
    8000316a:	33250513          	addi	a0,a0,818 # 80008498 <states.1791+0x150>
    8000316e:	ffffd097          	auipc	ra,0xffffd
    80003172:	41a080e7          	jalr	1050(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003176:	6cbc                	ld	a5,88(s1)
    80003178:	577d                	li	a4,-1
    8000317a:	fbb8                	sd	a4,112(a5)
  }
}
    8000317c:	60e2                	ld	ra,24(sp)
    8000317e:	6442                	ld	s0,16(sp)
    80003180:	64a2                	ld	s1,8(sp)
    80003182:	6902                	ld	s2,0(sp)
    80003184:	6105                	addi	sp,sp,32
    80003186:	8082                	ret

0000000080003188 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003188:	1101                	addi	sp,sp,-32
    8000318a:	ec06                	sd	ra,24(sp)
    8000318c:	e822                	sd	s0,16(sp)
    8000318e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003190:	fec40593          	addi	a1,s0,-20
    80003194:	4501                	li	a0,0
    80003196:	00000097          	auipc	ra,0x0
    8000319a:	f12080e7          	jalr	-238(ra) # 800030a8 <argint>
    return -1;
    8000319e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800031a0:	00054963          	bltz	a0,800031b2 <sys_exit+0x2a>
  exit(n);
    800031a4:	fec42503          	lw	a0,-20(s0)
    800031a8:	fffff097          	auipc	ra,0xfffff
    800031ac:	6b6080e7          	jalr	1718(ra) # 8000285e <exit>
  return 0;  // not reached
    800031b0:	4781                	li	a5,0
}
    800031b2:	853e                	mv	a0,a5
    800031b4:	60e2                	ld	ra,24(sp)
    800031b6:	6442                	ld	s0,16(sp)
    800031b8:	6105                	addi	sp,sp,32
    800031ba:	8082                	ret

00000000800031bc <sys_getpid>:

uint64
sys_getpid(void)
{
    800031bc:	1141                	addi	sp,sp,-16
    800031be:	e406                	sd	ra,8(sp)
    800031c0:	e022                	sd	s0,0(sp)
    800031c2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800031c4:	fffff097          	auipc	ra,0xfffff
    800031c8:	b0c080e7          	jalr	-1268(ra) # 80001cd0 <myproc>
}
    800031cc:	5908                	lw	a0,48(a0)
    800031ce:	60a2                	ld	ra,8(sp)
    800031d0:	6402                	ld	s0,0(sp)
    800031d2:	0141                	addi	sp,sp,16
    800031d4:	8082                	ret

00000000800031d6 <sys_fork>:

uint64
sys_fork(void)
{
    800031d6:	1141                	addi	sp,sp,-16
    800031d8:	e406                	sd	ra,8(sp)
    800031da:	e022                	sd	s0,0(sp)
    800031dc:	0800                	addi	s0,sp,16
  return fork();
    800031de:	fffff097          	auipc	ra,0xfffff
    800031e2:	fc2080e7          	jalr	-62(ra) # 800021a0 <fork>
}
    800031e6:	60a2                	ld	ra,8(sp)
    800031e8:	6402                	ld	s0,0(sp)
    800031ea:	0141                	addi	sp,sp,16
    800031ec:	8082                	ret

00000000800031ee <sys_wait>:

uint64
sys_wait(void)
{
    800031ee:	1101                	addi	sp,sp,-32
    800031f0:	ec06                	sd	ra,24(sp)
    800031f2:	e822                	sd	s0,16(sp)
    800031f4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800031f6:	fe840593          	addi	a1,s0,-24
    800031fa:	4501                	li	a0,0
    800031fc:	00000097          	auipc	ra,0x0
    80003200:	ece080e7          	jalr	-306(ra) # 800030ca <argaddr>
    80003204:	87aa                	mv	a5,a0
    return -1;
    80003206:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003208:	0007c863          	bltz	a5,80003218 <sys_wait+0x2a>
  return wait(p);
    8000320c:	fe843503          	ld	a0,-24(s0)
    80003210:	fffff097          	auipc	ra,0xfffff
    80003214:	3a8080e7          	jalr	936(ra) # 800025b8 <wait>
}
    80003218:	60e2                	ld	ra,24(sp)
    8000321a:	6442                	ld	s0,16(sp)
    8000321c:	6105                	addi	sp,sp,32
    8000321e:	8082                	ret

0000000080003220 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003220:	7179                	addi	sp,sp,-48
    80003222:	f406                	sd	ra,40(sp)
    80003224:	f022                	sd	s0,32(sp)
    80003226:	ec26                	sd	s1,24(sp)
    80003228:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000322a:	fdc40593          	addi	a1,s0,-36
    8000322e:	4501                	li	a0,0
    80003230:	00000097          	auipc	ra,0x0
    80003234:	e78080e7          	jalr	-392(ra) # 800030a8 <argint>
    80003238:	87aa                	mv	a5,a0
    return -1;
    8000323a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000323c:	0207c063          	bltz	a5,8000325c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003240:	fffff097          	auipc	ra,0xfffff
    80003244:	a90080e7          	jalr	-1392(ra) # 80001cd0 <myproc>
    80003248:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    8000324a:	fdc42503          	lw	a0,-36(s0)
    8000324e:	fffff097          	auipc	ra,0xfffff
    80003252:	e9c080e7          	jalr	-356(ra) # 800020ea <growproc>
    80003256:	00054863          	bltz	a0,80003266 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000325a:	8526                	mv	a0,s1
}
    8000325c:	70a2                	ld	ra,40(sp)
    8000325e:	7402                	ld	s0,32(sp)
    80003260:	64e2                	ld	s1,24(sp)
    80003262:	6145                	addi	sp,sp,48
    80003264:	8082                	ret
    return -1;
    80003266:	557d                	li	a0,-1
    80003268:	bfd5                	j	8000325c <sys_sbrk+0x3c>

000000008000326a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000326a:	7139                	addi	sp,sp,-64
    8000326c:	fc06                	sd	ra,56(sp)
    8000326e:	f822                	sd	s0,48(sp)
    80003270:	f426                	sd	s1,40(sp)
    80003272:	f04a                	sd	s2,32(sp)
    80003274:	ec4e                	sd	s3,24(sp)
    80003276:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003278:	fcc40593          	addi	a1,s0,-52
    8000327c:	4501                	li	a0,0
    8000327e:	00000097          	auipc	ra,0x0
    80003282:	e2a080e7          	jalr	-470(ra) # 800030a8 <argint>
    return -1;
    80003286:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003288:	06054563          	bltz	a0,800032f2 <sys_sleep+0x88>
  acquire(&tickslock);
    8000328c:	00015517          	auipc	a0,0x15
    80003290:	98450513          	addi	a0,a0,-1660 # 80017c10 <tickslock>
    80003294:	ffffe097          	auipc	ra,0xffffe
    80003298:	950080e7          	jalr	-1712(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000329c:	00006917          	auipc	s2,0x6
    800032a0:	d9c92903          	lw	s2,-612(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    800032a4:	fcc42783          	lw	a5,-52(s0)
    800032a8:	cf85                	beqz	a5,800032e0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800032aa:	00015997          	auipc	s3,0x15
    800032ae:	96698993          	addi	s3,s3,-1690 # 80017c10 <tickslock>
    800032b2:	00006497          	auipc	s1,0x6
    800032b6:	d8648493          	addi	s1,s1,-634 # 80009038 <ticks>
    if(myproc()->killed){
    800032ba:	fffff097          	auipc	ra,0xfffff
    800032be:	a16080e7          	jalr	-1514(ra) # 80001cd0 <myproc>
    800032c2:	551c                	lw	a5,40(a0)
    800032c4:	ef9d                	bnez	a5,80003302 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800032c6:	85ce                	mv	a1,s3
    800032c8:	8526                	mv	a0,s1
    800032ca:	fffff097          	auipc	ra,0xfffff
    800032ce:	278080e7          	jalr	632(ra) # 80002542 <sleep>
  while(ticks - ticks0 < n){
    800032d2:	409c                	lw	a5,0(s1)
    800032d4:	412787bb          	subw	a5,a5,s2
    800032d8:	fcc42703          	lw	a4,-52(s0)
    800032dc:	fce7efe3          	bltu	a5,a4,800032ba <sys_sleep+0x50>
  }
  release(&tickslock);
    800032e0:	00015517          	auipc	a0,0x15
    800032e4:	93050513          	addi	a0,a0,-1744 # 80017c10 <tickslock>
    800032e8:	ffffe097          	auipc	ra,0xffffe
    800032ec:	9b0080e7          	jalr	-1616(ra) # 80000c98 <release>
  return 0;
    800032f0:	4781                	li	a5,0
}
    800032f2:	853e                	mv	a0,a5
    800032f4:	70e2                	ld	ra,56(sp)
    800032f6:	7442                	ld	s0,48(sp)
    800032f8:	74a2                	ld	s1,40(sp)
    800032fa:	7902                	ld	s2,32(sp)
    800032fc:	69e2                	ld	s3,24(sp)
    800032fe:	6121                	addi	sp,sp,64
    80003300:	8082                	ret
      release(&tickslock);
    80003302:	00015517          	auipc	a0,0x15
    80003306:	90e50513          	addi	a0,a0,-1778 # 80017c10 <tickslock>
    8000330a:	ffffe097          	auipc	ra,0xffffe
    8000330e:	98e080e7          	jalr	-1650(ra) # 80000c98 <release>
      return -1;
    80003312:	57fd                	li	a5,-1
    80003314:	bff9                	j	800032f2 <sys_sleep+0x88>

0000000080003316 <sys_kill>:

uint64
sys_kill(void)
{
    80003316:	1101                	addi	sp,sp,-32
    80003318:	ec06                	sd	ra,24(sp)
    8000331a:	e822                	sd	s0,16(sp)
    8000331c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000331e:	fec40593          	addi	a1,s0,-20
    80003322:	4501                	li	a0,0
    80003324:	00000097          	auipc	ra,0x0
    80003328:	d84080e7          	jalr	-636(ra) # 800030a8 <argint>
    8000332c:	87aa                	mv	a5,a0
    return -1;
    8000332e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003330:	0007c863          	bltz	a5,80003340 <sys_kill+0x2a>
  return kill(pid);
    80003334:	fec42503          	lw	a0,-20(s0)
    80003338:	fffff097          	auipc	ra,0xfffff
    8000333c:	60e080e7          	jalr	1550(ra) # 80002946 <kill>
}
    80003340:	60e2                	ld	ra,24(sp)
    80003342:	6442                	ld	s0,16(sp)
    80003344:	6105                	addi	sp,sp,32
    80003346:	8082                	ret

0000000080003348 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003348:	1101                	addi	sp,sp,-32
    8000334a:	ec06                	sd	ra,24(sp)
    8000334c:	e822                	sd	s0,16(sp)
    8000334e:	e426                	sd	s1,8(sp)
    80003350:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003352:	00015517          	auipc	a0,0x15
    80003356:	8be50513          	addi	a0,a0,-1858 # 80017c10 <tickslock>
    8000335a:	ffffe097          	auipc	ra,0xffffe
    8000335e:	88a080e7          	jalr	-1910(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003362:	00006497          	auipc	s1,0x6
    80003366:	cd64a483          	lw	s1,-810(s1) # 80009038 <ticks>
  release(&tickslock);
    8000336a:	00015517          	auipc	a0,0x15
    8000336e:	8a650513          	addi	a0,a0,-1882 # 80017c10 <tickslock>
    80003372:	ffffe097          	auipc	ra,0xffffe
    80003376:	926080e7          	jalr	-1754(ra) # 80000c98 <release>
  return xticks;
}
    8000337a:	02049513          	slli	a0,s1,0x20
    8000337e:	9101                	srli	a0,a0,0x20
    80003380:	60e2                	ld	ra,24(sp)
    80003382:	6442                	ld	s0,16(sp)
    80003384:	64a2                	ld	s1,8(sp)
    80003386:	6105                	addi	sp,sp,32
    80003388:	8082                	ret

000000008000338a <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    8000338a:	1141                	addi	sp,sp,-16
    8000338c:	e406                	sd	ra,8(sp)
    8000338e:	e022                	sd	s0,0(sp)
    80003390:	0800                	addi	s0,sp,16
  return get_cpu();
    80003392:	00000097          	auipc	ra,0x0
    80003396:	808080e7          	jalr	-2040(ra) # 80002b9a <get_cpu>
}
    8000339a:	60a2                	ld	ra,8(sp)
    8000339c:	6402                	ld	s0,0(sp)
    8000339e:	0141                	addi	sp,sp,16
    800033a0:	8082                	ret

00000000800033a2 <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    800033a2:	1101                	addi	sp,sp,-32
    800033a4:	ec06                	sd	ra,24(sp)
    800033a6:	e822                	sd	s0,16(sp)
    800033a8:	1000                	addi	s0,sp,32
  int cpu_num;

  if(argint(0, &cpu_num) < 0)
    800033aa:	fec40593          	addi	a1,s0,-20
    800033ae:	4501                	li	a0,0
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	cf8080e7          	jalr	-776(ra) # 800030a8 <argint>
    800033b8:	87aa                	mv	a5,a0
    return -1;
    800033ba:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    800033bc:	0007c863          	bltz	a5,800033cc <sys_set_cpu+0x2a>
  return set_cpu(cpu_num);
    800033c0:	fec42503          	lw	a0,-20(s0)
    800033c4:	fffff097          	auipc	ra,0xfffff
    800033c8:	780080e7          	jalr	1920(ra) # 80002b44 <set_cpu>
}
    800033cc:	60e2                	ld	ra,24(sp)
    800033ce:	6442                	ld	s0,16(sp)
    800033d0:	6105                	addi	sp,sp,32
    800033d2:	8082                	ret

00000000800033d4 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800033d4:	7179                	addi	sp,sp,-48
    800033d6:	f406                	sd	ra,40(sp)
    800033d8:	f022                	sd	s0,32(sp)
    800033da:	ec26                	sd	s1,24(sp)
    800033dc:	e84a                	sd	s2,16(sp)
    800033de:	e44e                	sd	s3,8(sp)
    800033e0:	e052                	sd	s4,0(sp)
    800033e2:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800033e4:	00005597          	auipc	a1,0x5
    800033e8:	1ac58593          	addi	a1,a1,428 # 80008590 <syscalls+0xc0>
    800033ec:	00015517          	auipc	a0,0x15
    800033f0:	83c50513          	addi	a0,a0,-1988 # 80017c28 <bcache>
    800033f4:	ffffd097          	auipc	ra,0xffffd
    800033f8:	760080e7          	jalr	1888(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033fc:	0001d797          	auipc	a5,0x1d
    80003400:	82c78793          	addi	a5,a5,-2004 # 8001fc28 <bcache+0x8000>
    80003404:	0001d717          	auipc	a4,0x1d
    80003408:	a8c70713          	addi	a4,a4,-1396 # 8001fe90 <bcache+0x8268>
    8000340c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003410:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003414:	00015497          	auipc	s1,0x15
    80003418:	82c48493          	addi	s1,s1,-2004 # 80017c40 <bcache+0x18>
    b->next = bcache.head.next;
    8000341c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000341e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003420:	00005a17          	auipc	s4,0x5
    80003424:	178a0a13          	addi	s4,s4,376 # 80008598 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003428:	2b893783          	ld	a5,696(s2)
    8000342c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000342e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003432:	85d2                	mv	a1,s4
    80003434:	01048513          	addi	a0,s1,16
    80003438:	00001097          	auipc	ra,0x1
    8000343c:	4bc080e7          	jalr	1212(ra) # 800048f4 <initsleeplock>
    bcache.head.next->prev = b;
    80003440:	2b893783          	ld	a5,696(s2)
    80003444:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003446:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000344a:	45848493          	addi	s1,s1,1112
    8000344e:	fd349de3          	bne	s1,s3,80003428 <binit+0x54>
  }
}
    80003452:	70a2                	ld	ra,40(sp)
    80003454:	7402                	ld	s0,32(sp)
    80003456:	64e2                	ld	s1,24(sp)
    80003458:	6942                	ld	s2,16(sp)
    8000345a:	69a2                	ld	s3,8(sp)
    8000345c:	6a02                	ld	s4,0(sp)
    8000345e:	6145                	addi	sp,sp,48
    80003460:	8082                	ret

0000000080003462 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003462:	7179                	addi	sp,sp,-48
    80003464:	f406                	sd	ra,40(sp)
    80003466:	f022                	sd	s0,32(sp)
    80003468:	ec26                	sd	s1,24(sp)
    8000346a:	e84a                	sd	s2,16(sp)
    8000346c:	e44e                	sd	s3,8(sp)
    8000346e:	1800                	addi	s0,sp,48
    80003470:	89aa                	mv	s3,a0
    80003472:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003474:	00014517          	auipc	a0,0x14
    80003478:	7b450513          	addi	a0,a0,1972 # 80017c28 <bcache>
    8000347c:	ffffd097          	auipc	ra,0xffffd
    80003480:	768080e7          	jalr	1896(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003484:	0001d497          	auipc	s1,0x1d
    80003488:	a5c4b483          	ld	s1,-1444(s1) # 8001fee0 <bcache+0x82b8>
    8000348c:	0001d797          	auipc	a5,0x1d
    80003490:	a0478793          	addi	a5,a5,-1532 # 8001fe90 <bcache+0x8268>
    80003494:	02f48f63          	beq	s1,a5,800034d2 <bread+0x70>
    80003498:	873e                	mv	a4,a5
    8000349a:	a021                	j	800034a2 <bread+0x40>
    8000349c:	68a4                	ld	s1,80(s1)
    8000349e:	02e48a63          	beq	s1,a4,800034d2 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800034a2:	449c                	lw	a5,8(s1)
    800034a4:	ff379ce3          	bne	a5,s3,8000349c <bread+0x3a>
    800034a8:	44dc                	lw	a5,12(s1)
    800034aa:	ff2799e3          	bne	a5,s2,8000349c <bread+0x3a>
      b->refcnt++;
    800034ae:	40bc                	lw	a5,64(s1)
    800034b0:	2785                	addiw	a5,a5,1
    800034b2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034b4:	00014517          	auipc	a0,0x14
    800034b8:	77450513          	addi	a0,a0,1908 # 80017c28 <bcache>
    800034bc:	ffffd097          	auipc	ra,0xffffd
    800034c0:	7dc080e7          	jalr	2012(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800034c4:	01048513          	addi	a0,s1,16
    800034c8:	00001097          	auipc	ra,0x1
    800034cc:	466080e7          	jalr	1126(ra) # 8000492e <acquiresleep>
      return b;
    800034d0:	a8b9                	j	8000352e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034d2:	0001d497          	auipc	s1,0x1d
    800034d6:	a064b483          	ld	s1,-1530(s1) # 8001fed8 <bcache+0x82b0>
    800034da:	0001d797          	auipc	a5,0x1d
    800034de:	9b678793          	addi	a5,a5,-1610 # 8001fe90 <bcache+0x8268>
    800034e2:	00f48863          	beq	s1,a5,800034f2 <bread+0x90>
    800034e6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800034e8:	40bc                	lw	a5,64(s1)
    800034ea:	cf81                	beqz	a5,80003502 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034ec:	64a4                	ld	s1,72(s1)
    800034ee:	fee49de3          	bne	s1,a4,800034e8 <bread+0x86>
  panic("bget: no buffers");
    800034f2:	00005517          	auipc	a0,0x5
    800034f6:	0ae50513          	addi	a0,a0,174 # 800085a0 <syscalls+0xd0>
    800034fa:	ffffd097          	auipc	ra,0xffffd
    800034fe:	044080e7          	jalr	68(ra) # 8000053e <panic>
      b->dev = dev;
    80003502:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003506:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000350a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000350e:	4785                	li	a5,1
    80003510:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003512:	00014517          	auipc	a0,0x14
    80003516:	71650513          	addi	a0,a0,1814 # 80017c28 <bcache>
    8000351a:	ffffd097          	auipc	ra,0xffffd
    8000351e:	77e080e7          	jalr	1918(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003522:	01048513          	addi	a0,s1,16
    80003526:	00001097          	auipc	ra,0x1
    8000352a:	408080e7          	jalr	1032(ra) # 8000492e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000352e:	409c                	lw	a5,0(s1)
    80003530:	cb89                	beqz	a5,80003542 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003532:	8526                	mv	a0,s1
    80003534:	70a2                	ld	ra,40(sp)
    80003536:	7402                	ld	s0,32(sp)
    80003538:	64e2                	ld	s1,24(sp)
    8000353a:	6942                	ld	s2,16(sp)
    8000353c:	69a2                	ld	s3,8(sp)
    8000353e:	6145                	addi	sp,sp,48
    80003540:	8082                	ret
    virtio_disk_rw(b, 0);
    80003542:	4581                	li	a1,0
    80003544:	8526                	mv	a0,s1
    80003546:	00003097          	auipc	ra,0x3
    8000354a:	f10080e7          	jalr	-240(ra) # 80006456 <virtio_disk_rw>
    b->valid = 1;
    8000354e:	4785                	li	a5,1
    80003550:	c09c                	sw	a5,0(s1)
  return b;
    80003552:	b7c5                	j	80003532 <bread+0xd0>

0000000080003554 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003554:	1101                	addi	sp,sp,-32
    80003556:	ec06                	sd	ra,24(sp)
    80003558:	e822                	sd	s0,16(sp)
    8000355a:	e426                	sd	s1,8(sp)
    8000355c:	1000                	addi	s0,sp,32
    8000355e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003560:	0541                	addi	a0,a0,16
    80003562:	00001097          	auipc	ra,0x1
    80003566:	466080e7          	jalr	1126(ra) # 800049c8 <holdingsleep>
    8000356a:	cd01                	beqz	a0,80003582 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000356c:	4585                	li	a1,1
    8000356e:	8526                	mv	a0,s1
    80003570:	00003097          	auipc	ra,0x3
    80003574:	ee6080e7          	jalr	-282(ra) # 80006456 <virtio_disk_rw>
}
    80003578:	60e2                	ld	ra,24(sp)
    8000357a:	6442                	ld	s0,16(sp)
    8000357c:	64a2                	ld	s1,8(sp)
    8000357e:	6105                	addi	sp,sp,32
    80003580:	8082                	ret
    panic("bwrite");
    80003582:	00005517          	auipc	a0,0x5
    80003586:	03650513          	addi	a0,a0,54 # 800085b8 <syscalls+0xe8>
    8000358a:	ffffd097          	auipc	ra,0xffffd
    8000358e:	fb4080e7          	jalr	-76(ra) # 8000053e <panic>

0000000080003592 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003592:	1101                	addi	sp,sp,-32
    80003594:	ec06                	sd	ra,24(sp)
    80003596:	e822                	sd	s0,16(sp)
    80003598:	e426                	sd	s1,8(sp)
    8000359a:	e04a                	sd	s2,0(sp)
    8000359c:	1000                	addi	s0,sp,32
    8000359e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035a0:	01050913          	addi	s2,a0,16
    800035a4:	854a                	mv	a0,s2
    800035a6:	00001097          	auipc	ra,0x1
    800035aa:	422080e7          	jalr	1058(ra) # 800049c8 <holdingsleep>
    800035ae:	c92d                	beqz	a0,80003620 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800035b0:	854a                	mv	a0,s2
    800035b2:	00001097          	auipc	ra,0x1
    800035b6:	3d2080e7          	jalr	978(ra) # 80004984 <releasesleep>

  acquire(&bcache.lock);
    800035ba:	00014517          	auipc	a0,0x14
    800035be:	66e50513          	addi	a0,a0,1646 # 80017c28 <bcache>
    800035c2:	ffffd097          	auipc	ra,0xffffd
    800035c6:	622080e7          	jalr	1570(ra) # 80000be4 <acquire>
  b->refcnt--;
    800035ca:	40bc                	lw	a5,64(s1)
    800035cc:	37fd                	addiw	a5,a5,-1
    800035ce:	0007871b          	sext.w	a4,a5
    800035d2:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800035d4:	eb05                	bnez	a4,80003604 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800035d6:	68bc                	ld	a5,80(s1)
    800035d8:	64b8                	ld	a4,72(s1)
    800035da:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800035dc:	64bc                	ld	a5,72(s1)
    800035de:	68b8                	ld	a4,80(s1)
    800035e0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800035e2:	0001c797          	auipc	a5,0x1c
    800035e6:	64678793          	addi	a5,a5,1606 # 8001fc28 <bcache+0x8000>
    800035ea:	2b87b703          	ld	a4,696(a5)
    800035ee:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800035f0:	0001d717          	auipc	a4,0x1d
    800035f4:	8a070713          	addi	a4,a4,-1888 # 8001fe90 <bcache+0x8268>
    800035f8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035fa:	2b87b703          	ld	a4,696(a5)
    800035fe:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003600:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003604:	00014517          	auipc	a0,0x14
    80003608:	62450513          	addi	a0,a0,1572 # 80017c28 <bcache>
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	68c080e7          	jalr	1676(ra) # 80000c98 <release>
}
    80003614:	60e2                	ld	ra,24(sp)
    80003616:	6442                	ld	s0,16(sp)
    80003618:	64a2                	ld	s1,8(sp)
    8000361a:	6902                	ld	s2,0(sp)
    8000361c:	6105                	addi	sp,sp,32
    8000361e:	8082                	ret
    panic("brelse");
    80003620:	00005517          	auipc	a0,0x5
    80003624:	fa050513          	addi	a0,a0,-96 # 800085c0 <syscalls+0xf0>
    80003628:	ffffd097          	auipc	ra,0xffffd
    8000362c:	f16080e7          	jalr	-234(ra) # 8000053e <panic>

0000000080003630 <bpin>:

void
bpin(struct buf *b) {
    80003630:	1101                	addi	sp,sp,-32
    80003632:	ec06                	sd	ra,24(sp)
    80003634:	e822                	sd	s0,16(sp)
    80003636:	e426                	sd	s1,8(sp)
    80003638:	1000                	addi	s0,sp,32
    8000363a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000363c:	00014517          	auipc	a0,0x14
    80003640:	5ec50513          	addi	a0,a0,1516 # 80017c28 <bcache>
    80003644:	ffffd097          	auipc	ra,0xffffd
    80003648:	5a0080e7          	jalr	1440(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000364c:	40bc                	lw	a5,64(s1)
    8000364e:	2785                	addiw	a5,a5,1
    80003650:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003652:	00014517          	auipc	a0,0x14
    80003656:	5d650513          	addi	a0,a0,1494 # 80017c28 <bcache>
    8000365a:	ffffd097          	auipc	ra,0xffffd
    8000365e:	63e080e7          	jalr	1598(ra) # 80000c98 <release>
}
    80003662:	60e2                	ld	ra,24(sp)
    80003664:	6442                	ld	s0,16(sp)
    80003666:	64a2                	ld	s1,8(sp)
    80003668:	6105                	addi	sp,sp,32
    8000366a:	8082                	ret

000000008000366c <bunpin>:

void
bunpin(struct buf *b) {
    8000366c:	1101                	addi	sp,sp,-32
    8000366e:	ec06                	sd	ra,24(sp)
    80003670:	e822                	sd	s0,16(sp)
    80003672:	e426                	sd	s1,8(sp)
    80003674:	1000                	addi	s0,sp,32
    80003676:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003678:	00014517          	auipc	a0,0x14
    8000367c:	5b050513          	addi	a0,a0,1456 # 80017c28 <bcache>
    80003680:	ffffd097          	auipc	ra,0xffffd
    80003684:	564080e7          	jalr	1380(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003688:	40bc                	lw	a5,64(s1)
    8000368a:	37fd                	addiw	a5,a5,-1
    8000368c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000368e:	00014517          	auipc	a0,0x14
    80003692:	59a50513          	addi	a0,a0,1434 # 80017c28 <bcache>
    80003696:	ffffd097          	auipc	ra,0xffffd
    8000369a:	602080e7          	jalr	1538(ra) # 80000c98 <release>
}
    8000369e:	60e2                	ld	ra,24(sp)
    800036a0:	6442                	ld	s0,16(sp)
    800036a2:	64a2                	ld	s1,8(sp)
    800036a4:	6105                	addi	sp,sp,32
    800036a6:	8082                	ret

00000000800036a8 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800036a8:	1101                	addi	sp,sp,-32
    800036aa:	ec06                	sd	ra,24(sp)
    800036ac:	e822                	sd	s0,16(sp)
    800036ae:	e426                	sd	s1,8(sp)
    800036b0:	e04a                	sd	s2,0(sp)
    800036b2:	1000                	addi	s0,sp,32
    800036b4:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800036b6:	00d5d59b          	srliw	a1,a1,0xd
    800036ba:	0001d797          	auipc	a5,0x1d
    800036be:	c4a7a783          	lw	a5,-950(a5) # 80020304 <sb+0x1c>
    800036c2:	9dbd                	addw	a1,a1,a5
    800036c4:	00000097          	auipc	ra,0x0
    800036c8:	d9e080e7          	jalr	-610(ra) # 80003462 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800036cc:	0074f713          	andi	a4,s1,7
    800036d0:	4785                	li	a5,1
    800036d2:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800036d6:	14ce                	slli	s1,s1,0x33
    800036d8:	90d9                	srli	s1,s1,0x36
    800036da:	00950733          	add	a4,a0,s1
    800036de:	05874703          	lbu	a4,88(a4)
    800036e2:	00e7f6b3          	and	a3,a5,a4
    800036e6:	c69d                	beqz	a3,80003714 <bfree+0x6c>
    800036e8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800036ea:	94aa                	add	s1,s1,a0
    800036ec:	fff7c793          	not	a5,a5
    800036f0:	8ff9                	and	a5,a5,a4
    800036f2:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800036f6:	00001097          	auipc	ra,0x1
    800036fa:	118080e7          	jalr	280(ra) # 8000480e <log_write>
  brelse(bp);
    800036fe:	854a                	mv	a0,s2
    80003700:	00000097          	auipc	ra,0x0
    80003704:	e92080e7          	jalr	-366(ra) # 80003592 <brelse>
}
    80003708:	60e2                	ld	ra,24(sp)
    8000370a:	6442                	ld	s0,16(sp)
    8000370c:	64a2                	ld	s1,8(sp)
    8000370e:	6902                	ld	s2,0(sp)
    80003710:	6105                	addi	sp,sp,32
    80003712:	8082                	ret
    panic("freeing free block");
    80003714:	00005517          	auipc	a0,0x5
    80003718:	eb450513          	addi	a0,a0,-332 # 800085c8 <syscalls+0xf8>
    8000371c:	ffffd097          	auipc	ra,0xffffd
    80003720:	e22080e7          	jalr	-478(ra) # 8000053e <panic>

0000000080003724 <balloc>:
{
    80003724:	711d                	addi	sp,sp,-96
    80003726:	ec86                	sd	ra,88(sp)
    80003728:	e8a2                	sd	s0,80(sp)
    8000372a:	e4a6                	sd	s1,72(sp)
    8000372c:	e0ca                	sd	s2,64(sp)
    8000372e:	fc4e                	sd	s3,56(sp)
    80003730:	f852                	sd	s4,48(sp)
    80003732:	f456                	sd	s5,40(sp)
    80003734:	f05a                	sd	s6,32(sp)
    80003736:	ec5e                	sd	s7,24(sp)
    80003738:	e862                	sd	s8,16(sp)
    8000373a:	e466                	sd	s9,8(sp)
    8000373c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000373e:	0001d797          	auipc	a5,0x1d
    80003742:	bae7a783          	lw	a5,-1106(a5) # 800202ec <sb+0x4>
    80003746:	cbd1                	beqz	a5,800037da <balloc+0xb6>
    80003748:	8baa                	mv	s7,a0
    8000374a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000374c:	0001db17          	auipc	s6,0x1d
    80003750:	b9cb0b13          	addi	s6,s6,-1124 # 800202e8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003754:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003756:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003758:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000375a:	6c89                	lui	s9,0x2
    8000375c:	a831                	j	80003778 <balloc+0x54>
    brelse(bp);
    8000375e:	854a                	mv	a0,s2
    80003760:	00000097          	auipc	ra,0x0
    80003764:	e32080e7          	jalr	-462(ra) # 80003592 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003768:	015c87bb          	addw	a5,s9,s5
    8000376c:	00078a9b          	sext.w	s5,a5
    80003770:	004b2703          	lw	a4,4(s6)
    80003774:	06eaf363          	bgeu	s5,a4,800037da <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003778:	41fad79b          	sraiw	a5,s5,0x1f
    8000377c:	0137d79b          	srliw	a5,a5,0x13
    80003780:	015787bb          	addw	a5,a5,s5
    80003784:	40d7d79b          	sraiw	a5,a5,0xd
    80003788:	01cb2583          	lw	a1,28(s6)
    8000378c:	9dbd                	addw	a1,a1,a5
    8000378e:	855e                	mv	a0,s7
    80003790:	00000097          	auipc	ra,0x0
    80003794:	cd2080e7          	jalr	-814(ra) # 80003462 <bread>
    80003798:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000379a:	004b2503          	lw	a0,4(s6)
    8000379e:	000a849b          	sext.w	s1,s5
    800037a2:	8662                	mv	a2,s8
    800037a4:	faa4fde3          	bgeu	s1,a0,8000375e <balloc+0x3a>
      m = 1 << (bi % 8);
    800037a8:	41f6579b          	sraiw	a5,a2,0x1f
    800037ac:	01d7d69b          	srliw	a3,a5,0x1d
    800037b0:	00c6873b          	addw	a4,a3,a2
    800037b4:	00777793          	andi	a5,a4,7
    800037b8:	9f95                	subw	a5,a5,a3
    800037ba:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800037be:	4037571b          	sraiw	a4,a4,0x3
    800037c2:	00e906b3          	add	a3,s2,a4
    800037c6:	0586c683          	lbu	a3,88(a3)
    800037ca:	00d7f5b3          	and	a1,a5,a3
    800037ce:	cd91                	beqz	a1,800037ea <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037d0:	2605                	addiw	a2,a2,1
    800037d2:	2485                	addiw	s1,s1,1
    800037d4:	fd4618e3          	bne	a2,s4,800037a4 <balloc+0x80>
    800037d8:	b759                	j	8000375e <balloc+0x3a>
  panic("balloc: out of blocks");
    800037da:	00005517          	auipc	a0,0x5
    800037de:	e0650513          	addi	a0,a0,-506 # 800085e0 <syscalls+0x110>
    800037e2:	ffffd097          	auipc	ra,0xffffd
    800037e6:	d5c080e7          	jalr	-676(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800037ea:	974a                	add	a4,a4,s2
    800037ec:	8fd5                	or	a5,a5,a3
    800037ee:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800037f2:	854a                	mv	a0,s2
    800037f4:	00001097          	auipc	ra,0x1
    800037f8:	01a080e7          	jalr	26(ra) # 8000480e <log_write>
        brelse(bp);
    800037fc:	854a                	mv	a0,s2
    800037fe:	00000097          	auipc	ra,0x0
    80003802:	d94080e7          	jalr	-620(ra) # 80003592 <brelse>
  bp = bread(dev, bno);
    80003806:	85a6                	mv	a1,s1
    80003808:	855e                	mv	a0,s7
    8000380a:	00000097          	auipc	ra,0x0
    8000380e:	c58080e7          	jalr	-936(ra) # 80003462 <bread>
    80003812:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003814:	40000613          	li	a2,1024
    80003818:	4581                	li	a1,0
    8000381a:	05850513          	addi	a0,a0,88
    8000381e:	ffffd097          	auipc	ra,0xffffd
    80003822:	4c2080e7          	jalr	1218(ra) # 80000ce0 <memset>
  log_write(bp);
    80003826:	854a                	mv	a0,s2
    80003828:	00001097          	auipc	ra,0x1
    8000382c:	fe6080e7          	jalr	-26(ra) # 8000480e <log_write>
  brelse(bp);
    80003830:	854a                	mv	a0,s2
    80003832:	00000097          	auipc	ra,0x0
    80003836:	d60080e7          	jalr	-672(ra) # 80003592 <brelse>
}
    8000383a:	8526                	mv	a0,s1
    8000383c:	60e6                	ld	ra,88(sp)
    8000383e:	6446                	ld	s0,80(sp)
    80003840:	64a6                	ld	s1,72(sp)
    80003842:	6906                	ld	s2,64(sp)
    80003844:	79e2                	ld	s3,56(sp)
    80003846:	7a42                	ld	s4,48(sp)
    80003848:	7aa2                	ld	s5,40(sp)
    8000384a:	7b02                	ld	s6,32(sp)
    8000384c:	6be2                	ld	s7,24(sp)
    8000384e:	6c42                	ld	s8,16(sp)
    80003850:	6ca2                	ld	s9,8(sp)
    80003852:	6125                	addi	sp,sp,96
    80003854:	8082                	ret

0000000080003856 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003856:	7179                	addi	sp,sp,-48
    80003858:	f406                	sd	ra,40(sp)
    8000385a:	f022                	sd	s0,32(sp)
    8000385c:	ec26                	sd	s1,24(sp)
    8000385e:	e84a                	sd	s2,16(sp)
    80003860:	e44e                	sd	s3,8(sp)
    80003862:	e052                	sd	s4,0(sp)
    80003864:	1800                	addi	s0,sp,48
    80003866:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003868:	47ad                	li	a5,11
    8000386a:	04b7fe63          	bgeu	a5,a1,800038c6 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000386e:	ff45849b          	addiw	s1,a1,-12
    80003872:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003876:	0ff00793          	li	a5,255
    8000387a:	0ae7e363          	bltu	a5,a4,80003920 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000387e:	08052583          	lw	a1,128(a0)
    80003882:	c5ad                	beqz	a1,800038ec <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003884:	00092503          	lw	a0,0(s2)
    80003888:	00000097          	auipc	ra,0x0
    8000388c:	bda080e7          	jalr	-1062(ra) # 80003462 <bread>
    80003890:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003892:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003896:	02049593          	slli	a1,s1,0x20
    8000389a:	9181                	srli	a1,a1,0x20
    8000389c:	058a                	slli	a1,a1,0x2
    8000389e:	00b784b3          	add	s1,a5,a1
    800038a2:	0004a983          	lw	s3,0(s1)
    800038a6:	04098d63          	beqz	s3,80003900 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800038aa:	8552                	mv	a0,s4
    800038ac:	00000097          	auipc	ra,0x0
    800038b0:	ce6080e7          	jalr	-794(ra) # 80003592 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800038b4:	854e                	mv	a0,s3
    800038b6:	70a2                	ld	ra,40(sp)
    800038b8:	7402                	ld	s0,32(sp)
    800038ba:	64e2                	ld	s1,24(sp)
    800038bc:	6942                	ld	s2,16(sp)
    800038be:	69a2                	ld	s3,8(sp)
    800038c0:	6a02                	ld	s4,0(sp)
    800038c2:	6145                	addi	sp,sp,48
    800038c4:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800038c6:	02059493          	slli	s1,a1,0x20
    800038ca:	9081                	srli	s1,s1,0x20
    800038cc:	048a                	slli	s1,s1,0x2
    800038ce:	94aa                	add	s1,s1,a0
    800038d0:	0504a983          	lw	s3,80(s1)
    800038d4:	fe0990e3          	bnez	s3,800038b4 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800038d8:	4108                	lw	a0,0(a0)
    800038da:	00000097          	auipc	ra,0x0
    800038de:	e4a080e7          	jalr	-438(ra) # 80003724 <balloc>
    800038e2:	0005099b          	sext.w	s3,a0
    800038e6:	0534a823          	sw	s3,80(s1)
    800038ea:	b7e9                	j	800038b4 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800038ec:	4108                	lw	a0,0(a0)
    800038ee:	00000097          	auipc	ra,0x0
    800038f2:	e36080e7          	jalr	-458(ra) # 80003724 <balloc>
    800038f6:	0005059b          	sext.w	a1,a0
    800038fa:	08b92023          	sw	a1,128(s2)
    800038fe:	b759                	j	80003884 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003900:	00092503          	lw	a0,0(s2)
    80003904:	00000097          	auipc	ra,0x0
    80003908:	e20080e7          	jalr	-480(ra) # 80003724 <balloc>
    8000390c:	0005099b          	sext.w	s3,a0
    80003910:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003914:	8552                	mv	a0,s4
    80003916:	00001097          	auipc	ra,0x1
    8000391a:	ef8080e7          	jalr	-264(ra) # 8000480e <log_write>
    8000391e:	b771                	j	800038aa <bmap+0x54>
  panic("bmap: out of range");
    80003920:	00005517          	auipc	a0,0x5
    80003924:	cd850513          	addi	a0,a0,-808 # 800085f8 <syscalls+0x128>
    80003928:	ffffd097          	auipc	ra,0xffffd
    8000392c:	c16080e7          	jalr	-1002(ra) # 8000053e <panic>

0000000080003930 <iget>:
{
    80003930:	7179                	addi	sp,sp,-48
    80003932:	f406                	sd	ra,40(sp)
    80003934:	f022                	sd	s0,32(sp)
    80003936:	ec26                	sd	s1,24(sp)
    80003938:	e84a                	sd	s2,16(sp)
    8000393a:	e44e                	sd	s3,8(sp)
    8000393c:	e052                	sd	s4,0(sp)
    8000393e:	1800                	addi	s0,sp,48
    80003940:	89aa                	mv	s3,a0
    80003942:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003944:	0001d517          	auipc	a0,0x1d
    80003948:	9c450513          	addi	a0,a0,-1596 # 80020308 <itable>
    8000394c:	ffffd097          	auipc	ra,0xffffd
    80003950:	298080e7          	jalr	664(ra) # 80000be4 <acquire>
  empty = 0;
    80003954:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003956:	0001d497          	auipc	s1,0x1d
    8000395a:	9ca48493          	addi	s1,s1,-1590 # 80020320 <itable+0x18>
    8000395e:	0001e697          	auipc	a3,0x1e
    80003962:	45268693          	addi	a3,a3,1106 # 80021db0 <log>
    80003966:	a039                	j	80003974 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003968:	02090b63          	beqz	s2,8000399e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000396c:	08848493          	addi	s1,s1,136
    80003970:	02d48a63          	beq	s1,a3,800039a4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003974:	449c                	lw	a5,8(s1)
    80003976:	fef059e3          	blez	a5,80003968 <iget+0x38>
    8000397a:	4098                	lw	a4,0(s1)
    8000397c:	ff3716e3          	bne	a4,s3,80003968 <iget+0x38>
    80003980:	40d8                	lw	a4,4(s1)
    80003982:	ff4713e3          	bne	a4,s4,80003968 <iget+0x38>
      ip->ref++;
    80003986:	2785                	addiw	a5,a5,1
    80003988:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000398a:	0001d517          	auipc	a0,0x1d
    8000398e:	97e50513          	addi	a0,a0,-1666 # 80020308 <itable>
    80003992:	ffffd097          	auipc	ra,0xffffd
    80003996:	306080e7          	jalr	774(ra) # 80000c98 <release>
      return ip;
    8000399a:	8926                	mv	s2,s1
    8000399c:	a03d                	j	800039ca <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000399e:	f7f9                	bnez	a5,8000396c <iget+0x3c>
    800039a0:	8926                	mv	s2,s1
    800039a2:	b7e9                	j	8000396c <iget+0x3c>
  if(empty == 0)
    800039a4:	02090c63          	beqz	s2,800039dc <iget+0xac>
  ip->dev = dev;
    800039a8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800039ac:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800039b0:	4785                	li	a5,1
    800039b2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800039b6:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800039ba:	0001d517          	auipc	a0,0x1d
    800039be:	94e50513          	addi	a0,a0,-1714 # 80020308 <itable>
    800039c2:	ffffd097          	auipc	ra,0xffffd
    800039c6:	2d6080e7          	jalr	726(ra) # 80000c98 <release>
}
    800039ca:	854a                	mv	a0,s2
    800039cc:	70a2                	ld	ra,40(sp)
    800039ce:	7402                	ld	s0,32(sp)
    800039d0:	64e2                	ld	s1,24(sp)
    800039d2:	6942                	ld	s2,16(sp)
    800039d4:	69a2                	ld	s3,8(sp)
    800039d6:	6a02                	ld	s4,0(sp)
    800039d8:	6145                	addi	sp,sp,48
    800039da:	8082                	ret
    panic("iget: no inodes");
    800039dc:	00005517          	auipc	a0,0x5
    800039e0:	c3450513          	addi	a0,a0,-972 # 80008610 <syscalls+0x140>
    800039e4:	ffffd097          	auipc	ra,0xffffd
    800039e8:	b5a080e7          	jalr	-1190(ra) # 8000053e <panic>

00000000800039ec <fsinit>:
fsinit(int dev) {
    800039ec:	7179                	addi	sp,sp,-48
    800039ee:	f406                	sd	ra,40(sp)
    800039f0:	f022                	sd	s0,32(sp)
    800039f2:	ec26                	sd	s1,24(sp)
    800039f4:	e84a                	sd	s2,16(sp)
    800039f6:	e44e                	sd	s3,8(sp)
    800039f8:	1800                	addi	s0,sp,48
    800039fa:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039fc:	4585                	li	a1,1
    800039fe:	00000097          	auipc	ra,0x0
    80003a02:	a64080e7          	jalr	-1436(ra) # 80003462 <bread>
    80003a06:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a08:	0001d997          	auipc	s3,0x1d
    80003a0c:	8e098993          	addi	s3,s3,-1824 # 800202e8 <sb>
    80003a10:	02000613          	li	a2,32
    80003a14:	05850593          	addi	a1,a0,88
    80003a18:	854e                	mv	a0,s3
    80003a1a:	ffffd097          	auipc	ra,0xffffd
    80003a1e:	326080e7          	jalr	806(ra) # 80000d40 <memmove>
  brelse(bp);
    80003a22:	8526                	mv	a0,s1
    80003a24:	00000097          	auipc	ra,0x0
    80003a28:	b6e080e7          	jalr	-1170(ra) # 80003592 <brelse>
  if(sb.magic != FSMAGIC)
    80003a2c:	0009a703          	lw	a4,0(s3)
    80003a30:	102037b7          	lui	a5,0x10203
    80003a34:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a38:	02f71263          	bne	a4,a5,80003a5c <fsinit+0x70>
  initlog(dev, &sb);
    80003a3c:	0001d597          	auipc	a1,0x1d
    80003a40:	8ac58593          	addi	a1,a1,-1876 # 800202e8 <sb>
    80003a44:	854a                	mv	a0,s2
    80003a46:	00001097          	auipc	ra,0x1
    80003a4a:	b4c080e7          	jalr	-1204(ra) # 80004592 <initlog>
}
    80003a4e:	70a2                	ld	ra,40(sp)
    80003a50:	7402                	ld	s0,32(sp)
    80003a52:	64e2                	ld	s1,24(sp)
    80003a54:	6942                	ld	s2,16(sp)
    80003a56:	69a2                	ld	s3,8(sp)
    80003a58:	6145                	addi	sp,sp,48
    80003a5a:	8082                	ret
    panic("invalid file system");
    80003a5c:	00005517          	auipc	a0,0x5
    80003a60:	bc450513          	addi	a0,a0,-1084 # 80008620 <syscalls+0x150>
    80003a64:	ffffd097          	auipc	ra,0xffffd
    80003a68:	ada080e7          	jalr	-1318(ra) # 8000053e <panic>

0000000080003a6c <iinit>:
{
    80003a6c:	7179                	addi	sp,sp,-48
    80003a6e:	f406                	sd	ra,40(sp)
    80003a70:	f022                	sd	s0,32(sp)
    80003a72:	ec26                	sd	s1,24(sp)
    80003a74:	e84a                	sd	s2,16(sp)
    80003a76:	e44e                	sd	s3,8(sp)
    80003a78:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a7a:	00005597          	auipc	a1,0x5
    80003a7e:	bbe58593          	addi	a1,a1,-1090 # 80008638 <syscalls+0x168>
    80003a82:	0001d517          	auipc	a0,0x1d
    80003a86:	88650513          	addi	a0,a0,-1914 # 80020308 <itable>
    80003a8a:	ffffd097          	auipc	ra,0xffffd
    80003a8e:	0ca080e7          	jalr	202(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a92:	0001d497          	auipc	s1,0x1d
    80003a96:	89e48493          	addi	s1,s1,-1890 # 80020330 <itable+0x28>
    80003a9a:	0001e997          	auipc	s3,0x1e
    80003a9e:	32698993          	addi	s3,s3,806 # 80021dc0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003aa2:	00005917          	auipc	s2,0x5
    80003aa6:	b9e90913          	addi	s2,s2,-1122 # 80008640 <syscalls+0x170>
    80003aaa:	85ca                	mv	a1,s2
    80003aac:	8526                	mv	a0,s1
    80003aae:	00001097          	auipc	ra,0x1
    80003ab2:	e46080e7          	jalr	-442(ra) # 800048f4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003ab6:	08848493          	addi	s1,s1,136
    80003aba:	ff3498e3          	bne	s1,s3,80003aaa <iinit+0x3e>
}
    80003abe:	70a2                	ld	ra,40(sp)
    80003ac0:	7402                	ld	s0,32(sp)
    80003ac2:	64e2                	ld	s1,24(sp)
    80003ac4:	6942                	ld	s2,16(sp)
    80003ac6:	69a2                	ld	s3,8(sp)
    80003ac8:	6145                	addi	sp,sp,48
    80003aca:	8082                	ret

0000000080003acc <ialloc>:
{
    80003acc:	715d                	addi	sp,sp,-80
    80003ace:	e486                	sd	ra,72(sp)
    80003ad0:	e0a2                	sd	s0,64(sp)
    80003ad2:	fc26                	sd	s1,56(sp)
    80003ad4:	f84a                	sd	s2,48(sp)
    80003ad6:	f44e                	sd	s3,40(sp)
    80003ad8:	f052                	sd	s4,32(sp)
    80003ada:	ec56                	sd	s5,24(sp)
    80003adc:	e85a                	sd	s6,16(sp)
    80003ade:	e45e                	sd	s7,8(sp)
    80003ae0:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ae2:	0001d717          	auipc	a4,0x1d
    80003ae6:	81272703          	lw	a4,-2030(a4) # 800202f4 <sb+0xc>
    80003aea:	4785                	li	a5,1
    80003aec:	04e7fa63          	bgeu	a5,a4,80003b40 <ialloc+0x74>
    80003af0:	8aaa                	mv	s5,a0
    80003af2:	8bae                	mv	s7,a1
    80003af4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003af6:	0001ca17          	auipc	s4,0x1c
    80003afa:	7f2a0a13          	addi	s4,s4,2034 # 800202e8 <sb>
    80003afe:	00048b1b          	sext.w	s6,s1
    80003b02:	0044d593          	srli	a1,s1,0x4
    80003b06:	018a2783          	lw	a5,24(s4)
    80003b0a:	9dbd                	addw	a1,a1,a5
    80003b0c:	8556                	mv	a0,s5
    80003b0e:	00000097          	auipc	ra,0x0
    80003b12:	954080e7          	jalr	-1708(ra) # 80003462 <bread>
    80003b16:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b18:	05850993          	addi	s3,a0,88
    80003b1c:	00f4f793          	andi	a5,s1,15
    80003b20:	079a                	slli	a5,a5,0x6
    80003b22:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b24:	00099783          	lh	a5,0(s3)
    80003b28:	c785                	beqz	a5,80003b50 <ialloc+0x84>
    brelse(bp);
    80003b2a:	00000097          	auipc	ra,0x0
    80003b2e:	a68080e7          	jalr	-1432(ra) # 80003592 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b32:	0485                	addi	s1,s1,1
    80003b34:	00ca2703          	lw	a4,12(s4)
    80003b38:	0004879b          	sext.w	a5,s1
    80003b3c:	fce7e1e3          	bltu	a5,a4,80003afe <ialloc+0x32>
  panic("ialloc: no inodes");
    80003b40:	00005517          	auipc	a0,0x5
    80003b44:	b0850513          	addi	a0,a0,-1272 # 80008648 <syscalls+0x178>
    80003b48:	ffffd097          	auipc	ra,0xffffd
    80003b4c:	9f6080e7          	jalr	-1546(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003b50:	04000613          	li	a2,64
    80003b54:	4581                	li	a1,0
    80003b56:	854e                	mv	a0,s3
    80003b58:	ffffd097          	auipc	ra,0xffffd
    80003b5c:	188080e7          	jalr	392(ra) # 80000ce0 <memset>
      dip->type = type;
    80003b60:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b64:	854a                	mv	a0,s2
    80003b66:	00001097          	auipc	ra,0x1
    80003b6a:	ca8080e7          	jalr	-856(ra) # 8000480e <log_write>
      brelse(bp);
    80003b6e:	854a                	mv	a0,s2
    80003b70:	00000097          	auipc	ra,0x0
    80003b74:	a22080e7          	jalr	-1502(ra) # 80003592 <brelse>
      return iget(dev, inum);
    80003b78:	85da                	mv	a1,s6
    80003b7a:	8556                	mv	a0,s5
    80003b7c:	00000097          	auipc	ra,0x0
    80003b80:	db4080e7          	jalr	-588(ra) # 80003930 <iget>
}
    80003b84:	60a6                	ld	ra,72(sp)
    80003b86:	6406                	ld	s0,64(sp)
    80003b88:	74e2                	ld	s1,56(sp)
    80003b8a:	7942                	ld	s2,48(sp)
    80003b8c:	79a2                	ld	s3,40(sp)
    80003b8e:	7a02                	ld	s4,32(sp)
    80003b90:	6ae2                	ld	s5,24(sp)
    80003b92:	6b42                	ld	s6,16(sp)
    80003b94:	6ba2                	ld	s7,8(sp)
    80003b96:	6161                	addi	sp,sp,80
    80003b98:	8082                	ret

0000000080003b9a <iupdate>:
{
    80003b9a:	1101                	addi	sp,sp,-32
    80003b9c:	ec06                	sd	ra,24(sp)
    80003b9e:	e822                	sd	s0,16(sp)
    80003ba0:	e426                	sd	s1,8(sp)
    80003ba2:	e04a                	sd	s2,0(sp)
    80003ba4:	1000                	addi	s0,sp,32
    80003ba6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ba8:	415c                	lw	a5,4(a0)
    80003baa:	0047d79b          	srliw	a5,a5,0x4
    80003bae:	0001c597          	auipc	a1,0x1c
    80003bb2:	7525a583          	lw	a1,1874(a1) # 80020300 <sb+0x18>
    80003bb6:	9dbd                	addw	a1,a1,a5
    80003bb8:	4108                	lw	a0,0(a0)
    80003bba:	00000097          	auipc	ra,0x0
    80003bbe:	8a8080e7          	jalr	-1880(ra) # 80003462 <bread>
    80003bc2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bc4:	05850793          	addi	a5,a0,88
    80003bc8:	40c8                	lw	a0,4(s1)
    80003bca:	893d                	andi	a0,a0,15
    80003bcc:	051a                	slli	a0,a0,0x6
    80003bce:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003bd0:	04449703          	lh	a4,68(s1)
    80003bd4:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003bd8:	04649703          	lh	a4,70(s1)
    80003bdc:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003be0:	04849703          	lh	a4,72(s1)
    80003be4:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003be8:	04a49703          	lh	a4,74(s1)
    80003bec:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003bf0:	44f8                	lw	a4,76(s1)
    80003bf2:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003bf4:	03400613          	li	a2,52
    80003bf8:	05048593          	addi	a1,s1,80
    80003bfc:	0531                	addi	a0,a0,12
    80003bfe:	ffffd097          	auipc	ra,0xffffd
    80003c02:	142080e7          	jalr	322(ra) # 80000d40 <memmove>
  log_write(bp);
    80003c06:	854a                	mv	a0,s2
    80003c08:	00001097          	auipc	ra,0x1
    80003c0c:	c06080e7          	jalr	-1018(ra) # 8000480e <log_write>
  brelse(bp);
    80003c10:	854a                	mv	a0,s2
    80003c12:	00000097          	auipc	ra,0x0
    80003c16:	980080e7          	jalr	-1664(ra) # 80003592 <brelse>
}
    80003c1a:	60e2                	ld	ra,24(sp)
    80003c1c:	6442                	ld	s0,16(sp)
    80003c1e:	64a2                	ld	s1,8(sp)
    80003c20:	6902                	ld	s2,0(sp)
    80003c22:	6105                	addi	sp,sp,32
    80003c24:	8082                	ret

0000000080003c26 <idup>:
{
    80003c26:	1101                	addi	sp,sp,-32
    80003c28:	ec06                	sd	ra,24(sp)
    80003c2a:	e822                	sd	s0,16(sp)
    80003c2c:	e426                	sd	s1,8(sp)
    80003c2e:	1000                	addi	s0,sp,32
    80003c30:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c32:	0001c517          	auipc	a0,0x1c
    80003c36:	6d650513          	addi	a0,a0,1750 # 80020308 <itable>
    80003c3a:	ffffd097          	auipc	ra,0xffffd
    80003c3e:	faa080e7          	jalr	-86(ra) # 80000be4 <acquire>
  ip->ref++;
    80003c42:	449c                	lw	a5,8(s1)
    80003c44:	2785                	addiw	a5,a5,1
    80003c46:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c48:	0001c517          	auipc	a0,0x1c
    80003c4c:	6c050513          	addi	a0,a0,1728 # 80020308 <itable>
    80003c50:	ffffd097          	auipc	ra,0xffffd
    80003c54:	048080e7          	jalr	72(ra) # 80000c98 <release>
}
    80003c58:	8526                	mv	a0,s1
    80003c5a:	60e2                	ld	ra,24(sp)
    80003c5c:	6442                	ld	s0,16(sp)
    80003c5e:	64a2                	ld	s1,8(sp)
    80003c60:	6105                	addi	sp,sp,32
    80003c62:	8082                	ret

0000000080003c64 <ilock>:
{
    80003c64:	1101                	addi	sp,sp,-32
    80003c66:	ec06                	sd	ra,24(sp)
    80003c68:	e822                	sd	s0,16(sp)
    80003c6a:	e426                	sd	s1,8(sp)
    80003c6c:	e04a                	sd	s2,0(sp)
    80003c6e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c70:	c115                	beqz	a0,80003c94 <ilock+0x30>
    80003c72:	84aa                	mv	s1,a0
    80003c74:	451c                	lw	a5,8(a0)
    80003c76:	00f05f63          	blez	a5,80003c94 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c7a:	0541                	addi	a0,a0,16
    80003c7c:	00001097          	auipc	ra,0x1
    80003c80:	cb2080e7          	jalr	-846(ra) # 8000492e <acquiresleep>
  if(ip->valid == 0){
    80003c84:	40bc                	lw	a5,64(s1)
    80003c86:	cf99                	beqz	a5,80003ca4 <ilock+0x40>
}
    80003c88:	60e2                	ld	ra,24(sp)
    80003c8a:	6442                	ld	s0,16(sp)
    80003c8c:	64a2                	ld	s1,8(sp)
    80003c8e:	6902                	ld	s2,0(sp)
    80003c90:	6105                	addi	sp,sp,32
    80003c92:	8082                	ret
    panic("ilock");
    80003c94:	00005517          	auipc	a0,0x5
    80003c98:	9cc50513          	addi	a0,a0,-1588 # 80008660 <syscalls+0x190>
    80003c9c:	ffffd097          	auipc	ra,0xffffd
    80003ca0:	8a2080e7          	jalr	-1886(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ca4:	40dc                	lw	a5,4(s1)
    80003ca6:	0047d79b          	srliw	a5,a5,0x4
    80003caa:	0001c597          	auipc	a1,0x1c
    80003cae:	6565a583          	lw	a1,1622(a1) # 80020300 <sb+0x18>
    80003cb2:	9dbd                	addw	a1,a1,a5
    80003cb4:	4088                	lw	a0,0(s1)
    80003cb6:	fffff097          	auipc	ra,0xfffff
    80003cba:	7ac080e7          	jalr	1964(ra) # 80003462 <bread>
    80003cbe:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cc0:	05850593          	addi	a1,a0,88
    80003cc4:	40dc                	lw	a5,4(s1)
    80003cc6:	8bbd                	andi	a5,a5,15
    80003cc8:	079a                	slli	a5,a5,0x6
    80003cca:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ccc:	00059783          	lh	a5,0(a1)
    80003cd0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003cd4:	00259783          	lh	a5,2(a1)
    80003cd8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003cdc:	00459783          	lh	a5,4(a1)
    80003ce0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ce4:	00659783          	lh	a5,6(a1)
    80003ce8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003cec:	459c                	lw	a5,8(a1)
    80003cee:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003cf0:	03400613          	li	a2,52
    80003cf4:	05b1                	addi	a1,a1,12
    80003cf6:	05048513          	addi	a0,s1,80
    80003cfa:	ffffd097          	auipc	ra,0xffffd
    80003cfe:	046080e7          	jalr	70(ra) # 80000d40 <memmove>
    brelse(bp);
    80003d02:	854a                	mv	a0,s2
    80003d04:	00000097          	auipc	ra,0x0
    80003d08:	88e080e7          	jalr	-1906(ra) # 80003592 <brelse>
    ip->valid = 1;
    80003d0c:	4785                	li	a5,1
    80003d0e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d10:	04449783          	lh	a5,68(s1)
    80003d14:	fbb5                	bnez	a5,80003c88 <ilock+0x24>
      panic("ilock: no type");
    80003d16:	00005517          	auipc	a0,0x5
    80003d1a:	95250513          	addi	a0,a0,-1710 # 80008668 <syscalls+0x198>
    80003d1e:	ffffd097          	auipc	ra,0xffffd
    80003d22:	820080e7          	jalr	-2016(ra) # 8000053e <panic>

0000000080003d26 <iunlock>:
{
    80003d26:	1101                	addi	sp,sp,-32
    80003d28:	ec06                	sd	ra,24(sp)
    80003d2a:	e822                	sd	s0,16(sp)
    80003d2c:	e426                	sd	s1,8(sp)
    80003d2e:	e04a                	sd	s2,0(sp)
    80003d30:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d32:	c905                	beqz	a0,80003d62 <iunlock+0x3c>
    80003d34:	84aa                	mv	s1,a0
    80003d36:	01050913          	addi	s2,a0,16
    80003d3a:	854a                	mv	a0,s2
    80003d3c:	00001097          	auipc	ra,0x1
    80003d40:	c8c080e7          	jalr	-884(ra) # 800049c8 <holdingsleep>
    80003d44:	cd19                	beqz	a0,80003d62 <iunlock+0x3c>
    80003d46:	449c                	lw	a5,8(s1)
    80003d48:	00f05d63          	blez	a5,80003d62 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d4c:	854a                	mv	a0,s2
    80003d4e:	00001097          	auipc	ra,0x1
    80003d52:	c36080e7          	jalr	-970(ra) # 80004984 <releasesleep>
}
    80003d56:	60e2                	ld	ra,24(sp)
    80003d58:	6442                	ld	s0,16(sp)
    80003d5a:	64a2                	ld	s1,8(sp)
    80003d5c:	6902                	ld	s2,0(sp)
    80003d5e:	6105                	addi	sp,sp,32
    80003d60:	8082                	ret
    panic("iunlock");
    80003d62:	00005517          	auipc	a0,0x5
    80003d66:	91650513          	addi	a0,a0,-1770 # 80008678 <syscalls+0x1a8>
    80003d6a:	ffffc097          	auipc	ra,0xffffc
    80003d6e:	7d4080e7          	jalr	2004(ra) # 8000053e <panic>

0000000080003d72 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d72:	7179                	addi	sp,sp,-48
    80003d74:	f406                	sd	ra,40(sp)
    80003d76:	f022                	sd	s0,32(sp)
    80003d78:	ec26                	sd	s1,24(sp)
    80003d7a:	e84a                	sd	s2,16(sp)
    80003d7c:	e44e                	sd	s3,8(sp)
    80003d7e:	e052                	sd	s4,0(sp)
    80003d80:	1800                	addi	s0,sp,48
    80003d82:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d84:	05050493          	addi	s1,a0,80
    80003d88:	08050913          	addi	s2,a0,128
    80003d8c:	a021                	j	80003d94 <itrunc+0x22>
    80003d8e:	0491                	addi	s1,s1,4
    80003d90:	01248d63          	beq	s1,s2,80003daa <itrunc+0x38>
    if(ip->addrs[i]){
    80003d94:	408c                	lw	a1,0(s1)
    80003d96:	dde5                	beqz	a1,80003d8e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d98:	0009a503          	lw	a0,0(s3)
    80003d9c:	00000097          	auipc	ra,0x0
    80003da0:	90c080e7          	jalr	-1780(ra) # 800036a8 <bfree>
      ip->addrs[i] = 0;
    80003da4:	0004a023          	sw	zero,0(s1)
    80003da8:	b7dd                	j	80003d8e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003daa:	0809a583          	lw	a1,128(s3)
    80003dae:	e185                	bnez	a1,80003dce <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003db0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003db4:	854e                	mv	a0,s3
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	de4080e7          	jalr	-540(ra) # 80003b9a <iupdate>
}
    80003dbe:	70a2                	ld	ra,40(sp)
    80003dc0:	7402                	ld	s0,32(sp)
    80003dc2:	64e2                	ld	s1,24(sp)
    80003dc4:	6942                	ld	s2,16(sp)
    80003dc6:	69a2                	ld	s3,8(sp)
    80003dc8:	6a02                	ld	s4,0(sp)
    80003dca:	6145                	addi	sp,sp,48
    80003dcc:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003dce:	0009a503          	lw	a0,0(s3)
    80003dd2:	fffff097          	auipc	ra,0xfffff
    80003dd6:	690080e7          	jalr	1680(ra) # 80003462 <bread>
    80003dda:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ddc:	05850493          	addi	s1,a0,88
    80003de0:	45850913          	addi	s2,a0,1112
    80003de4:	a811                	j	80003df8 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003de6:	0009a503          	lw	a0,0(s3)
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	8be080e7          	jalr	-1858(ra) # 800036a8 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003df2:	0491                	addi	s1,s1,4
    80003df4:	01248563          	beq	s1,s2,80003dfe <itrunc+0x8c>
      if(a[j])
    80003df8:	408c                	lw	a1,0(s1)
    80003dfa:	dde5                	beqz	a1,80003df2 <itrunc+0x80>
    80003dfc:	b7ed                	j	80003de6 <itrunc+0x74>
    brelse(bp);
    80003dfe:	8552                	mv	a0,s4
    80003e00:	fffff097          	auipc	ra,0xfffff
    80003e04:	792080e7          	jalr	1938(ra) # 80003592 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e08:	0809a583          	lw	a1,128(s3)
    80003e0c:	0009a503          	lw	a0,0(s3)
    80003e10:	00000097          	auipc	ra,0x0
    80003e14:	898080e7          	jalr	-1896(ra) # 800036a8 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e18:	0809a023          	sw	zero,128(s3)
    80003e1c:	bf51                	j	80003db0 <itrunc+0x3e>

0000000080003e1e <iput>:
{
    80003e1e:	1101                	addi	sp,sp,-32
    80003e20:	ec06                	sd	ra,24(sp)
    80003e22:	e822                	sd	s0,16(sp)
    80003e24:	e426                	sd	s1,8(sp)
    80003e26:	e04a                	sd	s2,0(sp)
    80003e28:	1000                	addi	s0,sp,32
    80003e2a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e2c:	0001c517          	auipc	a0,0x1c
    80003e30:	4dc50513          	addi	a0,a0,1244 # 80020308 <itable>
    80003e34:	ffffd097          	auipc	ra,0xffffd
    80003e38:	db0080e7          	jalr	-592(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e3c:	4498                	lw	a4,8(s1)
    80003e3e:	4785                	li	a5,1
    80003e40:	02f70363          	beq	a4,a5,80003e66 <iput+0x48>
  ip->ref--;
    80003e44:	449c                	lw	a5,8(s1)
    80003e46:	37fd                	addiw	a5,a5,-1
    80003e48:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e4a:	0001c517          	auipc	a0,0x1c
    80003e4e:	4be50513          	addi	a0,a0,1214 # 80020308 <itable>
    80003e52:	ffffd097          	auipc	ra,0xffffd
    80003e56:	e46080e7          	jalr	-442(ra) # 80000c98 <release>
}
    80003e5a:	60e2                	ld	ra,24(sp)
    80003e5c:	6442                	ld	s0,16(sp)
    80003e5e:	64a2                	ld	s1,8(sp)
    80003e60:	6902                	ld	s2,0(sp)
    80003e62:	6105                	addi	sp,sp,32
    80003e64:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e66:	40bc                	lw	a5,64(s1)
    80003e68:	dff1                	beqz	a5,80003e44 <iput+0x26>
    80003e6a:	04a49783          	lh	a5,74(s1)
    80003e6e:	fbf9                	bnez	a5,80003e44 <iput+0x26>
    acquiresleep(&ip->lock);
    80003e70:	01048913          	addi	s2,s1,16
    80003e74:	854a                	mv	a0,s2
    80003e76:	00001097          	auipc	ra,0x1
    80003e7a:	ab8080e7          	jalr	-1352(ra) # 8000492e <acquiresleep>
    release(&itable.lock);
    80003e7e:	0001c517          	auipc	a0,0x1c
    80003e82:	48a50513          	addi	a0,a0,1162 # 80020308 <itable>
    80003e86:	ffffd097          	auipc	ra,0xffffd
    80003e8a:	e12080e7          	jalr	-494(ra) # 80000c98 <release>
    itrunc(ip);
    80003e8e:	8526                	mv	a0,s1
    80003e90:	00000097          	auipc	ra,0x0
    80003e94:	ee2080e7          	jalr	-286(ra) # 80003d72 <itrunc>
    ip->type = 0;
    80003e98:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e9c:	8526                	mv	a0,s1
    80003e9e:	00000097          	auipc	ra,0x0
    80003ea2:	cfc080e7          	jalr	-772(ra) # 80003b9a <iupdate>
    ip->valid = 0;
    80003ea6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003eaa:	854a                	mv	a0,s2
    80003eac:	00001097          	auipc	ra,0x1
    80003eb0:	ad8080e7          	jalr	-1320(ra) # 80004984 <releasesleep>
    acquire(&itable.lock);
    80003eb4:	0001c517          	auipc	a0,0x1c
    80003eb8:	45450513          	addi	a0,a0,1108 # 80020308 <itable>
    80003ebc:	ffffd097          	auipc	ra,0xffffd
    80003ec0:	d28080e7          	jalr	-728(ra) # 80000be4 <acquire>
    80003ec4:	b741                	j	80003e44 <iput+0x26>

0000000080003ec6 <iunlockput>:
{
    80003ec6:	1101                	addi	sp,sp,-32
    80003ec8:	ec06                	sd	ra,24(sp)
    80003eca:	e822                	sd	s0,16(sp)
    80003ecc:	e426                	sd	s1,8(sp)
    80003ece:	1000                	addi	s0,sp,32
    80003ed0:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ed2:	00000097          	auipc	ra,0x0
    80003ed6:	e54080e7          	jalr	-428(ra) # 80003d26 <iunlock>
  iput(ip);
    80003eda:	8526                	mv	a0,s1
    80003edc:	00000097          	auipc	ra,0x0
    80003ee0:	f42080e7          	jalr	-190(ra) # 80003e1e <iput>
}
    80003ee4:	60e2                	ld	ra,24(sp)
    80003ee6:	6442                	ld	s0,16(sp)
    80003ee8:	64a2                	ld	s1,8(sp)
    80003eea:	6105                	addi	sp,sp,32
    80003eec:	8082                	ret

0000000080003eee <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003eee:	1141                	addi	sp,sp,-16
    80003ef0:	e422                	sd	s0,8(sp)
    80003ef2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ef4:	411c                	lw	a5,0(a0)
    80003ef6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ef8:	415c                	lw	a5,4(a0)
    80003efa:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003efc:	04451783          	lh	a5,68(a0)
    80003f00:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f04:	04a51783          	lh	a5,74(a0)
    80003f08:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f0c:	04c56783          	lwu	a5,76(a0)
    80003f10:	e99c                	sd	a5,16(a1)
}
    80003f12:	6422                	ld	s0,8(sp)
    80003f14:	0141                	addi	sp,sp,16
    80003f16:	8082                	ret

0000000080003f18 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f18:	457c                	lw	a5,76(a0)
    80003f1a:	0ed7e963          	bltu	a5,a3,8000400c <readi+0xf4>
{
    80003f1e:	7159                	addi	sp,sp,-112
    80003f20:	f486                	sd	ra,104(sp)
    80003f22:	f0a2                	sd	s0,96(sp)
    80003f24:	eca6                	sd	s1,88(sp)
    80003f26:	e8ca                	sd	s2,80(sp)
    80003f28:	e4ce                	sd	s3,72(sp)
    80003f2a:	e0d2                	sd	s4,64(sp)
    80003f2c:	fc56                	sd	s5,56(sp)
    80003f2e:	f85a                	sd	s6,48(sp)
    80003f30:	f45e                	sd	s7,40(sp)
    80003f32:	f062                	sd	s8,32(sp)
    80003f34:	ec66                	sd	s9,24(sp)
    80003f36:	e86a                	sd	s10,16(sp)
    80003f38:	e46e                	sd	s11,8(sp)
    80003f3a:	1880                	addi	s0,sp,112
    80003f3c:	8baa                	mv	s7,a0
    80003f3e:	8c2e                	mv	s8,a1
    80003f40:	8ab2                	mv	s5,a2
    80003f42:	84b6                	mv	s1,a3
    80003f44:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f46:	9f35                	addw	a4,a4,a3
    return 0;
    80003f48:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f4a:	0ad76063          	bltu	a4,a3,80003fea <readi+0xd2>
  if(off + n > ip->size)
    80003f4e:	00e7f463          	bgeu	a5,a4,80003f56 <readi+0x3e>
    n = ip->size - off;
    80003f52:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f56:	0a0b0963          	beqz	s6,80004008 <readi+0xf0>
    80003f5a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f5c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f60:	5cfd                	li	s9,-1
    80003f62:	a82d                	j	80003f9c <readi+0x84>
    80003f64:	020a1d93          	slli	s11,s4,0x20
    80003f68:	020ddd93          	srli	s11,s11,0x20
    80003f6c:	05890613          	addi	a2,s2,88
    80003f70:	86ee                	mv	a3,s11
    80003f72:	963a                	add	a2,a2,a4
    80003f74:	85d6                	mv	a1,s5
    80003f76:	8562                	mv	a0,s8
    80003f78:	fffff097          	auipc	ra,0xfffff
    80003f7c:	a72080e7          	jalr	-1422(ra) # 800029ea <either_copyout>
    80003f80:	05950d63          	beq	a0,s9,80003fda <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f84:	854a                	mv	a0,s2
    80003f86:	fffff097          	auipc	ra,0xfffff
    80003f8a:	60c080e7          	jalr	1548(ra) # 80003592 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f8e:	013a09bb          	addw	s3,s4,s3
    80003f92:	009a04bb          	addw	s1,s4,s1
    80003f96:	9aee                	add	s5,s5,s11
    80003f98:	0569f763          	bgeu	s3,s6,80003fe6 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f9c:	000ba903          	lw	s2,0(s7)
    80003fa0:	00a4d59b          	srliw	a1,s1,0xa
    80003fa4:	855e                	mv	a0,s7
    80003fa6:	00000097          	auipc	ra,0x0
    80003faa:	8b0080e7          	jalr	-1872(ra) # 80003856 <bmap>
    80003fae:	0005059b          	sext.w	a1,a0
    80003fb2:	854a                	mv	a0,s2
    80003fb4:	fffff097          	auipc	ra,0xfffff
    80003fb8:	4ae080e7          	jalr	1198(ra) # 80003462 <bread>
    80003fbc:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fbe:	3ff4f713          	andi	a4,s1,1023
    80003fc2:	40ed07bb          	subw	a5,s10,a4
    80003fc6:	413b06bb          	subw	a3,s6,s3
    80003fca:	8a3e                	mv	s4,a5
    80003fcc:	2781                	sext.w	a5,a5
    80003fce:	0006861b          	sext.w	a2,a3
    80003fd2:	f8f679e3          	bgeu	a2,a5,80003f64 <readi+0x4c>
    80003fd6:	8a36                	mv	s4,a3
    80003fd8:	b771                	j	80003f64 <readi+0x4c>
      brelse(bp);
    80003fda:	854a                	mv	a0,s2
    80003fdc:	fffff097          	auipc	ra,0xfffff
    80003fe0:	5b6080e7          	jalr	1462(ra) # 80003592 <brelse>
      tot = -1;
    80003fe4:	59fd                	li	s3,-1
  }
  return tot;
    80003fe6:	0009851b          	sext.w	a0,s3
}
    80003fea:	70a6                	ld	ra,104(sp)
    80003fec:	7406                	ld	s0,96(sp)
    80003fee:	64e6                	ld	s1,88(sp)
    80003ff0:	6946                	ld	s2,80(sp)
    80003ff2:	69a6                	ld	s3,72(sp)
    80003ff4:	6a06                	ld	s4,64(sp)
    80003ff6:	7ae2                	ld	s5,56(sp)
    80003ff8:	7b42                	ld	s6,48(sp)
    80003ffa:	7ba2                	ld	s7,40(sp)
    80003ffc:	7c02                	ld	s8,32(sp)
    80003ffe:	6ce2                	ld	s9,24(sp)
    80004000:	6d42                	ld	s10,16(sp)
    80004002:	6da2                	ld	s11,8(sp)
    80004004:	6165                	addi	sp,sp,112
    80004006:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004008:	89da                	mv	s3,s6
    8000400a:	bff1                	j	80003fe6 <readi+0xce>
    return 0;
    8000400c:	4501                	li	a0,0
}
    8000400e:	8082                	ret

0000000080004010 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004010:	457c                	lw	a5,76(a0)
    80004012:	10d7e863          	bltu	a5,a3,80004122 <writei+0x112>
{
    80004016:	7159                	addi	sp,sp,-112
    80004018:	f486                	sd	ra,104(sp)
    8000401a:	f0a2                	sd	s0,96(sp)
    8000401c:	eca6                	sd	s1,88(sp)
    8000401e:	e8ca                	sd	s2,80(sp)
    80004020:	e4ce                	sd	s3,72(sp)
    80004022:	e0d2                	sd	s4,64(sp)
    80004024:	fc56                	sd	s5,56(sp)
    80004026:	f85a                	sd	s6,48(sp)
    80004028:	f45e                	sd	s7,40(sp)
    8000402a:	f062                	sd	s8,32(sp)
    8000402c:	ec66                	sd	s9,24(sp)
    8000402e:	e86a                	sd	s10,16(sp)
    80004030:	e46e                	sd	s11,8(sp)
    80004032:	1880                	addi	s0,sp,112
    80004034:	8b2a                	mv	s6,a0
    80004036:	8c2e                	mv	s8,a1
    80004038:	8ab2                	mv	s5,a2
    8000403a:	8936                	mv	s2,a3
    8000403c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000403e:	00e687bb          	addw	a5,a3,a4
    80004042:	0ed7e263          	bltu	a5,a3,80004126 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004046:	00043737          	lui	a4,0x43
    8000404a:	0ef76063          	bltu	a4,a5,8000412a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000404e:	0c0b8863          	beqz	s7,8000411e <writei+0x10e>
    80004052:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004054:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004058:	5cfd                	li	s9,-1
    8000405a:	a091                	j	8000409e <writei+0x8e>
    8000405c:	02099d93          	slli	s11,s3,0x20
    80004060:	020ddd93          	srli	s11,s11,0x20
    80004064:	05848513          	addi	a0,s1,88
    80004068:	86ee                	mv	a3,s11
    8000406a:	8656                	mv	a2,s5
    8000406c:	85e2                	mv	a1,s8
    8000406e:	953a                	add	a0,a0,a4
    80004070:	fffff097          	auipc	ra,0xfffff
    80004074:	9d0080e7          	jalr	-1584(ra) # 80002a40 <either_copyin>
    80004078:	07950263          	beq	a0,s9,800040dc <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000407c:	8526                	mv	a0,s1
    8000407e:	00000097          	auipc	ra,0x0
    80004082:	790080e7          	jalr	1936(ra) # 8000480e <log_write>
    brelse(bp);
    80004086:	8526                	mv	a0,s1
    80004088:	fffff097          	auipc	ra,0xfffff
    8000408c:	50a080e7          	jalr	1290(ra) # 80003592 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004090:	01498a3b          	addw	s4,s3,s4
    80004094:	0129893b          	addw	s2,s3,s2
    80004098:	9aee                	add	s5,s5,s11
    8000409a:	057a7663          	bgeu	s4,s7,800040e6 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000409e:	000b2483          	lw	s1,0(s6)
    800040a2:	00a9559b          	srliw	a1,s2,0xa
    800040a6:	855a                	mv	a0,s6
    800040a8:	fffff097          	auipc	ra,0xfffff
    800040ac:	7ae080e7          	jalr	1966(ra) # 80003856 <bmap>
    800040b0:	0005059b          	sext.w	a1,a0
    800040b4:	8526                	mv	a0,s1
    800040b6:	fffff097          	auipc	ra,0xfffff
    800040ba:	3ac080e7          	jalr	940(ra) # 80003462 <bread>
    800040be:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040c0:	3ff97713          	andi	a4,s2,1023
    800040c4:	40ed07bb          	subw	a5,s10,a4
    800040c8:	414b86bb          	subw	a3,s7,s4
    800040cc:	89be                	mv	s3,a5
    800040ce:	2781                	sext.w	a5,a5
    800040d0:	0006861b          	sext.w	a2,a3
    800040d4:	f8f674e3          	bgeu	a2,a5,8000405c <writei+0x4c>
    800040d8:	89b6                	mv	s3,a3
    800040da:	b749                	j	8000405c <writei+0x4c>
      brelse(bp);
    800040dc:	8526                	mv	a0,s1
    800040de:	fffff097          	auipc	ra,0xfffff
    800040e2:	4b4080e7          	jalr	1204(ra) # 80003592 <brelse>
  }

  if(off > ip->size)
    800040e6:	04cb2783          	lw	a5,76(s6)
    800040ea:	0127f463          	bgeu	a5,s2,800040f2 <writei+0xe2>
    ip->size = off;
    800040ee:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800040f2:	855a                	mv	a0,s6
    800040f4:	00000097          	auipc	ra,0x0
    800040f8:	aa6080e7          	jalr	-1370(ra) # 80003b9a <iupdate>

  return tot;
    800040fc:	000a051b          	sext.w	a0,s4
}
    80004100:	70a6                	ld	ra,104(sp)
    80004102:	7406                	ld	s0,96(sp)
    80004104:	64e6                	ld	s1,88(sp)
    80004106:	6946                	ld	s2,80(sp)
    80004108:	69a6                	ld	s3,72(sp)
    8000410a:	6a06                	ld	s4,64(sp)
    8000410c:	7ae2                	ld	s5,56(sp)
    8000410e:	7b42                	ld	s6,48(sp)
    80004110:	7ba2                	ld	s7,40(sp)
    80004112:	7c02                	ld	s8,32(sp)
    80004114:	6ce2                	ld	s9,24(sp)
    80004116:	6d42                	ld	s10,16(sp)
    80004118:	6da2                	ld	s11,8(sp)
    8000411a:	6165                	addi	sp,sp,112
    8000411c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000411e:	8a5e                	mv	s4,s7
    80004120:	bfc9                	j	800040f2 <writei+0xe2>
    return -1;
    80004122:	557d                	li	a0,-1
}
    80004124:	8082                	ret
    return -1;
    80004126:	557d                	li	a0,-1
    80004128:	bfe1                	j	80004100 <writei+0xf0>
    return -1;
    8000412a:	557d                	li	a0,-1
    8000412c:	bfd1                	j	80004100 <writei+0xf0>

000000008000412e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000412e:	1141                	addi	sp,sp,-16
    80004130:	e406                	sd	ra,8(sp)
    80004132:	e022                	sd	s0,0(sp)
    80004134:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004136:	4639                	li	a2,14
    80004138:	ffffd097          	auipc	ra,0xffffd
    8000413c:	c80080e7          	jalr	-896(ra) # 80000db8 <strncmp>
}
    80004140:	60a2                	ld	ra,8(sp)
    80004142:	6402                	ld	s0,0(sp)
    80004144:	0141                	addi	sp,sp,16
    80004146:	8082                	ret

0000000080004148 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004148:	7139                	addi	sp,sp,-64
    8000414a:	fc06                	sd	ra,56(sp)
    8000414c:	f822                	sd	s0,48(sp)
    8000414e:	f426                	sd	s1,40(sp)
    80004150:	f04a                	sd	s2,32(sp)
    80004152:	ec4e                	sd	s3,24(sp)
    80004154:	e852                	sd	s4,16(sp)
    80004156:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004158:	04451703          	lh	a4,68(a0)
    8000415c:	4785                	li	a5,1
    8000415e:	00f71a63          	bne	a4,a5,80004172 <dirlookup+0x2a>
    80004162:	892a                	mv	s2,a0
    80004164:	89ae                	mv	s3,a1
    80004166:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004168:	457c                	lw	a5,76(a0)
    8000416a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000416c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000416e:	e79d                	bnez	a5,8000419c <dirlookup+0x54>
    80004170:	a8a5                	j	800041e8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004172:	00004517          	auipc	a0,0x4
    80004176:	50e50513          	addi	a0,a0,1294 # 80008680 <syscalls+0x1b0>
    8000417a:	ffffc097          	auipc	ra,0xffffc
    8000417e:	3c4080e7          	jalr	964(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004182:	00004517          	auipc	a0,0x4
    80004186:	51650513          	addi	a0,a0,1302 # 80008698 <syscalls+0x1c8>
    8000418a:	ffffc097          	auipc	ra,0xffffc
    8000418e:	3b4080e7          	jalr	948(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004192:	24c1                	addiw	s1,s1,16
    80004194:	04c92783          	lw	a5,76(s2)
    80004198:	04f4f763          	bgeu	s1,a5,800041e6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000419c:	4741                	li	a4,16
    8000419e:	86a6                	mv	a3,s1
    800041a0:	fc040613          	addi	a2,s0,-64
    800041a4:	4581                	li	a1,0
    800041a6:	854a                	mv	a0,s2
    800041a8:	00000097          	auipc	ra,0x0
    800041ac:	d70080e7          	jalr	-656(ra) # 80003f18 <readi>
    800041b0:	47c1                	li	a5,16
    800041b2:	fcf518e3          	bne	a0,a5,80004182 <dirlookup+0x3a>
    if(de.inum == 0)
    800041b6:	fc045783          	lhu	a5,-64(s0)
    800041ba:	dfe1                	beqz	a5,80004192 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800041bc:	fc240593          	addi	a1,s0,-62
    800041c0:	854e                	mv	a0,s3
    800041c2:	00000097          	auipc	ra,0x0
    800041c6:	f6c080e7          	jalr	-148(ra) # 8000412e <namecmp>
    800041ca:	f561                	bnez	a0,80004192 <dirlookup+0x4a>
      if(poff)
    800041cc:	000a0463          	beqz	s4,800041d4 <dirlookup+0x8c>
        *poff = off;
    800041d0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041d4:	fc045583          	lhu	a1,-64(s0)
    800041d8:	00092503          	lw	a0,0(s2)
    800041dc:	fffff097          	auipc	ra,0xfffff
    800041e0:	754080e7          	jalr	1876(ra) # 80003930 <iget>
    800041e4:	a011                	j	800041e8 <dirlookup+0xa0>
  return 0;
    800041e6:	4501                	li	a0,0
}
    800041e8:	70e2                	ld	ra,56(sp)
    800041ea:	7442                	ld	s0,48(sp)
    800041ec:	74a2                	ld	s1,40(sp)
    800041ee:	7902                	ld	s2,32(sp)
    800041f0:	69e2                	ld	s3,24(sp)
    800041f2:	6a42                	ld	s4,16(sp)
    800041f4:	6121                	addi	sp,sp,64
    800041f6:	8082                	ret

00000000800041f8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800041f8:	711d                	addi	sp,sp,-96
    800041fa:	ec86                	sd	ra,88(sp)
    800041fc:	e8a2                	sd	s0,80(sp)
    800041fe:	e4a6                	sd	s1,72(sp)
    80004200:	e0ca                	sd	s2,64(sp)
    80004202:	fc4e                	sd	s3,56(sp)
    80004204:	f852                	sd	s4,48(sp)
    80004206:	f456                	sd	s5,40(sp)
    80004208:	f05a                	sd	s6,32(sp)
    8000420a:	ec5e                	sd	s7,24(sp)
    8000420c:	e862                	sd	s8,16(sp)
    8000420e:	e466                	sd	s9,8(sp)
    80004210:	1080                	addi	s0,sp,96
    80004212:	84aa                	mv	s1,a0
    80004214:	8b2e                	mv	s6,a1
    80004216:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004218:	00054703          	lbu	a4,0(a0)
    8000421c:	02f00793          	li	a5,47
    80004220:	02f70363          	beq	a4,a5,80004246 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004224:	ffffe097          	auipc	ra,0xffffe
    80004228:	aac080e7          	jalr	-1364(ra) # 80001cd0 <myproc>
    8000422c:	15053503          	ld	a0,336(a0)
    80004230:	00000097          	auipc	ra,0x0
    80004234:	9f6080e7          	jalr	-1546(ra) # 80003c26 <idup>
    80004238:	89aa                	mv	s3,a0
  while(*path == '/')
    8000423a:	02f00913          	li	s2,47
  len = path - s;
    8000423e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004240:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004242:	4c05                	li	s8,1
    80004244:	a865                	j	800042fc <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004246:	4585                	li	a1,1
    80004248:	4505                	li	a0,1
    8000424a:	fffff097          	auipc	ra,0xfffff
    8000424e:	6e6080e7          	jalr	1766(ra) # 80003930 <iget>
    80004252:	89aa                	mv	s3,a0
    80004254:	b7dd                	j	8000423a <namex+0x42>
      iunlockput(ip);
    80004256:	854e                	mv	a0,s3
    80004258:	00000097          	auipc	ra,0x0
    8000425c:	c6e080e7          	jalr	-914(ra) # 80003ec6 <iunlockput>
      return 0;
    80004260:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004262:	854e                	mv	a0,s3
    80004264:	60e6                	ld	ra,88(sp)
    80004266:	6446                	ld	s0,80(sp)
    80004268:	64a6                	ld	s1,72(sp)
    8000426a:	6906                	ld	s2,64(sp)
    8000426c:	79e2                	ld	s3,56(sp)
    8000426e:	7a42                	ld	s4,48(sp)
    80004270:	7aa2                	ld	s5,40(sp)
    80004272:	7b02                	ld	s6,32(sp)
    80004274:	6be2                	ld	s7,24(sp)
    80004276:	6c42                	ld	s8,16(sp)
    80004278:	6ca2                	ld	s9,8(sp)
    8000427a:	6125                	addi	sp,sp,96
    8000427c:	8082                	ret
      iunlock(ip);
    8000427e:	854e                	mv	a0,s3
    80004280:	00000097          	auipc	ra,0x0
    80004284:	aa6080e7          	jalr	-1370(ra) # 80003d26 <iunlock>
      return ip;
    80004288:	bfe9                	j	80004262 <namex+0x6a>
      iunlockput(ip);
    8000428a:	854e                	mv	a0,s3
    8000428c:	00000097          	auipc	ra,0x0
    80004290:	c3a080e7          	jalr	-966(ra) # 80003ec6 <iunlockput>
      return 0;
    80004294:	89d2                	mv	s3,s4
    80004296:	b7f1                	j	80004262 <namex+0x6a>
  len = path - s;
    80004298:	40b48633          	sub	a2,s1,a1
    8000429c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800042a0:	094cd463          	bge	s9,s4,80004328 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800042a4:	4639                	li	a2,14
    800042a6:	8556                	mv	a0,s5
    800042a8:	ffffd097          	auipc	ra,0xffffd
    800042ac:	a98080e7          	jalr	-1384(ra) # 80000d40 <memmove>
  while(*path == '/')
    800042b0:	0004c783          	lbu	a5,0(s1)
    800042b4:	01279763          	bne	a5,s2,800042c2 <namex+0xca>
    path++;
    800042b8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042ba:	0004c783          	lbu	a5,0(s1)
    800042be:	ff278de3          	beq	a5,s2,800042b8 <namex+0xc0>
    ilock(ip);
    800042c2:	854e                	mv	a0,s3
    800042c4:	00000097          	auipc	ra,0x0
    800042c8:	9a0080e7          	jalr	-1632(ra) # 80003c64 <ilock>
    if(ip->type != T_DIR){
    800042cc:	04499783          	lh	a5,68(s3)
    800042d0:	f98793e3          	bne	a5,s8,80004256 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800042d4:	000b0563          	beqz	s6,800042de <namex+0xe6>
    800042d8:	0004c783          	lbu	a5,0(s1)
    800042dc:	d3cd                	beqz	a5,8000427e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042de:	865e                	mv	a2,s7
    800042e0:	85d6                	mv	a1,s5
    800042e2:	854e                	mv	a0,s3
    800042e4:	00000097          	auipc	ra,0x0
    800042e8:	e64080e7          	jalr	-412(ra) # 80004148 <dirlookup>
    800042ec:	8a2a                	mv	s4,a0
    800042ee:	dd51                	beqz	a0,8000428a <namex+0x92>
    iunlockput(ip);
    800042f0:	854e                	mv	a0,s3
    800042f2:	00000097          	auipc	ra,0x0
    800042f6:	bd4080e7          	jalr	-1068(ra) # 80003ec6 <iunlockput>
    ip = next;
    800042fa:	89d2                	mv	s3,s4
  while(*path == '/')
    800042fc:	0004c783          	lbu	a5,0(s1)
    80004300:	05279763          	bne	a5,s2,8000434e <namex+0x156>
    path++;
    80004304:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004306:	0004c783          	lbu	a5,0(s1)
    8000430a:	ff278de3          	beq	a5,s2,80004304 <namex+0x10c>
  if(*path == 0)
    8000430e:	c79d                	beqz	a5,8000433c <namex+0x144>
    path++;
    80004310:	85a6                	mv	a1,s1
  len = path - s;
    80004312:	8a5e                	mv	s4,s7
    80004314:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004316:	01278963          	beq	a5,s2,80004328 <namex+0x130>
    8000431a:	dfbd                	beqz	a5,80004298 <namex+0xa0>
    path++;
    8000431c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000431e:	0004c783          	lbu	a5,0(s1)
    80004322:	ff279ce3          	bne	a5,s2,8000431a <namex+0x122>
    80004326:	bf8d                	j	80004298 <namex+0xa0>
    memmove(name, s, len);
    80004328:	2601                	sext.w	a2,a2
    8000432a:	8556                	mv	a0,s5
    8000432c:	ffffd097          	auipc	ra,0xffffd
    80004330:	a14080e7          	jalr	-1516(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004334:	9a56                	add	s4,s4,s5
    80004336:	000a0023          	sb	zero,0(s4)
    8000433a:	bf9d                	j	800042b0 <namex+0xb8>
  if(nameiparent){
    8000433c:	f20b03e3          	beqz	s6,80004262 <namex+0x6a>
    iput(ip);
    80004340:	854e                	mv	a0,s3
    80004342:	00000097          	auipc	ra,0x0
    80004346:	adc080e7          	jalr	-1316(ra) # 80003e1e <iput>
    return 0;
    8000434a:	4981                	li	s3,0
    8000434c:	bf19                	j	80004262 <namex+0x6a>
  if(*path == 0)
    8000434e:	d7fd                	beqz	a5,8000433c <namex+0x144>
  while(*path != '/' && *path != 0)
    80004350:	0004c783          	lbu	a5,0(s1)
    80004354:	85a6                	mv	a1,s1
    80004356:	b7d1                	j	8000431a <namex+0x122>

0000000080004358 <dirlink>:
{
    80004358:	7139                	addi	sp,sp,-64
    8000435a:	fc06                	sd	ra,56(sp)
    8000435c:	f822                	sd	s0,48(sp)
    8000435e:	f426                	sd	s1,40(sp)
    80004360:	f04a                	sd	s2,32(sp)
    80004362:	ec4e                	sd	s3,24(sp)
    80004364:	e852                	sd	s4,16(sp)
    80004366:	0080                	addi	s0,sp,64
    80004368:	892a                	mv	s2,a0
    8000436a:	8a2e                	mv	s4,a1
    8000436c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000436e:	4601                	li	a2,0
    80004370:	00000097          	auipc	ra,0x0
    80004374:	dd8080e7          	jalr	-552(ra) # 80004148 <dirlookup>
    80004378:	e93d                	bnez	a0,800043ee <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000437a:	04c92483          	lw	s1,76(s2)
    8000437e:	c49d                	beqz	s1,800043ac <dirlink+0x54>
    80004380:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004382:	4741                	li	a4,16
    80004384:	86a6                	mv	a3,s1
    80004386:	fc040613          	addi	a2,s0,-64
    8000438a:	4581                	li	a1,0
    8000438c:	854a                	mv	a0,s2
    8000438e:	00000097          	auipc	ra,0x0
    80004392:	b8a080e7          	jalr	-1142(ra) # 80003f18 <readi>
    80004396:	47c1                	li	a5,16
    80004398:	06f51163          	bne	a0,a5,800043fa <dirlink+0xa2>
    if(de.inum == 0)
    8000439c:	fc045783          	lhu	a5,-64(s0)
    800043a0:	c791                	beqz	a5,800043ac <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043a2:	24c1                	addiw	s1,s1,16
    800043a4:	04c92783          	lw	a5,76(s2)
    800043a8:	fcf4ede3          	bltu	s1,a5,80004382 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800043ac:	4639                	li	a2,14
    800043ae:	85d2                	mv	a1,s4
    800043b0:	fc240513          	addi	a0,s0,-62
    800043b4:	ffffd097          	auipc	ra,0xffffd
    800043b8:	a40080e7          	jalr	-1472(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800043bc:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043c0:	4741                	li	a4,16
    800043c2:	86a6                	mv	a3,s1
    800043c4:	fc040613          	addi	a2,s0,-64
    800043c8:	4581                	li	a1,0
    800043ca:	854a                	mv	a0,s2
    800043cc:	00000097          	auipc	ra,0x0
    800043d0:	c44080e7          	jalr	-956(ra) # 80004010 <writei>
    800043d4:	872a                	mv	a4,a0
    800043d6:	47c1                	li	a5,16
  return 0;
    800043d8:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043da:	02f71863          	bne	a4,a5,8000440a <dirlink+0xb2>
}
    800043de:	70e2                	ld	ra,56(sp)
    800043e0:	7442                	ld	s0,48(sp)
    800043e2:	74a2                	ld	s1,40(sp)
    800043e4:	7902                	ld	s2,32(sp)
    800043e6:	69e2                	ld	s3,24(sp)
    800043e8:	6a42                	ld	s4,16(sp)
    800043ea:	6121                	addi	sp,sp,64
    800043ec:	8082                	ret
    iput(ip);
    800043ee:	00000097          	auipc	ra,0x0
    800043f2:	a30080e7          	jalr	-1488(ra) # 80003e1e <iput>
    return -1;
    800043f6:	557d                	li	a0,-1
    800043f8:	b7dd                	j	800043de <dirlink+0x86>
      panic("dirlink read");
    800043fa:	00004517          	auipc	a0,0x4
    800043fe:	2ae50513          	addi	a0,a0,686 # 800086a8 <syscalls+0x1d8>
    80004402:	ffffc097          	auipc	ra,0xffffc
    80004406:	13c080e7          	jalr	316(ra) # 8000053e <panic>
    panic("dirlink");
    8000440a:	00004517          	auipc	a0,0x4
    8000440e:	3ae50513          	addi	a0,a0,942 # 800087b8 <syscalls+0x2e8>
    80004412:	ffffc097          	auipc	ra,0xffffc
    80004416:	12c080e7          	jalr	300(ra) # 8000053e <panic>

000000008000441a <namei>:

struct inode*
namei(char *path)
{
    8000441a:	1101                	addi	sp,sp,-32
    8000441c:	ec06                	sd	ra,24(sp)
    8000441e:	e822                	sd	s0,16(sp)
    80004420:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004422:	fe040613          	addi	a2,s0,-32
    80004426:	4581                	li	a1,0
    80004428:	00000097          	auipc	ra,0x0
    8000442c:	dd0080e7          	jalr	-560(ra) # 800041f8 <namex>
}
    80004430:	60e2                	ld	ra,24(sp)
    80004432:	6442                	ld	s0,16(sp)
    80004434:	6105                	addi	sp,sp,32
    80004436:	8082                	ret

0000000080004438 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004438:	1141                	addi	sp,sp,-16
    8000443a:	e406                	sd	ra,8(sp)
    8000443c:	e022                	sd	s0,0(sp)
    8000443e:	0800                	addi	s0,sp,16
    80004440:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004442:	4585                	li	a1,1
    80004444:	00000097          	auipc	ra,0x0
    80004448:	db4080e7          	jalr	-588(ra) # 800041f8 <namex>
}
    8000444c:	60a2                	ld	ra,8(sp)
    8000444e:	6402                	ld	s0,0(sp)
    80004450:	0141                	addi	sp,sp,16
    80004452:	8082                	ret

0000000080004454 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004454:	1101                	addi	sp,sp,-32
    80004456:	ec06                	sd	ra,24(sp)
    80004458:	e822                	sd	s0,16(sp)
    8000445a:	e426                	sd	s1,8(sp)
    8000445c:	e04a                	sd	s2,0(sp)
    8000445e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004460:	0001e917          	auipc	s2,0x1e
    80004464:	95090913          	addi	s2,s2,-1712 # 80021db0 <log>
    80004468:	01892583          	lw	a1,24(s2)
    8000446c:	02892503          	lw	a0,40(s2)
    80004470:	fffff097          	auipc	ra,0xfffff
    80004474:	ff2080e7          	jalr	-14(ra) # 80003462 <bread>
    80004478:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000447a:	02c92683          	lw	a3,44(s2)
    8000447e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004480:	02d05763          	blez	a3,800044ae <write_head+0x5a>
    80004484:	0001e797          	auipc	a5,0x1e
    80004488:	95c78793          	addi	a5,a5,-1700 # 80021de0 <log+0x30>
    8000448c:	05c50713          	addi	a4,a0,92
    80004490:	36fd                	addiw	a3,a3,-1
    80004492:	1682                	slli	a3,a3,0x20
    80004494:	9281                	srli	a3,a3,0x20
    80004496:	068a                	slli	a3,a3,0x2
    80004498:	0001e617          	auipc	a2,0x1e
    8000449c:	94c60613          	addi	a2,a2,-1716 # 80021de4 <log+0x34>
    800044a0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800044a2:	4390                	lw	a2,0(a5)
    800044a4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044a6:	0791                	addi	a5,a5,4
    800044a8:	0711                	addi	a4,a4,4
    800044aa:	fed79ce3          	bne	a5,a3,800044a2 <write_head+0x4e>
  }
  bwrite(buf);
    800044ae:	8526                	mv	a0,s1
    800044b0:	fffff097          	auipc	ra,0xfffff
    800044b4:	0a4080e7          	jalr	164(ra) # 80003554 <bwrite>
  brelse(buf);
    800044b8:	8526                	mv	a0,s1
    800044ba:	fffff097          	auipc	ra,0xfffff
    800044be:	0d8080e7          	jalr	216(ra) # 80003592 <brelse>
}
    800044c2:	60e2                	ld	ra,24(sp)
    800044c4:	6442                	ld	s0,16(sp)
    800044c6:	64a2                	ld	s1,8(sp)
    800044c8:	6902                	ld	s2,0(sp)
    800044ca:	6105                	addi	sp,sp,32
    800044cc:	8082                	ret

00000000800044ce <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800044ce:	0001e797          	auipc	a5,0x1e
    800044d2:	90e7a783          	lw	a5,-1778(a5) # 80021ddc <log+0x2c>
    800044d6:	0af05d63          	blez	a5,80004590 <install_trans+0xc2>
{
    800044da:	7139                	addi	sp,sp,-64
    800044dc:	fc06                	sd	ra,56(sp)
    800044de:	f822                	sd	s0,48(sp)
    800044e0:	f426                	sd	s1,40(sp)
    800044e2:	f04a                	sd	s2,32(sp)
    800044e4:	ec4e                	sd	s3,24(sp)
    800044e6:	e852                	sd	s4,16(sp)
    800044e8:	e456                	sd	s5,8(sp)
    800044ea:	e05a                	sd	s6,0(sp)
    800044ec:	0080                	addi	s0,sp,64
    800044ee:	8b2a                	mv	s6,a0
    800044f0:	0001ea97          	auipc	s5,0x1e
    800044f4:	8f0a8a93          	addi	s5,s5,-1808 # 80021de0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044f8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044fa:	0001e997          	auipc	s3,0x1e
    800044fe:	8b698993          	addi	s3,s3,-1866 # 80021db0 <log>
    80004502:	a035                	j	8000452e <install_trans+0x60>
      bunpin(dbuf);
    80004504:	8526                	mv	a0,s1
    80004506:	fffff097          	auipc	ra,0xfffff
    8000450a:	166080e7          	jalr	358(ra) # 8000366c <bunpin>
    brelse(lbuf);
    8000450e:	854a                	mv	a0,s2
    80004510:	fffff097          	auipc	ra,0xfffff
    80004514:	082080e7          	jalr	130(ra) # 80003592 <brelse>
    brelse(dbuf);
    80004518:	8526                	mv	a0,s1
    8000451a:	fffff097          	auipc	ra,0xfffff
    8000451e:	078080e7          	jalr	120(ra) # 80003592 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004522:	2a05                	addiw	s4,s4,1
    80004524:	0a91                	addi	s5,s5,4
    80004526:	02c9a783          	lw	a5,44(s3)
    8000452a:	04fa5963          	bge	s4,a5,8000457c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000452e:	0189a583          	lw	a1,24(s3)
    80004532:	014585bb          	addw	a1,a1,s4
    80004536:	2585                	addiw	a1,a1,1
    80004538:	0289a503          	lw	a0,40(s3)
    8000453c:	fffff097          	auipc	ra,0xfffff
    80004540:	f26080e7          	jalr	-218(ra) # 80003462 <bread>
    80004544:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004546:	000aa583          	lw	a1,0(s5)
    8000454a:	0289a503          	lw	a0,40(s3)
    8000454e:	fffff097          	auipc	ra,0xfffff
    80004552:	f14080e7          	jalr	-236(ra) # 80003462 <bread>
    80004556:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004558:	40000613          	li	a2,1024
    8000455c:	05890593          	addi	a1,s2,88
    80004560:	05850513          	addi	a0,a0,88
    80004564:	ffffc097          	auipc	ra,0xffffc
    80004568:	7dc080e7          	jalr	2012(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000456c:	8526                	mv	a0,s1
    8000456e:	fffff097          	auipc	ra,0xfffff
    80004572:	fe6080e7          	jalr	-26(ra) # 80003554 <bwrite>
    if(recovering == 0)
    80004576:	f80b1ce3          	bnez	s6,8000450e <install_trans+0x40>
    8000457a:	b769                	j	80004504 <install_trans+0x36>
}
    8000457c:	70e2                	ld	ra,56(sp)
    8000457e:	7442                	ld	s0,48(sp)
    80004580:	74a2                	ld	s1,40(sp)
    80004582:	7902                	ld	s2,32(sp)
    80004584:	69e2                	ld	s3,24(sp)
    80004586:	6a42                	ld	s4,16(sp)
    80004588:	6aa2                	ld	s5,8(sp)
    8000458a:	6b02                	ld	s6,0(sp)
    8000458c:	6121                	addi	sp,sp,64
    8000458e:	8082                	ret
    80004590:	8082                	ret

0000000080004592 <initlog>:
{
    80004592:	7179                	addi	sp,sp,-48
    80004594:	f406                	sd	ra,40(sp)
    80004596:	f022                	sd	s0,32(sp)
    80004598:	ec26                	sd	s1,24(sp)
    8000459a:	e84a                	sd	s2,16(sp)
    8000459c:	e44e                	sd	s3,8(sp)
    8000459e:	1800                	addi	s0,sp,48
    800045a0:	892a                	mv	s2,a0
    800045a2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800045a4:	0001e497          	auipc	s1,0x1e
    800045a8:	80c48493          	addi	s1,s1,-2036 # 80021db0 <log>
    800045ac:	00004597          	auipc	a1,0x4
    800045b0:	10c58593          	addi	a1,a1,268 # 800086b8 <syscalls+0x1e8>
    800045b4:	8526                	mv	a0,s1
    800045b6:	ffffc097          	auipc	ra,0xffffc
    800045ba:	59e080e7          	jalr	1438(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800045be:	0149a583          	lw	a1,20(s3)
    800045c2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800045c4:	0109a783          	lw	a5,16(s3)
    800045c8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800045ca:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800045ce:	854a                	mv	a0,s2
    800045d0:	fffff097          	auipc	ra,0xfffff
    800045d4:	e92080e7          	jalr	-366(ra) # 80003462 <bread>
  log.lh.n = lh->n;
    800045d8:	4d3c                	lw	a5,88(a0)
    800045da:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800045dc:	02f05563          	blez	a5,80004606 <initlog+0x74>
    800045e0:	05c50713          	addi	a4,a0,92
    800045e4:	0001d697          	auipc	a3,0x1d
    800045e8:	7fc68693          	addi	a3,a3,2044 # 80021de0 <log+0x30>
    800045ec:	37fd                	addiw	a5,a5,-1
    800045ee:	1782                	slli	a5,a5,0x20
    800045f0:	9381                	srli	a5,a5,0x20
    800045f2:	078a                	slli	a5,a5,0x2
    800045f4:	06050613          	addi	a2,a0,96
    800045f8:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800045fa:	4310                	lw	a2,0(a4)
    800045fc:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800045fe:	0711                	addi	a4,a4,4
    80004600:	0691                	addi	a3,a3,4
    80004602:	fef71ce3          	bne	a4,a5,800045fa <initlog+0x68>
  brelse(buf);
    80004606:	fffff097          	auipc	ra,0xfffff
    8000460a:	f8c080e7          	jalr	-116(ra) # 80003592 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000460e:	4505                	li	a0,1
    80004610:	00000097          	auipc	ra,0x0
    80004614:	ebe080e7          	jalr	-322(ra) # 800044ce <install_trans>
  log.lh.n = 0;
    80004618:	0001d797          	auipc	a5,0x1d
    8000461c:	7c07a223          	sw	zero,1988(a5) # 80021ddc <log+0x2c>
  write_head(); // clear the log
    80004620:	00000097          	auipc	ra,0x0
    80004624:	e34080e7          	jalr	-460(ra) # 80004454 <write_head>
}
    80004628:	70a2                	ld	ra,40(sp)
    8000462a:	7402                	ld	s0,32(sp)
    8000462c:	64e2                	ld	s1,24(sp)
    8000462e:	6942                	ld	s2,16(sp)
    80004630:	69a2                	ld	s3,8(sp)
    80004632:	6145                	addi	sp,sp,48
    80004634:	8082                	ret

0000000080004636 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004636:	1101                	addi	sp,sp,-32
    80004638:	ec06                	sd	ra,24(sp)
    8000463a:	e822                	sd	s0,16(sp)
    8000463c:	e426                	sd	s1,8(sp)
    8000463e:	e04a                	sd	s2,0(sp)
    80004640:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004642:	0001d517          	auipc	a0,0x1d
    80004646:	76e50513          	addi	a0,a0,1902 # 80021db0 <log>
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	59a080e7          	jalr	1434(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004652:	0001d497          	auipc	s1,0x1d
    80004656:	75e48493          	addi	s1,s1,1886 # 80021db0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000465a:	4979                	li	s2,30
    8000465c:	a039                	j	8000466a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000465e:	85a6                	mv	a1,s1
    80004660:	8526                	mv	a0,s1
    80004662:	ffffe097          	auipc	ra,0xffffe
    80004666:	ee0080e7          	jalr	-288(ra) # 80002542 <sleep>
    if(log.committing){
    8000466a:	50dc                	lw	a5,36(s1)
    8000466c:	fbed                	bnez	a5,8000465e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000466e:	509c                	lw	a5,32(s1)
    80004670:	0017871b          	addiw	a4,a5,1
    80004674:	0007069b          	sext.w	a3,a4
    80004678:	0027179b          	slliw	a5,a4,0x2
    8000467c:	9fb9                	addw	a5,a5,a4
    8000467e:	0017979b          	slliw	a5,a5,0x1
    80004682:	54d8                	lw	a4,44(s1)
    80004684:	9fb9                	addw	a5,a5,a4
    80004686:	00f95963          	bge	s2,a5,80004698 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000468a:	85a6                	mv	a1,s1
    8000468c:	8526                	mv	a0,s1
    8000468e:	ffffe097          	auipc	ra,0xffffe
    80004692:	eb4080e7          	jalr	-332(ra) # 80002542 <sleep>
    80004696:	bfd1                	j	8000466a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004698:	0001d517          	auipc	a0,0x1d
    8000469c:	71850513          	addi	a0,a0,1816 # 80021db0 <log>
    800046a0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800046a2:	ffffc097          	auipc	ra,0xffffc
    800046a6:	5f6080e7          	jalr	1526(ra) # 80000c98 <release>
      break;
    }
  }
}
    800046aa:	60e2                	ld	ra,24(sp)
    800046ac:	6442                	ld	s0,16(sp)
    800046ae:	64a2                	ld	s1,8(sp)
    800046b0:	6902                	ld	s2,0(sp)
    800046b2:	6105                	addi	sp,sp,32
    800046b4:	8082                	ret

00000000800046b6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800046b6:	7139                	addi	sp,sp,-64
    800046b8:	fc06                	sd	ra,56(sp)
    800046ba:	f822                	sd	s0,48(sp)
    800046bc:	f426                	sd	s1,40(sp)
    800046be:	f04a                	sd	s2,32(sp)
    800046c0:	ec4e                	sd	s3,24(sp)
    800046c2:	e852                	sd	s4,16(sp)
    800046c4:	e456                	sd	s5,8(sp)
    800046c6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800046c8:	0001d497          	auipc	s1,0x1d
    800046cc:	6e848493          	addi	s1,s1,1768 # 80021db0 <log>
    800046d0:	8526                	mv	a0,s1
    800046d2:	ffffc097          	auipc	ra,0xffffc
    800046d6:	512080e7          	jalr	1298(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800046da:	509c                	lw	a5,32(s1)
    800046dc:	37fd                	addiw	a5,a5,-1
    800046de:	0007891b          	sext.w	s2,a5
    800046e2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800046e4:	50dc                	lw	a5,36(s1)
    800046e6:	efb9                	bnez	a5,80004744 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800046e8:	06091663          	bnez	s2,80004754 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800046ec:	0001d497          	auipc	s1,0x1d
    800046f0:	6c448493          	addi	s1,s1,1732 # 80021db0 <log>
    800046f4:	4785                	li	a5,1
    800046f6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800046f8:	8526                	mv	a0,s1
    800046fa:	ffffc097          	auipc	ra,0xffffc
    800046fe:	59e080e7          	jalr	1438(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004702:	54dc                	lw	a5,44(s1)
    80004704:	06f04763          	bgtz	a5,80004772 <end_op+0xbc>
    acquire(&log.lock);
    80004708:	0001d497          	auipc	s1,0x1d
    8000470c:	6a848493          	addi	s1,s1,1704 # 80021db0 <log>
    80004710:	8526                	mv	a0,s1
    80004712:	ffffc097          	auipc	ra,0xffffc
    80004716:	4d2080e7          	jalr	1234(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000471a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000471e:	8526                	mv	a0,s1
    80004720:	ffffe097          	auipc	ra,0xffffe
    80004724:	fc0080e7          	jalr	-64(ra) # 800026e0 <wakeup>
    release(&log.lock);
    80004728:	8526                	mv	a0,s1
    8000472a:	ffffc097          	auipc	ra,0xffffc
    8000472e:	56e080e7          	jalr	1390(ra) # 80000c98 <release>
}
    80004732:	70e2                	ld	ra,56(sp)
    80004734:	7442                	ld	s0,48(sp)
    80004736:	74a2                	ld	s1,40(sp)
    80004738:	7902                	ld	s2,32(sp)
    8000473a:	69e2                	ld	s3,24(sp)
    8000473c:	6a42                	ld	s4,16(sp)
    8000473e:	6aa2                	ld	s5,8(sp)
    80004740:	6121                	addi	sp,sp,64
    80004742:	8082                	ret
    panic("log.committing");
    80004744:	00004517          	auipc	a0,0x4
    80004748:	f7c50513          	addi	a0,a0,-132 # 800086c0 <syscalls+0x1f0>
    8000474c:	ffffc097          	auipc	ra,0xffffc
    80004750:	df2080e7          	jalr	-526(ra) # 8000053e <panic>
    wakeup(&log);
    80004754:	0001d497          	auipc	s1,0x1d
    80004758:	65c48493          	addi	s1,s1,1628 # 80021db0 <log>
    8000475c:	8526                	mv	a0,s1
    8000475e:	ffffe097          	auipc	ra,0xffffe
    80004762:	f82080e7          	jalr	-126(ra) # 800026e0 <wakeup>
  release(&log.lock);
    80004766:	8526                	mv	a0,s1
    80004768:	ffffc097          	auipc	ra,0xffffc
    8000476c:	530080e7          	jalr	1328(ra) # 80000c98 <release>
  if(do_commit){
    80004770:	b7c9                	j	80004732 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004772:	0001da97          	auipc	s5,0x1d
    80004776:	66ea8a93          	addi	s5,s5,1646 # 80021de0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000477a:	0001da17          	auipc	s4,0x1d
    8000477e:	636a0a13          	addi	s4,s4,1590 # 80021db0 <log>
    80004782:	018a2583          	lw	a1,24(s4)
    80004786:	012585bb          	addw	a1,a1,s2
    8000478a:	2585                	addiw	a1,a1,1
    8000478c:	028a2503          	lw	a0,40(s4)
    80004790:	fffff097          	auipc	ra,0xfffff
    80004794:	cd2080e7          	jalr	-814(ra) # 80003462 <bread>
    80004798:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000479a:	000aa583          	lw	a1,0(s5)
    8000479e:	028a2503          	lw	a0,40(s4)
    800047a2:	fffff097          	auipc	ra,0xfffff
    800047a6:	cc0080e7          	jalr	-832(ra) # 80003462 <bread>
    800047aa:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800047ac:	40000613          	li	a2,1024
    800047b0:	05850593          	addi	a1,a0,88
    800047b4:	05848513          	addi	a0,s1,88
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	588080e7          	jalr	1416(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800047c0:	8526                	mv	a0,s1
    800047c2:	fffff097          	auipc	ra,0xfffff
    800047c6:	d92080e7          	jalr	-622(ra) # 80003554 <bwrite>
    brelse(from);
    800047ca:	854e                	mv	a0,s3
    800047cc:	fffff097          	auipc	ra,0xfffff
    800047d0:	dc6080e7          	jalr	-570(ra) # 80003592 <brelse>
    brelse(to);
    800047d4:	8526                	mv	a0,s1
    800047d6:	fffff097          	auipc	ra,0xfffff
    800047da:	dbc080e7          	jalr	-580(ra) # 80003592 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047de:	2905                	addiw	s2,s2,1
    800047e0:	0a91                	addi	s5,s5,4
    800047e2:	02ca2783          	lw	a5,44(s4)
    800047e6:	f8f94ee3          	blt	s2,a5,80004782 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800047ea:	00000097          	auipc	ra,0x0
    800047ee:	c6a080e7          	jalr	-918(ra) # 80004454 <write_head>
    install_trans(0); // Now install writes to home locations
    800047f2:	4501                	li	a0,0
    800047f4:	00000097          	auipc	ra,0x0
    800047f8:	cda080e7          	jalr	-806(ra) # 800044ce <install_trans>
    log.lh.n = 0;
    800047fc:	0001d797          	auipc	a5,0x1d
    80004800:	5e07a023          	sw	zero,1504(a5) # 80021ddc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004804:	00000097          	auipc	ra,0x0
    80004808:	c50080e7          	jalr	-944(ra) # 80004454 <write_head>
    8000480c:	bdf5                	j	80004708 <end_op+0x52>

000000008000480e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000480e:	1101                	addi	sp,sp,-32
    80004810:	ec06                	sd	ra,24(sp)
    80004812:	e822                	sd	s0,16(sp)
    80004814:	e426                	sd	s1,8(sp)
    80004816:	e04a                	sd	s2,0(sp)
    80004818:	1000                	addi	s0,sp,32
    8000481a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000481c:	0001d917          	auipc	s2,0x1d
    80004820:	59490913          	addi	s2,s2,1428 # 80021db0 <log>
    80004824:	854a                	mv	a0,s2
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	3be080e7          	jalr	958(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000482e:	02c92603          	lw	a2,44(s2)
    80004832:	47f5                	li	a5,29
    80004834:	06c7c563          	blt	a5,a2,8000489e <log_write+0x90>
    80004838:	0001d797          	auipc	a5,0x1d
    8000483c:	5947a783          	lw	a5,1428(a5) # 80021dcc <log+0x1c>
    80004840:	37fd                	addiw	a5,a5,-1
    80004842:	04f65e63          	bge	a2,a5,8000489e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004846:	0001d797          	auipc	a5,0x1d
    8000484a:	58a7a783          	lw	a5,1418(a5) # 80021dd0 <log+0x20>
    8000484e:	06f05063          	blez	a5,800048ae <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004852:	4781                	li	a5,0
    80004854:	06c05563          	blez	a2,800048be <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004858:	44cc                	lw	a1,12(s1)
    8000485a:	0001d717          	auipc	a4,0x1d
    8000485e:	58670713          	addi	a4,a4,1414 # 80021de0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004862:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004864:	4314                	lw	a3,0(a4)
    80004866:	04b68c63          	beq	a3,a1,800048be <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000486a:	2785                	addiw	a5,a5,1
    8000486c:	0711                	addi	a4,a4,4
    8000486e:	fef61be3          	bne	a2,a5,80004864 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004872:	0621                	addi	a2,a2,8
    80004874:	060a                	slli	a2,a2,0x2
    80004876:	0001d797          	auipc	a5,0x1d
    8000487a:	53a78793          	addi	a5,a5,1338 # 80021db0 <log>
    8000487e:	963e                	add	a2,a2,a5
    80004880:	44dc                	lw	a5,12(s1)
    80004882:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004884:	8526                	mv	a0,s1
    80004886:	fffff097          	auipc	ra,0xfffff
    8000488a:	daa080e7          	jalr	-598(ra) # 80003630 <bpin>
    log.lh.n++;
    8000488e:	0001d717          	auipc	a4,0x1d
    80004892:	52270713          	addi	a4,a4,1314 # 80021db0 <log>
    80004896:	575c                	lw	a5,44(a4)
    80004898:	2785                	addiw	a5,a5,1
    8000489a:	d75c                	sw	a5,44(a4)
    8000489c:	a835                	j	800048d8 <log_write+0xca>
    panic("too big a transaction");
    8000489e:	00004517          	auipc	a0,0x4
    800048a2:	e3250513          	addi	a0,a0,-462 # 800086d0 <syscalls+0x200>
    800048a6:	ffffc097          	auipc	ra,0xffffc
    800048aa:	c98080e7          	jalr	-872(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800048ae:	00004517          	auipc	a0,0x4
    800048b2:	e3a50513          	addi	a0,a0,-454 # 800086e8 <syscalls+0x218>
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	c88080e7          	jalr	-888(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800048be:	00878713          	addi	a4,a5,8
    800048c2:	00271693          	slli	a3,a4,0x2
    800048c6:	0001d717          	auipc	a4,0x1d
    800048ca:	4ea70713          	addi	a4,a4,1258 # 80021db0 <log>
    800048ce:	9736                	add	a4,a4,a3
    800048d0:	44d4                	lw	a3,12(s1)
    800048d2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800048d4:	faf608e3          	beq	a2,a5,80004884 <log_write+0x76>
  }
  release(&log.lock);
    800048d8:	0001d517          	auipc	a0,0x1d
    800048dc:	4d850513          	addi	a0,a0,1240 # 80021db0 <log>
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	3b8080e7          	jalr	952(ra) # 80000c98 <release>
}
    800048e8:	60e2                	ld	ra,24(sp)
    800048ea:	6442                	ld	s0,16(sp)
    800048ec:	64a2                	ld	s1,8(sp)
    800048ee:	6902                	ld	s2,0(sp)
    800048f0:	6105                	addi	sp,sp,32
    800048f2:	8082                	ret

00000000800048f4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800048f4:	1101                	addi	sp,sp,-32
    800048f6:	ec06                	sd	ra,24(sp)
    800048f8:	e822                	sd	s0,16(sp)
    800048fa:	e426                	sd	s1,8(sp)
    800048fc:	e04a                	sd	s2,0(sp)
    800048fe:	1000                	addi	s0,sp,32
    80004900:	84aa                	mv	s1,a0
    80004902:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004904:	00004597          	auipc	a1,0x4
    80004908:	e0458593          	addi	a1,a1,-508 # 80008708 <syscalls+0x238>
    8000490c:	0521                	addi	a0,a0,8
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	246080e7          	jalr	582(ra) # 80000b54 <initlock>
  lk->name = name;
    80004916:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000491a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000491e:	0204a423          	sw	zero,40(s1)
}
    80004922:	60e2                	ld	ra,24(sp)
    80004924:	6442                	ld	s0,16(sp)
    80004926:	64a2                	ld	s1,8(sp)
    80004928:	6902                	ld	s2,0(sp)
    8000492a:	6105                	addi	sp,sp,32
    8000492c:	8082                	ret

000000008000492e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000492e:	1101                	addi	sp,sp,-32
    80004930:	ec06                	sd	ra,24(sp)
    80004932:	e822                	sd	s0,16(sp)
    80004934:	e426                	sd	s1,8(sp)
    80004936:	e04a                	sd	s2,0(sp)
    80004938:	1000                	addi	s0,sp,32
    8000493a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000493c:	00850913          	addi	s2,a0,8
    80004940:	854a                	mv	a0,s2
    80004942:	ffffc097          	auipc	ra,0xffffc
    80004946:	2a2080e7          	jalr	674(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000494a:	409c                	lw	a5,0(s1)
    8000494c:	cb89                	beqz	a5,8000495e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000494e:	85ca                	mv	a1,s2
    80004950:	8526                	mv	a0,s1
    80004952:	ffffe097          	auipc	ra,0xffffe
    80004956:	bf0080e7          	jalr	-1040(ra) # 80002542 <sleep>
  while (lk->locked) {
    8000495a:	409c                	lw	a5,0(s1)
    8000495c:	fbed                	bnez	a5,8000494e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000495e:	4785                	li	a5,1
    80004960:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004962:	ffffd097          	auipc	ra,0xffffd
    80004966:	36e080e7          	jalr	878(ra) # 80001cd0 <myproc>
    8000496a:	591c                	lw	a5,48(a0)
    8000496c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000496e:	854a                	mv	a0,s2
    80004970:	ffffc097          	auipc	ra,0xffffc
    80004974:	328080e7          	jalr	808(ra) # 80000c98 <release>
}
    80004978:	60e2                	ld	ra,24(sp)
    8000497a:	6442                	ld	s0,16(sp)
    8000497c:	64a2                	ld	s1,8(sp)
    8000497e:	6902                	ld	s2,0(sp)
    80004980:	6105                	addi	sp,sp,32
    80004982:	8082                	ret

0000000080004984 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004984:	1101                	addi	sp,sp,-32
    80004986:	ec06                	sd	ra,24(sp)
    80004988:	e822                	sd	s0,16(sp)
    8000498a:	e426                	sd	s1,8(sp)
    8000498c:	e04a                	sd	s2,0(sp)
    8000498e:	1000                	addi	s0,sp,32
    80004990:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004992:	00850913          	addi	s2,a0,8
    80004996:	854a                	mv	a0,s2
    80004998:	ffffc097          	auipc	ra,0xffffc
    8000499c:	24c080e7          	jalr	588(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800049a0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049a4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800049a8:	8526                	mv	a0,s1
    800049aa:	ffffe097          	auipc	ra,0xffffe
    800049ae:	d36080e7          	jalr	-714(ra) # 800026e0 <wakeup>
  release(&lk->lk);
    800049b2:	854a                	mv	a0,s2
    800049b4:	ffffc097          	auipc	ra,0xffffc
    800049b8:	2e4080e7          	jalr	740(ra) # 80000c98 <release>
}
    800049bc:	60e2                	ld	ra,24(sp)
    800049be:	6442                	ld	s0,16(sp)
    800049c0:	64a2                	ld	s1,8(sp)
    800049c2:	6902                	ld	s2,0(sp)
    800049c4:	6105                	addi	sp,sp,32
    800049c6:	8082                	ret

00000000800049c8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800049c8:	7179                	addi	sp,sp,-48
    800049ca:	f406                	sd	ra,40(sp)
    800049cc:	f022                	sd	s0,32(sp)
    800049ce:	ec26                	sd	s1,24(sp)
    800049d0:	e84a                	sd	s2,16(sp)
    800049d2:	e44e                	sd	s3,8(sp)
    800049d4:	1800                	addi	s0,sp,48
    800049d6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800049d8:	00850913          	addi	s2,a0,8
    800049dc:	854a                	mv	a0,s2
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	206080e7          	jalr	518(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800049e6:	409c                	lw	a5,0(s1)
    800049e8:	ef99                	bnez	a5,80004a06 <holdingsleep+0x3e>
    800049ea:	4481                	li	s1,0
  release(&lk->lk);
    800049ec:	854a                	mv	a0,s2
    800049ee:	ffffc097          	auipc	ra,0xffffc
    800049f2:	2aa080e7          	jalr	682(ra) # 80000c98 <release>
  return r;
}
    800049f6:	8526                	mv	a0,s1
    800049f8:	70a2                	ld	ra,40(sp)
    800049fa:	7402                	ld	s0,32(sp)
    800049fc:	64e2                	ld	s1,24(sp)
    800049fe:	6942                	ld	s2,16(sp)
    80004a00:	69a2                	ld	s3,8(sp)
    80004a02:	6145                	addi	sp,sp,48
    80004a04:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a06:	0284a983          	lw	s3,40(s1)
    80004a0a:	ffffd097          	auipc	ra,0xffffd
    80004a0e:	2c6080e7          	jalr	710(ra) # 80001cd0 <myproc>
    80004a12:	5904                	lw	s1,48(a0)
    80004a14:	413484b3          	sub	s1,s1,s3
    80004a18:	0014b493          	seqz	s1,s1
    80004a1c:	bfc1                	j	800049ec <holdingsleep+0x24>

0000000080004a1e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a1e:	1141                	addi	sp,sp,-16
    80004a20:	e406                	sd	ra,8(sp)
    80004a22:	e022                	sd	s0,0(sp)
    80004a24:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a26:	00004597          	auipc	a1,0x4
    80004a2a:	cf258593          	addi	a1,a1,-782 # 80008718 <syscalls+0x248>
    80004a2e:	0001d517          	auipc	a0,0x1d
    80004a32:	4ca50513          	addi	a0,a0,1226 # 80021ef8 <ftable>
    80004a36:	ffffc097          	auipc	ra,0xffffc
    80004a3a:	11e080e7          	jalr	286(ra) # 80000b54 <initlock>
}
    80004a3e:	60a2                	ld	ra,8(sp)
    80004a40:	6402                	ld	s0,0(sp)
    80004a42:	0141                	addi	sp,sp,16
    80004a44:	8082                	ret

0000000080004a46 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a46:	1101                	addi	sp,sp,-32
    80004a48:	ec06                	sd	ra,24(sp)
    80004a4a:	e822                	sd	s0,16(sp)
    80004a4c:	e426                	sd	s1,8(sp)
    80004a4e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a50:	0001d517          	auipc	a0,0x1d
    80004a54:	4a850513          	addi	a0,a0,1192 # 80021ef8 <ftable>
    80004a58:	ffffc097          	auipc	ra,0xffffc
    80004a5c:	18c080e7          	jalr	396(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a60:	0001d497          	auipc	s1,0x1d
    80004a64:	4b048493          	addi	s1,s1,1200 # 80021f10 <ftable+0x18>
    80004a68:	0001e717          	auipc	a4,0x1e
    80004a6c:	44870713          	addi	a4,a4,1096 # 80022eb0 <ftable+0xfb8>
    if(f->ref == 0){
    80004a70:	40dc                	lw	a5,4(s1)
    80004a72:	cf99                	beqz	a5,80004a90 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a74:	02848493          	addi	s1,s1,40
    80004a78:	fee49ce3          	bne	s1,a4,80004a70 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a7c:	0001d517          	auipc	a0,0x1d
    80004a80:	47c50513          	addi	a0,a0,1148 # 80021ef8 <ftable>
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	214080e7          	jalr	532(ra) # 80000c98 <release>
  return 0;
    80004a8c:	4481                	li	s1,0
    80004a8e:	a819                	j	80004aa4 <filealloc+0x5e>
      f->ref = 1;
    80004a90:	4785                	li	a5,1
    80004a92:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a94:	0001d517          	auipc	a0,0x1d
    80004a98:	46450513          	addi	a0,a0,1124 # 80021ef8 <ftable>
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	1fc080e7          	jalr	508(ra) # 80000c98 <release>
}
    80004aa4:	8526                	mv	a0,s1
    80004aa6:	60e2                	ld	ra,24(sp)
    80004aa8:	6442                	ld	s0,16(sp)
    80004aaa:	64a2                	ld	s1,8(sp)
    80004aac:	6105                	addi	sp,sp,32
    80004aae:	8082                	ret

0000000080004ab0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004ab0:	1101                	addi	sp,sp,-32
    80004ab2:	ec06                	sd	ra,24(sp)
    80004ab4:	e822                	sd	s0,16(sp)
    80004ab6:	e426                	sd	s1,8(sp)
    80004ab8:	1000                	addi	s0,sp,32
    80004aba:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004abc:	0001d517          	auipc	a0,0x1d
    80004ac0:	43c50513          	addi	a0,a0,1084 # 80021ef8 <ftable>
    80004ac4:	ffffc097          	auipc	ra,0xffffc
    80004ac8:	120080e7          	jalr	288(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004acc:	40dc                	lw	a5,4(s1)
    80004ace:	02f05263          	blez	a5,80004af2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004ad2:	2785                	addiw	a5,a5,1
    80004ad4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004ad6:	0001d517          	auipc	a0,0x1d
    80004ada:	42250513          	addi	a0,a0,1058 # 80021ef8 <ftable>
    80004ade:	ffffc097          	auipc	ra,0xffffc
    80004ae2:	1ba080e7          	jalr	442(ra) # 80000c98 <release>
  return f;
}
    80004ae6:	8526                	mv	a0,s1
    80004ae8:	60e2                	ld	ra,24(sp)
    80004aea:	6442                	ld	s0,16(sp)
    80004aec:	64a2                	ld	s1,8(sp)
    80004aee:	6105                	addi	sp,sp,32
    80004af0:	8082                	ret
    panic("filedup");
    80004af2:	00004517          	auipc	a0,0x4
    80004af6:	c2e50513          	addi	a0,a0,-978 # 80008720 <syscalls+0x250>
    80004afa:	ffffc097          	auipc	ra,0xffffc
    80004afe:	a44080e7          	jalr	-1468(ra) # 8000053e <panic>

0000000080004b02 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b02:	7139                	addi	sp,sp,-64
    80004b04:	fc06                	sd	ra,56(sp)
    80004b06:	f822                	sd	s0,48(sp)
    80004b08:	f426                	sd	s1,40(sp)
    80004b0a:	f04a                	sd	s2,32(sp)
    80004b0c:	ec4e                	sd	s3,24(sp)
    80004b0e:	e852                	sd	s4,16(sp)
    80004b10:	e456                	sd	s5,8(sp)
    80004b12:	0080                	addi	s0,sp,64
    80004b14:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b16:	0001d517          	auipc	a0,0x1d
    80004b1a:	3e250513          	addi	a0,a0,994 # 80021ef8 <ftable>
    80004b1e:	ffffc097          	auipc	ra,0xffffc
    80004b22:	0c6080e7          	jalr	198(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004b26:	40dc                	lw	a5,4(s1)
    80004b28:	06f05163          	blez	a5,80004b8a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b2c:	37fd                	addiw	a5,a5,-1
    80004b2e:	0007871b          	sext.w	a4,a5
    80004b32:	c0dc                	sw	a5,4(s1)
    80004b34:	06e04363          	bgtz	a4,80004b9a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b38:	0004a903          	lw	s2,0(s1)
    80004b3c:	0094ca83          	lbu	s5,9(s1)
    80004b40:	0104ba03          	ld	s4,16(s1)
    80004b44:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b48:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b4c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b50:	0001d517          	auipc	a0,0x1d
    80004b54:	3a850513          	addi	a0,a0,936 # 80021ef8 <ftable>
    80004b58:	ffffc097          	auipc	ra,0xffffc
    80004b5c:	140080e7          	jalr	320(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004b60:	4785                	li	a5,1
    80004b62:	04f90d63          	beq	s2,a5,80004bbc <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b66:	3979                	addiw	s2,s2,-2
    80004b68:	4785                	li	a5,1
    80004b6a:	0527e063          	bltu	a5,s2,80004baa <fileclose+0xa8>
    begin_op();
    80004b6e:	00000097          	auipc	ra,0x0
    80004b72:	ac8080e7          	jalr	-1336(ra) # 80004636 <begin_op>
    iput(ff.ip);
    80004b76:	854e                	mv	a0,s3
    80004b78:	fffff097          	auipc	ra,0xfffff
    80004b7c:	2a6080e7          	jalr	678(ra) # 80003e1e <iput>
    end_op();
    80004b80:	00000097          	auipc	ra,0x0
    80004b84:	b36080e7          	jalr	-1226(ra) # 800046b6 <end_op>
    80004b88:	a00d                	j	80004baa <fileclose+0xa8>
    panic("fileclose");
    80004b8a:	00004517          	auipc	a0,0x4
    80004b8e:	b9e50513          	addi	a0,a0,-1122 # 80008728 <syscalls+0x258>
    80004b92:	ffffc097          	auipc	ra,0xffffc
    80004b96:	9ac080e7          	jalr	-1620(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004b9a:	0001d517          	auipc	a0,0x1d
    80004b9e:	35e50513          	addi	a0,a0,862 # 80021ef8 <ftable>
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	0f6080e7          	jalr	246(ra) # 80000c98 <release>
  }
}
    80004baa:	70e2                	ld	ra,56(sp)
    80004bac:	7442                	ld	s0,48(sp)
    80004bae:	74a2                	ld	s1,40(sp)
    80004bb0:	7902                	ld	s2,32(sp)
    80004bb2:	69e2                	ld	s3,24(sp)
    80004bb4:	6a42                	ld	s4,16(sp)
    80004bb6:	6aa2                	ld	s5,8(sp)
    80004bb8:	6121                	addi	sp,sp,64
    80004bba:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004bbc:	85d6                	mv	a1,s5
    80004bbe:	8552                	mv	a0,s4
    80004bc0:	00000097          	auipc	ra,0x0
    80004bc4:	34c080e7          	jalr	844(ra) # 80004f0c <pipeclose>
    80004bc8:	b7cd                	j	80004baa <fileclose+0xa8>

0000000080004bca <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004bca:	715d                	addi	sp,sp,-80
    80004bcc:	e486                	sd	ra,72(sp)
    80004bce:	e0a2                	sd	s0,64(sp)
    80004bd0:	fc26                	sd	s1,56(sp)
    80004bd2:	f84a                	sd	s2,48(sp)
    80004bd4:	f44e                	sd	s3,40(sp)
    80004bd6:	0880                	addi	s0,sp,80
    80004bd8:	84aa                	mv	s1,a0
    80004bda:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004bdc:	ffffd097          	auipc	ra,0xffffd
    80004be0:	0f4080e7          	jalr	244(ra) # 80001cd0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004be4:	409c                	lw	a5,0(s1)
    80004be6:	37f9                	addiw	a5,a5,-2
    80004be8:	4705                	li	a4,1
    80004bea:	04f76763          	bltu	a4,a5,80004c38 <filestat+0x6e>
    80004bee:	892a                	mv	s2,a0
    ilock(f->ip);
    80004bf0:	6c88                	ld	a0,24(s1)
    80004bf2:	fffff097          	auipc	ra,0xfffff
    80004bf6:	072080e7          	jalr	114(ra) # 80003c64 <ilock>
    stati(f->ip, &st);
    80004bfa:	fb840593          	addi	a1,s0,-72
    80004bfe:	6c88                	ld	a0,24(s1)
    80004c00:	fffff097          	auipc	ra,0xfffff
    80004c04:	2ee080e7          	jalr	750(ra) # 80003eee <stati>
    iunlock(f->ip);
    80004c08:	6c88                	ld	a0,24(s1)
    80004c0a:	fffff097          	auipc	ra,0xfffff
    80004c0e:	11c080e7          	jalr	284(ra) # 80003d26 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c12:	46e1                	li	a3,24
    80004c14:	fb840613          	addi	a2,s0,-72
    80004c18:	85ce                	mv	a1,s3
    80004c1a:	05093503          	ld	a0,80(s2)
    80004c1e:	ffffd097          	auipc	ra,0xffffd
    80004c22:	a54080e7          	jalr	-1452(ra) # 80001672 <copyout>
    80004c26:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c2a:	60a6                	ld	ra,72(sp)
    80004c2c:	6406                	ld	s0,64(sp)
    80004c2e:	74e2                	ld	s1,56(sp)
    80004c30:	7942                	ld	s2,48(sp)
    80004c32:	79a2                	ld	s3,40(sp)
    80004c34:	6161                	addi	sp,sp,80
    80004c36:	8082                	ret
  return -1;
    80004c38:	557d                	li	a0,-1
    80004c3a:	bfc5                	j	80004c2a <filestat+0x60>

0000000080004c3c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c3c:	7179                	addi	sp,sp,-48
    80004c3e:	f406                	sd	ra,40(sp)
    80004c40:	f022                	sd	s0,32(sp)
    80004c42:	ec26                	sd	s1,24(sp)
    80004c44:	e84a                	sd	s2,16(sp)
    80004c46:	e44e                	sd	s3,8(sp)
    80004c48:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c4a:	00854783          	lbu	a5,8(a0)
    80004c4e:	c3d5                	beqz	a5,80004cf2 <fileread+0xb6>
    80004c50:	84aa                	mv	s1,a0
    80004c52:	89ae                	mv	s3,a1
    80004c54:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c56:	411c                	lw	a5,0(a0)
    80004c58:	4705                	li	a4,1
    80004c5a:	04e78963          	beq	a5,a4,80004cac <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c5e:	470d                	li	a4,3
    80004c60:	04e78d63          	beq	a5,a4,80004cba <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c64:	4709                	li	a4,2
    80004c66:	06e79e63          	bne	a5,a4,80004ce2 <fileread+0xa6>
    ilock(f->ip);
    80004c6a:	6d08                	ld	a0,24(a0)
    80004c6c:	fffff097          	auipc	ra,0xfffff
    80004c70:	ff8080e7          	jalr	-8(ra) # 80003c64 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c74:	874a                	mv	a4,s2
    80004c76:	5094                	lw	a3,32(s1)
    80004c78:	864e                	mv	a2,s3
    80004c7a:	4585                	li	a1,1
    80004c7c:	6c88                	ld	a0,24(s1)
    80004c7e:	fffff097          	auipc	ra,0xfffff
    80004c82:	29a080e7          	jalr	666(ra) # 80003f18 <readi>
    80004c86:	892a                	mv	s2,a0
    80004c88:	00a05563          	blez	a0,80004c92 <fileread+0x56>
      f->off += r;
    80004c8c:	509c                	lw	a5,32(s1)
    80004c8e:	9fa9                	addw	a5,a5,a0
    80004c90:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c92:	6c88                	ld	a0,24(s1)
    80004c94:	fffff097          	auipc	ra,0xfffff
    80004c98:	092080e7          	jalr	146(ra) # 80003d26 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c9c:	854a                	mv	a0,s2
    80004c9e:	70a2                	ld	ra,40(sp)
    80004ca0:	7402                	ld	s0,32(sp)
    80004ca2:	64e2                	ld	s1,24(sp)
    80004ca4:	6942                	ld	s2,16(sp)
    80004ca6:	69a2                	ld	s3,8(sp)
    80004ca8:	6145                	addi	sp,sp,48
    80004caa:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004cac:	6908                	ld	a0,16(a0)
    80004cae:	00000097          	auipc	ra,0x0
    80004cb2:	3c8080e7          	jalr	968(ra) # 80005076 <piperead>
    80004cb6:	892a                	mv	s2,a0
    80004cb8:	b7d5                	j	80004c9c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004cba:	02451783          	lh	a5,36(a0)
    80004cbe:	03079693          	slli	a3,a5,0x30
    80004cc2:	92c1                	srli	a3,a3,0x30
    80004cc4:	4725                	li	a4,9
    80004cc6:	02d76863          	bltu	a4,a3,80004cf6 <fileread+0xba>
    80004cca:	0792                	slli	a5,a5,0x4
    80004ccc:	0001d717          	auipc	a4,0x1d
    80004cd0:	18c70713          	addi	a4,a4,396 # 80021e58 <devsw>
    80004cd4:	97ba                	add	a5,a5,a4
    80004cd6:	639c                	ld	a5,0(a5)
    80004cd8:	c38d                	beqz	a5,80004cfa <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004cda:	4505                	li	a0,1
    80004cdc:	9782                	jalr	a5
    80004cde:	892a                	mv	s2,a0
    80004ce0:	bf75                	j	80004c9c <fileread+0x60>
    panic("fileread");
    80004ce2:	00004517          	auipc	a0,0x4
    80004ce6:	a5650513          	addi	a0,a0,-1450 # 80008738 <syscalls+0x268>
    80004cea:	ffffc097          	auipc	ra,0xffffc
    80004cee:	854080e7          	jalr	-1964(ra) # 8000053e <panic>
    return -1;
    80004cf2:	597d                	li	s2,-1
    80004cf4:	b765                	j	80004c9c <fileread+0x60>
      return -1;
    80004cf6:	597d                	li	s2,-1
    80004cf8:	b755                	j	80004c9c <fileread+0x60>
    80004cfa:	597d                	li	s2,-1
    80004cfc:	b745                	j	80004c9c <fileread+0x60>

0000000080004cfe <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004cfe:	715d                	addi	sp,sp,-80
    80004d00:	e486                	sd	ra,72(sp)
    80004d02:	e0a2                	sd	s0,64(sp)
    80004d04:	fc26                	sd	s1,56(sp)
    80004d06:	f84a                	sd	s2,48(sp)
    80004d08:	f44e                	sd	s3,40(sp)
    80004d0a:	f052                	sd	s4,32(sp)
    80004d0c:	ec56                	sd	s5,24(sp)
    80004d0e:	e85a                	sd	s6,16(sp)
    80004d10:	e45e                	sd	s7,8(sp)
    80004d12:	e062                	sd	s8,0(sp)
    80004d14:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004d16:	00954783          	lbu	a5,9(a0)
    80004d1a:	10078663          	beqz	a5,80004e26 <filewrite+0x128>
    80004d1e:	892a                	mv	s2,a0
    80004d20:	8aae                	mv	s5,a1
    80004d22:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d24:	411c                	lw	a5,0(a0)
    80004d26:	4705                	li	a4,1
    80004d28:	02e78263          	beq	a5,a4,80004d4c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d2c:	470d                	li	a4,3
    80004d2e:	02e78663          	beq	a5,a4,80004d5a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d32:	4709                	li	a4,2
    80004d34:	0ee79163          	bne	a5,a4,80004e16 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d38:	0ac05d63          	blez	a2,80004df2 <filewrite+0xf4>
    int i = 0;
    80004d3c:	4981                	li	s3,0
    80004d3e:	6b05                	lui	s6,0x1
    80004d40:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004d44:	6b85                	lui	s7,0x1
    80004d46:	c00b8b9b          	addiw	s7,s7,-1024
    80004d4a:	a861                	j	80004de2 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d4c:	6908                	ld	a0,16(a0)
    80004d4e:	00000097          	auipc	ra,0x0
    80004d52:	22e080e7          	jalr	558(ra) # 80004f7c <pipewrite>
    80004d56:	8a2a                	mv	s4,a0
    80004d58:	a045                	j	80004df8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d5a:	02451783          	lh	a5,36(a0)
    80004d5e:	03079693          	slli	a3,a5,0x30
    80004d62:	92c1                	srli	a3,a3,0x30
    80004d64:	4725                	li	a4,9
    80004d66:	0cd76263          	bltu	a4,a3,80004e2a <filewrite+0x12c>
    80004d6a:	0792                	slli	a5,a5,0x4
    80004d6c:	0001d717          	auipc	a4,0x1d
    80004d70:	0ec70713          	addi	a4,a4,236 # 80021e58 <devsw>
    80004d74:	97ba                	add	a5,a5,a4
    80004d76:	679c                	ld	a5,8(a5)
    80004d78:	cbdd                	beqz	a5,80004e2e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d7a:	4505                	li	a0,1
    80004d7c:	9782                	jalr	a5
    80004d7e:	8a2a                	mv	s4,a0
    80004d80:	a8a5                	j	80004df8 <filewrite+0xfa>
    80004d82:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d86:	00000097          	auipc	ra,0x0
    80004d8a:	8b0080e7          	jalr	-1872(ra) # 80004636 <begin_op>
      ilock(f->ip);
    80004d8e:	01893503          	ld	a0,24(s2)
    80004d92:	fffff097          	auipc	ra,0xfffff
    80004d96:	ed2080e7          	jalr	-302(ra) # 80003c64 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d9a:	8762                	mv	a4,s8
    80004d9c:	02092683          	lw	a3,32(s2)
    80004da0:	01598633          	add	a2,s3,s5
    80004da4:	4585                	li	a1,1
    80004da6:	01893503          	ld	a0,24(s2)
    80004daa:	fffff097          	auipc	ra,0xfffff
    80004dae:	266080e7          	jalr	614(ra) # 80004010 <writei>
    80004db2:	84aa                	mv	s1,a0
    80004db4:	00a05763          	blez	a0,80004dc2 <filewrite+0xc4>
        f->off += r;
    80004db8:	02092783          	lw	a5,32(s2)
    80004dbc:	9fa9                	addw	a5,a5,a0
    80004dbe:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004dc2:	01893503          	ld	a0,24(s2)
    80004dc6:	fffff097          	auipc	ra,0xfffff
    80004dca:	f60080e7          	jalr	-160(ra) # 80003d26 <iunlock>
      end_op();
    80004dce:	00000097          	auipc	ra,0x0
    80004dd2:	8e8080e7          	jalr	-1816(ra) # 800046b6 <end_op>

      if(r != n1){
    80004dd6:	009c1f63          	bne	s8,s1,80004df4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004dda:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004dde:	0149db63          	bge	s3,s4,80004df4 <filewrite+0xf6>
      int n1 = n - i;
    80004de2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004de6:	84be                	mv	s1,a5
    80004de8:	2781                	sext.w	a5,a5
    80004dea:	f8fb5ce3          	bge	s6,a5,80004d82 <filewrite+0x84>
    80004dee:	84de                	mv	s1,s7
    80004df0:	bf49                	j	80004d82 <filewrite+0x84>
    int i = 0;
    80004df2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004df4:	013a1f63          	bne	s4,s3,80004e12 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004df8:	8552                	mv	a0,s4
    80004dfa:	60a6                	ld	ra,72(sp)
    80004dfc:	6406                	ld	s0,64(sp)
    80004dfe:	74e2                	ld	s1,56(sp)
    80004e00:	7942                	ld	s2,48(sp)
    80004e02:	79a2                	ld	s3,40(sp)
    80004e04:	7a02                	ld	s4,32(sp)
    80004e06:	6ae2                	ld	s5,24(sp)
    80004e08:	6b42                	ld	s6,16(sp)
    80004e0a:	6ba2                	ld	s7,8(sp)
    80004e0c:	6c02                	ld	s8,0(sp)
    80004e0e:	6161                	addi	sp,sp,80
    80004e10:	8082                	ret
    ret = (i == n ? n : -1);
    80004e12:	5a7d                	li	s4,-1
    80004e14:	b7d5                	j	80004df8 <filewrite+0xfa>
    panic("filewrite");
    80004e16:	00004517          	auipc	a0,0x4
    80004e1a:	93250513          	addi	a0,a0,-1742 # 80008748 <syscalls+0x278>
    80004e1e:	ffffb097          	auipc	ra,0xffffb
    80004e22:	720080e7          	jalr	1824(ra) # 8000053e <panic>
    return -1;
    80004e26:	5a7d                	li	s4,-1
    80004e28:	bfc1                	j	80004df8 <filewrite+0xfa>
      return -1;
    80004e2a:	5a7d                	li	s4,-1
    80004e2c:	b7f1                	j	80004df8 <filewrite+0xfa>
    80004e2e:	5a7d                	li	s4,-1
    80004e30:	b7e1                	j	80004df8 <filewrite+0xfa>

0000000080004e32 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e32:	7179                	addi	sp,sp,-48
    80004e34:	f406                	sd	ra,40(sp)
    80004e36:	f022                	sd	s0,32(sp)
    80004e38:	ec26                	sd	s1,24(sp)
    80004e3a:	e84a                	sd	s2,16(sp)
    80004e3c:	e44e                	sd	s3,8(sp)
    80004e3e:	e052                	sd	s4,0(sp)
    80004e40:	1800                	addi	s0,sp,48
    80004e42:	84aa                	mv	s1,a0
    80004e44:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e46:	0005b023          	sd	zero,0(a1)
    80004e4a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e4e:	00000097          	auipc	ra,0x0
    80004e52:	bf8080e7          	jalr	-1032(ra) # 80004a46 <filealloc>
    80004e56:	e088                	sd	a0,0(s1)
    80004e58:	c551                	beqz	a0,80004ee4 <pipealloc+0xb2>
    80004e5a:	00000097          	auipc	ra,0x0
    80004e5e:	bec080e7          	jalr	-1044(ra) # 80004a46 <filealloc>
    80004e62:	00aa3023          	sd	a0,0(s4)
    80004e66:	c92d                	beqz	a0,80004ed8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e68:	ffffc097          	auipc	ra,0xffffc
    80004e6c:	c8c080e7          	jalr	-884(ra) # 80000af4 <kalloc>
    80004e70:	892a                	mv	s2,a0
    80004e72:	c125                	beqz	a0,80004ed2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e74:	4985                	li	s3,1
    80004e76:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e7a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e7e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e82:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e86:	00004597          	auipc	a1,0x4
    80004e8a:	8d258593          	addi	a1,a1,-1838 # 80008758 <syscalls+0x288>
    80004e8e:	ffffc097          	auipc	ra,0xffffc
    80004e92:	cc6080e7          	jalr	-826(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004e96:	609c                	ld	a5,0(s1)
    80004e98:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e9c:	609c                	ld	a5,0(s1)
    80004e9e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ea2:	609c                	ld	a5,0(s1)
    80004ea4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ea8:	609c                	ld	a5,0(s1)
    80004eaa:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004eae:	000a3783          	ld	a5,0(s4)
    80004eb2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004eb6:	000a3783          	ld	a5,0(s4)
    80004eba:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ebe:	000a3783          	ld	a5,0(s4)
    80004ec2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ec6:	000a3783          	ld	a5,0(s4)
    80004eca:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ece:	4501                	li	a0,0
    80004ed0:	a025                	j	80004ef8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ed2:	6088                	ld	a0,0(s1)
    80004ed4:	e501                	bnez	a0,80004edc <pipealloc+0xaa>
    80004ed6:	a039                	j	80004ee4 <pipealloc+0xb2>
    80004ed8:	6088                	ld	a0,0(s1)
    80004eda:	c51d                	beqz	a0,80004f08 <pipealloc+0xd6>
    fileclose(*f0);
    80004edc:	00000097          	auipc	ra,0x0
    80004ee0:	c26080e7          	jalr	-986(ra) # 80004b02 <fileclose>
  if(*f1)
    80004ee4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ee8:	557d                	li	a0,-1
  if(*f1)
    80004eea:	c799                	beqz	a5,80004ef8 <pipealloc+0xc6>
    fileclose(*f1);
    80004eec:	853e                	mv	a0,a5
    80004eee:	00000097          	auipc	ra,0x0
    80004ef2:	c14080e7          	jalr	-1004(ra) # 80004b02 <fileclose>
  return -1;
    80004ef6:	557d                	li	a0,-1
}
    80004ef8:	70a2                	ld	ra,40(sp)
    80004efa:	7402                	ld	s0,32(sp)
    80004efc:	64e2                	ld	s1,24(sp)
    80004efe:	6942                	ld	s2,16(sp)
    80004f00:	69a2                	ld	s3,8(sp)
    80004f02:	6a02                	ld	s4,0(sp)
    80004f04:	6145                	addi	sp,sp,48
    80004f06:	8082                	ret
  return -1;
    80004f08:	557d                	li	a0,-1
    80004f0a:	b7fd                	j	80004ef8 <pipealloc+0xc6>

0000000080004f0c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f0c:	1101                	addi	sp,sp,-32
    80004f0e:	ec06                	sd	ra,24(sp)
    80004f10:	e822                	sd	s0,16(sp)
    80004f12:	e426                	sd	s1,8(sp)
    80004f14:	e04a                	sd	s2,0(sp)
    80004f16:	1000                	addi	s0,sp,32
    80004f18:	84aa                	mv	s1,a0
    80004f1a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f1c:	ffffc097          	auipc	ra,0xffffc
    80004f20:	cc8080e7          	jalr	-824(ra) # 80000be4 <acquire>
  if(writable){
    80004f24:	02090d63          	beqz	s2,80004f5e <pipeclose+0x52>
    pi->writeopen = 0;
    80004f28:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f2c:	21848513          	addi	a0,s1,536
    80004f30:	ffffd097          	auipc	ra,0xffffd
    80004f34:	7b0080e7          	jalr	1968(ra) # 800026e0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f38:	2204b783          	ld	a5,544(s1)
    80004f3c:	eb95                	bnez	a5,80004f70 <pipeclose+0x64>
    release(&pi->lock);
    80004f3e:	8526                	mv	a0,s1
    80004f40:	ffffc097          	auipc	ra,0xffffc
    80004f44:	d58080e7          	jalr	-680(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004f48:	8526                	mv	a0,s1
    80004f4a:	ffffc097          	auipc	ra,0xffffc
    80004f4e:	aae080e7          	jalr	-1362(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004f52:	60e2                	ld	ra,24(sp)
    80004f54:	6442                	ld	s0,16(sp)
    80004f56:	64a2                	ld	s1,8(sp)
    80004f58:	6902                	ld	s2,0(sp)
    80004f5a:	6105                	addi	sp,sp,32
    80004f5c:	8082                	ret
    pi->readopen = 0;
    80004f5e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f62:	21c48513          	addi	a0,s1,540
    80004f66:	ffffd097          	auipc	ra,0xffffd
    80004f6a:	77a080e7          	jalr	1914(ra) # 800026e0 <wakeup>
    80004f6e:	b7e9                	j	80004f38 <pipeclose+0x2c>
    release(&pi->lock);
    80004f70:	8526                	mv	a0,s1
    80004f72:	ffffc097          	auipc	ra,0xffffc
    80004f76:	d26080e7          	jalr	-730(ra) # 80000c98 <release>
}
    80004f7a:	bfe1                	j	80004f52 <pipeclose+0x46>

0000000080004f7c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f7c:	7159                	addi	sp,sp,-112
    80004f7e:	f486                	sd	ra,104(sp)
    80004f80:	f0a2                	sd	s0,96(sp)
    80004f82:	eca6                	sd	s1,88(sp)
    80004f84:	e8ca                	sd	s2,80(sp)
    80004f86:	e4ce                	sd	s3,72(sp)
    80004f88:	e0d2                	sd	s4,64(sp)
    80004f8a:	fc56                	sd	s5,56(sp)
    80004f8c:	f85a                	sd	s6,48(sp)
    80004f8e:	f45e                	sd	s7,40(sp)
    80004f90:	f062                	sd	s8,32(sp)
    80004f92:	ec66                	sd	s9,24(sp)
    80004f94:	1880                	addi	s0,sp,112
    80004f96:	84aa                	mv	s1,a0
    80004f98:	8aae                	mv	s5,a1
    80004f9a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f9c:	ffffd097          	auipc	ra,0xffffd
    80004fa0:	d34080e7          	jalr	-716(ra) # 80001cd0 <myproc>
    80004fa4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004fa6:	8526                	mv	a0,s1
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	c3c080e7          	jalr	-964(ra) # 80000be4 <acquire>
  while(i < n){
    80004fb0:	0d405163          	blez	s4,80005072 <pipewrite+0xf6>
    80004fb4:	8ba6                	mv	s7,s1
  int i = 0;
    80004fb6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fb8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004fba:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004fbe:	21c48c13          	addi	s8,s1,540
    80004fc2:	a08d                	j	80005024 <pipewrite+0xa8>
      release(&pi->lock);
    80004fc4:	8526                	mv	a0,s1
    80004fc6:	ffffc097          	auipc	ra,0xffffc
    80004fca:	cd2080e7          	jalr	-814(ra) # 80000c98 <release>
      return -1;
    80004fce:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004fd0:	854a                	mv	a0,s2
    80004fd2:	70a6                	ld	ra,104(sp)
    80004fd4:	7406                	ld	s0,96(sp)
    80004fd6:	64e6                	ld	s1,88(sp)
    80004fd8:	6946                	ld	s2,80(sp)
    80004fda:	69a6                	ld	s3,72(sp)
    80004fdc:	6a06                	ld	s4,64(sp)
    80004fde:	7ae2                	ld	s5,56(sp)
    80004fe0:	7b42                	ld	s6,48(sp)
    80004fe2:	7ba2                	ld	s7,40(sp)
    80004fe4:	7c02                	ld	s8,32(sp)
    80004fe6:	6ce2                	ld	s9,24(sp)
    80004fe8:	6165                	addi	sp,sp,112
    80004fea:	8082                	ret
      wakeup(&pi->nread);
    80004fec:	8566                	mv	a0,s9
    80004fee:	ffffd097          	auipc	ra,0xffffd
    80004ff2:	6f2080e7          	jalr	1778(ra) # 800026e0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ff6:	85de                	mv	a1,s7
    80004ff8:	8562                	mv	a0,s8
    80004ffa:	ffffd097          	auipc	ra,0xffffd
    80004ffe:	548080e7          	jalr	1352(ra) # 80002542 <sleep>
    80005002:	a839                	j	80005020 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005004:	21c4a783          	lw	a5,540(s1)
    80005008:	0017871b          	addiw	a4,a5,1
    8000500c:	20e4ae23          	sw	a4,540(s1)
    80005010:	1ff7f793          	andi	a5,a5,511
    80005014:	97a6                	add	a5,a5,s1
    80005016:	f9f44703          	lbu	a4,-97(s0)
    8000501a:	00e78c23          	sb	a4,24(a5)
      i++;
    8000501e:	2905                	addiw	s2,s2,1
  while(i < n){
    80005020:	03495d63          	bge	s2,s4,8000505a <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005024:	2204a783          	lw	a5,544(s1)
    80005028:	dfd1                	beqz	a5,80004fc4 <pipewrite+0x48>
    8000502a:	0289a783          	lw	a5,40(s3)
    8000502e:	fbd9                	bnez	a5,80004fc4 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005030:	2184a783          	lw	a5,536(s1)
    80005034:	21c4a703          	lw	a4,540(s1)
    80005038:	2007879b          	addiw	a5,a5,512
    8000503c:	faf708e3          	beq	a4,a5,80004fec <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005040:	4685                	li	a3,1
    80005042:	01590633          	add	a2,s2,s5
    80005046:	f9f40593          	addi	a1,s0,-97
    8000504a:	0509b503          	ld	a0,80(s3)
    8000504e:	ffffc097          	auipc	ra,0xffffc
    80005052:	6b0080e7          	jalr	1712(ra) # 800016fe <copyin>
    80005056:	fb6517e3          	bne	a0,s6,80005004 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000505a:	21848513          	addi	a0,s1,536
    8000505e:	ffffd097          	auipc	ra,0xffffd
    80005062:	682080e7          	jalr	1666(ra) # 800026e0 <wakeup>
  release(&pi->lock);
    80005066:	8526                	mv	a0,s1
    80005068:	ffffc097          	auipc	ra,0xffffc
    8000506c:	c30080e7          	jalr	-976(ra) # 80000c98 <release>
  return i;
    80005070:	b785                	j	80004fd0 <pipewrite+0x54>
  int i = 0;
    80005072:	4901                	li	s2,0
    80005074:	b7dd                	j	8000505a <pipewrite+0xde>

0000000080005076 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005076:	715d                	addi	sp,sp,-80
    80005078:	e486                	sd	ra,72(sp)
    8000507a:	e0a2                	sd	s0,64(sp)
    8000507c:	fc26                	sd	s1,56(sp)
    8000507e:	f84a                	sd	s2,48(sp)
    80005080:	f44e                	sd	s3,40(sp)
    80005082:	f052                	sd	s4,32(sp)
    80005084:	ec56                	sd	s5,24(sp)
    80005086:	e85a                	sd	s6,16(sp)
    80005088:	0880                	addi	s0,sp,80
    8000508a:	84aa                	mv	s1,a0
    8000508c:	892e                	mv	s2,a1
    8000508e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005090:	ffffd097          	auipc	ra,0xffffd
    80005094:	c40080e7          	jalr	-960(ra) # 80001cd0 <myproc>
    80005098:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000509a:	8b26                	mv	s6,s1
    8000509c:	8526                	mv	a0,s1
    8000509e:	ffffc097          	auipc	ra,0xffffc
    800050a2:	b46080e7          	jalr	-1210(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050a6:	2184a703          	lw	a4,536(s1)
    800050aa:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050ae:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050b2:	02f71463          	bne	a4,a5,800050da <piperead+0x64>
    800050b6:	2244a783          	lw	a5,548(s1)
    800050ba:	c385                	beqz	a5,800050da <piperead+0x64>
    if(pr->killed){
    800050bc:	028a2783          	lw	a5,40(s4)
    800050c0:	ebc1                	bnez	a5,80005150 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050c2:	85da                	mv	a1,s6
    800050c4:	854e                	mv	a0,s3
    800050c6:	ffffd097          	auipc	ra,0xffffd
    800050ca:	47c080e7          	jalr	1148(ra) # 80002542 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050ce:	2184a703          	lw	a4,536(s1)
    800050d2:	21c4a783          	lw	a5,540(s1)
    800050d6:	fef700e3          	beq	a4,a5,800050b6 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050da:	09505263          	blez	s5,8000515e <piperead+0xe8>
    800050de:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050e0:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800050e2:	2184a783          	lw	a5,536(s1)
    800050e6:	21c4a703          	lw	a4,540(s1)
    800050ea:	02f70d63          	beq	a4,a5,80005124 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800050ee:	0017871b          	addiw	a4,a5,1
    800050f2:	20e4ac23          	sw	a4,536(s1)
    800050f6:	1ff7f793          	andi	a5,a5,511
    800050fa:	97a6                	add	a5,a5,s1
    800050fc:	0187c783          	lbu	a5,24(a5)
    80005100:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005104:	4685                	li	a3,1
    80005106:	fbf40613          	addi	a2,s0,-65
    8000510a:	85ca                	mv	a1,s2
    8000510c:	050a3503          	ld	a0,80(s4)
    80005110:	ffffc097          	auipc	ra,0xffffc
    80005114:	562080e7          	jalr	1378(ra) # 80001672 <copyout>
    80005118:	01650663          	beq	a0,s6,80005124 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000511c:	2985                	addiw	s3,s3,1
    8000511e:	0905                	addi	s2,s2,1
    80005120:	fd3a91e3          	bne	s5,s3,800050e2 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005124:	21c48513          	addi	a0,s1,540
    80005128:	ffffd097          	auipc	ra,0xffffd
    8000512c:	5b8080e7          	jalr	1464(ra) # 800026e0 <wakeup>
  release(&pi->lock);
    80005130:	8526                	mv	a0,s1
    80005132:	ffffc097          	auipc	ra,0xffffc
    80005136:	b66080e7          	jalr	-1178(ra) # 80000c98 <release>
  return i;
}
    8000513a:	854e                	mv	a0,s3
    8000513c:	60a6                	ld	ra,72(sp)
    8000513e:	6406                	ld	s0,64(sp)
    80005140:	74e2                	ld	s1,56(sp)
    80005142:	7942                	ld	s2,48(sp)
    80005144:	79a2                	ld	s3,40(sp)
    80005146:	7a02                	ld	s4,32(sp)
    80005148:	6ae2                	ld	s5,24(sp)
    8000514a:	6b42                	ld	s6,16(sp)
    8000514c:	6161                	addi	sp,sp,80
    8000514e:	8082                	ret
      release(&pi->lock);
    80005150:	8526                	mv	a0,s1
    80005152:	ffffc097          	auipc	ra,0xffffc
    80005156:	b46080e7          	jalr	-1210(ra) # 80000c98 <release>
      return -1;
    8000515a:	59fd                	li	s3,-1
    8000515c:	bff9                	j	8000513a <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000515e:	4981                	li	s3,0
    80005160:	b7d1                	j	80005124 <piperead+0xae>

0000000080005162 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005162:	df010113          	addi	sp,sp,-528
    80005166:	20113423          	sd	ra,520(sp)
    8000516a:	20813023          	sd	s0,512(sp)
    8000516e:	ffa6                	sd	s1,504(sp)
    80005170:	fbca                	sd	s2,496(sp)
    80005172:	f7ce                	sd	s3,488(sp)
    80005174:	f3d2                	sd	s4,480(sp)
    80005176:	efd6                	sd	s5,472(sp)
    80005178:	ebda                	sd	s6,464(sp)
    8000517a:	e7de                	sd	s7,456(sp)
    8000517c:	e3e2                	sd	s8,448(sp)
    8000517e:	ff66                	sd	s9,440(sp)
    80005180:	fb6a                	sd	s10,432(sp)
    80005182:	f76e                	sd	s11,424(sp)
    80005184:	0c00                	addi	s0,sp,528
    80005186:	84aa                	mv	s1,a0
    80005188:	dea43c23          	sd	a0,-520(s0)
    8000518c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005190:	ffffd097          	auipc	ra,0xffffd
    80005194:	b40080e7          	jalr	-1216(ra) # 80001cd0 <myproc>
    80005198:	892a                	mv	s2,a0

  begin_op();
    8000519a:	fffff097          	auipc	ra,0xfffff
    8000519e:	49c080e7          	jalr	1180(ra) # 80004636 <begin_op>

  if((ip = namei(path)) == 0){
    800051a2:	8526                	mv	a0,s1
    800051a4:	fffff097          	auipc	ra,0xfffff
    800051a8:	276080e7          	jalr	630(ra) # 8000441a <namei>
    800051ac:	c92d                	beqz	a0,8000521e <exec+0xbc>
    800051ae:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800051b0:	fffff097          	auipc	ra,0xfffff
    800051b4:	ab4080e7          	jalr	-1356(ra) # 80003c64 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800051b8:	04000713          	li	a4,64
    800051bc:	4681                	li	a3,0
    800051be:	e5040613          	addi	a2,s0,-432
    800051c2:	4581                	li	a1,0
    800051c4:	8526                	mv	a0,s1
    800051c6:	fffff097          	auipc	ra,0xfffff
    800051ca:	d52080e7          	jalr	-686(ra) # 80003f18 <readi>
    800051ce:	04000793          	li	a5,64
    800051d2:	00f51a63          	bne	a0,a5,800051e6 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800051d6:	e5042703          	lw	a4,-432(s0)
    800051da:	464c47b7          	lui	a5,0x464c4
    800051de:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800051e2:	04f70463          	beq	a4,a5,8000522a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800051e6:	8526                	mv	a0,s1
    800051e8:	fffff097          	auipc	ra,0xfffff
    800051ec:	cde080e7          	jalr	-802(ra) # 80003ec6 <iunlockput>
    end_op();
    800051f0:	fffff097          	auipc	ra,0xfffff
    800051f4:	4c6080e7          	jalr	1222(ra) # 800046b6 <end_op>
  }
  return -1;
    800051f8:	557d                	li	a0,-1
}
    800051fa:	20813083          	ld	ra,520(sp)
    800051fe:	20013403          	ld	s0,512(sp)
    80005202:	74fe                	ld	s1,504(sp)
    80005204:	795e                	ld	s2,496(sp)
    80005206:	79be                	ld	s3,488(sp)
    80005208:	7a1e                	ld	s4,480(sp)
    8000520a:	6afe                	ld	s5,472(sp)
    8000520c:	6b5e                	ld	s6,464(sp)
    8000520e:	6bbe                	ld	s7,456(sp)
    80005210:	6c1e                	ld	s8,448(sp)
    80005212:	7cfa                	ld	s9,440(sp)
    80005214:	7d5a                	ld	s10,432(sp)
    80005216:	7dba                	ld	s11,424(sp)
    80005218:	21010113          	addi	sp,sp,528
    8000521c:	8082                	ret
    end_op();
    8000521e:	fffff097          	auipc	ra,0xfffff
    80005222:	498080e7          	jalr	1176(ra) # 800046b6 <end_op>
    return -1;
    80005226:	557d                	li	a0,-1
    80005228:	bfc9                	j	800051fa <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000522a:	854a                	mv	a0,s2
    8000522c:	ffffd097          	auipc	ra,0xffffd
    80005230:	b62080e7          	jalr	-1182(ra) # 80001d8e <proc_pagetable>
    80005234:	8baa                	mv	s7,a0
    80005236:	d945                	beqz	a0,800051e6 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005238:	e7042983          	lw	s3,-400(s0)
    8000523c:	e8845783          	lhu	a5,-376(s0)
    80005240:	c7ad                	beqz	a5,800052aa <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005242:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005244:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005246:	6c85                	lui	s9,0x1
    80005248:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000524c:	def43823          	sd	a5,-528(s0)
    80005250:	a42d                	j	8000547a <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005252:	00003517          	auipc	a0,0x3
    80005256:	50e50513          	addi	a0,a0,1294 # 80008760 <syscalls+0x290>
    8000525a:	ffffb097          	auipc	ra,0xffffb
    8000525e:	2e4080e7          	jalr	740(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005262:	8756                	mv	a4,s5
    80005264:	012d86bb          	addw	a3,s11,s2
    80005268:	4581                	li	a1,0
    8000526a:	8526                	mv	a0,s1
    8000526c:	fffff097          	auipc	ra,0xfffff
    80005270:	cac080e7          	jalr	-852(ra) # 80003f18 <readi>
    80005274:	2501                	sext.w	a0,a0
    80005276:	1aaa9963          	bne	s5,a0,80005428 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000527a:	6785                	lui	a5,0x1
    8000527c:	0127893b          	addw	s2,a5,s2
    80005280:	77fd                	lui	a5,0xfffff
    80005282:	01478a3b          	addw	s4,a5,s4
    80005286:	1f897163          	bgeu	s2,s8,80005468 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000528a:	02091593          	slli	a1,s2,0x20
    8000528e:	9181                	srli	a1,a1,0x20
    80005290:	95ea                	add	a1,a1,s10
    80005292:	855e                	mv	a0,s7
    80005294:	ffffc097          	auipc	ra,0xffffc
    80005298:	dda080e7          	jalr	-550(ra) # 8000106e <walkaddr>
    8000529c:	862a                	mv	a2,a0
    if(pa == 0)
    8000529e:	d955                	beqz	a0,80005252 <exec+0xf0>
      n = PGSIZE;
    800052a0:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800052a2:	fd9a70e3          	bgeu	s4,s9,80005262 <exec+0x100>
      n = sz - i;
    800052a6:	8ad2                	mv	s5,s4
    800052a8:	bf6d                	j	80005262 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052aa:	4901                	li	s2,0
  iunlockput(ip);
    800052ac:	8526                	mv	a0,s1
    800052ae:	fffff097          	auipc	ra,0xfffff
    800052b2:	c18080e7          	jalr	-1000(ra) # 80003ec6 <iunlockput>
  end_op();
    800052b6:	fffff097          	auipc	ra,0xfffff
    800052ba:	400080e7          	jalr	1024(ra) # 800046b6 <end_op>
  p = myproc();
    800052be:	ffffd097          	auipc	ra,0xffffd
    800052c2:	a12080e7          	jalr	-1518(ra) # 80001cd0 <myproc>
    800052c6:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800052c8:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800052cc:	6785                	lui	a5,0x1
    800052ce:	17fd                	addi	a5,a5,-1
    800052d0:	993e                	add	s2,s2,a5
    800052d2:	757d                	lui	a0,0xfffff
    800052d4:	00a977b3          	and	a5,s2,a0
    800052d8:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800052dc:	6609                	lui	a2,0x2
    800052de:	963e                	add	a2,a2,a5
    800052e0:	85be                	mv	a1,a5
    800052e2:	855e                	mv	a0,s7
    800052e4:	ffffc097          	auipc	ra,0xffffc
    800052e8:	13e080e7          	jalr	318(ra) # 80001422 <uvmalloc>
    800052ec:	8b2a                	mv	s6,a0
  ip = 0;
    800052ee:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800052f0:	12050c63          	beqz	a0,80005428 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052f4:	75f9                	lui	a1,0xffffe
    800052f6:	95aa                	add	a1,a1,a0
    800052f8:	855e                	mv	a0,s7
    800052fa:	ffffc097          	auipc	ra,0xffffc
    800052fe:	346080e7          	jalr	838(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005302:	7c7d                	lui	s8,0xfffff
    80005304:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005306:	e0043783          	ld	a5,-512(s0)
    8000530a:	6388                	ld	a0,0(a5)
    8000530c:	c535                	beqz	a0,80005378 <exec+0x216>
    8000530e:	e9040993          	addi	s3,s0,-368
    80005312:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005316:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005318:	ffffc097          	auipc	ra,0xffffc
    8000531c:	b4c080e7          	jalr	-1204(ra) # 80000e64 <strlen>
    80005320:	2505                	addiw	a0,a0,1
    80005322:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005326:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000532a:	13896363          	bltu	s2,s8,80005450 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000532e:	e0043d83          	ld	s11,-512(s0)
    80005332:	000dba03          	ld	s4,0(s11)
    80005336:	8552                	mv	a0,s4
    80005338:	ffffc097          	auipc	ra,0xffffc
    8000533c:	b2c080e7          	jalr	-1236(ra) # 80000e64 <strlen>
    80005340:	0015069b          	addiw	a3,a0,1
    80005344:	8652                	mv	a2,s4
    80005346:	85ca                	mv	a1,s2
    80005348:	855e                	mv	a0,s7
    8000534a:	ffffc097          	auipc	ra,0xffffc
    8000534e:	328080e7          	jalr	808(ra) # 80001672 <copyout>
    80005352:	10054363          	bltz	a0,80005458 <exec+0x2f6>
    ustack[argc] = sp;
    80005356:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000535a:	0485                	addi	s1,s1,1
    8000535c:	008d8793          	addi	a5,s11,8
    80005360:	e0f43023          	sd	a5,-512(s0)
    80005364:	008db503          	ld	a0,8(s11)
    80005368:	c911                	beqz	a0,8000537c <exec+0x21a>
    if(argc >= MAXARG)
    8000536a:	09a1                	addi	s3,s3,8
    8000536c:	fb3c96e3          	bne	s9,s3,80005318 <exec+0x1b6>
  sz = sz1;
    80005370:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005374:	4481                	li	s1,0
    80005376:	a84d                	j	80005428 <exec+0x2c6>
  sp = sz;
    80005378:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000537a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000537c:	00349793          	slli	a5,s1,0x3
    80005380:	f9040713          	addi	a4,s0,-112
    80005384:	97ba                	add	a5,a5,a4
    80005386:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000538a:	00148693          	addi	a3,s1,1
    8000538e:	068e                	slli	a3,a3,0x3
    80005390:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005394:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005398:	01897663          	bgeu	s2,s8,800053a4 <exec+0x242>
  sz = sz1;
    8000539c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053a0:	4481                	li	s1,0
    800053a2:	a059                	j	80005428 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800053a4:	e9040613          	addi	a2,s0,-368
    800053a8:	85ca                	mv	a1,s2
    800053aa:	855e                	mv	a0,s7
    800053ac:	ffffc097          	auipc	ra,0xffffc
    800053b0:	2c6080e7          	jalr	710(ra) # 80001672 <copyout>
    800053b4:	0a054663          	bltz	a0,80005460 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800053b8:	058ab783          	ld	a5,88(s5)
    800053bc:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800053c0:	df843783          	ld	a5,-520(s0)
    800053c4:	0007c703          	lbu	a4,0(a5)
    800053c8:	cf11                	beqz	a4,800053e4 <exec+0x282>
    800053ca:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053cc:	02f00693          	li	a3,47
    800053d0:	a039                	j	800053de <exec+0x27c>
      last = s+1;
    800053d2:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800053d6:	0785                	addi	a5,a5,1
    800053d8:	fff7c703          	lbu	a4,-1(a5)
    800053dc:	c701                	beqz	a4,800053e4 <exec+0x282>
    if(*s == '/')
    800053de:	fed71ce3          	bne	a4,a3,800053d6 <exec+0x274>
    800053e2:	bfc5                	j	800053d2 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800053e4:	4641                	li	a2,16
    800053e6:	df843583          	ld	a1,-520(s0)
    800053ea:	158a8513          	addi	a0,s5,344
    800053ee:	ffffc097          	auipc	ra,0xffffc
    800053f2:	a44080e7          	jalr	-1468(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800053f6:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800053fa:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800053fe:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005402:	058ab783          	ld	a5,88(s5)
    80005406:	e6843703          	ld	a4,-408(s0)
    8000540a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000540c:	058ab783          	ld	a5,88(s5)
    80005410:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005414:	85ea                	mv	a1,s10
    80005416:	ffffd097          	auipc	ra,0xffffd
    8000541a:	a14080e7          	jalr	-1516(ra) # 80001e2a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000541e:	0004851b          	sext.w	a0,s1
    80005422:	bbe1                	j	800051fa <exec+0x98>
    80005424:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005428:	e0843583          	ld	a1,-504(s0)
    8000542c:	855e                	mv	a0,s7
    8000542e:	ffffd097          	auipc	ra,0xffffd
    80005432:	9fc080e7          	jalr	-1540(ra) # 80001e2a <proc_freepagetable>
  if(ip){
    80005436:	da0498e3          	bnez	s1,800051e6 <exec+0x84>
  return -1;
    8000543a:	557d                	li	a0,-1
    8000543c:	bb7d                	j	800051fa <exec+0x98>
    8000543e:	e1243423          	sd	s2,-504(s0)
    80005442:	b7dd                	j	80005428 <exec+0x2c6>
    80005444:	e1243423          	sd	s2,-504(s0)
    80005448:	b7c5                	j	80005428 <exec+0x2c6>
    8000544a:	e1243423          	sd	s2,-504(s0)
    8000544e:	bfe9                	j	80005428 <exec+0x2c6>
  sz = sz1;
    80005450:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005454:	4481                	li	s1,0
    80005456:	bfc9                	j	80005428 <exec+0x2c6>
  sz = sz1;
    80005458:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000545c:	4481                	li	s1,0
    8000545e:	b7e9                	j	80005428 <exec+0x2c6>
  sz = sz1;
    80005460:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005464:	4481                	li	s1,0
    80005466:	b7c9                	j	80005428 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005468:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000546c:	2b05                	addiw	s6,s6,1
    8000546e:	0389899b          	addiw	s3,s3,56
    80005472:	e8845783          	lhu	a5,-376(s0)
    80005476:	e2fb5be3          	bge	s6,a5,800052ac <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000547a:	2981                	sext.w	s3,s3
    8000547c:	03800713          	li	a4,56
    80005480:	86ce                	mv	a3,s3
    80005482:	e1840613          	addi	a2,s0,-488
    80005486:	4581                	li	a1,0
    80005488:	8526                	mv	a0,s1
    8000548a:	fffff097          	auipc	ra,0xfffff
    8000548e:	a8e080e7          	jalr	-1394(ra) # 80003f18 <readi>
    80005492:	03800793          	li	a5,56
    80005496:	f8f517e3          	bne	a0,a5,80005424 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000549a:	e1842783          	lw	a5,-488(s0)
    8000549e:	4705                	li	a4,1
    800054a0:	fce796e3          	bne	a5,a4,8000546c <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800054a4:	e4043603          	ld	a2,-448(s0)
    800054a8:	e3843783          	ld	a5,-456(s0)
    800054ac:	f8f669e3          	bltu	a2,a5,8000543e <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800054b0:	e2843783          	ld	a5,-472(s0)
    800054b4:	963e                	add	a2,a2,a5
    800054b6:	f8f667e3          	bltu	a2,a5,80005444 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800054ba:	85ca                	mv	a1,s2
    800054bc:	855e                	mv	a0,s7
    800054be:	ffffc097          	auipc	ra,0xffffc
    800054c2:	f64080e7          	jalr	-156(ra) # 80001422 <uvmalloc>
    800054c6:	e0a43423          	sd	a0,-504(s0)
    800054ca:	d141                	beqz	a0,8000544a <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800054cc:	e2843d03          	ld	s10,-472(s0)
    800054d0:	df043783          	ld	a5,-528(s0)
    800054d4:	00fd77b3          	and	a5,s10,a5
    800054d8:	fba1                	bnez	a5,80005428 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800054da:	e2042d83          	lw	s11,-480(s0)
    800054de:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800054e2:	f80c03e3          	beqz	s8,80005468 <exec+0x306>
    800054e6:	8a62                	mv	s4,s8
    800054e8:	4901                	li	s2,0
    800054ea:	b345                	j	8000528a <exec+0x128>

00000000800054ec <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800054ec:	7179                	addi	sp,sp,-48
    800054ee:	f406                	sd	ra,40(sp)
    800054f0:	f022                	sd	s0,32(sp)
    800054f2:	ec26                	sd	s1,24(sp)
    800054f4:	e84a                	sd	s2,16(sp)
    800054f6:	1800                	addi	s0,sp,48
    800054f8:	892e                	mv	s2,a1
    800054fa:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800054fc:	fdc40593          	addi	a1,s0,-36
    80005500:	ffffe097          	auipc	ra,0xffffe
    80005504:	ba8080e7          	jalr	-1112(ra) # 800030a8 <argint>
    80005508:	04054063          	bltz	a0,80005548 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000550c:	fdc42703          	lw	a4,-36(s0)
    80005510:	47bd                	li	a5,15
    80005512:	02e7ed63          	bltu	a5,a4,8000554c <argfd+0x60>
    80005516:	ffffc097          	auipc	ra,0xffffc
    8000551a:	7ba080e7          	jalr	1978(ra) # 80001cd0 <myproc>
    8000551e:	fdc42703          	lw	a4,-36(s0)
    80005522:	01a70793          	addi	a5,a4,26
    80005526:	078e                	slli	a5,a5,0x3
    80005528:	953e                	add	a0,a0,a5
    8000552a:	611c                	ld	a5,0(a0)
    8000552c:	c395                	beqz	a5,80005550 <argfd+0x64>
    return -1;
  if(pfd)
    8000552e:	00090463          	beqz	s2,80005536 <argfd+0x4a>
    *pfd = fd;
    80005532:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005536:	4501                	li	a0,0
  if(pf)
    80005538:	c091                	beqz	s1,8000553c <argfd+0x50>
    *pf = f;
    8000553a:	e09c                	sd	a5,0(s1)
}
    8000553c:	70a2                	ld	ra,40(sp)
    8000553e:	7402                	ld	s0,32(sp)
    80005540:	64e2                	ld	s1,24(sp)
    80005542:	6942                	ld	s2,16(sp)
    80005544:	6145                	addi	sp,sp,48
    80005546:	8082                	ret
    return -1;
    80005548:	557d                	li	a0,-1
    8000554a:	bfcd                	j	8000553c <argfd+0x50>
    return -1;
    8000554c:	557d                	li	a0,-1
    8000554e:	b7fd                	j	8000553c <argfd+0x50>
    80005550:	557d                	li	a0,-1
    80005552:	b7ed                	j	8000553c <argfd+0x50>

0000000080005554 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005554:	1101                	addi	sp,sp,-32
    80005556:	ec06                	sd	ra,24(sp)
    80005558:	e822                	sd	s0,16(sp)
    8000555a:	e426                	sd	s1,8(sp)
    8000555c:	1000                	addi	s0,sp,32
    8000555e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005560:	ffffc097          	auipc	ra,0xffffc
    80005564:	770080e7          	jalr	1904(ra) # 80001cd0 <myproc>
    80005568:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000556a:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000556e:	4501                	li	a0,0
    80005570:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005572:	6398                	ld	a4,0(a5)
    80005574:	cb19                	beqz	a4,8000558a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005576:	2505                	addiw	a0,a0,1
    80005578:	07a1                	addi	a5,a5,8
    8000557a:	fed51ce3          	bne	a0,a3,80005572 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000557e:	557d                	li	a0,-1
}
    80005580:	60e2                	ld	ra,24(sp)
    80005582:	6442                	ld	s0,16(sp)
    80005584:	64a2                	ld	s1,8(sp)
    80005586:	6105                	addi	sp,sp,32
    80005588:	8082                	ret
      p->ofile[fd] = f;
    8000558a:	01a50793          	addi	a5,a0,26
    8000558e:	078e                	slli	a5,a5,0x3
    80005590:	963e                	add	a2,a2,a5
    80005592:	e204                	sd	s1,0(a2)
      return fd;
    80005594:	b7f5                	j	80005580 <fdalloc+0x2c>

0000000080005596 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005596:	715d                	addi	sp,sp,-80
    80005598:	e486                	sd	ra,72(sp)
    8000559a:	e0a2                	sd	s0,64(sp)
    8000559c:	fc26                	sd	s1,56(sp)
    8000559e:	f84a                	sd	s2,48(sp)
    800055a0:	f44e                	sd	s3,40(sp)
    800055a2:	f052                	sd	s4,32(sp)
    800055a4:	ec56                	sd	s5,24(sp)
    800055a6:	0880                	addi	s0,sp,80
    800055a8:	89ae                	mv	s3,a1
    800055aa:	8ab2                	mv	s5,a2
    800055ac:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055ae:	fb040593          	addi	a1,s0,-80
    800055b2:	fffff097          	auipc	ra,0xfffff
    800055b6:	e86080e7          	jalr	-378(ra) # 80004438 <nameiparent>
    800055ba:	892a                	mv	s2,a0
    800055bc:	12050f63          	beqz	a0,800056fa <create+0x164>
    return 0;

  ilock(dp);
    800055c0:	ffffe097          	auipc	ra,0xffffe
    800055c4:	6a4080e7          	jalr	1700(ra) # 80003c64 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800055c8:	4601                	li	a2,0
    800055ca:	fb040593          	addi	a1,s0,-80
    800055ce:	854a                	mv	a0,s2
    800055d0:	fffff097          	auipc	ra,0xfffff
    800055d4:	b78080e7          	jalr	-1160(ra) # 80004148 <dirlookup>
    800055d8:	84aa                	mv	s1,a0
    800055da:	c921                	beqz	a0,8000562a <create+0x94>
    iunlockput(dp);
    800055dc:	854a                	mv	a0,s2
    800055de:	fffff097          	auipc	ra,0xfffff
    800055e2:	8e8080e7          	jalr	-1816(ra) # 80003ec6 <iunlockput>
    ilock(ip);
    800055e6:	8526                	mv	a0,s1
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	67c080e7          	jalr	1660(ra) # 80003c64 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800055f0:	2981                	sext.w	s3,s3
    800055f2:	4789                	li	a5,2
    800055f4:	02f99463          	bne	s3,a5,8000561c <create+0x86>
    800055f8:	0444d783          	lhu	a5,68(s1)
    800055fc:	37f9                	addiw	a5,a5,-2
    800055fe:	17c2                	slli	a5,a5,0x30
    80005600:	93c1                	srli	a5,a5,0x30
    80005602:	4705                	li	a4,1
    80005604:	00f76c63          	bltu	a4,a5,8000561c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005608:	8526                	mv	a0,s1
    8000560a:	60a6                	ld	ra,72(sp)
    8000560c:	6406                	ld	s0,64(sp)
    8000560e:	74e2                	ld	s1,56(sp)
    80005610:	7942                	ld	s2,48(sp)
    80005612:	79a2                	ld	s3,40(sp)
    80005614:	7a02                	ld	s4,32(sp)
    80005616:	6ae2                	ld	s5,24(sp)
    80005618:	6161                	addi	sp,sp,80
    8000561a:	8082                	ret
    iunlockput(ip);
    8000561c:	8526                	mv	a0,s1
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	8a8080e7          	jalr	-1880(ra) # 80003ec6 <iunlockput>
    return 0;
    80005626:	4481                	li	s1,0
    80005628:	b7c5                	j	80005608 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000562a:	85ce                	mv	a1,s3
    8000562c:	00092503          	lw	a0,0(s2)
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	49c080e7          	jalr	1180(ra) # 80003acc <ialloc>
    80005638:	84aa                	mv	s1,a0
    8000563a:	c529                	beqz	a0,80005684 <create+0xee>
  ilock(ip);
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	628080e7          	jalr	1576(ra) # 80003c64 <ilock>
  ip->major = major;
    80005644:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005648:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000564c:	4785                	li	a5,1
    8000564e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005652:	8526                	mv	a0,s1
    80005654:	ffffe097          	auipc	ra,0xffffe
    80005658:	546080e7          	jalr	1350(ra) # 80003b9a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000565c:	2981                	sext.w	s3,s3
    8000565e:	4785                	li	a5,1
    80005660:	02f98a63          	beq	s3,a5,80005694 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005664:	40d0                	lw	a2,4(s1)
    80005666:	fb040593          	addi	a1,s0,-80
    8000566a:	854a                	mv	a0,s2
    8000566c:	fffff097          	auipc	ra,0xfffff
    80005670:	cec080e7          	jalr	-788(ra) # 80004358 <dirlink>
    80005674:	06054b63          	bltz	a0,800056ea <create+0x154>
  iunlockput(dp);
    80005678:	854a                	mv	a0,s2
    8000567a:	fffff097          	auipc	ra,0xfffff
    8000567e:	84c080e7          	jalr	-1972(ra) # 80003ec6 <iunlockput>
  return ip;
    80005682:	b759                	j	80005608 <create+0x72>
    panic("create: ialloc");
    80005684:	00003517          	auipc	a0,0x3
    80005688:	0fc50513          	addi	a0,a0,252 # 80008780 <syscalls+0x2b0>
    8000568c:	ffffb097          	auipc	ra,0xffffb
    80005690:	eb2080e7          	jalr	-334(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005694:	04a95783          	lhu	a5,74(s2)
    80005698:	2785                	addiw	a5,a5,1
    8000569a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000569e:	854a                	mv	a0,s2
    800056a0:	ffffe097          	auipc	ra,0xffffe
    800056a4:	4fa080e7          	jalr	1274(ra) # 80003b9a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800056a8:	40d0                	lw	a2,4(s1)
    800056aa:	00003597          	auipc	a1,0x3
    800056ae:	0e658593          	addi	a1,a1,230 # 80008790 <syscalls+0x2c0>
    800056b2:	8526                	mv	a0,s1
    800056b4:	fffff097          	auipc	ra,0xfffff
    800056b8:	ca4080e7          	jalr	-860(ra) # 80004358 <dirlink>
    800056bc:	00054f63          	bltz	a0,800056da <create+0x144>
    800056c0:	00492603          	lw	a2,4(s2)
    800056c4:	00003597          	auipc	a1,0x3
    800056c8:	0d458593          	addi	a1,a1,212 # 80008798 <syscalls+0x2c8>
    800056cc:	8526                	mv	a0,s1
    800056ce:	fffff097          	auipc	ra,0xfffff
    800056d2:	c8a080e7          	jalr	-886(ra) # 80004358 <dirlink>
    800056d6:	f80557e3          	bgez	a0,80005664 <create+0xce>
      panic("create dots");
    800056da:	00003517          	auipc	a0,0x3
    800056de:	0c650513          	addi	a0,a0,198 # 800087a0 <syscalls+0x2d0>
    800056e2:	ffffb097          	auipc	ra,0xffffb
    800056e6:	e5c080e7          	jalr	-420(ra) # 8000053e <panic>
    panic("create: dirlink");
    800056ea:	00003517          	auipc	a0,0x3
    800056ee:	0c650513          	addi	a0,a0,198 # 800087b0 <syscalls+0x2e0>
    800056f2:	ffffb097          	auipc	ra,0xffffb
    800056f6:	e4c080e7          	jalr	-436(ra) # 8000053e <panic>
    return 0;
    800056fa:	84aa                	mv	s1,a0
    800056fc:	b731                	j	80005608 <create+0x72>

00000000800056fe <sys_dup>:
{
    800056fe:	7179                	addi	sp,sp,-48
    80005700:	f406                	sd	ra,40(sp)
    80005702:	f022                	sd	s0,32(sp)
    80005704:	ec26                	sd	s1,24(sp)
    80005706:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005708:	fd840613          	addi	a2,s0,-40
    8000570c:	4581                	li	a1,0
    8000570e:	4501                	li	a0,0
    80005710:	00000097          	auipc	ra,0x0
    80005714:	ddc080e7          	jalr	-548(ra) # 800054ec <argfd>
    return -1;
    80005718:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000571a:	02054363          	bltz	a0,80005740 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000571e:	fd843503          	ld	a0,-40(s0)
    80005722:	00000097          	auipc	ra,0x0
    80005726:	e32080e7          	jalr	-462(ra) # 80005554 <fdalloc>
    8000572a:	84aa                	mv	s1,a0
    return -1;
    8000572c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000572e:	00054963          	bltz	a0,80005740 <sys_dup+0x42>
  filedup(f);
    80005732:	fd843503          	ld	a0,-40(s0)
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	37a080e7          	jalr	890(ra) # 80004ab0 <filedup>
  return fd;
    8000573e:	87a6                	mv	a5,s1
}
    80005740:	853e                	mv	a0,a5
    80005742:	70a2                	ld	ra,40(sp)
    80005744:	7402                	ld	s0,32(sp)
    80005746:	64e2                	ld	s1,24(sp)
    80005748:	6145                	addi	sp,sp,48
    8000574a:	8082                	ret

000000008000574c <sys_read>:
{
    8000574c:	7179                	addi	sp,sp,-48
    8000574e:	f406                	sd	ra,40(sp)
    80005750:	f022                	sd	s0,32(sp)
    80005752:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005754:	fe840613          	addi	a2,s0,-24
    80005758:	4581                	li	a1,0
    8000575a:	4501                	li	a0,0
    8000575c:	00000097          	auipc	ra,0x0
    80005760:	d90080e7          	jalr	-624(ra) # 800054ec <argfd>
    return -1;
    80005764:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005766:	04054163          	bltz	a0,800057a8 <sys_read+0x5c>
    8000576a:	fe440593          	addi	a1,s0,-28
    8000576e:	4509                	li	a0,2
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	938080e7          	jalr	-1736(ra) # 800030a8 <argint>
    return -1;
    80005778:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000577a:	02054763          	bltz	a0,800057a8 <sys_read+0x5c>
    8000577e:	fd840593          	addi	a1,s0,-40
    80005782:	4505                	li	a0,1
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	946080e7          	jalr	-1722(ra) # 800030ca <argaddr>
    return -1;
    8000578c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000578e:	00054d63          	bltz	a0,800057a8 <sys_read+0x5c>
  return fileread(f, p, n);
    80005792:	fe442603          	lw	a2,-28(s0)
    80005796:	fd843583          	ld	a1,-40(s0)
    8000579a:	fe843503          	ld	a0,-24(s0)
    8000579e:	fffff097          	auipc	ra,0xfffff
    800057a2:	49e080e7          	jalr	1182(ra) # 80004c3c <fileread>
    800057a6:	87aa                	mv	a5,a0
}
    800057a8:	853e                	mv	a0,a5
    800057aa:	70a2                	ld	ra,40(sp)
    800057ac:	7402                	ld	s0,32(sp)
    800057ae:	6145                	addi	sp,sp,48
    800057b0:	8082                	ret

00000000800057b2 <sys_write>:
{
    800057b2:	7179                	addi	sp,sp,-48
    800057b4:	f406                	sd	ra,40(sp)
    800057b6:	f022                	sd	s0,32(sp)
    800057b8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057ba:	fe840613          	addi	a2,s0,-24
    800057be:	4581                	li	a1,0
    800057c0:	4501                	li	a0,0
    800057c2:	00000097          	auipc	ra,0x0
    800057c6:	d2a080e7          	jalr	-726(ra) # 800054ec <argfd>
    return -1;
    800057ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057cc:	04054163          	bltz	a0,8000580e <sys_write+0x5c>
    800057d0:	fe440593          	addi	a1,s0,-28
    800057d4:	4509                	li	a0,2
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	8d2080e7          	jalr	-1838(ra) # 800030a8 <argint>
    return -1;
    800057de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057e0:	02054763          	bltz	a0,8000580e <sys_write+0x5c>
    800057e4:	fd840593          	addi	a1,s0,-40
    800057e8:	4505                	li	a0,1
    800057ea:	ffffe097          	auipc	ra,0xffffe
    800057ee:	8e0080e7          	jalr	-1824(ra) # 800030ca <argaddr>
    return -1;
    800057f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057f4:	00054d63          	bltz	a0,8000580e <sys_write+0x5c>
  return filewrite(f, p, n);
    800057f8:	fe442603          	lw	a2,-28(s0)
    800057fc:	fd843583          	ld	a1,-40(s0)
    80005800:	fe843503          	ld	a0,-24(s0)
    80005804:	fffff097          	auipc	ra,0xfffff
    80005808:	4fa080e7          	jalr	1274(ra) # 80004cfe <filewrite>
    8000580c:	87aa                	mv	a5,a0
}
    8000580e:	853e                	mv	a0,a5
    80005810:	70a2                	ld	ra,40(sp)
    80005812:	7402                	ld	s0,32(sp)
    80005814:	6145                	addi	sp,sp,48
    80005816:	8082                	ret

0000000080005818 <sys_close>:
{
    80005818:	1101                	addi	sp,sp,-32
    8000581a:	ec06                	sd	ra,24(sp)
    8000581c:	e822                	sd	s0,16(sp)
    8000581e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005820:	fe040613          	addi	a2,s0,-32
    80005824:	fec40593          	addi	a1,s0,-20
    80005828:	4501                	li	a0,0
    8000582a:	00000097          	auipc	ra,0x0
    8000582e:	cc2080e7          	jalr	-830(ra) # 800054ec <argfd>
    return -1;
    80005832:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005834:	02054463          	bltz	a0,8000585c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005838:	ffffc097          	auipc	ra,0xffffc
    8000583c:	498080e7          	jalr	1176(ra) # 80001cd0 <myproc>
    80005840:	fec42783          	lw	a5,-20(s0)
    80005844:	07e9                	addi	a5,a5,26
    80005846:	078e                	slli	a5,a5,0x3
    80005848:	97aa                	add	a5,a5,a0
    8000584a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000584e:	fe043503          	ld	a0,-32(s0)
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	2b0080e7          	jalr	688(ra) # 80004b02 <fileclose>
  return 0;
    8000585a:	4781                	li	a5,0
}
    8000585c:	853e                	mv	a0,a5
    8000585e:	60e2                	ld	ra,24(sp)
    80005860:	6442                	ld	s0,16(sp)
    80005862:	6105                	addi	sp,sp,32
    80005864:	8082                	ret

0000000080005866 <sys_fstat>:
{
    80005866:	1101                	addi	sp,sp,-32
    80005868:	ec06                	sd	ra,24(sp)
    8000586a:	e822                	sd	s0,16(sp)
    8000586c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000586e:	fe840613          	addi	a2,s0,-24
    80005872:	4581                	li	a1,0
    80005874:	4501                	li	a0,0
    80005876:	00000097          	auipc	ra,0x0
    8000587a:	c76080e7          	jalr	-906(ra) # 800054ec <argfd>
    return -1;
    8000587e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005880:	02054563          	bltz	a0,800058aa <sys_fstat+0x44>
    80005884:	fe040593          	addi	a1,s0,-32
    80005888:	4505                	li	a0,1
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	840080e7          	jalr	-1984(ra) # 800030ca <argaddr>
    return -1;
    80005892:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005894:	00054b63          	bltz	a0,800058aa <sys_fstat+0x44>
  return filestat(f, st);
    80005898:	fe043583          	ld	a1,-32(s0)
    8000589c:	fe843503          	ld	a0,-24(s0)
    800058a0:	fffff097          	auipc	ra,0xfffff
    800058a4:	32a080e7          	jalr	810(ra) # 80004bca <filestat>
    800058a8:	87aa                	mv	a5,a0
}
    800058aa:	853e                	mv	a0,a5
    800058ac:	60e2                	ld	ra,24(sp)
    800058ae:	6442                	ld	s0,16(sp)
    800058b0:	6105                	addi	sp,sp,32
    800058b2:	8082                	ret

00000000800058b4 <sys_link>:
{
    800058b4:	7169                	addi	sp,sp,-304
    800058b6:	f606                	sd	ra,296(sp)
    800058b8:	f222                	sd	s0,288(sp)
    800058ba:	ee26                	sd	s1,280(sp)
    800058bc:	ea4a                	sd	s2,272(sp)
    800058be:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058c0:	08000613          	li	a2,128
    800058c4:	ed040593          	addi	a1,s0,-304
    800058c8:	4501                	li	a0,0
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	822080e7          	jalr	-2014(ra) # 800030ec <argstr>
    return -1;
    800058d2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058d4:	10054e63          	bltz	a0,800059f0 <sys_link+0x13c>
    800058d8:	08000613          	li	a2,128
    800058dc:	f5040593          	addi	a1,s0,-176
    800058e0:	4505                	li	a0,1
    800058e2:	ffffe097          	auipc	ra,0xffffe
    800058e6:	80a080e7          	jalr	-2038(ra) # 800030ec <argstr>
    return -1;
    800058ea:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058ec:	10054263          	bltz	a0,800059f0 <sys_link+0x13c>
  begin_op();
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	d46080e7          	jalr	-698(ra) # 80004636 <begin_op>
  if((ip = namei(old)) == 0){
    800058f8:	ed040513          	addi	a0,s0,-304
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	b1e080e7          	jalr	-1250(ra) # 8000441a <namei>
    80005904:	84aa                	mv	s1,a0
    80005906:	c551                	beqz	a0,80005992 <sys_link+0xde>
  ilock(ip);
    80005908:	ffffe097          	auipc	ra,0xffffe
    8000590c:	35c080e7          	jalr	860(ra) # 80003c64 <ilock>
  if(ip->type == T_DIR){
    80005910:	04449703          	lh	a4,68(s1)
    80005914:	4785                	li	a5,1
    80005916:	08f70463          	beq	a4,a5,8000599e <sys_link+0xea>
  ip->nlink++;
    8000591a:	04a4d783          	lhu	a5,74(s1)
    8000591e:	2785                	addiw	a5,a5,1
    80005920:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005924:	8526                	mv	a0,s1
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	274080e7          	jalr	628(ra) # 80003b9a <iupdate>
  iunlock(ip);
    8000592e:	8526                	mv	a0,s1
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	3f6080e7          	jalr	1014(ra) # 80003d26 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005938:	fd040593          	addi	a1,s0,-48
    8000593c:	f5040513          	addi	a0,s0,-176
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	af8080e7          	jalr	-1288(ra) # 80004438 <nameiparent>
    80005948:	892a                	mv	s2,a0
    8000594a:	c935                	beqz	a0,800059be <sys_link+0x10a>
  ilock(dp);
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	318080e7          	jalr	792(ra) # 80003c64 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005954:	00092703          	lw	a4,0(s2)
    80005958:	409c                	lw	a5,0(s1)
    8000595a:	04f71d63          	bne	a4,a5,800059b4 <sys_link+0x100>
    8000595e:	40d0                	lw	a2,4(s1)
    80005960:	fd040593          	addi	a1,s0,-48
    80005964:	854a                	mv	a0,s2
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	9f2080e7          	jalr	-1550(ra) # 80004358 <dirlink>
    8000596e:	04054363          	bltz	a0,800059b4 <sys_link+0x100>
  iunlockput(dp);
    80005972:	854a                	mv	a0,s2
    80005974:	ffffe097          	auipc	ra,0xffffe
    80005978:	552080e7          	jalr	1362(ra) # 80003ec6 <iunlockput>
  iput(ip);
    8000597c:	8526                	mv	a0,s1
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	4a0080e7          	jalr	1184(ra) # 80003e1e <iput>
  end_op();
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	d30080e7          	jalr	-720(ra) # 800046b6 <end_op>
  return 0;
    8000598e:	4781                	li	a5,0
    80005990:	a085                	j	800059f0 <sys_link+0x13c>
    end_op();
    80005992:	fffff097          	auipc	ra,0xfffff
    80005996:	d24080e7          	jalr	-732(ra) # 800046b6 <end_op>
    return -1;
    8000599a:	57fd                	li	a5,-1
    8000599c:	a891                	j	800059f0 <sys_link+0x13c>
    iunlockput(ip);
    8000599e:	8526                	mv	a0,s1
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	526080e7          	jalr	1318(ra) # 80003ec6 <iunlockput>
    end_op();
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	d0e080e7          	jalr	-754(ra) # 800046b6 <end_op>
    return -1;
    800059b0:	57fd                	li	a5,-1
    800059b2:	a83d                	j	800059f0 <sys_link+0x13c>
    iunlockput(dp);
    800059b4:	854a                	mv	a0,s2
    800059b6:	ffffe097          	auipc	ra,0xffffe
    800059ba:	510080e7          	jalr	1296(ra) # 80003ec6 <iunlockput>
  ilock(ip);
    800059be:	8526                	mv	a0,s1
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	2a4080e7          	jalr	676(ra) # 80003c64 <ilock>
  ip->nlink--;
    800059c8:	04a4d783          	lhu	a5,74(s1)
    800059cc:	37fd                	addiw	a5,a5,-1
    800059ce:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059d2:	8526                	mv	a0,s1
    800059d4:	ffffe097          	auipc	ra,0xffffe
    800059d8:	1c6080e7          	jalr	454(ra) # 80003b9a <iupdate>
  iunlockput(ip);
    800059dc:	8526                	mv	a0,s1
    800059de:	ffffe097          	auipc	ra,0xffffe
    800059e2:	4e8080e7          	jalr	1256(ra) # 80003ec6 <iunlockput>
  end_op();
    800059e6:	fffff097          	auipc	ra,0xfffff
    800059ea:	cd0080e7          	jalr	-816(ra) # 800046b6 <end_op>
  return -1;
    800059ee:	57fd                	li	a5,-1
}
    800059f0:	853e                	mv	a0,a5
    800059f2:	70b2                	ld	ra,296(sp)
    800059f4:	7412                	ld	s0,288(sp)
    800059f6:	64f2                	ld	s1,280(sp)
    800059f8:	6952                	ld	s2,272(sp)
    800059fa:	6155                	addi	sp,sp,304
    800059fc:	8082                	ret

00000000800059fe <sys_unlink>:
{
    800059fe:	7151                	addi	sp,sp,-240
    80005a00:	f586                	sd	ra,232(sp)
    80005a02:	f1a2                	sd	s0,224(sp)
    80005a04:	eda6                	sd	s1,216(sp)
    80005a06:	e9ca                	sd	s2,208(sp)
    80005a08:	e5ce                	sd	s3,200(sp)
    80005a0a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a0c:	08000613          	li	a2,128
    80005a10:	f3040593          	addi	a1,s0,-208
    80005a14:	4501                	li	a0,0
    80005a16:	ffffd097          	auipc	ra,0xffffd
    80005a1a:	6d6080e7          	jalr	1750(ra) # 800030ec <argstr>
    80005a1e:	18054163          	bltz	a0,80005ba0 <sys_unlink+0x1a2>
  begin_op();
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	c14080e7          	jalr	-1004(ra) # 80004636 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a2a:	fb040593          	addi	a1,s0,-80
    80005a2e:	f3040513          	addi	a0,s0,-208
    80005a32:	fffff097          	auipc	ra,0xfffff
    80005a36:	a06080e7          	jalr	-1530(ra) # 80004438 <nameiparent>
    80005a3a:	84aa                	mv	s1,a0
    80005a3c:	c979                	beqz	a0,80005b12 <sys_unlink+0x114>
  ilock(dp);
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	226080e7          	jalr	550(ra) # 80003c64 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a46:	00003597          	auipc	a1,0x3
    80005a4a:	d4a58593          	addi	a1,a1,-694 # 80008790 <syscalls+0x2c0>
    80005a4e:	fb040513          	addi	a0,s0,-80
    80005a52:	ffffe097          	auipc	ra,0xffffe
    80005a56:	6dc080e7          	jalr	1756(ra) # 8000412e <namecmp>
    80005a5a:	14050a63          	beqz	a0,80005bae <sys_unlink+0x1b0>
    80005a5e:	00003597          	auipc	a1,0x3
    80005a62:	d3a58593          	addi	a1,a1,-710 # 80008798 <syscalls+0x2c8>
    80005a66:	fb040513          	addi	a0,s0,-80
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	6c4080e7          	jalr	1732(ra) # 8000412e <namecmp>
    80005a72:	12050e63          	beqz	a0,80005bae <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a76:	f2c40613          	addi	a2,s0,-212
    80005a7a:	fb040593          	addi	a1,s0,-80
    80005a7e:	8526                	mv	a0,s1
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	6c8080e7          	jalr	1736(ra) # 80004148 <dirlookup>
    80005a88:	892a                	mv	s2,a0
    80005a8a:	12050263          	beqz	a0,80005bae <sys_unlink+0x1b0>
  ilock(ip);
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	1d6080e7          	jalr	470(ra) # 80003c64 <ilock>
  if(ip->nlink < 1)
    80005a96:	04a91783          	lh	a5,74(s2)
    80005a9a:	08f05263          	blez	a5,80005b1e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a9e:	04491703          	lh	a4,68(s2)
    80005aa2:	4785                	li	a5,1
    80005aa4:	08f70563          	beq	a4,a5,80005b2e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005aa8:	4641                	li	a2,16
    80005aaa:	4581                	li	a1,0
    80005aac:	fc040513          	addi	a0,s0,-64
    80005ab0:	ffffb097          	auipc	ra,0xffffb
    80005ab4:	230080e7          	jalr	560(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ab8:	4741                	li	a4,16
    80005aba:	f2c42683          	lw	a3,-212(s0)
    80005abe:	fc040613          	addi	a2,s0,-64
    80005ac2:	4581                	li	a1,0
    80005ac4:	8526                	mv	a0,s1
    80005ac6:	ffffe097          	auipc	ra,0xffffe
    80005aca:	54a080e7          	jalr	1354(ra) # 80004010 <writei>
    80005ace:	47c1                	li	a5,16
    80005ad0:	0af51563          	bne	a0,a5,80005b7a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005ad4:	04491703          	lh	a4,68(s2)
    80005ad8:	4785                	li	a5,1
    80005ada:	0af70863          	beq	a4,a5,80005b8a <sys_unlink+0x18c>
  iunlockput(dp);
    80005ade:	8526                	mv	a0,s1
    80005ae0:	ffffe097          	auipc	ra,0xffffe
    80005ae4:	3e6080e7          	jalr	998(ra) # 80003ec6 <iunlockput>
  ip->nlink--;
    80005ae8:	04a95783          	lhu	a5,74(s2)
    80005aec:	37fd                	addiw	a5,a5,-1
    80005aee:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005af2:	854a                	mv	a0,s2
    80005af4:	ffffe097          	auipc	ra,0xffffe
    80005af8:	0a6080e7          	jalr	166(ra) # 80003b9a <iupdate>
  iunlockput(ip);
    80005afc:	854a                	mv	a0,s2
    80005afe:	ffffe097          	auipc	ra,0xffffe
    80005b02:	3c8080e7          	jalr	968(ra) # 80003ec6 <iunlockput>
  end_op();
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	bb0080e7          	jalr	-1104(ra) # 800046b6 <end_op>
  return 0;
    80005b0e:	4501                	li	a0,0
    80005b10:	a84d                	j	80005bc2 <sys_unlink+0x1c4>
    end_op();
    80005b12:	fffff097          	auipc	ra,0xfffff
    80005b16:	ba4080e7          	jalr	-1116(ra) # 800046b6 <end_op>
    return -1;
    80005b1a:	557d                	li	a0,-1
    80005b1c:	a05d                	j	80005bc2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b1e:	00003517          	auipc	a0,0x3
    80005b22:	ca250513          	addi	a0,a0,-862 # 800087c0 <syscalls+0x2f0>
    80005b26:	ffffb097          	auipc	ra,0xffffb
    80005b2a:	a18080e7          	jalr	-1512(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b2e:	04c92703          	lw	a4,76(s2)
    80005b32:	02000793          	li	a5,32
    80005b36:	f6e7f9e3          	bgeu	a5,a4,80005aa8 <sys_unlink+0xaa>
    80005b3a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b3e:	4741                	li	a4,16
    80005b40:	86ce                	mv	a3,s3
    80005b42:	f1840613          	addi	a2,s0,-232
    80005b46:	4581                	li	a1,0
    80005b48:	854a                	mv	a0,s2
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	3ce080e7          	jalr	974(ra) # 80003f18 <readi>
    80005b52:	47c1                	li	a5,16
    80005b54:	00f51b63          	bne	a0,a5,80005b6a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b58:	f1845783          	lhu	a5,-232(s0)
    80005b5c:	e7a1                	bnez	a5,80005ba4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b5e:	29c1                	addiw	s3,s3,16
    80005b60:	04c92783          	lw	a5,76(s2)
    80005b64:	fcf9ede3          	bltu	s3,a5,80005b3e <sys_unlink+0x140>
    80005b68:	b781                	j	80005aa8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b6a:	00003517          	auipc	a0,0x3
    80005b6e:	c6e50513          	addi	a0,a0,-914 # 800087d8 <syscalls+0x308>
    80005b72:	ffffb097          	auipc	ra,0xffffb
    80005b76:	9cc080e7          	jalr	-1588(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005b7a:	00003517          	auipc	a0,0x3
    80005b7e:	c7650513          	addi	a0,a0,-906 # 800087f0 <syscalls+0x320>
    80005b82:	ffffb097          	auipc	ra,0xffffb
    80005b86:	9bc080e7          	jalr	-1604(ra) # 8000053e <panic>
    dp->nlink--;
    80005b8a:	04a4d783          	lhu	a5,74(s1)
    80005b8e:	37fd                	addiw	a5,a5,-1
    80005b90:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b94:	8526                	mv	a0,s1
    80005b96:	ffffe097          	auipc	ra,0xffffe
    80005b9a:	004080e7          	jalr	4(ra) # 80003b9a <iupdate>
    80005b9e:	b781                	j	80005ade <sys_unlink+0xe0>
    return -1;
    80005ba0:	557d                	li	a0,-1
    80005ba2:	a005                	j	80005bc2 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005ba4:	854a                	mv	a0,s2
    80005ba6:	ffffe097          	auipc	ra,0xffffe
    80005baa:	320080e7          	jalr	800(ra) # 80003ec6 <iunlockput>
  iunlockput(dp);
    80005bae:	8526                	mv	a0,s1
    80005bb0:	ffffe097          	auipc	ra,0xffffe
    80005bb4:	316080e7          	jalr	790(ra) # 80003ec6 <iunlockput>
  end_op();
    80005bb8:	fffff097          	auipc	ra,0xfffff
    80005bbc:	afe080e7          	jalr	-1282(ra) # 800046b6 <end_op>
  return -1;
    80005bc0:	557d                	li	a0,-1
}
    80005bc2:	70ae                	ld	ra,232(sp)
    80005bc4:	740e                	ld	s0,224(sp)
    80005bc6:	64ee                	ld	s1,216(sp)
    80005bc8:	694e                	ld	s2,208(sp)
    80005bca:	69ae                	ld	s3,200(sp)
    80005bcc:	616d                	addi	sp,sp,240
    80005bce:	8082                	ret

0000000080005bd0 <sys_open>:

uint64
sys_open(void)
{
    80005bd0:	7131                	addi	sp,sp,-192
    80005bd2:	fd06                	sd	ra,184(sp)
    80005bd4:	f922                	sd	s0,176(sp)
    80005bd6:	f526                	sd	s1,168(sp)
    80005bd8:	f14a                	sd	s2,160(sp)
    80005bda:	ed4e                	sd	s3,152(sp)
    80005bdc:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005bde:	08000613          	li	a2,128
    80005be2:	f5040593          	addi	a1,s0,-176
    80005be6:	4501                	li	a0,0
    80005be8:	ffffd097          	auipc	ra,0xffffd
    80005bec:	504080e7          	jalr	1284(ra) # 800030ec <argstr>
    return -1;
    80005bf0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005bf2:	0c054163          	bltz	a0,80005cb4 <sys_open+0xe4>
    80005bf6:	f4c40593          	addi	a1,s0,-180
    80005bfa:	4505                	li	a0,1
    80005bfc:	ffffd097          	auipc	ra,0xffffd
    80005c00:	4ac080e7          	jalr	1196(ra) # 800030a8 <argint>
    80005c04:	0a054863          	bltz	a0,80005cb4 <sys_open+0xe4>

  begin_op();
    80005c08:	fffff097          	auipc	ra,0xfffff
    80005c0c:	a2e080e7          	jalr	-1490(ra) # 80004636 <begin_op>

  if(omode & O_CREATE){
    80005c10:	f4c42783          	lw	a5,-180(s0)
    80005c14:	2007f793          	andi	a5,a5,512
    80005c18:	cbdd                	beqz	a5,80005cce <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c1a:	4681                	li	a3,0
    80005c1c:	4601                	li	a2,0
    80005c1e:	4589                	li	a1,2
    80005c20:	f5040513          	addi	a0,s0,-176
    80005c24:	00000097          	auipc	ra,0x0
    80005c28:	972080e7          	jalr	-1678(ra) # 80005596 <create>
    80005c2c:	892a                	mv	s2,a0
    if(ip == 0){
    80005c2e:	c959                	beqz	a0,80005cc4 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c30:	04491703          	lh	a4,68(s2)
    80005c34:	478d                	li	a5,3
    80005c36:	00f71763          	bne	a4,a5,80005c44 <sys_open+0x74>
    80005c3a:	04695703          	lhu	a4,70(s2)
    80005c3e:	47a5                	li	a5,9
    80005c40:	0ce7ec63          	bltu	a5,a4,80005d18 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c44:	fffff097          	auipc	ra,0xfffff
    80005c48:	e02080e7          	jalr	-510(ra) # 80004a46 <filealloc>
    80005c4c:	89aa                	mv	s3,a0
    80005c4e:	10050263          	beqz	a0,80005d52 <sys_open+0x182>
    80005c52:	00000097          	auipc	ra,0x0
    80005c56:	902080e7          	jalr	-1790(ra) # 80005554 <fdalloc>
    80005c5a:	84aa                	mv	s1,a0
    80005c5c:	0e054663          	bltz	a0,80005d48 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c60:	04491703          	lh	a4,68(s2)
    80005c64:	478d                	li	a5,3
    80005c66:	0cf70463          	beq	a4,a5,80005d2e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c6a:	4789                	li	a5,2
    80005c6c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c70:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c74:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c78:	f4c42783          	lw	a5,-180(s0)
    80005c7c:	0017c713          	xori	a4,a5,1
    80005c80:	8b05                	andi	a4,a4,1
    80005c82:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c86:	0037f713          	andi	a4,a5,3
    80005c8a:	00e03733          	snez	a4,a4
    80005c8e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c92:	4007f793          	andi	a5,a5,1024
    80005c96:	c791                	beqz	a5,80005ca2 <sys_open+0xd2>
    80005c98:	04491703          	lh	a4,68(s2)
    80005c9c:	4789                	li	a5,2
    80005c9e:	08f70f63          	beq	a4,a5,80005d3c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005ca2:	854a                	mv	a0,s2
    80005ca4:	ffffe097          	auipc	ra,0xffffe
    80005ca8:	082080e7          	jalr	130(ra) # 80003d26 <iunlock>
  end_op();
    80005cac:	fffff097          	auipc	ra,0xfffff
    80005cb0:	a0a080e7          	jalr	-1526(ra) # 800046b6 <end_op>

  return fd;
}
    80005cb4:	8526                	mv	a0,s1
    80005cb6:	70ea                	ld	ra,184(sp)
    80005cb8:	744a                	ld	s0,176(sp)
    80005cba:	74aa                	ld	s1,168(sp)
    80005cbc:	790a                	ld	s2,160(sp)
    80005cbe:	69ea                	ld	s3,152(sp)
    80005cc0:	6129                	addi	sp,sp,192
    80005cc2:	8082                	ret
      end_op();
    80005cc4:	fffff097          	auipc	ra,0xfffff
    80005cc8:	9f2080e7          	jalr	-1550(ra) # 800046b6 <end_op>
      return -1;
    80005ccc:	b7e5                	j	80005cb4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005cce:	f5040513          	addi	a0,s0,-176
    80005cd2:	ffffe097          	auipc	ra,0xffffe
    80005cd6:	748080e7          	jalr	1864(ra) # 8000441a <namei>
    80005cda:	892a                	mv	s2,a0
    80005cdc:	c905                	beqz	a0,80005d0c <sys_open+0x13c>
    ilock(ip);
    80005cde:	ffffe097          	auipc	ra,0xffffe
    80005ce2:	f86080e7          	jalr	-122(ra) # 80003c64 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ce6:	04491703          	lh	a4,68(s2)
    80005cea:	4785                	li	a5,1
    80005cec:	f4f712e3          	bne	a4,a5,80005c30 <sys_open+0x60>
    80005cf0:	f4c42783          	lw	a5,-180(s0)
    80005cf4:	dba1                	beqz	a5,80005c44 <sys_open+0x74>
      iunlockput(ip);
    80005cf6:	854a                	mv	a0,s2
    80005cf8:	ffffe097          	auipc	ra,0xffffe
    80005cfc:	1ce080e7          	jalr	462(ra) # 80003ec6 <iunlockput>
      end_op();
    80005d00:	fffff097          	auipc	ra,0xfffff
    80005d04:	9b6080e7          	jalr	-1610(ra) # 800046b6 <end_op>
      return -1;
    80005d08:	54fd                	li	s1,-1
    80005d0a:	b76d                	j	80005cb4 <sys_open+0xe4>
      end_op();
    80005d0c:	fffff097          	auipc	ra,0xfffff
    80005d10:	9aa080e7          	jalr	-1622(ra) # 800046b6 <end_op>
      return -1;
    80005d14:	54fd                	li	s1,-1
    80005d16:	bf79                	j	80005cb4 <sys_open+0xe4>
    iunlockput(ip);
    80005d18:	854a                	mv	a0,s2
    80005d1a:	ffffe097          	auipc	ra,0xffffe
    80005d1e:	1ac080e7          	jalr	428(ra) # 80003ec6 <iunlockput>
    end_op();
    80005d22:	fffff097          	auipc	ra,0xfffff
    80005d26:	994080e7          	jalr	-1644(ra) # 800046b6 <end_op>
    return -1;
    80005d2a:	54fd                	li	s1,-1
    80005d2c:	b761                	j	80005cb4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d2e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d32:	04691783          	lh	a5,70(s2)
    80005d36:	02f99223          	sh	a5,36(s3)
    80005d3a:	bf2d                	j	80005c74 <sys_open+0xa4>
    itrunc(ip);
    80005d3c:	854a                	mv	a0,s2
    80005d3e:	ffffe097          	auipc	ra,0xffffe
    80005d42:	034080e7          	jalr	52(ra) # 80003d72 <itrunc>
    80005d46:	bfb1                	j	80005ca2 <sys_open+0xd2>
      fileclose(f);
    80005d48:	854e                	mv	a0,s3
    80005d4a:	fffff097          	auipc	ra,0xfffff
    80005d4e:	db8080e7          	jalr	-584(ra) # 80004b02 <fileclose>
    iunlockput(ip);
    80005d52:	854a                	mv	a0,s2
    80005d54:	ffffe097          	auipc	ra,0xffffe
    80005d58:	172080e7          	jalr	370(ra) # 80003ec6 <iunlockput>
    end_op();
    80005d5c:	fffff097          	auipc	ra,0xfffff
    80005d60:	95a080e7          	jalr	-1702(ra) # 800046b6 <end_op>
    return -1;
    80005d64:	54fd                	li	s1,-1
    80005d66:	b7b9                	j	80005cb4 <sys_open+0xe4>

0000000080005d68 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d68:	7175                	addi	sp,sp,-144
    80005d6a:	e506                	sd	ra,136(sp)
    80005d6c:	e122                	sd	s0,128(sp)
    80005d6e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d70:	fffff097          	auipc	ra,0xfffff
    80005d74:	8c6080e7          	jalr	-1850(ra) # 80004636 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d78:	08000613          	li	a2,128
    80005d7c:	f7040593          	addi	a1,s0,-144
    80005d80:	4501                	li	a0,0
    80005d82:	ffffd097          	auipc	ra,0xffffd
    80005d86:	36a080e7          	jalr	874(ra) # 800030ec <argstr>
    80005d8a:	02054963          	bltz	a0,80005dbc <sys_mkdir+0x54>
    80005d8e:	4681                	li	a3,0
    80005d90:	4601                	li	a2,0
    80005d92:	4585                	li	a1,1
    80005d94:	f7040513          	addi	a0,s0,-144
    80005d98:	fffff097          	auipc	ra,0xfffff
    80005d9c:	7fe080e7          	jalr	2046(ra) # 80005596 <create>
    80005da0:	cd11                	beqz	a0,80005dbc <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005da2:	ffffe097          	auipc	ra,0xffffe
    80005da6:	124080e7          	jalr	292(ra) # 80003ec6 <iunlockput>
  end_op();
    80005daa:	fffff097          	auipc	ra,0xfffff
    80005dae:	90c080e7          	jalr	-1780(ra) # 800046b6 <end_op>
  return 0;
    80005db2:	4501                	li	a0,0
}
    80005db4:	60aa                	ld	ra,136(sp)
    80005db6:	640a                	ld	s0,128(sp)
    80005db8:	6149                	addi	sp,sp,144
    80005dba:	8082                	ret
    end_op();
    80005dbc:	fffff097          	auipc	ra,0xfffff
    80005dc0:	8fa080e7          	jalr	-1798(ra) # 800046b6 <end_op>
    return -1;
    80005dc4:	557d                	li	a0,-1
    80005dc6:	b7fd                	j	80005db4 <sys_mkdir+0x4c>

0000000080005dc8 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005dc8:	7135                	addi	sp,sp,-160
    80005dca:	ed06                	sd	ra,152(sp)
    80005dcc:	e922                	sd	s0,144(sp)
    80005dce:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005dd0:	fffff097          	auipc	ra,0xfffff
    80005dd4:	866080e7          	jalr	-1946(ra) # 80004636 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005dd8:	08000613          	li	a2,128
    80005ddc:	f7040593          	addi	a1,s0,-144
    80005de0:	4501                	li	a0,0
    80005de2:	ffffd097          	auipc	ra,0xffffd
    80005de6:	30a080e7          	jalr	778(ra) # 800030ec <argstr>
    80005dea:	04054a63          	bltz	a0,80005e3e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005dee:	f6c40593          	addi	a1,s0,-148
    80005df2:	4505                	li	a0,1
    80005df4:	ffffd097          	auipc	ra,0xffffd
    80005df8:	2b4080e7          	jalr	692(ra) # 800030a8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005dfc:	04054163          	bltz	a0,80005e3e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005e00:	f6840593          	addi	a1,s0,-152
    80005e04:	4509                	li	a0,2
    80005e06:	ffffd097          	auipc	ra,0xffffd
    80005e0a:	2a2080e7          	jalr	674(ra) # 800030a8 <argint>
     argint(1, &major) < 0 ||
    80005e0e:	02054863          	bltz	a0,80005e3e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e12:	f6841683          	lh	a3,-152(s0)
    80005e16:	f6c41603          	lh	a2,-148(s0)
    80005e1a:	458d                	li	a1,3
    80005e1c:	f7040513          	addi	a0,s0,-144
    80005e20:	fffff097          	auipc	ra,0xfffff
    80005e24:	776080e7          	jalr	1910(ra) # 80005596 <create>
     argint(2, &minor) < 0 ||
    80005e28:	c919                	beqz	a0,80005e3e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e2a:	ffffe097          	auipc	ra,0xffffe
    80005e2e:	09c080e7          	jalr	156(ra) # 80003ec6 <iunlockput>
  end_op();
    80005e32:	fffff097          	auipc	ra,0xfffff
    80005e36:	884080e7          	jalr	-1916(ra) # 800046b6 <end_op>
  return 0;
    80005e3a:	4501                	li	a0,0
    80005e3c:	a031                	j	80005e48 <sys_mknod+0x80>
    end_op();
    80005e3e:	fffff097          	auipc	ra,0xfffff
    80005e42:	878080e7          	jalr	-1928(ra) # 800046b6 <end_op>
    return -1;
    80005e46:	557d                	li	a0,-1
}
    80005e48:	60ea                	ld	ra,152(sp)
    80005e4a:	644a                	ld	s0,144(sp)
    80005e4c:	610d                	addi	sp,sp,160
    80005e4e:	8082                	ret

0000000080005e50 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e50:	7135                	addi	sp,sp,-160
    80005e52:	ed06                	sd	ra,152(sp)
    80005e54:	e922                	sd	s0,144(sp)
    80005e56:	e526                	sd	s1,136(sp)
    80005e58:	e14a                	sd	s2,128(sp)
    80005e5a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e5c:	ffffc097          	auipc	ra,0xffffc
    80005e60:	e74080e7          	jalr	-396(ra) # 80001cd0 <myproc>
    80005e64:	892a                	mv	s2,a0
  
  begin_op();
    80005e66:	ffffe097          	auipc	ra,0xffffe
    80005e6a:	7d0080e7          	jalr	2000(ra) # 80004636 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e6e:	08000613          	li	a2,128
    80005e72:	f6040593          	addi	a1,s0,-160
    80005e76:	4501                	li	a0,0
    80005e78:	ffffd097          	auipc	ra,0xffffd
    80005e7c:	274080e7          	jalr	628(ra) # 800030ec <argstr>
    80005e80:	04054b63          	bltz	a0,80005ed6 <sys_chdir+0x86>
    80005e84:	f6040513          	addi	a0,s0,-160
    80005e88:	ffffe097          	auipc	ra,0xffffe
    80005e8c:	592080e7          	jalr	1426(ra) # 8000441a <namei>
    80005e90:	84aa                	mv	s1,a0
    80005e92:	c131                	beqz	a0,80005ed6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e94:	ffffe097          	auipc	ra,0xffffe
    80005e98:	dd0080e7          	jalr	-560(ra) # 80003c64 <ilock>
  if(ip->type != T_DIR){
    80005e9c:	04449703          	lh	a4,68(s1)
    80005ea0:	4785                	li	a5,1
    80005ea2:	04f71063          	bne	a4,a5,80005ee2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ea6:	8526                	mv	a0,s1
    80005ea8:	ffffe097          	auipc	ra,0xffffe
    80005eac:	e7e080e7          	jalr	-386(ra) # 80003d26 <iunlock>
  iput(p->cwd);
    80005eb0:	15093503          	ld	a0,336(s2)
    80005eb4:	ffffe097          	auipc	ra,0xffffe
    80005eb8:	f6a080e7          	jalr	-150(ra) # 80003e1e <iput>
  end_op();
    80005ebc:	ffffe097          	auipc	ra,0xffffe
    80005ec0:	7fa080e7          	jalr	2042(ra) # 800046b6 <end_op>
  p->cwd = ip;
    80005ec4:	14993823          	sd	s1,336(s2)
  return 0;
    80005ec8:	4501                	li	a0,0
}
    80005eca:	60ea                	ld	ra,152(sp)
    80005ecc:	644a                	ld	s0,144(sp)
    80005ece:	64aa                	ld	s1,136(sp)
    80005ed0:	690a                	ld	s2,128(sp)
    80005ed2:	610d                	addi	sp,sp,160
    80005ed4:	8082                	ret
    end_op();
    80005ed6:	ffffe097          	auipc	ra,0xffffe
    80005eda:	7e0080e7          	jalr	2016(ra) # 800046b6 <end_op>
    return -1;
    80005ede:	557d                	li	a0,-1
    80005ee0:	b7ed                	j	80005eca <sys_chdir+0x7a>
    iunlockput(ip);
    80005ee2:	8526                	mv	a0,s1
    80005ee4:	ffffe097          	auipc	ra,0xffffe
    80005ee8:	fe2080e7          	jalr	-30(ra) # 80003ec6 <iunlockput>
    end_op();
    80005eec:	ffffe097          	auipc	ra,0xffffe
    80005ef0:	7ca080e7          	jalr	1994(ra) # 800046b6 <end_op>
    return -1;
    80005ef4:	557d                	li	a0,-1
    80005ef6:	bfd1                	j	80005eca <sys_chdir+0x7a>

0000000080005ef8 <sys_exec>:

uint64
sys_exec(void)
{
    80005ef8:	7145                	addi	sp,sp,-464
    80005efa:	e786                	sd	ra,456(sp)
    80005efc:	e3a2                	sd	s0,448(sp)
    80005efe:	ff26                	sd	s1,440(sp)
    80005f00:	fb4a                	sd	s2,432(sp)
    80005f02:	f74e                	sd	s3,424(sp)
    80005f04:	f352                	sd	s4,416(sp)
    80005f06:	ef56                	sd	s5,408(sp)
    80005f08:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f0a:	08000613          	li	a2,128
    80005f0e:	f4040593          	addi	a1,s0,-192
    80005f12:	4501                	li	a0,0
    80005f14:	ffffd097          	auipc	ra,0xffffd
    80005f18:	1d8080e7          	jalr	472(ra) # 800030ec <argstr>
    return -1;
    80005f1c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f1e:	0c054a63          	bltz	a0,80005ff2 <sys_exec+0xfa>
    80005f22:	e3840593          	addi	a1,s0,-456
    80005f26:	4505                	li	a0,1
    80005f28:	ffffd097          	auipc	ra,0xffffd
    80005f2c:	1a2080e7          	jalr	418(ra) # 800030ca <argaddr>
    80005f30:	0c054163          	bltz	a0,80005ff2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005f34:	10000613          	li	a2,256
    80005f38:	4581                	li	a1,0
    80005f3a:	e4040513          	addi	a0,s0,-448
    80005f3e:	ffffb097          	auipc	ra,0xffffb
    80005f42:	da2080e7          	jalr	-606(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f46:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f4a:	89a6                	mv	s3,s1
    80005f4c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f4e:	02000a13          	li	s4,32
    80005f52:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f56:	00391513          	slli	a0,s2,0x3
    80005f5a:	e3040593          	addi	a1,s0,-464
    80005f5e:	e3843783          	ld	a5,-456(s0)
    80005f62:	953e                	add	a0,a0,a5
    80005f64:	ffffd097          	auipc	ra,0xffffd
    80005f68:	0aa080e7          	jalr	170(ra) # 8000300e <fetchaddr>
    80005f6c:	02054a63          	bltz	a0,80005fa0 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005f70:	e3043783          	ld	a5,-464(s0)
    80005f74:	c3b9                	beqz	a5,80005fba <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f76:	ffffb097          	auipc	ra,0xffffb
    80005f7a:	b7e080e7          	jalr	-1154(ra) # 80000af4 <kalloc>
    80005f7e:	85aa                	mv	a1,a0
    80005f80:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f84:	cd11                	beqz	a0,80005fa0 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f86:	6605                	lui	a2,0x1
    80005f88:	e3043503          	ld	a0,-464(s0)
    80005f8c:	ffffd097          	auipc	ra,0xffffd
    80005f90:	0d4080e7          	jalr	212(ra) # 80003060 <fetchstr>
    80005f94:	00054663          	bltz	a0,80005fa0 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005f98:	0905                	addi	s2,s2,1
    80005f9a:	09a1                	addi	s3,s3,8
    80005f9c:	fb491be3          	bne	s2,s4,80005f52 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fa0:	10048913          	addi	s2,s1,256
    80005fa4:	6088                	ld	a0,0(s1)
    80005fa6:	c529                	beqz	a0,80005ff0 <sys_exec+0xf8>
    kfree(argv[i]);
    80005fa8:	ffffb097          	auipc	ra,0xffffb
    80005fac:	a50080e7          	jalr	-1456(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fb0:	04a1                	addi	s1,s1,8
    80005fb2:	ff2499e3          	bne	s1,s2,80005fa4 <sys_exec+0xac>
  return -1;
    80005fb6:	597d                	li	s2,-1
    80005fb8:	a82d                	j	80005ff2 <sys_exec+0xfa>
      argv[i] = 0;
    80005fba:	0a8e                	slli	s5,s5,0x3
    80005fbc:	fc040793          	addi	a5,s0,-64
    80005fc0:	9abe                	add	s5,s5,a5
    80005fc2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005fc6:	e4040593          	addi	a1,s0,-448
    80005fca:	f4040513          	addi	a0,s0,-192
    80005fce:	fffff097          	auipc	ra,0xfffff
    80005fd2:	194080e7          	jalr	404(ra) # 80005162 <exec>
    80005fd6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fd8:	10048993          	addi	s3,s1,256
    80005fdc:	6088                	ld	a0,0(s1)
    80005fde:	c911                	beqz	a0,80005ff2 <sys_exec+0xfa>
    kfree(argv[i]);
    80005fe0:	ffffb097          	auipc	ra,0xffffb
    80005fe4:	a18080e7          	jalr	-1512(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fe8:	04a1                	addi	s1,s1,8
    80005fea:	ff3499e3          	bne	s1,s3,80005fdc <sys_exec+0xe4>
    80005fee:	a011                	j	80005ff2 <sys_exec+0xfa>
  return -1;
    80005ff0:	597d                	li	s2,-1
}
    80005ff2:	854a                	mv	a0,s2
    80005ff4:	60be                	ld	ra,456(sp)
    80005ff6:	641e                	ld	s0,448(sp)
    80005ff8:	74fa                	ld	s1,440(sp)
    80005ffa:	795a                	ld	s2,432(sp)
    80005ffc:	79ba                	ld	s3,424(sp)
    80005ffe:	7a1a                	ld	s4,416(sp)
    80006000:	6afa                	ld	s5,408(sp)
    80006002:	6179                	addi	sp,sp,464
    80006004:	8082                	ret

0000000080006006 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006006:	7139                	addi	sp,sp,-64
    80006008:	fc06                	sd	ra,56(sp)
    8000600a:	f822                	sd	s0,48(sp)
    8000600c:	f426                	sd	s1,40(sp)
    8000600e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006010:	ffffc097          	auipc	ra,0xffffc
    80006014:	cc0080e7          	jalr	-832(ra) # 80001cd0 <myproc>
    80006018:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000601a:	fd840593          	addi	a1,s0,-40
    8000601e:	4501                	li	a0,0
    80006020:	ffffd097          	auipc	ra,0xffffd
    80006024:	0aa080e7          	jalr	170(ra) # 800030ca <argaddr>
    return -1;
    80006028:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000602a:	0e054063          	bltz	a0,8000610a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000602e:	fc840593          	addi	a1,s0,-56
    80006032:	fd040513          	addi	a0,s0,-48
    80006036:	fffff097          	auipc	ra,0xfffff
    8000603a:	dfc080e7          	jalr	-516(ra) # 80004e32 <pipealloc>
    return -1;
    8000603e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006040:	0c054563          	bltz	a0,8000610a <sys_pipe+0x104>
  fd0 = -1;
    80006044:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006048:	fd043503          	ld	a0,-48(s0)
    8000604c:	fffff097          	auipc	ra,0xfffff
    80006050:	508080e7          	jalr	1288(ra) # 80005554 <fdalloc>
    80006054:	fca42223          	sw	a0,-60(s0)
    80006058:	08054c63          	bltz	a0,800060f0 <sys_pipe+0xea>
    8000605c:	fc843503          	ld	a0,-56(s0)
    80006060:	fffff097          	auipc	ra,0xfffff
    80006064:	4f4080e7          	jalr	1268(ra) # 80005554 <fdalloc>
    80006068:	fca42023          	sw	a0,-64(s0)
    8000606c:	06054863          	bltz	a0,800060dc <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006070:	4691                	li	a3,4
    80006072:	fc440613          	addi	a2,s0,-60
    80006076:	fd843583          	ld	a1,-40(s0)
    8000607a:	68a8                	ld	a0,80(s1)
    8000607c:	ffffb097          	auipc	ra,0xffffb
    80006080:	5f6080e7          	jalr	1526(ra) # 80001672 <copyout>
    80006084:	02054063          	bltz	a0,800060a4 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006088:	4691                	li	a3,4
    8000608a:	fc040613          	addi	a2,s0,-64
    8000608e:	fd843583          	ld	a1,-40(s0)
    80006092:	0591                	addi	a1,a1,4
    80006094:	68a8                	ld	a0,80(s1)
    80006096:	ffffb097          	auipc	ra,0xffffb
    8000609a:	5dc080e7          	jalr	1500(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000609e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060a0:	06055563          	bgez	a0,8000610a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800060a4:	fc442783          	lw	a5,-60(s0)
    800060a8:	07e9                	addi	a5,a5,26
    800060aa:	078e                	slli	a5,a5,0x3
    800060ac:	97a6                	add	a5,a5,s1
    800060ae:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800060b2:	fc042503          	lw	a0,-64(s0)
    800060b6:	0569                	addi	a0,a0,26
    800060b8:	050e                	slli	a0,a0,0x3
    800060ba:	9526                	add	a0,a0,s1
    800060bc:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800060c0:	fd043503          	ld	a0,-48(s0)
    800060c4:	fffff097          	auipc	ra,0xfffff
    800060c8:	a3e080e7          	jalr	-1474(ra) # 80004b02 <fileclose>
    fileclose(wf);
    800060cc:	fc843503          	ld	a0,-56(s0)
    800060d0:	fffff097          	auipc	ra,0xfffff
    800060d4:	a32080e7          	jalr	-1486(ra) # 80004b02 <fileclose>
    return -1;
    800060d8:	57fd                	li	a5,-1
    800060da:	a805                	j	8000610a <sys_pipe+0x104>
    if(fd0 >= 0)
    800060dc:	fc442783          	lw	a5,-60(s0)
    800060e0:	0007c863          	bltz	a5,800060f0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800060e4:	01a78513          	addi	a0,a5,26
    800060e8:	050e                	slli	a0,a0,0x3
    800060ea:	9526                	add	a0,a0,s1
    800060ec:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800060f0:	fd043503          	ld	a0,-48(s0)
    800060f4:	fffff097          	auipc	ra,0xfffff
    800060f8:	a0e080e7          	jalr	-1522(ra) # 80004b02 <fileclose>
    fileclose(wf);
    800060fc:	fc843503          	ld	a0,-56(s0)
    80006100:	fffff097          	auipc	ra,0xfffff
    80006104:	a02080e7          	jalr	-1534(ra) # 80004b02 <fileclose>
    return -1;
    80006108:	57fd                	li	a5,-1
}
    8000610a:	853e                	mv	a0,a5
    8000610c:	70e2                	ld	ra,56(sp)
    8000610e:	7442                	ld	s0,48(sp)
    80006110:	74a2                	ld	s1,40(sp)
    80006112:	6121                	addi	sp,sp,64
    80006114:	8082                	ret
	...

0000000080006120 <kernelvec>:
    80006120:	7111                	addi	sp,sp,-256
    80006122:	e006                	sd	ra,0(sp)
    80006124:	e40a                	sd	sp,8(sp)
    80006126:	e80e                	sd	gp,16(sp)
    80006128:	ec12                	sd	tp,24(sp)
    8000612a:	f016                	sd	t0,32(sp)
    8000612c:	f41a                	sd	t1,40(sp)
    8000612e:	f81e                	sd	t2,48(sp)
    80006130:	fc22                	sd	s0,56(sp)
    80006132:	e0a6                	sd	s1,64(sp)
    80006134:	e4aa                	sd	a0,72(sp)
    80006136:	e8ae                	sd	a1,80(sp)
    80006138:	ecb2                	sd	a2,88(sp)
    8000613a:	f0b6                	sd	a3,96(sp)
    8000613c:	f4ba                	sd	a4,104(sp)
    8000613e:	f8be                	sd	a5,112(sp)
    80006140:	fcc2                	sd	a6,120(sp)
    80006142:	e146                	sd	a7,128(sp)
    80006144:	e54a                	sd	s2,136(sp)
    80006146:	e94e                	sd	s3,144(sp)
    80006148:	ed52                	sd	s4,152(sp)
    8000614a:	f156                	sd	s5,160(sp)
    8000614c:	f55a                	sd	s6,168(sp)
    8000614e:	f95e                	sd	s7,176(sp)
    80006150:	fd62                	sd	s8,184(sp)
    80006152:	e1e6                	sd	s9,192(sp)
    80006154:	e5ea                	sd	s10,200(sp)
    80006156:	e9ee                	sd	s11,208(sp)
    80006158:	edf2                	sd	t3,216(sp)
    8000615a:	f1f6                	sd	t4,224(sp)
    8000615c:	f5fa                	sd	t5,232(sp)
    8000615e:	f9fe                	sd	t6,240(sp)
    80006160:	d7bfc0ef          	jal	ra,80002eda <kerneltrap>
    80006164:	6082                	ld	ra,0(sp)
    80006166:	6122                	ld	sp,8(sp)
    80006168:	61c2                	ld	gp,16(sp)
    8000616a:	7282                	ld	t0,32(sp)
    8000616c:	7322                	ld	t1,40(sp)
    8000616e:	73c2                	ld	t2,48(sp)
    80006170:	7462                	ld	s0,56(sp)
    80006172:	6486                	ld	s1,64(sp)
    80006174:	6526                	ld	a0,72(sp)
    80006176:	65c6                	ld	a1,80(sp)
    80006178:	6666                	ld	a2,88(sp)
    8000617a:	7686                	ld	a3,96(sp)
    8000617c:	7726                	ld	a4,104(sp)
    8000617e:	77c6                	ld	a5,112(sp)
    80006180:	7866                	ld	a6,120(sp)
    80006182:	688a                	ld	a7,128(sp)
    80006184:	692a                	ld	s2,136(sp)
    80006186:	69ca                	ld	s3,144(sp)
    80006188:	6a6a                	ld	s4,152(sp)
    8000618a:	7a8a                	ld	s5,160(sp)
    8000618c:	7b2a                	ld	s6,168(sp)
    8000618e:	7bca                	ld	s7,176(sp)
    80006190:	7c6a                	ld	s8,184(sp)
    80006192:	6c8e                	ld	s9,192(sp)
    80006194:	6d2e                	ld	s10,200(sp)
    80006196:	6dce                	ld	s11,208(sp)
    80006198:	6e6e                	ld	t3,216(sp)
    8000619a:	7e8e                	ld	t4,224(sp)
    8000619c:	7f2e                	ld	t5,232(sp)
    8000619e:	7fce                	ld	t6,240(sp)
    800061a0:	6111                	addi	sp,sp,256
    800061a2:	10200073          	sret
    800061a6:	00000013          	nop
    800061aa:	00000013          	nop
    800061ae:	0001                	nop

00000000800061b0 <timervec>:
    800061b0:	34051573          	csrrw	a0,mscratch,a0
    800061b4:	e10c                	sd	a1,0(a0)
    800061b6:	e510                	sd	a2,8(a0)
    800061b8:	e914                	sd	a3,16(a0)
    800061ba:	6d0c                	ld	a1,24(a0)
    800061bc:	7110                	ld	a2,32(a0)
    800061be:	6194                	ld	a3,0(a1)
    800061c0:	96b2                	add	a3,a3,a2
    800061c2:	e194                	sd	a3,0(a1)
    800061c4:	4589                	li	a1,2
    800061c6:	14459073          	csrw	sip,a1
    800061ca:	6914                	ld	a3,16(a0)
    800061cc:	6510                	ld	a2,8(a0)
    800061ce:	610c                	ld	a1,0(a0)
    800061d0:	34051573          	csrrw	a0,mscratch,a0
    800061d4:	30200073          	mret
	...

00000000800061da <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800061da:	1141                	addi	sp,sp,-16
    800061dc:	e422                	sd	s0,8(sp)
    800061de:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800061e0:	0c0007b7          	lui	a5,0xc000
    800061e4:	4705                	li	a4,1
    800061e6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800061e8:	c3d8                	sw	a4,4(a5)
}
    800061ea:	6422                	ld	s0,8(sp)
    800061ec:	0141                	addi	sp,sp,16
    800061ee:	8082                	ret

00000000800061f0 <plicinithart>:

void
plicinithart(void)
{
    800061f0:	1141                	addi	sp,sp,-16
    800061f2:	e406                	sd	ra,8(sp)
    800061f4:	e022                	sd	s0,0(sp)
    800061f6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061f8:	ffffc097          	auipc	ra,0xffffc
    800061fc:	aa6080e7          	jalr	-1370(ra) # 80001c9e <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006200:	0085171b          	slliw	a4,a0,0x8
    80006204:	0c0027b7          	lui	a5,0xc002
    80006208:	97ba                	add	a5,a5,a4
    8000620a:	40200713          	li	a4,1026
    8000620e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006212:	00d5151b          	slliw	a0,a0,0xd
    80006216:	0c2017b7          	lui	a5,0xc201
    8000621a:	953e                	add	a0,a0,a5
    8000621c:	00052023          	sw	zero,0(a0)
}
    80006220:	60a2                	ld	ra,8(sp)
    80006222:	6402                	ld	s0,0(sp)
    80006224:	0141                	addi	sp,sp,16
    80006226:	8082                	ret

0000000080006228 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006228:	1141                	addi	sp,sp,-16
    8000622a:	e406                	sd	ra,8(sp)
    8000622c:	e022                	sd	s0,0(sp)
    8000622e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006230:	ffffc097          	auipc	ra,0xffffc
    80006234:	a6e080e7          	jalr	-1426(ra) # 80001c9e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006238:	00d5179b          	slliw	a5,a0,0xd
    8000623c:	0c201537          	lui	a0,0xc201
    80006240:	953e                	add	a0,a0,a5
  return irq;
}
    80006242:	4148                	lw	a0,4(a0)
    80006244:	60a2                	ld	ra,8(sp)
    80006246:	6402                	ld	s0,0(sp)
    80006248:	0141                	addi	sp,sp,16
    8000624a:	8082                	ret

000000008000624c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000624c:	1101                	addi	sp,sp,-32
    8000624e:	ec06                	sd	ra,24(sp)
    80006250:	e822                	sd	s0,16(sp)
    80006252:	e426                	sd	s1,8(sp)
    80006254:	1000                	addi	s0,sp,32
    80006256:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006258:	ffffc097          	auipc	ra,0xffffc
    8000625c:	a46080e7          	jalr	-1466(ra) # 80001c9e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006260:	00d5151b          	slliw	a0,a0,0xd
    80006264:	0c2017b7          	lui	a5,0xc201
    80006268:	97aa                	add	a5,a5,a0
    8000626a:	c3c4                	sw	s1,4(a5)
}
    8000626c:	60e2                	ld	ra,24(sp)
    8000626e:	6442                	ld	s0,16(sp)
    80006270:	64a2                	ld	s1,8(sp)
    80006272:	6105                	addi	sp,sp,32
    80006274:	8082                	ret

0000000080006276 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006276:	1141                	addi	sp,sp,-16
    80006278:	e406                	sd	ra,8(sp)
    8000627a:	e022                	sd	s0,0(sp)
    8000627c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000627e:	479d                	li	a5,7
    80006280:	06a7c963          	blt	a5,a0,800062f2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006284:	0001d797          	auipc	a5,0x1d
    80006288:	d7c78793          	addi	a5,a5,-644 # 80023000 <disk>
    8000628c:	00a78733          	add	a4,a5,a0
    80006290:	6789                	lui	a5,0x2
    80006292:	97ba                	add	a5,a5,a4
    80006294:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006298:	e7ad                	bnez	a5,80006302 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000629a:	00451793          	slli	a5,a0,0x4
    8000629e:	0001f717          	auipc	a4,0x1f
    800062a2:	d6270713          	addi	a4,a4,-670 # 80025000 <disk+0x2000>
    800062a6:	6314                	ld	a3,0(a4)
    800062a8:	96be                	add	a3,a3,a5
    800062aa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800062ae:	6314                	ld	a3,0(a4)
    800062b0:	96be                	add	a3,a3,a5
    800062b2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800062b6:	6314                	ld	a3,0(a4)
    800062b8:	96be                	add	a3,a3,a5
    800062ba:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800062be:	6318                	ld	a4,0(a4)
    800062c0:	97ba                	add	a5,a5,a4
    800062c2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800062c6:	0001d797          	auipc	a5,0x1d
    800062ca:	d3a78793          	addi	a5,a5,-710 # 80023000 <disk>
    800062ce:	97aa                	add	a5,a5,a0
    800062d0:	6509                	lui	a0,0x2
    800062d2:	953e                	add	a0,a0,a5
    800062d4:	4785                	li	a5,1
    800062d6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800062da:	0001f517          	auipc	a0,0x1f
    800062de:	d3e50513          	addi	a0,a0,-706 # 80025018 <disk+0x2018>
    800062e2:	ffffc097          	auipc	ra,0xffffc
    800062e6:	3fe080e7          	jalr	1022(ra) # 800026e0 <wakeup>
}
    800062ea:	60a2                	ld	ra,8(sp)
    800062ec:	6402                	ld	s0,0(sp)
    800062ee:	0141                	addi	sp,sp,16
    800062f0:	8082                	ret
    panic("free_desc 1");
    800062f2:	00002517          	auipc	a0,0x2
    800062f6:	50e50513          	addi	a0,a0,1294 # 80008800 <syscalls+0x330>
    800062fa:	ffffa097          	auipc	ra,0xffffa
    800062fe:	244080e7          	jalr	580(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006302:	00002517          	auipc	a0,0x2
    80006306:	50e50513          	addi	a0,a0,1294 # 80008810 <syscalls+0x340>
    8000630a:	ffffa097          	auipc	ra,0xffffa
    8000630e:	234080e7          	jalr	564(ra) # 8000053e <panic>

0000000080006312 <virtio_disk_init>:
{
    80006312:	1101                	addi	sp,sp,-32
    80006314:	ec06                	sd	ra,24(sp)
    80006316:	e822                	sd	s0,16(sp)
    80006318:	e426                	sd	s1,8(sp)
    8000631a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000631c:	00002597          	auipc	a1,0x2
    80006320:	50458593          	addi	a1,a1,1284 # 80008820 <syscalls+0x350>
    80006324:	0001f517          	auipc	a0,0x1f
    80006328:	e0450513          	addi	a0,a0,-508 # 80025128 <disk+0x2128>
    8000632c:	ffffb097          	auipc	ra,0xffffb
    80006330:	828080e7          	jalr	-2008(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006334:	100017b7          	lui	a5,0x10001
    80006338:	4398                	lw	a4,0(a5)
    8000633a:	2701                	sext.w	a4,a4
    8000633c:	747277b7          	lui	a5,0x74727
    80006340:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006344:	0ef71163          	bne	a4,a5,80006426 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006348:	100017b7          	lui	a5,0x10001
    8000634c:	43dc                	lw	a5,4(a5)
    8000634e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006350:	4705                	li	a4,1
    80006352:	0ce79a63          	bne	a5,a4,80006426 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006356:	100017b7          	lui	a5,0x10001
    8000635a:	479c                	lw	a5,8(a5)
    8000635c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000635e:	4709                	li	a4,2
    80006360:	0ce79363          	bne	a5,a4,80006426 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006364:	100017b7          	lui	a5,0x10001
    80006368:	47d8                	lw	a4,12(a5)
    8000636a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000636c:	554d47b7          	lui	a5,0x554d4
    80006370:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006374:	0af71963          	bne	a4,a5,80006426 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006378:	100017b7          	lui	a5,0x10001
    8000637c:	4705                	li	a4,1
    8000637e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006380:	470d                	li	a4,3
    80006382:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006384:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006386:	c7ffe737          	lui	a4,0xc7ffe
    8000638a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000638e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006390:	2701                	sext.w	a4,a4
    80006392:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006394:	472d                	li	a4,11
    80006396:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006398:	473d                	li	a4,15
    8000639a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000639c:	6705                	lui	a4,0x1
    8000639e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800063a0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800063a4:	5bdc                	lw	a5,52(a5)
    800063a6:	2781                	sext.w	a5,a5
  if(max == 0)
    800063a8:	c7d9                	beqz	a5,80006436 <virtio_disk_init+0x124>
  if(max < NUM)
    800063aa:	471d                	li	a4,7
    800063ac:	08f77d63          	bgeu	a4,a5,80006446 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800063b0:	100014b7          	lui	s1,0x10001
    800063b4:	47a1                	li	a5,8
    800063b6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800063b8:	6609                	lui	a2,0x2
    800063ba:	4581                	li	a1,0
    800063bc:	0001d517          	auipc	a0,0x1d
    800063c0:	c4450513          	addi	a0,a0,-956 # 80023000 <disk>
    800063c4:	ffffb097          	auipc	ra,0xffffb
    800063c8:	91c080e7          	jalr	-1764(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800063cc:	0001d717          	auipc	a4,0x1d
    800063d0:	c3470713          	addi	a4,a4,-972 # 80023000 <disk>
    800063d4:	00c75793          	srli	a5,a4,0xc
    800063d8:	2781                	sext.w	a5,a5
    800063da:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800063dc:	0001f797          	auipc	a5,0x1f
    800063e0:	c2478793          	addi	a5,a5,-988 # 80025000 <disk+0x2000>
    800063e4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800063e6:	0001d717          	auipc	a4,0x1d
    800063ea:	c9a70713          	addi	a4,a4,-870 # 80023080 <disk+0x80>
    800063ee:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800063f0:	0001e717          	auipc	a4,0x1e
    800063f4:	c1070713          	addi	a4,a4,-1008 # 80024000 <disk+0x1000>
    800063f8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800063fa:	4705                	li	a4,1
    800063fc:	00e78c23          	sb	a4,24(a5)
    80006400:	00e78ca3          	sb	a4,25(a5)
    80006404:	00e78d23          	sb	a4,26(a5)
    80006408:	00e78da3          	sb	a4,27(a5)
    8000640c:	00e78e23          	sb	a4,28(a5)
    80006410:	00e78ea3          	sb	a4,29(a5)
    80006414:	00e78f23          	sb	a4,30(a5)
    80006418:	00e78fa3          	sb	a4,31(a5)
}
    8000641c:	60e2                	ld	ra,24(sp)
    8000641e:	6442                	ld	s0,16(sp)
    80006420:	64a2                	ld	s1,8(sp)
    80006422:	6105                	addi	sp,sp,32
    80006424:	8082                	ret
    panic("could not find virtio disk");
    80006426:	00002517          	auipc	a0,0x2
    8000642a:	40a50513          	addi	a0,a0,1034 # 80008830 <syscalls+0x360>
    8000642e:	ffffa097          	auipc	ra,0xffffa
    80006432:	110080e7          	jalr	272(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006436:	00002517          	auipc	a0,0x2
    8000643a:	41a50513          	addi	a0,a0,1050 # 80008850 <syscalls+0x380>
    8000643e:	ffffa097          	auipc	ra,0xffffa
    80006442:	100080e7          	jalr	256(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006446:	00002517          	auipc	a0,0x2
    8000644a:	42a50513          	addi	a0,a0,1066 # 80008870 <syscalls+0x3a0>
    8000644e:	ffffa097          	auipc	ra,0xffffa
    80006452:	0f0080e7          	jalr	240(ra) # 8000053e <panic>

0000000080006456 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006456:	7159                	addi	sp,sp,-112
    80006458:	f486                	sd	ra,104(sp)
    8000645a:	f0a2                	sd	s0,96(sp)
    8000645c:	eca6                	sd	s1,88(sp)
    8000645e:	e8ca                	sd	s2,80(sp)
    80006460:	e4ce                	sd	s3,72(sp)
    80006462:	e0d2                	sd	s4,64(sp)
    80006464:	fc56                	sd	s5,56(sp)
    80006466:	f85a                	sd	s6,48(sp)
    80006468:	f45e                	sd	s7,40(sp)
    8000646a:	f062                	sd	s8,32(sp)
    8000646c:	ec66                	sd	s9,24(sp)
    8000646e:	e86a                	sd	s10,16(sp)
    80006470:	1880                	addi	s0,sp,112
    80006472:	892a                	mv	s2,a0
    80006474:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006476:	00c52c83          	lw	s9,12(a0)
    8000647a:	001c9c9b          	slliw	s9,s9,0x1
    8000647e:	1c82                	slli	s9,s9,0x20
    80006480:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006484:	0001f517          	auipc	a0,0x1f
    80006488:	ca450513          	addi	a0,a0,-860 # 80025128 <disk+0x2128>
    8000648c:	ffffa097          	auipc	ra,0xffffa
    80006490:	758080e7          	jalr	1880(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006494:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006496:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006498:	0001db97          	auipc	s7,0x1d
    8000649c:	b68b8b93          	addi	s7,s7,-1176 # 80023000 <disk>
    800064a0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800064a2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800064a4:	8a4e                	mv	s4,s3
    800064a6:	a051                	j	8000652a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800064a8:	00fb86b3          	add	a3,s7,a5
    800064ac:	96da                	add	a3,a3,s6
    800064ae:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800064b2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800064b4:	0207c563          	bltz	a5,800064de <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800064b8:	2485                	addiw	s1,s1,1
    800064ba:	0711                	addi	a4,a4,4
    800064bc:	25548063          	beq	s1,s5,800066fc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800064c0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800064c2:	0001f697          	auipc	a3,0x1f
    800064c6:	b5668693          	addi	a3,a3,-1194 # 80025018 <disk+0x2018>
    800064ca:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800064cc:	0006c583          	lbu	a1,0(a3)
    800064d0:	fde1                	bnez	a1,800064a8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800064d2:	2785                	addiw	a5,a5,1
    800064d4:	0685                	addi	a3,a3,1
    800064d6:	ff879be3          	bne	a5,s8,800064cc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800064da:	57fd                	li	a5,-1
    800064dc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800064de:	02905a63          	blez	s1,80006512 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800064e2:	f9042503          	lw	a0,-112(s0)
    800064e6:	00000097          	auipc	ra,0x0
    800064ea:	d90080e7          	jalr	-624(ra) # 80006276 <free_desc>
      for(int j = 0; j < i; j++)
    800064ee:	4785                	li	a5,1
    800064f0:	0297d163          	bge	a5,s1,80006512 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800064f4:	f9442503          	lw	a0,-108(s0)
    800064f8:	00000097          	auipc	ra,0x0
    800064fc:	d7e080e7          	jalr	-642(ra) # 80006276 <free_desc>
      for(int j = 0; j < i; j++)
    80006500:	4789                	li	a5,2
    80006502:	0097d863          	bge	a5,s1,80006512 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006506:	f9842503          	lw	a0,-104(s0)
    8000650a:	00000097          	auipc	ra,0x0
    8000650e:	d6c080e7          	jalr	-660(ra) # 80006276 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006512:	0001f597          	auipc	a1,0x1f
    80006516:	c1658593          	addi	a1,a1,-1002 # 80025128 <disk+0x2128>
    8000651a:	0001f517          	auipc	a0,0x1f
    8000651e:	afe50513          	addi	a0,a0,-1282 # 80025018 <disk+0x2018>
    80006522:	ffffc097          	auipc	ra,0xffffc
    80006526:	020080e7          	jalr	32(ra) # 80002542 <sleep>
  for(int i = 0; i < 3; i++){
    8000652a:	f9040713          	addi	a4,s0,-112
    8000652e:	84ce                	mv	s1,s3
    80006530:	bf41                	j	800064c0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006532:	20058713          	addi	a4,a1,512
    80006536:	00471693          	slli	a3,a4,0x4
    8000653a:	0001d717          	auipc	a4,0x1d
    8000653e:	ac670713          	addi	a4,a4,-1338 # 80023000 <disk>
    80006542:	9736                	add	a4,a4,a3
    80006544:	4685                	li	a3,1
    80006546:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000654a:	20058713          	addi	a4,a1,512
    8000654e:	00471693          	slli	a3,a4,0x4
    80006552:	0001d717          	auipc	a4,0x1d
    80006556:	aae70713          	addi	a4,a4,-1362 # 80023000 <disk>
    8000655a:	9736                	add	a4,a4,a3
    8000655c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006560:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006564:	7679                	lui	a2,0xffffe
    80006566:	963e                	add	a2,a2,a5
    80006568:	0001f697          	auipc	a3,0x1f
    8000656c:	a9868693          	addi	a3,a3,-1384 # 80025000 <disk+0x2000>
    80006570:	6298                	ld	a4,0(a3)
    80006572:	9732                	add	a4,a4,a2
    80006574:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006576:	6298                	ld	a4,0(a3)
    80006578:	9732                	add	a4,a4,a2
    8000657a:	4541                	li	a0,16
    8000657c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000657e:	6298                	ld	a4,0(a3)
    80006580:	9732                	add	a4,a4,a2
    80006582:	4505                	li	a0,1
    80006584:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006588:	f9442703          	lw	a4,-108(s0)
    8000658c:	6288                	ld	a0,0(a3)
    8000658e:	962a                	add	a2,a2,a0
    80006590:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006594:	0712                	slli	a4,a4,0x4
    80006596:	6290                	ld	a2,0(a3)
    80006598:	963a                	add	a2,a2,a4
    8000659a:	05890513          	addi	a0,s2,88
    8000659e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800065a0:	6294                	ld	a3,0(a3)
    800065a2:	96ba                	add	a3,a3,a4
    800065a4:	40000613          	li	a2,1024
    800065a8:	c690                	sw	a2,8(a3)
  if(write)
    800065aa:	140d0063          	beqz	s10,800066ea <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800065ae:	0001f697          	auipc	a3,0x1f
    800065b2:	a526b683          	ld	a3,-1454(a3) # 80025000 <disk+0x2000>
    800065b6:	96ba                	add	a3,a3,a4
    800065b8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800065bc:	0001d817          	auipc	a6,0x1d
    800065c0:	a4480813          	addi	a6,a6,-1468 # 80023000 <disk>
    800065c4:	0001f517          	auipc	a0,0x1f
    800065c8:	a3c50513          	addi	a0,a0,-1476 # 80025000 <disk+0x2000>
    800065cc:	6114                	ld	a3,0(a0)
    800065ce:	96ba                	add	a3,a3,a4
    800065d0:	00c6d603          	lhu	a2,12(a3)
    800065d4:	00166613          	ori	a2,a2,1
    800065d8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800065dc:	f9842683          	lw	a3,-104(s0)
    800065e0:	6110                	ld	a2,0(a0)
    800065e2:	9732                	add	a4,a4,a2
    800065e4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800065e8:	20058613          	addi	a2,a1,512
    800065ec:	0612                	slli	a2,a2,0x4
    800065ee:	9642                	add	a2,a2,a6
    800065f0:	577d                	li	a4,-1
    800065f2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800065f6:	00469713          	slli	a4,a3,0x4
    800065fa:	6114                	ld	a3,0(a0)
    800065fc:	96ba                	add	a3,a3,a4
    800065fe:	03078793          	addi	a5,a5,48
    80006602:	97c2                	add	a5,a5,a6
    80006604:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006606:	611c                	ld	a5,0(a0)
    80006608:	97ba                	add	a5,a5,a4
    8000660a:	4685                	li	a3,1
    8000660c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000660e:	611c                	ld	a5,0(a0)
    80006610:	97ba                	add	a5,a5,a4
    80006612:	4809                	li	a6,2
    80006614:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006618:	611c                	ld	a5,0(a0)
    8000661a:	973e                	add	a4,a4,a5
    8000661c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006620:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006624:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006628:	6518                	ld	a4,8(a0)
    8000662a:	00275783          	lhu	a5,2(a4)
    8000662e:	8b9d                	andi	a5,a5,7
    80006630:	0786                	slli	a5,a5,0x1
    80006632:	97ba                	add	a5,a5,a4
    80006634:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006638:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000663c:	6518                	ld	a4,8(a0)
    8000663e:	00275783          	lhu	a5,2(a4)
    80006642:	2785                	addiw	a5,a5,1
    80006644:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006648:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000664c:	100017b7          	lui	a5,0x10001
    80006650:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006654:	00492703          	lw	a4,4(s2)
    80006658:	4785                	li	a5,1
    8000665a:	02f71163          	bne	a4,a5,8000667c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000665e:	0001f997          	auipc	s3,0x1f
    80006662:	aca98993          	addi	s3,s3,-1334 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006666:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006668:	85ce                	mv	a1,s3
    8000666a:	854a                	mv	a0,s2
    8000666c:	ffffc097          	auipc	ra,0xffffc
    80006670:	ed6080e7          	jalr	-298(ra) # 80002542 <sleep>
  while(b->disk == 1) {
    80006674:	00492783          	lw	a5,4(s2)
    80006678:	fe9788e3          	beq	a5,s1,80006668 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000667c:	f9042903          	lw	s2,-112(s0)
    80006680:	20090793          	addi	a5,s2,512
    80006684:	00479713          	slli	a4,a5,0x4
    80006688:	0001d797          	auipc	a5,0x1d
    8000668c:	97878793          	addi	a5,a5,-1672 # 80023000 <disk>
    80006690:	97ba                	add	a5,a5,a4
    80006692:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006696:	0001f997          	auipc	s3,0x1f
    8000669a:	96a98993          	addi	s3,s3,-1686 # 80025000 <disk+0x2000>
    8000669e:	00491713          	slli	a4,s2,0x4
    800066a2:	0009b783          	ld	a5,0(s3)
    800066a6:	97ba                	add	a5,a5,a4
    800066a8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800066ac:	854a                	mv	a0,s2
    800066ae:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800066b2:	00000097          	auipc	ra,0x0
    800066b6:	bc4080e7          	jalr	-1084(ra) # 80006276 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800066ba:	8885                	andi	s1,s1,1
    800066bc:	f0ed                	bnez	s1,8000669e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800066be:	0001f517          	auipc	a0,0x1f
    800066c2:	a6a50513          	addi	a0,a0,-1430 # 80025128 <disk+0x2128>
    800066c6:	ffffa097          	auipc	ra,0xffffa
    800066ca:	5d2080e7          	jalr	1490(ra) # 80000c98 <release>
}
    800066ce:	70a6                	ld	ra,104(sp)
    800066d0:	7406                	ld	s0,96(sp)
    800066d2:	64e6                	ld	s1,88(sp)
    800066d4:	6946                	ld	s2,80(sp)
    800066d6:	69a6                	ld	s3,72(sp)
    800066d8:	6a06                	ld	s4,64(sp)
    800066da:	7ae2                	ld	s5,56(sp)
    800066dc:	7b42                	ld	s6,48(sp)
    800066de:	7ba2                	ld	s7,40(sp)
    800066e0:	7c02                	ld	s8,32(sp)
    800066e2:	6ce2                	ld	s9,24(sp)
    800066e4:	6d42                	ld	s10,16(sp)
    800066e6:	6165                	addi	sp,sp,112
    800066e8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800066ea:	0001f697          	auipc	a3,0x1f
    800066ee:	9166b683          	ld	a3,-1770(a3) # 80025000 <disk+0x2000>
    800066f2:	96ba                	add	a3,a3,a4
    800066f4:	4609                	li	a2,2
    800066f6:	00c69623          	sh	a2,12(a3)
    800066fa:	b5c9                	j	800065bc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066fc:	f9042583          	lw	a1,-112(s0)
    80006700:	20058793          	addi	a5,a1,512
    80006704:	0792                	slli	a5,a5,0x4
    80006706:	0001d517          	auipc	a0,0x1d
    8000670a:	9a250513          	addi	a0,a0,-1630 # 800230a8 <disk+0xa8>
    8000670e:	953e                	add	a0,a0,a5
  if(write)
    80006710:	e20d11e3          	bnez	s10,80006532 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006714:	20058713          	addi	a4,a1,512
    80006718:	00471693          	slli	a3,a4,0x4
    8000671c:	0001d717          	auipc	a4,0x1d
    80006720:	8e470713          	addi	a4,a4,-1820 # 80023000 <disk>
    80006724:	9736                	add	a4,a4,a3
    80006726:	0a072423          	sw	zero,168(a4)
    8000672a:	b505                	j	8000654a <virtio_disk_rw+0xf4>

000000008000672c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000672c:	1101                	addi	sp,sp,-32
    8000672e:	ec06                	sd	ra,24(sp)
    80006730:	e822                	sd	s0,16(sp)
    80006732:	e426                	sd	s1,8(sp)
    80006734:	e04a                	sd	s2,0(sp)
    80006736:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006738:	0001f517          	auipc	a0,0x1f
    8000673c:	9f050513          	addi	a0,a0,-1552 # 80025128 <disk+0x2128>
    80006740:	ffffa097          	auipc	ra,0xffffa
    80006744:	4a4080e7          	jalr	1188(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006748:	10001737          	lui	a4,0x10001
    8000674c:	533c                	lw	a5,96(a4)
    8000674e:	8b8d                	andi	a5,a5,3
    80006750:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006752:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006756:	0001f797          	auipc	a5,0x1f
    8000675a:	8aa78793          	addi	a5,a5,-1878 # 80025000 <disk+0x2000>
    8000675e:	6b94                	ld	a3,16(a5)
    80006760:	0207d703          	lhu	a4,32(a5)
    80006764:	0026d783          	lhu	a5,2(a3)
    80006768:	06f70163          	beq	a4,a5,800067ca <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000676c:	0001d917          	auipc	s2,0x1d
    80006770:	89490913          	addi	s2,s2,-1900 # 80023000 <disk>
    80006774:	0001f497          	auipc	s1,0x1f
    80006778:	88c48493          	addi	s1,s1,-1908 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000677c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006780:	6898                	ld	a4,16(s1)
    80006782:	0204d783          	lhu	a5,32(s1)
    80006786:	8b9d                	andi	a5,a5,7
    80006788:	078e                	slli	a5,a5,0x3
    8000678a:	97ba                	add	a5,a5,a4
    8000678c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000678e:	20078713          	addi	a4,a5,512
    80006792:	0712                	slli	a4,a4,0x4
    80006794:	974a                	add	a4,a4,s2
    80006796:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000679a:	e731                	bnez	a4,800067e6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000679c:	20078793          	addi	a5,a5,512
    800067a0:	0792                	slli	a5,a5,0x4
    800067a2:	97ca                	add	a5,a5,s2
    800067a4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800067a6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800067aa:	ffffc097          	auipc	ra,0xffffc
    800067ae:	f36080e7          	jalr	-202(ra) # 800026e0 <wakeup>

    disk.used_idx += 1;
    800067b2:	0204d783          	lhu	a5,32(s1)
    800067b6:	2785                	addiw	a5,a5,1
    800067b8:	17c2                	slli	a5,a5,0x30
    800067ba:	93c1                	srli	a5,a5,0x30
    800067bc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800067c0:	6898                	ld	a4,16(s1)
    800067c2:	00275703          	lhu	a4,2(a4)
    800067c6:	faf71be3          	bne	a4,a5,8000677c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800067ca:	0001f517          	auipc	a0,0x1f
    800067ce:	95e50513          	addi	a0,a0,-1698 # 80025128 <disk+0x2128>
    800067d2:	ffffa097          	auipc	ra,0xffffa
    800067d6:	4c6080e7          	jalr	1222(ra) # 80000c98 <release>
}
    800067da:	60e2                	ld	ra,24(sp)
    800067dc:	6442                	ld	s0,16(sp)
    800067de:	64a2                	ld	s1,8(sp)
    800067e0:	6902                	ld	s2,0(sp)
    800067e2:	6105                	addi	sp,sp,32
    800067e4:	8082                	ret
      panic("virtio_disk_intr status");
    800067e6:	00002517          	auipc	a0,0x2
    800067ea:	0aa50513          	addi	a0,a0,170 # 80008890 <syscalls+0x3c0>
    800067ee:	ffffa097          	auipc	ra,0xffffa
    800067f2:	d50080e7          	jalr	-688(ra) # 8000053e <panic>

00000000800067f6 <cas>:
    800067f6:	100522af          	lr.w	t0,(a0)
    800067fa:	00b29563          	bne	t0,a1,80006804 <fail>
    800067fe:	18c5252f          	sc.w	a0,a2,(a0)
    80006802:	8082                	ret

0000000080006804 <fail>:
    80006804:	4505                	li	a0,1
    80006806:	8082                	ret
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
