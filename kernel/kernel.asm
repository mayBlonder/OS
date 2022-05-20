
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
    80000130:	854080e7          	jalr	-1964(ra) # 80002980 <either_copyin>
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
    800001c8:	b08080e7          	jalr	-1272(ra) # 80001ccc <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	308080e7          	jalr	776(ra) # 800024dc <sleep>
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
    80000214:	71a080e7          	jalr	1818(ra) # 8000292a <either_copyout>
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
    800002f6:	6e4080e7          	jalr	1764(ra) # 800029d6 <procdump>
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
    8000044a:	234080e7          	jalr	564(ra) # 8000267a <wakeup>
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
    800008a4:	dda080e7          	jalr	-550(ra) # 8000267a <wakeup>
    
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
    80000930:	bb0080e7          	jalr	-1104(ra) # 800024dc <sleep>
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
    80000b82:	12c080e7          	jalr	300(ra) # 80001caa <mycpu>
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
    80000bb4:	0fa080e7          	jalr	250(ra) # 80001caa <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	0ee080e7          	jalr	238(ra) # 80001caa <mycpu>
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
    80000bd8:	0d6080e7          	jalr	214(ra) # 80001caa <mycpu>
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
    80000c18:	096080e7          	jalr	150(ra) # 80001caa <mycpu>
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
    80000c44:	06a080e7          	jalr	106(ra) # 80001caa <mycpu>
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
    80000e9a:	e04080e7          	jalr	-508(ra) # 80001c9a <cpuid>
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
    80000eb6:	de8080e7          	jalr	-536(ra) # 80001c9a <cpuid>
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
    80000ed8:	cf6080e7          	jalr	-778(ra) # 80002bca <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	244080e7          	jalr	580(ra) # 80006120 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	3ec080e7          	jalr	1004(ra) # 800022d0 <scheduler>
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
    80000f50:	c56080e7          	jalr	-938(ra) # 80002ba2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	c76080e7          	jalr	-906(ra) # 80002bca <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	1ae080e7          	jalr	430(ra) # 8000610a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	1bc080e7          	jalr	444(ra) # 80006120 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	3a0080e7          	jalr	928(ra) # 8000330c <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	a30080e7          	jalr	-1488(ra) # 800039a4 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	9da080e7          	jalr	-1574(ra) # 80004956 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	2be080e7          	jalr	702(ra) # 80006242 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	0c6080e7          	jalr	198(ra) # 80002052 <userinit>
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
  struct spinlock *sleep_lock = &sleeping_list.head_lock;
  struct spinlock *zombie_lock = &zombie_list.head_lock;
  struct spinlock *unused_lock = &unused_list.head_lock;


  initlock(sleep_lock, "sleeping_list_head_lock");
    80001b30:	00006597          	auipc	a1,0x6
    80001b34:	6c058593          	addi	a1,a1,1728 # 800081f0 <digits+0x1b0>
    80001b38:	00007517          	auipc	a0,0x7
    80001b3c:	d8050513          	addi	a0,a0,-640 # 800088b8 <sleeping_list+0x8>
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	014080e7          	jalr	20(ra) # 80000b54 <initlock>
  initlock(zombie_lock, "zombie_list_head_lock");
    80001b48:	00006597          	auipc	a1,0x6
    80001b4c:	6c058593          	addi	a1,a1,1728 # 80008208 <digits+0x1c8>
    80001b50:	00007517          	auipc	a0,0x7
    80001b54:	d8850513          	addi	a0,a0,-632 # 800088d8 <zombie_list+0x8>
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	ffc080e7          	jalr	-4(ra) # 80000b54 <initlock>
  initlock(unused_lock, "unused_list_head_lock");
    80001b60:	00006597          	auipc	a1,0x6
    80001b64:	6c058593          	addi	a1,a1,1728 # 80008220 <digits+0x1e0>
    80001b68:	00007517          	auipc	a0,0x7
    80001b6c:	d9050513          	addi	a0,a0,-624 # 800088f8 <unused_list+0x8>
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
    initlock(runnable_head, "cpu_runnable_list_head_lock");
    80001c6a:	85ca                	mv	a1,s2
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	fffff097          	auipc	ra,0xfffff
    80001c72:	ee6080e7          	jalr	-282(ra) # 80000b54 <initlock>
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001c76:	0a848493          	addi	s1,s1,168
    80001c7a:	fd449ee3          	bne	s1,s4,80001c56 <procinit+0x142>
  }
}
    80001c7e:	60e6                	ld	ra,88(sp)
    80001c80:	6446                	ld	s0,80(sp)
    80001c82:	64a6                	ld	s1,72(sp)
    80001c84:	6906                	ld	s2,64(sp)
    80001c86:	79e2                	ld	s3,56(sp)
    80001c88:	7a42                	ld	s4,48(sp)
    80001c8a:	7aa2                	ld	s5,40(sp)
    80001c8c:	7b02                	ld	s6,32(sp)
    80001c8e:	6be2                	ld	s7,24(sp)
    80001c90:	6c42                	ld	s8,16(sp)
    80001c92:	6ca2                	ld	s9,8(sp)
    80001c94:	6d02                	ld	s10,0(sp)
    80001c96:	6125                	addi	sp,sp,96
    80001c98:	8082                	ret

0000000080001c9a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001c9a:	1141                	addi	sp,sp,-16
    80001c9c:	e422                	sd	s0,8(sp)
    80001c9e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ca0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001ca2:	2501                	sext.w	a0,a0
    80001ca4:	6422                	ld	s0,8(sp)
    80001ca6:	0141                	addi	sp,sp,16
    80001ca8:	8082                	ret

0000000080001caa <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001caa:	1141                	addi	sp,sp,-16
    80001cac:	e422                	sd	s0,8(sp)
    80001cae:	0800                	addi	s0,sp,16
    80001cb0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001cb2:	2781                	sext.w	a5,a5
    80001cb4:	0a800513          	li	a0,168
    80001cb8:	02a787b3          	mul	a5,a5,a0
  return c;
}
    80001cbc:	0000f517          	auipc	a0,0xf
    80001cc0:	61450513          	addi	a0,a0,1556 # 800112d0 <cpus>
    80001cc4:	953e                	add	a0,a0,a5
    80001cc6:	6422                	ld	s0,8(sp)
    80001cc8:	0141                	addi	sp,sp,16
    80001cca:	8082                	ret

0000000080001ccc <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001ccc:	1101                	addi	sp,sp,-32
    80001cce:	ec06                	sd	ra,24(sp)
    80001cd0:	e822                	sd	s0,16(sp)
    80001cd2:	e426                	sd	s1,8(sp)
    80001cd4:	1000                	addi	s0,sp,32
  push_off();
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	ec2080e7          	jalr	-318(ra) # 80000b98 <push_off>
    80001cde:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ce0:	2781                	sext.w	a5,a5
    80001ce2:	0a800713          	li	a4,168
    80001ce6:	02e787b3          	mul	a5,a5,a4
    80001cea:	0000f717          	auipc	a4,0xf
    80001cee:	5b670713          	addi	a4,a4,1462 # 800112a0 <pid_lock>
    80001cf2:	97ba                	add	a5,a5,a4
    80001cf4:	7b84                	ld	s1,48(a5)
  pop_off();
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	f42080e7          	jalr	-190(ra) # 80000c38 <pop_off>
  return p;
}
    80001cfe:	8526                	mv	a0,s1
    80001d00:	60e2                	ld	ra,24(sp)
    80001d02:	6442                	ld	s0,16(sp)
    80001d04:	64a2                	ld	s1,8(sp)
    80001d06:	6105                	addi	sp,sp,32
    80001d08:	8082                	ret

0000000080001d0a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001d0a:	1141                	addi	sp,sp,-16
    80001d0c:	e406                	sd	ra,8(sp)
    80001d0e:	e022                	sd	s0,0(sp)
    80001d10:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001d12:	00000097          	auipc	ra,0x0
    80001d16:	fba080e7          	jalr	-70(ra) # 80001ccc <myproc>
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	f7e080e7          	jalr	-130(ra) # 80000c98 <release>

  if (first) {
    80001d22:	00007797          	auipc	a5,0x7
    80001d26:	b7e7a783          	lw	a5,-1154(a5) # 800088a0 <first.1736>
    80001d2a:	eb89                	bnez	a5,80001d3c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001d2c:	00001097          	auipc	ra,0x1
    80001d30:	eb6080e7          	jalr	-330(ra) # 80002be2 <usertrapret>
}
    80001d34:	60a2                	ld	ra,8(sp)
    80001d36:	6402                	ld	s0,0(sp)
    80001d38:	0141                	addi	sp,sp,16
    80001d3a:	8082                	ret
    first = 0;
    80001d3c:	00007797          	auipc	a5,0x7
    80001d40:	b607a223          	sw	zero,-1180(a5) # 800088a0 <first.1736>
    fsinit(ROOTDEV);
    80001d44:	4505                	li	a0,1
    80001d46:	00002097          	auipc	ra,0x2
    80001d4a:	bde080e7          	jalr	-1058(ra) # 80003924 <fsinit>
    80001d4e:	bff9                	j	80001d2c <forkret+0x22>

0000000080001d50 <allocpid>:
allocpid() {
    80001d50:	1101                	addi	sp,sp,-32
    80001d52:	ec06                	sd	ra,24(sp)
    80001d54:	e822                	sd	s0,16(sp)
    80001d56:	e426                	sd	s1,8(sp)
    80001d58:	e04a                	sd	s2,0(sp)
    80001d5a:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001d5c:	00007917          	auipc	s2,0x7
    80001d60:	b4890913          	addi	s2,s2,-1208 # 800088a4 <nextpid>
    80001d64:	00092483          	lw	s1,0(s2)
  while (cas(&nextpid, pid, nextpid + 1));
    80001d68:	0014861b          	addiw	a2,s1,1
    80001d6c:	85a6                	mv	a1,s1
    80001d6e:	854a                	mv	a0,s2
    80001d70:	00005097          	auipc	ra,0x5
    80001d74:	9b6080e7          	jalr	-1610(ra) # 80006726 <cas>
    80001d78:	2501                	sext.w	a0,a0
    80001d7a:	f56d                	bnez	a0,80001d64 <allocpid+0x14>
}
    80001d7c:	8526                	mv	a0,s1
    80001d7e:	60e2                	ld	ra,24(sp)
    80001d80:	6442                	ld	s0,16(sp)
    80001d82:	64a2                	ld	s1,8(sp)
    80001d84:	6902                	ld	s2,0(sp)
    80001d86:	6105                	addi	sp,sp,32
    80001d88:	8082                	ret

0000000080001d8a <proc_pagetable>:
{
    80001d8a:	1101                	addi	sp,sp,-32
    80001d8c:	ec06                	sd	ra,24(sp)
    80001d8e:	e822                	sd	s0,16(sp)
    80001d90:	e426                	sd	s1,8(sp)
    80001d92:	e04a                	sd	s2,0(sp)
    80001d94:	1000                	addi	s0,sp,32
    80001d96:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	5a2080e7          	jalr	1442(ra) # 8000133a <uvmcreate>
    80001da0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001da2:	c121                	beqz	a0,80001de2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001da4:	4729                	li	a4,10
    80001da6:	00005697          	auipc	a3,0x5
    80001daa:	25a68693          	addi	a3,a3,602 # 80007000 <_trampoline>
    80001dae:	6605                	lui	a2,0x1
    80001db0:	040005b7          	lui	a1,0x4000
    80001db4:	15fd                	addi	a1,a1,-1
    80001db6:	05b2                	slli	a1,a1,0xc
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	2f8080e7          	jalr	760(ra) # 800010b0 <mappages>
    80001dc0:	02054863          	bltz	a0,80001df0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001dc4:	4719                	li	a4,6
    80001dc6:	05893683          	ld	a3,88(s2)
    80001dca:	6605                	lui	a2,0x1
    80001dcc:	020005b7          	lui	a1,0x2000
    80001dd0:	15fd                	addi	a1,a1,-1
    80001dd2:	05b6                	slli	a1,a1,0xd
    80001dd4:	8526                	mv	a0,s1
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	2da080e7          	jalr	730(ra) # 800010b0 <mappages>
    80001dde:	02054163          	bltz	a0,80001e00 <proc_pagetable+0x76>
}
    80001de2:	8526                	mv	a0,s1
    80001de4:	60e2                	ld	ra,24(sp)
    80001de6:	6442                	ld	s0,16(sp)
    80001de8:	64a2                	ld	s1,8(sp)
    80001dea:	6902                	ld	s2,0(sp)
    80001dec:	6105                	addi	sp,sp,32
    80001dee:	8082                	ret
    uvmfree(pagetable, 0);
    80001df0:	4581                	li	a1,0
    80001df2:	8526                	mv	a0,s1
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	742080e7          	jalr	1858(ra) # 80001536 <uvmfree>
    return 0;
    80001dfc:	4481                	li	s1,0
    80001dfe:	b7d5                	j	80001de2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e00:	4681                	li	a3,0
    80001e02:	4605                	li	a2,1
    80001e04:	040005b7          	lui	a1,0x4000
    80001e08:	15fd                	addi	a1,a1,-1
    80001e0a:	05b2                	slli	a1,a1,0xc
    80001e0c:	8526                	mv	a0,s1
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	468080e7          	jalr	1128(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001e16:	4581                	li	a1,0
    80001e18:	8526                	mv	a0,s1
    80001e1a:	fffff097          	auipc	ra,0xfffff
    80001e1e:	71c080e7          	jalr	1820(ra) # 80001536 <uvmfree>
    return 0;
    80001e22:	4481                	li	s1,0
    80001e24:	bf7d                	j	80001de2 <proc_pagetable+0x58>

0000000080001e26 <proc_freepagetable>:
{
    80001e26:	1101                	addi	sp,sp,-32
    80001e28:	ec06                	sd	ra,24(sp)
    80001e2a:	e822                	sd	s0,16(sp)
    80001e2c:	e426                	sd	s1,8(sp)
    80001e2e:	e04a                	sd	s2,0(sp)
    80001e30:	1000                	addi	s0,sp,32
    80001e32:	84aa                	mv	s1,a0
    80001e34:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e36:	4681                	li	a3,0
    80001e38:	4605                	li	a2,1
    80001e3a:	040005b7          	lui	a1,0x4000
    80001e3e:	15fd                	addi	a1,a1,-1
    80001e40:	05b2                	slli	a1,a1,0xc
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	434080e7          	jalr	1076(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e4a:	4681                	li	a3,0
    80001e4c:	4605                	li	a2,1
    80001e4e:	020005b7          	lui	a1,0x2000
    80001e52:	15fd                	addi	a1,a1,-1
    80001e54:	05b6                	slli	a1,a1,0xd
    80001e56:	8526                	mv	a0,s1
    80001e58:	fffff097          	auipc	ra,0xfffff
    80001e5c:	41e080e7          	jalr	1054(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001e60:	85ca                	mv	a1,s2
    80001e62:	8526                	mv	a0,s1
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	6d2080e7          	jalr	1746(ra) # 80001536 <uvmfree>
}
    80001e6c:	60e2                	ld	ra,24(sp)
    80001e6e:	6442                	ld	s0,16(sp)
    80001e70:	64a2                	ld	s1,8(sp)
    80001e72:	6902                	ld	s2,0(sp)
    80001e74:	6105                	addi	sp,sp,32
    80001e76:	8082                	ret

0000000080001e78 <freeproc>:
{
    80001e78:	1101                	addi	sp,sp,-32
    80001e7a:	ec06                	sd	ra,24(sp)
    80001e7c:	e822                	sd	s0,16(sp)
    80001e7e:	e426                	sd	s1,8(sp)
    80001e80:	1000                	addi	s0,sp,32
    80001e82:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001e84:	6d28                	ld	a0,88(a0)
    80001e86:	c509                	beqz	a0,80001e90 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	b70080e7          	jalr	-1168(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001e90:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001e94:	68a8                	ld	a0,80(s1)
    80001e96:	c511                	beqz	a0,80001ea2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001e98:	64ac                	ld	a1,72(s1)
    80001e9a:	00000097          	auipc	ra,0x0
    80001e9e:	f8c080e7          	jalr	-116(ra) # 80001e26 <proc_freepagetable>
  p->pagetable = 0;
    80001ea2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ea6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001eaa:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001eae:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001eb2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001eb6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001eba:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ebe:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ec2:	0004ac23          	sw	zero,24(s1)
  remove(remove_from_ZOMBIE_list, p); 
    80001ec6:	85a6                	mv	a1,s1
    80001ec8:	00007517          	auipc	a0,0x7
    80001ecc:	a0850513          	addi	a0,a0,-1528 # 800088d0 <zombie_list>
    80001ed0:	00000097          	auipc	ra,0x0
    80001ed4:	a7e080e7          	jalr	-1410(ra) # 8000194e <remove>
  append(add_to_UNUSED_list, p); 
    80001ed8:	85a6                	mv	a1,s1
    80001eda:	00007517          	auipc	a0,0x7
    80001ede:	a1650513          	addi	a0,a0,-1514 # 800088f0 <unused_list>
    80001ee2:	00000097          	auipc	ra,0x0
    80001ee6:	9a4080e7          	jalr	-1628(ra) # 80001886 <append>
}
    80001eea:	60e2                	ld	ra,24(sp)
    80001eec:	6442                	ld	s0,16(sp)
    80001eee:	64a2                	ld	s1,8(sp)
    80001ef0:	6105                	addi	sp,sp,32
    80001ef2:	8082                	ret

0000000080001ef4 <allocproc>:
{
    80001ef4:	715d                	addi	sp,sp,-80
    80001ef6:	e486                	sd	ra,72(sp)
    80001ef8:	e0a2                	sd	s0,64(sp)
    80001efa:	fc26                	sd	s1,56(sp)
    80001efc:	f84a                	sd	s2,48(sp)
    80001efe:	f44e                	sd	s3,40(sp)
    80001f00:	f052                	sd	s4,32(sp)
    80001f02:	ec56                	sd	s5,24(sp)
    80001f04:	e85a                	sd	s6,16(sp)
    80001f06:	e45e                	sd	s7,8(sp)
    80001f08:	0880                	addi	s0,sp,80
  while(!(unused_list.head == empty)) {
    80001f0a:	00007917          	auipc	s2,0x7
    80001f0e:	9e692903          	lw	s2,-1562(s2) # 800088f0 <unused_list>
    80001f12:	57fd                	li	a5,-1
    80001f14:	12f90d63          	beq	s2,a5,8000204e <allocproc+0x15a>
    80001f18:	19000a93          	li	s5,400
    p = &proc[unused_list.head];
    80001f1c:	00010a17          	auipc	s4,0x10
    80001f20:	8f4a0a13          	addi	s4,s4,-1804 # 80011810 <proc>
  while(!(unused_list.head == empty)) {
    80001f24:	00007b97          	auipc	s7,0x7
    80001f28:	98cb8b93          	addi	s7,s7,-1652 # 800088b0 <sleeping_list>
    80001f2c:	5b7d                	li	s6,-1
    p = &proc[unused_list.head];
    80001f2e:	035909b3          	mul	s3,s2,s5
    80001f32:	014984b3          	add	s1,s3,s4
    acquire(&p->lock);
    80001f36:	8526                	mv	a0,s1
    80001f38:	fffff097          	auipc	ra,0xfffff
    80001f3c:	cac080e7          	jalr	-852(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001f40:	4c9c                	lw	a5,24(s1)
    80001f42:	c79d                	beqz	a5,80001f70 <allocproc+0x7c>
      release(&p->lock);
    80001f44:	8526                	mv	a0,s1
    80001f46:	fffff097          	auipc	ra,0xfffff
    80001f4a:	d52080e7          	jalr	-686(ra) # 80000c98 <release>
  while(!(unused_list.head == empty)) {
    80001f4e:	040ba903          	lw	s2,64(s7)
    80001f52:	fd691ee3          	bne	s2,s6,80001f2e <allocproc+0x3a>
  return 0;
    80001f56:	4481                	li	s1,0
}
    80001f58:	8526                	mv	a0,s1
    80001f5a:	60a6                	ld	ra,72(sp)
    80001f5c:	6406                	ld	s0,64(sp)
    80001f5e:	74e2                	ld	s1,56(sp)
    80001f60:	7942                	ld	s2,48(sp)
    80001f62:	79a2                	ld	s3,40(sp)
    80001f64:	7a02                	ld	s4,32(sp)
    80001f66:	6ae2                	ld	s5,24(sp)
    80001f68:	6b42                	ld	s6,16(sp)
    80001f6a:	6ba2                	ld	s7,8(sp)
    80001f6c:	6161                	addi	sp,sp,80
    80001f6e:	8082                	ret
      remove(remove_from_unused_list, p); 
    80001f70:	85a6                	mv	a1,s1
    80001f72:	00007517          	auipc	a0,0x7
    80001f76:	97e50513          	addi	a0,a0,-1666 # 800088f0 <unused_list>
    80001f7a:	00000097          	auipc	ra,0x0
    80001f7e:	9d4080e7          	jalr	-1580(ra) # 8000194e <remove>
  p->pid = allocpid();
    80001f82:	00000097          	auipc	ra,0x0
    80001f86:	dce080e7          	jalr	-562(ra) # 80001d50 <allocpid>
    80001f8a:	19000a13          	li	s4,400
    80001f8e:	034907b3          	mul	a5,s2,s4
    80001f92:	00010a17          	auipc	s4,0x10
    80001f96:	87ea0a13          	addi	s4,s4,-1922 # 80011810 <proc>
    80001f9a:	9a3e                	add	s4,s4,a5
    80001f9c:	02aa2823          	sw	a0,48(s4)
  p->state = USED;
    80001fa0:	4785                	li	a5,1
    80001fa2:	00fa2c23          	sw	a5,24(s4)
  p->last_cpu = -1;
    80001fa6:	57fd                	li	a5,-1
    80001fa8:	16fa2423          	sw	a5,360(s4)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	b48080e7          	jalr	-1208(ra) # 80000af4 <kalloc>
    80001fb4:	8aaa                	mv	s5,a0
    80001fb6:	04aa3c23          	sd	a0,88(s4)
    80001fba:	c135                	beqz	a0,8000201e <allocproc+0x12a>
  p->pagetable = proc_pagetable(p);
    80001fbc:	8526                	mv	a0,s1
    80001fbe:	00000097          	auipc	ra,0x0
    80001fc2:	dcc080e7          	jalr	-564(ra) # 80001d8a <proc_pagetable>
    80001fc6:	8a2a                	mv	s4,a0
    80001fc8:	19000793          	li	a5,400
    80001fcc:	02f90733          	mul	a4,s2,a5
    80001fd0:	00010797          	auipc	a5,0x10
    80001fd4:	84078793          	addi	a5,a5,-1984 # 80011810 <proc>
    80001fd8:	97ba                	add	a5,a5,a4
    80001fda:	eba8                	sd	a0,80(a5)
  if(p->pagetable == 0){
    80001fdc:	cd29                	beqz	a0,80002036 <allocproc+0x142>
  memset(&p->context, 0, sizeof(p->context));
    80001fde:	06098513          	addi	a0,s3,96 # 1060 <_entry-0x7fffefa0>
    80001fe2:	00010997          	auipc	s3,0x10
    80001fe6:	82e98993          	addi	s3,s3,-2002 # 80011810 <proc>
    80001fea:	07000613          	li	a2,112
    80001fee:	4581                	li	a1,0
    80001ff0:	954e                	add	a0,a0,s3
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	cee080e7          	jalr	-786(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001ffa:	19000793          	li	a5,400
    80001ffe:	02f90933          	mul	s2,s2,a5
    80002002:	994e                	add	s2,s2,s3
    80002004:	00000797          	auipc	a5,0x0
    80002008:	d0678793          	addi	a5,a5,-762 # 80001d0a <forkret>
    8000200c:	06f93023          	sd	a5,96(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002010:	04093783          	ld	a5,64(s2)
    80002014:	6705                	lui	a4,0x1
    80002016:	97ba                	add	a5,a5,a4
    80002018:	06f93423          	sd	a5,104(s2)
  return p;
    8000201c:	bf35                	j	80001f58 <allocproc+0x64>
    freeproc(p);
    8000201e:	8526                	mv	a0,s1
    80002020:	00000097          	auipc	ra,0x0
    80002024:	e58080e7          	jalr	-424(ra) # 80001e78 <freeproc>
    release(&p->lock);
    80002028:	8526                	mv	a0,s1
    8000202a:	fffff097          	auipc	ra,0xfffff
    8000202e:	c6e080e7          	jalr	-914(ra) # 80000c98 <release>
    return 0;
    80002032:	84d6                	mv	s1,s5
    80002034:	b715                	j	80001f58 <allocproc+0x64>
    freeproc(p);
    80002036:	8526                	mv	a0,s1
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	e40080e7          	jalr	-448(ra) # 80001e78 <freeproc>
    release(&p->lock);
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	c56080e7          	jalr	-938(ra) # 80000c98 <release>
    return 0;
    8000204a:	84d2                	mv	s1,s4
    8000204c:	b731                	j	80001f58 <allocproc+0x64>
  return 0;
    8000204e:	4481                	li	s1,0
    80002050:	b721                	j	80001f58 <allocproc+0x64>

0000000080002052 <userinit>:
{
    80002052:	1101                	addi	sp,sp,-32
    80002054:	ec06                	sd	ra,24(sp)
    80002056:	e822                	sd	s0,16(sp)
    80002058:	e426                	sd	s1,8(sp)
    8000205a:	1000                	addi	s0,sp,32
  p = allocproc();
    8000205c:	00000097          	auipc	ra,0x0
    80002060:	e98080e7          	jalr	-360(ra) # 80001ef4 <allocproc>
    80002064:	84aa                	mv	s1,a0
  initproc = p;
    80002066:	00007797          	auipc	a5,0x7
    8000206a:	fca7b123          	sd	a0,-62(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000206e:	03400613          	li	a2,52
    80002072:	00007597          	auipc	a1,0x7
    80002076:	89e58593          	addi	a1,a1,-1890 # 80008910 <initcode>
    8000207a:	6928                	ld	a0,80(a0)
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	2ec080e7          	jalr	748(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80002084:	6785                	lui	a5,0x1
    80002086:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80002088:	6cb8                	ld	a4,88(s1)
    8000208a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    8000208e:	6cb8                	ld	a4,88(s1)
    80002090:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002092:	4641                	li	a2,16
    80002094:	00006597          	auipc	a1,0x6
    80002098:	1f458593          	addi	a1,a1,500 # 80008288 <digits+0x248>
    8000209c:	15848513          	addi	a0,s1,344
    800020a0:	fffff097          	auipc	ra,0xfffff
    800020a4:	d92080e7          	jalr	-622(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800020a8:	00006517          	auipc	a0,0x6
    800020ac:	1f050513          	addi	a0,a0,496 # 80008298 <digits+0x258>
    800020b0:	00002097          	auipc	ra,0x2
    800020b4:	2a2080e7          	jalr	674(ra) # 80004352 <namei>
    800020b8:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    800020bc:	478d                	li	a5,3
    800020be:	cc9c                	sw	a5,24(s1)
  append(l, p);
    800020c0:	85a6                	mv	a1,s1
    800020c2:	0000f517          	auipc	a0,0xf
    800020c6:	29650513          	addi	a0,a0,662 # 80011358 <cpus+0x88>
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	7bc080e7          	jalr	1980(ra) # 80001886 <append>
  release(&p->lock);
    800020d2:	8526                	mv	a0,s1
    800020d4:	fffff097          	auipc	ra,0xfffff
    800020d8:	bc4080e7          	jalr	-1084(ra) # 80000c98 <release>
}
    800020dc:	60e2                	ld	ra,24(sp)
    800020de:	6442                	ld	s0,16(sp)
    800020e0:	64a2                	ld	s1,8(sp)
    800020e2:	6105                	addi	sp,sp,32
    800020e4:	8082                	ret

00000000800020e6 <growproc>:
{
    800020e6:	1101                	addi	sp,sp,-32
    800020e8:	ec06                	sd	ra,24(sp)
    800020ea:	e822                	sd	s0,16(sp)
    800020ec:	e426                	sd	s1,8(sp)
    800020ee:	e04a                	sd	s2,0(sp)
    800020f0:	1000                	addi	s0,sp,32
    800020f2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800020f4:	00000097          	auipc	ra,0x0
    800020f8:	bd8080e7          	jalr	-1064(ra) # 80001ccc <myproc>
    800020fc:	892a                	mv	s2,a0
  sz = p->sz;
    800020fe:	652c                	ld	a1,72(a0)
    80002100:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002104:	00904f63          	bgtz	s1,80002122 <growproc+0x3c>
  } else if(n < 0){
    80002108:	0204cc63          	bltz	s1,80002140 <growproc+0x5a>
  p->sz = sz;
    8000210c:	1602                	slli	a2,a2,0x20
    8000210e:	9201                	srli	a2,a2,0x20
    80002110:	04c93423          	sd	a2,72(s2)
  return 0;
    80002114:	4501                	li	a0,0
}
    80002116:	60e2                	ld	ra,24(sp)
    80002118:	6442                	ld	s0,16(sp)
    8000211a:	64a2                	ld	s1,8(sp)
    8000211c:	6902                	ld	s2,0(sp)
    8000211e:	6105                	addi	sp,sp,32
    80002120:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002122:	9e25                	addw	a2,a2,s1
    80002124:	1602                	slli	a2,a2,0x20
    80002126:	9201                	srli	a2,a2,0x20
    80002128:	1582                	slli	a1,a1,0x20
    8000212a:	9181                	srli	a1,a1,0x20
    8000212c:	6928                	ld	a0,80(a0)
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	2f4080e7          	jalr	756(ra) # 80001422 <uvmalloc>
    80002136:	0005061b          	sext.w	a2,a0
    8000213a:	fa69                	bnez	a2,8000210c <growproc+0x26>
      return -1;
    8000213c:	557d                	li	a0,-1
    8000213e:	bfe1                	j	80002116 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002140:	9e25                	addw	a2,a2,s1
    80002142:	1602                	slli	a2,a2,0x20
    80002144:	9201                	srli	a2,a2,0x20
    80002146:	1582                	slli	a1,a1,0x20
    80002148:	9181                	srli	a1,a1,0x20
    8000214a:	6928                	ld	a0,80(a0)
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	28e080e7          	jalr	654(ra) # 800013da <uvmdealloc>
    80002154:	0005061b          	sext.w	a2,a0
    80002158:	bf55                	j	8000210c <growproc+0x26>

000000008000215a <fork>:
{
    8000215a:	7179                	addi	sp,sp,-48
    8000215c:	f406                	sd	ra,40(sp)
    8000215e:	f022                	sd	s0,32(sp)
    80002160:	ec26                	sd	s1,24(sp)
    80002162:	e84a                	sd	s2,16(sp)
    80002164:	e44e                	sd	s3,8(sp)
    80002166:	e052                	sd	s4,0(sp)
    80002168:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000216a:	00000097          	auipc	ra,0x0
    8000216e:	b62080e7          	jalr	-1182(ra) # 80001ccc <myproc>
    80002172:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80002174:	00000097          	auipc	ra,0x0
    80002178:	d80080e7          	jalr	-640(ra) # 80001ef4 <allocproc>
    8000217c:	14050863          	beqz	a0,800022cc <fork+0x172>
    80002180:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002182:	0489b603          	ld	a2,72(s3)
    80002186:	692c                	ld	a1,80(a0)
    80002188:	0509b503          	ld	a0,80(s3)
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	3e2080e7          	jalr	994(ra) # 8000156e <uvmcopy>
    80002194:	04054663          	bltz	a0,800021e0 <fork+0x86>
  np->sz = p->sz;
    80002198:	0489b783          	ld	a5,72(s3)
    8000219c:	04f93423          	sd	a5,72(s2)
  *(np->trapframe) = *(p->trapframe);
    800021a0:	0589b683          	ld	a3,88(s3)
    800021a4:	87b6                	mv	a5,a3
    800021a6:	05893703          	ld	a4,88(s2)
    800021aa:	12068693          	addi	a3,a3,288
    800021ae:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800021b2:	6788                	ld	a0,8(a5)
    800021b4:	6b8c                	ld	a1,16(a5)
    800021b6:	6f90                	ld	a2,24(a5)
    800021b8:	01073023          	sd	a6,0(a4)
    800021bc:	e708                	sd	a0,8(a4)
    800021be:	eb0c                	sd	a1,16(a4)
    800021c0:	ef10                	sd	a2,24(a4)
    800021c2:	02078793          	addi	a5,a5,32
    800021c6:	02070713          	addi	a4,a4,32
    800021ca:	fed792e3          	bne	a5,a3,800021ae <fork+0x54>
  np->trapframe->a0 = 0;
    800021ce:	05893783          	ld	a5,88(s2)
    800021d2:	0607b823          	sd	zero,112(a5)
    800021d6:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    800021da:	15000a13          	li	s4,336
    800021de:	a03d                	j	8000220c <fork+0xb2>
    freeproc(np);
    800021e0:	854a                	mv	a0,s2
    800021e2:	00000097          	auipc	ra,0x0
    800021e6:	c96080e7          	jalr	-874(ra) # 80001e78 <freeproc>
    release(&np->lock);
    800021ea:	854a                	mv	a0,s2
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	aac080e7          	jalr	-1364(ra) # 80000c98 <release>
    return -1;
    800021f4:	5a7d                	li	s4,-1
    800021f6:	a0d1                	j	800022ba <fork+0x160>
      np->ofile[i] = filedup(p->ofile[i]);
    800021f8:	00002097          	auipc	ra,0x2
    800021fc:	7f0080e7          	jalr	2032(ra) # 800049e8 <filedup>
    80002200:	009907b3          	add	a5,s2,s1
    80002204:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002206:	04a1                	addi	s1,s1,8
    80002208:	01448763          	beq	s1,s4,80002216 <fork+0xbc>
    if(p->ofile[i])
    8000220c:	009987b3          	add	a5,s3,s1
    80002210:	6388                	ld	a0,0(a5)
    80002212:	f17d                	bnez	a0,800021f8 <fork+0x9e>
    80002214:	bfcd                	j	80002206 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002216:	1509b503          	ld	a0,336(s3)
    8000221a:	00002097          	auipc	ra,0x2
    8000221e:	944080e7          	jalr	-1724(ra) # 80003b5e <idup>
    80002222:	14a93823          	sd	a0,336(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002226:	4641                	li	a2,16
    80002228:	15898593          	addi	a1,s3,344
    8000222c:	15890513          	addi	a0,s2,344
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	c02080e7          	jalr	-1022(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002238:	03092a03          	lw	s4,48(s2)
  release(&np->lock);
    8000223c:	854a                	mv	a0,s2
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a5a080e7          	jalr	-1446(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002246:	0000f497          	auipc	s1,0xf
    8000224a:	07248493          	addi	s1,s1,114 # 800112b8 <wait_lock>
    8000224e:	8526                	mv	a0,s1
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	994080e7          	jalr	-1644(ra) # 80000be4 <acquire>
  np->parent = p;
    80002258:	03393c23          	sd	s3,56(s2)
  release(&wait_lock);
    8000225c:	8526                	mv	a0,s1
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	a3a080e7          	jalr	-1478(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002266:	854a                	mv	a0,s2
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	97c080e7          	jalr	-1668(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002270:	478d                	li	a5,3
    80002272:	00f92c23          	sw	a5,24(s2)
  int last_cpu = p->last_cpu; 
    80002276:	1689a503          	lw	a0,360(s3)
  np->last_cpu = last_cpu;
    8000227a:	16a92423          	sw	a0,360(s2)
  inc_cpu(&cpus[np->last_cpu]);
    8000227e:	0000f497          	auipc	s1,0xf
    80002282:	05248493          	addi	s1,s1,82 # 800112d0 <cpus>
    80002286:	0a800993          	li	s3,168
    8000228a:	03350533          	mul	a0,a0,s3
    8000228e:	9526                	add	a0,a0,s1
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	5ae080e7          	jalr	1454(ra) # 8000183e <inc_cpu>
  append(&(cpus[np->last_cpu].runnable_list), np); 
    80002298:	16892503          	lw	a0,360(s2)
    8000229c:	03350533          	mul	a0,a0,s3
    800022a0:	08850513          	addi	a0,a0,136
    800022a4:	85ca                	mv	a1,s2
    800022a6:	9526                	add	a0,a0,s1
    800022a8:	fffff097          	auipc	ra,0xfffff
    800022ac:	5de080e7          	jalr	1502(ra) # 80001886 <append>
  release(&np->lock);
    800022b0:	854a                	mv	a0,s2
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9e6080e7          	jalr	-1562(ra) # 80000c98 <release>
}
    800022ba:	8552                	mv	a0,s4
    800022bc:	70a2                	ld	ra,40(sp)
    800022be:	7402                	ld	s0,32(sp)
    800022c0:	64e2                	ld	s1,24(sp)
    800022c2:	6942                	ld	s2,16(sp)
    800022c4:	69a2                	ld	s3,8(sp)
    800022c6:	6a02                	ld	s4,0(sp)
    800022c8:	6145                	addi	sp,sp,48
    800022ca:	8082                	ret
    return -1;
    800022cc:	5a7d                	li	s4,-1
    800022ce:	b7f5                	j	800022ba <fork+0x160>

00000000800022d0 <scheduler>:
{
    800022d0:	715d                	addi	sp,sp,-80
    800022d2:	e486                	sd	ra,72(sp)
    800022d4:	e0a2                	sd	s0,64(sp)
    800022d6:	fc26                	sd	s1,56(sp)
    800022d8:	f84a                	sd	s2,48(sp)
    800022da:	f44e                	sd	s3,40(sp)
    800022dc:	f052                	sd	s4,32(sp)
    800022de:	ec56                	sd	s5,24(sp)
    800022e0:	e85a                	sd	s6,16(sp)
    800022e2:	e45e                	sd	s7,8(sp)
    800022e4:	e062                	sd	s8,0(sp)
    800022e6:	0880                	addi	s0,sp,80
    800022e8:	8712                	mv	a4,tp
  int id = r_tp();
    800022ea:	2701                	sext.w	a4,a4
  c->proc = 0;
    800022ec:	0a800793          	li	a5,168
    800022f0:	02f707b3          	mul	a5,a4,a5
    800022f4:	0000f697          	auipc	a3,0xf
    800022f8:	fac68693          	addi	a3,a3,-84 # 800112a0 <pid_lock>
    800022fc:	96be                	add	a3,a3,a5
    800022fe:	0206b823          	sd	zero,48(a3)
        remove(&(c->runnable_list), p);
    80002302:	0000fb17          	auipc	s6,0xf
    80002306:	fceb0b13          	addi	s6,s6,-50 # 800112d0 <cpus>
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
    80002330:	0b89a783          	lw	a5,184(s3)
    80002334:	56fd                	li	a3,-1
      if(p->state == RUNNABLE) {
    80002336:	03578733          	mul	a4,a5,s5
    8000233a:	9752                	add	a4,a4,s4
    while(!(c->runnable_list.head == -1)) {
    8000233c:	fed783e3          	beq	a5,a3,80002322 <scheduler+0x52>
      if(p->state == RUNNABLE) {
    80002340:	4f10                	lw	a2,24(a4)
    80002342:	ff261de3          	bne	a2,s2,8000233c <scheduler+0x6c>
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
    8000236a:	0389b823          	sd	s8,48(s3)
        p->last_cpu = c->cpu_id;
    8000236e:	0b49a783          	lw	a5,180(s3)
    80002372:	16fc2423          	sw	a5,360(s8)
        swtch(&c->context, &p->context);
    80002376:	06048593          	addi	a1,s1,96
    8000237a:	95d2                	add	a1,a1,s4
    8000237c:	855a                	mv	a0,s6
    8000237e:	00000097          	auipc	ra,0x0
    80002382:	7ba080e7          	jalr	1978(ra) # 80002b38 <swtch>
        c->proc = 0;
    80002386:	0209b823          	sd	zero,48(s3)
        release(&p->lock);
    8000238a:	8562                	mv	a0,s8
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	90c080e7          	jalr	-1780(ra) # 80000c98 <release>
    80002394:	bf71                	j	80002330 <scheduler+0x60>

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
    800023aa:	926080e7          	jalr	-1754(ra) # 80001ccc <myproc>
    800023ae:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800023b0:	ffffe097          	auipc	ra,0xffffe
    800023b4:	7ba080e7          	jalr	1978(ra) # 80000b6a <holding>
    800023b8:	c541                	beqz	a0,80002440 <sched+0xaa>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023ba:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800023bc:	2781                	sext.w	a5,a5
    800023be:	0a800713          	li	a4,168
    800023c2:	02e787b3          	mul	a5,a5,a4
    800023c6:	0000f717          	auipc	a4,0xf
    800023ca:	eda70713          	addi	a4,a4,-294 # 800112a0 <pid_lock>
    800023ce:	97ba                	add	a5,a5,a4
    800023d0:	0a87a703          	lw	a4,168(a5)
    800023d4:	4785                	li	a5,1
    800023d6:	06f71d63          	bne	a4,a5,80002450 <sched+0xba>
  if(p->state == RUNNING)
    800023da:	4c98                	lw	a4,24(s1)
    800023dc:	4791                	li	a5,4
    800023de:	08f70163          	beq	a4,a5,80002460 <sched+0xca>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023e2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800023e6:	8b89                	andi	a5,a5,2
  if(intr_get())
    800023e8:	e7c1                	bnez	a5,80002470 <sched+0xda>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023ea:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800023ec:	0000f917          	auipc	s2,0xf
    800023f0:	eb490913          	addi	s2,s2,-332 # 800112a0 <pid_lock>
    800023f4:	2781                	sext.w	a5,a5
    800023f6:	0a800993          	li	s3,168
    800023fa:	033787b3          	mul	a5,a5,s3
    800023fe:	97ca                	add	a5,a5,s2
    80002400:	0ac7aa03          	lw	s4,172(a5)
    80002404:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002406:	2781                	sext.w	a5,a5
    80002408:	033787b3          	mul	a5,a5,s3
    8000240c:	0000f597          	auipc	a1,0xf
    80002410:	ecc58593          	addi	a1,a1,-308 # 800112d8 <cpus+0x8>
    80002414:	95be                	add	a1,a1,a5
    80002416:	06048513          	addi	a0,s1,96
    8000241a:	00000097          	auipc	ra,0x0
    8000241e:	71e080e7          	jalr	1822(ra) # 80002b38 <swtch>
    80002422:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002424:	2781                	sext.w	a5,a5
    80002426:	033787b3          	mul	a5,a5,s3
    8000242a:	97ca                	add	a5,a5,s2
    8000242c:	0b47a623          	sw	s4,172(a5)
}
    80002430:	70a2                	ld	ra,40(sp)
    80002432:	7402                	ld	s0,32(sp)
    80002434:	64e2                	ld	s1,24(sp)
    80002436:	6942                	ld	s2,16(sp)
    80002438:	69a2                	ld	s3,8(sp)
    8000243a:	6a02                	ld	s4,0(sp)
    8000243c:	6145                	addi	sp,sp,48
    8000243e:	8082                	ret
    panic("sched p->lock");
    80002440:	00006517          	auipc	a0,0x6
    80002444:	e6050513          	addi	a0,a0,-416 # 800082a0 <digits+0x260>
    80002448:	ffffe097          	auipc	ra,0xffffe
    8000244c:	0f6080e7          	jalr	246(ra) # 8000053e <panic>
    panic("sched locks");
    80002450:	00006517          	auipc	a0,0x6
    80002454:	e6050513          	addi	a0,a0,-416 # 800082b0 <digits+0x270>
    80002458:	ffffe097          	auipc	ra,0xffffe
    8000245c:	0e6080e7          	jalr	230(ra) # 8000053e <panic>
    panic("sched running");
    80002460:	00006517          	auipc	a0,0x6
    80002464:	e6050513          	addi	a0,a0,-416 # 800082c0 <digits+0x280>
    80002468:	ffffe097          	auipc	ra,0xffffe
    8000246c:	0d6080e7          	jalr	214(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002470:	00006517          	auipc	a0,0x6
    80002474:	e6050513          	addi	a0,a0,-416 # 800082d0 <digits+0x290>
    80002478:	ffffe097          	auipc	ra,0xffffe
    8000247c:	0c6080e7          	jalr	198(ra) # 8000053e <panic>

0000000080002480 <yield>:
{
    80002480:	1101                	addi	sp,sp,-32
    80002482:	ec06                	sd	ra,24(sp)
    80002484:	e822                	sd	s0,16(sp)
    80002486:	e426                	sd	s1,8(sp)
    80002488:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000248a:	00000097          	auipc	ra,0x0
    8000248e:	842080e7          	jalr	-1982(ra) # 80001ccc <myproc>
    80002492:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002494:	ffffe097          	auipc	ra,0xffffe
    80002498:	750080e7          	jalr	1872(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000249c:	478d                	li	a5,3
    8000249e:	cc9c                	sw	a5,24(s1)
    800024a0:	8792                	mv	a5,tp
  append(&(mycpu()->runnable_list), p);
    800024a2:	2781                	sext.w	a5,a5
    800024a4:	0a800513          	li	a0,168
    800024a8:	02a787b3          	mul	a5,a5,a0
    800024ac:	85a6                	mv	a1,s1
    800024ae:	0000f517          	auipc	a0,0xf
    800024b2:	eaa50513          	addi	a0,a0,-342 # 80011358 <cpus+0x88>
    800024b6:	953e                	add	a0,a0,a5
    800024b8:	fffff097          	auipc	ra,0xfffff
    800024bc:	3ce080e7          	jalr	974(ra) # 80001886 <append>
  sched();
    800024c0:	00000097          	auipc	ra,0x0
    800024c4:	ed6080e7          	jalr	-298(ra) # 80002396 <sched>
  release(&p->lock);
    800024c8:	8526                	mv	a0,s1
    800024ca:	ffffe097          	auipc	ra,0xffffe
    800024ce:	7ce080e7          	jalr	1998(ra) # 80000c98 <release>
}
    800024d2:	60e2                	ld	ra,24(sp)
    800024d4:	6442                	ld	s0,16(sp)
    800024d6:	64a2                	ld	s1,8(sp)
    800024d8:	6105                	addi	sp,sp,32
    800024da:	8082                	ret

00000000800024dc <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800024dc:	7179                	addi	sp,sp,-48
    800024de:	f406                	sd	ra,40(sp)
    800024e0:	f022                	sd	s0,32(sp)
    800024e2:	ec26                	sd	s1,24(sp)
    800024e4:	e84a                	sd	s2,16(sp)
    800024e6:	e44e                	sd	s3,8(sp)
    800024e8:	1800                	addi	s0,sp,48
    800024ea:	89aa                	mv	s3,a0
    800024ec:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	7de080e7          	jalr	2014(ra) # 80001ccc <myproc>
    800024f6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	6ec080e7          	jalr	1772(ra) # 80000be4 <acquire>
  release(lk);
    80002500:	854a                	mv	a0,s2
    80002502:	ffffe097          	auipc	ra,0xffffe
    80002506:	796080e7          	jalr	1942(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000250a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000250e:	4789                	li	a5,2
    80002510:	cc9c                	sw	a5,24(s1)

  struct linked_list *add_to_SLEEPING_list = &sleeping_list;
  append(add_to_SLEEPING_list, p);
    80002512:	85a6                	mv	a1,s1
    80002514:	00006517          	auipc	a0,0x6
    80002518:	39c50513          	addi	a0,a0,924 # 800088b0 <sleeping_list>
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	36a080e7          	jalr	874(ra) # 80001886 <append>

  sched();
    80002524:	00000097          	auipc	ra,0x0
    80002528:	e72080e7          	jalr	-398(ra) # 80002396 <sched>

  // Tidy up.
  p->chan = 0;
    8000252c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002530:	8526                	mv	a0,s1
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	766080e7          	jalr	1894(ra) # 80000c98 <release>
  acquire(lk);
    8000253a:	854a                	mv	a0,s2
    8000253c:	ffffe097          	auipc	ra,0xffffe
    80002540:	6a8080e7          	jalr	1704(ra) # 80000be4 <acquire>
}
    80002544:	70a2                	ld	ra,40(sp)
    80002546:	7402                	ld	s0,32(sp)
    80002548:	64e2                	ld	s1,24(sp)
    8000254a:	6942                	ld	s2,16(sp)
    8000254c:	69a2                	ld	s3,8(sp)
    8000254e:	6145                	addi	sp,sp,48
    80002550:	8082                	ret

0000000080002552 <wait>:
{
    80002552:	715d                	addi	sp,sp,-80
    80002554:	e486                	sd	ra,72(sp)
    80002556:	e0a2                	sd	s0,64(sp)
    80002558:	fc26                	sd	s1,56(sp)
    8000255a:	f84a                	sd	s2,48(sp)
    8000255c:	f44e                	sd	s3,40(sp)
    8000255e:	f052                	sd	s4,32(sp)
    80002560:	ec56                	sd	s5,24(sp)
    80002562:	e85a                	sd	s6,16(sp)
    80002564:	e45e                	sd	s7,8(sp)
    80002566:	e062                	sd	s8,0(sp)
    80002568:	0880                	addi	s0,sp,80
    8000256a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000256c:	fffff097          	auipc	ra,0xfffff
    80002570:	760080e7          	jalr	1888(ra) # 80001ccc <myproc>
    80002574:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002576:	0000f517          	auipc	a0,0xf
    8000257a:	d4250513          	addi	a0,a0,-702 # 800112b8 <wait_lock>
    8000257e:	ffffe097          	auipc	ra,0xffffe
    80002582:	666080e7          	jalr	1638(ra) # 80000be4 <acquire>
    havekids = 0;
    80002586:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002588:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000258a:	00015997          	auipc	s3,0x15
    8000258e:	68698993          	addi	s3,s3,1670 # 80017c10 <tickslock>
        havekids = 1;
    80002592:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002594:	0000fc17          	auipc	s8,0xf
    80002598:	d24c0c13          	addi	s8,s8,-732 # 800112b8 <wait_lock>
    havekids = 0;
    8000259c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000259e:	0000f497          	auipc	s1,0xf
    800025a2:	27248493          	addi	s1,s1,626 # 80011810 <proc>
    800025a6:	a0bd                	j	80002614 <wait+0xc2>
          pid = np->pid;
    800025a8:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800025ac:	000b0e63          	beqz	s6,800025c8 <wait+0x76>
    800025b0:	4691                	li	a3,4
    800025b2:	02c48613          	addi	a2,s1,44
    800025b6:	85da                	mv	a1,s6
    800025b8:	05093503          	ld	a0,80(s2)
    800025bc:	fffff097          	auipc	ra,0xfffff
    800025c0:	0b6080e7          	jalr	182(ra) # 80001672 <copyout>
    800025c4:	02054563          	bltz	a0,800025ee <wait+0x9c>
          freeproc(np);
    800025c8:	8526                	mv	a0,s1
    800025ca:	00000097          	auipc	ra,0x0
    800025ce:	8ae080e7          	jalr	-1874(ra) # 80001e78 <freeproc>
          release(&np->lock);
    800025d2:	8526                	mv	a0,s1
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	6c4080e7          	jalr	1732(ra) # 80000c98 <release>
          release(&wait_lock);
    800025dc:	0000f517          	auipc	a0,0xf
    800025e0:	cdc50513          	addi	a0,a0,-804 # 800112b8 <wait_lock>
    800025e4:	ffffe097          	auipc	ra,0xffffe
    800025e8:	6b4080e7          	jalr	1716(ra) # 80000c98 <release>
          return pid;
    800025ec:	a09d                	j	80002652 <wait+0x100>
            release(&np->lock);
    800025ee:	8526                	mv	a0,s1
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	6a8080e7          	jalr	1704(ra) # 80000c98 <release>
            release(&wait_lock);
    800025f8:	0000f517          	auipc	a0,0xf
    800025fc:	cc050513          	addi	a0,a0,-832 # 800112b8 <wait_lock>
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	698080e7          	jalr	1688(ra) # 80000c98 <release>
            return -1;
    80002608:	59fd                	li	s3,-1
    8000260a:	a0a1                	j	80002652 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000260c:	19048493          	addi	s1,s1,400
    80002610:	03348463          	beq	s1,s3,80002638 <wait+0xe6>
      if(np->parent == p){
    80002614:	7c9c                	ld	a5,56(s1)
    80002616:	ff279be3          	bne	a5,s2,8000260c <wait+0xba>
        acquire(&np->lock);
    8000261a:	8526                	mv	a0,s1
    8000261c:	ffffe097          	auipc	ra,0xffffe
    80002620:	5c8080e7          	jalr	1480(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002624:	4c9c                	lw	a5,24(s1)
    80002626:	f94781e3          	beq	a5,s4,800025a8 <wait+0x56>
        release(&np->lock);
    8000262a:	8526                	mv	a0,s1
    8000262c:	ffffe097          	auipc	ra,0xffffe
    80002630:	66c080e7          	jalr	1644(ra) # 80000c98 <release>
        havekids = 1;
    80002634:	8756                	mv	a4,s5
    80002636:	bfd9                	j	8000260c <wait+0xba>
    if(!havekids || p->killed){
    80002638:	c701                	beqz	a4,80002640 <wait+0xee>
    8000263a:	02892783          	lw	a5,40(s2)
    8000263e:	c79d                	beqz	a5,8000266c <wait+0x11a>
      release(&wait_lock);
    80002640:	0000f517          	auipc	a0,0xf
    80002644:	c7850513          	addi	a0,a0,-904 # 800112b8 <wait_lock>
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	650080e7          	jalr	1616(ra) # 80000c98 <release>
      return -1;
    80002650:	59fd                	li	s3,-1
}
    80002652:	854e                	mv	a0,s3
    80002654:	60a6                	ld	ra,72(sp)
    80002656:	6406                	ld	s0,64(sp)
    80002658:	74e2                	ld	s1,56(sp)
    8000265a:	7942                	ld	s2,48(sp)
    8000265c:	79a2                	ld	s3,40(sp)
    8000265e:	7a02                	ld	s4,32(sp)
    80002660:	6ae2                	ld	s5,24(sp)
    80002662:	6b42                	ld	s6,16(sp)
    80002664:	6ba2                	ld	s7,8(sp)
    80002666:	6c02                	ld	s8,0(sp)
    80002668:	6161                	addi	sp,sp,80
    8000266a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000266c:	85e2                	mv	a1,s8
    8000266e:	854a                	mv	a0,s2
    80002670:	00000097          	auipc	ra,0x0
    80002674:	e6c080e7          	jalr	-404(ra) # 800024dc <sleep>
    havekids = 0;
    80002678:	b715                	j	8000259c <wait+0x4a>

000000008000267a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000267a:	7119                	addi	sp,sp,-128
    8000267c:	fc86                	sd	ra,120(sp)
    8000267e:	f8a2                	sd	s0,112(sp)
    80002680:	f4a6                	sd	s1,104(sp)
    80002682:	f0ca                	sd	s2,96(sp)
    80002684:	ecce                	sd	s3,88(sp)
    80002686:	e8d2                	sd	s4,80(sp)
    80002688:	e4d6                	sd	s5,72(sp)
    8000268a:	e0da                	sd	s6,64(sp)
    8000268c:	fc5e                	sd	s7,56(sp)
    8000268e:	f862                	sd	s8,48(sp)
    80002690:	f466                	sd	s9,40(sp)
    80002692:	f06a                	sd	s10,32(sp)
    80002694:	ec6e                	sd	s11,24(sp)
    80002696:	0100                	addi	s0,sp,128
  struct proc *p;
  int empty = -1;
  int curr = sleeping_list.head;
    80002698:	00006497          	auipc	s1,0x6
    8000269c:	2184a483          	lw	s1,536(s1) # 800088b0 <sleeping_list>

  while(curr != empty) {
    800026a0:	57fd                	li	a5,-1
    800026a2:	0af48b63          	beq	s1,a5,80002758 <wakeup+0xde>
    800026a6:	8baa                	mv	s7,a0
    p = &proc[curr];
    800026a8:	19000a13          	li	s4,400
    800026ac:	0000f997          	auipc	s3,0xf
    800026b0:	16498993          	addi	s3,s3,356 # 80011810 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800026b4:	4b09                	li	s6,2
        struct linked_list *remove_from_SLEEPING_list = &sleeping_list;
        remove(remove_from_SLEEPING_list, p);
    800026b6:	00006d97          	auipc	s11,0x6
    800026ba:	1fad8d93          	addi	s11,s11,506 # 800088b0 <sleeping_list>
        p->state = RUNNABLE;
    800026be:	4d0d                	li	s10,3

        #ifdef ON
          p->last_cpu = min_num_procs_cpu();
        #endif

        inc_cpu(&cpus[p->last_cpu]);
    800026c0:	0000fc97          	auipc	s9,0xf
    800026c4:	c10c8c93          	addi	s9,s9,-1008 # 800112d0 <cpus>
    800026c8:	0a800c13          	li	s8,168
  while(curr != empty) {
    800026cc:	5afd                	li	s5,-1
    800026ce:	a829                	j	800026e8 <wakeup+0x6e>
        append(&cpus[p->last_cpu].runnable_list, p);
      }
      release(&p->lock);
    800026d0:	854a                	mv	a0,s2
    800026d2:	ffffe097          	auipc	ra,0xffffe
    800026d6:	5c6080e7          	jalr	1478(ra) # 80000c98 <release>
    }
  curr = p->next_proc;
    800026da:	034484b3          	mul	s1,s1,s4
    800026de:	94ce                	add	s1,s1,s3
    800026e0:	16c4a483          	lw	s1,364(s1)
  while(curr != empty) {
    800026e4:	07548a63          	beq	s1,s5,80002758 <wakeup+0xde>
    p = &proc[curr];
    800026e8:	03448933          	mul	s2,s1,s4
    800026ec:	994e                	add	s2,s2,s3
    if(p != myproc()){
    800026ee:	fffff097          	auipc	ra,0xfffff
    800026f2:	5de080e7          	jalr	1502(ra) # 80001ccc <myproc>
    800026f6:	fea902e3          	beq	s2,a0,800026da <wakeup+0x60>
      acquire(&p->lock);
    800026fa:	854a                	mv	a0,s2
    800026fc:	ffffe097          	auipc	ra,0xffffe
    80002700:	4e8080e7          	jalr	1256(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002704:	01892783          	lw	a5,24(s2)
    80002708:	fd6794e3          	bne	a5,s6,800026d0 <wakeup+0x56>
    8000270c:	02093783          	ld	a5,32(s2)
    80002710:	fd7790e3          	bne	a5,s7,800026d0 <wakeup+0x56>
        remove(remove_from_SLEEPING_list, p);
    80002714:	85ca                	mv	a1,s2
    80002716:	856e                	mv	a0,s11
    80002718:	fffff097          	auipc	ra,0xfffff
    8000271c:	236080e7          	jalr	566(ra) # 8000194e <remove>
        p->state = RUNNABLE;
    80002720:	01a92c23          	sw	s10,24(s2)
        inc_cpu(&cpus[p->last_cpu]);
    80002724:	f9243423          	sd	s2,-120(s0)
    80002728:	16892503          	lw	a0,360(s2)
    8000272c:	03850533          	mul	a0,a0,s8
    80002730:	9566                	add	a0,a0,s9
    80002732:	fffff097          	auipc	ra,0xfffff
    80002736:	10c080e7          	jalr	268(ra) # 8000183e <inc_cpu>
        append(&cpus[p->last_cpu].runnable_list, p);
    8000273a:	f8843783          	ld	a5,-120(s0)
    8000273e:	1687a503          	lw	a0,360(a5)
    80002742:	03850533          	mul	a0,a0,s8
    80002746:	08850513          	addi	a0,a0,136
    8000274a:	85ca                	mv	a1,s2
    8000274c:	9566                	add	a0,a0,s9
    8000274e:	fffff097          	auipc	ra,0xfffff
    80002752:	138080e7          	jalr	312(ra) # 80001886 <append>
    80002756:	bfad                	j	800026d0 <wakeup+0x56>
  }
}
    80002758:	70e6                	ld	ra,120(sp)
    8000275a:	7446                	ld	s0,112(sp)
    8000275c:	74a6                	ld	s1,104(sp)
    8000275e:	7906                	ld	s2,96(sp)
    80002760:	69e6                	ld	s3,88(sp)
    80002762:	6a46                	ld	s4,80(sp)
    80002764:	6aa6                	ld	s5,72(sp)
    80002766:	6b06                	ld	s6,64(sp)
    80002768:	7be2                	ld	s7,56(sp)
    8000276a:	7c42                	ld	s8,48(sp)
    8000276c:	7ca2                	ld	s9,40(sp)
    8000276e:	7d02                	ld	s10,32(sp)
    80002770:	6de2                	ld	s11,24(sp)
    80002772:	6109                	addi	sp,sp,128
    80002774:	8082                	ret

0000000080002776 <reparent>:
{
    80002776:	7179                	addi	sp,sp,-48
    80002778:	f406                	sd	ra,40(sp)
    8000277a:	f022                	sd	s0,32(sp)
    8000277c:	ec26                	sd	s1,24(sp)
    8000277e:	e84a                	sd	s2,16(sp)
    80002780:	e44e                	sd	s3,8(sp)
    80002782:	e052                	sd	s4,0(sp)
    80002784:	1800                	addi	s0,sp,48
    80002786:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002788:	0000f497          	auipc	s1,0xf
    8000278c:	08848493          	addi	s1,s1,136 # 80011810 <proc>
      pp->parent = initproc;
    80002790:	00007a17          	auipc	s4,0x7
    80002794:	898a0a13          	addi	s4,s4,-1896 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002798:	00015997          	auipc	s3,0x15
    8000279c:	47898993          	addi	s3,s3,1144 # 80017c10 <tickslock>
    800027a0:	a029                	j	800027aa <reparent+0x34>
    800027a2:	19048493          	addi	s1,s1,400
    800027a6:	01348d63          	beq	s1,s3,800027c0 <reparent+0x4a>
    if(pp->parent == p){
    800027aa:	7c9c                	ld	a5,56(s1)
    800027ac:	ff279be3          	bne	a5,s2,800027a2 <reparent+0x2c>
      pp->parent = initproc;
    800027b0:	000a3503          	ld	a0,0(s4)
    800027b4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800027b6:	00000097          	auipc	ra,0x0
    800027ba:	ec4080e7          	jalr	-316(ra) # 8000267a <wakeup>
    800027be:	b7d5                	j	800027a2 <reparent+0x2c>
}
    800027c0:	70a2                	ld	ra,40(sp)
    800027c2:	7402                	ld	s0,32(sp)
    800027c4:	64e2                	ld	s1,24(sp)
    800027c6:	6942                	ld	s2,16(sp)
    800027c8:	69a2                	ld	s3,8(sp)
    800027ca:	6a02                	ld	s4,0(sp)
    800027cc:	6145                	addi	sp,sp,48
    800027ce:	8082                	ret

00000000800027d0 <exit>:
{
    800027d0:	7179                	addi	sp,sp,-48
    800027d2:	f406                	sd	ra,40(sp)
    800027d4:	f022                	sd	s0,32(sp)
    800027d6:	ec26                	sd	s1,24(sp)
    800027d8:	e84a                	sd	s2,16(sp)
    800027da:	e44e                	sd	s3,8(sp)
    800027dc:	e052                	sd	s4,0(sp)
    800027de:	1800                	addi	s0,sp,48
    800027e0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800027e2:	fffff097          	auipc	ra,0xfffff
    800027e6:	4ea080e7          	jalr	1258(ra) # 80001ccc <myproc>
    800027ea:	89aa                	mv	s3,a0
  if(p == initproc)
    800027ec:	00007797          	auipc	a5,0x7
    800027f0:	83c7b783          	ld	a5,-1988(a5) # 80009028 <initproc>
    800027f4:	0d050493          	addi	s1,a0,208
    800027f8:	15050913          	addi	s2,a0,336
    800027fc:	02a79363          	bne	a5,a0,80002822 <exit+0x52>
    panic("init exiting");
    80002800:	00006517          	auipc	a0,0x6
    80002804:	ae850513          	addi	a0,a0,-1304 # 800082e8 <digits+0x2a8>
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	d36080e7          	jalr	-714(ra) # 8000053e <panic>
      fileclose(f);
    80002810:	00002097          	auipc	ra,0x2
    80002814:	22a080e7          	jalr	554(ra) # 80004a3a <fileclose>
      p->ofile[fd] = 0;
    80002818:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000281c:	04a1                	addi	s1,s1,8
    8000281e:	01248563          	beq	s1,s2,80002828 <exit+0x58>
    if(p->ofile[fd]){
    80002822:	6088                	ld	a0,0(s1)
    80002824:	f575                	bnez	a0,80002810 <exit+0x40>
    80002826:	bfdd                	j	8000281c <exit+0x4c>
  begin_op();
    80002828:	00002097          	auipc	ra,0x2
    8000282c:	d46080e7          	jalr	-698(ra) # 8000456e <begin_op>
  iput(p->cwd);
    80002830:	1509b503          	ld	a0,336(s3)
    80002834:	00001097          	auipc	ra,0x1
    80002838:	522080e7          	jalr	1314(ra) # 80003d56 <iput>
  end_op();
    8000283c:	00002097          	auipc	ra,0x2
    80002840:	db2080e7          	jalr	-590(ra) # 800045ee <end_op>
  p->cwd = 0;
    80002844:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002848:	0000f497          	auipc	s1,0xf
    8000284c:	a7048493          	addi	s1,s1,-1424 # 800112b8 <wait_lock>
    80002850:	8526                	mv	a0,s1
    80002852:	ffffe097          	auipc	ra,0xffffe
    80002856:	392080e7          	jalr	914(ra) # 80000be4 <acquire>
  reparent(p);
    8000285a:	854e                	mv	a0,s3
    8000285c:	00000097          	auipc	ra,0x0
    80002860:	f1a080e7          	jalr	-230(ra) # 80002776 <reparent>
  wakeup(p->parent);
    80002864:	0389b503          	ld	a0,56(s3)
    80002868:	00000097          	auipc	ra,0x0
    8000286c:	e12080e7          	jalr	-494(ra) # 8000267a <wakeup>
  acquire(&p->lock);
    80002870:	854e                	mv	a0,s3
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	372080e7          	jalr	882(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000287a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000287e:	4795                	li	a5,5
    80002880:	00f9ac23          	sw	a5,24(s3)
  append(&zombie_list, p); 
    80002884:	85ce                	mv	a1,s3
    80002886:	00006517          	auipc	a0,0x6
    8000288a:	04a50513          	addi	a0,a0,74 # 800088d0 <zombie_list>
    8000288e:	fffff097          	auipc	ra,0xfffff
    80002892:	ff8080e7          	jalr	-8(ra) # 80001886 <append>
  release(&wait_lock);
    80002896:	8526                	mv	a0,s1
    80002898:	ffffe097          	auipc	ra,0xffffe
    8000289c:	400080e7          	jalr	1024(ra) # 80000c98 <release>
  sched();
    800028a0:	00000097          	auipc	ra,0x0
    800028a4:	af6080e7          	jalr	-1290(ra) # 80002396 <sched>
  panic("zombie exit");
    800028a8:	00006517          	auipc	a0,0x6
    800028ac:	a5050513          	addi	a0,a0,-1456 # 800082f8 <digits+0x2b8>
    800028b0:	ffffe097          	auipc	ra,0xffffe
    800028b4:	c8e080e7          	jalr	-882(ra) # 8000053e <panic>

00000000800028b8 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800028b8:	7179                	addi	sp,sp,-48
    800028ba:	f406                	sd	ra,40(sp)
    800028bc:	f022                	sd	s0,32(sp)
    800028be:	ec26                	sd	s1,24(sp)
    800028c0:	e84a                	sd	s2,16(sp)
    800028c2:	e44e                	sd	s3,8(sp)
    800028c4:	1800                	addi	s0,sp,48
    800028c6:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800028c8:	0000f497          	auipc	s1,0xf
    800028cc:	f4848493          	addi	s1,s1,-184 # 80011810 <proc>
    800028d0:	00015997          	auipc	s3,0x15
    800028d4:	34098993          	addi	s3,s3,832 # 80017c10 <tickslock>
    acquire(&p->lock);
    800028d8:	8526                	mv	a0,s1
    800028da:	ffffe097          	auipc	ra,0xffffe
    800028de:	30a080e7          	jalr	778(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800028e2:	589c                	lw	a5,48(s1)
    800028e4:	01278d63          	beq	a5,s2,800028fe <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800028e8:	8526                	mv	a0,s1
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	3ae080e7          	jalr	942(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800028f2:	19048493          	addi	s1,s1,400
    800028f6:	ff3491e3          	bne	s1,s3,800028d8 <kill+0x20>
  }
  return -1;
    800028fa:	557d                	li	a0,-1
    800028fc:	a829                	j	80002916 <kill+0x5e>
      p->killed = 1;
    800028fe:	4785                	li	a5,1
    80002900:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002902:	4c98                	lw	a4,24(s1)
    80002904:	4789                	li	a5,2
    80002906:	00f70f63          	beq	a4,a5,80002924 <kill+0x6c>
      release(&p->lock);
    8000290a:	8526                	mv	a0,s1
    8000290c:	ffffe097          	auipc	ra,0xffffe
    80002910:	38c080e7          	jalr	908(ra) # 80000c98 <release>
      return 0;
    80002914:	4501                	li	a0,0
}
    80002916:	70a2                	ld	ra,40(sp)
    80002918:	7402                	ld	s0,32(sp)
    8000291a:	64e2                	ld	s1,24(sp)
    8000291c:	6942                	ld	s2,16(sp)
    8000291e:	69a2                	ld	s3,8(sp)
    80002920:	6145                	addi	sp,sp,48
    80002922:	8082                	ret
        p->state = RUNNABLE;
    80002924:	478d                	li	a5,3
    80002926:	cc9c                	sw	a5,24(s1)
    80002928:	b7cd                	j	8000290a <kill+0x52>

000000008000292a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000292a:	7179                	addi	sp,sp,-48
    8000292c:	f406                	sd	ra,40(sp)
    8000292e:	f022                	sd	s0,32(sp)
    80002930:	ec26                	sd	s1,24(sp)
    80002932:	e84a                	sd	s2,16(sp)
    80002934:	e44e                	sd	s3,8(sp)
    80002936:	e052                	sd	s4,0(sp)
    80002938:	1800                	addi	s0,sp,48
    8000293a:	84aa                	mv	s1,a0
    8000293c:	892e                	mv	s2,a1
    8000293e:	89b2                	mv	s3,a2
    80002940:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002942:	fffff097          	auipc	ra,0xfffff
    80002946:	38a080e7          	jalr	906(ra) # 80001ccc <myproc>
  if(user_dst){
    8000294a:	c08d                	beqz	s1,8000296c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000294c:	86d2                	mv	a3,s4
    8000294e:	864e                	mv	a2,s3
    80002950:	85ca                	mv	a1,s2
    80002952:	6928                	ld	a0,80(a0)
    80002954:	fffff097          	auipc	ra,0xfffff
    80002958:	d1e080e7          	jalr	-738(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000295c:	70a2                	ld	ra,40(sp)
    8000295e:	7402                	ld	s0,32(sp)
    80002960:	64e2                	ld	s1,24(sp)
    80002962:	6942                	ld	s2,16(sp)
    80002964:	69a2                	ld	s3,8(sp)
    80002966:	6a02                	ld	s4,0(sp)
    80002968:	6145                	addi	sp,sp,48
    8000296a:	8082                	ret
    memmove((char *)dst, src, len);
    8000296c:	000a061b          	sext.w	a2,s4
    80002970:	85ce                	mv	a1,s3
    80002972:	854a                	mv	a0,s2
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	3cc080e7          	jalr	972(ra) # 80000d40 <memmove>
    return 0;
    8000297c:	8526                	mv	a0,s1
    8000297e:	bff9                	j	8000295c <either_copyout+0x32>

0000000080002980 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002980:	7179                	addi	sp,sp,-48
    80002982:	f406                	sd	ra,40(sp)
    80002984:	f022                	sd	s0,32(sp)
    80002986:	ec26                	sd	s1,24(sp)
    80002988:	e84a                	sd	s2,16(sp)
    8000298a:	e44e                	sd	s3,8(sp)
    8000298c:	e052                	sd	s4,0(sp)
    8000298e:	1800                	addi	s0,sp,48
    80002990:	892a                	mv	s2,a0
    80002992:	84ae                	mv	s1,a1
    80002994:	89b2                	mv	s3,a2
    80002996:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002998:	fffff097          	auipc	ra,0xfffff
    8000299c:	334080e7          	jalr	820(ra) # 80001ccc <myproc>
  if(user_src){
    800029a0:	c08d                	beqz	s1,800029c2 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800029a2:	86d2                	mv	a3,s4
    800029a4:	864e                	mv	a2,s3
    800029a6:	85ca                	mv	a1,s2
    800029a8:	6928                	ld	a0,80(a0)
    800029aa:	fffff097          	auipc	ra,0xfffff
    800029ae:	d54080e7          	jalr	-684(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
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
    memmove(dst, (char*)src, len);
    800029c2:	000a061b          	sext.w	a2,s4
    800029c6:	85ce                	mv	a1,s3
    800029c8:	854a                	mv	a0,s2
    800029ca:	ffffe097          	auipc	ra,0xffffe
    800029ce:	376080e7          	jalr	886(ra) # 80000d40 <memmove>
    return 0;
    800029d2:	8526                	mv	a0,s1
    800029d4:	bff9                	j	800029b2 <either_copyin+0x32>

00000000800029d6 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    800029d6:	715d                	addi	sp,sp,-80
    800029d8:	e486                	sd	ra,72(sp)
    800029da:	e0a2                	sd	s0,64(sp)
    800029dc:	fc26                	sd	s1,56(sp)
    800029de:	f84a                	sd	s2,48(sp)
    800029e0:	f44e                	sd	s3,40(sp)
    800029e2:	f052                	sd	s4,32(sp)
    800029e4:	ec56                	sd	s5,24(sp)
    800029e6:	e85a                	sd	s6,16(sp)
    800029e8:	e45e                	sd	s7,8(sp)
    800029ea:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800029ec:	00005517          	auipc	a0,0x5
    800029f0:	6dc50513          	addi	a0,a0,1756 # 800080c8 <digits+0x88>
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	b94080e7          	jalr	-1132(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800029fc:	0000f497          	auipc	s1,0xf
    80002a00:	f6c48493          	addi	s1,s1,-148 # 80011968 <proc+0x158>
    80002a04:	00015917          	auipc	s2,0x15
    80002a08:	36490913          	addi	s2,s2,868 # 80017d68 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a0c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    80002a0e:	00006997          	auipc	s3,0x6
    80002a12:	8fa98993          	addi	s3,s3,-1798 # 80008308 <digits+0x2c8>
    printf("%d %s %s", p->pid, state, p->name);
    80002a16:	00006a97          	auipc	s5,0x6
    80002a1a:	8faa8a93          	addi	s5,s5,-1798 # 80008310 <digits+0x2d0>
    printf("\n");
    80002a1e:	00005a17          	auipc	s4,0x5
    80002a22:	6aaa0a13          	addi	s4,s4,1706 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a26:	00006b97          	auipc	s7,0x6
    80002a2a:	922b8b93          	addi	s7,s7,-1758 # 80008348 <states.1777>
    80002a2e:	a00d                	j	80002a50 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002a30:	ed86a583          	lw	a1,-296(a3)
    80002a34:	8556                	mv	a0,s5
    80002a36:	ffffe097          	auipc	ra,0xffffe
    80002a3a:	b52080e7          	jalr	-1198(ra) # 80000588 <printf>
    printf("\n");
    80002a3e:	8552                	mv	a0,s4
    80002a40:	ffffe097          	auipc	ra,0xffffe
    80002a44:	b48080e7          	jalr	-1208(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a48:	19048493          	addi	s1,s1,400
    80002a4c:	03248163          	beq	s1,s2,80002a6e <procdump+0x98>
    if(p->state == UNUSED)
    80002a50:	86a6                	mv	a3,s1
    80002a52:	ec04a783          	lw	a5,-320(s1)
    80002a56:	dbed                	beqz	a5,80002a48 <procdump+0x72>
      state = "???"; 
    80002a58:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a5a:	fcfb6be3          	bltu	s6,a5,80002a30 <procdump+0x5a>
    80002a5e:	1782                	slli	a5,a5,0x20
    80002a60:	9381                	srli	a5,a5,0x20
    80002a62:	078e                	slli	a5,a5,0x3
    80002a64:	97de                	add	a5,a5,s7
    80002a66:	6390                	ld	a2,0(a5)
    80002a68:	f661                	bnez	a2,80002a30 <procdump+0x5a>
      state = "???"; 
    80002a6a:	864e                	mv	a2,s3
    80002a6c:	b7d1                	j	80002a30 <procdump+0x5a>
  }
}
    80002a6e:	60a6                	ld	ra,72(sp)
    80002a70:	6406                	ld	s0,64(sp)
    80002a72:	74e2                	ld	s1,56(sp)
    80002a74:	7942                	ld	s2,48(sp)
    80002a76:	79a2                	ld	s3,40(sp)
    80002a78:	7a02                	ld	s4,32(sp)
    80002a7a:	6ae2                	ld	s5,24(sp)
    80002a7c:	6b42                	ld	s6,16(sp)
    80002a7e:	6ba2                	ld	s7,8(sp)
    80002a80:	6161                	addi	sp,sp,80
    80002a82:	8082                	ret

0000000080002a84 <set_cpu>:

// move process to different CPU. 
int
set_cpu(int cpu_num) {
  int fail = -1;
  if(cpu_num < NCPU) {
    80002a84:	479d                	li	a5,7
    80002a86:	04a7e863          	bltu	a5,a0,80002ad6 <set_cpu+0x52>
set_cpu(int cpu_num) {
    80002a8a:	1101                	addi	sp,sp,-32
    80002a8c:	ec06                	sd	ra,24(sp)
    80002a8e:	e822                	sd	s0,16(sp)
    80002a90:	e426                	sd	s1,8(sp)
    80002a92:	1000                	addi	s0,sp,32
    80002a94:	84aa                	mv	s1,a0
   if(cpu_num >= 0) {
     struct cpu *c = &cpus[cpu_num];
     if(c != NULL) {
        acquire(&myproc()->lock);
    80002a96:	fffff097          	auipc	ra,0xfffff
    80002a9a:	236080e7          	jalr	566(ra) # 80001ccc <myproc>
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	146080e7          	jalr	326(ra) # 80000be4 <acquire>
        myproc()->last_cpu = cpu_num;
    80002aa6:	fffff097          	auipc	ra,0xfffff
    80002aaa:	226080e7          	jalr	550(ra) # 80001ccc <myproc>
    80002aae:	16952423          	sw	s1,360(a0)
        release(&myproc()->lock);
    80002ab2:	fffff097          	auipc	ra,0xfffff
    80002ab6:	21a080e7          	jalr	538(ra) # 80001ccc <myproc>
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	1de080e7          	jalr	478(ra) # 80000c98 <release>

        // RUNNING -> RUNNABLE
        yield();
    80002ac2:	00000097          	auipc	ra,0x0
    80002ac6:	9be080e7          	jalr	-1602(ra) # 80002480 <yield>
        return cpu_num;
    80002aca:	8526                	mv	a0,s1
      }
    }
  }
  return fail;
}
    80002acc:	60e2                	ld	ra,24(sp)
    80002ace:	6442                	ld	s0,16(sp)
    80002ad0:	64a2                	ld	s1,8(sp)
    80002ad2:	6105                	addi	sp,sp,32
    80002ad4:	8082                	ret
  return fail;
    80002ad6:	557d                	li	a0,-1
}
    80002ad8:	8082                	ret

0000000080002ada <get_cpu>:

// returns current CPU.
int
get_cpu(void){
    80002ada:	1141                	addi	sp,sp,-16
    80002adc:	e406                	sd	ra,8(sp)
    80002ade:	e022                	sd	s0,0(sp)
    80002ae0:	0800                	addi	s0,sp,16

  // If process was not chosen by any cpy the value of myproc()->last_cpu is -1.
  return myproc()->last_cpu;
    80002ae2:	fffff097          	auipc	ra,0xfffff
    80002ae6:	1ea080e7          	jalr	490(ra) # 80001ccc <myproc>
}
    80002aea:	16852503          	lw	a0,360(a0)
    80002aee:	60a2                	ld	ra,8(sp)
    80002af0:	6402                	ld	s0,0(sp)
    80002af2:	0141                	addi	sp,sp,16
    80002af4:	8082                	ret

0000000080002af6 <min_cpu>:

int
min_cpu(void){
    80002af6:	1141                	addi	sp,sp,-16
    80002af8:	e422                	sd	s0,8(sp)
    80002afa:	0800                	addi	s0,sp,16
  struct cpu *c;
  struct cpu *min_cpu = cpus;
    80002afc:	0000e617          	auipc	a2,0xe
    80002b00:	7d460613          	addi	a2,a2,2004 # 800112d0 <cpus>
  
  for(c = cpus + 1; c < &cpus[NCPU] && c != NULL ; c++){
    80002b04:	0000f797          	auipc	a5,0xf
    80002b08:	87478793          	addi	a5,a5,-1932 # 80011378 <cpus+0xa8>
    80002b0c:	0000f597          	auipc	a1,0xf
    80002b10:	d0458593          	addi	a1,a1,-764 # 80011810 <proc>
    80002b14:	a029                	j	80002b1e <min_cpu+0x28>
    80002b16:	0a878793          	addi	a5,a5,168
    80002b1a:	00b78a63          	beq	a5,a1,80002b2e <min_cpu+0x38>
    if (c->proc_cnt < min_cpu->proc_cnt)
    80002b1e:	0807a683          	lw	a3,128(a5)
    80002b22:	08062703          	lw	a4,128(a2)
    80002b26:	fee6d8e3          	bge	a3,a4,80002b16 <min_cpu+0x20>
    80002b2a:	863e                	mv	a2,a5
    80002b2c:	b7ed                	j	80002b16 <min_cpu+0x20>
        min_cpu = c;
  }
  return min_cpu->cpu_id;   
}
    80002b2e:	08462503          	lw	a0,132(a2)
    80002b32:	6422                	ld	s0,8(sp)
    80002b34:	0141                	addi	sp,sp,16
    80002b36:	8082                	ret

0000000080002b38 <swtch>:
    80002b38:	00153023          	sd	ra,0(a0)
    80002b3c:	00253423          	sd	sp,8(a0)
    80002b40:	e900                	sd	s0,16(a0)
    80002b42:	ed04                	sd	s1,24(a0)
    80002b44:	03253023          	sd	s2,32(a0)
    80002b48:	03353423          	sd	s3,40(a0)
    80002b4c:	03453823          	sd	s4,48(a0)
    80002b50:	03553c23          	sd	s5,56(a0)
    80002b54:	05653023          	sd	s6,64(a0)
    80002b58:	05753423          	sd	s7,72(a0)
    80002b5c:	05853823          	sd	s8,80(a0)
    80002b60:	05953c23          	sd	s9,88(a0)
    80002b64:	07a53023          	sd	s10,96(a0)
    80002b68:	07b53423          	sd	s11,104(a0)
    80002b6c:	0005b083          	ld	ra,0(a1)
    80002b70:	0085b103          	ld	sp,8(a1)
    80002b74:	6980                	ld	s0,16(a1)
    80002b76:	6d84                	ld	s1,24(a1)
    80002b78:	0205b903          	ld	s2,32(a1)
    80002b7c:	0285b983          	ld	s3,40(a1)
    80002b80:	0305ba03          	ld	s4,48(a1)
    80002b84:	0385ba83          	ld	s5,56(a1)
    80002b88:	0405bb03          	ld	s6,64(a1)
    80002b8c:	0485bb83          	ld	s7,72(a1)
    80002b90:	0505bc03          	ld	s8,80(a1)
    80002b94:	0585bc83          	ld	s9,88(a1)
    80002b98:	0605bd03          	ld	s10,96(a1)
    80002b9c:	0685bd83          	ld	s11,104(a1)
    80002ba0:	8082                	ret

0000000080002ba2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002ba2:	1141                	addi	sp,sp,-16
    80002ba4:	e406                	sd	ra,8(sp)
    80002ba6:	e022                	sd	s0,0(sp)
    80002ba8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002baa:	00005597          	auipc	a1,0x5
    80002bae:	7ce58593          	addi	a1,a1,1998 # 80008378 <states.1777+0x30>
    80002bb2:	00015517          	auipc	a0,0x15
    80002bb6:	05e50513          	addi	a0,a0,94 # 80017c10 <tickslock>
    80002bba:	ffffe097          	auipc	ra,0xffffe
    80002bbe:	f9a080e7          	jalr	-102(ra) # 80000b54 <initlock>
}
    80002bc2:	60a2                	ld	ra,8(sp)
    80002bc4:	6402                	ld	s0,0(sp)
    80002bc6:	0141                	addi	sp,sp,16
    80002bc8:	8082                	ret

0000000080002bca <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002bca:	1141                	addi	sp,sp,-16
    80002bcc:	e422                	sd	s0,8(sp)
    80002bce:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bd0:	00003797          	auipc	a5,0x3
    80002bd4:	48078793          	addi	a5,a5,1152 # 80006050 <kernelvec>
    80002bd8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002bdc:	6422                	ld	s0,8(sp)
    80002bde:	0141                	addi	sp,sp,16
    80002be0:	8082                	ret

0000000080002be2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002be2:	1141                	addi	sp,sp,-16
    80002be4:	e406                	sd	ra,8(sp)
    80002be6:	e022                	sd	s0,0(sp)
    80002be8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002bea:	fffff097          	auipc	ra,0xfffff
    80002bee:	0e2080e7          	jalr	226(ra) # 80001ccc <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bf2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002bf6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bf8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002bfc:	00004617          	auipc	a2,0x4
    80002c00:	40460613          	addi	a2,a2,1028 # 80007000 <_trampoline>
    80002c04:	00004697          	auipc	a3,0x4
    80002c08:	3fc68693          	addi	a3,a3,1020 # 80007000 <_trampoline>
    80002c0c:	8e91                	sub	a3,a3,a2
    80002c0e:	040007b7          	lui	a5,0x4000
    80002c12:	17fd                	addi	a5,a5,-1
    80002c14:	07b2                	slli	a5,a5,0xc
    80002c16:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c18:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c1c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c1e:	180026f3          	csrr	a3,satp
    80002c22:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c24:	6d38                	ld	a4,88(a0)
    80002c26:	6134                	ld	a3,64(a0)
    80002c28:	6585                	lui	a1,0x1
    80002c2a:	96ae                	add	a3,a3,a1
    80002c2c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c2e:	6d38                	ld	a4,88(a0)
    80002c30:	00000697          	auipc	a3,0x0
    80002c34:	13868693          	addi	a3,a3,312 # 80002d68 <usertrap>
    80002c38:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c3a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c3c:	8692                	mv	a3,tp
    80002c3e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c40:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c44:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c48:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c4c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c50:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c52:	6f18                	ld	a4,24(a4)
    80002c54:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c58:	692c                	ld	a1,80(a0)
    80002c5a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002c5c:	00004717          	auipc	a4,0x4
    80002c60:	43470713          	addi	a4,a4,1076 # 80007090 <userret>
    80002c64:	8f11                	sub	a4,a4,a2
    80002c66:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002c68:	577d                	li	a4,-1
    80002c6a:	177e                	slli	a4,a4,0x3f
    80002c6c:	8dd9                	or	a1,a1,a4
    80002c6e:	02000537          	lui	a0,0x2000
    80002c72:	157d                	addi	a0,a0,-1
    80002c74:	0536                	slli	a0,a0,0xd
    80002c76:	9782                	jalr	a5
}
    80002c78:	60a2                	ld	ra,8(sp)
    80002c7a:	6402                	ld	s0,0(sp)
    80002c7c:	0141                	addi	sp,sp,16
    80002c7e:	8082                	ret

0000000080002c80 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c80:	1101                	addi	sp,sp,-32
    80002c82:	ec06                	sd	ra,24(sp)
    80002c84:	e822                	sd	s0,16(sp)
    80002c86:	e426                	sd	s1,8(sp)
    80002c88:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c8a:	00015497          	auipc	s1,0x15
    80002c8e:	f8648493          	addi	s1,s1,-122 # 80017c10 <tickslock>
    80002c92:	8526                	mv	a0,s1
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	f50080e7          	jalr	-176(ra) # 80000be4 <acquire>
  ticks++;
    80002c9c:	00006517          	auipc	a0,0x6
    80002ca0:	39450513          	addi	a0,a0,916 # 80009030 <ticks>
    80002ca4:	411c                	lw	a5,0(a0)
    80002ca6:	2785                	addiw	a5,a5,1
    80002ca8:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002caa:	00000097          	auipc	ra,0x0
    80002cae:	9d0080e7          	jalr	-1584(ra) # 8000267a <wakeup>
  release(&tickslock);
    80002cb2:	8526                	mv	a0,s1
    80002cb4:	ffffe097          	auipc	ra,0xffffe
    80002cb8:	fe4080e7          	jalr	-28(ra) # 80000c98 <release>
}
    80002cbc:	60e2                	ld	ra,24(sp)
    80002cbe:	6442                	ld	s0,16(sp)
    80002cc0:	64a2                	ld	s1,8(sp)
    80002cc2:	6105                	addi	sp,sp,32
    80002cc4:	8082                	ret

0000000080002cc6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002cc6:	1101                	addi	sp,sp,-32
    80002cc8:	ec06                	sd	ra,24(sp)
    80002cca:	e822                	sd	s0,16(sp)
    80002ccc:	e426                	sd	s1,8(sp)
    80002cce:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cd0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002cd4:	00074d63          	bltz	a4,80002cee <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002cd8:	57fd                	li	a5,-1
    80002cda:	17fe                	slli	a5,a5,0x3f
    80002cdc:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002cde:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002ce0:	06f70363          	beq	a4,a5,80002d46 <devintr+0x80>
  }
}
    80002ce4:	60e2                	ld	ra,24(sp)
    80002ce6:	6442                	ld	s0,16(sp)
    80002ce8:	64a2                	ld	s1,8(sp)
    80002cea:	6105                	addi	sp,sp,32
    80002cec:	8082                	ret
     (scause & 0xff) == 9){
    80002cee:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002cf2:	46a5                	li	a3,9
    80002cf4:	fed792e3          	bne	a5,a3,80002cd8 <devintr+0x12>
    int irq = plic_claim();
    80002cf8:	00003097          	auipc	ra,0x3
    80002cfc:	460080e7          	jalr	1120(ra) # 80006158 <plic_claim>
    80002d00:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d02:	47a9                	li	a5,10
    80002d04:	02f50763          	beq	a0,a5,80002d32 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002d08:	4785                	li	a5,1
    80002d0a:	02f50963          	beq	a0,a5,80002d3c <devintr+0x76>
    return 1;
    80002d0e:	4505                	li	a0,1
    } else if(irq){
    80002d10:	d8f1                	beqz	s1,80002ce4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d12:	85a6                	mv	a1,s1
    80002d14:	00005517          	auipc	a0,0x5
    80002d18:	66c50513          	addi	a0,a0,1644 # 80008380 <states.1777+0x38>
    80002d1c:	ffffe097          	auipc	ra,0xffffe
    80002d20:	86c080e7          	jalr	-1940(ra) # 80000588 <printf>
      plic_complete(irq);
    80002d24:	8526                	mv	a0,s1
    80002d26:	00003097          	auipc	ra,0x3
    80002d2a:	456080e7          	jalr	1110(ra) # 8000617c <plic_complete>
    return 1;
    80002d2e:	4505                	li	a0,1
    80002d30:	bf55                	j	80002ce4 <devintr+0x1e>
      uartintr();
    80002d32:	ffffe097          	auipc	ra,0xffffe
    80002d36:	c76080e7          	jalr	-906(ra) # 800009a8 <uartintr>
    80002d3a:	b7ed                	j	80002d24 <devintr+0x5e>
      virtio_disk_intr();
    80002d3c:	00004097          	auipc	ra,0x4
    80002d40:	920080e7          	jalr	-1760(ra) # 8000665c <virtio_disk_intr>
    80002d44:	b7c5                	j	80002d24 <devintr+0x5e>
    if(cpuid() == 0){
    80002d46:	fffff097          	auipc	ra,0xfffff
    80002d4a:	f54080e7          	jalr	-172(ra) # 80001c9a <cpuid>
    80002d4e:	c901                	beqz	a0,80002d5e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d50:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d54:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d56:	14479073          	csrw	sip,a5
    return 2;
    80002d5a:	4509                	li	a0,2
    80002d5c:	b761                	j	80002ce4 <devintr+0x1e>
      clockintr();
    80002d5e:	00000097          	auipc	ra,0x0
    80002d62:	f22080e7          	jalr	-222(ra) # 80002c80 <clockintr>
    80002d66:	b7ed                	j	80002d50 <devintr+0x8a>

0000000080002d68 <usertrap>:
{
    80002d68:	1101                	addi	sp,sp,-32
    80002d6a:	ec06                	sd	ra,24(sp)
    80002d6c:	e822                	sd	s0,16(sp)
    80002d6e:	e426                	sd	s1,8(sp)
    80002d70:	e04a                	sd	s2,0(sp)
    80002d72:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d74:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d78:	1007f793          	andi	a5,a5,256
    80002d7c:	e3ad                	bnez	a5,80002dde <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d7e:	00003797          	auipc	a5,0x3
    80002d82:	2d278793          	addi	a5,a5,722 # 80006050 <kernelvec>
    80002d86:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d8a:	fffff097          	auipc	ra,0xfffff
    80002d8e:	f42080e7          	jalr	-190(ra) # 80001ccc <myproc>
    80002d92:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d94:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d96:	14102773          	csrr	a4,sepc
    80002d9a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d9c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002da0:	47a1                	li	a5,8
    80002da2:	04f71c63          	bne	a4,a5,80002dfa <usertrap+0x92>
    if(p->killed)
    80002da6:	551c                	lw	a5,40(a0)
    80002da8:	e3b9                	bnez	a5,80002dee <usertrap+0x86>
    p->trapframe->epc += 4;
    80002daa:	6cb8                	ld	a4,88(s1)
    80002dac:	6f1c                	ld	a5,24(a4)
    80002dae:	0791                	addi	a5,a5,4
    80002db0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002db2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002db6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dba:	10079073          	csrw	sstatus,a5
    syscall();
    80002dbe:	00000097          	auipc	ra,0x0
    80002dc2:	2e0080e7          	jalr	736(ra) # 8000309e <syscall>
  if(p->killed)
    80002dc6:	549c                	lw	a5,40(s1)
    80002dc8:	ebc1                	bnez	a5,80002e58 <usertrap+0xf0>
  usertrapret();
    80002dca:	00000097          	auipc	ra,0x0
    80002dce:	e18080e7          	jalr	-488(ra) # 80002be2 <usertrapret>
}
    80002dd2:	60e2                	ld	ra,24(sp)
    80002dd4:	6442                	ld	s0,16(sp)
    80002dd6:	64a2                	ld	s1,8(sp)
    80002dd8:	6902                	ld	s2,0(sp)
    80002dda:	6105                	addi	sp,sp,32
    80002ddc:	8082                	ret
    panic("usertrap: not from user mode");
    80002dde:	00005517          	auipc	a0,0x5
    80002de2:	5c250513          	addi	a0,a0,1474 # 800083a0 <states.1777+0x58>
    80002de6:	ffffd097          	auipc	ra,0xffffd
    80002dea:	758080e7          	jalr	1880(ra) # 8000053e <panic>
      exit(-1);
    80002dee:	557d                	li	a0,-1
    80002df0:	00000097          	auipc	ra,0x0
    80002df4:	9e0080e7          	jalr	-1568(ra) # 800027d0 <exit>
    80002df8:	bf4d                	j	80002daa <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002dfa:	00000097          	auipc	ra,0x0
    80002dfe:	ecc080e7          	jalr	-308(ra) # 80002cc6 <devintr>
    80002e02:	892a                	mv	s2,a0
    80002e04:	c501                	beqz	a0,80002e0c <usertrap+0xa4>
  if(p->killed)
    80002e06:	549c                	lw	a5,40(s1)
    80002e08:	c3a1                	beqz	a5,80002e48 <usertrap+0xe0>
    80002e0a:	a815                	j	80002e3e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e0c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e10:	5890                	lw	a2,48(s1)
    80002e12:	00005517          	auipc	a0,0x5
    80002e16:	5ae50513          	addi	a0,a0,1454 # 800083c0 <states.1777+0x78>
    80002e1a:	ffffd097          	auipc	ra,0xffffd
    80002e1e:	76e080e7          	jalr	1902(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e22:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e26:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e2a:	00005517          	auipc	a0,0x5
    80002e2e:	5c650513          	addi	a0,a0,1478 # 800083f0 <states.1777+0xa8>
    80002e32:	ffffd097          	auipc	ra,0xffffd
    80002e36:	756080e7          	jalr	1878(ra) # 80000588 <printf>
    p->killed = 1;
    80002e3a:	4785                	li	a5,1
    80002e3c:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002e3e:	557d                	li	a0,-1
    80002e40:	00000097          	auipc	ra,0x0
    80002e44:	990080e7          	jalr	-1648(ra) # 800027d0 <exit>
  if(which_dev == 2)
    80002e48:	4789                	li	a5,2
    80002e4a:	f8f910e3          	bne	s2,a5,80002dca <usertrap+0x62>
    yield();
    80002e4e:	fffff097          	auipc	ra,0xfffff
    80002e52:	632080e7          	jalr	1586(ra) # 80002480 <yield>
    80002e56:	bf95                	j	80002dca <usertrap+0x62>
  int which_dev = 0;
    80002e58:	4901                	li	s2,0
    80002e5a:	b7d5                	j	80002e3e <usertrap+0xd6>

0000000080002e5c <kerneltrap>:
{
    80002e5c:	7179                	addi	sp,sp,-48
    80002e5e:	f406                	sd	ra,40(sp)
    80002e60:	f022                	sd	s0,32(sp)
    80002e62:	ec26                	sd	s1,24(sp)
    80002e64:	e84a                	sd	s2,16(sp)
    80002e66:	e44e                	sd	s3,8(sp)
    80002e68:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e6a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e6e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e72:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e76:	1004f793          	andi	a5,s1,256
    80002e7a:	cb85                	beqz	a5,80002eaa <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e7c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e80:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e82:	ef85                	bnez	a5,80002eba <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e84:	00000097          	auipc	ra,0x0
    80002e88:	e42080e7          	jalr	-446(ra) # 80002cc6 <devintr>
    80002e8c:	cd1d                	beqz	a0,80002eca <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e8e:	4789                	li	a5,2
    80002e90:	06f50a63          	beq	a0,a5,80002f04 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e94:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e98:	10049073          	csrw	sstatus,s1
}
    80002e9c:	70a2                	ld	ra,40(sp)
    80002e9e:	7402                	ld	s0,32(sp)
    80002ea0:	64e2                	ld	s1,24(sp)
    80002ea2:	6942                	ld	s2,16(sp)
    80002ea4:	69a2                	ld	s3,8(sp)
    80002ea6:	6145                	addi	sp,sp,48
    80002ea8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002eaa:	00005517          	auipc	a0,0x5
    80002eae:	56650513          	addi	a0,a0,1382 # 80008410 <states.1777+0xc8>
    80002eb2:	ffffd097          	auipc	ra,0xffffd
    80002eb6:	68c080e7          	jalr	1676(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002eba:	00005517          	auipc	a0,0x5
    80002ebe:	57e50513          	addi	a0,a0,1406 # 80008438 <states.1777+0xf0>
    80002ec2:	ffffd097          	auipc	ra,0xffffd
    80002ec6:	67c080e7          	jalr	1660(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002eca:	85ce                	mv	a1,s3
    80002ecc:	00005517          	auipc	a0,0x5
    80002ed0:	58c50513          	addi	a0,a0,1420 # 80008458 <states.1777+0x110>
    80002ed4:	ffffd097          	auipc	ra,0xffffd
    80002ed8:	6b4080e7          	jalr	1716(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002edc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ee0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ee4:	00005517          	auipc	a0,0x5
    80002ee8:	58450513          	addi	a0,a0,1412 # 80008468 <states.1777+0x120>
    80002eec:	ffffd097          	auipc	ra,0xffffd
    80002ef0:	69c080e7          	jalr	1692(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002ef4:	00005517          	auipc	a0,0x5
    80002ef8:	58c50513          	addi	a0,a0,1420 # 80008480 <states.1777+0x138>
    80002efc:	ffffd097          	auipc	ra,0xffffd
    80002f00:	642080e7          	jalr	1602(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f04:	fffff097          	auipc	ra,0xfffff
    80002f08:	dc8080e7          	jalr	-568(ra) # 80001ccc <myproc>
    80002f0c:	d541                	beqz	a0,80002e94 <kerneltrap+0x38>
    80002f0e:	fffff097          	auipc	ra,0xfffff
    80002f12:	dbe080e7          	jalr	-578(ra) # 80001ccc <myproc>
    80002f16:	4d18                	lw	a4,24(a0)
    80002f18:	4791                	li	a5,4
    80002f1a:	f6f71de3          	bne	a4,a5,80002e94 <kerneltrap+0x38>
    yield();
    80002f1e:	fffff097          	auipc	ra,0xfffff
    80002f22:	562080e7          	jalr	1378(ra) # 80002480 <yield>
    80002f26:	b7bd                	j	80002e94 <kerneltrap+0x38>

0000000080002f28 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f28:	1101                	addi	sp,sp,-32
    80002f2a:	ec06                	sd	ra,24(sp)
    80002f2c:	e822                	sd	s0,16(sp)
    80002f2e:	e426                	sd	s1,8(sp)
    80002f30:	1000                	addi	s0,sp,32
    80002f32:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f34:	fffff097          	auipc	ra,0xfffff
    80002f38:	d98080e7          	jalr	-616(ra) # 80001ccc <myproc>
  switch (n) {
    80002f3c:	4795                	li	a5,5
    80002f3e:	0497e163          	bltu	a5,s1,80002f80 <argraw+0x58>
    80002f42:	048a                	slli	s1,s1,0x2
    80002f44:	00005717          	auipc	a4,0x5
    80002f48:	57470713          	addi	a4,a4,1396 # 800084b8 <states.1777+0x170>
    80002f4c:	94ba                	add	s1,s1,a4
    80002f4e:	409c                	lw	a5,0(s1)
    80002f50:	97ba                	add	a5,a5,a4
    80002f52:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002f54:	6d3c                	ld	a5,88(a0)
    80002f56:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f58:	60e2                	ld	ra,24(sp)
    80002f5a:	6442                	ld	s0,16(sp)
    80002f5c:	64a2                	ld	s1,8(sp)
    80002f5e:	6105                	addi	sp,sp,32
    80002f60:	8082                	ret
    return p->trapframe->a1;
    80002f62:	6d3c                	ld	a5,88(a0)
    80002f64:	7fa8                	ld	a0,120(a5)
    80002f66:	bfcd                	j	80002f58 <argraw+0x30>
    return p->trapframe->a2;
    80002f68:	6d3c                	ld	a5,88(a0)
    80002f6a:	63c8                	ld	a0,128(a5)
    80002f6c:	b7f5                	j	80002f58 <argraw+0x30>
    return p->trapframe->a3;
    80002f6e:	6d3c                	ld	a5,88(a0)
    80002f70:	67c8                	ld	a0,136(a5)
    80002f72:	b7dd                	j	80002f58 <argraw+0x30>
    return p->trapframe->a4;
    80002f74:	6d3c                	ld	a5,88(a0)
    80002f76:	6bc8                	ld	a0,144(a5)
    80002f78:	b7c5                	j	80002f58 <argraw+0x30>
    return p->trapframe->a5;
    80002f7a:	6d3c                	ld	a5,88(a0)
    80002f7c:	6fc8                	ld	a0,152(a5)
    80002f7e:	bfe9                	j	80002f58 <argraw+0x30>
  panic("argraw");
    80002f80:	00005517          	auipc	a0,0x5
    80002f84:	51050513          	addi	a0,a0,1296 # 80008490 <states.1777+0x148>
    80002f88:	ffffd097          	auipc	ra,0xffffd
    80002f8c:	5b6080e7          	jalr	1462(ra) # 8000053e <panic>

0000000080002f90 <fetchaddr>:
{
    80002f90:	1101                	addi	sp,sp,-32
    80002f92:	ec06                	sd	ra,24(sp)
    80002f94:	e822                	sd	s0,16(sp)
    80002f96:	e426                	sd	s1,8(sp)
    80002f98:	e04a                	sd	s2,0(sp)
    80002f9a:	1000                	addi	s0,sp,32
    80002f9c:	84aa                	mv	s1,a0
    80002f9e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002fa0:	fffff097          	auipc	ra,0xfffff
    80002fa4:	d2c080e7          	jalr	-724(ra) # 80001ccc <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002fa8:	653c                	ld	a5,72(a0)
    80002faa:	02f4f863          	bgeu	s1,a5,80002fda <fetchaddr+0x4a>
    80002fae:	00848713          	addi	a4,s1,8
    80002fb2:	02e7e663          	bltu	a5,a4,80002fde <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002fb6:	46a1                	li	a3,8
    80002fb8:	8626                	mv	a2,s1
    80002fba:	85ca                	mv	a1,s2
    80002fbc:	6928                	ld	a0,80(a0)
    80002fbe:	ffffe097          	auipc	ra,0xffffe
    80002fc2:	740080e7          	jalr	1856(ra) # 800016fe <copyin>
    80002fc6:	00a03533          	snez	a0,a0
    80002fca:	40a00533          	neg	a0,a0
}
    80002fce:	60e2                	ld	ra,24(sp)
    80002fd0:	6442                	ld	s0,16(sp)
    80002fd2:	64a2                	ld	s1,8(sp)
    80002fd4:	6902                	ld	s2,0(sp)
    80002fd6:	6105                	addi	sp,sp,32
    80002fd8:	8082                	ret
    return -1;
    80002fda:	557d                	li	a0,-1
    80002fdc:	bfcd                	j	80002fce <fetchaddr+0x3e>
    80002fde:	557d                	li	a0,-1
    80002fe0:	b7fd                	j	80002fce <fetchaddr+0x3e>

0000000080002fe2 <fetchstr>:
{
    80002fe2:	7179                	addi	sp,sp,-48
    80002fe4:	f406                	sd	ra,40(sp)
    80002fe6:	f022                	sd	s0,32(sp)
    80002fe8:	ec26                	sd	s1,24(sp)
    80002fea:	e84a                	sd	s2,16(sp)
    80002fec:	e44e                	sd	s3,8(sp)
    80002fee:	1800                	addi	s0,sp,48
    80002ff0:	892a                	mv	s2,a0
    80002ff2:	84ae                	mv	s1,a1
    80002ff4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ff6:	fffff097          	auipc	ra,0xfffff
    80002ffa:	cd6080e7          	jalr	-810(ra) # 80001ccc <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ffe:	86ce                	mv	a3,s3
    80003000:	864a                	mv	a2,s2
    80003002:	85a6                	mv	a1,s1
    80003004:	6928                	ld	a0,80(a0)
    80003006:	ffffe097          	auipc	ra,0xffffe
    8000300a:	784080e7          	jalr	1924(ra) # 8000178a <copyinstr>
  if(err < 0)
    8000300e:	00054763          	bltz	a0,8000301c <fetchstr+0x3a>
  return strlen(buf);
    80003012:	8526                	mv	a0,s1
    80003014:	ffffe097          	auipc	ra,0xffffe
    80003018:	e50080e7          	jalr	-432(ra) # 80000e64 <strlen>
}
    8000301c:	70a2                	ld	ra,40(sp)
    8000301e:	7402                	ld	s0,32(sp)
    80003020:	64e2                	ld	s1,24(sp)
    80003022:	6942                	ld	s2,16(sp)
    80003024:	69a2                	ld	s3,8(sp)
    80003026:	6145                	addi	sp,sp,48
    80003028:	8082                	ret

000000008000302a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000302a:	1101                	addi	sp,sp,-32
    8000302c:	ec06                	sd	ra,24(sp)
    8000302e:	e822                	sd	s0,16(sp)
    80003030:	e426                	sd	s1,8(sp)
    80003032:	1000                	addi	s0,sp,32
    80003034:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003036:	00000097          	auipc	ra,0x0
    8000303a:	ef2080e7          	jalr	-270(ra) # 80002f28 <argraw>
    8000303e:	c088                	sw	a0,0(s1)
  return 0;
}
    80003040:	4501                	li	a0,0
    80003042:	60e2                	ld	ra,24(sp)
    80003044:	6442                	ld	s0,16(sp)
    80003046:	64a2                	ld	s1,8(sp)
    80003048:	6105                	addi	sp,sp,32
    8000304a:	8082                	ret

000000008000304c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000304c:	1101                	addi	sp,sp,-32
    8000304e:	ec06                	sd	ra,24(sp)
    80003050:	e822                	sd	s0,16(sp)
    80003052:	e426                	sd	s1,8(sp)
    80003054:	1000                	addi	s0,sp,32
    80003056:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003058:	00000097          	auipc	ra,0x0
    8000305c:	ed0080e7          	jalr	-304(ra) # 80002f28 <argraw>
    80003060:	e088                	sd	a0,0(s1)
  return 0;
}
    80003062:	4501                	li	a0,0
    80003064:	60e2                	ld	ra,24(sp)
    80003066:	6442                	ld	s0,16(sp)
    80003068:	64a2                	ld	s1,8(sp)
    8000306a:	6105                	addi	sp,sp,32
    8000306c:	8082                	ret

000000008000306e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000306e:	1101                	addi	sp,sp,-32
    80003070:	ec06                	sd	ra,24(sp)
    80003072:	e822                	sd	s0,16(sp)
    80003074:	e426                	sd	s1,8(sp)
    80003076:	e04a                	sd	s2,0(sp)
    80003078:	1000                	addi	s0,sp,32
    8000307a:	84ae                	mv	s1,a1
    8000307c:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000307e:	00000097          	auipc	ra,0x0
    80003082:	eaa080e7          	jalr	-342(ra) # 80002f28 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003086:	864a                	mv	a2,s2
    80003088:	85a6                	mv	a1,s1
    8000308a:	00000097          	auipc	ra,0x0
    8000308e:	f58080e7          	jalr	-168(ra) # 80002fe2 <fetchstr>
}
    80003092:	60e2                	ld	ra,24(sp)
    80003094:	6442                	ld	s0,16(sp)
    80003096:	64a2                	ld	s1,8(sp)
    80003098:	6902                	ld	s2,0(sp)
    8000309a:	6105                	addi	sp,sp,32
    8000309c:	8082                	ret

000000008000309e <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    8000309e:	1101                	addi	sp,sp,-32
    800030a0:	ec06                	sd	ra,24(sp)
    800030a2:	e822                	sd	s0,16(sp)
    800030a4:	e426                	sd	s1,8(sp)
    800030a6:	e04a                	sd	s2,0(sp)
    800030a8:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800030aa:	fffff097          	auipc	ra,0xfffff
    800030ae:	c22080e7          	jalr	-990(ra) # 80001ccc <myproc>
    800030b2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800030b4:	05853903          	ld	s2,88(a0)
    800030b8:	0a893783          	ld	a5,168(s2)
    800030bc:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800030c0:	37fd                	addiw	a5,a5,-1
    800030c2:	4751                	li	a4,20
    800030c4:	00f76f63          	bltu	a4,a5,800030e2 <syscall+0x44>
    800030c8:	00369713          	slli	a4,a3,0x3
    800030cc:	00005797          	auipc	a5,0x5
    800030d0:	40478793          	addi	a5,a5,1028 # 800084d0 <syscalls>
    800030d4:	97ba                	add	a5,a5,a4
    800030d6:	639c                	ld	a5,0(a5)
    800030d8:	c789                	beqz	a5,800030e2 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800030da:	9782                	jalr	a5
    800030dc:	06a93823          	sd	a0,112(s2)
    800030e0:	a839                	j	800030fe <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800030e2:	15848613          	addi	a2,s1,344
    800030e6:	588c                	lw	a1,48(s1)
    800030e8:	00005517          	auipc	a0,0x5
    800030ec:	3b050513          	addi	a0,a0,944 # 80008498 <states.1777+0x150>
    800030f0:	ffffd097          	auipc	ra,0xffffd
    800030f4:	498080e7          	jalr	1176(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800030f8:	6cbc                	ld	a5,88(s1)
    800030fa:	577d                	li	a4,-1
    800030fc:	fbb8                	sd	a4,112(a5)
  }
}
    800030fe:	60e2                	ld	ra,24(sp)
    80003100:	6442                	ld	s0,16(sp)
    80003102:	64a2                	ld	s1,8(sp)
    80003104:	6902                	ld	s2,0(sp)
    80003106:	6105                	addi	sp,sp,32
    80003108:	8082                	ret

000000008000310a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000310a:	1101                	addi	sp,sp,-32
    8000310c:	ec06                	sd	ra,24(sp)
    8000310e:	e822                	sd	s0,16(sp)
    80003110:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003112:	fec40593          	addi	a1,s0,-20
    80003116:	4501                	li	a0,0
    80003118:	00000097          	auipc	ra,0x0
    8000311c:	f12080e7          	jalr	-238(ra) # 8000302a <argint>
    return -1;
    80003120:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003122:	00054963          	bltz	a0,80003134 <sys_exit+0x2a>
  exit(n);
    80003126:	fec42503          	lw	a0,-20(s0)
    8000312a:	fffff097          	auipc	ra,0xfffff
    8000312e:	6a6080e7          	jalr	1702(ra) # 800027d0 <exit>
  return 0;  // not reached
    80003132:	4781                	li	a5,0
}
    80003134:	853e                	mv	a0,a5
    80003136:	60e2                	ld	ra,24(sp)
    80003138:	6442                	ld	s0,16(sp)
    8000313a:	6105                	addi	sp,sp,32
    8000313c:	8082                	ret

000000008000313e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000313e:	1141                	addi	sp,sp,-16
    80003140:	e406                	sd	ra,8(sp)
    80003142:	e022                	sd	s0,0(sp)
    80003144:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003146:	fffff097          	auipc	ra,0xfffff
    8000314a:	b86080e7          	jalr	-1146(ra) # 80001ccc <myproc>
}
    8000314e:	5908                	lw	a0,48(a0)
    80003150:	60a2                	ld	ra,8(sp)
    80003152:	6402                	ld	s0,0(sp)
    80003154:	0141                	addi	sp,sp,16
    80003156:	8082                	ret

0000000080003158 <sys_fork>:

uint64
sys_fork(void)
{
    80003158:	1141                	addi	sp,sp,-16
    8000315a:	e406                	sd	ra,8(sp)
    8000315c:	e022                	sd	s0,0(sp)
    8000315e:	0800                	addi	s0,sp,16
  return fork();
    80003160:	fffff097          	auipc	ra,0xfffff
    80003164:	ffa080e7          	jalr	-6(ra) # 8000215a <fork>
}
    80003168:	60a2                	ld	ra,8(sp)
    8000316a:	6402                	ld	s0,0(sp)
    8000316c:	0141                	addi	sp,sp,16
    8000316e:	8082                	ret

0000000080003170 <sys_wait>:

uint64
sys_wait(void)
{
    80003170:	1101                	addi	sp,sp,-32
    80003172:	ec06                	sd	ra,24(sp)
    80003174:	e822                	sd	s0,16(sp)
    80003176:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003178:	fe840593          	addi	a1,s0,-24
    8000317c:	4501                	li	a0,0
    8000317e:	00000097          	auipc	ra,0x0
    80003182:	ece080e7          	jalr	-306(ra) # 8000304c <argaddr>
    80003186:	87aa                	mv	a5,a0
    return -1;
    80003188:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000318a:	0007c863          	bltz	a5,8000319a <sys_wait+0x2a>
  return wait(p);
    8000318e:	fe843503          	ld	a0,-24(s0)
    80003192:	fffff097          	auipc	ra,0xfffff
    80003196:	3c0080e7          	jalr	960(ra) # 80002552 <wait>
}
    8000319a:	60e2                	ld	ra,24(sp)
    8000319c:	6442                	ld	s0,16(sp)
    8000319e:	6105                	addi	sp,sp,32
    800031a0:	8082                	ret

00000000800031a2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800031a2:	7179                	addi	sp,sp,-48
    800031a4:	f406                	sd	ra,40(sp)
    800031a6:	f022                	sd	s0,32(sp)
    800031a8:	ec26                	sd	s1,24(sp)
    800031aa:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800031ac:	fdc40593          	addi	a1,s0,-36
    800031b0:	4501                	li	a0,0
    800031b2:	00000097          	auipc	ra,0x0
    800031b6:	e78080e7          	jalr	-392(ra) # 8000302a <argint>
    800031ba:	87aa                	mv	a5,a0
    return -1;
    800031bc:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800031be:	0207c063          	bltz	a5,800031de <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800031c2:	fffff097          	auipc	ra,0xfffff
    800031c6:	b0a080e7          	jalr	-1270(ra) # 80001ccc <myproc>
    800031ca:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800031cc:	fdc42503          	lw	a0,-36(s0)
    800031d0:	fffff097          	auipc	ra,0xfffff
    800031d4:	f16080e7          	jalr	-234(ra) # 800020e6 <growproc>
    800031d8:	00054863          	bltz	a0,800031e8 <sys_sbrk+0x46>
    return -1;
  return addr;
    800031dc:	8526                	mv	a0,s1
}
    800031de:	70a2                	ld	ra,40(sp)
    800031e0:	7402                	ld	s0,32(sp)
    800031e2:	64e2                	ld	s1,24(sp)
    800031e4:	6145                	addi	sp,sp,48
    800031e6:	8082                	ret
    return -1;
    800031e8:	557d                	li	a0,-1
    800031ea:	bfd5                	j	800031de <sys_sbrk+0x3c>

00000000800031ec <sys_sleep>:

uint64
sys_sleep(void)
{
    800031ec:	7139                	addi	sp,sp,-64
    800031ee:	fc06                	sd	ra,56(sp)
    800031f0:	f822                	sd	s0,48(sp)
    800031f2:	f426                	sd	s1,40(sp)
    800031f4:	f04a                	sd	s2,32(sp)
    800031f6:	ec4e                	sd	s3,24(sp)
    800031f8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800031fa:	fcc40593          	addi	a1,s0,-52
    800031fe:	4501                	li	a0,0
    80003200:	00000097          	auipc	ra,0x0
    80003204:	e2a080e7          	jalr	-470(ra) # 8000302a <argint>
    return -1;
    80003208:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000320a:	06054563          	bltz	a0,80003274 <sys_sleep+0x88>
  acquire(&tickslock);
    8000320e:	00015517          	auipc	a0,0x15
    80003212:	a0250513          	addi	a0,a0,-1534 # 80017c10 <tickslock>
    80003216:	ffffe097          	auipc	ra,0xffffe
    8000321a:	9ce080e7          	jalr	-1586(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000321e:	00006917          	auipc	s2,0x6
    80003222:	e1292903          	lw	s2,-494(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003226:	fcc42783          	lw	a5,-52(s0)
    8000322a:	cf85                	beqz	a5,80003262 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000322c:	00015997          	auipc	s3,0x15
    80003230:	9e498993          	addi	s3,s3,-1564 # 80017c10 <tickslock>
    80003234:	00006497          	auipc	s1,0x6
    80003238:	dfc48493          	addi	s1,s1,-516 # 80009030 <ticks>
    if(myproc()->killed){
    8000323c:	fffff097          	auipc	ra,0xfffff
    80003240:	a90080e7          	jalr	-1392(ra) # 80001ccc <myproc>
    80003244:	551c                	lw	a5,40(a0)
    80003246:	ef9d                	bnez	a5,80003284 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003248:	85ce                	mv	a1,s3
    8000324a:	8526                	mv	a0,s1
    8000324c:	fffff097          	auipc	ra,0xfffff
    80003250:	290080e7          	jalr	656(ra) # 800024dc <sleep>
  while(ticks - ticks0 < n){
    80003254:	409c                	lw	a5,0(s1)
    80003256:	412787bb          	subw	a5,a5,s2
    8000325a:	fcc42703          	lw	a4,-52(s0)
    8000325e:	fce7efe3          	bltu	a5,a4,8000323c <sys_sleep+0x50>
  }
  release(&tickslock);
    80003262:	00015517          	auipc	a0,0x15
    80003266:	9ae50513          	addi	a0,a0,-1618 # 80017c10 <tickslock>
    8000326a:	ffffe097          	auipc	ra,0xffffe
    8000326e:	a2e080e7          	jalr	-1490(ra) # 80000c98 <release>
  return 0;
    80003272:	4781                	li	a5,0
}
    80003274:	853e                	mv	a0,a5
    80003276:	70e2                	ld	ra,56(sp)
    80003278:	7442                	ld	s0,48(sp)
    8000327a:	74a2                	ld	s1,40(sp)
    8000327c:	7902                	ld	s2,32(sp)
    8000327e:	69e2                	ld	s3,24(sp)
    80003280:	6121                	addi	sp,sp,64
    80003282:	8082                	ret
      release(&tickslock);
    80003284:	00015517          	auipc	a0,0x15
    80003288:	98c50513          	addi	a0,a0,-1652 # 80017c10 <tickslock>
    8000328c:	ffffe097          	auipc	ra,0xffffe
    80003290:	a0c080e7          	jalr	-1524(ra) # 80000c98 <release>
      return -1;
    80003294:	57fd                	li	a5,-1
    80003296:	bff9                	j	80003274 <sys_sleep+0x88>

0000000080003298 <sys_kill>:

uint64
sys_kill(void)
{
    80003298:	1101                	addi	sp,sp,-32
    8000329a:	ec06                	sd	ra,24(sp)
    8000329c:	e822                	sd	s0,16(sp)
    8000329e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800032a0:	fec40593          	addi	a1,s0,-20
    800032a4:	4501                	li	a0,0
    800032a6:	00000097          	auipc	ra,0x0
    800032aa:	d84080e7          	jalr	-636(ra) # 8000302a <argint>
    800032ae:	87aa                	mv	a5,a0
    return -1;
    800032b0:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800032b2:	0007c863          	bltz	a5,800032c2 <sys_kill+0x2a>
  return kill(pid);
    800032b6:	fec42503          	lw	a0,-20(s0)
    800032ba:	fffff097          	auipc	ra,0xfffff
    800032be:	5fe080e7          	jalr	1534(ra) # 800028b8 <kill>
}
    800032c2:	60e2                	ld	ra,24(sp)
    800032c4:	6442                	ld	s0,16(sp)
    800032c6:	6105                	addi	sp,sp,32
    800032c8:	8082                	ret

00000000800032ca <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800032ca:	1101                	addi	sp,sp,-32
    800032cc:	ec06                	sd	ra,24(sp)
    800032ce:	e822                	sd	s0,16(sp)
    800032d0:	e426                	sd	s1,8(sp)
    800032d2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800032d4:	00015517          	auipc	a0,0x15
    800032d8:	93c50513          	addi	a0,a0,-1732 # 80017c10 <tickslock>
    800032dc:	ffffe097          	auipc	ra,0xffffe
    800032e0:	908080e7          	jalr	-1784(ra) # 80000be4 <acquire>
  xticks = ticks;
    800032e4:	00006497          	auipc	s1,0x6
    800032e8:	d4c4a483          	lw	s1,-692(s1) # 80009030 <ticks>
  release(&tickslock);
    800032ec:	00015517          	auipc	a0,0x15
    800032f0:	92450513          	addi	a0,a0,-1756 # 80017c10 <tickslock>
    800032f4:	ffffe097          	auipc	ra,0xffffe
    800032f8:	9a4080e7          	jalr	-1628(ra) # 80000c98 <release>
  return xticks;
}
    800032fc:	02049513          	slli	a0,s1,0x20
    80003300:	9101                	srli	a0,a0,0x20
    80003302:	60e2                	ld	ra,24(sp)
    80003304:	6442                	ld	s0,16(sp)
    80003306:	64a2                	ld	s1,8(sp)
    80003308:	6105                	addi	sp,sp,32
    8000330a:	8082                	ret

000000008000330c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000330c:	7179                	addi	sp,sp,-48
    8000330e:	f406                	sd	ra,40(sp)
    80003310:	f022                	sd	s0,32(sp)
    80003312:	ec26                	sd	s1,24(sp)
    80003314:	e84a                	sd	s2,16(sp)
    80003316:	e44e                	sd	s3,8(sp)
    80003318:	e052                	sd	s4,0(sp)
    8000331a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000331c:	00005597          	auipc	a1,0x5
    80003320:	26458593          	addi	a1,a1,612 # 80008580 <syscalls+0xb0>
    80003324:	00015517          	auipc	a0,0x15
    80003328:	90450513          	addi	a0,a0,-1788 # 80017c28 <bcache>
    8000332c:	ffffe097          	auipc	ra,0xffffe
    80003330:	828080e7          	jalr	-2008(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003334:	0001d797          	auipc	a5,0x1d
    80003338:	8f478793          	addi	a5,a5,-1804 # 8001fc28 <bcache+0x8000>
    8000333c:	0001d717          	auipc	a4,0x1d
    80003340:	b5470713          	addi	a4,a4,-1196 # 8001fe90 <bcache+0x8268>
    80003344:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003348:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000334c:	00015497          	auipc	s1,0x15
    80003350:	8f448493          	addi	s1,s1,-1804 # 80017c40 <bcache+0x18>
    b->next = bcache.head.next;
    80003354:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003356:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003358:	00005a17          	auipc	s4,0x5
    8000335c:	230a0a13          	addi	s4,s4,560 # 80008588 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003360:	2b893783          	ld	a5,696(s2)
    80003364:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003366:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000336a:	85d2                	mv	a1,s4
    8000336c:	01048513          	addi	a0,s1,16
    80003370:	00001097          	auipc	ra,0x1
    80003374:	4bc080e7          	jalr	1212(ra) # 8000482c <initsleeplock>
    bcache.head.next->prev = b;
    80003378:	2b893783          	ld	a5,696(s2)
    8000337c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000337e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003382:	45848493          	addi	s1,s1,1112
    80003386:	fd349de3          	bne	s1,s3,80003360 <binit+0x54>
  }
}
    8000338a:	70a2                	ld	ra,40(sp)
    8000338c:	7402                	ld	s0,32(sp)
    8000338e:	64e2                	ld	s1,24(sp)
    80003390:	6942                	ld	s2,16(sp)
    80003392:	69a2                	ld	s3,8(sp)
    80003394:	6a02                	ld	s4,0(sp)
    80003396:	6145                	addi	sp,sp,48
    80003398:	8082                	ret

000000008000339a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000339a:	7179                	addi	sp,sp,-48
    8000339c:	f406                	sd	ra,40(sp)
    8000339e:	f022                	sd	s0,32(sp)
    800033a0:	ec26                	sd	s1,24(sp)
    800033a2:	e84a                	sd	s2,16(sp)
    800033a4:	e44e                	sd	s3,8(sp)
    800033a6:	1800                	addi	s0,sp,48
    800033a8:	89aa                	mv	s3,a0
    800033aa:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800033ac:	00015517          	auipc	a0,0x15
    800033b0:	87c50513          	addi	a0,a0,-1924 # 80017c28 <bcache>
    800033b4:	ffffe097          	auipc	ra,0xffffe
    800033b8:	830080e7          	jalr	-2000(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800033bc:	0001d497          	auipc	s1,0x1d
    800033c0:	b244b483          	ld	s1,-1244(s1) # 8001fee0 <bcache+0x82b8>
    800033c4:	0001d797          	auipc	a5,0x1d
    800033c8:	acc78793          	addi	a5,a5,-1332 # 8001fe90 <bcache+0x8268>
    800033cc:	02f48f63          	beq	s1,a5,8000340a <bread+0x70>
    800033d0:	873e                	mv	a4,a5
    800033d2:	a021                	j	800033da <bread+0x40>
    800033d4:	68a4                	ld	s1,80(s1)
    800033d6:	02e48a63          	beq	s1,a4,8000340a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800033da:	449c                	lw	a5,8(s1)
    800033dc:	ff379ce3          	bne	a5,s3,800033d4 <bread+0x3a>
    800033e0:	44dc                	lw	a5,12(s1)
    800033e2:	ff2799e3          	bne	a5,s2,800033d4 <bread+0x3a>
      b->refcnt++;
    800033e6:	40bc                	lw	a5,64(s1)
    800033e8:	2785                	addiw	a5,a5,1
    800033ea:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033ec:	00015517          	auipc	a0,0x15
    800033f0:	83c50513          	addi	a0,a0,-1988 # 80017c28 <bcache>
    800033f4:	ffffe097          	auipc	ra,0xffffe
    800033f8:	8a4080e7          	jalr	-1884(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800033fc:	01048513          	addi	a0,s1,16
    80003400:	00001097          	auipc	ra,0x1
    80003404:	466080e7          	jalr	1126(ra) # 80004866 <acquiresleep>
      return b;
    80003408:	a8b9                	j	80003466 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000340a:	0001d497          	auipc	s1,0x1d
    8000340e:	ace4b483          	ld	s1,-1330(s1) # 8001fed8 <bcache+0x82b0>
    80003412:	0001d797          	auipc	a5,0x1d
    80003416:	a7e78793          	addi	a5,a5,-1410 # 8001fe90 <bcache+0x8268>
    8000341a:	00f48863          	beq	s1,a5,8000342a <bread+0x90>
    8000341e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003420:	40bc                	lw	a5,64(s1)
    80003422:	cf81                	beqz	a5,8000343a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003424:	64a4                	ld	s1,72(s1)
    80003426:	fee49de3          	bne	s1,a4,80003420 <bread+0x86>
  panic("bget: no buffers");
    8000342a:	00005517          	auipc	a0,0x5
    8000342e:	16650513          	addi	a0,a0,358 # 80008590 <syscalls+0xc0>
    80003432:	ffffd097          	auipc	ra,0xffffd
    80003436:	10c080e7          	jalr	268(ra) # 8000053e <panic>
      b->dev = dev;
    8000343a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000343e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003442:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003446:	4785                	li	a5,1
    80003448:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000344a:	00014517          	auipc	a0,0x14
    8000344e:	7de50513          	addi	a0,a0,2014 # 80017c28 <bcache>
    80003452:	ffffe097          	auipc	ra,0xffffe
    80003456:	846080e7          	jalr	-1978(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000345a:	01048513          	addi	a0,s1,16
    8000345e:	00001097          	auipc	ra,0x1
    80003462:	408080e7          	jalr	1032(ra) # 80004866 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003466:	409c                	lw	a5,0(s1)
    80003468:	cb89                	beqz	a5,8000347a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000346a:	8526                	mv	a0,s1
    8000346c:	70a2                	ld	ra,40(sp)
    8000346e:	7402                	ld	s0,32(sp)
    80003470:	64e2                	ld	s1,24(sp)
    80003472:	6942                	ld	s2,16(sp)
    80003474:	69a2                	ld	s3,8(sp)
    80003476:	6145                	addi	sp,sp,48
    80003478:	8082                	ret
    virtio_disk_rw(b, 0);
    8000347a:	4581                	li	a1,0
    8000347c:	8526                	mv	a0,s1
    8000347e:	00003097          	auipc	ra,0x3
    80003482:	f08080e7          	jalr	-248(ra) # 80006386 <virtio_disk_rw>
    b->valid = 1;
    80003486:	4785                	li	a5,1
    80003488:	c09c                	sw	a5,0(s1)
  return b;
    8000348a:	b7c5                	j	8000346a <bread+0xd0>

000000008000348c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000348c:	1101                	addi	sp,sp,-32
    8000348e:	ec06                	sd	ra,24(sp)
    80003490:	e822                	sd	s0,16(sp)
    80003492:	e426                	sd	s1,8(sp)
    80003494:	1000                	addi	s0,sp,32
    80003496:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003498:	0541                	addi	a0,a0,16
    8000349a:	00001097          	auipc	ra,0x1
    8000349e:	466080e7          	jalr	1126(ra) # 80004900 <holdingsleep>
    800034a2:	cd01                	beqz	a0,800034ba <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800034a4:	4585                	li	a1,1
    800034a6:	8526                	mv	a0,s1
    800034a8:	00003097          	auipc	ra,0x3
    800034ac:	ede080e7          	jalr	-290(ra) # 80006386 <virtio_disk_rw>
}
    800034b0:	60e2                	ld	ra,24(sp)
    800034b2:	6442                	ld	s0,16(sp)
    800034b4:	64a2                	ld	s1,8(sp)
    800034b6:	6105                	addi	sp,sp,32
    800034b8:	8082                	ret
    panic("bwrite");
    800034ba:	00005517          	auipc	a0,0x5
    800034be:	0ee50513          	addi	a0,a0,238 # 800085a8 <syscalls+0xd8>
    800034c2:	ffffd097          	auipc	ra,0xffffd
    800034c6:	07c080e7          	jalr	124(ra) # 8000053e <panic>

00000000800034ca <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034ca:	1101                	addi	sp,sp,-32
    800034cc:	ec06                	sd	ra,24(sp)
    800034ce:	e822                	sd	s0,16(sp)
    800034d0:	e426                	sd	s1,8(sp)
    800034d2:	e04a                	sd	s2,0(sp)
    800034d4:	1000                	addi	s0,sp,32
    800034d6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034d8:	01050913          	addi	s2,a0,16
    800034dc:	854a                	mv	a0,s2
    800034de:	00001097          	auipc	ra,0x1
    800034e2:	422080e7          	jalr	1058(ra) # 80004900 <holdingsleep>
    800034e6:	c92d                	beqz	a0,80003558 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800034e8:	854a                	mv	a0,s2
    800034ea:	00001097          	auipc	ra,0x1
    800034ee:	3d2080e7          	jalr	978(ra) # 800048bc <releasesleep>

  acquire(&bcache.lock);
    800034f2:	00014517          	auipc	a0,0x14
    800034f6:	73650513          	addi	a0,a0,1846 # 80017c28 <bcache>
    800034fa:	ffffd097          	auipc	ra,0xffffd
    800034fe:	6ea080e7          	jalr	1770(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003502:	40bc                	lw	a5,64(s1)
    80003504:	37fd                	addiw	a5,a5,-1
    80003506:	0007871b          	sext.w	a4,a5
    8000350a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000350c:	eb05                	bnez	a4,8000353c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000350e:	68bc                	ld	a5,80(s1)
    80003510:	64b8                	ld	a4,72(s1)
    80003512:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003514:	64bc                	ld	a5,72(s1)
    80003516:	68b8                	ld	a4,80(s1)
    80003518:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000351a:	0001c797          	auipc	a5,0x1c
    8000351e:	70e78793          	addi	a5,a5,1806 # 8001fc28 <bcache+0x8000>
    80003522:	2b87b703          	ld	a4,696(a5)
    80003526:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003528:	0001d717          	auipc	a4,0x1d
    8000352c:	96870713          	addi	a4,a4,-1688 # 8001fe90 <bcache+0x8268>
    80003530:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003532:	2b87b703          	ld	a4,696(a5)
    80003536:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003538:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000353c:	00014517          	auipc	a0,0x14
    80003540:	6ec50513          	addi	a0,a0,1772 # 80017c28 <bcache>
    80003544:	ffffd097          	auipc	ra,0xffffd
    80003548:	754080e7          	jalr	1876(ra) # 80000c98 <release>
}
    8000354c:	60e2                	ld	ra,24(sp)
    8000354e:	6442                	ld	s0,16(sp)
    80003550:	64a2                	ld	s1,8(sp)
    80003552:	6902                	ld	s2,0(sp)
    80003554:	6105                	addi	sp,sp,32
    80003556:	8082                	ret
    panic("brelse");
    80003558:	00005517          	auipc	a0,0x5
    8000355c:	05850513          	addi	a0,a0,88 # 800085b0 <syscalls+0xe0>
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	fde080e7          	jalr	-34(ra) # 8000053e <panic>

0000000080003568 <bpin>:

void
bpin(struct buf *b) {
    80003568:	1101                	addi	sp,sp,-32
    8000356a:	ec06                	sd	ra,24(sp)
    8000356c:	e822                	sd	s0,16(sp)
    8000356e:	e426                	sd	s1,8(sp)
    80003570:	1000                	addi	s0,sp,32
    80003572:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003574:	00014517          	auipc	a0,0x14
    80003578:	6b450513          	addi	a0,a0,1716 # 80017c28 <bcache>
    8000357c:	ffffd097          	auipc	ra,0xffffd
    80003580:	668080e7          	jalr	1640(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003584:	40bc                	lw	a5,64(s1)
    80003586:	2785                	addiw	a5,a5,1
    80003588:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000358a:	00014517          	auipc	a0,0x14
    8000358e:	69e50513          	addi	a0,a0,1694 # 80017c28 <bcache>
    80003592:	ffffd097          	auipc	ra,0xffffd
    80003596:	706080e7          	jalr	1798(ra) # 80000c98 <release>
}
    8000359a:	60e2                	ld	ra,24(sp)
    8000359c:	6442                	ld	s0,16(sp)
    8000359e:	64a2                	ld	s1,8(sp)
    800035a0:	6105                	addi	sp,sp,32
    800035a2:	8082                	ret

00000000800035a4 <bunpin>:

void
bunpin(struct buf *b) {
    800035a4:	1101                	addi	sp,sp,-32
    800035a6:	ec06                	sd	ra,24(sp)
    800035a8:	e822                	sd	s0,16(sp)
    800035aa:	e426                	sd	s1,8(sp)
    800035ac:	1000                	addi	s0,sp,32
    800035ae:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035b0:	00014517          	auipc	a0,0x14
    800035b4:	67850513          	addi	a0,a0,1656 # 80017c28 <bcache>
    800035b8:	ffffd097          	auipc	ra,0xffffd
    800035bc:	62c080e7          	jalr	1580(ra) # 80000be4 <acquire>
  b->refcnt--;
    800035c0:	40bc                	lw	a5,64(s1)
    800035c2:	37fd                	addiw	a5,a5,-1
    800035c4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035c6:	00014517          	auipc	a0,0x14
    800035ca:	66250513          	addi	a0,a0,1634 # 80017c28 <bcache>
    800035ce:	ffffd097          	auipc	ra,0xffffd
    800035d2:	6ca080e7          	jalr	1738(ra) # 80000c98 <release>
}
    800035d6:	60e2                	ld	ra,24(sp)
    800035d8:	6442                	ld	s0,16(sp)
    800035da:	64a2                	ld	s1,8(sp)
    800035dc:	6105                	addi	sp,sp,32
    800035de:	8082                	ret

00000000800035e0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035e0:	1101                	addi	sp,sp,-32
    800035e2:	ec06                	sd	ra,24(sp)
    800035e4:	e822                	sd	s0,16(sp)
    800035e6:	e426                	sd	s1,8(sp)
    800035e8:	e04a                	sd	s2,0(sp)
    800035ea:	1000                	addi	s0,sp,32
    800035ec:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035ee:	00d5d59b          	srliw	a1,a1,0xd
    800035f2:	0001d797          	auipc	a5,0x1d
    800035f6:	d127a783          	lw	a5,-750(a5) # 80020304 <sb+0x1c>
    800035fa:	9dbd                	addw	a1,a1,a5
    800035fc:	00000097          	auipc	ra,0x0
    80003600:	d9e080e7          	jalr	-610(ra) # 8000339a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003604:	0074f713          	andi	a4,s1,7
    80003608:	4785                	li	a5,1
    8000360a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000360e:	14ce                	slli	s1,s1,0x33
    80003610:	90d9                	srli	s1,s1,0x36
    80003612:	00950733          	add	a4,a0,s1
    80003616:	05874703          	lbu	a4,88(a4)
    8000361a:	00e7f6b3          	and	a3,a5,a4
    8000361e:	c69d                	beqz	a3,8000364c <bfree+0x6c>
    80003620:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003622:	94aa                	add	s1,s1,a0
    80003624:	fff7c793          	not	a5,a5
    80003628:	8ff9                	and	a5,a5,a4
    8000362a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000362e:	00001097          	auipc	ra,0x1
    80003632:	118080e7          	jalr	280(ra) # 80004746 <log_write>
  brelse(bp);
    80003636:	854a                	mv	a0,s2
    80003638:	00000097          	auipc	ra,0x0
    8000363c:	e92080e7          	jalr	-366(ra) # 800034ca <brelse>
}
    80003640:	60e2                	ld	ra,24(sp)
    80003642:	6442                	ld	s0,16(sp)
    80003644:	64a2                	ld	s1,8(sp)
    80003646:	6902                	ld	s2,0(sp)
    80003648:	6105                	addi	sp,sp,32
    8000364a:	8082                	ret
    panic("freeing free block");
    8000364c:	00005517          	auipc	a0,0x5
    80003650:	f6c50513          	addi	a0,a0,-148 # 800085b8 <syscalls+0xe8>
    80003654:	ffffd097          	auipc	ra,0xffffd
    80003658:	eea080e7          	jalr	-278(ra) # 8000053e <panic>

000000008000365c <balloc>:
{
    8000365c:	711d                	addi	sp,sp,-96
    8000365e:	ec86                	sd	ra,88(sp)
    80003660:	e8a2                	sd	s0,80(sp)
    80003662:	e4a6                	sd	s1,72(sp)
    80003664:	e0ca                	sd	s2,64(sp)
    80003666:	fc4e                	sd	s3,56(sp)
    80003668:	f852                	sd	s4,48(sp)
    8000366a:	f456                	sd	s5,40(sp)
    8000366c:	f05a                	sd	s6,32(sp)
    8000366e:	ec5e                	sd	s7,24(sp)
    80003670:	e862                	sd	s8,16(sp)
    80003672:	e466                	sd	s9,8(sp)
    80003674:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003676:	0001d797          	auipc	a5,0x1d
    8000367a:	c767a783          	lw	a5,-906(a5) # 800202ec <sb+0x4>
    8000367e:	cbd1                	beqz	a5,80003712 <balloc+0xb6>
    80003680:	8baa                	mv	s7,a0
    80003682:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003684:	0001db17          	auipc	s6,0x1d
    80003688:	c64b0b13          	addi	s6,s6,-924 # 800202e8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000368c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000368e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003690:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003692:	6c89                	lui	s9,0x2
    80003694:	a831                	j	800036b0 <balloc+0x54>
    brelse(bp);
    80003696:	854a                	mv	a0,s2
    80003698:	00000097          	auipc	ra,0x0
    8000369c:	e32080e7          	jalr	-462(ra) # 800034ca <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800036a0:	015c87bb          	addw	a5,s9,s5
    800036a4:	00078a9b          	sext.w	s5,a5
    800036a8:	004b2703          	lw	a4,4(s6)
    800036ac:	06eaf363          	bgeu	s5,a4,80003712 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800036b0:	41fad79b          	sraiw	a5,s5,0x1f
    800036b4:	0137d79b          	srliw	a5,a5,0x13
    800036b8:	015787bb          	addw	a5,a5,s5
    800036bc:	40d7d79b          	sraiw	a5,a5,0xd
    800036c0:	01cb2583          	lw	a1,28(s6)
    800036c4:	9dbd                	addw	a1,a1,a5
    800036c6:	855e                	mv	a0,s7
    800036c8:	00000097          	auipc	ra,0x0
    800036cc:	cd2080e7          	jalr	-814(ra) # 8000339a <bread>
    800036d0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036d2:	004b2503          	lw	a0,4(s6)
    800036d6:	000a849b          	sext.w	s1,s5
    800036da:	8662                	mv	a2,s8
    800036dc:	faa4fde3          	bgeu	s1,a0,80003696 <balloc+0x3a>
      m = 1 << (bi % 8);
    800036e0:	41f6579b          	sraiw	a5,a2,0x1f
    800036e4:	01d7d69b          	srliw	a3,a5,0x1d
    800036e8:	00c6873b          	addw	a4,a3,a2
    800036ec:	00777793          	andi	a5,a4,7
    800036f0:	9f95                	subw	a5,a5,a3
    800036f2:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036f6:	4037571b          	sraiw	a4,a4,0x3
    800036fa:	00e906b3          	add	a3,s2,a4
    800036fe:	0586c683          	lbu	a3,88(a3)
    80003702:	00d7f5b3          	and	a1,a5,a3
    80003706:	cd91                	beqz	a1,80003722 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003708:	2605                	addiw	a2,a2,1
    8000370a:	2485                	addiw	s1,s1,1
    8000370c:	fd4618e3          	bne	a2,s4,800036dc <balloc+0x80>
    80003710:	b759                	j	80003696 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003712:	00005517          	auipc	a0,0x5
    80003716:	ebe50513          	addi	a0,a0,-322 # 800085d0 <syscalls+0x100>
    8000371a:	ffffd097          	auipc	ra,0xffffd
    8000371e:	e24080e7          	jalr	-476(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003722:	974a                	add	a4,a4,s2
    80003724:	8fd5                	or	a5,a5,a3
    80003726:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000372a:	854a                	mv	a0,s2
    8000372c:	00001097          	auipc	ra,0x1
    80003730:	01a080e7          	jalr	26(ra) # 80004746 <log_write>
        brelse(bp);
    80003734:	854a                	mv	a0,s2
    80003736:	00000097          	auipc	ra,0x0
    8000373a:	d94080e7          	jalr	-620(ra) # 800034ca <brelse>
  bp = bread(dev, bno);
    8000373e:	85a6                	mv	a1,s1
    80003740:	855e                	mv	a0,s7
    80003742:	00000097          	auipc	ra,0x0
    80003746:	c58080e7          	jalr	-936(ra) # 8000339a <bread>
    8000374a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000374c:	40000613          	li	a2,1024
    80003750:	4581                	li	a1,0
    80003752:	05850513          	addi	a0,a0,88
    80003756:	ffffd097          	auipc	ra,0xffffd
    8000375a:	58a080e7          	jalr	1418(ra) # 80000ce0 <memset>
  log_write(bp);
    8000375e:	854a                	mv	a0,s2
    80003760:	00001097          	auipc	ra,0x1
    80003764:	fe6080e7          	jalr	-26(ra) # 80004746 <log_write>
  brelse(bp);
    80003768:	854a                	mv	a0,s2
    8000376a:	00000097          	auipc	ra,0x0
    8000376e:	d60080e7          	jalr	-672(ra) # 800034ca <brelse>
}
    80003772:	8526                	mv	a0,s1
    80003774:	60e6                	ld	ra,88(sp)
    80003776:	6446                	ld	s0,80(sp)
    80003778:	64a6                	ld	s1,72(sp)
    8000377a:	6906                	ld	s2,64(sp)
    8000377c:	79e2                	ld	s3,56(sp)
    8000377e:	7a42                	ld	s4,48(sp)
    80003780:	7aa2                	ld	s5,40(sp)
    80003782:	7b02                	ld	s6,32(sp)
    80003784:	6be2                	ld	s7,24(sp)
    80003786:	6c42                	ld	s8,16(sp)
    80003788:	6ca2                	ld	s9,8(sp)
    8000378a:	6125                	addi	sp,sp,96
    8000378c:	8082                	ret

000000008000378e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000378e:	7179                	addi	sp,sp,-48
    80003790:	f406                	sd	ra,40(sp)
    80003792:	f022                	sd	s0,32(sp)
    80003794:	ec26                	sd	s1,24(sp)
    80003796:	e84a                	sd	s2,16(sp)
    80003798:	e44e                	sd	s3,8(sp)
    8000379a:	e052                	sd	s4,0(sp)
    8000379c:	1800                	addi	s0,sp,48
    8000379e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800037a0:	47ad                	li	a5,11
    800037a2:	04b7fe63          	bgeu	a5,a1,800037fe <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800037a6:	ff45849b          	addiw	s1,a1,-12
    800037aa:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800037ae:	0ff00793          	li	a5,255
    800037b2:	0ae7e363          	bltu	a5,a4,80003858 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800037b6:	08052583          	lw	a1,128(a0)
    800037ba:	c5ad                	beqz	a1,80003824 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800037bc:	00092503          	lw	a0,0(s2)
    800037c0:	00000097          	auipc	ra,0x0
    800037c4:	bda080e7          	jalr	-1062(ra) # 8000339a <bread>
    800037c8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037ca:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800037ce:	02049593          	slli	a1,s1,0x20
    800037d2:	9181                	srli	a1,a1,0x20
    800037d4:	058a                	slli	a1,a1,0x2
    800037d6:	00b784b3          	add	s1,a5,a1
    800037da:	0004a983          	lw	s3,0(s1)
    800037de:	04098d63          	beqz	s3,80003838 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800037e2:	8552                	mv	a0,s4
    800037e4:	00000097          	auipc	ra,0x0
    800037e8:	ce6080e7          	jalr	-794(ra) # 800034ca <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037ec:	854e                	mv	a0,s3
    800037ee:	70a2                	ld	ra,40(sp)
    800037f0:	7402                	ld	s0,32(sp)
    800037f2:	64e2                	ld	s1,24(sp)
    800037f4:	6942                	ld	s2,16(sp)
    800037f6:	69a2                	ld	s3,8(sp)
    800037f8:	6a02                	ld	s4,0(sp)
    800037fa:	6145                	addi	sp,sp,48
    800037fc:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800037fe:	02059493          	slli	s1,a1,0x20
    80003802:	9081                	srli	s1,s1,0x20
    80003804:	048a                	slli	s1,s1,0x2
    80003806:	94aa                	add	s1,s1,a0
    80003808:	0504a983          	lw	s3,80(s1)
    8000380c:	fe0990e3          	bnez	s3,800037ec <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003810:	4108                	lw	a0,0(a0)
    80003812:	00000097          	auipc	ra,0x0
    80003816:	e4a080e7          	jalr	-438(ra) # 8000365c <balloc>
    8000381a:	0005099b          	sext.w	s3,a0
    8000381e:	0534a823          	sw	s3,80(s1)
    80003822:	b7e9                	j	800037ec <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003824:	4108                	lw	a0,0(a0)
    80003826:	00000097          	auipc	ra,0x0
    8000382a:	e36080e7          	jalr	-458(ra) # 8000365c <balloc>
    8000382e:	0005059b          	sext.w	a1,a0
    80003832:	08b92023          	sw	a1,128(s2)
    80003836:	b759                	j	800037bc <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003838:	00092503          	lw	a0,0(s2)
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	e20080e7          	jalr	-480(ra) # 8000365c <balloc>
    80003844:	0005099b          	sext.w	s3,a0
    80003848:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000384c:	8552                	mv	a0,s4
    8000384e:	00001097          	auipc	ra,0x1
    80003852:	ef8080e7          	jalr	-264(ra) # 80004746 <log_write>
    80003856:	b771                	j	800037e2 <bmap+0x54>
  panic("bmap: out of range");
    80003858:	00005517          	auipc	a0,0x5
    8000385c:	d9050513          	addi	a0,a0,-624 # 800085e8 <syscalls+0x118>
    80003860:	ffffd097          	auipc	ra,0xffffd
    80003864:	cde080e7          	jalr	-802(ra) # 8000053e <panic>

0000000080003868 <iget>:
{
    80003868:	7179                	addi	sp,sp,-48
    8000386a:	f406                	sd	ra,40(sp)
    8000386c:	f022                	sd	s0,32(sp)
    8000386e:	ec26                	sd	s1,24(sp)
    80003870:	e84a                	sd	s2,16(sp)
    80003872:	e44e                	sd	s3,8(sp)
    80003874:	e052                	sd	s4,0(sp)
    80003876:	1800                	addi	s0,sp,48
    80003878:	89aa                	mv	s3,a0
    8000387a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000387c:	0001d517          	auipc	a0,0x1d
    80003880:	a8c50513          	addi	a0,a0,-1396 # 80020308 <itable>
    80003884:	ffffd097          	auipc	ra,0xffffd
    80003888:	360080e7          	jalr	864(ra) # 80000be4 <acquire>
  empty = 0;
    8000388c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000388e:	0001d497          	auipc	s1,0x1d
    80003892:	a9248493          	addi	s1,s1,-1390 # 80020320 <itable+0x18>
    80003896:	0001e697          	auipc	a3,0x1e
    8000389a:	51a68693          	addi	a3,a3,1306 # 80021db0 <log>
    8000389e:	a039                	j	800038ac <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038a0:	02090b63          	beqz	s2,800038d6 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038a4:	08848493          	addi	s1,s1,136
    800038a8:	02d48a63          	beq	s1,a3,800038dc <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038ac:	449c                	lw	a5,8(s1)
    800038ae:	fef059e3          	blez	a5,800038a0 <iget+0x38>
    800038b2:	4098                	lw	a4,0(s1)
    800038b4:	ff3716e3          	bne	a4,s3,800038a0 <iget+0x38>
    800038b8:	40d8                	lw	a4,4(s1)
    800038ba:	ff4713e3          	bne	a4,s4,800038a0 <iget+0x38>
      ip->ref++;
    800038be:	2785                	addiw	a5,a5,1
    800038c0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800038c2:	0001d517          	auipc	a0,0x1d
    800038c6:	a4650513          	addi	a0,a0,-1466 # 80020308 <itable>
    800038ca:	ffffd097          	auipc	ra,0xffffd
    800038ce:	3ce080e7          	jalr	974(ra) # 80000c98 <release>
      return ip;
    800038d2:	8926                	mv	s2,s1
    800038d4:	a03d                	j	80003902 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038d6:	f7f9                	bnez	a5,800038a4 <iget+0x3c>
    800038d8:	8926                	mv	s2,s1
    800038da:	b7e9                	j	800038a4 <iget+0x3c>
  if(empty == 0)
    800038dc:	02090c63          	beqz	s2,80003914 <iget+0xac>
  ip->dev = dev;
    800038e0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038e4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038e8:	4785                	li	a5,1
    800038ea:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038ee:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800038f2:	0001d517          	auipc	a0,0x1d
    800038f6:	a1650513          	addi	a0,a0,-1514 # 80020308 <itable>
    800038fa:	ffffd097          	auipc	ra,0xffffd
    800038fe:	39e080e7          	jalr	926(ra) # 80000c98 <release>
}
    80003902:	854a                	mv	a0,s2
    80003904:	70a2                	ld	ra,40(sp)
    80003906:	7402                	ld	s0,32(sp)
    80003908:	64e2                	ld	s1,24(sp)
    8000390a:	6942                	ld	s2,16(sp)
    8000390c:	69a2                	ld	s3,8(sp)
    8000390e:	6a02                	ld	s4,0(sp)
    80003910:	6145                	addi	sp,sp,48
    80003912:	8082                	ret
    panic("iget: no inodes");
    80003914:	00005517          	auipc	a0,0x5
    80003918:	cec50513          	addi	a0,a0,-788 # 80008600 <syscalls+0x130>
    8000391c:	ffffd097          	auipc	ra,0xffffd
    80003920:	c22080e7          	jalr	-990(ra) # 8000053e <panic>

0000000080003924 <fsinit>:
fsinit(int dev) {
    80003924:	7179                	addi	sp,sp,-48
    80003926:	f406                	sd	ra,40(sp)
    80003928:	f022                	sd	s0,32(sp)
    8000392a:	ec26                	sd	s1,24(sp)
    8000392c:	e84a                	sd	s2,16(sp)
    8000392e:	e44e                	sd	s3,8(sp)
    80003930:	1800                	addi	s0,sp,48
    80003932:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003934:	4585                	li	a1,1
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	a64080e7          	jalr	-1436(ra) # 8000339a <bread>
    8000393e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003940:	0001d997          	auipc	s3,0x1d
    80003944:	9a898993          	addi	s3,s3,-1624 # 800202e8 <sb>
    80003948:	02000613          	li	a2,32
    8000394c:	05850593          	addi	a1,a0,88
    80003950:	854e                	mv	a0,s3
    80003952:	ffffd097          	auipc	ra,0xffffd
    80003956:	3ee080e7          	jalr	1006(ra) # 80000d40 <memmove>
  brelse(bp);
    8000395a:	8526                	mv	a0,s1
    8000395c:	00000097          	auipc	ra,0x0
    80003960:	b6e080e7          	jalr	-1170(ra) # 800034ca <brelse>
  if(sb.magic != FSMAGIC)
    80003964:	0009a703          	lw	a4,0(s3)
    80003968:	102037b7          	lui	a5,0x10203
    8000396c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003970:	02f71263          	bne	a4,a5,80003994 <fsinit+0x70>
  initlog(dev, &sb);
    80003974:	0001d597          	auipc	a1,0x1d
    80003978:	97458593          	addi	a1,a1,-1676 # 800202e8 <sb>
    8000397c:	854a                	mv	a0,s2
    8000397e:	00001097          	auipc	ra,0x1
    80003982:	b4c080e7          	jalr	-1204(ra) # 800044ca <initlog>
}
    80003986:	70a2                	ld	ra,40(sp)
    80003988:	7402                	ld	s0,32(sp)
    8000398a:	64e2                	ld	s1,24(sp)
    8000398c:	6942                	ld	s2,16(sp)
    8000398e:	69a2                	ld	s3,8(sp)
    80003990:	6145                	addi	sp,sp,48
    80003992:	8082                	ret
    panic("invalid file system");
    80003994:	00005517          	auipc	a0,0x5
    80003998:	c7c50513          	addi	a0,a0,-900 # 80008610 <syscalls+0x140>
    8000399c:	ffffd097          	auipc	ra,0xffffd
    800039a0:	ba2080e7          	jalr	-1118(ra) # 8000053e <panic>

00000000800039a4 <iinit>:
{
    800039a4:	7179                	addi	sp,sp,-48
    800039a6:	f406                	sd	ra,40(sp)
    800039a8:	f022                	sd	s0,32(sp)
    800039aa:	ec26                	sd	s1,24(sp)
    800039ac:	e84a                	sd	s2,16(sp)
    800039ae:	e44e                	sd	s3,8(sp)
    800039b0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800039b2:	00005597          	auipc	a1,0x5
    800039b6:	c7658593          	addi	a1,a1,-906 # 80008628 <syscalls+0x158>
    800039ba:	0001d517          	auipc	a0,0x1d
    800039be:	94e50513          	addi	a0,a0,-1714 # 80020308 <itable>
    800039c2:	ffffd097          	auipc	ra,0xffffd
    800039c6:	192080e7          	jalr	402(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800039ca:	0001d497          	auipc	s1,0x1d
    800039ce:	96648493          	addi	s1,s1,-1690 # 80020330 <itable+0x28>
    800039d2:	0001e997          	auipc	s3,0x1e
    800039d6:	3ee98993          	addi	s3,s3,1006 # 80021dc0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800039da:	00005917          	auipc	s2,0x5
    800039de:	c5690913          	addi	s2,s2,-938 # 80008630 <syscalls+0x160>
    800039e2:	85ca                	mv	a1,s2
    800039e4:	8526                	mv	a0,s1
    800039e6:	00001097          	auipc	ra,0x1
    800039ea:	e46080e7          	jalr	-442(ra) # 8000482c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039ee:	08848493          	addi	s1,s1,136
    800039f2:	ff3498e3          	bne	s1,s3,800039e2 <iinit+0x3e>
}
    800039f6:	70a2                	ld	ra,40(sp)
    800039f8:	7402                	ld	s0,32(sp)
    800039fa:	64e2                	ld	s1,24(sp)
    800039fc:	6942                	ld	s2,16(sp)
    800039fe:	69a2                	ld	s3,8(sp)
    80003a00:	6145                	addi	sp,sp,48
    80003a02:	8082                	ret

0000000080003a04 <ialloc>:
{
    80003a04:	715d                	addi	sp,sp,-80
    80003a06:	e486                	sd	ra,72(sp)
    80003a08:	e0a2                	sd	s0,64(sp)
    80003a0a:	fc26                	sd	s1,56(sp)
    80003a0c:	f84a                	sd	s2,48(sp)
    80003a0e:	f44e                	sd	s3,40(sp)
    80003a10:	f052                	sd	s4,32(sp)
    80003a12:	ec56                	sd	s5,24(sp)
    80003a14:	e85a                	sd	s6,16(sp)
    80003a16:	e45e                	sd	s7,8(sp)
    80003a18:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a1a:	0001d717          	auipc	a4,0x1d
    80003a1e:	8da72703          	lw	a4,-1830(a4) # 800202f4 <sb+0xc>
    80003a22:	4785                	li	a5,1
    80003a24:	04e7fa63          	bgeu	a5,a4,80003a78 <ialloc+0x74>
    80003a28:	8aaa                	mv	s5,a0
    80003a2a:	8bae                	mv	s7,a1
    80003a2c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a2e:	0001da17          	auipc	s4,0x1d
    80003a32:	8baa0a13          	addi	s4,s4,-1862 # 800202e8 <sb>
    80003a36:	00048b1b          	sext.w	s6,s1
    80003a3a:	0044d593          	srli	a1,s1,0x4
    80003a3e:	018a2783          	lw	a5,24(s4)
    80003a42:	9dbd                	addw	a1,a1,a5
    80003a44:	8556                	mv	a0,s5
    80003a46:	00000097          	auipc	ra,0x0
    80003a4a:	954080e7          	jalr	-1708(ra) # 8000339a <bread>
    80003a4e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a50:	05850993          	addi	s3,a0,88
    80003a54:	00f4f793          	andi	a5,s1,15
    80003a58:	079a                	slli	a5,a5,0x6
    80003a5a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a5c:	00099783          	lh	a5,0(s3)
    80003a60:	c785                	beqz	a5,80003a88 <ialloc+0x84>
    brelse(bp);
    80003a62:	00000097          	auipc	ra,0x0
    80003a66:	a68080e7          	jalr	-1432(ra) # 800034ca <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a6a:	0485                	addi	s1,s1,1
    80003a6c:	00ca2703          	lw	a4,12(s4)
    80003a70:	0004879b          	sext.w	a5,s1
    80003a74:	fce7e1e3          	bltu	a5,a4,80003a36 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003a78:	00005517          	auipc	a0,0x5
    80003a7c:	bc050513          	addi	a0,a0,-1088 # 80008638 <syscalls+0x168>
    80003a80:	ffffd097          	auipc	ra,0xffffd
    80003a84:	abe080e7          	jalr	-1346(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003a88:	04000613          	li	a2,64
    80003a8c:	4581                	li	a1,0
    80003a8e:	854e                	mv	a0,s3
    80003a90:	ffffd097          	auipc	ra,0xffffd
    80003a94:	250080e7          	jalr	592(ra) # 80000ce0 <memset>
      dip->type = type;
    80003a98:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a9c:	854a                	mv	a0,s2
    80003a9e:	00001097          	auipc	ra,0x1
    80003aa2:	ca8080e7          	jalr	-856(ra) # 80004746 <log_write>
      brelse(bp);
    80003aa6:	854a                	mv	a0,s2
    80003aa8:	00000097          	auipc	ra,0x0
    80003aac:	a22080e7          	jalr	-1502(ra) # 800034ca <brelse>
      return iget(dev, inum);
    80003ab0:	85da                	mv	a1,s6
    80003ab2:	8556                	mv	a0,s5
    80003ab4:	00000097          	auipc	ra,0x0
    80003ab8:	db4080e7          	jalr	-588(ra) # 80003868 <iget>
}
    80003abc:	60a6                	ld	ra,72(sp)
    80003abe:	6406                	ld	s0,64(sp)
    80003ac0:	74e2                	ld	s1,56(sp)
    80003ac2:	7942                	ld	s2,48(sp)
    80003ac4:	79a2                	ld	s3,40(sp)
    80003ac6:	7a02                	ld	s4,32(sp)
    80003ac8:	6ae2                	ld	s5,24(sp)
    80003aca:	6b42                	ld	s6,16(sp)
    80003acc:	6ba2                	ld	s7,8(sp)
    80003ace:	6161                	addi	sp,sp,80
    80003ad0:	8082                	ret

0000000080003ad2 <iupdate>:
{
    80003ad2:	1101                	addi	sp,sp,-32
    80003ad4:	ec06                	sd	ra,24(sp)
    80003ad6:	e822                	sd	s0,16(sp)
    80003ad8:	e426                	sd	s1,8(sp)
    80003ada:	e04a                	sd	s2,0(sp)
    80003adc:	1000                	addi	s0,sp,32
    80003ade:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ae0:	415c                	lw	a5,4(a0)
    80003ae2:	0047d79b          	srliw	a5,a5,0x4
    80003ae6:	0001d597          	auipc	a1,0x1d
    80003aea:	81a5a583          	lw	a1,-2022(a1) # 80020300 <sb+0x18>
    80003aee:	9dbd                	addw	a1,a1,a5
    80003af0:	4108                	lw	a0,0(a0)
    80003af2:	00000097          	auipc	ra,0x0
    80003af6:	8a8080e7          	jalr	-1880(ra) # 8000339a <bread>
    80003afa:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003afc:	05850793          	addi	a5,a0,88
    80003b00:	40c8                	lw	a0,4(s1)
    80003b02:	893d                	andi	a0,a0,15
    80003b04:	051a                	slli	a0,a0,0x6
    80003b06:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003b08:	04449703          	lh	a4,68(s1)
    80003b0c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b10:	04649703          	lh	a4,70(s1)
    80003b14:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003b18:	04849703          	lh	a4,72(s1)
    80003b1c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b20:	04a49703          	lh	a4,74(s1)
    80003b24:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b28:	44f8                	lw	a4,76(s1)
    80003b2a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b2c:	03400613          	li	a2,52
    80003b30:	05048593          	addi	a1,s1,80
    80003b34:	0531                	addi	a0,a0,12
    80003b36:	ffffd097          	auipc	ra,0xffffd
    80003b3a:	20a080e7          	jalr	522(ra) # 80000d40 <memmove>
  log_write(bp);
    80003b3e:	854a                	mv	a0,s2
    80003b40:	00001097          	auipc	ra,0x1
    80003b44:	c06080e7          	jalr	-1018(ra) # 80004746 <log_write>
  brelse(bp);
    80003b48:	854a                	mv	a0,s2
    80003b4a:	00000097          	auipc	ra,0x0
    80003b4e:	980080e7          	jalr	-1664(ra) # 800034ca <brelse>
}
    80003b52:	60e2                	ld	ra,24(sp)
    80003b54:	6442                	ld	s0,16(sp)
    80003b56:	64a2                	ld	s1,8(sp)
    80003b58:	6902                	ld	s2,0(sp)
    80003b5a:	6105                	addi	sp,sp,32
    80003b5c:	8082                	ret

0000000080003b5e <idup>:
{
    80003b5e:	1101                	addi	sp,sp,-32
    80003b60:	ec06                	sd	ra,24(sp)
    80003b62:	e822                	sd	s0,16(sp)
    80003b64:	e426                	sd	s1,8(sp)
    80003b66:	1000                	addi	s0,sp,32
    80003b68:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b6a:	0001c517          	auipc	a0,0x1c
    80003b6e:	79e50513          	addi	a0,a0,1950 # 80020308 <itable>
    80003b72:	ffffd097          	auipc	ra,0xffffd
    80003b76:	072080e7          	jalr	114(ra) # 80000be4 <acquire>
  ip->ref++;
    80003b7a:	449c                	lw	a5,8(s1)
    80003b7c:	2785                	addiw	a5,a5,1
    80003b7e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b80:	0001c517          	auipc	a0,0x1c
    80003b84:	78850513          	addi	a0,a0,1928 # 80020308 <itable>
    80003b88:	ffffd097          	auipc	ra,0xffffd
    80003b8c:	110080e7          	jalr	272(ra) # 80000c98 <release>
}
    80003b90:	8526                	mv	a0,s1
    80003b92:	60e2                	ld	ra,24(sp)
    80003b94:	6442                	ld	s0,16(sp)
    80003b96:	64a2                	ld	s1,8(sp)
    80003b98:	6105                	addi	sp,sp,32
    80003b9a:	8082                	ret

0000000080003b9c <ilock>:
{
    80003b9c:	1101                	addi	sp,sp,-32
    80003b9e:	ec06                	sd	ra,24(sp)
    80003ba0:	e822                	sd	s0,16(sp)
    80003ba2:	e426                	sd	s1,8(sp)
    80003ba4:	e04a                	sd	s2,0(sp)
    80003ba6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ba8:	c115                	beqz	a0,80003bcc <ilock+0x30>
    80003baa:	84aa                	mv	s1,a0
    80003bac:	451c                	lw	a5,8(a0)
    80003bae:	00f05f63          	blez	a5,80003bcc <ilock+0x30>
  acquiresleep(&ip->lock);
    80003bb2:	0541                	addi	a0,a0,16
    80003bb4:	00001097          	auipc	ra,0x1
    80003bb8:	cb2080e7          	jalr	-846(ra) # 80004866 <acquiresleep>
  if(ip->valid == 0){
    80003bbc:	40bc                	lw	a5,64(s1)
    80003bbe:	cf99                	beqz	a5,80003bdc <ilock+0x40>
}
    80003bc0:	60e2                	ld	ra,24(sp)
    80003bc2:	6442                	ld	s0,16(sp)
    80003bc4:	64a2                	ld	s1,8(sp)
    80003bc6:	6902                	ld	s2,0(sp)
    80003bc8:	6105                	addi	sp,sp,32
    80003bca:	8082                	ret
    panic("ilock");
    80003bcc:	00005517          	auipc	a0,0x5
    80003bd0:	a8450513          	addi	a0,a0,-1404 # 80008650 <syscalls+0x180>
    80003bd4:	ffffd097          	auipc	ra,0xffffd
    80003bd8:	96a080e7          	jalr	-1686(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bdc:	40dc                	lw	a5,4(s1)
    80003bde:	0047d79b          	srliw	a5,a5,0x4
    80003be2:	0001c597          	auipc	a1,0x1c
    80003be6:	71e5a583          	lw	a1,1822(a1) # 80020300 <sb+0x18>
    80003bea:	9dbd                	addw	a1,a1,a5
    80003bec:	4088                	lw	a0,0(s1)
    80003bee:	fffff097          	auipc	ra,0xfffff
    80003bf2:	7ac080e7          	jalr	1964(ra) # 8000339a <bread>
    80003bf6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bf8:	05850593          	addi	a1,a0,88
    80003bfc:	40dc                	lw	a5,4(s1)
    80003bfe:	8bbd                	andi	a5,a5,15
    80003c00:	079a                	slli	a5,a5,0x6
    80003c02:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c04:	00059783          	lh	a5,0(a1)
    80003c08:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c0c:	00259783          	lh	a5,2(a1)
    80003c10:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c14:	00459783          	lh	a5,4(a1)
    80003c18:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c1c:	00659783          	lh	a5,6(a1)
    80003c20:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c24:	459c                	lw	a5,8(a1)
    80003c26:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c28:	03400613          	li	a2,52
    80003c2c:	05b1                	addi	a1,a1,12
    80003c2e:	05048513          	addi	a0,s1,80
    80003c32:	ffffd097          	auipc	ra,0xffffd
    80003c36:	10e080e7          	jalr	270(ra) # 80000d40 <memmove>
    brelse(bp);
    80003c3a:	854a                	mv	a0,s2
    80003c3c:	00000097          	auipc	ra,0x0
    80003c40:	88e080e7          	jalr	-1906(ra) # 800034ca <brelse>
    ip->valid = 1;
    80003c44:	4785                	li	a5,1
    80003c46:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c48:	04449783          	lh	a5,68(s1)
    80003c4c:	fbb5                	bnez	a5,80003bc0 <ilock+0x24>
      panic("ilock: no type");
    80003c4e:	00005517          	auipc	a0,0x5
    80003c52:	a0a50513          	addi	a0,a0,-1526 # 80008658 <syscalls+0x188>
    80003c56:	ffffd097          	auipc	ra,0xffffd
    80003c5a:	8e8080e7          	jalr	-1816(ra) # 8000053e <panic>

0000000080003c5e <iunlock>:
{
    80003c5e:	1101                	addi	sp,sp,-32
    80003c60:	ec06                	sd	ra,24(sp)
    80003c62:	e822                	sd	s0,16(sp)
    80003c64:	e426                	sd	s1,8(sp)
    80003c66:	e04a                	sd	s2,0(sp)
    80003c68:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c6a:	c905                	beqz	a0,80003c9a <iunlock+0x3c>
    80003c6c:	84aa                	mv	s1,a0
    80003c6e:	01050913          	addi	s2,a0,16
    80003c72:	854a                	mv	a0,s2
    80003c74:	00001097          	auipc	ra,0x1
    80003c78:	c8c080e7          	jalr	-884(ra) # 80004900 <holdingsleep>
    80003c7c:	cd19                	beqz	a0,80003c9a <iunlock+0x3c>
    80003c7e:	449c                	lw	a5,8(s1)
    80003c80:	00f05d63          	blez	a5,80003c9a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c84:	854a                	mv	a0,s2
    80003c86:	00001097          	auipc	ra,0x1
    80003c8a:	c36080e7          	jalr	-970(ra) # 800048bc <releasesleep>
}
    80003c8e:	60e2                	ld	ra,24(sp)
    80003c90:	6442                	ld	s0,16(sp)
    80003c92:	64a2                	ld	s1,8(sp)
    80003c94:	6902                	ld	s2,0(sp)
    80003c96:	6105                	addi	sp,sp,32
    80003c98:	8082                	ret
    panic("iunlock");
    80003c9a:	00005517          	auipc	a0,0x5
    80003c9e:	9ce50513          	addi	a0,a0,-1586 # 80008668 <syscalls+0x198>
    80003ca2:	ffffd097          	auipc	ra,0xffffd
    80003ca6:	89c080e7          	jalr	-1892(ra) # 8000053e <panic>

0000000080003caa <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003caa:	7179                	addi	sp,sp,-48
    80003cac:	f406                	sd	ra,40(sp)
    80003cae:	f022                	sd	s0,32(sp)
    80003cb0:	ec26                	sd	s1,24(sp)
    80003cb2:	e84a                	sd	s2,16(sp)
    80003cb4:	e44e                	sd	s3,8(sp)
    80003cb6:	e052                	sd	s4,0(sp)
    80003cb8:	1800                	addi	s0,sp,48
    80003cba:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003cbc:	05050493          	addi	s1,a0,80
    80003cc0:	08050913          	addi	s2,a0,128
    80003cc4:	a021                	j	80003ccc <itrunc+0x22>
    80003cc6:	0491                	addi	s1,s1,4
    80003cc8:	01248d63          	beq	s1,s2,80003ce2 <itrunc+0x38>
    if(ip->addrs[i]){
    80003ccc:	408c                	lw	a1,0(s1)
    80003cce:	dde5                	beqz	a1,80003cc6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003cd0:	0009a503          	lw	a0,0(s3)
    80003cd4:	00000097          	auipc	ra,0x0
    80003cd8:	90c080e7          	jalr	-1780(ra) # 800035e0 <bfree>
      ip->addrs[i] = 0;
    80003cdc:	0004a023          	sw	zero,0(s1)
    80003ce0:	b7dd                	j	80003cc6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ce2:	0809a583          	lw	a1,128(s3)
    80003ce6:	e185                	bnez	a1,80003d06 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ce8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003cec:	854e                	mv	a0,s3
    80003cee:	00000097          	auipc	ra,0x0
    80003cf2:	de4080e7          	jalr	-540(ra) # 80003ad2 <iupdate>
}
    80003cf6:	70a2                	ld	ra,40(sp)
    80003cf8:	7402                	ld	s0,32(sp)
    80003cfa:	64e2                	ld	s1,24(sp)
    80003cfc:	6942                	ld	s2,16(sp)
    80003cfe:	69a2                	ld	s3,8(sp)
    80003d00:	6a02                	ld	s4,0(sp)
    80003d02:	6145                	addi	sp,sp,48
    80003d04:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d06:	0009a503          	lw	a0,0(s3)
    80003d0a:	fffff097          	auipc	ra,0xfffff
    80003d0e:	690080e7          	jalr	1680(ra) # 8000339a <bread>
    80003d12:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d14:	05850493          	addi	s1,a0,88
    80003d18:	45850913          	addi	s2,a0,1112
    80003d1c:	a811                	j	80003d30 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003d1e:	0009a503          	lw	a0,0(s3)
    80003d22:	00000097          	auipc	ra,0x0
    80003d26:	8be080e7          	jalr	-1858(ra) # 800035e0 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003d2a:	0491                	addi	s1,s1,4
    80003d2c:	01248563          	beq	s1,s2,80003d36 <itrunc+0x8c>
      if(a[j])
    80003d30:	408c                	lw	a1,0(s1)
    80003d32:	dde5                	beqz	a1,80003d2a <itrunc+0x80>
    80003d34:	b7ed                	j	80003d1e <itrunc+0x74>
    brelse(bp);
    80003d36:	8552                	mv	a0,s4
    80003d38:	fffff097          	auipc	ra,0xfffff
    80003d3c:	792080e7          	jalr	1938(ra) # 800034ca <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d40:	0809a583          	lw	a1,128(s3)
    80003d44:	0009a503          	lw	a0,0(s3)
    80003d48:	00000097          	auipc	ra,0x0
    80003d4c:	898080e7          	jalr	-1896(ra) # 800035e0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d50:	0809a023          	sw	zero,128(s3)
    80003d54:	bf51                	j	80003ce8 <itrunc+0x3e>

0000000080003d56 <iput>:
{
    80003d56:	1101                	addi	sp,sp,-32
    80003d58:	ec06                	sd	ra,24(sp)
    80003d5a:	e822                	sd	s0,16(sp)
    80003d5c:	e426                	sd	s1,8(sp)
    80003d5e:	e04a                	sd	s2,0(sp)
    80003d60:	1000                	addi	s0,sp,32
    80003d62:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d64:	0001c517          	auipc	a0,0x1c
    80003d68:	5a450513          	addi	a0,a0,1444 # 80020308 <itable>
    80003d6c:	ffffd097          	auipc	ra,0xffffd
    80003d70:	e78080e7          	jalr	-392(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d74:	4498                	lw	a4,8(s1)
    80003d76:	4785                	li	a5,1
    80003d78:	02f70363          	beq	a4,a5,80003d9e <iput+0x48>
  ip->ref--;
    80003d7c:	449c                	lw	a5,8(s1)
    80003d7e:	37fd                	addiw	a5,a5,-1
    80003d80:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d82:	0001c517          	auipc	a0,0x1c
    80003d86:	58650513          	addi	a0,a0,1414 # 80020308 <itable>
    80003d8a:	ffffd097          	auipc	ra,0xffffd
    80003d8e:	f0e080e7          	jalr	-242(ra) # 80000c98 <release>
}
    80003d92:	60e2                	ld	ra,24(sp)
    80003d94:	6442                	ld	s0,16(sp)
    80003d96:	64a2                	ld	s1,8(sp)
    80003d98:	6902                	ld	s2,0(sp)
    80003d9a:	6105                	addi	sp,sp,32
    80003d9c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d9e:	40bc                	lw	a5,64(s1)
    80003da0:	dff1                	beqz	a5,80003d7c <iput+0x26>
    80003da2:	04a49783          	lh	a5,74(s1)
    80003da6:	fbf9                	bnez	a5,80003d7c <iput+0x26>
    acquiresleep(&ip->lock);
    80003da8:	01048913          	addi	s2,s1,16
    80003dac:	854a                	mv	a0,s2
    80003dae:	00001097          	auipc	ra,0x1
    80003db2:	ab8080e7          	jalr	-1352(ra) # 80004866 <acquiresleep>
    release(&itable.lock);
    80003db6:	0001c517          	auipc	a0,0x1c
    80003dba:	55250513          	addi	a0,a0,1362 # 80020308 <itable>
    80003dbe:	ffffd097          	auipc	ra,0xffffd
    80003dc2:	eda080e7          	jalr	-294(ra) # 80000c98 <release>
    itrunc(ip);
    80003dc6:	8526                	mv	a0,s1
    80003dc8:	00000097          	auipc	ra,0x0
    80003dcc:	ee2080e7          	jalr	-286(ra) # 80003caa <itrunc>
    ip->type = 0;
    80003dd0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003dd4:	8526                	mv	a0,s1
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	cfc080e7          	jalr	-772(ra) # 80003ad2 <iupdate>
    ip->valid = 0;
    80003dde:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003de2:	854a                	mv	a0,s2
    80003de4:	00001097          	auipc	ra,0x1
    80003de8:	ad8080e7          	jalr	-1320(ra) # 800048bc <releasesleep>
    acquire(&itable.lock);
    80003dec:	0001c517          	auipc	a0,0x1c
    80003df0:	51c50513          	addi	a0,a0,1308 # 80020308 <itable>
    80003df4:	ffffd097          	auipc	ra,0xffffd
    80003df8:	df0080e7          	jalr	-528(ra) # 80000be4 <acquire>
    80003dfc:	b741                	j	80003d7c <iput+0x26>

0000000080003dfe <iunlockput>:
{
    80003dfe:	1101                	addi	sp,sp,-32
    80003e00:	ec06                	sd	ra,24(sp)
    80003e02:	e822                	sd	s0,16(sp)
    80003e04:	e426                	sd	s1,8(sp)
    80003e06:	1000                	addi	s0,sp,32
    80003e08:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	e54080e7          	jalr	-428(ra) # 80003c5e <iunlock>
  iput(ip);
    80003e12:	8526                	mv	a0,s1
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	f42080e7          	jalr	-190(ra) # 80003d56 <iput>
}
    80003e1c:	60e2                	ld	ra,24(sp)
    80003e1e:	6442                	ld	s0,16(sp)
    80003e20:	64a2                	ld	s1,8(sp)
    80003e22:	6105                	addi	sp,sp,32
    80003e24:	8082                	ret

0000000080003e26 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e26:	1141                	addi	sp,sp,-16
    80003e28:	e422                	sd	s0,8(sp)
    80003e2a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e2c:	411c                	lw	a5,0(a0)
    80003e2e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e30:	415c                	lw	a5,4(a0)
    80003e32:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e34:	04451783          	lh	a5,68(a0)
    80003e38:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e3c:	04a51783          	lh	a5,74(a0)
    80003e40:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e44:	04c56783          	lwu	a5,76(a0)
    80003e48:	e99c                	sd	a5,16(a1)
}
    80003e4a:	6422                	ld	s0,8(sp)
    80003e4c:	0141                	addi	sp,sp,16
    80003e4e:	8082                	ret

0000000080003e50 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e50:	457c                	lw	a5,76(a0)
    80003e52:	0ed7e963          	bltu	a5,a3,80003f44 <readi+0xf4>
{
    80003e56:	7159                	addi	sp,sp,-112
    80003e58:	f486                	sd	ra,104(sp)
    80003e5a:	f0a2                	sd	s0,96(sp)
    80003e5c:	eca6                	sd	s1,88(sp)
    80003e5e:	e8ca                	sd	s2,80(sp)
    80003e60:	e4ce                	sd	s3,72(sp)
    80003e62:	e0d2                	sd	s4,64(sp)
    80003e64:	fc56                	sd	s5,56(sp)
    80003e66:	f85a                	sd	s6,48(sp)
    80003e68:	f45e                	sd	s7,40(sp)
    80003e6a:	f062                	sd	s8,32(sp)
    80003e6c:	ec66                	sd	s9,24(sp)
    80003e6e:	e86a                	sd	s10,16(sp)
    80003e70:	e46e                	sd	s11,8(sp)
    80003e72:	1880                	addi	s0,sp,112
    80003e74:	8baa                	mv	s7,a0
    80003e76:	8c2e                	mv	s8,a1
    80003e78:	8ab2                	mv	s5,a2
    80003e7a:	84b6                	mv	s1,a3
    80003e7c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e7e:	9f35                	addw	a4,a4,a3
    return 0;
    80003e80:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e82:	0ad76063          	bltu	a4,a3,80003f22 <readi+0xd2>
  if(off + n > ip->size)
    80003e86:	00e7f463          	bgeu	a5,a4,80003e8e <readi+0x3e>
    n = ip->size - off;
    80003e8a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e8e:	0a0b0963          	beqz	s6,80003f40 <readi+0xf0>
    80003e92:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e94:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e98:	5cfd                	li	s9,-1
    80003e9a:	a82d                	j	80003ed4 <readi+0x84>
    80003e9c:	020a1d93          	slli	s11,s4,0x20
    80003ea0:	020ddd93          	srli	s11,s11,0x20
    80003ea4:	05890613          	addi	a2,s2,88
    80003ea8:	86ee                	mv	a3,s11
    80003eaa:	963a                	add	a2,a2,a4
    80003eac:	85d6                	mv	a1,s5
    80003eae:	8562                	mv	a0,s8
    80003eb0:	fffff097          	auipc	ra,0xfffff
    80003eb4:	a7a080e7          	jalr	-1414(ra) # 8000292a <either_copyout>
    80003eb8:	05950d63          	beq	a0,s9,80003f12 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ebc:	854a                	mv	a0,s2
    80003ebe:	fffff097          	auipc	ra,0xfffff
    80003ec2:	60c080e7          	jalr	1548(ra) # 800034ca <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ec6:	013a09bb          	addw	s3,s4,s3
    80003eca:	009a04bb          	addw	s1,s4,s1
    80003ece:	9aee                	add	s5,s5,s11
    80003ed0:	0569f763          	bgeu	s3,s6,80003f1e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ed4:	000ba903          	lw	s2,0(s7)
    80003ed8:	00a4d59b          	srliw	a1,s1,0xa
    80003edc:	855e                	mv	a0,s7
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	8b0080e7          	jalr	-1872(ra) # 8000378e <bmap>
    80003ee6:	0005059b          	sext.w	a1,a0
    80003eea:	854a                	mv	a0,s2
    80003eec:	fffff097          	auipc	ra,0xfffff
    80003ef0:	4ae080e7          	jalr	1198(ra) # 8000339a <bread>
    80003ef4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ef6:	3ff4f713          	andi	a4,s1,1023
    80003efa:	40ed07bb          	subw	a5,s10,a4
    80003efe:	413b06bb          	subw	a3,s6,s3
    80003f02:	8a3e                	mv	s4,a5
    80003f04:	2781                	sext.w	a5,a5
    80003f06:	0006861b          	sext.w	a2,a3
    80003f0a:	f8f679e3          	bgeu	a2,a5,80003e9c <readi+0x4c>
    80003f0e:	8a36                	mv	s4,a3
    80003f10:	b771                	j	80003e9c <readi+0x4c>
      brelse(bp);
    80003f12:	854a                	mv	a0,s2
    80003f14:	fffff097          	auipc	ra,0xfffff
    80003f18:	5b6080e7          	jalr	1462(ra) # 800034ca <brelse>
      tot = -1;
    80003f1c:	59fd                	li	s3,-1
  }
  return tot;
    80003f1e:	0009851b          	sext.w	a0,s3
}
    80003f22:	70a6                	ld	ra,104(sp)
    80003f24:	7406                	ld	s0,96(sp)
    80003f26:	64e6                	ld	s1,88(sp)
    80003f28:	6946                	ld	s2,80(sp)
    80003f2a:	69a6                	ld	s3,72(sp)
    80003f2c:	6a06                	ld	s4,64(sp)
    80003f2e:	7ae2                	ld	s5,56(sp)
    80003f30:	7b42                	ld	s6,48(sp)
    80003f32:	7ba2                	ld	s7,40(sp)
    80003f34:	7c02                	ld	s8,32(sp)
    80003f36:	6ce2                	ld	s9,24(sp)
    80003f38:	6d42                	ld	s10,16(sp)
    80003f3a:	6da2                	ld	s11,8(sp)
    80003f3c:	6165                	addi	sp,sp,112
    80003f3e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f40:	89da                	mv	s3,s6
    80003f42:	bff1                	j	80003f1e <readi+0xce>
    return 0;
    80003f44:	4501                	li	a0,0
}
    80003f46:	8082                	ret

0000000080003f48 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f48:	457c                	lw	a5,76(a0)
    80003f4a:	10d7e863          	bltu	a5,a3,8000405a <writei+0x112>
{
    80003f4e:	7159                	addi	sp,sp,-112
    80003f50:	f486                	sd	ra,104(sp)
    80003f52:	f0a2                	sd	s0,96(sp)
    80003f54:	eca6                	sd	s1,88(sp)
    80003f56:	e8ca                	sd	s2,80(sp)
    80003f58:	e4ce                	sd	s3,72(sp)
    80003f5a:	e0d2                	sd	s4,64(sp)
    80003f5c:	fc56                	sd	s5,56(sp)
    80003f5e:	f85a                	sd	s6,48(sp)
    80003f60:	f45e                	sd	s7,40(sp)
    80003f62:	f062                	sd	s8,32(sp)
    80003f64:	ec66                	sd	s9,24(sp)
    80003f66:	e86a                	sd	s10,16(sp)
    80003f68:	e46e                	sd	s11,8(sp)
    80003f6a:	1880                	addi	s0,sp,112
    80003f6c:	8b2a                	mv	s6,a0
    80003f6e:	8c2e                	mv	s8,a1
    80003f70:	8ab2                	mv	s5,a2
    80003f72:	8936                	mv	s2,a3
    80003f74:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003f76:	00e687bb          	addw	a5,a3,a4
    80003f7a:	0ed7e263          	bltu	a5,a3,8000405e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f7e:	00043737          	lui	a4,0x43
    80003f82:	0ef76063          	bltu	a4,a5,80004062 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f86:	0c0b8863          	beqz	s7,80004056 <writei+0x10e>
    80003f8a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f8c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f90:	5cfd                	li	s9,-1
    80003f92:	a091                	j	80003fd6 <writei+0x8e>
    80003f94:	02099d93          	slli	s11,s3,0x20
    80003f98:	020ddd93          	srli	s11,s11,0x20
    80003f9c:	05848513          	addi	a0,s1,88
    80003fa0:	86ee                	mv	a3,s11
    80003fa2:	8656                	mv	a2,s5
    80003fa4:	85e2                	mv	a1,s8
    80003fa6:	953a                	add	a0,a0,a4
    80003fa8:	fffff097          	auipc	ra,0xfffff
    80003fac:	9d8080e7          	jalr	-1576(ra) # 80002980 <either_copyin>
    80003fb0:	07950263          	beq	a0,s9,80004014 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003fb4:	8526                	mv	a0,s1
    80003fb6:	00000097          	auipc	ra,0x0
    80003fba:	790080e7          	jalr	1936(ra) # 80004746 <log_write>
    brelse(bp);
    80003fbe:	8526                	mv	a0,s1
    80003fc0:	fffff097          	auipc	ra,0xfffff
    80003fc4:	50a080e7          	jalr	1290(ra) # 800034ca <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fc8:	01498a3b          	addw	s4,s3,s4
    80003fcc:	0129893b          	addw	s2,s3,s2
    80003fd0:	9aee                	add	s5,s5,s11
    80003fd2:	057a7663          	bgeu	s4,s7,8000401e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fd6:	000b2483          	lw	s1,0(s6)
    80003fda:	00a9559b          	srliw	a1,s2,0xa
    80003fde:	855a                	mv	a0,s6
    80003fe0:	fffff097          	auipc	ra,0xfffff
    80003fe4:	7ae080e7          	jalr	1966(ra) # 8000378e <bmap>
    80003fe8:	0005059b          	sext.w	a1,a0
    80003fec:	8526                	mv	a0,s1
    80003fee:	fffff097          	auipc	ra,0xfffff
    80003ff2:	3ac080e7          	jalr	940(ra) # 8000339a <bread>
    80003ff6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ff8:	3ff97713          	andi	a4,s2,1023
    80003ffc:	40ed07bb          	subw	a5,s10,a4
    80004000:	414b86bb          	subw	a3,s7,s4
    80004004:	89be                	mv	s3,a5
    80004006:	2781                	sext.w	a5,a5
    80004008:	0006861b          	sext.w	a2,a3
    8000400c:	f8f674e3          	bgeu	a2,a5,80003f94 <writei+0x4c>
    80004010:	89b6                	mv	s3,a3
    80004012:	b749                	j	80003f94 <writei+0x4c>
      brelse(bp);
    80004014:	8526                	mv	a0,s1
    80004016:	fffff097          	auipc	ra,0xfffff
    8000401a:	4b4080e7          	jalr	1204(ra) # 800034ca <brelse>
  }

  if(off > ip->size)
    8000401e:	04cb2783          	lw	a5,76(s6)
    80004022:	0127f463          	bgeu	a5,s2,8000402a <writei+0xe2>
    ip->size = off;
    80004026:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000402a:	855a                	mv	a0,s6
    8000402c:	00000097          	auipc	ra,0x0
    80004030:	aa6080e7          	jalr	-1370(ra) # 80003ad2 <iupdate>

  return tot;
    80004034:	000a051b          	sext.w	a0,s4
}
    80004038:	70a6                	ld	ra,104(sp)
    8000403a:	7406                	ld	s0,96(sp)
    8000403c:	64e6                	ld	s1,88(sp)
    8000403e:	6946                	ld	s2,80(sp)
    80004040:	69a6                	ld	s3,72(sp)
    80004042:	6a06                	ld	s4,64(sp)
    80004044:	7ae2                	ld	s5,56(sp)
    80004046:	7b42                	ld	s6,48(sp)
    80004048:	7ba2                	ld	s7,40(sp)
    8000404a:	7c02                	ld	s8,32(sp)
    8000404c:	6ce2                	ld	s9,24(sp)
    8000404e:	6d42                	ld	s10,16(sp)
    80004050:	6da2                	ld	s11,8(sp)
    80004052:	6165                	addi	sp,sp,112
    80004054:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004056:	8a5e                	mv	s4,s7
    80004058:	bfc9                	j	8000402a <writei+0xe2>
    return -1;
    8000405a:	557d                	li	a0,-1
}
    8000405c:	8082                	ret
    return -1;
    8000405e:	557d                	li	a0,-1
    80004060:	bfe1                	j	80004038 <writei+0xf0>
    return -1;
    80004062:	557d                	li	a0,-1
    80004064:	bfd1                	j	80004038 <writei+0xf0>

0000000080004066 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004066:	1141                	addi	sp,sp,-16
    80004068:	e406                	sd	ra,8(sp)
    8000406a:	e022                	sd	s0,0(sp)
    8000406c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000406e:	4639                	li	a2,14
    80004070:	ffffd097          	auipc	ra,0xffffd
    80004074:	d48080e7          	jalr	-696(ra) # 80000db8 <strncmp>
}
    80004078:	60a2                	ld	ra,8(sp)
    8000407a:	6402                	ld	s0,0(sp)
    8000407c:	0141                	addi	sp,sp,16
    8000407e:	8082                	ret

0000000080004080 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004080:	7139                	addi	sp,sp,-64
    80004082:	fc06                	sd	ra,56(sp)
    80004084:	f822                	sd	s0,48(sp)
    80004086:	f426                	sd	s1,40(sp)
    80004088:	f04a                	sd	s2,32(sp)
    8000408a:	ec4e                	sd	s3,24(sp)
    8000408c:	e852                	sd	s4,16(sp)
    8000408e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004090:	04451703          	lh	a4,68(a0)
    80004094:	4785                	li	a5,1
    80004096:	00f71a63          	bne	a4,a5,800040aa <dirlookup+0x2a>
    8000409a:	892a                	mv	s2,a0
    8000409c:	89ae                	mv	s3,a1
    8000409e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800040a0:	457c                	lw	a5,76(a0)
    800040a2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800040a4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040a6:	e79d                	bnez	a5,800040d4 <dirlookup+0x54>
    800040a8:	a8a5                	j	80004120 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800040aa:	00004517          	auipc	a0,0x4
    800040ae:	5c650513          	addi	a0,a0,1478 # 80008670 <syscalls+0x1a0>
    800040b2:	ffffc097          	auipc	ra,0xffffc
    800040b6:	48c080e7          	jalr	1164(ra) # 8000053e <panic>
      panic("dirlookup read");
    800040ba:	00004517          	auipc	a0,0x4
    800040be:	5ce50513          	addi	a0,a0,1486 # 80008688 <syscalls+0x1b8>
    800040c2:	ffffc097          	auipc	ra,0xffffc
    800040c6:	47c080e7          	jalr	1148(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ca:	24c1                	addiw	s1,s1,16
    800040cc:	04c92783          	lw	a5,76(s2)
    800040d0:	04f4f763          	bgeu	s1,a5,8000411e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040d4:	4741                	li	a4,16
    800040d6:	86a6                	mv	a3,s1
    800040d8:	fc040613          	addi	a2,s0,-64
    800040dc:	4581                	li	a1,0
    800040de:	854a                	mv	a0,s2
    800040e0:	00000097          	auipc	ra,0x0
    800040e4:	d70080e7          	jalr	-656(ra) # 80003e50 <readi>
    800040e8:	47c1                	li	a5,16
    800040ea:	fcf518e3          	bne	a0,a5,800040ba <dirlookup+0x3a>
    if(de.inum == 0)
    800040ee:	fc045783          	lhu	a5,-64(s0)
    800040f2:	dfe1                	beqz	a5,800040ca <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040f4:	fc240593          	addi	a1,s0,-62
    800040f8:	854e                	mv	a0,s3
    800040fa:	00000097          	auipc	ra,0x0
    800040fe:	f6c080e7          	jalr	-148(ra) # 80004066 <namecmp>
    80004102:	f561                	bnez	a0,800040ca <dirlookup+0x4a>
      if(poff)
    80004104:	000a0463          	beqz	s4,8000410c <dirlookup+0x8c>
        *poff = off;
    80004108:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000410c:	fc045583          	lhu	a1,-64(s0)
    80004110:	00092503          	lw	a0,0(s2)
    80004114:	fffff097          	auipc	ra,0xfffff
    80004118:	754080e7          	jalr	1876(ra) # 80003868 <iget>
    8000411c:	a011                	j	80004120 <dirlookup+0xa0>
  return 0;
    8000411e:	4501                	li	a0,0
}
    80004120:	70e2                	ld	ra,56(sp)
    80004122:	7442                	ld	s0,48(sp)
    80004124:	74a2                	ld	s1,40(sp)
    80004126:	7902                	ld	s2,32(sp)
    80004128:	69e2                	ld	s3,24(sp)
    8000412a:	6a42                	ld	s4,16(sp)
    8000412c:	6121                	addi	sp,sp,64
    8000412e:	8082                	ret

0000000080004130 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004130:	711d                	addi	sp,sp,-96
    80004132:	ec86                	sd	ra,88(sp)
    80004134:	e8a2                	sd	s0,80(sp)
    80004136:	e4a6                	sd	s1,72(sp)
    80004138:	e0ca                	sd	s2,64(sp)
    8000413a:	fc4e                	sd	s3,56(sp)
    8000413c:	f852                	sd	s4,48(sp)
    8000413e:	f456                	sd	s5,40(sp)
    80004140:	f05a                	sd	s6,32(sp)
    80004142:	ec5e                	sd	s7,24(sp)
    80004144:	e862                	sd	s8,16(sp)
    80004146:	e466                	sd	s9,8(sp)
    80004148:	1080                	addi	s0,sp,96
    8000414a:	84aa                	mv	s1,a0
    8000414c:	8b2e                	mv	s6,a1
    8000414e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004150:	00054703          	lbu	a4,0(a0)
    80004154:	02f00793          	li	a5,47
    80004158:	02f70363          	beq	a4,a5,8000417e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000415c:	ffffe097          	auipc	ra,0xffffe
    80004160:	b70080e7          	jalr	-1168(ra) # 80001ccc <myproc>
    80004164:	15053503          	ld	a0,336(a0)
    80004168:	00000097          	auipc	ra,0x0
    8000416c:	9f6080e7          	jalr	-1546(ra) # 80003b5e <idup>
    80004170:	89aa                	mv	s3,a0
  while(*path == '/')
    80004172:	02f00913          	li	s2,47
  len = path - s;
    80004176:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004178:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000417a:	4c05                	li	s8,1
    8000417c:	a865                	j	80004234 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000417e:	4585                	li	a1,1
    80004180:	4505                	li	a0,1
    80004182:	fffff097          	auipc	ra,0xfffff
    80004186:	6e6080e7          	jalr	1766(ra) # 80003868 <iget>
    8000418a:	89aa                	mv	s3,a0
    8000418c:	b7dd                	j	80004172 <namex+0x42>
      iunlockput(ip);
    8000418e:	854e                	mv	a0,s3
    80004190:	00000097          	auipc	ra,0x0
    80004194:	c6e080e7          	jalr	-914(ra) # 80003dfe <iunlockput>
      return 0;
    80004198:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000419a:	854e                	mv	a0,s3
    8000419c:	60e6                	ld	ra,88(sp)
    8000419e:	6446                	ld	s0,80(sp)
    800041a0:	64a6                	ld	s1,72(sp)
    800041a2:	6906                	ld	s2,64(sp)
    800041a4:	79e2                	ld	s3,56(sp)
    800041a6:	7a42                	ld	s4,48(sp)
    800041a8:	7aa2                	ld	s5,40(sp)
    800041aa:	7b02                	ld	s6,32(sp)
    800041ac:	6be2                	ld	s7,24(sp)
    800041ae:	6c42                	ld	s8,16(sp)
    800041b0:	6ca2                	ld	s9,8(sp)
    800041b2:	6125                	addi	sp,sp,96
    800041b4:	8082                	ret
      iunlock(ip);
    800041b6:	854e                	mv	a0,s3
    800041b8:	00000097          	auipc	ra,0x0
    800041bc:	aa6080e7          	jalr	-1370(ra) # 80003c5e <iunlock>
      return ip;
    800041c0:	bfe9                	j	8000419a <namex+0x6a>
      iunlockput(ip);
    800041c2:	854e                	mv	a0,s3
    800041c4:	00000097          	auipc	ra,0x0
    800041c8:	c3a080e7          	jalr	-966(ra) # 80003dfe <iunlockput>
      return 0;
    800041cc:	89d2                	mv	s3,s4
    800041ce:	b7f1                	j	8000419a <namex+0x6a>
  len = path - s;
    800041d0:	40b48633          	sub	a2,s1,a1
    800041d4:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800041d8:	094cd463          	bge	s9,s4,80004260 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800041dc:	4639                	li	a2,14
    800041de:	8556                	mv	a0,s5
    800041e0:	ffffd097          	auipc	ra,0xffffd
    800041e4:	b60080e7          	jalr	-1184(ra) # 80000d40 <memmove>
  while(*path == '/')
    800041e8:	0004c783          	lbu	a5,0(s1)
    800041ec:	01279763          	bne	a5,s2,800041fa <namex+0xca>
    path++;
    800041f0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041f2:	0004c783          	lbu	a5,0(s1)
    800041f6:	ff278de3          	beq	a5,s2,800041f0 <namex+0xc0>
    ilock(ip);
    800041fa:	854e                	mv	a0,s3
    800041fc:	00000097          	auipc	ra,0x0
    80004200:	9a0080e7          	jalr	-1632(ra) # 80003b9c <ilock>
    if(ip->type != T_DIR){
    80004204:	04499783          	lh	a5,68(s3)
    80004208:	f98793e3          	bne	a5,s8,8000418e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000420c:	000b0563          	beqz	s6,80004216 <namex+0xe6>
    80004210:	0004c783          	lbu	a5,0(s1)
    80004214:	d3cd                	beqz	a5,800041b6 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004216:	865e                	mv	a2,s7
    80004218:	85d6                	mv	a1,s5
    8000421a:	854e                	mv	a0,s3
    8000421c:	00000097          	auipc	ra,0x0
    80004220:	e64080e7          	jalr	-412(ra) # 80004080 <dirlookup>
    80004224:	8a2a                	mv	s4,a0
    80004226:	dd51                	beqz	a0,800041c2 <namex+0x92>
    iunlockput(ip);
    80004228:	854e                	mv	a0,s3
    8000422a:	00000097          	auipc	ra,0x0
    8000422e:	bd4080e7          	jalr	-1068(ra) # 80003dfe <iunlockput>
    ip = next;
    80004232:	89d2                	mv	s3,s4
  while(*path == '/')
    80004234:	0004c783          	lbu	a5,0(s1)
    80004238:	05279763          	bne	a5,s2,80004286 <namex+0x156>
    path++;
    8000423c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000423e:	0004c783          	lbu	a5,0(s1)
    80004242:	ff278de3          	beq	a5,s2,8000423c <namex+0x10c>
  if(*path == 0)
    80004246:	c79d                	beqz	a5,80004274 <namex+0x144>
    path++;
    80004248:	85a6                	mv	a1,s1
  len = path - s;
    8000424a:	8a5e                	mv	s4,s7
    8000424c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000424e:	01278963          	beq	a5,s2,80004260 <namex+0x130>
    80004252:	dfbd                	beqz	a5,800041d0 <namex+0xa0>
    path++;
    80004254:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004256:	0004c783          	lbu	a5,0(s1)
    8000425a:	ff279ce3          	bne	a5,s2,80004252 <namex+0x122>
    8000425e:	bf8d                	j	800041d0 <namex+0xa0>
    memmove(name, s, len);
    80004260:	2601                	sext.w	a2,a2
    80004262:	8556                	mv	a0,s5
    80004264:	ffffd097          	auipc	ra,0xffffd
    80004268:	adc080e7          	jalr	-1316(ra) # 80000d40 <memmove>
    name[len] = 0;
    8000426c:	9a56                	add	s4,s4,s5
    8000426e:	000a0023          	sb	zero,0(s4)
    80004272:	bf9d                	j	800041e8 <namex+0xb8>
  if(nameiparent){
    80004274:	f20b03e3          	beqz	s6,8000419a <namex+0x6a>
    iput(ip);
    80004278:	854e                	mv	a0,s3
    8000427a:	00000097          	auipc	ra,0x0
    8000427e:	adc080e7          	jalr	-1316(ra) # 80003d56 <iput>
    return 0;
    80004282:	4981                	li	s3,0
    80004284:	bf19                	j	8000419a <namex+0x6a>
  if(*path == 0)
    80004286:	d7fd                	beqz	a5,80004274 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004288:	0004c783          	lbu	a5,0(s1)
    8000428c:	85a6                	mv	a1,s1
    8000428e:	b7d1                	j	80004252 <namex+0x122>

0000000080004290 <dirlink>:
{
    80004290:	7139                	addi	sp,sp,-64
    80004292:	fc06                	sd	ra,56(sp)
    80004294:	f822                	sd	s0,48(sp)
    80004296:	f426                	sd	s1,40(sp)
    80004298:	f04a                	sd	s2,32(sp)
    8000429a:	ec4e                	sd	s3,24(sp)
    8000429c:	e852                	sd	s4,16(sp)
    8000429e:	0080                	addi	s0,sp,64
    800042a0:	892a                	mv	s2,a0
    800042a2:	8a2e                	mv	s4,a1
    800042a4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800042a6:	4601                	li	a2,0
    800042a8:	00000097          	auipc	ra,0x0
    800042ac:	dd8080e7          	jalr	-552(ra) # 80004080 <dirlookup>
    800042b0:	e93d                	bnez	a0,80004326 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042b2:	04c92483          	lw	s1,76(s2)
    800042b6:	c49d                	beqz	s1,800042e4 <dirlink+0x54>
    800042b8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042ba:	4741                	li	a4,16
    800042bc:	86a6                	mv	a3,s1
    800042be:	fc040613          	addi	a2,s0,-64
    800042c2:	4581                	li	a1,0
    800042c4:	854a                	mv	a0,s2
    800042c6:	00000097          	auipc	ra,0x0
    800042ca:	b8a080e7          	jalr	-1142(ra) # 80003e50 <readi>
    800042ce:	47c1                	li	a5,16
    800042d0:	06f51163          	bne	a0,a5,80004332 <dirlink+0xa2>
    if(de.inum == 0)
    800042d4:	fc045783          	lhu	a5,-64(s0)
    800042d8:	c791                	beqz	a5,800042e4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042da:	24c1                	addiw	s1,s1,16
    800042dc:	04c92783          	lw	a5,76(s2)
    800042e0:	fcf4ede3          	bltu	s1,a5,800042ba <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042e4:	4639                	li	a2,14
    800042e6:	85d2                	mv	a1,s4
    800042e8:	fc240513          	addi	a0,s0,-62
    800042ec:	ffffd097          	auipc	ra,0xffffd
    800042f0:	b08080e7          	jalr	-1272(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800042f4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042f8:	4741                	li	a4,16
    800042fa:	86a6                	mv	a3,s1
    800042fc:	fc040613          	addi	a2,s0,-64
    80004300:	4581                	li	a1,0
    80004302:	854a                	mv	a0,s2
    80004304:	00000097          	auipc	ra,0x0
    80004308:	c44080e7          	jalr	-956(ra) # 80003f48 <writei>
    8000430c:	872a                	mv	a4,a0
    8000430e:	47c1                	li	a5,16
  return 0;
    80004310:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004312:	02f71863          	bne	a4,a5,80004342 <dirlink+0xb2>
}
    80004316:	70e2                	ld	ra,56(sp)
    80004318:	7442                	ld	s0,48(sp)
    8000431a:	74a2                	ld	s1,40(sp)
    8000431c:	7902                	ld	s2,32(sp)
    8000431e:	69e2                	ld	s3,24(sp)
    80004320:	6a42                	ld	s4,16(sp)
    80004322:	6121                	addi	sp,sp,64
    80004324:	8082                	ret
    iput(ip);
    80004326:	00000097          	auipc	ra,0x0
    8000432a:	a30080e7          	jalr	-1488(ra) # 80003d56 <iput>
    return -1;
    8000432e:	557d                	li	a0,-1
    80004330:	b7dd                	j	80004316 <dirlink+0x86>
      panic("dirlink read");
    80004332:	00004517          	auipc	a0,0x4
    80004336:	36650513          	addi	a0,a0,870 # 80008698 <syscalls+0x1c8>
    8000433a:	ffffc097          	auipc	ra,0xffffc
    8000433e:	204080e7          	jalr	516(ra) # 8000053e <panic>
    panic("dirlink");
    80004342:	00004517          	auipc	a0,0x4
    80004346:	46650513          	addi	a0,a0,1126 # 800087a8 <syscalls+0x2d8>
    8000434a:	ffffc097          	auipc	ra,0xffffc
    8000434e:	1f4080e7          	jalr	500(ra) # 8000053e <panic>

0000000080004352 <namei>:

struct inode*
namei(char *path)
{
    80004352:	1101                	addi	sp,sp,-32
    80004354:	ec06                	sd	ra,24(sp)
    80004356:	e822                	sd	s0,16(sp)
    80004358:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000435a:	fe040613          	addi	a2,s0,-32
    8000435e:	4581                	li	a1,0
    80004360:	00000097          	auipc	ra,0x0
    80004364:	dd0080e7          	jalr	-560(ra) # 80004130 <namex>
}
    80004368:	60e2                	ld	ra,24(sp)
    8000436a:	6442                	ld	s0,16(sp)
    8000436c:	6105                	addi	sp,sp,32
    8000436e:	8082                	ret

0000000080004370 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004370:	1141                	addi	sp,sp,-16
    80004372:	e406                	sd	ra,8(sp)
    80004374:	e022                	sd	s0,0(sp)
    80004376:	0800                	addi	s0,sp,16
    80004378:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000437a:	4585                	li	a1,1
    8000437c:	00000097          	auipc	ra,0x0
    80004380:	db4080e7          	jalr	-588(ra) # 80004130 <namex>
}
    80004384:	60a2                	ld	ra,8(sp)
    80004386:	6402                	ld	s0,0(sp)
    80004388:	0141                	addi	sp,sp,16
    8000438a:	8082                	ret

000000008000438c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000438c:	1101                	addi	sp,sp,-32
    8000438e:	ec06                	sd	ra,24(sp)
    80004390:	e822                	sd	s0,16(sp)
    80004392:	e426                	sd	s1,8(sp)
    80004394:	e04a                	sd	s2,0(sp)
    80004396:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004398:	0001e917          	auipc	s2,0x1e
    8000439c:	a1890913          	addi	s2,s2,-1512 # 80021db0 <log>
    800043a0:	01892583          	lw	a1,24(s2)
    800043a4:	02892503          	lw	a0,40(s2)
    800043a8:	fffff097          	auipc	ra,0xfffff
    800043ac:	ff2080e7          	jalr	-14(ra) # 8000339a <bread>
    800043b0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800043b2:	02c92683          	lw	a3,44(s2)
    800043b6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800043b8:	02d05763          	blez	a3,800043e6 <write_head+0x5a>
    800043bc:	0001e797          	auipc	a5,0x1e
    800043c0:	a2478793          	addi	a5,a5,-1500 # 80021de0 <log+0x30>
    800043c4:	05c50713          	addi	a4,a0,92
    800043c8:	36fd                	addiw	a3,a3,-1
    800043ca:	1682                	slli	a3,a3,0x20
    800043cc:	9281                	srli	a3,a3,0x20
    800043ce:	068a                	slli	a3,a3,0x2
    800043d0:	0001e617          	auipc	a2,0x1e
    800043d4:	a1460613          	addi	a2,a2,-1516 # 80021de4 <log+0x34>
    800043d8:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800043da:	4390                	lw	a2,0(a5)
    800043dc:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043de:	0791                	addi	a5,a5,4
    800043e0:	0711                	addi	a4,a4,4
    800043e2:	fed79ce3          	bne	a5,a3,800043da <write_head+0x4e>
  }
  bwrite(buf);
    800043e6:	8526                	mv	a0,s1
    800043e8:	fffff097          	auipc	ra,0xfffff
    800043ec:	0a4080e7          	jalr	164(ra) # 8000348c <bwrite>
  brelse(buf);
    800043f0:	8526                	mv	a0,s1
    800043f2:	fffff097          	auipc	ra,0xfffff
    800043f6:	0d8080e7          	jalr	216(ra) # 800034ca <brelse>
}
    800043fa:	60e2                	ld	ra,24(sp)
    800043fc:	6442                	ld	s0,16(sp)
    800043fe:	64a2                	ld	s1,8(sp)
    80004400:	6902                	ld	s2,0(sp)
    80004402:	6105                	addi	sp,sp,32
    80004404:	8082                	ret

0000000080004406 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004406:	0001e797          	auipc	a5,0x1e
    8000440a:	9d67a783          	lw	a5,-1578(a5) # 80021ddc <log+0x2c>
    8000440e:	0af05d63          	blez	a5,800044c8 <install_trans+0xc2>
{
    80004412:	7139                	addi	sp,sp,-64
    80004414:	fc06                	sd	ra,56(sp)
    80004416:	f822                	sd	s0,48(sp)
    80004418:	f426                	sd	s1,40(sp)
    8000441a:	f04a                	sd	s2,32(sp)
    8000441c:	ec4e                	sd	s3,24(sp)
    8000441e:	e852                	sd	s4,16(sp)
    80004420:	e456                	sd	s5,8(sp)
    80004422:	e05a                	sd	s6,0(sp)
    80004424:	0080                	addi	s0,sp,64
    80004426:	8b2a                	mv	s6,a0
    80004428:	0001ea97          	auipc	s5,0x1e
    8000442c:	9b8a8a93          	addi	s5,s5,-1608 # 80021de0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004430:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004432:	0001e997          	auipc	s3,0x1e
    80004436:	97e98993          	addi	s3,s3,-1666 # 80021db0 <log>
    8000443a:	a035                	j	80004466 <install_trans+0x60>
      bunpin(dbuf);
    8000443c:	8526                	mv	a0,s1
    8000443e:	fffff097          	auipc	ra,0xfffff
    80004442:	166080e7          	jalr	358(ra) # 800035a4 <bunpin>
    brelse(lbuf);
    80004446:	854a                	mv	a0,s2
    80004448:	fffff097          	auipc	ra,0xfffff
    8000444c:	082080e7          	jalr	130(ra) # 800034ca <brelse>
    brelse(dbuf);
    80004450:	8526                	mv	a0,s1
    80004452:	fffff097          	auipc	ra,0xfffff
    80004456:	078080e7          	jalr	120(ra) # 800034ca <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000445a:	2a05                	addiw	s4,s4,1
    8000445c:	0a91                	addi	s5,s5,4
    8000445e:	02c9a783          	lw	a5,44(s3)
    80004462:	04fa5963          	bge	s4,a5,800044b4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004466:	0189a583          	lw	a1,24(s3)
    8000446a:	014585bb          	addw	a1,a1,s4
    8000446e:	2585                	addiw	a1,a1,1
    80004470:	0289a503          	lw	a0,40(s3)
    80004474:	fffff097          	auipc	ra,0xfffff
    80004478:	f26080e7          	jalr	-218(ra) # 8000339a <bread>
    8000447c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000447e:	000aa583          	lw	a1,0(s5)
    80004482:	0289a503          	lw	a0,40(s3)
    80004486:	fffff097          	auipc	ra,0xfffff
    8000448a:	f14080e7          	jalr	-236(ra) # 8000339a <bread>
    8000448e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004490:	40000613          	li	a2,1024
    80004494:	05890593          	addi	a1,s2,88
    80004498:	05850513          	addi	a0,a0,88
    8000449c:	ffffd097          	auipc	ra,0xffffd
    800044a0:	8a4080e7          	jalr	-1884(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800044a4:	8526                	mv	a0,s1
    800044a6:	fffff097          	auipc	ra,0xfffff
    800044aa:	fe6080e7          	jalr	-26(ra) # 8000348c <bwrite>
    if(recovering == 0)
    800044ae:	f80b1ce3          	bnez	s6,80004446 <install_trans+0x40>
    800044b2:	b769                	j	8000443c <install_trans+0x36>
}
    800044b4:	70e2                	ld	ra,56(sp)
    800044b6:	7442                	ld	s0,48(sp)
    800044b8:	74a2                	ld	s1,40(sp)
    800044ba:	7902                	ld	s2,32(sp)
    800044bc:	69e2                	ld	s3,24(sp)
    800044be:	6a42                	ld	s4,16(sp)
    800044c0:	6aa2                	ld	s5,8(sp)
    800044c2:	6b02                	ld	s6,0(sp)
    800044c4:	6121                	addi	sp,sp,64
    800044c6:	8082                	ret
    800044c8:	8082                	ret

00000000800044ca <initlog>:
{
    800044ca:	7179                	addi	sp,sp,-48
    800044cc:	f406                	sd	ra,40(sp)
    800044ce:	f022                	sd	s0,32(sp)
    800044d0:	ec26                	sd	s1,24(sp)
    800044d2:	e84a                	sd	s2,16(sp)
    800044d4:	e44e                	sd	s3,8(sp)
    800044d6:	1800                	addi	s0,sp,48
    800044d8:	892a                	mv	s2,a0
    800044da:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044dc:	0001e497          	auipc	s1,0x1e
    800044e0:	8d448493          	addi	s1,s1,-1836 # 80021db0 <log>
    800044e4:	00004597          	auipc	a1,0x4
    800044e8:	1c458593          	addi	a1,a1,452 # 800086a8 <syscalls+0x1d8>
    800044ec:	8526                	mv	a0,s1
    800044ee:	ffffc097          	auipc	ra,0xffffc
    800044f2:	666080e7          	jalr	1638(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800044f6:	0149a583          	lw	a1,20(s3)
    800044fa:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800044fc:	0109a783          	lw	a5,16(s3)
    80004500:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004502:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004506:	854a                	mv	a0,s2
    80004508:	fffff097          	auipc	ra,0xfffff
    8000450c:	e92080e7          	jalr	-366(ra) # 8000339a <bread>
  log.lh.n = lh->n;
    80004510:	4d3c                	lw	a5,88(a0)
    80004512:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004514:	02f05563          	blez	a5,8000453e <initlog+0x74>
    80004518:	05c50713          	addi	a4,a0,92
    8000451c:	0001e697          	auipc	a3,0x1e
    80004520:	8c468693          	addi	a3,a3,-1852 # 80021de0 <log+0x30>
    80004524:	37fd                	addiw	a5,a5,-1
    80004526:	1782                	slli	a5,a5,0x20
    80004528:	9381                	srli	a5,a5,0x20
    8000452a:	078a                	slli	a5,a5,0x2
    8000452c:	06050613          	addi	a2,a0,96
    80004530:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004532:	4310                	lw	a2,0(a4)
    80004534:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004536:	0711                	addi	a4,a4,4
    80004538:	0691                	addi	a3,a3,4
    8000453a:	fef71ce3          	bne	a4,a5,80004532 <initlog+0x68>
  brelse(buf);
    8000453e:	fffff097          	auipc	ra,0xfffff
    80004542:	f8c080e7          	jalr	-116(ra) # 800034ca <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004546:	4505                	li	a0,1
    80004548:	00000097          	auipc	ra,0x0
    8000454c:	ebe080e7          	jalr	-322(ra) # 80004406 <install_trans>
  log.lh.n = 0;
    80004550:	0001e797          	auipc	a5,0x1e
    80004554:	8807a623          	sw	zero,-1908(a5) # 80021ddc <log+0x2c>
  write_head(); // clear the log
    80004558:	00000097          	auipc	ra,0x0
    8000455c:	e34080e7          	jalr	-460(ra) # 8000438c <write_head>
}
    80004560:	70a2                	ld	ra,40(sp)
    80004562:	7402                	ld	s0,32(sp)
    80004564:	64e2                	ld	s1,24(sp)
    80004566:	6942                	ld	s2,16(sp)
    80004568:	69a2                	ld	s3,8(sp)
    8000456a:	6145                	addi	sp,sp,48
    8000456c:	8082                	ret

000000008000456e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000456e:	1101                	addi	sp,sp,-32
    80004570:	ec06                	sd	ra,24(sp)
    80004572:	e822                	sd	s0,16(sp)
    80004574:	e426                	sd	s1,8(sp)
    80004576:	e04a                	sd	s2,0(sp)
    80004578:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000457a:	0001e517          	auipc	a0,0x1e
    8000457e:	83650513          	addi	a0,a0,-1994 # 80021db0 <log>
    80004582:	ffffc097          	auipc	ra,0xffffc
    80004586:	662080e7          	jalr	1634(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000458a:	0001e497          	auipc	s1,0x1e
    8000458e:	82648493          	addi	s1,s1,-2010 # 80021db0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004592:	4979                	li	s2,30
    80004594:	a039                	j	800045a2 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004596:	85a6                	mv	a1,s1
    80004598:	8526                	mv	a0,s1
    8000459a:	ffffe097          	auipc	ra,0xffffe
    8000459e:	f42080e7          	jalr	-190(ra) # 800024dc <sleep>
    if(log.committing){
    800045a2:	50dc                	lw	a5,36(s1)
    800045a4:	fbed                	bnez	a5,80004596 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045a6:	509c                	lw	a5,32(s1)
    800045a8:	0017871b          	addiw	a4,a5,1
    800045ac:	0007069b          	sext.w	a3,a4
    800045b0:	0027179b          	slliw	a5,a4,0x2
    800045b4:	9fb9                	addw	a5,a5,a4
    800045b6:	0017979b          	slliw	a5,a5,0x1
    800045ba:	54d8                	lw	a4,44(s1)
    800045bc:	9fb9                	addw	a5,a5,a4
    800045be:	00f95963          	bge	s2,a5,800045d0 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045c2:	85a6                	mv	a1,s1
    800045c4:	8526                	mv	a0,s1
    800045c6:	ffffe097          	auipc	ra,0xffffe
    800045ca:	f16080e7          	jalr	-234(ra) # 800024dc <sleep>
    800045ce:	bfd1                	j	800045a2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045d0:	0001d517          	auipc	a0,0x1d
    800045d4:	7e050513          	addi	a0,a0,2016 # 80021db0 <log>
    800045d8:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800045da:	ffffc097          	auipc	ra,0xffffc
    800045de:	6be080e7          	jalr	1726(ra) # 80000c98 <release>
      break;
    }
  }
}
    800045e2:	60e2                	ld	ra,24(sp)
    800045e4:	6442                	ld	s0,16(sp)
    800045e6:	64a2                	ld	s1,8(sp)
    800045e8:	6902                	ld	s2,0(sp)
    800045ea:	6105                	addi	sp,sp,32
    800045ec:	8082                	ret

00000000800045ee <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045ee:	7139                	addi	sp,sp,-64
    800045f0:	fc06                	sd	ra,56(sp)
    800045f2:	f822                	sd	s0,48(sp)
    800045f4:	f426                	sd	s1,40(sp)
    800045f6:	f04a                	sd	s2,32(sp)
    800045f8:	ec4e                	sd	s3,24(sp)
    800045fa:	e852                	sd	s4,16(sp)
    800045fc:	e456                	sd	s5,8(sp)
    800045fe:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004600:	0001d497          	auipc	s1,0x1d
    80004604:	7b048493          	addi	s1,s1,1968 # 80021db0 <log>
    80004608:	8526                	mv	a0,s1
    8000460a:	ffffc097          	auipc	ra,0xffffc
    8000460e:	5da080e7          	jalr	1498(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004612:	509c                	lw	a5,32(s1)
    80004614:	37fd                	addiw	a5,a5,-1
    80004616:	0007891b          	sext.w	s2,a5
    8000461a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000461c:	50dc                	lw	a5,36(s1)
    8000461e:	efb9                	bnez	a5,8000467c <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004620:	06091663          	bnez	s2,8000468c <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004624:	0001d497          	auipc	s1,0x1d
    80004628:	78c48493          	addi	s1,s1,1932 # 80021db0 <log>
    8000462c:	4785                	li	a5,1
    8000462e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004630:	8526                	mv	a0,s1
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	666080e7          	jalr	1638(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000463a:	54dc                	lw	a5,44(s1)
    8000463c:	06f04763          	bgtz	a5,800046aa <end_op+0xbc>
    acquire(&log.lock);
    80004640:	0001d497          	auipc	s1,0x1d
    80004644:	77048493          	addi	s1,s1,1904 # 80021db0 <log>
    80004648:	8526                	mv	a0,s1
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	59a080e7          	jalr	1434(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004652:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004656:	8526                	mv	a0,s1
    80004658:	ffffe097          	auipc	ra,0xffffe
    8000465c:	022080e7          	jalr	34(ra) # 8000267a <wakeup>
    release(&log.lock);
    80004660:	8526                	mv	a0,s1
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	636080e7          	jalr	1590(ra) # 80000c98 <release>
}
    8000466a:	70e2                	ld	ra,56(sp)
    8000466c:	7442                	ld	s0,48(sp)
    8000466e:	74a2                	ld	s1,40(sp)
    80004670:	7902                	ld	s2,32(sp)
    80004672:	69e2                	ld	s3,24(sp)
    80004674:	6a42                	ld	s4,16(sp)
    80004676:	6aa2                	ld	s5,8(sp)
    80004678:	6121                	addi	sp,sp,64
    8000467a:	8082                	ret
    panic("log.committing");
    8000467c:	00004517          	auipc	a0,0x4
    80004680:	03450513          	addi	a0,a0,52 # 800086b0 <syscalls+0x1e0>
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	eba080e7          	jalr	-326(ra) # 8000053e <panic>
    wakeup(&log);
    8000468c:	0001d497          	auipc	s1,0x1d
    80004690:	72448493          	addi	s1,s1,1828 # 80021db0 <log>
    80004694:	8526                	mv	a0,s1
    80004696:	ffffe097          	auipc	ra,0xffffe
    8000469a:	fe4080e7          	jalr	-28(ra) # 8000267a <wakeup>
  release(&log.lock);
    8000469e:	8526                	mv	a0,s1
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	5f8080e7          	jalr	1528(ra) # 80000c98 <release>
  if(do_commit){
    800046a8:	b7c9                	j	8000466a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046aa:	0001da97          	auipc	s5,0x1d
    800046ae:	736a8a93          	addi	s5,s5,1846 # 80021de0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800046b2:	0001da17          	auipc	s4,0x1d
    800046b6:	6fea0a13          	addi	s4,s4,1790 # 80021db0 <log>
    800046ba:	018a2583          	lw	a1,24(s4)
    800046be:	012585bb          	addw	a1,a1,s2
    800046c2:	2585                	addiw	a1,a1,1
    800046c4:	028a2503          	lw	a0,40(s4)
    800046c8:	fffff097          	auipc	ra,0xfffff
    800046cc:	cd2080e7          	jalr	-814(ra) # 8000339a <bread>
    800046d0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046d2:	000aa583          	lw	a1,0(s5)
    800046d6:	028a2503          	lw	a0,40(s4)
    800046da:	fffff097          	auipc	ra,0xfffff
    800046de:	cc0080e7          	jalr	-832(ra) # 8000339a <bread>
    800046e2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046e4:	40000613          	li	a2,1024
    800046e8:	05850593          	addi	a1,a0,88
    800046ec:	05848513          	addi	a0,s1,88
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	650080e7          	jalr	1616(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800046f8:	8526                	mv	a0,s1
    800046fa:	fffff097          	auipc	ra,0xfffff
    800046fe:	d92080e7          	jalr	-622(ra) # 8000348c <bwrite>
    brelse(from);
    80004702:	854e                	mv	a0,s3
    80004704:	fffff097          	auipc	ra,0xfffff
    80004708:	dc6080e7          	jalr	-570(ra) # 800034ca <brelse>
    brelse(to);
    8000470c:	8526                	mv	a0,s1
    8000470e:	fffff097          	auipc	ra,0xfffff
    80004712:	dbc080e7          	jalr	-580(ra) # 800034ca <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004716:	2905                	addiw	s2,s2,1
    80004718:	0a91                	addi	s5,s5,4
    8000471a:	02ca2783          	lw	a5,44(s4)
    8000471e:	f8f94ee3          	blt	s2,a5,800046ba <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004722:	00000097          	auipc	ra,0x0
    80004726:	c6a080e7          	jalr	-918(ra) # 8000438c <write_head>
    install_trans(0); // Now install writes to home locations
    8000472a:	4501                	li	a0,0
    8000472c:	00000097          	auipc	ra,0x0
    80004730:	cda080e7          	jalr	-806(ra) # 80004406 <install_trans>
    log.lh.n = 0;
    80004734:	0001d797          	auipc	a5,0x1d
    80004738:	6a07a423          	sw	zero,1704(a5) # 80021ddc <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000473c:	00000097          	auipc	ra,0x0
    80004740:	c50080e7          	jalr	-944(ra) # 8000438c <write_head>
    80004744:	bdf5                	j	80004640 <end_op+0x52>

0000000080004746 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004746:	1101                	addi	sp,sp,-32
    80004748:	ec06                	sd	ra,24(sp)
    8000474a:	e822                	sd	s0,16(sp)
    8000474c:	e426                	sd	s1,8(sp)
    8000474e:	e04a                	sd	s2,0(sp)
    80004750:	1000                	addi	s0,sp,32
    80004752:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004754:	0001d917          	auipc	s2,0x1d
    80004758:	65c90913          	addi	s2,s2,1628 # 80021db0 <log>
    8000475c:	854a                	mv	a0,s2
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	486080e7          	jalr	1158(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004766:	02c92603          	lw	a2,44(s2)
    8000476a:	47f5                	li	a5,29
    8000476c:	06c7c563          	blt	a5,a2,800047d6 <log_write+0x90>
    80004770:	0001d797          	auipc	a5,0x1d
    80004774:	65c7a783          	lw	a5,1628(a5) # 80021dcc <log+0x1c>
    80004778:	37fd                	addiw	a5,a5,-1
    8000477a:	04f65e63          	bge	a2,a5,800047d6 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000477e:	0001d797          	auipc	a5,0x1d
    80004782:	6527a783          	lw	a5,1618(a5) # 80021dd0 <log+0x20>
    80004786:	06f05063          	blez	a5,800047e6 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000478a:	4781                	li	a5,0
    8000478c:	06c05563          	blez	a2,800047f6 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004790:	44cc                	lw	a1,12(s1)
    80004792:	0001d717          	auipc	a4,0x1d
    80004796:	64e70713          	addi	a4,a4,1614 # 80021de0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000479a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000479c:	4314                	lw	a3,0(a4)
    8000479e:	04b68c63          	beq	a3,a1,800047f6 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800047a2:	2785                	addiw	a5,a5,1
    800047a4:	0711                	addi	a4,a4,4
    800047a6:	fef61be3          	bne	a2,a5,8000479c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800047aa:	0621                	addi	a2,a2,8
    800047ac:	060a                	slli	a2,a2,0x2
    800047ae:	0001d797          	auipc	a5,0x1d
    800047b2:	60278793          	addi	a5,a5,1538 # 80021db0 <log>
    800047b6:	963e                	add	a2,a2,a5
    800047b8:	44dc                	lw	a5,12(s1)
    800047ba:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800047bc:	8526                	mv	a0,s1
    800047be:	fffff097          	auipc	ra,0xfffff
    800047c2:	daa080e7          	jalr	-598(ra) # 80003568 <bpin>
    log.lh.n++;
    800047c6:	0001d717          	auipc	a4,0x1d
    800047ca:	5ea70713          	addi	a4,a4,1514 # 80021db0 <log>
    800047ce:	575c                	lw	a5,44(a4)
    800047d0:	2785                	addiw	a5,a5,1
    800047d2:	d75c                	sw	a5,44(a4)
    800047d4:	a835                	j	80004810 <log_write+0xca>
    panic("too big a transaction");
    800047d6:	00004517          	auipc	a0,0x4
    800047da:	eea50513          	addi	a0,a0,-278 # 800086c0 <syscalls+0x1f0>
    800047de:	ffffc097          	auipc	ra,0xffffc
    800047e2:	d60080e7          	jalr	-672(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800047e6:	00004517          	auipc	a0,0x4
    800047ea:	ef250513          	addi	a0,a0,-270 # 800086d8 <syscalls+0x208>
    800047ee:	ffffc097          	auipc	ra,0xffffc
    800047f2:	d50080e7          	jalr	-688(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800047f6:	00878713          	addi	a4,a5,8
    800047fa:	00271693          	slli	a3,a4,0x2
    800047fe:	0001d717          	auipc	a4,0x1d
    80004802:	5b270713          	addi	a4,a4,1458 # 80021db0 <log>
    80004806:	9736                	add	a4,a4,a3
    80004808:	44d4                	lw	a3,12(s1)
    8000480a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000480c:	faf608e3          	beq	a2,a5,800047bc <log_write+0x76>
  }
  release(&log.lock);
    80004810:	0001d517          	auipc	a0,0x1d
    80004814:	5a050513          	addi	a0,a0,1440 # 80021db0 <log>
    80004818:	ffffc097          	auipc	ra,0xffffc
    8000481c:	480080e7          	jalr	1152(ra) # 80000c98 <release>
}
    80004820:	60e2                	ld	ra,24(sp)
    80004822:	6442                	ld	s0,16(sp)
    80004824:	64a2                	ld	s1,8(sp)
    80004826:	6902                	ld	s2,0(sp)
    80004828:	6105                	addi	sp,sp,32
    8000482a:	8082                	ret

000000008000482c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000482c:	1101                	addi	sp,sp,-32
    8000482e:	ec06                	sd	ra,24(sp)
    80004830:	e822                	sd	s0,16(sp)
    80004832:	e426                	sd	s1,8(sp)
    80004834:	e04a                	sd	s2,0(sp)
    80004836:	1000                	addi	s0,sp,32
    80004838:	84aa                	mv	s1,a0
    8000483a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000483c:	00004597          	auipc	a1,0x4
    80004840:	ebc58593          	addi	a1,a1,-324 # 800086f8 <syscalls+0x228>
    80004844:	0521                	addi	a0,a0,8
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	30e080e7          	jalr	782(ra) # 80000b54 <initlock>
  lk->name = name;
    8000484e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004852:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004856:	0204a423          	sw	zero,40(s1)
}
    8000485a:	60e2                	ld	ra,24(sp)
    8000485c:	6442                	ld	s0,16(sp)
    8000485e:	64a2                	ld	s1,8(sp)
    80004860:	6902                	ld	s2,0(sp)
    80004862:	6105                	addi	sp,sp,32
    80004864:	8082                	ret

0000000080004866 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004866:	1101                	addi	sp,sp,-32
    80004868:	ec06                	sd	ra,24(sp)
    8000486a:	e822                	sd	s0,16(sp)
    8000486c:	e426                	sd	s1,8(sp)
    8000486e:	e04a                	sd	s2,0(sp)
    80004870:	1000                	addi	s0,sp,32
    80004872:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004874:	00850913          	addi	s2,a0,8
    80004878:	854a                	mv	a0,s2
    8000487a:	ffffc097          	auipc	ra,0xffffc
    8000487e:	36a080e7          	jalr	874(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004882:	409c                	lw	a5,0(s1)
    80004884:	cb89                	beqz	a5,80004896 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004886:	85ca                	mv	a1,s2
    80004888:	8526                	mv	a0,s1
    8000488a:	ffffe097          	auipc	ra,0xffffe
    8000488e:	c52080e7          	jalr	-942(ra) # 800024dc <sleep>
  while (lk->locked) {
    80004892:	409c                	lw	a5,0(s1)
    80004894:	fbed                	bnez	a5,80004886 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004896:	4785                	li	a5,1
    80004898:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000489a:	ffffd097          	auipc	ra,0xffffd
    8000489e:	432080e7          	jalr	1074(ra) # 80001ccc <myproc>
    800048a2:	591c                	lw	a5,48(a0)
    800048a4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800048a6:	854a                	mv	a0,s2
    800048a8:	ffffc097          	auipc	ra,0xffffc
    800048ac:	3f0080e7          	jalr	1008(ra) # 80000c98 <release>
}
    800048b0:	60e2                	ld	ra,24(sp)
    800048b2:	6442                	ld	s0,16(sp)
    800048b4:	64a2                	ld	s1,8(sp)
    800048b6:	6902                	ld	s2,0(sp)
    800048b8:	6105                	addi	sp,sp,32
    800048ba:	8082                	ret

00000000800048bc <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800048bc:	1101                	addi	sp,sp,-32
    800048be:	ec06                	sd	ra,24(sp)
    800048c0:	e822                	sd	s0,16(sp)
    800048c2:	e426                	sd	s1,8(sp)
    800048c4:	e04a                	sd	s2,0(sp)
    800048c6:	1000                	addi	s0,sp,32
    800048c8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048ca:	00850913          	addi	s2,a0,8
    800048ce:	854a                	mv	a0,s2
    800048d0:	ffffc097          	auipc	ra,0xffffc
    800048d4:	314080e7          	jalr	788(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800048d8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048dc:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800048e0:	8526                	mv	a0,s1
    800048e2:	ffffe097          	auipc	ra,0xffffe
    800048e6:	d98080e7          	jalr	-616(ra) # 8000267a <wakeup>
  release(&lk->lk);
    800048ea:	854a                	mv	a0,s2
    800048ec:	ffffc097          	auipc	ra,0xffffc
    800048f0:	3ac080e7          	jalr	940(ra) # 80000c98 <release>
}
    800048f4:	60e2                	ld	ra,24(sp)
    800048f6:	6442                	ld	s0,16(sp)
    800048f8:	64a2                	ld	s1,8(sp)
    800048fa:	6902                	ld	s2,0(sp)
    800048fc:	6105                	addi	sp,sp,32
    800048fe:	8082                	ret

0000000080004900 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004900:	7179                	addi	sp,sp,-48
    80004902:	f406                	sd	ra,40(sp)
    80004904:	f022                	sd	s0,32(sp)
    80004906:	ec26                	sd	s1,24(sp)
    80004908:	e84a                	sd	s2,16(sp)
    8000490a:	e44e                	sd	s3,8(sp)
    8000490c:	1800                	addi	s0,sp,48
    8000490e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004910:	00850913          	addi	s2,a0,8
    80004914:	854a                	mv	a0,s2
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	2ce080e7          	jalr	718(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000491e:	409c                	lw	a5,0(s1)
    80004920:	ef99                	bnez	a5,8000493e <holdingsleep+0x3e>
    80004922:	4481                	li	s1,0
  release(&lk->lk);
    80004924:	854a                	mv	a0,s2
    80004926:	ffffc097          	auipc	ra,0xffffc
    8000492a:	372080e7          	jalr	882(ra) # 80000c98 <release>
  return r;
}
    8000492e:	8526                	mv	a0,s1
    80004930:	70a2                	ld	ra,40(sp)
    80004932:	7402                	ld	s0,32(sp)
    80004934:	64e2                	ld	s1,24(sp)
    80004936:	6942                	ld	s2,16(sp)
    80004938:	69a2                	ld	s3,8(sp)
    8000493a:	6145                	addi	sp,sp,48
    8000493c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000493e:	0284a983          	lw	s3,40(s1)
    80004942:	ffffd097          	auipc	ra,0xffffd
    80004946:	38a080e7          	jalr	906(ra) # 80001ccc <myproc>
    8000494a:	5904                	lw	s1,48(a0)
    8000494c:	413484b3          	sub	s1,s1,s3
    80004950:	0014b493          	seqz	s1,s1
    80004954:	bfc1                	j	80004924 <holdingsleep+0x24>

0000000080004956 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004956:	1141                	addi	sp,sp,-16
    80004958:	e406                	sd	ra,8(sp)
    8000495a:	e022                	sd	s0,0(sp)
    8000495c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000495e:	00004597          	auipc	a1,0x4
    80004962:	daa58593          	addi	a1,a1,-598 # 80008708 <syscalls+0x238>
    80004966:	0001d517          	auipc	a0,0x1d
    8000496a:	59250513          	addi	a0,a0,1426 # 80021ef8 <ftable>
    8000496e:	ffffc097          	auipc	ra,0xffffc
    80004972:	1e6080e7          	jalr	486(ra) # 80000b54 <initlock>
}
    80004976:	60a2                	ld	ra,8(sp)
    80004978:	6402                	ld	s0,0(sp)
    8000497a:	0141                	addi	sp,sp,16
    8000497c:	8082                	ret

000000008000497e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000497e:	1101                	addi	sp,sp,-32
    80004980:	ec06                	sd	ra,24(sp)
    80004982:	e822                	sd	s0,16(sp)
    80004984:	e426                	sd	s1,8(sp)
    80004986:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004988:	0001d517          	auipc	a0,0x1d
    8000498c:	57050513          	addi	a0,a0,1392 # 80021ef8 <ftable>
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	254080e7          	jalr	596(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004998:	0001d497          	auipc	s1,0x1d
    8000499c:	57848493          	addi	s1,s1,1400 # 80021f10 <ftable+0x18>
    800049a0:	0001e717          	auipc	a4,0x1e
    800049a4:	51070713          	addi	a4,a4,1296 # 80022eb0 <ftable+0xfb8>
    if(f->ref == 0){
    800049a8:	40dc                	lw	a5,4(s1)
    800049aa:	cf99                	beqz	a5,800049c8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049ac:	02848493          	addi	s1,s1,40
    800049b0:	fee49ce3          	bne	s1,a4,800049a8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800049b4:	0001d517          	auipc	a0,0x1d
    800049b8:	54450513          	addi	a0,a0,1348 # 80021ef8 <ftable>
    800049bc:	ffffc097          	auipc	ra,0xffffc
    800049c0:	2dc080e7          	jalr	732(ra) # 80000c98 <release>
  return 0;
    800049c4:	4481                	li	s1,0
    800049c6:	a819                	j	800049dc <filealloc+0x5e>
      f->ref = 1;
    800049c8:	4785                	li	a5,1
    800049ca:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049cc:	0001d517          	auipc	a0,0x1d
    800049d0:	52c50513          	addi	a0,a0,1324 # 80021ef8 <ftable>
    800049d4:	ffffc097          	auipc	ra,0xffffc
    800049d8:	2c4080e7          	jalr	708(ra) # 80000c98 <release>
}
    800049dc:	8526                	mv	a0,s1
    800049de:	60e2                	ld	ra,24(sp)
    800049e0:	6442                	ld	s0,16(sp)
    800049e2:	64a2                	ld	s1,8(sp)
    800049e4:	6105                	addi	sp,sp,32
    800049e6:	8082                	ret

00000000800049e8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049e8:	1101                	addi	sp,sp,-32
    800049ea:	ec06                	sd	ra,24(sp)
    800049ec:	e822                	sd	s0,16(sp)
    800049ee:	e426                	sd	s1,8(sp)
    800049f0:	1000                	addi	s0,sp,32
    800049f2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049f4:	0001d517          	auipc	a0,0x1d
    800049f8:	50450513          	addi	a0,a0,1284 # 80021ef8 <ftable>
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	1e8080e7          	jalr	488(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a04:	40dc                	lw	a5,4(s1)
    80004a06:	02f05263          	blez	a5,80004a2a <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a0a:	2785                	addiw	a5,a5,1
    80004a0c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a0e:	0001d517          	auipc	a0,0x1d
    80004a12:	4ea50513          	addi	a0,a0,1258 # 80021ef8 <ftable>
    80004a16:	ffffc097          	auipc	ra,0xffffc
    80004a1a:	282080e7          	jalr	642(ra) # 80000c98 <release>
  return f;
}
    80004a1e:	8526                	mv	a0,s1
    80004a20:	60e2                	ld	ra,24(sp)
    80004a22:	6442                	ld	s0,16(sp)
    80004a24:	64a2                	ld	s1,8(sp)
    80004a26:	6105                	addi	sp,sp,32
    80004a28:	8082                	ret
    panic("filedup");
    80004a2a:	00004517          	auipc	a0,0x4
    80004a2e:	ce650513          	addi	a0,a0,-794 # 80008710 <syscalls+0x240>
    80004a32:	ffffc097          	auipc	ra,0xffffc
    80004a36:	b0c080e7          	jalr	-1268(ra) # 8000053e <panic>

0000000080004a3a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a3a:	7139                	addi	sp,sp,-64
    80004a3c:	fc06                	sd	ra,56(sp)
    80004a3e:	f822                	sd	s0,48(sp)
    80004a40:	f426                	sd	s1,40(sp)
    80004a42:	f04a                	sd	s2,32(sp)
    80004a44:	ec4e                	sd	s3,24(sp)
    80004a46:	e852                	sd	s4,16(sp)
    80004a48:	e456                	sd	s5,8(sp)
    80004a4a:	0080                	addi	s0,sp,64
    80004a4c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a4e:	0001d517          	auipc	a0,0x1d
    80004a52:	4aa50513          	addi	a0,a0,1194 # 80021ef8 <ftable>
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	18e080e7          	jalr	398(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a5e:	40dc                	lw	a5,4(s1)
    80004a60:	06f05163          	blez	a5,80004ac2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a64:	37fd                	addiw	a5,a5,-1
    80004a66:	0007871b          	sext.w	a4,a5
    80004a6a:	c0dc                	sw	a5,4(s1)
    80004a6c:	06e04363          	bgtz	a4,80004ad2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a70:	0004a903          	lw	s2,0(s1)
    80004a74:	0094ca83          	lbu	s5,9(s1)
    80004a78:	0104ba03          	ld	s4,16(s1)
    80004a7c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a80:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a84:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a88:	0001d517          	auipc	a0,0x1d
    80004a8c:	47050513          	addi	a0,a0,1136 # 80021ef8 <ftable>
    80004a90:	ffffc097          	auipc	ra,0xffffc
    80004a94:	208080e7          	jalr	520(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004a98:	4785                	li	a5,1
    80004a9a:	04f90d63          	beq	s2,a5,80004af4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a9e:	3979                	addiw	s2,s2,-2
    80004aa0:	4785                	li	a5,1
    80004aa2:	0527e063          	bltu	a5,s2,80004ae2 <fileclose+0xa8>
    begin_op();
    80004aa6:	00000097          	auipc	ra,0x0
    80004aaa:	ac8080e7          	jalr	-1336(ra) # 8000456e <begin_op>
    iput(ff.ip);
    80004aae:	854e                	mv	a0,s3
    80004ab0:	fffff097          	auipc	ra,0xfffff
    80004ab4:	2a6080e7          	jalr	678(ra) # 80003d56 <iput>
    end_op();
    80004ab8:	00000097          	auipc	ra,0x0
    80004abc:	b36080e7          	jalr	-1226(ra) # 800045ee <end_op>
    80004ac0:	a00d                	j	80004ae2 <fileclose+0xa8>
    panic("fileclose");
    80004ac2:	00004517          	auipc	a0,0x4
    80004ac6:	c5650513          	addi	a0,a0,-938 # 80008718 <syscalls+0x248>
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	a74080e7          	jalr	-1420(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004ad2:	0001d517          	auipc	a0,0x1d
    80004ad6:	42650513          	addi	a0,a0,1062 # 80021ef8 <ftable>
    80004ada:	ffffc097          	auipc	ra,0xffffc
    80004ade:	1be080e7          	jalr	446(ra) # 80000c98 <release>
  }
}
    80004ae2:	70e2                	ld	ra,56(sp)
    80004ae4:	7442                	ld	s0,48(sp)
    80004ae6:	74a2                	ld	s1,40(sp)
    80004ae8:	7902                	ld	s2,32(sp)
    80004aea:	69e2                	ld	s3,24(sp)
    80004aec:	6a42                	ld	s4,16(sp)
    80004aee:	6aa2                	ld	s5,8(sp)
    80004af0:	6121                	addi	sp,sp,64
    80004af2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004af4:	85d6                	mv	a1,s5
    80004af6:	8552                	mv	a0,s4
    80004af8:	00000097          	auipc	ra,0x0
    80004afc:	34c080e7          	jalr	844(ra) # 80004e44 <pipeclose>
    80004b00:	b7cd                	j	80004ae2 <fileclose+0xa8>

0000000080004b02 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b02:	715d                	addi	sp,sp,-80
    80004b04:	e486                	sd	ra,72(sp)
    80004b06:	e0a2                	sd	s0,64(sp)
    80004b08:	fc26                	sd	s1,56(sp)
    80004b0a:	f84a                	sd	s2,48(sp)
    80004b0c:	f44e                	sd	s3,40(sp)
    80004b0e:	0880                	addi	s0,sp,80
    80004b10:	84aa                	mv	s1,a0
    80004b12:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b14:	ffffd097          	auipc	ra,0xffffd
    80004b18:	1b8080e7          	jalr	440(ra) # 80001ccc <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b1c:	409c                	lw	a5,0(s1)
    80004b1e:	37f9                	addiw	a5,a5,-2
    80004b20:	4705                	li	a4,1
    80004b22:	04f76763          	bltu	a4,a5,80004b70 <filestat+0x6e>
    80004b26:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b28:	6c88                	ld	a0,24(s1)
    80004b2a:	fffff097          	auipc	ra,0xfffff
    80004b2e:	072080e7          	jalr	114(ra) # 80003b9c <ilock>
    stati(f->ip, &st);
    80004b32:	fb840593          	addi	a1,s0,-72
    80004b36:	6c88                	ld	a0,24(s1)
    80004b38:	fffff097          	auipc	ra,0xfffff
    80004b3c:	2ee080e7          	jalr	750(ra) # 80003e26 <stati>
    iunlock(f->ip);
    80004b40:	6c88                	ld	a0,24(s1)
    80004b42:	fffff097          	auipc	ra,0xfffff
    80004b46:	11c080e7          	jalr	284(ra) # 80003c5e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b4a:	46e1                	li	a3,24
    80004b4c:	fb840613          	addi	a2,s0,-72
    80004b50:	85ce                	mv	a1,s3
    80004b52:	05093503          	ld	a0,80(s2)
    80004b56:	ffffd097          	auipc	ra,0xffffd
    80004b5a:	b1c080e7          	jalr	-1252(ra) # 80001672 <copyout>
    80004b5e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b62:	60a6                	ld	ra,72(sp)
    80004b64:	6406                	ld	s0,64(sp)
    80004b66:	74e2                	ld	s1,56(sp)
    80004b68:	7942                	ld	s2,48(sp)
    80004b6a:	79a2                	ld	s3,40(sp)
    80004b6c:	6161                	addi	sp,sp,80
    80004b6e:	8082                	ret
  return -1;
    80004b70:	557d                	li	a0,-1
    80004b72:	bfc5                	j	80004b62 <filestat+0x60>

0000000080004b74 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b74:	7179                	addi	sp,sp,-48
    80004b76:	f406                	sd	ra,40(sp)
    80004b78:	f022                	sd	s0,32(sp)
    80004b7a:	ec26                	sd	s1,24(sp)
    80004b7c:	e84a                	sd	s2,16(sp)
    80004b7e:	e44e                	sd	s3,8(sp)
    80004b80:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b82:	00854783          	lbu	a5,8(a0)
    80004b86:	c3d5                	beqz	a5,80004c2a <fileread+0xb6>
    80004b88:	84aa                	mv	s1,a0
    80004b8a:	89ae                	mv	s3,a1
    80004b8c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b8e:	411c                	lw	a5,0(a0)
    80004b90:	4705                	li	a4,1
    80004b92:	04e78963          	beq	a5,a4,80004be4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b96:	470d                	li	a4,3
    80004b98:	04e78d63          	beq	a5,a4,80004bf2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b9c:	4709                	li	a4,2
    80004b9e:	06e79e63          	bne	a5,a4,80004c1a <fileread+0xa6>
    ilock(f->ip);
    80004ba2:	6d08                	ld	a0,24(a0)
    80004ba4:	fffff097          	auipc	ra,0xfffff
    80004ba8:	ff8080e7          	jalr	-8(ra) # 80003b9c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004bac:	874a                	mv	a4,s2
    80004bae:	5094                	lw	a3,32(s1)
    80004bb0:	864e                	mv	a2,s3
    80004bb2:	4585                	li	a1,1
    80004bb4:	6c88                	ld	a0,24(s1)
    80004bb6:	fffff097          	auipc	ra,0xfffff
    80004bba:	29a080e7          	jalr	666(ra) # 80003e50 <readi>
    80004bbe:	892a                	mv	s2,a0
    80004bc0:	00a05563          	blez	a0,80004bca <fileread+0x56>
      f->off += r;
    80004bc4:	509c                	lw	a5,32(s1)
    80004bc6:	9fa9                	addw	a5,a5,a0
    80004bc8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004bca:	6c88                	ld	a0,24(s1)
    80004bcc:	fffff097          	auipc	ra,0xfffff
    80004bd0:	092080e7          	jalr	146(ra) # 80003c5e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004bd4:	854a                	mv	a0,s2
    80004bd6:	70a2                	ld	ra,40(sp)
    80004bd8:	7402                	ld	s0,32(sp)
    80004bda:	64e2                	ld	s1,24(sp)
    80004bdc:	6942                	ld	s2,16(sp)
    80004bde:	69a2                	ld	s3,8(sp)
    80004be0:	6145                	addi	sp,sp,48
    80004be2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004be4:	6908                	ld	a0,16(a0)
    80004be6:	00000097          	auipc	ra,0x0
    80004bea:	3c8080e7          	jalr	968(ra) # 80004fae <piperead>
    80004bee:	892a                	mv	s2,a0
    80004bf0:	b7d5                	j	80004bd4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004bf2:	02451783          	lh	a5,36(a0)
    80004bf6:	03079693          	slli	a3,a5,0x30
    80004bfa:	92c1                	srli	a3,a3,0x30
    80004bfc:	4725                	li	a4,9
    80004bfe:	02d76863          	bltu	a4,a3,80004c2e <fileread+0xba>
    80004c02:	0792                	slli	a5,a5,0x4
    80004c04:	0001d717          	auipc	a4,0x1d
    80004c08:	25470713          	addi	a4,a4,596 # 80021e58 <devsw>
    80004c0c:	97ba                	add	a5,a5,a4
    80004c0e:	639c                	ld	a5,0(a5)
    80004c10:	c38d                	beqz	a5,80004c32 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c12:	4505                	li	a0,1
    80004c14:	9782                	jalr	a5
    80004c16:	892a                	mv	s2,a0
    80004c18:	bf75                	j	80004bd4 <fileread+0x60>
    panic("fileread");
    80004c1a:	00004517          	auipc	a0,0x4
    80004c1e:	b0e50513          	addi	a0,a0,-1266 # 80008728 <syscalls+0x258>
    80004c22:	ffffc097          	auipc	ra,0xffffc
    80004c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>
    return -1;
    80004c2a:	597d                	li	s2,-1
    80004c2c:	b765                	j	80004bd4 <fileread+0x60>
      return -1;
    80004c2e:	597d                	li	s2,-1
    80004c30:	b755                	j	80004bd4 <fileread+0x60>
    80004c32:	597d                	li	s2,-1
    80004c34:	b745                	j	80004bd4 <fileread+0x60>

0000000080004c36 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c36:	715d                	addi	sp,sp,-80
    80004c38:	e486                	sd	ra,72(sp)
    80004c3a:	e0a2                	sd	s0,64(sp)
    80004c3c:	fc26                	sd	s1,56(sp)
    80004c3e:	f84a                	sd	s2,48(sp)
    80004c40:	f44e                	sd	s3,40(sp)
    80004c42:	f052                	sd	s4,32(sp)
    80004c44:	ec56                	sd	s5,24(sp)
    80004c46:	e85a                	sd	s6,16(sp)
    80004c48:	e45e                	sd	s7,8(sp)
    80004c4a:	e062                	sd	s8,0(sp)
    80004c4c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c4e:	00954783          	lbu	a5,9(a0)
    80004c52:	10078663          	beqz	a5,80004d5e <filewrite+0x128>
    80004c56:	892a                	mv	s2,a0
    80004c58:	8aae                	mv	s5,a1
    80004c5a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c5c:	411c                	lw	a5,0(a0)
    80004c5e:	4705                	li	a4,1
    80004c60:	02e78263          	beq	a5,a4,80004c84 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c64:	470d                	li	a4,3
    80004c66:	02e78663          	beq	a5,a4,80004c92 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c6a:	4709                	li	a4,2
    80004c6c:	0ee79163          	bne	a5,a4,80004d4e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c70:	0ac05d63          	blez	a2,80004d2a <filewrite+0xf4>
    int i = 0;
    80004c74:	4981                	li	s3,0
    80004c76:	6b05                	lui	s6,0x1
    80004c78:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c7c:	6b85                	lui	s7,0x1
    80004c7e:	c00b8b9b          	addiw	s7,s7,-1024
    80004c82:	a861                	j	80004d1a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c84:	6908                	ld	a0,16(a0)
    80004c86:	00000097          	auipc	ra,0x0
    80004c8a:	22e080e7          	jalr	558(ra) # 80004eb4 <pipewrite>
    80004c8e:	8a2a                	mv	s4,a0
    80004c90:	a045                	j	80004d30 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c92:	02451783          	lh	a5,36(a0)
    80004c96:	03079693          	slli	a3,a5,0x30
    80004c9a:	92c1                	srli	a3,a3,0x30
    80004c9c:	4725                	li	a4,9
    80004c9e:	0cd76263          	bltu	a4,a3,80004d62 <filewrite+0x12c>
    80004ca2:	0792                	slli	a5,a5,0x4
    80004ca4:	0001d717          	auipc	a4,0x1d
    80004ca8:	1b470713          	addi	a4,a4,436 # 80021e58 <devsw>
    80004cac:	97ba                	add	a5,a5,a4
    80004cae:	679c                	ld	a5,8(a5)
    80004cb0:	cbdd                	beqz	a5,80004d66 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004cb2:	4505                	li	a0,1
    80004cb4:	9782                	jalr	a5
    80004cb6:	8a2a                	mv	s4,a0
    80004cb8:	a8a5                	j	80004d30 <filewrite+0xfa>
    80004cba:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004cbe:	00000097          	auipc	ra,0x0
    80004cc2:	8b0080e7          	jalr	-1872(ra) # 8000456e <begin_op>
      ilock(f->ip);
    80004cc6:	01893503          	ld	a0,24(s2)
    80004cca:	fffff097          	auipc	ra,0xfffff
    80004cce:	ed2080e7          	jalr	-302(ra) # 80003b9c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004cd2:	8762                	mv	a4,s8
    80004cd4:	02092683          	lw	a3,32(s2)
    80004cd8:	01598633          	add	a2,s3,s5
    80004cdc:	4585                	li	a1,1
    80004cde:	01893503          	ld	a0,24(s2)
    80004ce2:	fffff097          	auipc	ra,0xfffff
    80004ce6:	266080e7          	jalr	614(ra) # 80003f48 <writei>
    80004cea:	84aa                	mv	s1,a0
    80004cec:	00a05763          	blez	a0,80004cfa <filewrite+0xc4>
        f->off += r;
    80004cf0:	02092783          	lw	a5,32(s2)
    80004cf4:	9fa9                	addw	a5,a5,a0
    80004cf6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cfa:	01893503          	ld	a0,24(s2)
    80004cfe:	fffff097          	auipc	ra,0xfffff
    80004d02:	f60080e7          	jalr	-160(ra) # 80003c5e <iunlock>
      end_op();
    80004d06:	00000097          	auipc	ra,0x0
    80004d0a:	8e8080e7          	jalr	-1816(ra) # 800045ee <end_op>

      if(r != n1){
    80004d0e:	009c1f63          	bne	s8,s1,80004d2c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d12:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d16:	0149db63          	bge	s3,s4,80004d2c <filewrite+0xf6>
      int n1 = n - i;
    80004d1a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d1e:	84be                	mv	s1,a5
    80004d20:	2781                	sext.w	a5,a5
    80004d22:	f8fb5ce3          	bge	s6,a5,80004cba <filewrite+0x84>
    80004d26:	84de                	mv	s1,s7
    80004d28:	bf49                	j	80004cba <filewrite+0x84>
    int i = 0;
    80004d2a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d2c:	013a1f63          	bne	s4,s3,80004d4a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d30:	8552                	mv	a0,s4
    80004d32:	60a6                	ld	ra,72(sp)
    80004d34:	6406                	ld	s0,64(sp)
    80004d36:	74e2                	ld	s1,56(sp)
    80004d38:	7942                	ld	s2,48(sp)
    80004d3a:	79a2                	ld	s3,40(sp)
    80004d3c:	7a02                	ld	s4,32(sp)
    80004d3e:	6ae2                	ld	s5,24(sp)
    80004d40:	6b42                	ld	s6,16(sp)
    80004d42:	6ba2                	ld	s7,8(sp)
    80004d44:	6c02                	ld	s8,0(sp)
    80004d46:	6161                	addi	sp,sp,80
    80004d48:	8082                	ret
    ret = (i == n ? n : -1);
    80004d4a:	5a7d                	li	s4,-1
    80004d4c:	b7d5                	j	80004d30 <filewrite+0xfa>
    panic("filewrite");
    80004d4e:	00004517          	auipc	a0,0x4
    80004d52:	9ea50513          	addi	a0,a0,-1558 # 80008738 <syscalls+0x268>
    80004d56:	ffffb097          	auipc	ra,0xffffb
    80004d5a:	7e8080e7          	jalr	2024(ra) # 8000053e <panic>
    return -1;
    80004d5e:	5a7d                	li	s4,-1
    80004d60:	bfc1                	j	80004d30 <filewrite+0xfa>
      return -1;
    80004d62:	5a7d                	li	s4,-1
    80004d64:	b7f1                	j	80004d30 <filewrite+0xfa>
    80004d66:	5a7d                	li	s4,-1
    80004d68:	b7e1                	j	80004d30 <filewrite+0xfa>

0000000080004d6a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d6a:	7179                	addi	sp,sp,-48
    80004d6c:	f406                	sd	ra,40(sp)
    80004d6e:	f022                	sd	s0,32(sp)
    80004d70:	ec26                	sd	s1,24(sp)
    80004d72:	e84a                	sd	s2,16(sp)
    80004d74:	e44e                	sd	s3,8(sp)
    80004d76:	e052                	sd	s4,0(sp)
    80004d78:	1800                	addi	s0,sp,48
    80004d7a:	84aa                	mv	s1,a0
    80004d7c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d7e:	0005b023          	sd	zero,0(a1)
    80004d82:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d86:	00000097          	auipc	ra,0x0
    80004d8a:	bf8080e7          	jalr	-1032(ra) # 8000497e <filealloc>
    80004d8e:	e088                	sd	a0,0(s1)
    80004d90:	c551                	beqz	a0,80004e1c <pipealloc+0xb2>
    80004d92:	00000097          	auipc	ra,0x0
    80004d96:	bec080e7          	jalr	-1044(ra) # 8000497e <filealloc>
    80004d9a:	00aa3023          	sd	a0,0(s4)
    80004d9e:	c92d                	beqz	a0,80004e10 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004da0:	ffffc097          	auipc	ra,0xffffc
    80004da4:	d54080e7          	jalr	-684(ra) # 80000af4 <kalloc>
    80004da8:	892a                	mv	s2,a0
    80004daa:	c125                	beqz	a0,80004e0a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004dac:	4985                	li	s3,1
    80004dae:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004db2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004db6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004dba:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004dbe:	00004597          	auipc	a1,0x4
    80004dc2:	98a58593          	addi	a1,a1,-1654 # 80008748 <syscalls+0x278>
    80004dc6:	ffffc097          	auipc	ra,0xffffc
    80004dca:	d8e080e7          	jalr	-626(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004dce:	609c                	ld	a5,0(s1)
    80004dd0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004dd4:	609c                	ld	a5,0(s1)
    80004dd6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004dda:	609c                	ld	a5,0(s1)
    80004ddc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004de0:	609c                	ld	a5,0(s1)
    80004de2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004de6:	000a3783          	ld	a5,0(s4)
    80004dea:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004dee:	000a3783          	ld	a5,0(s4)
    80004df2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004df6:	000a3783          	ld	a5,0(s4)
    80004dfa:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004dfe:	000a3783          	ld	a5,0(s4)
    80004e02:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e06:	4501                	li	a0,0
    80004e08:	a025                	j	80004e30 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e0a:	6088                	ld	a0,0(s1)
    80004e0c:	e501                	bnez	a0,80004e14 <pipealloc+0xaa>
    80004e0e:	a039                	j	80004e1c <pipealloc+0xb2>
    80004e10:	6088                	ld	a0,0(s1)
    80004e12:	c51d                	beqz	a0,80004e40 <pipealloc+0xd6>
    fileclose(*f0);
    80004e14:	00000097          	auipc	ra,0x0
    80004e18:	c26080e7          	jalr	-986(ra) # 80004a3a <fileclose>
  if(*f1)
    80004e1c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e20:	557d                	li	a0,-1
  if(*f1)
    80004e22:	c799                	beqz	a5,80004e30 <pipealloc+0xc6>
    fileclose(*f1);
    80004e24:	853e                	mv	a0,a5
    80004e26:	00000097          	auipc	ra,0x0
    80004e2a:	c14080e7          	jalr	-1004(ra) # 80004a3a <fileclose>
  return -1;
    80004e2e:	557d                	li	a0,-1
}
    80004e30:	70a2                	ld	ra,40(sp)
    80004e32:	7402                	ld	s0,32(sp)
    80004e34:	64e2                	ld	s1,24(sp)
    80004e36:	6942                	ld	s2,16(sp)
    80004e38:	69a2                	ld	s3,8(sp)
    80004e3a:	6a02                	ld	s4,0(sp)
    80004e3c:	6145                	addi	sp,sp,48
    80004e3e:	8082                	ret
  return -1;
    80004e40:	557d                	li	a0,-1
    80004e42:	b7fd                	j	80004e30 <pipealloc+0xc6>

0000000080004e44 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e44:	1101                	addi	sp,sp,-32
    80004e46:	ec06                	sd	ra,24(sp)
    80004e48:	e822                	sd	s0,16(sp)
    80004e4a:	e426                	sd	s1,8(sp)
    80004e4c:	e04a                	sd	s2,0(sp)
    80004e4e:	1000                	addi	s0,sp,32
    80004e50:	84aa                	mv	s1,a0
    80004e52:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e54:	ffffc097          	auipc	ra,0xffffc
    80004e58:	d90080e7          	jalr	-624(ra) # 80000be4 <acquire>
  if(writable){
    80004e5c:	02090d63          	beqz	s2,80004e96 <pipeclose+0x52>
    pi->writeopen = 0;
    80004e60:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e64:	21848513          	addi	a0,s1,536
    80004e68:	ffffe097          	auipc	ra,0xffffe
    80004e6c:	812080e7          	jalr	-2030(ra) # 8000267a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e70:	2204b783          	ld	a5,544(s1)
    80004e74:	eb95                	bnez	a5,80004ea8 <pipeclose+0x64>
    release(&pi->lock);
    80004e76:	8526                	mv	a0,s1
    80004e78:	ffffc097          	auipc	ra,0xffffc
    80004e7c:	e20080e7          	jalr	-480(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004e80:	8526                	mv	a0,s1
    80004e82:	ffffc097          	auipc	ra,0xffffc
    80004e86:	b76080e7          	jalr	-1162(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004e8a:	60e2                	ld	ra,24(sp)
    80004e8c:	6442                	ld	s0,16(sp)
    80004e8e:	64a2                	ld	s1,8(sp)
    80004e90:	6902                	ld	s2,0(sp)
    80004e92:	6105                	addi	sp,sp,32
    80004e94:	8082                	ret
    pi->readopen = 0;
    80004e96:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e9a:	21c48513          	addi	a0,s1,540
    80004e9e:	ffffd097          	auipc	ra,0xffffd
    80004ea2:	7dc080e7          	jalr	2012(ra) # 8000267a <wakeup>
    80004ea6:	b7e9                	j	80004e70 <pipeclose+0x2c>
    release(&pi->lock);
    80004ea8:	8526                	mv	a0,s1
    80004eaa:	ffffc097          	auipc	ra,0xffffc
    80004eae:	dee080e7          	jalr	-530(ra) # 80000c98 <release>
}
    80004eb2:	bfe1                	j	80004e8a <pipeclose+0x46>

0000000080004eb4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004eb4:	7159                	addi	sp,sp,-112
    80004eb6:	f486                	sd	ra,104(sp)
    80004eb8:	f0a2                	sd	s0,96(sp)
    80004eba:	eca6                	sd	s1,88(sp)
    80004ebc:	e8ca                	sd	s2,80(sp)
    80004ebe:	e4ce                	sd	s3,72(sp)
    80004ec0:	e0d2                	sd	s4,64(sp)
    80004ec2:	fc56                	sd	s5,56(sp)
    80004ec4:	f85a                	sd	s6,48(sp)
    80004ec6:	f45e                	sd	s7,40(sp)
    80004ec8:	f062                	sd	s8,32(sp)
    80004eca:	ec66                	sd	s9,24(sp)
    80004ecc:	1880                	addi	s0,sp,112
    80004ece:	84aa                	mv	s1,a0
    80004ed0:	8aae                	mv	s5,a1
    80004ed2:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ed4:	ffffd097          	auipc	ra,0xffffd
    80004ed8:	df8080e7          	jalr	-520(ra) # 80001ccc <myproc>
    80004edc:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ede:	8526                	mv	a0,s1
    80004ee0:	ffffc097          	auipc	ra,0xffffc
    80004ee4:	d04080e7          	jalr	-764(ra) # 80000be4 <acquire>
  while(i < n){
    80004ee8:	0d405163          	blez	s4,80004faa <pipewrite+0xf6>
    80004eec:	8ba6                	mv	s7,s1
  int i = 0;
    80004eee:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ef0:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ef2:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ef6:	21c48c13          	addi	s8,s1,540
    80004efa:	a08d                	j	80004f5c <pipewrite+0xa8>
      release(&pi->lock);
    80004efc:	8526                	mv	a0,s1
    80004efe:	ffffc097          	auipc	ra,0xffffc
    80004f02:	d9a080e7          	jalr	-614(ra) # 80000c98 <release>
      return -1;
    80004f06:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f08:	854a                	mv	a0,s2
    80004f0a:	70a6                	ld	ra,104(sp)
    80004f0c:	7406                	ld	s0,96(sp)
    80004f0e:	64e6                	ld	s1,88(sp)
    80004f10:	6946                	ld	s2,80(sp)
    80004f12:	69a6                	ld	s3,72(sp)
    80004f14:	6a06                	ld	s4,64(sp)
    80004f16:	7ae2                	ld	s5,56(sp)
    80004f18:	7b42                	ld	s6,48(sp)
    80004f1a:	7ba2                	ld	s7,40(sp)
    80004f1c:	7c02                	ld	s8,32(sp)
    80004f1e:	6ce2                	ld	s9,24(sp)
    80004f20:	6165                	addi	sp,sp,112
    80004f22:	8082                	ret
      wakeup(&pi->nread);
    80004f24:	8566                	mv	a0,s9
    80004f26:	ffffd097          	auipc	ra,0xffffd
    80004f2a:	754080e7          	jalr	1876(ra) # 8000267a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f2e:	85de                	mv	a1,s7
    80004f30:	8562                	mv	a0,s8
    80004f32:	ffffd097          	auipc	ra,0xffffd
    80004f36:	5aa080e7          	jalr	1450(ra) # 800024dc <sleep>
    80004f3a:	a839                	j	80004f58 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f3c:	21c4a783          	lw	a5,540(s1)
    80004f40:	0017871b          	addiw	a4,a5,1
    80004f44:	20e4ae23          	sw	a4,540(s1)
    80004f48:	1ff7f793          	andi	a5,a5,511
    80004f4c:	97a6                	add	a5,a5,s1
    80004f4e:	f9f44703          	lbu	a4,-97(s0)
    80004f52:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f56:	2905                	addiw	s2,s2,1
  while(i < n){
    80004f58:	03495d63          	bge	s2,s4,80004f92 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004f5c:	2204a783          	lw	a5,544(s1)
    80004f60:	dfd1                	beqz	a5,80004efc <pipewrite+0x48>
    80004f62:	0289a783          	lw	a5,40(s3)
    80004f66:	fbd9                	bnez	a5,80004efc <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f68:	2184a783          	lw	a5,536(s1)
    80004f6c:	21c4a703          	lw	a4,540(s1)
    80004f70:	2007879b          	addiw	a5,a5,512
    80004f74:	faf708e3          	beq	a4,a5,80004f24 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f78:	4685                	li	a3,1
    80004f7a:	01590633          	add	a2,s2,s5
    80004f7e:	f9f40593          	addi	a1,s0,-97
    80004f82:	0509b503          	ld	a0,80(s3)
    80004f86:	ffffc097          	auipc	ra,0xffffc
    80004f8a:	778080e7          	jalr	1912(ra) # 800016fe <copyin>
    80004f8e:	fb6517e3          	bne	a0,s6,80004f3c <pipewrite+0x88>
  wakeup(&pi->nread);
    80004f92:	21848513          	addi	a0,s1,536
    80004f96:	ffffd097          	auipc	ra,0xffffd
    80004f9a:	6e4080e7          	jalr	1764(ra) # 8000267a <wakeup>
  release(&pi->lock);
    80004f9e:	8526                	mv	a0,s1
    80004fa0:	ffffc097          	auipc	ra,0xffffc
    80004fa4:	cf8080e7          	jalr	-776(ra) # 80000c98 <release>
  return i;
    80004fa8:	b785                	j	80004f08 <pipewrite+0x54>
  int i = 0;
    80004faa:	4901                	li	s2,0
    80004fac:	b7dd                	j	80004f92 <pipewrite+0xde>

0000000080004fae <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004fae:	715d                	addi	sp,sp,-80
    80004fb0:	e486                	sd	ra,72(sp)
    80004fb2:	e0a2                	sd	s0,64(sp)
    80004fb4:	fc26                	sd	s1,56(sp)
    80004fb6:	f84a                	sd	s2,48(sp)
    80004fb8:	f44e                	sd	s3,40(sp)
    80004fba:	f052                	sd	s4,32(sp)
    80004fbc:	ec56                	sd	s5,24(sp)
    80004fbe:	e85a                	sd	s6,16(sp)
    80004fc0:	0880                	addi	s0,sp,80
    80004fc2:	84aa                	mv	s1,a0
    80004fc4:	892e                	mv	s2,a1
    80004fc6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004fc8:	ffffd097          	auipc	ra,0xffffd
    80004fcc:	d04080e7          	jalr	-764(ra) # 80001ccc <myproc>
    80004fd0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004fd2:	8b26                	mv	s6,s1
    80004fd4:	8526                	mv	a0,s1
    80004fd6:	ffffc097          	auipc	ra,0xffffc
    80004fda:	c0e080e7          	jalr	-1010(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fde:	2184a703          	lw	a4,536(s1)
    80004fe2:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fe6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fea:	02f71463          	bne	a4,a5,80005012 <piperead+0x64>
    80004fee:	2244a783          	lw	a5,548(s1)
    80004ff2:	c385                	beqz	a5,80005012 <piperead+0x64>
    if(pr->killed){
    80004ff4:	028a2783          	lw	a5,40(s4)
    80004ff8:	ebc1                	bnez	a5,80005088 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ffa:	85da                	mv	a1,s6
    80004ffc:	854e                	mv	a0,s3
    80004ffe:	ffffd097          	auipc	ra,0xffffd
    80005002:	4de080e7          	jalr	1246(ra) # 800024dc <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005006:	2184a703          	lw	a4,536(s1)
    8000500a:	21c4a783          	lw	a5,540(s1)
    8000500e:	fef700e3          	beq	a4,a5,80004fee <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005012:	09505263          	blez	s5,80005096 <piperead+0xe8>
    80005016:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005018:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000501a:	2184a783          	lw	a5,536(s1)
    8000501e:	21c4a703          	lw	a4,540(s1)
    80005022:	02f70d63          	beq	a4,a5,8000505c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005026:	0017871b          	addiw	a4,a5,1
    8000502a:	20e4ac23          	sw	a4,536(s1)
    8000502e:	1ff7f793          	andi	a5,a5,511
    80005032:	97a6                	add	a5,a5,s1
    80005034:	0187c783          	lbu	a5,24(a5)
    80005038:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000503c:	4685                	li	a3,1
    8000503e:	fbf40613          	addi	a2,s0,-65
    80005042:	85ca                	mv	a1,s2
    80005044:	050a3503          	ld	a0,80(s4)
    80005048:	ffffc097          	auipc	ra,0xffffc
    8000504c:	62a080e7          	jalr	1578(ra) # 80001672 <copyout>
    80005050:	01650663          	beq	a0,s6,8000505c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005054:	2985                	addiw	s3,s3,1
    80005056:	0905                	addi	s2,s2,1
    80005058:	fd3a91e3          	bne	s5,s3,8000501a <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000505c:	21c48513          	addi	a0,s1,540
    80005060:	ffffd097          	auipc	ra,0xffffd
    80005064:	61a080e7          	jalr	1562(ra) # 8000267a <wakeup>
  release(&pi->lock);
    80005068:	8526                	mv	a0,s1
    8000506a:	ffffc097          	auipc	ra,0xffffc
    8000506e:	c2e080e7          	jalr	-978(ra) # 80000c98 <release>
  return i;
}
    80005072:	854e                	mv	a0,s3
    80005074:	60a6                	ld	ra,72(sp)
    80005076:	6406                	ld	s0,64(sp)
    80005078:	74e2                	ld	s1,56(sp)
    8000507a:	7942                	ld	s2,48(sp)
    8000507c:	79a2                	ld	s3,40(sp)
    8000507e:	7a02                	ld	s4,32(sp)
    80005080:	6ae2                	ld	s5,24(sp)
    80005082:	6b42                	ld	s6,16(sp)
    80005084:	6161                	addi	sp,sp,80
    80005086:	8082                	ret
      release(&pi->lock);
    80005088:	8526                	mv	a0,s1
    8000508a:	ffffc097          	auipc	ra,0xffffc
    8000508e:	c0e080e7          	jalr	-1010(ra) # 80000c98 <release>
      return -1;
    80005092:	59fd                	li	s3,-1
    80005094:	bff9                	j	80005072 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005096:	4981                	li	s3,0
    80005098:	b7d1                	j	8000505c <piperead+0xae>

000000008000509a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000509a:	df010113          	addi	sp,sp,-528
    8000509e:	20113423          	sd	ra,520(sp)
    800050a2:	20813023          	sd	s0,512(sp)
    800050a6:	ffa6                	sd	s1,504(sp)
    800050a8:	fbca                	sd	s2,496(sp)
    800050aa:	f7ce                	sd	s3,488(sp)
    800050ac:	f3d2                	sd	s4,480(sp)
    800050ae:	efd6                	sd	s5,472(sp)
    800050b0:	ebda                	sd	s6,464(sp)
    800050b2:	e7de                	sd	s7,456(sp)
    800050b4:	e3e2                	sd	s8,448(sp)
    800050b6:	ff66                	sd	s9,440(sp)
    800050b8:	fb6a                	sd	s10,432(sp)
    800050ba:	f76e                	sd	s11,424(sp)
    800050bc:	0c00                	addi	s0,sp,528
    800050be:	84aa                	mv	s1,a0
    800050c0:	dea43c23          	sd	a0,-520(s0)
    800050c4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050c8:	ffffd097          	auipc	ra,0xffffd
    800050cc:	c04080e7          	jalr	-1020(ra) # 80001ccc <myproc>
    800050d0:	892a                	mv	s2,a0

  begin_op();
    800050d2:	fffff097          	auipc	ra,0xfffff
    800050d6:	49c080e7          	jalr	1180(ra) # 8000456e <begin_op>

  if((ip = namei(path)) == 0){
    800050da:	8526                	mv	a0,s1
    800050dc:	fffff097          	auipc	ra,0xfffff
    800050e0:	276080e7          	jalr	630(ra) # 80004352 <namei>
    800050e4:	c92d                	beqz	a0,80005156 <exec+0xbc>
    800050e6:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800050e8:	fffff097          	auipc	ra,0xfffff
    800050ec:	ab4080e7          	jalr	-1356(ra) # 80003b9c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050f0:	04000713          	li	a4,64
    800050f4:	4681                	li	a3,0
    800050f6:	e5040613          	addi	a2,s0,-432
    800050fa:	4581                	li	a1,0
    800050fc:	8526                	mv	a0,s1
    800050fe:	fffff097          	auipc	ra,0xfffff
    80005102:	d52080e7          	jalr	-686(ra) # 80003e50 <readi>
    80005106:	04000793          	li	a5,64
    8000510a:	00f51a63          	bne	a0,a5,8000511e <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000510e:	e5042703          	lw	a4,-432(s0)
    80005112:	464c47b7          	lui	a5,0x464c4
    80005116:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000511a:	04f70463          	beq	a4,a5,80005162 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000511e:	8526                	mv	a0,s1
    80005120:	fffff097          	auipc	ra,0xfffff
    80005124:	cde080e7          	jalr	-802(ra) # 80003dfe <iunlockput>
    end_op();
    80005128:	fffff097          	auipc	ra,0xfffff
    8000512c:	4c6080e7          	jalr	1222(ra) # 800045ee <end_op>
  }
  return -1;
    80005130:	557d                	li	a0,-1
}
    80005132:	20813083          	ld	ra,520(sp)
    80005136:	20013403          	ld	s0,512(sp)
    8000513a:	74fe                	ld	s1,504(sp)
    8000513c:	795e                	ld	s2,496(sp)
    8000513e:	79be                	ld	s3,488(sp)
    80005140:	7a1e                	ld	s4,480(sp)
    80005142:	6afe                	ld	s5,472(sp)
    80005144:	6b5e                	ld	s6,464(sp)
    80005146:	6bbe                	ld	s7,456(sp)
    80005148:	6c1e                	ld	s8,448(sp)
    8000514a:	7cfa                	ld	s9,440(sp)
    8000514c:	7d5a                	ld	s10,432(sp)
    8000514e:	7dba                	ld	s11,424(sp)
    80005150:	21010113          	addi	sp,sp,528
    80005154:	8082                	ret
    end_op();
    80005156:	fffff097          	auipc	ra,0xfffff
    8000515a:	498080e7          	jalr	1176(ra) # 800045ee <end_op>
    return -1;
    8000515e:	557d                	li	a0,-1
    80005160:	bfc9                	j	80005132 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005162:	854a                	mv	a0,s2
    80005164:	ffffd097          	auipc	ra,0xffffd
    80005168:	c26080e7          	jalr	-986(ra) # 80001d8a <proc_pagetable>
    8000516c:	8baa                	mv	s7,a0
    8000516e:	d945                	beqz	a0,8000511e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005170:	e7042983          	lw	s3,-400(s0)
    80005174:	e8845783          	lhu	a5,-376(s0)
    80005178:	c7ad                	beqz	a5,800051e2 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000517a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000517c:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    8000517e:	6c85                	lui	s9,0x1
    80005180:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005184:	def43823          	sd	a5,-528(s0)
    80005188:	a42d                	j	800053b2 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000518a:	00003517          	auipc	a0,0x3
    8000518e:	5c650513          	addi	a0,a0,1478 # 80008750 <syscalls+0x280>
    80005192:	ffffb097          	auipc	ra,0xffffb
    80005196:	3ac080e7          	jalr	940(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000519a:	8756                	mv	a4,s5
    8000519c:	012d86bb          	addw	a3,s11,s2
    800051a0:	4581                	li	a1,0
    800051a2:	8526                	mv	a0,s1
    800051a4:	fffff097          	auipc	ra,0xfffff
    800051a8:	cac080e7          	jalr	-852(ra) # 80003e50 <readi>
    800051ac:	2501                	sext.w	a0,a0
    800051ae:	1aaa9963          	bne	s5,a0,80005360 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800051b2:	6785                	lui	a5,0x1
    800051b4:	0127893b          	addw	s2,a5,s2
    800051b8:	77fd                	lui	a5,0xfffff
    800051ba:	01478a3b          	addw	s4,a5,s4
    800051be:	1f897163          	bgeu	s2,s8,800053a0 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800051c2:	02091593          	slli	a1,s2,0x20
    800051c6:	9181                	srli	a1,a1,0x20
    800051c8:	95ea                	add	a1,a1,s10
    800051ca:	855e                	mv	a0,s7
    800051cc:	ffffc097          	auipc	ra,0xffffc
    800051d0:	ea2080e7          	jalr	-350(ra) # 8000106e <walkaddr>
    800051d4:	862a                	mv	a2,a0
    if(pa == 0)
    800051d6:	d955                	beqz	a0,8000518a <exec+0xf0>
      n = PGSIZE;
    800051d8:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800051da:	fd9a70e3          	bgeu	s4,s9,8000519a <exec+0x100>
      n = sz - i;
    800051de:	8ad2                	mv	s5,s4
    800051e0:	bf6d                	j	8000519a <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051e2:	4901                	li	s2,0
  iunlockput(ip);
    800051e4:	8526                	mv	a0,s1
    800051e6:	fffff097          	auipc	ra,0xfffff
    800051ea:	c18080e7          	jalr	-1000(ra) # 80003dfe <iunlockput>
  end_op();
    800051ee:	fffff097          	auipc	ra,0xfffff
    800051f2:	400080e7          	jalr	1024(ra) # 800045ee <end_op>
  p = myproc();
    800051f6:	ffffd097          	auipc	ra,0xffffd
    800051fa:	ad6080e7          	jalr	-1322(ra) # 80001ccc <myproc>
    800051fe:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005200:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005204:	6785                	lui	a5,0x1
    80005206:	17fd                	addi	a5,a5,-1
    80005208:	993e                	add	s2,s2,a5
    8000520a:	757d                	lui	a0,0xfffff
    8000520c:	00a977b3          	and	a5,s2,a0
    80005210:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005214:	6609                	lui	a2,0x2
    80005216:	963e                	add	a2,a2,a5
    80005218:	85be                	mv	a1,a5
    8000521a:	855e                	mv	a0,s7
    8000521c:	ffffc097          	auipc	ra,0xffffc
    80005220:	206080e7          	jalr	518(ra) # 80001422 <uvmalloc>
    80005224:	8b2a                	mv	s6,a0
  ip = 0;
    80005226:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005228:	12050c63          	beqz	a0,80005360 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000522c:	75f9                	lui	a1,0xffffe
    8000522e:	95aa                	add	a1,a1,a0
    80005230:	855e                	mv	a0,s7
    80005232:	ffffc097          	auipc	ra,0xffffc
    80005236:	40e080e7          	jalr	1038(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    8000523a:	7c7d                	lui	s8,0xfffff
    8000523c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000523e:	e0043783          	ld	a5,-512(s0)
    80005242:	6388                	ld	a0,0(a5)
    80005244:	c535                	beqz	a0,800052b0 <exec+0x216>
    80005246:	e9040993          	addi	s3,s0,-368
    8000524a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000524e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005250:	ffffc097          	auipc	ra,0xffffc
    80005254:	c14080e7          	jalr	-1004(ra) # 80000e64 <strlen>
    80005258:	2505                	addiw	a0,a0,1
    8000525a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000525e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005262:	13896363          	bltu	s2,s8,80005388 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005266:	e0043d83          	ld	s11,-512(s0)
    8000526a:	000dba03          	ld	s4,0(s11)
    8000526e:	8552                	mv	a0,s4
    80005270:	ffffc097          	auipc	ra,0xffffc
    80005274:	bf4080e7          	jalr	-1036(ra) # 80000e64 <strlen>
    80005278:	0015069b          	addiw	a3,a0,1
    8000527c:	8652                	mv	a2,s4
    8000527e:	85ca                	mv	a1,s2
    80005280:	855e                	mv	a0,s7
    80005282:	ffffc097          	auipc	ra,0xffffc
    80005286:	3f0080e7          	jalr	1008(ra) # 80001672 <copyout>
    8000528a:	10054363          	bltz	a0,80005390 <exec+0x2f6>
    ustack[argc] = sp;
    8000528e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005292:	0485                	addi	s1,s1,1
    80005294:	008d8793          	addi	a5,s11,8
    80005298:	e0f43023          	sd	a5,-512(s0)
    8000529c:	008db503          	ld	a0,8(s11)
    800052a0:	c911                	beqz	a0,800052b4 <exec+0x21a>
    if(argc >= MAXARG)
    800052a2:	09a1                	addi	s3,s3,8
    800052a4:	fb3c96e3          	bne	s9,s3,80005250 <exec+0x1b6>
  sz = sz1;
    800052a8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052ac:	4481                	li	s1,0
    800052ae:	a84d                	j	80005360 <exec+0x2c6>
  sp = sz;
    800052b0:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800052b2:	4481                	li	s1,0
  ustack[argc] = 0;
    800052b4:	00349793          	slli	a5,s1,0x3
    800052b8:	f9040713          	addi	a4,s0,-112
    800052bc:	97ba                	add	a5,a5,a4
    800052be:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800052c2:	00148693          	addi	a3,s1,1
    800052c6:	068e                	slli	a3,a3,0x3
    800052c8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800052cc:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800052d0:	01897663          	bgeu	s2,s8,800052dc <exec+0x242>
  sz = sz1;
    800052d4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052d8:	4481                	li	s1,0
    800052da:	a059                	j	80005360 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800052dc:	e9040613          	addi	a2,s0,-368
    800052e0:	85ca                	mv	a1,s2
    800052e2:	855e                	mv	a0,s7
    800052e4:	ffffc097          	auipc	ra,0xffffc
    800052e8:	38e080e7          	jalr	910(ra) # 80001672 <copyout>
    800052ec:	0a054663          	bltz	a0,80005398 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800052f0:	058ab783          	ld	a5,88(s5)
    800052f4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800052f8:	df843783          	ld	a5,-520(s0)
    800052fc:	0007c703          	lbu	a4,0(a5)
    80005300:	cf11                	beqz	a4,8000531c <exec+0x282>
    80005302:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005304:	02f00693          	li	a3,47
    80005308:	a039                	j	80005316 <exec+0x27c>
      last = s+1;
    8000530a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000530e:	0785                	addi	a5,a5,1
    80005310:	fff7c703          	lbu	a4,-1(a5)
    80005314:	c701                	beqz	a4,8000531c <exec+0x282>
    if(*s == '/')
    80005316:	fed71ce3          	bne	a4,a3,8000530e <exec+0x274>
    8000531a:	bfc5                	j	8000530a <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000531c:	4641                	li	a2,16
    8000531e:	df843583          	ld	a1,-520(s0)
    80005322:	158a8513          	addi	a0,s5,344
    80005326:	ffffc097          	auipc	ra,0xffffc
    8000532a:	b0c080e7          	jalr	-1268(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000532e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005332:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005336:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000533a:	058ab783          	ld	a5,88(s5)
    8000533e:	e6843703          	ld	a4,-408(s0)
    80005342:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005344:	058ab783          	ld	a5,88(s5)
    80005348:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000534c:	85ea                	mv	a1,s10
    8000534e:	ffffd097          	auipc	ra,0xffffd
    80005352:	ad8080e7          	jalr	-1320(ra) # 80001e26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005356:	0004851b          	sext.w	a0,s1
    8000535a:	bbe1                	j	80005132 <exec+0x98>
    8000535c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005360:	e0843583          	ld	a1,-504(s0)
    80005364:	855e                	mv	a0,s7
    80005366:	ffffd097          	auipc	ra,0xffffd
    8000536a:	ac0080e7          	jalr	-1344(ra) # 80001e26 <proc_freepagetable>
  if(ip){
    8000536e:	da0498e3          	bnez	s1,8000511e <exec+0x84>
  return -1;
    80005372:	557d                	li	a0,-1
    80005374:	bb7d                	j	80005132 <exec+0x98>
    80005376:	e1243423          	sd	s2,-504(s0)
    8000537a:	b7dd                	j	80005360 <exec+0x2c6>
    8000537c:	e1243423          	sd	s2,-504(s0)
    80005380:	b7c5                	j	80005360 <exec+0x2c6>
    80005382:	e1243423          	sd	s2,-504(s0)
    80005386:	bfe9                	j	80005360 <exec+0x2c6>
  sz = sz1;
    80005388:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000538c:	4481                	li	s1,0
    8000538e:	bfc9                	j	80005360 <exec+0x2c6>
  sz = sz1;
    80005390:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005394:	4481                	li	s1,0
    80005396:	b7e9                	j	80005360 <exec+0x2c6>
  sz = sz1;
    80005398:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000539c:	4481                	li	s1,0
    8000539e:	b7c9                	j	80005360 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053a0:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053a4:	2b05                	addiw	s6,s6,1
    800053a6:	0389899b          	addiw	s3,s3,56
    800053aa:	e8845783          	lhu	a5,-376(s0)
    800053ae:	e2fb5be3          	bge	s6,a5,800051e4 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800053b2:	2981                	sext.w	s3,s3
    800053b4:	03800713          	li	a4,56
    800053b8:	86ce                	mv	a3,s3
    800053ba:	e1840613          	addi	a2,s0,-488
    800053be:	4581                	li	a1,0
    800053c0:	8526                	mv	a0,s1
    800053c2:	fffff097          	auipc	ra,0xfffff
    800053c6:	a8e080e7          	jalr	-1394(ra) # 80003e50 <readi>
    800053ca:	03800793          	li	a5,56
    800053ce:	f8f517e3          	bne	a0,a5,8000535c <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800053d2:	e1842783          	lw	a5,-488(s0)
    800053d6:	4705                	li	a4,1
    800053d8:	fce796e3          	bne	a5,a4,800053a4 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800053dc:	e4043603          	ld	a2,-448(s0)
    800053e0:	e3843783          	ld	a5,-456(s0)
    800053e4:	f8f669e3          	bltu	a2,a5,80005376 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053e8:	e2843783          	ld	a5,-472(s0)
    800053ec:	963e                	add	a2,a2,a5
    800053ee:	f8f667e3          	bltu	a2,a5,8000537c <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053f2:	85ca                	mv	a1,s2
    800053f4:	855e                	mv	a0,s7
    800053f6:	ffffc097          	auipc	ra,0xffffc
    800053fa:	02c080e7          	jalr	44(ra) # 80001422 <uvmalloc>
    800053fe:	e0a43423          	sd	a0,-504(s0)
    80005402:	d141                	beqz	a0,80005382 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005404:	e2843d03          	ld	s10,-472(s0)
    80005408:	df043783          	ld	a5,-528(s0)
    8000540c:	00fd77b3          	and	a5,s10,a5
    80005410:	fba1                	bnez	a5,80005360 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005412:	e2042d83          	lw	s11,-480(s0)
    80005416:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000541a:	f80c03e3          	beqz	s8,800053a0 <exec+0x306>
    8000541e:	8a62                	mv	s4,s8
    80005420:	4901                	li	s2,0
    80005422:	b345                	j	800051c2 <exec+0x128>

0000000080005424 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005424:	7179                	addi	sp,sp,-48
    80005426:	f406                	sd	ra,40(sp)
    80005428:	f022                	sd	s0,32(sp)
    8000542a:	ec26                	sd	s1,24(sp)
    8000542c:	e84a                	sd	s2,16(sp)
    8000542e:	1800                	addi	s0,sp,48
    80005430:	892e                	mv	s2,a1
    80005432:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005434:	fdc40593          	addi	a1,s0,-36
    80005438:	ffffe097          	auipc	ra,0xffffe
    8000543c:	bf2080e7          	jalr	-1038(ra) # 8000302a <argint>
    80005440:	04054063          	bltz	a0,80005480 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005444:	fdc42703          	lw	a4,-36(s0)
    80005448:	47bd                	li	a5,15
    8000544a:	02e7ed63          	bltu	a5,a4,80005484 <argfd+0x60>
    8000544e:	ffffd097          	auipc	ra,0xffffd
    80005452:	87e080e7          	jalr	-1922(ra) # 80001ccc <myproc>
    80005456:	fdc42703          	lw	a4,-36(s0)
    8000545a:	01a70793          	addi	a5,a4,26
    8000545e:	078e                	slli	a5,a5,0x3
    80005460:	953e                	add	a0,a0,a5
    80005462:	611c                	ld	a5,0(a0)
    80005464:	c395                	beqz	a5,80005488 <argfd+0x64>
    return -1;
  if(pfd)
    80005466:	00090463          	beqz	s2,8000546e <argfd+0x4a>
    *pfd = fd;
    8000546a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000546e:	4501                	li	a0,0
  if(pf)
    80005470:	c091                	beqz	s1,80005474 <argfd+0x50>
    *pf = f;
    80005472:	e09c                	sd	a5,0(s1)
}
    80005474:	70a2                	ld	ra,40(sp)
    80005476:	7402                	ld	s0,32(sp)
    80005478:	64e2                	ld	s1,24(sp)
    8000547a:	6942                	ld	s2,16(sp)
    8000547c:	6145                	addi	sp,sp,48
    8000547e:	8082                	ret
    return -1;
    80005480:	557d                	li	a0,-1
    80005482:	bfcd                	j	80005474 <argfd+0x50>
    return -1;
    80005484:	557d                	li	a0,-1
    80005486:	b7fd                	j	80005474 <argfd+0x50>
    80005488:	557d                	li	a0,-1
    8000548a:	b7ed                	j	80005474 <argfd+0x50>

000000008000548c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000548c:	1101                	addi	sp,sp,-32
    8000548e:	ec06                	sd	ra,24(sp)
    80005490:	e822                	sd	s0,16(sp)
    80005492:	e426                	sd	s1,8(sp)
    80005494:	1000                	addi	s0,sp,32
    80005496:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005498:	ffffd097          	auipc	ra,0xffffd
    8000549c:	834080e7          	jalr	-1996(ra) # 80001ccc <myproc>
    800054a0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054a2:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800054a6:	4501                	li	a0,0
    800054a8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800054aa:	6398                	ld	a4,0(a5)
    800054ac:	cb19                	beqz	a4,800054c2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800054ae:	2505                	addiw	a0,a0,1
    800054b0:	07a1                	addi	a5,a5,8
    800054b2:	fed51ce3          	bne	a0,a3,800054aa <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800054b6:	557d                	li	a0,-1
}
    800054b8:	60e2                	ld	ra,24(sp)
    800054ba:	6442                	ld	s0,16(sp)
    800054bc:	64a2                	ld	s1,8(sp)
    800054be:	6105                	addi	sp,sp,32
    800054c0:	8082                	ret
      p->ofile[fd] = f;
    800054c2:	01a50793          	addi	a5,a0,26
    800054c6:	078e                	slli	a5,a5,0x3
    800054c8:	963e                	add	a2,a2,a5
    800054ca:	e204                	sd	s1,0(a2)
      return fd;
    800054cc:	b7f5                	j	800054b8 <fdalloc+0x2c>

00000000800054ce <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054ce:	715d                	addi	sp,sp,-80
    800054d0:	e486                	sd	ra,72(sp)
    800054d2:	e0a2                	sd	s0,64(sp)
    800054d4:	fc26                	sd	s1,56(sp)
    800054d6:	f84a                	sd	s2,48(sp)
    800054d8:	f44e                	sd	s3,40(sp)
    800054da:	f052                	sd	s4,32(sp)
    800054dc:	ec56                	sd	s5,24(sp)
    800054de:	0880                	addi	s0,sp,80
    800054e0:	89ae                	mv	s3,a1
    800054e2:	8ab2                	mv	s5,a2
    800054e4:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054e6:	fb040593          	addi	a1,s0,-80
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	e86080e7          	jalr	-378(ra) # 80004370 <nameiparent>
    800054f2:	892a                	mv	s2,a0
    800054f4:	12050f63          	beqz	a0,80005632 <create+0x164>
    return 0;

  ilock(dp);
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	6a4080e7          	jalr	1700(ra) # 80003b9c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005500:	4601                	li	a2,0
    80005502:	fb040593          	addi	a1,s0,-80
    80005506:	854a                	mv	a0,s2
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	b78080e7          	jalr	-1160(ra) # 80004080 <dirlookup>
    80005510:	84aa                	mv	s1,a0
    80005512:	c921                	beqz	a0,80005562 <create+0x94>
    iunlockput(dp);
    80005514:	854a                	mv	a0,s2
    80005516:	fffff097          	auipc	ra,0xfffff
    8000551a:	8e8080e7          	jalr	-1816(ra) # 80003dfe <iunlockput>
    ilock(ip);
    8000551e:	8526                	mv	a0,s1
    80005520:	ffffe097          	auipc	ra,0xffffe
    80005524:	67c080e7          	jalr	1660(ra) # 80003b9c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005528:	2981                	sext.w	s3,s3
    8000552a:	4789                	li	a5,2
    8000552c:	02f99463          	bne	s3,a5,80005554 <create+0x86>
    80005530:	0444d783          	lhu	a5,68(s1)
    80005534:	37f9                	addiw	a5,a5,-2
    80005536:	17c2                	slli	a5,a5,0x30
    80005538:	93c1                	srli	a5,a5,0x30
    8000553a:	4705                	li	a4,1
    8000553c:	00f76c63          	bltu	a4,a5,80005554 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005540:	8526                	mv	a0,s1
    80005542:	60a6                	ld	ra,72(sp)
    80005544:	6406                	ld	s0,64(sp)
    80005546:	74e2                	ld	s1,56(sp)
    80005548:	7942                	ld	s2,48(sp)
    8000554a:	79a2                	ld	s3,40(sp)
    8000554c:	7a02                	ld	s4,32(sp)
    8000554e:	6ae2                	ld	s5,24(sp)
    80005550:	6161                	addi	sp,sp,80
    80005552:	8082                	ret
    iunlockput(ip);
    80005554:	8526                	mv	a0,s1
    80005556:	fffff097          	auipc	ra,0xfffff
    8000555a:	8a8080e7          	jalr	-1880(ra) # 80003dfe <iunlockput>
    return 0;
    8000555e:	4481                	li	s1,0
    80005560:	b7c5                	j	80005540 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005562:	85ce                	mv	a1,s3
    80005564:	00092503          	lw	a0,0(s2)
    80005568:	ffffe097          	auipc	ra,0xffffe
    8000556c:	49c080e7          	jalr	1180(ra) # 80003a04 <ialloc>
    80005570:	84aa                	mv	s1,a0
    80005572:	c529                	beqz	a0,800055bc <create+0xee>
  ilock(ip);
    80005574:	ffffe097          	auipc	ra,0xffffe
    80005578:	628080e7          	jalr	1576(ra) # 80003b9c <ilock>
  ip->major = major;
    8000557c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005580:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005584:	4785                	li	a5,1
    80005586:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000558a:	8526                	mv	a0,s1
    8000558c:	ffffe097          	auipc	ra,0xffffe
    80005590:	546080e7          	jalr	1350(ra) # 80003ad2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005594:	2981                	sext.w	s3,s3
    80005596:	4785                	li	a5,1
    80005598:	02f98a63          	beq	s3,a5,800055cc <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000559c:	40d0                	lw	a2,4(s1)
    8000559e:	fb040593          	addi	a1,s0,-80
    800055a2:	854a                	mv	a0,s2
    800055a4:	fffff097          	auipc	ra,0xfffff
    800055a8:	cec080e7          	jalr	-788(ra) # 80004290 <dirlink>
    800055ac:	06054b63          	bltz	a0,80005622 <create+0x154>
  iunlockput(dp);
    800055b0:	854a                	mv	a0,s2
    800055b2:	fffff097          	auipc	ra,0xfffff
    800055b6:	84c080e7          	jalr	-1972(ra) # 80003dfe <iunlockput>
  return ip;
    800055ba:	b759                	j	80005540 <create+0x72>
    panic("create: ialloc");
    800055bc:	00003517          	auipc	a0,0x3
    800055c0:	1b450513          	addi	a0,a0,436 # 80008770 <syscalls+0x2a0>
    800055c4:	ffffb097          	auipc	ra,0xffffb
    800055c8:	f7a080e7          	jalr	-134(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800055cc:	04a95783          	lhu	a5,74(s2)
    800055d0:	2785                	addiw	a5,a5,1
    800055d2:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800055d6:	854a                	mv	a0,s2
    800055d8:	ffffe097          	auipc	ra,0xffffe
    800055dc:	4fa080e7          	jalr	1274(ra) # 80003ad2 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055e0:	40d0                	lw	a2,4(s1)
    800055e2:	00003597          	auipc	a1,0x3
    800055e6:	19e58593          	addi	a1,a1,414 # 80008780 <syscalls+0x2b0>
    800055ea:	8526                	mv	a0,s1
    800055ec:	fffff097          	auipc	ra,0xfffff
    800055f0:	ca4080e7          	jalr	-860(ra) # 80004290 <dirlink>
    800055f4:	00054f63          	bltz	a0,80005612 <create+0x144>
    800055f8:	00492603          	lw	a2,4(s2)
    800055fc:	00003597          	auipc	a1,0x3
    80005600:	18c58593          	addi	a1,a1,396 # 80008788 <syscalls+0x2b8>
    80005604:	8526                	mv	a0,s1
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	c8a080e7          	jalr	-886(ra) # 80004290 <dirlink>
    8000560e:	f80557e3          	bgez	a0,8000559c <create+0xce>
      panic("create dots");
    80005612:	00003517          	auipc	a0,0x3
    80005616:	17e50513          	addi	a0,a0,382 # 80008790 <syscalls+0x2c0>
    8000561a:	ffffb097          	auipc	ra,0xffffb
    8000561e:	f24080e7          	jalr	-220(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005622:	00003517          	auipc	a0,0x3
    80005626:	17e50513          	addi	a0,a0,382 # 800087a0 <syscalls+0x2d0>
    8000562a:	ffffb097          	auipc	ra,0xffffb
    8000562e:	f14080e7          	jalr	-236(ra) # 8000053e <panic>
    return 0;
    80005632:	84aa                	mv	s1,a0
    80005634:	b731                	j	80005540 <create+0x72>

0000000080005636 <sys_dup>:
{
    80005636:	7179                	addi	sp,sp,-48
    80005638:	f406                	sd	ra,40(sp)
    8000563a:	f022                	sd	s0,32(sp)
    8000563c:	ec26                	sd	s1,24(sp)
    8000563e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005640:	fd840613          	addi	a2,s0,-40
    80005644:	4581                	li	a1,0
    80005646:	4501                	li	a0,0
    80005648:	00000097          	auipc	ra,0x0
    8000564c:	ddc080e7          	jalr	-548(ra) # 80005424 <argfd>
    return -1;
    80005650:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005652:	02054363          	bltz	a0,80005678 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005656:	fd843503          	ld	a0,-40(s0)
    8000565a:	00000097          	auipc	ra,0x0
    8000565e:	e32080e7          	jalr	-462(ra) # 8000548c <fdalloc>
    80005662:	84aa                	mv	s1,a0
    return -1;
    80005664:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005666:	00054963          	bltz	a0,80005678 <sys_dup+0x42>
  filedup(f);
    8000566a:	fd843503          	ld	a0,-40(s0)
    8000566e:	fffff097          	auipc	ra,0xfffff
    80005672:	37a080e7          	jalr	890(ra) # 800049e8 <filedup>
  return fd;
    80005676:	87a6                	mv	a5,s1
}
    80005678:	853e                	mv	a0,a5
    8000567a:	70a2                	ld	ra,40(sp)
    8000567c:	7402                	ld	s0,32(sp)
    8000567e:	64e2                	ld	s1,24(sp)
    80005680:	6145                	addi	sp,sp,48
    80005682:	8082                	ret

0000000080005684 <sys_read>:
{
    80005684:	7179                	addi	sp,sp,-48
    80005686:	f406                	sd	ra,40(sp)
    80005688:	f022                	sd	s0,32(sp)
    8000568a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000568c:	fe840613          	addi	a2,s0,-24
    80005690:	4581                	li	a1,0
    80005692:	4501                	li	a0,0
    80005694:	00000097          	auipc	ra,0x0
    80005698:	d90080e7          	jalr	-624(ra) # 80005424 <argfd>
    return -1;
    8000569c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000569e:	04054163          	bltz	a0,800056e0 <sys_read+0x5c>
    800056a2:	fe440593          	addi	a1,s0,-28
    800056a6:	4509                	li	a0,2
    800056a8:	ffffe097          	auipc	ra,0xffffe
    800056ac:	982080e7          	jalr	-1662(ra) # 8000302a <argint>
    return -1;
    800056b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056b2:	02054763          	bltz	a0,800056e0 <sys_read+0x5c>
    800056b6:	fd840593          	addi	a1,s0,-40
    800056ba:	4505                	li	a0,1
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	990080e7          	jalr	-1648(ra) # 8000304c <argaddr>
    return -1;
    800056c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056c6:	00054d63          	bltz	a0,800056e0 <sys_read+0x5c>
  return fileread(f, p, n);
    800056ca:	fe442603          	lw	a2,-28(s0)
    800056ce:	fd843583          	ld	a1,-40(s0)
    800056d2:	fe843503          	ld	a0,-24(s0)
    800056d6:	fffff097          	auipc	ra,0xfffff
    800056da:	49e080e7          	jalr	1182(ra) # 80004b74 <fileread>
    800056de:	87aa                	mv	a5,a0
}
    800056e0:	853e                	mv	a0,a5
    800056e2:	70a2                	ld	ra,40(sp)
    800056e4:	7402                	ld	s0,32(sp)
    800056e6:	6145                	addi	sp,sp,48
    800056e8:	8082                	ret

00000000800056ea <sys_write>:
{
    800056ea:	7179                	addi	sp,sp,-48
    800056ec:	f406                	sd	ra,40(sp)
    800056ee:	f022                	sd	s0,32(sp)
    800056f0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056f2:	fe840613          	addi	a2,s0,-24
    800056f6:	4581                	li	a1,0
    800056f8:	4501                	li	a0,0
    800056fa:	00000097          	auipc	ra,0x0
    800056fe:	d2a080e7          	jalr	-726(ra) # 80005424 <argfd>
    return -1;
    80005702:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005704:	04054163          	bltz	a0,80005746 <sys_write+0x5c>
    80005708:	fe440593          	addi	a1,s0,-28
    8000570c:	4509                	li	a0,2
    8000570e:	ffffe097          	auipc	ra,0xffffe
    80005712:	91c080e7          	jalr	-1764(ra) # 8000302a <argint>
    return -1;
    80005716:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005718:	02054763          	bltz	a0,80005746 <sys_write+0x5c>
    8000571c:	fd840593          	addi	a1,s0,-40
    80005720:	4505                	li	a0,1
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	92a080e7          	jalr	-1750(ra) # 8000304c <argaddr>
    return -1;
    8000572a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000572c:	00054d63          	bltz	a0,80005746 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005730:	fe442603          	lw	a2,-28(s0)
    80005734:	fd843583          	ld	a1,-40(s0)
    80005738:	fe843503          	ld	a0,-24(s0)
    8000573c:	fffff097          	auipc	ra,0xfffff
    80005740:	4fa080e7          	jalr	1274(ra) # 80004c36 <filewrite>
    80005744:	87aa                	mv	a5,a0
}
    80005746:	853e                	mv	a0,a5
    80005748:	70a2                	ld	ra,40(sp)
    8000574a:	7402                	ld	s0,32(sp)
    8000574c:	6145                	addi	sp,sp,48
    8000574e:	8082                	ret

0000000080005750 <sys_close>:
{
    80005750:	1101                	addi	sp,sp,-32
    80005752:	ec06                	sd	ra,24(sp)
    80005754:	e822                	sd	s0,16(sp)
    80005756:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005758:	fe040613          	addi	a2,s0,-32
    8000575c:	fec40593          	addi	a1,s0,-20
    80005760:	4501                	li	a0,0
    80005762:	00000097          	auipc	ra,0x0
    80005766:	cc2080e7          	jalr	-830(ra) # 80005424 <argfd>
    return -1;
    8000576a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000576c:	02054463          	bltz	a0,80005794 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005770:	ffffc097          	auipc	ra,0xffffc
    80005774:	55c080e7          	jalr	1372(ra) # 80001ccc <myproc>
    80005778:	fec42783          	lw	a5,-20(s0)
    8000577c:	07e9                	addi	a5,a5,26
    8000577e:	078e                	slli	a5,a5,0x3
    80005780:	97aa                	add	a5,a5,a0
    80005782:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005786:	fe043503          	ld	a0,-32(s0)
    8000578a:	fffff097          	auipc	ra,0xfffff
    8000578e:	2b0080e7          	jalr	688(ra) # 80004a3a <fileclose>
  return 0;
    80005792:	4781                	li	a5,0
}
    80005794:	853e                	mv	a0,a5
    80005796:	60e2                	ld	ra,24(sp)
    80005798:	6442                	ld	s0,16(sp)
    8000579a:	6105                	addi	sp,sp,32
    8000579c:	8082                	ret

000000008000579e <sys_fstat>:
{
    8000579e:	1101                	addi	sp,sp,-32
    800057a0:	ec06                	sd	ra,24(sp)
    800057a2:	e822                	sd	s0,16(sp)
    800057a4:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057a6:	fe840613          	addi	a2,s0,-24
    800057aa:	4581                	li	a1,0
    800057ac:	4501                	li	a0,0
    800057ae:	00000097          	auipc	ra,0x0
    800057b2:	c76080e7          	jalr	-906(ra) # 80005424 <argfd>
    return -1;
    800057b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057b8:	02054563          	bltz	a0,800057e2 <sys_fstat+0x44>
    800057bc:	fe040593          	addi	a1,s0,-32
    800057c0:	4505                	li	a0,1
    800057c2:	ffffe097          	auipc	ra,0xffffe
    800057c6:	88a080e7          	jalr	-1910(ra) # 8000304c <argaddr>
    return -1;
    800057ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057cc:	00054b63          	bltz	a0,800057e2 <sys_fstat+0x44>
  return filestat(f, st);
    800057d0:	fe043583          	ld	a1,-32(s0)
    800057d4:	fe843503          	ld	a0,-24(s0)
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	32a080e7          	jalr	810(ra) # 80004b02 <filestat>
    800057e0:	87aa                	mv	a5,a0
}
    800057e2:	853e                	mv	a0,a5
    800057e4:	60e2                	ld	ra,24(sp)
    800057e6:	6442                	ld	s0,16(sp)
    800057e8:	6105                	addi	sp,sp,32
    800057ea:	8082                	ret

00000000800057ec <sys_link>:
{
    800057ec:	7169                	addi	sp,sp,-304
    800057ee:	f606                	sd	ra,296(sp)
    800057f0:	f222                	sd	s0,288(sp)
    800057f2:	ee26                	sd	s1,280(sp)
    800057f4:	ea4a                	sd	s2,272(sp)
    800057f6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057f8:	08000613          	li	a2,128
    800057fc:	ed040593          	addi	a1,s0,-304
    80005800:	4501                	li	a0,0
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	86c080e7          	jalr	-1940(ra) # 8000306e <argstr>
    return -1;
    8000580a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000580c:	10054e63          	bltz	a0,80005928 <sys_link+0x13c>
    80005810:	08000613          	li	a2,128
    80005814:	f5040593          	addi	a1,s0,-176
    80005818:	4505                	li	a0,1
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	854080e7          	jalr	-1964(ra) # 8000306e <argstr>
    return -1;
    80005822:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005824:	10054263          	bltz	a0,80005928 <sys_link+0x13c>
  begin_op();
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	d46080e7          	jalr	-698(ra) # 8000456e <begin_op>
  if((ip = namei(old)) == 0){
    80005830:	ed040513          	addi	a0,s0,-304
    80005834:	fffff097          	auipc	ra,0xfffff
    80005838:	b1e080e7          	jalr	-1250(ra) # 80004352 <namei>
    8000583c:	84aa                	mv	s1,a0
    8000583e:	c551                	beqz	a0,800058ca <sys_link+0xde>
  ilock(ip);
    80005840:	ffffe097          	auipc	ra,0xffffe
    80005844:	35c080e7          	jalr	860(ra) # 80003b9c <ilock>
  if(ip->type == T_DIR){
    80005848:	04449703          	lh	a4,68(s1)
    8000584c:	4785                	li	a5,1
    8000584e:	08f70463          	beq	a4,a5,800058d6 <sys_link+0xea>
  ip->nlink++;
    80005852:	04a4d783          	lhu	a5,74(s1)
    80005856:	2785                	addiw	a5,a5,1
    80005858:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000585c:	8526                	mv	a0,s1
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	274080e7          	jalr	628(ra) # 80003ad2 <iupdate>
  iunlock(ip);
    80005866:	8526                	mv	a0,s1
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	3f6080e7          	jalr	1014(ra) # 80003c5e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005870:	fd040593          	addi	a1,s0,-48
    80005874:	f5040513          	addi	a0,s0,-176
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	af8080e7          	jalr	-1288(ra) # 80004370 <nameiparent>
    80005880:	892a                	mv	s2,a0
    80005882:	c935                	beqz	a0,800058f6 <sys_link+0x10a>
  ilock(dp);
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	318080e7          	jalr	792(ra) # 80003b9c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000588c:	00092703          	lw	a4,0(s2)
    80005890:	409c                	lw	a5,0(s1)
    80005892:	04f71d63          	bne	a4,a5,800058ec <sys_link+0x100>
    80005896:	40d0                	lw	a2,4(s1)
    80005898:	fd040593          	addi	a1,s0,-48
    8000589c:	854a                	mv	a0,s2
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	9f2080e7          	jalr	-1550(ra) # 80004290 <dirlink>
    800058a6:	04054363          	bltz	a0,800058ec <sys_link+0x100>
  iunlockput(dp);
    800058aa:	854a                	mv	a0,s2
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	552080e7          	jalr	1362(ra) # 80003dfe <iunlockput>
  iput(ip);
    800058b4:	8526                	mv	a0,s1
    800058b6:	ffffe097          	auipc	ra,0xffffe
    800058ba:	4a0080e7          	jalr	1184(ra) # 80003d56 <iput>
  end_op();
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	d30080e7          	jalr	-720(ra) # 800045ee <end_op>
  return 0;
    800058c6:	4781                	li	a5,0
    800058c8:	a085                	j	80005928 <sys_link+0x13c>
    end_op();
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	d24080e7          	jalr	-732(ra) # 800045ee <end_op>
    return -1;
    800058d2:	57fd                	li	a5,-1
    800058d4:	a891                	j	80005928 <sys_link+0x13c>
    iunlockput(ip);
    800058d6:	8526                	mv	a0,s1
    800058d8:	ffffe097          	auipc	ra,0xffffe
    800058dc:	526080e7          	jalr	1318(ra) # 80003dfe <iunlockput>
    end_op();
    800058e0:	fffff097          	auipc	ra,0xfffff
    800058e4:	d0e080e7          	jalr	-754(ra) # 800045ee <end_op>
    return -1;
    800058e8:	57fd                	li	a5,-1
    800058ea:	a83d                	j	80005928 <sys_link+0x13c>
    iunlockput(dp);
    800058ec:	854a                	mv	a0,s2
    800058ee:	ffffe097          	auipc	ra,0xffffe
    800058f2:	510080e7          	jalr	1296(ra) # 80003dfe <iunlockput>
  ilock(ip);
    800058f6:	8526                	mv	a0,s1
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	2a4080e7          	jalr	676(ra) # 80003b9c <ilock>
  ip->nlink--;
    80005900:	04a4d783          	lhu	a5,74(s1)
    80005904:	37fd                	addiw	a5,a5,-1
    80005906:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000590a:	8526                	mv	a0,s1
    8000590c:	ffffe097          	auipc	ra,0xffffe
    80005910:	1c6080e7          	jalr	454(ra) # 80003ad2 <iupdate>
  iunlockput(ip);
    80005914:	8526                	mv	a0,s1
    80005916:	ffffe097          	auipc	ra,0xffffe
    8000591a:	4e8080e7          	jalr	1256(ra) # 80003dfe <iunlockput>
  end_op();
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	cd0080e7          	jalr	-816(ra) # 800045ee <end_op>
  return -1;
    80005926:	57fd                	li	a5,-1
}
    80005928:	853e                	mv	a0,a5
    8000592a:	70b2                	ld	ra,296(sp)
    8000592c:	7412                	ld	s0,288(sp)
    8000592e:	64f2                	ld	s1,280(sp)
    80005930:	6952                	ld	s2,272(sp)
    80005932:	6155                	addi	sp,sp,304
    80005934:	8082                	ret

0000000080005936 <sys_unlink>:
{
    80005936:	7151                	addi	sp,sp,-240
    80005938:	f586                	sd	ra,232(sp)
    8000593a:	f1a2                	sd	s0,224(sp)
    8000593c:	eda6                	sd	s1,216(sp)
    8000593e:	e9ca                	sd	s2,208(sp)
    80005940:	e5ce                	sd	s3,200(sp)
    80005942:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005944:	08000613          	li	a2,128
    80005948:	f3040593          	addi	a1,s0,-208
    8000594c:	4501                	li	a0,0
    8000594e:	ffffd097          	auipc	ra,0xffffd
    80005952:	720080e7          	jalr	1824(ra) # 8000306e <argstr>
    80005956:	18054163          	bltz	a0,80005ad8 <sys_unlink+0x1a2>
  begin_op();
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	c14080e7          	jalr	-1004(ra) # 8000456e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005962:	fb040593          	addi	a1,s0,-80
    80005966:	f3040513          	addi	a0,s0,-208
    8000596a:	fffff097          	auipc	ra,0xfffff
    8000596e:	a06080e7          	jalr	-1530(ra) # 80004370 <nameiparent>
    80005972:	84aa                	mv	s1,a0
    80005974:	c979                	beqz	a0,80005a4a <sys_unlink+0x114>
  ilock(dp);
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	226080e7          	jalr	550(ra) # 80003b9c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000597e:	00003597          	auipc	a1,0x3
    80005982:	e0258593          	addi	a1,a1,-510 # 80008780 <syscalls+0x2b0>
    80005986:	fb040513          	addi	a0,s0,-80
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	6dc080e7          	jalr	1756(ra) # 80004066 <namecmp>
    80005992:	14050a63          	beqz	a0,80005ae6 <sys_unlink+0x1b0>
    80005996:	00003597          	auipc	a1,0x3
    8000599a:	df258593          	addi	a1,a1,-526 # 80008788 <syscalls+0x2b8>
    8000599e:	fb040513          	addi	a0,s0,-80
    800059a2:	ffffe097          	auipc	ra,0xffffe
    800059a6:	6c4080e7          	jalr	1732(ra) # 80004066 <namecmp>
    800059aa:	12050e63          	beqz	a0,80005ae6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800059ae:	f2c40613          	addi	a2,s0,-212
    800059b2:	fb040593          	addi	a1,s0,-80
    800059b6:	8526                	mv	a0,s1
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	6c8080e7          	jalr	1736(ra) # 80004080 <dirlookup>
    800059c0:	892a                	mv	s2,a0
    800059c2:	12050263          	beqz	a0,80005ae6 <sys_unlink+0x1b0>
  ilock(ip);
    800059c6:	ffffe097          	auipc	ra,0xffffe
    800059ca:	1d6080e7          	jalr	470(ra) # 80003b9c <ilock>
  if(ip->nlink < 1)
    800059ce:	04a91783          	lh	a5,74(s2)
    800059d2:	08f05263          	blez	a5,80005a56 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059d6:	04491703          	lh	a4,68(s2)
    800059da:	4785                	li	a5,1
    800059dc:	08f70563          	beq	a4,a5,80005a66 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800059e0:	4641                	li	a2,16
    800059e2:	4581                	li	a1,0
    800059e4:	fc040513          	addi	a0,s0,-64
    800059e8:	ffffb097          	auipc	ra,0xffffb
    800059ec:	2f8080e7          	jalr	760(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059f0:	4741                	li	a4,16
    800059f2:	f2c42683          	lw	a3,-212(s0)
    800059f6:	fc040613          	addi	a2,s0,-64
    800059fa:	4581                	li	a1,0
    800059fc:	8526                	mv	a0,s1
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	54a080e7          	jalr	1354(ra) # 80003f48 <writei>
    80005a06:	47c1                	li	a5,16
    80005a08:	0af51563          	bne	a0,a5,80005ab2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a0c:	04491703          	lh	a4,68(s2)
    80005a10:	4785                	li	a5,1
    80005a12:	0af70863          	beq	a4,a5,80005ac2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005a16:	8526                	mv	a0,s1
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	3e6080e7          	jalr	998(ra) # 80003dfe <iunlockput>
  ip->nlink--;
    80005a20:	04a95783          	lhu	a5,74(s2)
    80005a24:	37fd                	addiw	a5,a5,-1
    80005a26:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a2a:	854a                	mv	a0,s2
    80005a2c:	ffffe097          	auipc	ra,0xffffe
    80005a30:	0a6080e7          	jalr	166(ra) # 80003ad2 <iupdate>
  iunlockput(ip);
    80005a34:	854a                	mv	a0,s2
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	3c8080e7          	jalr	968(ra) # 80003dfe <iunlockput>
  end_op();
    80005a3e:	fffff097          	auipc	ra,0xfffff
    80005a42:	bb0080e7          	jalr	-1104(ra) # 800045ee <end_op>
  return 0;
    80005a46:	4501                	li	a0,0
    80005a48:	a84d                	j	80005afa <sys_unlink+0x1c4>
    end_op();
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	ba4080e7          	jalr	-1116(ra) # 800045ee <end_op>
    return -1;
    80005a52:	557d                	li	a0,-1
    80005a54:	a05d                	j	80005afa <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a56:	00003517          	auipc	a0,0x3
    80005a5a:	d5a50513          	addi	a0,a0,-678 # 800087b0 <syscalls+0x2e0>
    80005a5e:	ffffb097          	auipc	ra,0xffffb
    80005a62:	ae0080e7          	jalr	-1312(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a66:	04c92703          	lw	a4,76(s2)
    80005a6a:	02000793          	li	a5,32
    80005a6e:	f6e7f9e3          	bgeu	a5,a4,800059e0 <sys_unlink+0xaa>
    80005a72:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a76:	4741                	li	a4,16
    80005a78:	86ce                	mv	a3,s3
    80005a7a:	f1840613          	addi	a2,s0,-232
    80005a7e:	4581                	li	a1,0
    80005a80:	854a                	mv	a0,s2
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	3ce080e7          	jalr	974(ra) # 80003e50 <readi>
    80005a8a:	47c1                	li	a5,16
    80005a8c:	00f51b63          	bne	a0,a5,80005aa2 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a90:	f1845783          	lhu	a5,-232(s0)
    80005a94:	e7a1                	bnez	a5,80005adc <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a96:	29c1                	addiw	s3,s3,16
    80005a98:	04c92783          	lw	a5,76(s2)
    80005a9c:	fcf9ede3          	bltu	s3,a5,80005a76 <sys_unlink+0x140>
    80005aa0:	b781                	j	800059e0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005aa2:	00003517          	auipc	a0,0x3
    80005aa6:	d2650513          	addi	a0,a0,-730 # 800087c8 <syscalls+0x2f8>
    80005aaa:	ffffb097          	auipc	ra,0xffffb
    80005aae:	a94080e7          	jalr	-1388(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005ab2:	00003517          	auipc	a0,0x3
    80005ab6:	d2e50513          	addi	a0,a0,-722 # 800087e0 <syscalls+0x310>
    80005aba:	ffffb097          	auipc	ra,0xffffb
    80005abe:	a84080e7          	jalr	-1404(ra) # 8000053e <panic>
    dp->nlink--;
    80005ac2:	04a4d783          	lhu	a5,74(s1)
    80005ac6:	37fd                	addiw	a5,a5,-1
    80005ac8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005acc:	8526                	mv	a0,s1
    80005ace:	ffffe097          	auipc	ra,0xffffe
    80005ad2:	004080e7          	jalr	4(ra) # 80003ad2 <iupdate>
    80005ad6:	b781                	j	80005a16 <sys_unlink+0xe0>
    return -1;
    80005ad8:	557d                	li	a0,-1
    80005ada:	a005                	j	80005afa <sys_unlink+0x1c4>
    iunlockput(ip);
    80005adc:	854a                	mv	a0,s2
    80005ade:	ffffe097          	auipc	ra,0xffffe
    80005ae2:	320080e7          	jalr	800(ra) # 80003dfe <iunlockput>
  iunlockput(dp);
    80005ae6:	8526                	mv	a0,s1
    80005ae8:	ffffe097          	auipc	ra,0xffffe
    80005aec:	316080e7          	jalr	790(ra) # 80003dfe <iunlockput>
  end_op();
    80005af0:	fffff097          	auipc	ra,0xfffff
    80005af4:	afe080e7          	jalr	-1282(ra) # 800045ee <end_op>
  return -1;
    80005af8:	557d                	li	a0,-1
}
    80005afa:	70ae                	ld	ra,232(sp)
    80005afc:	740e                	ld	s0,224(sp)
    80005afe:	64ee                	ld	s1,216(sp)
    80005b00:	694e                	ld	s2,208(sp)
    80005b02:	69ae                	ld	s3,200(sp)
    80005b04:	616d                	addi	sp,sp,240
    80005b06:	8082                	ret

0000000080005b08 <sys_open>:

uint64
sys_open(void)
{
    80005b08:	7131                	addi	sp,sp,-192
    80005b0a:	fd06                	sd	ra,184(sp)
    80005b0c:	f922                	sd	s0,176(sp)
    80005b0e:	f526                	sd	s1,168(sp)
    80005b10:	f14a                	sd	s2,160(sp)
    80005b12:	ed4e                	sd	s3,152(sp)
    80005b14:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b16:	08000613          	li	a2,128
    80005b1a:	f5040593          	addi	a1,s0,-176
    80005b1e:	4501                	li	a0,0
    80005b20:	ffffd097          	auipc	ra,0xffffd
    80005b24:	54e080e7          	jalr	1358(ra) # 8000306e <argstr>
    return -1;
    80005b28:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b2a:	0c054163          	bltz	a0,80005bec <sys_open+0xe4>
    80005b2e:	f4c40593          	addi	a1,s0,-180
    80005b32:	4505                	li	a0,1
    80005b34:	ffffd097          	auipc	ra,0xffffd
    80005b38:	4f6080e7          	jalr	1270(ra) # 8000302a <argint>
    80005b3c:	0a054863          	bltz	a0,80005bec <sys_open+0xe4>

  begin_op();
    80005b40:	fffff097          	auipc	ra,0xfffff
    80005b44:	a2e080e7          	jalr	-1490(ra) # 8000456e <begin_op>

  if(omode & O_CREATE){
    80005b48:	f4c42783          	lw	a5,-180(s0)
    80005b4c:	2007f793          	andi	a5,a5,512
    80005b50:	cbdd                	beqz	a5,80005c06 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b52:	4681                	li	a3,0
    80005b54:	4601                	li	a2,0
    80005b56:	4589                	li	a1,2
    80005b58:	f5040513          	addi	a0,s0,-176
    80005b5c:	00000097          	auipc	ra,0x0
    80005b60:	972080e7          	jalr	-1678(ra) # 800054ce <create>
    80005b64:	892a                	mv	s2,a0
    if(ip == 0){
    80005b66:	c959                	beqz	a0,80005bfc <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b68:	04491703          	lh	a4,68(s2)
    80005b6c:	478d                	li	a5,3
    80005b6e:	00f71763          	bne	a4,a5,80005b7c <sys_open+0x74>
    80005b72:	04695703          	lhu	a4,70(s2)
    80005b76:	47a5                	li	a5,9
    80005b78:	0ce7ec63          	bltu	a5,a4,80005c50 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b7c:	fffff097          	auipc	ra,0xfffff
    80005b80:	e02080e7          	jalr	-510(ra) # 8000497e <filealloc>
    80005b84:	89aa                	mv	s3,a0
    80005b86:	10050263          	beqz	a0,80005c8a <sys_open+0x182>
    80005b8a:	00000097          	auipc	ra,0x0
    80005b8e:	902080e7          	jalr	-1790(ra) # 8000548c <fdalloc>
    80005b92:	84aa                	mv	s1,a0
    80005b94:	0e054663          	bltz	a0,80005c80 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b98:	04491703          	lh	a4,68(s2)
    80005b9c:	478d                	li	a5,3
    80005b9e:	0cf70463          	beq	a4,a5,80005c66 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005ba2:	4789                	li	a5,2
    80005ba4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ba8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005bac:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005bb0:	f4c42783          	lw	a5,-180(s0)
    80005bb4:	0017c713          	xori	a4,a5,1
    80005bb8:	8b05                	andi	a4,a4,1
    80005bba:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005bbe:	0037f713          	andi	a4,a5,3
    80005bc2:	00e03733          	snez	a4,a4
    80005bc6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005bca:	4007f793          	andi	a5,a5,1024
    80005bce:	c791                	beqz	a5,80005bda <sys_open+0xd2>
    80005bd0:	04491703          	lh	a4,68(s2)
    80005bd4:	4789                	li	a5,2
    80005bd6:	08f70f63          	beq	a4,a5,80005c74 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005bda:	854a                	mv	a0,s2
    80005bdc:	ffffe097          	auipc	ra,0xffffe
    80005be0:	082080e7          	jalr	130(ra) # 80003c5e <iunlock>
  end_op();
    80005be4:	fffff097          	auipc	ra,0xfffff
    80005be8:	a0a080e7          	jalr	-1526(ra) # 800045ee <end_op>

  return fd;
}
    80005bec:	8526                	mv	a0,s1
    80005bee:	70ea                	ld	ra,184(sp)
    80005bf0:	744a                	ld	s0,176(sp)
    80005bf2:	74aa                	ld	s1,168(sp)
    80005bf4:	790a                	ld	s2,160(sp)
    80005bf6:	69ea                	ld	s3,152(sp)
    80005bf8:	6129                	addi	sp,sp,192
    80005bfa:	8082                	ret
      end_op();
    80005bfc:	fffff097          	auipc	ra,0xfffff
    80005c00:	9f2080e7          	jalr	-1550(ra) # 800045ee <end_op>
      return -1;
    80005c04:	b7e5                	j	80005bec <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c06:	f5040513          	addi	a0,s0,-176
    80005c0a:	ffffe097          	auipc	ra,0xffffe
    80005c0e:	748080e7          	jalr	1864(ra) # 80004352 <namei>
    80005c12:	892a                	mv	s2,a0
    80005c14:	c905                	beqz	a0,80005c44 <sys_open+0x13c>
    ilock(ip);
    80005c16:	ffffe097          	auipc	ra,0xffffe
    80005c1a:	f86080e7          	jalr	-122(ra) # 80003b9c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c1e:	04491703          	lh	a4,68(s2)
    80005c22:	4785                	li	a5,1
    80005c24:	f4f712e3          	bne	a4,a5,80005b68 <sys_open+0x60>
    80005c28:	f4c42783          	lw	a5,-180(s0)
    80005c2c:	dba1                	beqz	a5,80005b7c <sys_open+0x74>
      iunlockput(ip);
    80005c2e:	854a                	mv	a0,s2
    80005c30:	ffffe097          	auipc	ra,0xffffe
    80005c34:	1ce080e7          	jalr	462(ra) # 80003dfe <iunlockput>
      end_op();
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	9b6080e7          	jalr	-1610(ra) # 800045ee <end_op>
      return -1;
    80005c40:	54fd                	li	s1,-1
    80005c42:	b76d                	j	80005bec <sys_open+0xe4>
      end_op();
    80005c44:	fffff097          	auipc	ra,0xfffff
    80005c48:	9aa080e7          	jalr	-1622(ra) # 800045ee <end_op>
      return -1;
    80005c4c:	54fd                	li	s1,-1
    80005c4e:	bf79                	j	80005bec <sys_open+0xe4>
    iunlockput(ip);
    80005c50:	854a                	mv	a0,s2
    80005c52:	ffffe097          	auipc	ra,0xffffe
    80005c56:	1ac080e7          	jalr	428(ra) # 80003dfe <iunlockput>
    end_op();
    80005c5a:	fffff097          	auipc	ra,0xfffff
    80005c5e:	994080e7          	jalr	-1644(ra) # 800045ee <end_op>
    return -1;
    80005c62:	54fd                	li	s1,-1
    80005c64:	b761                	j	80005bec <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c66:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c6a:	04691783          	lh	a5,70(s2)
    80005c6e:	02f99223          	sh	a5,36(s3)
    80005c72:	bf2d                	j	80005bac <sys_open+0xa4>
    itrunc(ip);
    80005c74:	854a                	mv	a0,s2
    80005c76:	ffffe097          	auipc	ra,0xffffe
    80005c7a:	034080e7          	jalr	52(ra) # 80003caa <itrunc>
    80005c7e:	bfb1                	j	80005bda <sys_open+0xd2>
      fileclose(f);
    80005c80:	854e                	mv	a0,s3
    80005c82:	fffff097          	auipc	ra,0xfffff
    80005c86:	db8080e7          	jalr	-584(ra) # 80004a3a <fileclose>
    iunlockput(ip);
    80005c8a:	854a                	mv	a0,s2
    80005c8c:	ffffe097          	auipc	ra,0xffffe
    80005c90:	172080e7          	jalr	370(ra) # 80003dfe <iunlockput>
    end_op();
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	95a080e7          	jalr	-1702(ra) # 800045ee <end_op>
    return -1;
    80005c9c:	54fd                	li	s1,-1
    80005c9e:	b7b9                	j	80005bec <sys_open+0xe4>

0000000080005ca0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ca0:	7175                	addi	sp,sp,-144
    80005ca2:	e506                	sd	ra,136(sp)
    80005ca4:	e122                	sd	s0,128(sp)
    80005ca6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ca8:	fffff097          	auipc	ra,0xfffff
    80005cac:	8c6080e7          	jalr	-1850(ra) # 8000456e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005cb0:	08000613          	li	a2,128
    80005cb4:	f7040593          	addi	a1,s0,-144
    80005cb8:	4501                	li	a0,0
    80005cba:	ffffd097          	auipc	ra,0xffffd
    80005cbe:	3b4080e7          	jalr	948(ra) # 8000306e <argstr>
    80005cc2:	02054963          	bltz	a0,80005cf4 <sys_mkdir+0x54>
    80005cc6:	4681                	li	a3,0
    80005cc8:	4601                	li	a2,0
    80005cca:	4585                	li	a1,1
    80005ccc:	f7040513          	addi	a0,s0,-144
    80005cd0:	fffff097          	auipc	ra,0xfffff
    80005cd4:	7fe080e7          	jalr	2046(ra) # 800054ce <create>
    80005cd8:	cd11                	beqz	a0,80005cf4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cda:	ffffe097          	auipc	ra,0xffffe
    80005cde:	124080e7          	jalr	292(ra) # 80003dfe <iunlockput>
  end_op();
    80005ce2:	fffff097          	auipc	ra,0xfffff
    80005ce6:	90c080e7          	jalr	-1780(ra) # 800045ee <end_op>
  return 0;
    80005cea:	4501                	li	a0,0
}
    80005cec:	60aa                	ld	ra,136(sp)
    80005cee:	640a                	ld	s0,128(sp)
    80005cf0:	6149                	addi	sp,sp,144
    80005cf2:	8082                	ret
    end_op();
    80005cf4:	fffff097          	auipc	ra,0xfffff
    80005cf8:	8fa080e7          	jalr	-1798(ra) # 800045ee <end_op>
    return -1;
    80005cfc:	557d                	li	a0,-1
    80005cfe:	b7fd                	j	80005cec <sys_mkdir+0x4c>

0000000080005d00 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d00:	7135                	addi	sp,sp,-160
    80005d02:	ed06                	sd	ra,152(sp)
    80005d04:	e922                	sd	s0,144(sp)
    80005d06:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d08:	fffff097          	auipc	ra,0xfffff
    80005d0c:	866080e7          	jalr	-1946(ra) # 8000456e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d10:	08000613          	li	a2,128
    80005d14:	f7040593          	addi	a1,s0,-144
    80005d18:	4501                	li	a0,0
    80005d1a:	ffffd097          	auipc	ra,0xffffd
    80005d1e:	354080e7          	jalr	852(ra) # 8000306e <argstr>
    80005d22:	04054a63          	bltz	a0,80005d76 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d26:	f6c40593          	addi	a1,s0,-148
    80005d2a:	4505                	li	a0,1
    80005d2c:	ffffd097          	auipc	ra,0xffffd
    80005d30:	2fe080e7          	jalr	766(ra) # 8000302a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d34:	04054163          	bltz	a0,80005d76 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d38:	f6840593          	addi	a1,s0,-152
    80005d3c:	4509                	li	a0,2
    80005d3e:	ffffd097          	auipc	ra,0xffffd
    80005d42:	2ec080e7          	jalr	748(ra) # 8000302a <argint>
     argint(1, &major) < 0 ||
    80005d46:	02054863          	bltz	a0,80005d76 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d4a:	f6841683          	lh	a3,-152(s0)
    80005d4e:	f6c41603          	lh	a2,-148(s0)
    80005d52:	458d                	li	a1,3
    80005d54:	f7040513          	addi	a0,s0,-144
    80005d58:	fffff097          	auipc	ra,0xfffff
    80005d5c:	776080e7          	jalr	1910(ra) # 800054ce <create>
     argint(2, &minor) < 0 ||
    80005d60:	c919                	beqz	a0,80005d76 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d62:	ffffe097          	auipc	ra,0xffffe
    80005d66:	09c080e7          	jalr	156(ra) # 80003dfe <iunlockput>
  end_op();
    80005d6a:	fffff097          	auipc	ra,0xfffff
    80005d6e:	884080e7          	jalr	-1916(ra) # 800045ee <end_op>
  return 0;
    80005d72:	4501                	li	a0,0
    80005d74:	a031                	j	80005d80 <sys_mknod+0x80>
    end_op();
    80005d76:	fffff097          	auipc	ra,0xfffff
    80005d7a:	878080e7          	jalr	-1928(ra) # 800045ee <end_op>
    return -1;
    80005d7e:	557d                	li	a0,-1
}
    80005d80:	60ea                	ld	ra,152(sp)
    80005d82:	644a                	ld	s0,144(sp)
    80005d84:	610d                	addi	sp,sp,160
    80005d86:	8082                	ret

0000000080005d88 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d88:	7135                	addi	sp,sp,-160
    80005d8a:	ed06                	sd	ra,152(sp)
    80005d8c:	e922                	sd	s0,144(sp)
    80005d8e:	e526                	sd	s1,136(sp)
    80005d90:	e14a                	sd	s2,128(sp)
    80005d92:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d94:	ffffc097          	auipc	ra,0xffffc
    80005d98:	f38080e7          	jalr	-200(ra) # 80001ccc <myproc>
    80005d9c:	892a                	mv	s2,a0
  
  begin_op();
    80005d9e:	ffffe097          	auipc	ra,0xffffe
    80005da2:	7d0080e7          	jalr	2000(ra) # 8000456e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005da6:	08000613          	li	a2,128
    80005daa:	f6040593          	addi	a1,s0,-160
    80005dae:	4501                	li	a0,0
    80005db0:	ffffd097          	auipc	ra,0xffffd
    80005db4:	2be080e7          	jalr	702(ra) # 8000306e <argstr>
    80005db8:	04054b63          	bltz	a0,80005e0e <sys_chdir+0x86>
    80005dbc:	f6040513          	addi	a0,s0,-160
    80005dc0:	ffffe097          	auipc	ra,0xffffe
    80005dc4:	592080e7          	jalr	1426(ra) # 80004352 <namei>
    80005dc8:	84aa                	mv	s1,a0
    80005dca:	c131                	beqz	a0,80005e0e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005dcc:	ffffe097          	auipc	ra,0xffffe
    80005dd0:	dd0080e7          	jalr	-560(ra) # 80003b9c <ilock>
  if(ip->type != T_DIR){
    80005dd4:	04449703          	lh	a4,68(s1)
    80005dd8:	4785                	li	a5,1
    80005dda:	04f71063          	bne	a4,a5,80005e1a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005dde:	8526                	mv	a0,s1
    80005de0:	ffffe097          	auipc	ra,0xffffe
    80005de4:	e7e080e7          	jalr	-386(ra) # 80003c5e <iunlock>
  iput(p->cwd);
    80005de8:	15093503          	ld	a0,336(s2)
    80005dec:	ffffe097          	auipc	ra,0xffffe
    80005df0:	f6a080e7          	jalr	-150(ra) # 80003d56 <iput>
  end_op();
    80005df4:	ffffe097          	auipc	ra,0xffffe
    80005df8:	7fa080e7          	jalr	2042(ra) # 800045ee <end_op>
  p->cwd = ip;
    80005dfc:	14993823          	sd	s1,336(s2)
  return 0;
    80005e00:	4501                	li	a0,0
}
    80005e02:	60ea                	ld	ra,152(sp)
    80005e04:	644a                	ld	s0,144(sp)
    80005e06:	64aa                	ld	s1,136(sp)
    80005e08:	690a                	ld	s2,128(sp)
    80005e0a:	610d                	addi	sp,sp,160
    80005e0c:	8082                	ret
    end_op();
    80005e0e:	ffffe097          	auipc	ra,0xffffe
    80005e12:	7e0080e7          	jalr	2016(ra) # 800045ee <end_op>
    return -1;
    80005e16:	557d                	li	a0,-1
    80005e18:	b7ed                	j	80005e02 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e1a:	8526                	mv	a0,s1
    80005e1c:	ffffe097          	auipc	ra,0xffffe
    80005e20:	fe2080e7          	jalr	-30(ra) # 80003dfe <iunlockput>
    end_op();
    80005e24:	ffffe097          	auipc	ra,0xffffe
    80005e28:	7ca080e7          	jalr	1994(ra) # 800045ee <end_op>
    return -1;
    80005e2c:	557d                	li	a0,-1
    80005e2e:	bfd1                	j	80005e02 <sys_chdir+0x7a>

0000000080005e30 <sys_exec>:

uint64
sys_exec(void)
{
    80005e30:	7145                	addi	sp,sp,-464
    80005e32:	e786                	sd	ra,456(sp)
    80005e34:	e3a2                	sd	s0,448(sp)
    80005e36:	ff26                	sd	s1,440(sp)
    80005e38:	fb4a                	sd	s2,432(sp)
    80005e3a:	f74e                	sd	s3,424(sp)
    80005e3c:	f352                	sd	s4,416(sp)
    80005e3e:	ef56                	sd	s5,408(sp)
    80005e40:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e42:	08000613          	li	a2,128
    80005e46:	f4040593          	addi	a1,s0,-192
    80005e4a:	4501                	li	a0,0
    80005e4c:	ffffd097          	auipc	ra,0xffffd
    80005e50:	222080e7          	jalr	546(ra) # 8000306e <argstr>
    return -1;
    80005e54:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e56:	0c054a63          	bltz	a0,80005f2a <sys_exec+0xfa>
    80005e5a:	e3840593          	addi	a1,s0,-456
    80005e5e:	4505                	li	a0,1
    80005e60:	ffffd097          	auipc	ra,0xffffd
    80005e64:	1ec080e7          	jalr	492(ra) # 8000304c <argaddr>
    80005e68:	0c054163          	bltz	a0,80005f2a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e6c:	10000613          	li	a2,256
    80005e70:	4581                	li	a1,0
    80005e72:	e4040513          	addi	a0,s0,-448
    80005e76:	ffffb097          	auipc	ra,0xffffb
    80005e7a:	e6a080e7          	jalr	-406(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e7e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e82:	89a6                	mv	s3,s1
    80005e84:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e86:	02000a13          	li	s4,32
    80005e8a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e8e:	00391513          	slli	a0,s2,0x3
    80005e92:	e3040593          	addi	a1,s0,-464
    80005e96:	e3843783          	ld	a5,-456(s0)
    80005e9a:	953e                	add	a0,a0,a5
    80005e9c:	ffffd097          	auipc	ra,0xffffd
    80005ea0:	0f4080e7          	jalr	244(ra) # 80002f90 <fetchaddr>
    80005ea4:	02054a63          	bltz	a0,80005ed8 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ea8:	e3043783          	ld	a5,-464(s0)
    80005eac:	c3b9                	beqz	a5,80005ef2 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005eae:	ffffb097          	auipc	ra,0xffffb
    80005eb2:	c46080e7          	jalr	-954(ra) # 80000af4 <kalloc>
    80005eb6:	85aa                	mv	a1,a0
    80005eb8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ebc:	cd11                	beqz	a0,80005ed8 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ebe:	6605                	lui	a2,0x1
    80005ec0:	e3043503          	ld	a0,-464(s0)
    80005ec4:	ffffd097          	auipc	ra,0xffffd
    80005ec8:	11e080e7          	jalr	286(ra) # 80002fe2 <fetchstr>
    80005ecc:	00054663          	bltz	a0,80005ed8 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ed0:	0905                	addi	s2,s2,1
    80005ed2:	09a1                	addi	s3,s3,8
    80005ed4:	fb491be3          	bne	s2,s4,80005e8a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ed8:	10048913          	addi	s2,s1,256
    80005edc:	6088                	ld	a0,0(s1)
    80005ede:	c529                	beqz	a0,80005f28 <sys_exec+0xf8>
    kfree(argv[i]);
    80005ee0:	ffffb097          	auipc	ra,0xffffb
    80005ee4:	b18080e7          	jalr	-1256(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ee8:	04a1                	addi	s1,s1,8
    80005eea:	ff2499e3          	bne	s1,s2,80005edc <sys_exec+0xac>
  return -1;
    80005eee:	597d                	li	s2,-1
    80005ef0:	a82d                	j	80005f2a <sys_exec+0xfa>
      argv[i] = 0;
    80005ef2:	0a8e                	slli	s5,s5,0x3
    80005ef4:	fc040793          	addi	a5,s0,-64
    80005ef8:	9abe                	add	s5,s5,a5
    80005efa:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005efe:	e4040593          	addi	a1,s0,-448
    80005f02:	f4040513          	addi	a0,s0,-192
    80005f06:	fffff097          	auipc	ra,0xfffff
    80005f0a:	194080e7          	jalr	404(ra) # 8000509a <exec>
    80005f0e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f10:	10048993          	addi	s3,s1,256
    80005f14:	6088                	ld	a0,0(s1)
    80005f16:	c911                	beqz	a0,80005f2a <sys_exec+0xfa>
    kfree(argv[i]);
    80005f18:	ffffb097          	auipc	ra,0xffffb
    80005f1c:	ae0080e7          	jalr	-1312(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f20:	04a1                	addi	s1,s1,8
    80005f22:	ff3499e3          	bne	s1,s3,80005f14 <sys_exec+0xe4>
    80005f26:	a011                	j	80005f2a <sys_exec+0xfa>
  return -1;
    80005f28:	597d                	li	s2,-1
}
    80005f2a:	854a                	mv	a0,s2
    80005f2c:	60be                	ld	ra,456(sp)
    80005f2e:	641e                	ld	s0,448(sp)
    80005f30:	74fa                	ld	s1,440(sp)
    80005f32:	795a                	ld	s2,432(sp)
    80005f34:	79ba                	ld	s3,424(sp)
    80005f36:	7a1a                	ld	s4,416(sp)
    80005f38:	6afa                	ld	s5,408(sp)
    80005f3a:	6179                	addi	sp,sp,464
    80005f3c:	8082                	ret

0000000080005f3e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f3e:	7139                	addi	sp,sp,-64
    80005f40:	fc06                	sd	ra,56(sp)
    80005f42:	f822                	sd	s0,48(sp)
    80005f44:	f426                	sd	s1,40(sp)
    80005f46:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f48:	ffffc097          	auipc	ra,0xffffc
    80005f4c:	d84080e7          	jalr	-636(ra) # 80001ccc <myproc>
    80005f50:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f52:	fd840593          	addi	a1,s0,-40
    80005f56:	4501                	li	a0,0
    80005f58:	ffffd097          	auipc	ra,0xffffd
    80005f5c:	0f4080e7          	jalr	244(ra) # 8000304c <argaddr>
    return -1;
    80005f60:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f62:	0e054063          	bltz	a0,80006042 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f66:	fc840593          	addi	a1,s0,-56
    80005f6a:	fd040513          	addi	a0,s0,-48
    80005f6e:	fffff097          	auipc	ra,0xfffff
    80005f72:	dfc080e7          	jalr	-516(ra) # 80004d6a <pipealloc>
    return -1;
    80005f76:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f78:	0c054563          	bltz	a0,80006042 <sys_pipe+0x104>
  fd0 = -1;
    80005f7c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f80:	fd043503          	ld	a0,-48(s0)
    80005f84:	fffff097          	auipc	ra,0xfffff
    80005f88:	508080e7          	jalr	1288(ra) # 8000548c <fdalloc>
    80005f8c:	fca42223          	sw	a0,-60(s0)
    80005f90:	08054c63          	bltz	a0,80006028 <sys_pipe+0xea>
    80005f94:	fc843503          	ld	a0,-56(s0)
    80005f98:	fffff097          	auipc	ra,0xfffff
    80005f9c:	4f4080e7          	jalr	1268(ra) # 8000548c <fdalloc>
    80005fa0:	fca42023          	sw	a0,-64(s0)
    80005fa4:	06054863          	bltz	a0,80006014 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fa8:	4691                	li	a3,4
    80005faa:	fc440613          	addi	a2,s0,-60
    80005fae:	fd843583          	ld	a1,-40(s0)
    80005fb2:	68a8                	ld	a0,80(s1)
    80005fb4:	ffffb097          	auipc	ra,0xffffb
    80005fb8:	6be080e7          	jalr	1726(ra) # 80001672 <copyout>
    80005fbc:	02054063          	bltz	a0,80005fdc <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005fc0:	4691                	li	a3,4
    80005fc2:	fc040613          	addi	a2,s0,-64
    80005fc6:	fd843583          	ld	a1,-40(s0)
    80005fca:	0591                	addi	a1,a1,4
    80005fcc:	68a8                	ld	a0,80(s1)
    80005fce:	ffffb097          	auipc	ra,0xffffb
    80005fd2:	6a4080e7          	jalr	1700(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fd6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fd8:	06055563          	bgez	a0,80006042 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005fdc:	fc442783          	lw	a5,-60(s0)
    80005fe0:	07e9                	addi	a5,a5,26
    80005fe2:	078e                	slli	a5,a5,0x3
    80005fe4:	97a6                	add	a5,a5,s1
    80005fe6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005fea:	fc042503          	lw	a0,-64(s0)
    80005fee:	0569                	addi	a0,a0,26
    80005ff0:	050e                	slli	a0,a0,0x3
    80005ff2:	9526                	add	a0,a0,s1
    80005ff4:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ff8:	fd043503          	ld	a0,-48(s0)
    80005ffc:	fffff097          	auipc	ra,0xfffff
    80006000:	a3e080e7          	jalr	-1474(ra) # 80004a3a <fileclose>
    fileclose(wf);
    80006004:	fc843503          	ld	a0,-56(s0)
    80006008:	fffff097          	auipc	ra,0xfffff
    8000600c:	a32080e7          	jalr	-1486(ra) # 80004a3a <fileclose>
    return -1;
    80006010:	57fd                	li	a5,-1
    80006012:	a805                	j	80006042 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006014:	fc442783          	lw	a5,-60(s0)
    80006018:	0007c863          	bltz	a5,80006028 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000601c:	01a78513          	addi	a0,a5,26
    80006020:	050e                	slli	a0,a0,0x3
    80006022:	9526                	add	a0,a0,s1
    80006024:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006028:	fd043503          	ld	a0,-48(s0)
    8000602c:	fffff097          	auipc	ra,0xfffff
    80006030:	a0e080e7          	jalr	-1522(ra) # 80004a3a <fileclose>
    fileclose(wf);
    80006034:	fc843503          	ld	a0,-56(s0)
    80006038:	fffff097          	auipc	ra,0xfffff
    8000603c:	a02080e7          	jalr	-1534(ra) # 80004a3a <fileclose>
    return -1;
    80006040:	57fd                	li	a5,-1
}
    80006042:	853e                	mv	a0,a5
    80006044:	70e2                	ld	ra,56(sp)
    80006046:	7442                	ld	s0,48(sp)
    80006048:	74a2                	ld	s1,40(sp)
    8000604a:	6121                	addi	sp,sp,64
    8000604c:	8082                	ret
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
    80006090:	dcdfc0ef          	jal	ra,80002e5c <kerneltrap>
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
    8000612c:	b72080e7          	jalr	-1166(ra) # 80001c9a <cpuid>
  
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
    80006164:	b3a080e7          	jalr	-1222(ra) # 80001c9a <cpuid>
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
    8000618c:	b12080e7          	jalr	-1262(ra) # 80001c9a <cpuid>
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
    80006216:	468080e7          	jalr	1128(ra) # 8000267a <wakeup>
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
    80006456:	08a080e7          	jalr	138(ra) # 800024dc <sleep>
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
    800065a0:	f40080e7          	jalr	-192(ra) # 800024dc <sleep>
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
    800066de:	fa0080e7          	jalr	-96(ra) # 8000267a <wakeup>

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
