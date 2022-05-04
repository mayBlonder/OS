
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	d1013103          	ld	sp,-752(sp) # 80009d10 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000052:	0000a717          	auipc	a4,0xa
    80000056:	00e70713          	addi	a4,a4,14 # 8000a060 <timer_scratch>
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
    80000064:	00007797          	auipc	a5,0x7
    80000068:	2cc78793          	addi	a5,a5,716 # 80007330 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd67ff>
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
    8000012c:	00004097          	auipc	ra,0x4
    80000130:	a8c080e7          	jalr	-1396(ra) # 80003bb8 <either_copyin>
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
    8000018c:	00012517          	auipc	a0,0x12
    80000190:	01450513          	addi	a0,a0,20 # 800121a0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00012497          	auipc	s1,0x12
    800001a0:	00448493          	addi	s1,s1,4 # 800121a0 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00012917          	auipc	s2,0x12
    800001aa:	09290913          	addi	s2,s2,146 # 80012238 <cons+0x98>
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
    800001c8:	a00080e7          	jalr	-1536(ra) # 80001bc4 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00003097          	auipc	ra,0x3
    800001d8:	b4e080e7          	jalr	-1202(ra) # 80002d22 <sleep>
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
    80000210:	00004097          	auipc	ra,0x4
    80000214:	952080e7          	jalr	-1710(ra) # 80003b62 <either_copyout>
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
    80000224:	00012517          	auipc	a0,0x12
    80000228:	f7c50513          	addi	a0,a0,-132 # 800121a0 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00012517          	auipc	a0,0x12
    8000023e:	f6650513          	addi	a0,a0,-154 # 800121a0 <cons>
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
    80000272:	00012717          	auipc	a4,0x12
    80000276:	fcf72323          	sw	a5,-58(a4) # 80012238 <cons+0x98>
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
    800002cc:	00012517          	auipc	a0,0x12
    800002d0:	ed450513          	addi	a0,a0,-300 # 800121a0 <cons>
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
    800002f2:	00004097          	auipc	ra,0x4
    800002f6:	91c080e7          	jalr	-1764(ra) # 80003c0e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00012517          	auipc	a0,0x12
    800002fe:	ea650513          	addi	a0,a0,-346 # 800121a0 <cons>
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
    8000031e:	00012717          	auipc	a4,0x12
    80000322:	e8270713          	addi	a4,a4,-382 # 800121a0 <cons>
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
    80000348:	00012797          	auipc	a5,0x12
    8000034c:	e5878793          	addi	a5,a5,-424 # 800121a0 <cons>
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
    80000376:	00012797          	auipc	a5,0x12
    8000037a:	ec27a783          	lw	a5,-318(a5) # 80012238 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00012717          	auipc	a4,0x12
    8000038e:	e1670713          	addi	a4,a4,-490 # 800121a0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00012497          	auipc	s1,0x12
    8000039e:	e0648493          	addi	s1,s1,-506 # 800121a0 <cons>
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
    800003d6:	00012717          	auipc	a4,0x12
    800003da:	dca70713          	addi	a4,a4,-566 # 800121a0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00012717          	auipc	a4,0x12
    800003f0:	e4f72a23          	sw	a5,-428(a4) # 80012240 <cons+0xa0>
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
    80000412:	00012797          	auipc	a5,0x12
    80000416:	d8e78793          	addi	a5,a5,-626 # 800121a0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00012797          	auipc	a5,0x12
    8000043a:	e0c7a323          	sw	a2,-506(a5) # 8001223c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00012517          	auipc	a0,0x12
    80000442:	dfa50513          	addi	a0,a0,-518 # 80012238 <cons+0x98>
    80000446:	00003097          	auipc	ra,0x3
    8000044a:	cf2080e7          	jalr	-782(ra) # 80003138 <wakeup>
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
    80000458:	00009597          	auipc	a1,0x9
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80009010 <etext+0x10>
    80000460:	00012517          	auipc	a0,0x12
    80000464:	d4050513          	addi	a0,a0,-704 # 800121a0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00023797          	auipc	a5,0x23
    8000047c:	b4078793          	addi	a5,a5,-1216 # 80022fb8 <devsw>
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
    800004ba:	00009617          	auipc	a2,0x9
    800004be:	b8660613          	addi	a2,a2,-1146 # 80009040 <digits>
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
    8000054a:	00012797          	auipc	a5,0x12
    8000054e:	d007ab23          	sw	zero,-746(a5) # 80012260 <pr+0x18>
  printf("panic: ");
    80000552:	00009517          	auipc	a0,0x9
    80000556:	ac650513          	addi	a0,a0,-1338 # 80009018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00009517          	auipc	a0,0x9
    80000570:	11c50513          	addi	a0,a0,284 # 80009688 <digits+0x648>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	0000a717          	auipc	a4,0xa
    80000582:	a8f72123          	sw	a5,-1406(a4) # 8000a000 <panicked>
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
    800005ba:	00012d97          	auipc	s11,0x12
    800005be:	ca6dad83          	lw	s11,-858(s11) # 80012260 <pr+0x18>
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
    800005e6:	00009b97          	auipc	s7,0x9
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80009040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00012517          	auipc	a0,0x12
    800005fc:	c5050513          	addi	a0,a0,-944 # 80012248 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00009517          	auipc	a0,0x9
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80009028 <etext+0x28>
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
    8000070a:	00009917          	auipc	s2,0x9
    8000070e:	91690913          	addi	s2,s2,-1770 # 80009020 <etext+0x20>
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
    8000075c:	00012517          	auipc	a0,0x12
    80000760:	aec50513          	addi	a0,a0,-1300 # 80012248 <pr>
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
    80000778:	00012497          	auipc	s1,0x12
    8000077c:	ad048493          	addi	s1,s1,-1328 # 80012248 <pr>
    80000780:	00009597          	auipc	a1,0x9
    80000784:	8b858593          	addi	a1,a1,-1864 # 80009038 <etext+0x38>
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
    800007d0:	00009597          	auipc	a1,0x9
    800007d4:	88858593          	addi	a1,a1,-1912 # 80009058 <digits+0x18>
    800007d8:	00012517          	auipc	a0,0x12
    800007dc:	a9050513          	addi	a0,a0,-1392 # 80012268 <uart_tx_lock>
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
    80000804:	00009797          	auipc	a5,0x9
    80000808:	7fc7a783          	lw	a5,2044(a5) # 8000a000 <panicked>
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
    80000840:	00009717          	auipc	a4,0x9
    80000844:	7c873703          	ld	a4,1992(a4) # 8000a008 <uart_tx_r>
    80000848:	00009797          	auipc	a5,0x9
    8000084c:	7c87b783          	ld	a5,1992(a5) # 8000a010 <uart_tx_w>
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
    8000086a:	00012a17          	auipc	s4,0x12
    8000086e:	9fea0a13          	addi	s4,s4,-1538 # 80012268 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00009497          	auipc	s1,0x9
    80000876:	79648493          	addi	s1,s1,1942 # 8000a008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00009997          	auipc	s3,0x9
    8000087e:	79698993          	addi	s3,s3,1942 # 8000a010 <uart_tx_w>
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
    800008a0:	00003097          	auipc	ra,0x3
    800008a4:	898080e7          	jalr	-1896(ra) # 80003138 <wakeup>
    
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
    800008dc:	00012517          	auipc	a0,0x12
    800008e0:	98c50513          	addi	a0,a0,-1652 # 80012268 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00009797          	auipc	a5,0x9
    800008f0:	7147a783          	lw	a5,1812(a5) # 8000a000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00009797          	auipc	a5,0x9
    800008fc:	7187b783          	ld	a5,1816(a5) # 8000a010 <uart_tx_w>
    80000900:	00009717          	auipc	a4,0x9
    80000904:	70873703          	ld	a4,1800(a4) # 8000a008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00012a17          	auipc	s4,0x12
    80000914:	958a0a13          	addi	s4,s4,-1704 # 80012268 <uart_tx_lock>
    80000918:	00009497          	auipc	s1,0x9
    8000091c:	6f048493          	addi	s1,s1,1776 # 8000a008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00009917          	auipc	s2,0x9
    80000924:	6f090913          	addi	s2,s2,1776 # 8000a010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	3f6080e7          	jalr	1014(ra) # 80002d22 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00012497          	auipc	s1,0x12
    80000946:	92648493          	addi	s1,s1,-1754 # 80012268 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00009717          	auipc	a4,0x9
    8000095a:	6af73d23          	sd	a5,1722(a4) # 8000a010 <uart_tx_w>
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
    800009ca:	00012497          	auipc	s1,0x12
    800009ce:	89e48493          	addi	s1,s1,-1890 # 80012268 <uart_tx_lock>
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
    80000a0c:	00027797          	auipc	a5,0x27
    80000a10:	5f478793          	addi	a5,a5,1524 # 80028000 <end>
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
    80000a2c:	00012917          	auipc	s2,0x12
    80000a30:	87490913          	addi	s2,s2,-1932 # 800122a0 <kmem>
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
    80000a5e:	00008517          	auipc	a0,0x8
    80000a62:	60250513          	addi	a0,a0,1538 # 80009060 <digits+0x20>
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
    80000ac0:	00008597          	auipc	a1,0x8
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80009068 <digits+0x28>
    80000ac8:	00011517          	auipc	a0,0x11
    80000acc:	7d850513          	addi	a0,a0,2008 # 800122a0 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00027517          	auipc	a0,0x27
    80000ae0:	52450513          	addi	a0,a0,1316 # 80028000 <end>
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
    80000afe:	00011497          	auipc	s1,0x11
    80000b02:	7a248493          	addi	s1,s1,1954 # 800122a0 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00011517          	auipc	a0,0x11
    80000b1a:	78a50513          	addi	a0,a0,1930 # 800122a0 <kmem>
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
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	75e50513          	addi	a0,a0,1886 # 800122a0 <kmem>
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
    80000b82:	01a080e7          	jalr	26(ra) # 80001b98 <mycpu>
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
    80000bb4:	fe8080e7          	jalr	-24(ra) # 80001b98 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	fdc080e7          	jalr	-36(ra) # 80001b98 <mycpu>
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
    80000bd8:	fc4080e7          	jalr	-60(ra) # 80001b98 <mycpu>
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
    80000c18:	f84080e7          	jalr	-124(ra) # 80001b98 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00008517          	auipc	a0,0x8
    80000c2c:	44850513          	addi	a0,a0,1096 # 80009070 <digits+0x30>
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
    80000c44:	f58080e7          	jalr	-168(ra) # 80001b98 <mycpu>
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
    80000c78:	00008517          	auipc	a0,0x8
    80000c7c:	40050513          	addi	a0,a0,1024 # 80009078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00008517          	auipc	a0,0x8
    80000c8c:	40850513          	addi	a0,a0,1032 # 80009090 <digits+0x50>
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
    80000cd0:	00008517          	auipc	a0,0x8
    80000cd4:	3c850513          	addi	a0,a0,968 # 80009098 <digits+0x58>
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
    80000e9a:	cf2080e7          	jalr	-782(ra) # 80001b88 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00009717          	auipc	a4,0x9
    80000ea2:	17a70713          	addi	a4,a4,378 # 8000a018 <started>
  if(cpuid() == 0){
    80000ea6:	c539                	beqz	a0,80000ef4 <main+0x66>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	cd6080e7          	jalr	-810(ra) # 80001b88 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00008517          	auipc	a0,0x8
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800090b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0e0080e7          	jalr	224(ra) # 80000fac <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00003097          	auipc	ra,0x3
    80000ed8:	e7a080e7          	jalr	-390(ra) # 80003d4e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00006097          	auipc	ra,0x6
    80000ee0:	494080e7          	jalr	1172(ra) # 80007370 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	9e2080e7          	jalr	-1566(ra) # 800028c6 <scheduler>
}
    80000eec:	60a2                	ld	ra,8(sp)
    80000eee:	6402                	ld	s0,0(sp)
    80000ef0:	0141                	addi	sp,sp,16
    80000ef2:	8082                	ret
    consoleinit();
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	55c080e7          	jalr	1372(ra) # 80000450 <consoleinit>
    printfinit();
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	872080e7          	jalr	-1934(ra) # 8000076e <printfinit>
    printf("\n");
    80000f04:	00008517          	auipc	a0,0x8
    80000f08:	78450513          	addi	a0,a0,1924 # 80009688 <digits+0x648>
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	67c080e7          	jalr	1660(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f14:	00008517          	auipc	a0,0x8
    80000f18:	18c50513          	addi	a0,a0,396 # 800090a0 <digits+0x60>
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	66c080e7          	jalr	1644(ra) # 80000588 <printf>
    printf("\n");
    80000f24:	00008517          	auipc	a0,0x8
    80000f28:	76450513          	addi	a0,a0,1892 # 80009688 <digits+0x648>
    80000f2c:	fffff097          	auipc	ra,0xfffff
    80000f30:	65c080e7          	jalr	1628(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	b84080e7          	jalr	-1148(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	322080e7          	jalr	802(ra) # 8000125e <kvminit>
    kvminithart();   // turn on paging
    80000f44:	00000097          	auipc	ra,0x0
    80000f48:	068080e7          	jalr	104(ra) # 80000fac <kvminithart>
    procinit();      // process table
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	ad4080e7          	jalr	-1324(ra) # 80001a20 <procinit>
    trapinit();      // trap vectors
    80000f54:	00003097          	auipc	ra,0x3
    80000f58:	dd2080e7          	jalr	-558(ra) # 80003d26 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00003097          	auipc	ra,0x3
    80000f60:	df2080e7          	jalr	-526(ra) # 80003d4e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00006097          	auipc	ra,0x6
    80000f68:	3f6080e7          	jalr	1014(ra) # 8000735a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00006097          	auipc	ra,0x6
    80000f70:	404080e7          	jalr	1028(ra) # 80007370 <plicinithart>
    binit();         // buffer cache
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	5d6080e7          	jalr	1494(ra) # 8000454a <binit>
    iinit();         // inode table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	c66080e7          	jalr	-922(ra) # 80004be2 <iinit>
    fileinit();      // file table
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	c10080e7          	jalr	-1008(ra) # 80005b94 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00006097          	auipc	ra,0x6
    80000f90:	506080e7          	jalr	1286(ra) # 80007492 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	208080e7          	jalr	520(ra) # 8000219c <userinit>
    __sync_synchronize();
    80000f9c:	0ff0000f          	fence
    started = 1;
    80000fa0:	4785                	li	a5,1
    80000fa2:	00009717          	auipc	a4,0x9
    80000fa6:	06f72b23          	sw	a5,118(a4) # 8000a018 <started>
    80000faa:	bf2d                	j	80000ee4 <main+0x56>

0000000080000fac <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fac:	1141                	addi	sp,sp,-16
    80000fae:	e422                	sd	s0,8(sp)
    80000fb0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb2:	00009797          	auipc	a5,0x9
    80000fb6:	06e7b783          	ld	a5,110(a5) # 8000a020 <kernel_pagetable>
    80000fba:	83b1                	srli	a5,a5,0xc
    80000fbc:	577d                	li	a4,-1
    80000fbe:	177e                	slli	a4,a4,0x3f
    80000fc0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fc6:	12000073          	sfence.vma
  sfence_vma();
}
    80000fca:	6422                	ld	s0,8(sp)
    80000fcc:	0141                	addi	sp,sp,16
    80000fce:	8082                	ret

0000000080000fd0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd0:	7139                	addi	sp,sp,-64
    80000fd2:	fc06                	sd	ra,56(sp)
    80000fd4:	f822                	sd	s0,48(sp)
    80000fd6:	f426                	sd	s1,40(sp)
    80000fd8:	f04a                	sd	s2,32(sp)
    80000fda:	ec4e                	sd	s3,24(sp)
    80000fdc:	e852                	sd	s4,16(sp)
    80000fde:	e456                	sd	s5,8(sp)
    80000fe0:	e05a                	sd	s6,0(sp)
    80000fe2:	0080                	addi	s0,sp,64
    80000fe4:	84aa                	mv	s1,a0
    80000fe6:	89ae                	mv	s3,a1
    80000fe8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fea:	57fd                	li	a5,-1
    80000fec:	83e9                	srli	a5,a5,0x1a
    80000fee:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff2:	04b7f263          	bgeu	a5,a1,80001036 <walk+0x66>
    panic("walk");
    80000ff6:	00008517          	auipc	a0,0x8
    80000ffa:	0da50513          	addi	a0,a0,218 # 800090d0 <digits+0x90>
    80000ffe:	fffff097          	auipc	ra,0xfffff
    80001002:	540080e7          	jalr	1344(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001006:	060a8663          	beqz	s5,80001072 <walk+0xa2>
    8000100a:	00000097          	auipc	ra,0x0
    8000100e:	aea080e7          	jalr	-1302(ra) # 80000af4 <kalloc>
    80001012:	84aa                	mv	s1,a0
    80001014:	c529                	beqz	a0,8000105e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001016:	6605                	lui	a2,0x1
    80001018:	4581                	li	a1,0
    8000101a:	00000097          	auipc	ra,0x0
    8000101e:	cc6080e7          	jalr	-826(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001022:	00c4d793          	srli	a5,s1,0xc
    80001026:	07aa                	slli	a5,a5,0xa
    80001028:	0017e793          	ori	a5,a5,1
    8000102c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001030:	3a5d                	addiw	s4,s4,-9
    80001032:	036a0063          	beq	s4,s6,80001052 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001036:	0149d933          	srl	s2,s3,s4
    8000103a:	1ff97913          	andi	s2,s2,511
    8000103e:	090e                	slli	s2,s2,0x3
    80001040:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001042:	00093483          	ld	s1,0(s2)
    80001046:	0014f793          	andi	a5,s1,1
    8000104a:	dfd5                	beqz	a5,80001006 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104c:	80a9                	srli	s1,s1,0xa
    8000104e:	04b2                	slli	s1,s1,0xc
    80001050:	b7c5                	j	80001030 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001052:	00c9d513          	srli	a0,s3,0xc
    80001056:	1ff57513          	andi	a0,a0,511
    8000105a:	050e                	slli	a0,a0,0x3
    8000105c:	9526                	add	a0,a0,s1
}
    8000105e:	70e2                	ld	ra,56(sp)
    80001060:	7442                	ld	s0,48(sp)
    80001062:	74a2                	ld	s1,40(sp)
    80001064:	7902                	ld	s2,32(sp)
    80001066:	69e2                	ld	s3,24(sp)
    80001068:	6a42                	ld	s4,16(sp)
    8000106a:	6aa2                	ld	s5,8(sp)
    8000106c:	6b02                	ld	s6,0(sp)
    8000106e:	6121                	addi	sp,sp,64
    80001070:	8082                	ret
        return 0;
    80001072:	4501                	li	a0,0
    80001074:	b7ed                	j	8000105e <walk+0x8e>

0000000080001076 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001076:	57fd                	li	a5,-1
    80001078:	83e9                	srli	a5,a5,0x1a
    8000107a:	00b7f463          	bgeu	a5,a1,80001082 <walkaddr+0xc>
    return 0;
    8000107e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001080:	8082                	ret
{
    80001082:	1141                	addi	sp,sp,-16
    80001084:	e406                	sd	ra,8(sp)
    80001086:	e022                	sd	s0,0(sp)
    80001088:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108a:	4601                	li	a2,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	f44080e7          	jalr	-188(ra) # 80000fd0 <walk>
  if(pte == 0)
    80001094:	c105                	beqz	a0,800010b4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001096:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001098:	0117f693          	andi	a3,a5,17
    8000109c:	4745                	li	a4,17
    return 0;
    8000109e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a0:	00e68663          	beq	a3,a4,800010ac <walkaddr+0x36>
}
    800010a4:	60a2                	ld	ra,8(sp)
    800010a6:	6402                	ld	s0,0(sp)
    800010a8:	0141                	addi	sp,sp,16
    800010aa:	8082                	ret
  pa = PTE2PA(*pte);
    800010ac:	00a7d513          	srli	a0,a5,0xa
    800010b0:	0532                	slli	a0,a0,0xc
  return pa;
    800010b2:	bfcd                	j	800010a4 <walkaddr+0x2e>
    return 0;
    800010b4:	4501                	li	a0,0
    800010b6:	b7fd                	j	800010a4 <walkaddr+0x2e>

00000000800010b8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b8:	715d                	addi	sp,sp,-80
    800010ba:	e486                	sd	ra,72(sp)
    800010bc:	e0a2                	sd	s0,64(sp)
    800010be:	fc26                	sd	s1,56(sp)
    800010c0:	f84a                	sd	s2,48(sp)
    800010c2:	f44e                	sd	s3,40(sp)
    800010c4:	f052                	sd	s4,32(sp)
    800010c6:	ec56                	sd	s5,24(sp)
    800010c8:	e85a                	sd	s6,16(sp)
    800010ca:	e45e                	sd	s7,8(sp)
    800010cc:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ce:	c205                	beqz	a2,800010ee <mappages+0x36>
    800010d0:	8aaa                	mv	s5,a0
    800010d2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d4:	77fd                	lui	a5,0xfffff
    800010d6:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010da:	15fd                	addi	a1,a1,-1
    800010dc:	00c589b3          	add	s3,a1,a2
    800010e0:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e4:	8952                	mv	s2,s4
    800010e6:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ea:	6b85                	lui	s7,0x1
    800010ec:	a015                	j	80001110 <mappages+0x58>
    panic("mappages: size");
    800010ee:	00008517          	auipc	a0,0x8
    800010f2:	fea50513          	addi	a0,a0,-22 # 800090d8 <digits+0x98>
    800010f6:	fffff097          	auipc	ra,0xfffff
    800010fa:	448080e7          	jalr	1096(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010fe:	00008517          	auipc	a0,0x8
    80001102:	fea50513          	addi	a0,a0,-22 # 800090e8 <digits+0xa8>
    80001106:	fffff097          	auipc	ra,0xfffff
    8000110a:	438080e7          	jalr	1080(ra) # 8000053e <panic>
    a += PGSIZE;
    8000110e:	995e                	add	s2,s2,s7
  for(;;){
    80001110:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001114:	4605                	li	a2,1
    80001116:	85ca                	mv	a1,s2
    80001118:	8556                	mv	a0,s5
    8000111a:	00000097          	auipc	ra,0x0
    8000111e:	eb6080e7          	jalr	-330(ra) # 80000fd0 <walk>
    80001122:	cd19                	beqz	a0,80001140 <mappages+0x88>
    if(*pte & PTE_V)
    80001124:	611c                	ld	a5,0(a0)
    80001126:	8b85                	andi	a5,a5,1
    80001128:	fbf9                	bnez	a5,800010fe <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112a:	80b1                	srli	s1,s1,0xc
    8000112c:	04aa                	slli	s1,s1,0xa
    8000112e:	0164e4b3          	or	s1,s1,s6
    80001132:	0014e493          	ori	s1,s1,1
    80001136:	e104                	sd	s1,0(a0)
    if(a == last)
    80001138:	fd391be3          	bne	s2,s3,8000110e <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113c:	4501                	li	a0,0
    8000113e:	a011                	j	80001142 <mappages+0x8a>
      return -1;
    80001140:	557d                	li	a0,-1
}
    80001142:	60a6                	ld	ra,72(sp)
    80001144:	6406                	ld	s0,64(sp)
    80001146:	74e2                	ld	s1,56(sp)
    80001148:	7942                	ld	s2,48(sp)
    8000114a:	79a2                	ld	s3,40(sp)
    8000114c:	7a02                	ld	s4,32(sp)
    8000114e:	6ae2                	ld	s5,24(sp)
    80001150:	6b42                	ld	s6,16(sp)
    80001152:	6ba2                	ld	s7,8(sp)
    80001154:	6161                	addi	sp,sp,80
    80001156:	8082                	ret

0000000080001158 <kvmmap>:
{
    80001158:	1141                	addi	sp,sp,-16
    8000115a:	e406                	sd	ra,8(sp)
    8000115c:	e022                	sd	s0,0(sp)
    8000115e:	0800                	addi	s0,sp,16
    80001160:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001162:	86b2                	mv	a3,a2
    80001164:	863e                	mv	a2,a5
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	f52080e7          	jalr	-174(ra) # 800010b8 <mappages>
    8000116e:	e509                	bnez	a0,80001178 <kvmmap+0x20>
}
    80001170:	60a2                	ld	ra,8(sp)
    80001172:	6402                	ld	s0,0(sp)
    80001174:	0141                	addi	sp,sp,16
    80001176:	8082                	ret
    panic("kvmmap");
    80001178:	00008517          	auipc	a0,0x8
    8000117c:	f8050513          	addi	a0,a0,-128 # 800090f8 <digits+0xb8>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3be080e7          	jalr	958(ra) # 8000053e <panic>

0000000080001188 <kvmmake>:
{
    80001188:	1101                	addi	sp,sp,-32
    8000118a:	ec06                	sd	ra,24(sp)
    8000118c:	e822                	sd	s0,16(sp)
    8000118e:	e426                	sd	s1,8(sp)
    80001190:	e04a                	sd	s2,0(sp)
    80001192:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001194:	00000097          	auipc	ra,0x0
    80001198:	960080e7          	jalr	-1696(ra) # 80000af4 <kalloc>
    8000119c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000119e:	6605                	lui	a2,0x1
    800011a0:	4581                	li	a1,0
    800011a2:	00000097          	auipc	ra,0x0
    800011a6:	b3e080e7          	jalr	-1218(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011aa:	4719                	li	a4,6
    800011ac:	6685                	lui	a3,0x1
    800011ae:	10000637          	lui	a2,0x10000
    800011b2:	100005b7          	lui	a1,0x10000
    800011b6:	8526                	mv	a0,s1
    800011b8:	00000097          	auipc	ra,0x0
    800011bc:	fa0080e7          	jalr	-96(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c0:	4719                	li	a4,6
    800011c2:	6685                	lui	a3,0x1
    800011c4:	10001637          	lui	a2,0x10001
    800011c8:	100015b7          	lui	a1,0x10001
    800011cc:	8526                	mv	a0,s1
    800011ce:	00000097          	auipc	ra,0x0
    800011d2:	f8a080e7          	jalr	-118(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d6:	4719                	li	a4,6
    800011d8:	004006b7          	lui	a3,0x400
    800011dc:	0c000637          	lui	a2,0xc000
    800011e0:	0c0005b7          	lui	a1,0xc000
    800011e4:	8526                	mv	a0,s1
    800011e6:	00000097          	auipc	ra,0x0
    800011ea:	f72080e7          	jalr	-142(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ee:	00008917          	auipc	s2,0x8
    800011f2:	e1290913          	addi	s2,s2,-494 # 80009000 <etext>
    800011f6:	4729                	li	a4,10
    800011f8:	80008697          	auipc	a3,0x80008
    800011fc:	e0868693          	addi	a3,a3,-504 # 9000 <_entry-0x7fff7000>
    80001200:	4605                	li	a2,1
    80001202:	067e                	slli	a2,a2,0x1f
    80001204:	85b2                	mv	a1,a2
    80001206:	8526                	mv	a0,s1
    80001208:	00000097          	auipc	ra,0x0
    8000120c:	f50080e7          	jalr	-176(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001210:	4719                	li	a4,6
    80001212:	46c5                	li	a3,17
    80001214:	06ee                	slli	a3,a3,0x1b
    80001216:	412686b3          	sub	a3,a3,s2
    8000121a:	864a                	mv	a2,s2
    8000121c:	85ca                	mv	a1,s2
    8000121e:	8526                	mv	a0,s1
    80001220:	00000097          	auipc	ra,0x0
    80001224:	f38080e7          	jalr	-200(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001228:	4729                	li	a4,10
    8000122a:	6685                	lui	a3,0x1
    8000122c:	00007617          	auipc	a2,0x7
    80001230:	dd460613          	addi	a2,a2,-556 # 80008000 <_trampoline>
    80001234:	040005b7          	lui	a1,0x4000
    80001238:	15fd                	addi	a1,a1,-1
    8000123a:	05b2                	slli	a1,a1,0xc
    8000123c:	8526                	mv	a0,s1
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	f1a080e7          	jalr	-230(ra) # 80001158 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001246:	8526                	mv	a0,s1
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	742080e7          	jalr	1858(ra) # 8000198a <proc_mapstacks>
}
    80001250:	8526                	mv	a0,s1
    80001252:	60e2                	ld	ra,24(sp)
    80001254:	6442                	ld	s0,16(sp)
    80001256:	64a2                	ld	s1,8(sp)
    80001258:	6902                	ld	s2,0(sp)
    8000125a:	6105                	addi	sp,sp,32
    8000125c:	8082                	ret

000000008000125e <kvminit>:
{
    8000125e:	1141                	addi	sp,sp,-16
    80001260:	e406                	sd	ra,8(sp)
    80001262:	e022                	sd	s0,0(sp)
    80001264:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f22080e7          	jalr	-222(ra) # 80001188 <kvmmake>
    8000126e:	00009797          	auipc	a5,0x9
    80001272:	daa7b923          	sd	a0,-590(a5) # 8000a020 <kernel_pagetable>
}
    80001276:	60a2                	ld	ra,8(sp)
    80001278:	6402                	ld	s0,0(sp)
    8000127a:	0141                	addi	sp,sp,16
    8000127c:	8082                	ret

000000008000127e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000127e:	715d                	addi	sp,sp,-80
    80001280:	e486                	sd	ra,72(sp)
    80001282:	e0a2                	sd	s0,64(sp)
    80001284:	fc26                	sd	s1,56(sp)
    80001286:	f84a                	sd	s2,48(sp)
    80001288:	f44e                	sd	s3,40(sp)
    8000128a:	f052                	sd	s4,32(sp)
    8000128c:	ec56                	sd	s5,24(sp)
    8000128e:	e85a                	sd	s6,16(sp)
    80001290:	e45e                	sd	s7,8(sp)
    80001292:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001294:	03459793          	slli	a5,a1,0x34
    80001298:	e795                	bnez	a5,800012c4 <uvmunmap+0x46>
    8000129a:	8a2a                	mv	s4,a0
    8000129c:	892e                	mv	s2,a1
    8000129e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	0632                	slli	a2,a2,0xc
    800012a2:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a6:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a8:	6b05                	lui	s6,0x1
    800012aa:	0735e863          	bltu	a1,s3,8000131a <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012ae:	60a6                	ld	ra,72(sp)
    800012b0:	6406                	ld	s0,64(sp)
    800012b2:	74e2                	ld	s1,56(sp)
    800012b4:	7942                	ld	s2,48(sp)
    800012b6:	79a2                	ld	s3,40(sp)
    800012b8:	7a02                	ld	s4,32(sp)
    800012ba:	6ae2                	ld	s5,24(sp)
    800012bc:	6b42                	ld	s6,16(sp)
    800012be:	6ba2                	ld	s7,8(sp)
    800012c0:	6161                	addi	sp,sp,80
    800012c2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c4:	00008517          	auipc	a0,0x8
    800012c8:	e3c50513          	addi	a0,a0,-452 # 80009100 <digits+0xc0>
    800012cc:	fffff097          	auipc	ra,0xfffff
    800012d0:	272080e7          	jalr	626(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012d4:	00008517          	auipc	a0,0x8
    800012d8:	e4450513          	addi	a0,a0,-444 # 80009118 <digits+0xd8>
    800012dc:	fffff097          	auipc	ra,0xfffff
    800012e0:	262080e7          	jalr	610(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012e4:	00008517          	auipc	a0,0x8
    800012e8:	e4450513          	addi	a0,a0,-444 # 80009128 <digits+0xe8>
    800012ec:	fffff097          	auipc	ra,0xfffff
    800012f0:	252080e7          	jalr	594(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012f4:	00008517          	auipc	a0,0x8
    800012f8:	e4c50513          	addi	a0,a0,-436 # 80009140 <digits+0x100>
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	242080e7          	jalr	578(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    80001304:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001306:	0532                	slli	a0,a0,0xc
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	6f0080e7          	jalr	1776(ra) # 800009f8 <kfree>
    *pte = 0;
    80001310:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001314:	995a                	add	s2,s2,s6
    80001316:	f9397ce3          	bgeu	s2,s3,800012ae <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131a:	4601                	li	a2,0
    8000131c:	85ca                	mv	a1,s2
    8000131e:	8552                	mv	a0,s4
    80001320:	00000097          	auipc	ra,0x0
    80001324:	cb0080e7          	jalr	-848(ra) # 80000fd0 <walk>
    80001328:	84aa                	mv	s1,a0
    8000132a:	d54d                	beqz	a0,800012d4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132c:	6108                	ld	a0,0(a0)
    8000132e:	00157793          	andi	a5,a0,1
    80001332:	dbcd                	beqz	a5,800012e4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001334:	3ff57793          	andi	a5,a0,1023
    80001338:	fb778ee3          	beq	a5,s7,800012f4 <uvmunmap+0x76>
    if(do_free){
    8000133c:	fc0a8ae3          	beqz	s5,80001310 <uvmunmap+0x92>
    80001340:	b7d1                	j	80001304 <uvmunmap+0x86>

0000000080001342 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001342:	1101                	addi	sp,sp,-32
    80001344:	ec06                	sd	ra,24(sp)
    80001346:	e822                	sd	s0,16(sp)
    80001348:	e426                	sd	s1,8(sp)
    8000134a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134c:	fffff097          	auipc	ra,0xfffff
    80001350:	7a8080e7          	jalr	1960(ra) # 80000af4 <kalloc>
    80001354:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001356:	c519                	beqz	a0,80001364 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001358:	6605                	lui	a2,0x1
    8000135a:	4581                	li	a1,0
    8000135c:	00000097          	auipc	ra,0x0
    80001360:	984080e7          	jalr	-1660(ra) # 80000ce0 <memset>
  return pagetable;
}
    80001364:	8526                	mv	a0,s1
    80001366:	60e2                	ld	ra,24(sp)
    80001368:	6442                	ld	s0,16(sp)
    8000136a:	64a2                	ld	s1,8(sp)
    8000136c:	6105                	addi	sp,sp,32
    8000136e:	8082                	ret

0000000080001370 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001370:	7179                	addi	sp,sp,-48
    80001372:	f406                	sd	ra,40(sp)
    80001374:	f022                	sd	s0,32(sp)
    80001376:	ec26                	sd	s1,24(sp)
    80001378:	e84a                	sd	s2,16(sp)
    8000137a:	e44e                	sd	s3,8(sp)
    8000137c:	e052                	sd	s4,0(sp)
    8000137e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001380:	6785                	lui	a5,0x1
    80001382:	04f67863          	bgeu	a2,a5,800013d2 <uvminit+0x62>
    80001386:	8a2a                	mv	s4,a0
    80001388:	89ae                	mv	s3,a1
    8000138a:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000138c:	fffff097          	auipc	ra,0xfffff
    80001390:	768080e7          	jalr	1896(ra) # 80000af4 <kalloc>
    80001394:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001396:	6605                	lui	a2,0x1
    80001398:	4581                	li	a1,0
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	946080e7          	jalr	-1722(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a2:	4779                	li	a4,30
    800013a4:	86ca                	mv	a3,s2
    800013a6:	6605                	lui	a2,0x1
    800013a8:	4581                	li	a1,0
    800013aa:	8552                	mv	a0,s4
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	d0c080e7          	jalr	-756(ra) # 800010b8 <mappages>
  memmove(mem, src, sz);
    800013b4:	8626                	mv	a2,s1
    800013b6:	85ce                	mv	a1,s3
    800013b8:	854a                	mv	a0,s2
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	986080e7          	jalr	-1658(ra) # 80000d40 <memmove>
}
    800013c2:	70a2                	ld	ra,40(sp)
    800013c4:	7402                	ld	s0,32(sp)
    800013c6:	64e2                	ld	s1,24(sp)
    800013c8:	6942                	ld	s2,16(sp)
    800013ca:	69a2                	ld	s3,8(sp)
    800013cc:	6a02                	ld	s4,0(sp)
    800013ce:	6145                	addi	sp,sp,48
    800013d0:	8082                	ret
    panic("inituvm: more than a page");
    800013d2:	00008517          	auipc	a0,0x8
    800013d6:	d8650513          	addi	a0,a0,-634 # 80009158 <digits+0x118>
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	164080e7          	jalr	356(ra) # 8000053e <panic>

00000000800013e2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e2:	1101                	addi	sp,sp,-32
    800013e4:	ec06                	sd	ra,24(sp)
    800013e6:	e822                	sd	s0,16(sp)
    800013e8:	e426                	sd	s1,8(sp)
    800013ea:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ec:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ee:	00b67d63          	bgeu	a2,a1,80001408 <uvmdealloc+0x26>
    800013f2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f4:	6785                	lui	a5,0x1
    800013f6:	17fd                	addi	a5,a5,-1
    800013f8:	00f60733          	add	a4,a2,a5
    800013fc:	767d                	lui	a2,0xfffff
    800013fe:	8f71                	and	a4,a4,a2
    80001400:	97ae                	add	a5,a5,a1
    80001402:	8ff1                	and	a5,a5,a2
    80001404:	00f76863          	bltu	a4,a5,80001414 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001408:	8526                	mv	a0,s1
    8000140a:	60e2                	ld	ra,24(sp)
    8000140c:	6442                	ld	s0,16(sp)
    8000140e:	64a2                	ld	s1,8(sp)
    80001410:	6105                	addi	sp,sp,32
    80001412:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001414:	8f99                	sub	a5,a5,a4
    80001416:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001418:	4685                	li	a3,1
    8000141a:	0007861b          	sext.w	a2,a5
    8000141e:	85ba                	mv	a1,a4
    80001420:	00000097          	auipc	ra,0x0
    80001424:	e5e080e7          	jalr	-418(ra) # 8000127e <uvmunmap>
    80001428:	b7c5                	j	80001408 <uvmdealloc+0x26>

000000008000142a <uvmalloc>:
  if(newsz < oldsz)
    8000142a:	0ab66163          	bltu	a2,a1,800014cc <uvmalloc+0xa2>
{
    8000142e:	7139                	addi	sp,sp,-64
    80001430:	fc06                	sd	ra,56(sp)
    80001432:	f822                	sd	s0,48(sp)
    80001434:	f426                	sd	s1,40(sp)
    80001436:	f04a                	sd	s2,32(sp)
    80001438:	ec4e                	sd	s3,24(sp)
    8000143a:	e852                	sd	s4,16(sp)
    8000143c:	e456                	sd	s5,8(sp)
    8000143e:	0080                	addi	s0,sp,64
    80001440:	8aaa                	mv	s5,a0
    80001442:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001444:	6985                	lui	s3,0x1
    80001446:	19fd                	addi	s3,s3,-1
    80001448:	95ce                	add	a1,a1,s3
    8000144a:	79fd                	lui	s3,0xfffff
    8000144c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001450:	08c9f063          	bgeu	s3,a2,800014d0 <uvmalloc+0xa6>
    80001454:	894e                	mv	s2,s3
    mem = kalloc();
    80001456:	fffff097          	auipc	ra,0xfffff
    8000145a:	69e080e7          	jalr	1694(ra) # 80000af4 <kalloc>
    8000145e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001460:	c51d                	beqz	a0,8000148e <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001462:	6605                	lui	a2,0x1
    80001464:	4581                	li	a1,0
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	87a080e7          	jalr	-1926(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000146e:	4779                	li	a4,30
    80001470:	86a6                	mv	a3,s1
    80001472:	6605                	lui	a2,0x1
    80001474:	85ca                	mv	a1,s2
    80001476:	8556                	mv	a0,s5
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	c40080e7          	jalr	-960(ra) # 800010b8 <mappages>
    80001480:	e905                	bnez	a0,800014b0 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001482:	6785                	lui	a5,0x1
    80001484:	993e                	add	s2,s2,a5
    80001486:	fd4968e3          	bltu	s2,s4,80001456 <uvmalloc+0x2c>
  return newsz;
    8000148a:	8552                	mv	a0,s4
    8000148c:	a809                	j	8000149e <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000148e:	864e                	mv	a2,s3
    80001490:	85ca                	mv	a1,s2
    80001492:	8556                	mv	a0,s5
    80001494:	00000097          	auipc	ra,0x0
    80001498:	f4e080e7          	jalr	-178(ra) # 800013e2 <uvmdealloc>
      return 0;
    8000149c:	4501                	li	a0,0
}
    8000149e:	70e2                	ld	ra,56(sp)
    800014a0:	7442                	ld	s0,48(sp)
    800014a2:	74a2                	ld	s1,40(sp)
    800014a4:	7902                	ld	s2,32(sp)
    800014a6:	69e2                	ld	s3,24(sp)
    800014a8:	6a42                	ld	s4,16(sp)
    800014aa:	6aa2                	ld	s5,8(sp)
    800014ac:	6121                	addi	sp,sp,64
    800014ae:	8082                	ret
      kfree(mem);
    800014b0:	8526                	mv	a0,s1
    800014b2:	fffff097          	auipc	ra,0xfffff
    800014b6:	546080e7          	jalr	1350(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014ba:	864e                	mv	a2,s3
    800014bc:	85ca                	mv	a1,s2
    800014be:	8556                	mv	a0,s5
    800014c0:	00000097          	auipc	ra,0x0
    800014c4:	f22080e7          	jalr	-222(ra) # 800013e2 <uvmdealloc>
      return 0;
    800014c8:	4501                	li	a0,0
    800014ca:	bfd1                	j	8000149e <uvmalloc+0x74>
    return oldsz;
    800014cc:	852e                	mv	a0,a1
}
    800014ce:	8082                	ret
  return newsz;
    800014d0:	8532                	mv	a0,a2
    800014d2:	b7f1                	j	8000149e <uvmalloc+0x74>

00000000800014d4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014d4:	7179                	addi	sp,sp,-48
    800014d6:	f406                	sd	ra,40(sp)
    800014d8:	f022                	sd	s0,32(sp)
    800014da:	ec26                	sd	s1,24(sp)
    800014dc:	e84a                	sd	s2,16(sp)
    800014de:	e44e                	sd	s3,8(sp)
    800014e0:	e052                	sd	s4,0(sp)
    800014e2:	1800                	addi	s0,sp,48
    800014e4:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014e6:	84aa                	mv	s1,a0
    800014e8:	6905                	lui	s2,0x1
    800014ea:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014ec:	4985                	li	s3,1
    800014ee:	a821                	j	80001506 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014f0:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014f2:	0532                	slli	a0,a0,0xc
    800014f4:	00000097          	auipc	ra,0x0
    800014f8:	fe0080e7          	jalr	-32(ra) # 800014d4 <freewalk>
      pagetable[i] = 0;
    800014fc:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001500:	04a1                	addi	s1,s1,8
    80001502:	03248163          	beq	s1,s2,80001524 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001506:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001508:	00f57793          	andi	a5,a0,15
    8000150c:	ff3782e3          	beq	a5,s3,800014f0 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001510:	8905                	andi	a0,a0,1
    80001512:	d57d                	beqz	a0,80001500 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001514:	00008517          	auipc	a0,0x8
    80001518:	c6450513          	addi	a0,a0,-924 # 80009178 <digits+0x138>
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	022080e7          	jalr	34(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001524:	8552                	mv	a0,s4
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	4d2080e7          	jalr	1234(ra) # 800009f8 <kfree>
}
    8000152e:	70a2                	ld	ra,40(sp)
    80001530:	7402                	ld	s0,32(sp)
    80001532:	64e2                	ld	s1,24(sp)
    80001534:	6942                	ld	s2,16(sp)
    80001536:	69a2                	ld	s3,8(sp)
    80001538:	6a02                	ld	s4,0(sp)
    8000153a:	6145                	addi	sp,sp,48
    8000153c:	8082                	ret

000000008000153e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000153e:	1101                	addi	sp,sp,-32
    80001540:	ec06                	sd	ra,24(sp)
    80001542:	e822                	sd	s0,16(sp)
    80001544:	e426                	sd	s1,8(sp)
    80001546:	1000                	addi	s0,sp,32
    80001548:	84aa                	mv	s1,a0
  if(sz > 0)
    8000154a:	e999                	bnez	a1,80001560 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000154c:	8526                	mv	a0,s1
    8000154e:	00000097          	auipc	ra,0x0
    80001552:	f86080e7          	jalr	-122(ra) # 800014d4 <freewalk>
}
    80001556:	60e2                	ld	ra,24(sp)
    80001558:	6442                	ld	s0,16(sp)
    8000155a:	64a2                	ld	s1,8(sp)
    8000155c:	6105                	addi	sp,sp,32
    8000155e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001560:	6605                	lui	a2,0x1
    80001562:	167d                	addi	a2,a2,-1
    80001564:	962e                	add	a2,a2,a1
    80001566:	4685                	li	a3,1
    80001568:	8231                	srli	a2,a2,0xc
    8000156a:	4581                	li	a1,0
    8000156c:	00000097          	auipc	ra,0x0
    80001570:	d12080e7          	jalr	-750(ra) # 8000127e <uvmunmap>
    80001574:	bfe1                	j	8000154c <uvmfree+0xe>

0000000080001576 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001576:	c679                	beqz	a2,80001644 <uvmcopy+0xce>
{
    80001578:	715d                	addi	sp,sp,-80
    8000157a:	e486                	sd	ra,72(sp)
    8000157c:	e0a2                	sd	s0,64(sp)
    8000157e:	fc26                	sd	s1,56(sp)
    80001580:	f84a                	sd	s2,48(sp)
    80001582:	f44e                	sd	s3,40(sp)
    80001584:	f052                	sd	s4,32(sp)
    80001586:	ec56                	sd	s5,24(sp)
    80001588:	e85a                	sd	s6,16(sp)
    8000158a:	e45e                	sd	s7,8(sp)
    8000158c:	0880                	addi	s0,sp,80
    8000158e:	8b2a                	mv	s6,a0
    80001590:	8aae                	mv	s5,a1
    80001592:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001594:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001596:	4601                	li	a2,0
    80001598:	85ce                	mv	a1,s3
    8000159a:	855a                	mv	a0,s6
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	a34080e7          	jalr	-1484(ra) # 80000fd0 <walk>
    800015a4:	c531                	beqz	a0,800015f0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015a6:	6118                	ld	a4,0(a0)
    800015a8:	00177793          	andi	a5,a4,1
    800015ac:	cbb1                	beqz	a5,80001600 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015ae:	00a75593          	srli	a1,a4,0xa
    800015b2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015b6:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	53a080e7          	jalr	1338(ra) # 80000af4 <kalloc>
    800015c2:	892a                	mv	s2,a0
    800015c4:	c939                	beqz	a0,8000161a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015c6:	6605                	lui	a2,0x1
    800015c8:	85de                	mv	a1,s7
    800015ca:	fffff097          	auipc	ra,0xfffff
    800015ce:	776080e7          	jalr	1910(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015d2:	8726                	mv	a4,s1
    800015d4:	86ca                	mv	a3,s2
    800015d6:	6605                	lui	a2,0x1
    800015d8:	85ce                	mv	a1,s3
    800015da:	8556                	mv	a0,s5
    800015dc:	00000097          	auipc	ra,0x0
    800015e0:	adc080e7          	jalr	-1316(ra) # 800010b8 <mappages>
    800015e4:	e515                	bnez	a0,80001610 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015e6:	6785                	lui	a5,0x1
    800015e8:	99be                	add	s3,s3,a5
    800015ea:	fb49e6e3          	bltu	s3,s4,80001596 <uvmcopy+0x20>
    800015ee:	a081                	j	8000162e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015f0:	00008517          	auipc	a0,0x8
    800015f4:	b9850513          	addi	a0,a0,-1128 # 80009188 <digits+0x148>
    800015f8:	fffff097          	auipc	ra,0xfffff
    800015fc:	f46080e7          	jalr	-186(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001600:	00008517          	auipc	a0,0x8
    80001604:	ba850513          	addi	a0,a0,-1112 # 800091a8 <digits+0x168>
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	f36080e7          	jalr	-202(ra) # 8000053e <panic>
      kfree(mem);
    80001610:	854a                	mv	a0,s2
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	3e6080e7          	jalr	998(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000161a:	4685                	li	a3,1
    8000161c:	00c9d613          	srli	a2,s3,0xc
    80001620:	4581                	li	a1,0
    80001622:	8556                	mv	a0,s5
    80001624:	00000097          	auipc	ra,0x0
    80001628:	c5a080e7          	jalr	-934(ra) # 8000127e <uvmunmap>
  return -1;
    8000162c:	557d                	li	a0,-1
}
    8000162e:	60a6                	ld	ra,72(sp)
    80001630:	6406                	ld	s0,64(sp)
    80001632:	74e2                	ld	s1,56(sp)
    80001634:	7942                	ld	s2,48(sp)
    80001636:	79a2                	ld	s3,40(sp)
    80001638:	7a02                	ld	s4,32(sp)
    8000163a:	6ae2                	ld	s5,24(sp)
    8000163c:	6b42                	ld	s6,16(sp)
    8000163e:	6ba2                	ld	s7,8(sp)
    80001640:	6161                	addi	sp,sp,80
    80001642:	8082                	ret
  return 0;
    80001644:	4501                	li	a0,0
}
    80001646:	8082                	ret

0000000080001648 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001648:	1141                	addi	sp,sp,-16
    8000164a:	e406                	sd	ra,8(sp)
    8000164c:	e022                	sd	s0,0(sp)
    8000164e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001650:	4601                	li	a2,0
    80001652:	00000097          	auipc	ra,0x0
    80001656:	97e080e7          	jalr	-1666(ra) # 80000fd0 <walk>
  if(pte == 0)
    8000165a:	c901                	beqz	a0,8000166a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000165c:	611c                	ld	a5,0(a0)
    8000165e:	9bbd                	andi	a5,a5,-17
    80001660:	e11c                	sd	a5,0(a0)
}
    80001662:	60a2                	ld	ra,8(sp)
    80001664:	6402                	ld	s0,0(sp)
    80001666:	0141                	addi	sp,sp,16
    80001668:	8082                	ret
    panic("uvmclear");
    8000166a:	00008517          	auipc	a0,0x8
    8000166e:	b5e50513          	addi	a0,a0,-1186 # 800091c8 <digits+0x188>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ecc080e7          	jalr	-308(ra) # 8000053e <panic>

000000008000167a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000167a:	c6bd                	beqz	a3,800016e8 <copyout+0x6e>
{
    8000167c:	715d                	addi	sp,sp,-80
    8000167e:	e486                	sd	ra,72(sp)
    80001680:	e0a2                	sd	s0,64(sp)
    80001682:	fc26                	sd	s1,56(sp)
    80001684:	f84a                	sd	s2,48(sp)
    80001686:	f44e                	sd	s3,40(sp)
    80001688:	f052                	sd	s4,32(sp)
    8000168a:	ec56                	sd	s5,24(sp)
    8000168c:	e85a                	sd	s6,16(sp)
    8000168e:	e45e                	sd	s7,8(sp)
    80001690:	e062                	sd	s8,0(sp)
    80001692:	0880                	addi	s0,sp,80
    80001694:	8b2a                	mv	s6,a0
    80001696:	8c2e                	mv	s8,a1
    80001698:	8a32                	mv	s4,a2
    8000169a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000169c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000169e:	6a85                	lui	s5,0x1
    800016a0:	a015                	j	800016c4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016a2:	9562                	add	a0,a0,s8
    800016a4:	0004861b          	sext.w	a2,s1
    800016a8:	85d2                	mv	a1,s4
    800016aa:	41250533          	sub	a0,a0,s2
    800016ae:	fffff097          	auipc	ra,0xfffff
    800016b2:	692080e7          	jalr	1682(ra) # 80000d40 <memmove>

    len -= n;
    800016b6:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ba:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016bc:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016c0:	02098263          	beqz	s3,800016e4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016c4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c8:	85ca                	mv	a1,s2
    800016ca:	855a                	mv	a0,s6
    800016cc:	00000097          	auipc	ra,0x0
    800016d0:	9aa080e7          	jalr	-1622(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800016d4:	cd01                	beqz	a0,800016ec <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016d6:	418904b3          	sub	s1,s2,s8
    800016da:	94d6                	add	s1,s1,s5
    if(n > len)
    800016dc:	fc99f3e3          	bgeu	s3,s1,800016a2 <copyout+0x28>
    800016e0:	84ce                	mv	s1,s3
    800016e2:	b7c1                	j	800016a2 <copyout+0x28>
  }
  return 0;
    800016e4:	4501                	li	a0,0
    800016e6:	a021                	j	800016ee <copyout+0x74>
    800016e8:	4501                	li	a0,0
}
    800016ea:	8082                	ret
      return -1;
    800016ec:	557d                	li	a0,-1
}
    800016ee:	60a6                	ld	ra,72(sp)
    800016f0:	6406                	ld	s0,64(sp)
    800016f2:	74e2                	ld	s1,56(sp)
    800016f4:	7942                	ld	s2,48(sp)
    800016f6:	79a2                	ld	s3,40(sp)
    800016f8:	7a02                	ld	s4,32(sp)
    800016fa:	6ae2                	ld	s5,24(sp)
    800016fc:	6b42                	ld	s6,16(sp)
    800016fe:	6ba2                	ld	s7,8(sp)
    80001700:	6c02                	ld	s8,0(sp)
    80001702:	6161                	addi	sp,sp,80
    80001704:	8082                	ret

0000000080001706 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001706:	c6bd                	beqz	a3,80001774 <copyin+0x6e>
{
    80001708:	715d                	addi	sp,sp,-80
    8000170a:	e486                	sd	ra,72(sp)
    8000170c:	e0a2                	sd	s0,64(sp)
    8000170e:	fc26                	sd	s1,56(sp)
    80001710:	f84a                	sd	s2,48(sp)
    80001712:	f44e                	sd	s3,40(sp)
    80001714:	f052                	sd	s4,32(sp)
    80001716:	ec56                	sd	s5,24(sp)
    80001718:	e85a                	sd	s6,16(sp)
    8000171a:	e45e                	sd	s7,8(sp)
    8000171c:	e062                	sd	s8,0(sp)
    8000171e:	0880                	addi	s0,sp,80
    80001720:	8b2a                	mv	s6,a0
    80001722:	8a2e                	mv	s4,a1
    80001724:	8c32                	mv	s8,a2
    80001726:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001728:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000172a:	6a85                	lui	s5,0x1
    8000172c:	a015                	j	80001750 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000172e:	9562                	add	a0,a0,s8
    80001730:	0004861b          	sext.w	a2,s1
    80001734:	412505b3          	sub	a1,a0,s2
    80001738:	8552                	mv	a0,s4
    8000173a:	fffff097          	auipc	ra,0xfffff
    8000173e:	606080e7          	jalr	1542(ra) # 80000d40 <memmove>

    len -= n;
    80001742:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001746:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001748:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000174c:	02098263          	beqz	s3,80001770 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001750:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001754:	85ca                	mv	a1,s2
    80001756:	855a                	mv	a0,s6
    80001758:	00000097          	auipc	ra,0x0
    8000175c:	91e080e7          	jalr	-1762(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001760:	cd01                	beqz	a0,80001778 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001762:	418904b3          	sub	s1,s2,s8
    80001766:	94d6                	add	s1,s1,s5
    if(n > len)
    80001768:	fc99f3e3          	bgeu	s3,s1,8000172e <copyin+0x28>
    8000176c:	84ce                	mv	s1,s3
    8000176e:	b7c1                	j	8000172e <copyin+0x28>
  }
  return 0;
    80001770:	4501                	li	a0,0
    80001772:	a021                	j	8000177a <copyin+0x74>
    80001774:	4501                	li	a0,0
}
    80001776:	8082                	ret
      return -1;
    80001778:	557d                	li	a0,-1
}
    8000177a:	60a6                	ld	ra,72(sp)
    8000177c:	6406                	ld	s0,64(sp)
    8000177e:	74e2                	ld	s1,56(sp)
    80001780:	7942                	ld	s2,48(sp)
    80001782:	79a2                	ld	s3,40(sp)
    80001784:	7a02                	ld	s4,32(sp)
    80001786:	6ae2                	ld	s5,24(sp)
    80001788:	6b42                	ld	s6,16(sp)
    8000178a:	6ba2                	ld	s7,8(sp)
    8000178c:	6c02                	ld	s8,0(sp)
    8000178e:	6161                	addi	sp,sp,80
    80001790:	8082                	ret

0000000080001792 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001792:	c6c5                	beqz	a3,8000183a <copyinstr+0xa8>
{
    80001794:	715d                	addi	sp,sp,-80
    80001796:	e486                	sd	ra,72(sp)
    80001798:	e0a2                	sd	s0,64(sp)
    8000179a:	fc26                	sd	s1,56(sp)
    8000179c:	f84a                	sd	s2,48(sp)
    8000179e:	f44e                	sd	s3,40(sp)
    800017a0:	f052                	sd	s4,32(sp)
    800017a2:	ec56                	sd	s5,24(sp)
    800017a4:	e85a                	sd	s6,16(sp)
    800017a6:	e45e                	sd	s7,8(sp)
    800017a8:	0880                	addi	s0,sp,80
    800017aa:	8a2a                	mv	s4,a0
    800017ac:	8b2e                	mv	s6,a1
    800017ae:	8bb2                	mv	s7,a2
    800017b0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017b2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017b4:	6985                	lui	s3,0x1
    800017b6:	a035                	j	800017e2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017bc:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017be:	0017b793          	seqz	a5,a5
    800017c2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017c6:	60a6                	ld	ra,72(sp)
    800017c8:	6406                	ld	s0,64(sp)
    800017ca:	74e2                	ld	s1,56(sp)
    800017cc:	7942                	ld	s2,48(sp)
    800017ce:	79a2                	ld	s3,40(sp)
    800017d0:	7a02                	ld	s4,32(sp)
    800017d2:	6ae2                	ld	s5,24(sp)
    800017d4:	6b42                	ld	s6,16(sp)
    800017d6:	6ba2                	ld	s7,8(sp)
    800017d8:	6161                	addi	sp,sp,80
    800017da:	8082                	ret
    srcva = va0 + PGSIZE;
    800017dc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017e0:	c8a9                	beqz	s1,80001832 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017e2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017e6:	85ca                	mv	a1,s2
    800017e8:	8552                	mv	a0,s4
    800017ea:	00000097          	auipc	ra,0x0
    800017ee:	88c080e7          	jalr	-1908(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800017f2:	c131                	beqz	a0,80001836 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017f4:	41790833          	sub	a6,s2,s7
    800017f8:	984e                	add	a6,a6,s3
    if(n > max)
    800017fa:	0104f363          	bgeu	s1,a6,80001800 <copyinstr+0x6e>
    800017fe:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001800:	955e                	add	a0,a0,s7
    80001802:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001806:	fc080be3          	beqz	a6,800017dc <copyinstr+0x4a>
    8000180a:	985a                	add	a6,a6,s6
    8000180c:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000180e:	41650633          	sub	a2,a0,s6
    80001812:	14fd                	addi	s1,s1,-1
    80001814:	9b26                	add	s6,s6,s1
    80001816:	00f60733          	add	a4,a2,a5
    8000181a:	00074703          	lbu	a4,0(a4)
    8000181e:	df49                	beqz	a4,800017b8 <copyinstr+0x26>
        *dst = *p;
    80001820:	00e78023          	sb	a4,0(a5)
      --max;
    80001824:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001828:	0785                	addi	a5,a5,1
    while(n > 0){
    8000182a:	ff0796e3          	bne	a5,a6,80001816 <copyinstr+0x84>
      dst++;
    8000182e:	8b42                	mv	s6,a6
    80001830:	b775                	j	800017dc <copyinstr+0x4a>
    80001832:	4781                	li	a5,0
    80001834:	b769                	j	800017be <copyinstr+0x2c>
      return -1;
    80001836:	557d                	li	a0,-1
    80001838:	b779                	j	800017c6 <copyinstr+0x34>
  int got_null = 0;
    8000183a:	4781                	li	a5,0
  if(got_null){
    8000183c:	0017b793          	seqz	a5,a5
    80001840:	40f00533          	neg	a0,a5
}
    80001844:	8082                	ret

0000000080001846 <add_proc_to_list>:
extern uint64 cas( volatile void *addr, int expected, int newval);

// Ass2
int
add_proc_to_list(int tail, struct proc *p)
{
    80001846:	1101                	addi	sp,sp,-32
    80001848:	ec06                	sd	ra,24(sp)
    8000184a:	e822                	sd	s0,16(sp)
    8000184c:	e426                	sd	s1,8(sp)
    8000184e:	e04a                	sd	s2,0(sp)
    80001850:	1000                	addi	s0,sp,32
    80001852:	892a                	mv	s2,a0
    80001854:	84ae                	mv	s1,a1
  // if (tail == p->pid)
    // return 0;
  printf("&&&&&&&&&&&&&&&adding: %d,     prev:   %d,   next:  %d\n", p->proc_ind, p->prev_proc, p->next_proc);
    80001856:	51b4                	lw	a3,96(a1)
    80001858:	51f0                	lw	a2,100(a1)
    8000185a:	4dec                	lw	a1,92(a1)
    8000185c:	00008517          	auipc	a0,0x8
    80001860:	97c50513          	addi	a0,a0,-1668 # 800091d8 <digits+0x198>
    80001864:	fffff097          	auipc	ra,0xfffff
    80001868:	d24080e7          	jalr	-732(ra) # 80000588 <printf>
  int p_before = proc[tail].next_proc;
    8000186c:	00011517          	auipc	a0,0x11
    80001870:	f0450513          	addi	a0,a0,-252 # 80012770 <proc>
    80001874:	19800793          	li	a5,408
    80001878:	02f907b3          	mul	a5,s2,a5
    8000187c:	00f50733          	add	a4,a0,a5
  if (cas(&proc[tail].next_proc, p_before, p->proc_ind) == 0)
    80001880:	06078793          	addi	a5,a5,96
    80001884:	4cf0                	lw	a2,92(s1)
    80001886:	532c                	lw	a1,96(a4)
    80001888:	953e                	add	a0,a0,a5
    8000188a:	00006097          	auipc	ra,0x6
    8000188e:	0ec080e7          	jalr	236(ra) # 80007976 <cas>
    80001892:	e51d                	bnez	a0,800018c0 <add_proc_to_list+0x7a>
  {
    p->prev_proc = tail;
    80001894:	0724a223          	sw	s2,100(s1)
    p->next_proc = -1;
    80001898:	57fd                	li	a5,-1
    8000189a:	d0bc                	sw	a5,96(s1)
    printf("&&&&&&&&&&&&&&&adding: %d,     prev:   %d,   next:  %d\n", p->proc_ind, p->prev_proc, p->next_proc);
    8000189c:	56fd                	li	a3,-1
    8000189e:	864a                	mv	a2,s2
    800018a0:	4cec                	lw	a1,92(s1)
    800018a2:	00008517          	auipc	a0,0x8
    800018a6:	93650513          	addi	a0,a0,-1738 # 800091d8 <digits+0x198>
    800018aa:	fffff097          	auipc	ra,0xfffff
    800018ae:	cde080e7          	jalr	-802(ra) # 80000588 <printf>
    return 0;
    800018b2:	4501                	li	a0,0
  }
  return -1;
}
    800018b4:	60e2                	ld	ra,24(sp)
    800018b6:	6442                	ld	s0,16(sp)
    800018b8:	64a2                	ld	s1,8(sp)
    800018ba:	6902                	ld	s2,0(sp)
    800018bc:	6105                	addi	sp,sp,32
    800018be:	8082                	ret
  return -1;
    800018c0:	557d                	li	a0,-1
    800018c2:	bfcd                	j	800018b4 <add_proc_to_list+0x6e>

00000000800018c4 <remove_proc_from_list>:

// Ass2
int
remove_proc_from_list(int ind)
{
    800018c4:	1101                	addi	sp,sp,-32
    800018c6:	ec06                	sd	ra,24(sp)
    800018c8:	e822                	sd	s0,16(sp)
    800018ca:	e426                	sd	s1,8(sp)
    800018cc:	e04a                	sd	s2,0(sp)
    800018ce:	1000                	addi	s0,sp,32
    800018d0:	84aa                	mv	s1,a0
  struct proc *p = &proc[ind];

  printf("######### remove cur: %d,    prev: %d, next: %d   \n", ind, p->prev_proc, p->next_proc);
    800018d2:	19800913          	li	s2,408
    800018d6:	032507b3          	mul	a5,a0,s2
    800018da:	00011917          	auipc	s2,0x11
    800018de:	e9690913          	addi	s2,s2,-362 # 80012770 <proc>
    800018e2:	993e                	add	s2,s2,a5
    800018e4:	06092683          	lw	a3,96(s2)
    800018e8:	06492603          	lw	a2,100(s2)
    800018ec:	85aa                	mv	a1,a0
    800018ee:	00008517          	auipc	a0,0x8
    800018f2:	92250513          	addi	a0,a0,-1758 # 80009210 <digits+0x1d0>
    800018f6:	fffff097          	auipc	ra,0xfffff
    800018fa:	c92080e7          	jalr	-878(ra) # 80000588 <printf>

  if (p->prev_proc == -1 && p->next_proc == -1)
    800018fe:	06093703          	ld	a4,96(s2)
    80001902:	57fd                	li	a5,-1
    return 1;  // Need to change head & tail.
    80001904:	4505                	li	a0,1
  if (p->prev_proc == -1 && p->next_proc == -1)
    80001906:	06f70863          	beq	a4,a5,80001976 <remove_proc_from_list+0xb2>
  
  if (p->prev_proc == -1)
    8000190a:	06492783          	lw	a5,100(s2)
    8000190e:	577d                	li	a4,-1
    80001910:	06e78963          	beq	a5,a4,80001982 <remove_proc_from_list+0xbe>
    return 2;  // Need to change head.

  if (p->next_proc == -1)
    80001914:	06092603          	lw	a2,96(s2)
    80001918:	577d                	li	a4,-1
    return 3;  // Need to change tail.
    8000191a:	450d                	li	a0,3
  if (p->next_proc == -1)
    8000191c:	04e60d63          	beq	a2,a4,80001976 <remove_proc_from_list+0xb2>

  int prev = proc[p->prev_proc].next_proc;
    80001920:	00011517          	auipc	a0,0x11
    80001924:	e5050513          	addi	a0,a0,-432 # 80012770 <proc>
    80001928:	19800713          	li	a4,408
    8000192c:	02e787b3          	mul	a5,a5,a4
    80001930:	00f50733          	add	a4,a0,a5
  if (cas(&proc[p->prev_proc].next_proc, prev, p->next_proc) == 0)
    80001934:	06078793          	addi	a5,a5,96
    80001938:	532c                	lw	a1,96(a4)
    8000193a:	953e                	add	a0,a0,a5
    8000193c:	00006097          	auipc	ra,0x6
    80001940:	03a080e7          	jalr	58(ra) # 80007976 <cas>
    80001944:	e129                	bnez	a0,80001986 <remove_proc_from_list+0xc2>
  {
    proc[p->next_proc].prev_proc = p->prev_proc;
    80001946:	00011797          	auipc	a5,0x11
    8000194a:	e2a78793          	addi	a5,a5,-470 # 80012770 <proc>
    8000194e:	19800713          	li	a4,408
    80001952:	06092683          	lw	a3,96(s2)
    80001956:	06492603          	lw	a2,100(s2)
    8000195a:	02e68733          	mul	a4,a3,a4
    8000195e:	97ba                	add	a5,a5,a4
    80001960:	d3f0                	sw	a2,100(a5)

    printf("######### remove cur: %d,    prev: %d, next: %d   \n", ind, p->prev_proc, p->next_proc);
    80001962:	85a6                	mv	a1,s1
    80001964:	00008517          	auipc	a0,0x8
    80001968:	8ac50513          	addi	a0,a0,-1876 # 80009210 <digits+0x1d0>
    8000196c:	fffff097          	auipc	ra,0xfffff
    80001970:	c1c080e7          	jalr	-996(ra) # 80000588 <printf>
    return 0;
    80001974:	4501                	li	a0,0
  }
  return -1;
}
    80001976:	60e2                	ld	ra,24(sp)
    80001978:	6442                	ld	s0,16(sp)
    8000197a:	64a2                	ld	s1,8(sp)
    8000197c:	6902                	ld	s2,0(sp)
    8000197e:	6105                	addi	sp,sp,32
    80001980:	8082                	ret
    return 2;  // Need to change head.
    80001982:	4509                	li	a0,2
    80001984:	bfcd                	j	80001976 <remove_proc_from_list+0xb2>
  return -1;
    80001986:	557d                	li	a0,-1
    80001988:	b7fd                	j	80001976 <remove_proc_from_list+0xb2>

000000008000198a <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000198a:	7139                	addi	sp,sp,-64
    8000198c:	fc06                	sd	ra,56(sp)
    8000198e:	f822                	sd	s0,48(sp)
    80001990:	f426                	sd	s1,40(sp)
    80001992:	f04a                	sd	s2,32(sp)
    80001994:	ec4e                	sd	s3,24(sp)
    80001996:	e852                	sd	s4,16(sp)
    80001998:	e456                	sd	s5,8(sp)
    8000199a:	e05a                	sd	s6,0(sp)
    8000199c:	0080                	addi	s0,sp,64
    8000199e:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a0:	00011497          	auipc	s1,0x11
    800019a4:	dd048493          	addi	s1,s1,-560 # 80012770 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800019a8:	8b26                	mv	s6,s1
    800019aa:	00007a97          	auipc	s5,0x7
    800019ae:	656a8a93          	addi	s5,s5,1622 # 80009000 <etext>
    800019b2:	04000937          	lui	s2,0x4000
    800019b6:	197d                	addi	s2,s2,-1
    800019b8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ba:	00017a17          	auipc	s4,0x17
    800019be:	3b6a0a13          	addi	s4,s4,950 # 80018d70 <tickslock>
    char *pa = kalloc();
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	132080e7          	jalr	306(ra) # 80000af4 <kalloc>
    800019ca:	862a                	mv	a2,a0
    if(pa == 0)
    800019cc:	c131                	beqz	a0,80001a10 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019ce:	416485b3          	sub	a1,s1,s6
    800019d2:	858d                	srai	a1,a1,0x3
    800019d4:	000ab783          	ld	a5,0(s5)
    800019d8:	02f585b3          	mul	a1,a1,a5
    800019dc:	2585                	addiw	a1,a1,1
    800019de:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019e2:	4719                	li	a4,6
    800019e4:	6685                	lui	a3,0x1
    800019e6:	40b905b3          	sub	a1,s2,a1
    800019ea:	854e                	mv	a0,s3
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	76c080e7          	jalr	1900(ra) # 80001158 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019f4:	19848493          	addi	s1,s1,408
    800019f8:	fd4495e3          	bne	s1,s4,800019c2 <proc_mapstacks+0x38>
  }
}
    800019fc:	70e2                	ld	ra,56(sp)
    800019fe:	7442                	ld	s0,48(sp)
    80001a00:	74a2                	ld	s1,40(sp)
    80001a02:	7902                	ld	s2,32(sp)
    80001a04:	69e2                	ld	s3,24(sp)
    80001a06:	6a42                	ld	s4,16(sp)
    80001a08:	6aa2                	ld	s5,8(sp)
    80001a0a:	6b02                	ld	s6,0(sp)
    80001a0c:	6121                	addi	sp,sp,64
    80001a0e:	8082                	ret
      panic("kalloc");
    80001a10:	00008517          	auipc	a0,0x8
    80001a14:	83850513          	addi	a0,a0,-1992 # 80009248 <digits+0x208>
    80001a18:	fffff097          	auipc	ra,0xfffff
    80001a1c:	b26080e7          	jalr	-1242(ra) # 8000053e <panic>

0000000080001a20 <procinit>:


// initialize the proc table at boot time.
	void
	procinit(void)
	{
    80001a20:	711d                	addi	sp,sp,-96
    80001a22:	ec86                	sd	ra,88(sp)
    80001a24:	e8a2                	sd	s0,80(sp)
    80001a26:	e4a6                	sd	s1,72(sp)
    80001a28:	e0ca                	sd	s2,64(sp)
    80001a2a:	fc4e                	sd	s3,56(sp)
    80001a2c:	f852                	sd	s4,48(sp)
    80001a2e:	f456                	sd	s5,40(sp)
    80001a30:	f05a                	sd	s6,32(sp)
    80001a32:	ec5e                	sd	s7,24(sp)
    80001a34:	e862                	sd	s8,16(sp)
    80001a36:	e466                	sd	s9,8(sp)
    80001a38:	1080                	addi	s0,sp,96
	  struct proc *p;
    int i = 0;
	  
	  initlock(&pid_lock, "nextpid");
    80001a3a:	00008597          	auipc	a1,0x8
    80001a3e:	81658593          	addi	a1,a1,-2026 # 80009250 <digits+0x210>
    80001a42:	00011517          	auipc	a0,0x11
    80001a46:	cfe50513          	addi	a0,a0,-770 # 80012740 <pid_lock>
    80001a4a:	fffff097          	auipc	ra,0xfffff
    80001a4e:	10a080e7          	jalr	266(ra) # 80000b54 <initlock>
	  initlock(&wait_lock, "wait_lock");
    80001a52:	00008597          	auipc	a1,0x8
    80001a56:	80658593          	addi	a1,a1,-2042 # 80009258 <digits+0x218>
    80001a5a:	00011517          	auipc	a0,0x11
    80001a5e:	cfe50513          	addi	a0,a0,-770 # 80012758 <wait_lock>
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	0f2080e7          	jalr	242(ra) # 80000b54 <initlock>
	  for(p = proc; p < &proc[NPROC]; p++) {
	      initlock(&p->lock, "proc");
    80001a6a:	00007597          	auipc	a1,0x7
    80001a6e:	7fe58593          	addi	a1,a1,2046 # 80009268 <digits+0x228>
    80001a72:	00011517          	auipc	a0,0x11
    80001a76:	cfe50513          	addi	a0,a0,-770 # 80012770 <proc>
    80001a7a:	fffff097          	auipc	ra,0xfffff
    80001a7e:	0da080e7          	jalr	218(ra) # 80000b54 <initlock>
	      p->kstack = KSTACK((int) (p - proc));
    80001a82:	00011497          	auipc	s1,0x11
    80001a86:	cee48493          	addi	s1,s1,-786 # 80012770 <proc>
    80001a8a:	040007b7          	lui	a5,0x4000
    80001a8e:	17f5                	addi	a5,a5,-3
    80001a90:	07b2                	slli	a5,a5,0xc
    80001a92:	f8bc                	sd	a5,112(s1)

        p->proc_ind = i;                               // Set index to process.
    80001a94:	0404ae23          	sw	zero,92(s1)
        p->prev_proc = -1;
    80001a98:	57fd                	li	a5,-1
    80001a9a:	d0fc                	sw	a5,100(s1)
        p->next_proc = -1;
    80001a9c:	d0bc                	sw	a5,96(s1)
    int i = 0;
    80001a9e:	4901                	li	s2,0
	  for(p = proc; p < &proc[NPROC]; p++) {
    80001aa0:	00017a97          	auipc	s5,0x17
    80001aa4:	2d0a8a93          	addi	s5,s5,720 # 80018d70 <tickslock>
	      p->kstack = KSTACK((int) (p - proc));
    80001aa8:	8ba6                	mv	s7,s1
    80001aaa:	00007b17          	auipc	s6,0x7
    80001aae:	556b0b13          	addi	s6,s6,1366 # 80009000 <etext>
    80001ab2:	04000a37          	lui	s4,0x4000
    80001ab6:	1a7d                	addi	s4,s4,-1
    80001ab8:	0a32                	slli	s4,s4,0xc
        if (i != 0)
        {
          printf("unused");
          add_proc_to_list(unused_list_tail, p);
    80001aba:	00008c17          	auipc	s8,0x8
    80001abe:	1f6c0c13          	addi	s8,s8,502 # 80009cb0 <unused_list_tail>
          if (unused_list_head == -1)
    80001ac2:	00008c97          	auipc	s9,0x8
    80001ac6:	1f2c8c93          	addi	s9,s9,498 # 80009cb4 <unused_list_head>
    80001aca:	a021                	j	80001ad2 <procinit+0xb2>
          {
            unused_list_head = p->proc_ind;
          }
            unused_list_tail = p->proc_ind;             // After adding to list, updating tail.
    80001acc:	4cfc                	lw	a5,92(s1)
    80001ace:	00fc2023          	sw	a5,0(s8)
        }
        i ++;
    80001ad2:	0019099b          	addiw	s3,s2,1
    80001ad6:	0009891b          	sext.w	s2,s3
	  for(p = proc; p < &proc[NPROC]; p++) {
    80001ada:	19848493          	addi	s1,s1,408
    80001ade:	07548763          	beq	s1,s5,80001b4c <procinit+0x12c>
	      initlock(&p->lock, "proc");
    80001ae2:	00007597          	auipc	a1,0x7
    80001ae6:	78658593          	addi	a1,a1,1926 # 80009268 <digits+0x228>
    80001aea:	8526                	mv	a0,s1
    80001aec:	fffff097          	auipc	ra,0xfffff
    80001af0:	068080e7          	jalr	104(ra) # 80000b54 <initlock>
	      p->kstack = KSTACK((int) (p - proc));
    80001af4:	417487b3          	sub	a5,s1,s7
    80001af8:	878d                	srai	a5,a5,0x3
    80001afa:	000b3703          	ld	a4,0(s6)
    80001afe:	02e787b3          	mul	a5,a5,a4
    80001b02:	2785                	addiw	a5,a5,1
    80001b04:	00d7979b          	slliw	a5,a5,0xd
    80001b08:	40fa07b3          	sub	a5,s4,a5
    80001b0c:	f8bc                	sd	a5,112(s1)
        p->proc_ind = i;                               // Set index to process.
    80001b0e:	0534ae23          	sw	s3,92(s1)
        p->prev_proc = -1;
    80001b12:	57fd                	li	a5,-1
    80001b14:	d0fc                	sw	a5,100(s1)
        p->next_proc = -1;
    80001b16:	d0bc                	sw	a5,96(s1)
        if (i != 0)
    80001b18:	fa090de3          	beqz	s2,80001ad2 <procinit+0xb2>
          printf("unused");
    80001b1c:	00007517          	auipc	a0,0x7
    80001b20:	75450513          	addi	a0,a0,1876 # 80009270 <digits+0x230>
    80001b24:	fffff097          	auipc	ra,0xfffff
    80001b28:	a64080e7          	jalr	-1436(ra) # 80000588 <printf>
          add_proc_to_list(unused_list_tail, p);
    80001b2c:	85a6                	mv	a1,s1
    80001b2e:	000c2503          	lw	a0,0(s8)
    80001b32:	00000097          	auipc	ra,0x0
    80001b36:	d14080e7          	jalr	-748(ra) # 80001846 <add_proc_to_list>
          if (unused_list_head == -1)
    80001b3a:	000ca703          	lw	a4,0(s9)
    80001b3e:	57fd                	li	a5,-1
    80001b40:	f8f716e3          	bne	a4,a5,80001acc <procinit+0xac>
            unused_list_head = p->proc_ind;
    80001b44:	4cfc                	lw	a5,92(s1)
    80001b46:	00fca023          	sw	a5,0(s9)
    80001b4a:	b749                	j	80001acc <procinit+0xac>
      }
  struct cpu *c;
  for(c = cpus; c < &cpus[NCPU]; c++)
    80001b4c:	00010797          	auipc	a5,0x10
    80001b50:	77478793          	addi	a5,a5,1908 # 800122c0 <cpus>
  {
    c->runnable_list_head = -1;
    80001b54:	577d                	li	a4,-1
  for(c = cpus; c < &cpus[NCPU]; c++)
    80001b56:	00011697          	auipc	a3,0x11
    80001b5a:	bea68693          	addi	a3,a3,-1046 # 80012740 <pid_lock>
    c->runnable_list_head = -1;
    80001b5e:	08e7a023          	sw	a4,128(a5)
    c->runnable_list_tail = -1;
    80001b62:	08e7a223          	sw	a4,132(a5)
  for(c = cpus; c < &cpus[NCPU]; c++)
    80001b66:	09078793          	addi	a5,a5,144
    80001b6a:	fed79ae3          	bne	a5,a3,80001b5e <procinit+0x13e>
  }
}
    80001b6e:	60e6                	ld	ra,88(sp)
    80001b70:	6446                	ld	s0,80(sp)
    80001b72:	64a6                	ld	s1,72(sp)
    80001b74:	6906                	ld	s2,64(sp)
    80001b76:	79e2                	ld	s3,56(sp)
    80001b78:	7a42                	ld	s4,48(sp)
    80001b7a:	7aa2                	ld	s5,40(sp)
    80001b7c:	7b02                	ld	s6,32(sp)
    80001b7e:	6be2                	ld	s7,24(sp)
    80001b80:	6c42                	ld	s8,16(sp)
    80001b82:	6ca2                	ld	s9,8(sp)
    80001b84:	6125                	addi	sp,sp,96
    80001b86:	8082                	ret

0000000080001b88 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001b88:	1141                	addi	sp,sp,-16
    80001b8a:	e422                	sd	s0,8(sp)
    80001b8c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b8e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b90:	2501                	sext.w	a0,a0
    80001b92:	6422                	ld	s0,8(sp)
    80001b94:	0141                	addi	sp,sp,16
    80001b96:	8082                	ret

0000000080001b98 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001b98:	1141                	addi	sp,sp,-16
    80001b9a:	e422                	sd	s0,8(sp)
    80001b9c:	0800                	addi	s0,sp,16
    80001b9e:	8792                	mv	a5,tp
  int id = r_tp();
    80001ba0:	0007871b          	sext.w	a4,a5
  int id = cpuid();
  struct cpu *c = &cpus[id];
  c->cpu_id = id;
    80001ba4:	00010517          	auipc	a0,0x10
    80001ba8:	71c50513          	addi	a0,a0,1820 # 800122c0 <cpus>
    80001bac:	00371793          	slli	a5,a4,0x3
    80001bb0:	00e786b3          	add	a3,a5,a4
    80001bb4:	0692                	slli	a3,a3,0x4
    80001bb6:	96aa                	add	a3,a3,a0
    80001bb8:	08e6a423          	sw	a4,136(a3)
  return c;
}
    80001bbc:	8536                	mv	a0,a3
    80001bbe:	6422                	ld	s0,8(sp)
    80001bc0:	0141                	addi	sp,sp,16
    80001bc2:	8082                	ret

0000000080001bc4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001bc4:	1101                	addi	sp,sp,-32
    80001bc6:	ec06                	sd	ra,24(sp)
    80001bc8:	e822                	sd	s0,16(sp)
    80001bca:	e426                	sd	s1,8(sp)
    80001bcc:	1000                	addi	s0,sp,32
  push_off();
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	fca080e7          	jalr	-54(ra) # 80000b98 <push_off>
    80001bd6:	8792                	mv	a5,tp
  int id = r_tp();
    80001bd8:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80001bdc:	00010617          	auipc	a2,0x10
    80001be0:	6e460613          	addi	a2,a2,1764 # 800122c0 <cpus>
    80001be4:	00371793          	slli	a5,a4,0x3
    80001be8:	00e786b3          	add	a3,a5,a4
    80001bec:	0692                	slli	a3,a3,0x4
    80001bee:	96b2                	add	a3,a3,a2
    80001bf0:	08e6a423          	sw	a4,136(a3)
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001bf4:	6284                	ld	s1,0(a3)
  pop_off();
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	042080e7          	jalr	66(ra) # 80000c38 <pop_off>
  return p;
}
    80001bfe:	8526                	mv	a0,s1
    80001c00:	60e2                	ld	ra,24(sp)
    80001c02:	6442                	ld	s0,16(sp)
    80001c04:	64a2                	ld	s1,8(sp)
    80001c06:	6105                	addi	sp,sp,32
    80001c08:	8082                	ret

0000000080001c0a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001c0a:	1141                	addi	sp,sp,-16
    80001c0c:	e406                	sd	ra,8(sp)
    80001c0e:	e022                	sd	s0,0(sp)
    80001c10:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001c12:	00000097          	auipc	ra,0x0
    80001c16:	fb2080e7          	jalr	-78(ra) # 80001bc4 <myproc>
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	07e080e7          	jalr	126(ra) # 80000c98 <release>

  if (first) {
    80001c22:	00008797          	auipc	a5,0x8
    80001c26:	07e7a783          	lw	a5,126(a5) # 80009ca0 <first.1780>
    80001c2a:	eb89                	bnez	a5,80001c3c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c2c:	00002097          	auipc	ra,0x2
    80001c30:	13a080e7          	jalr	314(ra) # 80003d66 <usertrapret>
}
    80001c34:	60a2                	ld	ra,8(sp)
    80001c36:	6402                	ld	s0,0(sp)
    80001c38:	0141                	addi	sp,sp,16
    80001c3a:	8082                	ret
    first = 0;
    80001c3c:	00008797          	auipc	a5,0x8
    80001c40:	0607a223          	sw	zero,100(a5) # 80009ca0 <first.1780>
    fsinit(ROOTDEV);
    80001c44:	4505                	li	a0,1
    80001c46:	00003097          	auipc	ra,0x3
    80001c4a:	f1c080e7          	jalr	-228(ra) # 80004b62 <fsinit>
    80001c4e:	bff9                	j	80001c2c <forkret+0x22>

0000000080001c50 <allocpid>:
allocpid() {
    80001c50:	1101                	addi	sp,sp,-32
    80001c52:	ec06                	sd	ra,24(sp)
    80001c54:	e822                	sd	s0,16(sp)
    80001c56:	e426                	sd	s1,8(sp)
    80001c58:	1000                	addi	s0,sp,32
  pid = nextpid;
    80001c5a:	00008517          	auipc	a0,0x8
    80001c5e:	04a50513          	addi	a0,a0,74 # 80009ca4 <nextpid>
    80001c62:	4104                	lw	s1,0(a0)
  if (cas(&nextpid, pid, (nextpid + 1)) == 0)
    80001c64:	0014861b          	addiw	a2,s1,1
    80001c68:	85a6                	mv	a1,s1
    80001c6a:	00006097          	auipc	ra,0x6
    80001c6e:	d0c080e7          	jalr	-756(ra) # 80007976 <cas>
    80001c72:	e519                	bnez	a0,80001c80 <allocpid+0x30>
}
    80001c74:	8526                	mv	a0,s1
    80001c76:	60e2                	ld	ra,24(sp)
    80001c78:	6442                	ld	s0,16(sp)
    80001c7a:	64a2                	ld	s1,8(sp)
    80001c7c:	6105                	addi	sp,sp,32
    80001c7e:	8082                	ret
  return allocpid();
    80001c80:	00000097          	auipc	ra,0x0
    80001c84:	fd0080e7          	jalr	-48(ra) # 80001c50 <allocpid>
    80001c88:	84aa                	mv	s1,a0
    80001c8a:	b7ed                	j	80001c74 <allocpid+0x24>

0000000080001c8c <proc_pagetable>:
{
    80001c8c:	1101                	addi	sp,sp,-32
    80001c8e:	ec06                	sd	ra,24(sp)
    80001c90:	e822                	sd	s0,16(sp)
    80001c92:	e426                	sd	s1,8(sp)
    80001c94:	e04a                	sd	s2,0(sp)
    80001c96:	1000                	addi	s0,sp,32
    80001c98:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	6a8080e7          	jalr	1704(ra) # 80001342 <uvmcreate>
    80001ca2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ca4:	c121                	beqz	a0,80001ce4 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ca6:	4729                	li	a4,10
    80001ca8:	00006697          	auipc	a3,0x6
    80001cac:	35868693          	addi	a3,a3,856 # 80008000 <_trampoline>
    80001cb0:	6605                	lui	a2,0x1
    80001cb2:	040005b7          	lui	a1,0x4000
    80001cb6:	15fd                	addi	a1,a1,-1
    80001cb8:	05b2                	slli	a1,a1,0xc
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	3fe080e7          	jalr	1022(ra) # 800010b8 <mappages>
    80001cc2:	02054863          	bltz	a0,80001cf2 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cc6:	4719                	li	a4,6
    80001cc8:	08893683          	ld	a3,136(s2) # 4000088 <_entry-0x7bffff78>
    80001ccc:	6605                	lui	a2,0x1
    80001cce:	020005b7          	lui	a1,0x2000
    80001cd2:	15fd                	addi	a1,a1,-1
    80001cd4:	05b6                	slli	a1,a1,0xd
    80001cd6:	8526                	mv	a0,s1
    80001cd8:	fffff097          	auipc	ra,0xfffff
    80001cdc:	3e0080e7          	jalr	992(ra) # 800010b8 <mappages>
    80001ce0:	02054163          	bltz	a0,80001d02 <proc_pagetable+0x76>
}
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	60e2                	ld	ra,24(sp)
    80001ce8:	6442                	ld	s0,16(sp)
    80001cea:	64a2                	ld	s1,8(sp)
    80001cec:	6902                	ld	s2,0(sp)
    80001cee:	6105                	addi	sp,sp,32
    80001cf0:	8082                	ret
    uvmfree(pagetable, 0);
    80001cf2:	4581                	li	a1,0
    80001cf4:	8526                	mv	a0,s1
    80001cf6:	00000097          	auipc	ra,0x0
    80001cfa:	848080e7          	jalr	-1976(ra) # 8000153e <uvmfree>
    return 0;
    80001cfe:	4481                	li	s1,0
    80001d00:	b7d5                	j	80001ce4 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d02:	4681                	li	a3,0
    80001d04:	4605                	li	a2,1
    80001d06:	040005b7          	lui	a1,0x4000
    80001d0a:	15fd                	addi	a1,a1,-1
    80001d0c:	05b2                	slli	a1,a1,0xc
    80001d0e:	8526                	mv	a0,s1
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	56e080e7          	jalr	1390(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001d18:	4581                	li	a1,0
    80001d1a:	8526                	mv	a0,s1
    80001d1c:	00000097          	auipc	ra,0x0
    80001d20:	822080e7          	jalr	-2014(ra) # 8000153e <uvmfree>
    return 0;
    80001d24:	4481                	li	s1,0
    80001d26:	bf7d                	j	80001ce4 <proc_pagetable+0x58>

0000000080001d28 <proc_freepagetable>:
{
    80001d28:	1101                	addi	sp,sp,-32
    80001d2a:	ec06                	sd	ra,24(sp)
    80001d2c:	e822                	sd	s0,16(sp)
    80001d2e:	e426                	sd	s1,8(sp)
    80001d30:	e04a                	sd	s2,0(sp)
    80001d32:	1000                	addi	s0,sp,32
    80001d34:	84aa                	mv	s1,a0
    80001d36:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d38:	4681                	li	a3,0
    80001d3a:	4605                	li	a2,1
    80001d3c:	040005b7          	lui	a1,0x4000
    80001d40:	15fd                	addi	a1,a1,-1
    80001d42:	05b2                	slli	a1,a1,0xc
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	53a080e7          	jalr	1338(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d4c:	4681                	li	a3,0
    80001d4e:	4605                	li	a2,1
    80001d50:	020005b7          	lui	a1,0x2000
    80001d54:	15fd                	addi	a1,a1,-1
    80001d56:	05b6                	slli	a1,a1,0xd
    80001d58:	8526                	mv	a0,s1
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	524080e7          	jalr	1316(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001d62:	85ca                	mv	a1,s2
    80001d64:	8526                	mv	a0,s1
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	7d8080e7          	jalr	2008(ra) # 8000153e <uvmfree>
}
    80001d6e:	60e2                	ld	ra,24(sp)
    80001d70:	6442                	ld	s0,16(sp)
    80001d72:	64a2                	ld	s1,8(sp)
    80001d74:	6902                	ld	s2,0(sp)
    80001d76:	6105                	addi	sp,sp,32
    80001d78:	8082                	ret

0000000080001d7a <freeproc>:
{
    80001d7a:	1101                	addi	sp,sp,-32
    80001d7c:	ec06                	sd	ra,24(sp)
    80001d7e:	e822                	sd	s0,16(sp)
    80001d80:	e426                	sd	s1,8(sp)
    80001d82:	1000                	addi	s0,sp,32
    80001d84:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d86:	6548                	ld	a0,136(a0)
    80001d88:	c509                	beqz	a0,80001d92 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d8a:	fffff097          	auipc	ra,0xfffff
    80001d8e:	c6e080e7          	jalr	-914(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001d92:	0804b423          	sd	zero,136(s1)
  if(p->pagetable)
    80001d96:	60c8                	ld	a0,128(s1)
    80001d98:	c511                	beqz	a0,80001da4 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d9a:	7cac                	ld	a1,120(s1)
    80001d9c:	00000097          	auipc	ra,0x0
    80001da0:	f8c080e7          	jalr	-116(ra) # 80001d28 <proc_freepagetable>
  p->pagetable = 0;
    80001da4:	0804b023          	sd	zero,128(s1)
  p->sz = 0;
    80001da8:	0604bc23          	sd	zero,120(s1)
  p->pid = 0;
    80001dac:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001db0:	0604b423          	sd	zero,104(s1)
  p->name[0] = 0;
    80001db4:	18048423          	sb	zero,392(s1)
  p->chan = 0;
    80001db8:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001dbc:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001dc0:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001dc4:	0004ac23          	sw	zero,24(s1)
  printf("zombie");
    80001dc8:	00007517          	auipc	a0,0x7
    80001dcc:	4b050513          	addi	a0,a0,1200 # 80009278 <digits+0x238>
    80001dd0:	ffffe097          	auipc	ra,0xffffe
    80001dd4:	7b8080e7          	jalr	1976(ra) # 80000588 <printf>
  int res = remove_proc_from_list(p->proc_ind); 
    80001dd8:	4ce8                	lw	a0,92(s1)
    80001dda:	00000097          	auipc	ra,0x0
    80001dde:	aea080e7          	jalr	-1302(ra) # 800018c4 <remove_proc_from_list>
  if (res == 1)
    80001de2:	4785                	li	a5,1
    80001de4:	08f50563          	beq	a0,a5,80001e6e <freeproc+0xf4>
  if (res == 2)
    80001de8:	4789                	li	a5,2
    80001dea:	0af50463          	beq	a0,a5,80001e92 <freeproc+0x118>
  if (res == 3){
    80001dee:	478d                	li	a5,3
    80001df0:	04f51763          	bne	a0,a5,80001e3e <freeproc+0xc4>
    zombie_list_tail = p->prev_proc;
    80001df4:	50fc                	lw	a5,100(s1)
    80001df6:	00008717          	auipc	a4,0x8
    80001dfa:	eaf72923          	sw	a5,-334(a4) # 80009ca8 <zombie_list_tail>
     if (proc[p->prev_proc].prev_proc == -1)
    80001dfe:	19800713          	li	a4,408
    80001e02:	02e786b3          	mul	a3,a5,a4
    80001e06:	00011717          	auipc	a4,0x11
    80001e0a:	96a70713          	addi	a4,a4,-1686 # 80012770 <proc>
    80001e0e:	9736                	add	a4,a4,a3
    80001e10:	5374                	lw	a3,100(a4)
    80001e12:	577d                	li	a4,-1
    80001e14:	0ce68a63          	beq	a3,a4,80001ee8 <freeproc+0x16e>
    proc[p->prev_proc].next_proc = -1;
    80001e18:	19800713          	li	a4,408
    80001e1c:	02e787b3          	mul	a5,a5,a4
    80001e20:	00011717          	auipc	a4,0x11
    80001e24:	95070713          	addi	a4,a4,-1712 # 80012770 <proc>
    80001e28:	97ba                	add	a5,a5,a4
    80001e2a:	577d                	li	a4,-1
    80001e2c:	d3b8                	sw	a4,96(a5)
    printf("1 no tail");
    80001e2e:	00007517          	auipc	a0,0x7
    80001e32:	47a50513          	addi	a0,a0,1146 # 800092a8 <digits+0x268>
    80001e36:	ffffe097          	auipc	ra,0xffffe
    80001e3a:	752080e7          	jalr	1874(ra) # 80000588 <printf>
  p->next_proc = -1;
    80001e3e:	57fd                	li	a5,-1
    80001e40:	d0bc                	sw	a5,96(s1)
  p->prev_proc = -1;
    80001e42:	d0fc                	sw	a5,100(s1)
  if (unused_list_tail != -1){
    80001e44:	00008717          	auipc	a4,0x8
    80001e48:	e6c72703          	lw	a4,-404(a4) # 80009cb0 <unused_list_tail>
    80001e4c:	57fd                	li	a5,-1
    80001e4e:	0af71263          	bne	a4,a5,80001ef2 <freeproc+0x178>
    unused_list_tail = unused_list_head = p->proc_ind;
    80001e52:	4cfc                	lw	a5,92(s1)
    80001e54:	00008717          	auipc	a4,0x8
    80001e58:	e6f72023          	sw	a5,-416(a4) # 80009cb4 <unused_list_head>
    80001e5c:	00008717          	auipc	a4,0x8
    80001e60:	e4f72a23          	sw	a5,-428(a4) # 80009cb0 <unused_list_tail>
}
    80001e64:	60e2                	ld	ra,24(sp)
    80001e66:	6442                	ld	s0,16(sp)
    80001e68:	64a2                	ld	s1,8(sp)
    80001e6a:	6105                	addi	sp,sp,32
    80001e6c:	8082                	ret
    zombie_list_head = -1;
    80001e6e:	57fd                	li	a5,-1
    80001e70:	00008717          	auipc	a4,0x8
    80001e74:	e2f72e23          	sw	a5,-452(a4) # 80009cac <zombie_list_head>
    zombie_list_tail = -1;
    80001e78:	00008717          	auipc	a4,0x8
    80001e7c:	e2f72823          	sw	a5,-464(a4) # 80009ca8 <zombie_list_tail>
    printf("2 no head & tail");
    80001e80:	00007517          	auipc	a0,0x7
    80001e84:	40050513          	addi	a0,a0,1024 # 80009280 <digits+0x240>
    80001e88:	ffffe097          	auipc	ra,0xffffe
    80001e8c:	700080e7          	jalr	1792(ra) # 80000588 <printf>
  if (res == 3){
    80001e90:	b77d                	j	80001e3e <freeproc+0xc4>
    zombie_list_head = p->next_proc;
    80001e92:	50bc                	lw	a5,96(s1)
    80001e94:	00008717          	auipc	a4,0x8
    80001e98:	e0f72c23          	sw	a5,-488(a4) # 80009cac <zombie_list_head>
    if (proc[p->next_proc].next_proc == -1)
    80001e9c:	19800713          	li	a4,408
    80001ea0:	02e786b3          	mul	a3,a5,a4
    80001ea4:	00011717          	auipc	a4,0x11
    80001ea8:	8cc70713          	addi	a4,a4,-1844 # 80012770 <proc>
    80001eac:	9736                	add	a4,a4,a3
    80001eae:	5334                	lw	a3,96(a4)
    80001eb0:	577d                	li	a4,-1
    80001eb2:	02e68663          	beq	a3,a4,80001ede <freeproc+0x164>
    proc[p->next_proc].prev_proc = -1;
    80001eb6:	19800713          	li	a4,408
    80001eba:	02e787b3          	mul	a5,a5,a4
    80001ebe:	00011717          	auipc	a4,0x11
    80001ec2:	8b270713          	addi	a4,a4,-1870 # 80012770 <proc>
    80001ec6:	97ba                	add	a5,a5,a4
    80001ec8:	577d                	li	a4,-1
    80001eca:	d3f8                	sw	a4,100(a5)
    printf("1 no head ");
    80001ecc:	00007517          	auipc	a0,0x7
    80001ed0:	3cc50513          	addi	a0,a0,972 # 80009298 <digits+0x258>
    80001ed4:	ffffe097          	auipc	ra,0xffffe
    80001ed8:	6b4080e7          	jalr	1716(ra) # 80000588 <printf>
  if (res == 3){
    80001edc:	b78d                	j	80001e3e <freeproc+0xc4>
      zombie_list_tail = p->next_proc;
    80001ede:	00008717          	auipc	a4,0x8
    80001ee2:	dcf72523          	sw	a5,-566(a4) # 80009ca8 <zombie_list_tail>
    80001ee6:	bfc1                	j	80001eb6 <freeproc+0x13c>
      zombie_list_head = p->prev_proc;
    80001ee8:	00008717          	auipc	a4,0x8
    80001eec:	dcf72223          	sw	a5,-572(a4) # 80009cac <zombie_list_head>
    80001ef0:	b725                	j	80001e18 <freeproc+0x9e>
    printf("unused");
    80001ef2:	00007517          	auipc	a0,0x7
    80001ef6:	37e50513          	addi	a0,a0,894 # 80009270 <digits+0x230>
    80001efa:	ffffe097          	auipc	ra,0xffffe
    80001efe:	68e080e7          	jalr	1678(ra) # 80000588 <printf>
    add_proc_to_list(unused_list_tail, p);
    80001f02:	85a6                	mv	a1,s1
    80001f04:	00008517          	auipc	a0,0x8
    80001f08:	dac52503          	lw	a0,-596(a0) # 80009cb0 <unused_list_tail>
    80001f0c:	00000097          	auipc	ra,0x0
    80001f10:	93a080e7          	jalr	-1734(ra) # 80001846 <add_proc_to_list>
    if (unused_list_head == -1)
    80001f14:	00008717          	auipc	a4,0x8
    80001f18:	da072703          	lw	a4,-608(a4) # 80009cb4 <unused_list_head>
    80001f1c:	57fd                	li	a5,-1
    80001f1e:	00f70863          	beq	a4,a5,80001f2e <freeproc+0x1b4>
    unused_list_tail = p->proc_ind;
    80001f22:	4cfc                	lw	a5,92(s1)
    80001f24:	00008717          	auipc	a4,0x8
    80001f28:	d8f72623          	sw	a5,-628(a4) # 80009cb0 <unused_list_tail>
    80001f2c:	bf25                	j	80001e64 <freeproc+0xea>
    unused_list_head = p->proc_ind;
    80001f2e:	4cfc                	lw	a5,92(s1)
    80001f30:	00008717          	auipc	a4,0x8
    80001f34:	d8f72223          	sw	a5,-636(a4) # 80009cb4 <unused_list_head>
    80001f38:	b7ed                	j	80001f22 <freeproc+0x1a8>

0000000080001f3a <allocproc>:
{
    80001f3a:	7139                	addi	sp,sp,-64
    80001f3c:	fc06                	sd	ra,56(sp)
    80001f3e:	f822                	sd	s0,48(sp)
    80001f40:	f426                	sd	s1,40(sp)
    80001f42:	f04a                	sd	s2,32(sp)
    80001f44:	ec4e                	sd	s3,24(sp)
    80001f46:	e852                	sd	s4,16(sp)
    80001f48:	e456                	sd	s5,8(sp)
    80001f4a:	0080                	addi	s0,sp,64
  if (unused_list_head > -1)
    80001f4c:	00008917          	auipc	s2,0x8
    80001f50:	d6892903          	lw	s2,-664(s2) # 80009cb4 <unused_list_head>
  return 0;
    80001f54:	4981                	li	s3,0
  if (unused_list_head > -1)
    80001f56:	00095c63          	bgez	s2,80001f6e <allocproc+0x34>
}
    80001f5a:	854e                	mv	a0,s3
    80001f5c:	70e2                	ld	ra,56(sp)
    80001f5e:	7442                	ld	s0,48(sp)
    80001f60:	74a2                	ld	s1,40(sp)
    80001f62:	7902                	ld	s2,32(sp)
    80001f64:	69e2                	ld	s3,24(sp)
    80001f66:	6a42                	ld	s4,16(sp)
    80001f68:	6aa2                	ld	s5,8(sp)
    80001f6a:	6121                	addi	sp,sp,64
    80001f6c:	8082                	ret
    p = &proc[unused_list_head];
    80001f6e:	19800a13          	li	s4,408
    80001f72:	03490a33          	mul	s4,s2,s4
    80001f76:	00010997          	auipc	s3,0x10
    80001f7a:	7fa98993          	addi	s3,s3,2042 # 80012770 <proc>
    80001f7e:	99d2                	add	s3,s3,s4
    acquire(&p->lock);
    80001f80:	854e                	mv	a0,s3
    80001f82:	fffff097          	auipc	ra,0xfffff
    80001f86:	c62080e7          	jalr	-926(ra) # 80000be4 <acquire>
    printf("unused");
    80001f8a:	00007517          	auipc	a0,0x7
    80001f8e:	2e650513          	addi	a0,a0,742 # 80009270 <digits+0x230>
    80001f92:	ffffe097          	auipc	ra,0xffffe
    80001f96:	5f6080e7          	jalr	1526(ra) # 80000588 <printf>
    int res = remove_proc_from_list(unused_list_head); 
    80001f9a:	00008517          	auipc	a0,0x8
    80001f9e:	d1a52503          	lw	a0,-742(a0) # 80009cb4 <unused_list_head>
    80001fa2:	00000097          	auipc	ra,0x0
    80001fa6:	922080e7          	jalr	-1758(ra) # 800018c4 <remove_proc_from_list>
    if (res == 1)
    80001faa:	4785                	li	a5,1
    80001fac:	06f50163          	beq	a0,a5,8000200e <allocproc+0xd4>
    if (res == 2)
    80001fb0:	4789                	li	a5,2
    80001fb2:	08f50063          	beq	a0,a5,80002032 <allocproc+0xf8>
    if (res == 3)
    80001fb6:	478d                	li	a5,3
    80001fb8:	0cf51563          	bne	a0,a5,80002082 <allocproc+0x148>
      unused_list_tail = p->prev_proc;      // Update tail.
    80001fbc:	00010717          	auipc	a4,0x10
    80001fc0:	7b470713          	addi	a4,a4,1972 # 80012770 <proc>
    80001fc4:	19800693          	li	a3,408
    80001fc8:	02d907b3          	mul	a5,s2,a3
    80001fcc:	97ba                	add	a5,a5,a4
    80001fce:	53fc                	lw	a5,100(a5)
    80001fd0:	00008617          	auipc	a2,0x8
    80001fd4:	cef62023          	sw	a5,-800(a2) # 80009cb0 <unused_list_tail>
       if (proc[p->prev_proc].prev_proc == -1)
    80001fd8:	02d786b3          	mul	a3,a5,a3
    80001fdc:	9736                	add	a4,a4,a3
    80001fde:	5374                	lw	a3,100(a4)
    80001fe0:	577d                	li	a4,-1
    80001fe2:	14e68c63          	beq	a3,a4,8000213a <allocproc+0x200>
      proc[p->prev_proc].next_proc = -1;    // Remove tail's next.
    80001fe6:	19800713          	li	a4,408
    80001fea:	02e787b3          	mul	a5,a5,a4
    80001fee:	00010717          	auipc	a4,0x10
    80001ff2:	78270713          	addi	a4,a4,1922 # 80012770 <proc>
    80001ff6:	97ba                	add	a5,a5,a4
    80001ff8:	577d                	li	a4,-1
    80001ffa:	d3b8                	sw	a4,96(a5)
      printf("1 no tail");
    80001ffc:	00007517          	auipc	a0,0x7
    80002000:	2ac50513          	addi	a0,a0,684 # 800092a8 <digits+0x268>
    80002004:	ffffe097          	auipc	ra,0xffffe
    80002008:	584080e7          	jalr	1412(ra) # 80000588 <printf>
    8000200c:	a89d                	j	80002082 <allocproc+0x148>
      unused_list_head = -1;
    8000200e:	57fd                	li	a5,-1
    80002010:	00008717          	auipc	a4,0x8
    80002014:	caf72223          	sw	a5,-860(a4) # 80009cb4 <unused_list_head>
      unused_list_tail = -1;
    80002018:	00008717          	auipc	a4,0x8
    8000201c:	c8f72c23          	sw	a5,-872(a4) # 80009cb0 <unused_list_tail>
      printf("1 no head & tail");
    80002020:	00007517          	auipc	a0,0x7
    80002024:	29850513          	addi	a0,a0,664 # 800092b8 <digits+0x278>
    80002028:	ffffe097          	auipc	ra,0xffffe
    8000202c:	560080e7          	jalr	1376(ra) # 80000588 <printf>
    if (res == 3)
    80002030:	a889                	j	80002082 <allocproc+0x148>
      unused_list_head = p->next_proc;      // Update head.
    80002032:	00010717          	auipc	a4,0x10
    80002036:	73e70713          	addi	a4,a4,1854 # 80012770 <proc>
    8000203a:	19800693          	li	a3,408
    8000203e:	02d907b3          	mul	a5,s2,a3
    80002042:	97ba                	add	a5,a5,a4
    80002044:	53bc                	lw	a5,96(a5)
    80002046:	00008617          	auipc	a2,0x8
    8000204a:	c6f62723          	sw	a5,-914(a2) # 80009cb4 <unused_list_head>
      if (proc[p->next_proc].next_proc == -1)
    8000204e:	02d786b3          	mul	a3,a5,a3
    80002052:	9736                	add	a4,a4,a3
    80002054:	5334                	lw	a3,96(a4)
    80002056:	577d                	li	a4,-1
    80002058:	0ce68c63          	beq	a3,a4,80002130 <allocproc+0x1f6>
      proc[p->next_proc].prev_proc = -1;    // Remove head's prev.
    8000205c:	19800713          	li	a4,408
    80002060:	02e787b3          	mul	a5,a5,a4
    80002064:	00010717          	auipc	a4,0x10
    80002068:	70c70713          	addi	a4,a4,1804 # 80012770 <proc>
    8000206c:	97ba                	add	a5,a5,a4
    8000206e:	577d                	li	a4,-1
    80002070:	d3f8                	sw	a4,100(a5)
      printf("1 no head");
    80002072:	00007517          	auipc	a0,0x7
    80002076:	25e50513          	addi	a0,a0,606 # 800092d0 <digits+0x290>
    8000207a:	ffffe097          	auipc	ra,0xffffe
    8000207e:	50e080e7          	jalr	1294(ra) # 80000588 <printf>
    p->prev_proc = -1;
    80002082:	19800493          	li	s1,408
    80002086:	029907b3          	mul	a5,s2,s1
    8000208a:	00010497          	auipc	s1,0x10
    8000208e:	6e648493          	addi	s1,s1,1766 # 80012770 <proc>
    80002092:	94be                	add	s1,s1,a5
    80002094:	57fd                	li	a5,-1
    80002096:	d0fc                	sw	a5,100(s1)
    p->next_proc = -1;
    80002098:	d0bc                	sw	a5,96(s1)
  p->pid = allocpid();
    8000209a:	00000097          	auipc	ra,0x0
    8000209e:	bb6080e7          	jalr	-1098(ra) # 80001c50 <allocpid>
    800020a2:	d888                	sw	a0,48(s1)
  p->state = USED;
    800020a4:	4785                	li	a5,1
    800020a6:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    800020a8:	0204aa23          	sw	zero,52(s1)
  p->last_ticks = 0;
    800020ac:	0204ac23          	sw	zero,56(s1)
  p->paused = 0;
    800020b0:	0404a023          	sw	zero,64(s1)
  p->sleeping_time = 0;
    800020b4:	0404a623          	sw	zero,76(s1)
  p->running_time = 0;
    800020b8:	0404a223          	sw	zero,68(s1)
  p->runnable_time = 0;
    800020bc:	0404a423          	sw	zero,72(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800020c0:	fffff097          	auipc	ra,0xfffff
    800020c4:	a34080e7          	jalr	-1484(ra) # 80000af4 <kalloc>
    800020c8:	8aaa                	mv	s5,a0
    800020ca:	e4c8                	sd	a0,136(s1)
    800020cc:	cd25                	beqz	a0,80002144 <allocproc+0x20a>
  p->pagetable = proc_pagetable(p);
    800020ce:	854e                	mv	a0,s3
    800020d0:	00000097          	auipc	ra,0x0
    800020d4:	bbc080e7          	jalr	-1092(ra) # 80001c8c <proc_pagetable>
    800020d8:	84aa                	mv	s1,a0
    800020da:	19800793          	li	a5,408
    800020de:	02f90733          	mul	a4,s2,a5
    800020e2:	00010797          	auipc	a5,0x10
    800020e6:	68e78793          	addi	a5,a5,1678 # 80012770 <proc>
    800020ea:	97ba                	add	a5,a5,a4
    800020ec:	e3c8                	sd	a0,128(a5)
  if(p->pagetable == 0){
    800020ee:	c53d                	beqz	a0,8000215c <allocproc+0x222>
  memset(&p->context, 0, sizeof(p->context));
    800020f0:	090a0513          	addi	a0,s4,144 # 4000090 <_entry-0x7bffff70>
    800020f4:	00010497          	auipc	s1,0x10
    800020f8:	67c48493          	addi	s1,s1,1660 # 80012770 <proc>
    800020fc:	07000613          	li	a2,112
    80002100:	4581                	li	a1,0
    80002102:	9526                	add	a0,a0,s1
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	bdc080e7          	jalr	-1060(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    8000210c:	19800793          	li	a5,408
    80002110:	02f90933          	mul	s2,s2,a5
    80002114:	9926                	add	s2,s2,s1
    80002116:	00000797          	auipc	a5,0x0
    8000211a:	af478793          	addi	a5,a5,-1292 # 80001c0a <forkret>
    8000211e:	08f93823          	sd	a5,144(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002122:	07093783          	ld	a5,112(s2)
    80002126:	6705                	lui	a4,0x1
    80002128:	97ba                	add	a5,a5,a4
    8000212a:	08f93c23          	sd	a5,152(s2)
  return p;
    8000212e:	b535                	j	80001f5a <allocproc+0x20>
        unused_list_tail = p->next_proc;
    80002130:	00008717          	auipc	a4,0x8
    80002134:	b8f72023          	sw	a5,-1152(a4) # 80009cb0 <unused_list_tail>
    80002138:	b715                	j	8000205c <allocproc+0x122>
        unused_list_head = p->prev_proc;
    8000213a:	00008717          	auipc	a4,0x8
    8000213e:	b6f72d23          	sw	a5,-1158(a4) # 80009cb4 <unused_list_head>
    80002142:	b555                	j	80001fe6 <allocproc+0xac>
    freeproc(p);
    80002144:	854e                	mv	a0,s3
    80002146:	00000097          	auipc	ra,0x0
    8000214a:	c34080e7          	jalr	-972(ra) # 80001d7a <freeproc>
    release(&p->lock);
    8000214e:	854e                	mv	a0,s3
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	b48080e7          	jalr	-1208(ra) # 80000c98 <release>
    return 0;
    80002158:	89d6                	mv	s3,s5
    8000215a:	b501                	j	80001f5a <allocproc+0x20>
    freeproc(p);
    8000215c:	854e                	mv	a0,s3
    8000215e:	00000097          	auipc	ra,0x0
    80002162:	c1c080e7          	jalr	-996(ra) # 80001d7a <freeproc>
    release(&p->lock);
    80002166:	854e                	mv	a0,s3
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	b30080e7          	jalr	-1232(ra) # 80000c98 <release>
    return 0;
    80002170:	89a6                	mv	s3,s1
    80002172:	b3e5                	j	80001f5a <allocproc+0x20>

0000000080002174 <str_compare>:
{
    80002174:	1141                	addi	sp,sp,-16
    80002176:	e422                	sd	s0,8(sp)
    80002178:	0800                	addi	s0,sp,16
      c1 = (unsigned char) *s1++;
    8000217a:	0505                	addi	a0,a0,1
    8000217c:	fff54783          	lbu	a5,-1(a0)
      c2 = (unsigned char) *s2++;
    80002180:	0585                	addi	a1,a1,1
    80002182:	fff5c703          	lbu	a4,-1(a1) # 1ffffff <_entry-0x7e000001>
      if (c1 == '\0')
    80002186:	c791                	beqz	a5,80002192 <str_compare+0x1e>
  while (c1 == c2);
    80002188:	fee789e3          	beq	a5,a4,8000217a <str_compare+0x6>
  return c1 - c2;
    8000218c:	40e7853b          	subw	a0,a5,a4
    80002190:	a019                	j	80002196 <str_compare+0x22>
        return c1 - c2;
    80002192:	40e0053b          	negw	a0,a4
}
    80002196:	6422                	ld	s0,8(sp)
    80002198:	0141                	addi	sp,sp,16
    8000219a:	8082                	ret

000000008000219c <userinit>:
{
    8000219c:	1101                	addi	sp,sp,-32
    8000219e:	ec06                	sd	ra,24(sp)
    800021a0:	e822                	sd	s0,16(sp)
    800021a2:	e426                	sd	s1,8(sp)
    800021a4:	e04a                	sd	s2,0(sp)
    800021a6:	1000                	addi	s0,sp,32
  p = allocproc();
    800021a8:	00000097          	auipc	ra,0x0
    800021ac:	d92080e7          	jalr	-622(ra) # 80001f3a <allocproc>
    800021b0:	84aa                	mv	s1,a0
  initproc = p;
    800021b2:	00008797          	auipc	a5,0x8
    800021b6:	e6a7bb23          	sd	a0,-394(a5) # 8000a028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800021ba:	03400613          	li	a2,52
    800021be:	00008597          	auipc	a1,0x8
    800021c2:	b1258593          	addi	a1,a1,-1262 # 80009cd0 <initcode>
    800021c6:	6148                	ld	a0,128(a0)
    800021c8:	fffff097          	auipc	ra,0xfffff
    800021cc:	1a8080e7          	jalr	424(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    800021d0:	6785                	lui	a5,0x1
    800021d2:	fcbc                	sd	a5,120(s1)
  p->trapframe->epc = 0;      // user program counter
    800021d4:	64d8                	ld	a4,136(s1)
    800021d6:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800021da:	64d8                	ld	a4,136(s1)
    800021dc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800021de:	4641                	li	a2,16
    800021e0:	00007597          	auipc	a1,0x7
    800021e4:	10058593          	addi	a1,a1,256 # 800092e0 <digits+0x2a0>
    800021e8:	18848513          	addi	a0,s1,392
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	c46080e7          	jalr	-954(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800021f4:	00007517          	auipc	a0,0x7
    800021f8:	0fc50513          	addi	a0,a0,252 # 800092f0 <digits+0x2b0>
    800021fc:	00003097          	auipc	ra,0x3
    80002200:	394080e7          	jalr	916(ra) # 80005590 <namei>
    80002204:	18a4b023          	sd	a0,384(s1)
  p->state = RUNNABLE;
    80002208:	478d                	li	a5,3
    8000220a:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    8000220c:	00008797          	auipc	a5,0x8
    80002210:	e487a783          	lw	a5,-440(a5) # 8000a054 <ticks>
    80002214:	dcdc                	sw	a5,60(s1)
    80002216:	8792                	mv	a5,tp
  int id = r_tp();
    80002218:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    8000221c:	00010617          	auipc	a2,0x10
    80002220:	0a460613          	addi	a2,a2,164 # 800122c0 <cpus>
    80002224:	00371793          	slli	a5,a4,0x3
    80002228:	00e786b3          	add	a3,a5,a4
    8000222c:	0692                	slli	a3,a3,0x4
    8000222e:	96b2                	add	a3,a3,a2
    80002230:	08e6a423          	sw	a4,136(a3)
  if (mycpu()->runnable_list_head == -1)
    80002234:	0806a703          	lw	a4,128(a3)
    80002238:	57fd                	li	a5,-1
    8000223a:	06f70c63          	beq	a4,a5,800022b2 <userinit+0x116>
    printf("runnable1");
    8000223e:	00007517          	auipc	a0,0x7
    80002242:	0da50513          	addi	a0,a0,218 # 80009318 <digits+0x2d8>
    80002246:	ffffe097          	auipc	ra,0xffffe
    8000224a:	342080e7          	jalr	834(ra) # 80000588 <printf>
    8000224e:	8792                	mv	a5,tp
  int id = r_tp();
    80002250:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002254:	00010917          	auipc	s2,0x10
    80002258:	06c90913          	addi	s2,s2,108 # 800122c0 <cpus>
    8000225c:	00371793          	slli	a5,a4,0x3
    80002260:	00e786b3          	add	a3,a5,a4
    80002264:	0692                	slli	a3,a3,0x4
    80002266:	96ca                	add	a3,a3,s2
    80002268:	08e6a423          	sw	a4,136(a3)
    add_proc_to_list(mycpu()->runnable_list_tail, p);
    8000226c:	85a6                	mv	a1,s1
    8000226e:	0846a503          	lw	a0,132(a3)
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	5d4080e7          	jalr	1492(ra) # 80001846 <add_proc_to_list>
    8000227a:	8792                	mv	a5,tp
  int id = r_tp();
    8000227c:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002280:	00371793          	slli	a5,a4,0x3
    80002284:	00e786b3          	add	a3,a5,a4
    80002288:	0692                	slli	a3,a3,0x4
    8000228a:	96ca                	add	a3,a3,s2
    8000228c:	08e6a423          	sw	a4,136(a3)
    mycpu()->runnable_list_tail = p->proc_ind;
    80002290:	4cf4                	lw	a3,92(s1)
    80002292:	97ba                	add	a5,a5,a4
    80002294:	0792                	slli	a5,a5,0x4
    80002296:	993e                	add	s2,s2,a5
    80002298:	08d92223          	sw	a3,132(s2)
  release(&p->lock);
    8000229c:	8526                	mv	a0,s1
    8000229e:	fffff097          	auipc	ra,0xfffff
    800022a2:	9fa080e7          	jalr	-1542(ra) # 80000c98 <release>
}
    800022a6:	60e2                	ld	ra,24(sp)
    800022a8:	6442                	ld	s0,16(sp)
    800022aa:	64a2                	ld	s1,8(sp)
    800022ac:	6902                	ld	s2,0(sp)
    800022ae:	6105                	addi	sp,sp,32
    800022b0:	8082                	ret
    printf("init runnable: %d            1\n", p->proc_ind);
    800022b2:	4cec                	lw	a1,92(s1)
    800022b4:	00007517          	auipc	a0,0x7
    800022b8:	04450513          	addi	a0,a0,68 # 800092f8 <digits+0x2b8>
    800022bc:	ffffe097          	auipc	ra,0xffffe
    800022c0:	2cc080e7          	jalr	716(ra) # 80000588 <printf>
    800022c4:	8792                	mv	a5,tp
  int id = r_tp();
    800022c6:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    800022ca:	00010717          	auipc	a4,0x10
    800022ce:	ff670713          	addi	a4,a4,-10 # 800122c0 <cpus>
    800022d2:	00369793          	slli	a5,a3,0x3
    800022d6:	00d78633          	add	a2,a5,a3
    800022da:	0612                	slli	a2,a2,0x4
    800022dc:	963a                	add	a2,a2,a4
    800022de:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_head = p->proc_ind;
    800022e2:	4cf0                	lw	a2,92(s1)
    800022e4:	97b6                	add	a5,a5,a3
    800022e6:	0792                	slli	a5,a5,0x4
    800022e8:	97ba                	add	a5,a5,a4
    800022ea:	08c7a023          	sw	a2,128(a5)
    800022ee:	8792                	mv	a5,tp
  int id = r_tp();
    800022f0:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    800022f4:	00369793          	slli	a5,a3,0x3
    800022f8:	00d78633          	add	a2,a5,a3
    800022fc:	0612                	slli	a2,a2,0x4
    800022fe:	963a                	add	a2,a2,a4
    80002300:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_tail = p->proc_ind;
    80002304:	4cf0                	lw	a2,92(s1)
    80002306:	97b6                	add	a5,a5,a3
    80002308:	0792                	slli	a5,a5,0x4
    8000230a:	973e                	add	a4,a4,a5
    8000230c:	08c72223          	sw	a2,132(a4)
    80002310:	b771                	j	8000229c <userinit+0x100>

0000000080002312 <growproc>:
{
    80002312:	1101                	addi	sp,sp,-32
    80002314:	ec06                	sd	ra,24(sp)
    80002316:	e822                	sd	s0,16(sp)
    80002318:	e426                	sd	s1,8(sp)
    8000231a:	e04a                	sd	s2,0(sp)
    8000231c:	1000                	addi	s0,sp,32
    8000231e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002320:	00000097          	auipc	ra,0x0
    80002324:	8a4080e7          	jalr	-1884(ra) # 80001bc4 <myproc>
    80002328:	892a                	mv	s2,a0
  sz = p->sz;
    8000232a:	7d2c                	ld	a1,120(a0)
    8000232c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002330:	00904f63          	bgtz	s1,8000234e <growproc+0x3c>
  } else if(n < 0){
    80002334:	0204cc63          	bltz	s1,8000236c <growproc+0x5a>
  p->sz = sz;
    80002338:	1602                	slli	a2,a2,0x20
    8000233a:	9201                	srli	a2,a2,0x20
    8000233c:	06c93c23          	sd	a2,120(s2)
  return 0;
    80002340:	4501                	li	a0,0
}
    80002342:	60e2                	ld	ra,24(sp)
    80002344:	6442                	ld	s0,16(sp)
    80002346:	64a2                	ld	s1,8(sp)
    80002348:	6902                	ld	s2,0(sp)
    8000234a:	6105                	addi	sp,sp,32
    8000234c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000234e:	9e25                	addw	a2,a2,s1
    80002350:	1602                	slli	a2,a2,0x20
    80002352:	9201                	srli	a2,a2,0x20
    80002354:	1582                	slli	a1,a1,0x20
    80002356:	9181                	srli	a1,a1,0x20
    80002358:	6148                	ld	a0,128(a0)
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	0d0080e7          	jalr	208(ra) # 8000142a <uvmalloc>
    80002362:	0005061b          	sext.w	a2,a0
    80002366:	fa69                	bnez	a2,80002338 <growproc+0x26>
      return -1;
    80002368:	557d                	li	a0,-1
    8000236a:	bfe1                	j	80002342 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000236c:	9e25                	addw	a2,a2,s1
    8000236e:	1602                	slli	a2,a2,0x20
    80002370:	9201                	srli	a2,a2,0x20
    80002372:	1582                	slli	a1,a1,0x20
    80002374:	9181                	srli	a1,a1,0x20
    80002376:	6148                	ld	a0,128(a0)
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	06a080e7          	jalr	106(ra) # 800013e2 <uvmdealloc>
    80002380:	0005061b          	sext.w	a2,a0
    80002384:	bf55                	j	80002338 <growproc+0x26>

0000000080002386 <fork>:
{
    80002386:	7139                	addi	sp,sp,-64
    80002388:	fc06                	sd	ra,56(sp)
    8000238a:	f822                	sd	s0,48(sp)
    8000238c:	f426                	sd	s1,40(sp)
    8000238e:	f04a                	sd	s2,32(sp)
    80002390:	ec4e                	sd	s3,24(sp)
    80002392:	e852                	sd	s4,16(sp)
    80002394:	e456                	sd	s5,8(sp)
    80002396:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002398:	00000097          	auipc	ra,0x0
    8000239c:	82c080e7          	jalr	-2004(ra) # 80001bc4 <myproc>
    800023a0:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    800023a2:	00000097          	auipc	ra,0x0
    800023a6:	b98080e7          	jalr	-1128(ra) # 80001f3a <allocproc>
    800023aa:	20050663          	beqz	a0,800025b6 <fork+0x230>
    800023ae:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800023b0:	0789b603          	ld	a2,120(s3)
    800023b4:	614c                	ld	a1,128(a0)
    800023b6:	0809b503          	ld	a0,128(s3)
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	1bc080e7          	jalr	444(ra) # 80001576 <uvmcopy>
    800023c2:	04054663          	bltz	a0,8000240e <fork+0x88>
  np->sz = p->sz;
    800023c6:	0789b783          	ld	a5,120(s3)
    800023ca:	06f93c23          	sd	a5,120(s2)
  *(np->trapframe) = *(p->trapframe);
    800023ce:	0889b683          	ld	a3,136(s3)
    800023d2:	87b6                	mv	a5,a3
    800023d4:	08893703          	ld	a4,136(s2)
    800023d8:	12068693          	addi	a3,a3,288
    800023dc:	0007b803          	ld	a6,0(a5)
    800023e0:	6788                	ld	a0,8(a5)
    800023e2:	6b8c                	ld	a1,16(a5)
    800023e4:	6f90                	ld	a2,24(a5)
    800023e6:	01073023          	sd	a6,0(a4)
    800023ea:	e708                	sd	a0,8(a4)
    800023ec:	eb0c                	sd	a1,16(a4)
    800023ee:	ef10                	sd	a2,24(a4)
    800023f0:	02078793          	addi	a5,a5,32
    800023f4:	02070713          	addi	a4,a4,32
    800023f8:	fed792e3          	bne	a5,a3,800023dc <fork+0x56>
  np->trapframe->a0 = 0;
    800023fc:	08893783          	ld	a5,136(s2)
    80002400:	0607b823          	sd	zero,112(a5)
    80002404:	10000493          	li	s1,256
  for(i = 0; i < NOFILE; i++)
    80002408:	18000a13          	li	s4,384
    8000240c:	a03d                	j	8000243a <fork+0xb4>
    freeproc(np);
    8000240e:	854a                	mv	a0,s2
    80002410:	00000097          	auipc	ra,0x0
    80002414:	96a080e7          	jalr	-1686(ra) # 80001d7a <freeproc>
    release(&np->lock);
    80002418:	854a                	mv	a0,s2
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	87e080e7          	jalr	-1922(ra) # 80000c98 <release>
    return -1;
    80002422:	5a7d                	li	s4,-1
    80002424:	aa39                	j	80002542 <fork+0x1bc>
      np->ofile[i] = filedup(p->ofile[i]);
    80002426:	00004097          	auipc	ra,0x4
    8000242a:	800080e7          	jalr	-2048(ra) # 80005c26 <filedup>
    8000242e:	009907b3          	add	a5,s2,s1
    80002432:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002434:	04a1                	addi	s1,s1,8
    80002436:	01448763          	beq	s1,s4,80002444 <fork+0xbe>
    if(p->ofile[i])
    8000243a:	009987b3          	add	a5,s3,s1
    8000243e:	6388                	ld	a0,0(a5)
    80002440:	f17d                	bnez	a0,80002426 <fork+0xa0>
    80002442:	bfcd                	j	80002434 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002444:	1809b503          	ld	a0,384(s3)
    80002448:	00003097          	auipc	ra,0x3
    8000244c:	954080e7          	jalr	-1708(ra) # 80004d9c <idup>
    80002450:	18a93023          	sd	a0,384(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002454:	4641                	li	a2,16
    80002456:	18898593          	addi	a1,s3,392
    8000245a:	18890513          	addi	a0,s2,392
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	9d4080e7          	jalr	-1580(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002466:	03092a03          	lw	s4,48(s2)
  release(&np->lock);
    8000246a:	854a                	mv	a0,s2
    8000246c:	fffff097          	auipc	ra,0xfffff
    80002470:	82c080e7          	jalr	-2004(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002474:	00010497          	auipc	s1,0x10
    80002478:	e4c48493          	addi	s1,s1,-436 # 800122c0 <cpus>
    8000247c:	00010a97          	auipc	s5,0x10
    80002480:	2dca8a93          	addi	s5,s5,732 # 80012758 <wait_lock>
    80002484:	8556                	mv	a0,s5
    80002486:	ffffe097          	auipc	ra,0xffffe
    8000248a:	75e080e7          	jalr	1886(ra) # 80000be4 <acquire>
  np->parent = p;
    8000248e:	07393423          	sd	s3,104(s2)
  release(&wait_lock);
    80002492:	8556                	mv	a0,s5
    80002494:	fffff097          	auipc	ra,0xfffff
    80002498:	804080e7          	jalr	-2044(ra) # 80000c98 <release>
  acquire(&np->lock);
    8000249c:	854a                	mv	a0,s2
    8000249e:	ffffe097          	auipc	ra,0xffffe
    800024a2:	746080e7          	jalr	1862(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800024a6:	478d                	li	a5,3
    800024a8:	00f92c23          	sw	a5,24(s2)
  np->last_runnable_time = ticks;
    800024ac:	00008797          	auipc	a5,0x8
    800024b0:	ba87a783          	lw	a5,-1112(a5) # 8000a054 <ticks>
    800024b4:	02f92e23          	sw	a5,60(s2)
    800024b8:	8792                	mv	a5,tp
  int id = r_tp();
    800024ba:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    800024be:	00371793          	slli	a5,a4,0x3
    800024c2:	00e786b3          	add	a3,a5,a4
    800024c6:	0692                	slli	a3,a3,0x4
    800024c8:	96a6                	add	a3,a3,s1
    800024ca:	08e6a423          	sw	a4,136(a3)
  if (mycpu()->runnable_list_head == -1)
    800024ce:	0806a703          	lw	a4,128(a3)
    800024d2:	57fd                	li	a5,-1
    800024d4:	08f70163          	beq	a4,a5,80002556 <fork+0x1d0>
    printf("runnable2");
    800024d8:	00007517          	auipc	a0,0x7
    800024dc:	e7850513          	addi	a0,a0,-392 # 80009350 <digits+0x310>
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	0a8080e7          	jalr	168(ra) # 80000588 <printf>
    800024e8:	8792                	mv	a5,tp
  int id = r_tp();
    800024ea:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    800024ee:	00010497          	auipc	s1,0x10
    800024f2:	dd248493          	addi	s1,s1,-558 # 800122c0 <cpus>
    800024f6:	00371793          	slli	a5,a4,0x3
    800024fa:	00e786b3          	add	a3,a5,a4
    800024fe:	0692                	slli	a3,a3,0x4
    80002500:	96a6                	add	a3,a3,s1
    80002502:	08e6a423          	sw	a4,136(a3)
    add_proc_to_list(mycpu()->runnable_list_tail, np);
    80002506:	85ca                	mv	a1,s2
    80002508:	0846a503          	lw	a0,132(a3)
    8000250c:	fffff097          	auipc	ra,0xfffff
    80002510:	33a080e7          	jalr	826(ra) # 80001846 <add_proc_to_list>
    80002514:	8792                	mv	a5,tp
  int id = r_tp();
    80002516:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    8000251a:	00371793          	slli	a5,a4,0x3
    8000251e:	00e786b3          	add	a3,a5,a4
    80002522:	0692                	slli	a3,a3,0x4
    80002524:	96a6                	add	a3,a3,s1
    80002526:	08e6a423          	sw	a4,136(a3)
    mycpu()->runnable_list_tail = np->proc_ind;
    8000252a:	05c92683          	lw	a3,92(s2)
    8000252e:	97ba                	add	a5,a5,a4
    80002530:	0792                	slli	a5,a5,0x4
    80002532:	94be                	add	s1,s1,a5
    80002534:	08d4a223          	sw	a3,132(s1)
  release(&np->lock);
    80002538:	854a                	mv	a0,s2
    8000253a:	ffffe097          	auipc	ra,0xffffe
    8000253e:	75e080e7          	jalr	1886(ra) # 80000c98 <release>
}
    80002542:	8552                	mv	a0,s4
    80002544:	70e2                	ld	ra,56(sp)
    80002546:	7442                	ld	s0,48(sp)
    80002548:	74a2                	ld	s1,40(sp)
    8000254a:	7902                	ld	s2,32(sp)
    8000254c:	69e2                	ld	s3,24(sp)
    8000254e:	6a42                	ld	s4,16(sp)
    80002550:	6aa2                	ld	s5,8(sp)
    80002552:	6121                	addi	sp,sp,64
    80002554:	8082                	ret
    printf("init runnable %d                 2\n", p->proc_ind);
    80002556:	05c9a583          	lw	a1,92(s3)
    8000255a:	00007517          	auipc	a0,0x7
    8000255e:	dce50513          	addi	a0,a0,-562 # 80009328 <digits+0x2e8>
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	026080e7          	jalr	38(ra) # 80000588 <printf>
    8000256a:	8792                	mv	a5,tp
  int id = r_tp();
    8000256c:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002570:	00369793          	slli	a5,a3,0x3
    80002574:	00d78633          	add	a2,a5,a3
    80002578:	0612                	slli	a2,a2,0x4
    8000257a:	9626                	add	a2,a2,s1
    8000257c:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_head = np->proc_ind;
    80002580:	05c92603          	lw	a2,92(s2)
    80002584:	97b6                	add	a5,a5,a3
    80002586:	0792                	slli	a5,a5,0x4
    80002588:	97a6                	add	a5,a5,s1
    8000258a:	08c7a023          	sw	a2,128(a5)
    8000258e:	8792                	mv	a5,tp
  int id = r_tp();
    80002590:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002594:	00369793          	slli	a5,a3,0x3
    80002598:	00d78633          	add	a2,a5,a3
    8000259c:	0612                	slli	a2,a2,0x4
    8000259e:	9626                	add	a2,a2,s1
    800025a0:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_tail = np->proc_ind;
    800025a4:	05c92603          	lw	a2,92(s2)
    800025a8:	97b6                	add	a5,a5,a3
    800025aa:	0792                	slli	a5,a5,0x4
    800025ac:	00f48733          	add	a4,s1,a5
    800025b0:	08c72223          	sw	a2,132(a4)
    800025b4:	b751                	j	80002538 <fork+0x1b2>
    return -1;
    800025b6:	5a7d                	li	s4,-1
    800025b8:	b769                	j	80002542 <fork+0x1bc>

00000000800025ba <unpause_system>:
{
    800025ba:	7179                	addi	sp,sp,-48
    800025bc:	f406                	sd	ra,40(sp)
    800025be:	f022                	sd	s0,32(sp)
    800025c0:	ec26                	sd	s1,24(sp)
    800025c2:	e84a                	sd	s2,16(sp)
    800025c4:	e44e                	sd	s3,8(sp)
    800025c6:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) 
    800025c8:	00010497          	auipc	s1,0x10
    800025cc:	1a848493          	addi	s1,s1,424 # 80012770 <proc>
      if(p->paused == 1) 
    800025d0:	4985                	li	s3,1
  for(p = proc; p < &proc[NPROC]; p++) 
    800025d2:	00016917          	auipc	s2,0x16
    800025d6:	79e90913          	addi	s2,s2,1950 # 80018d70 <tickslock>
    800025da:	a811                	j	800025ee <unpause_system+0x34>
      release(&p->lock);
    800025dc:	8526                	mv	a0,s1
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	6ba080e7          	jalr	1722(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) 
    800025e6:	19848493          	addi	s1,s1,408
    800025ea:	01248d63          	beq	s1,s2,80002604 <unpause_system+0x4a>
      acquire(&p->lock);
    800025ee:	8526                	mv	a0,s1
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	5f4080e7          	jalr	1524(ra) # 80000be4 <acquire>
      if(p->paused == 1) 
    800025f8:	40bc                	lw	a5,64(s1)
    800025fa:	ff3791e3          	bne	a5,s3,800025dc <unpause_system+0x22>
        p->paused = 0;
    800025fe:	0404a023          	sw	zero,64(s1)
    80002602:	bfe9                	j	800025dc <unpause_system+0x22>
} 
    80002604:	70a2                	ld	ra,40(sp)
    80002606:	7402                	ld	s0,32(sp)
    80002608:	64e2                	ld	s1,24(sp)
    8000260a:	6942                	ld	s2,16(sp)
    8000260c:	69a2                	ld	s3,8(sp)
    8000260e:	6145                	addi	sp,sp,48
    80002610:	8082                	ret

0000000080002612 <SJF_scheduler>:
{
    80002612:	711d                	addi	sp,sp,-96
    80002614:	ec86                	sd	ra,88(sp)
    80002616:	e8a2                	sd	s0,80(sp)
    80002618:	e4a6                	sd	s1,72(sp)
    8000261a:	e0ca                	sd	s2,64(sp)
    8000261c:	fc4e                	sd	s3,56(sp)
    8000261e:	f852                	sd	s4,48(sp)
    80002620:	f456                	sd	s5,40(sp)
    80002622:	f05a                	sd	s6,32(sp)
    80002624:	ec5e                	sd	s7,24(sp)
    80002626:	e862                	sd	s8,16(sp)
    80002628:	e466                	sd	s9,8(sp)
    8000262a:	e06a                	sd	s10,0(sp)
    8000262c:	1080                	addi	s0,sp,96
    8000262e:	8792                	mv	a5,tp
  int id = r_tp();
    80002630:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    80002632:	00010617          	auipc	a2,0x10
    80002636:	c8e60613          	addi	a2,a2,-882 # 800122c0 <cpus>
    8000263a:	00379713          	slli	a4,a5,0x3
    8000263e:	00f706b3          	add	a3,a4,a5
    80002642:	0692                	slli	a3,a3,0x4
    80002644:	96b2                	add	a3,a3,a2
    80002646:	08f6a423          	sw	a5,136(a3)
  c->proc = 0;
    8000264a:	0006b023          	sd	zero,0(a3)
      swtch(&c->context, &p_of_min->context);
    8000264e:	973e                	add	a4,a4,a5
    80002650:	0712                	slli	a4,a4,0x4
    80002652:	0721                	addi	a4,a4,8
    80002654:	00e60d33          	add	s10,a2,a4
    struct proc* p_of_min = proc;
    80002658:	00010a97          	auipc	s5,0x10
    8000265c:	118a8a93          	addi	s5,s5,280 # 80012770 <proc>
    uint min = INT_MAX;
    80002660:	80000b37          	lui	s6,0x80000
    80002664:	fffb4b13          	not	s6,s6
           should_switch = 1;
    80002668:	4a05                	li	s4,1
    8000266a:	89d2                	mv	s3,s4
      c->proc = p_of_min;
    8000266c:	8bb6                	mv	s7,a3
    8000266e:	a091                	j	800026b2 <SJF_scheduler+0xa0>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002670:	19878793          	addi	a5,a5,408
    80002674:	00d78c63          	beq	a5,a3,8000268c <SJF_scheduler+0x7a>
       if(p->state == RUNNABLE) {
    80002678:	4f98                	lw	a4,24(a5)
    8000267a:	fec71be3          	bne	a4,a2,80002670 <SJF_scheduler+0x5e>
         if (p->mean_ticks < min)
    8000267e:	5bd8                	lw	a4,52(a5)
    80002680:	feb778e3          	bgeu	a4,a1,80002670 <SJF_scheduler+0x5e>
    80002684:	84be                	mv	s1,a5
           min = p->mean_ticks;
    80002686:	85ba                	mv	a1,a4
           should_switch = 1;
    80002688:	894e                	mv	s2,s3
    8000268a:	b7dd                	j	80002670 <SJF_scheduler+0x5e>
    acquire(&p_of_min->lock);
    8000268c:	8c26                	mv	s8,s1
    8000268e:	8526                	mv	a0,s1
    80002690:	ffffe097          	auipc	ra,0xffffe
    80002694:	554080e7          	jalr	1364(ra) # 80000be4 <acquire>
    if (should_switch == 1 && p_of_min->state == RUNNABLE && p_of_min->paused == 0){
    80002698:	03490d63          	beq	s2,s4,800026d2 <SJF_scheduler+0xc0>
    release(&p_of_min->lock);
    8000269c:	8562                	mv	a0,s8
    8000269e:	ffffe097          	auipc	ra,0xffffe
    800026a2:	5fa080e7          	jalr	1530(ra) # 80000c98 <release>
    if (pause_flag == 1) 
    800026a6:	00008797          	auipc	a5,0x8
    800026aa:	9aa7a783          	lw	a5,-1622(a5) # 8000a050 <pause_flag>
    800026ae:	0b478163          	beq	a5,s4,80002750 <SJF_scheduler+0x13e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026b2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800026b6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026ba:	10079073          	csrw	sstatus,a5
    int should_switch = 0;
    800026be:	4901                	li	s2,0
    struct proc* p_of_min = proc;
    800026c0:	84d6                	mv	s1,s5
    uint min = INT_MAX;
    800026c2:	85da                	mv	a1,s6
    for(p = proc; p < &proc[NPROC]; p++) {
    800026c4:	87d6                	mv	a5,s5
       if(p->state == RUNNABLE) {
    800026c6:	460d                	li	a2,3
    for(p = proc; p < &proc[NPROC]; p++) {
    800026c8:	00016697          	auipc	a3,0x16
    800026cc:	6a868693          	addi	a3,a3,1704 # 80018d70 <tickslock>
    800026d0:	b765                	j	80002678 <SJF_scheduler+0x66>
    if (should_switch == 1 && p_of_min->state == RUNNABLE && p_of_min->paused == 0){
    800026d2:	4c98                	lw	a4,24(s1)
    800026d4:	478d                	li	a5,3
    800026d6:	fcf713e3          	bne	a4,a5,8000269c <SJF_scheduler+0x8a>
    800026da:	40bc                	lw	a5,64(s1)
    800026dc:	f3e1                	bnez	a5,8000269c <SJF_scheduler+0x8a>
      p_of_min->state = RUNNING;
    800026de:	4791                	li	a5,4
    800026e0:	cc9c                	sw	a5,24(s1)
      p_of_min->start_running_time = ticks;
    800026e2:	00008c97          	auipc	s9,0x8
    800026e6:	972c8c93          	addi	s9,s9,-1678 # 8000a054 <ticks>
    800026ea:	000ca903          	lw	s2,0(s9)
    800026ee:	0524a823          	sw	s2,80(s1)
      p_of_min->runnable_time += ticks - p_of_min->last_runnable_time;
    800026f2:	44bc                	lw	a5,72(s1)
    800026f4:	012787bb          	addw	a5,a5,s2
    800026f8:	5cd8                	lw	a4,60(s1)
    800026fa:	9f99                	subw	a5,a5,a4
    800026fc:	c4bc                	sw	a5,72(s1)
      c->proc = p_of_min;
    800026fe:	009bb023          	sd	s1,0(s7) # fffffffffffff000 <end+0xffffffff7ffd7000>
      swtch(&c->context, &p_of_min->context);
    80002702:	09048593          	addi	a1,s1,144
    80002706:	856a                	mv	a0,s10
    80002708:	00001097          	auipc	ra,0x1
    8000270c:	5b4080e7          	jalr	1460(ra) # 80003cbc <swtch>
      p_of_min->last_ticks= ticks - before_swtch;
    80002710:	000ca783          	lw	a5,0(s9)
    80002714:	4127893b          	subw	s2,a5,s2
    80002718:	0324ac23          	sw	s2,56(s1)
      p_of_min->mean_ticks=((10 - rate) * p->mean_ticks + p->last_ticks * (rate)) / 10 ;
    8000271c:	00007617          	auipc	a2,0x7
    80002720:	5a462603          	lw	a2,1444(a2) # 80009cc0 <rate>
    80002724:	46a9                	li	a3,10
    80002726:	40c687bb          	subw	a5,a3,a2
    8000272a:	00016717          	auipc	a4,0x16
    8000272e:	04670713          	addi	a4,a4,70 # 80018770 <proc+0x6000>
    80002732:	63472583          	lw	a1,1588(a4)
    80002736:	02b787bb          	mulw	a5,a5,a1
    8000273a:	63872703          	lw	a4,1592(a4)
    8000273e:	02c7073b          	mulw	a4,a4,a2
    80002742:	9fb9                	addw	a5,a5,a4
    80002744:	02d7d7bb          	divuw	a5,a5,a3
    80002748:	d8dc                	sw	a5,52(s1)
      c->proc = 0;
    8000274a:	000bb023          	sd	zero,0(s7)
    8000274e:	b7b9                	j	8000269c <SJF_scheduler+0x8a>
      if (wake_up_time <= ticks) 
    80002750:	00008717          	auipc	a4,0x8
    80002754:	8fc72703          	lw	a4,-1796(a4) # 8000a04c <wake_up_time>
    80002758:	00008797          	auipc	a5,0x8
    8000275c:	8fc7a783          	lw	a5,-1796(a5) # 8000a054 <ticks>
    80002760:	f4e7e9e3          	bltu	a5,a4,800026b2 <SJF_scheduler+0xa0>
        pause_flag = 0;
    80002764:	00008797          	auipc	a5,0x8
    80002768:	8e07a623          	sw	zero,-1812(a5) # 8000a050 <pause_flag>
        unpause_system();
    8000276c:	00000097          	auipc	ra,0x0
    80002770:	e4e080e7          	jalr	-434(ra) # 800025ba <unpause_system>
    80002774:	bf3d                	j	800026b2 <SJF_scheduler+0xa0>

0000000080002776 <FCFS_scheduler>:
{
    80002776:	7119                	addi	sp,sp,-128
    80002778:	fc86                	sd	ra,120(sp)
    8000277a:	f8a2                	sd	s0,112(sp)
    8000277c:	f4a6                	sd	s1,104(sp)
    8000277e:	f0ca                	sd	s2,96(sp)
    80002780:	ecce                	sd	s3,88(sp)
    80002782:	e8d2                	sd	s4,80(sp)
    80002784:	e4d6                	sd	s5,72(sp)
    80002786:	e0da                	sd	s6,64(sp)
    80002788:	fc5e                	sd	s7,56(sp)
    8000278a:	f862                	sd	s8,48(sp)
    8000278c:	f466                	sd	s9,40(sp)
    8000278e:	f06a                	sd	s10,32(sp)
    80002790:	ec6e                	sd	s11,24(sp)
    80002792:	0100                	addi	s0,sp,128
  asm volatile("mv %0, tp" : "=r" (x) );
    80002794:	8792                	mv	a5,tp
  int id = r_tp();
    80002796:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    80002798:	00010617          	auipc	a2,0x10
    8000279c:	b2860613          	addi	a2,a2,-1240 # 800122c0 <cpus>
    800027a0:	00379713          	slli	a4,a5,0x3
    800027a4:	00f706b3          	add	a3,a4,a5
    800027a8:	0692                	slli	a3,a3,0x4
    800027aa:	96b2                	add	a3,a3,a2
    800027ac:	08f6a423          	sw	a5,136(a3)
  c->proc = 0;
    800027b0:	0006b023          	sd	zero,0(a3)
        swtch(&c->context, &p_of_min->context);
    800027b4:	973e                	add	a4,a4,a5
    800027b6:	0712                	slli	a4,a4,0x4
    800027b8:	0721                	addi	a4,a4,8
    800027ba:	9732                	add	a4,a4,a2
    800027bc:	f8e43423          	sd	a4,-120(s0)
  int should_switch = 0;
    800027c0:	4b01                	li	s6,0
    struct proc *p_of_min = proc;
    800027c2:	00010c17          	auipc	s8,0x10
    800027c6:	faec0c13          	addi	s8,s8,-82 # 80012770 <proc>
    uint minlast_runnable = INT_MAX;
    800027ca:	80000d37          	lui	s10,0x80000
    800027ce:	fffd4d13          	not	s10,s10
          should_switch = 1;
    800027d2:	4c85                	li	s9,1
    800027d4:	8be6                	mv	s7,s9
        c->proc = p_of_min;
    800027d6:	8db6                	mv	s11,a3
    800027d8:	a095                	j	8000283c <FCFS_scheduler+0xc6>
      release(&p->lock);
    800027da:	8526                	mv	a0,s1
    800027dc:	ffffe097          	auipc	ra,0xffffe
    800027e0:	4bc080e7          	jalr	1212(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) 
    800027e4:	19848493          	addi	s1,s1,408
    800027e8:	03248463          	beq	s1,s2,80002810 <FCFS_scheduler+0x9a>
      acquire(&p->lock);
    800027ec:	8526                	mv	a0,s1
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	3f6080e7          	jalr	1014(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE && p->paused == 0) 
    800027f6:	4c9c                	lw	a5,24(s1)
    800027f8:	ff3791e3          	bne	a5,s3,800027da <FCFS_scheduler+0x64>
    800027fc:	40bc                	lw	a5,64(s1)
    800027fe:	fff1                	bnez	a5,800027da <FCFS_scheduler+0x64>
        if(p->last_runnable_time <= minlast_runnable)
    80002800:	5cdc                	lw	a5,60(s1)
    80002802:	fcfa6ce3          	bltu	s4,a5,800027da <FCFS_scheduler+0x64>
          minlast_runnable = p->mean_ticks;
    80002806:	0344aa03          	lw	s4,52(s1)
    8000280a:	8aa6                	mv	s5,s1
          should_switch = 1;
    8000280c:	8b5e                	mv	s6,s7
    8000280e:	b7f1                	j	800027da <FCFS_scheduler+0x64>
    acquire(&p_of_min->lock);
    80002810:	8956                	mv	s2,s5
    80002812:	8556                	mv	a0,s5
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	3d0080e7          	jalr	976(ra) # 80000be4 <acquire>
    if (p_of_min->paused == 0)
    8000281c:	040aa483          	lw	s1,64(s5)
    80002820:	e099                	bnez	s1,80002826 <FCFS_scheduler+0xb0>
      if (should_switch == 1 && p_of_min->pid > -1)
    80002822:	039b0c63          	beq	s6,s9,8000285a <FCFS_scheduler+0xe4>
    release(&p_of_min->lock);
    80002826:	854a                	mv	a0,s2
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	470080e7          	jalr	1136(ra) # 80000c98 <release>
    if (pause_flag == 1) 
    80002830:	00008797          	auipc	a5,0x8
    80002834:	8207a783          	lw	a5,-2016(a5) # 8000a050 <pause_flag>
    80002838:	07978463          	beq	a5,s9,800028a0 <FCFS_scheduler+0x12a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000283c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002840:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002844:	10079073          	csrw	sstatus,a5
    struct proc *p_of_min = proc;
    80002848:	8ae2                	mv	s5,s8
    uint minlast_runnable = INT_MAX;
    8000284a:	8a6a                	mv	s4,s10
    for(p = proc; p < &proc[NPROC]; p++) 
    8000284c:	84e2                	mv	s1,s8
      if(p->state == RUNNABLE && p->paused == 0) 
    8000284e:	498d                	li	s3,3
    for(p = proc; p < &proc[NPROC]; p++) 
    80002850:	00016917          	auipc	s2,0x16
    80002854:	52090913          	addi	s2,s2,1312 # 80018d70 <tickslock>
    80002858:	bf51                	j	800027ec <FCFS_scheduler+0x76>
      if (should_switch == 1 && p_of_min->pid > -1)
    8000285a:	030aa783          	lw	a5,48(s5)
    8000285e:	fc07c4e3          	bltz	a5,80002826 <FCFS_scheduler+0xb0>
        p_of_min->state = RUNNING;
    80002862:	4791                	li	a5,4
    80002864:	00faac23          	sw	a5,24(s5)
        p_of_min->start_running_time = ticks;
    80002868:	00007717          	auipc	a4,0x7
    8000286c:	7ec72703          	lw	a4,2028(a4) # 8000a054 <ticks>
    80002870:	04eaa823          	sw	a4,80(s5)
        p_of_min->runnable_time += ticks - p_of_min->last_runnable_time;
    80002874:	048aa783          	lw	a5,72(s5)
    80002878:	9fb9                	addw	a5,a5,a4
    8000287a:	03caa703          	lw	a4,60(s5)
    8000287e:	9f99                	subw	a5,a5,a4
    80002880:	04faa423          	sw	a5,72(s5)
        c->proc = p_of_min;
    80002884:	015db023          	sd	s5,0(s11)
        swtch(&c->context, &p_of_min->context);
    80002888:	090a8593          	addi	a1,s5,144
    8000288c:	f8843503          	ld	a0,-120(s0)
    80002890:	00001097          	auipc	ra,0x1
    80002894:	42c080e7          	jalr	1068(ra) # 80003cbc <swtch>
        c->proc = 0;
    80002898:	000db023          	sd	zero,0(s11)
        should_switch = 0;
    8000289c:	8b26                	mv	s6,s1
    8000289e:	b761                	j	80002826 <FCFS_scheduler+0xb0>
      if (wake_up_time <= ticks) 
    800028a0:	00007717          	auipc	a4,0x7
    800028a4:	7ac72703          	lw	a4,1964(a4) # 8000a04c <wake_up_time>
    800028a8:	00007797          	auipc	a5,0x7
    800028ac:	7ac7a783          	lw	a5,1964(a5) # 8000a054 <ticks>
    800028b0:	f8e7e6e3          	bltu	a5,a4,8000283c <FCFS_scheduler+0xc6>
        pause_flag = 0;
    800028b4:	00007797          	auipc	a5,0x7
    800028b8:	7807ae23          	sw	zero,1948(a5) # 8000a050 <pause_flag>
        unpause_system();
    800028bc:	00000097          	auipc	ra,0x0
    800028c0:	cfe080e7          	jalr	-770(ra) # 800025ba <unpause_system>
    800028c4:	bfa5                	j	8000283c <FCFS_scheduler+0xc6>

00000000800028c6 <scheduler>:
{
    800028c6:	7159                	addi	sp,sp,-112
    800028c8:	f486                	sd	ra,104(sp)
    800028ca:	f0a2                	sd	s0,96(sp)
    800028cc:	eca6                	sd	s1,88(sp)
    800028ce:	e8ca                	sd	s2,80(sp)
    800028d0:	e4ce                	sd	s3,72(sp)
    800028d2:	e0d2                	sd	s4,64(sp)
    800028d4:	fc56                	sd	s5,56(sp)
    800028d6:	f85a                	sd	s6,48(sp)
    800028d8:	f45e                	sd	s7,40(sp)
    800028da:	f062                	sd	s8,32(sp)
    800028dc:	ec66                	sd	s9,24(sp)
    800028de:	e86a                	sd	s10,16(sp)
    800028e0:	e46e                	sd	s11,8(sp)
    800028e2:	1880                	addi	s0,sp,112
  asm volatile("mv %0, tp" : "=r" (x) );
    800028e4:	8792                	mv	a5,tp
  int id = r_tp();
    800028e6:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    800028e8:	00010c17          	auipc	s8,0x10
    800028ec:	9d8c0c13          	addi	s8,s8,-1576 # 800122c0 <cpus>
    800028f0:	00379713          	slli	a4,a5,0x3
    800028f4:	00f706b3          	add	a3,a4,a5
    800028f8:	0692                	slli	a3,a3,0x4
    800028fa:	96e2                	add	a3,a3,s8
    800028fc:	08f6a423          	sw	a5,136(a3)
  c->proc = 0;
    80002900:	0006b023          	sd	zero,0(a3)
      swtch(&c->context, &p->context);
    80002904:	973e                	add	a4,a4,a5
    80002906:	0712                	slli	a4,a4,0x4
    80002908:	0721                	addi	a4,a4,8
    8000290a:	9c3a                	add	s8,s8,a4
    printf("start sched\n");
    8000290c:	00007a17          	auipc	s4,0x7
    80002910:	a54a0a13          	addi	s4,s4,-1452 # 80009360 <digits+0x320>
    if (c->runnable_list_head != -1)
    80002914:	8936                	mv	s2,a3
    80002916:	59fd                	li	s3,-1
    80002918:	19800b13          	li	s6,408
      p = &proc[c->runnable_list_head];
    8000291c:	00010a97          	auipc	s5,0x10
    80002920:	e54a8a93          	addi	s5,s5,-428 # 80012770 <proc>
      printf("proc ind: %d\n", c->runnable_list_head);
    80002924:	00007c97          	auipc	s9,0x7
    80002928:	a4cc8c93          	addi	s9,s9,-1460 # 80009370 <digits+0x330>
        proc[p->prev_proc].next_proc = -1;
    8000292c:	5bfd                	li	s7,-1
    8000292e:	a8c1                	j	800029fe <scheduler+0x138>
        c->runnable_list_head = -1;
    80002930:	09792023          	sw	s7,128(s2)
        c->runnable_list_tail = -1;
    80002934:	09792223          	sw	s7,132(s2)
        printf("No head & tail");
    80002938:	00007517          	auipc	a0,0x7
    8000293c:	a5850513          	addi	a0,a0,-1448 # 80009390 <digits+0x350>
    80002940:	ffffe097          	auipc	ra,0xffffe
    80002944:	c48080e7          	jalr	-952(ra) # 80000588 <printf>
      if (res == 3){
    80002948:	a815                	j	8000297c <scheduler+0xb6>
        c->runnable_list_head = p->next_proc;
    8000294a:	036487b3          	mul	a5,s1,s6
    8000294e:	97d6                	add	a5,a5,s5
    80002950:	53ac                	lw	a1,96(a5)
    80002952:	08b92023          	sw	a1,128(s2)
        if (proc[p->next_proc].next_proc == -1)
    80002956:	036587b3          	mul	a5,a1,s6
    8000295a:	97d6                	add	a5,a5,s5
    8000295c:	53bc                	lw	a5,96(a5)
    8000295e:	13378a63          	beq	a5,s3,80002a92 <scheduler+0x1cc>
        proc[p->next_proc].prev_proc = -1;
    80002962:	036587b3          	mul	a5,a1,s6
    80002966:	97d6                	add	a5,a5,s5
    80002968:	0777a223          	sw	s7,100(a5)
        printf("New head: %d\n", c->runnable_list_head);
    8000296c:	00007517          	auipc	a0,0x7
    80002970:	a3450513          	addi	a0,a0,-1484 # 800093a0 <digits+0x360>
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	c14080e7          	jalr	-1004(ra) # 80000588 <printf>
      acquire(&p->lock);
    8000297c:	856a                	mv	a0,s10
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	266080e7          	jalr	614(ra) # 80000be4 <acquire>
      p->prev_proc = -1;
    80002986:	036487b3          	mul	a5,s1,s6
    8000298a:	97d6                	add	a5,a5,s5
    8000298c:	0777a223          	sw	s7,100(a5)
      p->next_proc = -1;
    80002990:	0777a023          	sw	s7,96(a5)
      p->state = RUNNING;
    80002994:	4711                	li	a4,4
    80002996:	cf98                	sw	a4,24(a5)
      p->cpu_num = c->cpu_id;
    80002998:	08892703          	lw	a4,136(s2)
    8000299c:	cfb8                	sw	a4,88(a5)
      c->proc = p;
    8000299e:	01a93023          	sd	s10,0(s2)
      swtch(&c->context, &p->context);
    800029a2:	090d8593          	addi	a1,s11,144
    800029a6:	95d6                	add	a1,a1,s5
    800029a8:	8562                	mv	a0,s8
    800029aa:	00001097          	auipc	ra,0x1
    800029ae:	312080e7          	jalr	786(ra) # 80003cbc <swtch>
      if (c->runnable_list_head == -1)
    800029b2:	08092783          	lw	a5,128(s2)
    800029b6:	0f379463          	bne	a5,s3,80002a9e <scheduler+0x1d8>
        printf("init runnable %d  , prev: %d, next: %d                           7\n", p->proc_ind, p->prev_proc, p->next_proc);
    800029ba:	036484b3          	mul	s1,s1,s6
    800029be:	94d6                	add	s1,s1,s5
    800029c0:	50b4                	lw	a3,96(s1)
    800029c2:	50f0                	lw	a2,100(s1)
    800029c4:	4cec                	lw	a1,92(s1)
    800029c6:	00007517          	auipc	a0,0x7
    800029ca:	9f250513          	addi	a0,a0,-1550 # 800093b8 <digits+0x378>
    800029ce:	ffffe097          	auipc	ra,0xffffe
    800029d2:	bba080e7          	jalr	-1094(ra) # 80000588 <printf>
        c->runnable_list_head = p->proc_ind;
    800029d6:	4cfc                	lw	a5,92(s1)
    800029d8:	08f92023          	sw	a5,128(s2)
        c->runnable_list_tail = p->proc_ind;
    800029dc:	08f92223          	sw	a5,132(s2)
      c->proc = 0;
    800029e0:	00093023          	sd	zero,0(s2)
      release(&p->lock);
    800029e4:	856a                	mv	a0,s10
    800029e6:	ffffe097          	auipc	ra,0xffffe
    800029ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
      printf("end sched\n");
    800029ee:	00007517          	auipc	a0,0x7
    800029f2:	a4a50513          	addi	a0,a0,-1462 # 80009438 <digits+0x3f8>
    800029f6:	ffffe097          	auipc	ra,0xffffe
    800029fa:	b92080e7          	jalr	-1134(ra) # 80000588 <printf>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029fe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a02:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a06:	10079073          	csrw	sstatus,a5
    printf("start sched\n");
    80002a0a:	8552                	mv	a0,s4
    80002a0c:	ffffe097          	auipc	ra,0xffffe
    80002a10:	b7c080e7          	jalr	-1156(ra) # 80000588 <printf>
    if (c->runnable_list_head != -1)
    80002a14:	08092483          	lw	s1,128(s2)
    80002a18:	ff3483e3          	beq	s1,s3,800029fe <scheduler+0x138>
      p = &proc[c->runnable_list_head];
    80002a1c:	03648db3          	mul	s11,s1,s6
    80002a20:	015d8d33          	add	s10,s11,s5
      printf("proc ind: %d\n", c->runnable_list_head);
    80002a24:	85a6                	mv	a1,s1
    80002a26:	8566                	mv	a0,s9
    80002a28:	ffffe097          	auipc	ra,0xffffe
    80002a2c:	b60080e7          	jalr	-1184(ra) # 80000588 <printf>
      printf("runnable3");
    80002a30:	00007517          	auipc	a0,0x7
    80002a34:	95050513          	addi	a0,a0,-1712 # 80009380 <digits+0x340>
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	b50080e7          	jalr	-1200(ra) # 80000588 <printf>
      int res = remove_proc_from_list(p->proc_ind); 
    80002a40:	05cd2503          	lw	a0,92(s10) # ffffffff8000005c <end+0xfffffffefffd805c>
    80002a44:	fffff097          	auipc	ra,0xfffff
    80002a48:	e80080e7          	jalr	-384(ra) # 800018c4 <remove_proc_from_list>
      if (res == 1)
    80002a4c:	4785                	li	a5,1
    80002a4e:	eef501e3          	beq	a0,a5,80002930 <scheduler+0x6a>
      if (res == 2)
    80002a52:	4789                	li	a5,2
    80002a54:	eef50be3          	beq	a0,a5,8000294a <scheduler+0x84>
      if (res == 3){
    80002a58:	478d                	li	a5,3
    80002a5a:	f2f511e3          	bne	a0,a5,8000297c <scheduler+0xb6>
        c->runnable_list_tail = p->prev_proc;
    80002a5e:	036487b3          	mul	a5,s1,s6
    80002a62:	97d6                	add	a5,a5,s5
    80002a64:	53fc                	lw	a5,100(a5)
    80002a66:	08f92223          	sw	a5,132(s2)
        if (proc[p->prev_proc].prev_proc == -1)
    80002a6a:	03678733          	mul	a4,a5,s6
    80002a6e:	9756                	add	a4,a4,s5
    80002a70:	5378                	lw	a4,100(a4)
    80002a72:	03370363          	beq	a4,s3,80002a98 <scheduler+0x1d2>
        proc[p->prev_proc].next_proc = -1;
    80002a76:	036787b3          	mul	a5,a5,s6
    80002a7a:	97d6                	add	a5,a5,s5
    80002a7c:	0777a023          	sw	s7,96(a5)
        printf("No tail");
    80002a80:	00007517          	auipc	a0,0x7
    80002a84:	93050513          	addi	a0,a0,-1744 # 800093b0 <digits+0x370>
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	b00080e7          	jalr	-1280(ra) # 80000588 <printf>
    80002a90:	b5f5                	j	8000297c <scheduler+0xb6>
          c->runnable_list_tail = p->next_proc;
    80002a92:	08b92223          	sw	a1,132(s2)
    80002a96:	b5f1                	j	80002962 <scheduler+0x9c>
          c->runnable_list_head = p->prev_proc;
    80002a98:	08f92023          	sw	a5,128(s2)
    80002a9c:	bfe9                	j	80002a76 <scheduler+0x1b0>
        printf("runnable7");
    80002a9e:	00007517          	auipc	a0,0x7
    80002aa2:	96250513          	addi	a0,a0,-1694 # 80009400 <digits+0x3c0>
    80002aa6:	ffffe097          	auipc	ra,0xffffe
    80002aaa:	ae2080e7          	jalr	-1310(ra) # 80000588 <printf>
        add_proc_to_list(c->runnable_list_tail, p);
    80002aae:	85ea                	mv	a1,s10
    80002ab0:	08492503          	lw	a0,132(s2)
    80002ab4:	fffff097          	auipc	ra,0xfffff
    80002ab8:	d92080e7          	jalr	-622(ra) # 80001846 <add_proc_to_list>
        c->runnable_list_tail = p->proc_ind;
    80002abc:	036484b3          	mul	s1,s1,s6
    80002ac0:	94d6                	add	s1,s1,s5
    80002ac2:	4cec                	lw	a1,92(s1)
    80002ac4:	08b92223          	sw	a1,132(s2)
        printf("added back: %d, prev: %d, next: %d\n", c->runnable_list_tail, proc[c->runnable_list_tail].prev_proc, proc[c->runnable_list_tail].next_proc);
    80002ac8:	036587b3          	mul	a5,a1,s6
    80002acc:	97d6                	add	a5,a5,s5
    80002ace:	53b4                	lw	a3,96(a5)
    80002ad0:	53f0                	lw	a2,100(a5)
    80002ad2:	00007517          	auipc	a0,0x7
    80002ad6:	93e50513          	addi	a0,a0,-1730 # 80009410 <digits+0x3d0>
    80002ada:	ffffe097          	auipc	ra,0xffffe
    80002ade:	aae080e7          	jalr	-1362(ra) # 80000588 <printf>
    80002ae2:	bdfd                	j	800029e0 <scheduler+0x11a>

0000000080002ae4 <sched>:
{
    80002ae4:	7179                	addi	sp,sp,-48
    80002ae6:	f406                	sd	ra,40(sp)
    80002ae8:	f022                	sd	s0,32(sp)
    80002aea:	ec26                	sd	s1,24(sp)
    80002aec:	e84a                	sd	s2,16(sp)
    80002aee:	e44e                	sd	s3,8(sp)
    80002af0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002af2:	fffff097          	auipc	ra,0xfffff
    80002af6:	0d2080e7          	jalr	210(ra) # 80001bc4 <myproc>
    80002afa:	892a                	mv	s2,a0
  if(!holding(&p->lock))
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	06e080e7          	jalr	110(ra) # 80000b6a <holding>
    80002b04:	c55d                	beqz	a0,80002bb2 <sched+0xce>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b06:	8792                	mv	a5,tp
  int id = r_tp();
    80002b08:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002b0c:	0000f617          	auipc	a2,0xf
    80002b10:	7b460613          	addi	a2,a2,1972 # 800122c0 <cpus>
    80002b14:	00371793          	slli	a5,a4,0x3
    80002b18:	00e786b3          	add	a3,a5,a4
    80002b1c:	0692                	slli	a3,a3,0x4
    80002b1e:	96b2                	add	a3,a3,a2
    80002b20:	08e6a423          	sw	a4,136(a3)
  if(mycpu()->noff != 1)
    80002b24:	5eb8                	lw	a4,120(a3)
    80002b26:	4785                	li	a5,1
    80002b28:	08f71d63          	bne	a4,a5,80002bc2 <sched+0xde>
  if(p->state == RUNNING)
    80002b2c:	01892703          	lw	a4,24(s2)
    80002b30:	4791                	li	a5,4
    80002b32:	0af70063          	beq	a4,a5,80002bd2 <sched+0xee>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b36:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b3a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002b3c:	e3dd                	bnez	a5,80002be2 <sched+0xfe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b3e:	8792                	mv	a5,tp
  int id = r_tp();
    80002b40:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002b44:	0000f497          	auipc	s1,0xf
    80002b48:	77c48493          	addi	s1,s1,1916 # 800122c0 <cpus>
    80002b4c:	00371793          	slli	a5,a4,0x3
    80002b50:	00e786b3          	add	a3,a5,a4
    80002b54:	0692                	slli	a3,a3,0x4
    80002b56:	96a6                	add	a3,a3,s1
    80002b58:	08e6a423          	sw	a4,136(a3)
  intena = mycpu()->intena;
    80002b5c:	07c6a983          	lw	s3,124(a3)
    80002b60:	8592                	mv	a1,tp
  int id = r_tp();
    80002b62:	0005879b          	sext.w	a5,a1
  c->cpu_id = id;
    80002b66:	00379593          	slli	a1,a5,0x3
    80002b6a:	00f58733          	add	a4,a1,a5
    80002b6e:	0712                	slli	a4,a4,0x4
    80002b70:	9726                	add	a4,a4,s1
    80002b72:	08f72423          	sw	a5,136(a4)
  swtch(&p->context, &mycpu()->context);
    80002b76:	95be                	add	a1,a1,a5
    80002b78:	0592                	slli	a1,a1,0x4
    80002b7a:	05a1                	addi	a1,a1,8
    80002b7c:	95a6                	add	a1,a1,s1
    80002b7e:	09090513          	addi	a0,s2,144
    80002b82:	00001097          	auipc	ra,0x1
    80002b86:	13a080e7          	jalr	314(ra) # 80003cbc <swtch>
    80002b8a:	8792                	mv	a5,tp
  int id = r_tp();
    80002b8c:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002b90:	00371793          	slli	a5,a4,0x3
    80002b94:	00e786b3          	add	a3,a5,a4
    80002b98:	0692                	slli	a3,a3,0x4
    80002b9a:	96a6                	add	a3,a3,s1
    80002b9c:	08e6a423          	sw	a4,136(a3)
  mycpu()->intena = intena;
    80002ba0:	0736ae23          	sw	s3,124(a3)
}
    80002ba4:	70a2                	ld	ra,40(sp)
    80002ba6:	7402                	ld	s0,32(sp)
    80002ba8:	64e2                	ld	s1,24(sp)
    80002baa:	6942                	ld	s2,16(sp)
    80002bac:	69a2                	ld	s3,8(sp)
    80002bae:	6145                	addi	sp,sp,48
    80002bb0:	8082                	ret
    panic("sched p->lock");
    80002bb2:	00007517          	auipc	a0,0x7
    80002bb6:	89650513          	addi	a0,a0,-1898 # 80009448 <digits+0x408>
    80002bba:	ffffe097          	auipc	ra,0xffffe
    80002bbe:	984080e7          	jalr	-1660(ra) # 8000053e <panic>
    panic("sched locks");
    80002bc2:	00007517          	auipc	a0,0x7
    80002bc6:	89650513          	addi	a0,a0,-1898 # 80009458 <digits+0x418>
    80002bca:	ffffe097          	auipc	ra,0xffffe
    80002bce:	974080e7          	jalr	-1676(ra) # 8000053e <panic>
    panic("sched running");
    80002bd2:	00007517          	auipc	a0,0x7
    80002bd6:	89650513          	addi	a0,a0,-1898 # 80009468 <digits+0x428>
    80002bda:	ffffe097          	auipc	ra,0xffffe
    80002bde:	964080e7          	jalr	-1692(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002be2:	00007517          	auipc	a0,0x7
    80002be6:	89650513          	addi	a0,a0,-1898 # 80009478 <digits+0x438>
    80002bea:	ffffe097          	auipc	ra,0xffffe
    80002bee:	954080e7          	jalr	-1708(ra) # 8000053e <panic>

0000000080002bf2 <yield>:
{
    80002bf2:	1101                	addi	sp,sp,-32
    80002bf4:	ec06                	sd	ra,24(sp)
    80002bf6:	e822                	sd	s0,16(sp)
    80002bf8:	e426                	sd	s1,8(sp)
    80002bfa:	e04a                	sd	s2,0(sp)
    80002bfc:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002bfe:	fffff097          	auipc	ra,0xfffff
    80002c02:	fc6080e7          	jalr	-58(ra) # 80001bc4 <myproc>
    80002c06:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002c08:	ffffe097          	auipc	ra,0xffffe
    80002c0c:	fdc080e7          	jalr	-36(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002c10:	478d                	li	a5,3
    80002c12:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    80002c14:	00007797          	auipc	a5,0x7
    80002c18:	4407a783          	lw	a5,1088(a5) # 8000a054 <ticks>
    80002c1c:	dcdc                	sw	a5,60(s1)
    80002c1e:	8792                	mv	a5,tp
  int id = r_tp();
    80002c20:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002c24:	0000f617          	auipc	a2,0xf
    80002c28:	69c60613          	addi	a2,a2,1692 # 800122c0 <cpus>
    80002c2c:	00371793          	slli	a5,a4,0x3
    80002c30:	00e786b3          	add	a3,a5,a4
    80002c34:	0692                	slli	a3,a3,0x4
    80002c36:	96b2                	add	a3,a3,a2
    80002c38:	08e6a423          	sw	a4,136(a3)
   if (mycpu()->runnable_list_head == -1)
    80002c3c:	0806a703          	lw	a4,128(a3)
    80002c40:	57fd                	li	a5,-1
    80002c42:	08f70063          	beq	a4,a5,80002cc2 <yield+0xd0>
    printf("runnable8");
    80002c46:	00007517          	auipc	a0,0x7
    80002c4a:	87250513          	addi	a0,a0,-1934 # 800094b8 <digits+0x478>
    80002c4e:	ffffe097          	auipc	ra,0xffffe
    80002c52:	93a080e7          	jalr	-1734(ra) # 80000588 <printf>
    80002c56:	8792                	mv	a5,tp
  int id = r_tp();
    80002c58:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002c5c:	0000f917          	auipc	s2,0xf
    80002c60:	66490913          	addi	s2,s2,1636 # 800122c0 <cpus>
    80002c64:	00371793          	slli	a5,a4,0x3
    80002c68:	00e786b3          	add	a3,a5,a4
    80002c6c:	0692                	slli	a3,a3,0x4
    80002c6e:	96ca                	add	a3,a3,s2
    80002c70:	08e6a423          	sw	a4,136(a3)
    add_proc_to_list(mycpu()->runnable_list_tail, p);
    80002c74:	85a6                	mv	a1,s1
    80002c76:	0846a503          	lw	a0,132(a3)
    80002c7a:	fffff097          	auipc	ra,0xfffff
    80002c7e:	bcc080e7          	jalr	-1076(ra) # 80001846 <add_proc_to_list>
    80002c82:	8792                	mv	a5,tp
  int id = r_tp();
    80002c84:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002c88:	00371793          	slli	a5,a4,0x3
    80002c8c:	00e786b3          	add	a3,a5,a4
    80002c90:	0692                	slli	a3,a3,0x4
    80002c92:	96ca                	add	a3,a3,s2
    80002c94:	08e6a423          	sw	a4,136(a3)
    mycpu()->runnable_list_tail = p->proc_ind;
    80002c98:	4cf4                	lw	a3,92(s1)
    80002c9a:	97ba                	add	a5,a5,a4
    80002c9c:	0792                	slli	a5,a5,0x4
    80002c9e:	993e                	add	s2,s2,a5
    80002ca0:	08d92223          	sw	a3,132(s2)
  sched();
    80002ca4:	00000097          	auipc	ra,0x0
    80002ca8:	e40080e7          	jalr	-448(ra) # 80002ae4 <sched>
  release(&p->lock);
    80002cac:	8526                	mv	a0,s1
    80002cae:	ffffe097          	auipc	ra,0xffffe
    80002cb2:	fea080e7          	jalr	-22(ra) # 80000c98 <release>
}
    80002cb6:	60e2                	ld	ra,24(sp)
    80002cb8:	6442                	ld	s0,16(sp)
    80002cba:	64a2                	ld	s1,8(sp)
    80002cbc:	6902                	ld	s2,0(sp)
    80002cbe:	6105                	addi	sp,sp,32
    80002cc0:	8082                	ret
     printf("init runnable : %d                   8\n", p->proc_ind);
    80002cc2:	4cec                	lw	a1,92(s1)
    80002cc4:	00006517          	auipc	a0,0x6
    80002cc8:	7cc50513          	addi	a0,a0,1996 # 80009490 <digits+0x450>
    80002ccc:	ffffe097          	auipc	ra,0xffffe
    80002cd0:	8bc080e7          	jalr	-1860(ra) # 80000588 <printf>
    80002cd4:	8792                	mv	a5,tp
  int id = r_tp();
    80002cd6:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002cda:	0000f717          	auipc	a4,0xf
    80002cde:	5e670713          	addi	a4,a4,1510 # 800122c0 <cpus>
    80002ce2:	00369793          	slli	a5,a3,0x3
    80002ce6:	00d78633          	add	a2,a5,a3
    80002cea:	0612                	slli	a2,a2,0x4
    80002cec:	963a                	add	a2,a2,a4
    80002cee:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_head = p->proc_ind;
    80002cf2:	4cf0                	lw	a2,92(s1)
    80002cf4:	97b6                	add	a5,a5,a3
    80002cf6:	0792                	slli	a5,a5,0x4
    80002cf8:	97ba                	add	a5,a5,a4
    80002cfa:	08c7a023          	sw	a2,128(a5)
    80002cfe:	8792                	mv	a5,tp
  int id = r_tp();
    80002d00:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002d04:	00369793          	slli	a5,a3,0x3
    80002d08:	00d78633          	add	a2,a5,a3
    80002d0c:	0612                	slli	a2,a2,0x4
    80002d0e:	963a                	add	a2,a2,a4
    80002d10:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_tail = p->proc_ind;
    80002d14:	4cf0                	lw	a2,92(s1)
    80002d16:	97b6                	add	a5,a5,a3
    80002d18:	0792                	slli	a5,a5,0x4
    80002d1a:	973e                	add	a4,a4,a5
    80002d1c:	08c72223          	sw	a2,132(a4)
    80002d20:	b751                	j	80002ca4 <yield+0xb2>

0000000080002d22 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002d22:	7179                	addi	sp,sp,-48
    80002d24:	f406                	sd	ra,40(sp)
    80002d26:	f022                	sd	s0,32(sp)
    80002d28:	ec26                	sd	s1,24(sp)
    80002d2a:	e84a                	sd	s2,16(sp)
    80002d2c:	e44e                	sd	s3,8(sp)
    80002d2e:	1800                	addi	s0,sp,48
    80002d30:	89aa                	mv	s3,a0
    80002d32:	892e                	mv	s2,a1
  // TODO: remove from RUNNABLE and add to SLEEPING
  struct proc *p = myproc();
    80002d34:	fffff097          	auipc	ra,0xfffff
    80002d38:	e90080e7          	jalr	-368(ra) # 80001bc4 <myproc>
    80002d3c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002d3e:	ffffe097          	auipc	ra,0xffffe
    80002d42:	ea6080e7          	jalr	-346(ra) # 80000be4 <acquire>
  release(lk);
    80002d46:	854a                	mv	a0,s2
    80002d48:	ffffe097          	auipc	ra,0xffffe
    80002d4c:	f50080e7          	jalr	-176(ra) # 80000c98 <release>

  //Ass2
  printf("runnable ");
    80002d50:	00006517          	auipc	a0,0x6
    80002d54:	77850513          	addi	a0,a0,1912 # 800094c8 <digits+0x488>
    80002d58:	ffffe097          	auipc	ra,0xffffe
    80002d5c:	830080e7          	jalr	-2000(ra) # 80000588 <printf>
  int res = remove_proc_from_list(p->proc_ind); 
    80002d60:	4ce8                	lw	a0,92(s1)
    80002d62:	fffff097          	auipc	ra,0xfffff
    80002d66:	b62080e7          	jalr	-1182(ra) # 800018c4 <remove_proc_from_list>
  if (res == 1)
    80002d6a:	4785                	li	a5,1
    80002d6c:	08f50f63          	beq	a0,a5,80002e0a <sleep+0xe8>
  {
    mycpu()->runnable_list_head = -1;
    mycpu()->runnable_list_tail = -1;
    printf("4 no head & tail");
  }
  if (res == 2)
    80002d70:	4789                	li	a5,2
    80002d72:	0ef50463          	beq	a0,a5,80002e5a <sleep+0x138>
    if (proc[p->next_proc].next_proc == -1)
      mycpu()->runnable_list_tail = p->next_proc;
    proc[p->next_proc].prev_proc = -1;
    printf("4 no head ");
  }
  if (res == 3){
    80002d76:	478d                	li	a5,3
    80002d78:	16f50a63          	beq	a0,a5,80002eec <sleep+0x1ca>
      mycpu()->runnable_list_head = p->prev_proc;
    proc[p->prev_proc].next_proc = -1;
    printf("4 no tail");
  }

  p->next_proc = -1;
    80002d7c:	57fd                	li	a5,-1
    80002d7e:	d0bc                	sw	a5,96(s1)
  p->prev_proc = -1;
    80002d80:	d0fc                	sw	a5,100(s1)

  // Go to sleep.
  p->chan = chan;
    80002d82:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002d86:	4789                	li	a5,2
    80002d88:	cc9c                	sw	a5,24(s1)
  p->start_sleeping_time = ticks;
    80002d8a:	00007797          	auipc	a5,0x7
    80002d8e:	2ca7a783          	lw	a5,714(a5) # 8000a054 <ticks>
    80002d92:	c8fc                	sw	a5,84(s1)

  if (sleeping_list_tail != -1){
    80002d94:	00007717          	auipc	a4,0x7
    80002d98:	f2472703          	lw	a4,-220(a4) # 80009cb8 <sleeping_list_tail>
    80002d9c:	57fd                	li	a5,-1
    80002d9e:	1ef70663          	beq	a4,a5,80002f8a <sleep+0x268>
    printf("sleeping");
    80002da2:	00006517          	auipc	a0,0x6
    80002da6:	76e50513          	addi	a0,a0,1902 # 80009510 <digits+0x4d0>
    80002daa:	ffffd097          	auipc	ra,0xffffd
    80002dae:	7de080e7          	jalr	2014(ra) # 80000588 <printf>
    add_proc_to_list(sleeping_list_tail, p);
    80002db2:	85a6                	mv	a1,s1
    80002db4:	00007517          	auipc	a0,0x7
    80002db8:	f0452503          	lw	a0,-252(a0) # 80009cb8 <sleeping_list_tail>
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	a8a080e7          	jalr	-1398(ra) # 80001846 <add_proc_to_list>
    if (sleeping_list_head == -1)
    80002dc4:	00007717          	auipc	a4,0x7
    80002dc8:	ef872703          	lw	a4,-264(a4) # 80009cbc <sleeping_list_head>
    80002dcc:	57fd                	li	a5,-1
    80002dce:	1af70863          	beq	a4,a5,80002f7e <sleep+0x25c>
      {
        sleeping_list_head = p->proc_ind;
      }
    sleeping_list_tail = p->proc_ind;
    80002dd2:	4cfc                	lw	a5,92(s1)
    80002dd4:	00007717          	auipc	a4,0x7
    80002dd8:	eef72223          	sw	a5,-284(a4) # 80009cb8 <sleeping_list_tail>
    printf("head in sleeping\n");
    sleeping_list_tail =  p->proc_ind;
    sleeping_list_head = p->proc_ind;
  }

  sched();
    80002ddc:	00000097          	auipc	ra,0x0
    80002de0:	d08080e7          	jalr	-760(ra) # 80002ae4 <sched>

  // Tidy up.
  p->chan = 0;
    80002de4:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002de8:	8526                	mv	a0,s1
    80002dea:	ffffe097          	auipc	ra,0xffffe
    80002dee:	eae080e7          	jalr	-338(ra) # 80000c98 <release>
  acquire(lk);
    80002df2:	854a                	mv	a0,s2
    80002df4:	ffffe097          	auipc	ra,0xffffe
    80002df8:	df0080e7          	jalr	-528(ra) # 80000be4 <acquire>
}
    80002dfc:	70a2                	ld	ra,40(sp)
    80002dfe:	7402                	ld	s0,32(sp)
    80002e00:	64e2                	ld	s1,24(sp)
    80002e02:	6942                	ld	s2,16(sp)
    80002e04:	69a2                	ld	s3,8(sp)
    80002e06:	6145                	addi	sp,sp,48
    80002e08:	8082                	ret
    80002e0a:	8792                	mv	a5,tp
  int id = r_tp();
    80002e0c:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002e10:	0000f717          	auipc	a4,0xf
    80002e14:	4b070713          	addi	a4,a4,1200 # 800122c0 <cpus>
    80002e18:	00369793          	slli	a5,a3,0x3
    80002e1c:	00d78633          	add	a2,a5,a3
    80002e20:	0612                	slli	a2,a2,0x4
    80002e22:	963a                	add	a2,a2,a4
    80002e24:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_head = -1;
    80002e28:	55fd                	li	a1,-1
    80002e2a:	08b62023          	sw	a1,128(a2)
    80002e2e:	8792                	mv	a5,tp
  int id = r_tp();
    80002e30:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002e34:	00369793          	slli	a5,a3,0x3
    80002e38:	00d78633          	add	a2,a5,a3
    80002e3c:	0612                	slli	a2,a2,0x4
    80002e3e:	963a                	add	a2,a2,a4
    80002e40:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_tail = -1;
    80002e44:	08b62223          	sw	a1,132(a2)
    printf("4 no head & tail");
    80002e48:	00006517          	auipc	a0,0x6
    80002e4c:	69050513          	addi	a0,a0,1680 # 800094d8 <digits+0x498>
    80002e50:	ffffd097          	auipc	ra,0xffffd
    80002e54:	738080e7          	jalr	1848(ra) # 80000588 <printf>
  if (res == 3){
    80002e58:	b715                	j	80002d7c <sleep+0x5a>
    80002e5a:	8792                	mv	a5,tp
  int id = r_tp();
    80002e5c:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002e60:	0000f617          	auipc	a2,0xf
    80002e64:	46060613          	addi	a2,a2,1120 # 800122c0 <cpus>
    80002e68:	00371793          	slli	a5,a4,0x3
    80002e6c:	00e786b3          	add	a3,a5,a4
    80002e70:	0692                	slli	a3,a3,0x4
    80002e72:	96b2                	add	a3,a3,a2
    80002e74:	08e6a423          	sw	a4,136(a3)
    mycpu()->runnable_list_head = p->next_proc;
    80002e78:	50b4                	lw	a3,96(s1)
    80002e7a:	97ba                	add	a5,a5,a4
    80002e7c:	0792                	slli	a5,a5,0x4
    80002e7e:	97b2                	add	a5,a5,a2
    80002e80:	08d7a023          	sw	a3,128(a5)
    if (proc[p->next_proc].next_proc == -1)
    80002e84:	19800793          	li	a5,408
    80002e88:	02f686b3          	mul	a3,a3,a5
    80002e8c:	00010797          	auipc	a5,0x10
    80002e90:	8e478793          	addi	a5,a5,-1820 # 80012770 <proc>
    80002e94:	96be                	add	a3,a3,a5
    80002e96:	52b8                	lw	a4,96(a3)
    80002e98:	57fd                	li	a5,-1
    80002e9a:	02f70763          	beq	a4,a5,80002ec8 <sleep+0x1a6>
    proc[p->next_proc].prev_proc = -1;
    80002e9e:	50bc                	lw	a5,96(s1)
    80002ea0:	19800713          	li	a4,408
    80002ea4:	02e78733          	mul	a4,a5,a4
    80002ea8:	00010797          	auipc	a5,0x10
    80002eac:	8c878793          	addi	a5,a5,-1848 # 80012770 <proc>
    80002eb0:	97ba                	add	a5,a5,a4
    80002eb2:	577d                	li	a4,-1
    80002eb4:	d3f8                	sw	a4,100(a5)
    printf("4 no head ");
    80002eb6:	00006517          	auipc	a0,0x6
    80002eba:	63a50513          	addi	a0,a0,1594 # 800094f0 <digits+0x4b0>
    80002ebe:	ffffd097          	auipc	ra,0xffffd
    80002ec2:	6ca080e7          	jalr	1738(ra) # 80000588 <printf>
  if (res == 3){
    80002ec6:	bd5d                	j	80002d7c <sleep+0x5a>
    80002ec8:	8792                	mv	a5,tp
  int id = r_tp();
    80002eca:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002ece:	00371793          	slli	a5,a4,0x3
    80002ed2:	00e786b3          	add	a3,a5,a4
    80002ed6:	0692                	slli	a3,a3,0x4
    80002ed8:	96b2                	add	a3,a3,a2
    80002eda:	08e6a423          	sw	a4,136(a3)
      mycpu()->runnable_list_tail = p->next_proc;
    80002ede:	50b4                	lw	a3,96(s1)
    80002ee0:	97ba                	add	a5,a5,a4
    80002ee2:	0792                	slli	a5,a5,0x4
    80002ee4:	97b2                	add	a5,a5,a2
    80002ee6:	08d7a223          	sw	a3,132(a5)
    80002eea:	bf55                	j	80002e9e <sleep+0x17c>
    80002eec:	8792                	mv	a5,tp
  int id = r_tp();
    80002eee:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002ef2:	0000f617          	auipc	a2,0xf
    80002ef6:	3ce60613          	addi	a2,a2,974 # 800122c0 <cpus>
    80002efa:	00371793          	slli	a5,a4,0x3
    80002efe:	00e786b3          	add	a3,a5,a4
    80002f02:	0692                	slli	a3,a3,0x4
    80002f04:	96b2                	add	a3,a3,a2
    80002f06:	08e6a423          	sw	a4,136(a3)
    mycpu()->runnable_list_tail = p->prev_proc;
    80002f0a:	50f4                	lw	a3,100(s1)
    80002f0c:	97ba                	add	a5,a5,a4
    80002f0e:	0792                	slli	a5,a5,0x4
    80002f10:	97b2                	add	a5,a5,a2
    80002f12:	08d7a223          	sw	a3,132(a5)
    if (proc[p->prev_proc].prev_proc == -1)
    80002f16:	19800793          	li	a5,408
    80002f1a:	02f686b3          	mul	a3,a3,a5
    80002f1e:	00010797          	auipc	a5,0x10
    80002f22:	85278793          	addi	a5,a5,-1966 # 80012770 <proc>
    80002f26:	96be                	add	a3,a3,a5
    80002f28:	52f8                	lw	a4,100(a3)
    80002f2a:	57fd                	li	a5,-1
    80002f2c:	02f70763          	beq	a4,a5,80002f5a <sleep+0x238>
    proc[p->prev_proc].next_proc = -1;
    80002f30:	50fc                	lw	a5,100(s1)
    80002f32:	19800713          	li	a4,408
    80002f36:	02e78733          	mul	a4,a5,a4
    80002f3a:	00010797          	auipc	a5,0x10
    80002f3e:	83678793          	addi	a5,a5,-1994 # 80012770 <proc>
    80002f42:	97ba                	add	a5,a5,a4
    80002f44:	577d                	li	a4,-1
    80002f46:	d3b8                	sw	a4,96(a5)
    printf("4 no tail");
    80002f48:	00006517          	auipc	a0,0x6
    80002f4c:	5b850513          	addi	a0,a0,1464 # 80009500 <digits+0x4c0>
    80002f50:	ffffd097          	auipc	ra,0xffffd
    80002f54:	638080e7          	jalr	1592(ra) # 80000588 <printf>
    80002f58:	b515                	j	80002d7c <sleep+0x5a>
    80002f5a:	8792                	mv	a5,tp
  int id = r_tp();
    80002f5c:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002f60:	00371793          	slli	a5,a4,0x3
    80002f64:	00e786b3          	add	a3,a5,a4
    80002f68:	0692                	slli	a3,a3,0x4
    80002f6a:	96b2                	add	a3,a3,a2
    80002f6c:	08e6a423          	sw	a4,136(a3)
      mycpu()->runnable_list_head = p->prev_proc;
    80002f70:	50f4                	lw	a3,100(s1)
    80002f72:	97ba                	add	a5,a5,a4
    80002f74:	0792                	slli	a5,a5,0x4
    80002f76:	97b2                	add	a5,a5,a2
    80002f78:	08d7a023          	sw	a3,128(a5)
    80002f7c:	bf55                	j	80002f30 <sleep+0x20e>
        sleeping_list_head = p->proc_ind;
    80002f7e:	4cfc                	lw	a5,92(s1)
    80002f80:	00007717          	auipc	a4,0x7
    80002f84:	d2f72e23          	sw	a5,-708(a4) # 80009cbc <sleeping_list_head>
    80002f88:	b5a9                	j	80002dd2 <sleep+0xb0>
    printf("head in sleeping\n");
    80002f8a:	00006517          	auipc	a0,0x6
    80002f8e:	59650513          	addi	a0,a0,1430 # 80009520 <digits+0x4e0>
    80002f92:	ffffd097          	auipc	ra,0xffffd
    80002f96:	5f6080e7          	jalr	1526(ra) # 80000588 <printf>
    sleeping_list_tail =  p->proc_ind;
    80002f9a:	4cfc                	lw	a5,92(s1)
    80002f9c:	00007717          	auipc	a4,0x7
    80002fa0:	d0f72e23          	sw	a5,-740(a4) # 80009cb8 <sleeping_list_tail>
    sleeping_list_head = p->proc_ind;
    80002fa4:	00007717          	auipc	a4,0x7
    80002fa8:	d0f72c23          	sw	a5,-744(a4) # 80009cbc <sleeping_list_head>
    80002fac:	bd05                	j	80002ddc <sleep+0xba>

0000000080002fae <wait>:
{
    80002fae:	711d                	addi	sp,sp,-96
    80002fb0:	ec86                	sd	ra,88(sp)
    80002fb2:	e8a2                	sd	s0,80(sp)
    80002fb4:	e4a6                	sd	s1,72(sp)
    80002fb6:	e0ca                	sd	s2,64(sp)
    80002fb8:	fc4e                	sd	s3,56(sp)
    80002fba:	f852                	sd	s4,48(sp)
    80002fbc:	f456                	sd	s5,40(sp)
    80002fbe:	f05a                	sd	s6,32(sp)
    80002fc0:	ec5e                	sd	s7,24(sp)
    80002fc2:	e862                	sd	s8,16(sp)
    80002fc4:	e466                	sd	s9,8(sp)
    80002fc6:	1080                	addi	s0,sp,96
    80002fc8:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002fca:	fffff097          	auipc	ra,0xfffff
    80002fce:	bfa080e7          	jalr	-1030(ra) # 80001bc4 <myproc>
    80002fd2:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002fd4:	0000f517          	auipc	a0,0xf
    80002fd8:	78450513          	addi	a0,a0,1924 # 80012758 <wait_lock>
    80002fdc:	ffffe097          	auipc	ra,0xffffe
    80002fe0:	c08080e7          	jalr	-1016(ra) # 80000be4 <acquire>
    havekids = 0;
    80002fe4:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002fe6:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002fe8:	00016997          	auipc	s3,0x16
    80002fec:	d8898993          	addi	s3,s3,-632 # 80018d70 <tickslock>
        havekids = 1;
    80002ff0:	4a85                	li	s5,1
      p->sleeping_time += ticks - p->start_sleeping_time;
    80002ff2:	00007c97          	auipc	s9,0x7
    80002ff6:	062c8c93          	addi	s9,s9,98 # 8000a054 <ticks>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002ffa:	0000fc17          	auipc	s8,0xf
    80002ffe:	75ec0c13          	addi	s8,s8,1886 # 80012758 <wait_lock>
    havekids = 0;
    80003002:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80003004:	0000f497          	auipc	s1,0xf
    80003008:	76c48493          	addi	s1,s1,1900 # 80012770 <proc>
    8000300c:	a0bd                	j	8000307a <wait+0xcc>
          pid = np->pid;
    8000300e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80003012:	000b0e63          	beqz	s6,8000302e <wait+0x80>
    80003016:	4691                	li	a3,4
    80003018:	02c48613          	addi	a2,s1,44
    8000301c:	85da                	mv	a1,s6
    8000301e:	08093503          	ld	a0,128(s2)
    80003022:	ffffe097          	auipc	ra,0xffffe
    80003026:	658080e7          	jalr	1624(ra) # 8000167a <copyout>
    8000302a:	02054563          	bltz	a0,80003054 <wait+0xa6>
          freeproc(np);
    8000302e:	8526                	mv	a0,s1
    80003030:	fffff097          	auipc	ra,0xfffff
    80003034:	d4a080e7          	jalr	-694(ra) # 80001d7a <freeproc>
          release(&np->lock);
    80003038:	8526                	mv	a0,s1
    8000303a:	ffffe097          	auipc	ra,0xffffe
    8000303e:	c5e080e7          	jalr	-930(ra) # 80000c98 <release>
          release(&wait_lock);
    80003042:	0000f517          	auipc	a0,0xf
    80003046:	71650513          	addi	a0,a0,1814 # 80012758 <wait_lock>
    8000304a:	ffffe097          	auipc	ra,0xffffe
    8000304e:	c4e080e7          	jalr	-946(ra) # 80000c98 <release>
          return pid;
    80003052:	a09d                	j	800030b8 <wait+0x10a>
            release(&np->lock);
    80003054:	8526                	mv	a0,s1
    80003056:	ffffe097          	auipc	ra,0xffffe
    8000305a:	c42080e7          	jalr	-958(ra) # 80000c98 <release>
            release(&wait_lock);
    8000305e:	0000f517          	auipc	a0,0xf
    80003062:	6fa50513          	addi	a0,a0,1786 # 80012758 <wait_lock>
    80003066:	ffffe097          	auipc	ra,0xffffe
    8000306a:	c32080e7          	jalr	-974(ra) # 80000c98 <release>
            return -1;
    8000306e:	59fd                	li	s3,-1
    80003070:	a0a1                	j	800030b8 <wait+0x10a>
    for(np = proc; np < &proc[NPROC]; np++){
    80003072:	19848493          	addi	s1,s1,408
    80003076:	03348463          	beq	s1,s3,8000309e <wait+0xf0>
      if(np->parent == p){
    8000307a:	74bc                	ld	a5,104(s1)
    8000307c:	ff279be3          	bne	a5,s2,80003072 <wait+0xc4>
        acquire(&np->lock);
    80003080:	8526                	mv	a0,s1
    80003082:	ffffe097          	auipc	ra,0xffffe
    80003086:	b62080e7          	jalr	-1182(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000308a:	4c9c                	lw	a5,24(s1)
    8000308c:	f94781e3          	beq	a5,s4,8000300e <wait+0x60>
        release(&np->lock);
    80003090:	8526                	mv	a0,s1
    80003092:	ffffe097          	auipc	ra,0xffffe
    80003096:	c06080e7          	jalr	-1018(ra) # 80000c98 <release>
        havekids = 1;
    8000309a:	8756                	mv	a4,s5
    8000309c:	bfd9                	j	80003072 <wait+0xc4>
    if(!havekids || p->killed){
    8000309e:	c701                	beqz	a4,800030a6 <wait+0xf8>
    800030a0:	02892783          	lw	a5,40(s2)
    800030a4:	cb85                	beqz	a5,800030d4 <wait+0x126>
      release(&wait_lock);
    800030a6:	0000f517          	auipc	a0,0xf
    800030aa:	6b250513          	addi	a0,a0,1714 # 80012758 <wait_lock>
    800030ae:	ffffe097          	auipc	ra,0xffffe
    800030b2:	bea080e7          	jalr	-1046(ra) # 80000c98 <release>
      return -1;
    800030b6:	59fd                	li	s3,-1
}
    800030b8:	854e                	mv	a0,s3
    800030ba:	60e6                	ld	ra,88(sp)
    800030bc:	6446                	ld	s0,80(sp)
    800030be:	64a6                	ld	s1,72(sp)
    800030c0:	6906                	ld	s2,64(sp)
    800030c2:	79e2                	ld	s3,56(sp)
    800030c4:	7a42                	ld	s4,48(sp)
    800030c6:	7aa2                	ld	s5,40(sp)
    800030c8:	7b02                	ld	s6,32(sp)
    800030ca:	6be2                	ld	s7,24(sp)
    800030cc:	6c42                	ld	s8,16(sp)
    800030ce:	6ca2                	ld	s9,8(sp)
    800030d0:	6125                	addi	sp,sp,96
    800030d2:	8082                	ret
    if (p->state == RUNNING)
    800030d4:	01892783          	lw	a5,24(s2)
    800030d8:	4711                	li	a4,4
    800030da:	02e78063          	beq	a5,a4,800030fa <wait+0x14c>
     if (p->state == RUNNABLE)
    800030de:	470d                	li	a4,3
    800030e0:	02e79e63          	bne	a5,a4,8000311c <wait+0x16e>
      p->runnable_time += ticks - p->last_runnable_time;
    800030e4:	04892783          	lw	a5,72(s2)
    800030e8:	000ca703          	lw	a4,0(s9)
    800030ec:	9fb9                	addw	a5,a5,a4
    800030ee:	03c92703          	lw	a4,60(s2)
    800030f2:	9f99                	subw	a5,a5,a4
    800030f4:	04f92423          	sw	a5,72(s2)
    if (p->state == SLEEPING)
    800030f8:	a819                	j	8000310e <wait+0x160>
      p->running_time += ticks - p->start_running_time;
    800030fa:	04492783          	lw	a5,68(s2)
    800030fe:	000ca703          	lw	a4,0(s9)
    80003102:	9fb9                	addw	a5,a5,a4
    80003104:	05092703          	lw	a4,80(s2)
    80003108:	9f99                	subw	a5,a5,a4
    8000310a:	04f92223          	sw	a5,68(s2)
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000310e:	85e2                	mv	a1,s8
    80003110:	854a                	mv	a0,s2
    80003112:	00000097          	auipc	ra,0x0
    80003116:	c10080e7          	jalr	-1008(ra) # 80002d22 <sleep>
    havekids = 0;
    8000311a:	b5e5                	j	80003002 <wait+0x54>
    if (p->state == SLEEPING)
    8000311c:	4709                	li	a4,2
    8000311e:	fee798e3          	bne	a5,a4,8000310e <wait+0x160>
      p->sleeping_time += ticks - p->start_sleeping_time;
    80003122:	04c92783          	lw	a5,76(s2)
    80003126:	000ca703          	lw	a4,0(s9)
    8000312a:	9fb9                	addw	a5,a5,a4
    8000312c:	05492703          	lw	a4,84(s2)
    80003130:	9f99                	subw	a5,a5,a4
    80003132:	04f92623          	sw	a5,76(s2)
    80003136:	bfe1                	j	8000310e <wait+0x160>

0000000080003138 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80003138:	711d                	addi	sp,sp,-96
    8000313a:	ec86                	sd	ra,88(sp)
    8000313c:	e8a2                	sd	s0,80(sp)
    8000313e:	e4a6                	sd	s1,72(sp)
    80003140:	e0ca                	sd	s2,64(sp)
    80003142:	fc4e                	sd	s3,56(sp)
    80003144:	f852                	sd	s4,48(sp)
    80003146:	f456                	sd	s5,40(sp)
    80003148:	f05a                	sd	s6,32(sp)
    8000314a:	ec5e                	sd	s7,24(sp)
    8000314c:	e862                	sd	s8,16(sp)
    8000314e:	e466                	sd	s9,8(sp)
    80003150:	1080                	addi	s0,sp,96
    80003152:	89aa                	mv	s3,a0
  // TODO: go threw all SLEEPING and pick one to wake up- remove from SLEEPING and add to RUNNABLE.
  struct proc *p;
  
  while (sleeping_list_head != -1)
    80003154:	00007b97          	auipc	s7,0x7
    80003158:	b68b8b93          	addi	s7,s7,-1176 # 80009cbc <sleeping_list_head>
    8000315c:	597d                	li	s2,-1
  {
    p = &proc[sleeping_list_head];
    if (p->chan == chan)
    8000315e:	0000fa97          	auipc	s5,0xf
    80003162:	612a8a93          	addi	s5,s5,1554 # 80012770 <proc>
    80003166:	19800a13          	li	s4,408
            sleeping_list_tail = p->next_proc;
          proc[p->next_proc].prev_proc = -1;
          printf("5 no head ");
        }
        if (res == 3){
          sleeping_list_tail = p->prev_proc;
    8000316a:	00007c17          	auipc	s8,0x7
    8000316e:	b4ec0c13          	addi	s8,s8,-1202 # 80009cb8 <sleeping_list_tail>
        p->prev_proc = -1;
        p->next_proc = -1;
        release(&p->lock);

        
        if (cpus[p->cpu_num].runnable_list_head == -1)
    80003172:	0000fb17          	auipc	s6,0xf
    80003176:	14eb0b13          	addi	s6,s6,334 # 800122c0 <cpus>
  while (sleeping_list_head != -1)
    8000317a:	000ba483          	lw	s1,0(s7)
    if (p->chan == chan)
    8000317e:	03448733          	mul	a4,s1,s4
    80003182:	9756                	add	a4,a4,s5
  while (sleeping_list_head != -1)
    80003184:	19248863          	beq	s1,s2,80003314 <wakeup+0x1dc>
    if (p->chan == chan)
    80003188:	731c                	ld	a5,32(a4)
    8000318a:	ff379de3          	bne	a5,s3,80003184 <wakeup+0x4c>
      printf("wakeup\n"); 
    8000318e:	00006517          	auipc	a0,0x6
    80003192:	3aa50513          	addi	a0,a0,938 # 80009538 <digits+0x4f8>
    80003196:	ffffd097          	auipc	ra,0xffffd
    8000319a:	3f2080e7          	jalr	1010(ra) # 80000588 <printf>
      printf("sleeping");
    8000319e:	00006517          	auipc	a0,0x6
    800031a2:	37250513          	addi	a0,a0,882 # 80009510 <digits+0x4d0>
    800031a6:	ffffd097          	auipc	ra,0xffffd
    800031aa:	3e2080e7          	jalr	994(ra) # 80000588 <printf>
      int res = remove_proc_from_list(p->proc_ind); 
    800031ae:	034487b3          	mul	a5,s1,s4
    800031b2:	97d6                	add	a5,a5,s5
    800031b4:	4fe8                	lw	a0,92(a5)
    800031b6:	ffffe097          	auipc	ra,0xffffe
    800031ba:	70e080e7          	jalr	1806(ra) # 800018c4 <remove_proc_from_list>
        if (res == 1)
    800031be:	4785                	li	a5,1
    800031c0:	04f50263          	beq	a0,a5,80003204 <wakeup+0xcc>
        if (res == 2)
    800031c4:	4789                	li	a5,2
    800031c6:	04f50d63          	beq	a0,a5,80003220 <wakeup+0xe8>
        if (res == 3){
    800031ca:	478d                	li	a5,3
    800031cc:	08f51363          	bne	a0,a5,80003252 <wakeup+0x11a>
          sleeping_list_tail = p->prev_proc;
    800031d0:	034487b3          	mul	a5,s1,s4
    800031d4:	97d6                	add	a5,a5,s5
    800031d6:	53fc                	lw	a5,100(a5)
    800031d8:	00fc2023          	sw	a5,0(s8)
          if (proc[p->prev_proc].prev_proc == -1)
    800031dc:	03478733          	mul	a4,a5,s4
    800031e0:	9756                	add	a4,a4,s5
    800031e2:	5378                	lw	a4,100(a4)
    800031e4:	0f270c63          	beq	a4,s2,800032dc <wakeup+0x1a4>
          proc[p->prev_proc].next_proc = -1;
    800031e8:	034787b3          	mul	a5,a5,s4
    800031ec:	97d6                	add	a5,a5,s5
    800031ee:	577d                	li	a4,-1
    800031f0:	d3b8                	sw	a4,96(a5)
          printf("5 no tail");
    800031f2:	00006517          	auipc	a0,0x6
    800031f6:	37650513          	addi	a0,a0,886 # 80009568 <digits+0x528>
    800031fa:	ffffd097          	auipc	ra,0xffffd
    800031fe:	38e080e7          	jalr	910(ra) # 80000588 <printf>
    80003202:	a881                	j	80003252 <wakeup+0x11a>
          sleeping_list_head = -1;
    80003204:	57fd                	li	a5,-1
    80003206:	00fba023          	sw	a5,0(s7)
          sleeping_list_tail = -1;
    8000320a:	00fc2023          	sw	a5,0(s8)
          printf("5 no head & tail");
    8000320e:	00006517          	auipc	a0,0x6
    80003212:	33250513          	addi	a0,a0,818 # 80009540 <digits+0x500>
    80003216:	ffffd097          	auipc	ra,0xffffd
    8000321a:	372080e7          	jalr	882(ra) # 80000588 <printf>
        if (res == 3){
    8000321e:	a815                	j	80003252 <wakeup+0x11a>
          sleeping_list_head = p->next_proc;
    80003220:	034487b3          	mul	a5,s1,s4
    80003224:	97d6                	add	a5,a5,s5
    80003226:	53bc                	lw	a5,96(a5)
    80003228:	00fba023          	sw	a5,0(s7)
          if (proc[p->next_proc].next_proc == -1)
    8000322c:	03478733          	mul	a4,a5,s4
    80003230:	9756                	add	a4,a4,s5
    80003232:	5338                	lw	a4,96(a4)
    80003234:	0b270163          	beq	a4,s2,800032d6 <wakeup+0x19e>
          proc[p->next_proc].prev_proc = -1;
    80003238:	034787b3          	mul	a5,a5,s4
    8000323c:	97d6                	add	a5,a5,s5
    8000323e:	577d                	li	a4,-1
    80003240:	d3f8                	sw	a4,100(a5)
          printf("5 no head ");
    80003242:	00006517          	auipc	a0,0x6
    80003246:	31650513          	addi	a0,a0,790 # 80009558 <digits+0x518>
    8000324a:	ffffd097          	auipc	ra,0xffffd
    8000324e:	33e080e7          	jalr	830(ra) # 80000588 <printf>
    p = &proc[sleeping_list_head];
    80003252:	03448cb3          	mul	s9,s1,s4
    80003256:	9cd6                	add	s9,s9,s5
        acquire(&p->lock);
    80003258:	8566                	mv	a0,s9
    8000325a:	ffffe097          	auipc	ra,0xffffe
    8000325e:	98a080e7          	jalr	-1654(ra) # 80000be4 <acquire>
        p->state = RUNNABLE;
    80003262:	478d                	li	a5,3
    80003264:	00fcac23          	sw	a5,24(s9)
        p->prev_proc = -1;
    80003268:	57fd                	li	a5,-1
    8000326a:	06fca223          	sw	a5,100(s9)
        p->next_proc = -1;
    8000326e:	06fca023          	sw	a5,96(s9)
        release(&p->lock);
    80003272:	8566                	mv	a0,s9
    80003274:	ffffe097          	auipc	ra,0xffffe
    80003278:	a24080e7          	jalr	-1500(ra) # 80000c98 <release>
        if (cpus[p->cpu_num].runnable_list_head == -1)
    8000327c:	058ca703          	lw	a4,88(s9)
    80003280:	00371793          	slli	a5,a4,0x3
    80003284:	97ba                	add	a5,a5,a4
    80003286:	0792                	slli	a5,a5,0x4
    80003288:	97da                	add	a5,a5,s6
    8000328a:	0807a783          	lw	a5,128(a5)
    8000328e:	05278a63          	beq	a5,s2,800032e2 <wakeup+0x1aa>
          cpus[p->cpu_num].runnable_list_head = p->proc_ind;
          cpus[p->cpu_num].runnable_list_tail = p->proc_ind;
        }
        else
        {
          printf("runnable4");
    80003292:	00006517          	auipc	a0,0x6
    80003296:	30e50513          	addi	a0,a0,782 # 800095a0 <digits+0x560>
    8000329a:	ffffd097          	auipc	ra,0xffffd
    8000329e:	2ee080e7          	jalr	750(ra) # 80000588 <printf>
          add_proc_to_list(cpus[p->cpu_num].runnable_list_tail, p);
    800032a2:	034484b3          	mul	s1,s1,s4
    800032a6:	94d6                	add	s1,s1,s5
    800032a8:	4cb8                	lw	a4,88(s1)
    800032aa:	00371793          	slli	a5,a4,0x3
    800032ae:	97ba                	add	a5,a5,a4
    800032b0:	0792                	slli	a5,a5,0x4
    800032b2:	97da                	add	a5,a5,s6
    800032b4:	85e6                	mv	a1,s9
    800032b6:	0847a503          	lw	a0,132(a5)
    800032ba:	ffffe097          	auipc	ra,0xffffe
    800032be:	58c080e7          	jalr	1420(ra) # 80001846 <add_proc_to_list>
          cpus[p->cpu_num].runnable_list_tail = p->proc_ind;
    800032c2:	4cb8                	lw	a4,88(s1)
    800032c4:	00371793          	slli	a5,a4,0x3
    800032c8:	97ba                	add	a5,a5,a4
    800032ca:	0792                	slli	a5,a5,0x4
    800032cc:	97da                	add	a5,a5,s6
    800032ce:	4cf8                	lw	a4,92(s1)
    800032d0:	08e7a223          	sw	a4,132(a5)
    800032d4:	b55d                	j	8000317a <wakeup+0x42>
            sleeping_list_tail = p->next_proc;
    800032d6:	00fc2023          	sw	a5,0(s8)
    800032da:	bfb9                	j	80003238 <wakeup+0x100>
            sleeping_list_head = p->prev_proc;
    800032dc:	00fba023          	sw	a5,0(s7)
    800032e0:	b721                	j	800031e8 <wakeup+0xb0>
          printf("init runnable %d                  4\n", p->proc_ind);
    800032e2:	05cca583          	lw	a1,92(s9)
    800032e6:	00006517          	auipc	a0,0x6
    800032ea:	29250513          	addi	a0,a0,658 # 80009578 <digits+0x538>
    800032ee:	ffffd097          	auipc	ra,0xffffd
    800032f2:	29a080e7          	jalr	666(ra) # 80000588 <printf>
          cpus[p->cpu_num].runnable_list_head = p->proc_ind;
    800032f6:	058ca683          	lw	a3,88(s9)
    800032fa:	05cca603          	lw	a2,92(s9)
    800032fe:	00369793          	slli	a5,a3,0x3
    80003302:	00d78733          	add	a4,a5,a3
    80003306:	0712                	slli	a4,a4,0x4
    80003308:	975a                	add	a4,a4,s6
    8000330a:	08c72023          	sw	a2,128(a4)
          cpus[p->cpu_num].runnable_list_tail = p->proc_ind;
    8000330e:	08c72223          	sw	a2,132(a4)
    80003312:	b5a5                	j	8000317a <wakeup+0x42>
  //     }
  //     release(&p->lock);
  //   }
  // }
  }
}
    80003314:	60e6                	ld	ra,88(sp)
    80003316:	6446                	ld	s0,80(sp)
    80003318:	64a6                	ld	s1,72(sp)
    8000331a:	6906                	ld	s2,64(sp)
    8000331c:	79e2                	ld	s3,56(sp)
    8000331e:	7a42                	ld	s4,48(sp)
    80003320:	7aa2                	ld	s5,40(sp)
    80003322:	7b02                	ld	s6,32(sp)
    80003324:	6be2                	ld	s7,24(sp)
    80003326:	6c42                	ld	s8,16(sp)
    80003328:	6ca2                	ld	s9,8(sp)
    8000332a:	6125                	addi	sp,sp,96
    8000332c:	8082                	ret

000000008000332e <reparent>:
{
    8000332e:	7179                	addi	sp,sp,-48
    80003330:	f406                	sd	ra,40(sp)
    80003332:	f022                	sd	s0,32(sp)
    80003334:	ec26                	sd	s1,24(sp)
    80003336:	e84a                	sd	s2,16(sp)
    80003338:	e44e                	sd	s3,8(sp)
    8000333a:	e052                	sd	s4,0(sp)
    8000333c:	1800                	addi	s0,sp,48
    8000333e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80003340:	0000f497          	auipc	s1,0xf
    80003344:	43048493          	addi	s1,s1,1072 # 80012770 <proc>
      pp->parent = initproc;
    80003348:	00007a17          	auipc	s4,0x7
    8000334c:	ce0a0a13          	addi	s4,s4,-800 # 8000a028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80003350:	00016997          	auipc	s3,0x16
    80003354:	a2098993          	addi	s3,s3,-1504 # 80018d70 <tickslock>
    80003358:	a029                	j	80003362 <reparent+0x34>
    8000335a:	19848493          	addi	s1,s1,408
    8000335e:	01348d63          	beq	s1,s3,80003378 <reparent+0x4a>
    if(pp->parent == p){
    80003362:	74bc                	ld	a5,104(s1)
    80003364:	ff279be3          	bne	a5,s2,8000335a <reparent+0x2c>
      pp->parent = initproc;
    80003368:	000a3503          	ld	a0,0(s4)
    8000336c:	f4a8                	sd	a0,104(s1)
      wakeup(initproc);
    8000336e:	00000097          	auipc	ra,0x0
    80003372:	dca080e7          	jalr	-566(ra) # 80003138 <wakeup>
    80003376:	b7d5                	j	8000335a <reparent+0x2c>
}
    80003378:	70a2                	ld	ra,40(sp)
    8000337a:	7402                	ld	s0,32(sp)
    8000337c:	64e2                	ld	s1,24(sp)
    8000337e:	6942                	ld	s2,16(sp)
    80003380:	69a2                	ld	s3,8(sp)
    80003382:	6a02                	ld	s4,0(sp)
    80003384:	6145                	addi	sp,sp,48
    80003386:	8082                	ret

0000000080003388 <exit>:
{
    80003388:	7179                	addi	sp,sp,-48
    8000338a:	f406                	sd	ra,40(sp)
    8000338c:	f022                	sd	s0,32(sp)
    8000338e:	ec26                	sd	s1,24(sp)
    80003390:	e84a                	sd	s2,16(sp)
    80003392:	e44e                	sd	s3,8(sp)
    80003394:	e052                	sd	s4,0(sp)
    80003396:	1800                	addi	s0,sp,48
    80003398:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000339a:	fffff097          	auipc	ra,0xfffff
    8000339e:	82a080e7          	jalr	-2006(ra) # 80001bc4 <myproc>
    800033a2:	892a                	mv	s2,a0
  if(p == initproc)
    800033a4:	00007797          	auipc	a5,0x7
    800033a8:	c847b783          	ld	a5,-892(a5) # 8000a028 <initproc>
    800033ac:	10050493          	addi	s1,a0,256
    800033b0:	18050993          	addi	s3,a0,384
    800033b4:	02a79363          	bne	a5,a0,800033da <exit+0x52>
    panic("init exiting");
    800033b8:	00006517          	auipc	a0,0x6
    800033bc:	1f850513          	addi	a0,a0,504 # 800095b0 <digits+0x570>
    800033c0:	ffffd097          	auipc	ra,0xffffd
    800033c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>
      fileclose(f);
    800033c8:	00003097          	auipc	ra,0x3
    800033cc:	8b0080e7          	jalr	-1872(ra) # 80005c78 <fileclose>
      p->ofile[fd] = 0;
    800033d0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800033d4:	04a1                	addi	s1,s1,8
    800033d6:	00998563          	beq	s3,s1,800033e0 <exit+0x58>
    if(p->ofile[fd]){
    800033da:	6088                	ld	a0,0(s1)
    800033dc:	f575                	bnez	a0,800033c8 <exit+0x40>
    800033de:	bfdd                	j	800033d4 <exit+0x4c>
  if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) 
    800033e0:	18890493          	addi	s1,s2,392
    800033e4:	00006597          	auipc	a1,0x6
    800033e8:	1dc58593          	addi	a1,a1,476 # 800095c0 <digits+0x580>
    800033ec:	8526                	mv	a0,s1
    800033ee:	fffff097          	auipc	ra,0xfffff
    800033f2:	d86080e7          	jalr	-634(ra) # 80002174 <str_compare>
    800033f6:	e97d                	bnez	a0,800034ec <exit+0x164>
  begin_op();
    800033f8:	00002097          	auipc	ra,0x2
    800033fc:	3b4080e7          	jalr	948(ra) # 800057ac <begin_op>
  iput(p->cwd);
    80003400:	18093503          	ld	a0,384(s2)
    80003404:	00002097          	auipc	ra,0x2
    80003408:	b90080e7          	jalr	-1136(ra) # 80004f94 <iput>
  end_op();
    8000340c:	00002097          	auipc	ra,0x2
    80003410:	420080e7          	jalr	1056(ra) # 8000582c <end_op>
  p->cwd = 0;
    80003414:	18093023          	sd	zero,384(s2)
  acquire(&wait_lock);
    80003418:	0000f517          	auipc	a0,0xf
    8000341c:	34050513          	addi	a0,a0,832 # 80012758 <wait_lock>
    80003420:	ffffd097          	auipc	ra,0xffffd
    80003424:	7c4080e7          	jalr	1988(ra) # 80000be4 <acquire>
  reparent(p);
    80003428:	854a                	mv	a0,s2
    8000342a:	00000097          	auipc	ra,0x0
    8000342e:	f04080e7          	jalr	-252(ra) # 8000332e <reparent>
  wakeup(p->parent);
    80003432:	06893503          	ld	a0,104(s2)
    80003436:	00000097          	auipc	ra,0x0
    8000343a:	d02080e7          	jalr	-766(ra) # 80003138 <wakeup>
  acquire(&p->lock);
    8000343e:	854a                	mv	a0,s2
    80003440:	ffffd097          	auipc	ra,0xffffd
    80003444:	7a4080e7          	jalr	1956(ra) # 80000be4 <acquire>
  p->xstate = status;
    80003448:	03492623          	sw	s4,44(s2)
  p->state = ZOMBIE;
    8000344c:	4795                	li	a5,5
    8000344e:	00f92c23          	sw	a5,24(s2)
  p->running_time += ticks - p->start_running_time;
    80003452:	04492783          	lw	a5,68(s2)
    80003456:	00007717          	auipc	a4,0x7
    8000345a:	bfe72703          	lw	a4,-1026(a4) # 8000a054 <ticks>
    8000345e:	9fb9                	addw	a5,a5,a4
    80003460:	05092703          	lw	a4,80(s2)
    80003464:	9f99                	subw	a5,a5,a4
    80003466:	04f92223          	sw	a5,68(s2)
  printf("runnable ");
    8000346a:	00006517          	auipc	a0,0x6
    8000346e:	05e50513          	addi	a0,a0,94 # 800094c8 <digits+0x488>
    80003472:	ffffd097          	auipc	ra,0xffffd
    80003476:	116080e7          	jalr	278(ra) # 80000588 <printf>
  int res = remove_proc_from_list(p->proc_ind); 
    8000347a:	05c92503          	lw	a0,92(s2)
    8000347e:	ffffe097          	auipc	ra,0xffffe
    80003482:	446080e7          	jalr	1094(ra) # 800018c4 <remove_proc_from_list>
  if (res == 1)
    80003486:	4785                	li	a5,1
    80003488:	10f50863          	beq	a0,a5,80003598 <exit+0x210>
  if (res == 2)
    8000348c:	4789                	li	a5,2
    8000348e:	14f50763          	beq	a0,a5,800035dc <exit+0x254>
  if (res == 3){
    80003492:	478d                	li	a5,3
    80003494:	1cf50a63          	beq	a0,a5,80003668 <exit+0x2e0>
  p->next_proc = -1;
    80003498:	57fd                	li	a5,-1
    8000349a:	06f92023          	sw	a5,96(s2)
  p->prev_proc = -1;
    8000349e:	06f92223          	sw	a5,100(s2)
  if (zombie_list_tail != -1){
    800034a2:	00007717          	auipc	a4,0x7
    800034a6:	80672703          	lw	a4,-2042(a4) # 80009ca8 <zombie_list_tail>
    800034aa:	57fd                	li	a5,-1
    800034ac:	24f71463          	bne	a4,a5,800036f4 <exit+0x36c>
    zombie_list_tail = zombie_list_head = p->proc_ind;
    800034b0:	05c92783          	lw	a5,92(s2)
    800034b4:	00006717          	auipc	a4,0x6
    800034b8:	7ef72c23          	sw	a5,2040(a4) # 80009cac <zombie_list_head>
    800034bc:	00006717          	auipc	a4,0x6
    800034c0:	7ef72623          	sw	a5,2028(a4) # 80009ca8 <zombie_list_tail>
  release(&wait_lock);
    800034c4:	0000f517          	auipc	a0,0xf
    800034c8:	29450513          	addi	a0,a0,660 # 80012758 <wait_lock>
    800034cc:	ffffd097          	auipc	ra,0xffffd
    800034d0:	7cc080e7          	jalr	1996(ra) # 80000c98 <release>
  sched();
    800034d4:	fffff097          	auipc	ra,0xfffff
    800034d8:	610080e7          	jalr	1552(ra) # 80002ae4 <sched>
  panic("zombie exit");
    800034dc:	00006517          	auipc	a0,0x6
    800034e0:	12c50513          	addi	a0,a0,300 # 80009608 <digits+0x5c8>
    800034e4:	ffffd097          	auipc	ra,0xffffd
    800034e8:	05a080e7          	jalr	90(ra) # 8000053e <panic>
  if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) 
    800034ec:	00006597          	auipc	a1,0x6
    800034f0:	0dc58593          	addi	a1,a1,220 # 800095c8 <digits+0x588>
    800034f4:	8526                	mv	a0,s1
    800034f6:	fffff097          	auipc	ra,0xfffff
    800034fa:	c7e080e7          	jalr	-898(ra) # 80002174 <str_compare>
    800034fe:	ee050de3          	beqz	a0,800033f8 <exit+0x70>
    sleeping_processes_mean = ((sleeping_processes_mean * p_counter)+ p->sleeping_time)/(p_counter+1);
    80003502:	00007597          	auipc	a1,0x7
    80003506:	b3a58593          	addi	a1,a1,-1222 # 8000a03c <p_counter>
    8000350a:	4194                	lw	a3,0(a1)
    8000350c:	0016871b          	addiw	a4,a3,1
    80003510:	00007617          	auipc	a2,0x7
    80003514:	b3860613          	addi	a2,a2,-1224 # 8000a048 <sleeping_processes_mean>
    80003518:	421c                	lw	a5,0(a2)
    8000351a:	02d787bb          	mulw	a5,a5,a3
    8000351e:	04c92503          	lw	a0,76(s2)
    80003522:	9fa9                	addw	a5,a5,a0
    80003524:	02e7d7bb          	divuw	a5,a5,a4
    80003528:	c21c                	sw	a5,0(a2)
    running_processes_mean = ((running_processes_mean * p_counter)+ p->running_time)/(p_counter+1);
    8000352a:	04492603          	lw	a2,68(s2)
    8000352e:	00007517          	auipc	a0,0x7
    80003532:	b1650513          	addi	a0,a0,-1258 # 8000a044 <running_processes_mean>
    80003536:	411c                	lw	a5,0(a0)
    80003538:	02d787bb          	mulw	a5,a5,a3
    8000353c:	9fb1                	addw	a5,a5,a2
    8000353e:	02e7d7bb          	divuw	a5,a5,a4
    80003542:	c11c                	sw	a5,0(a0)
    runnable_processes_mean = ((runnable_processes_mean * p_counter)+ p->runnable_time)/(p_counter+1);
    80003544:	00007517          	auipc	a0,0x7
    80003548:	afc50513          	addi	a0,a0,-1284 # 8000a040 <runnable_processes_mean>
    8000354c:	411c                	lw	a5,0(a0)
    8000354e:	02d787bb          	mulw	a5,a5,a3
    80003552:	04892683          	lw	a3,72(s2)
    80003556:	9fb5                	addw	a5,a5,a3
    80003558:	02e7d7bb          	divuw	a5,a5,a4
    8000355c:	c11c                	sw	a5,0(a0)
    p_counter += 1;
    8000355e:	c198                	sw	a4,0(a1)
    program_time += p->running_time;
    80003560:	00007697          	auipc	a3,0x7
    80003564:	ad868693          	addi	a3,a3,-1320 # 8000a038 <program_time>
    80003568:	429c                	lw	a5,0(a3)
    8000356a:	00c7873b          	addw	a4,a5,a2
    8000356e:	c298                	sw	a4,0(a3)
    cpu_utilization = (program_time* 100) / (ticks - start_time) ;
    80003570:	06400793          	li	a5,100
    80003574:	02e787bb          	mulw	a5,a5,a4
    80003578:	00007717          	auipc	a4,0x7
    8000357c:	adc72703          	lw	a4,-1316(a4) # 8000a054 <ticks>
    80003580:	00007697          	auipc	a3,0x7
    80003584:	ab46a683          	lw	a3,-1356(a3) # 8000a034 <start_time>
    80003588:	9f15                	subw	a4,a4,a3
    8000358a:	02e7d7bb          	divuw	a5,a5,a4
    8000358e:	00007717          	auipc	a4,0x7
    80003592:	aaf72123          	sw	a5,-1374(a4) # 8000a030 <cpu_utilization>
    80003596:	b58d                	j	800033f8 <exit+0x70>
    80003598:	8612                	mv	a2,tp
  int id = r_tp();
    8000359a:	2601                	sext.w	a2,a2
  c->cpu_id = id;
    8000359c:	0000f797          	auipc	a5,0xf
    800035a0:	d2478793          	addi	a5,a5,-732 # 800122c0 <cpus>
    800035a4:	09000693          	li	a3,144
    800035a8:	02d60733          	mul	a4,a2,a3
    800035ac:	973e                	add	a4,a4,a5
    800035ae:	08c72423          	sw	a2,136(a4)
    mycpu()->runnable_list_head = -1;
    800035b2:	567d                	li	a2,-1
    800035b4:	08c72023          	sw	a2,128(a4)
    800035b8:	8712                	mv	a4,tp
  int id = r_tp();
    800035ba:	2701                	sext.w	a4,a4
  c->cpu_id = id;
    800035bc:	02d706b3          	mul	a3,a4,a3
    800035c0:	97b6                	add	a5,a5,a3
    800035c2:	08e7a423          	sw	a4,136(a5)
    mycpu()->runnable_list_tail = -1;
    800035c6:	08c7a223          	sw	a2,132(a5)
    printf("3 no head & tail");
    800035ca:	00006517          	auipc	a0,0x6
    800035ce:	00650513          	addi	a0,a0,6 # 800095d0 <digits+0x590>
    800035d2:	ffffd097          	auipc	ra,0xffffd
    800035d6:	fb6080e7          	jalr	-74(ra) # 80000588 <printf>
  if (res == 3){
    800035da:	bd7d                	j	80003498 <exit+0x110>
    800035dc:	8792                	mv	a5,tp
  int id = r_tp();
    800035de:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    800035e0:	09000713          	li	a4,144
    800035e4:	02e786b3          	mul	a3,a5,a4
    800035e8:	0000f717          	auipc	a4,0xf
    800035ec:	cd870713          	addi	a4,a4,-808 # 800122c0 <cpus>
    800035f0:	9736                	add	a4,a4,a3
    800035f2:	08f72423          	sw	a5,136(a4)
    mycpu()->runnable_list_head = p->next_proc;
    800035f6:	06092783          	lw	a5,96(s2)
    800035fa:	08f72023          	sw	a5,128(a4)
    if (proc[p->next_proc].next_proc == -1)
    800035fe:	19800713          	li	a4,408
    80003602:	02e787b3          	mul	a5,a5,a4
    80003606:	0000f717          	auipc	a4,0xf
    8000360a:	16a70713          	addi	a4,a4,362 # 80012770 <proc>
    8000360e:	97ba                	add	a5,a5,a4
    80003610:	53b8                	lw	a4,96(a5)
    80003612:	57fd                	li	a5,-1
    80003614:	02f70863          	beq	a4,a5,80003644 <exit+0x2bc>
    proc[p->next_proc].prev_proc = -1;
    80003618:	06092783          	lw	a5,96(s2)
    8000361c:	19800713          	li	a4,408
    80003620:	02e78733          	mul	a4,a5,a4
    80003624:	0000f797          	auipc	a5,0xf
    80003628:	14c78793          	addi	a5,a5,332 # 80012770 <proc>
    8000362c:	97ba                	add	a5,a5,a4
    8000362e:	577d                	li	a4,-1
    80003630:	d3f8                	sw	a4,100(a5)
    printf("3 no head");
    80003632:	00006517          	auipc	a0,0x6
    80003636:	fb650513          	addi	a0,a0,-74 # 800095e8 <digits+0x5a8>
    8000363a:	ffffd097          	auipc	ra,0xffffd
    8000363e:	f4e080e7          	jalr	-178(ra) # 80000588 <printf>
  if (res == 3){
    80003642:	bd99                	j	80003498 <exit+0x110>
    80003644:	8712                	mv	a4,tp
  int id = r_tp();
    80003646:	2701                	sext.w	a4,a4
  c->cpu_id = id;
    80003648:	09000793          	li	a5,144
    8000364c:	02f706b3          	mul	a3,a4,a5
    80003650:	0000f797          	auipc	a5,0xf
    80003654:	c7078793          	addi	a5,a5,-912 # 800122c0 <cpus>
    80003658:	97b6                	add	a5,a5,a3
    8000365a:	08e7a423          	sw	a4,136(a5)
      mycpu()->runnable_list_tail = p->next_proc;
    8000365e:	06092703          	lw	a4,96(s2)
    80003662:	08e7a223          	sw	a4,132(a5)
    80003666:	bf4d                	j	80003618 <exit+0x290>
    80003668:	8792                	mv	a5,tp
  int id = r_tp();
    8000366a:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    8000366c:	09000713          	li	a4,144
    80003670:	02e786b3          	mul	a3,a5,a4
    80003674:	0000f717          	auipc	a4,0xf
    80003678:	c4c70713          	addi	a4,a4,-948 # 800122c0 <cpus>
    8000367c:	9736                	add	a4,a4,a3
    8000367e:	08f72423          	sw	a5,136(a4)
    mycpu()->runnable_list_tail = p->prev_proc;
    80003682:	06492783          	lw	a5,100(s2)
    80003686:	08f72223          	sw	a5,132(a4)
    if (proc[p->prev_proc].prev_proc == -1)
    8000368a:	19800713          	li	a4,408
    8000368e:	02e787b3          	mul	a5,a5,a4
    80003692:	0000f717          	auipc	a4,0xf
    80003696:	0de70713          	addi	a4,a4,222 # 80012770 <proc>
    8000369a:	97ba                	add	a5,a5,a4
    8000369c:	53f8                	lw	a4,100(a5)
    8000369e:	57fd                	li	a5,-1
    800036a0:	02f70863          	beq	a4,a5,800036d0 <exit+0x348>
    proc[p->prev_proc].next_proc = -1;
    800036a4:	06492783          	lw	a5,100(s2)
    800036a8:	19800713          	li	a4,408
    800036ac:	02e78733          	mul	a4,a5,a4
    800036b0:	0000f797          	auipc	a5,0xf
    800036b4:	0c078793          	addi	a5,a5,192 # 80012770 <proc>
    800036b8:	97ba                	add	a5,a5,a4
    800036ba:	577d                	li	a4,-1
    800036bc:	d3b8                	sw	a4,96(a5)
    printf("3 no tail");
    800036be:	00006517          	auipc	a0,0x6
    800036c2:	f3a50513          	addi	a0,a0,-198 # 800095f8 <digits+0x5b8>
    800036c6:	ffffd097          	auipc	ra,0xffffd
    800036ca:	ec2080e7          	jalr	-318(ra) # 80000588 <printf>
    800036ce:	b3e9                	j	80003498 <exit+0x110>
    800036d0:	8712                	mv	a4,tp
  int id = r_tp();
    800036d2:	2701                	sext.w	a4,a4
  c->cpu_id = id;
    800036d4:	09000793          	li	a5,144
    800036d8:	02f706b3          	mul	a3,a4,a5
    800036dc:	0000f797          	auipc	a5,0xf
    800036e0:	be478793          	addi	a5,a5,-1052 # 800122c0 <cpus>
    800036e4:	97b6                	add	a5,a5,a3
    800036e6:	08e7a423          	sw	a4,136(a5)
      mycpu()->runnable_list_head = p->prev_proc;
    800036ea:	06492703          	lw	a4,100(s2)
    800036ee:	08e7a023          	sw	a4,128(a5)
    800036f2:	bf4d                	j	800036a4 <exit+0x31c>
    printf("zombie");
    800036f4:	00006517          	auipc	a0,0x6
    800036f8:	b8450513          	addi	a0,a0,-1148 # 80009278 <digits+0x238>
    800036fc:	ffffd097          	auipc	ra,0xffffd
    80003700:	e8c080e7          	jalr	-372(ra) # 80000588 <printf>
    add_proc_to_list(zombie_list_tail, p);
    80003704:	85ca                	mv	a1,s2
    80003706:	00006517          	auipc	a0,0x6
    8000370a:	5a252503          	lw	a0,1442(a0) # 80009ca8 <zombie_list_tail>
    8000370e:	ffffe097          	auipc	ra,0xffffe
    80003712:	138080e7          	jalr	312(ra) # 80001846 <add_proc_to_list>
     if (zombie_list_head == -1)
    80003716:	00006717          	auipc	a4,0x6
    8000371a:	59672703          	lw	a4,1430(a4) # 80009cac <zombie_list_head>
    8000371e:	57fd                	li	a5,-1
    80003720:	00f70963          	beq	a4,a5,80003732 <exit+0x3aa>
    zombie_list_tail = p->proc_ind;
    80003724:	05c92783          	lw	a5,92(s2)
    80003728:	00006717          	auipc	a4,0x6
    8000372c:	58f72023          	sw	a5,1408(a4) # 80009ca8 <zombie_list_tail>
    80003730:	bb51                	j	800034c4 <exit+0x13c>
        zombie_list_head = p->proc_ind;
    80003732:	05c92783          	lw	a5,92(s2)
    80003736:	00006717          	auipc	a4,0x6
    8000373a:	56f72b23          	sw	a5,1398(a4) # 80009cac <zombie_list_head>
    8000373e:	b7dd                	j	80003724 <exit+0x39c>

0000000080003740 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80003740:	7179                	addi	sp,sp,-48
    80003742:	f406                	sd	ra,40(sp)
    80003744:	f022                	sd	s0,32(sp)
    80003746:	ec26                	sd	s1,24(sp)
    80003748:	e84a                	sd	s2,16(sp)
    8000374a:	e44e                	sd	s3,8(sp)
    8000374c:	1800                	addi	s0,sp,48
    8000374e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80003750:	0000f497          	auipc	s1,0xf
    80003754:	02048493          	addi	s1,s1,32 # 80012770 <proc>
    80003758:	00015997          	auipc	s3,0x15
    8000375c:	61898993          	addi	s3,s3,1560 # 80018d70 <tickslock>
    acquire(&p->lock);
    80003760:	8526                	mv	a0,s1
    80003762:	ffffd097          	auipc	ra,0xffffd
    80003766:	482080e7          	jalr	1154(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000376a:	589c                	lw	a5,48(s1)
    8000376c:	01278d63          	beq	a5,s2,80003786 <kill+0x46>
        p->last_runnable_time = ticks;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80003770:	8526                	mv	a0,s1
    80003772:	ffffd097          	auipc	ra,0xffffd
    80003776:	526080e7          	jalr	1318(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000377a:	19848493          	addi	s1,s1,408
    8000377e:	ff3491e3          	bne	s1,s3,80003760 <kill+0x20>
  }
  return -1;
    80003782:	557d                	li	a0,-1
    80003784:	a829                	j	8000379e <kill+0x5e>
      p->killed = 1;
    80003786:	4785                	li	a5,1
    80003788:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000378a:	4c98                	lw	a4,24(s1)
    8000378c:	4789                	li	a5,2
    8000378e:	00f70f63          	beq	a4,a5,800037ac <kill+0x6c>
      release(&p->lock);
    80003792:	8526                	mv	a0,s1
    80003794:	ffffd097          	auipc	ra,0xffffd
    80003798:	504080e7          	jalr	1284(ra) # 80000c98 <release>
      return 0;
    8000379c:	4501                	li	a0,0
}
    8000379e:	70a2                	ld	ra,40(sp)
    800037a0:	7402                	ld	s0,32(sp)
    800037a2:	64e2                	ld	s1,24(sp)
    800037a4:	6942                	ld	s2,16(sp)
    800037a6:	69a2                	ld	s3,8(sp)
    800037a8:	6145                	addi	sp,sp,48
    800037aa:	8082                	ret
        p->state = RUNNABLE;
    800037ac:	478d                	li	a5,3
    800037ae:	cc9c                	sw	a5,24(s1)
        p->sleeping_time += ticks - p->start_sleeping_time;
    800037b0:	00007717          	auipc	a4,0x7
    800037b4:	8a472703          	lw	a4,-1884(a4) # 8000a054 <ticks>
    800037b8:	44fc                	lw	a5,76(s1)
    800037ba:	9fb9                	addw	a5,a5,a4
    800037bc:	48f4                	lw	a3,84(s1)
    800037be:	9f95                	subw	a5,a5,a3
    800037c0:	c4fc                	sw	a5,76(s1)
        p->last_runnable_time = ticks;
    800037c2:	dcd8                	sw	a4,60(s1)
    800037c4:	b7f9                	j	80003792 <kill+0x52>

00000000800037c6 <print_stats>:

int 
print_stats(void)
{
    800037c6:	1141                	addi	sp,sp,-16
    800037c8:	e406                	sd	ra,8(sp)
    800037ca:	e022                	sd	s0,0(sp)
    800037cc:	0800                	addi	s0,sp,16
  printf("sleeping_processes_mean: %d\n", sleeping_processes_mean);
    800037ce:	00007597          	auipc	a1,0x7
    800037d2:	87a5a583          	lw	a1,-1926(a1) # 8000a048 <sleeping_processes_mean>
    800037d6:	00006517          	auipc	a0,0x6
    800037da:	e4250513          	addi	a0,a0,-446 # 80009618 <digits+0x5d8>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	daa080e7          	jalr	-598(ra) # 80000588 <printf>
  printf("runnable_processes_mean: %d\n", runnable_processes_mean);
    800037e6:	00007597          	auipc	a1,0x7
    800037ea:	85a5a583          	lw	a1,-1958(a1) # 8000a040 <runnable_processes_mean>
    800037ee:	00006517          	auipc	a0,0x6
    800037f2:	e4a50513          	addi	a0,a0,-438 # 80009638 <digits+0x5f8>
    800037f6:	ffffd097          	auipc	ra,0xffffd
    800037fa:	d92080e7          	jalr	-622(ra) # 80000588 <printf>
  printf("running_processes_mean: %d\n", running_processes_mean);
    800037fe:	00007597          	auipc	a1,0x7
    80003802:	8465a583          	lw	a1,-1978(a1) # 8000a044 <running_processes_mean>
    80003806:	00006517          	auipc	a0,0x6
    8000380a:	e5250513          	addi	a0,a0,-430 # 80009658 <digits+0x618>
    8000380e:	ffffd097          	auipc	ra,0xffffd
    80003812:	d7a080e7          	jalr	-646(ra) # 80000588 <printf>
  printf("program_time: %d\n", program_time);
    80003816:	00007597          	auipc	a1,0x7
    8000381a:	8225a583          	lw	a1,-2014(a1) # 8000a038 <program_time>
    8000381e:	00006517          	auipc	a0,0x6
    80003822:	e5a50513          	addi	a0,a0,-422 # 80009678 <digits+0x638>
    80003826:	ffffd097          	auipc	ra,0xffffd
    8000382a:	d62080e7          	jalr	-670(ra) # 80000588 <printf>
  printf("cpu_utilization: %d\n", cpu_utilization);
    8000382e:	00007597          	auipc	a1,0x7
    80003832:	8025a583          	lw	a1,-2046(a1) # 8000a030 <cpu_utilization>
    80003836:	00006517          	auipc	a0,0x6
    8000383a:	e5a50513          	addi	a0,a0,-422 # 80009690 <digits+0x650>
    8000383e:	ffffd097          	auipc	ra,0xffffd
    80003842:	d4a080e7          	jalr	-694(ra) # 80000588 <printf>
  printf("ticks: %d\n", ticks);
    80003846:	00007597          	auipc	a1,0x7
    8000384a:	80e5a583          	lw	a1,-2034(a1) # 8000a054 <ticks>
    8000384e:	00006517          	auipc	a0,0x6
    80003852:	e5a50513          	addi	a0,a0,-422 # 800096a8 <digits+0x668>
    80003856:	ffffd097          	auipc	ra,0xffffd
    8000385a:	d32080e7          	jalr	-718(ra) # 80000588 <printf>
  return 0;
}
    8000385e:	4501                	li	a0,0
    80003860:	60a2                	ld	ra,8(sp)
    80003862:	6402                	ld	s0,0(sp)
    80003864:	0141                	addi	sp,sp,16
    80003866:	8082                	ret

0000000080003868 <set_cpu>:
// Ass2
int
set_cpu(int cpu_num)
{
  // TODO
  if (cpu_num > NCPU)
    80003868:	47a1                	li	a5,8
    8000386a:	0aa7cd63          	blt	a5,a0,80003924 <set_cpu+0xbc>
{
    8000386e:	1101                	addi	sp,sp,-32
    80003870:	ec06                	sd	ra,24(sp)
    80003872:	e822                	sd	s0,16(sp)
    80003874:	e426                	sd	s1,8(sp)
    80003876:	e04a                	sd	s2,0(sp)
    80003878:	1000                	addi	s0,sp,32
    return -1;

  struct cpu* c;
  for(c = cpus; c < &cpus[NCPU]; c++)
    8000387a:	0000f497          	auipc	s1,0xf
    8000387e:	a4648493          	addi	s1,s1,-1466 # 800122c0 <cpus>
    80003882:	0000f717          	auipc	a4,0xf
    80003886:	ebe70713          	addi	a4,a4,-322 # 80012740 <pid_lock>
  {
    if (c->cpu_id == cpu_num)
    8000388a:	0884a783          	lw	a5,136(s1)
    8000388e:	00a78d63          	beq	a5,a0,800038a8 <set_cpu+0x40>
  for(c = cpus; c < &cpus[NCPU]; c++)
    80003892:	09048493          	addi	s1,s1,144
    80003896:	fee49ae3          	bne	s1,a4,8000388a <set_cpu+0x22>
      }
      
      return 0;
    }
  }
  return -1;
    8000389a:	557d                	li	a0,-1
}
    8000389c:	60e2                	ld	ra,24(sp)
    8000389e:	6442                	ld	s0,16(sp)
    800038a0:	64a2                	ld	s1,8(sp)
    800038a2:	6902                	ld	s2,0(sp)
    800038a4:	6105                	addi	sp,sp,32
    800038a6:	8082                	ret
      if (c->runnable_list_head == -1)
    800038a8:	0804a703          	lw	a4,128(s1)
    800038ac:	57fd                	li	a5,-1
    800038ae:	02f70f63          	beq	a4,a5,800038ec <set_cpu+0x84>
        printf("runnable5");
    800038b2:	00006517          	auipc	a0,0x6
    800038b6:	e2e50513          	addi	a0,a0,-466 # 800096e0 <digits+0x6a0>
    800038ba:	ffffd097          	auipc	ra,0xffffd
    800038be:	cce080e7          	jalr	-818(ra) # 80000588 <printf>
        add_proc_to_list(c->runnable_list_tail, myproc());
    800038c2:	0844a903          	lw	s2,132(s1)
    800038c6:	ffffe097          	auipc	ra,0xffffe
    800038ca:	2fe080e7          	jalr	766(ra) # 80001bc4 <myproc>
    800038ce:	85aa                	mv	a1,a0
    800038d0:	854a                	mv	a0,s2
    800038d2:	ffffe097          	auipc	ra,0xffffe
    800038d6:	f74080e7          	jalr	-140(ra) # 80001846 <add_proc_to_list>
        c->runnable_list_tail = myproc()->proc_ind;
    800038da:	ffffe097          	auipc	ra,0xffffe
    800038de:	2ea080e7          	jalr	746(ra) # 80001bc4 <myproc>
    800038e2:	4d7c                	lw	a5,92(a0)
    800038e4:	08f4a223          	sw	a5,132(s1)
      return 0;
    800038e8:	4501                	li	a0,0
    800038ea:	bf4d                	j	8000389c <set_cpu+0x34>
        printf("init runnable %d                   5\n", proc->proc_ind);
    800038ec:	0000f597          	auipc	a1,0xf
    800038f0:	ee05a583          	lw	a1,-288(a1) # 800127cc <proc+0x5c>
    800038f4:	00006517          	auipc	a0,0x6
    800038f8:	dc450513          	addi	a0,a0,-572 # 800096b8 <digits+0x678>
    800038fc:	ffffd097          	auipc	ra,0xffffd
    80003900:	c8c080e7          	jalr	-884(ra) # 80000588 <printf>
        c->runnable_list_tail = myproc()->proc_ind;
    80003904:	ffffe097          	auipc	ra,0xffffe
    80003908:	2c0080e7          	jalr	704(ra) # 80001bc4 <myproc>
    8000390c:	4d7c                	lw	a5,92(a0)
    8000390e:	08f4a223          	sw	a5,132(s1)
        c->runnable_list_head = myproc()->proc_ind;
    80003912:	ffffe097          	auipc	ra,0xffffe
    80003916:	2b2080e7          	jalr	690(ra) # 80001bc4 <myproc>
    8000391a:	4d7c                	lw	a5,92(a0)
    8000391c:	08f4a023          	sw	a5,128(s1)
      return 0;
    80003920:	4501                	li	a0,0
    80003922:	bfad                	j	8000389c <set_cpu+0x34>
    return -1;
    80003924:	557d                	li	a0,-1
}
    80003926:	8082                	ret

0000000080003928 <get_cpu>:


int
get_cpu()
{
    80003928:	1141                	addi	sp,sp,-16
    8000392a:	e422                	sd	s0,8(sp)
    8000392c:	0800                	addi	s0,sp,16
    8000392e:	8512                	mv	a0,tp
  // TODO
  return cpuid();
}
    80003930:	2501                	sext.w	a0,a0
    80003932:	6422                	ld	s0,8(sp)
    80003934:	0141                	addi	sp,sp,16
    80003936:	8082                	ret

0000000080003938 <pause_system>:


int
pause_system(int seconds)
{
    80003938:	711d                	addi	sp,sp,-96
    8000393a:	ec86                	sd	ra,88(sp)
    8000393c:	e8a2                	sd	s0,80(sp)
    8000393e:	e4a6                	sd	s1,72(sp)
    80003940:	e0ca                	sd	s2,64(sp)
    80003942:	fc4e                	sd	s3,56(sp)
    80003944:	f852                	sd	s4,48(sp)
    80003946:	f456                	sd	s5,40(sp)
    80003948:	f05a                	sd	s6,32(sp)
    8000394a:	ec5e                	sd	s7,24(sp)
    8000394c:	e862                	sd	s8,16(sp)
    8000394e:	e466                	sd	s9,8(sp)
    80003950:	1080                	addi	s0,sp,96
    80003952:	84aa                	mv	s1,a0
  struct proc *p;
  struct proc *myProcess = myproc();
    80003954:	ffffe097          	auipc	ra,0xffffe
    80003958:	270080e7          	jalr	624(ra) # 80001bc4 <myproc>
    8000395c:	8b2a                	mv	s6,a0

  pause_flag = 1;
    8000395e:	4785                	li	a5,1
    80003960:	00006717          	auipc	a4,0x6
    80003964:	6ef72823          	sw	a5,1776(a4) # 8000a050 <pause_flag>

  wake_up_time = ticks + (seconds * 10);
    80003968:	0024979b          	slliw	a5,s1,0x2
    8000396c:	9fa5                	addw	a5,a5,s1
    8000396e:	0017979b          	slliw	a5,a5,0x1
    80003972:	00006717          	auipc	a4,0x6
    80003976:	6e272703          	lw	a4,1762(a4) # 8000a054 <ticks>
    8000397a:	9fb9                	addw	a5,a5,a4
    8000397c:	00006717          	auipc	a4,0x6
    80003980:	6cf72823          	sw	a5,1744(a4) # 8000a04c <wake_up_time>

  for(p = proc; p < &proc[NPROC]; p++)
    80003984:	0000f497          	auipc	s1,0xf
    80003988:	dec48493          	addi	s1,s1,-532 # 80012770 <proc>
  {
    acquire(&p->lock);
    if(p->state == RUNNING)
    8000398c:	4991                	li	s3,4
    {
      if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    8000398e:	00006a97          	auipc	s5,0x6
    80003992:	c32a8a93          	addi	s5,s5,-974 # 800095c0 <digits+0x580>
    80003996:	00006b97          	auipc	s7,0x6
    8000399a:	c32b8b93          	addi	s7,s7,-974 # 800095c8 <digits+0x588>
        if (p != myProcess) {
          p->paused = 1;
    8000399e:	4c85                	li	s9,1
          p->running_time += ticks - p->start_running_time;
    800039a0:	00006c17          	auipc	s8,0x6
    800039a4:	6b4c0c13          	addi	s8,s8,1716 # 8000a054 <ticks>
  for(p = proc; p < &proc[NPROC]; p++)
    800039a8:	00015917          	auipc	s2,0x15
    800039ac:	3c890913          	addi	s2,s2,968 # 80018d70 <tickslock>
    800039b0:	a811                	j	800039c4 <pause_system+0x8c>
          yield();
        }
      }
    }
    release(&p->lock);
    800039b2:	8526                	mv	a0,s1
    800039b4:	ffffd097          	auipc	ra,0xffffd
    800039b8:	2e4080e7          	jalr	740(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++)
    800039bc:	19848493          	addi	s1,s1,408
    800039c0:	05248a63          	beq	s1,s2,80003a14 <pause_system+0xdc>
    acquire(&p->lock);
    800039c4:	8526                	mv	a0,s1
    800039c6:	ffffd097          	auipc	ra,0xffffd
    800039ca:	21e080e7          	jalr	542(ra) # 80000be4 <acquire>
    if(p->state == RUNNING)
    800039ce:	4c9c                	lw	a5,24(s1)
    800039d0:	ff3791e3          	bne	a5,s3,800039b2 <pause_system+0x7a>
      if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    800039d4:	18848a13          	addi	s4,s1,392
    800039d8:	85d6                	mv	a1,s5
    800039da:	8552                	mv	a0,s4
    800039dc:	ffffe097          	auipc	ra,0xffffe
    800039e0:	798080e7          	jalr	1944(ra) # 80002174 <str_compare>
    800039e4:	d579                	beqz	a0,800039b2 <pause_system+0x7a>
    800039e6:	85de                	mv	a1,s7
    800039e8:	8552                	mv	a0,s4
    800039ea:	ffffe097          	auipc	ra,0xffffe
    800039ee:	78a080e7          	jalr	1930(ra) # 80002174 <str_compare>
    800039f2:	d161                	beqz	a0,800039b2 <pause_system+0x7a>
        if (p != myProcess) {
    800039f4:	fa9b0fe3          	beq	s6,s1,800039b2 <pause_system+0x7a>
          p->paused = 1;
    800039f8:	0594a023          	sw	s9,64(s1)
          p->running_time += ticks - p->start_running_time;
    800039fc:	40fc                	lw	a5,68(s1)
    800039fe:	000c2703          	lw	a4,0(s8)
    80003a02:	9fb9                	addw	a5,a5,a4
    80003a04:	48b8                	lw	a4,80(s1)
    80003a06:	9f99                	subw	a5,a5,a4
    80003a08:	c0fc                	sw	a5,68(s1)
          yield();
    80003a0a:	fffff097          	auipc	ra,0xfffff
    80003a0e:	1e8080e7          	jalr	488(ra) # 80002bf2 <yield>
    80003a12:	b745                	j	800039b2 <pause_system+0x7a>
  }
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) 
    80003a14:	188b0493          	addi	s1,s6,392
    80003a18:	00006597          	auipc	a1,0x6
    80003a1c:	ba858593          	addi	a1,a1,-1112 # 800095c0 <digits+0x580>
    80003a20:	8526                	mv	a0,s1
    80003a22:	ffffe097          	auipc	ra,0xffffe
    80003a26:	752080e7          	jalr	1874(ra) # 80002174 <str_compare>
    80003a2a:	ed19                	bnez	a0,80003a48 <pause_system+0x110>
    myProcess->running_time += ticks - myProcess->start_running_time;
    release(&myProcess->lock);
    yield();
  }
  return 0;
}
    80003a2c:	4501                	li	a0,0
    80003a2e:	60e6                	ld	ra,88(sp)
    80003a30:	6446                	ld	s0,80(sp)
    80003a32:	64a6                	ld	s1,72(sp)
    80003a34:	6906                	ld	s2,64(sp)
    80003a36:	79e2                	ld	s3,56(sp)
    80003a38:	7a42                	ld	s4,48(sp)
    80003a3a:	7aa2                	ld	s5,40(sp)
    80003a3c:	7b02                	ld	s6,32(sp)
    80003a3e:	6be2                	ld	s7,24(sp)
    80003a40:	6c42                	ld	s8,16(sp)
    80003a42:	6ca2                	ld	s9,8(sp)
    80003a44:	6125                	addi	sp,sp,96
    80003a46:	8082                	ret
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) 
    80003a48:	00006597          	auipc	a1,0x6
    80003a4c:	b8058593          	addi	a1,a1,-1152 # 800095c8 <digits+0x588>
    80003a50:	8526                	mv	a0,s1
    80003a52:	ffffe097          	auipc	ra,0xffffe
    80003a56:	722080e7          	jalr	1826(ra) # 80002174 <str_compare>
    80003a5a:	d969                	beqz	a0,80003a2c <pause_system+0xf4>
    acquire(&myProcess->lock);
    80003a5c:	855a                	mv	a0,s6
    80003a5e:	ffffd097          	auipc	ra,0xffffd
    80003a62:	186080e7          	jalr	390(ra) # 80000be4 <acquire>
    myProcess->paused = 1;
    80003a66:	4785                	li	a5,1
    80003a68:	04fb2023          	sw	a5,64(s6)
    myProcess->running_time += ticks - myProcess->start_running_time;
    80003a6c:	044b2783          	lw	a5,68(s6)
    80003a70:	00006717          	auipc	a4,0x6
    80003a74:	5e472703          	lw	a4,1508(a4) # 8000a054 <ticks>
    80003a78:	9fb9                	addw	a5,a5,a4
    80003a7a:	050b2703          	lw	a4,80(s6)
    80003a7e:	9f99                	subw	a5,a5,a4
    80003a80:	04fb2223          	sw	a5,68(s6)
    release(&myProcess->lock);
    80003a84:	855a                	mv	a0,s6
    80003a86:	ffffd097          	auipc	ra,0xffffd
    80003a8a:	212080e7          	jalr	530(ra) # 80000c98 <release>
    yield();
    80003a8e:	fffff097          	auipc	ra,0xfffff
    80003a92:	164080e7          	jalr	356(ra) # 80002bf2 <yield>
    80003a96:	bf59                	j	80003a2c <pause_system+0xf4>

0000000080003a98 <kill_system>:
// depending on usr_dst.
// Returns 0 on success, -1 on error.

int
kill_system(void) 
{
    80003a98:	7139                	addi	sp,sp,-64
    80003a9a:	fc06                	sd	ra,56(sp)
    80003a9c:	f822                	sd	s0,48(sp)
    80003a9e:	f426                	sd	s1,40(sp)
    80003aa0:	f04a                	sd	s2,32(sp)
    80003aa2:	ec4e                	sd	s3,24(sp)
    80003aa4:	e852                	sd	s4,16(sp)
    80003aa6:	e456                	sd	s5,8(sp)
    80003aa8:	e05a                	sd	s6,0(sp)
    80003aaa:	0080                	addi	s0,sp,64
  struct proc *p;
  struct proc *myProcess = myproc();
    80003aac:	ffffe097          	auipc	ra,0xffffe
    80003ab0:	118080e7          	jalr	280(ra) # 80001bc4 <myproc>
    80003ab4:	8b2a                	mv	s6,a0

  for (p = proc; p < &proc[NPROC]; p++) {
    80003ab6:	0000f497          	auipc	s1,0xf
    80003aba:	e4248493          	addi	s1,s1,-446 # 800128f8 <proc+0x188>
    80003abe:	00015a17          	auipc	s4,0x15
    80003ac2:	43aa0a13          	addi	s4,s4,1082 # 80018ef8 <bcache+0x170>
    if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    80003ac6:	00006997          	auipc	s3,0x6
    80003aca:	afa98993          	addi	s3,s3,-1286 # 800095c0 <digits+0x580>
    80003ace:	00006a97          	auipc	s5,0x6
    80003ad2:	afaa8a93          	addi	s5,s5,-1286 # 800095c8 <digits+0x588>
    80003ad6:	a029                	j	80003ae0 <kill_system+0x48>
  for (p = proc; p < &proc[NPROC]; p++) {
    80003ad8:	19848493          	addi	s1,s1,408
    80003adc:	03448b63          	beq	s1,s4,80003b12 <kill_system+0x7a>
    if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    80003ae0:	85ce                	mv	a1,s3
    80003ae2:	8526                	mv	a0,s1
    80003ae4:	ffffe097          	auipc	ra,0xffffe
    80003ae8:	690080e7          	jalr	1680(ra) # 80002174 <str_compare>
    80003aec:	d575                	beqz	a0,80003ad8 <kill_system+0x40>
    80003aee:	85d6                	mv	a1,s5
    80003af0:	8526                	mv	a0,s1
    80003af2:	ffffe097          	auipc	ra,0xffffe
    80003af6:	682080e7          	jalr	1666(ra) # 80002174 <str_compare>
    80003afa:	dd79                	beqz	a0,80003ad8 <kill_system+0x40>
      if (p != myProcess) {
    80003afc:	e7848793          	addi	a5,s1,-392
    80003b00:	fcfb0ce3          	beq	s6,a5,80003ad8 <kill_system+0x40>
        kill(p->pid);      
    80003b04:	ea84a503          	lw	a0,-344(s1)
    80003b08:	00000097          	auipc	ra,0x0
    80003b0c:	c38080e7          	jalr	-968(ra) # 80003740 <kill>
    80003b10:	b7e1                	j	80003ad8 <kill_system+0x40>
      }
    }
  }
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) {
    80003b12:	188b0493          	addi	s1,s6,392
    80003b16:	00006597          	auipc	a1,0x6
    80003b1a:	aaa58593          	addi	a1,a1,-1366 # 800095c0 <digits+0x580>
    80003b1e:	8526                	mv	a0,s1
    80003b20:	ffffe097          	auipc	ra,0xffffe
    80003b24:	654080e7          	jalr	1620(ra) # 80002174 <str_compare>
    80003b28:	ed01                	bnez	a0,80003b40 <kill_system+0xa8>
    kill(myProcess->pid);
  }
  return 0;
}
    80003b2a:	4501                	li	a0,0
    80003b2c:	70e2                	ld	ra,56(sp)
    80003b2e:	7442                	ld	s0,48(sp)
    80003b30:	74a2                	ld	s1,40(sp)
    80003b32:	7902                	ld	s2,32(sp)
    80003b34:	69e2                	ld	s3,24(sp)
    80003b36:	6a42                	ld	s4,16(sp)
    80003b38:	6aa2                	ld	s5,8(sp)
    80003b3a:	6b02                	ld	s6,0(sp)
    80003b3c:	6121                	addi	sp,sp,64
    80003b3e:	8082                	ret
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) {
    80003b40:	00006597          	auipc	a1,0x6
    80003b44:	a8858593          	addi	a1,a1,-1400 # 800095c8 <digits+0x588>
    80003b48:	8526                	mv	a0,s1
    80003b4a:	ffffe097          	auipc	ra,0xffffe
    80003b4e:	62a080e7          	jalr	1578(ra) # 80002174 <str_compare>
    80003b52:	dd61                	beqz	a0,80003b2a <kill_system+0x92>
    kill(myProcess->pid);
    80003b54:	030b2503          	lw	a0,48(s6)
    80003b58:	00000097          	auipc	ra,0x0
    80003b5c:	be8080e7          	jalr	-1048(ra) # 80003740 <kill>
    80003b60:	b7e9                	j	80003b2a <kill_system+0x92>

0000000080003b62 <either_copyout>:

int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80003b62:	7179                	addi	sp,sp,-48
    80003b64:	f406                	sd	ra,40(sp)
    80003b66:	f022                	sd	s0,32(sp)
    80003b68:	ec26                	sd	s1,24(sp)
    80003b6a:	e84a                	sd	s2,16(sp)
    80003b6c:	e44e                	sd	s3,8(sp)
    80003b6e:	e052                	sd	s4,0(sp)
    80003b70:	1800                	addi	s0,sp,48
    80003b72:	84aa                	mv	s1,a0
    80003b74:	892e                	mv	s2,a1
    80003b76:	89b2                	mv	s3,a2
    80003b78:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80003b7a:	ffffe097          	auipc	ra,0xffffe
    80003b7e:	04a080e7          	jalr	74(ra) # 80001bc4 <myproc>
  if(user_dst){
    80003b82:	c08d                	beqz	s1,80003ba4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80003b84:	86d2                	mv	a3,s4
    80003b86:	864e                	mv	a2,s3
    80003b88:	85ca                	mv	a1,s2
    80003b8a:	6148                	ld	a0,128(a0)
    80003b8c:	ffffe097          	auipc	ra,0xffffe
    80003b90:	aee080e7          	jalr	-1298(ra) # 8000167a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80003b94:	70a2                	ld	ra,40(sp)
    80003b96:	7402                	ld	s0,32(sp)
    80003b98:	64e2                	ld	s1,24(sp)
    80003b9a:	6942                	ld	s2,16(sp)
    80003b9c:	69a2                	ld	s3,8(sp)
    80003b9e:	6a02                	ld	s4,0(sp)
    80003ba0:	6145                	addi	sp,sp,48
    80003ba2:	8082                	ret
    memmove((char *)dst, src, len);
    80003ba4:	000a061b          	sext.w	a2,s4
    80003ba8:	85ce                	mv	a1,s3
    80003baa:	854a                	mv	a0,s2
    80003bac:	ffffd097          	auipc	ra,0xffffd
    80003bb0:	194080e7          	jalr	404(ra) # 80000d40 <memmove>
    return 0;
    80003bb4:	8526                	mv	a0,s1
    80003bb6:	bff9                	j	80003b94 <either_copyout+0x32>

0000000080003bb8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80003bb8:	7179                	addi	sp,sp,-48
    80003bba:	f406                	sd	ra,40(sp)
    80003bbc:	f022                	sd	s0,32(sp)
    80003bbe:	ec26                	sd	s1,24(sp)
    80003bc0:	e84a                	sd	s2,16(sp)
    80003bc2:	e44e                	sd	s3,8(sp)
    80003bc4:	e052                	sd	s4,0(sp)
    80003bc6:	1800                	addi	s0,sp,48
    80003bc8:	892a                	mv	s2,a0
    80003bca:	84ae                	mv	s1,a1
    80003bcc:	89b2                	mv	s3,a2
    80003bce:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80003bd0:	ffffe097          	auipc	ra,0xffffe
    80003bd4:	ff4080e7          	jalr	-12(ra) # 80001bc4 <myproc>
  if(user_src){
    80003bd8:	c08d                	beqz	s1,80003bfa <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80003bda:	86d2                	mv	a3,s4
    80003bdc:	864e                	mv	a2,s3
    80003bde:	85ca                	mv	a1,s2
    80003be0:	6148                	ld	a0,128(a0)
    80003be2:	ffffe097          	auipc	ra,0xffffe
    80003be6:	b24080e7          	jalr	-1244(ra) # 80001706 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80003bea:	70a2                	ld	ra,40(sp)
    80003bec:	7402                	ld	s0,32(sp)
    80003bee:	64e2                	ld	s1,24(sp)
    80003bf0:	6942                	ld	s2,16(sp)
    80003bf2:	69a2                	ld	s3,8(sp)
    80003bf4:	6a02                	ld	s4,0(sp)
    80003bf6:	6145                	addi	sp,sp,48
    80003bf8:	8082                	ret
    memmove(dst, (char*)src, len);
    80003bfa:	000a061b          	sext.w	a2,s4
    80003bfe:	85ce                	mv	a1,s3
    80003c00:	854a                	mv	a0,s2
    80003c02:	ffffd097          	auipc	ra,0xffffd
    80003c06:	13e080e7          	jalr	318(ra) # 80000d40 <memmove>
    return 0;
    80003c0a:	8526                	mv	a0,s1
    80003c0c:	bff9                	j	80003bea <either_copyin+0x32>

0000000080003c0e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80003c0e:	715d                	addi	sp,sp,-80
    80003c10:	e486                	sd	ra,72(sp)
    80003c12:	e0a2                	sd	s0,64(sp)
    80003c14:	fc26                	sd	s1,56(sp)
    80003c16:	f84a                	sd	s2,48(sp)
    80003c18:	f44e                	sd	s3,40(sp)
    80003c1a:	f052                	sd	s4,32(sp)
    80003c1c:	ec56                	sd	s5,24(sp)
    80003c1e:	e85a                	sd	s6,16(sp)
    80003c20:	e45e                	sd	s7,8(sp)
    80003c22:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80003c24:	00006517          	auipc	a0,0x6
    80003c28:	a6450513          	addi	a0,a0,-1436 # 80009688 <digits+0x648>
    80003c2c:	ffffd097          	auipc	ra,0xffffd
    80003c30:	95c080e7          	jalr	-1700(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80003c34:	0000f497          	auipc	s1,0xf
    80003c38:	cc448493          	addi	s1,s1,-828 # 800128f8 <proc+0x188>
    80003c3c:	00015917          	auipc	s2,0x15
    80003c40:	2bc90913          	addi	s2,s2,700 # 80018ef8 <bcache+0x170>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003c44:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80003c46:	00006997          	auipc	s3,0x6
    80003c4a:	aaa98993          	addi	s3,s3,-1366 # 800096f0 <digits+0x6b0>
    printf("%d %s %s", p->pid, state, p->name);
    80003c4e:	00006a97          	auipc	s5,0x6
    80003c52:	aaaa8a93          	addi	s5,s5,-1366 # 800096f8 <digits+0x6b8>
    printf("\n");
    80003c56:	00006a17          	auipc	s4,0x6
    80003c5a:	a32a0a13          	addi	s4,s4,-1486 # 80009688 <digits+0x648>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003c5e:	00006b97          	auipc	s7,0x6
    80003c62:	ac2b8b93          	addi	s7,s7,-1342 # 80009720 <states.1847>
    80003c66:	a00d                	j	80003c88 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80003c68:	ea86a583          	lw	a1,-344(a3)
    80003c6c:	8556                	mv	a0,s5
    80003c6e:	ffffd097          	auipc	ra,0xffffd
    80003c72:	91a080e7          	jalr	-1766(ra) # 80000588 <printf>
    printf("\n");
    80003c76:	8552                	mv	a0,s4
    80003c78:	ffffd097          	auipc	ra,0xffffd
    80003c7c:	910080e7          	jalr	-1776(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80003c80:	19848493          	addi	s1,s1,408
    80003c84:	03248163          	beq	s1,s2,80003ca6 <procdump+0x98>
    if(p->state == UNUSED)
    80003c88:	86a6                	mv	a3,s1
    80003c8a:	e904a783          	lw	a5,-368(s1)
    80003c8e:	dbed                	beqz	a5,80003c80 <procdump+0x72>
      state = "???";
    80003c90:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003c92:	fcfb6be3          	bltu	s6,a5,80003c68 <procdump+0x5a>
    80003c96:	1782                	slli	a5,a5,0x20
    80003c98:	9381                	srli	a5,a5,0x20
    80003c9a:	078e                	slli	a5,a5,0x3
    80003c9c:	97de                	add	a5,a5,s7
    80003c9e:	6390                	ld	a2,0(a5)
    80003ca0:	f661                	bnez	a2,80003c68 <procdump+0x5a>
      state = "???";
    80003ca2:	864e                	mv	a2,s3
    80003ca4:	b7d1                	j	80003c68 <procdump+0x5a>
  }
}
    80003ca6:	60a6                	ld	ra,72(sp)
    80003ca8:	6406                	ld	s0,64(sp)
    80003caa:	74e2                	ld	s1,56(sp)
    80003cac:	7942                	ld	s2,48(sp)
    80003cae:	79a2                	ld	s3,40(sp)
    80003cb0:	7a02                	ld	s4,32(sp)
    80003cb2:	6ae2                	ld	s5,24(sp)
    80003cb4:	6b42                	ld	s6,16(sp)
    80003cb6:	6ba2                	ld	s7,8(sp)
    80003cb8:	6161                	addi	sp,sp,80
    80003cba:	8082                	ret

0000000080003cbc <swtch>:
    80003cbc:	00153023          	sd	ra,0(a0)
    80003cc0:	00253423          	sd	sp,8(a0)
    80003cc4:	e900                	sd	s0,16(a0)
    80003cc6:	ed04                	sd	s1,24(a0)
    80003cc8:	03253023          	sd	s2,32(a0)
    80003ccc:	03353423          	sd	s3,40(a0)
    80003cd0:	03453823          	sd	s4,48(a0)
    80003cd4:	03553c23          	sd	s5,56(a0)
    80003cd8:	05653023          	sd	s6,64(a0)
    80003cdc:	05753423          	sd	s7,72(a0)
    80003ce0:	05853823          	sd	s8,80(a0)
    80003ce4:	05953c23          	sd	s9,88(a0)
    80003ce8:	07a53023          	sd	s10,96(a0)
    80003cec:	07b53423          	sd	s11,104(a0)
    80003cf0:	0005b083          	ld	ra,0(a1)
    80003cf4:	0085b103          	ld	sp,8(a1)
    80003cf8:	6980                	ld	s0,16(a1)
    80003cfa:	6d84                	ld	s1,24(a1)
    80003cfc:	0205b903          	ld	s2,32(a1)
    80003d00:	0285b983          	ld	s3,40(a1)
    80003d04:	0305ba03          	ld	s4,48(a1)
    80003d08:	0385ba83          	ld	s5,56(a1)
    80003d0c:	0405bb03          	ld	s6,64(a1)
    80003d10:	0485bb83          	ld	s7,72(a1)
    80003d14:	0505bc03          	ld	s8,80(a1)
    80003d18:	0585bc83          	ld	s9,88(a1)
    80003d1c:	0605bd03          	ld	s10,96(a1)
    80003d20:	0685bd83          	ld	s11,104(a1)
    80003d24:	8082                	ret

0000000080003d26 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80003d26:	1141                	addi	sp,sp,-16
    80003d28:	e406                	sd	ra,8(sp)
    80003d2a:	e022                	sd	s0,0(sp)
    80003d2c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80003d2e:	00006597          	auipc	a1,0x6
    80003d32:	a2258593          	addi	a1,a1,-1502 # 80009750 <states.1847+0x30>
    80003d36:	00015517          	auipc	a0,0x15
    80003d3a:	03a50513          	addi	a0,a0,58 # 80018d70 <tickslock>
    80003d3e:	ffffd097          	auipc	ra,0xffffd
    80003d42:	e16080e7          	jalr	-490(ra) # 80000b54 <initlock>
}
    80003d46:	60a2                	ld	ra,8(sp)
    80003d48:	6402                	ld	s0,0(sp)
    80003d4a:	0141                	addi	sp,sp,16
    80003d4c:	8082                	ret

0000000080003d4e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80003d4e:	1141                	addi	sp,sp,-16
    80003d50:	e422                	sd	s0,8(sp)
    80003d52:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003d54:	00003797          	auipc	a5,0x3
    80003d58:	54c78793          	addi	a5,a5,1356 # 800072a0 <kernelvec>
    80003d5c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80003d60:	6422                	ld	s0,8(sp)
    80003d62:	0141                	addi	sp,sp,16
    80003d64:	8082                	ret

0000000080003d66 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80003d66:	1141                	addi	sp,sp,-16
    80003d68:	e406                	sd	ra,8(sp)
    80003d6a:	e022                	sd	s0,0(sp)
    80003d6c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003d6e:	ffffe097          	auipc	ra,0xffffe
    80003d72:	e56080e7          	jalr	-426(ra) # 80001bc4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003d76:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003d7a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003d7c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80003d80:	00004617          	auipc	a2,0x4
    80003d84:	28060613          	addi	a2,a2,640 # 80008000 <_trampoline>
    80003d88:	00004697          	auipc	a3,0x4
    80003d8c:	27868693          	addi	a3,a3,632 # 80008000 <_trampoline>
    80003d90:	8e91                	sub	a3,a3,a2
    80003d92:	040007b7          	lui	a5,0x4000
    80003d96:	17fd                	addi	a5,a5,-1
    80003d98:	07b2                	slli	a5,a5,0xc
    80003d9a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003d9c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003da0:	6558                	ld	a4,136(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003da2:	180026f3          	csrr	a3,satp
    80003da6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80003da8:	6558                	ld	a4,136(a0)
    80003daa:	7934                	ld	a3,112(a0)
    80003dac:	6585                	lui	a1,0x1
    80003dae:	96ae                	add	a3,a3,a1
    80003db0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80003db2:	6558                	ld	a4,136(a0)
    80003db4:	00000697          	auipc	a3,0x0
    80003db8:	13868693          	addi	a3,a3,312 # 80003eec <usertrap>
    80003dbc:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80003dbe:	6558                	ld	a4,136(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003dc0:	8692                	mv	a3,tp
    80003dc2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003dc4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003dc8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003dcc:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003dd0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80003dd4:	6558                	ld	a4,136(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003dd6:	6f18                	ld	a4,24(a4)
    80003dd8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003ddc:	614c                	ld	a1,128(a0)
    80003dde:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80003de0:	00004717          	auipc	a4,0x4
    80003de4:	2b070713          	addi	a4,a4,688 # 80008090 <userret>
    80003de8:	8f11                	sub	a4,a4,a2
    80003dea:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80003dec:	577d                	li	a4,-1
    80003dee:	177e                	slli	a4,a4,0x3f
    80003df0:	8dd9                	or	a1,a1,a4
    80003df2:	02000537          	lui	a0,0x2000
    80003df6:	157d                	addi	a0,a0,-1
    80003df8:	0536                	slli	a0,a0,0xd
    80003dfa:	9782                	jalr	a5
}
    80003dfc:	60a2                	ld	ra,8(sp)
    80003dfe:	6402                	ld	s0,0(sp)
    80003e00:	0141                	addi	sp,sp,16
    80003e02:	8082                	ret

0000000080003e04 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80003e04:	1101                	addi	sp,sp,-32
    80003e06:	ec06                	sd	ra,24(sp)
    80003e08:	e822                	sd	s0,16(sp)
    80003e0a:	e426                	sd	s1,8(sp)
    80003e0c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003e0e:	00015497          	auipc	s1,0x15
    80003e12:	f6248493          	addi	s1,s1,-158 # 80018d70 <tickslock>
    80003e16:	8526                	mv	a0,s1
    80003e18:	ffffd097          	auipc	ra,0xffffd
    80003e1c:	dcc080e7          	jalr	-564(ra) # 80000be4 <acquire>
  ticks++;
    80003e20:	00006517          	auipc	a0,0x6
    80003e24:	23450513          	addi	a0,a0,564 # 8000a054 <ticks>
    80003e28:	411c                	lw	a5,0(a0)
    80003e2a:	2785                	addiw	a5,a5,1
    80003e2c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80003e2e:	fffff097          	auipc	ra,0xfffff
    80003e32:	30a080e7          	jalr	778(ra) # 80003138 <wakeup>
  release(&tickslock);
    80003e36:	8526                	mv	a0,s1
    80003e38:	ffffd097          	auipc	ra,0xffffd
    80003e3c:	e60080e7          	jalr	-416(ra) # 80000c98 <release>
}
    80003e40:	60e2                	ld	ra,24(sp)
    80003e42:	6442                	ld	s0,16(sp)
    80003e44:	64a2                	ld	s1,8(sp)
    80003e46:	6105                	addi	sp,sp,32
    80003e48:	8082                	ret

0000000080003e4a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003e4a:	1101                	addi	sp,sp,-32
    80003e4c:	ec06                	sd	ra,24(sp)
    80003e4e:	e822                	sd	s0,16(sp)
    80003e50:	e426                	sd	s1,8(sp)
    80003e52:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003e54:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003e58:	00074d63          	bltz	a4,80003e72 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003e5c:	57fd                	li	a5,-1
    80003e5e:	17fe                	slli	a5,a5,0x3f
    80003e60:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80003e62:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80003e64:	06f70363          	beq	a4,a5,80003eca <devintr+0x80>
  }
}
    80003e68:	60e2                	ld	ra,24(sp)
    80003e6a:	6442                	ld	s0,16(sp)
    80003e6c:	64a2                	ld	s1,8(sp)
    80003e6e:	6105                	addi	sp,sp,32
    80003e70:	8082                	ret
     (scause & 0xff) == 9){
    80003e72:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80003e76:	46a5                	li	a3,9
    80003e78:	fed792e3          	bne	a5,a3,80003e5c <devintr+0x12>
    int irq = plic_claim();
    80003e7c:	00003097          	auipc	ra,0x3
    80003e80:	52c080e7          	jalr	1324(ra) # 800073a8 <plic_claim>
    80003e84:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003e86:	47a9                	li	a5,10
    80003e88:	02f50763          	beq	a0,a5,80003eb6 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003e8c:	4785                	li	a5,1
    80003e8e:	02f50963          	beq	a0,a5,80003ec0 <devintr+0x76>
    return 1;
    80003e92:	4505                	li	a0,1
    } else if(irq){
    80003e94:	d8f1                	beqz	s1,80003e68 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003e96:	85a6                	mv	a1,s1
    80003e98:	00006517          	auipc	a0,0x6
    80003e9c:	8c050513          	addi	a0,a0,-1856 # 80009758 <states.1847+0x38>
    80003ea0:	ffffc097          	auipc	ra,0xffffc
    80003ea4:	6e8080e7          	jalr	1768(ra) # 80000588 <printf>
      plic_complete(irq);
    80003ea8:	8526                	mv	a0,s1
    80003eaa:	00003097          	auipc	ra,0x3
    80003eae:	522080e7          	jalr	1314(ra) # 800073cc <plic_complete>
    return 1;
    80003eb2:	4505                	li	a0,1
    80003eb4:	bf55                	j	80003e68 <devintr+0x1e>
      uartintr();
    80003eb6:	ffffd097          	auipc	ra,0xffffd
    80003eba:	af2080e7          	jalr	-1294(ra) # 800009a8 <uartintr>
    80003ebe:	b7ed                	j	80003ea8 <devintr+0x5e>
      virtio_disk_intr();
    80003ec0:	00004097          	auipc	ra,0x4
    80003ec4:	9ec080e7          	jalr	-1556(ra) # 800078ac <virtio_disk_intr>
    80003ec8:	b7c5                	j	80003ea8 <devintr+0x5e>
    if(cpuid() == 0){
    80003eca:	ffffe097          	auipc	ra,0xffffe
    80003ece:	cbe080e7          	jalr	-834(ra) # 80001b88 <cpuid>
    80003ed2:	c901                	beqz	a0,80003ee2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003ed4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003ed8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003eda:	14479073          	csrw	sip,a5
    return 2;
    80003ede:	4509                	li	a0,2
    80003ee0:	b761                	j	80003e68 <devintr+0x1e>
      clockintr();
    80003ee2:	00000097          	auipc	ra,0x0
    80003ee6:	f22080e7          	jalr	-222(ra) # 80003e04 <clockintr>
    80003eea:	b7ed                	j	80003ed4 <devintr+0x8a>

0000000080003eec <usertrap>:
{
    80003eec:	1101                	addi	sp,sp,-32
    80003eee:	ec06                	sd	ra,24(sp)
    80003ef0:	e822                	sd	s0,16(sp)
    80003ef2:	e426                	sd	s1,8(sp)
    80003ef4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003ef6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003efa:	1007f793          	andi	a5,a5,256
    80003efe:	e3a5                	bnez	a5,80003f5e <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003f00:	00003797          	auipc	a5,0x3
    80003f04:	3a078793          	addi	a5,a5,928 # 800072a0 <kernelvec>
    80003f08:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003f0c:	ffffe097          	auipc	ra,0xffffe
    80003f10:	cb8080e7          	jalr	-840(ra) # 80001bc4 <myproc>
    80003f14:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003f16:	655c                	ld	a5,136(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003f18:	14102773          	csrr	a4,sepc
    80003f1c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003f1e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003f22:	47a1                	li	a5,8
    80003f24:	04f71b63          	bne	a4,a5,80003f7a <usertrap+0x8e>
    if(p->killed)
    80003f28:	551c                	lw	a5,40(a0)
    80003f2a:	e3b1                	bnez	a5,80003f6e <usertrap+0x82>
    p->trapframe->epc += 4;
    80003f2c:	64d8                	ld	a4,136(s1)
    80003f2e:	6f1c                	ld	a5,24(a4)
    80003f30:	0791                	addi	a5,a5,4
    80003f32:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003f34:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003f38:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003f3c:	10079073          	csrw	sstatus,a5
    syscall();
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	2f0080e7          	jalr	752(ra) # 80004230 <syscall>
  if(p->killed)
    80003f48:	549c                	lw	a5,40(s1)
    80003f4a:	e7b5                	bnez	a5,80003fb6 <usertrap+0xca>
  usertrapret();
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	e1a080e7          	jalr	-486(ra) # 80003d66 <usertrapret>
}
    80003f54:	60e2                	ld	ra,24(sp)
    80003f56:	6442                	ld	s0,16(sp)
    80003f58:	64a2                	ld	s1,8(sp)
    80003f5a:	6105                	addi	sp,sp,32
    80003f5c:	8082                	ret
    panic("usertrap: not from user mode");
    80003f5e:	00006517          	auipc	a0,0x6
    80003f62:	81a50513          	addi	a0,a0,-2022 # 80009778 <states.1847+0x58>
    80003f66:	ffffc097          	auipc	ra,0xffffc
    80003f6a:	5d8080e7          	jalr	1496(ra) # 8000053e <panic>
      exit(-1);
    80003f6e:	557d                	li	a0,-1
    80003f70:	fffff097          	auipc	ra,0xfffff
    80003f74:	418080e7          	jalr	1048(ra) # 80003388 <exit>
    80003f78:	bf55                	j	80003f2c <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    80003f7a:	00000097          	auipc	ra,0x0
    80003f7e:	ed0080e7          	jalr	-304(ra) # 80003e4a <devintr>
    80003f82:	f179                	bnez	a0,80003f48 <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003f84:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003f88:	5890                	lw	a2,48(s1)
    80003f8a:	00006517          	auipc	a0,0x6
    80003f8e:	80e50513          	addi	a0,a0,-2034 # 80009798 <states.1847+0x78>
    80003f92:	ffffc097          	auipc	ra,0xffffc
    80003f96:	5f6080e7          	jalr	1526(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003f9a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003f9e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003fa2:	00006517          	auipc	a0,0x6
    80003fa6:	82650513          	addi	a0,a0,-2010 # 800097c8 <states.1847+0xa8>
    80003faa:	ffffc097          	auipc	ra,0xffffc
    80003fae:	5de080e7          	jalr	1502(ra) # 80000588 <printf>
    p->killed = 1;
    80003fb2:	4785                	li	a5,1
    80003fb4:	d49c                	sw	a5,40(s1)
    exit(-1);
    80003fb6:	557d                	li	a0,-1
    80003fb8:	fffff097          	auipc	ra,0xfffff
    80003fbc:	3d0080e7          	jalr	976(ra) # 80003388 <exit>
    80003fc0:	b771                	j	80003f4c <usertrap+0x60>

0000000080003fc2 <kerneltrap>:
{
    80003fc2:	7179                	addi	sp,sp,-48
    80003fc4:	f406                	sd	ra,40(sp)
    80003fc6:	f022                	sd	s0,32(sp)
    80003fc8:	ec26                	sd	s1,24(sp)
    80003fca:	e84a                	sd	s2,16(sp)
    80003fcc:	e44e                	sd	s3,8(sp)
    80003fce:	e052                	sd	s4,0(sp)
    80003fd0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003fd2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003fd6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003fda:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0){
    80003fde:	1004f793          	andi	a5,s1,256
    80003fe2:	cb8d                	beqz	a5,80004014 <kerneltrap+0x52>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003fe4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003fe8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003fea:	ef8d                	bnez	a5,80004024 <kerneltrap+0x62>
  if((which_dev = devintr()) == 0){
    80003fec:	00000097          	auipc	ra,0x0
    80003ff0:	e5e080e7          	jalr	-418(ra) # 80003e4a <devintr>
    80003ff4:	c121                	beqz	a0,80004034 <kerneltrap+0x72>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80003ff6:	4789                	li	a5,2
    80003ff8:	06f50b63          	beq	a0,a5,8000406e <kerneltrap+0xac>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003ffc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80004000:	10049073          	csrw	sstatus,s1
}
    80004004:	70a2                	ld	ra,40(sp)
    80004006:	7402                	ld	s0,32(sp)
    80004008:	64e2                	ld	s1,24(sp)
    8000400a:	6942                	ld	s2,16(sp)
    8000400c:	69a2                	ld	s3,8(sp)
    8000400e:	6a02                	ld	s4,0(sp)
    80004010:	6145                	addi	sp,sp,48
    80004012:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80004014:	00005517          	auipc	a0,0x5
    80004018:	7d450513          	addi	a0,a0,2004 # 800097e8 <states.1847+0xc8>
    8000401c:	ffffc097          	auipc	ra,0xffffc
    80004020:	522080e7          	jalr	1314(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80004024:	00005517          	auipc	a0,0x5
    80004028:	7ec50513          	addi	a0,a0,2028 # 80009810 <states.1847+0xf0>
    8000402c:	ffffc097          	auipc	ra,0xffffc
    80004030:	512080e7          	jalr	1298(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80004034:	85ce                	mv	a1,s3
    80004036:	00005517          	auipc	a0,0x5
    8000403a:	7fa50513          	addi	a0,a0,2042 # 80009830 <states.1847+0x110>
    8000403e:	ffffc097          	auipc	ra,0xffffc
    80004042:	54a080e7          	jalr	1354(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80004046:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000404a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000404e:	00005517          	auipc	a0,0x5
    80004052:	7f250513          	addi	a0,a0,2034 # 80009840 <states.1847+0x120>
    80004056:	ffffc097          	auipc	ra,0xffffc
    8000405a:	532080e7          	jalr	1330(ra) # 80000588 <printf>
    panic("kerneltrap");
    8000405e:	00005517          	auipc	a0,0x5
    80004062:	7fa50513          	addi	a0,a0,2042 # 80009858 <states.1847+0x138>
    80004066:	ffffc097          	auipc	ra,0xffffc
    8000406a:	4d8080e7          	jalr	1240(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    8000406e:	ffffe097          	auipc	ra,0xffffe
    80004072:	b56080e7          	jalr	-1194(ra) # 80001bc4 <myproc>
    80004076:	d159                	beqz	a0,80003ffc <kerneltrap+0x3a>
    80004078:	ffffe097          	auipc	ra,0xffffe
    8000407c:	b4c080e7          	jalr	-1204(ra) # 80001bc4 <myproc>
    80004080:	4d18                	lw	a4,24(a0)
    80004082:	4791                	li	a5,4
    80004084:	f6f71ce3          	bne	a4,a5,80003ffc <kerneltrap+0x3a>
    myproc()->running_time += ticks - myproc()->start_running_time;
    80004088:	00006a17          	auipc	s4,0x6
    8000408c:	fcca2a03          	lw	s4,-52(s4) # 8000a054 <ticks>
    80004090:	ffffe097          	auipc	ra,0xffffe
    80004094:	b34080e7          	jalr	-1228(ra) # 80001bc4 <myproc>
    80004098:	05052983          	lw	s3,80(a0)
    8000409c:	ffffe097          	auipc	ra,0xffffe
    800040a0:	b28080e7          	jalr	-1240(ra) # 80001bc4 <myproc>
    800040a4:	417c                	lw	a5,68(a0)
    800040a6:	014787bb          	addw	a5,a5,s4
    800040aa:	413787bb          	subw	a5,a5,s3
    800040ae:	c17c                	sw	a5,68(a0)
    yield();
    800040b0:	fffff097          	auipc	ra,0xfffff
    800040b4:	b42080e7          	jalr	-1214(ra) # 80002bf2 <yield>
    800040b8:	b791                	j	80003ffc <kerneltrap+0x3a>

00000000800040ba <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800040ba:	1101                	addi	sp,sp,-32
    800040bc:	ec06                	sd	ra,24(sp)
    800040be:	e822                	sd	s0,16(sp)
    800040c0:	e426                	sd	s1,8(sp)
    800040c2:	1000                	addi	s0,sp,32
    800040c4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800040c6:	ffffe097          	auipc	ra,0xffffe
    800040ca:	afe080e7          	jalr	-1282(ra) # 80001bc4 <myproc>
  switch (n) {
    800040ce:	4795                	li	a5,5
    800040d0:	0497e163          	bltu	a5,s1,80004112 <argraw+0x58>
    800040d4:	048a                	slli	s1,s1,0x2
    800040d6:	00005717          	auipc	a4,0x5
    800040da:	7ba70713          	addi	a4,a4,1978 # 80009890 <states.1847+0x170>
    800040de:	94ba                	add	s1,s1,a4
    800040e0:	409c                	lw	a5,0(s1)
    800040e2:	97ba                	add	a5,a5,a4
    800040e4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800040e6:	655c                	ld	a5,136(a0)
    800040e8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800040ea:	60e2                	ld	ra,24(sp)
    800040ec:	6442                	ld	s0,16(sp)
    800040ee:	64a2                	ld	s1,8(sp)
    800040f0:	6105                	addi	sp,sp,32
    800040f2:	8082                	ret
    return p->trapframe->a1;
    800040f4:	655c                	ld	a5,136(a0)
    800040f6:	7fa8                	ld	a0,120(a5)
    800040f8:	bfcd                	j	800040ea <argraw+0x30>
    return p->trapframe->a2;
    800040fa:	655c                	ld	a5,136(a0)
    800040fc:	63c8                	ld	a0,128(a5)
    800040fe:	b7f5                	j	800040ea <argraw+0x30>
    return p->trapframe->a3;
    80004100:	655c                	ld	a5,136(a0)
    80004102:	67c8                	ld	a0,136(a5)
    80004104:	b7dd                	j	800040ea <argraw+0x30>
    return p->trapframe->a4;
    80004106:	655c                	ld	a5,136(a0)
    80004108:	6bc8                	ld	a0,144(a5)
    8000410a:	b7c5                	j	800040ea <argraw+0x30>
    return p->trapframe->a5;
    8000410c:	655c                	ld	a5,136(a0)
    8000410e:	6fc8                	ld	a0,152(a5)
    80004110:	bfe9                	j	800040ea <argraw+0x30>
  panic("argraw");
    80004112:	00005517          	auipc	a0,0x5
    80004116:	75650513          	addi	a0,a0,1878 # 80009868 <states.1847+0x148>
    8000411a:	ffffc097          	auipc	ra,0xffffc
    8000411e:	424080e7          	jalr	1060(ra) # 8000053e <panic>

0000000080004122 <fetchaddr>:
{
    80004122:	1101                	addi	sp,sp,-32
    80004124:	ec06                	sd	ra,24(sp)
    80004126:	e822                	sd	s0,16(sp)
    80004128:	e426                	sd	s1,8(sp)
    8000412a:	e04a                	sd	s2,0(sp)
    8000412c:	1000                	addi	s0,sp,32
    8000412e:	84aa                	mv	s1,a0
    80004130:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80004132:	ffffe097          	auipc	ra,0xffffe
    80004136:	a92080e7          	jalr	-1390(ra) # 80001bc4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    8000413a:	7d3c                	ld	a5,120(a0)
    8000413c:	02f4f863          	bgeu	s1,a5,8000416c <fetchaddr+0x4a>
    80004140:	00848713          	addi	a4,s1,8
    80004144:	02e7e663          	bltu	a5,a4,80004170 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80004148:	46a1                	li	a3,8
    8000414a:	8626                	mv	a2,s1
    8000414c:	85ca                	mv	a1,s2
    8000414e:	6148                	ld	a0,128(a0)
    80004150:	ffffd097          	auipc	ra,0xffffd
    80004154:	5b6080e7          	jalr	1462(ra) # 80001706 <copyin>
    80004158:	00a03533          	snez	a0,a0
    8000415c:	40a00533          	neg	a0,a0
}
    80004160:	60e2                	ld	ra,24(sp)
    80004162:	6442                	ld	s0,16(sp)
    80004164:	64a2                	ld	s1,8(sp)
    80004166:	6902                	ld	s2,0(sp)
    80004168:	6105                	addi	sp,sp,32
    8000416a:	8082                	ret
    return -1;
    8000416c:	557d                	li	a0,-1
    8000416e:	bfcd                	j	80004160 <fetchaddr+0x3e>
    80004170:	557d                	li	a0,-1
    80004172:	b7fd                	j	80004160 <fetchaddr+0x3e>

0000000080004174 <fetchstr>:
{
    80004174:	7179                	addi	sp,sp,-48
    80004176:	f406                	sd	ra,40(sp)
    80004178:	f022                	sd	s0,32(sp)
    8000417a:	ec26                	sd	s1,24(sp)
    8000417c:	e84a                	sd	s2,16(sp)
    8000417e:	e44e                	sd	s3,8(sp)
    80004180:	1800                	addi	s0,sp,48
    80004182:	892a                	mv	s2,a0
    80004184:	84ae                	mv	s1,a1
    80004186:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80004188:	ffffe097          	auipc	ra,0xffffe
    8000418c:	a3c080e7          	jalr	-1476(ra) # 80001bc4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80004190:	86ce                	mv	a3,s3
    80004192:	864a                	mv	a2,s2
    80004194:	85a6                	mv	a1,s1
    80004196:	6148                	ld	a0,128(a0)
    80004198:	ffffd097          	auipc	ra,0xffffd
    8000419c:	5fa080e7          	jalr	1530(ra) # 80001792 <copyinstr>
  if(err < 0)
    800041a0:	00054763          	bltz	a0,800041ae <fetchstr+0x3a>
  return strlen(buf);
    800041a4:	8526                	mv	a0,s1
    800041a6:	ffffd097          	auipc	ra,0xffffd
    800041aa:	cbe080e7          	jalr	-834(ra) # 80000e64 <strlen>
}
    800041ae:	70a2                	ld	ra,40(sp)
    800041b0:	7402                	ld	s0,32(sp)
    800041b2:	64e2                	ld	s1,24(sp)
    800041b4:	6942                	ld	s2,16(sp)
    800041b6:	69a2                	ld	s3,8(sp)
    800041b8:	6145                	addi	sp,sp,48
    800041ba:	8082                	ret

00000000800041bc <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800041bc:	1101                	addi	sp,sp,-32
    800041be:	ec06                	sd	ra,24(sp)
    800041c0:	e822                	sd	s0,16(sp)
    800041c2:	e426                	sd	s1,8(sp)
    800041c4:	1000                	addi	s0,sp,32
    800041c6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800041c8:	00000097          	auipc	ra,0x0
    800041cc:	ef2080e7          	jalr	-270(ra) # 800040ba <argraw>
    800041d0:	c088                	sw	a0,0(s1)
  return 0;
}
    800041d2:	4501                	li	a0,0
    800041d4:	60e2                	ld	ra,24(sp)
    800041d6:	6442                	ld	s0,16(sp)
    800041d8:	64a2                	ld	s1,8(sp)
    800041da:	6105                	addi	sp,sp,32
    800041dc:	8082                	ret

00000000800041de <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800041de:	1101                	addi	sp,sp,-32
    800041e0:	ec06                	sd	ra,24(sp)
    800041e2:	e822                	sd	s0,16(sp)
    800041e4:	e426                	sd	s1,8(sp)
    800041e6:	1000                	addi	s0,sp,32
    800041e8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800041ea:	00000097          	auipc	ra,0x0
    800041ee:	ed0080e7          	jalr	-304(ra) # 800040ba <argraw>
    800041f2:	e088                	sd	a0,0(s1)
  return 0;
}
    800041f4:	4501                	li	a0,0
    800041f6:	60e2                	ld	ra,24(sp)
    800041f8:	6442                	ld	s0,16(sp)
    800041fa:	64a2                	ld	s1,8(sp)
    800041fc:	6105                	addi	sp,sp,32
    800041fe:	8082                	ret

0000000080004200 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80004200:	1101                	addi	sp,sp,-32
    80004202:	ec06                	sd	ra,24(sp)
    80004204:	e822                	sd	s0,16(sp)
    80004206:	e426                	sd	s1,8(sp)
    80004208:	e04a                	sd	s2,0(sp)
    8000420a:	1000                	addi	s0,sp,32
    8000420c:	84ae                	mv	s1,a1
    8000420e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80004210:	00000097          	auipc	ra,0x0
    80004214:	eaa080e7          	jalr	-342(ra) # 800040ba <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80004218:	864a                	mv	a2,s2
    8000421a:	85a6                	mv	a1,s1
    8000421c:	00000097          	auipc	ra,0x0
    80004220:	f58080e7          	jalr	-168(ra) # 80004174 <fetchstr>
}
    80004224:	60e2                	ld	ra,24(sp)
    80004226:	6442                	ld	s0,16(sp)
    80004228:	64a2                	ld	s1,8(sp)
    8000422a:	6902                	ld	s2,0(sp)
    8000422c:	6105                	addi	sp,sp,32
    8000422e:	8082                	ret

0000000080004230 <syscall>:
[SYS_set_cpu]       sys_set_cpu,
};

void
syscall(void)
{
    80004230:	1101                	addi	sp,sp,-32
    80004232:	ec06                	sd	ra,24(sp)
    80004234:	e822                	sd	s0,16(sp)
    80004236:	e426                	sd	s1,8(sp)
    80004238:	e04a                	sd	s2,0(sp)
    8000423a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000423c:	ffffe097          	auipc	ra,0xffffe
    80004240:	988080e7          	jalr	-1656(ra) # 80001bc4 <myproc>
    80004244:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80004246:	08853903          	ld	s2,136(a0)
    8000424a:	0a893783          	ld	a5,168(s2)
    8000424e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80004252:	37fd                	addiw	a5,a5,-1
    80004254:	4765                	li	a4,25
    80004256:	00f76f63          	bltu	a4,a5,80004274 <syscall+0x44>
    8000425a:	00369713          	slli	a4,a3,0x3
    8000425e:	00005797          	auipc	a5,0x5
    80004262:	64a78793          	addi	a5,a5,1610 # 800098a8 <syscalls>
    80004266:	97ba                	add	a5,a5,a4
    80004268:	639c                	ld	a5,0(a5)
    8000426a:	c789                	beqz	a5,80004274 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000426c:	9782                	jalr	a5
    8000426e:	06a93823          	sd	a0,112(s2)
    80004272:	a839                	j	80004290 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80004274:	18848613          	addi	a2,s1,392
    80004278:	588c                	lw	a1,48(s1)
    8000427a:	00005517          	auipc	a0,0x5
    8000427e:	5f650513          	addi	a0,a0,1526 # 80009870 <states.1847+0x150>
    80004282:	ffffc097          	auipc	ra,0xffffc
    80004286:	306080e7          	jalr	774(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000428a:	64dc                	ld	a5,136(s1)
    8000428c:	577d                	li	a4,-1
    8000428e:	fbb8                	sd	a4,112(a5)
  }
}
    80004290:	60e2                	ld	ra,24(sp)
    80004292:	6442                	ld	s0,16(sp)
    80004294:	64a2                	ld	s1,8(sp)
    80004296:	6902                	ld	s2,0(sp)
    80004298:	6105                	addi	sp,sp,32
    8000429a:	8082                	ret

000000008000429c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000429c:	1101                	addi	sp,sp,-32
    8000429e:	ec06                	sd	ra,24(sp)
    800042a0:	e822                	sd	s0,16(sp)
    800042a2:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800042a4:	fec40593          	addi	a1,s0,-20
    800042a8:	4501                	li	a0,0
    800042aa:	00000097          	auipc	ra,0x0
    800042ae:	f12080e7          	jalr	-238(ra) # 800041bc <argint>
    return -1;
    800042b2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800042b4:	00054963          	bltz	a0,800042c6 <sys_exit+0x2a>
  exit(n);
    800042b8:	fec42503          	lw	a0,-20(s0)
    800042bc:	fffff097          	auipc	ra,0xfffff
    800042c0:	0cc080e7          	jalr	204(ra) # 80003388 <exit>
  return 0;  // not reached
    800042c4:	4781                	li	a5,0
}
    800042c6:	853e                	mv	a0,a5
    800042c8:	60e2                	ld	ra,24(sp)
    800042ca:	6442                	ld	s0,16(sp)
    800042cc:	6105                	addi	sp,sp,32
    800042ce:	8082                	ret

00000000800042d0 <sys_getpid>:

uint64
sys_getpid(void)
{
    800042d0:	1141                	addi	sp,sp,-16
    800042d2:	e406                	sd	ra,8(sp)
    800042d4:	e022                	sd	s0,0(sp)
    800042d6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800042d8:	ffffe097          	auipc	ra,0xffffe
    800042dc:	8ec080e7          	jalr	-1812(ra) # 80001bc4 <myproc>
}
    800042e0:	5908                	lw	a0,48(a0)
    800042e2:	60a2                	ld	ra,8(sp)
    800042e4:	6402                	ld	s0,0(sp)
    800042e6:	0141                	addi	sp,sp,16
    800042e8:	8082                	ret

00000000800042ea <sys_fork>:

uint64
sys_fork(void)
{
    800042ea:	1141                	addi	sp,sp,-16
    800042ec:	e406                	sd	ra,8(sp)
    800042ee:	e022                	sd	s0,0(sp)
    800042f0:	0800                	addi	s0,sp,16
  return fork();
    800042f2:	ffffe097          	auipc	ra,0xffffe
    800042f6:	094080e7          	jalr	148(ra) # 80002386 <fork>
}
    800042fa:	60a2                	ld	ra,8(sp)
    800042fc:	6402                	ld	s0,0(sp)
    800042fe:	0141                	addi	sp,sp,16
    80004300:	8082                	ret

0000000080004302 <sys_wait>:

uint64
sys_wait(void)
{
    80004302:	1101                	addi	sp,sp,-32
    80004304:	ec06                	sd	ra,24(sp)
    80004306:	e822                	sd	s0,16(sp)
    80004308:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000430a:	fe840593          	addi	a1,s0,-24
    8000430e:	4501                	li	a0,0
    80004310:	00000097          	auipc	ra,0x0
    80004314:	ece080e7          	jalr	-306(ra) # 800041de <argaddr>
    80004318:	87aa                	mv	a5,a0
    return -1;
    8000431a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000431c:	0007c863          	bltz	a5,8000432c <sys_wait+0x2a>
  return wait(p);
    80004320:	fe843503          	ld	a0,-24(s0)
    80004324:	fffff097          	auipc	ra,0xfffff
    80004328:	c8a080e7          	jalr	-886(ra) # 80002fae <wait>
}
    8000432c:	60e2                	ld	ra,24(sp)
    8000432e:	6442                	ld	s0,16(sp)
    80004330:	6105                	addi	sp,sp,32
    80004332:	8082                	ret

0000000080004334 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80004334:	7179                	addi	sp,sp,-48
    80004336:	f406                	sd	ra,40(sp)
    80004338:	f022                	sd	s0,32(sp)
    8000433a:	ec26                	sd	s1,24(sp)
    8000433c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000433e:	fdc40593          	addi	a1,s0,-36
    80004342:	4501                	li	a0,0
    80004344:	00000097          	auipc	ra,0x0
    80004348:	e78080e7          	jalr	-392(ra) # 800041bc <argint>
    8000434c:	87aa                	mv	a5,a0
    return -1;
    8000434e:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80004350:	0207c063          	bltz	a5,80004370 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80004354:	ffffe097          	auipc	ra,0xffffe
    80004358:	870080e7          	jalr	-1936(ra) # 80001bc4 <myproc>
    8000435c:	5d24                	lw	s1,120(a0)
  if(growproc(n) < 0)
    8000435e:	fdc42503          	lw	a0,-36(s0)
    80004362:	ffffe097          	auipc	ra,0xffffe
    80004366:	fb0080e7          	jalr	-80(ra) # 80002312 <growproc>
    8000436a:	00054863          	bltz	a0,8000437a <sys_sbrk+0x46>
    return -1;
  return addr;
    8000436e:	8526                	mv	a0,s1
}
    80004370:	70a2                	ld	ra,40(sp)
    80004372:	7402                	ld	s0,32(sp)
    80004374:	64e2                	ld	s1,24(sp)
    80004376:	6145                	addi	sp,sp,48
    80004378:	8082                	ret
    return -1;
    8000437a:	557d                	li	a0,-1
    8000437c:	bfd5                	j	80004370 <sys_sbrk+0x3c>

000000008000437e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000437e:	7139                	addi	sp,sp,-64
    80004380:	fc06                	sd	ra,56(sp)
    80004382:	f822                	sd	s0,48(sp)
    80004384:	f426                	sd	s1,40(sp)
    80004386:	f04a                	sd	s2,32(sp)
    80004388:	ec4e                	sd	s3,24(sp)
    8000438a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000438c:	fcc40593          	addi	a1,s0,-52
    80004390:	4501                	li	a0,0
    80004392:	00000097          	auipc	ra,0x0
    80004396:	e2a080e7          	jalr	-470(ra) # 800041bc <argint>
    return -1;
    8000439a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000439c:	06054563          	bltz	a0,80004406 <sys_sleep+0x88>
  acquire(&tickslock);
    800043a0:	00015517          	auipc	a0,0x15
    800043a4:	9d050513          	addi	a0,a0,-1584 # 80018d70 <tickslock>
    800043a8:	ffffd097          	auipc	ra,0xffffd
    800043ac:	83c080e7          	jalr	-1988(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800043b0:	00006917          	auipc	s2,0x6
    800043b4:	ca492903          	lw	s2,-860(s2) # 8000a054 <ticks>
  
  while(ticks - ticks0 < n){
    800043b8:	fcc42783          	lw	a5,-52(s0)
    800043bc:	cf85                	beqz	a5,800043f4 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800043be:	00015997          	auipc	s3,0x15
    800043c2:	9b298993          	addi	s3,s3,-1614 # 80018d70 <tickslock>
    800043c6:	00006497          	auipc	s1,0x6
    800043ca:	c8e48493          	addi	s1,s1,-882 # 8000a054 <ticks>
    if(myproc()->killed){
    800043ce:	ffffd097          	auipc	ra,0xffffd
    800043d2:	7f6080e7          	jalr	2038(ra) # 80001bc4 <myproc>
    800043d6:	551c                	lw	a5,40(a0)
    800043d8:	ef9d                	bnez	a5,80004416 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800043da:	85ce                	mv	a1,s3
    800043dc:	8526                	mv	a0,s1
    800043de:	fffff097          	auipc	ra,0xfffff
    800043e2:	944080e7          	jalr	-1724(ra) # 80002d22 <sleep>
  while(ticks - ticks0 < n){
    800043e6:	409c                	lw	a5,0(s1)
    800043e8:	412787bb          	subw	a5,a5,s2
    800043ec:	fcc42703          	lw	a4,-52(s0)
    800043f0:	fce7efe3          	bltu	a5,a4,800043ce <sys_sleep+0x50>
  }
  release(&tickslock);
    800043f4:	00015517          	auipc	a0,0x15
    800043f8:	97c50513          	addi	a0,a0,-1668 # 80018d70 <tickslock>
    800043fc:	ffffd097          	auipc	ra,0xffffd
    80004400:	89c080e7          	jalr	-1892(ra) # 80000c98 <release>
  return 0;
    80004404:	4781                	li	a5,0
}
    80004406:	853e                	mv	a0,a5
    80004408:	70e2                	ld	ra,56(sp)
    8000440a:	7442                	ld	s0,48(sp)
    8000440c:	74a2                	ld	s1,40(sp)
    8000440e:	7902                	ld	s2,32(sp)
    80004410:	69e2                	ld	s3,24(sp)
    80004412:	6121                	addi	sp,sp,64
    80004414:	8082                	ret
      release(&tickslock);
    80004416:	00015517          	auipc	a0,0x15
    8000441a:	95a50513          	addi	a0,a0,-1702 # 80018d70 <tickslock>
    8000441e:	ffffd097          	auipc	ra,0xffffd
    80004422:	87a080e7          	jalr	-1926(ra) # 80000c98 <release>
      return -1;
    80004426:	57fd                	li	a5,-1
    80004428:	bff9                	j	80004406 <sys_sleep+0x88>

000000008000442a <sys_kill>:

uint64
sys_kill(void)
{
    8000442a:	1101                	addi	sp,sp,-32
    8000442c:	ec06                	sd	ra,24(sp)
    8000442e:	e822                	sd	s0,16(sp)
    80004430:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80004432:	fec40593          	addi	a1,s0,-20
    80004436:	4501                	li	a0,0
    80004438:	00000097          	auipc	ra,0x0
    8000443c:	d84080e7          	jalr	-636(ra) # 800041bc <argint>
    80004440:	87aa                	mv	a5,a0
    return -1;
    80004442:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80004444:	0007c863          	bltz	a5,80004454 <sys_kill+0x2a>
  return kill(pid);
    80004448:	fec42503          	lw	a0,-20(s0)
    8000444c:	fffff097          	auipc	ra,0xfffff
    80004450:	2f4080e7          	jalr	756(ra) # 80003740 <kill>
}
    80004454:	60e2                	ld	ra,24(sp)
    80004456:	6442                	ld	s0,16(sp)
    80004458:	6105                	addi	sp,sp,32
    8000445a:	8082                	ret

000000008000445c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000445c:	1101                	addi	sp,sp,-32
    8000445e:	ec06                	sd	ra,24(sp)
    80004460:	e822                	sd	s0,16(sp)
    80004462:	e426                	sd	s1,8(sp)
    80004464:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80004466:	00015517          	auipc	a0,0x15
    8000446a:	90a50513          	addi	a0,a0,-1782 # 80018d70 <tickslock>
    8000446e:	ffffc097          	auipc	ra,0xffffc
    80004472:	776080e7          	jalr	1910(ra) # 80000be4 <acquire>
  xticks = ticks;
    80004476:	00006497          	auipc	s1,0x6
    8000447a:	bde4a483          	lw	s1,-1058(s1) # 8000a054 <ticks>
  release(&tickslock);
    8000447e:	00015517          	auipc	a0,0x15
    80004482:	8f250513          	addi	a0,a0,-1806 # 80018d70 <tickslock>
    80004486:	ffffd097          	auipc	ra,0xffffd
    8000448a:	812080e7          	jalr	-2030(ra) # 80000c98 <release>
  return xticks;
}
    8000448e:	02049513          	slli	a0,s1,0x20
    80004492:	9101                	srli	a0,a0,0x20
    80004494:	60e2                	ld	ra,24(sp)
    80004496:	6442                	ld	s0,16(sp)
    80004498:	64a2                	ld	s1,8(sp)
    8000449a:	6105                	addi	sp,sp,32
    8000449c:	8082                	ret

000000008000449e <sys_print_stats>:

uint64
sys_print_stats(void)
{
    8000449e:	1141                	addi	sp,sp,-16
    800044a0:	e406                	sd	ra,8(sp)
    800044a2:	e022                	sd	s0,0(sp)
    800044a4:	0800                	addi	s0,sp,16
  return print_stats();
    800044a6:	fffff097          	auipc	ra,0xfffff
    800044aa:	320080e7          	jalr	800(ra) # 800037c6 <print_stats>
}
    800044ae:	60a2                	ld	ra,8(sp)
    800044b0:	6402                	ld	s0,0(sp)
    800044b2:	0141                	addi	sp,sp,16
    800044b4:	8082                	ret

00000000800044b6 <sys_get_cpu>:

// Ass2
uint64
sys_get_cpu(void)
{
    800044b6:	1141                	addi	sp,sp,-16
    800044b8:	e406                	sd	ra,8(sp)
    800044ba:	e022                	sd	s0,0(sp)
    800044bc:	0800                	addi	s0,sp,16
  return get_cpu();
    800044be:	fffff097          	auipc	ra,0xfffff
    800044c2:	46a080e7          	jalr	1130(ra) # 80003928 <get_cpu>
}
    800044c6:	60a2                	ld	ra,8(sp)
    800044c8:	6402                	ld	s0,0(sp)
    800044ca:	0141                	addi	sp,sp,16
    800044cc:	8082                	ret

00000000800044ce <sys_set_cpu>:

// Ass2
uint64
sys_set_cpu(void)
{
    800044ce:	1101                	addi	sp,sp,-32
    800044d0:	ec06                	sd	ra,24(sp)
    800044d2:	e822                	sd	s0,16(sp)
    800044d4:	1000                	addi	s0,sp,32
  int cpu_num;
  if(argint(0, &cpu_num) < 0)
    800044d6:	fec40593          	addi	a1,s0,-20
    800044da:	4501                	li	a0,0
    800044dc:	00000097          	auipc	ra,0x0
    800044e0:	ce0080e7          	jalr	-800(ra) # 800041bc <argint>
    800044e4:	87aa                	mv	a5,a0
    return -1;
    800044e6:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    800044e8:	0007c863          	bltz	a5,800044f8 <sys_set_cpu+0x2a>

  return set_cpu(cpu_num);
    800044ec:	fec42503          	lw	a0,-20(s0)
    800044f0:	fffff097          	auipc	ra,0xfffff
    800044f4:	378080e7          	jalr	888(ra) # 80003868 <set_cpu>
}
    800044f8:	60e2                	ld	ra,24(sp)
    800044fa:	6442                	ld	s0,16(sp)
    800044fc:	6105                	addi	sp,sp,32
    800044fe:	8082                	ret

0000000080004500 <sys_pause_system>:



uint64
sys_pause_system(void)
{
    80004500:	1101                	addi	sp,sp,-32
    80004502:	ec06                	sd	ra,24(sp)
    80004504:	e822                	sd	s0,16(sp)
    80004506:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    80004508:	fec40593          	addi	a1,s0,-20
    8000450c:	4501                	li	a0,0
    8000450e:	00000097          	auipc	ra,0x0
    80004512:	cae080e7          	jalr	-850(ra) # 800041bc <argint>
    80004516:	87aa                	mv	a5,a0
    return -1;
    80004518:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    8000451a:	0007c863          	bltz	a5,8000452a <sys_pause_system+0x2a>

  return pause_system(seconds);
    8000451e:	fec42503          	lw	a0,-20(s0)
    80004522:	fffff097          	auipc	ra,0xfffff
    80004526:	416080e7          	jalr	1046(ra) # 80003938 <pause_system>
}
    8000452a:	60e2                	ld	ra,24(sp)
    8000452c:	6442                	ld	s0,16(sp)
    8000452e:	6105                	addi	sp,sp,32
    80004530:	8082                	ret

0000000080004532 <sys_kill_system>:


uint64
sys_kill_system(void)
{
    80004532:	1141                	addi	sp,sp,-16
    80004534:	e406                	sd	ra,8(sp)
    80004536:	e022                	sd	s0,0(sp)
    80004538:	0800                	addi	s0,sp,16
  return kill_system(); 
    8000453a:	fffff097          	auipc	ra,0xfffff
    8000453e:	55e080e7          	jalr	1374(ra) # 80003a98 <kill_system>
}
    80004542:	60a2                	ld	ra,8(sp)
    80004544:	6402                	ld	s0,0(sp)
    80004546:	0141                	addi	sp,sp,16
    80004548:	8082                	ret

000000008000454a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000454a:	7179                	addi	sp,sp,-48
    8000454c:	f406                	sd	ra,40(sp)
    8000454e:	f022                	sd	s0,32(sp)
    80004550:	ec26                	sd	s1,24(sp)
    80004552:	e84a                	sd	s2,16(sp)
    80004554:	e44e                	sd	s3,8(sp)
    80004556:	e052                	sd	s4,0(sp)
    80004558:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000455a:	00005597          	auipc	a1,0x5
    8000455e:	42658593          	addi	a1,a1,1062 # 80009980 <syscalls+0xd8>
    80004562:	00015517          	auipc	a0,0x15
    80004566:	82650513          	addi	a0,a0,-2010 # 80018d88 <bcache>
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	5ea080e7          	jalr	1514(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80004572:	0001d797          	auipc	a5,0x1d
    80004576:	81678793          	addi	a5,a5,-2026 # 80020d88 <bcache+0x8000>
    8000457a:	0001d717          	auipc	a4,0x1d
    8000457e:	a7670713          	addi	a4,a4,-1418 # 80020ff0 <bcache+0x8268>
    80004582:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80004586:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000458a:	00015497          	auipc	s1,0x15
    8000458e:	81648493          	addi	s1,s1,-2026 # 80018da0 <bcache+0x18>
    b->next = bcache.head.next;
    80004592:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80004594:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80004596:	00005a17          	auipc	s4,0x5
    8000459a:	3f2a0a13          	addi	s4,s4,1010 # 80009988 <syscalls+0xe0>
    b->next = bcache.head.next;
    8000459e:	2b893783          	ld	a5,696(s2)
    800045a2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800045a4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800045a8:	85d2                	mv	a1,s4
    800045aa:	01048513          	addi	a0,s1,16
    800045ae:	00001097          	auipc	ra,0x1
    800045b2:	4bc080e7          	jalr	1212(ra) # 80005a6a <initsleeplock>
    bcache.head.next->prev = b;
    800045b6:	2b893783          	ld	a5,696(s2)
    800045ba:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800045bc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800045c0:	45848493          	addi	s1,s1,1112
    800045c4:	fd349de3          	bne	s1,s3,8000459e <binit+0x54>
  }
}
    800045c8:	70a2                	ld	ra,40(sp)
    800045ca:	7402                	ld	s0,32(sp)
    800045cc:	64e2                	ld	s1,24(sp)
    800045ce:	6942                	ld	s2,16(sp)
    800045d0:	69a2                	ld	s3,8(sp)
    800045d2:	6a02                	ld	s4,0(sp)
    800045d4:	6145                	addi	sp,sp,48
    800045d6:	8082                	ret

00000000800045d8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800045d8:	7179                	addi	sp,sp,-48
    800045da:	f406                	sd	ra,40(sp)
    800045dc:	f022                	sd	s0,32(sp)
    800045de:	ec26                	sd	s1,24(sp)
    800045e0:	e84a                	sd	s2,16(sp)
    800045e2:	e44e                	sd	s3,8(sp)
    800045e4:	1800                	addi	s0,sp,48
    800045e6:	89aa                	mv	s3,a0
    800045e8:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800045ea:	00014517          	auipc	a0,0x14
    800045ee:	79e50513          	addi	a0,a0,1950 # 80018d88 <bcache>
    800045f2:	ffffc097          	auipc	ra,0xffffc
    800045f6:	5f2080e7          	jalr	1522(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800045fa:	0001d497          	auipc	s1,0x1d
    800045fe:	a464b483          	ld	s1,-1466(s1) # 80021040 <bcache+0x82b8>
    80004602:	0001d797          	auipc	a5,0x1d
    80004606:	9ee78793          	addi	a5,a5,-1554 # 80020ff0 <bcache+0x8268>
    8000460a:	02f48f63          	beq	s1,a5,80004648 <bread+0x70>
    8000460e:	873e                	mv	a4,a5
    80004610:	a021                	j	80004618 <bread+0x40>
    80004612:	68a4                	ld	s1,80(s1)
    80004614:	02e48a63          	beq	s1,a4,80004648 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80004618:	449c                	lw	a5,8(s1)
    8000461a:	ff379ce3          	bne	a5,s3,80004612 <bread+0x3a>
    8000461e:	44dc                	lw	a5,12(s1)
    80004620:	ff2799e3          	bne	a5,s2,80004612 <bread+0x3a>
      b->refcnt++;
    80004624:	40bc                	lw	a5,64(s1)
    80004626:	2785                	addiw	a5,a5,1
    80004628:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000462a:	00014517          	auipc	a0,0x14
    8000462e:	75e50513          	addi	a0,a0,1886 # 80018d88 <bcache>
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	666080e7          	jalr	1638(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000463a:	01048513          	addi	a0,s1,16
    8000463e:	00001097          	auipc	ra,0x1
    80004642:	466080e7          	jalr	1126(ra) # 80005aa4 <acquiresleep>
      return b;
    80004646:	a8b9                	j	800046a4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80004648:	0001d497          	auipc	s1,0x1d
    8000464c:	9f04b483          	ld	s1,-1552(s1) # 80021038 <bcache+0x82b0>
    80004650:	0001d797          	auipc	a5,0x1d
    80004654:	9a078793          	addi	a5,a5,-1632 # 80020ff0 <bcache+0x8268>
    80004658:	00f48863          	beq	s1,a5,80004668 <bread+0x90>
    8000465c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000465e:	40bc                	lw	a5,64(s1)
    80004660:	cf81                	beqz	a5,80004678 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80004662:	64a4                	ld	s1,72(s1)
    80004664:	fee49de3          	bne	s1,a4,8000465e <bread+0x86>
  panic("bget: no buffers");
    80004668:	00005517          	auipc	a0,0x5
    8000466c:	32850513          	addi	a0,a0,808 # 80009990 <syscalls+0xe8>
    80004670:	ffffc097          	auipc	ra,0xffffc
    80004674:	ece080e7          	jalr	-306(ra) # 8000053e <panic>
      b->dev = dev;
    80004678:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000467c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80004680:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80004684:	4785                	li	a5,1
    80004686:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80004688:	00014517          	auipc	a0,0x14
    8000468c:	70050513          	addi	a0,a0,1792 # 80018d88 <bcache>
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	608080e7          	jalr	1544(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80004698:	01048513          	addi	a0,s1,16
    8000469c:	00001097          	auipc	ra,0x1
    800046a0:	408080e7          	jalr	1032(ra) # 80005aa4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800046a4:	409c                	lw	a5,0(s1)
    800046a6:	cb89                	beqz	a5,800046b8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800046a8:	8526                	mv	a0,s1
    800046aa:	70a2                	ld	ra,40(sp)
    800046ac:	7402                	ld	s0,32(sp)
    800046ae:	64e2                	ld	s1,24(sp)
    800046b0:	6942                	ld	s2,16(sp)
    800046b2:	69a2                	ld	s3,8(sp)
    800046b4:	6145                	addi	sp,sp,48
    800046b6:	8082                	ret
    virtio_disk_rw(b, 0);
    800046b8:	4581                	li	a1,0
    800046ba:	8526                	mv	a0,s1
    800046bc:	00003097          	auipc	ra,0x3
    800046c0:	f1a080e7          	jalr	-230(ra) # 800075d6 <virtio_disk_rw>
    b->valid = 1;
    800046c4:	4785                	li	a5,1
    800046c6:	c09c                	sw	a5,0(s1)
  return b;
    800046c8:	b7c5                	j	800046a8 <bread+0xd0>

00000000800046ca <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800046ca:	1101                	addi	sp,sp,-32
    800046cc:	ec06                	sd	ra,24(sp)
    800046ce:	e822                	sd	s0,16(sp)
    800046d0:	e426                	sd	s1,8(sp)
    800046d2:	1000                	addi	s0,sp,32
    800046d4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800046d6:	0541                	addi	a0,a0,16
    800046d8:	00001097          	auipc	ra,0x1
    800046dc:	466080e7          	jalr	1126(ra) # 80005b3e <holdingsleep>
    800046e0:	cd01                	beqz	a0,800046f8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800046e2:	4585                	li	a1,1
    800046e4:	8526                	mv	a0,s1
    800046e6:	00003097          	auipc	ra,0x3
    800046ea:	ef0080e7          	jalr	-272(ra) # 800075d6 <virtio_disk_rw>
}
    800046ee:	60e2                	ld	ra,24(sp)
    800046f0:	6442                	ld	s0,16(sp)
    800046f2:	64a2                	ld	s1,8(sp)
    800046f4:	6105                	addi	sp,sp,32
    800046f6:	8082                	ret
    panic("bwrite");
    800046f8:	00005517          	auipc	a0,0x5
    800046fc:	2b050513          	addi	a0,a0,688 # 800099a8 <syscalls+0x100>
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	e3e080e7          	jalr	-450(ra) # 8000053e <panic>

0000000080004708 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80004708:	1101                	addi	sp,sp,-32
    8000470a:	ec06                	sd	ra,24(sp)
    8000470c:	e822                	sd	s0,16(sp)
    8000470e:	e426                	sd	s1,8(sp)
    80004710:	e04a                	sd	s2,0(sp)
    80004712:	1000                	addi	s0,sp,32
    80004714:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80004716:	01050913          	addi	s2,a0,16
    8000471a:	854a                	mv	a0,s2
    8000471c:	00001097          	auipc	ra,0x1
    80004720:	422080e7          	jalr	1058(ra) # 80005b3e <holdingsleep>
    80004724:	c92d                	beqz	a0,80004796 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80004726:	854a                	mv	a0,s2
    80004728:	00001097          	auipc	ra,0x1
    8000472c:	3d2080e7          	jalr	978(ra) # 80005afa <releasesleep>

  acquire(&bcache.lock);
    80004730:	00014517          	auipc	a0,0x14
    80004734:	65850513          	addi	a0,a0,1624 # 80018d88 <bcache>
    80004738:	ffffc097          	auipc	ra,0xffffc
    8000473c:	4ac080e7          	jalr	1196(ra) # 80000be4 <acquire>
  b->refcnt--;
    80004740:	40bc                	lw	a5,64(s1)
    80004742:	37fd                	addiw	a5,a5,-1
    80004744:	0007871b          	sext.w	a4,a5
    80004748:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000474a:	eb05                	bnez	a4,8000477a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000474c:	68bc                	ld	a5,80(s1)
    8000474e:	64b8                	ld	a4,72(s1)
    80004750:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80004752:	64bc                	ld	a5,72(s1)
    80004754:	68b8                	ld	a4,80(s1)
    80004756:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80004758:	0001c797          	auipc	a5,0x1c
    8000475c:	63078793          	addi	a5,a5,1584 # 80020d88 <bcache+0x8000>
    80004760:	2b87b703          	ld	a4,696(a5)
    80004764:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80004766:	0001d717          	auipc	a4,0x1d
    8000476a:	88a70713          	addi	a4,a4,-1910 # 80020ff0 <bcache+0x8268>
    8000476e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80004770:	2b87b703          	ld	a4,696(a5)
    80004774:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80004776:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000477a:	00014517          	auipc	a0,0x14
    8000477e:	60e50513          	addi	a0,a0,1550 # 80018d88 <bcache>
    80004782:	ffffc097          	auipc	ra,0xffffc
    80004786:	516080e7          	jalr	1302(ra) # 80000c98 <release>
}
    8000478a:	60e2                	ld	ra,24(sp)
    8000478c:	6442                	ld	s0,16(sp)
    8000478e:	64a2                	ld	s1,8(sp)
    80004790:	6902                	ld	s2,0(sp)
    80004792:	6105                	addi	sp,sp,32
    80004794:	8082                	ret
    panic("brelse");
    80004796:	00005517          	auipc	a0,0x5
    8000479a:	21a50513          	addi	a0,a0,538 # 800099b0 <syscalls+0x108>
    8000479e:	ffffc097          	auipc	ra,0xffffc
    800047a2:	da0080e7          	jalr	-608(ra) # 8000053e <panic>

00000000800047a6 <bpin>:

void
bpin(struct buf *b) {
    800047a6:	1101                	addi	sp,sp,-32
    800047a8:	ec06                	sd	ra,24(sp)
    800047aa:	e822                	sd	s0,16(sp)
    800047ac:	e426                	sd	s1,8(sp)
    800047ae:	1000                	addi	s0,sp,32
    800047b0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800047b2:	00014517          	auipc	a0,0x14
    800047b6:	5d650513          	addi	a0,a0,1494 # 80018d88 <bcache>
    800047ba:	ffffc097          	auipc	ra,0xffffc
    800047be:	42a080e7          	jalr	1066(ra) # 80000be4 <acquire>
  b->refcnt++;
    800047c2:	40bc                	lw	a5,64(s1)
    800047c4:	2785                	addiw	a5,a5,1
    800047c6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800047c8:	00014517          	auipc	a0,0x14
    800047cc:	5c050513          	addi	a0,a0,1472 # 80018d88 <bcache>
    800047d0:	ffffc097          	auipc	ra,0xffffc
    800047d4:	4c8080e7          	jalr	1224(ra) # 80000c98 <release>
}
    800047d8:	60e2                	ld	ra,24(sp)
    800047da:	6442                	ld	s0,16(sp)
    800047dc:	64a2                	ld	s1,8(sp)
    800047de:	6105                	addi	sp,sp,32
    800047e0:	8082                	ret

00000000800047e2 <bunpin>:

void
bunpin(struct buf *b) {
    800047e2:	1101                	addi	sp,sp,-32
    800047e4:	ec06                	sd	ra,24(sp)
    800047e6:	e822                	sd	s0,16(sp)
    800047e8:	e426                	sd	s1,8(sp)
    800047ea:	1000                	addi	s0,sp,32
    800047ec:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800047ee:	00014517          	auipc	a0,0x14
    800047f2:	59a50513          	addi	a0,a0,1434 # 80018d88 <bcache>
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	3ee080e7          	jalr	1006(ra) # 80000be4 <acquire>
  b->refcnt--;
    800047fe:	40bc                	lw	a5,64(s1)
    80004800:	37fd                	addiw	a5,a5,-1
    80004802:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80004804:	00014517          	auipc	a0,0x14
    80004808:	58450513          	addi	a0,a0,1412 # 80018d88 <bcache>
    8000480c:	ffffc097          	auipc	ra,0xffffc
    80004810:	48c080e7          	jalr	1164(ra) # 80000c98 <release>
}
    80004814:	60e2                	ld	ra,24(sp)
    80004816:	6442                	ld	s0,16(sp)
    80004818:	64a2                	ld	s1,8(sp)
    8000481a:	6105                	addi	sp,sp,32
    8000481c:	8082                	ret

000000008000481e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000481e:	1101                	addi	sp,sp,-32
    80004820:	ec06                	sd	ra,24(sp)
    80004822:	e822                	sd	s0,16(sp)
    80004824:	e426                	sd	s1,8(sp)
    80004826:	e04a                	sd	s2,0(sp)
    80004828:	1000                	addi	s0,sp,32
    8000482a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000482c:	00d5d59b          	srliw	a1,a1,0xd
    80004830:	0001d797          	auipc	a5,0x1d
    80004834:	c347a783          	lw	a5,-972(a5) # 80021464 <sb+0x1c>
    80004838:	9dbd                	addw	a1,a1,a5
    8000483a:	00000097          	auipc	ra,0x0
    8000483e:	d9e080e7          	jalr	-610(ra) # 800045d8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80004842:	0074f713          	andi	a4,s1,7
    80004846:	4785                	li	a5,1
    80004848:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000484c:	14ce                	slli	s1,s1,0x33
    8000484e:	90d9                	srli	s1,s1,0x36
    80004850:	00950733          	add	a4,a0,s1
    80004854:	05874703          	lbu	a4,88(a4)
    80004858:	00e7f6b3          	and	a3,a5,a4
    8000485c:	c69d                	beqz	a3,8000488a <bfree+0x6c>
    8000485e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80004860:	94aa                	add	s1,s1,a0
    80004862:	fff7c793          	not	a5,a5
    80004866:	8ff9                	and	a5,a5,a4
    80004868:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000486c:	00001097          	auipc	ra,0x1
    80004870:	118080e7          	jalr	280(ra) # 80005984 <log_write>
  brelse(bp);
    80004874:	854a                	mv	a0,s2
    80004876:	00000097          	auipc	ra,0x0
    8000487a:	e92080e7          	jalr	-366(ra) # 80004708 <brelse>
}
    8000487e:	60e2                	ld	ra,24(sp)
    80004880:	6442                	ld	s0,16(sp)
    80004882:	64a2                	ld	s1,8(sp)
    80004884:	6902                	ld	s2,0(sp)
    80004886:	6105                	addi	sp,sp,32
    80004888:	8082                	ret
    panic("freeing free block");
    8000488a:	00005517          	auipc	a0,0x5
    8000488e:	12e50513          	addi	a0,a0,302 # 800099b8 <syscalls+0x110>
    80004892:	ffffc097          	auipc	ra,0xffffc
    80004896:	cac080e7          	jalr	-852(ra) # 8000053e <panic>

000000008000489a <balloc>:
{
    8000489a:	711d                	addi	sp,sp,-96
    8000489c:	ec86                	sd	ra,88(sp)
    8000489e:	e8a2                	sd	s0,80(sp)
    800048a0:	e4a6                	sd	s1,72(sp)
    800048a2:	e0ca                	sd	s2,64(sp)
    800048a4:	fc4e                	sd	s3,56(sp)
    800048a6:	f852                	sd	s4,48(sp)
    800048a8:	f456                	sd	s5,40(sp)
    800048aa:	f05a                	sd	s6,32(sp)
    800048ac:	ec5e                	sd	s7,24(sp)
    800048ae:	e862                	sd	s8,16(sp)
    800048b0:	e466                	sd	s9,8(sp)
    800048b2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800048b4:	0001d797          	auipc	a5,0x1d
    800048b8:	b987a783          	lw	a5,-1128(a5) # 8002144c <sb+0x4>
    800048bc:	cbd1                	beqz	a5,80004950 <balloc+0xb6>
    800048be:	8baa                	mv	s7,a0
    800048c0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800048c2:	0001db17          	auipc	s6,0x1d
    800048c6:	b86b0b13          	addi	s6,s6,-1146 # 80021448 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800048ca:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800048cc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800048ce:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800048d0:	6c89                	lui	s9,0x2
    800048d2:	a831                	j	800048ee <balloc+0x54>
    brelse(bp);
    800048d4:	854a                	mv	a0,s2
    800048d6:	00000097          	auipc	ra,0x0
    800048da:	e32080e7          	jalr	-462(ra) # 80004708 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800048de:	015c87bb          	addw	a5,s9,s5
    800048e2:	00078a9b          	sext.w	s5,a5
    800048e6:	004b2703          	lw	a4,4(s6)
    800048ea:	06eaf363          	bgeu	s5,a4,80004950 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800048ee:	41fad79b          	sraiw	a5,s5,0x1f
    800048f2:	0137d79b          	srliw	a5,a5,0x13
    800048f6:	015787bb          	addw	a5,a5,s5
    800048fa:	40d7d79b          	sraiw	a5,a5,0xd
    800048fe:	01cb2583          	lw	a1,28(s6)
    80004902:	9dbd                	addw	a1,a1,a5
    80004904:	855e                	mv	a0,s7
    80004906:	00000097          	auipc	ra,0x0
    8000490a:	cd2080e7          	jalr	-814(ra) # 800045d8 <bread>
    8000490e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004910:	004b2503          	lw	a0,4(s6)
    80004914:	000a849b          	sext.w	s1,s5
    80004918:	8662                	mv	a2,s8
    8000491a:	faa4fde3          	bgeu	s1,a0,800048d4 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000491e:	41f6579b          	sraiw	a5,a2,0x1f
    80004922:	01d7d69b          	srliw	a3,a5,0x1d
    80004926:	00c6873b          	addw	a4,a3,a2
    8000492a:	00777793          	andi	a5,a4,7
    8000492e:	9f95                	subw	a5,a5,a3
    80004930:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80004934:	4037571b          	sraiw	a4,a4,0x3
    80004938:	00e906b3          	add	a3,s2,a4
    8000493c:	0586c683          	lbu	a3,88(a3)
    80004940:	00d7f5b3          	and	a1,a5,a3
    80004944:	cd91                	beqz	a1,80004960 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004946:	2605                	addiw	a2,a2,1
    80004948:	2485                	addiw	s1,s1,1
    8000494a:	fd4618e3          	bne	a2,s4,8000491a <balloc+0x80>
    8000494e:	b759                	j	800048d4 <balloc+0x3a>
  panic("balloc: out of blocks");
    80004950:	00005517          	auipc	a0,0x5
    80004954:	08050513          	addi	a0,a0,128 # 800099d0 <syscalls+0x128>
    80004958:	ffffc097          	auipc	ra,0xffffc
    8000495c:	be6080e7          	jalr	-1050(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80004960:	974a                	add	a4,a4,s2
    80004962:	8fd5                	or	a5,a5,a3
    80004964:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80004968:	854a                	mv	a0,s2
    8000496a:	00001097          	auipc	ra,0x1
    8000496e:	01a080e7          	jalr	26(ra) # 80005984 <log_write>
        brelse(bp);
    80004972:	854a                	mv	a0,s2
    80004974:	00000097          	auipc	ra,0x0
    80004978:	d94080e7          	jalr	-620(ra) # 80004708 <brelse>
  bp = bread(dev, bno);
    8000497c:	85a6                	mv	a1,s1
    8000497e:	855e                	mv	a0,s7
    80004980:	00000097          	auipc	ra,0x0
    80004984:	c58080e7          	jalr	-936(ra) # 800045d8 <bread>
    80004988:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000498a:	40000613          	li	a2,1024
    8000498e:	4581                	li	a1,0
    80004990:	05850513          	addi	a0,a0,88
    80004994:	ffffc097          	auipc	ra,0xffffc
    80004998:	34c080e7          	jalr	844(ra) # 80000ce0 <memset>
  log_write(bp);
    8000499c:	854a                	mv	a0,s2
    8000499e:	00001097          	auipc	ra,0x1
    800049a2:	fe6080e7          	jalr	-26(ra) # 80005984 <log_write>
  brelse(bp);
    800049a6:	854a                	mv	a0,s2
    800049a8:	00000097          	auipc	ra,0x0
    800049ac:	d60080e7          	jalr	-672(ra) # 80004708 <brelse>
}
    800049b0:	8526                	mv	a0,s1
    800049b2:	60e6                	ld	ra,88(sp)
    800049b4:	6446                	ld	s0,80(sp)
    800049b6:	64a6                	ld	s1,72(sp)
    800049b8:	6906                	ld	s2,64(sp)
    800049ba:	79e2                	ld	s3,56(sp)
    800049bc:	7a42                	ld	s4,48(sp)
    800049be:	7aa2                	ld	s5,40(sp)
    800049c0:	7b02                	ld	s6,32(sp)
    800049c2:	6be2                	ld	s7,24(sp)
    800049c4:	6c42                	ld	s8,16(sp)
    800049c6:	6ca2                	ld	s9,8(sp)
    800049c8:	6125                	addi	sp,sp,96
    800049ca:	8082                	ret

00000000800049cc <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800049cc:	7179                	addi	sp,sp,-48
    800049ce:	f406                	sd	ra,40(sp)
    800049d0:	f022                	sd	s0,32(sp)
    800049d2:	ec26                	sd	s1,24(sp)
    800049d4:	e84a                	sd	s2,16(sp)
    800049d6:	e44e                	sd	s3,8(sp)
    800049d8:	e052                	sd	s4,0(sp)
    800049da:	1800                	addi	s0,sp,48
    800049dc:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800049de:	47ad                	li	a5,11
    800049e0:	04b7fe63          	bgeu	a5,a1,80004a3c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800049e4:	ff45849b          	addiw	s1,a1,-12
    800049e8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800049ec:	0ff00793          	li	a5,255
    800049f0:	0ae7e363          	bltu	a5,a4,80004a96 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800049f4:	08052583          	lw	a1,128(a0)
    800049f8:	c5ad                	beqz	a1,80004a62 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800049fa:	00092503          	lw	a0,0(s2)
    800049fe:	00000097          	auipc	ra,0x0
    80004a02:	bda080e7          	jalr	-1062(ra) # 800045d8 <bread>
    80004a06:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80004a08:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80004a0c:	02049593          	slli	a1,s1,0x20
    80004a10:	9181                	srli	a1,a1,0x20
    80004a12:	058a                	slli	a1,a1,0x2
    80004a14:	00b784b3          	add	s1,a5,a1
    80004a18:	0004a983          	lw	s3,0(s1)
    80004a1c:	04098d63          	beqz	s3,80004a76 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80004a20:	8552                	mv	a0,s4
    80004a22:	00000097          	auipc	ra,0x0
    80004a26:	ce6080e7          	jalr	-794(ra) # 80004708 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80004a2a:	854e                	mv	a0,s3
    80004a2c:	70a2                	ld	ra,40(sp)
    80004a2e:	7402                	ld	s0,32(sp)
    80004a30:	64e2                	ld	s1,24(sp)
    80004a32:	6942                	ld	s2,16(sp)
    80004a34:	69a2                	ld	s3,8(sp)
    80004a36:	6a02                	ld	s4,0(sp)
    80004a38:	6145                	addi	sp,sp,48
    80004a3a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80004a3c:	02059493          	slli	s1,a1,0x20
    80004a40:	9081                	srli	s1,s1,0x20
    80004a42:	048a                	slli	s1,s1,0x2
    80004a44:	94aa                	add	s1,s1,a0
    80004a46:	0504a983          	lw	s3,80(s1)
    80004a4a:	fe0990e3          	bnez	s3,80004a2a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80004a4e:	4108                	lw	a0,0(a0)
    80004a50:	00000097          	auipc	ra,0x0
    80004a54:	e4a080e7          	jalr	-438(ra) # 8000489a <balloc>
    80004a58:	0005099b          	sext.w	s3,a0
    80004a5c:	0534a823          	sw	s3,80(s1)
    80004a60:	b7e9                	j	80004a2a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80004a62:	4108                	lw	a0,0(a0)
    80004a64:	00000097          	auipc	ra,0x0
    80004a68:	e36080e7          	jalr	-458(ra) # 8000489a <balloc>
    80004a6c:	0005059b          	sext.w	a1,a0
    80004a70:	08b92023          	sw	a1,128(s2)
    80004a74:	b759                	j	800049fa <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80004a76:	00092503          	lw	a0,0(s2)
    80004a7a:	00000097          	auipc	ra,0x0
    80004a7e:	e20080e7          	jalr	-480(ra) # 8000489a <balloc>
    80004a82:	0005099b          	sext.w	s3,a0
    80004a86:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80004a8a:	8552                	mv	a0,s4
    80004a8c:	00001097          	auipc	ra,0x1
    80004a90:	ef8080e7          	jalr	-264(ra) # 80005984 <log_write>
    80004a94:	b771                	j	80004a20 <bmap+0x54>
  panic("bmap: out of range");
    80004a96:	00005517          	auipc	a0,0x5
    80004a9a:	f5250513          	addi	a0,a0,-174 # 800099e8 <syscalls+0x140>
    80004a9e:	ffffc097          	auipc	ra,0xffffc
    80004aa2:	aa0080e7          	jalr	-1376(ra) # 8000053e <panic>

0000000080004aa6 <iget>:
{
    80004aa6:	7179                	addi	sp,sp,-48
    80004aa8:	f406                	sd	ra,40(sp)
    80004aaa:	f022                	sd	s0,32(sp)
    80004aac:	ec26                	sd	s1,24(sp)
    80004aae:	e84a                	sd	s2,16(sp)
    80004ab0:	e44e                	sd	s3,8(sp)
    80004ab2:	e052                	sd	s4,0(sp)
    80004ab4:	1800                	addi	s0,sp,48
    80004ab6:	89aa                	mv	s3,a0
    80004ab8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80004aba:	0001d517          	auipc	a0,0x1d
    80004abe:	9ae50513          	addi	a0,a0,-1618 # 80021468 <itable>
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	122080e7          	jalr	290(ra) # 80000be4 <acquire>
  empty = 0;
    80004aca:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004acc:	0001d497          	auipc	s1,0x1d
    80004ad0:	9b448493          	addi	s1,s1,-1612 # 80021480 <itable+0x18>
    80004ad4:	0001e697          	auipc	a3,0x1e
    80004ad8:	43c68693          	addi	a3,a3,1084 # 80022f10 <log>
    80004adc:	a039                	j	80004aea <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004ade:	02090b63          	beqz	s2,80004b14 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004ae2:	08848493          	addi	s1,s1,136
    80004ae6:	02d48a63          	beq	s1,a3,80004b1a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80004aea:	449c                	lw	a5,8(s1)
    80004aec:	fef059e3          	blez	a5,80004ade <iget+0x38>
    80004af0:	4098                	lw	a4,0(s1)
    80004af2:	ff3716e3          	bne	a4,s3,80004ade <iget+0x38>
    80004af6:	40d8                	lw	a4,4(s1)
    80004af8:	ff4713e3          	bne	a4,s4,80004ade <iget+0x38>
      ip->ref++;
    80004afc:	2785                	addiw	a5,a5,1
    80004afe:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80004b00:	0001d517          	auipc	a0,0x1d
    80004b04:	96850513          	addi	a0,a0,-1688 # 80021468 <itable>
    80004b08:	ffffc097          	auipc	ra,0xffffc
    80004b0c:	190080e7          	jalr	400(ra) # 80000c98 <release>
      return ip;
    80004b10:	8926                	mv	s2,s1
    80004b12:	a03d                	j	80004b40 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004b14:	f7f9                	bnez	a5,80004ae2 <iget+0x3c>
    80004b16:	8926                	mv	s2,s1
    80004b18:	b7e9                	j	80004ae2 <iget+0x3c>
  if(empty == 0)
    80004b1a:	02090c63          	beqz	s2,80004b52 <iget+0xac>
  ip->dev = dev;
    80004b1e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004b22:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80004b26:	4785                	li	a5,1
    80004b28:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80004b2c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80004b30:	0001d517          	auipc	a0,0x1d
    80004b34:	93850513          	addi	a0,a0,-1736 # 80021468 <itable>
    80004b38:	ffffc097          	auipc	ra,0xffffc
    80004b3c:	160080e7          	jalr	352(ra) # 80000c98 <release>
}
    80004b40:	854a                	mv	a0,s2
    80004b42:	70a2                	ld	ra,40(sp)
    80004b44:	7402                	ld	s0,32(sp)
    80004b46:	64e2                	ld	s1,24(sp)
    80004b48:	6942                	ld	s2,16(sp)
    80004b4a:	69a2                	ld	s3,8(sp)
    80004b4c:	6a02                	ld	s4,0(sp)
    80004b4e:	6145                	addi	sp,sp,48
    80004b50:	8082                	ret
    panic("iget: no inodes");
    80004b52:	00005517          	auipc	a0,0x5
    80004b56:	eae50513          	addi	a0,a0,-338 # 80009a00 <syscalls+0x158>
    80004b5a:	ffffc097          	auipc	ra,0xffffc
    80004b5e:	9e4080e7          	jalr	-1564(ra) # 8000053e <panic>

0000000080004b62 <fsinit>:
fsinit(int dev) {
    80004b62:	7179                	addi	sp,sp,-48
    80004b64:	f406                	sd	ra,40(sp)
    80004b66:	f022                	sd	s0,32(sp)
    80004b68:	ec26                	sd	s1,24(sp)
    80004b6a:	e84a                	sd	s2,16(sp)
    80004b6c:	e44e                	sd	s3,8(sp)
    80004b6e:	1800                	addi	s0,sp,48
    80004b70:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80004b72:	4585                	li	a1,1
    80004b74:	00000097          	auipc	ra,0x0
    80004b78:	a64080e7          	jalr	-1436(ra) # 800045d8 <bread>
    80004b7c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80004b7e:	0001d997          	auipc	s3,0x1d
    80004b82:	8ca98993          	addi	s3,s3,-1846 # 80021448 <sb>
    80004b86:	02000613          	li	a2,32
    80004b8a:	05850593          	addi	a1,a0,88
    80004b8e:	854e                	mv	a0,s3
    80004b90:	ffffc097          	auipc	ra,0xffffc
    80004b94:	1b0080e7          	jalr	432(ra) # 80000d40 <memmove>
  brelse(bp);
    80004b98:	8526                	mv	a0,s1
    80004b9a:	00000097          	auipc	ra,0x0
    80004b9e:	b6e080e7          	jalr	-1170(ra) # 80004708 <brelse>
  if(sb.magic != FSMAGIC)
    80004ba2:	0009a703          	lw	a4,0(s3)
    80004ba6:	102037b7          	lui	a5,0x10203
    80004baa:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80004bae:	02f71263          	bne	a4,a5,80004bd2 <fsinit+0x70>
  initlog(dev, &sb);
    80004bb2:	0001d597          	auipc	a1,0x1d
    80004bb6:	89658593          	addi	a1,a1,-1898 # 80021448 <sb>
    80004bba:	854a                	mv	a0,s2
    80004bbc:	00001097          	auipc	ra,0x1
    80004bc0:	b4c080e7          	jalr	-1204(ra) # 80005708 <initlog>
}
    80004bc4:	70a2                	ld	ra,40(sp)
    80004bc6:	7402                	ld	s0,32(sp)
    80004bc8:	64e2                	ld	s1,24(sp)
    80004bca:	6942                	ld	s2,16(sp)
    80004bcc:	69a2                	ld	s3,8(sp)
    80004bce:	6145                	addi	sp,sp,48
    80004bd0:	8082                	ret
    panic("invalid file system");
    80004bd2:	00005517          	auipc	a0,0x5
    80004bd6:	e3e50513          	addi	a0,a0,-450 # 80009a10 <syscalls+0x168>
    80004bda:	ffffc097          	auipc	ra,0xffffc
    80004bde:	964080e7          	jalr	-1692(ra) # 8000053e <panic>

0000000080004be2 <iinit>:
{
    80004be2:	7179                	addi	sp,sp,-48
    80004be4:	f406                	sd	ra,40(sp)
    80004be6:	f022                	sd	s0,32(sp)
    80004be8:	ec26                	sd	s1,24(sp)
    80004bea:	e84a                	sd	s2,16(sp)
    80004bec:	e44e                	sd	s3,8(sp)
    80004bee:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80004bf0:	00005597          	auipc	a1,0x5
    80004bf4:	e3858593          	addi	a1,a1,-456 # 80009a28 <syscalls+0x180>
    80004bf8:	0001d517          	auipc	a0,0x1d
    80004bfc:	87050513          	addi	a0,a0,-1936 # 80021468 <itable>
    80004c00:	ffffc097          	auipc	ra,0xffffc
    80004c04:	f54080e7          	jalr	-172(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80004c08:	0001d497          	auipc	s1,0x1d
    80004c0c:	88848493          	addi	s1,s1,-1912 # 80021490 <itable+0x28>
    80004c10:	0001e997          	auipc	s3,0x1e
    80004c14:	31098993          	addi	s3,s3,784 # 80022f20 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80004c18:	00005917          	auipc	s2,0x5
    80004c1c:	e1890913          	addi	s2,s2,-488 # 80009a30 <syscalls+0x188>
    80004c20:	85ca                	mv	a1,s2
    80004c22:	8526                	mv	a0,s1
    80004c24:	00001097          	auipc	ra,0x1
    80004c28:	e46080e7          	jalr	-442(ra) # 80005a6a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80004c2c:	08848493          	addi	s1,s1,136
    80004c30:	ff3498e3          	bne	s1,s3,80004c20 <iinit+0x3e>
}
    80004c34:	70a2                	ld	ra,40(sp)
    80004c36:	7402                	ld	s0,32(sp)
    80004c38:	64e2                	ld	s1,24(sp)
    80004c3a:	6942                	ld	s2,16(sp)
    80004c3c:	69a2                	ld	s3,8(sp)
    80004c3e:	6145                	addi	sp,sp,48
    80004c40:	8082                	ret

0000000080004c42 <ialloc>:
{
    80004c42:	715d                	addi	sp,sp,-80
    80004c44:	e486                	sd	ra,72(sp)
    80004c46:	e0a2                	sd	s0,64(sp)
    80004c48:	fc26                	sd	s1,56(sp)
    80004c4a:	f84a                	sd	s2,48(sp)
    80004c4c:	f44e                	sd	s3,40(sp)
    80004c4e:	f052                	sd	s4,32(sp)
    80004c50:	ec56                	sd	s5,24(sp)
    80004c52:	e85a                	sd	s6,16(sp)
    80004c54:	e45e                	sd	s7,8(sp)
    80004c56:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80004c58:	0001c717          	auipc	a4,0x1c
    80004c5c:	7fc72703          	lw	a4,2044(a4) # 80021454 <sb+0xc>
    80004c60:	4785                	li	a5,1
    80004c62:	04e7fa63          	bgeu	a5,a4,80004cb6 <ialloc+0x74>
    80004c66:	8aaa                	mv	s5,a0
    80004c68:	8bae                	mv	s7,a1
    80004c6a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004c6c:	0001ca17          	auipc	s4,0x1c
    80004c70:	7dca0a13          	addi	s4,s4,2012 # 80021448 <sb>
    80004c74:	00048b1b          	sext.w	s6,s1
    80004c78:	0044d593          	srli	a1,s1,0x4
    80004c7c:	018a2783          	lw	a5,24(s4)
    80004c80:	9dbd                	addw	a1,a1,a5
    80004c82:	8556                	mv	a0,s5
    80004c84:	00000097          	auipc	ra,0x0
    80004c88:	954080e7          	jalr	-1708(ra) # 800045d8 <bread>
    80004c8c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004c8e:	05850993          	addi	s3,a0,88
    80004c92:	00f4f793          	andi	a5,s1,15
    80004c96:	079a                	slli	a5,a5,0x6
    80004c98:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004c9a:	00099783          	lh	a5,0(s3)
    80004c9e:	c785                	beqz	a5,80004cc6 <ialloc+0x84>
    brelse(bp);
    80004ca0:	00000097          	auipc	ra,0x0
    80004ca4:	a68080e7          	jalr	-1432(ra) # 80004708 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80004ca8:	0485                	addi	s1,s1,1
    80004caa:	00ca2703          	lw	a4,12(s4)
    80004cae:	0004879b          	sext.w	a5,s1
    80004cb2:	fce7e1e3          	bltu	a5,a4,80004c74 <ialloc+0x32>
  panic("ialloc: no inodes");
    80004cb6:	00005517          	auipc	a0,0x5
    80004cba:	d8250513          	addi	a0,a0,-638 # 80009a38 <syscalls+0x190>
    80004cbe:	ffffc097          	auipc	ra,0xffffc
    80004cc2:	880080e7          	jalr	-1920(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80004cc6:	04000613          	li	a2,64
    80004cca:	4581                	li	a1,0
    80004ccc:	854e                	mv	a0,s3
    80004cce:	ffffc097          	auipc	ra,0xffffc
    80004cd2:	012080e7          	jalr	18(ra) # 80000ce0 <memset>
      dip->type = type;
    80004cd6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80004cda:	854a                	mv	a0,s2
    80004cdc:	00001097          	auipc	ra,0x1
    80004ce0:	ca8080e7          	jalr	-856(ra) # 80005984 <log_write>
      brelse(bp);
    80004ce4:	854a                	mv	a0,s2
    80004ce6:	00000097          	auipc	ra,0x0
    80004cea:	a22080e7          	jalr	-1502(ra) # 80004708 <brelse>
      return iget(dev, inum);
    80004cee:	85da                	mv	a1,s6
    80004cf0:	8556                	mv	a0,s5
    80004cf2:	00000097          	auipc	ra,0x0
    80004cf6:	db4080e7          	jalr	-588(ra) # 80004aa6 <iget>
}
    80004cfa:	60a6                	ld	ra,72(sp)
    80004cfc:	6406                	ld	s0,64(sp)
    80004cfe:	74e2                	ld	s1,56(sp)
    80004d00:	7942                	ld	s2,48(sp)
    80004d02:	79a2                	ld	s3,40(sp)
    80004d04:	7a02                	ld	s4,32(sp)
    80004d06:	6ae2                	ld	s5,24(sp)
    80004d08:	6b42                	ld	s6,16(sp)
    80004d0a:	6ba2                	ld	s7,8(sp)
    80004d0c:	6161                	addi	sp,sp,80
    80004d0e:	8082                	ret

0000000080004d10 <iupdate>:
{
    80004d10:	1101                	addi	sp,sp,-32
    80004d12:	ec06                	sd	ra,24(sp)
    80004d14:	e822                	sd	s0,16(sp)
    80004d16:	e426                	sd	s1,8(sp)
    80004d18:	e04a                	sd	s2,0(sp)
    80004d1a:	1000                	addi	s0,sp,32
    80004d1c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004d1e:	415c                	lw	a5,4(a0)
    80004d20:	0047d79b          	srliw	a5,a5,0x4
    80004d24:	0001c597          	auipc	a1,0x1c
    80004d28:	73c5a583          	lw	a1,1852(a1) # 80021460 <sb+0x18>
    80004d2c:	9dbd                	addw	a1,a1,a5
    80004d2e:	4108                	lw	a0,0(a0)
    80004d30:	00000097          	auipc	ra,0x0
    80004d34:	8a8080e7          	jalr	-1880(ra) # 800045d8 <bread>
    80004d38:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004d3a:	05850793          	addi	a5,a0,88
    80004d3e:	40c8                	lw	a0,4(s1)
    80004d40:	893d                	andi	a0,a0,15
    80004d42:	051a                	slli	a0,a0,0x6
    80004d44:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80004d46:	04449703          	lh	a4,68(s1)
    80004d4a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80004d4e:	04649703          	lh	a4,70(s1)
    80004d52:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80004d56:	04849703          	lh	a4,72(s1)
    80004d5a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80004d5e:	04a49703          	lh	a4,74(s1)
    80004d62:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80004d66:	44f8                	lw	a4,76(s1)
    80004d68:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004d6a:	03400613          	li	a2,52
    80004d6e:	05048593          	addi	a1,s1,80
    80004d72:	0531                	addi	a0,a0,12
    80004d74:	ffffc097          	auipc	ra,0xffffc
    80004d78:	fcc080e7          	jalr	-52(ra) # 80000d40 <memmove>
  log_write(bp);
    80004d7c:	854a                	mv	a0,s2
    80004d7e:	00001097          	auipc	ra,0x1
    80004d82:	c06080e7          	jalr	-1018(ra) # 80005984 <log_write>
  brelse(bp);
    80004d86:	854a                	mv	a0,s2
    80004d88:	00000097          	auipc	ra,0x0
    80004d8c:	980080e7          	jalr	-1664(ra) # 80004708 <brelse>
}
    80004d90:	60e2                	ld	ra,24(sp)
    80004d92:	6442                	ld	s0,16(sp)
    80004d94:	64a2                	ld	s1,8(sp)
    80004d96:	6902                	ld	s2,0(sp)
    80004d98:	6105                	addi	sp,sp,32
    80004d9a:	8082                	ret

0000000080004d9c <idup>:
{
    80004d9c:	1101                	addi	sp,sp,-32
    80004d9e:	ec06                	sd	ra,24(sp)
    80004da0:	e822                	sd	s0,16(sp)
    80004da2:	e426                	sd	s1,8(sp)
    80004da4:	1000                	addi	s0,sp,32
    80004da6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004da8:	0001c517          	auipc	a0,0x1c
    80004dac:	6c050513          	addi	a0,a0,1728 # 80021468 <itable>
    80004db0:	ffffc097          	auipc	ra,0xffffc
    80004db4:	e34080e7          	jalr	-460(ra) # 80000be4 <acquire>
  ip->ref++;
    80004db8:	449c                	lw	a5,8(s1)
    80004dba:	2785                	addiw	a5,a5,1
    80004dbc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004dbe:	0001c517          	auipc	a0,0x1c
    80004dc2:	6aa50513          	addi	a0,a0,1706 # 80021468 <itable>
    80004dc6:	ffffc097          	auipc	ra,0xffffc
    80004dca:	ed2080e7          	jalr	-302(ra) # 80000c98 <release>
}
    80004dce:	8526                	mv	a0,s1
    80004dd0:	60e2                	ld	ra,24(sp)
    80004dd2:	6442                	ld	s0,16(sp)
    80004dd4:	64a2                	ld	s1,8(sp)
    80004dd6:	6105                	addi	sp,sp,32
    80004dd8:	8082                	ret

0000000080004dda <ilock>:
{
    80004dda:	1101                	addi	sp,sp,-32
    80004ddc:	ec06                	sd	ra,24(sp)
    80004dde:	e822                	sd	s0,16(sp)
    80004de0:	e426                	sd	s1,8(sp)
    80004de2:	e04a                	sd	s2,0(sp)
    80004de4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004de6:	c115                	beqz	a0,80004e0a <ilock+0x30>
    80004de8:	84aa                	mv	s1,a0
    80004dea:	451c                	lw	a5,8(a0)
    80004dec:	00f05f63          	blez	a5,80004e0a <ilock+0x30>
  acquiresleep(&ip->lock);
    80004df0:	0541                	addi	a0,a0,16
    80004df2:	00001097          	auipc	ra,0x1
    80004df6:	cb2080e7          	jalr	-846(ra) # 80005aa4 <acquiresleep>
  if(ip->valid == 0){
    80004dfa:	40bc                	lw	a5,64(s1)
    80004dfc:	cf99                	beqz	a5,80004e1a <ilock+0x40>
}
    80004dfe:	60e2                	ld	ra,24(sp)
    80004e00:	6442                	ld	s0,16(sp)
    80004e02:	64a2                	ld	s1,8(sp)
    80004e04:	6902                	ld	s2,0(sp)
    80004e06:	6105                	addi	sp,sp,32
    80004e08:	8082                	ret
    panic("ilock");
    80004e0a:	00005517          	auipc	a0,0x5
    80004e0e:	c4650513          	addi	a0,a0,-954 # 80009a50 <syscalls+0x1a8>
    80004e12:	ffffb097          	auipc	ra,0xffffb
    80004e16:	72c080e7          	jalr	1836(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004e1a:	40dc                	lw	a5,4(s1)
    80004e1c:	0047d79b          	srliw	a5,a5,0x4
    80004e20:	0001c597          	auipc	a1,0x1c
    80004e24:	6405a583          	lw	a1,1600(a1) # 80021460 <sb+0x18>
    80004e28:	9dbd                	addw	a1,a1,a5
    80004e2a:	4088                	lw	a0,0(s1)
    80004e2c:	fffff097          	auipc	ra,0xfffff
    80004e30:	7ac080e7          	jalr	1964(ra) # 800045d8 <bread>
    80004e34:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004e36:	05850593          	addi	a1,a0,88
    80004e3a:	40dc                	lw	a5,4(s1)
    80004e3c:	8bbd                	andi	a5,a5,15
    80004e3e:	079a                	slli	a5,a5,0x6
    80004e40:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004e42:	00059783          	lh	a5,0(a1)
    80004e46:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004e4a:	00259783          	lh	a5,2(a1)
    80004e4e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004e52:	00459783          	lh	a5,4(a1)
    80004e56:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004e5a:	00659783          	lh	a5,6(a1)
    80004e5e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004e62:	459c                	lw	a5,8(a1)
    80004e64:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004e66:	03400613          	li	a2,52
    80004e6a:	05b1                	addi	a1,a1,12
    80004e6c:	05048513          	addi	a0,s1,80
    80004e70:	ffffc097          	auipc	ra,0xffffc
    80004e74:	ed0080e7          	jalr	-304(ra) # 80000d40 <memmove>
    brelse(bp);
    80004e78:	854a                	mv	a0,s2
    80004e7a:	00000097          	auipc	ra,0x0
    80004e7e:	88e080e7          	jalr	-1906(ra) # 80004708 <brelse>
    ip->valid = 1;
    80004e82:	4785                	li	a5,1
    80004e84:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004e86:	04449783          	lh	a5,68(s1)
    80004e8a:	fbb5                	bnez	a5,80004dfe <ilock+0x24>
      panic("ilock: no type");
    80004e8c:	00005517          	auipc	a0,0x5
    80004e90:	bcc50513          	addi	a0,a0,-1076 # 80009a58 <syscalls+0x1b0>
    80004e94:	ffffb097          	auipc	ra,0xffffb
    80004e98:	6aa080e7          	jalr	1706(ra) # 8000053e <panic>

0000000080004e9c <iunlock>:
{
    80004e9c:	1101                	addi	sp,sp,-32
    80004e9e:	ec06                	sd	ra,24(sp)
    80004ea0:	e822                	sd	s0,16(sp)
    80004ea2:	e426                	sd	s1,8(sp)
    80004ea4:	e04a                	sd	s2,0(sp)
    80004ea6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004ea8:	c905                	beqz	a0,80004ed8 <iunlock+0x3c>
    80004eaa:	84aa                	mv	s1,a0
    80004eac:	01050913          	addi	s2,a0,16
    80004eb0:	854a                	mv	a0,s2
    80004eb2:	00001097          	auipc	ra,0x1
    80004eb6:	c8c080e7          	jalr	-884(ra) # 80005b3e <holdingsleep>
    80004eba:	cd19                	beqz	a0,80004ed8 <iunlock+0x3c>
    80004ebc:	449c                	lw	a5,8(s1)
    80004ebe:	00f05d63          	blez	a5,80004ed8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004ec2:	854a                	mv	a0,s2
    80004ec4:	00001097          	auipc	ra,0x1
    80004ec8:	c36080e7          	jalr	-970(ra) # 80005afa <releasesleep>
}
    80004ecc:	60e2                	ld	ra,24(sp)
    80004ece:	6442                	ld	s0,16(sp)
    80004ed0:	64a2                	ld	s1,8(sp)
    80004ed2:	6902                	ld	s2,0(sp)
    80004ed4:	6105                	addi	sp,sp,32
    80004ed6:	8082                	ret
    panic("iunlock");
    80004ed8:	00005517          	auipc	a0,0x5
    80004edc:	b9050513          	addi	a0,a0,-1136 # 80009a68 <syscalls+0x1c0>
    80004ee0:	ffffb097          	auipc	ra,0xffffb
    80004ee4:	65e080e7          	jalr	1630(ra) # 8000053e <panic>

0000000080004ee8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004ee8:	7179                	addi	sp,sp,-48
    80004eea:	f406                	sd	ra,40(sp)
    80004eec:	f022                	sd	s0,32(sp)
    80004eee:	ec26                	sd	s1,24(sp)
    80004ef0:	e84a                	sd	s2,16(sp)
    80004ef2:	e44e                	sd	s3,8(sp)
    80004ef4:	e052                	sd	s4,0(sp)
    80004ef6:	1800                	addi	s0,sp,48
    80004ef8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004efa:	05050493          	addi	s1,a0,80
    80004efe:	08050913          	addi	s2,a0,128
    80004f02:	a021                	j	80004f0a <itrunc+0x22>
    80004f04:	0491                	addi	s1,s1,4
    80004f06:	01248d63          	beq	s1,s2,80004f20 <itrunc+0x38>
    if(ip->addrs[i]){
    80004f0a:	408c                	lw	a1,0(s1)
    80004f0c:	dde5                	beqz	a1,80004f04 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004f0e:	0009a503          	lw	a0,0(s3)
    80004f12:	00000097          	auipc	ra,0x0
    80004f16:	90c080e7          	jalr	-1780(ra) # 8000481e <bfree>
      ip->addrs[i] = 0;
    80004f1a:	0004a023          	sw	zero,0(s1)
    80004f1e:	b7dd                	j	80004f04 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004f20:	0809a583          	lw	a1,128(s3)
    80004f24:	e185                	bnez	a1,80004f44 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004f26:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004f2a:	854e                	mv	a0,s3
    80004f2c:	00000097          	auipc	ra,0x0
    80004f30:	de4080e7          	jalr	-540(ra) # 80004d10 <iupdate>
}
    80004f34:	70a2                	ld	ra,40(sp)
    80004f36:	7402                	ld	s0,32(sp)
    80004f38:	64e2                	ld	s1,24(sp)
    80004f3a:	6942                	ld	s2,16(sp)
    80004f3c:	69a2                	ld	s3,8(sp)
    80004f3e:	6a02                	ld	s4,0(sp)
    80004f40:	6145                	addi	sp,sp,48
    80004f42:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004f44:	0009a503          	lw	a0,0(s3)
    80004f48:	fffff097          	auipc	ra,0xfffff
    80004f4c:	690080e7          	jalr	1680(ra) # 800045d8 <bread>
    80004f50:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004f52:	05850493          	addi	s1,a0,88
    80004f56:	45850913          	addi	s2,a0,1112
    80004f5a:	a811                	j	80004f6e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004f5c:	0009a503          	lw	a0,0(s3)
    80004f60:	00000097          	auipc	ra,0x0
    80004f64:	8be080e7          	jalr	-1858(ra) # 8000481e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004f68:	0491                	addi	s1,s1,4
    80004f6a:	01248563          	beq	s1,s2,80004f74 <itrunc+0x8c>
      if(a[j])
    80004f6e:	408c                	lw	a1,0(s1)
    80004f70:	dde5                	beqz	a1,80004f68 <itrunc+0x80>
    80004f72:	b7ed                	j	80004f5c <itrunc+0x74>
    brelse(bp);
    80004f74:	8552                	mv	a0,s4
    80004f76:	fffff097          	auipc	ra,0xfffff
    80004f7a:	792080e7          	jalr	1938(ra) # 80004708 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004f7e:	0809a583          	lw	a1,128(s3)
    80004f82:	0009a503          	lw	a0,0(s3)
    80004f86:	00000097          	auipc	ra,0x0
    80004f8a:	898080e7          	jalr	-1896(ra) # 8000481e <bfree>
    ip->addrs[NDIRECT] = 0;
    80004f8e:	0809a023          	sw	zero,128(s3)
    80004f92:	bf51                	j	80004f26 <itrunc+0x3e>

0000000080004f94 <iput>:
{
    80004f94:	1101                	addi	sp,sp,-32
    80004f96:	ec06                	sd	ra,24(sp)
    80004f98:	e822                	sd	s0,16(sp)
    80004f9a:	e426                	sd	s1,8(sp)
    80004f9c:	e04a                	sd	s2,0(sp)
    80004f9e:	1000                	addi	s0,sp,32
    80004fa0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004fa2:	0001c517          	auipc	a0,0x1c
    80004fa6:	4c650513          	addi	a0,a0,1222 # 80021468 <itable>
    80004faa:	ffffc097          	auipc	ra,0xffffc
    80004fae:	c3a080e7          	jalr	-966(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004fb2:	4498                	lw	a4,8(s1)
    80004fb4:	4785                	li	a5,1
    80004fb6:	02f70363          	beq	a4,a5,80004fdc <iput+0x48>
  ip->ref--;
    80004fba:	449c                	lw	a5,8(s1)
    80004fbc:	37fd                	addiw	a5,a5,-1
    80004fbe:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004fc0:	0001c517          	auipc	a0,0x1c
    80004fc4:	4a850513          	addi	a0,a0,1192 # 80021468 <itable>
    80004fc8:	ffffc097          	auipc	ra,0xffffc
    80004fcc:	cd0080e7          	jalr	-816(ra) # 80000c98 <release>
}
    80004fd0:	60e2                	ld	ra,24(sp)
    80004fd2:	6442                	ld	s0,16(sp)
    80004fd4:	64a2                	ld	s1,8(sp)
    80004fd6:	6902                	ld	s2,0(sp)
    80004fd8:	6105                	addi	sp,sp,32
    80004fda:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004fdc:	40bc                	lw	a5,64(s1)
    80004fde:	dff1                	beqz	a5,80004fba <iput+0x26>
    80004fe0:	04a49783          	lh	a5,74(s1)
    80004fe4:	fbf9                	bnez	a5,80004fba <iput+0x26>
    acquiresleep(&ip->lock);
    80004fe6:	01048913          	addi	s2,s1,16
    80004fea:	854a                	mv	a0,s2
    80004fec:	00001097          	auipc	ra,0x1
    80004ff0:	ab8080e7          	jalr	-1352(ra) # 80005aa4 <acquiresleep>
    release(&itable.lock);
    80004ff4:	0001c517          	auipc	a0,0x1c
    80004ff8:	47450513          	addi	a0,a0,1140 # 80021468 <itable>
    80004ffc:	ffffc097          	auipc	ra,0xffffc
    80005000:	c9c080e7          	jalr	-868(ra) # 80000c98 <release>
    itrunc(ip);
    80005004:	8526                	mv	a0,s1
    80005006:	00000097          	auipc	ra,0x0
    8000500a:	ee2080e7          	jalr	-286(ra) # 80004ee8 <itrunc>
    ip->type = 0;
    8000500e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80005012:	8526                	mv	a0,s1
    80005014:	00000097          	auipc	ra,0x0
    80005018:	cfc080e7          	jalr	-772(ra) # 80004d10 <iupdate>
    ip->valid = 0;
    8000501c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80005020:	854a                	mv	a0,s2
    80005022:	00001097          	auipc	ra,0x1
    80005026:	ad8080e7          	jalr	-1320(ra) # 80005afa <releasesleep>
    acquire(&itable.lock);
    8000502a:	0001c517          	auipc	a0,0x1c
    8000502e:	43e50513          	addi	a0,a0,1086 # 80021468 <itable>
    80005032:	ffffc097          	auipc	ra,0xffffc
    80005036:	bb2080e7          	jalr	-1102(ra) # 80000be4 <acquire>
    8000503a:	b741                	j	80004fba <iput+0x26>

000000008000503c <iunlockput>:
{
    8000503c:	1101                	addi	sp,sp,-32
    8000503e:	ec06                	sd	ra,24(sp)
    80005040:	e822                	sd	s0,16(sp)
    80005042:	e426                	sd	s1,8(sp)
    80005044:	1000                	addi	s0,sp,32
    80005046:	84aa                	mv	s1,a0
  iunlock(ip);
    80005048:	00000097          	auipc	ra,0x0
    8000504c:	e54080e7          	jalr	-428(ra) # 80004e9c <iunlock>
  iput(ip);
    80005050:	8526                	mv	a0,s1
    80005052:	00000097          	auipc	ra,0x0
    80005056:	f42080e7          	jalr	-190(ra) # 80004f94 <iput>
}
    8000505a:	60e2                	ld	ra,24(sp)
    8000505c:	6442                	ld	s0,16(sp)
    8000505e:	64a2                	ld	s1,8(sp)
    80005060:	6105                	addi	sp,sp,32
    80005062:	8082                	ret

0000000080005064 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80005064:	1141                	addi	sp,sp,-16
    80005066:	e422                	sd	s0,8(sp)
    80005068:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000506a:	411c                	lw	a5,0(a0)
    8000506c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000506e:	415c                	lw	a5,4(a0)
    80005070:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80005072:	04451783          	lh	a5,68(a0)
    80005076:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000507a:	04a51783          	lh	a5,74(a0)
    8000507e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80005082:	04c56783          	lwu	a5,76(a0)
    80005086:	e99c                	sd	a5,16(a1)
}
    80005088:	6422                	ld	s0,8(sp)
    8000508a:	0141                	addi	sp,sp,16
    8000508c:	8082                	ret

000000008000508e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000508e:	457c                	lw	a5,76(a0)
    80005090:	0ed7e963          	bltu	a5,a3,80005182 <readi+0xf4>
{
    80005094:	7159                	addi	sp,sp,-112
    80005096:	f486                	sd	ra,104(sp)
    80005098:	f0a2                	sd	s0,96(sp)
    8000509a:	eca6                	sd	s1,88(sp)
    8000509c:	e8ca                	sd	s2,80(sp)
    8000509e:	e4ce                	sd	s3,72(sp)
    800050a0:	e0d2                	sd	s4,64(sp)
    800050a2:	fc56                	sd	s5,56(sp)
    800050a4:	f85a                	sd	s6,48(sp)
    800050a6:	f45e                	sd	s7,40(sp)
    800050a8:	f062                	sd	s8,32(sp)
    800050aa:	ec66                	sd	s9,24(sp)
    800050ac:	e86a                	sd	s10,16(sp)
    800050ae:	e46e                	sd	s11,8(sp)
    800050b0:	1880                	addi	s0,sp,112
    800050b2:	8baa                	mv	s7,a0
    800050b4:	8c2e                	mv	s8,a1
    800050b6:	8ab2                	mv	s5,a2
    800050b8:	84b6                	mv	s1,a3
    800050ba:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800050bc:	9f35                	addw	a4,a4,a3
    return 0;
    800050be:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800050c0:	0ad76063          	bltu	a4,a3,80005160 <readi+0xd2>
  if(off + n > ip->size)
    800050c4:	00e7f463          	bgeu	a5,a4,800050cc <readi+0x3e>
    n = ip->size - off;
    800050c8:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800050cc:	0a0b0963          	beqz	s6,8000517e <readi+0xf0>
    800050d0:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800050d2:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800050d6:	5cfd                	li	s9,-1
    800050d8:	a82d                	j	80005112 <readi+0x84>
    800050da:	020a1d93          	slli	s11,s4,0x20
    800050de:	020ddd93          	srli	s11,s11,0x20
    800050e2:	05890613          	addi	a2,s2,88
    800050e6:	86ee                	mv	a3,s11
    800050e8:	963a                	add	a2,a2,a4
    800050ea:	85d6                	mv	a1,s5
    800050ec:	8562                	mv	a0,s8
    800050ee:	fffff097          	auipc	ra,0xfffff
    800050f2:	a74080e7          	jalr	-1420(ra) # 80003b62 <either_copyout>
    800050f6:	05950d63          	beq	a0,s9,80005150 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800050fa:	854a                	mv	a0,s2
    800050fc:	fffff097          	auipc	ra,0xfffff
    80005100:	60c080e7          	jalr	1548(ra) # 80004708 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80005104:	013a09bb          	addw	s3,s4,s3
    80005108:	009a04bb          	addw	s1,s4,s1
    8000510c:	9aee                	add	s5,s5,s11
    8000510e:	0569f763          	bgeu	s3,s6,8000515c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80005112:	000ba903          	lw	s2,0(s7)
    80005116:	00a4d59b          	srliw	a1,s1,0xa
    8000511a:	855e                	mv	a0,s7
    8000511c:	00000097          	auipc	ra,0x0
    80005120:	8b0080e7          	jalr	-1872(ra) # 800049cc <bmap>
    80005124:	0005059b          	sext.w	a1,a0
    80005128:	854a                	mv	a0,s2
    8000512a:	fffff097          	auipc	ra,0xfffff
    8000512e:	4ae080e7          	jalr	1198(ra) # 800045d8 <bread>
    80005132:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80005134:	3ff4f713          	andi	a4,s1,1023
    80005138:	40ed07bb          	subw	a5,s10,a4
    8000513c:	413b06bb          	subw	a3,s6,s3
    80005140:	8a3e                	mv	s4,a5
    80005142:	2781                	sext.w	a5,a5
    80005144:	0006861b          	sext.w	a2,a3
    80005148:	f8f679e3          	bgeu	a2,a5,800050da <readi+0x4c>
    8000514c:	8a36                	mv	s4,a3
    8000514e:	b771                	j	800050da <readi+0x4c>
      brelse(bp);
    80005150:	854a                	mv	a0,s2
    80005152:	fffff097          	auipc	ra,0xfffff
    80005156:	5b6080e7          	jalr	1462(ra) # 80004708 <brelse>
      tot = -1;
    8000515a:	59fd                	li	s3,-1
  }
  return tot;
    8000515c:	0009851b          	sext.w	a0,s3
}
    80005160:	70a6                	ld	ra,104(sp)
    80005162:	7406                	ld	s0,96(sp)
    80005164:	64e6                	ld	s1,88(sp)
    80005166:	6946                	ld	s2,80(sp)
    80005168:	69a6                	ld	s3,72(sp)
    8000516a:	6a06                	ld	s4,64(sp)
    8000516c:	7ae2                	ld	s5,56(sp)
    8000516e:	7b42                	ld	s6,48(sp)
    80005170:	7ba2                	ld	s7,40(sp)
    80005172:	7c02                	ld	s8,32(sp)
    80005174:	6ce2                	ld	s9,24(sp)
    80005176:	6d42                	ld	s10,16(sp)
    80005178:	6da2                	ld	s11,8(sp)
    8000517a:	6165                	addi	sp,sp,112
    8000517c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000517e:	89da                	mv	s3,s6
    80005180:	bff1                	j	8000515c <readi+0xce>
    return 0;
    80005182:	4501                	li	a0,0
}
    80005184:	8082                	ret

0000000080005186 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80005186:	457c                	lw	a5,76(a0)
    80005188:	10d7e863          	bltu	a5,a3,80005298 <writei+0x112>
{
    8000518c:	7159                	addi	sp,sp,-112
    8000518e:	f486                	sd	ra,104(sp)
    80005190:	f0a2                	sd	s0,96(sp)
    80005192:	eca6                	sd	s1,88(sp)
    80005194:	e8ca                	sd	s2,80(sp)
    80005196:	e4ce                	sd	s3,72(sp)
    80005198:	e0d2                	sd	s4,64(sp)
    8000519a:	fc56                	sd	s5,56(sp)
    8000519c:	f85a                	sd	s6,48(sp)
    8000519e:	f45e                	sd	s7,40(sp)
    800051a0:	f062                	sd	s8,32(sp)
    800051a2:	ec66                	sd	s9,24(sp)
    800051a4:	e86a                	sd	s10,16(sp)
    800051a6:	e46e                	sd	s11,8(sp)
    800051a8:	1880                	addi	s0,sp,112
    800051aa:	8b2a                	mv	s6,a0
    800051ac:	8c2e                	mv	s8,a1
    800051ae:	8ab2                	mv	s5,a2
    800051b0:	8936                	mv	s2,a3
    800051b2:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800051b4:	00e687bb          	addw	a5,a3,a4
    800051b8:	0ed7e263          	bltu	a5,a3,8000529c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800051bc:	00043737          	lui	a4,0x43
    800051c0:	0ef76063          	bltu	a4,a5,800052a0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800051c4:	0c0b8863          	beqz	s7,80005294 <writei+0x10e>
    800051c8:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800051ca:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800051ce:	5cfd                	li	s9,-1
    800051d0:	a091                	j	80005214 <writei+0x8e>
    800051d2:	02099d93          	slli	s11,s3,0x20
    800051d6:	020ddd93          	srli	s11,s11,0x20
    800051da:	05848513          	addi	a0,s1,88
    800051de:	86ee                	mv	a3,s11
    800051e0:	8656                	mv	a2,s5
    800051e2:	85e2                	mv	a1,s8
    800051e4:	953a                	add	a0,a0,a4
    800051e6:	fffff097          	auipc	ra,0xfffff
    800051ea:	9d2080e7          	jalr	-1582(ra) # 80003bb8 <either_copyin>
    800051ee:	07950263          	beq	a0,s9,80005252 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800051f2:	8526                	mv	a0,s1
    800051f4:	00000097          	auipc	ra,0x0
    800051f8:	790080e7          	jalr	1936(ra) # 80005984 <log_write>
    brelse(bp);
    800051fc:	8526                	mv	a0,s1
    800051fe:	fffff097          	auipc	ra,0xfffff
    80005202:	50a080e7          	jalr	1290(ra) # 80004708 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80005206:	01498a3b          	addw	s4,s3,s4
    8000520a:	0129893b          	addw	s2,s3,s2
    8000520e:	9aee                	add	s5,s5,s11
    80005210:	057a7663          	bgeu	s4,s7,8000525c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80005214:	000b2483          	lw	s1,0(s6)
    80005218:	00a9559b          	srliw	a1,s2,0xa
    8000521c:	855a                	mv	a0,s6
    8000521e:	fffff097          	auipc	ra,0xfffff
    80005222:	7ae080e7          	jalr	1966(ra) # 800049cc <bmap>
    80005226:	0005059b          	sext.w	a1,a0
    8000522a:	8526                	mv	a0,s1
    8000522c:	fffff097          	auipc	ra,0xfffff
    80005230:	3ac080e7          	jalr	940(ra) # 800045d8 <bread>
    80005234:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80005236:	3ff97713          	andi	a4,s2,1023
    8000523a:	40ed07bb          	subw	a5,s10,a4
    8000523e:	414b86bb          	subw	a3,s7,s4
    80005242:	89be                	mv	s3,a5
    80005244:	2781                	sext.w	a5,a5
    80005246:	0006861b          	sext.w	a2,a3
    8000524a:	f8f674e3          	bgeu	a2,a5,800051d2 <writei+0x4c>
    8000524e:	89b6                	mv	s3,a3
    80005250:	b749                	j	800051d2 <writei+0x4c>
      brelse(bp);
    80005252:	8526                	mv	a0,s1
    80005254:	fffff097          	auipc	ra,0xfffff
    80005258:	4b4080e7          	jalr	1204(ra) # 80004708 <brelse>
  }

  if(off > ip->size)
    8000525c:	04cb2783          	lw	a5,76(s6)
    80005260:	0127f463          	bgeu	a5,s2,80005268 <writei+0xe2>
    ip->size = off;
    80005264:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80005268:	855a                	mv	a0,s6
    8000526a:	00000097          	auipc	ra,0x0
    8000526e:	aa6080e7          	jalr	-1370(ra) # 80004d10 <iupdate>

  return tot;
    80005272:	000a051b          	sext.w	a0,s4
}
    80005276:	70a6                	ld	ra,104(sp)
    80005278:	7406                	ld	s0,96(sp)
    8000527a:	64e6                	ld	s1,88(sp)
    8000527c:	6946                	ld	s2,80(sp)
    8000527e:	69a6                	ld	s3,72(sp)
    80005280:	6a06                	ld	s4,64(sp)
    80005282:	7ae2                	ld	s5,56(sp)
    80005284:	7b42                	ld	s6,48(sp)
    80005286:	7ba2                	ld	s7,40(sp)
    80005288:	7c02                	ld	s8,32(sp)
    8000528a:	6ce2                	ld	s9,24(sp)
    8000528c:	6d42                	ld	s10,16(sp)
    8000528e:	6da2                	ld	s11,8(sp)
    80005290:	6165                	addi	sp,sp,112
    80005292:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80005294:	8a5e                	mv	s4,s7
    80005296:	bfc9                	j	80005268 <writei+0xe2>
    return -1;
    80005298:	557d                	li	a0,-1
}
    8000529a:	8082                	ret
    return -1;
    8000529c:	557d                	li	a0,-1
    8000529e:	bfe1                	j	80005276 <writei+0xf0>
    return -1;
    800052a0:	557d                	li	a0,-1
    800052a2:	bfd1                	j	80005276 <writei+0xf0>

00000000800052a4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800052a4:	1141                	addi	sp,sp,-16
    800052a6:	e406                	sd	ra,8(sp)
    800052a8:	e022                	sd	s0,0(sp)
    800052aa:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800052ac:	4639                	li	a2,14
    800052ae:	ffffc097          	auipc	ra,0xffffc
    800052b2:	b0a080e7          	jalr	-1270(ra) # 80000db8 <strncmp>
}
    800052b6:	60a2                	ld	ra,8(sp)
    800052b8:	6402                	ld	s0,0(sp)
    800052ba:	0141                	addi	sp,sp,16
    800052bc:	8082                	ret

00000000800052be <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800052be:	7139                	addi	sp,sp,-64
    800052c0:	fc06                	sd	ra,56(sp)
    800052c2:	f822                	sd	s0,48(sp)
    800052c4:	f426                	sd	s1,40(sp)
    800052c6:	f04a                	sd	s2,32(sp)
    800052c8:	ec4e                	sd	s3,24(sp)
    800052ca:	e852                	sd	s4,16(sp)
    800052cc:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800052ce:	04451703          	lh	a4,68(a0)
    800052d2:	4785                	li	a5,1
    800052d4:	00f71a63          	bne	a4,a5,800052e8 <dirlookup+0x2a>
    800052d8:	892a                	mv	s2,a0
    800052da:	89ae                	mv	s3,a1
    800052dc:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800052de:	457c                	lw	a5,76(a0)
    800052e0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800052e2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800052e4:	e79d                	bnez	a5,80005312 <dirlookup+0x54>
    800052e6:	a8a5                	j	8000535e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800052e8:	00004517          	auipc	a0,0x4
    800052ec:	78850513          	addi	a0,a0,1928 # 80009a70 <syscalls+0x1c8>
    800052f0:	ffffb097          	auipc	ra,0xffffb
    800052f4:	24e080e7          	jalr	590(ra) # 8000053e <panic>
      panic("dirlookup read");
    800052f8:	00004517          	auipc	a0,0x4
    800052fc:	79050513          	addi	a0,a0,1936 # 80009a88 <syscalls+0x1e0>
    80005300:	ffffb097          	auipc	ra,0xffffb
    80005304:	23e080e7          	jalr	574(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80005308:	24c1                	addiw	s1,s1,16
    8000530a:	04c92783          	lw	a5,76(s2)
    8000530e:	04f4f763          	bgeu	s1,a5,8000535c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005312:	4741                	li	a4,16
    80005314:	86a6                	mv	a3,s1
    80005316:	fc040613          	addi	a2,s0,-64
    8000531a:	4581                	li	a1,0
    8000531c:	854a                	mv	a0,s2
    8000531e:	00000097          	auipc	ra,0x0
    80005322:	d70080e7          	jalr	-656(ra) # 8000508e <readi>
    80005326:	47c1                	li	a5,16
    80005328:	fcf518e3          	bne	a0,a5,800052f8 <dirlookup+0x3a>
    if(de.inum == 0)
    8000532c:	fc045783          	lhu	a5,-64(s0)
    80005330:	dfe1                	beqz	a5,80005308 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80005332:	fc240593          	addi	a1,s0,-62
    80005336:	854e                	mv	a0,s3
    80005338:	00000097          	auipc	ra,0x0
    8000533c:	f6c080e7          	jalr	-148(ra) # 800052a4 <namecmp>
    80005340:	f561                	bnez	a0,80005308 <dirlookup+0x4a>
      if(poff)
    80005342:	000a0463          	beqz	s4,8000534a <dirlookup+0x8c>
        *poff = off;
    80005346:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000534a:	fc045583          	lhu	a1,-64(s0)
    8000534e:	00092503          	lw	a0,0(s2)
    80005352:	fffff097          	auipc	ra,0xfffff
    80005356:	754080e7          	jalr	1876(ra) # 80004aa6 <iget>
    8000535a:	a011                	j	8000535e <dirlookup+0xa0>
  return 0;
    8000535c:	4501                	li	a0,0
}
    8000535e:	70e2                	ld	ra,56(sp)
    80005360:	7442                	ld	s0,48(sp)
    80005362:	74a2                	ld	s1,40(sp)
    80005364:	7902                	ld	s2,32(sp)
    80005366:	69e2                	ld	s3,24(sp)
    80005368:	6a42                	ld	s4,16(sp)
    8000536a:	6121                	addi	sp,sp,64
    8000536c:	8082                	ret

000000008000536e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000536e:	711d                	addi	sp,sp,-96
    80005370:	ec86                	sd	ra,88(sp)
    80005372:	e8a2                	sd	s0,80(sp)
    80005374:	e4a6                	sd	s1,72(sp)
    80005376:	e0ca                	sd	s2,64(sp)
    80005378:	fc4e                	sd	s3,56(sp)
    8000537a:	f852                	sd	s4,48(sp)
    8000537c:	f456                	sd	s5,40(sp)
    8000537e:	f05a                	sd	s6,32(sp)
    80005380:	ec5e                	sd	s7,24(sp)
    80005382:	e862                	sd	s8,16(sp)
    80005384:	e466                	sd	s9,8(sp)
    80005386:	1080                	addi	s0,sp,96
    80005388:	84aa                	mv	s1,a0
    8000538a:	8b2e                	mv	s6,a1
    8000538c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000538e:	00054703          	lbu	a4,0(a0)
    80005392:	02f00793          	li	a5,47
    80005396:	02f70363          	beq	a4,a5,800053bc <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000539a:	ffffd097          	auipc	ra,0xffffd
    8000539e:	82a080e7          	jalr	-2006(ra) # 80001bc4 <myproc>
    800053a2:	18053503          	ld	a0,384(a0)
    800053a6:	00000097          	auipc	ra,0x0
    800053aa:	9f6080e7          	jalr	-1546(ra) # 80004d9c <idup>
    800053ae:	89aa                	mv	s3,a0
  while(*path == '/')
    800053b0:	02f00913          	li	s2,47
  len = path - s;
    800053b4:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800053b6:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800053b8:	4c05                	li	s8,1
    800053ba:	a865                	j	80005472 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800053bc:	4585                	li	a1,1
    800053be:	4505                	li	a0,1
    800053c0:	fffff097          	auipc	ra,0xfffff
    800053c4:	6e6080e7          	jalr	1766(ra) # 80004aa6 <iget>
    800053c8:	89aa                	mv	s3,a0
    800053ca:	b7dd                	j	800053b0 <namex+0x42>
      iunlockput(ip);
    800053cc:	854e                	mv	a0,s3
    800053ce:	00000097          	auipc	ra,0x0
    800053d2:	c6e080e7          	jalr	-914(ra) # 8000503c <iunlockput>
      return 0;
    800053d6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800053d8:	854e                	mv	a0,s3
    800053da:	60e6                	ld	ra,88(sp)
    800053dc:	6446                	ld	s0,80(sp)
    800053de:	64a6                	ld	s1,72(sp)
    800053e0:	6906                	ld	s2,64(sp)
    800053e2:	79e2                	ld	s3,56(sp)
    800053e4:	7a42                	ld	s4,48(sp)
    800053e6:	7aa2                	ld	s5,40(sp)
    800053e8:	7b02                	ld	s6,32(sp)
    800053ea:	6be2                	ld	s7,24(sp)
    800053ec:	6c42                	ld	s8,16(sp)
    800053ee:	6ca2                	ld	s9,8(sp)
    800053f0:	6125                	addi	sp,sp,96
    800053f2:	8082                	ret
      iunlock(ip);
    800053f4:	854e                	mv	a0,s3
    800053f6:	00000097          	auipc	ra,0x0
    800053fa:	aa6080e7          	jalr	-1370(ra) # 80004e9c <iunlock>
      return ip;
    800053fe:	bfe9                	j	800053d8 <namex+0x6a>
      iunlockput(ip);
    80005400:	854e                	mv	a0,s3
    80005402:	00000097          	auipc	ra,0x0
    80005406:	c3a080e7          	jalr	-966(ra) # 8000503c <iunlockput>
      return 0;
    8000540a:	89d2                	mv	s3,s4
    8000540c:	b7f1                	j	800053d8 <namex+0x6a>
  len = path - s;
    8000540e:	40b48633          	sub	a2,s1,a1
    80005412:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80005416:	094cd463          	bge	s9,s4,8000549e <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000541a:	4639                	li	a2,14
    8000541c:	8556                	mv	a0,s5
    8000541e:	ffffc097          	auipc	ra,0xffffc
    80005422:	922080e7          	jalr	-1758(ra) # 80000d40 <memmove>
  while(*path == '/')
    80005426:	0004c783          	lbu	a5,0(s1)
    8000542a:	01279763          	bne	a5,s2,80005438 <namex+0xca>
    path++;
    8000542e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80005430:	0004c783          	lbu	a5,0(s1)
    80005434:	ff278de3          	beq	a5,s2,8000542e <namex+0xc0>
    ilock(ip);
    80005438:	854e                	mv	a0,s3
    8000543a:	00000097          	auipc	ra,0x0
    8000543e:	9a0080e7          	jalr	-1632(ra) # 80004dda <ilock>
    if(ip->type != T_DIR){
    80005442:	04499783          	lh	a5,68(s3)
    80005446:	f98793e3          	bne	a5,s8,800053cc <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000544a:	000b0563          	beqz	s6,80005454 <namex+0xe6>
    8000544e:	0004c783          	lbu	a5,0(s1)
    80005452:	d3cd                	beqz	a5,800053f4 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80005454:	865e                	mv	a2,s7
    80005456:	85d6                	mv	a1,s5
    80005458:	854e                	mv	a0,s3
    8000545a:	00000097          	auipc	ra,0x0
    8000545e:	e64080e7          	jalr	-412(ra) # 800052be <dirlookup>
    80005462:	8a2a                	mv	s4,a0
    80005464:	dd51                	beqz	a0,80005400 <namex+0x92>
    iunlockput(ip);
    80005466:	854e                	mv	a0,s3
    80005468:	00000097          	auipc	ra,0x0
    8000546c:	bd4080e7          	jalr	-1068(ra) # 8000503c <iunlockput>
    ip = next;
    80005470:	89d2                	mv	s3,s4
  while(*path == '/')
    80005472:	0004c783          	lbu	a5,0(s1)
    80005476:	05279763          	bne	a5,s2,800054c4 <namex+0x156>
    path++;
    8000547a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000547c:	0004c783          	lbu	a5,0(s1)
    80005480:	ff278de3          	beq	a5,s2,8000547a <namex+0x10c>
  if(*path == 0)
    80005484:	c79d                	beqz	a5,800054b2 <namex+0x144>
    path++;
    80005486:	85a6                	mv	a1,s1
  len = path - s;
    80005488:	8a5e                	mv	s4,s7
    8000548a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000548c:	01278963          	beq	a5,s2,8000549e <namex+0x130>
    80005490:	dfbd                	beqz	a5,8000540e <namex+0xa0>
    path++;
    80005492:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80005494:	0004c783          	lbu	a5,0(s1)
    80005498:	ff279ce3          	bne	a5,s2,80005490 <namex+0x122>
    8000549c:	bf8d                	j	8000540e <namex+0xa0>
    memmove(name, s, len);
    8000549e:	2601                	sext.w	a2,a2
    800054a0:	8556                	mv	a0,s5
    800054a2:	ffffc097          	auipc	ra,0xffffc
    800054a6:	89e080e7          	jalr	-1890(ra) # 80000d40 <memmove>
    name[len] = 0;
    800054aa:	9a56                	add	s4,s4,s5
    800054ac:	000a0023          	sb	zero,0(s4)
    800054b0:	bf9d                	j	80005426 <namex+0xb8>
  if(nameiparent){
    800054b2:	f20b03e3          	beqz	s6,800053d8 <namex+0x6a>
    iput(ip);
    800054b6:	854e                	mv	a0,s3
    800054b8:	00000097          	auipc	ra,0x0
    800054bc:	adc080e7          	jalr	-1316(ra) # 80004f94 <iput>
    return 0;
    800054c0:	4981                	li	s3,0
    800054c2:	bf19                	j	800053d8 <namex+0x6a>
  if(*path == 0)
    800054c4:	d7fd                	beqz	a5,800054b2 <namex+0x144>
  while(*path != '/' && *path != 0)
    800054c6:	0004c783          	lbu	a5,0(s1)
    800054ca:	85a6                	mv	a1,s1
    800054cc:	b7d1                	j	80005490 <namex+0x122>

00000000800054ce <dirlink>:
{
    800054ce:	7139                	addi	sp,sp,-64
    800054d0:	fc06                	sd	ra,56(sp)
    800054d2:	f822                	sd	s0,48(sp)
    800054d4:	f426                	sd	s1,40(sp)
    800054d6:	f04a                	sd	s2,32(sp)
    800054d8:	ec4e                	sd	s3,24(sp)
    800054da:	e852                	sd	s4,16(sp)
    800054dc:	0080                	addi	s0,sp,64
    800054de:	892a                	mv	s2,a0
    800054e0:	8a2e                	mv	s4,a1
    800054e2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800054e4:	4601                	li	a2,0
    800054e6:	00000097          	auipc	ra,0x0
    800054ea:	dd8080e7          	jalr	-552(ra) # 800052be <dirlookup>
    800054ee:	e93d                	bnez	a0,80005564 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800054f0:	04c92483          	lw	s1,76(s2)
    800054f4:	c49d                	beqz	s1,80005522 <dirlink+0x54>
    800054f6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054f8:	4741                	li	a4,16
    800054fa:	86a6                	mv	a3,s1
    800054fc:	fc040613          	addi	a2,s0,-64
    80005500:	4581                	li	a1,0
    80005502:	854a                	mv	a0,s2
    80005504:	00000097          	auipc	ra,0x0
    80005508:	b8a080e7          	jalr	-1142(ra) # 8000508e <readi>
    8000550c:	47c1                	li	a5,16
    8000550e:	06f51163          	bne	a0,a5,80005570 <dirlink+0xa2>
    if(de.inum == 0)
    80005512:	fc045783          	lhu	a5,-64(s0)
    80005516:	c791                	beqz	a5,80005522 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80005518:	24c1                	addiw	s1,s1,16
    8000551a:	04c92783          	lw	a5,76(s2)
    8000551e:	fcf4ede3          	bltu	s1,a5,800054f8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80005522:	4639                	li	a2,14
    80005524:	85d2                	mv	a1,s4
    80005526:	fc240513          	addi	a0,s0,-62
    8000552a:	ffffc097          	auipc	ra,0xffffc
    8000552e:	8ca080e7          	jalr	-1846(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80005532:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005536:	4741                	li	a4,16
    80005538:	86a6                	mv	a3,s1
    8000553a:	fc040613          	addi	a2,s0,-64
    8000553e:	4581                	li	a1,0
    80005540:	854a                	mv	a0,s2
    80005542:	00000097          	auipc	ra,0x0
    80005546:	c44080e7          	jalr	-956(ra) # 80005186 <writei>
    8000554a:	872a                	mv	a4,a0
    8000554c:	47c1                	li	a5,16
  return 0;
    8000554e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005550:	02f71863          	bne	a4,a5,80005580 <dirlink+0xb2>
}
    80005554:	70e2                	ld	ra,56(sp)
    80005556:	7442                	ld	s0,48(sp)
    80005558:	74a2                	ld	s1,40(sp)
    8000555a:	7902                	ld	s2,32(sp)
    8000555c:	69e2                	ld	s3,24(sp)
    8000555e:	6a42                	ld	s4,16(sp)
    80005560:	6121                	addi	sp,sp,64
    80005562:	8082                	ret
    iput(ip);
    80005564:	00000097          	auipc	ra,0x0
    80005568:	a30080e7          	jalr	-1488(ra) # 80004f94 <iput>
    return -1;
    8000556c:	557d                	li	a0,-1
    8000556e:	b7dd                	j	80005554 <dirlink+0x86>
      panic("dirlink read");
    80005570:	00004517          	auipc	a0,0x4
    80005574:	52850513          	addi	a0,a0,1320 # 80009a98 <syscalls+0x1f0>
    80005578:	ffffb097          	auipc	ra,0xffffb
    8000557c:	fc6080e7          	jalr	-58(ra) # 8000053e <panic>
    panic("dirlink");
    80005580:	00004517          	auipc	a0,0x4
    80005584:	62850513          	addi	a0,a0,1576 # 80009ba8 <syscalls+0x300>
    80005588:	ffffb097          	auipc	ra,0xffffb
    8000558c:	fb6080e7          	jalr	-74(ra) # 8000053e <panic>

0000000080005590 <namei>:

struct inode*
namei(char *path)
{
    80005590:	1101                	addi	sp,sp,-32
    80005592:	ec06                	sd	ra,24(sp)
    80005594:	e822                	sd	s0,16(sp)
    80005596:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80005598:	fe040613          	addi	a2,s0,-32
    8000559c:	4581                	li	a1,0
    8000559e:	00000097          	auipc	ra,0x0
    800055a2:	dd0080e7          	jalr	-560(ra) # 8000536e <namex>
}
    800055a6:	60e2                	ld	ra,24(sp)
    800055a8:	6442                	ld	s0,16(sp)
    800055aa:	6105                	addi	sp,sp,32
    800055ac:	8082                	ret

00000000800055ae <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800055ae:	1141                	addi	sp,sp,-16
    800055b0:	e406                	sd	ra,8(sp)
    800055b2:	e022                	sd	s0,0(sp)
    800055b4:	0800                	addi	s0,sp,16
    800055b6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800055b8:	4585                	li	a1,1
    800055ba:	00000097          	auipc	ra,0x0
    800055be:	db4080e7          	jalr	-588(ra) # 8000536e <namex>
}
    800055c2:	60a2                	ld	ra,8(sp)
    800055c4:	6402                	ld	s0,0(sp)
    800055c6:	0141                	addi	sp,sp,16
    800055c8:	8082                	ret

00000000800055ca <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800055ca:	1101                	addi	sp,sp,-32
    800055cc:	ec06                	sd	ra,24(sp)
    800055ce:	e822                	sd	s0,16(sp)
    800055d0:	e426                	sd	s1,8(sp)
    800055d2:	e04a                	sd	s2,0(sp)
    800055d4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800055d6:	0001e917          	auipc	s2,0x1e
    800055da:	93a90913          	addi	s2,s2,-1734 # 80022f10 <log>
    800055de:	01892583          	lw	a1,24(s2)
    800055e2:	02892503          	lw	a0,40(s2)
    800055e6:	fffff097          	auipc	ra,0xfffff
    800055ea:	ff2080e7          	jalr	-14(ra) # 800045d8 <bread>
    800055ee:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800055f0:	02c92683          	lw	a3,44(s2)
    800055f4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800055f6:	02d05763          	blez	a3,80005624 <write_head+0x5a>
    800055fa:	0001e797          	auipc	a5,0x1e
    800055fe:	94678793          	addi	a5,a5,-1722 # 80022f40 <log+0x30>
    80005602:	05c50713          	addi	a4,a0,92
    80005606:	36fd                	addiw	a3,a3,-1
    80005608:	1682                	slli	a3,a3,0x20
    8000560a:	9281                	srli	a3,a3,0x20
    8000560c:	068a                	slli	a3,a3,0x2
    8000560e:	0001e617          	auipc	a2,0x1e
    80005612:	93660613          	addi	a2,a2,-1738 # 80022f44 <log+0x34>
    80005616:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80005618:	4390                	lw	a2,0(a5)
    8000561a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000561c:	0791                	addi	a5,a5,4
    8000561e:	0711                	addi	a4,a4,4
    80005620:	fed79ce3          	bne	a5,a3,80005618 <write_head+0x4e>
  }
  bwrite(buf);
    80005624:	8526                	mv	a0,s1
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	0a4080e7          	jalr	164(ra) # 800046ca <bwrite>
  brelse(buf);
    8000562e:	8526                	mv	a0,s1
    80005630:	fffff097          	auipc	ra,0xfffff
    80005634:	0d8080e7          	jalr	216(ra) # 80004708 <brelse>
}
    80005638:	60e2                	ld	ra,24(sp)
    8000563a:	6442                	ld	s0,16(sp)
    8000563c:	64a2                	ld	s1,8(sp)
    8000563e:	6902                	ld	s2,0(sp)
    80005640:	6105                	addi	sp,sp,32
    80005642:	8082                	ret

0000000080005644 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80005644:	0001e797          	auipc	a5,0x1e
    80005648:	8f87a783          	lw	a5,-1800(a5) # 80022f3c <log+0x2c>
    8000564c:	0af05d63          	blez	a5,80005706 <install_trans+0xc2>
{
    80005650:	7139                	addi	sp,sp,-64
    80005652:	fc06                	sd	ra,56(sp)
    80005654:	f822                	sd	s0,48(sp)
    80005656:	f426                	sd	s1,40(sp)
    80005658:	f04a                	sd	s2,32(sp)
    8000565a:	ec4e                	sd	s3,24(sp)
    8000565c:	e852                	sd	s4,16(sp)
    8000565e:	e456                	sd	s5,8(sp)
    80005660:	e05a                	sd	s6,0(sp)
    80005662:	0080                	addi	s0,sp,64
    80005664:	8b2a                	mv	s6,a0
    80005666:	0001ea97          	auipc	s5,0x1e
    8000566a:	8daa8a93          	addi	s5,s5,-1830 # 80022f40 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000566e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80005670:	0001e997          	auipc	s3,0x1e
    80005674:	8a098993          	addi	s3,s3,-1888 # 80022f10 <log>
    80005678:	a035                	j	800056a4 <install_trans+0x60>
      bunpin(dbuf);
    8000567a:	8526                	mv	a0,s1
    8000567c:	fffff097          	auipc	ra,0xfffff
    80005680:	166080e7          	jalr	358(ra) # 800047e2 <bunpin>
    brelse(lbuf);
    80005684:	854a                	mv	a0,s2
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	082080e7          	jalr	130(ra) # 80004708 <brelse>
    brelse(dbuf);
    8000568e:	8526                	mv	a0,s1
    80005690:	fffff097          	auipc	ra,0xfffff
    80005694:	078080e7          	jalr	120(ra) # 80004708 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80005698:	2a05                	addiw	s4,s4,1
    8000569a:	0a91                	addi	s5,s5,4
    8000569c:	02c9a783          	lw	a5,44(s3)
    800056a0:	04fa5963          	bge	s4,a5,800056f2 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800056a4:	0189a583          	lw	a1,24(s3)
    800056a8:	014585bb          	addw	a1,a1,s4
    800056ac:	2585                	addiw	a1,a1,1
    800056ae:	0289a503          	lw	a0,40(s3)
    800056b2:	fffff097          	auipc	ra,0xfffff
    800056b6:	f26080e7          	jalr	-218(ra) # 800045d8 <bread>
    800056ba:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800056bc:	000aa583          	lw	a1,0(s5)
    800056c0:	0289a503          	lw	a0,40(s3)
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	f14080e7          	jalr	-236(ra) # 800045d8 <bread>
    800056cc:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800056ce:	40000613          	li	a2,1024
    800056d2:	05890593          	addi	a1,s2,88
    800056d6:	05850513          	addi	a0,a0,88
    800056da:	ffffb097          	auipc	ra,0xffffb
    800056de:	666080e7          	jalr	1638(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800056e2:	8526                	mv	a0,s1
    800056e4:	fffff097          	auipc	ra,0xfffff
    800056e8:	fe6080e7          	jalr	-26(ra) # 800046ca <bwrite>
    if(recovering == 0)
    800056ec:	f80b1ce3          	bnez	s6,80005684 <install_trans+0x40>
    800056f0:	b769                	j	8000567a <install_trans+0x36>
}
    800056f2:	70e2                	ld	ra,56(sp)
    800056f4:	7442                	ld	s0,48(sp)
    800056f6:	74a2                	ld	s1,40(sp)
    800056f8:	7902                	ld	s2,32(sp)
    800056fa:	69e2                	ld	s3,24(sp)
    800056fc:	6a42                	ld	s4,16(sp)
    800056fe:	6aa2                	ld	s5,8(sp)
    80005700:	6b02                	ld	s6,0(sp)
    80005702:	6121                	addi	sp,sp,64
    80005704:	8082                	ret
    80005706:	8082                	ret

0000000080005708 <initlog>:
{
    80005708:	7179                	addi	sp,sp,-48
    8000570a:	f406                	sd	ra,40(sp)
    8000570c:	f022                	sd	s0,32(sp)
    8000570e:	ec26                	sd	s1,24(sp)
    80005710:	e84a                	sd	s2,16(sp)
    80005712:	e44e                	sd	s3,8(sp)
    80005714:	1800                	addi	s0,sp,48
    80005716:	892a                	mv	s2,a0
    80005718:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000571a:	0001d497          	auipc	s1,0x1d
    8000571e:	7f648493          	addi	s1,s1,2038 # 80022f10 <log>
    80005722:	00004597          	auipc	a1,0x4
    80005726:	38658593          	addi	a1,a1,902 # 80009aa8 <syscalls+0x200>
    8000572a:	8526                	mv	a0,s1
    8000572c:	ffffb097          	auipc	ra,0xffffb
    80005730:	428080e7          	jalr	1064(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80005734:	0149a583          	lw	a1,20(s3)
    80005738:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000573a:	0109a783          	lw	a5,16(s3)
    8000573e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80005740:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80005744:	854a                	mv	a0,s2
    80005746:	fffff097          	auipc	ra,0xfffff
    8000574a:	e92080e7          	jalr	-366(ra) # 800045d8 <bread>
  log.lh.n = lh->n;
    8000574e:	4d3c                	lw	a5,88(a0)
    80005750:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80005752:	02f05563          	blez	a5,8000577c <initlog+0x74>
    80005756:	05c50713          	addi	a4,a0,92
    8000575a:	0001d697          	auipc	a3,0x1d
    8000575e:	7e668693          	addi	a3,a3,2022 # 80022f40 <log+0x30>
    80005762:	37fd                	addiw	a5,a5,-1
    80005764:	1782                	slli	a5,a5,0x20
    80005766:	9381                	srli	a5,a5,0x20
    80005768:	078a                	slli	a5,a5,0x2
    8000576a:	06050613          	addi	a2,a0,96
    8000576e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80005770:	4310                	lw	a2,0(a4)
    80005772:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80005774:	0711                	addi	a4,a4,4
    80005776:	0691                	addi	a3,a3,4
    80005778:	fef71ce3          	bne	a4,a5,80005770 <initlog+0x68>
  brelse(buf);
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	f8c080e7          	jalr	-116(ra) # 80004708 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80005784:	4505                	li	a0,1
    80005786:	00000097          	auipc	ra,0x0
    8000578a:	ebe080e7          	jalr	-322(ra) # 80005644 <install_trans>
  log.lh.n = 0;
    8000578e:	0001d797          	auipc	a5,0x1d
    80005792:	7a07a723          	sw	zero,1966(a5) # 80022f3c <log+0x2c>
  write_head(); // clear the log
    80005796:	00000097          	auipc	ra,0x0
    8000579a:	e34080e7          	jalr	-460(ra) # 800055ca <write_head>
}
    8000579e:	70a2                	ld	ra,40(sp)
    800057a0:	7402                	ld	s0,32(sp)
    800057a2:	64e2                	ld	s1,24(sp)
    800057a4:	6942                	ld	s2,16(sp)
    800057a6:	69a2                	ld	s3,8(sp)
    800057a8:	6145                	addi	sp,sp,48
    800057aa:	8082                	ret

00000000800057ac <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800057ac:	1101                	addi	sp,sp,-32
    800057ae:	ec06                	sd	ra,24(sp)
    800057b0:	e822                	sd	s0,16(sp)
    800057b2:	e426                	sd	s1,8(sp)
    800057b4:	e04a                	sd	s2,0(sp)
    800057b6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800057b8:	0001d517          	auipc	a0,0x1d
    800057bc:	75850513          	addi	a0,a0,1880 # 80022f10 <log>
    800057c0:	ffffb097          	auipc	ra,0xffffb
    800057c4:	424080e7          	jalr	1060(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800057c8:	0001d497          	auipc	s1,0x1d
    800057cc:	74848493          	addi	s1,s1,1864 # 80022f10 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800057d0:	4979                	li	s2,30
    800057d2:	a039                	j	800057e0 <begin_op+0x34>
      sleep(&log, &log.lock);
    800057d4:	85a6                	mv	a1,s1
    800057d6:	8526                	mv	a0,s1
    800057d8:	ffffd097          	auipc	ra,0xffffd
    800057dc:	54a080e7          	jalr	1354(ra) # 80002d22 <sleep>
    if(log.committing){
    800057e0:	50dc                	lw	a5,36(s1)
    800057e2:	fbed                	bnez	a5,800057d4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800057e4:	509c                	lw	a5,32(s1)
    800057e6:	0017871b          	addiw	a4,a5,1
    800057ea:	0007069b          	sext.w	a3,a4
    800057ee:	0027179b          	slliw	a5,a4,0x2
    800057f2:	9fb9                	addw	a5,a5,a4
    800057f4:	0017979b          	slliw	a5,a5,0x1
    800057f8:	54d8                	lw	a4,44(s1)
    800057fa:	9fb9                	addw	a5,a5,a4
    800057fc:	00f95963          	bge	s2,a5,8000580e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80005800:	85a6                	mv	a1,s1
    80005802:	8526                	mv	a0,s1
    80005804:	ffffd097          	auipc	ra,0xffffd
    80005808:	51e080e7          	jalr	1310(ra) # 80002d22 <sleep>
    8000580c:	bfd1                	j	800057e0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000580e:	0001d517          	auipc	a0,0x1d
    80005812:	70250513          	addi	a0,a0,1794 # 80022f10 <log>
    80005816:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80005818:	ffffb097          	auipc	ra,0xffffb
    8000581c:	480080e7          	jalr	1152(ra) # 80000c98 <release>
      break;
    }
  }
}
    80005820:	60e2                	ld	ra,24(sp)
    80005822:	6442                	ld	s0,16(sp)
    80005824:	64a2                	ld	s1,8(sp)
    80005826:	6902                	ld	s2,0(sp)
    80005828:	6105                	addi	sp,sp,32
    8000582a:	8082                	ret

000000008000582c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000582c:	7139                	addi	sp,sp,-64
    8000582e:	fc06                	sd	ra,56(sp)
    80005830:	f822                	sd	s0,48(sp)
    80005832:	f426                	sd	s1,40(sp)
    80005834:	f04a                	sd	s2,32(sp)
    80005836:	ec4e                	sd	s3,24(sp)
    80005838:	e852                	sd	s4,16(sp)
    8000583a:	e456                	sd	s5,8(sp)
    8000583c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000583e:	0001d497          	auipc	s1,0x1d
    80005842:	6d248493          	addi	s1,s1,1746 # 80022f10 <log>
    80005846:	8526                	mv	a0,s1
    80005848:	ffffb097          	auipc	ra,0xffffb
    8000584c:	39c080e7          	jalr	924(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80005850:	509c                	lw	a5,32(s1)
    80005852:	37fd                	addiw	a5,a5,-1
    80005854:	0007891b          	sext.w	s2,a5
    80005858:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000585a:	50dc                	lw	a5,36(s1)
    8000585c:	efb9                	bnez	a5,800058ba <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000585e:	06091663          	bnez	s2,800058ca <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80005862:	0001d497          	auipc	s1,0x1d
    80005866:	6ae48493          	addi	s1,s1,1710 # 80022f10 <log>
    8000586a:	4785                	li	a5,1
    8000586c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000586e:	8526                	mv	a0,s1
    80005870:	ffffb097          	auipc	ra,0xffffb
    80005874:	428080e7          	jalr	1064(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80005878:	54dc                	lw	a5,44(s1)
    8000587a:	06f04763          	bgtz	a5,800058e8 <end_op+0xbc>
    acquire(&log.lock);
    8000587e:	0001d497          	auipc	s1,0x1d
    80005882:	69248493          	addi	s1,s1,1682 # 80022f10 <log>
    80005886:	8526                	mv	a0,s1
    80005888:	ffffb097          	auipc	ra,0xffffb
    8000588c:	35c080e7          	jalr	860(ra) # 80000be4 <acquire>
    log.committing = 0;
    80005890:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80005894:	8526                	mv	a0,s1
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	8a2080e7          	jalr	-1886(ra) # 80003138 <wakeup>
    release(&log.lock);
    8000589e:	8526                	mv	a0,s1
    800058a0:	ffffb097          	auipc	ra,0xffffb
    800058a4:	3f8080e7          	jalr	1016(ra) # 80000c98 <release>
}
    800058a8:	70e2                	ld	ra,56(sp)
    800058aa:	7442                	ld	s0,48(sp)
    800058ac:	74a2                	ld	s1,40(sp)
    800058ae:	7902                	ld	s2,32(sp)
    800058b0:	69e2                	ld	s3,24(sp)
    800058b2:	6a42                	ld	s4,16(sp)
    800058b4:	6aa2                	ld	s5,8(sp)
    800058b6:	6121                	addi	sp,sp,64
    800058b8:	8082                	ret
    panic("log.committing");
    800058ba:	00004517          	auipc	a0,0x4
    800058be:	1f650513          	addi	a0,a0,502 # 80009ab0 <syscalls+0x208>
    800058c2:	ffffb097          	auipc	ra,0xffffb
    800058c6:	c7c080e7          	jalr	-900(ra) # 8000053e <panic>
    wakeup(&log);
    800058ca:	0001d497          	auipc	s1,0x1d
    800058ce:	64648493          	addi	s1,s1,1606 # 80022f10 <log>
    800058d2:	8526                	mv	a0,s1
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	864080e7          	jalr	-1948(ra) # 80003138 <wakeup>
  release(&log.lock);
    800058dc:	8526                	mv	a0,s1
    800058de:	ffffb097          	auipc	ra,0xffffb
    800058e2:	3ba080e7          	jalr	954(ra) # 80000c98 <release>
  if(do_commit){
    800058e6:	b7c9                	j	800058a8 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800058e8:	0001da97          	auipc	s5,0x1d
    800058ec:	658a8a93          	addi	s5,s5,1624 # 80022f40 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800058f0:	0001da17          	auipc	s4,0x1d
    800058f4:	620a0a13          	addi	s4,s4,1568 # 80022f10 <log>
    800058f8:	018a2583          	lw	a1,24(s4)
    800058fc:	012585bb          	addw	a1,a1,s2
    80005900:	2585                	addiw	a1,a1,1
    80005902:	028a2503          	lw	a0,40(s4)
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	cd2080e7          	jalr	-814(ra) # 800045d8 <bread>
    8000590e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80005910:	000aa583          	lw	a1,0(s5)
    80005914:	028a2503          	lw	a0,40(s4)
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	cc0080e7          	jalr	-832(ra) # 800045d8 <bread>
    80005920:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80005922:	40000613          	li	a2,1024
    80005926:	05850593          	addi	a1,a0,88
    8000592a:	05848513          	addi	a0,s1,88
    8000592e:	ffffb097          	auipc	ra,0xffffb
    80005932:	412080e7          	jalr	1042(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80005936:	8526                	mv	a0,s1
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	d92080e7          	jalr	-622(ra) # 800046ca <bwrite>
    brelse(from);
    80005940:	854e                	mv	a0,s3
    80005942:	fffff097          	auipc	ra,0xfffff
    80005946:	dc6080e7          	jalr	-570(ra) # 80004708 <brelse>
    brelse(to);
    8000594a:	8526                	mv	a0,s1
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	dbc080e7          	jalr	-580(ra) # 80004708 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80005954:	2905                	addiw	s2,s2,1
    80005956:	0a91                	addi	s5,s5,4
    80005958:	02ca2783          	lw	a5,44(s4)
    8000595c:	f8f94ee3          	blt	s2,a5,800058f8 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80005960:	00000097          	auipc	ra,0x0
    80005964:	c6a080e7          	jalr	-918(ra) # 800055ca <write_head>
    install_trans(0); // Now install writes to home locations
    80005968:	4501                	li	a0,0
    8000596a:	00000097          	auipc	ra,0x0
    8000596e:	cda080e7          	jalr	-806(ra) # 80005644 <install_trans>
    log.lh.n = 0;
    80005972:	0001d797          	auipc	a5,0x1d
    80005976:	5c07a523          	sw	zero,1482(a5) # 80022f3c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000597a:	00000097          	auipc	ra,0x0
    8000597e:	c50080e7          	jalr	-944(ra) # 800055ca <write_head>
    80005982:	bdf5                	j	8000587e <end_op+0x52>

0000000080005984 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80005984:	1101                	addi	sp,sp,-32
    80005986:	ec06                	sd	ra,24(sp)
    80005988:	e822                	sd	s0,16(sp)
    8000598a:	e426                	sd	s1,8(sp)
    8000598c:	e04a                	sd	s2,0(sp)
    8000598e:	1000                	addi	s0,sp,32
    80005990:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80005992:	0001d917          	auipc	s2,0x1d
    80005996:	57e90913          	addi	s2,s2,1406 # 80022f10 <log>
    8000599a:	854a                	mv	a0,s2
    8000599c:	ffffb097          	auipc	ra,0xffffb
    800059a0:	248080e7          	jalr	584(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800059a4:	02c92603          	lw	a2,44(s2)
    800059a8:	47f5                	li	a5,29
    800059aa:	06c7c563          	blt	a5,a2,80005a14 <log_write+0x90>
    800059ae:	0001d797          	auipc	a5,0x1d
    800059b2:	57e7a783          	lw	a5,1406(a5) # 80022f2c <log+0x1c>
    800059b6:	37fd                	addiw	a5,a5,-1
    800059b8:	04f65e63          	bge	a2,a5,80005a14 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800059bc:	0001d797          	auipc	a5,0x1d
    800059c0:	5747a783          	lw	a5,1396(a5) # 80022f30 <log+0x20>
    800059c4:	06f05063          	blez	a5,80005a24 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800059c8:	4781                	li	a5,0
    800059ca:	06c05563          	blez	a2,80005a34 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800059ce:	44cc                	lw	a1,12(s1)
    800059d0:	0001d717          	auipc	a4,0x1d
    800059d4:	57070713          	addi	a4,a4,1392 # 80022f40 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800059d8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800059da:	4314                	lw	a3,0(a4)
    800059dc:	04b68c63          	beq	a3,a1,80005a34 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800059e0:	2785                	addiw	a5,a5,1
    800059e2:	0711                	addi	a4,a4,4
    800059e4:	fef61be3          	bne	a2,a5,800059da <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800059e8:	0621                	addi	a2,a2,8
    800059ea:	060a                	slli	a2,a2,0x2
    800059ec:	0001d797          	auipc	a5,0x1d
    800059f0:	52478793          	addi	a5,a5,1316 # 80022f10 <log>
    800059f4:	963e                	add	a2,a2,a5
    800059f6:	44dc                	lw	a5,12(s1)
    800059f8:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800059fa:	8526                	mv	a0,s1
    800059fc:	fffff097          	auipc	ra,0xfffff
    80005a00:	daa080e7          	jalr	-598(ra) # 800047a6 <bpin>
    log.lh.n++;
    80005a04:	0001d717          	auipc	a4,0x1d
    80005a08:	50c70713          	addi	a4,a4,1292 # 80022f10 <log>
    80005a0c:	575c                	lw	a5,44(a4)
    80005a0e:	2785                	addiw	a5,a5,1
    80005a10:	d75c                	sw	a5,44(a4)
    80005a12:	a835                	j	80005a4e <log_write+0xca>
    panic("too big a transaction");
    80005a14:	00004517          	auipc	a0,0x4
    80005a18:	0ac50513          	addi	a0,a0,172 # 80009ac0 <syscalls+0x218>
    80005a1c:	ffffb097          	auipc	ra,0xffffb
    80005a20:	b22080e7          	jalr	-1246(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80005a24:	00004517          	auipc	a0,0x4
    80005a28:	0b450513          	addi	a0,a0,180 # 80009ad8 <syscalls+0x230>
    80005a2c:	ffffb097          	auipc	ra,0xffffb
    80005a30:	b12080e7          	jalr	-1262(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80005a34:	00878713          	addi	a4,a5,8
    80005a38:	00271693          	slli	a3,a4,0x2
    80005a3c:	0001d717          	auipc	a4,0x1d
    80005a40:	4d470713          	addi	a4,a4,1236 # 80022f10 <log>
    80005a44:	9736                	add	a4,a4,a3
    80005a46:	44d4                	lw	a3,12(s1)
    80005a48:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80005a4a:	faf608e3          	beq	a2,a5,800059fa <log_write+0x76>
  }
  release(&log.lock);
    80005a4e:	0001d517          	auipc	a0,0x1d
    80005a52:	4c250513          	addi	a0,a0,1218 # 80022f10 <log>
    80005a56:	ffffb097          	auipc	ra,0xffffb
    80005a5a:	242080e7          	jalr	578(ra) # 80000c98 <release>
}
    80005a5e:	60e2                	ld	ra,24(sp)
    80005a60:	6442                	ld	s0,16(sp)
    80005a62:	64a2                	ld	s1,8(sp)
    80005a64:	6902                	ld	s2,0(sp)
    80005a66:	6105                	addi	sp,sp,32
    80005a68:	8082                	ret

0000000080005a6a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80005a6a:	1101                	addi	sp,sp,-32
    80005a6c:	ec06                	sd	ra,24(sp)
    80005a6e:	e822                	sd	s0,16(sp)
    80005a70:	e426                	sd	s1,8(sp)
    80005a72:	e04a                	sd	s2,0(sp)
    80005a74:	1000                	addi	s0,sp,32
    80005a76:	84aa                	mv	s1,a0
    80005a78:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80005a7a:	00004597          	auipc	a1,0x4
    80005a7e:	07e58593          	addi	a1,a1,126 # 80009af8 <syscalls+0x250>
    80005a82:	0521                	addi	a0,a0,8
    80005a84:	ffffb097          	auipc	ra,0xffffb
    80005a88:	0d0080e7          	jalr	208(ra) # 80000b54 <initlock>
  lk->name = name;
    80005a8c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80005a90:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005a94:	0204a423          	sw	zero,40(s1)
}
    80005a98:	60e2                	ld	ra,24(sp)
    80005a9a:	6442                	ld	s0,16(sp)
    80005a9c:	64a2                	ld	s1,8(sp)
    80005a9e:	6902                	ld	s2,0(sp)
    80005aa0:	6105                	addi	sp,sp,32
    80005aa2:	8082                	ret

0000000080005aa4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80005aa4:	1101                	addi	sp,sp,-32
    80005aa6:	ec06                	sd	ra,24(sp)
    80005aa8:	e822                	sd	s0,16(sp)
    80005aaa:	e426                	sd	s1,8(sp)
    80005aac:	e04a                	sd	s2,0(sp)
    80005aae:	1000                	addi	s0,sp,32
    80005ab0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005ab2:	00850913          	addi	s2,a0,8
    80005ab6:	854a                	mv	a0,s2
    80005ab8:	ffffb097          	auipc	ra,0xffffb
    80005abc:	12c080e7          	jalr	300(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80005ac0:	409c                	lw	a5,0(s1)
    80005ac2:	cb89                	beqz	a5,80005ad4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80005ac4:	85ca                	mv	a1,s2
    80005ac6:	8526                	mv	a0,s1
    80005ac8:	ffffd097          	auipc	ra,0xffffd
    80005acc:	25a080e7          	jalr	602(ra) # 80002d22 <sleep>
  while (lk->locked) {
    80005ad0:	409c                	lw	a5,0(s1)
    80005ad2:	fbed                	bnez	a5,80005ac4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80005ad4:	4785                	li	a5,1
    80005ad6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80005ad8:	ffffc097          	auipc	ra,0xffffc
    80005adc:	0ec080e7          	jalr	236(ra) # 80001bc4 <myproc>
    80005ae0:	591c                	lw	a5,48(a0)
    80005ae2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80005ae4:	854a                	mv	a0,s2
    80005ae6:	ffffb097          	auipc	ra,0xffffb
    80005aea:	1b2080e7          	jalr	434(ra) # 80000c98 <release>
}
    80005aee:	60e2                	ld	ra,24(sp)
    80005af0:	6442                	ld	s0,16(sp)
    80005af2:	64a2                	ld	s1,8(sp)
    80005af4:	6902                	ld	s2,0(sp)
    80005af6:	6105                	addi	sp,sp,32
    80005af8:	8082                	ret

0000000080005afa <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80005afa:	1101                	addi	sp,sp,-32
    80005afc:	ec06                	sd	ra,24(sp)
    80005afe:	e822                	sd	s0,16(sp)
    80005b00:	e426                	sd	s1,8(sp)
    80005b02:	e04a                	sd	s2,0(sp)
    80005b04:	1000                	addi	s0,sp,32
    80005b06:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005b08:	00850913          	addi	s2,a0,8
    80005b0c:	854a                	mv	a0,s2
    80005b0e:	ffffb097          	auipc	ra,0xffffb
    80005b12:	0d6080e7          	jalr	214(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80005b16:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005b1a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80005b1e:	8526                	mv	a0,s1
    80005b20:	ffffd097          	auipc	ra,0xffffd
    80005b24:	618080e7          	jalr	1560(ra) # 80003138 <wakeup>
  release(&lk->lk);
    80005b28:	854a                	mv	a0,s2
    80005b2a:	ffffb097          	auipc	ra,0xffffb
    80005b2e:	16e080e7          	jalr	366(ra) # 80000c98 <release>
}
    80005b32:	60e2                	ld	ra,24(sp)
    80005b34:	6442                	ld	s0,16(sp)
    80005b36:	64a2                	ld	s1,8(sp)
    80005b38:	6902                	ld	s2,0(sp)
    80005b3a:	6105                	addi	sp,sp,32
    80005b3c:	8082                	ret

0000000080005b3e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80005b3e:	7179                	addi	sp,sp,-48
    80005b40:	f406                	sd	ra,40(sp)
    80005b42:	f022                	sd	s0,32(sp)
    80005b44:	ec26                	sd	s1,24(sp)
    80005b46:	e84a                	sd	s2,16(sp)
    80005b48:	e44e                	sd	s3,8(sp)
    80005b4a:	1800                	addi	s0,sp,48
    80005b4c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80005b4e:	00850913          	addi	s2,a0,8
    80005b52:	854a                	mv	a0,s2
    80005b54:	ffffb097          	auipc	ra,0xffffb
    80005b58:	090080e7          	jalr	144(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80005b5c:	409c                	lw	a5,0(s1)
    80005b5e:	ef99                	bnez	a5,80005b7c <holdingsleep+0x3e>
    80005b60:	4481                	li	s1,0
  release(&lk->lk);
    80005b62:	854a                	mv	a0,s2
    80005b64:	ffffb097          	auipc	ra,0xffffb
    80005b68:	134080e7          	jalr	308(ra) # 80000c98 <release>
  return r;
}
    80005b6c:	8526                	mv	a0,s1
    80005b6e:	70a2                	ld	ra,40(sp)
    80005b70:	7402                	ld	s0,32(sp)
    80005b72:	64e2                	ld	s1,24(sp)
    80005b74:	6942                	ld	s2,16(sp)
    80005b76:	69a2                	ld	s3,8(sp)
    80005b78:	6145                	addi	sp,sp,48
    80005b7a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80005b7c:	0284a983          	lw	s3,40(s1)
    80005b80:	ffffc097          	auipc	ra,0xffffc
    80005b84:	044080e7          	jalr	68(ra) # 80001bc4 <myproc>
    80005b88:	5904                	lw	s1,48(a0)
    80005b8a:	413484b3          	sub	s1,s1,s3
    80005b8e:	0014b493          	seqz	s1,s1
    80005b92:	bfc1                	j	80005b62 <holdingsleep+0x24>

0000000080005b94 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80005b94:	1141                	addi	sp,sp,-16
    80005b96:	e406                	sd	ra,8(sp)
    80005b98:	e022                	sd	s0,0(sp)
    80005b9a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005b9c:	00004597          	auipc	a1,0x4
    80005ba0:	f6c58593          	addi	a1,a1,-148 # 80009b08 <syscalls+0x260>
    80005ba4:	0001d517          	auipc	a0,0x1d
    80005ba8:	4b450513          	addi	a0,a0,1204 # 80023058 <ftable>
    80005bac:	ffffb097          	auipc	ra,0xffffb
    80005bb0:	fa8080e7          	jalr	-88(ra) # 80000b54 <initlock>
}
    80005bb4:	60a2                	ld	ra,8(sp)
    80005bb6:	6402                	ld	s0,0(sp)
    80005bb8:	0141                	addi	sp,sp,16
    80005bba:	8082                	ret

0000000080005bbc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80005bbc:	1101                	addi	sp,sp,-32
    80005bbe:	ec06                	sd	ra,24(sp)
    80005bc0:	e822                	sd	s0,16(sp)
    80005bc2:	e426                	sd	s1,8(sp)
    80005bc4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80005bc6:	0001d517          	auipc	a0,0x1d
    80005bca:	49250513          	addi	a0,a0,1170 # 80023058 <ftable>
    80005bce:	ffffb097          	auipc	ra,0xffffb
    80005bd2:	016080e7          	jalr	22(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005bd6:	0001d497          	auipc	s1,0x1d
    80005bda:	49a48493          	addi	s1,s1,1178 # 80023070 <ftable+0x18>
    80005bde:	0001e717          	auipc	a4,0x1e
    80005be2:	43270713          	addi	a4,a4,1074 # 80024010 <ftable+0xfb8>
    if(f->ref == 0){
    80005be6:	40dc                	lw	a5,4(s1)
    80005be8:	cf99                	beqz	a5,80005c06 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005bea:	02848493          	addi	s1,s1,40
    80005bee:	fee49ce3          	bne	s1,a4,80005be6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80005bf2:	0001d517          	auipc	a0,0x1d
    80005bf6:	46650513          	addi	a0,a0,1126 # 80023058 <ftable>
    80005bfa:	ffffb097          	auipc	ra,0xffffb
    80005bfe:	09e080e7          	jalr	158(ra) # 80000c98 <release>
  return 0;
    80005c02:	4481                	li	s1,0
    80005c04:	a819                	j	80005c1a <filealloc+0x5e>
      f->ref = 1;
    80005c06:	4785                	li	a5,1
    80005c08:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005c0a:	0001d517          	auipc	a0,0x1d
    80005c0e:	44e50513          	addi	a0,a0,1102 # 80023058 <ftable>
    80005c12:	ffffb097          	auipc	ra,0xffffb
    80005c16:	086080e7          	jalr	134(ra) # 80000c98 <release>
}
    80005c1a:	8526                	mv	a0,s1
    80005c1c:	60e2                	ld	ra,24(sp)
    80005c1e:	6442                	ld	s0,16(sp)
    80005c20:	64a2                	ld	s1,8(sp)
    80005c22:	6105                	addi	sp,sp,32
    80005c24:	8082                	ret

0000000080005c26 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005c26:	1101                	addi	sp,sp,-32
    80005c28:	ec06                	sd	ra,24(sp)
    80005c2a:	e822                	sd	s0,16(sp)
    80005c2c:	e426                	sd	s1,8(sp)
    80005c2e:	1000                	addi	s0,sp,32
    80005c30:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005c32:	0001d517          	auipc	a0,0x1d
    80005c36:	42650513          	addi	a0,a0,1062 # 80023058 <ftable>
    80005c3a:	ffffb097          	auipc	ra,0xffffb
    80005c3e:	faa080e7          	jalr	-86(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80005c42:	40dc                	lw	a5,4(s1)
    80005c44:	02f05263          	blez	a5,80005c68 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005c48:	2785                	addiw	a5,a5,1
    80005c4a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005c4c:	0001d517          	auipc	a0,0x1d
    80005c50:	40c50513          	addi	a0,a0,1036 # 80023058 <ftable>
    80005c54:	ffffb097          	auipc	ra,0xffffb
    80005c58:	044080e7          	jalr	68(ra) # 80000c98 <release>
  return f;
}
    80005c5c:	8526                	mv	a0,s1
    80005c5e:	60e2                	ld	ra,24(sp)
    80005c60:	6442                	ld	s0,16(sp)
    80005c62:	64a2                	ld	s1,8(sp)
    80005c64:	6105                	addi	sp,sp,32
    80005c66:	8082                	ret
    panic("filedup");
    80005c68:	00004517          	auipc	a0,0x4
    80005c6c:	ea850513          	addi	a0,a0,-344 # 80009b10 <syscalls+0x268>
    80005c70:	ffffb097          	auipc	ra,0xffffb
    80005c74:	8ce080e7          	jalr	-1842(ra) # 8000053e <panic>

0000000080005c78 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005c78:	7139                	addi	sp,sp,-64
    80005c7a:	fc06                	sd	ra,56(sp)
    80005c7c:	f822                	sd	s0,48(sp)
    80005c7e:	f426                	sd	s1,40(sp)
    80005c80:	f04a                	sd	s2,32(sp)
    80005c82:	ec4e                	sd	s3,24(sp)
    80005c84:	e852                	sd	s4,16(sp)
    80005c86:	e456                	sd	s5,8(sp)
    80005c88:	0080                	addi	s0,sp,64
    80005c8a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005c8c:	0001d517          	auipc	a0,0x1d
    80005c90:	3cc50513          	addi	a0,a0,972 # 80023058 <ftable>
    80005c94:	ffffb097          	auipc	ra,0xffffb
    80005c98:	f50080e7          	jalr	-176(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80005c9c:	40dc                	lw	a5,4(s1)
    80005c9e:	06f05163          	blez	a5,80005d00 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005ca2:	37fd                	addiw	a5,a5,-1
    80005ca4:	0007871b          	sext.w	a4,a5
    80005ca8:	c0dc                	sw	a5,4(s1)
    80005caa:	06e04363          	bgtz	a4,80005d10 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005cae:	0004a903          	lw	s2,0(s1)
    80005cb2:	0094ca83          	lbu	s5,9(s1)
    80005cb6:	0104ba03          	ld	s4,16(s1)
    80005cba:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005cbe:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005cc2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005cc6:	0001d517          	auipc	a0,0x1d
    80005cca:	39250513          	addi	a0,a0,914 # 80023058 <ftable>
    80005cce:	ffffb097          	auipc	ra,0xffffb
    80005cd2:	fca080e7          	jalr	-54(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80005cd6:	4785                	li	a5,1
    80005cd8:	04f90d63          	beq	s2,a5,80005d32 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005cdc:	3979                	addiw	s2,s2,-2
    80005cde:	4785                	li	a5,1
    80005ce0:	0527e063          	bltu	a5,s2,80005d20 <fileclose+0xa8>
    begin_op();
    80005ce4:	00000097          	auipc	ra,0x0
    80005ce8:	ac8080e7          	jalr	-1336(ra) # 800057ac <begin_op>
    iput(ff.ip);
    80005cec:	854e                	mv	a0,s3
    80005cee:	fffff097          	auipc	ra,0xfffff
    80005cf2:	2a6080e7          	jalr	678(ra) # 80004f94 <iput>
    end_op();
    80005cf6:	00000097          	auipc	ra,0x0
    80005cfa:	b36080e7          	jalr	-1226(ra) # 8000582c <end_op>
    80005cfe:	a00d                	j	80005d20 <fileclose+0xa8>
    panic("fileclose");
    80005d00:	00004517          	auipc	a0,0x4
    80005d04:	e1850513          	addi	a0,a0,-488 # 80009b18 <syscalls+0x270>
    80005d08:	ffffb097          	auipc	ra,0xffffb
    80005d0c:	836080e7          	jalr	-1994(ra) # 8000053e <panic>
    release(&ftable.lock);
    80005d10:	0001d517          	auipc	a0,0x1d
    80005d14:	34850513          	addi	a0,a0,840 # 80023058 <ftable>
    80005d18:	ffffb097          	auipc	ra,0xffffb
    80005d1c:	f80080e7          	jalr	-128(ra) # 80000c98 <release>
  }
}
    80005d20:	70e2                	ld	ra,56(sp)
    80005d22:	7442                	ld	s0,48(sp)
    80005d24:	74a2                	ld	s1,40(sp)
    80005d26:	7902                	ld	s2,32(sp)
    80005d28:	69e2                	ld	s3,24(sp)
    80005d2a:	6a42                	ld	s4,16(sp)
    80005d2c:	6aa2                	ld	s5,8(sp)
    80005d2e:	6121                	addi	sp,sp,64
    80005d30:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005d32:	85d6                	mv	a1,s5
    80005d34:	8552                	mv	a0,s4
    80005d36:	00000097          	auipc	ra,0x0
    80005d3a:	34c080e7          	jalr	844(ra) # 80006082 <pipeclose>
    80005d3e:	b7cd                	j	80005d20 <fileclose+0xa8>

0000000080005d40 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005d40:	715d                	addi	sp,sp,-80
    80005d42:	e486                	sd	ra,72(sp)
    80005d44:	e0a2                	sd	s0,64(sp)
    80005d46:	fc26                	sd	s1,56(sp)
    80005d48:	f84a                	sd	s2,48(sp)
    80005d4a:	f44e                	sd	s3,40(sp)
    80005d4c:	0880                	addi	s0,sp,80
    80005d4e:	84aa                	mv	s1,a0
    80005d50:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005d52:	ffffc097          	auipc	ra,0xffffc
    80005d56:	e72080e7          	jalr	-398(ra) # 80001bc4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005d5a:	409c                	lw	a5,0(s1)
    80005d5c:	37f9                	addiw	a5,a5,-2
    80005d5e:	4705                	li	a4,1
    80005d60:	04f76763          	bltu	a4,a5,80005dae <filestat+0x6e>
    80005d64:	892a                	mv	s2,a0
    ilock(f->ip);
    80005d66:	6c88                	ld	a0,24(s1)
    80005d68:	fffff097          	auipc	ra,0xfffff
    80005d6c:	072080e7          	jalr	114(ra) # 80004dda <ilock>
    stati(f->ip, &st);
    80005d70:	fb840593          	addi	a1,s0,-72
    80005d74:	6c88                	ld	a0,24(s1)
    80005d76:	fffff097          	auipc	ra,0xfffff
    80005d7a:	2ee080e7          	jalr	750(ra) # 80005064 <stati>
    iunlock(f->ip);
    80005d7e:	6c88                	ld	a0,24(s1)
    80005d80:	fffff097          	auipc	ra,0xfffff
    80005d84:	11c080e7          	jalr	284(ra) # 80004e9c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005d88:	46e1                	li	a3,24
    80005d8a:	fb840613          	addi	a2,s0,-72
    80005d8e:	85ce                	mv	a1,s3
    80005d90:	08093503          	ld	a0,128(s2)
    80005d94:	ffffc097          	auipc	ra,0xffffc
    80005d98:	8e6080e7          	jalr	-1818(ra) # 8000167a <copyout>
    80005d9c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005da0:	60a6                	ld	ra,72(sp)
    80005da2:	6406                	ld	s0,64(sp)
    80005da4:	74e2                	ld	s1,56(sp)
    80005da6:	7942                	ld	s2,48(sp)
    80005da8:	79a2                	ld	s3,40(sp)
    80005daa:	6161                	addi	sp,sp,80
    80005dac:	8082                	ret
  return -1;
    80005dae:	557d                	li	a0,-1
    80005db0:	bfc5                	j	80005da0 <filestat+0x60>

0000000080005db2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005db2:	7179                	addi	sp,sp,-48
    80005db4:	f406                	sd	ra,40(sp)
    80005db6:	f022                	sd	s0,32(sp)
    80005db8:	ec26                	sd	s1,24(sp)
    80005dba:	e84a                	sd	s2,16(sp)
    80005dbc:	e44e                	sd	s3,8(sp)
    80005dbe:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005dc0:	00854783          	lbu	a5,8(a0)
    80005dc4:	c3d5                	beqz	a5,80005e68 <fileread+0xb6>
    80005dc6:	84aa                	mv	s1,a0
    80005dc8:	89ae                	mv	s3,a1
    80005dca:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005dcc:	411c                	lw	a5,0(a0)
    80005dce:	4705                	li	a4,1
    80005dd0:	04e78963          	beq	a5,a4,80005e22 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005dd4:	470d                	li	a4,3
    80005dd6:	04e78d63          	beq	a5,a4,80005e30 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005dda:	4709                	li	a4,2
    80005ddc:	06e79e63          	bne	a5,a4,80005e58 <fileread+0xa6>
    ilock(f->ip);
    80005de0:	6d08                	ld	a0,24(a0)
    80005de2:	fffff097          	auipc	ra,0xfffff
    80005de6:	ff8080e7          	jalr	-8(ra) # 80004dda <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005dea:	874a                	mv	a4,s2
    80005dec:	5094                	lw	a3,32(s1)
    80005dee:	864e                	mv	a2,s3
    80005df0:	4585                	li	a1,1
    80005df2:	6c88                	ld	a0,24(s1)
    80005df4:	fffff097          	auipc	ra,0xfffff
    80005df8:	29a080e7          	jalr	666(ra) # 8000508e <readi>
    80005dfc:	892a                	mv	s2,a0
    80005dfe:	00a05563          	blez	a0,80005e08 <fileread+0x56>
      f->off += r;
    80005e02:	509c                	lw	a5,32(s1)
    80005e04:	9fa9                	addw	a5,a5,a0
    80005e06:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005e08:	6c88                	ld	a0,24(s1)
    80005e0a:	fffff097          	auipc	ra,0xfffff
    80005e0e:	092080e7          	jalr	146(ra) # 80004e9c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005e12:	854a                	mv	a0,s2
    80005e14:	70a2                	ld	ra,40(sp)
    80005e16:	7402                	ld	s0,32(sp)
    80005e18:	64e2                	ld	s1,24(sp)
    80005e1a:	6942                	ld	s2,16(sp)
    80005e1c:	69a2                	ld	s3,8(sp)
    80005e1e:	6145                	addi	sp,sp,48
    80005e20:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005e22:	6908                	ld	a0,16(a0)
    80005e24:	00000097          	auipc	ra,0x0
    80005e28:	3c8080e7          	jalr	968(ra) # 800061ec <piperead>
    80005e2c:	892a                	mv	s2,a0
    80005e2e:	b7d5                	j	80005e12 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005e30:	02451783          	lh	a5,36(a0)
    80005e34:	03079693          	slli	a3,a5,0x30
    80005e38:	92c1                	srli	a3,a3,0x30
    80005e3a:	4725                	li	a4,9
    80005e3c:	02d76863          	bltu	a4,a3,80005e6c <fileread+0xba>
    80005e40:	0792                	slli	a5,a5,0x4
    80005e42:	0001d717          	auipc	a4,0x1d
    80005e46:	17670713          	addi	a4,a4,374 # 80022fb8 <devsw>
    80005e4a:	97ba                	add	a5,a5,a4
    80005e4c:	639c                	ld	a5,0(a5)
    80005e4e:	c38d                	beqz	a5,80005e70 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005e50:	4505                	li	a0,1
    80005e52:	9782                	jalr	a5
    80005e54:	892a                	mv	s2,a0
    80005e56:	bf75                	j	80005e12 <fileread+0x60>
    panic("fileread");
    80005e58:	00004517          	auipc	a0,0x4
    80005e5c:	cd050513          	addi	a0,a0,-816 # 80009b28 <syscalls+0x280>
    80005e60:	ffffa097          	auipc	ra,0xffffa
    80005e64:	6de080e7          	jalr	1758(ra) # 8000053e <panic>
    return -1;
    80005e68:	597d                	li	s2,-1
    80005e6a:	b765                	j	80005e12 <fileread+0x60>
      return -1;
    80005e6c:	597d                	li	s2,-1
    80005e6e:	b755                	j	80005e12 <fileread+0x60>
    80005e70:	597d                	li	s2,-1
    80005e72:	b745                	j	80005e12 <fileread+0x60>

0000000080005e74 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005e74:	715d                	addi	sp,sp,-80
    80005e76:	e486                	sd	ra,72(sp)
    80005e78:	e0a2                	sd	s0,64(sp)
    80005e7a:	fc26                	sd	s1,56(sp)
    80005e7c:	f84a                	sd	s2,48(sp)
    80005e7e:	f44e                	sd	s3,40(sp)
    80005e80:	f052                	sd	s4,32(sp)
    80005e82:	ec56                	sd	s5,24(sp)
    80005e84:	e85a                	sd	s6,16(sp)
    80005e86:	e45e                	sd	s7,8(sp)
    80005e88:	e062                	sd	s8,0(sp)
    80005e8a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005e8c:	00954783          	lbu	a5,9(a0)
    80005e90:	10078663          	beqz	a5,80005f9c <filewrite+0x128>
    80005e94:	892a                	mv	s2,a0
    80005e96:	8aae                	mv	s5,a1
    80005e98:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005e9a:	411c                	lw	a5,0(a0)
    80005e9c:	4705                	li	a4,1
    80005e9e:	02e78263          	beq	a5,a4,80005ec2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005ea2:	470d                	li	a4,3
    80005ea4:	02e78663          	beq	a5,a4,80005ed0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005ea8:	4709                	li	a4,2
    80005eaa:	0ee79163          	bne	a5,a4,80005f8c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005eae:	0ac05d63          	blez	a2,80005f68 <filewrite+0xf4>
    int i = 0;
    80005eb2:	4981                	li	s3,0
    80005eb4:	6b05                	lui	s6,0x1
    80005eb6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005eba:	6b85                	lui	s7,0x1
    80005ebc:	c00b8b9b          	addiw	s7,s7,-1024
    80005ec0:	a861                	j	80005f58 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005ec2:	6908                	ld	a0,16(a0)
    80005ec4:	00000097          	auipc	ra,0x0
    80005ec8:	22e080e7          	jalr	558(ra) # 800060f2 <pipewrite>
    80005ecc:	8a2a                	mv	s4,a0
    80005ece:	a045                	j	80005f6e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005ed0:	02451783          	lh	a5,36(a0)
    80005ed4:	03079693          	slli	a3,a5,0x30
    80005ed8:	92c1                	srli	a3,a3,0x30
    80005eda:	4725                	li	a4,9
    80005edc:	0cd76263          	bltu	a4,a3,80005fa0 <filewrite+0x12c>
    80005ee0:	0792                	slli	a5,a5,0x4
    80005ee2:	0001d717          	auipc	a4,0x1d
    80005ee6:	0d670713          	addi	a4,a4,214 # 80022fb8 <devsw>
    80005eea:	97ba                	add	a5,a5,a4
    80005eec:	679c                	ld	a5,8(a5)
    80005eee:	cbdd                	beqz	a5,80005fa4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005ef0:	4505                	li	a0,1
    80005ef2:	9782                	jalr	a5
    80005ef4:	8a2a                	mv	s4,a0
    80005ef6:	a8a5                	j	80005f6e <filewrite+0xfa>
    80005ef8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005efc:	00000097          	auipc	ra,0x0
    80005f00:	8b0080e7          	jalr	-1872(ra) # 800057ac <begin_op>
      ilock(f->ip);
    80005f04:	01893503          	ld	a0,24(s2)
    80005f08:	fffff097          	auipc	ra,0xfffff
    80005f0c:	ed2080e7          	jalr	-302(ra) # 80004dda <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005f10:	8762                	mv	a4,s8
    80005f12:	02092683          	lw	a3,32(s2)
    80005f16:	01598633          	add	a2,s3,s5
    80005f1a:	4585                	li	a1,1
    80005f1c:	01893503          	ld	a0,24(s2)
    80005f20:	fffff097          	auipc	ra,0xfffff
    80005f24:	266080e7          	jalr	614(ra) # 80005186 <writei>
    80005f28:	84aa                	mv	s1,a0
    80005f2a:	00a05763          	blez	a0,80005f38 <filewrite+0xc4>
        f->off += r;
    80005f2e:	02092783          	lw	a5,32(s2)
    80005f32:	9fa9                	addw	a5,a5,a0
    80005f34:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005f38:	01893503          	ld	a0,24(s2)
    80005f3c:	fffff097          	auipc	ra,0xfffff
    80005f40:	f60080e7          	jalr	-160(ra) # 80004e9c <iunlock>
      end_op();
    80005f44:	00000097          	auipc	ra,0x0
    80005f48:	8e8080e7          	jalr	-1816(ra) # 8000582c <end_op>

      if(r != n1){
    80005f4c:	009c1f63          	bne	s8,s1,80005f6a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005f50:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005f54:	0149db63          	bge	s3,s4,80005f6a <filewrite+0xf6>
      int n1 = n - i;
    80005f58:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005f5c:	84be                	mv	s1,a5
    80005f5e:	2781                	sext.w	a5,a5
    80005f60:	f8fb5ce3          	bge	s6,a5,80005ef8 <filewrite+0x84>
    80005f64:	84de                	mv	s1,s7
    80005f66:	bf49                	j	80005ef8 <filewrite+0x84>
    int i = 0;
    80005f68:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005f6a:	013a1f63          	bne	s4,s3,80005f88 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005f6e:	8552                	mv	a0,s4
    80005f70:	60a6                	ld	ra,72(sp)
    80005f72:	6406                	ld	s0,64(sp)
    80005f74:	74e2                	ld	s1,56(sp)
    80005f76:	7942                	ld	s2,48(sp)
    80005f78:	79a2                	ld	s3,40(sp)
    80005f7a:	7a02                	ld	s4,32(sp)
    80005f7c:	6ae2                	ld	s5,24(sp)
    80005f7e:	6b42                	ld	s6,16(sp)
    80005f80:	6ba2                	ld	s7,8(sp)
    80005f82:	6c02                	ld	s8,0(sp)
    80005f84:	6161                	addi	sp,sp,80
    80005f86:	8082                	ret
    ret = (i == n ? n : -1);
    80005f88:	5a7d                	li	s4,-1
    80005f8a:	b7d5                	j	80005f6e <filewrite+0xfa>
    panic("filewrite");
    80005f8c:	00004517          	auipc	a0,0x4
    80005f90:	bac50513          	addi	a0,a0,-1108 # 80009b38 <syscalls+0x290>
    80005f94:	ffffa097          	auipc	ra,0xffffa
    80005f98:	5aa080e7          	jalr	1450(ra) # 8000053e <panic>
    return -1;
    80005f9c:	5a7d                	li	s4,-1
    80005f9e:	bfc1                	j	80005f6e <filewrite+0xfa>
      return -1;
    80005fa0:	5a7d                	li	s4,-1
    80005fa2:	b7f1                	j	80005f6e <filewrite+0xfa>
    80005fa4:	5a7d                	li	s4,-1
    80005fa6:	b7e1                	j	80005f6e <filewrite+0xfa>

0000000080005fa8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005fa8:	7179                	addi	sp,sp,-48
    80005faa:	f406                	sd	ra,40(sp)
    80005fac:	f022                	sd	s0,32(sp)
    80005fae:	ec26                	sd	s1,24(sp)
    80005fb0:	e84a                	sd	s2,16(sp)
    80005fb2:	e44e                	sd	s3,8(sp)
    80005fb4:	e052                	sd	s4,0(sp)
    80005fb6:	1800                	addi	s0,sp,48
    80005fb8:	84aa                	mv	s1,a0
    80005fba:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005fbc:	0005b023          	sd	zero,0(a1)
    80005fc0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005fc4:	00000097          	auipc	ra,0x0
    80005fc8:	bf8080e7          	jalr	-1032(ra) # 80005bbc <filealloc>
    80005fcc:	e088                	sd	a0,0(s1)
    80005fce:	c551                	beqz	a0,8000605a <pipealloc+0xb2>
    80005fd0:	00000097          	auipc	ra,0x0
    80005fd4:	bec080e7          	jalr	-1044(ra) # 80005bbc <filealloc>
    80005fd8:	00aa3023          	sd	a0,0(s4)
    80005fdc:	c92d                	beqz	a0,8000604e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005fde:	ffffb097          	auipc	ra,0xffffb
    80005fe2:	b16080e7          	jalr	-1258(ra) # 80000af4 <kalloc>
    80005fe6:	892a                	mv	s2,a0
    80005fe8:	c125                	beqz	a0,80006048 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005fea:	4985                	li	s3,1
    80005fec:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005ff0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005ff4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005ff8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005ffc:	00004597          	auipc	a1,0x4
    80006000:	b4c58593          	addi	a1,a1,-1204 # 80009b48 <syscalls+0x2a0>
    80006004:	ffffb097          	auipc	ra,0xffffb
    80006008:	b50080e7          	jalr	-1200(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000600c:	609c                	ld	a5,0(s1)
    8000600e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80006012:	609c                	ld	a5,0(s1)
    80006014:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80006018:	609c                	ld	a5,0(s1)
    8000601a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000601e:	609c                	ld	a5,0(s1)
    80006020:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80006024:	000a3783          	ld	a5,0(s4)
    80006028:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000602c:	000a3783          	ld	a5,0(s4)
    80006030:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80006034:	000a3783          	ld	a5,0(s4)
    80006038:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000603c:	000a3783          	ld	a5,0(s4)
    80006040:	0127b823          	sd	s2,16(a5)
  return 0;
    80006044:	4501                	li	a0,0
    80006046:	a025                	j	8000606e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80006048:	6088                	ld	a0,0(s1)
    8000604a:	e501                	bnez	a0,80006052 <pipealloc+0xaa>
    8000604c:	a039                	j	8000605a <pipealloc+0xb2>
    8000604e:	6088                	ld	a0,0(s1)
    80006050:	c51d                	beqz	a0,8000607e <pipealloc+0xd6>
    fileclose(*f0);
    80006052:	00000097          	auipc	ra,0x0
    80006056:	c26080e7          	jalr	-986(ra) # 80005c78 <fileclose>
  if(*f1)
    8000605a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000605e:	557d                	li	a0,-1
  if(*f1)
    80006060:	c799                	beqz	a5,8000606e <pipealloc+0xc6>
    fileclose(*f1);
    80006062:	853e                	mv	a0,a5
    80006064:	00000097          	auipc	ra,0x0
    80006068:	c14080e7          	jalr	-1004(ra) # 80005c78 <fileclose>
  return -1;
    8000606c:	557d                	li	a0,-1
}
    8000606e:	70a2                	ld	ra,40(sp)
    80006070:	7402                	ld	s0,32(sp)
    80006072:	64e2                	ld	s1,24(sp)
    80006074:	6942                	ld	s2,16(sp)
    80006076:	69a2                	ld	s3,8(sp)
    80006078:	6a02                	ld	s4,0(sp)
    8000607a:	6145                	addi	sp,sp,48
    8000607c:	8082                	ret
  return -1;
    8000607e:	557d                	li	a0,-1
    80006080:	b7fd                	j	8000606e <pipealloc+0xc6>

0000000080006082 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80006082:	1101                	addi	sp,sp,-32
    80006084:	ec06                	sd	ra,24(sp)
    80006086:	e822                	sd	s0,16(sp)
    80006088:	e426                	sd	s1,8(sp)
    8000608a:	e04a                	sd	s2,0(sp)
    8000608c:	1000                	addi	s0,sp,32
    8000608e:	84aa                	mv	s1,a0
    80006090:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80006092:	ffffb097          	auipc	ra,0xffffb
    80006096:	b52080e7          	jalr	-1198(ra) # 80000be4 <acquire>
  if(writable){
    8000609a:	02090d63          	beqz	s2,800060d4 <pipeclose+0x52>
    pi->writeopen = 0;
    8000609e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800060a2:	21848513          	addi	a0,s1,536
    800060a6:	ffffd097          	auipc	ra,0xffffd
    800060aa:	092080e7          	jalr	146(ra) # 80003138 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800060ae:	2204b783          	ld	a5,544(s1)
    800060b2:	eb95                	bnez	a5,800060e6 <pipeclose+0x64>
    release(&pi->lock);
    800060b4:	8526                	mv	a0,s1
    800060b6:	ffffb097          	auipc	ra,0xffffb
    800060ba:	be2080e7          	jalr	-1054(ra) # 80000c98 <release>
    kfree((char*)pi);
    800060be:	8526                	mv	a0,s1
    800060c0:	ffffb097          	auipc	ra,0xffffb
    800060c4:	938080e7          	jalr	-1736(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800060c8:	60e2                	ld	ra,24(sp)
    800060ca:	6442                	ld	s0,16(sp)
    800060cc:	64a2                	ld	s1,8(sp)
    800060ce:	6902                	ld	s2,0(sp)
    800060d0:	6105                	addi	sp,sp,32
    800060d2:	8082                	ret
    pi->readopen = 0;
    800060d4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800060d8:	21c48513          	addi	a0,s1,540
    800060dc:	ffffd097          	auipc	ra,0xffffd
    800060e0:	05c080e7          	jalr	92(ra) # 80003138 <wakeup>
    800060e4:	b7e9                	j	800060ae <pipeclose+0x2c>
    release(&pi->lock);
    800060e6:	8526                	mv	a0,s1
    800060e8:	ffffb097          	auipc	ra,0xffffb
    800060ec:	bb0080e7          	jalr	-1104(ra) # 80000c98 <release>
}
    800060f0:	bfe1                	j	800060c8 <pipeclose+0x46>

00000000800060f2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800060f2:	7159                	addi	sp,sp,-112
    800060f4:	f486                	sd	ra,104(sp)
    800060f6:	f0a2                	sd	s0,96(sp)
    800060f8:	eca6                	sd	s1,88(sp)
    800060fa:	e8ca                	sd	s2,80(sp)
    800060fc:	e4ce                	sd	s3,72(sp)
    800060fe:	e0d2                	sd	s4,64(sp)
    80006100:	fc56                	sd	s5,56(sp)
    80006102:	f85a                	sd	s6,48(sp)
    80006104:	f45e                	sd	s7,40(sp)
    80006106:	f062                	sd	s8,32(sp)
    80006108:	ec66                	sd	s9,24(sp)
    8000610a:	1880                	addi	s0,sp,112
    8000610c:	84aa                	mv	s1,a0
    8000610e:	8aae                	mv	s5,a1
    80006110:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80006112:	ffffc097          	auipc	ra,0xffffc
    80006116:	ab2080e7          	jalr	-1358(ra) # 80001bc4 <myproc>
    8000611a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000611c:	8526                	mv	a0,s1
    8000611e:	ffffb097          	auipc	ra,0xffffb
    80006122:	ac6080e7          	jalr	-1338(ra) # 80000be4 <acquire>
  while(i < n){
    80006126:	0d405163          	blez	s4,800061e8 <pipewrite+0xf6>
    8000612a:	8ba6                	mv	s7,s1
  int i = 0;
    8000612c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000612e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80006130:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80006134:	21c48c13          	addi	s8,s1,540
    80006138:	a08d                	j	8000619a <pipewrite+0xa8>
      release(&pi->lock);
    8000613a:	8526                	mv	a0,s1
    8000613c:	ffffb097          	auipc	ra,0xffffb
    80006140:	b5c080e7          	jalr	-1188(ra) # 80000c98 <release>
      return -1;
    80006144:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80006146:	854a                	mv	a0,s2
    80006148:	70a6                	ld	ra,104(sp)
    8000614a:	7406                	ld	s0,96(sp)
    8000614c:	64e6                	ld	s1,88(sp)
    8000614e:	6946                	ld	s2,80(sp)
    80006150:	69a6                	ld	s3,72(sp)
    80006152:	6a06                	ld	s4,64(sp)
    80006154:	7ae2                	ld	s5,56(sp)
    80006156:	7b42                	ld	s6,48(sp)
    80006158:	7ba2                	ld	s7,40(sp)
    8000615a:	7c02                	ld	s8,32(sp)
    8000615c:	6ce2                	ld	s9,24(sp)
    8000615e:	6165                	addi	sp,sp,112
    80006160:	8082                	ret
      wakeup(&pi->nread);
    80006162:	8566                	mv	a0,s9
    80006164:	ffffd097          	auipc	ra,0xffffd
    80006168:	fd4080e7          	jalr	-44(ra) # 80003138 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000616c:	85de                	mv	a1,s7
    8000616e:	8562                	mv	a0,s8
    80006170:	ffffd097          	auipc	ra,0xffffd
    80006174:	bb2080e7          	jalr	-1102(ra) # 80002d22 <sleep>
    80006178:	a839                	j	80006196 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000617a:	21c4a783          	lw	a5,540(s1)
    8000617e:	0017871b          	addiw	a4,a5,1
    80006182:	20e4ae23          	sw	a4,540(s1)
    80006186:	1ff7f793          	andi	a5,a5,511
    8000618a:	97a6                	add	a5,a5,s1
    8000618c:	f9f44703          	lbu	a4,-97(s0)
    80006190:	00e78c23          	sb	a4,24(a5)
      i++;
    80006194:	2905                	addiw	s2,s2,1
  while(i < n){
    80006196:	03495d63          	bge	s2,s4,800061d0 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    8000619a:	2204a783          	lw	a5,544(s1)
    8000619e:	dfd1                	beqz	a5,8000613a <pipewrite+0x48>
    800061a0:	0289a783          	lw	a5,40(s3)
    800061a4:	fbd9                	bnez	a5,8000613a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800061a6:	2184a783          	lw	a5,536(s1)
    800061aa:	21c4a703          	lw	a4,540(s1)
    800061ae:	2007879b          	addiw	a5,a5,512
    800061b2:	faf708e3          	beq	a4,a5,80006162 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800061b6:	4685                	li	a3,1
    800061b8:	01590633          	add	a2,s2,s5
    800061bc:	f9f40593          	addi	a1,s0,-97
    800061c0:	0809b503          	ld	a0,128(s3)
    800061c4:	ffffb097          	auipc	ra,0xffffb
    800061c8:	542080e7          	jalr	1346(ra) # 80001706 <copyin>
    800061cc:	fb6517e3          	bne	a0,s6,8000617a <pipewrite+0x88>
  wakeup(&pi->nread);
    800061d0:	21848513          	addi	a0,s1,536
    800061d4:	ffffd097          	auipc	ra,0xffffd
    800061d8:	f64080e7          	jalr	-156(ra) # 80003138 <wakeup>
  release(&pi->lock);
    800061dc:	8526                	mv	a0,s1
    800061de:	ffffb097          	auipc	ra,0xffffb
    800061e2:	aba080e7          	jalr	-1350(ra) # 80000c98 <release>
  return i;
    800061e6:	b785                	j	80006146 <pipewrite+0x54>
  int i = 0;
    800061e8:	4901                	li	s2,0
    800061ea:	b7dd                	j	800061d0 <pipewrite+0xde>

00000000800061ec <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800061ec:	715d                	addi	sp,sp,-80
    800061ee:	e486                	sd	ra,72(sp)
    800061f0:	e0a2                	sd	s0,64(sp)
    800061f2:	fc26                	sd	s1,56(sp)
    800061f4:	f84a                	sd	s2,48(sp)
    800061f6:	f44e                	sd	s3,40(sp)
    800061f8:	f052                	sd	s4,32(sp)
    800061fa:	ec56                	sd	s5,24(sp)
    800061fc:	e85a                	sd	s6,16(sp)
    800061fe:	0880                	addi	s0,sp,80
    80006200:	84aa                	mv	s1,a0
    80006202:	892e                	mv	s2,a1
    80006204:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80006206:	ffffc097          	auipc	ra,0xffffc
    8000620a:	9be080e7          	jalr	-1602(ra) # 80001bc4 <myproc>
    8000620e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80006210:	8b26                	mv	s6,s1
    80006212:	8526                	mv	a0,s1
    80006214:	ffffb097          	auipc	ra,0xffffb
    80006218:	9d0080e7          	jalr	-1584(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000621c:	2184a703          	lw	a4,536(s1)
    80006220:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80006224:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80006228:	02f71463          	bne	a4,a5,80006250 <piperead+0x64>
    8000622c:	2244a783          	lw	a5,548(s1)
    80006230:	c385                	beqz	a5,80006250 <piperead+0x64>
    if(pr->killed){
    80006232:	028a2783          	lw	a5,40(s4)
    80006236:	ebc1                	bnez	a5,800062c6 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80006238:	85da                	mv	a1,s6
    8000623a:	854e                	mv	a0,s3
    8000623c:	ffffd097          	auipc	ra,0xffffd
    80006240:	ae6080e7          	jalr	-1306(ra) # 80002d22 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80006244:	2184a703          	lw	a4,536(s1)
    80006248:	21c4a783          	lw	a5,540(s1)
    8000624c:	fef700e3          	beq	a4,a5,8000622c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80006250:	09505263          	blez	s5,800062d4 <piperead+0xe8>
    80006254:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80006256:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80006258:	2184a783          	lw	a5,536(s1)
    8000625c:	21c4a703          	lw	a4,540(s1)
    80006260:	02f70d63          	beq	a4,a5,8000629a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80006264:	0017871b          	addiw	a4,a5,1
    80006268:	20e4ac23          	sw	a4,536(s1)
    8000626c:	1ff7f793          	andi	a5,a5,511
    80006270:	97a6                	add	a5,a5,s1
    80006272:	0187c783          	lbu	a5,24(a5)
    80006276:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000627a:	4685                	li	a3,1
    8000627c:	fbf40613          	addi	a2,s0,-65
    80006280:	85ca                	mv	a1,s2
    80006282:	080a3503          	ld	a0,128(s4)
    80006286:	ffffb097          	auipc	ra,0xffffb
    8000628a:	3f4080e7          	jalr	1012(ra) # 8000167a <copyout>
    8000628e:	01650663          	beq	a0,s6,8000629a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80006292:	2985                	addiw	s3,s3,1
    80006294:	0905                	addi	s2,s2,1
    80006296:	fd3a91e3          	bne	s5,s3,80006258 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000629a:	21c48513          	addi	a0,s1,540
    8000629e:	ffffd097          	auipc	ra,0xffffd
    800062a2:	e9a080e7          	jalr	-358(ra) # 80003138 <wakeup>
  release(&pi->lock);
    800062a6:	8526                	mv	a0,s1
    800062a8:	ffffb097          	auipc	ra,0xffffb
    800062ac:	9f0080e7          	jalr	-1552(ra) # 80000c98 <release>
  return i;
}
    800062b0:	854e                	mv	a0,s3
    800062b2:	60a6                	ld	ra,72(sp)
    800062b4:	6406                	ld	s0,64(sp)
    800062b6:	74e2                	ld	s1,56(sp)
    800062b8:	7942                	ld	s2,48(sp)
    800062ba:	79a2                	ld	s3,40(sp)
    800062bc:	7a02                	ld	s4,32(sp)
    800062be:	6ae2                	ld	s5,24(sp)
    800062c0:	6b42                	ld	s6,16(sp)
    800062c2:	6161                	addi	sp,sp,80
    800062c4:	8082                	ret
      release(&pi->lock);
    800062c6:	8526                	mv	a0,s1
    800062c8:	ffffb097          	auipc	ra,0xffffb
    800062cc:	9d0080e7          	jalr	-1584(ra) # 80000c98 <release>
      return -1;
    800062d0:	59fd                	li	s3,-1
    800062d2:	bff9                	j	800062b0 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800062d4:	4981                	li	s3,0
    800062d6:	b7d1                	j	8000629a <piperead+0xae>

00000000800062d8 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800062d8:	df010113          	addi	sp,sp,-528
    800062dc:	20113423          	sd	ra,520(sp)
    800062e0:	20813023          	sd	s0,512(sp)
    800062e4:	ffa6                	sd	s1,504(sp)
    800062e6:	fbca                	sd	s2,496(sp)
    800062e8:	f7ce                	sd	s3,488(sp)
    800062ea:	f3d2                	sd	s4,480(sp)
    800062ec:	efd6                	sd	s5,472(sp)
    800062ee:	ebda                	sd	s6,464(sp)
    800062f0:	e7de                	sd	s7,456(sp)
    800062f2:	e3e2                	sd	s8,448(sp)
    800062f4:	ff66                	sd	s9,440(sp)
    800062f6:	fb6a                	sd	s10,432(sp)
    800062f8:	f76e                	sd	s11,424(sp)
    800062fa:	0c00                	addi	s0,sp,528
    800062fc:	84aa                	mv	s1,a0
    800062fe:	dea43c23          	sd	a0,-520(s0)
    80006302:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80006306:	ffffc097          	auipc	ra,0xffffc
    8000630a:	8be080e7          	jalr	-1858(ra) # 80001bc4 <myproc>
    8000630e:	892a                	mv	s2,a0

  begin_op();
    80006310:	fffff097          	auipc	ra,0xfffff
    80006314:	49c080e7          	jalr	1180(ra) # 800057ac <begin_op>

  if((ip = namei(path)) == 0){
    80006318:	8526                	mv	a0,s1
    8000631a:	fffff097          	auipc	ra,0xfffff
    8000631e:	276080e7          	jalr	630(ra) # 80005590 <namei>
    80006322:	c92d                	beqz	a0,80006394 <exec+0xbc>
    80006324:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80006326:	fffff097          	auipc	ra,0xfffff
    8000632a:	ab4080e7          	jalr	-1356(ra) # 80004dda <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000632e:	04000713          	li	a4,64
    80006332:	4681                	li	a3,0
    80006334:	e5040613          	addi	a2,s0,-432
    80006338:	4581                	li	a1,0
    8000633a:	8526                	mv	a0,s1
    8000633c:	fffff097          	auipc	ra,0xfffff
    80006340:	d52080e7          	jalr	-686(ra) # 8000508e <readi>
    80006344:	04000793          	li	a5,64
    80006348:	00f51a63          	bne	a0,a5,8000635c <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000634c:	e5042703          	lw	a4,-432(s0)
    80006350:	464c47b7          	lui	a5,0x464c4
    80006354:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80006358:	04f70463          	beq	a4,a5,800063a0 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000635c:	8526                	mv	a0,s1
    8000635e:	fffff097          	auipc	ra,0xfffff
    80006362:	cde080e7          	jalr	-802(ra) # 8000503c <iunlockput>
    end_op();
    80006366:	fffff097          	auipc	ra,0xfffff
    8000636a:	4c6080e7          	jalr	1222(ra) # 8000582c <end_op>
  }
  return -1;
    8000636e:	557d                	li	a0,-1
}
    80006370:	20813083          	ld	ra,520(sp)
    80006374:	20013403          	ld	s0,512(sp)
    80006378:	74fe                	ld	s1,504(sp)
    8000637a:	795e                	ld	s2,496(sp)
    8000637c:	79be                	ld	s3,488(sp)
    8000637e:	7a1e                	ld	s4,480(sp)
    80006380:	6afe                	ld	s5,472(sp)
    80006382:	6b5e                	ld	s6,464(sp)
    80006384:	6bbe                	ld	s7,456(sp)
    80006386:	6c1e                	ld	s8,448(sp)
    80006388:	7cfa                	ld	s9,440(sp)
    8000638a:	7d5a                	ld	s10,432(sp)
    8000638c:	7dba                	ld	s11,424(sp)
    8000638e:	21010113          	addi	sp,sp,528
    80006392:	8082                	ret
    end_op();
    80006394:	fffff097          	auipc	ra,0xfffff
    80006398:	498080e7          	jalr	1176(ra) # 8000582c <end_op>
    return -1;
    8000639c:	557d                	li	a0,-1
    8000639e:	bfc9                	j	80006370 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800063a0:	854a                	mv	a0,s2
    800063a2:	ffffc097          	auipc	ra,0xffffc
    800063a6:	8ea080e7          	jalr	-1814(ra) # 80001c8c <proc_pagetable>
    800063aa:	8baa                	mv	s7,a0
    800063ac:	d945                	beqz	a0,8000635c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800063ae:	e7042983          	lw	s3,-400(s0)
    800063b2:	e8845783          	lhu	a5,-376(s0)
    800063b6:	c7ad                	beqz	a5,80006420 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800063b8:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800063ba:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800063bc:	6c85                	lui	s9,0x1
    800063be:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800063c2:	def43823          	sd	a5,-528(s0)
    800063c6:	a42d                	j	800065f0 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800063c8:	00003517          	auipc	a0,0x3
    800063cc:	78850513          	addi	a0,a0,1928 # 80009b50 <syscalls+0x2a8>
    800063d0:	ffffa097          	auipc	ra,0xffffa
    800063d4:	16e080e7          	jalr	366(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800063d8:	8756                	mv	a4,s5
    800063da:	012d86bb          	addw	a3,s11,s2
    800063de:	4581                	li	a1,0
    800063e0:	8526                	mv	a0,s1
    800063e2:	fffff097          	auipc	ra,0xfffff
    800063e6:	cac080e7          	jalr	-852(ra) # 8000508e <readi>
    800063ea:	2501                	sext.w	a0,a0
    800063ec:	1aaa9963          	bne	s5,a0,8000659e <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800063f0:	6785                	lui	a5,0x1
    800063f2:	0127893b          	addw	s2,a5,s2
    800063f6:	77fd                	lui	a5,0xfffff
    800063f8:	01478a3b          	addw	s4,a5,s4
    800063fc:	1f897163          	bgeu	s2,s8,800065de <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80006400:	02091593          	slli	a1,s2,0x20
    80006404:	9181                	srli	a1,a1,0x20
    80006406:	95ea                	add	a1,a1,s10
    80006408:	855e                	mv	a0,s7
    8000640a:	ffffb097          	auipc	ra,0xffffb
    8000640e:	c6c080e7          	jalr	-916(ra) # 80001076 <walkaddr>
    80006412:	862a                	mv	a2,a0
    if(pa == 0)
    80006414:	d955                	beqz	a0,800063c8 <exec+0xf0>
      n = PGSIZE;
    80006416:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80006418:	fd9a70e3          	bgeu	s4,s9,800063d8 <exec+0x100>
      n = sz - i;
    8000641c:	8ad2                	mv	s5,s4
    8000641e:	bf6d                	j	800063d8 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80006420:	4901                	li	s2,0
  iunlockput(ip);
    80006422:	8526                	mv	a0,s1
    80006424:	fffff097          	auipc	ra,0xfffff
    80006428:	c18080e7          	jalr	-1000(ra) # 8000503c <iunlockput>
  end_op();
    8000642c:	fffff097          	auipc	ra,0xfffff
    80006430:	400080e7          	jalr	1024(ra) # 8000582c <end_op>
  p = myproc();
    80006434:	ffffb097          	auipc	ra,0xffffb
    80006438:	790080e7          	jalr	1936(ra) # 80001bc4 <myproc>
    8000643c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000643e:	07853d03          	ld	s10,120(a0)
  sz = PGROUNDUP(sz);
    80006442:	6785                	lui	a5,0x1
    80006444:	17fd                	addi	a5,a5,-1
    80006446:	993e                	add	s2,s2,a5
    80006448:	757d                	lui	a0,0xfffff
    8000644a:	00a977b3          	and	a5,s2,a0
    8000644e:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80006452:	6609                	lui	a2,0x2
    80006454:	963e                	add	a2,a2,a5
    80006456:	85be                	mv	a1,a5
    80006458:	855e                	mv	a0,s7
    8000645a:	ffffb097          	auipc	ra,0xffffb
    8000645e:	fd0080e7          	jalr	-48(ra) # 8000142a <uvmalloc>
    80006462:	8b2a                	mv	s6,a0
  ip = 0;
    80006464:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80006466:	12050c63          	beqz	a0,8000659e <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000646a:	75f9                	lui	a1,0xffffe
    8000646c:	95aa                	add	a1,a1,a0
    8000646e:	855e                	mv	a0,s7
    80006470:	ffffb097          	auipc	ra,0xffffb
    80006474:	1d8080e7          	jalr	472(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80006478:	7c7d                	lui	s8,0xfffff
    8000647a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000647c:	e0043783          	ld	a5,-512(s0)
    80006480:	6388                	ld	a0,0(a5)
    80006482:	c535                	beqz	a0,800064ee <exec+0x216>
    80006484:	e9040993          	addi	s3,s0,-368
    80006488:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000648c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000648e:	ffffb097          	auipc	ra,0xffffb
    80006492:	9d6080e7          	jalr	-1578(ra) # 80000e64 <strlen>
    80006496:	2505                	addiw	a0,a0,1
    80006498:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000649c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800064a0:	13896363          	bltu	s2,s8,800065c6 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800064a4:	e0043d83          	ld	s11,-512(s0)
    800064a8:	000dba03          	ld	s4,0(s11)
    800064ac:	8552                	mv	a0,s4
    800064ae:	ffffb097          	auipc	ra,0xffffb
    800064b2:	9b6080e7          	jalr	-1610(ra) # 80000e64 <strlen>
    800064b6:	0015069b          	addiw	a3,a0,1
    800064ba:	8652                	mv	a2,s4
    800064bc:	85ca                	mv	a1,s2
    800064be:	855e                	mv	a0,s7
    800064c0:	ffffb097          	auipc	ra,0xffffb
    800064c4:	1ba080e7          	jalr	442(ra) # 8000167a <copyout>
    800064c8:	10054363          	bltz	a0,800065ce <exec+0x2f6>
    ustack[argc] = sp;
    800064cc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800064d0:	0485                	addi	s1,s1,1
    800064d2:	008d8793          	addi	a5,s11,8
    800064d6:	e0f43023          	sd	a5,-512(s0)
    800064da:	008db503          	ld	a0,8(s11)
    800064de:	c911                	beqz	a0,800064f2 <exec+0x21a>
    if(argc >= MAXARG)
    800064e0:	09a1                	addi	s3,s3,8
    800064e2:	fb3c96e3          	bne	s9,s3,8000648e <exec+0x1b6>
  sz = sz1;
    800064e6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800064ea:	4481                	li	s1,0
    800064ec:	a84d                	j	8000659e <exec+0x2c6>
  sp = sz;
    800064ee:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800064f0:	4481                	li	s1,0
  ustack[argc] = 0;
    800064f2:	00349793          	slli	a5,s1,0x3
    800064f6:	f9040713          	addi	a4,s0,-112
    800064fa:	97ba                	add	a5,a5,a4
    800064fc:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80006500:	00148693          	addi	a3,s1,1
    80006504:	068e                	slli	a3,a3,0x3
    80006506:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000650a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000650e:	01897663          	bgeu	s2,s8,8000651a <exec+0x242>
  sz = sz1;
    80006512:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80006516:	4481                	li	s1,0
    80006518:	a059                	j	8000659e <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000651a:	e9040613          	addi	a2,s0,-368
    8000651e:	85ca                	mv	a1,s2
    80006520:	855e                	mv	a0,s7
    80006522:	ffffb097          	auipc	ra,0xffffb
    80006526:	158080e7          	jalr	344(ra) # 8000167a <copyout>
    8000652a:	0a054663          	bltz	a0,800065d6 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000652e:	088ab783          	ld	a5,136(s5)
    80006532:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80006536:	df843783          	ld	a5,-520(s0)
    8000653a:	0007c703          	lbu	a4,0(a5)
    8000653e:	cf11                	beqz	a4,8000655a <exec+0x282>
    80006540:	0785                	addi	a5,a5,1
    if(*s == '/')
    80006542:	02f00693          	li	a3,47
    80006546:	a039                	j	80006554 <exec+0x27c>
      last = s+1;
    80006548:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000654c:	0785                	addi	a5,a5,1
    8000654e:	fff7c703          	lbu	a4,-1(a5)
    80006552:	c701                	beqz	a4,8000655a <exec+0x282>
    if(*s == '/')
    80006554:	fed71ce3          	bne	a4,a3,8000654c <exec+0x274>
    80006558:	bfc5                	j	80006548 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000655a:	4641                	li	a2,16
    8000655c:	df843583          	ld	a1,-520(s0)
    80006560:	188a8513          	addi	a0,s5,392
    80006564:	ffffb097          	auipc	ra,0xffffb
    80006568:	8ce080e7          	jalr	-1842(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000656c:	080ab503          	ld	a0,128(s5)
  p->pagetable = pagetable;
    80006570:	097ab023          	sd	s7,128(s5)
  p->sz = sz;
    80006574:	076abc23          	sd	s6,120(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80006578:	088ab783          	ld	a5,136(s5)
    8000657c:	e6843703          	ld	a4,-408(s0)
    80006580:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80006582:	088ab783          	ld	a5,136(s5)
    80006586:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000658a:	85ea                	mv	a1,s10
    8000658c:	ffffb097          	auipc	ra,0xffffb
    80006590:	79c080e7          	jalr	1948(ra) # 80001d28 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80006594:	0004851b          	sext.w	a0,s1
    80006598:	bbe1                	j	80006370 <exec+0x98>
    8000659a:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000659e:	e0843583          	ld	a1,-504(s0)
    800065a2:	855e                	mv	a0,s7
    800065a4:	ffffb097          	auipc	ra,0xffffb
    800065a8:	784080e7          	jalr	1924(ra) # 80001d28 <proc_freepagetable>
  if(ip){
    800065ac:	da0498e3          	bnez	s1,8000635c <exec+0x84>
  return -1;
    800065b0:	557d                	li	a0,-1
    800065b2:	bb7d                	j	80006370 <exec+0x98>
    800065b4:	e1243423          	sd	s2,-504(s0)
    800065b8:	b7dd                	j	8000659e <exec+0x2c6>
    800065ba:	e1243423          	sd	s2,-504(s0)
    800065be:	b7c5                	j	8000659e <exec+0x2c6>
    800065c0:	e1243423          	sd	s2,-504(s0)
    800065c4:	bfe9                	j	8000659e <exec+0x2c6>
  sz = sz1;
    800065c6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800065ca:	4481                	li	s1,0
    800065cc:	bfc9                	j	8000659e <exec+0x2c6>
  sz = sz1;
    800065ce:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800065d2:	4481                	li	s1,0
    800065d4:	b7e9                	j	8000659e <exec+0x2c6>
  sz = sz1;
    800065d6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800065da:	4481                	li	s1,0
    800065dc:	b7c9                	j	8000659e <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800065de:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800065e2:	2b05                	addiw	s6,s6,1
    800065e4:	0389899b          	addiw	s3,s3,56
    800065e8:	e8845783          	lhu	a5,-376(s0)
    800065ec:	e2fb5be3          	bge	s6,a5,80006422 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800065f0:	2981                	sext.w	s3,s3
    800065f2:	03800713          	li	a4,56
    800065f6:	86ce                	mv	a3,s3
    800065f8:	e1840613          	addi	a2,s0,-488
    800065fc:	4581                	li	a1,0
    800065fe:	8526                	mv	a0,s1
    80006600:	fffff097          	auipc	ra,0xfffff
    80006604:	a8e080e7          	jalr	-1394(ra) # 8000508e <readi>
    80006608:	03800793          	li	a5,56
    8000660c:	f8f517e3          	bne	a0,a5,8000659a <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80006610:	e1842783          	lw	a5,-488(s0)
    80006614:	4705                	li	a4,1
    80006616:	fce796e3          	bne	a5,a4,800065e2 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000661a:	e4043603          	ld	a2,-448(s0)
    8000661e:	e3843783          	ld	a5,-456(s0)
    80006622:	f8f669e3          	bltu	a2,a5,800065b4 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80006626:	e2843783          	ld	a5,-472(s0)
    8000662a:	963e                	add	a2,a2,a5
    8000662c:	f8f667e3          	bltu	a2,a5,800065ba <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80006630:	85ca                	mv	a1,s2
    80006632:	855e                	mv	a0,s7
    80006634:	ffffb097          	auipc	ra,0xffffb
    80006638:	df6080e7          	jalr	-522(ra) # 8000142a <uvmalloc>
    8000663c:	e0a43423          	sd	a0,-504(s0)
    80006640:	d141                	beqz	a0,800065c0 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80006642:	e2843d03          	ld	s10,-472(s0)
    80006646:	df043783          	ld	a5,-528(s0)
    8000664a:	00fd77b3          	and	a5,s10,a5
    8000664e:	fba1                	bnez	a5,8000659e <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80006650:	e2042d83          	lw	s11,-480(s0)
    80006654:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80006658:	f80c03e3          	beqz	s8,800065de <exec+0x306>
    8000665c:	8a62                	mv	s4,s8
    8000665e:	4901                	li	s2,0
    80006660:	b345                	j	80006400 <exec+0x128>

0000000080006662 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80006662:	7179                	addi	sp,sp,-48
    80006664:	f406                	sd	ra,40(sp)
    80006666:	f022                	sd	s0,32(sp)
    80006668:	ec26                	sd	s1,24(sp)
    8000666a:	e84a                	sd	s2,16(sp)
    8000666c:	1800                	addi	s0,sp,48
    8000666e:	892e                	mv	s2,a1
    80006670:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80006672:	fdc40593          	addi	a1,s0,-36
    80006676:	ffffe097          	auipc	ra,0xffffe
    8000667a:	b46080e7          	jalr	-1210(ra) # 800041bc <argint>
    8000667e:	04054063          	bltz	a0,800066be <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80006682:	fdc42703          	lw	a4,-36(s0)
    80006686:	47bd                	li	a5,15
    80006688:	02e7ed63          	bltu	a5,a4,800066c2 <argfd+0x60>
    8000668c:	ffffb097          	auipc	ra,0xffffb
    80006690:	538080e7          	jalr	1336(ra) # 80001bc4 <myproc>
    80006694:	fdc42703          	lw	a4,-36(s0)
    80006698:	02070793          	addi	a5,a4,32
    8000669c:	078e                	slli	a5,a5,0x3
    8000669e:	953e                	add	a0,a0,a5
    800066a0:	611c                	ld	a5,0(a0)
    800066a2:	c395                	beqz	a5,800066c6 <argfd+0x64>
    return -1;
  if(pfd)
    800066a4:	00090463          	beqz	s2,800066ac <argfd+0x4a>
    *pfd = fd;
    800066a8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800066ac:	4501                	li	a0,0
  if(pf)
    800066ae:	c091                	beqz	s1,800066b2 <argfd+0x50>
    *pf = f;
    800066b0:	e09c                	sd	a5,0(s1)
}
    800066b2:	70a2                	ld	ra,40(sp)
    800066b4:	7402                	ld	s0,32(sp)
    800066b6:	64e2                	ld	s1,24(sp)
    800066b8:	6942                	ld	s2,16(sp)
    800066ba:	6145                	addi	sp,sp,48
    800066bc:	8082                	ret
    return -1;
    800066be:	557d                	li	a0,-1
    800066c0:	bfcd                	j	800066b2 <argfd+0x50>
    return -1;
    800066c2:	557d                	li	a0,-1
    800066c4:	b7fd                	j	800066b2 <argfd+0x50>
    800066c6:	557d                	li	a0,-1
    800066c8:	b7ed                	j	800066b2 <argfd+0x50>

00000000800066ca <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800066ca:	1101                	addi	sp,sp,-32
    800066cc:	ec06                	sd	ra,24(sp)
    800066ce:	e822                	sd	s0,16(sp)
    800066d0:	e426                	sd	s1,8(sp)
    800066d2:	1000                	addi	s0,sp,32
    800066d4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800066d6:	ffffb097          	auipc	ra,0xffffb
    800066da:	4ee080e7          	jalr	1262(ra) # 80001bc4 <myproc>
    800066de:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800066e0:	10050793          	addi	a5,a0,256 # fffffffffffff100 <end+0xffffffff7ffd7100>
    800066e4:	4501                	li	a0,0
    800066e6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800066e8:	6398                	ld	a4,0(a5)
    800066ea:	cb19                	beqz	a4,80006700 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800066ec:	2505                	addiw	a0,a0,1
    800066ee:	07a1                	addi	a5,a5,8
    800066f0:	fed51ce3          	bne	a0,a3,800066e8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800066f4:	557d                	li	a0,-1
}
    800066f6:	60e2                	ld	ra,24(sp)
    800066f8:	6442                	ld	s0,16(sp)
    800066fa:	64a2                	ld	s1,8(sp)
    800066fc:	6105                	addi	sp,sp,32
    800066fe:	8082                	ret
      p->ofile[fd] = f;
    80006700:	02050793          	addi	a5,a0,32
    80006704:	078e                	slli	a5,a5,0x3
    80006706:	963e                	add	a2,a2,a5
    80006708:	e204                	sd	s1,0(a2)
      return fd;
    8000670a:	b7f5                	j	800066f6 <fdalloc+0x2c>

000000008000670c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000670c:	715d                	addi	sp,sp,-80
    8000670e:	e486                	sd	ra,72(sp)
    80006710:	e0a2                	sd	s0,64(sp)
    80006712:	fc26                	sd	s1,56(sp)
    80006714:	f84a                	sd	s2,48(sp)
    80006716:	f44e                	sd	s3,40(sp)
    80006718:	f052                	sd	s4,32(sp)
    8000671a:	ec56                	sd	s5,24(sp)
    8000671c:	0880                	addi	s0,sp,80
    8000671e:	89ae                	mv	s3,a1
    80006720:	8ab2                	mv	s5,a2
    80006722:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80006724:	fb040593          	addi	a1,s0,-80
    80006728:	fffff097          	auipc	ra,0xfffff
    8000672c:	e86080e7          	jalr	-378(ra) # 800055ae <nameiparent>
    80006730:	892a                	mv	s2,a0
    80006732:	12050f63          	beqz	a0,80006870 <create+0x164>
    return 0;

  ilock(dp);
    80006736:	ffffe097          	auipc	ra,0xffffe
    8000673a:	6a4080e7          	jalr	1700(ra) # 80004dda <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000673e:	4601                	li	a2,0
    80006740:	fb040593          	addi	a1,s0,-80
    80006744:	854a                	mv	a0,s2
    80006746:	fffff097          	auipc	ra,0xfffff
    8000674a:	b78080e7          	jalr	-1160(ra) # 800052be <dirlookup>
    8000674e:	84aa                	mv	s1,a0
    80006750:	c921                	beqz	a0,800067a0 <create+0x94>
    iunlockput(dp);
    80006752:	854a                	mv	a0,s2
    80006754:	fffff097          	auipc	ra,0xfffff
    80006758:	8e8080e7          	jalr	-1816(ra) # 8000503c <iunlockput>
    ilock(ip);
    8000675c:	8526                	mv	a0,s1
    8000675e:	ffffe097          	auipc	ra,0xffffe
    80006762:	67c080e7          	jalr	1660(ra) # 80004dda <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80006766:	2981                	sext.w	s3,s3
    80006768:	4789                	li	a5,2
    8000676a:	02f99463          	bne	s3,a5,80006792 <create+0x86>
    8000676e:	0444d783          	lhu	a5,68(s1)
    80006772:	37f9                	addiw	a5,a5,-2
    80006774:	17c2                	slli	a5,a5,0x30
    80006776:	93c1                	srli	a5,a5,0x30
    80006778:	4705                	li	a4,1
    8000677a:	00f76c63          	bltu	a4,a5,80006792 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000677e:	8526                	mv	a0,s1
    80006780:	60a6                	ld	ra,72(sp)
    80006782:	6406                	ld	s0,64(sp)
    80006784:	74e2                	ld	s1,56(sp)
    80006786:	7942                	ld	s2,48(sp)
    80006788:	79a2                	ld	s3,40(sp)
    8000678a:	7a02                	ld	s4,32(sp)
    8000678c:	6ae2                	ld	s5,24(sp)
    8000678e:	6161                	addi	sp,sp,80
    80006790:	8082                	ret
    iunlockput(ip);
    80006792:	8526                	mv	a0,s1
    80006794:	fffff097          	auipc	ra,0xfffff
    80006798:	8a8080e7          	jalr	-1880(ra) # 8000503c <iunlockput>
    return 0;
    8000679c:	4481                	li	s1,0
    8000679e:	b7c5                	j	8000677e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800067a0:	85ce                	mv	a1,s3
    800067a2:	00092503          	lw	a0,0(s2)
    800067a6:	ffffe097          	auipc	ra,0xffffe
    800067aa:	49c080e7          	jalr	1180(ra) # 80004c42 <ialloc>
    800067ae:	84aa                	mv	s1,a0
    800067b0:	c529                	beqz	a0,800067fa <create+0xee>
  ilock(ip);
    800067b2:	ffffe097          	auipc	ra,0xffffe
    800067b6:	628080e7          	jalr	1576(ra) # 80004dda <ilock>
  ip->major = major;
    800067ba:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800067be:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800067c2:	4785                	li	a5,1
    800067c4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800067c8:	8526                	mv	a0,s1
    800067ca:	ffffe097          	auipc	ra,0xffffe
    800067ce:	546080e7          	jalr	1350(ra) # 80004d10 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800067d2:	2981                	sext.w	s3,s3
    800067d4:	4785                	li	a5,1
    800067d6:	02f98a63          	beq	s3,a5,8000680a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800067da:	40d0                	lw	a2,4(s1)
    800067dc:	fb040593          	addi	a1,s0,-80
    800067e0:	854a                	mv	a0,s2
    800067e2:	fffff097          	auipc	ra,0xfffff
    800067e6:	cec080e7          	jalr	-788(ra) # 800054ce <dirlink>
    800067ea:	06054b63          	bltz	a0,80006860 <create+0x154>
  iunlockput(dp);
    800067ee:	854a                	mv	a0,s2
    800067f0:	fffff097          	auipc	ra,0xfffff
    800067f4:	84c080e7          	jalr	-1972(ra) # 8000503c <iunlockput>
  return ip;
    800067f8:	b759                	j	8000677e <create+0x72>
    panic("create: ialloc");
    800067fa:	00003517          	auipc	a0,0x3
    800067fe:	37650513          	addi	a0,a0,886 # 80009b70 <syscalls+0x2c8>
    80006802:	ffffa097          	auipc	ra,0xffffa
    80006806:	d3c080e7          	jalr	-708(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000680a:	04a95783          	lhu	a5,74(s2)
    8000680e:	2785                	addiw	a5,a5,1
    80006810:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80006814:	854a                	mv	a0,s2
    80006816:	ffffe097          	auipc	ra,0xffffe
    8000681a:	4fa080e7          	jalr	1274(ra) # 80004d10 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000681e:	40d0                	lw	a2,4(s1)
    80006820:	00003597          	auipc	a1,0x3
    80006824:	36058593          	addi	a1,a1,864 # 80009b80 <syscalls+0x2d8>
    80006828:	8526                	mv	a0,s1
    8000682a:	fffff097          	auipc	ra,0xfffff
    8000682e:	ca4080e7          	jalr	-860(ra) # 800054ce <dirlink>
    80006832:	00054f63          	bltz	a0,80006850 <create+0x144>
    80006836:	00492603          	lw	a2,4(s2)
    8000683a:	00003597          	auipc	a1,0x3
    8000683e:	34e58593          	addi	a1,a1,846 # 80009b88 <syscalls+0x2e0>
    80006842:	8526                	mv	a0,s1
    80006844:	fffff097          	auipc	ra,0xfffff
    80006848:	c8a080e7          	jalr	-886(ra) # 800054ce <dirlink>
    8000684c:	f80557e3          	bgez	a0,800067da <create+0xce>
      panic("create dots");
    80006850:	00003517          	auipc	a0,0x3
    80006854:	34050513          	addi	a0,a0,832 # 80009b90 <syscalls+0x2e8>
    80006858:	ffffa097          	auipc	ra,0xffffa
    8000685c:	ce6080e7          	jalr	-794(ra) # 8000053e <panic>
    panic("create: dirlink");
    80006860:	00003517          	auipc	a0,0x3
    80006864:	34050513          	addi	a0,a0,832 # 80009ba0 <syscalls+0x2f8>
    80006868:	ffffa097          	auipc	ra,0xffffa
    8000686c:	cd6080e7          	jalr	-810(ra) # 8000053e <panic>
    return 0;
    80006870:	84aa                	mv	s1,a0
    80006872:	b731                	j	8000677e <create+0x72>

0000000080006874 <sys_dup>:
{
    80006874:	7179                	addi	sp,sp,-48
    80006876:	f406                	sd	ra,40(sp)
    80006878:	f022                	sd	s0,32(sp)
    8000687a:	ec26                	sd	s1,24(sp)
    8000687c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000687e:	fd840613          	addi	a2,s0,-40
    80006882:	4581                	li	a1,0
    80006884:	4501                	li	a0,0
    80006886:	00000097          	auipc	ra,0x0
    8000688a:	ddc080e7          	jalr	-548(ra) # 80006662 <argfd>
    return -1;
    8000688e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80006890:	02054363          	bltz	a0,800068b6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80006894:	fd843503          	ld	a0,-40(s0)
    80006898:	00000097          	auipc	ra,0x0
    8000689c:	e32080e7          	jalr	-462(ra) # 800066ca <fdalloc>
    800068a0:	84aa                	mv	s1,a0
    return -1;
    800068a2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800068a4:	00054963          	bltz	a0,800068b6 <sys_dup+0x42>
  filedup(f);
    800068a8:	fd843503          	ld	a0,-40(s0)
    800068ac:	fffff097          	auipc	ra,0xfffff
    800068b0:	37a080e7          	jalr	890(ra) # 80005c26 <filedup>
  return fd;
    800068b4:	87a6                	mv	a5,s1
}
    800068b6:	853e                	mv	a0,a5
    800068b8:	70a2                	ld	ra,40(sp)
    800068ba:	7402                	ld	s0,32(sp)
    800068bc:	64e2                	ld	s1,24(sp)
    800068be:	6145                	addi	sp,sp,48
    800068c0:	8082                	ret

00000000800068c2 <sys_read>:
{
    800068c2:	7179                	addi	sp,sp,-48
    800068c4:	f406                	sd	ra,40(sp)
    800068c6:	f022                	sd	s0,32(sp)
    800068c8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800068ca:	fe840613          	addi	a2,s0,-24
    800068ce:	4581                	li	a1,0
    800068d0:	4501                	li	a0,0
    800068d2:	00000097          	auipc	ra,0x0
    800068d6:	d90080e7          	jalr	-624(ra) # 80006662 <argfd>
    return -1;
    800068da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800068dc:	04054163          	bltz	a0,8000691e <sys_read+0x5c>
    800068e0:	fe440593          	addi	a1,s0,-28
    800068e4:	4509                	li	a0,2
    800068e6:	ffffe097          	auipc	ra,0xffffe
    800068ea:	8d6080e7          	jalr	-1834(ra) # 800041bc <argint>
    return -1;
    800068ee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800068f0:	02054763          	bltz	a0,8000691e <sys_read+0x5c>
    800068f4:	fd840593          	addi	a1,s0,-40
    800068f8:	4505                	li	a0,1
    800068fa:	ffffe097          	auipc	ra,0xffffe
    800068fe:	8e4080e7          	jalr	-1820(ra) # 800041de <argaddr>
    return -1;
    80006902:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006904:	00054d63          	bltz	a0,8000691e <sys_read+0x5c>
  return fileread(f, p, n);
    80006908:	fe442603          	lw	a2,-28(s0)
    8000690c:	fd843583          	ld	a1,-40(s0)
    80006910:	fe843503          	ld	a0,-24(s0)
    80006914:	fffff097          	auipc	ra,0xfffff
    80006918:	49e080e7          	jalr	1182(ra) # 80005db2 <fileread>
    8000691c:	87aa                	mv	a5,a0
}
    8000691e:	853e                	mv	a0,a5
    80006920:	70a2                	ld	ra,40(sp)
    80006922:	7402                	ld	s0,32(sp)
    80006924:	6145                	addi	sp,sp,48
    80006926:	8082                	ret

0000000080006928 <sys_write>:
{
    80006928:	7179                	addi	sp,sp,-48
    8000692a:	f406                	sd	ra,40(sp)
    8000692c:	f022                	sd	s0,32(sp)
    8000692e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006930:	fe840613          	addi	a2,s0,-24
    80006934:	4581                	li	a1,0
    80006936:	4501                	li	a0,0
    80006938:	00000097          	auipc	ra,0x0
    8000693c:	d2a080e7          	jalr	-726(ra) # 80006662 <argfd>
    return -1;
    80006940:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006942:	04054163          	bltz	a0,80006984 <sys_write+0x5c>
    80006946:	fe440593          	addi	a1,s0,-28
    8000694a:	4509                	li	a0,2
    8000694c:	ffffe097          	auipc	ra,0xffffe
    80006950:	870080e7          	jalr	-1936(ra) # 800041bc <argint>
    return -1;
    80006954:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006956:	02054763          	bltz	a0,80006984 <sys_write+0x5c>
    8000695a:	fd840593          	addi	a1,s0,-40
    8000695e:	4505                	li	a0,1
    80006960:	ffffe097          	auipc	ra,0xffffe
    80006964:	87e080e7          	jalr	-1922(ra) # 800041de <argaddr>
    return -1;
    80006968:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000696a:	00054d63          	bltz	a0,80006984 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000696e:	fe442603          	lw	a2,-28(s0)
    80006972:	fd843583          	ld	a1,-40(s0)
    80006976:	fe843503          	ld	a0,-24(s0)
    8000697a:	fffff097          	auipc	ra,0xfffff
    8000697e:	4fa080e7          	jalr	1274(ra) # 80005e74 <filewrite>
    80006982:	87aa                	mv	a5,a0
}
    80006984:	853e                	mv	a0,a5
    80006986:	70a2                	ld	ra,40(sp)
    80006988:	7402                	ld	s0,32(sp)
    8000698a:	6145                	addi	sp,sp,48
    8000698c:	8082                	ret

000000008000698e <sys_close>:
{
    8000698e:	1101                	addi	sp,sp,-32
    80006990:	ec06                	sd	ra,24(sp)
    80006992:	e822                	sd	s0,16(sp)
    80006994:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80006996:	fe040613          	addi	a2,s0,-32
    8000699a:	fec40593          	addi	a1,s0,-20
    8000699e:	4501                	li	a0,0
    800069a0:	00000097          	auipc	ra,0x0
    800069a4:	cc2080e7          	jalr	-830(ra) # 80006662 <argfd>
    return -1;
    800069a8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800069aa:	02054563          	bltz	a0,800069d4 <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    800069ae:	ffffb097          	auipc	ra,0xffffb
    800069b2:	216080e7          	jalr	534(ra) # 80001bc4 <myproc>
    800069b6:	fec42783          	lw	a5,-20(s0)
    800069ba:	02078793          	addi	a5,a5,32
    800069be:	078e                	slli	a5,a5,0x3
    800069c0:	97aa                	add	a5,a5,a0
    800069c2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800069c6:	fe043503          	ld	a0,-32(s0)
    800069ca:	fffff097          	auipc	ra,0xfffff
    800069ce:	2ae080e7          	jalr	686(ra) # 80005c78 <fileclose>
  return 0;
    800069d2:	4781                	li	a5,0
}
    800069d4:	853e                	mv	a0,a5
    800069d6:	60e2                	ld	ra,24(sp)
    800069d8:	6442                	ld	s0,16(sp)
    800069da:	6105                	addi	sp,sp,32
    800069dc:	8082                	ret

00000000800069de <sys_fstat>:
{
    800069de:	1101                	addi	sp,sp,-32
    800069e0:	ec06                	sd	ra,24(sp)
    800069e2:	e822                	sd	s0,16(sp)
    800069e4:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800069e6:	fe840613          	addi	a2,s0,-24
    800069ea:	4581                	li	a1,0
    800069ec:	4501                	li	a0,0
    800069ee:	00000097          	auipc	ra,0x0
    800069f2:	c74080e7          	jalr	-908(ra) # 80006662 <argfd>
    return -1;
    800069f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800069f8:	02054563          	bltz	a0,80006a22 <sys_fstat+0x44>
    800069fc:	fe040593          	addi	a1,s0,-32
    80006a00:	4505                	li	a0,1
    80006a02:	ffffd097          	auipc	ra,0xffffd
    80006a06:	7dc080e7          	jalr	2012(ra) # 800041de <argaddr>
    return -1;
    80006a0a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006a0c:	00054b63          	bltz	a0,80006a22 <sys_fstat+0x44>
  return filestat(f, st);
    80006a10:	fe043583          	ld	a1,-32(s0)
    80006a14:	fe843503          	ld	a0,-24(s0)
    80006a18:	fffff097          	auipc	ra,0xfffff
    80006a1c:	328080e7          	jalr	808(ra) # 80005d40 <filestat>
    80006a20:	87aa                	mv	a5,a0
}
    80006a22:	853e                	mv	a0,a5
    80006a24:	60e2                	ld	ra,24(sp)
    80006a26:	6442                	ld	s0,16(sp)
    80006a28:	6105                	addi	sp,sp,32
    80006a2a:	8082                	ret

0000000080006a2c <sys_link>:
{
    80006a2c:	7169                	addi	sp,sp,-304
    80006a2e:	f606                	sd	ra,296(sp)
    80006a30:	f222                	sd	s0,288(sp)
    80006a32:	ee26                	sd	s1,280(sp)
    80006a34:	ea4a                	sd	s2,272(sp)
    80006a36:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006a38:	08000613          	li	a2,128
    80006a3c:	ed040593          	addi	a1,s0,-304
    80006a40:	4501                	li	a0,0
    80006a42:	ffffd097          	auipc	ra,0xffffd
    80006a46:	7be080e7          	jalr	1982(ra) # 80004200 <argstr>
    return -1;
    80006a4a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006a4c:	10054e63          	bltz	a0,80006b68 <sys_link+0x13c>
    80006a50:	08000613          	li	a2,128
    80006a54:	f5040593          	addi	a1,s0,-176
    80006a58:	4505                	li	a0,1
    80006a5a:	ffffd097          	auipc	ra,0xffffd
    80006a5e:	7a6080e7          	jalr	1958(ra) # 80004200 <argstr>
    return -1;
    80006a62:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006a64:	10054263          	bltz	a0,80006b68 <sys_link+0x13c>
  begin_op();
    80006a68:	fffff097          	auipc	ra,0xfffff
    80006a6c:	d44080e7          	jalr	-700(ra) # 800057ac <begin_op>
  if((ip = namei(old)) == 0){
    80006a70:	ed040513          	addi	a0,s0,-304
    80006a74:	fffff097          	auipc	ra,0xfffff
    80006a78:	b1c080e7          	jalr	-1252(ra) # 80005590 <namei>
    80006a7c:	84aa                	mv	s1,a0
    80006a7e:	c551                	beqz	a0,80006b0a <sys_link+0xde>
  ilock(ip);
    80006a80:	ffffe097          	auipc	ra,0xffffe
    80006a84:	35a080e7          	jalr	858(ra) # 80004dda <ilock>
  if(ip->type == T_DIR){
    80006a88:	04449703          	lh	a4,68(s1)
    80006a8c:	4785                	li	a5,1
    80006a8e:	08f70463          	beq	a4,a5,80006b16 <sys_link+0xea>
  ip->nlink++;
    80006a92:	04a4d783          	lhu	a5,74(s1)
    80006a96:	2785                	addiw	a5,a5,1
    80006a98:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006a9c:	8526                	mv	a0,s1
    80006a9e:	ffffe097          	auipc	ra,0xffffe
    80006aa2:	272080e7          	jalr	626(ra) # 80004d10 <iupdate>
  iunlock(ip);
    80006aa6:	8526                	mv	a0,s1
    80006aa8:	ffffe097          	auipc	ra,0xffffe
    80006aac:	3f4080e7          	jalr	1012(ra) # 80004e9c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80006ab0:	fd040593          	addi	a1,s0,-48
    80006ab4:	f5040513          	addi	a0,s0,-176
    80006ab8:	fffff097          	auipc	ra,0xfffff
    80006abc:	af6080e7          	jalr	-1290(ra) # 800055ae <nameiparent>
    80006ac0:	892a                	mv	s2,a0
    80006ac2:	c935                	beqz	a0,80006b36 <sys_link+0x10a>
  ilock(dp);
    80006ac4:	ffffe097          	auipc	ra,0xffffe
    80006ac8:	316080e7          	jalr	790(ra) # 80004dda <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80006acc:	00092703          	lw	a4,0(s2)
    80006ad0:	409c                	lw	a5,0(s1)
    80006ad2:	04f71d63          	bne	a4,a5,80006b2c <sys_link+0x100>
    80006ad6:	40d0                	lw	a2,4(s1)
    80006ad8:	fd040593          	addi	a1,s0,-48
    80006adc:	854a                	mv	a0,s2
    80006ade:	fffff097          	auipc	ra,0xfffff
    80006ae2:	9f0080e7          	jalr	-1552(ra) # 800054ce <dirlink>
    80006ae6:	04054363          	bltz	a0,80006b2c <sys_link+0x100>
  iunlockput(dp);
    80006aea:	854a                	mv	a0,s2
    80006aec:	ffffe097          	auipc	ra,0xffffe
    80006af0:	550080e7          	jalr	1360(ra) # 8000503c <iunlockput>
  iput(ip);
    80006af4:	8526                	mv	a0,s1
    80006af6:	ffffe097          	auipc	ra,0xffffe
    80006afa:	49e080e7          	jalr	1182(ra) # 80004f94 <iput>
  end_op();
    80006afe:	fffff097          	auipc	ra,0xfffff
    80006b02:	d2e080e7          	jalr	-722(ra) # 8000582c <end_op>
  return 0;
    80006b06:	4781                	li	a5,0
    80006b08:	a085                	j	80006b68 <sys_link+0x13c>
    end_op();
    80006b0a:	fffff097          	auipc	ra,0xfffff
    80006b0e:	d22080e7          	jalr	-734(ra) # 8000582c <end_op>
    return -1;
    80006b12:	57fd                	li	a5,-1
    80006b14:	a891                	j	80006b68 <sys_link+0x13c>
    iunlockput(ip);
    80006b16:	8526                	mv	a0,s1
    80006b18:	ffffe097          	auipc	ra,0xffffe
    80006b1c:	524080e7          	jalr	1316(ra) # 8000503c <iunlockput>
    end_op();
    80006b20:	fffff097          	auipc	ra,0xfffff
    80006b24:	d0c080e7          	jalr	-756(ra) # 8000582c <end_op>
    return -1;
    80006b28:	57fd                	li	a5,-1
    80006b2a:	a83d                	j	80006b68 <sys_link+0x13c>
    iunlockput(dp);
    80006b2c:	854a                	mv	a0,s2
    80006b2e:	ffffe097          	auipc	ra,0xffffe
    80006b32:	50e080e7          	jalr	1294(ra) # 8000503c <iunlockput>
  ilock(ip);
    80006b36:	8526                	mv	a0,s1
    80006b38:	ffffe097          	auipc	ra,0xffffe
    80006b3c:	2a2080e7          	jalr	674(ra) # 80004dda <ilock>
  ip->nlink--;
    80006b40:	04a4d783          	lhu	a5,74(s1)
    80006b44:	37fd                	addiw	a5,a5,-1
    80006b46:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006b4a:	8526                	mv	a0,s1
    80006b4c:	ffffe097          	auipc	ra,0xffffe
    80006b50:	1c4080e7          	jalr	452(ra) # 80004d10 <iupdate>
  iunlockput(ip);
    80006b54:	8526                	mv	a0,s1
    80006b56:	ffffe097          	auipc	ra,0xffffe
    80006b5a:	4e6080e7          	jalr	1254(ra) # 8000503c <iunlockput>
  end_op();
    80006b5e:	fffff097          	auipc	ra,0xfffff
    80006b62:	cce080e7          	jalr	-818(ra) # 8000582c <end_op>
  return -1;
    80006b66:	57fd                	li	a5,-1
}
    80006b68:	853e                	mv	a0,a5
    80006b6a:	70b2                	ld	ra,296(sp)
    80006b6c:	7412                	ld	s0,288(sp)
    80006b6e:	64f2                	ld	s1,280(sp)
    80006b70:	6952                	ld	s2,272(sp)
    80006b72:	6155                	addi	sp,sp,304
    80006b74:	8082                	ret

0000000080006b76 <sys_unlink>:
{
    80006b76:	7151                	addi	sp,sp,-240
    80006b78:	f586                	sd	ra,232(sp)
    80006b7a:	f1a2                	sd	s0,224(sp)
    80006b7c:	eda6                	sd	s1,216(sp)
    80006b7e:	e9ca                	sd	s2,208(sp)
    80006b80:	e5ce                	sd	s3,200(sp)
    80006b82:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80006b84:	08000613          	li	a2,128
    80006b88:	f3040593          	addi	a1,s0,-208
    80006b8c:	4501                	li	a0,0
    80006b8e:	ffffd097          	auipc	ra,0xffffd
    80006b92:	672080e7          	jalr	1650(ra) # 80004200 <argstr>
    80006b96:	18054163          	bltz	a0,80006d18 <sys_unlink+0x1a2>
  begin_op();
    80006b9a:	fffff097          	auipc	ra,0xfffff
    80006b9e:	c12080e7          	jalr	-1006(ra) # 800057ac <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006ba2:	fb040593          	addi	a1,s0,-80
    80006ba6:	f3040513          	addi	a0,s0,-208
    80006baa:	fffff097          	auipc	ra,0xfffff
    80006bae:	a04080e7          	jalr	-1532(ra) # 800055ae <nameiparent>
    80006bb2:	84aa                	mv	s1,a0
    80006bb4:	c979                	beqz	a0,80006c8a <sys_unlink+0x114>
  ilock(dp);
    80006bb6:	ffffe097          	auipc	ra,0xffffe
    80006bba:	224080e7          	jalr	548(ra) # 80004dda <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006bbe:	00003597          	auipc	a1,0x3
    80006bc2:	fc258593          	addi	a1,a1,-62 # 80009b80 <syscalls+0x2d8>
    80006bc6:	fb040513          	addi	a0,s0,-80
    80006bca:	ffffe097          	auipc	ra,0xffffe
    80006bce:	6da080e7          	jalr	1754(ra) # 800052a4 <namecmp>
    80006bd2:	14050a63          	beqz	a0,80006d26 <sys_unlink+0x1b0>
    80006bd6:	00003597          	auipc	a1,0x3
    80006bda:	fb258593          	addi	a1,a1,-78 # 80009b88 <syscalls+0x2e0>
    80006bde:	fb040513          	addi	a0,s0,-80
    80006be2:	ffffe097          	auipc	ra,0xffffe
    80006be6:	6c2080e7          	jalr	1730(ra) # 800052a4 <namecmp>
    80006bea:	12050e63          	beqz	a0,80006d26 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80006bee:	f2c40613          	addi	a2,s0,-212
    80006bf2:	fb040593          	addi	a1,s0,-80
    80006bf6:	8526                	mv	a0,s1
    80006bf8:	ffffe097          	auipc	ra,0xffffe
    80006bfc:	6c6080e7          	jalr	1734(ra) # 800052be <dirlookup>
    80006c00:	892a                	mv	s2,a0
    80006c02:	12050263          	beqz	a0,80006d26 <sys_unlink+0x1b0>
  ilock(ip);
    80006c06:	ffffe097          	auipc	ra,0xffffe
    80006c0a:	1d4080e7          	jalr	468(ra) # 80004dda <ilock>
  if(ip->nlink < 1)
    80006c0e:	04a91783          	lh	a5,74(s2)
    80006c12:	08f05263          	blez	a5,80006c96 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006c16:	04491703          	lh	a4,68(s2)
    80006c1a:	4785                	li	a5,1
    80006c1c:	08f70563          	beq	a4,a5,80006ca6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80006c20:	4641                	li	a2,16
    80006c22:	4581                	li	a1,0
    80006c24:	fc040513          	addi	a0,s0,-64
    80006c28:	ffffa097          	auipc	ra,0xffffa
    80006c2c:	0b8080e7          	jalr	184(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006c30:	4741                	li	a4,16
    80006c32:	f2c42683          	lw	a3,-212(s0)
    80006c36:	fc040613          	addi	a2,s0,-64
    80006c3a:	4581                	li	a1,0
    80006c3c:	8526                	mv	a0,s1
    80006c3e:	ffffe097          	auipc	ra,0xffffe
    80006c42:	548080e7          	jalr	1352(ra) # 80005186 <writei>
    80006c46:	47c1                	li	a5,16
    80006c48:	0af51563          	bne	a0,a5,80006cf2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80006c4c:	04491703          	lh	a4,68(s2)
    80006c50:	4785                	li	a5,1
    80006c52:	0af70863          	beq	a4,a5,80006d02 <sys_unlink+0x18c>
  iunlockput(dp);
    80006c56:	8526                	mv	a0,s1
    80006c58:	ffffe097          	auipc	ra,0xffffe
    80006c5c:	3e4080e7          	jalr	996(ra) # 8000503c <iunlockput>
  ip->nlink--;
    80006c60:	04a95783          	lhu	a5,74(s2)
    80006c64:	37fd                	addiw	a5,a5,-1
    80006c66:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006c6a:	854a                	mv	a0,s2
    80006c6c:	ffffe097          	auipc	ra,0xffffe
    80006c70:	0a4080e7          	jalr	164(ra) # 80004d10 <iupdate>
  iunlockput(ip);
    80006c74:	854a                	mv	a0,s2
    80006c76:	ffffe097          	auipc	ra,0xffffe
    80006c7a:	3c6080e7          	jalr	966(ra) # 8000503c <iunlockput>
  end_op();
    80006c7e:	fffff097          	auipc	ra,0xfffff
    80006c82:	bae080e7          	jalr	-1106(ra) # 8000582c <end_op>
  return 0;
    80006c86:	4501                	li	a0,0
    80006c88:	a84d                	j	80006d3a <sys_unlink+0x1c4>
    end_op();
    80006c8a:	fffff097          	auipc	ra,0xfffff
    80006c8e:	ba2080e7          	jalr	-1118(ra) # 8000582c <end_op>
    return -1;
    80006c92:	557d                	li	a0,-1
    80006c94:	a05d                	j	80006d3a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80006c96:	00003517          	auipc	a0,0x3
    80006c9a:	f1a50513          	addi	a0,a0,-230 # 80009bb0 <syscalls+0x308>
    80006c9e:	ffffa097          	auipc	ra,0xffffa
    80006ca2:	8a0080e7          	jalr	-1888(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006ca6:	04c92703          	lw	a4,76(s2)
    80006caa:	02000793          	li	a5,32
    80006cae:	f6e7f9e3          	bgeu	a5,a4,80006c20 <sys_unlink+0xaa>
    80006cb2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006cb6:	4741                	li	a4,16
    80006cb8:	86ce                	mv	a3,s3
    80006cba:	f1840613          	addi	a2,s0,-232
    80006cbe:	4581                	li	a1,0
    80006cc0:	854a                	mv	a0,s2
    80006cc2:	ffffe097          	auipc	ra,0xffffe
    80006cc6:	3cc080e7          	jalr	972(ra) # 8000508e <readi>
    80006cca:	47c1                	li	a5,16
    80006ccc:	00f51b63          	bne	a0,a5,80006ce2 <sys_unlink+0x16c>
    if(de.inum != 0)
    80006cd0:	f1845783          	lhu	a5,-232(s0)
    80006cd4:	e7a1                	bnez	a5,80006d1c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006cd6:	29c1                	addiw	s3,s3,16
    80006cd8:	04c92783          	lw	a5,76(s2)
    80006cdc:	fcf9ede3          	bltu	s3,a5,80006cb6 <sys_unlink+0x140>
    80006ce0:	b781                	j	80006c20 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80006ce2:	00003517          	auipc	a0,0x3
    80006ce6:	ee650513          	addi	a0,a0,-282 # 80009bc8 <syscalls+0x320>
    80006cea:	ffffa097          	auipc	ra,0xffffa
    80006cee:	854080e7          	jalr	-1964(ra) # 8000053e <panic>
    panic("unlink: writei");
    80006cf2:	00003517          	auipc	a0,0x3
    80006cf6:	eee50513          	addi	a0,a0,-274 # 80009be0 <syscalls+0x338>
    80006cfa:	ffffa097          	auipc	ra,0xffffa
    80006cfe:	844080e7          	jalr	-1980(ra) # 8000053e <panic>
    dp->nlink--;
    80006d02:	04a4d783          	lhu	a5,74(s1)
    80006d06:	37fd                	addiw	a5,a5,-1
    80006d08:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006d0c:	8526                	mv	a0,s1
    80006d0e:	ffffe097          	auipc	ra,0xffffe
    80006d12:	002080e7          	jalr	2(ra) # 80004d10 <iupdate>
    80006d16:	b781                	j	80006c56 <sys_unlink+0xe0>
    return -1;
    80006d18:	557d                	li	a0,-1
    80006d1a:	a005                	j	80006d3a <sys_unlink+0x1c4>
    iunlockput(ip);
    80006d1c:	854a                	mv	a0,s2
    80006d1e:	ffffe097          	auipc	ra,0xffffe
    80006d22:	31e080e7          	jalr	798(ra) # 8000503c <iunlockput>
  iunlockput(dp);
    80006d26:	8526                	mv	a0,s1
    80006d28:	ffffe097          	auipc	ra,0xffffe
    80006d2c:	314080e7          	jalr	788(ra) # 8000503c <iunlockput>
  end_op();
    80006d30:	fffff097          	auipc	ra,0xfffff
    80006d34:	afc080e7          	jalr	-1284(ra) # 8000582c <end_op>
  return -1;
    80006d38:	557d                	li	a0,-1
}
    80006d3a:	70ae                	ld	ra,232(sp)
    80006d3c:	740e                	ld	s0,224(sp)
    80006d3e:	64ee                	ld	s1,216(sp)
    80006d40:	694e                	ld	s2,208(sp)
    80006d42:	69ae                	ld	s3,200(sp)
    80006d44:	616d                	addi	sp,sp,240
    80006d46:	8082                	ret

0000000080006d48 <sys_open>:

uint64
sys_open(void)
{
    80006d48:	7131                	addi	sp,sp,-192
    80006d4a:	fd06                	sd	ra,184(sp)
    80006d4c:	f922                	sd	s0,176(sp)
    80006d4e:	f526                	sd	s1,168(sp)
    80006d50:	f14a                	sd	s2,160(sp)
    80006d52:	ed4e                	sd	s3,152(sp)
    80006d54:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006d56:	08000613          	li	a2,128
    80006d5a:	f5040593          	addi	a1,s0,-176
    80006d5e:	4501                	li	a0,0
    80006d60:	ffffd097          	auipc	ra,0xffffd
    80006d64:	4a0080e7          	jalr	1184(ra) # 80004200 <argstr>
    return -1;
    80006d68:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006d6a:	0c054163          	bltz	a0,80006e2c <sys_open+0xe4>
    80006d6e:	f4c40593          	addi	a1,s0,-180
    80006d72:	4505                	li	a0,1
    80006d74:	ffffd097          	auipc	ra,0xffffd
    80006d78:	448080e7          	jalr	1096(ra) # 800041bc <argint>
    80006d7c:	0a054863          	bltz	a0,80006e2c <sys_open+0xe4>

  begin_op();
    80006d80:	fffff097          	auipc	ra,0xfffff
    80006d84:	a2c080e7          	jalr	-1492(ra) # 800057ac <begin_op>

  if(omode & O_CREATE){
    80006d88:	f4c42783          	lw	a5,-180(s0)
    80006d8c:	2007f793          	andi	a5,a5,512
    80006d90:	cbdd                	beqz	a5,80006e46 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006d92:	4681                	li	a3,0
    80006d94:	4601                	li	a2,0
    80006d96:	4589                	li	a1,2
    80006d98:	f5040513          	addi	a0,s0,-176
    80006d9c:	00000097          	auipc	ra,0x0
    80006da0:	970080e7          	jalr	-1680(ra) # 8000670c <create>
    80006da4:	892a                	mv	s2,a0
    if(ip == 0){
    80006da6:	c959                	beqz	a0,80006e3c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006da8:	04491703          	lh	a4,68(s2)
    80006dac:	478d                	li	a5,3
    80006dae:	00f71763          	bne	a4,a5,80006dbc <sys_open+0x74>
    80006db2:	04695703          	lhu	a4,70(s2)
    80006db6:	47a5                	li	a5,9
    80006db8:	0ce7ec63          	bltu	a5,a4,80006e90 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006dbc:	fffff097          	auipc	ra,0xfffff
    80006dc0:	e00080e7          	jalr	-512(ra) # 80005bbc <filealloc>
    80006dc4:	89aa                	mv	s3,a0
    80006dc6:	10050263          	beqz	a0,80006eca <sys_open+0x182>
    80006dca:	00000097          	auipc	ra,0x0
    80006dce:	900080e7          	jalr	-1792(ra) # 800066ca <fdalloc>
    80006dd2:	84aa                	mv	s1,a0
    80006dd4:	0e054663          	bltz	a0,80006ec0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006dd8:	04491703          	lh	a4,68(s2)
    80006ddc:	478d                	li	a5,3
    80006dde:	0cf70463          	beq	a4,a5,80006ea6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006de2:	4789                	li	a5,2
    80006de4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006de8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006dec:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006df0:	f4c42783          	lw	a5,-180(s0)
    80006df4:	0017c713          	xori	a4,a5,1
    80006df8:	8b05                	andi	a4,a4,1
    80006dfa:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006dfe:	0037f713          	andi	a4,a5,3
    80006e02:	00e03733          	snez	a4,a4
    80006e06:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006e0a:	4007f793          	andi	a5,a5,1024
    80006e0e:	c791                	beqz	a5,80006e1a <sys_open+0xd2>
    80006e10:	04491703          	lh	a4,68(s2)
    80006e14:	4789                	li	a5,2
    80006e16:	08f70f63          	beq	a4,a5,80006eb4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006e1a:	854a                	mv	a0,s2
    80006e1c:	ffffe097          	auipc	ra,0xffffe
    80006e20:	080080e7          	jalr	128(ra) # 80004e9c <iunlock>
  end_op();
    80006e24:	fffff097          	auipc	ra,0xfffff
    80006e28:	a08080e7          	jalr	-1528(ra) # 8000582c <end_op>

  return fd;
}
    80006e2c:	8526                	mv	a0,s1
    80006e2e:	70ea                	ld	ra,184(sp)
    80006e30:	744a                	ld	s0,176(sp)
    80006e32:	74aa                	ld	s1,168(sp)
    80006e34:	790a                	ld	s2,160(sp)
    80006e36:	69ea                	ld	s3,152(sp)
    80006e38:	6129                	addi	sp,sp,192
    80006e3a:	8082                	ret
      end_op();
    80006e3c:	fffff097          	auipc	ra,0xfffff
    80006e40:	9f0080e7          	jalr	-1552(ra) # 8000582c <end_op>
      return -1;
    80006e44:	b7e5                	j	80006e2c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006e46:	f5040513          	addi	a0,s0,-176
    80006e4a:	ffffe097          	auipc	ra,0xffffe
    80006e4e:	746080e7          	jalr	1862(ra) # 80005590 <namei>
    80006e52:	892a                	mv	s2,a0
    80006e54:	c905                	beqz	a0,80006e84 <sys_open+0x13c>
    ilock(ip);
    80006e56:	ffffe097          	auipc	ra,0xffffe
    80006e5a:	f84080e7          	jalr	-124(ra) # 80004dda <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006e5e:	04491703          	lh	a4,68(s2)
    80006e62:	4785                	li	a5,1
    80006e64:	f4f712e3          	bne	a4,a5,80006da8 <sys_open+0x60>
    80006e68:	f4c42783          	lw	a5,-180(s0)
    80006e6c:	dba1                	beqz	a5,80006dbc <sys_open+0x74>
      iunlockput(ip);
    80006e6e:	854a                	mv	a0,s2
    80006e70:	ffffe097          	auipc	ra,0xffffe
    80006e74:	1cc080e7          	jalr	460(ra) # 8000503c <iunlockput>
      end_op();
    80006e78:	fffff097          	auipc	ra,0xfffff
    80006e7c:	9b4080e7          	jalr	-1612(ra) # 8000582c <end_op>
      return -1;
    80006e80:	54fd                	li	s1,-1
    80006e82:	b76d                	j	80006e2c <sys_open+0xe4>
      end_op();
    80006e84:	fffff097          	auipc	ra,0xfffff
    80006e88:	9a8080e7          	jalr	-1624(ra) # 8000582c <end_op>
      return -1;
    80006e8c:	54fd                	li	s1,-1
    80006e8e:	bf79                	j	80006e2c <sys_open+0xe4>
    iunlockput(ip);
    80006e90:	854a                	mv	a0,s2
    80006e92:	ffffe097          	auipc	ra,0xffffe
    80006e96:	1aa080e7          	jalr	426(ra) # 8000503c <iunlockput>
    end_op();
    80006e9a:	fffff097          	auipc	ra,0xfffff
    80006e9e:	992080e7          	jalr	-1646(ra) # 8000582c <end_op>
    return -1;
    80006ea2:	54fd                	li	s1,-1
    80006ea4:	b761                	j	80006e2c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006ea6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006eaa:	04691783          	lh	a5,70(s2)
    80006eae:	02f99223          	sh	a5,36(s3)
    80006eb2:	bf2d                	j	80006dec <sys_open+0xa4>
    itrunc(ip);
    80006eb4:	854a                	mv	a0,s2
    80006eb6:	ffffe097          	auipc	ra,0xffffe
    80006eba:	032080e7          	jalr	50(ra) # 80004ee8 <itrunc>
    80006ebe:	bfb1                	j	80006e1a <sys_open+0xd2>
      fileclose(f);
    80006ec0:	854e                	mv	a0,s3
    80006ec2:	fffff097          	auipc	ra,0xfffff
    80006ec6:	db6080e7          	jalr	-586(ra) # 80005c78 <fileclose>
    iunlockput(ip);
    80006eca:	854a                	mv	a0,s2
    80006ecc:	ffffe097          	auipc	ra,0xffffe
    80006ed0:	170080e7          	jalr	368(ra) # 8000503c <iunlockput>
    end_op();
    80006ed4:	fffff097          	auipc	ra,0xfffff
    80006ed8:	958080e7          	jalr	-1704(ra) # 8000582c <end_op>
    return -1;
    80006edc:	54fd                	li	s1,-1
    80006ede:	b7b9                	j	80006e2c <sys_open+0xe4>

0000000080006ee0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006ee0:	7175                	addi	sp,sp,-144
    80006ee2:	e506                	sd	ra,136(sp)
    80006ee4:	e122                	sd	s0,128(sp)
    80006ee6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006ee8:	fffff097          	auipc	ra,0xfffff
    80006eec:	8c4080e7          	jalr	-1852(ra) # 800057ac <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006ef0:	08000613          	li	a2,128
    80006ef4:	f7040593          	addi	a1,s0,-144
    80006ef8:	4501                	li	a0,0
    80006efa:	ffffd097          	auipc	ra,0xffffd
    80006efe:	306080e7          	jalr	774(ra) # 80004200 <argstr>
    80006f02:	02054963          	bltz	a0,80006f34 <sys_mkdir+0x54>
    80006f06:	4681                	li	a3,0
    80006f08:	4601                	li	a2,0
    80006f0a:	4585                	li	a1,1
    80006f0c:	f7040513          	addi	a0,s0,-144
    80006f10:	fffff097          	auipc	ra,0xfffff
    80006f14:	7fc080e7          	jalr	2044(ra) # 8000670c <create>
    80006f18:	cd11                	beqz	a0,80006f34 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006f1a:	ffffe097          	auipc	ra,0xffffe
    80006f1e:	122080e7          	jalr	290(ra) # 8000503c <iunlockput>
  end_op();
    80006f22:	fffff097          	auipc	ra,0xfffff
    80006f26:	90a080e7          	jalr	-1782(ra) # 8000582c <end_op>
  return 0;
    80006f2a:	4501                	li	a0,0
}
    80006f2c:	60aa                	ld	ra,136(sp)
    80006f2e:	640a                	ld	s0,128(sp)
    80006f30:	6149                	addi	sp,sp,144
    80006f32:	8082                	ret
    end_op();
    80006f34:	fffff097          	auipc	ra,0xfffff
    80006f38:	8f8080e7          	jalr	-1800(ra) # 8000582c <end_op>
    return -1;
    80006f3c:	557d                	li	a0,-1
    80006f3e:	b7fd                	j	80006f2c <sys_mkdir+0x4c>

0000000080006f40 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006f40:	7135                	addi	sp,sp,-160
    80006f42:	ed06                	sd	ra,152(sp)
    80006f44:	e922                	sd	s0,144(sp)
    80006f46:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006f48:	fffff097          	auipc	ra,0xfffff
    80006f4c:	864080e7          	jalr	-1948(ra) # 800057ac <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006f50:	08000613          	li	a2,128
    80006f54:	f7040593          	addi	a1,s0,-144
    80006f58:	4501                	li	a0,0
    80006f5a:	ffffd097          	auipc	ra,0xffffd
    80006f5e:	2a6080e7          	jalr	678(ra) # 80004200 <argstr>
    80006f62:	04054a63          	bltz	a0,80006fb6 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006f66:	f6c40593          	addi	a1,s0,-148
    80006f6a:	4505                	li	a0,1
    80006f6c:	ffffd097          	auipc	ra,0xffffd
    80006f70:	250080e7          	jalr	592(ra) # 800041bc <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006f74:	04054163          	bltz	a0,80006fb6 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006f78:	f6840593          	addi	a1,s0,-152
    80006f7c:	4509                	li	a0,2
    80006f7e:	ffffd097          	auipc	ra,0xffffd
    80006f82:	23e080e7          	jalr	574(ra) # 800041bc <argint>
     argint(1, &major) < 0 ||
    80006f86:	02054863          	bltz	a0,80006fb6 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006f8a:	f6841683          	lh	a3,-152(s0)
    80006f8e:	f6c41603          	lh	a2,-148(s0)
    80006f92:	458d                	li	a1,3
    80006f94:	f7040513          	addi	a0,s0,-144
    80006f98:	fffff097          	auipc	ra,0xfffff
    80006f9c:	774080e7          	jalr	1908(ra) # 8000670c <create>
     argint(2, &minor) < 0 ||
    80006fa0:	c919                	beqz	a0,80006fb6 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006fa2:	ffffe097          	auipc	ra,0xffffe
    80006fa6:	09a080e7          	jalr	154(ra) # 8000503c <iunlockput>
  end_op();
    80006faa:	fffff097          	auipc	ra,0xfffff
    80006fae:	882080e7          	jalr	-1918(ra) # 8000582c <end_op>
  return 0;
    80006fb2:	4501                	li	a0,0
    80006fb4:	a031                	j	80006fc0 <sys_mknod+0x80>
    end_op();
    80006fb6:	fffff097          	auipc	ra,0xfffff
    80006fba:	876080e7          	jalr	-1930(ra) # 8000582c <end_op>
    return -1;
    80006fbe:	557d                	li	a0,-1
}
    80006fc0:	60ea                	ld	ra,152(sp)
    80006fc2:	644a                	ld	s0,144(sp)
    80006fc4:	610d                	addi	sp,sp,160
    80006fc6:	8082                	ret

0000000080006fc8 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006fc8:	7135                	addi	sp,sp,-160
    80006fca:	ed06                	sd	ra,152(sp)
    80006fcc:	e922                	sd	s0,144(sp)
    80006fce:	e526                	sd	s1,136(sp)
    80006fd0:	e14a                	sd	s2,128(sp)
    80006fd2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006fd4:	ffffb097          	auipc	ra,0xffffb
    80006fd8:	bf0080e7          	jalr	-1040(ra) # 80001bc4 <myproc>
    80006fdc:	892a                	mv	s2,a0
  
  begin_op();
    80006fde:	ffffe097          	auipc	ra,0xffffe
    80006fe2:	7ce080e7          	jalr	1998(ra) # 800057ac <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006fe6:	08000613          	li	a2,128
    80006fea:	f6040593          	addi	a1,s0,-160
    80006fee:	4501                	li	a0,0
    80006ff0:	ffffd097          	auipc	ra,0xffffd
    80006ff4:	210080e7          	jalr	528(ra) # 80004200 <argstr>
    80006ff8:	04054b63          	bltz	a0,8000704e <sys_chdir+0x86>
    80006ffc:	f6040513          	addi	a0,s0,-160
    80007000:	ffffe097          	auipc	ra,0xffffe
    80007004:	590080e7          	jalr	1424(ra) # 80005590 <namei>
    80007008:	84aa                	mv	s1,a0
    8000700a:	c131                	beqz	a0,8000704e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000700c:	ffffe097          	auipc	ra,0xffffe
    80007010:	dce080e7          	jalr	-562(ra) # 80004dda <ilock>
  if(ip->type != T_DIR){
    80007014:	04449703          	lh	a4,68(s1)
    80007018:	4785                	li	a5,1
    8000701a:	04f71063          	bne	a4,a5,8000705a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000701e:	8526                	mv	a0,s1
    80007020:	ffffe097          	auipc	ra,0xffffe
    80007024:	e7c080e7          	jalr	-388(ra) # 80004e9c <iunlock>
  iput(p->cwd);
    80007028:	18093503          	ld	a0,384(s2)
    8000702c:	ffffe097          	auipc	ra,0xffffe
    80007030:	f68080e7          	jalr	-152(ra) # 80004f94 <iput>
  end_op();
    80007034:	ffffe097          	auipc	ra,0xffffe
    80007038:	7f8080e7          	jalr	2040(ra) # 8000582c <end_op>
  p->cwd = ip;
    8000703c:	18993023          	sd	s1,384(s2)
  return 0;
    80007040:	4501                	li	a0,0
}
    80007042:	60ea                	ld	ra,152(sp)
    80007044:	644a                	ld	s0,144(sp)
    80007046:	64aa                	ld	s1,136(sp)
    80007048:	690a                	ld	s2,128(sp)
    8000704a:	610d                	addi	sp,sp,160
    8000704c:	8082                	ret
    end_op();
    8000704e:	ffffe097          	auipc	ra,0xffffe
    80007052:	7de080e7          	jalr	2014(ra) # 8000582c <end_op>
    return -1;
    80007056:	557d                	li	a0,-1
    80007058:	b7ed                	j	80007042 <sys_chdir+0x7a>
    iunlockput(ip);
    8000705a:	8526                	mv	a0,s1
    8000705c:	ffffe097          	auipc	ra,0xffffe
    80007060:	fe0080e7          	jalr	-32(ra) # 8000503c <iunlockput>
    end_op();
    80007064:	ffffe097          	auipc	ra,0xffffe
    80007068:	7c8080e7          	jalr	1992(ra) # 8000582c <end_op>
    return -1;
    8000706c:	557d                	li	a0,-1
    8000706e:	bfd1                	j	80007042 <sys_chdir+0x7a>

0000000080007070 <sys_exec>:

uint64
sys_exec(void)
{
    80007070:	7145                	addi	sp,sp,-464
    80007072:	e786                	sd	ra,456(sp)
    80007074:	e3a2                	sd	s0,448(sp)
    80007076:	ff26                	sd	s1,440(sp)
    80007078:	fb4a                	sd	s2,432(sp)
    8000707a:	f74e                	sd	s3,424(sp)
    8000707c:	f352                	sd	s4,416(sp)
    8000707e:	ef56                	sd	s5,408(sp)
    80007080:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80007082:	08000613          	li	a2,128
    80007086:	f4040593          	addi	a1,s0,-192
    8000708a:	4501                	li	a0,0
    8000708c:	ffffd097          	auipc	ra,0xffffd
    80007090:	174080e7          	jalr	372(ra) # 80004200 <argstr>
    return -1;
    80007094:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80007096:	0c054a63          	bltz	a0,8000716a <sys_exec+0xfa>
    8000709a:	e3840593          	addi	a1,s0,-456
    8000709e:	4505                	li	a0,1
    800070a0:	ffffd097          	auipc	ra,0xffffd
    800070a4:	13e080e7          	jalr	318(ra) # 800041de <argaddr>
    800070a8:	0c054163          	bltz	a0,8000716a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800070ac:	10000613          	li	a2,256
    800070b0:	4581                	li	a1,0
    800070b2:	e4040513          	addi	a0,s0,-448
    800070b6:	ffffa097          	auipc	ra,0xffffa
    800070ba:	c2a080e7          	jalr	-982(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800070be:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800070c2:	89a6                	mv	s3,s1
    800070c4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800070c6:	02000a13          	li	s4,32
    800070ca:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800070ce:	00391513          	slli	a0,s2,0x3
    800070d2:	e3040593          	addi	a1,s0,-464
    800070d6:	e3843783          	ld	a5,-456(s0)
    800070da:	953e                	add	a0,a0,a5
    800070dc:	ffffd097          	auipc	ra,0xffffd
    800070e0:	046080e7          	jalr	70(ra) # 80004122 <fetchaddr>
    800070e4:	02054a63          	bltz	a0,80007118 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800070e8:	e3043783          	ld	a5,-464(s0)
    800070ec:	c3b9                	beqz	a5,80007132 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800070ee:	ffffa097          	auipc	ra,0xffffa
    800070f2:	a06080e7          	jalr	-1530(ra) # 80000af4 <kalloc>
    800070f6:	85aa                	mv	a1,a0
    800070f8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800070fc:	cd11                	beqz	a0,80007118 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800070fe:	6605                	lui	a2,0x1
    80007100:	e3043503          	ld	a0,-464(s0)
    80007104:	ffffd097          	auipc	ra,0xffffd
    80007108:	070080e7          	jalr	112(ra) # 80004174 <fetchstr>
    8000710c:	00054663          	bltz	a0,80007118 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80007110:	0905                	addi	s2,s2,1
    80007112:	09a1                	addi	s3,s3,8
    80007114:	fb491be3          	bne	s2,s4,800070ca <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80007118:	10048913          	addi	s2,s1,256
    8000711c:	6088                	ld	a0,0(s1)
    8000711e:	c529                	beqz	a0,80007168 <sys_exec+0xf8>
    kfree(argv[i]);
    80007120:	ffffa097          	auipc	ra,0xffffa
    80007124:	8d8080e7          	jalr	-1832(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80007128:	04a1                	addi	s1,s1,8
    8000712a:	ff2499e3          	bne	s1,s2,8000711c <sys_exec+0xac>
  return -1;
    8000712e:	597d                	li	s2,-1
    80007130:	a82d                	j	8000716a <sys_exec+0xfa>
      argv[i] = 0;
    80007132:	0a8e                	slli	s5,s5,0x3
    80007134:	fc040793          	addi	a5,s0,-64
    80007138:	9abe                	add	s5,s5,a5
    8000713a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000713e:	e4040593          	addi	a1,s0,-448
    80007142:	f4040513          	addi	a0,s0,-192
    80007146:	fffff097          	auipc	ra,0xfffff
    8000714a:	192080e7          	jalr	402(ra) # 800062d8 <exec>
    8000714e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80007150:	10048993          	addi	s3,s1,256
    80007154:	6088                	ld	a0,0(s1)
    80007156:	c911                	beqz	a0,8000716a <sys_exec+0xfa>
    kfree(argv[i]);
    80007158:	ffffa097          	auipc	ra,0xffffa
    8000715c:	8a0080e7          	jalr	-1888(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80007160:	04a1                	addi	s1,s1,8
    80007162:	ff3499e3          	bne	s1,s3,80007154 <sys_exec+0xe4>
    80007166:	a011                	j	8000716a <sys_exec+0xfa>
  return -1;
    80007168:	597d                	li	s2,-1
}
    8000716a:	854a                	mv	a0,s2
    8000716c:	60be                	ld	ra,456(sp)
    8000716e:	641e                	ld	s0,448(sp)
    80007170:	74fa                	ld	s1,440(sp)
    80007172:	795a                	ld	s2,432(sp)
    80007174:	79ba                	ld	s3,424(sp)
    80007176:	7a1a                	ld	s4,416(sp)
    80007178:	6afa                	ld	s5,408(sp)
    8000717a:	6179                	addi	sp,sp,464
    8000717c:	8082                	ret

000000008000717e <sys_pipe>:

uint64
sys_pipe(void)
{
    8000717e:	7139                	addi	sp,sp,-64
    80007180:	fc06                	sd	ra,56(sp)
    80007182:	f822                	sd	s0,48(sp)
    80007184:	f426                	sd	s1,40(sp)
    80007186:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80007188:	ffffb097          	auipc	ra,0xffffb
    8000718c:	a3c080e7          	jalr	-1476(ra) # 80001bc4 <myproc>
    80007190:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80007192:	fd840593          	addi	a1,s0,-40
    80007196:	4501                	li	a0,0
    80007198:	ffffd097          	auipc	ra,0xffffd
    8000719c:	046080e7          	jalr	70(ra) # 800041de <argaddr>
    return -1;
    800071a0:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800071a2:	0e054263          	bltz	a0,80007286 <sys_pipe+0x108>
  if(pipealloc(&rf, &wf) < 0)
    800071a6:	fc840593          	addi	a1,s0,-56
    800071aa:	fd040513          	addi	a0,s0,-48
    800071ae:	fffff097          	auipc	ra,0xfffff
    800071b2:	dfa080e7          	jalr	-518(ra) # 80005fa8 <pipealloc>
    return -1;
    800071b6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800071b8:	0c054763          	bltz	a0,80007286 <sys_pipe+0x108>
  fd0 = -1;
    800071bc:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800071c0:	fd043503          	ld	a0,-48(s0)
    800071c4:	fffff097          	auipc	ra,0xfffff
    800071c8:	506080e7          	jalr	1286(ra) # 800066ca <fdalloc>
    800071cc:	fca42223          	sw	a0,-60(s0)
    800071d0:	08054e63          	bltz	a0,8000726c <sys_pipe+0xee>
    800071d4:	fc843503          	ld	a0,-56(s0)
    800071d8:	fffff097          	auipc	ra,0xfffff
    800071dc:	4f2080e7          	jalr	1266(ra) # 800066ca <fdalloc>
    800071e0:	fca42023          	sw	a0,-64(s0)
    800071e4:	06054a63          	bltz	a0,80007258 <sys_pipe+0xda>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800071e8:	4691                	li	a3,4
    800071ea:	fc440613          	addi	a2,s0,-60
    800071ee:	fd843583          	ld	a1,-40(s0)
    800071f2:	60c8                	ld	a0,128(s1)
    800071f4:	ffffa097          	auipc	ra,0xffffa
    800071f8:	486080e7          	jalr	1158(ra) # 8000167a <copyout>
    800071fc:	02054063          	bltz	a0,8000721c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80007200:	4691                	li	a3,4
    80007202:	fc040613          	addi	a2,s0,-64
    80007206:	fd843583          	ld	a1,-40(s0)
    8000720a:	0591                	addi	a1,a1,4
    8000720c:	60c8                	ld	a0,128(s1)
    8000720e:	ffffa097          	auipc	ra,0xffffa
    80007212:	46c080e7          	jalr	1132(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80007216:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80007218:	06055763          	bgez	a0,80007286 <sys_pipe+0x108>
    p->ofile[fd0] = 0;
    8000721c:	fc442783          	lw	a5,-60(s0)
    80007220:	02078793          	addi	a5,a5,32
    80007224:	078e                	slli	a5,a5,0x3
    80007226:	97a6                	add	a5,a5,s1
    80007228:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000722c:	fc042503          	lw	a0,-64(s0)
    80007230:	02050513          	addi	a0,a0,32
    80007234:	050e                	slli	a0,a0,0x3
    80007236:	9526                	add	a0,a0,s1
    80007238:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000723c:	fd043503          	ld	a0,-48(s0)
    80007240:	fffff097          	auipc	ra,0xfffff
    80007244:	a38080e7          	jalr	-1480(ra) # 80005c78 <fileclose>
    fileclose(wf);
    80007248:	fc843503          	ld	a0,-56(s0)
    8000724c:	fffff097          	auipc	ra,0xfffff
    80007250:	a2c080e7          	jalr	-1492(ra) # 80005c78 <fileclose>
    return -1;
    80007254:	57fd                	li	a5,-1
    80007256:	a805                	j	80007286 <sys_pipe+0x108>
    if(fd0 >= 0)
    80007258:	fc442783          	lw	a5,-60(s0)
    8000725c:	0007c863          	bltz	a5,8000726c <sys_pipe+0xee>
      p->ofile[fd0] = 0;
    80007260:	02078513          	addi	a0,a5,32
    80007264:	050e                	slli	a0,a0,0x3
    80007266:	9526                	add	a0,a0,s1
    80007268:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000726c:	fd043503          	ld	a0,-48(s0)
    80007270:	fffff097          	auipc	ra,0xfffff
    80007274:	a08080e7          	jalr	-1528(ra) # 80005c78 <fileclose>
    fileclose(wf);
    80007278:	fc843503          	ld	a0,-56(s0)
    8000727c:	fffff097          	auipc	ra,0xfffff
    80007280:	9fc080e7          	jalr	-1540(ra) # 80005c78 <fileclose>
    return -1;
    80007284:	57fd                	li	a5,-1
}
    80007286:	853e                	mv	a0,a5
    80007288:	70e2                	ld	ra,56(sp)
    8000728a:	7442                	ld	s0,48(sp)
    8000728c:	74a2                	ld	s1,40(sp)
    8000728e:	6121                	addi	sp,sp,64
    80007290:	8082                	ret
	...

00000000800072a0 <kernelvec>:
    800072a0:	7111                	addi	sp,sp,-256
    800072a2:	e006                	sd	ra,0(sp)
    800072a4:	e40a                	sd	sp,8(sp)
    800072a6:	e80e                	sd	gp,16(sp)
    800072a8:	ec12                	sd	tp,24(sp)
    800072aa:	f016                	sd	t0,32(sp)
    800072ac:	f41a                	sd	t1,40(sp)
    800072ae:	f81e                	sd	t2,48(sp)
    800072b0:	fc22                	sd	s0,56(sp)
    800072b2:	e0a6                	sd	s1,64(sp)
    800072b4:	e4aa                	sd	a0,72(sp)
    800072b6:	e8ae                	sd	a1,80(sp)
    800072b8:	ecb2                	sd	a2,88(sp)
    800072ba:	f0b6                	sd	a3,96(sp)
    800072bc:	f4ba                	sd	a4,104(sp)
    800072be:	f8be                	sd	a5,112(sp)
    800072c0:	fcc2                	sd	a6,120(sp)
    800072c2:	e146                	sd	a7,128(sp)
    800072c4:	e54a                	sd	s2,136(sp)
    800072c6:	e94e                	sd	s3,144(sp)
    800072c8:	ed52                	sd	s4,152(sp)
    800072ca:	f156                	sd	s5,160(sp)
    800072cc:	f55a                	sd	s6,168(sp)
    800072ce:	f95e                	sd	s7,176(sp)
    800072d0:	fd62                	sd	s8,184(sp)
    800072d2:	e1e6                	sd	s9,192(sp)
    800072d4:	e5ea                	sd	s10,200(sp)
    800072d6:	e9ee                	sd	s11,208(sp)
    800072d8:	edf2                	sd	t3,216(sp)
    800072da:	f1f6                	sd	t4,224(sp)
    800072dc:	f5fa                	sd	t5,232(sp)
    800072de:	f9fe                	sd	t6,240(sp)
    800072e0:	ce3fc0ef          	jal	ra,80003fc2 <kerneltrap>
    800072e4:	6082                	ld	ra,0(sp)
    800072e6:	6122                	ld	sp,8(sp)
    800072e8:	61c2                	ld	gp,16(sp)
    800072ea:	7282                	ld	t0,32(sp)
    800072ec:	7322                	ld	t1,40(sp)
    800072ee:	73c2                	ld	t2,48(sp)
    800072f0:	7462                	ld	s0,56(sp)
    800072f2:	6486                	ld	s1,64(sp)
    800072f4:	6526                	ld	a0,72(sp)
    800072f6:	65c6                	ld	a1,80(sp)
    800072f8:	6666                	ld	a2,88(sp)
    800072fa:	7686                	ld	a3,96(sp)
    800072fc:	7726                	ld	a4,104(sp)
    800072fe:	77c6                	ld	a5,112(sp)
    80007300:	7866                	ld	a6,120(sp)
    80007302:	688a                	ld	a7,128(sp)
    80007304:	692a                	ld	s2,136(sp)
    80007306:	69ca                	ld	s3,144(sp)
    80007308:	6a6a                	ld	s4,152(sp)
    8000730a:	7a8a                	ld	s5,160(sp)
    8000730c:	7b2a                	ld	s6,168(sp)
    8000730e:	7bca                	ld	s7,176(sp)
    80007310:	7c6a                	ld	s8,184(sp)
    80007312:	6c8e                	ld	s9,192(sp)
    80007314:	6d2e                	ld	s10,200(sp)
    80007316:	6dce                	ld	s11,208(sp)
    80007318:	6e6e                	ld	t3,216(sp)
    8000731a:	7e8e                	ld	t4,224(sp)
    8000731c:	7f2e                	ld	t5,232(sp)
    8000731e:	7fce                	ld	t6,240(sp)
    80007320:	6111                	addi	sp,sp,256
    80007322:	10200073          	sret
    80007326:	00000013          	nop
    8000732a:	00000013          	nop
    8000732e:	0001                	nop

0000000080007330 <timervec>:
    80007330:	34051573          	csrrw	a0,mscratch,a0
    80007334:	e10c                	sd	a1,0(a0)
    80007336:	e510                	sd	a2,8(a0)
    80007338:	e914                	sd	a3,16(a0)
    8000733a:	6d0c                	ld	a1,24(a0)
    8000733c:	7110                	ld	a2,32(a0)
    8000733e:	6194                	ld	a3,0(a1)
    80007340:	96b2                	add	a3,a3,a2
    80007342:	e194                	sd	a3,0(a1)
    80007344:	4589                	li	a1,2
    80007346:	14459073          	csrw	sip,a1
    8000734a:	6914                	ld	a3,16(a0)
    8000734c:	6510                	ld	a2,8(a0)
    8000734e:	610c                	ld	a1,0(a0)
    80007350:	34051573          	csrrw	a0,mscratch,a0
    80007354:	30200073          	mret
	...

000000008000735a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000735a:	1141                	addi	sp,sp,-16
    8000735c:	e422                	sd	s0,8(sp)
    8000735e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80007360:	0c0007b7          	lui	a5,0xc000
    80007364:	4705                	li	a4,1
    80007366:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80007368:	c3d8                	sw	a4,4(a5)
}
    8000736a:	6422                	ld	s0,8(sp)
    8000736c:	0141                	addi	sp,sp,16
    8000736e:	8082                	ret

0000000080007370 <plicinithart>:

void
plicinithart(void)
{
    80007370:	1141                	addi	sp,sp,-16
    80007372:	e406                	sd	ra,8(sp)
    80007374:	e022                	sd	s0,0(sp)
    80007376:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80007378:	ffffb097          	auipc	ra,0xffffb
    8000737c:	810080e7          	jalr	-2032(ra) # 80001b88 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80007380:	0085171b          	slliw	a4,a0,0x8
    80007384:	0c0027b7          	lui	a5,0xc002
    80007388:	97ba                	add	a5,a5,a4
    8000738a:	40200713          	li	a4,1026
    8000738e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80007392:	00d5151b          	slliw	a0,a0,0xd
    80007396:	0c2017b7          	lui	a5,0xc201
    8000739a:	953e                	add	a0,a0,a5
    8000739c:	00052023          	sw	zero,0(a0)
}
    800073a0:	60a2                	ld	ra,8(sp)
    800073a2:	6402                	ld	s0,0(sp)
    800073a4:	0141                	addi	sp,sp,16
    800073a6:	8082                	ret

00000000800073a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800073a8:	1141                	addi	sp,sp,-16
    800073aa:	e406                	sd	ra,8(sp)
    800073ac:	e022                	sd	s0,0(sp)
    800073ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800073b0:	ffffa097          	auipc	ra,0xffffa
    800073b4:	7d8080e7          	jalr	2008(ra) # 80001b88 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800073b8:	00d5179b          	slliw	a5,a0,0xd
    800073bc:	0c201537          	lui	a0,0xc201
    800073c0:	953e                	add	a0,a0,a5
  return irq;
}
    800073c2:	4148                	lw	a0,4(a0)
    800073c4:	60a2                	ld	ra,8(sp)
    800073c6:	6402                	ld	s0,0(sp)
    800073c8:	0141                	addi	sp,sp,16
    800073ca:	8082                	ret

00000000800073cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800073cc:	1101                	addi	sp,sp,-32
    800073ce:	ec06                	sd	ra,24(sp)
    800073d0:	e822                	sd	s0,16(sp)
    800073d2:	e426                	sd	s1,8(sp)
    800073d4:	1000                	addi	s0,sp,32
    800073d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800073d8:	ffffa097          	auipc	ra,0xffffa
    800073dc:	7b0080e7          	jalr	1968(ra) # 80001b88 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800073e0:	00d5151b          	slliw	a0,a0,0xd
    800073e4:	0c2017b7          	lui	a5,0xc201
    800073e8:	97aa                	add	a5,a5,a0
    800073ea:	c3c4                	sw	s1,4(a5)
}
    800073ec:	60e2                	ld	ra,24(sp)
    800073ee:	6442                	ld	s0,16(sp)
    800073f0:	64a2                	ld	s1,8(sp)
    800073f2:	6105                	addi	sp,sp,32
    800073f4:	8082                	ret

00000000800073f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800073f6:	1141                	addi	sp,sp,-16
    800073f8:	e406                	sd	ra,8(sp)
    800073fa:	e022                	sd	s0,0(sp)
    800073fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800073fe:	479d                	li	a5,7
    80007400:	06a7c963          	blt	a5,a0,80007472 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80007404:	0001e797          	auipc	a5,0x1e
    80007408:	bfc78793          	addi	a5,a5,-1028 # 80025000 <disk>
    8000740c:	00a78733          	add	a4,a5,a0
    80007410:	6789                	lui	a5,0x2
    80007412:	97ba                	add	a5,a5,a4
    80007414:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80007418:	e7ad                	bnez	a5,80007482 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000741a:	00451793          	slli	a5,a0,0x4
    8000741e:	00020717          	auipc	a4,0x20
    80007422:	be270713          	addi	a4,a4,-1054 # 80027000 <disk+0x2000>
    80007426:	6314                	ld	a3,0(a4)
    80007428:	96be                	add	a3,a3,a5
    8000742a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000742e:	6314                	ld	a3,0(a4)
    80007430:	96be                	add	a3,a3,a5
    80007432:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80007436:	6314                	ld	a3,0(a4)
    80007438:	96be                	add	a3,a3,a5
    8000743a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000743e:	6318                	ld	a4,0(a4)
    80007440:	97ba                	add	a5,a5,a4
    80007442:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80007446:	0001e797          	auipc	a5,0x1e
    8000744a:	bba78793          	addi	a5,a5,-1094 # 80025000 <disk>
    8000744e:	97aa                	add	a5,a5,a0
    80007450:	6509                	lui	a0,0x2
    80007452:	953e                	add	a0,a0,a5
    80007454:	4785                	li	a5,1
    80007456:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000745a:	00020517          	auipc	a0,0x20
    8000745e:	bbe50513          	addi	a0,a0,-1090 # 80027018 <disk+0x2018>
    80007462:	ffffc097          	auipc	ra,0xffffc
    80007466:	cd6080e7          	jalr	-810(ra) # 80003138 <wakeup>
}
    8000746a:	60a2                	ld	ra,8(sp)
    8000746c:	6402                	ld	s0,0(sp)
    8000746e:	0141                	addi	sp,sp,16
    80007470:	8082                	ret
    panic("free_desc 1");
    80007472:	00002517          	auipc	a0,0x2
    80007476:	77e50513          	addi	a0,a0,1918 # 80009bf0 <syscalls+0x348>
    8000747a:	ffff9097          	auipc	ra,0xffff9
    8000747e:	0c4080e7          	jalr	196(ra) # 8000053e <panic>
    panic("free_desc 2");
    80007482:	00002517          	auipc	a0,0x2
    80007486:	77e50513          	addi	a0,a0,1918 # 80009c00 <syscalls+0x358>
    8000748a:	ffff9097          	auipc	ra,0xffff9
    8000748e:	0b4080e7          	jalr	180(ra) # 8000053e <panic>

0000000080007492 <virtio_disk_init>:
{
    80007492:	1101                	addi	sp,sp,-32
    80007494:	ec06                	sd	ra,24(sp)
    80007496:	e822                	sd	s0,16(sp)
    80007498:	e426                	sd	s1,8(sp)
    8000749a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000749c:	00002597          	auipc	a1,0x2
    800074a0:	77458593          	addi	a1,a1,1908 # 80009c10 <syscalls+0x368>
    800074a4:	00020517          	auipc	a0,0x20
    800074a8:	c8450513          	addi	a0,a0,-892 # 80027128 <disk+0x2128>
    800074ac:	ffff9097          	auipc	ra,0xffff9
    800074b0:	6a8080e7          	jalr	1704(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800074b4:	100017b7          	lui	a5,0x10001
    800074b8:	4398                	lw	a4,0(a5)
    800074ba:	2701                	sext.w	a4,a4
    800074bc:	747277b7          	lui	a5,0x74727
    800074c0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800074c4:	0ef71163          	bne	a4,a5,800075a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800074c8:	100017b7          	lui	a5,0x10001
    800074cc:	43dc                	lw	a5,4(a5)
    800074ce:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800074d0:	4705                	li	a4,1
    800074d2:	0ce79a63          	bne	a5,a4,800075a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800074d6:	100017b7          	lui	a5,0x10001
    800074da:	479c                	lw	a5,8(a5)
    800074dc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800074de:	4709                	li	a4,2
    800074e0:	0ce79363          	bne	a5,a4,800075a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800074e4:	100017b7          	lui	a5,0x10001
    800074e8:	47d8                	lw	a4,12(a5)
    800074ea:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800074ec:	554d47b7          	lui	a5,0x554d4
    800074f0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800074f4:	0af71963          	bne	a4,a5,800075a6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800074f8:	100017b7          	lui	a5,0x10001
    800074fc:	4705                	li	a4,1
    800074fe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80007500:	470d                	li	a4,3
    80007502:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80007504:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80007506:	c7ffe737          	lui	a4,0xc7ffe
    8000750a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd675f>
    8000750e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80007510:	2701                	sext.w	a4,a4
    80007512:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80007514:	472d                	li	a4,11
    80007516:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80007518:	473d                	li	a4,15
    8000751a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000751c:	6705                	lui	a4,0x1
    8000751e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80007520:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80007524:	5bdc                	lw	a5,52(a5)
    80007526:	2781                	sext.w	a5,a5
  if(max == 0)
    80007528:	c7d9                	beqz	a5,800075b6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000752a:	471d                	li	a4,7
    8000752c:	08f77d63          	bgeu	a4,a5,800075c6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80007530:	100014b7          	lui	s1,0x10001
    80007534:	47a1                	li	a5,8
    80007536:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80007538:	6609                	lui	a2,0x2
    8000753a:	4581                	li	a1,0
    8000753c:	0001e517          	auipc	a0,0x1e
    80007540:	ac450513          	addi	a0,a0,-1340 # 80025000 <disk>
    80007544:	ffff9097          	auipc	ra,0xffff9
    80007548:	79c080e7          	jalr	1948(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000754c:	0001e717          	auipc	a4,0x1e
    80007550:	ab470713          	addi	a4,a4,-1356 # 80025000 <disk>
    80007554:	00c75793          	srli	a5,a4,0xc
    80007558:	2781                	sext.w	a5,a5
    8000755a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000755c:	00020797          	auipc	a5,0x20
    80007560:	aa478793          	addi	a5,a5,-1372 # 80027000 <disk+0x2000>
    80007564:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80007566:	0001e717          	auipc	a4,0x1e
    8000756a:	b1a70713          	addi	a4,a4,-1254 # 80025080 <disk+0x80>
    8000756e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80007570:	0001f717          	auipc	a4,0x1f
    80007574:	a9070713          	addi	a4,a4,-1392 # 80026000 <disk+0x1000>
    80007578:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000757a:	4705                	li	a4,1
    8000757c:	00e78c23          	sb	a4,24(a5)
    80007580:	00e78ca3          	sb	a4,25(a5)
    80007584:	00e78d23          	sb	a4,26(a5)
    80007588:	00e78da3          	sb	a4,27(a5)
    8000758c:	00e78e23          	sb	a4,28(a5)
    80007590:	00e78ea3          	sb	a4,29(a5)
    80007594:	00e78f23          	sb	a4,30(a5)
    80007598:	00e78fa3          	sb	a4,31(a5)
}
    8000759c:	60e2                	ld	ra,24(sp)
    8000759e:	6442                	ld	s0,16(sp)
    800075a0:	64a2                	ld	s1,8(sp)
    800075a2:	6105                	addi	sp,sp,32
    800075a4:	8082                	ret
    panic("could not find virtio disk");
    800075a6:	00002517          	auipc	a0,0x2
    800075aa:	67a50513          	addi	a0,a0,1658 # 80009c20 <syscalls+0x378>
    800075ae:	ffff9097          	auipc	ra,0xffff9
    800075b2:	f90080e7          	jalr	-112(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800075b6:	00002517          	auipc	a0,0x2
    800075ba:	68a50513          	addi	a0,a0,1674 # 80009c40 <syscalls+0x398>
    800075be:	ffff9097          	auipc	ra,0xffff9
    800075c2:	f80080e7          	jalr	-128(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800075c6:	00002517          	auipc	a0,0x2
    800075ca:	69a50513          	addi	a0,a0,1690 # 80009c60 <syscalls+0x3b8>
    800075ce:	ffff9097          	auipc	ra,0xffff9
    800075d2:	f70080e7          	jalr	-144(ra) # 8000053e <panic>

00000000800075d6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800075d6:	7159                	addi	sp,sp,-112
    800075d8:	f486                	sd	ra,104(sp)
    800075da:	f0a2                	sd	s0,96(sp)
    800075dc:	eca6                	sd	s1,88(sp)
    800075de:	e8ca                	sd	s2,80(sp)
    800075e0:	e4ce                	sd	s3,72(sp)
    800075e2:	e0d2                	sd	s4,64(sp)
    800075e4:	fc56                	sd	s5,56(sp)
    800075e6:	f85a                	sd	s6,48(sp)
    800075e8:	f45e                	sd	s7,40(sp)
    800075ea:	f062                	sd	s8,32(sp)
    800075ec:	ec66                	sd	s9,24(sp)
    800075ee:	e86a                	sd	s10,16(sp)
    800075f0:	1880                	addi	s0,sp,112
    800075f2:	892a                	mv	s2,a0
    800075f4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800075f6:	00c52c83          	lw	s9,12(a0)
    800075fa:	001c9c9b          	slliw	s9,s9,0x1
    800075fe:	1c82                	slli	s9,s9,0x20
    80007600:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80007604:	00020517          	auipc	a0,0x20
    80007608:	b2450513          	addi	a0,a0,-1244 # 80027128 <disk+0x2128>
    8000760c:	ffff9097          	auipc	ra,0xffff9
    80007610:	5d8080e7          	jalr	1496(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80007614:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80007616:	4c21                	li	s8,8
      disk.free[i] = 0;
    80007618:	0001eb97          	auipc	s7,0x1e
    8000761c:	9e8b8b93          	addi	s7,s7,-1560 # 80025000 <disk>
    80007620:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80007622:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80007624:	8a4e                	mv	s4,s3
    80007626:	a051                	j	800076aa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80007628:	00fb86b3          	add	a3,s7,a5
    8000762c:	96da                	add	a3,a3,s6
    8000762e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80007632:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80007634:	0207c563          	bltz	a5,8000765e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80007638:	2485                	addiw	s1,s1,1
    8000763a:	0711                	addi	a4,a4,4
    8000763c:	25548063          	beq	s1,s5,8000787c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80007640:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80007642:	00020697          	auipc	a3,0x20
    80007646:	9d668693          	addi	a3,a3,-1578 # 80027018 <disk+0x2018>
    8000764a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000764c:	0006c583          	lbu	a1,0(a3)
    80007650:	fde1                	bnez	a1,80007628 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80007652:	2785                	addiw	a5,a5,1
    80007654:	0685                	addi	a3,a3,1
    80007656:	ff879be3          	bne	a5,s8,8000764c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000765a:	57fd                	li	a5,-1
    8000765c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000765e:	02905a63          	blez	s1,80007692 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80007662:	f9042503          	lw	a0,-112(s0)
    80007666:	00000097          	auipc	ra,0x0
    8000766a:	d90080e7          	jalr	-624(ra) # 800073f6 <free_desc>
      for(int j = 0; j < i; j++)
    8000766e:	4785                	li	a5,1
    80007670:	0297d163          	bge	a5,s1,80007692 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80007674:	f9442503          	lw	a0,-108(s0)
    80007678:	00000097          	auipc	ra,0x0
    8000767c:	d7e080e7          	jalr	-642(ra) # 800073f6 <free_desc>
      for(int j = 0; j < i; j++)
    80007680:	4789                	li	a5,2
    80007682:	0097d863          	bge	a5,s1,80007692 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80007686:	f9842503          	lw	a0,-104(s0)
    8000768a:	00000097          	auipc	ra,0x0
    8000768e:	d6c080e7          	jalr	-660(ra) # 800073f6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80007692:	00020597          	auipc	a1,0x20
    80007696:	a9658593          	addi	a1,a1,-1386 # 80027128 <disk+0x2128>
    8000769a:	00020517          	auipc	a0,0x20
    8000769e:	97e50513          	addi	a0,a0,-1666 # 80027018 <disk+0x2018>
    800076a2:	ffffb097          	auipc	ra,0xffffb
    800076a6:	680080e7          	jalr	1664(ra) # 80002d22 <sleep>
  for(int i = 0; i < 3; i++){
    800076aa:	f9040713          	addi	a4,s0,-112
    800076ae:	84ce                	mv	s1,s3
    800076b0:	bf41                	j	80007640 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800076b2:	20058713          	addi	a4,a1,512
    800076b6:	00471693          	slli	a3,a4,0x4
    800076ba:	0001e717          	auipc	a4,0x1e
    800076be:	94670713          	addi	a4,a4,-1722 # 80025000 <disk>
    800076c2:	9736                	add	a4,a4,a3
    800076c4:	4685                	li	a3,1
    800076c6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800076ca:	20058713          	addi	a4,a1,512
    800076ce:	00471693          	slli	a3,a4,0x4
    800076d2:	0001e717          	auipc	a4,0x1e
    800076d6:	92e70713          	addi	a4,a4,-1746 # 80025000 <disk>
    800076da:	9736                	add	a4,a4,a3
    800076dc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800076e0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800076e4:	7679                	lui	a2,0xffffe
    800076e6:	963e                	add	a2,a2,a5
    800076e8:	00020697          	auipc	a3,0x20
    800076ec:	91868693          	addi	a3,a3,-1768 # 80027000 <disk+0x2000>
    800076f0:	6298                	ld	a4,0(a3)
    800076f2:	9732                	add	a4,a4,a2
    800076f4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800076f6:	6298                	ld	a4,0(a3)
    800076f8:	9732                	add	a4,a4,a2
    800076fa:	4541                	li	a0,16
    800076fc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800076fe:	6298                	ld	a4,0(a3)
    80007700:	9732                	add	a4,a4,a2
    80007702:	4505                	li	a0,1
    80007704:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80007708:	f9442703          	lw	a4,-108(s0)
    8000770c:	6288                	ld	a0,0(a3)
    8000770e:	962a                	add	a2,a2,a0
    80007710:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd600e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80007714:	0712                	slli	a4,a4,0x4
    80007716:	6290                	ld	a2,0(a3)
    80007718:	963a                	add	a2,a2,a4
    8000771a:	05890513          	addi	a0,s2,88
    8000771e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80007720:	6294                	ld	a3,0(a3)
    80007722:	96ba                	add	a3,a3,a4
    80007724:	40000613          	li	a2,1024
    80007728:	c690                	sw	a2,8(a3)
  if(write)
    8000772a:	140d0063          	beqz	s10,8000786a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000772e:	00020697          	auipc	a3,0x20
    80007732:	8d26b683          	ld	a3,-1838(a3) # 80027000 <disk+0x2000>
    80007736:	96ba                	add	a3,a3,a4
    80007738:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000773c:	0001e817          	auipc	a6,0x1e
    80007740:	8c480813          	addi	a6,a6,-1852 # 80025000 <disk>
    80007744:	00020517          	auipc	a0,0x20
    80007748:	8bc50513          	addi	a0,a0,-1860 # 80027000 <disk+0x2000>
    8000774c:	6114                	ld	a3,0(a0)
    8000774e:	96ba                	add	a3,a3,a4
    80007750:	00c6d603          	lhu	a2,12(a3)
    80007754:	00166613          	ori	a2,a2,1
    80007758:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000775c:	f9842683          	lw	a3,-104(s0)
    80007760:	6110                	ld	a2,0(a0)
    80007762:	9732                	add	a4,a4,a2
    80007764:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80007768:	20058613          	addi	a2,a1,512
    8000776c:	0612                	slli	a2,a2,0x4
    8000776e:	9642                	add	a2,a2,a6
    80007770:	577d                	li	a4,-1
    80007772:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80007776:	00469713          	slli	a4,a3,0x4
    8000777a:	6114                	ld	a3,0(a0)
    8000777c:	96ba                	add	a3,a3,a4
    8000777e:	03078793          	addi	a5,a5,48
    80007782:	97c2                	add	a5,a5,a6
    80007784:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80007786:	611c                	ld	a5,0(a0)
    80007788:	97ba                	add	a5,a5,a4
    8000778a:	4685                	li	a3,1
    8000778c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000778e:	611c                	ld	a5,0(a0)
    80007790:	97ba                	add	a5,a5,a4
    80007792:	4809                	li	a6,2
    80007794:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80007798:	611c                	ld	a5,0(a0)
    8000779a:	973e                	add	a4,a4,a5
    8000779c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800077a0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800077a4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800077a8:	6518                	ld	a4,8(a0)
    800077aa:	00275783          	lhu	a5,2(a4)
    800077ae:	8b9d                	andi	a5,a5,7
    800077b0:	0786                	slli	a5,a5,0x1
    800077b2:	97ba                	add	a5,a5,a4
    800077b4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800077b8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800077bc:	6518                	ld	a4,8(a0)
    800077be:	00275783          	lhu	a5,2(a4)
    800077c2:	2785                	addiw	a5,a5,1
    800077c4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800077c8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800077cc:	100017b7          	lui	a5,0x10001
    800077d0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800077d4:	00492703          	lw	a4,4(s2)
    800077d8:	4785                	li	a5,1
    800077da:	02f71163          	bne	a4,a5,800077fc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800077de:	00020997          	auipc	s3,0x20
    800077e2:	94a98993          	addi	s3,s3,-1718 # 80027128 <disk+0x2128>
  while(b->disk == 1) {
    800077e6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800077e8:	85ce                	mv	a1,s3
    800077ea:	854a                	mv	a0,s2
    800077ec:	ffffb097          	auipc	ra,0xffffb
    800077f0:	536080e7          	jalr	1334(ra) # 80002d22 <sleep>
  while(b->disk == 1) {
    800077f4:	00492783          	lw	a5,4(s2)
    800077f8:	fe9788e3          	beq	a5,s1,800077e8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800077fc:	f9042903          	lw	s2,-112(s0)
    80007800:	20090793          	addi	a5,s2,512
    80007804:	00479713          	slli	a4,a5,0x4
    80007808:	0001d797          	auipc	a5,0x1d
    8000780c:	7f878793          	addi	a5,a5,2040 # 80025000 <disk>
    80007810:	97ba                	add	a5,a5,a4
    80007812:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80007816:	0001f997          	auipc	s3,0x1f
    8000781a:	7ea98993          	addi	s3,s3,2026 # 80027000 <disk+0x2000>
    8000781e:	00491713          	slli	a4,s2,0x4
    80007822:	0009b783          	ld	a5,0(s3)
    80007826:	97ba                	add	a5,a5,a4
    80007828:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000782c:	854a                	mv	a0,s2
    8000782e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80007832:	00000097          	auipc	ra,0x0
    80007836:	bc4080e7          	jalr	-1084(ra) # 800073f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000783a:	8885                	andi	s1,s1,1
    8000783c:	f0ed                	bnez	s1,8000781e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000783e:	00020517          	auipc	a0,0x20
    80007842:	8ea50513          	addi	a0,a0,-1814 # 80027128 <disk+0x2128>
    80007846:	ffff9097          	auipc	ra,0xffff9
    8000784a:	452080e7          	jalr	1106(ra) # 80000c98 <release>
}
    8000784e:	70a6                	ld	ra,104(sp)
    80007850:	7406                	ld	s0,96(sp)
    80007852:	64e6                	ld	s1,88(sp)
    80007854:	6946                	ld	s2,80(sp)
    80007856:	69a6                	ld	s3,72(sp)
    80007858:	6a06                	ld	s4,64(sp)
    8000785a:	7ae2                	ld	s5,56(sp)
    8000785c:	7b42                	ld	s6,48(sp)
    8000785e:	7ba2                	ld	s7,40(sp)
    80007860:	7c02                	ld	s8,32(sp)
    80007862:	6ce2                	ld	s9,24(sp)
    80007864:	6d42                	ld	s10,16(sp)
    80007866:	6165                	addi	sp,sp,112
    80007868:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000786a:	0001f697          	auipc	a3,0x1f
    8000786e:	7966b683          	ld	a3,1942(a3) # 80027000 <disk+0x2000>
    80007872:	96ba                	add	a3,a3,a4
    80007874:	4609                	li	a2,2
    80007876:	00c69623          	sh	a2,12(a3)
    8000787a:	b5c9                	j	8000773c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000787c:	f9042583          	lw	a1,-112(s0)
    80007880:	20058793          	addi	a5,a1,512
    80007884:	0792                	slli	a5,a5,0x4
    80007886:	0001e517          	auipc	a0,0x1e
    8000788a:	82250513          	addi	a0,a0,-2014 # 800250a8 <disk+0xa8>
    8000788e:	953e                	add	a0,a0,a5
  if(write)
    80007890:	e20d11e3          	bnez	s10,800076b2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80007894:	20058713          	addi	a4,a1,512
    80007898:	00471693          	slli	a3,a4,0x4
    8000789c:	0001d717          	auipc	a4,0x1d
    800078a0:	76470713          	addi	a4,a4,1892 # 80025000 <disk>
    800078a4:	9736                	add	a4,a4,a3
    800078a6:	0a072423          	sw	zero,168(a4)
    800078aa:	b505                	j	800076ca <virtio_disk_rw+0xf4>

00000000800078ac <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800078ac:	1101                	addi	sp,sp,-32
    800078ae:	ec06                	sd	ra,24(sp)
    800078b0:	e822                	sd	s0,16(sp)
    800078b2:	e426                	sd	s1,8(sp)
    800078b4:	e04a                	sd	s2,0(sp)
    800078b6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800078b8:	00020517          	auipc	a0,0x20
    800078bc:	87050513          	addi	a0,a0,-1936 # 80027128 <disk+0x2128>
    800078c0:	ffff9097          	auipc	ra,0xffff9
    800078c4:	324080e7          	jalr	804(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800078c8:	10001737          	lui	a4,0x10001
    800078cc:	533c                	lw	a5,96(a4)
    800078ce:	8b8d                	andi	a5,a5,3
    800078d0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800078d2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800078d6:	0001f797          	auipc	a5,0x1f
    800078da:	72a78793          	addi	a5,a5,1834 # 80027000 <disk+0x2000>
    800078de:	6b94                	ld	a3,16(a5)
    800078e0:	0207d703          	lhu	a4,32(a5)
    800078e4:	0026d783          	lhu	a5,2(a3)
    800078e8:	06f70163          	beq	a4,a5,8000794a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800078ec:	0001d917          	auipc	s2,0x1d
    800078f0:	71490913          	addi	s2,s2,1812 # 80025000 <disk>
    800078f4:	0001f497          	auipc	s1,0x1f
    800078f8:	70c48493          	addi	s1,s1,1804 # 80027000 <disk+0x2000>
    __sync_synchronize();
    800078fc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80007900:	6898                	ld	a4,16(s1)
    80007902:	0204d783          	lhu	a5,32(s1)
    80007906:	8b9d                	andi	a5,a5,7
    80007908:	078e                	slli	a5,a5,0x3
    8000790a:	97ba                	add	a5,a5,a4
    8000790c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000790e:	20078713          	addi	a4,a5,512
    80007912:	0712                	slli	a4,a4,0x4
    80007914:	974a                	add	a4,a4,s2
    80007916:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000791a:	e731                	bnez	a4,80007966 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000791c:	20078793          	addi	a5,a5,512
    80007920:	0792                	slli	a5,a5,0x4
    80007922:	97ca                	add	a5,a5,s2
    80007924:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80007926:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000792a:	ffffc097          	auipc	ra,0xffffc
    8000792e:	80e080e7          	jalr	-2034(ra) # 80003138 <wakeup>

    disk.used_idx += 1;
    80007932:	0204d783          	lhu	a5,32(s1)
    80007936:	2785                	addiw	a5,a5,1
    80007938:	17c2                	slli	a5,a5,0x30
    8000793a:	93c1                	srli	a5,a5,0x30
    8000793c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80007940:	6898                	ld	a4,16(s1)
    80007942:	00275703          	lhu	a4,2(a4)
    80007946:	faf71be3          	bne	a4,a5,800078fc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000794a:	0001f517          	auipc	a0,0x1f
    8000794e:	7de50513          	addi	a0,a0,2014 # 80027128 <disk+0x2128>
    80007952:	ffff9097          	auipc	ra,0xffff9
    80007956:	346080e7          	jalr	838(ra) # 80000c98 <release>
}
    8000795a:	60e2                	ld	ra,24(sp)
    8000795c:	6442                	ld	s0,16(sp)
    8000795e:	64a2                	ld	s1,8(sp)
    80007960:	6902                	ld	s2,0(sp)
    80007962:	6105                	addi	sp,sp,32
    80007964:	8082                	ret
      panic("virtio_disk_intr status");
    80007966:	00002517          	auipc	a0,0x2
    8000796a:	31a50513          	addi	a0,a0,794 # 80009c80 <syscalls+0x3d8>
    8000796e:	ffff9097          	auipc	ra,0xffff9
    80007972:	bd0080e7          	jalr	-1072(ra) # 8000053e <panic>

0000000080007976 <cas>:
    80007976:	100522af          	lr.w	t0,(a0)
    8000797a:	00b29563          	bne	t0,a1,80007984 <fail>
    8000797e:	18c5252f          	sc.w	a0,a2,(a0)
    80007982:	8082                	ret

0000000080007984 <fail>:
    80007984:	4505                	li	a0,1
    80007986:	8082                	ret
	...

0000000080008000 <_trampoline>:
    80008000:	14051573          	csrrw	a0,sscratch,a0
    80008004:	02153423          	sd	ra,40(a0)
    80008008:	02253823          	sd	sp,48(a0)
    8000800c:	02353c23          	sd	gp,56(a0)
    80008010:	04453023          	sd	tp,64(a0)
    80008014:	04553423          	sd	t0,72(a0)
    80008018:	04653823          	sd	t1,80(a0)
    8000801c:	04753c23          	sd	t2,88(a0)
    80008020:	f120                	sd	s0,96(a0)
    80008022:	f524                	sd	s1,104(a0)
    80008024:	fd2c                	sd	a1,120(a0)
    80008026:	e150                	sd	a2,128(a0)
    80008028:	e554                	sd	a3,136(a0)
    8000802a:	e958                	sd	a4,144(a0)
    8000802c:	ed5c                	sd	a5,152(a0)
    8000802e:	0b053023          	sd	a6,160(a0)
    80008032:	0b153423          	sd	a7,168(a0)
    80008036:	0b253823          	sd	s2,176(a0)
    8000803a:	0b353c23          	sd	s3,184(a0)
    8000803e:	0d453023          	sd	s4,192(a0)
    80008042:	0d553423          	sd	s5,200(a0)
    80008046:	0d653823          	sd	s6,208(a0)
    8000804a:	0d753c23          	sd	s7,216(a0)
    8000804e:	0f853023          	sd	s8,224(a0)
    80008052:	0f953423          	sd	s9,232(a0)
    80008056:	0fa53823          	sd	s10,240(a0)
    8000805a:	0fb53c23          	sd	s11,248(a0)
    8000805e:	11c53023          	sd	t3,256(a0)
    80008062:	11d53423          	sd	t4,264(a0)
    80008066:	11e53823          	sd	t5,272(a0)
    8000806a:	11f53c23          	sd	t6,280(a0)
    8000806e:	140022f3          	csrr	t0,sscratch
    80008072:	06553823          	sd	t0,112(a0)
    80008076:	00853103          	ld	sp,8(a0)
    8000807a:	02053203          	ld	tp,32(a0)
    8000807e:	01053283          	ld	t0,16(a0)
    80008082:	00053303          	ld	t1,0(a0)
    80008086:	18031073          	csrw	satp,t1
    8000808a:	12000073          	sfence.vma
    8000808e:	8282                	jr	t0

0000000080008090 <userret>:
    80008090:	18059073          	csrw	satp,a1
    80008094:	12000073          	sfence.vma
    80008098:	07053283          	ld	t0,112(a0)
    8000809c:	14029073          	csrw	sscratch,t0
    800080a0:	02853083          	ld	ra,40(a0)
    800080a4:	03053103          	ld	sp,48(a0)
    800080a8:	03853183          	ld	gp,56(a0)
    800080ac:	04053203          	ld	tp,64(a0)
    800080b0:	04853283          	ld	t0,72(a0)
    800080b4:	05053303          	ld	t1,80(a0)
    800080b8:	05853383          	ld	t2,88(a0)
    800080bc:	7120                	ld	s0,96(a0)
    800080be:	7524                	ld	s1,104(a0)
    800080c0:	7d2c                	ld	a1,120(a0)
    800080c2:	6150                	ld	a2,128(a0)
    800080c4:	6554                	ld	a3,136(a0)
    800080c6:	6958                	ld	a4,144(a0)
    800080c8:	6d5c                	ld	a5,152(a0)
    800080ca:	0a053803          	ld	a6,160(a0)
    800080ce:	0a853883          	ld	a7,168(a0)
    800080d2:	0b053903          	ld	s2,176(a0)
    800080d6:	0b853983          	ld	s3,184(a0)
    800080da:	0c053a03          	ld	s4,192(a0)
    800080de:	0c853a83          	ld	s5,200(a0)
    800080e2:	0d053b03          	ld	s6,208(a0)
    800080e6:	0d853b83          	ld	s7,216(a0)
    800080ea:	0e053c03          	ld	s8,224(a0)
    800080ee:	0e853c83          	ld	s9,232(a0)
    800080f2:	0f053d03          	ld	s10,240(a0)
    800080f6:	0f853d83          	ld	s11,248(a0)
    800080fa:	10053e03          	ld	t3,256(a0)
    800080fe:	10853e83          	ld	t4,264(a0)
    80008102:	11053f03          	ld	t5,272(a0)
    80008106:	11853f83          	ld	t6,280(a0)
    8000810a:	14051573          	csrrw	a0,sscratch,a0
    8000810e:	10200073          	sret
	...
