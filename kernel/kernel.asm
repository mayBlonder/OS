
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
    80000068:	05c78793          	addi	a5,a5,92 # 800060c0 <timervec>
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
    80000130:	832080e7          	jalr	-1998(ra) # 8000295e <either_copyin>
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
    800001d8:	2fa080e7          	jalr	762(ra) # 800024ce <sleep>
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
    80000214:	6f8080e7          	jalr	1784(ra) # 80002908 <either_copyout>
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
    800002f6:	6c2080e7          	jalr	1730(ra) # 800029b4 <procdump>
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
    8000044a:	226080e7          	jalr	550(ra) # 8000266c <wakeup>
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
    800008a4:	dcc080e7          	jalr	-564(ra) # 8000266c <wakeup>
    
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
    80000930:	ba2080e7          	jalr	-1118(ra) # 800024ce <sleep>
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
    80000ed8:	cd4080e7          	jalr	-812(ra) # 80002ba8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	224080e7          	jalr	548(ra) # 80006100 <plicinithart>
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
    80000f50:	c34080e7          	jalr	-972(ra) # 80002b80 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	c54080e7          	jalr	-940(ra) # 80002ba8 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	18e080e7          	jalr	398(ra) # 800060ea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	19c080e7          	jalr	412(ra) # 80006100 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	37e080e7          	jalr	894(ra) # 800032ea <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	a0e080e7          	jalr	-1522(ra) # 80003982 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	9b8080e7          	jalr	-1608(ra) # 80004934 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	29e080e7          	jalr	670(ra) # 80006222 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	0c2080e7          	jalr	194(ra) # 8000204e <userinit>
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
    8000185e:	eac080e7          	jalr	-340(ra) # 80006706 <cas>
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
    80001d28:	b7c7a783          	lw	a5,-1156(a5) # 800088a0 <first.1725>
    80001d2c:	eb89                	bnez	a5,80001d3e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001d2e:	00001097          	auipc	ra,0x1
    80001d32:	e92080e7          	jalr	-366(ra) # 80002bc0 <usertrapret>
}
    80001d36:	60a2                	ld	ra,8(sp)
    80001d38:	6402                	ld	s0,0(sp)
    80001d3a:	0141                	addi	sp,sp,16
    80001d3c:	8082                	ret
    first = 0;
    80001d3e:	00007797          	auipc	a5,0x7
    80001d42:	b607a123          	sw	zero,-1182(a5) # 800088a0 <first.1725>
    fsinit(ROOTDEV);
    80001d46:	4505                	li	a0,1
    80001d48:	00002097          	auipc	ra,0x2
    80001d4c:	bba080e7          	jalr	-1094(ra) # 80003902 <fsinit>
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
    80001d76:	994080e7          	jalr	-1644(ra) # 80006706 <cas>
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
  remove(&zombie_list, p); 
    80001ec8:	85a6                	mv	a1,s1
    80001eca:	00007517          	auipc	a0,0x7
    80001ece:	a0650513          	addi	a0,a0,-1530 # 800088d0 <zombie_list>
    80001ed2:	00000097          	auipc	ra,0x0
    80001ed6:	a7c080e7          	jalr	-1412(ra) # 8000194e <remove>
  append(&unused_list, p); 
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
    80001f16:	12f90a63          	beq	s2,a5,8000204a <allocproc+0x154>
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
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001fa8:	fffff097          	auipc	ra,0xfffff
    80001fac:	b4c080e7          	jalr	-1204(ra) # 80000af4 <kalloc>
    80001fb0:	8aaa                	mv	s5,a0
    80001fb2:	04aa3c23          	sd	a0,88(s4)
    80001fb6:	c135                	beqz	a0,8000201a <allocproc+0x124>
  p->pagetable = proc_pagetable(p);
    80001fb8:	8526                	mv	a0,s1
    80001fba:	00000097          	auipc	ra,0x0
    80001fbe:	dd2080e7          	jalr	-558(ra) # 80001d8c <proc_pagetable>
    80001fc2:	8a2a                	mv	s4,a0
    80001fc4:	19000793          	li	a5,400
    80001fc8:	02f90733          	mul	a4,s2,a5
    80001fcc:	00010797          	auipc	a5,0x10
    80001fd0:	84478793          	addi	a5,a5,-1980 # 80011810 <proc>
    80001fd4:	97ba                	add	a5,a5,a4
    80001fd6:	eba8                	sd	a0,80(a5)
  if(p->pagetable == 0){
    80001fd8:	cd29                	beqz	a0,80002032 <allocproc+0x13c>
  memset(&p->context, 0, sizeof(p->context));
    80001fda:	06098513          	addi	a0,s3,96
    80001fde:	00010997          	auipc	s3,0x10
    80001fe2:	83298993          	addi	s3,s3,-1998 # 80011810 <proc>
    80001fe6:	07000613          	li	a2,112
    80001fea:	4581                	li	a1,0
    80001fec:	954e                	add	a0,a0,s3
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	cf2080e7          	jalr	-782(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001ff6:	19000793          	li	a5,400
    80001ffa:	02f90933          	mul	s2,s2,a5
    80001ffe:	994e                	add	s2,s2,s3
    80002000:	00000797          	auipc	a5,0x0
    80002004:	d0c78793          	addi	a5,a5,-756 # 80001d0c <forkret>
    80002008:	06f93023          	sd	a5,96(s2)
  p->context.sp = p->kstack + PGSIZE;
    8000200c:	04093783          	ld	a5,64(s2)
    80002010:	6705                	lui	a4,0x1
    80002012:	97ba                	add	a5,a5,a4
    80002014:	06f93423          	sd	a5,104(s2)
  return p;
    80002018:	b789                	j	80001f5a <allocproc+0x64>
    freeproc(p);
    8000201a:	8526                	mv	a0,s1
    8000201c:	00000097          	auipc	ra,0x0
    80002020:	e5e080e7          	jalr	-418(ra) # 80001e7a <freeproc>
    release(&p->lock);
    80002024:	8526                	mv	a0,s1
    80002026:	fffff097          	auipc	ra,0xfffff
    8000202a:	c72080e7          	jalr	-910(ra) # 80000c98 <release>
    return 0;
    8000202e:	84d6                	mv	s1,s5
    80002030:	b72d                	j	80001f5a <allocproc+0x64>
    freeproc(p);
    80002032:	8526                	mv	a0,s1
    80002034:	00000097          	auipc	ra,0x0
    80002038:	e46080e7          	jalr	-442(ra) # 80001e7a <freeproc>
    release(&p->lock);
    8000203c:	8526                	mv	a0,s1
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	c5a080e7          	jalr	-934(ra) # 80000c98 <release>
    return 0;
    80002046:	84d2                	mv	s1,s4
    80002048:	bf09                	j	80001f5a <allocproc+0x64>
  return 0;
    8000204a:	4481                	li	s1,0
    8000204c:	b739                	j	80001f5a <allocproc+0x64>

000000008000204e <userinit>:
{
    8000204e:	1101                	addi	sp,sp,-32
    80002050:	ec06                	sd	ra,24(sp)
    80002052:	e822                	sd	s0,16(sp)
    80002054:	e426                	sd	s1,8(sp)
    80002056:	1000                	addi	s0,sp,32
  p = allocproc();
    80002058:	00000097          	auipc	ra,0x0
    8000205c:	e9e080e7          	jalr	-354(ra) # 80001ef6 <allocproc>
    80002060:	84aa                	mv	s1,a0
  initproc = p;
    80002062:	00007797          	auipc	a5,0x7
    80002066:	fca7b323          	sd	a0,-58(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000206a:	03400613          	li	a2,52
    8000206e:	00007597          	auipc	a1,0x7
    80002072:	8a258593          	addi	a1,a1,-1886 # 80008910 <initcode>
    80002076:	6928                	ld	a0,80(a0)
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	2f0080e7          	jalr	752(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80002080:	6785                	lui	a5,0x1
    80002082:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80002084:	6cb8                	ld	a4,88(s1)
    80002086:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    8000208a:	6cb8                	ld	a4,88(s1)
    8000208c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    8000208e:	4641                	li	a2,16
    80002090:	00006597          	auipc	a1,0x6
    80002094:	1f858593          	addi	a1,a1,504 # 80008288 <digits+0x248>
    80002098:	15848513          	addi	a0,s1,344
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	d96080e7          	jalr	-618(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800020a4:	00006517          	auipc	a0,0x6
    800020a8:	1f450513          	addi	a0,a0,500 # 80008298 <digits+0x258>
    800020ac:	00002097          	auipc	ra,0x2
    800020b0:	284080e7          	jalr	644(ra) # 80004330 <namei>
    800020b4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    800020b8:	478d                	li	a5,3
    800020ba:	cc9c                	sw	a5,24(s1)
  append(l, p);
    800020bc:	85a6                	mv	a1,s1
    800020be:	0000f517          	auipc	a0,0xf
    800020c2:	26a50513          	addi	a0,a0,618 # 80011328 <cpus+0x88>
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	7c0080e7          	jalr	1984(ra) # 80001886 <append>
  release(&p->lock);
    800020ce:	8526                	mv	a0,s1
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	bc8080e7          	jalr	-1080(ra) # 80000c98 <release>
}
    800020d8:	60e2                	ld	ra,24(sp)
    800020da:	6442                	ld	s0,16(sp)
    800020dc:	64a2                	ld	s1,8(sp)
    800020de:	6105                	addi	sp,sp,32
    800020e0:	8082                	ret

00000000800020e2 <growproc>:
{
    800020e2:	1101                	addi	sp,sp,-32
    800020e4:	ec06                	sd	ra,24(sp)
    800020e6:	e822                	sd	s0,16(sp)
    800020e8:	e426                	sd	s1,8(sp)
    800020ea:	e04a                	sd	s2,0(sp)
    800020ec:	1000                	addi	s0,sp,32
    800020ee:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800020f0:	00000097          	auipc	ra,0x0
    800020f4:	bde080e7          	jalr	-1058(ra) # 80001cce <myproc>
    800020f8:	892a                	mv	s2,a0
  sz = p->sz;
    800020fa:	652c                	ld	a1,72(a0)
    800020fc:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002100:	00904f63          	bgtz	s1,8000211e <growproc+0x3c>
  } else if(n < 0){
    80002104:	0204cc63          	bltz	s1,8000213c <growproc+0x5a>
  p->sz = sz;
    80002108:	1602                	slli	a2,a2,0x20
    8000210a:	9201                	srli	a2,a2,0x20
    8000210c:	04c93423          	sd	a2,72(s2)
  return 0;
    80002110:	4501                	li	a0,0
}
    80002112:	60e2                	ld	ra,24(sp)
    80002114:	6442                	ld	s0,16(sp)
    80002116:	64a2                	ld	s1,8(sp)
    80002118:	6902                	ld	s2,0(sp)
    8000211a:	6105                	addi	sp,sp,32
    8000211c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000211e:	9e25                	addw	a2,a2,s1
    80002120:	1602                	slli	a2,a2,0x20
    80002122:	9201                	srli	a2,a2,0x20
    80002124:	1582                	slli	a1,a1,0x20
    80002126:	9181                	srli	a1,a1,0x20
    80002128:	6928                	ld	a0,80(a0)
    8000212a:	fffff097          	auipc	ra,0xfffff
    8000212e:	2f8080e7          	jalr	760(ra) # 80001422 <uvmalloc>
    80002132:	0005061b          	sext.w	a2,a0
    80002136:	fa69                	bnez	a2,80002108 <growproc+0x26>
      return -1;
    80002138:	557d                	li	a0,-1
    8000213a:	bfe1                	j	80002112 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000213c:	9e25                	addw	a2,a2,s1
    8000213e:	1602                	slli	a2,a2,0x20
    80002140:	9201                	srli	a2,a2,0x20
    80002142:	1582                	slli	a1,a1,0x20
    80002144:	9181                	srli	a1,a1,0x20
    80002146:	6928                	ld	a0,80(a0)
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	292080e7          	jalr	658(ra) # 800013da <uvmdealloc>
    80002150:	0005061b          	sext.w	a2,a0
    80002154:	bf55                	j	80002108 <growproc+0x26>

0000000080002156 <fork>:
{
    80002156:	7139                	addi	sp,sp,-64
    80002158:	fc06                	sd	ra,56(sp)
    8000215a:	f822                	sd	s0,48(sp)
    8000215c:	f426                	sd	s1,40(sp)
    8000215e:	f04a                	sd	s2,32(sp)
    80002160:	ec4e                	sd	s3,24(sp)
    80002162:	e852                	sd	s4,16(sp)
    80002164:	e456                	sd	s5,8(sp)
    80002166:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002168:	00000097          	auipc	ra,0x0
    8000216c:	b66080e7          	jalr	-1178(ra) # 80001cce <myproc>
    80002170:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80002172:	00000097          	auipc	ra,0x0
    80002176:	d84080e7          	jalr	-636(ra) # 80001ef6 <allocproc>
    8000217a:	14050963          	beqz	a0,800022cc <fork+0x176>
    8000217e:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002180:	0489b603          	ld	a2,72(s3)
    80002184:	692c                	ld	a1,80(a0)
    80002186:	0509b503          	ld	a0,80(s3)
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	3e4080e7          	jalr	996(ra) # 8000156e <uvmcopy>
    80002192:	04054663          	bltz	a0,800021de <fork+0x88>
  np->sz = p->sz;
    80002196:	0489b783          	ld	a5,72(s3)
    8000219a:	04f93423          	sd	a5,72(s2)
  *(np->trapframe) = *(p->trapframe);
    8000219e:	0589b683          	ld	a3,88(s3)
    800021a2:	87b6                	mv	a5,a3
    800021a4:	05893703          	ld	a4,88(s2)
    800021a8:	12068693          	addi	a3,a3,288
    800021ac:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800021b0:	6788                	ld	a0,8(a5)
    800021b2:	6b8c                	ld	a1,16(a5)
    800021b4:	6f90                	ld	a2,24(a5)
    800021b6:	01073023          	sd	a6,0(a4)
    800021ba:	e708                	sd	a0,8(a4)
    800021bc:	eb0c                	sd	a1,16(a4)
    800021be:	ef10                	sd	a2,24(a4)
    800021c0:	02078793          	addi	a5,a5,32
    800021c4:	02070713          	addi	a4,a4,32
    800021c8:	fed792e3          	bne	a5,a3,800021ac <fork+0x56>
  np->trapframe->a0 = 0;
    800021cc:	05893783          	ld	a5,88(s2)
    800021d0:	0607b823          	sd	zero,112(a5)
    800021d4:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    800021d8:	15000a13          	li	s4,336
    800021dc:	a03d                	j	8000220a <fork+0xb4>
    freeproc(np);
    800021de:	854a                	mv	a0,s2
    800021e0:	00000097          	auipc	ra,0x0
    800021e4:	c9a080e7          	jalr	-870(ra) # 80001e7a <freeproc>
    release(&np->lock);
    800021e8:	854a                	mv	a0,s2
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	aae080e7          	jalr	-1362(ra) # 80000c98 <release>
    return -1;
    800021f2:	5afd                	li	s5,-1
    800021f4:	a0d1                	j	800022b8 <fork+0x162>
      np->ofile[i] = filedup(p->ofile[i]);
    800021f6:	00002097          	auipc	ra,0x2
    800021fa:	7d0080e7          	jalr	2000(ra) # 800049c6 <filedup>
    800021fe:	009907b3          	add	a5,s2,s1
    80002202:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002204:	04a1                	addi	s1,s1,8
    80002206:	01448763          	beq	s1,s4,80002214 <fork+0xbe>
    if(p->ofile[i])
    8000220a:	009987b3          	add	a5,s3,s1
    8000220e:	6388                	ld	a0,0(a5)
    80002210:	f17d                	bnez	a0,800021f6 <fork+0xa0>
    80002212:	bfcd                	j	80002204 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002214:	1509b503          	ld	a0,336(s3)
    80002218:	00002097          	auipc	ra,0x2
    8000221c:	924080e7          	jalr	-1756(ra) # 80003b3c <idup>
    80002220:	14a93823          	sd	a0,336(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002224:	4641                	li	a2,16
    80002226:	15898593          	addi	a1,s3,344
    8000222a:	15890513          	addi	a0,s2,344
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	c04080e7          	jalr	-1020(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002236:	03092a83          	lw	s5,48(s2)
  release(&np->lock);
    8000223a:	854a                	mv	a0,s2
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	a5c080e7          	jalr	-1444(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002244:	0000f497          	auipc	s1,0xf
    80002248:	05c48493          	addi	s1,s1,92 # 800112a0 <cpus>
    8000224c:	0000fa17          	auipc	s4,0xf
    80002250:	5aca0a13          	addi	s4,s4,1452 # 800117f8 <wait_lock>
    80002254:	8552                	mv	a0,s4
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	98e080e7          	jalr	-1650(ra) # 80000be4 <acquire>
  np->parent = p;
    8000225e:	03393c23          	sd	s3,56(s2)
  release(&wait_lock);
    80002262:	8552                	mv	a0,s4
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	a34080e7          	jalr	-1484(ra) # 80000c98 <release>
  acquire(&np->lock);
    8000226c:	854a                	mv	a0,s2
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	976080e7          	jalr	-1674(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002276:	478d                	li	a5,3
    80002278:	00f92c23          	sw	a5,24(s2)
  np->last_cpu = p->last_cpu;
    8000227c:	1689a503          	lw	a0,360(s3)
    80002280:	16a92423          	sw	a0,360(s2)
  inc_cpu(&cpus[np->last_cpu]);
    80002284:	0a800993          	li	s3,168
    80002288:	03350533          	mul	a0,a0,s3
    8000228c:	9526                	add	a0,a0,s1
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	5b0080e7          	jalr	1456(ra) # 8000183e <inc_cpu>
  append(&(cpus[np->last_cpu].runnable_list), np); // admit the new process to the father’s current CPU’s ready list
    80002296:	16892503          	lw	a0,360(s2)
    8000229a:	03350533          	mul	a0,a0,s3
    8000229e:	08850513          	addi	a0,a0,136
    800022a2:	85ca                	mv	a1,s2
    800022a4:	9526                	add	a0,a0,s1
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	5e0080e7          	jalr	1504(ra) # 80001886 <append>
  release(&np->lock);
    800022ae:	854a                	mv	a0,s2
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	9e8080e7          	jalr	-1560(ra) # 80000c98 <release>
}
    800022b8:	8556                	mv	a0,s5
    800022ba:	70e2                	ld	ra,56(sp)
    800022bc:	7442                	ld	s0,48(sp)
    800022be:	74a2                	ld	s1,40(sp)
    800022c0:	7902                	ld	s2,32(sp)
    800022c2:	69e2                	ld	s3,24(sp)
    800022c4:	6a42                	ld	s4,16(sp)
    800022c6:	6aa2                	ld	s5,8(sp)
    800022c8:	6121                	addi	sp,sp,64
    800022ca:	8082                	ret
    return -1;
    800022cc:	5afd                	li	s5,-1
    800022ce:	b7ed                	j	800022b8 <fork+0x162>

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
    800022ec:	0000fb17          	auipc	s6,0xf
    800022f0:	fb4b0b13          	addi	s6,s6,-76 # 800112a0 <cpus>
    800022f4:	0a800793          	li	a5,168
    800022f8:	02f707b3          	mul	a5,a4,a5
    800022fc:	00fb06b3          	add	a3,s6,a5
    80002300:	0006b023          	sd	zero,0(a3)
        remove(&(c->runnable_list), p);
    80002304:	08878b93          	addi	s7,a5,136
    80002308:	9bda                	add	s7,s7,s6
        swtch(&c->context, &p->context);
    8000230a:	07a1                	addi	a5,a5,8
    8000230c:	9b3e                	add	s6,s6,a5
    while(!(c->runnable_list.head == -1)) {
    8000230e:	89b6                	mv	s3,a3
      if(p->state == RUNNABLE) {
    80002310:	0000fa17          	auipc	s4,0xf
    80002314:	500a0a13          	addi	s4,s4,1280 # 80011810 <proc>
    80002318:	19000a93          	li	s5,400
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000231c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002320:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002324:	10079073          	csrw	sstatus,a5
    80002328:	490d                	li	s2,3
    while(!(c->runnable_list.head == -1)) {
    8000232a:	0889a783          	lw	a5,136(s3)
    8000232e:	56fd                	li	a3,-1
      if(p->state == RUNNABLE) {
    80002330:	03578733          	mul	a4,a5,s5
    80002334:	9752                	add	a4,a4,s4
    while(!(c->runnable_list.head == -1)) {
    80002336:	fed783e3          	beq	a5,a3,8000231c <scheduler+0x4c>
      if(p->state == RUNNABLE) {
    8000233a:	4f10                	lw	a2,24(a4)
    8000233c:	ff261de3          	bne	a2,s2,80002336 <scheduler+0x66>
    80002340:	035784b3          	mul	s1,a5,s5
      p = &proc[c->runnable_list.head];
    80002344:	01448c33          	add	s8,s1,s4
        acquire(&p->lock);
    80002348:	8562                	mv	a0,s8
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	89a080e7          	jalr	-1894(ra) # 80000be4 <acquire>
        remove(&(c->runnable_list), p);
    80002352:	85e2                	mv	a1,s8
    80002354:	855e                	mv	a0,s7
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	5f8080e7          	jalr	1528(ra) # 8000194e <remove>
        p->state = RUNNING;
    8000235e:	4791                	li	a5,4
    80002360:	00fc2c23          	sw	a5,24(s8)
        c->proc = p;
    80002364:	0189b023          	sd	s8,0(s3)
        p->last_cpu = c->cpu_id;
    80002368:	0849a783          	lw	a5,132(s3)
    8000236c:	16fc2423          	sw	a5,360(s8)
        swtch(&c->context, &p->context);
    80002370:	06048593          	addi	a1,s1,96
    80002374:	95d2                	add	a1,a1,s4
    80002376:	855a                	mv	a0,s6
    80002378:	00000097          	auipc	ra,0x0
    8000237c:	79e080e7          	jalr	1950(ra) # 80002b16 <swtch>
        c->proc = 0;
    80002380:	0009b023          	sd	zero,0(s3)
        release(&p->lock);
    80002384:	8562                	mv	a0,s8
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	912080e7          	jalr	-1774(ra) # 80000c98 <release>
    8000238e:	bf71                	j	8000232a <scheduler+0x5a>

0000000080002390 <sched>:
{
    80002390:	7179                	addi	sp,sp,-48
    80002392:	f406                	sd	ra,40(sp)
    80002394:	f022                	sd	s0,32(sp)
    80002396:	ec26                	sd	s1,24(sp)
    80002398:	e84a                	sd	s2,16(sp)
    8000239a:	e44e                	sd	s3,8(sp)
    8000239c:	e052                	sd	s4,0(sp)
    8000239e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800023a0:	00000097          	auipc	ra,0x0
    800023a4:	92e080e7          	jalr	-1746(ra) # 80001cce <myproc>
    800023a8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800023aa:	ffffe097          	auipc	ra,0xffffe
    800023ae:	7c0080e7          	jalr	1984(ra) # 80000b6a <holding>
    800023b2:	c141                	beqz	a0,80002432 <sched+0xa2>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023b4:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800023b6:	2781                	sext.w	a5,a5
    800023b8:	0a800713          	li	a4,168
    800023bc:	02e787b3          	mul	a5,a5,a4
    800023c0:	0000f717          	auipc	a4,0xf
    800023c4:	ee070713          	addi	a4,a4,-288 # 800112a0 <cpus>
    800023c8:	97ba                	add	a5,a5,a4
    800023ca:	5fb8                	lw	a4,120(a5)
    800023cc:	4785                	li	a5,1
    800023ce:	06f71a63          	bne	a4,a5,80002442 <sched+0xb2>
  if(p->state == RUNNING)
    800023d2:	4c98                	lw	a4,24(s1)
    800023d4:	4791                	li	a5,4
    800023d6:	06f70e63          	beq	a4,a5,80002452 <sched+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023da:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800023de:	8b89                	andi	a5,a5,2
  if(intr_get())
    800023e0:	e3c9                	bnez	a5,80002462 <sched+0xd2>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023e2:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800023e4:	0000f917          	auipc	s2,0xf
    800023e8:	ebc90913          	addi	s2,s2,-324 # 800112a0 <cpus>
    800023ec:	2781                	sext.w	a5,a5
    800023ee:	0a800993          	li	s3,168
    800023f2:	033787b3          	mul	a5,a5,s3
    800023f6:	97ca                	add	a5,a5,s2
    800023f8:	07c7aa03          	lw	s4,124(a5)
    800023fc:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    800023fe:	2581                	sext.w	a1,a1
    80002400:	033585b3          	mul	a1,a1,s3
    80002404:	05a1                	addi	a1,a1,8
    80002406:	95ca                	add	a1,a1,s2
    80002408:	06048513          	addi	a0,s1,96
    8000240c:	00000097          	auipc	ra,0x0
    80002410:	70a080e7          	jalr	1802(ra) # 80002b16 <swtch>
    80002414:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002416:	2781                	sext.w	a5,a5
    80002418:	033787b3          	mul	a5,a5,s3
    8000241c:	993e                	add	s2,s2,a5
    8000241e:	07492e23          	sw	s4,124(s2)
}
    80002422:	70a2                	ld	ra,40(sp)
    80002424:	7402                	ld	s0,32(sp)
    80002426:	64e2                	ld	s1,24(sp)
    80002428:	6942                	ld	s2,16(sp)
    8000242a:	69a2                	ld	s3,8(sp)
    8000242c:	6a02                	ld	s4,0(sp)
    8000242e:	6145                	addi	sp,sp,48
    80002430:	8082                	ret
    panic("sched p->lock");
    80002432:	00006517          	auipc	a0,0x6
    80002436:	e6e50513          	addi	a0,a0,-402 # 800082a0 <digits+0x260>
    8000243a:	ffffe097          	auipc	ra,0xffffe
    8000243e:	104080e7          	jalr	260(ra) # 8000053e <panic>
    panic("sched locks");
    80002442:	00006517          	auipc	a0,0x6
    80002446:	e6e50513          	addi	a0,a0,-402 # 800082b0 <digits+0x270>
    8000244a:	ffffe097          	auipc	ra,0xffffe
    8000244e:	0f4080e7          	jalr	244(ra) # 8000053e <panic>
    panic("sched running");
    80002452:	00006517          	auipc	a0,0x6
    80002456:	e6e50513          	addi	a0,a0,-402 # 800082c0 <digits+0x280>
    8000245a:	ffffe097          	auipc	ra,0xffffe
    8000245e:	0e4080e7          	jalr	228(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002462:	00006517          	auipc	a0,0x6
    80002466:	e6e50513          	addi	a0,a0,-402 # 800082d0 <digits+0x290>
    8000246a:	ffffe097          	auipc	ra,0xffffe
    8000246e:	0d4080e7          	jalr	212(ra) # 8000053e <panic>

0000000080002472 <yield>:
{
    80002472:	1101                	addi	sp,sp,-32
    80002474:	ec06                	sd	ra,24(sp)
    80002476:	e822                	sd	s0,16(sp)
    80002478:	e426                	sd	s1,8(sp)
    8000247a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000247c:	00000097          	auipc	ra,0x0
    80002480:	852080e7          	jalr	-1966(ra) # 80001cce <myproc>
    80002484:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002486:	ffffe097          	auipc	ra,0xffffe
    8000248a:	75e080e7          	jalr	1886(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000248e:	478d                	li	a5,3
    80002490:	cc9c                	sw	a5,24(s1)
    80002492:	8792                	mv	a5,tp
  append(&(mycpu()->runnable_list), p);
    80002494:	2781                	sext.w	a5,a5
    80002496:	0a800513          	li	a0,168
    8000249a:	02a787b3          	mul	a5,a5,a0
    8000249e:	85a6                	mv	a1,s1
    800024a0:	0000f517          	auipc	a0,0xf
    800024a4:	e8850513          	addi	a0,a0,-376 # 80011328 <cpus+0x88>
    800024a8:	953e                	add	a0,a0,a5
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	3dc080e7          	jalr	988(ra) # 80001886 <append>
  sched();
    800024b2:	00000097          	auipc	ra,0x0
    800024b6:	ede080e7          	jalr	-290(ra) # 80002390 <sched>
  release(&p->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	7dc080e7          	jalr	2012(ra) # 80000c98 <release>
}
    800024c4:	60e2                	ld	ra,24(sp)
    800024c6:	6442                	ld	s0,16(sp)
    800024c8:	64a2                	ld	s1,8(sp)
    800024ca:	6105                	addi	sp,sp,32
    800024cc:	8082                	ret

00000000800024ce <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800024ce:	7179                	addi	sp,sp,-48
    800024d0:	f406                	sd	ra,40(sp)
    800024d2:	f022                	sd	s0,32(sp)
    800024d4:	ec26                	sd	s1,24(sp)
    800024d6:	e84a                	sd	s2,16(sp)
    800024d8:	e44e                	sd	s3,8(sp)
    800024da:	1800                	addi	s0,sp,48
    800024dc:	89aa                	mv	s3,a0
    800024de:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800024e0:	fffff097          	auipc	ra,0xfffff
    800024e4:	7ee080e7          	jalr	2030(ra) # 80001cce <myproc>
    800024e8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);
    800024ea:	ffffe097          	auipc	ra,0xffffe
    800024ee:	6fa080e7          	jalr	1786(ra) # 80000be4 <acquire>
  release(lk);
    800024f2:	854a                	mv	a0,s2
    800024f4:	ffffe097          	auipc	ra,0xffffe
    800024f8:	7a4080e7          	jalr	1956(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800024fc:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002500:	4789                	li	a5,2
    80002502:	cc9c                	sw	a5,24(s1)
  append(&sleeping_list, p);
    80002504:	85a6                	mv	a1,s1
    80002506:	00006517          	auipc	a0,0x6
    8000250a:	3aa50513          	addi	a0,a0,938 # 800088b0 <sleeping_list>
    8000250e:	fffff097          	auipc	ra,0xfffff
    80002512:	378080e7          	jalr	888(ra) # 80001886 <append>

  sched();
    80002516:	00000097          	auipc	ra,0x0
    8000251a:	e7a080e7          	jalr	-390(ra) # 80002390 <sched>

  // Tidy up.
  p->chan = 0;
    8000251e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002522:	8526                	mv	a0,s1
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	774080e7          	jalr	1908(ra) # 80000c98 <release>
  acquire(lk);
    8000252c:	854a                	mv	a0,s2
    8000252e:	ffffe097          	auipc	ra,0xffffe
    80002532:	6b6080e7          	jalr	1718(ra) # 80000be4 <acquire>
}
    80002536:	70a2                	ld	ra,40(sp)
    80002538:	7402                	ld	s0,32(sp)
    8000253a:	64e2                	ld	s1,24(sp)
    8000253c:	6942                	ld	s2,16(sp)
    8000253e:	69a2                	ld	s3,8(sp)
    80002540:	6145                	addi	sp,sp,48
    80002542:	8082                	ret

0000000080002544 <wait>:
{
    80002544:	715d                	addi	sp,sp,-80
    80002546:	e486                	sd	ra,72(sp)
    80002548:	e0a2                	sd	s0,64(sp)
    8000254a:	fc26                	sd	s1,56(sp)
    8000254c:	f84a                	sd	s2,48(sp)
    8000254e:	f44e                	sd	s3,40(sp)
    80002550:	f052                	sd	s4,32(sp)
    80002552:	ec56                	sd	s5,24(sp)
    80002554:	e85a                	sd	s6,16(sp)
    80002556:	e45e                	sd	s7,8(sp)
    80002558:	e062                	sd	s8,0(sp)
    8000255a:	0880                	addi	s0,sp,80
    8000255c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000255e:	fffff097          	auipc	ra,0xfffff
    80002562:	770080e7          	jalr	1904(ra) # 80001cce <myproc>
    80002566:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002568:	0000f517          	auipc	a0,0xf
    8000256c:	29050513          	addi	a0,a0,656 # 800117f8 <wait_lock>
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	674080e7          	jalr	1652(ra) # 80000be4 <acquire>
    havekids = 0;
    80002578:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000257a:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000257c:	00015997          	auipc	s3,0x15
    80002580:	69498993          	addi	s3,s3,1684 # 80017c10 <tickslock>
        havekids = 1;
    80002584:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002586:	0000fc17          	auipc	s8,0xf
    8000258a:	272c0c13          	addi	s8,s8,626 # 800117f8 <wait_lock>
    havekids = 0;
    8000258e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002590:	0000f497          	auipc	s1,0xf
    80002594:	28048493          	addi	s1,s1,640 # 80011810 <proc>
    80002598:	a0bd                	j	80002606 <wait+0xc2>
          pid = np->pid;
    8000259a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000259e:	000b0e63          	beqz	s6,800025ba <wait+0x76>
    800025a2:	4691                	li	a3,4
    800025a4:	02c48613          	addi	a2,s1,44
    800025a8:	85da                	mv	a1,s6
    800025aa:	05093503          	ld	a0,80(s2)
    800025ae:	fffff097          	auipc	ra,0xfffff
    800025b2:	0c4080e7          	jalr	196(ra) # 80001672 <copyout>
    800025b6:	02054563          	bltz	a0,800025e0 <wait+0x9c>
          freeproc(np);
    800025ba:	8526                	mv	a0,s1
    800025bc:	00000097          	auipc	ra,0x0
    800025c0:	8be080e7          	jalr	-1858(ra) # 80001e7a <freeproc>
          release(&np->lock);
    800025c4:	8526                	mv	a0,s1
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	6d2080e7          	jalr	1746(ra) # 80000c98 <release>
          release(&wait_lock);
    800025ce:	0000f517          	auipc	a0,0xf
    800025d2:	22a50513          	addi	a0,a0,554 # 800117f8 <wait_lock>
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	6c2080e7          	jalr	1730(ra) # 80000c98 <release>
          return pid;
    800025de:	a09d                	j	80002644 <wait+0x100>
            release(&np->lock);
    800025e0:	8526                	mv	a0,s1
    800025e2:	ffffe097          	auipc	ra,0xffffe
    800025e6:	6b6080e7          	jalr	1718(ra) # 80000c98 <release>
            release(&wait_lock);
    800025ea:	0000f517          	auipc	a0,0xf
    800025ee:	20e50513          	addi	a0,a0,526 # 800117f8 <wait_lock>
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	6a6080e7          	jalr	1702(ra) # 80000c98 <release>
            return -1;
    800025fa:	59fd                	li	s3,-1
    800025fc:	a0a1                	j	80002644 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800025fe:	19048493          	addi	s1,s1,400
    80002602:	03348463          	beq	s1,s3,8000262a <wait+0xe6>
      if(np->parent == p){
    80002606:	7c9c                	ld	a5,56(s1)
    80002608:	ff279be3          	bne	a5,s2,800025fe <wait+0xba>
        acquire(&np->lock);
    8000260c:	8526                	mv	a0,s1
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	5d6080e7          	jalr	1494(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002616:	4c9c                	lw	a5,24(s1)
    80002618:	f94781e3          	beq	a5,s4,8000259a <wait+0x56>
        release(&np->lock);
    8000261c:	8526                	mv	a0,s1
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	67a080e7          	jalr	1658(ra) # 80000c98 <release>
        havekids = 1;
    80002626:	8756                	mv	a4,s5
    80002628:	bfd9                	j	800025fe <wait+0xba>
    if(!havekids || p->killed){
    8000262a:	c701                	beqz	a4,80002632 <wait+0xee>
    8000262c:	02892783          	lw	a5,40(s2)
    80002630:	c79d                	beqz	a5,8000265e <wait+0x11a>
      release(&wait_lock);
    80002632:	0000f517          	auipc	a0,0xf
    80002636:	1c650513          	addi	a0,a0,454 # 800117f8 <wait_lock>
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	65e080e7          	jalr	1630(ra) # 80000c98 <release>
      return -1;
    80002642:	59fd                	li	s3,-1
}
    80002644:	854e                	mv	a0,s3
    80002646:	60a6                	ld	ra,72(sp)
    80002648:	6406                	ld	s0,64(sp)
    8000264a:	74e2                	ld	s1,56(sp)
    8000264c:	7942                	ld	s2,48(sp)
    8000264e:	79a2                	ld	s3,40(sp)
    80002650:	7a02                	ld	s4,32(sp)
    80002652:	6ae2                	ld	s5,24(sp)
    80002654:	6b42                	ld	s6,16(sp)
    80002656:	6ba2                	ld	s7,8(sp)
    80002658:	6c02                	ld	s8,0(sp)
    8000265a:	6161                	addi	sp,sp,80
    8000265c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000265e:	85e2                	mv	a1,s8
    80002660:	854a                	mv	a0,s2
    80002662:	00000097          	auipc	ra,0x0
    80002666:	e6c080e7          	jalr	-404(ra) # 800024ce <sleep>
    havekids = 0;
    8000266a:	b715                	j	8000258e <wait+0x4a>

000000008000266c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000266c:	7159                	addi	sp,sp,-112
    8000266e:	f486                	sd	ra,104(sp)
    80002670:	f0a2                	sd	s0,96(sp)
    80002672:	eca6                	sd	s1,88(sp)
    80002674:	e8ca                	sd	s2,80(sp)
    80002676:	e4ce                	sd	s3,72(sp)
    80002678:	e0d2                	sd	s4,64(sp)
    8000267a:	fc56                	sd	s5,56(sp)
    8000267c:	f85a                	sd	s6,48(sp)
    8000267e:	f45e                	sd	s7,40(sp)
    80002680:	f062                	sd	s8,32(sp)
    80002682:	ec66                	sd	s9,24(sp)
    80002684:	e86a                	sd	s10,16(sp)
    80002686:	e46e                	sd	s11,8(sp)
    80002688:	1880                	addi	s0,sp,112
  struct proc *p;

  int curr = sleeping_list.head;
    8000268a:	00006917          	auipc	s2,0x6
    8000268e:	22692903          	lw	s2,550(s2) # 800088b0 <sleeping_list>

  while(curr != -1) {
    80002692:	57fd                	li	a5,-1
    80002694:	0af90163          	beq	s2,a5,80002736 <wakeup+0xca>
    80002698:	8c2a                	mv	s8,a0
    p = &proc[curr];
    8000269a:	19000a13          	li	s4,400
    8000269e:	0000f997          	auipc	s3,0xf
    800026a2:	17298993          	addi	s3,s3,370 # 80011810 <proc>
    curr = p->next_proc;
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800026a6:	4b89                	li	s7,2
        remove(&sleeping_list, p);
        p->state = RUNNABLE;
    800026a8:	4d8d                	li	s11,3

        #ifdef ON
          p->last_cpu = min_cpu_process_count();
        #endif
        inc_cpu(&cpus[p->last_cpu]);
    800026aa:	0000fd17          	auipc	s10,0xf
    800026ae:	bf6d0d13          	addi	s10,s10,-1034 # 800112a0 <cpus>
    800026b2:	0a800c93          	li	s9,168
  while(curr != -1) {
    800026b6:	5b7d                	li	s6,-1
    800026b8:	a801                	j	800026c8 <wakeup+0x5c>

        append(&cpus[p->last_cpu].runnable_list, p);
      }
      release(&p->lock);
    800026ba:	8526                	mv	a0,s1
    800026bc:	ffffe097          	auipc	ra,0xffffe
    800026c0:	5dc080e7          	jalr	1500(ra) # 80000c98 <release>
  while(curr != -1) {
    800026c4:	07690963          	beq	s2,s6,80002736 <wakeup+0xca>
    p = &proc[curr];
    800026c8:	034904b3          	mul	s1,s2,s4
    800026cc:	94ce                	add	s1,s1,s3
    curr = p->next_proc;
    800026ce:	16c4a903          	lw	s2,364(s1)
    if(p != myproc()){
    800026d2:	fffff097          	auipc	ra,0xfffff
    800026d6:	5fc080e7          	jalr	1532(ra) # 80001cce <myproc>
    800026da:	fea485e3          	beq	s1,a0,800026c4 <wakeup+0x58>
      acquire(&p->lock);
    800026de:	8526                	mv	a0,s1
    800026e0:	ffffe097          	auipc	ra,0xffffe
    800026e4:	504080e7          	jalr	1284(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800026e8:	4c9c                	lw	a5,24(s1)
    800026ea:	fd7798e3          	bne	a5,s7,800026ba <wakeup+0x4e>
    800026ee:	709c                	ld	a5,32(s1)
    800026f0:	fd8795e3          	bne	a5,s8,800026ba <wakeup+0x4e>
        remove(&sleeping_list, p);
    800026f4:	85a6                	mv	a1,s1
    800026f6:	00006517          	auipc	a0,0x6
    800026fa:	1ba50513          	addi	a0,a0,442 # 800088b0 <sleeping_list>
    800026fe:	fffff097          	auipc	ra,0xfffff
    80002702:	250080e7          	jalr	592(ra) # 8000194e <remove>
        p->state = RUNNABLE;
    80002706:	01b4ac23          	sw	s11,24(s1)
        inc_cpu(&cpus[p->last_cpu]);
    8000270a:	1684a503          	lw	a0,360(s1)
    8000270e:	03950533          	mul	a0,a0,s9
    80002712:	956a                	add	a0,a0,s10
    80002714:	fffff097          	auipc	ra,0xfffff
    80002718:	12a080e7          	jalr	298(ra) # 8000183e <inc_cpu>
        append(&cpus[p->last_cpu].runnable_list, p);
    8000271c:	1684a503          	lw	a0,360(s1)
    80002720:	03950533          	mul	a0,a0,s9
    80002724:	08850513          	addi	a0,a0,136
    80002728:	85a6                	mv	a1,s1
    8000272a:	956a                	add	a0,a0,s10
    8000272c:	fffff097          	auipc	ra,0xfffff
    80002730:	15a080e7          	jalr	346(ra) # 80001886 <append>
    80002734:	b759                	j	800026ba <wakeup+0x4e>
    }
  }
}
    80002736:	70a6                	ld	ra,104(sp)
    80002738:	7406                	ld	s0,96(sp)
    8000273a:	64e6                	ld	s1,88(sp)
    8000273c:	6946                	ld	s2,80(sp)
    8000273e:	69a6                	ld	s3,72(sp)
    80002740:	6a06                	ld	s4,64(sp)
    80002742:	7ae2                	ld	s5,56(sp)
    80002744:	7b42                	ld	s6,48(sp)
    80002746:	7ba2                	ld	s7,40(sp)
    80002748:	7c02                	ld	s8,32(sp)
    8000274a:	6ce2                	ld	s9,24(sp)
    8000274c:	6d42                	ld	s10,16(sp)
    8000274e:	6da2                	ld	s11,8(sp)
    80002750:	6165                	addi	sp,sp,112
    80002752:	8082                	ret

0000000080002754 <reparent>:
{
    80002754:	7179                	addi	sp,sp,-48
    80002756:	f406                	sd	ra,40(sp)
    80002758:	f022                	sd	s0,32(sp)
    8000275a:	ec26                	sd	s1,24(sp)
    8000275c:	e84a                	sd	s2,16(sp)
    8000275e:	e44e                	sd	s3,8(sp)
    80002760:	e052                	sd	s4,0(sp)
    80002762:	1800                	addi	s0,sp,48
    80002764:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002766:	0000f497          	auipc	s1,0xf
    8000276a:	0aa48493          	addi	s1,s1,170 # 80011810 <proc>
      pp->parent = initproc;
    8000276e:	00007a17          	auipc	s4,0x7
    80002772:	8baa0a13          	addi	s4,s4,-1862 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002776:	00015997          	auipc	s3,0x15
    8000277a:	49a98993          	addi	s3,s3,1178 # 80017c10 <tickslock>
    8000277e:	a029                	j	80002788 <reparent+0x34>
    80002780:	19048493          	addi	s1,s1,400
    80002784:	01348d63          	beq	s1,s3,8000279e <reparent+0x4a>
    if(pp->parent == p){
    80002788:	7c9c                	ld	a5,56(s1)
    8000278a:	ff279be3          	bne	a5,s2,80002780 <reparent+0x2c>
      pp->parent = initproc;
    8000278e:	000a3503          	ld	a0,0(s4)
    80002792:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002794:	00000097          	auipc	ra,0x0
    80002798:	ed8080e7          	jalr	-296(ra) # 8000266c <wakeup>
    8000279c:	b7d5                	j	80002780 <reparent+0x2c>
}
    8000279e:	70a2                	ld	ra,40(sp)
    800027a0:	7402                	ld	s0,32(sp)
    800027a2:	64e2                	ld	s1,24(sp)
    800027a4:	6942                	ld	s2,16(sp)
    800027a6:	69a2                	ld	s3,8(sp)
    800027a8:	6a02                	ld	s4,0(sp)
    800027aa:	6145                	addi	sp,sp,48
    800027ac:	8082                	ret

00000000800027ae <exit>:
{
    800027ae:	7179                	addi	sp,sp,-48
    800027b0:	f406                	sd	ra,40(sp)
    800027b2:	f022                	sd	s0,32(sp)
    800027b4:	ec26                	sd	s1,24(sp)
    800027b6:	e84a                	sd	s2,16(sp)
    800027b8:	e44e                	sd	s3,8(sp)
    800027ba:	e052                	sd	s4,0(sp)
    800027bc:	1800                	addi	s0,sp,48
    800027be:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800027c0:	fffff097          	auipc	ra,0xfffff
    800027c4:	50e080e7          	jalr	1294(ra) # 80001cce <myproc>
    800027c8:	89aa                	mv	s3,a0
  if(p == initproc)
    800027ca:	00007797          	auipc	a5,0x7
    800027ce:	85e7b783          	ld	a5,-1954(a5) # 80009028 <initproc>
    800027d2:	0d050493          	addi	s1,a0,208
    800027d6:	15050913          	addi	s2,a0,336
    800027da:	02a79363          	bne	a5,a0,80002800 <exit+0x52>
    panic("init exiting");
    800027de:	00006517          	auipc	a0,0x6
    800027e2:	b0a50513          	addi	a0,a0,-1270 # 800082e8 <digits+0x2a8>
    800027e6:	ffffe097          	auipc	ra,0xffffe
    800027ea:	d58080e7          	jalr	-680(ra) # 8000053e <panic>
      fileclose(f);
    800027ee:	00002097          	auipc	ra,0x2
    800027f2:	22a080e7          	jalr	554(ra) # 80004a18 <fileclose>
      p->ofile[fd] = 0;
    800027f6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800027fa:	04a1                	addi	s1,s1,8
    800027fc:	01248563          	beq	s1,s2,80002806 <exit+0x58>
    if(p->ofile[fd]){
    80002800:	6088                	ld	a0,0(s1)
    80002802:	f575                	bnez	a0,800027ee <exit+0x40>
    80002804:	bfdd                	j	800027fa <exit+0x4c>
  begin_op();
    80002806:	00002097          	auipc	ra,0x2
    8000280a:	d46080e7          	jalr	-698(ra) # 8000454c <begin_op>
  iput(p->cwd);
    8000280e:	1509b503          	ld	a0,336(s3)
    80002812:	00001097          	auipc	ra,0x1
    80002816:	522080e7          	jalr	1314(ra) # 80003d34 <iput>
  end_op();
    8000281a:	00002097          	auipc	ra,0x2
    8000281e:	db2080e7          	jalr	-590(ra) # 800045cc <end_op>
  p->cwd = 0;
    80002822:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002826:	0000f497          	auipc	s1,0xf
    8000282a:	fd248493          	addi	s1,s1,-46 # 800117f8 <wait_lock>
    8000282e:	8526                	mv	a0,s1
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	3b4080e7          	jalr	948(ra) # 80000be4 <acquire>
  reparent(p);
    80002838:	854e                	mv	a0,s3
    8000283a:	00000097          	auipc	ra,0x0
    8000283e:	f1a080e7          	jalr	-230(ra) # 80002754 <reparent>
  wakeup(p->parent);
    80002842:	0389b503          	ld	a0,56(s3)
    80002846:	00000097          	auipc	ra,0x0
    8000284a:	e26080e7          	jalr	-474(ra) # 8000266c <wakeup>
  acquire(&p->lock);
    8000284e:	854e                	mv	a0,s3
    80002850:	ffffe097          	auipc	ra,0xffffe
    80002854:	394080e7          	jalr	916(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002858:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000285c:	4795                	li	a5,5
    8000285e:	00f9ac23          	sw	a5,24(s3)
  append(&zombie_list, p); // exit to admit the exiting process to the ZOMBIE list
    80002862:	85ce                	mv	a1,s3
    80002864:	00006517          	auipc	a0,0x6
    80002868:	06c50513          	addi	a0,a0,108 # 800088d0 <zombie_list>
    8000286c:	fffff097          	auipc	ra,0xfffff
    80002870:	01a080e7          	jalr	26(ra) # 80001886 <append>
  release(&wait_lock);
    80002874:	8526                	mv	a0,s1
    80002876:	ffffe097          	auipc	ra,0xffffe
    8000287a:	422080e7          	jalr	1058(ra) # 80000c98 <release>
  sched();
    8000287e:	00000097          	auipc	ra,0x0
    80002882:	b12080e7          	jalr	-1262(ra) # 80002390 <sched>
  panic("zombie exit");
    80002886:	00006517          	auipc	a0,0x6
    8000288a:	a7250513          	addi	a0,a0,-1422 # 800082f8 <digits+0x2b8>
    8000288e:	ffffe097          	auipc	ra,0xffffe
    80002892:	cb0080e7          	jalr	-848(ra) # 8000053e <panic>

0000000080002896 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002896:	7179                	addi	sp,sp,-48
    80002898:	f406                	sd	ra,40(sp)
    8000289a:	f022                	sd	s0,32(sp)
    8000289c:	ec26                	sd	s1,24(sp)
    8000289e:	e84a                	sd	s2,16(sp)
    800028a0:	e44e                	sd	s3,8(sp)
    800028a2:	1800                	addi	s0,sp,48
    800028a4:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800028a6:	0000f497          	auipc	s1,0xf
    800028aa:	f6a48493          	addi	s1,s1,-150 # 80011810 <proc>
    800028ae:	00015997          	auipc	s3,0x15
    800028b2:	36298993          	addi	s3,s3,866 # 80017c10 <tickslock>
    acquire(&p->lock);
    800028b6:	8526                	mv	a0,s1
    800028b8:	ffffe097          	auipc	ra,0xffffe
    800028bc:	32c080e7          	jalr	812(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800028c0:	589c                	lw	a5,48(s1)
    800028c2:	01278d63          	beq	a5,s2,800028dc <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800028c6:	8526                	mv	a0,s1
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	3d0080e7          	jalr	976(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800028d0:	19048493          	addi	s1,s1,400
    800028d4:	ff3491e3          	bne	s1,s3,800028b6 <kill+0x20>
  }
  return -1;
    800028d8:	557d                	li	a0,-1
    800028da:	a829                	j	800028f4 <kill+0x5e>
      p->killed = 1;
    800028dc:	4785                	li	a5,1
    800028de:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800028e0:	4c98                	lw	a4,24(s1)
    800028e2:	4789                	li	a5,2
    800028e4:	00f70f63          	beq	a4,a5,80002902 <kill+0x6c>
      release(&p->lock);
    800028e8:	8526                	mv	a0,s1
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	3ae080e7          	jalr	942(ra) # 80000c98 <release>
      return 0;
    800028f2:	4501                	li	a0,0
}
    800028f4:	70a2                	ld	ra,40(sp)
    800028f6:	7402                	ld	s0,32(sp)
    800028f8:	64e2                	ld	s1,24(sp)
    800028fa:	6942                	ld	s2,16(sp)
    800028fc:	69a2                	ld	s3,8(sp)
    800028fe:	6145                	addi	sp,sp,48
    80002900:	8082                	ret
        p->state = RUNNABLE;
    80002902:	478d                	li	a5,3
    80002904:	cc9c                	sw	a5,24(s1)
    80002906:	b7cd                	j	800028e8 <kill+0x52>

0000000080002908 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002908:	7179                	addi	sp,sp,-48
    8000290a:	f406                	sd	ra,40(sp)
    8000290c:	f022                	sd	s0,32(sp)
    8000290e:	ec26                	sd	s1,24(sp)
    80002910:	e84a                	sd	s2,16(sp)
    80002912:	e44e                	sd	s3,8(sp)
    80002914:	e052                	sd	s4,0(sp)
    80002916:	1800                	addi	s0,sp,48
    80002918:	84aa                	mv	s1,a0
    8000291a:	892e                	mv	s2,a1
    8000291c:	89b2                	mv	s3,a2
    8000291e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002920:	fffff097          	auipc	ra,0xfffff
    80002924:	3ae080e7          	jalr	942(ra) # 80001cce <myproc>
  if(user_dst){
    80002928:	c08d                	beqz	s1,8000294a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000292a:	86d2                	mv	a3,s4
    8000292c:	864e                	mv	a2,s3
    8000292e:	85ca                	mv	a1,s2
    80002930:	6928                	ld	a0,80(a0)
    80002932:	fffff097          	auipc	ra,0xfffff
    80002936:	d40080e7          	jalr	-704(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000293a:	70a2                	ld	ra,40(sp)
    8000293c:	7402                	ld	s0,32(sp)
    8000293e:	64e2                	ld	s1,24(sp)
    80002940:	6942                	ld	s2,16(sp)
    80002942:	69a2                	ld	s3,8(sp)
    80002944:	6a02                	ld	s4,0(sp)
    80002946:	6145                	addi	sp,sp,48
    80002948:	8082                	ret
    memmove((char *)dst, src, len);
    8000294a:	000a061b          	sext.w	a2,s4
    8000294e:	85ce                	mv	a1,s3
    80002950:	854a                	mv	a0,s2
    80002952:	ffffe097          	auipc	ra,0xffffe
    80002956:	3ee080e7          	jalr	1006(ra) # 80000d40 <memmove>
    return 0;
    8000295a:	8526                	mv	a0,s1
    8000295c:	bff9                	j	8000293a <either_copyout+0x32>

000000008000295e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000295e:	7179                	addi	sp,sp,-48
    80002960:	f406                	sd	ra,40(sp)
    80002962:	f022                	sd	s0,32(sp)
    80002964:	ec26                	sd	s1,24(sp)
    80002966:	e84a                	sd	s2,16(sp)
    80002968:	e44e                	sd	s3,8(sp)
    8000296a:	e052                	sd	s4,0(sp)
    8000296c:	1800                	addi	s0,sp,48
    8000296e:	892a                	mv	s2,a0
    80002970:	84ae                	mv	s1,a1
    80002972:	89b2                	mv	s3,a2
    80002974:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002976:	fffff097          	auipc	ra,0xfffff
    8000297a:	358080e7          	jalr	856(ra) # 80001cce <myproc>
  if(user_src){
    8000297e:	c08d                	beqz	s1,800029a0 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002980:	86d2                	mv	a3,s4
    80002982:	864e                	mv	a2,s3
    80002984:	85ca                	mv	a1,s2
    80002986:	6928                	ld	a0,80(a0)
    80002988:	fffff097          	auipc	ra,0xfffff
    8000298c:	d76080e7          	jalr	-650(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002990:	70a2                	ld	ra,40(sp)
    80002992:	7402                	ld	s0,32(sp)
    80002994:	64e2                	ld	s1,24(sp)
    80002996:	6942                	ld	s2,16(sp)
    80002998:	69a2                	ld	s3,8(sp)
    8000299a:	6a02                	ld	s4,0(sp)
    8000299c:	6145                	addi	sp,sp,48
    8000299e:	8082                	ret
    memmove(dst, (char*)src, len);
    800029a0:	000a061b          	sext.w	a2,s4
    800029a4:	85ce                	mv	a1,s3
    800029a6:	854a                	mv	a0,s2
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	398080e7          	jalr	920(ra) # 80000d40 <memmove>
    return 0;
    800029b0:	8526                	mv	a0,s1
    800029b2:	bff9                	j	80002990 <either_copyin+0x32>

00000000800029b4 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    800029b4:	715d                	addi	sp,sp,-80
    800029b6:	e486                	sd	ra,72(sp)
    800029b8:	e0a2                	sd	s0,64(sp)
    800029ba:	fc26                	sd	s1,56(sp)
    800029bc:	f84a                	sd	s2,48(sp)
    800029be:	f44e                	sd	s3,40(sp)
    800029c0:	f052                	sd	s4,32(sp)
    800029c2:	ec56                	sd	s5,24(sp)
    800029c4:	e85a                	sd	s6,16(sp)
    800029c6:	e45e                	sd	s7,8(sp)
    800029c8:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800029ca:	00005517          	auipc	a0,0x5
    800029ce:	6fe50513          	addi	a0,a0,1790 # 800080c8 <digits+0x88>
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	bb6080e7          	jalr	-1098(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800029da:	0000f497          	auipc	s1,0xf
    800029de:	f8e48493          	addi	s1,s1,-114 # 80011968 <proc+0x158>
    800029e2:	00015917          	auipc	s2,0x15
    800029e6:	38690913          	addi	s2,s2,902 # 80017d68 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029ea:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    800029ec:	00006997          	auipc	s3,0x6
    800029f0:	91c98993          	addi	s3,s3,-1764 # 80008308 <digits+0x2c8>
    printf("%d %s %s", p->pid, state, p->name);
    800029f4:	00006a97          	auipc	s5,0x6
    800029f8:	91ca8a93          	addi	s5,s5,-1764 # 80008310 <digits+0x2d0>
    printf("\n");
    800029fc:	00005a17          	auipc	s4,0x5
    80002a00:	6cca0a13          	addi	s4,s4,1740 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a04:	00006b97          	auipc	s7,0x6
    80002a08:	944b8b93          	addi	s7,s7,-1724 # 80008348 <states.1763>
    80002a0c:	a00d                	j	80002a2e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002a0e:	ed86a583          	lw	a1,-296(a3)
    80002a12:	8556                	mv	a0,s5
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	b74080e7          	jalr	-1164(ra) # 80000588 <printf>
    printf("\n");
    80002a1c:	8552                	mv	a0,s4
    80002a1e:	ffffe097          	auipc	ra,0xffffe
    80002a22:	b6a080e7          	jalr	-1174(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a26:	19048493          	addi	s1,s1,400
    80002a2a:	03248163          	beq	s1,s2,80002a4c <procdump+0x98>
    if(p->state == UNUSED)
    80002a2e:	86a6                	mv	a3,s1
    80002a30:	ec04a783          	lw	a5,-320(s1)
    80002a34:	dbed                	beqz	a5,80002a26 <procdump+0x72>
      state = "???"; 
    80002a36:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a38:	fcfb6be3          	bltu	s6,a5,80002a0e <procdump+0x5a>
    80002a3c:	1782                	slli	a5,a5,0x20
    80002a3e:	9381                	srli	a5,a5,0x20
    80002a40:	078e                	slli	a5,a5,0x3
    80002a42:	97de                	add	a5,a5,s7
    80002a44:	6390                	ld	a2,0(a5)
    80002a46:	f661                	bnez	a2,80002a0e <procdump+0x5a>
      state = "???"; 
    80002a48:	864e                	mv	a2,s3
    80002a4a:	b7d1                	j	80002a0e <procdump+0x5a>
  }
}
    80002a4c:	60a6                	ld	ra,72(sp)
    80002a4e:	6406                	ld	s0,64(sp)
    80002a50:	74e2                	ld	s1,56(sp)
    80002a52:	7942                	ld	s2,48(sp)
    80002a54:	79a2                	ld	s3,40(sp)
    80002a56:	7a02                	ld	s4,32(sp)
    80002a58:	6ae2                	ld	s5,24(sp)
    80002a5a:	6b42                	ld	s6,16(sp)
    80002a5c:	6ba2                	ld	s7,8(sp)
    80002a5e:	6161                	addi	sp,sp,80
    80002a60:	8082                	ret

0000000080002a62 <set_cpu>:

// move process to different CPU. 
int
set_cpu(int cpu_num) {
  if(cpu_num < NCPU) {
    80002a62:	479d                	li	a5,7
    80002a64:	04a7e863          	bltu	a5,a0,80002ab4 <set_cpu+0x52>
set_cpu(int cpu_num) {
    80002a68:	1101                	addi	sp,sp,-32
    80002a6a:	ec06                	sd	ra,24(sp)
    80002a6c:	e822                	sd	s0,16(sp)
    80002a6e:	e426                	sd	s1,8(sp)
    80002a70:	1000                	addi	s0,sp,32
    80002a72:	84aa                	mv	s1,a0
   if(cpu_num >= 0) {
     struct cpu *c = &cpus[cpu_num];
     if(c != NULL) {
        acquire(&myproc()->lock);
    80002a74:	fffff097          	auipc	ra,0xfffff
    80002a78:	25a080e7          	jalr	602(ra) # 80001cce <myproc>
    80002a7c:	ffffe097          	auipc	ra,0xffffe
    80002a80:	168080e7          	jalr	360(ra) # 80000be4 <acquire>
        myproc()->last_cpu = cpu_num;
    80002a84:	fffff097          	auipc	ra,0xfffff
    80002a88:	24a080e7          	jalr	586(ra) # 80001cce <myproc>
    80002a8c:	16952423          	sw	s1,360(a0)
        release(&myproc()->lock);
    80002a90:	fffff097          	auipc	ra,0xfffff
    80002a94:	23e080e7          	jalr	574(ra) # 80001cce <myproc>
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	200080e7          	jalr	512(ra) # 80000c98 <release>
        yield();
    80002aa0:	00000097          	auipc	ra,0x0
    80002aa4:	9d2080e7          	jalr	-1582(ra) # 80002472 <yield>
        return cpu_num;
    80002aa8:	8526                	mv	a0,s1
      }
    }
  }
  return -1;
}
    80002aaa:	60e2                	ld	ra,24(sp)
    80002aac:	6442                	ld	s0,16(sp)
    80002aae:	64a2                	ld	s1,8(sp)
    80002ab0:	6105                	addi	sp,sp,32
    80002ab2:	8082                	ret
  return -1;
    80002ab4:	557d                	li	a0,-1
}
    80002ab6:	8082                	ret

0000000080002ab8 <get_cpu>:

// returns current CPU.
int
get_cpu(void){
    80002ab8:	1141                	addi	sp,sp,-16
    80002aba:	e406                	sd	ra,8(sp)
    80002abc:	e022                	sd	s0,0(sp)
    80002abe:	0800                	addi	s0,sp,16
  return myproc()->last_cpu;
    80002ac0:	fffff097          	auipc	ra,0xfffff
    80002ac4:	20e080e7          	jalr	526(ra) # 80001cce <myproc>
}
    80002ac8:	16852503          	lw	a0,360(a0)
    80002acc:	60a2                	ld	ra,8(sp)
    80002ace:	6402                	ld	s0,0(sp)
    80002ad0:	0141                	addi	sp,sp,16
    80002ad2:	8082                	ret

0000000080002ad4 <min_cpu>:

int
min_cpu(void){
    80002ad4:	1141                	addi	sp,sp,-16
    80002ad6:	e422                	sd	s0,8(sp)
    80002ad8:	0800                	addi	s0,sp,16
  struct cpu *c;
  struct cpu *min_cpu = cpus;
    80002ada:	0000e617          	auipc	a2,0xe
    80002ade:	7c660613          	addi	a2,a2,1990 # 800112a0 <cpus>
  
  for(c = cpus + 1; c < &cpus[NCPU] && c != NULL ; c++){
    80002ae2:	0000f797          	auipc	a5,0xf
    80002ae6:	86678793          	addi	a5,a5,-1946 # 80011348 <cpus+0xa8>
    80002aea:	0000f597          	auipc	a1,0xf
    80002aee:	cf658593          	addi	a1,a1,-778 # 800117e0 <pid_lock>
    80002af2:	a029                	j	80002afc <min_cpu+0x28>
    80002af4:	0a878793          	addi	a5,a5,168
    80002af8:	00b78a63          	beq	a5,a1,80002b0c <min_cpu+0x38>
    if (c->proc_cnt < min_cpu->proc_cnt)
    80002afc:	0807a683          	lw	a3,128(a5)
    80002b00:	08062703          	lw	a4,128(a2)
    80002b04:	fee6d8e3          	bge	a3,a4,80002af4 <min_cpu+0x20>
    80002b08:	863e                	mv	a2,a5
    80002b0a:	b7ed                	j	80002af4 <min_cpu+0x20>
        min_cpu = c;
  }
  return min_cpu->cpu_id;   
}
    80002b0c:	08462503          	lw	a0,132(a2)
    80002b10:	6422                	ld	s0,8(sp)
    80002b12:	0141                	addi	sp,sp,16
    80002b14:	8082                	ret

0000000080002b16 <swtch>:
    80002b16:	00153023          	sd	ra,0(a0)
    80002b1a:	00253423          	sd	sp,8(a0)
    80002b1e:	e900                	sd	s0,16(a0)
    80002b20:	ed04                	sd	s1,24(a0)
    80002b22:	03253023          	sd	s2,32(a0)
    80002b26:	03353423          	sd	s3,40(a0)
    80002b2a:	03453823          	sd	s4,48(a0)
    80002b2e:	03553c23          	sd	s5,56(a0)
    80002b32:	05653023          	sd	s6,64(a0)
    80002b36:	05753423          	sd	s7,72(a0)
    80002b3a:	05853823          	sd	s8,80(a0)
    80002b3e:	05953c23          	sd	s9,88(a0)
    80002b42:	07a53023          	sd	s10,96(a0)
    80002b46:	07b53423          	sd	s11,104(a0)
    80002b4a:	0005b083          	ld	ra,0(a1)
    80002b4e:	0085b103          	ld	sp,8(a1)
    80002b52:	6980                	ld	s0,16(a1)
    80002b54:	6d84                	ld	s1,24(a1)
    80002b56:	0205b903          	ld	s2,32(a1)
    80002b5a:	0285b983          	ld	s3,40(a1)
    80002b5e:	0305ba03          	ld	s4,48(a1)
    80002b62:	0385ba83          	ld	s5,56(a1)
    80002b66:	0405bb03          	ld	s6,64(a1)
    80002b6a:	0485bb83          	ld	s7,72(a1)
    80002b6e:	0505bc03          	ld	s8,80(a1)
    80002b72:	0585bc83          	ld	s9,88(a1)
    80002b76:	0605bd03          	ld	s10,96(a1)
    80002b7a:	0685bd83          	ld	s11,104(a1)
    80002b7e:	8082                	ret

0000000080002b80 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b80:	1141                	addi	sp,sp,-16
    80002b82:	e406                	sd	ra,8(sp)
    80002b84:	e022                	sd	s0,0(sp)
    80002b86:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b88:	00005597          	auipc	a1,0x5
    80002b8c:	7f058593          	addi	a1,a1,2032 # 80008378 <states.1763+0x30>
    80002b90:	00015517          	auipc	a0,0x15
    80002b94:	08050513          	addi	a0,a0,128 # 80017c10 <tickslock>
    80002b98:	ffffe097          	auipc	ra,0xffffe
    80002b9c:	fbc080e7          	jalr	-68(ra) # 80000b54 <initlock>
}
    80002ba0:	60a2                	ld	ra,8(sp)
    80002ba2:	6402                	ld	s0,0(sp)
    80002ba4:	0141                	addi	sp,sp,16
    80002ba6:	8082                	ret

0000000080002ba8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002ba8:	1141                	addi	sp,sp,-16
    80002baa:	e422                	sd	s0,8(sp)
    80002bac:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bae:	00003797          	auipc	a5,0x3
    80002bb2:	48278793          	addi	a5,a5,1154 # 80006030 <kernelvec>
    80002bb6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002bba:	6422                	ld	s0,8(sp)
    80002bbc:	0141                	addi	sp,sp,16
    80002bbe:	8082                	ret

0000000080002bc0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002bc0:	1141                	addi	sp,sp,-16
    80002bc2:	e406                	sd	ra,8(sp)
    80002bc4:	e022                	sd	s0,0(sp)
    80002bc6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002bc8:	fffff097          	auipc	ra,0xfffff
    80002bcc:	106080e7          	jalr	262(ra) # 80001cce <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bd0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002bd4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bd6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002bda:	00004617          	auipc	a2,0x4
    80002bde:	42660613          	addi	a2,a2,1062 # 80007000 <_trampoline>
    80002be2:	00004697          	auipc	a3,0x4
    80002be6:	41e68693          	addi	a3,a3,1054 # 80007000 <_trampoline>
    80002bea:	8e91                	sub	a3,a3,a2
    80002bec:	040007b7          	lui	a5,0x4000
    80002bf0:	17fd                	addi	a5,a5,-1
    80002bf2:	07b2                	slli	a5,a5,0xc
    80002bf4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bf6:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002bfa:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002bfc:	180026f3          	csrr	a3,satp
    80002c00:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c02:	6d38                	ld	a4,88(a0)
    80002c04:	6134                	ld	a3,64(a0)
    80002c06:	6585                	lui	a1,0x1
    80002c08:	96ae                	add	a3,a3,a1
    80002c0a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c0c:	6d38                	ld	a4,88(a0)
    80002c0e:	00000697          	auipc	a3,0x0
    80002c12:	13868693          	addi	a3,a3,312 # 80002d46 <usertrap>
    80002c16:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c18:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c1a:	8692                	mv	a3,tp
    80002c1c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c1e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c22:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c26:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c2a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c2e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c30:	6f18                	ld	a4,24(a4)
    80002c32:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c36:	692c                	ld	a1,80(a0)
    80002c38:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002c3a:	00004717          	auipc	a4,0x4
    80002c3e:	45670713          	addi	a4,a4,1110 # 80007090 <userret>
    80002c42:	8f11                	sub	a4,a4,a2
    80002c44:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002c46:	577d                	li	a4,-1
    80002c48:	177e                	slli	a4,a4,0x3f
    80002c4a:	8dd9                	or	a1,a1,a4
    80002c4c:	02000537          	lui	a0,0x2000
    80002c50:	157d                	addi	a0,a0,-1
    80002c52:	0536                	slli	a0,a0,0xd
    80002c54:	9782                	jalr	a5
}
    80002c56:	60a2                	ld	ra,8(sp)
    80002c58:	6402                	ld	s0,0(sp)
    80002c5a:	0141                	addi	sp,sp,16
    80002c5c:	8082                	ret

0000000080002c5e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c5e:	1101                	addi	sp,sp,-32
    80002c60:	ec06                	sd	ra,24(sp)
    80002c62:	e822                	sd	s0,16(sp)
    80002c64:	e426                	sd	s1,8(sp)
    80002c66:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c68:	00015497          	auipc	s1,0x15
    80002c6c:	fa848493          	addi	s1,s1,-88 # 80017c10 <tickslock>
    80002c70:	8526                	mv	a0,s1
    80002c72:	ffffe097          	auipc	ra,0xffffe
    80002c76:	f72080e7          	jalr	-142(ra) # 80000be4 <acquire>
  ticks++;
    80002c7a:	00006517          	auipc	a0,0x6
    80002c7e:	3b650513          	addi	a0,a0,950 # 80009030 <ticks>
    80002c82:	411c                	lw	a5,0(a0)
    80002c84:	2785                	addiw	a5,a5,1
    80002c86:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002c88:	00000097          	auipc	ra,0x0
    80002c8c:	9e4080e7          	jalr	-1564(ra) # 8000266c <wakeup>
  release(&tickslock);
    80002c90:	8526                	mv	a0,s1
    80002c92:	ffffe097          	auipc	ra,0xffffe
    80002c96:	006080e7          	jalr	6(ra) # 80000c98 <release>
}
    80002c9a:	60e2                	ld	ra,24(sp)
    80002c9c:	6442                	ld	s0,16(sp)
    80002c9e:	64a2                	ld	s1,8(sp)
    80002ca0:	6105                	addi	sp,sp,32
    80002ca2:	8082                	ret

0000000080002ca4 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002ca4:	1101                	addi	sp,sp,-32
    80002ca6:	ec06                	sd	ra,24(sp)
    80002ca8:	e822                	sd	s0,16(sp)
    80002caa:	e426                	sd	s1,8(sp)
    80002cac:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cae:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002cb2:	00074d63          	bltz	a4,80002ccc <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002cb6:	57fd                	li	a5,-1
    80002cb8:	17fe                	slli	a5,a5,0x3f
    80002cba:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002cbc:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002cbe:	06f70363          	beq	a4,a5,80002d24 <devintr+0x80>
  }
}
    80002cc2:	60e2                	ld	ra,24(sp)
    80002cc4:	6442                	ld	s0,16(sp)
    80002cc6:	64a2                	ld	s1,8(sp)
    80002cc8:	6105                	addi	sp,sp,32
    80002cca:	8082                	ret
     (scause & 0xff) == 9){
    80002ccc:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002cd0:	46a5                	li	a3,9
    80002cd2:	fed792e3          	bne	a5,a3,80002cb6 <devintr+0x12>
    int irq = plic_claim();
    80002cd6:	00003097          	auipc	ra,0x3
    80002cda:	462080e7          	jalr	1122(ra) # 80006138 <plic_claim>
    80002cde:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ce0:	47a9                	li	a5,10
    80002ce2:	02f50763          	beq	a0,a5,80002d10 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002ce6:	4785                	li	a5,1
    80002ce8:	02f50963          	beq	a0,a5,80002d1a <devintr+0x76>
    return 1;
    80002cec:	4505                	li	a0,1
    } else if(irq){
    80002cee:	d8f1                	beqz	s1,80002cc2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002cf0:	85a6                	mv	a1,s1
    80002cf2:	00005517          	auipc	a0,0x5
    80002cf6:	68e50513          	addi	a0,a0,1678 # 80008380 <states.1763+0x38>
    80002cfa:	ffffe097          	auipc	ra,0xffffe
    80002cfe:	88e080e7          	jalr	-1906(ra) # 80000588 <printf>
      plic_complete(irq);
    80002d02:	8526                	mv	a0,s1
    80002d04:	00003097          	auipc	ra,0x3
    80002d08:	458080e7          	jalr	1112(ra) # 8000615c <plic_complete>
    return 1;
    80002d0c:	4505                	li	a0,1
    80002d0e:	bf55                	j	80002cc2 <devintr+0x1e>
      uartintr();
    80002d10:	ffffe097          	auipc	ra,0xffffe
    80002d14:	c98080e7          	jalr	-872(ra) # 800009a8 <uartintr>
    80002d18:	b7ed                	j	80002d02 <devintr+0x5e>
      virtio_disk_intr();
    80002d1a:	00004097          	auipc	ra,0x4
    80002d1e:	922080e7          	jalr	-1758(ra) # 8000663c <virtio_disk_intr>
    80002d22:	b7c5                	j	80002d02 <devintr+0x5e>
    if(cpuid() == 0){
    80002d24:	fffff097          	auipc	ra,0xfffff
    80002d28:	f78080e7          	jalr	-136(ra) # 80001c9c <cpuid>
    80002d2c:	c901                	beqz	a0,80002d3c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d2e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d32:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d34:	14479073          	csrw	sip,a5
    return 2;
    80002d38:	4509                	li	a0,2
    80002d3a:	b761                	j	80002cc2 <devintr+0x1e>
      clockintr();
    80002d3c:	00000097          	auipc	ra,0x0
    80002d40:	f22080e7          	jalr	-222(ra) # 80002c5e <clockintr>
    80002d44:	b7ed                	j	80002d2e <devintr+0x8a>

0000000080002d46 <usertrap>:
{
    80002d46:	1101                	addi	sp,sp,-32
    80002d48:	ec06                	sd	ra,24(sp)
    80002d4a:	e822                	sd	s0,16(sp)
    80002d4c:	e426                	sd	s1,8(sp)
    80002d4e:	e04a                	sd	s2,0(sp)
    80002d50:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d52:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d56:	1007f793          	andi	a5,a5,256
    80002d5a:	e3ad                	bnez	a5,80002dbc <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d5c:	00003797          	auipc	a5,0x3
    80002d60:	2d478793          	addi	a5,a5,724 # 80006030 <kernelvec>
    80002d64:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	f66080e7          	jalr	-154(ra) # 80001cce <myproc>
    80002d70:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d72:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d74:	14102773          	csrr	a4,sepc
    80002d78:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d7a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002d7e:	47a1                	li	a5,8
    80002d80:	04f71c63          	bne	a4,a5,80002dd8 <usertrap+0x92>
    if(p->killed)
    80002d84:	551c                	lw	a5,40(a0)
    80002d86:	e3b9                	bnez	a5,80002dcc <usertrap+0x86>
    p->trapframe->epc += 4;
    80002d88:	6cb8                	ld	a4,88(s1)
    80002d8a:	6f1c                	ld	a5,24(a4)
    80002d8c:	0791                	addi	a5,a5,4
    80002d8e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d98:	10079073          	csrw	sstatus,a5
    syscall();
    80002d9c:	00000097          	auipc	ra,0x0
    80002da0:	2e0080e7          	jalr	736(ra) # 8000307c <syscall>
  if(p->killed)
    80002da4:	549c                	lw	a5,40(s1)
    80002da6:	ebc1                	bnez	a5,80002e36 <usertrap+0xf0>
  usertrapret();
    80002da8:	00000097          	auipc	ra,0x0
    80002dac:	e18080e7          	jalr	-488(ra) # 80002bc0 <usertrapret>
}
    80002db0:	60e2                	ld	ra,24(sp)
    80002db2:	6442                	ld	s0,16(sp)
    80002db4:	64a2                	ld	s1,8(sp)
    80002db6:	6902                	ld	s2,0(sp)
    80002db8:	6105                	addi	sp,sp,32
    80002dba:	8082                	ret
    panic("usertrap: not from user mode");
    80002dbc:	00005517          	auipc	a0,0x5
    80002dc0:	5e450513          	addi	a0,a0,1508 # 800083a0 <states.1763+0x58>
    80002dc4:	ffffd097          	auipc	ra,0xffffd
    80002dc8:	77a080e7          	jalr	1914(ra) # 8000053e <panic>
      exit(-1);
    80002dcc:	557d                	li	a0,-1
    80002dce:	00000097          	auipc	ra,0x0
    80002dd2:	9e0080e7          	jalr	-1568(ra) # 800027ae <exit>
    80002dd6:	bf4d                	j	80002d88 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002dd8:	00000097          	auipc	ra,0x0
    80002ddc:	ecc080e7          	jalr	-308(ra) # 80002ca4 <devintr>
    80002de0:	892a                	mv	s2,a0
    80002de2:	c501                	beqz	a0,80002dea <usertrap+0xa4>
  if(p->killed)
    80002de4:	549c                	lw	a5,40(s1)
    80002de6:	c3a1                	beqz	a5,80002e26 <usertrap+0xe0>
    80002de8:	a815                	j	80002e1c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dea:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002dee:	5890                	lw	a2,48(s1)
    80002df0:	00005517          	auipc	a0,0x5
    80002df4:	5d050513          	addi	a0,a0,1488 # 800083c0 <states.1763+0x78>
    80002df8:	ffffd097          	auipc	ra,0xffffd
    80002dfc:	790080e7          	jalr	1936(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e00:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e04:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e08:	00005517          	auipc	a0,0x5
    80002e0c:	5e850513          	addi	a0,a0,1512 # 800083f0 <states.1763+0xa8>
    80002e10:	ffffd097          	auipc	ra,0xffffd
    80002e14:	778080e7          	jalr	1912(ra) # 80000588 <printf>
    p->killed = 1;
    80002e18:	4785                	li	a5,1
    80002e1a:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002e1c:	557d                	li	a0,-1
    80002e1e:	00000097          	auipc	ra,0x0
    80002e22:	990080e7          	jalr	-1648(ra) # 800027ae <exit>
  if(which_dev == 2)
    80002e26:	4789                	li	a5,2
    80002e28:	f8f910e3          	bne	s2,a5,80002da8 <usertrap+0x62>
    yield();
    80002e2c:	fffff097          	auipc	ra,0xfffff
    80002e30:	646080e7          	jalr	1606(ra) # 80002472 <yield>
    80002e34:	bf95                	j	80002da8 <usertrap+0x62>
  int which_dev = 0;
    80002e36:	4901                	li	s2,0
    80002e38:	b7d5                	j	80002e1c <usertrap+0xd6>

0000000080002e3a <kerneltrap>:
{
    80002e3a:	7179                	addi	sp,sp,-48
    80002e3c:	f406                	sd	ra,40(sp)
    80002e3e:	f022                	sd	s0,32(sp)
    80002e40:	ec26                	sd	s1,24(sp)
    80002e42:	e84a                	sd	s2,16(sp)
    80002e44:	e44e                	sd	s3,8(sp)
    80002e46:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e48:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e4c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e50:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e54:	1004f793          	andi	a5,s1,256
    80002e58:	cb85                	beqz	a5,80002e88 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e5a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e5e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e60:	ef85                	bnez	a5,80002e98 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e62:	00000097          	auipc	ra,0x0
    80002e66:	e42080e7          	jalr	-446(ra) # 80002ca4 <devintr>
    80002e6a:	cd1d                	beqz	a0,80002ea8 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e6c:	4789                	li	a5,2
    80002e6e:	06f50a63          	beq	a0,a5,80002ee2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e72:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e76:	10049073          	csrw	sstatus,s1
}
    80002e7a:	70a2                	ld	ra,40(sp)
    80002e7c:	7402                	ld	s0,32(sp)
    80002e7e:	64e2                	ld	s1,24(sp)
    80002e80:	6942                	ld	s2,16(sp)
    80002e82:	69a2                	ld	s3,8(sp)
    80002e84:	6145                	addi	sp,sp,48
    80002e86:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e88:	00005517          	auipc	a0,0x5
    80002e8c:	58850513          	addi	a0,a0,1416 # 80008410 <states.1763+0xc8>
    80002e90:	ffffd097          	auipc	ra,0xffffd
    80002e94:	6ae080e7          	jalr	1710(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002e98:	00005517          	auipc	a0,0x5
    80002e9c:	5a050513          	addi	a0,a0,1440 # 80008438 <states.1763+0xf0>
    80002ea0:	ffffd097          	auipc	ra,0xffffd
    80002ea4:	69e080e7          	jalr	1694(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002ea8:	85ce                	mv	a1,s3
    80002eaa:	00005517          	auipc	a0,0x5
    80002eae:	5ae50513          	addi	a0,a0,1454 # 80008458 <states.1763+0x110>
    80002eb2:	ffffd097          	auipc	ra,0xffffd
    80002eb6:	6d6080e7          	jalr	1750(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002eba:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ebe:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ec2:	00005517          	auipc	a0,0x5
    80002ec6:	5a650513          	addi	a0,a0,1446 # 80008468 <states.1763+0x120>
    80002eca:	ffffd097          	auipc	ra,0xffffd
    80002ece:	6be080e7          	jalr	1726(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002ed2:	00005517          	auipc	a0,0x5
    80002ed6:	5ae50513          	addi	a0,a0,1454 # 80008480 <states.1763+0x138>
    80002eda:	ffffd097          	auipc	ra,0xffffd
    80002ede:	664080e7          	jalr	1636(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ee2:	fffff097          	auipc	ra,0xfffff
    80002ee6:	dec080e7          	jalr	-532(ra) # 80001cce <myproc>
    80002eea:	d541                	beqz	a0,80002e72 <kerneltrap+0x38>
    80002eec:	fffff097          	auipc	ra,0xfffff
    80002ef0:	de2080e7          	jalr	-542(ra) # 80001cce <myproc>
    80002ef4:	4d18                	lw	a4,24(a0)
    80002ef6:	4791                	li	a5,4
    80002ef8:	f6f71de3          	bne	a4,a5,80002e72 <kerneltrap+0x38>
    yield();
    80002efc:	fffff097          	auipc	ra,0xfffff
    80002f00:	576080e7          	jalr	1398(ra) # 80002472 <yield>
    80002f04:	b7bd                	j	80002e72 <kerneltrap+0x38>

0000000080002f06 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f06:	1101                	addi	sp,sp,-32
    80002f08:	ec06                	sd	ra,24(sp)
    80002f0a:	e822                	sd	s0,16(sp)
    80002f0c:	e426                	sd	s1,8(sp)
    80002f0e:	1000                	addi	s0,sp,32
    80002f10:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f12:	fffff097          	auipc	ra,0xfffff
    80002f16:	dbc080e7          	jalr	-580(ra) # 80001cce <myproc>
  switch (n) {
    80002f1a:	4795                	li	a5,5
    80002f1c:	0497e163          	bltu	a5,s1,80002f5e <argraw+0x58>
    80002f20:	048a                	slli	s1,s1,0x2
    80002f22:	00005717          	auipc	a4,0x5
    80002f26:	59670713          	addi	a4,a4,1430 # 800084b8 <states.1763+0x170>
    80002f2a:	94ba                	add	s1,s1,a4
    80002f2c:	409c                	lw	a5,0(s1)
    80002f2e:	97ba                	add	a5,a5,a4
    80002f30:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002f32:	6d3c                	ld	a5,88(a0)
    80002f34:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f36:	60e2                	ld	ra,24(sp)
    80002f38:	6442                	ld	s0,16(sp)
    80002f3a:	64a2                	ld	s1,8(sp)
    80002f3c:	6105                	addi	sp,sp,32
    80002f3e:	8082                	ret
    return p->trapframe->a1;
    80002f40:	6d3c                	ld	a5,88(a0)
    80002f42:	7fa8                	ld	a0,120(a5)
    80002f44:	bfcd                	j	80002f36 <argraw+0x30>
    return p->trapframe->a2;
    80002f46:	6d3c                	ld	a5,88(a0)
    80002f48:	63c8                	ld	a0,128(a5)
    80002f4a:	b7f5                	j	80002f36 <argraw+0x30>
    return p->trapframe->a3;
    80002f4c:	6d3c                	ld	a5,88(a0)
    80002f4e:	67c8                	ld	a0,136(a5)
    80002f50:	b7dd                	j	80002f36 <argraw+0x30>
    return p->trapframe->a4;
    80002f52:	6d3c                	ld	a5,88(a0)
    80002f54:	6bc8                	ld	a0,144(a5)
    80002f56:	b7c5                	j	80002f36 <argraw+0x30>
    return p->trapframe->a5;
    80002f58:	6d3c                	ld	a5,88(a0)
    80002f5a:	6fc8                	ld	a0,152(a5)
    80002f5c:	bfe9                	j	80002f36 <argraw+0x30>
  panic("argraw");
    80002f5e:	00005517          	auipc	a0,0x5
    80002f62:	53250513          	addi	a0,a0,1330 # 80008490 <states.1763+0x148>
    80002f66:	ffffd097          	auipc	ra,0xffffd
    80002f6a:	5d8080e7          	jalr	1496(ra) # 8000053e <panic>

0000000080002f6e <fetchaddr>:
{
    80002f6e:	1101                	addi	sp,sp,-32
    80002f70:	ec06                	sd	ra,24(sp)
    80002f72:	e822                	sd	s0,16(sp)
    80002f74:	e426                	sd	s1,8(sp)
    80002f76:	e04a                	sd	s2,0(sp)
    80002f78:	1000                	addi	s0,sp,32
    80002f7a:	84aa                	mv	s1,a0
    80002f7c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002f7e:	fffff097          	auipc	ra,0xfffff
    80002f82:	d50080e7          	jalr	-688(ra) # 80001cce <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002f86:	653c                	ld	a5,72(a0)
    80002f88:	02f4f863          	bgeu	s1,a5,80002fb8 <fetchaddr+0x4a>
    80002f8c:	00848713          	addi	a4,s1,8
    80002f90:	02e7e663          	bltu	a5,a4,80002fbc <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f94:	46a1                	li	a3,8
    80002f96:	8626                	mv	a2,s1
    80002f98:	85ca                	mv	a1,s2
    80002f9a:	6928                	ld	a0,80(a0)
    80002f9c:	ffffe097          	auipc	ra,0xffffe
    80002fa0:	762080e7          	jalr	1890(ra) # 800016fe <copyin>
    80002fa4:	00a03533          	snez	a0,a0
    80002fa8:	40a00533          	neg	a0,a0
}
    80002fac:	60e2                	ld	ra,24(sp)
    80002fae:	6442                	ld	s0,16(sp)
    80002fb0:	64a2                	ld	s1,8(sp)
    80002fb2:	6902                	ld	s2,0(sp)
    80002fb4:	6105                	addi	sp,sp,32
    80002fb6:	8082                	ret
    return -1;
    80002fb8:	557d                	li	a0,-1
    80002fba:	bfcd                	j	80002fac <fetchaddr+0x3e>
    80002fbc:	557d                	li	a0,-1
    80002fbe:	b7fd                	j	80002fac <fetchaddr+0x3e>

0000000080002fc0 <fetchstr>:
{
    80002fc0:	7179                	addi	sp,sp,-48
    80002fc2:	f406                	sd	ra,40(sp)
    80002fc4:	f022                	sd	s0,32(sp)
    80002fc6:	ec26                	sd	s1,24(sp)
    80002fc8:	e84a                	sd	s2,16(sp)
    80002fca:	e44e                	sd	s3,8(sp)
    80002fcc:	1800                	addi	s0,sp,48
    80002fce:	892a                	mv	s2,a0
    80002fd0:	84ae                	mv	s1,a1
    80002fd2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002fd4:	fffff097          	auipc	ra,0xfffff
    80002fd8:	cfa080e7          	jalr	-774(ra) # 80001cce <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002fdc:	86ce                	mv	a3,s3
    80002fde:	864a                	mv	a2,s2
    80002fe0:	85a6                	mv	a1,s1
    80002fe2:	6928                	ld	a0,80(a0)
    80002fe4:	ffffe097          	auipc	ra,0xffffe
    80002fe8:	7a6080e7          	jalr	1958(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002fec:	00054763          	bltz	a0,80002ffa <fetchstr+0x3a>
  return strlen(buf);
    80002ff0:	8526                	mv	a0,s1
    80002ff2:	ffffe097          	auipc	ra,0xffffe
    80002ff6:	e72080e7          	jalr	-398(ra) # 80000e64 <strlen>
}
    80002ffa:	70a2                	ld	ra,40(sp)
    80002ffc:	7402                	ld	s0,32(sp)
    80002ffe:	64e2                	ld	s1,24(sp)
    80003000:	6942                	ld	s2,16(sp)
    80003002:	69a2                	ld	s3,8(sp)
    80003004:	6145                	addi	sp,sp,48
    80003006:	8082                	ret

0000000080003008 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003008:	1101                	addi	sp,sp,-32
    8000300a:	ec06                	sd	ra,24(sp)
    8000300c:	e822                	sd	s0,16(sp)
    8000300e:	e426                	sd	s1,8(sp)
    80003010:	1000                	addi	s0,sp,32
    80003012:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003014:	00000097          	auipc	ra,0x0
    80003018:	ef2080e7          	jalr	-270(ra) # 80002f06 <argraw>
    8000301c:	c088                	sw	a0,0(s1)
  return 0;
}
    8000301e:	4501                	li	a0,0
    80003020:	60e2                	ld	ra,24(sp)
    80003022:	6442                	ld	s0,16(sp)
    80003024:	64a2                	ld	s1,8(sp)
    80003026:	6105                	addi	sp,sp,32
    80003028:	8082                	ret

000000008000302a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000302a:	1101                	addi	sp,sp,-32
    8000302c:	ec06                	sd	ra,24(sp)
    8000302e:	e822                	sd	s0,16(sp)
    80003030:	e426                	sd	s1,8(sp)
    80003032:	1000                	addi	s0,sp,32
    80003034:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003036:	00000097          	auipc	ra,0x0
    8000303a:	ed0080e7          	jalr	-304(ra) # 80002f06 <argraw>
    8000303e:	e088                	sd	a0,0(s1)
  return 0;
}
    80003040:	4501                	li	a0,0
    80003042:	60e2                	ld	ra,24(sp)
    80003044:	6442                	ld	s0,16(sp)
    80003046:	64a2                	ld	s1,8(sp)
    80003048:	6105                	addi	sp,sp,32
    8000304a:	8082                	ret

000000008000304c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000304c:	1101                	addi	sp,sp,-32
    8000304e:	ec06                	sd	ra,24(sp)
    80003050:	e822                	sd	s0,16(sp)
    80003052:	e426                	sd	s1,8(sp)
    80003054:	e04a                	sd	s2,0(sp)
    80003056:	1000                	addi	s0,sp,32
    80003058:	84ae                	mv	s1,a1
    8000305a:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000305c:	00000097          	auipc	ra,0x0
    80003060:	eaa080e7          	jalr	-342(ra) # 80002f06 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003064:	864a                	mv	a2,s2
    80003066:	85a6                	mv	a1,s1
    80003068:	00000097          	auipc	ra,0x0
    8000306c:	f58080e7          	jalr	-168(ra) # 80002fc0 <fetchstr>
}
    80003070:	60e2                	ld	ra,24(sp)
    80003072:	6442                	ld	s0,16(sp)
    80003074:	64a2                	ld	s1,8(sp)
    80003076:	6902                	ld	s2,0(sp)
    80003078:	6105                	addi	sp,sp,32
    8000307a:	8082                	ret

000000008000307c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    8000307c:	1101                	addi	sp,sp,-32
    8000307e:	ec06                	sd	ra,24(sp)
    80003080:	e822                	sd	s0,16(sp)
    80003082:	e426                	sd	s1,8(sp)
    80003084:	e04a                	sd	s2,0(sp)
    80003086:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003088:	fffff097          	auipc	ra,0xfffff
    8000308c:	c46080e7          	jalr	-954(ra) # 80001cce <myproc>
    80003090:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003092:	05853903          	ld	s2,88(a0)
    80003096:	0a893783          	ld	a5,168(s2)
    8000309a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000309e:	37fd                	addiw	a5,a5,-1
    800030a0:	4751                	li	a4,20
    800030a2:	00f76f63          	bltu	a4,a5,800030c0 <syscall+0x44>
    800030a6:	00369713          	slli	a4,a3,0x3
    800030aa:	00005797          	auipc	a5,0x5
    800030ae:	42678793          	addi	a5,a5,1062 # 800084d0 <syscalls>
    800030b2:	97ba                	add	a5,a5,a4
    800030b4:	639c                	ld	a5,0(a5)
    800030b6:	c789                	beqz	a5,800030c0 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800030b8:	9782                	jalr	a5
    800030ba:	06a93823          	sd	a0,112(s2)
    800030be:	a839                	j	800030dc <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800030c0:	15848613          	addi	a2,s1,344
    800030c4:	588c                	lw	a1,48(s1)
    800030c6:	00005517          	auipc	a0,0x5
    800030ca:	3d250513          	addi	a0,a0,978 # 80008498 <states.1763+0x150>
    800030ce:	ffffd097          	auipc	ra,0xffffd
    800030d2:	4ba080e7          	jalr	1210(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800030d6:	6cbc                	ld	a5,88(s1)
    800030d8:	577d                	li	a4,-1
    800030da:	fbb8                	sd	a4,112(a5)
  }
}
    800030dc:	60e2                	ld	ra,24(sp)
    800030de:	6442                	ld	s0,16(sp)
    800030e0:	64a2                	ld	s1,8(sp)
    800030e2:	6902                	ld	s2,0(sp)
    800030e4:	6105                	addi	sp,sp,32
    800030e6:	8082                	ret

00000000800030e8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800030e8:	1101                	addi	sp,sp,-32
    800030ea:	ec06                	sd	ra,24(sp)
    800030ec:	e822                	sd	s0,16(sp)
    800030ee:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800030f0:	fec40593          	addi	a1,s0,-20
    800030f4:	4501                	li	a0,0
    800030f6:	00000097          	auipc	ra,0x0
    800030fa:	f12080e7          	jalr	-238(ra) # 80003008 <argint>
    return -1;
    800030fe:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003100:	00054963          	bltz	a0,80003112 <sys_exit+0x2a>
  exit(n);
    80003104:	fec42503          	lw	a0,-20(s0)
    80003108:	fffff097          	auipc	ra,0xfffff
    8000310c:	6a6080e7          	jalr	1702(ra) # 800027ae <exit>
  return 0;  // not reached
    80003110:	4781                	li	a5,0
}
    80003112:	853e                	mv	a0,a5
    80003114:	60e2                	ld	ra,24(sp)
    80003116:	6442                	ld	s0,16(sp)
    80003118:	6105                	addi	sp,sp,32
    8000311a:	8082                	ret

000000008000311c <sys_getpid>:

uint64
sys_getpid(void)
{
    8000311c:	1141                	addi	sp,sp,-16
    8000311e:	e406                	sd	ra,8(sp)
    80003120:	e022                	sd	s0,0(sp)
    80003122:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003124:	fffff097          	auipc	ra,0xfffff
    80003128:	baa080e7          	jalr	-1110(ra) # 80001cce <myproc>
}
    8000312c:	5908                	lw	a0,48(a0)
    8000312e:	60a2                	ld	ra,8(sp)
    80003130:	6402                	ld	s0,0(sp)
    80003132:	0141                	addi	sp,sp,16
    80003134:	8082                	ret

0000000080003136 <sys_fork>:

uint64
sys_fork(void)
{
    80003136:	1141                	addi	sp,sp,-16
    80003138:	e406                	sd	ra,8(sp)
    8000313a:	e022                	sd	s0,0(sp)
    8000313c:	0800                	addi	s0,sp,16
  return fork();
    8000313e:	fffff097          	auipc	ra,0xfffff
    80003142:	018080e7          	jalr	24(ra) # 80002156 <fork>
}
    80003146:	60a2                	ld	ra,8(sp)
    80003148:	6402                	ld	s0,0(sp)
    8000314a:	0141                	addi	sp,sp,16
    8000314c:	8082                	ret

000000008000314e <sys_wait>:

uint64
sys_wait(void)
{
    8000314e:	1101                	addi	sp,sp,-32
    80003150:	ec06                	sd	ra,24(sp)
    80003152:	e822                	sd	s0,16(sp)
    80003154:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003156:	fe840593          	addi	a1,s0,-24
    8000315a:	4501                	li	a0,0
    8000315c:	00000097          	auipc	ra,0x0
    80003160:	ece080e7          	jalr	-306(ra) # 8000302a <argaddr>
    80003164:	87aa                	mv	a5,a0
    return -1;
    80003166:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003168:	0007c863          	bltz	a5,80003178 <sys_wait+0x2a>
  return wait(p);
    8000316c:	fe843503          	ld	a0,-24(s0)
    80003170:	fffff097          	auipc	ra,0xfffff
    80003174:	3d4080e7          	jalr	980(ra) # 80002544 <wait>
}
    80003178:	60e2                	ld	ra,24(sp)
    8000317a:	6442                	ld	s0,16(sp)
    8000317c:	6105                	addi	sp,sp,32
    8000317e:	8082                	ret

0000000080003180 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003180:	7179                	addi	sp,sp,-48
    80003182:	f406                	sd	ra,40(sp)
    80003184:	f022                	sd	s0,32(sp)
    80003186:	ec26                	sd	s1,24(sp)
    80003188:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000318a:	fdc40593          	addi	a1,s0,-36
    8000318e:	4501                	li	a0,0
    80003190:	00000097          	auipc	ra,0x0
    80003194:	e78080e7          	jalr	-392(ra) # 80003008 <argint>
    80003198:	87aa                	mv	a5,a0
    return -1;
    8000319a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000319c:	0207c063          	bltz	a5,800031bc <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800031a0:	fffff097          	auipc	ra,0xfffff
    800031a4:	b2e080e7          	jalr	-1234(ra) # 80001cce <myproc>
    800031a8:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800031aa:	fdc42503          	lw	a0,-36(s0)
    800031ae:	fffff097          	auipc	ra,0xfffff
    800031b2:	f34080e7          	jalr	-204(ra) # 800020e2 <growproc>
    800031b6:	00054863          	bltz	a0,800031c6 <sys_sbrk+0x46>
    return -1;
  return addr;
    800031ba:	8526                	mv	a0,s1
}
    800031bc:	70a2                	ld	ra,40(sp)
    800031be:	7402                	ld	s0,32(sp)
    800031c0:	64e2                	ld	s1,24(sp)
    800031c2:	6145                	addi	sp,sp,48
    800031c4:	8082                	ret
    return -1;
    800031c6:	557d                	li	a0,-1
    800031c8:	bfd5                	j	800031bc <sys_sbrk+0x3c>

00000000800031ca <sys_sleep>:

uint64
sys_sleep(void)
{
    800031ca:	7139                	addi	sp,sp,-64
    800031cc:	fc06                	sd	ra,56(sp)
    800031ce:	f822                	sd	s0,48(sp)
    800031d0:	f426                	sd	s1,40(sp)
    800031d2:	f04a                	sd	s2,32(sp)
    800031d4:	ec4e                	sd	s3,24(sp)
    800031d6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800031d8:	fcc40593          	addi	a1,s0,-52
    800031dc:	4501                	li	a0,0
    800031de:	00000097          	auipc	ra,0x0
    800031e2:	e2a080e7          	jalr	-470(ra) # 80003008 <argint>
    return -1;
    800031e6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800031e8:	06054563          	bltz	a0,80003252 <sys_sleep+0x88>
  acquire(&tickslock);
    800031ec:	00015517          	auipc	a0,0x15
    800031f0:	a2450513          	addi	a0,a0,-1500 # 80017c10 <tickslock>
    800031f4:	ffffe097          	auipc	ra,0xffffe
    800031f8:	9f0080e7          	jalr	-1552(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800031fc:	00006917          	auipc	s2,0x6
    80003200:	e3492903          	lw	s2,-460(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003204:	fcc42783          	lw	a5,-52(s0)
    80003208:	cf85                	beqz	a5,80003240 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000320a:	00015997          	auipc	s3,0x15
    8000320e:	a0698993          	addi	s3,s3,-1530 # 80017c10 <tickslock>
    80003212:	00006497          	auipc	s1,0x6
    80003216:	e1e48493          	addi	s1,s1,-482 # 80009030 <ticks>
    if(myproc()->killed){
    8000321a:	fffff097          	auipc	ra,0xfffff
    8000321e:	ab4080e7          	jalr	-1356(ra) # 80001cce <myproc>
    80003222:	551c                	lw	a5,40(a0)
    80003224:	ef9d                	bnez	a5,80003262 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003226:	85ce                	mv	a1,s3
    80003228:	8526                	mv	a0,s1
    8000322a:	fffff097          	auipc	ra,0xfffff
    8000322e:	2a4080e7          	jalr	676(ra) # 800024ce <sleep>
  while(ticks - ticks0 < n){
    80003232:	409c                	lw	a5,0(s1)
    80003234:	412787bb          	subw	a5,a5,s2
    80003238:	fcc42703          	lw	a4,-52(s0)
    8000323c:	fce7efe3          	bltu	a5,a4,8000321a <sys_sleep+0x50>
  }
  release(&tickslock);
    80003240:	00015517          	auipc	a0,0x15
    80003244:	9d050513          	addi	a0,a0,-1584 # 80017c10 <tickslock>
    80003248:	ffffe097          	auipc	ra,0xffffe
    8000324c:	a50080e7          	jalr	-1456(ra) # 80000c98 <release>
  return 0;
    80003250:	4781                	li	a5,0
}
    80003252:	853e                	mv	a0,a5
    80003254:	70e2                	ld	ra,56(sp)
    80003256:	7442                	ld	s0,48(sp)
    80003258:	74a2                	ld	s1,40(sp)
    8000325a:	7902                	ld	s2,32(sp)
    8000325c:	69e2                	ld	s3,24(sp)
    8000325e:	6121                	addi	sp,sp,64
    80003260:	8082                	ret
      release(&tickslock);
    80003262:	00015517          	auipc	a0,0x15
    80003266:	9ae50513          	addi	a0,a0,-1618 # 80017c10 <tickslock>
    8000326a:	ffffe097          	auipc	ra,0xffffe
    8000326e:	a2e080e7          	jalr	-1490(ra) # 80000c98 <release>
      return -1;
    80003272:	57fd                	li	a5,-1
    80003274:	bff9                	j	80003252 <sys_sleep+0x88>

0000000080003276 <sys_kill>:

uint64
sys_kill(void)
{
    80003276:	1101                	addi	sp,sp,-32
    80003278:	ec06                	sd	ra,24(sp)
    8000327a:	e822                	sd	s0,16(sp)
    8000327c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000327e:	fec40593          	addi	a1,s0,-20
    80003282:	4501                	li	a0,0
    80003284:	00000097          	auipc	ra,0x0
    80003288:	d84080e7          	jalr	-636(ra) # 80003008 <argint>
    8000328c:	87aa                	mv	a5,a0
    return -1;
    8000328e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003290:	0007c863          	bltz	a5,800032a0 <sys_kill+0x2a>
  return kill(pid);
    80003294:	fec42503          	lw	a0,-20(s0)
    80003298:	fffff097          	auipc	ra,0xfffff
    8000329c:	5fe080e7          	jalr	1534(ra) # 80002896 <kill>
}
    800032a0:	60e2                	ld	ra,24(sp)
    800032a2:	6442                	ld	s0,16(sp)
    800032a4:	6105                	addi	sp,sp,32
    800032a6:	8082                	ret

00000000800032a8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800032a8:	1101                	addi	sp,sp,-32
    800032aa:	ec06                	sd	ra,24(sp)
    800032ac:	e822                	sd	s0,16(sp)
    800032ae:	e426                	sd	s1,8(sp)
    800032b0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800032b2:	00015517          	auipc	a0,0x15
    800032b6:	95e50513          	addi	a0,a0,-1698 # 80017c10 <tickslock>
    800032ba:	ffffe097          	auipc	ra,0xffffe
    800032be:	92a080e7          	jalr	-1750(ra) # 80000be4 <acquire>
  xticks = ticks;
    800032c2:	00006497          	auipc	s1,0x6
    800032c6:	d6e4a483          	lw	s1,-658(s1) # 80009030 <ticks>
  release(&tickslock);
    800032ca:	00015517          	auipc	a0,0x15
    800032ce:	94650513          	addi	a0,a0,-1722 # 80017c10 <tickslock>
    800032d2:	ffffe097          	auipc	ra,0xffffe
    800032d6:	9c6080e7          	jalr	-1594(ra) # 80000c98 <release>
  return xticks;
}
    800032da:	02049513          	slli	a0,s1,0x20
    800032de:	9101                	srli	a0,a0,0x20
    800032e0:	60e2                	ld	ra,24(sp)
    800032e2:	6442                	ld	s0,16(sp)
    800032e4:	64a2                	ld	s1,8(sp)
    800032e6:	6105                	addi	sp,sp,32
    800032e8:	8082                	ret

00000000800032ea <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800032ea:	7179                	addi	sp,sp,-48
    800032ec:	f406                	sd	ra,40(sp)
    800032ee:	f022                	sd	s0,32(sp)
    800032f0:	ec26                	sd	s1,24(sp)
    800032f2:	e84a                	sd	s2,16(sp)
    800032f4:	e44e                	sd	s3,8(sp)
    800032f6:	e052                	sd	s4,0(sp)
    800032f8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800032fa:	00005597          	auipc	a1,0x5
    800032fe:	28658593          	addi	a1,a1,646 # 80008580 <syscalls+0xb0>
    80003302:	00015517          	auipc	a0,0x15
    80003306:	92650513          	addi	a0,a0,-1754 # 80017c28 <bcache>
    8000330a:	ffffe097          	auipc	ra,0xffffe
    8000330e:	84a080e7          	jalr	-1974(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003312:	0001d797          	auipc	a5,0x1d
    80003316:	91678793          	addi	a5,a5,-1770 # 8001fc28 <bcache+0x8000>
    8000331a:	0001d717          	auipc	a4,0x1d
    8000331e:	b7670713          	addi	a4,a4,-1162 # 8001fe90 <bcache+0x8268>
    80003322:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003326:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000332a:	00015497          	auipc	s1,0x15
    8000332e:	91648493          	addi	s1,s1,-1770 # 80017c40 <bcache+0x18>
    b->next = bcache.head.next;
    80003332:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003334:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003336:	00005a17          	auipc	s4,0x5
    8000333a:	252a0a13          	addi	s4,s4,594 # 80008588 <syscalls+0xb8>
    b->next = bcache.head.next;
    8000333e:	2b893783          	ld	a5,696(s2)
    80003342:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003344:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003348:	85d2                	mv	a1,s4
    8000334a:	01048513          	addi	a0,s1,16
    8000334e:	00001097          	auipc	ra,0x1
    80003352:	4bc080e7          	jalr	1212(ra) # 8000480a <initsleeplock>
    bcache.head.next->prev = b;
    80003356:	2b893783          	ld	a5,696(s2)
    8000335a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000335c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003360:	45848493          	addi	s1,s1,1112
    80003364:	fd349de3          	bne	s1,s3,8000333e <binit+0x54>
  }
}
    80003368:	70a2                	ld	ra,40(sp)
    8000336a:	7402                	ld	s0,32(sp)
    8000336c:	64e2                	ld	s1,24(sp)
    8000336e:	6942                	ld	s2,16(sp)
    80003370:	69a2                	ld	s3,8(sp)
    80003372:	6a02                	ld	s4,0(sp)
    80003374:	6145                	addi	sp,sp,48
    80003376:	8082                	ret

0000000080003378 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003378:	7179                	addi	sp,sp,-48
    8000337a:	f406                	sd	ra,40(sp)
    8000337c:	f022                	sd	s0,32(sp)
    8000337e:	ec26                	sd	s1,24(sp)
    80003380:	e84a                	sd	s2,16(sp)
    80003382:	e44e                	sd	s3,8(sp)
    80003384:	1800                	addi	s0,sp,48
    80003386:	89aa                	mv	s3,a0
    80003388:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000338a:	00015517          	auipc	a0,0x15
    8000338e:	89e50513          	addi	a0,a0,-1890 # 80017c28 <bcache>
    80003392:	ffffe097          	auipc	ra,0xffffe
    80003396:	852080e7          	jalr	-1966(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000339a:	0001d497          	auipc	s1,0x1d
    8000339e:	b464b483          	ld	s1,-1210(s1) # 8001fee0 <bcache+0x82b8>
    800033a2:	0001d797          	auipc	a5,0x1d
    800033a6:	aee78793          	addi	a5,a5,-1298 # 8001fe90 <bcache+0x8268>
    800033aa:	02f48f63          	beq	s1,a5,800033e8 <bread+0x70>
    800033ae:	873e                	mv	a4,a5
    800033b0:	a021                	j	800033b8 <bread+0x40>
    800033b2:	68a4                	ld	s1,80(s1)
    800033b4:	02e48a63          	beq	s1,a4,800033e8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800033b8:	449c                	lw	a5,8(s1)
    800033ba:	ff379ce3          	bne	a5,s3,800033b2 <bread+0x3a>
    800033be:	44dc                	lw	a5,12(s1)
    800033c0:	ff2799e3          	bne	a5,s2,800033b2 <bread+0x3a>
      b->refcnt++;
    800033c4:	40bc                	lw	a5,64(s1)
    800033c6:	2785                	addiw	a5,a5,1
    800033c8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033ca:	00015517          	auipc	a0,0x15
    800033ce:	85e50513          	addi	a0,a0,-1954 # 80017c28 <bcache>
    800033d2:	ffffe097          	auipc	ra,0xffffe
    800033d6:	8c6080e7          	jalr	-1850(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800033da:	01048513          	addi	a0,s1,16
    800033de:	00001097          	auipc	ra,0x1
    800033e2:	466080e7          	jalr	1126(ra) # 80004844 <acquiresleep>
      return b;
    800033e6:	a8b9                	j	80003444 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033e8:	0001d497          	auipc	s1,0x1d
    800033ec:	af04b483          	ld	s1,-1296(s1) # 8001fed8 <bcache+0x82b0>
    800033f0:	0001d797          	auipc	a5,0x1d
    800033f4:	aa078793          	addi	a5,a5,-1376 # 8001fe90 <bcache+0x8268>
    800033f8:	00f48863          	beq	s1,a5,80003408 <bread+0x90>
    800033fc:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800033fe:	40bc                	lw	a5,64(s1)
    80003400:	cf81                	beqz	a5,80003418 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003402:	64a4                	ld	s1,72(s1)
    80003404:	fee49de3          	bne	s1,a4,800033fe <bread+0x86>
  panic("bget: no buffers");
    80003408:	00005517          	auipc	a0,0x5
    8000340c:	18850513          	addi	a0,a0,392 # 80008590 <syscalls+0xc0>
    80003410:	ffffd097          	auipc	ra,0xffffd
    80003414:	12e080e7          	jalr	302(ra) # 8000053e <panic>
      b->dev = dev;
    80003418:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000341c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003420:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003424:	4785                	li	a5,1
    80003426:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003428:	00015517          	auipc	a0,0x15
    8000342c:	80050513          	addi	a0,a0,-2048 # 80017c28 <bcache>
    80003430:	ffffe097          	auipc	ra,0xffffe
    80003434:	868080e7          	jalr	-1944(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003438:	01048513          	addi	a0,s1,16
    8000343c:	00001097          	auipc	ra,0x1
    80003440:	408080e7          	jalr	1032(ra) # 80004844 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003444:	409c                	lw	a5,0(s1)
    80003446:	cb89                	beqz	a5,80003458 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003448:	8526                	mv	a0,s1
    8000344a:	70a2                	ld	ra,40(sp)
    8000344c:	7402                	ld	s0,32(sp)
    8000344e:	64e2                	ld	s1,24(sp)
    80003450:	6942                	ld	s2,16(sp)
    80003452:	69a2                	ld	s3,8(sp)
    80003454:	6145                	addi	sp,sp,48
    80003456:	8082                	ret
    virtio_disk_rw(b, 0);
    80003458:	4581                	li	a1,0
    8000345a:	8526                	mv	a0,s1
    8000345c:	00003097          	auipc	ra,0x3
    80003460:	f0a080e7          	jalr	-246(ra) # 80006366 <virtio_disk_rw>
    b->valid = 1;
    80003464:	4785                	li	a5,1
    80003466:	c09c                	sw	a5,0(s1)
  return b;
    80003468:	b7c5                	j	80003448 <bread+0xd0>

000000008000346a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000346a:	1101                	addi	sp,sp,-32
    8000346c:	ec06                	sd	ra,24(sp)
    8000346e:	e822                	sd	s0,16(sp)
    80003470:	e426                	sd	s1,8(sp)
    80003472:	1000                	addi	s0,sp,32
    80003474:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003476:	0541                	addi	a0,a0,16
    80003478:	00001097          	auipc	ra,0x1
    8000347c:	466080e7          	jalr	1126(ra) # 800048de <holdingsleep>
    80003480:	cd01                	beqz	a0,80003498 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003482:	4585                	li	a1,1
    80003484:	8526                	mv	a0,s1
    80003486:	00003097          	auipc	ra,0x3
    8000348a:	ee0080e7          	jalr	-288(ra) # 80006366 <virtio_disk_rw>
}
    8000348e:	60e2                	ld	ra,24(sp)
    80003490:	6442                	ld	s0,16(sp)
    80003492:	64a2                	ld	s1,8(sp)
    80003494:	6105                	addi	sp,sp,32
    80003496:	8082                	ret
    panic("bwrite");
    80003498:	00005517          	auipc	a0,0x5
    8000349c:	11050513          	addi	a0,a0,272 # 800085a8 <syscalls+0xd8>
    800034a0:	ffffd097          	auipc	ra,0xffffd
    800034a4:	09e080e7          	jalr	158(ra) # 8000053e <panic>

00000000800034a8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034a8:	1101                	addi	sp,sp,-32
    800034aa:	ec06                	sd	ra,24(sp)
    800034ac:	e822                	sd	s0,16(sp)
    800034ae:	e426                	sd	s1,8(sp)
    800034b0:	e04a                	sd	s2,0(sp)
    800034b2:	1000                	addi	s0,sp,32
    800034b4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034b6:	01050913          	addi	s2,a0,16
    800034ba:	854a                	mv	a0,s2
    800034bc:	00001097          	auipc	ra,0x1
    800034c0:	422080e7          	jalr	1058(ra) # 800048de <holdingsleep>
    800034c4:	c92d                	beqz	a0,80003536 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800034c6:	854a                	mv	a0,s2
    800034c8:	00001097          	auipc	ra,0x1
    800034cc:	3d2080e7          	jalr	978(ra) # 8000489a <releasesleep>

  acquire(&bcache.lock);
    800034d0:	00014517          	auipc	a0,0x14
    800034d4:	75850513          	addi	a0,a0,1880 # 80017c28 <bcache>
    800034d8:	ffffd097          	auipc	ra,0xffffd
    800034dc:	70c080e7          	jalr	1804(ra) # 80000be4 <acquire>
  b->refcnt--;
    800034e0:	40bc                	lw	a5,64(s1)
    800034e2:	37fd                	addiw	a5,a5,-1
    800034e4:	0007871b          	sext.w	a4,a5
    800034e8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800034ea:	eb05                	bnez	a4,8000351a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800034ec:	68bc                	ld	a5,80(s1)
    800034ee:	64b8                	ld	a4,72(s1)
    800034f0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800034f2:	64bc                	ld	a5,72(s1)
    800034f4:	68b8                	ld	a4,80(s1)
    800034f6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800034f8:	0001c797          	auipc	a5,0x1c
    800034fc:	73078793          	addi	a5,a5,1840 # 8001fc28 <bcache+0x8000>
    80003500:	2b87b703          	ld	a4,696(a5)
    80003504:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003506:	0001d717          	auipc	a4,0x1d
    8000350a:	98a70713          	addi	a4,a4,-1654 # 8001fe90 <bcache+0x8268>
    8000350e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003510:	2b87b703          	ld	a4,696(a5)
    80003514:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003516:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000351a:	00014517          	auipc	a0,0x14
    8000351e:	70e50513          	addi	a0,a0,1806 # 80017c28 <bcache>
    80003522:	ffffd097          	auipc	ra,0xffffd
    80003526:	776080e7          	jalr	1910(ra) # 80000c98 <release>
}
    8000352a:	60e2                	ld	ra,24(sp)
    8000352c:	6442                	ld	s0,16(sp)
    8000352e:	64a2                	ld	s1,8(sp)
    80003530:	6902                	ld	s2,0(sp)
    80003532:	6105                	addi	sp,sp,32
    80003534:	8082                	ret
    panic("brelse");
    80003536:	00005517          	auipc	a0,0x5
    8000353a:	07a50513          	addi	a0,a0,122 # 800085b0 <syscalls+0xe0>
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	000080e7          	jalr	ra # 8000053e <panic>

0000000080003546 <bpin>:

void
bpin(struct buf *b) {
    80003546:	1101                	addi	sp,sp,-32
    80003548:	ec06                	sd	ra,24(sp)
    8000354a:	e822                	sd	s0,16(sp)
    8000354c:	e426                	sd	s1,8(sp)
    8000354e:	1000                	addi	s0,sp,32
    80003550:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003552:	00014517          	auipc	a0,0x14
    80003556:	6d650513          	addi	a0,a0,1750 # 80017c28 <bcache>
    8000355a:	ffffd097          	auipc	ra,0xffffd
    8000355e:	68a080e7          	jalr	1674(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003562:	40bc                	lw	a5,64(s1)
    80003564:	2785                	addiw	a5,a5,1
    80003566:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003568:	00014517          	auipc	a0,0x14
    8000356c:	6c050513          	addi	a0,a0,1728 # 80017c28 <bcache>
    80003570:	ffffd097          	auipc	ra,0xffffd
    80003574:	728080e7          	jalr	1832(ra) # 80000c98 <release>
}
    80003578:	60e2                	ld	ra,24(sp)
    8000357a:	6442                	ld	s0,16(sp)
    8000357c:	64a2                	ld	s1,8(sp)
    8000357e:	6105                	addi	sp,sp,32
    80003580:	8082                	ret

0000000080003582 <bunpin>:

void
bunpin(struct buf *b) {
    80003582:	1101                	addi	sp,sp,-32
    80003584:	ec06                	sd	ra,24(sp)
    80003586:	e822                	sd	s0,16(sp)
    80003588:	e426                	sd	s1,8(sp)
    8000358a:	1000                	addi	s0,sp,32
    8000358c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000358e:	00014517          	auipc	a0,0x14
    80003592:	69a50513          	addi	a0,a0,1690 # 80017c28 <bcache>
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	64e080e7          	jalr	1614(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000359e:	40bc                	lw	a5,64(s1)
    800035a0:	37fd                	addiw	a5,a5,-1
    800035a2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035a4:	00014517          	auipc	a0,0x14
    800035a8:	68450513          	addi	a0,a0,1668 # 80017c28 <bcache>
    800035ac:	ffffd097          	auipc	ra,0xffffd
    800035b0:	6ec080e7          	jalr	1772(ra) # 80000c98 <release>
}
    800035b4:	60e2                	ld	ra,24(sp)
    800035b6:	6442                	ld	s0,16(sp)
    800035b8:	64a2                	ld	s1,8(sp)
    800035ba:	6105                	addi	sp,sp,32
    800035bc:	8082                	ret

00000000800035be <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035be:	1101                	addi	sp,sp,-32
    800035c0:	ec06                	sd	ra,24(sp)
    800035c2:	e822                	sd	s0,16(sp)
    800035c4:	e426                	sd	s1,8(sp)
    800035c6:	e04a                	sd	s2,0(sp)
    800035c8:	1000                	addi	s0,sp,32
    800035ca:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035cc:	00d5d59b          	srliw	a1,a1,0xd
    800035d0:	0001d797          	auipc	a5,0x1d
    800035d4:	d347a783          	lw	a5,-716(a5) # 80020304 <sb+0x1c>
    800035d8:	9dbd                	addw	a1,a1,a5
    800035da:	00000097          	auipc	ra,0x0
    800035de:	d9e080e7          	jalr	-610(ra) # 80003378 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800035e2:	0074f713          	andi	a4,s1,7
    800035e6:	4785                	li	a5,1
    800035e8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800035ec:	14ce                	slli	s1,s1,0x33
    800035ee:	90d9                	srli	s1,s1,0x36
    800035f0:	00950733          	add	a4,a0,s1
    800035f4:	05874703          	lbu	a4,88(a4)
    800035f8:	00e7f6b3          	and	a3,a5,a4
    800035fc:	c69d                	beqz	a3,8000362a <bfree+0x6c>
    800035fe:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003600:	94aa                	add	s1,s1,a0
    80003602:	fff7c793          	not	a5,a5
    80003606:	8ff9                	and	a5,a5,a4
    80003608:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000360c:	00001097          	auipc	ra,0x1
    80003610:	118080e7          	jalr	280(ra) # 80004724 <log_write>
  brelse(bp);
    80003614:	854a                	mv	a0,s2
    80003616:	00000097          	auipc	ra,0x0
    8000361a:	e92080e7          	jalr	-366(ra) # 800034a8 <brelse>
}
    8000361e:	60e2                	ld	ra,24(sp)
    80003620:	6442                	ld	s0,16(sp)
    80003622:	64a2                	ld	s1,8(sp)
    80003624:	6902                	ld	s2,0(sp)
    80003626:	6105                	addi	sp,sp,32
    80003628:	8082                	ret
    panic("freeing free block");
    8000362a:	00005517          	auipc	a0,0x5
    8000362e:	f8e50513          	addi	a0,a0,-114 # 800085b8 <syscalls+0xe8>
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	f0c080e7          	jalr	-244(ra) # 8000053e <panic>

000000008000363a <balloc>:
{
    8000363a:	711d                	addi	sp,sp,-96
    8000363c:	ec86                	sd	ra,88(sp)
    8000363e:	e8a2                	sd	s0,80(sp)
    80003640:	e4a6                	sd	s1,72(sp)
    80003642:	e0ca                	sd	s2,64(sp)
    80003644:	fc4e                	sd	s3,56(sp)
    80003646:	f852                	sd	s4,48(sp)
    80003648:	f456                	sd	s5,40(sp)
    8000364a:	f05a                	sd	s6,32(sp)
    8000364c:	ec5e                	sd	s7,24(sp)
    8000364e:	e862                	sd	s8,16(sp)
    80003650:	e466                	sd	s9,8(sp)
    80003652:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003654:	0001d797          	auipc	a5,0x1d
    80003658:	c987a783          	lw	a5,-872(a5) # 800202ec <sb+0x4>
    8000365c:	cbd1                	beqz	a5,800036f0 <balloc+0xb6>
    8000365e:	8baa                	mv	s7,a0
    80003660:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003662:	0001db17          	auipc	s6,0x1d
    80003666:	c86b0b13          	addi	s6,s6,-890 # 800202e8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000366a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000366c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000366e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003670:	6c89                	lui	s9,0x2
    80003672:	a831                	j	8000368e <balloc+0x54>
    brelse(bp);
    80003674:	854a                	mv	a0,s2
    80003676:	00000097          	auipc	ra,0x0
    8000367a:	e32080e7          	jalr	-462(ra) # 800034a8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000367e:	015c87bb          	addw	a5,s9,s5
    80003682:	00078a9b          	sext.w	s5,a5
    80003686:	004b2703          	lw	a4,4(s6)
    8000368a:	06eaf363          	bgeu	s5,a4,800036f0 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000368e:	41fad79b          	sraiw	a5,s5,0x1f
    80003692:	0137d79b          	srliw	a5,a5,0x13
    80003696:	015787bb          	addw	a5,a5,s5
    8000369a:	40d7d79b          	sraiw	a5,a5,0xd
    8000369e:	01cb2583          	lw	a1,28(s6)
    800036a2:	9dbd                	addw	a1,a1,a5
    800036a4:	855e                	mv	a0,s7
    800036a6:	00000097          	auipc	ra,0x0
    800036aa:	cd2080e7          	jalr	-814(ra) # 80003378 <bread>
    800036ae:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036b0:	004b2503          	lw	a0,4(s6)
    800036b4:	000a849b          	sext.w	s1,s5
    800036b8:	8662                	mv	a2,s8
    800036ba:	faa4fde3          	bgeu	s1,a0,80003674 <balloc+0x3a>
      m = 1 << (bi % 8);
    800036be:	41f6579b          	sraiw	a5,a2,0x1f
    800036c2:	01d7d69b          	srliw	a3,a5,0x1d
    800036c6:	00c6873b          	addw	a4,a3,a2
    800036ca:	00777793          	andi	a5,a4,7
    800036ce:	9f95                	subw	a5,a5,a3
    800036d0:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036d4:	4037571b          	sraiw	a4,a4,0x3
    800036d8:	00e906b3          	add	a3,s2,a4
    800036dc:	0586c683          	lbu	a3,88(a3)
    800036e0:	00d7f5b3          	and	a1,a5,a3
    800036e4:	cd91                	beqz	a1,80003700 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036e6:	2605                	addiw	a2,a2,1
    800036e8:	2485                	addiw	s1,s1,1
    800036ea:	fd4618e3          	bne	a2,s4,800036ba <balloc+0x80>
    800036ee:	b759                	j	80003674 <balloc+0x3a>
  panic("balloc: out of blocks");
    800036f0:	00005517          	auipc	a0,0x5
    800036f4:	ee050513          	addi	a0,a0,-288 # 800085d0 <syscalls+0x100>
    800036f8:	ffffd097          	auipc	ra,0xffffd
    800036fc:	e46080e7          	jalr	-442(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003700:	974a                	add	a4,a4,s2
    80003702:	8fd5                	or	a5,a5,a3
    80003704:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003708:	854a                	mv	a0,s2
    8000370a:	00001097          	auipc	ra,0x1
    8000370e:	01a080e7          	jalr	26(ra) # 80004724 <log_write>
        brelse(bp);
    80003712:	854a                	mv	a0,s2
    80003714:	00000097          	auipc	ra,0x0
    80003718:	d94080e7          	jalr	-620(ra) # 800034a8 <brelse>
  bp = bread(dev, bno);
    8000371c:	85a6                	mv	a1,s1
    8000371e:	855e                	mv	a0,s7
    80003720:	00000097          	auipc	ra,0x0
    80003724:	c58080e7          	jalr	-936(ra) # 80003378 <bread>
    80003728:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000372a:	40000613          	li	a2,1024
    8000372e:	4581                	li	a1,0
    80003730:	05850513          	addi	a0,a0,88
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	5ac080e7          	jalr	1452(ra) # 80000ce0 <memset>
  log_write(bp);
    8000373c:	854a                	mv	a0,s2
    8000373e:	00001097          	auipc	ra,0x1
    80003742:	fe6080e7          	jalr	-26(ra) # 80004724 <log_write>
  brelse(bp);
    80003746:	854a                	mv	a0,s2
    80003748:	00000097          	auipc	ra,0x0
    8000374c:	d60080e7          	jalr	-672(ra) # 800034a8 <brelse>
}
    80003750:	8526                	mv	a0,s1
    80003752:	60e6                	ld	ra,88(sp)
    80003754:	6446                	ld	s0,80(sp)
    80003756:	64a6                	ld	s1,72(sp)
    80003758:	6906                	ld	s2,64(sp)
    8000375a:	79e2                	ld	s3,56(sp)
    8000375c:	7a42                	ld	s4,48(sp)
    8000375e:	7aa2                	ld	s5,40(sp)
    80003760:	7b02                	ld	s6,32(sp)
    80003762:	6be2                	ld	s7,24(sp)
    80003764:	6c42                	ld	s8,16(sp)
    80003766:	6ca2                	ld	s9,8(sp)
    80003768:	6125                	addi	sp,sp,96
    8000376a:	8082                	ret

000000008000376c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000376c:	7179                	addi	sp,sp,-48
    8000376e:	f406                	sd	ra,40(sp)
    80003770:	f022                	sd	s0,32(sp)
    80003772:	ec26                	sd	s1,24(sp)
    80003774:	e84a                	sd	s2,16(sp)
    80003776:	e44e                	sd	s3,8(sp)
    80003778:	e052                	sd	s4,0(sp)
    8000377a:	1800                	addi	s0,sp,48
    8000377c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000377e:	47ad                	li	a5,11
    80003780:	04b7fe63          	bgeu	a5,a1,800037dc <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003784:	ff45849b          	addiw	s1,a1,-12
    80003788:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000378c:	0ff00793          	li	a5,255
    80003790:	0ae7e363          	bltu	a5,a4,80003836 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003794:	08052583          	lw	a1,128(a0)
    80003798:	c5ad                	beqz	a1,80003802 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000379a:	00092503          	lw	a0,0(s2)
    8000379e:	00000097          	auipc	ra,0x0
    800037a2:	bda080e7          	jalr	-1062(ra) # 80003378 <bread>
    800037a6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037a8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800037ac:	02049593          	slli	a1,s1,0x20
    800037b0:	9181                	srli	a1,a1,0x20
    800037b2:	058a                	slli	a1,a1,0x2
    800037b4:	00b784b3          	add	s1,a5,a1
    800037b8:	0004a983          	lw	s3,0(s1)
    800037bc:	04098d63          	beqz	s3,80003816 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800037c0:	8552                	mv	a0,s4
    800037c2:	00000097          	auipc	ra,0x0
    800037c6:	ce6080e7          	jalr	-794(ra) # 800034a8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037ca:	854e                	mv	a0,s3
    800037cc:	70a2                	ld	ra,40(sp)
    800037ce:	7402                	ld	s0,32(sp)
    800037d0:	64e2                	ld	s1,24(sp)
    800037d2:	6942                	ld	s2,16(sp)
    800037d4:	69a2                	ld	s3,8(sp)
    800037d6:	6a02                	ld	s4,0(sp)
    800037d8:	6145                	addi	sp,sp,48
    800037da:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800037dc:	02059493          	slli	s1,a1,0x20
    800037e0:	9081                	srli	s1,s1,0x20
    800037e2:	048a                	slli	s1,s1,0x2
    800037e4:	94aa                	add	s1,s1,a0
    800037e6:	0504a983          	lw	s3,80(s1)
    800037ea:	fe0990e3          	bnez	s3,800037ca <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800037ee:	4108                	lw	a0,0(a0)
    800037f0:	00000097          	auipc	ra,0x0
    800037f4:	e4a080e7          	jalr	-438(ra) # 8000363a <balloc>
    800037f8:	0005099b          	sext.w	s3,a0
    800037fc:	0534a823          	sw	s3,80(s1)
    80003800:	b7e9                	j	800037ca <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003802:	4108                	lw	a0,0(a0)
    80003804:	00000097          	auipc	ra,0x0
    80003808:	e36080e7          	jalr	-458(ra) # 8000363a <balloc>
    8000380c:	0005059b          	sext.w	a1,a0
    80003810:	08b92023          	sw	a1,128(s2)
    80003814:	b759                	j	8000379a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003816:	00092503          	lw	a0,0(s2)
    8000381a:	00000097          	auipc	ra,0x0
    8000381e:	e20080e7          	jalr	-480(ra) # 8000363a <balloc>
    80003822:	0005099b          	sext.w	s3,a0
    80003826:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000382a:	8552                	mv	a0,s4
    8000382c:	00001097          	auipc	ra,0x1
    80003830:	ef8080e7          	jalr	-264(ra) # 80004724 <log_write>
    80003834:	b771                	j	800037c0 <bmap+0x54>
  panic("bmap: out of range");
    80003836:	00005517          	auipc	a0,0x5
    8000383a:	db250513          	addi	a0,a0,-590 # 800085e8 <syscalls+0x118>
    8000383e:	ffffd097          	auipc	ra,0xffffd
    80003842:	d00080e7          	jalr	-768(ra) # 8000053e <panic>

0000000080003846 <iget>:
{
    80003846:	7179                	addi	sp,sp,-48
    80003848:	f406                	sd	ra,40(sp)
    8000384a:	f022                	sd	s0,32(sp)
    8000384c:	ec26                	sd	s1,24(sp)
    8000384e:	e84a                	sd	s2,16(sp)
    80003850:	e44e                	sd	s3,8(sp)
    80003852:	e052                	sd	s4,0(sp)
    80003854:	1800                	addi	s0,sp,48
    80003856:	89aa                	mv	s3,a0
    80003858:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000385a:	0001d517          	auipc	a0,0x1d
    8000385e:	aae50513          	addi	a0,a0,-1362 # 80020308 <itable>
    80003862:	ffffd097          	auipc	ra,0xffffd
    80003866:	382080e7          	jalr	898(ra) # 80000be4 <acquire>
  empty = 0;
    8000386a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000386c:	0001d497          	auipc	s1,0x1d
    80003870:	ab448493          	addi	s1,s1,-1356 # 80020320 <itable+0x18>
    80003874:	0001e697          	auipc	a3,0x1e
    80003878:	53c68693          	addi	a3,a3,1340 # 80021db0 <log>
    8000387c:	a039                	j	8000388a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000387e:	02090b63          	beqz	s2,800038b4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003882:	08848493          	addi	s1,s1,136
    80003886:	02d48a63          	beq	s1,a3,800038ba <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000388a:	449c                	lw	a5,8(s1)
    8000388c:	fef059e3          	blez	a5,8000387e <iget+0x38>
    80003890:	4098                	lw	a4,0(s1)
    80003892:	ff3716e3          	bne	a4,s3,8000387e <iget+0x38>
    80003896:	40d8                	lw	a4,4(s1)
    80003898:	ff4713e3          	bne	a4,s4,8000387e <iget+0x38>
      ip->ref++;
    8000389c:	2785                	addiw	a5,a5,1
    8000389e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800038a0:	0001d517          	auipc	a0,0x1d
    800038a4:	a6850513          	addi	a0,a0,-1432 # 80020308 <itable>
    800038a8:	ffffd097          	auipc	ra,0xffffd
    800038ac:	3f0080e7          	jalr	1008(ra) # 80000c98 <release>
      return ip;
    800038b0:	8926                	mv	s2,s1
    800038b2:	a03d                	j	800038e0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038b4:	f7f9                	bnez	a5,80003882 <iget+0x3c>
    800038b6:	8926                	mv	s2,s1
    800038b8:	b7e9                	j	80003882 <iget+0x3c>
  if(empty == 0)
    800038ba:	02090c63          	beqz	s2,800038f2 <iget+0xac>
  ip->dev = dev;
    800038be:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038c2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038c6:	4785                	li	a5,1
    800038c8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038cc:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800038d0:	0001d517          	auipc	a0,0x1d
    800038d4:	a3850513          	addi	a0,a0,-1480 # 80020308 <itable>
    800038d8:	ffffd097          	auipc	ra,0xffffd
    800038dc:	3c0080e7          	jalr	960(ra) # 80000c98 <release>
}
    800038e0:	854a                	mv	a0,s2
    800038e2:	70a2                	ld	ra,40(sp)
    800038e4:	7402                	ld	s0,32(sp)
    800038e6:	64e2                	ld	s1,24(sp)
    800038e8:	6942                	ld	s2,16(sp)
    800038ea:	69a2                	ld	s3,8(sp)
    800038ec:	6a02                	ld	s4,0(sp)
    800038ee:	6145                	addi	sp,sp,48
    800038f0:	8082                	ret
    panic("iget: no inodes");
    800038f2:	00005517          	auipc	a0,0x5
    800038f6:	d0e50513          	addi	a0,a0,-754 # 80008600 <syscalls+0x130>
    800038fa:	ffffd097          	auipc	ra,0xffffd
    800038fe:	c44080e7          	jalr	-956(ra) # 8000053e <panic>

0000000080003902 <fsinit>:
fsinit(int dev) {
    80003902:	7179                	addi	sp,sp,-48
    80003904:	f406                	sd	ra,40(sp)
    80003906:	f022                	sd	s0,32(sp)
    80003908:	ec26                	sd	s1,24(sp)
    8000390a:	e84a                	sd	s2,16(sp)
    8000390c:	e44e                	sd	s3,8(sp)
    8000390e:	1800                	addi	s0,sp,48
    80003910:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003912:	4585                	li	a1,1
    80003914:	00000097          	auipc	ra,0x0
    80003918:	a64080e7          	jalr	-1436(ra) # 80003378 <bread>
    8000391c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000391e:	0001d997          	auipc	s3,0x1d
    80003922:	9ca98993          	addi	s3,s3,-1590 # 800202e8 <sb>
    80003926:	02000613          	li	a2,32
    8000392a:	05850593          	addi	a1,a0,88
    8000392e:	854e                	mv	a0,s3
    80003930:	ffffd097          	auipc	ra,0xffffd
    80003934:	410080e7          	jalr	1040(ra) # 80000d40 <memmove>
  brelse(bp);
    80003938:	8526                	mv	a0,s1
    8000393a:	00000097          	auipc	ra,0x0
    8000393e:	b6e080e7          	jalr	-1170(ra) # 800034a8 <brelse>
  if(sb.magic != FSMAGIC)
    80003942:	0009a703          	lw	a4,0(s3)
    80003946:	102037b7          	lui	a5,0x10203
    8000394a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000394e:	02f71263          	bne	a4,a5,80003972 <fsinit+0x70>
  initlog(dev, &sb);
    80003952:	0001d597          	auipc	a1,0x1d
    80003956:	99658593          	addi	a1,a1,-1642 # 800202e8 <sb>
    8000395a:	854a                	mv	a0,s2
    8000395c:	00001097          	auipc	ra,0x1
    80003960:	b4c080e7          	jalr	-1204(ra) # 800044a8 <initlog>
}
    80003964:	70a2                	ld	ra,40(sp)
    80003966:	7402                	ld	s0,32(sp)
    80003968:	64e2                	ld	s1,24(sp)
    8000396a:	6942                	ld	s2,16(sp)
    8000396c:	69a2                	ld	s3,8(sp)
    8000396e:	6145                	addi	sp,sp,48
    80003970:	8082                	ret
    panic("invalid file system");
    80003972:	00005517          	auipc	a0,0x5
    80003976:	c9e50513          	addi	a0,a0,-866 # 80008610 <syscalls+0x140>
    8000397a:	ffffd097          	auipc	ra,0xffffd
    8000397e:	bc4080e7          	jalr	-1084(ra) # 8000053e <panic>

0000000080003982 <iinit>:
{
    80003982:	7179                	addi	sp,sp,-48
    80003984:	f406                	sd	ra,40(sp)
    80003986:	f022                	sd	s0,32(sp)
    80003988:	ec26                	sd	s1,24(sp)
    8000398a:	e84a                	sd	s2,16(sp)
    8000398c:	e44e                	sd	s3,8(sp)
    8000398e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003990:	00005597          	auipc	a1,0x5
    80003994:	c9858593          	addi	a1,a1,-872 # 80008628 <syscalls+0x158>
    80003998:	0001d517          	auipc	a0,0x1d
    8000399c:	97050513          	addi	a0,a0,-1680 # 80020308 <itable>
    800039a0:	ffffd097          	auipc	ra,0xffffd
    800039a4:	1b4080e7          	jalr	436(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800039a8:	0001d497          	auipc	s1,0x1d
    800039ac:	98848493          	addi	s1,s1,-1656 # 80020330 <itable+0x28>
    800039b0:	0001e997          	auipc	s3,0x1e
    800039b4:	41098993          	addi	s3,s3,1040 # 80021dc0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800039b8:	00005917          	auipc	s2,0x5
    800039bc:	c7890913          	addi	s2,s2,-904 # 80008630 <syscalls+0x160>
    800039c0:	85ca                	mv	a1,s2
    800039c2:	8526                	mv	a0,s1
    800039c4:	00001097          	auipc	ra,0x1
    800039c8:	e46080e7          	jalr	-442(ra) # 8000480a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039cc:	08848493          	addi	s1,s1,136
    800039d0:	ff3498e3          	bne	s1,s3,800039c0 <iinit+0x3e>
}
    800039d4:	70a2                	ld	ra,40(sp)
    800039d6:	7402                	ld	s0,32(sp)
    800039d8:	64e2                	ld	s1,24(sp)
    800039da:	6942                	ld	s2,16(sp)
    800039dc:	69a2                	ld	s3,8(sp)
    800039de:	6145                	addi	sp,sp,48
    800039e0:	8082                	ret

00000000800039e2 <ialloc>:
{
    800039e2:	715d                	addi	sp,sp,-80
    800039e4:	e486                	sd	ra,72(sp)
    800039e6:	e0a2                	sd	s0,64(sp)
    800039e8:	fc26                	sd	s1,56(sp)
    800039ea:	f84a                	sd	s2,48(sp)
    800039ec:	f44e                	sd	s3,40(sp)
    800039ee:	f052                	sd	s4,32(sp)
    800039f0:	ec56                	sd	s5,24(sp)
    800039f2:	e85a                	sd	s6,16(sp)
    800039f4:	e45e                	sd	s7,8(sp)
    800039f6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800039f8:	0001d717          	auipc	a4,0x1d
    800039fc:	8fc72703          	lw	a4,-1796(a4) # 800202f4 <sb+0xc>
    80003a00:	4785                	li	a5,1
    80003a02:	04e7fa63          	bgeu	a5,a4,80003a56 <ialloc+0x74>
    80003a06:	8aaa                	mv	s5,a0
    80003a08:	8bae                	mv	s7,a1
    80003a0a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a0c:	0001da17          	auipc	s4,0x1d
    80003a10:	8dca0a13          	addi	s4,s4,-1828 # 800202e8 <sb>
    80003a14:	00048b1b          	sext.w	s6,s1
    80003a18:	0044d593          	srli	a1,s1,0x4
    80003a1c:	018a2783          	lw	a5,24(s4)
    80003a20:	9dbd                	addw	a1,a1,a5
    80003a22:	8556                	mv	a0,s5
    80003a24:	00000097          	auipc	ra,0x0
    80003a28:	954080e7          	jalr	-1708(ra) # 80003378 <bread>
    80003a2c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a2e:	05850993          	addi	s3,a0,88
    80003a32:	00f4f793          	andi	a5,s1,15
    80003a36:	079a                	slli	a5,a5,0x6
    80003a38:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a3a:	00099783          	lh	a5,0(s3)
    80003a3e:	c785                	beqz	a5,80003a66 <ialloc+0x84>
    brelse(bp);
    80003a40:	00000097          	auipc	ra,0x0
    80003a44:	a68080e7          	jalr	-1432(ra) # 800034a8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a48:	0485                	addi	s1,s1,1
    80003a4a:	00ca2703          	lw	a4,12(s4)
    80003a4e:	0004879b          	sext.w	a5,s1
    80003a52:	fce7e1e3          	bltu	a5,a4,80003a14 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003a56:	00005517          	auipc	a0,0x5
    80003a5a:	be250513          	addi	a0,a0,-1054 # 80008638 <syscalls+0x168>
    80003a5e:	ffffd097          	auipc	ra,0xffffd
    80003a62:	ae0080e7          	jalr	-1312(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003a66:	04000613          	li	a2,64
    80003a6a:	4581                	li	a1,0
    80003a6c:	854e                	mv	a0,s3
    80003a6e:	ffffd097          	auipc	ra,0xffffd
    80003a72:	272080e7          	jalr	626(ra) # 80000ce0 <memset>
      dip->type = type;
    80003a76:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a7a:	854a                	mv	a0,s2
    80003a7c:	00001097          	auipc	ra,0x1
    80003a80:	ca8080e7          	jalr	-856(ra) # 80004724 <log_write>
      brelse(bp);
    80003a84:	854a                	mv	a0,s2
    80003a86:	00000097          	auipc	ra,0x0
    80003a8a:	a22080e7          	jalr	-1502(ra) # 800034a8 <brelse>
      return iget(dev, inum);
    80003a8e:	85da                	mv	a1,s6
    80003a90:	8556                	mv	a0,s5
    80003a92:	00000097          	auipc	ra,0x0
    80003a96:	db4080e7          	jalr	-588(ra) # 80003846 <iget>
}
    80003a9a:	60a6                	ld	ra,72(sp)
    80003a9c:	6406                	ld	s0,64(sp)
    80003a9e:	74e2                	ld	s1,56(sp)
    80003aa0:	7942                	ld	s2,48(sp)
    80003aa2:	79a2                	ld	s3,40(sp)
    80003aa4:	7a02                	ld	s4,32(sp)
    80003aa6:	6ae2                	ld	s5,24(sp)
    80003aa8:	6b42                	ld	s6,16(sp)
    80003aaa:	6ba2                	ld	s7,8(sp)
    80003aac:	6161                	addi	sp,sp,80
    80003aae:	8082                	ret

0000000080003ab0 <iupdate>:
{
    80003ab0:	1101                	addi	sp,sp,-32
    80003ab2:	ec06                	sd	ra,24(sp)
    80003ab4:	e822                	sd	s0,16(sp)
    80003ab6:	e426                	sd	s1,8(sp)
    80003ab8:	e04a                	sd	s2,0(sp)
    80003aba:	1000                	addi	s0,sp,32
    80003abc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003abe:	415c                	lw	a5,4(a0)
    80003ac0:	0047d79b          	srliw	a5,a5,0x4
    80003ac4:	0001d597          	auipc	a1,0x1d
    80003ac8:	83c5a583          	lw	a1,-1988(a1) # 80020300 <sb+0x18>
    80003acc:	9dbd                	addw	a1,a1,a5
    80003ace:	4108                	lw	a0,0(a0)
    80003ad0:	00000097          	auipc	ra,0x0
    80003ad4:	8a8080e7          	jalr	-1880(ra) # 80003378 <bread>
    80003ad8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ada:	05850793          	addi	a5,a0,88
    80003ade:	40c8                	lw	a0,4(s1)
    80003ae0:	893d                	andi	a0,a0,15
    80003ae2:	051a                	slli	a0,a0,0x6
    80003ae4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003ae6:	04449703          	lh	a4,68(s1)
    80003aea:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003aee:	04649703          	lh	a4,70(s1)
    80003af2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003af6:	04849703          	lh	a4,72(s1)
    80003afa:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003afe:	04a49703          	lh	a4,74(s1)
    80003b02:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b06:	44f8                	lw	a4,76(s1)
    80003b08:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b0a:	03400613          	li	a2,52
    80003b0e:	05048593          	addi	a1,s1,80
    80003b12:	0531                	addi	a0,a0,12
    80003b14:	ffffd097          	auipc	ra,0xffffd
    80003b18:	22c080e7          	jalr	556(ra) # 80000d40 <memmove>
  log_write(bp);
    80003b1c:	854a                	mv	a0,s2
    80003b1e:	00001097          	auipc	ra,0x1
    80003b22:	c06080e7          	jalr	-1018(ra) # 80004724 <log_write>
  brelse(bp);
    80003b26:	854a                	mv	a0,s2
    80003b28:	00000097          	auipc	ra,0x0
    80003b2c:	980080e7          	jalr	-1664(ra) # 800034a8 <brelse>
}
    80003b30:	60e2                	ld	ra,24(sp)
    80003b32:	6442                	ld	s0,16(sp)
    80003b34:	64a2                	ld	s1,8(sp)
    80003b36:	6902                	ld	s2,0(sp)
    80003b38:	6105                	addi	sp,sp,32
    80003b3a:	8082                	ret

0000000080003b3c <idup>:
{
    80003b3c:	1101                	addi	sp,sp,-32
    80003b3e:	ec06                	sd	ra,24(sp)
    80003b40:	e822                	sd	s0,16(sp)
    80003b42:	e426                	sd	s1,8(sp)
    80003b44:	1000                	addi	s0,sp,32
    80003b46:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b48:	0001c517          	auipc	a0,0x1c
    80003b4c:	7c050513          	addi	a0,a0,1984 # 80020308 <itable>
    80003b50:	ffffd097          	auipc	ra,0xffffd
    80003b54:	094080e7          	jalr	148(ra) # 80000be4 <acquire>
  ip->ref++;
    80003b58:	449c                	lw	a5,8(s1)
    80003b5a:	2785                	addiw	a5,a5,1
    80003b5c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b5e:	0001c517          	auipc	a0,0x1c
    80003b62:	7aa50513          	addi	a0,a0,1962 # 80020308 <itable>
    80003b66:	ffffd097          	auipc	ra,0xffffd
    80003b6a:	132080e7          	jalr	306(ra) # 80000c98 <release>
}
    80003b6e:	8526                	mv	a0,s1
    80003b70:	60e2                	ld	ra,24(sp)
    80003b72:	6442                	ld	s0,16(sp)
    80003b74:	64a2                	ld	s1,8(sp)
    80003b76:	6105                	addi	sp,sp,32
    80003b78:	8082                	ret

0000000080003b7a <ilock>:
{
    80003b7a:	1101                	addi	sp,sp,-32
    80003b7c:	ec06                	sd	ra,24(sp)
    80003b7e:	e822                	sd	s0,16(sp)
    80003b80:	e426                	sd	s1,8(sp)
    80003b82:	e04a                	sd	s2,0(sp)
    80003b84:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b86:	c115                	beqz	a0,80003baa <ilock+0x30>
    80003b88:	84aa                	mv	s1,a0
    80003b8a:	451c                	lw	a5,8(a0)
    80003b8c:	00f05f63          	blez	a5,80003baa <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b90:	0541                	addi	a0,a0,16
    80003b92:	00001097          	auipc	ra,0x1
    80003b96:	cb2080e7          	jalr	-846(ra) # 80004844 <acquiresleep>
  if(ip->valid == 0){
    80003b9a:	40bc                	lw	a5,64(s1)
    80003b9c:	cf99                	beqz	a5,80003bba <ilock+0x40>
}
    80003b9e:	60e2                	ld	ra,24(sp)
    80003ba0:	6442                	ld	s0,16(sp)
    80003ba2:	64a2                	ld	s1,8(sp)
    80003ba4:	6902                	ld	s2,0(sp)
    80003ba6:	6105                	addi	sp,sp,32
    80003ba8:	8082                	ret
    panic("ilock");
    80003baa:	00005517          	auipc	a0,0x5
    80003bae:	aa650513          	addi	a0,a0,-1370 # 80008650 <syscalls+0x180>
    80003bb2:	ffffd097          	auipc	ra,0xffffd
    80003bb6:	98c080e7          	jalr	-1652(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bba:	40dc                	lw	a5,4(s1)
    80003bbc:	0047d79b          	srliw	a5,a5,0x4
    80003bc0:	0001c597          	auipc	a1,0x1c
    80003bc4:	7405a583          	lw	a1,1856(a1) # 80020300 <sb+0x18>
    80003bc8:	9dbd                	addw	a1,a1,a5
    80003bca:	4088                	lw	a0,0(s1)
    80003bcc:	fffff097          	auipc	ra,0xfffff
    80003bd0:	7ac080e7          	jalr	1964(ra) # 80003378 <bread>
    80003bd4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bd6:	05850593          	addi	a1,a0,88
    80003bda:	40dc                	lw	a5,4(s1)
    80003bdc:	8bbd                	andi	a5,a5,15
    80003bde:	079a                	slli	a5,a5,0x6
    80003be0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003be2:	00059783          	lh	a5,0(a1)
    80003be6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003bea:	00259783          	lh	a5,2(a1)
    80003bee:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003bf2:	00459783          	lh	a5,4(a1)
    80003bf6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003bfa:	00659783          	lh	a5,6(a1)
    80003bfe:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c02:	459c                	lw	a5,8(a1)
    80003c04:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c06:	03400613          	li	a2,52
    80003c0a:	05b1                	addi	a1,a1,12
    80003c0c:	05048513          	addi	a0,s1,80
    80003c10:	ffffd097          	auipc	ra,0xffffd
    80003c14:	130080e7          	jalr	304(ra) # 80000d40 <memmove>
    brelse(bp);
    80003c18:	854a                	mv	a0,s2
    80003c1a:	00000097          	auipc	ra,0x0
    80003c1e:	88e080e7          	jalr	-1906(ra) # 800034a8 <brelse>
    ip->valid = 1;
    80003c22:	4785                	li	a5,1
    80003c24:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c26:	04449783          	lh	a5,68(s1)
    80003c2a:	fbb5                	bnez	a5,80003b9e <ilock+0x24>
      panic("ilock: no type");
    80003c2c:	00005517          	auipc	a0,0x5
    80003c30:	a2c50513          	addi	a0,a0,-1492 # 80008658 <syscalls+0x188>
    80003c34:	ffffd097          	auipc	ra,0xffffd
    80003c38:	90a080e7          	jalr	-1782(ra) # 8000053e <panic>

0000000080003c3c <iunlock>:
{
    80003c3c:	1101                	addi	sp,sp,-32
    80003c3e:	ec06                	sd	ra,24(sp)
    80003c40:	e822                	sd	s0,16(sp)
    80003c42:	e426                	sd	s1,8(sp)
    80003c44:	e04a                	sd	s2,0(sp)
    80003c46:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c48:	c905                	beqz	a0,80003c78 <iunlock+0x3c>
    80003c4a:	84aa                	mv	s1,a0
    80003c4c:	01050913          	addi	s2,a0,16
    80003c50:	854a                	mv	a0,s2
    80003c52:	00001097          	auipc	ra,0x1
    80003c56:	c8c080e7          	jalr	-884(ra) # 800048de <holdingsleep>
    80003c5a:	cd19                	beqz	a0,80003c78 <iunlock+0x3c>
    80003c5c:	449c                	lw	a5,8(s1)
    80003c5e:	00f05d63          	blez	a5,80003c78 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c62:	854a                	mv	a0,s2
    80003c64:	00001097          	auipc	ra,0x1
    80003c68:	c36080e7          	jalr	-970(ra) # 8000489a <releasesleep>
}
    80003c6c:	60e2                	ld	ra,24(sp)
    80003c6e:	6442                	ld	s0,16(sp)
    80003c70:	64a2                	ld	s1,8(sp)
    80003c72:	6902                	ld	s2,0(sp)
    80003c74:	6105                	addi	sp,sp,32
    80003c76:	8082                	ret
    panic("iunlock");
    80003c78:	00005517          	auipc	a0,0x5
    80003c7c:	9f050513          	addi	a0,a0,-1552 # 80008668 <syscalls+0x198>
    80003c80:	ffffd097          	auipc	ra,0xffffd
    80003c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>

0000000080003c88 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c88:	7179                	addi	sp,sp,-48
    80003c8a:	f406                	sd	ra,40(sp)
    80003c8c:	f022                	sd	s0,32(sp)
    80003c8e:	ec26                	sd	s1,24(sp)
    80003c90:	e84a                	sd	s2,16(sp)
    80003c92:	e44e                	sd	s3,8(sp)
    80003c94:	e052                	sd	s4,0(sp)
    80003c96:	1800                	addi	s0,sp,48
    80003c98:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c9a:	05050493          	addi	s1,a0,80
    80003c9e:	08050913          	addi	s2,a0,128
    80003ca2:	a021                	j	80003caa <itrunc+0x22>
    80003ca4:	0491                	addi	s1,s1,4
    80003ca6:	01248d63          	beq	s1,s2,80003cc0 <itrunc+0x38>
    if(ip->addrs[i]){
    80003caa:	408c                	lw	a1,0(s1)
    80003cac:	dde5                	beqz	a1,80003ca4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003cae:	0009a503          	lw	a0,0(s3)
    80003cb2:	00000097          	auipc	ra,0x0
    80003cb6:	90c080e7          	jalr	-1780(ra) # 800035be <bfree>
      ip->addrs[i] = 0;
    80003cba:	0004a023          	sw	zero,0(s1)
    80003cbe:	b7dd                	j	80003ca4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003cc0:	0809a583          	lw	a1,128(s3)
    80003cc4:	e185                	bnez	a1,80003ce4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003cc6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003cca:	854e                	mv	a0,s3
    80003ccc:	00000097          	auipc	ra,0x0
    80003cd0:	de4080e7          	jalr	-540(ra) # 80003ab0 <iupdate>
}
    80003cd4:	70a2                	ld	ra,40(sp)
    80003cd6:	7402                	ld	s0,32(sp)
    80003cd8:	64e2                	ld	s1,24(sp)
    80003cda:	6942                	ld	s2,16(sp)
    80003cdc:	69a2                	ld	s3,8(sp)
    80003cde:	6a02                	ld	s4,0(sp)
    80003ce0:	6145                	addi	sp,sp,48
    80003ce2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ce4:	0009a503          	lw	a0,0(s3)
    80003ce8:	fffff097          	auipc	ra,0xfffff
    80003cec:	690080e7          	jalr	1680(ra) # 80003378 <bread>
    80003cf0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003cf2:	05850493          	addi	s1,a0,88
    80003cf6:	45850913          	addi	s2,a0,1112
    80003cfa:	a811                	j	80003d0e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003cfc:	0009a503          	lw	a0,0(s3)
    80003d00:	00000097          	auipc	ra,0x0
    80003d04:	8be080e7          	jalr	-1858(ra) # 800035be <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003d08:	0491                	addi	s1,s1,4
    80003d0a:	01248563          	beq	s1,s2,80003d14 <itrunc+0x8c>
      if(a[j])
    80003d0e:	408c                	lw	a1,0(s1)
    80003d10:	dde5                	beqz	a1,80003d08 <itrunc+0x80>
    80003d12:	b7ed                	j	80003cfc <itrunc+0x74>
    brelse(bp);
    80003d14:	8552                	mv	a0,s4
    80003d16:	fffff097          	auipc	ra,0xfffff
    80003d1a:	792080e7          	jalr	1938(ra) # 800034a8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d1e:	0809a583          	lw	a1,128(s3)
    80003d22:	0009a503          	lw	a0,0(s3)
    80003d26:	00000097          	auipc	ra,0x0
    80003d2a:	898080e7          	jalr	-1896(ra) # 800035be <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d2e:	0809a023          	sw	zero,128(s3)
    80003d32:	bf51                	j	80003cc6 <itrunc+0x3e>

0000000080003d34 <iput>:
{
    80003d34:	1101                	addi	sp,sp,-32
    80003d36:	ec06                	sd	ra,24(sp)
    80003d38:	e822                	sd	s0,16(sp)
    80003d3a:	e426                	sd	s1,8(sp)
    80003d3c:	e04a                	sd	s2,0(sp)
    80003d3e:	1000                	addi	s0,sp,32
    80003d40:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d42:	0001c517          	auipc	a0,0x1c
    80003d46:	5c650513          	addi	a0,a0,1478 # 80020308 <itable>
    80003d4a:	ffffd097          	auipc	ra,0xffffd
    80003d4e:	e9a080e7          	jalr	-358(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d52:	4498                	lw	a4,8(s1)
    80003d54:	4785                	li	a5,1
    80003d56:	02f70363          	beq	a4,a5,80003d7c <iput+0x48>
  ip->ref--;
    80003d5a:	449c                	lw	a5,8(s1)
    80003d5c:	37fd                	addiw	a5,a5,-1
    80003d5e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d60:	0001c517          	auipc	a0,0x1c
    80003d64:	5a850513          	addi	a0,a0,1448 # 80020308 <itable>
    80003d68:	ffffd097          	auipc	ra,0xffffd
    80003d6c:	f30080e7          	jalr	-208(ra) # 80000c98 <release>
}
    80003d70:	60e2                	ld	ra,24(sp)
    80003d72:	6442                	ld	s0,16(sp)
    80003d74:	64a2                	ld	s1,8(sp)
    80003d76:	6902                	ld	s2,0(sp)
    80003d78:	6105                	addi	sp,sp,32
    80003d7a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d7c:	40bc                	lw	a5,64(s1)
    80003d7e:	dff1                	beqz	a5,80003d5a <iput+0x26>
    80003d80:	04a49783          	lh	a5,74(s1)
    80003d84:	fbf9                	bnez	a5,80003d5a <iput+0x26>
    acquiresleep(&ip->lock);
    80003d86:	01048913          	addi	s2,s1,16
    80003d8a:	854a                	mv	a0,s2
    80003d8c:	00001097          	auipc	ra,0x1
    80003d90:	ab8080e7          	jalr	-1352(ra) # 80004844 <acquiresleep>
    release(&itable.lock);
    80003d94:	0001c517          	auipc	a0,0x1c
    80003d98:	57450513          	addi	a0,a0,1396 # 80020308 <itable>
    80003d9c:	ffffd097          	auipc	ra,0xffffd
    80003da0:	efc080e7          	jalr	-260(ra) # 80000c98 <release>
    itrunc(ip);
    80003da4:	8526                	mv	a0,s1
    80003da6:	00000097          	auipc	ra,0x0
    80003daa:	ee2080e7          	jalr	-286(ra) # 80003c88 <itrunc>
    ip->type = 0;
    80003dae:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003db2:	8526                	mv	a0,s1
    80003db4:	00000097          	auipc	ra,0x0
    80003db8:	cfc080e7          	jalr	-772(ra) # 80003ab0 <iupdate>
    ip->valid = 0;
    80003dbc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003dc0:	854a                	mv	a0,s2
    80003dc2:	00001097          	auipc	ra,0x1
    80003dc6:	ad8080e7          	jalr	-1320(ra) # 8000489a <releasesleep>
    acquire(&itable.lock);
    80003dca:	0001c517          	auipc	a0,0x1c
    80003dce:	53e50513          	addi	a0,a0,1342 # 80020308 <itable>
    80003dd2:	ffffd097          	auipc	ra,0xffffd
    80003dd6:	e12080e7          	jalr	-494(ra) # 80000be4 <acquire>
    80003dda:	b741                	j	80003d5a <iput+0x26>

0000000080003ddc <iunlockput>:
{
    80003ddc:	1101                	addi	sp,sp,-32
    80003dde:	ec06                	sd	ra,24(sp)
    80003de0:	e822                	sd	s0,16(sp)
    80003de2:	e426                	sd	s1,8(sp)
    80003de4:	1000                	addi	s0,sp,32
    80003de6:	84aa                	mv	s1,a0
  iunlock(ip);
    80003de8:	00000097          	auipc	ra,0x0
    80003dec:	e54080e7          	jalr	-428(ra) # 80003c3c <iunlock>
  iput(ip);
    80003df0:	8526                	mv	a0,s1
    80003df2:	00000097          	auipc	ra,0x0
    80003df6:	f42080e7          	jalr	-190(ra) # 80003d34 <iput>
}
    80003dfa:	60e2                	ld	ra,24(sp)
    80003dfc:	6442                	ld	s0,16(sp)
    80003dfe:	64a2                	ld	s1,8(sp)
    80003e00:	6105                	addi	sp,sp,32
    80003e02:	8082                	ret

0000000080003e04 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e04:	1141                	addi	sp,sp,-16
    80003e06:	e422                	sd	s0,8(sp)
    80003e08:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e0a:	411c                	lw	a5,0(a0)
    80003e0c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e0e:	415c                	lw	a5,4(a0)
    80003e10:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e12:	04451783          	lh	a5,68(a0)
    80003e16:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e1a:	04a51783          	lh	a5,74(a0)
    80003e1e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e22:	04c56783          	lwu	a5,76(a0)
    80003e26:	e99c                	sd	a5,16(a1)
}
    80003e28:	6422                	ld	s0,8(sp)
    80003e2a:	0141                	addi	sp,sp,16
    80003e2c:	8082                	ret

0000000080003e2e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e2e:	457c                	lw	a5,76(a0)
    80003e30:	0ed7e963          	bltu	a5,a3,80003f22 <readi+0xf4>
{
    80003e34:	7159                	addi	sp,sp,-112
    80003e36:	f486                	sd	ra,104(sp)
    80003e38:	f0a2                	sd	s0,96(sp)
    80003e3a:	eca6                	sd	s1,88(sp)
    80003e3c:	e8ca                	sd	s2,80(sp)
    80003e3e:	e4ce                	sd	s3,72(sp)
    80003e40:	e0d2                	sd	s4,64(sp)
    80003e42:	fc56                	sd	s5,56(sp)
    80003e44:	f85a                	sd	s6,48(sp)
    80003e46:	f45e                	sd	s7,40(sp)
    80003e48:	f062                	sd	s8,32(sp)
    80003e4a:	ec66                	sd	s9,24(sp)
    80003e4c:	e86a                	sd	s10,16(sp)
    80003e4e:	e46e                	sd	s11,8(sp)
    80003e50:	1880                	addi	s0,sp,112
    80003e52:	8baa                	mv	s7,a0
    80003e54:	8c2e                	mv	s8,a1
    80003e56:	8ab2                	mv	s5,a2
    80003e58:	84b6                	mv	s1,a3
    80003e5a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e5c:	9f35                	addw	a4,a4,a3
    return 0;
    80003e5e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e60:	0ad76063          	bltu	a4,a3,80003f00 <readi+0xd2>
  if(off + n > ip->size)
    80003e64:	00e7f463          	bgeu	a5,a4,80003e6c <readi+0x3e>
    n = ip->size - off;
    80003e68:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e6c:	0a0b0963          	beqz	s6,80003f1e <readi+0xf0>
    80003e70:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e72:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e76:	5cfd                	li	s9,-1
    80003e78:	a82d                	j	80003eb2 <readi+0x84>
    80003e7a:	020a1d93          	slli	s11,s4,0x20
    80003e7e:	020ddd93          	srli	s11,s11,0x20
    80003e82:	05890613          	addi	a2,s2,88
    80003e86:	86ee                	mv	a3,s11
    80003e88:	963a                	add	a2,a2,a4
    80003e8a:	85d6                	mv	a1,s5
    80003e8c:	8562                	mv	a0,s8
    80003e8e:	fffff097          	auipc	ra,0xfffff
    80003e92:	a7a080e7          	jalr	-1414(ra) # 80002908 <either_copyout>
    80003e96:	05950d63          	beq	a0,s9,80003ef0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e9a:	854a                	mv	a0,s2
    80003e9c:	fffff097          	auipc	ra,0xfffff
    80003ea0:	60c080e7          	jalr	1548(ra) # 800034a8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ea4:	013a09bb          	addw	s3,s4,s3
    80003ea8:	009a04bb          	addw	s1,s4,s1
    80003eac:	9aee                	add	s5,s5,s11
    80003eae:	0569f763          	bgeu	s3,s6,80003efc <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003eb2:	000ba903          	lw	s2,0(s7)
    80003eb6:	00a4d59b          	srliw	a1,s1,0xa
    80003eba:	855e                	mv	a0,s7
    80003ebc:	00000097          	auipc	ra,0x0
    80003ec0:	8b0080e7          	jalr	-1872(ra) # 8000376c <bmap>
    80003ec4:	0005059b          	sext.w	a1,a0
    80003ec8:	854a                	mv	a0,s2
    80003eca:	fffff097          	auipc	ra,0xfffff
    80003ece:	4ae080e7          	jalr	1198(ra) # 80003378 <bread>
    80003ed2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ed4:	3ff4f713          	andi	a4,s1,1023
    80003ed8:	40ed07bb          	subw	a5,s10,a4
    80003edc:	413b06bb          	subw	a3,s6,s3
    80003ee0:	8a3e                	mv	s4,a5
    80003ee2:	2781                	sext.w	a5,a5
    80003ee4:	0006861b          	sext.w	a2,a3
    80003ee8:	f8f679e3          	bgeu	a2,a5,80003e7a <readi+0x4c>
    80003eec:	8a36                	mv	s4,a3
    80003eee:	b771                	j	80003e7a <readi+0x4c>
      brelse(bp);
    80003ef0:	854a                	mv	a0,s2
    80003ef2:	fffff097          	auipc	ra,0xfffff
    80003ef6:	5b6080e7          	jalr	1462(ra) # 800034a8 <brelse>
      tot = -1;
    80003efa:	59fd                	li	s3,-1
  }
  return tot;
    80003efc:	0009851b          	sext.w	a0,s3
}
    80003f00:	70a6                	ld	ra,104(sp)
    80003f02:	7406                	ld	s0,96(sp)
    80003f04:	64e6                	ld	s1,88(sp)
    80003f06:	6946                	ld	s2,80(sp)
    80003f08:	69a6                	ld	s3,72(sp)
    80003f0a:	6a06                	ld	s4,64(sp)
    80003f0c:	7ae2                	ld	s5,56(sp)
    80003f0e:	7b42                	ld	s6,48(sp)
    80003f10:	7ba2                	ld	s7,40(sp)
    80003f12:	7c02                	ld	s8,32(sp)
    80003f14:	6ce2                	ld	s9,24(sp)
    80003f16:	6d42                	ld	s10,16(sp)
    80003f18:	6da2                	ld	s11,8(sp)
    80003f1a:	6165                	addi	sp,sp,112
    80003f1c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f1e:	89da                	mv	s3,s6
    80003f20:	bff1                	j	80003efc <readi+0xce>
    return 0;
    80003f22:	4501                	li	a0,0
}
    80003f24:	8082                	ret

0000000080003f26 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f26:	457c                	lw	a5,76(a0)
    80003f28:	10d7e863          	bltu	a5,a3,80004038 <writei+0x112>
{
    80003f2c:	7159                	addi	sp,sp,-112
    80003f2e:	f486                	sd	ra,104(sp)
    80003f30:	f0a2                	sd	s0,96(sp)
    80003f32:	eca6                	sd	s1,88(sp)
    80003f34:	e8ca                	sd	s2,80(sp)
    80003f36:	e4ce                	sd	s3,72(sp)
    80003f38:	e0d2                	sd	s4,64(sp)
    80003f3a:	fc56                	sd	s5,56(sp)
    80003f3c:	f85a                	sd	s6,48(sp)
    80003f3e:	f45e                	sd	s7,40(sp)
    80003f40:	f062                	sd	s8,32(sp)
    80003f42:	ec66                	sd	s9,24(sp)
    80003f44:	e86a                	sd	s10,16(sp)
    80003f46:	e46e                	sd	s11,8(sp)
    80003f48:	1880                	addi	s0,sp,112
    80003f4a:	8b2a                	mv	s6,a0
    80003f4c:	8c2e                	mv	s8,a1
    80003f4e:	8ab2                	mv	s5,a2
    80003f50:	8936                	mv	s2,a3
    80003f52:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003f54:	00e687bb          	addw	a5,a3,a4
    80003f58:	0ed7e263          	bltu	a5,a3,8000403c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f5c:	00043737          	lui	a4,0x43
    80003f60:	0ef76063          	bltu	a4,a5,80004040 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f64:	0c0b8863          	beqz	s7,80004034 <writei+0x10e>
    80003f68:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f6a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f6e:	5cfd                	li	s9,-1
    80003f70:	a091                	j	80003fb4 <writei+0x8e>
    80003f72:	02099d93          	slli	s11,s3,0x20
    80003f76:	020ddd93          	srli	s11,s11,0x20
    80003f7a:	05848513          	addi	a0,s1,88
    80003f7e:	86ee                	mv	a3,s11
    80003f80:	8656                	mv	a2,s5
    80003f82:	85e2                	mv	a1,s8
    80003f84:	953a                	add	a0,a0,a4
    80003f86:	fffff097          	auipc	ra,0xfffff
    80003f8a:	9d8080e7          	jalr	-1576(ra) # 8000295e <either_copyin>
    80003f8e:	07950263          	beq	a0,s9,80003ff2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f92:	8526                	mv	a0,s1
    80003f94:	00000097          	auipc	ra,0x0
    80003f98:	790080e7          	jalr	1936(ra) # 80004724 <log_write>
    brelse(bp);
    80003f9c:	8526                	mv	a0,s1
    80003f9e:	fffff097          	auipc	ra,0xfffff
    80003fa2:	50a080e7          	jalr	1290(ra) # 800034a8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fa6:	01498a3b          	addw	s4,s3,s4
    80003faa:	0129893b          	addw	s2,s3,s2
    80003fae:	9aee                	add	s5,s5,s11
    80003fb0:	057a7663          	bgeu	s4,s7,80003ffc <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fb4:	000b2483          	lw	s1,0(s6)
    80003fb8:	00a9559b          	srliw	a1,s2,0xa
    80003fbc:	855a                	mv	a0,s6
    80003fbe:	fffff097          	auipc	ra,0xfffff
    80003fc2:	7ae080e7          	jalr	1966(ra) # 8000376c <bmap>
    80003fc6:	0005059b          	sext.w	a1,a0
    80003fca:	8526                	mv	a0,s1
    80003fcc:	fffff097          	auipc	ra,0xfffff
    80003fd0:	3ac080e7          	jalr	940(ra) # 80003378 <bread>
    80003fd4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fd6:	3ff97713          	andi	a4,s2,1023
    80003fda:	40ed07bb          	subw	a5,s10,a4
    80003fde:	414b86bb          	subw	a3,s7,s4
    80003fe2:	89be                	mv	s3,a5
    80003fe4:	2781                	sext.w	a5,a5
    80003fe6:	0006861b          	sext.w	a2,a3
    80003fea:	f8f674e3          	bgeu	a2,a5,80003f72 <writei+0x4c>
    80003fee:	89b6                	mv	s3,a3
    80003ff0:	b749                	j	80003f72 <writei+0x4c>
      brelse(bp);
    80003ff2:	8526                	mv	a0,s1
    80003ff4:	fffff097          	auipc	ra,0xfffff
    80003ff8:	4b4080e7          	jalr	1204(ra) # 800034a8 <brelse>
  }

  if(off > ip->size)
    80003ffc:	04cb2783          	lw	a5,76(s6)
    80004000:	0127f463          	bgeu	a5,s2,80004008 <writei+0xe2>
    ip->size = off;
    80004004:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004008:	855a                	mv	a0,s6
    8000400a:	00000097          	auipc	ra,0x0
    8000400e:	aa6080e7          	jalr	-1370(ra) # 80003ab0 <iupdate>

  return tot;
    80004012:	000a051b          	sext.w	a0,s4
}
    80004016:	70a6                	ld	ra,104(sp)
    80004018:	7406                	ld	s0,96(sp)
    8000401a:	64e6                	ld	s1,88(sp)
    8000401c:	6946                	ld	s2,80(sp)
    8000401e:	69a6                	ld	s3,72(sp)
    80004020:	6a06                	ld	s4,64(sp)
    80004022:	7ae2                	ld	s5,56(sp)
    80004024:	7b42                	ld	s6,48(sp)
    80004026:	7ba2                	ld	s7,40(sp)
    80004028:	7c02                	ld	s8,32(sp)
    8000402a:	6ce2                	ld	s9,24(sp)
    8000402c:	6d42                	ld	s10,16(sp)
    8000402e:	6da2                	ld	s11,8(sp)
    80004030:	6165                	addi	sp,sp,112
    80004032:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004034:	8a5e                	mv	s4,s7
    80004036:	bfc9                	j	80004008 <writei+0xe2>
    return -1;
    80004038:	557d                	li	a0,-1
}
    8000403a:	8082                	ret
    return -1;
    8000403c:	557d                	li	a0,-1
    8000403e:	bfe1                	j	80004016 <writei+0xf0>
    return -1;
    80004040:	557d                	li	a0,-1
    80004042:	bfd1                	j	80004016 <writei+0xf0>

0000000080004044 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004044:	1141                	addi	sp,sp,-16
    80004046:	e406                	sd	ra,8(sp)
    80004048:	e022                	sd	s0,0(sp)
    8000404a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000404c:	4639                	li	a2,14
    8000404e:	ffffd097          	auipc	ra,0xffffd
    80004052:	d6a080e7          	jalr	-662(ra) # 80000db8 <strncmp>
}
    80004056:	60a2                	ld	ra,8(sp)
    80004058:	6402                	ld	s0,0(sp)
    8000405a:	0141                	addi	sp,sp,16
    8000405c:	8082                	ret

000000008000405e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000405e:	7139                	addi	sp,sp,-64
    80004060:	fc06                	sd	ra,56(sp)
    80004062:	f822                	sd	s0,48(sp)
    80004064:	f426                	sd	s1,40(sp)
    80004066:	f04a                	sd	s2,32(sp)
    80004068:	ec4e                	sd	s3,24(sp)
    8000406a:	e852                	sd	s4,16(sp)
    8000406c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000406e:	04451703          	lh	a4,68(a0)
    80004072:	4785                	li	a5,1
    80004074:	00f71a63          	bne	a4,a5,80004088 <dirlookup+0x2a>
    80004078:	892a                	mv	s2,a0
    8000407a:	89ae                	mv	s3,a1
    8000407c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000407e:	457c                	lw	a5,76(a0)
    80004080:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004082:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004084:	e79d                	bnez	a5,800040b2 <dirlookup+0x54>
    80004086:	a8a5                	j	800040fe <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004088:	00004517          	auipc	a0,0x4
    8000408c:	5e850513          	addi	a0,a0,1512 # 80008670 <syscalls+0x1a0>
    80004090:	ffffc097          	auipc	ra,0xffffc
    80004094:	4ae080e7          	jalr	1198(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004098:	00004517          	auipc	a0,0x4
    8000409c:	5f050513          	addi	a0,a0,1520 # 80008688 <syscalls+0x1b8>
    800040a0:	ffffc097          	auipc	ra,0xffffc
    800040a4:	49e080e7          	jalr	1182(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040a8:	24c1                	addiw	s1,s1,16
    800040aa:	04c92783          	lw	a5,76(s2)
    800040ae:	04f4f763          	bgeu	s1,a5,800040fc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040b2:	4741                	li	a4,16
    800040b4:	86a6                	mv	a3,s1
    800040b6:	fc040613          	addi	a2,s0,-64
    800040ba:	4581                	li	a1,0
    800040bc:	854a                	mv	a0,s2
    800040be:	00000097          	auipc	ra,0x0
    800040c2:	d70080e7          	jalr	-656(ra) # 80003e2e <readi>
    800040c6:	47c1                	li	a5,16
    800040c8:	fcf518e3          	bne	a0,a5,80004098 <dirlookup+0x3a>
    if(de.inum == 0)
    800040cc:	fc045783          	lhu	a5,-64(s0)
    800040d0:	dfe1                	beqz	a5,800040a8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040d2:	fc240593          	addi	a1,s0,-62
    800040d6:	854e                	mv	a0,s3
    800040d8:	00000097          	auipc	ra,0x0
    800040dc:	f6c080e7          	jalr	-148(ra) # 80004044 <namecmp>
    800040e0:	f561                	bnez	a0,800040a8 <dirlookup+0x4a>
      if(poff)
    800040e2:	000a0463          	beqz	s4,800040ea <dirlookup+0x8c>
        *poff = off;
    800040e6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800040ea:	fc045583          	lhu	a1,-64(s0)
    800040ee:	00092503          	lw	a0,0(s2)
    800040f2:	fffff097          	auipc	ra,0xfffff
    800040f6:	754080e7          	jalr	1876(ra) # 80003846 <iget>
    800040fa:	a011                	j	800040fe <dirlookup+0xa0>
  return 0;
    800040fc:	4501                	li	a0,0
}
    800040fe:	70e2                	ld	ra,56(sp)
    80004100:	7442                	ld	s0,48(sp)
    80004102:	74a2                	ld	s1,40(sp)
    80004104:	7902                	ld	s2,32(sp)
    80004106:	69e2                	ld	s3,24(sp)
    80004108:	6a42                	ld	s4,16(sp)
    8000410a:	6121                	addi	sp,sp,64
    8000410c:	8082                	ret

000000008000410e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000410e:	711d                	addi	sp,sp,-96
    80004110:	ec86                	sd	ra,88(sp)
    80004112:	e8a2                	sd	s0,80(sp)
    80004114:	e4a6                	sd	s1,72(sp)
    80004116:	e0ca                	sd	s2,64(sp)
    80004118:	fc4e                	sd	s3,56(sp)
    8000411a:	f852                	sd	s4,48(sp)
    8000411c:	f456                	sd	s5,40(sp)
    8000411e:	f05a                	sd	s6,32(sp)
    80004120:	ec5e                	sd	s7,24(sp)
    80004122:	e862                	sd	s8,16(sp)
    80004124:	e466                	sd	s9,8(sp)
    80004126:	1080                	addi	s0,sp,96
    80004128:	84aa                	mv	s1,a0
    8000412a:	8b2e                	mv	s6,a1
    8000412c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000412e:	00054703          	lbu	a4,0(a0)
    80004132:	02f00793          	li	a5,47
    80004136:	02f70363          	beq	a4,a5,8000415c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000413a:	ffffe097          	auipc	ra,0xffffe
    8000413e:	b94080e7          	jalr	-1132(ra) # 80001cce <myproc>
    80004142:	15053503          	ld	a0,336(a0)
    80004146:	00000097          	auipc	ra,0x0
    8000414a:	9f6080e7          	jalr	-1546(ra) # 80003b3c <idup>
    8000414e:	89aa                	mv	s3,a0
  while(*path == '/')
    80004150:	02f00913          	li	s2,47
  len = path - s;
    80004154:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004156:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004158:	4c05                	li	s8,1
    8000415a:	a865                	j	80004212 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000415c:	4585                	li	a1,1
    8000415e:	4505                	li	a0,1
    80004160:	fffff097          	auipc	ra,0xfffff
    80004164:	6e6080e7          	jalr	1766(ra) # 80003846 <iget>
    80004168:	89aa                	mv	s3,a0
    8000416a:	b7dd                	j	80004150 <namex+0x42>
      iunlockput(ip);
    8000416c:	854e                	mv	a0,s3
    8000416e:	00000097          	auipc	ra,0x0
    80004172:	c6e080e7          	jalr	-914(ra) # 80003ddc <iunlockput>
      return 0;
    80004176:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004178:	854e                	mv	a0,s3
    8000417a:	60e6                	ld	ra,88(sp)
    8000417c:	6446                	ld	s0,80(sp)
    8000417e:	64a6                	ld	s1,72(sp)
    80004180:	6906                	ld	s2,64(sp)
    80004182:	79e2                	ld	s3,56(sp)
    80004184:	7a42                	ld	s4,48(sp)
    80004186:	7aa2                	ld	s5,40(sp)
    80004188:	7b02                	ld	s6,32(sp)
    8000418a:	6be2                	ld	s7,24(sp)
    8000418c:	6c42                	ld	s8,16(sp)
    8000418e:	6ca2                	ld	s9,8(sp)
    80004190:	6125                	addi	sp,sp,96
    80004192:	8082                	ret
      iunlock(ip);
    80004194:	854e                	mv	a0,s3
    80004196:	00000097          	auipc	ra,0x0
    8000419a:	aa6080e7          	jalr	-1370(ra) # 80003c3c <iunlock>
      return ip;
    8000419e:	bfe9                	j	80004178 <namex+0x6a>
      iunlockput(ip);
    800041a0:	854e                	mv	a0,s3
    800041a2:	00000097          	auipc	ra,0x0
    800041a6:	c3a080e7          	jalr	-966(ra) # 80003ddc <iunlockput>
      return 0;
    800041aa:	89d2                	mv	s3,s4
    800041ac:	b7f1                	j	80004178 <namex+0x6a>
  len = path - s;
    800041ae:	40b48633          	sub	a2,s1,a1
    800041b2:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800041b6:	094cd463          	bge	s9,s4,8000423e <namex+0x130>
    memmove(name, s, DIRSIZ);
    800041ba:	4639                	li	a2,14
    800041bc:	8556                	mv	a0,s5
    800041be:	ffffd097          	auipc	ra,0xffffd
    800041c2:	b82080e7          	jalr	-1150(ra) # 80000d40 <memmove>
  while(*path == '/')
    800041c6:	0004c783          	lbu	a5,0(s1)
    800041ca:	01279763          	bne	a5,s2,800041d8 <namex+0xca>
    path++;
    800041ce:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041d0:	0004c783          	lbu	a5,0(s1)
    800041d4:	ff278de3          	beq	a5,s2,800041ce <namex+0xc0>
    ilock(ip);
    800041d8:	854e                	mv	a0,s3
    800041da:	00000097          	auipc	ra,0x0
    800041de:	9a0080e7          	jalr	-1632(ra) # 80003b7a <ilock>
    if(ip->type != T_DIR){
    800041e2:	04499783          	lh	a5,68(s3)
    800041e6:	f98793e3          	bne	a5,s8,8000416c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800041ea:	000b0563          	beqz	s6,800041f4 <namex+0xe6>
    800041ee:	0004c783          	lbu	a5,0(s1)
    800041f2:	d3cd                	beqz	a5,80004194 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800041f4:	865e                	mv	a2,s7
    800041f6:	85d6                	mv	a1,s5
    800041f8:	854e                	mv	a0,s3
    800041fa:	00000097          	auipc	ra,0x0
    800041fe:	e64080e7          	jalr	-412(ra) # 8000405e <dirlookup>
    80004202:	8a2a                	mv	s4,a0
    80004204:	dd51                	beqz	a0,800041a0 <namex+0x92>
    iunlockput(ip);
    80004206:	854e                	mv	a0,s3
    80004208:	00000097          	auipc	ra,0x0
    8000420c:	bd4080e7          	jalr	-1068(ra) # 80003ddc <iunlockput>
    ip = next;
    80004210:	89d2                	mv	s3,s4
  while(*path == '/')
    80004212:	0004c783          	lbu	a5,0(s1)
    80004216:	05279763          	bne	a5,s2,80004264 <namex+0x156>
    path++;
    8000421a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000421c:	0004c783          	lbu	a5,0(s1)
    80004220:	ff278de3          	beq	a5,s2,8000421a <namex+0x10c>
  if(*path == 0)
    80004224:	c79d                	beqz	a5,80004252 <namex+0x144>
    path++;
    80004226:	85a6                	mv	a1,s1
  len = path - s;
    80004228:	8a5e                	mv	s4,s7
    8000422a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000422c:	01278963          	beq	a5,s2,8000423e <namex+0x130>
    80004230:	dfbd                	beqz	a5,800041ae <namex+0xa0>
    path++;
    80004232:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004234:	0004c783          	lbu	a5,0(s1)
    80004238:	ff279ce3          	bne	a5,s2,80004230 <namex+0x122>
    8000423c:	bf8d                	j	800041ae <namex+0xa0>
    memmove(name, s, len);
    8000423e:	2601                	sext.w	a2,a2
    80004240:	8556                	mv	a0,s5
    80004242:	ffffd097          	auipc	ra,0xffffd
    80004246:	afe080e7          	jalr	-1282(ra) # 80000d40 <memmove>
    name[len] = 0;
    8000424a:	9a56                	add	s4,s4,s5
    8000424c:	000a0023          	sb	zero,0(s4)
    80004250:	bf9d                	j	800041c6 <namex+0xb8>
  if(nameiparent){
    80004252:	f20b03e3          	beqz	s6,80004178 <namex+0x6a>
    iput(ip);
    80004256:	854e                	mv	a0,s3
    80004258:	00000097          	auipc	ra,0x0
    8000425c:	adc080e7          	jalr	-1316(ra) # 80003d34 <iput>
    return 0;
    80004260:	4981                	li	s3,0
    80004262:	bf19                	j	80004178 <namex+0x6a>
  if(*path == 0)
    80004264:	d7fd                	beqz	a5,80004252 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004266:	0004c783          	lbu	a5,0(s1)
    8000426a:	85a6                	mv	a1,s1
    8000426c:	b7d1                	j	80004230 <namex+0x122>

000000008000426e <dirlink>:
{
    8000426e:	7139                	addi	sp,sp,-64
    80004270:	fc06                	sd	ra,56(sp)
    80004272:	f822                	sd	s0,48(sp)
    80004274:	f426                	sd	s1,40(sp)
    80004276:	f04a                	sd	s2,32(sp)
    80004278:	ec4e                	sd	s3,24(sp)
    8000427a:	e852                	sd	s4,16(sp)
    8000427c:	0080                	addi	s0,sp,64
    8000427e:	892a                	mv	s2,a0
    80004280:	8a2e                	mv	s4,a1
    80004282:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004284:	4601                	li	a2,0
    80004286:	00000097          	auipc	ra,0x0
    8000428a:	dd8080e7          	jalr	-552(ra) # 8000405e <dirlookup>
    8000428e:	e93d                	bnez	a0,80004304 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004290:	04c92483          	lw	s1,76(s2)
    80004294:	c49d                	beqz	s1,800042c2 <dirlink+0x54>
    80004296:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004298:	4741                	li	a4,16
    8000429a:	86a6                	mv	a3,s1
    8000429c:	fc040613          	addi	a2,s0,-64
    800042a0:	4581                	li	a1,0
    800042a2:	854a                	mv	a0,s2
    800042a4:	00000097          	auipc	ra,0x0
    800042a8:	b8a080e7          	jalr	-1142(ra) # 80003e2e <readi>
    800042ac:	47c1                	li	a5,16
    800042ae:	06f51163          	bne	a0,a5,80004310 <dirlink+0xa2>
    if(de.inum == 0)
    800042b2:	fc045783          	lhu	a5,-64(s0)
    800042b6:	c791                	beqz	a5,800042c2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042b8:	24c1                	addiw	s1,s1,16
    800042ba:	04c92783          	lw	a5,76(s2)
    800042be:	fcf4ede3          	bltu	s1,a5,80004298 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042c2:	4639                	li	a2,14
    800042c4:	85d2                	mv	a1,s4
    800042c6:	fc240513          	addi	a0,s0,-62
    800042ca:	ffffd097          	auipc	ra,0xffffd
    800042ce:	b2a080e7          	jalr	-1238(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800042d2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042d6:	4741                	li	a4,16
    800042d8:	86a6                	mv	a3,s1
    800042da:	fc040613          	addi	a2,s0,-64
    800042de:	4581                	li	a1,0
    800042e0:	854a                	mv	a0,s2
    800042e2:	00000097          	auipc	ra,0x0
    800042e6:	c44080e7          	jalr	-956(ra) # 80003f26 <writei>
    800042ea:	872a                	mv	a4,a0
    800042ec:	47c1                	li	a5,16
  return 0;
    800042ee:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042f0:	02f71863          	bne	a4,a5,80004320 <dirlink+0xb2>
}
    800042f4:	70e2                	ld	ra,56(sp)
    800042f6:	7442                	ld	s0,48(sp)
    800042f8:	74a2                	ld	s1,40(sp)
    800042fa:	7902                	ld	s2,32(sp)
    800042fc:	69e2                	ld	s3,24(sp)
    800042fe:	6a42                	ld	s4,16(sp)
    80004300:	6121                	addi	sp,sp,64
    80004302:	8082                	ret
    iput(ip);
    80004304:	00000097          	auipc	ra,0x0
    80004308:	a30080e7          	jalr	-1488(ra) # 80003d34 <iput>
    return -1;
    8000430c:	557d                	li	a0,-1
    8000430e:	b7dd                	j	800042f4 <dirlink+0x86>
      panic("dirlink read");
    80004310:	00004517          	auipc	a0,0x4
    80004314:	38850513          	addi	a0,a0,904 # 80008698 <syscalls+0x1c8>
    80004318:	ffffc097          	auipc	ra,0xffffc
    8000431c:	226080e7          	jalr	550(ra) # 8000053e <panic>
    panic("dirlink");
    80004320:	00004517          	auipc	a0,0x4
    80004324:	48850513          	addi	a0,a0,1160 # 800087a8 <syscalls+0x2d8>
    80004328:	ffffc097          	auipc	ra,0xffffc
    8000432c:	216080e7          	jalr	534(ra) # 8000053e <panic>

0000000080004330 <namei>:

struct inode*
namei(char *path)
{
    80004330:	1101                	addi	sp,sp,-32
    80004332:	ec06                	sd	ra,24(sp)
    80004334:	e822                	sd	s0,16(sp)
    80004336:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004338:	fe040613          	addi	a2,s0,-32
    8000433c:	4581                	li	a1,0
    8000433e:	00000097          	auipc	ra,0x0
    80004342:	dd0080e7          	jalr	-560(ra) # 8000410e <namex>
}
    80004346:	60e2                	ld	ra,24(sp)
    80004348:	6442                	ld	s0,16(sp)
    8000434a:	6105                	addi	sp,sp,32
    8000434c:	8082                	ret

000000008000434e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000434e:	1141                	addi	sp,sp,-16
    80004350:	e406                	sd	ra,8(sp)
    80004352:	e022                	sd	s0,0(sp)
    80004354:	0800                	addi	s0,sp,16
    80004356:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004358:	4585                	li	a1,1
    8000435a:	00000097          	auipc	ra,0x0
    8000435e:	db4080e7          	jalr	-588(ra) # 8000410e <namex>
}
    80004362:	60a2                	ld	ra,8(sp)
    80004364:	6402                	ld	s0,0(sp)
    80004366:	0141                	addi	sp,sp,16
    80004368:	8082                	ret

000000008000436a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000436a:	1101                	addi	sp,sp,-32
    8000436c:	ec06                	sd	ra,24(sp)
    8000436e:	e822                	sd	s0,16(sp)
    80004370:	e426                	sd	s1,8(sp)
    80004372:	e04a                	sd	s2,0(sp)
    80004374:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004376:	0001e917          	auipc	s2,0x1e
    8000437a:	a3a90913          	addi	s2,s2,-1478 # 80021db0 <log>
    8000437e:	01892583          	lw	a1,24(s2)
    80004382:	02892503          	lw	a0,40(s2)
    80004386:	fffff097          	auipc	ra,0xfffff
    8000438a:	ff2080e7          	jalr	-14(ra) # 80003378 <bread>
    8000438e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004390:	02c92683          	lw	a3,44(s2)
    80004394:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004396:	02d05763          	blez	a3,800043c4 <write_head+0x5a>
    8000439a:	0001e797          	auipc	a5,0x1e
    8000439e:	a4678793          	addi	a5,a5,-1466 # 80021de0 <log+0x30>
    800043a2:	05c50713          	addi	a4,a0,92
    800043a6:	36fd                	addiw	a3,a3,-1
    800043a8:	1682                	slli	a3,a3,0x20
    800043aa:	9281                	srli	a3,a3,0x20
    800043ac:	068a                	slli	a3,a3,0x2
    800043ae:	0001e617          	auipc	a2,0x1e
    800043b2:	a3660613          	addi	a2,a2,-1482 # 80021de4 <log+0x34>
    800043b6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800043b8:	4390                	lw	a2,0(a5)
    800043ba:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043bc:	0791                	addi	a5,a5,4
    800043be:	0711                	addi	a4,a4,4
    800043c0:	fed79ce3          	bne	a5,a3,800043b8 <write_head+0x4e>
  }
  bwrite(buf);
    800043c4:	8526                	mv	a0,s1
    800043c6:	fffff097          	auipc	ra,0xfffff
    800043ca:	0a4080e7          	jalr	164(ra) # 8000346a <bwrite>
  brelse(buf);
    800043ce:	8526                	mv	a0,s1
    800043d0:	fffff097          	auipc	ra,0xfffff
    800043d4:	0d8080e7          	jalr	216(ra) # 800034a8 <brelse>
}
    800043d8:	60e2                	ld	ra,24(sp)
    800043da:	6442                	ld	s0,16(sp)
    800043dc:	64a2                	ld	s1,8(sp)
    800043de:	6902                	ld	s2,0(sp)
    800043e0:	6105                	addi	sp,sp,32
    800043e2:	8082                	ret

00000000800043e4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043e4:	0001e797          	auipc	a5,0x1e
    800043e8:	9f87a783          	lw	a5,-1544(a5) # 80021ddc <log+0x2c>
    800043ec:	0af05d63          	blez	a5,800044a6 <install_trans+0xc2>
{
    800043f0:	7139                	addi	sp,sp,-64
    800043f2:	fc06                	sd	ra,56(sp)
    800043f4:	f822                	sd	s0,48(sp)
    800043f6:	f426                	sd	s1,40(sp)
    800043f8:	f04a                	sd	s2,32(sp)
    800043fa:	ec4e                	sd	s3,24(sp)
    800043fc:	e852                	sd	s4,16(sp)
    800043fe:	e456                	sd	s5,8(sp)
    80004400:	e05a                	sd	s6,0(sp)
    80004402:	0080                	addi	s0,sp,64
    80004404:	8b2a                	mv	s6,a0
    80004406:	0001ea97          	auipc	s5,0x1e
    8000440a:	9daa8a93          	addi	s5,s5,-1574 # 80021de0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000440e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004410:	0001e997          	auipc	s3,0x1e
    80004414:	9a098993          	addi	s3,s3,-1632 # 80021db0 <log>
    80004418:	a035                	j	80004444 <install_trans+0x60>
      bunpin(dbuf);
    8000441a:	8526                	mv	a0,s1
    8000441c:	fffff097          	auipc	ra,0xfffff
    80004420:	166080e7          	jalr	358(ra) # 80003582 <bunpin>
    brelse(lbuf);
    80004424:	854a                	mv	a0,s2
    80004426:	fffff097          	auipc	ra,0xfffff
    8000442a:	082080e7          	jalr	130(ra) # 800034a8 <brelse>
    brelse(dbuf);
    8000442e:	8526                	mv	a0,s1
    80004430:	fffff097          	auipc	ra,0xfffff
    80004434:	078080e7          	jalr	120(ra) # 800034a8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004438:	2a05                	addiw	s4,s4,1
    8000443a:	0a91                	addi	s5,s5,4
    8000443c:	02c9a783          	lw	a5,44(s3)
    80004440:	04fa5963          	bge	s4,a5,80004492 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004444:	0189a583          	lw	a1,24(s3)
    80004448:	014585bb          	addw	a1,a1,s4
    8000444c:	2585                	addiw	a1,a1,1
    8000444e:	0289a503          	lw	a0,40(s3)
    80004452:	fffff097          	auipc	ra,0xfffff
    80004456:	f26080e7          	jalr	-218(ra) # 80003378 <bread>
    8000445a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000445c:	000aa583          	lw	a1,0(s5)
    80004460:	0289a503          	lw	a0,40(s3)
    80004464:	fffff097          	auipc	ra,0xfffff
    80004468:	f14080e7          	jalr	-236(ra) # 80003378 <bread>
    8000446c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000446e:	40000613          	li	a2,1024
    80004472:	05890593          	addi	a1,s2,88
    80004476:	05850513          	addi	a0,a0,88
    8000447a:	ffffd097          	auipc	ra,0xffffd
    8000447e:	8c6080e7          	jalr	-1850(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004482:	8526                	mv	a0,s1
    80004484:	fffff097          	auipc	ra,0xfffff
    80004488:	fe6080e7          	jalr	-26(ra) # 8000346a <bwrite>
    if(recovering == 0)
    8000448c:	f80b1ce3          	bnez	s6,80004424 <install_trans+0x40>
    80004490:	b769                	j	8000441a <install_trans+0x36>
}
    80004492:	70e2                	ld	ra,56(sp)
    80004494:	7442                	ld	s0,48(sp)
    80004496:	74a2                	ld	s1,40(sp)
    80004498:	7902                	ld	s2,32(sp)
    8000449a:	69e2                	ld	s3,24(sp)
    8000449c:	6a42                	ld	s4,16(sp)
    8000449e:	6aa2                	ld	s5,8(sp)
    800044a0:	6b02                	ld	s6,0(sp)
    800044a2:	6121                	addi	sp,sp,64
    800044a4:	8082                	ret
    800044a6:	8082                	ret

00000000800044a8 <initlog>:
{
    800044a8:	7179                	addi	sp,sp,-48
    800044aa:	f406                	sd	ra,40(sp)
    800044ac:	f022                	sd	s0,32(sp)
    800044ae:	ec26                	sd	s1,24(sp)
    800044b0:	e84a                	sd	s2,16(sp)
    800044b2:	e44e                	sd	s3,8(sp)
    800044b4:	1800                	addi	s0,sp,48
    800044b6:	892a                	mv	s2,a0
    800044b8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044ba:	0001e497          	auipc	s1,0x1e
    800044be:	8f648493          	addi	s1,s1,-1802 # 80021db0 <log>
    800044c2:	00004597          	auipc	a1,0x4
    800044c6:	1e658593          	addi	a1,a1,486 # 800086a8 <syscalls+0x1d8>
    800044ca:	8526                	mv	a0,s1
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	688080e7          	jalr	1672(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800044d4:	0149a583          	lw	a1,20(s3)
    800044d8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800044da:	0109a783          	lw	a5,16(s3)
    800044de:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044e0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044e4:	854a                	mv	a0,s2
    800044e6:	fffff097          	auipc	ra,0xfffff
    800044ea:	e92080e7          	jalr	-366(ra) # 80003378 <bread>
  log.lh.n = lh->n;
    800044ee:	4d3c                	lw	a5,88(a0)
    800044f0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800044f2:	02f05563          	blez	a5,8000451c <initlog+0x74>
    800044f6:	05c50713          	addi	a4,a0,92
    800044fa:	0001e697          	auipc	a3,0x1e
    800044fe:	8e668693          	addi	a3,a3,-1818 # 80021de0 <log+0x30>
    80004502:	37fd                	addiw	a5,a5,-1
    80004504:	1782                	slli	a5,a5,0x20
    80004506:	9381                	srli	a5,a5,0x20
    80004508:	078a                	slli	a5,a5,0x2
    8000450a:	06050613          	addi	a2,a0,96
    8000450e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004510:	4310                	lw	a2,0(a4)
    80004512:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004514:	0711                	addi	a4,a4,4
    80004516:	0691                	addi	a3,a3,4
    80004518:	fef71ce3          	bne	a4,a5,80004510 <initlog+0x68>
  brelse(buf);
    8000451c:	fffff097          	auipc	ra,0xfffff
    80004520:	f8c080e7          	jalr	-116(ra) # 800034a8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004524:	4505                	li	a0,1
    80004526:	00000097          	auipc	ra,0x0
    8000452a:	ebe080e7          	jalr	-322(ra) # 800043e4 <install_trans>
  log.lh.n = 0;
    8000452e:	0001e797          	auipc	a5,0x1e
    80004532:	8a07a723          	sw	zero,-1874(a5) # 80021ddc <log+0x2c>
  write_head(); // clear the log
    80004536:	00000097          	auipc	ra,0x0
    8000453a:	e34080e7          	jalr	-460(ra) # 8000436a <write_head>
}
    8000453e:	70a2                	ld	ra,40(sp)
    80004540:	7402                	ld	s0,32(sp)
    80004542:	64e2                	ld	s1,24(sp)
    80004544:	6942                	ld	s2,16(sp)
    80004546:	69a2                	ld	s3,8(sp)
    80004548:	6145                	addi	sp,sp,48
    8000454a:	8082                	ret

000000008000454c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000454c:	1101                	addi	sp,sp,-32
    8000454e:	ec06                	sd	ra,24(sp)
    80004550:	e822                	sd	s0,16(sp)
    80004552:	e426                	sd	s1,8(sp)
    80004554:	e04a                	sd	s2,0(sp)
    80004556:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004558:	0001e517          	auipc	a0,0x1e
    8000455c:	85850513          	addi	a0,a0,-1960 # 80021db0 <log>
    80004560:	ffffc097          	auipc	ra,0xffffc
    80004564:	684080e7          	jalr	1668(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004568:	0001e497          	auipc	s1,0x1e
    8000456c:	84848493          	addi	s1,s1,-1976 # 80021db0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004570:	4979                	li	s2,30
    80004572:	a039                	j	80004580 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004574:	85a6                	mv	a1,s1
    80004576:	8526                	mv	a0,s1
    80004578:	ffffe097          	auipc	ra,0xffffe
    8000457c:	f56080e7          	jalr	-170(ra) # 800024ce <sleep>
    if(log.committing){
    80004580:	50dc                	lw	a5,36(s1)
    80004582:	fbed                	bnez	a5,80004574 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004584:	509c                	lw	a5,32(s1)
    80004586:	0017871b          	addiw	a4,a5,1
    8000458a:	0007069b          	sext.w	a3,a4
    8000458e:	0027179b          	slliw	a5,a4,0x2
    80004592:	9fb9                	addw	a5,a5,a4
    80004594:	0017979b          	slliw	a5,a5,0x1
    80004598:	54d8                	lw	a4,44(s1)
    8000459a:	9fb9                	addw	a5,a5,a4
    8000459c:	00f95963          	bge	s2,a5,800045ae <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045a0:	85a6                	mv	a1,s1
    800045a2:	8526                	mv	a0,s1
    800045a4:	ffffe097          	auipc	ra,0xffffe
    800045a8:	f2a080e7          	jalr	-214(ra) # 800024ce <sleep>
    800045ac:	bfd1                	j	80004580 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045ae:	0001e517          	auipc	a0,0x1e
    800045b2:	80250513          	addi	a0,a0,-2046 # 80021db0 <log>
    800045b6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800045b8:	ffffc097          	auipc	ra,0xffffc
    800045bc:	6e0080e7          	jalr	1760(ra) # 80000c98 <release>
      break;
    }
  }
}
    800045c0:	60e2                	ld	ra,24(sp)
    800045c2:	6442                	ld	s0,16(sp)
    800045c4:	64a2                	ld	s1,8(sp)
    800045c6:	6902                	ld	s2,0(sp)
    800045c8:	6105                	addi	sp,sp,32
    800045ca:	8082                	ret

00000000800045cc <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045cc:	7139                	addi	sp,sp,-64
    800045ce:	fc06                	sd	ra,56(sp)
    800045d0:	f822                	sd	s0,48(sp)
    800045d2:	f426                	sd	s1,40(sp)
    800045d4:	f04a                	sd	s2,32(sp)
    800045d6:	ec4e                	sd	s3,24(sp)
    800045d8:	e852                	sd	s4,16(sp)
    800045da:	e456                	sd	s5,8(sp)
    800045dc:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045de:	0001d497          	auipc	s1,0x1d
    800045e2:	7d248493          	addi	s1,s1,2002 # 80021db0 <log>
    800045e6:	8526                	mv	a0,s1
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	5fc080e7          	jalr	1532(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800045f0:	509c                	lw	a5,32(s1)
    800045f2:	37fd                	addiw	a5,a5,-1
    800045f4:	0007891b          	sext.w	s2,a5
    800045f8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800045fa:	50dc                	lw	a5,36(s1)
    800045fc:	efb9                	bnez	a5,8000465a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800045fe:	06091663          	bnez	s2,8000466a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004602:	0001d497          	auipc	s1,0x1d
    80004606:	7ae48493          	addi	s1,s1,1966 # 80021db0 <log>
    8000460a:	4785                	li	a5,1
    8000460c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000460e:	8526                	mv	a0,s1
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	688080e7          	jalr	1672(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004618:	54dc                	lw	a5,44(s1)
    8000461a:	06f04763          	bgtz	a5,80004688 <end_op+0xbc>
    acquire(&log.lock);
    8000461e:	0001d497          	auipc	s1,0x1d
    80004622:	79248493          	addi	s1,s1,1938 # 80021db0 <log>
    80004626:	8526                	mv	a0,s1
    80004628:	ffffc097          	auipc	ra,0xffffc
    8000462c:	5bc080e7          	jalr	1468(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004630:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004634:	8526                	mv	a0,s1
    80004636:	ffffe097          	auipc	ra,0xffffe
    8000463a:	036080e7          	jalr	54(ra) # 8000266c <wakeup>
    release(&log.lock);
    8000463e:	8526                	mv	a0,s1
    80004640:	ffffc097          	auipc	ra,0xffffc
    80004644:	658080e7          	jalr	1624(ra) # 80000c98 <release>
}
    80004648:	70e2                	ld	ra,56(sp)
    8000464a:	7442                	ld	s0,48(sp)
    8000464c:	74a2                	ld	s1,40(sp)
    8000464e:	7902                	ld	s2,32(sp)
    80004650:	69e2                	ld	s3,24(sp)
    80004652:	6a42                	ld	s4,16(sp)
    80004654:	6aa2                	ld	s5,8(sp)
    80004656:	6121                	addi	sp,sp,64
    80004658:	8082                	ret
    panic("log.committing");
    8000465a:	00004517          	auipc	a0,0x4
    8000465e:	05650513          	addi	a0,a0,86 # 800086b0 <syscalls+0x1e0>
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	edc080e7          	jalr	-292(ra) # 8000053e <panic>
    wakeup(&log);
    8000466a:	0001d497          	auipc	s1,0x1d
    8000466e:	74648493          	addi	s1,s1,1862 # 80021db0 <log>
    80004672:	8526                	mv	a0,s1
    80004674:	ffffe097          	auipc	ra,0xffffe
    80004678:	ff8080e7          	jalr	-8(ra) # 8000266c <wakeup>
  release(&log.lock);
    8000467c:	8526                	mv	a0,s1
    8000467e:	ffffc097          	auipc	ra,0xffffc
    80004682:	61a080e7          	jalr	1562(ra) # 80000c98 <release>
  if(do_commit){
    80004686:	b7c9                	j	80004648 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004688:	0001da97          	auipc	s5,0x1d
    8000468c:	758a8a93          	addi	s5,s5,1880 # 80021de0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004690:	0001da17          	auipc	s4,0x1d
    80004694:	720a0a13          	addi	s4,s4,1824 # 80021db0 <log>
    80004698:	018a2583          	lw	a1,24(s4)
    8000469c:	012585bb          	addw	a1,a1,s2
    800046a0:	2585                	addiw	a1,a1,1
    800046a2:	028a2503          	lw	a0,40(s4)
    800046a6:	fffff097          	auipc	ra,0xfffff
    800046aa:	cd2080e7          	jalr	-814(ra) # 80003378 <bread>
    800046ae:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046b0:	000aa583          	lw	a1,0(s5)
    800046b4:	028a2503          	lw	a0,40(s4)
    800046b8:	fffff097          	auipc	ra,0xfffff
    800046bc:	cc0080e7          	jalr	-832(ra) # 80003378 <bread>
    800046c0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046c2:	40000613          	li	a2,1024
    800046c6:	05850593          	addi	a1,a0,88
    800046ca:	05848513          	addi	a0,s1,88
    800046ce:	ffffc097          	auipc	ra,0xffffc
    800046d2:	672080e7          	jalr	1650(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800046d6:	8526                	mv	a0,s1
    800046d8:	fffff097          	auipc	ra,0xfffff
    800046dc:	d92080e7          	jalr	-622(ra) # 8000346a <bwrite>
    brelse(from);
    800046e0:	854e                	mv	a0,s3
    800046e2:	fffff097          	auipc	ra,0xfffff
    800046e6:	dc6080e7          	jalr	-570(ra) # 800034a8 <brelse>
    brelse(to);
    800046ea:	8526                	mv	a0,s1
    800046ec:	fffff097          	auipc	ra,0xfffff
    800046f0:	dbc080e7          	jalr	-580(ra) # 800034a8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046f4:	2905                	addiw	s2,s2,1
    800046f6:	0a91                	addi	s5,s5,4
    800046f8:	02ca2783          	lw	a5,44(s4)
    800046fc:	f8f94ee3          	blt	s2,a5,80004698 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004700:	00000097          	auipc	ra,0x0
    80004704:	c6a080e7          	jalr	-918(ra) # 8000436a <write_head>
    install_trans(0); // Now install writes to home locations
    80004708:	4501                	li	a0,0
    8000470a:	00000097          	auipc	ra,0x0
    8000470e:	cda080e7          	jalr	-806(ra) # 800043e4 <install_trans>
    log.lh.n = 0;
    80004712:	0001d797          	auipc	a5,0x1d
    80004716:	6c07a523          	sw	zero,1738(a5) # 80021ddc <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000471a:	00000097          	auipc	ra,0x0
    8000471e:	c50080e7          	jalr	-944(ra) # 8000436a <write_head>
    80004722:	bdf5                	j	8000461e <end_op+0x52>

0000000080004724 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004724:	1101                	addi	sp,sp,-32
    80004726:	ec06                	sd	ra,24(sp)
    80004728:	e822                	sd	s0,16(sp)
    8000472a:	e426                	sd	s1,8(sp)
    8000472c:	e04a                	sd	s2,0(sp)
    8000472e:	1000                	addi	s0,sp,32
    80004730:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004732:	0001d917          	auipc	s2,0x1d
    80004736:	67e90913          	addi	s2,s2,1662 # 80021db0 <log>
    8000473a:	854a                	mv	a0,s2
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	4a8080e7          	jalr	1192(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004744:	02c92603          	lw	a2,44(s2)
    80004748:	47f5                	li	a5,29
    8000474a:	06c7c563          	blt	a5,a2,800047b4 <log_write+0x90>
    8000474e:	0001d797          	auipc	a5,0x1d
    80004752:	67e7a783          	lw	a5,1662(a5) # 80021dcc <log+0x1c>
    80004756:	37fd                	addiw	a5,a5,-1
    80004758:	04f65e63          	bge	a2,a5,800047b4 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000475c:	0001d797          	auipc	a5,0x1d
    80004760:	6747a783          	lw	a5,1652(a5) # 80021dd0 <log+0x20>
    80004764:	06f05063          	blez	a5,800047c4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004768:	4781                	li	a5,0
    8000476a:	06c05563          	blez	a2,800047d4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000476e:	44cc                	lw	a1,12(s1)
    80004770:	0001d717          	auipc	a4,0x1d
    80004774:	67070713          	addi	a4,a4,1648 # 80021de0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004778:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000477a:	4314                	lw	a3,0(a4)
    8000477c:	04b68c63          	beq	a3,a1,800047d4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004780:	2785                	addiw	a5,a5,1
    80004782:	0711                	addi	a4,a4,4
    80004784:	fef61be3          	bne	a2,a5,8000477a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004788:	0621                	addi	a2,a2,8
    8000478a:	060a                	slli	a2,a2,0x2
    8000478c:	0001d797          	auipc	a5,0x1d
    80004790:	62478793          	addi	a5,a5,1572 # 80021db0 <log>
    80004794:	963e                	add	a2,a2,a5
    80004796:	44dc                	lw	a5,12(s1)
    80004798:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000479a:	8526                	mv	a0,s1
    8000479c:	fffff097          	auipc	ra,0xfffff
    800047a0:	daa080e7          	jalr	-598(ra) # 80003546 <bpin>
    log.lh.n++;
    800047a4:	0001d717          	auipc	a4,0x1d
    800047a8:	60c70713          	addi	a4,a4,1548 # 80021db0 <log>
    800047ac:	575c                	lw	a5,44(a4)
    800047ae:	2785                	addiw	a5,a5,1
    800047b0:	d75c                	sw	a5,44(a4)
    800047b2:	a835                	j	800047ee <log_write+0xca>
    panic("too big a transaction");
    800047b4:	00004517          	auipc	a0,0x4
    800047b8:	f0c50513          	addi	a0,a0,-244 # 800086c0 <syscalls+0x1f0>
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	d82080e7          	jalr	-638(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800047c4:	00004517          	auipc	a0,0x4
    800047c8:	f1450513          	addi	a0,a0,-236 # 800086d8 <syscalls+0x208>
    800047cc:	ffffc097          	auipc	ra,0xffffc
    800047d0:	d72080e7          	jalr	-654(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800047d4:	00878713          	addi	a4,a5,8
    800047d8:	00271693          	slli	a3,a4,0x2
    800047dc:	0001d717          	auipc	a4,0x1d
    800047e0:	5d470713          	addi	a4,a4,1492 # 80021db0 <log>
    800047e4:	9736                	add	a4,a4,a3
    800047e6:	44d4                	lw	a3,12(s1)
    800047e8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800047ea:	faf608e3          	beq	a2,a5,8000479a <log_write+0x76>
  }
  release(&log.lock);
    800047ee:	0001d517          	auipc	a0,0x1d
    800047f2:	5c250513          	addi	a0,a0,1474 # 80021db0 <log>
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	4a2080e7          	jalr	1186(ra) # 80000c98 <release>
}
    800047fe:	60e2                	ld	ra,24(sp)
    80004800:	6442                	ld	s0,16(sp)
    80004802:	64a2                	ld	s1,8(sp)
    80004804:	6902                	ld	s2,0(sp)
    80004806:	6105                	addi	sp,sp,32
    80004808:	8082                	ret

000000008000480a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000480a:	1101                	addi	sp,sp,-32
    8000480c:	ec06                	sd	ra,24(sp)
    8000480e:	e822                	sd	s0,16(sp)
    80004810:	e426                	sd	s1,8(sp)
    80004812:	e04a                	sd	s2,0(sp)
    80004814:	1000                	addi	s0,sp,32
    80004816:	84aa                	mv	s1,a0
    80004818:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000481a:	00004597          	auipc	a1,0x4
    8000481e:	ede58593          	addi	a1,a1,-290 # 800086f8 <syscalls+0x228>
    80004822:	0521                	addi	a0,a0,8
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	330080e7          	jalr	816(ra) # 80000b54 <initlock>
  lk->name = name;
    8000482c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004830:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004834:	0204a423          	sw	zero,40(s1)
}
    80004838:	60e2                	ld	ra,24(sp)
    8000483a:	6442                	ld	s0,16(sp)
    8000483c:	64a2                	ld	s1,8(sp)
    8000483e:	6902                	ld	s2,0(sp)
    80004840:	6105                	addi	sp,sp,32
    80004842:	8082                	ret

0000000080004844 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004844:	1101                	addi	sp,sp,-32
    80004846:	ec06                	sd	ra,24(sp)
    80004848:	e822                	sd	s0,16(sp)
    8000484a:	e426                	sd	s1,8(sp)
    8000484c:	e04a                	sd	s2,0(sp)
    8000484e:	1000                	addi	s0,sp,32
    80004850:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004852:	00850913          	addi	s2,a0,8
    80004856:	854a                	mv	a0,s2
    80004858:	ffffc097          	auipc	ra,0xffffc
    8000485c:	38c080e7          	jalr	908(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004860:	409c                	lw	a5,0(s1)
    80004862:	cb89                	beqz	a5,80004874 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004864:	85ca                	mv	a1,s2
    80004866:	8526                	mv	a0,s1
    80004868:	ffffe097          	auipc	ra,0xffffe
    8000486c:	c66080e7          	jalr	-922(ra) # 800024ce <sleep>
  while (lk->locked) {
    80004870:	409c                	lw	a5,0(s1)
    80004872:	fbed                	bnez	a5,80004864 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004874:	4785                	li	a5,1
    80004876:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004878:	ffffd097          	auipc	ra,0xffffd
    8000487c:	456080e7          	jalr	1110(ra) # 80001cce <myproc>
    80004880:	591c                	lw	a5,48(a0)
    80004882:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004884:	854a                	mv	a0,s2
    80004886:	ffffc097          	auipc	ra,0xffffc
    8000488a:	412080e7          	jalr	1042(ra) # 80000c98 <release>
}
    8000488e:	60e2                	ld	ra,24(sp)
    80004890:	6442                	ld	s0,16(sp)
    80004892:	64a2                	ld	s1,8(sp)
    80004894:	6902                	ld	s2,0(sp)
    80004896:	6105                	addi	sp,sp,32
    80004898:	8082                	ret

000000008000489a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000489a:	1101                	addi	sp,sp,-32
    8000489c:	ec06                	sd	ra,24(sp)
    8000489e:	e822                	sd	s0,16(sp)
    800048a0:	e426                	sd	s1,8(sp)
    800048a2:	e04a                	sd	s2,0(sp)
    800048a4:	1000                	addi	s0,sp,32
    800048a6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048a8:	00850913          	addi	s2,a0,8
    800048ac:	854a                	mv	a0,s2
    800048ae:	ffffc097          	auipc	ra,0xffffc
    800048b2:	336080e7          	jalr	822(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800048b6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048ba:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800048be:	8526                	mv	a0,s1
    800048c0:	ffffe097          	auipc	ra,0xffffe
    800048c4:	dac080e7          	jalr	-596(ra) # 8000266c <wakeup>
  release(&lk->lk);
    800048c8:	854a                	mv	a0,s2
    800048ca:	ffffc097          	auipc	ra,0xffffc
    800048ce:	3ce080e7          	jalr	974(ra) # 80000c98 <release>
}
    800048d2:	60e2                	ld	ra,24(sp)
    800048d4:	6442                	ld	s0,16(sp)
    800048d6:	64a2                	ld	s1,8(sp)
    800048d8:	6902                	ld	s2,0(sp)
    800048da:	6105                	addi	sp,sp,32
    800048dc:	8082                	ret

00000000800048de <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048de:	7179                	addi	sp,sp,-48
    800048e0:	f406                	sd	ra,40(sp)
    800048e2:	f022                	sd	s0,32(sp)
    800048e4:	ec26                	sd	s1,24(sp)
    800048e6:	e84a                	sd	s2,16(sp)
    800048e8:	e44e                	sd	s3,8(sp)
    800048ea:	1800                	addi	s0,sp,48
    800048ec:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800048ee:	00850913          	addi	s2,a0,8
    800048f2:	854a                	mv	a0,s2
    800048f4:	ffffc097          	auipc	ra,0xffffc
    800048f8:	2f0080e7          	jalr	752(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800048fc:	409c                	lw	a5,0(s1)
    800048fe:	ef99                	bnez	a5,8000491c <holdingsleep+0x3e>
    80004900:	4481                	li	s1,0
  release(&lk->lk);
    80004902:	854a                	mv	a0,s2
    80004904:	ffffc097          	auipc	ra,0xffffc
    80004908:	394080e7          	jalr	916(ra) # 80000c98 <release>
  return r;
}
    8000490c:	8526                	mv	a0,s1
    8000490e:	70a2                	ld	ra,40(sp)
    80004910:	7402                	ld	s0,32(sp)
    80004912:	64e2                	ld	s1,24(sp)
    80004914:	6942                	ld	s2,16(sp)
    80004916:	69a2                	ld	s3,8(sp)
    80004918:	6145                	addi	sp,sp,48
    8000491a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000491c:	0284a983          	lw	s3,40(s1)
    80004920:	ffffd097          	auipc	ra,0xffffd
    80004924:	3ae080e7          	jalr	942(ra) # 80001cce <myproc>
    80004928:	5904                	lw	s1,48(a0)
    8000492a:	413484b3          	sub	s1,s1,s3
    8000492e:	0014b493          	seqz	s1,s1
    80004932:	bfc1                	j	80004902 <holdingsleep+0x24>

0000000080004934 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004934:	1141                	addi	sp,sp,-16
    80004936:	e406                	sd	ra,8(sp)
    80004938:	e022                	sd	s0,0(sp)
    8000493a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000493c:	00004597          	auipc	a1,0x4
    80004940:	dcc58593          	addi	a1,a1,-564 # 80008708 <syscalls+0x238>
    80004944:	0001d517          	auipc	a0,0x1d
    80004948:	5b450513          	addi	a0,a0,1460 # 80021ef8 <ftable>
    8000494c:	ffffc097          	auipc	ra,0xffffc
    80004950:	208080e7          	jalr	520(ra) # 80000b54 <initlock>
}
    80004954:	60a2                	ld	ra,8(sp)
    80004956:	6402                	ld	s0,0(sp)
    80004958:	0141                	addi	sp,sp,16
    8000495a:	8082                	ret

000000008000495c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000495c:	1101                	addi	sp,sp,-32
    8000495e:	ec06                	sd	ra,24(sp)
    80004960:	e822                	sd	s0,16(sp)
    80004962:	e426                	sd	s1,8(sp)
    80004964:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004966:	0001d517          	auipc	a0,0x1d
    8000496a:	59250513          	addi	a0,a0,1426 # 80021ef8 <ftable>
    8000496e:	ffffc097          	auipc	ra,0xffffc
    80004972:	276080e7          	jalr	630(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004976:	0001d497          	auipc	s1,0x1d
    8000497a:	59a48493          	addi	s1,s1,1434 # 80021f10 <ftable+0x18>
    8000497e:	0001e717          	auipc	a4,0x1e
    80004982:	53270713          	addi	a4,a4,1330 # 80022eb0 <ftable+0xfb8>
    if(f->ref == 0){
    80004986:	40dc                	lw	a5,4(s1)
    80004988:	cf99                	beqz	a5,800049a6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000498a:	02848493          	addi	s1,s1,40
    8000498e:	fee49ce3          	bne	s1,a4,80004986 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004992:	0001d517          	auipc	a0,0x1d
    80004996:	56650513          	addi	a0,a0,1382 # 80021ef8 <ftable>
    8000499a:	ffffc097          	auipc	ra,0xffffc
    8000499e:	2fe080e7          	jalr	766(ra) # 80000c98 <release>
  return 0;
    800049a2:	4481                	li	s1,0
    800049a4:	a819                	j	800049ba <filealloc+0x5e>
      f->ref = 1;
    800049a6:	4785                	li	a5,1
    800049a8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049aa:	0001d517          	auipc	a0,0x1d
    800049ae:	54e50513          	addi	a0,a0,1358 # 80021ef8 <ftable>
    800049b2:	ffffc097          	auipc	ra,0xffffc
    800049b6:	2e6080e7          	jalr	742(ra) # 80000c98 <release>
}
    800049ba:	8526                	mv	a0,s1
    800049bc:	60e2                	ld	ra,24(sp)
    800049be:	6442                	ld	s0,16(sp)
    800049c0:	64a2                	ld	s1,8(sp)
    800049c2:	6105                	addi	sp,sp,32
    800049c4:	8082                	ret

00000000800049c6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049c6:	1101                	addi	sp,sp,-32
    800049c8:	ec06                	sd	ra,24(sp)
    800049ca:	e822                	sd	s0,16(sp)
    800049cc:	e426                	sd	s1,8(sp)
    800049ce:	1000                	addi	s0,sp,32
    800049d0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049d2:	0001d517          	auipc	a0,0x1d
    800049d6:	52650513          	addi	a0,a0,1318 # 80021ef8 <ftable>
    800049da:	ffffc097          	auipc	ra,0xffffc
    800049de:	20a080e7          	jalr	522(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800049e2:	40dc                	lw	a5,4(s1)
    800049e4:	02f05263          	blez	a5,80004a08 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049e8:	2785                	addiw	a5,a5,1
    800049ea:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800049ec:	0001d517          	auipc	a0,0x1d
    800049f0:	50c50513          	addi	a0,a0,1292 # 80021ef8 <ftable>
    800049f4:	ffffc097          	auipc	ra,0xffffc
    800049f8:	2a4080e7          	jalr	676(ra) # 80000c98 <release>
  return f;
}
    800049fc:	8526                	mv	a0,s1
    800049fe:	60e2                	ld	ra,24(sp)
    80004a00:	6442                	ld	s0,16(sp)
    80004a02:	64a2                	ld	s1,8(sp)
    80004a04:	6105                	addi	sp,sp,32
    80004a06:	8082                	ret
    panic("filedup");
    80004a08:	00004517          	auipc	a0,0x4
    80004a0c:	d0850513          	addi	a0,a0,-760 # 80008710 <syscalls+0x240>
    80004a10:	ffffc097          	auipc	ra,0xffffc
    80004a14:	b2e080e7          	jalr	-1234(ra) # 8000053e <panic>

0000000080004a18 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a18:	7139                	addi	sp,sp,-64
    80004a1a:	fc06                	sd	ra,56(sp)
    80004a1c:	f822                	sd	s0,48(sp)
    80004a1e:	f426                	sd	s1,40(sp)
    80004a20:	f04a                	sd	s2,32(sp)
    80004a22:	ec4e                	sd	s3,24(sp)
    80004a24:	e852                	sd	s4,16(sp)
    80004a26:	e456                	sd	s5,8(sp)
    80004a28:	0080                	addi	s0,sp,64
    80004a2a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a2c:	0001d517          	auipc	a0,0x1d
    80004a30:	4cc50513          	addi	a0,a0,1228 # 80021ef8 <ftable>
    80004a34:	ffffc097          	auipc	ra,0xffffc
    80004a38:	1b0080e7          	jalr	432(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a3c:	40dc                	lw	a5,4(s1)
    80004a3e:	06f05163          	blez	a5,80004aa0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a42:	37fd                	addiw	a5,a5,-1
    80004a44:	0007871b          	sext.w	a4,a5
    80004a48:	c0dc                	sw	a5,4(s1)
    80004a4a:	06e04363          	bgtz	a4,80004ab0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a4e:	0004a903          	lw	s2,0(s1)
    80004a52:	0094ca83          	lbu	s5,9(s1)
    80004a56:	0104ba03          	ld	s4,16(s1)
    80004a5a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a5e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a62:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a66:	0001d517          	auipc	a0,0x1d
    80004a6a:	49250513          	addi	a0,a0,1170 # 80021ef8 <ftable>
    80004a6e:	ffffc097          	auipc	ra,0xffffc
    80004a72:	22a080e7          	jalr	554(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004a76:	4785                	li	a5,1
    80004a78:	04f90d63          	beq	s2,a5,80004ad2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a7c:	3979                	addiw	s2,s2,-2
    80004a7e:	4785                	li	a5,1
    80004a80:	0527e063          	bltu	a5,s2,80004ac0 <fileclose+0xa8>
    begin_op();
    80004a84:	00000097          	auipc	ra,0x0
    80004a88:	ac8080e7          	jalr	-1336(ra) # 8000454c <begin_op>
    iput(ff.ip);
    80004a8c:	854e                	mv	a0,s3
    80004a8e:	fffff097          	auipc	ra,0xfffff
    80004a92:	2a6080e7          	jalr	678(ra) # 80003d34 <iput>
    end_op();
    80004a96:	00000097          	auipc	ra,0x0
    80004a9a:	b36080e7          	jalr	-1226(ra) # 800045cc <end_op>
    80004a9e:	a00d                	j	80004ac0 <fileclose+0xa8>
    panic("fileclose");
    80004aa0:	00004517          	auipc	a0,0x4
    80004aa4:	c7850513          	addi	a0,a0,-904 # 80008718 <syscalls+0x248>
    80004aa8:	ffffc097          	auipc	ra,0xffffc
    80004aac:	a96080e7          	jalr	-1386(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004ab0:	0001d517          	auipc	a0,0x1d
    80004ab4:	44850513          	addi	a0,a0,1096 # 80021ef8 <ftable>
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	1e0080e7          	jalr	480(ra) # 80000c98 <release>
  }
}
    80004ac0:	70e2                	ld	ra,56(sp)
    80004ac2:	7442                	ld	s0,48(sp)
    80004ac4:	74a2                	ld	s1,40(sp)
    80004ac6:	7902                	ld	s2,32(sp)
    80004ac8:	69e2                	ld	s3,24(sp)
    80004aca:	6a42                	ld	s4,16(sp)
    80004acc:	6aa2                	ld	s5,8(sp)
    80004ace:	6121                	addi	sp,sp,64
    80004ad0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004ad2:	85d6                	mv	a1,s5
    80004ad4:	8552                	mv	a0,s4
    80004ad6:	00000097          	auipc	ra,0x0
    80004ada:	34c080e7          	jalr	844(ra) # 80004e22 <pipeclose>
    80004ade:	b7cd                	j	80004ac0 <fileclose+0xa8>

0000000080004ae0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ae0:	715d                	addi	sp,sp,-80
    80004ae2:	e486                	sd	ra,72(sp)
    80004ae4:	e0a2                	sd	s0,64(sp)
    80004ae6:	fc26                	sd	s1,56(sp)
    80004ae8:	f84a                	sd	s2,48(sp)
    80004aea:	f44e                	sd	s3,40(sp)
    80004aec:	0880                	addi	s0,sp,80
    80004aee:	84aa                	mv	s1,a0
    80004af0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004af2:	ffffd097          	auipc	ra,0xffffd
    80004af6:	1dc080e7          	jalr	476(ra) # 80001cce <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004afa:	409c                	lw	a5,0(s1)
    80004afc:	37f9                	addiw	a5,a5,-2
    80004afe:	4705                	li	a4,1
    80004b00:	04f76763          	bltu	a4,a5,80004b4e <filestat+0x6e>
    80004b04:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b06:	6c88                	ld	a0,24(s1)
    80004b08:	fffff097          	auipc	ra,0xfffff
    80004b0c:	072080e7          	jalr	114(ra) # 80003b7a <ilock>
    stati(f->ip, &st);
    80004b10:	fb840593          	addi	a1,s0,-72
    80004b14:	6c88                	ld	a0,24(s1)
    80004b16:	fffff097          	auipc	ra,0xfffff
    80004b1a:	2ee080e7          	jalr	750(ra) # 80003e04 <stati>
    iunlock(f->ip);
    80004b1e:	6c88                	ld	a0,24(s1)
    80004b20:	fffff097          	auipc	ra,0xfffff
    80004b24:	11c080e7          	jalr	284(ra) # 80003c3c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b28:	46e1                	li	a3,24
    80004b2a:	fb840613          	addi	a2,s0,-72
    80004b2e:	85ce                	mv	a1,s3
    80004b30:	05093503          	ld	a0,80(s2)
    80004b34:	ffffd097          	auipc	ra,0xffffd
    80004b38:	b3e080e7          	jalr	-1218(ra) # 80001672 <copyout>
    80004b3c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b40:	60a6                	ld	ra,72(sp)
    80004b42:	6406                	ld	s0,64(sp)
    80004b44:	74e2                	ld	s1,56(sp)
    80004b46:	7942                	ld	s2,48(sp)
    80004b48:	79a2                	ld	s3,40(sp)
    80004b4a:	6161                	addi	sp,sp,80
    80004b4c:	8082                	ret
  return -1;
    80004b4e:	557d                	li	a0,-1
    80004b50:	bfc5                	j	80004b40 <filestat+0x60>

0000000080004b52 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b52:	7179                	addi	sp,sp,-48
    80004b54:	f406                	sd	ra,40(sp)
    80004b56:	f022                	sd	s0,32(sp)
    80004b58:	ec26                	sd	s1,24(sp)
    80004b5a:	e84a                	sd	s2,16(sp)
    80004b5c:	e44e                	sd	s3,8(sp)
    80004b5e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b60:	00854783          	lbu	a5,8(a0)
    80004b64:	c3d5                	beqz	a5,80004c08 <fileread+0xb6>
    80004b66:	84aa                	mv	s1,a0
    80004b68:	89ae                	mv	s3,a1
    80004b6a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b6c:	411c                	lw	a5,0(a0)
    80004b6e:	4705                	li	a4,1
    80004b70:	04e78963          	beq	a5,a4,80004bc2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b74:	470d                	li	a4,3
    80004b76:	04e78d63          	beq	a5,a4,80004bd0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b7a:	4709                	li	a4,2
    80004b7c:	06e79e63          	bne	a5,a4,80004bf8 <fileread+0xa6>
    ilock(f->ip);
    80004b80:	6d08                	ld	a0,24(a0)
    80004b82:	fffff097          	auipc	ra,0xfffff
    80004b86:	ff8080e7          	jalr	-8(ra) # 80003b7a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b8a:	874a                	mv	a4,s2
    80004b8c:	5094                	lw	a3,32(s1)
    80004b8e:	864e                	mv	a2,s3
    80004b90:	4585                	li	a1,1
    80004b92:	6c88                	ld	a0,24(s1)
    80004b94:	fffff097          	auipc	ra,0xfffff
    80004b98:	29a080e7          	jalr	666(ra) # 80003e2e <readi>
    80004b9c:	892a                	mv	s2,a0
    80004b9e:	00a05563          	blez	a0,80004ba8 <fileread+0x56>
      f->off += r;
    80004ba2:	509c                	lw	a5,32(s1)
    80004ba4:	9fa9                	addw	a5,a5,a0
    80004ba6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004ba8:	6c88                	ld	a0,24(s1)
    80004baa:	fffff097          	auipc	ra,0xfffff
    80004bae:	092080e7          	jalr	146(ra) # 80003c3c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004bb2:	854a                	mv	a0,s2
    80004bb4:	70a2                	ld	ra,40(sp)
    80004bb6:	7402                	ld	s0,32(sp)
    80004bb8:	64e2                	ld	s1,24(sp)
    80004bba:	6942                	ld	s2,16(sp)
    80004bbc:	69a2                	ld	s3,8(sp)
    80004bbe:	6145                	addi	sp,sp,48
    80004bc0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004bc2:	6908                	ld	a0,16(a0)
    80004bc4:	00000097          	auipc	ra,0x0
    80004bc8:	3c8080e7          	jalr	968(ra) # 80004f8c <piperead>
    80004bcc:	892a                	mv	s2,a0
    80004bce:	b7d5                	j	80004bb2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004bd0:	02451783          	lh	a5,36(a0)
    80004bd4:	03079693          	slli	a3,a5,0x30
    80004bd8:	92c1                	srli	a3,a3,0x30
    80004bda:	4725                	li	a4,9
    80004bdc:	02d76863          	bltu	a4,a3,80004c0c <fileread+0xba>
    80004be0:	0792                	slli	a5,a5,0x4
    80004be2:	0001d717          	auipc	a4,0x1d
    80004be6:	27670713          	addi	a4,a4,630 # 80021e58 <devsw>
    80004bea:	97ba                	add	a5,a5,a4
    80004bec:	639c                	ld	a5,0(a5)
    80004bee:	c38d                	beqz	a5,80004c10 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004bf0:	4505                	li	a0,1
    80004bf2:	9782                	jalr	a5
    80004bf4:	892a                	mv	s2,a0
    80004bf6:	bf75                	j	80004bb2 <fileread+0x60>
    panic("fileread");
    80004bf8:	00004517          	auipc	a0,0x4
    80004bfc:	b3050513          	addi	a0,a0,-1232 # 80008728 <syscalls+0x258>
    80004c00:	ffffc097          	auipc	ra,0xffffc
    80004c04:	93e080e7          	jalr	-1730(ra) # 8000053e <panic>
    return -1;
    80004c08:	597d                	li	s2,-1
    80004c0a:	b765                	j	80004bb2 <fileread+0x60>
      return -1;
    80004c0c:	597d                	li	s2,-1
    80004c0e:	b755                	j	80004bb2 <fileread+0x60>
    80004c10:	597d                	li	s2,-1
    80004c12:	b745                	j	80004bb2 <fileread+0x60>

0000000080004c14 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c14:	715d                	addi	sp,sp,-80
    80004c16:	e486                	sd	ra,72(sp)
    80004c18:	e0a2                	sd	s0,64(sp)
    80004c1a:	fc26                	sd	s1,56(sp)
    80004c1c:	f84a                	sd	s2,48(sp)
    80004c1e:	f44e                	sd	s3,40(sp)
    80004c20:	f052                	sd	s4,32(sp)
    80004c22:	ec56                	sd	s5,24(sp)
    80004c24:	e85a                	sd	s6,16(sp)
    80004c26:	e45e                	sd	s7,8(sp)
    80004c28:	e062                	sd	s8,0(sp)
    80004c2a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c2c:	00954783          	lbu	a5,9(a0)
    80004c30:	10078663          	beqz	a5,80004d3c <filewrite+0x128>
    80004c34:	892a                	mv	s2,a0
    80004c36:	8aae                	mv	s5,a1
    80004c38:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c3a:	411c                	lw	a5,0(a0)
    80004c3c:	4705                	li	a4,1
    80004c3e:	02e78263          	beq	a5,a4,80004c62 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c42:	470d                	li	a4,3
    80004c44:	02e78663          	beq	a5,a4,80004c70 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c48:	4709                	li	a4,2
    80004c4a:	0ee79163          	bne	a5,a4,80004d2c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c4e:	0ac05d63          	blez	a2,80004d08 <filewrite+0xf4>
    int i = 0;
    80004c52:	4981                	li	s3,0
    80004c54:	6b05                	lui	s6,0x1
    80004c56:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c5a:	6b85                	lui	s7,0x1
    80004c5c:	c00b8b9b          	addiw	s7,s7,-1024
    80004c60:	a861                	j	80004cf8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c62:	6908                	ld	a0,16(a0)
    80004c64:	00000097          	auipc	ra,0x0
    80004c68:	22e080e7          	jalr	558(ra) # 80004e92 <pipewrite>
    80004c6c:	8a2a                	mv	s4,a0
    80004c6e:	a045                	j	80004d0e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c70:	02451783          	lh	a5,36(a0)
    80004c74:	03079693          	slli	a3,a5,0x30
    80004c78:	92c1                	srli	a3,a3,0x30
    80004c7a:	4725                	li	a4,9
    80004c7c:	0cd76263          	bltu	a4,a3,80004d40 <filewrite+0x12c>
    80004c80:	0792                	slli	a5,a5,0x4
    80004c82:	0001d717          	auipc	a4,0x1d
    80004c86:	1d670713          	addi	a4,a4,470 # 80021e58 <devsw>
    80004c8a:	97ba                	add	a5,a5,a4
    80004c8c:	679c                	ld	a5,8(a5)
    80004c8e:	cbdd                	beqz	a5,80004d44 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c90:	4505                	li	a0,1
    80004c92:	9782                	jalr	a5
    80004c94:	8a2a                	mv	s4,a0
    80004c96:	a8a5                	j	80004d0e <filewrite+0xfa>
    80004c98:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c9c:	00000097          	auipc	ra,0x0
    80004ca0:	8b0080e7          	jalr	-1872(ra) # 8000454c <begin_op>
      ilock(f->ip);
    80004ca4:	01893503          	ld	a0,24(s2)
    80004ca8:	fffff097          	auipc	ra,0xfffff
    80004cac:	ed2080e7          	jalr	-302(ra) # 80003b7a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004cb0:	8762                	mv	a4,s8
    80004cb2:	02092683          	lw	a3,32(s2)
    80004cb6:	01598633          	add	a2,s3,s5
    80004cba:	4585                	li	a1,1
    80004cbc:	01893503          	ld	a0,24(s2)
    80004cc0:	fffff097          	auipc	ra,0xfffff
    80004cc4:	266080e7          	jalr	614(ra) # 80003f26 <writei>
    80004cc8:	84aa                	mv	s1,a0
    80004cca:	00a05763          	blez	a0,80004cd8 <filewrite+0xc4>
        f->off += r;
    80004cce:	02092783          	lw	a5,32(s2)
    80004cd2:	9fa9                	addw	a5,a5,a0
    80004cd4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cd8:	01893503          	ld	a0,24(s2)
    80004cdc:	fffff097          	auipc	ra,0xfffff
    80004ce0:	f60080e7          	jalr	-160(ra) # 80003c3c <iunlock>
      end_op();
    80004ce4:	00000097          	auipc	ra,0x0
    80004ce8:	8e8080e7          	jalr	-1816(ra) # 800045cc <end_op>

      if(r != n1){
    80004cec:	009c1f63          	bne	s8,s1,80004d0a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004cf0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004cf4:	0149db63          	bge	s3,s4,80004d0a <filewrite+0xf6>
      int n1 = n - i;
    80004cf8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004cfc:	84be                	mv	s1,a5
    80004cfe:	2781                	sext.w	a5,a5
    80004d00:	f8fb5ce3          	bge	s6,a5,80004c98 <filewrite+0x84>
    80004d04:	84de                	mv	s1,s7
    80004d06:	bf49                	j	80004c98 <filewrite+0x84>
    int i = 0;
    80004d08:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d0a:	013a1f63          	bne	s4,s3,80004d28 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d0e:	8552                	mv	a0,s4
    80004d10:	60a6                	ld	ra,72(sp)
    80004d12:	6406                	ld	s0,64(sp)
    80004d14:	74e2                	ld	s1,56(sp)
    80004d16:	7942                	ld	s2,48(sp)
    80004d18:	79a2                	ld	s3,40(sp)
    80004d1a:	7a02                	ld	s4,32(sp)
    80004d1c:	6ae2                	ld	s5,24(sp)
    80004d1e:	6b42                	ld	s6,16(sp)
    80004d20:	6ba2                	ld	s7,8(sp)
    80004d22:	6c02                	ld	s8,0(sp)
    80004d24:	6161                	addi	sp,sp,80
    80004d26:	8082                	ret
    ret = (i == n ? n : -1);
    80004d28:	5a7d                	li	s4,-1
    80004d2a:	b7d5                	j	80004d0e <filewrite+0xfa>
    panic("filewrite");
    80004d2c:	00004517          	auipc	a0,0x4
    80004d30:	a0c50513          	addi	a0,a0,-1524 # 80008738 <syscalls+0x268>
    80004d34:	ffffc097          	auipc	ra,0xffffc
    80004d38:	80a080e7          	jalr	-2038(ra) # 8000053e <panic>
    return -1;
    80004d3c:	5a7d                	li	s4,-1
    80004d3e:	bfc1                	j	80004d0e <filewrite+0xfa>
      return -1;
    80004d40:	5a7d                	li	s4,-1
    80004d42:	b7f1                	j	80004d0e <filewrite+0xfa>
    80004d44:	5a7d                	li	s4,-1
    80004d46:	b7e1                	j	80004d0e <filewrite+0xfa>

0000000080004d48 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d48:	7179                	addi	sp,sp,-48
    80004d4a:	f406                	sd	ra,40(sp)
    80004d4c:	f022                	sd	s0,32(sp)
    80004d4e:	ec26                	sd	s1,24(sp)
    80004d50:	e84a                	sd	s2,16(sp)
    80004d52:	e44e                	sd	s3,8(sp)
    80004d54:	e052                	sd	s4,0(sp)
    80004d56:	1800                	addi	s0,sp,48
    80004d58:	84aa                	mv	s1,a0
    80004d5a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d5c:	0005b023          	sd	zero,0(a1)
    80004d60:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d64:	00000097          	auipc	ra,0x0
    80004d68:	bf8080e7          	jalr	-1032(ra) # 8000495c <filealloc>
    80004d6c:	e088                	sd	a0,0(s1)
    80004d6e:	c551                	beqz	a0,80004dfa <pipealloc+0xb2>
    80004d70:	00000097          	auipc	ra,0x0
    80004d74:	bec080e7          	jalr	-1044(ra) # 8000495c <filealloc>
    80004d78:	00aa3023          	sd	a0,0(s4)
    80004d7c:	c92d                	beqz	a0,80004dee <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d7e:	ffffc097          	auipc	ra,0xffffc
    80004d82:	d76080e7          	jalr	-650(ra) # 80000af4 <kalloc>
    80004d86:	892a                	mv	s2,a0
    80004d88:	c125                	beqz	a0,80004de8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d8a:	4985                	li	s3,1
    80004d8c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d90:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d94:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d98:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d9c:	00004597          	auipc	a1,0x4
    80004da0:	9ac58593          	addi	a1,a1,-1620 # 80008748 <syscalls+0x278>
    80004da4:	ffffc097          	auipc	ra,0xffffc
    80004da8:	db0080e7          	jalr	-592(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004dac:	609c                	ld	a5,0(s1)
    80004dae:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004db2:	609c                	ld	a5,0(s1)
    80004db4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004db8:	609c                	ld	a5,0(s1)
    80004dba:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004dbe:	609c                	ld	a5,0(s1)
    80004dc0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004dc4:	000a3783          	ld	a5,0(s4)
    80004dc8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004dcc:	000a3783          	ld	a5,0(s4)
    80004dd0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004dd4:	000a3783          	ld	a5,0(s4)
    80004dd8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ddc:	000a3783          	ld	a5,0(s4)
    80004de0:	0127b823          	sd	s2,16(a5)
  return 0;
    80004de4:	4501                	li	a0,0
    80004de6:	a025                	j	80004e0e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004de8:	6088                	ld	a0,0(s1)
    80004dea:	e501                	bnez	a0,80004df2 <pipealloc+0xaa>
    80004dec:	a039                	j	80004dfa <pipealloc+0xb2>
    80004dee:	6088                	ld	a0,0(s1)
    80004df0:	c51d                	beqz	a0,80004e1e <pipealloc+0xd6>
    fileclose(*f0);
    80004df2:	00000097          	auipc	ra,0x0
    80004df6:	c26080e7          	jalr	-986(ra) # 80004a18 <fileclose>
  if(*f1)
    80004dfa:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004dfe:	557d                	li	a0,-1
  if(*f1)
    80004e00:	c799                	beqz	a5,80004e0e <pipealloc+0xc6>
    fileclose(*f1);
    80004e02:	853e                	mv	a0,a5
    80004e04:	00000097          	auipc	ra,0x0
    80004e08:	c14080e7          	jalr	-1004(ra) # 80004a18 <fileclose>
  return -1;
    80004e0c:	557d                	li	a0,-1
}
    80004e0e:	70a2                	ld	ra,40(sp)
    80004e10:	7402                	ld	s0,32(sp)
    80004e12:	64e2                	ld	s1,24(sp)
    80004e14:	6942                	ld	s2,16(sp)
    80004e16:	69a2                	ld	s3,8(sp)
    80004e18:	6a02                	ld	s4,0(sp)
    80004e1a:	6145                	addi	sp,sp,48
    80004e1c:	8082                	ret
  return -1;
    80004e1e:	557d                	li	a0,-1
    80004e20:	b7fd                	j	80004e0e <pipealloc+0xc6>

0000000080004e22 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e22:	1101                	addi	sp,sp,-32
    80004e24:	ec06                	sd	ra,24(sp)
    80004e26:	e822                	sd	s0,16(sp)
    80004e28:	e426                	sd	s1,8(sp)
    80004e2a:	e04a                	sd	s2,0(sp)
    80004e2c:	1000                	addi	s0,sp,32
    80004e2e:	84aa                	mv	s1,a0
    80004e30:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e32:	ffffc097          	auipc	ra,0xffffc
    80004e36:	db2080e7          	jalr	-590(ra) # 80000be4 <acquire>
  if(writable){
    80004e3a:	02090d63          	beqz	s2,80004e74 <pipeclose+0x52>
    pi->writeopen = 0;
    80004e3e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e42:	21848513          	addi	a0,s1,536
    80004e46:	ffffe097          	auipc	ra,0xffffe
    80004e4a:	826080e7          	jalr	-2010(ra) # 8000266c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e4e:	2204b783          	ld	a5,544(s1)
    80004e52:	eb95                	bnez	a5,80004e86 <pipeclose+0x64>
    release(&pi->lock);
    80004e54:	8526                	mv	a0,s1
    80004e56:	ffffc097          	auipc	ra,0xffffc
    80004e5a:	e42080e7          	jalr	-446(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004e5e:	8526                	mv	a0,s1
    80004e60:	ffffc097          	auipc	ra,0xffffc
    80004e64:	b98080e7          	jalr	-1128(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004e68:	60e2                	ld	ra,24(sp)
    80004e6a:	6442                	ld	s0,16(sp)
    80004e6c:	64a2                	ld	s1,8(sp)
    80004e6e:	6902                	ld	s2,0(sp)
    80004e70:	6105                	addi	sp,sp,32
    80004e72:	8082                	ret
    pi->readopen = 0;
    80004e74:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e78:	21c48513          	addi	a0,s1,540
    80004e7c:	ffffd097          	auipc	ra,0xffffd
    80004e80:	7f0080e7          	jalr	2032(ra) # 8000266c <wakeup>
    80004e84:	b7e9                	j	80004e4e <pipeclose+0x2c>
    release(&pi->lock);
    80004e86:	8526                	mv	a0,s1
    80004e88:	ffffc097          	auipc	ra,0xffffc
    80004e8c:	e10080e7          	jalr	-496(ra) # 80000c98 <release>
}
    80004e90:	bfe1                	j	80004e68 <pipeclose+0x46>

0000000080004e92 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e92:	7159                	addi	sp,sp,-112
    80004e94:	f486                	sd	ra,104(sp)
    80004e96:	f0a2                	sd	s0,96(sp)
    80004e98:	eca6                	sd	s1,88(sp)
    80004e9a:	e8ca                	sd	s2,80(sp)
    80004e9c:	e4ce                	sd	s3,72(sp)
    80004e9e:	e0d2                	sd	s4,64(sp)
    80004ea0:	fc56                	sd	s5,56(sp)
    80004ea2:	f85a                	sd	s6,48(sp)
    80004ea4:	f45e                	sd	s7,40(sp)
    80004ea6:	f062                	sd	s8,32(sp)
    80004ea8:	ec66                	sd	s9,24(sp)
    80004eaa:	1880                	addi	s0,sp,112
    80004eac:	84aa                	mv	s1,a0
    80004eae:	8aae                	mv	s5,a1
    80004eb0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004eb2:	ffffd097          	auipc	ra,0xffffd
    80004eb6:	e1c080e7          	jalr	-484(ra) # 80001cce <myproc>
    80004eba:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ebc:	8526                	mv	a0,s1
    80004ebe:	ffffc097          	auipc	ra,0xffffc
    80004ec2:	d26080e7          	jalr	-730(ra) # 80000be4 <acquire>
  while(i < n){
    80004ec6:	0d405163          	blez	s4,80004f88 <pipewrite+0xf6>
    80004eca:	8ba6                	mv	s7,s1
  int i = 0;
    80004ecc:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ece:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ed0:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ed4:	21c48c13          	addi	s8,s1,540
    80004ed8:	a08d                	j	80004f3a <pipewrite+0xa8>
      release(&pi->lock);
    80004eda:	8526                	mv	a0,s1
    80004edc:	ffffc097          	auipc	ra,0xffffc
    80004ee0:	dbc080e7          	jalr	-580(ra) # 80000c98 <release>
      return -1;
    80004ee4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ee6:	854a                	mv	a0,s2
    80004ee8:	70a6                	ld	ra,104(sp)
    80004eea:	7406                	ld	s0,96(sp)
    80004eec:	64e6                	ld	s1,88(sp)
    80004eee:	6946                	ld	s2,80(sp)
    80004ef0:	69a6                	ld	s3,72(sp)
    80004ef2:	6a06                	ld	s4,64(sp)
    80004ef4:	7ae2                	ld	s5,56(sp)
    80004ef6:	7b42                	ld	s6,48(sp)
    80004ef8:	7ba2                	ld	s7,40(sp)
    80004efa:	7c02                	ld	s8,32(sp)
    80004efc:	6ce2                	ld	s9,24(sp)
    80004efe:	6165                	addi	sp,sp,112
    80004f00:	8082                	ret
      wakeup(&pi->nread);
    80004f02:	8566                	mv	a0,s9
    80004f04:	ffffd097          	auipc	ra,0xffffd
    80004f08:	768080e7          	jalr	1896(ra) # 8000266c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f0c:	85de                	mv	a1,s7
    80004f0e:	8562                	mv	a0,s8
    80004f10:	ffffd097          	auipc	ra,0xffffd
    80004f14:	5be080e7          	jalr	1470(ra) # 800024ce <sleep>
    80004f18:	a839                	j	80004f36 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f1a:	21c4a783          	lw	a5,540(s1)
    80004f1e:	0017871b          	addiw	a4,a5,1
    80004f22:	20e4ae23          	sw	a4,540(s1)
    80004f26:	1ff7f793          	andi	a5,a5,511
    80004f2a:	97a6                	add	a5,a5,s1
    80004f2c:	f9f44703          	lbu	a4,-97(s0)
    80004f30:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f34:	2905                	addiw	s2,s2,1
  while(i < n){
    80004f36:	03495d63          	bge	s2,s4,80004f70 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004f3a:	2204a783          	lw	a5,544(s1)
    80004f3e:	dfd1                	beqz	a5,80004eda <pipewrite+0x48>
    80004f40:	0289a783          	lw	a5,40(s3)
    80004f44:	fbd9                	bnez	a5,80004eda <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f46:	2184a783          	lw	a5,536(s1)
    80004f4a:	21c4a703          	lw	a4,540(s1)
    80004f4e:	2007879b          	addiw	a5,a5,512
    80004f52:	faf708e3          	beq	a4,a5,80004f02 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f56:	4685                	li	a3,1
    80004f58:	01590633          	add	a2,s2,s5
    80004f5c:	f9f40593          	addi	a1,s0,-97
    80004f60:	0509b503          	ld	a0,80(s3)
    80004f64:	ffffc097          	auipc	ra,0xffffc
    80004f68:	79a080e7          	jalr	1946(ra) # 800016fe <copyin>
    80004f6c:	fb6517e3          	bne	a0,s6,80004f1a <pipewrite+0x88>
  wakeup(&pi->nread);
    80004f70:	21848513          	addi	a0,s1,536
    80004f74:	ffffd097          	auipc	ra,0xffffd
    80004f78:	6f8080e7          	jalr	1784(ra) # 8000266c <wakeup>
  release(&pi->lock);
    80004f7c:	8526                	mv	a0,s1
    80004f7e:	ffffc097          	auipc	ra,0xffffc
    80004f82:	d1a080e7          	jalr	-742(ra) # 80000c98 <release>
  return i;
    80004f86:	b785                	j	80004ee6 <pipewrite+0x54>
  int i = 0;
    80004f88:	4901                	li	s2,0
    80004f8a:	b7dd                	j	80004f70 <pipewrite+0xde>

0000000080004f8c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f8c:	715d                	addi	sp,sp,-80
    80004f8e:	e486                	sd	ra,72(sp)
    80004f90:	e0a2                	sd	s0,64(sp)
    80004f92:	fc26                	sd	s1,56(sp)
    80004f94:	f84a                	sd	s2,48(sp)
    80004f96:	f44e                	sd	s3,40(sp)
    80004f98:	f052                	sd	s4,32(sp)
    80004f9a:	ec56                	sd	s5,24(sp)
    80004f9c:	e85a                	sd	s6,16(sp)
    80004f9e:	0880                	addi	s0,sp,80
    80004fa0:	84aa                	mv	s1,a0
    80004fa2:	892e                	mv	s2,a1
    80004fa4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004fa6:	ffffd097          	auipc	ra,0xffffd
    80004faa:	d28080e7          	jalr	-728(ra) # 80001cce <myproc>
    80004fae:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004fb0:	8b26                	mv	s6,s1
    80004fb2:	8526                	mv	a0,s1
    80004fb4:	ffffc097          	auipc	ra,0xffffc
    80004fb8:	c30080e7          	jalr	-976(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fbc:	2184a703          	lw	a4,536(s1)
    80004fc0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fc4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fc8:	02f71463          	bne	a4,a5,80004ff0 <piperead+0x64>
    80004fcc:	2244a783          	lw	a5,548(s1)
    80004fd0:	c385                	beqz	a5,80004ff0 <piperead+0x64>
    if(pr->killed){
    80004fd2:	028a2783          	lw	a5,40(s4)
    80004fd6:	ebc1                	bnez	a5,80005066 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fd8:	85da                	mv	a1,s6
    80004fda:	854e                	mv	a0,s3
    80004fdc:	ffffd097          	auipc	ra,0xffffd
    80004fe0:	4f2080e7          	jalr	1266(ra) # 800024ce <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fe4:	2184a703          	lw	a4,536(s1)
    80004fe8:	21c4a783          	lw	a5,540(s1)
    80004fec:	fef700e3          	beq	a4,a5,80004fcc <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ff0:	09505263          	blez	s5,80005074 <piperead+0xe8>
    80004ff4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ff6:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004ff8:	2184a783          	lw	a5,536(s1)
    80004ffc:	21c4a703          	lw	a4,540(s1)
    80005000:	02f70d63          	beq	a4,a5,8000503a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005004:	0017871b          	addiw	a4,a5,1
    80005008:	20e4ac23          	sw	a4,536(s1)
    8000500c:	1ff7f793          	andi	a5,a5,511
    80005010:	97a6                	add	a5,a5,s1
    80005012:	0187c783          	lbu	a5,24(a5)
    80005016:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000501a:	4685                	li	a3,1
    8000501c:	fbf40613          	addi	a2,s0,-65
    80005020:	85ca                	mv	a1,s2
    80005022:	050a3503          	ld	a0,80(s4)
    80005026:	ffffc097          	auipc	ra,0xffffc
    8000502a:	64c080e7          	jalr	1612(ra) # 80001672 <copyout>
    8000502e:	01650663          	beq	a0,s6,8000503a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005032:	2985                	addiw	s3,s3,1
    80005034:	0905                	addi	s2,s2,1
    80005036:	fd3a91e3          	bne	s5,s3,80004ff8 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000503a:	21c48513          	addi	a0,s1,540
    8000503e:	ffffd097          	auipc	ra,0xffffd
    80005042:	62e080e7          	jalr	1582(ra) # 8000266c <wakeup>
  release(&pi->lock);
    80005046:	8526                	mv	a0,s1
    80005048:	ffffc097          	auipc	ra,0xffffc
    8000504c:	c50080e7          	jalr	-944(ra) # 80000c98 <release>
  return i;
}
    80005050:	854e                	mv	a0,s3
    80005052:	60a6                	ld	ra,72(sp)
    80005054:	6406                	ld	s0,64(sp)
    80005056:	74e2                	ld	s1,56(sp)
    80005058:	7942                	ld	s2,48(sp)
    8000505a:	79a2                	ld	s3,40(sp)
    8000505c:	7a02                	ld	s4,32(sp)
    8000505e:	6ae2                	ld	s5,24(sp)
    80005060:	6b42                	ld	s6,16(sp)
    80005062:	6161                	addi	sp,sp,80
    80005064:	8082                	ret
      release(&pi->lock);
    80005066:	8526                	mv	a0,s1
    80005068:	ffffc097          	auipc	ra,0xffffc
    8000506c:	c30080e7          	jalr	-976(ra) # 80000c98 <release>
      return -1;
    80005070:	59fd                	li	s3,-1
    80005072:	bff9                	j	80005050 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005074:	4981                	li	s3,0
    80005076:	b7d1                	j	8000503a <piperead+0xae>

0000000080005078 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005078:	df010113          	addi	sp,sp,-528
    8000507c:	20113423          	sd	ra,520(sp)
    80005080:	20813023          	sd	s0,512(sp)
    80005084:	ffa6                	sd	s1,504(sp)
    80005086:	fbca                	sd	s2,496(sp)
    80005088:	f7ce                	sd	s3,488(sp)
    8000508a:	f3d2                	sd	s4,480(sp)
    8000508c:	efd6                	sd	s5,472(sp)
    8000508e:	ebda                	sd	s6,464(sp)
    80005090:	e7de                	sd	s7,456(sp)
    80005092:	e3e2                	sd	s8,448(sp)
    80005094:	ff66                	sd	s9,440(sp)
    80005096:	fb6a                	sd	s10,432(sp)
    80005098:	f76e                	sd	s11,424(sp)
    8000509a:	0c00                	addi	s0,sp,528
    8000509c:	84aa                	mv	s1,a0
    8000509e:	dea43c23          	sd	a0,-520(s0)
    800050a2:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050a6:	ffffd097          	auipc	ra,0xffffd
    800050aa:	c28080e7          	jalr	-984(ra) # 80001cce <myproc>
    800050ae:	892a                	mv	s2,a0

  begin_op();
    800050b0:	fffff097          	auipc	ra,0xfffff
    800050b4:	49c080e7          	jalr	1180(ra) # 8000454c <begin_op>

  if((ip = namei(path)) == 0){
    800050b8:	8526                	mv	a0,s1
    800050ba:	fffff097          	auipc	ra,0xfffff
    800050be:	276080e7          	jalr	630(ra) # 80004330 <namei>
    800050c2:	c92d                	beqz	a0,80005134 <exec+0xbc>
    800050c4:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800050c6:	fffff097          	auipc	ra,0xfffff
    800050ca:	ab4080e7          	jalr	-1356(ra) # 80003b7a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050ce:	04000713          	li	a4,64
    800050d2:	4681                	li	a3,0
    800050d4:	e5040613          	addi	a2,s0,-432
    800050d8:	4581                	li	a1,0
    800050da:	8526                	mv	a0,s1
    800050dc:	fffff097          	auipc	ra,0xfffff
    800050e0:	d52080e7          	jalr	-686(ra) # 80003e2e <readi>
    800050e4:	04000793          	li	a5,64
    800050e8:	00f51a63          	bne	a0,a5,800050fc <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800050ec:	e5042703          	lw	a4,-432(s0)
    800050f0:	464c47b7          	lui	a5,0x464c4
    800050f4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800050f8:	04f70463          	beq	a4,a5,80005140 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800050fc:	8526                	mv	a0,s1
    800050fe:	fffff097          	auipc	ra,0xfffff
    80005102:	cde080e7          	jalr	-802(ra) # 80003ddc <iunlockput>
    end_op();
    80005106:	fffff097          	auipc	ra,0xfffff
    8000510a:	4c6080e7          	jalr	1222(ra) # 800045cc <end_op>
  }
  return -1;
    8000510e:	557d                	li	a0,-1
}
    80005110:	20813083          	ld	ra,520(sp)
    80005114:	20013403          	ld	s0,512(sp)
    80005118:	74fe                	ld	s1,504(sp)
    8000511a:	795e                	ld	s2,496(sp)
    8000511c:	79be                	ld	s3,488(sp)
    8000511e:	7a1e                	ld	s4,480(sp)
    80005120:	6afe                	ld	s5,472(sp)
    80005122:	6b5e                	ld	s6,464(sp)
    80005124:	6bbe                	ld	s7,456(sp)
    80005126:	6c1e                	ld	s8,448(sp)
    80005128:	7cfa                	ld	s9,440(sp)
    8000512a:	7d5a                	ld	s10,432(sp)
    8000512c:	7dba                	ld	s11,424(sp)
    8000512e:	21010113          	addi	sp,sp,528
    80005132:	8082                	ret
    end_op();
    80005134:	fffff097          	auipc	ra,0xfffff
    80005138:	498080e7          	jalr	1176(ra) # 800045cc <end_op>
    return -1;
    8000513c:	557d                	li	a0,-1
    8000513e:	bfc9                	j	80005110 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005140:	854a                	mv	a0,s2
    80005142:	ffffd097          	auipc	ra,0xffffd
    80005146:	c4a080e7          	jalr	-950(ra) # 80001d8c <proc_pagetable>
    8000514a:	8baa                	mv	s7,a0
    8000514c:	d945                	beqz	a0,800050fc <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000514e:	e7042983          	lw	s3,-400(s0)
    80005152:	e8845783          	lhu	a5,-376(s0)
    80005156:	c7ad                	beqz	a5,800051c0 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005158:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000515a:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    8000515c:	6c85                	lui	s9,0x1
    8000515e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005162:	def43823          	sd	a5,-528(s0)
    80005166:	a42d                	j	80005390 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005168:	00003517          	auipc	a0,0x3
    8000516c:	5e850513          	addi	a0,a0,1512 # 80008750 <syscalls+0x280>
    80005170:	ffffb097          	auipc	ra,0xffffb
    80005174:	3ce080e7          	jalr	974(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005178:	8756                	mv	a4,s5
    8000517a:	012d86bb          	addw	a3,s11,s2
    8000517e:	4581                	li	a1,0
    80005180:	8526                	mv	a0,s1
    80005182:	fffff097          	auipc	ra,0xfffff
    80005186:	cac080e7          	jalr	-852(ra) # 80003e2e <readi>
    8000518a:	2501                	sext.w	a0,a0
    8000518c:	1aaa9963          	bne	s5,a0,8000533e <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005190:	6785                	lui	a5,0x1
    80005192:	0127893b          	addw	s2,a5,s2
    80005196:	77fd                	lui	a5,0xfffff
    80005198:	01478a3b          	addw	s4,a5,s4
    8000519c:	1f897163          	bgeu	s2,s8,8000537e <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800051a0:	02091593          	slli	a1,s2,0x20
    800051a4:	9181                	srli	a1,a1,0x20
    800051a6:	95ea                	add	a1,a1,s10
    800051a8:	855e                	mv	a0,s7
    800051aa:	ffffc097          	auipc	ra,0xffffc
    800051ae:	ec4080e7          	jalr	-316(ra) # 8000106e <walkaddr>
    800051b2:	862a                	mv	a2,a0
    if(pa == 0)
    800051b4:	d955                	beqz	a0,80005168 <exec+0xf0>
      n = PGSIZE;
    800051b6:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800051b8:	fd9a70e3          	bgeu	s4,s9,80005178 <exec+0x100>
      n = sz - i;
    800051bc:	8ad2                	mv	s5,s4
    800051be:	bf6d                	j	80005178 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051c0:	4901                	li	s2,0
  iunlockput(ip);
    800051c2:	8526                	mv	a0,s1
    800051c4:	fffff097          	auipc	ra,0xfffff
    800051c8:	c18080e7          	jalr	-1000(ra) # 80003ddc <iunlockput>
  end_op();
    800051cc:	fffff097          	auipc	ra,0xfffff
    800051d0:	400080e7          	jalr	1024(ra) # 800045cc <end_op>
  p = myproc();
    800051d4:	ffffd097          	auipc	ra,0xffffd
    800051d8:	afa080e7          	jalr	-1286(ra) # 80001cce <myproc>
    800051dc:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800051de:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800051e2:	6785                	lui	a5,0x1
    800051e4:	17fd                	addi	a5,a5,-1
    800051e6:	993e                	add	s2,s2,a5
    800051e8:	757d                	lui	a0,0xfffff
    800051ea:	00a977b3          	and	a5,s2,a0
    800051ee:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051f2:	6609                	lui	a2,0x2
    800051f4:	963e                	add	a2,a2,a5
    800051f6:	85be                	mv	a1,a5
    800051f8:	855e                	mv	a0,s7
    800051fa:	ffffc097          	auipc	ra,0xffffc
    800051fe:	228080e7          	jalr	552(ra) # 80001422 <uvmalloc>
    80005202:	8b2a                	mv	s6,a0
  ip = 0;
    80005204:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005206:	12050c63          	beqz	a0,8000533e <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000520a:	75f9                	lui	a1,0xffffe
    8000520c:	95aa                	add	a1,a1,a0
    8000520e:	855e                	mv	a0,s7
    80005210:	ffffc097          	auipc	ra,0xffffc
    80005214:	430080e7          	jalr	1072(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005218:	7c7d                	lui	s8,0xfffff
    8000521a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000521c:	e0043783          	ld	a5,-512(s0)
    80005220:	6388                	ld	a0,0(a5)
    80005222:	c535                	beqz	a0,8000528e <exec+0x216>
    80005224:	e9040993          	addi	s3,s0,-368
    80005228:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000522c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000522e:	ffffc097          	auipc	ra,0xffffc
    80005232:	c36080e7          	jalr	-970(ra) # 80000e64 <strlen>
    80005236:	2505                	addiw	a0,a0,1
    80005238:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000523c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005240:	13896363          	bltu	s2,s8,80005366 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005244:	e0043d83          	ld	s11,-512(s0)
    80005248:	000dba03          	ld	s4,0(s11)
    8000524c:	8552                	mv	a0,s4
    8000524e:	ffffc097          	auipc	ra,0xffffc
    80005252:	c16080e7          	jalr	-1002(ra) # 80000e64 <strlen>
    80005256:	0015069b          	addiw	a3,a0,1
    8000525a:	8652                	mv	a2,s4
    8000525c:	85ca                	mv	a1,s2
    8000525e:	855e                	mv	a0,s7
    80005260:	ffffc097          	auipc	ra,0xffffc
    80005264:	412080e7          	jalr	1042(ra) # 80001672 <copyout>
    80005268:	10054363          	bltz	a0,8000536e <exec+0x2f6>
    ustack[argc] = sp;
    8000526c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005270:	0485                	addi	s1,s1,1
    80005272:	008d8793          	addi	a5,s11,8
    80005276:	e0f43023          	sd	a5,-512(s0)
    8000527a:	008db503          	ld	a0,8(s11)
    8000527e:	c911                	beqz	a0,80005292 <exec+0x21a>
    if(argc >= MAXARG)
    80005280:	09a1                	addi	s3,s3,8
    80005282:	fb3c96e3          	bne	s9,s3,8000522e <exec+0x1b6>
  sz = sz1;
    80005286:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000528a:	4481                	li	s1,0
    8000528c:	a84d                	j	8000533e <exec+0x2c6>
  sp = sz;
    8000528e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005290:	4481                	li	s1,0
  ustack[argc] = 0;
    80005292:	00349793          	slli	a5,s1,0x3
    80005296:	f9040713          	addi	a4,s0,-112
    8000529a:	97ba                	add	a5,a5,a4
    8000529c:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800052a0:	00148693          	addi	a3,s1,1
    800052a4:	068e                	slli	a3,a3,0x3
    800052a6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800052aa:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800052ae:	01897663          	bgeu	s2,s8,800052ba <exec+0x242>
  sz = sz1;
    800052b2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052b6:	4481                	li	s1,0
    800052b8:	a059                	j	8000533e <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800052ba:	e9040613          	addi	a2,s0,-368
    800052be:	85ca                	mv	a1,s2
    800052c0:	855e                	mv	a0,s7
    800052c2:	ffffc097          	auipc	ra,0xffffc
    800052c6:	3b0080e7          	jalr	944(ra) # 80001672 <copyout>
    800052ca:	0a054663          	bltz	a0,80005376 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800052ce:	058ab783          	ld	a5,88(s5)
    800052d2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800052d6:	df843783          	ld	a5,-520(s0)
    800052da:	0007c703          	lbu	a4,0(a5)
    800052de:	cf11                	beqz	a4,800052fa <exec+0x282>
    800052e0:	0785                	addi	a5,a5,1
    if(*s == '/')
    800052e2:	02f00693          	li	a3,47
    800052e6:	a039                	j	800052f4 <exec+0x27c>
      last = s+1;
    800052e8:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800052ec:	0785                	addi	a5,a5,1
    800052ee:	fff7c703          	lbu	a4,-1(a5)
    800052f2:	c701                	beqz	a4,800052fa <exec+0x282>
    if(*s == '/')
    800052f4:	fed71ce3          	bne	a4,a3,800052ec <exec+0x274>
    800052f8:	bfc5                	j	800052e8 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800052fa:	4641                	li	a2,16
    800052fc:	df843583          	ld	a1,-520(s0)
    80005300:	158a8513          	addi	a0,s5,344
    80005304:	ffffc097          	auipc	ra,0xffffc
    80005308:	b2e080e7          	jalr	-1234(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000530c:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005310:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005314:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005318:	058ab783          	ld	a5,88(s5)
    8000531c:	e6843703          	ld	a4,-408(s0)
    80005320:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005322:	058ab783          	ld	a5,88(s5)
    80005326:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000532a:	85ea                	mv	a1,s10
    8000532c:	ffffd097          	auipc	ra,0xffffd
    80005330:	afc080e7          	jalr	-1284(ra) # 80001e28 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005334:	0004851b          	sext.w	a0,s1
    80005338:	bbe1                	j	80005110 <exec+0x98>
    8000533a:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000533e:	e0843583          	ld	a1,-504(s0)
    80005342:	855e                	mv	a0,s7
    80005344:	ffffd097          	auipc	ra,0xffffd
    80005348:	ae4080e7          	jalr	-1308(ra) # 80001e28 <proc_freepagetable>
  if(ip){
    8000534c:	da0498e3          	bnez	s1,800050fc <exec+0x84>
  return -1;
    80005350:	557d                	li	a0,-1
    80005352:	bb7d                	j	80005110 <exec+0x98>
    80005354:	e1243423          	sd	s2,-504(s0)
    80005358:	b7dd                	j	8000533e <exec+0x2c6>
    8000535a:	e1243423          	sd	s2,-504(s0)
    8000535e:	b7c5                	j	8000533e <exec+0x2c6>
    80005360:	e1243423          	sd	s2,-504(s0)
    80005364:	bfe9                	j	8000533e <exec+0x2c6>
  sz = sz1;
    80005366:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000536a:	4481                	li	s1,0
    8000536c:	bfc9                	j	8000533e <exec+0x2c6>
  sz = sz1;
    8000536e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005372:	4481                	li	s1,0
    80005374:	b7e9                	j	8000533e <exec+0x2c6>
  sz = sz1;
    80005376:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000537a:	4481                	li	s1,0
    8000537c:	b7c9                	j	8000533e <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000537e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005382:	2b05                	addiw	s6,s6,1
    80005384:	0389899b          	addiw	s3,s3,56
    80005388:	e8845783          	lhu	a5,-376(s0)
    8000538c:	e2fb5be3          	bge	s6,a5,800051c2 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005390:	2981                	sext.w	s3,s3
    80005392:	03800713          	li	a4,56
    80005396:	86ce                	mv	a3,s3
    80005398:	e1840613          	addi	a2,s0,-488
    8000539c:	4581                	li	a1,0
    8000539e:	8526                	mv	a0,s1
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	a8e080e7          	jalr	-1394(ra) # 80003e2e <readi>
    800053a8:	03800793          	li	a5,56
    800053ac:	f8f517e3          	bne	a0,a5,8000533a <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800053b0:	e1842783          	lw	a5,-488(s0)
    800053b4:	4705                	li	a4,1
    800053b6:	fce796e3          	bne	a5,a4,80005382 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800053ba:	e4043603          	ld	a2,-448(s0)
    800053be:	e3843783          	ld	a5,-456(s0)
    800053c2:	f8f669e3          	bltu	a2,a5,80005354 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053c6:	e2843783          	ld	a5,-472(s0)
    800053ca:	963e                	add	a2,a2,a5
    800053cc:	f8f667e3          	bltu	a2,a5,8000535a <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053d0:	85ca                	mv	a1,s2
    800053d2:	855e                	mv	a0,s7
    800053d4:	ffffc097          	auipc	ra,0xffffc
    800053d8:	04e080e7          	jalr	78(ra) # 80001422 <uvmalloc>
    800053dc:	e0a43423          	sd	a0,-504(s0)
    800053e0:	d141                	beqz	a0,80005360 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800053e2:	e2843d03          	ld	s10,-472(s0)
    800053e6:	df043783          	ld	a5,-528(s0)
    800053ea:	00fd77b3          	and	a5,s10,a5
    800053ee:	fba1                	bnez	a5,8000533e <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053f0:	e2042d83          	lw	s11,-480(s0)
    800053f4:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053f8:	f80c03e3          	beqz	s8,8000537e <exec+0x306>
    800053fc:	8a62                	mv	s4,s8
    800053fe:	4901                	li	s2,0
    80005400:	b345                	j	800051a0 <exec+0x128>

0000000080005402 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005402:	7179                	addi	sp,sp,-48
    80005404:	f406                	sd	ra,40(sp)
    80005406:	f022                	sd	s0,32(sp)
    80005408:	ec26                	sd	s1,24(sp)
    8000540a:	e84a                	sd	s2,16(sp)
    8000540c:	1800                	addi	s0,sp,48
    8000540e:	892e                	mv	s2,a1
    80005410:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005412:	fdc40593          	addi	a1,s0,-36
    80005416:	ffffe097          	auipc	ra,0xffffe
    8000541a:	bf2080e7          	jalr	-1038(ra) # 80003008 <argint>
    8000541e:	04054063          	bltz	a0,8000545e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005422:	fdc42703          	lw	a4,-36(s0)
    80005426:	47bd                	li	a5,15
    80005428:	02e7ed63          	bltu	a5,a4,80005462 <argfd+0x60>
    8000542c:	ffffd097          	auipc	ra,0xffffd
    80005430:	8a2080e7          	jalr	-1886(ra) # 80001cce <myproc>
    80005434:	fdc42703          	lw	a4,-36(s0)
    80005438:	01a70793          	addi	a5,a4,26
    8000543c:	078e                	slli	a5,a5,0x3
    8000543e:	953e                	add	a0,a0,a5
    80005440:	611c                	ld	a5,0(a0)
    80005442:	c395                	beqz	a5,80005466 <argfd+0x64>
    return -1;
  if(pfd)
    80005444:	00090463          	beqz	s2,8000544c <argfd+0x4a>
    *pfd = fd;
    80005448:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000544c:	4501                	li	a0,0
  if(pf)
    8000544e:	c091                	beqz	s1,80005452 <argfd+0x50>
    *pf = f;
    80005450:	e09c                	sd	a5,0(s1)
}
    80005452:	70a2                	ld	ra,40(sp)
    80005454:	7402                	ld	s0,32(sp)
    80005456:	64e2                	ld	s1,24(sp)
    80005458:	6942                	ld	s2,16(sp)
    8000545a:	6145                	addi	sp,sp,48
    8000545c:	8082                	ret
    return -1;
    8000545e:	557d                	li	a0,-1
    80005460:	bfcd                	j	80005452 <argfd+0x50>
    return -1;
    80005462:	557d                	li	a0,-1
    80005464:	b7fd                	j	80005452 <argfd+0x50>
    80005466:	557d                	li	a0,-1
    80005468:	b7ed                	j	80005452 <argfd+0x50>

000000008000546a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000546a:	1101                	addi	sp,sp,-32
    8000546c:	ec06                	sd	ra,24(sp)
    8000546e:	e822                	sd	s0,16(sp)
    80005470:	e426                	sd	s1,8(sp)
    80005472:	1000                	addi	s0,sp,32
    80005474:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005476:	ffffd097          	auipc	ra,0xffffd
    8000547a:	858080e7          	jalr	-1960(ra) # 80001cce <myproc>
    8000547e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005480:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005484:	4501                	li	a0,0
    80005486:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005488:	6398                	ld	a4,0(a5)
    8000548a:	cb19                	beqz	a4,800054a0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000548c:	2505                	addiw	a0,a0,1
    8000548e:	07a1                	addi	a5,a5,8
    80005490:	fed51ce3          	bne	a0,a3,80005488 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005494:	557d                	li	a0,-1
}
    80005496:	60e2                	ld	ra,24(sp)
    80005498:	6442                	ld	s0,16(sp)
    8000549a:	64a2                	ld	s1,8(sp)
    8000549c:	6105                	addi	sp,sp,32
    8000549e:	8082                	ret
      p->ofile[fd] = f;
    800054a0:	01a50793          	addi	a5,a0,26
    800054a4:	078e                	slli	a5,a5,0x3
    800054a6:	963e                	add	a2,a2,a5
    800054a8:	e204                	sd	s1,0(a2)
      return fd;
    800054aa:	b7f5                	j	80005496 <fdalloc+0x2c>

00000000800054ac <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054ac:	715d                	addi	sp,sp,-80
    800054ae:	e486                	sd	ra,72(sp)
    800054b0:	e0a2                	sd	s0,64(sp)
    800054b2:	fc26                	sd	s1,56(sp)
    800054b4:	f84a                	sd	s2,48(sp)
    800054b6:	f44e                	sd	s3,40(sp)
    800054b8:	f052                	sd	s4,32(sp)
    800054ba:	ec56                	sd	s5,24(sp)
    800054bc:	0880                	addi	s0,sp,80
    800054be:	89ae                	mv	s3,a1
    800054c0:	8ab2                	mv	s5,a2
    800054c2:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054c4:	fb040593          	addi	a1,s0,-80
    800054c8:	fffff097          	auipc	ra,0xfffff
    800054cc:	e86080e7          	jalr	-378(ra) # 8000434e <nameiparent>
    800054d0:	892a                	mv	s2,a0
    800054d2:	12050f63          	beqz	a0,80005610 <create+0x164>
    return 0;

  ilock(dp);
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	6a4080e7          	jalr	1700(ra) # 80003b7a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054de:	4601                	li	a2,0
    800054e0:	fb040593          	addi	a1,s0,-80
    800054e4:	854a                	mv	a0,s2
    800054e6:	fffff097          	auipc	ra,0xfffff
    800054ea:	b78080e7          	jalr	-1160(ra) # 8000405e <dirlookup>
    800054ee:	84aa                	mv	s1,a0
    800054f0:	c921                	beqz	a0,80005540 <create+0x94>
    iunlockput(dp);
    800054f2:	854a                	mv	a0,s2
    800054f4:	fffff097          	auipc	ra,0xfffff
    800054f8:	8e8080e7          	jalr	-1816(ra) # 80003ddc <iunlockput>
    ilock(ip);
    800054fc:	8526                	mv	a0,s1
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	67c080e7          	jalr	1660(ra) # 80003b7a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005506:	2981                	sext.w	s3,s3
    80005508:	4789                	li	a5,2
    8000550a:	02f99463          	bne	s3,a5,80005532 <create+0x86>
    8000550e:	0444d783          	lhu	a5,68(s1)
    80005512:	37f9                	addiw	a5,a5,-2
    80005514:	17c2                	slli	a5,a5,0x30
    80005516:	93c1                	srli	a5,a5,0x30
    80005518:	4705                	li	a4,1
    8000551a:	00f76c63          	bltu	a4,a5,80005532 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000551e:	8526                	mv	a0,s1
    80005520:	60a6                	ld	ra,72(sp)
    80005522:	6406                	ld	s0,64(sp)
    80005524:	74e2                	ld	s1,56(sp)
    80005526:	7942                	ld	s2,48(sp)
    80005528:	79a2                	ld	s3,40(sp)
    8000552a:	7a02                	ld	s4,32(sp)
    8000552c:	6ae2                	ld	s5,24(sp)
    8000552e:	6161                	addi	sp,sp,80
    80005530:	8082                	ret
    iunlockput(ip);
    80005532:	8526                	mv	a0,s1
    80005534:	fffff097          	auipc	ra,0xfffff
    80005538:	8a8080e7          	jalr	-1880(ra) # 80003ddc <iunlockput>
    return 0;
    8000553c:	4481                	li	s1,0
    8000553e:	b7c5                	j	8000551e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005540:	85ce                	mv	a1,s3
    80005542:	00092503          	lw	a0,0(s2)
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	49c080e7          	jalr	1180(ra) # 800039e2 <ialloc>
    8000554e:	84aa                	mv	s1,a0
    80005550:	c529                	beqz	a0,8000559a <create+0xee>
  ilock(ip);
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	628080e7          	jalr	1576(ra) # 80003b7a <ilock>
  ip->major = major;
    8000555a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000555e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005562:	4785                	li	a5,1
    80005564:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005568:	8526                	mv	a0,s1
    8000556a:	ffffe097          	auipc	ra,0xffffe
    8000556e:	546080e7          	jalr	1350(ra) # 80003ab0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005572:	2981                	sext.w	s3,s3
    80005574:	4785                	li	a5,1
    80005576:	02f98a63          	beq	s3,a5,800055aa <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000557a:	40d0                	lw	a2,4(s1)
    8000557c:	fb040593          	addi	a1,s0,-80
    80005580:	854a                	mv	a0,s2
    80005582:	fffff097          	auipc	ra,0xfffff
    80005586:	cec080e7          	jalr	-788(ra) # 8000426e <dirlink>
    8000558a:	06054b63          	bltz	a0,80005600 <create+0x154>
  iunlockput(dp);
    8000558e:	854a                	mv	a0,s2
    80005590:	fffff097          	auipc	ra,0xfffff
    80005594:	84c080e7          	jalr	-1972(ra) # 80003ddc <iunlockput>
  return ip;
    80005598:	b759                	j	8000551e <create+0x72>
    panic("create: ialloc");
    8000559a:	00003517          	auipc	a0,0x3
    8000559e:	1d650513          	addi	a0,a0,470 # 80008770 <syscalls+0x2a0>
    800055a2:	ffffb097          	auipc	ra,0xffffb
    800055a6:	f9c080e7          	jalr	-100(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800055aa:	04a95783          	lhu	a5,74(s2)
    800055ae:	2785                	addiw	a5,a5,1
    800055b0:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800055b4:	854a                	mv	a0,s2
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	4fa080e7          	jalr	1274(ra) # 80003ab0 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055be:	40d0                	lw	a2,4(s1)
    800055c0:	00003597          	auipc	a1,0x3
    800055c4:	1c058593          	addi	a1,a1,448 # 80008780 <syscalls+0x2b0>
    800055c8:	8526                	mv	a0,s1
    800055ca:	fffff097          	auipc	ra,0xfffff
    800055ce:	ca4080e7          	jalr	-860(ra) # 8000426e <dirlink>
    800055d2:	00054f63          	bltz	a0,800055f0 <create+0x144>
    800055d6:	00492603          	lw	a2,4(s2)
    800055da:	00003597          	auipc	a1,0x3
    800055de:	1ae58593          	addi	a1,a1,430 # 80008788 <syscalls+0x2b8>
    800055e2:	8526                	mv	a0,s1
    800055e4:	fffff097          	auipc	ra,0xfffff
    800055e8:	c8a080e7          	jalr	-886(ra) # 8000426e <dirlink>
    800055ec:	f80557e3          	bgez	a0,8000557a <create+0xce>
      panic("create dots");
    800055f0:	00003517          	auipc	a0,0x3
    800055f4:	1a050513          	addi	a0,a0,416 # 80008790 <syscalls+0x2c0>
    800055f8:	ffffb097          	auipc	ra,0xffffb
    800055fc:	f46080e7          	jalr	-186(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005600:	00003517          	auipc	a0,0x3
    80005604:	1a050513          	addi	a0,a0,416 # 800087a0 <syscalls+0x2d0>
    80005608:	ffffb097          	auipc	ra,0xffffb
    8000560c:	f36080e7          	jalr	-202(ra) # 8000053e <panic>
    return 0;
    80005610:	84aa                	mv	s1,a0
    80005612:	b731                	j	8000551e <create+0x72>

0000000080005614 <sys_dup>:
{
    80005614:	7179                	addi	sp,sp,-48
    80005616:	f406                	sd	ra,40(sp)
    80005618:	f022                	sd	s0,32(sp)
    8000561a:	ec26                	sd	s1,24(sp)
    8000561c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000561e:	fd840613          	addi	a2,s0,-40
    80005622:	4581                	li	a1,0
    80005624:	4501                	li	a0,0
    80005626:	00000097          	auipc	ra,0x0
    8000562a:	ddc080e7          	jalr	-548(ra) # 80005402 <argfd>
    return -1;
    8000562e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005630:	02054363          	bltz	a0,80005656 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005634:	fd843503          	ld	a0,-40(s0)
    80005638:	00000097          	auipc	ra,0x0
    8000563c:	e32080e7          	jalr	-462(ra) # 8000546a <fdalloc>
    80005640:	84aa                	mv	s1,a0
    return -1;
    80005642:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005644:	00054963          	bltz	a0,80005656 <sys_dup+0x42>
  filedup(f);
    80005648:	fd843503          	ld	a0,-40(s0)
    8000564c:	fffff097          	auipc	ra,0xfffff
    80005650:	37a080e7          	jalr	890(ra) # 800049c6 <filedup>
  return fd;
    80005654:	87a6                	mv	a5,s1
}
    80005656:	853e                	mv	a0,a5
    80005658:	70a2                	ld	ra,40(sp)
    8000565a:	7402                	ld	s0,32(sp)
    8000565c:	64e2                	ld	s1,24(sp)
    8000565e:	6145                	addi	sp,sp,48
    80005660:	8082                	ret

0000000080005662 <sys_read>:
{
    80005662:	7179                	addi	sp,sp,-48
    80005664:	f406                	sd	ra,40(sp)
    80005666:	f022                	sd	s0,32(sp)
    80005668:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000566a:	fe840613          	addi	a2,s0,-24
    8000566e:	4581                	li	a1,0
    80005670:	4501                	li	a0,0
    80005672:	00000097          	auipc	ra,0x0
    80005676:	d90080e7          	jalr	-624(ra) # 80005402 <argfd>
    return -1;
    8000567a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000567c:	04054163          	bltz	a0,800056be <sys_read+0x5c>
    80005680:	fe440593          	addi	a1,s0,-28
    80005684:	4509                	li	a0,2
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	982080e7          	jalr	-1662(ra) # 80003008 <argint>
    return -1;
    8000568e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005690:	02054763          	bltz	a0,800056be <sys_read+0x5c>
    80005694:	fd840593          	addi	a1,s0,-40
    80005698:	4505                	li	a0,1
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	990080e7          	jalr	-1648(ra) # 8000302a <argaddr>
    return -1;
    800056a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056a4:	00054d63          	bltz	a0,800056be <sys_read+0x5c>
  return fileread(f, p, n);
    800056a8:	fe442603          	lw	a2,-28(s0)
    800056ac:	fd843583          	ld	a1,-40(s0)
    800056b0:	fe843503          	ld	a0,-24(s0)
    800056b4:	fffff097          	auipc	ra,0xfffff
    800056b8:	49e080e7          	jalr	1182(ra) # 80004b52 <fileread>
    800056bc:	87aa                	mv	a5,a0
}
    800056be:	853e                	mv	a0,a5
    800056c0:	70a2                	ld	ra,40(sp)
    800056c2:	7402                	ld	s0,32(sp)
    800056c4:	6145                	addi	sp,sp,48
    800056c6:	8082                	ret

00000000800056c8 <sys_write>:
{
    800056c8:	7179                	addi	sp,sp,-48
    800056ca:	f406                	sd	ra,40(sp)
    800056cc:	f022                	sd	s0,32(sp)
    800056ce:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056d0:	fe840613          	addi	a2,s0,-24
    800056d4:	4581                	li	a1,0
    800056d6:	4501                	li	a0,0
    800056d8:	00000097          	auipc	ra,0x0
    800056dc:	d2a080e7          	jalr	-726(ra) # 80005402 <argfd>
    return -1;
    800056e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056e2:	04054163          	bltz	a0,80005724 <sys_write+0x5c>
    800056e6:	fe440593          	addi	a1,s0,-28
    800056ea:	4509                	li	a0,2
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	91c080e7          	jalr	-1764(ra) # 80003008 <argint>
    return -1;
    800056f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056f6:	02054763          	bltz	a0,80005724 <sys_write+0x5c>
    800056fa:	fd840593          	addi	a1,s0,-40
    800056fe:	4505                	li	a0,1
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	92a080e7          	jalr	-1750(ra) # 8000302a <argaddr>
    return -1;
    80005708:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000570a:	00054d63          	bltz	a0,80005724 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000570e:	fe442603          	lw	a2,-28(s0)
    80005712:	fd843583          	ld	a1,-40(s0)
    80005716:	fe843503          	ld	a0,-24(s0)
    8000571a:	fffff097          	auipc	ra,0xfffff
    8000571e:	4fa080e7          	jalr	1274(ra) # 80004c14 <filewrite>
    80005722:	87aa                	mv	a5,a0
}
    80005724:	853e                	mv	a0,a5
    80005726:	70a2                	ld	ra,40(sp)
    80005728:	7402                	ld	s0,32(sp)
    8000572a:	6145                	addi	sp,sp,48
    8000572c:	8082                	ret

000000008000572e <sys_close>:
{
    8000572e:	1101                	addi	sp,sp,-32
    80005730:	ec06                	sd	ra,24(sp)
    80005732:	e822                	sd	s0,16(sp)
    80005734:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005736:	fe040613          	addi	a2,s0,-32
    8000573a:	fec40593          	addi	a1,s0,-20
    8000573e:	4501                	li	a0,0
    80005740:	00000097          	auipc	ra,0x0
    80005744:	cc2080e7          	jalr	-830(ra) # 80005402 <argfd>
    return -1;
    80005748:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000574a:	02054463          	bltz	a0,80005772 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000574e:	ffffc097          	auipc	ra,0xffffc
    80005752:	580080e7          	jalr	1408(ra) # 80001cce <myproc>
    80005756:	fec42783          	lw	a5,-20(s0)
    8000575a:	07e9                	addi	a5,a5,26
    8000575c:	078e                	slli	a5,a5,0x3
    8000575e:	97aa                	add	a5,a5,a0
    80005760:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005764:	fe043503          	ld	a0,-32(s0)
    80005768:	fffff097          	auipc	ra,0xfffff
    8000576c:	2b0080e7          	jalr	688(ra) # 80004a18 <fileclose>
  return 0;
    80005770:	4781                	li	a5,0
}
    80005772:	853e                	mv	a0,a5
    80005774:	60e2                	ld	ra,24(sp)
    80005776:	6442                	ld	s0,16(sp)
    80005778:	6105                	addi	sp,sp,32
    8000577a:	8082                	ret

000000008000577c <sys_fstat>:
{
    8000577c:	1101                	addi	sp,sp,-32
    8000577e:	ec06                	sd	ra,24(sp)
    80005780:	e822                	sd	s0,16(sp)
    80005782:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005784:	fe840613          	addi	a2,s0,-24
    80005788:	4581                	li	a1,0
    8000578a:	4501                	li	a0,0
    8000578c:	00000097          	auipc	ra,0x0
    80005790:	c76080e7          	jalr	-906(ra) # 80005402 <argfd>
    return -1;
    80005794:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005796:	02054563          	bltz	a0,800057c0 <sys_fstat+0x44>
    8000579a:	fe040593          	addi	a1,s0,-32
    8000579e:	4505                	li	a0,1
    800057a0:	ffffe097          	auipc	ra,0xffffe
    800057a4:	88a080e7          	jalr	-1910(ra) # 8000302a <argaddr>
    return -1;
    800057a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057aa:	00054b63          	bltz	a0,800057c0 <sys_fstat+0x44>
  return filestat(f, st);
    800057ae:	fe043583          	ld	a1,-32(s0)
    800057b2:	fe843503          	ld	a0,-24(s0)
    800057b6:	fffff097          	auipc	ra,0xfffff
    800057ba:	32a080e7          	jalr	810(ra) # 80004ae0 <filestat>
    800057be:	87aa                	mv	a5,a0
}
    800057c0:	853e                	mv	a0,a5
    800057c2:	60e2                	ld	ra,24(sp)
    800057c4:	6442                	ld	s0,16(sp)
    800057c6:	6105                	addi	sp,sp,32
    800057c8:	8082                	ret

00000000800057ca <sys_link>:
{
    800057ca:	7169                	addi	sp,sp,-304
    800057cc:	f606                	sd	ra,296(sp)
    800057ce:	f222                	sd	s0,288(sp)
    800057d0:	ee26                	sd	s1,280(sp)
    800057d2:	ea4a                	sd	s2,272(sp)
    800057d4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057d6:	08000613          	li	a2,128
    800057da:	ed040593          	addi	a1,s0,-304
    800057de:	4501                	li	a0,0
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	86c080e7          	jalr	-1940(ra) # 8000304c <argstr>
    return -1;
    800057e8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057ea:	10054e63          	bltz	a0,80005906 <sys_link+0x13c>
    800057ee:	08000613          	li	a2,128
    800057f2:	f5040593          	addi	a1,s0,-176
    800057f6:	4505                	li	a0,1
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	854080e7          	jalr	-1964(ra) # 8000304c <argstr>
    return -1;
    80005800:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005802:	10054263          	bltz	a0,80005906 <sys_link+0x13c>
  begin_op();
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	d46080e7          	jalr	-698(ra) # 8000454c <begin_op>
  if((ip = namei(old)) == 0){
    8000580e:	ed040513          	addi	a0,s0,-304
    80005812:	fffff097          	auipc	ra,0xfffff
    80005816:	b1e080e7          	jalr	-1250(ra) # 80004330 <namei>
    8000581a:	84aa                	mv	s1,a0
    8000581c:	c551                	beqz	a0,800058a8 <sys_link+0xde>
  ilock(ip);
    8000581e:	ffffe097          	auipc	ra,0xffffe
    80005822:	35c080e7          	jalr	860(ra) # 80003b7a <ilock>
  if(ip->type == T_DIR){
    80005826:	04449703          	lh	a4,68(s1)
    8000582a:	4785                	li	a5,1
    8000582c:	08f70463          	beq	a4,a5,800058b4 <sys_link+0xea>
  ip->nlink++;
    80005830:	04a4d783          	lhu	a5,74(s1)
    80005834:	2785                	addiw	a5,a5,1
    80005836:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000583a:	8526                	mv	a0,s1
    8000583c:	ffffe097          	auipc	ra,0xffffe
    80005840:	274080e7          	jalr	628(ra) # 80003ab0 <iupdate>
  iunlock(ip);
    80005844:	8526                	mv	a0,s1
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	3f6080e7          	jalr	1014(ra) # 80003c3c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000584e:	fd040593          	addi	a1,s0,-48
    80005852:	f5040513          	addi	a0,s0,-176
    80005856:	fffff097          	auipc	ra,0xfffff
    8000585a:	af8080e7          	jalr	-1288(ra) # 8000434e <nameiparent>
    8000585e:	892a                	mv	s2,a0
    80005860:	c935                	beqz	a0,800058d4 <sys_link+0x10a>
  ilock(dp);
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	318080e7          	jalr	792(ra) # 80003b7a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000586a:	00092703          	lw	a4,0(s2)
    8000586e:	409c                	lw	a5,0(s1)
    80005870:	04f71d63          	bne	a4,a5,800058ca <sys_link+0x100>
    80005874:	40d0                	lw	a2,4(s1)
    80005876:	fd040593          	addi	a1,s0,-48
    8000587a:	854a                	mv	a0,s2
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	9f2080e7          	jalr	-1550(ra) # 8000426e <dirlink>
    80005884:	04054363          	bltz	a0,800058ca <sys_link+0x100>
  iunlockput(dp);
    80005888:	854a                	mv	a0,s2
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	552080e7          	jalr	1362(ra) # 80003ddc <iunlockput>
  iput(ip);
    80005892:	8526                	mv	a0,s1
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	4a0080e7          	jalr	1184(ra) # 80003d34 <iput>
  end_op();
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	d30080e7          	jalr	-720(ra) # 800045cc <end_op>
  return 0;
    800058a4:	4781                	li	a5,0
    800058a6:	a085                	j	80005906 <sys_link+0x13c>
    end_op();
    800058a8:	fffff097          	auipc	ra,0xfffff
    800058ac:	d24080e7          	jalr	-732(ra) # 800045cc <end_op>
    return -1;
    800058b0:	57fd                	li	a5,-1
    800058b2:	a891                	j	80005906 <sys_link+0x13c>
    iunlockput(ip);
    800058b4:	8526                	mv	a0,s1
    800058b6:	ffffe097          	auipc	ra,0xffffe
    800058ba:	526080e7          	jalr	1318(ra) # 80003ddc <iunlockput>
    end_op();
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	d0e080e7          	jalr	-754(ra) # 800045cc <end_op>
    return -1;
    800058c6:	57fd                	li	a5,-1
    800058c8:	a83d                	j	80005906 <sys_link+0x13c>
    iunlockput(dp);
    800058ca:	854a                	mv	a0,s2
    800058cc:	ffffe097          	auipc	ra,0xffffe
    800058d0:	510080e7          	jalr	1296(ra) # 80003ddc <iunlockput>
  ilock(ip);
    800058d4:	8526                	mv	a0,s1
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	2a4080e7          	jalr	676(ra) # 80003b7a <ilock>
  ip->nlink--;
    800058de:	04a4d783          	lhu	a5,74(s1)
    800058e2:	37fd                	addiw	a5,a5,-1
    800058e4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058e8:	8526                	mv	a0,s1
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	1c6080e7          	jalr	454(ra) # 80003ab0 <iupdate>
  iunlockput(ip);
    800058f2:	8526                	mv	a0,s1
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	4e8080e7          	jalr	1256(ra) # 80003ddc <iunlockput>
  end_op();
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	cd0080e7          	jalr	-816(ra) # 800045cc <end_op>
  return -1;
    80005904:	57fd                	li	a5,-1
}
    80005906:	853e                	mv	a0,a5
    80005908:	70b2                	ld	ra,296(sp)
    8000590a:	7412                	ld	s0,288(sp)
    8000590c:	64f2                	ld	s1,280(sp)
    8000590e:	6952                	ld	s2,272(sp)
    80005910:	6155                	addi	sp,sp,304
    80005912:	8082                	ret

0000000080005914 <sys_unlink>:
{
    80005914:	7151                	addi	sp,sp,-240
    80005916:	f586                	sd	ra,232(sp)
    80005918:	f1a2                	sd	s0,224(sp)
    8000591a:	eda6                	sd	s1,216(sp)
    8000591c:	e9ca                	sd	s2,208(sp)
    8000591e:	e5ce                	sd	s3,200(sp)
    80005920:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005922:	08000613          	li	a2,128
    80005926:	f3040593          	addi	a1,s0,-208
    8000592a:	4501                	li	a0,0
    8000592c:	ffffd097          	auipc	ra,0xffffd
    80005930:	720080e7          	jalr	1824(ra) # 8000304c <argstr>
    80005934:	18054163          	bltz	a0,80005ab6 <sys_unlink+0x1a2>
  begin_op();
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	c14080e7          	jalr	-1004(ra) # 8000454c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005940:	fb040593          	addi	a1,s0,-80
    80005944:	f3040513          	addi	a0,s0,-208
    80005948:	fffff097          	auipc	ra,0xfffff
    8000594c:	a06080e7          	jalr	-1530(ra) # 8000434e <nameiparent>
    80005950:	84aa                	mv	s1,a0
    80005952:	c979                	beqz	a0,80005a28 <sys_unlink+0x114>
  ilock(dp);
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	226080e7          	jalr	550(ra) # 80003b7a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000595c:	00003597          	auipc	a1,0x3
    80005960:	e2458593          	addi	a1,a1,-476 # 80008780 <syscalls+0x2b0>
    80005964:	fb040513          	addi	a0,s0,-80
    80005968:	ffffe097          	auipc	ra,0xffffe
    8000596c:	6dc080e7          	jalr	1756(ra) # 80004044 <namecmp>
    80005970:	14050a63          	beqz	a0,80005ac4 <sys_unlink+0x1b0>
    80005974:	00003597          	auipc	a1,0x3
    80005978:	e1458593          	addi	a1,a1,-492 # 80008788 <syscalls+0x2b8>
    8000597c:	fb040513          	addi	a0,s0,-80
    80005980:	ffffe097          	auipc	ra,0xffffe
    80005984:	6c4080e7          	jalr	1732(ra) # 80004044 <namecmp>
    80005988:	12050e63          	beqz	a0,80005ac4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000598c:	f2c40613          	addi	a2,s0,-212
    80005990:	fb040593          	addi	a1,s0,-80
    80005994:	8526                	mv	a0,s1
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	6c8080e7          	jalr	1736(ra) # 8000405e <dirlookup>
    8000599e:	892a                	mv	s2,a0
    800059a0:	12050263          	beqz	a0,80005ac4 <sys_unlink+0x1b0>
  ilock(ip);
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	1d6080e7          	jalr	470(ra) # 80003b7a <ilock>
  if(ip->nlink < 1)
    800059ac:	04a91783          	lh	a5,74(s2)
    800059b0:	08f05263          	blez	a5,80005a34 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059b4:	04491703          	lh	a4,68(s2)
    800059b8:	4785                	li	a5,1
    800059ba:	08f70563          	beq	a4,a5,80005a44 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800059be:	4641                	li	a2,16
    800059c0:	4581                	li	a1,0
    800059c2:	fc040513          	addi	a0,s0,-64
    800059c6:	ffffb097          	auipc	ra,0xffffb
    800059ca:	31a080e7          	jalr	794(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059ce:	4741                	li	a4,16
    800059d0:	f2c42683          	lw	a3,-212(s0)
    800059d4:	fc040613          	addi	a2,s0,-64
    800059d8:	4581                	li	a1,0
    800059da:	8526                	mv	a0,s1
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	54a080e7          	jalr	1354(ra) # 80003f26 <writei>
    800059e4:	47c1                	li	a5,16
    800059e6:	0af51563          	bne	a0,a5,80005a90 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059ea:	04491703          	lh	a4,68(s2)
    800059ee:	4785                	li	a5,1
    800059f0:	0af70863          	beq	a4,a5,80005aa0 <sys_unlink+0x18c>
  iunlockput(dp);
    800059f4:	8526                	mv	a0,s1
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	3e6080e7          	jalr	998(ra) # 80003ddc <iunlockput>
  ip->nlink--;
    800059fe:	04a95783          	lhu	a5,74(s2)
    80005a02:	37fd                	addiw	a5,a5,-1
    80005a04:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a08:	854a                	mv	a0,s2
    80005a0a:	ffffe097          	auipc	ra,0xffffe
    80005a0e:	0a6080e7          	jalr	166(ra) # 80003ab0 <iupdate>
  iunlockput(ip);
    80005a12:	854a                	mv	a0,s2
    80005a14:	ffffe097          	auipc	ra,0xffffe
    80005a18:	3c8080e7          	jalr	968(ra) # 80003ddc <iunlockput>
  end_op();
    80005a1c:	fffff097          	auipc	ra,0xfffff
    80005a20:	bb0080e7          	jalr	-1104(ra) # 800045cc <end_op>
  return 0;
    80005a24:	4501                	li	a0,0
    80005a26:	a84d                	j	80005ad8 <sys_unlink+0x1c4>
    end_op();
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	ba4080e7          	jalr	-1116(ra) # 800045cc <end_op>
    return -1;
    80005a30:	557d                	li	a0,-1
    80005a32:	a05d                	j	80005ad8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a34:	00003517          	auipc	a0,0x3
    80005a38:	d7c50513          	addi	a0,a0,-644 # 800087b0 <syscalls+0x2e0>
    80005a3c:	ffffb097          	auipc	ra,0xffffb
    80005a40:	b02080e7          	jalr	-1278(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a44:	04c92703          	lw	a4,76(s2)
    80005a48:	02000793          	li	a5,32
    80005a4c:	f6e7f9e3          	bgeu	a5,a4,800059be <sys_unlink+0xaa>
    80005a50:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a54:	4741                	li	a4,16
    80005a56:	86ce                	mv	a3,s3
    80005a58:	f1840613          	addi	a2,s0,-232
    80005a5c:	4581                	li	a1,0
    80005a5e:	854a                	mv	a0,s2
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	3ce080e7          	jalr	974(ra) # 80003e2e <readi>
    80005a68:	47c1                	li	a5,16
    80005a6a:	00f51b63          	bne	a0,a5,80005a80 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a6e:	f1845783          	lhu	a5,-232(s0)
    80005a72:	e7a1                	bnez	a5,80005aba <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a74:	29c1                	addiw	s3,s3,16
    80005a76:	04c92783          	lw	a5,76(s2)
    80005a7a:	fcf9ede3          	bltu	s3,a5,80005a54 <sys_unlink+0x140>
    80005a7e:	b781                	j	800059be <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a80:	00003517          	auipc	a0,0x3
    80005a84:	d4850513          	addi	a0,a0,-696 # 800087c8 <syscalls+0x2f8>
    80005a88:	ffffb097          	auipc	ra,0xffffb
    80005a8c:	ab6080e7          	jalr	-1354(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005a90:	00003517          	auipc	a0,0x3
    80005a94:	d5050513          	addi	a0,a0,-688 # 800087e0 <syscalls+0x310>
    80005a98:	ffffb097          	auipc	ra,0xffffb
    80005a9c:	aa6080e7          	jalr	-1370(ra) # 8000053e <panic>
    dp->nlink--;
    80005aa0:	04a4d783          	lhu	a5,74(s1)
    80005aa4:	37fd                	addiw	a5,a5,-1
    80005aa6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005aaa:	8526                	mv	a0,s1
    80005aac:	ffffe097          	auipc	ra,0xffffe
    80005ab0:	004080e7          	jalr	4(ra) # 80003ab0 <iupdate>
    80005ab4:	b781                	j	800059f4 <sys_unlink+0xe0>
    return -1;
    80005ab6:	557d                	li	a0,-1
    80005ab8:	a005                	j	80005ad8 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005aba:	854a                	mv	a0,s2
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	320080e7          	jalr	800(ra) # 80003ddc <iunlockput>
  iunlockput(dp);
    80005ac4:	8526                	mv	a0,s1
    80005ac6:	ffffe097          	auipc	ra,0xffffe
    80005aca:	316080e7          	jalr	790(ra) # 80003ddc <iunlockput>
  end_op();
    80005ace:	fffff097          	auipc	ra,0xfffff
    80005ad2:	afe080e7          	jalr	-1282(ra) # 800045cc <end_op>
  return -1;
    80005ad6:	557d                	li	a0,-1
}
    80005ad8:	70ae                	ld	ra,232(sp)
    80005ada:	740e                	ld	s0,224(sp)
    80005adc:	64ee                	ld	s1,216(sp)
    80005ade:	694e                	ld	s2,208(sp)
    80005ae0:	69ae                	ld	s3,200(sp)
    80005ae2:	616d                	addi	sp,sp,240
    80005ae4:	8082                	ret

0000000080005ae6 <sys_open>:

uint64
sys_open(void)
{
    80005ae6:	7131                	addi	sp,sp,-192
    80005ae8:	fd06                	sd	ra,184(sp)
    80005aea:	f922                	sd	s0,176(sp)
    80005aec:	f526                	sd	s1,168(sp)
    80005aee:	f14a                	sd	s2,160(sp)
    80005af0:	ed4e                	sd	s3,152(sp)
    80005af2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005af4:	08000613          	li	a2,128
    80005af8:	f5040593          	addi	a1,s0,-176
    80005afc:	4501                	li	a0,0
    80005afe:	ffffd097          	auipc	ra,0xffffd
    80005b02:	54e080e7          	jalr	1358(ra) # 8000304c <argstr>
    return -1;
    80005b06:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b08:	0c054163          	bltz	a0,80005bca <sys_open+0xe4>
    80005b0c:	f4c40593          	addi	a1,s0,-180
    80005b10:	4505                	li	a0,1
    80005b12:	ffffd097          	auipc	ra,0xffffd
    80005b16:	4f6080e7          	jalr	1270(ra) # 80003008 <argint>
    80005b1a:	0a054863          	bltz	a0,80005bca <sys_open+0xe4>

  begin_op();
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	a2e080e7          	jalr	-1490(ra) # 8000454c <begin_op>

  if(omode & O_CREATE){
    80005b26:	f4c42783          	lw	a5,-180(s0)
    80005b2a:	2007f793          	andi	a5,a5,512
    80005b2e:	cbdd                	beqz	a5,80005be4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b30:	4681                	li	a3,0
    80005b32:	4601                	li	a2,0
    80005b34:	4589                	li	a1,2
    80005b36:	f5040513          	addi	a0,s0,-176
    80005b3a:	00000097          	auipc	ra,0x0
    80005b3e:	972080e7          	jalr	-1678(ra) # 800054ac <create>
    80005b42:	892a                	mv	s2,a0
    if(ip == 0){
    80005b44:	c959                	beqz	a0,80005bda <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b46:	04491703          	lh	a4,68(s2)
    80005b4a:	478d                	li	a5,3
    80005b4c:	00f71763          	bne	a4,a5,80005b5a <sys_open+0x74>
    80005b50:	04695703          	lhu	a4,70(s2)
    80005b54:	47a5                	li	a5,9
    80005b56:	0ce7ec63          	bltu	a5,a4,80005c2e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b5a:	fffff097          	auipc	ra,0xfffff
    80005b5e:	e02080e7          	jalr	-510(ra) # 8000495c <filealloc>
    80005b62:	89aa                	mv	s3,a0
    80005b64:	10050263          	beqz	a0,80005c68 <sys_open+0x182>
    80005b68:	00000097          	auipc	ra,0x0
    80005b6c:	902080e7          	jalr	-1790(ra) # 8000546a <fdalloc>
    80005b70:	84aa                	mv	s1,a0
    80005b72:	0e054663          	bltz	a0,80005c5e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b76:	04491703          	lh	a4,68(s2)
    80005b7a:	478d                	li	a5,3
    80005b7c:	0cf70463          	beq	a4,a5,80005c44 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b80:	4789                	li	a5,2
    80005b82:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b86:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b8a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b8e:	f4c42783          	lw	a5,-180(s0)
    80005b92:	0017c713          	xori	a4,a5,1
    80005b96:	8b05                	andi	a4,a4,1
    80005b98:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b9c:	0037f713          	andi	a4,a5,3
    80005ba0:	00e03733          	snez	a4,a4
    80005ba4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005ba8:	4007f793          	andi	a5,a5,1024
    80005bac:	c791                	beqz	a5,80005bb8 <sys_open+0xd2>
    80005bae:	04491703          	lh	a4,68(s2)
    80005bb2:	4789                	li	a5,2
    80005bb4:	08f70f63          	beq	a4,a5,80005c52 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005bb8:	854a                	mv	a0,s2
    80005bba:	ffffe097          	auipc	ra,0xffffe
    80005bbe:	082080e7          	jalr	130(ra) # 80003c3c <iunlock>
  end_op();
    80005bc2:	fffff097          	auipc	ra,0xfffff
    80005bc6:	a0a080e7          	jalr	-1526(ra) # 800045cc <end_op>

  return fd;
}
    80005bca:	8526                	mv	a0,s1
    80005bcc:	70ea                	ld	ra,184(sp)
    80005bce:	744a                	ld	s0,176(sp)
    80005bd0:	74aa                	ld	s1,168(sp)
    80005bd2:	790a                	ld	s2,160(sp)
    80005bd4:	69ea                	ld	s3,152(sp)
    80005bd6:	6129                	addi	sp,sp,192
    80005bd8:	8082                	ret
      end_op();
    80005bda:	fffff097          	auipc	ra,0xfffff
    80005bde:	9f2080e7          	jalr	-1550(ra) # 800045cc <end_op>
      return -1;
    80005be2:	b7e5                	j	80005bca <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005be4:	f5040513          	addi	a0,s0,-176
    80005be8:	ffffe097          	auipc	ra,0xffffe
    80005bec:	748080e7          	jalr	1864(ra) # 80004330 <namei>
    80005bf0:	892a                	mv	s2,a0
    80005bf2:	c905                	beqz	a0,80005c22 <sys_open+0x13c>
    ilock(ip);
    80005bf4:	ffffe097          	auipc	ra,0xffffe
    80005bf8:	f86080e7          	jalr	-122(ra) # 80003b7a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005bfc:	04491703          	lh	a4,68(s2)
    80005c00:	4785                	li	a5,1
    80005c02:	f4f712e3          	bne	a4,a5,80005b46 <sys_open+0x60>
    80005c06:	f4c42783          	lw	a5,-180(s0)
    80005c0a:	dba1                	beqz	a5,80005b5a <sys_open+0x74>
      iunlockput(ip);
    80005c0c:	854a                	mv	a0,s2
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	1ce080e7          	jalr	462(ra) # 80003ddc <iunlockput>
      end_op();
    80005c16:	fffff097          	auipc	ra,0xfffff
    80005c1a:	9b6080e7          	jalr	-1610(ra) # 800045cc <end_op>
      return -1;
    80005c1e:	54fd                	li	s1,-1
    80005c20:	b76d                	j	80005bca <sys_open+0xe4>
      end_op();
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	9aa080e7          	jalr	-1622(ra) # 800045cc <end_op>
      return -1;
    80005c2a:	54fd                	li	s1,-1
    80005c2c:	bf79                	j	80005bca <sys_open+0xe4>
    iunlockput(ip);
    80005c2e:	854a                	mv	a0,s2
    80005c30:	ffffe097          	auipc	ra,0xffffe
    80005c34:	1ac080e7          	jalr	428(ra) # 80003ddc <iunlockput>
    end_op();
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	994080e7          	jalr	-1644(ra) # 800045cc <end_op>
    return -1;
    80005c40:	54fd                	li	s1,-1
    80005c42:	b761                	j	80005bca <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c44:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c48:	04691783          	lh	a5,70(s2)
    80005c4c:	02f99223          	sh	a5,36(s3)
    80005c50:	bf2d                	j	80005b8a <sys_open+0xa4>
    itrunc(ip);
    80005c52:	854a                	mv	a0,s2
    80005c54:	ffffe097          	auipc	ra,0xffffe
    80005c58:	034080e7          	jalr	52(ra) # 80003c88 <itrunc>
    80005c5c:	bfb1                	j	80005bb8 <sys_open+0xd2>
      fileclose(f);
    80005c5e:	854e                	mv	a0,s3
    80005c60:	fffff097          	auipc	ra,0xfffff
    80005c64:	db8080e7          	jalr	-584(ra) # 80004a18 <fileclose>
    iunlockput(ip);
    80005c68:	854a                	mv	a0,s2
    80005c6a:	ffffe097          	auipc	ra,0xffffe
    80005c6e:	172080e7          	jalr	370(ra) # 80003ddc <iunlockput>
    end_op();
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	95a080e7          	jalr	-1702(ra) # 800045cc <end_op>
    return -1;
    80005c7a:	54fd                	li	s1,-1
    80005c7c:	b7b9                	j	80005bca <sys_open+0xe4>

0000000080005c7e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c7e:	7175                	addi	sp,sp,-144
    80005c80:	e506                	sd	ra,136(sp)
    80005c82:	e122                	sd	s0,128(sp)
    80005c84:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c86:	fffff097          	auipc	ra,0xfffff
    80005c8a:	8c6080e7          	jalr	-1850(ra) # 8000454c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c8e:	08000613          	li	a2,128
    80005c92:	f7040593          	addi	a1,s0,-144
    80005c96:	4501                	li	a0,0
    80005c98:	ffffd097          	auipc	ra,0xffffd
    80005c9c:	3b4080e7          	jalr	948(ra) # 8000304c <argstr>
    80005ca0:	02054963          	bltz	a0,80005cd2 <sys_mkdir+0x54>
    80005ca4:	4681                	li	a3,0
    80005ca6:	4601                	li	a2,0
    80005ca8:	4585                	li	a1,1
    80005caa:	f7040513          	addi	a0,s0,-144
    80005cae:	fffff097          	auipc	ra,0xfffff
    80005cb2:	7fe080e7          	jalr	2046(ra) # 800054ac <create>
    80005cb6:	cd11                	beqz	a0,80005cd2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cb8:	ffffe097          	auipc	ra,0xffffe
    80005cbc:	124080e7          	jalr	292(ra) # 80003ddc <iunlockput>
  end_op();
    80005cc0:	fffff097          	auipc	ra,0xfffff
    80005cc4:	90c080e7          	jalr	-1780(ra) # 800045cc <end_op>
  return 0;
    80005cc8:	4501                	li	a0,0
}
    80005cca:	60aa                	ld	ra,136(sp)
    80005ccc:	640a                	ld	s0,128(sp)
    80005cce:	6149                	addi	sp,sp,144
    80005cd0:	8082                	ret
    end_op();
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	8fa080e7          	jalr	-1798(ra) # 800045cc <end_op>
    return -1;
    80005cda:	557d                	li	a0,-1
    80005cdc:	b7fd                	j	80005cca <sys_mkdir+0x4c>

0000000080005cde <sys_mknod>:

uint64
sys_mknod(void)
{
    80005cde:	7135                	addi	sp,sp,-160
    80005ce0:	ed06                	sd	ra,152(sp)
    80005ce2:	e922                	sd	s0,144(sp)
    80005ce4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	866080e7          	jalr	-1946(ra) # 8000454c <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cee:	08000613          	li	a2,128
    80005cf2:	f7040593          	addi	a1,s0,-144
    80005cf6:	4501                	li	a0,0
    80005cf8:	ffffd097          	auipc	ra,0xffffd
    80005cfc:	354080e7          	jalr	852(ra) # 8000304c <argstr>
    80005d00:	04054a63          	bltz	a0,80005d54 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d04:	f6c40593          	addi	a1,s0,-148
    80005d08:	4505                	li	a0,1
    80005d0a:	ffffd097          	auipc	ra,0xffffd
    80005d0e:	2fe080e7          	jalr	766(ra) # 80003008 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d12:	04054163          	bltz	a0,80005d54 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d16:	f6840593          	addi	a1,s0,-152
    80005d1a:	4509                	li	a0,2
    80005d1c:	ffffd097          	auipc	ra,0xffffd
    80005d20:	2ec080e7          	jalr	748(ra) # 80003008 <argint>
     argint(1, &major) < 0 ||
    80005d24:	02054863          	bltz	a0,80005d54 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d28:	f6841683          	lh	a3,-152(s0)
    80005d2c:	f6c41603          	lh	a2,-148(s0)
    80005d30:	458d                	li	a1,3
    80005d32:	f7040513          	addi	a0,s0,-144
    80005d36:	fffff097          	auipc	ra,0xfffff
    80005d3a:	776080e7          	jalr	1910(ra) # 800054ac <create>
     argint(2, &minor) < 0 ||
    80005d3e:	c919                	beqz	a0,80005d54 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d40:	ffffe097          	auipc	ra,0xffffe
    80005d44:	09c080e7          	jalr	156(ra) # 80003ddc <iunlockput>
  end_op();
    80005d48:	fffff097          	auipc	ra,0xfffff
    80005d4c:	884080e7          	jalr	-1916(ra) # 800045cc <end_op>
  return 0;
    80005d50:	4501                	li	a0,0
    80005d52:	a031                	j	80005d5e <sys_mknod+0x80>
    end_op();
    80005d54:	fffff097          	auipc	ra,0xfffff
    80005d58:	878080e7          	jalr	-1928(ra) # 800045cc <end_op>
    return -1;
    80005d5c:	557d                	li	a0,-1
}
    80005d5e:	60ea                	ld	ra,152(sp)
    80005d60:	644a                	ld	s0,144(sp)
    80005d62:	610d                	addi	sp,sp,160
    80005d64:	8082                	ret

0000000080005d66 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d66:	7135                	addi	sp,sp,-160
    80005d68:	ed06                	sd	ra,152(sp)
    80005d6a:	e922                	sd	s0,144(sp)
    80005d6c:	e526                	sd	s1,136(sp)
    80005d6e:	e14a                	sd	s2,128(sp)
    80005d70:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d72:	ffffc097          	auipc	ra,0xffffc
    80005d76:	f5c080e7          	jalr	-164(ra) # 80001cce <myproc>
    80005d7a:	892a                	mv	s2,a0
  
  begin_op();
    80005d7c:	ffffe097          	auipc	ra,0xffffe
    80005d80:	7d0080e7          	jalr	2000(ra) # 8000454c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d84:	08000613          	li	a2,128
    80005d88:	f6040593          	addi	a1,s0,-160
    80005d8c:	4501                	li	a0,0
    80005d8e:	ffffd097          	auipc	ra,0xffffd
    80005d92:	2be080e7          	jalr	702(ra) # 8000304c <argstr>
    80005d96:	04054b63          	bltz	a0,80005dec <sys_chdir+0x86>
    80005d9a:	f6040513          	addi	a0,s0,-160
    80005d9e:	ffffe097          	auipc	ra,0xffffe
    80005da2:	592080e7          	jalr	1426(ra) # 80004330 <namei>
    80005da6:	84aa                	mv	s1,a0
    80005da8:	c131                	beqz	a0,80005dec <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005daa:	ffffe097          	auipc	ra,0xffffe
    80005dae:	dd0080e7          	jalr	-560(ra) # 80003b7a <ilock>
  if(ip->type != T_DIR){
    80005db2:	04449703          	lh	a4,68(s1)
    80005db6:	4785                	li	a5,1
    80005db8:	04f71063          	bne	a4,a5,80005df8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005dbc:	8526                	mv	a0,s1
    80005dbe:	ffffe097          	auipc	ra,0xffffe
    80005dc2:	e7e080e7          	jalr	-386(ra) # 80003c3c <iunlock>
  iput(p->cwd);
    80005dc6:	15093503          	ld	a0,336(s2)
    80005dca:	ffffe097          	auipc	ra,0xffffe
    80005dce:	f6a080e7          	jalr	-150(ra) # 80003d34 <iput>
  end_op();
    80005dd2:	ffffe097          	auipc	ra,0xffffe
    80005dd6:	7fa080e7          	jalr	2042(ra) # 800045cc <end_op>
  p->cwd = ip;
    80005dda:	14993823          	sd	s1,336(s2)
  return 0;
    80005dde:	4501                	li	a0,0
}
    80005de0:	60ea                	ld	ra,152(sp)
    80005de2:	644a                	ld	s0,144(sp)
    80005de4:	64aa                	ld	s1,136(sp)
    80005de6:	690a                	ld	s2,128(sp)
    80005de8:	610d                	addi	sp,sp,160
    80005dea:	8082                	ret
    end_op();
    80005dec:	ffffe097          	auipc	ra,0xffffe
    80005df0:	7e0080e7          	jalr	2016(ra) # 800045cc <end_op>
    return -1;
    80005df4:	557d                	li	a0,-1
    80005df6:	b7ed                	j	80005de0 <sys_chdir+0x7a>
    iunlockput(ip);
    80005df8:	8526                	mv	a0,s1
    80005dfa:	ffffe097          	auipc	ra,0xffffe
    80005dfe:	fe2080e7          	jalr	-30(ra) # 80003ddc <iunlockput>
    end_op();
    80005e02:	ffffe097          	auipc	ra,0xffffe
    80005e06:	7ca080e7          	jalr	1994(ra) # 800045cc <end_op>
    return -1;
    80005e0a:	557d                	li	a0,-1
    80005e0c:	bfd1                	j	80005de0 <sys_chdir+0x7a>

0000000080005e0e <sys_exec>:

uint64
sys_exec(void)
{
    80005e0e:	7145                	addi	sp,sp,-464
    80005e10:	e786                	sd	ra,456(sp)
    80005e12:	e3a2                	sd	s0,448(sp)
    80005e14:	ff26                	sd	s1,440(sp)
    80005e16:	fb4a                	sd	s2,432(sp)
    80005e18:	f74e                	sd	s3,424(sp)
    80005e1a:	f352                	sd	s4,416(sp)
    80005e1c:	ef56                	sd	s5,408(sp)
    80005e1e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e20:	08000613          	li	a2,128
    80005e24:	f4040593          	addi	a1,s0,-192
    80005e28:	4501                	li	a0,0
    80005e2a:	ffffd097          	auipc	ra,0xffffd
    80005e2e:	222080e7          	jalr	546(ra) # 8000304c <argstr>
    return -1;
    80005e32:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e34:	0c054a63          	bltz	a0,80005f08 <sys_exec+0xfa>
    80005e38:	e3840593          	addi	a1,s0,-456
    80005e3c:	4505                	li	a0,1
    80005e3e:	ffffd097          	auipc	ra,0xffffd
    80005e42:	1ec080e7          	jalr	492(ra) # 8000302a <argaddr>
    80005e46:	0c054163          	bltz	a0,80005f08 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e4a:	10000613          	li	a2,256
    80005e4e:	4581                	li	a1,0
    80005e50:	e4040513          	addi	a0,s0,-448
    80005e54:	ffffb097          	auipc	ra,0xffffb
    80005e58:	e8c080e7          	jalr	-372(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e5c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e60:	89a6                	mv	s3,s1
    80005e62:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e64:	02000a13          	li	s4,32
    80005e68:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e6c:	00391513          	slli	a0,s2,0x3
    80005e70:	e3040593          	addi	a1,s0,-464
    80005e74:	e3843783          	ld	a5,-456(s0)
    80005e78:	953e                	add	a0,a0,a5
    80005e7a:	ffffd097          	auipc	ra,0xffffd
    80005e7e:	0f4080e7          	jalr	244(ra) # 80002f6e <fetchaddr>
    80005e82:	02054a63          	bltz	a0,80005eb6 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e86:	e3043783          	ld	a5,-464(s0)
    80005e8a:	c3b9                	beqz	a5,80005ed0 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e8c:	ffffb097          	auipc	ra,0xffffb
    80005e90:	c68080e7          	jalr	-920(ra) # 80000af4 <kalloc>
    80005e94:	85aa                	mv	a1,a0
    80005e96:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e9a:	cd11                	beqz	a0,80005eb6 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e9c:	6605                	lui	a2,0x1
    80005e9e:	e3043503          	ld	a0,-464(s0)
    80005ea2:	ffffd097          	auipc	ra,0xffffd
    80005ea6:	11e080e7          	jalr	286(ra) # 80002fc0 <fetchstr>
    80005eaa:	00054663          	bltz	a0,80005eb6 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005eae:	0905                	addi	s2,s2,1
    80005eb0:	09a1                	addi	s3,s3,8
    80005eb2:	fb491be3          	bne	s2,s4,80005e68 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eb6:	10048913          	addi	s2,s1,256
    80005eba:	6088                	ld	a0,0(s1)
    80005ebc:	c529                	beqz	a0,80005f06 <sys_exec+0xf8>
    kfree(argv[i]);
    80005ebe:	ffffb097          	auipc	ra,0xffffb
    80005ec2:	b3a080e7          	jalr	-1222(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ec6:	04a1                	addi	s1,s1,8
    80005ec8:	ff2499e3          	bne	s1,s2,80005eba <sys_exec+0xac>
  return -1;
    80005ecc:	597d                	li	s2,-1
    80005ece:	a82d                	j	80005f08 <sys_exec+0xfa>
      argv[i] = 0;
    80005ed0:	0a8e                	slli	s5,s5,0x3
    80005ed2:	fc040793          	addi	a5,s0,-64
    80005ed6:	9abe                	add	s5,s5,a5
    80005ed8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005edc:	e4040593          	addi	a1,s0,-448
    80005ee0:	f4040513          	addi	a0,s0,-192
    80005ee4:	fffff097          	auipc	ra,0xfffff
    80005ee8:	194080e7          	jalr	404(ra) # 80005078 <exec>
    80005eec:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eee:	10048993          	addi	s3,s1,256
    80005ef2:	6088                	ld	a0,0(s1)
    80005ef4:	c911                	beqz	a0,80005f08 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ef6:	ffffb097          	auipc	ra,0xffffb
    80005efa:	b02080e7          	jalr	-1278(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005efe:	04a1                	addi	s1,s1,8
    80005f00:	ff3499e3          	bne	s1,s3,80005ef2 <sys_exec+0xe4>
    80005f04:	a011                	j	80005f08 <sys_exec+0xfa>
  return -1;
    80005f06:	597d                	li	s2,-1
}
    80005f08:	854a                	mv	a0,s2
    80005f0a:	60be                	ld	ra,456(sp)
    80005f0c:	641e                	ld	s0,448(sp)
    80005f0e:	74fa                	ld	s1,440(sp)
    80005f10:	795a                	ld	s2,432(sp)
    80005f12:	79ba                	ld	s3,424(sp)
    80005f14:	7a1a                	ld	s4,416(sp)
    80005f16:	6afa                	ld	s5,408(sp)
    80005f18:	6179                	addi	sp,sp,464
    80005f1a:	8082                	ret

0000000080005f1c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f1c:	7139                	addi	sp,sp,-64
    80005f1e:	fc06                	sd	ra,56(sp)
    80005f20:	f822                	sd	s0,48(sp)
    80005f22:	f426                	sd	s1,40(sp)
    80005f24:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f26:	ffffc097          	auipc	ra,0xffffc
    80005f2a:	da8080e7          	jalr	-600(ra) # 80001cce <myproc>
    80005f2e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f30:	fd840593          	addi	a1,s0,-40
    80005f34:	4501                	li	a0,0
    80005f36:	ffffd097          	auipc	ra,0xffffd
    80005f3a:	0f4080e7          	jalr	244(ra) # 8000302a <argaddr>
    return -1;
    80005f3e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f40:	0e054063          	bltz	a0,80006020 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f44:	fc840593          	addi	a1,s0,-56
    80005f48:	fd040513          	addi	a0,s0,-48
    80005f4c:	fffff097          	auipc	ra,0xfffff
    80005f50:	dfc080e7          	jalr	-516(ra) # 80004d48 <pipealloc>
    return -1;
    80005f54:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f56:	0c054563          	bltz	a0,80006020 <sys_pipe+0x104>
  fd0 = -1;
    80005f5a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f5e:	fd043503          	ld	a0,-48(s0)
    80005f62:	fffff097          	auipc	ra,0xfffff
    80005f66:	508080e7          	jalr	1288(ra) # 8000546a <fdalloc>
    80005f6a:	fca42223          	sw	a0,-60(s0)
    80005f6e:	08054c63          	bltz	a0,80006006 <sys_pipe+0xea>
    80005f72:	fc843503          	ld	a0,-56(s0)
    80005f76:	fffff097          	auipc	ra,0xfffff
    80005f7a:	4f4080e7          	jalr	1268(ra) # 8000546a <fdalloc>
    80005f7e:	fca42023          	sw	a0,-64(s0)
    80005f82:	06054863          	bltz	a0,80005ff2 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f86:	4691                	li	a3,4
    80005f88:	fc440613          	addi	a2,s0,-60
    80005f8c:	fd843583          	ld	a1,-40(s0)
    80005f90:	68a8                	ld	a0,80(s1)
    80005f92:	ffffb097          	auipc	ra,0xffffb
    80005f96:	6e0080e7          	jalr	1760(ra) # 80001672 <copyout>
    80005f9a:	02054063          	bltz	a0,80005fba <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f9e:	4691                	li	a3,4
    80005fa0:	fc040613          	addi	a2,s0,-64
    80005fa4:	fd843583          	ld	a1,-40(s0)
    80005fa8:	0591                	addi	a1,a1,4
    80005faa:	68a8                	ld	a0,80(s1)
    80005fac:	ffffb097          	auipc	ra,0xffffb
    80005fb0:	6c6080e7          	jalr	1734(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fb4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fb6:	06055563          	bgez	a0,80006020 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005fba:	fc442783          	lw	a5,-60(s0)
    80005fbe:	07e9                	addi	a5,a5,26
    80005fc0:	078e                	slli	a5,a5,0x3
    80005fc2:	97a6                	add	a5,a5,s1
    80005fc4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005fc8:	fc042503          	lw	a0,-64(s0)
    80005fcc:	0569                	addi	a0,a0,26
    80005fce:	050e                	slli	a0,a0,0x3
    80005fd0:	9526                	add	a0,a0,s1
    80005fd2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005fd6:	fd043503          	ld	a0,-48(s0)
    80005fda:	fffff097          	auipc	ra,0xfffff
    80005fde:	a3e080e7          	jalr	-1474(ra) # 80004a18 <fileclose>
    fileclose(wf);
    80005fe2:	fc843503          	ld	a0,-56(s0)
    80005fe6:	fffff097          	auipc	ra,0xfffff
    80005fea:	a32080e7          	jalr	-1486(ra) # 80004a18 <fileclose>
    return -1;
    80005fee:	57fd                	li	a5,-1
    80005ff0:	a805                	j	80006020 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005ff2:	fc442783          	lw	a5,-60(s0)
    80005ff6:	0007c863          	bltz	a5,80006006 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005ffa:	01a78513          	addi	a0,a5,26
    80005ffe:	050e                	slli	a0,a0,0x3
    80006000:	9526                	add	a0,a0,s1
    80006002:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006006:	fd043503          	ld	a0,-48(s0)
    8000600a:	fffff097          	auipc	ra,0xfffff
    8000600e:	a0e080e7          	jalr	-1522(ra) # 80004a18 <fileclose>
    fileclose(wf);
    80006012:	fc843503          	ld	a0,-56(s0)
    80006016:	fffff097          	auipc	ra,0xfffff
    8000601a:	a02080e7          	jalr	-1534(ra) # 80004a18 <fileclose>
    return -1;
    8000601e:	57fd                	li	a5,-1
}
    80006020:	853e                	mv	a0,a5
    80006022:	70e2                	ld	ra,56(sp)
    80006024:	7442                	ld	s0,48(sp)
    80006026:	74a2                	ld	s1,40(sp)
    80006028:	6121                	addi	sp,sp,64
    8000602a:	8082                	ret
    8000602c:	0000                	unimp
	...

0000000080006030 <kernelvec>:
    80006030:	7111                	addi	sp,sp,-256
    80006032:	e006                	sd	ra,0(sp)
    80006034:	e40a                	sd	sp,8(sp)
    80006036:	e80e                	sd	gp,16(sp)
    80006038:	ec12                	sd	tp,24(sp)
    8000603a:	f016                	sd	t0,32(sp)
    8000603c:	f41a                	sd	t1,40(sp)
    8000603e:	f81e                	sd	t2,48(sp)
    80006040:	fc22                	sd	s0,56(sp)
    80006042:	e0a6                	sd	s1,64(sp)
    80006044:	e4aa                	sd	a0,72(sp)
    80006046:	e8ae                	sd	a1,80(sp)
    80006048:	ecb2                	sd	a2,88(sp)
    8000604a:	f0b6                	sd	a3,96(sp)
    8000604c:	f4ba                	sd	a4,104(sp)
    8000604e:	f8be                	sd	a5,112(sp)
    80006050:	fcc2                	sd	a6,120(sp)
    80006052:	e146                	sd	a7,128(sp)
    80006054:	e54a                	sd	s2,136(sp)
    80006056:	e94e                	sd	s3,144(sp)
    80006058:	ed52                	sd	s4,152(sp)
    8000605a:	f156                	sd	s5,160(sp)
    8000605c:	f55a                	sd	s6,168(sp)
    8000605e:	f95e                	sd	s7,176(sp)
    80006060:	fd62                	sd	s8,184(sp)
    80006062:	e1e6                	sd	s9,192(sp)
    80006064:	e5ea                	sd	s10,200(sp)
    80006066:	e9ee                	sd	s11,208(sp)
    80006068:	edf2                	sd	t3,216(sp)
    8000606a:	f1f6                	sd	t4,224(sp)
    8000606c:	f5fa                	sd	t5,232(sp)
    8000606e:	f9fe                	sd	t6,240(sp)
    80006070:	dcbfc0ef          	jal	ra,80002e3a <kerneltrap>
    80006074:	6082                	ld	ra,0(sp)
    80006076:	6122                	ld	sp,8(sp)
    80006078:	61c2                	ld	gp,16(sp)
    8000607a:	7282                	ld	t0,32(sp)
    8000607c:	7322                	ld	t1,40(sp)
    8000607e:	73c2                	ld	t2,48(sp)
    80006080:	7462                	ld	s0,56(sp)
    80006082:	6486                	ld	s1,64(sp)
    80006084:	6526                	ld	a0,72(sp)
    80006086:	65c6                	ld	a1,80(sp)
    80006088:	6666                	ld	a2,88(sp)
    8000608a:	7686                	ld	a3,96(sp)
    8000608c:	7726                	ld	a4,104(sp)
    8000608e:	77c6                	ld	a5,112(sp)
    80006090:	7866                	ld	a6,120(sp)
    80006092:	688a                	ld	a7,128(sp)
    80006094:	692a                	ld	s2,136(sp)
    80006096:	69ca                	ld	s3,144(sp)
    80006098:	6a6a                	ld	s4,152(sp)
    8000609a:	7a8a                	ld	s5,160(sp)
    8000609c:	7b2a                	ld	s6,168(sp)
    8000609e:	7bca                	ld	s7,176(sp)
    800060a0:	7c6a                	ld	s8,184(sp)
    800060a2:	6c8e                	ld	s9,192(sp)
    800060a4:	6d2e                	ld	s10,200(sp)
    800060a6:	6dce                	ld	s11,208(sp)
    800060a8:	6e6e                	ld	t3,216(sp)
    800060aa:	7e8e                	ld	t4,224(sp)
    800060ac:	7f2e                	ld	t5,232(sp)
    800060ae:	7fce                	ld	t6,240(sp)
    800060b0:	6111                	addi	sp,sp,256
    800060b2:	10200073          	sret
    800060b6:	00000013          	nop
    800060ba:	00000013          	nop
    800060be:	0001                	nop

00000000800060c0 <timervec>:
    800060c0:	34051573          	csrrw	a0,mscratch,a0
    800060c4:	e10c                	sd	a1,0(a0)
    800060c6:	e510                	sd	a2,8(a0)
    800060c8:	e914                	sd	a3,16(a0)
    800060ca:	6d0c                	ld	a1,24(a0)
    800060cc:	7110                	ld	a2,32(a0)
    800060ce:	6194                	ld	a3,0(a1)
    800060d0:	96b2                	add	a3,a3,a2
    800060d2:	e194                	sd	a3,0(a1)
    800060d4:	4589                	li	a1,2
    800060d6:	14459073          	csrw	sip,a1
    800060da:	6914                	ld	a3,16(a0)
    800060dc:	6510                	ld	a2,8(a0)
    800060de:	610c                	ld	a1,0(a0)
    800060e0:	34051573          	csrrw	a0,mscratch,a0
    800060e4:	30200073          	mret
	...

00000000800060ea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060ea:	1141                	addi	sp,sp,-16
    800060ec:	e422                	sd	s0,8(sp)
    800060ee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060f0:	0c0007b7          	lui	a5,0xc000
    800060f4:	4705                	li	a4,1
    800060f6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060f8:	c3d8                	sw	a4,4(a5)
}
    800060fa:	6422                	ld	s0,8(sp)
    800060fc:	0141                	addi	sp,sp,16
    800060fe:	8082                	ret

0000000080006100 <plicinithart>:

void
plicinithart(void)
{
    80006100:	1141                	addi	sp,sp,-16
    80006102:	e406                	sd	ra,8(sp)
    80006104:	e022                	sd	s0,0(sp)
    80006106:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006108:	ffffc097          	auipc	ra,0xffffc
    8000610c:	b94080e7          	jalr	-1132(ra) # 80001c9c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006110:	0085171b          	slliw	a4,a0,0x8
    80006114:	0c0027b7          	lui	a5,0xc002
    80006118:	97ba                	add	a5,a5,a4
    8000611a:	40200713          	li	a4,1026
    8000611e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006122:	00d5151b          	slliw	a0,a0,0xd
    80006126:	0c2017b7          	lui	a5,0xc201
    8000612a:	953e                	add	a0,a0,a5
    8000612c:	00052023          	sw	zero,0(a0)
}
    80006130:	60a2                	ld	ra,8(sp)
    80006132:	6402                	ld	s0,0(sp)
    80006134:	0141                	addi	sp,sp,16
    80006136:	8082                	ret

0000000080006138 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006138:	1141                	addi	sp,sp,-16
    8000613a:	e406                	sd	ra,8(sp)
    8000613c:	e022                	sd	s0,0(sp)
    8000613e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006140:	ffffc097          	auipc	ra,0xffffc
    80006144:	b5c080e7          	jalr	-1188(ra) # 80001c9c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006148:	00d5179b          	slliw	a5,a0,0xd
    8000614c:	0c201537          	lui	a0,0xc201
    80006150:	953e                	add	a0,a0,a5
  return irq;
}
    80006152:	4148                	lw	a0,4(a0)
    80006154:	60a2                	ld	ra,8(sp)
    80006156:	6402                	ld	s0,0(sp)
    80006158:	0141                	addi	sp,sp,16
    8000615a:	8082                	ret

000000008000615c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000615c:	1101                	addi	sp,sp,-32
    8000615e:	ec06                	sd	ra,24(sp)
    80006160:	e822                	sd	s0,16(sp)
    80006162:	e426                	sd	s1,8(sp)
    80006164:	1000                	addi	s0,sp,32
    80006166:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006168:	ffffc097          	auipc	ra,0xffffc
    8000616c:	b34080e7          	jalr	-1228(ra) # 80001c9c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006170:	00d5151b          	slliw	a0,a0,0xd
    80006174:	0c2017b7          	lui	a5,0xc201
    80006178:	97aa                	add	a5,a5,a0
    8000617a:	c3c4                	sw	s1,4(a5)
}
    8000617c:	60e2                	ld	ra,24(sp)
    8000617e:	6442                	ld	s0,16(sp)
    80006180:	64a2                	ld	s1,8(sp)
    80006182:	6105                	addi	sp,sp,32
    80006184:	8082                	ret

0000000080006186 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006186:	1141                	addi	sp,sp,-16
    80006188:	e406                	sd	ra,8(sp)
    8000618a:	e022                	sd	s0,0(sp)
    8000618c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000618e:	479d                	li	a5,7
    80006190:	06a7c963          	blt	a5,a0,80006202 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006194:	0001d797          	auipc	a5,0x1d
    80006198:	e6c78793          	addi	a5,a5,-404 # 80023000 <disk>
    8000619c:	00a78733          	add	a4,a5,a0
    800061a0:	6789                	lui	a5,0x2
    800061a2:	97ba                	add	a5,a5,a4
    800061a4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800061a8:	e7ad                	bnez	a5,80006212 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061aa:	00451793          	slli	a5,a0,0x4
    800061ae:	0001f717          	auipc	a4,0x1f
    800061b2:	e5270713          	addi	a4,a4,-430 # 80025000 <disk+0x2000>
    800061b6:	6314                	ld	a3,0(a4)
    800061b8:	96be                	add	a3,a3,a5
    800061ba:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800061be:	6314                	ld	a3,0(a4)
    800061c0:	96be                	add	a3,a3,a5
    800061c2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800061c6:	6314                	ld	a3,0(a4)
    800061c8:	96be                	add	a3,a3,a5
    800061ca:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800061ce:	6318                	ld	a4,0(a4)
    800061d0:	97ba                	add	a5,a5,a4
    800061d2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800061d6:	0001d797          	auipc	a5,0x1d
    800061da:	e2a78793          	addi	a5,a5,-470 # 80023000 <disk>
    800061de:	97aa                	add	a5,a5,a0
    800061e0:	6509                	lui	a0,0x2
    800061e2:	953e                	add	a0,a0,a5
    800061e4:	4785                	li	a5,1
    800061e6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800061ea:	0001f517          	auipc	a0,0x1f
    800061ee:	e2e50513          	addi	a0,a0,-466 # 80025018 <disk+0x2018>
    800061f2:	ffffc097          	auipc	ra,0xffffc
    800061f6:	47a080e7          	jalr	1146(ra) # 8000266c <wakeup>
}
    800061fa:	60a2                	ld	ra,8(sp)
    800061fc:	6402                	ld	s0,0(sp)
    800061fe:	0141                	addi	sp,sp,16
    80006200:	8082                	ret
    panic("free_desc 1");
    80006202:	00002517          	auipc	a0,0x2
    80006206:	5ee50513          	addi	a0,a0,1518 # 800087f0 <syscalls+0x320>
    8000620a:	ffffa097          	auipc	ra,0xffffa
    8000620e:	334080e7          	jalr	820(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006212:	00002517          	auipc	a0,0x2
    80006216:	5ee50513          	addi	a0,a0,1518 # 80008800 <syscalls+0x330>
    8000621a:	ffffa097          	auipc	ra,0xffffa
    8000621e:	324080e7          	jalr	804(ra) # 8000053e <panic>

0000000080006222 <virtio_disk_init>:
{
    80006222:	1101                	addi	sp,sp,-32
    80006224:	ec06                	sd	ra,24(sp)
    80006226:	e822                	sd	s0,16(sp)
    80006228:	e426                	sd	s1,8(sp)
    8000622a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000622c:	00002597          	auipc	a1,0x2
    80006230:	5e458593          	addi	a1,a1,1508 # 80008810 <syscalls+0x340>
    80006234:	0001f517          	auipc	a0,0x1f
    80006238:	ef450513          	addi	a0,a0,-268 # 80025128 <disk+0x2128>
    8000623c:	ffffb097          	auipc	ra,0xffffb
    80006240:	918080e7          	jalr	-1768(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006244:	100017b7          	lui	a5,0x10001
    80006248:	4398                	lw	a4,0(a5)
    8000624a:	2701                	sext.w	a4,a4
    8000624c:	747277b7          	lui	a5,0x74727
    80006250:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006254:	0ef71163          	bne	a4,a5,80006336 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006258:	100017b7          	lui	a5,0x10001
    8000625c:	43dc                	lw	a5,4(a5)
    8000625e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006260:	4705                	li	a4,1
    80006262:	0ce79a63          	bne	a5,a4,80006336 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006266:	100017b7          	lui	a5,0x10001
    8000626a:	479c                	lw	a5,8(a5)
    8000626c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000626e:	4709                	li	a4,2
    80006270:	0ce79363          	bne	a5,a4,80006336 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006274:	100017b7          	lui	a5,0x10001
    80006278:	47d8                	lw	a4,12(a5)
    8000627a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000627c:	554d47b7          	lui	a5,0x554d4
    80006280:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006284:	0af71963          	bne	a4,a5,80006336 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006288:	100017b7          	lui	a5,0x10001
    8000628c:	4705                	li	a4,1
    8000628e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006290:	470d                	li	a4,3
    80006292:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006294:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006296:	c7ffe737          	lui	a4,0xc7ffe
    8000629a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000629e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800062a0:	2701                	sext.w	a4,a4
    800062a2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062a4:	472d                	li	a4,11
    800062a6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062a8:	473d                	li	a4,15
    800062aa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800062ac:	6705                	lui	a4,0x1
    800062ae:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800062b0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062b4:	5bdc                	lw	a5,52(a5)
    800062b6:	2781                	sext.w	a5,a5
  if(max == 0)
    800062b8:	c7d9                	beqz	a5,80006346 <virtio_disk_init+0x124>
  if(max < NUM)
    800062ba:	471d                	li	a4,7
    800062bc:	08f77d63          	bgeu	a4,a5,80006356 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062c0:	100014b7          	lui	s1,0x10001
    800062c4:	47a1                	li	a5,8
    800062c6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800062c8:	6609                	lui	a2,0x2
    800062ca:	4581                	li	a1,0
    800062cc:	0001d517          	auipc	a0,0x1d
    800062d0:	d3450513          	addi	a0,a0,-716 # 80023000 <disk>
    800062d4:	ffffb097          	auipc	ra,0xffffb
    800062d8:	a0c080e7          	jalr	-1524(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800062dc:	0001d717          	auipc	a4,0x1d
    800062e0:	d2470713          	addi	a4,a4,-732 # 80023000 <disk>
    800062e4:	00c75793          	srli	a5,a4,0xc
    800062e8:	2781                	sext.w	a5,a5
    800062ea:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800062ec:	0001f797          	auipc	a5,0x1f
    800062f0:	d1478793          	addi	a5,a5,-748 # 80025000 <disk+0x2000>
    800062f4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800062f6:	0001d717          	auipc	a4,0x1d
    800062fa:	d8a70713          	addi	a4,a4,-630 # 80023080 <disk+0x80>
    800062fe:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006300:	0001e717          	auipc	a4,0x1e
    80006304:	d0070713          	addi	a4,a4,-768 # 80024000 <disk+0x1000>
    80006308:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000630a:	4705                	li	a4,1
    8000630c:	00e78c23          	sb	a4,24(a5)
    80006310:	00e78ca3          	sb	a4,25(a5)
    80006314:	00e78d23          	sb	a4,26(a5)
    80006318:	00e78da3          	sb	a4,27(a5)
    8000631c:	00e78e23          	sb	a4,28(a5)
    80006320:	00e78ea3          	sb	a4,29(a5)
    80006324:	00e78f23          	sb	a4,30(a5)
    80006328:	00e78fa3          	sb	a4,31(a5)
}
    8000632c:	60e2                	ld	ra,24(sp)
    8000632e:	6442                	ld	s0,16(sp)
    80006330:	64a2                	ld	s1,8(sp)
    80006332:	6105                	addi	sp,sp,32
    80006334:	8082                	ret
    panic("could not find virtio disk");
    80006336:	00002517          	auipc	a0,0x2
    8000633a:	4ea50513          	addi	a0,a0,1258 # 80008820 <syscalls+0x350>
    8000633e:	ffffa097          	auipc	ra,0xffffa
    80006342:	200080e7          	jalr	512(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006346:	00002517          	auipc	a0,0x2
    8000634a:	4fa50513          	addi	a0,a0,1274 # 80008840 <syscalls+0x370>
    8000634e:	ffffa097          	auipc	ra,0xffffa
    80006352:	1f0080e7          	jalr	496(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006356:	00002517          	auipc	a0,0x2
    8000635a:	50a50513          	addi	a0,a0,1290 # 80008860 <syscalls+0x390>
    8000635e:	ffffa097          	auipc	ra,0xffffa
    80006362:	1e0080e7          	jalr	480(ra) # 8000053e <panic>

0000000080006366 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006366:	7159                	addi	sp,sp,-112
    80006368:	f486                	sd	ra,104(sp)
    8000636a:	f0a2                	sd	s0,96(sp)
    8000636c:	eca6                	sd	s1,88(sp)
    8000636e:	e8ca                	sd	s2,80(sp)
    80006370:	e4ce                	sd	s3,72(sp)
    80006372:	e0d2                	sd	s4,64(sp)
    80006374:	fc56                	sd	s5,56(sp)
    80006376:	f85a                	sd	s6,48(sp)
    80006378:	f45e                	sd	s7,40(sp)
    8000637a:	f062                	sd	s8,32(sp)
    8000637c:	ec66                	sd	s9,24(sp)
    8000637e:	e86a                	sd	s10,16(sp)
    80006380:	1880                	addi	s0,sp,112
    80006382:	892a                	mv	s2,a0
    80006384:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006386:	00c52c83          	lw	s9,12(a0)
    8000638a:	001c9c9b          	slliw	s9,s9,0x1
    8000638e:	1c82                	slli	s9,s9,0x20
    80006390:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006394:	0001f517          	auipc	a0,0x1f
    80006398:	d9450513          	addi	a0,a0,-620 # 80025128 <disk+0x2128>
    8000639c:	ffffb097          	auipc	ra,0xffffb
    800063a0:	848080e7          	jalr	-1976(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800063a4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800063a6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800063a8:	0001db97          	auipc	s7,0x1d
    800063ac:	c58b8b93          	addi	s7,s7,-936 # 80023000 <disk>
    800063b0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800063b2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800063b4:	8a4e                	mv	s4,s3
    800063b6:	a051                	j	8000643a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800063b8:	00fb86b3          	add	a3,s7,a5
    800063bc:	96da                	add	a3,a3,s6
    800063be:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800063c2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800063c4:	0207c563          	bltz	a5,800063ee <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800063c8:	2485                	addiw	s1,s1,1
    800063ca:	0711                	addi	a4,a4,4
    800063cc:	25548063          	beq	s1,s5,8000660c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800063d0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800063d2:	0001f697          	auipc	a3,0x1f
    800063d6:	c4668693          	addi	a3,a3,-954 # 80025018 <disk+0x2018>
    800063da:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800063dc:	0006c583          	lbu	a1,0(a3)
    800063e0:	fde1                	bnez	a1,800063b8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800063e2:	2785                	addiw	a5,a5,1
    800063e4:	0685                	addi	a3,a3,1
    800063e6:	ff879be3          	bne	a5,s8,800063dc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800063ea:	57fd                	li	a5,-1
    800063ec:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800063ee:	02905a63          	blez	s1,80006422 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063f2:	f9042503          	lw	a0,-112(s0)
    800063f6:	00000097          	auipc	ra,0x0
    800063fa:	d90080e7          	jalr	-624(ra) # 80006186 <free_desc>
      for(int j = 0; j < i; j++)
    800063fe:	4785                	li	a5,1
    80006400:	0297d163          	bge	a5,s1,80006422 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006404:	f9442503          	lw	a0,-108(s0)
    80006408:	00000097          	auipc	ra,0x0
    8000640c:	d7e080e7          	jalr	-642(ra) # 80006186 <free_desc>
      for(int j = 0; j < i; j++)
    80006410:	4789                	li	a5,2
    80006412:	0097d863          	bge	a5,s1,80006422 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006416:	f9842503          	lw	a0,-104(s0)
    8000641a:	00000097          	auipc	ra,0x0
    8000641e:	d6c080e7          	jalr	-660(ra) # 80006186 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006422:	0001f597          	auipc	a1,0x1f
    80006426:	d0658593          	addi	a1,a1,-762 # 80025128 <disk+0x2128>
    8000642a:	0001f517          	auipc	a0,0x1f
    8000642e:	bee50513          	addi	a0,a0,-1042 # 80025018 <disk+0x2018>
    80006432:	ffffc097          	auipc	ra,0xffffc
    80006436:	09c080e7          	jalr	156(ra) # 800024ce <sleep>
  for(int i = 0; i < 3; i++){
    8000643a:	f9040713          	addi	a4,s0,-112
    8000643e:	84ce                	mv	s1,s3
    80006440:	bf41                	j	800063d0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006442:	20058713          	addi	a4,a1,512
    80006446:	00471693          	slli	a3,a4,0x4
    8000644a:	0001d717          	auipc	a4,0x1d
    8000644e:	bb670713          	addi	a4,a4,-1098 # 80023000 <disk>
    80006452:	9736                	add	a4,a4,a3
    80006454:	4685                	li	a3,1
    80006456:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000645a:	20058713          	addi	a4,a1,512
    8000645e:	00471693          	slli	a3,a4,0x4
    80006462:	0001d717          	auipc	a4,0x1d
    80006466:	b9e70713          	addi	a4,a4,-1122 # 80023000 <disk>
    8000646a:	9736                	add	a4,a4,a3
    8000646c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006470:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006474:	7679                	lui	a2,0xffffe
    80006476:	963e                	add	a2,a2,a5
    80006478:	0001f697          	auipc	a3,0x1f
    8000647c:	b8868693          	addi	a3,a3,-1144 # 80025000 <disk+0x2000>
    80006480:	6298                	ld	a4,0(a3)
    80006482:	9732                	add	a4,a4,a2
    80006484:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006486:	6298                	ld	a4,0(a3)
    80006488:	9732                	add	a4,a4,a2
    8000648a:	4541                	li	a0,16
    8000648c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000648e:	6298                	ld	a4,0(a3)
    80006490:	9732                	add	a4,a4,a2
    80006492:	4505                	li	a0,1
    80006494:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006498:	f9442703          	lw	a4,-108(s0)
    8000649c:	6288                	ld	a0,0(a3)
    8000649e:	962a                	add	a2,a2,a0
    800064a0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800064a4:	0712                	slli	a4,a4,0x4
    800064a6:	6290                	ld	a2,0(a3)
    800064a8:	963a                	add	a2,a2,a4
    800064aa:	05890513          	addi	a0,s2,88
    800064ae:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800064b0:	6294                	ld	a3,0(a3)
    800064b2:	96ba                	add	a3,a3,a4
    800064b4:	40000613          	li	a2,1024
    800064b8:	c690                	sw	a2,8(a3)
  if(write)
    800064ba:	140d0063          	beqz	s10,800065fa <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800064be:	0001f697          	auipc	a3,0x1f
    800064c2:	b426b683          	ld	a3,-1214(a3) # 80025000 <disk+0x2000>
    800064c6:	96ba                	add	a3,a3,a4
    800064c8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064cc:	0001d817          	auipc	a6,0x1d
    800064d0:	b3480813          	addi	a6,a6,-1228 # 80023000 <disk>
    800064d4:	0001f517          	auipc	a0,0x1f
    800064d8:	b2c50513          	addi	a0,a0,-1236 # 80025000 <disk+0x2000>
    800064dc:	6114                	ld	a3,0(a0)
    800064de:	96ba                	add	a3,a3,a4
    800064e0:	00c6d603          	lhu	a2,12(a3)
    800064e4:	00166613          	ori	a2,a2,1
    800064e8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800064ec:	f9842683          	lw	a3,-104(s0)
    800064f0:	6110                	ld	a2,0(a0)
    800064f2:	9732                	add	a4,a4,a2
    800064f4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800064f8:	20058613          	addi	a2,a1,512
    800064fc:	0612                	slli	a2,a2,0x4
    800064fe:	9642                	add	a2,a2,a6
    80006500:	577d                	li	a4,-1
    80006502:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006506:	00469713          	slli	a4,a3,0x4
    8000650a:	6114                	ld	a3,0(a0)
    8000650c:	96ba                	add	a3,a3,a4
    8000650e:	03078793          	addi	a5,a5,48
    80006512:	97c2                	add	a5,a5,a6
    80006514:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006516:	611c                	ld	a5,0(a0)
    80006518:	97ba                	add	a5,a5,a4
    8000651a:	4685                	li	a3,1
    8000651c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000651e:	611c                	ld	a5,0(a0)
    80006520:	97ba                	add	a5,a5,a4
    80006522:	4809                	li	a6,2
    80006524:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006528:	611c                	ld	a5,0(a0)
    8000652a:	973e                	add	a4,a4,a5
    8000652c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006530:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006534:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006538:	6518                	ld	a4,8(a0)
    8000653a:	00275783          	lhu	a5,2(a4)
    8000653e:	8b9d                	andi	a5,a5,7
    80006540:	0786                	slli	a5,a5,0x1
    80006542:	97ba                	add	a5,a5,a4
    80006544:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006548:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000654c:	6518                	ld	a4,8(a0)
    8000654e:	00275783          	lhu	a5,2(a4)
    80006552:	2785                	addiw	a5,a5,1
    80006554:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006558:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000655c:	100017b7          	lui	a5,0x10001
    80006560:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006564:	00492703          	lw	a4,4(s2)
    80006568:	4785                	li	a5,1
    8000656a:	02f71163          	bne	a4,a5,8000658c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000656e:	0001f997          	auipc	s3,0x1f
    80006572:	bba98993          	addi	s3,s3,-1094 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006576:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006578:	85ce                	mv	a1,s3
    8000657a:	854a                	mv	a0,s2
    8000657c:	ffffc097          	auipc	ra,0xffffc
    80006580:	f52080e7          	jalr	-174(ra) # 800024ce <sleep>
  while(b->disk == 1) {
    80006584:	00492783          	lw	a5,4(s2)
    80006588:	fe9788e3          	beq	a5,s1,80006578 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000658c:	f9042903          	lw	s2,-112(s0)
    80006590:	20090793          	addi	a5,s2,512
    80006594:	00479713          	slli	a4,a5,0x4
    80006598:	0001d797          	auipc	a5,0x1d
    8000659c:	a6878793          	addi	a5,a5,-1432 # 80023000 <disk>
    800065a0:	97ba                	add	a5,a5,a4
    800065a2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800065a6:	0001f997          	auipc	s3,0x1f
    800065aa:	a5a98993          	addi	s3,s3,-1446 # 80025000 <disk+0x2000>
    800065ae:	00491713          	slli	a4,s2,0x4
    800065b2:	0009b783          	ld	a5,0(s3)
    800065b6:	97ba                	add	a5,a5,a4
    800065b8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800065bc:	854a                	mv	a0,s2
    800065be:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065c2:	00000097          	auipc	ra,0x0
    800065c6:	bc4080e7          	jalr	-1084(ra) # 80006186 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065ca:	8885                	andi	s1,s1,1
    800065cc:	f0ed                	bnez	s1,800065ae <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065ce:	0001f517          	auipc	a0,0x1f
    800065d2:	b5a50513          	addi	a0,a0,-1190 # 80025128 <disk+0x2128>
    800065d6:	ffffa097          	auipc	ra,0xffffa
    800065da:	6c2080e7          	jalr	1730(ra) # 80000c98 <release>
}
    800065de:	70a6                	ld	ra,104(sp)
    800065e0:	7406                	ld	s0,96(sp)
    800065e2:	64e6                	ld	s1,88(sp)
    800065e4:	6946                	ld	s2,80(sp)
    800065e6:	69a6                	ld	s3,72(sp)
    800065e8:	6a06                	ld	s4,64(sp)
    800065ea:	7ae2                	ld	s5,56(sp)
    800065ec:	7b42                	ld	s6,48(sp)
    800065ee:	7ba2                	ld	s7,40(sp)
    800065f0:	7c02                	ld	s8,32(sp)
    800065f2:	6ce2                	ld	s9,24(sp)
    800065f4:	6d42                	ld	s10,16(sp)
    800065f6:	6165                	addi	sp,sp,112
    800065f8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800065fa:	0001f697          	auipc	a3,0x1f
    800065fe:	a066b683          	ld	a3,-1530(a3) # 80025000 <disk+0x2000>
    80006602:	96ba                	add	a3,a3,a4
    80006604:	4609                	li	a2,2
    80006606:	00c69623          	sh	a2,12(a3)
    8000660a:	b5c9                	j	800064cc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000660c:	f9042583          	lw	a1,-112(s0)
    80006610:	20058793          	addi	a5,a1,512
    80006614:	0792                	slli	a5,a5,0x4
    80006616:	0001d517          	auipc	a0,0x1d
    8000661a:	a9250513          	addi	a0,a0,-1390 # 800230a8 <disk+0xa8>
    8000661e:	953e                	add	a0,a0,a5
  if(write)
    80006620:	e20d11e3          	bnez	s10,80006442 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006624:	20058713          	addi	a4,a1,512
    80006628:	00471693          	slli	a3,a4,0x4
    8000662c:	0001d717          	auipc	a4,0x1d
    80006630:	9d470713          	addi	a4,a4,-1580 # 80023000 <disk>
    80006634:	9736                	add	a4,a4,a3
    80006636:	0a072423          	sw	zero,168(a4)
    8000663a:	b505                	j	8000645a <virtio_disk_rw+0xf4>

000000008000663c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000663c:	1101                	addi	sp,sp,-32
    8000663e:	ec06                	sd	ra,24(sp)
    80006640:	e822                	sd	s0,16(sp)
    80006642:	e426                	sd	s1,8(sp)
    80006644:	e04a                	sd	s2,0(sp)
    80006646:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006648:	0001f517          	auipc	a0,0x1f
    8000664c:	ae050513          	addi	a0,a0,-1312 # 80025128 <disk+0x2128>
    80006650:	ffffa097          	auipc	ra,0xffffa
    80006654:	594080e7          	jalr	1428(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006658:	10001737          	lui	a4,0x10001
    8000665c:	533c                	lw	a5,96(a4)
    8000665e:	8b8d                	andi	a5,a5,3
    80006660:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006662:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006666:	0001f797          	auipc	a5,0x1f
    8000666a:	99a78793          	addi	a5,a5,-1638 # 80025000 <disk+0x2000>
    8000666e:	6b94                	ld	a3,16(a5)
    80006670:	0207d703          	lhu	a4,32(a5)
    80006674:	0026d783          	lhu	a5,2(a3)
    80006678:	06f70163          	beq	a4,a5,800066da <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000667c:	0001d917          	auipc	s2,0x1d
    80006680:	98490913          	addi	s2,s2,-1660 # 80023000 <disk>
    80006684:	0001f497          	auipc	s1,0x1f
    80006688:	97c48493          	addi	s1,s1,-1668 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000668c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006690:	6898                	ld	a4,16(s1)
    80006692:	0204d783          	lhu	a5,32(s1)
    80006696:	8b9d                	andi	a5,a5,7
    80006698:	078e                	slli	a5,a5,0x3
    8000669a:	97ba                	add	a5,a5,a4
    8000669c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000669e:	20078713          	addi	a4,a5,512
    800066a2:	0712                	slli	a4,a4,0x4
    800066a4:	974a                	add	a4,a4,s2
    800066a6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800066aa:	e731                	bnez	a4,800066f6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800066ac:	20078793          	addi	a5,a5,512
    800066b0:	0792                	slli	a5,a5,0x4
    800066b2:	97ca                	add	a5,a5,s2
    800066b4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800066b6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800066ba:	ffffc097          	auipc	ra,0xffffc
    800066be:	fb2080e7          	jalr	-78(ra) # 8000266c <wakeup>

    disk.used_idx += 1;
    800066c2:	0204d783          	lhu	a5,32(s1)
    800066c6:	2785                	addiw	a5,a5,1
    800066c8:	17c2                	slli	a5,a5,0x30
    800066ca:	93c1                	srli	a5,a5,0x30
    800066cc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066d0:	6898                	ld	a4,16(s1)
    800066d2:	00275703          	lhu	a4,2(a4)
    800066d6:	faf71be3          	bne	a4,a5,8000668c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800066da:	0001f517          	auipc	a0,0x1f
    800066de:	a4e50513          	addi	a0,a0,-1458 # 80025128 <disk+0x2128>
    800066e2:	ffffa097          	auipc	ra,0xffffa
    800066e6:	5b6080e7          	jalr	1462(ra) # 80000c98 <release>
}
    800066ea:	60e2                	ld	ra,24(sp)
    800066ec:	6442                	ld	s0,16(sp)
    800066ee:	64a2                	ld	s1,8(sp)
    800066f0:	6902                	ld	s2,0(sp)
    800066f2:	6105                	addi	sp,sp,32
    800066f4:	8082                	ret
      panic("virtio_disk_intr status");
    800066f6:	00002517          	auipc	a0,0x2
    800066fa:	18a50513          	addi	a0,a0,394 # 80008880 <syscalls+0x3b0>
    800066fe:	ffffa097          	auipc	ra,0xffffa
    80006702:	e40080e7          	jalr	-448(ra) # 8000053e <panic>

0000000080006706 <cas>:
    80006706:	100522af          	lr.w	t0,(a0)
    8000670a:	00b29563          	bne	t0,a1,80006714 <fail>
    8000670e:	18c5252f          	sc.w	a0,a2,(a0)
    80006712:	8082                	ret

0000000080006714 <fail>:
    80006714:	4505                	li	a0,1
    80006716:	8082                	ret
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
