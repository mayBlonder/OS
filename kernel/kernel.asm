
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
    80000068:	10c78793          	addi	a5,a5,268 # 80006170 <timervec>
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
    80000130:	8aa080e7          	jalr	-1878(ra) # 800029d6 <either_copyin>
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
    800001c8:	b76080e7          	jalr	-1162(ra) # 80001d3a <myproc>
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
    80000214:	770080e7          	jalr	1904(ra) # 80002980 <either_copyout>
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
    800002f6:	73a080e7          	jalr	1850(ra) # 80002a2c <procdump>
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
    80000b82:	19a080e7          	jalr	410(ra) # 80001d18 <mycpu>
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
    80000bb4:	168080e7          	jalr	360(ra) # 80001d18 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	15c080e7          	jalr	348(ra) # 80001d18 <mycpu>
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
    80000bd8:	144080e7          	jalr	324(ra) # 80001d18 <mycpu>
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
    80000c18:	104080e7          	jalr	260(ra) # 80001d18 <mycpu>
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
    80000c44:	0d8080e7          	jalr	216(ra) # 80001d18 <mycpu>
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
    80000e9a:	e72080e7          	jalr	-398(ra) # 80001d08 <cpuid>
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
    80000eb6:	e56080e7          	jalr	-426(ra) # 80001d08 <cpuid>
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
    80000ed8:	d84080e7          	jalr	-636(ra) # 80002c58 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	2d4080e7          	jalr	724(ra) # 800061b0 <plicinithart>
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
    80000f48:	c3c080e7          	jalr	-964(ra) # 80001b80 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	ce4080e7          	jalr	-796(ra) # 80002c30 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	d04080e7          	jalr	-764(ra) # 80002c58 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	23e080e7          	jalr	574(ra) # 8000619a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	24c080e7          	jalr	588(ra) # 800061b0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	42e080e7          	jalr	1070(ra) # 8000339a <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	abe080e7          	jalr	-1346(ra) # 80003a32 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	a68080e7          	jalr	-1432(ra) # 800049e4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	34e080e7          	jalr	846(ra) # 800062d2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	12e080e7          	jalr	302(ra) # 800020ba <userinit>
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
    80001244:	8aa080e7          	jalr	-1878(ra) # 80001aea <proc_mapstacks>
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
struct linked_list unused_list = {-1};   // contains all UNUSED process entries.
struct linked_list sleeping_list = {-1}; // contains all SLEEPING processes.
struct linked_list zombie_list = {-1};   // contains all ZOMBIE processes.

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
    8000185e:	f5c080e7          	jalr	-164(ra) # 800067b6 <cas>
    80001862:	2501                	sext.w	a0,a0
    80001864:	f575                	bnez	a0,80001850 <inc_cpu+0x12>
}
    80001866:	60e2                	ld	ra,24(sp)
    80001868:	6442                	ld	s0,16(sp)
    8000186a:	64a2                	ld	s1,8(sp)
    8000186c:	6902                	ld	s2,0(sp)
    8000186e:	6105                	addi	sp,sp,32
    80001870:	8082                	ret

0000000080001872 <initialize_proc>:

void
initialize_proc(struct proc *p){
    80001872:	1141                	addi	sp,sp,-16
    80001874:	e422                	sd	s0,8(sp)
    80001876:	0800                	addi	s0,sp,16
  p->prev_proc = -1;
    80001878:	57fd                	li	a5,-1
    8000187a:	16f52823          	sw	a5,368(a0)
  p->next_proc = -1;
    8000187e:	16f52623          	sw	a5,364(a0)
}
    80001882:	6422                	ld	s0,8(sp)
    80001884:	0141                	addi	sp,sp,16
    80001886:	8082                	ret

0000000080001888 <isEmpty>:

int
isEmpty(struct linked_list *lst){
    80001888:	1141                	addi	sp,sp,-16
    8000188a:	e422                	sd	s0,8(sp)
    8000188c:	0800                	addi	s0,sp,16
  int h= 0;
  h = lst->head == -1;
    8000188e:	4108                	lw	a0,0(a0)
    80001890:	0505                	addi	a0,a0,1
  return h;
}
    80001892:	00153513          	seqz	a0,a0
    80001896:	6422                	ld	s0,8(sp)
    80001898:	0141                	addi	sp,sp,16
    8000189a:	8082                	ret

000000008000189c <get_head>:

int 
get_head(struct linked_list *lst){
    8000189c:	1101                	addi	sp,sp,-32
    8000189e:	ec06                	sd	ra,24(sp)
    800018a0:	e822                	sd	s0,16(sp)
    800018a2:	e426                	sd	s1,8(sp)
    800018a4:	e04a                	sd	s2,0(sp)
    800018a6:	1000                	addi	s0,sp,32
    800018a8:	84aa                	mv	s1,a0
  acquire(&lst->head_lock); 
    800018aa:	00850913          	addi	s2,a0,8
    800018ae:	854a                	mv	a0,s2
    800018b0:	fffff097          	auipc	ra,0xfffff
    800018b4:	334080e7          	jalr	820(ra) # 80000be4 <acquire>
  int output = lst->head;
    800018b8:	4084                	lw	s1,0(s1)
  release(&lst->head_lock);
    800018ba:	854a                	mv	a0,s2
    800018bc:	fffff097          	auipc	ra,0xfffff
    800018c0:	3dc080e7          	jalr	988(ra) # 80000c98 <release>
  return output;
}
    800018c4:	8526                	mv	a0,s1
    800018c6:	60e2                	ld	ra,24(sp)
    800018c8:	6442                	ld	s0,16(sp)
    800018ca:	64a2                	ld	s1,8(sp)
    800018cc:	6902                	ld	s2,0(sp)
    800018ce:	6105                	addi	sp,sp,32
    800018d0:	8082                	ret

00000000800018d2 <set_prev_proc>:

void set_prev_proc(struct proc *p, int value){
    800018d2:	1141                	addi	sp,sp,-16
    800018d4:	e422                	sd	s0,8(sp)
    800018d6:	0800                	addi	s0,sp,16
  p->prev_proc = value; 
    800018d8:	16b52823          	sw	a1,368(a0)
}
    800018dc:	6422                	ld	s0,8(sp)
    800018de:	0141                	addi	sp,sp,16
    800018e0:	8082                	ret

00000000800018e2 <set_next_proc>:

void set_next_proc(struct proc *p, int value){
    800018e2:	1141                	addi	sp,sp,-16
    800018e4:	e422                	sd	s0,8(sp)
    800018e6:	0800                	addi	s0,sp,16
  p->next_proc = value; 
    800018e8:	16b52623          	sw	a1,364(a0)
}
    800018ec:	6422                	ld	s0,8(sp)
    800018ee:	0141                	addi	sp,sp,16
    800018f0:	8082                	ret

00000000800018f2 <append>:

void 
append(struct linked_list *lst, struct proc *p){
    800018f2:	7139                	addi	sp,sp,-64
    800018f4:	fc06                	sd	ra,56(sp)
    800018f6:	f822                	sd	s0,48(sp)
    800018f8:	f426                	sd	s1,40(sp)
    800018fa:	f04a                	sd	s2,32(sp)
    800018fc:	ec4e                	sd	s3,24(sp)
    800018fe:	e852                	sd	s4,16(sp)
    80001900:	e456                	sd	s5,8(sp)
    80001902:	0080                	addi	s0,sp,64
    80001904:	84aa                	mv	s1,a0
    80001906:	892e                	mv	s2,a1
  acquire(&lst->head_lock);
    80001908:	00850993          	addi	s3,a0,8
    8000190c:	854e                	mv	a0,s3
    8000190e:	fffff097          	auipc	ra,0xfffff
    80001912:	2d6080e7          	jalr	726(ra) # 80000be4 <acquire>
  if(isEmpty(lst)){
    80001916:	4098                	lw	a4,0(s1)
    80001918:	57fd                	li	a5,-1
    8000191a:	04f71063          	bne	a4,a5,8000195a <append+0x68>
    lst->head = p->proc_ind;
    8000191e:	17492783          	lw	a5,372(s2) # 1174 <_entry-0x7fffee8c>
    80001922:	c09c                	sw	a5,0(s1)
    release(&lst->head_lock);
    80001924:	854e                	mv	a0,s3
    80001926:	fffff097          	auipc	ra,0xfffff
    8000192a:	372080e7          	jalr	882(ra) # 80000c98 <release>
    release(&lst->head_lock);
    set_next_proc(&proc[lst->tail], p->proc_ind);  // update next proc of the curr tail
    set_prev_proc(p, proc[lst->tail].proc_ind); // update the prev proc of the new proc
    release(&proc[lst->tail].list_lock);
  }
  acquire(&lst->head_lock);
    8000192e:	854e                	mv	a0,s3
    80001930:	fffff097          	auipc	ra,0xfffff
    80001934:	2b4080e7          	jalr	692(ra) # 80000be4 <acquire>
  lst->tail = p->proc_ind;
    80001938:	17492783          	lw	a5,372(s2)
    8000193c:	c0dc                	sw	a5,4(s1)
  release(&lst->head_lock);
    8000193e:	854e                	mv	a0,s3
    80001940:	fffff097          	auipc	ra,0xfffff
    80001944:	358080e7          	jalr	856(ra) # 80000c98 <release>
}
    80001948:	70e2                	ld	ra,56(sp)
    8000194a:	7442                	ld	s0,48(sp)
    8000194c:	74a2                	ld	s1,40(sp)
    8000194e:	7902                	ld	s2,32(sp)
    80001950:	69e2                	ld	s3,24(sp)
    80001952:	6a42                	ld	s4,16(sp)
    80001954:	6aa2                	ld	s5,8(sp)
    80001956:	6121                	addi	sp,sp,64
    80001958:	8082                	ret
    acquire(&proc[lst->tail].list_lock);
    8000195a:	40c8                	lw	a0,4(s1)
    8000195c:	19000a93          	li	s5,400
    80001960:	03550533          	mul	a0,a0,s5
    80001964:	17850513          	addi	a0,a0,376
    80001968:	00010a17          	auipc	s4,0x10
    8000196c:	ea8a0a13          	addi	s4,s4,-344 # 80011810 <proc>
    80001970:	9552                	add	a0,a0,s4
    80001972:	fffff097          	auipc	ra,0xfffff
    80001976:	272080e7          	jalr	626(ra) # 80000be4 <acquire>
    release(&lst->head_lock);
    8000197a:	854e                	mv	a0,s3
    8000197c:	fffff097          	auipc	ra,0xfffff
    80001980:	31c080e7          	jalr	796(ra) # 80000c98 <release>
    set_next_proc(&proc[lst->tail], p->proc_ind);  // update next proc of the curr tail
    80001984:	40dc                	lw	a5,4(s1)
    80001986:	17492703          	lw	a4,372(s2)
  p->next_proc = value; 
    8000198a:	035787b3          	mul	a5,a5,s5
    8000198e:	97d2                	add	a5,a5,s4
    80001990:	16e7a623          	sw	a4,364(a5)
    set_prev_proc(p, proc[lst->tail].proc_ind); // update the prev proc of the new proc
    80001994:	40dc                	lw	a5,4(s1)
    80001996:	035787b3          	mul	a5,a5,s5
    8000199a:	97d2                	add	a5,a5,s4
    8000199c:	1747a783          	lw	a5,372(a5)
  p->prev_proc = value; 
    800019a0:	16f92823          	sw	a5,368(s2)
    release(&proc[lst->tail].list_lock);
    800019a4:	40c8                	lw	a0,4(s1)
    800019a6:	03550533          	mul	a0,a0,s5
    800019aa:	17850513          	addi	a0,a0,376
    800019ae:	9552                	add	a0,a0,s4
    800019b0:	fffff097          	auipc	ra,0xfffff
    800019b4:	2e8080e7          	jalr	744(ra) # 80000c98 <release>
    800019b8:	bf9d                	j	8000192e <append+0x3c>

00000000800019ba <remove>:

void 
remove(struct linked_list *lst, struct proc *p){
    800019ba:	7179                	addi	sp,sp,-48
    800019bc:	f406                	sd	ra,40(sp)
    800019be:	f022                	sd	s0,32(sp)
    800019c0:	ec26                	sd	s1,24(sp)
    800019c2:	e84a                	sd	s2,16(sp)
    800019c4:	e44e                	sd	s3,8(sp)
    800019c6:	e052                	sd	s4,0(sp)
    800019c8:	1800                	addi	s0,sp,48
    800019ca:	892a                	mv	s2,a0
    800019cc:	84ae                	mv	s1,a1
  acquire(&lst->head_lock);
    800019ce:	00850993          	addi	s3,a0,8
    800019d2:	854e                	mv	a0,s3
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  h = lst->head == -1;
    800019dc:	00092783          	lw	a5,0(s2)
  if(isEmpty(lst)){
    800019e0:	577d                	li	a4,-1
    800019e2:	0ae78263          	beq	a5,a4,80001a86 <remove+0xcc>
    release(&lst->head_lock);
    panic("list is empty\n");
  }

  if(lst->head == p->proc_ind){ // the required proc is the head
    800019e6:	1744a703          	lw	a4,372(s1)
    800019ea:	0af70b63          	beq	a4,a5,80001aa0 <remove+0xe6>
      lst->tail = -1;
    }
    release(&lst->head_lock);
  }
  else{
    if (lst->tail == p->proc_ind) {
    800019ee:	00492783          	lw	a5,4(s2)
    800019f2:	0ee78763          	beq	a5,a4,80001ae0 <remove+0x126>
      lst->tail = p->prev_proc;
    }
    release(&lst->head_lock); 
    800019f6:	854e                	mv	a0,s3
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>
    acquire(&p->list_lock);
    80001a00:	17848993          	addi	s3,s1,376
    80001a04:	854e                	mv	a0,s3
    80001a06:	fffff097          	auipc	ra,0xfffff
    80001a0a:	1de080e7          	jalr	478(ra) # 80000be4 <acquire>
    acquire(&proc[p->prev_proc].list_lock);
    80001a0e:	1704a503          	lw	a0,368(s1)
    80001a12:	19000a13          	li	s4,400
    80001a16:	03450533          	mul	a0,a0,s4
    80001a1a:	17850513          	addi	a0,a0,376
    80001a1e:	00010917          	auipc	s2,0x10
    80001a22:	df290913          	addi	s2,s2,-526 # 80011810 <proc>
    80001a26:	954a                	add	a0,a0,s2
    80001a28:	fffff097          	auipc	ra,0xfffff
    80001a2c:	1bc080e7          	jalr	444(ra) # 80000be4 <acquire>
    set_next_proc(&proc[p->prev_proc], p->next_proc);
    80001a30:	1704a703          	lw	a4,368(s1)
    80001a34:	16c4a783          	lw	a5,364(s1)
  p->next_proc = value; 
    80001a38:	03470733          	mul	a4,a4,s4
    80001a3c:	974a                	add	a4,a4,s2
    80001a3e:	16f72623          	sw	a5,364(a4)
    set_prev_proc(&proc[p->next_proc], p->prev_proc);
    80001a42:	1704a503          	lw	a0,368(s1)
  p->prev_proc = value; 
    80001a46:	034787b3          	mul	a5,a5,s4
    80001a4a:	97ca                	add	a5,a5,s2
    80001a4c:	16a7a823          	sw	a0,368(a5)
    release(&proc[p->prev_proc].list_lock);
    80001a50:	03450533          	mul	a0,a0,s4
    80001a54:	17850513          	addi	a0,a0,376
    80001a58:	954a                	add	a0,a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	23e080e7          	jalr	574(ra) # 80000c98 <release>
    release(&p->list_lock);
    80001a62:	854e                	mv	a0,s3
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	234080e7          	jalr	564(ra) # 80000c98 <release>
  p->prev_proc = -1;
    80001a6c:	57fd                	li	a5,-1
    80001a6e:	16f4a823          	sw	a5,368(s1)
  p->next_proc = -1;
    80001a72:	16f4a623          	sw	a5,364(s1)
  }
  initialize_proc(p);
}
    80001a76:	70a2                	ld	ra,40(sp)
    80001a78:	7402                	ld	s0,32(sp)
    80001a7a:	64e2                	ld	s1,24(sp)
    80001a7c:	6942                	ld	s2,16(sp)
    80001a7e:	69a2                	ld	s3,8(sp)
    80001a80:	6a02                	ld	s4,0(sp)
    80001a82:	6145                	addi	sp,sp,48
    80001a84:	8082                	ret
    release(&lst->head_lock);
    80001a86:	854e                	mv	a0,s3
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	210080e7          	jalr	528(ra) # 80000c98 <release>
    panic("list is empty\n");
    80001a90:	00006517          	auipc	a0,0x6
    80001a94:	74850513          	addi	a0,a0,1864 # 800081d8 <digits+0x198>
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	aa6080e7          	jalr	-1370(ra) # 8000053e <panic>
    lst->head = p->next_proc;
    80001aa0:	16c4a783          	lw	a5,364(s1)
    80001aa4:	00f92023          	sw	a5,0(s2)
  p->prev_proc = value; 
    80001aa8:	19000713          	li	a4,400
    80001aac:	02e787b3          	mul	a5,a5,a4
    80001ab0:	00010717          	auipc	a4,0x10
    80001ab4:	d6070713          	addi	a4,a4,-672 # 80011810 <proc>
    80001ab8:	97ba                	add	a5,a5,a4
    80001aba:	577d                	li	a4,-1
    80001abc:	16e7a823          	sw	a4,368(a5)
    if(lst->tail == p->proc_ind){
    80001ac0:	00492703          	lw	a4,4(s2)
    80001ac4:	1744a783          	lw	a5,372(s1)
    80001ac8:	00f70863          	beq	a4,a5,80001ad8 <remove+0x11e>
    release(&lst->head_lock);
    80001acc:	854e                	mv	a0,s3
    80001ace:	fffff097          	auipc	ra,0xfffff
    80001ad2:	1ca080e7          	jalr	458(ra) # 80000c98 <release>
    80001ad6:	bf59                	j	80001a6c <remove+0xb2>
      lst->tail = -1;
    80001ad8:	57fd                	li	a5,-1
    80001ada:	00f92223          	sw	a5,4(s2)
    80001ade:	b7fd                	j	80001acc <remove+0x112>
      lst->tail = p->prev_proc;
    80001ae0:	1704a783          	lw	a5,368(s1)
    80001ae4:	00f92223          	sw	a5,4(s2)
    80001ae8:	b739                	j	800019f6 <remove+0x3c>

0000000080001aea <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001aea:	7139                	addi	sp,sp,-64
    80001aec:	fc06                	sd	ra,56(sp)
    80001aee:	f822                	sd	s0,48(sp)
    80001af0:	f426                	sd	s1,40(sp)
    80001af2:	f04a                	sd	s2,32(sp)
    80001af4:	ec4e                	sd	s3,24(sp)
    80001af6:	e852                	sd	s4,16(sp)
    80001af8:	e456                	sd	s5,8(sp)
    80001afa:	e05a                	sd	s6,0(sp)
    80001afc:	0080                	addi	s0,sp,64
    80001afe:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b00:	00010497          	auipc	s1,0x10
    80001b04:	d1048493          	addi	s1,s1,-752 # 80011810 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001b08:	8b26                	mv	s6,s1
    80001b0a:	00006a97          	auipc	s5,0x6
    80001b0e:	4f6a8a93          	addi	s5,s5,1270 # 80008000 <etext>
    80001b12:	04000937          	lui	s2,0x4000
    80001b16:	197d                	addi	s2,s2,-1
    80001b18:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b1a:	00016a17          	auipc	s4,0x16
    80001b1e:	0f6a0a13          	addi	s4,s4,246 # 80017c10 <tickslock>
    char *pa = kalloc();
    80001b22:	fffff097          	auipc	ra,0xfffff
    80001b26:	fd2080e7          	jalr	-46(ra) # 80000af4 <kalloc>
    80001b2a:	862a                	mv	a2,a0
    if(pa == 0)
    80001b2c:	c131                	beqz	a0,80001b70 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001b2e:	416485b3          	sub	a1,s1,s6
    80001b32:	8591                	srai	a1,a1,0x4
    80001b34:	000ab783          	ld	a5,0(s5)
    80001b38:	02f585b3          	mul	a1,a1,a5
    80001b3c:	2585                	addiw	a1,a1,1
    80001b3e:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b42:	4719                	li	a4,6
    80001b44:	6685                	lui	a3,0x1
    80001b46:	40b905b3          	sub	a1,s2,a1
    80001b4a:	854e                	mv	a0,s3
    80001b4c:	fffff097          	auipc	ra,0xfffff
    80001b50:	604080e7          	jalr	1540(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b54:	19048493          	addi	s1,s1,400
    80001b58:	fd4495e3          	bne	s1,s4,80001b22 <proc_mapstacks+0x38>
  }
}
    80001b5c:	70e2                	ld	ra,56(sp)
    80001b5e:	7442                	ld	s0,48(sp)
    80001b60:	74a2                	ld	s1,40(sp)
    80001b62:	7902                	ld	s2,32(sp)
    80001b64:	69e2                	ld	s3,24(sp)
    80001b66:	6a42                	ld	s4,16(sp)
    80001b68:	6aa2                	ld	s5,8(sp)
    80001b6a:	6b02                	ld	s6,0(sp)
    80001b6c:	6121                	addi	sp,sp,64
    80001b6e:	8082                	ret
      panic("kalloc");
    80001b70:	00006517          	auipc	a0,0x6
    80001b74:	67850513          	addi	a0,a0,1656 # 800081e8 <digits+0x1a8>
    80001b78:	fffff097          	auipc	ra,0xfffff
    80001b7c:	9c6080e7          	jalr	-1594(ra) # 8000053e <panic>

0000000080001b80 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001b80:	711d                	addi	sp,sp,-96
    80001b82:	ec86                	sd	ra,88(sp)
    80001b84:	e8a2                	sd	s0,80(sp)
    80001b86:	e4a6                	sd	s1,72(sp)
    80001b88:	e0ca                	sd	s2,64(sp)
    80001b8a:	fc4e                	sd	s3,56(sp)
    80001b8c:	f852                	sd	s4,48(sp)
    80001b8e:	f456                	sd	s5,40(sp)
    80001b90:	f05a                	sd	s6,32(sp)
    80001b92:	ec5e                	sd	s7,24(sp)
    80001b94:	e862                	sd	s8,16(sp)
    80001b96:	e466                	sd	s9,8(sp)
    80001b98:	e06a                	sd	s10,0(sp)
    80001b9a:	1080                	addi	s0,sp,96
  // Adding all processes to UNUSED list.
  struct proc *p;
  struct cpu *c;
  int i = 0;

  initlock(&sleeping_list.head_lock, "sleeping_list_head_lock");
    80001b9c:	00006597          	auipc	a1,0x6
    80001ba0:	65458593          	addi	a1,a1,1620 # 800081f0 <digits+0x1b0>
    80001ba4:	00007517          	auipc	a0,0x7
    80001ba8:	d1450513          	addi	a0,a0,-748 # 800088b8 <sleeping_list+0x8>
    80001bac:	fffff097          	auipc	ra,0xfffff
    80001bb0:	fa8080e7          	jalr	-88(ra) # 80000b54 <initlock>
  initlock(&zombie_list.head_lock, "zombie_list_head_lock");
    80001bb4:	00006597          	auipc	a1,0x6
    80001bb8:	65458593          	addi	a1,a1,1620 # 80008208 <digits+0x1c8>
    80001bbc:	00007517          	auipc	a0,0x7
    80001bc0:	d1c50513          	addi	a0,a0,-740 # 800088d8 <zombie_list+0x8>
    80001bc4:	fffff097          	auipc	ra,0xfffff
    80001bc8:	f90080e7          	jalr	-112(ra) # 80000b54 <initlock>
  initlock(&unused_list.head_lock, "unused_list_head_lock");
    80001bcc:	00006597          	auipc	a1,0x6
    80001bd0:	65458593          	addi	a1,a1,1620 # 80008220 <digits+0x1e0>
    80001bd4:	00007517          	auipc	a0,0x7
    80001bd8:	d2450513          	addi	a0,a0,-732 # 800088f8 <unused_list+0x8>
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	f78080e7          	jalr	-136(ra) # 80000b54 <initlock>
  initlock(&pid_lock, "nextpid");
    80001be4:	00006597          	auipc	a1,0x6
    80001be8:	65458593          	addi	a1,a1,1620 # 80008238 <digits+0x1f8>
    80001bec:	00010517          	auipc	a0,0x10
    80001bf0:	bf450513          	addi	a0,a0,-1036 # 800117e0 <pid_lock>
    80001bf4:	fffff097          	auipc	ra,0xfffff
    80001bf8:	f60080e7          	jalr	-160(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001bfc:	00006597          	auipc	a1,0x6
    80001c00:	64458593          	addi	a1,a1,1604 # 80008240 <digits+0x200>
    80001c04:	00010517          	auipc	a0,0x10
    80001c08:	bf450513          	addi	a0,a0,-1036 # 800117f8 <wait_lock>
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	f48080e7          	jalr	-184(ra) # 80000b54 <initlock>
  int i = 0;
    80001c14:	4901                	li	s2,0

  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c16:	00010497          	auipc	s1,0x10
    80001c1a:	bfa48493          	addi	s1,s1,-1030 # 80011810 <proc>
      initlock(&p->lock, "proc");
    80001c1e:	00006d17          	auipc	s10,0x6
    80001c22:	632d0d13          	addi	s10,s10,1586 # 80008250 <digits+0x210>
      initlock(&p->list_lock, "list_lock");
    80001c26:	00006c97          	auipc	s9,0x6
    80001c2a:	632c8c93          	addi	s9,s9,1586 # 80008258 <digits+0x218>
      p->kstack = KSTACK((int) (p - proc));
    80001c2e:	8c26                	mv	s8,s1
    80001c30:	00006b97          	auipc	s7,0x6
    80001c34:	3d0b8b93          	addi	s7,s7,976 # 80008000 <etext>
    80001c38:	04000a37          	lui	s4,0x4000
    80001c3c:	1a7d                	addi	s4,s4,-1
    80001c3e:	0a32                	slli	s4,s4,0xc
      p->proc_ind = i;
      i=i+1;
      p->prev_proc = -1;
    80001c40:	59fd                	li	s3,-1
      p->next_proc = -1;
      append(&unused_list, p); 
    80001c42:	00007b17          	auipc	s6,0x7
    80001c46:	caeb0b13          	addi	s6,s6,-850 # 800088f0 <unused_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c4a:	00016a97          	auipc	s5,0x16
    80001c4e:	fc6a8a93          	addi	s5,s5,-58 # 80017c10 <tickslock>
      initlock(&p->lock, "proc");
    80001c52:	85ea                	mv	a1,s10
    80001c54:	8526                	mv	a0,s1
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	efe080e7          	jalr	-258(ra) # 80000b54 <initlock>
      initlock(&p->list_lock, "list_lock");
    80001c5e:	85e6                	mv	a1,s9
    80001c60:	17848513          	addi	a0,s1,376
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	ef0080e7          	jalr	-272(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001c6c:	418487b3          	sub	a5,s1,s8
    80001c70:	8791                	srai	a5,a5,0x4
    80001c72:	000bb703          	ld	a4,0(s7)
    80001c76:	02e787b3          	mul	a5,a5,a4
    80001c7a:	2785                	addiw	a5,a5,1
    80001c7c:	00d7979b          	slliw	a5,a5,0xd
    80001c80:	40fa07b3          	sub	a5,s4,a5
    80001c84:	e0bc                	sd	a5,64(s1)
      p->proc_ind = i;
    80001c86:	1724aa23          	sw	s2,372(s1)
      i=i+1;
    80001c8a:	2905                	addiw	s2,s2,1
      p->prev_proc = -1;
    80001c8c:	1734a823          	sw	s3,368(s1)
      p->next_proc = -1;
    80001c90:	1734a623          	sw	s3,364(s1)
      append(&unused_list, p); 
    80001c94:	85a6                	mv	a1,s1
    80001c96:	855a                	mv	a0,s6
    80001c98:	00000097          	auipc	ra,0x0
    80001c9c:	c5a080e7          	jalr	-934(ra) # 800018f2 <append>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ca0:	19048493          	addi	s1,s1,400
    80001ca4:	fb5497e3          	bne	s1,s5,80001c52 <procinit+0xd2>
  }

  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001ca8:	0000f497          	auipc	s1,0xf
    80001cac:	5f848493          	addi	s1,s1,1528 # 800112a0 <cpus>
    c->runnable_list = (struct linked_list){-1};
    80001cb0:	5a7d                	li	s4,-1
    initlock(&c->runnable_list.head_lock, "cpu_runnable_list_head_lock");
    80001cb2:	00006997          	auipc	s3,0x6
    80001cb6:	5b698993          	addi	s3,s3,1462 # 80008268 <digits+0x228>
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001cba:	00010917          	auipc	s2,0x10
    80001cbe:	b2690913          	addi	s2,s2,-1242 # 800117e0 <pid_lock>
    c->runnable_list = (struct linked_list){-1};
    80001cc2:	0804b423          	sd	zero,136(s1)
    80001cc6:	0804b823          	sd	zero,144(s1)
    80001cca:	0804bc23          	sd	zero,152(s1)
    80001cce:	0a04b023          	sd	zero,160(s1)
    80001cd2:	0944a423          	sw	s4,136(s1)
    initlock(&c->runnable_list.head_lock, "cpu_runnable_list_head_lock");
    80001cd6:	85ce                	mv	a1,s3
    80001cd8:	09048513          	addi	a0,s1,144
    80001cdc:	fffff097          	auipc	ra,0xfffff
    80001ce0:	e78080e7          	jalr	-392(ra) # 80000b54 <initlock>
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001ce4:	0a848493          	addi	s1,s1,168
    80001ce8:	fd249de3          	bne	s1,s2,80001cc2 <procinit+0x142>
  }
}
    80001cec:	60e6                	ld	ra,88(sp)
    80001cee:	6446                	ld	s0,80(sp)
    80001cf0:	64a6                	ld	s1,72(sp)
    80001cf2:	6906                	ld	s2,64(sp)
    80001cf4:	79e2                	ld	s3,56(sp)
    80001cf6:	7a42                	ld	s4,48(sp)
    80001cf8:	7aa2                	ld	s5,40(sp)
    80001cfa:	7b02                	ld	s6,32(sp)
    80001cfc:	6be2                	ld	s7,24(sp)
    80001cfe:	6c42                	ld	s8,16(sp)
    80001d00:	6ca2                	ld	s9,8(sp)
    80001d02:	6d02                	ld	s10,0(sp)
    80001d04:	6125                	addi	sp,sp,96
    80001d06:	8082                	ret

0000000080001d08 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001d08:	1141                	addi	sp,sp,-16
    80001d0a:	e422                	sd	s0,8(sp)
    80001d0c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d0e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001d10:	2501                	sext.w	a0,a0
    80001d12:	6422                	ld	s0,8(sp)
    80001d14:	0141                	addi	sp,sp,16
    80001d16:	8082                	ret

0000000080001d18 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001d18:	1141                	addi	sp,sp,-16
    80001d1a:	e422                	sd	s0,8(sp)
    80001d1c:	0800                	addi	s0,sp,16
    80001d1e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001d20:	2781                	sext.w	a5,a5
    80001d22:	0a800513          	li	a0,168
    80001d26:	02a787b3          	mul	a5,a5,a0
  return c;
}
    80001d2a:	0000f517          	auipc	a0,0xf
    80001d2e:	57650513          	addi	a0,a0,1398 # 800112a0 <cpus>
    80001d32:	953e                	add	a0,a0,a5
    80001d34:	6422                	ld	s0,8(sp)
    80001d36:	0141                	addi	sp,sp,16
    80001d38:	8082                	ret

0000000080001d3a <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001d3a:	1101                	addi	sp,sp,-32
    80001d3c:	ec06                	sd	ra,24(sp)
    80001d3e:	e822                	sd	s0,16(sp)
    80001d40:	e426                	sd	s1,8(sp)
    80001d42:	1000                	addi	s0,sp,32
  push_off();
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	e54080e7          	jalr	-428(ra) # 80000b98 <push_off>
    80001d4c:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001d4e:	2781                	sext.w	a5,a5
    80001d50:	0a800713          	li	a4,168
    80001d54:	02e787b3          	mul	a5,a5,a4
    80001d58:	0000f717          	auipc	a4,0xf
    80001d5c:	54870713          	addi	a4,a4,1352 # 800112a0 <cpus>
    80001d60:	97ba                	add	a5,a5,a4
    80001d62:	6384                	ld	s1,0(a5)
  pop_off();
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	ed4080e7          	jalr	-300(ra) # 80000c38 <pop_off>
  return p;
}
    80001d6c:	8526                	mv	a0,s1
    80001d6e:	60e2                	ld	ra,24(sp)
    80001d70:	6442                	ld	s0,16(sp)
    80001d72:	64a2                	ld	s1,8(sp)
    80001d74:	6105                	addi	sp,sp,32
    80001d76:	8082                	ret

0000000080001d78 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001d78:	1141                	addi	sp,sp,-16
    80001d7a:	e406                	sd	ra,8(sp)
    80001d7c:	e022                	sd	s0,0(sp)
    80001d7e:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001d80:	00000097          	auipc	ra,0x0
    80001d84:	fba080e7          	jalr	-70(ra) # 80001d3a <myproc>
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	f10080e7          	jalr	-240(ra) # 80000c98 <release>

  if (first) {
    80001d90:	00007797          	auipc	a5,0x7
    80001d94:	b107a783          	lw	a5,-1264(a5) # 800088a0 <first.1741>
    80001d98:	eb89                	bnez	a5,80001daa <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001d9a:	00001097          	auipc	ra,0x1
    80001d9e:	ed6080e7          	jalr	-298(ra) # 80002c70 <usertrapret>
}
    80001da2:	60a2                	ld	ra,8(sp)
    80001da4:	6402                	ld	s0,0(sp)
    80001da6:	0141                	addi	sp,sp,16
    80001da8:	8082                	ret
    first = 0;
    80001daa:	00007797          	auipc	a5,0x7
    80001dae:	ae07ab23          	sw	zero,-1290(a5) # 800088a0 <first.1741>
    fsinit(ROOTDEV);
    80001db2:	4505                	li	a0,1
    80001db4:	00002097          	auipc	ra,0x2
    80001db8:	bfe080e7          	jalr	-1026(ra) # 800039b2 <fsinit>
    80001dbc:	bff9                	j	80001d9a <forkret+0x22>

0000000080001dbe <allocpid>:
allocpid() {
    80001dbe:	1101                	addi	sp,sp,-32
    80001dc0:	ec06                	sd	ra,24(sp)
    80001dc2:	e822                	sd	s0,16(sp)
    80001dc4:	e426                	sd	s1,8(sp)
    80001dc6:	e04a                	sd	s2,0(sp)
    80001dc8:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001dca:	00007917          	auipc	s2,0x7
    80001dce:	ada90913          	addi	s2,s2,-1318 # 800088a4 <nextpid>
    80001dd2:	00092483          	lw	s1,0(s2)
  while (cas(&nextpid, pid, nextpid + 1));
    80001dd6:	0014861b          	addiw	a2,s1,1
    80001dda:	85a6                	mv	a1,s1
    80001ddc:	854a                	mv	a0,s2
    80001dde:	00005097          	auipc	ra,0x5
    80001de2:	9d8080e7          	jalr	-1576(ra) # 800067b6 <cas>
    80001de6:	2501                	sext.w	a0,a0
    80001de8:	f56d                	bnez	a0,80001dd2 <allocpid+0x14>
}
    80001dea:	8526                	mv	a0,s1
    80001dec:	60e2                	ld	ra,24(sp)
    80001dee:	6442                	ld	s0,16(sp)
    80001df0:	64a2                	ld	s1,8(sp)
    80001df2:	6902                	ld	s2,0(sp)
    80001df4:	6105                	addi	sp,sp,32
    80001df6:	8082                	ret

0000000080001df8 <proc_pagetable>:
{
    80001df8:	1101                	addi	sp,sp,-32
    80001dfa:	ec06                	sd	ra,24(sp)
    80001dfc:	e822                	sd	s0,16(sp)
    80001dfe:	e426                	sd	s1,8(sp)
    80001e00:	e04a                	sd	s2,0(sp)
    80001e02:	1000                	addi	s0,sp,32
    80001e04:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001e06:	fffff097          	auipc	ra,0xfffff
    80001e0a:	534080e7          	jalr	1332(ra) # 8000133a <uvmcreate>
    80001e0e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001e10:	c121                	beqz	a0,80001e50 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e12:	4729                	li	a4,10
    80001e14:	00005697          	auipc	a3,0x5
    80001e18:	1ec68693          	addi	a3,a3,492 # 80007000 <_trampoline>
    80001e1c:	6605                	lui	a2,0x1
    80001e1e:	040005b7          	lui	a1,0x4000
    80001e22:	15fd                	addi	a1,a1,-1
    80001e24:	05b2                	slli	a1,a1,0xc
    80001e26:	fffff097          	auipc	ra,0xfffff
    80001e2a:	28a080e7          	jalr	650(ra) # 800010b0 <mappages>
    80001e2e:	02054863          	bltz	a0,80001e5e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001e32:	4719                	li	a4,6
    80001e34:	05893683          	ld	a3,88(s2)
    80001e38:	6605                	lui	a2,0x1
    80001e3a:	020005b7          	lui	a1,0x2000
    80001e3e:	15fd                	addi	a1,a1,-1
    80001e40:	05b6                	slli	a1,a1,0xd
    80001e42:	8526                	mv	a0,s1
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	26c080e7          	jalr	620(ra) # 800010b0 <mappages>
    80001e4c:	02054163          	bltz	a0,80001e6e <proc_pagetable+0x76>
}
    80001e50:	8526                	mv	a0,s1
    80001e52:	60e2                	ld	ra,24(sp)
    80001e54:	6442                	ld	s0,16(sp)
    80001e56:	64a2                	ld	s1,8(sp)
    80001e58:	6902                	ld	s2,0(sp)
    80001e5a:	6105                	addi	sp,sp,32
    80001e5c:	8082                	ret
    uvmfree(pagetable, 0);
    80001e5e:	4581                	li	a1,0
    80001e60:	8526                	mv	a0,s1
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	6d4080e7          	jalr	1748(ra) # 80001536 <uvmfree>
    return 0;
    80001e6a:	4481                	li	s1,0
    80001e6c:	b7d5                	j	80001e50 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e6e:	4681                	li	a3,0
    80001e70:	4605                	li	a2,1
    80001e72:	040005b7          	lui	a1,0x4000
    80001e76:	15fd                	addi	a1,a1,-1
    80001e78:	05b2                	slli	a1,a1,0xc
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	3fa080e7          	jalr	1018(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001e84:	4581                	li	a1,0
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	6ae080e7          	jalr	1710(ra) # 80001536 <uvmfree>
    return 0;
    80001e90:	4481                	li	s1,0
    80001e92:	bf7d                	j	80001e50 <proc_pagetable+0x58>

0000000080001e94 <proc_freepagetable>:
{
    80001e94:	1101                	addi	sp,sp,-32
    80001e96:	ec06                	sd	ra,24(sp)
    80001e98:	e822                	sd	s0,16(sp)
    80001e9a:	e426                	sd	s1,8(sp)
    80001e9c:	e04a                	sd	s2,0(sp)
    80001e9e:	1000                	addi	s0,sp,32
    80001ea0:	84aa                	mv	s1,a0
    80001ea2:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ea4:	4681                	li	a3,0
    80001ea6:	4605                	li	a2,1
    80001ea8:	040005b7          	lui	a1,0x4000
    80001eac:	15fd                	addi	a1,a1,-1
    80001eae:	05b2                	slli	a1,a1,0xc
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	3c6080e7          	jalr	966(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001eb8:	4681                	li	a3,0
    80001eba:	4605                	li	a2,1
    80001ebc:	020005b7          	lui	a1,0x2000
    80001ec0:	15fd                	addi	a1,a1,-1
    80001ec2:	05b6                	slli	a1,a1,0xd
    80001ec4:	8526                	mv	a0,s1
    80001ec6:	fffff097          	auipc	ra,0xfffff
    80001eca:	3b0080e7          	jalr	944(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ece:	85ca                	mv	a1,s2
    80001ed0:	8526                	mv	a0,s1
    80001ed2:	fffff097          	auipc	ra,0xfffff
    80001ed6:	664080e7          	jalr	1636(ra) # 80001536 <uvmfree>
}
    80001eda:	60e2                	ld	ra,24(sp)
    80001edc:	6442                	ld	s0,16(sp)
    80001ede:	64a2                	ld	s1,8(sp)
    80001ee0:	6902                	ld	s2,0(sp)
    80001ee2:	6105                	addi	sp,sp,32
    80001ee4:	8082                	ret

0000000080001ee6 <freeproc>:
{
    80001ee6:	1101                	addi	sp,sp,-32
    80001ee8:	ec06                	sd	ra,24(sp)
    80001eea:	e822                	sd	s0,16(sp)
    80001eec:	e426                	sd	s1,8(sp)
    80001eee:	1000                	addi	s0,sp,32
    80001ef0:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001ef2:	6d28                	ld	a0,88(a0)
    80001ef4:	c509                	beqz	a0,80001efe <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	b02080e7          	jalr	-1278(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001efe:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001f02:	68a8                	ld	a0,80(s1)
    80001f04:	c511                	beqz	a0,80001f10 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001f06:	64ac                	ld	a1,72(s1)
    80001f08:	00000097          	auipc	ra,0x0
    80001f0c:	f8c080e7          	jalr	-116(ra) # 80001e94 <proc_freepagetable>
  p->pagetable = 0;
    80001f10:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001f14:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001f18:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001f1c:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001f20:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001f24:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001f28:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001f2c:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001f30:	0004ac23          	sw	zero,24(s1)
  remove(&zombie_list, p); // remove the freed process from the ZOMBIE list
    80001f34:	85a6                	mv	a1,s1
    80001f36:	00007517          	auipc	a0,0x7
    80001f3a:	99a50513          	addi	a0,a0,-1638 # 800088d0 <zombie_list>
    80001f3e:	00000097          	auipc	ra,0x0
    80001f42:	a7c080e7          	jalr	-1412(ra) # 800019ba <remove>
  append(&unused_list, p); // admit its entry to the UNUSED entry list.
    80001f46:	85a6                	mv	a1,s1
    80001f48:	00007517          	auipc	a0,0x7
    80001f4c:	9a850513          	addi	a0,a0,-1624 # 800088f0 <unused_list>
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	9a2080e7          	jalr	-1630(ra) # 800018f2 <append>
}
    80001f58:	60e2                	ld	ra,24(sp)
    80001f5a:	6442                	ld	s0,16(sp)
    80001f5c:	64a2                	ld	s1,8(sp)
    80001f5e:	6105                	addi	sp,sp,32
    80001f60:	8082                	ret

0000000080001f62 <allocproc>:
{
    80001f62:	715d                	addi	sp,sp,-80
    80001f64:	e486                	sd	ra,72(sp)
    80001f66:	e0a2                	sd	s0,64(sp)
    80001f68:	fc26                	sd	s1,56(sp)
    80001f6a:	f84a                	sd	s2,48(sp)
    80001f6c:	f44e                	sd	s3,40(sp)
    80001f6e:	f052                	sd	s4,32(sp)
    80001f70:	ec56                	sd	s5,24(sp)
    80001f72:	e85a                	sd	s6,16(sp)
    80001f74:	e45e                	sd	s7,8(sp)
    80001f76:	0880                	addi	s0,sp,80
  h = lst->head == -1;
    80001f78:	00007917          	auipc	s2,0x7
    80001f7c:	97892903          	lw	s2,-1672(s2) # 800088f0 <unused_list>
  while(!isEmpty(&unused_list)){
    80001f80:	57fd                	li	a5,-1
    80001f82:	12f90a63          	beq	s2,a5,800020b6 <allocproc+0x154>
    80001f86:	19000a93          	li	s5,400
    p = &proc[unused_list.head];
    80001f8a:	00010a17          	auipc	s4,0x10
    80001f8e:	886a0a13          	addi	s4,s4,-1914 # 80011810 <proc>
  h = lst->head == -1;
    80001f92:	00007b97          	auipc	s7,0x7
    80001f96:	91eb8b93          	addi	s7,s7,-1762 # 800088b0 <sleeping_list>
  while(!isEmpty(&unused_list)){
    80001f9a:	5b7d                	li	s6,-1
    p = &proc[unused_list.head];
    80001f9c:	035909b3          	mul	s3,s2,s5
    80001fa0:	014984b3          	add	s1,s3,s4
    acquire(&p->lock);
    80001fa4:	8526                	mv	a0,s1
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	c3e080e7          	jalr	-962(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001fae:	4c9c                	lw	a5,24(s1)
    80001fb0:	c79d                	beqz	a5,80001fde <allocproc+0x7c>
      release(&p->lock);
    80001fb2:	8526                	mv	a0,s1
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	ce4080e7          	jalr	-796(ra) # 80000c98 <release>
  h = lst->head == -1;
    80001fbc:	040ba903          	lw	s2,64(s7)
  while(!isEmpty(&unused_list)){
    80001fc0:	fd691ee3          	bne	s2,s6,80001f9c <allocproc+0x3a>
  return 0;
    80001fc4:	4481                	li	s1,0
}
    80001fc6:	8526                	mv	a0,s1
    80001fc8:	60a6                	ld	ra,72(sp)
    80001fca:	6406                	ld	s0,64(sp)
    80001fcc:	74e2                	ld	s1,56(sp)
    80001fce:	7942                	ld	s2,48(sp)
    80001fd0:	79a2                	ld	s3,40(sp)
    80001fd2:	7a02                	ld	s4,32(sp)
    80001fd4:	6ae2                	ld	s5,24(sp)
    80001fd6:	6b42                	ld	s6,16(sp)
    80001fd8:	6ba2                	ld	s7,8(sp)
    80001fda:	6161                	addi	sp,sp,80
    80001fdc:	8082                	ret
      remove(&unused_list, p); 
    80001fde:	85a6                	mv	a1,s1
    80001fe0:	00007517          	auipc	a0,0x7
    80001fe4:	91050513          	addi	a0,a0,-1776 # 800088f0 <unused_list>
    80001fe8:	00000097          	auipc	ra,0x0
    80001fec:	9d2080e7          	jalr	-1582(ra) # 800019ba <remove>
  p->pid = allocpid();
    80001ff0:	00000097          	auipc	ra,0x0
    80001ff4:	dce080e7          	jalr	-562(ra) # 80001dbe <allocpid>
    80001ff8:	19000a13          	li	s4,400
    80001ffc:	034907b3          	mul	a5,s2,s4
    80002000:	00010a17          	auipc	s4,0x10
    80002004:	810a0a13          	addi	s4,s4,-2032 # 80011810 <proc>
    80002008:	9a3e                	add	s4,s4,a5
    8000200a:	02aa2823          	sw	a0,48(s4)
  p->state = USED;
    8000200e:	4785                	li	a5,1
    80002010:	00fa2c23          	sw	a5,24(s4)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002014:	fffff097          	auipc	ra,0xfffff
    80002018:	ae0080e7          	jalr	-1312(ra) # 80000af4 <kalloc>
    8000201c:	8aaa                	mv	s5,a0
    8000201e:	04aa3c23          	sd	a0,88(s4)
    80002022:	c135                	beqz	a0,80002086 <allocproc+0x124>
  p->pagetable = proc_pagetable(p);
    80002024:	8526                	mv	a0,s1
    80002026:	00000097          	auipc	ra,0x0
    8000202a:	dd2080e7          	jalr	-558(ra) # 80001df8 <proc_pagetable>
    8000202e:	8a2a                	mv	s4,a0
    80002030:	19000793          	li	a5,400
    80002034:	02f90733          	mul	a4,s2,a5
    80002038:	0000f797          	auipc	a5,0xf
    8000203c:	7d878793          	addi	a5,a5,2008 # 80011810 <proc>
    80002040:	97ba                	add	a5,a5,a4
    80002042:	eba8                	sd	a0,80(a5)
  if(p->pagetable == 0){
    80002044:	cd29                	beqz	a0,8000209e <allocproc+0x13c>
  memset(&p->context, 0, sizeof(p->context));
    80002046:	06098513          	addi	a0,s3,96
    8000204a:	0000f997          	auipc	s3,0xf
    8000204e:	7c698993          	addi	s3,s3,1990 # 80011810 <proc>
    80002052:	07000613          	li	a2,112
    80002056:	4581                	li	a1,0
    80002058:	954e                	add	a0,a0,s3
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	c86080e7          	jalr	-890(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80002062:	19000793          	li	a5,400
    80002066:	02f90933          	mul	s2,s2,a5
    8000206a:	994e                	add	s2,s2,s3
    8000206c:	00000797          	auipc	a5,0x0
    80002070:	d0c78793          	addi	a5,a5,-756 # 80001d78 <forkret>
    80002074:	06f93023          	sd	a5,96(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002078:	04093783          	ld	a5,64(s2)
    8000207c:	6705                	lui	a4,0x1
    8000207e:	97ba                	add	a5,a5,a4
    80002080:	06f93423          	sd	a5,104(s2)
  return p;
    80002084:	b789                	j	80001fc6 <allocproc+0x64>
    freeproc(p);
    80002086:	8526                	mv	a0,s1
    80002088:	00000097          	auipc	ra,0x0
    8000208c:	e5e080e7          	jalr	-418(ra) # 80001ee6 <freeproc>
    release(&p->lock);
    80002090:	8526                	mv	a0,s1
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	c06080e7          	jalr	-1018(ra) # 80000c98 <release>
    return 0;
    8000209a:	84d6                	mv	s1,s5
    8000209c:	b72d                	j	80001fc6 <allocproc+0x64>
    freeproc(p);
    8000209e:	8526                	mv	a0,s1
    800020a0:	00000097          	auipc	ra,0x0
    800020a4:	e46080e7          	jalr	-442(ra) # 80001ee6 <freeproc>
    release(&p->lock);
    800020a8:	8526                	mv	a0,s1
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	bee080e7          	jalr	-1042(ra) # 80000c98 <release>
    return 0;
    800020b2:	84d2                	mv	s1,s4
    800020b4:	bf09                	j	80001fc6 <allocproc+0x64>
  return 0;
    800020b6:	4481                	li	s1,0
    800020b8:	b739                	j	80001fc6 <allocproc+0x64>

00000000800020ba <userinit>:
{
    800020ba:	1101                	addi	sp,sp,-32
    800020bc:	ec06                	sd	ra,24(sp)
    800020be:	e822                	sd	s0,16(sp)
    800020c0:	e426                	sd	s1,8(sp)
    800020c2:	1000                	addi	s0,sp,32
  p = allocproc();
    800020c4:	00000097          	auipc	ra,0x0
    800020c8:	e9e080e7          	jalr	-354(ra) # 80001f62 <allocproc>
    800020cc:	84aa                	mv	s1,a0
  initproc = p;
    800020ce:	00007797          	auipc	a5,0x7
    800020d2:	f4a7bd23          	sd	a0,-166(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800020d6:	03400613          	li	a2,52
    800020da:	00007597          	auipc	a1,0x7
    800020de:	83658593          	addi	a1,a1,-1994 # 80008910 <initcode>
    800020e2:	6928                	ld	a0,80(a0)
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	284080e7          	jalr	644(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    800020ec:	6785                	lui	a5,0x1
    800020ee:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    800020f0:	6cb8                	ld	a4,88(s1)
    800020f2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800020f6:	6cb8                	ld	a4,88(s1)
    800020f8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800020fa:	4641                	li	a2,16
    800020fc:	00006597          	auipc	a1,0x6
    80002100:	18c58593          	addi	a1,a1,396 # 80008288 <digits+0x248>
    80002104:	15848513          	addi	a0,s1,344
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	d2a080e7          	jalr	-726(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80002110:	00006517          	auipc	a0,0x6
    80002114:	18850513          	addi	a0,a0,392 # 80008298 <digits+0x258>
    80002118:	00002097          	auipc	ra,0x2
    8000211c:	2c8080e7          	jalr	712(ra) # 800043e0 <namei>
    80002120:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80002124:	478d                	li	a5,3
    80002126:	cc9c                	sw	a5,24(s1)
  append(&(cpus[0].runnable_list), p); // admit the init process (the first process in the OS) to the first CPU’s list.
    80002128:	85a6                	mv	a1,s1
    8000212a:	0000f517          	auipc	a0,0xf
    8000212e:	1fe50513          	addi	a0,a0,510 # 80011328 <cpus+0x88>
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	7c0080e7          	jalr	1984(ra) # 800018f2 <append>
  release(&p->lock);
    8000213a:	8526                	mv	a0,s1
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	b5c080e7          	jalr	-1188(ra) # 80000c98 <release>
}
    80002144:	60e2                	ld	ra,24(sp)
    80002146:	6442                	ld	s0,16(sp)
    80002148:	64a2                	ld	s1,8(sp)
    8000214a:	6105                	addi	sp,sp,32
    8000214c:	8082                	ret

000000008000214e <growproc>:
{
    8000214e:	1101                	addi	sp,sp,-32
    80002150:	ec06                	sd	ra,24(sp)
    80002152:	e822                	sd	s0,16(sp)
    80002154:	e426                	sd	s1,8(sp)
    80002156:	e04a                	sd	s2,0(sp)
    80002158:	1000                	addi	s0,sp,32
    8000215a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000215c:	00000097          	auipc	ra,0x0
    80002160:	bde080e7          	jalr	-1058(ra) # 80001d3a <myproc>
    80002164:	892a                	mv	s2,a0
  sz = p->sz;
    80002166:	652c                	ld	a1,72(a0)
    80002168:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000216c:	00904f63          	bgtz	s1,8000218a <growproc+0x3c>
  } else if(n < 0){
    80002170:	0204cc63          	bltz	s1,800021a8 <growproc+0x5a>
  p->sz = sz;
    80002174:	1602                	slli	a2,a2,0x20
    80002176:	9201                	srli	a2,a2,0x20
    80002178:	04c93423          	sd	a2,72(s2)
  return 0;
    8000217c:	4501                	li	a0,0
}
    8000217e:	60e2                	ld	ra,24(sp)
    80002180:	6442                	ld	s0,16(sp)
    80002182:	64a2                	ld	s1,8(sp)
    80002184:	6902                	ld	s2,0(sp)
    80002186:	6105                	addi	sp,sp,32
    80002188:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000218a:	9e25                	addw	a2,a2,s1
    8000218c:	1602                	slli	a2,a2,0x20
    8000218e:	9201                	srli	a2,a2,0x20
    80002190:	1582                	slli	a1,a1,0x20
    80002192:	9181                	srli	a1,a1,0x20
    80002194:	6928                	ld	a0,80(a0)
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	28c080e7          	jalr	652(ra) # 80001422 <uvmalloc>
    8000219e:	0005061b          	sext.w	a2,a0
    800021a2:	fa69                	bnez	a2,80002174 <growproc+0x26>
      return -1;
    800021a4:	557d                	li	a0,-1
    800021a6:	bfe1                	j	8000217e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800021a8:	9e25                	addw	a2,a2,s1
    800021aa:	1602                	slli	a2,a2,0x20
    800021ac:	9201                	srli	a2,a2,0x20
    800021ae:	1582                	slli	a1,a1,0x20
    800021b0:	9181                	srli	a1,a1,0x20
    800021b2:	6928                	ld	a0,80(a0)
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	226080e7          	jalr	550(ra) # 800013da <uvmdealloc>
    800021bc:	0005061b          	sext.w	a2,a0
    800021c0:	bf55                	j	80002174 <growproc+0x26>

00000000800021c2 <fork>:
{
    800021c2:	7139                	addi	sp,sp,-64
    800021c4:	fc06                	sd	ra,56(sp)
    800021c6:	f822                	sd	s0,48(sp)
    800021c8:	f426                	sd	s1,40(sp)
    800021ca:	f04a                	sd	s2,32(sp)
    800021cc:	ec4e                	sd	s3,24(sp)
    800021ce:	e852                	sd	s4,16(sp)
    800021d0:	e456                	sd	s5,8(sp)
    800021d2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    800021d4:	00000097          	auipc	ra,0x0
    800021d8:	b66080e7          	jalr	-1178(ra) # 80001d3a <myproc>
    800021dc:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    800021de:	00000097          	auipc	ra,0x0
    800021e2:	d84080e7          	jalr	-636(ra) # 80001f62 <allocproc>
    800021e6:	14050663          	beqz	a0,80002332 <fork+0x170>
    800021ea:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800021ec:	04893603          	ld	a2,72(s2)
    800021f0:	692c                	ld	a1,80(a0)
    800021f2:	05093503          	ld	a0,80(s2)
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	378080e7          	jalr	888(ra) # 8000156e <uvmcopy>
    800021fe:	04054663          	bltz	a0,8000224a <fork+0x88>
  np->sz = p->sz;
    80002202:	04893783          	ld	a5,72(s2)
    80002206:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    8000220a:	05893683          	ld	a3,88(s2)
    8000220e:	87b6                	mv	a5,a3
    80002210:	0589b703          	ld	a4,88(s3)
    80002214:	12068693          	addi	a3,a3,288
    80002218:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000221c:	6788                	ld	a0,8(a5)
    8000221e:	6b8c                	ld	a1,16(a5)
    80002220:	6f90                	ld	a2,24(a5)
    80002222:	01073023          	sd	a6,0(a4)
    80002226:	e708                	sd	a0,8(a4)
    80002228:	eb0c                	sd	a1,16(a4)
    8000222a:	ef10                	sd	a2,24(a4)
    8000222c:	02078793          	addi	a5,a5,32
    80002230:	02070713          	addi	a4,a4,32
    80002234:	fed792e3          	bne	a5,a3,80002218 <fork+0x56>
  np->trapframe->a0 = 0;
    80002238:	0589b783          	ld	a5,88(s3)
    8000223c:	0607b823          	sd	zero,112(a5)
    80002240:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002244:	15000a13          	li	s4,336
    80002248:	a03d                	j	80002276 <fork+0xb4>
    freeproc(np);
    8000224a:	854e                	mv	a0,s3
    8000224c:	00000097          	auipc	ra,0x0
    80002250:	c9a080e7          	jalr	-870(ra) # 80001ee6 <freeproc>
    release(&np->lock);
    80002254:	854e                	mv	a0,s3
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	a42080e7          	jalr	-1470(ra) # 80000c98 <release>
    return -1;
    8000225e:	5afd                	li	s5,-1
    80002260:	a87d                	j	8000231e <fork+0x15c>
      np->ofile[i] = filedup(p->ofile[i]);
    80002262:	00003097          	auipc	ra,0x3
    80002266:	814080e7          	jalr	-2028(ra) # 80004a76 <filedup>
    8000226a:	009987b3          	add	a5,s3,s1
    8000226e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002270:	04a1                	addi	s1,s1,8
    80002272:	01448763          	beq	s1,s4,80002280 <fork+0xbe>
    if(p->ofile[i])
    80002276:	009907b3          	add	a5,s2,s1
    8000227a:	6388                	ld	a0,0(a5)
    8000227c:	f17d                	bnez	a0,80002262 <fork+0xa0>
    8000227e:	bfcd                	j	80002270 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002280:	15093503          	ld	a0,336(s2)
    80002284:	00002097          	auipc	ra,0x2
    80002288:	968080e7          	jalr	-1688(ra) # 80003bec <idup>
    8000228c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002290:	4641                	li	a2,16
    80002292:	15890593          	addi	a1,s2,344
    80002296:	15898513          	addi	a0,s3,344
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	b98080e7          	jalr	-1128(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    800022a2:	0309aa83          	lw	s5,48(s3)
  release(&np->lock);
    800022a6:	854e                	mv	a0,s3
    800022a8:	fffff097          	auipc	ra,0xfffff
    800022ac:	9f0080e7          	jalr	-1552(ra) # 80000c98 <release>
  acquire(&wait_lock);
    800022b0:	0000fa17          	auipc	s4,0xf
    800022b4:	ff0a0a13          	addi	s4,s4,-16 # 800112a0 <cpus>
    800022b8:	0000f497          	auipc	s1,0xf
    800022bc:	54048493          	addi	s1,s1,1344 # 800117f8 <wait_lock>
    800022c0:	8526                	mv	a0,s1
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	922080e7          	jalr	-1758(ra) # 80000be4 <acquire>
  np->parent = p;
    800022ca:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    800022ce:	8526                	mv	a0,s1
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	9c8080e7          	jalr	-1592(ra) # 80000c98 <release>
  acquire(&np->lock);
    800022d8:	854e                	mv	a0,s3
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	90a080e7          	jalr	-1782(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800022e2:	478d                	li	a5,3
    800022e4:	00f9ac23          	sw	a5,24(s3)
  np->last_cpu = p->last_cpu; // case BLNCFLG=OFF -> cpu = parent's cpu 
    800022e8:	16892483          	lw	s1,360(s2)
    800022ec:	1699a423          	sw	s1,360(s3)
  struct cpu *c = &cpus[np->last_cpu];
    800022f0:	0a800513          	li	a0,168
    800022f4:	02a484b3          	mul	s1,s1,a0
  inc_cpu(c);
    800022f8:	009a0533          	add	a0,s4,s1
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	542080e7          	jalr	1346(ra) # 8000183e <inc_cpu>
  append(&(c->runnable_list), np); // admit the new process to the father’s current CPU’s ready list
    80002304:	08848513          	addi	a0,s1,136
    80002308:	85ce                	mv	a1,s3
    8000230a:	9552                	add	a0,a0,s4
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	5e6080e7          	jalr	1510(ra) # 800018f2 <append>
  release(&np->lock);
    80002314:	854e                	mv	a0,s3
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	982080e7          	jalr	-1662(ra) # 80000c98 <release>
}
    8000231e:	8556                	mv	a0,s5
    80002320:	70e2                	ld	ra,56(sp)
    80002322:	7442                	ld	s0,48(sp)
    80002324:	74a2                	ld	s1,40(sp)
    80002326:	7902                	ld	s2,32(sp)
    80002328:	69e2                	ld	s3,24(sp)
    8000232a:	6a42                	ld	s4,16(sp)
    8000232c:	6aa2                	ld	s5,8(sp)
    8000232e:	6121                	addi	sp,sp,64
    80002330:	8082                	ret
    return -1;
    80002332:	5afd                	li	s5,-1
    80002334:	b7ed                	j	8000231e <fork+0x15c>

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
    80002352:	0000fb17          	auipc	s6,0xf
    80002356:	f4eb0b13          	addi	s6,s6,-178 # 800112a0 <cpus>
    8000235a:	0a800793          	li	a5,168
    8000235e:	02f707b3          	mul	a5,a4,a5
    80002362:	00fb06b3          	add	a3,s6,a5
    80002366:	0006b023          	sd	zero,0(a3)
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    8000236a:	08878a13          	addi	s4,a5,136
    8000236e:	9a5a                	add	s4,s4,s6
          swtch(&c->context, &p->context);
    80002370:	07a1                	addi	a5,a5,8
    80002372:	9b3e                	add	s6,s6,a5
  h = lst->head == -1;
    80002374:	8936                	mv	s2,a3
      if(p->state == RUNNABLE) {
    80002376:	0000f997          	auipc	s3,0xf
    8000237a:	49a98993          	addi	s3,s3,1178 # 80011810 <proc>
    8000237e:	19000a93          	li	s5,400
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002382:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002386:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000238a:	10079073          	csrw	sstatus,a5
    8000238e:	4b8d                	li	s7,3
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    80002390:	54fd                	li	s1,-1
    80002392:	08892783          	lw	a5,136(s2)
    80002396:	fe9786e3          	beq	a5,s1,80002382 <scheduler+0x4c>
      p =  &proc[get_head(&c->runnable_list)]; //  pick the first process from the correct CPU’s list.
    8000239a:	8552                	mv	a0,s4
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	500080e7          	jalr	1280(ra) # 8000189c <get_head>
      if(p->state == RUNNABLE) {
    800023a4:	035507b3          	mul	a5,a0,s5
    800023a8:	97ce                	add	a5,a5,s3
    800023aa:	4f9c                	lw	a5,24(a5)
    800023ac:	ff7793e3          	bne	a5,s7,80002392 <scheduler+0x5c>
    800023b0:	035504b3          	mul	s1,a0,s5
      p =  &proc[get_head(&c->runnable_list)]; //  pick the first process from the correct CPU’s list.
    800023b4:	01348c33          	add	s8,s1,s3
        acquire(&p->lock);
    800023b8:	8562                	mv	a0,s8
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	82a080e7          	jalr	-2006(ra) # 80000be4 <acquire>
          remove(&(c->runnable_list), p);
    800023c2:	85e2                	mv	a1,s8
    800023c4:	8552                	mv	a0,s4
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	5f4080e7          	jalr	1524(ra) # 800019ba <remove>
          p->state = RUNNING;
    800023ce:	4791                	li	a5,4
    800023d0:	00fc2c23          	sw	a5,24(s8)
          c->proc = p;
    800023d4:	01893023          	sd	s8,0(s2)
          p->last_cpu = c->cpu_id;
    800023d8:	08492783          	lw	a5,132(s2)
    800023dc:	16fc2423          	sw	a5,360(s8)
          swtch(&c->context, &p->context);
    800023e0:	06048593          	addi	a1,s1,96
    800023e4:	95ce                	add	a1,a1,s3
    800023e6:	855a                	mv	a0,s6
    800023e8:	00000097          	auipc	ra,0x0
    800023ec:	7de080e7          	jalr	2014(ra) # 80002bc6 <swtch>
          c->proc = 0;
    800023f0:	00093023          	sd	zero,0(s2)
        release(&p->lock);
    800023f4:	8562                	mv	a0,s8
    800023f6:	fffff097          	auipc	ra,0xfffff
    800023fa:	8a2080e7          	jalr	-1886(ra) # 80000c98 <release>
    800023fe:	bf49                	j	80002390 <scheduler+0x5a>

0000000080002400 <sched>:
{
    80002400:	7179                	addi	sp,sp,-48
    80002402:	f406                	sd	ra,40(sp)
    80002404:	f022                	sd	s0,32(sp)
    80002406:	ec26                	sd	s1,24(sp)
    80002408:	e84a                	sd	s2,16(sp)
    8000240a:	e44e                	sd	s3,8(sp)
    8000240c:	e052                	sd	s4,0(sp)
    8000240e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002410:	00000097          	auipc	ra,0x0
    80002414:	92a080e7          	jalr	-1750(ra) # 80001d3a <myproc>
    80002418:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000241a:	ffffe097          	auipc	ra,0xffffe
    8000241e:	750080e7          	jalr	1872(ra) # 80000b6a <holding>
    80002422:	c141                	beqz	a0,800024a2 <sched+0xa2>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002424:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002426:	2781                	sext.w	a5,a5
    80002428:	0a800713          	li	a4,168
    8000242c:	02e787b3          	mul	a5,a5,a4
    80002430:	0000f717          	auipc	a4,0xf
    80002434:	e7070713          	addi	a4,a4,-400 # 800112a0 <cpus>
    80002438:	97ba                	add	a5,a5,a4
    8000243a:	5fb8                	lw	a4,120(a5)
    8000243c:	4785                	li	a5,1
    8000243e:	06f71a63          	bne	a4,a5,800024b2 <sched+0xb2>
  if(p->state == RUNNING)
    80002442:	4c98                	lw	a4,24(s1)
    80002444:	4791                	li	a5,4
    80002446:	06f70e63          	beq	a4,a5,800024c2 <sched+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000244a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000244e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002450:	e3c9                	bnez	a5,800024d2 <sched+0xd2>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002452:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002454:	0000f917          	auipc	s2,0xf
    80002458:	e4c90913          	addi	s2,s2,-436 # 800112a0 <cpus>
    8000245c:	2781                	sext.w	a5,a5
    8000245e:	0a800993          	li	s3,168
    80002462:	033787b3          	mul	a5,a5,s3
    80002466:	97ca                	add	a5,a5,s2
    80002468:	07c7aa03          	lw	s4,124(a5)
    8000246c:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    8000246e:	2581                	sext.w	a1,a1
    80002470:	033585b3          	mul	a1,a1,s3
    80002474:	05a1                	addi	a1,a1,8
    80002476:	95ca                	add	a1,a1,s2
    80002478:	06048513          	addi	a0,s1,96
    8000247c:	00000097          	auipc	ra,0x0
    80002480:	74a080e7          	jalr	1866(ra) # 80002bc6 <swtch>
    80002484:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002486:	2781                	sext.w	a5,a5
    80002488:	033787b3          	mul	a5,a5,s3
    8000248c:	993e                	add	s2,s2,a5
    8000248e:	07492e23          	sw	s4,124(s2)
}
    80002492:	70a2                	ld	ra,40(sp)
    80002494:	7402                	ld	s0,32(sp)
    80002496:	64e2                	ld	s1,24(sp)
    80002498:	6942                	ld	s2,16(sp)
    8000249a:	69a2                	ld	s3,8(sp)
    8000249c:	6a02                	ld	s4,0(sp)
    8000249e:	6145                	addi	sp,sp,48
    800024a0:	8082                	ret
    panic("sched p->lock");
    800024a2:	00006517          	auipc	a0,0x6
    800024a6:	dfe50513          	addi	a0,a0,-514 # 800082a0 <digits+0x260>
    800024aa:	ffffe097          	auipc	ra,0xffffe
    800024ae:	094080e7          	jalr	148(ra) # 8000053e <panic>
    panic("sched locks");
    800024b2:	00006517          	auipc	a0,0x6
    800024b6:	dfe50513          	addi	a0,a0,-514 # 800082b0 <digits+0x270>
    800024ba:	ffffe097          	auipc	ra,0xffffe
    800024be:	084080e7          	jalr	132(ra) # 8000053e <panic>
    panic("sched running");
    800024c2:	00006517          	auipc	a0,0x6
    800024c6:	dfe50513          	addi	a0,a0,-514 # 800082c0 <digits+0x280>
    800024ca:	ffffe097          	auipc	ra,0xffffe
    800024ce:	074080e7          	jalr	116(ra) # 8000053e <panic>
    panic("sched interruptible");
    800024d2:	00006517          	auipc	a0,0x6
    800024d6:	dfe50513          	addi	a0,a0,-514 # 800082d0 <digits+0x290>
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	064080e7          	jalr	100(ra) # 8000053e <panic>

00000000800024e2 <yield>:
{
    800024e2:	1101                	addi	sp,sp,-32
    800024e4:	ec06                	sd	ra,24(sp)
    800024e6:	e822                	sd	s0,16(sp)
    800024e8:	e426                	sd	s1,8(sp)
    800024ea:	e04a                	sd	s2,0(sp)
    800024ec:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800024ee:	00000097          	auipc	ra,0x0
    800024f2:	84c080e7          	jalr	-1972(ra) # 80001d3a <myproc>
    800024f6:	84aa                	mv	s1,a0
    800024f8:	8912                	mv	s2,tp
  acquire(&p->lock);
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	6ea080e7          	jalr	1770(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002502:	478d                	li	a5,3
    80002504:	cc9c                	sw	a5,24(s1)
  append(&(c->runnable_list), p);
    80002506:	2901                	sext.w	s2,s2
    80002508:	0a800513          	li	a0,168
    8000250c:	02a90933          	mul	s2,s2,a0
    80002510:	85a6                	mv	a1,s1
    80002512:	0000f517          	auipc	a0,0xf
    80002516:	e1650513          	addi	a0,a0,-490 # 80011328 <cpus+0x88>
    8000251a:	954a                	add	a0,a0,s2
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	3d6080e7          	jalr	982(ra) # 800018f2 <append>
  sched();
    80002524:	00000097          	auipc	ra,0x0
    80002528:	edc080e7          	jalr	-292(ra) # 80002400 <sched>
  release(&p->lock);
    8000252c:	8526                	mv	a0,s1
    8000252e:	ffffe097          	auipc	ra,0xffffe
    80002532:	76a080e7          	jalr	1898(ra) # 80000c98 <release>
}
    80002536:	60e2                	ld	ra,24(sp)
    80002538:	6442                	ld	s0,16(sp)
    8000253a:	64a2                	ld	s1,8(sp)
    8000253c:	6902                	ld	s2,0(sp)
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
    80002558:	7e6080e7          	jalr	2022(ra) # 80001d3a <myproc>
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
  //printf("insert sleep sleep %d\n", p->index); //delete
  append(&sleeping_list, p);
    80002578:	85a6                	mv	a1,s1
    8000257a:	00006517          	auipc	a0,0x6
    8000257e:	33650513          	addi	a0,a0,822 # 800088b0 <sleeping_list>
    80002582:	fffff097          	auipc	ra,0xfffff
    80002586:	370080e7          	jalr	880(ra) # 800018f2 <append>

  sched();
    8000258a:	00000097          	auipc	ra,0x0
    8000258e:	e76080e7          	jalr	-394(ra) # 80002400 <sched>

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
    800025d6:	768080e7          	jalr	1896(ra) # 80001d3a <myproc>
    800025da:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800025dc:	0000f517          	auipc	a0,0xf
    800025e0:	21c50513          	addi	a0,a0,540 # 800117f8 <wait_lock>
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
    800025fe:	1fec0c13          	addi	s8,s8,510 # 800117f8 <wait_lock>
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
    80002634:	8b6080e7          	jalr	-1866(ra) # 80001ee6 <freeproc>
          release(&np->lock);
    80002638:	8526                	mv	a0,s1
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	65e080e7          	jalr	1630(ra) # 80000c98 <release>
          release(&wait_lock);
    80002642:	0000f517          	auipc	a0,0xf
    80002646:	1b650513          	addi	a0,a0,438 # 800117f8 <wait_lock>
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
    80002662:	19a50513          	addi	a0,a0,410 # 800117f8 <wait_lock>
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
    800026aa:	15250513          	addi	a0,a0,338 # 800117f8 <wait_lock>
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
    800026e0:	7159                	addi	sp,sp,-112
    800026e2:	f486                	sd	ra,104(sp)
    800026e4:	f0a2                	sd	s0,96(sp)
    800026e6:	eca6                	sd	s1,88(sp)
    800026e8:	e8ca                	sd	s2,80(sp)
    800026ea:	e4ce                	sd	s3,72(sp)
    800026ec:	e0d2                	sd	s4,64(sp)
    800026ee:	fc56                	sd	s5,56(sp)
    800026f0:	f85a                	sd	s6,48(sp)
    800026f2:	f45e                	sd	s7,40(sp)
    800026f4:	f062                	sd	s8,32(sp)
    800026f6:	ec66                	sd	s9,24(sp)
    800026f8:	e86a                	sd	s10,16(sp)
    800026fa:	e46e                	sd	s11,8(sp)
    800026fc:	1880                	addi	s0,sp,112
    800026fe:	8c2a                	mv	s8,a0
  struct proc *p;
  struct cpu *c;
  int curr = get_head(&sleeping_list);
    80002700:	00006517          	auipc	a0,0x6
    80002704:	1b050513          	addi	a0,a0,432 # 800088b0 <sleeping_list>
    80002708:	fffff097          	auipc	ra,0xfffff
    8000270c:	194080e7          	jalr	404(ra) # 8000189c <get_head>

  while(curr != -1) {
    80002710:	57fd                	li	a5,-1
    80002712:	08f50e63          	beq	a0,a5,800027ae <wakeup+0xce>
    80002716:	892a                	mv	s2,a0
    p = &proc[curr];
    80002718:	19000a93          	li	s5,400
    8000271c:	0000fa17          	auipc	s4,0xf
    80002720:	0f4a0a13          	addi	s4,s4,244 # 80011810 <proc>
    curr = p->next_proc;
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002724:	4b89                	li	s7,2
        remove(&sleeping_list, p);
        p->state = RUNNABLE;
    80002726:	4d8d                	li	s11,3
    80002728:	0a800d13          	li	s10,168

        #ifdef ON
          p->last_cpu = min_cpu_process_count(); // case BLNCFLG=ON -> cpu = CPU with the lowest counter value
        #endif
        c = &cpus[p->last_cpu];
    8000272c:	0000fc97          	auipc	s9,0xf
    80002730:	b74c8c93          	addi	s9,s9,-1164 # 800112a0 <cpus>
  while(curr != -1) {
    80002734:	5b7d                	li	s6,-1
    80002736:	a801                	j	80002746 <wakeup+0x66>
        inc_cpu(c);

        append(&(c->runnable_list), p);
      }
      release(&p->lock);
    80002738:	8526                	mv	a0,s1
    8000273a:	ffffe097          	auipc	ra,0xffffe
    8000273e:	55e080e7          	jalr	1374(ra) # 80000c98 <release>
  while(curr != -1) {
    80002742:	07690663          	beq	s2,s6,800027ae <wakeup+0xce>
    p = &proc[curr];
    80002746:	035904b3          	mul	s1,s2,s5
    8000274a:	94d2                	add	s1,s1,s4
    curr = p->next_proc;
    8000274c:	16c4a903          	lw	s2,364(s1)
    if(p != myproc()){
    80002750:	fffff097          	auipc	ra,0xfffff
    80002754:	5ea080e7          	jalr	1514(ra) # 80001d3a <myproc>
    80002758:	fea485e3          	beq	s1,a0,80002742 <wakeup+0x62>
      acquire(&p->lock);
    8000275c:	8526                	mv	a0,s1
    8000275e:	ffffe097          	auipc	ra,0xffffe
    80002762:	486080e7          	jalr	1158(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002766:	4c9c                	lw	a5,24(s1)
    80002768:	fd7798e3          	bne	a5,s7,80002738 <wakeup+0x58>
    8000276c:	709c                	ld	a5,32(s1)
    8000276e:	fd8795e3          	bne	a5,s8,80002738 <wakeup+0x58>
        remove(&sleeping_list, p);
    80002772:	85a6                	mv	a1,s1
    80002774:	00006517          	auipc	a0,0x6
    80002778:	13c50513          	addi	a0,a0,316 # 800088b0 <sleeping_list>
    8000277c:	fffff097          	auipc	ra,0xfffff
    80002780:	23e080e7          	jalr	574(ra) # 800019ba <remove>
        p->state = RUNNABLE;
    80002784:	01b4ac23          	sw	s11,24(s1)
        c = &cpus[p->last_cpu];
    80002788:	1684a983          	lw	s3,360(s1)
    8000278c:	03a989b3          	mul	s3,s3,s10
        inc_cpu(c);
    80002790:	013c8533          	add	a0,s9,s3
    80002794:	fffff097          	auipc	ra,0xfffff
    80002798:	0aa080e7          	jalr	170(ra) # 8000183e <inc_cpu>
        append(&(c->runnable_list), p);
    8000279c:	08898513          	addi	a0,s3,136
    800027a0:	85a6                	mv	a1,s1
    800027a2:	9566                	add	a0,a0,s9
    800027a4:	fffff097          	auipc	ra,0xfffff
    800027a8:	14e080e7          	jalr	334(ra) # 800018f2 <append>
    800027ac:	b771                	j	80002738 <wakeup+0x58>
    }
  }
}
    800027ae:	70a6                	ld	ra,104(sp)
    800027b0:	7406                	ld	s0,96(sp)
    800027b2:	64e6                	ld	s1,88(sp)
    800027b4:	6946                	ld	s2,80(sp)
    800027b6:	69a6                	ld	s3,72(sp)
    800027b8:	6a06                	ld	s4,64(sp)
    800027ba:	7ae2                	ld	s5,56(sp)
    800027bc:	7b42                	ld	s6,48(sp)
    800027be:	7ba2                	ld	s7,40(sp)
    800027c0:	7c02                	ld	s8,32(sp)
    800027c2:	6ce2                	ld	s9,24(sp)
    800027c4:	6d42                	ld	s10,16(sp)
    800027c6:	6da2                	ld	s11,8(sp)
    800027c8:	6165                	addi	sp,sp,112
    800027ca:	8082                	ret

00000000800027cc <reparent>:
{
    800027cc:	7179                	addi	sp,sp,-48
    800027ce:	f406                	sd	ra,40(sp)
    800027d0:	f022                	sd	s0,32(sp)
    800027d2:	ec26                	sd	s1,24(sp)
    800027d4:	e84a                	sd	s2,16(sp)
    800027d6:	e44e                	sd	s3,8(sp)
    800027d8:	e052                	sd	s4,0(sp)
    800027da:	1800                	addi	s0,sp,48
    800027dc:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800027de:	0000f497          	auipc	s1,0xf
    800027e2:	03248493          	addi	s1,s1,50 # 80011810 <proc>
      pp->parent = initproc;
    800027e6:	00007a17          	auipc	s4,0x7
    800027ea:	842a0a13          	addi	s4,s4,-1982 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800027ee:	00015997          	auipc	s3,0x15
    800027f2:	42298993          	addi	s3,s3,1058 # 80017c10 <tickslock>
    800027f6:	a029                	j	80002800 <reparent+0x34>
    800027f8:	19048493          	addi	s1,s1,400
    800027fc:	01348d63          	beq	s1,s3,80002816 <reparent+0x4a>
    if(pp->parent == p){
    80002800:	7c9c                	ld	a5,56(s1)
    80002802:	ff279be3          	bne	a5,s2,800027f8 <reparent+0x2c>
      pp->parent = initproc;
    80002806:	000a3503          	ld	a0,0(s4)
    8000280a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000280c:	00000097          	auipc	ra,0x0
    80002810:	ed4080e7          	jalr	-300(ra) # 800026e0 <wakeup>
    80002814:	b7d5                	j	800027f8 <reparent+0x2c>
}
    80002816:	70a2                	ld	ra,40(sp)
    80002818:	7402                	ld	s0,32(sp)
    8000281a:	64e2                	ld	s1,24(sp)
    8000281c:	6942                	ld	s2,16(sp)
    8000281e:	69a2                	ld	s3,8(sp)
    80002820:	6a02                	ld	s4,0(sp)
    80002822:	6145                	addi	sp,sp,48
    80002824:	8082                	ret

0000000080002826 <exit>:
{
    80002826:	7179                	addi	sp,sp,-48
    80002828:	f406                	sd	ra,40(sp)
    8000282a:	f022                	sd	s0,32(sp)
    8000282c:	ec26                	sd	s1,24(sp)
    8000282e:	e84a                	sd	s2,16(sp)
    80002830:	e44e                	sd	s3,8(sp)
    80002832:	e052                	sd	s4,0(sp)
    80002834:	1800                	addi	s0,sp,48
    80002836:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002838:	fffff097          	auipc	ra,0xfffff
    8000283c:	502080e7          	jalr	1282(ra) # 80001d3a <myproc>
    80002840:	89aa                	mv	s3,a0
  if(p == initproc)
    80002842:	00006797          	auipc	a5,0x6
    80002846:	7e67b783          	ld	a5,2022(a5) # 80009028 <initproc>
    8000284a:	0d050493          	addi	s1,a0,208
    8000284e:	15050913          	addi	s2,a0,336
    80002852:	02a79363          	bne	a5,a0,80002878 <exit+0x52>
    panic("init exiting");
    80002856:	00006517          	auipc	a0,0x6
    8000285a:	a9250513          	addi	a0,a0,-1390 # 800082e8 <digits+0x2a8>
    8000285e:	ffffe097          	auipc	ra,0xffffe
    80002862:	ce0080e7          	jalr	-800(ra) # 8000053e <panic>
      fileclose(f);
    80002866:	00002097          	auipc	ra,0x2
    8000286a:	262080e7          	jalr	610(ra) # 80004ac8 <fileclose>
      p->ofile[fd] = 0;
    8000286e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002872:	04a1                	addi	s1,s1,8
    80002874:	01248563          	beq	s1,s2,8000287e <exit+0x58>
    if(p->ofile[fd]){
    80002878:	6088                	ld	a0,0(s1)
    8000287a:	f575                	bnez	a0,80002866 <exit+0x40>
    8000287c:	bfdd                	j	80002872 <exit+0x4c>
  begin_op();
    8000287e:	00002097          	auipc	ra,0x2
    80002882:	d7e080e7          	jalr	-642(ra) # 800045fc <begin_op>
  iput(p->cwd);
    80002886:	1509b503          	ld	a0,336(s3)
    8000288a:	00001097          	auipc	ra,0x1
    8000288e:	55a080e7          	jalr	1370(ra) # 80003de4 <iput>
  end_op();
    80002892:	00002097          	auipc	ra,0x2
    80002896:	dea080e7          	jalr	-534(ra) # 8000467c <end_op>
  p->cwd = 0;
    8000289a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000289e:	0000f497          	auipc	s1,0xf
    800028a2:	f5a48493          	addi	s1,s1,-166 # 800117f8 <wait_lock>
    800028a6:	8526                	mv	a0,s1
    800028a8:	ffffe097          	auipc	ra,0xffffe
    800028ac:	33c080e7          	jalr	828(ra) # 80000be4 <acquire>
  reparent(p);
    800028b0:	854e                	mv	a0,s3
    800028b2:	00000097          	auipc	ra,0x0
    800028b6:	f1a080e7          	jalr	-230(ra) # 800027cc <reparent>
  wakeup(p->parent);
    800028ba:	0389b503          	ld	a0,56(s3)
    800028be:	00000097          	auipc	ra,0x0
    800028c2:	e22080e7          	jalr	-478(ra) # 800026e0 <wakeup>
  acquire(&p->lock);
    800028c6:	854e                	mv	a0,s3
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	31c080e7          	jalr	796(ra) # 80000be4 <acquire>
  p->xstate = status;
    800028d0:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800028d4:	4795                	li	a5,5
    800028d6:	00f9ac23          	sw	a5,24(s3)
  append(&zombie_list, p); // exit to admit the exiting process to the ZOMBIE list
    800028da:	85ce                	mv	a1,s3
    800028dc:	00006517          	auipc	a0,0x6
    800028e0:	ff450513          	addi	a0,a0,-12 # 800088d0 <zombie_list>
    800028e4:	fffff097          	auipc	ra,0xfffff
    800028e8:	00e080e7          	jalr	14(ra) # 800018f2 <append>
  release(&wait_lock);
    800028ec:	8526                	mv	a0,s1
    800028ee:	ffffe097          	auipc	ra,0xffffe
    800028f2:	3aa080e7          	jalr	938(ra) # 80000c98 <release>
  sched();
    800028f6:	00000097          	auipc	ra,0x0
    800028fa:	b0a080e7          	jalr	-1270(ra) # 80002400 <sched>
  panic("zombie exit");
    800028fe:	00006517          	auipc	a0,0x6
    80002902:	9fa50513          	addi	a0,a0,-1542 # 800082f8 <digits+0x2b8>
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	c38080e7          	jalr	-968(ra) # 8000053e <panic>

000000008000290e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000290e:	7179                	addi	sp,sp,-48
    80002910:	f406                	sd	ra,40(sp)
    80002912:	f022                	sd	s0,32(sp)
    80002914:	ec26                	sd	s1,24(sp)
    80002916:	e84a                	sd	s2,16(sp)
    80002918:	e44e                	sd	s3,8(sp)
    8000291a:	1800                	addi	s0,sp,48
    8000291c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000291e:	0000f497          	auipc	s1,0xf
    80002922:	ef248493          	addi	s1,s1,-270 # 80011810 <proc>
    80002926:	00015997          	auipc	s3,0x15
    8000292a:	2ea98993          	addi	s3,s3,746 # 80017c10 <tickslock>
    acquire(&p->lock);
    8000292e:	8526                	mv	a0,s1
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	2b4080e7          	jalr	692(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002938:	589c                	lw	a5,48(s1)
    8000293a:	01278d63          	beq	a5,s2,80002954 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000293e:	8526                	mv	a0,s1
    80002940:	ffffe097          	auipc	ra,0xffffe
    80002944:	358080e7          	jalr	856(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002948:	19048493          	addi	s1,s1,400
    8000294c:	ff3491e3          	bne	s1,s3,8000292e <kill+0x20>
  }
  return -1;
    80002950:	557d                	li	a0,-1
    80002952:	a829                	j	8000296c <kill+0x5e>
      p->killed = 1;
    80002954:	4785                	li	a5,1
    80002956:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002958:	4c98                	lw	a4,24(s1)
    8000295a:	4789                	li	a5,2
    8000295c:	00f70f63          	beq	a4,a5,8000297a <kill+0x6c>
      release(&p->lock);
    80002960:	8526                	mv	a0,s1
    80002962:	ffffe097          	auipc	ra,0xffffe
    80002966:	336080e7          	jalr	822(ra) # 80000c98 <release>
      return 0;
    8000296a:	4501                	li	a0,0
}
    8000296c:	70a2                	ld	ra,40(sp)
    8000296e:	7402                	ld	s0,32(sp)
    80002970:	64e2                	ld	s1,24(sp)
    80002972:	6942                	ld	s2,16(sp)
    80002974:	69a2                	ld	s3,8(sp)
    80002976:	6145                	addi	sp,sp,48
    80002978:	8082                	ret
        p->state = RUNNABLE;
    8000297a:	478d                	li	a5,3
    8000297c:	cc9c                	sw	a5,24(s1)
    8000297e:	b7cd                	j	80002960 <kill+0x52>

0000000080002980 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002980:	7179                	addi	sp,sp,-48
    80002982:	f406                	sd	ra,40(sp)
    80002984:	f022                	sd	s0,32(sp)
    80002986:	ec26                	sd	s1,24(sp)
    80002988:	e84a                	sd	s2,16(sp)
    8000298a:	e44e                	sd	s3,8(sp)
    8000298c:	e052                	sd	s4,0(sp)
    8000298e:	1800                	addi	s0,sp,48
    80002990:	84aa                	mv	s1,a0
    80002992:	892e                	mv	s2,a1
    80002994:	89b2                	mv	s3,a2
    80002996:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002998:	fffff097          	auipc	ra,0xfffff
    8000299c:	3a2080e7          	jalr	930(ra) # 80001d3a <myproc>
  if(user_dst){
    800029a0:	c08d                	beqz	s1,800029c2 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800029a2:	86d2                	mv	a3,s4
    800029a4:	864e                	mv	a2,s3
    800029a6:	85ca                	mv	a1,s2
    800029a8:	6928                	ld	a0,80(a0)
    800029aa:	fffff097          	auipc	ra,0xfffff
    800029ae:	cc8080e7          	jalr	-824(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800029b2:	70a2                	ld	ra,40(sp)
    800029b4:	7402                	ld	s0,32(sp)
    800029b6:	64e2                	ld	s1,24(sp)
    800029b8:	6942                	ld	s2,16(sp)
    800029ba:	69a2                	ld	s3,8(sp)
    800029bc:	6a02                	ld	s4,0(sp)
    800029be:	6145                	addi	sp,sp,48
    800029c0:	8082                	ret
    memmove((char *)dst, src, len);
    800029c2:	000a061b          	sext.w	a2,s4
    800029c6:	85ce                	mv	a1,s3
    800029c8:	854a                	mv	a0,s2
    800029ca:	ffffe097          	auipc	ra,0xffffe
    800029ce:	376080e7          	jalr	886(ra) # 80000d40 <memmove>
    return 0;
    800029d2:	8526                	mv	a0,s1
    800029d4:	bff9                	j	800029b2 <either_copyout+0x32>

00000000800029d6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800029d6:	7179                	addi	sp,sp,-48
    800029d8:	f406                	sd	ra,40(sp)
    800029da:	f022                	sd	s0,32(sp)
    800029dc:	ec26                	sd	s1,24(sp)
    800029de:	e84a                	sd	s2,16(sp)
    800029e0:	e44e                	sd	s3,8(sp)
    800029e2:	e052                	sd	s4,0(sp)
    800029e4:	1800                	addi	s0,sp,48
    800029e6:	892a                	mv	s2,a0
    800029e8:	84ae                	mv	s1,a1
    800029ea:	89b2                	mv	s3,a2
    800029ec:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029ee:	fffff097          	auipc	ra,0xfffff
    800029f2:	34c080e7          	jalr	844(ra) # 80001d3a <myproc>
  if(user_src){
    800029f6:	c08d                	beqz	s1,80002a18 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800029f8:	86d2                	mv	a3,s4
    800029fa:	864e                	mv	a2,s3
    800029fc:	85ca                	mv	a1,s2
    800029fe:	6928                	ld	a0,80(a0)
    80002a00:	fffff097          	auipc	ra,0xfffff
    80002a04:	cfe080e7          	jalr	-770(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002a08:	70a2                	ld	ra,40(sp)
    80002a0a:	7402                	ld	s0,32(sp)
    80002a0c:	64e2                	ld	s1,24(sp)
    80002a0e:	6942                	ld	s2,16(sp)
    80002a10:	69a2                	ld	s3,8(sp)
    80002a12:	6a02                	ld	s4,0(sp)
    80002a14:	6145                	addi	sp,sp,48
    80002a16:	8082                	ret
    memmove(dst, (char*)src, len);
    80002a18:	000a061b          	sext.w	a2,s4
    80002a1c:	85ce                	mv	a1,s3
    80002a1e:	854a                	mv	a0,s2
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	320080e7          	jalr	800(ra) # 80000d40 <memmove>
    return 0;
    80002a28:	8526                	mv	a0,s1
    80002a2a:	bff9                	j	80002a08 <either_copyin+0x32>

0000000080002a2c <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    80002a2c:	715d                	addi	sp,sp,-80
    80002a2e:	e486                	sd	ra,72(sp)
    80002a30:	e0a2                	sd	s0,64(sp)
    80002a32:	fc26                	sd	s1,56(sp)
    80002a34:	f84a                	sd	s2,48(sp)
    80002a36:	f44e                	sd	s3,40(sp)
    80002a38:	f052                	sd	s4,32(sp)
    80002a3a:	ec56                	sd	s5,24(sp)
    80002a3c:	e85a                	sd	s6,16(sp)
    80002a3e:	e45e                	sd	s7,8(sp)
    80002a40:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002a42:	00005517          	auipc	a0,0x5
    80002a46:	68650513          	addi	a0,a0,1670 # 800080c8 <digits+0x88>
    80002a4a:	ffffe097          	auipc	ra,0xffffe
    80002a4e:	b3e080e7          	jalr	-1218(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a52:	0000f497          	auipc	s1,0xf
    80002a56:	f1648493          	addi	s1,s1,-234 # 80011968 <proc+0x158>
    80002a5a:	00015917          	auipc	s2,0x15
    80002a5e:	30e90913          	addi	s2,s2,782 # 80017d68 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a62:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    80002a64:	00006997          	auipc	s3,0x6
    80002a68:	8a498993          	addi	s3,s3,-1884 # 80008308 <digits+0x2c8>
    printf("%d %s %s", p->pid, state, p->name);
    80002a6c:	00006a97          	auipc	s5,0x6
    80002a70:	8a4a8a93          	addi	s5,s5,-1884 # 80008310 <digits+0x2d0>
    printf("\n");
    80002a74:	00005a17          	auipc	s4,0x5
    80002a78:	654a0a13          	addi	s4,s4,1620 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a7c:	00006b97          	auipc	s7,0x6
    80002a80:	8ccb8b93          	addi	s7,s7,-1844 # 80008348 <states.1780>
    80002a84:	a00d                	j	80002aa6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002a86:	ed86a583          	lw	a1,-296(a3)
    80002a8a:	8556                	mv	a0,s5
    80002a8c:	ffffe097          	auipc	ra,0xffffe
    80002a90:	afc080e7          	jalr	-1284(ra) # 80000588 <printf>
    printf("\n");
    80002a94:	8552                	mv	a0,s4
    80002a96:	ffffe097          	auipc	ra,0xffffe
    80002a9a:	af2080e7          	jalr	-1294(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a9e:	19048493          	addi	s1,s1,400
    80002aa2:	03248163          	beq	s1,s2,80002ac4 <procdump+0x98>
    if(p->state == UNUSED)
    80002aa6:	86a6                	mv	a3,s1
    80002aa8:	ec04a783          	lw	a5,-320(s1)
    80002aac:	dbed                	beqz	a5,80002a9e <procdump+0x72>
      state = "???"; 
    80002aae:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ab0:	fcfb6be3          	bltu	s6,a5,80002a86 <procdump+0x5a>
    80002ab4:	1782                	slli	a5,a5,0x20
    80002ab6:	9381                	srli	a5,a5,0x20
    80002ab8:	078e                	slli	a5,a5,0x3
    80002aba:	97de                	add	a5,a5,s7
    80002abc:	6390                	ld	a2,0(a5)
    80002abe:	f661                	bnez	a2,80002a86 <procdump+0x5a>
      state = "???"; 
    80002ac0:	864e                	mv	a2,s3
    80002ac2:	b7d1                	j	80002a86 <procdump+0x5a>
  }
}
    80002ac4:	60a6                	ld	ra,72(sp)
    80002ac6:	6406                	ld	s0,64(sp)
    80002ac8:	74e2                	ld	s1,56(sp)
    80002aca:	7942                	ld	s2,48(sp)
    80002acc:	79a2                	ld	s3,40(sp)
    80002ace:	7a02                	ld	s4,32(sp)
    80002ad0:	6ae2                	ld	s5,24(sp)
    80002ad2:	6b42                	ld	s6,16(sp)
    80002ad4:	6ba2                	ld	s7,8(sp)
    80002ad6:	6161                	addi	sp,sp,80
    80002ad8:	8082                	ret

0000000080002ada <set_cpu>:

// assign current process to a different CPU. 
int
set_cpu(int cpu_num){
    80002ada:	1101                	addi	sp,sp,-32
    80002adc:	ec06                	sd	ra,24(sp)
    80002ade:	e822                	sd	s0,16(sp)
    80002ae0:	e426                	sd	s1,8(sp)
    80002ae2:	e04a                	sd	s2,0(sp)
    80002ae4:	1000                	addi	s0,sp,32
    80002ae6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ae8:	fffff097          	auipc	ra,0xfffff
    80002aec:	252080e7          	jalr	594(ra) # 80001d3a <myproc>
  if(cpu_num >= 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL){
    80002af0:	0004871b          	sext.w	a4,s1
    80002af4:	479d                	li	a5,7
    80002af6:	02e7e963          	bltu	a5,a4,80002b28 <set_cpu+0x4e>
    80002afa:	892a                	mv	s2,a0
    acquire(&p->lock);
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	0e8080e7          	jalr	232(ra) # 80000be4 <acquire>
    p->last_cpu = cpu_num;
    80002b04:	16992423          	sw	s1,360(s2)
    release(&p->lock);
    80002b08:	854a                	mv	a0,s2
    80002b0a:	ffffe097          	auipc	ra,0xffffe
    80002b0e:	18e080e7          	jalr	398(ra) # 80000c98 <release>

    yield();
    80002b12:	00000097          	auipc	ra,0x0
    80002b16:	9d0080e7          	jalr	-1584(ra) # 800024e2 <yield>

    return cpu_num;
    80002b1a:	8526                	mv	a0,s1
  }
  return -1;
}
    80002b1c:	60e2                	ld	ra,24(sp)
    80002b1e:	6442                	ld	s0,16(sp)
    80002b20:	64a2                	ld	s1,8(sp)
    80002b22:	6902                	ld	s2,0(sp)
    80002b24:	6105                	addi	sp,sp,32
    80002b26:	8082                	ret
  return -1;
    80002b28:	557d                	li	a0,-1
    80002b2a:	bfcd                	j	80002b1c <set_cpu+0x42>

0000000080002b2c <get_cpu>:

// return the current CPU id.
int
get_cpu(void){
    80002b2c:	1141                	addi	sp,sp,-16
    80002b2e:	e406                	sd	ra,8(sp)
    80002b30:	e022                	sd	s0,0(sp)
    80002b32:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b34:	fffff097          	auipc	ra,0xfffff
    80002b38:	206080e7          	jalr	518(ra) # 80001d3a <myproc>
  return p->last_cpu;
}
    80002b3c:	16852503          	lw	a0,360(a0)
    80002b40:	60a2                	ld	ra,8(sp)
    80002b42:	6402                	ld	s0,0(sp)
    80002b44:	0141                	addi	sp,sp,16
    80002b46:	8082                	ret

0000000080002b48 <min_cpu>:

int
min_cpu(void){
    80002b48:	1141                	addi	sp,sp,-16
    80002b4a:	e422                	sd	s0,8(sp)
    80002b4c:	0800                	addi	s0,sp,16
  struct cpu *c, *min_cpu;
// should add an if to insure numberOfCpus>0
  min_cpu = cpus;
    80002b4e:	0000e617          	auipc	a2,0xe
    80002b52:	75260613          	addi	a2,a2,1874 # 800112a0 <cpus>
  for(c = cpus + 1; c < &cpus[NCPU] && c != NULL ; c++){
    80002b56:	0000e797          	auipc	a5,0xe
    80002b5a:	7f278793          	addi	a5,a5,2034 # 80011348 <cpus+0xa8>
    80002b5e:	0000f597          	auipc	a1,0xf
    80002b62:	c8258593          	addi	a1,a1,-894 # 800117e0 <pid_lock>
    80002b66:	a029                	j	80002b70 <min_cpu+0x28>
    80002b68:	0a878793          	addi	a5,a5,168
    80002b6c:	00b78a63          	beq	a5,a1,80002b80 <min_cpu+0x38>
    if (c->proc_cnt < min_cpu->proc_cnt)
    80002b70:	0807a683          	lw	a3,128(a5)
    80002b74:	08062703          	lw	a4,128(a2)
    80002b78:	fee6d8e3          	bge	a3,a4,80002b68 <min_cpu+0x20>
    80002b7c:	863e                	mv	a2,a5
    80002b7e:	b7ed                	j	80002b68 <min_cpu+0x20>
        min_cpu = c;
  }
  return min_cpu->cpu_id;   
}
    80002b80:	08462503          	lw	a0,132(a2)
    80002b84:	6422                	ld	s0,8(sp)
    80002b86:	0141                	addi	sp,sp,16
    80002b88:	8082                	ret

0000000080002b8a <cpu_process_count>:

int
cpu_process_count(int cpu_num){
    80002b8a:	1141                	addi	sp,sp,-16
    80002b8c:	e422                	sd	s0,8(sp)
    80002b8e:	0800                	addi	s0,sp,16
  if (cpu_num > 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL) 
    80002b90:	fff5071b          	addiw	a4,a0,-1
    80002b94:	4799                	li	a5,6
    80002b96:	02e7e063          	bltu	a5,a4,80002bb6 <cpu_process_count+0x2c>
    return cpus[cpu_num].proc_cnt;
    80002b9a:	0a800793          	li	a5,168
    80002b9e:	02f50533          	mul	a0,a0,a5
    80002ba2:	0000e797          	auipc	a5,0xe
    80002ba6:	6fe78793          	addi	a5,a5,1790 # 800112a0 <cpus>
    80002baa:	953e                	add	a0,a0,a5
    80002bac:	08052503          	lw	a0,128(a0)
  return -1;
}
    80002bb0:	6422                	ld	s0,8(sp)
    80002bb2:	0141                	addi	sp,sp,16
    80002bb4:	8082                	ret
  return -1;
    80002bb6:	557d                	li	a0,-1
    80002bb8:	bfe5                	j	80002bb0 <cpu_process_count+0x26>

0000000080002bba <steal_process>:




void
steal_process(struct cpu *curr_c){  /*
    80002bba:	1141                	addi	sp,sp,-16
    80002bbc:	e422                	sd	s0,8(sp)
    80002bbe:	0800                	addi	s0,sp,16
  }
  p = proc[stolen_process];
  append(&c->runnable_list, p);
  p->last_cpu = c->cpu_id;
  inc_cpu(c); */
    80002bc0:	6422                	ld	s0,8(sp)
    80002bc2:	0141                	addi	sp,sp,16
    80002bc4:	8082                	ret

0000000080002bc6 <swtch>:
    80002bc6:	00153023          	sd	ra,0(a0)
    80002bca:	00253423          	sd	sp,8(a0)
    80002bce:	e900                	sd	s0,16(a0)
    80002bd0:	ed04                	sd	s1,24(a0)
    80002bd2:	03253023          	sd	s2,32(a0)
    80002bd6:	03353423          	sd	s3,40(a0)
    80002bda:	03453823          	sd	s4,48(a0)
    80002bde:	03553c23          	sd	s5,56(a0)
    80002be2:	05653023          	sd	s6,64(a0)
    80002be6:	05753423          	sd	s7,72(a0)
    80002bea:	05853823          	sd	s8,80(a0)
    80002bee:	05953c23          	sd	s9,88(a0)
    80002bf2:	07a53023          	sd	s10,96(a0)
    80002bf6:	07b53423          	sd	s11,104(a0)
    80002bfa:	0005b083          	ld	ra,0(a1)
    80002bfe:	0085b103          	ld	sp,8(a1)
    80002c02:	6980                	ld	s0,16(a1)
    80002c04:	6d84                	ld	s1,24(a1)
    80002c06:	0205b903          	ld	s2,32(a1)
    80002c0a:	0285b983          	ld	s3,40(a1)
    80002c0e:	0305ba03          	ld	s4,48(a1)
    80002c12:	0385ba83          	ld	s5,56(a1)
    80002c16:	0405bb03          	ld	s6,64(a1)
    80002c1a:	0485bb83          	ld	s7,72(a1)
    80002c1e:	0505bc03          	ld	s8,80(a1)
    80002c22:	0585bc83          	ld	s9,88(a1)
    80002c26:	0605bd03          	ld	s10,96(a1)
    80002c2a:	0685bd83          	ld	s11,104(a1)
    80002c2e:	8082                	ret

0000000080002c30 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c30:	1141                	addi	sp,sp,-16
    80002c32:	e406                	sd	ra,8(sp)
    80002c34:	e022                	sd	s0,0(sp)
    80002c36:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c38:	00005597          	auipc	a1,0x5
    80002c3c:	74058593          	addi	a1,a1,1856 # 80008378 <states.1780+0x30>
    80002c40:	00015517          	auipc	a0,0x15
    80002c44:	fd050513          	addi	a0,a0,-48 # 80017c10 <tickslock>
    80002c48:	ffffe097          	auipc	ra,0xffffe
    80002c4c:	f0c080e7          	jalr	-244(ra) # 80000b54 <initlock>
}
    80002c50:	60a2                	ld	ra,8(sp)
    80002c52:	6402                	ld	s0,0(sp)
    80002c54:	0141                	addi	sp,sp,16
    80002c56:	8082                	ret

0000000080002c58 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c58:	1141                	addi	sp,sp,-16
    80002c5a:	e422                	sd	s0,8(sp)
    80002c5c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c5e:	00003797          	auipc	a5,0x3
    80002c62:	48278793          	addi	a5,a5,1154 # 800060e0 <kernelvec>
    80002c66:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c6a:	6422                	ld	s0,8(sp)
    80002c6c:	0141                	addi	sp,sp,16
    80002c6e:	8082                	ret

0000000080002c70 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002c70:	1141                	addi	sp,sp,-16
    80002c72:	e406                	sd	ra,8(sp)
    80002c74:	e022                	sd	s0,0(sp)
    80002c76:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c78:	fffff097          	auipc	ra,0xfffff
    80002c7c:	0c2080e7          	jalr	194(ra) # 80001d3a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c80:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c84:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c86:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002c8a:	00004617          	auipc	a2,0x4
    80002c8e:	37660613          	addi	a2,a2,886 # 80007000 <_trampoline>
    80002c92:	00004697          	auipc	a3,0x4
    80002c96:	36e68693          	addi	a3,a3,878 # 80007000 <_trampoline>
    80002c9a:	8e91                	sub	a3,a3,a2
    80002c9c:	040007b7          	lui	a5,0x4000
    80002ca0:	17fd                	addi	a5,a5,-1
    80002ca2:	07b2                	slli	a5,a5,0xc
    80002ca4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ca6:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002caa:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002cac:	180026f3          	csrr	a3,satp
    80002cb0:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002cb2:	6d38                	ld	a4,88(a0)
    80002cb4:	6134                	ld	a3,64(a0)
    80002cb6:	6585                	lui	a1,0x1
    80002cb8:	96ae                	add	a3,a3,a1
    80002cba:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002cbc:	6d38                	ld	a4,88(a0)
    80002cbe:	00000697          	auipc	a3,0x0
    80002cc2:	13868693          	addi	a3,a3,312 # 80002df6 <usertrap>
    80002cc6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002cc8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002cca:	8692                	mv	a3,tp
    80002ccc:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cce:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002cd2:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002cd6:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cda:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002cde:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ce0:	6f18                	ld	a4,24(a4)
    80002ce2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002ce6:	692c                	ld	a1,80(a0)
    80002ce8:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002cea:	00004717          	auipc	a4,0x4
    80002cee:	3a670713          	addi	a4,a4,934 # 80007090 <userret>
    80002cf2:	8f11                	sub	a4,a4,a2
    80002cf4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002cf6:	577d                	li	a4,-1
    80002cf8:	177e                	slli	a4,a4,0x3f
    80002cfa:	8dd9                	or	a1,a1,a4
    80002cfc:	02000537          	lui	a0,0x2000
    80002d00:	157d                	addi	a0,a0,-1
    80002d02:	0536                	slli	a0,a0,0xd
    80002d04:	9782                	jalr	a5
}
    80002d06:	60a2                	ld	ra,8(sp)
    80002d08:	6402                	ld	s0,0(sp)
    80002d0a:	0141                	addi	sp,sp,16
    80002d0c:	8082                	ret

0000000080002d0e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d0e:	1101                	addi	sp,sp,-32
    80002d10:	ec06                	sd	ra,24(sp)
    80002d12:	e822                	sd	s0,16(sp)
    80002d14:	e426                	sd	s1,8(sp)
    80002d16:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d18:	00015497          	auipc	s1,0x15
    80002d1c:	ef848493          	addi	s1,s1,-264 # 80017c10 <tickslock>
    80002d20:	8526                	mv	a0,s1
    80002d22:	ffffe097          	auipc	ra,0xffffe
    80002d26:	ec2080e7          	jalr	-318(ra) # 80000be4 <acquire>
  ticks++;
    80002d2a:	00006517          	auipc	a0,0x6
    80002d2e:	30650513          	addi	a0,a0,774 # 80009030 <ticks>
    80002d32:	411c                	lw	a5,0(a0)
    80002d34:	2785                	addiw	a5,a5,1
    80002d36:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002d38:	00000097          	auipc	ra,0x0
    80002d3c:	9a8080e7          	jalr	-1624(ra) # 800026e0 <wakeup>
  release(&tickslock);
    80002d40:	8526                	mv	a0,s1
    80002d42:	ffffe097          	auipc	ra,0xffffe
    80002d46:	f56080e7          	jalr	-170(ra) # 80000c98 <release>
}
    80002d4a:	60e2                	ld	ra,24(sp)
    80002d4c:	6442                	ld	s0,16(sp)
    80002d4e:	64a2                	ld	s1,8(sp)
    80002d50:	6105                	addi	sp,sp,32
    80002d52:	8082                	ret

0000000080002d54 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002d54:	1101                	addi	sp,sp,-32
    80002d56:	ec06                	sd	ra,24(sp)
    80002d58:	e822                	sd	s0,16(sp)
    80002d5a:	e426                	sd	s1,8(sp)
    80002d5c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d5e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002d62:	00074d63          	bltz	a4,80002d7c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002d66:	57fd                	li	a5,-1
    80002d68:	17fe                	slli	a5,a5,0x3f
    80002d6a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002d6c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002d6e:	06f70363          	beq	a4,a5,80002dd4 <devintr+0x80>
  }
}
    80002d72:	60e2                	ld	ra,24(sp)
    80002d74:	6442                	ld	s0,16(sp)
    80002d76:	64a2                	ld	s1,8(sp)
    80002d78:	6105                	addi	sp,sp,32
    80002d7a:	8082                	ret
     (scause & 0xff) == 9){
    80002d7c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002d80:	46a5                	li	a3,9
    80002d82:	fed792e3          	bne	a5,a3,80002d66 <devintr+0x12>
    int irq = plic_claim();
    80002d86:	00003097          	auipc	ra,0x3
    80002d8a:	462080e7          	jalr	1122(ra) # 800061e8 <plic_claim>
    80002d8e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d90:	47a9                	li	a5,10
    80002d92:	02f50763          	beq	a0,a5,80002dc0 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002d96:	4785                	li	a5,1
    80002d98:	02f50963          	beq	a0,a5,80002dca <devintr+0x76>
    return 1;
    80002d9c:	4505                	li	a0,1
    } else if(irq){
    80002d9e:	d8f1                	beqz	s1,80002d72 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002da0:	85a6                	mv	a1,s1
    80002da2:	00005517          	auipc	a0,0x5
    80002da6:	5de50513          	addi	a0,a0,1502 # 80008380 <states.1780+0x38>
    80002daa:	ffffd097          	auipc	ra,0xffffd
    80002dae:	7de080e7          	jalr	2014(ra) # 80000588 <printf>
      plic_complete(irq);
    80002db2:	8526                	mv	a0,s1
    80002db4:	00003097          	auipc	ra,0x3
    80002db8:	458080e7          	jalr	1112(ra) # 8000620c <plic_complete>
    return 1;
    80002dbc:	4505                	li	a0,1
    80002dbe:	bf55                	j	80002d72 <devintr+0x1e>
      uartintr();
    80002dc0:	ffffe097          	auipc	ra,0xffffe
    80002dc4:	be8080e7          	jalr	-1048(ra) # 800009a8 <uartintr>
    80002dc8:	b7ed                	j	80002db2 <devintr+0x5e>
      virtio_disk_intr();
    80002dca:	00004097          	auipc	ra,0x4
    80002dce:	922080e7          	jalr	-1758(ra) # 800066ec <virtio_disk_intr>
    80002dd2:	b7c5                	j	80002db2 <devintr+0x5e>
    if(cpuid() == 0){
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	f34080e7          	jalr	-204(ra) # 80001d08 <cpuid>
    80002ddc:	c901                	beqz	a0,80002dec <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002dde:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002de2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002de4:	14479073          	csrw	sip,a5
    return 2;
    80002de8:	4509                	li	a0,2
    80002dea:	b761                	j	80002d72 <devintr+0x1e>
      clockintr();
    80002dec:	00000097          	auipc	ra,0x0
    80002df0:	f22080e7          	jalr	-222(ra) # 80002d0e <clockintr>
    80002df4:	b7ed                	j	80002dde <devintr+0x8a>

0000000080002df6 <usertrap>:
{
    80002df6:	1101                	addi	sp,sp,-32
    80002df8:	ec06                	sd	ra,24(sp)
    80002dfa:	e822                	sd	s0,16(sp)
    80002dfc:	e426                	sd	s1,8(sp)
    80002dfe:	e04a                	sd	s2,0(sp)
    80002e00:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e02:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e06:	1007f793          	andi	a5,a5,256
    80002e0a:	e3ad                	bnez	a5,80002e6c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e0c:	00003797          	auipc	a5,0x3
    80002e10:	2d478793          	addi	a5,a5,724 # 800060e0 <kernelvec>
    80002e14:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e18:	fffff097          	auipc	ra,0xfffff
    80002e1c:	f22080e7          	jalr	-222(ra) # 80001d3a <myproc>
    80002e20:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e22:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e24:	14102773          	csrr	a4,sepc
    80002e28:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e2a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002e2e:	47a1                	li	a5,8
    80002e30:	04f71c63          	bne	a4,a5,80002e88 <usertrap+0x92>
    if(p->killed)
    80002e34:	551c                	lw	a5,40(a0)
    80002e36:	e3b9                	bnez	a5,80002e7c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002e38:	6cb8                	ld	a4,88(s1)
    80002e3a:	6f1c                	ld	a5,24(a4)
    80002e3c:	0791                	addi	a5,a5,4
    80002e3e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e40:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e44:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e48:	10079073          	csrw	sstatus,a5
    syscall();
    80002e4c:	00000097          	auipc	ra,0x0
    80002e50:	2e0080e7          	jalr	736(ra) # 8000312c <syscall>
  if(p->killed)
    80002e54:	549c                	lw	a5,40(s1)
    80002e56:	ebc1                	bnez	a5,80002ee6 <usertrap+0xf0>
  usertrapret();
    80002e58:	00000097          	auipc	ra,0x0
    80002e5c:	e18080e7          	jalr	-488(ra) # 80002c70 <usertrapret>
}
    80002e60:	60e2                	ld	ra,24(sp)
    80002e62:	6442                	ld	s0,16(sp)
    80002e64:	64a2                	ld	s1,8(sp)
    80002e66:	6902                	ld	s2,0(sp)
    80002e68:	6105                	addi	sp,sp,32
    80002e6a:	8082                	ret
    panic("usertrap: not from user mode");
    80002e6c:	00005517          	auipc	a0,0x5
    80002e70:	53450513          	addi	a0,a0,1332 # 800083a0 <states.1780+0x58>
    80002e74:	ffffd097          	auipc	ra,0xffffd
    80002e78:	6ca080e7          	jalr	1738(ra) # 8000053e <panic>
      exit(-1);
    80002e7c:	557d                	li	a0,-1
    80002e7e:	00000097          	auipc	ra,0x0
    80002e82:	9a8080e7          	jalr	-1624(ra) # 80002826 <exit>
    80002e86:	bf4d                	j	80002e38 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002e88:	00000097          	auipc	ra,0x0
    80002e8c:	ecc080e7          	jalr	-308(ra) # 80002d54 <devintr>
    80002e90:	892a                	mv	s2,a0
    80002e92:	c501                	beqz	a0,80002e9a <usertrap+0xa4>
  if(p->killed)
    80002e94:	549c                	lw	a5,40(s1)
    80002e96:	c3a1                	beqz	a5,80002ed6 <usertrap+0xe0>
    80002e98:	a815                	j	80002ecc <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e9a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e9e:	5890                	lw	a2,48(s1)
    80002ea0:	00005517          	auipc	a0,0x5
    80002ea4:	52050513          	addi	a0,a0,1312 # 800083c0 <states.1780+0x78>
    80002ea8:	ffffd097          	auipc	ra,0xffffd
    80002eac:	6e0080e7          	jalr	1760(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002eb0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002eb4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002eb8:	00005517          	auipc	a0,0x5
    80002ebc:	53850513          	addi	a0,a0,1336 # 800083f0 <states.1780+0xa8>
    80002ec0:	ffffd097          	auipc	ra,0xffffd
    80002ec4:	6c8080e7          	jalr	1736(ra) # 80000588 <printf>
    p->killed = 1;
    80002ec8:	4785                	li	a5,1
    80002eca:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002ecc:	557d                	li	a0,-1
    80002ece:	00000097          	auipc	ra,0x0
    80002ed2:	958080e7          	jalr	-1704(ra) # 80002826 <exit>
  if(which_dev == 2)
    80002ed6:	4789                	li	a5,2
    80002ed8:	f8f910e3          	bne	s2,a5,80002e58 <usertrap+0x62>
    yield();
    80002edc:	fffff097          	auipc	ra,0xfffff
    80002ee0:	606080e7          	jalr	1542(ra) # 800024e2 <yield>
    80002ee4:	bf95                	j	80002e58 <usertrap+0x62>
  int which_dev = 0;
    80002ee6:	4901                	li	s2,0
    80002ee8:	b7d5                	j	80002ecc <usertrap+0xd6>

0000000080002eea <kerneltrap>:
{
    80002eea:	7179                	addi	sp,sp,-48
    80002eec:	f406                	sd	ra,40(sp)
    80002eee:	f022                	sd	s0,32(sp)
    80002ef0:	ec26                	sd	s1,24(sp)
    80002ef2:	e84a                	sd	s2,16(sp)
    80002ef4:	e44e                	sd	s3,8(sp)
    80002ef6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ef8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002efc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f00:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002f04:	1004f793          	andi	a5,s1,256
    80002f08:	cb85                	beqz	a5,80002f38 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f0a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f0e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f10:	ef85                	bnez	a5,80002f48 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002f12:	00000097          	auipc	ra,0x0
    80002f16:	e42080e7          	jalr	-446(ra) # 80002d54 <devintr>
    80002f1a:	cd1d                	beqz	a0,80002f58 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f1c:	4789                	li	a5,2
    80002f1e:	06f50a63          	beq	a0,a5,80002f92 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f22:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f26:	10049073          	csrw	sstatus,s1
}
    80002f2a:	70a2                	ld	ra,40(sp)
    80002f2c:	7402                	ld	s0,32(sp)
    80002f2e:	64e2                	ld	s1,24(sp)
    80002f30:	6942                	ld	s2,16(sp)
    80002f32:	69a2                	ld	s3,8(sp)
    80002f34:	6145                	addi	sp,sp,48
    80002f36:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f38:	00005517          	auipc	a0,0x5
    80002f3c:	4d850513          	addi	a0,a0,1240 # 80008410 <states.1780+0xc8>
    80002f40:	ffffd097          	auipc	ra,0xffffd
    80002f44:	5fe080e7          	jalr	1534(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002f48:	00005517          	auipc	a0,0x5
    80002f4c:	4f050513          	addi	a0,a0,1264 # 80008438 <states.1780+0xf0>
    80002f50:	ffffd097          	auipc	ra,0xffffd
    80002f54:	5ee080e7          	jalr	1518(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002f58:	85ce                	mv	a1,s3
    80002f5a:	00005517          	auipc	a0,0x5
    80002f5e:	4fe50513          	addi	a0,a0,1278 # 80008458 <states.1780+0x110>
    80002f62:	ffffd097          	auipc	ra,0xffffd
    80002f66:	626080e7          	jalr	1574(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f6a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f6e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f72:	00005517          	auipc	a0,0x5
    80002f76:	4f650513          	addi	a0,a0,1270 # 80008468 <states.1780+0x120>
    80002f7a:	ffffd097          	auipc	ra,0xffffd
    80002f7e:	60e080e7          	jalr	1550(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002f82:	00005517          	auipc	a0,0x5
    80002f86:	4fe50513          	addi	a0,a0,1278 # 80008480 <states.1780+0x138>
    80002f8a:	ffffd097          	auipc	ra,0xffffd
    80002f8e:	5b4080e7          	jalr	1460(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f92:	fffff097          	auipc	ra,0xfffff
    80002f96:	da8080e7          	jalr	-600(ra) # 80001d3a <myproc>
    80002f9a:	d541                	beqz	a0,80002f22 <kerneltrap+0x38>
    80002f9c:	fffff097          	auipc	ra,0xfffff
    80002fa0:	d9e080e7          	jalr	-610(ra) # 80001d3a <myproc>
    80002fa4:	4d18                	lw	a4,24(a0)
    80002fa6:	4791                	li	a5,4
    80002fa8:	f6f71de3          	bne	a4,a5,80002f22 <kerneltrap+0x38>
    yield();
    80002fac:	fffff097          	auipc	ra,0xfffff
    80002fb0:	536080e7          	jalr	1334(ra) # 800024e2 <yield>
    80002fb4:	b7bd                	j	80002f22 <kerneltrap+0x38>

0000000080002fb6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002fb6:	1101                	addi	sp,sp,-32
    80002fb8:	ec06                	sd	ra,24(sp)
    80002fba:	e822                	sd	s0,16(sp)
    80002fbc:	e426                	sd	s1,8(sp)
    80002fbe:	1000                	addi	s0,sp,32
    80002fc0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002fc2:	fffff097          	auipc	ra,0xfffff
    80002fc6:	d78080e7          	jalr	-648(ra) # 80001d3a <myproc>
  switch (n) {
    80002fca:	4795                	li	a5,5
    80002fcc:	0497e163          	bltu	a5,s1,8000300e <argraw+0x58>
    80002fd0:	048a                	slli	s1,s1,0x2
    80002fd2:	00005717          	auipc	a4,0x5
    80002fd6:	4e670713          	addi	a4,a4,1254 # 800084b8 <states.1780+0x170>
    80002fda:	94ba                	add	s1,s1,a4
    80002fdc:	409c                	lw	a5,0(s1)
    80002fde:	97ba                	add	a5,a5,a4
    80002fe0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002fe2:	6d3c                	ld	a5,88(a0)
    80002fe4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002fe6:	60e2                	ld	ra,24(sp)
    80002fe8:	6442                	ld	s0,16(sp)
    80002fea:	64a2                	ld	s1,8(sp)
    80002fec:	6105                	addi	sp,sp,32
    80002fee:	8082                	ret
    return p->trapframe->a1;
    80002ff0:	6d3c                	ld	a5,88(a0)
    80002ff2:	7fa8                	ld	a0,120(a5)
    80002ff4:	bfcd                	j	80002fe6 <argraw+0x30>
    return p->trapframe->a2;
    80002ff6:	6d3c                	ld	a5,88(a0)
    80002ff8:	63c8                	ld	a0,128(a5)
    80002ffa:	b7f5                	j	80002fe6 <argraw+0x30>
    return p->trapframe->a3;
    80002ffc:	6d3c                	ld	a5,88(a0)
    80002ffe:	67c8                	ld	a0,136(a5)
    80003000:	b7dd                	j	80002fe6 <argraw+0x30>
    return p->trapframe->a4;
    80003002:	6d3c                	ld	a5,88(a0)
    80003004:	6bc8                	ld	a0,144(a5)
    80003006:	b7c5                	j	80002fe6 <argraw+0x30>
    return p->trapframe->a5;
    80003008:	6d3c                	ld	a5,88(a0)
    8000300a:	6fc8                	ld	a0,152(a5)
    8000300c:	bfe9                	j	80002fe6 <argraw+0x30>
  panic("argraw");
    8000300e:	00005517          	auipc	a0,0x5
    80003012:	48250513          	addi	a0,a0,1154 # 80008490 <states.1780+0x148>
    80003016:	ffffd097          	auipc	ra,0xffffd
    8000301a:	528080e7          	jalr	1320(ra) # 8000053e <panic>

000000008000301e <fetchaddr>:
{
    8000301e:	1101                	addi	sp,sp,-32
    80003020:	ec06                	sd	ra,24(sp)
    80003022:	e822                	sd	s0,16(sp)
    80003024:	e426                	sd	s1,8(sp)
    80003026:	e04a                	sd	s2,0(sp)
    80003028:	1000                	addi	s0,sp,32
    8000302a:	84aa                	mv	s1,a0
    8000302c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000302e:	fffff097          	auipc	ra,0xfffff
    80003032:	d0c080e7          	jalr	-756(ra) # 80001d3a <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003036:	653c                	ld	a5,72(a0)
    80003038:	02f4f863          	bgeu	s1,a5,80003068 <fetchaddr+0x4a>
    8000303c:	00848713          	addi	a4,s1,8
    80003040:	02e7e663          	bltu	a5,a4,8000306c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003044:	46a1                	li	a3,8
    80003046:	8626                	mv	a2,s1
    80003048:	85ca                	mv	a1,s2
    8000304a:	6928                	ld	a0,80(a0)
    8000304c:	ffffe097          	auipc	ra,0xffffe
    80003050:	6b2080e7          	jalr	1714(ra) # 800016fe <copyin>
    80003054:	00a03533          	snez	a0,a0
    80003058:	40a00533          	neg	a0,a0
}
    8000305c:	60e2                	ld	ra,24(sp)
    8000305e:	6442                	ld	s0,16(sp)
    80003060:	64a2                	ld	s1,8(sp)
    80003062:	6902                	ld	s2,0(sp)
    80003064:	6105                	addi	sp,sp,32
    80003066:	8082                	ret
    return -1;
    80003068:	557d                	li	a0,-1
    8000306a:	bfcd                	j	8000305c <fetchaddr+0x3e>
    8000306c:	557d                	li	a0,-1
    8000306e:	b7fd                	j	8000305c <fetchaddr+0x3e>

0000000080003070 <fetchstr>:
{
    80003070:	7179                	addi	sp,sp,-48
    80003072:	f406                	sd	ra,40(sp)
    80003074:	f022                	sd	s0,32(sp)
    80003076:	ec26                	sd	s1,24(sp)
    80003078:	e84a                	sd	s2,16(sp)
    8000307a:	e44e                	sd	s3,8(sp)
    8000307c:	1800                	addi	s0,sp,48
    8000307e:	892a                	mv	s2,a0
    80003080:	84ae                	mv	s1,a1
    80003082:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003084:	fffff097          	auipc	ra,0xfffff
    80003088:	cb6080e7          	jalr	-842(ra) # 80001d3a <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000308c:	86ce                	mv	a3,s3
    8000308e:	864a                	mv	a2,s2
    80003090:	85a6                	mv	a1,s1
    80003092:	6928                	ld	a0,80(a0)
    80003094:	ffffe097          	auipc	ra,0xffffe
    80003098:	6f6080e7          	jalr	1782(ra) # 8000178a <copyinstr>
  if(err < 0)
    8000309c:	00054763          	bltz	a0,800030aa <fetchstr+0x3a>
  return strlen(buf);
    800030a0:	8526                	mv	a0,s1
    800030a2:	ffffe097          	auipc	ra,0xffffe
    800030a6:	dc2080e7          	jalr	-574(ra) # 80000e64 <strlen>
}
    800030aa:	70a2                	ld	ra,40(sp)
    800030ac:	7402                	ld	s0,32(sp)
    800030ae:	64e2                	ld	s1,24(sp)
    800030b0:	6942                	ld	s2,16(sp)
    800030b2:	69a2                	ld	s3,8(sp)
    800030b4:	6145                	addi	sp,sp,48
    800030b6:	8082                	ret

00000000800030b8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800030b8:	1101                	addi	sp,sp,-32
    800030ba:	ec06                	sd	ra,24(sp)
    800030bc:	e822                	sd	s0,16(sp)
    800030be:	e426                	sd	s1,8(sp)
    800030c0:	1000                	addi	s0,sp,32
    800030c2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030c4:	00000097          	auipc	ra,0x0
    800030c8:	ef2080e7          	jalr	-270(ra) # 80002fb6 <argraw>
    800030cc:	c088                	sw	a0,0(s1)
  return 0;
}
    800030ce:	4501                	li	a0,0
    800030d0:	60e2                	ld	ra,24(sp)
    800030d2:	6442                	ld	s0,16(sp)
    800030d4:	64a2                	ld	s1,8(sp)
    800030d6:	6105                	addi	sp,sp,32
    800030d8:	8082                	ret

00000000800030da <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800030da:	1101                	addi	sp,sp,-32
    800030dc:	ec06                	sd	ra,24(sp)
    800030de:	e822                	sd	s0,16(sp)
    800030e0:	e426                	sd	s1,8(sp)
    800030e2:	1000                	addi	s0,sp,32
    800030e4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030e6:	00000097          	auipc	ra,0x0
    800030ea:	ed0080e7          	jalr	-304(ra) # 80002fb6 <argraw>
    800030ee:	e088                	sd	a0,0(s1)
  return 0;
}
    800030f0:	4501                	li	a0,0
    800030f2:	60e2                	ld	ra,24(sp)
    800030f4:	6442                	ld	s0,16(sp)
    800030f6:	64a2                	ld	s1,8(sp)
    800030f8:	6105                	addi	sp,sp,32
    800030fa:	8082                	ret

00000000800030fc <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800030fc:	1101                	addi	sp,sp,-32
    800030fe:	ec06                	sd	ra,24(sp)
    80003100:	e822                	sd	s0,16(sp)
    80003102:	e426                	sd	s1,8(sp)
    80003104:	e04a                	sd	s2,0(sp)
    80003106:	1000                	addi	s0,sp,32
    80003108:	84ae                	mv	s1,a1
    8000310a:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000310c:	00000097          	auipc	ra,0x0
    80003110:	eaa080e7          	jalr	-342(ra) # 80002fb6 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003114:	864a                	mv	a2,s2
    80003116:	85a6                	mv	a1,s1
    80003118:	00000097          	auipc	ra,0x0
    8000311c:	f58080e7          	jalr	-168(ra) # 80003070 <fetchstr>
}
    80003120:	60e2                	ld	ra,24(sp)
    80003122:	6442                	ld	s0,16(sp)
    80003124:	64a2                	ld	s1,8(sp)
    80003126:	6902                	ld	s2,0(sp)
    80003128:	6105                	addi	sp,sp,32
    8000312a:	8082                	ret

000000008000312c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    8000312c:	1101                	addi	sp,sp,-32
    8000312e:	ec06                	sd	ra,24(sp)
    80003130:	e822                	sd	s0,16(sp)
    80003132:	e426                	sd	s1,8(sp)
    80003134:	e04a                	sd	s2,0(sp)
    80003136:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003138:	fffff097          	auipc	ra,0xfffff
    8000313c:	c02080e7          	jalr	-1022(ra) # 80001d3a <myproc>
    80003140:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003142:	05853903          	ld	s2,88(a0)
    80003146:	0a893783          	ld	a5,168(s2)
    8000314a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000314e:	37fd                	addiw	a5,a5,-1
    80003150:	4751                	li	a4,20
    80003152:	00f76f63          	bltu	a4,a5,80003170 <syscall+0x44>
    80003156:	00369713          	slli	a4,a3,0x3
    8000315a:	00005797          	auipc	a5,0x5
    8000315e:	37678793          	addi	a5,a5,886 # 800084d0 <syscalls>
    80003162:	97ba                	add	a5,a5,a4
    80003164:	639c                	ld	a5,0(a5)
    80003166:	c789                	beqz	a5,80003170 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003168:	9782                	jalr	a5
    8000316a:	06a93823          	sd	a0,112(s2)
    8000316e:	a839                	j	8000318c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003170:	15848613          	addi	a2,s1,344
    80003174:	588c                	lw	a1,48(s1)
    80003176:	00005517          	auipc	a0,0x5
    8000317a:	32250513          	addi	a0,a0,802 # 80008498 <states.1780+0x150>
    8000317e:	ffffd097          	auipc	ra,0xffffd
    80003182:	40a080e7          	jalr	1034(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003186:	6cbc                	ld	a5,88(s1)
    80003188:	577d                	li	a4,-1
    8000318a:	fbb8                	sd	a4,112(a5)
  }
}
    8000318c:	60e2                	ld	ra,24(sp)
    8000318e:	6442                	ld	s0,16(sp)
    80003190:	64a2                	ld	s1,8(sp)
    80003192:	6902                	ld	s2,0(sp)
    80003194:	6105                	addi	sp,sp,32
    80003196:	8082                	ret

0000000080003198 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003198:	1101                	addi	sp,sp,-32
    8000319a:	ec06                	sd	ra,24(sp)
    8000319c:	e822                	sd	s0,16(sp)
    8000319e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800031a0:	fec40593          	addi	a1,s0,-20
    800031a4:	4501                	li	a0,0
    800031a6:	00000097          	auipc	ra,0x0
    800031aa:	f12080e7          	jalr	-238(ra) # 800030b8 <argint>
    return -1;
    800031ae:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800031b0:	00054963          	bltz	a0,800031c2 <sys_exit+0x2a>
  exit(n);
    800031b4:	fec42503          	lw	a0,-20(s0)
    800031b8:	fffff097          	auipc	ra,0xfffff
    800031bc:	66e080e7          	jalr	1646(ra) # 80002826 <exit>
  return 0;  // not reached
    800031c0:	4781                	li	a5,0
}
    800031c2:	853e                	mv	a0,a5
    800031c4:	60e2                	ld	ra,24(sp)
    800031c6:	6442                	ld	s0,16(sp)
    800031c8:	6105                	addi	sp,sp,32
    800031ca:	8082                	ret

00000000800031cc <sys_getpid>:

uint64
sys_getpid(void)
{
    800031cc:	1141                	addi	sp,sp,-16
    800031ce:	e406                	sd	ra,8(sp)
    800031d0:	e022                	sd	s0,0(sp)
    800031d2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800031d4:	fffff097          	auipc	ra,0xfffff
    800031d8:	b66080e7          	jalr	-1178(ra) # 80001d3a <myproc>
}
    800031dc:	5908                	lw	a0,48(a0)
    800031de:	60a2                	ld	ra,8(sp)
    800031e0:	6402                	ld	s0,0(sp)
    800031e2:	0141                	addi	sp,sp,16
    800031e4:	8082                	ret

00000000800031e6 <sys_fork>:

uint64
sys_fork(void)
{
    800031e6:	1141                	addi	sp,sp,-16
    800031e8:	e406                	sd	ra,8(sp)
    800031ea:	e022                	sd	s0,0(sp)
    800031ec:	0800                	addi	s0,sp,16
  return fork();
    800031ee:	fffff097          	auipc	ra,0xfffff
    800031f2:	fd4080e7          	jalr	-44(ra) # 800021c2 <fork>
}
    800031f6:	60a2                	ld	ra,8(sp)
    800031f8:	6402                	ld	s0,0(sp)
    800031fa:	0141                	addi	sp,sp,16
    800031fc:	8082                	ret

00000000800031fe <sys_wait>:

uint64
sys_wait(void)
{
    800031fe:	1101                	addi	sp,sp,-32
    80003200:	ec06                	sd	ra,24(sp)
    80003202:	e822                	sd	s0,16(sp)
    80003204:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003206:	fe840593          	addi	a1,s0,-24
    8000320a:	4501                	li	a0,0
    8000320c:	00000097          	auipc	ra,0x0
    80003210:	ece080e7          	jalr	-306(ra) # 800030da <argaddr>
    80003214:	87aa                	mv	a5,a0
    return -1;
    80003216:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003218:	0007c863          	bltz	a5,80003228 <sys_wait+0x2a>
  return wait(p);
    8000321c:	fe843503          	ld	a0,-24(s0)
    80003220:	fffff097          	auipc	ra,0xfffff
    80003224:	398080e7          	jalr	920(ra) # 800025b8 <wait>
}
    80003228:	60e2                	ld	ra,24(sp)
    8000322a:	6442                	ld	s0,16(sp)
    8000322c:	6105                	addi	sp,sp,32
    8000322e:	8082                	ret

0000000080003230 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003230:	7179                	addi	sp,sp,-48
    80003232:	f406                	sd	ra,40(sp)
    80003234:	f022                	sd	s0,32(sp)
    80003236:	ec26                	sd	s1,24(sp)
    80003238:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000323a:	fdc40593          	addi	a1,s0,-36
    8000323e:	4501                	li	a0,0
    80003240:	00000097          	auipc	ra,0x0
    80003244:	e78080e7          	jalr	-392(ra) # 800030b8 <argint>
    80003248:	87aa                	mv	a5,a0
    return -1;
    8000324a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000324c:	0207c063          	bltz	a5,8000326c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003250:	fffff097          	auipc	ra,0xfffff
    80003254:	aea080e7          	jalr	-1302(ra) # 80001d3a <myproc>
    80003258:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    8000325a:	fdc42503          	lw	a0,-36(s0)
    8000325e:	fffff097          	auipc	ra,0xfffff
    80003262:	ef0080e7          	jalr	-272(ra) # 8000214e <growproc>
    80003266:	00054863          	bltz	a0,80003276 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000326a:	8526                	mv	a0,s1
}
    8000326c:	70a2                	ld	ra,40(sp)
    8000326e:	7402                	ld	s0,32(sp)
    80003270:	64e2                	ld	s1,24(sp)
    80003272:	6145                	addi	sp,sp,48
    80003274:	8082                	ret
    return -1;
    80003276:	557d                	li	a0,-1
    80003278:	bfd5                	j	8000326c <sys_sbrk+0x3c>

000000008000327a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000327a:	7139                	addi	sp,sp,-64
    8000327c:	fc06                	sd	ra,56(sp)
    8000327e:	f822                	sd	s0,48(sp)
    80003280:	f426                	sd	s1,40(sp)
    80003282:	f04a                	sd	s2,32(sp)
    80003284:	ec4e                	sd	s3,24(sp)
    80003286:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003288:	fcc40593          	addi	a1,s0,-52
    8000328c:	4501                	li	a0,0
    8000328e:	00000097          	auipc	ra,0x0
    80003292:	e2a080e7          	jalr	-470(ra) # 800030b8 <argint>
    return -1;
    80003296:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003298:	06054563          	bltz	a0,80003302 <sys_sleep+0x88>
  acquire(&tickslock);
    8000329c:	00015517          	auipc	a0,0x15
    800032a0:	97450513          	addi	a0,a0,-1676 # 80017c10 <tickslock>
    800032a4:	ffffe097          	auipc	ra,0xffffe
    800032a8:	940080e7          	jalr	-1728(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800032ac:	00006917          	auipc	s2,0x6
    800032b0:	d8492903          	lw	s2,-636(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800032b4:	fcc42783          	lw	a5,-52(s0)
    800032b8:	cf85                	beqz	a5,800032f0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800032ba:	00015997          	auipc	s3,0x15
    800032be:	95698993          	addi	s3,s3,-1706 # 80017c10 <tickslock>
    800032c2:	00006497          	auipc	s1,0x6
    800032c6:	d6e48493          	addi	s1,s1,-658 # 80009030 <ticks>
    if(myproc()->killed){
    800032ca:	fffff097          	auipc	ra,0xfffff
    800032ce:	a70080e7          	jalr	-1424(ra) # 80001d3a <myproc>
    800032d2:	551c                	lw	a5,40(a0)
    800032d4:	ef9d                	bnez	a5,80003312 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800032d6:	85ce                	mv	a1,s3
    800032d8:	8526                	mv	a0,s1
    800032da:	fffff097          	auipc	ra,0xfffff
    800032de:	268080e7          	jalr	616(ra) # 80002542 <sleep>
  while(ticks - ticks0 < n){
    800032e2:	409c                	lw	a5,0(s1)
    800032e4:	412787bb          	subw	a5,a5,s2
    800032e8:	fcc42703          	lw	a4,-52(s0)
    800032ec:	fce7efe3          	bltu	a5,a4,800032ca <sys_sleep+0x50>
  }
  release(&tickslock);
    800032f0:	00015517          	auipc	a0,0x15
    800032f4:	92050513          	addi	a0,a0,-1760 # 80017c10 <tickslock>
    800032f8:	ffffe097          	auipc	ra,0xffffe
    800032fc:	9a0080e7          	jalr	-1632(ra) # 80000c98 <release>
  return 0;
    80003300:	4781                	li	a5,0
}
    80003302:	853e                	mv	a0,a5
    80003304:	70e2                	ld	ra,56(sp)
    80003306:	7442                	ld	s0,48(sp)
    80003308:	74a2                	ld	s1,40(sp)
    8000330a:	7902                	ld	s2,32(sp)
    8000330c:	69e2                	ld	s3,24(sp)
    8000330e:	6121                	addi	sp,sp,64
    80003310:	8082                	ret
      release(&tickslock);
    80003312:	00015517          	auipc	a0,0x15
    80003316:	8fe50513          	addi	a0,a0,-1794 # 80017c10 <tickslock>
    8000331a:	ffffe097          	auipc	ra,0xffffe
    8000331e:	97e080e7          	jalr	-1666(ra) # 80000c98 <release>
      return -1;
    80003322:	57fd                	li	a5,-1
    80003324:	bff9                	j	80003302 <sys_sleep+0x88>

0000000080003326 <sys_kill>:

uint64
sys_kill(void)
{
    80003326:	1101                	addi	sp,sp,-32
    80003328:	ec06                	sd	ra,24(sp)
    8000332a:	e822                	sd	s0,16(sp)
    8000332c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000332e:	fec40593          	addi	a1,s0,-20
    80003332:	4501                	li	a0,0
    80003334:	00000097          	auipc	ra,0x0
    80003338:	d84080e7          	jalr	-636(ra) # 800030b8 <argint>
    8000333c:	87aa                	mv	a5,a0
    return -1;
    8000333e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003340:	0007c863          	bltz	a5,80003350 <sys_kill+0x2a>
  return kill(pid);
    80003344:	fec42503          	lw	a0,-20(s0)
    80003348:	fffff097          	auipc	ra,0xfffff
    8000334c:	5c6080e7          	jalr	1478(ra) # 8000290e <kill>
}
    80003350:	60e2                	ld	ra,24(sp)
    80003352:	6442                	ld	s0,16(sp)
    80003354:	6105                	addi	sp,sp,32
    80003356:	8082                	ret

0000000080003358 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003358:	1101                	addi	sp,sp,-32
    8000335a:	ec06                	sd	ra,24(sp)
    8000335c:	e822                	sd	s0,16(sp)
    8000335e:	e426                	sd	s1,8(sp)
    80003360:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003362:	00015517          	auipc	a0,0x15
    80003366:	8ae50513          	addi	a0,a0,-1874 # 80017c10 <tickslock>
    8000336a:	ffffe097          	auipc	ra,0xffffe
    8000336e:	87a080e7          	jalr	-1926(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003372:	00006497          	auipc	s1,0x6
    80003376:	cbe4a483          	lw	s1,-834(s1) # 80009030 <ticks>
  release(&tickslock);
    8000337a:	00015517          	auipc	a0,0x15
    8000337e:	89650513          	addi	a0,a0,-1898 # 80017c10 <tickslock>
    80003382:	ffffe097          	auipc	ra,0xffffe
    80003386:	916080e7          	jalr	-1770(ra) # 80000c98 <release>
  return xticks;
}
    8000338a:	02049513          	slli	a0,s1,0x20
    8000338e:	9101                	srli	a0,a0,0x20
    80003390:	60e2                	ld	ra,24(sp)
    80003392:	6442                	ld	s0,16(sp)
    80003394:	64a2                	ld	s1,8(sp)
    80003396:	6105                	addi	sp,sp,32
    80003398:	8082                	ret

000000008000339a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000339a:	7179                	addi	sp,sp,-48
    8000339c:	f406                	sd	ra,40(sp)
    8000339e:	f022                	sd	s0,32(sp)
    800033a0:	ec26                	sd	s1,24(sp)
    800033a2:	e84a                	sd	s2,16(sp)
    800033a4:	e44e                	sd	s3,8(sp)
    800033a6:	e052                	sd	s4,0(sp)
    800033a8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800033aa:	00005597          	auipc	a1,0x5
    800033ae:	1d658593          	addi	a1,a1,470 # 80008580 <syscalls+0xb0>
    800033b2:	00015517          	auipc	a0,0x15
    800033b6:	87650513          	addi	a0,a0,-1930 # 80017c28 <bcache>
    800033ba:	ffffd097          	auipc	ra,0xffffd
    800033be:	79a080e7          	jalr	1946(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033c2:	0001d797          	auipc	a5,0x1d
    800033c6:	86678793          	addi	a5,a5,-1946 # 8001fc28 <bcache+0x8000>
    800033ca:	0001d717          	auipc	a4,0x1d
    800033ce:	ac670713          	addi	a4,a4,-1338 # 8001fe90 <bcache+0x8268>
    800033d2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800033d6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033da:	00015497          	auipc	s1,0x15
    800033de:	86648493          	addi	s1,s1,-1946 # 80017c40 <bcache+0x18>
    b->next = bcache.head.next;
    800033e2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033e4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033e6:	00005a17          	auipc	s4,0x5
    800033ea:	1a2a0a13          	addi	s4,s4,418 # 80008588 <syscalls+0xb8>
    b->next = bcache.head.next;
    800033ee:	2b893783          	ld	a5,696(s2)
    800033f2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800033f4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800033f8:	85d2                	mv	a1,s4
    800033fa:	01048513          	addi	a0,s1,16
    800033fe:	00001097          	auipc	ra,0x1
    80003402:	4bc080e7          	jalr	1212(ra) # 800048ba <initsleeplock>
    bcache.head.next->prev = b;
    80003406:	2b893783          	ld	a5,696(s2)
    8000340a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000340c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003410:	45848493          	addi	s1,s1,1112
    80003414:	fd349de3          	bne	s1,s3,800033ee <binit+0x54>
  }
}
    80003418:	70a2                	ld	ra,40(sp)
    8000341a:	7402                	ld	s0,32(sp)
    8000341c:	64e2                	ld	s1,24(sp)
    8000341e:	6942                	ld	s2,16(sp)
    80003420:	69a2                	ld	s3,8(sp)
    80003422:	6a02                	ld	s4,0(sp)
    80003424:	6145                	addi	sp,sp,48
    80003426:	8082                	ret

0000000080003428 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003428:	7179                	addi	sp,sp,-48
    8000342a:	f406                	sd	ra,40(sp)
    8000342c:	f022                	sd	s0,32(sp)
    8000342e:	ec26                	sd	s1,24(sp)
    80003430:	e84a                	sd	s2,16(sp)
    80003432:	e44e                	sd	s3,8(sp)
    80003434:	1800                	addi	s0,sp,48
    80003436:	89aa                	mv	s3,a0
    80003438:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000343a:	00014517          	auipc	a0,0x14
    8000343e:	7ee50513          	addi	a0,a0,2030 # 80017c28 <bcache>
    80003442:	ffffd097          	auipc	ra,0xffffd
    80003446:	7a2080e7          	jalr	1954(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000344a:	0001d497          	auipc	s1,0x1d
    8000344e:	a964b483          	ld	s1,-1386(s1) # 8001fee0 <bcache+0x82b8>
    80003452:	0001d797          	auipc	a5,0x1d
    80003456:	a3e78793          	addi	a5,a5,-1474 # 8001fe90 <bcache+0x8268>
    8000345a:	02f48f63          	beq	s1,a5,80003498 <bread+0x70>
    8000345e:	873e                	mv	a4,a5
    80003460:	a021                	j	80003468 <bread+0x40>
    80003462:	68a4                	ld	s1,80(s1)
    80003464:	02e48a63          	beq	s1,a4,80003498 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003468:	449c                	lw	a5,8(s1)
    8000346a:	ff379ce3          	bne	a5,s3,80003462 <bread+0x3a>
    8000346e:	44dc                	lw	a5,12(s1)
    80003470:	ff2799e3          	bne	a5,s2,80003462 <bread+0x3a>
      b->refcnt++;
    80003474:	40bc                	lw	a5,64(s1)
    80003476:	2785                	addiw	a5,a5,1
    80003478:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000347a:	00014517          	auipc	a0,0x14
    8000347e:	7ae50513          	addi	a0,a0,1966 # 80017c28 <bcache>
    80003482:	ffffe097          	auipc	ra,0xffffe
    80003486:	816080e7          	jalr	-2026(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000348a:	01048513          	addi	a0,s1,16
    8000348e:	00001097          	auipc	ra,0x1
    80003492:	466080e7          	jalr	1126(ra) # 800048f4 <acquiresleep>
      return b;
    80003496:	a8b9                	j	800034f4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003498:	0001d497          	auipc	s1,0x1d
    8000349c:	a404b483          	ld	s1,-1472(s1) # 8001fed8 <bcache+0x82b0>
    800034a0:	0001d797          	auipc	a5,0x1d
    800034a4:	9f078793          	addi	a5,a5,-1552 # 8001fe90 <bcache+0x8268>
    800034a8:	00f48863          	beq	s1,a5,800034b8 <bread+0x90>
    800034ac:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800034ae:	40bc                	lw	a5,64(s1)
    800034b0:	cf81                	beqz	a5,800034c8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034b2:	64a4                	ld	s1,72(s1)
    800034b4:	fee49de3          	bne	s1,a4,800034ae <bread+0x86>
  panic("bget: no buffers");
    800034b8:	00005517          	auipc	a0,0x5
    800034bc:	0d850513          	addi	a0,a0,216 # 80008590 <syscalls+0xc0>
    800034c0:	ffffd097          	auipc	ra,0xffffd
    800034c4:	07e080e7          	jalr	126(ra) # 8000053e <panic>
      b->dev = dev;
    800034c8:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800034cc:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800034d0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800034d4:	4785                	li	a5,1
    800034d6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034d8:	00014517          	auipc	a0,0x14
    800034dc:	75050513          	addi	a0,a0,1872 # 80017c28 <bcache>
    800034e0:	ffffd097          	auipc	ra,0xffffd
    800034e4:	7b8080e7          	jalr	1976(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800034e8:	01048513          	addi	a0,s1,16
    800034ec:	00001097          	auipc	ra,0x1
    800034f0:	408080e7          	jalr	1032(ra) # 800048f4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800034f4:	409c                	lw	a5,0(s1)
    800034f6:	cb89                	beqz	a5,80003508 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800034f8:	8526                	mv	a0,s1
    800034fa:	70a2                	ld	ra,40(sp)
    800034fc:	7402                	ld	s0,32(sp)
    800034fe:	64e2                	ld	s1,24(sp)
    80003500:	6942                	ld	s2,16(sp)
    80003502:	69a2                	ld	s3,8(sp)
    80003504:	6145                	addi	sp,sp,48
    80003506:	8082                	ret
    virtio_disk_rw(b, 0);
    80003508:	4581                	li	a1,0
    8000350a:	8526                	mv	a0,s1
    8000350c:	00003097          	auipc	ra,0x3
    80003510:	f0a080e7          	jalr	-246(ra) # 80006416 <virtio_disk_rw>
    b->valid = 1;
    80003514:	4785                	li	a5,1
    80003516:	c09c                	sw	a5,0(s1)
  return b;
    80003518:	b7c5                	j	800034f8 <bread+0xd0>

000000008000351a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000351a:	1101                	addi	sp,sp,-32
    8000351c:	ec06                	sd	ra,24(sp)
    8000351e:	e822                	sd	s0,16(sp)
    80003520:	e426                	sd	s1,8(sp)
    80003522:	1000                	addi	s0,sp,32
    80003524:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003526:	0541                	addi	a0,a0,16
    80003528:	00001097          	auipc	ra,0x1
    8000352c:	466080e7          	jalr	1126(ra) # 8000498e <holdingsleep>
    80003530:	cd01                	beqz	a0,80003548 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003532:	4585                	li	a1,1
    80003534:	8526                	mv	a0,s1
    80003536:	00003097          	auipc	ra,0x3
    8000353a:	ee0080e7          	jalr	-288(ra) # 80006416 <virtio_disk_rw>
}
    8000353e:	60e2                	ld	ra,24(sp)
    80003540:	6442                	ld	s0,16(sp)
    80003542:	64a2                	ld	s1,8(sp)
    80003544:	6105                	addi	sp,sp,32
    80003546:	8082                	ret
    panic("bwrite");
    80003548:	00005517          	auipc	a0,0x5
    8000354c:	06050513          	addi	a0,a0,96 # 800085a8 <syscalls+0xd8>
    80003550:	ffffd097          	auipc	ra,0xffffd
    80003554:	fee080e7          	jalr	-18(ra) # 8000053e <panic>

0000000080003558 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003558:	1101                	addi	sp,sp,-32
    8000355a:	ec06                	sd	ra,24(sp)
    8000355c:	e822                	sd	s0,16(sp)
    8000355e:	e426                	sd	s1,8(sp)
    80003560:	e04a                	sd	s2,0(sp)
    80003562:	1000                	addi	s0,sp,32
    80003564:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003566:	01050913          	addi	s2,a0,16
    8000356a:	854a                	mv	a0,s2
    8000356c:	00001097          	auipc	ra,0x1
    80003570:	422080e7          	jalr	1058(ra) # 8000498e <holdingsleep>
    80003574:	c92d                	beqz	a0,800035e6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003576:	854a                	mv	a0,s2
    80003578:	00001097          	auipc	ra,0x1
    8000357c:	3d2080e7          	jalr	978(ra) # 8000494a <releasesleep>

  acquire(&bcache.lock);
    80003580:	00014517          	auipc	a0,0x14
    80003584:	6a850513          	addi	a0,a0,1704 # 80017c28 <bcache>
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	65c080e7          	jalr	1628(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003590:	40bc                	lw	a5,64(s1)
    80003592:	37fd                	addiw	a5,a5,-1
    80003594:	0007871b          	sext.w	a4,a5
    80003598:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000359a:	eb05                	bnez	a4,800035ca <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000359c:	68bc                	ld	a5,80(s1)
    8000359e:	64b8                	ld	a4,72(s1)
    800035a0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800035a2:	64bc                	ld	a5,72(s1)
    800035a4:	68b8                	ld	a4,80(s1)
    800035a6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800035a8:	0001c797          	auipc	a5,0x1c
    800035ac:	68078793          	addi	a5,a5,1664 # 8001fc28 <bcache+0x8000>
    800035b0:	2b87b703          	ld	a4,696(a5)
    800035b4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800035b6:	0001d717          	auipc	a4,0x1d
    800035ba:	8da70713          	addi	a4,a4,-1830 # 8001fe90 <bcache+0x8268>
    800035be:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035c0:	2b87b703          	ld	a4,696(a5)
    800035c4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800035c6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800035ca:	00014517          	auipc	a0,0x14
    800035ce:	65e50513          	addi	a0,a0,1630 # 80017c28 <bcache>
    800035d2:	ffffd097          	auipc	ra,0xffffd
    800035d6:	6c6080e7          	jalr	1734(ra) # 80000c98 <release>
}
    800035da:	60e2                	ld	ra,24(sp)
    800035dc:	6442                	ld	s0,16(sp)
    800035de:	64a2                	ld	s1,8(sp)
    800035e0:	6902                	ld	s2,0(sp)
    800035e2:	6105                	addi	sp,sp,32
    800035e4:	8082                	ret
    panic("brelse");
    800035e6:	00005517          	auipc	a0,0x5
    800035ea:	fca50513          	addi	a0,a0,-54 # 800085b0 <syscalls+0xe0>
    800035ee:	ffffd097          	auipc	ra,0xffffd
    800035f2:	f50080e7          	jalr	-176(ra) # 8000053e <panic>

00000000800035f6 <bpin>:

void
bpin(struct buf *b) {
    800035f6:	1101                	addi	sp,sp,-32
    800035f8:	ec06                	sd	ra,24(sp)
    800035fa:	e822                	sd	s0,16(sp)
    800035fc:	e426                	sd	s1,8(sp)
    800035fe:	1000                	addi	s0,sp,32
    80003600:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003602:	00014517          	auipc	a0,0x14
    80003606:	62650513          	addi	a0,a0,1574 # 80017c28 <bcache>
    8000360a:	ffffd097          	auipc	ra,0xffffd
    8000360e:	5da080e7          	jalr	1498(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003612:	40bc                	lw	a5,64(s1)
    80003614:	2785                	addiw	a5,a5,1
    80003616:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003618:	00014517          	auipc	a0,0x14
    8000361c:	61050513          	addi	a0,a0,1552 # 80017c28 <bcache>
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	678080e7          	jalr	1656(ra) # 80000c98 <release>
}
    80003628:	60e2                	ld	ra,24(sp)
    8000362a:	6442                	ld	s0,16(sp)
    8000362c:	64a2                	ld	s1,8(sp)
    8000362e:	6105                	addi	sp,sp,32
    80003630:	8082                	ret

0000000080003632 <bunpin>:

void
bunpin(struct buf *b) {
    80003632:	1101                	addi	sp,sp,-32
    80003634:	ec06                	sd	ra,24(sp)
    80003636:	e822                	sd	s0,16(sp)
    80003638:	e426                	sd	s1,8(sp)
    8000363a:	1000                	addi	s0,sp,32
    8000363c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000363e:	00014517          	auipc	a0,0x14
    80003642:	5ea50513          	addi	a0,a0,1514 # 80017c28 <bcache>
    80003646:	ffffd097          	auipc	ra,0xffffd
    8000364a:	59e080e7          	jalr	1438(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000364e:	40bc                	lw	a5,64(s1)
    80003650:	37fd                	addiw	a5,a5,-1
    80003652:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003654:	00014517          	auipc	a0,0x14
    80003658:	5d450513          	addi	a0,a0,1492 # 80017c28 <bcache>
    8000365c:	ffffd097          	auipc	ra,0xffffd
    80003660:	63c080e7          	jalr	1596(ra) # 80000c98 <release>
}
    80003664:	60e2                	ld	ra,24(sp)
    80003666:	6442                	ld	s0,16(sp)
    80003668:	64a2                	ld	s1,8(sp)
    8000366a:	6105                	addi	sp,sp,32
    8000366c:	8082                	ret

000000008000366e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000366e:	1101                	addi	sp,sp,-32
    80003670:	ec06                	sd	ra,24(sp)
    80003672:	e822                	sd	s0,16(sp)
    80003674:	e426                	sd	s1,8(sp)
    80003676:	e04a                	sd	s2,0(sp)
    80003678:	1000                	addi	s0,sp,32
    8000367a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000367c:	00d5d59b          	srliw	a1,a1,0xd
    80003680:	0001d797          	auipc	a5,0x1d
    80003684:	c847a783          	lw	a5,-892(a5) # 80020304 <sb+0x1c>
    80003688:	9dbd                	addw	a1,a1,a5
    8000368a:	00000097          	auipc	ra,0x0
    8000368e:	d9e080e7          	jalr	-610(ra) # 80003428 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003692:	0074f713          	andi	a4,s1,7
    80003696:	4785                	li	a5,1
    80003698:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000369c:	14ce                	slli	s1,s1,0x33
    8000369e:	90d9                	srli	s1,s1,0x36
    800036a0:	00950733          	add	a4,a0,s1
    800036a4:	05874703          	lbu	a4,88(a4)
    800036a8:	00e7f6b3          	and	a3,a5,a4
    800036ac:	c69d                	beqz	a3,800036da <bfree+0x6c>
    800036ae:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800036b0:	94aa                	add	s1,s1,a0
    800036b2:	fff7c793          	not	a5,a5
    800036b6:	8ff9                	and	a5,a5,a4
    800036b8:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800036bc:	00001097          	auipc	ra,0x1
    800036c0:	118080e7          	jalr	280(ra) # 800047d4 <log_write>
  brelse(bp);
    800036c4:	854a                	mv	a0,s2
    800036c6:	00000097          	auipc	ra,0x0
    800036ca:	e92080e7          	jalr	-366(ra) # 80003558 <brelse>
}
    800036ce:	60e2                	ld	ra,24(sp)
    800036d0:	6442                	ld	s0,16(sp)
    800036d2:	64a2                	ld	s1,8(sp)
    800036d4:	6902                	ld	s2,0(sp)
    800036d6:	6105                	addi	sp,sp,32
    800036d8:	8082                	ret
    panic("freeing free block");
    800036da:	00005517          	auipc	a0,0x5
    800036de:	ede50513          	addi	a0,a0,-290 # 800085b8 <syscalls+0xe8>
    800036e2:	ffffd097          	auipc	ra,0xffffd
    800036e6:	e5c080e7          	jalr	-420(ra) # 8000053e <panic>

00000000800036ea <balloc>:
{
    800036ea:	711d                	addi	sp,sp,-96
    800036ec:	ec86                	sd	ra,88(sp)
    800036ee:	e8a2                	sd	s0,80(sp)
    800036f0:	e4a6                	sd	s1,72(sp)
    800036f2:	e0ca                	sd	s2,64(sp)
    800036f4:	fc4e                	sd	s3,56(sp)
    800036f6:	f852                	sd	s4,48(sp)
    800036f8:	f456                	sd	s5,40(sp)
    800036fa:	f05a                	sd	s6,32(sp)
    800036fc:	ec5e                	sd	s7,24(sp)
    800036fe:	e862                	sd	s8,16(sp)
    80003700:	e466                	sd	s9,8(sp)
    80003702:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003704:	0001d797          	auipc	a5,0x1d
    80003708:	be87a783          	lw	a5,-1048(a5) # 800202ec <sb+0x4>
    8000370c:	cbd1                	beqz	a5,800037a0 <balloc+0xb6>
    8000370e:	8baa                	mv	s7,a0
    80003710:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003712:	0001db17          	auipc	s6,0x1d
    80003716:	bd6b0b13          	addi	s6,s6,-1066 # 800202e8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000371a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000371c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000371e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003720:	6c89                	lui	s9,0x2
    80003722:	a831                	j	8000373e <balloc+0x54>
    brelse(bp);
    80003724:	854a                	mv	a0,s2
    80003726:	00000097          	auipc	ra,0x0
    8000372a:	e32080e7          	jalr	-462(ra) # 80003558 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000372e:	015c87bb          	addw	a5,s9,s5
    80003732:	00078a9b          	sext.w	s5,a5
    80003736:	004b2703          	lw	a4,4(s6)
    8000373a:	06eaf363          	bgeu	s5,a4,800037a0 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000373e:	41fad79b          	sraiw	a5,s5,0x1f
    80003742:	0137d79b          	srliw	a5,a5,0x13
    80003746:	015787bb          	addw	a5,a5,s5
    8000374a:	40d7d79b          	sraiw	a5,a5,0xd
    8000374e:	01cb2583          	lw	a1,28(s6)
    80003752:	9dbd                	addw	a1,a1,a5
    80003754:	855e                	mv	a0,s7
    80003756:	00000097          	auipc	ra,0x0
    8000375a:	cd2080e7          	jalr	-814(ra) # 80003428 <bread>
    8000375e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003760:	004b2503          	lw	a0,4(s6)
    80003764:	000a849b          	sext.w	s1,s5
    80003768:	8662                	mv	a2,s8
    8000376a:	faa4fde3          	bgeu	s1,a0,80003724 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000376e:	41f6579b          	sraiw	a5,a2,0x1f
    80003772:	01d7d69b          	srliw	a3,a5,0x1d
    80003776:	00c6873b          	addw	a4,a3,a2
    8000377a:	00777793          	andi	a5,a4,7
    8000377e:	9f95                	subw	a5,a5,a3
    80003780:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003784:	4037571b          	sraiw	a4,a4,0x3
    80003788:	00e906b3          	add	a3,s2,a4
    8000378c:	0586c683          	lbu	a3,88(a3)
    80003790:	00d7f5b3          	and	a1,a5,a3
    80003794:	cd91                	beqz	a1,800037b0 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003796:	2605                	addiw	a2,a2,1
    80003798:	2485                	addiw	s1,s1,1
    8000379a:	fd4618e3          	bne	a2,s4,8000376a <balloc+0x80>
    8000379e:	b759                	j	80003724 <balloc+0x3a>
  panic("balloc: out of blocks");
    800037a0:	00005517          	auipc	a0,0x5
    800037a4:	e3050513          	addi	a0,a0,-464 # 800085d0 <syscalls+0x100>
    800037a8:	ffffd097          	auipc	ra,0xffffd
    800037ac:	d96080e7          	jalr	-618(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800037b0:	974a                	add	a4,a4,s2
    800037b2:	8fd5                	or	a5,a5,a3
    800037b4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800037b8:	854a                	mv	a0,s2
    800037ba:	00001097          	auipc	ra,0x1
    800037be:	01a080e7          	jalr	26(ra) # 800047d4 <log_write>
        brelse(bp);
    800037c2:	854a                	mv	a0,s2
    800037c4:	00000097          	auipc	ra,0x0
    800037c8:	d94080e7          	jalr	-620(ra) # 80003558 <brelse>
  bp = bread(dev, bno);
    800037cc:	85a6                	mv	a1,s1
    800037ce:	855e                	mv	a0,s7
    800037d0:	00000097          	auipc	ra,0x0
    800037d4:	c58080e7          	jalr	-936(ra) # 80003428 <bread>
    800037d8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800037da:	40000613          	li	a2,1024
    800037de:	4581                	li	a1,0
    800037e0:	05850513          	addi	a0,a0,88
    800037e4:	ffffd097          	auipc	ra,0xffffd
    800037e8:	4fc080e7          	jalr	1276(ra) # 80000ce0 <memset>
  log_write(bp);
    800037ec:	854a                	mv	a0,s2
    800037ee:	00001097          	auipc	ra,0x1
    800037f2:	fe6080e7          	jalr	-26(ra) # 800047d4 <log_write>
  brelse(bp);
    800037f6:	854a                	mv	a0,s2
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	d60080e7          	jalr	-672(ra) # 80003558 <brelse>
}
    80003800:	8526                	mv	a0,s1
    80003802:	60e6                	ld	ra,88(sp)
    80003804:	6446                	ld	s0,80(sp)
    80003806:	64a6                	ld	s1,72(sp)
    80003808:	6906                	ld	s2,64(sp)
    8000380a:	79e2                	ld	s3,56(sp)
    8000380c:	7a42                	ld	s4,48(sp)
    8000380e:	7aa2                	ld	s5,40(sp)
    80003810:	7b02                	ld	s6,32(sp)
    80003812:	6be2                	ld	s7,24(sp)
    80003814:	6c42                	ld	s8,16(sp)
    80003816:	6ca2                	ld	s9,8(sp)
    80003818:	6125                	addi	sp,sp,96
    8000381a:	8082                	ret

000000008000381c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000381c:	7179                	addi	sp,sp,-48
    8000381e:	f406                	sd	ra,40(sp)
    80003820:	f022                	sd	s0,32(sp)
    80003822:	ec26                	sd	s1,24(sp)
    80003824:	e84a                	sd	s2,16(sp)
    80003826:	e44e                	sd	s3,8(sp)
    80003828:	e052                	sd	s4,0(sp)
    8000382a:	1800                	addi	s0,sp,48
    8000382c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000382e:	47ad                	li	a5,11
    80003830:	04b7fe63          	bgeu	a5,a1,8000388c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003834:	ff45849b          	addiw	s1,a1,-12
    80003838:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000383c:	0ff00793          	li	a5,255
    80003840:	0ae7e363          	bltu	a5,a4,800038e6 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003844:	08052583          	lw	a1,128(a0)
    80003848:	c5ad                	beqz	a1,800038b2 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000384a:	00092503          	lw	a0,0(s2)
    8000384e:	00000097          	auipc	ra,0x0
    80003852:	bda080e7          	jalr	-1062(ra) # 80003428 <bread>
    80003856:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003858:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000385c:	02049593          	slli	a1,s1,0x20
    80003860:	9181                	srli	a1,a1,0x20
    80003862:	058a                	slli	a1,a1,0x2
    80003864:	00b784b3          	add	s1,a5,a1
    80003868:	0004a983          	lw	s3,0(s1)
    8000386c:	04098d63          	beqz	s3,800038c6 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003870:	8552                	mv	a0,s4
    80003872:	00000097          	auipc	ra,0x0
    80003876:	ce6080e7          	jalr	-794(ra) # 80003558 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000387a:	854e                	mv	a0,s3
    8000387c:	70a2                	ld	ra,40(sp)
    8000387e:	7402                	ld	s0,32(sp)
    80003880:	64e2                	ld	s1,24(sp)
    80003882:	6942                	ld	s2,16(sp)
    80003884:	69a2                	ld	s3,8(sp)
    80003886:	6a02                	ld	s4,0(sp)
    80003888:	6145                	addi	sp,sp,48
    8000388a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000388c:	02059493          	slli	s1,a1,0x20
    80003890:	9081                	srli	s1,s1,0x20
    80003892:	048a                	slli	s1,s1,0x2
    80003894:	94aa                	add	s1,s1,a0
    80003896:	0504a983          	lw	s3,80(s1)
    8000389a:	fe0990e3          	bnez	s3,8000387a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000389e:	4108                	lw	a0,0(a0)
    800038a0:	00000097          	auipc	ra,0x0
    800038a4:	e4a080e7          	jalr	-438(ra) # 800036ea <balloc>
    800038a8:	0005099b          	sext.w	s3,a0
    800038ac:	0534a823          	sw	s3,80(s1)
    800038b0:	b7e9                	j	8000387a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800038b2:	4108                	lw	a0,0(a0)
    800038b4:	00000097          	auipc	ra,0x0
    800038b8:	e36080e7          	jalr	-458(ra) # 800036ea <balloc>
    800038bc:	0005059b          	sext.w	a1,a0
    800038c0:	08b92023          	sw	a1,128(s2)
    800038c4:	b759                	j	8000384a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800038c6:	00092503          	lw	a0,0(s2)
    800038ca:	00000097          	auipc	ra,0x0
    800038ce:	e20080e7          	jalr	-480(ra) # 800036ea <balloc>
    800038d2:	0005099b          	sext.w	s3,a0
    800038d6:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800038da:	8552                	mv	a0,s4
    800038dc:	00001097          	auipc	ra,0x1
    800038e0:	ef8080e7          	jalr	-264(ra) # 800047d4 <log_write>
    800038e4:	b771                	j	80003870 <bmap+0x54>
  panic("bmap: out of range");
    800038e6:	00005517          	auipc	a0,0x5
    800038ea:	d0250513          	addi	a0,a0,-766 # 800085e8 <syscalls+0x118>
    800038ee:	ffffd097          	auipc	ra,0xffffd
    800038f2:	c50080e7          	jalr	-944(ra) # 8000053e <panic>

00000000800038f6 <iget>:
{
    800038f6:	7179                	addi	sp,sp,-48
    800038f8:	f406                	sd	ra,40(sp)
    800038fa:	f022                	sd	s0,32(sp)
    800038fc:	ec26                	sd	s1,24(sp)
    800038fe:	e84a                	sd	s2,16(sp)
    80003900:	e44e                	sd	s3,8(sp)
    80003902:	e052                	sd	s4,0(sp)
    80003904:	1800                	addi	s0,sp,48
    80003906:	89aa                	mv	s3,a0
    80003908:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000390a:	0001d517          	auipc	a0,0x1d
    8000390e:	9fe50513          	addi	a0,a0,-1538 # 80020308 <itable>
    80003912:	ffffd097          	auipc	ra,0xffffd
    80003916:	2d2080e7          	jalr	722(ra) # 80000be4 <acquire>
  empty = 0;
    8000391a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000391c:	0001d497          	auipc	s1,0x1d
    80003920:	a0448493          	addi	s1,s1,-1532 # 80020320 <itable+0x18>
    80003924:	0001e697          	auipc	a3,0x1e
    80003928:	48c68693          	addi	a3,a3,1164 # 80021db0 <log>
    8000392c:	a039                	j	8000393a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000392e:	02090b63          	beqz	s2,80003964 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003932:	08848493          	addi	s1,s1,136
    80003936:	02d48a63          	beq	s1,a3,8000396a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000393a:	449c                	lw	a5,8(s1)
    8000393c:	fef059e3          	blez	a5,8000392e <iget+0x38>
    80003940:	4098                	lw	a4,0(s1)
    80003942:	ff3716e3          	bne	a4,s3,8000392e <iget+0x38>
    80003946:	40d8                	lw	a4,4(s1)
    80003948:	ff4713e3          	bne	a4,s4,8000392e <iget+0x38>
      ip->ref++;
    8000394c:	2785                	addiw	a5,a5,1
    8000394e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003950:	0001d517          	auipc	a0,0x1d
    80003954:	9b850513          	addi	a0,a0,-1608 # 80020308 <itable>
    80003958:	ffffd097          	auipc	ra,0xffffd
    8000395c:	340080e7          	jalr	832(ra) # 80000c98 <release>
      return ip;
    80003960:	8926                	mv	s2,s1
    80003962:	a03d                	j	80003990 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003964:	f7f9                	bnez	a5,80003932 <iget+0x3c>
    80003966:	8926                	mv	s2,s1
    80003968:	b7e9                	j	80003932 <iget+0x3c>
  if(empty == 0)
    8000396a:	02090c63          	beqz	s2,800039a2 <iget+0xac>
  ip->dev = dev;
    8000396e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003972:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003976:	4785                	li	a5,1
    80003978:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000397c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003980:	0001d517          	auipc	a0,0x1d
    80003984:	98850513          	addi	a0,a0,-1656 # 80020308 <itable>
    80003988:	ffffd097          	auipc	ra,0xffffd
    8000398c:	310080e7          	jalr	784(ra) # 80000c98 <release>
}
    80003990:	854a                	mv	a0,s2
    80003992:	70a2                	ld	ra,40(sp)
    80003994:	7402                	ld	s0,32(sp)
    80003996:	64e2                	ld	s1,24(sp)
    80003998:	6942                	ld	s2,16(sp)
    8000399a:	69a2                	ld	s3,8(sp)
    8000399c:	6a02                	ld	s4,0(sp)
    8000399e:	6145                	addi	sp,sp,48
    800039a0:	8082                	ret
    panic("iget: no inodes");
    800039a2:	00005517          	auipc	a0,0x5
    800039a6:	c5e50513          	addi	a0,a0,-930 # 80008600 <syscalls+0x130>
    800039aa:	ffffd097          	auipc	ra,0xffffd
    800039ae:	b94080e7          	jalr	-1132(ra) # 8000053e <panic>

00000000800039b2 <fsinit>:
fsinit(int dev) {
    800039b2:	7179                	addi	sp,sp,-48
    800039b4:	f406                	sd	ra,40(sp)
    800039b6:	f022                	sd	s0,32(sp)
    800039b8:	ec26                	sd	s1,24(sp)
    800039ba:	e84a                	sd	s2,16(sp)
    800039bc:	e44e                	sd	s3,8(sp)
    800039be:	1800                	addi	s0,sp,48
    800039c0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039c2:	4585                	li	a1,1
    800039c4:	00000097          	auipc	ra,0x0
    800039c8:	a64080e7          	jalr	-1436(ra) # 80003428 <bread>
    800039cc:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800039ce:	0001d997          	auipc	s3,0x1d
    800039d2:	91a98993          	addi	s3,s3,-1766 # 800202e8 <sb>
    800039d6:	02000613          	li	a2,32
    800039da:	05850593          	addi	a1,a0,88
    800039de:	854e                	mv	a0,s3
    800039e0:	ffffd097          	auipc	ra,0xffffd
    800039e4:	360080e7          	jalr	864(ra) # 80000d40 <memmove>
  brelse(bp);
    800039e8:	8526                	mv	a0,s1
    800039ea:	00000097          	auipc	ra,0x0
    800039ee:	b6e080e7          	jalr	-1170(ra) # 80003558 <brelse>
  if(sb.magic != FSMAGIC)
    800039f2:	0009a703          	lw	a4,0(s3)
    800039f6:	102037b7          	lui	a5,0x10203
    800039fa:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800039fe:	02f71263          	bne	a4,a5,80003a22 <fsinit+0x70>
  initlog(dev, &sb);
    80003a02:	0001d597          	auipc	a1,0x1d
    80003a06:	8e658593          	addi	a1,a1,-1818 # 800202e8 <sb>
    80003a0a:	854a                	mv	a0,s2
    80003a0c:	00001097          	auipc	ra,0x1
    80003a10:	b4c080e7          	jalr	-1204(ra) # 80004558 <initlog>
}
    80003a14:	70a2                	ld	ra,40(sp)
    80003a16:	7402                	ld	s0,32(sp)
    80003a18:	64e2                	ld	s1,24(sp)
    80003a1a:	6942                	ld	s2,16(sp)
    80003a1c:	69a2                	ld	s3,8(sp)
    80003a1e:	6145                	addi	sp,sp,48
    80003a20:	8082                	ret
    panic("invalid file system");
    80003a22:	00005517          	auipc	a0,0x5
    80003a26:	bee50513          	addi	a0,a0,-1042 # 80008610 <syscalls+0x140>
    80003a2a:	ffffd097          	auipc	ra,0xffffd
    80003a2e:	b14080e7          	jalr	-1260(ra) # 8000053e <panic>

0000000080003a32 <iinit>:
{
    80003a32:	7179                	addi	sp,sp,-48
    80003a34:	f406                	sd	ra,40(sp)
    80003a36:	f022                	sd	s0,32(sp)
    80003a38:	ec26                	sd	s1,24(sp)
    80003a3a:	e84a                	sd	s2,16(sp)
    80003a3c:	e44e                	sd	s3,8(sp)
    80003a3e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a40:	00005597          	auipc	a1,0x5
    80003a44:	be858593          	addi	a1,a1,-1048 # 80008628 <syscalls+0x158>
    80003a48:	0001d517          	auipc	a0,0x1d
    80003a4c:	8c050513          	addi	a0,a0,-1856 # 80020308 <itable>
    80003a50:	ffffd097          	auipc	ra,0xffffd
    80003a54:	104080e7          	jalr	260(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a58:	0001d497          	auipc	s1,0x1d
    80003a5c:	8d848493          	addi	s1,s1,-1832 # 80020330 <itable+0x28>
    80003a60:	0001e997          	auipc	s3,0x1e
    80003a64:	36098993          	addi	s3,s3,864 # 80021dc0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a68:	00005917          	auipc	s2,0x5
    80003a6c:	bc890913          	addi	s2,s2,-1080 # 80008630 <syscalls+0x160>
    80003a70:	85ca                	mv	a1,s2
    80003a72:	8526                	mv	a0,s1
    80003a74:	00001097          	auipc	ra,0x1
    80003a78:	e46080e7          	jalr	-442(ra) # 800048ba <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a7c:	08848493          	addi	s1,s1,136
    80003a80:	ff3498e3          	bne	s1,s3,80003a70 <iinit+0x3e>
}
    80003a84:	70a2                	ld	ra,40(sp)
    80003a86:	7402                	ld	s0,32(sp)
    80003a88:	64e2                	ld	s1,24(sp)
    80003a8a:	6942                	ld	s2,16(sp)
    80003a8c:	69a2                	ld	s3,8(sp)
    80003a8e:	6145                	addi	sp,sp,48
    80003a90:	8082                	ret

0000000080003a92 <ialloc>:
{
    80003a92:	715d                	addi	sp,sp,-80
    80003a94:	e486                	sd	ra,72(sp)
    80003a96:	e0a2                	sd	s0,64(sp)
    80003a98:	fc26                	sd	s1,56(sp)
    80003a9a:	f84a                	sd	s2,48(sp)
    80003a9c:	f44e                	sd	s3,40(sp)
    80003a9e:	f052                	sd	s4,32(sp)
    80003aa0:	ec56                	sd	s5,24(sp)
    80003aa2:	e85a                	sd	s6,16(sp)
    80003aa4:	e45e                	sd	s7,8(sp)
    80003aa6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003aa8:	0001d717          	auipc	a4,0x1d
    80003aac:	84c72703          	lw	a4,-1972(a4) # 800202f4 <sb+0xc>
    80003ab0:	4785                	li	a5,1
    80003ab2:	04e7fa63          	bgeu	a5,a4,80003b06 <ialloc+0x74>
    80003ab6:	8aaa                	mv	s5,a0
    80003ab8:	8bae                	mv	s7,a1
    80003aba:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003abc:	0001da17          	auipc	s4,0x1d
    80003ac0:	82ca0a13          	addi	s4,s4,-2004 # 800202e8 <sb>
    80003ac4:	00048b1b          	sext.w	s6,s1
    80003ac8:	0044d593          	srli	a1,s1,0x4
    80003acc:	018a2783          	lw	a5,24(s4)
    80003ad0:	9dbd                	addw	a1,a1,a5
    80003ad2:	8556                	mv	a0,s5
    80003ad4:	00000097          	auipc	ra,0x0
    80003ad8:	954080e7          	jalr	-1708(ra) # 80003428 <bread>
    80003adc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003ade:	05850993          	addi	s3,a0,88
    80003ae2:	00f4f793          	andi	a5,s1,15
    80003ae6:	079a                	slli	a5,a5,0x6
    80003ae8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003aea:	00099783          	lh	a5,0(s3)
    80003aee:	c785                	beqz	a5,80003b16 <ialloc+0x84>
    brelse(bp);
    80003af0:	00000097          	auipc	ra,0x0
    80003af4:	a68080e7          	jalr	-1432(ra) # 80003558 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003af8:	0485                	addi	s1,s1,1
    80003afa:	00ca2703          	lw	a4,12(s4)
    80003afe:	0004879b          	sext.w	a5,s1
    80003b02:	fce7e1e3          	bltu	a5,a4,80003ac4 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003b06:	00005517          	auipc	a0,0x5
    80003b0a:	b3250513          	addi	a0,a0,-1230 # 80008638 <syscalls+0x168>
    80003b0e:	ffffd097          	auipc	ra,0xffffd
    80003b12:	a30080e7          	jalr	-1488(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003b16:	04000613          	li	a2,64
    80003b1a:	4581                	li	a1,0
    80003b1c:	854e                	mv	a0,s3
    80003b1e:	ffffd097          	auipc	ra,0xffffd
    80003b22:	1c2080e7          	jalr	450(ra) # 80000ce0 <memset>
      dip->type = type;
    80003b26:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b2a:	854a                	mv	a0,s2
    80003b2c:	00001097          	auipc	ra,0x1
    80003b30:	ca8080e7          	jalr	-856(ra) # 800047d4 <log_write>
      brelse(bp);
    80003b34:	854a                	mv	a0,s2
    80003b36:	00000097          	auipc	ra,0x0
    80003b3a:	a22080e7          	jalr	-1502(ra) # 80003558 <brelse>
      return iget(dev, inum);
    80003b3e:	85da                	mv	a1,s6
    80003b40:	8556                	mv	a0,s5
    80003b42:	00000097          	auipc	ra,0x0
    80003b46:	db4080e7          	jalr	-588(ra) # 800038f6 <iget>
}
    80003b4a:	60a6                	ld	ra,72(sp)
    80003b4c:	6406                	ld	s0,64(sp)
    80003b4e:	74e2                	ld	s1,56(sp)
    80003b50:	7942                	ld	s2,48(sp)
    80003b52:	79a2                	ld	s3,40(sp)
    80003b54:	7a02                	ld	s4,32(sp)
    80003b56:	6ae2                	ld	s5,24(sp)
    80003b58:	6b42                	ld	s6,16(sp)
    80003b5a:	6ba2                	ld	s7,8(sp)
    80003b5c:	6161                	addi	sp,sp,80
    80003b5e:	8082                	ret

0000000080003b60 <iupdate>:
{
    80003b60:	1101                	addi	sp,sp,-32
    80003b62:	ec06                	sd	ra,24(sp)
    80003b64:	e822                	sd	s0,16(sp)
    80003b66:	e426                	sd	s1,8(sp)
    80003b68:	e04a                	sd	s2,0(sp)
    80003b6a:	1000                	addi	s0,sp,32
    80003b6c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b6e:	415c                	lw	a5,4(a0)
    80003b70:	0047d79b          	srliw	a5,a5,0x4
    80003b74:	0001c597          	auipc	a1,0x1c
    80003b78:	78c5a583          	lw	a1,1932(a1) # 80020300 <sb+0x18>
    80003b7c:	9dbd                	addw	a1,a1,a5
    80003b7e:	4108                	lw	a0,0(a0)
    80003b80:	00000097          	auipc	ra,0x0
    80003b84:	8a8080e7          	jalr	-1880(ra) # 80003428 <bread>
    80003b88:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b8a:	05850793          	addi	a5,a0,88
    80003b8e:	40c8                	lw	a0,4(s1)
    80003b90:	893d                	andi	a0,a0,15
    80003b92:	051a                	slli	a0,a0,0x6
    80003b94:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003b96:	04449703          	lh	a4,68(s1)
    80003b9a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b9e:	04649703          	lh	a4,70(s1)
    80003ba2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003ba6:	04849703          	lh	a4,72(s1)
    80003baa:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003bae:	04a49703          	lh	a4,74(s1)
    80003bb2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003bb6:	44f8                	lw	a4,76(s1)
    80003bb8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003bba:	03400613          	li	a2,52
    80003bbe:	05048593          	addi	a1,s1,80
    80003bc2:	0531                	addi	a0,a0,12
    80003bc4:	ffffd097          	auipc	ra,0xffffd
    80003bc8:	17c080e7          	jalr	380(ra) # 80000d40 <memmove>
  log_write(bp);
    80003bcc:	854a                	mv	a0,s2
    80003bce:	00001097          	auipc	ra,0x1
    80003bd2:	c06080e7          	jalr	-1018(ra) # 800047d4 <log_write>
  brelse(bp);
    80003bd6:	854a                	mv	a0,s2
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	980080e7          	jalr	-1664(ra) # 80003558 <brelse>
}
    80003be0:	60e2                	ld	ra,24(sp)
    80003be2:	6442                	ld	s0,16(sp)
    80003be4:	64a2                	ld	s1,8(sp)
    80003be6:	6902                	ld	s2,0(sp)
    80003be8:	6105                	addi	sp,sp,32
    80003bea:	8082                	ret

0000000080003bec <idup>:
{
    80003bec:	1101                	addi	sp,sp,-32
    80003bee:	ec06                	sd	ra,24(sp)
    80003bf0:	e822                	sd	s0,16(sp)
    80003bf2:	e426                	sd	s1,8(sp)
    80003bf4:	1000                	addi	s0,sp,32
    80003bf6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bf8:	0001c517          	auipc	a0,0x1c
    80003bfc:	71050513          	addi	a0,a0,1808 # 80020308 <itable>
    80003c00:	ffffd097          	auipc	ra,0xffffd
    80003c04:	fe4080e7          	jalr	-28(ra) # 80000be4 <acquire>
  ip->ref++;
    80003c08:	449c                	lw	a5,8(s1)
    80003c0a:	2785                	addiw	a5,a5,1
    80003c0c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c0e:	0001c517          	auipc	a0,0x1c
    80003c12:	6fa50513          	addi	a0,a0,1786 # 80020308 <itable>
    80003c16:	ffffd097          	auipc	ra,0xffffd
    80003c1a:	082080e7          	jalr	130(ra) # 80000c98 <release>
}
    80003c1e:	8526                	mv	a0,s1
    80003c20:	60e2                	ld	ra,24(sp)
    80003c22:	6442                	ld	s0,16(sp)
    80003c24:	64a2                	ld	s1,8(sp)
    80003c26:	6105                	addi	sp,sp,32
    80003c28:	8082                	ret

0000000080003c2a <ilock>:
{
    80003c2a:	1101                	addi	sp,sp,-32
    80003c2c:	ec06                	sd	ra,24(sp)
    80003c2e:	e822                	sd	s0,16(sp)
    80003c30:	e426                	sd	s1,8(sp)
    80003c32:	e04a                	sd	s2,0(sp)
    80003c34:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c36:	c115                	beqz	a0,80003c5a <ilock+0x30>
    80003c38:	84aa                	mv	s1,a0
    80003c3a:	451c                	lw	a5,8(a0)
    80003c3c:	00f05f63          	blez	a5,80003c5a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c40:	0541                	addi	a0,a0,16
    80003c42:	00001097          	auipc	ra,0x1
    80003c46:	cb2080e7          	jalr	-846(ra) # 800048f4 <acquiresleep>
  if(ip->valid == 0){
    80003c4a:	40bc                	lw	a5,64(s1)
    80003c4c:	cf99                	beqz	a5,80003c6a <ilock+0x40>
}
    80003c4e:	60e2                	ld	ra,24(sp)
    80003c50:	6442                	ld	s0,16(sp)
    80003c52:	64a2                	ld	s1,8(sp)
    80003c54:	6902                	ld	s2,0(sp)
    80003c56:	6105                	addi	sp,sp,32
    80003c58:	8082                	ret
    panic("ilock");
    80003c5a:	00005517          	auipc	a0,0x5
    80003c5e:	9f650513          	addi	a0,a0,-1546 # 80008650 <syscalls+0x180>
    80003c62:	ffffd097          	auipc	ra,0xffffd
    80003c66:	8dc080e7          	jalr	-1828(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c6a:	40dc                	lw	a5,4(s1)
    80003c6c:	0047d79b          	srliw	a5,a5,0x4
    80003c70:	0001c597          	auipc	a1,0x1c
    80003c74:	6905a583          	lw	a1,1680(a1) # 80020300 <sb+0x18>
    80003c78:	9dbd                	addw	a1,a1,a5
    80003c7a:	4088                	lw	a0,0(s1)
    80003c7c:	fffff097          	auipc	ra,0xfffff
    80003c80:	7ac080e7          	jalr	1964(ra) # 80003428 <bread>
    80003c84:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c86:	05850593          	addi	a1,a0,88
    80003c8a:	40dc                	lw	a5,4(s1)
    80003c8c:	8bbd                	andi	a5,a5,15
    80003c8e:	079a                	slli	a5,a5,0x6
    80003c90:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c92:	00059783          	lh	a5,0(a1)
    80003c96:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c9a:	00259783          	lh	a5,2(a1)
    80003c9e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003ca2:	00459783          	lh	a5,4(a1)
    80003ca6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003caa:	00659783          	lh	a5,6(a1)
    80003cae:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003cb2:	459c                	lw	a5,8(a1)
    80003cb4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003cb6:	03400613          	li	a2,52
    80003cba:	05b1                	addi	a1,a1,12
    80003cbc:	05048513          	addi	a0,s1,80
    80003cc0:	ffffd097          	auipc	ra,0xffffd
    80003cc4:	080080e7          	jalr	128(ra) # 80000d40 <memmove>
    brelse(bp);
    80003cc8:	854a                	mv	a0,s2
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	88e080e7          	jalr	-1906(ra) # 80003558 <brelse>
    ip->valid = 1;
    80003cd2:	4785                	li	a5,1
    80003cd4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003cd6:	04449783          	lh	a5,68(s1)
    80003cda:	fbb5                	bnez	a5,80003c4e <ilock+0x24>
      panic("ilock: no type");
    80003cdc:	00005517          	auipc	a0,0x5
    80003ce0:	97c50513          	addi	a0,a0,-1668 # 80008658 <syscalls+0x188>
    80003ce4:	ffffd097          	auipc	ra,0xffffd
    80003ce8:	85a080e7          	jalr	-1958(ra) # 8000053e <panic>

0000000080003cec <iunlock>:
{
    80003cec:	1101                	addi	sp,sp,-32
    80003cee:	ec06                	sd	ra,24(sp)
    80003cf0:	e822                	sd	s0,16(sp)
    80003cf2:	e426                	sd	s1,8(sp)
    80003cf4:	e04a                	sd	s2,0(sp)
    80003cf6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003cf8:	c905                	beqz	a0,80003d28 <iunlock+0x3c>
    80003cfa:	84aa                	mv	s1,a0
    80003cfc:	01050913          	addi	s2,a0,16
    80003d00:	854a                	mv	a0,s2
    80003d02:	00001097          	auipc	ra,0x1
    80003d06:	c8c080e7          	jalr	-884(ra) # 8000498e <holdingsleep>
    80003d0a:	cd19                	beqz	a0,80003d28 <iunlock+0x3c>
    80003d0c:	449c                	lw	a5,8(s1)
    80003d0e:	00f05d63          	blez	a5,80003d28 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d12:	854a                	mv	a0,s2
    80003d14:	00001097          	auipc	ra,0x1
    80003d18:	c36080e7          	jalr	-970(ra) # 8000494a <releasesleep>
}
    80003d1c:	60e2                	ld	ra,24(sp)
    80003d1e:	6442                	ld	s0,16(sp)
    80003d20:	64a2                	ld	s1,8(sp)
    80003d22:	6902                	ld	s2,0(sp)
    80003d24:	6105                	addi	sp,sp,32
    80003d26:	8082                	ret
    panic("iunlock");
    80003d28:	00005517          	auipc	a0,0x5
    80003d2c:	94050513          	addi	a0,a0,-1728 # 80008668 <syscalls+0x198>
    80003d30:	ffffd097          	auipc	ra,0xffffd
    80003d34:	80e080e7          	jalr	-2034(ra) # 8000053e <panic>

0000000080003d38 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d38:	7179                	addi	sp,sp,-48
    80003d3a:	f406                	sd	ra,40(sp)
    80003d3c:	f022                	sd	s0,32(sp)
    80003d3e:	ec26                	sd	s1,24(sp)
    80003d40:	e84a                	sd	s2,16(sp)
    80003d42:	e44e                	sd	s3,8(sp)
    80003d44:	e052                	sd	s4,0(sp)
    80003d46:	1800                	addi	s0,sp,48
    80003d48:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d4a:	05050493          	addi	s1,a0,80
    80003d4e:	08050913          	addi	s2,a0,128
    80003d52:	a021                	j	80003d5a <itrunc+0x22>
    80003d54:	0491                	addi	s1,s1,4
    80003d56:	01248d63          	beq	s1,s2,80003d70 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d5a:	408c                	lw	a1,0(s1)
    80003d5c:	dde5                	beqz	a1,80003d54 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d5e:	0009a503          	lw	a0,0(s3)
    80003d62:	00000097          	auipc	ra,0x0
    80003d66:	90c080e7          	jalr	-1780(ra) # 8000366e <bfree>
      ip->addrs[i] = 0;
    80003d6a:	0004a023          	sw	zero,0(s1)
    80003d6e:	b7dd                	j	80003d54 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d70:	0809a583          	lw	a1,128(s3)
    80003d74:	e185                	bnez	a1,80003d94 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d76:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d7a:	854e                	mv	a0,s3
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	de4080e7          	jalr	-540(ra) # 80003b60 <iupdate>
}
    80003d84:	70a2                	ld	ra,40(sp)
    80003d86:	7402                	ld	s0,32(sp)
    80003d88:	64e2                	ld	s1,24(sp)
    80003d8a:	6942                	ld	s2,16(sp)
    80003d8c:	69a2                	ld	s3,8(sp)
    80003d8e:	6a02                	ld	s4,0(sp)
    80003d90:	6145                	addi	sp,sp,48
    80003d92:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d94:	0009a503          	lw	a0,0(s3)
    80003d98:	fffff097          	auipc	ra,0xfffff
    80003d9c:	690080e7          	jalr	1680(ra) # 80003428 <bread>
    80003da0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003da2:	05850493          	addi	s1,a0,88
    80003da6:	45850913          	addi	s2,a0,1112
    80003daa:	a811                	j	80003dbe <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003dac:	0009a503          	lw	a0,0(s3)
    80003db0:	00000097          	auipc	ra,0x0
    80003db4:	8be080e7          	jalr	-1858(ra) # 8000366e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003db8:	0491                	addi	s1,s1,4
    80003dba:	01248563          	beq	s1,s2,80003dc4 <itrunc+0x8c>
      if(a[j])
    80003dbe:	408c                	lw	a1,0(s1)
    80003dc0:	dde5                	beqz	a1,80003db8 <itrunc+0x80>
    80003dc2:	b7ed                	j	80003dac <itrunc+0x74>
    brelse(bp);
    80003dc4:	8552                	mv	a0,s4
    80003dc6:	fffff097          	auipc	ra,0xfffff
    80003dca:	792080e7          	jalr	1938(ra) # 80003558 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003dce:	0809a583          	lw	a1,128(s3)
    80003dd2:	0009a503          	lw	a0,0(s3)
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	898080e7          	jalr	-1896(ra) # 8000366e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003dde:	0809a023          	sw	zero,128(s3)
    80003de2:	bf51                	j	80003d76 <itrunc+0x3e>

0000000080003de4 <iput>:
{
    80003de4:	1101                	addi	sp,sp,-32
    80003de6:	ec06                	sd	ra,24(sp)
    80003de8:	e822                	sd	s0,16(sp)
    80003dea:	e426                	sd	s1,8(sp)
    80003dec:	e04a                	sd	s2,0(sp)
    80003dee:	1000                	addi	s0,sp,32
    80003df0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003df2:	0001c517          	auipc	a0,0x1c
    80003df6:	51650513          	addi	a0,a0,1302 # 80020308 <itable>
    80003dfa:	ffffd097          	auipc	ra,0xffffd
    80003dfe:	dea080e7          	jalr	-534(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e02:	4498                	lw	a4,8(s1)
    80003e04:	4785                	li	a5,1
    80003e06:	02f70363          	beq	a4,a5,80003e2c <iput+0x48>
  ip->ref--;
    80003e0a:	449c                	lw	a5,8(s1)
    80003e0c:	37fd                	addiw	a5,a5,-1
    80003e0e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e10:	0001c517          	auipc	a0,0x1c
    80003e14:	4f850513          	addi	a0,a0,1272 # 80020308 <itable>
    80003e18:	ffffd097          	auipc	ra,0xffffd
    80003e1c:	e80080e7          	jalr	-384(ra) # 80000c98 <release>
}
    80003e20:	60e2                	ld	ra,24(sp)
    80003e22:	6442                	ld	s0,16(sp)
    80003e24:	64a2                	ld	s1,8(sp)
    80003e26:	6902                	ld	s2,0(sp)
    80003e28:	6105                	addi	sp,sp,32
    80003e2a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e2c:	40bc                	lw	a5,64(s1)
    80003e2e:	dff1                	beqz	a5,80003e0a <iput+0x26>
    80003e30:	04a49783          	lh	a5,74(s1)
    80003e34:	fbf9                	bnez	a5,80003e0a <iput+0x26>
    acquiresleep(&ip->lock);
    80003e36:	01048913          	addi	s2,s1,16
    80003e3a:	854a                	mv	a0,s2
    80003e3c:	00001097          	auipc	ra,0x1
    80003e40:	ab8080e7          	jalr	-1352(ra) # 800048f4 <acquiresleep>
    release(&itable.lock);
    80003e44:	0001c517          	auipc	a0,0x1c
    80003e48:	4c450513          	addi	a0,a0,1220 # 80020308 <itable>
    80003e4c:	ffffd097          	auipc	ra,0xffffd
    80003e50:	e4c080e7          	jalr	-436(ra) # 80000c98 <release>
    itrunc(ip);
    80003e54:	8526                	mv	a0,s1
    80003e56:	00000097          	auipc	ra,0x0
    80003e5a:	ee2080e7          	jalr	-286(ra) # 80003d38 <itrunc>
    ip->type = 0;
    80003e5e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e62:	8526                	mv	a0,s1
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	cfc080e7          	jalr	-772(ra) # 80003b60 <iupdate>
    ip->valid = 0;
    80003e6c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e70:	854a                	mv	a0,s2
    80003e72:	00001097          	auipc	ra,0x1
    80003e76:	ad8080e7          	jalr	-1320(ra) # 8000494a <releasesleep>
    acquire(&itable.lock);
    80003e7a:	0001c517          	auipc	a0,0x1c
    80003e7e:	48e50513          	addi	a0,a0,1166 # 80020308 <itable>
    80003e82:	ffffd097          	auipc	ra,0xffffd
    80003e86:	d62080e7          	jalr	-670(ra) # 80000be4 <acquire>
    80003e8a:	b741                	j	80003e0a <iput+0x26>

0000000080003e8c <iunlockput>:
{
    80003e8c:	1101                	addi	sp,sp,-32
    80003e8e:	ec06                	sd	ra,24(sp)
    80003e90:	e822                	sd	s0,16(sp)
    80003e92:	e426                	sd	s1,8(sp)
    80003e94:	1000                	addi	s0,sp,32
    80003e96:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e98:	00000097          	auipc	ra,0x0
    80003e9c:	e54080e7          	jalr	-428(ra) # 80003cec <iunlock>
  iput(ip);
    80003ea0:	8526                	mv	a0,s1
    80003ea2:	00000097          	auipc	ra,0x0
    80003ea6:	f42080e7          	jalr	-190(ra) # 80003de4 <iput>
}
    80003eaa:	60e2                	ld	ra,24(sp)
    80003eac:	6442                	ld	s0,16(sp)
    80003eae:	64a2                	ld	s1,8(sp)
    80003eb0:	6105                	addi	sp,sp,32
    80003eb2:	8082                	ret

0000000080003eb4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003eb4:	1141                	addi	sp,sp,-16
    80003eb6:	e422                	sd	s0,8(sp)
    80003eb8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003eba:	411c                	lw	a5,0(a0)
    80003ebc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ebe:	415c                	lw	a5,4(a0)
    80003ec0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ec2:	04451783          	lh	a5,68(a0)
    80003ec6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003eca:	04a51783          	lh	a5,74(a0)
    80003ece:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ed2:	04c56783          	lwu	a5,76(a0)
    80003ed6:	e99c                	sd	a5,16(a1)
}
    80003ed8:	6422                	ld	s0,8(sp)
    80003eda:	0141                	addi	sp,sp,16
    80003edc:	8082                	ret

0000000080003ede <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ede:	457c                	lw	a5,76(a0)
    80003ee0:	0ed7e963          	bltu	a5,a3,80003fd2 <readi+0xf4>
{
    80003ee4:	7159                	addi	sp,sp,-112
    80003ee6:	f486                	sd	ra,104(sp)
    80003ee8:	f0a2                	sd	s0,96(sp)
    80003eea:	eca6                	sd	s1,88(sp)
    80003eec:	e8ca                	sd	s2,80(sp)
    80003eee:	e4ce                	sd	s3,72(sp)
    80003ef0:	e0d2                	sd	s4,64(sp)
    80003ef2:	fc56                	sd	s5,56(sp)
    80003ef4:	f85a                	sd	s6,48(sp)
    80003ef6:	f45e                	sd	s7,40(sp)
    80003ef8:	f062                	sd	s8,32(sp)
    80003efa:	ec66                	sd	s9,24(sp)
    80003efc:	e86a                	sd	s10,16(sp)
    80003efe:	e46e                	sd	s11,8(sp)
    80003f00:	1880                	addi	s0,sp,112
    80003f02:	8baa                	mv	s7,a0
    80003f04:	8c2e                	mv	s8,a1
    80003f06:	8ab2                	mv	s5,a2
    80003f08:	84b6                	mv	s1,a3
    80003f0a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f0c:	9f35                	addw	a4,a4,a3
    return 0;
    80003f0e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f10:	0ad76063          	bltu	a4,a3,80003fb0 <readi+0xd2>
  if(off + n > ip->size)
    80003f14:	00e7f463          	bgeu	a5,a4,80003f1c <readi+0x3e>
    n = ip->size - off;
    80003f18:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f1c:	0a0b0963          	beqz	s6,80003fce <readi+0xf0>
    80003f20:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f22:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f26:	5cfd                	li	s9,-1
    80003f28:	a82d                	j	80003f62 <readi+0x84>
    80003f2a:	020a1d93          	slli	s11,s4,0x20
    80003f2e:	020ddd93          	srli	s11,s11,0x20
    80003f32:	05890613          	addi	a2,s2,88
    80003f36:	86ee                	mv	a3,s11
    80003f38:	963a                	add	a2,a2,a4
    80003f3a:	85d6                	mv	a1,s5
    80003f3c:	8562                	mv	a0,s8
    80003f3e:	fffff097          	auipc	ra,0xfffff
    80003f42:	a42080e7          	jalr	-1470(ra) # 80002980 <either_copyout>
    80003f46:	05950d63          	beq	a0,s9,80003fa0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f4a:	854a                	mv	a0,s2
    80003f4c:	fffff097          	auipc	ra,0xfffff
    80003f50:	60c080e7          	jalr	1548(ra) # 80003558 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f54:	013a09bb          	addw	s3,s4,s3
    80003f58:	009a04bb          	addw	s1,s4,s1
    80003f5c:	9aee                	add	s5,s5,s11
    80003f5e:	0569f763          	bgeu	s3,s6,80003fac <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f62:	000ba903          	lw	s2,0(s7)
    80003f66:	00a4d59b          	srliw	a1,s1,0xa
    80003f6a:	855e                	mv	a0,s7
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	8b0080e7          	jalr	-1872(ra) # 8000381c <bmap>
    80003f74:	0005059b          	sext.w	a1,a0
    80003f78:	854a                	mv	a0,s2
    80003f7a:	fffff097          	auipc	ra,0xfffff
    80003f7e:	4ae080e7          	jalr	1198(ra) # 80003428 <bread>
    80003f82:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f84:	3ff4f713          	andi	a4,s1,1023
    80003f88:	40ed07bb          	subw	a5,s10,a4
    80003f8c:	413b06bb          	subw	a3,s6,s3
    80003f90:	8a3e                	mv	s4,a5
    80003f92:	2781                	sext.w	a5,a5
    80003f94:	0006861b          	sext.w	a2,a3
    80003f98:	f8f679e3          	bgeu	a2,a5,80003f2a <readi+0x4c>
    80003f9c:	8a36                	mv	s4,a3
    80003f9e:	b771                	j	80003f2a <readi+0x4c>
      brelse(bp);
    80003fa0:	854a                	mv	a0,s2
    80003fa2:	fffff097          	auipc	ra,0xfffff
    80003fa6:	5b6080e7          	jalr	1462(ra) # 80003558 <brelse>
      tot = -1;
    80003faa:	59fd                	li	s3,-1
  }
  return tot;
    80003fac:	0009851b          	sext.w	a0,s3
}
    80003fb0:	70a6                	ld	ra,104(sp)
    80003fb2:	7406                	ld	s0,96(sp)
    80003fb4:	64e6                	ld	s1,88(sp)
    80003fb6:	6946                	ld	s2,80(sp)
    80003fb8:	69a6                	ld	s3,72(sp)
    80003fba:	6a06                	ld	s4,64(sp)
    80003fbc:	7ae2                	ld	s5,56(sp)
    80003fbe:	7b42                	ld	s6,48(sp)
    80003fc0:	7ba2                	ld	s7,40(sp)
    80003fc2:	7c02                	ld	s8,32(sp)
    80003fc4:	6ce2                	ld	s9,24(sp)
    80003fc6:	6d42                	ld	s10,16(sp)
    80003fc8:	6da2                	ld	s11,8(sp)
    80003fca:	6165                	addi	sp,sp,112
    80003fcc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fce:	89da                	mv	s3,s6
    80003fd0:	bff1                	j	80003fac <readi+0xce>
    return 0;
    80003fd2:	4501                	li	a0,0
}
    80003fd4:	8082                	ret

0000000080003fd6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fd6:	457c                	lw	a5,76(a0)
    80003fd8:	10d7e863          	bltu	a5,a3,800040e8 <writei+0x112>
{
    80003fdc:	7159                	addi	sp,sp,-112
    80003fde:	f486                	sd	ra,104(sp)
    80003fe0:	f0a2                	sd	s0,96(sp)
    80003fe2:	eca6                	sd	s1,88(sp)
    80003fe4:	e8ca                	sd	s2,80(sp)
    80003fe6:	e4ce                	sd	s3,72(sp)
    80003fe8:	e0d2                	sd	s4,64(sp)
    80003fea:	fc56                	sd	s5,56(sp)
    80003fec:	f85a                	sd	s6,48(sp)
    80003fee:	f45e                	sd	s7,40(sp)
    80003ff0:	f062                	sd	s8,32(sp)
    80003ff2:	ec66                	sd	s9,24(sp)
    80003ff4:	e86a                	sd	s10,16(sp)
    80003ff6:	e46e                	sd	s11,8(sp)
    80003ff8:	1880                	addi	s0,sp,112
    80003ffa:	8b2a                	mv	s6,a0
    80003ffc:	8c2e                	mv	s8,a1
    80003ffe:	8ab2                	mv	s5,a2
    80004000:	8936                	mv	s2,a3
    80004002:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004004:	00e687bb          	addw	a5,a3,a4
    80004008:	0ed7e263          	bltu	a5,a3,800040ec <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000400c:	00043737          	lui	a4,0x43
    80004010:	0ef76063          	bltu	a4,a5,800040f0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004014:	0c0b8863          	beqz	s7,800040e4 <writei+0x10e>
    80004018:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000401a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000401e:	5cfd                	li	s9,-1
    80004020:	a091                	j	80004064 <writei+0x8e>
    80004022:	02099d93          	slli	s11,s3,0x20
    80004026:	020ddd93          	srli	s11,s11,0x20
    8000402a:	05848513          	addi	a0,s1,88
    8000402e:	86ee                	mv	a3,s11
    80004030:	8656                	mv	a2,s5
    80004032:	85e2                	mv	a1,s8
    80004034:	953a                	add	a0,a0,a4
    80004036:	fffff097          	auipc	ra,0xfffff
    8000403a:	9a0080e7          	jalr	-1632(ra) # 800029d6 <either_copyin>
    8000403e:	07950263          	beq	a0,s9,800040a2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004042:	8526                	mv	a0,s1
    80004044:	00000097          	auipc	ra,0x0
    80004048:	790080e7          	jalr	1936(ra) # 800047d4 <log_write>
    brelse(bp);
    8000404c:	8526                	mv	a0,s1
    8000404e:	fffff097          	auipc	ra,0xfffff
    80004052:	50a080e7          	jalr	1290(ra) # 80003558 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004056:	01498a3b          	addw	s4,s3,s4
    8000405a:	0129893b          	addw	s2,s3,s2
    8000405e:	9aee                	add	s5,s5,s11
    80004060:	057a7663          	bgeu	s4,s7,800040ac <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004064:	000b2483          	lw	s1,0(s6)
    80004068:	00a9559b          	srliw	a1,s2,0xa
    8000406c:	855a                	mv	a0,s6
    8000406e:	fffff097          	auipc	ra,0xfffff
    80004072:	7ae080e7          	jalr	1966(ra) # 8000381c <bmap>
    80004076:	0005059b          	sext.w	a1,a0
    8000407a:	8526                	mv	a0,s1
    8000407c:	fffff097          	auipc	ra,0xfffff
    80004080:	3ac080e7          	jalr	940(ra) # 80003428 <bread>
    80004084:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004086:	3ff97713          	andi	a4,s2,1023
    8000408a:	40ed07bb          	subw	a5,s10,a4
    8000408e:	414b86bb          	subw	a3,s7,s4
    80004092:	89be                	mv	s3,a5
    80004094:	2781                	sext.w	a5,a5
    80004096:	0006861b          	sext.w	a2,a3
    8000409a:	f8f674e3          	bgeu	a2,a5,80004022 <writei+0x4c>
    8000409e:	89b6                	mv	s3,a3
    800040a0:	b749                	j	80004022 <writei+0x4c>
      brelse(bp);
    800040a2:	8526                	mv	a0,s1
    800040a4:	fffff097          	auipc	ra,0xfffff
    800040a8:	4b4080e7          	jalr	1204(ra) # 80003558 <brelse>
  }

  if(off > ip->size)
    800040ac:	04cb2783          	lw	a5,76(s6)
    800040b0:	0127f463          	bgeu	a5,s2,800040b8 <writei+0xe2>
    ip->size = off;
    800040b4:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800040b8:	855a                	mv	a0,s6
    800040ba:	00000097          	auipc	ra,0x0
    800040be:	aa6080e7          	jalr	-1370(ra) # 80003b60 <iupdate>

  return tot;
    800040c2:	000a051b          	sext.w	a0,s4
}
    800040c6:	70a6                	ld	ra,104(sp)
    800040c8:	7406                	ld	s0,96(sp)
    800040ca:	64e6                	ld	s1,88(sp)
    800040cc:	6946                	ld	s2,80(sp)
    800040ce:	69a6                	ld	s3,72(sp)
    800040d0:	6a06                	ld	s4,64(sp)
    800040d2:	7ae2                	ld	s5,56(sp)
    800040d4:	7b42                	ld	s6,48(sp)
    800040d6:	7ba2                	ld	s7,40(sp)
    800040d8:	7c02                	ld	s8,32(sp)
    800040da:	6ce2                	ld	s9,24(sp)
    800040dc:	6d42                	ld	s10,16(sp)
    800040de:	6da2                	ld	s11,8(sp)
    800040e0:	6165                	addi	sp,sp,112
    800040e2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040e4:	8a5e                	mv	s4,s7
    800040e6:	bfc9                	j	800040b8 <writei+0xe2>
    return -1;
    800040e8:	557d                	li	a0,-1
}
    800040ea:	8082                	ret
    return -1;
    800040ec:	557d                	li	a0,-1
    800040ee:	bfe1                	j	800040c6 <writei+0xf0>
    return -1;
    800040f0:	557d                	li	a0,-1
    800040f2:	bfd1                	j	800040c6 <writei+0xf0>

00000000800040f4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800040f4:	1141                	addi	sp,sp,-16
    800040f6:	e406                	sd	ra,8(sp)
    800040f8:	e022                	sd	s0,0(sp)
    800040fa:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800040fc:	4639                	li	a2,14
    800040fe:	ffffd097          	auipc	ra,0xffffd
    80004102:	cba080e7          	jalr	-838(ra) # 80000db8 <strncmp>
}
    80004106:	60a2                	ld	ra,8(sp)
    80004108:	6402                	ld	s0,0(sp)
    8000410a:	0141                	addi	sp,sp,16
    8000410c:	8082                	ret

000000008000410e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000410e:	7139                	addi	sp,sp,-64
    80004110:	fc06                	sd	ra,56(sp)
    80004112:	f822                	sd	s0,48(sp)
    80004114:	f426                	sd	s1,40(sp)
    80004116:	f04a                	sd	s2,32(sp)
    80004118:	ec4e                	sd	s3,24(sp)
    8000411a:	e852                	sd	s4,16(sp)
    8000411c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000411e:	04451703          	lh	a4,68(a0)
    80004122:	4785                	li	a5,1
    80004124:	00f71a63          	bne	a4,a5,80004138 <dirlookup+0x2a>
    80004128:	892a                	mv	s2,a0
    8000412a:	89ae                	mv	s3,a1
    8000412c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000412e:	457c                	lw	a5,76(a0)
    80004130:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004132:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004134:	e79d                	bnez	a5,80004162 <dirlookup+0x54>
    80004136:	a8a5                	j	800041ae <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004138:	00004517          	auipc	a0,0x4
    8000413c:	53850513          	addi	a0,a0,1336 # 80008670 <syscalls+0x1a0>
    80004140:	ffffc097          	auipc	ra,0xffffc
    80004144:	3fe080e7          	jalr	1022(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004148:	00004517          	auipc	a0,0x4
    8000414c:	54050513          	addi	a0,a0,1344 # 80008688 <syscalls+0x1b8>
    80004150:	ffffc097          	auipc	ra,0xffffc
    80004154:	3ee080e7          	jalr	1006(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004158:	24c1                	addiw	s1,s1,16
    8000415a:	04c92783          	lw	a5,76(s2)
    8000415e:	04f4f763          	bgeu	s1,a5,800041ac <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004162:	4741                	li	a4,16
    80004164:	86a6                	mv	a3,s1
    80004166:	fc040613          	addi	a2,s0,-64
    8000416a:	4581                	li	a1,0
    8000416c:	854a                	mv	a0,s2
    8000416e:	00000097          	auipc	ra,0x0
    80004172:	d70080e7          	jalr	-656(ra) # 80003ede <readi>
    80004176:	47c1                	li	a5,16
    80004178:	fcf518e3          	bne	a0,a5,80004148 <dirlookup+0x3a>
    if(de.inum == 0)
    8000417c:	fc045783          	lhu	a5,-64(s0)
    80004180:	dfe1                	beqz	a5,80004158 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004182:	fc240593          	addi	a1,s0,-62
    80004186:	854e                	mv	a0,s3
    80004188:	00000097          	auipc	ra,0x0
    8000418c:	f6c080e7          	jalr	-148(ra) # 800040f4 <namecmp>
    80004190:	f561                	bnez	a0,80004158 <dirlookup+0x4a>
      if(poff)
    80004192:	000a0463          	beqz	s4,8000419a <dirlookup+0x8c>
        *poff = off;
    80004196:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000419a:	fc045583          	lhu	a1,-64(s0)
    8000419e:	00092503          	lw	a0,0(s2)
    800041a2:	fffff097          	auipc	ra,0xfffff
    800041a6:	754080e7          	jalr	1876(ra) # 800038f6 <iget>
    800041aa:	a011                	j	800041ae <dirlookup+0xa0>
  return 0;
    800041ac:	4501                	li	a0,0
}
    800041ae:	70e2                	ld	ra,56(sp)
    800041b0:	7442                	ld	s0,48(sp)
    800041b2:	74a2                	ld	s1,40(sp)
    800041b4:	7902                	ld	s2,32(sp)
    800041b6:	69e2                	ld	s3,24(sp)
    800041b8:	6a42                	ld	s4,16(sp)
    800041ba:	6121                	addi	sp,sp,64
    800041bc:	8082                	ret

00000000800041be <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800041be:	711d                	addi	sp,sp,-96
    800041c0:	ec86                	sd	ra,88(sp)
    800041c2:	e8a2                	sd	s0,80(sp)
    800041c4:	e4a6                	sd	s1,72(sp)
    800041c6:	e0ca                	sd	s2,64(sp)
    800041c8:	fc4e                	sd	s3,56(sp)
    800041ca:	f852                	sd	s4,48(sp)
    800041cc:	f456                	sd	s5,40(sp)
    800041ce:	f05a                	sd	s6,32(sp)
    800041d0:	ec5e                	sd	s7,24(sp)
    800041d2:	e862                	sd	s8,16(sp)
    800041d4:	e466                	sd	s9,8(sp)
    800041d6:	1080                	addi	s0,sp,96
    800041d8:	84aa                	mv	s1,a0
    800041da:	8b2e                	mv	s6,a1
    800041dc:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041de:	00054703          	lbu	a4,0(a0)
    800041e2:	02f00793          	li	a5,47
    800041e6:	02f70363          	beq	a4,a5,8000420c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041ea:	ffffe097          	auipc	ra,0xffffe
    800041ee:	b50080e7          	jalr	-1200(ra) # 80001d3a <myproc>
    800041f2:	15053503          	ld	a0,336(a0)
    800041f6:	00000097          	auipc	ra,0x0
    800041fa:	9f6080e7          	jalr	-1546(ra) # 80003bec <idup>
    800041fe:	89aa                	mv	s3,a0
  while(*path == '/')
    80004200:	02f00913          	li	s2,47
  len = path - s;
    80004204:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004206:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004208:	4c05                	li	s8,1
    8000420a:	a865                	j	800042c2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000420c:	4585                	li	a1,1
    8000420e:	4505                	li	a0,1
    80004210:	fffff097          	auipc	ra,0xfffff
    80004214:	6e6080e7          	jalr	1766(ra) # 800038f6 <iget>
    80004218:	89aa                	mv	s3,a0
    8000421a:	b7dd                	j	80004200 <namex+0x42>
      iunlockput(ip);
    8000421c:	854e                	mv	a0,s3
    8000421e:	00000097          	auipc	ra,0x0
    80004222:	c6e080e7          	jalr	-914(ra) # 80003e8c <iunlockput>
      return 0;
    80004226:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004228:	854e                	mv	a0,s3
    8000422a:	60e6                	ld	ra,88(sp)
    8000422c:	6446                	ld	s0,80(sp)
    8000422e:	64a6                	ld	s1,72(sp)
    80004230:	6906                	ld	s2,64(sp)
    80004232:	79e2                	ld	s3,56(sp)
    80004234:	7a42                	ld	s4,48(sp)
    80004236:	7aa2                	ld	s5,40(sp)
    80004238:	7b02                	ld	s6,32(sp)
    8000423a:	6be2                	ld	s7,24(sp)
    8000423c:	6c42                	ld	s8,16(sp)
    8000423e:	6ca2                	ld	s9,8(sp)
    80004240:	6125                	addi	sp,sp,96
    80004242:	8082                	ret
      iunlock(ip);
    80004244:	854e                	mv	a0,s3
    80004246:	00000097          	auipc	ra,0x0
    8000424a:	aa6080e7          	jalr	-1370(ra) # 80003cec <iunlock>
      return ip;
    8000424e:	bfe9                	j	80004228 <namex+0x6a>
      iunlockput(ip);
    80004250:	854e                	mv	a0,s3
    80004252:	00000097          	auipc	ra,0x0
    80004256:	c3a080e7          	jalr	-966(ra) # 80003e8c <iunlockput>
      return 0;
    8000425a:	89d2                	mv	s3,s4
    8000425c:	b7f1                	j	80004228 <namex+0x6a>
  len = path - s;
    8000425e:	40b48633          	sub	a2,s1,a1
    80004262:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004266:	094cd463          	bge	s9,s4,800042ee <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000426a:	4639                	li	a2,14
    8000426c:	8556                	mv	a0,s5
    8000426e:	ffffd097          	auipc	ra,0xffffd
    80004272:	ad2080e7          	jalr	-1326(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004276:	0004c783          	lbu	a5,0(s1)
    8000427a:	01279763          	bne	a5,s2,80004288 <namex+0xca>
    path++;
    8000427e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004280:	0004c783          	lbu	a5,0(s1)
    80004284:	ff278de3          	beq	a5,s2,8000427e <namex+0xc0>
    ilock(ip);
    80004288:	854e                	mv	a0,s3
    8000428a:	00000097          	auipc	ra,0x0
    8000428e:	9a0080e7          	jalr	-1632(ra) # 80003c2a <ilock>
    if(ip->type != T_DIR){
    80004292:	04499783          	lh	a5,68(s3)
    80004296:	f98793e3          	bne	a5,s8,8000421c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000429a:	000b0563          	beqz	s6,800042a4 <namex+0xe6>
    8000429e:	0004c783          	lbu	a5,0(s1)
    800042a2:	d3cd                	beqz	a5,80004244 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042a4:	865e                	mv	a2,s7
    800042a6:	85d6                	mv	a1,s5
    800042a8:	854e                	mv	a0,s3
    800042aa:	00000097          	auipc	ra,0x0
    800042ae:	e64080e7          	jalr	-412(ra) # 8000410e <dirlookup>
    800042b2:	8a2a                	mv	s4,a0
    800042b4:	dd51                	beqz	a0,80004250 <namex+0x92>
    iunlockput(ip);
    800042b6:	854e                	mv	a0,s3
    800042b8:	00000097          	auipc	ra,0x0
    800042bc:	bd4080e7          	jalr	-1068(ra) # 80003e8c <iunlockput>
    ip = next;
    800042c0:	89d2                	mv	s3,s4
  while(*path == '/')
    800042c2:	0004c783          	lbu	a5,0(s1)
    800042c6:	05279763          	bne	a5,s2,80004314 <namex+0x156>
    path++;
    800042ca:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042cc:	0004c783          	lbu	a5,0(s1)
    800042d0:	ff278de3          	beq	a5,s2,800042ca <namex+0x10c>
  if(*path == 0)
    800042d4:	c79d                	beqz	a5,80004302 <namex+0x144>
    path++;
    800042d6:	85a6                	mv	a1,s1
  len = path - s;
    800042d8:	8a5e                	mv	s4,s7
    800042da:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800042dc:	01278963          	beq	a5,s2,800042ee <namex+0x130>
    800042e0:	dfbd                	beqz	a5,8000425e <namex+0xa0>
    path++;
    800042e2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800042e4:	0004c783          	lbu	a5,0(s1)
    800042e8:	ff279ce3          	bne	a5,s2,800042e0 <namex+0x122>
    800042ec:	bf8d                	j	8000425e <namex+0xa0>
    memmove(name, s, len);
    800042ee:	2601                	sext.w	a2,a2
    800042f0:	8556                	mv	a0,s5
    800042f2:	ffffd097          	auipc	ra,0xffffd
    800042f6:	a4e080e7          	jalr	-1458(ra) # 80000d40 <memmove>
    name[len] = 0;
    800042fa:	9a56                	add	s4,s4,s5
    800042fc:	000a0023          	sb	zero,0(s4)
    80004300:	bf9d                	j	80004276 <namex+0xb8>
  if(nameiparent){
    80004302:	f20b03e3          	beqz	s6,80004228 <namex+0x6a>
    iput(ip);
    80004306:	854e                	mv	a0,s3
    80004308:	00000097          	auipc	ra,0x0
    8000430c:	adc080e7          	jalr	-1316(ra) # 80003de4 <iput>
    return 0;
    80004310:	4981                	li	s3,0
    80004312:	bf19                	j	80004228 <namex+0x6a>
  if(*path == 0)
    80004314:	d7fd                	beqz	a5,80004302 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004316:	0004c783          	lbu	a5,0(s1)
    8000431a:	85a6                	mv	a1,s1
    8000431c:	b7d1                	j	800042e0 <namex+0x122>

000000008000431e <dirlink>:
{
    8000431e:	7139                	addi	sp,sp,-64
    80004320:	fc06                	sd	ra,56(sp)
    80004322:	f822                	sd	s0,48(sp)
    80004324:	f426                	sd	s1,40(sp)
    80004326:	f04a                	sd	s2,32(sp)
    80004328:	ec4e                	sd	s3,24(sp)
    8000432a:	e852                	sd	s4,16(sp)
    8000432c:	0080                	addi	s0,sp,64
    8000432e:	892a                	mv	s2,a0
    80004330:	8a2e                	mv	s4,a1
    80004332:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004334:	4601                	li	a2,0
    80004336:	00000097          	auipc	ra,0x0
    8000433a:	dd8080e7          	jalr	-552(ra) # 8000410e <dirlookup>
    8000433e:	e93d                	bnez	a0,800043b4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004340:	04c92483          	lw	s1,76(s2)
    80004344:	c49d                	beqz	s1,80004372 <dirlink+0x54>
    80004346:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004348:	4741                	li	a4,16
    8000434a:	86a6                	mv	a3,s1
    8000434c:	fc040613          	addi	a2,s0,-64
    80004350:	4581                	li	a1,0
    80004352:	854a                	mv	a0,s2
    80004354:	00000097          	auipc	ra,0x0
    80004358:	b8a080e7          	jalr	-1142(ra) # 80003ede <readi>
    8000435c:	47c1                	li	a5,16
    8000435e:	06f51163          	bne	a0,a5,800043c0 <dirlink+0xa2>
    if(de.inum == 0)
    80004362:	fc045783          	lhu	a5,-64(s0)
    80004366:	c791                	beqz	a5,80004372 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004368:	24c1                	addiw	s1,s1,16
    8000436a:	04c92783          	lw	a5,76(s2)
    8000436e:	fcf4ede3          	bltu	s1,a5,80004348 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004372:	4639                	li	a2,14
    80004374:	85d2                	mv	a1,s4
    80004376:	fc240513          	addi	a0,s0,-62
    8000437a:	ffffd097          	auipc	ra,0xffffd
    8000437e:	a7a080e7          	jalr	-1414(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004382:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004386:	4741                	li	a4,16
    80004388:	86a6                	mv	a3,s1
    8000438a:	fc040613          	addi	a2,s0,-64
    8000438e:	4581                	li	a1,0
    80004390:	854a                	mv	a0,s2
    80004392:	00000097          	auipc	ra,0x0
    80004396:	c44080e7          	jalr	-956(ra) # 80003fd6 <writei>
    8000439a:	872a                	mv	a4,a0
    8000439c:	47c1                	li	a5,16
  return 0;
    8000439e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043a0:	02f71863          	bne	a4,a5,800043d0 <dirlink+0xb2>
}
    800043a4:	70e2                	ld	ra,56(sp)
    800043a6:	7442                	ld	s0,48(sp)
    800043a8:	74a2                	ld	s1,40(sp)
    800043aa:	7902                	ld	s2,32(sp)
    800043ac:	69e2                	ld	s3,24(sp)
    800043ae:	6a42                	ld	s4,16(sp)
    800043b0:	6121                	addi	sp,sp,64
    800043b2:	8082                	ret
    iput(ip);
    800043b4:	00000097          	auipc	ra,0x0
    800043b8:	a30080e7          	jalr	-1488(ra) # 80003de4 <iput>
    return -1;
    800043bc:	557d                	li	a0,-1
    800043be:	b7dd                	j	800043a4 <dirlink+0x86>
      panic("dirlink read");
    800043c0:	00004517          	auipc	a0,0x4
    800043c4:	2d850513          	addi	a0,a0,728 # 80008698 <syscalls+0x1c8>
    800043c8:	ffffc097          	auipc	ra,0xffffc
    800043cc:	176080e7          	jalr	374(ra) # 8000053e <panic>
    panic("dirlink");
    800043d0:	00004517          	auipc	a0,0x4
    800043d4:	3d850513          	addi	a0,a0,984 # 800087a8 <syscalls+0x2d8>
    800043d8:	ffffc097          	auipc	ra,0xffffc
    800043dc:	166080e7          	jalr	358(ra) # 8000053e <panic>

00000000800043e0 <namei>:

struct inode*
namei(char *path)
{
    800043e0:	1101                	addi	sp,sp,-32
    800043e2:	ec06                	sd	ra,24(sp)
    800043e4:	e822                	sd	s0,16(sp)
    800043e6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043e8:	fe040613          	addi	a2,s0,-32
    800043ec:	4581                	li	a1,0
    800043ee:	00000097          	auipc	ra,0x0
    800043f2:	dd0080e7          	jalr	-560(ra) # 800041be <namex>
}
    800043f6:	60e2                	ld	ra,24(sp)
    800043f8:	6442                	ld	s0,16(sp)
    800043fa:	6105                	addi	sp,sp,32
    800043fc:	8082                	ret

00000000800043fe <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043fe:	1141                	addi	sp,sp,-16
    80004400:	e406                	sd	ra,8(sp)
    80004402:	e022                	sd	s0,0(sp)
    80004404:	0800                	addi	s0,sp,16
    80004406:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004408:	4585                	li	a1,1
    8000440a:	00000097          	auipc	ra,0x0
    8000440e:	db4080e7          	jalr	-588(ra) # 800041be <namex>
}
    80004412:	60a2                	ld	ra,8(sp)
    80004414:	6402                	ld	s0,0(sp)
    80004416:	0141                	addi	sp,sp,16
    80004418:	8082                	ret

000000008000441a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000441a:	1101                	addi	sp,sp,-32
    8000441c:	ec06                	sd	ra,24(sp)
    8000441e:	e822                	sd	s0,16(sp)
    80004420:	e426                	sd	s1,8(sp)
    80004422:	e04a                	sd	s2,0(sp)
    80004424:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004426:	0001e917          	auipc	s2,0x1e
    8000442a:	98a90913          	addi	s2,s2,-1654 # 80021db0 <log>
    8000442e:	01892583          	lw	a1,24(s2)
    80004432:	02892503          	lw	a0,40(s2)
    80004436:	fffff097          	auipc	ra,0xfffff
    8000443a:	ff2080e7          	jalr	-14(ra) # 80003428 <bread>
    8000443e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004440:	02c92683          	lw	a3,44(s2)
    80004444:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004446:	02d05763          	blez	a3,80004474 <write_head+0x5a>
    8000444a:	0001e797          	auipc	a5,0x1e
    8000444e:	99678793          	addi	a5,a5,-1642 # 80021de0 <log+0x30>
    80004452:	05c50713          	addi	a4,a0,92
    80004456:	36fd                	addiw	a3,a3,-1
    80004458:	1682                	slli	a3,a3,0x20
    8000445a:	9281                	srli	a3,a3,0x20
    8000445c:	068a                	slli	a3,a3,0x2
    8000445e:	0001e617          	auipc	a2,0x1e
    80004462:	98660613          	addi	a2,a2,-1658 # 80021de4 <log+0x34>
    80004466:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004468:	4390                	lw	a2,0(a5)
    8000446a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000446c:	0791                	addi	a5,a5,4
    8000446e:	0711                	addi	a4,a4,4
    80004470:	fed79ce3          	bne	a5,a3,80004468 <write_head+0x4e>
  }
  bwrite(buf);
    80004474:	8526                	mv	a0,s1
    80004476:	fffff097          	auipc	ra,0xfffff
    8000447a:	0a4080e7          	jalr	164(ra) # 8000351a <bwrite>
  brelse(buf);
    8000447e:	8526                	mv	a0,s1
    80004480:	fffff097          	auipc	ra,0xfffff
    80004484:	0d8080e7          	jalr	216(ra) # 80003558 <brelse>
}
    80004488:	60e2                	ld	ra,24(sp)
    8000448a:	6442                	ld	s0,16(sp)
    8000448c:	64a2                	ld	s1,8(sp)
    8000448e:	6902                	ld	s2,0(sp)
    80004490:	6105                	addi	sp,sp,32
    80004492:	8082                	ret

0000000080004494 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004494:	0001e797          	auipc	a5,0x1e
    80004498:	9487a783          	lw	a5,-1720(a5) # 80021ddc <log+0x2c>
    8000449c:	0af05d63          	blez	a5,80004556 <install_trans+0xc2>
{
    800044a0:	7139                	addi	sp,sp,-64
    800044a2:	fc06                	sd	ra,56(sp)
    800044a4:	f822                	sd	s0,48(sp)
    800044a6:	f426                	sd	s1,40(sp)
    800044a8:	f04a                	sd	s2,32(sp)
    800044aa:	ec4e                	sd	s3,24(sp)
    800044ac:	e852                	sd	s4,16(sp)
    800044ae:	e456                	sd	s5,8(sp)
    800044b0:	e05a                	sd	s6,0(sp)
    800044b2:	0080                	addi	s0,sp,64
    800044b4:	8b2a                	mv	s6,a0
    800044b6:	0001ea97          	auipc	s5,0x1e
    800044ba:	92aa8a93          	addi	s5,s5,-1750 # 80021de0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044be:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044c0:	0001e997          	auipc	s3,0x1e
    800044c4:	8f098993          	addi	s3,s3,-1808 # 80021db0 <log>
    800044c8:	a035                	j	800044f4 <install_trans+0x60>
      bunpin(dbuf);
    800044ca:	8526                	mv	a0,s1
    800044cc:	fffff097          	auipc	ra,0xfffff
    800044d0:	166080e7          	jalr	358(ra) # 80003632 <bunpin>
    brelse(lbuf);
    800044d4:	854a                	mv	a0,s2
    800044d6:	fffff097          	auipc	ra,0xfffff
    800044da:	082080e7          	jalr	130(ra) # 80003558 <brelse>
    brelse(dbuf);
    800044de:	8526                	mv	a0,s1
    800044e0:	fffff097          	auipc	ra,0xfffff
    800044e4:	078080e7          	jalr	120(ra) # 80003558 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044e8:	2a05                	addiw	s4,s4,1
    800044ea:	0a91                	addi	s5,s5,4
    800044ec:	02c9a783          	lw	a5,44(s3)
    800044f0:	04fa5963          	bge	s4,a5,80004542 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044f4:	0189a583          	lw	a1,24(s3)
    800044f8:	014585bb          	addw	a1,a1,s4
    800044fc:	2585                	addiw	a1,a1,1
    800044fe:	0289a503          	lw	a0,40(s3)
    80004502:	fffff097          	auipc	ra,0xfffff
    80004506:	f26080e7          	jalr	-218(ra) # 80003428 <bread>
    8000450a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000450c:	000aa583          	lw	a1,0(s5)
    80004510:	0289a503          	lw	a0,40(s3)
    80004514:	fffff097          	auipc	ra,0xfffff
    80004518:	f14080e7          	jalr	-236(ra) # 80003428 <bread>
    8000451c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000451e:	40000613          	li	a2,1024
    80004522:	05890593          	addi	a1,s2,88
    80004526:	05850513          	addi	a0,a0,88
    8000452a:	ffffd097          	auipc	ra,0xffffd
    8000452e:	816080e7          	jalr	-2026(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004532:	8526                	mv	a0,s1
    80004534:	fffff097          	auipc	ra,0xfffff
    80004538:	fe6080e7          	jalr	-26(ra) # 8000351a <bwrite>
    if(recovering == 0)
    8000453c:	f80b1ce3          	bnez	s6,800044d4 <install_trans+0x40>
    80004540:	b769                	j	800044ca <install_trans+0x36>
}
    80004542:	70e2                	ld	ra,56(sp)
    80004544:	7442                	ld	s0,48(sp)
    80004546:	74a2                	ld	s1,40(sp)
    80004548:	7902                	ld	s2,32(sp)
    8000454a:	69e2                	ld	s3,24(sp)
    8000454c:	6a42                	ld	s4,16(sp)
    8000454e:	6aa2                	ld	s5,8(sp)
    80004550:	6b02                	ld	s6,0(sp)
    80004552:	6121                	addi	sp,sp,64
    80004554:	8082                	ret
    80004556:	8082                	ret

0000000080004558 <initlog>:
{
    80004558:	7179                	addi	sp,sp,-48
    8000455a:	f406                	sd	ra,40(sp)
    8000455c:	f022                	sd	s0,32(sp)
    8000455e:	ec26                	sd	s1,24(sp)
    80004560:	e84a                	sd	s2,16(sp)
    80004562:	e44e                	sd	s3,8(sp)
    80004564:	1800                	addi	s0,sp,48
    80004566:	892a                	mv	s2,a0
    80004568:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000456a:	0001e497          	auipc	s1,0x1e
    8000456e:	84648493          	addi	s1,s1,-1978 # 80021db0 <log>
    80004572:	00004597          	auipc	a1,0x4
    80004576:	13658593          	addi	a1,a1,310 # 800086a8 <syscalls+0x1d8>
    8000457a:	8526                	mv	a0,s1
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	5d8080e7          	jalr	1496(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004584:	0149a583          	lw	a1,20(s3)
    80004588:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000458a:	0109a783          	lw	a5,16(s3)
    8000458e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004590:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004594:	854a                	mv	a0,s2
    80004596:	fffff097          	auipc	ra,0xfffff
    8000459a:	e92080e7          	jalr	-366(ra) # 80003428 <bread>
  log.lh.n = lh->n;
    8000459e:	4d3c                	lw	a5,88(a0)
    800045a0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800045a2:	02f05563          	blez	a5,800045cc <initlog+0x74>
    800045a6:	05c50713          	addi	a4,a0,92
    800045aa:	0001e697          	auipc	a3,0x1e
    800045ae:	83668693          	addi	a3,a3,-1994 # 80021de0 <log+0x30>
    800045b2:	37fd                	addiw	a5,a5,-1
    800045b4:	1782                	slli	a5,a5,0x20
    800045b6:	9381                	srli	a5,a5,0x20
    800045b8:	078a                	slli	a5,a5,0x2
    800045ba:	06050613          	addi	a2,a0,96
    800045be:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800045c0:	4310                	lw	a2,0(a4)
    800045c2:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800045c4:	0711                	addi	a4,a4,4
    800045c6:	0691                	addi	a3,a3,4
    800045c8:	fef71ce3          	bne	a4,a5,800045c0 <initlog+0x68>
  brelse(buf);
    800045cc:	fffff097          	auipc	ra,0xfffff
    800045d0:	f8c080e7          	jalr	-116(ra) # 80003558 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800045d4:	4505                	li	a0,1
    800045d6:	00000097          	auipc	ra,0x0
    800045da:	ebe080e7          	jalr	-322(ra) # 80004494 <install_trans>
  log.lh.n = 0;
    800045de:	0001d797          	auipc	a5,0x1d
    800045e2:	7e07af23          	sw	zero,2046(a5) # 80021ddc <log+0x2c>
  write_head(); // clear the log
    800045e6:	00000097          	auipc	ra,0x0
    800045ea:	e34080e7          	jalr	-460(ra) # 8000441a <write_head>
}
    800045ee:	70a2                	ld	ra,40(sp)
    800045f0:	7402                	ld	s0,32(sp)
    800045f2:	64e2                	ld	s1,24(sp)
    800045f4:	6942                	ld	s2,16(sp)
    800045f6:	69a2                	ld	s3,8(sp)
    800045f8:	6145                	addi	sp,sp,48
    800045fa:	8082                	ret

00000000800045fc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045fc:	1101                	addi	sp,sp,-32
    800045fe:	ec06                	sd	ra,24(sp)
    80004600:	e822                	sd	s0,16(sp)
    80004602:	e426                	sd	s1,8(sp)
    80004604:	e04a                	sd	s2,0(sp)
    80004606:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004608:	0001d517          	auipc	a0,0x1d
    8000460c:	7a850513          	addi	a0,a0,1960 # 80021db0 <log>
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	5d4080e7          	jalr	1492(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004618:	0001d497          	auipc	s1,0x1d
    8000461c:	79848493          	addi	s1,s1,1944 # 80021db0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004620:	4979                	li	s2,30
    80004622:	a039                	j	80004630 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004624:	85a6                	mv	a1,s1
    80004626:	8526                	mv	a0,s1
    80004628:	ffffe097          	auipc	ra,0xffffe
    8000462c:	f1a080e7          	jalr	-230(ra) # 80002542 <sleep>
    if(log.committing){
    80004630:	50dc                	lw	a5,36(s1)
    80004632:	fbed                	bnez	a5,80004624 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004634:	509c                	lw	a5,32(s1)
    80004636:	0017871b          	addiw	a4,a5,1
    8000463a:	0007069b          	sext.w	a3,a4
    8000463e:	0027179b          	slliw	a5,a4,0x2
    80004642:	9fb9                	addw	a5,a5,a4
    80004644:	0017979b          	slliw	a5,a5,0x1
    80004648:	54d8                	lw	a4,44(s1)
    8000464a:	9fb9                	addw	a5,a5,a4
    8000464c:	00f95963          	bge	s2,a5,8000465e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004650:	85a6                	mv	a1,s1
    80004652:	8526                	mv	a0,s1
    80004654:	ffffe097          	auipc	ra,0xffffe
    80004658:	eee080e7          	jalr	-274(ra) # 80002542 <sleep>
    8000465c:	bfd1                	j	80004630 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000465e:	0001d517          	auipc	a0,0x1d
    80004662:	75250513          	addi	a0,a0,1874 # 80021db0 <log>
    80004666:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	630080e7          	jalr	1584(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004670:	60e2                	ld	ra,24(sp)
    80004672:	6442                	ld	s0,16(sp)
    80004674:	64a2                	ld	s1,8(sp)
    80004676:	6902                	ld	s2,0(sp)
    80004678:	6105                	addi	sp,sp,32
    8000467a:	8082                	ret

000000008000467c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000467c:	7139                	addi	sp,sp,-64
    8000467e:	fc06                	sd	ra,56(sp)
    80004680:	f822                	sd	s0,48(sp)
    80004682:	f426                	sd	s1,40(sp)
    80004684:	f04a                	sd	s2,32(sp)
    80004686:	ec4e                	sd	s3,24(sp)
    80004688:	e852                	sd	s4,16(sp)
    8000468a:	e456                	sd	s5,8(sp)
    8000468c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000468e:	0001d497          	auipc	s1,0x1d
    80004692:	72248493          	addi	s1,s1,1826 # 80021db0 <log>
    80004696:	8526                	mv	a0,s1
    80004698:	ffffc097          	auipc	ra,0xffffc
    8000469c:	54c080e7          	jalr	1356(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800046a0:	509c                	lw	a5,32(s1)
    800046a2:	37fd                	addiw	a5,a5,-1
    800046a4:	0007891b          	sext.w	s2,a5
    800046a8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800046aa:	50dc                	lw	a5,36(s1)
    800046ac:	efb9                	bnez	a5,8000470a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800046ae:	06091663          	bnez	s2,8000471a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800046b2:	0001d497          	auipc	s1,0x1d
    800046b6:	6fe48493          	addi	s1,s1,1790 # 80021db0 <log>
    800046ba:	4785                	li	a5,1
    800046bc:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800046be:	8526                	mv	a0,s1
    800046c0:	ffffc097          	auipc	ra,0xffffc
    800046c4:	5d8080e7          	jalr	1496(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800046c8:	54dc                	lw	a5,44(s1)
    800046ca:	06f04763          	bgtz	a5,80004738 <end_op+0xbc>
    acquire(&log.lock);
    800046ce:	0001d497          	auipc	s1,0x1d
    800046d2:	6e248493          	addi	s1,s1,1762 # 80021db0 <log>
    800046d6:	8526                	mv	a0,s1
    800046d8:	ffffc097          	auipc	ra,0xffffc
    800046dc:	50c080e7          	jalr	1292(ra) # 80000be4 <acquire>
    log.committing = 0;
    800046e0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800046e4:	8526                	mv	a0,s1
    800046e6:	ffffe097          	auipc	ra,0xffffe
    800046ea:	ffa080e7          	jalr	-6(ra) # 800026e0 <wakeup>
    release(&log.lock);
    800046ee:	8526                	mv	a0,s1
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	5a8080e7          	jalr	1448(ra) # 80000c98 <release>
}
    800046f8:	70e2                	ld	ra,56(sp)
    800046fa:	7442                	ld	s0,48(sp)
    800046fc:	74a2                	ld	s1,40(sp)
    800046fe:	7902                	ld	s2,32(sp)
    80004700:	69e2                	ld	s3,24(sp)
    80004702:	6a42                	ld	s4,16(sp)
    80004704:	6aa2                	ld	s5,8(sp)
    80004706:	6121                	addi	sp,sp,64
    80004708:	8082                	ret
    panic("log.committing");
    8000470a:	00004517          	auipc	a0,0x4
    8000470e:	fa650513          	addi	a0,a0,-90 # 800086b0 <syscalls+0x1e0>
    80004712:	ffffc097          	auipc	ra,0xffffc
    80004716:	e2c080e7          	jalr	-468(ra) # 8000053e <panic>
    wakeup(&log);
    8000471a:	0001d497          	auipc	s1,0x1d
    8000471e:	69648493          	addi	s1,s1,1686 # 80021db0 <log>
    80004722:	8526                	mv	a0,s1
    80004724:	ffffe097          	auipc	ra,0xffffe
    80004728:	fbc080e7          	jalr	-68(ra) # 800026e0 <wakeup>
  release(&log.lock);
    8000472c:	8526                	mv	a0,s1
    8000472e:	ffffc097          	auipc	ra,0xffffc
    80004732:	56a080e7          	jalr	1386(ra) # 80000c98 <release>
  if(do_commit){
    80004736:	b7c9                	j	800046f8 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004738:	0001da97          	auipc	s5,0x1d
    8000473c:	6a8a8a93          	addi	s5,s5,1704 # 80021de0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004740:	0001da17          	auipc	s4,0x1d
    80004744:	670a0a13          	addi	s4,s4,1648 # 80021db0 <log>
    80004748:	018a2583          	lw	a1,24(s4)
    8000474c:	012585bb          	addw	a1,a1,s2
    80004750:	2585                	addiw	a1,a1,1
    80004752:	028a2503          	lw	a0,40(s4)
    80004756:	fffff097          	auipc	ra,0xfffff
    8000475a:	cd2080e7          	jalr	-814(ra) # 80003428 <bread>
    8000475e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004760:	000aa583          	lw	a1,0(s5)
    80004764:	028a2503          	lw	a0,40(s4)
    80004768:	fffff097          	auipc	ra,0xfffff
    8000476c:	cc0080e7          	jalr	-832(ra) # 80003428 <bread>
    80004770:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004772:	40000613          	li	a2,1024
    80004776:	05850593          	addi	a1,a0,88
    8000477a:	05848513          	addi	a0,s1,88
    8000477e:	ffffc097          	auipc	ra,0xffffc
    80004782:	5c2080e7          	jalr	1474(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004786:	8526                	mv	a0,s1
    80004788:	fffff097          	auipc	ra,0xfffff
    8000478c:	d92080e7          	jalr	-622(ra) # 8000351a <bwrite>
    brelse(from);
    80004790:	854e                	mv	a0,s3
    80004792:	fffff097          	auipc	ra,0xfffff
    80004796:	dc6080e7          	jalr	-570(ra) # 80003558 <brelse>
    brelse(to);
    8000479a:	8526                	mv	a0,s1
    8000479c:	fffff097          	auipc	ra,0xfffff
    800047a0:	dbc080e7          	jalr	-580(ra) # 80003558 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047a4:	2905                	addiw	s2,s2,1
    800047a6:	0a91                	addi	s5,s5,4
    800047a8:	02ca2783          	lw	a5,44(s4)
    800047ac:	f8f94ee3          	blt	s2,a5,80004748 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800047b0:	00000097          	auipc	ra,0x0
    800047b4:	c6a080e7          	jalr	-918(ra) # 8000441a <write_head>
    install_trans(0); // Now install writes to home locations
    800047b8:	4501                	li	a0,0
    800047ba:	00000097          	auipc	ra,0x0
    800047be:	cda080e7          	jalr	-806(ra) # 80004494 <install_trans>
    log.lh.n = 0;
    800047c2:	0001d797          	auipc	a5,0x1d
    800047c6:	6007ad23          	sw	zero,1562(a5) # 80021ddc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800047ca:	00000097          	auipc	ra,0x0
    800047ce:	c50080e7          	jalr	-944(ra) # 8000441a <write_head>
    800047d2:	bdf5                	j	800046ce <end_op+0x52>

00000000800047d4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800047d4:	1101                	addi	sp,sp,-32
    800047d6:	ec06                	sd	ra,24(sp)
    800047d8:	e822                	sd	s0,16(sp)
    800047da:	e426                	sd	s1,8(sp)
    800047dc:	e04a                	sd	s2,0(sp)
    800047de:	1000                	addi	s0,sp,32
    800047e0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800047e2:	0001d917          	auipc	s2,0x1d
    800047e6:	5ce90913          	addi	s2,s2,1486 # 80021db0 <log>
    800047ea:	854a                	mv	a0,s2
    800047ec:	ffffc097          	auipc	ra,0xffffc
    800047f0:	3f8080e7          	jalr	1016(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800047f4:	02c92603          	lw	a2,44(s2)
    800047f8:	47f5                	li	a5,29
    800047fa:	06c7c563          	blt	a5,a2,80004864 <log_write+0x90>
    800047fe:	0001d797          	auipc	a5,0x1d
    80004802:	5ce7a783          	lw	a5,1486(a5) # 80021dcc <log+0x1c>
    80004806:	37fd                	addiw	a5,a5,-1
    80004808:	04f65e63          	bge	a2,a5,80004864 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000480c:	0001d797          	auipc	a5,0x1d
    80004810:	5c47a783          	lw	a5,1476(a5) # 80021dd0 <log+0x20>
    80004814:	06f05063          	blez	a5,80004874 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004818:	4781                	li	a5,0
    8000481a:	06c05563          	blez	a2,80004884 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000481e:	44cc                	lw	a1,12(s1)
    80004820:	0001d717          	auipc	a4,0x1d
    80004824:	5c070713          	addi	a4,a4,1472 # 80021de0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004828:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000482a:	4314                	lw	a3,0(a4)
    8000482c:	04b68c63          	beq	a3,a1,80004884 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004830:	2785                	addiw	a5,a5,1
    80004832:	0711                	addi	a4,a4,4
    80004834:	fef61be3          	bne	a2,a5,8000482a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004838:	0621                	addi	a2,a2,8
    8000483a:	060a                	slli	a2,a2,0x2
    8000483c:	0001d797          	auipc	a5,0x1d
    80004840:	57478793          	addi	a5,a5,1396 # 80021db0 <log>
    80004844:	963e                	add	a2,a2,a5
    80004846:	44dc                	lw	a5,12(s1)
    80004848:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000484a:	8526                	mv	a0,s1
    8000484c:	fffff097          	auipc	ra,0xfffff
    80004850:	daa080e7          	jalr	-598(ra) # 800035f6 <bpin>
    log.lh.n++;
    80004854:	0001d717          	auipc	a4,0x1d
    80004858:	55c70713          	addi	a4,a4,1372 # 80021db0 <log>
    8000485c:	575c                	lw	a5,44(a4)
    8000485e:	2785                	addiw	a5,a5,1
    80004860:	d75c                	sw	a5,44(a4)
    80004862:	a835                	j	8000489e <log_write+0xca>
    panic("too big a transaction");
    80004864:	00004517          	auipc	a0,0x4
    80004868:	e5c50513          	addi	a0,a0,-420 # 800086c0 <syscalls+0x1f0>
    8000486c:	ffffc097          	auipc	ra,0xffffc
    80004870:	cd2080e7          	jalr	-814(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004874:	00004517          	auipc	a0,0x4
    80004878:	e6450513          	addi	a0,a0,-412 # 800086d8 <syscalls+0x208>
    8000487c:	ffffc097          	auipc	ra,0xffffc
    80004880:	cc2080e7          	jalr	-830(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004884:	00878713          	addi	a4,a5,8
    80004888:	00271693          	slli	a3,a4,0x2
    8000488c:	0001d717          	auipc	a4,0x1d
    80004890:	52470713          	addi	a4,a4,1316 # 80021db0 <log>
    80004894:	9736                	add	a4,a4,a3
    80004896:	44d4                	lw	a3,12(s1)
    80004898:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000489a:	faf608e3          	beq	a2,a5,8000484a <log_write+0x76>
  }
  release(&log.lock);
    8000489e:	0001d517          	auipc	a0,0x1d
    800048a2:	51250513          	addi	a0,a0,1298 # 80021db0 <log>
    800048a6:	ffffc097          	auipc	ra,0xffffc
    800048aa:	3f2080e7          	jalr	1010(ra) # 80000c98 <release>
}
    800048ae:	60e2                	ld	ra,24(sp)
    800048b0:	6442                	ld	s0,16(sp)
    800048b2:	64a2                	ld	s1,8(sp)
    800048b4:	6902                	ld	s2,0(sp)
    800048b6:	6105                	addi	sp,sp,32
    800048b8:	8082                	ret

00000000800048ba <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800048ba:	1101                	addi	sp,sp,-32
    800048bc:	ec06                	sd	ra,24(sp)
    800048be:	e822                	sd	s0,16(sp)
    800048c0:	e426                	sd	s1,8(sp)
    800048c2:	e04a                	sd	s2,0(sp)
    800048c4:	1000                	addi	s0,sp,32
    800048c6:	84aa                	mv	s1,a0
    800048c8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800048ca:	00004597          	auipc	a1,0x4
    800048ce:	e2e58593          	addi	a1,a1,-466 # 800086f8 <syscalls+0x228>
    800048d2:	0521                	addi	a0,a0,8
    800048d4:	ffffc097          	auipc	ra,0xffffc
    800048d8:	280080e7          	jalr	640(ra) # 80000b54 <initlock>
  lk->name = name;
    800048dc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800048e0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048e4:	0204a423          	sw	zero,40(s1)
}
    800048e8:	60e2                	ld	ra,24(sp)
    800048ea:	6442                	ld	s0,16(sp)
    800048ec:	64a2                	ld	s1,8(sp)
    800048ee:	6902                	ld	s2,0(sp)
    800048f0:	6105                	addi	sp,sp,32
    800048f2:	8082                	ret

00000000800048f4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800048f4:	1101                	addi	sp,sp,-32
    800048f6:	ec06                	sd	ra,24(sp)
    800048f8:	e822                	sd	s0,16(sp)
    800048fa:	e426                	sd	s1,8(sp)
    800048fc:	e04a                	sd	s2,0(sp)
    800048fe:	1000                	addi	s0,sp,32
    80004900:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004902:	00850913          	addi	s2,a0,8
    80004906:	854a                	mv	a0,s2
    80004908:	ffffc097          	auipc	ra,0xffffc
    8000490c:	2dc080e7          	jalr	732(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004910:	409c                	lw	a5,0(s1)
    80004912:	cb89                	beqz	a5,80004924 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004914:	85ca                	mv	a1,s2
    80004916:	8526                	mv	a0,s1
    80004918:	ffffe097          	auipc	ra,0xffffe
    8000491c:	c2a080e7          	jalr	-982(ra) # 80002542 <sleep>
  while (lk->locked) {
    80004920:	409c                	lw	a5,0(s1)
    80004922:	fbed                	bnez	a5,80004914 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004924:	4785                	li	a5,1
    80004926:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004928:	ffffd097          	auipc	ra,0xffffd
    8000492c:	412080e7          	jalr	1042(ra) # 80001d3a <myproc>
    80004930:	591c                	lw	a5,48(a0)
    80004932:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004934:	854a                	mv	a0,s2
    80004936:	ffffc097          	auipc	ra,0xffffc
    8000493a:	362080e7          	jalr	866(ra) # 80000c98 <release>
}
    8000493e:	60e2                	ld	ra,24(sp)
    80004940:	6442                	ld	s0,16(sp)
    80004942:	64a2                	ld	s1,8(sp)
    80004944:	6902                	ld	s2,0(sp)
    80004946:	6105                	addi	sp,sp,32
    80004948:	8082                	ret

000000008000494a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000494a:	1101                	addi	sp,sp,-32
    8000494c:	ec06                	sd	ra,24(sp)
    8000494e:	e822                	sd	s0,16(sp)
    80004950:	e426                	sd	s1,8(sp)
    80004952:	e04a                	sd	s2,0(sp)
    80004954:	1000                	addi	s0,sp,32
    80004956:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004958:	00850913          	addi	s2,a0,8
    8000495c:	854a                	mv	a0,s2
    8000495e:	ffffc097          	auipc	ra,0xffffc
    80004962:	286080e7          	jalr	646(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004966:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000496a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000496e:	8526                	mv	a0,s1
    80004970:	ffffe097          	auipc	ra,0xffffe
    80004974:	d70080e7          	jalr	-656(ra) # 800026e0 <wakeup>
  release(&lk->lk);
    80004978:	854a                	mv	a0,s2
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	31e080e7          	jalr	798(ra) # 80000c98 <release>
}
    80004982:	60e2                	ld	ra,24(sp)
    80004984:	6442                	ld	s0,16(sp)
    80004986:	64a2                	ld	s1,8(sp)
    80004988:	6902                	ld	s2,0(sp)
    8000498a:	6105                	addi	sp,sp,32
    8000498c:	8082                	ret

000000008000498e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000498e:	7179                	addi	sp,sp,-48
    80004990:	f406                	sd	ra,40(sp)
    80004992:	f022                	sd	s0,32(sp)
    80004994:	ec26                	sd	s1,24(sp)
    80004996:	e84a                	sd	s2,16(sp)
    80004998:	e44e                	sd	s3,8(sp)
    8000499a:	1800                	addi	s0,sp,48
    8000499c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000499e:	00850913          	addi	s2,a0,8
    800049a2:	854a                	mv	a0,s2
    800049a4:	ffffc097          	auipc	ra,0xffffc
    800049a8:	240080e7          	jalr	576(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800049ac:	409c                	lw	a5,0(s1)
    800049ae:	ef99                	bnez	a5,800049cc <holdingsleep+0x3e>
    800049b0:	4481                	li	s1,0
  release(&lk->lk);
    800049b2:	854a                	mv	a0,s2
    800049b4:	ffffc097          	auipc	ra,0xffffc
    800049b8:	2e4080e7          	jalr	740(ra) # 80000c98 <release>
  return r;
}
    800049bc:	8526                	mv	a0,s1
    800049be:	70a2                	ld	ra,40(sp)
    800049c0:	7402                	ld	s0,32(sp)
    800049c2:	64e2                	ld	s1,24(sp)
    800049c4:	6942                	ld	s2,16(sp)
    800049c6:	69a2                	ld	s3,8(sp)
    800049c8:	6145                	addi	sp,sp,48
    800049ca:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800049cc:	0284a983          	lw	s3,40(s1)
    800049d0:	ffffd097          	auipc	ra,0xffffd
    800049d4:	36a080e7          	jalr	874(ra) # 80001d3a <myproc>
    800049d8:	5904                	lw	s1,48(a0)
    800049da:	413484b3          	sub	s1,s1,s3
    800049de:	0014b493          	seqz	s1,s1
    800049e2:	bfc1                	j	800049b2 <holdingsleep+0x24>

00000000800049e4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800049e4:	1141                	addi	sp,sp,-16
    800049e6:	e406                	sd	ra,8(sp)
    800049e8:	e022                	sd	s0,0(sp)
    800049ea:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049ec:	00004597          	auipc	a1,0x4
    800049f0:	d1c58593          	addi	a1,a1,-740 # 80008708 <syscalls+0x238>
    800049f4:	0001d517          	auipc	a0,0x1d
    800049f8:	50450513          	addi	a0,a0,1284 # 80021ef8 <ftable>
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	158080e7          	jalr	344(ra) # 80000b54 <initlock>
}
    80004a04:	60a2                	ld	ra,8(sp)
    80004a06:	6402                	ld	s0,0(sp)
    80004a08:	0141                	addi	sp,sp,16
    80004a0a:	8082                	ret

0000000080004a0c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a0c:	1101                	addi	sp,sp,-32
    80004a0e:	ec06                	sd	ra,24(sp)
    80004a10:	e822                	sd	s0,16(sp)
    80004a12:	e426                	sd	s1,8(sp)
    80004a14:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a16:	0001d517          	auipc	a0,0x1d
    80004a1a:	4e250513          	addi	a0,a0,1250 # 80021ef8 <ftable>
    80004a1e:	ffffc097          	auipc	ra,0xffffc
    80004a22:	1c6080e7          	jalr	454(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a26:	0001d497          	auipc	s1,0x1d
    80004a2a:	4ea48493          	addi	s1,s1,1258 # 80021f10 <ftable+0x18>
    80004a2e:	0001e717          	auipc	a4,0x1e
    80004a32:	48270713          	addi	a4,a4,1154 # 80022eb0 <ftable+0xfb8>
    if(f->ref == 0){
    80004a36:	40dc                	lw	a5,4(s1)
    80004a38:	cf99                	beqz	a5,80004a56 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a3a:	02848493          	addi	s1,s1,40
    80004a3e:	fee49ce3          	bne	s1,a4,80004a36 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a42:	0001d517          	auipc	a0,0x1d
    80004a46:	4b650513          	addi	a0,a0,1206 # 80021ef8 <ftable>
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
  return 0;
    80004a52:	4481                	li	s1,0
    80004a54:	a819                	j	80004a6a <filealloc+0x5e>
      f->ref = 1;
    80004a56:	4785                	li	a5,1
    80004a58:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a5a:	0001d517          	auipc	a0,0x1d
    80004a5e:	49e50513          	addi	a0,a0,1182 # 80021ef8 <ftable>
    80004a62:	ffffc097          	auipc	ra,0xffffc
    80004a66:	236080e7          	jalr	566(ra) # 80000c98 <release>
}
    80004a6a:	8526                	mv	a0,s1
    80004a6c:	60e2                	ld	ra,24(sp)
    80004a6e:	6442                	ld	s0,16(sp)
    80004a70:	64a2                	ld	s1,8(sp)
    80004a72:	6105                	addi	sp,sp,32
    80004a74:	8082                	ret

0000000080004a76 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a76:	1101                	addi	sp,sp,-32
    80004a78:	ec06                	sd	ra,24(sp)
    80004a7a:	e822                	sd	s0,16(sp)
    80004a7c:	e426                	sd	s1,8(sp)
    80004a7e:	1000                	addi	s0,sp,32
    80004a80:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a82:	0001d517          	auipc	a0,0x1d
    80004a86:	47650513          	addi	a0,a0,1142 # 80021ef8 <ftable>
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	15a080e7          	jalr	346(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a92:	40dc                	lw	a5,4(s1)
    80004a94:	02f05263          	blez	a5,80004ab8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a98:	2785                	addiw	a5,a5,1
    80004a9a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a9c:	0001d517          	auipc	a0,0x1d
    80004aa0:	45c50513          	addi	a0,a0,1116 # 80021ef8 <ftable>
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	1f4080e7          	jalr	500(ra) # 80000c98 <release>
  return f;
}
    80004aac:	8526                	mv	a0,s1
    80004aae:	60e2                	ld	ra,24(sp)
    80004ab0:	6442                	ld	s0,16(sp)
    80004ab2:	64a2                	ld	s1,8(sp)
    80004ab4:	6105                	addi	sp,sp,32
    80004ab6:	8082                	ret
    panic("filedup");
    80004ab8:	00004517          	auipc	a0,0x4
    80004abc:	c5850513          	addi	a0,a0,-936 # 80008710 <syscalls+0x240>
    80004ac0:	ffffc097          	auipc	ra,0xffffc
    80004ac4:	a7e080e7          	jalr	-1410(ra) # 8000053e <panic>

0000000080004ac8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ac8:	7139                	addi	sp,sp,-64
    80004aca:	fc06                	sd	ra,56(sp)
    80004acc:	f822                	sd	s0,48(sp)
    80004ace:	f426                	sd	s1,40(sp)
    80004ad0:	f04a                	sd	s2,32(sp)
    80004ad2:	ec4e                	sd	s3,24(sp)
    80004ad4:	e852                	sd	s4,16(sp)
    80004ad6:	e456                	sd	s5,8(sp)
    80004ad8:	0080                	addi	s0,sp,64
    80004ada:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004adc:	0001d517          	auipc	a0,0x1d
    80004ae0:	41c50513          	addi	a0,a0,1052 # 80021ef8 <ftable>
    80004ae4:	ffffc097          	auipc	ra,0xffffc
    80004ae8:	100080e7          	jalr	256(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004aec:	40dc                	lw	a5,4(s1)
    80004aee:	06f05163          	blez	a5,80004b50 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004af2:	37fd                	addiw	a5,a5,-1
    80004af4:	0007871b          	sext.w	a4,a5
    80004af8:	c0dc                	sw	a5,4(s1)
    80004afa:	06e04363          	bgtz	a4,80004b60 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004afe:	0004a903          	lw	s2,0(s1)
    80004b02:	0094ca83          	lbu	s5,9(s1)
    80004b06:	0104ba03          	ld	s4,16(s1)
    80004b0a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b0e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b12:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b16:	0001d517          	auipc	a0,0x1d
    80004b1a:	3e250513          	addi	a0,a0,994 # 80021ef8 <ftable>
    80004b1e:	ffffc097          	auipc	ra,0xffffc
    80004b22:	17a080e7          	jalr	378(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004b26:	4785                	li	a5,1
    80004b28:	04f90d63          	beq	s2,a5,80004b82 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b2c:	3979                	addiw	s2,s2,-2
    80004b2e:	4785                	li	a5,1
    80004b30:	0527e063          	bltu	a5,s2,80004b70 <fileclose+0xa8>
    begin_op();
    80004b34:	00000097          	auipc	ra,0x0
    80004b38:	ac8080e7          	jalr	-1336(ra) # 800045fc <begin_op>
    iput(ff.ip);
    80004b3c:	854e                	mv	a0,s3
    80004b3e:	fffff097          	auipc	ra,0xfffff
    80004b42:	2a6080e7          	jalr	678(ra) # 80003de4 <iput>
    end_op();
    80004b46:	00000097          	auipc	ra,0x0
    80004b4a:	b36080e7          	jalr	-1226(ra) # 8000467c <end_op>
    80004b4e:	a00d                	j	80004b70 <fileclose+0xa8>
    panic("fileclose");
    80004b50:	00004517          	auipc	a0,0x4
    80004b54:	bc850513          	addi	a0,a0,-1080 # 80008718 <syscalls+0x248>
    80004b58:	ffffc097          	auipc	ra,0xffffc
    80004b5c:	9e6080e7          	jalr	-1562(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004b60:	0001d517          	auipc	a0,0x1d
    80004b64:	39850513          	addi	a0,a0,920 # 80021ef8 <ftable>
    80004b68:	ffffc097          	auipc	ra,0xffffc
    80004b6c:	130080e7          	jalr	304(ra) # 80000c98 <release>
  }
}
    80004b70:	70e2                	ld	ra,56(sp)
    80004b72:	7442                	ld	s0,48(sp)
    80004b74:	74a2                	ld	s1,40(sp)
    80004b76:	7902                	ld	s2,32(sp)
    80004b78:	69e2                	ld	s3,24(sp)
    80004b7a:	6a42                	ld	s4,16(sp)
    80004b7c:	6aa2                	ld	s5,8(sp)
    80004b7e:	6121                	addi	sp,sp,64
    80004b80:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b82:	85d6                	mv	a1,s5
    80004b84:	8552                	mv	a0,s4
    80004b86:	00000097          	auipc	ra,0x0
    80004b8a:	34c080e7          	jalr	844(ra) # 80004ed2 <pipeclose>
    80004b8e:	b7cd                	j	80004b70 <fileclose+0xa8>

0000000080004b90 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b90:	715d                	addi	sp,sp,-80
    80004b92:	e486                	sd	ra,72(sp)
    80004b94:	e0a2                	sd	s0,64(sp)
    80004b96:	fc26                	sd	s1,56(sp)
    80004b98:	f84a                	sd	s2,48(sp)
    80004b9a:	f44e                	sd	s3,40(sp)
    80004b9c:	0880                	addi	s0,sp,80
    80004b9e:	84aa                	mv	s1,a0
    80004ba0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ba2:	ffffd097          	auipc	ra,0xffffd
    80004ba6:	198080e7          	jalr	408(ra) # 80001d3a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004baa:	409c                	lw	a5,0(s1)
    80004bac:	37f9                	addiw	a5,a5,-2
    80004bae:	4705                	li	a4,1
    80004bb0:	04f76763          	bltu	a4,a5,80004bfe <filestat+0x6e>
    80004bb4:	892a                	mv	s2,a0
    ilock(f->ip);
    80004bb6:	6c88                	ld	a0,24(s1)
    80004bb8:	fffff097          	auipc	ra,0xfffff
    80004bbc:	072080e7          	jalr	114(ra) # 80003c2a <ilock>
    stati(f->ip, &st);
    80004bc0:	fb840593          	addi	a1,s0,-72
    80004bc4:	6c88                	ld	a0,24(s1)
    80004bc6:	fffff097          	auipc	ra,0xfffff
    80004bca:	2ee080e7          	jalr	750(ra) # 80003eb4 <stati>
    iunlock(f->ip);
    80004bce:	6c88                	ld	a0,24(s1)
    80004bd0:	fffff097          	auipc	ra,0xfffff
    80004bd4:	11c080e7          	jalr	284(ra) # 80003cec <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004bd8:	46e1                	li	a3,24
    80004bda:	fb840613          	addi	a2,s0,-72
    80004bde:	85ce                	mv	a1,s3
    80004be0:	05093503          	ld	a0,80(s2)
    80004be4:	ffffd097          	auipc	ra,0xffffd
    80004be8:	a8e080e7          	jalr	-1394(ra) # 80001672 <copyout>
    80004bec:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004bf0:	60a6                	ld	ra,72(sp)
    80004bf2:	6406                	ld	s0,64(sp)
    80004bf4:	74e2                	ld	s1,56(sp)
    80004bf6:	7942                	ld	s2,48(sp)
    80004bf8:	79a2                	ld	s3,40(sp)
    80004bfa:	6161                	addi	sp,sp,80
    80004bfc:	8082                	ret
  return -1;
    80004bfe:	557d                	li	a0,-1
    80004c00:	bfc5                	j	80004bf0 <filestat+0x60>

0000000080004c02 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c02:	7179                	addi	sp,sp,-48
    80004c04:	f406                	sd	ra,40(sp)
    80004c06:	f022                	sd	s0,32(sp)
    80004c08:	ec26                	sd	s1,24(sp)
    80004c0a:	e84a                	sd	s2,16(sp)
    80004c0c:	e44e                	sd	s3,8(sp)
    80004c0e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c10:	00854783          	lbu	a5,8(a0)
    80004c14:	c3d5                	beqz	a5,80004cb8 <fileread+0xb6>
    80004c16:	84aa                	mv	s1,a0
    80004c18:	89ae                	mv	s3,a1
    80004c1a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c1c:	411c                	lw	a5,0(a0)
    80004c1e:	4705                	li	a4,1
    80004c20:	04e78963          	beq	a5,a4,80004c72 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c24:	470d                	li	a4,3
    80004c26:	04e78d63          	beq	a5,a4,80004c80 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c2a:	4709                	li	a4,2
    80004c2c:	06e79e63          	bne	a5,a4,80004ca8 <fileread+0xa6>
    ilock(f->ip);
    80004c30:	6d08                	ld	a0,24(a0)
    80004c32:	fffff097          	auipc	ra,0xfffff
    80004c36:	ff8080e7          	jalr	-8(ra) # 80003c2a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c3a:	874a                	mv	a4,s2
    80004c3c:	5094                	lw	a3,32(s1)
    80004c3e:	864e                	mv	a2,s3
    80004c40:	4585                	li	a1,1
    80004c42:	6c88                	ld	a0,24(s1)
    80004c44:	fffff097          	auipc	ra,0xfffff
    80004c48:	29a080e7          	jalr	666(ra) # 80003ede <readi>
    80004c4c:	892a                	mv	s2,a0
    80004c4e:	00a05563          	blez	a0,80004c58 <fileread+0x56>
      f->off += r;
    80004c52:	509c                	lw	a5,32(s1)
    80004c54:	9fa9                	addw	a5,a5,a0
    80004c56:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c58:	6c88                	ld	a0,24(s1)
    80004c5a:	fffff097          	auipc	ra,0xfffff
    80004c5e:	092080e7          	jalr	146(ra) # 80003cec <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c62:	854a                	mv	a0,s2
    80004c64:	70a2                	ld	ra,40(sp)
    80004c66:	7402                	ld	s0,32(sp)
    80004c68:	64e2                	ld	s1,24(sp)
    80004c6a:	6942                	ld	s2,16(sp)
    80004c6c:	69a2                	ld	s3,8(sp)
    80004c6e:	6145                	addi	sp,sp,48
    80004c70:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c72:	6908                	ld	a0,16(a0)
    80004c74:	00000097          	auipc	ra,0x0
    80004c78:	3c8080e7          	jalr	968(ra) # 8000503c <piperead>
    80004c7c:	892a                	mv	s2,a0
    80004c7e:	b7d5                	j	80004c62 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c80:	02451783          	lh	a5,36(a0)
    80004c84:	03079693          	slli	a3,a5,0x30
    80004c88:	92c1                	srli	a3,a3,0x30
    80004c8a:	4725                	li	a4,9
    80004c8c:	02d76863          	bltu	a4,a3,80004cbc <fileread+0xba>
    80004c90:	0792                	slli	a5,a5,0x4
    80004c92:	0001d717          	auipc	a4,0x1d
    80004c96:	1c670713          	addi	a4,a4,454 # 80021e58 <devsw>
    80004c9a:	97ba                	add	a5,a5,a4
    80004c9c:	639c                	ld	a5,0(a5)
    80004c9e:	c38d                	beqz	a5,80004cc0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ca0:	4505                	li	a0,1
    80004ca2:	9782                	jalr	a5
    80004ca4:	892a                	mv	s2,a0
    80004ca6:	bf75                	j	80004c62 <fileread+0x60>
    panic("fileread");
    80004ca8:	00004517          	auipc	a0,0x4
    80004cac:	a8050513          	addi	a0,a0,-1408 # 80008728 <syscalls+0x258>
    80004cb0:	ffffc097          	auipc	ra,0xffffc
    80004cb4:	88e080e7          	jalr	-1906(ra) # 8000053e <panic>
    return -1;
    80004cb8:	597d                	li	s2,-1
    80004cba:	b765                	j	80004c62 <fileread+0x60>
      return -1;
    80004cbc:	597d                	li	s2,-1
    80004cbe:	b755                	j	80004c62 <fileread+0x60>
    80004cc0:	597d                	li	s2,-1
    80004cc2:	b745                	j	80004c62 <fileread+0x60>

0000000080004cc4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004cc4:	715d                	addi	sp,sp,-80
    80004cc6:	e486                	sd	ra,72(sp)
    80004cc8:	e0a2                	sd	s0,64(sp)
    80004cca:	fc26                	sd	s1,56(sp)
    80004ccc:	f84a                	sd	s2,48(sp)
    80004cce:	f44e                	sd	s3,40(sp)
    80004cd0:	f052                	sd	s4,32(sp)
    80004cd2:	ec56                	sd	s5,24(sp)
    80004cd4:	e85a                	sd	s6,16(sp)
    80004cd6:	e45e                	sd	s7,8(sp)
    80004cd8:	e062                	sd	s8,0(sp)
    80004cda:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004cdc:	00954783          	lbu	a5,9(a0)
    80004ce0:	10078663          	beqz	a5,80004dec <filewrite+0x128>
    80004ce4:	892a                	mv	s2,a0
    80004ce6:	8aae                	mv	s5,a1
    80004ce8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cea:	411c                	lw	a5,0(a0)
    80004cec:	4705                	li	a4,1
    80004cee:	02e78263          	beq	a5,a4,80004d12 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cf2:	470d                	li	a4,3
    80004cf4:	02e78663          	beq	a5,a4,80004d20 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cf8:	4709                	li	a4,2
    80004cfa:	0ee79163          	bne	a5,a4,80004ddc <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004cfe:	0ac05d63          	blez	a2,80004db8 <filewrite+0xf4>
    int i = 0;
    80004d02:	4981                	li	s3,0
    80004d04:	6b05                	lui	s6,0x1
    80004d06:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004d0a:	6b85                	lui	s7,0x1
    80004d0c:	c00b8b9b          	addiw	s7,s7,-1024
    80004d10:	a861                	j	80004da8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d12:	6908                	ld	a0,16(a0)
    80004d14:	00000097          	auipc	ra,0x0
    80004d18:	22e080e7          	jalr	558(ra) # 80004f42 <pipewrite>
    80004d1c:	8a2a                	mv	s4,a0
    80004d1e:	a045                	j	80004dbe <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d20:	02451783          	lh	a5,36(a0)
    80004d24:	03079693          	slli	a3,a5,0x30
    80004d28:	92c1                	srli	a3,a3,0x30
    80004d2a:	4725                	li	a4,9
    80004d2c:	0cd76263          	bltu	a4,a3,80004df0 <filewrite+0x12c>
    80004d30:	0792                	slli	a5,a5,0x4
    80004d32:	0001d717          	auipc	a4,0x1d
    80004d36:	12670713          	addi	a4,a4,294 # 80021e58 <devsw>
    80004d3a:	97ba                	add	a5,a5,a4
    80004d3c:	679c                	ld	a5,8(a5)
    80004d3e:	cbdd                	beqz	a5,80004df4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d40:	4505                	li	a0,1
    80004d42:	9782                	jalr	a5
    80004d44:	8a2a                	mv	s4,a0
    80004d46:	a8a5                	j	80004dbe <filewrite+0xfa>
    80004d48:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d4c:	00000097          	auipc	ra,0x0
    80004d50:	8b0080e7          	jalr	-1872(ra) # 800045fc <begin_op>
      ilock(f->ip);
    80004d54:	01893503          	ld	a0,24(s2)
    80004d58:	fffff097          	auipc	ra,0xfffff
    80004d5c:	ed2080e7          	jalr	-302(ra) # 80003c2a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d60:	8762                	mv	a4,s8
    80004d62:	02092683          	lw	a3,32(s2)
    80004d66:	01598633          	add	a2,s3,s5
    80004d6a:	4585                	li	a1,1
    80004d6c:	01893503          	ld	a0,24(s2)
    80004d70:	fffff097          	auipc	ra,0xfffff
    80004d74:	266080e7          	jalr	614(ra) # 80003fd6 <writei>
    80004d78:	84aa                	mv	s1,a0
    80004d7a:	00a05763          	blez	a0,80004d88 <filewrite+0xc4>
        f->off += r;
    80004d7e:	02092783          	lw	a5,32(s2)
    80004d82:	9fa9                	addw	a5,a5,a0
    80004d84:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d88:	01893503          	ld	a0,24(s2)
    80004d8c:	fffff097          	auipc	ra,0xfffff
    80004d90:	f60080e7          	jalr	-160(ra) # 80003cec <iunlock>
      end_op();
    80004d94:	00000097          	auipc	ra,0x0
    80004d98:	8e8080e7          	jalr	-1816(ra) # 8000467c <end_op>

      if(r != n1){
    80004d9c:	009c1f63          	bne	s8,s1,80004dba <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004da0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004da4:	0149db63          	bge	s3,s4,80004dba <filewrite+0xf6>
      int n1 = n - i;
    80004da8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004dac:	84be                	mv	s1,a5
    80004dae:	2781                	sext.w	a5,a5
    80004db0:	f8fb5ce3          	bge	s6,a5,80004d48 <filewrite+0x84>
    80004db4:	84de                	mv	s1,s7
    80004db6:	bf49                	j	80004d48 <filewrite+0x84>
    int i = 0;
    80004db8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004dba:	013a1f63          	bne	s4,s3,80004dd8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004dbe:	8552                	mv	a0,s4
    80004dc0:	60a6                	ld	ra,72(sp)
    80004dc2:	6406                	ld	s0,64(sp)
    80004dc4:	74e2                	ld	s1,56(sp)
    80004dc6:	7942                	ld	s2,48(sp)
    80004dc8:	79a2                	ld	s3,40(sp)
    80004dca:	7a02                	ld	s4,32(sp)
    80004dcc:	6ae2                	ld	s5,24(sp)
    80004dce:	6b42                	ld	s6,16(sp)
    80004dd0:	6ba2                	ld	s7,8(sp)
    80004dd2:	6c02                	ld	s8,0(sp)
    80004dd4:	6161                	addi	sp,sp,80
    80004dd6:	8082                	ret
    ret = (i == n ? n : -1);
    80004dd8:	5a7d                	li	s4,-1
    80004dda:	b7d5                	j	80004dbe <filewrite+0xfa>
    panic("filewrite");
    80004ddc:	00004517          	auipc	a0,0x4
    80004de0:	95c50513          	addi	a0,a0,-1700 # 80008738 <syscalls+0x268>
    80004de4:	ffffb097          	auipc	ra,0xffffb
    80004de8:	75a080e7          	jalr	1882(ra) # 8000053e <panic>
    return -1;
    80004dec:	5a7d                	li	s4,-1
    80004dee:	bfc1                	j	80004dbe <filewrite+0xfa>
      return -1;
    80004df0:	5a7d                	li	s4,-1
    80004df2:	b7f1                	j	80004dbe <filewrite+0xfa>
    80004df4:	5a7d                	li	s4,-1
    80004df6:	b7e1                	j	80004dbe <filewrite+0xfa>

0000000080004df8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004df8:	7179                	addi	sp,sp,-48
    80004dfa:	f406                	sd	ra,40(sp)
    80004dfc:	f022                	sd	s0,32(sp)
    80004dfe:	ec26                	sd	s1,24(sp)
    80004e00:	e84a                	sd	s2,16(sp)
    80004e02:	e44e                	sd	s3,8(sp)
    80004e04:	e052                	sd	s4,0(sp)
    80004e06:	1800                	addi	s0,sp,48
    80004e08:	84aa                	mv	s1,a0
    80004e0a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e0c:	0005b023          	sd	zero,0(a1)
    80004e10:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e14:	00000097          	auipc	ra,0x0
    80004e18:	bf8080e7          	jalr	-1032(ra) # 80004a0c <filealloc>
    80004e1c:	e088                	sd	a0,0(s1)
    80004e1e:	c551                	beqz	a0,80004eaa <pipealloc+0xb2>
    80004e20:	00000097          	auipc	ra,0x0
    80004e24:	bec080e7          	jalr	-1044(ra) # 80004a0c <filealloc>
    80004e28:	00aa3023          	sd	a0,0(s4)
    80004e2c:	c92d                	beqz	a0,80004e9e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e2e:	ffffc097          	auipc	ra,0xffffc
    80004e32:	cc6080e7          	jalr	-826(ra) # 80000af4 <kalloc>
    80004e36:	892a                	mv	s2,a0
    80004e38:	c125                	beqz	a0,80004e98 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e3a:	4985                	li	s3,1
    80004e3c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e40:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e44:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e48:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e4c:	00004597          	auipc	a1,0x4
    80004e50:	8fc58593          	addi	a1,a1,-1796 # 80008748 <syscalls+0x278>
    80004e54:	ffffc097          	auipc	ra,0xffffc
    80004e58:	d00080e7          	jalr	-768(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004e5c:	609c                	ld	a5,0(s1)
    80004e5e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e62:	609c                	ld	a5,0(s1)
    80004e64:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e68:	609c                	ld	a5,0(s1)
    80004e6a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e6e:	609c                	ld	a5,0(s1)
    80004e70:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e74:	000a3783          	ld	a5,0(s4)
    80004e78:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e7c:	000a3783          	ld	a5,0(s4)
    80004e80:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e84:	000a3783          	ld	a5,0(s4)
    80004e88:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e8c:	000a3783          	ld	a5,0(s4)
    80004e90:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e94:	4501                	li	a0,0
    80004e96:	a025                	j	80004ebe <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e98:	6088                	ld	a0,0(s1)
    80004e9a:	e501                	bnez	a0,80004ea2 <pipealloc+0xaa>
    80004e9c:	a039                	j	80004eaa <pipealloc+0xb2>
    80004e9e:	6088                	ld	a0,0(s1)
    80004ea0:	c51d                	beqz	a0,80004ece <pipealloc+0xd6>
    fileclose(*f0);
    80004ea2:	00000097          	auipc	ra,0x0
    80004ea6:	c26080e7          	jalr	-986(ra) # 80004ac8 <fileclose>
  if(*f1)
    80004eaa:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004eae:	557d                	li	a0,-1
  if(*f1)
    80004eb0:	c799                	beqz	a5,80004ebe <pipealloc+0xc6>
    fileclose(*f1);
    80004eb2:	853e                	mv	a0,a5
    80004eb4:	00000097          	auipc	ra,0x0
    80004eb8:	c14080e7          	jalr	-1004(ra) # 80004ac8 <fileclose>
  return -1;
    80004ebc:	557d                	li	a0,-1
}
    80004ebe:	70a2                	ld	ra,40(sp)
    80004ec0:	7402                	ld	s0,32(sp)
    80004ec2:	64e2                	ld	s1,24(sp)
    80004ec4:	6942                	ld	s2,16(sp)
    80004ec6:	69a2                	ld	s3,8(sp)
    80004ec8:	6a02                	ld	s4,0(sp)
    80004eca:	6145                	addi	sp,sp,48
    80004ecc:	8082                	ret
  return -1;
    80004ece:	557d                	li	a0,-1
    80004ed0:	b7fd                	j	80004ebe <pipealloc+0xc6>

0000000080004ed2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ed2:	1101                	addi	sp,sp,-32
    80004ed4:	ec06                	sd	ra,24(sp)
    80004ed6:	e822                	sd	s0,16(sp)
    80004ed8:	e426                	sd	s1,8(sp)
    80004eda:	e04a                	sd	s2,0(sp)
    80004edc:	1000                	addi	s0,sp,32
    80004ede:	84aa                	mv	s1,a0
    80004ee0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ee2:	ffffc097          	auipc	ra,0xffffc
    80004ee6:	d02080e7          	jalr	-766(ra) # 80000be4 <acquire>
  if(writable){
    80004eea:	02090d63          	beqz	s2,80004f24 <pipeclose+0x52>
    pi->writeopen = 0;
    80004eee:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ef2:	21848513          	addi	a0,s1,536
    80004ef6:	ffffd097          	auipc	ra,0xffffd
    80004efa:	7ea080e7          	jalr	2026(ra) # 800026e0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004efe:	2204b783          	ld	a5,544(s1)
    80004f02:	eb95                	bnez	a5,80004f36 <pipeclose+0x64>
    release(&pi->lock);
    80004f04:	8526                	mv	a0,s1
    80004f06:	ffffc097          	auipc	ra,0xffffc
    80004f0a:	d92080e7          	jalr	-622(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004f0e:	8526                	mv	a0,s1
    80004f10:	ffffc097          	auipc	ra,0xffffc
    80004f14:	ae8080e7          	jalr	-1304(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004f18:	60e2                	ld	ra,24(sp)
    80004f1a:	6442                	ld	s0,16(sp)
    80004f1c:	64a2                	ld	s1,8(sp)
    80004f1e:	6902                	ld	s2,0(sp)
    80004f20:	6105                	addi	sp,sp,32
    80004f22:	8082                	ret
    pi->readopen = 0;
    80004f24:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f28:	21c48513          	addi	a0,s1,540
    80004f2c:	ffffd097          	auipc	ra,0xffffd
    80004f30:	7b4080e7          	jalr	1972(ra) # 800026e0 <wakeup>
    80004f34:	b7e9                	j	80004efe <pipeclose+0x2c>
    release(&pi->lock);
    80004f36:	8526                	mv	a0,s1
    80004f38:	ffffc097          	auipc	ra,0xffffc
    80004f3c:	d60080e7          	jalr	-672(ra) # 80000c98 <release>
}
    80004f40:	bfe1                	j	80004f18 <pipeclose+0x46>

0000000080004f42 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f42:	7159                	addi	sp,sp,-112
    80004f44:	f486                	sd	ra,104(sp)
    80004f46:	f0a2                	sd	s0,96(sp)
    80004f48:	eca6                	sd	s1,88(sp)
    80004f4a:	e8ca                	sd	s2,80(sp)
    80004f4c:	e4ce                	sd	s3,72(sp)
    80004f4e:	e0d2                	sd	s4,64(sp)
    80004f50:	fc56                	sd	s5,56(sp)
    80004f52:	f85a                	sd	s6,48(sp)
    80004f54:	f45e                	sd	s7,40(sp)
    80004f56:	f062                	sd	s8,32(sp)
    80004f58:	ec66                	sd	s9,24(sp)
    80004f5a:	1880                	addi	s0,sp,112
    80004f5c:	84aa                	mv	s1,a0
    80004f5e:	8aae                	mv	s5,a1
    80004f60:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f62:	ffffd097          	auipc	ra,0xffffd
    80004f66:	dd8080e7          	jalr	-552(ra) # 80001d3a <myproc>
    80004f6a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f6c:	8526                	mv	a0,s1
    80004f6e:	ffffc097          	auipc	ra,0xffffc
    80004f72:	c76080e7          	jalr	-906(ra) # 80000be4 <acquire>
  while(i < n){
    80004f76:	0d405163          	blez	s4,80005038 <pipewrite+0xf6>
    80004f7a:	8ba6                	mv	s7,s1
  int i = 0;
    80004f7c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f7e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f80:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f84:	21c48c13          	addi	s8,s1,540
    80004f88:	a08d                	j	80004fea <pipewrite+0xa8>
      release(&pi->lock);
    80004f8a:	8526                	mv	a0,s1
    80004f8c:	ffffc097          	auipc	ra,0xffffc
    80004f90:	d0c080e7          	jalr	-756(ra) # 80000c98 <release>
      return -1;
    80004f94:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f96:	854a                	mv	a0,s2
    80004f98:	70a6                	ld	ra,104(sp)
    80004f9a:	7406                	ld	s0,96(sp)
    80004f9c:	64e6                	ld	s1,88(sp)
    80004f9e:	6946                	ld	s2,80(sp)
    80004fa0:	69a6                	ld	s3,72(sp)
    80004fa2:	6a06                	ld	s4,64(sp)
    80004fa4:	7ae2                	ld	s5,56(sp)
    80004fa6:	7b42                	ld	s6,48(sp)
    80004fa8:	7ba2                	ld	s7,40(sp)
    80004faa:	7c02                	ld	s8,32(sp)
    80004fac:	6ce2                	ld	s9,24(sp)
    80004fae:	6165                	addi	sp,sp,112
    80004fb0:	8082                	ret
      wakeup(&pi->nread);
    80004fb2:	8566                	mv	a0,s9
    80004fb4:	ffffd097          	auipc	ra,0xffffd
    80004fb8:	72c080e7          	jalr	1836(ra) # 800026e0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004fbc:	85de                	mv	a1,s7
    80004fbe:	8562                	mv	a0,s8
    80004fc0:	ffffd097          	auipc	ra,0xffffd
    80004fc4:	582080e7          	jalr	1410(ra) # 80002542 <sleep>
    80004fc8:	a839                	j	80004fe6 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004fca:	21c4a783          	lw	a5,540(s1)
    80004fce:	0017871b          	addiw	a4,a5,1
    80004fd2:	20e4ae23          	sw	a4,540(s1)
    80004fd6:	1ff7f793          	andi	a5,a5,511
    80004fda:	97a6                	add	a5,a5,s1
    80004fdc:	f9f44703          	lbu	a4,-97(s0)
    80004fe0:	00e78c23          	sb	a4,24(a5)
      i++;
    80004fe4:	2905                	addiw	s2,s2,1
  while(i < n){
    80004fe6:	03495d63          	bge	s2,s4,80005020 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004fea:	2204a783          	lw	a5,544(s1)
    80004fee:	dfd1                	beqz	a5,80004f8a <pipewrite+0x48>
    80004ff0:	0289a783          	lw	a5,40(s3)
    80004ff4:	fbd9                	bnez	a5,80004f8a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ff6:	2184a783          	lw	a5,536(s1)
    80004ffa:	21c4a703          	lw	a4,540(s1)
    80004ffe:	2007879b          	addiw	a5,a5,512
    80005002:	faf708e3          	beq	a4,a5,80004fb2 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005006:	4685                	li	a3,1
    80005008:	01590633          	add	a2,s2,s5
    8000500c:	f9f40593          	addi	a1,s0,-97
    80005010:	0509b503          	ld	a0,80(s3)
    80005014:	ffffc097          	auipc	ra,0xffffc
    80005018:	6ea080e7          	jalr	1770(ra) # 800016fe <copyin>
    8000501c:	fb6517e3          	bne	a0,s6,80004fca <pipewrite+0x88>
  wakeup(&pi->nread);
    80005020:	21848513          	addi	a0,s1,536
    80005024:	ffffd097          	auipc	ra,0xffffd
    80005028:	6bc080e7          	jalr	1724(ra) # 800026e0 <wakeup>
  release(&pi->lock);
    8000502c:	8526                	mv	a0,s1
    8000502e:	ffffc097          	auipc	ra,0xffffc
    80005032:	c6a080e7          	jalr	-918(ra) # 80000c98 <release>
  return i;
    80005036:	b785                	j	80004f96 <pipewrite+0x54>
  int i = 0;
    80005038:	4901                	li	s2,0
    8000503a:	b7dd                	j	80005020 <pipewrite+0xde>

000000008000503c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000503c:	715d                	addi	sp,sp,-80
    8000503e:	e486                	sd	ra,72(sp)
    80005040:	e0a2                	sd	s0,64(sp)
    80005042:	fc26                	sd	s1,56(sp)
    80005044:	f84a                	sd	s2,48(sp)
    80005046:	f44e                	sd	s3,40(sp)
    80005048:	f052                	sd	s4,32(sp)
    8000504a:	ec56                	sd	s5,24(sp)
    8000504c:	e85a                	sd	s6,16(sp)
    8000504e:	0880                	addi	s0,sp,80
    80005050:	84aa                	mv	s1,a0
    80005052:	892e                	mv	s2,a1
    80005054:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005056:	ffffd097          	auipc	ra,0xffffd
    8000505a:	ce4080e7          	jalr	-796(ra) # 80001d3a <myproc>
    8000505e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005060:	8b26                	mv	s6,s1
    80005062:	8526                	mv	a0,s1
    80005064:	ffffc097          	auipc	ra,0xffffc
    80005068:	b80080e7          	jalr	-1152(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000506c:	2184a703          	lw	a4,536(s1)
    80005070:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005074:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005078:	02f71463          	bne	a4,a5,800050a0 <piperead+0x64>
    8000507c:	2244a783          	lw	a5,548(s1)
    80005080:	c385                	beqz	a5,800050a0 <piperead+0x64>
    if(pr->killed){
    80005082:	028a2783          	lw	a5,40(s4)
    80005086:	ebc1                	bnez	a5,80005116 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005088:	85da                	mv	a1,s6
    8000508a:	854e                	mv	a0,s3
    8000508c:	ffffd097          	auipc	ra,0xffffd
    80005090:	4b6080e7          	jalr	1206(ra) # 80002542 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005094:	2184a703          	lw	a4,536(s1)
    80005098:	21c4a783          	lw	a5,540(s1)
    8000509c:	fef700e3          	beq	a4,a5,8000507c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050a0:	09505263          	blez	s5,80005124 <piperead+0xe8>
    800050a4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050a6:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800050a8:	2184a783          	lw	a5,536(s1)
    800050ac:	21c4a703          	lw	a4,540(s1)
    800050b0:	02f70d63          	beq	a4,a5,800050ea <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800050b4:	0017871b          	addiw	a4,a5,1
    800050b8:	20e4ac23          	sw	a4,536(s1)
    800050bc:	1ff7f793          	andi	a5,a5,511
    800050c0:	97a6                	add	a5,a5,s1
    800050c2:	0187c783          	lbu	a5,24(a5)
    800050c6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050ca:	4685                	li	a3,1
    800050cc:	fbf40613          	addi	a2,s0,-65
    800050d0:	85ca                	mv	a1,s2
    800050d2:	050a3503          	ld	a0,80(s4)
    800050d6:	ffffc097          	auipc	ra,0xffffc
    800050da:	59c080e7          	jalr	1436(ra) # 80001672 <copyout>
    800050de:	01650663          	beq	a0,s6,800050ea <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050e2:	2985                	addiw	s3,s3,1
    800050e4:	0905                	addi	s2,s2,1
    800050e6:	fd3a91e3          	bne	s5,s3,800050a8 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050ea:	21c48513          	addi	a0,s1,540
    800050ee:	ffffd097          	auipc	ra,0xffffd
    800050f2:	5f2080e7          	jalr	1522(ra) # 800026e0 <wakeup>
  release(&pi->lock);
    800050f6:	8526                	mv	a0,s1
    800050f8:	ffffc097          	auipc	ra,0xffffc
    800050fc:	ba0080e7          	jalr	-1120(ra) # 80000c98 <release>
  return i;
}
    80005100:	854e                	mv	a0,s3
    80005102:	60a6                	ld	ra,72(sp)
    80005104:	6406                	ld	s0,64(sp)
    80005106:	74e2                	ld	s1,56(sp)
    80005108:	7942                	ld	s2,48(sp)
    8000510a:	79a2                	ld	s3,40(sp)
    8000510c:	7a02                	ld	s4,32(sp)
    8000510e:	6ae2                	ld	s5,24(sp)
    80005110:	6b42                	ld	s6,16(sp)
    80005112:	6161                	addi	sp,sp,80
    80005114:	8082                	ret
      release(&pi->lock);
    80005116:	8526                	mv	a0,s1
    80005118:	ffffc097          	auipc	ra,0xffffc
    8000511c:	b80080e7          	jalr	-1152(ra) # 80000c98 <release>
      return -1;
    80005120:	59fd                	li	s3,-1
    80005122:	bff9                	j	80005100 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005124:	4981                	li	s3,0
    80005126:	b7d1                	j	800050ea <piperead+0xae>

0000000080005128 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005128:	df010113          	addi	sp,sp,-528
    8000512c:	20113423          	sd	ra,520(sp)
    80005130:	20813023          	sd	s0,512(sp)
    80005134:	ffa6                	sd	s1,504(sp)
    80005136:	fbca                	sd	s2,496(sp)
    80005138:	f7ce                	sd	s3,488(sp)
    8000513a:	f3d2                	sd	s4,480(sp)
    8000513c:	efd6                	sd	s5,472(sp)
    8000513e:	ebda                	sd	s6,464(sp)
    80005140:	e7de                	sd	s7,456(sp)
    80005142:	e3e2                	sd	s8,448(sp)
    80005144:	ff66                	sd	s9,440(sp)
    80005146:	fb6a                	sd	s10,432(sp)
    80005148:	f76e                	sd	s11,424(sp)
    8000514a:	0c00                	addi	s0,sp,528
    8000514c:	84aa                	mv	s1,a0
    8000514e:	dea43c23          	sd	a0,-520(s0)
    80005152:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005156:	ffffd097          	auipc	ra,0xffffd
    8000515a:	be4080e7          	jalr	-1052(ra) # 80001d3a <myproc>
    8000515e:	892a                	mv	s2,a0

  begin_op();
    80005160:	fffff097          	auipc	ra,0xfffff
    80005164:	49c080e7          	jalr	1180(ra) # 800045fc <begin_op>

  if((ip = namei(path)) == 0){
    80005168:	8526                	mv	a0,s1
    8000516a:	fffff097          	auipc	ra,0xfffff
    8000516e:	276080e7          	jalr	630(ra) # 800043e0 <namei>
    80005172:	c92d                	beqz	a0,800051e4 <exec+0xbc>
    80005174:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005176:	fffff097          	auipc	ra,0xfffff
    8000517a:	ab4080e7          	jalr	-1356(ra) # 80003c2a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000517e:	04000713          	li	a4,64
    80005182:	4681                	li	a3,0
    80005184:	e5040613          	addi	a2,s0,-432
    80005188:	4581                	li	a1,0
    8000518a:	8526                	mv	a0,s1
    8000518c:	fffff097          	auipc	ra,0xfffff
    80005190:	d52080e7          	jalr	-686(ra) # 80003ede <readi>
    80005194:	04000793          	li	a5,64
    80005198:	00f51a63          	bne	a0,a5,800051ac <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000519c:	e5042703          	lw	a4,-432(s0)
    800051a0:	464c47b7          	lui	a5,0x464c4
    800051a4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800051a8:	04f70463          	beq	a4,a5,800051f0 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800051ac:	8526                	mv	a0,s1
    800051ae:	fffff097          	auipc	ra,0xfffff
    800051b2:	cde080e7          	jalr	-802(ra) # 80003e8c <iunlockput>
    end_op();
    800051b6:	fffff097          	auipc	ra,0xfffff
    800051ba:	4c6080e7          	jalr	1222(ra) # 8000467c <end_op>
  }
  return -1;
    800051be:	557d                	li	a0,-1
}
    800051c0:	20813083          	ld	ra,520(sp)
    800051c4:	20013403          	ld	s0,512(sp)
    800051c8:	74fe                	ld	s1,504(sp)
    800051ca:	795e                	ld	s2,496(sp)
    800051cc:	79be                	ld	s3,488(sp)
    800051ce:	7a1e                	ld	s4,480(sp)
    800051d0:	6afe                	ld	s5,472(sp)
    800051d2:	6b5e                	ld	s6,464(sp)
    800051d4:	6bbe                	ld	s7,456(sp)
    800051d6:	6c1e                	ld	s8,448(sp)
    800051d8:	7cfa                	ld	s9,440(sp)
    800051da:	7d5a                	ld	s10,432(sp)
    800051dc:	7dba                	ld	s11,424(sp)
    800051de:	21010113          	addi	sp,sp,528
    800051e2:	8082                	ret
    end_op();
    800051e4:	fffff097          	auipc	ra,0xfffff
    800051e8:	498080e7          	jalr	1176(ra) # 8000467c <end_op>
    return -1;
    800051ec:	557d                	li	a0,-1
    800051ee:	bfc9                	j	800051c0 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800051f0:	854a                	mv	a0,s2
    800051f2:	ffffd097          	auipc	ra,0xffffd
    800051f6:	c06080e7          	jalr	-1018(ra) # 80001df8 <proc_pagetable>
    800051fa:	8baa                	mv	s7,a0
    800051fc:	d945                	beqz	a0,800051ac <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051fe:	e7042983          	lw	s3,-400(s0)
    80005202:	e8845783          	lhu	a5,-376(s0)
    80005206:	c7ad                	beqz	a5,80005270 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005208:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000520a:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    8000520c:	6c85                	lui	s9,0x1
    8000520e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005212:	def43823          	sd	a5,-528(s0)
    80005216:	a42d                	j	80005440 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005218:	00003517          	auipc	a0,0x3
    8000521c:	53850513          	addi	a0,a0,1336 # 80008750 <syscalls+0x280>
    80005220:	ffffb097          	auipc	ra,0xffffb
    80005224:	31e080e7          	jalr	798(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005228:	8756                	mv	a4,s5
    8000522a:	012d86bb          	addw	a3,s11,s2
    8000522e:	4581                	li	a1,0
    80005230:	8526                	mv	a0,s1
    80005232:	fffff097          	auipc	ra,0xfffff
    80005236:	cac080e7          	jalr	-852(ra) # 80003ede <readi>
    8000523a:	2501                	sext.w	a0,a0
    8000523c:	1aaa9963          	bne	s5,a0,800053ee <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005240:	6785                	lui	a5,0x1
    80005242:	0127893b          	addw	s2,a5,s2
    80005246:	77fd                	lui	a5,0xfffff
    80005248:	01478a3b          	addw	s4,a5,s4
    8000524c:	1f897163          	bgeu	s2,s8,8000542e <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005250:	02091593          	slli	a1,s2,0x20
    80005254:	9181                	srli	a1,a1,0x20
    80005256:	95ea                	add	a1,a1,s10
    80005258:	855e                	mv	a0,s7
    8000525a:	ffffc097          	auipc	ra,0xffffc
    8000525e:	e14080e7          	jalr	-492(ra) # 8000106e <walkaddr>
    80005262:	862a                	mv	a2,a0
    if(pa == 0)
    80005264:	d955                	beqz	a0,80005218 <exec+0xf0>
      n = PGSIZE;
    80005266:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005268:	fd9a70e3          	bgeu	s4,s9,80005228 <exec+0x100>
      n = sz - i;
    8000526c:	8ad2                	mv	s5,s4
    8000526e:	bf6d                	j	80005228 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005270:	4901                	li	s2,0
  iunlockput(ip);
    80005272:	8526                	mv	a0,s1
    80005274:	fffff097          	auipc	ra,0xfffff
    80005278:	c18080e7          	jalr	-1000(ra) # 80003e8c <iunlockput>
  end_op();
    8000527c:	fffff097          	auipc	ra,0xfffff
    80005280:	400080e7          	jalr	1024(ra) # 8000467c <end_op>
  p = myproc();
    80005284:	ffffd097          	auipc	ra,0xffffd
    80005288:	ab6080e7          	jalr	-1354(ra) # 80001d3a <myproc>
    8000528c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000528e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005292:	6785                	lui	a5,0x1
    80005294:	17fd                	addi	a5,a5,-1
    80005296:	993e                	add	s2,s2,a5
    80005298:	757d                	lui	a0,0xfffff
    8000529a:	00a977b3          	and	a5,s2,a0
    8000529e:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800052a2:	6609                	lui	a2,0x2
    800052a4:	963e                	add	a2,a2,a5
    800052a6:	85be                	mv	a1,a5
    800052a8:	855e                	mv	a0,s7
    800052aa:	ffffc097          	auipc	ra,0xffffc
    800052ae:	178080e7          	jalr	376(ra) # 80001422 <uvmalloc>
    800052b2:	8b2a                	mv	s6,a0
  ip = 0;
    800052b4:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800052b6:	12050c63          	beqz	a0,800053ee <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052ba:	75f9                	lui	a1,0xffffe
    800052bc:	95aa                	add	a1,a1,a0
    800052be:	855e                	mv	a0,s7
    800052c0:	ffffc097          	auipc	ra,0xffffc
    800052c4:	380080e7          	jalr	896(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800052c8:	7c7d                	lui	s8,0xfffff
    800052ca:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800052cc:	e0043783          	ld	a5,-512(s0)
    800052d0:	6388                	ld	a0,0(a5)
    800052d2:	c535                	beqz	a0,8000533e <exec+0x216>
    800052d4:	e9040993          	addi	s3,s0,-368
    800052d8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800052dc:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800052de:	ffffc097          	auipc	ra,0xffffc
    800052e2:	b86080e7          	jalr	-1146(ra) # 80000e64 <strlen>
    800052e6:	2505                	addiw	a0,a0,1
    800052e8:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800052ec:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800052f0:	13896363          	bltu	s2,s8,80005416 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800052f4:	e0043d83          	ld	s11,-512(s0)
    800052f8:	000dba03          	ld	s4,0(s11)
    800052fc:	8552                	mv	a0,s4
    800052fe:	ffffc097          	auipc	ra,0xffffc
    80005302:	b66080e7          	jalr	-1178(ra) # 80000e64 <strlen>
    80005306:	0015069b          	addiw	a3,a0,1
    8000530a:	8652                	mv	a2,s4
    8000530c:	85ca                	mv	a1,s2
    8000530e:	855e                	mv	a0,s7
    80005310:	ffffc097          	auipc	ra,0xffffc
    80005314:	362080e7          	jalr	866(ra) # 80001672 <copyout>
    80005318:	10054363          	bltz	a0,8000541e <exec+0x2f6>
    ustack[argc] = sp;
    8000531c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005320:	0485                	addi	s1,s1,1
    80005322:	008d8793          	addi	a5,s11,8
    80005326:	e0f43023          	sd	a5,-512(s0)
    8000532a:	008db503          	ld	a0,8(s11)
    8000532e:	c911                	beqz	a0,80005342 <exec+0x21a>
    if(argc >= MAXARG)
    80005330:	09a1                	addi	s3,s3,8
    80005332:	fb3c96e3          	bne	s9,s3,800052de <exec+0x1b6>
  sz = sz1;
    80005336:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000533a:	4481                	li	s1,0
    8000533c:	a84d                	j	800053ee <exec+0x2c6>
  sp = sz;
    8000533e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005340:	4481                	li	s1,0
  ustack[argc] = 0;
    80005342:	00349793          	slli	a5,s1,0x3
    80005346:	f9040713          	addi	a4,s0,-112
    8000534a:	97ba                	add	a5,a5,a4
    8000534c:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005350:	00148693          	addi	a3,s1,1
    80005354:	068e                	slli	a3,a3,0x3
    80005356:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000535a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000535e:	01897663          	bgeu	s2,s8,8000536a <exec+0x242>
  sz = sz1;
    80005362:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005366:	4481                	li	s1,0
    80005368:	a059                	j	800053ee <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000536a:	e9040613          	addi	a2,s0,-368
    8000536e:	85ca                	mv	a1,s2
    80005370:	855e                	mv	a0,s7
    80005372:	ffffc097          	auipc	ra,0xffffc
    80005376:	300080e7          	jalr	768(ra) # 80001672 <copyout>
    8000537a:	0a054663          	bltz	a0,80005426 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000537e:	058ab783          	ld	a5,88(s5)
    80005382:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005386:	df843783          	ld	a5,-520(s0)
    8000538a:	0007c703          	lbu	a4,0(a5)
    8000538e:	cf11                	beqz	a4,800053aa <exec+0x282>
    80005390:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005392:	02f00693          	li	a3,47
    80005396:	a039                	j	800053a4 <exec+0x27c>
      last = s+1;
    80005398:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000539c:	0785                	addi	a5,a5,1
    8000539e:	fff7c703          	lbu	a4,-1(a5)
    800053a2:	c701                	beqz	a4,800053aa <exec+0x282>
    if(*s == '/')
    800053a4:	fed71ce3          	bne	a4,a3,8000539c <exec+0x274>
    800053a8:	bfc5                	j	80005398 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800053aa:	4641                	li	a2,16
    800053ac:	df843583          	ld	a1,-520(s0)
    800053b0:	158a8513          	addi	a0,s5,344
    800053b4:	ffffc097          	auipc	ra,0xffffc
    800053b8:	a7e080e7          	jalr	-1410(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800053bc:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800053c0:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800053c4:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800053c8:	058ab783          	ld	a5,88(s5)
    800053cc:	e6843703          	ld	a4,-408(s0)
    800053d0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800053d2:	058ab783          	ld	a5,88(s5)
    800053d6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800053da:	85ea                	mv	a1,s10
    800053dc:	ffffd097          	auipc	ra,0xffffd
    800053e0:	ab8080e7          	jalr	-1352(ra) # 80001e94 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800053e4:	0004851b          	sext.w	a0,s1
    800053e8:	bbe1                	j	800051c0 <exec+0x98>
    800053ea:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800053ee:	e0843583          	ld	a1,-504(s0)
    800053f2:	855e                	mv	a0,s7
    800053f4:	ffffd097          	auipc	ra,0xffffd
    800053f8:	aa0080e7          	jalr	-1376(ra) # 80001e94 <proc_freepagetable>
  if(ip){
    800053fc:	da0498e3          	bnez	s1,800051ac <exec+0x84>
  return -1;
    80005400:	557d                	li	a0,-1
    80005402:	bb7d                	j	800051c0 <exec+0x98>
    80005404:	e1243423          	sd	s2,-504(s0)
    80005408:	b7dd                	j	800053ee <exec+0x2c6>
    8000540a:	e1243423          	sd	s2,-504(s0)
    8000540e:	b7c5                	j	800053ee <exec+0x2c6>
    80005410:	e1243423          	sd	s2,-504(s0)
    80005414:	bfe9                	j	800053ee <exec+0x2c6>
  sz = sz1;
    80005416:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000541a:	4481                	li	s1,0
    8000541c:	bfc9                	j	800053ee <exec+0x2c6>
  sz = sz1;
    8000541e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005422:	4481                	li	s1,0
    80005424:	b7e9                	j	800053ee <exec+0x2c6>
  sz = sz1;
    80005426:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000542a:	4481                	li	s1,0
    8000542c:	b7c9                	j	800053ee <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000542e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005432:	2b05                	addiw	s6,s6,1
    80005434:	0389899b          	addiw	s3,s3,56
    80005438:	e8845783          	lhu	a5,-376(s0)
    8000543c:	e2fb5be3          	bge	s6,a5,80005272 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005440:	2981                	sext.w	s3,s3
    80005442:	03800713          	li	a4,56
    80005446:	86ce                	mv	a3,s3
    80005448:	e1840613          	addi	a2,s0,-488
    8000544c:	4581                	li	a1,0
    8000544e:	8526                	mv	a0,s1
    80005450:	fffff097          	auipc	ra,0xfffff
    80005454:	a8e080e7          	jalr	-1394(ra) # 80003ede <readi>
    80005458:	03800793          	li	a5,56
    8000545c:	f8f517e3          	bne	a0,a5,800053ea <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005460:	e1842783          	lw	a5,-488(s0)
    80005464:	4705                	li	a4,1
    80005466:	fce796e3          	bne	a5,a4,80005432 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000546a:	e4043603          	ld	a2,-448(s0)
    8000546e:	e3843783          	ld	a5,-456(s0)
    80005472:	f8f669e3          	bltu	a2,a5,80005404 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005476:	e2843783          	ld	a5,-472(s0)
    8000547a:	963e                	add	a2,a2,a5
    8000547c:	f8f667e3          	bltu	a2,a5,8000540a <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005480:	85ca                	mv	a1,s2
    80005482:	855e                	mv	a0,s7
    80005484:	ffffc097          	auipc	ra,0xffffc
    80005488:	f9e080e7          	jalr	-98(ra) # 80001422 <uvmalloc>
    8000548c:	e0a43423          	sd	a0,-504(s0)
    80005490:	d141                	beqz	a0,80005410 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005492:	e2843d03          	ld	s10,-472(s0)
    80005496:	df043783          	ld	a5,-528(s0)
    8000549a:	00fd77b3          	and	a5,s10,a5
    8000549e:	fba1                	bnez	a5,800053ee <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800054a0:	e2042d83          	lw	s11,-480(s0)
    800054a4:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800054a8:	f80c03e3          	beqz	s8,8000542e <exec+0x306>
    800054ac:	8a62                	mv	s4,s8
    800054ae:	4901                	li	s2,0
    800054b0:	b345                	j	80005250 <exec+0x128>

00000000800054b2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800054b2:	7179                	addi	sp,sp,-48
    800054b4:	f406                	sd	ra,40(sp)
    800054b6:	f022                	sd	s0,32(sp)
    800054b8:	ec26                	sd	s1,24(sp)
    800054ba:	e84a                	sd	s2,16(sp)
    800054bc:	1800                	addi	s0,sp,48
    800054be:	892e                	mv	s2,a1
    800054c0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800054c2:	fdc40593          	addi	a1,s0,-36
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	bf2080e7          	jalr	-1038(ra) # 800030b8 <argint>
    800054ce:	04054063          	bltz	a0,8000550e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800054d2:	fdc42703          	lw	a4,-36(s0)
    800054d6:	47bd                	li	a5,15
    800054d8:	02e7ed63          	bltu	a5,a4,80005512 <argfd+0x60>
    800054dc:	ffffd097          	auipc	ra,0xffffd
    800054e0:	85e080e7          	jalr	-1954(ra) # 80001d3a <myproc>
    800054e4:	fdc42703          	lw	a4,-36(s0)
    800054e8:	01a70793          	addi	a5,a4,26
    800054ec:	078e                	slli	a5,a5,0x3
    800054ee:	953e                	add	a0,a0,a5
    800054f0:	611c                	ld	a5,0(a0)
    800054f2:	c395                	beqz	a5,80005516 <argfd+0x64>
    return -1;
  if(pfd)
    800054f4:	00090463          	beqz	s2,800054fc <argfd+0x4a>
    *pfd = fd;
    800054f8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800054fc:	4501                	li	a0,0
  if(pf)
    800054fe:	c091                	beqz	s1,80005502 <argfd+0x50>
    *pf = f;
    80005500:	e09c                	sd	a5,0(s1)
}
    80005502:	70a2                	ld	ra,40(sp)
    80005504:	7402                	ld	s0,32(sp)
    80005506:	64e2                	ld	s1,24(sp)
    80005508:	6942                	ld	s2,16(sp)
    8000550a:	6145                	addi	sp,sp,48
    8000550c:	8082                	ret
    return -1;
    8000550e:	557d                	li	a0,-1
    80005510:	bfcd                	j	80005502 <argfd+0x50>
    return -1;
    80005512:	557d                	li	a0,-1
    80005514:	b7fd                	j	80005502 <argfd+0x50>
    80005516:	557d                	li	a0,-1
    80005518:	b7ed                	j	80005502 <argfd+0x50>

000000008000551a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000551a:	1101                	addi	sp,sp,-32
    8000551c:	ec06                	sd	ra,24(sp)
    8000551e:	e822                	sd	s0,16(sp)
    80005520:	e426                	sd	s1,8(sp)
    80005522:	1000                	addi	s0,sp,32
    80005524:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005526:	ffffd097          	auipc	ra,0xffffd
    8000552a:	814080e7          	jalr	-2028(ra) # 80001d3a <myproc>
    8000552e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005530:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005534:	4501                	li	a0,0
    80005536:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005538:	6398                	ld	a4,0(a5)
    8000553a:	cb19                	beqz	a4,80005550 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000553c:	2505                	addiw	a0,a0,1
    8000553e:	07a1                	addi	a5,a5,8
    80005540:	fed51ce3          	bne	a0,a3,80005538 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005544:	557d                	li	a0,-1
}
    80005546:	60e2                	ld	ra,24(sp)
    80005548:	6442                	ld	s0,16(sp)
    8000554a:	64a2                	ld	s1,8(sp)
    8000554c:	6105                	addi	sp,sp,32
    8000554e:	8082                	ret
      p->ofile[fd] = f;
    80005550:	01a50793          	addi	a5,a0,26
    80005554:	078e                	slli	a5,a5,0x3
    80005556:	963e                	add	a2,a2,a5
    80005558:	e204                	sd	s1,0(a2)
      return fd;
    8000555a:	b7f5                	j	80005546 <fdalloc+0x2c>

000000008000555c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000555c:	715d                	addi	sp,sp,-80
    8000555e:	e486                	sd	ra,72(sp)
    80005560:	e0a2                	sd	s0,64(sp)
    80005562:	fc26                	sd	s1,56(sp)
    80005564:	f84a                	sd	s2,48(sp)
    80005566:	f44e                	sd	s3,40(sp)
    80005568:	f052                	sd	s4,32(sp)
    8000556a:	ec56                	sd	s5,24(sp)
    8000556c:	0880                	addi	s0,sp,80
    8000556e:	89ae                	mv	s3,a1
    80005570:	8ab2                	mv	s5,a2
    80005572:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005574:	fb040593          	addi	a1,s0,-80
    80005578:	fffff097          	auipc	ra,0xfffff
    8000557c:	e86080e7          	jalr	-378(ra) # 800043fe <nameiparent>
    80005580:	892a                	mv	s2,a0
    80005582:	12050f63          	beqz	a0,800056c0 <create+0x164>
    return 0;

  ilock(dp);
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	6a4080e7          	jalr	1700(ra) # 80003c2a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000558e:	4601                	li	a2,0
    80005590:	fb040593          	addi	a1,s0,-80
    80005594:	854a                	mv	a0,s2
    80005596:	fffff097          	auipc	ra,0xfffff
    8000559a:	b78080e7          	jalr	-1160(ra) # 8000410e <dirlookup>
    8000559e:	84aa                	mv	s1,a0
    800055a0:	c921                	beqz	a0,800055f0 <create+0x94>
    iunlockput(dp);
    800055a2:	854a                	mv	a0,s2
    800055a4:	fffff097          	auipc	ra,0xfffff
    800055a8:	8e8080e7          	jalr	-1816(ra) # 80003e8c <iunlockput>
    ilock(ip);
    800055ac:	8526                	mv	a0,s1
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	67c080e7          	jalr	1660(ra) # 80003c2a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800055b6:	2981                	sext.w	s3,s3
    800055b8:	4789                	li	a5,2
    800055ba:	02f99463          	bne	s3,a5,800055e2 <create+0x86>
    800055be:	0444d783          	lhu	a5,68(s1)
    800055c2:	37f9                	addiw	a5,a5,-2
    800055c4:	17c2                	slli	a5,a5,0x30
    800055c6:	93c1                	srli	a5,a5,0x30
    800055c8:	4705                	li	a4,1
    800055ca:	00f76c63          	bltu	a4,a5,800055e2 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800055ce:	8526                	mv	a0,s1
    800055d0:	60a6                	ld	ra,72(sp)
    800055d2:	6406                	ld	s0,64(sp)
    800055d4:	74e2                	ld	s1,56(sp)
    800055d6:	7942                	ld	s2,48(sp)
    800055d8:	79a2                	ld	s3,40(sp)
    800055da:	7a02                	ld	s4,32(sp)
    800055dc:	6ae2                	ld	s5,24(sp)
    800055de:	6161                	addi	sp,sp,80
    800055e0:	8082                	ret
    iunlockput(ip);
    800055e2:	8526                	mv	a0,s1
    800055e4:	fffff097          	auipc	ra,0xfffff
    800055e8:	8a8080e7          	jalr	-1880(ra) # 80003e8c <iunlockput>
    return 0;
    800055ec:	4481                	li	s1,0
    800055ee:	b7c5                	j	800055ce <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800055f0:	85ce                	mv	a1,s3
    800055f2:	00092503          	lw	a0,0(s2)
    800055f6:	ffffe097          	auipc	ra,0xffffe
    800055fa:	49c080e7          	jalr	1180(ra) # 80003a92 <ialloc>
    800055fe:	84aa                	mv	s1,a0
    80005600:	c529                	beqz	a0,8000564a <create+0xee>
  ilock(ip);
    80005602:	ffffe097          	auipc	ra,0xffffe
    80005606:	628080e7          	jalr	1576(ra) # 80003c2a <ilock>
  ip->major = major;
    8000560a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000560e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005612:	4785                	li	a5,1
    80005614:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005618:	8526                	mv	a0,s1
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	546080e7          	jalr	1350(ra) # 80003b60 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005622:	2981                	sext.w	s3,s3
    80005624:	4785                	li	a5,1
    80005626:	02f98a63          	beq	s3,a5,8000565a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000562a:	40d0                	lw	a2,4(s1)
    8000562c:	fb040593          	addi	a1,s0,-80
    80005630:	854a                	mv	a0,s2
    80005632:	fffff097          	auipc	ra,0xfffff
    80005636:	cec080e7          	jalr	-788(ra) # 8000431e <dirlink>
    8000563a:	06054b63          	bltz	a0,800056b0 <create+0x154>
  iunlockput(dp);
    8000563e:	854a                	mv	a0,s2
    80005640:	fffff097          	auipc	ra,0xfffff
    80005644:	84c080e7          	jalr	-1972(ra) # 80003e8c <iunlockput>
  return ip;
    80005648:	b759                	j	800055ce <create+0x72>
    panic("create: ialloc");
    8000564a:	00003517          	auipc	a0,0x3
    8000564e:	12650513          	addi	a0,a0,294 # 80008770 <syscalls+0x2a0>
    80005652:	ffffb097          	auipc	ra,0xffffb
    80005656:	eec080e7          	jalr	-276(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000565a:	04a95783          	lhu	a5,74(s2)
    8000565e:	2785                	addiw	a5,a5,1
    80005660:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005664:	854a                	mv	a0,s2
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	4fa080e7          	jalr	1274(ra) # 80003b60 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000566e:	40d0                	lw	a2,4(s1)
    80005670:	00003597          	auipc	a1,0x3
    80005674:	11058593          	addi	a1,a1,272 # 80008780 <syscalls+0x2b0>
    80005678:	8526                	mv	a0,s1
    8000567a:	fffff097          	auipc	ra,0xfffff
    8000567e:	ca4080e7          	jalr	-860(ra) # 8000431e <dirlink>
    80005682:	00054f63          	bltz	a0,800056a0 <create+0x144>
    80005686:	00492603          	lw	a2,4(s2)
    8000568a:	00003597          	auipc	a1,0x3
    8000568e:	0fe58593          	addi	a1,a1,254 # 80008788 <syscalls+0x2b8>
    80005692:	8526                	mv	a0,s1
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	c8a080e7          	jalr	-886(ra) # 8000431e <dirlink>
    8000569c:	f80557e3          	bgez	a0,8000562a <create+0xce>
      panic("create dots");
    800056a0:	00003517          	auipc	a0,0x3
    800056a4:	0f050513          	addi	a0,a0,240 # 80008790 <syscalls+0x2c0>
    800056a8:	ffffb097          	auipc	ra,0xffffb
    800056ac:	e96080e7          	jalr	-362(ra) # 8000053e <panic>
    panic("create: dirlink");
    800056b0:	00003517          	auipc	a0,0x3
    800056b4:	0f050513          	addi	a0,a0,240 # 800087a0 <syscalls+0x2d0>
    800056b8:	ffffb097          	auipc	ra,0xffffb
    800056bc:	e86080e7          	jalr	-378(ra) # 8000053e <panic>
    return 0;
    800056c0:	84aa                	mv	s1,a0
    800056c2:	b731                	j	800055ce <create+0x72>

00000000800056c4 <sys_dup>:
{
    800056c4:	7179                	addi	sp,sp,-48
    800056c6:	f406                	sd	ra,40(sp)
    800056c8:	f022                	sd	s0,32(sp)
    800056ca:	ec26                	sd	s1,24(sp)
    800056cc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800056ce:	fd840613          	addi	a2,s0,-40
    800056d2:	4581                	li	a1,0
    800056d4:	4501                	li	a0,0
    800056d6:	00000097          	auipc	ra,0x0
    800056da:	ddc080e7          	jalr	-548(ra) # 800054b2 <argfd>
    return -1;
    800056de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800056e0:	02054363          	bltz	a0,80005706 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800056e4:	fd843503          	ld	a0,-40(s0)
    800056e8:	00000097          	auipc	ra,0x0
    800056ec:	e32080e7          	jalr	-462(ra) # 8000551a <fdalloc>
    800056f0:	84aa                	mv	s1,a0
    return -1;
    800056f2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800056f4:	00054963          	bltz	a0,80005706 <sys_dup+0x42>
  filedup(f);
    800056f8:	fd843503          	ld	a0,-40(s0)
    800056fc:	fffff097          	auipc	ra,0xfffff
    80005700:	37a080e7          	jalr	890(ra) # 80004a76 <filedup>
  return fd;
    80005704:	87a6                	mv	a5,s1
}
    80005706:	853e                	mv	a0,a5
    80005708:	70a2                	ld	ra,40(sp)
    8000570a:	7402                	ld	s0,32(sp)
    8000570c:	64e2                	ld	s1,24(sp)
    8000570e:	6145                	addi	sp,sp,48
    80005710:	8082                	ret

0000000080005712 <sys_read>:
{
    80005712:	7179                	addi	sp,sp,-48
    80005714:	f406                	sd	ra,40(sp)
    80005716:	f022                	sd	s0,32(sp)
    80005718:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000571a:	fe840613          	addi	a2,s0,-24
    8000571e:	4581                	li	a1,0
    80005720:	4501                	li	a0,0
    80005722:	00000097          	auipc	ra,0x0
    80005726:	d90080e7          	jalr	-624(ra) # 800054b2 <argfd>
    return -1;
    8000572a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000572c:	04054163          	bltz	a0,8000576e <sys_read+0x5c>
    80005730:	fe440593          	addi	a1,s0,-28
    80005734:	4509                	li	a0,2
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	982080e7          	jalr	-1662(ra) # 800030b8 <argint>
    return -1;
    8000573e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005740:	02054763          	bltz	a0,8000576e <sys_read+0x5c>
    80005744:	fd840593          	addi	a1,s0,-40
    80005748:	4505                	li	a0,1
    8000574a:	ffffe097          	auipc	ra,0xffffe
    8000574e:	990080e7          	jalr	-1648(ra) # 800030da <argaddr>
    return -1;
    80005752:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005754:	00054d63          	bltz	a0,8000576e <sys_read+0x5c>
  return fileread(f, p, n);
    80005758:	fe442603          	lw	a2,-28(s0)
    8000575c:	fd843583          	ld	a1,-40(s0)
    80005760:	fe843503          	ld	a0,-24(s0)
    80005764:	fffff097          	auipc	ra,0xfffff
    80005768:	49e080e7          	jalr	1182(ra) # 80004c02 <fileread>
    8000576c:	87aa                	mv	a5,a0
}
    8000576e:	853e                	mv	a0,a5
    80005770:	70a2                	ld	ra,40(sp)
    80005772:	7402                	ld	s0,32(sp)
    80005774:	6145                	addi	sp,sp,48
    80005776:	8082                	ret

0000000080005778 <sys_write>:
{
    80005778:	7179                	addi	sp,sp,-48
    8000577a:	f406                	sd	ra,40(sp)
    8000577c:	f022                	sd	s0,32(sp)
    8000577e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005780:	fe840613          	addi	a2,s0,-24
    80005784:	4581                	li	a1,0
    80005786:	4501                	li	a0,0
    80005788:	00000097          	auipc	ra,0x0
    8000578c:	d2a080e7          	jalr	-726(ra) # 800054b2 <argfd>
    return -1;
    80005790:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005792:	04054163          	bltz	a0,800057d4 <sys_write+0x5c>
    80005796:	fe440593          	addi	a1,s0,-28
    8000579a:	4509                	li	a0,2
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	91c080e7          	jalr	-1764(ra) # 800030b8 <argint>
    return -1;
    800057a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057a6:	02054763          	bltz	a0,800057d4 <sys_write+0x5c>
    800057aa:	fd840593          	addi	a1,s0,-40
    800057ae:	4505                	li	a0,1
    800057b0:	ffffe097          	auipc	ra,0xffffe
    800057b4:	92a080e7          	jalr	-1750(ra) # 800030da <argaddr>
    return -1;
    800057b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057ba:	00054d63          	bltz	a0,800057d4 <sys_write+0x5c>
  return filewrite(f, p, n);
    800057be:	fe442603          	lw	a2,-28(s0)
    800057c2:	fd843583          	ld	a1,-40(s0)
    800057c6:	fe843503          	ld	a0,-24(s0)
    800057ca:	fffff097          	auipc	ra,0xfffff
    800057ce:	4fa080e7          	jalr	1274(ra) # 80004cc4 <filewrite>
    800057d2:	87aa                	mv	a5,a0
}
    800057d4:	853e                	mv	a0,a5
    800057d6:	70a2                	ld	ra,40(sp)
    800057d8:	7402                	ld	s0,32(sp)
    800057da:	6145                	addi	sp,sp,48
    800057dc:	8082                	ret

00000000800057de <sys_close>:
{
    800057de:	1101                	addi	sp,sp,-32
    800057e0:	ec06                	sd	ra,24(sp)
    800057e2:	e822                	sd	s0,16(sp)
    800057e4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800057e6:	fe040613          	addi	a2,s0,-32
    800057ea:	fec40593          	addi	a1,s0,-20
    800057ee:	4501                	li	a0,0
    800057f0:	00000097          	auipc	ra,0x0
    800057f4:	cc2080e7          	jalr	-830(ra) # 800054b2 <argfd>
    return -1;
    800057f8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057fa:	02054463          	bltz	a0,80005822 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800057fe:	ffffc097          	auipc	ra,0xffffc
    80005802:	53c080e7          	jalr	1340(ra) # 80001d3a <myproc>
    80005806:	fec42783          	lw	a5,-20(s0)
    8000580a:	07e9                	addi	a5,a5,26
    8000580c:	078e                	slli	a5,a5,0x3
    8000580e:	97aa                	add	a5,a5,a0
    80005810:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005814:	fe043503          	ld	a0,-32(s0)
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	2b0080e7          	jalr	688(ra) # 80004ac8 <fileclose>
  return 0;
    80005820:	4781                	li	a5,0
}
    80005822:	853e                	mv	a0,a5
    80005824:	60e2                	ld	ra,24(sp)
    80005826:	6442                	ld	s0,16(sp)
    80005828:	6105                	addi	sp,sp,32
    8000582a:	8082                	ret

000000008000582c <sys_fstat>:
{
    8000582c:	1101                	addi	sp,sp,-32
    8000582e:	ec06                	sd	ra,24(sp)
    80005830:	e822                	sd	s0,16(sp)
    80005832:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005834:	fe840613          	addi	a2,s0,-24
    80005838:	4581                	li	a1,0
    8000583a:	4501                	li	a0,0
    8000583c:	00000097          	auipc	ra,0x0
    80005840:	c76080e7          	jalr	-906(ra) # 800054b2 <argfd>
    return -1;
    80005844:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005846:	02054563          	bltz	a0,80005870 <sys_fstat+0x44>
    8000584a:	fe040593          	addi	a1,s0,-32
    8000584e:	4505                	li	a0,1
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	88a080e7          	jalr	-1910(ra) # 800030da <argaddr>
    return -1;
    80005858:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000585a:	00054b63          	bltz	a0,80005870 <sys_fstat+0x44>
  return filestat(f, st);
    8000585e:	fe043583          	ld	a1,-32(s0)
    80005862:	fe843503          	ld	a0,-24(s0)
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	32a080e7          	jalr	810(ra) # 80004b90 <filestat>
    8000586e:	87aa                	mv	a5,a0
}
    80005870:	853e                	mv	a0,a5
    80005872:	60e2                	ld	ra,24(sp)
    80005874:	6442                	ld	s0,16(sp)
    80005876:	6105                	addi	sp,sp,32
    80005878:	8082                	ret

000000008000587a <sys_link>:
{
    8000587a:	7169                	addi	sp,sp,-304
    8000587c:	f606                	sd	ra,296(sp)
    8000587e:	f222                	sd	s0,288(sp)
    80005880:	ee26                	sd	s1,280(sp)
    80005882:	ea4a                	sd	s2,272(sp)
    80005884:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005886:	08000613          	li	a2,128
    8000588a:	ed040593          	addi	a1,s0,-304
    8000588e:	4501                	li	a0,0
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	86c080e7          	jalr	-1940(ra) # 800030fc <argstr>
    return -1;
    80005898:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000589a:	10054e63          	bltz	a0,800059b6 <sys_link+0x13c>
    8000589e:	08000613          	li	a2,128
    800058a2:	f5040593          	addi	a1,s0,-176
    800058a6:	4505                	li	a0,1
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	854080e7          	jalr	-1964(ra) # 800030fc <argstr>
    return -1;
    800058b0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058b2:	10054263          	bltz	a0,800059b6 <sys_link+0x13c>
  begin_op();
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	d46080e7          	jalr	-698(ra) # 800045fc <begin_op>
  if((ip = namei(old)) == 0){
    800058be:	ed040513          	addi	a0,s0,-304
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	b1e080e7          	jalr	-1250(ra) # 800043e0 <namei>
    800058ca:	84aa                	mv	s1,a0
    800058cc:	c551                	beqz	a0,80005958 <sys_link+0xde>
  ilock(ip);
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	35c080e7          	jalr	860(ra) # 80003c2a <ilock>
  if(ip->type == T_DIR){
    800058d6:	04449703          	lh	a4,68(s1)
    800058da:	4785                	li	a5,1
    800058dc:	08f70463          	beq	a4,a5,80005964 <sys_link+0xea>
  ip->nlink++;
    800058e0:	04a4d783          	lhu	a5,74(s1)
    800058e4:	2785                	addiw	a5,a5,1
    800058e6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058ea:	8526                	mv	a0,s1
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	274080e7          	jalr	628(ra) # 80003b60 <iupdate>
  iunlock(ip);
    800058f4:	8526                	mv	a0,s1
    800058f6:	ffffe097          	auipc	ra,0xffffe
    800058fa:	3f6080e7          	jalr	1014(ra) # 80003cec <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058fe:	fd040593          	addi	a1,s0,-48
    80005902:	f5040513          	addi	a0,s0,-176
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	af8080e7          	jalr	-1288(ra) # 800043fe <nameiparent>
    8000590e:	892a                	mv	s2,a0
    80005910:	c935                	beqz	a0,80005984 <sys_link+0x10a>
  ilock(dp);
    80005912:	ffffe097          	auipc	ra,0xffffe
    80005916:	318080e7          	jalr	792(ra) # 80003c2a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000591a:	00092703          	lw	a4,0(s2)
    8000591e:	409c                	lw	a5,0(s1)
    80005920:	04f71d63          	bne	a4,a5,8000597a <sys_link+0x100>
    80005924:	40d0                	lw	a2,4(s1)
    80005926:	fd040593          	addi	a1,s0,-48
    8000592a:	854a                	mv	a0,s2
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	9f2080e7          	jalr	-1550(ra) # 8000431e <dirlink>
    80005934:	04054363          	bltz	a0,8000597a <sys_link+0x100>
  iunlockput(dp);
    80005938:	854a                	mv	a0,s2
    8000593a:	ffffe097          	auipc	ra,0xffffe
    8000593e:	552080e7          	jalr	1362(ra) # 80003e8c <iunlockput>
  iput(ip);
    80005942:	8526                	mv	a0,s1
    80005944:	ffffe097          	auipc	ra,0xffffe
    80005948:	4a0080e7          	jalr	1184(ra) # 80003de4 <iput>
  end_op();
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	d30080e7          	jalr	-720(ra) # 8000467c <end_op>
  return 0;
    80005954:	4781                	li	a5,0
    80005956:	a085                	j	800059b6 <sys_link+0x13c>
    end_op();
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	d24080e7          	jalr	-732(ra) # 8000467c <end_op>
    return -1;
    80005960:	57fd                	li	a5,-1
    80005962:	a891                	j	800059b6 <sys_link+0x13c>
    iunlockput(ip);
    80005964:	8526                	mv	a0,s1
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	526080e7          	jalr	1318(ra) # 80003e8c <iunlockput>
    end_op();
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	d0e080e7          	jalr	-754(ra) # 8000467c <end_op>
    return -1;
    80005976:	57fd                	li	a5,-1
    80005978:	a83d                	j	800059b6 <sys_link+0x13c>
    iunlockput(dp);
    8000597a:	854a                	mv	a0,s2
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	510080e7          	jalr	1296(ra) # 80003e8c <iunlockput>
  ilock(ip);
    80005984:	8526                	mv	a0,s1
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	2a4080e7          	jalr	676(ra) # 80003c2a <ilock>
  ip->nlink--;
    8000598e:	04a4d783          	lhu	a5,74(s1)
    80005992:	37fd                	addiw	a5,a5,-1
    80005994:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005998:	8526                	mv	a0,s1
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	1c6080e7          	jalr	454(ra) # 80003b60 <iupdate>
  iunlockput(ip);
    800059a2:	8526                	mv	a0,s1
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	4e8080e7          	jalr	1256(ra) # 80003e8c <iunlockput>
  end_op();
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	cd0080e7          	jalr	-816(ra) # 8000467c <end_op>
  return -1;
    800059b4:	57fd                	li	a5,-1
}
    800059b6:	853e                	mv	a0,a5
    800059b8:	70b2                	ld	ra,296(sp)
    800059ba:	7412                	ld	s0,288(sp)
    800059bc:	64f2                	ld	s1,280(sp)
    800059be:	6952                	ld	s2,272(sp)
    800059c0:	6155                	addi	sp,sp,304
    800059c2:	8082                	ret

00000000800059c4 <sys_unlink>:
{
    800059c4:	7151                	addi	sp,sp,-240
    800059c6:	f586                	sd	ra,232(sp)
    800059c8:	f1a2                	sd	s0,224(sp)
    800059ca:	eda6                	sd	s1,216(sp)
    800059cc:	e9ca                	sd	s2,208(sp)
    800059ce:	e5ce                	sd	s3,200(sp)
    800059d0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800059d2:	08000613          	li	a2,128
    800059d6:	f3040593          	addi	a1,s0,-208
    800059da:	4501                	li	a0,0
    800059dc:	ffffd097          	auipc	ra,0xffffd
    800059e0:	720080e7          	jalr	1824(ra) # 800030fc <argstr>
    800059e4:	18054163          	bltz	a0,80005b66 <sys_unlink+0x1a2>
  begin_op();
    800059e8:	fffff097          	auipc	ra,0xfffff
    800059ec:	c14080e7          	jalr	-1004(ra) # 800045fc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800059f0:	fb040593          	addi	a1,s0,-80
    800059f4:	f3040513          	addi	a0,s0,-208
    800059f8:	fffff097          	auipc	ra,0xfffff
    800059fc:	a06080e7          	jalr	-1530(ra) # 800043fe <nameiparent>
    80005a00:	84aa                	mv	s1,a0
    80005a02:	c979                	beqz	a0,80005ad8 <sys_unlink+0x114>
  ilock(dp);
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	226080e7          	jalr	550(ra) # 80003c2a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a0c:	00003597          	auipc	a1,0x3
    80005a10:	d7458593          	addi	a1,a1,-652 # 80008780 <syscalls+0x2b0>
    80005a14:	fb040513          	addi	a0,s0,-80
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	6dc080e7          	jalr	1756(ra) # 800040f4 <namecmp>
    80005a20:	14050a63          	beqz	a0,80005b74 <sys_unlink+0x1b0>
    80005a24:	00003597          	auipc	a1,0x3
    80005a28:	d6458593          	addi	a1,a1,-668 # 80008788 <syscalls+0x2b8>
    80005a2c:	fb040513          	addi	a0,s0,-80
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	6c4080e7          	jalr	1732(ra) # 800040f4 <namecmp>
    80005a38:	12050e63          	beqz	a0,80005b74 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a3c:	f2c40613          	addi	a2,s0,-212
    80005a40:	fb040593          	addi	a1,s0,-80
    80005a44:	8526                	mv	a0,s1
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	6c8080e7          	jalr	1736(ra) # 8000410e <dirlookup>
    80005a4e:	892a                	mv	s2,a0
    80005a50:	12050263          	beqz	a0,80005b74 <sys_unlink+0x1b0>
  ilock(ip);
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	1d6080e7          	jalr	470(ra) # 80003c2a <ilock>
  if(ip->nlink < 1)
    80005a5c:	04a91783          	lh	a5,74(s2)
    80005a60:	08f05263          	blez	a5,80005ae4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a64:	04491703          	lh	a4,68(s2)
    80005a68:	4785                	li	a5,1
    80005a6a:	08f70563          	beq	a4,a5,80005af4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a6e:	4641                	li	a2,16
    80005a70:	4581                	li	a1,0
    80005a72:	fc040513          	addi	a0,s0,-64
    80005a76:	ffffb097          	auipc	ra,0xffffb
    80005a7a:	26a080e7          	jalr	618(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a7e:	4741                	li	a4,16
    80005a80:	f2c42683          	lw	a3,-212(s0)
    80005a84:	fc040613          	addi	a2,s0,-64
    80005a88:	4581                	li	a1,0
    80005a8a:	8526                	mv	a0,s1
    80005a8c:	ffffe097          	auipc	ra,0xffffe
    80005a90:	54a080e7          	jalr	1354(ra) # 80003fd6 <writei>
    80005a94:	47c1                	li	a5,16
    80005a96:	0af51563          	bne	a0,a5,80005b40 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a9a:	04491703          	lh	a4,68(s2)
    80005a9e:	4785                	li	a5,1
    80005aa0:	0af70863          	beq	a4,a5,80005b50 <sys_unlink+0x18c>
  iunlockput(dp);
    80005aa4:	8526                	mv	a0,s1
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	3e6080e7          	jalr	998(ra) # 80003e8c <iunlockput>
  ip->nlink--;
    80005aae:	04a95783          	lhu	a5,74(s2)
    80005ab2:	37fd                	addiw	a5,a5,-1
    80005ab4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005ab8:	854a                	mv	a0,s2
    80005aba:	ffffe097          	auipc	ra,0xffffe
    80005abe:	0a6080e7          	jalr	166(ra) # 80003b60 <iupdate>
  iunlockput(ip);
    80005ac2:	854a                	mv	a0,s2
    80005ac4:	ffffe097          	auipc	ra,0xffffe
    80005ac8:	3c8080e7          	jalr	968(ra) # 80003e8c <iunlockput>
  end_op();
    80005acc:	fffff097          	auipc	ra,0xfffff
    80005ad0:	bb0080e7          	jalr	-1104(ra) # 8000467c <end_op>
  return 0;
    80005ad4:	4501                	li	a0,0
    80005ad6:	a84d                	j	80005b88 <sys_unlink+0x1c4>
    end_op();
    80005ad8:	fffff097          	auipc	ra,0xfffff
    80005adc:	ba4080e7          	jalr	-1116(ra) # 8000467c <end_op>
    return -1;
    80005ae0:	557d                	li	a0,-1
    80005ae2:	a05d                	j	80005b88 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005ae4:	00003517          	auipc	a0,0x3
    80005ae8:	ccc50513          	addi	a0,a0,-820 # 800087b0 <syscalls+0x2e0>
    80005aec:	ffffb097          	auipc	ra,0xffffb
    80005af0:	a52080e7          	jalr	-1454(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005af4:	04c92703          	lw	a4,76(s2)
    80005af8:	02000793          	li	a5,32
    80005afc:	f6e7f9e3          	bgeu	a5,a4,80005a6e <sys_unlink+0xaa>
    80005b00:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b04:	4741                	li	a4,16
    80005b06:	86ce                	mv	a3,s3
    80005b08:	f1840613          	addi	a2,s0,-232
    80005b0c:	4581                	li	a1,0
    80005b0e:	854a                	mv	a0,s2
    80005b10:	ffffe097          	auipc	ra,0xffffe
    80005b14:	3ce080e7          	jalr	974(ra) # 80003ede <readi>
    80005b18:	47c1                	li	a5,16
    80005b1a:	00f51b63          	bne	a0,a5,80005b30 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b1e:	f1845783          	lhu	a5,-232(s0)
    80005b22:	e7a1                	bnez	a5,80005b6a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b24:	29c1                	addiw	s3,s3,16
    80005b26:	04c92783          	lw	a5,76(s2)
    80005b2a:	fcf9ede3          	bltu	s3,a5,80005b04 <sys_unlink+0x140>
    80005b2e:	b781                	j	80005a6e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b30:	00003517          	auipc	a0,0x3
    80005b34:	c9850513          	addi	a0,a0,-872 # 800087c8 <syscalls+0x2f8>
    80005b38:	ffffb097          	auipc	ra,0xffffb
    80005b3c:	a06080e7          	jalr	-1530(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005b40:	00003517          	auipc	a0,0x3
    80005b44:	ca050513          	addi	a0,a0,-864 # 800087e0 <syscalls+0x310>
    80005b48:	ffffb097          	auipc	ra,0xffffb
    80005b4c:	9f6080e7          	jalr	-1546(ra) # 8000053e <panic>
    dp->nlink--;
    80005b50:	04a4d783          	lhu	a5,74(s1)
    80005b54:	37fd                	addiw	a5,a5,-1
    80005b56:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b5a:	8526                	mv	a0,s1
    80005b5c:	ffffe097          	auipc	ra,0xffffe
    80005b60:	004080e7          	jalr	4(ra) # 80003b60 <iupdate>
    80005b64:	b781                	j	80005aa4 <sys_unlink+0xe0>
    return -1;
    80005b66:	557d                	li	a0,-1
    80005b68:	a005                	j	80005b88 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b6a:	854a                	mv	a0,s2
    80005b6c:	ffffe097          	auipc	ra,0xffffe
    80005b70:	320080e7          	jalr	800(ra) # 80003e8c <iunlockput>
  iunlockput(dp);
    80005b74:	8526                	mv	a0,s1
    80005b76:	ffffe097          	auipc	ra,0xffffe
    80005b7a:	316080e7          	jalr	790(ra) # 80003e8c <iunlockput>
  end_op();
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	afe080e7          	jalr	-1282(ra) # 8000467c <end_op>
  return -1;
    80005b86:	557d                	li	a0,-1
}
    80005b88:	70ae                	ld	ra,232(sp)
    80005b8a:	740e                	ld	s0,224(sp)
    80005b8c:	64ee                	ld	s1,216(sp)
    80005b8e:	694e                	ld	s2,208(sp)
    80005b90:	69ae                	ld	s3,200(sp)
    80005b92:	616d                	addi	sp,sp,240
    80005b94:	8082                	ret

0000000080005b96 <sys_open>:

uint64
sys_open(void)
{
    80005b96:	7131                	addi	sp,sp,-192
    80005b98:	fd06                	sd	ra,184(sp)
    80005b9a:	f922                	sd	s0,176(sp)
    80005b9c:	f526                	sd	s1,168(sp)
    80005b9e:	f14a                	sd	s2,160(sp)
    80005ba0:	ed4e                	sd	s3,152(sp)
    80005ba2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ba4:	08000613          	li	a2,128
    80005ba8:	f5040593          	addi	a1,s0,-176
    80005bac:	4501                	li	a0,0
    80005bae:	ffffd097          	auipc	ra,0xffffd
    80005bb2:	54e080e7          	jalr	1358(ra) # 800030fc <argstr>
    return -1;
    80005bb6:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005bb8:	0c054163          	bltz	a0,80005c7a <sys_open+0xe4>
    80005bbc:	f4c40593          	addi	a1,s0,-180
    80005bc0:	4505                	li	a0,1
    80005bc2:	ffffd097          	auipc	ra,0xffffd
    80005bc6:	4f6080e7          	jalr	1270(ra) # 800030b8 <argint>
    80005bca:	0a054863          	bltz	a0,80005c7a <sys_open+0xe4>

  begin_op();
    80005bce:	fffff097          	auipc	ra,0xfffff
    80005bd2:	a2e080e7          	jalr	-1490(ra) # 800045fc <begin_op>

  if(omode & O_CREATE){
    80005bd6:	f4c42783          	lw	a5,-180(s0)
    80005bda:	2007f793          	andi	a5,a5,512
    80005bde:	cbdd                	beqz	a5,80005c94 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005be0:	4681                	li	a3,0
    80005be2:	4601                	li	a2,0
    80005be4:	4589                	li	a1,2
    80005be6:	f5040513          	addi	a0,s0,-176
    80005bea:	00000097          	auipc	ra,0x0
    80005bee:	972080e7          	jalr	-1678(ra) # 8000555c <create>
    80005bf2:	892a                	mv	s2,a0
    if(ip == 0){
    80005bf4:	c959                	beqz	a0,80005c8a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005bf6:	04491703          	lh	a4,68(s2)
    80005bfa:	478d                	li	a5,3
    80005bfc:	00f71763          	bne	a4,a5,80005c0a <sys_open+0x74>
    80005c00:	04695703          	lhu	a4,70(s2)
    80005c04:	47a5                	li	a5,9
    80005c06:	0ce7ec63          	bltu	a5,a4,80005cde <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	e02080e7          	jalr	-510(ra) # 80004a0c <filealloc>
    80005c12:	89aa                	mv	s3,a0
    80005c14:	10050263          	beqz	a0,80005d18 <sys_open+0x182>
    80005c18:	00000097          	auipc	ra,0x0
    80005c1c:	902080e7          	jalr	-1790(ra) # 8000551a <fdalloc>
    80005c20:	84aa                	mv	s1,a0
    80005c22:	0e054663          	bltz	a0,80005d0e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c26:	04491703          	lh	a4,68(s2)
    80005c2a:	478d                	li	a5,3
    80005c2c:	0cf70463          	beq	a4,a5,80005cf4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c30:	4789                	li	a5,2
    80005c32:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c36:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c3a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c3e:	f4c42783          	lw	a5,-180(s0)
    80005c42:	0017c713          	xori	a4,a5,1
    80005c46:	8b05                	andi	a4,a4,1
    80005c48:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c4c:	0037f713          	andi	a4,a5,3
    80005c50:	00e03733          	snez	a4,a4
    80005c54:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c58:	4007f793          	andi	a5,a5,1024
    80005c5c:	c791                	beqz	a5,80005c68 <sys_open+0xd2>
    80005c5e:	04491703          	lh	a4,68(s2)
    80005c62:	4789                	li	a5,2
    80005c64:	08f70f63          	beq	a4,a5,80005d02 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c68:	854a                	mv	a0,s2
    80005c6a:	ffffe097          	auipc	ra,0xffffe
    80005c6e:	082080e7          	jalr	130(ra) # 80003cec <iunlock>
  end_op();
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	a0a080e7          	jalr	-1526(ra) # 8000467c <end_op>

  return fd;
}
    80005c7a:	8526                	mv	a0,s1
    80005c7c:	70ea                	ld	ra,184(sp)
    80005c7e:	744a                	ld	s0,176(sp)
    80005c80:	74aa                	ld	s1,168(sp)
    80005c82:	790a                	ld	s2,160(sp)
    80005c84:	69ea                	ld	s3,152(sp)
    80005c86:	6129                	addi	sp,sp,192
    80005c88:	8082                	ret
      end_op();
    80005c8a:	fffff097          	auipc	ra,0xfffff
    80005c8e:	9f2080e7          	jalr	-1550(ra) # 8000467c <end_op>
      return -1;
    80005c92:	b7e5                	j	80005c7a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c94:	f5040513          	addi	a0,s0,-176
    80005c98:	ffffe097          	auipc	ra,0xffffe
    80005c9c:	748080e7          	jalr	1864(ra) # 800043e0 <namei>
    80005ca0:	892a                	mv	s2,a0
    80005ca2:	c905                	beqz	a0,80005cd2 <sys_open+0x13c>
    ilock(ip);
    80005ca4:	ffffe097          	auipc	ra,0xffffe
    80005ca8:	f86080e7          	jalr	-122(ra) # 80003c2a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005cac:	04491703          	lh	a4,68(s2)
    80005cb0:	4785                	li	a5,1
    80005cb2:	f4f712e3          	bne	a4,a5,80005bf6 <sys_open+0x60>
    80005cb6:	f4c42783          	lw	a5,-180(s0)
    80005cba:	dba1                	beqz	a5,80005c0a <sys_open+0x74>
      iunlockput(ip);
    80005cbc:	854a                	mv	a0,s2
    80005cbe:	ffffe097          	auipc	ra,0xffffe
    80005cc2:	1ce080e7          	jalr	462(ra) # 80003e8c <iunlockput>
      end_op();
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	9b6080e7          	jalr	-1610(ra) # 8000467c <end_op>
      return -1;
    80005cce:	54fd                	li	s1,-1
    80005cd0:	b76d                	j	80005c7a <sys_open+0xe4>
      end_op();
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	9aa080e7          	jalr	-1622(ra) # 8000467c <end_op>
      return -1;
    80005cda:	54fd                	li	s1,-1
    80005cdc:	bf79                	j	80005c7a <sys_open+0xe4>
    iunlockput(ip);
    80005cde:	854a                	mv	a0,s2
    80005ce0:	ffffe097          	auipc	ra,0xffffe
    80005ce4:	1ac080e7          	jalr	428(ra) # 80003e8c <iunlockput>
    end_op();
    80005ce8:	fffff097          	auipc	ra,0xfffff
    80005cec:	994080e7          	jalr	-1644(ra) # 8000467c <end_op>
    return -1;
    80005cf0:	54fd                	li	s1,-1
    80005cf2:	b761                	j	80005c7a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005cf4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005cf8:	04691783          	lh	a5,70(s2)
    80005cfc:	02f99223          	sh	a5,36(s3)
    80005d00:	bf2d                	j	80005c3a <sys_open+0xa4>
    itrunc(ip);
    80005d02:	854a                	mv	a0,s2
    80005d04:	ffffe097          	auipc	ra,0xffffe
    80005d08:	034080e7          	jalr	52(ra) # 80003d38 <itrunc>
    80005d0c:	bfb1                	j	80005c68 <sys_open+0xd2>
      fileclose(f);
    80005d0e:	854e                	mv	a0,s3
    80005d10:	fffff097          	auipc	ra,0xfffff
    80005d14:	db8080e7          	jalr	-584(ra) # 80004ac8 <fileclose>
    iunlockput(ip);
    80005d18:	854a                	mv	a0,s2
    80005d1a:	ffffe097          	auipc	ra,0xffffe
    80005d1e:	172080e7          	jalr	370(ra) # 80003e8c <iunlockput>
    end_op();
    80005d22:	fffff097          	auipc	ra,0xfffff
    80005d26:	95a080e7          	jalr	-1702(ra) # 8000467c <end_op>
    return -1;
    80005d2a:	54fd                	li	s1,-1
    80005d2c:	b7b9                	j	80005c7a <sys_open+0xe4>

0000000080005d2e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d2e:	7175                	addi	sp,sp,-144
    80005d30:	e506                	sd	ra,136(sp)
    80005d32:	e122                	sd	s0,128(sp)
    80005d34:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d36:	fffff097          	auipc	ra,0xfffff
    80005d3a:	8c6080e7          	jalr	-1850(ra) # 800045fc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d3e:	08000613          	li	a2,128
    80005d42:	f7040593          	addi	a1,s0,-144
    80005d46:	4501                	li	a0,0
    80005d48:	ffffd097          	auipc	ra,0xffffd
    80005d4c:	3b4080e7          	jalr	948(ra) # 800030fc <argstr>
    80005d50:	02054963          	bltz	a0,80005d82 <sys_mkdir+0x54>
    80005d54:	4681                	li	a3,0
    80005d56:	4601                	li	a2,0
    80005d58:	4585                	li	a1,1
    80005d5a:	f7040513          	addi	a0,s0,-144
    80005d5e:	fffff097          	auipc	ra,0xfffff
    80005d62:	7fe080e7          	jalr	2046(ra) # 8000555c <create>
    80005d66:	cd11                	beqz	a0,80005d82 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d68:	ffffe097          	auipc	ra,0xffffe
    80005d6c:	124080e7          	jalr	292(ra) # 80003e8c <iunlockput>
  end_op();
    80005d70:	fffff097          	auipc	ra,0xfffff
    80005d74:	90c080e7          	jalr	-1780(ra) # 8000467c <end_op>
  return 0;
    80005d78:	4501                	li	a0,0
}
    80005d7a:	60aa                	ld	ra,136(sp)
    80005d7c:	640a                	ld	s0,128(sp)
    80005d7e:	6149                	addi	sp,sp,144
    80005d80:	8082                	ret
    end_op();
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	8fa080e7          	jalr	-1798(ra) # 8000467c <end_op>
    return -1;
    80005d8a:	557d                	li	a0,-1
    80005d8c:	b7fd                	j	80005d7a <sys_mkdir+0x4c>

0000000080005d8e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d8e:	7135                	addi	sp,sp,-160
    80005d90:	ed06                	sd	ra,152(sp)
    80005d92:	e922                	sd	s0,144(sp)
    80005d94:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d96:	fffff097          	auipc	ra,0xfffff
    80005d9a:	866080e7          	jalr	-1946(ra) # 800045fc <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d9e:	08000613          	li	a2,128
    80005da2:	f7040593          	addi	a1,s0,-144
    80005da6:	4501                	li	a0,0
    80005da8:	ffffd097          	auipc	ra,0xffffd
    80005dac:	354080e7          	jalr	852(ra) # 800030fc <argstr>
    80005db0:	04054a63          	bltz	a0,80005e04 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005db4:	f6c40593          	addi	a1,s0,-148
    80005db8:	4505                	li	a0,1
    80005dba:	ffffd097          	auipc	ra,0xffffd
    80005dbe:	2fe080e7          	jalr	766(ra) # 800030b8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005dc2:	04054163          	bltz	a0,80005e04 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005dc6:	f6840593          	addi	a1,s0,-152
    80005dca:	4509                	li	a0,2
    80005dcc:	ffffd097          	auipc	ra,0xffffd
    80005dd0:	2ec080e7          	jalr	748(ra) # 800030b8 <argint>
     argint(1, &major) < 0 ||
    80005dd4:	02054863          	bltz	a0,80005e04 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005dd8:	f6841683          	lh	a3,-152(s0)
    80005ddc:	f6c41603          	lh	a2,-148(s0)
    80005de0:	458d                	li	a1,3
    80005de2:	f7040513          	addi	a0,s0,-144
    80005de6:	fffff097          	auipc	ra,0xfffff
    80005dea:	776080e7          	jalr	1910(ra) # 8000555c <create>
     argint(2, &minor) < 0 ||
    80005dee:	c919                	beqz	a0,80005e04 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005df0:	ffffe097          	auipc	ra,0xffffe
    80005df4:	09c080e7          	jalr	156(ra) # 80003e8c <iunlockput>
  end_op();
    80005df8:	fffff097          	auipc	ra,0xfffff
    80005dfc:	884080e7          	jalr	-1916(ra) # 8000467c <end_op>
  return 0;
    80005e00:	4501                	li	a0,0
    80005e02:	a031                	j	80005e0e <sys_mknod+0x80>
    end_op();
    80005e04:	fffff097          	auipc	ra,0xfffff
    80005e08:	878080e7          	jalr	-1928(ra) # 8000467c <end_op>
    return -1;
    80005e0c:	557d                	li	a0,-1
}
    80005e0e:	60ea                	ld	ra,152(sp)
    80005e10:	644a                	ld	s0,144(sp)
    80005e12:	610d                	addi	sp,sp,160
    80005e14:	8082                	ret

0000000080005e16 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e16:	7135                	addi	sp,sp,-160
    80005e18:	ed06                	sd	ra,152(sp)
    80005e1a:	e922                	sd	s0,144(sp)
    80005e1c:	e526                	sd	s1,136(sp)
    80005e1e:	e14a                	sd	s2,128(sp)
    80005e20:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e22:	ffffc097          	auipc	ra,0xffffc
    80005e26:	f18080e7          	jalr	-232(ra) # 80001d3a <myproc>
    80005e2a:	892a                	mv	s2,a0
  
  begin_op();
    80005e2c:	ffffe097          	auipc	ra,0xffffe
    80005e30:	7d0080e7          	jalr	2000(ra) # 800045fc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e34:	08000613          	li	a2,128
    80005e38:	f6040593          	addi	a1,s0,-160
    80005e3c:	4501                	li	a0,0
    80005e3e:	ffffd097          	auipc	ra,0xffffd
    80005e42:	2be080e7          	jalr	702(ra) # 800030fc <argstr>
    80005e46:	04054b63          	bltz	a0,80005e9c <sys_chdir+0x86>
    80005e4a:	f6040513          	addi	a0,s0,-160
    80005e4e:	ffffe097          	auipc	ra,0xffffe
    80005e52:	592080e7          	jalr	1426(ra) # 800043e0 <namei>
    80005e56:	84aa                	mv	s1,a0
    80005e58:	c131                	beqz	a0,80005e9c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e5a:	ffffe097          	auipc	ra,0xffffe
    80005e5e:	dd0080e7          	jalr	-560(ra) # 80003c2a <ilock>
  if(ip->type != T_DIR){
    80005e62:	04449703          	lh	a4,68(s1)
    80005e66:	4785                	li	a5,1
    80005e68:	04f71063          	bne	a4,a5,80005ea8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e6c:	8526                	mv	a0,s1
    80005e6e:	ffffe097          	auipc	ra,0xffffe
    80005e72:	e7e080e7          	jalr	-386(ra) # 80003cec <iunlock>
  iput(p->cwd);
    80005e76:	15093503          	ld	a0,336(s2)
    80005e7a:	ffffe097          	auipc	ra,0xffffe
    80005e7e:	f6a080e7          	jalr	-150(ra) # 80003de4 <iput>
  end_op();
    80005e82:	ffffe097          	auipc	ra,0xffffe
    80005e86:	7fa080e7          	jalr	2042(ra) # 8000467c <end_op>
  p->cwd = ip;
    80005e8a:	14993823          	sd	s1,336(s2)
  return 0;
    80005e8e:	4501                	li	a0,0
}
    80005e90:	60ea                	ld	ra,152(sp)
    80005e92:	644a                	ld	s0,144(sp)
    80005e94:	64aa                	ld	s1,136(sp)
    80005e96:	690a                	ld	s2,128(sp)
    80005e98:	610d                	addi	sp,sp,160
    80005e9a:	8082                	ret
    end_op();
    80005e9c:	ffffe097          	auipc	ra,0xffffe
    80005ea0:	7e0080e7          	jalr	2016(ra) # 8000467c <end_op>
    return -1;
    80005ea4:	557d                	li	a0,-1
    80005ea6:	b7ed                	j	80005e90 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ea8:	8526                	mv	a0,s1
    80005eaa:	ffffe097          	auipc	ra,0xffffe
    80005eae:	fe2080e7          	jalr	-30(ra) # 80003e8c <iunlockput>
    end_op();
    80005eb2:	ffffe097          	auipc	ra,0xffffe
    80005eb6:	7ca080e7          	jalr	1994(ra) # 8000467c <end_op>
    return -1;
    80005eba:	557d                	li	a0,-1
    80005ebc:	bfd1                	j	80005e90 <sys_chdir+0x7a>

0000000080005ebe <sys_exec>:

uint64
sys_exec(void)
{
    80005ebe:	7145                	addi	sp,sp,-464
    80005ec0:	e786                	sd	ra,456(sp)
    80005ec2:	e3a2                	sd	s0,448(sp)
    80005ec4:	ff26                	sd	s1,440(sp)
    80005ec6:	fb4a                	sd	s2,432(sp)
    80005ec8:	f74e                	sd	s3,424(sp)
    80005eca:	f352                	sd	s4,416(sp)
    80005ecc:	ef56                	sd	s5,408(sp)
    80005ece:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ed0:	08000613          	li	a2,128
    80005ed4:	f4040593          	addi	a1,s0,-192
    80005ed8:	4501                	li	a0,0
    80005eda:	ffffd097          	auipc	ra,0xffffd
    80005ede:	222080e7          	jalr	546(ra) # 800030fc <argstr>
    return -1;
    80005ee2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ee4:	0c054a63          	bltz	a0,80005fb8 <sys_exec+0xfa>
    80005ee8:	e3840593          	addi	a1,s0,-456
    80005eec:	4505                	li	a0,1
    80005eee:	ffffd097          	auipc	ra,0xffffd
    80005ef2:	1ec080e7          	jalr	492(ra) # 800030da <argaddr>
    80005ef6:	0c054163          	bltz	a0,80005fb8 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005efa:	10000613          	li	a2,256
    80005efe:	4581                	li	a1,0
    80005f00:	e4040513          	addi	a0,s0,-448
    80005f04:	ffffb097          	auipc	ra,0xffffb
    80005f08:	ddc080e7          	jalr	-548(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f0c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f10:	89a6                	mv	s3,s1
    80005f12:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f14:	02000a13          	li	s4,32
    80005f18:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f1c:	00391513          	slli	a0,s2,0x3
    80005f20:	e3040593          	addi	a1,s0,-464
    80005f24:	e3843783          	ld	a5,-456(s0)
    80005f28:	953e                	add	a0,a0,a5
    80005f2a:	ffffd097          	auipc	ra,0xffffd
    80005f2e:	0f4080e7          	jalr	244(ra) # 8000301e <fetchaddr>
    80005f32:	02054a63          	bltz	a0,80005f66 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005f36:	e3043783          	ld	a5,-464(s0)
    80005f3a:	c3b9                	beqz	a5,80005f80 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f3c:	ffffb097          	auipc	ra,0xffffb
    80005f40:	bb8080e7          	jalr	-1096(ra) # 80000af4 <kalloc>
    80005f44:	85aa                	mv	a1,a0
    80005f46:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f4a:	cd11                	beqz	a0,80005f66 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f4c:	6605                	lui	a2,0x1
    80005f4e:	e3043503          	ld	a0,-464(s0)
    80005f52:	ffffd097          	auipc	ra,0xffffd
    80005f56:	11e080e7          	jalr	286(ra) # 80003070 <fetchstr>
    80005f5a:	00054663          	bltz	a0,80005f66 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005f5e:	0905                	addi	s2,s2,1
    80005f60:	09a1                	addi	s3,s3,8
    80005f62:	fb491be3          	bne	s2,s4,80005f18 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f66:	10048913          	addi	s2,s1,256
    80005f6a:	6088                	ld	a0,0(s1)
    80005f6c:	c529                	beqz	a0,80005fb6 <sys_exec+0xf8>
    kfree(argv[i]);
    80005f6e:	ffffb097          	auipc	ra,0xffffb
    80005f72:	a8a080e7          	jalr	-1398(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f76:	04a1                	addi	s1,s1,8
    80005f78:	ff2499e3          	bne	s1,s2,80005f6a <sys_exec+0xac>
  return -1;
    80005f7c:	597d                	li	s2,-1
    80005f7e:	a82d                	j	80005fb8 <sys_exec+0xfa>
      argv[i] = 0;
    80005f80:	0a8e                	slli	s5,s5,0x3
    80005f82:	fc040793          	addi	a5,s0,-64
    80005f86:	9abe                	add	s5,s5,a5
    80005f88:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005f8c:	e4040593          	addi	a1,s0,-448
    80005f90:	f4040513          	addi	a0,s0,-192
    80005f94:	fffff097          	auipc	ra,0xfffff
    80005f98:	194080e7          	jalr	404(ra) # 80005128 <exec>
    80005f9c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f9e:	10048993          	addi	s3,s1,256
    80005fa2:	6088                	ld	a0,0(s1)
    80005fa4:	c911                	beqz	a0,80005fb8 <sys_exec+0xfa>
    kfree(argv[i]);
    80005fa6:	ffffb097          	auipc	ra,0xffffb
    80005faa:	a52080e7          	jalr	-1454(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fae:	04a1                	addi	s1,s1,8
    80005fb0:	ff3499e3          	bne	s1,s3,80005fa2 <sys_exec+0xe4>
    80005fb4:	a011                	j	80005fb8 <sys_exec+0xfa>
  return -1;
    80005fb6:	597d                	li	s2,-1
}
    80005fb8:	854a                	mv	a0,s2
    80005fba:	60be                	ld	ra,456(sp)
    80005fbc:	641e                	ld	s0,448(sp)
    80005fbe:	74fa                	ld	s1,440(sp)
    80005fc0:	795a                	ld	s2,432(sp)
    80005fc2:	79ba                	ld	s3,424(sp)
    80005fc4:	7a1a                	ld	s4,416(sp)
    80005fc6:	6afa                	ld	s5,408(sp)
    80005fc8:	6179                	addi	sp,sp,464
    80005fca:	8082                	ret

0000000080005fcc <sys_pipe>:

uint64
sys_pipe(void)
{
    80005fcc:	7139                	addi	sp,sp,-64
    80005fce:	fc06                	sd	ra,56(sp)
    80005fd0:	f822                	sd	s0,48(sp)
    80005fd2:	f426                	sd	s1,40(sp)
    80005fd4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005fd6:	ffffc097          	auipc	ra,0xffffc
    80005fda:	d64080e7          	jalr	-668(ra) # 80001d3a <myproc>
    80005fde:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005fe0:	fd840593          	addi	a1,s0,-40
    80005fe4:	4501                	li	a0,0
    80005fe6:	ffffd097          	auipc	ra,0xffffd
    80005fea:	0f4080e7          	jalr	244(ra) # 800030da <argaddr>
    return -1;
    80005fee:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ff0:	0e054063          	bltz	a0,800060d0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ff4:	fc840593          	addi	a1,s0,-56
    80005ff8:	fd040513          	addi	a0,s0,-48
    80005ffc:	fffff097          	auipc	ra,0xfffff
    80006000:	dfc080e7          	jalr	-516(ra) # 80004df8 <pipealloc>
    return -1;
    80006004:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006006:	0c054563          	bltz	a0,800060d0 <sys_pipe+0x104>
  fd0 = -1;
    8000600a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000600e:	fd043503          	ld	a0,-48(s0)
    80006012:	fffff097          	auipc	ra,0xfffff
    80006016:	508080e7          	jalr	1288(ra) # 8000551a <fdalloc>
    8000601a:	fca42223          	sw	a0,-60(s0)
    8000601e:	08054c63          	bltz	a0,800060b6 <sys_pipe+0xea>
    80006022:	fc843503          	ld	a0,-56(s0)
    80006026:	fffff097          	auipc	ra,0xfffff
    8000602a:	4f4080e7          	jalr	1268(ra) # 8000551a <fdalloc>
    8000602e:	fca42023          	sw	a0,-64(s0)
    80006032:	06054863          	bltz	a0,800060a2 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006036:	4691                	li	a3,4
    80006038:	fc440613          	addi	a2,s0,-60
    8000603c:	fd843583          	ld	a1,-40(s0)
    80006040:	68a8                	ld	a0,80(s1)
    80006042:	ffffb097          	auipc	ra,0xffffb
    80006046:	630080e7          	jalr	1584(ra) # 80001672 <copyout>
    8000604a:	02054063          	bltz	a0,8000606a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000604e:	4691                	li	a3,4
    80006050:	fc040613          	addi	a2,s0,-64
    80006054:	fd843583          	ld	a1,-40(s0)
    80006058:	0591                	addi	a1,a1,4
    8000605a:	68a8                	ld	a0,80(s1)
    8000605c:	ffffb097          	auipc	ra,0xffffb
    80006060:	616080e7          	jalr	1558(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006064:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006066:	06055563          	bgez	a0,800060d0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000606a:	fc442783          	lw	a5,-60(s0)
    8000606e:	07e9                	addi	a5,a5,26
    80006070:	078e                	slli	a5,a5,0x3
    80006072:	97a6                	add	a5,a5,s1
    80006074:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006078:	fc042503          	lw	a0,-64(s0)
    8000607c:	0569                	addi	a0,a0,26
    8000607e:	050e                	slli	a0,a0,0x3
    80006080:	9526                	add	a0,a0,s1
    80006082:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006086:	fd043503          	ld	a0,-48(s0)
    8000608a:	fffff097          	auipc	ra,0xfffff
    8000608e:	a3e080e7          	jalr	-1474(ra) # 80004ac8 <fileclose>
    fileclose(wf);
    80006092:	fc843503          	ld	a0,-56(s0)
    80006096:	fffff097          	auipc	ra,0xfffff
    8000609a:	a32080e7          	jalr	-1486(ra) # 80004ac8 <fileclose>
    return -1;
    8000609e:	57fd                	li	a5,-1
    800060a0:	a805                	j	800060d0 <sys_pipe+0x104>
    if(fd0 >= 0)
    800060a2:	fc442783          	lw	a5,-60(s0)
    800060a6:	0007c863          	bltz	a5,800060b6 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800060aa:	01a78513          	addi	a0,a5,26
    800060ae:	050e                	slli	a0,a0,0x3
    800060b0:	9526                	add	a0,a0,s1
    800060b2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800060b6:	fd043503          	ld	a0,-48(s0)
    800060ba:	fffff097          	auipc	ra,0xfffff
    800060be:	a0e080e7          	jalr	-1522(ra) # 80004ac8 <fileclose>
    fileclose(wf);
    800060c2:	fc843503          	ld	a0,-56(s0)
    800060c6:	fffff097          	auipc	ra,0xfffff
    800060ca:	a02080e7          	jalr	-1534(ra) # 80004ac8 <fileclose>
    return -1;
    800060ce:	57fd                	li	a5,-1
}
    800060d0:	853e                	mv	a0,a5
    800060d2:	70e2                	ld	ra,56(sp)
    800060d4:	7442                	ld	s0,48(sp)
    800060d6:	74a2                	ld	s1,40(sp)
    800060d8:	6121                	addi	sp,sp,64
    800060da:	8082                	ret
    800060dc:	0000                	unimp
	...

00000000800060e0 <kernelvec>:
    800060e0:	7111                	addi	sp,sp,-256
    800060e2:	e006                	sd	ra,0(sp)
    800060e4:	e40a                	sd	sp,8(sp)
    800060e6:	e80e                	sd	gp,16(sp)
    800060e8:	ec12                	sd	tp,24(sp)
    800060ea:	f016                	sd	t0,32(sp)
    800060ec:	f41a                	sd	t1,40(sp)
    800060ee:	f81e                	sd	t2,48(sp)
    800060f0:	fc22                	sd	s0,56(sp)
    800060f2:	e0a6                	sd	s1,64(sp)
    800060f4:	e4aa                	sd	a0,72(sp)
    800060f6:	e8ae                	sd	a1,80(sp)
    800060f8:	ecb2                	sd	a2,88(sp)
    800060fa:	f0b6                	sd	a3,96(sp)
    800060fc:	f4ba                	sd	a4,104(sp)
    800060fe:	f8be                	sd	a5,112(sp)
    80006100:	fcc2                	sd	a6,120(sp)
    80006102:	e146                	sd	a7,128(sp)
    80006104:	e54a                	sd	s2,136(sp)
    80006106:	e94e                	sd	s3,144(sp)
    80006108:	ed52                	sd	s4,152(sp)
    8000610a:	f156                	sd	s5,160(sp)
    8000610c:	f55a                	sd	s6,168(sp)
    8000610e:	f95e                	sd	s7,176(sp)
    80006110:	fd62                	sd	s8,184(sp)
    80006112:	e1e6                	sd	s9,192(sp)
    80006114:	e5ea                	sd	s10,200(sp)
    80006116:	e9ee                	sd	s11,208(sp)
    80006118:	edf2                	sd	t3,216(sp)
    8000611a:	f1f6                	sd	t4,224(sp)
    8000611c:	f5fa                	sd	t5,232(sp)
    8000611e:	f9fe                	sd	t6,240(sp)
    80006120:	dcbfc0ef          	jal	ra,80002eea <kerneltrap>
    80006124:	6082                	ld	ra,0(sp)
    80006126:	6122                	ld	sp,8(sp)
    80006128:	61c2                	ld	gp,16(sp)
    8000612a:	7282                	ld	t0,32(sp)
    8000612c:	7322                	ld	t1,40(sp)
    8000612e:	73c2                	ld	t2,48(sp)
    80006130:	7462                	ld	s0,56(sp)
    80006132:	6486                	ld	s1,64(sp)
    80006134:	6526                	ld	a0,72(sp)
    80006136:	65c6                	ld	a1,80(sp)
    80006138:	6666                	ld	a2,88(sp)
    8000613a:	7686                	ld	a3,96(sp)
    8000613c:	7726                	ld	a4,104(sp)
    8000613e:	77c6                	ld	a5,112(sp)
    80006140:	7866                	ld	a6,120(sp)
    80006142:	688a                	ld	a7,128(sp)
    80006144:	692a                	ld	s2,136(sp)
    80006146:	69ca                	ld	s3,144(sp)
    80006148:	6a6a                	ld	s4,152(sp)
    8000614a:	7a8a                	ld	s5,160(sp)
    8000614c:	7b2a                	ld	s6,168(sp)
    8000614e:	7bca                	ld	s7,176(sp)
    80006150:	7c6a                	ld	s8,184(sp)
    80006152:	6c8e                	ld	s9,192(sp)
    80006154:	6d2e                	ld	s10,200(sp)
    80006156:	6dce                	ld	s11,208(sp)
    80006158:	6e6e                	ld	t3,216(sp)
    8000615a:	7e8e                	ld	t4,224(sp)
    8000615c:	7f2e                	ld	t5,232(sp)
    8000615e:	7fce                	ld	t6,240(sp)
    80006160:	6111                	addi	sp,sp,256
    80006162:	10200073          	sret
    80006166:	00000013          	nop
    8000616a:	00000013          	nop
    8000616e:	0001                	nop

0000000080006170 <timervec>:
    80006170:	34051573          	csrrw	a0,mscratch,a0
    80006174:	e10c                	sd	a1,0(a0)
    80006176:	e510                	sd	a2,8(a0)
    80006178:	e914                	sd	a3,16(a0)
    8000617a:	6d0c                	ld	a1,24(a0)
    8000617c:	7110                	ld	a2,32(a0)
    8000617e:	6194                	ld	a3,0(a1)
    80006180:	96b2                	add	a3,a3,a2
    80006182:	e194                	sd	a3,0(a1)
    80006184:	4589                	li	a1,2
    80006186:	14459073          	csrw	sip,a1
    8000618a:	6914                	ld	a3,16(a0)
    8000618c:	6510                	ld	a2,8(a0)
    8000618e:	610c                	ld	a1,0(a0)
    80006190:	34051573          	csrrw	a0,mscratch,a0
    80006194:	30200073          	mret
	...

000000008000619a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000619a:	1141                	addi	sp,sp,-16
    8000619c:	e422                	sd	s0,8(sp)
    8000619e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800061a0:	0c0007b7          	lui	a5,0xc000
    800061a4:	4705                	li	a4,1
    800061a6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800061a8:	c3d8                	sw	a4,4(a5)
}
    800061aa:	6422                	ld	s0,8(sp)
    800061ac:	0141                	addi	sp,sp,16
    800061ae:	8082                	ret

00000000800061b0 <plicinithart>:

void
plicinithart(void)
{
    800061b0:	1141                	addi	sp,sp,-16
    800061b2:	e406                	sd	ra,8(sp)
    800061b4:	e022                	sd	s0,0(sp)
    800061b6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061b8:	ffffc097          	auipc	ra,0xffffc
    800061bc:	b50080e7          	jalr	-1200(ra) # 80001d08 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800061c0:	0085171b          	slliw	a4,a0,0x8
    800061c4:	0c0027b7          	lui	a5,0xc002
    800061c8:	97ba                	add	a5,a5,a4
    800061ca:	40200713          	li	a4,1026
    800061ce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800061d2:	00d5151b          	slliw	a0,a0,0xd
    800061d6:	0c2017b7          	lui	a5,0xc201
    800061da:	953e                	add	a0,a0,a5
    800061dc:	00052023          	sw	zero,0(a0)
}
    800061e0:	60a2                	ld	ra,8(sp)
    800061e2:	6402                	ld	s0,0(sp)
    800061e4:	0141                	addi	sp,sp,16
    800061e6:	8082                	ret

00000000800061e8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800061e8:	1141                	addi	sp,sp,-16
    800061ea:	e406                	sd	ra,8(sp)
    800061ec:	e022                	sd	s0,0(sp)
    800061ee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061f0:	ffffc097          	auipc	ra,0xffffc
    800061f4:	b18080e7          	jalr	-1256(ra) # 80001d08 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800061f8:	00d5179b          	slliw	a5,a0,0xd
    800061fc:	0c201537          	lui	a0,0xc201
    80006200:	953e                	add	a0,a0,a5
  return irq;
}
    80006202:	4148                	lw	a0,4(a0)
    80006204:	60a2                	ld	ra,8(sp)
    80006206:	6402                	ld	s0,0(sp)
    80006208:	0141                	addi	sp,sp,16
    8000620a:	8082                	ret

000000008000620c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000620c:	1101                	addi	sp,sp,-32
    8000620e:	ec06                	sd	ra,24(sp)
    80006210:	e822                	sd	s0,16(sp)
    80006212:	e426                	sd	s1,8(sp)
    80006214:	1000                	addi	s0,sp,32
    80006216:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006218:	ffffc097          	auipc	ra,0xffffc
    8000621c:	af0080e7          	jalr	-1296(ra) # 80001d08 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006220:	00d5151b          	slliw	a0,a0,0xd
    80006224:	0c2017b7          	lui	a5,0xc201
    80006228:	97aa                	add	a5,a5,a0
    8000622a:	c3c4                	sw	s1,4(a5)
}
    8000622c:	60e2                	ld	ra,24(sp)
    8000622e:	6442                	ld	s0,16(sp)
    80006230:	64a2                	ld	s1,8(sp)
    80006232:	6105                	addi	sp,sp,32
    80006234:	8082                	ret

0000000080006236 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006236:	1141                	addi	sp,sp,-16
    80006238:	e406                	sd	ra,8(sp)
    8000623a:	e022                	sd	s0,0(sp)
    8000623c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000623e:	479d                	li	a5,7
    80006240:	06a7c963          	blt	a5,a0,800062b2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006244:	0001d797          	auipc	a5,0x1d
    80006248:	dbc78793          	addi	a5,a5,-580 # 80023000 <disk>
    8000624c:	00a78733          	add	a4,a5,a0
    80006250:	6789                	lui	a5,0x2
    80006252:	97ba                	add	a5,a5,a4
    80006254:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006258:	e7ad                	bnez	a5,800062c2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000625a:	00451793          	slli	a5,a0,0x4
    8000625e:	0001f717          	auipc	a4,0x1f
    80006262:	da270713          	addi	a4,a4,-606 # 80025000 <disk+0x2000>
    80006266:	6314                	ld	a3,0(a4)
    80006268:	96be                	add	a3,a3,a5
    8000626a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000626e:	6314                	ld	a3,0(a4)
    80006270:	96be                	add	a3,a3,a5
    80006272:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006276:	6314                	ld	a3,0(a4)
    80006278:	96be                	add	a3,a3,a5
    8000627a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000627e:	6318                	ld	a4,0(a4)
    80006280:	97ba                	add	a5,a5,a4
    80006282:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006286:	0001d797          	auipc	a5,0x1d
    8000628a:	d7a78793          	addi	a5,a5,-646 # 80023000 <disk>
    8000628e:	97aa                	add	a5,a5,a0
    80006290:	6509                	lui	a0,0x2
    80006292:	953e                	add	a0,a0,a5
    80006294:	4785                	li	a5,1
    80006296:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000629a:	0001f517          	auipc	a0,0x1f
    8000629e:	d7e50513          	addi	a0,a0,-642 # 80025018 <disk+0x2018>
    800062a2:	ffffc097          	auipc	ra,0xffffc
    800062a6:	43e080e7          	jalr	1086(ra) # 800026e0 <wakeup>
}
    800062aa:	60a2                	ld	ra,8(sp)
    800062ac:	6402                	ld	s0,0(sp)
    800062ae:	0141                	addi	sp,sp,16
    800062b0:	8082                	ret
    panic("free_desc 1");
    800062b2:	00002517          	auipc	a0,0x2
    800062b6:	53e50513          	addi	a0,a0,1342 # 800087f0 <syscalls+0x320>
    800062ba:	ffffa097          	auipc	ra,0xffffa
    800062be:	284080e7          	jalr	644(ra) # 8000053e <panic>
    panic("free_desc 2");
    800062c2:	00002517          	auipc	a0,0x2
    800062c6:	53e50513          	addi	a0,a0,1342 # 80008800 <syscalls+0x330>
    800062ca:	ffffa097          	auipc	ra,0xffffa
    800062ce:	274080e7          	jalr	628(ra) # 8000053e <panic>

00000000800062d2 <virtio_disk_init>:
{
    800062d2:	1101                	addi	sp,sp,-32
    800062d4:	ec06                	sd	ra,24(sp)
    800062d6:	e822                	sd	s0,16(sp)
    800062d8:	e426                	sd	s1,8(sp)
    800062da:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800062dc:	00002597          	auipc	a1,0x2
    800062e0:	53458593          	addi	a1,a1,1332 # 80008810 <syscalls+0x340>
    800062e4:	0001f517          	auipc	a0,0x1f
    800062e8:	e4450513          	addi	a0,a0,-444 # 80025128 <disk+0x2128>
    800062ec:	ffffb097          	auipc	ra,0xffffb
    800062f0:	868080e7          	jalr	-1944(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062f4:	100017b7          	lui	a5,0x10001
    800062f8:	4398                	lw	a4,0(a5)
    800062fa:	2701                	sext.w	a4,a4
    800062fc:	747277b7          	lui	a5,0x74727
    80006300:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006304:	0ef71163          	bne	a4,a5,800063e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006308:	100017b7          	lui	a5,0x10001
    8000630c:	43dc                	lw	a5,4(a5)
    8000630e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006310:	4705                	li	a4,1
    80006312:	0ce79a63          	bne	a5,a4,800063e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006316:	100017b7          	lui	a5,0x10001
    8000631a:	479c                	lw	a5,8(a5)
    8000631c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000631e:	4709                	li	a4,2
    80006320:	0ce79363          	bne	a5,a4,800063e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006324:	100017b7          	lui	a5,0x10001
    80006328:	47d8                	lw	a4,12(a5)
    8000632a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000632c:	554d47b7          	lui	a5,0x554d4
    80006330:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006334:	0af71963          	bne	a4,a5,800063e6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006338:	100017b7          	lui	a5,0x10001
    8000633c:	4705                	li	a4,1
    8000633e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006340:	470d                	li	a4,3
    80006342:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006344:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006346:	c7ffe737          	lui	a4,0xc7ffe
    8000634a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000634e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006350:	2701                	sext.w	a4,a4
    80006352:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006354:	472d                	li	a4,11
    80006356:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006358:	473d                	li	a4,15
    8000635a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000635c:	6705                	lui	a4,0x1
    8000635e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006360:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006364:	5bdc                	lw	a5,52(a5)
    80006366:	2781                	sext.w	a5,a5
  if(max == 0)
    80006368:	c7d9                	beqz	a5,800063f6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000636a:	471d                	li	a4,7
    8000636c:	08f77d63          	bgeu	a4,a5,80006406 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006370:	100014b7          	lui	s1,0x10001
    80006374:	47a1                	li	a5,8
    80006376:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006378:	6609                	lui	a2,0x2
    8000637a:	4581                	li	a1,0
    8000637c:	0001d517          	auipc	a0,0x1d
    80006380:	c8450513          	addi	a0,a0,-892 # 80023000 <disk>
    80006384:	ffffb097          	auipc	ra,0xffffb
    80006388:	95c080e7          	jalr	-1700(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000638c:	0001d717          	auipc	a4,0x1d
    80006390:	c7470713          	addi	a4,a4,-908 # 80023000 <disk>
    80006394:	00c75793          	srli	a5,a4,0xc
    80006398:	2781                	sext.w	a5,a5
    8000639a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000639c:	0001f797          	auipc	a5,0x1f
    800063a0:	c6478793          	addi	a5,a5,-924 # 80025000 <disk+0x2000>
    800063a4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800063a6:	0001d717          	auipc	a4,0x1d
    800063aa:	cda70713          	addi	a4,a4,-806 # 80023080 <disk+0x80>
    800063ae:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800063b0:	0001e717          	auipc	a4,0x1e
    800063b4:	c5070713          	addi	a4,a4,-944 # 80024000 <disk+0x1000>
    800063b8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800063ba:	4705                	li	a4,1
    800063bc:	00e78c23          	sb	a4,24(a5)
    800063c0:	00e78ca3          	sb	a4,25(a5)
    800063c4:	00e78d23          	sb	a4,26(a5)
    800063c8:	00e78da3          	sb	a4,27(a5)
    800063cc:	00e78e23          	sb	a4,28(a5)
    800063d0:	00e78ea3          	sb	a4,29(a5)
    800063d4:	00e78f23          	sb	a4,30(a5)
    800063d8:	00e78fa3          	sb	a4,31(a5)
}
    800063dc:	60e2                	ld	ra,24(sp)
    800063de:	6442                	ld	s0,16(sp)
    800063e0:	64a2                	ld	s1,8(sp)
    800063e2:	6105                	addi	sp,sp,32
    800063e4:	8082                	ret
    panic("could not find virtio disk");
    800063e6:	00002517          	auipc	a0,0x2
    800063ea:	43a50513          	addi	a0,a0,1082 # 80008820 <syscalls+0x350>
    800063ee:	ffffa097          	auipc	ra,0xffffa
    800063f2:	150080e7          	jalr	336(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800063f6:	00002517          	auipc	a0,0x2
    800063fa:	44a50513          	addi	a0,a0,1098 # 80008840 <syscalls+0x370>
    800063fe:	ffffa097          	auipc	ra,0xffffa
    80006402:	140080e7          	jalr	320(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006406:	00002517          	auipc	a0,0x2
    8000640a:	45a50513          	addi	a0,a0,1114 # 80008860 <syscalls+0x390>
    8000640e:	ffffa097          	auipc	ra,0xffffa
    80006412:	130080e7          	jalr	304(ra) # 8000053e <panic>

0000000080006416 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006416:	7159                	addi	sp,sp,-112
    80006418:	f486                	sd	ra,104(sp)
    8000641a:	f0a2                	sd	s0,96(sp)
    8000641c:	eca6                	sd	s1,88(sp)
    8000641e:	e8ca                	sd	s2,80(sp)
    80006420:	e4ce                	sd	s3,72(sp)
    80006422:	e0d2                	sd	s4,64(sp)
    80006424:	fc56                	sd	s5,56(sp)
    80006426:	f85a                	sd	s6,48(sp)
    80006428:	f45e                	sd	s7,40(sp)
    8000642a:	f062                	sd	s8,32(sp)
    8000642c:	ec66                	sd	s9,24(sp)
    8000642e:	e86a                	sd	s10,16(sp)
    80006430:	1880                	addi	s0,sp,112
    80006432:	892a                	mv	s2,a0
    80006434:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006436:	00c52c83          	lw	s9,12(a0)
    8000643a:	001c9c9b          	slliw	s9,s9,0x1
    8000643e:	1c82                	slli	s9,s9,0x20
    80006440:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006444:	0001f517          	auipc	a0,0x1f
    80006448:	ce450513          	addi	a0,a0,-796 # 80025128 <disk+0x2128>
    8000644c:	ffffa097          	auipc	ra,0xffffa
    80006450:	798080e7          	jalr	1944(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006454:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006456:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006458:	0001db97          	auipc	s7,0x1d
    8000645c:	ba8b8b93          	addi	s7,s7,-1112 # 80023000 <disk>
    80006460:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006462:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006464:	8a4e                	mv	s4,s3
    80006466:	a051                	j	800064ea <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006468:	00fb86b3          	add	a3,s7,a5
    8000646c:	96da                	add	a3,a3,s6
    8000646e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006472:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006474:	0207c563          	bltz	a5,8000649e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006478:	2485                	addiw	s1,s1,1
    8000647a:	0711                	addi	a4,a4,4
    8000647c:	25548063          	beq	s1,s5,800066bc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006480:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006482:	0001f697          	auipc	a3,0x1f
    80006486:	b9668693          	addi	a3,a3,-1130 # 80025018 <disk+0x2018>
    8000648a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000648c:	0006c583          	lbu	a1,0(a3)
    80006490:	fde1                	bnez	a1,80006468 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006492:	2785                	addiw	a5,a5,1
    80006494:	0685                	addi	a3,a3,1
    80006496:	ff879be3          	bne	a5,s8,8000648c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000649a:	57fd                	li	a5,-1
    8000649c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000649e:	02905a63          	blez	s1,800064d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800064a2:	f9042503          	lw	a0,-112(s0)
    800064a6:	00000097          	auipc	ra,0x0
    800064aa:	d90080e7          	jalr	-624(ra) # 80006236 <free_desc>
      for(int j = 0; j < i; j++)
    800064ae:	4785                	li	a5,1
    800064b0:	0297d163          	bge	a5,s1,800064d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800064b4:	f9442503          	lw	a0,-108(s0)
    800064b8:	00000097          	auipc	ra,0x0
    800064bc:	d7e080e7          	jalr	-642(ra) # 80006236 <free_desc>
      for(int j = 0; j < i; j++)
    800064c0:	4789                	li	a5,2
    800064c2:	0097d863          	bge	a5,s1,800064d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800064c6:	f9842503          	lw	a0,-104(s0)
    800064ca:	00000097          	auipc	ra,0x0
    800064ce:	d6c080e7          	jalr	-660(ra) # 80006236 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064d2:	0001f597          	auipc	a1,0x1f
    800064d6:	c5658593          	addi	a1,a1,-938 # 80025128 <disk+0x2128>
    800064da:	0001f517          	auipc	a0,0x1f
    800064de:	b3e50513          	addi	a0,a0,-1218 # 80025018 <disk+0x2018>
    800064e2:	ffffc097          	auipc	ra,0xffffc
    800064e6:	060080e7          	jalr	96(ra) # 80002542 <sleep>
  for(int i = 0; i < 3; i++){
    800064ea:	f9040713          	addi	a4,s0,-112
    800064ee:	84ce                	mv	s1,s3
    800064f0:	bf41                	j	80006480 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800064f2:	20058713          	addi	a4,a1,512
    800064f6:	00471693          	slli	a3,a4,0x4
    800064fa:	0001d717          	auipc	a4,0x1d
    800064fe:	b0670713          	addi	a4,a4,-1274 # 80023000 <disk>
    80006502:	9736                	add	a4,a4,a3
    80006504:	4685                	li	a3,1
    80006506:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000650a:	20058713          	addi	a4,a1,512
    8000650e:	00471693          	slli	a3,a4,0x4
    80006512:	0001d717          	auipc	a4,0x1d
    80006516:	aee70713          	addi	a4,a4,-1298 # 80023000 <disk>
    8000651a:	9736                	add	a4,a4,a3
    8000651c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006520:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006524:	7679                	lui	a2,0xffffe
    80006526:	963e                	add	a2,a2,a5
    80006528:	0001f697          	auipc	a3,0x1f
    8000652c:	ad868693          	addi	a3,a3,-1320 # 80025000 <disk+0x2000>
    80006530:	6298                	ld	a4,0(a3)
    80006532:	9732                	add	a4,a4,a2
    80006534:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006536:	6298                	ld	a4,0(a3)
    80006538:	9732                	add	a4,a4,a2
    8000653a:	4541                	li	a0,16
    8000653c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000653e:	6298                	ld	a4,0(a3)
    80006540:	9732                	add	a4,a4,a2
    80006542:	4505                	li	a0,1
    80006544:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006548:	f9442703          	lw	a4,-108(s0)
    8000654c:	6288                	ld	a0,0(a3)
    8000654e:	962a                	add	a2,a2,a0
    80006550:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006554:	0712                	slli	a4,a4,0x4
    80006556:	6290                	ld	a2,0(a3)
    80006558:	963a                	add	a2,a2,a4
    8000655a:	05890513          	addi	a0,s2,88
    8000655e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006560:	6294                	ld	a3,0(a3)
    80006562:	96ba                	add	a3,a3,a4
    80006564:	40000613          	li	a2,1024
    80006568:	c690                	sw	a2,8(a3)
  if(write)
    8000656a:	140d0063          	beqz	s10,800066aa <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000656e:	0001f697          	auipc	a3,0x1f
    80006572:	a926b683          	ld	a3,-1390(a3) # 80025000 <disk+0x2000>
    80006576:	96ba                	add	a3,a3,a4
    80006578:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000657c:	0001d817          	auipc	a6,0x1d
    80006580:	a8480813          	addi	a6,a6,-1404 # 80023000 <disk>
    80006584:	0001f517          	auipc	a0,0x1f
    80006588:	a7c50513          	addi	a0,a0,-1412 # 80025000 <disk+0x2000>
    8000658c:	6114                	ld	a3,0(a0)
    8000658e:	96ba                	add	a3,a3,a4
    80006590:	00c6d603          	lhu	a2,12(a3)
    80006594:	00166613          	ori	a2,a2,1
    80006598:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000659c:	f9842683          	lw	a3,-104(s0)
    800065a0:	6110                	ld	a2,0(a0)
    800065a2:	9732                	add	a4,a4,a2
    800065a4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800065a8:	20058613          	addi	a2,a1,512
    800065ac:	0612                	slli	a2,a2,0x4
    800065ae:	9642                	add	a2,a2,a6
    800065b0:	577d                	li	a4,-1
    800065b2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800065b6:	00469713          	slli	a4,a3,0x4
    800065ba:	6114                	ld	a3,0(a0)
    800065bc:	96ba                	add	a3,a3,a4
    800065be:	03078793          	addi	a5,a5,48
    800065c2:	97c2                	add	a5,a5,a6
    800065c4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800065c6:	611c                	ld	a5,0(a0)
    800065c8:	97ba                	add	a5,a5,a4
    800065ca:	4685                	li	a3,1
    800065cc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800065ce:	611c                	ld	a5,0(a0)
    800065d0:	97ba                	add	a5,a5,a4
    800065d2:	4809                	li	a6,2
    800065d4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800065d8:	611c                	ld	a5,0(a0)
    800065da:	973e                	add	a4,a4,a5
    800065dc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800065e0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800065e4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800065e8:	6518                	ld	a4,8(a0)
    800065ea:	00275783          	lhu	a5,2(a4)
    800065ee:	8b9d                	andi	a5,a5,7
    800065f0:	0786                	slli	a5,a5,0x1
    800065f2:	97ba                	add	a5,a5,a4
    800065f4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800065f8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065fc:	6518                	ld	a4,8(a0)
    800065fe:	00275783          	lhu	a5,2(a4)
    80006602:	2785                	addiw	a5,a5,1
    80006604:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006608:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000660c:	100017b7          	lui	a5,0x10001
    80006610:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006614:	00492703          	lw	a4,4(s2)
    80006618:	4785                	li	a5,1
    8000661a:	02f71163          	bne	a4,a5,8000663c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000661e:	0001f997          	auipc	s3,0x1f
    80006622:	b0a98993          	addi	s3,s3,-1270 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006626:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006628:	85ce                	mv	a1,s3
    8000662a:	854a                	mv	a0,s2
    8000662c:	ffffc097          	auipc	ra,0xffffc
    80006630:	f16080e7          	jalr	-234(ra) # 80002542 <sleep>
  while(b->disk == 1) {
    80006634:	00492783          	lw	a5,4(s2)
    80006638:	fe9788e3          	beq	a5,s1,80006628 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000663c:	f9042903          	lw	s2,-112(s0)
    80006640:	20090793          	addi	a5,s2,512
    80006644:	00479713          	slli	a4,a5,0x4
    80006648:	0001d797          	auipc	a5,0x1d
    8000664c:	9b878793          	addi	a5,a5,-1608 # 80023000 <disk>
    80006650:	97ba                	add	a5,a5,a4
    80006652:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006656:	0001f997          	auipc	s3,0x1f
    8000665a:	9aa98993          	addi	s3,s3,-1622 # 80025000 <disk+0x2000>
    8000665e:	00491713          	slli	a4,s2,0x4
    80006662:	0009b783          	ld	a5,0(s3)
    80006666:	97ba                	add	a5,a5,a4
    80006668:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000666c:	854a                	mv	a0,s2
    8000666e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006672:	00000097          	auipc	ra,0x0
    80006676:	bc4080e7          	jalr	-1084(ra) # 80006236 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000667a:	8885                	andi	s1,s1,1
    8000667c:	f0ed                	bnez	s1,8000665e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000667e:	0001f517          	auipc	a0,0x1f
    80006682:	aaa50513          	addi	a0,a0,-1366 # 80025128 <disk+0x2128>
    80006686:	ffffa097          	auipc	ra,0xffffa
    8000668a:	612080e7          	jalr	1554(ra) # 80000c98 <release>
}
    8000668e:	70a6                	ld	ra,104(sp)
    80006690:	7406                	ld	s0,96(sp)
    80006692:	64e6                	ld	s1,88(sp)
    80006694:	6946                	ld	s2,80(sp)
    80006696:	69a6                	ld	s3,72(sp)
    80006698:	6a06                	ld	s4,64(sp)
    8000669a:	7ae2                	ld	s5,56(sp)
    8000669c:	7b42                	ld	s6,48(sp)
    8000669e:	7ba2                	ld	s7,40(sp)
    800066a0:	7c02                	ld	s8,32(sp)
    800066a2:	6ce2                	ld	s9,24(sp)
    800066a4:	6d42                	ld	s10,16(sp)
    800066a6:	6165                	addi	sp,sp,112
    800066a8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800066aa:	0001f697          	auipc	a3,0x1f
    800066ae:	9566b683          	ld	a3,-1706(a3) # 80025000 <disk+0x2000>
    800066b2:	96ba                	add	a3,a3,a4
    800066b4:	4609                	li	a2,2
    800066b6:	00c69623          	sh	a2,12(a3)
    800066ba:	b5c9                	j	8000657c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066bc:	f9042583          	lw	a1,-112(s0)
    800066c0:	20058793          	addi	a5,a1,512
    800066c4:	0792                	slli	a5,a5,0x4
    800066c6:	0001d517          	auipc	a0,0x1d
    800066ca:	9e250513          	addi	a0,a0,-1566 # 800230a8 <disk+0xa8>
    800066ce:	953e                	add	a0,a0,a5
  if(write)
    800066d0:	e20d11e3          	bnez	s10,800064f2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800066d4:	20058713          	addi	a4,a1,512
    800066d8:	00471693          	slli	a3,a4,0x4
    800066dc:	0001d717          	auipc	a4,0x1d
    800066e0:	92470713          	addi	a4,a4,-1756 # 80023000 <disk>
    800066e4:	9736                	add	a4,a4,a3
    800066e6:	0a072423          	sw	zero,168(a4)
    800066ea:	b505                	j	8000650a <virtio_disk_rw+0xf4>

00000000800066ec <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800066ec:	1101                	addi	sp,sp,-32
    800066ee:	ec06                	sd	ra,24(sp)
    800066f0:	e822                	sd	s0,16(sp)
    800066f2:	e426                	sd	s1,8(sp)
    800066f4:	e04a                	sd	s2,0(sp)
    800066f6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800066f8:	0001f517          	auipc	a0,0x1f
    800066fc:	a3050513          	addi	a0,a0,-1488 # 80025128 <disk+0x2128>
    80006700:	ffffa097          	auipc	ra,0xffffa
    80006704:	4e4080e7          	jalr	1252(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006708:	10001737          	lui	a4,0x10001
    8000670c:	533c                	lw	a5,96(a4)
    8000670e:	8b8d                	andi	a5,a5,3
    80006710:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006712:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006716:	0001f797          	auipc	a5,0x1f
    8000671a:	8ea78793          	addi	a5,a5,-1814 # 80025000 <disk+0x2000>
    8000671e:	6b94                	ld	a3,16(a5)
    80006720:	0207d703          	lhu	a4,32(a5)
    80006724:	0026d783          	lhu	a5,2(a3)
    80006728:	06f70163          	beq	a4,a5,8000678a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000672c:	0001d917          	auipc	s2,0x1d
    80006730:	8d490913          	addi	s2,s2,-1836 # 80023000 <disk>
    80006734:	0001f497          	auipc	s1,0x1f
    80006738:	8cc48493          	addi	s1,s1,-1844 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000673c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006740:	6898                	ld	a4,16(s1)
    80006742:	0204d783          	lhu	a5,32(s1)
    80006746:	8b9d                	andi	a5,a5,7
    80006748:	078e                	slli	a5,a5,0x3
    8000674a:	97ba                	add	a5,a5,a4
    8000674c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000674e:	20078713          	addi	a4,a5,512
    80006752:	0712                	slli	a4,a4,0x4
    80006754:	974a                	add	a4,a4,s2
    80006756:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000675a:	e731                	bnez	a4,800067a6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000675c:	20078793          	addi	a5,a5,512
    80006760:	0792                	slli	a5,a5,0x4
    80006762:	97ca                	add	a5,a5,s2
    80006764:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006766:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000676a:	ffffc097          	auipc	ra,0xffffc
    8000676e:	f76080e7          	jalr	-138(ra) # 800026e0 <wakeup>

    disk.used_idx += 1;
    80006772:	0204d783          	lhu	a5,32(s1)
    80006776:	2785                	addiw	a5,a5,1
    80006778:	17c2                	slli	a5,a5,0x30
    8000677a:	93c1                	srli	a5,a5,0x30
    8000677c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006780:	6898                	ld	a4,16(s1)
    80006782:	00275703          	lhu	a4,2(a4)
    80006786:	faf71be3          	bne	a4,a5,8000673c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000678a:	0001f517          	auipc	a0,0x1f
    8000678e:	99e50513          	addi	a0,a0,-1634 # 80025128 <disk+0x2128>
    80006792:	ffffa097          	auipc	ra,0xffffa
    80006796:	506080e7          	jalr	1286(ra) # 80000c98 <release>
}
    8000679a:	60e2                	ld	ra,24(sp)
    8000679c:	6442                	ld	s0,16(sp)
    8000679e:	64a2                	ld	s1,8(sp)
    800067a0:	6902                	ld	s2,0(sp)
    800067a2:	6105                	addi	sp,sp,32
    800067a4:	8082                	ret
      panic("virtio_disk_intr status");
    800067a6:	00002517          	auipc	a0,0x2
    800067aa:	0da50513          	addi	a0,a0,218 # 80008880 <syscalls+0x3b0>
    800067ae:	ffffa097          	auipc	ra,0xffffa
    800067b2:	d90080e7          	jalr	-624(ra) # 8000053e <panic>

00000000800067b6 <cas>:
    800067b6:	100522af          	lr.w	t0,(a0)
    800067ba:	00b29563          	bne	t0,a1,800067c4 <fail>
    800067be:	18c5252f          	sc.w	a0,a2,(a0)
    800067c2:	8082                	ret

00000000800067c4 <fail>:
    800067c4:	4505                	li	a0,1
    800067c6:	8082                	ret
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
