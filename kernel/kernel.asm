
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
    80000068:	0fc78793          	addi	a5,a5,252 # 80006160 <timervec>
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
    80000130:	896080e7          	jalr	-1898(ra) # 800029c2 <either_copyin>
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
    800001d8:	364080e7          	jalr	868(ra) # 80002538 <sleep>
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
    80000214:	75c080e7          	jalr	1884(ra) # 8000296c <either_copyout>
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
    800002f6:	726080e7          	jalr	1830(ra) # 80002a18 <procdump>
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
    8000044a:	290080e7          	jalr	656(ra) # 800026d6 <wakeup>
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
    800008a4:	e36080e7          	jalr	-458(ra) # 800026d6 <wakeup>
    
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
    80000930:	c0c080e7          	jalr	-1012(ra) # 80002538 <sleep>
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
    80000ed8:	d70080e7          	jalr	-656(ra) # 80002c44 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	2c4080e7          	jalr	708(ra) # 800061a0 <plicinithart>
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
    80000f50:	cd0080e7          	jalr	-816(ra) # 80002c1c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	cf0080e7          	jalr	-784(ra) # 80002c44 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	22e080e7          	jalr	558(ra) # 8000618a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	23c080e7          	jalr	572(ra) # 800061a0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	41a080e7          	jalr	1050(ra) # 80003386 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	aaa080e7          	jalr	-1366(ra) # 80003a1e <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	a54080e7          	jalr	-1452(ra) # 800049d0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	33e080e7          	jalr	830(ra) # 800062c2 <virtio_disk_init>
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
    8000185e:	f4c080e7          	jalr	-180(ra) # 800067a6 <cas>
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
    80001d9e:	ec2080e7          	jalr	-318(ra) # 80002c5c <usertrapret>
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
    80001db8:	bea080e7          	jalr	-1046(ra) # 8000399e <fsinit>
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
    80001de2:	9c8080e7          	jalr	-1592(ra) # 800067a6 <cas>
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
    8000211c:	2b4080e7          	jalr	692(ra) # 800043cc <namei>
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
    80002266:	800080e7          	jalr	-2048(ra) # 80004a62 <filedup>
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
    80002288:	954080e7          	jalr	-1708(ra) # 80003bd8 <idup>
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
    80002352:	0000fa97          	auipc	s5,0xf
    80002356:	f4ea8a93          	addi	s5,s5,-178 # 800112a0 <cpus>
    8000235a:	0a800793          	li	a5,168
    8000235e:	02f707b3          	mul	a5,a4,a5
    80002362:	00fa86b3          	add	a3,s5,a5
    80002366:	0006b023          	sd	zero,0(a3)
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    8000236a:	08878b13          	addi	s6,a5,136
    8000236e:	9b56                	add	s6,s6,s5
          swtch(&c->context, &p->context);
    80002370:	07a1                	addi	a5,a5,8
    80002372:	9abe                	add	s5,s5,a5
  h = lst->head == -1;
    80002374:	8936                	mv	s2,a3
      if(p->state == RUNNABLE) {
    80002376:	0000f997          	auipc	s3,0xf
    8000237a:	49a98993          	addi	s3,s3,1178 # 80011810 <proc>
    8000237e:	19000a13          	li	s4,400
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002382:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002386:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000238a:	10079073          	csrw	sstatus,a5
    8000238e:	4b8d                	li	s7,3
  h = lst->head == -1;
    80002390:	08892783          	lw	a5,136(s2)
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    80002394:	56fd                	li	a3,-1
      if(p->state == RUNNABLE) {
    80002396:	03478733          	mul	a4,a5,s4
    8000239a:	974e                	add	a4,a4,s3
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    8000239c:	fed783e3          	beq	a5,a3,80002382 <scheduler+0x4c>
      if(p->state == RUNNABLE) {
    800023a0:	4f10                	lw	a2,24(a4)
    800023a2:	ff761de3          	bne	a2,s7,8000239c <scheduler+0x66>
    800023a6:	034784b3          	mul	s1,a5,s4
      p = &proc[c->runnable_list.head];
    800023aa:	01348c33          	add	s8,s1,s3
        acquire(&p->lock);
    800023ae:	8562                	mv	a0,s8
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	834080e7          	jalr	-1996(ra) # 80000be4 <acquire>
          remove(&(c->runnable_list), p);
    800023b8:	85e2                	mv	a1,s8
    800023ba:	855a                	mv	a0,s6
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	5fe080e7          	jalr	1534(ra) # 800019ba <remove>
          p->state = RUNNING;
    800023c4:	4791                	li	a5,4
    800023c6:	00fc2c23          	sw	a5,24(s8)
          c->proc = p;
    800023ca:	01893023          	sd	s8,0(s2)
          p->last_cpu = c->cpu_id;
    800023ce:	08492783          	lw	a5,132(s2)
    800023d2:	16fc2423          	sw	a5,360(s8)
          swtch(&c->context, &p->context);
    800023d6:	06048593          	addi	a1,s1,96
    800023da:	95ce                	add	a1,a1,s3
    800023dc:	8556                	mv	a0,s5
    800023de:	00000097          	auipc	ra,0x0
    800023e2:	7d4080e7          	jalr	2004(ra) # 80002bb2 <swtch>
          c->proc = 0;
    800023e6:	00093023          	sd	zero,0(s2)
        release(&p->lock);
    800023ea:	8562                	mv	a0,s8
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	8ac080e7          	jalr	-1876(ra) # 80000c98 <release>
    800023f4:	bf71                	j	80002390 <scheduler+0x5a>

00000000800023f6 <sched>:
{
    800023f6:	7179                	addi	sp,sp,-48
    800023f8:	f406                	sd	ra,40(sp)
    800023fa:	f022                	sd	s0,32(sp)
    800023fc:	ec26                	sd	s1,24(sp)
    800023fe:	e84a                	sd	s2,16(sp)
    80002400:	e44e                	sd	s3,8(sp)
    80002402:	e052                	sd	s4,0(sp)
    80002404:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002406:	00000097          	auipc	ra,0x0
    8000240a:	934080e7          	jalr	-1740(ra) # 80001d3a <myproc>
    8000240e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002410:	ffffe097          	auipc	ra,0xffffe
    80002414:	75a080e7          	jalr	1882(ra) # 80000b6a <holding>
    80002418:	c141                	beqz	a0,80002498 <sched+0xa2>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000241a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000241c:	2781                	sext.w	a5,a5
    8000241e:	0a800713          	li	a4,168
    80002422:	02e787b3          	mul	a5,a5,a4
    80002426:	0000f717          	auipc	a4,0xf
    8000242a:	e7a70713          	addi	a4,a4,-390 # 800112a0 <cpus>
    8000242e:	97ba                	add	a5,a5,a4
    80002430:	5fb8                	lw	a4,120(a5)
    80002432:	4785                	li	a5,1
    80002434:	06f71a63          	bne	a4,a5,800024a8 <sched+0xb2>
  if(p->state == RUNNING)
    80002438:	4c98                	lw	a4,24(s1)
    8000243a:	4791                	li	a5,4
    8000243c:	06f70e63          	beq	a4,a5,800024b8 <sched+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002440:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002444:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002446:	e3c9                	bnez	a5,800024c8 <sched+0xd2>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002448:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000244a:	0000f917          	auipc	s2,0xf
    8000244e:	e5690913          	addi	s2,s2,-426 # 800112a0 <cpus>
    80002452:	2781                	sext.w	a5,a5
    80002454:	0a800993          	li	s3,168
    80002458:	033787b3          	mul	a5,a5,s3
    8000245c:	97ca                	add	a5,a5,s2
    8000245e:	07c7aa03          	lw	s4,124(a5)
    80002462:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    80002464:	2581                	sext.w	a1,a1
    80002466:	033585b3          	mul	a1,a1,s3
    8000246a:	05a1                	addi	a1,a1,8
    8000246c:	95ca                	add	a1,a1,s2
    8000246e:	06048513          	addi	a0,s1,96
    80002472:	00000097          	auipc	ra,0x0
    80002476:	740080e7          	jalr	1856(ra) # 80002bb2 <swtch>
    8000247a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000247c:	2781                	sext.w	a5,a5
    8000247e:	033787b3          	mul	a5,a5,s3
    80002482:	993e                	add	s2,s2,a5
    80002484:	07492e23          	sw	s4,124(s2)
}
    80002488:	70a2                	ld	ra,40(sp)
    8000248a:	7402                	ld	s0,32(sp)
    8000248c:	64e2                	ld	s1,24(sp)
    8000248e:	6942                	ld	s2,16(sp)
    80002490:	69a2                	ld	s3,8(sp)
    80002492:	6a02                	ld	s4,0(sp)
    80002494:	6145                	addi	sp,sp,48
    80002496:	8082                	ret
    panic("sched p->lock");
    80002498:	00006517          	auipc	a0,0x6
    8000249c:	e0850513          	addi	a0,a0,-504 # 800082a0 <digits+0x260>
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	09e080e7          	jalr	158(ra) # 8000053e <panic>
    panic("sched locks");
    800024a8:	00006517          	auipc	a0,0x6
    800024ac:	e0850513          	addi	a0,a0,-504 # 800082b0 <digits+0x270>
    800024b0:	ffffe097          	auipc	ra,0xffffe
    800024b4:	08e080e7          	jalr	142(ra) # 8000053e <panic>
    panic("sched running");
    800024b8:	00006517          	auipc	a0,0x6
    800024bc:	e0850513          	addi	a0,a0,-504 # 800082c0 <digits+0x280>
    800024c0:	ffffe097          	auipc	ra,0xffffe
    800024c4:	07e080e7          	jalr	126(ra) # 8000053e <panic>
    panic("sched interruptible");
    800024c8:	00006517          	auipc	a0,0x6
    800024cc:	e0850513          	addi	a0,a0,-504 # 800082d0 <digits+0x290>
    800024d0:	ffffe097          	auipc	ra,0xffffe
    800024d4:	06e080e7          	jalr	110(ra) # 8000053e <panic>

00000000800024d8 <yield>:
{
    800024d8:	1101                	addi	sp,sp,-32
    800024da:	ec06                	sd	ra,24(sp)
    800024dc:	e822                	sd	s0,16(sp)
    800024de:	e426                	sd	s1,8(sp)
    800024e0:	e04a                	sd	s2,0(sp)
    800024e2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800024e4:	00000097          	auipc	ra,0x0
    800024e8:	856080e7          	jalr	-1962(ra) # 80001d3a <myproc>
    800024ec:	84aa                	mv	s1,a0
    800024ee:	8912                	mv	s2,tp
  acquire(&p->lock);
    800024f0:	ffffe097          	auipc	ra,0xffffe
    800024f4:	6f4080e7          	jalr	1780(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800024f8:	478d                	li	a5,3
    800024fa:	cc9c                	sw	a5,24(s1)
  append(&(c->runnable_list), p);
    800024fc:	2901                	sext.w	s2,s2
    800024fe:	0a800513          	li	a0,168
    80002502:	02a90933          	mul	s2,s2,a0
    80002506:	85a6                	mv	a1,s1
    80002508:	0000f517          	auipc	a0,0xf
    8000250c:	e2050513          	addi	a0,a0,-480 # 80011328 <cpus+0x88>
    80002510:	954a                	add	a0,a0,s2
    80002512:	fffff097          	auipc	ra,0xfffff
    80002516:	3e0080e7          	jalr	992(ra) # 800018f2 <append>
  sched();
    8000251a:	00000097          	auipc	ra,0x0
    8000251e:	edc080e7          	jalr	-292(ra) # 800023f6 <sched>
  release(&p->lock);
    80002522:	8526                	mv	a0,s1
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	774080e7          	jalr	1908(ra) # 80000c98 <release>
}
    8000252c:	60e2                	ld	ra,24(sp)
    8000252e:	6442                	ld	s0,16(sp)
    80002530:	64a2                	ld	s1,8(sp)
    80002532:	6902                	ld	s2,0(sp)
    80002534:	6105                	addi	sp,sp,32
    80002536:	8082                	ret

0000000080002538 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002538:	7179                	addi	sp,sp,-48
    8000253a:	f406                	sd	ra,40(sp)
    8000253c:	f022                	sd	s0,32(sp)
    8000253e:	ec26                	sd	s1,24(sp)
    80002540:	e84a                	sd	s2,16(sp)
    80002542:	e44e                	sd	s3,8(sp)
    80002544:	1800                	addi	s0,sp,48
    80002546:	89aa                	mv	s3,a0
    80002548:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000254a:	fffff097          	auipc	ra,0xfffff
    8000254e:	7f0080e7          	jalr	2032(ra) # 80001d3a <myproc>
    80002552:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);
    80002554:	ffffe097          	auipc	ra,0xffffe
    80002558:	690080e7          	jalr	1680(ra) # 80000be4 <acquire>
  release(lk);
    8000255c:	854a                	mv	a0,s2
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	73a080e7          	jalr	1850(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002566:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000256a:	4789                	li	a5,2
    8000256c:	cc9c                	sw	a5,24(s1)
  //printf("insert sleep sleep %d\n", p->index); //delete
  append(&sleeping_list, p);
    8000256e:	85a6                	mv	a1,s1
    80002570:	00006517          	auipc	a0,0x6
    80002574:	34050513          	addi	a0,a0,832 # 800088b0 <sleeping_list>
    80002578:	fffff097          	auipc	ra,0xfffff
    8000257c:	37a080e7          	jalr	890(ra) # 800018f2 <append>

  sched();
    80002580:	00000097          	auipc	ra,0x0
    80002584:	e76080e7          	jalr	-394(ra) # 800023f6 <sched>

  // Tidy up.
  p->chan = 0;
    80002588:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000258c:	8526                	mv	a0,s1
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	70a080e7          	jalr	1802(ra) # 80000c98 <release>
  acquire(lk);
    80002596:	854a                	mv	a0,s2
    80002598:	ffffe097          	auipc	ra,0xffffe
    8000259c:	64c080e7          	jalr	1612(ra) # 80000be4 <acquire>
}
    800025a0:	70a2                	ld	ra,40(sp)
    800025a2:	7402                	ld	s0,32(sp)
    800025a4:	64e2                	ld	s1,24(sp)
    800025a6:	6942                	ld	s2,16(sp)
    800025a8:	69a2                	ld	s3,8(sp)
    800025aa:	6145                	addi	sp,sp,48
    800025ac:	8082                	ret

00000000800025ae <wait>:
{
    800025ae:	715d                	addi	sp,sp,-80
    800025b0:	e486                	sd	ra,72(sp)
    800025b2:	e0a2                	sd	s0,64(sp)
    800025b4:	fc26                	sd	s1,56(sp)
    800025b6:	f84a                	sd	s2,48(sp)
    800025b8:	f44e                	sd	s3,40(sp)
    800025ba:	f052                	sd	s4,32(sp)
    800025bc:	ec56                	sd	s5,24(sp)
    800025be:	e85a                	sd	s6,16(sp)
    800025c0:	e45e                	sd	s7,8(sp)
    800025c2:	e062                	sd	s8,0(sp)
    800025c4:	0880                	addi	s0,sp,80
    800025c6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025c8:	fffff097          	auipc	ra,0xfffff
    800025cc:	772080e7          	jalr	1906(ra) # 80001d3a <myproc>
    800025d0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800025d2:	0000f517          	auipc	a0,0xf
    800025d6:	22650513          	addi	a0,a0,550 # 800117f8 <wait_lock>
    800025da:	ffffe097          	auipc	ra,0xffffe
    800025de:	60a080e7          	jalr	1546(ra) # 80000be4 <acquire>
    havekids = 0;
    800025e2:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800025e4:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800025e6:	00015997          	auipc	s3,0x15
    800025ea:	62a98993          	addi	s3,s3,1578 # 80017c10 <tickslock>
        havekids = 1;
    800025ee:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025f0:	0000fc17          	auipc	s8,0xf
    800025f4:	208c0c13          	addi	s8,s8,520 # 800117f8 <wait_lock>
    havekids = 0;
    800025f8:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800025fa:	0000f497          	auipc	s1,0xf
    800025fe:	21648493          	addi	s1,s1,534 # 80011810 <proc>
    80002602:	a0bd                	j	80002670 <wait+0xc2>
          pid = np->pid;
    80002604:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002608:	000b0e63          	beqz	s6,80002624 <wait+0x76>
    8000260c:	4691                	li	a3,4
    8000260e:	02c48613          	addi	a2,s1,44
    80002612:	85da                	mv	a1,s6
    80002614:	05093503          	ld	a0,80(s2)
    80002618:	fffff097          	auipc	ra,0xfffff
    8000261c:	05a080e7          	jalr	90(ra) # 80001672 <copyout>
    80002620:	02054563          	bltz	a0,8000264a <wait+0x9c>
          freeproc(np);
    80002624:	8526                	mv	a0,s1
    80002626:	00000097          	auipc	ra,0x0
    8000262a:	8c0080e7          	jalr	-1856(ra) # 80001ee6 <freeproc>
          release(&np->lock);
    8000262e:	8526                	mv	a0,s1
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	668080e7          	jalr	1640(ra) # 80000c98 <release>
          release(&wait_lock);
    80002638:	0000f517          	auipc	a0,0xf
    8000263c:	1c050513          	addi	a0,a0,448 # 800117f8 <wait_lock>
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	658080e7          	jalr	1624(ra) # 80000c98 <release>
          return pid;
    80002648:	a09d                	j	800026ae <wait+0x100>
            release(&np->lock);
    8000264a:	8526                	mv	a0,s1
    8000264c:	ffffe097          	auipc	ra,0xffffe
    80002650:	64c080e7          	jalr	1612(ra) # 80000c98 <release>
            release(&wait_lock);
    80002654:	0000f517          	auipc	a0,0xf
    80002658:	1a450513          	addi	a0,a0,420 # 800117f8 <wait_lock>
    8000265c:	ffffe097          	auipc	ra,0xffffe
    80002660:	63c080e7          	jalr	1596(ra) # 80000c98 <release>
            return -1;
    80002664:	59fd                	li	s3,-1
    80002666:	a0a1                	j	800026ae <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002668:	19048493          	addi	s1,s1,400
    8000266c:	03348463          	beq	s1,s3,80002694 <wait+0xe6>
      if(np->parent == p){
    80002670:	7c9c                	ld	a5,56(s1)
    80002672:	ff279be3          	bne	a5,s2,80002668 <wait+0xba>
        acquire(&np->lock);
    80002676:	8526                	mv	a0,s1
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	56c080e7          	jalr	1388(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002680:	4c9c                	lw	a5,24(s1)
    80002682:	f94781e3          	beq	a5,s4,80002604 <wait+0x56>
        release(&np->lock);
    80002686:	8526                	mv	a0,s1
    80002688:	ffffe097          	auipc	ra,0xffffe
    8000268c:	610080e7          	jalr	1552(ra) # 80000c98 <release>
        havekids = 1;
    80002690:	8756                	mv	a4,s5
    80002692:	bfd9                	j	80002668 <wait+0xba>
    if(!havekids || p->killed){
    80002694:	c701                	beqz	a4,8000269c <wait+0xee>
    80002696:	02892783          	lw	a5,40(s2)
    8000269a:	c79d                	beqz	a5,800026c8 <wait+0x11a>
      release(&wait_lock);
    8000269c:	0000f517          	auipc	a0,0xf
    800026a0:	15c50513          	addi	a0,a0,348 # 800117f8 <wait_lock>
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	5f4080e7          	jalr	1524(ra) # 80000c98 <release>
      return -1;
    800026ac:	59fd                	li	s3,-1
}
    800026ae:	854e                	mv	a0,s3
    800026b0:	60a6                	ld	ra,72(sp)
    800026b2:	6406                	ld	s0,64(sp)
    800026b4:	74e2                	ld	s1,56(sp)
    800026b6:	7942                	ld	s2,48(sp)
    800026b8:	79a2                	ld	s3,40(sp)
    800026ba:	7a02                	ld	s4,32(sp)
    800026bc:	6ae2                	ld	s5,24(sp)
    800026be:	6b42                	ld	s6,16(sp)
    800026c0:	6ba2                	ld	s7,8(sp)
    800026c2:	6c02                	ld	s8,0(sp)
    800026c4:	6161                	addi	sp,sp,80
    800026c6:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800026c8:	85e2                	mv	a1,s8
    800026ca:	854a                	mv	a0,s2
    800026cc:	00000097          	auipc	ra,0x0
    800026d0:	e6c080e7          	jalr	-404(ra) # 80002538 <sleep>
    havekids = 0;
    800026d4:	b715                	j	800025f8 <wait+0x4a>

00000000800026d6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800026d6:	7159                	addi	sp,sp,-112
    800026d8:	f486                	sd	ra,104(sp)
    800026da:	f0a2                	sd	s0,96(sp)
    800026dc:	eca6                	sd	s1,88(sp)
    800026de:	e8ca                	sd	s2,80(sp)
    800026e0:	e4ce                	sd	s3,72(sp)
    800026e2:	e0d2                	sd	s4,64(sp)
    800026e4:	fc56                	sd	s5,56(sp)
    800026e6:	f85a                	sd	s6,48(sp)
    800026e8:	f45e                	sd	s7,40(sp)
    800026ea:	f062                	sd	s8,32(sp)
    800026ec:	ec66                	sd	s9,24(sp)
    800026ee:	e86a                	sd	s10,16(sp)
    800026f0:	e46e                	sd	s11,8(sp)
    800026f2:	1880                	addi	s0,sp,112
  struct proc *p;
  struct cpu *c;

  int curr = sleeping_list.head;
    800026f4:	00006917          	auipc	s2,0x6
    800026f8:	1bc92903          	lw	s2,444(s2) # 800088b0 <sleeping_list>
  // int curr = get_head(&sleeping_list);

  while(curr != -1) {
    800026fc:	57fd                	li	a5,-1
    800026fe:	08f90e63          	beq	s2,a5,8000279a <wakeup+0xc4>
    80002702:	8c2a                	mv	s8,a0
    p = &proc[curr];
    80002704:	19000a93          	li	s5,400
    80002708:	0000fa17          	auipc	s4,0xf
    8000270c:	108a0a13          	addi	s4,s4,264 # 80011810 <proc>
    curr = p->next_proc;
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002710:	4b89                	li	s7,2
        remove(&sleeping_list, p);
        p->state = RUNNABLE;
    80002712:	4d8d                	li	s11,3
    80002714:	0a800d13          	li	s10,168

        #ifdef ON
          p->last_cpu = min_cpu_process_count(); // case BLNCFLG=ON -> cpu = CPU with the lowest counter value
        #endif
        c = &cpus[p->last_cpu];
    80002718:	0000fc97          	auipc	s9,0xf
    8000271c:	b88c8c93          	addi	s9,s9,-1144 # 800112a0 <cpus>
  while(curr != -1) {
    80002720:	5b7d                	li	s6,-1
    80002722:	a801                	j	80002732 <wakeup+0x5c>
        inc_cpu(c);

        append(&(c->runnable_list), p);
      }
      release(&p->lock);
    80002724:	8526                	mv	a0,s1
    80002726:	ffffe097          	auipc	ra,0xffffe
    8000272a:	572080e7          	jalr	1394(ra) # 80000c98 <release>
  while(curr != -1) {
    8000272e:	07690663          	beq	s2,s6,8000279a <wakeup+0xc4>
    p = &proc[curr];
    80002732:	035904b3          	mul	s1,s2,s5
    80002736:	94d2                	add	s1,s1,s4
    curr = p->next_proc;
    80002738:	16c4a903          	lw	s2,364(s1)
    if(p != myproc()){
    8000273c:	fffff097          	auipc	ra,0xfffff
    80002740:	5fe080e7          	jalr	1534(ra) # 80001d3a <myproc>
    80002744:	fea485e3          	beq	s1,a0,8000272e <wakeup+0x58>
      acquire(&p->lock);
    80002748:	8526                	mv	a0,s1
    8000274a:	ffffe097          	auipc	ra,0xffffe
    8000274e:	49a080e7          	jalr	1178(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002752:	4c9c                	lw	a5,24(s1)
    80002754:	fd7798e3          	bne	a5,s7,80002724 <wakeup+0x4e>
    80002758:	709c                	ld	a5,32(s1)
    8000275a:	fd8795e3          	bne	a5,s8,80002724 <wakeup+0x4e>
        remove(&sleeping_list, p);
    8000275e:	85a6                	mv	a1,s1
    80002760:	00006517          	auipc	a0,0x6
    80002764:	15050513          	addi	a0,a0,336 # 800088b0 <sleeping_list>
    80002768:	fffff097          	auipc	ra,0xfffff
    8000276c:	252080e7          	jalr	594(ra) # 800019ba <remove>
        p->state = RUNNABLE;
    80002770:	01b4ac23          	sw	s11,24(s1)
        c = &cpus[p->last_cpu];
    80002774:	1684a983          	lw	s3,360(s1)
    80002778:	03a989b3          	mul	s3,s3,s10
        inc_cpu(c);
    8000277c:	013c8533          	add	a0,s9,s3
    80002780:	fffff097          	auipc	ra,0xfffff
    80002784:	0be080e7          	jalr	190(ra) # 8000183e <inc_cpu>
        append(&(c->runnable_list), p);
    80002788:	08898513          	addi	a0,s3,136
    8000278c:	85a6                	mv	a1,s1
    8000278e:	9566                	add	a0,a0,s9
    80002790:	fffff097          	auipc	ra,0xfffff
    80002794:	162080e7          	jalr	354(ra) # 800018f2 <append>
    80002798:	b771                	j	80002724 <wakeup+0x4e>
    }
  }
}
    8000279a:	70a6                	ld	ra,104(sp)
    8000279c:	7406                	ld	s0,96(sp)
    8000279e:	64e6                	ld	s1,88(sp)
    800027a0:	6946                	ld	s2,80(sp)
    800027a2:	69a6                	ld	s3,72(sp)
    800027a4:	6a06                	ld	s4,64(sp)
    800027a6:	7ae2                	ld	s5,56(sp)
    800027a8:	7b42                	ld	s6,48(sp)
    800027aa:	7ba2                	ld	s7,40(sp)
    800027ac:	7c02                	ld	s8,32(sp)
    800027ae:	6ce2                	ld	s9,24(sp)
    800027b0:	6d42                	ld	s10,16(sp)
    800027b2:	6da2                	ld	s11,8(sp)
    800027b4:	6165                	addi	sp,sp,112
    800027b6:	8082                	ret

00000000800027b8 <reparent>:
{
    800027b8:	7179                	addi	sp,sp,-48
    800027ba:	f406                	sd	ra,40(sp)
    800027bc:	f022                	sd	s0,32(sp)
    800027be:	ec26                	sd	s1,24(sp)
    800027c0:	e84a                	sd	s2,16(sp)
    800027c2:	e44e                	sd	s3,8(sp)
    800027c4:	e052                	sd	s4,0(sp)
    800027c6:	1800                	addi	s0,sp,48
    800027c8:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800027ca:	0000f497          	auipc	s1,0xf
    800027ce:	04648493          	addi	s1,s1,70 # 80011810 <proc>
      pp->parent = initproc;
    800027d2:	00007a17          	auipc	s4,0x7
    800027d6:	856a0a13          	addi	s4,s4,-1962 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800027da:	00015997          	auipc	s3,0x15
    800027de:	43698993          	addi	s3,s3,1078 # 80017c10 <tickslock>
    800027e2:	a029                	j	800027ec <reparent+0x34>
    800027e4:	19048493          	addi	s1,s1,400
    800027e8:	01348d63          	beq	s1,s3,80002802 <reparent+0x4a>
    if(pp->parent == p){
    800027ec:	7c9c                	ld	a5,56(s1)
    800027ee:	ff279be3          	bne	a5,s2,800027e4 <reparent+0x2c>
      pp->parent = initproc;
    800027f2:	000a3503          	ld	a0,0(s4)
    800027f6:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800027f8:	00000097          	auipc	ra,0x0
    800027fc:	ede080e7          	jalr	-290(ra) # 800026d6 <wakeup>
    80002800:	b7d5                	j	800027e4 <reparent+0x2c>
}
    80002802:	70a2                	ld	ra,40(sp)
    80002804:	7402                	ld	s0,32(sp)
    80002806:	64e2                	ld	s1,24(sp)
    80002808:	6942                	ld	s2,16(sp)
    8000280a:	69a2                	ld	s3,8(sp)
    8000280c:	6a02                	ld	s4,0(sp)
    8000280e:	6145                	addi	sp,sp,48
    80002810:	8082                	ret

0000000080002812 <exit>:
{
    80002812:	7179                	addi	sp,sp,-48
    80002814:	f406                	sd	ra,40(sp)
    80002816:	f022                	sd	s0,32(sp)
    80002818:	ec26                	sd	s1,24(sp)
    8000281a:	e84a                	sd	s2,16(sp)
    8000281c:	e44e                	sd	s3,8(sp)
    8000281e:	e052                	sd	s4,0(sp)
    80002820:	1800                	addi	s0,sp,48
    80002822:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002824:	fffff097          	auipc	ra,0xfffff
    80002828:	516080e7          	jalr	1302(ra) # 80001d3a <myproc>
    8000282c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000282e:	00006797          	auipc	a5,0x6
    80002832:	7fa7b783          	ld	a5,2042(a5) # 80009028 <initproc>
    80002836:	0d050493          	addi	s1,a0,208
    8000283a:	15050913          	addi	s2,a0,336
    8000283e:	02a79363          	bne	a5,a0,80002864 <exit+0x52>
    panic("init exiting");
    80002842:	00006517          	auipc	a0,0x6
    80002846:	aa650513          	addi	a0,a0,-1370 # 800082e8 <digits+0x2a8>
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	cf4080e7          	jalr	-780(ra) # 8000053e <panic>
      fileclose(f);
    80002852:	00002097          	auipc	ra,0x2
    80002856:	262080e7          	jalr	610(ra) # 80004ab4 <fileclose>
      p->ofile[fd] = 0;
    8000285a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000285e:	04a1                	addi	s1,s1,8
    80002860:	01248563          	beq	s1,s2,8000286a <exit+0x58>
    if(p->ofile[fd]){
    80002864:	6088                	ld	a0,0(s1)
    80002866:	f575                	bnez	a0,80002852 <exit+0x40>
    80002868:	bfdd                	j	8000285e <exit+0x4c>
  begin_op();
    8000286a:	00002097          	auipc	ra,0x2
    8000286e:	d7e080e7          	jalr	-642(ra) # 800045e8 <begin_op>
  iput(p->cwd);
    80002872:	1509b503          	ld	a0,336(s3)
    80002876:	00001097          	auipc	ra,0x1
    8000287a:	55a080e7          	jalr	1370(ra) # 80003dd0 <iput>
  end_op();
    8000287e:	00002097          	auipc	ra,0x2
    80002882:	dea080e7          	jalr	-534(ra) # 80004668 <end_op>
  p->cwd = 0;
    80002886:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000288a:	0000f497          	auipc	s1,0xf
    8000288e:	f6e48493          	addi	s1,s1,-146 # 800117f8 <wait_lock>
    80002892:	8526                	mv	a0,s1
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	350080e7          	jalr	848(ra) # 80000be4 <acquire>
  reparent(p);
    8000289c:	854e                	mv	a0,s3
    8000289e:	00000097          	auipc	ra,0x0
    800028a2:	f1a080e7          	jalr	-230(ra) # 800027b8 <reparent>
  wakeup(p->parent);
    800028a6:	0389b503          	ld	a0,56(s3)
    800028aa:	00000097          	auipc	ra,0x0
    800028ae:	e2c080e7          	jalr	-468(ra) # 800026d6 <wakeup>
  acquire(&p->lock);
    800028b2:	854e                	mv	a0,s3
    800028b4:	ffffe097          	auipc	ra,0xffffe
    800028b8:	330080e7          	jalr	816(ra) # 80000be4 <acquire>
  p->xstate = status;
    800028bc:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800028c0:	4795                	li	a5,5
    800028c2:	00f9ac23          	sw	a5,24(s3)
  append(&zombie_list, p); // exit to admit the exiting process to the ZOMBIE list
    800028c6:	85ce                	mv	a1,s3
    800028c8:	00006517          	auipc	a0,0x6
    800028cc:	00850513          	addi	a0,a0,8 # 800088d0 <zombie_list>
    800028d0:	fffff097          	auipc	ra,0xfffff
    800028d4:	022080e7          	jalr	34(ra) # 800018f2 <append>
  release(&wait_lock);
    800028d8:	8526                	mv	a0,s1
    800028da:	ffffe097          	auipc	ra,0xffffe
    800028de:	3be080e7          	jalr	958(ra) # 80000c98 <release>
  sched();
    800028e2:	00000097          	auipc	ra,0x0
    800028e6:	b14080e7          	jalr	-1260(ra) # 800023f6 <sched>
  panic("zombie exit");
    800028ea:	00006517          	auipc	a0,0x6
    800028ee:	a0e50513          	addi	a0,a0,-1522 # 800082f8 <digits+0x2b8>
    800028f2:	ffffe097          	auipc	ra,0xffffe
    800028f6:	c4c080e7          	jalr	-948(ra) # 8000053e <panic>

00000000800028fa <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800028fa:	7179                	addi	sp,sp,-48
    800028fc:	f406                	sd	ra,40(sp)
    800028fe:	f022                	sd	s0,32(sp)
    80002900:	ec26                	sd	s1,24(sp)
    80002902:	e84a                	sd	s2,16(sp)
    80002904:	e44e                	sd	s3,8(sp)
    80002906:	1800                	addi	s0,sp,48
    80002908:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000290a:	0000f497          	auipc	s1,0xf
    8000290e:	f0648493          	addi	s1,s1,-250 # 80011810 <proc>
    80002912:	00015997          	auipc	s3,0x15
    80002916:	2fe98993          	addi	s3,s3,766 # 80017c10 <tickslock>
    acquire(&p->lock);
    8000291a:	8526                	mv	a0,s1
    8000291c:	ffffe097          	auipc	ra,0xffffe
    80002920:	2c8080e7          	jalr	712(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002924:	589c                	lw	a5,48(s1)
    80002926:	01278d63          	beq	a5,s2,80002940 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000292a:	8526                	mv	a0,s1
    8000292c:	ffffe097          	auipc	ra,0xffffe
    80002930:	36c080e7          	jalr	876(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002934:	19048493          	addi	s1,s1,400
    80002938:	ff3491e3          	bne	s1,s3,8000291a <kill+0x20>
  }
  return -1;
    8000293c:	557d                	li	a0,-1
    8000293e:	a829                	j	80002958 <kill+0x5e>
      p->killed = 1;
    80002940:	4785                	li	a5,1
    80002942:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002944:	4c98                	lw	a4,24(s1)
    80002946:	4789                	li	a5,2
    80002948:	00f70f63          	beq	a4,a5,80002966 <kill+0x6c>
      release(&p->lock);
    8000294c:	8526                	mv	a0,s1
    8000294e:	ffffe097          	auipc	ra,0xffffe
    80002952:	34a080e7          	jalr	842(ra) # 80000c98 <release>
      return 0;
    80002956:	4501                	li	a0,0
}
    80002958:	70a2                	ld	ra,40(sp)
    8000295a:	7402                	ld	s0,32(sp)
    8000295c:	64e2                	ld	s1,24(sp)
    8000295e:	6942                	ld	s2,16(sp)
    80002960:	69a2                	ld	s3,8(sp)
    80002962:	6145                	addi	sp,sp,48
    80002964:	8082                	ret
        p->state = RUNNABLE;
    80002966:	478d                	li	a5,3
    80002968:	cc9c                	sw	a5,24(s1)
    8000296a:	b7cd                	j	8000294c <kill+0x52>

000000008000296c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000296c:	7179                	addi	sp,sp,-48
    8000296e:	f406                	sd	ra,40(sp)
    80002970:	f022                	sd	s0,32(sp)
    80002972:	ec26                	sd	s1,24(sp)
    80002974:	e84a                	sd	s2,16(sp)
    80002976:	e44e                	sd	s3,8(sp)
    80002978:	e052                	sd	s4,0(sp)
    8000297a:	1800                	addi	s0,sp,48
    8000297c:	84aa                	mv	s1,a0
    8000297e:	892e                	mv	s2,a1
    80002980:	89b2                	mv	s3,a2
    80002982:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002984:	fffff097          	auipc	ra,0xfffff
    80002988:	3b6080e7          	jalr	950(ra) # 80001d3a <myproc>
  if(user_dst){
    8000298c:	c08d                	beqz	s1,800029ae <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000298e:	86d2                	mv	a3,s4
    80002990:	864e                	mv	a2,s3
    80002992:	85ca                	mv	a1,s2
    80002994:	6928                	ld	a0,80(a0)
    80002996:	fffff097          	auipc	ra,0xfffff
    8000299a:	cdc080e7          	jalr	-804(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000299e:	70a2                	ld	ra,40(sp)
    800029a0:	7402                	ld	s0,32(sp)
    800029a2:	64e2                	ld	s1,24(sp)
    800029a4:	6942                	ld	s2,16(sp)
    800029a6:	69a2                	ld	s3,8(sp)
    800029a8:	6a02                	ld	s4,0(sp)
    800029aa:	6145                	addi	sp,sp,48
    800029ac:	8082                	ret
    memmove((char *)dst, src, len);
    800029ae:	000a061b          	sext.w	a2,s4
    800029b2:	85ce                	mv	a1,s3
    800029b4:	854a                	mv	a0,s2
    800029b6:	ffffe097          	auipc	ra,0xffffe
    800029ba:	38a080e7          	jalr	906(ra) # 80000d40 <memmove>
    return 0;
    800029be:	8526                	mv	a0,s1
    800029c0:	bff9                	j	8000299e <either_copyout+0x32>

00000000800029c2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800029c2:	7179                	addi	sp,sp,-48
    800029c4:	f406                	sd	ra,40(sp)
    800029c6:	f022                	sd	s0,32(sp)
    800029c8:	ec26                	sd	s1,24(sp)
    800029ca:	e84a                	sd	s2,16(sp)
    800029cc:	e44e                	sd	s3,8(sp)
    800029ce:	e052                	sd	s4,0(sp)
    800029d0:	1800                	addi	s0,sp,48
    800029d2:	892a                	mv	s2,a0
    800029d4:	84ae                	mv	s1,a1
    800029d6:	89b2                	mv	s3,a2
    800029d8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029da:	fffff097          	auipc	ra,0xfffff
    800029de:	360080e7          	jalr	864(ra) # 80001d3a <myproc>
  if(user_src){
    800029e2:	c08d                	beqz	s1,80002a04 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800029e4:	86d2                	mv	a3,s4
    800029e6:	864e                	mv	a2,s3
    800029e8:	85ca                	mv	a1,s2
    800029ea:	6928                	ld	a0,80(a0)
    800029ec:	fffff097          	auipc	ra,0xfffff
    800029f0:	d12080e7          	jalr	-750(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800029f4:	70a2                	ld	ra,40(sp)
    800029f6:	7402                	ld	s0,32(sp)
    800029f8:	64e2                	ld	s1,24(sp)
    800029fa:	6942                	ld	s2,16(sp)
    800029fc:	69a2                	ld	s3,8(sp)
    800029fe:	6a02                	ld	s4,0(sp)
    80002a00:	6145                	addi	sp,sp,48
    80002a02:	8082                	ret
    memmove(dst, (char*)src, len);
    80002a04:	000a061b          	sext.w	a2,s4
    80002a08:	85ce                	mv	a1,s3
    80002a0a:	854a                	mv	a0,s2
    80002a0c:	ffffe097          	auipc	ra,0xffffe
    80002a10:	334080e7          	jalr	820(ra) # 80000d40 <memmove>
    return 0;
    80002a14:	8526                	mv	a0,s1
    80002a16:	bff9                	j	800029f4 <either_copyin+0x32>

0000000080002a18 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    80002a18:	715d                	addi	sp,sp,-80
    80002a1a:	e486                	sd	ra,72(sp)
    80002a1c:	e0a2                	sd	s0,64(sp)
    80002a1e:	fc26                	sd	s1,56(sp)
    80002a20:	f84a                	sd	s2,48(sp)
    80002a22:	f44e                	sd	s3,40(sp)
    80002a24:	f052                	sd	s4,32(sp)
    80002a26:	ec56                	sd	s5,24(sp)
    80002a28:	e85a                	sd	s6,16(sp)
    80002a2a:	e45e                	sd	s7,8(sp)
    80002a2c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002a2e:	00005517          	auipc	a0,0x5
    80002a32:	69a50513          	addi	a0,a0,1690 # 800080c8 <digits+0x88>
    80002a36:	ffffe097          	auipc	ra,0xffffe
    80002a3a:	b52080e7          	jalr	-1198(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a3e:	0000f497          	auipc	s1,0xf
    80002a42:	f2a48493          	addi	s1,s1,-214 # 80011968 <proc+0x158>
    80002a46:	00015917          	auipc	s2,0x15
    80002a4a:	32290913          	addi	s2,s2,802 # 80017d68 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a4e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    80002a50:	00006997          	auipc	s3,0x6
    80002a54:	8b898993          	addi	s3,s3,-1864 # 80008308 <digits+0x2c8>
    printf("%d %s %s", p->pid, state, p->name);
    80002a58:	00006a97          	auipc	s5,0x6
    80002a5c:	8b8a8a93          	addi	s5,s5,-1864 # 80008310 <digits+0x2d0>
    printf("\n");
    80002a60:	00005a17          	auipc	s4,0x5
    80002a64:	668a0a13          	addi	s4,s4,1640 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a68:	00006b97          	auipc	s7,0x6
    80002a6c:	8e0b8b93          	addi	s7,s7,-1824 # 80008348 <states.1780>
    80002a70:	a00d                	j	80002a92 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002a72:	ed86a583          	lw	a1,-296(a3)
    80002a76:	8556                	mv	a0,s5
    80002a78:	ffffe097          	auipc	ra,0xffffe
    80002a7c:	b10080e7          	jalr	-1264(ra) # 80000588 <printf>
    printf("\n");
    80002a80:	8552                	mv	a0,s4
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	b06080e7          	jalr	-1274(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a8a:	19048493          	addi	s1,s1,400
    80002a8e:	03248163          	beq	s1,s2,80002ab0 <procdump+0x98>
    if(p->state == UNUSED)
    80002a92:	86a6                	mv	a3,s1
    80002a94:	ec04a783          	lw	a5,-320(s1)
    80002a98:	dbed                	beqz	a5,80002a8a <procdump+0x72>
      state = "???"; 
    80002a9a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a9c:	fcfb6be3          	bltu	s6,a5,80002a72 <procdump+0x5a>
    80002aa0:	1782                	slli	a5,a5,0x20
    80002aa2:	9381                	srli	a5,a5,0x20
    80002aa4:	078e                	slli	a5,a5,0x3
    80002aa6:	97de                	add	a5,a5,s7
    80002aa8:	6390                	ld	a2,0(a5)
    80002aaa:	f661                	bnez	a2,80002a72 <procdump+0x5a>
      state = "???"; 
    80002aac:	864e                	mv	a2,s3
    80002aae:	b7d1                	j	80002a72 <procdump+0x5a>
  }
}
    80002ab0:	60a6                	ld	ra,72(sp)
    80002ab2:	6406                	ld	s0,64(sp)
    80002ab4:	74e2                	ld	s1,56(sp)
    80002ab6:	7942                	ld	s2,48(sp)
    80002ab8:	79a2                	ld	s3,40(sp)
    80002aba:	7a02                	ld	s4,32(sp)
    80002abc:	6ae2                	ld	s5,24(sp)
    80002abe:	6b42                	ld	s6,16(sp)
    80002ac0:	6ba2                	ld	s7,8(sp)
    80002ac2:	6161                	addi	sp,sp,80
    80002ac4:	8082                	ret

0000000080002ac6 <set_cpu>:

// assign current process to a different CPU. 
int
set_cpu(int cpu_num){
    80002ac6:	1101                	addi	sp,sp,-32
    80002ac8:	ec06                	sd	ra,24(sp)
    80002aca:	e822                	sd	s0,16(sp)
    80002acc:	e426                	sd	s1,8(sp)
    80002ace:	e04a                	sd	s2,0(sp)
    80002ad0:	1000                	addi	s0,sp,32
    80002ad2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ad4:	fffff097          	auipc	ra,0xfffff
    80002ad8:	266080e7          	jalr	614(ra) # 80001d3a <myproc>
  if(cpu_num >= 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL){
    80002adc:	0004871b          	sext.w	a4,s1
    80002ae0:	479d                	li	a5,7
    80002ae2:	02e7e963          	bltu	a5,a4,80002b14 <set_cpu+0x4e>
    80002ae6:	892a                	mv	s2,a0
    acquire(&p->lock);
    80002ae8:	ffffe097          	auipc	ra,0xffffe
    80002aec:	0fc080e7          	jalr	252(ra) # 80000be4 <acquire>
    p->last_cpu = cpu_num;
    80002af0:	16992423          	sw	s1,360(s2)
    release(&p->lock);
    80002af4:	854a                	mv	a0,s2
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	1a2080e7          	jalr	418(ra) # 80000c98 <release>

    yield();
    80002afe:	00000097          	auipc	ra,0x0
    80002b02:	9da080e7          	jalr	-1574(ra) # 800024d8 <yield>

    return cpu_num;
    80002b06:	8526                	mv	a0,s1
  }
  return -1;
}
    80002b08:	60e2                	ld	ra,24(sp)
    80002b0a:	6442                	ld	s0,16(sp)
    80002b0c:	64a2                	ld	s1,8(sp)
    80002b0e:	6902                	ld	s2,0(sp)
    80002b10:	6105                	addi	sp,sp,32
    80002b12:	8082                	ret
  return -1;
    80002b14:	557d                	li	a0,-1
    80002b16:	bfcd                	j	80002b08 <set_cpu+0x42>

0000000080002b18 <get_cpu>:

// return the current CPU id.
int
get_cpu(void){
    80002b18:	1141                	addi	sp,sp,-16
    80002b1a:	e406                	sd	ra,8(sp)
    80002b1c:	e022                	sd	s0,0(sp)
    80002b1e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b20:	fffff097          	auipc	ra,0xfffff
    80002b24:	21a080e7          	jalr	538(ra) # 80001d3a <myproc>
  return p->last_cpu;
}
    80002b28:	16852503          	lw	a0,360(a0)
    80002b2c:	60a2                	ld	ra,8(sp)
    80002b2e:	6402                	ld	s0,0(sp)
    80002b30:	0141                	addi	sp,sp,16
    80002b32:	8082                	ret

0000000080002b34 <min_cpu>:

int
min_cpu(void){
    80002b34:	1141                	addi	sp,sp,-16
    80002b36:	e422                	sd	s0,8(sp)
    80002b38:	0800                	addi	s0,sp,16
  struct cpu *c, *min_cpu;
// should add an if to insure numberOfCpus>0
  min_cpu = cpus;
    80002b3a:	0000e617          	auipc	a2,0xe
    80002b3e:	76660613          	addi	a2,a2,1894 # 800112a0 <cpus>
  for(c = cpus + 1; c < &cpus[NCPU] && c != NULL ; c++){
    80002b42:	0000f797          	auipc	a5,0xf
    80002b46:	80678793          	addi	a5,a5,-2042 # 80011348 <cpus+0xa8>
    80002b4a:	0000f597          	auipc	a1,0xf
    80002b4e:	c9658593          	addi	a1,a1,-874 # 800117e0 <pid_lock>
    80002b52:	a029                	j	80002b5c <min_cpu+0x28>
    80002b54:	0a878793          	addi	a5,a5,168
    80002b58:	00b78a63          	beq	a5,a1,80002b6c <min_cpu+0x38>
    if (c->proc_cnt < min_cpu->proc_cnt)
    80002b5c:	0807a683          	lw	a3,128(a5)
    80002b60:	08062703          	lw	a4,128(a2)
    80002b64:	fee6d8e3          	bge	a3,a4,80002b54 <min_cpu+0x20>
    80002b68:	863e                	mv	a2,a5
    80002b6a:	b7ed                	j	80002b54 <min_cpu+0x20>
        min_cpu = c;
  }
  return min_cpu->cpu_id;   
}
    80002b6c:	08462503          	lw	a0,132(a2)
    80002b70:	6422                	ld	s0,8(sp)
    80002b72:	0141                	addi	sp,sp,16
    80002b74:	8082                	ret

0000000080002b76 <cpu_process_count>:

int
cpu_process_count(int cpu_num){
    80002b76:	1141                	addi	sp,sp,-16
    80002b78:	e422                	sd	s0,8(sp)
    80002b7a:	0800                	addi	s0,sp,16
  if (cpu_num > 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL) 
    80002b7c:	fff5071b          	addiw	a4,a0,-1
    80002b80:	4799                	li	a5,6
    80002b82:	02e7e063          	bltu	a5,a4,80002ba2 <cpu_process_count+0x2c>
    return cpus[cpu_num].proc_cnt;
    80002b86:	0a800793          	li	a5,168
    80002b8a:	02f50533          	mul	a0,a0,a5
    80002b8e:	0000e797          	auipc	a5,0xe
    80002b92:	71278793          	addi	a5,a5,1810 # 800112a0 <cpus>
    80002b96:	953e                	add	a0,a0,a5
    80002b98:	08052503          	lw	a0,128(a0)
  return -1;
}
    80002b9c:	6422                	ld	s0,8(sp)
    80002b9e:	0141                	addi	sp,sp,16
    80002ba0:	8082                	ret
  return -1;
    80002ba2:	557d                	li	a0,-1
    80002ba4:	bfe5                	j	80002b9c <cpu_process_count+0x26>

0000000080002ba6 <steal_process>:




void
steal_process(struct cpu *curr_c){  /*
    80002ba6:	1141                	addi	sp,sp,-16
    80002ba8:	e422                	sd	s0,8(sp)
    80002baa:	0800                	addi	s0,sp,16
  }
  p = proc[stolen_process];
  append(&c->runnable_list, p);
  p->last_cpu = c->cpu_id;
  inc_cpu(c); */
    80002bac:	6422                	ld	s0,8(sp)
    80002bae:	0141                	addi	sp,sp,16
    80002bb0:	8082                	ret

0000000080002bb2 <swtch>:
    80002bb2:	00153023          	sd	ra,0(a0)
    80002bb6:	00253423          	sd	sp,8(a0)
    80002bba:	e900                	sd	s0,16(a0)
    80002bbc:	ed04                	sd	s1,24(a0)
    80002bbe:	03253023          	sd	s2,32(a0)
    80002bc2:	03353423          	sd	s3,40(a0)
    80002bc6:	03453823          	sd	s4,48(a0)
    80002bca:	03553c23          	sd	s5,56(a0)
    80002bce:	05653023          	sd	s6,64(a0)
    80002bd2:	05753423          	sd	s7,72(a0)
    80002bd6:	05853823          	sd	s8,80(a0)
    80002bda:	05953c23          	sd	s9,88(a0)
    80002bde:	07a53023          	sd	s10,96(a0)
    80002be2:	07b53423          	sd	s11,104(a0)
    80002be6:	0005b083          	ld	ra,0(a1)
    80002bea:	0085b103          	ld	sp,8(a1)
    80002bee:	6980                	ld	s0,16(a1)
    80002bf0:	6d84                	ld	s1,24(a1)
    80002bf2:	0205b903          	ld	s2,32(a1)
    80002bf6:	0285b983          	ld	s3,40(a1)
    80002bfa:	0305ba03          	ld	s4,48(a1)
    80002bfe:	0385ba83          	ld	s5,56(a1)
    80002c02:	0405bb03          	ld	s6,64(a1)
    80002c06:	0485bb83          	ld	s7,72(a1)
    80002c0a:	0505bc03          	ld	s8,80(a1)
    80002c0e:	0585bc83          	ld	s9,88(a1)
    80002c12:	0605bd03          	ld	s10,96(a1)
    80002c16:	0685bd83          	ld	s11,104(a1)
    80002c1a:	8082                	ret

0000000080002c1c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c1c:	1141                	addi	sp,sp,-16
    80002c1e:	e406                	sd	ra,8(sp)
    80002c20:	e022                	sd	s0,0(sp)
    80002c22:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c24:	00005597          	auipc	a1,0x5
    80002c28:	75458593          	addi	a1,a1,1876 # 80008378 <states.1780+0x30>
    80002c2c:	00015517          	auipc	a0,0x15
    80002c30:	fe450513          	addi	a0,a0,-28 # 80017c10 <tickslock>
    80002c34:	ffffe097          	auipc	ra,0xffffe
    80002c38:	f20080e7          	jalr	-224(ra) # 80000b54 <initlock>
}
    80002c3c:	60a2                	ld	ra,8(sp)
    80002c3e:	6402                	ld	s0,0(sp)
    80002c40:	0141                	addi	sp,sp,16
    80002c42:	8082                	ret

0000000080002c44 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c44:	1141                	addi	sp,sp,-16
    80002c46:	e422                	sd	s0,8(sp)
    80002c48:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c4a:	00003797          	auipc	a5,0x3
    80002c4e:	48678793          	addi	a5,a5,1158 # 800060d0 <kernelvec>
    80002c52:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c56:	6422                	ld	s0,8(sp)
    80002c58:	0141                	addi	sp,sp,16
    80002c5a:	8082                	ret

0000000080002c5c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002c5c:	1141                	addi	sp,sp,-16
    80002c5e:	e406                	sd	ra,8(sp)
    80002c60:	e022                	sd	s0,0(sp)
    80002c62:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c64:	fffff097          	auipc	ra,0xfffff
    80002c68:	0d6080e7          	jalr	214(ra) # 80001d3a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c6c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c70:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c72:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002c76:	00004617          	auipc	a2,0x4
    80002c7a:	38a60613          	addi	a2,a2,906 # 80007000 <_trampoline>
    80002c7e:	00004697          	auipc	a3,0x4
    80002c82:	38268693          	addi	a3,a3,898 # 80007000 <_trampoline>
    80002c86:	8e91                	sub	a3,a3,a2
    80002c88:	040007b7          	lui	a5,0x4000
    80002c8c:	17fd                	addi	a5,a5,-1
    80002c8e:	07b2                	slli	a5,a5,0xc
    80002c90:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c92:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c96:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c98:	180026f3          	csrr	a3,satp
    80002c9c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c9e:	6d38                	ld	a4,88(a0)
    80002ca0:	6134                	ld	a3,64(a0)
    80002ca2:	6585                	lui	a1,0x1
    80002ca4:	96ae                	add	a3,a3,a1
    80002ca6:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ca8:	6d38                	ld	a4,88(a0)
    80002caa:	00000697          	auipc	a3,0x0
    80002cae:	13868693          	addi	a3,a3,312 # 80002de2 <usertrap>
    80002cb2:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002cb4:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002cb6:	8692                	mv	a3,tp
    80002cb8:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cba:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002cbe:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002cc2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cc6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002cca:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ccc:	6f18                	ld	a4,24(a4)
    80002cce:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002cd2:	692c                	ld	a1,80(a0)
    80002cd4:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002cd6:	00004717          	auipc	a4,0x4
    80002cda:	3ba70713          	addi	a4,a4,954 # 80007090 <userret>
    80002cde:	8f11                	sub	a4,a4,a2
    80002ce0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002ce2:	577d                	li	a4,-1
    80002ce4:	177e                	slli	a4,a4,0x3f
    80002ce6:	8dd9                	or	a1,a1,a4
    80002ce8:	02000537          	lui	a0,0x2000
    80002cec:	157d                	addi	a0,a0,-1
    80002cee:	0536                	slli	a0,a0,0xd
    80002cf0:	9782                	jalr	a5
}
    80002cf2:	60a2                	ld	ra,8(sp)
    80002cf4:	6402                	ld	s0,0(sp)
    80002cf6:	0141                	addi	sp,sp,16
    80002cf8:	8082                	ret

0000000080002cfa <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002cfa:	1101                	addi	sp,sp,-32
    80002cfc:	ec06                	sd	ra,24(sp)
    80002cfe:	e822                	sd	s0,16(sp)
    80002d00:	e426                	sd	s1,8(sp)
    80002d02:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d04:	00015497          	auipc	s1,0x15
    80002d08:	f0c48493          	addi	s1,s1,-244 # 80017c10 <tickslock>
    80002d0c:	8526                	mv	a0,s1
    80002d0e:	ffffe097          	auipc	ra,0xffffe
    80002d12:	ed6080e7          	jalr	-298(ra) # 80000be4 <acquire>
  ticks++;
    80002d16:	00006517          	auipc	a0,0x6
    80002d1a:	31a50513          	addi	a0,a0,794 # 80009030 <ticks>
    80002d1e:	411c                	lw	a5,0(a0)
    80002d20:	2785                	addiw	a5,a5,1
    80002d22:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002d24:	00000097          	auipc	ra,0x0
    80002d28:	9b2080e7          	jalr	-1614(ra) # 800026d6 <wakeup>
  release(&tickslock);
    80002d2c:	8526                	mv	a0,s1
    80002d2e:	ffffe097          	auipc	ra,0xffffe
    80002d32:	f6a080e7          	jalr	-150(ra) # 80000c98 <release>
}
    80002d36:	60e2                	ld	ra,24(sp)
    80002d38:	6442                	ld	s0,16(sp)
    80002d3a:	64a2                	ld	s1,8(sp)
    80002d3c:	6105                	addi	sp,sp,32
    80002d3e:	8082                	ret

0000000080002d40 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002d40:	1101                	addi	sp,sp,-32
    80002d42:	ec06                	sd	ra,24(sp)
    80002d44:	e822                	sd	s0,16(sp)
    80002d46:	e426                	sd	s1,8(sp)
    80002d48:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d4a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002d4e:	00074d63          	bltz	a4,80002d68 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002d52:	57fd                	li	a5,-1
    80002d54:	17fe                	slli	a5,a5,0x3f
    80002d56:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002d58:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002d5a:	06f70363          	beq	a4,a5,80002dc0 <devintr+0x80>
  }
}
    80002d5e:	60e2                	ld	ra,24(sp)
    80002d60:	6442                	ld	s0,16(sp)
    80002d62:	64a2                	ld	s1,8(sp)
    80002d64:	6105                	addi	sp,sp,32
    80002d66:	8082                	ret
     (scause & 0xff) == 9){
    80002d68:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002d6c:	46a5                	li	a3,9
    80002d6e:	fed792e3          	bne	a5,a3,80002d52 <devintr+0x12>
    int irq = plic_claim();
    80002d72:	00003097          	auipc	ra,0x3
    80002d76:	466080e7          	jalr	1126(ra) # 800061d8 <plic_claim>
    80002d7a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d7c:	47a9                	li	a5,10
    80002d7e:	02f50763          	beq	a0,a5,80002dac <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002d82:	4785                	li	a5,1
    80002d84:	02f50963          	beq	a0,a5,80002db6 <devintr+0x76>
    return 1;
    80002d88:	4505                	li	a0,1
    } else if(irq){
    80002d8a:	d8f1                	beqz	s1,80002d5e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d8c:	85a6                	mv	a1,s1
    80002d8e:	00005517          	auipc	a0,0x5
    80002d92:	5f250513          	addi	a0,a0,1522 # 80008380 <states.1780+0x38>
    80002d96:	ffffd097          	auipc	ra,0xffffd
    80002d9a:	7f2080e7          	jalr	2034(ra) # 80000588 <printf>
      plic_complete(irq);
    80002d9e:	8526                	mv	a0,s1
    80002da0:	00003097          	auipc	ra,0x3
    80002da4:	45c080e7          	jalr	1116(ra) # 800061fc <plic_complete>
    return 1;
    80002da8:	4505                	li	a0,1
    80002daa:	bf55                	j	80002d5e <devintr+0x1e>
      uartintr();
    80002dac:	ffffe097          	auipc	ra,0xffffe
    80002db0:	bfc080e7          	jalr	-1028(ra) # 800009a8 <uartintr>
    80002db4:	b7ed                	j	80002d9e <devintr+0x5e>
      virtio_disk_intr();
    80002db6:	00004097          	auipc	ra,0x4
    80002dba:	926080e7          	jalr	-1754(ra) # 800066dc <virtio_disk_intr>
    80002dbe:	b7c5                	j	80002d9e <devintr+0x5e>
    if(cpuid() == 0){
    80002dc0:	fffff097          	auipc	ra,0xfffff
    80002dc4:	f48080e7          	jalr	-184(ra) # 80001d08 <cpuid>
    80002dc8:	c901                	beqz	a0,80002dd8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002dca:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002dce:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002dd0:	14479073          	csrw	sip,a5
    return 2;
    80002dd4:	4509                	li	a0,2
    80002dd6:	b761                	j	80002d5e <devintr+0x1e>
      clockintr();
    80002dd8:	00000097          	auipc	ra,0x0
    80002ddc:	f22080e7          	jalr	-222(ra) # 80002cfa <clockintr>
    80002de0:	b7ed                	j	80002dca <devintr+0x8a>

0000000080002de2 <usertrap>:
{
    80002de2:	1101                	addi	sp,sp,-32
    80002de4:	ec06                	sd	ra,24(sp)
    80002de6:	e822                	sd	s0,16(sp)
    80002de8:	e426                	sd	s1,8(sp)
    80002dea:	e04a                	sd	s2,0(sp)
    80002dec:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dee:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002df2:	1007f793          	andi	a5,a5,256
    80002df6:	e3ad                	bnez	a5,80002e58 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002df8:	00003797          	auipc	a5,0x3
    80002dfc:	2d878793          	addi	a5,a5,728 # 800060d0 <kernelvec>
    80002e00:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e04:	fffff097          	auipc	ra,0xfffff
    80002e08:	f36080e7          	jalr	-202(ra) # 80001d3a <myproc>
    80002e0c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e0e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e10:	14102773          	csrr	a4,sepc
    80002e14:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e16:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002e1a:	47a1                	li	a5,8
    80002e1c:	04f71c63          	bne	a4,a5,80002e74 <usertrap+0x92>
    if(p->killed)
    80002e20:	551c                	lw	a5,40(a0)
    80002e22:	e3b9                	bnez	a5,80002e68 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002e24:	6cb8                	ld	a4,88(s1)
    80002e26:	6f1c                	ld	a5,24(a4)
    80002e28:	0791                	addi	a5,a5,4
    80002e2a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e2c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e30:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e34:	10079073          	csrw	sstatus,a5
    syscall();
    80002e38:	00000097          	auipc	ra,0x0
    80002e3c:	2e0080e7          	jalr	736(ra) # 80003118 <syscall>
  if(p->killed)
    80002e40:	549c                	lw	a5,40(s1)
    80002e42:	ebc1                	bnez	a5,80002ed2 <usertrap+0xf0>
  usertrapret();
    80002e44:	00000097          	auipc	ra,0x0
    80002e48:	e18080e7          	jalr	-488(ra) # 80002c5c <usertrapret>
}
    80002e4c:	60e2                	ld	ra,24(sp)
    80002e4e:	6442                	ld	s0,16(sp)
    80002e50:	64a2                	ld	s1,8(sp)
    80002e52:	6902                	ld	s2,0(sp)
    80002e54:	6105                	addi	sp,sp,32
    80002e56:	8082                	ret
    panic("usertrap: not from user mode");
    80002e58:	00005517          	auipc	a0,0x5
    80002e5c:	54850513          	addi	a0,a0,1352 # 800083a0 <states.1780+0x58>
    80002e60:	ffffd097          	auipc	ra,0xffffd
    80002e64:	6de080e7          	jalr	1758(ra) # 8000053e <panic>
      exit(-1);
    80002e68:	557d                	li	a0,-1
    80002e6a:	00000097          	auipc	ra,0x0
    80002e6e:	9a8080e7          	jalr	-1624(ra) # 80002812 <exit>
    80002e72:	bf4d                	j	80002e24 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002e74:	00000097          	auipc	ra,0x0
    80002e78:	ecc080e7          	jalr	-308(ra) # 80002d40 <devintr>
    80002e7c:	892a                	mv	s2,a0
    80002e7e:	c501                	beqz	a0,80002e86 <usertrap+0xa4>
  if(p->killed)
    80002e80:	549c                	lw	a5,40(s1)
    80002e82:	c3a1                	beqz	a5,80002ec2 <usertrap+0xe0>
    80002e84:	a815                	j	80002eb8 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e86:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e8a:	5890                	lw	a2,48(s1)
    80002e8c:	00005517          	auipc	a0,0x5
    80002e90:	53450513          	addi	a0,a0,1332 # 800083c0 <states.1780+0x78>
    80002e94:	ffffd097          	auipc	ra,0xffffd
    80002e98:	6f4080e7          	jalr	1780(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e9c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ea0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ea4:	00005517          	auipc	a0,0x5
    80002ea8:	54c50513          	addi	a0,a0,1356 # 800083f0 <states.1780+0xa8>
    80002eac:	ffffd097          	auipc	ra,0xffffd
    80002eb0:	6dc080e7          	jalr	1756(ra) # 80000588 <printf>
    p->killed = 1;
    80002eb4:	4785                	li	a5,1
    80002eb6:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002eb8:	557d                	li	a0,-1
    80002eba:	00000097          	auipc	ra,0x0
    80002ebe:	958080e7          	jalr	-1704(ra) # 80002812 <exit>
  if(which_dev == 2)
    80002ec2:	4789                	li	a5,2
    80002ec4:	f8f910e3          	bne	s2,a5,80002e44 <usertrap+0x62>
    yield();
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	610080e7          	jalr	1552(ra) # 800024d8 <yield>
    80002ed0:	bf95                	j	80002e44 <usertrap+0x62>
  int which_dev = 0;
    80002ed2:	4901                	li	s2,0
    80002ed4:	b7d5                	j	80002eb8 <usertrap+0xd6>

0000000080002ed6 <kerneltrap>:
{
    80002ed6:	7179                	addi	sp,sp,-48
    80002ed8:	f406                	sd	ra,40(sp)
    80002eda:	f022                	sd	s0,32(sp)
    80002edc:	ec26                	sd	s1,24(sp)
    80002ede:	e84a                	sd	s2,16(sp)
    80002ee0:	e44e                	sd	s3,8(sp)
    80002ee2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ee4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ee8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eec:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002ef0:	1004f793          	andi	a5,s1,256
    80002ef4:	cb85                	beqz	a5,80002f24 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ef6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002efa:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002efc:	ef85                	bnez	a5,80002f34 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002efe:	00000097          	auipc	ra,0x0
    80002f02:	e42080e7          	jalr	-446(ra) # 80002d40 <devintr>
    80002f06:	cd1d                	beqz	a0,80002f44 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f08:	4789                	li	a5,2
    80002f0a:	06f50a63          	beq	a0,a5,80002f7e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f0e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f12:	10049073          	csrw	sstatus,s1
}
    80002f16:	70a2                	ld	ra,40(sp)
    80002f18:	7402                	ld	s0,32(sp)
    80002f1a:	64e2                	ld	s1,24(sp)
    80002f1c:	6942                	ld	s2,16(sp)
    80002f1e:	69a2                	ld	s3,8(sp)
    80002f20:	6145                	addi	sp,sp,48
    80002f22:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f24:	00005517          	auipc	a0,0x5
    80002f28:	4ec50513          	addi	a0,a0,1260 # 80008410 <states.1780+0xc8>
    80002f2c:	ffffd097          	auipc	ra,0xffffd
    80002f30:	612080e7          	jalr	1554(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002f34:	00005517          	auipc	a0,0x5
    80002f38:	50450513          	addi	a0,a0,1284 # 80008438 <states.1780+0xf0>
    80002f3c:	ffffd097          	auipc	ra,0xffffd
    80002f40:	602080e7          	jalr	1538(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002f44:	85ce                	mv	a1,s3
    80002f46:	00005517          	auipc	a0,0x5
    80002f4a:	51250513          	addi	a0,a0,1298 # 80008458 <states.1780+0x110>
    80002f4e:	ffffd097          	auipc	ra,0xffffd
    80002f52:	63a080e7          	jalr	1594(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f56:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f5a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f5e:	00005517          	auipc	a0,0x5
    80002f62:	50a50513          	addi	a0,a0,1290 # 80008468 <states.1780+0x120>
    80002f66:	ffffd097          	auipc	ra,0xffffd
    80002f6a:	622080e7          	jalr	1570(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002f6e:	00005517          	auipc	a0,0x5
    80002f72:	51250513          	addi	a0,a0,1298 # 80008480 <states.1780+0x138>
    80002f76:	ffffd097          	auipc	ra,0xffffd
    80002f7a:	5c8080e7          	jalr	1480(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f7e:	fffff097          	auipc	ra,0xfffff
    80002f82:	dbc080e7          	jalr	-580(ra) # 80001d3a <myproc>
    80002f86:	d541                	beqz	a0,80002f0e <kerneltrap+0x38>
    80002f88:	fffff097          	auipc	ra,0xfffff
    80002f8c:	db2080e7          	jalr	-590(ra) # 80001d3a <myproc>
    80002f90:	4d18                	lw	a4,24(a0)
    80002f92:	4791                	li	a5,4
    80002f94:	f6f71de3          	bne	a4,a5,80002f0e <kerneltrap+0x38>
    yield();
    80002f98:	fffff097          	auipc	ra,0xfffff
    80002f9c:	540080e7          	jalr	1344(ra) # 800024d8 <yield>
    80002fa0:	b7bd                	j	80002f0e <kerneltrap+0x38>

0000000080002fa2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002fa2:	1101                	addi	sp,sp,-32
    80002fa4:	ec06                	sd	ra,24(sp)
    80002fa6:	e822                	sd	s0,16(sp)
    80002fa8:	e426                	sd	s1,8(sp)
    80002faa:	1000                	addi	s0,sp,32
    80002fac:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002fae:	fffff097          	auipc	ra,0xfffff
    80002fb2:	d8c080e7          	jalr	-628(ra) # 80001d3a <myproc>
  switch (n) {
    80002fb6:	4795                	li	a5,5
    80002fb8:	0497e163          	bltu	a5,s1,80002ffa <argraw+0x58>
    80002fbc:	048a                	slli	s1,s1,0x2
    80002fbe:	00005717          	auipc	a4,0x5
    80002fc2:	4fa70713          	addi	a4,a4,1274 # 800084b8 <states.1780+0x170>
    80002fc6:	94ba                	add	s1,s1,a4
    80002fc8:	409c                	lw	a5,0(s1)
    80002fca:	97ba                	add	a5,a5,a4
    80002fcc:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002fce:	6d3c                	ld	a5,88(a0)
    80002fd0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002fd2:	60e2                	ld	ra,24(sp)
    80002fd4:	6442                	ld	s0,16(sp)
    80002fd6:	64a2                	ld	s1,8(sp)
    80002fd8:	6105                	addi	sp,sp,32
    80002fda:	8082                	ret
    return p->trapframe->a1;
    80002fdc:	6d3c                	ld	a5,88(a0)
    80002fde:	7fa8                	ld	a0,120(a5)
    80002fe0:	bfcd                	j	80002fd2 <argraw+0x30>
    return p->trapframe->a2;
    80002fe2:	6d3c                	ld	a5,88(a0)
    80002fe4:	63c8                	ld	a0,128(a5)
    80002fe6:	b7f5                	j	80002fd2 <argraw+0x30>
    return p->trapframe->a3;
    80002fe8:	6d3c                	ld	a5,88(a0)
    80002fea:	67c8                	ld	a0,136(a5)
    80002fec:	b7dd                	j	80002fd2 <argraw+0x30>
    return p->trapframe->a4;
    80002fee:	6d3c                	ld	a5,88(a0)
    80002ff0:	6bc8                	ld	a0,144(a5)
    80002ff2:	b7c5                	j	80002fd2 <argraw+0x30>
    return p->trapframe->a5;
    80002ff4:	6d3c                	ld	a5,88(a0)
    80002ff6:	6fc8                	ld	a0,152(a5)
    80002ff8:	bfe9                	j	80002fd2 <argraw+0x30>
  panic("argraw");
    80002ffa:	00005517          	auipc	a0,0x5
    80002ffe:	49650513          	addi	a0,a0,1174 # 80008490 <states.1780+0x148>
    80003002:	ffffd097          	auipc	ra,0xffffd
    80003006:	53c080e7          	jalr	1340(ra) # 8000053e <panic>

000000008000300a <fetchaddr>:
{
    8000300a:	1101                	addi	sp,sp,-32
    8000300c:	ec06                	sd	ra,24(sp)
    8000300e:	e822                	sd	s0,16(sp)
    80003010:	e426                	sd	s1,8(sp)
    80003012:	e04a                	sd	s2,0(sp)
    80003014:	1000                	addi	s0,sp,32
    80003016:	84aa                	mv	s1,a0
    80003018:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000301a:	fffff097          	auipc	ra,0xfffff
    8000301e:	d20080e7          	jalr	-736(ra) # 80001d3a <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003022:	653c                	ld	a5,72(a0)
    80003024:	02f4f863          	bgeu	s1,a5,80003054 <fetchaddr+0x4a>
    80003028:	00848713          	addi	a4,s1,8
    8000302c:	02e7e663          	bltu	a5,a4,80003058 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003030:	46a1                	li	a3,8
    80003032:	8626                	mv	a2,s1
    80003034:	85ca                	mv	a1,s2
    80003036:	6928                	ld	a0,80(a0)
    80003038:	ffffe097          	auipc	ra,0xffffe
    8000303c:	6c6080e7          	jalr	1734(ra) # 800016fe <copyin>
    80003040:	00a03533          	snez	a0,a0
    80003044:	40a00533          	neg	a0,a0
}
    80003048:	60e2                	ld	ra,24(sp)
    8000304a:	6442                	ld	s0,16(sp)
    8000304c:	64a2                	ld	s1,8(sp)
    8000304e:	6902                	ld	s2,0(sp)
    80003050:	6105                	addi	sp,sp,32
    80003052:	8082                	ret
    return -1;
    80003054:	557d                	li	a0,-1
    80003056:	bfcd                	j	80003048 <fetchaddr+0x3e>
    80003058:	557d                	li	a0,-1
    8000305a:	b7fd                	j	80003048 <fetchaddr+0x3e>

000000008000305c <fetchstr>:
{
    8000305c:	7179                	addi	sp,sp,-48
    8000305e:	f406                	sd	ra,40(sp)
    80003060:	f022                	sd	s0,32(sp)
    80003062:	ec26                	sd	s1,24(sp)
    80003064:	e84a                	sd	s2,16(sp)
    80003066:	e44e                	sd	s3,8(sp)
    80003068:	1800                	addi	s0,sp,48
    8000306a:	892a                	mv	s2,a0
    8000306c:	84ae                	mv	s1,a1
    8000306e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003070:	fffff097          	auipc	ra,0xfffff
    80003074:	cca080e7          	jalr	-822(ra) # 80001d3a <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003078:	86ce                	mv	a3,s3
    8000307a:	864a                	mv	a2,s2
    8000307c:	85a6                	mv	a1,s1
    8000307e:	6928                	ld	a0,80(a0)
    80003080:	ffffe097          	auipc	ra,0xffffe
    80003084:	70a080e7          	jalr	1802(ra) # 8000178a <copyinstr>
  if(err < 0)
    80003088:	00054763          	bltz	a0,80003096 <fetchstr+0x3a>
  return strlen(buf);
    8000308c:	8526                	mv	a0,s1
    8000308e:	ffffe097          	auipc	ra,0xffffe
    80003092:	dd6080e7          	jalr	-554(ra) # 80000e64 <strlen>
}
    80003096:	70a2                	ld	ra,40(sp)
    80003098:	7402                	ld	s0,32(sp)
    8000309a:	64e2                	ld	s1,24(sp)
    8000309c:	6942                	ld	s2,16(sp)
    8000309e:	69a2                	ld	s3,8(sp)
    800030a0:	6145                	addi	sp,sp,48
    800030a2:	8082                	ret

00000000800030a4 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800030a4:	1101                	addi	sp,sp,-32
    800030a6:	ec06                	sd	ra,24(sp)
    800030a8:	e822                	sd	s0,16(sp)
    800030aa:	e426                	sd	s1,8(sp)
    800030ac:	1000                	addi	s0,sp,32
    800030ae:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030b0:	00000097          	auipc	ra,0x0
    800030b4:	ef2080e7          	jalr	-270(ra) # 80002fa2 <argraw>
    800030b8:	c088                	sw	a0,0(s1)
  return 0;
}
    800030ba:	4501                	li	a0,0
    800030bc:	60e2                	ld	ra,24(sp)
    800030be:	6442                	ld	s0,16(sp)
    800030c0:	64a2                	ld	s1,8(sp)
    800030c2:	6105                	addi	sp,sp,32
    800030c4:	8082                	ret

00000000800030c6 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800030c6:	1101                	addi	sp,sp,-32
    800030c8:	ec06                	sd	ra,24(sp)
    800030ca:	e822                	sd	s0,16(sp)
    800030cc:	e426                	sd	s1,8(sp)
    800030ce:	1000                	addi	s0,sp,32
    800030d0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030d2:	00000097          	auipc	ra,0x0
    800030d6:	ed0080e7          	jalr	-304(ra) # 80002fa2 <argraw>
    800030da:	e088                	sd	a0,0(s1)
  return 0;
}
    800030dc:	4501                	li	a0,0
    800030de:	60e2                	ld	ra,24(sp)
    800030e0:	6442                	ld	s0,16(sp)
    800030e2:	64a2                	ld	s1,8(sp)
    800030e4:	6105                	addi	sp,sp,32
    800030e6:	8082                	ret

00000000800030e8 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800030e8:	1101                	addi	sp,sp,-32
    800030ea:	ec06                	sd	ra,24(sp)
    800030ec:	e822                	sd	s0,16(sp)
    800030ee:	e426                	sd	s1,8(sp)
    800030f0:	e04a                	sd	s2,0(sp)
    800030f2:	1000                	addi	s0,sp,32
    800030f4:	84ae                	mv	s1,a1
    800030f6:	8932                	mv	s2,a2
  *ip = argraw(n);
    800030f8:	00000097          	auipc	ra,0x0
    800030fc:	eaa080e7          	jalr	-342(ra) # 80002fa2 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003100:	864a                	mv	a2,s2
    80003102:	85a6                	mv	a1,s1
    80003104:	00000097          	auipc	ra,0x0
    80003108:	f58080e7          	jalr	-168(ra) # 8000305c <fetchstr>
}
    8000310c:	60e2                	ld	ra,24(sp)
    8000310e:	6442                	ld	s0,16(sp)
    80003110:	64a2                	ld	s1,8(sp)
    80003112:	6902                	ld	s2,0(sp)
    80003114:	6105                	addi	sp,sp,32
    80003116:	8082                	ret

0000000080003118 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80003118:	1101                	addi	sp,sp,-32
    8000311a:	ec06                	sd	ra,24(sp)
    8000311c:	e822                	sd	s0,16(sp)
    8000311e:	e426                	sd	s1,8(sp)
    80003120:	e04a                	sd	s2,0(sp)
    80003122:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003124:	fffff097          	auipc	ra,0xfffff
    80003128:	c16080e7          	jalr	-1002(ra) # 80001d3a <myproc>
    8000312c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000312e:	05853903          	ld	s2,88(a0)
    80003132:	0a893783          	ld	a5,168(s2)
    80003136:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000313a:	37fd                	addiw	a5,a5,-1
    8000313c:	4751                	li	a4,20
    8000313e:	00f76f63          	bltu	a4,a5,8000315c <syscall+0x44>
    80003142:	00369713          	slli	a4,a3,0x3
    80003146:	00005797          	auipc	a5,0x5
    8000314a:	38a78793          	addi	a5,a5,906 # 800084d0 <syscalls>
    8000314e:	97ba                	add	a5,a5,a4
    80003150:	639c                	ld	a5,0(a5)
    80003152:	c789                	beqz	a5,8000315c <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003154:	9782                	jalr	a5
    80003156:	06a93823          	sd	a0,112(s2)
    8000315a:	a839                	j	80003178 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000315c:	15848613          	addi	a2,s1,344
    80003160:	588c                	lw	a1,48(s1)
    80003162:	00005517          	auipc	a0,0x5
    80003166:	33650513          	addi	a0,a0,822 # 80008498 <states.1780+0x150>
    8000316a:	ffffd097          	auipc	ra,0xffffd
    8000316e:	41e080e7          	jalr	1054(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003172:	6cbc                	ld	a5,88(s1)
    80003174:	577d                	li	a4,-1
    80003176:	fbb8                	sd	a4,112(a5)
  }
}
    80003178:	60e2                	ld	ra,24(sp)
    8000317a:	6442                	ld	s0,16(sp)
    8000317c:	64a2                	ld	s1,8(sp)
    8000317e:	6902                	ld	s2,0(sp)
    80003180:	6105                	addi	sp,sp,32
    80003182:	8082                	ret

0000000080003184 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003184:	1101                	addi	sp,sp,-32
    80003186:	ec06                	sd	ra,24(sp)
    80003188:	e822                	sd	s0,16(sp)
    8000318a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000318c:	fec40593          	addi	a1,s0,-20
    80003190:	4501                	li	a0,0
    80003192:	00000097          	auipc	ra,0x0
    80003196:	f12080e7          	jalr	-238(ra) # 800030a4 <argint>
    return -1;
    8000319a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000319c:	00054963          	bltz	a0,800031ae <sys_exit+0x2a>
  exit(n);
    800031a0:	fec42503          	lw	a0,-20(s0)
    800031a4:	fffff097          	auipc	ra,0xfffff
    800031a8:	66e080e7          	jalr	1646(ra) # 80002812 <exit>
  return 0;  // not reached
    800031ac:	4781                	li	a5,0
}
    800031ae:	853e                	mv	a0,a5
    800031b0:	60e2                	ld	ra,24(sp)
    800031b2:	6442                	ld	s0,16(sp)
    800031b4:	6105                	addi	sp,sp,32
    800031b6:	8082                	ret

00000000800031b8 <sys_getpid>:

uint64
sys_getpid(void)
{
    800031b8:	1141                	addi	sp,sp,-16
    800031ba:	e406                	sd	ra,8(sp)
    800031bc:	e022                	sd	s0,0(sp)
    800031be:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800031c0:	fffff097          	auipc	ra,0xfffff
    800031c4:	b7a080e7          	jalr	-1158(ra) # 80001d3a <myproc>
}
    800031c8:	5908                	lw	a0,48(a0)
    800031ca:	60a2                	ld	ra,8(sp)
    800031cc:	6402                	ld	s0,0(sp)
    800031ce:	0141                	addi	sp,sp,16
    800031d0:	8082                	ret

00000000800031d2 <sys_fork>:

uint64
sys_fork(void)
{
    800031d2:	1141                	addi	sp,sp,-16
    800031d4:	e406                	sd	ra,8(sp)
    800031d6:	e022                	sd	s0,0(sp)
    800031d8:	0800                	addi	s0,sp,16
  return fork();
    800031da:	fffff097          	auipc	ra,0xfffff
    800031de:	fe8080e7          	jalr	-24(ra) # 800021c2 <fork>
}
    800031e2:	60a2                	ld	ra,8(sp)
    800031e4:	6402                	ld	s0,0(sp)
    800031e6:	0141                	addi	sp,sp,16
    800031e8:	8082                	ret

00000000800031ea <sys_wait>:

uint64
sys_wait(void)
{
    800031ea:	1101                	addi	sp,sp,-32
    800031ec:	ec06                	sd	ra,24(sp)
    800031ee:	e822                	sd	s0,16(sp)
    800031f0:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800031f2:	fe840593          	addi	a1,s0,-24
    800031f6:	4501                	li	a0,0
    800031f8:	00000097          	auipc	ra,0x0
    800031fc:	ece080e7          	jalr	-306(ra) # 800030c6 <argaddr>
    80003200:	87aa                	mv	a5,a0
    return -1;
    80003202:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003204:	0007c863          	bltz	a5,80003214 <sys_wait+0x2a>
  return wait(p);
    80003208:	fe843503          	ld	a0,-24(s0)
    8000320c:	fffff097          	auipc	ra,0xfffff
    80003210:	3a2080e7          	jalr	930(ra) # 800025ae <wait>
}
    80003214:	60e2                	ld	ra,24(sp)
    80003216:	6442                	ld	s0,16(sp)
    80003218:	6105                	addi	sp,sp,32
    8000321a:	8082                	ret

000000008000321c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000321c:	7179                	addi	sp,sp,-48
    8000321e:	f406                	sd	ra,40(sp)
    80003220:	f022                	sd	s0,32(sp)
    80003222:	ec26                	sd	s1,24(sp)
    80003224:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003226:	fdc40593          	addi	a1,s0,-36
    8000322a:	4501                	li	a0,0
    8000322c:	00000097          	auipc	ra,0x0
    80003230:	e78080e7          	jalr	-392(ra) # 800030a4 <argint>
    80003234:	87aa                	mv	a5,a0
    return -1;
    80003236:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003238:	0207c063          	bltz	a5,80003258 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000323c:	fffff097          	auipc	ra,0xfffff
    80003240:	afe080e7          	jalr	-1282(ra) # 80001d3a <myproc>
    80003244:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003246:	fdc42503          	lw	a0,-36(s0)
    8000324a:	fffff097          	auipc	ra,0xfffff
    8000324e:	f04080e7          	jalr	-252(ra) # 8000214e <growproc>
    80003252:	00054863          	bltz	a0,80003262 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003256:	8526                	mv	a0,s1
}
    80003258:	70a2                	ld	ra,40(sp)
    8000325a:	7402                	ld	s0,32(sp)
    8000325c:	64e2                	ld	s1,24(sp)
    8000325e:	6145                	addi	sp,sp,48
    80003260:	8082                	ret
    return -1;
    80003262:	557d                	li	a0,-1
    80003264:	bfd5                	j	80003258 <sys_sbrk+0x3c>

0000000080003266 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003266:	7139                	addi	sp,sp,-64
    80003268:	fc06                	sd	ra,56(sp)
    8000326a:	f822                	sd	s0,48(sp)
    8000326c:	f426                	sd	s1,40(sp)
    8000326e:	f04a                	sd	s2,32(sp)
    80003270:	ec4e                	sd	s3,24(sp)
    80003272:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003274:	fcc40593          	addi	a1,s0,-52
    80003278:	4501                	li	a0,0
    8000327a:	00000097          	auipc	ra,0x0
    8000327e:	e2a080e7          	jalr	-470(ra) # 800030a4 <argint>
    return -1;
    80003282:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003284:	06054563          	bltz	a0,800032ee <sys_sleep+0x88>
  acquire(&tickslock);
    80003288:	00015517          	auipc	a0,0x15
    8000328c:	98850513          	addi	a0,a0,-1656 # 80017c10 <tickslock>
    80003290:	ffffe097          	auipc	ra,0xffffe
    80003294:	954080e7          	jalr	-1708(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003298:	00006917          	auipc	s2,0x6
    8000329c:	d9892903          	lw	s2,-616(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800032a0:	fcc42783          	lw	a5,-52(s0)
    800032a4:	cf85                	beqz	a5,800032dc <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800032a6:	00015997          	auipc	s3,0x15
    800032aa:	96a98993          	addi	s3,s3,-1686 # 80017c10 <tickslock>
    800032ae:	00006497          	auipc	s1,0x6
    800032b2:	d8248493          	addi	s1,s1,-638 # 80009030 <ticks>
    if(myproc()->killed){
    800032b6:	fffff097          	auipc	ra,0xfffff
    800032ba:	a84080e7          	jalr	-1404(ra) # 80001d3a <myproc>
    800032be:	551c                	lw	a5,40(a0)
    800032c0:	ef9d                	bnez	a5,800032fe <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800032c2:	85ce                	mv	a1,s3
    800032c4:	8526                	mv	a0,s1
    800032c6:	fffff097          	auipc	ra,0xfffff
    800032ca:	272080e7          	jalr	626(ra) # 80002538 <sleep>
  while(ticks - ticks0 < n){
    800032ce:	409c                	lw	a5,0(s1)
    800032d0:	412787bb          	subw	a5,a5,s2
    800032d4:	fcc42703          	lw	a4,-52(s0)
    800032d8:	fce7efe3          	bltu	a5,a4,800032b6 <sys_sleep+0x50>
  }
  release(&tickslock);
    800032dc:	00015517          	auipc	a0,0x15
    800032e0:	93450513          	addi	a0,a0,-1740 # 80017c10 <tickslock>
    800032e4:	ffffe097          	auipc	ra,0xffffe
    800032e8:	9b4080e7          	jalr	-1612(ra) # 80000c98 <release>
  return 0;
    800032ec:	4781                	li	a5,0
}
    800032ee:	853e                	mv	a0,a5
    800032f0:	70e2                	ld	ra,56(sp)
    800032f2:	7442                	ld	s0,48(sp)
    800032f4:	74a2                	ld	s1,40(sp)
    800032f6:	7902                	ld	s2,32(sp)
    800032f8:	69e2                	ld	s3,24(sp)
    800032fa:	6121                	addi	sp,sp,64
    800032fc:	8082                	ret
      release(&tickslock);
    800032fe:	00015517          	auipc	a0,0x15
    80003302:	91250513          	addi	a0,a0,-1774 # 80017c10 <tickslock>
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	992080e7          	jalr	-1646(ra) # 80000c98 <release>
      return -1;
    8000330e:	57fd                	li	a5,-1
    80003310:	bff9                	j	800032ee <sys_sleep+0x88>

0000000080003312 <sys_kill>:

uint64
sys_kill(void)
{
    80003312:	1101                	addi	sp,sp,-32
    80003314:	ec06                	sd	ra,24(sp)
    80003316:	e822                	sd	s0,16(sp)
    80003318:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000331a:	fec40593          	addi	a1,s0,-20
    8000331e:	4501                	li	a0,0
    80003320:	00000097          	auipc	ra,0x0
    80003324:	d84080e7          	jalr	-636(ra) # 800030a4 <argint>
    80003328:	87aa                	mv	a5,a0
    return -1;
    8000332a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000332c:	0007c863          	bltz	a5,8000333c <sys_kill+0x2a>
  return kill(pid);
    80003330:	fec42503          	lw	a0,-20(s0)
    80003334:	fffff097          	auipc	ra,0xfffff
    80003338:	5c6080e7          	jalr	1478(ra) # 800028fa <kill>
}
    8000333c:	60e2                	ld	ra,24(sp)
    8000333e:	6442                	ld	s0,16(sp)
    80003340:	6105                	addi	sp,sp,32
    80003342:	8082                	ret

0000000080003344 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003344:	1101                	addi	sp,sp,-32
    80003346:	ec06                	sd	ra,24(sp)
    80003348:	e822                	sd	s0,16(sp)
    8000334a:	e426                	sd	s1,8(sp)
    8000334c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000334e:	00015517          	auipc	a0,0x15
    80003352:	8c250513          	addi	a0,a0,-1854 # 80017c10 <tickslock>
    80003356:	ffffe097          	auipc	ra,0xffffe
    8000335a:	88e080e7          	jalr	-1906(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000335e:	00006497          	auipc	s1,0x6
    80003362:	cd24a483          	lw	s1,-814(s1) # 80009030 <ticks>
  release(&tickslock);
    80003366:	00015517          	auipc	a0,0x15
    8000336a:	8aa50513          	addi	a0,a0,-1878 # 80017c10 <tickslock>
    8000336e:	ffffe097          	auipc	ra,0xffffe
    80003372:	92a080e7          	jalr	-1750(ra) # 80000c98 <release>
  return xticks;
}
    80003376:	02049513          	slli	a0,s1,0x20
    8000337a:	9101                	srli	a0,a0,0x20
    8000337c:	60e2                	ld	ra,24(sp)
    8000337e:	6442                	ld	s0,16(sp)
    80003380:	64a2                	ld	s1,8(sp)
    80003382:	6105                	addi	sp,sp,32
    80003384:	8082                	ret

0000000080003386 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003386:	7179                	addi	sp,sp,-48
    80003388:	f406                	sd	ra,40(sp)
    8000338a:	f022                	sd	s0,32(sp)
    8000338c:	ec26                	sd	s1,24(sp)
    8000338e:	e84a                	sd	s2,16(sp)
    80003390:	e44e                	sd	s3,8(sp)
    80003392:	e052                	sd	s4,0(sp)
    80003394:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003396:	00005597          	auipc	a1,0x5
    8000339a:	1ea58593          	addi	a1,a1,490 # 80008580 <syscalls+0xb0>
    8000339e:	00015517          	auipc	a0,0x15
    800033a2:	88a50513          	addi	a0,a0,-1910 # 80017c28 <bcache>
    800033a6:	ffffd097          	auipc	ra,0xffffd
    800033aa:	7ae080e7          	jalr	1966(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033ae:	0001d797          	auipc	a5,0x1d
    800033b2:	87a78793          	addi	a5,a5,-1926 # 8001fc28 <bcache+0x8000>
    800033b6:	0001d717          	auipc	a4,0x1d
    800033ba:	ada70713          	addi	a4,a4,-1318 # 8001fe90 <bcache+0x8268>
    800033be:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800033c2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033c6:	00015497          	auipc	s1,0x15
    800033ca:	87a48493          	addi	s1,s1,-1926 # 80017c40 <bcache+0x18>
    b->next = bcache.head.next;
    800033ce:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033d0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033d2:	00005a17          	auipc	s4,0x5
    800033d6:	1b6a0a13          	addi	s4,s4,438 # 80008588 <syscalls+0xb8>
    b->next = bcache.head.next;
    800033da:	2b893783          	ld	a5,696(s2)
    800033de:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800033e0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800033e4:	85d2                	mv	a1,s4
    800033e6:	01048513          	addi	a0,s1,16
    800033ea:	00001097          	auipc	ra,0x1
    800033ee:	4bc080e7          	jalr	1212(ra) # 800048a6 <initsleeplock>
    bcache.head.next->prev = b;
    800033f2:	2b893783          	ld	a5,696(s2)
    800033f6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033f8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033fc:	45848493          	addi	s1,s1,1112
    80003400:	fd349de3          	bne	s1,s3,800033da <binit+0x54>
  }
}
    80003404:	70a2                	ld	ra,40(sp)
    80003406:	7402                	ld	s0,32(sp)
    80003408:	64e2                	ld	s1,24(sp)
    8000340a:	6942                	ld	s2,16(sp)
    8000340c:	69a2                	ld	s3,8(sp)
    8000340e:	6a02                	ld	s4,0(sp)
    80003410:	6145                	addi	sp,sp,48
    80003412:	8082                	ret

0000000080003414 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003414:	7179                	addi	sp,sp,-48
    80003416:	f406                	sd	ra,40(sp)
    80003418:	f022                	sd	s0,32(sp)
    8000341a:	ec26                	sd	s1,24(sp)
    8000341c:	e84a                	sd	s2,16(sp)
    8000341e:	e44e                	sd	s3,8(sp)
    80003420:	1800                	addi	s0,sp,48
    80003422:	89aa                	mv	s3,a0
    80003424:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003426:	00015517          	auipc	a0,0x15
    8000342a:	80250513          	addi	a0,a0,-2046 # 80017c28 <bcache>
    8000342e:	ffffd097          	auipc	ra,0xffffd
    80003432:	7b6080e7          	jalr	1974(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003436:	0001d497          	auipc	s1,0x1d
    8000343a:	aaa4b483          	ld	s1,-1366(s1) # 8001fee0 <bcache+0x82b8>
    8000343e:	0001d797          	auipc	a5,0x1d
    80003442:	a5278793          	addi	a5,a5,-1454 # 8001fe90 <bcache+0x8268>
    80003446:	02f48f63          	beq	s1,a5,80003484 <bread+0x70>
    8000344a:	873e                	mv	a4,a5
    8000344c:	a021                	j	80003454 <bread+0x40>
    8000344e:	68a4                	ld	s1,80(s1)
    80003450:	02e48a63          	beq	s1,a4,80003484 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003454:	449c                	lw	a5,8(s1)
    80003456:	ff379ce3          	bne	a5,s3,8000344e <bread+0x3a>
    8000345a:	44dc                	lw	a5,12(s1)
    8000345c:	ff2799e3          	bne	a5,s2,8000344e <bread+0x3a>
      b->refcnt++;
    80003460:	40bc                	lw	a5,64(s1)
    80003462:	2785                	addiw	a5,a5,1
    80003464:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003466:	00014517          	auipc	a0,0x14
    8000346a:	7c250513          	addi	a0,a0,1986 # 80017c28 <bcache>
    8000346e:	ffffe097          	auipc	ra,0xffffe
    80003472:	82a080e7          	jalr	-2006(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003476:	01048513          	addi	a0,s1,16
    8000347a:	00001097          	auipc	ra,0x1
    8000347e:	466080e7          	jalr	1126(ra) # 800048e0 <acquiresleep>
      return b;
    80003482:	a8b9                	j	800034e0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003484:	0001d497          	auipc	s1,0x1d
    80003488:	a544b483          	ld	s1,-1452(s1) # 8001fed8 <bcache+0x82b0>
    8000348c:	0001d797          	auipc	a5,0x1d
    80003490:	a0478793          	addi	a5,a5,-1532 # 8001fe90 <bcache+0x8268>
    80003494:	00f48863          	beq	s1,a5,800034a4 <bread+0x90>
    80003498:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000349a:	40bc                	lw	a5,64(s1)
    8000349c:	cf81                	beqz	a5,800034b4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000349e:	64a4                	ld	s1,72(s1)
    800034a0:	fee49de3          	bne	s1,a4,8000349a <bread+0x86>
  panic("bget: no buffers");
    800034a4:	00005517          	auipc	a0,0x5
    800034a8:	0ec50513          	addi	a0,a0,236 # 80008590 <syscalls+0xc0>
    800034ac:	ffffd097          	auipc	ra,0xffffd
    800034b0:	092080e7          	jalr	146(ra) # 8000053e <panic>
      b->dev = dev;
    800034b4:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800034b8:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800034bc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800034c0:	4785                	li	a5,1
    800034c2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034c4:	00014517          	auipc	a0,0x14
    800034c8:	76450513          	addi	a0,a0,1892 # 80017c28 <bcache>
    800034cc:	ffffd097          	auipc	ra,0xffffd
    800034d0:	7cc080e7          	jalr	1996(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800034d4:	01048513          	addi	a0,s1,16
    800034d8:	00001097          	auipc	ra,0x1
    800034dc:	408080e7          	jalr	1032(ra) # 800048e0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800034e0:	409c                	lw	a5,0(s1)
    800034e2:	cb89                	beqz	a5,800034f4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800034e4:	8526                	mv	a0,s1
    800034e6:	70a2                	ld	ra,40(sp)
    800034e8:	7402                	ld	s0,32(sp)
    800034ea:	64e2                	ld	s1,24(sp)
    800034ec:	6942                	ld	s2,16(sp)
    800034ee:	69a2                	ld	s3,8(sp)
    800034f0:	6145                	addi	sp,sp,48
    800034f2:	8082                	ret
    virtio_disk_rw(b, 0);
    800034f4:	4581                	li	a1,0
    800034f6:	8526                	mv	a0,s1
    800034f8:	00003097          	auipc	ra,0x3
    800034fc:	f0e080e7          	jalr	-242(ra) # 80006406 <virtio_disk_rw>
    b->valid = 1;
    80003500:	4785                	li	a5,1
    80003502:	c09c                	sw	a5,0(s1)
  return b;
    80003504:	b7c5                	j	800034e4 <bread+0xd0>

0000000080003506 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003506:	1101                	addi	sp,sp,-32
    80003508:	ec06                	sd	ra,24(sp)
    8000350a:	e822                	sd	s0,16(sp)
    8000350c:	e426                	sd	s1,8(sp)
    8000350e:	1000                	addi	s0,sp,32
    80003510:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003512:	0541                	addi	a0,a0,16
    80003514:	00001097          	auipc	ra,0x1
    80003518:	466080e7          	jalr	1126(ra) # 8000497a <holdingsleep>
    8000351c:	cd01                	beqz	a0,80003534 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000351e:	4585                	li	a1,1
    80003520:	8526                	mv	a0,s1
    80003522:	00003097          	auipc	ra,0x3
    80003526:	ee4080e7          	jalr	-284(ra) # 80006406 <virtio_disk_rw>
}
    8000352a:	60e2                	ld	ra,24(sp)
    8000352c:	6442                	ld	s0,16(sp)
    8000352e:	64a2                	ld	s1,8(sp)
    80003530:	6105                	addi	sp,sp,32
    80003532:	8082                	ret
    panic("bwrite");
    80003534:	00005517          	auipc	a0,0x5
    80003538:	07450513          	addi	a0,a0,116 # 800085a8 <syscalls+0xd8>
    8000353c:	ffffd097          	auipc	ra,0xffffd
    80003540:	002080e7          	jalr	2(ra) # 8000053e <panic>

0000000080003544 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003544:	1101                	addi	sp,sp,-32
    80003546:	ec06                	sd	ra,24(sp)
    80003548:	e822                	sd	s0,16(sp)
    8000354a:	e426                	sd	s1,8(sp)
    8000354c:	e04a                	sd	s2,0(sp)
    8000354e:	1000                	addi	s0,sp,32
    80003550:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003552:	01050913          	addi	s2,a0,16
    80003556:	854a                	mv	a0,s2
    80003558:	00001097          	auipc	ra,0x1
    8000355c:	422080e7          	jalr	1058(ra) # 8000497a <holdingsleep>
    80003560:	c92d                	beqz	a0,800035d2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003562:	854a                	mv	a0,s2
    80003564:	00001097          	auipc	ra,0x1
    80003568:	3d2080e7          	jalr	978(ra) # 80004936 <releasesleep>

  acquire(&bcache.lock);
    8000356c:	00014517          	auipc	a0,0x14
    80003570:	6bc50513          	addi	a0,a0,1724 # 80017c28 <bcache>
    80003574:	ffffd097          	auipc	ra,0xffffd
    80003578:	670080e7          	jalr	1648(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000357c:	40bc                	lw	a5,64(s1)
    8000357e:	37fd                	addiw	a5,a5,-1
    80003580:	0007871b          	sext.w	a4,a5
    80003584:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003586:	eb05                	bnez	a4,800035b6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003588:	68bc                	ld	a5,80(s1)
    8000358a:	64b8                	ld	a4,72(s1)
    8000358c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000358e:	64bc                	ld	a5,72(s1)
    80003590:	68b8                	ld	a4,80(s1)
    80003592:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003594:	0001c797          	auipc	a5,0x1c
    80003598:	69478793          	addi	a5,a5,1684 # 8001fc28 <bcache+0x8000>
    8000359c:	2b87b703          	ld	a4,696(a5)
    800035a0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800035a2:	0001d717          	auipc	a4,0x1d
    800035a6:	8ee70713          	addi	a4,a4,-1810 # 8001fe90 <bcache+0x8268>
    800035aa:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035ac:	2b87b703          	ld	a4,696(a5)
    800035b0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800035b2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800035b6:	00014517          	auipc	a0,0x14
    800035ba:	67250513          	addi	a0,a0,1650 # 80017c28 <bcache>
    800035be:	ffffd097          	auipc	ra,0xffffd
    800035c2:	6da080e7          	jalr	1754(ra) # 80000c98 <release>
}
    800035c6:	60e2                	ld	ra,24(sp)
    800035c8:	6442                	ld	s0,16(sp)
    800035ca:	64a2                	ld	s1,8(sp)
    800035cc:	6902                	ld	s2,0(sp)
    800035ce:	6105                	addi	sp,sp,32
    800035d0:	8082                	ret
    panic("brelse");
    800035d2:	00005517          	auipc	a0,0x5
    800035d6:	fde50513          	addi	a0,a0,-34 # 800085b0 <syscalls+0xe0>
    800035da:	ffffd097          	auipc	ra,0xffffd
    800035de:	f64080e7          	jalr	-156(ra) # 8000053e <panic>

00000000800035e2 <bpin>:

void
bpin(struct buf *b) {
    800035e2:	1101                	addi	sp,sp,-32
    800035e4:	ec06                	sd	ra,24(sp)
    800035e6:	e822                	sd	s0,16(sp)
    800035e8:	e426                	sd	s1,8(sp)
    800035ea:	1000                	addi	s0,sp,32
    800035ec:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035ee:	00014517          	auipc	a0,0x14
    800035f2:	63a50513          	addi	a0,a0,1594 # 80017c28 <bcache>
    800035f6:	ffffd097          	auipc	ra,0xffffd
    800035fa:	5ee080e7          	jalr	1518(ra) # 80000be4 <acquire>
  b->refcnt++;
    800035fe:	40bc                	lw	a5,64(s1)
    80003600:	2785                	addiw	a5,a5,1
    80003602:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003604:	00014517          	auipc	a0,0x14
    80003608:	62450513          	addi	a0,a0,1572 # 80017c28 <bcache>
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	68c080e7          	jalr	1676(ra) # 80000c98 <release>
}
    80003614:	60e2                	ld	ra,24(sp)
    80003616:	6442                	ld	s0,16(sp)
    80003618:	64a2                	ld	s1,8(sp)
    8000361a:	6105                	addi	sp,sp,32
    8000361c:	8082                	ret

000000008000361e <bunpin>:

void
bunpin(struct buf *b) {
    8000361e:	1101                	addi	sp,sp,-32
    80003620:	ec06                	sd	ra,24(sp)
    80003622:	e822                	sd	s0,16(sp)
    80003624:	e426                	sd	s1,8(sp)
    80003626:	1000                	addi	s0,sp,32
    80003628:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000362a:	00014517          	auipc	a0,0x14
    8000362e:	5fe50513          	addi	a0,a0,1534 # 80017c28 <bcache>
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	5b2080e7          	jalr	1458(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000363a:	40bc                	lw	a5,64(s1)
    8000363c:	37fd                	addiw	a5,a5,-1
    8000363e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003640:	00014517          	auipc	a0,0x14
    80003644:	5e850513          	addi	a0,a0,1512 # 80017c28 <bcache>
    80003648:	ffffd097          	auipc	ra,0xffffd
    8000364c:	650080e7          	jalr	1616(ra) # 80000c98 <release>
}
    80003650:	60e2                	ld	ra,24(sp)
    80003652:	6442                	ld	s0,16(sp)
    80003654:	64a2                	ld	s1,8(sp)
    80003656:	6105                	addi	sp,sp,32
    80003658:	8082                	ret

000000008000365a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000365a:	1101                	addi	sp,sp,-32
    8000365c:	ec06                	sd	ra,24(sp)
    8000365e:	e822                	sd	s0,16(sp)
    80003660:	e426                	sd	s1,8(sp)
    80003662:	e04a                	sd	s2,0(sp)
    80003664:	1000                	addi	s0,sp,32
    80003666:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003668:	00d5d59b          	srliw	a1,a1,0xd
    8000366c:	0001d797          	auipc	a5,0x1d
    80003670:	c987a783          	lw	a5,-872(a5) # 80020304 <sb+0x1c>
    80003674:	9dbd                	addw	a1,a1,a5
    80003676:	00000097          	auipc	ra,0x0
    8000367a:	d9e080e7          	jalr	-610(ra) # 80003414 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000367e:	0074f713          	andi	a4,s1,7
    80003682:	4785                	li	a5,1
    80003684:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003688:	14ce                	slli	s1,s1,0x33
    8000368a:	90d9                	srli	s1,s1,0x36
    8000368c:	00950733          	add	a4,a0,s1
    80003690:	05874703          	lbu	a4,88(a4)
    80003694:	00e7f6b3          	and	a3,a5,a4
    80003698:	c69d                	beqz	a3,800036c6 <bfree+0x6c>
    8000369a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000369c:	94aa                	add	s1,s1,a0
    8000369e:	fff7c793          	not	a5,a5
    800036a2:	8ff9                	and	a5,a5,a4
    800036a4:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800036a8:	00001097          	auipc	ra,0x1
    800036ac:	118080e7          	jalr	280(ra) # 800047c0 <log_write>
  brelse(bp);
    800036b0:	854a                	mv	a0,s2
    800036b2:	00000097          	auipc	ra,0x0
    800036b6:	e92080e7          	jalr	-366(ra) # 80003544 <brelse>
}
    800036ba:	60e2                	ld	ra,24(sp)
    800036bc:	6442                	ld	s0,16(sp)
    800036be:	64a2                	ld	s1,8(sp)
    800036c0:	6902                	ld	s2,0(sp)
    800036c2:	6105                	addi	sp,sp,32
    800036c4:	8082                	ret
    panic("freeing free block");
    800036c6:	00005517          	auipc	a0,0x5
    800036ca:	ef250513          	addi	a0,a0,-270 # 800085b8 <syscalls+0xe8>
    800036ce:	ffffd097          	auipc	ra,0xffffd
    800036d2:	e70080e7          	jalr	-400(ra) # 8000053e <panic>

00000000800036d6 <balloc>:
{
    800036d6:	711d                	addi	sp,sp,-96
    800036d8:	ec86                	sd	ra,88(sp)
    800036da:	e8a2                	sd	s0,80(sp)
    800036dc:	e4a6                	sd	s1,72(sp)
    800036de:	e0ca                	sd	s2,64(sp)
    800036e0:	fc4e                	sd	s3,56(sp)
    800036e2:	f852                	sd	s4,48(sp)
    800036e4:	f456                	sd	s5,40(sp)
    800036e6:	f05a                	sd	s6,32(sp)
    800036e8:	ec5e                	sd	s7,24(sp)
    800036ea:	e862                	sd	s8,16(sp)
    800036ec:	e466                	sd	s9,8(sp)
    800036ee:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800036f0:	0001d797          	auipc	a5,0x1d
    800036f4:	bfc7a783          	lw	a5,-1028(a5) # 800202ec <sb+0x4>
    800036f8:	cbd1                	beqz	a5,8000378c <balloc+0xb6>
    800036fa:	8baa                	mv	s7,a0
    800036fc:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036fe:	0001db17          	auipc	s6,0x1d
    80003702:	beab0b13          	addi	s6,s6,-1046 # 800202e8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003706:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003708:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000370a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000370c:	6c89                	lui	s9,0x2
    8000370e:	a831                	j	8000372a <balloc+0x54>
    brelse(bp);
    80003710:	854a                	mv	a0,s2
    80003712:	00000097          	auipc	ra,0x0
    80003716:	e32080e7          	jalr	-462(ra) # 80003544 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000371a:	015c87bb          	addw	a5,s9,s5
    8000371e:	00078a9b          	sext.w	s5,a5
    80003722:	004b2703          	lw	a4,4(s6)
    80003726:	06eaf363          	bgeu	s5,a4,8000378c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000372a:	41fad79b          	sraiw	a5,s5,0x1f
    8000372e:	0137d79b          	srliw	a5,a5,0x13
    80003732:	015787bb          	addw	a5,a5,s5
    80003736:	40d7d79b          	sraiw	a5,a5,0xd
    8000373a:	01cb2583          	lw	a1,28(s6)
    8000373e:	9dbd                	addw	a1,a1,a5
    80003740:	855e                	mv	a0,s7
    80003742:	00000097          	auipc	ra,0x0
    80003746:	cd2080e7          	jalr	-814(ra) # 80003414 <bread>
    8000374a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000374c:	004b2503          	lw	a0,4(s6)
    80003750:	000a849b          	sext.w	s1,s5
    80003754:	8662                	mv	a2,s8
    80003756:	faa4fde3          	bgeu	s1,a0,80003710 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000375a:	41f6579b          	sraiw	a5,a2,0x1f
    8000375e:	01d7d69b          	srliw	a3,a5,0x1d
    80003762:	00c6873b          	addw	a4,a3,a2
    80003766:	00777793          	andi	a5,a4,7
    8000376a:	9f95                	subw	a5,a5,a3
    8000376c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003770:	4037571b          	sraiw	a4,a4,0x3
    80003774:	00e906b3          	add	a3,s2,a4
    80003778:	0586c683          	lbu	a3,88(a3)
    8000377c:	00d7f5b3          	and	a1,a5,a3
    80003780:	cd91                	beqz	a1,8000379c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003782:	2605                	addiw	a2,a2,1
    80003784:	2485                	addiw	s1,s1,1
    80003786:	fd4618e3          	bne	a2,s4,80003756 <balloc+0x80>
    8000378a:	b759                	j	80003710 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000378c:	00005517          	auipc	a0,0x5
    80003790:	e4450513          	addi	a0,a0,-444 # 800085d0 <syscalls+0x100>
    80003794:	ffffd097          	auipc	ra,0xffffd
    80003798:	daa080e7          	jalr	-598(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000379c:	974a                	add	a4,a4,s2
    8000379e:	8fd5                	or	a5,a5,a3
    800037a0:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800037a4:	854a                	mv	a0,s2
    800037a6:	00001097          	auipc	ra,0x1
    800037aa:	01a080e7          	jalr	26(ra) # 800047c0 <log_write>
        brelse(bp);
    800037ae:	854a                	mv	a0,s2
    800037b0:	00000097          	auipc	ra,0x0
    800037b4:	d94080e7          	jalr	-620(ra) # 80003544 <brelse>
  bp = bread(dev, bno);
    800037b8:	85a6                	mv	a1,s1
    800037ba:	855e                	mv	a0,s7
    800037bc:	00000097          	auipc	ra,0x0
    800037c0:	c58080e7          	jalr	-936(ra) # 80003414 <bread>
    800037c4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800037c6:	40000613          	li	a2,1024
    800037ca:	4581                	li	a1,0
    800037cc:	05850513          	addi	a0,a0,88
    800037d0:	ffffd097          	auipc	ra,0xffffd
    800037d4:	510080e7          	jalr	1296(ra) # 80000ce0 <memset>
  log_write(bp);
    800037d8:	854a                	mv	a0,s2
    800037da:	00001097          	auipc	ra,0x1
    800037de:	fe6080e7          	jalr	-26(ra) # 800047c0 <log_write>
  brelse(bp);
    800037e2:	854a                	mv	a0,s2
    800037e4:	00000097          	auipc	ra,0x0
    800037e8:	d60080e7          	jalr	-672(ra) # 80003544 <brelse>
}
    800037ec:	8526                	mv	a0,s1
    800037ee:	60e6                	ld	ra,88(sp)
    800037f0:	6446                	ld	s0,80(sp)
    800037f2:	64a6                	ld	s1,72(sp)
    800037f4:	6906                	ld	s2,64(sp)
    800037f6:	79e2                	ld	s3,56(sp)
    800037f8:	7a42                	ld	s4,48(sp)
    800037fa:	7aa2                	ld	s5,40(sp)
    800037fc:	7b02                	ld	s6,32(sp)
    800037fe:	6be2                	ld	s7,24(sp)
    80003800:	6c42                	ld	s8,16(sp)
    80003802:	6ca2                	ld	s9,8(sp)
    80003804:	6125                	addi	sp,sp,96
    80003806:	8082                	ret

0000000080003808 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003808:	7179                	addi	sp,sp,-48
    8000380a:	f406                	sd	ra,40(sp)
    8000380c:	f022                	sd	s0,32(sp)
    8000380e:	ec26                	sd	s1,24(sp)
    80003810:	e84a                	sd	s2,16(sp)
    80003812:	e44e                	sd	s3,8(sp)
    80003814:	e052                	sd	s4,0(sp)
    80003816:	1800                	addi	s0,sp,48
    80003818:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000381a:	47ad                	li	a5,11
    8000381c:	04b7fe63          	bgeu	a5,a1,80003878 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003820:	ff45849b          	addiw	s1,a1,-12
    80003824:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003828:	0ff00793          	li	a5,255
    8000382c:	0ae7e363          	bltu	a5,a4,800038d2 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003830:	08052583          	lw	a1,128(a0)
    80003834:	c5ad                	beqz	a1,8000389e <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003836:	00092503          	lw	a0,0(s2)
    8000383a:	00000097          	auipc	ra,0x0
    8000383e:	bda080e7          	jalr	-1062(ra) # 80003414 <bread>
    80003842:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003844:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003848:	02049593          	slli	a1,s1,0x20
    8000384c:	9181                	srli	a1,a1,0x20
    8000384e:	058a                	slli	a1,a1,0x2
    80003850:	00b784b3          	add	s1,a5,a1
    80003854:	0004a983          	lw	s3,0(s1)
    80003858:	04098d63          	beqz	s3,800038b2 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000385c:	8552                	mv	a0,s4
    8000385e:	00000097          	auipc	ra,0x0
    80003862:	ce6080e7          	jalr	-794(ra) # 80003544 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003866:	854e                	mv	a0,s3
    80003868:	70a2                	ld	ra,40(sp)
    8000386a:	7402                	ld	s0,32(sp)
    8000386c:	64e2                	ld	s1,24(sp)
    8000386e:	6942                	ld	s2,16(sp)
    80003870:	69a2                	ld	s3,8(sp)
    80003872:	6a02                	ld	s4,0(sp)
    80003874:	6145                	addi	sp,sp,48
    80003876:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003878:	02059493          	slli	s1,a1,0x20
    8000387c:	9081                	srli	s1,s1,0x20
    8000387e:	048a                	slli	s1,s1,0x2
    80003880:	94aa                	add	s1,s1,a0
    80003882:	0504a983          	lw	s3,80(s1)
    80003886:	fe0990e3          	bnez	s3,80003866 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000388a:	4108                	lw	a0,0(a0)
    8000388c:	00000097          	auipc	ra,0x0
    80003890:	e4a080e7          	jalr	-438(ra) # 800036d6 <balloc>
    80003894:	0005099b          	sext.w	s3,a0
    80003898:	0534a823          	sw	s3,80(s1)
    8000389c:	b7e9                	j	80003866 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000389e:	4108                	lw	a0,0(a0)
    800038a0:	00000097          	auipc	ra,0x0
    800038a4:	e36080e7          	jalr	-458(ra) # 800036d6 <balloc>
    800038a8:	0005059b          	sext.w	a1,a0
    800038ac:	08b92023          	sw	a1,128(s2)
    800038b0:	b759                	j	80003836 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800038b2:	00092503          	lw	a0,0(s2)
    800038b6:	00000097          	auipc	ra,0x0
    800038ba:	e20080e7          	jalr	-480(ra) # 800036d6 <balloc>
    800038be:	0005099b          	sext.w	s3,a0
    800038c2:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800038c6:	8552                	mv	a0,s4
    800038c8:	00001097          	auipc	ra,0x1
    800038cc:	ef8080e7          	jalr	-264(ra) # 800047c0 <log_write>
    800038d0:	b771                	j	8000385c <bmap+0x54>
  panic("bmap: out of range");
    800038d2:	00005517          	auipc	a0,0x5
    800038d6:	d1650513          	addi	a0,a0,-746 # 800085e8 <syscalls+0x118>
    800038da:	ffffd097          	auipc	ra,0xffffd
    800038de:	c64080e7          	jalr	-924(ra) # 8000053e <panic>

00000000800038e2 <iget>:
{
    800038e2:	7179                	addi	sp,sp,-48
    800038e4:	f406                	sd	ra,40(sp)
    800038e6:	f022                	sd	s0,32(sp)
    800038e8:	ec26                	sd	s1,24(sp)
    800038ea:	e84a                	sd	s2,16(sp)
    800038ec:	e44e                	sd	s3,8(sp)
    800038ee:	e052                	sd	s4,0(sp)
    800038f0:	1800                	addi	s0,sp,48
    800038f2:	89aa                	mv	s3,a0
    800038f4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800038f6:	0001d517          	auipc	a0,0x1d
    800038fa:	a1250513          	addi	a0,a0,-1518 # 80020308 <itable>
    800038fe:	ffffd097          	auipc	ra,0xffffd
    80003902:	2e6080e7          	jalr	742(ra) # 80000be4 <acquire>
  empty = 0;
    80003906:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003908:	0001d497          	auipc	s1,0x1d
    8000390c:	a1848493          	addi	s1,s1,-1512 # 80020320 <itable+0x18>
    80003910:	0001e697          	auipc	a3,0x1e
    80003914:	4a068693          	addi	a3,a3,1184 # 80021db0 <log>
    80003918:	a039                	j	80003926 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000391a:	02090b63          	beqz	s2,80003950 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000391e:	08848493          	addi	s1,s1,136
    80003922:	02d48a63          	beq	s1,a3,80003956 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003926:	449c                	lw	a5,8(s1)
    80003928:	fef059e3          	blez	a5,8000391a <iget+0x38>
    8000392c:	4098                	lw	a4,0(s1)
    8000392e:	ff3716e3          	bne	a4,s3,8000391a <iget+0x38>
    80003932:	40d8                	lw	a4,4(s1)
    80003934:	ff4713e3          	bne	a4,s4,8000391a <iget+0x38>
      ip->ref++;
    80003938:	2785                	addiw	a5,a5,1
    8000393a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000393c:	0001d517          	auipc	a0,0x1d
    80003940:	9cc50513          	addi	a0,a0,-1588 # 80020308 <itable>
    80003944:	ffffd097          	auipc	ra,0xffffd
    80003948:	354080e7          	jalr	852(ra) # 80000c98 <release>
      return ip;
    8000394c:	8926                	mv	s2,s1
    8000394e:	a03d                	j	8000397c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003950:	f7f9                	bnez	a5,8000391e <iget+0x3c>
    80003952:	8926                	mv	s2,s1
    80003954:	b7e9                	j	8000391e <iget+0x3c>
  if(empty == 0)
    80003956:	02090c63          	beqz	s2,8000398e <iget+0xac>
  ip->dev = dev;
    8000395a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000395e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003962:	4785                	li	a5,1
    80003964:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003968:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000396c:	0001d517          	auipc	a0,0x1d
    80003970:	99c50513          	addi	a0,a0,-1636 # 80020308 <itable>
    80003974:	ffffd097          	auipc	ra,0xffffd
    80003978:	324080e7          	jalr	804(ra) # 80000c98 <release>
}
    8000397c:	854a                	mv	a0,s2
    8000397e:	70a2                	ld	ra,40(sp)
    80003980:	7402                	ld	s0,32(sp)
    80003982:	64e2                	ld	s1,24(sp)
    80003984:	6942                	ld	s2,16(sp)
    80003986:	69a2                	ld	s3,8(sp)
    80003988:	6a02                	ld	s4,0(sp)
    8000398a:	6145                	addi	sp,sp,48
    8000398c:	8082                	ret
    panic("iget: no inodes");
    8000398e:	00005517          	auipc	a0,0x5
    80003992:	c7250513          	addi	a0,a0,-910 # 80008600 <syscalls+0x130>
    80003996:	ffffd097          	auipc	ra,0xffffd
    8000399a:	ba8080e7          	jalr	-1112(ra) # 8000053e <panic>

000000008000399e <fsinit>:
fsinit(int dev) {
    8000399e:	7179                	addi	sp,sp,-48
    800039a0:	f406                	sd	ra,40(sp)
    800039a2:	f022                	sd	s0,32(sp)
    800039a4:	ec26                	sd	s1,24(sp)
    800039a6:	e84a                	sd	s2,16(sp)
    800039a8:	e44e                	sd	s3,8(sp)
    800039aa:	1800                	addi	s0,sp,48
    800039ac:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039ae:	4585                	li	a1,1
    800039b0:	00000097          	auipc	ra,0x0
    800039b4:	a64080e7          	jalr	-1436(ra) # 80003414 <bread>
    800039b8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800039ba:	0001d997          	auipc	s3,0x1d
    800039be:	92e98993          	addi	s3,s3,-1746 # 800202e8 <sb>
    800039c2:	02000613          	li	a2,32
    800039c6:	05850593          	addi	a1,a0,88
    800039ca:	854e                	mv	a0,s3
    800039cc:	ffffd097          	auipc	ra,0xffffd
    800039d0:	374080e7          	jalr	884(ra) # 80000d40 <memmove>
  brelse(bp);
    800039d4:	8526                	mv	a0,s1
    800039d6:	00000097          	auipc	ra,0x0
    800039da:	b6e080e7          	jalr	-1170(ra) # 80003544 <brelse>
  if(sb.magic != FSMAGIC)
    800039de:	0009a703          	lw	a4,0(s3)
    800039e2:	102037b7          	lui	a5,0x10203
    800039e6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800039ea:	02f71263          	bne	a4,a5,80003a0e <fsinit+0x70>
  initlog(dev, &sb);
    800039ee:	0001d597          	auipc	a1,0x1d
    800039f2:	8fa58593          	addi	a1,a1,-1798 # 800202e8 <sb>
    800039f6:	854a                	mv	a0,s2
    800039f8:	00001097          	auipc	ra,0x1
    800039fc:	b4c080e7          	jalr	-1204(ra) # 80004544 <initlog>
}
    80003a00:	70a2                	ld	ra,40(sp)
    80003a02:	7402                	ld	s0,32(sp)
    80003a04:	64e2                	ld	s1,24(sp)
    80003a06:	6942                	ld	s2,16(sp)
    80003a08:	69a2                	ld	s3,8(sp)
    80003a0a:	6145                	addi	sp,sp,48
    80003a0c:	8082                	ret
    panic("invalid file system");
    80003a0e:	00005517          	auipc	a0,0x5
    80003a12:	c0250513          	addi	a0,a0,-1022 # 80008610 <syscalls+0x140>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	b28080e7          	jalr	-1240(ra) # 8000053e <panic>

0000000080003a1e <iinit>:
{
    80003a1e:	7179                	addi	sp,sp,-48
    80003a20:	f406                	sd	ra,40(sp)
    80003a22:	f022                	sd	s0,32(sp)
    80003a24:	ec26                	sd	s1,24(sp)
    80003a26:	e84a                	sd	s2,16(sp)
    80003a28:	e44e                	sd	s3,8(sp)
    80003a2a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a2c:	00005597          	auipc	a1,0x5
    80003a30:	bfc58593          	addi	a1,a1,-1028 # 80008628 <syscalls+0x158>
    80003a34:	0001d517          	auipc	a0,0x1d
    80003a38:	8d450513          	addi	a0,a0,-1836 # 80020308 <itable>
    80003a3c:	ffffd097          	auipc	ra,0xffffd
    80003a40:	118080e7          	jalr	280(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a44:	0001d497          	auipc	s1,0x1d
    80003a48:	8ec48493          	addi	s1,s1,-1812 # 80020330 <itable+0x28>
    80003a4c:	0001e997          	auipc	s3,0x1e
    80003a50:	37498993          	addi	s3,s3,884 # 80021dc0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a54:	00005917          	auipc	s2,0x5
    80003a58:	bdc90913          	addi	s2,s2,-1060 # 80008630 <syscalls+0x160>
    80003a5c:	85ca                	mv	a1,s2
    80003a5e:	8526                	mv	a0,s1
    80003a60:	00001097          	auipc	ra,0x1
    80003a64:	e46080e7          	jalr	-442(ra) # 800048a6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a68:	08848493          	addi	s1,s1,136
    80003a6c:	ff3498e3          	bne	s1,s3,80003a5c <iinit+0x3e>
}
    80003a70:	70a2                	ld	ra,40(sp)
    80003a72:	7402                	ld	s0,32(sp)
    80003a74:	64e2                	ld	s1,24(sp)
    80003a76:	6942                	ld	s2,16(sp)
    80003a78:	69a2                	ld	s3,8(sp)
    80003a7a:	6145                	addi	sp,sp,48
    80003a7c:	8082                	ret

0000000080003a7e <ialloc>:
{
    80003a7e:	715d                	addi	sp,sp,-80
    80003a80:	e486                	sd	ra,72(sp)
    80003a82:	e0a2                	sd	s0,64(sp)
    80003a84:	fc26                	sd	s1,56(sp)
    80003a86:	f84a                	sd	s2,48(sp)
    80003a88:	f44e                	sd	s3,40(sp)
    80003a8a:	f052                	sd	s4,32(sp)
    80003a8c:	ec56                	sd	s5,24(sp)
    80003a8e:	e85a                	sd	s6,16(sp)
    80003a90:	e45e                	sd	s7,8(sp)
    80003a92:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a94:	0001d717          	auipc	a4,0x1d
    80003a98:	86072703          	lw	a4,-1952(a4) # 800202f4 <sb+0xc>
    80003a9c:	4785                	li	a5,1
    80003a9e:	04e7fa63          	bgeu	a5,a4,80003af2 <ialloc+0x74>
    80003aa2:	8aaa                	mv	s5,a0
    80003aa4:	8bae                	mv	s7,a1
    80003aa6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003aa8:	0001da17          	auipc	s4,0x1d
    80003aac:	840a0a13          	addi	s4,s4,-1984 # 800202e8 <sb>
    80003ab0:	00048b1b          	sext.w	s6,s1
    80003ab4:	0044d593          	srli	a1,s1,0x4
    80003ab8:	018a2783          	lw	a5,24(s4)
    80003abc:	9dbd                	addw	a1,a1,a5
    80003abe:	8556                	mv	a0,s5
    80003ac0:	00000097          	auipc	ra,0x0
    80003ac4:	954080e7          	jalr	-1708(ra) # 80003414 <bread>
    80003ac8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003aca:	05850993          	addi	s3,a0,88
    80003ace:	00f4f793          	andi	a5,s1,15
    80003ad2:	079a                	slli	a5,a5,0x6
    80003ad4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003ad6:	00099783          	lh	a5,0(s3)
    80003ada:	c785                	beqz	a5,80003b02 <ialloc+0x84>
    brelse(bp);
    80003adc:	00000097          	auipc	ra,0x0
    80003ae0:	a68080e7          	jalr	-1432(ra) # 80003544 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ae4:	0485                	addi	s1,s1,1
    80003ae6:	00ca2703          	lw	a4,12(s4)
    80003aea:	0004879b          	sext.w	a5,s1
    80003aee:	fce7e1e3          	bltu	a5,a4,80003ab0 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003af2:	00005517          	auipc	a0,0x5
    80003af6:	b4650513          	addi	a0,a0,-1210 # 80008638 <syscalls+0x168>
    80003afa:	ffffd097          	auipc	ra,0xffffd
    80003afe:	a44080e7          	jalr	-1468(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003b02:	04000613          	li	a2,64
    80003b06:	4581                	li	a1,0
    80003b08:	854e                	mv	a0,s3
    80003b0a:	ffffd097          	auipc	ra,0xffffd
    80003b0e:	1d6080e7          	jalr	470(ra) # 80000ce0 <memset>
      dip->type = type;
    80003b12:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b16:	854a                	mv	a0,s2
    80003b18:	00001097          	auipc	ra,0x1
    80003b1c:	ca8080e7          	jalr	-856(ra) # 800047c0 <log_write>
      brelse(bp);
    80003b20:	854a                	mv	a0,s2
    80003b22:	00000097          	auipc	ra,0x0
    80003b26:	a22080e7          	jalr	-1502(ra) # 80003544 <brelse>
      return iget(dev, inum);
    80003b2a:	85da                	mv	a1,s6
    80003b2c:	8556                	mv	a0,s5
    80003b2e:	00000097          	auipc	ra,0x0
    80003b32:	db4080e7          	jalr	-588(ra) # 800038e2 <iget>
}
    80003b36:	60a6                	ld	ra,72(sp)
    80003b38:	6406                	ld	s0,64(sp)
    80003b3a:	74e2                	ld	s1,56(sp)
    80003b3c:	7942                	ld	s2,48(sp)
    80003b3e:	79a2                	ld	s3,40(sp)
    80003b40:	7a02                	ld	s4,32(sp)
    80003b42:	6ae2                	ld	s5,24(sp)
    80003b44:	6b42                	ld	s6,16(sp)
    80003b46:	6ba2                	ld	s7,8(sp)
    80003b48:	6161                	addi	sp,sp,80
    80003b4a:	8082                	ret

0000000080003b4c <iupdate>:
{
    80003b4c:	1101                	addi	sp,sp,-32
    80003b4e:	ec06                	sd	ra,24(sp)
    80003b50:	e822                	sd	s0,16(sp)
    80003b52:	e426                	sd	s1,8(sp)
    80003b54:	e04a                	sd	s2,0(sp)
    80003b56:	1000                	addi	s0,sp,32
    80003b58:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b5a:	415c                	lw	a5,4(a0)
    80003b5c:	0047d79b          	srliw	a5,a5,0x4
    80003b60:	0001c597          	auipc	a1,0x1c
    80003b64:	7a05a583          	lw	a1,1952(a1) # 80020300 <sb+0x18>
    80003b68:	9dbd                	addw	a1,a1,a5
    80003b6a:	4108                	lw	a0,0(a0)
    80003b6c:	00000097          	auipc	ra,0x0
    80003b70:	8a8080e7          	jalr	-1880(ra) # 80003414 <bread>
    80003b74:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b76:	05850793          	addi	a5,a0,88
    80003b7a:	40c8                	lw	a0,4(s1)
    80003b7c:	893d                	andi	a0,a0,15
    80003b7e:	051a                	slli	a0,a0,0x6
    80003b80:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003b82:	04449703          	lh	a4,68(s1)
    80003b86:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b8a:	04649703          	lh	a4,70(s1)
    80003b8e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003b92:	04849703          	lh	a4,72(s1)
    80003b96:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b9a:	04a49703          	lh	a4,74(s1)
    80003b9e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003ba2:	44f8                	lw	a4,76(s1)
    80003ba4:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003ba6:	03400613          	li	a2,52
    80003baa:	05048593          	addi	a1,s1,80
    80003bae:	0531                	addi	a0,a0,12
    80003bb0:	ffffd097          	auipc	ra,0xffffd
    80003bb4:	190080e7          	jalr	400(ra) # 80000d40 <memmove>
  log_write(bp);
    80003bb8:	854a                	mv	a0,s2
    80003bba:	00001097          	auipc	ra,0x1
    80003bbe:	c06080e7          	jalr	-1018(ra) # 800047c0 <log_write>
  brelse(bp);
    80003bc2:	854a                	mv	a0,s2
    80003bc4:	00000097          	auipc	ra,0x0
    80003bc8:	980080e7          	jalr	-1664(ra) # 80003544 <brelse>
}
    80003bcc:	60e2                	ld	ra,24(sp)
    80003bce:	6442                	ld	s0,16(sp)
    80003bd0:	64a2                	ld	s1,8(sp)
    80003bd2:	6902                	ld	s2,0(sp)
    80003bd4:	6105                	addi	sp,sp,32
    80003bd6:	8082                	ret

0000000080003bd8 <idup>:
{
    80003bd8:	1101                	addi	sp,sp,-32
    80003bda:	ec06                	sd	ra,24(sp)
    80003bdc:	e822                	sd	s0,16(sp)
    80003bde:	e426                	sd	s1,8(sp)
    80003be0:	1000                	addi	s0,sp,32
    80003be2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003be4:	0001c517          	auipc	a0,0x1c
    80003be8:	72450513          	addi	a0,a0,1828 # 80020308 <itable>
    80003bec:	ffffd097          	auipc	ra,0xffffd
    80003bf0:	ff8080e7          	jalr	-8(ra) # 80000be4 <acquire>
  ip->ref++;
    80003bf4:	449c                	lw	a5,8(s1)
    80003bf6:	2785                	addiw	a5,a5,1
    80003bf8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bfa:	0001c517          	auipc	a0,0x1c
    80003bfe:	70e50513          	addi	a0,a0,1806 # 80020308 <itable>
    80003c02:	ffffd097          	auipc	ra,0xffffd
    80003c06:	096080e7          	jalr	150(ra) # 80000c98 <release>
}
    80003c0a:	8526                	mv	a0,s1
    80003c0c:	60e2                	ld	ra,24(sp)
    80003c0e:	6442                	ld	s0,16(sp)
    80003c10:	64a2                	ld	s1,8(sp)
    80003c12:	6105                	addi	sp,sp,32
    80003c14:	8082                	ret

0000000080003c16 <ilock>:
{
    80003c16:	1101                	addi	sp,sp,-32
    80003c18:	ec06                	sd	ra,24(sp)
    80003c1a:	e822                	sd	s0,16(sp)
    80003c1c:	e426                	sd	s1,8(sp)
    80003c1e:	e04a                	sd	s2,0(sp)
    80003c20:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c22:	c115                	beqz	a0,80003c46 <ilock+0x30>
    80003c24:	84aa                	mv	s1,a0
    80003c26:	451c                	lw	a5,8(a0)
    80003c28:	00f05f63          	blez	a5,80003c46 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c2c:	0541                	addi	a0,a0,16
    80003c2e:	00001097          	auipc	ra,0x1
    80003c32:	cb2080e7          	jalr	-846(ra) # 800048e0 <acquiresleep>
  if(ip->valid == 0){
    80003c36:	40bc                	lw	a5,64(s1)
    80003c38:	cf99                	beqz	a5,80003c56 <ilock+0x40>
}
    80003c3a:	60e2                	ld	ra,24(sp)
    80003c3c:	6442                	ld	s0,16(sp)
    80003c3e:	64a2                	ld	s1,8(sp)
    80003c40:	6902                	ld	s2,0(sp)
    80003c42:	6105                	addi	sp,sp,32
    80003c44:	8082                	ret
    panic("ilock");
    80003c46:	00005517          	auipc	a0,0x5
    80003c4a:	a0a50513          	addi	a0,a0,-1526 # 80008650 <syscalls+0x180>
    80003c4e:	ffffd097          	auipc	ra,0xffffd
    80003c52:	8f0080e7          	jalr	-1808(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c56:	40dc                	lw	a5,4(s1)
    80003c58:	0047d79b          	srliw	a5,a5,0x4
    80003c5c:	0001c597          	auipc	a1,0x1c
    80003c60:	6a45a583          	lw	a1,1700(a1) # 80020300 <sb+0x18>
    80003c64:	9dbd                	addw	a1,a1,a5
    80003c66:	4088                	lw	a0,0(s1)
    80003c68:	fffff097          	auipc	ra,0xfffff
    80003c6c:	7ac080e7          	jalr	1964(ra) # 80003414 <bread>
    80003c70:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c72:	05850593          	addi	a1,a0,88
    80003c76:	40dc                	lw	a5,4(s1)
    80003c78:	8bbd                	andi	a5,a5,15
    80003c7a:	079a                	slli	a5,a5,0x6
    80003c7c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c7e:	00059783          	lh	a5,0(a1)
    80003c82:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c86:	00259783          	lh	a5,2(a1)
    80003c8a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c8e:	00459783          	lh	a5,4(a1)
    80003c92:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c96:	00659783          	lh	a5,6(a1)
    80003c9a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c9e:	459c                	lw	a5,8(a1)
    80003ca0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ca2:	03400613          	li	a2,52
    80003ca6:	05b1                	addi	a1,a1,12
    80003ca8:	05048513          	addi	a0,s1,80
    80003cac:	ffffd097          	auipc	ra,0xffffd
    80003cb0:	094080e7          	jalr	148(ra) # 80000d40 <memmove>
    brelse(bp);
    80003cb4:	854a                	mv	a0,s2
    80003cb6:	00000097          	auipc	ra,0x0
    80003cba:	88e080e7          	jalr	-1906(ra) # 80003544 <brelse>
    ip->valid = 1;
    80003cbe:	4785                	li	a5,1
    80003cc0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003cc2:	04449783          	lh	a5,68(s1)
    80003cc6:	fbb5                	bnez	a5,80003c3a <ilock+0x24>
      panic("ilock: no type");
    80003cc8:	00005517          	auipc	a0,0x5
    80003ccc:	99050513          	addi	a0,a0,-1648 # 80008658 <syscalls+0x188>
    80003cd0:	ffffd097          	auipc	ra,0xffffd
    80003cd4:	86e080e7          	jalr	-1938(ra) # 8000053e <panic>

0000000080003cd8 <iunlock>:
{
    80003cd8:	1101                	addi	sp,sp,-32
    80003cda:	ec06                	sd	ra,24(sp)
    80003cdc:	e822                	sd	s0,16(sp)
    80003cde:	e426                	sd	s1,8(sp)
    80003ce0:	e04a                	sd	s2,0(sp)
    80003ce2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ce4:	c905                	beqz	a0,80003d14 <iunlock+0x3c>
    80003ce6:	84aa                	mv	s1,a0
    80003ce8:	01050913          	addi	s2,a0,16
    80003cec:	854a                	mv	a0,s2
    80003cee:	00001097          	auipc	ra,0x1
    80003cf2:	c8c080e7          	jalr	-884(ra) # 8000497a <holdingsleep>
    80003cf6:	cd19                	beqz	a0,80003d14 <iunlock+0x3c>
    80003cf8:	449c                	lw	a5,8(s1)
    80003cfa:	00f05d63          	blez	a5,80003d14 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003cfe:	854a                	mv	a0,s2
    80003d00:	00001097          	auipc	ra,0x1
    80003d04:	c36080e7          	jalr	-970(ra) # 80004936 <releasesleep>
}
    80003d08:	60e2                	ld	ra,24(sp)
    80003d0a:	6442                	ld	s0,16(sp)
    80003d0c:	64a2                	ld	s1,8(sp)
    80003d0e:	6902                	ld	s2,0(sp)
    80003d10:	6105                	addi	sp,sp,32
    80003d12:	8082                	ret
    panic("iunlock");
    80003d14:	00005517          	auipc	a0,0x5
    80003d18:	95450513          	addi	a0,a0,-1708 # 80008668 <syscalls+0x198>
    80003d1c:	ffffd097          	auipc	ra,0xffffd
    80003d20:	822080e7          	jalr	-2014(ra) # 8000053e <panic>

0000000080003d24 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d24:	7179                	addi	sp,sp,-48
    80003d26:	f406                	sd	ra,40(sp)
    80003d28:	f022                	sd	s0,32(sp)
    80003d2a:	ec26                	sd	s1,24(sp)
    80003d2c:	e84a                	sd	s2,16(sp)
    80003d2e:	e44e                	sd	s3,8(sp)
    80003d30:	e052                	sd	s4,0(sp)
    80003d32:	1800                	addi	s0,sp,48
    80003d34:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d36:	05050493          	addi	s1,a0,80
    80003d3a:	08050913          	addi	s2,a0,128
    80003d3e:	a021                	j	80003d46 <itrunc+0x22>
    80003d40:	0491                	addi	s1,s1,4
    80003d42:	01248d63          	beq	s1,s2,80003d5c <itrunc+0x38>
    if(ip->addrs[i]){
    80003d46:	408c                	lw	a1,0(s1)
    80003d48:	dde5                	beqz	a1,80003d40 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d4a:	0009a503          	lw	a0,0(s3)
    80003d4e:	00000097          	auipc	ra,0x0
    80003d52:	90c080e7          	jalr	-1780(ra) # 8000365a <bfree>
      ip->addrs[i] = 0;
    80003d56:	0004a023          	sw	zero,0(s1)
    80003d5a:	b7dd                	j	80003d40 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d5c:	0809a583          	lw	a1,128(s3)
    80003d60:	e185                	bnez	a1,80003d80 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d62:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d66:	854e                	mv	a0,s3
    80003d68:	00000097          	auipc	ra,0x0
    80003d6c:	de4080e7          	jalr	-540(ra) # 80003b4c <iupdate>
}
    80003d70:	70a2                	ld	ra,40(sp)
    80003d72:	7402                	ld	s0,32(sp)
    80003d74:	64e2                	ld	s1,24(sp)
    80003d76:	6942                	ld	s2,16(sp)
    80003d78:	69a2                	ld	s3,8(sp)
    80003d7a:	6a02                	ld	s4,0(sp)
    80003d7c:	6145                	addi	sp,sp,48
    80003d7e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d80:	0009a503          	lw	a0,0(s3)
    80003d84:	fffff097          	auipc	ra,0xfffff
    80003d88:	690080e7          	jalr	1680(ra) # 80003414 <bread>
    80003d8c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d8e:	05850493          	addi	s1,a0,88
    80003d92:	45850913          	addi	s2,a0,1112
    80003d96:	a811                	j	80003daa <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003d98:	0009a503          	lw	a0,0(s3)
    80003d9c:	00000097          	auipc	ra,0x0
    80003da0:	8be080e7          	jalr	-1858(ra) # 8000365a <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003da4:	0491                	addi	s1,s1,4
    80003da6:	01248563          	beq	s1,s2,80003db0 <itrunc+0x8c>
      if(a[j])
    80003daa:	408c                	lw	a1,0(s1)
    80003dac:	dde5                	beqz	a1,80003da4 <itrunc+0x80>
    80003dae:	b7ed                	j	80003d98 <itrunc+0x74>
    brelse(bp);
    80003db0:	8552                	mv	a0,s4
    80003db2:	fffff097          	auipc	ra,0xfffff
    80003db6:	792080e7          	jalr	1938(ra) # 80003544 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003dba:	0809a583          	lw	a1,128(s3)
    80003dbe:	0009a503          	lw	a0,0(s3)
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	898080e7          	jalr	-1896(ra) # 8000365a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003dca:	0809a023          	sw	zero,128(s3)
    80003dce:	bf51                	j	80003d62 <itrunc+0x3e>

0000000080003dd0 <iput>:
{
    80003dd0:	1101                	addi	sp,sp,-32
    80003dd2:	ec06                	sd	ra,24(sp)
    80003dd4:	e822                	sd	s0,16(sp)
    80003dd6:	e426                	sd	s1,8(sp)
    80003dd8:	e04a                	sd	s2,0(sp)
    80003dda:	1000                	addi	s0,sp,32
    80003ddc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003dde:	0001c517          	auipc	a0,0x1c
    80003de2:	52a50513          	addi	a0,a0,1322 # 80020308 <itable>
    80003de6:	ffffd097          	auipc	ra,0xffffd
    80003dea:	dfe080e7          	jalr	-514(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dee:	4498                	lw	a4,8(s1)
    80003df0:	4785                	li	a5,1
    80003df2:	02f70363          	beq	a4,a5,80003e18 <iput+0x48>
  ip->ref--;
    80003df6:	449c                	lw	a5,8(s1)
    80003df8:	37fd                	addiw	a5,a5,-1
    80003dfa:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dfc:	0001c517          	auipc	a0,0x1c
    80003e00:	50c50513          	addi	a0,a0,1292 # 80020308 <itable>
    80003e04:	ffffd097          	auipc	ra,0xffffd
    80003e08:	e94080e7          	jalr	-364(ra) # 80000c98 <release>
}
    80003e0c:	60e2                	ld	ra,24(sp)
    80003e0e:	6442                	ld	s0,16(sp)
    80003e10:	64a2                	ld	s1,8(sp)
    80003e12:	6902                	ld	s2,0(sp)
    80003e14:	6105                	addi	sp,sp,32
    80003e16:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e18:	40bc                	lw	a5,64(s1)
    80003e1a:	dff1                	beqz	a5,80003df6 <iput+0x26>
    80003e1c:	04a49783          	lh	a5,74(s1)
    80003e20:	fbf9                	bnez	a5,80003df6 <iput+0x26>
    acquiresleep(&ip->lock);
    80003e22:	01048913          	addi	s2,s1,16
    80003e26:	854a                	mv	a0,s2
    80003e28:	00001097          	auipc	ra,0x1
    80003e2c:	ab8080e7          	jalr	-1352(ra) # 800048e0 <acquiresleep>
    release(&itable.lock);
    80003e30:	0001c517          	auipc	a0,0x1c
    80003e34:	4d850513          	addi	a0,a0,1240 # 80020308 <itable>
    80003e38:	ffffd097          	auipc	ra,0xffffd
    80003e3c:	e60080e7          	jalr	-416(ra) # 80000c98 <release>
    itrunc(ip);
    80003e40:	8526                	mv	a0,s1
    80003e42:	00000097          	auipc	ra,0x0
    80003e46:	ee2080e7          	jalr	-286(ra) # 80003d24 <itrunc>
    ip->type = 0;
    80003e4a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e4e:	8526                	mv	a0,s1
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	cfc080e7          	jalr	-772(ra) # 80003b4c <iupdate>
    ip->valid = 0;
    80003e58:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e5c:	854a                	mv	a0,s2
    80003e5e:	00001097          	auipc	ra,0x1
    80003e62:	ad8080e7          	jalr	-1320(ra) # 80004936 <releasesleep>
    acquire(&itable.lock);
    80003e66:	0001c517          	auipc	a0,0x1c
    80003e6a:	4a250513          	addi	a0,a0,1186 # 80020308 <itable>
    80003e6e:	ffffd097          	auipc	ra,0xffffd
    80003e72:	d76080e7          	jalr	-650(ra) # 80000be4 <acquire>
    80003e76:	b741                	j	80003df6 <iput+0x26>

0000000080003e78 <iunlockput>:
{
    80003e78:	1101                	addi	sp,sp,-32
    80003e7a:	ec06                	sd	ra,24(sp)
    80003e7c:	e822                	sd	s0,16(sp)
    80003e7e:	e426                	sd	s1,8(sp)
    80003e80:	1000                	addi	s0,sp,32
    80003e82:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e84:	00000097          	auipc	ra,0x0
    80003e88:	e54080e7          	jalr	-428(ra) # 80003cd8 <iunlock>
  iput(ip);
    80003e8c:	8526                	mv	a0,s1
    80003e8e:	00000097          	auipc	ra,0x0
    80003e92:	f42080e7          	jalr	-190(ra) # 80003dd0 <iput>
}
    80003e96:	60e2                	ld	ra,24(sp)
    80003e98:	6442                	ld	s0,16(sp)
    80003e9a:	64a2                	ld	s1,8(sp)
    80003e9c:	6105                	addi	sp,sp,32
    80003e9e:	8082                	ret

0000000080003ea0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ea0:	1141                	addi	sp,sp,-16
    80003ea2:	e422                	sd	s0,8(sp)
    80003ea4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ea6:	411c                	lw	a5,0(a0)
    80003ea8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003eaa:	415c                	lw	a5,4(a0)
    80003eac:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003eae:	04451783          	lh	a5,68(a0)
    80003eb2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003eb6:	04a51783          	lh	a5,74(a0)
    80003eba:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ebe:	04c56783          	lwu	a5,76(a0)
    80003ec2:	e99c                	sd	a5,16(a1)
}
    80003ec4:	6422                	ld	s0,8(sp)
    80003ec6:	0141                	addi	sp,sp,16
    80003ec8:	8082                	ret

0000000080003eca <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003eca:	457c                	lw	a5,76(a0)
    80003ecc:	0ed7e963          	bltu	a5,a3,80003fbe <readi+0xf4>
{
    80003ed0:	7159                	addi	sp,sp,-112
    80003ed2:	f486                	sd	ra,104(sp)
    80003ed4:	f0a2                	sd	s0,96(sp)
    80003ed6:	eca6                	sd	s1,88(sp)
    80003ed8:	e8ca                	sd	s2,80(sp)
    80003eda:	e4ce                	sd	s3,72(sp)
    80003edc:	e0d2                	sd	s4,64(sp)
    80003ede:	fc56                	sd	s5,56(sp)
    80003ee0:	f85a                	sd	s6,48(sp)
    80003ee2:	f45e                	sd	s7,40(sp)
    80003ee4:	f062                	sd	s8,32(sp)
    80003ee6:	ec66                	sd	s9,24(sp)
    80003ee8:	e86a                	sd	s10,16(sp)
    80003eea:	e46e                	sd	s11,8(sp)
    80003eec:	1880                	addi	s0,sp,112
    80003eee:	8baa                	mv	s7,a0
    80003ef0:	8c2e                	mv	s8,a1
    80003ef2:	8ab2                	mv	s5,a2
    80003ef4:	84b6                	mv	s1,a3
    80003ef6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ef8:	9f35                	addw	a4,a4,a3
    return 0;
    80003efa:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003efc:	0ad76063          	bltu	a4,a3,80003f9c <readi+0xd2>
  if(off + n > ip->size)
    80003f00:	00e7f463          	bgeu	a5,a4,80003f08 <readi+0x3e>
    n = ip->size - off;
    80003f04:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f08:	0a0b0963          	beqz	s6,80003fba <readi+0xf0>
    80003f0c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f0e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f12:	5cfd                	li	s9,-1
    80003f14:	a82d                	j	80003f4e <readi+0x84>
    80003f16:	020a1d93          	slli	s11,s4,0x20
    80003f1a:	020ddd93          	srli	s11,s11,0x20
    80003f1e:	05890613          	addi	a2,s2,88
    80003f22:	86ee                	mv	a3,s11
    80003f24:	963a                	add	a2,a2,a4
    80003f26:	85d6                	mv	a1,s5
    80003f28:	8562                	mv	a0,s8
    80003f2a:	fffff097          	auipc	ra,0xfffff
    80003f2e:	a42080e7          	jalr	-1470(ra) # 8000296c <either_copyout>
    80003f32:	05950d63          	beq	a0,s9,80003f8c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f36:	854a                	mv	a0,s2
    80003f38:	fffff097          	auipc	ra,0xfffff
    80003f3c:	60c080e7          	jalr	1548(ra) # 80003544 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f40:	013a09bb          	addw	s3,s4,s3
    80003f44:	009a04bb          	addw	s1,s4,s1
    80003f48:	9aee                	add	s5,s5,s11
    80003f4a:	0569f763          	bgeu	s3,s6,80003f98 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f4e:	000ba903          	lw	s2,0(s7)
    80003f52:	00a4d59b          	srliw	a1,s1,0xa
    80003f56:	855e                	mv	a0,s7
    80003f58:	00000097          	auipc	ra,0x0
    80003f5c:	8b0080e7          	jalr	-1872(ra) # 80003808 <bmap>
    80003f60:	0005059b          	sext.w	a1,a0
    80003f64:	854a                	mv	a0,s2
    80003f66:	fffff097          	auipc	ra,0xfffff
    80003f6a:	4ae080e7          	jalr	1198(ra) # 80003414 <bread>
    80003f6e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f70:	3ff4f713          	andi	a4,s1,1023
    80003f74:	40ed07bb          	subw	a5,s10,a4
    80003f78:	413b06bb          	subw	a3,s6,s3
    80003f7c:	8a3e                	mv	s4,a5
    80003f7e:	2781                	sext.w	a5,a5
    80003f80:	0006861b          	sext.w	a2,a3
    80003f84:	f8f679e3          	bgeu	a2,a5,80003f16 <readi+0x4c>
    80003f88:	8a36                	mv	s4,a3
    80003f8a:	b771                	j	80003f16 <readi+0x4c>
      brelse(bp);
    80003f8c:	854a                	mv	a0,s2
    80003f8e:	fffff097          	auipc	ra,0xfffff
    80003f92:	5b6080e7          	jalr	1462(ra) # 80003544 <brelse>
      tot = -1;
    80003f96:	59fd                	li	s3,-1
  }
  return tot;
    80003f98:	0009851b          	sext.w	a0,s3
}
    80003f9c:	70a6                	ld	ra,104(sp)
    80003f9e:	7406                	ld	s0,96(sp)
    80003fa0:	64e6                	ld	s1,88(sp)
    80003fa2:	6946                	ld	s2,80(sp)
    80003fa4:	69a6                	ld	s3,72(sp)
    80003fa6:	6a06                	ld	s4,64(sp)
    80003fa8:	7ae2                	ld	s5,56(sp)
    80003faa:	7b42                	ld	s6,48(sp)
    80003fac:	7ba2                	ld	s7,40(sp)
    80003fae:	7c02                	ld	s8,32(sp)
    80003fb0:	6ce2                	ld	s9,24(sp)
    80003fb2:	6d42                	ld	s10,16(sp)
    80003fb4:	6da2                	ld	s11,8(sp)
    80003fb6:	6165                	addi	sp,sp,112
    80003fb8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fba:	89da                	mv	s3,s6
    80003fbc:	bff1                	j	80003f98 <readi+0xce>
    return 0;
    80003fbe:	4501                	li	a0,0
}
    80003fc0:	8082                	ret

0000000080003fc2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fc2:	457c                	lw	a5,76(a0)
    80003fc4:	10d7e863          	bltu	a5,a3,800040d4 <writei+0x112>
{
    80003fc8:	7159                	addi	sp,sp,-112
    80003fca:	f486                	sd	ra,104(sp)
    80003fcc:	f0a2                	sd	s0,96(sp)
    80003fce:	eca6                	sd	s1,88(sp)
    80003fd0:	e8ca                	sd	s2,80(sp)
    80003fd2:	e4ce                	sd	s3,72(sp)
    80003fd4:	e0d2                	sd	s4,64(sp)
    80003fd6:	fc56                	sd	s5,56(sp)
    80003fd8:	f85a                	sd	s6,48(sp)
    80003fda:	f45e                	sd	s7,40(sp)
    80003fdc:	f062                	sd	s8,32(sp)
    80003fde:	ec66                	sd	s9,24(sp)
    80003fe0:	e86a                	sd	s10,16(sp)
    80003fe2:	e46e                	sd	s11,8(sp)
    80003fe4:	1880                	addi	s0,sp,112
    80003fe6:	8b2a                	mv	s6,a0
    80003fe8:	8c2e                	mv	s8,a1
    80003fea:	8ab2                	mv	s5,a2
    80003fec:	8936                	mv	s2,a3
    80003fee:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003ff0:	00e687bb          	addw	a5,a3,a4
    80003ff4:	0ed7e263          	bltu	a5,a3,800040d8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ff8:	00043737          	lui	a4,0x43
    80003ffc:	0ef76063          	bltu	a4,a5,800040dc <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004000:	0c0b8863          	beqz	s7,800040d0 <writei+0x10e>
    80004004:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004006:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000400a:	5cfd                	li	s9,-1
    8000400c:	a091                	j	80004050 <writei+0x8e>
    8000400e:	02099d93          	slli	s11,s3,0x20
    80004012:	020ddd93          	srli	s11,s11,0x20
    80004016:	05848513          	addi	a0,s1,88
    8000401a:	86ee                	mv	a3,s11
    8000401c:	8656                	mv	a2,s5
    8000401e:	85e2                	mv	a1,s8
    80004020:	953a                	add	a0,a0,a4
    80004022:	fffff097          	auipc	ra,0xfffff
    80004026:	9a0080e7          	jalr	-1632(ra) # 800029c2 <either_copyin>
    8000402a:	07950263          	beq	a0,s9,8000408e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000402e:	8526                	mv	a0,s1
    80004030:	00000097          	auipc	ra,0x0
    80004034:	790080e7          	jalr	1936(ra) # 800047c0 <log_write>
    brelse(bp);
    80004038:	8526                	mv	a0,s1
    8000403a:	fffff097          	auipc	ra,0xfffff
    8000403e:	50a080e7          	jalr	1290(ra) # 80003544 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004042:	01498a3b          	addw	s4,s3,s4
    80004046:	0129893b          	addw	s2,s3,s2
    8000404a:	9aee                	add	s5,s5,s11
    8000404c:	057a7663          	bgeu	s4,s7,80004098 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004050:	000b2483          	lw	s1,0(s6)
    80004054:	00a9559b          	srliw	a1,s2,0xa
    80004058:	855a                	mv	a0,s6
    8000405a:	fffff097          	auipc	ra,0xfffff
    8000405e:	7ae080e7          	jalr	1966(ra) # 80003808 <bmap>
    80004062:	0005059b          	sext.w	a1,a0
    80004066:	8526                	mv	a0,s1
    80004068:	fffff097          	auipc	ra,0xfffff
    8000406c:	3ac080e7          	jalr	940(ra) # 80003414 <bread>
    80004070:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004072:	3ff97713          	andi	a4,s2,1023
    80004076:	40ed07bb          	subw	a5,s10,a4
    8000407a:	414b86bb          	subw	a3,s7,s4
    8000407e:	89be                	mv	s3,a5
    80004080:	2781                	sext.w	a5,a5
    80004082:	0006861b          	sext.w	a2,a3
    80004086:	f8f674e3          	bgeu	a2,a5,8000400e <writei+0x4c>
    8000408a:	89b6                	mv	s3,a3
    8000408c:	b749                	j	8000400e <writei+0x4c>
      brelse(bp);
    8000408e:	8526                	mv	a0,s1
    80004090:	fffff097          	auipc	ra,0xfffff
    80004094:	4b4080e7          	jalr	1204(ra) # 80003544 <brelse>
  }

  if(off > ip->size)
    80004098:	04cb2783          	lw	a5,76(s6)
    8000409c:	0127f463          	bgeu	a5,s2,800040a4 <writei+0xe2>
    ip->size = off;
    800040a0:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800040a4:	855a                	mv	a0,s6
    800040a6:	00000097          	auipc	ra,0x0
    800040aa:	aa6080e7          	jalr	-1370(ra) # 80003b4c <iupdate>

  return tot;
    800040ae:	000a051b          	sext.w	a0,s4
}
    800040b2:	70a6                	ld	ra,104(sp)
    800040b4:	7406                	ld	s0,96(sp)
    800040b6:	64e6                	ld	s1,88(sp)
    800040b8:	6946                	ld	s2,80(sp)
    800040ba:	69a6                	ld	s3,72(sp)
    800040bc:	6a06                	ld	s4,64(sp)
    800040be:	7ae2                	ld	s5,56(sp)
    800040c0:	7b42                	ld	s6,48(sp)
    800040c2:	7ba2                	ld	s7,40(sp)
    800040c4:	7c02                	ld	s8,32(sp)
    800040c6:	6ce2                	ld	s9,24(sp)
    800040c8:	6d42                	ld	s10,16(sp)
    800040ca:	6da2                	ld	s11,8(sp)
    800040cc:	6165                	addi	sp,sp,112
    800040ce:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040d0:	8a5e                	mv	s4,s7
    800040d2:	bfc9                	j	800040a4 <writei+0xe2>
    return -1;
    800040d4:	557d                	li	a0,-1
}
    800040d6:	8082                	ret
    return -1;
    800040d8:	557d                	li	a0,-1
    800040da:	bfe1                	j	800040b2 <writei+0xf0>
    return -1;
    800040dc:	557d                	li	a0,-1
    800040de:	bfd1                	j	800040b2 <writei+0xf0>

00000000800040e0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800040e0:	1141                	addi	sp,sp,-16
    800040e2:	e406                	sd	ra,8(sp)
    800040e4:	e022                	sd	s0,0(sp)
    800040e6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800040e8:	4639                	li	a2,14
    800040ea:	ffffd097          	auipc	ra,0xffffd
    800040ee:	cce080e7          	jalr	-818(ra) # 80000db8 <strncmp>
}
    800040f2:	60a2                	ld	ra,8(sp)
    800040f4:	6402                	ld	s0,0(sp)
    800040f6:	0141                	addi	sp,sp,16
    800040f8:	8082                	ret

00000000800040fa <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800040fa:	7139                	addi	sp,sp,-64
    800040fc:	fc06                	sd	ra,56(sp)
    800040fe:	f822                	sd	s0,48(sp)
    80004100:	f426                	sd	s1,40(sp)
    80004102:	f04a                	sd	s2,32(sp)
    80004104:	ec4e                	sd	s3,24(sp)
    80004106:	e852                	sd	s4,16(sp)
    80004108:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000410a:	04451703          	lh	a4,68(a0)
    8000410e:	4785                	li	a5,1
    80004110:	00f71a63          	bne	a4,a5,80004124 <dirlookup+0x2a>
    80004114:	892a                	mv	s2,a0
    80004116:	89ae                	mv	s3,a1
    80004118:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000411a:	457c                	lw	a5,76(a0)
    8000411c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000411e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004120:	e79d                	bnez	a5,8000414e <dirlookup+0x54>
    80004122:	a8a5                	j	8000419a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004124:	00004517          	auipc	a0,0x4
    80004128:	54c50513          	addi	a0,a0,1356 # 80008670 <syscalls+0x1a0>
    8000412c:	ffffc097          	auipc	ra,0xffffc
    80004130:	412080e7          	jalr	1042(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004134:	00004517          	auipc	a0,0x4
    80004138:	55450513          	addi	a0,a0,1364 # 80008688 <syscalls+0x1b8>
    8000413c:	ffffc097          	auipc	ra,0xffffc
    80004140:	402080e7          	jalr	1026(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004144:	24c1                	addiw	s1,s1,16
    80004146:	04c92783          	lw	a5,76(s2)
    8000414a:	04f4f763          	bgeu	s1,a5,80004198 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000414e:	4741                	li	a4,16
    80004150:	86a6                	mv	a3,s1
    80004152:	fc040613          	addi	a2,s0,-64
    80004156:	4581                	li	a1,0
    80004158:	854a                	mv	a0,s2
    8000415a:	00000097          	auipc	ra,0x0
    8000415e:	d70080e7          	jalr	-656(ra) # 80003eca <readi>
    80004162:	47c1                	li	a5,16
    80004164:	fcf518e3          	bne	a0,a5,80004134 <dirlookup+0x3a>
    if(de.inum == 0)
    80004168:	fc045783          	lhu	a5,-64(s0)
    8000416c:	dfe1                	beqz	a5,80004144 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000416e:	fc240593          	addi	a1,s0,-62
    80004172:	854e                	mv	a0,s3
    80004174:	00000097          	auipc	ra,0x0
    80004178:	f6c080e7          	jalr	-148(ra) # 800040e0 <namecmp>
    8000417c:	f561                	bnez	a0,80004144 <dirlookup+0x4a>
      if(poff)
    8000417e:	000a0463          	beqz	s4,80004186 <dirlookup+0x8c>
        *poff = off;
    80004182:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004186:	fc045583          	lhu	a1,-64(s0)
    8000418a:	00092503          	lw	a0,0(s2)
    8000418e:	fffff097          	auipc	ra,0xfffff
    80004192:	754080e7          	jalr	1876(ra) # 800038e2 <iget>
    80004196:	a011                	j	8000419a <dirlookup+0xa0>
  return 0;
    80004198:	4501                	li	a0,0
}
    8000419a:	70e2                	ld	ra,56(sp)
    8000419c:	7442                	ld	s0,48(sp)
    8000419e:	74a2                	ld	s1,40(sp)
    800041a0:	7902                	ld	s2,32(sp)
    800041a2:	69e2                	ld	s3,24(sp)
    800041a4:	6a42                	ld	s4,16(sp)
    800041a6:	6121                	addi	sp,sp,64
    800041a8:	8082                	ret

00000000800041aa <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800041aa:	711d                	addi	sp,sp,-96
    800041ac:	ec86                	sd	ra,88(sp)
    800041ae:	e8a2                	sd	s0,80(sp)
    800041b0:	e4a6                	sd	s1,72(sp)
    800041b2:	e0ca                	sd	s2,64(sp)
    800041b4:	fc4e                	sd	s3,56(sp)
    800041b6:	f852                	sd	s4,48(sp)
    800041b8:	f456                	sd	s5,40(sp)
    800041ba:	f05a                	sd	s6,32(sp)
    800041bc:	ec5e                	sd	s7,24(sp)
    800041be:	e862                	sd	s8,16(sp)
    800041c0:	e466                	sd	s9,8(sp)
    800041c2:	1080                	addi	s0,sp,96
    800041c4:	84aa                	mv	s1,a0
    800041c6:	8b2e                	mv	s6,a1
    800041c8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041ca:	00054703          	lbu	a4,0(a0)
    800041ce:	02f00793          	li	a5,47
    800041d2:	02f70363          	beq	a4,a5,800041f8 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041d6:	ffffe097          	auipc	ra,0xffffe
    800041da:	b64080e7          	jalr	-1180(ra) # 80001d3a <myproc>
    800041de:	15053503          	ld	a0,336(a0)
    800041e2:	00000097          	auipc	ra,0x0
    800041e6:	9f6080e7          	jalr	-1546(ra) # 80003bd8 <idup>
    800041ea:	89aa                	mv	s3,a0
  while(*path == '/')
    800041ec:	02f00913          	li	s2,47
  len = path - s;
    800041f0:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800041f2:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800041f4:	4c05                	li	s8,1
    800041f6:	a865                	j	800042ae <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800041f8:	4585                	li	a1,1
    800041fa:	4505                	li	a0,1
    800041fc:	fffff097          	auipc	ra,0xfffff
    80004200:	6e6080e7          	jalr	1766(ra) # 800038e2 <iget>
    80004204:	89aa                	mv	s3,a0
    80004206:	b7dd                	j	800041ec <namex+0x42>
      iunlockput(ip);
    80004208:	854e                	mv	a0,s3
    8000420a:	00000097          	auipc	ra,0x0
    8000420e:	c6e080e7          	jalr	-914(ra) # 80003e78 <iunlockput>
      return 0;
    80004212:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004214:	854e                	mv	a0,s3
    80004216:	60e6                	ld	ra,88(sp)
    80004218:	6446                	ld	s0,80(sp)
    8000421a:	64a6                	ld	s1,72(sp)
    8000421c:	6906                	ld	s2,64(sp)
    8000421e:	79e2                	ld	s3,56(sp)
    80004220:	7a42                	ld	s4,48(sp)
    80004222:	7aa2                	ld	s5,40(sp)
    80004224:	7b02                	ld	s6,32(sp)
    80004226:	6be2                	ld	s7,24(sp)
    80004228:	6c42                	ld	s8,16(sp)
    8000422a:	6ca2                	ld	s9,8(sp)
    8000422c:	6125                	addi	sp,sp,96
    8000422e:	8082                	ret
      iunlock(ip);
    80004230:	854e                	mv	a0,s3
    80004232:	00000097          	auipc	ra,0x0
    80004236:	aa6080e7          	jalr	-1370(ra) # 80003cd8 <iunlock>
      return ip;
    8000423a:	bfe9                	j	80004214 <namex+0x6a>
      iunlockput(ip);
    8000423c:	854e                	mv	a0,s3
    8000423e:	00000097          	auipc	ra,0x0
    80004242:	c3a080e7          	jalr	-966(ra) # 80003e78 <iunlockput>
      return 0;
    80004246:	89d2                	mv	s3,s4
    80004248:	b7f1                	j	80004214 <namex+0x6a>
  len = path - s;
    8000424a:	40b48633          	sub	a2,s1,a1
    8000424e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004252:	094cd463          	bge	s9,s4,800042da <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004256:	4639                	li	a2,14
    80004258:	8556                	mv	a0,s5
    8000425a:	ffffd097          	auipc	ra,0xffffd
    8000425e:	ae6080e7          	jalr	-1306(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004262:	0004c783          	lbu	a5,0(s1)
    80004266:	01279763          	bne	a5,s2,80004274 <namex+0xca>
    path++;
    8000426a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000426c:	0004c783          	lbu	a5,0(s1)
    80004270:	ff278de3          	beq	a5,s2,8000426a <namex+0xc0>
    ilock(ip);
    80004274:	854e                	mv	a0,s3
    80004276:	00000097          	auipc	ra,0x0
    8000427a:	9a0080e7          	jalr	-1632(ra) # 80003c16 <ilock>
    if(ip->type != T_DIR){
    8000427e:	04499783          	lh	a5,68(s3)
    80004282:	f98793e3          	bne	a5,s8,80004208 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004286:	000b0563          	beqz	s6,80004290 <namex+0xe6>
    8000428a:	0004c783          	lbu	a5,0(s1)
    8000428e:	d3cd                	beqz	a5,80004230 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004290:	865e                	mv	a2,s7
    80004292:	85d6                	mv	a1,s5
    80004294:	854e                	mv	a0,s3
    80004296:	00000097          	auipc	ra,0x0
    8000429a:	e64080e7          	jalr	-412(ra) # 800040fa <dirlookup>
    8000429e:	8a2a                	mv	s4,a0
    800042a0:	dd51                	beqz	a0,8000423c <namex+0x92>
    iunlockput(ip);
    800042a2:	854e                	mv	a0,s3
    800042a4:	00000097          	auipc	ra,0x0
    800042a8:	bd4080e7          	jalr	-1068(ra) # 80003e78 <iunlockput>
    ip = next;
    800042ac:	89d2                	mv	s3,s4
  while(*path == '/')
    800042ae:	0004c783          	lbu	a5,0(s1)
    800042b2:	05279763          	bne	a5,s2,80004300 <namex+0x156>
    path++;
    800042b6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042b8:	0004c783          	lbu	a5,0(s1)
    800042bc:	ff278de3          	beq	a5,s2,800042b6 <namex+0x10c>
  if(*path == 0)
    800042c0:	c79d                	beqz	a5,800042ee <namex+0x144>
    path++;
    800042c2:	85a6                	mv	a1,s1
  len = path - s;
    800042c4:	8a5e                	mv	s4,s7
    800042c6:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800042c8:	01278963          	beq	a5,s2,800042da <namex+0x130>
    800042cc:	dfbd                	beqz	a5,8000424a <namex+0xa0>
    path++;
    800042ce:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800042d0:	0004c783          	lbu	a5,0(s1)
    800042d4:	ff279ce3          	bne	a5,s2,800042cc <namex+0x122>
    800042d8:	bf8d                	j	8000424a <namex+0xa0>
    memmove(name, s, len);
    800042da:	2601                	sext.w	a2,a2
    800042dc:	8556                	mv	a0,s5
    800042de:	ffffd097          	auipc	ra,0xffffd
    800042e2:	a62080e7          	jalr	-1438(ra) # 80000d40 <memmove>
    name[len] = 0;
    800042e6:	9a56                	add	s4,s4,s5
    800042e8:	000a0023          	sb	zero,0(s4)
    800042ec:	bf9d                	j	80004262 <namex+0xb8>
  if(nameiparent){
    800042ee:	f20b03e3          	beqz	s6,80004214 <namex+0x6a>
    iput(ip);
    800042f2:	854e                	mv	a0,s3
    800042f4:	00000097          	auipc	ra,0x0
    800042f8:	adc080e7          	jalr	-1316(ra) # 80003dd0 <iput>
    return 0;
    800042fc:	4981                	li	s3,0
    800042fe:	bf19                	j	80004214 <namex+0x6a>
  if(*path == 0)
    80004300:	d7fd                	beqz	a5,800042ee <namex+0x144>
  while(*path != '/' && *path != 0)
    80004302:	0004c783          	lbu	a5,0(s1)
    80004306:	85a6                	mv	a1,s1
    80004308:	b7d1                	j	800042cc <namex+0x122>

000000008000430a <dirlink>:
{
    8000430a:	7139                	addi	sp,sp,-64
    8000430c:	fc06                	sd	ra,56(sp)
    8000430e:	f822                	sd	s0,48(sp)
    80004310:	f426                	sd	s1,40(sp)
    80004312:	f04a                	sd	s2,32(sp)
    80004314:	ec4e                	sd	s3,24(sp)
    80004316:	e852                	sd	s4,16(sp)
    80004318:	0080                	addi	s0,sp,64
    8000431a:	892a                	mv	s2,a0
    8000431c:	8a2e                	mv	s4,a1
    8000431e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004320:	4601                	li	a2,0
    80004322:	00000097          	auipc	ra,0x0
    80004326:	dd8080e7          	jalr	-552(ra) # 800040fa <dirlookup>
    8000432a:	e93d                	bnez	a0,800043a0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000432c:	04c92483          	lw	s1,76(s2)
    80004330:	c49d                	beqz	s1,8000435e <dirlink+0x54>
    80004332:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004334:	4741                	li	a4,16
    80004336:	86a6                	mv	a3,s1
    80004338:	fc040613          	addi	a2,s0,-64
    8000433c:	4581                	li	a1,0
    8000433e:	854a                	mv	a0,s2
    80004340:	00000097          	auipc	ra,0x0
    80004344:	b8a080e7          	jalr	-1142(ra) # 80003eca <readi>
    80004348:	47c1                	li	a5,16
    8000434a:	06f51163          	bne	a0,a5,800043ac <dirlink+0xa2>
    if(de.inum == 0)
    8000434e:	fc045783          	lhu	a5,-64(s0)
    80004352:	c791                	beqz	a5,8000435e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004354:	24c1                	addiw	s1,s1,16
    80004356:	04c92783          	lw	a5,76(s2)
    8000435a:	fcf4ede3          	bltu	s1,a5,80004334 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000435e:	4639                	li	a2,14
    80004360:	85d2                	mv	a1,s4
    80004362:	fc240513          	addi	a0,s0,-62
    80004366:	ffffd097          	auipc	ra,0xffffd
    8000436a:	a8e080e7          	jalr	-1394(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000436e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004372:	4741                	li	a4,16
    80004374:	86a6                	mv	a3,s1
    80004376:	fc040613          	addi	a2,s0,-64
    8000437a:	4581                	li	a1,0
    8000437c:	854a                	mv	a0,s2
    8000437e:	00000097          	auipc	ra,0x0
    80004382:	c44080e7          	jalr	-956(ra) # 80003fc2 <writei>
    80004386:	872a                	mv	a4,a0
    80004388:	47c1                	li	a5,16
  return 0;
    8000438a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000438c:	02f71863          	bne	a4,a5,800043bc <dirlink+0xb2>
}
    80004390:	70e2                	ld	ra,56(sp)
    80004392:	7442                	ld	s0,48(sp)
    80004394:	74a2                	ld	s1,40(sp)
    80004396:	7902                	ld	s2,32(sp)
    80004398:	69e2                	ld	s3,24(sp)
    8000439a:	6a42                	ld	s4,16(sp)
    8000439c:	6121                	addi	sp,sp,64
    8000439e:	8082                	ret
    iput(ip);
    800043a0:	00000097          	auipc	ra,0x0
    800043a4:	a30080e7          	jalr	-1488(ra) # 80003dd0 <iput>
    return -1;
    800043a8:	557d                	li	a0,-1
    800043aa:	b7dd                	j	80004390 <dirlink+0x86>
      panic("dirlink read");
    800043ac:	00004517          	auipc	a0,0x4
    800043b0:	2ec50513          	addi	a0,a0,748 # 80008698 <syscalls+0x1c8>
    800043b4:	ffffc097          	auipc	ra,0xffffc
    800043b8:	18a080e7          	jalr	394(ra) # 8000053e <panic>
    panic("dirlink");
    800043bc:	00004517          	auipc	a0,0x4
    800043c0:	3ec50513          	addi	a0,a0,1004 # 800087a8 <syscalls+0x2d8>
    800043c4:	ffffc097          	auipc	ra,0xffffc
    800043c8:	17a080e7          	jalr	378(ra) # 8000053e <panic>

00000000800043cc <namei>:

struct inode*
namei(char *path)
{
    800043cc:	1101                	addi	sp,sp,-32
    800043ce:	ec06                	sd	ra,24(sp)
    800043d0:	e822                	sd	s0,16(sp)
    800043d2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043d4:	fe040613          	addi	a2,s0,-32
    800043d8:	4581                	li	a1,0
    800043da:	00000097          	auipc	ra,0x0
    800043de:	dd0080e7          	jalr	-560(ra) # 800041aa <namex>
}
    800043e2:	60e2                	ld	ra,24(sp)
    800043e4:	6442                	ld	s0,16(sp)
    800043e6:	6105                	addi	sp,sp,32
    800043e8:	8082                	ret

00000000800043ea <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043ea:	1141                	addi	sp,sp,-16
    800043ec:	e406                	sd	ra,8(sp)
    800043ee:	e022                	sd	s0,0(sp)
    800043f0:	0800                	addi	s0,sp,16
    800043f2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800043f4:	4585                	li	a1,1
    800043f6:	00000097          	auipc	ra,0x0
    800043fa:	db4080e7          	jalr	-588(ra) # 800041aa <namex>
}
    800043fe:	60a2                	ld	ra,8(sp)
    80004400:	6402                	ld	s0,0(sp)
    80004402:	0141                	addi	sp,sp,16
    80004404:	8082                	ret

0000000080004406 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004406:	1101                	addi	sp,sp,-32
    80004408:	ec06                	sd	ra,24(sp)
    8000440a:	e822                	sd	s0,16(sp)
    8000440c:	e426                	sd	s1,8(sp)
    8000440e:	e04a                	sd	s2,0(sp)
    80004410:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004412:	0001e917          	auipc	s2,0x1e
    80004416:	99e90913          	addi	s2,s2,-1634 # 80021db0 <log>
    8000441a:	01892583          	lw	a1,24(s2)
    8000441e:	02892503          	lw	a0,40(s2)
    80004422:	fffff097          	auipc	ra,0xfffff
    80004426:	ff2080e7          	jalr	-14(ra) # 80003414 <bread>
    8000442a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000442c:	02c92683          	lw	a3,44(s2)
    80004430:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004432:	02d05763          	blez	a3,80004460 <write_head+0x5a>
    80004436:	0001e797          	auipc	a5,0x1e
    8000443a:	9aa78793          	addi	a5,a5,-1622 # 80021de0 <log+0x30>
    8000443e:	05c50713          	addi	a4,a0,92
    80004442:	36fd                	addiw	a3,a3,-1
    80004444:	1682                	slli	a3,a3,0x20
    80004446:	9281                	srli	a3,a3,0x20
    80004448:	068a                	slli	a3,a3,0x2
    8000444a:	0001e617          	auipc	a2,0x1e
    8000444e:	99a60613          	addi	a2,a2,-1638 # 80021de4 <log+0x34>
    80004452:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004454:	4390                	lw	a2,0(a5)
    80004456:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004458:	0791                	addi	a5,a5,4
    8000445a:	0711                	addi	a4,a4,4
    8000445c:	fed79ce3          	bne	a5,a3,80004454 <write_head+0x4e>
  }
  bwrite(buf);
    80004460:	8526                	mv	a0,s1
    80004462:	fffff097          	auipc	ra,0xfffff
    80004466:	0a4080e7          	jalr	164(ra) # 80003506 <bwrite>
  brelse(buf);
    8000446a:	8526                	mv	a0,s1
    8000446c:	fffff097          	auipc	ra,0xfffff
    80004470:	0d8080e7          	jalr	216(ra) # 80003544 <brelse>
}
    80004474:	60e2                	ld	ra,24(sp)
    80004476:	6442                	ld	s0,16(sp)
    80004478:	64a2                	ld	s1,8(sp)
    8000447a:	6902                	ld	s2,0(sp)
    8000447c:	6105                	addi	sp,sp,32
    8000447e:	8082                	ret

0000000080004480 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004480:	0001e797          	auipc	a5,0x1e
    80004484:	95c7a783          	lw	a5,-1700(a5) # 80021ddc <log+0x2c>
    80004488:	0af05d63          	blez	a5,80004542 <install_trans+0xc2>
{
    8000448c:	7139                	addi	sp,sp,-64
    8000448e:	fc06                	sd	ra,56(sp)
    80004490:	f822                	sd	s0,48(sp)
    80004492:	f426                	sd	s1,40(sp)
    80004494:	f04a                	sd	s2,32(sp)
    80004496:	ec4e                	sd	s3,24(sp)
    80004498:	e852                	sd	s4,16(sp)
    8000449a:	e456                	sd	s5,8(sp)
    8000449c:	e05a                	sd	s6,0(sp)
    8000449e:	0080                	addi	s0,sp,64
    800044a0:	8b2a                	mv	s6,a0
    800044a2:	0001ea97          	auipc	s5,0x1e
    800044a6:	93ea8a93          	addi	s5,s5,-1730 # 80021de0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044aa:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044ac:	0001e997          	auipc	s3,0x1e
    800044b0:	90498993          	addi	s3,s3,-1788 # 80021db0 <log>
    800044b4:	a035                	j	800044e0 <install_trans+0x60>
      bunpin(dbuf);
    800044b6:	8526                	mv	a0,s1
    800044b8:	fffff097          	auipc	ra,0xfffff
    800044bc:	166080e7          	jalr	358(ra) # 8000361e <bunpin>
    brelse(lbuf);
    800044c0:	854a                	mv	a0,s2
    800044c2:	fffff097          	auipc	ra,0xfffff
    800044c6:	082080e7          	jalr	130(ra) # 80003544 <brelse>
    brelse(dbuf);
    800044ca:	8526                	mv	a0,s1
    800044cc:	fffff097          	auipc	ra,0xfffff
    800044d0:	078080e7          	jalr	120(ra) # 80003544 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044d4:	2a05                	addiw	s4,s4,1
    800044d6:	0a91                	addi	s5,s5,4
    800044d8:	02c9a783          	lw	a5,44(s3)
    800044dc:	04fa5963          	bge	s4,a5,8000452e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044e0:	0189a583          	lw	a1,24(s3)
    800044e4:	014585bb          	addw	a1,a1,s4
    800044e8:	2585                	addiw	a1,a1,1
    800044ea:	0289a503          	lw	a0,40(s3)
    800044ee:	fffff097          	auipc	ra,0xfffff
    800044f2:	f26080e7          	jalr	-218(ra) # 80003414 <bread>
    800044f6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800044f8:	000aa583          	lw	a1,0(s5)
    800044fc:	0289a503          	lw	a0,40(s3)
    80004500:	fffff097          	auipc	ra,0xfffff
    80004504:	f14080e7          	jalr	-236(ra) # 80003414 <bread>
    80004508:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000450a:	40000613          	li	a2,1024
    8000450e:	05890593          	addi	a1,s2,88
    80004512:	05850513          	addi	a0,a0,88
    80004516:	ffffd097          	auipc	ra,0xffffd
    8000451a:	82a080e7          	jalr	-2006(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000451e:	8526                	mv	a0,s1
    80004520:	fffff097          	auipc	ra,0xfffff
    80004524:	fe6080e7          	jalr	-26(ra) # 80003506 <bwrite>
    if(recovering == 0)
    80004528:	f80b1ce3          	bnez	s6,800044c0 <install_trans+0x40>
    8000452c:	b769                	j	800044b6 <install_trans+0x36>
}
    8000452e:	70e2                	ld	ra,56(sp)
    80004530:	7442                	ld	s0,48(sp)
    80004532:	74a2                	ld	s1,40(sp)
    80004534:	7902                	ld	s2,32(sp)
    80004536:	69e2                	ld	s3,24(sp)
    80004538:	6a42                	ld	s4,16(sp)
    8000453a:	6aa2                	ld	s5,8(sp)
    8000453c:	6b02                	ld	s6,0(sp)
    8000453e:	6121                	addi	sp,sp,64
    80004540:	8082                	ret
    80004542:	8082                	ret

0000000080004544 <initlog>:
{
    80004544:	7179                	addi	sp,sp,-48
    80004546:	f406                	sd	ra,40(sp)
    80004548:	f022                	sd	s0,32(sp)
    8000454a:	ec26                	sd	s1,24(sp)
    8000454c:	e84a                	sd	s2,16(sp)
    8000454e:	e44e                	sd	s3,8(sp)
    80004550:	1800                	addi	s0,sp,48
    80004552:	892a                	mv	s2,a0
    80004554:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004556:	0001e497          	auipc	s1,0x1e
    8000455a:	85a48493          	addi	s1,s1,-1958 # 80021db0 <log>
    8000455e:	00004597          	auipc	a1,0x4
    80004562:	14a58593          	addi	a1,a1,330 # 800086a8 <syscalls+0x1d8>
    80004566:	8526                	mv	a0,s1
    80004568:	ffffc097          	auipc	ra,0xffffc
    8000456c:	5ec080e7          	jalr	1516(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004570:	0149a583          	lw	a1,20(s3)
    80004574:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004576:	0109a783          	lw	a5,16(s3)
    8000457a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000457c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004580:	854a                	mv	a0,s2
    80004582:	fffff097          	auipc	ra,0xfffff
    80004586:	e92080e7          	jalr	-366(ra) # 80003414 <bread>
  log.lh.n = lh->n;
    8000458a:	4d3c                	lw	a5,88(a0)
    8000458c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000458e:	02f05563          	blez	a5,800045b8 <initlog+0x74>
    80004592:	05c50713          	addi	a4,a0,92
    80004596:	0001e697          	auipc	a3,0x1e
    8000459a:	84a68693          	addi	a3,a3,-1974 # 80021de0 <log+0x30>
    8000459e:	37fd                	addiw	a5,a5,-1
    800045a0:	1782                	slli	a5,a5,0x20
    800045a2:	9381                	srli	a5,a5,0x20
    800045a4:	078a                	slli	a5,a5,0x2
    800045a6:	06050613          	addi	a2,a0,96
    800045aa:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800045ac:	4310                	lw	a2,0(a4)
    800045ae:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800045b0:	0711                	addi	a4,a4,4
    800045b2:	0691                	addi	a3,a3,4
    800045b4:	fef71ce3          	bne	a4,a5,800045ac <initlog+0x68>
  brelse(buf);
    800045b8:	fffff097          	auipc	ra,0xfffff
    800045bc:	f8c080e7          	jalr	-116(ra) # 80003544 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800045c0:	4505                	li	a0,1
    800045c2:	00000097          	auipc	ra,0x0
    800045c6:	ebe080e7          	jalr	-322(ra) # 80004480 <install_trans>
  log.lh.n = 0;
    800045ca:	0001e797          	auipc	a5,0x1e
    800045ce:	8007a923          	sw	zero,-2030(a5) # 80021ddc <log+0x2c>
  write_head(); // clear the log
    800045d2:	00000097          	auipc	ra,0x0
    800045d6:	e34080e7          	jalr	-460(ra) # 80004406 <write_head>
}
    800045da:	70a2                	ld	ra,40(sp)
    800045dc:	7402                	ld	s0,32(sp)
    800045de:	64e2                	ld	s1,24(sp)
    800045e0:	6942                	ld	s2,16(sp)
    800045e2:	69a2                	ld	s3,8(sp)
    800045e4:	6145                	addi	sp,sp,48
    800045e6:	8082                	ret

00000000800045e8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045e8:	1101                	addi	sp,sp,-32
    800045ea:	ec06                	sd	ra,24(sp)
    800045ec:	e822                	sd	s0,16(sp)
    800045ee:	e426                	sd	s1,8(sp)
    800045f0:	e04a                	sd	s2,0(sp)
    800045f2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800045f4:	0001d517          	auipc	a0,0x1d
    800045f8:	7bc50513          	addi	a0,a0,1980 # 80021db0 <log>
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	5e8080e7          	jalr	1512(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004604:	0001d497          	auipc	s1,0x1d
    80004608:	7ac48493          	addi	s1,s1,1964 # 80021db0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000460c:	4979                	li	s2,30
    8000460e:	a039                	j	8000461c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004610:	85a6                	mv	a1,s1
    80004612:	8526                	mv	a0,s1
    80004614:	ffffe097          	auipc	ra,0xffffe
    80004618:	f24080e7          	jalr	-220(ra) # 80002538 <sleep>
    if(log.committing){
    8000461c:	50dc                	lw	a5,36(s1)
    8000461e:	fbed                	bnez	a5,80004610 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004620:	509c                	lw	a5,32(s1)
    80004622:	0017871b          	addiw	a4,a5,1
    80004626:	0007069b          	sext.w	a3,a4
    8000462a:	0027179b          	slliw	a5,a4,0x2
    8000462e:	9fb9                	addw	a5,a5,a4
    80004630:	0017979b          	slliw	a5,a5,0x1
    80004634:	54d8                	lw	a4,44(s1)
    80004636:	9fb9                	addw	a5,a5,a4
    80004638:	00f95963          	bge	s2,a5,8000464a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000463c:	85a6                	mv	a1,s1
    8000463e:	8526                	mv	a0,s1
    80004640:	ffffe097          	auipc	ra,0xffffe
    80004644:	ef8080e7          	jalr	-264(ra) # 80002538 <sleep>
    80004648:	bfd1                	j	8000461c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000464a:	0001d517          	auipc	a0,0x1d
    8000464e:	76650513          	addi	a0,a0,1894 # 80021db0 <log>
    80004652:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004654:	ffffc097          	auipc	ra,0xffffc
    80004658:	644080e7          	jalr	1604(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000465c:	60e2                	ld	ra,24(sp)
    8000465e:	6442                	ld	s0,16(sp)
    80004660:	64a2                	ld	s1,8(sp)
    80004662:	6902                	ld	s2,0(sp)
    80004664:	6105                	addi	sp,sp,32
    80004666:	8082                	ret

0000000080004668 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004668:	7139                	addi	sp,sp,-64
    8000466a:	fc06                	sd	ra,56(sp)
    8000466c:	f822                	sd	s0,48(sp)
    8000466e:	f426                	sd	s1,40(sp)
    80004670:	f04a                	sd	s2,32(sp)
    80004672:	ec4e                	sd	s3,24(sp)
    80004674:	e852                	sd	s4,16(sp)
    80004676:	e456                	sd	s5,8(sp)
    80004678:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000467a:	0001d497          	auipc	s1,0x1d
    8000467e:	73648493          	addi	s1,s1,1846 # 80021db0 <log>
    80004682:	8526                	mv	a0,s1
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	560080e7          	jalr	1376(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000468c:	509c                	lw	a5,32(s1)
    8000468e:	37fd                	addiw	a5,a5,-1
    80004690:	0007891b          	sext.w	s2,a5
    80004694:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004696:	50dc                	lw	a5,36(s1)
    80004698:	efb9                	bnez	a5,800046f6 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000469a:	06091663          	bnez	s2,80004706 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000469e:	0001d497          	auipc	s1,0x1d
    800046a2:	71248493          	addi	s1,s1,1810 # 80021db0 <log>
    800046a6:	4785                	li	a5,1
    800046a8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800046aa:	8526                	mv	a0,s1
    800046ac:	ffffc097          	auipc	ra,0xffffc
    800046b0:	5ec080e7          	jalr	1516(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800046b4:	54dc                	lw	a5,44(s1)
    800046b6:	06f04763          	bgtz	a5,80004724 <end_op+0xbc>
    acquire(&log.lock);
    800046ba:	0001d497          	auipc	s1,0x1d
    800046be:	6f648493          	addi	s1,s1,1782 # 80021db0 <log>
    800046c2:	8526                	mv	a0,s1
    800046c4:	ffffc097          	auipc	ra,0xffffc
    800046c8:	520080e7          	jalr	1312(ra) # 80000be4 <acquire>
    log.committing = 0;
    800046cc:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800046d0:	8526                	mv	a0,s1
    800046d2:	ffffe097          	auipc	ra,0xffffe
    800046d6:	004080e7          	jalr	4(ra) # 800026d6 <wakeup>
    release(&log.lock);
    800046da:	8526                	mv	a0,s1
    800046dc:	ffffc097          	auipc	ra,0xffffc
    800046e0:	5bc080e7          	jalr	1468(ra) # 80000c98 <release>
}
    800046e4:	70e2                	ld	ra,56(sp)
    800046e6:	7442                	ld	s0,48(sp)
    800046e8:	74a2                	ld	s1,40(sp)
    800046ea:	7902                	ld	s2,32(sp)
    800046ec:	69e2                	ld	s3,24(sp)
    800046ee:	6a42                	ld	s4,16(sp)
    800046f0:	6aa2                	ld	s5,8(sp)
    800046f2:	6121                	addi	sp,sp,64
    800046f4:	8082                	ret
    panic("log.committing");
    800046f6:	00004517          	auipc	a0,0x4
    800046fa:	fba50513          	addi	a0,a0,-70 # 800086b0 <syscalls+0x1e0>
    800046fe:	ffffc097          	auipc	ra,0xffffc
    80004702:	e40080e7          	jalr	-448(ra) # 8000053e <panic>
    wakeup(&log);
    80004706:	0001d497          	auipc	s1,0x1d
    8000470a:	6aa48493          	addi	s1,s1,1706 # 80021db0 <log>
    8000470e:	8526                	mv	a0,s1
    80004710:	ffffe097          	auipc	ra,0xffffe
    80004714:	fc6080e7          	jalr	-58(ra) # 800026d6 <wakeup>
  release(&log.lock);
    80004718:	8526                	mv	a0,s1
    8000471a:	ffffc097          	auipc	ra,0xffffc
    8000471e:	57e080e7          	jalr	1406(ra) # 80000c98 <release>
  if(do_commit){
    80004722:	b7c9                	j	800046e4 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004724:	0001da97          	auipc	s5,0x1d
    80004728:	6bca8a93          	addi	s5,s5,1724 # 80021de0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000472c:	0001da17          	auipc	s4,0x1d
    80004730:	684a0a13          	addi	s4,s4,1668 # 80021db0 <log>
    80004734:	018a2583          	lw	a1,24(s4)
    80004738:	012585bb          	addw	a1,a1,s2
    8000473c:	2585                	addiw	a1,a1,1
    8000473e:	028a2503          	lw	a0,40(s4)
    80004742:	fffff097          	auipc	ra,0xfffff
    80004746:	cd2080e7          	jalr	-814(ra) # 80003414 <bread>
    8000474a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000474c:	000aa583          	lw	a1,0(s5)
    80004750:	028a2503          	lw	a0,40(s4)
    80004754:	fffff097          	auipc	ra,0xfffff
    80004758:	cc0080e7          	jalr	-832(ra) # 80003414 <bread>
    8000475c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000475e:	40000613          	li	a2,1024
    80004762:	05850593          	addi	a1,a0,88
    80004766:	05848513          	addi	a0,s1,88
    8000476a:	ffffc097          	auipc	ra,0xffffc
    8000476e:	5d6080e7          	jalr	1494(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004772:	8526                	mv	a0,s1
    80004774:	fffff097          	auipc	ra,0xfffff
    80004778:	d92080e7          	jalr	-622(ra) # 80003506 <bwrite>
    brelse(from);
    8000477c:	854e                	mv	a0,s3
    8000477e:	fffff097          	auipc	ra,0xfffff
    80004782:	dc6080e7          	jalr	-570(ra) # 80003544 <brelse>
    brelse(to);
    80004786:	8526                	mv	a0,s1
    80004788:	fffff097          	auipc	ra,0xfffff
    8000478c:	dbc080e7          	jalr	-580(ra) # 80003544 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004790:	2905                	addiw	s2,s2,1
    80004792:	0a91                	addi	s5,s5,4
    80004794:	02ca2783          	lw	a5,44(s4)
    80004798:	f8f94ee3          	blt	s2,a5,80004734 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000479c:	00000097          	auipc	ra,0x0
    800047a0:	c6a080e7          	jalr	-918(ra) # 80004406 <write_head>
    install_trans(0); // Now install writes to home locations
    800047a4:	4501                	li	a0,0
    800047a6:	00000097          	auipc	ra,0x0
    800047aa:	cda080e7          	jalr	-806(ra) # 80004480 <install_trans>
    log.lh.n = 0;
    800047ae:	0001d797          	auipc	a5,0x1d
    800047b2:	6207a723          	sw	zero,1582(a5) # 80021ddc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800047b6:	00000097          	auipc	ra,0x0
    800047ba:	c50080e7          	jalr	-944(ra) # 80004406 <write_head>
    800047be:	bdf5                	j	800046ba <end_op+0x52>

00000000800047c0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800047c0:	1101                	addi	sp,sp,-32
    800047c2:	ec06                	sd	ra,24(sp)
    800047c4:	e822                	sd	s0,16(sp)
    800047c6:	e426                	sd	s1,8(sp)
    800047c8:	e04a                	sd	s2,0(sp)
    800047ca:	1000                	addi	s0,sp,32
    800047cc:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800047ce:	0001d917          	auipc	s2,0x1d
    800047d2:	5e290913          	addi	s2,s2,1506 # 80021db0 <log>
    800047d6:	854a                	mv	a0,s2
    800047d8:	ffffc097          	auipc	ra,0xffffc
    800047dc:	40c080e7          	jalr	1036(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800047e0:	02c92603          	lw	a2,44(s2)
    800047e4:	47f5                	li	a5,29
    800047e6:	06c7c563          	blt	a5,a2,80004850 <log_write+0x90>
    800047ea:	0001d797          	auipc	a5,0x1d
    800047ee:	5e27a783          	lw	a5,1506(a5) # 80021dcc <log+0x1c>
    800047f2:	37fd                	addiw	a5,a5,-1
    800047f4:	04f65e63          	bge	a2,a5,80004850 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800047f8:	0001d797          	auipc	a5,0x1d
    800047fc:	5d87a783          	lw	a5,1496(a5) # 80021dd0 <log+0x20>
    80004800:	06f05063          	blez	a5,80004860 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004804:	4781                	li	a5,0
    80004806:	06c05563          	blez	a2,80004870 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000480a:	44cc                	lw	a1,12(s1)
    8000480c:	0001d717          	auipc	a4,0x1d
    80004810:	5d470713          	addi	a4,a4,1492 # 80021de0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004814:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004816:	4314                	lw	a3,0(a4)
    80004818:	04b68c63          	beq	a3,a1,80004870 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000481c:	2785                	addiw	a5,a5,1
    8000481e:	0711                	addi	a4,a4,4
    80004820:	fef61be3          	bne	a2,a5,80004816 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004824:	0621                	addi	a2,a2,8
    80004826:	060a                	slli	a2,a2,0x2
    80004828:	0001d797          	auipc	a5,0x1d
    8000482c:	58878793          	addi	a5,a5,1416 # 80021db0 <log>
    80004830:	963e                	add	a2,a2,a5
    80004832:	44dc                	lw	a5,12(s1)
    80004834:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004836:	8526                	mv	a0,s1
    80004838:	fffff097          	auipc	ra,0xfffff
    8000483c:	daa080e7          	jalr	-598(ra) # 800035e2 <bpin>
    log.lh.n++;
    80004840:	0001d717          	auipc	a4,0x1d
    80004844:	57070713          	addi	a4,a4,1392 # 80021db0 <log>
    80004848:	575c                	lw	a5,44(a4)
    8000484a:	2785                	addiw	a5,a5,1
    8000484c:	d75c                	sw	a5,44(a4)
    8000484e:	a835                	j	8000488a <log_write+0xca>
    panic("too big a transaction");
    80004850:	00004517          	auipc	a0,0x4
    80004854:	e7050513          	addi	a0,a0,-400 # 800086c0 <syscalls+0x1f0>
    80004858:	ffffc097          	auipc	ra,0xffffc
    8000485c:	ce6080e7          	jalr	-794(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004860:	00004517          	auipc	a0,0x4
    80004864:	e7850513          	addi	a0,a0,-392 # 800086d8 <syscalls+0x208>
    80004868:	ffffc097          	auipc	ra,0xffffc
    8000486c:	cd6080e7          	jalr	-810(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004870:	00878713          	addi	a4,a5,8
    80004874:	00271693          	slli	a3,a4,0x2
    80004878:	0001d717          	auipc	a4,0x1d
    8000487c:	53870713          	addi	a4,a4,1336 # 80021db0 <log>
    80004880:	9736                	add	a4,a4,a3
    80004882:	44d4                	lw	a3,12(s1)
    80004884:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004886:	faf608e3          	beq	a2,a5,80004836 <log_write+0x76>
  }
  release(&log.lock);
    8000488a:	0001d517          	auipc	a0,0x1d
    8000488e:	52650513          	addi	a0,a0,1318 # 80021db0 <log>
    80004892:	ffffc097          	auipc	ra,0xffffc
    80004896:	406080e7          	jalr	1030(ra) # 80000c98 <release>
}
    8000489a:	60e2                	ld	ra,24(sp)
    8000489c:	6442                	ld	s0,16(sp)
    8000489e:	64a2                	ld	s1,8(sp)
    800048a0:	6902                	ld	s2,0(sp)
    800048a2:	6105                	addi	sp,sp,32
    800048a4:	8082                	ret

00000000800048a6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800048a6:	1101                	addi	sp,sp,-32
    800048a8:	ec06                	sd	ra,24(sp)
    800048aa:	e822                	sd	s0,16(sp)
    800048ac:	e426                	sd	s1,8(sp)
    800048ae:	e04a                	sd	s2,0(sp)
    800048b0:	1000                	addi	s0,sp,32
    800048b2:	84aa                	mv	s1,a0
    800048b4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800048b6:	00004597          	auipc	a1,0x4
    800048ba:	e4258593          	addi	a1,a1,-446 # 800086f8 <syscalls+0x228>
    800048be:	0521                	addi	a0,a0,8
    800048c0:	ffffc097          	auipc	ra,0xffffc
    800048c4:	294080e7          	jalr	660(ra) # 80000b54 <initlock>
  lk->name = name;
    800048c8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800048cc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048d0:	0204a423          	sw	zero,40(s1)
}
    800048d4:	60e2                	ld	ra,24(sp)
    800048d6:	6442                	ld	s0,16(sp)
    800048d8:	64a2                	ld	s1,8(sp)
    800048da:	6902                	ld	s2,0(sp)
    800048dc:	6105                	addi	sp,sp,32
    800048de:	8082                	ret

00000000800048e0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800048e0:	1101                	addi	sp,sp,-32
    800048e2:	ec06                	sd	ra,24(sp)
    800048e4:	e822                	sd	s0,16(sp)
    800048e6:	e426                	sd	s1,8(sp)
    800048e8:	e04a                	sd	s2,0(sp)
    800048ea:	1000                	addi	s0,sp,32
    800048ec:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048ee:	00850913          	addi	s2,a0,8
    800048f2:	854a                	mv	a0,s2
    800048f4:	ffffc097          	auipc	ra,0xffffc
    800048f8:	2f0080e7          	jalr	752(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800048fc:	409c                	lw	a5,0(s1)
    800048fe:	cb89                	beqz	a5,80004910 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004900:	85ca                	mv	a1,s2
    80004902:	8526                	mv	a0,s1
    80004904:	ffffe097          	auipc	ra,0xffffe
    80004908:	c34080e7          	jalr	-972(ra) # 80002538 <sleep>
  while (lk->locked) {
    8000490c:	409c                	lw	a5,0(s1)
    8000490e:	fbed                	bnez	a5,80004900 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004910:	4785                	li	a5,1
    80004912:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004914:	ffffd097          	auipc	ra,0xffffd
    80004918:	426080e7          	jalr	1062(ra) # 80001d3a <myproc>
    8000491c:	591c                	lw	a5,48(a0)
    8000491e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004920:	854a                	mv	a0,s2
    80004922:	ffffc097          	auipc	ra,0xffffc
    80004926:	376080e7          	jalr	886(ra) # 80000c98 <release>
}
    8000492a:	60e2                	ld	ra,24(sp)
    8000492c:	6442                	ld	s0,16(sp)
    8000492e:	64a2                	ld	s1,8(sp)
    80004930:	6902                	ld	s2,0(sp)
    80004932:	6105                	addi	sp,sp,32
    80004934:	8082                	ret

0000000080004936 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004936:	1101                	addi	sp,sp,-32
    80004938:	ec06                	sd	ra,24(sp)
    8000493a:	e822                	sd	s0,16(sp)
    8000493c:	e426                	sd	s1,8(sp)
    8000493e:	e04a                	sd	s2,0(sp)
    80004940:	1000                	addi	s0,sp,32
    80004942:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004944:	00850913          	addi	s2,a0,8
    80004948:	854a                	mv	a0,s2
    8000494a:	ffffc097          	auipc	ra,0xffffc
    8000494e:	29a080e7          	jalr	666(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004952:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004956:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000495a:	8526                	mv	a0,s1
    8000495c:	ffffe097          	auipc	ra,0xffffe
    80004960:	d7a080e7          	jalr	-646(ra) # 800026d6 <wakeup>
  release(&lk->lk);
    80004964:	854a                	mv	a0,s2
    80004966:	ffffc097          	auipc	ra,0xffffc
    8000496a:	332080e7          	jalr	818(ra) # 80000c98 <release>
}
    8000496e:	60e2                	ld	ra,24(sp)
    80004970:	6442                	ld	s0,16(sp)
    80004972:	64a2                	ld	s1,8(sp)
    80004974:	6902                	ld	s2,0(sp)
    80004976:	6105                	addi	sp,sp,32
    80004978:	8082                	ret

000000008000497a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000497a:	7179                	addi	sp,sp,-48
    8000497c:	f406                	sd	ra,40(sp)
    8000497e:	f022                	sd	s0,32(sp)
    80004980:	ec26                	sd	s1,24(sp)
    80004982:	e84a                	sd	s2,16(sp)
    80004984:	e44e                	sd	s3,8(sp)
    80004986:	1800                	addi	s0,sp,48
    80004988:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000498a:	00850913          	addi	s2,a0,8
    8000498e:	854a                	mv	a0,s2
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	254080e7          	jalr	596(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004998:	409c                	lw	a5,0(s1)
    8000499a:	ef99                	bnez	a5,800049b8 <holdingsleep+0x3e>
    8000499c:	4481                	li	s1,0
  release(&lk->lk);
    8000499e:	854a                	mv	a0,s2
    800049a0:	ffffc097          	auipc	ra,0xffffc
    800049a4:	2f8080e7          	jalr	760(ra) # 80000c98 <release>
  return r;
}
    800049a8:	8526                	mv	a0,s1
    800049aa:	70a2                	ld	ra,40(sp)
    800049ac:	7402                	ld	s0,32(sp)
    800049ae:	64e2                	ld	s1,24(sp)
    800049b0:	6942                	ld	s2,16(sp)
    800049b2:	69a2                	ld	s3,8(sp)
    800049b4:	6145                	addi	sp,sp,48
    800049b6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800049b8:	0284a983          	lw	s3,40(s1)
    800049bc:	ffffd097          	auipc	ra,0xffffd
    800049c0:	37e080e7          	jalr	894(ra) # 80001d3a <myproc>
    800049c4:	5904                	lw	s1,48(a0)
    800049c6:	413484b3          	sub	s1,s1,s3
    800049ca:	0014b493          	seqz	s1,s1
    800049ce:	bfc1                	j	8000499e <holdingsleep+0x24>

00000000800049d0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800049d0:	1141                	addi	sp,sp,-16
    800049d2:	e406                	sd	ra,8(sp)
    800049d4:	e022                	sd	s0,0(sp)
    800049d6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049d8:	00004597          	auipc	a1,0x4
    800049dc:	d3058593          	addi	a1,a1,-720 # 80008708 <syscalls+0x238>
    800049e0:	0001d517          	auipc	a0,0x1d
    800049e4:	51850513          	addi	a0,a0,1304 # 80021ef8 <ftable>
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	16c080e7          	jalr	364(ra) # 80000b54 <initlock>
}
    800049f0:	60a2                	ld	ra,8(sp)
    800049f2:	6402                	ld	s0,0(sp)
    800049f4:	0141                	addi	sp,sp,16
    800049f6:	8082                	ret

00000000800049f8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800049f8:	1101                	addi	sp,sp,-32
    800049fa:	ec06                	sd	ra,24(sp)
    800049fc:	e822                	sd	s0,16(sp)
    800049fe:	e426                	sd	s1,8(sp)
    80004a00:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a02:	0001d517          	auipc	a0,0x1d
    80004a06:	4f650513          	addi	a0,a0,1270 # 80021ef8 <ftable>
    80004a0a:	ffffc097          	auipc	ra,0xffffc
    80004a0e:	1da080e7          	jalr	474(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a12:	0001d497          	auipc	s1,0x1d
    80004a16:	4fe48493          	addi	s1,s1,1278 # 80021f10 <ftable+0x18>
    80004a1a:	0001e717          	auipc	a4,0x1e
    80004a1e:	49670713          	addi	a4,a4,1174 # 80022eb0 <ftable+0xfb8>
    if(f->ref == 0){
    80004a22:	40dc                	lw	a5,4(s1)
    80004a24:	cf99                	beqz	a5,80004a42 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a26:	02848493          	addi	s1,s1,40
    80004a2a:	fee49ce3          	bne	s1,a4,80004a22 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a2e:	0001d517          	auipc	a0,0x1d
    80004a32:	4ca50513          	addi	a0,a0,1226 # 80021ef8 <ftable>
    80004a36:	ffffc097          	auipc	ra,0xffffc
    80004a3a:	262080e7          	jalr	610(ra) # 80000c98 <release>
  return 0;
    80004a3e:	4481                	li	s1,0
    80004a40:	a819                	j	80004a56 <filealloc+0x5e>
      f->ref = 1;
    80004a42:	4785                	li	a5,1
    80004a44:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a46:	0001d517          	auipc	a0,0x1d
    80004a4a:	4b250513          	addi	a0,a0,1202 # 80021ef8 <ftable>
    80004a4e:	ffffc097          	auipc	ra,0xffffc
    80004a52:	24a080e7          	jalr	586(ra) # 80000c98 <release>
}
    80004a56:	8526                	mv	a0,s1
    80004a58:	60e2                	ld	ra,24(sp)
    80004a5a:	6442                	ld	s0,16(sp)
    80004a5c:	64a2                	ld	s1,8(sp)
    80004a5e:	6105                	addi	sp,sp,32
    80004a60:	8082                	ret

0000000080004a62 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a62:	1101                	addi	sp,sp,-32
    80004a64:	ec06                	sd	ra,24(sp)
    80004a66:	e822                	sd	s0,16(sp)
    80004a68:	e426                	sd	s1,8(sp)
    80004a6a:	1000                	addi	s0,sp,32
    80004a6c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a6e:	0001d517          	auipc	a0,0x1d
    80004a72:	48a50513          	addi	a0,a0,1162 # 80021ef8 <ftable>
    80004a76:	ffffc097          	auipc	ra,0xffffc
    80004a7a:	16e080e7          	jalr	366(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a7e:	40dc                	lw	a5,4(s1)
    80004a80:	02f05263          	blez	a5,80004aa4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a84:	2785                	addiw	a5,a5,1
    80004a86:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a88:	0001d517          	auipc	a0,0x1d
    80004a8c:	47050513          	addi	a0,a0,1136 # 80021ef8 <ftable>
    80004a90:	ffffc097          	auipc	ra,0xffffc
    80004a94:	208080e7          	jalr	520(ra) # 80000c98 <release>
  return f;
}
    80004a98:	8526                	mv	a0,s1
    80004a9a:	60e2                	ld	ra,24(sp)
    80004a9c:	6442                	ld	s0,16(sp)
    80004a9e:	64a2                	ld	s1,8(sp)
    80004aa0:	6105                	addi	sp,sp,32
    80004aa2:	8082                	ret
    panic("filedup");
    80004aa4:	00004517          	auipc	a0,0x4
    80004aa8:	c6c50513          	addi	a0,a0,-916 # 80008710 <syscalls+0x240>
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	a92080e7          	jalr	-1390(ra) # 8000053e <panic>

0000000080004ab4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ab4:	7139                	addi	sp,sp,-64
    80004ab6:	fc06                	sd	ra,56(sp)
    80004ab8:	f822                	sd	s0,48(sp)
    80004aba:	f426                	sd	s1,40(sp)
    80004abc:	f04a                	sd	s2,32(sp)
    80004abe:	ec4e                	sd	s3,24(sp)
    80004ac0:	e852                	sd	s4,16(sp)
    80004ac2:	e456                	sd	s5,8(sp)
    80004ac4:	0080                	addi	s0,sp,64
    80004ac6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004ac8:	0001d517          	auipc	a0,0x1d
    80004acc:	43050513          	addi	a0,a0,1072 # 80021ef8 <ftable>
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	114080e7          	jalr	276(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004ad8:	40dc                	lw	a5,4(s1)
    80004ada:	06f05163          	blez	a5,80004b3c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004ade:	37fd                	addiw	a5,a5,-1
    80004ae0:	0007871b          	sext.w	a4,a5
    80004ae4:	c0dc                	sw	a5,4(s1)
    80004ae6:	06e04363          	bgtz	a4,80004b4c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004aea:	0004a903          	lw	s2,0(s1)
    80004aee:	0094ca83          	lbu	s5,9(s1)
    80004af2:	0104ba03          	ld	s4,16(s1)
    80004af6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004afa:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004afe:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b02:	0001d517          	auipc	a0,0x1d
    80004b06:	3f650513          	addi	a0,a0,1014 # 80021ef8 <ftable>
    80004b0a:	ffffc097          	auipc	ra,0xffffc
    80004b0e:	18e080e7          	jalr	398(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004b12:	4785                	li	a5,1
    80004b14:	04f90d63          	beq	s2,a5,80004b6e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b18:	3979                	addiw	s2,s2,-2
    80004b1a:	4785                	li	a5,1
    80004b1c:	0527e063          	bltu	a5,s2,80004b5c <fileclose+0xa8>
    begin_op();
    80004b20:	00000097          	auipc	ra,0x0
    80004b24:	ac8080e7          	jalr	-1336(ra) # 800045e8 <begin_op>
    iput(ff.ip);
    80004b28:	854e                	mv	a0,s3
    80004b2a:	fffff097          	auipc	ra,0xfffff
    80004b2e:	2a6080e7          	jalr	678(ra) # 80003dd0 <iput>
    end_op();
    80004b32:	00000097          	auipc	ra,0x0
    80004b36:	b36080e7          	jalr	-1226(ra) # 80004668 <end_op>
    80004b3a:	a00d                	j	80004b5c <fileclose+0xa8>
    panic("fileclose");
    80004b3c:	00004517          	auipc	a0,0x4
    80004b40:	bdc50513          	addi	a0,a0,-1060 # 80008718 <syscalls+0x248>
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	9fa080e7          	jalr	-1542(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004b4c:	0001d517          	auipc	a0,0x1d
    80004b50:	3ac50513          	addi	a0,a0,940 # 80021ef8 <ftable>
    80004b54:	ffffc097          	auipc	ra,0xffffc
    80004b58:	144080e7          	jalr	324(ra) # 80000c98 <release>
  }
}
    80004b5c:	70e2                	ld	ra,56(sp)
    80004b5e:	7442                	ld	s0,48(sp)
    80004b60:	74a2                	ld	s1,40(sp)
    80004b62:	7902                	ld	s2,32(sp)
    80004b64:	69e2                	ld	s3,24(sp)
    80004b66:	6a42                	ld	s4,16(sp)
    80004b68:	6aa2                	ld	s5,8(sp)
    80004b6a:	6121                	addi	sp,sp,64
    80004b6c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b6e:	85d6                	mv	a1,s5
    80004b70:	8552                	mv	a0,s4
    80004b72:	00000097          	auipc	ra,0x0
    80004b76:	34c080e7          	jalr	844(ra) # 80004ebe <pipeclose>
    80004b7a:	b7cd                	j	80004b5c <fileclose+0xa8>

0000000080004b7c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b7c:	715d                	addi	sp,sp,-80
    80004b7e:	e486                	sd	ra,72(sp)
    80004b80:	e0a2                	sd	s0,64(sp)
    80004b82:	fc26                	sd	s1,56(sp)
    80004b84:	f84a                	sd	s2,48(sp)
    80004b86:	f44e                	sd	s3,40(sp)
    80004b88:	0880                	addi	s0,sp,80
    80004b8a:	84aa                	mv	s1,a0
    80004b8c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b8e:	ffffd097          	auipc	ra,0xffffd
    80004b92:	1ac080e7          	jalr	428(ra) # 80001d3a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b96:	409c                	lw	a5,0(s1)
    80004b98:	37f9                	addiw	a5,a5,-2
    80004b9a:	4705                	li	a4,1
    80004b9c:	04f76763          	bltu	a4,a5,80004bea <filestat+0x6e>
    80004ba0:	892a                	mv	s2,a0
    ilock(f->ip);
    80004ba2:	6c88                	ld	a0,24(s1)
    80004ba4:	fffff097          	auipc	ra,0xfffff
    80004ba8:	072080e7          	jalr	114(ra) # 80003c16 <ilock>
    stati(f->ip, &st);
    80004bac:	fb840593          	addi	a1,s0,-72
    80004bb0:	6c88                	ld	a0,24(s1)
    80004bb2:	fffff097          	auipc	ra,0xfffff
    80004bb6:	2ee080e7          	jalr	750(ra) # 80003ea0 <stati>
    iunlock(f->ip);
    80004bba:	6c88                	ld	a0,24(s1)
    80004bbc:	fffff097          	auipc	ra,0xfffff
    80004bc0:	11c080e7          	jalr	284(ra) # 80003cd8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004bc4:	46e1                	li	a3,24
    80004bc6:	fb840613          	addi	a2,s0,-72
    80004bca:	85ce                	mv	a1,s3
    80004bcc:	05093503          	ld	a0,80(s2)
    80004bd0:	ffffd097          	auipc	ra,0xffffd
    80004bd4:	aa2080e7          	jalr	-1374(ra) # 80001672 <copyout>
    80004bd8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004bdc:	60a6                	ld	ra,72(sp)
    80004bde:	6406                	ld	s0,64(sp)
    80004be0:	74e2                	ld	s1,56(sp)
    80004be2:	7942                	ld	s2,48(sp)
    80004be4:	79a2                	ld	s3,40(sp)
    80004be6:	6161                	addi	sp,sp,80
    80004be8:	8082                	ret
  return -1;
    80004bea:	557d                	li	a0,-1
    80004bec:	bfc5                	j	80004bdc <filestat+0x60>

0000000080004bee <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004bee:	7179                	addi	sp,sp,-48
    80004bf0:	f406                	sd	ra,40(sp)
    80004bf2:	f022                	sd	s0,32(sp)
    80004bf4:	ec26                	sd	s1,24(sp)
    80004bf6:	e84a                	sd	s2,16(sp)
    80004bf8:	e44e                	sd	s3,8(sp)
    80004bfa:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004bfc:	00854783          	lbu	a5,8(a0)
    80004c00:	c3d5                	beqz	a5,80004ca4 <fileread+0xb6>
    80004c02:	84aa                	mv	s1,a0
    80004c04:	89ae                	mv	s3,a1
    80004c06:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c08:	411c                	lw	a5,0(a0)
    80004c0a:	4705                	li	a4,1
    80004c0c:	04e78963          	beq	a5,a4,80004c5e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c10:	470d                	li	a4,3
    80004c12:	04e78d63          	beq	a5,a4,80004c6c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c16:	4709                	li	a4,2
    80004c18:	06e79e63          	bne	a5,a4,80004c94 <fileread+0xa6>
    ilock(f->ip);
    80004c1c:	6d08                	ld	a0,24(a0)
    80004c1e:	fffff097          	auipc	ra,0xfffff
    80004c22:	ff8080e7          	jalr	-8(ra) # 80003c16 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c26:	874a                	mv	a4,s2
    80004c28:	5094                	lw	a3,32(s1)
    80004c2a:	864e                	mv	a2,s3
    80004c2c:	4585                	li	a1,1
    80004c2e:	6c88                	ld	a0,24(s1)
    80004c30:	fffff097          	auipc	ra,0xfffff
    80004c34:	29a080e7          	jalr	666(ra) # 80003eca <readi>
    80004c38:	892a                	mv	s2,a0
    80004c3a:	00a05563          	blez	a0,80004c44 <fileread+0x56>
      f->off += r;
    80004c3e:	509c                	lw	a5,32(s1)
    80004c40:	9fa9                	addw	a5,a5,a0
    80004c42:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c44:	6c88                	ld	a0,24(s1)
    80004c46:	fffff097          	auipc	ra,0xfffff
    80004c4a:	092080e7          	jalr	146(ra) # 80003cd8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c4e:	854a                	mv	a0,s2
    80004c50:	70a2                	ld	ra,40(sp)
    80004c52:	7402                	ld	s0,32(sp)
    80004c54:	64e2                	ld	s1,24(sp)
    80004c56:	6942                	ld	s2,16(sp)
    80004c58:	69a2                	ld	s3,8(sp)
    80004c5a:	6145                	addi	sp,sp,48
    80004c5c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c5e:	6908                	ld	a0,16(a0)
    80004c60:	00000097          	auipc	ra,0x0
    80004c64:	3c8080e7          	jalr	968(ra) # 80005028 <piperead>
    80004c68:	892a                	mv	s2,a0
    80004c6a:	b7d5                	j	80004c4e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c6c:	02451783          	lh	a5,36(a0)
    80004c70:	03079693          	slli	a3,a5,0x30
    80004c74:	92c1                	srli	a3,a3,0x30
    80004c76:	4725                	li	a4,9
    80004c78:	02d76863          	bltu	a4,a3,80004ca8 <fileread+0xba>
    80004c7c:	0792                	slli	a5,a5,0x4
    80004c7e:	0001d717          	auipc	a4,0x1d
    80004c82:	1da70713          	addi	a4,a4,474 # 80021e58 <devsw>
    80004c86:	97ba                	add	a5,a5,a4
    80004c88:	639c                	ld	a5,0(a5)
    80004c8a:	c38d                	beqz	a5,80004cac <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c8c:	4505                	li	a0,1
    80004c8e:	9782                	jalr	a5
    80004c90:	892a                	mv	s2,a0
    80004c92:	bf75                	j	80004c4e <fileread+0x60>
    panic("fileread");
    80004c94:	00004517          	auipc	a0,0x4
    80004c98:	a9450513          	addi	a0,a0,-1388 # 80008728 <syscalls+0x258>
    80004c9c:	ffffc097          	auipc	ra,0xffffc
    80004ca0:	8a2080e7          	jalr	-1886(ra) # 8000053e <panic>
    return -1;
    80004ca4:	597d                	li	s2,-1
    80004ca6:	b765                	j	80004c4e <fileread+0x60>
      return -1;
    80004ca8:	597d                	li	s2,-1
    80004caa:	b755                	j	80004c4e <fileread+0x60>
    80004cac:	597d                	li	s2,-1
    80004cae:	b745                	j	80004c4e <fileread+0x60>

0000000080004cb0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004cb0:	715d                	addi	sp,sp,-80
    80004cb2:	e486                	sd	ra,72(sp)
    80004cb4:	e0a2                	sd	s0,64(sp)
    80004cb6:	fc26                	sd	s1,56(sp)
    80004cb8:	f84a                	sd	s2,48(sp)
    80004cba:	f44e                	sd	s3,40(sp)
    80004cbc:	f052                	sd	s4,32(sp)
    80004cbe:	ec56                	sd	s5,24(sp)
    80004cc0:	e85a                	sd	s6,16(sp)
    80004cc2:	e45e                	sd	s7,8(sp)
    80004cc4:	e062                	sd	s8,0(sp)
    80004cc6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004cc8:	00954783          	lbu	a5,9(a0)
    80004ccc:	10078663          	beqz	a5,80004dd8 <filewrite+0x128>
    80004cd0:	892a                	mv	s2,a0
    80004cd2:	8aae                	mv	s5,a1
    80004cd4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cd6:	411c                	lw	a5,0(a0)
    80004cd8:	4705                	li	a4,1
    80004cda:	02e78263          	beq	a5,a4,80004cfe <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cde:	470d                	li	a4,3
    80004ce0:	02e78663          	beq	a5,a4,80004d0c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ce4:	4709                	li	a4,2
    80004ce6:	0ee79163          	bne	a5,a4,80004dc8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004cea:	0ac05d63          	blez	a2,80004da4 <filewrite+0xf4>
    int i = 0;
    80004cee:	4981                	li	s3,0
    80004cf0:	6b05                	lui	s6,0x1
    80004cf2:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004cf6:	6b85                	lui	s7,0x1
    80004cf8:	c00b8b9b          	addiw	s7,s7,-1024
    80004cfc:	a861                	j	80004d94 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004cfe:	6908                	ld	a0,16(a0)
    80004d00:	00000097          	auipc	ra,0x0
    80004d04:	22e080e7          	jalr	558(ra) # 80004f2e <pipewrite>
    80004d08:	8a2a                	mv	s4,a0
    80004d0a:	a045                	j	80004daa <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d0c:	02451783          	lh	a5,36(a0)
    80004d10:	03079693          	slli	a3,a5,0x30
    80004d14:	92c1                	srli	a3,a3,0x30
    80004d16:	4725                	li	a4,9
    80004d18:	0cd76263          	bltu	a4,a3,80004ddc <filewrite+0x12c>
    80004d1c:	0792                	slli	a5,a5,0x4
    80004d1e:	0001d717          	auipc	a4,0x1d
    80004d22:	13a70713          	addi	a4,a4,314 # 80021e58 <devsw>
    80004d26:	97ba                	add	a5,a5,a4
    80004d28:	679c                	ld	a5,8(a5)
    80004d2a:	cbdd                	beqz	a5,80004de0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d2c:	4505                	li	a0,1
    80004d2e:	9782                	jalr	a5
    80004d30:	8a2a                	mv	s4,a0
    80004d32:	a8a5                	j	80004daa <filewrite+0xfa>
    80004d34:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d38:	00000097          	auipc	ra,0x0
    80004d3c:	8b0080e7          	jalr	-1872(ra) # 800045e8 <begin_op>
      ilock(f->ip);
    80004d40:	01893503          	ld	a0,24(s2)
    80004d44:	fffff097          	auipc	ra,0xfffff
    80004d48:	ed2080e7          	jalr	-302(ra) # 80003c16 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d4c:	8762                	mv	a4,s8
    80004d4e:	02092683          	lw	a3,32(s2)
    80004d52:	01598633          	add	a2,s3,s5
    80004d56:	4585                	li	a1,1
    80004d58:	01893503          	ld	a0,24(s2)
    80004d5c:	fffff097          	auipc	ra,0xfffff
    80004d60:	266080e7          	jalr	614(ra) # 80003fc2 <writei>
    80004d64:	84aa                	mv	s1,a0
    80004d66:	00a05763          	blez	a0,80004d74 <filewrite+0xc4>
        f->off += r;
    80004d6a:	02092783          	lw	a5,32(s2)
    80004d6e:	9fa9                	addw	a5,a5,a0
    80004d70:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d74:	01893503          	ld	a0,24(s2)
    80004d78:	fffff097          	auipc	ra,0xfffff
    80004d7c:	f60080e7          	jalr	-160(ra) # 80003cd8 <iunlock>
      end_op();
    80004d80:	00000097          	auipc	ra,0x0
    80004d84:	8e8080e7          	jalr	-1816(ra) # 80004668 <end_op>

      if(r != n1){
    80004d88:	009c1f63          	bne	s8,s1,80004da6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d8c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d90:	0149db63          	bge	s3,s4,80004da6 <filewrite+0xf6>
      int n1 = n - i;
    80004d94:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d98:	84be                	mv	s1,a5
    80004d9a:	2781                	sext.w	a5,a5
    80004d9c:	f8fb5ce3          	bge	s6,a5,80004d34 <filewrite+0x84>
    80004da0:	84de                	mv	s1,s7
    80004da2:	bf49                	j	80004d34 <filewrite+0x84>
    int i = 0;
    80004da4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004da6:	013a1f63          	bne	s4,s3,80004dc4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004daa:	8552                	mv	a0,s4
    80004dac:	60a6                	ld	ra,72(sp)
    80004dae:	6406                	ld	s0,64(sp)
    80004db0:	74e2                	ld	s1,56(sp)
    80004db2:	7942                	ld	s2,48(sp)
    80004db4:	79a2                	ld	s3,40(sp)
    80004db6:	7a02                	ld	s4,32(sp)
    80004db8:	6ae2                	ld	s5,24(sp)
    80004dba:	6b42                	ld	s6,16(sp)
    80004dbc:	6ba2                	ld	s7,8(sp)
    80004dbe:	6c02                	ld	s8,0(sp)
    80004dc0:	6161                	addi	sp,sp,80
    80004dc2:	8082                	ret
    ret = (i == n ? n : -1);
    80004dc4:	5a7d                	li	s4,-1
    80004dc6:	b7d5                	j	80004daa <filewrite+0xfa>
    panic("filewrite");
    80004dc8:	00004517          	auipc	a0,0x4
    80004dcc:	97050513          	addi	a0,a0,-1680 # 80008738 <syscalls+0x268>
    80004dd0:	ffffb097          	auipc	ra,0xffffb
    80004dd4:	76e080e7          	jalr	1902(ra) # 8000053e <panic>
    return -1;
    80004dd8:	5a7d                	li	s4,-1
    80004dda:	bfc1                	j	80004daa <filewrite+0xfa>
      return -1;
    80004ddc:	5a7d                	li	s4,-1
    80004dde:	b7f1                	j	80004daa <filewrite+0xfa>
    80004de0:	5a7d                	li	s4,-1
    80004de2:	b7e1                	j	80004daa <filewrite+0xfa>

0000000080004de4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004de4:	7179                	addi	sp,sp,-48
    80004de6:	f406                	sd	ra,40(sp)
    80004de8:	f022                	sd	s0,32(sp)
    80004dea:	ec26                	sd	s1,24(sp)
    80004dec:	e84a                	sd	s2,16(sp)
    80004dee:	e44e                	sd	s3,8(sp)
    80004df0:	e052                	sd	s4,0(sp)
    80004df2:	1800                	addi	s0,sp,48
    80004df4:	84aa                	mv	s1,a0
    80004df6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004df8:	0005b023          	sd	zero,0(a1)
    80004dfc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e00:	00000097          	auipc	ra,0x0
    80004e04:	bf8080e7          	jalr	-1032(ra) # 800049f8 <filealloc>
    80004e08:	e088                	sd	a0,0(s1)
    80004e0a:	c551                	beqz	a0,80004e96 <pipealloc+0xb2>
    80004e0c:	00000097          	auipc	ra,0x0
    80004e10:	bec080e7          	jalr	-1044(ra) # 800049f8 <filealloc>
    80004e14:	00aa3023          	sd	a0,0(s4)
    80004e18:	c92d                	beqz	a0,80004e8a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e1a:	ffffc097          	auipc	ra,0xffffc
    80004e1e:	cda080e7          	jalr	-806(ra) # 80000af4 <kalloc>
    80004e22:	892a                	mv	s2,a0
    80004e24:	c125                	beqz	a0,80004e84 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e26:	4985                	li	s3,1
    80004e28:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e2c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e30:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e34:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e38:	00004597          	auipc	a1,0x4
    80004e3c:	91058593          	addi	a1,a1,-1776 # 80008748 <syscalls+0x278>
    80004e40:	ffffc097          	auipc	ra,0xffffc
    80004e44:	d14080e7          	jalr	-748(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004e48:	609c                	ld	a5,0(s1)
    80004e4a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e4e:	609c                	ld	a5,0(s1)
    80004e50:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e54:	609c                	ld	a5,0(s1)
    80004e56:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e5a:	609c                	ld	a5,0(s1)
    80004e5c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e60:	000a3783          	ld	a5,0(s4)
    80004e64:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e68:	000a3783          	ld	a5,0(s4)
    80004e6c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e70:	000a3783          	ld	a5,0(s4)
    80004e74:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e78:	000a3783          	ld	a5,0(s4)
    80004e7c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e80:	4501                	li	a0,0
    80004e82:	a025                	j	80004eaa <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e84:	6088                	ld	a0,0(s1)
    80004e86:	e501                	bnez	a0,80004e8e <pipealloc+0xaa>
    80004e88:	a039                	j	80004e96 <pipealloc+0xb2>
    80004e8a:	6088                	ld	a0,0(s1)
    80004e8c:	c51d                	beqz	a0,80004eba <pipealloc+0xd6>
    fileclose(*f0);
    80004e8e:	00000097          	auipc	ra,0x0
    80004e92:	c26080e7          	jalr	-986(ra) # 80004ab4 <fileclose>
  if(*f1)
    80004e96:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e9a:	557d                	li	a0,-1
  if(*f1)
    80004e9c:	c799                	beqz	a5,80004eaa <pipealloc+0xc6>
    fileclose(*f1);
    80004e9e:	853e                	mv	a0,a5
    80004ea0:	00000097          	auipc	ra,0x0
    80004ea4:	c14080e7          	jalr	-1004(ra) # 80004ab4 <fileclose>
  return -1;
    80004ea8:	557d                	li	a0,-1
}
    80004eaa:	70a2                	ld	ra,40(sp)
    80004eac:	7402                	ld	s0,32(sp)
    80004eae:	64e2                	ld	s1,24(sp)
    80004eb0:	6942                	ld	s2,16(sp)
    80004eb2:	69a2                	ld	s3,8(sp)
    80004eb4:	6a02                	ld	s4,0(sp)
    80004eb6:	6145                	addi	sp,sp,48
    80004eb8:	8082                	ret
  return -1;
    80004eba:	557d                	li	a0,-1
    80004ebc:	b7fd                	j	80004eaa <pipealloc+0xc6>

0000000080004ebe <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ebe:	1101                	addi	sp,sp,-32
    80004ec0:	ec06                	sd	ra,24(sp)
    80004ec2:	e822                	sd	s0,16(sp)
    80004ec4:	e426                	sd	s1,8(sp)
    80004ec6:	e04a                	sd	s2,0(sp)
    80004ec8:	1000                	addi	s0,sp,32
    80004eca:	84aa                	mv	s1,a0
    80004ecc:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ece:	ffffc097          	auipc	ra,0xffffc
    80004ed2:	d16080e7          	jalr	-746(ra) # 80000be4 <acquire>
  if(writable){
    80004ed6:	02090d63          	beqz	s2,80004f10 <pipeclose+0x52>
    pi->writeopen = 0;
    80004eda:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ede:	21848513          	addi	a0,s1,536
    80004ee2:	ffffd097          	auipc	ra,0xffffd
    80004ee6:	7f4080e7          	jalr	2036(ra) # 800026d6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004eea:	2204b783          	ld	a5,544(s1)
    80004eee:	eb95                	bnez	a5,80004f22 <pipeclose+0x64>
    release(&pi->lock);
    80004ef0:	8526                	mv	a0,s1
    80004ef2:	ffffc097          	auipc	ra,0xffffc
    80004ef6:	da6080e7          	jalr	-602(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004efa:	8526                	mv	a0,s1
    80004efc:	ffffc097          	auipc	ra,0xffffc
    80004f00:	afc080e7          	jalr	-1284(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004f04:	60e2                	ld	ra,24(sp)
    80004f06:	6442                	ld	s0,16(sp)
    80004f08:	64a2                	ld	s1,8(sp)
    80004f0a:	6902                	ld	s2,0(sp)
    80004f0c:	6105                	addi	sp,sp,32
    80004f0e:	8082                	ret
    pi->readopen = 0;
    80004f10:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f14:	21c48513          	addi	a0,s1,540
    80004f18:	ffffd097          	auipc	ra,0xffffd
    80004f1c:	7be080e7          	jalr	1982(ra) # 800026d6 <wakeup>
    80004f20:	b7e9                	j	80004eea <pipeclose+0x2c>
    release(&pi->lock);
    80004f22:	8526                	mv	a0,s1
    80004f24:	ffffc097          	auipc	ra,0xffffc
    80004f28:	d74080e7          	jalr	-652(ra) # 80000c98 <release>
}
    80004f2c:	bfe1                	j	80004f04 <pipeclose+0x46>

0000000080004f2e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f2e:	7159                	addi	sp,sp,-112
    80004f30:	f486                	sd	ra,104(sp)
    80004f32:	f0a2                	sd	s0,96(sp)
    80004f34:	eca6                	sd	s1,88(sp)
    80004f36:	e8ca                	sd	s2,80(sp)
    80004f38:	e4ce                	sd	s3,72(sp)
    80004f3a:	e0d2                	sd	s4,64(sp)
    80004f3c:	fc56                	sd	s5,56(sp)
    80004f3e:	f85a                	sd	s6,48(sp)
    80004f40:	f45e                	sd	s7,40(sp)
    80004f42:	f062                	sd	s8,32(sp)
    80004f44:	ec66                	sd	s9,24(sp)
    80004f46:	1880                	addi	s0,sp,112
    80004f48:	84aa                	mv	s1,a0
    80004f4a:	8aae                	mv	s5,a1
    80004f4c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f4e:	ffffd097          	auipc	ra,0xffffd
    80004f52:	dec080e7          	jalr	-532(ra) # 80001d3a <myproc>
    80004f56:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f58:	8526                	mv	a0,s1
    80004f5a:	ffffc097          	auipc	ra,0xffffc
    80004f5e:	c8a080e7          	jalr	-886(ra) # 80000be4 <acquire>
  while(i < n){
    80004f62:	0d405163          	blez	s4,80005024 <pipewrite+0xf6>
    80004f66:	8ba6                	mv	s7,s1
  int i = 0;
    80004f68:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f6a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f6c:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f70:	21c48c13          	addi	s8,s1,540
    80004f74:	a08d                	j	80004fd6 <pipewrite+0xa8>
      release(&pi->lock);
    80004f76:	8526                	mv	a0,s1
    80004f78:	ffffc097          	auipc	ra,0xffffc
    80004f7c:	d20080e7          	jalr	-736(ra) # 80000c98 <release>
      return -1;
    80004f80:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f82:	854a                	mv	a0,s2
    80004f84:	70a6                	ld	ra,104(sp)
    80004f86:	7406                	ld	s0,96(sp)
    80004f88:	64e6                	ld	s1,88(sp)
    80004f8a:	6946                	ld	s2,80(sp)
    80004f8c:	69a6                	ld	s3,72(sp)
    80004f8e:	6a06                	ld	s4,64(sp)
    80004f90:	7ae2                	ld	s5,56(sp)
    80004f92:	7b42                	ld	s6,48(sp)
    80004f94:	7ba2                	ld	s7,40(sp)
    80004f96:	7c02                	ld	s8,32(sp)
    80004f98:	6ce2                	ld	s9,24(sp)
    80004f9a:	6165                	addi	sp,sp,112
    80004f9c:	8082                	ret
      wakeup(&pi->nread);
    80004f9e:	8566                	mv	a0,s9
    80004fa0:	ffffd097          	auipc	ra,0xffffd
    80004fa4:	736080e7          	jalr	1846(ra) # 800026d6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004fa8:	85de                	mv	a1,s7
    80004faa:	8562                	mv	a0,s8
    80004fac:	ffffd097          	auipc	ra,0xffffd
    80004fb0:	58c080e7          	jalr	1420(ra) # 80002538 <sleep>
    80004fb4:	a839                	j	80004fd2 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004fb6:	21c4a783          	lw	a5,540(s1)
    80004fba:	0017871b          	addiw	a4,a5,1
    80004fbe:	20e4ae23          	sw	a4,540(s1)
    80004fc2:	1ff7f793          	andi	a5,a5,511
    80004fc6:	97a6                	add	a5,a5,s1
    80004fc8:	f9f44703          	lbu	a4,-97(s0)
    80004fcc:	00e78c23          	sb	a4,24(a5)
      i++;
    80004fd0:	2905                	addiw	s2,s2,1
  while(i < n){
    80004fd2:	03495d63          	bge	s2,s4,8000500c <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004fd6:	2204a783          	lw	a5,544(s1)
    80004fda:	dfd1                	beqz	a5,80004f76 <pipewrite+0x48>
    80004fdc:	0289a783          	lw	a5,40(s3)
    80004fe0:	fbd9                	bnez	a5,80004f76 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004fe2:	2184a783          	lw	a5,536(s1)
    80004fe6:	21c4a703          	lw	a4,540(s1)
    80004fea:	2007879b          	addiw	a5,a5,512
    80004fee:	faf708e3          	beq	a4,a5,80004f9e <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ff2:	4685                	li	a3,1
    80004ff4:	01590633          	add	a2,s2,s5
    80004ff8:	f9f40593          	addi	a1,s0,-97
    80004ffc:	0509b503          	ld	a0,80(s3)
    80005000:	ffffc097          	auipc	ra,0xffffc
    80005004:	6fe080e7          	jalr	1790(ra) # 800016fe <copyin>
    80005008:	fb6517e3          	bne	a0,s6,80004fb6 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000500c:	21848513          	addi	a0,s1,536
    80005010:	ffffd097          	auipc	ra,0xffffd
    80005014:	6c6080e7          	jalr	1734(ra) # 800026d6 <wakeup>
  release(&pi->lock);
    80005018:	8526                	mv	a0,s1
    8000501a:	ffffc097          	auipc	ra,0xffffc
    8000501e:	c7e080e7          	jalr	-898(ra) # 80000c98 <release>
  return i;
    80005022:	b785                	j	80004f82 <pipewrite+0x54>
  int i = 0;
    80005024:	4901                	li	s2,0
    80005026:	b7dd                	j	8000500c <pipewrite+0xde>

0000000080005028 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005028:	715d                	addi	sp,sp,-80
    8000502a:	e486                	sd	ra,72(sp)
    8000502c:	e0a2                	sd	s0,64(sp)
    8000502e:	fc26                	sd	s1,56(sp)
    80005030:	f84a                	sd	s2,48(sp)
    80005032:	f44e                	sd	s3,40(sp)
    80005034:	f052                	sd	s4,32(sp)
    80005036:	ec56                	sd	s5,24(sp)
    80005038:	e85a                	sd	s6,16(sp)
    8000503a:	0880                	addi	s0,sp,80
    8000503c:	84aa                	mv	s1,a0
    8000503e:	892e                	mv	s2,a1
    80005040:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005042:	ffffd097          	auipc	ra,0xffffd
    80005046:	cf8080e7          	jalr	-776(ra) # 80001d3a <myproc>
    8000504a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000504c:	8b26                	mv	s6,s1
    8000504e:	8526                	mv	a0,s1
    80005050:	ffffc097          	auipc	ra,0xffffc
    80005054:	b94080e7          	jalr	-1132(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005058:	2184a703          	lw	a4,536(s1)
    8000505c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005060:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005064:	02f71463          	bne	a4,a5,8000508c <piperead+0x64>
    80005068:	2244a783          	lw	a5,548(s1)
    8000506c:	c385                	beqz	a5,8000508c <piperead+0x64>
    if(pr->killed){
    8000506e:	028a2783          	lw	a5,40(s4)
    80005072:	ebc1                	bnez	a5,80005102 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005074:	85da                	mv	a1,s6
    80005076:	854e                	mv	a0,s3
    80005078:	ffffd097          	auipc	ra,0xffffd
    8000507c:	4c0080e7          	jalr	1216(ra) # 80002538 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005080:	2184a703          	lw	a4,536(s1)
    80005084:	21c4a783          	lw	a5,540(s1)
    80005088:	fef700e3          	beq	a4,a5,80005068 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000508c:	09505263          	blez	s5,80005110 <piperead+0xe8>
    80005090:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005092:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005094:	2184a783          	lw	a5,536(s1)
    80005098:	21c4a703          	lw	a4,540(s1)
    8000509c:	02f70d63          	beq	a4,a5,800050d6 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800050a0:	0017871b          	addiw	a4,a5,1
    800050a4:	20e4ac23          	sw	a4,536(s1)
    800050a8:	1ff7f793          	andi	a5,a5,511
    800050ac:	97a6                	add	a5,a5,s1
    800050ae:	0187c783          	lbu	a5,24(a5)
    800050b2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050b6:	4685                	li	a3,1
    800050b8:	fbf40613          	addi	a2,s0,-65
    800050bc:	85ca                	mv	a1,s2
    800050be:	050a3503          	ld	a0,80(s4)
    800050c2:	ffffc097          	auipc	ra,0xffffc
    800050c6:	5b0080e7          	jalr	1456(ra) # 80001672 <copyout>
    800050ca:	01650663          	beq	a0,s6,800050d6 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050ce:	2985                	addiw	s3,s3,1
    800050d0:	0905                	addi	s2,s2,1
    800050d2:	fd3a91e3          	bne	s5,s3,80005094 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050d6:	21c48513          	addi	a0,s1,540
    800050da:	ffffd097          	auipc	ra,0xffffd
    800050de:	5fc080e7          	jalr	1532(ra) # 800026d6 <wakeup>
  release(&pi->lock);
    800050e2:	8526                	mv	a0,s1
    800050e4:	ffffc097          	auipc	ra,0xffffc
    800050e8:	bb4080e7          	jalr	-1100(ra) # 80000c98 <release>
  return i;
}
    800050ec:	854e                	mv	a0,s3
    800050ee:	60a6                	ld	ra,72(sp)
    800050f0:	6406                	ld	s0,64(sp)
    800050f2:	74e2                	ld	s1,56(sp)
    800050f4:	7942                	ld	s2,48(sp)
    800050f6:	79a2                	ld	s3,40(sp)
    800050f8:	7a02                	ld	s4,32(sp)
    800050fa:	6ae2                	ld	s5,24(sp)
    800050fc:	6b42                	ld	s6,16(sp)
    800050fe:	6161                	addi	sp,sp,80
    80005100:	8082                	ret
      release(&pi->lock);
    80005102:	8526                	mv	a0,s1
    80005104:	ffffc097          	auipc	ra,0xffffc
    80005108:	b94080e7          	jalr	-1132(ra) # 80000c98 <release>
      return -1;
    8000510c:	59fd                	li	s3,-1
    8000510e:	bff9                	j	800050ec <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005110:	4981                	li	s3,0
    80005112:	b7d1                	j	800050d6 <piperead+0xae>

0000000080005114 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005114:	df010113          	addi	sp,sp,-528
    80005118:	20113423          	sd	ra,520(sp)
    8000511c:	20813023          	sd	s0,512(sp)
    80005120:	ffa6                	sd	s1,504(sp)
    80005122:	fbca                	sd	s2,496(sp)
    80005124:	f7ce                	sd	s3,488(sp)
    80005126:	f3d2                	sd	s4,480(sp)
    80005128:	efd6                	sd	s5,472(sp)
    8000512a:	ebda                	sd	s6,464(sp)
    8000512c:	e7de                	sd	s7,456(sp)
    8000512e:	e3e2                	sd	s8,448(sp)
    80005130:	ff66                	sd	s9,440(sp)
    80005132:	fb6a                	sd	s10,432(sp)
    80005134:	f76e                	sd	s11,424(sp)
    80005136:	0c00                	addi	s0,sp,528
    80005138:	84aa                	mv	s1,a0
    8000513a:	dea43c23          	sd	a0,-520(s0)
    8000513e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005142:	ffffd097          	auipc	ra,0xffffd
    80005146:	bf8080e7          	jalr	-1032(ra) # 80001d3a <myproc>
    8000514a:	892a                	mv	s2,a0

  begin_op();
    8000514c:	fffff097          	auipc	ra,0xfffff
    80005150:	49c080e7          	jalr	1180(ra) # 800045e8 <begin_op>

  if((ip = namei(path)) == 0){
    80005154:	8526                	mv	a0,s1
    80005156:	fffff097          	auipc	ra,0xfffff
    8000515a:	276080e7          	jalr	630(ra) # 800043cc <namei>
    8000515e:	c92d                	beqz	a0,800051d0 <exec+0xbc>
    80005160:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005162:	fffff097          	auipc	ra,0xfffff
    80005166:	ab4080e7          	jalr	-1356(ra) # 80003c16 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000516a:	04000713          	li	a4,64
    8000516e:	4681                	li	a3,0
    80005170:	e5040613          	addi	a2,s0,-432
    80005174:	4581                	li	a1,0
    80005176:	8526                	mv	a0,s1
    80005178:	fffff097          	auipc	ra,0xfffff
    8000517c:	d52080e7          	jalr	-686(ra) # 80003eca <readi>
    80005180:	04000793          	li	a5,64
    80005184:	00f51a63          	bne	a0,a5,80005198 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005188:	e5042703          	lw	a4,-432(s0)
    8000518c:	464c47b7          	lui	a5,0x464c4
    80005190:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005194:	04f70463          	beq	a4,a5,800051dc <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005198:	8526                	mv	a0,s1
    8000519a:	fffff097          	auipc	ra,0xfffff
    8000519e:	cde080e7          	jalr	-802(ra) # 80003e78 <iunlockput>
    end_op();
    800051a2:	fffff097          	auipc	ra,0xfffff
    800051a6:	4c6080e7          	jalr	1222(ra) # 80004668 <end_op>
  }
  return -1;
    800051aa:	557d                	li	a0,-1
}
    800051ac:	20813083          	ld	ra,520(sp)
    800051b0:	20013403          	ld	s0,512(sp)
    800051b4:	74fe                	ld	s1,504(sp)
    800051b6:	795e                	ld	s2,496(sp)
    800051b8:	79be                	ld	s3,488(sp)
    800051ba:	7a1e                	ld	s4,480(sp)
    800051bc:	6afe                	ld	s5,472(sp)
    800051be:	6b5e                	ld	s6,464(sp)
    800051c0:	6bbe                	ld	s7,456(sp)
    800051c2:	6c1e                	ld	s8,448(sp)
    800051c4:	7cfa                	ld	s9,440(sp)
    800051c6:	7d5a                	ld	s10,432(sp)
    800051c8:	7dba                	ld	s11,424(sp)
    800051ca:	21010113          	addi	sp,sp,528
    800051ce:	8082                	ret
    end_op();
    800051d0:	fffff097          	auipc	ra,0xfffff
    800051d4:	498080e7          	jalr	1176(ra) # 80004668 <end_op>
    return -1;
    800051d8:	557d                	li	a0,-1
    800051da:	bfc9                	j	800051ac <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800051dc:	854a                	mv	a0,s2
    800051de:	ffffd097          	auipc	ra,0xffffd
    800051e2:	c1a080e7          	jalr	-998(ra) # 80001df8 <proc_pagetable>
    800051e6:	8baa                	mv	s7,a0
    800051e8:	d945                	beqz	a0,80005198 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051ea:	e7042983          	lw	s3,-400(s0)
    800051ee:	e8845783          	lhu	a5,-376(s0)
    800051f2:	c7ad                	beqz	a5,8000525c <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051f4:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051f6:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800051f8:	6c85                	lui	s9,0x1
    800051fa:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800051fe:	def43823          	sd	a5,-528(s0)
    80005202:	a42d                	j	8000542c <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005204:	00003517          	auipc	a0,0x3
    80005208:	54c50513          	addi	a0,a0,1356 # 80008750 <syscalls+0x280>
    8000520c:	ffffb097          	auipc	ra,0xffffb
    80005210:	332080e7          	jalr	818(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005214:	8756                	mv	a4,s5
    80005216:	012d86bb          	addw	a3,s11,s2
    8000521a:	4581                	li	a1,0
    8000521c:	8526                	mv	a0,s1
    8000521e:	fffff097          	auipc	ra,0xfffff
    80005222:	cac080e7          	jalr	-852(ra) # 80003eca <readi>
    80005226:	2501                	sext.w	a0,a0
    80005228:	1aaa9963          	bne	s5,a0,800053da <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000522c:	6785                	lui	a5,0x1
    8000522e:	0127893b          	addw	s2,a5,s2
    80005232:	77fd                	lui	a5,0xfffff
    80005234:	01478a3b          	addw	s4,a5,s4
    80005238:	1f897163          	bgeu	s2,s8,8000541a <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000523c:	02091593          	slli	a1,s2,0x20
    80005240:	9181                	srli	a1,a1,0x20
    80005242:	95ea                	add	a1,a1,s10
    80005244:	855e                	mv	a0,s7
    80005246:	ffffc097          	auipc	ra,0xffffc
    8000524a:	e28080e7          	jalr	-472(ra) # 8000106e <walkaddr>
    8000524e:	862a                	mv	a2,a0
    if(pa == 0)
    80005250:	d955                	beqz	a0,80005204 <exec+0xf0>
      n = PGSIZE;
    80005252:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005254:	fd9a70e3          	bgeu	s4,s9,80005214 <exec+0x100>
      n = sz - i;
    80005258:	8ad2                	mv	s5,s4
    8000525a:	bf6d                	j	80005214 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000525c:	4901                	li	s2,0
  iunlockput(ip);
    8000525e:	8526                	mv	a0,s1
    80005260:	fffff097          	auipc	ra,0xfffff
    80005264:	c18080e7          	jalr	-1000(ra) # 80003e78 <iunlockput>
  end_op();
    80005268:	fffff097          	auipc	ra,0xfffff
    8000526c:	400080e7          	jalr	1024(ra) # 80004668 <end_op>
  p = myproc();
    80005270:	ffffd097          	auipc	ra,0xffffd
    80005274:	aca080e7          	jalr	-1334(ra) # 80001d3a <myproc>
    80005278:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000527a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000527e:	6785                	lui	a5,0x1
    80005280:	17fd                	addi	a5,a5,-1
    80005282:	993e                	add	s2,s2,a5
    80005284:	757d                	lui	a0,0xfffff
    80005286:	00a977b3          	and	a5,s2,a0
    8000528a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000528e:	6609                	lui	a2,0x2
    80005290:	963e                	add	a2,a2,a5
    80005292:	85be                	mv	a1,a5
    80005294:	855e                	mv	a0,s7
    80005296:	ffffc097          	auipc	ra,0xffffc
    8000529a:	18c080e7          	jalr	396(ra) # 80001422 <uvmalloc>
    8000529e:	8b2a                	mv	s6,a0
  ip = 0;
    800052a0:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800052a2:	12050c63          	beqz	a0,800053da <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052a6:	75f9                	lui	a1,0xffffe
    800052a8:	95aa                	add	a1,a1,a0
    800052aa:	855e                	mv	a0,s7
    800052ac:	ffffc097          	auipc	ra,0xffffc
    800052b0:	394080e7          	jalr	916(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800052b4:	7c7d                	lui	s8,0xfffff
    800052b6:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800052b8:	e0043783          	ld	a5,-512(s0)
    800052bc:	6388                	ld	a0,0(a5)
    800052be:	c535                	beqz	a0,8000532a <exec+0x216>
    800052c0:	e9040993          	addi	s3,s0,-368
    800052c4:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800052c8:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800052ca:	ffffc097          	auipc	ra,0xffffc
    800052ce:	b9a080e7          	jalr	-1126(ra) # 80000e64 <strlen>
    800052d2:	2505                	addiw	a0,a0,1
    800052d4:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800052d8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800052dc:	13896363          	bltu	s2,s8,80005402 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800052e0:	e0043d83          	ld	s11,-512(s0)
    800052e4:	000dba03          	ld	s4,0(s11)
    800052e8:	8552                	mv	a0,s4
    800052ea:	ffffc097          	auipc	ra,0xffffc
    800052ee:	b7a080e7          	jalr	-1158(ra) # 80000e64 <strlen>
    800052f2:	0015069b          	addiw	a3,a0,1
    800052f6:	8652                	mv	a2,s4
    800052f8:	85ca                	mv	a1,s2
    800052fa:	855e                	mv	a0,s7
    800052fc:	ffffc097          	auipc	ra,0xffffc
    80005300:	376080e7          	jalr	886(ra) # 80001672 <copyout>
    80005304:	10054363          	bltz	a0,8000540a <exec+0x2f6>
    ustack[argc] = sp;
    80005308:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000530c:	0485                	addi	s1,s1,1
    8000530e:	008d8793          	addi	a5,s11,8
    80005312:	e0f43023          	sd	a5,-512(s0)
    80005316:	008db503          	ld	a0,8(s11)
    8000531a:	c911                	beqz	a0,8000532e <exec+0x21a>
    if(argc >= MAXARG)
    8000531c:	09a1                	addi	s3,s3,8
    8000531e:	fb3c96e3          	bne	s9,s3,800052ca <exec+0x1b6>
  sz = sz1;
    80005322:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005326:	4481                	li	s1,0
    80005328:	a84d                	j	800053da <exec+0x2c6>
  sp = sz;
    8000532a:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000532c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000532e:	00349793          	slli	a5,s1,0x3
    80005332:	f9040713          	addi	a4,s0,-112
    80005336:	97ba                	add	a5,a5,a4
    80005338:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000533c:	00148693          	addi	a3,s1,1
    80005340:	068e                	slli	a3,a3,0x3
    80005342:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005346:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000534a:	01897663          	bgeu	s2,s8,80005356 <exec+0x242>
  sz = sz1;
    8000534e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005352:	4481                	li	s1,0
    80005354:	a059                	j	800053da <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005356:	e9040613          	addi	a2,s0,-368
    8000535a:	85ca                	mv	a1,s2
    8000535c:	855e                	mv	a0,s7
    8000535e:	ffffc097          	auipc	ra,0xffffc
    80005362:	314080e7          	jalr	788(ra) # 80001672 <copyout>
    80005366:	0a054663          	bltz	a0,80005412 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000536a:	058ab783          	ld	a5,88(s5)
    8000536e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005372:	df843783          	ld	a5,-520(s0)
    80005376:	0007c703          	lbu	a4,0(a5)
    8000537a:	cf11                	beqz	a4,80005396 <exec+0x282>
    8000537c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000537e:	02f00693          	li	a3,47
    80005382:	a039                	j	80005390 <exec+0x27c>
      last = s+1;
    80005384:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005388:	0785                	addi	a5,a5,1
    8000538a:	fff7c703          	lbu	a4,-1(a5)
    8000538e:	c701                	beqz	a4,80005396 <exec+0x282>
    if(*s == '/')
    80005390:	fed71ce3          	bne	a4,a3,80005388 <exec+0x274>
    80005394:	bfc5                	j	80005384 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005396:	4641                	li	a2,16
    80005398:	df843583          	ld	a1,-520(s0)
    8000539c:	158a8513          	addi	a0,s5,344
    800053a0:	ffffc097          	auipc	ra,0xffffc
    800053a4:	a92080e7          	jalr	-1390(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800053a8:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800053ac:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800053b0:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800053b4:	058ab783          	ld	a5,88(s5)
    800053b8:	e6843703          	ld	a4,-408(s0)
    800053bc:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800053be:	058ab783          	ld	a5,88(s5)
    800053c2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800053c6:	85ea                	mv	a1,s10
    800053c8:	ffffd097          	auipc	ra,0xffffd
    800053cc:	acc080e7          	jalr	-1332(ra) # 80001e94 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800053d0:	0004851b          	sext.w	a0,s1
    800053d4:	bbe1                	j	800051ac <exec+0x98>
    800053d6:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800053da:	e0843583          	ld	a1,-504(s0)
    800053de:	855e                	mv	a0,s7
    800053e0:	ffffd097          	auipc	ra,0xffffd
    800053e4:	ab4080e7          	jalr	-1356(ra) # 80001e94 <proc_freepagetable>
  if(ip){
    800053e8:	da0498e3          	bnez	s1,80005198 <exec+0x84>
  return -1;
    800053ec:	557d                	li	a0,-1
    800053ee:	bb7d                	j	800051ac <exec+0x98>
    800053f0:	e1243423          	sd	s2,-504(s0)
    800053f4:	b7dd                	j	800053da <exec+0x2c6>
    800053f6:	e1243423          	sd	s2,-504(s0)
    800053fa:	b7c5                	j	800053da <exec+0x2c6>
    800053fc:	e1243423          	sd	s2,-504(s0)
    80005400:	bfe9                	j	800053da <exec+0x2c6>
  sz = sz1;
    80005402:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005406:	4481                	li	s1,0
    80005408:	bfc9                	j	800053da <exec+0x2c6>
  sz = sz1;
    8000540a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000540e:	4481                	li	s1,0
    80005410:	b7e9                	j	800053da <exec+0x2c6>
  sz = sz1;
    80005412:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005416:	4481                	li	s1,0
    80005418:	b7c9                	j	800053da <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000541a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000541e:	2b05                	addiw	s6,s6,1
    80005420:	0389899b          	addiw	s3,s3,56
    80005424:	e8845783          	lhu	a5,-376(s0)
    80005428:	e2fb5be3          	bge	s6,a5,8000525e <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000542c:	2981                	sext.w	s3,s3
    8000542e:	03800713          	li	a4,56
    80005432:	86ce                	mv	a3,s3
    80005434:	e1840613          	addi	a2,s0,-488
    80005438:	4581                	li	a1,0
    8000543a:	8526                	mv	a0,s1
    8000543c:	fffff097          	auipc	ra,0xfffff
    80005440:	a8e080e7          	jalr	-1394(ra) # 80003eca <readi>
    80005444:	03800793          	li	a5,56
    80005448:	f8f517e3          	bne	a0,a5,800053d6 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000544c:	e1842783          	lw	a5,-488(s0)
    80005450:	4705                	li	a4,1
    80005452:	fce796e3          	bne	a5,a4,8000541e <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005456:	e4043603          	ld	a2,-448(s0)
    8000545a:	e3843783          	ld	a5,-456(s0)
    8000545e:	f8f669e3          	bltu	a2,a5,800053f0 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005462:	e2843783          	ld	a5,-472(s0)
    80005466:	963e                	add	a2,a2,a5
    80005468:	f8f667e3          	bltu	a2,a5,800053f6 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000546c:	85ca                	mv	a1,s2
    8000546e:	855e                	mv	a0,s7
    80005470:	ffffc097          	auipc	ra,0xffffc
    80005474:	fb2080e7          	jalr	-78(ra) # 80001422 <uvmalloc>
    80005478:	e0a43423          	sd	a0,-504(s0)
    8000547c:	d141                	beqz	a0,800053fc <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000547e:	e2843d03          	ld	s10,-472(s0)
    80005482:	df043783          	ld	a5,-528(s0)
    80005486:	00fd77b3          	and	a5,s10,a5
    8000548a:	fba1                	bnez	a5,800053da <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000548c:	e2042d83          	lw	s11,-480(s0)
    80005490:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005494:	f80c03e3          	beqz	s8,8000541a <exec+0x306>
    80005498:	8a62                	mv	s4,s8
    8000549a:	4901                	li	s2,0
    8000549c:	b345                	j	8000523c <exec+0x128>

000000008000549e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000549e:	7179                	addi	sp,sp,-48
    800054a0:	f406                	sd	ra,40(sp)
    800054a2:	f022                	sd	s0,32(sp)
    800054a4:	ec26                	sd	s1,24(sp)
    800054a6:	e84a                	sd	s2,16(sp)
    800054a8:	1800                	addi	s0,sp,48
    800054aa:	892e                	mv	s2,a1
    800054ac:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800054ae:	fdc40593          	addi	a1,s0,-36
    800054b2:	ffffe097          	auipc	ra,0xffffe
    800054b6:	bf2080e7          	jalr	-1038(ra) # 800030a4 <argint>
    800054ba:	04054063          	bltz	a0,800054fa <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800054be:	fdc42703          	lw	a4,-36(s0)
    800054c2:	47bd                	li	a5,15
    800054c4:	02e7ed63          	bltu	a5,a4,800054fe <argfd+0x60>
    800054c8:	ffffd097          	auipc	ra,0xffffd
    800054cc:	872080e7          	jalr	-1934(ra) # 80001d3a <myproc>
    800054d0:	fdc42703          	lw	a4,-36(s0)
    800054d4:	01a70793          	addi	a5,a4,26
    800054d8:	078e                	slli	a5,a5,0x3
    800054da:	953e                	add	a0,a0,a5
    800054dc:	611c                	ld	a5,0(a0)
    800054de:	c395                	beqz	a5,80005502 <argfd+0x64>
    return -1;
  if(pfd)
    800054e0:	00090463          	beqz	s2,800054e8 <argfd+0x4a>
    *pfd = fd;
    800054e4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800054e8:	4501                	li	a0,0
  if(pf)
    800054ea:	c091                	beqz	s1,800054ee <argfd+0x50>
    *pf = f;
    800054ec:	e09c                	sd	a5,0(s1)
}
    800054ee:	70a2                	ld	ra,40(sp)
    800054f0:	7402                	ld	s0,32(sp)
    800054f2:	64e2                	ld	s1,24(sp)
    800054f4:	6942                	ld	s2,16(sp)
    800054f6:	6145                	addi	sp,sp,48
    800054f8:	8082                	ret
    return -1;
    800054fa:	557d                	li	a0,-1
    800054fc:	bfcd                	j	800054ee <argfd+0x50>
    return -1;
    800054fe:	557d                	li	a0,-1
    80005500:	b7fd                	j	800054ee <argfd+0x50>
    80005502:	557d                	li	a0,-1
    80005504:	b7ed                	j	800054ee <argfd+0x50>

0000000080005506 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005506:	1101                	addi	sp,sp,-32
    80005508:	ec06                	sd	ra,24(sp)
    8000550a:	e822                	sd	s0,16(sp)
    8000550c:	e426                	sd	s1,8(sp)
    8000550e:	1000                	addi	s0,sp,32
    80005510:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005512:	ffffd097          	auipc	ra,0xffffd
    80005516:	828080e7          	jalr	-2008(ra) # 80001d3a <myproc>
    8000551a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000551c:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005520:	4501                	li	a0,0
    80005522:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005524:	6398                	ld	a4,0(a5)
    80005526:	cb19                	beqz	a4,8000553c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005528:	2505                	addiw	a0,a0,1
    8000552a:	07a1                	addi	a5,a5,8
    8000552c:	fed51ce3          	bne	a0,a3,80005524 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005530:	557d                	li	a0,-1
}
    80005532:	60e2                	ld	ra,24(sp)
    80005534:	6442                	ld	s0,16(sp)
    80005536:	64a2                	ld	s1,8(sp)
    80005538:	6105                	addi	sp,sp,32
    8000553a:	8082                	ret
      p->ofile[fd] = f;
    8000553c:	01a50793          	addi	a5,a0,26
    80005540:	078e                	slli	a5,a5,0x3
    80005542:	963e                	add	a2,a2,a5
    80005544:	e204                	sd	s1,0(a2)
      return fd;
    80005546:	b7f5                	j	80005532 <fdalloc+0x2c>

0000000080005548 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005548:	715d                	addi	sp,sp,-80
    8000554a:	e486                	sd	ra,72(sp)
    8000554c:	e0a2                	sd	s0,64(sp)
    8000554e:	fc26                	sd	s1,56(sp)
    80005550:	f84a                	sd	s2,48(sp)
    80005552:	f44e                	sd	s3,40(sp)
    80005554:	f052                	sd	s4,32(sp)
    80005556:	ec56                	sd	s5,24(sp)
    80005558:	0880                	addi	s0,sp,80
    8000555a:	89ae                	mv	s3,a1
    8000555c:	8ab2                	mv	s5,a2
    8000555e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005560:	fb040593          	addi	a1,s0,-80
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	e86080e7          	jalr	-378(ra) # 800043ea <nameiparent>
    8000556c:	892a                	mv	s2,a0
    8000556e:	12050f63          	beqz	a0,800056ac <create+0x164>
    return 0;

  ilock(dp);
    80005572:	ffffe097          	auipc	ra,0xffffe
    80005576:	6a4080e7          	jalr	1700(ra) # 80003c16 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000557a:	4601                	li	a2,0
    8000557c:	fb040593          	addi	a1,s0,-80
    80005580:	854a                	mv	a0,s2
    80005582:	fffff097          	auipc	ra,0xfffff
    80005586:	b78080e7          	jalr	-1160(ra) # 800040fa <dirlookup>
    8000558a:	84aa                	mv	s1,a0
    8000558c:	c921                	beqz	a0,800055dc <create+0x94>
    iunlockput(dp);
    8000558e:	854a                	mv	a0,s2
    80005590:	fffff097          	auipc	ra,0xfffff
    80005594:	8e8080e7          	jalr	-1816(ra) # 80003e78 <iunlockput>
    ilock(ip);
    80005598:	8526                	mv	a0,s1
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	67c080e7          	jalr	1660(ra) # 80003c16 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800055a2:	2981                	sext.w	s3,s3
    800055a4:	4789                	li	a5,2
    800055a6:	02f99463          	bne	s3,a5,800055ce <create+0x86>
    800055aa:	0444d783          	lhu	a5,68(s1)
    800055ae:	37f9                	addiw	a5,a5,-2
    800055b0:	17c2                	slli	a5,a5,0x30
    800055b2:	93c1                	srli	a5,a5,0x30
    800055b4:	4705                	li	a4,1
    800055b6:	00f76c63          	bltu	a4,a5,800055ce <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800055ba:	8526                	mv	a0,s1
    800055bc:	60a6                	ld	ra,72(sp)
    800055be:	6406                	ld	s0,64(sp)
    800055c0:	74e2                	ld	s1,56(sp)
    800055c2:	7942                	ld	s2,48(sp)
    800055c4:	79a2                	ld	s3,40(sp)
    800055c6:	7a02                	ld	s4,32(sp)
    800055c8:	6ae2                	ld	s5,24(sp)
    800055ca:	6161                	addi	sp,sp,80
    800055cc:	8082                	ret
    iunlockput(ip);
    800055ce:	8526                	mv	a0,s1
    800055d0:	fffff097          	auipc	ra,0xfffff
    800055d4:	8a8080e7          	jalr	-1880(ra) # 80003e78 <iunlockput>
    return 0;
    800055d8:	4481                	li	s1,0
    800055da:	b7c5                	j	800055ba <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800055dc:	85ce                	mv	a1,s3
    800055de:	00092503          	lw	a0,0(s2)
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	49c080e7          	jalr	1180(ra) # 80003a7e <ialloc>
    800055ea:	84aa                	mv	s1,a0
    800055ec:	c529                	beqz	a0,80005636 <create+0xee>
  ilock(ip);
    800055ee:	ffffe097          	auipc	ra,0xffffe
    800055f2:	628080e7          	jalr	1576(ra) # 80003c16 <ilock>
  ip->major = major;
    800055f6:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800055fa:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800055fe:	4785                	li	a5,1
    80005600:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005604:	8526                	mv	a0,s1
    80005606:	ffffe097          	auipc	ra,0xffffe
    8000560a:	546080e7          	jalr	1350(ra) # 80003b4c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000560e:	2981                	sext.w	s3,s3
    80005610:	4785                	li	a5,1
    80005612:	02f98a63          	beq	s3,a5,80005646 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005616:	40d0                	lw	a2,4(s1)
    80005618:	fb040593          	addi	a1,s0,-80
    8000561c:	854a                	mv	a0,s2
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	cec080e7          	jalr	-788(ra) # 8000430a <dirlink>
    80005626:	06054b63          	bltz	a0,8000569c <create+0x154>
  iunlockput(dp);
    8000562a:	854a                	mv	a0,s2
    8000562c:	fffff097          	auipc	ra,0xfffff
    80005630:	84c080e7          	jalr	-1972(ra) # 80003e78 <iunlockput>
  return ip;
    80005634:	b759                	j	800055ba <create+0x72>
    panic("create: ialloc");
    80005636:	00003517          	auipc	a0,0x3
    8000563a:	13a50513          	addi	a0,a0,314 # 80008770 <syscalls+0x2a0>
    8000563e:	ffffb097          	auipc	ra,0xffffb
    80005642:	f00080e7          	jalr	-256(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005646:	04a95783          	lhu	a5,74(s2)
    8000564a:	2785                	addiw	a5,a5,1
    8000564c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005650:	854a                	mv	a0,s2
    80005652:	ffffe097          	auipc	ra,0xffffe
    80005656:	4fa080e7          	jalr	1274(ra) # 80003b4c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000565a:	40d0                	lw	a2,4(s1)
    8000565c:	00003597          	auipc	a1,0x3
    80005660:	12458593          	addi	a1,a1,292 # 80008780 <syscalls+0x2b0>
    80005664:	8526                	mv	a0,s1
    80005666:	fffff097          	auipc	ra,0xfffff
    8000566a:	ca4080e7          	jalr	-860(ra) # 8000430a <dirlink>
    8000566e:	00054f63          	bltz	a0,8000568c <create+0x144>
    80005672:	00492603          	lw	a2,4(s2)
    80005676:	00003597          	auipc	a1,0x3
    8000567a:	11258593          	addi	a1,a1,274 # 80008788 <syscalls+0x2b8>
    8000567e:	8526                	mv	a0,s1
    80005680:	fffff097          	auipc	ra,0xfffff
    80005684:	c8a080e7          	jalr	-886(ra) # 8000430a <dirlink>
    80005688:	f80557e3          	bgez	a0,80005616 <create+0xce>
      panic("create dots");
    8000568c:	00003517          	auipc	a0,0x3
    80005690:	10450513          	addi	a0,a0,260 # 80008790 <syscalls+0x2c0>
    80005694:	ffffb097          	auipc	ra,0xffffb
    80005698:	eaa080e7          	jalr	-342(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000569c:	00003517          	auipc	a0,0x3
    800056a0:	10450513          	addi	a0,a0,260 # 800087a0 <syscalls+0x2d0>
    800056a4:	ffffb097          	auipc	ra,0xffffb
    800056a8:	e9a080e7          	jalr	-358(ra) # 8000053e <panic>
    return 0;
    800056ac:	84aa                	mv	s1,a0
    800056ae:	b731                	j	800055ba <create+0x72>

00000000800056b0 <sys_dup>:
{
    800056b0:	7179                	addi	sp,sp,-48
    800056b2:	f406                	sd	ra,40(sp)
    800056b4:	f022                	sd	s0,32(sp)
    800056b6:	ec26                	sd	s1,24(sp)
    800056b8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800056ba:	fd840613          	addi	a2,s0,-40
    800056be:	4581                	li	a1,0
    800056c0:	4501                	li	a0,0
    800056c2:	00000097          	auipc	ra,0x0
    800056c6:	ddc080e7          	jalr	-548(ra) # 8000549e <argfd>
    return -1;
    800056ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800056cc:	02054363          	bltz	a0,800056f2 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800056d0:	fd843503          	ld	a0,-40(s0)
    800056d4:	00000097          	auipc	ra,0x0
    800056d8:	e32080e7          	jalr	-462(ra) # 80005506 <fdalloc>
    800056dc:	84aa                	mv	s1,a0
    return -1;
    800056de:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800056e0:	00054963          	bltz	a0,800056f2 <sys_dup+0x42>
  filedup(f);
    800056e4:	fd843503          	ld	a0,-40(s0)
    800056e8:	fffff097          	auipc	ra,0xfffff
    800056ec:	37a080e7          	jalr	890(ra) # 80004a62 <filedup>
  return fd;
    800056f0:	87a6                	mv	a5,s1
}
    800056f2:	853e                	mv	a0,a5
    800056f4:	70a2                	ld	ra,40(sp)
    800056f6:	7402                	ld	s0,32(sp)
    800056f8:	64e2                	ld	s1,24(sp)
    800056fa:	6145                	addi	sp,sp,48
    800056fc:	8082                	ret

00000000800056fe <sys_read>:
{
    800056fe:	7179                	addi	sp,sp,-48
    80005700:	f406                	sd	ra,40(sp)
    80005702:	f022                	sd	s0,32(sp)
    80005704:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005706:	fe840613          	addi	a2,s0,-24
    8000570a:	4581                	li	a1,0
    8000570c:	4501                	li	a0,0
    8000570e:	00000097          	auipc	ra,0x0
    80005712:	d90080e7          	jalr	-624(ra) # 8000549e <argfd>
    return -1;
    80005716:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005718:	04054163          	bltz	a0,8000575a <sys_read+0x5c>
    8000571c:	fe440593          	addi	a1,s0,-28
    80005720:	4509                	li	a0,2
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	982080e7          	jalr	-1662(ra) # 800030a4 <argint>
    return -1;
    8000572a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000572c:	02054763          	bltz	a0,8000575a <sys_read+0x5c>
    80005730:	fd840593          	addi	a1,s0,-40
    80005734:	4505                	li	a0,1
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	990080e7          	jalr	-1648(ra) # 800030c6 <argaddr>
    return -1;
    8000573e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005740:	00054d63          	bltz	a0,8000575a <sys_read+0x5c>
  return fileread(f, p, n);
    80005744:	fe442603          	lw	a2,-28(s0)
    80005748:	fd843583          	ld	a1,-40(s0)
    8000574c:	fe843503          	ld	a0,-24(s0)
    80005750:	fffff097          	auipc	ra,0xfffff
    80005754:	49e080e7          	jalr	1182(ra) # 80004bee <fileread>
    80005758:	87aa                	mv	a5,a0
}
    8000575a:	853e                	mv	a0,a5
    8000575c:	70a2                	ld	ra,40(sp)
    8000575e:	7402                	ld	s0,32(sp)
    80005760:	6145                	addi	sp,sp,48
    80005762:	8082                	ret

0000000080005764 <sys_write>:
{
    80005764:	7179                	addi	sp,sp,-48
    80005766:	f406                	sd	ra,40(sp)
    80005768:	f022                	sd	s0,32(sp)
    8000576a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000576c:	fe840613          	addi	a2,s0,-24
    80005770:	4581                	li	a1,0
    80005772:	4501                	li	a0,0
    80005774:	00000097          	auipc	ra,0x0
    80005778:	d2a080e7          	jalr	-726(ra) # 8000549e <argfd>
    return -1;
    8000577c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000577e:	04054163          	bltz	a0,800057c0 <sys_write+0x5c>
    80005782:	fe440593          	addi	a1,s0,-28
    80005786:	4509                	li	a0,2
    80005788:	ffffe097          	auipc	ra,0xffffe
    8000578c:	91c080e7          	jalr	-1764(ra) # 800030a4 <argint>
    return -1;
    80005790:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005792:	02054763          	bltz	a0,800057c0 <sys_write+0x5c>
    80005796:	fd840593          	addi	a1,s0,-40
    8000579a:	4505                	li	a0,1
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	92a080e7          	jalr	-1750(ra) # 800030c6 <argaddr>
    return -1;
    800057a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057a6:	00054d63          	bltz	a0,800057c0 <sys_write+0x5c>
  return filewrite(f, p, n);
    800057aa:	fe442603          	lw	a2,-28(s0)
    800057ae:	fd843583          	ld	a1,-40(s0)
    800057b2:	fe843503          	ld	a0,-24(s0)
    800057b6:	fffff097          	auipc	ra,0xfffff
    800057ba:	4fa080e7          	jalr	1274(ra) # 80004cb0 <filewrite>
    800057be:	87aa                	mv	a5,a0
}
    800057c0:	853e                	mv	a0,a5
    800057c2:	70a2                	ld	ra,40(sp)
    800057c4:	7402                	ld	s0,32(sp)
    800057c6:	6145                	addi	sp,sp,48
    800057c8:	8082                	ret

00000000800057ca <sys_close>:
{
    800057ca:	1101                	addi	sp,sp,-32
    800057cc:	ec06                	sd	ra,24(sp)
    800057ce:	e822                	sd	s0,16(sp)
    800057d0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800057d2:	fe040613          	addi	a2,s0,-32
    800057d6:	fec40593          	addi	a1,s0,-20
    800057da:	4501                	li	a0,0
    800057dc:	00000097          	auipc	ra,0x0
    800057e0:	cc2080e7          	jalr	-830(ra) # 8000549e <argfd>
    return -1;
    800057e4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057e6:	02054463          	bltz	a0,8000580e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800057ea:	ffffc097          	auipc	ra,0xffffc
    800057ee:	550080e7          	jalr	1360(ra) # 80001d3a <myproc>
    800057f2:	fec42783          	lw	a5,-20(s0)
    800057f6:	07e9                	addi	a5,a5,26
    800057f8:	078e                	slli	a5,a5,0x3
    800057fa:	97aa                	add	a5,a5,a0
    800057fc:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005800:	fe043503          	ld	a0,-32(s0)
    80005804:	fffff097          	auipc	ra,0xfffff
    80005808:	2b0080e7          	jalr	688(ra) # 80004ab4 <fileclose>
  return 0;
    8000580c:	4781                	li	a5,0
}
    8000580e:	853e                	mv	a0,a5
    80005810:	60e2                	ld	ra,24(sp)
    80005812:	6442                	ld	s0,16(sp)
    80005814:	6105                	addi	sp,sp,32
    80005816:	8082                	ret

0000000080005818 <sys_fstat>:
{
    80005818:	1101                	addi	sp,sp,-32
    8000581a:	ec06                	sd	ra,24(sp)
    8000581c:	e822                	sd	s0,16(sp)
    8000581e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005820:	fe840613          	addi	a2,s0,-24
    80005824:	4581                	li	a1,0
    80005826:	4501                	li	a0,0
    80005828:	00000097          	auipc	ra,0x0
    8000582c:	c76080e7          	jalr	-906(ra) # 8000549e <argfd>
    return -1;
    80005830:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005832:	02054563          	bltz	a0,8000585c <sys_fstat+0x44>
    80005836:	fe040593          	addi	a1,s0,-32
    8000583a:	4505                	li	a0,1
    8000583c:	ffffe097          	auipc	ra,0xffffe
    80005840:	88a080e7          	jalr	-1910(ra) # 800030c6 <argaddr>
    return -1;
    80005844:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005846:	00054b63          	bltz	a0,8000585c <sys_fstat+0x44>
  return filestat(f, st);
    8000584a:	fe043583          	ld	a1,-32(s0)
    8000584e:	fe843503          	ld	a0,-24(s0)
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	32a080e7          	jalr	810(ra) # 80004b7c <filestat>
    8000585a:	87aa                	mv	a5,a0
}
    8000585c:	853e                	mv	a0,a5
    8000585e:	60e2                	ld	ra,24(sp)
    80005860:	6442                	ld	s0,16(sp)
    80005862:	6105                	addi	sp,sp,32
    80005864:	8082                	ret

0000000080005866 <sys_link>:
{
    80005866:	7169                	addi	sp,sp,-304
    80005868:	f606                	sd	ra,296(sp)
    8000586a:	f222                	sd	s0,288(sp)
    8000586c:	ee26                	sd	s1,280(sp)
    8000586e:	ea4a                	sd	s2,272(sp)
    80005870:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005872:	08000613          	li	a2,128
    80005876:	ed040593          	addi	a1,s0,-304
    8000587a:	4501                	li	a0,0
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	86c080e7          	jalr	-1940(ra) # 800030e8 <argstr>
    return -1;
    80005884:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005886:	10054e63          	bltz	a0,800059a2 <sys_link+0x13c>
    8000588a:	08000613          	li	a2,128
    8000588e:	f5040593          	addi	a1,s0,-176
    80005892:	4505                	li	a0,1
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	854080e7          	jalr	-1964(ra) # 800030e8 <argstr>
    return -1;
    8000589c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000589e:	10054263          	bltz	a0,800059a2 <sys_link+0x13c>
  begin_op();
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	d46080e7          	jalr	-698(ra) # 800045e8 <begin_op>
  if((ip = namei(old)) == 0){
    800058aa:	ed040513          	addi	a0,s0,-304
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	b1e080e7          	jalr	-1250(ra) # 800043cc <namei>
    800058b6:	84aa                	mv	s1,a0
    800058b8:	c551                	beqz	a0,80005944 <sys_link+0xde>
  ilock(ip);
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	35c080e7          	jalr	860(ra) # 80003c16 <ilock>
  if(ip->type == T_DIR){
    800058c2:	04449703          	lh	a4,68(s1)
    800058c6:	4785                	li	a5,1
    800058c8:	08f70463          	beq	a4,a5,80005950 <sys_link+0xea>
  ip->nlink++;
    800058cc:	04a4d783          	lhu	a5,74(s1)
    800058d0:	2785                	addiw	a5,a5,1
    800058d2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058d6:	8526                	mv	a0,s1
    800058d8:	ffffe097          	auipc	ra,0xffffe
    800058dc:	274080e7          	jalr	628(ra) # 80003b4c <iupdate>
  iunlock(ip);
    800058e0:	8526                	mv	a0,s1
    800058e2:	ffffe097          	auipc	ra,0xffffe
    800058e6:	3f6080e7          	jalr	1014(ra) # 80003cd8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058ea:	fd040593          	addi	a1,s0,-48
    800058ee:	f5040513          	addi	a0,s0,-176
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	af8080e7          	jalr	-1288(ra) # 800043ea <nameiparent>
    800058fa:	892a                	mv	s2,a0
    800058fc:	c935                	beqz	a0,80005970 <sys_link+0x10a>
  ilock(dp);
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	318080e7          	jalr	792(ra) # 80003c16 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005906:	00092703          	lw	a4,0(s2)
    8000590a:	409c                	lw	a5,0(s1)
    8000590c:	04f71d63          	bne	a4,a5,80005966 <sys_link+0x100>
    80005910:	40d0                	lw	a2,4(s1)
    80005912:	fd040593          	addi	a1,s0,-48
    80005916:	854a                	mv	a0,s2
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	9f2080e7          	jalr	-1550(ra) # 8000430a <dirlink>
    80005920:	04054363          	bltz	a0,80005966 <sys_link+0x100>
  iunlockput(dp);
    80005924:	854a                	mv	a0,s2
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	552080e7          	jalr	1362(ra) # 80003e78 <iunlockput>
  iput(ip);
    8000592e:	8526                	mv	a0,s1
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	4a0080e7          	jalr	1184(ra) # 80003dd0 <iput>
  end_op();
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	d30080e7          	jalr	-720(ra) # 80004668 <end_op>
  return 0;
    80005940:	4781                	li	a5,0
    80005942:	a085                	j	800059a2 <sys_link+0x13c>
    end_op();
    80005944:	fffff097          	auipc	ra,0xfffff
    80005948:	d24080e7          	jalr	-732(ra) # 80004668 <end_op>
    return -1;
    8000594c:	57fd                	li	a5,-1
    8000594e:	a891                	j	800059a2 <sys_link+0x13c>
    iunlockput(ip);
    80005950:	8526                	mv	a0,s1
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	526080e7          	jalr	1318(ra) # 80003e78 <iunlockput>
    end_op();
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	d0e080e7          	jalr	-754(ra) # 80004668 <end_op>
    return -1;
    80005962:	57fd                	li	a5,-1
    80005964:	a83d                	j	800059a2 <sys_link+0x13c>
    iunlockput(dp);
    80005966:	854a                	mv	a0,s2
    80005968:	ffffe097          	auipc	ra,0xffffe
    8000596c:	510080e7          	jalr	1296(ra) # 80003e78 <iunlockput>
  ilock(ip);
    80005970:	8526                	mv	a0,s1
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	2a4080e7          	jalr	676(ra) # 80003c16 <ilock>
  ip->nlink--;
    8000597a:	04a4d783          	lhu	a5,74(s1)
    8000597e:	37fd                	addiw	a5,a5,-1
    80005980:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005984:	8526                	mv	a0,s1
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	1c6080e7          	jalr	454(ra) # 80003b4c <iupdate>
  iunlockput(ip);
    8000598e:	8526                	mv	a0,s1
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	4e8080e7          	jalr	1256(ra) # 80003e78 <iunlockput>
  end_op();
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	cd0080e7          	jalr	-816(ra) # 80004668 <end_op>
  return -1;
    800059a0:	57fd                	li	a5,-1
}
    800059a2:	853e                	mv	a0,a5
    800059a4:	70b2                	ld	ra,296(sp)
    800059a6:	7412                	ld	s0,288(sp)
    800059a8:	64f2                	ld	s1,280(sp)
    800059aa:	6952                	ld	s2,272(sp)
    800059ac:	6155                	addi	sp,sp,304
    800059ae:	8082                	ret

00000000800059b0 <sys_unlink>:
{
    800059b0:	7151                	addi	sp,sp,-240
    800059b2:	f586                	sd	ra,232(sp)
    800059b4:	f1a2                	sd	s0,224(sp)
    800059b6:	eda6                	sd	s1,216(sp)
    800059b8:	e9ca                	sd	s2,208(sp)
    800059ba:	e5ce                	sd	s3,200(sp)
    800059bc:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800059be:	08000613          	li	a2,128
    800059c2:	f3040593          	addi	a1,s0,-208
    800059c6:	4501                	li	a0,0
    800059c8:	ffffd097          	auipc	ra,0xffffd
    800059cc:	720080e7          	jalr	1824(ra) # 800030e8 <argstr>
    800059d0:	18054163          	bltz	a0,80005b52 <sys_unlink+0x1a2>
  begin_op();
    800059d4:	fffff097          	auipc	ra,0xfffff
    800059d8:	c14080e7          	jalr	-1004(ra) # 800045e8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800059dc:	fb040593          	addi	a1,s0,-80
    800059e0:	f3040513          	addi	a0,s0,-208
    800059e4:	fffff097          	auipc	ra,0xfffff
    800059e8:	a06080e7          	jalr	-1530(ra) # 800043ea <nameiparent>
    800059ec:	84aa                	mv	s1,a0
    800059ee:	c979                	beqz	a0,80005ac4 <sys_unlink+0x114>
  ilock(dp);
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	226080e7          	jalr	550(ra) # 80003c16 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800059f8:	00003597          	auipc	a1,0x3
    800059fc:	d8858593          	addi	a1,a1,-632 # 80008780 <syscalls+0x2b0>
    80005a00:	fb040513          	addi	a0,s0,-80
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	6dc080e7          	jalr	1756(ra) # 800040e0 <namecmp>
    80005a0c:	14050a63          	beqz	a0,80005b60 <sys_unlink+0x1b0>
    80005a10:	00003597          	auipc	a1,0x3
    80005a14:	d7858593          	addi	a1,a1,-648 # 80008788 <syscalls+0x2b8>
    80005a18:	fb040513          	addi	a0,s0,-80
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	6c4080e7          	jalr	1732(ra) # 800040e0 <namecmp>
    80005a24:	12050e63          	beqz	a0,80005b60 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a28:	f2c40613          	addi	a2,s0,-212
    80005a2c:	fb040593          	addi	a1,s0,-80
    80005a30:	8526                	mv	a0,s1
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	6c8080e7          	jalr	1736(ra) # 800040fa <dirlookup>
    80005a3a:	892a                	mv	s2,a0
    80005a3c:	12050263          	beqz	a0,80005b60 <sys_unlink+0x1b0>
  ilock(ip);
    80005a40:	ffffe097          	auipc	ra,0xffffe
    80005a44:	1d6080e7          	jalr	470(ra) # 80003c16 <ilock>
  if(ip->nlink < 1)
    80005a48:	04a91783          	lh	a5,74(s2)
    80005a4c:	08f05263          	blez	a5,80005ad0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a50:	04491703          	lh	a4,68(s2)
    80005a54:	4785                	li	a5,1
    80005a56:	08f70563          	beq	a4,a5,80005ae0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a5a:	4641                	li	a2,16
    80005a5c:	4581                	li	a1,0
    80005a5e:	fc040513          	addi	a0,s0,-64
    80005a62:	ffffb097          	auipc	ra,0xffffb
    80005a66:	27e080e7          	jalr	638(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a6a:	4741                	li	a4,16
    80005a6c:	f2c42683          	lw	a3,-212(s0)
    80005a70:	fc040613          	addi	a2,s0,-64
    80005a74:	4581                	li	a1,0
    80005a76:	8526                	mv	a0,s1
    80005a78:	ffffe097          	auipc	ra,0xffffe
    80005a7c:	54a080e7          	jalr	1354(ra) # 80003fc2 <writei>
    80005a80:	47c1                	li	a5,16
    80005a82:	0af51563          	bne	a0,a5,80005b2c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a86:	04491703          	lh	a4,68(s2)
    80005a8a:	4785                	li	a5,1
    80005a8c:	0af70863          	beq	a4,a5,80005b3c <sys_unlink+0x18c>
  iunlockput(dp);
    80005a90:	8526                	mv	a0,s1
    80005a92:	ffffe097          	auipc	ra,0xffffe
    80005a96:	3e6080e7          	jalr	998(ra) # 80003e78 <iunlockput>
  ip->nlink--;
    80005a9a:	04a95783          	lhu	a5,74(s2)
    80005a9e:	37fd                	addiw	a5,a5,-1
    80005aa0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005aa4:	854a                	mv	a0,s2
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	0a6080e7          	jalr	166(ra) # 80003b4c <iupdate>
  iunlockput(ip);
    80005aae:	854a                	mv	a0,s2
    80005ab0:	ffffe097          	auipc	ra,0xffffe
    80005ab4:	3c8080e7          	jalr	968(ra) # 80003e78 <iunlockput>
  end_op();
    80005ab8:	fffff097          	auipc	ra,0xfffff
    80005abc:	bb0080e7          	jalr	-1104(ra) # 80004668 <end_op>
  return 0;
    80005ac0:	4501                	li	a0,0
    80005ac2:	a84d                	j	80005b74 <sys_unlink+0x1c4>
    end_op();
    80005ac4:	fffff097          	auipc	ra,0xfffff
    80005ac8:	ba4080e7          	jalr	-1116(ra) # 80004668 <end_op>
    return -1;
    80005acc:	557d                	li	a0,-1
    80005ace:	a05d                	j	80005b74 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005ad0:	00003517          	auipc	a0,0x3
    80005ad4:	ce050513          	addi	a0,a0,-800 # 800087b0 <syscalls+0x2e0>
    80005ad8:	ffffb097          	auipc	ra,0xffffb
    80005adc:	a66080e7          	jalr	-1434(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ae0:	04c92703          	lw	a4,76(s2)
    80005ae4:	02000793          	li	a5,32
    80005ae8:	f6e7f9e3          	bgeu	a5,a4,80005a5a <sys_unlink+0xaa>
    80005aec:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005af0:	4741                	li	a4,16
    80005af2:	86ce                	mv	a3,s3
    80005af4:	f1840613          	addi	a2,s0,-232
    80005af8:	4581                	li	a1,0
    80005afa:	854a                	mv	a0,s2
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	3ce080e7          	jalr	974(ra) # 80003eca <readi>
    80005b04:	47c1                	li	a5,16
    80005b06:	00f51b63          	bne	a0,a5,80005b1c <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b0a:	f1845783          	lhu	a5,-232(s0)
    80005b0e:	e7a1                	bnez	a5,80005b56 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b10:	29c1                	addiw	s3,s3,16
    80005b12:	04c92783          	lw	a5,76(s2)
    80005b16:	fcf9ede3          	bltu	s3,a5,80005af0 <sys_unlink+0x140>
    80005b1a:	b781                	j	80005a5a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b1c:	00003517          	auipc	a0,0x3
    80005b20:	cac50513          	addi	a0,a0,-852 # 800087c8 <syscalls+0x2f8>
    80005b24:	ffffb097          	auipc	ra,0xffffb
    80005b28:	a1a080e7          	jalr	-1510(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005b2c:	00003517          	auipc	a0,0x3
    80005b30:	cb450513          	addi	a0,a0,-844 # 800087e0 <syscalls+0x310>
    80005b34:	ffffb097          	auipc	ra,0xffffb
    80005b38:	a0a080e7          	jalr	-1526(ra) # 8000053e <panic>
    dp->nlink--;
    80005b3c:	04a4d783          	lhu	a5,74(s1)
    80005b40:	37fd                	addiw	a5,a5,-1
    80005b42:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b46:	8526                	mv	a0,s1
    80005b48:	ffffe097          	auipc	ra,0xffffe
    80005b4c:	004080e7          	jalr	4(ra) # 80003b4c <iupdate>
    80005b50:	b781                	j	80005a90 <sys_unlink+0xe0>
    return -1;
    80005b52:	557d                	li	a0,-1
    80005b54:	a005                	j	80005b74 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b56:	854a                	mv	a0,s2
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	320080e7          	jalr	800(ra) # 80003e78 <iunlockput>
  iunlockput(dp);
    80005b60:	8526                	mv	a0,s1
    80005b62:	ffffe097          	auipc	ra,0xffffe
    80005b66:	316080e7          	jalr	790(ra) # 80003e78 <iunlockput>
  end_op();
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	afe080e7          	jalr	-1282(ra) # 80004668 <end_op>
  return -1;
    80005b72:	557d                	li	a0,-1
}
    80005b74:	70ae                	ld	ra,232(sp)
    80005b76:	740e                	ld	s0,224(sp)
    80005b78:	64ee                	ld	s1,216(sp)
    80005b7a:	694e                	ld	s2,208(sp)
    80005b7c:	69ae                	ld	s3,200(sp)
    80005b7e:	616d                	addi	sp,sp,240
    80005b80:	8082                	ret

0000000080005b82 <sys_open>:

uint64
sys_open(void)
{
    80005b82:	7131                	addi	sp,sp,-192
    80005b84:	fd06                	sd	ra,184(sp)
    80005b86:	f922                	sd	s0,176(sp)
    80005b88:	f526                	sd	s1,168(sp)
    80005b8a:	f14a                	sd	s2,160(sp)
    80005b8c:	ed4e                	sd	s3,152(sp)
    80005b8e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b90:	08000613          	li	a2,128
    80005b94:	f5040593          	addi	a1,s0,-176
    80005b98:	4501                	li	a0,0
    80005b9a:	ffffd097          	auipc	ra,0xffffd
    80005b9e:	54e080e7          	jalr	1358(ra) # 800030e8 <argstr>
    return -1;
    80005ba2:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ba4:	0c054163          	bltz	a0,80005c66 <sys_open+0xe4>
    80005ba8:	f4c40593          	addi	a1,s0,-180
    80005bac:	4505                	li	a0,1
    80005bae:	ffffd097          	auipc	ra,0xffffd
    80005bb2:	4f6080e7          	jalr	1270(ra) # 800030a4 <argint>
    80005bb6:	0a054863          	bltz	a0,80005c66 <sys_open+0xe4>

  begin_op();
    80005bba:	fffff097          	auipc	ra,0xfffff
    80005bbe:	a2e080e7          	jalr	-1490(ra) # 800045e8 <begin_op>

  if(omode & O_CREATE){
    80005bc2:	f4c42783          	lw	a5,-180(s0)
    80005bc6:	2007f793          	andi	a5,a5,512
    80005bca:	cbdd                	beqz	a5,80005c80 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005bcc:	4681                	li	a3,0
    80005bce:	4601                	li	a2,0
    80005bd0:	4589                	li	a1,2
    80005bd2:	f5040513          	addi	a0,s0,-176
    80005bd6:	00000097          	auipc	ra,0x0
    80005bda:	972080e7          	jalr	-1678(ra) # 80005548 <create>
    80005bde:	892a                	mv	s2,a0
    if(ip == 0){
    80005be0:	c959                	beqz	a0,80005c76 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005be2:	04491703          	lh	a4,68(s2)
    80005be6:	478d                	li	a5,3
    80005be8:	00f71763          	bne	a4,a5,80005bf6 <sys_open+0x74>
    80005bec:	04695703          	lhu	a4,70(s2)
    80005bf0:	47a5                	li	a5,9
    80005bf2:	0ce7ec63          	bltu	a5,a4,80005cca <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005bf6:	fffff097          	auipc	ra,0xfffff
    80005bfa:	e02080e7          	jalr	-510(ra) # 800049f8 <filealloc>
    80005bfe:	89aa                	mv	s3,a0
    80005c00:	10050263          	beqz	a0,80005d04 <sys_open+0x182>
    80005c04:	00000097          	auipc	ra,0x0
    80005c08:	902080e7          	jalr	-1790(ra) # 80005506 <fdalloc>
    80005c0c:	84aa                	mv	s1,a0
    80005c0e:	0e054663          	bltz	a0,80005cfa <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c12:	04491703          	lh	a4,68(s2)
    80005c16:	478d                	li	a5,3
    80005c18:	0cf70463          	beq	a4,a5,80005ce0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c1c:	4789                	li	a5,2
    80005c1e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c22:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c26:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c2a:	f4c42783          	lw	a5,-180(s0)
    80005c2e:	0017c713          	xori	a4,a5,1
    80005c32:	8b05                	andi	a4,a4,1
    80005c34:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c38:	0037f713          	andi	a4,a5,3
    80005c3c:	00e03733          	snez	a4,a4
    80005c40:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c44:	4007f793          	andi	a5,a5,1024
    80005c48:	c791                	beqz	a5,80005c54 <sys_open+0xd2>
    80005c4a:	04491703          	lh	a4,68(s2)
    80005c4e:	4789                	li	a5,2
    80005c50:	08f70f63          	beq	a4,a5,80005cee <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c54:	854a                	mv	a0,s2
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	082080e7          	jalr	130(ra) # 80003cd8 <iunlock>
  end_op();
    80005c5e:	fffff097          	auipc	ra,0xfffff
    80005c62:	a0a080e7          	jalr	-1526(ra) # 80004668 <end_op>

  return fd;
}
    80005c66:	8526                	mv	a0,s1
    80005c68:	70ea                	ld	ra,184(sp)
    80005c6a:	744a                	ld	s0,176(sp)
    80005c6c:	74aa                	ld	s1,168(sp)
    80005c6e:	790a                	ld	s2,160(sp)
    80005c70:	69ea                	ld	s3,152(sp)
    80005c72:	6129                	addi	sp,sp,192
    80005c74:	8082                	ret
      end_op();
    80005c76:	fffff097          	auipc	ra,0xfffff
    80005c7a:	9f2080e7          	jalr	-1550(ra) # 80004668 <end_op>
      return -1;
    80005c7e:	b7e5                	j	80005c66 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c80:	f5040513          	addi	a0,s0,-176
    80005c84:	ffffe097          	auipc	ra,0xffffe
    80005c88:	748080e7          	jalr	1864(ra) # 800043cc <namei>
    80005c8c:	892a                	mv	s2,a0
    80005c8e:	c905                	beqz	a0,80005cbe <sys_open+0x13c>
    ilock(ip);
    80005c90:	ffffe097          	auipc	ra,0xffffe
    80005c94:	f86080e7          	jalr	-122(ra) # 80003c16 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c98:	04491703          	lh	a4,68(s2)
    80005c9c:	4785                	li	a5,1
    80005c9e:	f4f712e3          	bne	a4,a5,80005be2 <sys_open+0x60>
    80005ca2:	f4c42783          	lw	a5,-180(s0)
    80005ca6:	dba1                	beqz	a5,80005bf6 <sys_open+0x74>
      iunlockput(ip);
    80005ca8:	854a                	mv	a0,s2
    80005caa:	ffffe097          	auipc	ra,0xffffe
    80005cae:	1ce080e7          	jalr	462(ra) # 80003e78 <iunlockput>
      end_op();
    80005cb2:	fffff097          	auipc	ra,0xfffff
    80005cb6:	9b6080e7          	jalr	-1610(ra) # 80004668 <end_op>
      return -1;
    80005cba:	54fd                	li	s1,-1
    80005cbc:	b76d                	j	80005c66 <sys_open+0xe4>
      end_op();
    80005cbe:	fffff097          	auipc	ra,0xfffff
    80005cc2:	9aa080e7          	jalr	-1622(ra) # 80004668 <end_op>
      return -1;
    80005cc6:	54fd                	li	s1,-1
    80005cc8:	bf79                	j	80005c66 <sys_open+0xe4>
    iunlockput(ip);
    80005cca:	854a                	mv	a0,s2
    80005ccc:	ffffe097          	auipc	ra,0xffffe
    80005cd0:	1ac080e7          	jalr	428(ra) # 80003e78 <iunlockput>
    end_op();
    80005cd4:	fffff097          	auipc	ra,0xfffff
    80005cd8:	994080e7          	jalr	-1644(ra) # 80004668 <end_op>
    return -1;
    80005cdc:	54fd                	li	s1,-1
    80005cde:	b761                	j	80005c66 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ce0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ce4:	04691783          	lh	a5,70(s2)
    80005ce8:	02f99223          	sh	a5,36(s3)
    80005cec:	bf2d                	j	80005c26 <sys_open+0xa4>
    itrunc(ip);
    80005cee:	854a                	mv	a0,s2
    80005cf0:	ffffe097          	auipc	ra,0xffffe
    80005cf4:	034080e7          	jalr	52(ra) # 80003d24 <itrunc>
    80005cf8:	bfb1                	j	80005c54 <sys_open+0xd2>
      fileclose(f);
    80005cfa:	854e                	mv	a0,s3
    80005cfc:	fffff097          	auipc	ra,0xfffff
    80005d00:	db8080e7          	jalr	-584(ra) # 80004ab4 <fileclose>
    iunlockput(ip);
    80005d04:	854a                	mv	a0,s2
    80005d06:	ffffe097          	auipc	ra,0xffffe
    80005d0a:	172080e7          	jalr	370(ra) # 80003e78 <iunlockput>
    end_op();
    80005d0e:	fffff097          	auipc	ra,0xfffff
    80005d12:	95a080e7          	jalr	-1702(ra) # 80004668 <end_op>
    return -1;
    80005d16:	54fd                	li	s1,-1
    80005d18:	b7b9                	j	80005c66 <sys_open+0xe4>

0000000080005d1a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d1a:	7175                	addi	sp,sp,-144
    80005d1c:	e506                	sd	ra,136(sp)
    80005d1e:	e122                	sd	s0,128(sp)
    80005d20:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d22:	fffff097          	auipc	ra,0xfffff
    80005d26:	8c6080e7          	jalr	-1850(ra) # 800045e8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d2a:	08000613          	li	a2,128
    80005d2e:	f7040593          	addi	a1,s0,-144
    80005d32:	4501                	li	a0,0
    80005d34:	ffffd097          	auipc	ra,0xffffd
    80005d38:	3b4080e7          	jalr	948(ra) # 800030e8 <argstr>
    80005d3c:	02054963          	bltz	a0,80005d6e <sys_mkdir+0x54>
    80005d40:	4681                	li	a3,0
    80005d42:	4601                	li	a2,0
    80005d44:	4585                	li	a1,1
    80005d46:	f7040513          	addi	a0,s0,-144
    80005d4a:	fffff097          	auipc	ra,0xfffff
    80005d4e:	7fe080e7          	jalr	2046(ra) # 80005548 <create>
    80005d52:	cd11                	beqz	a0,80005d6e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d54:	ffffe097          	auipc	ra,0xffffe
    80005d58:	124080e7          	jalr	292(ra) # 80003e78 <iunlockput>
  end_op();
    80005d5c:	fffff097          	auipc	ra,0xfffff
    80005d60:	90c080e7          	jalr	-1780(ra) # 80004668 <end_op>
  return 0;
    80005d64:	4501                	li	a0,0
}
    80005d66:	60aa                	ld	ra,136(sp)
    80005d68:	640a                	ld	s0,128(sp)
    80005d6a:	6149                	addi	sp,sp,144
    80005d6c:	8082                	ret
    end_op();
    80005d6e:	fffff097          	auipc	ra,0xfffff
    80005d72:	8fa080e7          	jalr	-1798(ra) # 80004668 <end_op>
    return -1;
    80005d76:	557d                	li	a0,-1
    80005d78:	b7fd                	j	80005d66 <sys_mkdir+0x4c>

0000000080005d7a <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d7a:	7135                	addi	sp,sp,-160
    80005d7c:	ed06                	sd	ra,152(sp)
    80005d7e:	e922                	sd	s0,144(sp)
    80005d80:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	866080e7          	jalr	-1946(ra) # 800045e8 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d8a:	08000613          	li	a2,128
    80005d8e:	f7040593          	addi	a1,s0,-144
    80005d92:	4501                	li	a0,0
    80005d94:	ffffd097          	auipc	ra,0xffffd
    80005d98:	354080e7          	jalr	852(ra) # 800030e8 <argstr>
    80005d9c:	04054a63          	bltz	a0,80005df0 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005da0:	f6c40593          	addi	a1,s0,-148
    80005da4:	4505                	li	a0,1
    80005da6:	ffffd097          	auipc	ra,0xffffd
    80005daa:	2fe080e7          	jalr	766(ra) # 800030a4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005dae:	04054163          	bltz	a0,80005df0 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005db2:	f6840593          	addi	a1,s0,-152
    80005db6:	4509                	li	a0,2
    80005db8:	ffffd097          	auipc	ra,0xffffd
    80005dbc:	2ec080e7          	jalr	748(ra) # 800030a4 <argint>
     argint(1, &major) < 0 ||
    80005dc0:	02054863          	bltz	a0,80005df0 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005dc4:	f6841683          	lh	a3,-152(s0)
    80005dc8:	f6c41603          	lh	a2,-148(s0)
    80005dcc:	458d                	li	a1,3
    80005dce:	f7040513          	addi	a0,s0,-144
    80005dd2:	fffff097          	auipc	ra,0xfffff
    80005dd6:	776080e7          	jalr	1910(ra) # 80005548 <create>
     argint(2, &minor) < 0 ||
    80005dda:	c919                	beqz	a0,80005df0 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ddc:	ffffe097          	auipc	ra,0xffffe
    80005de0:	09c080e7          	jalr	156(ra) # 80003e78 <iunlockput>
  end_op();
    80005de4:	fffff097          	auipc	ra,0xfffff
    80005de8:	884080e7          	jalr	-1916(ra) # 80004668 <end_op>
  return 0;
    80005dec:	4501                	li	a0,0
    80005dee:	a031                	j	80005dfa <sys_mknod+0x80>
    end_op();
    80005df0:	fffff097          	auipc	ra,0xfffff
    80005df4:	878080e7          	jalr	-1928(ra) # 80004668 <end_op>
    return -1;
    80005df8:	557d                	li	a0,-1
}
    80005dfa:	60ea                	ld	ra,152(sp)
    80005dfc:	644a                	ld	s0,144(sp)
    80005dfe:	610d                	addi	sp,sp,160
    80005e00:	8082                	ret

0000000080005e02 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e02:	7135                	addi	sp,sp,-160
    80005e04:	ed06                	sd	ra,152(sp)
    80005e06:	e922                	sd	s0,144(sp)
    80005e08:	e526                	sd	s1,136(sp)
    80005e0a:	e14a                	sd	s2,128(sp)
    80005e0c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e0e:	ffffc097          	auipc	ra,0xffffc
    80005e12:	f2c080e7          	jalr	-212(ra) # 80001d3a <myproc>
    80005e16:	892a                	mv	s2,a0
  
  begin_op();
    80005e18:	ffffe097          	auipc	ra,0xffffe
    80005e1c:	7d0080e7          	jalr	2000(ra) # 800045e8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e20:	08000613          	li	a2,128
    80005e24:	f6040593          	addi	a1,s0,-160
    80005e28:	4501                	li	a0,0
    80005e2a:	ffffd097          	auipc	ra,0xffffd
    80005e2e:	2be080e7          	jalr	702(ra) # 800030e8 <argstr>
    80005e32:	04054b63          	bltz	a0,80005e88 <sys_chdir+0x86>
    80005e36:	f6040513          	addi	a0,s0,-160
    80005e3a:	ffffe097          	auipc	ra,0xffffe
    80005e3e:	592080e7          	jalr	1426(ra) # 800043cc <namei>
    80005e42:	84aa                	mv	s1,a0
    80005e44:	c131                	beqz	a0,80005e88 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e46:	ffffe097          	auipc	ra,0xffffe
    80005e4a:	dd0080e7          	jalr	-560(ra) # 80003c16 <ilock>
  if(ip->type != T_DIR){
    80005e4e:	04449703          	lh	a4,68(s1)
    80005e52:	4785                	li	a5,1
    80005e54:	04f71063          	bne	a4,a5,80005e94 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e58:	8526                	mv	a0,s1
    80005e5a:	ffffe097          	auipc	ra,0xffffe
    80005e5e:	e7e080e7          	jalr	-386(ra) # 80003cd8 <iunlock>
  iput(p->cwd);
    80005e62:	15093503          	ld	a0,336(s2)
    80005e66:	ffffe097          	auipc	ra,0xffffe
    80005e6a:	f6a080e7          	jalr	-150(ra) # 80003dd0 <iput>
  end_op();
    80005e6e:	ffffe097          	auipc	ra,0xffffe
    80005e72:	7fa080e7          	jalr	2042(ra) # 80004668 <end_op>
  p->cwd = ip;
    80005e76:	14993823          	sd	s1,336(s2)
  return 0;
    80005e7a:	4501                	li	a0,0
}
    80005e7c:	60ea                	ld	ra,152(sp)
    80005e7e:	644a                	ld	s0,144(sp)
    80005e80:	64aa                	ld	s1,136(sp)
    80005e82:	690a                	ld	s2,128(sp)
    80005e84:	610d                	addi	sp,sp,160
    80005e86:	8082                	ret
    end_op();
    80005e88:	ffffe097          	auipc	ra,0xffffe
    80005e8c:	7e0080e7          	jalr	2016(ra) # 80004668 <end_op>
    return -1;
    80005e90:	557d                	li	a0,-1
    80005e92:	b7ed                	j	80005e7c <sys_chdir+0x7a>
    iunlockput(ip);
    80005e94:	8526                	mv	a0,s1
    80005e96:	ffffe097          	auipc	ra,0xffffe
    80005e9a:	fe2080e7          	jalr	-30(ra) # 80003e78 <iunlockput>
    end_op();
    80005e9e:	ffffe097          	auipc	ra,0xffffe
    80005ea2:	7ca080e7          	jalr	1994(ra) # 80004668 <end_op>
    return -1;
    80005ea6:	557d                	li	a0,-1
    80005ea8:	bfd1                	j	80005e7c <sys_chdir+0x7a>

0000000080005eaa <sys_exec>:

uint64
sys_exec(void)
{
    80005eaa:	7145                	addi	sp,sp,-464
    80005eac:	e786                	sd	ra,456(sp)
    80005eae:	e3a2                	sd	s0,448(sp)
    80005eb0:	ff26                	sd	s1,440(sp)
    80005eb2:	fb4a                	sd	s2,432(sp)
    80005eb4:	f74e                	sd	s3,424(sp)
    80005eb6:	f352                	sd	s4,416(sp)
    80005eb8:	ef56                	sd	s5,408(sp)
    80005eba:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ebc:	08000613          	li	a2,128
    80005ec0:	f4040593          	addi	a1,s0,-192
    80005ec4:	4501                	li	a0,0
    80005ec6:	ffffd097          	auipc	ra,0xffffd
    80005eca:	222080e7          	jalr	546(ra) # 800030e8 <argstr>
    return -1;
    80005ece:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ed0:	0c054a63          	bltz	a0,80005fa4 <sys_exec+0xfa>
    80005ed4:	e3840593          	addi	a1,s0,-456
    80005ed8:	4505                	li	a0,1
    80005eda:	ffffd097          	auipc	ra,0xffffd
    80005ede:	1ec080e7          	jalr	492(ra) # 800030c6 <argaddr>
    80005ee2:	0c054163          	bltz	a0,80005fa4 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ee6:	10000613          	li	a2,256
    80005eea:	4581                	li	a1,0
    80005eec:	e4040513          	addi	a0,s0,-448
    80005ef0:	ffffb097          	auipc	ra,0xffffb
    80005ef4:	df0080e7          	jalr	-528(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ef8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005efc:	89a6                	mv	s3,s1
    80005efe:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f00:	02000a13          	li	s4,32
    80005f04:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f08:	00391513          	slli	a0,s2,0x3
    80005f0c:	e3040593          	addi	a1,s0,-464
    80005f10:	e3843783          	ld	a5,-456(s0)
    80005f14:	953e                	add	a0,a0,a5
    80005f16:	ffffd097          	auipc	ra,0xffffd
    80005f1a:	0f4080e7          	jalr	244(ra) # 8000300a <fetchaddr>
    80005f1e:	02054a63          	bltz	a0,80005f52 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005f22:	e3043783          	ld	a5,-464(s0)
    80005f26:	c3b9                	beqz	a5,80005f6c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f28:	ffffb097          	auipc	ra,0xffffb
    80005f2c:	bcc080e7          	jalr	-1076(ra) # 80000af4 <kalloc>
    80005f30:	85aa                	mv	a1,a0
    80005f32:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f36:	cd11                	beqz	a0,80005f52 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f38:	6605                	lui	a2,0x1
    80005f3a:	e3043503          	ld	a0,-464(s0)
    80005f3e:	ffffd097          	auipc	ra,0xffffd
    80005f42:	11e080e7          	jalr	286(ra) # 8000305c <fetchstr>
    80005f46:	00054663          	bltz	a0,80005f52 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005f4a:	0905                	addi	s2,s2,1
    80005f4c:	09a1                	addi	s3,s3,8
    80005f4e:	fb491be3          	bne	s2,s4,80005f04 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f52:	10048913          	addi	s2,s1,256
    80005f56:	6088                	ld	a0,0(s1)
    80005f58:	c529                	beqz	a0,80005fa2 <sys_exec+0xf8>
    kfree(argv[i]);
    80005f5a:	ffffb097          	auipc	ra,0xffffb
    80005f5e:	a9e080e7          	jalr	-1378(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f62:	04a1                	addi	s1,s1,8
    80005f64:	ff2499e3          	bne	s1,s2,80005f56 <sys_exec+0xac>
  return -1;
    80005f68:	597d                	li	s2,-1
    80005f6a:	a82d                	j	80005fa4 <sys_exec+0xfa>
      argv[i] = 0;
    80005f6c:	0a8e                	slli	s5,s5,0x3
    80005f6e:	fc040793          	addi	a5,s0,-64
    80005f72:	9abe                	add	s5,s5,a5
    80005f74:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005f78:	e4040593          	addi	a1,s0,-448
    80005f7c:	f4040513          	addi	a0,s0,-192
    80005f80:	fffff097          	auipc	ra,0xfffff
    80005f84:	194080e7          	jalr	404(ra) # 80005114 <exec>
    80005f88:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f8a:	10048993          	addi	s3,s1,256
    80005f8e:	6088                	ld	a0,0(s1)
    80005f90:	c911                	beqz	a0,80005fa4 <sys_exec+0xfa>
    kfree(argv[i]);
    80005f92:	ffffb097          	auipc	ra,0xffffb
    80005f96:	a66080e7          	jalr	-1434(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f9a:	04a1                	addi	s1,s1,8
    80005f9c:	ff3499e3          	bne	s1,s3,80005f8e <sys_exec+0xe4>
    80005fa0:	a011                	j	80005fa4 <sys_exec+0xfa>
  return -1;
    80005fa2:	597d                	li	s2,-1
}
    80005fa4:	854a                	mv	a0,s2
    80005fa6:	60be                	ld	ra,456(sp)
    80005fa8:	641e                	ld	s0,448(sp)
    80005faa:	74fa                	ld	s1,440(sp)
    80005fac:	795a                	ld	s2,432(sp)
    80005fae:	79ba                	ld	s3,424(sp)
    80005fb0:	7a1a                	ld	s4,416(sp)
    80005fb2:	6afa                	ld	s5,408(sp)
    80005fb4:	6179                	addi	sp,sp,464
    80005fb6:	8082                	ret

0000000080005fb8 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005fb8:	7139                	addi	sp,sp,-64
    80005fba:	fc06                	sd	ra,56(sp)
    80005fbc:	f822                	sd	s0,48(sp)
    80005fbe:	f426                	sd	s1,40(sp)
    80005fc0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005fc2:	ffffc097          	auipc	ra,0xffffc
    80005fc6:	d78080e7          	jalr	-648(ra) # 80001d3a <myproc>
    80005fca:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005fcc:	fd840593          	addi	a1,s0,-40
    80005fd0:	4501                	li	a0,0
    80005fd2:	ffffd097          	auipc	ra,0xffffd
    80005fd6:	0f4080e7          	jalr	244(ra) # 800030c6 <argaddr>
    return -1;
    80005fda:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005fdc:	0e054063          	bltz	a0,800060bc <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005fe0:	fc840593          	addi	a1,s0,-56
    80005fe4:	fd040513          	addi	a0,s0,-48
    80005fe8:	fffff097          	auipc	ra,0xfffff
    80005fec:	dfc080e7          	jalr	-516(ra) # 80004de4 <pipealloc>
    return -1;
    80005ff0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ff2:	0c054563          	bltz	a0,800060bc <sys_pipe+0x104>
  fd0 = -1;
    80005ff6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ffa:	fd043503          	ld	a0,-48(s0)
    80005ffe:	fffff097          	auipc	ra,0xfffff
    80006002:	508080e7          	jalr	1288(ra) # 80005506 <fdalloc>
    80006006:	fca42223          	sw	a0,-60(s0)
    8000600a:	08054c63          	bltz	a0,800060a2 <sys_pipe+0xea>
    8000600e:	fc843503          	ld	a0,-56(s0)
    80006012:	fffff097          	auipc	ra,0xfffff
    80006016:	4f4080e7          	jalr	1268(ra) # 80005506 <fdalloc>
    8000601a:	fca42023          	sw	a0,-64(s0)
    8000601e:	06054863          	bltz	a0,8000608e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006022:	4691                	li	a3,4
    80006024:	fc440613          	addi	a2,s0,-60
    80006028:	fd843583          	ld	a1,-40(s0)
    8000602c:	68a8                	ld	a0,80(s1)
    8000602e:	ffffb097          	auipc	ra,0xffffb
    80006032:	644080e7          	jalr	1604(ra) # 80001672 <copyout>
    80006036:	02054063          	bltz	a0,80006056 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000603a:	4691                	li	a3,4
    8000603c:	fc040613          	addi	a2,s0,-64
    80006040:	fd843583          	ld	a1,-40(s0)
    80006044:	0591                	addi	a1,a1,4
    80006046:	68a8                	ld	a0,80(s1)
    80006048:	ffffb097          	auipc	ra,0xffffb
    8000604c:	62a080e7          	jalr	1578(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006050:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006052:	06055563          	bgez	a0,800060bc <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006056:	fc442783          	lw	a5,-60(s0)
    8000605a:	07e9                	addi	a5,a5,26
    8000605c:	078e                	slli	a5,a5,0x3
    8000605e:	97a6                	add	a5,a5,s1
    80006060:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006064:	fc042503          	lw	a0,-64(s0)
    80006068:	0569                	addi	a0,a0,26
    8000606a:	050e                	slli	a0,a0,0x3
    8000606c:	9526                	add	a0,a0,s1
    8000606e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006072:	fd043503          	ld	a0,-48(s0)
    80006076:	fffff097          	auipc	ra,0xfffff
    8000607a:	a3e080e7          	jalr	-1474(ra) # 80004ab4 <fileclose>
    fileclose(wf);
    8000607e:	fc843503          	ld	a0,-56(s0)
    80006082:	fffff097          	auipc	ra,0xfffff
    80006086:	a32080e7          	jalr	-1486(ra) # 80004ab4 <fileclose>
    return -1;
    8000608a:	57fd                	li	a5,-1
    8000608c:	a805                	j	800060bc <sys_pipe+0x104>
    if(fd0 >= 0)
    8000608e:	fc442783          	lw	a5,-60(s0)
    80006092:	0007c863          	bltz	a5,800060a2 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006096:	01a78513          	addi	a0,a5,26
    8000609a:	050e                	slli	a0,a0,0x3
    8000609c:	9526                	add	a0,a0,s1
    8000609e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800060a2:	fd043503          	ld	a0,-48(s0)
    800060a6:	fffff097          	auipc	ra,0xfffff
    800060aa:	a0e080e7          	jalr	-1522(ra) # 80004ab4 <fileclose>
    fileclose(wf);
    800060ae:	fc843503          	ld	a0,-56(s0)
    800060b2:	fffff097          	auipc	ra,0xfffff
    800060b6:	a02080e7          	jalr	-1534(ra) # 80004ab4 <fileclose>
    return -1;
    800060ba:	57fd                	li	a5,-1
}
    800060bc:	853e                	mv	a0,a5
    800060be:	70e2                	ld	ra,56(sp)
    800060c0:	7442                	ld	s0,48(sp)
    800060c2:	74a2                	ld	s1,40(sp)
    800060c4:	6121                	addi	sp,sp,64
    800060c6:	8082                	ret
	...

00000000800060d0 <kernelvec>:
    800060d0:	7111                	addi	sp,sp,-256
    800060d2:	e006                	sd	ra,0(sp)
    800060d4:	e40a                	sd	sp,8(sp)
    800060d6:	e80e                	sd	gp,16(sp)
    800060d8:	ec12                	sd	tp,24(sp)
    800060da:	f016                	sd	t0,32(sp)
    800060dc:	f41a                	sd	t1,40(sp)
    800060de:	f81e                	sd	t2,48(sp)
    800060e0:	fc22                	sd	s0,56(sp)
    800060e2:	e0a6                	sd	s1,64(sp)
    800060e4:	e4aa                	sd	a0,72(sp)
    800060e6:	e8ae                	sd	a1,80(sp)
    800060e8:	ecb2                	sd	a2,88(sp)
    800060ea:	f0b6                	sd	a3,96(sp)
    800060ec:	f4ba                	sd	a4,104(sp)
    800060ee:	f8be                	sd	a5,112(sp)
    800060f0:	fcc2                	sd	a6,120(sp)
    800060f2:	e146                	sd	a7,128(sp)
    800060f4:	e54a                	sd	s2,136(sp)
    800060f6:	e94e                	sd	s3,144(sp)
    800060f8:	ed52                	sd	s4,152(sp)
    800060fa:	f156                	sd	s5,160(sp)
    800060fc:	f55a                	sd	s6,168(sp)
    800060fe:	f95e                	sd	s7,176(sp)
    80006100:	fd62                	sd	s8,184(sp)
    80006102:	e1e6                	sd	s9,192(sp)
    80006104:	e5ea                	sd	s10,200(sp)
    80006106:	e9ee                	sd	s11,208(sp)
    80006108:	edf2                	sd	t3,216(sp)
    8000610a:	f1f6                	sd	t4,224(sp)
    8000610c:	f5fa                	sd	t5,232(sp)
    8000610e:	f9fe                	sd	t6,240(sp)
    80006110:	dc7fc0ef          	jal	ra,80002ed6 <kerneltrap>
    80006114:	6082                	ld	ra,0(sp)
    80006116:	6122                	ld	sp,8(sp)
    80006118:	61c2                	ld	gp,16(sp)
    8000611a:	7282                	ld	t0,32(sp)
    8000611c:	7322                	ld	t1,40(sp)
    8000611e:	73c2                	ld	t2,48(sp)
    80006120:	7462                	ld	s0,56(sp)
    80006122:	6486                	ld	s1,64(sp)
    80006124:	6526                	ld	a0,72(sp)
    80006126:	65c6                	ld	a1,80(sp)
    80006128:	6666                	ld	a2,88(sp)
    8000612a:	7686                	ld	a3,96(sp)
    8000612c:	7726                	ld	a4,104(sp)
    8000612e:	77c6                	ld	a5,112(sp)
    80006130:	7866                	ld	a6,120(sp)
    80006132:	688a                	ld	a7,128(sp)
    80006134:	692a                	ld	s2,136(sp)
    80006136:	69ca                	ld	s3,144(sp)
    80006138:	6a6a                	ld	s4,152(sp)
    8000613a:	7a8a                	ld	s5,160(sp)
    8000613c:	7b2a                	ld	s6,168(sp)
    8000613e:	7bca                	ld	s7,176(sp)
    80006140:	7c6a                	ld	s8,184(sp)
    80006142:	6c8e                	ld	s9,192(sp)
    80006144:	6d2e                	ld	s10,200(sp)
    80006146:	6dce                	ld	s11,208(sp)
    80006148:	6e6e                	ld	t3,216(sp)
    8000614a:	7e8e                	ld	t4,224(sp)
    8000614c:	7f2e                	ld	t5,232(sp)
    8000614e:	7fce                	ld	t6,240(sp)
    80006150:	6111                	addi	sp,sp,256
    80006152:	10200073          	sret
    80006156:	00000013          	nop
    8000615a:	00000013          	nop
    8000615e:	0001                	nop

0000000080006160 <timervec>:
    80006160:	34051573          	csrrw	a0,mscratch,a0
    80006164:	e10c                	sd	a1,0(a0)
    80006166:	e510                	sd	a2,8(a0)
    80006168:	e914                	sd	a3,16(a0)
    8000616a:	6d0c                	ld	a1,24(a0)
    8000616c:	7110                	ld	a2,32(a0)
    8000616e:	6194                	ld	a3,0(a1)
    80006170:	96b2                	add	a3,a3,a2
    80006172:	e194                	sd	a3,0(a1)
    80006174:	4589                	li	a1,2
    80006176:	14459073          	csrw	sip,a1
    8000617a:	6914                	ld	a3,16(a0)
    8000617c:	6510                	ld	a2,8(a0)
    8000617e:	610c                	ld	a1,0(a0)
    80006180:	34051573          	csrrw	a0,mscratch,a0
    80006184:	30200073          	mret
	...

000000008000618a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000618a:	1141                	addi	sp,sp,-16
    8000618c:	e422                	sd	s0,8(sp)
    8000618e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006190:	0c0007b7          	lui	a5,0xc000
    80006194:	4705                	li	a4,1
    80006196:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006198:	c3d8                	sw	a4,4(a5)
}
    8000619a:	6422                	ld	s0,8(sp)
    8000619c:	0141                	addi	sp,sp,16
    8000619e:	8082                	ret

00000000800061a0 <plicinithart>:

void
plicinithart(void)
{
    800061a0:	1141                	addi	sp,sp,-16
    800061a2:	e406                	sd	ra,8(sp)
    800061a4:	e022                	sd	s0,0(sp)
    800061a6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061a8:	ffffc097          	auipc	ra,0xffffc
    800061ac:	b60080e7          	jalr	-1184(ra) # 80001d08 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800061b0:	0085171b          	slliw	a4,a0,0x8
    800061b4:	0c0027b7          	lui	a5,0xc002
    800061b8:	97ba                	add	a5,a5,a4
    800061ba:	40200713          	li	a4,1026
    800061be:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800061c2:	00d5151b          	slliw	a0,a0,0xd
    800061c6:	0c2017b7          	lui	a5,0xc201
    800061ca:	953e                	add	a0,a0,a5
    800061cc:	00052023          	sw	zero,0(a0)
}
    800061d0:	60a2                	ld	ra,8(sp)
    800061d2:	6402                	ld	s0,0(sp)
    800061d4:	0141                	addi	sp,sp,16
    800061d6:	8082                	ret

00000000800061d8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800061d8:	1141                	addi	sp,sp,-16
    800061da:	e406                	sd	ra,8(sp)
    800061dc:	e022                	sd	s0,0(sp)
    800061de:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061e0:	ffffc097          	auipc	ra,0xffffc
    800061e4:	b28080e7          	jalr	-1240(ra) # 80001d08 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800061e8:	00d5179b          	slliw	a5,a0,0xd
    800061ec:	0c201537          	lui	a0,0xc201
    800061f0:	953e                	add	a0,a0,a5
  return irq;
}
    800061f2:	4148                	lw	a0,4(a0)
    800061f4:	60a2                	ld	ra,8(sp)
    800061f6:	6402                	ld	s0,0(sp)
    800061f8:	0141                	addi	sp,sp,16
    800061fa:	8082                	ret

00000000800061fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061fc:	1101                	addi	sp,sp,-32
    800061fe:	ec06                	sd	ra,24(sp)
    80006200:	e822                	sd	s0,16(sp)
    80006202:	e426                	sd	s1,8(sp)
    80006204:	1000                	addi	s0,sp,32
    80006206:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006208:	ffffc097          	auipc	ra,0xffffc
    8000620c:	b00080e7          	jalr	-1280(ra) # 80001d08 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006210:	00d5151b          	slliw	a0,a0,0xd
    80006214:	0c2017b7          	lui	a5,0xc201
    80006218:	97aa                	add	a5,a5,a0
    8000621a:	c3c4                	sw	s1,4(a5)
}
    8000621c:	60e2                	ld	ra,24(sp)
    8000621e:	6442                	ld	s0,16(sp)
    80006220:	64a2                	ld	s1,8(sp)
    80006222:	6105                	addi	sp,sp,32
    80006224:	8082                	ret

0000000080006226 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006226:	1141                	addi	sp,sp,-16
    80006228:	e406                	sd	ra,8(sp)
    8000622a:	e022                	sd	s0,0(sp)
    8000622c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000622e:	479d                	li	a5,7
    80006230:	06a7c963          	blt	a5,a0,800062a2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006234:	0001d797          	auipc	a5,0x1d
    80006238:	dcc78793          	addi	a5,a5,-564 # 80023000 <disk>
    8000623c:	00a78733          	add	a4,a5,a0
    80006240:	6789                	lui	a5,0x2
    80006242:	97ba                	add	a5,a5,a4
    80006244:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006248:	e7ad                	bnez	a5,800062b2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000624a:	00451793          	slli	a5,a0,0x4
    8000624e:	0001f717          	auipc	a4,0x1f
    80006252:	db270713          	addi	a4,a4,-590 # 80025000 <disk+0x2000>
    80006256:	6314                	ld	a3,0(a4)
    80006258:	96be                	add	a3,a3,a5
    8000625a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000625e:	6314                	ld	a3,0(a4)
    80006260:	96be                	add	a3,a3,a5
    80006262:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006266:	6314                	ld	a3,0(a4)
    80006268:	96be                	add	a3,a3,a5
    8000626a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000626e:	6318                	ld	a4,0(a4)
    80006270:	97ba                	add	a5,a5,a4
    80006272:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006276:	0001d797          	auipc	a5,0x1d
    8000627a:	d8a78793          	addi	a5,a5,-630 # 80023000 <disk>
    8000627e:	97aa                	add	a5,a5,a0
    80006280:	6509                	lui	a0,0x2
    80006282:	953e                	add	a0,a0,a5
    80006284:	4785                	li	a5,1
    80006286:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000628a:	0001f517          	auipc	a0,0x1f
    8000628e:	d8e50513          	addi	a0,a0,-626 # 80025018 <disk+0x2018>
    80006292:	ffffc097          	auipc	ra,0xffffc
    80006296:	444080e7          	jalr	1092(ra) # 800026d6 <wakeup>
}
    8000629a:	60a2                	ld	ra,8(sp)
    8000629c:	6402                	ld	s0,0(sp)
    8000629e:	0141                	addi	sp,sp,16
    800062a0:	8082                	ret
    panic("free_desc 1");
    800062a2:	00002517          	auipc	a0,0x2
    800062a6:	54e50513          	addi	a0,a0,1358 # 800087f0 <syscalls+0x320>
    800062aa:	ffffa097          	auipc	ra,0xffffa
    800062ae:	294080e7          	jalr	660(ra) # 8000053e <panic>
    panic("free_desc 2");
    800062b2:	00002517          	auipc	a0,0x2
    800062b6:	54e50513          	addi	a0,a0,1358 # 80008800 <syscalls+0x330>
    800062ba:	ffffa097          	auipc	ra,0xffffa
    800062be:	284080e7          	jalr	644(ra) # 8000053e <panic>

00000000800062c2 <virtio_disk_init>:
{
    800062c2:	1101                	addi	sp,sp,-32
    800062c4:	ec06                	sd	ra,24(sp)
    800062c6:	e822                	sd	s0,16(sp)
    800062c8:	e426                	sd	s1,8(sp)
    800062ca:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800062cc:	00002597          	auipc	a1,0x2
    800062d0:	54458593          	addi	a1,a1,1348 # 80008810 <syscalls+0x340>
    800062d4:	0001f517          	auipc	a0,0x1f
    800062d8:	e5450513          	addi	a0,a0,-428 # 80025128 <disk+0x2128>
    800062dc:	ffffb097          	auipc	ra,0xffffb
    800062e0:	878080e7          	jalr	-1928(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062e4:	100017b7          	lui	a5,0x10001
    800062e8:	4398                	lw	a4,0(a5)
    800062ea:	2701                	sext.w	a4,a4
    800062ec:	747277b7          	lui	a5,0x74727
    800062f0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800062f4:	0ef71163          	bne	a4,a5,800063d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062f8:	100017b7          	lui	a5,0x10001
    800062fc:	43dc                	lw	a5,4(a5)
    800062fe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006300:	4705                	li	a4,1
    80006302:	0ce79a63          	bne	a5,a4,800063d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006306:	100017b7          	lui	a5,0x10001
    8000630a:	479c                	lw	a5,8(a5)
    8000630c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000630e:	4709                	li	a4,2
    80006310:	0ce79363          	bne	a5,a4,800063d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006314:	100017b7          	lui	a5,0x10001
    80006318:	47d8                	lw	a4,12(a5)
    8000631a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000631c:	554d47b7          	lui	a5,0x554d4
    80006320:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006324:	0af71963          	bne	a4,a5,800063d6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006328:	100017b7          	lui	a5,0x10001
    8000632c:	4705                	li	a4,1
    8000632e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006330:	470d                	li	a4,3
    80006332:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006334:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006336:	c7ffe737          	lui	a4,0xc7ffe
    8000633a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000633e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006340:	2701                	sext.w	a4,a4
    80006342:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006344:	472d                	li	a4,11
    80006346:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006348:	473d                	li	a4,15
    8000634a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000634c:	6705                	lui	a4,0x1
    8000634e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006350:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006354:	5bdc                	lw	a5,52(a5)
    80006356:	2781                	sext.w	a5,a5
  if(max == 0)
    80006358:	c7d9                	beqz	a5,800063e6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000635a:	471d                	li	a4,7
    8000635c:	08f77d63          	bgeu	a4,a5,800063f6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006360:	100014b7          	lui	s1,0x10001
    80006364:	47a1                	li	a5,8
    80006366:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006368:	6609                	lui	a2,0x2
    8000636a:	4581                	li	a1,0
    8000636c:	0001d517          	auipc	a0,0x1d
    80006370:	c9450513          	addi	a0,a0,-876 # 80023000 <disk>
    80006374:	ffffb097          	auipc	ra,0xffffb
    80006378:	96c080e7          	jalr	-1684(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000637c:	0001d717          	auipc	a4,0x1d
    80006380:	c8470713          	addi	a4,a4,-892 # 80023000 <disk>
    80006384:	00c75793          	srli	a5,a4,0xc
    80006388:	2781                	sext.w	a5,a5
    8000638a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000638c:	0001f797          	auipc	a5,0x1f
    80006390:	c7478793          	addi	a5,a5,-908 # 80025000 <disk+0x2000>
    80006394:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006396:	0001d717          	auipc	a4,0x1d
    8000639a:	cea70713          	addi	a4,a4,-790 # 80023080 <disk+0x80>
    8000639e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800063a0:	0001e717          	auipc	a4,0x1e
    800063a4:	c6070713          	addi	a4,a4,-928 # 80024000 <disk+0x1000>
    800063a8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800063aa:	4705                	li	a4,1
    800063ac:	00e78c23          	sb	a4,24(a5)
    800063b0:	00e78ca3          	sb	a4,25(a5)
    800063b4:	00e78d23          	sb	a4,26(a5)
    800063b8:	00e78da3          	sb	a4,27(a5)
    800063bc:	00e78e23          	sb	a4,28(a5)
    800063c0:	00e78ea3          	sb	a4,29(a5)
    800063c4:	00e78f23          	sb	a4,30(a5)
    800063c8:	00e78fa3          	sb	a4,31(a5)
}
    800063cc:	60e2                	ld	ra,24(sp)
    800063ce:	6442                	ld	s0,16(sp)
    800063d0:	64a2                	ld	s1,8(sp)
    800063d2:	6105                	addi	sp,sp,32
    800063d4:	8082                	ret
    panic("could not find virtio disk");
    800063d6:	00002517          	auipc	a0,0x2
    800063da:	44a50513          	addi	a0,a0,1098 # 80008820 <syscalls+0x350>
    800063de:	ffffa097          	auipc	ra,0xffffa
    800063e2:	160080e7          	jalr	352(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800063e6:	00002517          	auipc	a0,0x2
    800063ea:	45a50513          	addi	a0,a0,1114 # 80008840 <syscalls+0x370>
    800063ee:	ffffa097          	auipc	ra,0xffffa
    800063f2:	150080e7          	jalr	336(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800063f6:	00002517          	auipc	a0,0x2
    800063fa:	46a50513          	addi	a0,a0,1130 # 80008860 <syscalls+0x390>
    800063fe:	ffffa097          	auipc	ra,0xffffa
    80006402:	140080e7          	jalr	320(ra) # 8000053e <panic>

0000000080006406 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006406:	7159                	addi	sp,sp,-112
    80006408:	f486                	sd	ra,104(sp)
    8000640a:	f0a2                	sd	s0,96(sp)
    8000640c:	eca6                	sd	s1,88(sp)
    8000640e:	e8ca                	sd	s2,80(sp)
    80006410:	e4ce                	sd	s3,72(sp)
    80006412:	e0d2                	sd	s4,64(sp)
    80006414:	fc56                	sd	s5,56(sp)
    80006416:	f85a                	sd	s6,48(sp)
    80006418:	f45e                	sd	s7,40(sp)
    8000641a:	f062                	sd	s8,32(sp)
    8000641c:	ec66                	sd	s9,24(sp)
    8000641e:	e86a                	sd	s10,16(sp)
    80006420:	1880                	addi	s0,sp,112
    80006422:	892a                	mv	s2,a0
    80006424:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006426:	00c52c83          	lw	s9,12(a0)
    8000642a:	001c9c9b          	slliw	s9,s9,0x1
    8000642e:	1c82                	slli	s9,s9,0x20
    80006430:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006434:	0001f517          	auipc	a0,0x1f
    80006438:	cf450513          	addi	a0,a0,-780 # 80025128 <disk+0x2128>
    8000643c:	ffffa097          	auipc	ra,0xffffa
    80006440:	7a8080e7          	jalr	1960(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006444:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006446:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006448:	0001db97          	auipc	s7,0x1d
    8000644c:	bb8b8b93          	addi	s7,s7,-1096 # 80023000 <disk>
    80006450:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006452:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006454:	8a4e                	mv	s4,s3
    80006456:	a051                	j	800064da <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006458:	00fb86b3          	add	a3,s7,a5
    8000645c:	96da                	add	a3,a3,s6
    8000645e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006462:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006464:	0207c563          	bltz	a5,8000648e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006468:	2485                	addiw	s1,s1,1
    8000646a:	0711                	addi	a4,a4,4
    8000646c:	25548063          	beq	s1,s5,800066ac <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006470:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006472:	0001f697          	auipc	a3,0x1f
    80006476:	ba668693          	addi	a3,a3,-1114 # 80025018 <disk+0x2018>
    8000647a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000647c:	0006c583          	lbu	a1,0(a3)
    80006480:	fde1                	bnez	a1,80006458 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006482:	2785                	addiw	a5,a5,1
    80006484:	0685                	addi	a3,a3,1
    80006486:	ff879be3          	bne	a5,s8,8000647c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000648a:	57fd                	li	a5,-1
    8000648c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000648e:	02905a63          	blez	s1,800064c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006492:	f9042503          	lw	a0,-112(s0)
    80006496:	00000097          	auipc	ra,0x0
    8000649a:	d90080e7          	jalr	-624(ra) # 80006226 <free_desc>
      for(int j = 0; j < i; j++)
    8000649e:	4785                	li	a5,1
    800064a0:	0297d163          	bge	a5,s1,800064c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800064a4:	f9442503          	lw	a0,-108(s0)
    800064a8:	00000097          	auipc	ra,0x0
    800064ac:	d7e080e7          	jalr	-642(ra) # 80006226 <free_desc>
      for(int j = 0; j < i; j++)
    800064b0:	4789                	li	a5,2
    800064b2:	0097d863          	bge	a5,s1,800064c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800064b6:	f9842503          	lw	a0,-104(s0)
    800064ba:	00000097          	auipc	ra,0x0
    800064be:	d6c080e7          	jalr	-660(ra) # 80006226 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064c2:	0001f597          	auipc	a1,0x1f
    800064c6:	c6658593          	addi	a1,a1,-922 # 80025128 <disk+0x2128>
    800064ca:	0001f517          	auipc	a0,0x1f
    800064ce:	b4e50513          	addi	a0,a0,-1202 # 80025018 <disk+0x2018>
    800064d2:	ffffc097          	auipc	ra,0xffffc
    800064d6:	066080e7          	jalr	102(ra) # 80002538 <sleep>
  for(int i = 0; i < 3; i++){
    800064da:	f9040713          	addi	a4,s0,-112
    800064de:	84ce                	mv	s1,s3
    800064e0:	bf41                	j	80006470 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800064e2:	20058713          	addi	a4,a1,512
    800064e6:	00471693          	slli	a3,a4,0x4
    800064ea:	0001d717          	auipc	a4,0x1d
    800064ee:	b1670713          	addi	a4,a4,-1258 # 80023000 <disk>
    800064f2:	9736                	add	a4,a4,a3
    800064f4:	4685                	li	a3,1
    800064f6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064fa:	20058713          	addi	a4,a1,512
    800064fe:	00471693          	slli	a3,a4,0x4
    80006502:	0001d717          	auipc	a4,0x1d
    80006506:	afe70713          	addi	a4,a4,-1282 # 80023000 <disk>
    8000650a:	9736                	add	a4,a4,a3
    8000650c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006510:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006514:	7679                	lui	a2,0xffffe
    80006516:	963e                	add	a2,a2,a5
    80006518:	0001f697          	auipc	a3,0x1f
    8000651c:	ae868693          	addi	a3,a3,-1304 # 80025000 <disk+0x2000>
    80006520:	6298                	ld	a4,0(a3)
    80006522:	9732                	add	a4,a4,a2
    80006524:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006526:	6298                	ld	a4,0(a3)
    80006528:	9732                	add	a4,a4,a2
    8000652a:	4541                	li	a0,16
    8000652c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000652e:	6298                	ld	a4,0(a3)
    80006530:	9732                	add	a4,a4,a2
    80006532:	4505                	li	a0,1
    80006534:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006538:	f9442703          	lw	a4,-108(s0)
    8000653c:	6288                	ld	a0,0(a3)
    8000653e:	962a                	add	a2,a2,a0
    80006540:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006544:	0712                	slli	a4,a4,0x4
    80006546:	6290                	ld	a2,0(a3)
    80006548:	963a                	add	a2,a2,a4
    8000654a:	05890513          	addi	a0,s2,88
    8000654e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006550:	6294                	ld	a3,0(a3)
    80006552:	96ba                	add	a3,a3,a4
    80006554:	40000613          	li	a2,1024
    80006558:	c690                	sw	a2,8(a3)
  if(write)
    8000655a:	140d0063          	beqz	s10,8000669a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000655e:	0001f697          	auipc	a3,0x1f
    80006562:	aa26b683          	ld	a3,-1374(a3) # 80025000 <disk+0x2000>
    80006566:	96ba                	add	a3,a3,a4
    80006568:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000656c:	0001d817          	auipc	a6,0x1d
    80006570:	a9480813          	addi	a6,a6,-1388 # 80023000 <disk>
    80006574:	0001f517          	auipc	a0,0x1f
    80006578:	a8c50513          	addi	a0,a0,-1396 # 80025000 <disk+0x2000>
    8000657c:	6114                	ld	a3,0(a0)
    8000657e:	96ba                	add	a3,a3,a4
    80006580:	00c6d603          	lhu	a2,12(a3)
    80006584:	00166613          	ori	a2,a2,1
    80006588:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000658c:	f9842683          	lw	a3,-104(s0)
    80006590:	6110                	ld	a2,0(a0)
    80006592:	9732                	add	a4,a4,a2
    80006594:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006598:	20058613          	addi	a2,a1,512
    8000659c:	0612                	slli	a2,a2,0x4
    8000659e:	9642                	add	a2,a2,a6
    800065a0:	577d                	li	a4,-1
    800065a2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800065a6:	00469713          	slli	a4,a3,0x4
    800065aa:	6114                	ld	a3,0(a0)
    800065ac:	96ba                	add	a3,a3,a4
    800065ae:	03078793          	addi	a5,a5,48
    800065b2:	97c2                	add	a5,a5,a6
    800065b4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800065b6:	611c                	ld	a5,0(a0)
    800065b8:	97ba                	add	a5,a5,a4
    800065ba:	4685                	li	a3,1
    800065bc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800065be:	611c                	ld	a5,0(a0)
    800065c0:	97ba                	add	a5,a5,a4
    800065c2:	4809                	li	a6,2
    800065c4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800065c8:	611c                	ld	a5,0(a0)
    800065ca:	973e                	add	a4,a4,a5
    800065cc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800065d0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800065d4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800065d8:	6518                	ld	a4,8(a0)
    800065da:	00275783          	lhu	a5,2(a4)
    800065de:	8b9d                	andi	a5,a5,7
    800065e0:	0786                	slli	a5,a5,0x1
    800065e2:	97ba                	add	a5,a5,a4
    800065e4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800065e8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065ec:	6518                	ld	a4,8(a0)
    800065ee:	00275783          	lhu	a5,2(a4)
    800065f2:	2785                	addiw	a5,a5,1
    800065f4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065f8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065fc:	100017b7          	lui	a5,0x10001
    80006600:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006604:	00492703          	lw	a4,4(s2)
    80006608:	4785                	li	a5,1
    8000660a:	02f71163          	bne	a4,a5,8000662c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000660e:	0001f997          	auipc	s3,0x1f
    80006612:	b1a98993          	addi	s3,s3,-1254 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006616:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006618:	85ce                	mv	a1,s3
    8000661a:	854a                	mv	a0,s2
    8000661c:	ffffc097          	auipc	ra,0xffffc
    80006620:	f1c080e7          	jalr	-228(ra) # 80002538 <sleep>
  while(b->disk == 1) {
    80006624:	00492783          	lw	a5,4(s2)
    80006628:	fe9788e3          	beq	a5,s1,80006618 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000662c:	f9042903          	lw	s2,-112(s0)
    80006630:	20090793          	addi	a5,s2,512
    80006634:	00479713          	slli	a4,a5,0x4
    80006638:	0001d797          	auipc	a5,0x1d
    8000663c:	9c878793          	addi	a5,a5,-1592 # 80023000 <disk>
    80006640:	97ba                	add	a5,a5,a4
    80006642:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006646:	0001f997          	auipc	s3,0x1f
    8000664a:	9ba98993          	addi	s3,s3,-1606 # 80025000 <disk+0x2000>
    8000664e:	00491713          	slli	a4,s2,0x4
    80006652:	0009b783          	ld	a5,0(s3)
    80006656:	97ba                	add	a5,a5,a4
    80006658:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000665c:	854a                	mv	a0,s2
    8000665e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006662:	00000097          	auipc	ra,0x0
    80006666:	bc4080e7          	jalr	-1084(ra) # 80006226 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000666a:	8885                	andi	s1,s1,1
    8000666c:	f0ed                	bnez	s1,8000664e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000666e:	0001f517          	auipc	a0,0x1f
    80006672:	aba50513          	addi	a0,a0,-1350 # 80025128 <disk+0x2128>
    80006676:	ffffa097          	auipc	ra,0xffffa
    8000667a:	622080e7          	jalr	1570(ra) # 80000c98 <release>
}
    8000667e:	70a6                	ld	ra,104(sp)
    80006680:	7406                	ld	s0,96(sp)
    80006682:	64e6                	ld	s1,88(sp)
    80006684:	6946                	ld	s2,80(sp)
    80006686:	69a6                	ld	s3,72(sp)
    80006688:	6a06                	ld	s4,64(sp)
    8000668a:	7ae2                	ld	s5,56(sp)
    8000668c:	7b42                	ld	s6,48(sp)
    8000668e:	7ba2                	ld	s7,40(sp)
    80006690:	7c02                	ld	s8,32(sp)
    80006692:	6ce2                	ld	s9,24(sp)
    80006694:	6d42                	ld	s10,16(sp)
    80006696:	6165                	addi	sp,sp,112
    80006698:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000669a:	0001f697          	auipc	a3,0x1f
    8000669e:	9666b683          	ld	a3,-1690(a3) # 80025000 <disk+0x2000>
    800066a2:	96ba                	add	a3,a3,a4
    800066a4:	4609                	li	a2,2
    800066a6:	00c69623          	sh	a2,12(a3)
    800066aa:	b5c9                	j	8000656c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066ac:	f9042583          	lw	a1,-112(s0)
    800066b0:	20058793          	addi	a5,a1,512
    800066b4:	0792                	slli	a5,a5,0x4
    800066b6:	0001d517          	auipc	a0,0x1d
    800066ba:	9f250513          	addi	a0,a0,-1550 # 800230a8 <disk+0xa8>
    800066be:	953e                	add	a0,a0,a5
  if(write)
    800066c0:	e20d11e3          	bnez	s10,800064e2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800066c4:	20058713          	addi	a4,a1,512
    800066c8:	00471693          	slli	a3,a4,0x4
    800066cc:	0001d717          	auipc	a4,0x1d
    800066d0:	93470713          	addi	a4,a4,-1740 # 80023000 <disk>
    800066d4:	9736                	add	a4,a4,a3
    800066d6:	0a072423          	sw	zero,168(a4)
    800066da:	b505                	j	800064fa <virtio_disk_rw+0xf4>

00000000800066dc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800066dc:	1101                	addi	sp,sp,-32
    800066de:	ec06                	sd	ra,24(sp)
    800066e0:	e822                	sd	s0,16(sp)
    800066e2:	e426                	sd	s1,8(sp)
    800066e4:	e04a                	sd	s2,0(sp)
    800066e6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800066e8:	0001f517          	auipc	a0,0x1f
    800066ec:	a4050513          	addi	a0,a0,-1472 # 80025128 <disk+0x2128>
    800066f0:	ffffa097          	auipc	ra,0xffffa
    800066f4:	4f4080e7          	jalr	1268(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800066f8:	10001737          	lui	a4,0x10001
    800066fc:	533c                	lw	a5,96(a4)
    800066fe:	8b8d                	andi	a5,a5,3
    80006700:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006702:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006706:	0001f797          	auipc	a5,0x1f
    8000670a:	8fa78793          	addi	a5,a5,-1798 # 80025000 <disk+0x2000>
    8000670e:	6b94                	ld	a3,16(a5)
    80006710:	0207d703          	lhu	a4,32(a5)
    80006714:	0026d783          	lhu	a5,2(a3)
    80006718:	06f70163          	beq	a4,a5,8000677a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000671c:	0001d917          	auipc	s2,0x1d
    80006720:	8e490913          	addi	s2,s2,-1820 # 80023000 <disk>
    80006724:	0001f497          	auipc	s1,0x1f
    80006728:	8dc48493          	addi	s1,s1,-1828 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000672c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006730:	6898                	ld	a4,16(s1)
    80006732:	0204d783          	lhu	a5,32(s1)
    80006736:	8b9d                	andi	a5,a5,7
    80006738:	078e                	slli	a5,a5,0x3
    8000673a:	97ba                	add	a5,a5,a4
    8000673c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000673e:	20078713          	addi	a4,a5,512
    80006742:	0712                	slli	a4,a4,0x4
    80006744:	974a                	add	a4,a4,s2
    80006746:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000674a:	e731                	bnez	a4,80006796 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000674c:	20078793          	addi	a5,a5,512
    80006750:	0792                	slli	a5,a5,0x4
    80006752:	97ca                	add	a5,a5,s2
    80006754:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006756:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000675a:	ffffc097          	auipc	ra,0xffffc
    8000675e:	f7c080e7          	jalr	-132(ra) # 800026d6 <wakeup>

    disk.used_idx += 1;
    80006762:	0204d783          	lhu	a5,32(s1)
    80006766:	2785                	addiw	a5,a5,1
    80006768:	17c2                	slli	a5,a5,0x30
    8000676a:	93c1                	srli	a5,a5,0x30
    8000676c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006770:	6898                	ld	a4,16(s1)
    80006772:	00275703          	lhu	a4,2(a4)
    80006776:	faf71be3          	bne	a4,a5,8000672c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000677a:	0001f517          	auipc	a0,0x1f
    8000677e:	9ae50513          	addi	a0,a0,-1618 # 80025128 <disk+0x2128>
    80006782:	ffffa097          	auipc	ra,0xffffa
    80006786:	516080e7          	jalr	1302(ra) # 80000c98 <release>
}
    8000678a:	60e2                	ld	ra,24(sp)
    8000678c:	6442                	ld	s0,16(sp)
    8000678e:	64a2                	ld	s1,8(sp)
    80006790:	6902                	ld	s2,0(sp)
    80006792:	6105                	addi	sp,sp,32
    80006794:	8082                	ret
      panic("virtio_disk_intr status");
    80006796:	00002517          	auipc	a0,0x2
    8000679a:	0ea50513          	addi	a0,a0,234 # 80008880 <syscalls+0x3b0>
    8000679e:	ffffa097          	auipc	ra,0xffffa
    800067a2:	da0080e7          	jalr	-608(ra) # 8000053e <panic>

00000000800067a6 <cas>:
    800067a6:	100522af          	lr.w	t0,(a0)
    800067aa:	00b29563          	bne	t0,a1,800067b4 <fail>
    800067ae:	18c5252f          	sc.w	a0,a2,(a0)
    800067b2:	8082                	ret

00000000800067b4 <fail>:
    800067b4:	4505                	li	a0,1
    800067b6:	8082                	ret
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
