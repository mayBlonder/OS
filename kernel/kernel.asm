
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	95013103          	ld	sp,-1712(sp) # 80008950 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	07c78793          	addi	a5,a5,124 # 800060e0 <timervec>
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
    80000130:	84c080e7          	jalr	-1972(ra) # 80002978 <either_copyin>
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
    800001c8:	b0a080e7          	jalr	-1270(ra) # 80001cce <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	300080e7          	jalr	768(ra) # 800024d4 <sleep>
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
    80000214:	712080e7          	jalr	1810(ra) # 80002922 <either_copyout>
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
    800002f6:	6dc080e7          	jalr	1756(ra) # 800029ce <procdump>
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
    8000044a:	22c080e7          	jalr	556(ra) # 80002672 <wakeup>
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
    800008a4:	dd2080e7          	jalr	-558(ra) # 80002672 <wakeup>
    
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
    80000930:	ba8080e7          	jalr	-1112(ra) # 800024d4 <sleep>
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
    80000b82:	12e080e7          	jalr	302(ra) # 80001cac <mycpu>
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
    80000bb4:	0fc080e7          	jalr	252(ra) # 80001cac <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	0f0080e7          	jalr	240(ra) # 80001cac <mycpu>
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
    80000bd8:	0d8080e7          	jalr	216(ra) # 80001cac <mycpu>
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
    80000c18:	098080e7          	jalr	152(ra) # 80001cac <mycpu>
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
    80000c44:	06c080e7          	jalr	108(ra) # 80001cac <mycpu>
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
    80000e9a:	e06080e7          	jalr	-506(ra) # 80001c9c <cpuid>
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
    80000eb6:	dea080e7          	jalr	-534(ra) # 80001c9c <cpuid>
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
    80000ed8:	cee080e7          	jalr	-786(ra) # 80002bc2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	244080e7          	jalr	580(ra) # 80006120 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	3f2080e7          	jalr	1010(ra) # 800022d6 <scheduler>
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
    80000f50:	c4e080e7          	jalr	-946(ra) # 80002b9a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	c6e080e7          	jalr	-914(ra) # 80002bc2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	1ae080e7          	jalr	430(ra) # 8000610a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	1bc080e7          	jalr	444(ra) # 80006120 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	398080e7          	jalr	920(ra) # 80003304 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	a28080e7          	jalr	-1496(ra) # 8000399c <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	9d2080e7          	jalr	-1582(ra) # 8000494e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	2be080e7          	jalr	702(ra) # 80006242 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	0c8080e7          	jalr	200(ra) # 80002054 <userinit>
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
    8000185e:	ecc080e7          	jalr	-308(ra) # 80006726 <cas>
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
  // Adding all processes to UNUSED list.
  struct proc *p;
  struct cpu *c;
  int i = 0;

  initlock(&sleeping_list.head_lock, "sleeping_list_head_lock");
    80001b30:	00006597          	auipc	a1,0x6
    80001b34:	6c058593          	addi	a1,a1,1728 # 800081f0 <digits+0x1b0>
    80001b38:	00007517          	auipc	a0,0x7
    80001b3c:	d8050513          	addi	a0,a0,-640 # 800088b8 <sleeping_list+0x8>
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	014080e7          	jalr	20(ra) # 80000b54 <initlock>
  initlock(&zombie_list.head_lock, "zombie_list_head_lock");
    80001b48:	00006597          	auipc	a1,0x6
    80001b4c:	6c058593          	addi	a1,a1,1728 # 80008208 <digits+0x1c8>
    80001b50:	00007517          	auipc	a0,0x7
    80001b54:	d8850513          	addi	a0,a0,-632 # 800088d8 <zombie_list+0x8>
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	ffc080e7          	jalr	-4(ra) # 80000b54 <initlock>
  initlock(&unused_list.head_lock, "unused_list_head_lock");
    80001b60:	00006597          	auipc	a1,0x6
    80001b64:	6c058593          	addi	a1,a1,1728 # 80008220 <digits+0x1e0>
    80001b68:	00007517          	auipc	a0,0x7
    80001b6c:	d9050513          	addi	a0,a0,-624 # 800088f8 <unused_list+0x8>
    80001b70:	fffff097          	auipc	ra,0xfffff
    80001b74:	fe4080e7          	jalr	-28(ra) # 80000b54 <initlock>
  initlock(&pid_lock, "nextpid");
    80001b78:	00006597          	auipc	a1,0x6
    80001b7c:	6c058593          	addi	a1,a1,1728 # 80008238 <digits+0x1f8>
    80001b80:	00010517          	auipc	a0,0x10
    80001b84:	c6050513          	addi	a0,a0,-928 # 800117e0 <pid_lock>
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	fcc080e7          	jalr	-52(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b90:	00006597          	auipc	a1,0x6
    80001b94:	6b058593          	addi	a1,a1,1712 # 80008240 <digits+0x200>
    80001b98:	00010517          	auipc	a0,0x10
    80001b9c:	c6050513          	addi	a0,a0,-928 # 800117f8 <wait_lock>
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
      append(&unused_list, p); 
    80001bd6:	00007b17          	auipc	s6,0x7
    80001bda:	d1ab0b13          	addi	s6,s6,-742 # 800088f0 <unused_list>
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
      append(&unused_list, p); 
    80001c28:	85a6                	mv	a1,s1
    80001c2a:	855a                	mv	a0,s6
    80001c2c:	00000097          	auipc	ra,0x0
    80001c30:	c5a080e7          	jalr	-934(ra) # 80001886 <append>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c34:	19048493          	addi	s1,s1,400
    80001c38:	fb5497e3          	bne	s1,s5,80001be6 <procinit+0xd2>
  }

  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001c3c:	0000f497          	auipc	s1,0xf
    80001c40:	66448493          	addi	s1,s1,1636 # 800112a0 <cpus>
    c->runnable_list = (struct linked_list){-1};
    80001c44:	5a7d                	li	s4,-1
    initlock(&c->runnable_list.head_lock, "cpu_runnable_list_head_lock");
    80001c46:	00006997          	auipc	s3,0x6
    80001c4a:	62298993          	addi	s3,s3,1570 # 80008268 <digits+0x228>
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001c4e:	00010917          	auipc	s2,0x10
    80001c52:	b9290913          	addi	s2,s2,-1134 # 800117e0 <pid_lock>
    c->runnable_list = (struct linked_list){-1};
    80001c56:	0804b423          	sd	zero,136(s1)
    80001c5a:	0804b823          	sd	zero,144(s1)
    80001c5e:	0804bc23          	sd	zero,152(s1)
    80001c62:	0a04b023          	sd	zero,160(s1)
    80001c66:	0944a423          	sw	s4,136(s1)
    initlock(&c->runnable_list.head_lock, "cpu_runnable_list_head_lock");
    80001c6a:	85ce                	mv	a1,s3
    80001c6c:	09048513          	addi	a0,s1,144
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	ee4080e7          	jalr	-284(ra) # 80000b54 <initlock>
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001c78:	0a848493          	addi	s1,s1,168
    80001c7c:	fd249de3          	bne	s1,s2,80001c56 <procinit+0x142>
  }
}
    80001c80:	60e6                	ld	ra,88(sp)
    80001c82:	6446                	ld	s0,80(sp)
    80001c84:	64a6                	ld	s1,72(sp)
    80001c86:	6906                	ld	s2,64(sp)
    80001c88:	79e2                	ld	s3,56(sp)
    80001c8a:	7a42                	ld	s4,48(sp)
    80001c8c:	7aa2                	ld	s5,40(sp)
    80001c8e:	7b02                	ld	s6,32(sp)
    80001c90:	6be2                	ld	s7,24(sp)
    80001c92:	6c42                	ld	s8,16(sp)
    80001c94:	6ca2                	ld	s9,8(sp)
    80001c96:	6d02                	ld	s10,0(sp)
    80001c98:	6125                	addi	sp,sp,96
    80001c9a:	8082                	ret

0000000080001c9c <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001c9c:	1141                	addi	sp,sp,-16
    80001c9e:	e422                	sd	s0,8(sp)
    80001ca0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ca2:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001ca4:	2501                	sext.w	a0,a0
    80001ca6:	6422                	ld	s0,8(sp)
    80001ca8:	0141                	addi	sp,sp,16
    80001caa:	8082                	ret

0000000080001cac <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001cac:	1141                	addi	sp,sp,-16
    80001cae:	e422                	sd	s0,8(sp)
    80001cb0:	0800                	addi	s0,sp,16
    80001cb2:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001cb4:	2781                	sext.w	a5,a5
    80001cb6:	0a800513          	li	a0,168
    80001cba:	02a787b3          	mul	a5,a5,a0
  return c;
}
    80001cbe:	0000f517          	auipc	a0,0xf
    80001cc2:	5e250513          	addi	a0,a0,1506 # 800112a0 <cpus>
    80001cc6:	953e                	add	a0,a0,a5
    80001cc8:	6422                	ld	s0,8(sp)
    80001cca:	0141                	addi	sp,sp,16
    80001ccc:	8082                	ret

0000000080001cce <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001cce:	1101                	addi	sp,sp,-32
    80001cd0:	ec06                	sd	ra,24(sp)
    80001cd2:	e822                	sd	s0,16(sp)
    80001cd4:	e426                	sd	s1,8(sp)
    80001cd6:	1000                	addi	s0,sp,32
  push_off();
    80001cd8:	fffff097          	auipc	ra,0xfffff
    80001cdc:	ec0080e7          	jalr	-320(ra) # 80000b98 <push_off>
    80001ce0:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ce2:	2781                	sext.w	a5,a5
    80001ce4:	0a800713          	li	a4,168
    80001ce8:	02e787b3          	mul	a5,a5,a4
    80001cec:	0000f717          	auipc	a4,0xf
    80001cf0:	5b470713          	addi	a4,a4,1460 # 800112a0 <cpus>
    80001cf4:	97ba                	add	a5,a5,a4
    80001cf6:	6384                	ld	s1,0(a5)
  pop_off();
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	f40080e7          	jalr	-192(ra) # 80000c38 <pop_off>
  return p;
}
    80001d00:	8526                	mv	a0,s1
    80001d02:	60e2                	ld	ra,24(sp)
    80001d04:	6442                	ld	s0,16(sp)
    80001d06:	64a2                	ld	s1,8(sp)
    80001d08:	6105                	addi	sp,sp,32
    80001d0a:	8082                	ret

0000000080001d0c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001d0c:	1141                	addi	sp,sp,-16
    80001d0e:	e406                	sd	ra,8(sp)
    80001d10:	e022                	sd	s0,0(sp)
    80001d12:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	fba080e7          	jalr	-70(ra) # 80001cce <myproc>
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	f7c080e7          	jalr	-132(ra) # 80000c98 <release>

  if (first) {
    80001d24:	00007797          	auipc	a5,0x7
    80001d28:	b7c7a783          	lw	a5,-1156(a5) # 800088a0 <first.1728>
    80001d2c:	eb89                	bnez	a5,80001d3e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001d2e:	00001097          	auipc	ra,0x1
    80001d32:	eac080e7          	jalr	-340(ra) # 80002bda <usertrapret>
}
    80001d36:	60a2                	ld	ra,8(sp)
    80001d38:	6402                	ld	s0,0(sp)
    80001d3a:	0141                	addi	sp,sp,16
    80001d3c:	8082                	ret
    first = 0;
    80001d3e:	00007797          	auipc	a5,0x7
    80001d42:	b607a123          	sw	zero,-1182(a5) # 800088a0 <first.1728>
    fsinit(ROOTDEV);
    80001d46:	4505                	li	a0,1
    80001d48:	00002097          	auipc	ra,0x2
    80001d4c:	bd4080e7          	jalr	-1068(ra) # 8000391c <fsinit>
    80001d50:	bff9                	j	80001d2e <forkret+0x22>

0000000080001d52 <allocpid>:
allocpid() {
    80001d52:	1101                	addi	sp,sp,-32
    80001d54:	ec06                	sd	ra,24(sp)
    80001d56:	e822                	sd	s0,16(sp)
    80001d58:	e426                	sd	s1,8(sp)
    80001d5a:	e04a                	sd	s2,0(sp)
    80001d5c:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001d5e:	00007917          	auipc	s2,0x7
    80001d62:	b4690913          	addi	s2,s2,-1210 # 800088a4 <nextpid>
    80001d66:	00092483          	lw	s1,0(s2)
  while (cas(&nextpid, pid, nextpid + 1));
    80001d6a:	0014861b          	addiw	a2,s1,1
    80001d6e:	85a6                	mv	a1,s1
    80001d70:	854a                	mv	a0,s2
    80001d72:	00005097          	auipc	ra,0x5
    80001d76:	9b4080e7          	jalr	-1612(ra) # 80006726 <cas>
    80001d7a:	2501                	sext.w	a0,a0
    80001d7c:	f56d                	bnez	a0,80001d66 <allocpid+0x14>
}
    80001d7e:	8526                	mv	a0,s1
    80001d80:	60e2                	ld	ra,24(sp)
    80001d82:	6442                	ld	s0,16(sp)
    80001d84:	64a2                	ld	s1,8(sp)
    80001d86:	6902                	ld	s2,0(sp)
    80001d88:	6105                	addi	sp,sp,32
    80001d8a:	8082                	ret

0000000080001d8c <proc_pagetable>:
{
    80001d8c:	1101                	addi	sp,sp,-32
    80001d8e:	ec06                	sd	ra,24(sp)
    80001d90:	e822                	sd	s0,16(sp)
    80001d92:	e426                	sd	s1,8(sp)
    80001d94:	e04a                	sd	s2,0(sp)
    80001d96:	1000                	addi	s0,sp,32
    80001d98:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001d9a:	fffff097          	auipc	ra,0xfffff
    80001d9e:	5a0080e7          	jalr	1440(ra) # 8000133a <uvmcreate>
    80001da2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001da4:	c121                	beqz	a0,80001de4 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001da6:	4729                	li	a4,10
    80001da8:	00005697          	auipc	a3,0x5
    80001dac:	25868693          	addi	a3,a3,600 # 80007000 <_trampoline>
    80001db0:	6605                	lui	a2,0x1
    80001db2:	040005b7          	lui	a1,0x4000
    80001db6:	15fd                	addi	a1,a1,-1
    80001db8:	05b2                	slli	a1,a1,0xc
    80001dba:	fffff097          	auipc	ra,0xfffff
    80001dbe:	2f6080e7          	jalr	758(ra) # 800010b0 <mappages>
    80001dc2:	02054863          	bltz	a0,80001df2 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001dc6:	4719                	li	a4,6
    80001dc8:	05893683          	ld	a3,88(s2)
    80001dcc:	6605                	lui	a2,0x1
    80001dce:	020005b7          	lui	a1,0x2000
    80001dd2:	15fd                	addi	a1,a1,-1
    80001dd4:	05b6                	slli	a1,a1,0xd
    80001dd6:	8526                	mv	a0,s1
    80001dd8:	fffff097          	auipc	ra,0xfffff
    80001ddc:	2d8080e7          	jalr	728(ra) # 800010b0 <mappages>
    80001de0:	02054163          	bltz	a0,80001e02 <proc_pagetable+0x76>
}
    80001de4:	8526                	mv	a0,s1
    80001de6:	60e2                	ld	ra,24(sp)
    80001de8:	6442                	ld	s0,16(sp)
    80001dea:	64a2                	ld	s1,8(sp)
    80001dec:	6902                	ld	s2,0(sp)
    80001dee:	6105                	addi	sp,sp,32
    80001df0:	8082                	ret
    uvmfree(pagetable, 0);
    80001df2:	4581                	li	a1,0
    80001df4:	8526                	mv	a0,s1
    80001df6:	fffff097          	auipc	ra,0xfffff
    80001dfa:	740080e7          	jalr	1856(ra) # 80001536 <uvmfree>
    return 0;
    80001dfe:	4481                	li	s1,0
    80001e00:	b7d5                	j	80001de4 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e02:	4681                	li	a3,0
    80001e04:	4605                	li	a2,1
    80001e06:	040005b7          	lui	a1,0x4000
    80001e0a:	15fd                	addi	a1,a1,-1
    80001e0c:	05b2                	slli	a1,a1,0xc
    80001e0e:	8526                	mv	a0,s1
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	466080e7          	jalr	1126(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001e18:	4581                	li	a1,0
    80001e1a:	8526                	mv	a0,s1
    80001e1c:	fffff097          	auipc	ra,0xfffff
    80001e20:	71a080e7          	jalr	1818(ra) # 80001536 <uvmfree>
    return 0;
    80001e24:	4481                	li	s1,0
    80001e26:	bf7d                	j	80001de4 <proc_pagetable+0x58>

0000000080001e28 <proc_freepagetable>:
{
    80001e28:	1101                	addi	sp,sp,-32
    80001e2a:	ec06                	sd	ra,24(sp)
    80001e2c:	e822                	sd	s0,16(sp)
    80001e2e:	e426                	sd	s1,8(sp)
    80001e30:	e04a                	sd	s2,0(sp)
    80001e32:	1000                	addi	s0,sp,32
    80001e34:	84aa                	mv	s1,a0
    80001e36:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e38:	4681                	li	a3,0
    80001e3a:	4605                	li	a2,1
    80001e3c:	040005b7          	lui	a1,0x4000
    80001e40:	15fd                	addi	a1,a1,-1
    80001e42:	05b2                	slli	a1,a1,0xc
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	432080e7          	jalr	1074(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e4c:	4681                	li	a3,0
    80001e4e:	4605                	li	a2,1
    80001e50:	020005b7          	lui	a1,0x2000
    80001e54:	15fd                	addi	a1,a1,-1
    80001e56:	05b6                	slli	a1,a1,0xd
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	41c080e7          	jalr	1052(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001e62:	85ca                	mv	a1,s2
    80001e64:	8526                	mv	a0,s1
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	6d0080e7          	jalr	1744(ra) # 80001536 <uvmfree>
}
    80001e6e:	60e2                	ld	ra,24(sp)
    80001e70:	6442                	ld	s0,16(sp)
    80001e72:	64a2                	ld	s1,8(sp)
    80001e74:	6902                	ld	s2,0(sp)
    80001e76:	6105                	addi	sp,sp,32
    80001e78:	8082                	ret

0000000080001e7a <freeproc>:
{
    80001e7a:	1101                	addi	sp,sp,-32
    80001e7c:	ec06                	sd	ra,24(sp)
    80001e7e:	e822                	sd	s0,16(sp)
    80001e80:	e426                	sd	s1,8(sp)
    80001e82:	1000                	addi	s0,sp,32
    80001e84:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001e86:	6d28                	ld	a0,88(a0)
    80001e88:	c509                	beqz	a0,80001e92 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	b6e080e7          	jalr	-1170(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001e92:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001e96:	68a8                	ld	a0,80(s1)
    80001e98:	c511                	beqz	a0,80001ea4 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001e9a:	64ac                	ld	a1,72(s1)
    80001e9c:	00000097          	auipc	ra,0x0
    80001ea0:	f8c080e7          	jalr	-116(ra) # 80001e28 <proc_freepagetable>
  p->pagetable = 0;
    80001ea4:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ea8:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001eac:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001eb0:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001eb4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001eb8:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ebc:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ec0:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ec4:	0004ac23          	sw	zero,24(s1)
  remove(remove_from_ZOMBIE_list, p); 
    80001ec8:	85a6                	mv	a1,s1
    80001eca:	00007517          	auipc	a0,0x7
    80001ece:	a0650513          	addi	a0,a0,-1530 # 800088d0 <zombie_list>
    80001ed2:	00000097          	auipc	ra,0x0
    80001ed6:	a7c080e7          	jalr	-1412(ra) # 8000194e <remove>
  append(add_to_UNUSED_list, p); 
    80001eda:	85a6                	mv	a1,s1
    80001edc:	00007517          	auipc	a0,0x7
    80001ee0:	a1450513          	addi	a0,a0,-1516 # 800088f0 <unused_list>
    80001ee4:	00000097          	auipc	ra,0x0
    80001ee8:	9a2080e7          	jalr	-1630(ra) # 80001886 <append>
}
    80001eec:	60e2                	ld	ra,24(sp)
    80001eee:	6442                	ld	s0,16(sp)
    80001ef0:	64a2                	ld	s1,8(sp)
    80001ef2:	6105                	addi	sp,sp,32
    80001ef4:	8082                	ret

0000000080001ef6 <allocproc>:
{
    80001ef6:	715d                	addi	sp,sp,-80
    80001ef8:	e486                	sd	ra,72(sp)
    80001efa:	e0a2                	sd	s0,64(sp)
    80001efc:	fc26                	sd	s1,56(sp)
    80001efe:	f84a                	sd	s2,48(sp)
    80001f00:	f44e                	sd	s3,40(sp)
    80001f02:	f052                	sd	s4,32(sp)
    80001f04:	ec56                	sd	s5,24(sp)
    80001f06:	e85a                	sd	s6,16(sp)
    80001f08:	e45e                	sd	s7,8(sp)
    80001f0a:	0880                	addi	s0,sp,80
    while(!(unused_list.head == -1)){
    80001f0c:	00007917          	auipc	s2,0x7
    80001f10:	9e492903          	lw	s2,-1564(s2) # 800088f0 <unused_list>
    80001f14:	57fd                	li	a5,-1
    80001f16:	12f90d63          	beq	s2,a5,80002050 <allocproc+0x15a>
    80001f1a:	19000a93          	li	s5,400
    p = &proc[unused_list.head];
    80001f1e:	00010a17          	auipc	s4,0x10
    80001f22:	8f2a0a13          	addi	s4,s4,-1806 # 80011810 <proc>
    while(!(unused_list.head == -1)){
    80001f26:	00007b97          	auipc	s7,0x7
    80001f2a:	98ab8b93          	addi	s7,s7,-1654 # 800088b0 <sleeping_list>
    80001f2e:	5b7d                	li	s6,-1
    p = &proc[unused_list.head];
    80001f30:	035909b3          	mul	s3,s2,s5
    80001f34:	014984b3          	add	s1,s3,s4
    acquire(&p->lock);
    80001f38:	8526                	mv	a0,s1
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	caa080e7          	jalr	-854(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001f42:	4c9c                	lw	a5,24(s1)
    80001f44:	c79d                	beqz	a5,80001f72 <allocproc+0x7c>
      release(&p->lock);
    80001f46:	8526                	mv	a0,s1
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	d50080e7          	jalr	-688(ra) # 80000c98 <release>
    while(!(unused_list.head == -1)){
    80001f50:	040ba903          	lw	s2,64(s7)
    80001f54:	fd691ee3          	bne	s2,s6,80001f30 <allocproc+0x3a>
  return 0;
    80001f58:	4481                	li	s1,0
}
    80001f5a:	8526                	mv	a0,s1
    80001f5c:	60a6                	ld	ra,72(sp)
    80001f5e:	6406                	ld	s0,64(sp)
    80001f60:	74e2                	ld	s1,56(sp)
    80001f62:	7942                	ld	s2,48(sp)
    80001f64:	79a2                	ld	s3,40(sp)
    80001f66:	7a02                	ld	s4,32(sp)
    80001f68:	6ae2                	ld	s5,24(sp)
    80001f6a:	6b42                	ld	s6,16(sp)
    80001f6c:	6ba2                	ld	s7,8(sp)
    80001f6e:	6161                	addi	sp,sp,80
    80001f70:	8082                	ret
      remove(&unused_list, p); 
    80001f72:	85a6                	mv	a1,s1
    80001f74:	00007517          	auipc	a0,0x7
    80001f78:	97c50513          	addi	a0,a0,-1668 # 800088f0 <unused_list>
    80001f7c:	00000097          	auipc	ra,0x0
    80001f80:	9d2080e7          	jalr	-1582(ra) # 8000194e <remove>
  p->pid = allocpid();
    80001f84:	00000097          	auipc	ra,0x0
    80001f88:	dce080e7          	jalr	-562(ra) # 80001d52 <allocpid>
    80001f8c:	19000a13          	li	s4,400
    80001f90:	034907b3          	mul	a5,s2,s4
    80001f94:	00010a17          	auipc	s4,0x10
    80001f98:	87ca0a13          	addi	s4,s4,-1924 # 80011810 <proc>
    80001f9c:	9a3e                	add	s4,s4,a5
    80001f9e:	02aa2823          	sw	a0,48(s4)
  p->state = USED;
    80001fa2:	4785                	li	a5,1
    80001fa4:	00fa2c23          	sw	a5,24(s4)
  p->last_cpu = -1;
    80001fa8:	57fd                	li	a5,-1
    80001faa:	16fa2423          	sw	a5,360(s4)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001fae:	fffff097          	auipc	ra,0xfffff
    80001fb2:	b46080e7          	jalr	-1210(ra) # 80000af4 <kalloc>
    80001fb6:	8aaa                	mv	s5,a0
    80001fb8:	04aa3c23          	sd	a0,88(s4)
    80001fbc:	c135                	beqz	a0,80002020 <allocproc+0x12a>
  p->pagetable = proc_pagetable(p);
    80001fbe:	8526                	mv	a0,s1
    80001fc0:	00000097          	auipc	ra,0x0
    80001fc4:	dcc080e7          	jalr	-564(ra) # 80001d8c <proc_pagetable>
    80001fc8:	8a2a                	mv	s4,a0
    80001fca:	19000793          	li	a5,400
    80001fce:	02f90733          	mul	a4,s2,a5
    80001fd2:	00010797          	auipc	a5,0x10
    80001fd6:	83e78793          	addi	a5,a5,-1986 # 80011810 <proc>
    80001fda:	97ba                	add	a5,a5,a4
    80001fdc:	eba8                	sd	a0,80(a5)
  if(p->pagetable == 0){
    80001fde:	cd29                	beqz	a0,80002038 <allocproc+0x142>
  memset(&p->context, 0, sizeof(p->context));
    80001fe0:	06098513          	addi	a0,s3,96
    80001fe4:	00010997          	auipc	s3,0x10
    80001fe8:	82c98993          	addi	s3,s3,-2004 # 80011810 <proc>
    80001fec:	07000613          	li	a2,112
    80001ff0:	4581                	li	a1,0
    80001ff2:	954e                	add	a0,a0,s3
    80001ff4:	fffff097          	auipc	ra,0xfffff
    80001ff8:	cec080e7          	jalr	-788(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001ffc:	19000793          	li	a5,400
    80002000:	02f90933          	mul	s2,s2,a5
    80002004:	994e                	add	s2,s2,s3
    80002006:	00000797          	auipc	a5,0x0
    8000200a:	d0678793          	addi	a5,a5,-762 # 80001d0c <forkret>
    8000200e:	06f93023          	sd	a5,96(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002012:	04093783          	ld	a5,64(s2)
    80002016:	6705                	lui	a4,0x1
    80002018:	97ba                	add	a5,a5,a4
    8000201a:	06f93423          	sd	a5,104(s2)
  return p;
    8000201e:	bf35                	j	80001f5a <allocproc+0x64>
    freeproc(p);
    80002020:	8526                	mv	a0,s1
    80002022:	00000097          	auipc	ra,0x0
    80002026:	e58080e7          	jalr	-424(ra) # 80001e7a <freeproc>
    release(&p->lock);
    8000202a:	8526                	mv	a0,s1
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	c6c080e7          	jalr	-916(ra) # 80000c98 <release>
    return 0;
    80002034:	84d6                	mv	s1,s5
    80002036:	b715                	j	80001f5a <allocproc+0x64>
    freeproc(p);
    80002038:	8526                	mv	a0,s1
    8000203a:	00000097          	auipc	ra,0x0
    8000203e:	e40080e7          	jalr	-448(ra) # 80001e7a <freeproc>
    release(&p->lock);
    80002042:	8526                	mv	a0,s1
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	c54080e7          	jalr	-940(ra) # 80000c98 <release>
    return 0;
    8000204c:	84d2                	mv	s1,s4
    8000204e:	b731                	j	80001f5a <allocproc+0x64>
  return 0;
    80002050:	4481                	li	s1,0
    80002052:	b721                	j	80001f5a <allocproc+0x64>

0000000080002054 <userinit>:
{
    80002054:	1101                	addi	sp,sp,-32
    80002056:	ec06                	sd	ra,24(sp)
    80002058:	e822                	sd	s0,16(sp)
    8000205a:	e426                	sd	s1,8(sp)
    8000205c:	1000                	addi	s0,sp,32
  p = allocproc();
    8000205e:	00000097          	auipc	ra,0x0
    80002062:	e98080e7          	jalr	-360(ra) # 80001ef6 <allocproc>
    80002066:	84aa                	mv	s1,a0
  initproc = p;
    80002068:	00007797          	auipc	a5,0x7
    8000206c:	fca7b023          	sd	a0,-64(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002070:	03400613          	li	a2,52
    80002074:	00007597          	auipc	a1,0x7
    80002078:	89c58593          	addi	a1,a1,-1892 # 80008910 <initcode>
    8000207c:	6928                	ld	a0,80(a0)
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	2ea080e7          	jalr	746(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80002086:	6785                	lui	a5,0x1
    80002088:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    8000208a:	6cb8                	ld	a4,88(s1)
    8000208c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002090:	6cb8                	ld	a4,88(s1)
    80002092:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002094:	4641                	li	a2,16
    80002096:	00006597          	auipc	a1,0x6
    8000209a:	1f258593          	addi	a1,a1,498 # 80008288 <digits+0x248>
    8000209e:	15848513          	addi	a0,s1,344
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	d90080e7          	jalr	-624(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800020aa:	00006517          	auipc	a0,0x6
    800020ae:	1ee50513          	addi	a0,a0,494 # 80008298 <digits+0x258>
    800020b2:	00002097          	auipc	ra,0x2
    800020b6:	298080e7          	jalr	664(ra) # 8000434a <namei>
    800020ba:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    800020be:	478d                	li	a5,3
    800020c0:	cc9c                	sw	a5,24(s1)
  append(l, p);
    800020c2:	85a6                	mv	a1,s1
    800020c4:	0000f517          	auipc	a0,0xf
    800020c8:	26450513          	addi	a0,a0,612 # 80011328 <cpus+0x88>
    800020cc:	fffff097          	auipc	ra,0xfffff
    800020d0:	7ba080e7          	jalr	1978(ra) # 80001886 <append>
  release(&p->lock);
    800020d4:	8526                	mv	a0,s1
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	bc2080e7          	jalr	-1086(ra) # 80000c98 <release>
}
    800020de:	60e2                	ld	ra,24(sp)
    800020e0:	6442                	ld	s0,16(sp)
    800020e2:	64a2                	ld	s1,8(sp)
    800020e4:	6105                	addi	sp,sp,32
    800020e6:	8082                	ret

00000000800020e8 <growproc>:
{
    800020e8:	1101                	addi	sp,sp,-32
    800020ea:	ec06                	sd	ra,24(sp)
    800020ec:	e822                	sd	s0,16(sp)
    800020ee:	e426                	sd	s1,8(sp)
    800020f0:	e04a                	sd	s2,0(sp)
    800020f2:	1000                	addi	s0,sp,32
    800020f4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800020f6:	00000097          	auipc	ra,0x0
    800020fa:	bd8080e7          	jalr	-1064(ra) # 80001cce <myproc>
    800020fe:	892a                	mv	s2,a0
  sz = p->sz;
    80002100:	652c                	ld	a1,72(a0)
    80002102:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002106:	00904f63          	bgtz	s1,80002124 <growproc+0x3c>
  } else if(n < 0){
    8000210a:	0204cc63          	bltz	s1,80002142 <growproc+0x5a>
  p->sz = sz;
    8000210e:	1602                	slli	a2,a2,0x20
    80002110:	9201                	srli	a2,a2,0x20
    80002112:	04c93423          	sd	a2,72(s2)
  return 0;
    80002116:	4501                	li	a0,0
}
    80002118:	60e2                	ld	ra,24(sp)
    8000211a:	6442                	ld	s0,16(sp)
    8000211c:	64a2                	ld	s1,8(sp)
    8000211e:	6902                	ld	s2,0(sp)
    80002120:	6105                	addi	sp,sp,32
    80002122:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002124:	9e25                	addw	a2,a2,s1
    80002126:	1602                	slli	a2,a2,0x20
    80002128:	9201                	srli	a2,a2,0x20
    8000212a:	1582                	slli	a1,a1,0x20
    8000212c:	9181                	srli	a1,a1,0x20
    8000212e:	6928                	ld	a0,80(a0)
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	2f2080e7          	jalr	754(ra) # 80001422 <uvmalloc>
    80002138:	0005061b          	sext.w	a2,a0
    8000213c:	fa69                	bnez	a2,8000210e <growproc+0x26>
      return -1;
    8000213e:	557d                	li	a0,-1
    80002140:	bfe1                	j	80002118 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002142:	9e25                	addw	a2,a2,s1
    80002144:	1602                	slli	a2,a2,0x20
    80002146:	9201                	srli	a2,a2,0x20
    80002148:	1582                	slli	a1,a1,0x20
    8000214a:	9181                	srli	a1,a1,0x20
    8000214c:	6928                	ld	a0,80(a0)
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	28c080e7          	jalr	652(ra) # 800013da <uvmdealloc>
    80002156:	0005061b          	sext.w	a2,a0
    8000215a:	bf55                	j	8000210e <growproc+0x26>

000000008000215c <fork>:
{
    8000215c:	7139                	addi	sp,sp,-64
    8000215e:	fc06                	sd	ra,56(sp)
    80002160:	f822                	sd	s0,48(sp)
    80002162:	f426                	sd	s1,40(sp)
    80002164:	f04a                	sd	s2,32(sp)
    80002166:	ec4e                	sd	s3,24(sp)
    80002168:	e852                	sd	s4,16(sp)
    8000216a:	e456                	sd	s5,8(sp)
    8000216c:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	b60080e7          	jalr	-1184(ra) # 80001cce <myproc>
    80002176:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80002178:	00000097          	auipc	ra,0x0
    8000217c:	d7e080e7          	jalr	-642(ra) # 80001ef6 <allocproc>
    80002180:	14050963          	beqz	a0,800022d2 <fork+0x176>
    80002184:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002186:	0489b603          	ld	a2,72(s3)
    8000218a:	692c                	ld	a1,80(a0)
    8000218c:	0509b503          	ld	a0,80(s3)
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	3de080e7          	jalr	990(ra) # 8000156e <uvmcopy>
    80002198:	04054663          	bltz	a0,800021e4 <fork+0x88>
  np->sz = p->sz;
    8000219c:	0489b783          	ld	a5,72(s3)
    800021a0:	04f93423          	sd	a5,72(s2)
  *(np->trapframe) = *(p->trapframe);
    800021a4:	0589b683          	ld	a3,88(s3)
    800021a8:	87b6                	mv	a5,a3
    800021aa:	05893703          	ld	a4,88(s2)
    800021ae:	12068693          	addi	a3,a3,288
    800021b2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800021b6:	6788                	ld	a0,8(a5)
    800021b8:	6b8c                	ld	a1,16(a5)
    800021ba:	6f90                	ld	a2,24(a5)
    800021bc:	01073023          	sd	a6,0(a4)
    800021c0:	e708                	sd	a0,8(a4)
    800021c2:	eb0c                	sd	a1,16(a4)
    800021c4:	ef10                	sd	a2,24(a4)
    800021c6:	02078793          	addi	a5,a5,32
    800021ca:	02070713          	addi	a4,a4,32
    800021ce:	fed792e3          	bne	a5,a3,800021b2 <fork+0x56>
  np->trapframe->a0 = 0;
    800021d2:	05893783          	ld	a5,88(s2)
    800021d6:	0607b823          	sd	zero,112(a5)
    800021da:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    800021de:	15000a13          	li	s4,336
    800021e2:	a03d                	j	80002210 <fork+0xb4>
    freeproc(np);
    800021e4:	854a                	mv	a0,s2
    800021e6:	00000097          	auipc	ra,0x0
    800021ea:	c94080e7          	jalr	-876(ra) # 80001e7a <freeproc>
    release(&np->lock);
    800021ee:	854a                	mv	a0,s2
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	aa8080e7          	jalr	-1368(ra) # 80000c98 <release>
    return -1;
    800021f8:	5afd                	li	s5,-1
    800021fa:	a0d1                	j	800022be <fork+0x162>
      np->ofile[i] = filedup(p->ofile[i]);
    800021fc:	00002097          	auipc	ra,0x2
    80002200:	7e4080e7          	jalr	2020(ra) # 800049e0 <filedup>
    80002204:	009907b3          	add	a5,s2,s1
    80002208:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    8000220a:	04a1                	addi	s1,s1,8
    8000220c:	01448763          	beq	s1,s4,8000221a <fork+0xbe>
    if(p->ofile[i])
    80002210:	009987b3          	add	a5,s3,s1
    80002214:	6388                	ld	a0,0(a5)
    80002216:	f17d                	bnez	a0,800021fc <fork+0xa0>
    80002218:	bfcd                	j	8000220a <fork+0xae>
  np->cwd = idup(p->cwd);
    8000221a:	1509b503          	ld	a0,336(s3)
    8000221e:	00002097          	auipc	ra,0x2
    80002222:	938080e7          	jalr	-1736(ra) # 80003b56 <idup>
    80002226:	14a93823          	sd	a0,336(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000222a:	4641                	li	a2,16
    8000222c:	15898593          	addi	a1,s3,344
    80002230:	15890513          	addi	a0,s2,344
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	bfe080e7          	jalr	-1026(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    8000223c:	03092a83          	lw	s5,48(s2)
  release(&np->lock);
    80002240:	854a                	mv	a0,s2
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
  acquire(&wait_lock);
    8000224a:	0000f497          	auipc	s1,0xf
    8000224e:	05648493          	addi	s1,s1,86 # 800112a0 <cpus>
    80002252:	0000fa17          	auipc	s4,0xf
    80002256:	5a6a0a13          	addi	s4,s4,1446 # 800117f8 <wait_lock>
    8000225a:	8552                	mv	a0,s4
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	988080e7          	jalr	-1656(ra) # 80000be4 <acquire>
  np->parent = p;
    80002264:	03393c23          	sd	s3,56(s2)
  release(&wait_lock);
    80002268:	8552                	mv	a0,s4
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	a2e080e7          	jalr	-1490(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002272:	854a                	mv	a0,s2
    80002274:	fffff097          	auipc	ra,0xfffff
    80002278:	970080e7          	jalr	-1680(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    8000227c:	478d                	li	a5,3
    8000227e:	00f92c23          	sw	a5,24(s2)
  int last_cpu = p->last_cpu; 
    80002282:	1689a503          	lw	a0,360(s3)
  np->last_cpu = last_cpu;
    80002286:	16a92423          	sw	a0,360(s2)
  inc_cpu(&cpus[np->last_cpu]);
    8000228a:	0a800993          	li	s3,168
    8000228e:	03350533          	mul	a0,a0,s3
    80002292:	9526                	add	a0,a0,s1
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	5aa080e7          	jalr	1450(ra) # 8000183e <inc_cpu>
  append(&(cpus[np->last_cpu].runnable_list), np); 
    8000229c:	16892503          	lw	a0,360(s2)
    800022a0:	03350533          	mul	a0,a0,s3
    800022a4:	08850513          	addi	a0,a0,136
    800022a8:	85ca                	mv	a1,s2
    800022aa:	9526                	add	a0,a0,s1
    800022ac:	fffff097          	auipc	ra,0xfffff
    800022b0:	5da080e7          	jalr	1498(ra) # 80001886 <append>
  release(&np->lock);
    800022b4:	854a                	mv	a0,s2
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	9e2080e7          	jalr	-1566(ra) # 80000c98 <release>
}
    800022be:	8556                	mv	a0,s5
    800022c0:	70e2                	ld	ra,56(sp)
    800022c2:	7442                	ld	s0,48(sp)
    800022c4:	74a2                	ld	s1,40(sp)
    800022c6:	7902                	ld	s2,32(sp)
    800022c8:	69e2                	ld	s3,24(sp)
    800022ca:	6a42                	ld	s4,16(sp)
    800022cc:	6aa2                	ld	s5,8(sp)
    800022ce:	6121                	addi	sp,sp,64
    800022d0:	8082                	ret
    return -1;
    800022d2:	5afd                	li	s5,-1
    800022d4:	b7ed                	j	800022be <fork+0x162>

00000000800022d6 <scheduler>:
{
    800022d6:	715d                	addi	sp,sp,-80
    800022d8:	e486                	sd	ra,72(sp)
    800022da:	e0a2                	sd	s0,64(sp)
    800022dc:	fc26                	sd	s1,56(sp)
    800022de:	f84a                	sd	s2,48(sp)
    800022e0:	f44e                	sd	s3,40(sp)
    800022e2:	f052                	sd	s4,32(sp)
    800022e4:	ec56                	sd	s5,24(sp)
    800022e6:	e85a                	sd	s6,16(sp)
    800022e8:	e45e                	sd	s7,8(sp)
    800022ea:	e062                	sd	s8,0(sp)
    800022ec:	0880                	addi	s0,sp,80
    800022ee:	8712                	mv	a4,tp
  int id = r_tp();
    800022f0:	2701                	sext.w	a4,a4
  c->proc = 0;
    800022f2:	0000fb17          	auipc	s6,0xf
    800022f6:	faeb0b13          	addi	s6,s6,-82 # 800112a0 <cpus>
    800022fa:	0a800793          	li	a5,168
    800022fe:	02f707b3          	mul	a5,a4,a5
    80002302:	00fb06b3          	add	a3,s6,a5
    80002306:	0006b023          	sd	zero,0(a3)
        remove(&(c->runnable_list), p);
    8000230a:	08878b93          	addi	s7,a5,136
    8000230e:	9bda                	add	s7,s7,s6
        swtch(&c->context, &p->context);
    80002310:	07a1                	addi	a5,a5,8
    80002312:	9b3e                	add	s6,s6,a5
    while(!(c->runnable_list.head == -1)) {
    80002314:	89b6                	mv	s3,a3
      if(p->state == RUNNABLE) {
    80002316:	0000fa17          	auipc	s4,0xf
    8000231a:	4faa0a13          	addi	s4,s4,1274 # 80011810 <proc>
    8000231e:	19000a93          	li	s5,400
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002322:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002326:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000232a:	10079073          	csrw	sstatus,a5
    8000232e:	490d                	li	s2,3
    while(!(c->runnable_list.head == -1)) {
    80002330:	0889a783          	lw	a5,136(s3)
    80002334:	56fd                	li	a3,-1
      if(p->state == RUNNABLE) {
    80002336:	03578733          	mul	a4,a5,s5
    8000233a:	9752                	add	a4,a4,s4
    while(!(c->runnable_list.head == -1)) {
    8000233c:	fed783e3          	beq	a5,a3,80002322 <scheduler+0x4c>
      if(p->state == RUNNABLE) {
    80002340:	4f10                	lw	a2,24(a4)
    80002342:	ff261de3          	bne	a2,s2,8000233c <scheduler+0x66>
    80002346:	035784b3          	mul	s1,a5,s5
      p = &proc[c->runnable_list.head];
    8000234a:	01448c33          	add	s8,s1,s4
        acquire(&p->lock);
    8000234e:	8562                	mv	a0,s8
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	894080e7          	jalr	-1900(ra) # 80000be4 <acquire>
        remove(&(c->runnable_list), p);
    80002358:	85e2                	mv	a1,s8
    8000235a:	855e                	mv	a0,s7
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	5f2080e7          	jalr	1522(ra) # 8000194e <remove>
        p->state = RUNNING;
    80002364:	4791                	li	a5,4
    80002366:	00fc2c23          	sw	a5,24(s8)
        c->proc = p;
    8000236a:	0189b023          	sd	s8,0(s3)
        p->last_cpu = c->cpu_id;
    8000236e:	0849a783          	lw	a5,132(s3)
    80002372:	16fc2423          	sw	a5,360(s8)
        swtch(&c->context, &p->context);
    80002376:	06048593          	addi	a1,s1,96
    8000237a:	95d2                	add	a1,a1,s4
    8000237c:	855a                	mv	a0,s6
    8000237e:	00000097          	auipc	ra,0x0
    80002382:	7b2080e7          	jalr	1970(ra) # 80002b30 <swtch>
        c->proc = 0;
    80002386:	0009b023          	sd	zero,0(s3)
        release(&p->lock);
    8000238a:	8562                	mv	a0,s8
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	90c080e7          	jalr	-1780(ra) # 80000c98 <release>
    80002394:	bf71                	j	80002330 <scheduler+0x5a>

0000000080002396 <sched>:
{
    80002396:	7179                	addi	sp,sp,-48
    80002398:	f406                	sd	ra,40(sp)
    8000239a:	f022                	sd	s0,32(sp)
    8000239c:	ec26                	sd	s1,24(sp)
    8000239e:	e84a                	sd	s2,16(sp)
    800023a0:	e44e                	sd	s3,8(sp)
    800023a2:	e052                	sd	s4,0(sp)
    800023a4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800023a6:	00000097          	auipc	ra,0x0
    800023aa:	928080e7          	jalr	-1752(ra) # 80001cce <myproc>
    800023ae:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800023b0:	ffffe097          	auipc	ra,0xffffe
    800023b4:	7ba080e7          	jalr	1978(ra) # 80000b6a <holding>
    800023b8:	c141                	beqz	a0,80002438 <sched+0xa2>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023ba:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800023bc:	2781                	sext.w	a5,a5
    800023be:	0a800713          	li	a4,168
    800023c2:	02e787b3          	mul	a5,a5,a4
    800023c6:	0000f717          	auipc	a4,0xf
    800023ca:	eda70713          	addi	a4,a4,-294 # 800112a0 <cpus>
    800023ce:	97ba                	add	a5,a5,a4
    800023d0:	5fb8                	lw	a4,120(a5)
    800023d2:	4785                	li	a5,1
    800023d4:	06f71a63          	bne	a4,a5,80002448 <sched+0xb2>
  if(p->state == RUNNING)
    800023d8:	4c98                	lw	a4,24(s1)
    800023da:	4791                	li	a5,4
    800023dc:	06f70e63          	beq	a4,a5,80002458 <sched+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023e0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800023e4:	8b89                	andi	a5,a5,2
  if(intr_get())
    800023e6:	e3c9                	bnez	a5,80002468 <sched+0xd2>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023e8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800023ea:	0000f917          	auipc	s2,0xf
    800023ee:	eb690913          	addi	s2,s2,-330 # 800112a0 <cpus>
    800023f2:	2781                	sext.w	a5,a5
    800023f4:	0a800993          	li	s3,168
    800023f8:	033787b3          	mul	a5,a5,s3
    800023fc:	97ca                	add	a5,a5,s2
    800023fe:	07c7aa03          	lw	s4,124(a5)
    80002402:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    80002404:	2581                	sext.w	a1,a1
    80002406:	033585b3          	mul	a1,a1,s3
    8000240a:	05a1                	addi	a1,a1,8
    8000240c:	95ca                	add	a1,a1,s2
    8000240e:	06048513          	addi	a0,s1,96
    80002412:	00000097          	auipc	ra,0x0
    80002416:	71e080e7          	jalr	1822(ra) # 80002b30 <swtch>
    8000241a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000241c:	2781                	sext.w	a5,a5
    8000241e:	033787b3          	mul	a5,a5,s3
    80002422:	993e                	add	s2,s2,a5
    80002424:	07492e23          	sw	s4,124(s2)
}
    80002428:	70a2                	ld	ra,40(sp)
    8000242a:	7402                	ld	s0,32(sp)
    8000242c:	64e2                	ld	s1,24(sp)
    8000242e:	6942                	ld	s2,16(sp)
    80002430:	69a2                	ld	s3,8(sp)
    80002432:	6a02                	ld	s4,0(sp)
    80002434:	6145                	addi	sp,sp,48
    80002436:	8082                	ret
    panic("sched p->lock");
    80002438:	00006517          	auipc	a0,0x6
    8000243c:	e6850513          	addi	a0,a0,-408 # 800082a0 <digits+0x260>
    80002440:	ffffe097          	auipc	ra,0xffffe
    80002444:	0fe080e7          	jalr	254(ra) # 8000053e <panic>
    panic("sched locks");
    80002448:	00006517          	auipc	a0,0x6
    8000244c:	e6850513          	addi	a0,a0,-408 # 800082b0 <digits+0x270>
    80002450:	ffffe097          	auipc	ra,0xffffe
    80002454:	0ee080e7          	jalr	238(ra) # 8000053e <panic>
    panic("sched running");
    80002458:	00006517          	auipc	a0,0x6
    8000245c:	e6850513          	addi	a0,a0,-408 # 800082c0 <digits+0x280>
    80002460:	ffffe097          	auipc	ra,0xffffe
    80002464:	0de080e7          	jalr	222(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002468:	00006517          	auipc	a0,0x6
    8000246c:	e6850513          	addi	a0,a0,-408 # 800082d0 <digits+0x290>
    80002470:	ffffe097          	auipc	ra,0xffffe
    80002474:	0ce080e7          	jalr	206(ra) # 8000053e <panic>

0000000080002478 <yield>:
{
    80002478:	1101                	addi	sp,sp,-32
    8000247a:	ec06                	sd	ra,24(sp)
    8000247c:	e822                	sd	s0,16(sp)
    8000247e:	e426                	sd	s1,8(sp)
    80002480:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002482:	00000097          	auipc	ra,0x0
    80002486:	84c080e7          	jalr	-1972(ra) # 80001cce <myproc>
    8000248a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000248c:	ffffe097          	auipc	ra,0xffffe
    80002490:	758080e7          	jalr	1880(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002494:	478d                	li	a5,3
    80002496:	cc9c                	sw	a5,24(s1)
    80002498:	8792                	mv	a5,tp
  append(&(mycpu()->runnable_list), p);
    8000249a:	2781                	sext.w	a5,a5
    8000249c:	0a800513          	li	a0,168
    800024a0:	02a787b3          	mul	a5,a5,a0
    800024a4:	85a6                	mv	a1,s1
    800024a6:	0000f517          	auipc	a0,0xf
    800024aa:	e8250513          	addi	a0,a0,-382 # 80011328 <cpus+0x88>
    800024ae:	953e                	add	a0,a0,a5
    800024b0:	fffff097          	auipc	ra,0xfffff
    800024b4:	3d6080e7          	jalr	982(ra) # 80001886 <append>
  sched();
    800024b8:	00000097          	auipc	ra,0x0
    800024bc:	ede080e7          	jalr	-290(ra) # 80002396 <sched>
  release(&p->lock);
    800024c0:	8526                	mv	a0,s1
    800024c2:	ffffe097          	auipc	ra,0xffffe
    800024c6:	7d6080e7          	jalr	2006(ra) # 80000c98 <release>
}
    800024ca:	60e2                	ld	ra,24(sp)
    800024cc:	6442                	ld	s0,16(sp)
    800024ce:	64a2                	ld	s1,8(sp)
    800024d0:	6105                	addi	sp,sp,32
    800024d2:	8082                	ret

00000000800024d4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800024d4:	7179                	addi	sp,sp,-48
    800024d6:	f406                	sd	ra,40(sp)
    800024d8:	f022                	sd	s0,32(sp)
    800024da:	ec26                	sd	s1,24(sp)
    800024dc:	e84a                	sd	s2,16(sp)
    800024de:	e44e                	sd	s3,8(sp)
    800024e0:	1800                	addi	s0,sp,48
    800024e2:	89aa                	mv	s3,a0
    800024e4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800024e6:	fffff097          	auipc	ra,0xfffff
    800024ea:	7e8080e7          	jalr	2024(ra) # 80001cce <myproc>
    800024ee:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);
    800024f0:	ffffe097          	auipc	ra,0xffffe
    800024f4:	6f4080e7          	jalr	1780(ra) # 80000be4 <acquire>
  release(lk);
    800024f8:	854a                	mv	a0,s2
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	79e080e7          	jalr	1950(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002502:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002506:	4789                	li	a5,2
    80002508:	cc9c                	sw	a5,24(s1)

  struct linked_list *add_to_SLEEPING_list = &sleeping_list;
  append(add_to_SLEEPING_list, p);
    8000250a:	85a6                	mv	a1,s1
    8000250c:	00006517          	auipc	a0,0x6
    80002510:	3a450513          	addi	a0,a0,932 # 800088b0 <sleeping_list>
    80002514:	fffff097          	auipc	ra,0xfffff
    80002518:	372080e7          	jalr	882(ra) # 80001886 <append>

  sched();
    8000251c:	00000097          	auipc	ra,0x0
    80002520:	e7a080e7          	jalr	-390(ra) # 80002396 <sched>

  // Tidy up.
  p->chan = 0;
    80002524:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002528:	8526                	mv	a0,s1
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	76e080e7          	jalr	1902(ra) # 80000c98 <release>
  acquire(lk);
    80002532:	854a                	mv	a0,s2
    80002534:	ffffe097          	auipc	ra,0xffffe
    80002538:	6b0080e7          	jalr	1712(ra) # 80000be4 <acquire>
}
    8000253c:	70a2                	ld	ra,40(sp)
    8000253e:	7402                	ld	s0,32(sp)
    80002540:	64e2                	ld	s1,24(sp)
    80002542:	6942                	ld	s2,16(sp)
    80002544:	69a2                	ld	s3,8(sp)
    80002546:	6145                	addi	sp,sp,48
    80002548:	8082                	ret

000000008000254a <wait>:
{
    8000254a:	715d                	addi	sp,sp,-80
    8000254c:	e486                	sd	ra,72(sp)
    8000254e:	e0a2                	sd	s0,64(sp)
    80002550:	fc26                	sd	s1,56(sp)
    80002552:	f84a                	sd	s2,48(sp)
    80002554:	f44e                	sd	s3,40(sp)
    80002556:	f052                	sd	s4,32(sp)
    80002558:	ec56                	sd	s5,24(sp)
    8000255a:	e85a                	sd	s6,16(sp)
    8000255c:	e45e                	sd	s7,8(sp)
    8000255e:	e062                	sd	s8,0(sp)
    80002560:	0880                	addi	s0,sp,80
    80002562:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002564:	fffff097          	auipc	ra,0xfffff
    80002568:	76a080e7          	jalr	1898(ra) # 80001cce <myproc>
    8000256c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000256e:	0000f517          	auipc	a0,0xf
    80002572:	28a50513          	addi	a0,a0,650 # 800117f8 <wait_lock>
    80002576:	ffffe097          	auipc	ra,0xffffe
    8000257a:	66e080e7          	jalr	1646(ra) # 80000be4 <acquire>
    havekids = 0;
    8000257e:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002580:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002582:	00015997          	auipc	s3,0x15
    80002586:	68e98993          	addi	s3,s3,1678 # 80017c10 <tickslock>
        havekids = 1;
    8000258a:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000258c:	0000fc17          	auipc	s8,0xf
    80002590:	26cc0c13          	addi	s8,s8,620 # 800117f8 <wait_lock>
    havekids = 0;
    80002594:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002596:	0000f497          	auipc	s1,0xf
    8000259a:	27a48493          	addi	s1,s1,634 # 80011810 <proc>
    8000259e:	a0bd                	j	8000260c <wait+0xc2>
          pid = np->pid;
    800025a0:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800025a4:	000b0e63          	beqz	s6,800025c0 <wait+0x76>
    800025a8:	4691                	li	a3,4
    800025aa:	02c48613          	addi	a2,s1,44
    800025ae:	85da                	mv	a1,s6
    800025b0:	05093503          	ld	a0,80(s2)
    800025b4:	fffff097          	auipc	ra,0xfffff
    800025b8:	0be080e7          	jalr	190(ra) # 80001672 <copyout>
    800025bc:	02054563          	bltz	a0,800025e6 <wait+0x9c>
          freeproc(np);
    800025c0:	8526                	mv	a0,s1
    800025c2:	00000097          	auipc	ra,0x0
    800025c6:	8b8080e7          	jalr	-1864(ra) # 80001e7a <freeproc>
          release(&np->lock);
    800025ca:	8526                	mv	a0,s1
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	6cc080e7          	jalr	1740(ra) # 80000c98 <release>
          release(&wait_lock);
    800025d4:	0000f517          	auipc	a0,0xf
    800025d8:	22450513          	addi	a0,a0,548 # 800117f8 <wait_lock>
    800025dc:	ffffe097          	auipc	ra,0xffffe
    800025e0:	6bc080e7          	jalr	1724(ra) # 80000c98 <release>
          return pid;
    800025e4:	a09d                	j	8000264a <wait+0x100>
            release(&np->lock);
    800025e6:	8526                	mv	a0,s1
    800025e8:	ffffe097          	auipc	ra,0xffffe
    800025ec:	6b0080e7          	jalr	1712(ra) # 80000c98 <release>
            release(&wait_lock);
    800025f0:	0000f517          	auipc	a0,0xf
    800025f4:	20850513          	addi	a0,a0,520 # 800117f8 <wait_lock>
    800025f8:	ffffe097          	auipc	ra,0xffffe
    800025fc:	6a0080e7          	jalr	1696(ra) # 80000c98 <release>
            return -1;
    80002600:	59fd                	li	s3,-1
    80002602:	a0a1                	j	8000264a <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002604:	19048493          	addi	s1,s1,400
    80002608:	03348463          	beq	s1,s3,80002630 <wait+0xe6>
      if(np->parent == p){
    8000260c:	7c9c                	ld	a5,56(s1)
    8000260e:	ff279be3          	bne	a5,s2,80002604 <wait+0xba>
        acquire(&np->lock);
    80002612:	8526                	mv	a0,s1
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	5d0080e7          	jalr	1488(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000261c:	4c9c                	lw	a5,24(s1)
    8000261e:	f94781e3          	beq	a5,s4,800025a0 <wait+0x56>
        release(&np->lock);
    80002622:	8526                	mv	a0,s1
    80002624:	ffffe097          	auipc	ra,0xffffe
    80002628:	674080e7          	jalr	1652(ra) # 80000c98 <release>
        havekids = 1;
    8000262c:	8756                	mv	a4,s5
    8000262e:	bfd9                	j	80002604 <wait+0xba>
    if(!havekids || p->killed){
    80002630:	c701                	beqz	a4,80002638 <wait+0xee>
    80002632:	02892783          	lw	a5,40(s2)
    80002636:	c79d                	beqz	a5,80002664 <wait+0x11a>
      release(&wait_lock);
    80002638:	0000f517          	auipc	a0,0xf
    8000263c:	1c050513          	addi	a0,a0,448 # 800117f8 <wait_lock>
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	658080e7          	jalr	1624(ra) # 80000c98 <release>
      return -1;
    80002648:	59fd                	li	s3,-1
}
    8000264a:	854e                	mv	a0,s3
    8000264c:	60a6                	ld	ra,72(sp)
    8000264e:	6406                	ld	s0,64(sp)
    80002650:	74e2                	ld	s1,56(sp)
    80002652:	7942                	ld	s2,48(sp)
    80002654:	79a2                	ld	s3,40(sp)
    80002656:	7a02                	ld	s4,32(sp)
    80002658:	6ae2                	ld	s5,24(sp)
    8000265a:	6b42                	ld	s6,16(sp)
    8000265c:	6ba2                	ld	s7,8(sp)
    8000265e:	6c02                	ld	s8,0(sp)
    80002660:	6161                	addi	sp,sp,80
    80002662:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002664:	85e2                	mv	a1,s8
    80002666:	854a                	mv	a0,s2
    80002668:	00000097          	auipc	ra,0x0
    8000266c:	e6c080e7          	jalr	-404(ra) # 800024d4 <sleep>
    havekids = 0;
    80002670:	b715                	j	80002594 <wait+0x4a>

0000000080002672 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002672:	7119                	addi	sp,sp,-128
    80002674:	fc86                	sd	ra,120(sp)
    80002676:	f8a2                	sd	s0,112(sp)
    80002678:	f4a6                	sd	s1,104(sp)
    8000267a:	f0ca                	sd	s2,96(sp)
    8000267c:	ecce                	sd	s3,88(sp)
    8000267e:	e8d2                	sd	s4,80(sp)
    80002680:	e4d6                	sd	s5,72(sp)
    80002682:	e0da                	sd	s6,64(sp)
    80002684:	fc5e                	sd	s7,56(sp)
    80002686:	f862                	sd	s8,48(sp)
    80002688:	f466                	sd	s9,40(sp)
    8000268a:	f06a                	sd	s10,32(sp)
    8000268c:	ec6e                	sd	s11,24(sp)
    8000268e:	0100                	addi	s0,sp,128
  struct proc *p;
  int empty = -1;
  int curr = sleeping_list.head;
    80002690:	00006497          	auipc	s1,0x6
    80002694:	2204a483          	lw	s1,544(s1) # 800088b0 <sleeping_list>

  while(curr != empty) {
    80002698:	57fd                	li	a5,-1
    8000269a:	0af48b63          	beq	s1,a5,80002750 <wakeup+0xde>
    8000269e:	8baa                	mv	s7,a0
    p = &proc[curr];
    800026a0:	19000a13          	li	s4,400
    800026a4:	0000f997          	auipc	s3,0xf
    800026a8:	16c98993          	addi	s3,s3,364 # 80011810 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800026ac:	4b09                	li	s6,2
        struct linked_list *remove_from_SLEEPING_list = &sleeping_list;
        remove(remove_from_SLEEPING_list, p);
    800026ae:	00006d97          	auipc	s11,0x6
    800026b2:	202d8d93          	addi	s11,s11,514 # 800088b0 <sleeping_list>
        p->state = RUNNABLE;
    800026b6:	4d0d                	li	s10,3

        #ifdef ON
          p->last_cpu = min_num_procs_cpu();
        #endif

        inc_cpu(&cpus[p->last_cpu]);
    800026b8:	0000fc97          	auipc	s9,0xf
    800026bc:	be8c8c93          	addi	s9,s9,-1048 # 800112a0 <cpus>
    800026c0:	0a800c13          	li	s8,168
  while(curr != empty) {
    800026c4:	5afd                	li	s5,-1
    800026c6:	a829                	j	800026e0 <wakeup+0x6e>
        append(&cpus[p->last_cpu].runnable_list, p);
      }
      release(&p->lock);
    800026c8:	854a                	mv	a0,s2
    800026ca:	ffffe097          	auipc	ra,0xffffe
    800026ce:	5ce080e7          	jalr	1486(ra) # 80000c98 <release>
    }
  curr = p->next_proc;
    800026d2:	034484b3          	mul	s1,s1,s4
    800026d6:	94ce                	add	s1,s1,s3
    800026d8:	16c4a483          	lw	s1,364(s1)
  while(curr != empty) {
    800026dc:	07548a63          	beq	s1,s5,80002750 <wakeup+0xde>
    p = &proc[curr];
    800026e0:	03448933          	mul	s2,s1,s4
    800026e4:	994e                	add	s2,s2,s3
    if(p != myproc()){
    800026e6:	fffff097          	auipc	ra,0xfffff
    800026ea:	5e8080e7          	jalr	1512(ra) # 80001cce <myproc>
    800026ee:	fea902e3          	beq	s2,a0,800026d2 <wakeup+0x60>
      acquire(&p->lock);
    800026f2:	854a                	mv	a0,s2
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	4f0080e7          	jalr	1264(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800026fc:	01892783          	lw	a5,24(s2)
    80002700:	fd6794e3          	bne	a5,s6,800026c8 <wakeup+0x56>
    80002704:	02093783          	ld	a5,32(s2)
    80002708:	fd7790e3          	bne	a5,s7,800026c8 <wakeup+0x56>
        remove(remove_from_SLEEPING_list, p);
    8000270c:	85ca                	mv	a1,s2
    8000270e:	856e                	mv	a0,s11
    80002710:	fffff097          	auipc	ra,0xfffff
    80002714:	23e080e7          	jalr	574(ra) # 8000194e <remove>
        p->state = RUNNABLE;
    80002718:	01a92c23          	sw	s10,24(s2)
        inc_cpu(&cpus[p->last_cpu]);
    8000271c:	f9243423          	sd	s2,-120(s0)
    80002720:	16892503          	lw	a0,360(s2)
    80002724:	03850533          	mul	a0,a0,s8
    80002728:	9566                	add	a0,a0,s9
    8000272a:	fffff097          	auipc	ra,0xfffff
    8000272e:	114080e7          	jalr	276(ra) # 8000183e <inc_cpu>
        append(&cpus[p->last_cpu].runnable_list, p);
    80002732:	f8843783          	ld	a5,-120(s0)
    80002736:	1687a503          	lw	a0,360(a5)
    8000273a:	03850533          	mul	a0,a0,s8
    8000273e:	08850513          	addi	a0,a0,136
    80002742:	85ca                	mv	a1,s2
    80002744:	9566                	add	a0,a0,s9
    80002746:	fffff097          	auipc	ra,0xfffff
    8000274a:	140080e7          	jalr	320(ra) # 80001886 <append>
    8000274e:	bfad                	j	800026c8 <wakeup+0x56>
  }
}
    80002750:	70e6                	ld	ra,120(sp)
    80002752:	7446                	ld	s0,112(sp)
    80002754:	74a6                	ld	s1,104(sp)
    80002756:	7906                	ld	s2,96(sp)
    80002758:	69e6                	ld	s3,88(sp)
    8000275a:	6a46                	ld	s4,80(sp)
    8000275c:	6aa6                	ld	s5,72(sp)
    8000275e:	6b06                	ld	s6,64(sp)
    80002760:	7be2                	ld	s7,56(sp)
    80002762:	7c42                	ld	s8,48(sp)
    80002764:	7ca2                	ld	s9,40(sp)
    80002766:	7d02                	ld	s10,32(sp)
    80002768:	6de2                	ld	s11,24(sp)
    8000276a:	6109                	addi	sp,sp,128
    8000276c:	8082                	ret

000000008000276e <reparent>:
{
    8000276e:	7179                	addi	sp,sp,-48
    80002770:	f406                	sd	ra,40(sp)
    80002772:	f022                	sd	s0,32(sp)
    80002774:	ec26                	sd	s1,24(sp)
    80002776:	e84a                	sd	s2,16(sp)
    80002778:	e44e                	sd	s3,8(sp)
    8000277a:	e052                	sd	s4,0(sp)
    8000277c:	1800                	addi	s0,sp,48
    8000277e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002780:	0000f497          	auipc	s1,0xf
    80002784:	09048493          	addi	s1,s1,144 # 80011810 <proc>
      pp->parent = initproc;
    80002788:	00007a17          	auipc	s4,0x7
    8000278c:	8a0a0a13          	addi	s4,s4,-1888 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002790:	00015997          	auipc	s3,0x15
    80002794:	48098993          	addi	s3,s3,1152 # 80017c10 <tickslock>
    80002798:	a029                	j	800027a2 <reparent+0x34>
    8000279a:	19048493          	addi	s1,s1,400
    8000279e:	01348d63          	beq	s1,s3,800027b8 <reparent+0x4a>
    if(pp->parent == p){
    800027a2:	7c9c                	ld	a5,56(s1)
    800027a4:	ff279be3          	bne	a5,s2,8000279a <reparent+0x2c>
      pp->parent = initproc;
    800027a8:	000a3503          	ld	a0,0(s4)
    800027ac:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800027ae:	00000097          	auipc	ra,0x0
    800027b2:	ec4080e7          	jalr	-316(ra) # 80002672 <wakeup>
    800027b6:	b7d5                	j	8000279a <reparent+0x2c>
}
    800027b8:	70a2                	ld	ra,40(sp)
    800027ba:	7402                	ld	s0,32(sp)
    800027bc:	64e2                	ld	s1,24(sp)
    800027be:	6942                	ld	s2,16(sp)
    800027c0:	69a2                	ld	s3,8(sp)
    800027c2:	6a02                	ld	s4,0(sp)
    800027c4:	6145                	addi	sp,sp,48
    800027c6:	8082                	ret

00000000800027c8 <exit>:
{
    800027c8:	7179                	addi	sp,sp,-48
    800027ca:	f406                	sd	ra,40(sp)
    800027cc:	f022                	sd	s0,32(sp)
    800027ce:	ec26                	sd	s1,24(sp)
    800027d0:	e84a                	sd	s2,16(sp)
    800027d2:	e44e                	sd	s3,8(sp)
    800027d4:	e052                	sd	s4,0(sp)
    800027d6:	1800                	addi	s0,sp,48
    800027d8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800027da:	fffff097          	auipc	ra,0xfffff
    800027de:	4f4080e7          	jalr	1268(ra) # 80001cce <myproc>
    800027e2:	89aa                	mv	s3,a0
  if(p == initproc)
    800027e4:	00007797          	auipc	a5,0x7
    800027e8:	8447b783          	ld	a5,-1980(a5) # 80009028 <initproc>
    800027ec:	0d050493          	addi	s1,a0,208
    800027f0:	15050913          	addi	s2,a0,336
    800027f4:	02a79363          	bne	a5,a0,8000281a <exit+0x52>
    panic("init exiting");
    800027f8:	00006517          	auipc	a0,0x6
    800027fc:	af050513          	addi	a0,a0,-1296 # 800082e8 <digits+0x2a8>
    80002800:	ffffe097          	auipc	ra,0xffffe
    80002804:	d3e080e7          	jalr	-706(ra) # 8000053e <panic>
      fileclose(f);
    80002808:	00002097          	auipc	ra,0x2
    8000280c:	22a080e7          	jalr	554(ra) # 80004a32 <fileclose>
      p->ofile[fd] = 0;
    80002810:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002814:	04a1                	addi	s1,s1,8
    80002816:	01248563          	beq	s1,s2,80002820 <exit+0x58>
    if(p->ofile[fd]){
    8000281a:	6088                	ld	a0,0(s1)
    8000281c:	f575                	bnez	a0,80002808 <exit+0x40>
    8000281e:	bfdd                	j	80002814 <exit+0x4c>
  begin_op();
    80002820:	00002097          	auipc	ra,0x2
    80002824:	d46080e7          	jalr	-698(ra) # 80004566 <begin_op>
  iput(p->cwd);
    80002828:	1509b503          	ld	a0,336(s3)
    8000282c:	00001097          	auipc	ra,0x1
    80002830:	522080e7          	jalr	1314(ra) # 80003d4e <iput>
  end_op();
    80002834:	00002097          	auipc	ra,0x2
    80002838:	db2080e7          	jalr	-590(ra) # 800045e6 <end_op>
  p->cwd = 0;
    8000283c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002840:	0000f497          	auipc	s1,0xf
    80002844:	fb848493          	addi	s1,s1,-72 # 800117f8 <wait_lock>
    80002848:	8526                	mv	a0,s1
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	39a080e7          	jalr	922(ra) # 80000be4 <acquire>
  reparent(p);
    80002852:	854e                	mv	a0,s3
    80002854:	00000097          	auipc	ra,0x0
    80002858:	f1a080e7          	jalr	-230(ra) # 8000276e <reparent>
  wakeup(p->parent);
    8000285c:	0389b503          	ld	a0,56(s3)
    80002860:	00000097          	auipc	ra,0x0
    80002864:	e12080e7          	jalr	-494(ra) # 80002672 <wakeup>
  acquire(&p->lock);
    80002868:	854e                	mv	a0,s3
    8000286a:	ffffe097          	auipc	ra,0xffffe
    8000286e:	37a080e7          	jalr	890(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002872:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002876:	4795                	li	a5,5
    80002878:	00f9ac23          	sw	a5,24(s3)
  append(&zombie_list, p); 
    8000287c:	85ce                	mv	a1,s3
    8000287e:	00006517          	auipc	a0,0x6
    80002882:	05250513          	addi	a0,a0,82 # 800088d0 <zombie_list>
    80002886:	fffff097          	auipc	ra,0xfffff
    8000288a:	000080e7          	jalr	ra # 80001886 <append>
  release(&wait_lock);
    8000288e:	8526                	mv	a0,s1
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	408080e7          	jalr	1032(ra) # 80000c98 <release>
  sched();
    80002898:	00000097          	auipc	ra,0x0
    8000289c:	afe080e7          	jalr	-1282(ra) # 80002396 <sched>
  panic("zombie exit");
    800028a0:	00006517          	auipc	a0,0x6
    800028a4:	a5850513          	addi	a0,a0,-1448 # 800082f8 <digits+0x2b8>
    800028a8:	ffffe097          	auipc	ra,0xffffe
    800028ac:	c96080e7          	jalr	-874(ra) # 8000053e <panic>

00000000800028b0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800028b0:	7179                	addi	sp,sp,-48
    800028b2:	f406                	sd	ra,40(sp)
    800028b4:	f022                	sd	s0,32(sp)
    800028b6:	ec26                	sd	s1,24(sp)
    800028b8:	e84a                	sd	s2,16(sp)
    800028ba:	e44e                	sd	s3,8(sp)
    800028bc:	1800                	addi	s0,sp,48
    800028be:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800028c0:	0000f497          	auipc	s1,0xf
    800028c4:	f5048493          	addi	s1,s1,-176 # 80011810 <proc>
    800028c8:	00015997          	auipc	s3,0x15
    800028cc:	34898993          	addi	s3,s3,840 # 80017c10 <tickslock>
    acquire(&p->lock);
    800028d0:	8526                	mv	a0,s1
    800028d2:	ffffe097          	auipc	ra,0xffffe
    800028d6:	312080e7          	jalr	786(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800028da:	589c                	lw	a5,48(s1)
    800028dc:	01278d63          	beq	a5,s2,800028f6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800028e0:	8526                	mv	a0,s1
    800028e2:	ffffe097          	auipc	ra,0xffffe
    800028e6:	3b6080e7          	jalr	950(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800028ea:	19048493          	addi	s1,s1,400
    800028ee:	ff3491e3          	bne	s1,s3,800028d0 <kill+0x20>
  }
  return -1;
    800028f2:	557d                	li	a0,-1
    800028f4:	a829                	j	8000290e <kill+0x5e>
      p->killed = 1;
    800028f6:	4785                	li	a5,1
    800028f8:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800028fa:	4c98                	lw	a4,24(s1)
    800028fc:	4789                	li	a5,2
    800028fe:	00f70f63          	beq	a4,a5,8000291c <kill+0x6c>
      release(&p->lock);
    80002902:	8526                	mv	a0,s1
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	394080e7          	jalr	916(ra) # 80000c98 <release>
      return 0;
    8000290c:	4501                	li	a0,0
}
    8000290e:	70a2                	ld	ra,40(sp)
    80002910:	7402                	ld	s0,32(sp)
    80002912:	64e2                	ld	s1,24(sp)
    80002914:	6942                	ld	s2,16(sp)
    80002916:	69a2                	ld	s3,8(sp)
    80002918:	6145                	addi	sp,sp,48
    8000291a:	8082                	ret
        p->state = RUNNABLE;
    8000291c:	478d                	li	a5,3
    8000291e:	cc9c                	sw	a5,24(s1)
    80002920:	b7cd                	j	80002902 <kill+0x52>

0000000080002922 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002922:	7179                	addi	sp,sp,-48
    80002924:	f406                	sd	ra,40(sp)
    80002926:	f022                	sd	s0,32(sp)
    80002928:	ec26                	sd	s1,24(sp)
    8000292a:	e84a                	sd	s2,16(sp)
    8000292c:	e44e                	sd	s3,8(sp)
    8000292e:	e052                	sd	s4,0(sp)
    80002930:	1800                	addi	s0,sp,48
    80002932:	84aa                	mv	s1,a0
    80002934:	892e                	mv	s2,a1
    80002936:	89b2                	mv	s3,a2
    80002938:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000293a:	fffff097          	auipc	ra,0xfffff
    8000293e:	394080e7          	jalr	916(ra) # 80001cce <myproc>
  if(user_dst){
    80002942:	c08d                	beqz	s1,80002964 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002944:	86d2                	mv	a3,s4
    80002946:	864e                	mv	a2,s3
    80002948:	85ca                	mv	a1,s2
    8000294a:	6928                	ld	a0,80(a0)
    8000294c:	fffff097          	auipc	ra,0xfffff
    80002950:	d26080e7          	jalr	-730(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002954:	70a2                	ld	ra,40(sp)
    80002956:	7402                	ld	s0,32(sp)
    80002958:	64e2                	ld	s1,24(sp)
    8000295a:	6942                	ld	s2,16(sp)
    8000295c:	69a2                	ld	s3,8(sp)
    8000295e:	6a02                	ld	s4,0(sp)
    80002960:	6145                	addi	sp,sp,48
    80002962:	8082                	ret
    memmove((char *)dst, src, len);
    80002964:	000a061b          	sext.w	a2,s4
    80002968:	85ce                	mv	a1,s3
    8000296a:	854a                	mv	a0,s2
    8000296c:	ffffe097          	auipc	ra,0xffffe
    80002970:	3d4080e7          	jalr	980(ra) # 80000d40 <memmove>
    return 0;
    80002974:	8526                	mv	a0,s1
    80002976:	bff9                	j	80002954 <either_copyout+0x32>

0000000080002978 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002978:	7179                	addi	sp,sp,-48
    8000297a:	f406                	sd	ra,40(sp)
    8000297c:	f022                	sd	s0,32(sp)
    8000297e:	ec26                	sd	s1,24(sp)
    80002980:	e84a                	sd	s2,16(sp)
    80002982:	e44e                	sd	s3,8(sp)
    80002984:	e052                	sd	s4,0(sp)
    80002986:	1800                	addi	s0,sp,48
    80002988:	892a                	mv	s2,a0
    8000298a:	84ae                	mv	s1,a1
    8000298c:	89b2                	mv	s3,a2
    8000298e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002990:	fffff097          	auipc	ra,0xfffff
    80002994:	33e080e7          	jalr	830(ra) # 80001cce <myproc>
  if(user_src){
    80002998:	c08d                	beqz	s1,800029ba <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000299a:	86d2                	mv	a3,s4
    8000299c:	864e                	mv	a2,s3
    8000299e:	85ca                	mv	a1,s2
    800029a0:	6928                	ld	a0,80(a0)
    800029a2:	fffff097          	auipc	ra,0xfffff
    800029a6:	d5c080e7          	jalr	-676(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800029aa:	70a2                	ld	ra,40(sp)
    800029ac:	7402                	ld	s0,32(sp)
    800029ae:	64e2                	ld	s1,24(sp)
    800029b0:	6942                	ld	s2,16(sp)
    800029b2:	69a2                	ld	s3,8(sp)
    800029b4:	6a02                	ld	s4,0(sp)
    800029b6:	6145                	addi	sp,sp,48
    800029b8:	8082                	ret
    memmove(dst, (char*)src, len);
    800029ba:	000a061b          	sext.w	a2,s4
    800029be:	85ce                	mv	a1,s3
    800029c0:	854a                	mv	a0,s2
    800029c2:	ffffe097          	auipc	ra,0xffffe
    800029c6:	37e080e7          	jalr	894(ra) # 80000d40 <memmove>
    return 0;
    800029ca:	8526                	mv	a0,s1
    800029cc:	bff9                	j	800029aa <either_copyin+0x32>

00000000800029ce <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    800029ce:	715d                	addi	sp,sp,-80
    800029d0:	e486                	sd	ra,72(sp)
    800029d2:	e0a2                	sd	s0,64(sp)
    800029d4:	fc26                	sd	s1,56(sp)
    800029d6:	f84a                	sd	s2,48(sp)
    800029d8:	f44e                	sd	s3,40(sp)
    800029da:	f052                	sd	s4,32(sp)
    800029dc:	ec56                	sd	s5,24(sp)
    800029de:	e85a                	sd	s6,16(sp)
    800029e0:	e45e                	sd	s7,8(sp)
    800029e2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800029e4:	00005517          	auipc	a0,0x5
    800029e8:	6e450513          	addi	a0,a0,1764 # 800080c8 <digits+0x88>
    800029ec:	ffffe097          	auipc	ra,0xffffe
    800029f0:	b9c080e7          	jalr	-1124(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800029f4:	0000f497          	auipc	s1,0xf
    800029f8:	f7448493          	addi	s1,s1,-140 # 80011968 <proc+0x158>
    800029fc:	00015917          	auipc	s2,0x15
    80002a00:	36c90913          	addi	s2,s2,876 # 80017d68 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a04:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    80002a06:	00006997          	auipc	s3,0x6
    80002a0a:	90298993          	addi	s3,s3,-1790 # 80008308 <digits+0x2c8>
    printf("%d %s %s", p->pid, state, p->name);
    80002a0e:	00006a97          	auipc	s5,0x6
    80002a12:	902a8a93          	addi	s5,s5,-1790 # 80008310 <digits+0x2d0>
    printf("\n");
    80002a16:	00005a17          	auipc	s4,0x5
    80002a1a:	6b2a0a13          	addi	s4,s4,1714 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a1e:	00006b97          	auipc	s7,0x6
    80002a22:	92ab8b93          	addi	s7,s7,-1750 # 80008348 <states.1769>
    80002a26:	a00d                	j	80002a48 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002a28:	ed86a583          	lw	a1,-296(a3)
    80002a2c:	8556                	mv	a0,s5
    80002a2e:	ffffe097          	auipc	ra,0xffffe
    80002a32:	b5a080e7          	jalr	-1190(ra) # 80000588 <printf>
    printf("\n");
    80002a36:	8552                	mv	a0,s4
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	b50080e7          	jalr	-1200(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a40:	19048493          	addi	s1,s1,400
    80002a44:	03248163          	beq	s1,s2,80002a66 <procdump+0x98>
    if(p->state == UNUSED)
    80002a48:	86a6                	mv	a3,s1
    80002a4a:	ec04a783          	lw	a5,-320(s1)
    80002a4e:	dbed                	beqz	a5,80002a40 <procdump+0x72>
      state = "???"; 
    80002a50:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a52:	fcfb6be3          	bltu	s6,a5,80002a28 <procdump+0x5a>
    80002a56:	1782                	slli	a5,a5,0x20
    80002a58:	9381                	srli	a5,a5,0x20
    80002a5a:	078e                	slli	a5,a5,0x3
    80002a5c:	97de                	add	a5,a5,s7
    80002a5e:	6390                	ld	a2,0(a5)
    80002a60:	f661                	bnez	a2,80002a28 <procdump+0x5a>
      state = "???"; 
    80002a62:	864e                	mv	a2,s3
    80002a64:	b7d1                	j	80002a28 <procdump+0x5a>
  }
}
    80002a66:	60a6                	ld	ra,72(sp)
    80002a68:	6406                	ld	s0,64(sp)
    80002a6a:	74e2                	ld	s1,56(sp)
    80002a6c:	7942                	ld	s2,48(sp)
    80002a6e:	79a2                	ld	s3,40(sp)
    80002a70:	7a02                	ld	s4,32(sp)
    80002a72:	6ae2                	ld	s5,24(sp)
    80002a74:	6b42                	ld	s6,16(sp)
    80002a76:	6ba2                	ld	s7,8(sp)
    80002a78:	6161                	addi	sp,sp,80
    80002a7a:	8082                	ret

0000000080002a7c <set_cpu>:

// move process to different CPU. 
int
set_cpu(int cpu_num) {
  int fail = -1;
  if(cpu_num < NCPU) {
    80002a7c:	479d                	li	a5,7
    80002a7e:	04a7e863          	bltu	a5,a0,80002ace <set_cpu+0x52>
set_cpu(int cpu_num) {
    80002a82:	1101                	addi	sp,sp,-32
    80002a84:	ec06                	sd	ra,24(sp)
    80002a86:	e822                	sd	s0,16(sp)
    80002a88:	e426                	sd	s1,8(sp)
    80002a8a:	1000                	addi	s0,sp,32
    80002a8c:	84aa                	mv	s1,a0
   if(cpu_num >= 0) {
     struct cpu *c = &cpus[cpu_num];
     if(c != NULL) {
        acquire(&myproc()->lock);
    80002a8e:	fffff097          	auipc	ra,0xfffff
    80002a92:	240080e7          	jalr	576(ra) # 80001cce <myproc>
    80002a96:	ffffe097          	auipc	ra,0xffffe
    80002a9a:	14e080e7          	jalr	334(ra) # 80000be4 <acquire>
        myproc()->last_cpu = cpu_num;
    80002a9e:	fffff097          	auipc	ra,0xfffff
    80002aa2:	230080e7          	jalr	560(ra) # 80001cce <myproc>
    80002aa6:	16952423          	sw	s1,360(a0)
        release(&myproc()->lock);
    80002aaa:	fffff097          	auipc	ra,0xfffff
    80002aae:	224080e7          	jalr	548(ra) # 80001cce <myproc>
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	1e6080e7          	jalr	486(ra) # 80000c98 <release>

        // RUNNING -> RUNNABLE
        yield();
    80002aba:	00000097          	auipc	ra,0x0
    80002abe:	9be080e7          	jalr	-1602(ra) # 80002478 <yield>
        return cpu_num;
    80002ac2:	8526                	mv	a0,s1
      }
    }
  }
  return fail;
}
    80002ac4:	60e2                	ld	ra,24(sp)
    80002ac6:	6442                	ld	s0,16(sp)
    80002ac8:	64a2                	ld	s1,8(sp)
    80002aca:	6105                	addi	sp,sp,32
    80002acc:	8082                	ret
  return fail;
    80002ace:	557d                	li	a0,-1
}
    80002ad0:	8082                	ret

0000000080002ad2 <get_cpu>:

// returns current CPU.
int
get_cpu(void){
    80002ad2:	1141                	addi	sp,sp,-16
    80002ad4:	e406                	sd	ra,8(sp)
    80002ad6:	e022                	sd	s0,0(sp)
    80002ad8:	0800                	addi	s0,sp,16

  // If process was not chosen by any cpy the value of myproc()->last_cpu is -1.
  return myproc()->last_cpu;
    80002ada:	fffff097          	auipc	ra,0xfffff
    80002ade:	1f4080e7          	jalr	500(ra) # 80001cce <myproc>
}
    80002ae2:	16852503          	lw	a0,360(a0)
    80002ae6:	60a2                	ld	ra,8(sp)
    80002ae8:	6402                	ld	s0,0(sp)
    80002aea:	0141                	addi	sp,sp,16
    80002aec:	8082                	ret

0000000080002aee <min_cpu>:

int
min_cpu(void){
    80002aee:	1141                	addi	sp,sp,-16
    80002af0:	e422                	sd	s0,8(sp)
    80002af2:	0800                	addi	s0,sp,16
  struct cpu *c;
  struct cpu *min_cpu = cpus;
    80002af4:	0000e617          	auipc	a2,0xe
    80002af8:	7ac60613          	addi	a2,a2,1964 # 800112a0 <cpus>
  
  for(c = cpus + 1; c < &cpus[NCPU] && c != NULL ; c++){
    80002afc:	0000f797          	auipc	a5,0xf
    80002b00:	84c78793          	addi	a5,a5,-1972 # 80011348 <cpus+0xa8>
    80002b04:	0000f597          	auipc	a1,0xf
    80002b08:	cdc58593          	addi	a1,a1,-804 # 800117e0 <pid_lock>
    80002b0c:	a029                	j	80002b16 <min_cpu+0x28>
    80002b0e:	0a878793          	addi	a5,a5,168
    80002b12:	00b78a63          	beq	a5,a1,80002b26 <min_cpu+0x38>
    if (c->proc_cnt < min_cpu->proc_cnt)
    80002b16:	0807a683          	lw	a3,128(a5)
    80002b1a:	08062703          	lw	a4,128(a2)
    80002b1e:	fee6d8e3          	bge	a3,a4,80002b0e <min_cpu+0x20>
    80002b22:	863e                	mv	a2,a5
    80002b24:	b7ed                	j	80002b0e <min_cpu+0x20>
        min_cpu = c;
  }
  return min_cpu->cpu_id;   
}
    80002b26:	08462503          	lw	a0,132(a2)
    80002b2a:	6422                	ld	s0,8(sp)
    80002b2c:	0141                	addi	sp,sp,16
    80002b2e:	8082                	ret

0000000080002b30 <swtch>:
    80002b30:	00153023          	sd	ra,0(a0)
    80002b34:	00253423          	sd	sp,8(a0)
    80002b38:	e900                	sd	s0,16(a0)
    80002b3a:	ed04                	sd	s1,24(a0)
    80002b3c:	03253023          	sd	s2,32(a0)
    80002b40:	03353423          	sd	s3,40(a0)
    80002b44:	03453823          	sd	s4,48(a0)
    80002b48:	03553c23          	sd	s5,56(a0)
    80002b4c:	05653023          	sd	s6,64(a0)
    80002b50:	05753423          	sd	s7,72(a0)
    80002b54:	05853823          	sd	s8,80(a0)
    80002b58:	05953c23          	sd	s9,88(a0)
    80002b5c:	07a53023          	sd	s10,96(a0)
    80002b60:	07b53423          	sd	s11,104(a0)
    80002b64:	0005b083          	ld	ra,0(a1)
    80002b68:	0085b103          	ld	sp,8(a1)
    80002b6c:	6980                	ld	s0,16(a1)
    80002b6e:	6d84                	ld	s1,24(a1)
    80002b70:	0205b903          	ld	s2,32(a1)
    80002b74:	0285b983          	ld	s3,40(a1)
    80002b78:	0305ba03          	ld	s4,48(a1)
    80002b7c:	0385ba83          	ld	s5,56(a1)
    80002b80:	0405bb03          	ld	s6,64(a1)
    80002b84:	0485bb83          	ld	s7,72(a1)
    80002b88:	0505bc03          	ld	s8,80(a1)
    80002b8c:	0585bc83          	ld	s9,88(a1)
    80002b90:	0605bd03          	ld	s10,96(a1)
    80002b94:	0685bd83          	ld	s11,104(a1)
    80002b98:	8082                	ret

0000000080002b9a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b9a:	1141                	addi	sp,sp,-16
    80002b9c:	e406                	sd	ra,8(sp)
    80002b9e:	e022                	sd	s0,0(sp)
    80002ba0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002ba2:	00005597          	auipc	a1,0x5
    80002ba6:	7d658593          	addi	a1,a1,2006 # 80008378 <states.1769+0x30>
    80002baa:	00015517          	auipc	a0,0x15
    80002bae:	06650513          	addi	a0,a0,102 # 80017c10 <tickslock>
    80002bb2:	ffffe097          	auipc	ra,0xffffe
    80002bb6:	fa2080e7          	jalr	-94(ra) # 80000b54 <initlock>
}
    80002bba:	60a2                	ld	ra,8(sp)
    80002bbc:	6402                	ld	s0,0(sp)
    80002bbe:	0141                	addi	sp,sp,16
    80002bc0:	8082                	ret

0000000080002bc2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002bc2:	1141                	addi	sp,sp,-16
    80002bc4:	e422                	sd	s0,8(sp)
    80002bc6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bc8:	00003797          	auipc	a5,0x3
    80002bcc:	48878793          	addi	a5,a5,1160 # 80006050 <kernelvec>
    80002bd0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002bd4:	6422                	ld	s0,8(sp)
    80002bd6:	0141                	addi	sp,sp,16
    80002bd8:	8082                	ret

0000000080002bda <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002bda:	1141                	addi	sp,sp,-16
    80002bdc:	e406                	sd	ra,8(sp)
    80002bde:	e022                	sd	s0,0(sp)
    80002be0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002be2:	fffff097          	auipc	ra,0xfffff
    80002be6:	0ec080e7          	jalr	236(ra) # 80001cce <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bea:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002bee:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bf0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002bf4:	00004617          	auipc	a2,0x4
    80002bf8:	40c60613          	addi	a2,a2,1036 # 80007000 <_trampoline>
    80002bfc:	00004697          	auipc	a3,0x4
    80002c00:	40468693          	addi	a3,a3,1028 # 80007000 <_trampoline>
    80002c04:	8e91                	sub	a3,a3,a2
    80002c06:	040007b7          	lui	a5,0x4000
    80002c0a:	17fd                	addi	a5,a5,-1
    80002c0c:	07b2                	slli	a5,a5,0xc
    80002c0e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c10:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c14:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c16:	180026f3          	csrr	a3,satp
    80002c1a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c1c:	6d38                	ld	a4,88(a0)
    80002c1e:	6134                	ld	a3,64(a0)
    80002c20:	6585                	lui	a1,0x1
    80002c22:	96ae                	add	a3,a3,a1
    80002c24:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c26:	6d38                	ld	a4,88(a0)
    80002c28:	00000697          	auipc	a3,0x0
    80002c2c:	13868693          	addi	a3,a3,312 # 80002d60 <usertrap>
    80002c30:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c32:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c34:	8692                	mv	a3,tp
    80002c36:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c38:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c3c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c40:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c44:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c48:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c4a:	6f18                	ld	a4,24(a4)
    80002c4c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c50:	692c                	ld	a1,80(a0)
    80002c52:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002c54:	00004717          	auipc	a4,0x4
    80002c58:	43c70713          	addi	a4,a4,1084 # 80007090 <userret>
    80002c5c:	8f11                	sub	a4,a4,a2
    80002c5e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002c60:	577d                	li	a4,-1
    80002c62:	177e                	slli	a4,a4,0x3f
    80002c64:	8dd9                	or	a1,a1,a4
    80002c66:	02000537          	lui	a0,0x2000
    80002c6a:	157d                	addi	a0,a0,-1
    80002c6c:	0536                	slli	a0,a0,0xd
    80002c6e:	9782                	jalr	a5
}
    80002c70:	60a2                	ld	ra,8(sp)
    80002c72:	6402                	ld	s0,0(sp)
    80002c74:	0141                	addi	sp,sp,16
    80002c76:	8082                	ret

0000000080002c78 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c78:	1101                	addi	sp,sp,-32
    80002c7a:	ec06                	sd	ra,24(sp)
    80002c7c:	e822                	sd	s0,16(sp)
    80002c7e:	e426                	sd	s1,8(sp)
    80002c80:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c82:	00015497          	auipc	s1,0x15
    80002c86:	f8e48493          	addi	s1,s1,-114 # 80017c10 <tickslock>
    80002c8a:	8526                	mv	a0,s1
    80002c8c:	ffffe097          	auipc	ra,0xffffe
    80002c90:	f58080e7          	jalr	-168(ra) # 80000be4 <acquire>
  ticks++;
    80002c94:	00006517          	auipc	a0,0x6
    80002c98:	39c50513          	addi	a0,a0,924 # 80009030 <ticks>
    80002c9c:	411c                	lw	a5,0(a0)
    80002c9e:	2785                	addiw	a5,a5,1
    80002ca0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002ca2:	00000097          	auipc	ra,0x0
    80002ca6:	9d0080e7          	jalr	-1584(ra) # 80002672 <wakeup>
  release(&tickslock);
    80002caa:	8526                	mv	a0,s1
    80002cac:	ffffe097          	auipc	ra,0xffffe
    80002cb0:	fec080e7          	jalr	-20(ra) # 80000c98 <release>
}
    80002cb4:	60e2                	ld	ra,24(sp)
    80002cb6:	6442                	ld	s0,16(sp)
    80002cb8:	64a2                	ld	s1,8(sp)
    80002cba:	6105                	addi	sp,sp,32
    80002cbc:	8082                	ret

0000000080002cbe <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002cbe:	1101                	addi	sp,sp,-32
    80002cc0:	ec06                	sd	ra,24(sp)
    80002cc2:	e822                	sd	s0,16(sp)
    80002cc4:	e426                	sd	s1,8(sp)
    80002cc6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cc8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002ccc:	00074d63          	bltz	a4,80002ce6 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002cd0:	57fd                	li	a5,-1
    80002cd2:	17fe                	slli	a5,a5,0x3f
    80002cd4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002cd6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002cd8:	06f70363          	beq	a4,a5,80002d3e <devintr+0x80>
  }
}
    80002cdc:	60e2                	ld	ra,24(sp)
    80002cde:	6442                	ld	s0,16(sp)
    80002ce0:	64a2                	ld	s1,8(sp)
    80002ce2:	6105                	addi	sp,sp,32
    80002ce4:	8082                	ret
     (scause & 0xff) == 9){
    80002ce6:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002cea:	46a5                	li	a3,9
    80002cec:	fed792e3          	bne	a5,a3,80002cd0 <devintr+0x12>
    int irq = plic_claim();
    80002cf0:	00003097          	auipc	ra,0x3
    80002cf4:	468080e7          	jalr	1128(ra) # 80006158 <plic_claim>
    80002cf8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002cfa:	47a9                	li	a5,10
    80002cfc:	02f50763          	beq	a0,a5,80002d2a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002d00:	4785                	li	a5,1
    80002d02:	02f50963          	beq	a0,a5,80002d34 <devintr+0x76>
    return 1;
    80002d06:	4505                	li	a0,1
    } else if(irq){
    80002d08:	d8f1                	beqz	s1,80002cdc <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d0a:	85a6                	mv	a1,s1
    80002d0c:	00005517          	auipc	a0,0x5
    80002d10:	67450513          	addi	a0,a0,1652 # 80008380 <states.1769+0x38>
    80002d14:	ffffe097          	auipc	ra,0xffffe
    80002d18:	874080e7          	jalr	-1932(ra) # 80000588 <printf>
      plic_complete(irq);
    80002d1c:	8526                	mv	a0,s1
    80002d1e:	00003097          	auipc	ra,0x3
    80002d22:	45e080e7          	jalr	1118(ra) # 8000617c <plic_complete>
    return 1;
    80002d26:	4505                	li	a0,1
    80002d28:	bf55                	j	80002cdc <devintr+0x1e>
      uartintr();
    80002d2a:	ffffe097          	auipc	ra,0xffffe
    80002d2e:	c7e080e7          	jalr	-898(ra) # 800009a8 <uartintr>
    80002d32:	b7ed                	j	80002d1c <devintr+0x5e>
      virtio_disk_intr();
    80002d34:	00004097          	auipc	ra,0x4
    80002d38:	928080e7          	jalr	-1752(ra) # 8000665c <virtio_disk_intr>
    80002d3c:	b7c5                	j	80002d1c <devintr+0x5e>
    if(cpuid() == 0){
    80002d3e:	fffff097          	auipc	ra,0xfffff
    80002d42:	f5e080e7          	jalr	-162(ra) # 80001c9c <cpuid>
    80002d46:	c901                	beqz	a0,80002d56 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d48:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d4c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d4e:	14479073          	csrw	sip,a5
    return 2;
    80002d52:	4509                	li	a0,2
    80002d54:	b761                	j	80002cdc <devintr+0x1e>
      clockintr();
    80002d56:	00000097          	auipc	ra,0x0
    80002d5a:	f22080e7          	jalr	-222(ra) # 80002c78 <clockintr>
    80002d5e:	b7ed                	j	80002d48 <devintr+0x8a>

0000000080002d60 <usertrap>:
{
    80002d60:	1101                	addi	sp,sp,-32
    80002d62:	ec06                	sd	ra,24(sp)
    80002d64:	e822                	sd	s0,16(sp)
    80002d66:	e426                	sd	s1,8(sp)
    80002d68:	e04a                	sd	s2,0(sp)
    80002d6a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d6c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d70:	1007f793          	andi	a5,a5,256
    80002d74:	e3ad                	bnez	a5,80002dd6 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d76:	00003797          	auipc	a5,0x3
    80002d7a:	2da78793          	addi	a5,a5,730 # 80006050 <kernelvec>
    80002d7e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d82:	fffff097          	auipc	ra,0xfffff
    80002d86:	f4c080e7          	jalr	-180(ra) # 80001cce <myproc>
    80002d8a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d8c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d8e:	14102773          	csrr	a4,sepc
    80002d92:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d94:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002d98:	47a1                	li	a5,8
    80002d9a:	04f71c63          	bne	a4,a5,80002df2 <usertrap+0x92>
    if(p->killed)
    80002d9e:	551c                	lw	a5,40(a0)
    80002da0:	e3b9                	bnez	a5,80002de6 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002da2:	6cb8                	ld	a4,88(s1)
    80002da4:	6f1c                	ld	a5,24(a4)
    80002da6:	0791                	addi	a5,a5,4
    80002da8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002daa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002dae:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002db2:	10079073          	csrw	sstatus,a5
    syscall();
    80002db6:	00000097          	auipc	ra,0x0
    80002dba:	2e0080e7          	jalr	736(ra) # 80003096 <syscall>
  if(p->killed)
    80002dbe:	549c                	lw	a5,40(s1)
    80002dc0:	ebc1                	bnez	a5,80002e50 <usertrap+0xf0>
  usertrapret();
    80002dc2:	00000097          	auipc	ra,0x0
    80002dc6:	e18080e7          	jalr	-488(ra) # 80002bda <usertrapret>
}
    80002dca:	60e2                	ld	ra,24(sp)
    80002dcc:	6442                	ld	s0,16(sp)
    80002dce:	64a2                	ld	s1,8(sp)
    80002dd0:	6902                	ld	s2,0(sp)
    80002dd2:	6105                	addi	sp,sp,32
    80002dd4:	8082                	ret
    panic("usertrap: not from user mode");
    80002dd6:	00005517          	auipc	a0,0x5
    80002dda:	5ca50513          	addi	a0,a0,1482 # 800083a0 <states.1769+0x58>
    80002dde:	ffffd097          	auipc	ra,0xffffd
    80002de2:	760080e7          	jalr	1888(ra) # 8000053e <panic>
      exit(-1);
    80002de6:	557d                	li	a0,-1
    80002de8:	00000097          	auipc	ra,0x0
    80002dec:	9e0080e7          	jalr	-1568(ra) # 800027c8 <exit>
    80002df0:	bf4d                	j	80002da2 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002df2:	00000097          	auipc	ra,0x0
    80002df6:	ecc080e7          	jalr	-308(ra) # 80002cbe <devintr>
    80002dfa:	892a                	mv	s2,a0
    80002dfc:	c501                	beqz	a0,80002e04 <usertrap+0xa4>
  if(p->killed)
    80002dfe:	549c                	lw	a5,40(s1)
    80002e00:	c3a1                	beqz	a5,80002e40 <usertrap+0xe0>
    80002e02:	a815                	j	80002e36 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e04:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e08:	5890                	lw	a2,48(s1)
    80002e0a:	00005517          	auipc	a0,0x5
    80002e0e:	5b650513          	addi	a0,a0,1462 # 800083c0 <states.1769+0x78>
    80002e12:	ffffd097          	auipc	ra,0xffffd
    80002e16:	776080e7          	jalr	1910(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e1a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e1e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e22:	00005517          	auipc	a0,0x5
    80002e26:	5ce50513          	addi	a0,a0,1486 # 800083f0 <states.1769+0xa8>
    80002e2a:	ffffd097          	auipc	ra,0xffffd
    80002e2e:	75e080e7          	jalr	1886(ra) # 80000588 <printf>
    p->killed = 1;
    80002e32:	4785                	li	a5,1
    80002e34:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002e36:	557d                	li	a0,-1
    80002e38:	00000097          	auipc	ra,0x0
    80002e3c:	990080e7          	jalr	-1648(ra) # 800027c8 <exit>
  if(which_dev == 2)
    80002e40:	4789                	li	a5,2
    80002e42:	f8f910e3          	bne	s2,a5,80002dc2 <usertrap+0x62>
    yield();
    80002e46:	fffff097          	auipc	ra,0xfffff
    80002e4a:	632080e7          	jalr	1586(ra) # 80002478 <yield>
    80002e4e:	bf95                	j	80002dc2 <usertrap+0x62>
  int which_dev = 0;
    80002e50:	4901                	li	s2,0
    80002e52:	b7d5                	j	80002e36 <usertrap+0xd6>

0000000080002e54 <kerneltrap>:
{
    80002e54:	7179                	addi	sp,sp,-48
    80002e56:	f406                	sd	ra,40(sp)
    80002e58:	f022                	sd	s0,32(sp)
    80002e5a:	ec26                	sd	s1,24(sp)
    80002e5c:	e84a                	sd	s2,16(sp)
    80002e5e:	e44e                	sd	s3,8(sp)
    80002e60:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e62:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e66:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e6a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e6e:	1004f793          	andi	a5,s1,256
    80002e72:	cb85                	beqz	a5,80002ea2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e78:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e7a:	ef85                	bnez	a5,80002eb2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e7c:	00000097          	auipc	ra,0x0
    80002e80:	e42080e7          	jalr	-446(ra) # 80002cbe <devintr>
    80002e84:	cd1d                	beqz	a0,80002ec2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e86:	4789                	li	a5,2
    80002e88:	06f50a63          	beq	a0,a5,80002efc <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e8c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e90:	10049073          	csrw	sstatus,s1
}
    80002e94:	70a2                	ld	ra,40(sp)
    80002e96:	7402                	ld	s0,32(sp)
    80002e98:	64e2                	ld	s1,24(sp)
    80002e9a:	6942                	ld	s2,16(sp)
    80002e9c:	69a2                	ld	s3,8(sp)
    80002e9e:	6145                	addi	sp,sp,48
    80002ea0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ea2:	00005517          	auipc	a0,0x5
    80002ea6:	56e50513          	addi	a0,a0,1390 # 80008410 <states.1769+0xc8>
    80002eaa:	ffffd097          	auipc	ra,0xffffd
    80002eae:	694080e7          	jalr	1684(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002eb2:	00005517          	auipc	a0,0x5
    80002eb6:	58650513          	addi	a0,a0,1414 # 80008438 <states.1769+0xf0>
    80002eba:	ffffd097          	auipc	ra,0xffffd
    80002ebe:	684080e7          	jalr	1668(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002ec2:	85ce                	mv	a1,s3
    80002ec4:	00005517          	auipc	a0,0x5
    80002ec8:	59450513          	addi	a0,a0,1428 # 80008458 <states.1769+0x110>
    80002ecc:	ffffd097          	auipc	ra,0xffffd
    80002ed0:	6bc080e7          	jalr	1724(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ed4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ed8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002edc:	00005517          	auipc	a0,0x5
    80002ee0:	58c50513          	addi	a0,a0,1420 # 80008468 <states.1769+0x120>
    80002ee4:	ffffd097          	auipc	ra,0xffffd
    80002ee8:	6a4080e7          	jalr	1700(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002eec:	00005517          	auipc	a0,0x5
    80002ef0:	59450513          	addi	a0,a0,1428 # 80008480 <states.1769+0x138>
    80002ef4:	ffffd097          	auipc	ra,0xffffd
    80002ef8:	64a080e7          	jalr	1610(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002efc:	fffff097          	auipc	ra,0xfffff
    80002f00:	dd2080e7          	jalr	-558(ra) # 80001cce <myproc>
    80002f04:	d541                	beqz	a0,80002e8c <kerneltrap+0x38>
    80002f06:	fffff097          	auipc	ra,0xfffff
    80002f0a:	dc8080e7          	jalr	-568(ra) # 80001cce <myproc>
    80002f0e:	4d18                	lw	a4,24(a0)
    80002f10:	4791                	li	a5,4
    80002f12:	f6f71de3          	bne	a4,a5,80002e8c <kerneltrap+0x38>
    yield();
    80002f16:	fffff097          	auipc	ra,0xfffff
    80002f1a:	562080e7          	jalr	1378(ra) # 80002478 <yield>
    80002f1e:	b7bd                	j	80002e8c <kerneltrap+0x38>

0000000080002f20 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f20:	1101                	addi	sp,sp,-32
    80002f22:	ec06                	sd	ra,24(sp)
    80002f24:	e822                	sd	s0,16(sp)
    80002f26:	e426                	sd	s1,8(sp)
    80002f28:	1000                	addi	s0,sp,32
    80002f2a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f2c:	fffff097          	auipc	ra,0xfffff
    80002f30:	da2080e7          	jalr	-606(ra) # 80001cce <myproc>
  switch (n) {
    80002f34:	4795                	li	a5,5
    80002f36:	0497e163          	bltu	a5,s1,80002f78 <argraw+0x58>
    80002f3a:	048a                	slli	s1,s1,0x2
    80002f3c:	00005717          	auipc	a4,0x5
    80002f40:	57c70713          	addi	a4,a4,1404 # 800084b8 <states.1769+0x170>
    80002f44:	94ba                	add	s1,s1,a4
    80002f46:	409c                	lw	a5,0(s1)
    80002f48:	97ba                	add	a5,a5,a4
    80002f4a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002f4c:	6d3c                	ld	a5,88(a0)
    80002f4e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f50:	60e2                	ld	ra,24(sp)
    80002f52:	6442                	ld	s0,16(sp)
    80002f54:	64a2                	ld	s1,8(sp)
    80002f56:	6105                	addi	sp,sp,32
    80002f58:	8082                	ret
    return p->trapframe->a1;
    80002f5a:	6d3c                	ld	a5,88(a0)
    80002f5c:	7fa8                	ld	a0,120(a5)
    80002f5e:	bfcd                	j	80002f50 <argraw+0x30>
    return p->trapframe->a2;
    80002f60:	6d3c                	ld	a5,88(a0)
    80002f62:	63c8                	ld	a0,128(a5)
    80002f64:	b7f5                	j	80002f50 <argraw+0x30>
    return p->trapframe->a3;
    80002f66:	6d3c                	ld	a5,88(a0)
    80002f68:	67c8                	ld	a0,136(a5)
    80002f6a:	b7dd                	j	80002f50 <argraw+0x30>
    return p->trapframe->a4;
    80002f6c:	6d3c                	ld	a5,88(a0)
    80002f6e:	6bc8                	ld	a0,144(a5)
    80002f70:	b7c5                	j	80002f50 <argraw+0x30>
    return p->trapframe->a5;
    80002f72:	6d3c                	ld	a5,88(a0)
    80002f74:	6fc8                	ld	a0,152(a5)
    80002f76:	bfe9                	j	80002f50 <argraw+0x30>
  panic("argraw");
    80002f78:	00005517          	auipc	a0,0x5
    80002f7c:	51850513          	addi	a0,a0,1304 # 80008490 <states.1769+0x148>
    80002f80:	ffffd097          	auipc	ra,0xffffd
    80002f84:	5be080e7          	jalr	1470(ra) # 8000053e <panic>

0000000080002f88 <fetchaddr>:
{
    80002f88:	1101                	addi	sp,sp,-32
    80002f8a:	ec06                	sd	ra,24(sp)
    80002f8c:	e822                	sd	s0,16(sp)
    80002f8e:	e426                	sd	s1,8(sp)
    80002f90:	e04a                	sd	s2,0(sp)
    80002f92:	1000                	addi	s0,sp,32
    80002f94:	84aa                	mv	s1,a0
    80002f96:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002f98:	fffff097          	auipc	ra,0xfffff
    80002f9c:	d36080e7          	jalr	-714(ra) # 80001cce <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002fa0:	653c                	ld	a5,72(a0)
    80002fa2:	02f4f863          	bgeu	s1,a5,80002fd2 <fetchaddr+0x4a>
    80002fa6:	00848713          	addi	a4,s1,8
    80002faa:	02e7e663          	bltu	a5,a4,80002fd6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002fae:	46a1                	li	a3,8
    80002fb0:	8626                	mv	a2,s1
    80002fb2:	85ca                	mv	a1,s2
    80002fb4:	6928                	ld	a0,80(a0)
    80002fb6:	ffffe097          	auipc	ra,0xffffe
    80002fba:	748080e7          	jalr	1864(ra) # 800016fe <copyin>
    80002fbe:	00a03533          	snez	a0,a0
    80002fc2:	40a00533          	neg	a0,a0
}
    80002fc6:	60e2                	ld	ra,24(sp)
    80002fc8:	6442                	ld	s0,16(sp)
    80002fca:	64a2                	ld	s1,8(sp)
    80002fcc:	6902                	ld	s2,0(sp)
    80002fce:	6105                	addi	sp,sp,32
    80002fd0:	8082                	ret
    return -1;
    80002fd2:	557d                	li	a0,-1
    80002fd4:	bfcd                	j	80002fc6 <fetchaddr+0x3e>
    80002fd6:	557d                	li	a0,-1
    80002fd8:	b7fd                	j	80002fc6 <fetchaddr+0x3e>

0000000080002fda <fetchstr>:
{
    80002fda:	7179                	addi	sp,sp,-48
    80002fdc:	f406                	sd	ra,40(sp)
    80002fde:	f022                	sd	s0,32(sp)
    80002fe0:	ec26                	sd	s1,24(sp)
    80002fe2:	e84a                	sd	s2,16(sp)
    80002fe4:	e44e                	sd	s3,8(sp)
    80002fe6:	1800                	addi	s0,sp,48
    80002fe8:	892a                	mv	s2,a0
    80002fea:	84ae                	mv	s1,a1
    80002fec:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002fee:	fffff097          	auipc	ra,0xfffff
    80002ff2:	ce0080e7          	jalr	-800(ra) # 80001cce <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ff6:	86ce                	mv	a3,s3
    80002ff8:	864a                	mv	a2,s2
    80002ffa:	85a6                	mv	a1,s1
    80002ffc:	6928                	ld	a0,80(a0)
    80002ffe:	ffffe097          	auipc	ra,0xffffe
    80003002:	78c080e7          	jalr	1932(ra) # 8000178a <copyinstr>
  if(err < 0)
    80003006:	00054763          	bltz	a0,80003014 <fetchstr+0x3a>
  return strlen(buf);
    8000300a:	8526                	mv	a0,s1
    8000300c:	ffffe097          	auipc	ra,0xffffe
    80003010:	e58080e7          	jalr	-424(ra) # 80000e64 <strlen>
}
    80003014:	70a2                	ld	ra,40(sp)
    80003016:	7402                	ld	s0,32(sp)
    80003018:	64e2                	ld	s1,24(sp)
    8000301a:	6942                	ld	s2,16(sp)
    8000301c:	69a2                	ld	s3,8(sp)
    8000301e:	6145                	addi	sp,sp,48
    80003020:	8082                	ret

0000000080003022 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003022:	1101                	addi	sp,sp,-32
    80003024:	ec06                	sd	ra,24(sp)
    80003026:	e822                	sd	s0,16(sp)
    80003028:	e426                	sd	s1,8(sp)
    8000302a:	1000                	addi	s0,sp,32
    8000302c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000302e:	00000097          	auipc	ra,0x0
    80003032:	ef2080e7          	jalr	-270(ra) # 80002f20 <argraw>
    80003036:	c088                	sw	a0,0(s1)
  return 0;
}
    80003038:	4501                	li	a0,0
    8000303a:	60e2                	ld	ra,24(sp)
    8000303c:	6442                	ld	s0,16(sp)
    8000303e:	64a2                	ld	s1,8(sp)
    80003040:	6105                	addi	sp,sp,32
    80003042:	8082                	ret

0000000080003044 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003044:	1101                	addi	sp,sp,-32
    80003046:	ec06                	sd	ra,24(sp)
    80003048:	e822                	sd	s0,16(sp)
    8000304a:	e426                	sd	s1,8(sp)
    8000304c:	1000                	addi	s0,sp,32
    8000304e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003050:	00000097          	auipc	ra,0x0
    80003054:	ed0080e7          	jalr	-304(ra) # 80002f20 <argraw>
    80003058:	e088                	sd	a0,0(s1)
  return 0;
}
    8000305a:	4501                	li	a0,0
    8000305c:	60e2                	ld	ra,24(sp)
    8000305e:	6442                	ld	s0,16(sp)
    80003060:	64a2                	ld	s1,8(sp)
    80003062:	6105                	addi	sp,sp,32
    80003064:	8082                	ret

0000000080003066 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003066:	1101                	addi	sp,sp,-32
    80003068:	ec06                	sd	ra,24(sp)
    8000306a:	e822                	sd	s0,16(sp)
    8000306c:	e426                	sd	s1,8(sp)
    8000306e:	e04a                	sd	s2,0(sp)
    80003070:	1000                	addi	s0,sp,32
    80003072:	84ae                	mv	s1,a1
    80003074:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003076:	00000097          	auipc	ra,0x0
    8000307a:	eaa080e7          	jalr	-342(ra) # 80002f20 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000307e:	864a                	mv	a2,s2
    80003080:	85a6                	mv	a1,s1
    80003082:	00000097          	auipc	ra,0x0
    80003086:	f58080e7          	jalr	-168(ra) # 80002fda <fetchstr>
}
    8000308a:	60e2                	ld	ra,24(sp)
    8000308c:	6442                	ld	s0,16(sp)
    8000308e:	64a2                	ld	s1,8(sp)
    80003090:	6902                	ld	s2,0(sp)
    80003092:	6105                	addi	sp,sp,32
    80003094:	8082                	ret

0000000080003096 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80003096:	1101                	addi	sp,sp,-32
    80003098:	ec06                	sd	ra,24(sp)
    8000309a:	e822                	sd	s0,16(sp)
    8000309c:	e426                	sd	s1,8(sp)
    8000309e:	e04a                	sd	s2,0(sp)
    800030a0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800030a2:	fffff097          	auipc	ra,0xfffff
    800030a6:	c2c080e7          	jalr	-980(ra) # 80001cce <myproc>
    800030aa:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800030ac:	05853903          	ld	s2,88(a0)
    800030b0:	0a893783          	ld	a5,168(s2)
    800030b4:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800030b8:	37fd                	addiw	a5,a5,-1
    800030ba:	4751                	li	a4,20
    800030bc:	00f76f63          	bltu	a4,a5,800030da <syscall+0x44>
    800030c0:	00369713          	slli	a4,a3,0x3
    800030c4:	00005797          	auipc	a5,0x5
    800030c8:	40c78793          	addi	a5,a5,1036 # 800084d0 <syscalls>
    800030cc:	97ba                	add	a5,a5,a4
    800030ce:	639c                	ld	a5,0(a5)
    800030d0:	c789                	beqz	a5,800030da <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800030d2:	9782                	jalr	a5
    800030d4:	06a93823          	sd	a0,112(s2)
    800030d8:	a839                	j	800030f6 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800030da:	15848613          	addi	a2,s1,344
    800030de:	588c                	lw	a1,48(s1)
    800030e0:	00005517          	auipc	a0,0x5
    800030e4:	3b850513          	addi	a0,a0,952 # 80008498 <states.1769+0x150>
    800030e8:	ffffd097          	auipc	ra,0xffffd
    800030ec:	4a0080e7          	jalr	1184(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800030f0:	6cbc                	ld	a5,88(s1)
    800030f2:	577d                	li	a4,-1
    800030f4:	fbb8                	sd	a4,112(a5)
  }
}
    800030f6:	60e2                	ld	ra,24(sp)
    800030f8:	6442                	ld	s0,16(sp)
    800030fa:	64a2                	ld	s1,8(sp)
    800030fc:	6902                	ld	s2,0(sp)
    800030fe:	6105                	addi	sp,sp,32
    80003100:	8082                	ret

0000000080003102 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003102:	1101                	addi	sp,sp,-32
    80003104:	ec06                	sd	ra,24(sp)
    80003106:	e822                	sd	s0,16(sp)
    80003108:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000310a:	fec40593          	addi	a1,s0,-20
    8000310e:	4501                	li	a0,0
    80003110:	00000097          	auipc	ra,0x0
    80003114:	f12080e7          	jalr	-238(ra) # 80003022 <argint>
    return -1;
    80003118:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000311a:	00054963          	bltz	a0,8000312c <sys_exit+0x2a>
  exit(n);
    8000311e:	fec42503          	lw	a0,-20(s0)
    80003122:	fffff097          	auipc	ra,0xfffff
    80003126:	6a6080e7          	jalr	1702(ra) # 800027c8 <exit>
  return 0;  // not reached
    8000312a:	4781                	li	a5,0
}
    8000312c:	853e                	mv	a0,a5
    8000312e:	60e2                	ld	ra,24(sp)
    80003130:	6442                	ld	s0,16(sp)
    80003132:	6105                	addi	sp,sp,32
    80003134:	8082                	ret

0000000080003136 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003136:	1141                	addi	sp,sp,-16
    80003138:	e406                	sd	ra,8(sp)
    8000313a:	e022                	sd	s0,0(sp)
    8000313c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000313e:	fffff097          	auipc	ra,0xfffff
    80003142:	b90080e7          	jalr	-1136(ra) # 80001cce <myproc>
}
    80003146:	5908                	lw	a0,48(a0)
    80003148:	60a2                	ld	ra,8(sp)
    8000314a:	6402                	ld	s0,0(sp)
    8000314c:	0141                	addi	sp,sp,16
    8000314e:	8082                	ret

0000000080003150 <sys_fork>:

uint64
sys_fork(void)
{
    80003150:	1141                	addi	sp,sp,-16
    80003152:	e406                	sd	ra,8(sp)
    80003154:	e022                	sd	s0,0(sp)
    80003156:	0800                	addi	s0,sp,16
  return fork();
    80003158:	fffff097          	auipc	ra,0xfffff
    8000315c:	004080e7          	jalr	4(ra) # 8000215c <fork>
}
    80003160:	60a2                	ld	ra,8(sp)
    80003162:	6402                	ld	s0,0(sp)
    80003164:	0141                	addi	sp,sp,16
    80003166:	8082                	ret

0000000080003168 <sys_wait>:

uint64
sys_wait(void)
{
    80003168:	1101                	addi	sp,sp,-32
    8000316a:	ec06                	sd	ra,24(sp)
    8000316c:	e822                	sd	s0,16(sp)
    8000316e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003170:	fe840593          	addi	a1,s0,-24
    80003174:	4501                	li	a0,0
    80003176:	00000097          	auipc	ra,0x0
    8000317a:	ece080e7          	jalr	-306(ra) # 80003044 <argaddr>
    8000317e:	87aa                	mv	a5,a0
    return -1;
    80003180:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003182:	0007c863          	bltz	a5,80003192 <sys_wait+0x2a>
  return wait(p);
    80003186:	fe843503          	ld	a0,-24(s0)
    8000318a:	fffff097          	auipc	ra,0xfffff
    8000318e:	3c0080e7          	jalr	960(ra) # 8000254a <wait>
}
    80003192:	60e2                	ld	ra,24(sp)
    80003194:	6442                	ld	s0,16(sp)
    80003196:	6105                	addi	sp,sp,32
    80003198:	8082                	ret

000000008000319a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000319a:	7179                	addi	sp,sp,-48
    8000319c:	f406                	sd	ra,40(sp)
    8000319e:	f022                	sd	s0,32(sp)
    800031a0:	ec26                	sd	s1,24(sp)
    800031a2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800031a4:	fdc40593          	addi	a1,s0,-36
    800031a8:	4501                	li	a0,0
    800031aa:	00000097          	auipc	ra,0x0
    800031ae:	e78080e7          	jalr	-392(ra) # 80003022 <argint>
    800031b2:	87aa                	mv	a5,a0
    return -1;
    800031b4:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800031b6:	0207c063          	bltz	a5,800031d6 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800031ba:	fffff097          	auipc	ra,0xfffff
    800031be:	b14080e7          	jalr	-1260(ra) # 80001cce <myproc>
    800031c2:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800031c4:	fdc42503          	lw	a0,-36(s0)
    800031c8:	fffff097          	auipc	ra,0xfffff
    800031cc:	f20080e7          	jalr	-224(ra) # 800020e8 <growproc>
    800031d0:	00054863          	bltz	a0,800031e0 <sys_sbrk+0x46>
    return -1;
  return addr;
    800031d4:	8526                	mv	a0,s1
}
    800031d6:	70a2                	ld	ra,40(sp)
    800031d8:	7402                	ld	s0,32(sp)
    800031da:	64e2                	ld	s1,24(sp)
    800031dc:	6145                	addi	sp,sp,48
    800031de:	8082                	ret
    return -1;
    800031e0:	557d                	li	a0,-1
    800031e2:	bfd5                	j	800031d6 <sys_sbrk+0x3c>

00000000800031e4 <sys_sleep>:

uint64
sys_sleep(void)
{
    800031e4:	7139                	addi	sp,sp,-64
    800031e6:	fc06                	sd	ra,56(sp)
    800031e8:	f822                	sd	s0,48(sp)
    800031ea:	f426                	sd	s1,40(sp)
    800031ec:	f04a                	sd	s2,32(sp)
    800031ee:	ec4e                	sd	s3,24(sp)
    800031f0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800031f2:	fcc40593          	addi	a1,s0,-52
    800031f6:	4501                	li	a0,0
    800031f8:	00000097          	auipc	ra,0x0
    800031fc:	e2a080e7          	jalr	-470(ra) # 80003022 <argint>
    return -1;
    80003200:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003202:	06054563          	bltz	a0,8000326c <sys_sleep+0x88>
  acquire(&tickslock);
    80003206:	00015517          	auipc	a0,0x15
    8000320a:	a0a50513          	addi	a0,a0,-1526 # 80017c10 <tickslock>
    8000320e:	ffffe097          	auipc	ra,0xffffe
    80003212:	9d6080e7          	jalr	-1578(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003216:	00006917          	auipc	s2,0x6
    8000321a:	e1a92903          	lw	s2,-486(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000321e:	fcc42783          	lw	a5,-52(s0)
    80003222:	cf85                	beqz	a5,8000325a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003224:	00015997          	auipc	s3,0x15
    80003228:	9ec98993          	addi	s3,s3,-1556 # 80017c10 <tickslock>
    8000322c:	00006497          	auipc	s1,0x6
    80003230:	e0448493          	addi	s1,s1,-508 # 80009030 <ticks>
    if(myproc()->killed){
    80003234:	fffff097          	auipc	ra,0xfffff
    80003238:	a9a080e7          	jalr	-1382(ra) # 80001cce <myproc>
    8000323c:	551c                	lw	a5,40(a0)
    8000323e:	ef9d                	bnez	a5,8000327c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003240:	85ce                	mv	a1,s3
    80003242:	8526                	mv	a0,s1
    80003244:	fffff097          	auipc	ra,0xfffff
    80003248:	290080e7          	jalr	656(ra) # 800024d4 <sleep>
  while(ticks - ticks0 < n){
    8000324c:	409c                	lw	a5,0(s1)
    8000324e:	412787bb          	subw	a5,a5,s2
    80003252:	fcc42703          	lw	a4,-52(s0)
    80003256:	fce7efe3          	bltu	a5,a4,80003234 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000325a:	00015517          	auipc	a0,0x15
    8000325e:	9b650513          	addi	a0,a0,-1610 # 80017c10 <tickslock>
    80003262:	ffffe097          	auipc	ra,0xffffe
    80003266:	a36080e7          	jalr	-1482(ra) # 80000c98 <release>
  return 0;
    8000326a:	4781                	li	a5,0
}
    8000326c:	853e                	mv	a0,a5
    8000326e:	70e2                	ld	ra,56(sp)
    80003270:	7442                	ld	s0,48(sp)
    80003272:	74a2                	ld	s1,40(sp)
    80003274:	7902                	ld	s2,32(sp)
    80003276:	69e2                	ld	s3,24(sp)
    80003278:	6121                	addi	sp,sp,64
    8000327a:	8082                	ret
      release(&tickslock);
    8000327c:	00015517          	auipc	a0,0x15
    80003280:	99450513          	addi	a0,a0,-1644 # 80017c10 <tickslock>
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	a14080e7          	jalr	-1516(ra) # 80000c98 <release>
      return -1;
    8000328c:	57fd                	li	a5,-1
    8000328e:	bff9                	j	8000326c <sys_sleep+0x88>

0000000080003290 <sys_kill>:

uint64
sys_kill(void)
{
    80003290:	1101                	addi	sp,sp,-32
    80003292:	ec06                	sd	ra,24(sp)
    80003294:	e822                	sd	s0,16(sp)
    80003296:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003298:	fec40593          	addi	a1,s0,-20
    8000329c:	4501                	li	a0,0
    8000329e:	00000097          	auipc	ra,0x0
    800032a2:	d84080e7          	jalr	-636(ra) # 80003022 <argint>
    800032a6:	87aa                	mv	a5,a0
    return -1;
    800032a8:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800032aa:	0007c863          	bltz	a5,800032ba <sys_kill+0x2a>
  return kill(pid);
    800032ae:	fec42503          	lw	a0,-20(s0)
    800032b2:	fffff097          	auipc	ra,0xfffff
    800032b6:	5fe080e7          	jalr	1534(ra) # 800028b0 <kill>
}
    800032ba:	60e2                	ld	ra,24(sp)
    800032bc:	6442                	ld	s0,16(sp)
    800032be:	6105                	addi	sp,sp,32
    800032c0:	8082                	ret

00000000800032c2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800032c2:	1101                	addi	sp,sp,-32
    800032c4:	ec06                	sd	ra,24(sp)
    800032c6:	e822                	sd	s0,16(sp)
    800032c8:	e426                	sd	s1,8(sp)
    800032ca:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800032cc:	00015517          	auipc	a0,0x15
    800032d0:	94450513          	addi	a0,a0,-1724 # 80017c10 <tickslock>
    800032d4:	ffffe097          	auipc	ra,0xffffe
    800032d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>
  xticks = ticks;
    800032dc:	00006497          	auipc	s1,0x6
    800032e0:	d544a483          	lw	s1,-684(s1) # 80009030 <ticks>
  release(&tickslock);
    800032e4:	00015517          	auipc	a0,0x15
    800032e8:	92c50513          	addi	a0,a0,-1748 # 80017c10 <tickslock>
    800032ec:	ffffe097          	auipc	ra,0xffffe
    800032f0:	9ac080e7          	jalr	-1620(ra) # 80000c98 <release>
  return xticks;
}
    800032f4:	02049513          	slli	a0,s1,0x20
    800032f8:	9101                	srli	a0,a0,0x20
    800032fa:	60e2                	ld	ra,24(sp)
    800032fc:	6442                	ld	s0,16(sp)
    800032fe:	64a2                	ld	s1,8(sp)
    80003300:	6105                	addi	sp,sp,32
    80003302:	8082                	ret

0000000080003304 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003304:	7179                	addi	sp,sp,-48
    80003306:	f406                	sd	ra,40(sp)
    80003308:	f022                	sd	s0,32(sp)
    8000330a:	ec26                	sd	s1,24(sp)
    8000330c:	e84a                	sd	s2,16(sp)
    8000330e:	e44e                	sd	s3,8(sp)
    80003310:	e052                	sd	s4,0(sp)
    80003312:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003314:	00005597          	auipc	a1,0x5
    80003318:	26c58593          	addi	a1,a1,620 # 80008580 <syscalls+0xb0>
    8000331c:	00015517          	auipc	a0,0x15
    80003320:	90c50513          	addi	a0,a0,-1780 # 80017c28 <bcache>
    80003324:	ffffe097          	auipc	ra,0xffffe
    80003328:	830080e7          	jalr	-2000(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000332c:	0001d797          	auipc	a5,0x1d
    80003330:	8fc78793          	addi	a5,a5,-1796 # 8001fc28 <bcache+0x8000>
    80003334:	0001d717          	auipc	a4,0x1d
    80003338:	b5c70713          	addi	a4,a4,-1188 # 8001fe90 <bcache+0x8268>
    8000333c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003340:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003344:	00015497          	auipc	s1,0x15
    80003348:	8fc48493          	addi	s1,s1,-1796 # 80017c40 <bcache+0x18>
    b->next = bcache.head.next;
    8000334c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000334e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003350:	00005a17          	auipc	s4,0x5
    80003354:	238a0a13          	addi	s4,s4,568 # 80008588 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003358:	2b893783          	ld	a5,696(s2)
    8000335c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000335e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003362:	85d2                	mv	a1,s4
    80003364:	01048513          	addi	a0,s1,16
    80003368:	00001097          	auipc	ra,0x1
    8000336c:	4bc080e7          	jalr	1212(ra) # 80004824 <initsleeplock>
    bcache.head.next->prev = b;
    80003370:	2b893783          	ld	a5,696(s2)
    80003374:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003376:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000337a:	45848493          	addi	s1,s1,1112
    8000337e:	fd349de3          	bne	s1,s3,80003358 <binit+0x54>
  }
}
    80003382:	70a2                	ld	ra,40(sp)
    80003384:	7402                	ld	s0,32(sp)
    80003386:	64e2                	ld	s1,24(sp)
    80003388:	6942                	ld	s2,16(sp)
    8000338a:	69a2                	ld	s3,8(sp)
    8000338c:	6a02                	ld	s4,0(sp)
    8000338e:	6145                	addi	sp,sp,48
    80003390:	8082                	ret

0000000080003392 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003392:	7179                	addi	sp,sp,-48
    80003394:	f406                	sd	ra,40(sp)
    80003396:	f022                	sd	s0,32(sp)
    80003398:	ec26                	sd	s1,24(sp)
    8000339a:	e84a                	sd	s2,16(sp)
    8000339c:	e44e                	sd	s3,8(sp)
    8000339e:	1800                	addi	s0,sp,48
    800033a0:	89aa                	mv	s3,a0
    800033a2:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800033a4:	00015517          	auipc	a0,0x15
    800033a8:	88450513          	addi	a0,a0,-1916 # 80017c28 <bcache>
    800033ac:	ffffe097          	auipc	ra,0xffffe
    800033b0:	838080e7          	jalr	-1992(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800033b4:	0001d497          	auipc	s1,0x1d
    800033b8:	b2c4b483          	ld	s1,-1236(s1) # 8001fee0 <bcache+0x82b8>
    800033bc:	0001d797          	auipc	a5,0x1d
    800033c0:	ad478793          	addi	a5,a5,-1324 # 8001fe90 <bcache+0x8268>
    800033c4:	02f48f63          	beq	s1,a5,80003402 <bread+0x70>
    800033c8:	873e                	mv	a4,a5
    800033ca:	a021                	j	800033d2 <bread+0x40>
    800033cc:	68a4                	ld	s1,80(s1)
    800033ce:	02e48a63          	beq	s1,a4,80003402 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800033d2:	449c                	lw	a5,8(s1)
    800033d4:	ff379ce3          	bne	a5,s3,800033cc <bread+0x3a>
    800033d8:	44dc                	lw	a5,12(s1)
    800033da:	ff2799e3          	bne	a5,s2,800033cc <bread+0x3a>
      b->refcnt++;
    800033de:	40bc                	lw	a5,64(s1)
    800033e0:	2785                	addiw	a5,a5,1
    800033e2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033e4:	00015517          	auipc	a0,0x15
    800033e8:	84450513          	addi	a0,a0,-1980 # 80017c28 <bcache>
    800033ec:	ffffe097          	auipc	ra,0xffffe
    800033f0:	8ac080e7          	jalr	-1876(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800033f4:	01048513          	addi	a0,s1,16
    800033f8:	00001097          	auipc	ra,0x1
    800033fc:	466080e7          	jalr	1126(ra) # 8000485e <acquiresleep>
      return b;
    80003400:	a8b9                	j	8000345e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003402:	0001d497          	auipc	s1,0x1d
    80003406:	ad64b483          	ld	s1,-1322(s1) # 8001fed8 <bcache+0x82b0>
    8000340a:	0001d797          	auipc	a5,0x1d
    8000340e:	a8678793          	addi	a5,a5,-1402 # 8001fe90 <bcache+0x8268>
    80003412:	00f48863          	beq	s1,a5,80003422 <bread+0x90>
    80003416:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003418:	40bc                	lw	a5,64(s1)
    8000341a:	cf81                	beqz	a5,80003432 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000341c:	64a4                	ld	s1,72(s1)
    8000341e:	fee49de3          	bne	s1,a4,80003418 <bread+0x86>
  panic("bget: no buffers");
    80003422:	00005517          	auipc	a0,0x5
    80003426:	16e50513          	addi	a0,a0,366 # 80008590 <syscalls+0xc0>
    8000342a:	ffffd097          	auipc	ra,0xffffd
    8000342e:	114080e7          	jalr	276(ra) # 8000053e <panic>
      b->dev = dev;
    80003432:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003436:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000343a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000343e:	4785                	li	a5,1
    80003440:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003442:	00014517          	auipc	a0,0x14
    80003446:	7e650513          	addi	a0,a0,2022 # 80017c28 <bcache>
    8000344a:	ffffe097          	auipc	ra,0xffffe
    8000344e:	84e080e7          	jalr	-1970(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003452:	01048513          	addi	a0,s1,16
    80003456:	00001097          	auipc	ra,0x1
    8000345a:	408080e7          	jalr	1032(ra) # 8000485e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000345e:	409c                	lw	a5,0(s1)
    80003460:	cb89                	beqz	a5,80003472 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003462:	8526                	mv	a0,s1
    80003464:	70a2                	ld	ra,40(sp)
    80003466:	7402                	ld	s0,32(sp)
    80003468:	64e2                	ld	s1,24(sp)
    8000346a:	6942                	ld	s2,16(sp)
    8000346c:	69a2                	ld	s3,8(sp)
    8000346e:	6145                	addi	sp,sp,48
    80003470:	8082                	ret
    virtio_disk_rw(b, 0);
    80003472:	4581                	li	a1,0
    80003474:	8526                	mv	a0,s1
    80003476:	00003097          	auipc	ra,0x3
    8000347a:	f10080e7          	jalr	-240(ra) # 80006386 <virtio_disk_rw>
    b->valid = 1;
    8000347e:	4785                	li	a5,1
    80003480:	c09c                	sw	a5,0(s1)
  return b;
    80003482:	b7c5                	j	80003462 <bread+0xd0>

0000000080003484 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003484:	1101                	addi	sp,sp,-32
    80003486:	ec06                	sd	ra,24(sp)
    80003488:	e822                	sd	s0,16(sp)
    8000348a:	e426                	sd	s1,8(sp)
    8000348c:	1000                	addi	s0,sp,32
    8000348e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003490:	0541                	addi	a0,a0,16
    80003492:	00001097          	auipc	ra,0x1
    80003496:	466080e7          	jalr	1126(ra) # 800048f8 <holdingsleep>
    8000349a:	cd01                	beqz	a0,800034b2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000349c:	4585                	li	a1,1
    8000349e:	8526                	mv	a0,s1
    800034a0:	00003097          	auipc	ra,0x3
    800034a4:	ee6080e7          	jalr	-282(ra) # 80006386 <virtio_disk_rw>
}
    800034a8:	60e2                	ld	ra,24(sp)
    800034aa:	6442                	ld	s0,16(sp)
    800034ac:	64a2                	ld	s1,8(sp)
    800034ae:	6105                	addi	sp,sp,32
    800034b0:	8082                	ret
    panic("bwrite");
    800034b2:	00005517          	auipc	a0,0x5
    800034b6:	0f650513          	addi	a0,a0,246 # 800085a8 <syscalls+0xd8>
    800034ba:	ffffd097          	auipc	ra,0xffffd
    800034be:	084080e7          	jalr	132(ra) # 8000053e <panic>

00000000800034c2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034c2:	1101                	addi	sp,sp,-32
    800034c4:	ec06                	sd	ra,24(sp)
    800034c6:	e822                	sd	s0,16(sp)
    800034c8:	e426                	sd	s1,8(sp)
    800034ca:	e04a                	sd	s2,0(sp)
    800034cc:	1000                	addi	s0,sp,32
    800034ce:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034d0:	01050913          	addi	s2,a0,16
    800034d4:	854a                	mv	a0,s2
    800034d6:	00001097          	auipc	ra,0x1
    800034da:	422080e7          	jalr	1058(ra) # 800048f8 <holdingsleep>
    800034de:	c92d                	beqz	a0,80003550 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800034e0:	854a                	mv	a0,s2
    800034e2:	00001097          	auipc	ra,0x1
    800034e6:	3d2080e7          	jalr	978(ra) # 800048b4 <releasesleep>

  acquire(&bcache.lock);
    800034ea:	00014517          	auipc	a0,0x14
    800034ee:	73e50513          	addi	a0,a0,1854 # 80017c28 <bcache>
    800034f2:	ffffd097          	auipc	ra,0xffffd
    800034f6:	6f2080e7          	jalr	1778(ra) # 80000be4 <acquire>
  b->refcnt--;
    800034fa:	40bc                	lw	a5,64(s1)
    800034fc:	37fd                	addiw	a5,a5,-1
    800034fe:	0007871b          	sext.w	a4,a5
    80003502:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003504:	eb05                	bnez	a4,80003534 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003506:	68bc                	ld	a5,80(s1)
    80003508:	64b8                	ld	a4,72(s1)
    8000350a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000350c:	64bc                	ld	a5,72(s1)
    8000350e:	68b8                	ld	a4,80(s1)
    80003510:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003512:	0001c797          	auipc	a5,0x1c
    80003516:	71678793          	addi	a5,a5,1814 # 8001fc28 <bcache+0x8000>
    8000351a:	2b87b703          	ld	a4,696(a5)
    8000351e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003520:	0001d717          	auipc	a4,0x1d
    80003524:	97070713          	addi	a4,a4,-1680 # 8001fe90 <bcache+0x8268>
    80003528:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000352a:	2b87b703          	ld	a4,696(a5)
    8000352e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003530:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003534:	00014517          	auipc	a0,0x14
    80003538:	6f450513          	addi	a0,a0,1780 # 80017c28 <bcache>
    8000353c:	ffffd097          	auipc	ra,0xffffd
    80003540:	75c080e7          	jalr	1884(ra) # 80000c98 <release>
}
    80003544:	60e2                	ld	ra,24(sp)
    80003546:	6442                	ld	s0,16(sp)
    80003548:	64a2                	ld	s1,8(sp)
    8000354a:	6902                	ld	s2,0(sp)
    8000354c:	6105                	addi	sp,sp,32
    8000354e:	8082                	ret
    panic("brelse");
    80003550:	00005517          	auipc	a0,0x5
    80003554:	06050513          	addi	a0,a0,96 # 800085b0 <syscalls+0xe0>
    80003558:	ffffd097          	auipc	ra,0xffffd
    8000355c:	fe6080e7          	jalr	-26(ra) # 8000053e <panic>

0000000080003560 <bpin>:

void
bpin(struct buf *b) {
    80003560:	1101                	addi	sp,sp,-32
    80003562:	ec06                	sd	ra,24(sp)
    80003564:	e822                	sd	s0,16(sp)
    80003566:	e426                	sd	s1,8(sp)
    80003568:	1000                	addi	s0,sp,32
    8000356a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000356c:	00014517          	auipc	a0,0x14
    80003570:	6bc50513          	addi	a0,a0,1724 # 80017c28 <bcache>
    80003574:	ffffd097          	auipc	ra,0xffffd
    80003578:	670080e7          	jalr	1648(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000357c:	40bc                	lw	a5,64(s1)
    8000357e:	2785                	addiw	a5,a5,1
    80003580:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003582:	00014517          	auipc	a0,0x14
    80003586:	6a650513          	addi	a0,a0,1702 # 80017c28 <bcache>
    8000358a:	ffffd097          	auipc	ra,0xffffd
    8000358e:	70e080e7          	jalr	1806(ra) # 80000c98 <release>
}
    80003592:	60e2                	ld	ra,24(sp)
    80003594:	6442                	ld	s0,16(sp)
    80003596:	64a2                	ld	s1,8(sp)
    80003598:	6105                	addi	sp,sp,32
    8000359a:	8082                	ret

000000008000359c <bunpin>:

void
bunpin(struct buf *b) {
    8000359c:	1101                	addi	sp,sp,-32
    8000359e:	ec06                	sd	ra,24(sp)
    800035a0:	e822                	sd	s0,16(sp)
    800035a2:	e426                	sd	s1,8(sp)
    800035a4:	1000                	addi	s0,sp,32
    800035a6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035a8:	00014517          	auipc	a0,0x14
    800035ac:	68050513          	addi	a0,a0,1664 # 80017c28 <bcache>
    800035b0:	ffffd097          	auipc	ra,0xffffd
    800035b4:	634080e7          	jalr	1588(ra) # 80000be4 <acquire>
  b->refcnt--;
    800035b8:	40bc                	lw	a5,64(s1)
    800035ba:	37fd                	addiw	a5,a5,-1
    800035bc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035be:	00014517          	auipc	a0,0x14
    800035c2:	66a50513          	addi	a0,a0,1642 # 80017c28 <bcache>
    800035c6:	ffffd097          	auipc	ra,0xffffd
    800035ca:	6d2080e7          	jalr	1746(ra) # 80000c98 <release>
}
    800035ce:	60e2                	ld	ra,24(sp)
    800035d0:	6442                	ld	s0,16(sp)
    800035d2:	64a2                	ld	s1,8(sp)
    800035d4:	6105                	addi	sp,sp,32
    800035d6:	8082                	ret

00000000800035d8 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035d8:	1101                	addi	sp,sp,-32
    800035da:	ec06                	sd	ra,24(sp)
    800035dc:	e822                	sd	s0,16(sp)
    800035de:	e426                	sd	s1,8(sp)
    800035e0:	e04a                	sd	s2,0(sp)
    800035e2:	1000                	addi	s0,sp,32
    800035e4:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035e6:	00d5d59b          	srliw	a1,a1,0xd
    800035ea:	0001d797          	auipc	a5,0x1d
    800035ee:	d1a7a783          	lw	a5,-742(a5) # 80020304 <sb+0x1c>
    800035f2:	9dbd                	addw	a1,a1,a5
    800035f4:	00000097          	auipc	ra,0x0
    800035f8:	d9e080e7          	jalr	-610(ra) # 80003392 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800035fc:	0074f713          	andi	a4,s1,7
    80003600:	4785                	li	a5,1
    80003602:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003606:	14ce                	slli	s1,s1,0x33
    80003608:	90d9                	srli	s1,s1,0x36
    8000360a:	00950733          	add	a4,a0,s1
    8000360e:	05874703          	lbu	a4,88(a4)
    80003612:	00e7f6b3          	and	a3,a5,a4
    80003616:	c69d                	beqz	a3,80003644 <bfree+0x6c>
    80003618:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000361a:	94aa                	add	s1,s1,a0
    8000361c:	fff7c793          	not	a5,a5
    80003620:	8ff9                	and	a5,a5,a4
    80003622:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003626:	00001097          	auipc	ra,0x1
    8000362a:	118080e7          	jalr	280(ra) # 8000473e <log_write>
  brelse(bp);
    8000362e:	854a                	mv	a0,s2
    80003630:	00000097          	auipc	ra,0x0
    80003634:	e92080e7          	jalr	-366(ra) # 800034c2 <brelse>
}
    80003638:	60e2                	ld	ra,24(sp)
    8000363a:	6442                	ld	s0,16(sp)
    8000363c:	64a2                	ld	s1,8(sp)
    8000363e:	6902                	ld	s2,0(sp)
    80003640:	6105                	addi	sp,sp,32
    80003642:	8082                	ret
    panic("freeing free block");
    80003644:	00005517          	auipc	a0,0x5
    80003648:	f7450513          	addi	a0,a0,-140 # 800085b8 <syscalls+0xe8>
    8000364c:	ffffd097          	auipc	ra,0xffffd
    80003650:	ef2080e7          	jalr	-270(ra) # 8000053e <panic>

0000000080003654 <balloc>:
{
    80003654:	711d                	addi	sp,sp,-96
    80003656:	ec86                	sd	ra,88(sp)
    80003658:	e8a2                	sd	s0,80(sp)
    8000365a:	e4a6                	sd	s1,72(sp)
    8000365c:	e0ca                	sd	s2,64(sp)
    8000365e:	fc4e                	sd	s3,56(sp)
    80003660:	f852                	sd	s4,48(sp)
    80003662:	f456                	sd	s5,40(sp)
    80003664:	f05a                	sd	s6,32(sp)
    80003666:	ec5e                	sd	s7,24(sp)
    80003668:	e862                	sd	s8,16(sp)
    8000366a:	e466                	sd	s9,8(sp)
    8000366c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000366e:	0001d797          	auipc	a5,0x1d
    80003672:	c7e7a783          	lw	a5,-898(a5) # 800202ec <sb+0x4>
    80003676:	cbd1                	beqz	a5,8000370a <balloc+0xb6>
    80003678:	8baa                	mv	s7,a0
    8000367a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000367c:	0001db17          	auipc	s6,0x1d
    80003680:	c6cb0b13          	addi	s6,s6,-916 # 800202e8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003684:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003686:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003688:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000368a:	6c89                	lui	s9,0x2
    8000368c:	a831                	j	800036a8 <balloc+0x54>
    brelse(bp);
    8000368e:	854a                	mv	a0,s2
    80003690:	00000097          	auipc	ra,0x0
    80003694:	e32080e7          	jalr	-462(ra) # 800034c2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003698:	015c87bb          	addw	a5,s9,s5
    8000369c:	00078a9b          	sext.w	s5,a5
    800036a0:	004b2703          	lw	a4,4(s6)
    800036a4:	06eaf363          	bgeu	s5,a4,8000370a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800036a8:	41fad79b          	sraiw	a5,s5,0x1f
    800036ac:	0137d79b          	srliw	a5,a5,0x13
    800036b0:	015787bb          	addw	a5,a5,s5
    800036b4:	40d7d79b          	sraiw	a5,a5,0xd
    800036b8:	01cb2583          	lw	a1,28(s6)
    800036bc:	9dbd                	addw	a1,a1,a5
    800036be:	855e                	mv	a0,s7
    800036c0:	00000097          	auipc	ra,0x0
    800036c4:	cd2080e7          	jalr	-814(ra) # 80003392 <bread>
    800036c8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036ca:	004b2503          	lw	a0,4(s6)
    800036ce:	000a849b          	sext.w	s1,s5
    800036d2:	8662                	mv	a2,s8
    800036d4:	faa4fde3          	bgeu	s1,a0,8000368e <balloc+0x3a>
      m = 1 << (bi % 8);
    800036d8:	41f6579b          	sraiw	a5,a2,0x1f
    800036dc:	01d7d69b          	srliw	a3,a5,0x1d
    800036e0:	00c6873b          	addw	a4,a3,a2
    800036e4:	00777793          	andi	a5,a4,7
    800036e8:	9f95                	subw	a5,a5,a3
    800036ea:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036ee:	4037571b          	sraiw	a4,a4,0x3
    800036f2:	00e906b3          	add	a3,s2,a4
    800036f6:	0586c683          	lbu	a3,88(a3)
    800036fa:	00d7f5b3          	and	a1,a5,a3
    800036fe:	cd91                	beqz	a1,8000371a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003700:	2605                	addiw	a2,a2,1
    80003702:	2485                	addiw	s1,s1,1
    80003704:	fd4618e3          	bne	a2,s4,800036d4 <balloc+0x80>
    80003708:	b759                	j	8000368e <balloc+0x3a>
  panic("balloc: out of blocks");
    8000370a:	00005517          	auipc	a0,0x5
    8000370e:	ec650513          	addi	a0,a0,-314 # 800085d0 <syscalls+0x100>
    80003712:	ffffd097          	auipc	ra,0xffffd
    80003716:	e2c080e7          	jalr	-468(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000371a:	974a                	add	a4,a4,s2
    8000371c:	8fd5                	or	a5,a5,a3
    8000371e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003722:	854a                	mv	a0,s2
    80003724:	00001097          	auipc	ra,0x1
    80003728:	01a080e7          	jalr	26(ra) # 8000473e <log_write>
        brelse(bp);
    8000372c:	854a                	mv	a0,s2
    8000372e:	00000097          	auipc	ra,0x0
    80003732:	d94080e7          	jalr	-620(ra) # 800034c2 <brelse>
  bp = bread(dev, bno);
    80003736:	85a6                	mv	a1,s1
    80003738:	855e                	mv	a0,s7
    8000373a:	00000097          	auipc	ra,0x0
    8000373e:	c58080e7          	jalr	-936(ra) # 80003392 <bread>
    80003742:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003744:	40000613          	li	a2,1024
    80003748:	4581                	li	a1,0
    8000374a:	05850513          	addi	a0,a0,88
    8000374e:	ffffd097          	auipc	ra,0xffffd
    80003752:	592080e7          	jalr	1426(ra) # 80000ce0 <memset>
  log_write(bp);
    80003756:	854a                	mv	a0,s2
    80003758:	00001097          	auipc	ra,0x1
    8000375c:	fe6080e7          	jalr	-26(ra) # 8000473e <log_write>
  brelse(bp);
    80003760:	854a                	mv	a0,s2
    80003762:	00000097          	auipc	ra,0x0
    80003766:	d60080e7          	jalr	-672(ra) # 800034c2 <brelse>
}
    8000376a:	8526                	mv	a0,s1
    8000376c:	60e6                	ld	ra,88(sp)
    8000376e:	6446                	ld	s0,80(sp)
    80003770:	64a6                	ld	s1,72(sp)
    80003772:	6906                	ld	s2,64(sp)
    80003774:	79e2                	ld	s3,56(sp)
    80003776:	7a42                	ld	s4,48(sp)
    80003778:	7aa2                	ld	s5,40(sp)
    8000377a:	7b02                	ld	s6,32(sp)
    8000377c:	6be2                	ld	s7,24(sp)
    8000377e:	6c42                	ld	s8,16(sp)
    80003780:	6ca2                	ld	s9,8(sp)
    80003782:	6125                	addi	sp,sp,96
    80003784:	8082                	ret

0000000080003786 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003786:	7179                	addi	sp,sp,-48
    80003788:	f406                	sd	ra,40(sp)
    8000378a:	f022                	sd	s0,32(sp)
    8000378c:	ec26                	sd	s1,24(sp)
    8000378e:	e84a                	sd	s2,16(sp)
    80003790:	e44e                	sd	s3,8(sp)
    80003792:	e052                	sd	s4,0(sp)
    80003794:	1800                	addi	s0,sp,48
    80003796:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003798:	47ad                	li	a5,11
    8000379a:	04b7fe63          	bgeu	a5,a1,800037f6 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000379e:	ff45849b          	addiw	s1,a1,-12
    800037a2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800037a6:	0ff00793          	li	a5,255
    800037aa:	0ae7e363          	bltu	a5,a4,80003850 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800037ae:	08052583          	lw	a1,128(a0)
    800037b2:	c5ad                	beqz	a1,8000381c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800037b4:	00092503          	lw	a0,0(s2)
    800037b8:	00000097          	auipc	ra,0x0
    800037bc:	bda080e7          	jalr	-1062(ra) # 80003392 <bread>
    800037c0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037c2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800037c6:	02049593          	slli	a1,s1,0x20
    800037ca:	9181                	srli	a1,a1,0x20
    800037cc:	058a                	slli	a1,a1,0x2
    800037ce:	00b784b3          	add	s1,a5,a1
    800037d2:	0004a983          	lw	s3,0(s1)
    800037d6:	04098d63          	beqz	s3,80003830 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800037da:	8552                	mv	a0,s4
    800037dc:	00000097          	auipc	ra,0x0
    800037e0:	ce6080e7          	jalr	-794(ra) # 800034c2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037e4:	854e                	mv	a0,s3
    800037e6:	70a2                	ld	ra,40(sp)
    800037e8:	7402                	ld	s0,32(sp)
    800037ea:	64e2                	ld	s1,24(sp)
    800037ec:	6942                	ld	s2,16(sp)
    800037ee:	69a2                	ld	s3,8(sp)
    800037f0:	6a02                	ld	s4,0(sp)
    800037f2:	6145                	addi	sp,sp,48
    800037f4:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800037f6:	02059493          	slli	s1,a1,0x20
    800037fa:	9081                	srli	s1,s1,0x20
    800037fc:	048a                	slli	s1,s1,0x2
    800037fe:	94aa                	add	s1,s1,a0
    80003800:	0504a983          	lw	s3,80(s1)
    80003804:	fe0990e3          	bnez	s3,800037e4 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003808:	4108                	lw	a0,0(a0)
    8000380a:	00000097          	auipc	ra,0x0
    8000380e:	e4a080e7          	jalr	-438(ra) # 80003654 <balloc>
    80003812:	0005099b          	sext.w	s3,a0
    80003816:	0534a823          	sw	s3,80(s1)
    8000381a:	b7e9                	j	800037e4 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000381c:	4108                	lw	a0,0(a0)
    8000381e:	00000097          	auipc	ra,0x0
    80003822:	e36080e7          	jalr	-458(ra) # 80003654 <balloc>
    80003826:	0005059b          	sext.w	a1,a0
    8000382a:	08b92023          	sw	a1,128(s2)
    8000382e:	b759                	j	800037b4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003830:	00092503          	lw	a0,0(s2)
    80003834:	00000097          	auipc	ra,0x0
    80003838:	e20080e7          	jalr	-480(ra) # 80003654 <balloc>
    8000383c:	0005099b          	sext.w	s3,a0
    80003840:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003844:	8552                	mv	a0,s4
    80003846:	00001097          	auipc	ra,0x1
    8000384a:	ef8080e7          	jalr	-264(ra) # 8000473e <log_write>
    8000384e:	b771                	j	800037da <bmap+0x54>
  panic("bmap: out of range");
    80003850:	00005517          	auipc	a0,0x5
    80003854:	d9850513          	addi	a0,a0,-616 # 800085e8 <syscalls+0x118>
    80003858:	ffffd097          	auipc	ra,0xffffd
    8000385c:	ce6080e7          	jalr	-794(ra) # 8000053e <panic>

0000000080003860 <iget>:
{
    80003860:	7179                	addi	sp,sp,-48
    80003862:	f406                	sd	ra,40(sp)
    80003864:	f022                	sd	s0,32(sp)
    80003866:	ec26                	sd	s1,24(sp)
    80003868:	e84a                	sd	s2,16(sp)
    8000386a:	e44e                	sd	s3,8(sp)
    8000386c:	e052                	sd	s4,0(sp)
    8000386e:	1800                	addi	s0,sp,48
    80003870:	89aa                	mv	s3,a0
    80003872:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003874:	0001d517          	auipc	a0,0x1d
    80003878:	a9450513          	addi	a0,a0,-1388 # 80020308 <itable>
    8000387c:	ffffd097          	auipc	ra,0xffffd
    80003880:	368080e7          	jalr	872(ra) # 80000be4 <acquire>
  empty = 0;
    80003884:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003886:	0001d497          	auipc	s1,0x1d
    8000388a:	a9a48493          	addi	s1,s1,-1382 # 80020320 <itable+0x18>
    8000388e:	0001e697          	auipc	a3,0x1e
    80003892:	52268693          	addi	a3,a3,1314 # 80021db0 <log>
    80003896:	a039                	j	800038a4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003898:	02090b63          	beqz	s2,800038ce <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000389c:	08848493          	addi	s1,s1,136
    800038a0:	02d48a63          	beq	s1,a3,800038d4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038a4:	449c                	lw	a5,8(s1)
    800038a6:	fef059e3          	blez	a5,80003898 <iget+0x38>
    800038aa:	4098                	lw	a4,0(s1)
    800038ac:	ff3716e3          	bne	a4,s3,80003898 <iget+0x38>
    800038b0:	40d8                	lw	a4,4(s1)
    800038b2:	ff4713e3          	bne	a4,s4,80003898 <iget+0x38>
      ip->ref++;
    800038b6:	2785                	addiw	a5,a5,1
    800038b8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800038ba:	0001d517          	auipc	a0,0x1d
    800038be:	a4e50513          	addi	a0,a0,-1458 # 80020308 <itable>
    800038c2:	ffffd097          	auipc	ra,0xffffd
    800038c6:	3d6080e7          	jalr	982(ra) # 80000c98 <release>
      return ip;
    800038ca:	8926                	mv	s2,s1
    800038cc:	a03d                	j	800038fa <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038ce:	f7f9                	bnez	a5,8000389c <iget+0x3c>
    800038d0:	8926                	mv	s2,s1
    800038d2:	b7e9                	j	8000389c <iget+0x3c>
  if(empty == 0)
    800038d4:	02090c63          	beqz	s2,8000390c <iget+0xac>
  ip->dev = dev;
    800038d8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038dc:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038e0:	4785                	li	a5,1
    800038e2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038e6:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800038ea:	0001d517          	auipc	a0,0x1d
    800038ee:	a1e50513          	addi	a0,a0,-1506 # 80020308 <itable>
    800038f2:	ffffd097          	auipc	ra,0xffffd
    800038f6:	3a6080e7          	jalr	934(ra) # 80000c98 <release>
}
    800038fa:	854a                	mv	a0,s2
    800038fc:	70a2                	ld	ra,40(sp)
    800038fe:	7402                	ld	s0,32(sp)
    80003900:	64e2                	ld	s1,24(sp)
    80003902:	6942                	ld	s2,16(sp)
    80003904:	69a2                	ld	s3,8(sp)
    80003906:	6a02                	ld	s4,0(sp)
    80003908:	6145                	addi	sp,sp,48
    8000390a:	8082                	ret
    panic("iget: no inodes");
    8000390c:	00005517          	auipc	a0,0x5
    80003910:	cf450513          	addi	a0,a0,-780 # 80008600 <syscalls+0x130>
    80003914:	ffffd097          	auipc	ra,0xffffd
    80003918:	c2a080e7          	jalr	-982(ra) # 8000053e <panic>

000000008000391c <fsinit>:
fsinit(int dev) {
    8000391c:	7179                	addi	sp,sp,-48
    8000391e:	f406                	sd	ra,40(sp)
    80003920:	f022                	sd	s0,32(sp)
    80003922:	ec26                	sd	s1,24(sp)
    80003924:	e84a                	sd	s2,16(sp)
    80003926:	e44e                	sd	s3,8(sp)
    80003928:	1800                	addi	s0,sp,48
    8000392a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000392c:	4585                	li	a1,1
    8000392e:	00000097          	auipc	ra,0x0
    80003932:	a64080e7          	jalr	-1436(ra) # 80003392 <bread>
    80003936:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003938:	0001d997          	auipc	s3,0x1d
    8000393c:	9b098993          	addi	s3,s3,-1616 # 800202e8 <sb>
    80003940:	02000613          	li	a2,32
    80003944:	05850593          	addi	a1,a0,88
    80003948:	854e                	mv	a0,s3
    8000394a:	ffffd097          	auipc	ra,0xffffd
    8000394e:	3f6080e7          	jalr	1014(ra) # 80000d40 <memmove>
  brelse(bp);
    80003952:	8526                	mv	a0,s1
    80003954:	00000097          	auipc	ra,0x0
    80003958:	b6e080e7          	jalr	-1170(ra) # 800034c2 <brelse>
  if(sb.magic != FSMAGIC)
    8000395c:	0009a703          	lw	a4,0(s3)
    80003960:	102037b7          	lui	a5,0x10203
    80003964:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003968:	02f71263          	bne	a4,a5,8000398c <fsinit+0x70>
  initlog(dev, &sb);
    8000396c:	0001d597          	auipc	a1,0x1d
    80003970:	97c58593          	addi	a1,a1,-1668 # 800202e8 <sb>
    80003974:	854a                	mv	a0,s2
    80003976:	00001097          	auipc	ra,0x1
    8000397a:	b4c080e7          	jalr	-1204(ra) # 800044c2 <initlog>
}
    8000397e:	70a2                	ld	ra,40(sp)
    80003980:	7402                	ld	s0,32(sp)
    80003982:	64e2                	ld	s1,24(sp)
    80003984:	6942                	ld	s2,16(sp)
    80003986:	69a2                	ld	s3,8(sp)
    80003988:	6145                	addi	sp,sp,48
    8000398a:	8082                	ret
    panic("invalid file system");
    8000398c:	00005517          	auipc	a0,0x5
    80003990:	c8450513          	addi	a0,a0,-892 # 80008610 <syscalls+0x140>
    80003994:	ffffd097          	auipc	ra,0xffffd
    80003998:	baa080e7          	jalr	-1110(ra) # 8000053e <panic>

000000008000399c <iinit>:
{
    8000399c:	7179                	addi	sp,sp,-48
    8000399e:	f406                	sd	ra,40(sp)
    800039a0:	f022                	sd	s0,32(sp)
    800039a2:	ec26                	sd	s1,24(sp)
    800039a4:	e84a                	sd	s2,16(sp)
    800039a6:	e44e                	sd	s3,8(sp)
    800039a8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800039aa:	00005597          	auipc	a1,0x5
    800039ae:	c7e58593          	addi	a1,a1,-898 # 80008628 <syscalls+0x158>
    800039b2:	0001d517          	auipc	a0,0x1d
    800039b6:	95650513          	addi	a0,a0,-1706 # 80020308 <itable>
    800039ba:	ffffd097          	auipc	ra,0xffffd
    800039be:	19a080e7          	jalr	410(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800039c2:	0001d497          	auipc	s1,0x1d
    800039c6:	96e48493          	addi	s1,s1,-1682 # 80020330 <itable+0x28>
    800039ca:	0001e997          	auipc	s3,0x1e
    800039ce:	3f698993          	addi	s3,s3,1014 # 80021dc0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800039d2:	00005917          	auipc	s2,0x5
    800039d6:	c5e90913          	addi	s2,s2,-930 # 80008630 <syscalls+0x160>
    800039da:	85ca                	mv	a1,s2
    800039dc:	8526                	mv	a0,s1
    800039de:	00001097          	auipc	ra,0x1
    800039e2:	e46080e7          	jalr	-442(ra) # 80004824 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039e6:	08848493          	addi	s1,s1,136
    800039ea:	ff3498e3          	bne	s1,s3,800039da <iinit+0x3e>
}
    800039ee:	70a2                	ld	ra,40(sp)
    800039f0:	7402                	ld	s0,32(sp)
    800039f2:	64e2                	ld	s1,24(sp)
    800039f4:	6942                	ld	s2,16(sp)
    800039f6:	69a2                	ld	s3,8(sp)
    800039f8:	6145                	addi	sp,sp,48
    800039fa:	8082                	ret

00000000800039fc <ialloc>:
{
    800039fc:	715d                	addi	sp,sp,-80
    800039fe:	e486                	sd	ra,72(sp)
    80003a00:	e0a2                	sd	s0,64(sp)
    80003a02:	fc26                	sd	s1,56(sp)
    80003a04:	f84a                	sd	s2,48(sp)
    80003a06:	f44e                	sd	s3,40(sp)
    80003a08:	f052                	sd	s4,32(sp)
    80003a0a:	ec56                	sd	s5,24(sp)
    80003a0c:	e85a                	sd	s6,16(sp)
    80003a0e:	e45e                	sd	s7,8(sp)
    80003a10:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a12:	0001d717          	auipc	a4,0x1d
    80003a16:	8e272703          	lw	a4,-1822(a4) # 800202f4 <sb+0xc>
    80003a1a:	4785                	li	a5,1
    80003a1c:	04e7fa63          	bgeu	a5,a4,80003a70 <ialloc+0x74>
    80003a20:	8aaa                	mv	s5,a0
    80003a22:	8bae                	mv	s7,a1
    80003a24:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a26:	0001da17          	auipc	s4,0x1d
    80003a2a:	8c2a0a13          	addi	s4,s4,-1854 # 800202e8 <sb>
    80003a2e:	00048b1b          	sext.w	s6,s1
    80003a32:	0044d593          	srli	a1,s1,0x4
    80003a36:	018a2783          	lw	a5,24(s4)
    80003a3a:	9dbd                	addw	a1,a1,a5
    80003a3c:	8556                	mv	a0,s5
    80003a3e:	00000097          	auipc	ra,0x0
    80003a42:	954080e7          	jalr	-1708(ra) # 80003392 <bread>
    80003a46:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a48:	05850993          	addi	s3,a0,88
    80003a4c:	00f4f793          	andi	a5,s1,15
    80003a50:	079a                	slli	a5,a5,0x6
    80003a52:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a54:	00099783          	lh	a5,0(s3)
    80003a58:	c785                	beqz	a5,80003a80 <ialloc+0x84>
    brelse(bp);
    80003a5a:	00000097          	auipc	ra,0x0
    80003a5e:	a68080e7          	jalr	-1432(ra) # 800034c2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a62:	0485                	addi	s1,s1,1
    80003a64:	00ca2703          	lw	a4,12(s4)
    80003a68:	0004879b          	sext.w	a5,s1
    80003a6c:	fce7e1e3          	bltu	a5,a4,80003a2e <ialloc+0x32>
  panic("ialloc: no inodes");
    80003a70:	00005517          	auipc	a0,0x5
    80003a74:	bc850513          	addi	a0,a0,-1080 # 80008638 <syscalls+0x168>
    80003a78:	ffffd097          	auipc	ra,0xffffd
    80003a7c:	ac6080e7          	jalr	-1338(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003a80:	04000613          	li	a2,64
    80003a84:	4581                	li	a1,0
    80003a86:	854e                	mv	a0,s3
    80003a88:	ffffd097          	auipc	ra,0xffffd
    80003a8c:	258080e7          	jalr	600(ra) # 80000ce0 <memset>
      dip->type = type;
    80003a90:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a94:	854a                	mv	a0,s2
    80003a96:	00001097          	auipc	ra,0x1
    80003a9a:	ca8080e7          	jalr	-856(ra) # 8000473e <log_write>
      brelse(bp);
    80003a9e:	854a                	mv	a0,s2
    80003aa0:	00000097          	auipc	ra,0x0
    80003aa4:	a22080e7          	jalr	-1502(ra) # 800034c2 <brelse>
      return iget(dev, inum);
    80003aa8:	85da                	mv	a1,s6
    80003aaa:	8556                	mv	a0,s5
    80003aac:	00000097          	auipc	ra,0x0
    80003ab0:	db4080e7          	jalr	-588(ra) # 80003860 <iget>
}
    80003ab4:	60a6                	ld	ra,72(sp)
    80003ab6:	6406                	ld	s0,64(sp)
    80003ab8:	74e2                	ld	s1,56(sp)
    80003aba:	7942                	ld	s2,48(sp)
    80003abc:	79a2                	ld	s3,40(sp)
    80003abe:	7a02                	ld	s4,32(sp)
    80003ac0:	6ae2                	ld	s5,24(sp)
    80003ac2:	6b42                	ld	s6,16(sp)
    80003ac4:	6ba2                	ld	s7,8(sp)
    80003ac6:	6161                	addi	sp,sp,80
    80003ac8:	8082                	ret

0000000080003aca <iupdate>:
{
    80003aca:	1101                	addi	sp,sp,-32
    80003acc:	ec06                	sd	ra,24(sp)
    80003ace:	e822                	sd	s0,16(sp)
    80003ad0:	e426                	sd	s1,8(sp)
    80003ad2:	e04a                	sd	s2,0(sp)
    80003ad4:	1000                	addi	s0,sp,32
    80003ad6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ad8:	415c                	lw	a5,4(a0)
    80003ada:	0047d79b          	srliw	a5,a5,0x4
    80003ade:	0001d597          	auipc	a1,0x1d
    80003ae2:	8225a583          	lw	a1,-2014(a1) # 80020300 <sb+0x18>
    80003ae6:	9dbd                	addw	a1,a1,a5
    80003ae8:	4108                	lw	a0,0(a0)
    80003aea:	00000097          	auipc	ra,0x0
    80003aee:	8a8080e7          	jalr	-1880(ra) # 80003392 <bread>
    80003af2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003af4:	05850793          	addi	a5,a0,88
    80003af8:	40c8                	lw	a0,4(s1)
    80003afa:	893d                	andi	a0,a0,15
    80003afc:	051a                	slli	a0,a0,0x6
    80003afe:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003b00:	04449703          	lh	a4,68(s1)
    80003b04:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b08:	04649703          	lh	a4,70(s1)
    80003b0c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003b10:	04849703          	lh	a4,72(s1)
    80003b14:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b18:	04a49703          	lh	a4,74(s1)
    80003b1c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b20:	44f8                	lw	a4,76(s1)
    80003b22:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b24:	03400613          	li	a2,52
    80003b28:	05048593          	addi	a1,s1,80
    80003b2c:	0531                	addi	a0,a0,12
    80003b2e:	ffffd097          	auipc	ra,0xffffd
    80003b32:	212080e7          	jalr	530(ra) # 80000d40 <memmove>
  log_write(bp);
    80003b36:	854a                	mv	a0,s2
    80003b38:	00001097          	auipc	ra,0x1
    80003b3c:	c06080e7          	jalr	-1018(ra) # 8000473e <log_write>
  brelse(bp);
    80003b40:	854a                	mv	a0,s2
    80003b42:	00000097          	auipc	ra,0x0
    80003b46:	980080e7          	jalr	-1664(ra) # 800034c2 <brelse>
}
    80003b4a:	60e2                	ld	ra,24(sp)
    80003b4c:	6442                	ld	s0,16(sp)
    80003b4e:	64a2                	ld	s1,8(sp)
    80003b50:	6902                	ld	s2,0(sp)
    80003b52:	6105                	addi	sp,sp,32
    80003b54:	8082                	ret

0000000080003b56 <idup>:
{
    80003b56:	1101                	addi	sp,sp,-32
    80003b58:	ec06                	sd	ra,24(sp)
    80003b5a:	e822                	sd	s0,16(sp)
    80003b5c:	e426                	sd	s1,8(sp)
    80003b5e:	1000                	addi	s0,sp,32
    80003b60:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b62:	0001c517          	auipc	a0,0x1c
    80003b66:	7a650513          	addi	a0,a0,1958 # 80020308 <itable>
    80003b6a:	ffffd097          	auipc	ra,0xffffd
    80003b6e:	07a080e7          	jalr	122(ra) # 80000be4 <acquire>
  ip->ref++;
    80003b72:	449c                	lw	a5,8(s1)
    80003b74:	2785                	addiw	a5,a5,1
    80003b76:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b78:	0001c517          	auipc	a0,0x1c
    80003b7c:	79050513          	addi	a0,a0,1936 # 80020308 <itable>
    80003b80:	ffffd097          	auipc	ra,0xffffd
    80003b84:	118080e7          	jalr	280(ra) # 80000c98 <release>
}
    80003b88:	8526                	mv	a0,s1
    80003b8a:	60e2                	ld	ra,24(sp)
    80003b8c:	6442                	ld	s0,16(sp)
    80003b8e:	64a2                	ld	s1,8(sp)
    80003b90:	6105                	addi	sp,sp,32
    80003b92:	8082                	ret

0000000080003b94 <ilock>:
{
    80003b94:	1101                	addi	sp,sp,-32
    80003b96:	ec06                	sd	ra,24(sp)
    80003b98:	e822                	sd	s0,16(sp)
    80003b9a:	e426                	sd	s1,8(sp)
    80003b9c:	e04a                	sd	s2,0(sp)
    80003b9e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ba0:	c115                	beqz	a0,80003bc4 <ilock+0x30>
    80003ba2:	84aa                	mv	s1,a0
    80003ba4:	451c                	lw	a5,8(a0)
    80003ba6:	00f05f63          	blez	a5,80003bc4 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003baa:	0541                	addi	a0,a0,16
    80003bac:	00001097          	auipc	ra,0x1
    80003bb0:	cb2080e7          	jalr	-846(ra) # 8000485e <acquiresleep>
  if(ip->valid == 0){
    80003bb4:	40bc                	lw	a5,64(s1)
    80003bb6:	cf99                	beqz	a5,80003bd4 <ilock+0x40>
}
    80003bb8:	60e2                	ld	ra,24(sp)
    80003bba:	6442                	ld	s0,16(sp)
    80003bbc:	64a2                	ld	s1,8(sp)
    80003bbe:	6902                	ld	s2,0(sp)
    80003bc0:	6105                	addi	sp,sp,32
    80003bc2:	8082                	ret
    panic("ilock");
    80003bc4:	00005517          	auipc	a0,0x5
    80003bc8:	a8c50513          	addi	a0,a0,-1396 # 80008650 <syscalls+0x180>
    80003bcc:	ffffd097          	auipc	ra,0xffffd
    80003bd0:	972080e7          	jalr	-1678(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bd4:	40dc                	lw	a5,4(s1)
    80003bd6:	0047d79b          	srliw	a5,a5,0x4
    80003bda:	0001c597          	auipc	a1,0x1c
    80003bde:	7265a583          	lw	a1,1830(a1) # 80020300 <sb+0x18>
    80003be2:	9dbd                	addw	a1,a1,a5
    80003be4:	4088                	lw	a0,0(s1)
    80003be6:	fffff097          	auipc	ra,0xfffff
    80003bea:	7ac080e7          	jalr	1964(ra) # 80003392 <bread>
    80003bee:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bf0:	05850593          	addi	a1,a0,88
    80003bf4:	40dc                	lw	a5,4(s1)
    80003bf6:	8bbd                	andi	a5,a5,15
    80003bf8:	079a                	slli	a5,a5,0x6
    80003bfa:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003bfc:	00059783          	lh	a5,0(a1)
    80003c00:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c04:	00259783          	lh	a5,2(a1)
    80003c08:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c0c:	00459783          	lh	a5,4(a1)
    80003c10:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c14:	00659783          	lh	a5,6(a1)
    80003c18:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c1c:	459c                	lw	a5,8(a1)
    80003c1e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c20:	03400613          	li	a2,52
    80003c24:	05b1                	addi	a1,a1,12
    80003c26:	05048513          	addi	a0,s1,80
    80003c2a:	ffffd097          	auipc	ra,0xffffd
    80003c2e:	116080e7          	jalr	278(ra) # 80000d40 <memmove>
    brelse(bp);
    80003c32:	854a                	mv	a0,s2
    80003c34:	00000097          	auipc	ra,0x0
    80003c38:	88e080e7          	jalr	-1906(ra) # 800034c2 <brelse>
    ip->valid = 1;
    80003c3c:	4785                	li	a5,1
    80003c3e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c40:	04449783          	lh	a5,68(s1)
    80003c44:	fbb5                	bnez	a5,80003bb8 <ilock+0x24>
      panic("ilock: no type");
    80003c46:	00005517          	auipc	a0,0x5
    80003c4a:	a1250513          	addi	a0,a0,-1518 # 80008658 <syscalls+0x188>
    80003c4e:	ffffd097          	auipc	ra,0xffffd
    80003c52:	8f0080e7          	jalr	-1808(ra) # 8000053e <panic>

0000000080003c56 <iunlock>:
{
    80003c56:	1101                	addi	sp,sp,-32
    80003c58:	ec06                	sd	ra,24(sp)
    80003c5a:	e822                	sd	s0,16(sp)
    80003c5c:	e426                	sd	s1,8(sp)
    80003c5e:	e04a                	sd	s2,0(sp)
    80003c60:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c62:	c905                	beqz	a0,80003c92 <iunlock+0x3c>
    80003c64:	84aa                	mv	s1,a0
    80003c66:	01050913          	addi	s2,a0,16
    80003c6a:	854a                	mv	a0,s2
    80003c6c:	00001097          	auipc	ra,0x1
    80003c70:	c8c080e7          	jalr	-884(ra) # 800048f8 <holdingsleep>
    80003c74:	cd19                	beqz	a0,80003c92 <iunlock+0x3c>
    80003c76:	449c                	lw	a5,8(s1)
    80003c78:	00f05d63          	blez	a5,80003c92 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c7c:	854a                	mv	a0,s2
    80003c7e:	00001097          	auipc	ra,0x1
    80003c82:	c36080e7          	jalr	-970(ra) # 800048b4 <releasesleep>
}
    80003c86:	60e2                	ld	ra,24(sp)
    80003c88:	6442                	ld	s0,16(sp)
    80003c8a:	64a2                	ld	s1,8(sp)
    80003c8c:	6902                	ld	s2,0(sp)
    80003c8e:	6105                	addi	sp,sp,32
    80003c90:	8082                	ret
    panic("iunlock");
    80003c92:	00005517          	auipc	a0,0x5
    80003c96:	9d650513          	addi	a0,a0,-1578 # 80008668 <syscalls+0x198>
    80003c9a:	ffffd097          	auipc	ra,0xffffd
    80003c9e:	8a4080e7          	jalr	-1884(ra) # 8000053e <panic>

0000000080003ca2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ca2:	7179                	addi	sp,sp,-48
    80003ca4:	f406                	sd	ra,40(sp)
    80003ca6:	f022                	sd	s0,32(sp)
    80003ca8:	ec26                	sd	s1,24(sp)
    80003caa:	e84a                	sd	s2,16(sp)
    80003cac:	e44e                	sd	s3,8(sp)
    80003cae:	e052                	sd	s4,0(sp)
    80003cb0:	1800                	addi	s0,sp,48
    80003cb2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003cb4:	05050493          	addi	s1,a0,80
    80003cb8:	08050913          	addi	s2,a0,128
    80003cbc:	a021                	j	80003cc4 <itrunc+0x22>
    80003cbe:	0491                	addi	s1,s1,4
    80003cc0:	01248d63          	beq	s1,s2,80003cda <itrunc+0x38>
    if(ip->addrs[i]){
    80003cc4:	408c                	lw	a1,0(s1)
    80003cc6:	dde5                	beqz	a1,80003cbe <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003cc8:	0009a503          	lw	a0,0(s3)
    80003ccc:	00000097          	auipc	ra,0x0
    80003cd0:	90c080e7          	jalr	-1780(ra) # 800035d8 <bfree>
      ip->addrs[i] = 0;
    80003cd4:	0004a023          	sw	zero,0(s1)
    80003cd8:	b7dd                	j	80003cbe <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003cda:	0809a583          	lw	a1,128(s3)
    80003cde:	e185                	bnez	a1,80003cfe <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ce0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ce4:	854e                	mv	a0,s3
    80003ce6:	00000097          	auipc	ra,0x0
    80003cea:	de4080e7          	jalr	-540(ra) # 80003aca <iupdate>
}
    80003cee:	70a2                	ld	ra,40(sp)
    80003cf0:	7402                	ld	s0,32(sp)
    80003cf2:	64e2                	ld	s1,24(sp)
    80003cf4:	6942                	ld	s2,16(sp)
    80003cf6:	69a2                	ld	s3,8(sp)
    80003cf8:	6a02                	ld	s4,0(sp)
    80003cfa:	6145                	addi	sp,sp,48
    80003cfc:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003cfe:	0009a503          	lw	a0,0(s3)
    80003d02:	fffff097          	auipc	ra,0xfffff
    80003d06:	690080e7          	jalr	1680(ra) # 80003392 <bread>
    80003d0a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d0c:	05850493          	addi	s1,a0,88
    80003d10:	45850913          	addi	s2,a0,1112
    80003d14:	a811                	j	80003d28 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003d16:	0009a503          	lw	a0,0(s3)
    80003d1a:	00000097          	auipc	ra,0x0
    80003d1e:	8be080e7          	jalr	-1858(ra) # 800035d8 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003d22:	0491                	addi	s1,s1,4
    80003d24:	01248563          	beq	s1,s2,80003d2e <itrunc+0x8c>
      if(a[j])
    80003d28:	408c                	lw	a1,0(s1)
    80003d2a:	dde5                	beqz	a1,80003d22 <itrunc+0x80>
    80003d2c:	b7ed                	j	80003d16 <itrunc+0x74>
    brelse(bp);
    80003d2e:	8552                	mv	a0,s4
    80003d30:	fffff097          	auipc	ra,0xfffff
    80003d34:	792080e7          	jalr	1938(ra) # 800034c2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d38:	0809a583          	lw	a1,128(s3)
    80003d3c:	0009a503          	lw	a0,0(s3)
    80003d40:	00000097          	auipc	ra,0x0
    80003d44:	898080e7          	jalr	-1896(ra) # 800035d8 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d48:	0809a023          	sw	zero,128(s3)
    80003d4c:	bf51                	j	80003ce0 <itrunc+0x3e>

0000000080003d4e <iput>:
{
    80003d4e:	1101                	addi	sp,sp,-32
    80003d50:	ec06                	sd	ra,24(sp)
    80003d52:	e822                	sd	s0,16(sp)
    80003d54:	e426                	sd	s1,8(sp)
    80003d56:	e04a                	sd	s2,0(sp)
    80003d58:	1000                	addi	s0,sp,32
    80003d5a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d5c:	0001c517          	auipc	a0,0x1c
    80003d60:	5ac50513          	addi	a0,a0,1452 # 80020308 <itable>
    80003d64:	ffffd097          	auipc	ra,0xffffd
    80003d68:	e80080e7          	jalr	-384(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d6c:	4498                	lw	a4,8(s1)
    80003d6e:	4785                	li	a5,1
    80003d70:	02f70363          	beq	a4,a5,80003d96 <iput+0x48>
  ip->ref--;
    80003d74:	449c                	lw	a5,8(s1)
    80003d76:	37fd                	addiw	a5,a5,-1
    80003d78:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d7a:	0001c517          	auipc	a0,0x1c
    80003d7e:	58e50513          	addi	a0,a0,1422 # 80020308 <itable>
    80003d82:	ffffd097          	auipc	ra,0xffffd
    80003d86:	f16080e7          	jalr	-234(ra) # 80000c98 <release>
}
    80003d8a:	60e2                	ld	ra,24(sp)
    80003d8c:	6442                	ld	s0,16(sp)
    80003d8e:	64a2                	ld	s1,8(sp)
    80003d90:	6902                	ld	s2,0(sp)
    80003d92:	6105                	addi	sp,sp,32
    80003d94:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d96:	40bc                	lw	a5,64(s1)
    80003d98:	dff1                	beqz	a5,80003d74 <iput+0x26>
    80003d9a:	04a49783          	lh	a5,74(s1)
    80003d9e:	fbf9                	bnez	a5,80003d74 <iput+0x26>
    acquiresleep(&ip->lock);
    80003da0:	01048913          	addi	s2,s1,16
    80003da4:	854a                	mv	a0,s2
    80003da6:	00001097          	auipc	ra,0x1
    80003daa:	ab8080e7          	jalr	-1352(ra) # 8000485e <acquiresleep>
    release(&itable.lock);
    80003dae:	0001c517          	auipc	a0,0x1c
    80003db2:	55a50513          	addi	a0,a0,1370 # 80020308 <itable>
    80003db6:	ffffd097          	auipc	ra,0xffffd
    80003dba:	ee2080e7          	jalr	-286(ra) # 80000c98 <release>
    itrunc(ip);
    80003dbe:	8526                	mv	a0,s1
    80003dc0:	00000097          	auipc	ra,0x0
    80003dc4:	ee2080e7          	jalr	-286(ra) # 80003ca2 <itrunc>
    ip->type = 0;
    80003dc8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003dcc:	8526                	mv	a0,s1
    80003dce:	00000097          	auipc	ra,0x0
    80003dd2:	cfc080e7          	jalr	-772(ra) # 80003aca <iupdate>
    ip->valid = 0;
    80003dd6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003dda:	854a                	mv	a0,s2
    80003ddc:	00001097          	auipc	ra,0x1
    80003de0:	ad8080e7          	jalr	-1320(ra) # 800048b4 <releasesleep>
    acquire(&itable.lock);
    80003de4:	0001c517          	auipc	a0,0x1c
    80003de8:	52450513          	addi	a0,a0,1316 # 80020308 <itable>
    80003dec:	ffffd097          	auipc	ra,0xffffd
    80003df0:	df8080e7          	jalr	-520(ra) # 80000be4 <acquire>
    80003df4:	b741                	j	80003d74 <iput+0x26>

0000000080003df6 <iunlockput>:
{
    80003df6:	1101                	addi	sp,sp,-32
    80003df8:	ec06                	sd	ra,24(sp)
    80003dfa:	e822                	sd	s0,16(sp)
    80003dfc:	e426                	sd	s1,8(sp)
    80003dfe:	1000                	addi	s0,sp,32
    80003e00:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e02:	00000097          	auipc	ra,0x0
    80003e06:	e54080e7          	jalr	-428(ra) # 80003c56 <iunlock>
  iput(ip);
    80003e0a:	8526                	mv	a0,s1
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	f42080e7          	jalr	-190(ra) # 80003d4e <iput>
}
    80003e14:	60e2                	ld	ra,24(sp)
    80003e16:	6442                	ld	s0,16(sp)
    80003e18:	64a2                	ld	s1,8(sp)
    80003e1a:	6105                	addi	sp,sp,32
    80003e1c:	8082                	ret

0000000080003e1e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e1e:	1141                	addi	sp,sp,-16
    80003e20:	e422                	sd	s0,8(sp)
    80003e22:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e24:	411c                	lw	a5,0(a0)
    80003e26:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e28:	415c                	lw	a5,4(a0)
    80003e2a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e2c:	04451783          	lh	a5,68(a0)
    80003e30:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e34:	04a51783          	lh	a5,74(a0)
    80003e38:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e3c:	04c56783          	lwu	a5,76(a0)
    80003e40:	e99c                	sd	a5,16(a1)
}
    80003e42:	6422                	ld	s0,8(sp)
    80003e44:	0141                	addi	sp,sp,16
    80003e46:	8082                	ret

0000000080003e48 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e48:	457c                	lw	a5,76(a0)
    80003e4a:	0ed7e963          	bltu	a5,a3,80003f3c <readi+0xf4>
{
    80003e4e:	7159                	addi	sp,sp,-112
    80003e50:	f486                	sd	ra,104(sp)
    80003e52:	f0a2                	sd	s0,96(sp)
    80003e54:	eca6                	sd	s1,88(sp)
    80003e56:	e8ca                	sd	s2,80(sp)
    80003e58:	e4ce                	sd	s3,72(sp)
    80003e5a:	e0d2                	sd	s4,64(sp)
    80003e5c:	fc56                	sd	s5,56(sp)
    80003e5e:	f85a                	sd	s6,48(sp)
    80003e60:	f45e                	sd	s7,40(sp)
    80003e62:	f062                	sd	s8,32(sp)
    80003e64:	ec66                	sd	s9,24(sp)
    80003e66:	e86a                	sd	s10,16(sp)
    80003e68:	e46e                	sd	s11,8(sp)
    80003e6a:	1880                	addi	s0,sp,112
    80003e6c:	8baa                	mv	s7,a0
    80003e6e:	8c2e                	mv	s8,a1
    80003e70:	8ab2                	mv	s5,a2
    80003e72:	84b6                	mv	s1,a3
    80003e74:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e76:	9f35                	addw	a4,a4,a3
    return 0;
    80003e78:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e7a:	0ad76063          	bltu	a4,a3,80003f1a <readi+0xd2>
  if(off + n > ip->size)
    80003e7e:	00e7f463          	bgeu	a5,a4,80003e86 <readi+0x3e>
    n = ip->size - off;
    80003e82:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e86:	0a0b0963          	beqz	s6,80003f38 <readi+0xf0>
    80003e8a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e8c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e90:	5cfd                	li	s9,-1
    80003e92:	a82d                	j	80003ecc <readi+0x84>
    80003e94:	020a1d93          	slli	s11,s4,0x20
    80003e98:	020ddd93          	srli	s11,s11,0x20
    80003e9c:	05890613          	addi	a2,s2,88
    80003ea0:	86ee                	mv	a3,s11
    80003ea2:	963a                	add	a2,a2,a4
    80003ea4:	85d6                	mv	a1,s5
    80003ea6:	8562                	mv	a0,s8
    80003ea8:	fffff097          	auipc	ra,0xfffff
    80003eac:	a7a080e7          	jalr	-1414(ra) # 80002922 <either_copyout>
    80003eb0:	05950d63          	beq	a0,s9,80003f0a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003eb4:	854a                	mv	a0,s2
    80003eb6:	fffff097          	auipc	ra,0xfffff
    80003eba:	60c080e7          	jalr	1548(ra) # 800034c2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ebe:	013a09bb          	addw	s3,s4,s3
    80003ec2:	009a04bb          	addw	s1,s4,s1
    80003ec6:	9aee                	add	s5,s5,s11
    80003ec8:	0569f763          	bgeu	s3,s6,80003f16 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ecc:	000ba903          	lw	s2,0(s7)
    80003ed0:	00a4d59b          	srliw	a1,s1,0xa
    80003ed4:	855e                	mv	a0,s7
    80003ed6:	00000097          	auipc	ra,0x0
    80003eda:	8b0080e7          	jalr	-1872(ra) # 80003786 <bmap>
    80003ede:	0005059b          	sext.w	a1,a0
    80003ee2:	854a                	mv	a0,s2
    80003ee4:	fffff097          	auipc	ra,0xfffff
    80003ee8:	4ae080e7          	jalr	1198(ra) # 80003392 <bread>
    80003eec:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eee:	3ff4f713          	andi	a4,s1,1023
    80003ef2:	40ed07bb          	subw	a5,s10,a4
    80003ef6:	413b06bb          	subw	a3,s6,s3
    80003efa:	8a3e                	mv	s4,a5
    80003efc:	2781                	sext.w	a5,a5
    80003efe:	0006861b          	sext.w	a2,a3
    80003f02:	f8f679e3          	bgeu	a2,a5,80003e94 <readi+0x4c>
    80003f06:	8a36                	mv	s4,a3
    80003f08:	b771                	j	80003e94 <readi+0x4c>
      brelse(bp);
    80003f0a:	854a                	mv	a0,s2
    80003f0c:	fffff097          	auipc	ra,0xfffff
    80003f10:	5b6080e7          	jalr	1462(ra) # 800034c2 <brelse>
      tot = -1;
    80003f14:	59fd                	li	s3,-1
  }
  return tot;
    80003f16:	0009851b          	sext.w	a0,s3
}
    80003f1a:	70a6                	ld	ra,104(sp)
    80003f1c:	7406                	ld	s0,96(sp)
    80003f1e:	64e6                	ld	s1,88(sp)
    80003f20:	6946                	ld	s2,80(sp)
    80003f22:	69a6                	ld	s3,72(sp)
    80003f24:	6a06                	ld	s4,64(sp)
    80003f26:	7ae2                	ld	s5,56(sp)
    80003f28:	7b42                	ld	s6,48(sp)
    80003f2a:	7ba2                	ld	s7,40(sp)
    80003f2c:	7c02                	ld	s8,32(sp)
    80003f2e:	6ce2                	ld	s9,24(sp)
    80003f30:	6d42                	ld	s10,16(sp)
    80003f32:	6da2                	ld	s11,8(sp)
    80003f34:	6165                	addi	sp,sp,112
    80003f36:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f38:	89da                	mv	s3,s6
    80003f3a:	bff1                	j	80003f16 <readi+0xce>
    return 0;
    80003f3c:	4501                	li	a0,0
}
    80003f3e:	8082                	ret

0000000080003f40 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f40:	457c                	lw	a5,76(a0)
    80003f42:	10d7e863          	bltu	a5,a3,80004052 <writei+0x112>
{
    80003f46:	7159                	addi	sp,sp,-112
    80003f48:	f486                	sd	ra,104(sp)
    80003f4a:	f0a2                	sd	s0,96(sp)
    80003f4c:	eca6                	sd	s1,88(sp)
    80003f4e:	e8ca                	sd	s2,80(sp)
    80003f50:	e4ce                	sd	s3,72(sp)
    80003f52:	e0d2                	sd	s4,64(sp)
    80003f54:	fc56                	sd	s5,56(sp)
    80003f56:	f85a                	sd	s6,48(sp)
    80003f58:	f45e                	sd	s7,40(sp)
    80003f5a:	f062                	sd	s8,32(sp)
    80003f5c:	ec66                	sd	s9,24(sp)
    80003f5e:	e86a                	sd	s10,16(sp)
    80003f60:	e46e                	sd	s11,8(sp)
    80003f62:	1880                	addi	s0,sp,112
    80003f64:	8b2a                	mv	s6,a0
    80003f66:	8c2e                	mv	s8,a1
    80003f68:	8ab2                	mv	s5,a2
    80003f6a:	8936                	mv	s2,a3
    80003f6c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003f6e:	00e687bb          	addw	a5,a3,a4
    80003f72:	0ed7e263          	bltu	a5,a3,80004056 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f76:	00043737          	lui	a4,0x43
    80003f7a:	0ef76063          	bltu	a4,a5,8000405a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f7e:	0c0b8863          	beqz	s7,8000404e <writei+0x10e>
    80003f82:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f84:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f88:	5cfd                	li	s9,-1
    80003f8a:	a091                	j	80003fce <writei+0x8e>
    80003f8c:	02099d93          	slli	s11,s3,0x20
    80003f90:	020ddd93          	srli	s11,s11,0x20
    80003f94:	05848513          	addi	a0,s1,88
    80003f98:	86ee                	mv	a3,s11
    80003f9a:	8656                	mv	a2,s5
    80003f9c:	85e2                	mv	a1,s8
    80003f9e:	953a                	add	a0,a0,a4
    80003fa0:	fffff097          	auipc	ra,0xfffff
    80003fa4:	9d8080e7          	jalr	-1576(ra) # 80002978 <either_copyin>
    80003fa8:	07950263          	beq	a0,s9,8000400c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003fac:	8526                	mv	a0,s1
    80003fae:	00000097          	auipc	ra,0x0
    80003fb2:	790080e7          	jalr	1936(ra) # 8000473e <log_write>
    brelse(bp);
    80003fb6:	8526                	mv	a0,s1
    80003fb8:	fffff097          	auipc	ra,0xfffff
    80003fbc:	50a080e7          	jalr	1290(ra) # 800034c2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fc0:	01498a3b          	addw	s4,s3,s4
    80003fc4:	0129893b          	addw	s2,s3,s2
    80003fc8:	9aee                	add	s5,s5,s11
    80003fca:	057a7663          	bgeu	s4,s7,80004016 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fce:	000b2483          	lw	s1,0(s6)
    80003fd2:	00a9559b          	srliw	a1,s2,0xa
    80003fd6:	855a                	mv	a0,s6
    80003fd8:	fffff097          	auipc	ra,0xfffff
    80003fdc:	7ae080e7          	jalr	1966(ra) # 80003786 <bmap>
    80003fe0:	0005059b          	sext.w	a1,a0
    80003fe4:	8526                	mv	a0,s1
    80003fe6:	fffff097          	auipc	ra,0xfffff
    80003fea:	3ac080e7          	jalr	940(ra) # 80003392 <bread>
    80003fee:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ff0:	3ff97713          	andi	a4,s2,1023
    80003ff4:	40ed07bb          	subw	a5,s10,a4
    80003ff8:	414b86bb          	subw	a3,s7,s4
    80003ffc:	89be                	mv	s3,a5
    80003ffe:	2781                	sext.w	a5,a5
    80004000:	0006861b          	sext.w	a2,a3
    80004004:	f8f674e3          	bgeu	a2,a5,80003f8c <writei+0x4c>
    80004008:	89b6                	mv	s3,a3
    8000400a:	b749                	j	80003f8c <writei+0x4c>
      brelse(bp);
    8000400c:	8526                	mv	a0,s1
    8000400e:	fffff097          	auipc	ra,0xfffff
    80004012:	4b4080e7          	jalr	1204(ra) # 800034c2 <brelse>
  }

  if(off > ip->size)
    80004016:	04cb2783          	lw	a5,76(s6)
    8000401a:	0127f463          	bgeu	a5,s2,80004022 <writei+0xe2>
    ip->size = off;
    8000401e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004022:	855a                	mv	a0,s6
    80004024:	00000097          	auipc	ra,0x0
    80004028:	aa6080e7          	jalr	-1370(ra) # 80003aca <iupdate>

  return tot;
    8000402c:	000a051b          	sext.w	a0,s4
}
    80004030:	70a6                	ld	ra,104(sp)
    80004032:	7406                	ld	s0,96(sp)
    80004034:	64e6                	ld	s1,88(sp)
    80004036:	6946                	ld	s2,80(sp)
    80004038:	69a6                	ld	s3,72(sp)
    8000403a:	6a06                	ld	s4,64(sp)
    8000403c:	7ae2                	ld	s5,56(sp)
    8000403e:	7b42                	ld	s6,48(sp)
    80004040:	7ba2                	ld	s7,40(sp)
    80004042:	7c02                	ld	s8,32(sp)
    80004044:	6ce2                	ld	s9,24(sp)
    80004046:	6d42                	ld	s10,16(sp)
    80004048:	6da2                	ld	s11,8(sp)
    8000404a:	6165                	addi	sp,sp,112
    8000404c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000404e:	8a5e                	mv	s4,s7
    80004050:	bfc9                	j	80004022 <writei+0xe2>
    return -1;
    80004052:	557d                	li	a0,-1
}
    80004054:	8082                	ret
    return -1;
    80004056:	557d                	li	a0,-1
    80004058:	bfe1                	j	80004030 <writei+0xf0>
    return -1;
    8000405a:	557d                	li	a0,-1
    8000405c:	bfd1                	j	80004030 <writei+0xf0>

000000008000405e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000405e:	1141                	addi	sp,sp,-16
    80004060:	e406                	sd	ra,8(sp)
    80004062:	e022                	sd	s0,0(sp)
    80004064:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004066:	4639                	li	a2,14
    80004068:	ffffd097          	auipc	ra,0xffffd
    8000406c:	d50080e7          	jalr	-688(ra) # 80000db8 <strncmp>
}
    80004070:	60a2                	ld	ra,8(sp)
    80004072:	6402                	ld	s0,0(sp)
    80004074:	0141                	addi	sp,sp,16
    80004076:	8082                	ret

0000000080004078 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004078:	7139                	addi	sp,sp,-64
    8000407a:	fc06                	sd	ra,56(sp)
    8000407c:	f822                	sd	s0,48(sp)
    8000407e:	f426                	sd	s1,40(sp)
    80004080:	f04a                	sd	s2,32(sp)
    80004082:	ec4e                	sd	s3,24(sp)
    80004084:	e852                	sd	s4,16(sp)
    80004086:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004088:	04451703          	lh	a4,68(a0)
    8000408c:	4785                	li	a5,1
    8000408e:	00f71a63          	bne	a4,a5,800040a2 <dirlookup+0x2a>
    80004092:	892a                	mv	s2,a0
    80004094:	89ae                	mv	s3,a1
    80004096:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004098:	457c                	lw	a5,76(a0)
    8000409a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000409c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000409e:	e79d                	bnez	a5,800040cc <dirlookup+0x54>
    800040a0:	a8a5                	j	80004118 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800040a2:	00004517          	auipc	a0,0x4
    800040a6:	5ce50513          	addi	a0,a0,1486 # 80008670 <syscalls+0x1a0>
    800040aa:	ffffc097          	auipc	ra,0xffffc
    800040ae:	494080e7          	jalr	1172(ra) # 8000053e <panic>
      panic("dirlookup read");
    800040b2:	00004517          	auipc	a0,0x4
    800040b6:	5d650513          	addi	a0,a0,1494 # 80008688 <syscalls+0x1b8>
    800040ba:	ffffc097          	auipc	ra,0xffffc
    800040be:	484080e7          	jalr	1156(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040c2:	24c1                	addiw	s1,s1,16
    800040c4:	04c92783          	lw	a5,76(s2)
    800040c8:	04f4f763          	bgeu	s1,a5,80004116 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040cc:	4741                	li	a4,16
    800040ce:	86a6                	mv	a3,s1
    800040d0:	fc040613          	addi	a2,s0,-64
    800040d4:	4581                	li	a1,0
    800040d6:	854a                	mv	a0,s2
    800040d8:	00000097          	auipc	ra,0x0
    800040dc:	d70080e7          	jalr	-656(ra) # 80003e48 <readi>
    800040e0:	47c1                	li	a5,16
    800040e2:	fcf518e3          	bne	a0,a5,800040b2 <dirlookup+0x3a>
    if(de.inum == 0)
    800040e6:	fc045783          	lhu	a5,-64(s0)
    800040ea:	dfe1                	beqz	a5,800040c2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040ec:	fc240593          	addi	a1,s0,-62
    800040f0:	854e                	mv	a0,s3
    800040f2:	00000097          	auipc	ra,0x0
    800040f6:	f6c080e7          	jalr	-148(ra) # 8000405e <namecmp>
    800040fa:	f561                	bnez	a0,800040c2 <dirlookup+0x4a>
      if(poff)
    800040fc:	000a0463          	beqz	s4,80004104 <dirlookup+0x8c>
        *poff = off;
    80004100:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004104:	fc045583          	lhu	a1,-64(s0)
    80004108:	00092503          	lw	a0,0(s2)
    8000410c:	fffff097          	auipc	ra,0xfffff
    80004110:	754080e7          	jalr	1876(ra) # 80003860 <iget>
    80004114:	a011                	j	80004118 <dirlookup+0xa0>
  return 0;
    80004116:	4501                	li	a0,0
}
    80004118:	70e2                	ld	ra,56(sp)
    8000411a:	7442                	ld	s0,48(sp)
    8000411c:	74a2                	ld	s1,40(sp)
    8000411e:	7902                	ld	s2,32(sp)
    80004120:	69e2                	ld	s3,24(sp)
    80004122:	6a42                	ld	s4,16(sp)
    80004124:	6121                	addi	sp,sp,64
    80004126:	8082                	ret

0000000080004128 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004128:	711d                	addi	sp,sp,-96
    8000412a:	ec86                	sd	ra,88(sp)
    8000412c:	e8a2                	sd	s0,80(sp)
    8000412e:	e4a6                	sd	s1,72(sp)
    80004130:	e0ca                	sd	s2,64(sp)
    80004132:	fc4e                	sd	s3,56(sp)
    80004134:	f852                	sd	s4,48(sp)
    80004136:	f456                	sd	s5,40(sp)
    80004138:	f05a                	sd	s6,32(sp)
    8000413a:	ec5e                	sd	s7,24(sp)
    8000413c:	e862                	sd	s8,16(sp)
    8000413e:	e466                	sd	s9,8(sp)
    80004140:	1080                	addi	s0,sp,96
    80004142:	84aa                	mv	s1,a0
    80004144:	8b2e                	mv	s6,a1
    80004146:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004148:	00054703          	lbu	a4,0(a0)
    8000414c:	02f00793          	li	a5,47
    80004150:	02f70363          	beq	a4,a5,80004176 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004154:	ffffe097          	auipc	ra,0xffffe
    80004158:	b7a080e7          	jalr	-1158(ra) # 80001cce <myproc>
    8000415c:	15053503          	ld	a0,336(a0)
    80004160:	00000097          	auipc	ra,0x0
    80004164:	9f6080e7          	jalr	-1546(ra) # 80003b56 <idup>
    80004168:	89aa                	mv	s3,a0
  while(*path == '/')
    8000416a:	02f00913          	li	s2,47
  len = path - s;
    8000416e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004170:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004172:	4c05                	li	s8,1
    80004174:	a865                	j	8000422c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004176:	4585                	li	a1,1
    80004178:	4505                	li	a0,1
    8000417a:	fffff097          	auipc	ra,0xfffff
    8000417e:	6e6080e7          	jalr	1766(ra) # 80003860 <iget>
    80004182:	89aa                	mv	s3,a0
    80004184:	b7dd                	j	8000416a <namex+0x42>
      iunlockput(ip);
    80004186:	854e                	mv	a0,s3
    80004188:	00000097          	auipc	ra,0x0
    8000418c:	c6e080e7          	jalr	-914(ra) # 80003df6 <iunlockput>
      return 0;
    80004190:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004192:	854e                	mv	a0,s3
    80004194:	60e6                	ld	ra,88(sp)
    80004196:	6446                	ld	s0,80(sp)
    80004198:	64a6                	ld	s1,72(sp)
    8000419a:	6906                	ld	s2,64(sp)
    8000419c:	79e2                	ld	s3,56(sp)
    8000419e:	7a42                	ld	s4,48(sp)
    800041a0:	7aa2                	ld	s5,40(sp)
    800041a2:	7b02                	ld	s6,32(sp)
    800041a4:	6be2                	ld	s7,24(sp)
    800041a6:	6c42                	ld	s8,16(sp)
    800041a8:	6ca2                	ld	s9,8(sp)
    800041aa:	6125                	addi	sp,sp,96
    800041ac:	8082                	ret
      iunlock(ip);
    800041ae:	854e                	mv	a0,s3
    800041b0:	00000097          	auipc	ra,0x0
    800041b4:	aa6080e7          	jalr	-1370(ra) # 80003c56 <iunlock>
      return ip;
    800041b8:	bfe9                	j	80004192 <namex+0x6a>
      iunlockput(ip);
    800041ba:	854e                	mv	a0,s3
    800041bc:	00000097          	auipc	ra,0x0
    800041c0:	c3a080e7          	jalr	-966(ra) # 80003df6 <iunlockput>
      return 0;
    800041c4:	89d2                	mv	s3,s4
    800041c6:	b7f1                	j	80004192 <namex+0x6a>
  len = path - s;
    800041c8:	40b48633          	sub	a2,s1,a1
    800041cc:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800041d0:	094cd463          	bge	s9,s4,80004258 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800041d4:	4639                	li	a2,14
    800041d6:	8556                	mv	a0,s5
    800041d8:	ffffd097          	auipc	ra,0xffffd
    800041dc:	b68080e7          	jalr	-1176(ra) # 80000d40 <memmove>
  while(*path == '/')
    800041e0:	0004c783          	lbu	a5,0(s1)
    800041e4:	01279763          	bne	a5,s2,800041f2 <namex+0xca>
    path++;
    800041e8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041ea:	0004c783          	lbu	a5,0(s1)
    800041ee:	ff278de3          	beq	a5,s2,800041e8 <namex+0xc0>
    ilock(ip);
    800041f2:	854e                	mv	a0,s3
    800041f4:	00000097          	auipc	ra,0x0
    800041f8:	9a0080e7          	jalr	-1632(ra) # 80003b94 <ilock>
    if(ip->type != T_DIR){
    800041fc:	04499783          	lh	a5,68(s3)
    80004200:	f98793e3          	bne	a5,s8,80004186 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004204:	000b0563          	beqz	s6,8000420e <namex+0xe6>
    80004208:	0004c783          	lbu	a5,0(s1)
    8000420c:	d3cd                	beqz	a5,800041ae <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000420e:	865e                	mv	a2,s7
    80004210:	85d6                	mv	a1,s5
    80004212:	854e                	mv	a0,s3
    80004214:	00000097          	auipc	ra,0x0
    80004218:	e64080e7          	jalr	-412(ra) # 80004078 <dirlookup>
    8000421c:	8a2a                	mv	s4,a0
    8000421e:	dd51                	beqz	a0,800041ba <namex+0x92>
    iunlockput(ip);
    80004220:	854e                	mv	a0,s3
    80004222:	00000097          	auipc	ra,0x0
    80004226:	bd4080e7          	jalr	-1068(ra) # 80003df6 <iunlockput>
    ip = next;
    8000422a:	89d2                	mv	s3,s4
  while(*path == '/')
    8000422c:	0004c783          	lbu	a5,0(s1)
    80004230:	05279763          	bne	a5,s2,8000427e <namex+0x156>
    path++;
    80004234:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004236:	0004c783          	lbu	a5,0(s1)
    8000423a:	ff278de3          	beq	a5,s2,80004234 <namex+0x10c>
  if(*path == 0)
    8000423e:	c79d                	beqz	a5,8000426c <namex+0x144>
    path++;
    80004240:	85a6                	mv	a1,s1
  len = path - s;
    80004242:	8a5e                	mv	s4,s7
    80004244:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004246:	01278963          	beq	a5,s2,80004258 <namex+0x130>
    8000424a:	dfbd                	beqz	a5,800041c8 <namex+0xa0>
    path++;
    8000424c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000424e:	0004c783          	lbu	a5,0(s1)
    80004252:	ff279ce3          	bne	a5,s2,8000424a <namex+0x122>
    80004256:	bf8d                	j	800041c8 <namex+0xa0>
    memmove(name, s, len);
    80004258:	2601                	sext.w	a2,a2
    8000425a:	8556                	mv	a0,s5
    8000425c:	ffffd097          	auipc	ra,0xffffd
    80004260:	ae4080e7          	jalr	-1308(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004264:	9a56                	add	s4,s4,s5
    80004266:	000a0023          	sb	zero,0(s4)
    8000426a:	bf9d                	j	800041e0 <namex+0xb8>
  if(nameiparent){
    8000426c:	f20b03e3          	beqz	s6,80004192 <namex+0x6a>
    iput(ip);
    80004270:	854e                	mv	a0,s3
    80004272:	00000097          	auipc	ra,0x0
    80004276:	adc080e7          	jalr	-1316(ra) # 80003d4e <iput>
    return 0;
    8000427a:	4981                	li	s3,0
    8000427c:	bf19                	j	80004192 <namex+0x6a>
  if(*path == 0)
    8000427e:	d7fd                	beqz	a5,8000426c <namex+0x144>
  while(*path != '/' && *path != 0)
    80004280:	0004c783          	lbu	a5,0(s1)
    80004284:	85a6                	mv	a1,s1
    80004286:	b7d1                	j	8000424a <namex+0x122>

0000000080004288 <dirlink>:
{
    80004288:	7139                	addi	sp,sp,-64
    8000428a:	fc06                	sd	ra,56(sp)
    8000428c:	f822                	sd	s0,48(sp)
    8000428e:	f426                	sd	s1,40(sp)
    80004290:	f04a                	sd	s2,32(sp)
    80004292:	ec4e                	sd	s3,24(sp)
    80004294:	e852                	sd	s4,16(sp)
    80004296:	0080                	addi	s0,sp,64
    80004298:	892a                	mv	s2,a0
    8000429a:	8a2e                	mv	s4,a1
    8000429c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000429e:	4601                	li	a2,0
    800042a0:	00000097          	auipc	ra,0x0
    800042a4:	dd8080e7          	jalr	-552(ra) # 80004078 <dirlookup>
    800042a8:	e93d                	bnez	a0,8000431e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042aa:	04c92483          	lw	s1,76(s2)
    800042ae:	c49d                	beqz	s1,800042dc <dirlink+0x54>
    800042b0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042b2:	4741                	li	a4,16
    800042b4:	86a6                	mv	a3,s1
    800042b6:	fc040613          	addi	a2,s0,-64
    800042ba:	4581                	li	a1,0
    800042bc:	854a                	mv	a0,s2
    800042be:	00000097          	auipc	ra,0x0
    800042c2:	b8a080e7          	jalr	-1142(ra) # 80003e48 <readi>
    800042c6:	47c1                	li	a5,16
    800042c8:	06f51163          	bne	a0,a5,8000432a <dirlink+0xa2>
    if(de.inum == 0)
    800042cc:	fc045783          	lhu	a5,-64(s0)
    800042d0:	c791                	beqz	a5,800042dc <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042d2:	24c1                	addiw	s1,s1,16
    800042d4:	04c92783          	lw	a5,76(s2)
    800042d8:	fcf4ede3          	bltu	s1,a5,800042b2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042dc:	4639                	li	a2,14
    800042de:	85d2                	mv	a1,s4
    800042e0:	fc240513          	addi	a0,s0,-62
    800042e4:	ffffd097          	auipc	ra,0xffffd
    800042e8:	b10080e7          	jalr	-1264(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800042ec:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042f0:	4741                	li	a4,16
    800042f2:	86a6                	mv	a3,s1
    800042f4:	fc040613          	addi	a2,s0,-64
    800042f8:	4581                	li	a1,0
    800042fa:	854a                	mv	a0,s2
    800042fc:	00000097          	auipc	ra,0x0
    80004300:	c44080e7          	jalr	-956(ra) # 80003f40 <writei>
    80004304:	872a                	mv	a4,a0
    80004306:	47c1                	li	a5,16
  return 0;
    80004308:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000430a:	02f71863          	bne	a4,a5,8000433a <dirlink+0xb2>
}
    8000430e:	70e2                	ld	ra,56(sp)
    80004310:	7442                	ld	s0,48(sp)
    80004312:	74a2                	ld	s1,40(sp)
    80004314:	7902                	ld	s2,32(sp)
    80004316:	69e2                	ld	s3,24(sp)
    80004318:	6a42                	ld	s4,16(sp)
    8000431a:	6121                	addi	sp,sp,64
    8000431c:	8082                	ret
    iput(ip);
    8000431e:	00000097          	auipc	ra,0x0
    80004322:	a30080e7          	jalr	-1488(ra) # 80003d4e <iput>
    return -1;
    80004326:	557d                	li	a0,-1
    80004328:	b7dd                	j	8000430e <dirlink+0x86>
      panic("dirlink read");
    8000432a:	00004517          	auipc	a0,0x4
    8000432e:	36e50513          	addi	a0,a0,878 # 80008698 <syscalls+0x1c8>
    80004332:	ffffc097          	auipc	ra,0xffffc
    80004336:	20c080e7          	jalr	524(ra) # 8000053e <panic>
    panic("dirlink");
    8000433a:	00004517          	auipc	a0,0x4
    8000433e:	46e50513          	addi	a0,a0,1134 # 800087a8 <syscalls+0x2d8>
    80004342:	ffffc097          	auipc	ra,0xffffc
    80004346:	1fc080e7          	jalr	508(ra) # 8000053e <panic>

000000008000434a <namei>:

struct inode*
namei(char *path)
{
    8000434a:	1101                	addi	sp,sp,-32
    8000434c:	ec06                	sd	ra,24(sp)
    8000434e:	e822                	sd	s0,16(sp)
    80004350:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004352:	fe040613          	addi	a2,s0,-32
    80004356:	4581                	li	a1,0
    80004358:	00000097          	auipc	ra,0x0
    8000435c:	dd0080e7          	jalr	-560(ra) # 80004128 <namex>
}
    80004360:	60e2                	ld	ra,24(sp)
    80004362:	6442                	ld	s0,16(sp)
    80004364:	6105                	addi	sp,sp,32
    80004366:	8082                	ret

0000000080004368 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004368:	1141                	addi	sp,sp,-16
    8000436a:	e406                	sd	ra,8(sp)
    8000436c:	e022                	sd	s0,0(sp)
    8000436e:	0800                	addi	s0,sp,16
    80004370:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004372:	4585                	li	a1,1
    80004374:	00000097          	auipc	ra,0x0
    80004378:	db4080e7          	jalr	-588(ra) # 80004128 <namex>
}
    8000437c:	60a2                	ld	ra,8(sp)
    8000437e:	6402                	ld	s0,0(sp)
    80004380:	0141                	addi	sp,sp,16
    80004382:	8082                	ret

0000000080004384 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004384:	1101                	addi	sp,sp,-32
    80004386:	ec06                	sd	ra,24(sp)
    80004388:	e822                	sd	s0,16(sp)
    8000438a:	e426                	sd	s1,8(sp)
    8000438c:	e04a                	sd	s2,0(sp)
    8000438e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004390:	0001e917          	auipc	s2,0x1e
    80004394:	a2090913          	addi	s2,s2,-1504 # 80021db0 <log>
    80004398:	01892583          	lw	a1,24(s2)
    8000439c:	02892503          	lw	a0,40(s2)
    800043a0:	fffff097          	auipc	ra,0xfffff
    800043a4:	ff2080e7          	jalr	-14(ra) # 80003392 <bread>
    800043a8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800043aa:	02c92683          	lw	a3,44(s2)
    800043ae:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800043b0:	02d05763          	blez	a3,800043de <write_head+0x5a>
    800043b4:	0001e797          	auipc	a5,0x1e
    800043b8:	a2c78793          	addi	a5,a5,-1492 # 80021de0 <log+0x30>
    800043bc:	05c50713          	addi	a4,a0,92
    800043c0:	36fd                	addiw	a3,a3,-1
    800043c2:	1682                	slli	a3,a3,0x20
    800043c4:	9281                	srli	a3,a3,0x20
    800043c6:	068a                	slli	a3,a3,0x2
    800043c8:	0001e617          	auipc	a2,0x1e
    800043cc:	a1c60613          	addi	a2,a2,-1508 # 80021de4 <log+0x34>
    800043d0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800043d2:	4390                	lw	a2,0(a5)
    800043d4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043d6:	0791                	addi	a5,a5,4
    800043d8:	0711                	addi	a4,a4,4
    800043da:	fed79ce3          	bne	a5,a3,800043d2 <write_head+0x4e>
  }
  bwrite(buf);
    800043de:	8526                	mv	a0,s1
    800043e0:	fffff097          	auipc	ra,0xfffff
    800043e4:	0a4080e7          	jalr	164(ra) # 80003484 <bwrite>
  brelse(buf);
    800043e8:	8526                	mv	a0,s1
    800043ea:	fffff097          	auipc	ra,0xfffff
    800043ee:	0d8080e7          	jalr	216(ra) # 800034c2 <brelse>
}
    800043f2:	60e2                	ld	ra,24(sp)
    800043f4:	6442                	ld	s0,16(sp)
    800043f6:	64a2                	ld	s1,8(sp)
    800043f8:	6902                	ld	s2,0(sp)
    800043fa:	6105                	addi	sp,sp,32
    800043fc:	8082                	ret

00000000800043fe <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043fe:	0001e797          	auipc	a5,0x1e
    80004402:	9de7a783          	lw	a5,-1570(a5) # 80021ddc <log+0x2c>
    80004406:	0af05d63          	blez	a5,800044c0 <install_trans+0xc2>
{
    8000440a:	7139                	addi	sp,sp,-64
    8000440c:	fc06                	sd	ra,56(sp)
    8000440e:	f822                	sd	s0,48(sp)
    80004410:	f426                	sd	s1,40(sp)
    80004412:	f04a                	sd	s2,32(sp)
    80004414:	ec4e                	sd	s3,24(sp)
    80004416:	e852                	sd	s4,16(sp)
    80004418:	e456                	sd	s5,8(sp)
    8000441a:	e05a                	sd	s6,0(sp)
    8000441c:	0080                	addi	s0,sp,64
    8000441e:	8b2a                	mv	s6,a0
    80004420:	0001ea97          	auipc	s5,0x1e
    80004424:	9c0a8a93          	addi	s5,s5,-1600 # 80021de0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004428:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000442a:	0001e997          	auipc	s3,0x1e
    8000442e:	98698993          	addi	s3,s3,-1658 # 80021db0 <log>
    80004432:	a035                	j	8000445e <install_trans+0x60>
      bunpin(dbuf);
    80004434:	8526                	mv	a0,s1
    80004436:	fffff097          	auipc	ra,0xfffff
    8000443a:	166080e7          	jalr	358(ra) # 8000359c <bunpin>
    brelse(lbuf);
    8000443e:	854a                	mv	a0,s2
    80004440:	fffff097          	auipc	ra,0xfffff
    80004444:	082080e7          	jalr	130(ra) # 800034c2 <brelse>
    brelse(dbuf);
    80004448:	8526                	mv	a0,s1
    8000444a:	fffff097          	auipc	ra,0xfffff
    8000444e:	078080e7          	jalr	120(ra) # 800034c2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004452:	2a05                	addiw	s4,s4,1
    80004454:	0a91                	addi	s5,s5,4
    80004456:	02c9a783          	lw	a5,44(s3)
    8000445a:	04fa5963          	bge	s4,a5,800044ac <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000445e:	0189a583          	lw	a1,24(s3)
    80004462:	014585bb          	addw	a1,a1,s4
    80004466:	2585                	addiw	a1,a1,1
    80004468:	0289a503          	lw	a0,40(s3)
    8000446c:	fffff097          	auipc	ra,0xfffff
    80004470:	f26080e7          	jalr	-218(ra) # 80003392 <bread>
    80004474:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004476:	000aa583          	lw	a1,0(s5)
    8000447a:	0289a503          	lw	a0,40(s3)
    8000447e:	fffff097          	auipc	ra,0xfffff
    80004482:	f14080e7          	jalr	-236(ra) # 80003392 <bread>
    80004486:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004488:	40000613          	li	a2,1024
    8000448c:	05890593          	addi	a1,s2,88
    80004490:	05850513          	addi	a0,a0,88
    80004494:	ffffd097          	auipc	ra,0xffffd
    80004498:	8ac080e7          	jalr	-1876(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000449c:	8526                	mv	a0,s1
    8000449e:	fffff097          	auipc	ra,0xfffff
    800044a2:	fe6080e7          	jalr	-26(ra) # 80003484 <bwrite>
    if(recovering == 0)
    800044a6:	f80b1ce3          	bnez	s6,8000443e <install_trans+0x40>
    800044aa:	b769                	j	80004434 <install_trans+0x36>
}
    800044ac:	70e2                	ld	ra,56(sp)
    800044ae:	7442                	ld	s0,48(sp)
    800044b0:	74a2                	ld	s1,40(sp)
    800044b2:	7902                	ld	s2,32(sp)
    800044b4:	69e2                	ld	s3,24(sp)
    800044b6:	6a42                	ld	s4,16(sp)
    800044b8:	6aa2                	ld	s5,8(sp)
    800044ba:	6b02                	ld	s6,0(sp)
    800044bc:	6121                	addi	sp,sp,64
    800044be:	8082                	ret
    800044c0:	8082                	ret

00000000800044c2 <initlog>:
{
    800044c2:	7179                	addi	sp,sp,-48
    800044c4:	f406                	sd	ra,40(sp)
    800044c6:	f022                	sd	s0,32(sp)
    800044c8:	ec26                	sd	s1,24(sp)
    800044ca:	e84a                	sd	s2,16(sp)
    800044cc:	e44e                	sd	s3,8(sp)
    800044ce:	1800                	addi	s0,sp,48
    800044d0:	892a                	mv	s2,a0
    800044d2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044d4:	0001e497          	auipc	s1,0x1e
    800044d8:	8dc48493          	addi	s1,s1,-1828 # 80021db0 <log>
    800044dc:	00004597          	auipc	a1,0x4
    800044e0:	1cc58593          	addi	a1,a1,460 # 800086a8 <syscalls+0x1d8>
    800044e4:	8526                	mv	a0,s1
    800044e6:	ffffc097          	auipc	ra,0xffffc
    800044ea:	66e080e7          	jalr	1646(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800044ee:	0149a583          	lw	a1,20(s3)
    800044f2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800044f4:	0109a783          	lw	a5,16(s3)
    800044f8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044fa:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044fe:	854a                	mv	a0,s2
    80004500:	fffff097          	auipc	ra,0xfffff
    80004504:	e92080e7          	jalr	-366(ra) # 80003392 <bread>
  log.lh.n = lh->n;
    80004508:	4d3c                	lw	a5,88(a0)
    8000450a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000450c:	02f05563          	blez	a5,80004536 <initlog+0x74>
    80004510:	05c50713          	addi	a4,a0,92
    80004514:	0001e697          	auipc	a3,0x1e
    80004518:	8cc68693          	addi	a3,a3,-1844 # 80021de0 <log+0x30>
    8000451c:	37fd                	addiw	a5,a5,-1
    8000451e:	1782                	slli	a5,a5,0x20
    80004520:	9381                	srli	a5,a5,0x20
    80004522:	078a                	slli	a5,a5,0x2
    80004524:	06050613          	addi	a2,a0,96
    80004528:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000452a:	4310                	lw	a2,0(a4)
    8000452c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000452e:	0711                	addi	a4,a4,4
    80004530:	0691                	addi	a3,a3,4
    80004532:	fef71ce3          	bne	a4,a5,8000452a <initlog+0x68>
  brelse(buf);
    80004536:	fffff097          	auipc	ra,0xfffff
    8000453a:	f8c080e7          	jalr	-116(ra) # 800034c2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000453e:	4505                	li	a0,1
    80004540:	00000097          	auipc	ra,0x0
    80004544:	ebe080e7          	jalr	-322(ra) # 800043fe <install_trans>
  log.lh.n = 0;
    80004548:	0001e797          	auipc	a5,0x1e
    8000454c:	8807aa23          	sw	zero,-1900(a5) # 80021ddc <log+0x2c>
  write_head(); // clear the log
    80004550:	00000097          	auipc	ra,0x0
    80004554:	e34080e7          	jalr	-460(ra) # 80004384 <write_head>
}
    80004558:	70a2                	ld	ra,40(sp)
    8000455a:	7402                	ld	s0,32(sp)
    8000455c:	64e2                	ld	s1,24(sp)
    8000455e:	6942                	ld	s2,16(sp)
    80004560:	69a2                	ld	s3,8(sp)
    80004562:	6145                	addi	sp,sp,48
    80004564:	8082                	ret

0000000080004566 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004566:	1101                	addi	sp,sp,-32
    80004568:	ec06                	sd	ra,24(sp)
    8000456a:	e822                	sd	s0,16(sp)
    8000456c:	e426                	sd	s1,8(sp)
    8000456e:	e04a                	sd	s2,0(sp)
    80004570:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004572:	0001e517          	auipc	a0,0x1e
    80004576:	83e50513          	addi	a0,a0,-1986 # 80021db0 <log>
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	66a080e7          	jalr	1642(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004582:	0001e497          	auipc	s1,0x1e
    80004586:	82e48493          	addi	s1,s1,-2002 # 80021db0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000458a:	4979                	li	s2,30
    8000458c:	a039                	j	8000459a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000458e:	85a6                	mv	a1,s1
    80004590:	8526                	mv	a0,s1
    80004592:	ffffe097          	auipc	ra,0xffffe
    80004596:	f42080e7          	jalr	-190(ra) # 800024d4 <sleep>
    if(log.committing){
    8000459a:	50dc                	lw	a5,36(s1)
    8000459c:	fbed                	bnez	a5,8000458e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000459e:	509c                	lw	a5,32(s1)
    800045a0:	0017871b          	addiw	a4,a5,1
    800045a4:	0007069b          	sext.w	a3,a4
    800045a8:	0027179b          	slliw	a5,a4,0x2
    800045ac:	9fb9                	addw	a5,a5,a4
    800045ae:	0017979b          	slliw	a5,a5,0x1
    800045b2:	54d8                	lw	a4,44(s1)
    800045b4:	9fb9                	addw	a5,a5,a4
    800045b6:	00f95963          	bge	s2,a5,800045c8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045ba:	85a6                	mv	a1,s1
    800045bc:	8526                	mv	a0,s1
    800045be:	ffffe097          	auipc	ra,0xffffe
    800045c2:	f16080e7          	jalr	-234(ra) # 800024d4 <sleep>
    800045c6:	bfd1                	j	8000459a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045c8:	0001d517          	auipc	a0,0x1d
    800045cc:	7e850513          	addi	a0,a0,2024 # 80021db0 <log>
    800045d0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	6c6080e7          	jalr	1734(ra) # 80000c98 <release>
      break;
    }
  }
}
    800045da:	60e2                	ld	ra,24(sp)
    800045dc:	6442                	ld	s0,16(sp)
    800045de:	64a2                	ld	s1,8(sp)
    800045e0:	6902                	ld	s2,0(sp)
    800045e2:	6105                	addi	sp,sp,32
    800045e4:	8082                	ret

00000000800045e6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045e6:	7139                	addi	sp,sp,-64
    800045e8:	fc06                	sd	ra,56(sp)
    800045ea:	f822                	sd	s0,48(sp)
    800045ec:	f426                	sd	s1,40(sp)
    800045ee:	f04a                	sd	s2,32(sp)
    800045f0:	ec4e                	sd	s3,24(sp)
    800045f2:	e852                	sd	s4,16(sp)
    800045f4:	e456                	sd	s5,8(sp)
    800045f6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045f8:	0001d497          	auipc	s1,0x1d
    800045fc:	7b848493          	addi	s1,s1,1976 # 80021db0 <log>
    80004600:	8526                	mv	a0,s1
    80004602:	ffffc097          	auipc	ra,0xffffc
    80004606:	5e2080e7          	jalr	1506(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000460a:	509c                	lw	a5,32(s1)
    8000460c:	37fd                	addiw	a5,a5,-1
    8000460e:	0007891b          	sext.w	s2,a5
    80004612:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004614:	50dc                	lw	a5,36(s1)
    80004616:	efb9                	bnez	a5,80004674 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004618:	06091663          	bnez	s2,80004684 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000461c:	0001d497          	auipc	s1,0x1d
    80004620:	79448493          	addi	s1,s1,1940 # 80021db0 <log>
    80004624:	4785                	li	a5,1
    80004626:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004628:	8526                	mv	a0,s1
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	66e080e7          	jalr	1646(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004632:	54dc                	lw	a5,44(s1)
    80004634:	06f04763          	bgtz	a5,800046a2 <end_op+0xbc>
    acquire(&log.lock);
    80004638:	0001d497          	auipc	s1,0x1d
    8000463c:	77848493          	addi	s1,s1,1912 # 80021db0 <log>
    80004640:	8526                	mv	a0,s1
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	5a2080e7          	jalr	1442(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000464a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000464e:	8526                	mv	a0,s1
    80004650:	ffffe097          	auipc	ra,0xffffe
    80004654:	022080e7          	jalr	34(ra) # 80002672 <wakeup>
    release(&log.lock);
    80004658:	8526                	mv	a0,s1
    8000465a:	ffffc097          	auipc	ra,0xffffc
    8000465e:	63e080e7          	jalr	1598(ra) # 80000c98 <release>
}
    80004662:	70e2                	ld	ra,56(sp)
    80004664:	7442                	ld	s0,48(sp)
    80004666:	74a2                	ld	s1,40(sp)
    80004668:	7902                	ld	s2,32(sp)
    8000466a:	69e2                	ld	s3,24(sp)
    8000466c:	6a42                	ld	s4,16(sp)
    8000466e:	6aa2                	ld	s5,8(sp)
    80004670:	6121                	addi	sp,sp,64
    80004672:	8082                	ret
    panic("log.committing");
    80004674:	00004517          	auipc	a0,0x4
    80004678:	03c50513          	addi	a0,a0,60 # 800086b0 <syscalls+0x1e0>
    8000467c:	ffffc097          	auipc	ra,0xffffc
    80004680:	ec2080e7          	jalr	-318(ra) # 8000053e <panic>
    wakeup(&log);
    80004684:	0001d497          	auipc	s1,0x1d
    80004688:	72c48493          	addi	s1,s1,1836 # 80021db0 <log>
    8000468c:	8526                	mv	a0,s1
    8000468e:	ffffe097          	auipc	ra,0xffffe
    80004692:	fe4080e7          	jalr	-28(ra) # 80002672 <wakeup>
  release(&log.lock);
    80004696:	8526                	mv	a0,s1
    80004698:	ffffc097          	auipc	ra,0xffffc
    8000469c:	600080e7          	jalr	1536(ra) # 80000c98 <release>
  if(do_commit){
    800046a0:	b7c9                	j	80004662 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046a2:	0001da97          	auipc	s5,0x1d
    800046a6:	73ea8a93          	addi	s5,s5,1854 # 80021de0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800046aa:	0001da17          	auipc	s4,0x1d
    800046ae:	706a0a13          	addi	s4,s4,1798 # 80021db0 <log>
    800046b2:	018a2583          	lw	a1,24(s4)
    800046b6:	012585bb          	addw	a1,a1,s2
    800046ba:	2585                	addiw	a1,a1,1
    800046bc:	028a2503          	lw	a0,40(s4)
    800046c0:	fffff097          	auipc	ra,0xfffff
    800046c4:	cd2080e7          	jalr	-814(ra) # 80003392 <bread>
    800046c8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046ca:	000aa583          	lw	a1,0(s5)
    800046ce:	028a2503          	lw	a0,40(s4)
    800046d2:	fffff097          	auipc	ra,0xfffff
    800046d6:	cc0080e7          	jalr	-832(ra) # 80003392 <bread>
    800046da:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046dc:	40000613          	li	a2,1024
    800046e0:	05850593          	addi	a1,a0,88
    800046e4:	05848513          	addi	a0,s1,88
    800046e8:	ffffc097          	auipc	ra,0xffffc
    800046ec:	658080e7          	jalr	1624(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800046f0:	8526                	mv	a0,s1
    800046f2:	fffff097          	auipc	ra,0xfffff
    800046f6:	d92080e7          	jalr	-622(ra) # 80003484 <bwrite>
    brelse(from);
    800046fa:	854e                	mv	a0,s3
    800046fc:	fffff097          	auipc	ra,0xfffff
    80004700:	dc6080e7          	jalr	-570(ra) # 800034c2 <brelse>
    brelse(to);
    80004704:	8526                	mv	a0,s1
    80004706:	fffff097          	auipc	ra,0xfffff
    8000470a:	dbc080e7          	jalr	-580(ra) # 800034c2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000470e:	2905                	addiw	s2,s2,1
    80004710:	0a91                	addi	s5,s5,4
    80004712:	02ca2783          	lw	a5,44(s4)
    80004716:	f8f94ee3          	blt	s2,a5,800046b2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000471a:	00000097          	auipc	ra,0x0
    8000471e:	c6a080e7          	jalr	-918(ra) # 80004384 <write_head>
    install_trans(0); // Now install writes to home locations
    80004722:	4501                	li	a0,0
    80004724:	00000097          	auipc	ra,0x0
    80004728:	cda080e7          	jalr	-806(ra) # 800043fe <install_trans>
    log.lh.n = 0;
    8000472c:	0001d797          	auipc	a5,0x1d
    80004730:	6a07a823          	sw	zero,1712(a5) # 80021ddc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004734:	00000097          	auipc	ra,0x0
    80004738:	c50080e7          	jalr	-944(ra) # 80004384 <write_head>
    8000473c:	bdf5                	j	80004638 <end_op+0x52>

000000008000473e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000473e:	1101                	addi	sp,sp,-32
    80004740:	ec06                	sd	ra,24(sp)
    80004742:	e822                	sd	s0,16(sp)
    80004744:	e426                	sd	s1,8(sp)
    80004746:	e04a                	sd	s2,0(sp)
    80004748:	1000                	addi	s0,sp,32
    8000474a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000474c:	0001d917          	auipc	s2,0x1d
    80004750:	66490913          	addi	s2,s2,1636 # 80021db0 <log>
    80004754:	854a                	mv	a0,s2
    80004756:	ffffc097          	auipc	ra,0xffffc
    8000475a:	48e080e7          	jalr	1166(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000475e:	02c92603          	lw	a2,44(s2)
    80004762:	47f5                	li	a5,29
    80004764:	06c7c563          	blt	a5,a2,800047ce <log_write+0x90>
    80004768:	0001d797          	auipc	a5,0x1d
    8000476c:	6647a783          	lw	a5,1636(a5) # 80021dcc <log+0x1c>
    80004770:	37fd                	addiw	a5,a5,-1
    80004772:	04f65e63          	bge	a2,a5,800047ce <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004776:	0001d797          	auipc	a5,0x1d
    8000477a:	65a7a783          	lw	a5,1626(a5) # 80021dd0 <log+0x20>
    8000477e:	06f05063          	blez	a5,800047de <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004782:	4781                	li	a5,0
    80004784:	06c05563          	blez	a2,800047ee <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004788:	44cc                	lw	a1,12(s1)
    8000478a:	0001d717          	auipc	a4,0x1d
    8000478e:	65670713          	addi	a4,a4,1622 # 80021de0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004792:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004794:	4314                	lw	a3,0(a4)
    80004796:	04b68c63          	beq	a3,a1,800047ee <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000479a:	2785                	addiw	a5,a5,1
    8000479c:	0711                	addi	a4,a4,4
    8000479e:	fef61be3          	bne	a2,a5,80004794 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800047a2:	0621                	addi	a2,a2,8
    800047a4:	060a                	slli	a2,a2,0x2
    800047a6:	0001d797          	auipc	a5,0x1d
    800047aa:	60a78793          	addi	a5,a5,1546 # 80021db0 <log>
    800047ae:	963e                	add	a2,a2,a5
    800047b0:	44dc                	lw	a5,12(s1)
    800047b2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800047b4:	8526                	mv	a0,s1
    800047b6:	fffff097          	auipc	ra,0xfffff
    800047ba:	daa080e7          	jalr	-598(ra) # 80003560 <bpin>
    log.lh.n++;
    800047be:	0001d717          	auipc	a4,0x1d
    800047c2:	5f270713          	addi	a4,a4,1522 # 80021db0 <log>
    800047c6:	575c                	lw	a5,44(a4)
    800047c8:	2785                	addiw	a5,a5,1
    800047ca:	d75c                	sw	a5,44(a4)
    800047cc:	a835                	j	80004808 <log_write+0xca>
    panic("too big a transaction");
    800047ce:	00004517          	auipc	a0,0x4
    800047d2:	ef250513          	addi	a0,a0,-270 # 800086c0 <syscalls+0x1f0>
    800047d6:	ffffc097          	auipc	ra,0xffffc
    800047da:	d68080e7          	jalr	-664(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800047de:	00004517          	auipc	a0,0x4
    800047e2:	efa50513          	addi	a0,a0,-262 # 800086d8 <syscalls+0x208>
    800047e6:	ffffc097          	auipc	ra,0xffffc
    800047ea:	d58080e7          	jalr	-680(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800047ee:	00878713          	addi	a4,a5,8
    800047f2:	00271693          	slli	a3,a4,0x2
    800047f6:	0001d717          	auipc	a4,0x1d
    800047fa:	5ba70713          	addi	a4,a4,1466 # 80021db0 <log>
    800047fe:	9736                	add	a4,a4,a3
    80004800:	44d4                	lw	a3,12(s1)
    80004802:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004804:	faf608e3          	beq	a2,a5,800047b4 <log_write+0x76>
  }
  release(&log.lock);
    80004808:	0001d517          	auipc	a0,0x1d
    8000480c:	5a850513          	addi	a0,a0,1448 # 80021db0 <log>
    80004810:	ffffc097          	auipc	ra,0xffffc
    80004814:	488080e7          	jalr	1160(ra) # 80000c98 <release>
}
    80004818:	60e2                	ld	ra,24(sp)
    8000481a:	6442                	ld	s0,16(sp)
    8000481c:	64a2                	ld	s1,8(sp)
    8000481e:	6902                	ld	s2,0(sp)
    80004820:	6105                	addi	sp,sp,32
    80004822:	8082                	ret

0000000080004824 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004824:	1101                	addi	sp,sp,-32
    80004826:	ec06                	sd	ra,24(sp)
    80004828:	e822                	sd	s0,16(sp)
    8000482a:	e426                	sd	s1,8(sp)
    8000482c:	e04a                	sd	s2,0(sp)
    8000482e:	1000                	addi	s0,sp,32
    80004830:	84aa                	mv	s1,a0
    80004832:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004834:	00004597          	auipc	a1,0x4
    80004838:	ec458593          	addi	a1,a1,-316 # 800086f8 <syscalls+0x228>
    8000483c:	0521                	addi	a0,a0,8
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	316080e7          	jalr	790(ra) # 80000b54 <initlock>
  lk->name = name;
    80004846:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000484a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000484e:	0204a423          	sw	zero,40(s1)
}
    80004852:	60e2                	ld	ra,24(sp)
    80004854:	6442                	ld	s0,16(sp)
    80004856:	64a2                	ld	s1,8(sp)
    80004858:	6902                	ld	s2,0(sp)
    8000485a:	6105                	addi	sp,sp,32
    8000485c:	8082                	ret

000000008000485e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000485e:	1101                	addi	sp,sp,-32
    80004860:	ec06                	sd	ra,24(sp)
    80004862:	e822                	sd	s0,16(sp)
    80004864:	e426                	sd	s1,8(sp)
    80004866:	e04a                	sd	s2,0(sp)
    80004868:	1000                	addi	s0,sp,32
    8000486a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000486c:	00850913          	addi	s2,a0,8
    80004870:	854a                	mv	a0,s2
    80004872:	ffffc097          	auipc	ra,0xffffc
    80004876:	372080e7          	jalr	882(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000487a:	409c                	lw	a5,0(s1)
    8000487c:	cb89                	beqz	a5,8000488e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000487e:	85ca                	mv	a1,s2
    80004880:	8526                	mv	a0,s1
    80004882:	ffffe097          	auipc	ra,0xffffe
    80004886:	c52080e7          	jalr	-942(ra) # 800024d4 <sleep>
  while (lk->locked) {
    8000488a:	409c                	lw	a5,0(s1)
    8000488c:	fbed                	bnez	a5,8000487e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000488e:	4785                	li	a5,1
    80004890:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004892:	ffffd097          	auipc	ra,0xffffd
    80004896:	43c080e7          	jalr	1084(ra) # 80001cce <myproc>
    8000489a:	591c                	lw	a5,48(a0)
    8000489c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000489e:	854a                	mv	a0,s2
    800048a0:	ffffc097          	auipc	ra,0xffffc
    800048a4:	3f8080e7          	jalr	1016(ra) # 80000c98 <release>
}
    800048a8:	60e2                	ld	ra,24(sp)
    800048aa:	6442                	ld	s0,16(sp)
    800048ac:	64a2                	ld	s1,8(sp)
    800048ae:	6902                	ld	s2,0(sp)
    800048b0:	6105                	addi	sp,sp,32
    800048b2:	8082                	ret

00000000800048b4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800048b4:	1101                	addi	sp,sp,-32
    800048b6:	ec06                	sd	ra,24(sp)
    800048b8:	e822                	sd	s0,16(sp)
    800048ba:	e426                	sd	s1,8(sp)
    800048bc:	e04a                	sd	s2,0(sp)
    800048be:	1000                	addi	s0,sp,32
    800048c0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048c2:	00850913          	addi	s2,a0,8
    800048c6:	854a                	mv	a0,s2
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	31c080e7          	jalr	796(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800048d0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048d4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800048d8:	8526                	mv	a0,s1
    800048da:	ffffe097          	auipc	ra,0xffffe
    800048de:	d98080e7          	jalr	-616(ra) # 80002672 <wakeup>
  release(&lk->lk);
    800048e2:	854a                	mv	a0,s2
    800048e4:	ffffc097          	auipc	ra,0xffffc
    800048e8:	3b4080e7          	jalr	948(ra) # 80000c98 <release>
}
    800048ec:	60e2                	ld	ra,24(sp)
    800048ee:	6442                	ld	s0,16(sp)
    800048f0:	64a2                	ld	s1,8(sp)
    800048f2:	6902                	ld	s2,0(sp)
    800048f4:	6105                	addi	sp,sp,32
    800048f6:	8082                	ret

00000000800048f8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048f8:	7179                	addi	sp,sp,-48
    800048fa:	f406                	sd	ra,40(sp)
    800048fc:	f022                	sd	s0,32(sp)
    800048fe:	ec26                	sd	s1,24(sp)
    80004900:	e84a                	sd	s2,16(sp)
    80004902:	e44e                	sd	s3,8(sp)
    80004904:	1800                	addi	s0,sp,48
    80004906:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004908:	00850913          	addi	s2,a0,8
    8000490c:	854a                	mv	a0,s2
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	2d6080e7          	jalr	726(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004916:	409c                	lw	a5,0(s1)
    80004918:	ef99                	bnez	a5,80004936 <holdingsleep+0x3e>
    8000491a:	4481                	li	s1,0
  release(&lk->lk);
    8000491c:	854a                	mv	a0,s2
    8000491e:	ffffc097          	auipc	ra,0xffffc
    80004922:	37a080e7          	jalr	890(ra) # 80000c98 <release>
  return r;
}
    80004926:	8526                	mv	a0,s1
    80004928:	70a2                	ld	ra,40(sp)
    8000492a:	7402                	ld	s0,32(sp)
    8000492c:	64e2                	ld	s1,24(sp)
    8000492e:	6942                	ld	s2,16(sp)
    80004930:	69a2                	ld	s3,8(sp)
    80004932:	6145                	addi	sp,sp,48
    80004934:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004936:	0284a983          	lw	s3,40(s1)
    8000493a:	ffffd097          	auipc	ra,0xffffd
    8000493e:	394080e7          	jalr	916(ra) # 80001cce <myproc>
    80004942:	5904                	lw	s1,48(a0)
    80004944:	413484b3          	sub	s1,s1,s3
    80004948:	0014b493          	seqz	s1,s1
    8000494c:	bfc1                	j	8000491c <holdingsleep+0x24>

000000008000494e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000494e:	1141                	addi	sp,sp,-16
    80004950:	e406                	sd	ra,8(sp)
    80004952:	e022                	sd	s0,0(sp)
    80004954:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004956:	00004597          	auipc	a1,0x4
    8000495a:	db258593          	addi	a1,a1,-590 # 80008708 <syscalls+0x238>
    8000495e:	0001d517          	auipc	a0,0x1d
    80004962:	59a50513          	addi	a0,a0,1434 # 80021ef8 <ftable>
    80004966:	ffffc097          	auipc	ra,0xffffc
    8000496a:	1ee080e7          	jalr	494(ra) # 80000b54 <initlock>
}
    8000496e:	60a2                	ld	ra,8(sp)
    80004970:	6402                	ld	s0,0(sp)
    80004972:	0141                	addi	sp,sp,16
    80004974:	8082                	ret

0000000080004976 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004976:	1101                	addi	sp,sp,-32
    80004978:	ec06                	sd	ra,24(sp)
    8000497a:	e822                	sd	s0,16(sp)
    8000497c:	e426                	sd	s1,8(sp)
    8000497e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004980:	0001d517          	auipc	a0,0x1d
    80004984:	57850513          	addi	a0,a0,1400 # 80021ef8 <ftable>
    80004988:	ffffc097          	auipc	ra,0xffffc
    8000498c:	25c080e7          	jalr	604(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004990:	0001d497          	auipc	s1,0x1d
    80004994:	58048493          	addi	s1,s1,1408 # 80021f10 <ftable+0x18>
    80004998:	0001e717          	auipc	a4,0x1e
    8000499c:	51870713          	addi	a4,a4,1304 # 80022eb0 <ftable+0xfb8>
    if(f->ref == 0){
    800049a0:	40dc                	lw	a5,4(s1)
    800049a2:	cf99                	beqz	a5,800049c0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049a4:	02848493          	addi	s1,s1,40
    800049a8:	fee49ce3          	bne	s1,a4,800049a0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800049ac:	0001d517          	auipc	a0,0x1d
    800049b0:	54c50513          	addi	a0,a0,1356 # 80021ef8 <ftable>
    800049b4:	ffffc097          	auipc	ra,0xffffc
    800049b8:	2e4080e7          	jalr	740(ra) # 80000c98 <release>
  return 0;
    800049bc:	4481                	li	s1,0
    800049be:	a819                	j	800049d4 <filealloc+0x5e>
      f->ref = 1;
    800049c0:	4785                	li	a5,1
    800049c2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049c4:	0001d517          	auipc	a0,0x1d
    800049c8:	53450513          	addi	a0,a0,1332 # 80021ef8 <ftable>
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	2cc080e7          	jalr	716(ra) # 80000c98 <release>
}
    800049d4:	8526                	mv	a0,s1
    800049d6:	60e2                	ld	ra,24(sp)
    800049d8:	6442                	ld	s0,16(sp)
    800049da:	64a2                	ld	s1,8(sp)
    800049dc:	6105                	addi	sp,sp,32
    800049de:	8082                	ret

00000000800049e0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049e0:	1101                	addi	sp,sp,-32
    800049e2:	ec06                	sd	ra,24(sp)
    800049e4:	e822                	sd	s0,16(sp)
    800049e6:	e426                	sd	s1,8(sp)
    800049e8:	1000                	addi	s0,sp,32
    800049ea:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049ec:	0001d517          	auipc	a0,0x1d
    800049f0:	50c50513          	addi	a0,a0,1292 # 80021ef8 <ftable>
    800049f4:	ffffc097          	auipc	ra,0xffffc
    800049f8:	1f0080e7          	jalr	496(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800049fc:	40dc                	lw	a5,4(s1)
    800049fe:	02f05263          	blez	a5,80004a22 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a02:	2785                	addiw	a5,a5,1
    80004a04:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a06:	0001d517          	auipc	a0,0x1d
    80004a0a:	4f250513          	addi	a0,a0,1266 # 80021ef8 <ftable>
    80004a0e:	ffffc097          	auipc	ra,0xffffc
    80004a12:	28a080e7          	jalr	650(ra) # 80000c98 <release>
  return f;
}
    80004a16:	8526                	mv	a0,s1
    80004a18:	60e2                	ld	ra,24(sp)
    80004a1a:	6442                	ld	s0,16(sp)
    80004a1c:	64a2                	ld	s1,8(sp)
    80004a1e:	6105                	addi	sp,sp,32
    80004a20:	8082                	ret
    panic("filedup");
    80004a22:	00004517          	auipc	a0,0x4
    80004a26:	cee50513          	addi	a0,a0,-786 # 80008710 <syscalls+0x240>
    80004a2a:	ffffc097          	auipc	ra,0xffffc
    80004a2e:	b14080e7          	jalr	-1260(ra) # 8000053e <panic>

0000000080004a32 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a32:	7139                	addi	sp,sp,-64
    80004a34:	fc06                	sd	ra,56(sp)
    80004a36:	f822                	sd	s0,48(sp)
    80004a38:	f426                	sd	s1,40(sp)
    80004a3a:	f04a                	sd	s2,32(sp)
    80004a3c:	ec4e                	sd	s3,24(sp)
    80004a3e:	e852                	sd	s4,16(sp)
    80004a40:	e456                	sd	s5,8(sp)
    80004a42:	0080                	addi	s0,sp,64
    80004a44:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a46:	0001d517          	auipc	a0,0x1d
    80004a4a:	4b250513          	addi	a0,a0,1202 # 80021ef8 <ftable>
    80004a4e:	ffffc097          	auipc	ra,0xffffc
    80004a52:	196080e7          	jalr	406(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a56:	40dc                	lw	a5,4(s1)
    80004a58:	06f05163          	blez	a5,80004aba <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a5c:	37fd                	addiw	a5,a5,-1
    80004a5e:	0007871b          	sext.w	a4,a5
    80004a62:	c0dc                	sw	a5,4(s1)
    80004a64:	06e04363          	bgtz	a4,80004aca <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a68:	0004a903          	lw	s2,0(s1)
    80004a6c:	0094ca83          	lbu	s5,9(s1)
    80004a70:	0104ba03          	ld	s4,16(s1)
    80004a74:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a78:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a7c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a80:	0001d517          	auipc	a0,0x1d
    80004a84:	47850513          	addi	a0,a0,1144 # 80021ef8 <ftable>
    80004a88:	ffffc097          	auipc	ra,0xffffc
    80004a8c:	210080e7          	jalr	528(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004a90:	4785                	li	a5,1
    80004a92:	04f90d63          	beq	s2,a5,80004aec <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a96:	3979                	addiw	s2,s2,-2
    80004a98:	4785                	li	a5,1
    80004a9a:	0527e063          	bltu	a5,s2,80004ada <fileclose+0xa8>
    begin_op();
    80004a9e:	00000097          	auipc	ra,0x0
    80004aa2:	ac8080e7          	jalr	-1336(ra) # 80004566 <begin_op>
    iput(ff.ip);
    80004aa6:	854e                	mv	a0,s3
    80004aa8:	fffff097          	auipc	ra,0xfffff
    80004aac:	2a6080e7          	jalr	678(ra) # 80003d4e <iput>
    end_op();
    80004ab0:	00000097          	auipc	ra,0x0
    80004ab4:	b36080e7          	jalr	-1226(ra) # 800045e6 <end_op>
    80004ab8:	a00d                	j	80004ada <fileclose+0xa8>
    panic("fileclose");
    80004aba:	00004517          	auipc	a0,0x4
    80004abe:	c5e50513          	addi	a0,a0,-930 # 80008718 <syscalls+0x248>
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	a7c080e7          	jalr	-1412(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004aca:	0001d517          	auipc	a0,0x1d
    80004ace:	42e50513          	addi	a0,a0,1070 # 80021ef8 <ftable>
    80004ad2:	ffffc097          	auipc	ra,0xffffc
    80004ad6:	1c6080e7          	jalr	454(ra) # 80000c98 <release>
  }
}
    80004ada:	70e2                	ld	ra,56(sp)
    80004adc:	7442                	ld	s0,48(sp)
    80004ade:	74a2                	ld	s1,40(sp)
    80004ae0:	7902                	ld	s2,32(sp)
    80004ae2:	69e2                	ld	s3,24(sp)
    80004ae4:	6a42                	ld	s4,16(sp)
    80004ae6:	6aa2                	ld	s5,8(sp)
    80004ae8:	6121                	addi	sp,sp,64
    80004aea:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004aec:	85d6                	mv	a1,s5
    80004aee:	8552                	mv	a0,s4
    80004af0:	00000097          	auipc	ra,0x0
    80004af4:	34c080e7          	jalr	844(ra) # 80004e3c <pipeclose>
    80004af8:	b7cd                	j	80004ada <fileclose+0xa8>

0000000080004afa <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004afa:	715d                	addi	sp,sp,-80
    80004afc:	e486                	sd	ra,72(sp)
    80004afe:	e0a2                	sd	s0,64(sp)
    80004b00:	fc26                	sd	s1,56(sp)
    80004b02:	f84a                	sd	s2,48(sp)
    80004b04:	f44e                	sd	s3,40(sp)
    80004b06:	0880                	addi	s0,sp,80
    80004b08:	84aa                	mv	s1,a0
    80004b0a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b0c:	ffffd097          	auipc	ra,0xffffd
    80004b10:	1c2080e7          	jalr	450(ra) # 80001cce <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b14:	409c                	lw	a5,0(s1)
    80004b16:	37f9                	addiw	a5,a5,-2
    80004b18:	4705                	li	a4,1
    80004b1a:	04f76763          	bltu	a4,a5,80004b68 <filestat+0x6e>
    80004b1e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b20:	6c88                	ld	a0,24(s1)
    80004b22:	fffff097          	auipc	ra,0xfffff
    80004b26:	072080e7          	jalr	114(ra) # 80003b94 <ilock>
    stati(f->ip, &st);
    80004b2a:	fb840593          	addi	a1,s0,-72
    80004b2e:	6c88                	ld	a0,24(s1)
    80004b30:	fffff097          	auipc	ra,0xfffff
    80004b34:	2ee080e7          	jalr	750(ra) # 80003e1e <stati>
    iunlock(f->ip);
    80004b38:	6c88                	ld	a0,24(s1)
    80004b3a:	fffff097          	auipc	ra,0xfffff
    80004b3e:	11c080e7          	jalr	284(ra) # 80003c56 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b42:	46e1                	li	a3,24
    80004b44:	fb840613          	addi	a2,s0,-72
    80004b48:	85ce                	mv	a1,s3
    80004b4a:	05093503          	ld	a0,80(s2)
    80004b4e:	ffffd097          	auipc	ra,0xffffd
    80004b52:	b24080e7          	jalr	-1244(ra) # 80001672 <copyout>
    80004b56:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b5a:	60a6                	ld	ra,72(sp)
    80004b5c:	6406                	ld	s0,64(sp)
    80004b5e:	74e2                	ld	s1,56(sp)
    80004b60:	7942                	ld	s2,48(sp)
    80004b62:	79a2                	ld	s3,40(sp)
    80004b64:	6161                	addi	sp,sp,80
    80004b66:	8082                	ret
  return -1;
    80004b68:	557d                	li	a0,-1
    80004b6a:	bfc5                	j	80004b5a <filestat+0x60>

0000000080004b6c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b6c:	7179                	addi	sp,sp,-48
    80004b6e:	f406                	sd	ra,40(sp)
    80004b70:	f022                	sd	s0,32(sp)
    80004b72:	ec26                	sd	s1,24(sp)
    80004b74:	e84a                	sd	s2,16(sp)
    80004b76:	e44e                	sd	s3,8(sp)
    80004b78:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b7a:	00854783          	lbu	a5,8(a0)
    80004b7e:	c3d5                	beqz	a5,80004c22 <fileread+0xb6>
    80004b80:	84aa                	mv	s1,a0
    80004b82:	89ae                	mv	s3,a1
    80004b84:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b86:	411c                	lw	a5,0(a0)
    80004b88:	4705                	li	a4,1
    80004b8a:	04e78963          	beq	a5,a4,80004bdc <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b8e:	470d                	li	a4,3
    80004b90:	04e78d63          	beq	a5,a4,80004bea <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b94:	4709                	li	a4,2
    80004b96:	06e79e63          	bne	a5,a4,80004c12 <fileread+0xa6>
    ilock(f->ip);
    80004b9a:	6d08                	ld	a0,24(a0)
    80004b9c:	fffff097          	auipc	ra,0xfffff
    80004ba0:	ff8080e7          	jalr	-8(ra) # 80003b94 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ba4:	874a                	mv	a4,s2
    80004ba6:	5094                	lw	a3,32(s1)
    80004ba8:	864e                	mv	a2,s3
    80004baa:	4585                	li	a1,1
    80004bac:	6c88                	ld	a0,24(s1)
    80004bae:	fffff097          	auipc	ra,0xfffff
    80004bb2:	29a080e7          	jalr	666(ra) # 80003e48 <readi>
    80004bb6:	892a                	mv	s2,a0
    80004bb8:	00a05563          	blez	a0,80004bc2 <fileread+0x56>
      f->off += r;
    80004bbc:	509c                	lw	a5,32(s1)
    80004bbe:	9fa9                	addw	a5,a5,a0
    80004bc0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004bc2:	6c88                	ld	a0,24(s1)
    80004bc4:	fffff097          	auipc	ra,0xfffff
    80004bc8:	092080e7          	jalr	146(ra) # 80003c56 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004bcc:	854a                	mv	a0,s2
    80004bce:	70a2                	ld	ra,40(sp)
    80004bd0:	7402                	ld	s0,32(sp)
    80004bd2:	64e2                	ld	s1,24(sp)
    80004bd4:	6942                	ld	s2,16(sp)
    80004bd6:	69a2                	ld	s3,8(sp)
    80004bd8:	6145                	addi	sp,sp,48
    80004bda:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004bdc:	6908                	ld	a0,16(a0)
    80004bde:	00000097          	auipc	ra,0x0
    80004be2:	3c8080e7          	jalr	968(ra) # 80004fa6 <piperead>
    80004be6:	892a                	mv	s2,a0
    80004be8:	b7d5                	j	80004bcc <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004bea:	02451783          	lh	a5,36(a0)
    80004bee:	03079693          	slli	a3,a5,0x30
    80004bf2:	92c1                	srli	a3,a3,0x30
    80004bf4:	4725                	li	a4,9
    80004bf6:	02d76863          	bltu	a4,a3,80004c26 <fileread+0xba>
    80004bfa:	0792                	slli	a5,a5,0x4
    80004bfc:	0001d717          	auipc	a4,0x1d
    80004c00:	25c70713          	addi	a4,a4,604 # 80021e58 <devsw>
    80004c04:	97ba                	add	a5,a5,a4
    80004c06:	639c                	ld	a5,0(a5)
    80004c08:	c38d                	beqz	a5,80004c2a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c0a:	4505                	li	a0,1
    80004c0c:	9782                	jalr	a5
    80004c0e:	892a                	mv	s2,a0
    80004c10:	bf75                	j	80004bcc <fileread+0x60>
    panic("fileread");
    80004c12:	00004517          	auipc	a0,0x4
    80004c16:	b1650513          	addi	a0,a0,-1258 # 80008728 <syscalls+0x258>
    80004c1a:	ffffc097          	auipc	ra,0xffffc
    80004c1e:	924080e7          	jalr	-1756(ra) # 8000053e <panic>
    return -1;
    80004c22:	597d                	li	s2,-1
    80004c24:	b765                	j	80004bcc <fileread+0x60>
      return -1;
    80004c26:	597d                	li	s2,-1
    80004c28:	b755                	j	80004bcc <fileread+0x60>
    80004c2a:	597d                	li	s2,-1
    80004c2c:	b745                	j	80004bcc <fileread+0x60>

0000000080004c2e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c2e:	715d                	addi	sp,sp,-80
    80004c30:	e486                	sd	ra,72(sp)
    80004c32:	e0a2                	sd	s0,64(sp)
    80004c34:	fc26                	sd	s1,56(sp)
    80004c36:	f84a                	sd	s2,48(sp)
    80004c38:	f44e                	sd	s3,40(sp)
    80004c3a:	f052                	sd	s4,32(sp)
    80004c3c:	ec56                	sd	s5,24(sp)
    80004c3e:	e85a                	sd	s6,16(sp)
    80004c40:	e45e                	sd	s7,8(sp)
    80004c42:	e062                	sd	s8,0(sp)
    80004c44:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c46:	00954783          	lbu	a5,9(a0)
    80004c4a:	10078663          	beqz	a5,80004d56 <filewrite+0x128>
    80004c4e:	892a                	mv	s2,a0
    80004c50:	8aae                	mv	s5,a1
    80004c52:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c54:	411c                	lw	a5,0(a0)
    80004c56:	4705                	li	a4,1
    80004c58:	02e78263          	beq	a5,a4,80004c7c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c5c:	470d                	li	a4,3
    80004c5e:	02e78663          	beq	a5,a4,80004c8a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c62:	4709                	li	a4,2
    80004c64:	0ee79163          	bne	a5,a4,80004d46 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c68:	0ac05d63          	blez	a2,80004d22 <filewrite+0xf4>
    int i = 0;
    80004c6c:	4981                	li	s3,0
    80004c6e:	6b05                	lui	s6,0x1
    80004c70:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c74:	6b85                	lui	s7,0x1
    80004c76:	c00b8b9b          	addiw	s7,s7,-1024
    80004c7a:	a861                	j	80004d12 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c7c:	6908                	ld	a0,16(a0)
    80004c7e:	00000097          	auipc	ra,0x0
    80004c82:	22e080e7          	jalr	558(ra) # 80004eac <pipewrite>
    80004c86:	8a2a                	mv	s4,a0
    80004c88:	a045                	j	80004d28 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c8a:	02451783          	lh	a5,36(a0)
    80004c8e:	03079693          	slli	a3,a5,0x30
    80004c92:	92c1                	srli	a3,a3,0x30
    80004c94:	4725                	li	a4,9
    80004c96:	0cd76263          	bltu	a4,a3,80004d5a <filewrite+0x12c>
    80004c9a:	0792                	slli	a5,a5,0x4
    80004c9c:	0001d717          	auipc	a4,0x1d
    80004ca0:	1bc70713          	addi	a4,a4,444 # 80021e58 <devsw>
    80004ca4:	97ba                	add	a5,a5,a4
    80004ca6:	679c                	ld	a5,8(a5)
    80004ca8:	cbdd                	beqz	a5,80004d5e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004caa:	4505                	li	a0,1
    80004cac:	9782                	jalr	a5
    80004cae:	8a2a                	mv	s4,a0
    80004cb0:	a8a5                	j	80004d28 <filewrite+0xfa>
    80004cb2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004cb6:	00000097          	auipc	ra,0x0
    80004cba:	8b0080e7          	jalr	-1872(ra) # 80004566 <begin_op>
      ilock(f->ip);
    80004cbe:	01893503          	ld	a0,24(s2)
    80004cc2:	fffff097          	auipc	ra,0xfffff
    80004cc6:	ed2080e7          	jalr	-302(ra) # 80003b94 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004cca:	8762                	mv	a4,s8
    80004ccc:	02092683          	lw	a3,32(s2)
    80004cd0:	01598633          	add	a2,s3,s5
    80004cd4:	4585                	li	a1,1
    80004cd6:	01893503          	ld	a0,24(s2)
    80004cda:	fffff097          	auipc	ra,0xfffff
    80004cde:	266080e7          	jalr	614(ra) # 80003f40 <writei>
    80004ce2:	84aa                	mv	s1,a0
    80004ce4:	00a05763          	blez	a0,80004cf2 <filewrite+0xc4>
        f->off += r;
    80004ce8:	02092783          	lw	a5,32(s2)
    80004cec:	9fa9                	addw	a5,a5,a0
    80004cee:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cf2:	01893503          	ld	a0,24(s2)
    80004cf6:	fffff097          	auipc	ra,0xfffff
    80004cfa:	f60080e7          	jalr	-160(ra) # 80003c56 <iunlock>
      end_op();
    80004cfe:	00000097          	auipc	ra,0x0
    80004d02:	8e8080e7          	jalr	-1816(ra) # 800045e6 <end_op>

      if(r != n1){
    80004d06:	009c1f63          	bne	s8,s1,80004d24 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d0a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d0e:	0149db63          	bge	s3,s4,80004d24 <filewrite+0xf6>
      int n1 = n - i;
    80004d12:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d16:	84be                	mv	s1,a5
    80004d18:	2781                	sext.w	a5,a5
    80004d1a:	f8fb5ce3          	bge	s6,a5,80004cb2 <filewrite+0x84>
    80004d1e:	84de                	mv	s1,s7
    80004d20:	bf49                	j	80004cb2 <filewrite+0x84>
    int i = 0;
    80004d22:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d24:	013a1f63          	bne	s4,s3,80004d42 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d28:	8552                	mv	a0,s4
    80004d2a:	60a6                	ld	ra,72(sp)
    80004d2c:	6406                	ld	s0,64(sp)
    80004d2e:	74e2                	ld	s1,56(sp)
    80004d30:	7942                	ld	s2,48(sp)
    80004d32:	79a2                	ld	s3,40(sp)
    80004d34:	7a02                	ld	s4,32(sp)
    80004d36:	6ae2                	ld	s5,24(sp)
    80004d38:	6b42                	ld	s6,16(sp)
    80004d3a:	6ba2                	ld	s7,8(sp)
    80004d3c:	6c02                	ld	s8,0(sp)
    80004d3e:	6161                	addi	sp,sp,80
    80004d40:	8082                	ret
    ret = (i == n ? n : -1);
    80004d42:	5a7d                	li	s4,-1
    80004d44:	b7d5                	j	80004d28 <filewrite+0xfa>
    panic("filewrite");
    80004d46:	00004517          	auipc	a0,0x4
    80004d4a:	9f250513          	addi	a0,a0,-1550 # 80008738 <syscalls+0x268>
    80004d4e:	ffffb097          	auipc	ra,0xffffb
    80004d52:	7f0080e7          	jalr	2032(ra) # 8000053e <panic>
    return -1;
    80004d56:	5a7d                	li	s4,-1
    80004d58:	bfc1                	j	80004d28 <filewrite+0xfa>
      return -1;
    80004d5a:	5a7d                	li	s4,-1
    80004d5c:	b7f1                	j	80004d28 <filewrite+0xfa>
    80004d5e:	5a7d                	li	s4,-1
    80004d60:	b7e1                	j	80004d28 <filewrite+0xfa>

0000000080004d62 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d62:	7179                	addi	sp,sp,-48
    80004d64:	f406                	sd	ra,40(sp)
    80004d66:	f022                	sd	s0,32(sp)
    80004d68:	ec26                	sd	s1,24(sp)
    80004d6a:	e84a                	sd	s2,16(sp)
    80004d6c:	e44e                	sd	s3,8(sp)
    80004d6e:	e052                	sd	s4,0(sp)
    80004d70:	1800                	addi	s0,sp,48
    80004d72:	84aa                	mv	s1,a0
    80004d74:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d76:	0005b023          	sd	zero,0(a1)
    80004d7a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d7e:	00000097          	auipc	ra,0x0
    80004d82:	bf8080e7          	jalr	-1032(ra) # 80004976 <filealloc>
    80004d86:	e088                	sd	a0,0(s1)
    80004d88:	c551                	beqz	a0,80004e14 <pipealloc+0xb2>
    80004d8a:	00000097          	auipc	ra,0x0
    80004d8e:	bec080e7          	jalr	-1044(ra) # 80004976 <filealloc>
    80004d92:	00aa3023          	sd	a0,0(s4)
    80004d96:	c92d                	beqz	a0,80004e08 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d98:	ffffc097          	auipc	ra,0xffffc
    80004d9c:	d5c080e7          	jalr	-676(ra) # 80000af4 <kalloc>
    80004da0:	892a                	mv	s2,a0
    80004da2:	c125                	beqz	a0,80004e02 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004da4:	4985                	li	s3,1
    80004da6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004daa:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004dae:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004db2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004db6:	00004597          	auipc	a1,0x4
    80004dba:	99258593          	addi	a1,a1,-1646 # 80008748 <syscalls+0x278>
    80004dbe:	ffffc097          	auipc	ra,0xffffc
    80004dc2:	d96080e7          	jalr	-618(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004dc6:	609c                	ld	a5,0(s1)
    80004dc8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004dcc:	609c                	ld	a5,0(s1)
    80004dce:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004dd2:	609c                	ld	a5,0(s1)
    80004dd4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004dd8:	609c                	ld	a5,0(s1)
    80004dda:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004dde:	000a3783          	ld	a5,0(s4)
    80004de2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004de6:	000a3783          	ld	a5,0(s4)
    80004dea:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004dee:	000a3783          	ld	a5,0(s4)
    80004df2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004df6:	000a3783          	ld	a5,0(s4)
    80004dfa:	0127b823          	sd	s2,16(a5)
  return 0;
    80004dfe:	4501                	li	a0,0
    80004e00:	a025                	j	80004e28 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e02:	6088                	ld	a0,0(s1)
    80004e04:	e501                	bnez	a0,80004e0c <pipealloc+0xaa>
    80004e06:	a039                	j	80004e14 <pipealloc+0xb2>
    80004e08:	6088                	ld	a0,0(s1)
    80004e0a:	c51d                	beqz	a0,80004e38 <pipealloc+0xd6>
    fileclose(*f0);
    80004e0c:	00000097          	auipc	ra,0x0
    80004e10:	c26080e7          	jalr	-986(ra) # 80004a32 <fileclose>
  if(*f1)
    80004e14:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e18:	557d                	li	a0,-1
  if(*f1)
    80004e1a:	c799                	beqz	a5,80004e28 <pipealloc+0xc6>
    fileclose(*f1);
    80004e1c:	853e                	mv	a0,a5
    80004e1e:	00000097          	auipc	ra,0x0
    80004e22:	c14080e7          	jalr	-1004(ra) # 80004a32 <fileclose>
  return -1;
    80004e26:	557d                	li	a0,-1
}
    80004e28:	70a2                	ld	ra,40(sp)
    80004e2a:	7402                	ld	s0,32(sp)
    80004e2c:	64e2                	ld	s1,24(sp)
    80004e2e:	6942                	ld	s2,16(sp)
    80004e30:	69a2                	ld	s3,8(sp)
    80004e32:	6a02                	ld	s4,0(sp)
    80004e34:	6145                	addi	sp,sp,48
    80004e36:	8082                	ret
  return -1;
    80004e38:	557d                	li	a0,-1
    80004e3a:	b7fd                	j	80004e28 <pipealloc+0xc6>

0000000080004e3c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e3c:	1101                	addi	sp,sp,-32
    80004e3e:	ec06                	sd	ra,24(sp)
    80004e40:	e822                	sd	s0,16(sp)
    80004e42:	e426                	sd	s1,8(sp)
    80004e44:	e04a                	sd	s2,0(sp)
    80004e46:	1000                	addi	s0,sp,32
    80004e48:	84aa                	mv	s1,a0
    80004e4a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e4c:	ffffc097          	auipc	ra,0xffffc
    80004e50:	d98080e7          	jalr	-616(ra) # 80000be4 <acquire>
  if(writable){
    80004e54:	02090d63          	beqz	s2,80004e8e <pipeclose+0x52>
    pi->writeopen = 0;
    80004e58:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e5c:	21848513          	addi	a0,s1,536
    80004e60:	ffffe097          	auipc	ra,0xffffe
    80004e64:	812080e7          	jalr	-2030(ra) # 80002672 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e68:	2204b783          	ld	a5,544(s1)
    80004e6c:	eb95                	bnez	a5,80004ea0 <pipeclose+0x64>
    release(&pi->lock);
    80004e6e:	8526                	mv	a0,s1
    80004e70:	ffffc097          	auipc	ra,0xffffc
    80004e74:	e28080e7          	jalr	-472(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004e78:	8526                	mv	a0,s1
    80004e7a:	ffffc097          	auipc	ra,0xffffc
    80004e7e:	b7e080e7          	jalr	-1154(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004e82:	60e2                	ld	ra,24(sp)
    80004e84:	6442                	ld	s0,16(sp)
    80004e86:	64a2                	ld	s1,8(sp)
    80004e88:	6902                	ld	s2,0(sp)
    80004e8a:	6105                	addi	sp,sp,32
    80004e8c:	8082                	ret
    pi->readopen = 0;
    80004e8e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e92:	21c48513          	addi	a0,s1,540
    80004e96:	ffffd097          	auipc	ra,0xffffd
    80004e9a:	7dc080e7          	jalr	2012(ra) # 80002672 <wakeup>
    80004e9e:	b7e9                	j	80004e68 <pipeclose+0x2c>
    release(&pi->lock);
    80004ea0:	8526                	mv	a0,s1
    80004ea2:	ffffc097          	auipc	ra,0xffffc
    80004ea6:	df6080e7          	jalr	-522(ra) # 80000c98 <release>
}
    80004eaa:	bfe1                	j	80004e82 <pipeclose+0x46>

0000000080004eac <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004eac:	7159                	addi	sp,sp,-112
    80004eae:	f486                	sd	ra,104(sp)
    80004eb0:	f0a2                	sd	s0,96(sp)
    80004eb2:	eca6                	sd	s1,88(sp)
    80004eb4:	e8ca                	sd	s2,80(sp)
    80004eb6:	e4ce                	sd	s3,72(sp)
    80004eb8:	e0d2                	sd	s4,64(sp)
    80004eba:	fc56                	sd	s5,56(sp)
    80004ebc:	f85a                	sd	s6,48(sp)
    80004ebe:	f45e                	sd	s7,40(sp)
    80004ec0:	f062                	sd	s8,32(sp)
    80004ec2:	ec66                	sd	s9,24(sp)
    80004ec4:	1880                	addi	s0,sp,112
    80004ec6:	84aa                	mv	s1,a0
    80004ec8:	8aae                	mv	s5,a1
    80004eca:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ecc:	ffffd097          	auipc	ra,0xffffd
    80004ed0:	e02080e7          	jalr	-510(ra) # 80001cce <myproc>
    80004ed4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ed6:	8526                	mv	a0,s1
    80004ed8:	ffffc097          	auipc	ra,0xffffc
    80004edc:	d0c080e7          	jalr	-756(ra) # 80000be4 <acquire>
  while(i < n){
    80004ee0:	0d405163          	blez	s4,80004fa2 <pipewrite+0xf6>
    80004ee4:	8ba6                	mv	s7,s1
  int i = 0;
    80004ee6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ee8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004eea:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004eee:	21c48c13          	addi	s8,s1,540
    80004ef2:	a08d                	j	80004f54 <pipewrite+0xa8>
      release(&pi->lock);
    80004ef4:	8526                	mv	a0,s1
    80004ef6:	ffffc097          	auipc	ra,0xffffc
    80004efa:	da2080e7          	jalr	-606(ra) # 80000c98 <release>
      return -1;
    80004efe:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f00:	854a                	mv	a0,s2
    80004f02:	70a6                	ld	ra,104(sp)
    80004f04:	7406                	ld	s0,96(sp)
    80004f06:	64e6                	ld	s1,88(sp)
    80004f08:	6946                	ld	s2,80(sp)
    80004f0a:	69a6                	ld	s3,72(sp)
    80004f0c:	6a06                	ld	s4,64(sp)
    80004f0e:	7ae2                	ld	s5,56(sp)
    80004f10:	7b42                	ld	s6,48(sp)
    80004f12:	7ba2                	ld	s7,40(sp)
    80004f14:	7c02                	ld	s8,32(sp)
    80004f16:	6ce2                	ld	s9,24(sp)
    80004f18:	6165                	addi	sp,sp,112
    80004f1a:	8082                	ret
      wakeup(&pi->nread);
    80004f1c:	8566                	mv	a0,s9
    80004f1e:	ffffd097          	auipc	ra,0xffffd
    80004f22:	754080e7          	jalr	1876(ra) # 80002672 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f26:	85de                	mv	a1,s7
    80004f28:	8562                	mv	a0,s8
    80004f2a:	ffffd097          	auipc	ra,0xffffd
    80004f2e:	5aa080e7          	jalr	1450(ra) # 800024d4 <sleep>
    80004f32:	a839                	j	80004f50 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f34:	21c4a783          	lw	a5,540(s1)
    80004f38:	0017871b          	addiw	a4,a5,1
    80004f3c:	20e4ae23          	sw	a4,540(s1)
    80004f40:	1ff7f793          	andi	a5,a5,511
    80004f44:	97a6                	add	a5,a5,s1
    80004f46:	f9f44703          	lbu	a4,-97(s0)
    80004f4a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f4e:	2905                	addiw	s2,s2,1
  while(i < n){
    80004f50:	03495d63          	bge	s2,s4,80004f8a <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004f54:	2204a783          	lw	a5,544(s1)
    80004f58:	dfd1                	beqz	a5,80004ef4 <pipewrite+0x48>
    80004f5a:	0289a783          	lw	a5,40(s3)
    80004f5e:	fbd9                	bnez	a5,80004ef4 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f60:	2184a783          	lw	a5,536(s1)
    80004f64:	21c4a703          	lw	a4,540(s1)
    80004f68:	2007879b          	addiw	a5,a5,512
    80004f6c:	faf708e3          	beq	a4,a5,80004f1c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f70:	4685                	li	a3,1
    80004f72:	01590633          	add	a2,s2,s5
    80004f76:	f9f40593          	addi	a1,s0,-97
    80004f7a:	0509b503          	ld	a0,80(s3)
    80004f7e:	ffffc097          	auipc	ra,0xffffc
    80004f82:	780080e7          	jalr	1920(ra) # 800016fe <copyin>
    80004f86:	fb6517e3          	bne	a0,s6,80004f34 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004f8a:	21848513          	addi	a0,s1,536
    80004f8e:	ffffd097          	auipc	ra,0xffffd
    80004f92:	6e4080e7          	jalr	1764(ra) # 80002672 <wakeup>
  release(&pi->lock);
    80004f96:	8526                	mv	a0,s1
    80004f98:	ffffc097          	auipc	ra,0xffffc
    80004f9c:	d00080e7          	jalr	-768(ra) # 80000c98 <release>
  return i;
    80004fa0:	b785                	j	80004f00 <pipewrite+0x54>
  int i = 0;
    80004fa2:	4901                	li	s2,0
    80004fa4:	b7dd                	j	80004f8a <pipewrite+0xde>

0000000080004fa6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004fa6:	715d                	addi	sp,sp,-80
    80004fa8:	e486                	sd	ra,72(sp)
    80004faa:	e0a2                	sd	s0,64(sp)
    80004fac:	fc26                	sd	s1,56(sp)
    80004fae:	f84a                	sd	s2,48(sp)
    80004fb0:	f44e                	sd	s3,40(sp)
    80004fb2:	f052                	sd	s4,32(sp)
    80004fb4:	ec56                	sd	s5,24(sp)
    80004fb6:	e85a                	sd	s6,16(sp)
    80004fb8:	0880                	addi	s0,sp,80
    80004fba:	84aa                	mv	s1,a0
    80004fbc:	892e                	mv	s2,a1
    80004fbe:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004fc0:	ffffd097          	auipc	ra,0xffffd
    80004fc4:	d0e080e7          	jalr	-754(ra) # 80001cce <myproc>
    80004fc8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004fca:	8b26                	mv	s6,s1
    80004fcc:	8526                	mv	a0,s1
    80004fce:	ffffc097          	auipc	ra,0xffffc
    80004fd2:	c16080e7          	jalr	-1002(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fd6:	2184a703          	lw	a4,536(s1)
    80004fda:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fde:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fe2:	02f71463          	bne	a4,a5,8000500a <piperead+0x64>
    80004fe6:	2244a783          	lw	a5,548(s1)
    80004fea:	c385                	beqz	a5,8000500a <piperead+0x64>
    if(pr->killed){
    80004fec:	028a2783          	lw	a5,40(s4)
    80004ff0:	ebc1                	bnez	a5,80005080 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ff2:	85da                	mv	a1,s6
    80004ff4:	854e                	mv	a0,s3
    80004ff6:	ffffd097          	auipc	ra,0xffffd
    80004ffa:	4de080e7          	jalr	1246(ra) # 800024d4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ffe:	2184a703          	lw	a4,536(s1)
    80005002:	21c4a783          	lw	a5,540(s1)
    80005006:	fef700e3          	beq	a4,a5,80004fe6 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000500a:	09505263          	blez	s5,8000508e <piperead+0xe8>
    8000500e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005010:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005012:	2184a783          	lw	a5,536(s1)
    80005016:	21c4a703          	lw	a4,540(s1)
    8000501a:	02f70d63          	beq	a4,a5,80005054 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000501e:	0017871b          	addiw	a4,a5,1
    80005022:	20e4ac23          	sw	a4,536(s1)
    80005026:	1ff7f793          	andi	a5,a5,511
    8000502a:	97a6                	add	a5,a5,s1
    8000502c:	0187c783          	lbu	a5,24(a5)
    80005030:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005034:	4685                	li	a3,1
    80005036:	fbf40613          	addi	a2,s0,-65
    8000503a:	85ca                	mv	a1,s2
    8000503c:	050a3503          	ld	a0,80(s4)
    80005040:	ffffc097          	auipc	ra,0xffffc
    80005044:	632080e7          	jalr	1586(ra) # 80001672 <copyout>
    80005048:	01650663          	beq	a0,s6,80005054 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000504c:	2985                	addiw	s3,s3,1
    8000504e:	0905                	addi	s2,s2,1
    80005050:	fd3a91e3          	bne	s5,s3,80005012 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005054:	21c48513          	addi	a0,s1,540
    80005058:	ffffd097          	auipc	ra,0xffffd
    8000505c:	61a080e7          	jalr	1562(ra) # 80002672 <wakeup>
  release(&pi->lock);
    80005060:	8526                	mv	a0,s1
    80005062:	ffffc097          	auipc	ra,0xffffc
    80005066:	c36080e7          	jalr	-970(ra) # 80000c98 <release>
  return i;
}
    8000506a:	854e                	mv	a0,s3
    8000506c:	60a6                	ld	ra,72(sp)
    8000506e:	6406                	ld	s0,64(sp)
    80005070:	74e2                	ld	s1,56(sp)
    80005072:	7942                	ld	s2,48(sp)
    80005074:	79a2                	ld	s3,40(sp)
    80005076:	7a02                	ld	s4,32(sp)
    80005078:	6ae2                	ld	s5,24(sp)
    8000507a:	6b42                	ld	s6,16(sp)
    8000507c:	6161                	addi	sp,sp,80
    8000507e:	8082                	ret
      release(&pi->lock);
    80005080:	8526                	mv	a0,s1
    80005082:	ffffc097          	auipc	ra,0xffffc
    80005086:	c16080e7          	jalr	-1002(ra) # 80000c98 <release>
      return -1;
    8000508a:	59fd                	li	s3,-1
    8000508c:	bff9                	j	8000506a <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000508e:	4981                	li	s3,0
    80005090:	b7d1                	j	80005054 <piperead+0xae>

0000000080005092 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005092:	df010113          	addi	sp,sp,-528
    80005096:	20113423          	sd	ra,520(sp)
    8000509a:	20813023          	sd	s0,512(sp)
    8000509e:	ffa6                	sd	s1,504(sp)
    800050a0:	fbca                	sd	s2,496(sp)
    800050a2:	f7ce                	sd	s3,488(sp)
    800050a4:	f3d2                	sd	s4,480(sp)
    800050a6:	efd6                	sd	s5,472(sp)
    800050a8:	ebda                	sd	s6,464(sp)
    800050aa:	e7de                	sd	s7,456(sp)
    800050ac:	e3e2                	sd	s8,448(sp)
    800050ae:	ff66                	sd	s9,440(sp)
    800050b0:	fb6a                	sd	s10,432(sp)
    800050b2:	f76e                	sd	s11,424(sp)
    800050b4:	0c00                	addi	s0,sp,528
    800050b6:	84aa                	mv	s1,a0
    800050b8:	dea43c23          	sd	a0,-520(s0)
    800050bc:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050c0:	ffffd097          	auipc	ra,0xffffd
    800050c4:	c0e080e7          	jalr	-1010(ra) # 80001cce <myproc>
    800050c8:	892a                	mv	s2,a0

  begin_op();
    800050ca:	fffff097          	auipc	ra,0xfffff
    800050ce:	49c080e7          	jalr	1180(ra) # 80004566 <begin_op>

  if((ip = namei(path)) == 0){
    800050d2:	8526                	mv	a0,s1
    800050d4:	fffff097          	auipc	ra,0xfffff
    800050d8:	276080e7          	jalr	630(ra) # 8000434a <namei>
    800050dc:	c92d                	beqz	a0,8000514e <exec+0xbc>
    800050de:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800050e0:	fffff097          	auipc	ra,0xfffff
    800050e4:	ab4080e7          	jalr	-1356(ra) # 80003b94 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050e8:	04000713          	li	a4,64
    800050ec:	4681                	li	a3,0
    800050ee:	e5040613          	addi	a2,s0,-432
    800050f2:	4581                	li	a1,0
    800050f4:	8526                	mv	a0,s1
    800050f6:	fffff097          	auipc	ra,0xfffff
    800050fa:	d52080e7          	jalr	-686(ra) # 80003e48 <readi>
    800050fe:	04000793          	li	a5,64
    80005102:	00f51a63          	bne	a0,a5,80005116 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005106:	e5042703          	lw	a4,-432(s0)
    8000510a:	464c47b7          	lui	a5,0x464c4
    8000510e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005112:	04f70463          	beq	a4,a5,8000515a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005116:	8526                	mv	a0,s1
    80005118:	fffff097          	auipc	ra,0xfffff
    8000511c:	cde080e7          	jalr	-802(ra) # 80003df6 <iunlockput>
    end_op();
    80005120:	fffff097          	auipc	ra,0xfffff
    80005124:	4c6080e7          	jalr	1222(ra) # 800045e6 <end_op>
  }
  return -1;
    80005128:	557d                	li	a0,-1
}
    8000512a:	20813083          	ld	ra,520(sp)
    8000512e:	20013403          	ld	s0,512(sp)
    80005132:	74fe                	ld	s1,504(sp)
    80005134:	795e                	ld	s2,496(sp)
    80005136:	79be                	ld	s3,488(sp)
    80005138:	7a1e                	ld	s4,480(sp)
    8000513a:	6afe                	ld	s5,472(sp)
    8000513c:	6b5e                	ld	s6,464(sp)
    8000513e:	6bbe                	ld	s7,456(sp)
    80005140:	6c1e                	ld	s8,448(sp)
    80005142:	7cfa                	ld	s9,440(sp)
    80005144:	7d5a                	ld	s10,432(sp)
    80005146:	7dba                	ld	s11,424(sp)
    80005148:	21010113          	addi	sp,sp,528
    8000514c:	8082                	ret
    end_op();
    8000514e:	fffff097          	auipc	ra,0xfffff
    80005152:	498080e7          	jalr	1176(ra) # 800045e6 <end_op>
    return -1;
    80005156:	557d                	li	a0,-1
    80005158:	bfc9                	j	8000512a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000515a:	854a                	mv	a0,s2
    8000515c:	ffffd097          	auipc	ra,0xffffd
    80005160:	c30080e7          	jalr	-976(ra) # 80001d8c <proc_pagetable>
    80005164:	8baa                	mv	s7,a0
    80005166:	d945                	beqz	a0,80005116 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005168:	e7042983          	lw	s3,-400(s0)
    8000516c:	e8845783          	lhu	a5,-376(s0)
    80005170:	c7ad                	beqz	a5,800051da <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005172:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005174:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005176:	6c85                	lui	s9,0x1
    80005178:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000517c:	def43823          	sd	a5,-528(s0)
    80005180:	a42d                	j	800053aa <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005182:	00003517          	auipc	a0,0x3
    80005186:	5ce50513          	addi	a0,a0,1486 # 80008750 <syscalls+0x280>
    8000518a:	ffffb097          	auipc	ra,0xffffb
    8000518e:	3b4080e7          	jalr	948(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005192:	8756                	mv	a4,s5
    80005194:	012d86bb          	addw	a3,s11,s2
    80005198:	4581                	li	a1,0
    8000519a:	8526                	mv	a0,s1
    8000519c:	fffff097          	auipc	ra,0xfffff
    800051a0:	cac080e7          	jalr	-852(ra) # 80003e48 <readi>
    800051a4:	2501                	sext.w	a0,a0
    800051a6:	1aaa9963          	bne	s5,a0,80005358 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800051aa:	6785                	lui	a5,0x1
    800051ac:	0127893b          	addw	s2,a5,s2
    800051b0:	77fd                	lui	a5,0xfffff
    800051b2:	01478a3b          	addw	s4,a5,s4
    800051b6:	1f897163          	bgeu	s2,s8,80005398 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800051ba:	02091593          	slli	a1,s2,0x20
    800051be:	9181                	srli	a1,a1,0x20
    800051c0:	95ea                	add	a1,a1,s10
    800051c2:	855e                	mv	a0,s7
    800051c4:	ffffc097          	auipc	ra,0xffffc
    800051c8:	eaa080e7          	jalr	-342(ra) # 8000106e <walkaddr>
    800051cc:	862a                	mv	a2,a0
    if(pa == 0)
    800051ce:	d955                	beqz	a0,80005182 <exec+0xf0>
      n = PGSIZE;
    800051d0:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800051d2:	fd9a70e3          	bgeu	s4,s9,80005192 <exec+0x100>
      n = sz - i;
    800051d6:	8ad2                	mv	s5,s4
    800051d8:	bf6d                	j	80005192 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051da:	4901                	li	s2,0
  iunlockput(ip);
    800051dc:	8526                	mv	a0,s1
    800051de:	fffff097          	auipc	ra,0xfffff
    800051e2:	c18080e7          	jalr	-1000(ra) # 80003df6 <iunlockput>
  end_op();
    800051e6:	fffff097          	auipc	ra,0xfffff
    800051ea:	400080e7          	jalr	1024(ra) # 800045e6 <end_op>
  p = myproc();
    800051ee:	ffffd097          	auipc	ra,0xffffd
    800051f2:	ae0080e7          	jalr	-1312(ra) # 80001cce <myproc>
    800051f6:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800051f8:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800051fc:	6785                	lui	a5,0x1
    800051fe:	17fd                	addi	a5,a5,-1
    80005200:	993e                	add	s2,s2,a5
    80005202:	757d                	lui	a0,0xfffff
    80005204:	00a977b3          	and	a5,s2,a0
    80005208:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000520c:	6609                	lui	a2,0x2
    8000520e:	963e                	add	a2,a2,a5
    80005210:	85be                	mv	a1,a5
    80005212:	855e                	mv	a0,s7
    80005214:	ffffc097          	auipc	ra,0xffffc
    80005218:	20e080e7          	jalr	526(ra) # 80001422 <uvmalloc>
    8000521c:	8b2a                	mv	s6,a0
  ip = 0;
    8000521e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005220:	12050c63          	beqz	a0,80005358 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005224:	75f9                	lui	a1,0xffffe
    80005226:	95aa                	add	a1,a1,a0
    80005228:	855e                	mv	a0,s7
    8000522a:	ffffc097          	auipc	ra,0xffffc
    8000522e:	416080e7          	jalr	1046(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005232:	7c7d                	lui	s8,0xfffff
    80005234:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005236:	e0043783          	ld	a5,-512(s0)
    8000523a:	6388                	ld	a0,0(a5)
    8000523c:	c535                	beqz	a0,800052a8 <exec+0x216>
    8000523e:	e9040993          	addi	s3,s0,-368
    80005242:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005246:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005248:	ffffc097          	auipc	ra,0xffffc
    8000524c:	c1c080e7          	jalr	-996(ra) # 80000e64 <strlen>
    80005250:	2505                	addiw	a0,a0,1
    80005252:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005256:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000525a:	13896363          	bltu	s2,s8,80005380 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000525e:	e0043d83          	ld	s11,-512(s0)
    80005262:	000dba03          	ld	s4,0(s11)
    80005266:	8552                	mv	a0,s4
    80005268:	ffffc097          	auipc	ra,0xffffc
    8000526c:	bfc080e7          	jalr	-1028(ra) # 80000e64 <strlen>
    80005270:	0015069b          	addiw	a3,a0,1
    80005274:	8652                	mv	a2,s4
    80005276:	85ca                	mv	a1,s2
    80005278:	855e                	mv	a0,s7
    8000527a:	ffffc097          	auipc	ra,0xffffc
    8000527e:	3f8080e7          	jalr	1016(ra) # 80001672 <copyout>
    80005282:	10054363          	bltz	a0,80005388 <exec+0x2f6>
    ustack[argc] = sp;
    80005286:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000528a:	0485                	addi	s1,s1,1
    8000528c:	008d8793          	addi	a5,s11,8
    80005290:	e0f43023          	sd	a5,-512(s0)
    80005294:	008db503          	ld	a0,8(s11)
    80005298:	c911                	beqz	a0,800052ac <exec+0x21a>
    if(argc >= MAXARG)
    8000529a:	09a1                	addi	s3,s3,8
    8000529c:	fb3c96e3          	bne	s9,s3,80005248 <exec+0x1b6>
  sz = sz1;
    800052a0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052a4:	4481                	li	s1,0
    800052a6:	a84d                	j	80005358 <exec+0x2c6>
  sp = sz;
    800052a8:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800052aa:	4481                	li	s1,0
  ustack[argc] = 0;
    800052ac:	00349793          	slli	a5,s1,0x3
    800052b0:	f9040713          	addi	a4,s0,-112
    800052b4:	97ba                	add	a5,a5,a4
    800052b6:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800052ba:	00148693          	addi	a3,s1,1
    800052be:	068e                	slli	a3,a3,0x3
    800052c0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800052c4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800052c8:	01897663          	bgeu	s2,s8,800052d4 <exec+0x242>
  sz = sz1;
    800052cc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052d0:	4481                	li	s1,0
    800052d2:	a059                	j	80005358 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800052d4:	e9040613          	addi	a2,s0,-368
    800052d8:	85ca                	mv	a1,s2
    800052da:	855e                	mv	a0,s7
    800052dc:	ffffc097          	auipc	ra,0xffffc
    800052e0:	396080e7          	jalr	918(ra) # 80001672 <copyout>
    800052e4:	0a054663          	bltz	a0,80005390 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800052e8:	058ab783          	ld	a5,88(s5)
    800052ec:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800052f0:	df843783          	ld	a5,-520(s0)
    800052f4:	0007c703          	lbu	a4,0(a5)
    800052f8:	cf11                	beqz	a4,80005314 <exec+0x282>
    800052fa:	0785                	addi	a5,a5,1
    if(*s == '/')
    800052fc:	02f00693          	li	a3,47
    80005300:	a039                	j	8000530e <exec+0x27c>
      last = s+1;
    80005302:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005306:	0785                	addi	a5,a5,1
    80005308:	fff7c703          	lbu	a4,-1(a5)
    8000530c:	c701                	beqz	a4,80005314 <exec+0x282>
    if(*s == '/')
    8000530e:	fed71ce3          	bne	a4,a3,80005306 <exec+0x274>
    80005312:	bfc5                	j	80005302 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005314:	4641                	li	a2,16
    80005316:	df843583          	ld	a1,-520(s0)
    8000531a:	158a8513          	addi	a0,s5,344
    8000531e:	ffffc097          	auipc	ra,0xffffc
    80005322:	b14080e7          	jalr	-1260(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005326:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000532a:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000532e:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005332:	058ab783          	ld	a5,88(s5)
    80005336:	e6843703          	ld	a4,-408(s0)
    8000533a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000533c:	058ab783          	ld	a5,88(s5)
    80005340:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005344:	85ea                	mv	a1,s10
    80005346:	ffffd097          	auipc	ra,0xffffd
    8000534a:	ae2080e7          	jalr	-1310(ra) # 80001e28 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000534e:	0004851b          	sext.w	a0,s1
    80005352:	bbe1                	j	8000512a <exec+0x98>
    80005354:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005358:	e0843583          	ld	a1,-504(s0)
    8000535c:	855e                	mv	a0,s7
    8000535e:	ffffd097          	auipc	ra,0xffffd
    80005362:	aca080e7          	jalr	-1334(ra) # 80001e28 <proc_freepagetable>
  if(ip){
    80005366:	da0498e3          	bnez	s1,80005116 <exec+0x84>
  return -1;
    8000536a:	557d                	li	a0,-1
    8000536c:	bb7d                	j	8000512a <exec+0x98>
    8000536e:	e1243423          	sd	s2,-504(s0)
    80005372:	b7dd                	j	80005358 <exec+0x2c6>
    80005374:	e1243423          	sd	s2,-504(s0)
    80005378:	b7c5                	j	80005358 <exec+0x2c6>
    8000537a:	e1243423          	sd	s2,-504(s0)
    8000537e:	bfe9                	j	80005358 <exec+0x2c6>
  sz = sz1;
    80005380:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005384:	4481                	li	s1,0
    80005386:	bfc9                	j	80005358 <exec+0x2c6>
  sz = sz1;
    80005388:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000538c:	4481                	li	s1,0
    8000538e:	b7e9                	j	80005358 <exec+0x2c6>
  sz = sz1;
    80005390:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005394:	4481                	li	s1,0
    80005396:	b7c9                	j	80005358 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005398:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000539c:	2b05                	addiw	s6,s6,1
    8000539e:	0389899b          	addiw	s3,s3,56
    800053a2:	e8845783          	lhu	a5,-376(s0)
    800053a6:	e2fb5be3          	bge	s6,a5,800051dc <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800053aa:	2981                	sext.w	s3,s3
    800053ac:	03800713          	li	a4,56
    800053b0:	86ce                	mv	a3,s3
    800053b2:	e1840613          	addi	a2,s0,-488
    800053b6:	4581                	li	a1,0
    800053b8:	8526                	mv	a0,s1
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	a8e080e7          	jalr	-1394(ra) # 80003e48 <readi>
    800053c2:	03800793          	li	a5,56
    800053c6:	f8f517e3          	bne	a0,a5,80005354 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800053ca:	e1842783          	lw	a5,-488(s0)
    800053ce:	4705                	li	a4,1
    800053d0:	fce796e3          	bne	a5,a4,8000539c <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800053d4:	e4043603          	ld	a2,-448(s0)
    800053d8:	e3843783          	ld	a5,-456(s0)
    800053dc:	f8f669e3          	bltu	a2,a5,8000536e <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053e0:	e2843783          	ld	a5,-472(s0)
    800053e4:	963e                	add	a2,a2,a5
    800053e6:	f8f667e3          	bltu	a2,a5,80005374 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053ea:	85ca                	mv	a1,s2
    800053ec:	855e                	mv	a0,s7
    800053ee:	ffffc097          	auipc	ra,0xffffc
    800053f2:	034080e7          	jalr	52(ra) # 80001422 <uvmalloc>
    800053f6:	e0a43423          	sd	a0,-504(s0)
    800053fa:	d141                	beqz	a0,8000537a <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800053fc:	e2843d03          	ld	s10,-472(s0)
    80005400:	df043783          	ld	a5,-528(s0)
    80005404:	00fd77b3          	and	a5,s10,a5
    80005408:	fba1                	bnez	a5,80005358 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000540a:	e2042d83          	lw	s11,-480(s0)
    8000540e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005412:	f80c03e3          	beqz	s8,80005398 <exec+0x306>
    80005416:	8a62                	mv	s4,s8
    80005418:	4901                	li	s2,0
    8000541a:	b345                	j	800051ba <exec+0x128>

000000008000541c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000541c:	7179                	addi	sp,sp,-48
    8000541e:	f406                	sd	ra,40(sp)
    80005420:	f022                	sd	s0,32(sp)
    80005422:	ec26                	sd	s1,24(sp)
    80005424:	e84a                	sd	s2,16(sp)
    80005426:	1800                	addi	s0,sp,48
    80005428:	892e                	mv	s2,a1
    8000542a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000542c:	fdc40593          	addi	a1,s0,-36
    80005430:	ffffe097          	auipc	ra,0xffffe
    80005434:	bf2080e7          	jalr	-1038(ra) # 80003022 <argint>
    80005438:	04054063          	bltz	a0,80005478 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000543c:	fdc42703          	lw	a4,-36(s0)
    80005440:	47bd                	li	a5,15
    80005442:	02e7ed63          	bltu	a5,a4,8000547c <argfd+0x60>
    80005446:	ffffd097          	auipc	ra,0xffffd
    8000544a:	888080e7          	jalr	-1912(ra) # 80001cce <myproc>
    8000544e:	fdc42703          	lw	a4,-36(s0)
    80005452:	01a70793          	addi	a5,a4,26
    80005456:	078e                	slli	a5,a5,0x3
    80005458:	953e                	add	a0,a0,a5
    8000545a:	611c                	ld	a5,0(a0)
    8000545c:	c395                	beqz	a5,80005480 <argfd+0x64>
    return -1;
  if(pfd)
    8000545e:	00090463          	beqz	s2,80005466 <argfd+0x4a>
    *pfd = fd;
    80005462:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005466:	4501                	li	a0,0
  if(pf)
    80005468:	c091                	beqz	s1,8000546c <argfd+0x50>
    *pf = f;
    8000546a:	e09c                	sd	a5,0(s1)
}
    8000546c:	70a2                	ld	ra,40(sp)
    8000546e:	7402                	ld	s0,32(sp)
    80005470:	64e2                	ld	s1,24(sp)
    80005472:	6942                	ld	s2,16(sp)
    80005474:	6145                	addi	sp,sp,48
    80005476:	8082                	ret
    return -1;
    80005478:	557d                	li	a0,-1
    8000547a:	bfcd                	j	8000546c <argfd+0x50>
    return -1;
    8000547c:	557d                	li	a0,-1
    8000547e:	b7fd                	j	8000546c <argfd+0x50>
    80005480:	557d                	li	a0,-1
    80005482:	b7ed                	j	8000546c <argfd+0x50>

0000000080005484 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005484:	1101                	addi	sp,sp,-32
    80005486:	ec06                	sd	ra,24(sp)
    80005488:	e822                	sd	s0,16(sp)
    8000548a:	e426                	sd	s1,8(sp)
    8000548c:	1000                	addi	s0,sp,32
    8000548e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005490:	ffffd097          	auipc	ra,0xffffd
    80005494:	83e080e7          	jalr	-1986(ra) # 80001cce <myproc>
    80005498:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000549a:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000549e:	4501                	li	a0,0
    800054a0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800054a2:	6398                	ld	a4,0(a5)
    800054a4:	cb19                	beqz	a4,800054ba <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800054a6:	2505                	addiw	a0,a0,1
    800054a8:	07a1                	addi	a5,a5,8
    800054aa:	fed51ce3          	bne	a0,a3,800054a2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800054ae:	557d                	li	a0,-1
}
    800054b0:	60e2                	ld	ra,24(sp)
    800054b2:	6442                	ld	s0,16(sp)
    800054b4:	64a2                	ld	s1,8(sp)
    800054b6:	6105                	addi	sp,sp,32
    800054b8:	8082                	ret
      p->ofile[fd] = f;
    800054ba:	01a50793          	addi	a5,a0,26
    800054be:	078e                	slli	a5,a5,0x3
    800054c0:	963e                	add	a2,a2,a5
    800054c2:	e204                	sd	s1,0(a2)
      return fd;
    800054c4:	b7f5                	j	800054b0 <fdalloc+0x2c>

00000000800054c6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054c6:	715d                	addi	sp,sp,-80
    800054c8:	e486                	sd	ra,72(sp)
    800054ca:	e0a2                	sd	s0,64(sp)
    800054cc:	fc26                	sd	s1,56(sp)
    800054ce:	f84a                	sd	s2,48(sp)
    800054d0:	f44e                	sd	s3,40(sp)
    800054d2:	f052                	sd	s4,32(sp)
    800054d4:	ec56                	sd	s5,24(sp)
    800054d6:	0880                	addi	s0,sp,80
    800054d8:	89ae                	mv	s3,a1
    800054da:	8ab2                	mv	s5,a2
    800054dc:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054de:	fb040593          	addi	a1,s0,-80
    800054e2:	fffff097          	auipc	ra,0xfffff
    800054e6:	e86080e7          	jalr	-378(ra) # 80004368 <nameiparent>
    800054ea:	892a                	mv	s2,a0
    800054ec:	12050f63          	beqz	a0,8000562a <create+0x164>
    return 0;

  ilock(dp);
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	6a4080e7          	jalr	1700(ra) # 80003b94 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054f8:	4601                	li	a2,0
    800054fa:	fb040593          	addi	a1,s0,-80
    800054fe:	854a                	mv	a0,s2
    80005500:	fffff097          	auipc	ra,0xfffff
    80005504:	b78080e7          	jalr	-1160(ra) # 80004078 <dirlookup>
    80005508:	84aa                	mv	s1,a0
    8000550a:	c921                	beqz	a0,8000555a <create+0x94>
    iunlockput(dp);
    8000550c:	854a                	mv	a0,s2
    8000550e:	fffff097          	auipc	ra,0xfffff
    80005512:	8e8080e7          	jalr	-1816(ra) # 80003df6 <iunlockput>
    ilock(ip);
    80005516:	8526                	mv	a0,s1
    80005518:	ffffe097          	auipc	ra,0xffffe
    8000551c:	67c080e7          	jalr	1660(ra) # 80003b94 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005520:	2981                	sext.w	s3,s3
    80005522:	4789                	li	a5,2
    80005524:	02f99463          	bne	s3,a5,8000554c <create+0x86>
    80005528:	0444d783          	lhu	a5,68(s1)
    8000552c:	37f9                	addiw	a5,a5,-2
    8000552e:	17c2                	slli	a5,a5,0x30
    80005530:	93c1                	srli	a5,a5,0x30
    80005532:	4705                	li	a4,1
    80005534:	00f76c63          	bltu	a4,a5,8000554c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005538:	8526                	mv	a0,s1
    8000553a:	60a6                	ld	ra,72(sp)
    8000553c:	6406                	ld	s0,64(sp)
    8000553e:	74e2                	ld	s1,56(sp)
    80005540:	7942                	ld	s2,48(sp)
    80005542:	79a2                	ld	s3,40(sp)
    80005544:	7a02                	ld	s4,32(sp)
    80005546:	6ae2                	ld	s5,24(sp)
    80005548:	6161                	addi	sp,sp,80
    8000554a:	8082                	ret
    iunlockput(ip);
    8000554c:	8526                	mv	a0,s1
    8000554e:	fffff097          	auipc	ra,0xfffff
    80005552:	8a8080e7          	jalr	-1880(ra) # 80003df6 <iunlockput>
    return 0;
    80005556:	4481                	li	s1,0
    80005558:	b7c5                	j	80005538 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000555a:	85ce                	mv	a1,s3
    8000555c:	00092503          	lw	a0,0(s2)
    80005560:	ffffe097          	auipc	ra,0xffffe
    80005564:	49c080e7          	jalr	1180(ra) # 800039fc <ialloc>
    80005568:	84aa                	mv	s1,a0
    8000556a:	c529                	beqz	a0,800055b4 <create+0xee>
  ilock(ip);
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	628080e7          	jalr	1576(ra) # 80003b94 <ilock>
  ip->major = major;
    80005574:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005578:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000557c:	4785                	li	a5,1
    8000557e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005582:	8526                	mv	a0,s1
    80005584:	ffffe097          	auipc	ra,0xffffe
    80005588:	546080e7          	jalr	1350(ra) # 80003aca <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000558c:	2981                	sext.w	s3,s3
    8000558e:	4785                	li	a5,1
    80005590:	02f98a63          	beq	s3,a5,800055c4 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005594:	40d0                	lw	a2,4(s1)
    80005596:	fb040593          	addi	a1,s0,-80
    8000559a:	854a                	mv	a0,s2
    8000559c:	fffff097          	auipc	ra,0xfffff
    800055a0:	cec080e7          	jalr	-788(ra) # 80004288 <dirlink>
    800055a4:	06054b63          	bltz	a0,8000561a <create+0x154>
  iunlockput(dp);
    800055a8:	854a                	mv	a0,s2
    800055aa:	fffff097          	auipc	ra,0xfffff
    800055ae:	84c080e7          	jalr	-1972(ra) # 80003df6 <iunlockput>
  return ip;
    800055b2:	b759                	j	80005538 <create+0x72>
    panic("create: ialloc");
    800055b4:	00003517          	auipc	a0,0x3
    800055b8:	1bc50513          	addi	a0,a0,444 # 80008770 <syscalls+0x2a0>
    800055bc:	ffffb097          	auipc	ra,0xffffb
    800055c0:	f82080e7          	jalr	-126(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800055c4:	04a95783          	lhu	a5,74(s2)
    800055c8:	2785                	addiw	a5,a5,1
    800055ca:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800055ce:	854a                	mv	a0,s2
    800055d0:	ffffe097          	auipc	ra,0xffffe
    800055d4:	4fa080e7          	jalr	1274(ra) # 80003aca <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055d8:	40d0                	lw	a2,4(s1)
    800055da:	00003597          	auipc	a1,0x3
    800055de:	1a658593          	addi	a1,a1,422 # 80008780 <syscalls+0x2b0>
    800055e2:	8526                	mv	a0,s1
    800055e4:	fffff097          	auipc	ra,0xfffff
    800055e8:	ca4080e7          	jalr	-860(ra) # 80004288 <dirlink>
    800055ec:	00054f63          	bltz	a0,8000560a <create+0x144>
    800055f0:	00492603          	lw	a2,4(s2)
    800055f4:	00003597          	auipc	a1,0x3
    800055f8:	19458593          	addi	a1,a1,404 # 80008788 <syscalls+0x2b8>
    800055fc:	8526                	mv	a0,s1
    800055fe:	fffff097          	auipc	ra,0xfffff
    80005602:	c8a080e7          	jalr	-886(ra) # 80004288 <dirlink>
    80005606:	f80557e3          	bgez	a0,80005594 <create+0xce>
      panic("create dots");
    8000560a:	00003517          	auipc	a0,0x3
    8000560e:	18650513          	addi	a0,a0,390 # 80008790 <syscalls+0x2c0>
    80005612:	ffffb097          	auipc	ra,0xffffb
    80005616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000561a:	00003517          	auipc	a0,0x3
    8000561e:	18650513          	addi	a0,a0,390 # 800087a0 <syscalls+0x2d0>
    80005622:	ffffb097          	auipc	ra,0xffffb
    80005626:	f1c080e7          	jalr	-228(ra) # 8000053e <panic>
    return 0;
    8000562a:	84aa                	mv	s1,a0
    8000562c:	b731                	j	80005538 <create+0x72>

000000008000562e <sys_dup>:
{
    8000562e:	7179                	addi	sp,sp,-48
    80005630:	f406                	sd	ra,40(sp)
    80005632:	f022                	sd	s0,32(sp)
    80005634:	ec26                	sd	s1,24(sp)
    80005636:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005638:	fd840613          	addi	a2,s0,-40
    8000563c:	4581                	li	a1,0
    8000563e:	4501                	li	a0,0
    80005640:	00000097          	auipc	ra,0x0
    80005644:	ddc080e7          	jalr	-548(ra) # 8000541c <argfd>
    return -1;
    80005648:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000564a:	02054363          	bltz	a0,80005670 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000564e:	fd843503          	ld	a0,-40(s0)
    80005652:	00000097          	auipc	ra,0x0
    80005656:	e32080e7          	jalr	-462(ra) # 80005484 <fdalloc>
    8000565a:	84aa                	mv	s1,a0
    return -1;
    8000565c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000565e:	00054963          	bltz	a0,80005670 <sys_dup+0x42>
  filedup(f);
    80005662:	fd843503          	ld	a0,-40(s0)
    80005666:	fffff097          	auipc	ra,0xfffff
    8000566a:	37a080e7          	jalr	890(ra) # 800049e0 <filedup>
  return fd;
    8000566e:	87a6                	mv	a5,s1
}
    80005670:	853e                	mv	a0,a5
    80005672:	70a2                	ld	ra,40(sp)
    80005674:	7402                	ld	s0,32(sp)
    80005676:	64e2                	ld	s1,24(sp)
    80005678:	6145                	addi	sp,sp,48
    8000567a:	8082                	ret

000000008000567c <sys_read>:
{
    8000567c:	7179                	addi	sp,sp,-48
    8000567e:	f406                	sd	ra,40(sp)
    80005680:	f022                	sd	s0,32(sp)
    80005682:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005684:	fe840613          	addi	a2,s0,-24
    80005688:	4581                	li	a1,0
    8000568a:	4501                	li	a0,0
    8000568c:	00000097          	auipc	ra,0x0
    80005690:	d90080e7          	jalr	-624(ra) # 8000541c <argfd>
    return -1;
    80005694:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005696:	04054163          	bltz	a0,800056d8 <sys_read+0x5c>
    8000569a:	fe440593          	addi	a1,s0,-28
    8000569e:	4509                	li	a0,2
    800056a0:	ffffe097          	auipc	ra,0xffffe
    800056a4:	982080e7          	jalr	-1662(ra) # 80003022 <argint>
    return -1;
    800056a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056aa:	02054763          	bltz	a0,800056d8 <sys_read+0x5c>
    800056ae:	fd840593          	addi	a1,s0,-40
    800056b2:	4505                	li	a0,1
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	990080e7          	jalr	-1648(ra) # 80003044 <argaddr>
    return -1;
    800056bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056be:	00054d63          	bltz	a0,800056d8 <sys_read+0x5c>
  return fileread(f, p, n);
    800056c2:	fe442603          	lw	a2,-28(s0)
    800056c6:	fd843583          	ld	a1,-40(s0)
    800056ca:	fe843503          	ld	a0,-24(s0)
    800056ce:	fffff097          	auipc	ra,0xfffff
    800056d2:	49e080e7          	jalr	1182(ra) # 80004b6c <fileread>
    800056d6:	87aa                	mv	a5,a0
}
    800056d8:	853e                	mv	a0,a5
    800056da:	70a2                	ld	ra,40(sp)
    800056dc:	7402                	ld	s0,32(sp)
    800056de:	6145                	addi	sp,sp,48
    800056e0:	8082                	ret

00000000800056e2 <sys_write>:
{
    800056e2:	7179                	addi	sp,sp,-48
    800056e4:	f406                	sd	ra,40(sp)
    800056e6:	f022                	sd	s0,32(sp)
    800056e8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056ea:	fe840613          	addi	a2,s0,-24
    800056ee:	4581                	li	a1,0
    800056f0:	4501                	li	a0,0
    800056f2:	00000097          	auipc	ra,0x0
    800056f6:	d2a080e7          	jalr	-726(ra) # 8000541c <argfd>
    return -1;
    800056fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056fc:	04054163          	bltz	a0,8000573e <sys_write+0x5c>
    80005700:	fe440593          	addi	a1,s0,-28
    80005704:	4509                	li	a0,2
    80005706:	ffffe097          	auipc	ra,0xffffe
    8000570a:	91c080e7          	jalr	-1764(ra) # 80003022 <argint>
    return -1;
    8000570e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005710:	02054763          	bltz	a0,8000573e <sys_write+0x5c>
    80005714:	fd840593          	addi	a1,s0,-40
    80005718:	4505                	li	a0,1
    8000571a:	ffffe097          	auipc	ra,0xffffe
    8000571e:	92a080e7          	jalr	-1750(ra) # 80003044 <argaddr>
    return -1;
    80005722:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005724:	00054d63          	bltz	a0,8000573e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005728:	fe442603          	lw	a2,-28(s0)
    8000572c:	fd843583          	ld	a1,-40(s0)
    80005730:	fe843503          	ld	a0,-24(s0)
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	4fa080e7          	jalr	1274(ra) # 80004c2e <filewrite>
    8000573c:	87aa                	mv	a5,a0
}
    8000573e:	853e                	mv	a0,a5
    80005740:	70a2                	ld	ra,40(sp)
    80005742:	7402                	ld	s0,32(sp)
    80005744:	6145                	addi	sp,sp,48
    80005746:	8082                	ret

0000000080005748 <sys_close>:
{
    80005748:	1101                	addi	sp,sp,-32
    8000574a:	ec06                	sd	ra,24(sp)
    8000574c:	e822                	sd	s0,16(sp)
    8000574e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005750:	fe040613          	addi	a2,s0,-32
    80005754:	fec40593          	addi	a1,s0,-20
    80005758:	4501                	li	a0,0
    8000575a:	00000097          	auipc	ra,0x0
    8000575e:	cc2080e7          	jalr	-830(ra) # 8000541c <argfd>
    return -1;
    80005762:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005764:	02054463          	bltz	a0,8000578c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005768:	ffffc097          	auipc	ra,0xffffc
    8000576c:	566080e7          	jalr	1382(ra) # 80001cce <myproc>
    80005770:	fec42783          	lw	a5,-20(s0)
    80005774:	07e9                	addi	a5,a5,26
    80005776:	078e                	slli	a5,a5,0x3
    80005778:	97aa                	add	a5,a5,a0
    8000577a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000577e:	fe043503          	ld	a0,-32(s0)
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	2b0080e7          	jalr	688(ra) # 80004a32 <fileclose>
  return 0;
    8000578a:	4781                	li	a5,0
}
    8000578c:	853e                	mv	a0,a5
    8000578e:	60e2                	ld	ra,24(sp)
    80005790:	6442                	ld	s0,16(sp)
    80005792:	6105                	addi	sp,sp,32
    80005794:	8082                	ret

0000000080005796 <sys_fstat>:
{
    80005796:	1101                	addi	sp,sp,-32
    80005798:	ec06                	sd	ra,24(sp)
    8000579a:	e822                	sd	s0,16(sp)
    8000579c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000579e:	fe840613          	addi	a2,s0,-24
    800057a2:	4581                	li	a1,0
    800057a4:	4501                	li	a0,0
    800057a6:	00000097          	auipc	ra,0x0
    800057aa:	c76080e7          	jalr	-906(ra) # 8000541c <argfd>
    return -1;
    800057ae:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057b0:	02054563          	bltz	a0,800057da <sys_fstat+0x44>
    800057b4:	fe040593          	addi	a1,s0,-32
    800057b8:	4505                	li	a0,1
    800057ba:	ffffe097          	auipc	ra,0xffffe
    800057be:	88a080e7          	jalr	-1910(ra) # 80003044 <argaddr>
    return -1;
    800057c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057c4:	00054b63          	bltz	a0,800057da <sys_fstat+0x44>
  return filestat(f, st);
    800057c8:	fe043583          	ld	a1,-32(s0)
    800057cc:	fe843503          	ld	a0,-24(s0)
    800057d0:	fffff097          	auipc	ra,0xfffff
    800057d4:	32a080e7          	jalr	810(ra) # 80004afa <filestat>
    800057d8:	87aa                	mv	a5,a0
}
    800057da:	853e                	mv	a0,a5
    800057dc:	60e2                	ld	ra,24(sp)
    800057de:	6442                	ld	s0,16(sp)
    800057e0:	6105                	addi	sp,sp,32
    800057e2:	8082                	ret

00000000800057e4 <sys_link>:
{
    800057e4:	7169                	addi	sp,sp,-304
    800057e6:	f606                	sd	ra,296(sp)
    800057e8:	f222                	sd	s0,288(sp)
    800057ea:	ee26                	sd	s1,280(sp)
    800057ec:	ea4a                	sd	s2,272(sp)
    800057ee:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057f0:	08000613          	li	a2,128
    800057f4:	ed040593          	addi	a1,s0,-304
    800057f8:	4501                	li	a0,0
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	86c080e7          	jalr	-1940(ra) # 80003066 <argstr>
    return -1;
    80005802:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005804:	10054e63          	bltz	a0,80005920 <sys_link+0x13c>
    80005808:	08000613          	li	a2,128
    8000580c:	f5040593          	addi	a1,s0,-176
    80005810:	4505                	li	a0,1
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	854080e7          	jalr	-1964(ra) # 80003066 <argstr>
    return -1;
    8000581a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000581c:	10054263          	bltz	a0,80005920 <sys_link+0x13c>
  begin_op();
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	d46080e7          	jalr	-698(ra) # 80004566 <begin_op>
  if((ip = namei(old)) == 0){
    80005828:	ed040513          	addi	a0,s0,-304
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	b1e080e7          	jalr	-1250(ra) # 8000434a <namei>
    80005834:	84aa                	mv	s1,a0
    80005836:	c551                	beqz	a0,800058c2 <sys_link+0xde>
  ilock(ip);
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	35c080e7          	jalr	860(ra) # 80003b94 <ilock>
  if(ip->type == T_DIR){
    80005840:	04449703          	lh	a4,68(s1)
    80005844:	4785                	li	a5,1
    80005846:	08f70463          	beq	a4,a5,800058ce <sys_link+0xea>
  ip->nlink++;
    8000584a:	04a4d783          	lhu	a5,74(s1)
    8000584e:	2785                	addiw	a5,a5,1
    80005850:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005854:	8526                	mv	a0,s1
    80005856:	ffffe097          	auipc	ra,0xffffe
    8000585a:	274080e7          	jalr	628(ra) # 80003aca <iupdate>
  iunlock(ip);
    8000585e:	8526                	mv	a0,s1
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	3f6080e7          	jalr	1014(ra) # 80003c56 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005868:	fd040593          	addi	a1,s0,-48
    8000586c:	f5040513          	addi	a0,s0,-176
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	af8080e7          	jalr	-1288(ra) # 80004368 <nameiparent>
    80005878:	892a                	mv	s2,a0
    8000587a:	c935                	beqz	a0,800058ee <sys_link+0x10a>
  ilock(dp);
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	318080e7          	jalr	792(ra) # 80003b94 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005884:	00092703          	lw	a4,0(s2)
    80005888:	409c                	lw	a5,0(s1)
    8000588a:	04f71d63          	bne	a4,a5,800058e4 <sys_link+0x100>
    8000588e:	40d0                	lw	a2,4(s1)
    80005890:	fd040593          	addi	a1,s0,-48
    80005894:	854a                	mv	a0,s2
    80005896:	fffff097          	auipc	ra,0xfffff
    8000589a:	9f2080e7          	jalr	-1550(ra) # 80004288 <dirlink>
    8000589e:	04054363          	bltz	a0,800058e4 <sys_link+0x100>
  iunlockput(dp);
    800058a2:	854a                	mv	a0,s2
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	552080e7          	jalr	1362(ra) # 80003df6 <iunlockput>
  iput(ip);
    800058ac:	8526                	mv	a0,s1
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	4a0080e7          	jalr	1184(ra) # 80003d4e <iput>
  end_op();
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	d30080e7          	jalr	-720(ra) # 800045e6 <end_op>
  return 0;
    800058be:	4781                	li	a5,0
    800058c0:	a085                	j	80005920 <sys_link+0x13c>
    end_op();
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	d24080e7          	jalr	-732(ra) # 800045e6 <end_op>
    return -1;
    800058ca:	57fd                	li	a5,-1
    800058cc:	a891                	j	80005920 <sys_link+0x13c>
    iunlockput(ip);
    800058ce:	8526                	mv	a0,s1
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	526080e7          	jalr	1318(ra) # 80003df6 <iunlockput>
    end_op();
    800058d8:	fffff097          	auipc	ra,0xfffff
    800058dc:	d0e080e7          	jalr	-754(ra) # 800045e6 <end_op>
    return -1;
    800058e0:	57fd                	li	a5,-1
    800058e2:	a83d                	j	80005920 <sys_link+0x13c>
    iunlockput(dp);
    800058e4:	854a                	mv	a0,s2
    800058e6:	ffffe097          	auipc	ra,0xffffe
    800058ea:	510080e7          	jalr	1296(ra) # 80003df6 <iunlockput>
  ilock(ip);
    800058ee:	8526                	mv	a0,s1
    800058f0:	ffffe097          	auipc	ra,0xffffe
    800058f4:	2a4080e7          	jalr	676(ra) # 80003b94 <ilock>
  ip->nlink--;
    800058f8:	04a4d783          	lhu	a5,74(s1)
    800058fc:	37fd                	addiw	a5,a5,-1
    800058fe:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005902:	8526                	mv	a0,s1
    80005904:	ffffe097          	auipc	ra,0xffffe
    80005908:	1c6080e7          	jalr	454(ra) # 80003aca <iupdate>
  iunlockput(ip);
    8000590c:	8526                	mv	a0,s1
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	4e8080e7          	jalr	1256(ra) # 80003df6 <iunlockput>
  end_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	cd0080e7          	jalr	-816(ra) # 800045e6 <end_op>
  return -1;
    8000591e:	57fd                	li	a5,-1
}
    80005920:	853e                	mv	a0,a5
    80005922:	70b2                	ld	ra,296(sp)
    80005924:	7412                	ld	s0,288(sp)
    80005926:	64f2                	ld	s1,280(sp)
    80005928:	6952                	ld	s2,272(sp)
    8000592a:	6155                	addi	sp,sp,304
    8000592c:	8082                	ret

000000008000592e <sys_unlink>:
{
    8000592e:	7151                	addi	sp,sp,-240
    80005930:	f586                	sd	ra,232(sp)
    80005932:	f1a2                	sd	s0,224(sp)
    80005934:	eda6                	sd	s1,216(sp)
    80005936:	e9ca                	sd	s2,208(sp)
    80005938:	e5ce                	sd	s3,200(sp)
    8000593a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000593c:	08000613          	li	a2,128
    80005940:	f3040593          	addi	a1,s0,-208
    80005944:	4501                	li	a0,0
    80005946:	ffffd097          	auipc	ra,0xffffd
    8000594a:	720080e7          	jalr	1824(ra) # 80003066 <argstr>
    8000594e:	18054163          	bltz	a0,80005ad0 <sys_unlink+0x1a2>
  begin_op();
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	c14080e7          	jalr	-1004(ra) # 80004566 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000595a:	fb040593          	addi	a1,s0,-80
    8000595e:	f3040513          	addi	a0,s0,-208
    80005962:	fffff097          	auipc	ra,0xfffff
    80005966:	a06080e7          	jalr	-1530(ra) # 80004368 <nameiparent>
    8000596a:	84aa                	mv	s1,a0
    8000596c:	c979                	beqz	a0,80005a42 <sys_unlink+0x114>
  ilock(dp);
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	226080e7          	jalr	550(ra) # 80003b94 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005976:	00003597          	auipc	a1,0x3
    8000597a:	e0a58593          	addi	a1,a1,-502 # 80008780 <syscalls+0x2b0>
    8000597e:	fb040513          	addi	a0,s0,-80
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	6dc080e7          	jalr	1756(ra) # 8000405e <namecmp>
    8000598a:	14050a63          	beqz	a0,80005ade <sys_unlink+0x1b0>
    8000598e:	00003597          	auipc	a1,0x3
    80005992:	dfa58593          	addi	a1,a1,-518 # 80008788 <syscalls+0x2b8>
    80005996:	fb040513          	addi	a0,s0,-80
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	6c4080e7          	jalr	1732(ra) # 8000405e <namecmp>
    800059a2:	12050e63          	beqz	a0,80005ade <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800059a6:	f2c40613          	addi	a2,s0,-212
    800059aa:	fb040593          	addi	a1,s0,-80
    800059ae:	8526                	mv	a0,s1
    800059b0:	ffffe097          	auipc	ra,0xffffe
    800059b4:	6c8080e7          	jalr	1736(ra) # 80004078 <dirlookup>
    800059b8:	892a                	mv	s2,a0
    800059ba:	12050263          	beqz	a0,80005ade <sys_unlink+0x1b0>
  ilock(ip);
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	1d6080e7          	jalr	470(ra) # 80003b94 <ilock>
  if(ip->nlink < 1)
    800059c6:	04a91783          	lh	a5,74(s2)
    800059ca:	08f05263          	blez	a5,80005a4e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059ce:	04491703          	lh	a4,68(s2)
    800059d2:	4785                	li	a5,1
    800059d4:	08f70563          	beq	a4,a5,80005a5e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800059d8:	4641                	li	a2,16
    800059da:	4581                	li	a1,0
    800059dc:	fc040513          	addi	a0,s0,-64
    800059e0:	ffffb097          	auipc	ra,0xffffb
    800059e4:	300080e7          	jalr	768(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059e8:	4741                	li	a4,16
    800059ea:	f2c42683          	lw	a3,-212(s0)
    800059ee:	fc040613          	addi	a2,s0,-64
    800059f2:	4581                	li	a1,0
    800059f4:	8526                	mv	a0,s1
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	54a080e7          	jalr	1354(ra) # 80003f40 <writei>
    800059fe:	47c1                	li	a5,16
    80005a00:	0af51563          	bne	a0,a5,80005aaa <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a04:	04491703          	lh	a4,68(s2)
    80005a08:	4785                	li	a5,1
    80005a0a:	0af70863          	beq	a4,a5,80005aba <sys_unlink+0x18c>
  iunlockput(dp);
    80005a0e:	8526                	mv	a0,s1
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	3e6080e7          	jalr	998(ra) # 80003df6 <iunlockput>
  ip->nlink--;
    80005a18:	04a95783          	lhu	a5,74(s2)
    80005a1c:	37fd                	addiw	a5,a5,-1
    80005a1e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a22:	854a                	mv	a0,s2
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	0a6080e7          	jalr	166(ra) # 80003aca <iupdate>
  iunlockput(ip);
    80005a2c:	854a                	mv	a0,s2
    80005a2e:	ffffe097          	auipc	ra,0xffffe
    80005a32:	3c8080e7          	jalr	968(ra) # 80003df6 <iunlockput>
  end_op();
    80005a36:	fffff097          	auipc	ra,0xfffff
    80005a3a:	bb0080e7          	jalr	-1104(ra) # 800045e6 <end_op>
  return 0;
    80005a3e:	4501                	li	a0,0
    80005a40:	a84d                	j	80005af2 <sys_unlink+0x1c4>
    end_op();
    80005a42:	fffff097          	auipc	ra,0xfffff
    80005a46:	ba4080e7          	jalr	-1116(ra) # 800045e6 <end_op>
    return -1;
    80005a4a:	557d                	li	a0,-1
    80005a4c:	a05d                	j	80005af2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a4e:	00003517          	auipc	a0,0x3
    80005a52:	d6250513          	addi	a0,a0,-670 # 800087b0 <syscalls+0x2e0>
    80005a56:	ffffb097          	auipc	ra,0xffffb
    80005a5a:	ae8080e7          	jalr	-1304(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a5e:	04c92703          	lw	a4,76(s2)
    80005a62:	02000793          	li	a5,32
    80005a66:	f6e7f9e3          	bgeu	a5,a4,800059d8 <sys_unlink+0xaa>
    80005a6a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a6e:	4741                	li	a4,16
    80005a70:	86ce                	mv	a3,s3
    80005a72:	f1840613          	addi	a2,s0,-232
    80005a76:	4581                	li	a1,0
    80005a78:	854a                	mv	a0,s2
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	3ce080e7          	jalr	974(ra) # 80003e48 <readi>
    80005a82:	47c1                	li	a5,16
    80005a84:	00f51b63          	bne	a0,a5,80005a9a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a88:	f1845783          	lhu	a5,-232(s0)
    80005a8c:	e7a1                	bnez	a5,80005ad4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a8e:	29c1                	addiw	s3,s3,16
    80005a90:	04c92783          	lw	a5,76(s2)
    80005a94:	fcf9ede3          	bltu	s3,a5,80005a6e <sys_unlink+0x140>
    80005a98:	b781                	j	800059d8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a9a:	00003517          	auipc	a0,0x3
    80005a9e:	d2e50513          	addi	a0,a0,-722 # 800087c8 <syscalls+0x2f8>
    80005aa2:	ffffb097          	auipc	ra,0xffffb
    80005aa6:	a9c080e7          	jalr	-1380(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005aaa:	00003517          	auipc	a0,0x3
    80005aae:	d3650513          	addi	a0,a0,-714 # 800087e0 <syscalls+0x310>
    80005ab2:	ffffb097          	auipc	ra,0xffffb
    80005ab6:	a8c080e7          	jalr	-1396(ra) # 8000053e <panic>
    dp->nlink--;
    80005aba:	04a4d783          	lhu	a5,74(s1)
    80005abe:	37fd                	addiw	a5,a5,-1
    80005ac0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ac4:	8526                	mv	a0,s1
    80005ac6:	ffffe097          	auipc	ra,0xffffe
    80005aca:	004080e7          	jalr	4(ra) # 80003aca <iupdate>
    80005ace:	b781                	j	80005a0e <sys_unlink+0xe0>
    return -1;
    80005ad0:	557d                	li	a0,-1
    80005ad2:	a005                	j	80005af2 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005ad4:	854a                	mv	a0,s2
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	320080e7          	jalr	800(ra) # 80003df6 <iunlockput>
  iunlockput(dp);
    80005ade:	8526                	mv	a0,s1
    80005ae0:	ffffe097          	auipc	ra,0xffffe
    80005ae4:	316080e7          	jalr	790(ra) # 80003df6 <iunlockput>
  end_op();
    80005ae8:	fffff097          	auipc	ra,0xfffff
    80005aec:	afe080e7          	jalr	-1282(ra) # 800045e6 <end_op>
  return -1;
    80005af0:	557d                	li	a0,-1
}
    80005af2:	70ae                	ld	ra,232(sp)
    80005af4:	740e                	ld	s0,224(sp)
    80005af6:	64ee                	ld	s1,216(sp)
    80005af8:	694e                	ld	s2,208(sp)
    80005afa:	69ae                	ld	s3,200(sp)
    80005afc:	616d                	addi	sp,sp,240
    80005afe:	8082                	ret

0000000080005b00 <sys_open>:

uint64
sys_open(void)
{
    80005b00:	7131                	addi	sp,sp,-192
    80005b02:	fd06                	sd	ra,184(sp)
    80005b04:	f922                	sd	s0,176(sp)
    80005b06:	f526                	sd	s1,168(sp)
    80005b08:	f14a                	sd	s2,160(sp)
    80005b0a:	ed4e                	sd	s3,152(sp)
    80005b0c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b0e:	08000613          	li	a2,128
    80005b12:	f5040593          	addi	a1,s0,-176
    80005b16:	4501                	li	a0,0
    80005b18:	ffffd097          	auipc	ra,0xffffd
    80005b1c:	54e080e7          	jalr	1358(ra) # 80003066 <argstr>
    return -1;
    80005b20:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b22:	0c054163          	bltz	a0,80005be4 <sys_open+0xe4>
    80005b26:	f4c40593          	addi	a1,s0,-180
    80005b2a:	4505                	li	a0,1
    80005b2c:	ffffd097          	auipc	ra,0xffffd
    80005b30:	4f6080e7          	jalr	1270(ra) # 80003022 <argint>
    80005b34:	0a054863          	bltz	a0,80005be4 <sys_open+0xe4>

  begin_op();
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	a2e080e7          	jalr	-1490(ra) # 80004566 <begin_op>

  if(omode & O_CREATE){
    80005b40:	f4c42783          	lw	a5,-180(s0)
    80005b44:	2007f793          	andi	a5,a5,512
    80005b48:	cbdd                	beqz	a5,80005bfe <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b4a:	4681                	li	a3,0
    80005b4c:	4601                	li	a2,0
    80005b4e:	4589                	li	a1,2
    80005b50:	f5040513          	addi	a0,s0,-176
    80005b54:	00000097          	auipc	ra,0x0
    80005b58:	972080e7          	jalr	-1678(ra) # 800054c6 <create>
    80005b5c:	892a                	mv	s2,a0
    if(ip == 0){
    80005b5e:	c959                	beqz	a0,80005bf4 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b60:	04491703          	lh	a4,68(s2)
    80005b64:	478d                	li	a5,3
    80005b66:	00f71763          	bne	a4,a5,80005b74 <sys_open+0x74>
    80005b6a:	04695703          	lhu	a4,70(s2)
    80005b6e:	47a5                	li	a5,9
    80005b70:	0ce7ec63          	bltu	a5,a4,80005c48 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b74:	fffff097          	auipc	ra,0xfffff
    80005b78:	e02080e7          	jalr	-510(ra) # 80004976 <filealloc>
    80005b7c:	89aa                	mv	s3,a0
    80005b7e:	10050263          	beqz	a0,80005c82 <sys_open+0x182>
    80005b82:	00000097          	auipc	ra,0x0
    80005b86:	902080e7          	jalr	-1790(ra) # 80005484 <fdalloc>
    80005b8a:	84aa                	mv	s1,a0
    80005b8c:	0e054663          	bltz	a0,80005c78 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b90:	04491703          	lh	a4,68(s2)
    80005b94:	478d                	li	a5,3
    80005b96:	0cf70463          	beq	a4,a5,80005c5e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b9a:	4789                	li	a5,2
    80005b9c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ba0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005ba4:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ba8:	f4c42783          	lw	a5,-180(s0)
    80005bac:	0017c713          	xori	a4,a5,1
    80005bb0:	8b05                	andi	a4,a4,1
    80005bb2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005bb6:	0037f713          	andi	a4,a5,3
    80005bba:	00e03733          	snez	a4,a4
    80005bbe:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005bc2:	4007f793          	andi	a5,a5,1024
    80005bc6:	c791                	beqz	a5,80005bd2 <sys_open+0xd2>
    80005bc8:	04491703          	lh	a4,68(s2)
    80005bcc:	4789                	li	a5,2
    80005bce:	08f70f63          	beq	a4,a5,80005c6c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005bd2:	854a                	mv	a0,s2
    80005bd4:	ffffe097          	auipc	ra,0xffffe
    80005bd8:	082080e7          	jalr	130(ra) # 80003c56 <iunlock>
  end_op();
    80005bdc:	fffff097          	auipc	ra,0xfffff
    80005be0:	a0a080e7          	jalr	-1526(ra) # 800045e6 <end_op>

  return fd;
}
    80005be4:	8526                	mv	a0,s1
    80005be6:	70ea                	ld	ra,184(sp)
    80005be8:	744a                	ld	s0,176(sp)
    80005bea:	74aa                	ld	s1,168(sp)
    80005bec:	790a                	ld	s2,160(sp)
    80005bee:	69ea                	ld	s3,152(sp)
    80005bf0:	6129                	addi	sp,sp,192
    80005bf2:	8082                	ret
      end_op();
    80005bf4:	fffff097          	auipc	ra,0xfffff
    80005bf8:	9f2080e7          	jalr	-1550(ra) # 800045e6 <end_op>
      return -1;
    80005bfc:	b7e5                	j	80005be4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005bfe:	f5040513          	addi	a0,s0,-176
    80005c02:	ffffe097          	auipc	ra,0xffffe
    80005c06:	748080e7          	jalr	1864(ra) # 8000434a <namei>
    80005c0a:	892a                	mv	s2,a0
    80005c0c:	c905                	beqz	a0,80005c3c <sys_open+0x13c>
    ilock(ip);
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	f86080e7          	jalr	-122(ra) # 80003b94 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c16:	04491703          	lh	a4,68(s2)
    80005c1a:	4785                	li	a5,1
    80005c1c:	f4f712e3          	bne	a4,a5,80005b60 <sys_open+0x60>
    80005c20:	f4c42783          	lw	a5,-180(s0)
    80005c24:	dba1                	beqz	a5,80005b74 <sys_open+0x74>
      iunlockput(ip);
    80005c26:	854a                	mv	a0,s2
    80005c28:	ffffe097          	auipc	ra,0xffffe
    80005c2c:	1ce080e7          	jalr	462(ra) # 80003df6 <iunlockput>
      end_op();
    80005c30:	fffff097          	auipc	ra,0xfffff
    80005c34:	9b6080e7          	jalr	-1610(ra) # 800045e6 <end_op>
      return -1;
    80005c38:	54fd                	li	s1,-1
    80005c3a:	b76d                	j	80005be4 <sys_open+0xe4>
      end_op();
    80005c3c:	fffff097          	auipc	ra,0xfffff
    80005c40:	9aa080e7          	jalr	-1622(ra) # 800045e6 <end_op>
      return -1;
    80005c44:	54fd                	li	s1,-1
    80005c46:	bf79                	j	80005be4 <sys_open+0xe4>
    iunlockput(ip);
    80005c48:	854a                	mv	a0,s2
    80005c4a:	ffffe097          	auipc	ra,0xffffe
    80005c4e:	1ac080e7          	jalr	428(ra) # 80003df6 <iunlockput>
    end_op();
    80005c52:	fffff097          	auipc	ra,0xfffff
    80005c56:	994080e7          	jalr	-1644(ra) # 800045e6 <end_op>
    return -1;
    80005c5a:	54fd                	li	s1,-1
    80005c5c:	b761                	j	80005be4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c5e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c62:	04691783          	lh	a5,70(s2)
    80005c66:	02f99223          	sh	a5,36(s3)
    80005c6a:	bf2d                	j	80005ba4 <sys_open+0xa4>
    itrunc(ip);
    80005c6c:	854a                	mv	a0,s2
    80005c6e:	ffffe097          	auipc	ra,0xffffe
    80005c72:	034080e7          	jalr	52(ra) # 80003ca2 <itrunc>
    80005c76:	bfb1                	j	80005bd2 <sys_open+0xd2>
      fileclose(f);
    80005c78:	854e                	mv	a0,s3
    80005c7a:	fffff097          	auipc	ra,0xfffff
    80005c7e:	db8080e7          	jalr	-584(ra) # 80004a32 <fileclose>
    iunlockput(ip);
    80005c82:	854a                	mv	a0,s2
    80005c84:	ffffe097          	auipc	ra,0xffffe
    80005c88:	172080e7          	jalr	370(ra) # 80003df6 <iunlockput>
    end_op();
    80005c8c:	fffff097          	auipc	ra,0xfffff
    80005c90:	95a080e7          	jalr	-1702(ra) # 800045e6 <end_op>
    return -1;
    80005c94:	54fd                	li	s1,-1
    80005c96:	b7b9                	j	80005be4 <sys_open+0xe4>

0000000080005c98 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c98:	7175                	addi	sp,sp,-144
    80005c9a:	e506                	sd	ra,136(sp)
    80005c9c:	e122                	sd	s0,128(sp)
    80005c9e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ca0:	fffff097          	auipc	ra,0xfffff
    80005ca4:	8c6080e7          	jalr	-1850(ra) # 80004566 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ca8:	08000613          	li	a2,128
    80005cac:	f7040593          	addi	a1,s0,-144
    80005cb0:	4501                	li	a0,0
    80005cb2:	ffffd097          	auipc	ra,0xffffd
    80005cb6:	3b4080e7          	jalr	948(ra) # 80003066 <argstr>
    80005cba:	02054963          	bltz	a0,80005cec <sys_mkdir+0x54>
    80005cbe:	4681                	li	a3,0
    80005cc0:	4601                	li	a2,0
    80005cc2:	4585                	li	a1,1
    80005cc4:	f7040513          	addi	a0,s0,-144
    80005cc8:	fffff097          	auipc	ra,0xfffff
    80005ccc:	7fe080e7          	jalr	2046(ra) # 800054c6 <create>
    80005cd0:	cd11                	beqz	a0,80005cec <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cd2:	ffffe097          	auipc	ra,0xffffe
    80005cd6:	124080e7          	jalr	292(ra) # 80003df6 <iunlockput>
  end_op();
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	90c080e7          	jalr	-1780(ra) # 800045e6 <end_op>
  return 0;
    80005ce2:	4501                	li	a0,0
}
    80005ce4:	60aa                	ld	ra,136(sp)
    80005ce6:	640a                	ld	s0,128(sp)
    80005ce8:	6149                	addi	sp,sp,144
    80005cea:	8082                	ret
    end_op();
    80005cec:	fffff097          	auipc	ra,0xfffff
    80005cf0:	8fa080e7          	jalr	-1798(ra) # 800045e6 <end_op>
    return -1;
    80005cf4:	557d                	li	a0,-1
    80005cf6:	b7fd                	j	80005ce4 <sys_mkdir+0x4c>

0000000080005cf8 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005cf8:	7135                	addi	sp,sp,-160
    80005cfa:	ed06                	sd	ra,152(sp)
    80005cfc:	e922                	sd	s0,144(sp)
    80005cfe:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d00:	fffff097          	auipc	ra,0xfffff
    80005d04:	866080e7          	jalr	-1946(ra) # 80004566 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d08:	08000613          	li	a2,128
    80005d0c:	f7040593          	addi	a1,s0,-144
    80005d10:	4501                	li	a0,0
    80005d12:	ffffd097          	auipc	ra,0xffffd
    80005d16:	354080e7          	jalr	852(ra) # 80003066 <argstr>
    80005d1a:	04054a63          	bltz	a0,80005d6e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d1e:	f6c40593          	addi	a1,s0,-148
    80005d22:	4505                	li	a0,1
    80005d24:	ffffd097          	auipc	ra,0xffffd
    80005d28:	2fe080e7          	jalr	766(ra) # 80003022 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d2c:	04054163          	bltz	a0,80005d6e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d30:	f6840593          	addi	a1,s0,-152
    80005d34:	4509                	li	a0,2
    80005d36:	ffffd097          	auipc	ra,0xffffd
    80005d3a:	2ec080e7          	jalr	748(ra) # 80003022 <argint>
     argint(1, &major) < 0 ||
    80005d3e:	02054863          	bltz	a0,80005d6e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d42:	f6841683          	lh	a3,-152(s0)
    80005d46:	f6c41603          	lh	a2,-148(s0)
    80005d4a:	458d                	li	a1,3
    80005d4c:	f7040513          	addi	a0,s0,-144
    80005d50:	fffff097          	auipc	ra,0xfffff
    80005d54:	776080e7          	jalr	1910(ra) # 800054c6 <create>
     argint(2, &minor) < 0 ||
    80005d58:	c919                	beqz	a0,80005d6e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d5a:	ffffe097          	auipc	ra,0xffffe
    80005d5e:	09c080e7          	jalr	156(ra) # 80003df6 <iunlockput>
  end_op();
    80005d62:	fffff097          	auipc	ra,0xfffff
    80005d66:	884080e7          	jalr	-1916(ra) # 800045e6 <end_op>
  return 0;
    80005d6a:	4501                	li	a0,0
    80005d6c:	a031                	j	80005d78 <sys_mknod+0x80>
    end_op();
    80005d6e:	fffff097          	auipc	ra,0xfffff
    80005d72:	878080e7          	jalr	-1928(ra) # 800045e6 <end_op>
    return -1;
    80005d76:	557d                	li	a0,-1
}
    80005d78:	60ea                	ld	ra,152(sp)
    80005d7a:	644a                	ld	s0,144(sp)
    80005d7c:	610d                	addi	sp,sp,160
    80005d7e:	8082                	ret

0000000080005d80 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d80:	7135                	addi	sp,sp,-160
    80005d82:	ed06                	sd	ra,152(sp)
    80005d84:	e922                	sd	s0,144(sp)
    80005d86:	e526                	sd	s1,136(sp)
    80005d88:	e14a                	sd	s2,128(sp)
    80005d8a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d8c:	ffffc097          	auipc	ra,0xffffc
    80005d90:	f42080e7          	jalr	-190(ra) # 80001cce <myproc>
    80005d94:	892a                	mv	s2,a0
  
  begin_op();
    80005d96:	ffffe097          	auipc	ra,0xffffe
    80005d9a:	7d0080e7          	jalr	2000(ra) # 80004566 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d9e:	08000613          	li	a2,128
    80005da2:	f6040593          	addi	a1,s0,-160
    80005da6:	4501                	li	a0,0
    80005da8:	ffffd097          	auipc	ra,0xffffd
    80005dac:	2be080e7          	jalr	702(ra) # 80003066 <argstr>
    80005db0:	04054b63          	bltz	a0,80005e06 <sys_chdir+0x86>
    80005db4:	f6040513          	addi	a0,s0,-160
    80005db8:	ffffe097          	auipc	ra,0xffffe
    80005dbc:	592080e7          	jalr	1426(ra) # 8000434a <namei>
    80005dc0:	84aa                	mv	s1,a0
    80005dc2:	c131                	beqz	a0,80005e06 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005dc4:	ffffe097          	auipc	ra,0xffffe
    80005dc8:	dd0080e7          	jalr	-560(ra) # 80003b94 <ilock>
  if(ip->type != T_DIR){
    80005dcc:	04449703          	lh	a4,68(s1)
    80005dd0:	4785                	li	a5,1
    80005dd2:	04f71063          	bne	a4,a5,80005e12 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005dd6:	8526                	mv	a0,s1
    80005dd8:	ffffe097          	auipc	ra,0xffffe
    80005ddc:	e7e080e7          	jalr	-386(ra) # 80003c56 <iunlock>
  iput(p->cwd);
    80005de0:	15093503          	ld	a0,336(s2)
    80005de4:	ffffe097          	auipc	ra,0xffffe
    80005de8:	f6a080e7          	jalr	-150(ra) # 80003d4e <iput>
  end_op();
    80005dec:	ffffe097          	auipc	ra,0xffffe
    80005df0:	7fa080e7          	jalr	2042(ra) # 800045e6 <end_op>
  p->cwd = ip;
    80005df4:	14993823          	sd	s1,336(s2)
  return 0;
    80005df8:	4501                	li	a0,0
}
    80005dfa:	60ea                	ld	ra,152(sp)
    80005dfc:	644a                	ld	s0,144(sp)
    80005dfe:	64aa                	ld	s1,136(sp)
    80005e00:	690a                	ld	s2,128(sp)
    80005e02:	610d                	addi	sp,sp,160
    80005e04:	8082                	ret
    end_op();
    80005e06:	ffffe097          	auipc	ra,0xffffe
    80005e0a:	7e0080e7          	jalr	2016(ra) # 800045e6 <end_op>
    return -1;
    80005e0e:	557d                	li	a0,-1
    80005e10:	b7ed                	j	80005dfa <sys_chdir+0x7a>
    iunlockput(ip);
    80005e12:	8526                	mv	a0,s1
    80005e14:	ffffe097          	auipc	ra,0xffffe
    80005e18:	fe2080e7          	jalr	-30(ra) # 80003df6 <iunlockput>
    end_op();
    80005e1c:	ffffe097          	auipc	ra,0xffffe
    80005e20:	7ca080e7          	jalr	1994(ra) # 800045e6 <end_op>
    return -1;
    80005e24:	557d                	li	a0,-1
    80005e26:	bfd1                	j	80005dfa <sys_chdir+0x7a>

0000000080005e28 <sys_exec>:

uint64
sys_exec(void)
{
    80005e28:	7145                	addi	sp,sp,-464
    80005e2a:	e786                	sd	ra,456(sp)
    80005e2c:	e3a2                	sd	s0,448(sp)
    80005e2e:	ff26                	sd	s1,440(sp)
    80005e30:	fb4a                	sd	s2,432(sp)
    80005e32:	f74e                	sd	s3,424(sp)
    80005e34:	f352                	sd	s4,416(sp)
    80005e36:	ef56                	sd	s5,408(sp)
    80005e38:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e3a:	08000613          	li	a2,128
    80005e3e:	f4040593          	addi	a1,s0,-192
    80005e42:	4501                	li	a0,0
    80005e44:	ffffd097          	auipc	ra,0xffffd
    80005e48:	222080e7          	jalr	546(ra) # 80003066 <argstr>
    return -1;
    80005e4c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e4e:	0c054a63          	bltz	a0,80005f22 <sys_exec+0xfa>
    80005e52:	e3840593          	addi	a1,s0,-456
    80005e56:	4505                	li	a0,1
    80005e58:	ffffd097          	auipc	ra,0xffffd
    80005e5c:	1ec080e7          	jalr	492(ra) # 80003044 <argaddr>
    80005e60:	0c054163          	bltz	a0,80005f22 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e64:	10000613          	li	a2,256
    80005e68:	4581                	li	a1,0
    80005e6a:	e4040513          	addi	a0,s0,-448
    80005e6e:	ffffb097          	auipc	ra,0xffffb
    80005e72:	e72080e7          	jalr	-398(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e76:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e7a:	89a6                	mv	s3,s1
    80005e7c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e7e:	02000a13          	li	s4,32
    80005e82:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e86:	00391513          	slli	a0,s2,0x3
    80005e8a:	e3040593          	addi	a1,s0,-464
    80005e8e:	e3843783          	ld	a5,-456(s0)
    80005e92:	953e                	add	a0,a0,a5
    80005e94:	ffffd097          	auipc	ra,0xffffd
    80005e98:	0f4080e7          	jalr	244(ra) # 80002f88 <fetchaddr>
    80005e9c:	02054a63          	bltz	a0,80005ed0 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ea0:	e3043783          	ld	a5,-464(s0)
    80005ea4:	c3b9                	beqz	a5,80005eea <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ea6:	ffffb097          	auipc	ra,0xffffb
    80005eaa:	c4e080e7          	jalr	-946(ra) # 80000af4 <kalloc>
    80005eae:	85aa                	mv	a1,a0
    80005eb0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005eb4:	cd11                	beqz	a0,80005ed0 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005eb6:	6605                	lui	a2,0x1
    80005eb8:	e3043503          	ld	a0,-464(s0)
    80005ebc:	ffffd097          	auipc	ra,0xffffd
    80005ec0:	11e080e7          	jalr	286(ra) # 80002fda <fetchstr>
    80005ec4:	00054663          	bltz	a0,80005ed0 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ec8:	0905                	addi	s2,s2,1
    80005eca:	09a1                	addi	s3,s3,8
    80005ecc:	fb491be3          	bne	s2,s4,80005e82 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ed0:	10048913          	addi	s2,s1,256
    80005ed4:	6088                	ld	a0,0(s1)
    80005ed6:	c529                	beqz	a0,80005f20 <sys_exec+0xf8>
    kfree(argv[i]);
    80005ed8:	ffffb097          	auipc	ra,0xffffb
    80005edc:	b20080e7          	jalr	-1248(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ee0:	04a1                	addi	s1,s1,8
    80005ee2:	ff2499e3          	bne	s1,s2,80005ed4 <sys_exec+0xac>
  return -1;
    80005ee6:	597d                	li	s2,-1
    80005ee8:	a82d                	j	80005f22 <sys_exec+0xfa>
      argv[i] = 0;
    80005eea:	0a8e                	slli	s5,s5,0x3
    80005eec:	fc040793          	addi	a5,s0,-64
    80005ef0:	9abe                	add	s5,s5,a5
    80005ef2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ef6:	e4040593          	addi	a1,s0,-448
    80005efa:	f4040513          	addi	a0,s0,-192
    80005efe:	fffff097          	auipc	ra,0xfffff
    80005f02:	194080e7          	jalr	404(ra) # 80005092 <exec>
    80005f06:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f08:	10048993          	addi	s3,s1,256
    80005f0c:	6088                	ld	a0,0(s1)
    80005f0e:	c911                	beqz	a0,80005f22 <sys_exec+0xfa>
    kfree(argv[i]);
    80005f10:	ffffb097          	auipc	ra,0xffffb
    80005f14:	ae8080e7          	jalr	-1304(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f18:	04a1                	addi	s1,s1,8
    80005f1a:	ff3499e3          	bne	s1,s3,80005f0c <sys_exec+0xe4>
    80005f1e:	a011                	j	80005f22 <sys_exec+0xfa>
  return -1;
    80005f20:	597d                	li	s2,-1
}
    80005f22:	854a                	mv	a0,s2
    80005f24:	60be                	ld	ra,456(sp)
    80005f26:	641e                	ld	s0,448(sp)
    80005f28:	74fa                	ld	s1,440(sp)
    80005f2a:	795a                	ld	s2,432(sp)
    80005f2c:	79ba                	ld	s3,424(sp)
    80005f2e:	7a1a                	ld	s4,416(sp)
    80005f30:	6afa                	ld	s5,408(sp)
    80005f32:	6179                	addi	sp,sp,464
    80005f34:	8082                	ret

0000000080005f36 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f36:	7139                	addi	sp,sp,-64
    80005f38:	fc06                	sd	ra,56(sp)
    80005f3a:	f822                	sd	s0,48(sp)
    80005f3c:	f426                	sd	s1,40(sp)
    80005f3e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f40:	ffffc097          	auipc	ra,0xffffc
    80005f44:	d8e080e7          	jalr	-626(ra) # 80001cce <myproc>
    80005f48:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f4a:	fd840593          	addi	a1,s0,-40
    80005f4e:	4501                	li	a0,0
    80005f50:	ffffd097          	auipc	ra,0xffffd
    80005f54:	0f4080e7          	jalr	244(ra) # 80003044 <argaddr>
    return -1;
    80005f58:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f5a:	0e054063          	bltz	a0,8000603a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f5e:	fc840593          	addi	a1,s0,-56
    80005f62:	fd040513          	addi	a0,s0,-48
    80005f66:	fffff097          	auipc	ra,0xfffff
    80005f6a:	dfc080e7          	jalr	-516(ra) # 80004d62 <pipealloc>
    return -1;
    80005f6e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f70:	0c054563          	bltz	a0,8000603a <sys_pipe+0x104>
  fd0 = -1;
    80005f74:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f78:	fd043503          	ld	a0,-48(s0)
    80005f7c:	fffff097          	auipc	ra,0xfffff
    80005f80:	508080e7          	jalr	1288(ra) # 80005484 <fdalloc>
    80005f84:	fca42223          	sw	a0,-60(s0)
    80005f88:	08054c63          	bltz	a0,80006020 <sys_pipe+0xea>
    80005f8c:	fc843503          	ld	a0,-56(s0)
    80005f90:	fffff097          	auipc	ra,0xfffff
    80005f94:	4f4080e7          	jalr	1268(ra) # 80005484 <fdalloc>
    80005f98:	fca42023          	sw	a0,-64(s0)
    80005f9c:	06054863          	bltz	a0,8000600c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fa0:	4691                	li	a3,4
    80005fa2:	fc440613          	addi	a2,s0,-60
    80005fa6:	fd843583          	ld	a1,-40(s0)
    80005faa:	68a8                	ld	a0,80(s1)
    80005fac:	ffffb097          	auipc	ra,0xffffb
    80005fb0:	6c6080e7          	jalr	1734(ra) # 80001672 <copyout>
    80005fb4:	02054063          	bltz	a0,80005fd4 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005fb8:	4691                	li	a3,4
    80005fba:	fc040613          	addi	a2,s0,-64
    80005fbe:	fd843583          	ld	a1,-40(s0)
    80005fc2:	0591                	addi	a1,a1,4
    80005fc4:	68a8                	ld	a0,80(s1)
    80005fc6:	ffffb097          	auipc	ra,0xffffb
    80005fca:	6ac080e7          	jalr	1708(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fce:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fd0:	06055563          	bgez	a0,8000603a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005fd4:	fc442783          	lw	a5,-60(s0)
    80005fd8:	07e9                	addi	a5,a5,26
    80005fda:	078e                	slli	a5,a5,0x3
    80005fdc:	97a6                	add	a5,a5,s1
    80005fde:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005fe2:	fc042503          	lw	a0,-64(s0)
    80005fe6:	0569                	addi	a0,a0,26
    80005fe8:	050e                	slli	a0,a0,0x3
    80005fea:	9526                	add	a0,a0,s1
    80005fec:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ff0:	fd043503          	ld	a0,-48(s0)
    80005ff4:	fffff097          	auipc	ra,0xfffff
    80005ff8:	a3e080e7          	jalr	-1474(ra) # 80004a32 <fileclose>
    fileclose(wf);
    80005ffc:	fc843503          	ld	a0,-56(s0)
    80006000:	fffff097          	auipc	ra,0xfffff
    80006004:	a32080e7          	jalr	-1486(ra) # 80004a32 <fileclose>
    return -1;
    80006008:	57fd                	li	a5,-1
    8000600a:	a805                	j	8000603a <sys_pipe+0x104>
    if(fd0 >= 0)
    8000600c:	fc442783          	lw	a5,-60(s0)
    80006010:	0007c863          	bltz	a5,80006020 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006014:	01a78513          	addi	a0,a5,26
    80006018:	050e                	slli	a0,a0,0x3
    8000601a:	9526                	add	a0,a0,s1
    8000601c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006020:	fd043503          	ld	a0,-48(s0)
    80006024:	fffff097          	auipc	ra,0xfffff
    80006028:	a0e080e7          	jalr	-1522(ra) # 80004a32 <fileclose>
    fileclose(wf);
    8000602c:	fc843503          	ld	a0,-56(s0)
    80006030:	fffff097          	auipc	ra,0xfffff
    80006034:	a02080e7          	jalr	-1534(ra) # 80004a32 <fileclose>
    return -1;
    80006038:	57fd                	li	a5,-1
}
    8000603a:	853e                	mv	a0,a5
    8000603c:	70e2                	ld	ra,56(sp)
    8000603e:	7442                	ld	s0,48(sp)
    80006040:	74a2                	ld	s1,40(sp)
    80006042:	6121                	addi	sp,sp,64
    80006044:	8082                	ret
	...

0000000080006050 <kernelvec>:
    80006050:	7111                	addi	sp,sp,-256
    80006052:	e006                	sd	ra,0(sp)
    80006054:	e40a                	sd	sp,8(sp)
    80006056:	e80e                	sd	gp,16(sp)
    80006058:	ec12                	sd	tp,24(sp)
    8000605a:	f016                	sd	t0,32(sp)
    8000605c:	f41a                	sd	t1,40(sp)
    8000605e:	f81e                	sd	t2,48(sp)
    80006060:	fc22                	sd	s0,56(sp)
    80006062:	e0a6                	sd	s1,64(sp)
    80006064:	e4aa                	sd	a0,72(sp)
    80006066:	e8ae                	sd	a1,80(sp)
    80006068:	ecb2                	sd	a2,88(sp)
    8000606a:	f0b6                	sd	a3,96(sp)
    8000606c:	f4ba                	sd	a4,104(sp)
    8000606e:	f8be                	sd	a5,112(sp)
    80006070:	fcc2                	sd	a6,120(sp)
    80006072:	e146                	sd	a7,128(sp)
    80006074:	e54a                	sd	s2,136(sp)
    80006076:	e94e                	sd	s3,144(sp)
    80006078:	ed52                	sd	s4,152(sp)
    8000607a:	f156                	sd	s5,160(sp)
    8000607c:	f55a                	sd	s6,168(sp)
    8000607e:	f95e                	sd	s7,176(sp)
    80006080:	fd62                	sd	s8,184(sp)
    80006082:	e1e6                	sd	s9,192(sp)
    80006084:	e5ea                	sd	s10,200(sp)
    80006086:	e9ee                	sd	s11,208(sp)
    80006088:	edf2                	sd	t3,216(sp)
    8000608a:	f1f6                	sd	t4,224(sp)
    8000608c:	f5fa                	sd	t5,232(sp)
    8000608e:	f9fe                	sd	t6,240(sp)
    80006090:	dc5fc0ef          	jal	ra,80002e54 <kerneltrap>
    80006094:	6082                	ld	ra,0(sp)
    80006096:	6122                	ld	sp,8(sp)
    80006098:	61c2                	ld	gp,16(sp)
    8000609a:	7282                	ld	t0,32(sp)
    8000609c:	7322                	ld	t1,40(sp)
    8000609e:	73c2                	ld	t2,48(sp)
    800060a0:	7462                	ld	s0,56(sp)
    800060a2:	6486                	ld	s1,64(sp)
    800060a4:	6526                	ld	a0,72(sp)
    800060a6:	65c6                	ld	a1,80(sp)
    800060a8:	6666                	ld	a2,88(sp)
    800060aa:	7686                	ld	a3,96(sp)
    800060ac:	7726                	ld	a4,104(sp)
    800060ae:	77c6                	ld	a5,112(sp)
    800060b0:	7866                	ld	a6,120(sp)
    800060b2:	688a                	ld	a7,128(sp)
    800060b4:	692a                	ld	s2,136(sp)
    800060b6:	69ca                	ld	s3,144(sp)
    800060b8:	6a6a                	ld	s4,152(sp)
    800060ba:	7a8a                	ld	s5,160(sp)
    800060bc:	7b2a                	ld	s6,168(sp)
    800060be:	7bca                	ld	s7,176(sp)
    800060c0:	7c6a                	ld	s8,184(sp)
    800060c2:	6c8e                	ld	s9,192(sp)
    800060c4:	6d2e                	ld	s10,200(sp)
    800060c6:	6dce                	ld	s11,208(sp)
    800060c8:	6e6e                	ld	t3,216(sp)
    800060ca:	7e8e                	ld	t4,224(sp)
    800060cc:	7f2e                	ld	t5,232(sp)
    800060ce:	7fce                	ld	t6,240(sp)
    800060d0:	6111                	addi	sp,sp,256
    800060d2:	10200073          	sret
    800060d6:	00000013          	nop
    800060da:	00000013          	nop
    800060de:	0001                	nop

00000000800060e0 <timervec>:
    800060e0:	34051573          	csrrw	a0,mscratch,a0
    800060e4:	e10c                	sd	a1,0(a0)
    800060e6:	e510                	sd	a2,8(a0)
    800060e8:	e914                	sd	a3,16(a0)
    800060ea:	6d0c                	ld	a1,24(a0)
    800060ec:	7110                	ld	a2,32(a0)
    800060ee:	6194                	ld	a3,0(a1)
    800060f0:	96b2                	add	a3,a3,a2
    800060f2:	e194                	sd	a3,0(a1)
    800060f4:	4589                	li	a1,2
    800060f6:	14459073          	csrw	sip,a1
    800060fa:	6914                	ld	a3,16(a0)
    800060fc:	6510                	ld	a2,8(a0)
    800060fe:	610c                	ld	a1,0(a0)
    80006100:	34051573          	csrrw	a0,mscratch,a0
    80006104:	30200073          	mret
	...

000000008000610a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000610a:	1141                	addi	sp,sp,-16
    8000610c:	e422                	sd	s0,8(sp)
    8000610e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006110:	0c0007b7          	lui	a5,0xc000
    80006114:	4705                	li	a4,1
    80006116:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006118:	c3d8                	sw	a4,4(a5)
}
    8000611a:	6422                	ld	s0,8(sp)
    8000611c:	0141                	addi	sp,sp,16
    8000611e:	8082                	ret

0000000080006120 <plicinithart>:

void
plicinithart(void)
{
    80006120:	1141                	addi	sp,sp,-16
    80006122:	e406                	sd	ra,8(sp)
    80006124:	e022                	sd	s0,0(sp)
    80006126:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006128:	ffffc097          	auipc	ra,0xffffc
    8000612c:	b74080e7          	jalr	-1164(ra) # 80001c9c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006130:	0085171b          	slliw	a4,a0,0x8
    80006134:	0c0027b7          	lui	a5,0xc002
    80006138:	97ba                	add	a5,a5,a4
    8000613a:	40200713          	li	a4,1026
    8000613e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006142:	00d5151b          	slliw	a0,a0,0xd
    80006146:	0c2017b7          	lui	a5,0xc201
    8000614a:	953e                	add	a0,a0,a5
    8000614c:	00052023          	sw	zero,0(a0)
}
    80006150:	60a2                	ld	ra,8(sp)
    80006152:	6402                	ld	s0,0(sp)
    80006154:	0141                	addi	sp,sp,16
    80006156:	8082                	ret

0000000080006158 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006158:	1141                	addi	sp,sp,-16
    8000615a:	e406                	sd	ra,8(sp)
    8000615c:	e022                	sd	s0,0(sp)
    8000615e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006160:	ffffc097          	auipc	ra,0xffffc
    80006164:	b3c080e7          	jalr	-1220(ra) # 80001c9c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006168:	00d5179b          	slliw	a5,a0,0xd
    8000616c:	0c201537          	lui	a0,0xc201
    80006170:	953e                	add	a0,a0,a5
  return irq;
}
    80006172:	4148                	lw	a0,4(a0)
    80006174:	60a2                	ld	ra,8(sp)
    80006176:	6402                	ld	s0,0(sp)
    80006178:	0141                	addi	sp,sp,16
    8000617a:	8082                	ret

000000008000617c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000617c:	1101                	addi	sp,sp,-32
    8000617e:	ec06                	sd	ra,24(sp)
    80006180:	e822                	sd	s0,16(sp)
    80006182:	e426                	sd	s1,8(sp)
    80006184:	1000                	addi	s0,sp,32
    80006186:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006188:	ffffc097          	auipc	ra,0xffffc
    8000618c:	b14080e7          	jalr	-1260(ra) # 80001c9c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006190:	00d5151b          	slliw	a0,a0,0xd
    80006194:	0c2017b7          	lui	a5,0xc201
    80006198:	97aa                	add	a5,a5,a0
    8000619a:	c3c4                	sw	s1,4(a5)
}
    8000619c:	60e2                	ld	ra,24(sp)
    8000619e:	6442                	ld	s0,16(sp)
    800061a0:	64a2                	ld	s1,8(sp)
    800061a2:	6105                	addi	sp,sp,32
    800061a4:	8082                	ret

00000000800061a6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800061a6:	1141                	addi	sp,sp,-16
    800061a8:	e406                	sd	ra,8(sp)
    800061aa:	e022                	sd	s0,0(sp)
    800061ac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800061ae:	479d                	li	a5,7
    800061b0:	06a7c963          	blt	a5,a0,80006222 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800061b4:	0001d797          	auipc	a5,0x1d
    800061b8:	e4c78793          	addi	a5,a5,-436 # 80023000 <disk>
    800061bc:	00a78733          	add	a4,a5,a0
    800061c0:	6789                	lui	a5,0x2
    800061c2:	97ba                	add	a5,a5,a4
    800061c4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800061c8:	e7ad                	bnez	a5,80006232 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061ca:	00451793          	slli	a5,a0,0x4
    800061ce:	0001f717          	auipc	a4,0x1f
    800061d2:	e3270713          	addi	a4,a4,-462 # 80025000 <disk+0x2000>
    800061d6:	6314                	ld	a3,0(a4)
    800061d8:	96be                	add	a3,a3,a5
    800061da:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800061de:	6314                	ld	a3,0(a4)
    800061e0:	96be                	add	a3,a3,a5
    800061e2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800061e6:	6314                	ld	a3,0(a4)
    800061e8:	96be                	add	a3,a3,a5
    800061ea:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800061ee:	6318                	ld	a4,0(a4)
    800061f0:	97ba                	add	a5,a5,a4
    800061f2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800061f6:	0001d797          	auipc	a5,0x1d
    800061fa:	e0a78793          	addi	a5,a5,-502 # 80023000 <disk>
    800061fe:	97aa                	add	a5,a5,a0
    80006200:	6509                	lui	a0,0x2
    80006202:	953e                	add	a0,a0,a5
    80006204:	4785                	li	a5,1
    80006206:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000620a:	0001f517          	auipc	a0,0x1f
    8000620e:	e0e50513          	addi	a0,a0,-498 # 80025018 <disk+0x2018>
    80006212:	ffffc097          	auipc	ra,0xffffc
    80006216:	460080e7          	jalr	1120(ra) # 80002672 <wakeup>
}
    8000621a:	60a2                	ld	ra,8(sp)
    8000621c:	6402                	ld	s0,0(sp)
    8000621e:	0141                	addi	sp,sp,16
    80006220:	8082                	ret
    panic("free_desc 1");
    80006222:	00002517          	auipc	a0,0x2
    80006226:	5ce50513          	addi	a0,a0,1486 # 800087f0 <syscalls+0x320>
    8000622a:	ffffa097          	auipc	ra,0xffffa
    8000622e:	314080e7          	jalr	788(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006232:	00002517          	auipc	a0,0x2
    80006236:	5ce50513          	addi	a0,a0,1486 # 80008800 <syscalls+0x330>
    8000623a:	ffffa097          	auipc	ra,0xffffa
    8000623e:	304080e7          	jalr	772(ra) # 8000053e <panic>

0000000080006242 <virtio_disk_init>:
{
    80006242:	1101                	addi	sp,sp,-32
    80006244:	ec06                	sd	ra,24(sp)
    80006246:	e822                	sd	s0,16(sp)
    80006248:	e426                	sd	s1,8(sp)
    8000624a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000624c:	00002597          	auipc	a1,0x2
    80006250:	5c458593          	addi	a1,a1,1476 # 80008810 <syscalls+0x340>
    80006254:	0001f517          	auipc	a0,0x1f
    80006258:	ed450513          	addi	a0,a0,-300 # 80025128 <disk+0x2128>
    8000625c:	ffffb097          	auipc	ra,0xffffb
    80006260:	8f8080e7          	jalr	-1800(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006264:	100017b7          	lui	a5,0x10001
    80006268:	4398                	lw	a4,0(a5)
    8000626a:	2701                	sext.w	a4,a4
    8000626c:	747277b7          	lui	a5,0x74727
    80006270:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006274:	0ef71163          	bne	a4,a5,80006356 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006278:	100017b7          	lui	a5,0x10001
    8000627c:	43dc                	lw	a5,4(a5)
    8000627e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006280:	4705                	li	a4,1
    80006282:	0ce79a63          	bne	a5,a4,80006356 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006286:	100017b7          	lui	a5,0x10001
    8000628a:	479c                	lw	a5,8(a5)
    8000628c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000628e:	4709                	li	a4,2
    80006290:	0ce79363          	bne	a5,a4,80006356 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006294:	100017b7          	lui	a5,0x10001
    80006298:	47d8                	lw	a4,12(a5)
    8000629a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000629c:	554d47b7          	lui	a5,0x554d4
    800062a0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800062a4:	0af71963          	bne	a4,a5,80006356 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062a8:	100017b7          	lui	a5,0x10001
    800062ac:	4705                	li	a4,1
    800062ae:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062b0:	470d                	li	a4,3
    800062b2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800062b4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800062b6:	c7ffe737          	lui	a4,0xc7ffe
    800062ba:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800062be:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800062c0:	2701                	sext.w	a4,a4
    800062c2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062c4:	472d                	li	a4,11
    800062c6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062c8:	473d                	li	a4,15
    800062ca:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800062cc:	6705                	lui	a4,0x1
    800062ce:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800062d0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062d4:	5bdc                	lw	a5,52(a5)
    800062d6:	2781                	sext.w	a5,a5
  if(max == 0)
    800062d8:	c7d9                	beqz	a5,80006366 <virtio_disk_init+0x124>
  if(max < NUM)
    800062da:	471d                	li	a4,7
    800062dc:	08f77d63          	bgeu	a4,a5,80006376 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062e0:	100014b7          	lui	s1,0x10001
    800062e4:	47a1                	li	a5,8
    800062e6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800062e8:	6609                	lui	a2,0x2
    800062ea:	4581                	li	a1,0
    800062ec:	0001d517          	auipc	a0,0x1d
    800062f0:	d1450513          	addi	a0,a0,-748 # 80023000 <disk>
    800062f4:	ffffb097          	auipc	ra,0xffffb
    800062f8:	9ec080e7          	jalr	-1556(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800062fc:	0001d717          	auipc	a4,0x1d
    80006300:	d0470713          	addi	a4,a4,-764 # 80023000 <disk>
    80006304:	00c75793          	srli	a5,a4,0xc
    80006308:	2781                	sext.w	a5,a5
    8000630a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000630c:	0001f797          	auipc	a5,0x1f
    80006310:	cf478793          	addi	a5,a5,-780 # 80025000 <disk+0x2000>
    80006314:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006316:	0001d717          	auipc	a4,0x1d
    8000631a:	d6a70713          	addi	a4,a4,-662 # 80023080 <disk+0x80>
    8000631e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006320:	0001e717          	auipc	a4,0x1e
    80006324:	ce070713          	addi	a4,a4,-800 # 80024000 <disk+0x1000>
    80006328:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000632a:	4705                	li	a4,1
    8000632c:	00e78c23          	sb	a4,24(a5)
    80006330:	00e78ca3          	sb	a4,25(a5)
    80006334:	00e78d23          	sb	a4,26(a5)
    80006338:	00e78da3          	sb	a4,27(a5)
    8000633c:	00e78e23          	sb	a4,28(a5)
    80006340:	00e78ea3          	sb	a4,29(a5)
    80006344:	00e78f23          	sb	a4,30(a5)
    80006348:	00e78fa3          	sb	a4,31(a5)
}
    8000634c:	60e2                	ld	ra,24(sp)
    8000634e:	6442                	ld	s0,16(sp)
    80006350:	64a2                	ld	s1,8(sp)
    80006352:	6105                	addi	sp,sp,32
    80006354:	8082                	ret
    panic("could not find virtio disk");
    80006356:	00002517          	auipc	a0,0x2
    8000635a:	4ca50513          	addi	a0,a0,1226 # 80008820 <syscalls+0x350>
    8000635e:	ffffa097          	auipc	ra,0xffffa
    80006362:	1e0080e7          	jalr	480(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006366:	00002517          	auipc	a0,0x2
    8000636a:	4da50513          	addi	a0,a0,1242 # 80008840 <syscalls+0x370>
    8000636e:	ffffa097          	auipc	ra,0xffffa
    80006372:	1d0080e7          	jalr	464(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006376:	00002517          	auipc	a0,0x2
    8000637a:	4ea50513          	addi	a0,a0,1258 # 80008860 <syscalls+0x390>
    8000637e:	ffffa097          	auipc	ra,0xffffa
    80006382:	1c0080e7          	jalr	448(ra) # 8000053e <panic>

0000000080006386 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006386:	7159                	addi	sp,sp,-112
    80006388:	f486                	sd	ra,104(sp)
    8000638a:	f0a2                	sd	s0,96(sp)
    8000638c:	eca6                	sd	s1,88(sp)
    8000638e:	e8ca                	sd	s2,80(sp)
    80006390:	e4ce                	sd	s3,72(sp)
    80006392:	e0d2                	sd	s4,64(sp)
    80006394:	fc56                	sd	s5,56(sp)
    80006396:	f85a                	sd	s6,48(sp)
    80006398:	f45e                	sd	s7,40(sp)
    8000639a:	f062                	sd	s8,32(sp)
    8000639c:	ec66                	sd	s9,24(sp)
    8000639e:	e86a                	sd	s10,16(sp)
    800063a0:	1880                	addi	s0,sp,112
    800063a2:	892a                	mv	s2,a0
    800063a4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800063a6:	00c52c83          	lw	s9,12(a0)
    800063aa:	001c9c9b          	slliw	s9,s9,0x1
    800063ae:	1c82                	slli	s9,s9,0x20
    800063b0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800063b4:	0001f517          	auipc	a0,0x1f
    800063b8:	d7450513          	addi	a0,a0,-652 # 80025128 <disk+0x2128>
    800063bc:	ffffb097          	auipc	ra,0xffffb
    800063c0:	828080e7          	jalr	-2008(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800063c4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800063c6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800063c8:	0001db97          	auipc	s7,0x1d
    800063cc:	c38b8b93          	addi	s7,s7,-968 # 80023000 <disk>
    800063d0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800063d2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800063d4:	8a4e                	mv	s4,s3
    800063d6:	a051                	j	8000645a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800063d8:	00fb86b3          	add	a3,s7,a5
    800063dc:	96da                	add	a3,a3,s6
    800063de:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800063e2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800063e4:	0207c563          	bltz	a5,8000640e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800063e8:	2485                	addiw	s1,s1,1
    800063ea:	0711                	addi	a4,a4,4
    800063ec:	25548063          	beq	s1,s5,8000662c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800063f0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800063f2:	0001f697          	auipc	a3,0x1f
    800063f6:	c2668693          	addi	a3,a3,-986 # 80025018 <disk+0x2018>
    800063fa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800063fc:	0006c583          	lbu	a1,0(a3)
    80006400:	fde1                	bnez	a1,800063d8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006402:	2785                	addiw	a5,a5,1
    80006404:	0685                	addi	a3,a3,1
    80006406:	ff879be3          	bne	a5,s8,800063fc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000640a:	57fd                	li	a5,-1
    8000640c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000640e:	02905a63          	blez	s1,80006442 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006412:	f9042503          	lw	a0,-112(s0)
    80006416:	00000097          	auipc	ra,0x0
    8000641a:	d90080e7          	jalr	-624(ra) # 800061a6 <free_desc>
      for(int j = 0; j < i; j++)
    8000641e:	4785                	li	a5,1
    80006420:	0297d163          	bge	a5,s1,80006442 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006424:	f9442503          	lw	a0,-108(s0)
    80006428:	00000097          	auipc	ra,0x0
    8000642c:	d7e080e7          	jalr	-642(ra) # 800061a6 <free_desc>
      for(int j = 0; j < i; j++)
    80006430:	4789                	li	a5,2
    80006432:	0097d863          	bge	a5,s1,80006442 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006436:	f9842503          	lw	a0,-104(s0)
    8000643a:	00000097          	auipc	ra,0x0
    8000643e:	d6c080e7          	jalr	-660(ra) # 800061a6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006442:	0001f597          	auipc	a1,0x1f
    80006446:	ce658593          	addi	a1,a1,-794 # 80025128 <disk+0x2128>
    8000644a:	0001f517          	auipc	a0,0x1f
    8000644e:	bce50513          	addi	a0,a0,-1074 # 80025018 <disk+0x2018>
    80006452:	ffffc097          	auipc	ra,0xffffc
    80006456:	082080e7          	jalr	130(ra) # 800024d4 <sleep>
  for(int i = 0; i < 3; i++){
    8000645a:	f9040713          	addi	a4,s0,-112
    8000645e:	84ce                	mv	s1,s3
    80006460:	bf41                	j	800063f0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006462:	20058713          	addi	a4,a1,512
    80006466:	00471693          	slli	a3,a4,0x4
    8000646a:	0001d717          	auipc	a4,0x1d
    8000646e:	b9670713          	addi	a4,a4,-1130 # 80023000 <disk>
    80006472:	9736                	add	a4,a4,a3
    80006474:	4685                	li	a3,1
    80006476:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000647a:	20058713          	addi	a4,a1,512
    8000647e:	00471693          	slli	a3,a4,0x4
    80006482:	0001d717          	auipc	a4,0x1d
    80006486:	b7e70713          	addi	a4,a4,-1154 # 80023000 <disk>
    8000648a:	9736                	add	a4,a4,a3
    8000648c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006490:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006494:	7679                	lui	a2,0xffffe
    80006496:	963e                	add	a2,a2,a5
    80006498:	0001f697          	auipc	a3,0x1f
    8000649c:	b6868693          	addi	a3,a3,-1176 # 80025000 <disk+0x2000>
    800064a0:	6298                	ld	a4,0(a3)
    800064a2:	9732                	add	a4,a4,a2
    800064a4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800064a6:	6298                	ld	a4,0(a3)
    800064a8:	9732                	add	a4,a4,a2
    800064aa:	4541                	li	a0,16
    800064ac:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064ae:	6298                	ld	a4,0(a3)
    800064b0:	9732                	add	a4,a4,a2
    800064b2:	4505                	li	a0,1
    800064b4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800064b8:	f9442703          	lw	a4,-108(s0)
    800064bc:	6288                	ld	a0,0(a3)
    800064be:	962a                	add	a2,a2,a0
    800064c0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800064c4:	0712                	slli	a4,a4,0x4
    800064c6:	6290                	ld	a2,0(a3)
    800064c8:	963a                	add	a2,a2,a4
    800064ca:	05890513          	addi	a0,s2,88
    800064ce:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800064d0:	6294                	ld	a3,0(a3)
    800064d2:	96ba                	add	a3,a3,a4
    800064d4:	40000613          	li	a2,1024
    800064d8:	c690                	sw	a2,8(a3)
  if(write)
    800064da:	140d0063          	beqz	s10,8000661a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800064de:	0001f697          	auipc	a3,0x1f
    800064e2:	b226b683          	ld	a3,-1246(a3) # 80025000 <disk+0x2000>
    800064e6:	96ba                	add	a3,a3,a4
    800064e8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064ec:	0001d817          	auipc	a6,0x1d
    800064f0:	b1480813          	addi	a6,a6,-1260 # 80023000 <disk>
    800064f4:	0001f517          	auipc	a0,0x1f
    800064f8:	b0c50513          	addi	a0,a0,-1268 # 80025000 <disk+0x2000>
    800064fc:	6114                	ld	a3,0(a0)
    800064fe:	96ba                	add	a3,a3,a4
    80006500:	00c6d603          	lhu	a2,12(a3)
    80006504:	00166613          	ori	a2,a2,1
    80006508:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000650c:	f9842683          	lw	a3,-104(s0)
    80006510:	6110                	ld	a2,0(a0)
    80006512:	9732                	add	a4,a4,a2
    80006514:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006518:	20058613          	addi	a2,a1,512
    8000651c:	0612                	slli	a2,a2,0x4
    8000651e:	9642                	add	a2,a2,a6
    80006520:	577d                	li	a4,-1
    80006522:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006526:	00469713          	slli	a4,a3,0x4
    8000652a:	6114                	ld	a3,0(a0)
    8000652c:	96ba                	add	a3,a3,a4
    8000652e:	03078793          	addi	a5,a5,48
    80006532:	97c2                	add	a5,a5,a6
    80006534:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006536:	611c                	ld	a5,0(a0)
    80006538:	97ba                	add	a5,a5,a4
    8000653a:	4685                	li	a3,1
    8000653c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000653e:	611c                	ld	a5,0(a0)
    80006540:	97ba                	add	a5,a5,a4
    80006542:	4809                	li	a6,2
    80006544:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006548:	611c                	ld	a5,0(a0)
    8000654a:	973e                	add	a4,a4,a5
    8000654c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006550:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006554:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006558:	6518                	ld	a4,8(a0)
    8000655a:	00275783          	lhu	a5,2(a4)
    8000655e:	8b9d                	andi	a5,a5,7
    80006560:	0786                	slli	a5,a5,0x1
    80006562:	97ba                	add	a5,a5,a4
    80006564:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006568:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000656c:	6518                	ld	a4,8(a0)
    8000656e:	00275783          	lhu	a5,2(a4)
    80006572:	2785                	addiw	a5,a5,1
    80006574:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006578:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000657c:	100017b7          	lui	a5,0x10001
    80006580:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006584:	00492703          	lw	a4,4(s2)
    80006588:	4785                	li	a5,1
    8000658a:	02f71163          	bne	a4,a5,800065ac <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000658e:	0001f997          	auipc	s3,0x1f
    80006592:	b9a98993          	addi	s3,s3,-1126 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006596:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006598:	85ce                	mv	a1,s3
    8000659a:	854a                	mv	a0,s2
    8000659c:	ffffc097          	auipc	ra,0xffffc
    800065a0:	f38080e7          	jalr	-200(ra) # 800024d4 <sleep>
  while(b->disk == 1) {
    800065a4:	00492783          	lw	a5,4(s2)
    800065a8:	fe9788e3          	beq	a5,s1,80006598 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800065ac:	f9042903          	lw	s2,-112(s0)
    800065b0:	20090793          	addi	a5,s2,512
    800065b4:	00479713          	slli	a4,a5,0x4
    800065b8:	0001d797          	auipc	a5,0x1d
    800065bc:	a4878793          	addi	a5,a5,-1464 # 80023000 <disk>
    800065c0:	97ba                	add	a5,a5,a4
    800065c2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800065c6:	0001f997          	auipc	s3,0x1f
    800065ca:	a3a98993          	addi	s3,s3,-1478 # 80025000 <disk+0x2000>
    800065ce:	00491713          	slli	a4,s2,0x4
    800065d2:	0009b783          	ld	a5,0(s3)
    800065d6:	97ba                	add	a5,a5,a4
    800065d8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800065dc:	854a                	mv	a0,s2
    800065de:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065e2:	00000097          	auipc	ra,0x0
    800065e6:	bc4080e7          	jalr	-1084(ra) # 800061a6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065ea:	8885                	andi	s1,s1,1
    800065ec:	f0ed                	bnez	s1,800065ce <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065ee:	0001f517          	auipc	a0,0x1f
    800065f2:	b3a50513          	addi	a0,a0,-1222 # 80025128 <disk+0x2128>
    800065f6:	ffffa097          	auipc	ra,0xffffa
    800065fa:	6a2080e7          	jalr	1698(ra) # 80000c98 <release>
}
    800065fe:	70a6                	ld	ra,104(sp)
    80006600:	7406                	ld	s0,96(sp)
    80006602:	64e6                	ld	s1,88(sp)
    80006604:	6946                	ld	s2,80(sp)
    80006606:	69a6                	ld	s3,72(sp)
    80006608:	6a06                	ld	s4,64(sp)
    8000660a:	7ae2                	ld	s5,56(sp)
    8000660c:	7b42                	ld	s6,48(sp)
    8000660e:	7ba2                	ld	s7,40(sp)
    80006610:	7c02                	ld	s8,32(sp)
    80006612:	6ce2                	ld	s9,24(sp)
    80006614:	6d42                	ld	s10,16(sp)
    80006616:	6165                	addi	sp,sp,112
    80006618:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000661a:	0001f697          	auipc	a3,0x1f
    8000661e:	9e66b683          	ld	a3,-1562(a3) # 80025000 <disk+0x2000>
    80006622:	96ba                	add	a3,a3,a4
    80006624:	4609                	li	a2,2
    80006626:	00c69623          	sh	a2,12(a3)
    8000662a:	b5c9                	j	800064ec <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000662c:	f9042583          	lw	a1,-112(s0)
    80006630:	20058793          	addi	a5,a1,512
    80006634:	0792                	slli	a5,a5,0x4
    80006636:	0001d517          	auipc	a0,0x1d
    8000663a:	a7250513          	addi	a0,a0,-1422 # 800230a8 <disk+0xa8>
    8000663e:	953e                	add	a0,a0,a5
  if(write)
    80006640:	e20d11e3          	bnez	s10,80006462 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006644:	20058713          	addi	a4,a1,512
    80006648:	00471693          	slli	a3,a4,0x4
    8000664c:	0001d717          	auipc	a4,0x1d
    80006650:	9b470713          	addi	a4,a4,-1612 # 80023000 <disk>
    80006654:	9736                	add	a4,a4,a3
    80006656:	0a072423          	sw	zero,168(a4)
    8000665a:	b505                	j	8000647a <virtio_disk_rw+0xf4>

000000008000665c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000665c:	1101                	addi	sp,sp,-32
    8000665e:	ec06                	sd	ra,24(sp)
    80006660:	e822                	sd	s0,16(sp)
    80006662:	e426                	sd	s1,8(sp)
    80006664:	e04a                	sd	s2,0(sp)
    80006666:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006668:	0001f517          	auipc	a0,0x1f
    8000666c:	ac050513          	addi	a0,a0,-1344 # 80025128 <disk+0x2128>
    80006670:	ffffa097          	auipc	ra,0xffffa
    80006674:	574080e7          	jalr	1396(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006678:	10001737          	lui	a4,0x10001
    8000667c:	533c                	lw	a5,96(a4)
    8000667e:	8b8d                	andi	a5,a5,3
    80006680:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006682:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006686:	0001f797          	auipc	a5,0x1f
    8000668a:	97a78793          	addi	a5,a5,-1670 # 80025000 <disk+0x2000>
    8000668e:	6b94                	ld	a3,16(a5)
    80006690:	0207d703          	lhu	a4,32(a5)
    80006694:	0026d783          	lhu	a5,2(a3)
    80006698:	06f70163          	beq	a4,a5,800066fa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000669c:	0001d917          	auipc	s2,0x1d
    800066a0:	96490913          	addi	s2,s2,-1692 # 80023000 <disk>
    800066a4:	0001f497          	auipc	s1,0x1f
    800066a8:	95c48493          	addi	s1,s1,-1700 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800066ac:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066b0:	6898                	ld	a4,16(s1)
    800066b2:	0204d783          	lhu	a5,32(s1)
    800066b6:	8b9d                	andi	a5,a5,7
    800066b8:	078e                	slli	a5,a5,0x3
    800066ba:	97ba                	add	a5,a5,a4
    800066bc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800066be:	20078713          	addi	a4,a5,512
    800066c2:	0712                	slli	a4,a4,0x4
    800066c4:	974a                	add	a4,a4,s2
    800066c6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800066ca:	e731                	bnez	a4,80006716 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800066cc:	20078793          	addi	a5,a5,512
    800066d0:	0792                	slli	a5,a5,0x4
    800066d2:	97ca                	add	a5,a5,s2
    800066d4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800066d6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800066da:	ffffc097          	auipc	ra,0xffffc
    800066de:	f98080e7          	jalr	-104(ra) # 80002672 <wakeup>

    disk.used_idx += 1;
    800066e2:	0204d783          	lhu	a5,32(s1)
    800066e6:	2785                	addiw	a5,a5,1
    800066e8:	17c2                	slli	a5,a5,0x30
    800066ea:	93c1                	srli	a5,a5,0x30
    800066ec:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066f0:	6898                	ld	a4,16(s1)
    800066f2:	00275703          	lhu	a4,2(a4)
    800066f6:	faf71be3          	bne	a4,a5,800066ac <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800066fa:	0001f517          	auipc	a0,0x1f
    800066fe:	a2e50513          	addi	a0,a0,-1490 # 80025128 <disk+0x2128>
    80006702:	ffffa097          	auipc	ra,0xffffa
    80006706:	596080e7          	jalr	1430(ra) # 80000c98 <release>
}
    8000670a:	60e2                	ld	ra,24(sp)
    8000670c:	6442                	ld	s0,16(sp)
    8000670e:	64a2                	ld	s1,8(sp)
    80006710:	6902                	ld	s2,0(sp)
    80006712:	6105                	addi	sp,sp,32
    80006714:	8082                	ret
      panic("virtio_disk_intr status");
    80006716:	00002517          	auipc	a0,0x2
    8000671a:	16a50513          	addi	a0,a0,362 # 80008880 <syscalls+0x3b0>
    8000671e:	ffffa097          	auipc	ra,0xffffa
    80006722:	e20080e7          	jalr	-480(ra) # 8000053e <panic>

0000000080006726 <cas>:
    80006726:	100522af          	lr.w	t0,(a0)
    8000672a:	00b29563          	bne	t0,a1,80006734 <fail>
    8000672e:	18c5252f          	sc.w	a0,a2,(a0)
    80006732:	8082                	ret

0000000080006734 <fail>:
    80006734:	4505                	li	a0,1
    80006736:	8082                	ret
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
