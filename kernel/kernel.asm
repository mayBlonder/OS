
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
    80000068:	06c78793          	addi	a5,a5,108 # 800060d0 <timervec>
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
    80000130:	838080e7          	jalr	-1992(ra) # 80002964 <either_copyin>
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
    80000214:	6fe080e7          	jalr	1790(ra) # 8000290e <either_copyout>
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
    800002f6:	6c8080e7          	jalr	1736(ra) # 800029ba <procdump>
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
    80000ed8:	cda080e7          	jalr	-806(ra) # 80002bae <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	234080e7          	jalr	564(ra) # 80006110 <plicinithart>
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
    80000f50:	c3a080e7          	jalr	-966(ra) # 80002b86 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	c5a080e7          	jalr	-934(ra) # 80002bae <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	19e080e7          	jalr	414(ra) # 800060fa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	1ac080e7          	jalr	428(ra) # 80006110 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	384080e7          	jalr	900(ra) # 800032f0 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	a14080e7          	jalr	-1516(ra) # 80003988 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	9be080e7          	jalr	-1602(ra) # 8000493a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	2ae080e7          	jalr	686(ra) # 80006232 <virtio_disk_init>
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
    8000185e:	ebc080e7          	jalr	-324(ra) # 80006716 <cas>
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
    80001d28:	b7c7a783          	lw	a5,-1156(a5) # 800088a0 <first.1726>
    80001d2c:	eb89                	bnez	a5,80001d3e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001d2e:	00001097          	auipc	ra,0x1
    80001d32:	e98080e7          	jalr	-360(ra) # 80002bc6 <usertrapret>
}
    80001d36:	60a2                	ld	ra,8(sp)
    80001d38:	6402                	ld	s0,0(sp)
    80001d3a:	0141                	addi	sp,sp,16
    80001d3c:	8082                	ret
    first = 0;
    80001d3e:	00007797          	auipc	a5,0x7
    80001d42:	b607a123          	sw	zero,-1182(a5) # 800088a0 <first.1726>
    fsinit(ROOTDEV);
    80001d46:	4505                	li	a0,1
    80001d48:	00002097          	auipc	ra,0x2
    80001d4c:	bc0080e7          	jalr	-1088(ra) # 80003908 <fsinit>
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
    80001d76:	9a4080e7          	jalr	-1628(ra) # 80006716 <cas>
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
    800020b6:	284080e7          	jalr	644(ra) # 80004336 <namei>
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
    80002200:	7d0080e7          	jalr	2000(ra) # 800049cc <filedup>
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
    80002222:	924080e7          	jalr	-1756(ra) # 80003b42 <idup>
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
    80002382:	79e080e7          	jalr	1950(ra) # 80002b1c <swtch>
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
    80002416:	70a080e7          	jalr	1802(ra) # 80002b1c <swtch>
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
  append(&sleeping_list, p);
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
    80002672:	7159                	addi	sp,sp,-112
    80002674:	f486                	sd	ra,104(sp)
    80002676:	f0a2                	sd	s0,96(sp)
    80002678:	eca6                	sd	s1,88(sp)
    8000267a:	e8ca                	sd	s2,80(sp)
    8000267c:	e4ce                	sd	s3,72(sp)
    8000267e:	e0d2                	sd	s4,64(sp)
    80002680:	fc56                	sd	s5,56(sp)
    80002682:	f85a                	sd	s6,48(sp)
    80002684:	f45e                	sd	s7,40(sp)
    80002686:	f062                	sd	s8,32(sp)
    80002688:	ec66                	sd	s9,24(sp)
    8000268a:	e86a                	sd	s10,16(sp)
    8000268c:	e46e                	sd	s11,8(sp)
    8000268e:	1880                	addi	s0,sp,112
  struct proc *p;

  int curr = sleeping_list.head;
    80002690:	00006917          	auipc	s2,0x6
    80002694:	22092903          	lw	s2,544(s2) # 800088b0 <sleeping_list>

  while(curr != -1) {
    80002698:	57fd                	li	a5,-1
    8000269a:	0af90163          	beq	s2,a5,8000273c <wakeup+0xca>
    8000269e:	8c2a                	mv	s8,a0
    p = &proc[curr];
    800026a0:	19000a13          	li	s4,400
    800026a4:	0000f997          	auipc	s3,0xf
    800026a8:	16c98993          	addi	s3,s3,364 # 80011810 <proc>
    curr = p->next_proc;
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800026ac:	4b89                	li	s7,2
        remove(&sleeping_list, p);
        p->state = RUNNABLE;
    800026ae:	4d8d                	li	s11,3

        #ifdef ON
          p->last_cpu = min_num_procs_cpu();
        #endif
        inc_cpu(&cpus[p->last_cpu]);
    800026b0:	0000fd17          	auipc	s10,0xf
    800026b4:	bf0d0d13          	addi	s10,s10,-1040 # 800112a0 <cpus>
    800026b8:	0a800c93          	li	s9,168
  while(curr != -1) {
    800026bc:	5b7d                	li	s6,-1
    800026be:	a801                	j	800026ce <wakeup+0x5c>

        append(&cpus[p->last_cpu].runnable_list, p);
      }
      release(&p->lock);
    800026c0:	8526                	mv	a0,s1
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	5d6080e7          	jalr	1494(ra) # 80000c98 <release>
  while(curr != -1) {
    800026ca:	07690963          	beq	s2,s6,8000273c <wakeup+0xca>
    p = &proc[curr];
    800026ce:	034904b3          	mul	s1,s2,s4
    800026d2:	94ce                	add	s1,s1,s3
    curr = p->next_proc;
    800026d4:	16c4a903          	lw	s2,364(s1)
    if(p != myproc()){
    800026d8:	fffff097          	auipc	ra,0xfffff
    800026dc:	5f6080e7          	jalr	1526(ra) # 80001cce <myproc>
    800026e0:	fea485e3          	beq	s1,a0,800026ca <wakeup+0x58>
      acquire(&p->lock);
    800026e4:	8526                	mv	a0,s1
    800026e6:	ffffe097          	auipc	ra,0xffffe
    800026ea:	4fe080e7          	jalr	1278(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800026ee:	4c9c                	lw	a5,24(s1)
    800026f0:	fd7798e3          	bne	a5,s7,800026c0 <wakeup+0x4e>
    800026f4:	709c                	ld	a5,32(s1)
    800026f6:	fd8795e3          	bne	a5,s8,800026c0 <wakeup+0x4e>
        remove(&sleeping_list, p);
    800026fa:	85a6                	mv	a1,s1
    800026fc:	00006517          	auipc	a0,0x6
    80002700:	1b450513          	addi	a0,a0,436 # 800088b0 <sleeping_list>
    80002704:	fffff097          	auipc	ra,0xfffff
    80002708:	24a080e7          	jalr	586(ra) # 8000194e <remove>
        p->state = RUNNABLE;
    8000270c:	01b4ac23          	sw	s11,24(s1)
        inc_cpu(&cpus[p->last_cpu]);
    80002710:	1684a503          	lw	a0,360(s1)
    80002714:	03950533          	mul	a0,a0,s9
    80002718:	956a                	add	a0,a0,s10
    8000271a:	fffff097          	auipc	ra,0xfffff
    8000271e:	124080e7          	jalr	292(ra) # 8000183e <inc_cpu>
        append(&cpus[p->last_cpu].runnable_list, p);
    80002722:	1684a503          	lw	a0,360(s1)
    80002726:	03950533          	mul	a0,a0,s9
    8000272a:	08850513          	addi	a0,a0,136
    8000272e:	85a6                	mv	a1,s1
    80002730:	956a                	add	a0,a0,s10
    80002732:	fffff097          	auipc	ra,0xfffff
    80002736:	154080e7          	jalr	340(ra) # 80001886 <append>
    8000273a:	b759                	j	800026c0 <wakeup+0x4e>
    }
  }
}
    8000273c:	70a6                	ld	ra,104(sp)
    8000273e:	7406                	ld	s0,96(sp)
    80002740:	64e6                	ld	s1,88(sp)
    80002742:	6946                	ld	s2,80(sp)
    80002744:	69a6                	ld	s3,72(sp)
    80002746:	6a06                	ld	s4,64(sp)
    80002748:	7ae2                	ld	s5,56(sp)
    8000274a:	7b42                	ld	s6,48(sp)
    8000274c:	7ba2                	ld	s7,40(sp)
    8000274e:	7c02                	ld	s8,32(sp)
    80002750:	6ce2                	ld	s9,24(sp)
    80002752:	6d42                	ld	s10,16(sp)
    80002754:	6da2                	ld	s11,8(sp)
    80002756:	6165                	addi	sp,sp,112
    80002758:	8082                	ret

000000008000275a <reparent>:
{
    8000275a:	7179                	addi	sp,sp,-48
    8000275c:	f406                	sd	ra,40(sp)
    8000275e:	f022                	sd	s0,32(sp)
    80002760:	ec26                	sd	s1,24(sp)
    80002762:	e84a                	sd	s2,16(sp)
    80002764:	e44e                	sd	s3,8(sp)
    80002766:	e052                	sd	s4,0(sp)
    80002768:	1800                	addi	s0,sp,48
    8000276a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000276c:	0000f497          	auipc	s1,0xf
    80002770:	0a448493          	addi	s1,s1,164 # 80011810 <proc>
      pp->parent = initproc;
    80002774:	00007a17          	auipc	s4,0x7
    80002778:	8b4a0a13          	addi	s4,s4,-1868 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000277c:	00015997          	auipc	s3,0x15
    80002780:	49498993          	addi	s3,s3,1172 # 80017c10 <tickslock>
    80002784:	a029                	j	8000278e <reparent+0x34>
    80002786:	19048493          	addi	s1,s1,400
    8000278a:	01348d63          	beq	s1,s3,800027a4 <reparent+0x4a>
    if(pp->parent == p){
    8000278e:	7c9c                	ld	a5,56(s1)
    80002790:	ff279be3          	bne	a5,s2,80002786 <reparent+0x2c>
      pp->parent = initproc;
    80002794:	000a3503          	ld	a0,0(s4)
    80002798:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000279a:	00000097          	auipc	ra,0x0
    8000279e:	ed8080e7          	jalr	-296(ra) # 80002672 <wakeup>
    800027a2:	b7d5                	j	80002786 <reparent+0x2c>
}
    800027a4:	70a2                	ld	ra,40(sp)
    800027a6:	7402                	ld	s0,32(sp)
    800027a8:	64e2                	ld	s1,24(sp)
    800027aa:	6942                	ld	s2,16(sp)
    800027ac:	69a2                	ld	s3,8(sp)
    800027ae:	6a02                	ld	s4,0(sp)
    800027b0:	6145                	addi	sp,sp,48
    800027b2:	8082                	ret

00000000800027b4 <exit>:
{
    800027b4:	7179                	addi	sp,sp,-48
    800027b6:	f406                	sd	ra,40(sp)
    800027b8:	f022                	sd	s0,32(sp)
    800027ba:	ec26                	sd	s1,24(sp)
    800027bc:	e84a                	sd	s2,16(sp)
    800027be:	e44e                	sd	s3,8(sp)
    800027c0:	e052                	sd	s4,0(sp)
    800027c2:	1800                	addi	s0,sp,48
    800027c4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800027c6:	fffff097          	auipc	ra,0xfffff
    800027ca:	508080e7          	jalr	1288(ra) # 80001cce <myproc>
    800027ce:	89aa                	mv	s3,a0
  if(p == initproc)
    800027d0:	00007797          	auipc	a5,0x7
    800027d4:	8587b783          	ld	a5,-1960(a5) # 80009028 <initproc>
    800027d8:	0d050493          	addi	s1,a0,208
    800027dc:	15050913          	addi	s2,a0,336
    800027e0:	02a79363          	bne	a5,a0,80002806 <exit+0x52>
    panic("init exiting");
    800027e4:	00006517          	auipc	a0,0x6
    800027e8:	b0450513          	addi	a0,a0,-1276 # 800082e8 <digits+0x2a8>
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	d52080e7          	jalr	-686(ra) # 8000053e <panic>
      fileclose(f);
    800027f4:	00002097          	auipc	ra,0x2
    800027f8:	22a080e7          	jalr	554(ra) # 80004a1e <fileclose>
      p->ofile[fd] = 0;
    800027fc:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002800:	04a1                	addi	s1,s1,8
    80002802:	01248563          	beq	s1,s2,8000280c <exit+0x58>
    if(p->ofile[fd]){
    80002806:	6088                	ld	a0,0(s1)
    80002808:	f575                	bnez	a0,800027f4 <exit+0x40>
    8000280a:	bfdd                	j	80002800 <exit+0x4c>
  begin_op();
    8000280c:	00002097          	auipc	ra,0x2
    80002810:	d46080e7          	jalr	-698(ra) # 80004552 <begin_op>
  iput(p->cwd);
    80002814:	1509b503          	ld	a0,336(s3)
    80002818:	00001097          	auipc	ra,0x1
    8000281c:	522080e7          	jalr	1314(ra) # 80003d3a <iput>
  end_op();
    80002820:	00002097          	auipc	ra,0x2
    80002824:	db2080e7          	jalr	-590(ra) # 800045d2 <end_op>
  p->cwd = 0;
    80002828:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000282c:	0000f497          	auipc	s1,0xf
    80002830:	fcc48493          	addi	s1,s1,-52 # 800117f8 <wait_lock>
    80002834:	8526                	mv	a0,s1
    80002836:	ffffe097          	auipc	ra,0xffffe
    8000283a:	3ae080e7          	jalr	942(ra) # 80000be4 <acquire>
  reparent(p);
    8000283e:	854e                	mv	a0,s3
    80002840:	00000097          	auipc	ra,0x0
    80002844:	f1a080e7          	jalr	-230(ra) # 8000275a <reparent>
  wakeup(p->parent);
    80002848:	0389b503          	ld	a0,56(s3)
    8000284c:	00000097          	auipc	ra,0x0
    80002850:	e26080e7          	jalr	-474(ra) # 80002672 <wakeup>
  acquire(&p->lock);
    80002854:	854e                	mv	a0,s3
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	38e080e7          	jalr	910(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000285e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002862:	4795                	li	a5,5
    80002864:	00f9ac23          	sw	a5,24(s3)
  append(&zombie_list, p); // exit to admit the exiting process to the ZOMBIE list
    80002868:	85ce                	mv	a1,s3
    8000286a:	00006517          	auipc	a0,0x6
    8000286e:	06650513          	addi	a0,a0,102 # 800088d0 <zombie_list>
    80002872:	fffff097          	auipc	ra,0xfffff
    80002876:	014080e7          	jalr	20(ra) # 80001886 <append>
  release(&wait_lock);
    8000287a:	8526                	mv	a0,s1
    8000287c:	ffffe097          	auipc	ra,0xffffe
    80002880:	41c080e7          	jalr	1052(ra) # 80000c98 <release>
  sched();
    80002884:	00000097          	auipc	ra,0x0
    80002888:	b12080e7          	jalr	-1262(ra) # 80002396 <sched>
  panic("zombie exit");
    8000288c:	00006517          	auipc	a0,0x6
    80002890:	a6c50513          	addi	a0,a0,-1428 # 800082f8 <digits+0x2b8>
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	caa080e7          	jalr	-854(ra) # 8000053e <panic>

000000008000289c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000289c:	7179                	addi	sp,sp,-48
    8000289e:	f406                	sd	ra,40(sp)
    800028a0:	f022                	sd	s0,32(sp)
    800028a2:	ec26                	sd	s1,24(sp)
    800028a4:	e84a                	sd	s2,16(sp)
    800028a6:	e44e                	sd	s3,8(sp)
    800028a8:	1800                	addi	s0,sp,48
    800028aa:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800028ac:	0000f497          	auipc	s1,0xf
    800028b0:	f6448493          	addi	s1,s1,-156 # 80011810 <proc>
    800028b4:	00015997          	auipc	s3,0x15
    800028b8:	35c98993          	addi	s3,s3,860 # 80017c10 <tickslock>
    acquire(&p->lock);
    800028bc:	8526                	mv	a0,s1
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	326080e7          	jalr	806(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800028c6:	589c                	lw	a5,48(s1)
    800028c8:	01278d63          	beq	a5,s2,800028e2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800028cc:	8526                	mv	a0,s1
    800028ce:	ffffe097          	auipc	ra,0xffffe
    800028d2:	3ca080e7          	jalr	970(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800028d6:	19048493          	addi	s1,s1,400
    800028da:	ff3491e3          	bne	s1,s3,800028bc <kill+0x20>
  }
  return -1;
    800028de:	557d                	li	a0,-1
    800028e0:	a829                	j	800028fa <kill+0x5e>
      p->killed = 1;
    800028e2:	4785                	li	a5,1
    800028e4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800028e6:	4c98                	lw	a4,24(s1)
    800028e8:	4789                	li	a5,2
    800028ea:	00f70f63          	beq	a4,a5,80002908 <kill+0x6c>
      release(&p->lock);
    800028ee:	8526                	mv	a0,s1
    800028f0:	ffffe097          	auipc	ra,0xffffe
    800028f4:	3a8080e7          	jalr	936(ra) # 80000c98 <release>
      return 0;
    800028f8:	4501                	li	a0,0
}
    800028fa:	70a2                	ld	ra,40(sp)
    800028fc:	7402                	ld	s0,32(sp)
    800028fe:	64e2                	ld	s1,24(sp)
    80002900:	6942                	ld	s2,16(sp)
    80002902:	69a2                	ld	s3,8(sp)
    80002904:	6145                	addi	sp,sp,48
    80002906:	8082                	ret
        p->state = RUNNABLE;
    80002908:	478d                	li	a5,3
    8000290a:	cc9c                	sw	a5,24(s1)
    8000290c:	b7cd                	j	800028ee <kill+0x52>

000000008000290e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000290e:	7179                	addi	sp,sp,-48
    80002910:	f406                	sd	ra,40(sp)
    80002912:	f022                	sd	s0,32(sp)
    80002914:	ec26                	sd	s1,24(sp)
    80002916:	e84a                	sd	s2,16(sp)
    80002918:	e44e                	sd	s3,8(sp)
    8000291a:	e052                	sd	s4,0(sp)
    8000291c:	1800                	addi	s0,sp,48
    8000291e:	84aa                	mv	s1,a0
    80002920:	892e                	mv	s2,a1
    80002922:	89b2                	mv	s3,a2
    80002924:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002926:	fffff097          	auipc	ra,0xfffff
    8000292a:	3a8080e7          	jalr	936(ra) # 80001cce <myproc>
  if(user_dst){
    8000292e:	c08d                	beqz	s1,80002950 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002930:	86d2                	mv	a3,s4
    80002932:	864e                	mv	a2,s3
    80002934:	85ca                	mv	a1,s2
    80002936:	6928                	ld	a0,80(a0)
    80002938:	fffff097          	auipc	ra,0xfffff
    8000293c:	d3a080e7          	jalr	-710(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002940:	70a2                	ld	ra,40(sp)
    80002942:	7402                	ld	s0,32(sp)
    80002944:	64e2                	ld	s1,24(sp)
    80002946:	6942                	ld	s2,16(sp)
    80002948:	69a2                	ld	s3,8(sp)
    8000294a:	6a02                	ld	s4,0(sp)
    8000294c:	6145                	addi	sp,sp,48
    8000294e:	8082                	ret
    memmove((char *)dst, src, len);
    80002950:	000a061b          	sext.w	a2,s4
    80002954:	85ce                	mv	a1,s3
    80002956:	854a                	mv	a0,s2
    80002958:	ffffe097          	auipc	ra,0xffffe
    8000295c:	3e8080e7          	jalr	1000(ra) # 80000d40 <memmove>
    return 0;
    80002960:	8526                	mv	a0,s1
    80002962:	bff9                	j	80002940 <either_copyout+0x32>

0000000080002964 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002964:	7179                	addi	sp,sp,-48
    80002966:	f406                	sd	ra,40(sp)
    80002968:	f022                	sd	s0,32(sp)
    8000296a:	ec26                	sd	s1,24(sp)
    8000296c:	e84a                	sd	s2,16(sp)
    8000296e:	e44e                	sd	s3,8(sp)
    80002970:	e052                	sd	s4,0(sp)
    80002972:	1800                	addi	s0,sp,48
    80002974:	892a                	mv	s2,a0
    80002976:	84ae                	mv	s1,a1
    80002978:	89b2                	mv	s3,a2
    8000297a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000297c:	fffff097          	auipc	ra,0xfffff
    80002980:	352080e7          	jalr	850(ra) # 80001cce <myproc>
  if(user_src){
    80002984:	c08d                	beqz	s1,800029a6 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002986:	86d2                	mv	a3,s4
    80002988:	864e                	mv	a2,s3
    8000298a:	85ca                	mv	a1,s2
    8000298c:	6928                	ld	a0,80(a0)
    8000298e:	fffff097          	auipc	ra,0xfffff
    80002992:	d70080e7          	jalr	-656(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002996:	70a2                	ld	ra,40(sp)
    80002998:	7402                	ld	s0,32(sp)
    8000299a:	64e2                	ld	s1,24(sp)
    8000299c:	6942                	ld	s2,16(sp)
    8000299e:	69a2                	ld	s3,8(sp)
    800029a0:	6a02                	ld	s4,0(sp)
    800029a2:	6145                	addi	sp,sp,48
    800029a4:	8082                	ret
    memmove(dst, (char*)src, len);
    800029a6:	000a061b          	sext.w	a2,s4
    800029aa:	85ce                	mv	a1,s3
    800029ac:	854a                	mv	a0,s2
    800029ae:	ffffe097          	auipc	ra,0xffffe
    800029b2:	392080e7          	jalr	914(ra) # 80000d40 <memmove>
    return 0;
    800029b6:	8526                	mv	a0,s1
    800029b8:	bff9                	j	80002996 <either_copyin+0x32>

00000000800029ba <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    800029ba:	715d                	addi	sp,sp,-80
    800029bc:	e486                	sd	ra,72(sp)
    800029be:	e0a2                	sd	s0,64(sp)
    800029c0:	fc26                	sd	s1,56(sp)
    800029c2:	f84a                	sd	s2,48(sp)
    800029c4:	f44e                	sd	s3,40(sp)
    800029c6:	f052                	sd	s4,32(sp)
    800029c8:	ec56                	sd	s5,24(sp)
    800029ca:	e85a                	sd	s6,16(sp)
    800029cc:	e45e                	sd	s7,8(sp)
    800029ce:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800029d0:	00005517          	auipc	a0,0x5
    800029d4:	6f850513          	addi	a0,a0,1784 # 800080c8 <digits+0x88>
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	bb0080e7          	jalr	-1104(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800029e0:	0000f497          	auipc	s1,0xf
    800029e4:	f8848493          	addi	s1,s1,-120 # 80011968 <proc+0x158>
    800029e8:	00015917          	auipc	s2,0x15
    800029ec:	38090913          	addi	s2,s2,896 # 80017d68 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029f0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    800029f2:	00006997          	auipc	s3,0x6
    800029f6:	91698993          	addi	s3,s3,-1770 # 80008308 <digits+0x2c8>
    printf("%d %s %s", p->pid, state, p->name);
    800029fa:	00006a97          	auipc	s5,0x6
    800029fe:	916a8a93          	addi	s5,s5,-1770 # 80008310 <digits+0x2d0>
    printf("\n");
    80002a02:	00005a17          	auipc	s4,0x5
    80002a06:	6c6a0a13          	addi	s4,s4,1734 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a0a:	00006b97          	auipc	s7,0x6
    80002a0e:	93eb8b93          	addi	s7,s7,-1730 # 80008348 <states.1764>
    80002a12:	a00d                	j	80002a34 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002a14:	ed86a583          	lw	a1,-296(a3)
    80002a18:	8556                	mv	a0,s5
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	b6e080e7          	jalr	-1170(ra) # 80000588 <printf>
    printf("\n");
    80002a22:	8552                	mv	a0,s4
    80002a24:	ffffe097          	auipc	ra,0xffffe
    80002a28:	b64080e7          	jalr	-1180(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a2c:	19048493          	addi	s1,s1,400
    80002a30:	03248163          	beq	s1,s2,80002a52 <procdump+0x98>
    if(p->state == UNUSED)
    80002a34:	86a6                	mv	a3,s1
    80002a36:	ec04a783          	lw	a5,-320(s1)
    80002a3a:	dbed                	beqz	a5,80002a2c <procdump+0x72>
      state = "???"; 
    80002a3c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a3e:	fcfb6be3          	bltu	s6,a5,80002a14 <procdump+0x5a>
    80002a42:	1782                	slli	a5,a5,0x20
    80002a44:	9381                	srli	a5,a5,0x20
    80002a46:	078e                	slli	a5,a5,0x3
    80002a48:	97de                	add	a5,a5,s7
    80002a4a:	6390                	ld	a2,0(a5)
    80002a4c:	f661                	bnez	a2,80002a14 <procdump+0x5a>
      state = "???"; 
    80002a4e:	864e                	mv	a2,s3
    80002a50:	b7d1                	j	80002a14 <procdump+0x5a>
  }
}
    80002a52:	60a6                	ld	ra,72(sp)
    80002a54:	6406                	ld	s0,64(sp)
    80002a56:	74e2                	ld	s1,56(sp)
    80002a58:	7942                	ld	s2,48(sp)
    80002a5a:	79a2                	ld	s3,40(sp)
    80002a5c:	7a02                	ld	s4,32(sp)
    80002a5e:	6ae2                	ld	s5,24(sp)
    80002a60:	6b42                	ld	s6,16(sp)
    80002a62:	6ba2                	ld	s7,8(sp)
    80002a64:	6161                	addi	sp,sp,80
    80002a66:	8082                	ret

0000000080002a68 <set_cpu>:

// move process to different CPU. 
int
set_cpu(int cpu_num) {
  int fail = -1;
  if(cpu_num < NCPU) {
    80002a68:	479d                	li	a5,7
    80002a6a:	04a7e863          	bltu	a5,a0,80002aba <set_cpu+0x52>
set_cpu(int cpu_num) {
    80002a6e:	1101                	addi	sp,sp,-32
    80002a70:	ec06                	sd	ra,24(sp)
    80002a72:	e822                	sd	s0,16(sp)
    80002a74:	e426                	sd	s1,8(sp)
    80002a76:	1000                	addi	s0,sp,32
    80002a78:	84aa                	mv	s1,a0
   if(cpu_num >= 0) {
     struct cpu *c = &cpus[cpu_num];
     if(c != NULL) {
        acquire(&myproc()->lock);
    80002a7a:	fffff097          	auipc	ra,0xfffff
    80002a7e:	254080e7          	jalr	596(ra) # 80001cce <myproc>
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	162080e7          	jalr	354(ra) # 80000be4 <acquire>
        myproc()->last_cpu = cpu_num;
    80002a8a:	fffff097          	auipc	ra,0xfffff
    80002a8e:	244080e7          	jalr	580(ra) # 80001cce <myproc>
    80002a92:	16952423          	sw	s1,360(a0)
        release(&myproc()->lock);
    80002a96:	fffff097          	auipc	ra,0xfffff
    80002a9a:	238080e7          	jalr	568(ra) # 80001cce <myproc>
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	1fa080e7          	jalr	506(ra) # 80000c98 <release>

        // RUNNING -> RUNNABLE
        yield();
    80002aa6:	00000097          	auipc	ra,0x0
    80002aaa:	9d2080e7          	jalr	-1582(ra) # 80002478 <yield>
        return cpu_num;
    80002aae:	8526                	mv	a0,s1
      }
    }
  }
  return fail;
}
    80002ab0:	60e2                	ld	ra,24(sp)
    80002ab2:	6442                	ld	s0,16(sp)
    80002ab4:	64a2                	ld	s1,8(sp)
    80002ab6:	6105                	addi	sp,sp,32
    80002ab8:	8082                	ret
  return fail;
    80002aba:	557d                	li	a0,-1
}
    80002abc:	8082                	ret

0000000080002abe <get_cpu>:

// returns current CPU.
int
get_cpu(void){
    80002abe:	1141                	addi	sp,sp,-16
    80002ac0:	e406                	sd	ra,8(sp)
    80002ac2:	e022                	sd	s0,0(sp)
    80002ac4:	0800                	addi	s0,sp,16

  // If process was not chosen by any cpy the value of myproc()->last_cpu is -1.
  return myproc()->last_cpu;
    80002ac6:	fffff097          	auipc	ra,0xfffff
    80002aca:	208080e7          	jalr	520(ra) # 80001cce <myproc>
}
    80002ace:	16852503          	lw	a0,360(a0)
    80002ad2:	60a2                	ld	ra,8(sp)
    80002ad4:	6402                	ld	s0,0(sp)
    80002ad6:	0141                	addi	sp,sp,16
    80002ad8:	8082                	ret

0000000080002ada <min_cpu>:

int
min_cpu(void){
    80002ada:	1141                	addi	sp,sp,-16
    80002adc:	e422                	sd	s0,8(sp)
    80002ade:	0800                	addi	s0,sp,16
  struct cpu *c;
  struct cpu *min_cpu = cpus;
    80002ae0:	0000e617          	auipc	a2,0xe
    80002ae4:	7c060613          	addi	a2,a2,1984 # 800112a0 <cpus>
  
  for(c = cpus + 1; c < &cpus[NCPU] && c != NULL ; c++){
    80002ae8:	0000f797          	auipc	a5,0xf
    80002aec:	86078793          	addi	a5,a5,-1952 # 80011348 <cpus+0xa8>
    80002af0:	0000f597          	auipc	a1,0xf
    80002af4:	cf058593          	addi	a1,a1,-784 # 800117e0 <pid_lock>
    80002af8:	a029                	j	80002b02 <min_cpu+0x28>
    80002afa:	0a878793          	addi	a5,a5,168
    80002afe:	00b78a63          	beq	a5,a1,80002b12 <min_cpu+0x38>
    if (c->proc_cnt < min_cpu->proc_cnt)
    80002b02:	0807a683          	lw	a3,128(a5)
    80002b06:	08062703          	lw	a4,128(a2)
    80002b0a:	fee6d8e3          	bge	a3,a4,80002afa <min_cpu+0x20>
    80002b0e:	863e                	mv	a2,a5
    80002b10:	b7ed                	j	80002afa <min_cpu+0x20>
        min_cpu = c;
  }
  return min_cpu->cpu_id;   
}
    80002b12:	08462503          	lw	a0,132(a2)
    80002b16:	6422                	ld	s0,8(sp)
    80002b18:	0141                	addi	sp,sp,16
    80002b1a:	8082                	ret

0000000080002b1c <swtch>:
    80002b1c:	00153023          	sd	ra,0(a0)
    80002b20:	00253423          	sd	sp,8(a0)
    80002b24:	e900                	sd	s0,16(a0)
    80002b26:	ed04                	sd	s1,24(a0)
    80002b28:	03253023          	sd	s2,32(a0)
    80002b2c:	03353423          	sd	s3,40(a0)
    80002b30:	03453823          	sd	s4,48(a0)
    80002b34:	03553c23          	sd	s5,56(a0)
    80002b38:	05653023          	sd	s6,64(a0)
    80002b3c:	05753423          	sd	s7,72(a0)
    80002b40:	05853823          	sd	s8,80(a0)
    80002b44:	05953c23          	sd	s9,88(a0)
    80002b48:	07a53023          	sd	s10,96(a0)
    80002b4c:	07b53423          	sd	s11,104(a0)
    80002b50:	0005b083          	ld	ra,0(a1)
    80002b54:	0085b103          	ld	sp,8(a1)
    80002b58:	6980                	ld	s0,16(a1)
    80002b5a:	6d84                	ld	s1,24(a1)
    80002b5c:	0205b903          	ld	s2,32(a1)
    80002b60:	0285b983          	ld	s3,40(a1)
    80002b64:	0305ba03          	ld	s4,48(a1)
    80002b68:	0385ba83          	ld	s5,56(a1)
    80002b6c:	0405bb03          	ld	s6,64(a1)
    80002b70:	0485bb83          	ld	s7,72(a1)
    80002b74:	0505bc03          	ld	s8,80(a1)
    80002b78:	0585bc83          	ld	s9,88(a1)
    80002b7c:	0605bd03          	ld	s10,96(a1)
    80002b80:	0685bd83          	ld	s11,104(a1)
    80002b84:	8082                	ret

0000000080002b86 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b86:	1141                	addi	sp,sp,-16
    80002b88:	e406                	sd	ra,8(sp)
    80002b8a:	e022                	sd	s0,0(sp)
    80002b8c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b8e:	00005597          	auipc	a1,0x5
    80002b92:	7ea58593          	addi	a1,a1,2026 # 80008378 <states.1764+0x30>
    80002b96:	00015517          	auipc	a0,0x15
    80002b9a:	07a50513          	addi	a0,a0,122 # 80017c10 <tickslock>
    80002b9e:	ffffe097          	auipc	ra,0xffffe
    80002ba2:	fb6080e7          	jalr	-74(ra) # 80000b54 <initlock>
}
    80002ba6:	60a2                	ld	ra,8(sp)
    80002ba8:	6402                	ld	s0,0(sp)
    80002baa:	0141                	addi	sp,sp,16
    80002bac:	8082                	ret

0000000080002bae <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002bae:	1141                	addi	sp,sp,-16
    80002bb0:	e422                	sd	s0,8(sp)
    80002bb2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bb4:	00003797          	auipc	a5,0x3
    80002bb8:	48c78793          	addi	a5,a5,1164 # 80006040 <kernelvec>
    80002bbc:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002bc0:	6422                	ld	s0,8(sp)
    80002bc2:	0141                	addi	sp,sp,16
    80002bc4:	8082                	ret

0000000080002bc6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002bc6:	1141                	addi	sp,sp,-16
    80002bc8:	e406                	sd	ra,8(sp)
    80002bca:	e022                	sd	s0,0(sp)
    80002bcc:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002bce:	fffff097          	auipc	ra,0xfffff
    80002bd2:	100080e7          	jalr	256(ra) # 80001cce <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bd6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002bda:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bdc:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002be0:	00004617          	auipc	a2,0x4
    80002be4:	42060613          	addi	a2,a2,1056 # 80007000 <_trampoline>
    80002be8:	00004697          	auipc	a3,0x4
    80002bec:	41868693          	addi	a3,a3,1048 # 80007000 <_trampoline>
    80002bf0:	8e91                	sub	a3,a3,a2
    80002bf2:	040007b7          	lui	a5,0x4000
    80002bf6:	17fd                	addi	a5,a5,-1
    80002bf8:	07b2                	slli	a5,a5,0xc
    80002bfa:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bfc:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c00:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c02:	180026f3          	csrr	a3,satp
    80002c06:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c08:	6d38                	ld	a4,88(a0)
    80002c0a:	6134                	ld	a3,64(a0)
    80002c0c:	6585                	lui	a1,0x1
    80002c0e:	96ae                	add	a3,a3,a1
    80002c10:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c12:	6d38                	ld	a4,88(a0)
    80002c14:	00000697          	auipc	a3,0x0
    80002c18:	13868693          	addi	a3,a3,312 # 80002d4c <usertrap>
    80002c1c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c1e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c20:	8692                	mv	a3,tp
    80002c22:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c24:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c28:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c2c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c30:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c34:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c36:	6f18                	ld	a4,24(a4)
    80002c38:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c3c:	692c                	ld	a1,80(a0)
    80002c3e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002c40:	00004717          	auipc	a4,0x4
    80002c44:	45070713          	addi	a4,a4,1104 # 80007090 <userret>
    80002c48:	8f11                	sub	a4,a4,a2
    80002c4a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002c4c:	577d                	li	a4,-1
    80002c4e:	177e                	slli	a4,a4,0x3f
    80002c50:	8dd9                	or	a1,a1,a4
    80002c52:	02000537          	lui	a0,0x2000
    80002c56:	157d                	addi	a0,a0,-1
    80002c58:	0536                	slli	a0,a0,0xd
    80002c5a:	9782                	jalr	a5
}
    80002c5c:	60a2                	ld	ra,8(sp)
    80002c5e:	6402                	ld	s0,0(sp)
    80002c60:	0141                	addi	sp,sp,16
    80002c62:	8082                	ret

0000000080002c64 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c64:	1101                	addi	sp,sp,-32
    80002c66:	ec06                	sd	ra,24(sp)
    80002c68:	e822                	sd	s0,16(sp)
    80002c6a:	e426                	sd	s1,8(sp)
    80002c6c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c6e:	00015497          	auipc	s1,0x15
    80002c72:	fa248493          	addi	s1,s1,-94 # 80017c10 <tickslock>
    80002c76:	8526                	mv	a0,s1
    80002c78:	ffffe097          	auipc	ra,0xffffe
    80002c7c:	f6c080e7          	jalr	-148(ra) # 80000be4 <acquire>
  ticks++;
    80002c80:	00006517          	auipc	a0,0x6
    80002c84:	3b050513          	addi	a0,a0,944 # 80009030 <ticks>
    80002c88:	411c                	lw	a5,0(a0)
    80002c8a:	2785                	addiw	a5,a5,1
    80002c8c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002c8e:	00000097          	auipc	ra,0x0
    80002c92:	9e4080e7          	jalr	-1564(ra) # 80002672 <wakeup>
  release(&tickslock);
    80002c96:	8526                	mv	a0,s1
    80002c98:	ffffe097          	auipc	ra,0xffffe
    80002c9c:	000080e7          	jalr	ra # 80000c98 <release>
}
    80002ca0:	60e2                	ld	ra,24(sp)
    80002ca2:	6442                	ld	s0,16(sp)
    80002ca4:	64a2                	ld	s1,8(sp)
    80002ca6:	6105                	addi	sp,sp,32
    80002ca8:	8082                	ret

0000000080002caa <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002caa:	1101                	addi	sp,sp,-32
    80002cac:	ec06                	sd	ra,24(sp)
    80002cae:	e822                	sd	s0,16(sp)
    80002cb0:	e426                	sd	s1,8(sp)
    80002cb2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cb4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002cb8:	00074d63          	bltz	a4,80002cd2 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002cbc:	57fd                	li	a5,-1
    80002cbe:	17fe                	slli	a5,a5,0x3f
    80002cc0:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002cc2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002cc4:	06f70363          	beq	a4,a5,80002d2a <devintr+0x80>
  }
}
    80002cc8:	60e2                	ld	ra,24(sp)
    80002cca:	6442                	ld	s0,16(sp)
    80002ccc:	64a2                	ld	s1,8(sp)
    80002cce:	6105                	addi	sp,sp,32
    80002cd0:	8082                	ret
     (scause & 0xff) == 9){
    80002cd2:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002cd6:	46a5                	li	a3,9
    80002cd8:	fed792e3          	bne	a5,a3,80002cbc <devintr+0x12>
    int irq = plic_claim();
    80002cdc:	00003097          	auipc	ra,0x3
    80002ce0:	46c080e7          	jalr	1132(ra) # 80006148 <plic_claim>
    80002ce4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ce6:	47a9                	li	a5,10
    80002ce8:	02f50763          	beq	a0,a5,80002d16 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002cec:	4785                	li	a5,1
    80002cee:	02f50963          	beq	a0,a5,80002d20 <devintr+0x76>
    return 1;
    80002cf2:	4505                	li	a0,1
    } else if(irq){
    80002cf4:	d8f1                	beqz	s1,80002cc8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002cf6:	85a6                	mv	a1,s1
    80002cf8:	00005517          	auipc	a0,0x5
    80002cfc:	68850513          	addi	a0,a0,1672 # 80008380 <states.1764+0x38>
    80002d00:	ffffe097          	auipc	ra,0xffffe
    80002d04:	888080e7          	jalr	-1912(ra) # 80000588 <printf>
      plic_complete(irq);
    80002d08:	8526                	mv	a0,s1
    80002d0a:	00003097          	auipc	ra,0x3
    80002d0e:	462080e7          	jalr	1122(ra) # 8000616c <plic_complete>
    return 1;
    80002d12:	4505                	li	a0,1
    80002d14:	bf55                	j	80002cc8 <devintr+0x1e>
      uartintr();
    80002d16:	ffffe097          	auipc	ra,0xffffe
    80002d1a:	c92080e7          	jalr	-878(ra) # 800009a8 <uartintr>
    80002d1e:	b7ed                	j	80002d08 <devintr+0x5e>
      virtio_disk_intr();
    80002d20:	00004097          	auipc	ra,0x4
    80002d24:	92c080e7          	jalr	-1748(ra) # 8000664c <virtio_disk_intr>
    80002d28:	b7c5                	j	80002d08 <devintr+0x5e>
    if(cpuid() == 0){
    80002d2a:	fffff097          	auipc	ra,0xfffff
    80002d2e:	f72080e7          	jalr	-142(ra) # 80001c9c <cpuid>
    80002d32:	c901                	beqz	a0,80002d42 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d34:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d38:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d3a:	14479073          	csrw	sip,a5
    return 2;
    80002d3e:	4509                	li	a0,2
    80002d40:	b761                	j	80002cc8 <devintr+0x1e>
      clockintr();
    80002d42:	00000097          	auipc	ra,0x0
    80002d46:	f22080e7          	jalr	-222(ra) # 80002c64 <clockintr>
    80002d4a:	b7ed                	j	80002d34 <devintr+0x8a>

0000000080002d4c <usertrap>:
{
    80002d4c:	1101                	addi	sp,sp,-32
    80002d4e:	ec06                	sd	ra,24(sp)
    80002d50:	e822                	sd	s0,16(sp)
    80002d52:	e426                	sd	s1,8(sp)
    80002d54:	e04a                	sd	s2,0(sp)
    80002d56:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d58:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d5c:	1007f793          	andi	a5,a5,256
    80002d60:	e3ad                	bnez	a5,80002dc2 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d62:	00003797          	auipc	a5,0x3
    80002d66:	2de78793          	addi	a5,a5,734 # 80006040 <kernelvec>
    80002d6a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	f60080e7          	jalr	-160(ra) # 80001cce <myproc>
    80002d76:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d78:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d7a:	14102773          	csrr	a4,sepc
    80002d7e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d80:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002d84:	47a1                	li	a5,8
    80002d86:	04f71c63          	bne	a4,a5,80002dde <usertrap+0x92>
    if(p->killed)
    80002d8a:	551c                	lw	a5,40(a0)
    80002d8c:	e3b9                	bnez	a5,80002dd2 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002d8e:	6cb8                	ld	a4,88(s1)
    80002d90:	6f1c                	ld	a5,24(a4)
    80002d92:	0791                	addi	a5,a5,4
    80002d94:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d96:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d9a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d9e:	10079073          	csrw	sstatus,a5
    syscall();
    80002da2:	00000097          	auipc	ra,0x0
    80002da6:	2e0080e7          	jalr	736(ra) # 80003082 <syscall>
  if(p->killed)
    80002daa:	549c                	lw	a5,40(s1)
    80002dac:	ebc1                	bnez	a5,80002e3c <usertrap+0xf0>
  usertrapret();
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	e18080e7          	jalr	-488(ra) # 80002bc6 <usertrapret>
}
    80002db6:	60e2                	ld	ra,24(sp)
    80002db8:	6442                	ld	s0,16(sp)
    80002dba:	64a2                	ld	s1,8(sp)
    80002dbc:	6902                	ld	s2,0(sp)
    80002dbe:	6105                	addi	sp,sp,32
    80002dc0:	8082                	ret
    panic("usertrap: not from user mode");
    80002dc2:	00005517          	auipc	a0,0x5
    80002dc6:	5de50513          	addi	a0,a0,1502 # 800083a0 <states.1764+0x58>
    80002dca:	ffffd097          	auipc	ra,0xffffd
    80002dce:	774080e7          	jalr	1908(ra) # 8000053e <panic>
      exit(-1);
    80002dd2:	557d                	li	a0,-1
    80002dd4:	00000097          	auipc	ra,0x0
    80002dd8:	9e0080e7          	jalr	-1568(ra) # 800027b4 <exit>
    80002ddc:	bf4d                	j	80002d8e <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002dde:	00000097          	auipc	ra,0x0
    80002de2:	ecc080e7          	jalr	-308(ra) # 80002caa <devintr>
    80002de6:	892a                	mv	s2,a0
    80002de8:	c501                	beqz	a0,80002df0 <usertrap+0xa4>
  if(p->killed)
    80002dea:	549c                	lw	a5,40(s1)
    80002dec:	c3a1                	beqz	a5,80002e2c <usertrap+0xe0>
    80002dee:	a815                	j	80002e22 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002df0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002df4:	5890                	lw	a2,48(s1)
    80002df6:	00005517          	auipc	a0,0x5
    80002dfa:	5ca50513          	addi	a0,a0,1482 # 800083c0 <states.1764+0x78>
    80002dfe:	ffffd097          	auipc	ra,0xffffd
    80002e02:	78a080e7          	jalr	1930(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e06:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e0a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e0e:	00005517          	auipc	a0,0x5
    80002e12:	5e250513          	addi	a0,a0,1506 # 800083f0 <states.1764+0xa8>
    80002e16:	ffffd097          	auipc	ra,0xffffd
    80002e1a:	772080e7          	jalr	1906(ra) # 80000588 <printf>
    p->killed = 1;
    80002e1e:	4785                	li	a5,1
    80002e20:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002e22:	557d                	li	a0,-1
    80002e24:	00000097          	auipc	ra,0x0
    80002e28:	990080e7          	jalr	-1648(ra) # 800027b4 <exit>
  if(which_dev == 2)
    80002e2c:	4789                	li	a5,2
    80002e2e:	f8f910e3          	bne	s2,a5,80002dae <usertrap+0x62>
    yield();
    80002e32:	fffff097          	auipc	ra,0xfffff
    80002e36:	646080e7          	jalr	1606(ra) # 80002478 <yield>
    80002e3a:	bf95                	j	80002dae <usertrap+0x62>
  int which_dev = 0;
    80002e3c:	4901                	li	s2,0
    80002e3e:	b7d5                	j	80002e22 <usertrap+0xd6>

0000000080002e40 <kerneltrap>:
{
    80002e40:	7179                	addi	sp,sp,-48
    80002e42:	f406                	sd	ra,40(sp)
    80002e44:	f022                	sd	s0,32(sp)
    80002e46:	ec26                	sd	s1,24(sp)
    80002e48:	e84a                	sd	s2,16(sp)
    80002e4a:	e44e                	sd	s3,8(sp)
    80002e4c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e4e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e52:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e56:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e5a:	1004f793          	andi	a5,s1,256
    80002e5e:	cb85                	beqz	a5,80002e8e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e60:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e64:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e66:	ef85                	bnez	a5,80002e9e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e68:	00000097          	auipc	ra,0x0
    80002e6c:	e42080e7          	jalr	-446(ra) # 80002caa <devintr>
    80002e70:	cd1d                	beqz	a0,80002eae <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e72:	4789                	li	a5,2
    80002e74:	06f50a63          	beq	a0,a5,80002ee8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e78:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e7c:	10049073          	csrw	sstatus,s1
}
    80002e80:	70a2                	ld	ra,40(sp)
    80002e82:	7402                	ld	s0,32(sp)
    80002e84:	64e2                	ld	s1,24(sp)
    80002e86:	6942                	ld	s2,16(sp)
    80002e88:	69a2                	ld	s3,8(sp)
    80002e8a:	6145                	addi	sp,sp,48
    80002e8c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e8e:	00005517          	auipc	a0,0x5
    80002e92:	58250513          	addi	a0,a0,1410 # 80008410 <states.1764+0xc8>
    80002e96:	ffffd097          	auipc	ra,0xffffd
    80002e9a:	6a8080e7          	jalr	1704(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002e9e:	00005517          	auipc	a0,0x5
    80002ea2:	59a50513          	addi	a0,a0,1434 # 80008438 <states.1764+0xf0>
    80002ea6:	ffffd097          	auipc	ra,0xffffd
    80002eaa:	698080e7          	jalr	1688(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002eae:	85ce                	mv	a1,s3
    80002eb0:	00005517          	auipc	a0,0x5
    80002eb4:	5a850513          	addi	a0,a0,1448 # 80008458 <states.1764+0x110>
    80002eb8:	ffffd097          	auipc	ra,0xffffd
    80002ebc:	6d0080e7          	jalr	1744(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ec0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ec4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ec8:	00005517          	auipc	a0,0x5
    80002ecc:	5a050513          	addi	a0,a0,1440 # 80008468 <states.1764+0x120>
    80002ed0:	ffffd097          	auipc	ra,0xffffd
    80002ed4:	6b8080e7          	jalr	1720(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002ed8:	00005517          	auipc	a0,0x5
    80002edc:	5a850513          	addi	a0,a0,1448 # 80008480 <states.1764+0x138>
    80002ee0:	ffffd097          	auipc	ra,0xffffd
    80002ee4:	65e080e7          	jalr	1630(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ee8:	fffff097          	auipc	ra,0xfffff
    80002eec:	de6080e7          	jalr	-538(ra) # 80001cce <myproc>
    80002ef0:	d541                	beqz	a0,80002e78 <kerneltrap+0x38>
    80002ef2:	fffff097          	auipc	ra,0xfffff
    80002ef6:	ddc080e7          	jalr	-548(ra) # 80001cce <myproc>
    80002efa:	4d18                	lw	a4,24(a0)
    80002efc:	4791                	li	a5,4
    80002efe:	f6f71de3          	bne	a4,a5,80002e78 <kerneltrap+0x38>
    yield();
    80002f02:	fffff097          	auipc	ra,0xfffff
    80002f06:	576080e7          	jalr	1398(ra) # 80002478 <yield>
    80002f0a:	b7bd                	j	80002e78 <kerneltrap+0x38>

0000000080002f0c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f0c:	1101                	addi	sp,sp,-32
    80002f0e:	ec06                	sd	ra,24(sp)
    80002f10:	e822                	sd	s0,16(sp)
    80002f12:	e426                	sd	s1,8(sp)
    80002f14:	1000                	addi	s0,sp,32
    80002f16:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f18:	fffff097          	auipc	ra,0xfffff
    80002f1c:	db6080e7          	jalr	-586(ra) # 80001cce <myproc>
  switch (n) {
    80002f20:	4795                	li	a5,5
    80002f22:	0497e163          	bltu	a5,s1,80002f64 <argraw+0x58>
    80002f26:	048a                	slli	s1,s1,0x2
    80002f28:	00005717          	auipc	a4,0x5
    80002f2c:	59070713          	addi	a4,a4,1424 # 800084b8 <states.1764+0x170>
    80002f30:	94ba                	add	s1,s1,a4
    80002f32:	409c                	lw	a5,0(s1)
    80002f34:	97ba                	add	a5,a5,a4
    80002f36:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002f38:	6d3c                	ld	a5,88(a0)
    80002f3a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f3c:	60e2                	ld	ra,24(sp)
    80002f3e:	6442                	ld	s0,16(sp)
    80002f40:	64a2                	ld	s1,8(sp)
    80002f42:	6105                	addi	sp,sp,32
    80002f44:	8082                	ret
    return p->trapframe->a1;
    80002f46:	6d3c                	ld	a5,88(a0)
    80002f48:	7fa8                	ld	a0,120(a5)
    80002f4a:	bfcd                	j	80002f3c <argraw+0x30>
    return p->trapframe->a2;
    80002f4c:	6d3c                	ld	a5,88(a0)
    80002f4e:	63c8                	ld	a0,128(a5)
    80002f50:	b7f5                	j	80002f3c <argraw+0x30>
    return p->trapframe->a3;
    80002f52:	6d3c                	ld	a5,88(a0)
    80002f54:	67c8                	ld	a0,136(a5)
    80002f56:	b7dd                	j	80002f3c <argraw+0x30>
    return p->trapframe->a4;
    80002f58:	6d3c                	ld	a5,88(a0)
    80002f5a:	6bc8                	ld	a0,144(a5)
    80002f5c:	b7c5                	j	80002f3c <argraw+0x30>
    return p->trapframe->a5;
    80002f5e:	6d3c                	ld	a5,88(a0)
    80002f60:	6fc8                	ld	a0,152(a5)
    80002f62:	bfe9                	j	80002f3c <argraw+0x30>
  panic("argraw");
    80002f64:	00005517          	auipc	a0,0x5
    80002f68:	52c50513          	addi	a0,a0,1324 # 80008490 <states.1764+0x148>
    80002f6c:	ffffd097          	auipc	ra,0xffffd
    80002f70:	5d2080e7          	jalr	1490(ra) # 8000053e <panic>

0000000080002f74 <fetchaddr>:
{
    80002f74:	1101                	addi	sp,sp,-32
    80002f76:	ec06                	sd	ra,24(sp)
    80002f78:	e822                	sd	s0,16(sp)
    80002f7a:	e426                	sd	s1,8(sp)
    80002f7c:	e04a                	sd	s2,0(sp)
    80002f7e:	1000                	addi	s0,sp,32
    80002f80:	84aa                	mv	s1,a0
    80002f82:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002f84:	fffff097          	auipc	ra,0xfffff
    80002f88:	d4a080e7          	jalr	-694(ra) # 80001cce <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002f8c:	653c                	ld	a5,72(a0)
    80002f8e:	02f4f863          	bgeu	s1,a5,80002fbe <fetchaddr+0x4a>
    80002f92:	00848713          	addi	a4,s1,8
    80002f96:	02e7e663          	bltu	a5,a4,80002fc2 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f9a:	46a1                	li	a3,8
    80002f9c:	8626                	mv	a2,s1
    80002f9e:	85ca                	mv	a1,s2
    80002fa0:	6928                	ld	a0,80(a0)
    80002fa2:	ffffe097          	auipc	ra,0xffffe
    80002fa6:	75c080e7          	jalr	1884(ra) # 800016fe <copyin>
    80002faa:	00a03533          	snez	a0,a0
    80002fae:	40a00533          	neg	a0,a0
}
    80002fb2:	60e2                	ld	ra,24(sp)
    80002fb4:	6442                	ld	s0,16(sp)
    80002fb6:	64a2                	ld	s1,8(sp)
    80002fb8:	6902                	ld	s2,0(sp)
    80002fba:	6105                	addi	sp,sp,32
    80002fbc:	8082                	ret
    return -1;
    80002fbe:	557d                	li	a0,-1
    80002fc0:	bfcd                	j	80002fb2 <fetchaddr+0x3e>
    80002fc2:	557d                	li	a0,-1
    80002fc4:	b7fd                	j	80002fb2 <fetchaddr+0x3e>

0000000080002fc6 <fetchstr>:
{
    80002fc6:	7179                	addi	sp,sp,-48
    80002fc8:	f406                	sd	ra,40(sp)
    80002fca:	f022                	sd	s0,32(sp)
    80002fcc:	ec26                	sd	s1,24(sp)
    80002fce:	e84a                	sd	s2,16(sp)
    80002fd0:	e44e                	sd	s3,8(sp)
    80002fd2:	1800                	addi	s0,sp,48
    80002fd4:	892a                	mv	s2,a0
    80002fd6:	84ae                	mv	s1,a1
    80002fd8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002fda:	fffff097          	auipc	ra,0xfffff
    80002fde:	cf4080e7          	jalr	-780(ra) # 80001cce <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002fe2:	86ce                	mv	a3,s3
    80002fe4:	864a                	mv	a2,s2
    80002fe6:	85a6                	mv	a1,s1
    80002fe8:	6928                	ld	a0,80(a0)
    80002fea:	ffffe097          	auipc	ra,0xffffe
    80002fee:	7a0080e7          	jalr	1952(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002ff2:	00054763          	bltz	a0,80003000 <fetchstr+0x3a>
  return strlen(buf);
    80002ff6:	8526                	mv	a0,s1
    80002ff8:	ffffe097          	auipc	ra,0xffffe
    80002ffc:	e6c080e7          	jalr	-404(ra) # 80000e64 <strlen>
}
    80003000:	70a2                	ld	ra,40(sp)
    80003002:	7402                	ld	s0,32(sp)
    80003004:	64e2                	ld	s1,24(sp)
    80003006:	6942                	ld	s2,16(sp)
    80003008:	69a2                	ld	s3,8(sp)
    8000300a:	6145                	addi	sp,sp,48
    8000300c:	8082                	ret

000000008000300e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000300e:	1101                	addi	sp,sp,-32
    80003010:	ec06                	sd	ra,24(sp)
    80003012:	e822                	sd	s0,16(sp)
    80003014:	e426                	sd	s1,8(sp)
    80003016:	1000                	addi	s0,sp,32
    80003018:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000301a:	00000097          	auipc	ra,0x0
    8000301e:	ef2080e7          	jalr	-270(ra) # 80002f0c <argraw>
    80003022:	c088                	sw	a0,0(s1)
  return 0;
}
    80003024:	4501                	li	a0,0
    80003026:	60e2                	ld	ra,24(sp)
    80003028:	6442                	ld	s0,16(sp)
    8000302a:	64a2                	ld	s1,8(sp)
    8000302c:	6105                	addi	sp,sp,32
    8000302e:	8082                	ret

0000000080003030 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003030:	1101                	addi	sp,sp,-32
    80003032:	ec06                	sd	ra,24(sp)
    80003034:	e822                	sd	s0,16(sp)
    80003036:	e426                	sd	s1,8(sp)
    80003038:	1000                	addi	s0,sp,32
    8000303a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000303c:	00000097          	auipc	ra,0x0
    80003040:	ed0080e7          	jalr	-304(ra) # 80002f0c <argraw>
    80003044:	e088                	sd	a0,0(s1)
  return 0;
}
    80003046:	4501                	li	a0,0
    80003048:	60e2                	ld	ra,24(sp)
    8000304a:	6442                	ld	s0,16(sp)
    8000304c:	64a2                	ld	s1,8(sp)
    8000304e:	6105                	addi	sp,sp,32
    80003050:	8082                	ret

0000000080003052 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003052:	1101                	addi	sp,sp,-32
    80003054:	ec06                	sd	ra,24(sp)
    80003056:	e822                	sd	s0,16(sp)
    80003058:	e426                	sd	s1,8(sp)
    8000305a:	e04a                	sd	s2,0(sp)
    8000305c:	1000                	addi	s0,sp,32
    8000305e:	84ae                	mv	s1,a1
    80003060:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003062:	00000097          	auipc	ra,0x0
    80003066:	eaa080e7          	jalr	-342(ra) # 80002f0c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000306a:	864a                	mv	a2,s2
    8000306c:	85a6                	mv	a1,s1
    8000306e:	00000097          	auipc	ra,0x0
    80003072:	f58080e7          	jalr	-168(ra) # 80002fc6 <fetchstr>
}
    80003076:	60e2                	ld	ra,24(sp)
    80003078:	6442                	ld	s0,16(sp)
    8000307a:	64a2                	ld	s1,8(sp)
    8000307c:	6902                	ld	s2,0(sp)
    8000307e:	6105                	addi	sp,sp,32
    80003080:	8082                	ret

0000000080003082 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80003082:	1101                	addi	sp,sp,-32
    80003084:	ec06                	sd	ra,24(sp)
    80003086:	e822                	sd	s0,16(sp)
    80003088:	e426                	sd	s1,8(sp)
    8000308a:	e04a                	sd	s2,0(sp)
    8000308c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000308e:	fffff097          	auipc	ra,0xfffff
    80003092:	c40080e7          	jalr	-960(ra) # 80001cce <myproc>
    80003096:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003098:	05853903          	ld	s2,88(a0)
    8000309c:	0a893783          	ld	a5,168(s2)
    800030a0:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800030a4:	37fd                	addiw	a5,a5,-1
    800030a6:	4751                	li	a4,20
    800030a8:	00f76f63          	bltu	a4,a5,800030c6 <syscall+0x44>
    800030ac:	00369713          	slli	a4,a3,0x3
    800030b0:	00005797          	auipc	a5,0x5
    800030b4:	42078793          	addi	a5,a5,1056 # 800084d0 <syscalls>
    800030b8:	97ba                	add	a5,a5,a4
    800030ba:	639c                	ld	a5,0(a5)
    800030bc:	c789                	beqz	a5,800030c6 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800030be:	9782                	jalr	a5
    800030c0:	06a93823          	sd	a0,112(s2)
    800030c4:	a839                	j	800030e2 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800030c6:	15848613          	addi	a2,s1,344
    800030ca:	588c                	lw	a1,48(s1)
    800030cc:	00005517          	auipc	a0,0x5
    800030d0:	3cc50513          	addi	a0,a0,972 # 80008498 <states.1764+0x150>
    800030d4:	ffffd097          	auipc	ra,0xffffd
    800030d8:	4b4080e7          	jalr	1204(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800030dc:	6cbc                	ld	a5,88(s1)
    800030de:	577d                	li	a4,-1
    800030e0:	fbb8                	sd	a4,112(a5)
  }
}
    800030e2:	60e2                	ld	ra,24(sp)
    800030e4:	6442                	ld	s0,16(sp)
    800030e6:	64a2                	ld	s1,8(sp)
    800030e8:	6902                	ld	s2,0(sp)
    800030ea:	6105                	addi	sp,sp,32
    800030ec:	8082                	ret

00000000800030ee <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800030ee:	1101                	addi	sp,sp,-32
    800030f0:	ec06                	sd	ra,24(sp)
    800030f2:	e822                	sd	s0,16(sp)
    800030f4:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800030f6:	fec40593          	addi	a1,s0,-20
    800030fa:	4501                	li	a0,0
    800030fc:	00000097          	auipc	ra,0x0
    80003100:	f12080e7          	jalr	-238(ra) # 8000300e <argint>
    return -1;
    80003104:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003106:	00054963          	bltz	a0,80003118 <sys_exit+0x2a>
  exit(n);
    8000310a:	fec42503          	lw	a0,-20(s0)
    8000310e:	fffff097          	auipc	ra,0xfffff
    80003112:	6a6080e7          	jalr	1702(ra) # 800027b4 <exit>
  return 0;  // not reached
    80003116:	4781                	li	a5,0
}
    80003118:	853e                	mv	a0,a5
    8000311a:	60e2                	ld	ra,24(sp)
    8000311c:	6442                	ld	s0,16(sp)
    8000311e:	6105                	addi	sp,sp,32
    80003120:	8082                	ret

0000000080003122 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003122:	1141                	addi	sp,sp,-16
    80003124:	e406                	sd	ra,8(sp)
    80003126:	e022                	sd	s0,0(sp)
    80003128:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000312a:	fffff097          	auipc	ra,0xfffff
    8000312e:	ba4080e7          	jalr	-1116(ra) # 80001cce <myproc>
}
    80003132:	5908                	lw	a0,48(a0)
    80003134:	60a2                	ld	ra,8(sp)
    80003136:	6402                	ld	s0,0(sp)
    80003138:	0141                	addi	sp,sp,16
    8000313a:	8082                	ret

000000008000313c <sys_fork>:

uint64
sys_fork(void)
{
    8000313c:	1141                	addi	sp,sp,-16
    8000313e:	e406                	sd	ra,8(sp)
    80003140:	e022                	sd	s0,0(sp)
    80003142:	0800                	addi	s0,sp,16
  return fork();
    80003144:	fffff097          	auipc	ra,0xfffff
    80003148:	018080e7          	jalr	24(ra) # 8000215c <fork>
}
    8000314c:	60a2                	ld	ra,8(sp)
    8000314e:	6402                	ld	s0,0(sp)
    80003150:	0141                	addi	sp,sp,16
    80003152:	8082                	ret

0000000080003154 <sys_wait>:

uint64
sys_wait(void)
{
    80003154:	1101                	addi	sp,sp,-32
    80003156:	ec06                	sd	ra,24(sp)
    80003158:	e822                	sd	s0,16(sp)
    8000315a:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000315c:	fe840593          	addi	a1,s0,-24
    80003160:	4501                	li	a0,0
    80003162:	00000097          	auipc	ra,0x0
    80003166:	ece080e7          	jalr	-306(ra) # 80003030 <argaddr>
    8000316a:	87aa                	mv	a5,a0
    return -1;
    8000316c:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000316e:	0007c863          	bltz	a5,8000317e <sys_wait+0x2a>
  return wait(p);
    80003172:	fe843503          	ld	a0,-24(s0)
    80003176:	fffff097          	auipc	ra,0xfffff
    8000317a:	3d4080e7          	jalr	980(ra) # 8000254a <wait>
}
    8000317e:	60e2                	ld	ra,24(sp)
    80003180:	6442                	ld	s0,16(sp)
    80003182:	6105                	addi	sp,sp,32
    80003184:	8082                	ret

0000000080003186 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003186:	7179                	addi	sp,sp,-48
    80003188:	f406                	sd	ra,40(sp)
    8000318a:	f022                	sd	s0,32(sp)
    8000318c:	ec26                	sd	s1,24(sp)
    8000318e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003190:	fdc40593          	addi	a1,s0,-36
    80003194:	4501                	li	a0,0
    80003196:	00000097          	auipc	ra,0x0
    8000319a:	e78080e7          	jalr	-392(ra) # 8000300e <argint>
    8000319e:	87aa                	mv	a5,a0
    return -1;
    800031a0:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800031a2:	0207c063          	bltz	a5,800031c2 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800031a6:	fffff097          	auipc	ra,0xfffff
    800031aa:	b28080e7          	jalr	-1240(ra) # 80001cce <myproc>
    800031ae:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800031b0:	fdc42503          	lw	a0,-36(s0)
    800031b4:	fffff097          	auipc	ra,0xfffff
    800031b8:	f34080e7          	jalr	-204(ra) # 800020e8 <growproc>
    800031bc:	00054863          	bltz	a0,800031cc <sys_sbrk+0x46>
    return -1;
  return addr;
    800031c0:	8526                	mv	a0,s1
}
    800031c2:	70a2                	ld	ra,40(sp)
    800031c4:	7402                	ld	s0,32(sp)
    800031c6:	64e2                	ld	s1,24(sp)
    800031c8:	6145                	addi	sp,sp,48
    800031ca:	8082                	ret
    return -1;
    800031cc:	557d                	li	a0,-1
    800031ce:	bfd5                	j	800031c2 <sys_sbrk+0x3c>

00000000800031d0 <sys_sleep>:

uint64
sys_sleep(void)
{
    800031d0:	7139                	addi	sp,sp,-64
    800031d2:	fc06                	sd	ra,56(sp)
    800031d4:	f822                	sd	s0,48(sp)
    800031d6:	f426                	sd	s1,40(sp)
    800031d8:	f04a                	sd	s2,32(sp)
    800031da:	ec4e                	sd	s3,24(sp)
    800031dc:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800031de:	fcc40593          	addi	a1,s0,-52
    800031e2:	4501                	li	a0,0
    800031e4:	00000097          	auipc	ra,0x0
    800031e8:	e2a080e7          	jalr	-470(ra) # 8000300e <argint>
    return -1;
    800031ec:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800031ee:	06054563          	bltz	a0,80003258 <sys_sleep+0x88>
  acquire(&tickslock);
    800031f2:	00015517          	auipc	a0,0x15
    800031f6:	a1e50513          	addi	a0,a0,-1506 # 80017c10 <tickslock>
    800031fa:	ffffe097          	auipc	ra,0xffffe
    800031fe:	9ea080e7          	jalr	-1558(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003202:	00006917          	auipc	s2,0x6
    80003206:	e2e92903          	lw	s2,-466(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000320a:	fcc42783          	lw	a5,-52(s0)
    8000320e:	cf85                	beqz	a5,80003246 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003210:	00015997          	auipc	s3,0x15
    80003214:	a0098993          	addi	s3,s3,-1536 # 80017c10 <tickslock>
    80003218:	00006497          	auipc	s1,0x6
    8000321c:	e1848493          	addi	s1,s1,-488 # 80009030 <ticks>
    if(myproc()->killed){
    80003220:	fffff097          	auipc	ra,0xfffff
    80003224:	aae080e7          	jalr	-1362(ra) # 80001cce <myproc>
    80003228:	551c                	lw	a5,40(a0)
    8000322a:	ef9d                	bnez	a5,80003268 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000322c:	85ce                	mv	a1,s3
    8000322e:	8526                	mv	a0,s1
    80003230:	fffff097          	auipc	ra,0xfffff
    80003234:	2a4080e7          	jalr	676(ra) # 800024d4 <sleep>
  while(ticks - ticks0 < n){
    80003238:	409c                	lw	a5,0(s1)
    8000323a:	412787bb          	subw	a5,a5,s2
    8000323e:	fcc42703          	lw	a4,-52(s0)
    80003242:	fce7efe3          	bltu	a5,a4,80003220 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003246:	00015517          	auipc	a0,0x15
    8000324a:	9ca50513          	addi	a0,a0,-1590 # 80017c10 <tickslock>
    8000324e:	ffffe097          	auipc	ra,0xffffe
    80003252:	a4a080e7          	jalr	-1462(ra) # 80000c98 <release>
  return 0;
    80003256:	4781                	li	a5,0
}
    80003258:	853e                	mv	a0,a5
    8000325a:	70e2                	ld	ra,56(sp)
    8000325c:	7442                	ld	s0,48(sp)
    8000325e:	74a2                	ld	s1,40(sp)
    80003260:	7902                	ld	s2,32(sp)
    80003262:	69e2                	ld	s3,24(sp)
    80003264:	6121                	addi	sp,sp,64
    80003266:	8082                	ret
      release(&tickslock);
    80003268:	00015517          	auipc	a0,0x15
    8000326c:	9a850513          	addi	a0,a0,-1624 # 80017c10 <tickslock>
    80003270:	ffffe097          	auipc	ra,0xffffe
    80003274:	a28080e7          	jalr	-1496(ra) # 80000c98 <release>
      return -1;
    80003278:	57fd                	li	a5,-1
    8000327a:	bff9                	j	80003258 <sys_sleep+0x88>

000000008000327c <sys_kill>:

uint64
sys_kill(void)
{
    8000327c:	1101                	addi	sp,sp,-32
    8000327e:	ec06                	sd	ra,24(sp)
    80003280:	e822                	sd	s0,16(sp)
    80003282:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003284:	fec40593          	addi	a1,s0,-20
    80003288:	4501                	li	a0,0
    8000328a:	00000097          	auipc	ra,0x0
    8000328e:	d84080e7          	jalr	-636(ra) # 8000300e <argint>
    80003292:	87aa                	mv	a5,a0
    return -1;
    80003294:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003296:	0007c863          	bltz	a5,800032a6 <sys_kill+0x2a>
  return kill(pid);
    8000329a:	fec42503          	lw	a0,-20(s0)
    8000329e:	fffff097          	auipc	ra,0xfffff
    800032a2:	5fe080e7          	jalr	1534(ra) # 8000289c <kill>
}
    800032a6:	60e2                	ld	ra,24(sp)
    800032a8:	6442                	ld	s0,16(sp)
    800032aa:	6105                	addi	sp,sp,32
    800032ac:	8082                	ret

00000000800032ae <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800032ae:	1101                	addi	sp,sp,-32
    800032b0:	ec06                	sd	ra,24(sp)
    800032b2:	e822                	sd	s0,16(sp)
    800032b4:	e426                	sd	s1,8(sp)
    800032b6:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800032b8:	00015517          	auipc	a0,0x15
    800032bc:	95850513          	addi	a0,a0,-1704 # 80017c10 <tickslock>
    800032c0:	ffffe097          	auipc	ra,0xffffe
    800032c4:	924080e7          	jalr	-1756(ra) # 80000be4 <acquire>
  xticks = ticks;
    800032c8:	00006497          	auipc	s1,0x6
    800032cc:	d684a483          	lw	s1,-664(s1) # 80009030 <ticks>
  release(&tickslock);
    800032d0:	00015517          	auipc	a0,0x15
    800032d4:	94050513          	addi	a0,a0,-1728 # 80017c10 <tickslock>
    800032d8:	ffffe097          	auipc	ra,0xffffe
    800032dc:	9c0080e7          	jalr	-1600(ra) # 80000c98 <release>
  return xticks;
}
    800032e0:	02049513          	slli	a0,s1,0x20
    800032e4:	9101                	srli	a0,a0,0x20
    800032e6:	60e2                	ld	ra,24(sp)
    800032e8:	6442                	ld	s0,16(sp)
    800032ea:	64a2                	ld	s1,8(sp)
    800032ec:	6105                	addi	sp,sp,32
    800032ee:	8082                	ret

00000000800032f0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800032f0:	7179                	addi	sp,sp,-48
    800032f2:	f406                	sd	ra,40(sp)
    800032f4:	f022                	sd	s0,32(sp)
    800032f6:	ec26                	sd	s1,24(sp)
    800032f8:	e84a                	sd	s2,16(sp)
    800032fa:	e44e                	sd	s3,8(sp)
    800032fc:	e052                	sd	s4,0(sp)
    800032fe:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003300:	00005597          	auipc	a1,0x5
    80003304:	28058593          	addi	a1,a1,640 # 80008580 <syscalls+0xb0>
    80003308:	00015517          	auipc	a0,0x15
    8000330c:	92050513          	addi	a0,a0,-1760 # 80017c28 <bcache>
    80003310:	ffffe097          	auipc	ra,0xffffe
    80003314:	844080e7          	jalr	-1980(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003318:	0001d797          	auipc	a5,0x1d
    8000331c:	91078793          	addi	a5,a5,-1776 # 8001fc28 <bcache+0x8000>
    80003320:	0001d717          	auipc	a4,0x1d
    80003324:	b7070713          	addi	a4,a4,-1168 # 8001fe90 <bcache+0x8268>
    80003328:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000332c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003330:	00015497          	auipc	s1,0x15
    80003334:	91048493          	addi	s1,s1,-1776 # 80017c40 <bcache+0x18>
    b->next = bcache.head.next;
    80003338:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000333a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000333c:	00005a17          	auipc	s4,0x5
    80003340:	24ca0a13          	addi	s4,s4,588 # 80008588 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003344:	2b893783          	ld	a5,696(s2)
    80003348:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000334a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000334e:	85d2                	mv	a1,s4
    80003350:	01048513          	addi	a0,s1,16
    80003354:	00001097          	auipc	ra,0x1
    80003358:	4bc080e7          	jalr	1212(ra) # 80004810 <initsleeplock>
    bcache.head.next->prev = b;
    8000335c:	2b893783          	ld	a5,696(s2)
    80003360:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003362:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003366:	45848493          	addi	s1,s1,1112
    8000336a:	fd349de3          	bne	s1,s3,80003344 <binit+0x54>
  }
}
    8000336e:	70a2                	ld	ra,40(sp)
    80003370:	7402                	ld	s0,32(sp)
    80003372:	64e2                	ld	s1,24(sp)
    80003374:	6942                	ld	s2,16(sp)
    80003376:	69a2                	ld	s3,8(sp)
    80003378:	6a02                	ld	s4,0(sp)
    8000337a:	6145                	addi	sp,sp,48
    8000337c:	8082                	ret

000000008000337e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000337e:	7179                	addi	sp,sp,-48
    80003380:	f406                	sd	ra,40(sp)
    80003382:	f022                	sd	s0,32(sp)
    80003384:	ec26                	sd	s1,24(sp)
    80003386:	e84a                	sd	s2,16(sp)
    80003388:	e44e                	sd	s3,8(sp)
    8000338a:	1800                	addi	s0,sp,48
    8000338c:	89aa                	mv	s3,a0
    8000338e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003390:	00015517          	auipc	a0,0x15
    80003394:	89850513          	addi	a0,a0,-1896 # 80017c28 <bcache>
    80003398:	ffffe097          	auipc	ra,0xffffe
    8000339c:	84c080e7          	jalr	-1972(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800033a0:	0001d497          	auipc	s1,0x1d
    800033a4:	b404b483          	ld	s1,-1216(s1) # 8001fee0 <bcache+0x82b8>
    800033a8:	0001d797          	auipc	a5,0x1d
    800033ac:	ae878793          	addi	a5,a5,-1304 # 8001fe90 <bcache+0x8268>
    800033b0:	02f48f63          	beq	s1,a5,800033ee <bread+0x70>
    800033b4:	873e                	mv	a4,a5
    800033b6:	a021                	j	800033be <bread+0x40>
    800033b8:	68a4                	ld	s1,80(s1)
    800033ba:	02e48a63          	beq	s1,a4,800033ee <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800033be:	449c                	lw	a5,8(s1)
    800033c0:	ff379ce3          	bne	a5,s3,800033b8 <bread+0x3a>
    800033c4:	44dc                	lw	a5,12(s1)
    800033c6:	ff2799e3          	bne	a5,s2,800033b8 <bread+0x3a>
      b->refcnt++;
    800033ca:	40bc                	lw	a5,64(s1)
    800033cc:	2785                	addiw	a5,a5,1
    800033ce:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033d0:	00015517          	auipc	a0,0x15
    800033d4:	85850513          	addi	a0,a0,-1960 # 80017c28 <bcache>
    800033d8:	ffffe097          	auipc	ra,0xffffe
    800033dc:	8c0080e7          	jalr	-1856(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800033e0:	01048513          	addi	a0,s1,16
    800033e4:	00001097          	auipc	ra,0x1
    800033e8:	466080e7          	jalr	1126(ra) # 8000484a <acquiresleep>
      return b;
    800033ec:	a8b9                	j	8000344a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033ee:	0001d497          	auipc	s1,0x1d
    800033f2:	aea4b483          	ld	s1,-1302(s1) # 8001fed8 <bcache+0x82b0>
    800033f6:	0001d797          	auipc	a5,0x1d
    800033fa:	a9a78793          	addi	a5,a5,-1382 # 8001fe90 <bcache+0x8268>
    800033fe:	00f48863          	beq	s1,a5,8000340e <bread+0x90>
    80003402:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003404:	40bc                	lw	a5,64(s1)
    80003406:	cf81                	beqz	a5,8000341e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003408:	64a4                	ld	s1,72(s1)
    8000340a:	fee49de3          	bne	s1,a4,80003404 <bread+0x86>
  panic("bget: no buffers");
    8000340e:	00005517          	auipc	a0,0x5
    80003412:	18250513          	addi	a0,a0,386 # 80008590 <syscalls+0xc0>
    80003416:	ffffd097          	auipc	ra,0xffffd
    8000341a:	128080e7          	jalr	296(ra) # 8000053e <panic>
      b->dev = dev;
    8000341e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003422:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003426:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000342a:	4785                	li	a5,1
    8000342c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000342e:	00014517          	auipc	a0,0x14
    80003432:	7fa50513          	addi	a0,a0,2042 # 80017c28 <bcache>
    80003436:	ffffe097          	auipc	ra,0xffffe
    8000343a:	862080e7          	jalr	-1950(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000343e:	01048513          	addi	a0,s1,16
    80003442:	00001097          	auipc	ra,0x1
    80003446:	408080e7          	jalr	1032(ra) # 8000484a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000344a:	409c                	lw	a5,0(s1)
    8000344c:	cb89                	beqz	a5,8000345e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000344e:	8526                	mv	a0,s1
    80003450:	70a2                	ld	ra,40(sp)
    80003452:	7402                	ld	s0,32(sp)
    80003454:	64e2                	ld	s1,24(sp)
    80003456:	6942                	ld	s2,16(sp)
    80003458:	69a2                	ld	s3,8(sp)
    8000345a:	6145                	addi	sp,sp,48
    8000345c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000345e:	4581                	li	a1,0
    80003460:	8526                	mv	a0,s1
    80003462:	00003097          	auipc	ra,0x3
    80003466:	f14080e7          	jalr	-236(ra) # 80006376 <virtio_disk_rw>
    b->valid = 1;
    8000346a:	4785                	li	a5,1
    8000346c:	c09c                	sw	a5,0(s1)
  return b;
    8000346e:	b7c5                	j	8000344e <bread+0xd0>

0000000080003470 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003470:	1101                	addi	sp,sp,-32
    80003472:	ec06                	sd	ra,24(sp)
    80003474:	e822                	sd	s0,16(sp)
    80003476:	e426                	sd	s1,8(sp)
    80003478:	1000                	addi	s0,sp,32
    8000347a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000347c:	0541                	addi	a0,a0,16
    8000347e:	00001097          	auipc	ra,0x1
    80003482:	466080e7          	jalr	1126(ra) # 800048e4 <holdingsleep>
    80003486:	cd01                	beqz	a0,8000349e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003488:	4585                	li	a1,1
    8000348a:	8526                	mv	a0,s1
    8000348c:	00003097          	auipc	ra,0x3
    80003490:	eea080e7          	jalr	-278(ra) # 80006376 <virtio_disk_rw>
}
    80003494:	60e2                	ld	ra,24(sp)
    80003496:	6442                	ld	s0,16(sp)
    80003498:	64a2                	ld	s1,8(sp)
    8000349a:	6105                	addi	sp,sp,32
    8000349c:	8082                	ret
    panic("bwrite");
    8000349e:	00005517          	auipc	a0,0x5
    800034a2:	10a50513          	addi	a0,a0,266 # 800085a8 <syscalls+0xd8>
    800034a6:	ffffd097          	auipc	ra,0xffffd
    800034aa:	098080e7          	jalr	152(ra) # 8000053e <panic>

00000000800034ae <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034ae:	1101                	addi	sp,sp,-32
    800034b0:	ec06                	sd	ra,24(sp)
    800034b2:	e822                	sd	s0,16(sp)
    800034b4:	e426                	sd	s1,8(sp)
    800034b6:	e04a                	sd	s2,0(sp)
    800034b8:	1000                	addi	s0,sp,32
    800034ba:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034bc:	01050913          	addi	s2,a0,16
    800034c0:	854a                	mv	a0,s2
    800034c2:	00001097          	auipc	ra,0x1
    800034c6:	422080e7          	jalr	1058(ra) # 800048e4 <holdingsleep>
    800034ca:	c92d                	beqz	a0,8000353c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800034cc:	854a                	mv	a0,s2
    800034ce:	00001097          	auipc	ra,0x1
    800034d2:	3d2080e7          	jalr	978(ra) # 800048a0 <releasesleep>

  acquire(&bcache.lock);
    800034d6:	00014517          	auipc	a0,0x14
    800034da:	75250513          	addi	a0,a0,1874 # 80017c28 <bcache>
    800034de:	ffffd097          	auipc	ra,0xffffd
    800034e2:	706080e7          	jalr	1798(ra) # 80000be4 <acquire>
  b->refcnt--;
    800034e6:	40bc                	lw	a5,64(s1)
    800034e8:	37fd                	addiw	a5,a5,-1
    800034ea:	0007871b          	sext.w	a4,a5
    800034ee:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800034f0:	eb05                	bnez	a4,80003520 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800034f2:	68bc                	ld	a5,80(s1)
    800034f4:	64b8                	ld	a4,72(s1)
    800034f6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800034f8:	64bc                	ld	a5,72(s1)
    800034fa:	68b8                	ld	a4,80(s1)
    800034fc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800034fe:	0001c797          	auipc	a5,0x1c
    80003502:	72a78793          	addi	a5,a5,1834 # 8001fc28 <bcache+0x8000>
    80003506:	2b87b703          	ld	a4,696(a5)
    8000350a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000350c:	0001d717          	auipc	a4,0x1d
    80003510:	98470713          	addi	a4,a4,-1660 # 8001fe90 <bcache+0x8268>
    80003514:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003516:	2b87b703          	ld	a4,696(a5)
    8000351a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000351c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003520:	00014517          	auipc	a0,0x14
    80003524:	70850513          	addi	a0,a0,1800 # 80017c28 <bcache>
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	770080e7          	jalr	1904(ra) # 80000c98 <release>
}
    80003530:	60e2                	ld	ra,24(sp)
    80003532:	6442                	ld	s0,16(sp)
    80003534:	64a2                	ld	s1,8(sp)
    80003536:	6902                	ld	s2,0(sp)
    80003538:	6105                	addi	sp,sp,32
    8000353a:	8082                	ret
    panic("brelse");
    8000353c:	00005517          	auipc	a0,0x5
    80003540:	07450513          	addi	a0,a0,116 # 800085b0 <syscalls+0xe0>
    80003544:	ffffd097          	auipc	ra,0xffffd
    80003548:	ffa080e7          	jalr	-6(ra) # 8000053e <panic>

000000008000354c <bpin>:

void
bpin(struct buf *b) {
    8000354c:	1101                	addi	sp,sp,-32
    8000354e:	ec06                	sd	ra,24(sp)
    80003550:	e822                	sd	s0,16(sp)
    80003552:	e426                	sd	s1,8(sp)
    80003554:	1000                	addi	s0,sp,32
    80003556:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003558:	00014517          	auipc	a0,0x14
    8000355c:	6d050513          	addi	a0,a0,1744 # 80017c28 <bcache>
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	684080e7          	jalr	1668(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003568:	40bc                	lw	a5,64(s1)
    8000356a:	2785                	addiw	a5,a5,1
    8000356c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000356e:	00014517          	auipc	a0,0x14
    80003572:	6ba50513          	addi	a0,a0,1722 # 80017c28 <bcache>
    80003576:	ffffd097          	auipc	ra,0xffffd
    8000357a:	722080e7          	jalr	1826(ra) # 80000c98 <release>
}
    8000357e:	60e2                	ld	ra,24(sp)
    80003580:	6442                	ld	s0,16(sp)
    80003582:	64a2                	ld	s1,8(sp)
    80003584:	6105                	addi	sp,sp,32
    80003586:	8082                	ret

0000000080003588 <bunpin>:

void
bunpin(struct buf *b) {
    80003588:	1101                	addi	sp,sp,-32
    8000358a:	ec06                	sd	ra,24(sp)
    8000358c:	e822                	sd	s0,16(sp)
    8000358e:	e426                	sd	s1,8(sp)
    80003590:	1000                	addi	s0,sp,32
    80003592:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003594:	00014517          	auipc	a0,0x14
    80003598:	69450513          	addi	a0,a0,1684 # 80017c28 <bcache>
    8000359c:	ffffd097          	auipc	ra,0xffffd
    800035a0:	648080e7          	jalr	1608(ra) # 80000be4 <acquire>
  b->refcnt--;
    800035a4:	40bc                	lw	a5,64(s1)
    800035a6:	37fd                	addiw	a5,a5,-1
    800035a8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035aa:	00014517          	auipc	a0,0x14
    800035ae:	67e50513          	addi	a0,a0,1662 # 80017c28 <bcache>
    800035b2:	ffffd097          	auipc	ra,0xffffd
    800035b6:	6e6080e7          	jalr	1766(ra) # 80000c98 <release>
}
    800035ba:	60e2                	ld	ra,24(sp)
    800035bc:	6442                	ld	s0,16(sp)
    800035be:	64a2                	ld	s1,8(sp)
    800035c0:	6105                	addi	sp,sp,32
    800035c2:	8082                	ret

00000000800035c4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035c4:	1101                	addi	sp,sp,-32
    800035c6:	ec06                	sd	ra,24(sp)
    800035c8:	e822                	sd	s0,16(sp)
    800035ca:	e426                	sd	s1,8(sp)
    800035cc:	e04a                	sd	s2,0(sp)
    800035ce:	1000                	addi	s0,sp,32
    800035d0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035d2:	00d5d59b          	srliw	a1,a1,0xd
    800035d6:	0001d797          	auipc	a5,0x1d
    800035da:	d2e7a783          	lw	a5,-722(a5) # 80020304 <sb+0x1c>
    800035de:	9dbd                	addw	a1,a1,a5
    800035e0:	00000097          	auipc	ra,0x0
    800035e4:	d9e080e7          	jalr	-610(ra) # 8000337e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800035e8:	0074f713          	andi	a4,s1,7
    800035ec:	4785                	li	a5,1
    800035ee:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800035f2:	14ce                	slli	s1,s1,0x33
    800035f4:	90d9                	srli	s1,s1,0x36
    800035f6:	00950733          	add	a4,a0,s1
    800035fa:	05874703          	lbu	a4,88(a4)
    800035fe:	00e7f6b3          	and	a3,a5,a4
    80003602:	c69d                	beqz	a3,80003630 <bfree+0x6c>
    80003604:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003606:	94aa                	add	s1,s1,a0
    80003608:	fff7c793          	not	a5,a5
    8000360c:	8ff9                	and	a5,a5,a4
    8000360e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003612:	00001097          	auipc	ra,0x1
    80003616:	118080e7          	jalr	280(ra) # 8000472a <log_write>
  brelse(bp);
    8000361a:	854a                	mv	a0,s2
    8000361c:	00000097          	auipc	ra,0x0
    80003620:	e92080e7          	jalr	-366(ra) # 800034ae <brelse>
}
    80003624:	60e2                	ld	ra,24(sp)
    80003626:	6442                	ld	s0,16(sp)
    80003628:	64a2                	ld	s1,8(sp)
    8000362a:	6902                	ld	s2,0(sp)
    8000362c:	6105                	addi	sp,sp,32
    8000362e:	8082                	ret
    panic("freeing free block");
    80003630:	00005517          	auipc	a0,0x5
    80003634:	f8850513          	addi	a0,a0,-120 # 800085b8 <syscalls+0xe8>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	f06080e7          	jalr	-250(ra) # 8000053e <panic>

0000000080003640 <balloc>:
{
    80003640:	711d                	addi	sp,sp,-96
    80003642:	ec86                	sd	ra,88(sp)
    80003644:	e8a2                	sd	s0,80(sp)
    80003646:	e4a6                	sd	s1,72(sp)
    80003648:	e0ca                	sd	s2,64(sp)
    8000364a:	fc4e                	sd	s3,56(sp)
    8000364c:	f852                	sd	s4,48(sp)
    8000364e:	f456                	sd	s5,40(sp)
    80003650:	f05a                	sd	s6,32(sp)
    80003652:	ec5e                	sd	s7,24(sp)
    80003654:	e862                	sd	s8,16(sp)
    80003656:	e466                	sd	s9,8(sp)
    80003658:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000365a:	0001d797          	auipc	a5,0x1d
    8000365e:	c927a783          	lw	a5,-878(a5) # 800202ec <sb+0x4>
    80003662:	cbd1                	beqz	a5,800036f6 <balloc+0xb6>
    80003664:	8baa                	mv	s7,a0
    80003666:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003668:	0001db17          	auipc	s6,0x1d
    8000366c:	c80b0b13          	addi	s6,s6,-896 # 800202e8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003670:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003672:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003674:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003676:	6c89                	lui	s9,0x2
    80003678:	a831                	j	80003694 <balloc+0x54>
    brelse(bp);
    8000367a:	854a                	mv	a0,s2
    8000367c:	00000097          	auipc	ra,0x0
    80003680:	e32080e7          	jalr	-462(ra) # 800034ae <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003684:	015c87bb          	addw	a5,s9,s5
    80003688:	00078a9b          	sext.w	s5,a5
    8000368c:	004b2703          	lw	a4,4(s6)
    80003690:	06eaf363          	bgeu	s5,a4,800036f6 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003694:	41fad79b          	sraiw	a5,s5,0x1f
    80003698:	0137d79b          	srliw	a5,a5,0x13
    8000369c:	015787bb          	addw	a5,a5,s5
    800036a0:	40d7d79b          	sraiw	a5,a5,0xd
    800036a4:	01cb2583          	lw	a1,28(s6)
    800036a8:	9dbd                	addw	a1,a1,a5
    800036aa:	855e                	mv	a0,s7
    800036ac:	00000097          	auipc	ra,0x0
    800036b0:	cd2080e7          	jalr	-814(ra) # 8000337e <bread>
    800036b4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036b6:	004b2503          	lw	a0,4(s6)
    800036ba:	000a849b          	sext.w	s1,s5
    800036be:	8662                	mv	a2,s8
    800036c0:	faa4fde3          	bgeu	s1,a0,8000367a <balloc+0x3a>
      m = 1 << (bi % 8);
    800036c4:	41f6579b          	sraiw	a5,a2,0x1f
    800036c8:	01d7d69b          	srliw	a3,a5,0x1d
    800036cc:	00c6873b          	addw	a4,a3,a2
    800036d0:	00777793          	andi	a5,a4,7
    800036d4:	9f95                	subw	a5,a5,a3
    800036d6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036da:	4037571b          	sraiw	a4,a4,0x3
    800036de:	00e906b3          	add	a3,s2,a4
    800036e2:	0586c683          	lbu	a3,88(a3)
    800036e6:	00d7f5b3          	and	a1,a5,a3
    800036ea:	cd91                	beqz	a1,80003706 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036ec:	2605                	addiw	a2,a2,1
    800036ee:	2485                	addiw	s1,s1,1
    800036f0:	fd4618e3          	bne	a2,s4,800036c0 <balloc+0x80>
    800036f4:	b759                	j	8000367a <balloc+0x3a>
  panic("balloc: out of blocks");
    800036f6:	00005517          	auipc	a0,0x5
    800036fa:	eda50513          	addi	a0,a0,-294 # 800085d0 <syscalls+0x100>
    800036fe:	ffffd097          	auipc	ra,0xffffd
    80003702:	e40080e7          	jalr	-448(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003706:	974a                	add	a4,a4,s2
    80003708:	8fd5                	or	a5,a5,a3
    8000370a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000370e:	854a                	mv	a0,s2
    80003710:	00001097          	auipc	ra,0x1
    80003714:	01a080e7          	jalr	26(ra) # 8000472a <log_write>
        brelse(bp);
    80003718:	854a                	mv	a0,s2
    8000371a:	00000097          	auipc	ra,0x0
    8000371e:	d94080e7          	jalr	-620(ra) # 800034ae <brelse>
  bp = bread(dev, bno);
    80003722:	85a6                	mv	a1,s1
    80003724:	855e                	mv	a0,s7
    80003726:	00000097          	auipc	ra,0x0
    8000372a:	c58080e7          	jalr	-936(ra) # 8000337e <bread>
    8000372e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003730:	40000613          	li	a2,1024
    80003734:	4581                	li	a1,0
    80003736:	05850513          	addi	a0,a0,88
    8000373a:	ffffd097          	auipc	ra,0xffffd
    8000373e:	5a6080e7          	jalr	1446(ra) # 80000ce0 <memset>
  log_write(bp);
    80003742:	854a                	mv	a0,s2
    80003744:	00001097          	auipc	ra,0x1
    80003748:	fe6080e7          	jalr	-26(ra) # 8000472a <log_write>
  brelse(bp);
    8000374c:	854a                	mv	a0,s2
    8000374e:	00000097          	auipc	ra,0x0
    80003752:	d60080e7          	jalr	-672(ra) # 800034ae <brelse>
}
    80003756:	8526                	mv	a0,s1
    80003758:	60e6                	ld	ra,88(sp)
    8000375a:	6446                	ld	s0,80(sp)
    8000375c:	64a6                	ld	s1,72(sp)
    8000375e:	6906                	ld	s2,64(sp)
    80003760:	79e2                	ld	s3,56(sp)
    80003762:	7a42                	ld	s4,48(sp)
    80003764:	7aa2                	ld	s5,40(sp)
    80003766:	7b02                	ld	s6,32(sp)
    80003768:	6be2                	ld	s7,24(sp)
    8000376a:	6c42                	ld	s8,16(sp)
    8000376c:	6ca2                	ld	s9,8(sp)
    8000376e:	6125                	addi	sp,sp,96
    80003770:	8082                	ret

0000000080003772 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003772:	7179                	addi	sp,sp,-48
    80003774:	f406                	sd	ra,40(sp)
    80003776:	f022                	sd	s0,32(sp)
    80003778:	ec26                	sd	s1,24(sp)
    8000377a:	e84a                	sd	s2,16(sp)
    8000377c:	e44e                	sd	s3,8(sp)
    8000377e:	e052                	sd	s4,0(sp)
    80003780:	1800                	addi	s0,sp,48
    80003782:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003784:	47ad                	li	a5,11
    80003786:	04b7fe63          	bgeu	a5,a1,800037e2 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000378a:	ff45849b          	addiw	s1,a1,-12
    8000378e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003792:	0ff00793          	li	a5,255
    80003796:	0ae7e363          	bltu	a5,a4,8000383c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000379a:	08052583          	lw	a1,128(a0)
    8000379e:	c5ad                	beqz	a1,80003808 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800037a0:	00092503          	lw	a0,0(s2)
    800037a4:	00000097          	auipc	ra,0x0
    800037a8:	bda080e7          	jalr	-1062(ra) # 8000337e <bread>
    800037ac:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037ae:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800037b2:	02049593          	slli	a1,s1,0x20
    800037b6:	9181                	srli	a1,a1,0x20
    800037b8:	058a                	slli	a1,a1,0x2
    800037ba:	00b784b3          	add	s1,a5,a1
    800037be:	0004a983          	lw	s3,0(s1)
    800037c2:	04098d63          	beqz	s3,8000381c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800037c6:	8552                	mv	a0,s4
    800037c8:	00000097          	auipc	ra,0x0
    800037cc:	ce6080e7          	jalr	-794(ra) # 800034ae <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037d0:	854e                	mv	a0,s3
    800037d2:	70a2                	ld	ra,40(sp)
    800037d4:	7402                	ld	s0,32(sp)
    800037d6:	64e2                	ld	s1,24(sp)
    800037d8:	6942                	ld	s2,16(sp)
    800037da:	69a2                	ld	s3,8(sp)
    800037dc:	6a02                	ld	s4,0(sp)
    800037de:	6145                	addi	sp,sp,48
    800037e0:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800037e2:	02059493          	slli	s1,a1,0x20
    800037e6:	9081                	srli	s1,s1,0x20
    800037e8:	048a                	slli	s1,s1,0x2
    800037ea:	94aa                	add	s1,s1,a0
    800037ec:	0504a983          	lw	s3,80(s1)
    800037f0:	fe0990e3          	bnez	s3,800037d0 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800037f4:	4108                	lw	a0,0(a0)
    800037f6:	00000097          	auipc	ra,0x0
    800037fa:	e4a080e7          	jalr	-438(ra) # 80003640 <balloc>
    800037fe:	0005099b          	sext.w	s3,a0
    80003802:	0534a823          	sw	s3,80(s1)
    80003806:	b7e9                	j	800037d0 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003808:	4108                	lw	a0,0(a0)
    8000380a:	00000097          	auipc	ra,0x0
    8000380e:	e36080e7          	jalr	-458(ra) # 80003640 <balloc>
    80003812:	0005059b          	sext.w	a1,a0
    80003816:	08b92023          	sw	a1,128(s2)
    8000381a:	b759                	j	800037a0 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000381c:	00092503          	lw	a0,0(s2)
    80003820:	00000097          	auipc	ra,0x0
    80003824:	e20080e7          	jalr	-480(ra) # 80003640 <balloc>
    80003828:	0005099b          	sext.w	s3,a0
    8000382c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003830:	8552                	mv	a0,s4
    80003832:	00001097          	auipc	ra,0x1
    80003836:	ef8080e7          	jalr	-264(ra) # 8000472a <log_write>
    8000383a:	b771                	j	800037c6 <bmap+0x54>
  panic("bmap: out of range");
    8000383c:	00005517          	auipc	a0,0x5
    80003840:	dac50513          	addi	a0,a0,-596 # 800085e8 <syscalls+0x118>
    80003844:	ffffd097          	auipc	ra,0xffffd
    80003848:	cfa080e7          	jalr	-774(ra) # 8000053e <panic>

000000008000384c <iget>:
{
    8000384c:	7179                	addi	sp,sp,-48
    8000384e:	f406                	sd	ra,40(sp)
    80003850:	f022                	sd	s0,32(sp)
    80003852:	ec26                	sd	s1,24(sp)
    80003854:	e84a                	sd	s2,16(sp)
    80003856:	e44e                	sd	s3,8(sp)
    80003858:	e052                	sd	s4,0(sp)
    8000385a:	1800                	addi	s0,sp,48
    8000385c:	89aa                	mv	s3,a0
    8000385e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003860:	0001d517          	auipc	a0,0x1d
    80003864:	aa850513          	addi	a0,a0,-1368 # 80020308 <itable>
    80003868:	ffffd097          	auipc	ra,0xffffd
    8000386c:	37c080e7          	jalr	892(ra) # 80000be4 <acquire>
  empty = 0;
    80003870:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003872:	0001d497          	auipc	s1,0x1d
    80003876:	aae48493          	addi	s1,s1,-1362 # 80020320 <itable+0x18>
    8000387a:	0001e697          	auipc	a3,0x1e
    8000387e:	53668693          	addi	a3,a3,1334 # 80021db0 <log>
    80003882:	a039                	j	80003890 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003884:	02090b63          	beqz	s2,800038ba <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003888:	08848493          	addi	s1,s1,136
    8000388c:	02d48a63          	beq	s1,a3,800038c0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003890:	449c                	lw	a5,8(s1)
    80003892:	fef059e3          	blez	a5,80003884 <iget+0x38>
    80003896:	4098                	lw	a4,0(s1)
    80003898:	ff3716e3          	bne	a4,s3,80003884 <iget+0x38>
    8000389c:	40d8                	lw	a4,4(s1)
    8000389e:	ff4713e3          	bne	a4,s4,80003884 <iget+0x38>
      ip->ref++;
    800038a2:	2785                	addiw	a5,a5,1
    800038a4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800038a6:	0001d517          	auipc	a0,0x1d
    800038aa:	a6250513          	addi	a0,a0,-1438 # 80020308 <itable>
    800038ae:	ffffd097          	auipc	ra,0xffffd
    800038b2:	3ea080e7          	jalr	1002(ra) # 80000c98 <release>
      return ip;
    800038b6:	8926                	mv	s2,s1
    800038b8:	a03d                	j	800038e6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038ba:	f7f9                	bnez	a5,80003888 <iget+0x3c>
    800038bc:	8926                	mv	s2,s1
    800038be:	b7e9                	j	80003888 <iget+0x3c>
  if(empty == 0)
    800038c0:	02090c63          	beqz	s2,800038f8 <iget+0xac>
  ip->dev = dev;
    800038c4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038c8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038cc:	4785                	li	a5,1
    800038ce:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038d2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800038d6:	0001d517          	auipc	a0,0x1d
    800038da:	a3250513          	addi	a0,a0,-1486 # 80020308 <itable>
    800038de:	ffffd097          	auipc	ra,0xffffd
    800038e2:	3ba080e7          	jalr	954(ra) # 80000c98 <release>
}
    800038e6:	854a                	mv	a0,s2
    800038e8:	70a2                	ld	ra,40(sp)
    800038ea:	7402                	ld	s0,32(sp)
    800038ec:	64e2                	ld	s1,24(sp)
    800038ee:	6942                	ld	s2,16(sp)
    800038f0:	69a2                	ld	s3,8(sp)
    800038f2:	6a02                	ld	s4,0(sp)
    800038f4:	6145                	addi	sp,sp,48
    800038f6:	8082                	ret
    panic("iget: no inodes");
    800038f8:	00005517          	auipc	a0,0x5
    800038fc:	d0850513          	addi	a0,a0,-760 # 80008600 <syscalls+0x130>
    80003900:	ffffd097          	auipc	ra,0xffffd
    80003904:	c3e080e7          	jalr	-962(ra) # 8000053e <panic>

0000000080003908 <fsinit>:
fsinit(int dev) {
    80003908:	7179                	addi	sp,sp,-48
    8000390a:	f406                	sd	ra,40(sp)
    8000390c:	f022                	sd	s0,32(sp)
    8000390e:	ec26                	sd	s1,24(sp)
    80003910:	e84a                	sd	s2,16(sp)
    80003912:	e44e                	sd	s3,8(sp)
    80003914:	1800                	addi	s0,sp,48
    80003916:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003918:	4585                	li	a1,1
    8000391a:	00000097          	auipc	ra,0x0
    8000391e:	a64080e7          	jalr	-1436(ra) # 8000337e <bread>
    80003922:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003924:	0001d997          	auipc	s3,0x1d
    80003928:	9c498993          	addi	s3,s3,-1596 # 800202e8 <sb>
    8000392c:	02000613          	li	a2,32
    80003930:	05850593          	addi	a1,a0,88
    80003934:	854e                	mv	a0,s3
    80003936:	ffffd097          	auipc	ra,0xffffd
    8000393a:	40a080e7          	jalr	1034(ra) # 80000d40 <memmove>
  brelse(bp);
    8000393e:	8526                	mv	a0,s1
    80003940:	00000097          	auipc	ra,0x0
    80003944:	b6e080e7          	jalr	-1170(ra) # 800034ae <brelse>
  if(sb.magic != FSMAGIC)
    80003948:	0009a703          	lw	a4,0(s3)
    8000394c:	102037b7          	lui	a5,0x10203
    80003950:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003954:	02f71263          	bne	a4,a5,80003978 <fsinit+0x70>
  initlog(dev, &sb);
    80003958:	0001d597          	auipc	a1,0x1d
    8000395c:	99058593          	addi	a1,a1,-1648 # 800202e8 <sb>
    80003960:	854a                	mv	a0,s2
    80003962:	00001097          	auipc	ra,0x1
    80003966:	b4c080e7          	jalr	-1204(ra) # 800044ae <initlog>
}
    8000396a:	70a2                	ld	ra,40(sp)
    8000396c:	7402                	ld	s0,32(sp)
    8000396e:	64e2                	ld	s1,24(sp)
    80003970:	6942                	ld	s2,16(sp)
    80003972:	69a2                	ld	s3,8(sp)
    80003974:	6145                	addi	sp,sp,48
    80003976:	8082                	ret
    panic("invalid file system");
    80003978:	00005517          	auipc	a0,0x5
    8000397c:	c9850513          	addi	a0,a0,-872 # 80008610 <syscalls+0x140>
    80003980:	ffffd097          	auipc	ra,0xffffd
    80003984:	bbe080e7          	jalr	-1090(ra) # 8000053e <panic>

0000000080003988 <iinit>:
{
    80003988:	7179                	addi	sp,sp,-48
    8000398a:	f406                	sd	ra,40(sp)
    8000398c:	f022                	sd	s0,32(sp)
    8000398e:	ec26                	sd	s1,24(sp)
    80003990:	e84a                	sd	s2,16(sp)
    80003992:	e44e                	sd	s3,8(sp)
    80003994:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003996:	00005597          	auipc	a1,0x5
    8000399a:	c9258593          	addi	a1,a1,-878 # 80008628 <syscalls+0x158>
    8000399e:	0001d517          	auipc	a0,0x1d
    800039a2:	96a50513          	addi	a0,a0,-1686 # 80020308 <itable>
    800039a6:	ffffd097          	auipc	ra,0xffffd
    800039aa:	1ae080e7          	jalr	430(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800039ae:	0001d497          	auipc	s1,0x1d
    800039b2:	98248493          	addi	s1,s1,-1662 # 80020330 <itable+0x28>
    800039b6:	0001e997          	auipc	s3,0x1e
    800039ba:	40a98993          	addi	s3,s3,1034 # 80021dc0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800039be:	00005917          	auipc	s2,0x5
    800039c2:	c7290913          	addi	s2,s2,-910 # 80008630 <syscalls+0x160>
    800039c6:	85ca                	mv	a1,s2
    800039c8:	8526                	mv	a0,s1
    800039ca:	00001097          	auipc	ra,0x1
    800039ce:	e46080e7          	jalr	-442(ra) # 80004810 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039d2:	08848493          	addi	s1,s1,136
    800039d6:	ff3498e3          	bne	s1,s3,800039c6 <iinit+0x3e>
}
    800039da:	70a2                	ld	ra,40(sp)
    800039dc:	7402                	ld	s0,32(sp)
    800039de:	64e2                	ld	s1,24(sp)
    800039e0:	6942                	ld	s2,16(sp)
    800039e2:	69a2                	ld	s3,8(sp)
    800039e4:	6145                	addi	sp,sp,48
    800039e6:	8082                	ret

00000000800039e8 <ialloc>:
{
    800039e8:	715d                	addi	sp,sp,-80
    800039ea:	e486                	sd	ra,72(sp)
    800039ec:	e0a2                	sd	s0,64(sp)
    800039ee:	fc26                	sd	s1,56(sp)
    800039f0:	f84a                	sd	s2,48(sp)
    800039f2:	f44e                	sd	s3,40(sp)
    800039f4:	f052                	sd	s4,32(sp)
    800039f6:	ec56                	sd	s5,24(sp)
    800039f8:	e85a                	sd	s6,16(sp)
    800039fa:	e45e                	sd	s7,8(sp)
    800039fc:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800039fe:	0001d717          	auipc	a4,0x1d
    80003a02:	8f672703          	lw	a4,-1802(a4) # 800202f4 <sb+0xc>
    80003a06:	4785                	li	a5,1
    80003a08:	04e7fa63          	bgeu	a5,a4,80003a5c <ialloc+0x74>
    80003a0c:	8aaa                	mv	s5,a0
    80003a0e:	8bae                	mv	s7,a1
    80003a10:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a12:	0001da17          	auipc	s4,0x1d
    80003a16:	8d6a0a13          	addi	s4,s4,-1834 # 800202e8 <sb>
    80003a1a:	00048b1b          	sext.w	s6,s1
    80003a1e:	0044d593          	srli	a1,s1,0x4
    80003a22:	018a2783          	lw	a5,24(s4)
    80003a26:	9dbd                	addw	a1,a1,a5
    80003a28:	8556                	mv	a0,s5
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	954080e7          	jalr	-1708(ra) # 8000337e <bread>
    80003a32:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a34:	05850993          	addi	s3,a0,88
    80003a38:	00f4f793          	andi	a5,s1,15
    80003a3c:	079a                	slli	a5,a5,0x6
    80003a3e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a40:	00099783          	lh	a5,0(s3)
    80003a44:	c785                	beqz	a5,80003a6c <ialloc+0x84>
    brelse(bp);
    80003a46:	00000097          	auipc	ra,0x0
    80003a4a:	a68080e7          	jalr	-1432(ra) # 800034ae <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a4e:	0485                	addi	s1,s1,1
    80003a50:	00ca2703          	lw	a4,12(s4)
    80003a54:	0004879b          	sext.w	a5,s1
    80003a58:	fce7e1e3          	bltu	a5,a4,80003a1a <ialloc+0x32>
  panic("ialloc: no inodes");
    80003a5c:	00005517          	auipc	a0,0x5
    80003a60:	bdc50513          	addi	a0,a0,-1060 # 80008638 <syscalls+0x168>
    80003a64:	ffffd097          	auipc	ra,0xffffd
    80003a68:	ada080e7          	jalr	-1318(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003a6c:	04000613          	li	a2,64
    80003a70:	4581                	li	a1,0
    80003a72:	854e                	mv	a0,s3
    80003a74:	ffffd097          	auipc	ra,0xffffd
    80003a78:	26c080e7          	jalr	620(ra) # 80000ce0 <memset>
      dip->type = type;
    80003a7c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a80:	854a                	mv	a0,s2
    80003a82:	00001097          	auipc	ra,0x1
    80003a86:	ca8080e7          	jalr	-856(ra) # 8000472a <log_write>
      brelse(bp);
    80003a8a:	854a                	mv	a0,s2
    80003a8c:	00000097          	auipc	ra,0x0
    80003a90:	a22080e7          	jalr	-1502(ra) # 800034ae <brelse>
      return iget(dev, inum);
    80003a94:	85da                	mv	a1,s6
    80003a96:	8556                	mv	a0,s5
    80003a98:	00000097          	auipc	ra,0x0
    80003a9c:	db4080e7          	jalr	-588(ra) # 8000384c <iget>
}
    80003aa0:	60a6                	ld	ra,72(sp)
    80003aa2:	6406                	ld	s0,64(sp)
    80003aa4:	74e2                	ld	s1,56(sp)
    80003aa6:	7942                	ld	s2,48(sp)
    80003aa8:	79a2                	ld	s3,40(sp)
    80003aaa:	7a02                	ld	s4,32(sp)
    80003aac:	6ae2                	ld	s5,24(sp)
    80003aae:	6b42                	ld	s6,16(sp)
    80003ab0:	6ba2                	ld	s7,8(sp)
    80003ab2:	6161                	addi	sp,sp,80
    80003ab4:	8082                	ret

0000000080003ab6 <iupdate>:
{
    80003ab6:	1101                	addi	sp,sp,-32
    80003ab8:	ec06                	sd	ra,24(sp)
    80003aba:	e822                	sd	s0,16(sp)
    80003abc:	e426                	sd	s1,8(sp)
    80003abe:	e04a                	sd	s2,0(sp)
    80003ac0:	1000                	addi	s0,sp,32
    80003ac2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ac4:	415c                	lw	a5,4(a0)
    80003ac6:	0047d79b          	srliw	a5,a5,0x4
    80003aca:	0001d597          	auipc	a1,0x1d
    80003ace:	8365a583          	lw	a1,-1994(a1) # 80020300 <sb+0x18>
    80003ad2:	9dbd                	addw	a1,a1,a5
    80003ad4:	4108                	lw	a0,0(a0)
    80003ad6:	00000097          	auipc	ra,0x0
    80003ada:	8a8080e7          	jalr	-1880(ra) # 8000337e <bread>
    80003ade:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ae0:	05850793          	addi	a5,a0,88
    80003ae4:	40c8                	lw	a0,4(s1)
    80003ae6:	893d                	andi	a0,a0,15
    80003ae8:	051a                	slli	a0,a0,0x6
    80003aea:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003aec:	04449703          	lh	a4,68(s1)
    80003af0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003af4:	04649703          	lh	a4,70(s1)
    80003af8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003afc:	04849703          	lh	a4,72(s1)
    80003b00:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b04:	04a49703          	lh	a4,74(s1)
    80003b08:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b0c:	44f8                	lw	a4,76(s1)
    80003b0e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b10:	03400613          	li	a2,52
    80003b14:	05048593          	addi	a1,s1,80
    80003b18:	0531                	addi	a0,a0,12
    80003b1a:	ffffd097          	auipc	ra,0xffffd
    80003b1e:	226080e7          	jalr	550(ra) # 80000d40 <memmove>
  log_write(bp);
    80003b22:	854a                	mv	a0,s2
    80003b24:	00001097          	auipc	ra,0x1
    80003b28:	c06080e7          	jalr	-1018(ra) # 8000472a <log_write>
  brelse(bp);
    80003b2c:	854a                	mv	a0,s2
    80003b2e:	00000097          	auipc	ra,0x0
    80003b32:	980080e7          	jalr	-1664(ra) # 800034ae <brelse>
}
    80003b36:	60e2                	ld	ra,24(sp)
    80003b38:	6442                	ld	s0,16(sp)
    80003b3a:	64a2                	ld	s1,8(sp)
    80003b3c:	6902                	ld	s2,0(sp)
    80003b3e:	6105                	addi	sp,sp,32
    80003b40:	8082                	ret

0000000080003b42 <idup>:
{
    80003b42:	1101                	addi	sp,sp,-32
    80003b44:	ec06                	sd	ra,24(sp)
    80003b46:	e822                	sd	s0,16(sp)
    80003b48:	e426                	sd	s1,8(sp)
    80003b4a:	1000                	addi	s0,sp,32
    80003b4c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b4e:	0001c517          	auipc	a0,0x1c
    80003b52:	7ba50513          	addi	a0,a0,1978 # 80020308 <itable>
    80003b56:	ffffd097          	auipc	ra,0xffffd
    80003b5a:	08e080e7          	jalr	142(ra) # 80000be4 <acquire>
  ip->ref++;
    80003b5e:	449c                	lw	a5,8(s1)
    80003b60:	2785                	addiw	a5,a5,1
    80003b62:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b64:	0001c517          	auipc	a0,0x1c
    80003b68:	7a450513          	addi	a0,a0,1956 # 80020308 <itable>
    80003b6c:	ffffd097          	auipc	ra,0xffffd
    80003b70:	12c080e7          	jalr	300(ra) # 80000c98 <release>
}
    80003b74:	8526                	mv	a0,s1
    80003b76:	60e2                	ld	ra,24(sp)
    80003b78:	6442                	ld	s0,16(sp)
    80003b7a:	64a2                	ld	s1,8(sp)
    80003b7c:	6105                	addi	sp,sp,32
    80003b7e:	8082                	ret

0000000080003b80 <ilock>:
{
    80003b80:	1101                	addi	sp,sp,-32
    80003b82:	ec06                	sd	ra,24(sp)
    80003b84:	e822                	sd	s0,16(sp)
    80003b86:	e426                	sd	s1,8(sp)
    80003b88:	e04a                	sd	s2,0(sp)
    80003b8a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b8c:	c115                	beqz	a0,80003bb0 <ilock+0x30>
    80003b8e:	84aa                	mv	s1,a0
    80003b90:	451c                	lw	a5,8(a0)
    80003b92:	00f05f63          	blez	a5,80003bb0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b96:	0541                	addi	a0,a0,16
    80003b98:	00001097          	auipc	ra,0x1
    80003b9c:	cb2080e7          	jalr	-846(ra) # 8000484a <acquiresleep>
  if(ip->valid == 0){
    80003ba0:	40bc                	lw	a5,64(s1)
    80003ba2:	cf99                	beqz	a5,80003bc0 <ilock+0x40>
}
    80003ba4:	60e2                	ld	ra,24(sp)
    80003ba6:	6442                	ld	s0,16(sp)
    80003ba8:	64a2                	ld	s1,8(sp)
    80003baa:	6902                	ld	s2,0(sp)
    80003bac:	6105                	addi	sp,sp,32
    80003bae:	8082                	ret
    panic("ilock");
    80003bb0:	00005517          	auipc	a0,0x5
    80003bb4:	aa050513          	addi	a0,a0,-1376 # 80008650 <syscalls+0x180>
    80003bb8:	ffffd097          	auipc	ra,0xffffd
    80003bbc:	986080e7          	jalr	-1658(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bc0:	40dc                	lw	a5,4(s1)
    80003bc2:	0047d79b          	srliw	a5,a5,0x4
    80003bc6:	0001c597          	auipc	a1,0x1c
    80003bca:	73a5a583          	lw	a1,1850(a1) # 80020300 <sb+0x18>
    80003bce:	9dbd                	addw	a1,a1,a5
    80003bd0:	4088                	lw	a0,0(s1)
    80003bd2:	fffff097          	auipc	ra,0xfffff
    80003bd6:	7ac080e7          	jalr	1964(ra) # 8000337e <bread>
    80003bda:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bdc:	05850593          	addi	a1,a0,88
    80003be0:	40dc                	lw	a5,4(s1)
    80003be2:	8bbd                	andi	a5,a5,15
    80003be4:	079a                	slli	a5,a5,0x6
    80003be6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003be8:	00059783          	lh	a5,0(a1)
    80003bec:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003bf0:	00259783          	lh	a5,2(a1)
    80003bf4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003bf8:	00459783          	lh	a5,4(a1)
    80003bfc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c00:	00659783          	lh	a5,6(a1)
    80003c04:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c08:	459c                	lw	a5,8(a1)
    80003c0a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c0c:	03400613          	li	a2,52
    80003c10:	05b1                	addi	a1,a1,12
    80003c12:	05048513          	addi	a0,s1,80
    80003c16:	ffffd097          	auipc	ra,0xffffd
    80003c1a:	12a080e7          	jalr	298(ra) # 80000d40 <memmove>
    brelse(bp);
    80003c1e:	854a                	mv	a0,s2
    80003c20:	00000097          	auipc	ra,0x0
    80003c24:	88e080e7          	jalr	-1906(ra) # 800034ae <brelse>
    ip->valid = 1;
    80003c28:	4785                	li	a5,1
    80003c2a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c2c:	04449783          	lh	a5,68(s1)
    80003c30:	fbb5                	bnez	a5,80003ba4 <ilock+0x24>
      panic("ilock: no type");
    80003c32:	00005517          	auipc	a0,0x5
    80003c36:	a2650513          	addi	a0,a0,-1498 # 80008658 <syscalls+0x188>
    80003c3a:	ffffd097          	auipc	ra,0xffffd
    80003c3e:	904080e7          	jalr	-1788(ra) # 8000053e <panic>

0000000080003c42 <iunlock>:
{
    80003c42:	1101                	addi	sp,sp,-32
    80003c44:	ec06                	sd	ra,24(sp)
    80003c46:	e822                	sd	s0,16(sp)
    80003c48:	e426                	sd	s1,8(sp)
    80003c4a:	e04a                	sd	s2,0(sp)
    80003c4c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c4e:	c905                	beqz	a0,80003c7e <iunlock+0x3c>
    80003c50:	84aa                	mv	s1,a0
    80003c52:	01050913          	addi	s2,a0,16
    80003c56:	854a                	mv	a0,s2
    80003c58:	00001097          	auipc	ra,0x1
    80003c5c:	c8c080e7          	jalr	-884(ra) # 800048e4 <holdingsleep>
    80003c60:	cd19                	beqz	a0,80003c7e <iunlock+0x3c>
    80003c62:	449c                	lw	a5,8(s1)
    80003c64:	00f05d63          	blez	a5,80003c7e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c68:	854a                	mv	a0,s2
    80003c6a:	00001097          	auipc	ra,0x1
    80003c6e:	c36080e7          	jalr	-970(ra) # 800048a0 <releasesleep>
}
    80003c72:	60e2                	ld	ra,24(sp)
    80003c74:	6442                	ld	s0,16(sp)
    80003c76:	64a2                	ld	s1,8(sp)
    80003c78:	6902                	ld	s2,0(sp)
    80003c7a:	6105                	addi	sp,sp,32
    80003c7c:	8082                	ret
    panic("iunlock");
    80003c7e:	00005517          	auipc	a0,0x5
    80003c82:	9ea50513          	addi	a0,a0,-1558 # 80008668 <syscalls+0x198>
    80003c86:	ffffd097          	auipc	ra,0xffffd
    80003c8a:	8b8080e7          	jalr	-1864(ra) # 8000053e <panic>

0000000080003c8e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c8e:	7179                	addi	sp,sp,-48
    80003c90:	f406                	sd	ra,40(sp)
    80003c92:	f022                	sd	s0,32(sp)
    80003c94:	ec26                	sd	s1,24(sp)
    80003c96:	e84a                	sd	s2,16(sp)
    80003c98:	e44e                	sd	s3,8(sp)
    80003c9a:	e052                	sd	s4,0(sp)
    80003c9c:	1800                	addi	s0,sp,48
    80003c9e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ca0:	05050493          	addi	s1,a0,80
    80003ca4:	08050913          	addi	s2,a0,128
    80003ca8:	a021                	j	80003cb0 <itrunc+0x22>
    80003caa:	0491                	addi	s1,s1,4
    80003cac:	01248d63          	beq	s1,s2,80003cc6 <itrunc+0x38>
    if(ip->addrs[i]){
    80003cb0:	408c                	lw	a1,0(s1)
    80003cb2:	dde5                	beqz	a1,80003caa <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003cb4:	0009a503          	lw	a0,0(s3)
    80003cb8:	00000097          	auipc	ra,0x0
    80003cbc:	90c080e7          	jalr	-1780(ra) # 800035c4 <bfree>
      ip->addrs[i] = 0;
    80003cc0:	0004a023          	sw	zero,0(s1)
    80003cc4:	b7dd                	j	80003caa <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003cc6:	0809a583          	lw	a1,128(s3)
    80003cca:	e185                	bnez	a1,80003cea <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ccc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003cd0:	854e                	mv	a0,s3
    80003cd2:	00000097          	auipc	ra,0x0
    80003cd6:	de4080e7          	jalr	-540(ra) # 80003ab6 <iupdate>
}
    80003cda:	70a2                	ld	ra,40(sp)
    80003cdc:	7402                	ld	s0,32(sp)
    80003cde:	64e2                	ld	s1,24(sp)
    80003ce0:	6942                	ld	s2,16(sp)
    80003ce2:	69a2                	ld	s3,8(sp)
    80003ce4:	6a02                	ld	s4,0(sp)
    80003ce6:	6145                	addi	sp,sp,48
    80003ce8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003cea:	0009a503          	lw	a0,0(s3)
    80003cee:	fffff097          	auipc	ra,0xfffff
    80003cf2:	690080e7          	jalr	1680(ra) # 8000337e <bread>
    80003cf6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003cf8:	05850493          	addi	s1,a0,88
    80003cfc:	45850913          	addi	s2,a0,1112
    80003d00:	a811                	j	80003d14 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003d02:	0009a503          	lw	a0,0(s3)
    80003d06:	00000097          	auipc	ra,0x0
    80003d0a:	8be080e7          	jalr	-1858(ra) # 800035c4 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003d0e:	0491                	addi	s1,s1,4
    80003d10:	01248563          	beq	s1,s2,80003d1a <itrunc+0x8c>
      if(a[j])
    80003d14:	408c                	lw	a1,0(s1)
    80003d16:	dde5                	beqz	a1,80003d0e <itrunc+0x80>
    80003d18:	b7ed                	j	80003d02 <itrunc+0x74>
    brelse(bp);
    80003d1a:	8552                	mv	a0,s4
    80003d1c:	fffff097          	auipc	ra,0xfffff
    80003d20:	792080e7          	jalr	1938(ra) # 800034ae <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d24:	0809a583          	lw	a1,128(s3)
    80003d28:	0009a503          	lw	a0,0(s3)
    80003d2c:	00000097          	auipc	ra,0x0
    80003d30:	898080e7          	jalr	-1896(ra) # 800035c4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d34:	0809a023          	sw	zero,128(s3)
    80003d38:	bf51                	j	80003ccc <itrunc+0x3e>

0000000080003d3a <iput>:
{
    80003d3a:	1101                	addi	sp,sp,-32
    80003d3c:	ec06                	sd	ra,24(sp)
    80003d3e:	e822                	sd	s0,16(sp)
    80003d40:	e426                	sd	s1,8(sp)
    80003d42:	e04a                	sd	s2,0(sp)
    80003d44:	1000                	addi	s0,sp,32
    80003d46:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d48:	0001c517          	auipc	a0,0x1c
    80003d4c:	5c050513          	addi	a0,a0,1472 # 80020308 <itable>
    80003d50:	ffffd097          	auipc	ra,0xffffd
    80003d54:	e94080e7          	jalr	-364(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d58:	4498                	lw	a4,8(s1)
    80003d5a:	4785                	li	a5,1
    80003d5c:	02f70363          	beq	a4,a5,80003d82 <iput+0x48>
  ip->ref--;
    80003d60:	449c                	lw	a5,8(s1)
    80003d62:	37fd                	addiw	a5,a5,-1
    80003d64:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d66:	0001c517          	auipc	a0,0x1c
    80003d6a:	5a250513          	addi	a0,a0,1442 # 80020308 <itable>
    80003d6e:	ffffd097          	auipc	ra,0xffffd
    80003d72:	f2a080e7          	jalr	-214(ra) # 80000c98 <release>
}
    80003d76:	60e2                	ld	ra,24(sp)
    80003d78:	6442                	ld	s0,16(sp)
    80003d7a:	64a2                	ld	s1,8(sp)
    80003d7c:	6902                	ld	s2,0(sp)
    80003d7e:	6105                	addi	sp,sp,32
    80003d80:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d82:	40bc                	lw	a5,64(s1)
    80003d84:	dff1                	beqz	a5,80003d60 <iput+0x26>
    80003d86:	04a49783          	lh	a5,74(s1)
    80003d8a:	fbf9                	bnez	a5,80003d60 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d8c:	01048913          	addi	s2,s1,16
    80003d90:	854a                	mv	a0,s2
    80003d92:	00001097          	auipc	ra,0x1
    80003d96:	ab8080e7          	jalr	-1352(ra) # 8000484a <acquiresleep>
    release(&itable.lock);
    80003d9a:	0001c517          	auipc	a0,0x1c
    80003d9e:	56e50513          	addi	a0,a0,1390 # 80020308 <itable>
    80003da2:	ffffd097          	auipc	ra,0xffffd
    80003da6:	ef6080e7          	jalr	-266(ra) # 80000c98 <release>
    itrunc(ip);
    80003daa:	8526                	mv	a0,s1
    80003dac:	00000097          	auipc	ra,0x0
    80003db0:	ee2080e7          	jalr	-286(ra) # 80003c8e <itrunc>
    ip->type = 0;
    80003db4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003db8:	8526                	mv	a0,s1
    80003dba:	00000097          	auipc	ra,0x0
    80003dbe:	cfc080e7          	jalr	-772(ra) # 80003ab6 <iupdate>
    ip->valid = 0;
    80003dc2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003dc6:	854a                	mv	a0,s2
    80003dc8:	00001097          	auipc	ra,0x1
    80003dcc:	ad8080e7          	jalr	-1320(ra) # 800048a0 <releasesleep>
    acquire(&itable.lock);
    80003dd0:	0001c517          	auipc	a0,0x1c
    80003dd4:	53850513          	addi	a0,a0,1336 # 80020308 <itable>
    80003dd8:	ffffd097          	auipc	ra,0xffffd
    80003ddc:	e0c080e7          	jalr	-500(ra) # 80000be4 <acquire>
    80003de0:	b741                	j	80003d60 <iput+0x26>

0000000080003de2 <iunlockput>:
{
    80003de2:	1101                	addi	sp,sp,-32
    80003de4:	ec06                	sd	ra,24(sp)
    80003de6:	e822                	sd	s0,16(sp)
    80003de8:	e426                	sd	s1,8(sp)
    80003dea:	1000                	addi	s0,sp,32
    80003dec:	84aa                	mv	s1,a0
  iunlock(ip);
    80003dee:	00000097          	auipc	ra,0x0
    80003df2:	e54080e7          	jalr	-428(ra) # 80003c42 <iunlock>
  iput(ip);
    80003df6:	8526                	mv	a0,s1
    80003df8:	00000097          	auipc	ra,0x0
    80003dfc:	f42080e7          	jalr	-190(ra) # 80003d3a <iput>
}
    80003e00:	60e2                	ld	ra,24(sp)
    80003e02:	6442                	ld	s0,16(sp)
    80003e04:	64a2                	ld	s1,8(sp)
    80003e06:	6105                	addi	sp,sp,32
    80003e08:	8082                	ret

0000000080003e0a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e0a:	1141                	addi	sp,sp,-16
    80003e0c:	e422                	sd	s0,8(sp)
    80003e0e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e10:	411c                	lw	a5,0(a0)
    80003e12:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e14:	415c                	lw	a5,4(a0)
    80003e16:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e18:	04451783          	lh	a5,68(a0)
    80003e1c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e20:	04a51783          	lh	a5,74(a0)
    80003e24:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e28:	04c56783          	lwu	a5,76(a0)
    80003e2c:	e99c                	sd	a5,16(a1)
}
    80003e2e:	6422                	ld	s0,8(sp)
    80003e30:	0141                	addi	sp,sp,16
    80003e32:	8082                	ret

0000000080003e34 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e34:	457c                	lw	a5,76(a0)
    80003e36:	0ed7e963          	bltu	a5,a3,80003f28 <readi+0xf4>
{
    80003e3a:	7159                	addi	sp,sp,-112
    80003e3c:	f486                	sd	ra,104(sp)
    80003e3e:	f0a2                	sd	s0,96(sp)
    80003e40:	eca6                	sd	s1,88(sp)
    80003e42:	e8ca                	sd	s2,80(sp)
    80003e44:	e4ce                	sd	s3,72(sp)
    80003e46:	e0d2                	sd	s4,64(sp)
    80003e48:	fc56                	sd	s5,56(sp)
    80003e4a:	f85a                	sd	s6,48(sp)
    80003e4c:	f45e                	sd	s7,40(sp)
    80003e4e:	f062                	sd	s8,32(sp)
    80003e50:	ec66                	sd	s9,24(sp)
    80003e52:	e86a                	sd	s10,16(sp)
    80003e54:	e46e                	sd	s11,8(sp)
    80003e56:	1880                	addi	s0,sp,112
    80003e58:	8baa                	mv	s7,a0
    80003e5a:	8c2e                	mv	s8,a1
    80003e5c:	8ab2                	mv	s5,a2
    80003e5e:	84b6                	mv	s1,a3
    80003e60:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e62:	9f35                	addw	a4,a4,a3
    return 0;
    80003e64:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e66:	0ad76063          	bltu	a4,a3,80003f06 <readi+0xd2>
  if(off + n > ip->size)
    80003e6a:	00e7f463          	bgeu	a5,a4,80003e72 <readi+0x3e>
    n = ip->size - off;
    80003e6e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e72:	0a0b0963          	beqz	s6,80003f24 <readi+0xf0>
    80003e76:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e78:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e7c:	5cfd                	li	s9,-1
    80003e7e:	a82d                	j	80003eb8 <readi+0x84>
    80003e80:	020a1d93          	slli	s11,s4,0x20
    80003e84:	020ddd93          	srli	s11,s11,0x20
    80003e88:	05890613          	addi	a2,s2,88
    80003e8c:	86ee                	mv	a3,s11
    80003e8e:	963a                	add	a2,a2,a4
    80003e90:	85d6                	mv	a1,s5
    80003e92:	8562                	mv	a0,s8
    80003e94:	fffff097          	auipc	ra,0xfffff
    80003e98:	a7a080e7          	jalr	-1414(ra) # 8000290e <either_copyout>
    80003e9c:	05950d63          	beq	a0,s9,80003ef6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ea0:	854a                	mv	a0,s2
    80003ea2:	fffff097          	auipc	ra,0xfffff
    80003ea6:	60c080e7          	jalr	1548(ra) # 800034ae <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003eaa:	013a09bb          	addw	s3,s4,s3
    80003eae:	009a04bb          	addw	s1,s4,s1
    80003eb2:	9aee                	add	s5,s5,s11
    80003eb4:	0569f763          	bgeu	s3,s6,80003f02 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003eb8:	000ba903          	lw	s2,0(s7)
    80003ebc:	00a4d59b          	srliw	a1,s1,0xa
    80003ec0:	855e                	mv	a0,s7
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	8b0080e7          	jalr	-1872(ra) # 80003772 <bmap>
    80003eca:	0005059b          	sext.w	a1,a0
    80003ece:	854a                	mv	a0,s2
    80003ed0:	fffff097          	auipc	ra,0xfffff
    80003ed4:	4ae080e7          	jalr	1198(ra) # 8000337e <bread>
    80003ed8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eda:	3ff4f713          	andi	a4,s1,1023
    80003ede:	40ed07bb          	subw	a5,s10,a4
    80003ee2:	413b06bb          	subw	a3,s6,s3
    80003ee6:	8a3e                	mv	s4,a5
    80003ee8:	2781                	sext.w	a5,a5
    80003eea:	0006861b          	sext.w	a2,a3
    80003eee:	f8f679e3          	bgeu	a2,a5,80003e80 <readi+0x4c>
    80003ef2:	8a36                	mv	s4,a3
    80003ef4:	b771                	j	80003e80 <readi+0x4c>
      brelse(bp);
    80003ef6:	854a                	mv	a0,s2
    80003ef8:	fffff097          	auipc	ra,0xfffff
    80003efc:	5b6080e7          	jalr	1462(ra) # 800034ae <brelse>
      tot = -1;
    80003f00:	59fd                	li	s3,-1
  }
  return tot;
    80003f02:	0009851b          	sext.w	a0,s3
}
    80003f06:	70a6                	ld	ra,104(sp)
    80003f08:	7406                	ld	s0,96(sp)
    80003f0a:	64e6                	ld	s1,88(sp)
    80003f0c:	6946                	ld	s2,80(sp)
    80003f0e:	69a6                	ld	s3,72(sp)
    80003f10:	6a06                	ld	s4,64(sp)
    80003f12:	7ae2                	ld	s5,56(sp)
    80003f14:	7b42                	ld	s6,48(sp)
    80003f16:	7ba2                	ld	s7,40(sp)
    80003f18:	7c02                	ld	s8,32(sp)
    80003f1a:	6ce2                	ld	s9,24(sp)
    80003f1c:	6d42                	ld	s10,16(sp)
    80003f1e:	6da2                	ld	s11,8(sp)
    80003f20:	6165                	addi	sp,sp,112
    80003f22:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f24:	89da                	mv	s3,s6
    80003f26:	bff1                	j	80003f02 <readi+0xce>
    return 0;
    80003f28:	4501                	li	a0,0
}
    80003f2a:	8082                	ret

0000000080003f2c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f2c:	457c                	lw	a5,76(a0)
    80003f2e:	10d7e863          	bltu	a5,a3,8000403e <writei+0x112>
{
    80003f32:	7159                	addi	sp,sp,-112
    80003f34:	f486                	sd	ra,104(sp)
    80003f36:	f0a2                	sd	s0,96(sp)
    80003f38:	eca6                	sd	s1,88(sp)
    80003f3a:	e8ca                	sd	s2,80(sp)
    80003f3c:	e4ce                	sd	s3,72(sp)
    80003f3e:	e0d2                	sd	s4,64(sp)
    80003f40:	fc56                	sd	s5,56(sp)
    80003f42:	f85a                	sd	s6,48(sp)
    80003f44:	f45e                	sd	s7,40(sp)
    80003f46:	f062                	sd	s8,32(sp)
    80003f48:	ec66                	sd	s9,24(sp)
    80003f4a:	e86a                	sd	s10,16(sp)
    80003f4c:	e46e                	sd	s11,8(sp)
    80003f4e:	1880                	addi	s0,sp,112
    80003f50:	8b2a                	mv	s6,a0
    80003f52:	8c2e                	mv	s8,a1
    80003f54:	8ab2                	mv	s5,a2
    80003f56:	8936                	mv	s2,a3
    80003f58:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003f5a:	00e687bb          	addw	a5,a3,a4
    80003f5e:	0ed7e263          	bltu	a5,a3,80004042 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f62:	00043737          	lui	a4,0x43
    80003f66:	0ef76063          	bltu	a4,a5,80004046 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f6a:	0c0b8863          	beqz	s7,8000403a <writei+0x10e>
    80003f6e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f70:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f74:	5cfd                	li	s9,-1
    80003f76:	a091                	j	80003fba <writei+0x8e>
    80003f78:	02099d93          	slli	s11,s3,0x20
    80003f7c:	020ddd93          	srli	s11,s11,0x20
    80003f80:	05848513          	addi	a0,s1,88
    80003f84:	86ee                	mv	a3,s11
    80003f86:	8656                	mv	a2,s5
    80003f88:	85e2                	mv	a1,s8
    80003f8a:	953a                	add	a0,a0,a4
    80003f8c:	fffff097          	auipc	ra,0xfffff
    80003f90:	9d8080e7          	jalr	-1576(ra) # 80002964 <either_copyin>
    80003f94:	07950263          	beq	a0,s9,80003ff8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f98:	8526                	mv	a0,s1
    80003f9a:	00000097          	auipc	ra,0x0
    80003f9e:	790080e7          	jalr	1936(ra) # 8000472a <log_write>
    brelse(bp);
    80003fa2:	8526                	mv	a0,s1
    80003fa4:	fffff097          	auipc	ra,0xfffff
    80003fa8:	50a080e7          	jalr	1290(ra) # 800034ae <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fac:	01498a3b          	addw	s4,s3,s4
    80003fb0:	0129893b          	addw	s2,s3,s2
    80003fb4:	9aee                	add	s5,s5,s11
    80003fb6:	057a7663          	bgeu	s4,s7,80004002 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fba:	000b2483          	lw	s1,0(s6)
    80003fbe:	00a9559b          	srliw	a1,s2,0xa
    80003fc2:	855a                	mv	a0,s6
    80003fc4:	fffff097          	auipc	ra,0xfffff
    80003fc8:	7ae080e7          	jalr	1966(ra) # 80003772 <bmap>
    80003fcc:	0005059b          	sext.w	a1,a0
    80003fd0:	8526                	mv	a0,s1
    80003fd2:	fffff097          	auipc	ra,0xfffff
    80003fd6:	3ac080e7          	jalr	940(ra) # 8000337e <bread>
    80003fda:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fdc:	3ff97713          	andi	a4,s2,1023
    80003fe0:	40ed07bb          	subw	a5,s10,a4
    80003fe4:	414b86bb          	subw	a3,s7,s4
    80003fe8:	89be                	mv	s3,a5
    80003fea:	2781                	sext.w	a5,a5
    80003fec:	0006861b          	sext.w	a2,a3
    80003ff0:	f8f674e3          	bgeu	a2,a5,80003f78 <writei+0x4c>
    80003ff4:	89b6                	mv	s3,a3
    80003ff6:	b749                	j	80003f78 <writei+0x4c>
      brelse(bp);
    80003ff8:	8526                	mv	a0,s1
    80003ffa:	fffff097          	auipc	ra,0xfffff
    80003ffe:	4b4080e7          	jalr	1204(ra) # 800034ae <brelse>
  }

  if(off > ip->size)
    80004002:	04cb2783          	lw	a5,76(s6)
    80004006:	0127f463          	bgeu	a5,s2,8000400e <writei+0xe2>
    ip->size = off;
    8000400a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000400e:	855a                	mv	a0,s6
    80004010:	00000097          	auipc	ra,0x0
    80004014:	aa6080e7          	jalr	-1370(ra) # 80003ab6 <iupdate>

  return tot;
    80004018:	000a051b          	sext.w	a0,s4
}
    8000401c:	70a6                	ld	ra,104(sp)
    8000401e:	7406                	ld	s0,96(sp)
    80004020:	64e6                	ld	s1,88(sp)
    80004022:	6946                	ld	s2,80(sp)
    80004024:	69a6                	ld	s3,72(sp)
    80004026:	6a06                	ld	s4,64(sp)
    80004028:	7ae2                	ld	s5,56(sp)
    8000402a:	7b42                	ld	s6,48(sp)
    8000402c:	7ba2                	ld	s7,40(sp)
    8000402e:	7c02                	ld	s8,32(sp)
    80004030:	6ce2                	ld	s9,24(sp)
    80004032:	6d42                	ld	s10,16(sp)
    80004034:	6da2                	ld	s11,8(sp)
    80004036:	6165                	addi	sp,sp,112
    80004038:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000403a:	8a5e                	mv	s4,s7
    8000403c:	bfc9                	j	8000400e <writei+0xe2>
    return -1;
    8000403e:	557d                	li	a0,-1
}
    80004040:	8082                	ret
    return -1;
    80004042:	557d                	li	a0,-1
    80004044:	bfe1                	j	8000401c <writei+0xf0>
    return -1;
    80004046:	557d                	li	a0,-1
    80004048:	bfd1                	j	8000401c <writei+0xf0>

000000008000404a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000404a:	1141                	addi	sp,sp,-16
    8000404c:	e406                	sd	ra,8(sp)
    8000404e:	e022                	sd	s0,0(sp)
    80004050:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004052:	4639                	li	a2,14
    80004054:	ffffd097          	auipc	ra,0xffffd
    80004058:	d64080e7          	jalr	-668(ra) # 80000db8 <strncmp>
}
    8000405c:	60a2                	ld	ra,8(sp)
    8000405e:	6402                	ld	s0,0(sp)
    80004060:	0141                	addi	sp,sp,16
    80004062:	8082                	ret

0000000080004064 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004064:	7139                	addi	sp,sp,-64
    80004066:	fc06                	sd	ra,56(sp)
    80004068:	f822                	sd	s0,48(sp)
    8000406a:	f426                	sd	s1,40(sp)
    8000406c:	f04a                	sd	s2,32(sp)
    8000406e:	ec4e                	sd	s3,24(sp)
    80004070:	e852                	sd	s4,16(sp)
    80004072:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004074:	04451703          	lh	a4,68(a0)
    80004078:	4785                	li	a5,1
    8000407a:	00f71a63          	bne	a4,a5,8000408e <dirlookup+0x2a>
    8000407e:	892a                	mv	s2,a0
    80004080:	89ae                	mv	s3,a1
    80004082:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004084:	457c                	lw	a5,76(a0)
    80004086:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004088:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000408a:	e79d                	bnez	a5,800040b8 <dirlookup+0x54>
    8000408c:	a8a5                	j	80004104 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000408e:	00004517          	auipc	a0,0x4
    80004092:	5e250513          	addi	a0,a0,1506 # 80008670 <syscalls+0x1a0>
    80004096:	ffffc097          	auipc	ra,0xffffc
    8000409a:	4a8080e7          	jalr	1192(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000409e:	00004517          	auipc	a0,0x4
    800040a2:	5ea50513          	addi	a0,a0,1514 # 80008688 <syscalls+0x1b8>
    800040a6:	ffffc097          	auipc	ra,0xffffc
    800040aa:	498080e7          	jalr	1176(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ae:	24c1                	addiw	s1,s1,16
    800040b0:	04c92783          	lw	a5,76(s2)
    800040b4:	04f4f763          	bgeu	s1,a5,80004102 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040b8:	4741                	li	a4,16
    800040ba:	86a6                	mv	a3,s1
    800040bc:	fc040613          	addi	a2,s0,-64
    800040c0:	4581                	li	a1,0
    800040c2:	854a                	mv	a0,s2
    800040c4:	00000097          	auipc	ra,0x0
    800040c8:	d70080e7          	jalr	-656(ra) # 80003e34 <readi>
    800040cc:	47c1                	li	a5,16
    800040ce:	fcf518e3          	bne	a0,a5,8000409e <dirlookup+0x3a>
    if(de.inum == 0)
    800040d2:	fc045783          	lhu	a5,-64(s0)
    800040d6:	dfe1                	beqz	a5,800040ae <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040d8:	fc240593          	addi	a1,s0,-62
    800040dc:	854e                	mv	a0,s3
    800040de:	00000097          	auipc	ra,0x0
    800040e2:	f6c080e7          	jalr	-148(ra) # 8000404a <namecmp>
    800040e6:	f561                	bnez	a0,800040ae <dirlookup+0x4a>
      if(poff)
    800040e8:	000a0463          	beqz	s4,800040f0 <dirlookup+0x8c>
        *poff = off;
    800040ec:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800040f0:	fc045583          	lhu	a1,-64(s0)
    800040f4:	00092503          	lw	a0,0(s2)
    800040f8:	fffff097          	auipc	ra,0xfffff
    800040fc:	754080e7          	jalr	1876(ra) # 8000384c <iget>
    80004100:	a011                	j	80004104 <dirlookup+0xa0>
  return 0;
    80004102:	4501                	li	a0,0
}
    80004104:	70e2                	ld	ra,56(sp)
    80004106:	7442                	ld	s0,48(sp)
    80004108:	74a2                	ld	s1,40(sp)
    8000410a:	7902                	ld	s2,32(sp)
    8000410c:	69e2                	ld	s3,24(sp)
    8000410e:	6a42                	ld	s4,16(sp)
    80004110:	6121                	addi	sp,sp,64
    80004112:	8082                	ret

0000000080004114 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004114:	711d                	addi	sp,sp,-96
    80004116:	ec86                	sd	ra,88(sp)
    80004118:	e8a2                	sd	s0,80(sp)
    8000411a:	e4a6                	sd	s1,72(sp)
    8000411c:	e0ca                	sd	s2,64(sp)
    8000411e:	fc4e                	sd	s3,56(sp)
    80004120:	f852                	sd	s4,48(sp)
    80004122:	f456                	sd	s5,40(sp)
    80004124:	f05a                	sd	s6,32(sp)
    80004126:	ec5e                	sd	s7,24(sp)
    80004128:	e862                	sd	s8,16(sp)
    8000412a:	e466                	sd	s9,8(sp)
    8000412c:	1080                	addi	s0,sp,96
    8000412e:	84aa                	mv	s1,a0
    80004130:	8b2e                	mv	s6,a1
    80004132:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004134:	00054703          	lbu	a4,0(a0)
    80004138:	02f00793          	li	a5,47
    8000413c:	02f70363          	beq	a4,a5,80004162 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004140:	ffffe097          	auipc	ra,0xffffe
    80004144:	b8e080e7          	jalr	-1138(ra) # 80001cce <myproc>
    80004148:	15053503          	ld	a0,336(a0)
    8000414c:	00000097          	auipc	ra,0x0
    80004150:	9f6080e7          	jalr	-1546(ra) # 80003b42 <idup>
    80004154:	89aa                	mv	s3,a0
  while(*path == '/')
    80004156:	02f00913          	li	s2,47
  len = path - s;
    8000415a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000415c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000415e:	4c05                	li	s8,1
    80004160:	a865                	j	80004218 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004162:	4585                	li	a1,1
    80004164:	4505                	li	a0,1
    80004166:	fffff097          	auipc	ra,0xfffff
    8000416a:	6e6080e7          	jalr	1766(ra) # 8000384c <iget>
    8000416e:	89aa                	mv	s3,a0
    80004170:	b7dd                	j	80004156 <namex+0x42>
      iunlockput(ip);
    80004172:	854e                	mv	a0,s3
    80004174:	00000097          	auipc	ra,0x0
    80004178:	c6e080e7          	jalr	-914(ra) # 80003de2 <iunlockput>
      return 0;
    8000417c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000417e:	854e                	mv	a0,s3
    80004180:	60e6                	ld	ra,88(sp)
    80004182:	6446                	ld	s0,80(sp)
    80004184:	64a6                	ld	s1,72(sp)
    80004186:	6906                	ld	s2,64(sp)
    80004188:	79e2                	ld	s3,56(sp)
    8000418a:	7a42                	ld	s4,48(sp)
    8000418c:	7aa2                	ld	s5,40(sp)
    8000418e:	7b02                	ld	s6,32(sp)
    80004190:	6be2                	ld	s7,24(sp)
    80004192:	6c42                	ld	s8,16(sp)
    80004194:	6ca2                	ld	s9,8(sp)
    80004196:	6125                	addi	sp,sp,96
    80004198:	8082                	ret
      iunlock(ip);
    8000419a:	854e                	mv	a0,s3
    8000419c:	00000097          	auipc	ra,0x0
    800041a0:	aa6080e7          	jalr	-1370(ra) # 80003c42 <iunlock>
      return ip;
    800041a4:	bfe9                	j	8000417e <namex+0x6a>
      iunlockput(ip);
    800041a6:	854e                	mv	a0,s3
    800041a8:	00000097          	auipc	ra,0x0
    800041ac:	c3a080e7          	jalr	-966(ra) # 80003de2 <iunlockput>
      return 0;
    800041b0:	89d2                	mv	s3,s4
    800041b2:	b7f1                	j	8000417e <namex+0x6a>
  len = path - s;
    800041b4:	40b48633          	sub	a2,s1,a1
    800041b8:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800041bc:	094cd463          	bge	s9,s4,80004244 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800041c0:	4639                	li	a2,14
    800041c2:	8556                	mv	a0,s5
    800041c4:	ffffd097          	auipc	ra,0xffffd
    800041c8:	b7c080e7          	jalr	-1156(ra) # 80000d40 <memmove>
  while(*path == '/')
    800041cc:	0004c783          	lbu	a5,0(s1)
    800041d0:	01279763          	bne	a5,s2,800041de <namex+0xca>
    path++;
    800041d4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041d6:	0004c783          	lbu	a5,0(s1)
    800041da:	ff278de3          	beq	a5,s2,800041d4 <namex+0xc0>
    ilock(ip);
    800041de:	854e                	mv	a0,s3
    800041e0:	00000097          	auipc	ra,0x0
    800041e4:	9a0080e7          	jalr	-1632(ra) # 80003b80 <ilock>
    if(ip->type != T_DIR){
    800041e8:	04499783          	lh	a5,68(s3)
    800041ec:	f98793e3          	bne	a5,s8,80004172 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800041f0:	000b0563          	beqz	s6,800041fa <namex+0xe6>
    800041f4:	0004c783          	lbu	a5,0(s1)
    800041f8:	d3cd                	beqz	a5,8000419a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800041fa:	865e                	mv	a2,s7
    800041fc:	85d6                	mv	a1,s5
    800041fe:	854e                	mv	a0,s3
    80004200:	00000097          	auipc	ra,0x0
    80004204:	e64080e7          	jalr	-412(ra) # 80004064 <dirlookup>
    80004208:	8a2a                	mv	s4,a0
    8000420a:	dd51                	beqz	a0,800041a6 <namex+0x92>
    iunlockput(ip);
    8000420c:	854e                	mv	a0,s3
    8000420e:	00000097          	auipc	ra,0x0
    80004212:	bd4080e7          	jalr	-1068(ra) # 80003de2 <iunlockput>
    ip = next;
    80004216:	89d2                	mv	s3,s4
  while(*path == '/')
    80004218:	0004c783          	lbu	a5,0(s1)
    8000421c:	05279763          	bne	a5,s2,8000426a <namex+0x156>
    path++;
    80004220:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004222:	0004c783          	lbu	a5,0(s1)
    80004226:	ff278de3          	beq	a5,s2,80004220 <namex+0x10c>
  if(*path == 0)
    8000422a:	c79d                	beqz	a5,80004258 <namex+0x144>
    path++;
    8000422c:	85a6                	mv	a1,s1
  len = path - s;
    8000422e:	8a5e                	mv	s4,s7
    80004230:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004232:	01278963          	beq	a5,s2,80004244 <namex+0x130>
    80004236:	dfbd                	beqz	a5,800041b4 <namex+0xa0>
    path++;
    80004238:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000423a:	0004c783          	lbu	a5,0(s1)
    8000423e:	ff279ce3          	bne	a5,s2,80004236 <namex+0x122>
    80004242:	bf8d                	j	800041b4 <namex+0xa0>
    memmove(name, s, len);
    80004244:	2601                	sext.w	a2,a2
    80004246:	8556                	mv	a0,s5
    80004248:	ffffd097          	auipc	ra,0xffffd
    8000424c:	af8080e7          	jalr	-1288(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004250:	9a56                	add	s4,s4,s5
    80004252:	000a0023          	sb	zero,0(s4)
    80004256:	bf9d                	j	800041cc <namex+0xb8>
  if(nameiparent){
    80004258:	f20b03e3          	beqz	s6,8000417e <namex+0x6a>
    iput(ip);
    8000425c:	854e                	mv	a0,s3
    8000425e:	00000097          	auipc	ra,0x0
    80004262:	adc080e7          	jalr	-1316(ra) # 80003d3a <iput>
    return 0;
    80004266:	4981                	li	s3,0
    80004268:	bf19                	j	8000417e <namex+0x6a>
  if(*path == 0)
    8000426a:	d7fd                	beqz	a5,80004258 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000426c:	0004c783          	lbu	a5,0(s1)
    80004270:	85a6                	mv	a1,s1
    80004272:	b7d1                	j	80004236 <namex+0x122>

0000000080004274 <dirlink>:
{
    80004274:	7139                	addi	sp,sp,-64
    80004276:	fc06                	sd	ra,56(sp)
    80004278:	f822                	sd	s0,48(sp)
    8000427a:	f426                	sd	s1,40(sp)
    8000427c:	f04a                	sd	s2,32(sp)
    8000427e:	ec4e                	sd	s3,24(sp)
    80004280:	e852                	sd	s4,16(sp)
    80004282:	0080                	addi	s0,sp,64
    80004284:	892a                	mv	s2,a0
    80004286:	8a2e                	mv	s4,a1
    80004288:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000428a:	4601                	li	a2,0
    8000428c:	00000097          	auipc	ra,0x0
    80004290:	dd8080e7          	jalr	-552(ra) # 80004064 <dirlookup>
    80004294:	e93d                	bnez	a0,8000430a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004296:	04c92483          	lw	s1,76(s2)
    8000429a:	c49d                	beqz	s1,800042c8 <dirlink+0x54>
    8000429c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000429e:	4741                	li	a4,16
    800042a0:	86a6                	mv	a3,s1
    800042a2:	fc040613          	addi	a2,s0,-64
    800042a6:	4581                	li	a1,0
    800042a8:	854a                	mv	a0,s2
    800042aa:	00000097          	auipc	ra,0x0
    800042ae:	b8a080e7          	jalr	-1142(ra) # 80003e34 <readi>
    800042b2:	47c1                	li	a5,16
    800042b4:	06f51163          	bne	a0,a5,80004316 <dirlink+0xa2>
    if(de.inum == 0)
    800042b8:	fc045783          	lhu	a5,-64(s0)
    800042bc:	c791                	beqz	a5,800042c8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042be:	24c1                	addiw	s1,s1,16
    800042c0:	04c92783          	lw	a5,76(s2)
    800042c4:	fcf4ede3          	bltu	s1,a5,8000429e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042c8:	4639                	li	a2,14
    800042ca:	85d2                	mv	a1,s4
    800042cc:	fc240513          	addi	a0,s0,-62
    800042d0:	ffffd097          	auipc	ra,0xffffd
    800042d4:	b24080e7          	jalr	-1244(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800042d8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042dc:	4741                	li	a4,16
    800042de:	86a6                	mv	a3,s1
    800042e0:	fc040613          	addi	a2,s0,-64
    800042e4:	4581                	li	a1,0
    800042e6:	854a                	mv	a0,s2
    800042e8:	00000097          	auipc	ra,0x0
    800042ec:	c44080e7          	jalr	-956(ra) # 80003f2c <writei>
    800042f0:	872a                	mv	a4,a0
    800042f2:	47c1                	li	a5,16
  return 0;
    800042f4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042f6:	02f71863          	bne	a4,a5,80004326 <dirlink+0xb2>
}
    800042fa:	70e2                	ld	ra,56(sp)
    800042fc:	7442                	ld	s0,48(sp)
    800042fe:	74a2                	ld	s1,40(sp)
    80004300:	7902                	ld	s2,32(sp)
    80004302:	69e2                	ld	s3,24(sp)
    80004304:	6a42                	ld	s4,16(sp)
    80004306:	6121                	addi	sp,sp,64
    80004308:	8082                	ret
    iput(ip);
    8000430a:	00000097          	auipc	ra,0x0
    8000430e:	a30080e7          	jalr	-1488(ra) # 80003d3a <iput>
    return -1;
    80004312:	557d                	li	a0,-1
    80004314:	b7dd                	j	800042fa <dirlink+0x86>
      panic("dirlink read");
    80004316:	00004517          	auipc	a0,0x4
    8000431a:	38250513          	addi	a0,a0,898 # 80008698 <syscalls+0x1c8>
    8000431e:	ffffc097          	auipc	ra,0xffffc
    80004322:	220080e7          	jalr	544(ra) # 8000053e <panic>
    panic("dirlink");
    80004326:	00004517          	auipc	a0,0x4
    8000432a:	48250513          	addi	a0,a0,1154 # 800087a8 <syscalls+0x2d8>
    8000432e:	ffffc097          	auipc	ra,0xffffc
    80004332:	210080e7          	jalr	528(ra) # 8000053e <panic>

0000000080004336 <namei>:

struct inode*
namei(char *path)
{
    80004336:	1101                	addi	sp,sp,-32
    80004338:	ec06                	sd	ra,24(sp)
    8000433a:	e822                	sd	s0,16(sp)
    8000433c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000433e:	fe040613          	addi	a2,s0,-32
    80004342:	4581                	li	a1,0
    80004344:	00000097          	auipc	ra,0x0
    80004348:	dd0080e7          	jalr	-560(ra) # 80004114 <namex>
}
    8000434c:	60e2                	ld	ra,24(sp)
    8000434e:	6442                	ld	s0,16(sp)
    80004350:	6105                	addi	sp,sp,32
    80004352:	8082                	ret

0000000080004354 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004354:	1141                	addi	sp,sp,-16
    80004356:	e406                	sd	ra,8(sp)
    80004358:	e022                	sd	s0,0(sp)
    8000435a:	0800                	addi	s0,sp,16
    8000435c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000435e:	4585                	li	a1,1
    80004360:	00000097          	auipc	ra,0x0
    80004364:	db4080e7          	jalr	-588(ra) # 80004114 <namex>
}
    80004368:	60a2                	ld	ra,8(sp)
    8000436a:	6402                	ld	s0,0(sp)
    8000436c:	0141                	addi	sp,sp,16
    8000436e:	8082                	ret

0000000080004370 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004370:	1101                	addi	sp,sp,-32
    80004372:	ec06                	sd	ra,24(sp)
    80004374:	e822                	sd	s0,16(sp)
    80004376:	e426                	sd	s1,8(sp)
    80004378:	e04a                	sd	s2,0(sp)
    8000437a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000437c:	0001e917          	auipc	s2,0x1e
    80004380:	a3490913          	addi	s2,s2,-1484 # 80021db0 <log>
    80004384:	01892583          	lw	a1,24(s2)
    80004388:	02892503          	lw	a0,40(s2)
    8000438c:	fffff097          	auipc	ra,0xfffff
    80004390:	ff2080e7          	jalr	-14(ra) # 8000337e <bread>
    80004394:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004396:	02c92683          	lw	a3,44(s2)
    8000439a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000439c:	02d05763          	blez	a3,800043ca <write_head+0x5a>
    800043a0:	0001e797          	auipc	a5,0x1e
    800043a4:	a4078793          	addi	a5,a5,-1472 # 80021de0 <log+0x30>
    800043a8:	05c50713          	addi	a4,a0,92
    800043ac:	36fd                	addiw	a3,a3,-1
    800043ae:	1682                	slli	a3,a3,0x20
    800043b0:	9281                	srli	a3,a3,0x20
    800043b2:	068a                	slli	a3,a3,0x2
    800043b4:	0001e617          	auipc	a2,0x1e
    800043b8:	a3060613          	addi	a2,a2,-1488 # 80021de4 <log+0x34>
    800043bc:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800043be:	4390                	lw	a2,0(a5)
    800043c0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043c2:	0791                	addi	a5,a5,4
    800043c4:	0711                	addi	a4,a4,4
    800043c6:	fed79ce3          	bne	a5,a3,800043be <write_head+0x4e>
  }
  bwrite(buf);
    800043ca:	8526                	mv	a0,s1
    800043cc:	fffff097          	auipc	ra,0xfffff
    800043d0:	0a4080e7          	jalr	164(ra) # 80003470 <bwrite>
  brelse(buf);
    800043d4:	8526                	mv	a0,s1
    800043d6:	fffff097          	auipc	ra,0xfffff
    800043da:	0d8080e7          	jalr	216(ra) # 800034ae <brelse>
}
    800043de:	60e2                	ld	ra,24(sp)
    800043e0:	6442                	ld	s0,16(sp)
    800043e2:	64a2                	ld	s1,8(sp)
    800043e4:	6902                	ld	s2,0(sp)
    800043e6:	6105                	addi	sp,sp,32
    800043e8:	8082                	ret

00000000800043ea <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ea:	0001e797          	auipc	a5,0x1e
    800043ee:	9f27a783          	lw	a5,-1550(a5) # 80021ddc <log+0x2c>
    800043f2:	0af05d63          	blez	a5,800044ac <install_trans+0xc2>
{
    800043f6:	7139                	addi	sp,sp,-64
    800043f8:	fc06                	sd	ra,56(sp)
    800043fa:	f822                	sd	s0,48(sp)
    800043fc:	f426                	sd	s1,40(sp)
    800043fe:	f04a                	sd	s2,32(sp)
    80004400:	ec4e                	sd	s3,24(sp)
    80004402:	e852                	sd	s4,16(sp)
    80004404:	e456                	sd	s5,8(sp)
    80004406:	e05a                	sd	s6,0(sp)
    80004408:	0080                	addi	s0,sp,64
    8000440a:	8b2a                	mv	s6,a0
    8000440c:	0001ea97          	auipc	s5,0x1e
    80004410:	9d4a8a93          	addi	s5,s5,-1580 # 80021de0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004414:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004416:	0001e997          	auipc	s3,0x1e
    8000441a:	99a98993          	addi	s3,s3,-1638 # 80021db0 <log>
    8000441e:	a035                	j	8000444a <install_trans+0x60>
      bunpin(dbuf);
    80004420:	8526                	mv	a0,s1
    80004422:	fffff097          	auipc	ra,0xfffff
    80004426:	166080e7          	jalr	358(ra) # 80003588 <bunpin>
    brelse(lbuf);
    8000442a:	854a                	mv	a0,s2
    8000442c:	fffff097          	auipc	ra,0xfffff
    80004430:	082080e7          	jalr	130(ra) # 800034ae <brelse>
    brelse(dbuf);
    80004434:	8526                	mv	a0,s1
    80004436:	fffff097          	auipc	ra,0xfffff
    8000443a:	078080e7          	jalr	120(ra) # 800034ae <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000443e:	2a05                	addiw	s4,s4,1
    80004440:	0a91                	addi	s5,s5,4
    80004442:	02c9a783          	lw	a5,44(s3)
    80004446:	04fa5963          	bge	s4,a5,80004498 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000444a:	0189a583          	lw	a1,24(s3)
    8000444e:	014585bb          	addw	a1,a1,s4
    80004452:	2585                	addiw	a1,a1,1
    80004454:	0289a503          	lw	a0,40(s3)
    80004458:	fffff097          	auipc	ra,0xfffff
    8000445c:	f26080e7          	jalr	-218(ra) # 8000337e <bread>
    80004460:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004462:	000aa583          	lw	a1,0(s5)
    80004466:	0289a503          	lw	a0,40(s3)
    8000446a:	fffff097          	auipc	ra,0xfffff
    8000446e:	f14080e7          	jalr	-236(ra) # 8000337e <bread>
    80004472:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004474:	40000613          	li	a2,1024
    80004478:	05890593          	addi	a1,s2,88
    8000447c:	05850513          	addi	a0,a0,88
    80004480:	ffffd097          	auipc	ra,0xffffd
    80004484:	8c0080e7          	jalr	-1856(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004488:	8526                	mv	a0,s1
    8000448a:	fffff097          	auipc	ra,0xfffff
    8000448e:	fe6080e7          	jalr	-26(ra) # 80003470 <bwrite>
    if(recovering == 0)
    80004492:	f80b1ce3          	bnez	s6,8000442a <install_trans+0x40>
    80004496:	b769                	j	80004420 <install_trans+0x36>
}
    80004498:	70e2                	ld	ra,56(sp)
    8000449a:	7442                	ld	s0,48(sp)
    8000449c:	74a2                	ld	s1,40(sp)
    8000449e:	7902                	ld	s2,32(sp)
    800044a0:	69e2                	ld	s3,24(sp)
    800044a2:	6a42                	ld	s4,16(sp)
    800044a4:	6aa2                	ld	s5,8(sp)
    800044a6:	6b02                	ld	s6,0(sp)
    800044a8:	6121                	addi	sp,sp,64
    800044aa:	8082                	ret
    800044ac:	8082                	ret

00000000800044ae <initlog>:
{
    800044ae:	7179                	addi	sp,sp,-48
    800044b0:	f406                	sd	ra,40(sp)
    800044b2:	f022                	sd	s0,32(sp)
    800044b4:	ec26                	sd	s1,24(sp)
    800044b6:	e84a                	sd	s2,16(sp)
    800044b8:	e44e                	sd	s3,8(sp)
    800044ba:	1800                	addi	s0,sp,48
    800044bc:	892a                	mv	s2,a0
    800044be:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044c0:	0001e497          	auipc	s1,0x1e
    800044c4:	8f048493          	addi	s1,s1,-1808 # 80021db0 <log>
    800044c8:	00004597          	auipc	a1,0x4
    800044cc:	1e058593          	addi	a1,a1,480 # 800086a8 <syscalls+0x1d8>
    800044d0:	8526                	mv	a0,s1
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	682080e7          	jalr	1666(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800044da:	0149a583          	lw	a1,20(s3)
    800044de:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800044e0:	0109a783          	lw	a5,16(s3)
    800044e4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044e6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044ea:	854a                	mv	a0,s2
    800044ec:	fffff097          	auipc	ra,0xfffff
    800044f0:	e92080e7          	jalr	-366(ra) # 8000337e <bread>
  log.lh.n = lh->n;
    800044f4:	4d3c                	lw	a5,88(a0)
    800044f6:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800044f8:	02f05563          	blez	a5,80004522 <initlog+0x74>
    800044fc:	05c50713          	addi	a4,a0,92
    80004500:	0001e697          	auipc	a3,0x1e
    80004504:	8e068693          	addi	a3,a3,-1824 # 80021de0 <log+0x30>
    80004508:	37fd                	addiw	a5,a5,-1
    8000450a:	1782                	slli	a5,a5,0x20
    8000450c:	9381                	srli	a5,a5,0x20
    8000450e:	078a                	slli	a5,a5,0x2
    80004510:	06050613          	addi	a2,a0,96
    80004514:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004516:	4310                	lw	a2,0(a4)
    80004518:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000451a:	0711                	addi	a4,a4,4
    8000451c:	0691                	addi	a3,a3,4
    8000451e:	fef71ce3          	bne	a4,a5,80004516 <initlog+0x68>
  brelse(buf);
    80004522:	fffff097          	auipc	ra,0xfffff
    80004526:	f8c080e7          	jalr	-116(ra) # 800034ae <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000452a:	4505                	li	a0,1
    8000452c:	00000097          	auipc	ra,0x0
    80004530:	ebe080e7          	jalr	-322(ra) # 800043ea <install_trans>
  log.lh.n = 0;
    80004534:	0001e797          	auipc	a5,0x1e
    80004538:	8a07a423          	sw	zero,-1880(a5) # 80021ddc <log+0x2c>
  write_head(); // clear the log
    8000453c:	00000097          	auipc	ra,0x0
    80004540:	e34080e7          	jalr	-460(ra) # 80004370 <write_head>
}
    80004544:	70a2                	ld	ra,40(sp)
    80004546:	7402                	ld	s0,32(sp)
    80004548:	64e2                	ld	s1,24(sp)
    8000454a:	6942                	ld	s2,16(sp)
    8000454c:	69a2                	ld	s3,8(sp)
    8000454e:	6145                	addi	sp,sp,48
    80004550:	8082                	ret

0000000080004552 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004552:	1101                	addi	sp,sp,-32
    80004554:	ec06                	sd	ra,24(sp)
    80004556:	e822                	sd	s0,16(sp)
    80004558:	e426                	sd	s1,8(sp)
    8000455a:	e04a                	sd	s2,0(sp)
    8000455c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000455e:	0001e517          	auipc	a0,0x1e
    80004562:	85250513          	addi	a0,a0,-1966 # 80021db0 <log>
    80004566:	ffffc097          	auipc	ra,0xffffc
    8000456a:	67e080e7          	jalr	1662(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000456e:	0001e497          	auipc	s1,0x1e
    80004572:	84248493          	addi	s1,s1,-1982 # 80021db0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004576:	4979                	li	s2,30
    80004578:	a039                	j	80004586 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000457a:	85a6                	mv	a1,s1
    8000457c:	8526                	mv	a0,s1
    8000457e:	ffffe097          	auipc	ra,0xffffe
    80004582:	f56080e7          	jalr	-170(ra) # 800024d4 <sleep>
    if(log.committing){
    80004586:	50dc                	lw	a5,36(s1)
    80004588:	fbed                	bnez	a5,8000457a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000458a:	509c                	lw	a5,32(s1)
    8000458c:	0017871b          	addiw	a4,a5,1
    80004590:	0007069b          	sext.w	a3,a4
    80004594:	0027179b          	slliw	a5,a4,0x2
    80004598:	9fb9                	addw	a5,a5,a4
    8000459a:	0017979b          	slliw	a5,a5,0x1
    8000459e:	54d8                	lw	a4,44(s1)
    800045a0:	9fb9                	addw	a5,a5,a4
    800045a2:	00f95963          	bge	s2,a5,800045b4 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045a6:	85a6                	mv	a1,s1
    800045a8:	8526                	mv	a0,s1
    800045aa:	ffffe097          	auipc	ra,0xffffe
    800045ae:	f2a080e7          	jalr	-214(ra) # 800024d4 <sleep>
    800045b2:	bfd1                	j	80004586 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045b4:	0001d517          	auipc	a0,0x1d
    800045b8:	7fc50513          	addi	a0,a0,2044 # 80021db0 <log>
    800045bc:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	6da080e7          	jalr	1754(ra) # 80000c98 <release>
      break;
    }
  }
}
    800045c6:	60e2                	ld	ra,24(sp)
    800045c8:	6442                	ld	s0,16(sp)
    800045ca:	64a2                	ld	s1,8(sp)
    800045cc:	6902                	ld	s2,0(sp)
    800045ce:	6105                	addi	sp,sp,32
    800045d0:	8082                	ret

00000000800045d2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045d2:	7139                	addi	sp,sp,-64
    800045d4:	fc06                	sd	ra,56(sp)
    800045d6:	f822                	sd	s0,48(sp)
    800045d8:	f426                	sd	s1,40(sp)
    800045da:	f04a                	sd	s2,32(sp)
    800045dc:	ec4e                	sd	s3,24(sp)
    800045de:	e852                	sd	s4,16(sp)
    800045e0:	e456                	sd	s5,8(sp)
    800045e2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045e4:	0001d497          	auipc	s1,0x1d
    800045e8:	7cc48493          	addi	s1,s1,1996 # 80021db0 <log>
    800045ec:	8526                	mv	a0,s1
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	5f6080e7          	jalr	1526(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800045f6:	509c                	lw	a5,32(s1)
    800045f8:	37fd                	addiw	a5,a5,-1
    800045fa:	0007891b          	sext.w	s2,a5
    800045fe:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004600:	50dc                	lw	a5,36(s1)
    80004602:	efb9                	bnez	a5,80004660 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004604:	06091663          	bnez	s2,80004670 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004608:	0001d497          	auipc	s1,0x1d
    8000460c:	7a848493          	addi	s1,s1,1960 # 80021db0 <log>
    80004610:	4785                	li	a5,1
    80004612:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004614:	8526                	mv	a0,s1
    80004616:	ffffc097          	auipc	ra,0xffffc
    8000461a:	682080e7          	jalr	1666(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000461e:	54dc                	lw	a5,44(s1)
    80004620:	06f04763          	bgtz	a5,8000468e <end_op+0xbc>
    acquire(&log.lock);
    80004624:	0001d497          	auipc	s1,0x1d
    80004628:	78c48493          	addi	s1,s1,1932 # 80021db0 <log>
    8000462c:	8526                	mv	a0,s1
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	5b6080e7          	jalr	1462(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004636:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000463a:	8526                	mv	a0,s1
    8000463c:	ffffe097          	auipc	ra,0xffffe
    80004640:	036080e7          	jalr	54(ra) # 80002672 <wakeup>
    release(&log.lock);
    80004644:	8526                	mv	a0,s1
    80004646:	ffffc097          	auipc	ra,0xffffc
    8000464a:	652080e7          	jalr	1618(ra) # 80000c98 <release>
}
    8000464e:	70e2                	ld	ra,56(sp)
    80004650:	7442                	ld	s0,48(sp)
    80004652:	74a2                	ld	s1,40(sp)
    80004654:	7902                	ld	s2,32(sp)
    80004656:	69e2                	ld	s3,24(sp)
    80004658:	6a42                	ld	s4,16(sp)
    8000465a:	6aa2                	ld	s5,8(sp)
    8000465c:	6121                	addi	sp,sp,64
    8000465e:	8082                	ret
    panic("log.committing");
    80004660:	00004517          	auipc	a0,0x4
    80004664:	05050513          	addi	a0,a0,80 # 800086b0 <syscalls+0x1e0>
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	ed6080e7          	jalr	-298(ra) # 8000053e <panic>
    wakeup(&log);
    80004670:	0001d497          	auipc	s1,0x1d
    80004674:	74048493          	addi	s1,s1,1856 # 80021db0 <log>
    80004678:	8526                	mv	a0,s1
    8000467a:	ffffe097          	auipc	ra,0xffffe
    8000467e:	ff8080e7          	jalr	-8(ra) # 80002672 <wakeup>
  release(&log.lock);
    80004682:	8526                	mv	a0,s1
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	614080e7          	jalr	1556(ra) # 80000c98 <release>
  if(do_commit){
    8000468c:	b7c9                	j	8000464e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000468e:	0001da97          	auipc	s5,0x1d
    80004692:	752a8a93          	addi	s5,s5,1874 # 80021de0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004696:	0001da17          	auipc	s4,0x1d
    8000469a:	71aa0a13          	addi	s4,s4,1818 # 80021db0 <log>
    8000469e:	018a2583          	lw	a1,24(s4)
    800046a2:	012585bb          	addw	a1,a1,s2
    800046a6:	2585                	addiw	a1,a1,1
    800046a8:	028a2503          	lw	a0,40(s4)
    800046ac:	fffff097          	auipc	ra,0xfffff
    800046b0:	cd2080e7          	jalr	-814(ra) # 8000337e <bread>
    800046b4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046b6:	000aa583          	lw	a1,0(s5)
    800046ba:	028a2503          	lw	a0,40(s4)
    800046be:	fffff097          	auipc	ra,0xfffff
    800046c2:	cc0080e7          	jalr	-832(ra) # 8000337e <bread>
    800046c6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046c8:	40000613          	li	a2,1024
    800046cc:	05850593          	addi	a1,a0,88
    800046d0:	05848513          	addi	a0,s1,88
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	66c080e7          	jalr	1644(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800046dc:	8526                	mv	a0,s1
    800046de:	fffff097          	auipc	ra,0xfffff
    800046e2:	d92080e7          	jalr	-622(ra) # 80003470 <bwrite>
    brelse(from);
    800046e6:	854e                	mv	a0,s3
    800046e8:	fffff097          	auipc	ra,0xfffff
    800046ec:	dc6080e7          	jalr	-570(ra) # 800034ae <brelse>
    brelse(to);
    800046f0:	8526                	mv	a0,s1
    800046f2:	fffff097          	auipc	ra,0xfffff
    800046f6:	dbc080e7          	jalr	-580(ra) # 800034ae <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046fa:	2905                	addiw	s2,s2,1
    800046fc:	0a91                	addi	s5,s5,4
    800046fe:	02ca2783          	lw	a5,44(s4)
    80004702:	f8f94ee3          	blt	s2,a5,8000469e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004706:	00000097          	auipc	ra,0x0
    8000470a:	c6a080e7          	jalr	-918(ra) # 80004370 <write_head>
    install_trans(0); // Now install writes to home locations
    8000470e:	4501                	li	a0,0
    80004710:	00000097          	auipc	ra,0x0
    80004714:	cda080e7          	jalr	-806(ra) # 800043ea <install_trans>
    log.lh.n = 0;
    80004718:	0001d797          	auipc	a5,0x1d
    8000471c:	6c07a223          	sw	zero,1732(a5) # 80021ddc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004720:	00000097          	auipc	ra,0x0
    80004724:	c50080e7          	jalr	-944(ra) # 80004370 <write_head>
    80004728:	bdf5                	j	80004624 <end_op+0x52>

000000008000472a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000472a:	1101                	addi	sp,sp,-32
    8000472c:	ec06                	sd	ra,24(sp)
    8000472e:	e822                	sd	s0,16(sp)
    80004730:	e426                	sd	s1,8(sp)
    80004732:	e04a                	sd	s2,0(sp)
    80004734:	1000                	addi	s0,sp,32
    80004736:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004738:	0001d917          	auipc	s2,0x1d
    8000473c:	67890913          	addi	s2,s2,1656 # 80021db0 <log>
    80004740:	854a                	mv	a0,s2
    80004742:	ffffc097          	auipc	ra,0xffffc
    80004746:	4a2080e7          	jalr	1186(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000474a:	02c92603          	lw	a2,44(s2)
    8000474e:	47f5                	li	a5,29
    80004750:	06c7c563          	blt	a5,a2,800047ba <log_write+0x90>
    80004754:	0001d797          	auipc	a5,0x1d
    80004758:	6787a783          	lw	a5,1656(a5) # 80021dcc <log+0x1c>
    8000475c:	37fd                	addiw	a5,a5,-1
    8000475e:	04f65e63          	bge	a2,a5,800047ba <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004762:	0001d797          	auipc	a5,0x1d
    80004766:	66e7a783          	lw	a5,1646(a5) # 80021dd0 <log+0x20>
    8000476a:	06f05063          	blez	a5,800047ca <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000476e:	4781                	li	a5,0
    80004770:	06c05563          	blez	a2,800047da <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004774:	44cc                	lw	a1,12(s1)
    80004776:	0001d717          	auipc	a4,0x1d
    8000477a:	66a70713          	addi	a4,a4,1642 # 80021de0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000477e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004780:	4314                	lw	a3,0(a4)
    80004782:	04b68c63          	beq	a3,a1,800047da <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004786:	2785                	addiw	a5,a5,1
    80004788:	0711                	addi	a4,a4,4
    8000478a:	fef61be3          	bne	a2,a5,80004780 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000478e:	0621                	addi	a2,a2,8
    80004790:	060a                	slli	a2,a2,0x2
    80004792:	0001d797          	auipc	a5,0x1d
    80004796:	61e78793          	addi	a5,a5,1566 # 80021db0 <log>
    8000479a:	963e                	add	a2,a2,a5
    8000479c:	44dc                	lw	a5,12(s1)
    8000479e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800047a0:	8526                	mv	a0,s1
    800047a2:	fffff097          	auipc	ra,0xfffff
    800047a6:	daa080e7          	jalr	-598(ra) # 8000354c <bpin>
    log.lh.n++;
    800047aa:	0001d717          	auipc	a4,0x1d
    800047ae:	60670713          	addi	a4,a4,1542 # 80021db0 <log>
    800047b2:	575c                	lw	a5,44(a4)
    800047b4:	2785                	addiw	a5,a5,1
    800047b6:	d75c                	sw	a5,44(a4)
    800047b8:	a835                	j	800047f4 <log_write+0xca>
    panic("too big a transaction");
    800047ba:	00004517          	auipc	a0,0x4
    800047be:	f0650513          	addi	a0,a0,-250 # 800086c0 <syscalls+0x1f0>
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	d7c080e7          	jalr	-644(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800047ca:	00004517          	auipc	a0,0x4
    800047ce:	f0e50513          	addi	a0,a0,-242 # 800086d8 <syscalls+0x208>
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	d6c080e7          	jalr	-660(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800047da:	00878713          	addi	a4,a5,8
    800047de:	00271693          	slli	a3,a4,0x2
    800047e2:	0001d717          	auipc	a4,0x1d
    800047e6:	5ce70713          	addi	a4,a4,1486 # 80021db0 <log>
    800047ea:	9736                	add	a4,a4,a3
    800047ec:	44d4                	lw	a3,12(s1)
    800047ee:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800047f0:	faf608e3          	beq	a2,a5,800047a0 <log_write+0x76>
  }
  release(&log.lock);
    800047f4:	0001d517          	auipc	a0,0x1d
    800047f8:	5bc50513          	addi	a0,a0,1468 # 80021db0 <log>
    800047fc:	ffffc097          	auipc	ra,0xffffc
    80004800:	49c080e7          	jalr	1180(ra) # 80000c98 <release>
}
    80004804:	60e2                	ld	ra,24(sp)
    80004806:	6442                	ld	s0,16(sp)
    80004808:	64a2                	ld	s1,8(sp)
    8000480a:	6902                	ld	s2,0(sp)
    8000480c:	6105                	addi	sp,sp,32
    8000480e:	8082                	ret

0000000080004810 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004810:	1101                	addi	sp,sp,-32
    80004812:	ec06                	sd	ra,24(sp)
    80004814:	e822                	sd	s0,16(sp)
    80004816:	e426                	sd	s1,8(sp)
    80004818:	e04a                	sd	s2,0(sp)
    8000481a:	1000                	addi	s0,sp,32
    8000481c:	84aa                	mv	s1,a0
    8000481e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004820:	00004597          	auipc	a1,0x4
    80004824:	ed858593          	addi	a1,a1,-296 # 800086f8 <syscalls+0x228>
    80004828:	0521                	addi	a0,a0,8
    8000482a:	ffffc097          	auipc	ra,0xffffc
    8000482e:	32a080e7          	jalr	810(ra) # 80000b54 <initlock>
  lk->name = name;
    80004832:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004836:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000483a:	0204a423          	sw	zero,40(s1)
}
    8000483e:	60e2                	ld	ra,24(sp)
    80004840:	6442                	ld	s0,16(sp)
    80004842:	64a2                	ld	s1,8(sp)
    80004844:	6902                	ld	s2,0(sp)
    80004846:	6105                	addi	sp,sp,32
    80004848:	8082                	ret

000000008000484a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000484a:	1101                	addi	sp,sp,-32
    8000484c:	ec06                	sd	ra,24(sp)
    8000484e:	e822                	sd	s0,16(sp)
    80004850:	e426                	sd	s1,8(sp)
    80004852:	e04a                	sd	s2,0(sp)
    80004854:	1000                	addi	s0,sp,32
    80004856:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004858:	00850913          	addi	s2,a0,8
    8000485c:	854a                	mv	a0,s2
    8000485e:	ffffc097          	auipc	ra,0xffffc
    80004862:	386080e7          	jalr	902(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004866:	409c                	lw	a5,0(s1)
    80004868:	cb89                	beqz	a5,8000487a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000486a:	85ca                	mv	a1,s2
    8000486c:	8526                	mv	a0,s1
    8000486e:	ffffe097          	auipc	ra,0xffffe
    80004872:	c66080e7          	jalr	-922(ra) # 800024d4 <sleep>
  while (lk->locked) {
    80004876:	409c                	lw	a5,0(s1)
    80004878:	fbed                	bnez	a5,8000486a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000487a:	4785                	li	a5,1
    8000487c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000487e:	ffffd097          	auipc	ra,0xffffd
    80004882:	450080e7          	jalr	1104(ra) # 80001cce <myproc>
    80004886:	591c                	lw	a5,48(a0)
    80004888:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000488a:	854a                	mv	a0,s2
    8000488c:	ffffc097          	auipc	ra,0xffffc
    80004890:	40c080e7          	jalr	1036(ra) # 80000c98 <release>
}
    80004894:	60e2                	ld	ra,24(sp)
    80004896:	6442                	ld	s0,16(sp)
    80004898:	64a2                	ld	s1,8(sp)
    8000489a:	6902                	ld	s2,0(sp)
    8000489c:	6105                	addi	sp,sp,32
    8000489e:	8082                	ret

00000000800048a0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800048a0:	1101                	addi	sp,sp,-32
    800048a2:	ec06                	sd	ra,24(sp)
    800048a4:	e822                	sd	s0,16(sp)
    800048a6:	e426                	sd	s1,8(sp)
    800048a8:	e04a                	sd	s2,0(sp)
    800048aa:	1000                	addi	s0,sp,32
    800048ac:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048ae:	00850913          	addi	s2,a0,8
    800048b2:	854a                	mv	a0,s2
    800048b4:	ffffc097          	auipc	ra,0xffffc
    800048b8:	330080e7          	jalr	816(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800048bc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048c0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800048c4:	8526                	mv	a0,s1
    800048c6:	ffffe097          	auipc	ra,0xffffe
    800048ca:	dac080e7          	jalr	-596(ra) # 80002672 <wakeup>
  release(&lk->lk);
    800048ce:	854a                	mv	a0,s2
    800048d0:	ffffc097          	auipc	ra,0xffffc
    800048d4:	3c8080e7          	jalr	968(ra) # 80000c98 <release>
}
    800048d8:	60e2                	ld	ra,24(sp)
    800048da:	6442                	ld	s0,16(sp)
    800048dc:	64a2                	ld	s1,8(sp)
    800048de:	6902                	ld	s2,0(sp)
    800048e0:	6105                	addi	sp,sp,32
    800048e2:	8082                	ret

00000000800048e4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048e4:	7179                	addi	sp,sp,-48
    800048e6:	f406                	sd	ra,40(sp)
    800048e8:	f022                	sd	s0,32(sp)
    800048ea:	ec26                	sd	s1,24(sp)
    800048ec:	e84a                	sd	s2,16(sp)
    800048ee:	e44e                	sd	s3,8(sp)
    800048f0:	1800                	addi	s0,sp,48
    800048f2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800048f4:	00850913          	addi	s2,a0,8
    800048f8:	854a                	mv	a0,s2
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	2ea080e7          	jalr	746(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004902:	409c                	lw	a5,0(s1)
    80004904:	ef99                	bnez	a5,80004922 <holdingsleep+0x3e>
    80004906:	4481                	li	s1,0
  release(&lk->lk);
    80004908:	854a                	mv	a0,s2
    8000490a:	ffffc097          	auipc	ra,0xffffc
    8000490e:	38e080e7          	jalr	910(ra) # 80000c98 <release>
  return r;
}
    80004912:	8526                	mv	a0,s1
    80004914:	70a2                	ld	ra,40(sp)
    80004916:	7402                	ld	s0,32(sp)
    80004918:	64e2                	ld	s1,24(sp)
    8000491a:	6942                	ld	s2,16(sp)
    8000491c:	69a2                	ld	s3,8(sp)
    8000491e:	6145                	addi	sp,sp,48
    80004920:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004922:	0284a983          	lw	s3,40(s1)
    80004926:	ffffd097          	auipc	ra,0xffffd
    8000492a:	3a8080e7          	jalr	936(ra) # 80001cce <myproc>
    8000492e:	5904                	lw	s1,48(a0)
    80004930:	413484b3          	sub	s1,s1,s3
    80004934:	0014b493          	seqz	s1,s1
    80004938:	bfc1                	j	80004908 <holdingsleep+0x24>

000000008000493a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000493a:	1141                	addi	sp,sp,-16
    8000493c:	e406                	sd	ra,8(sp)
    8000493e:	e022                	sd	s0,0(sp)
    80004940:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004942:	00004597          	auipc	a1,0x4
    80004946:	dc658593          	addi	a1,a1,-570 # 80008708 <syscalls+0x238>
    8000494a:	0001d517          	auipc	a0,0x1d
    8000494e:	5ae50513          	addi	a0,a0,1454 # 80021ef8 <ftable>
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	202080e7          	jalr	514(ra) # 80000b54 <initlock>
}
    8000495a:	60a2                	ld	ra,8(sp)
    8000495c:	6402                	ld	s0,0(sp)
    8000495e:	0141                	addi	sp,sp,16
    80004960:	8082                	ret

0000000080004962 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004962:	1101                	addi	sp,sp,-32
    80004964:	ec06                	sd	ra,24(sp)
    80004966:	e822                	sd	s0,16(sp)
    80004968:	e426                	sd	s1,8(sp)
    8000496a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000496c:	0001d517          	auipc	a0,0x1d
    80004970:	58c50513          	addi	a0,a0,1420 # 80021ef8 <ftable>
    80004974:	ffffc097          	auipc	ra,0xffffc
    80004978:	270080e7          	jalr	624(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000497c:	0001d497          	auipc	s1,0x1d
    80004980:	59448493          	addi	s1,s1,1428 # 80021f10 <ftable+0x18>
    80004984:	0001e717          	auipc	a4,0x1e
    80004988:	52c70713          	addi	a4,a4,1324 # 80022eb0 <ftable+0xfb8>
    if(f->ref == 0){
    8000498c:	40dc                	lw	a5,4(s1)
    8000498e:	cf99                	beqz	a5,800049ac <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004990:	02848493          	addi	s1,s1,40
    80004994:	fee49ce3          	bne	s1,a4,8000498c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004998:	0001d517          	auipc	a0,0x1d
    8000499c:	56050513          	addi	a0,a0,1376 # 80021ef8 <ftable>
    800049a0:	ffffc097          	auipc	ra,0xffffc
    800049a4:	2f8080e7          	jalr	760(ra) # 80000c98 <release>
  return 0;
    800049a8:	4481                	li	s1,0
    800049aa:	a819                	j	800049c0 <filealloc+0x5e>
      f->ref = 1;
    800049ac:	4785                	li	a5,1
    800049ae:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049b0:	0001d517          	auipc	a0,0x1d
    800049b4:	54850513          	addi	a0,a0,1352 # 80021ef8 <ftable>
    800049b8:	ffffc097          	auipc	ra,0xffffc
    800049bc:	2e0080e7          	jalr	736(ra) # 80000c98 <release>
}
    800049c0:	8526                	mv	a0,s1
    800049c2:	60e2                	ld	ra,24(sp)
    800049c4:	6442                	ld	s0,16(sp)
    800049c6:	64a2                	ld	s1,8(sp)
    800049c8:	6105                	addi	sp,sp,32
    800049ca:	8082                	ret

00000000800049cc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049cc:	1101                	addi	sp,sp,-32
    800049ce:	ec06                	sd	ra,24(sp)
    800049d0:	e822                	sd	s0,16(sp)
    800049d2:	e426                	sd	s1,8(sp)
    800049d4:	1000                	addi	s0,sp,32
    800049d6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049d8:	0001d517          	auipc	a0,0x1d
    800049dc:	52050513          	addi	a0,a0,1312 # 80021ef8 <ftable>
    800049e0:	ffffc097          	auipc	ra,0xffffc
    800049e4:	204080e7          	jalr	516(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800049e8:	40dc                	lw	a5,4(s1)
    800049ea:	02f05263          	blez	a5,80004a0e <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049ee:	2785                	addiw	a5,a5,1
    800049f0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800049f2:	0001d517          	auipc	a0,0x1d
    800049f6:	50650513          	addi	a0,a0,1286 # 80021ef8 <ftable>
    800049fa:	ffffc097          	auipc	ra,0xffffc
    800049fe:	29e080e7          	jalr	670(ra) # 80000c98 <release>
  return f;
}
    80004a02:	8526                	mv	a0,s1
    80004a04:	60e2                	ld	ra,24(sp)
    80004a06:	6442                	ld	s0,16(sp)
    80004a08:	64a2                	ld	s1,8(sp)
    80004a0a:	6105                	addi	sp,sp,32
    80004a0c:	8082                	ret
    panic("filedup");
    80004a0e:	00004517          	auipc	a0,0x4
    80004a12:	d0250513          	addi	a0,a0,-766 # 80008710 <syscalls+0x240>
    80004a16:	ffffc097          	auipc	ra,0xffffc
    80004a1a:	b28080e7          	jalr	-1240(ra) # 8000053e <panic>

0000000080004a1e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a1e:	7139                	addi	sp,sp,-64
    80004a20:	fc06                	sd	ra,56(sp)
    80004a22:	f822                	sd	s0,48(sp)
    80004a24:	f426                	sd	s1,40(sp)
    80004a26:	f04a                	sd	s2,32(sp)
    80004a28:	ec4e                	sd	s3,24(sp)
    80004a2a:	e852                	sd	s4,16(sp)
    80004a2c:	e456                	sd	s5,8(sp)
    80004a2e:	0080                	addi	s0,sp,64
    80004a30:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a32:	0001d517          	auipc	a0,0x1d
    80004a36:	4c650513          	addi	a0,a0,1222 # 80021ef8 <ftable>
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	1aa080e7          	jalr	426(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a42:	40dc                	lw	a5,4(s1)
    80004a44:	06f05163          	blez	a5,80004aa6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a48:	37fd                	addiw	a5,a5,-1
    80004a4a:	0007871b          	sext.w	a4,a5
    80004a4e:	c0dc                	sw	a5,4(s1)
    80004a50:	06e04363          	bgtz	a4,80004ab6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a54:	0004a903          	lw	s2,0(s1)
    80004a58:	0094ca83          	lbu	s5,9(s1)
    80004a5c:	0104ba03          	ld	s4,16(s1)
    80004a60:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a64:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a68:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a6c:	0001d517          	auipc	a0,0x1d
    80004a70:	48c50513          	addi	a0,a0,1164 # 80021ef8 <ftable>
    80004a74:	ffffc097          	auipc	ra,0xffffc
    80004a78:	224080e7          	jalr	548(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004a7c:	4785                	li	a5,1
    80004a7e:	04f90d63          	beq	s2,a5,80004ad8 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a82:	3979                	addiw	s2,s2,-2
    80004a84:	4785                	li	a5,1
    80004a86:	0527e063          	bltu	a5,s2,80004ac6 <fileclose+0xa8>
    begin_op();
    80004a8a:	00000097          	auipc	ra,0x0
    80004a8e:	ac8080e7          	jalr	-1336(ra) # 80004552 <begin_op>
    iput(ff.ip);
    80004a92:	854e                	mv	a0,s3
    80004a94:	fffff097          	auipc	ra,0xfffff
    80004a98:	2a6080e7          	jalr	678(ra) # 80003d3a <iput>
    end_op();
    80004a9c:	00000097          	auipc	ra,0x0
    80004aa0:	b36080e7          	jalr	-1226(ra) # 800045d2 <end_op>
    80004aa4:	a00d                	j	80004ac6 <fileclose+0xa8>
    panic("fileclose");
    80004aa6:	00004517          	auipc	a0,0x4
    80004aaa:	c7250513          	addi	a0,a0,-910 # 80008718 <syscalls+0x248>
    80004aae:	ffffc097          	auipc	ra,0xffffc
    80004ab2:	a90080e7          	jalr	-1392(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004ab6:	0001d517          	auipc	a0,0x1d
    80004aba:	44250513          	addi	a0,a0,1090 # 80021ef8 <ftable>
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	1da080e7          	jalr	474(ra) # 80000c98 <release>
  }
}
    80004ac6:	70e2                	ld	ra,56(sp)
    80004ac8:	7442                	ld	s0,48(sp)
    80004aca:	74a2                	ld	s1,40(sp)
    80004acc:	7902                	ld	s2,32(sp)
    80004ace:	69e2                	ld	s3,24(sp)
    80004ad0:	6a42                	ld	s4,16(sp)
    80004ad2:	6aa2                	ld	s5,8(sp)
    80004ad4:	6121                	addi	sp,sp,64
    80004ad6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004ad8:	85d6                	mv	a1,s5
    80004ada:	8552                	mv	a0,s4
    80004adc:	00000097          	auipc	ra,0x0
    80004ae0:	34c080e7          	jalr	844(ra) # 80004e28 <pipeclose>
    80004ae4:	b7cd                	j	80004ac6 <fileclose+0xa8>

0000000080004ae6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ae6:	715d                	addi	sp,sp,-80
    80004ae8:	e486                	sd	ra,72(sp)
    80004aea:	e0a2                	sd	s0,64(sp)
    80004aec:	fc26                	sd	s1,56(sp)
    80004aee:	f84a                	sd	s2,48(sp)
    80004af0:	f44e                	sd	s3,40(sp)
    80004af2:	0880                	addi	s0,sp,80
    80004af4:	84aa                	mv	s1,a0
    80004af6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004af8:	ffffd097          	auipc	ra,0xffffd
    80004afc:	1d6080e7          	jalr	470(ra) # 80001cce <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b00:	409c                	lw	a5,0(s1)
    80004b02:	37f9                	addiw	a5,a5,-2
    80004b04:	4705                	li	a4,1
    80004b06:	04f76763          	bltu	a4,a5,80004b54 <filestat+0x6e>
    80004b0a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b0c:	6c88                	ld	a0,24(s1)
    80004b0e:	fffff097          	auipc	ra,0xfffff
    80004b12:	072080e7          	jalr	114(ra) # 80003b80 <ilock>
    stati(f->ip, &st);
    80004b16:	fb840593          	addi	a1,s0,-72
    80004b1a:	6c88                	ld	a0,24(s1)
    80004b1c:	fffff097          	auipc	ra,0xfffff
    80004b20:	2ee080e7          	jalr	750(ra) # 80003e0a <stati>
    iunlock(f->ip);
    80004b24:	6c88                	ld	a0,24(s1)
    80004b26:	fffff097          	auipc	ra,0xfffff
    80004b2a:	11c080e7          	jalr	284(ra) # 80003c42 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b2e:	46e1                	li	a3,24
    80004b30:	fb840613          	addi	a2,s0,-72
    80004b34:	85ce                	mv	a1,s3
    80004b36:	05093503          	ld	a0,80(s2)
    80004b3a:	ffffd097          	auipc	ra,0xffffd
    80004b3e:	b38080e7          	jalr	-1224(ra) # 80001672 <copyout>
    80004b42:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b46:	60a6                	ld	ra,72(sp)
    80004b48:	6406                	ld	s0,64(sp)
    80004b4a:	74e2                	ld	s1,56(sp)
    80004b4c:	7942                	ld	s2,48(sp)
    80004b4e:	79a2                	ld	s3,40(sp)
    80004b50:	6161                	addi	sp,sp,80
    80004b52:	8082                	ret
  return -1;
    80004b54:	557d                	li	a0,-1
    80004b56:	bfc5                	j	80004b46 <filestat+0x60>

0000000080004b58 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b58:	7179                	addi	sp,sp,-48
    80004b5a:	f406                	sd	ra,40(sp)
    80004b5c:	f022                	sd	s0,32(sp)
    80004b5e:	ec26                	sd	s1,24(sp)
    80004b60:	e84a                	sd	s2,16(sp)
    80004b62:	e44e                	sd	s3,8(sp)
    80004b64:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b66:	00854783          	lbu	a5,8(a0)
    80004b6a:	c3d5                	beqz	a5,80004c0e <fileread+0xb6>
    80004b6c:	84aa                	mv	s1,a0
    80004b6e:	89ae                	mv	s3,a1
    80004b70:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b72:	411c                	lw	a5,0(a0)
    80004b74:	4705                	li	a4,1
    80004b76:	04e78963          	beq	a5,a4,80004bc8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b7a:	470d                	li	a4,3
    80004b7c:	04e78d63          	beq	a5,a4,80004bd6 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b80:	4709                	li	a4,2
    80004b82:	06e79e63          	bne	a5,a4,80004bfe <fileread+0xa6>
    ilock(f->ip);
    80004b86:	6d08                	ld	a0,24(a0)
    80004b88:	fffff097          	auipc	ra,0xfffff
    80004b8c:	ff8080e7          	jalr	-8(ra) # 80003b80 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b90:	874a                	mv	a4,s2
    80004b92:	5094                	lw	a3,32(s1)
    80004b94:	864e                	mv	a2,s3
    80004b96:	4585                	li	a1,1
    80004b98:	6c88                	ld	a0,24(s1)
    80004b9a:	fffff097          	auipc	ra,0xfffff
    80004b9e:	29a080e7          	jalr	666(ra) # 80003e34 <readi>
    80004ba2:	892a                	mv	s2,a0
    80004ba4:	00a05563          	blez	a0,80004bae <fileread+0x56>
      f->off += r;
    80004ba8:	509c                	lw	a5,32(s1)
    80004baa:	9fa9                	addw	a5,a5,a0
    80004bac:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004bae:	6c88                	ld	a0,24(s1)
    80004bb0:	fffff097          	auipc	ra,0xfffff
    80004bb4:	092080e7          	jalr	146(ra) # 80003c42 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004bb8:	854a                	mv	a0,s2
    80004bba:	70a2                	ld	ra,40(sp)
    80004bbc:	7402                	ld	s0,32(sp)
    80004bbe:	64e2                	ld	s1,24(sp)
    80004bc0:	6942                	ld	s2,16(sp)
    80004bc2:	69a2                	ld	s3,8(sp)
    80004bc4:	6145                	addi	sp,sp,48
    80004bc6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004bc8:	6908                	ld	a0,16(a0)
    80004bca:	00000097          	auipc	ra,0x0
    80004bce:	3c8080e7          	jalr	968(ra) # 80004f92 <piperead>
    80004bd2:	892a                	mv	s2,a0
    80004bd4:	b7d5                	j	80004bb8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004bd6:	02451783          	lh	a5,36(a0)
    80004bda:	03079693          	slli	a3,a5,0x30
    80004bde:	92c1                	srli	a3,a3,0x30
    80004be0:	4725                	li	a4,9
    80004be2:	02d76863          	bltu	a4,a3,80004c12 <fileread+0xba>
    80004be6:	0792                	slli	a5,a5,0x4
    80004be8:	0001d717          	auipc	a4,0x1d
    80004bec:	27070713          	addi	a4,a4,624 # 80021e58 <devsw>
    80004bf0:	97ba                	add	a5,a5,a4
    80004bf2:	639c                	ld	a5,0(a5)
    80004bf4:	c38d                	beqz	a5,80004c16 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004bf6:	4505                	li	a0,1
    80004bf8:	9782                	jalr	a5
    80004bfa:	892a                	mv	s2,a0
    80004bfc:	bf75                	j	80004bb8 <fileread+0x60>
    panic("fileread");
    80004bfe:	00004517          	auipc	a0,0x4
    80004c02:	b2a50513          	addi	a0,a0,-1238 # 80008728 <syscalls+0x258>
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	938080e7          	jalr	-1736(ra) # 8000053e <panic>
    return -1;
    80004c0e:	597d                	li	s2,-1
    80004c10:	b765                	j	80004bb8 <fileread+0x60>
      return -1;
    80004c12:	597d                	li	s2,-1
    80004c14:	b755                	j	80004bb8 <fileread+0x60>
    80004c16:	597d                	li	s2,-1
    80004c18:	b745                	j	80004bb8 <fileread+0x60>

0000000080004c1a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c1a:	715d                	addi	sp,sp,-80
    80004c1c:	e486                	sd	ra,72(sp)
    80004c1e:	e0a2                	sd	s0,64(sp)
    80004c20:	fc26                	sd	s1,56(sp)
    80004c22:	f84a                	sd	s2,48(sp)
    80004c24:	f44e                	sd	s3,40(sp)
    80004c26:	f052                	sd	s4,32(sp)
    80004c28:	ec56                	sd	s5,24(sp)
    80004c2a:	e85a                	sd	s6,16(sp)
    80004c2c:	e45e                	sd	s7,8(sp)
    80004c2e:	e062                	sd	s8,0(sp)
    80004c30:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c32:	00954783          	lbu	a5,9(a0)
    80004c36:	10078663          	beqz	a5,80004d42 <filewrite+0x128>
    80004c3a:	892a                	mv	s2,a0
    80004c3c:	8aae                	mv	s5,a1
    80004c3e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c40:	411c                	lw	a5,0(a0)
    80004c42:	4705                	li	a4,1
    80004c44:	02e78263          	beq	a5,a4,80004c68 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c48:	470d                	li	a4,3
    80004c4a:	02e78663          	beq	a5,a4,80004c76 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c4e:	4709                	li	a4,2
    80004c50:	0ee79163          	bne	a5,a4,80004d32 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c54:	0ac05d63          	blez	a2,80004d0e <filewrite+0xf4>
    int i = 0;
    80004c58:	4981                	li	s3,0
    80004c5a:	6b05                	lui	s6,0x1
    80004c5c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c60:	6b85                	lui	s7,0x1
    80004c62:	c00b8b9b          	addiw	s7,s7,-1024
    80004c66:	a861                	j	80004cfe <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c68:	6908                	ld	a0,16(a0)
    80004c6a:	00000097          	auipc	ra,0x0
    80004c6e:	22e080e7          	jalr	558(ra) # 80004e98 <pipewrite>
    80004c72:	8a2a                	mv	s4,a0
    80004c74:	a045                	j	80004d14 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c76:	02451783          	lh	a5,36(a0)
    80004c7a:	03079693          	slli	a3,a5,0x30
    80004c7e:	92c1                	srli	a3,a3,0x30
    80004c80:	4725                	li	a4,9
    80004c82:	0cd76263          	bltu	a4,a3,80004d46 <filewrite+0x12c>
    80004c86:	0792                	slli	a5,a5,0x4
    80004c88:	0001d717          	auipc	a4,0x1d
    80004c8c:	1d070713          	addi	a4,a4,464 # 80021e58 <devsw>
    80004c90:	97ba                	add	a5,a5,a4
    80004c92:	679c                	ld	a5,8(a5)
    80004c94:	cbdd                	beqz	a5,80004d4a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c96:	4505                	li	a0,1
    80004c98:	9782                	jalr	a5
    80004c9a:	8a2a                	mv	s4,a0
    80004c9c:	a8a5                	j	80004d14 <filewrite+0xfa>
    80004c9e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ca2:	00000097          	auipc	ra,0x0
    80004ca6:	8b0080e7          	jalr	-1872(ra) # 80004552 <begin_op>
      ilock(f->ip);
    80004caa:	01893503          	ld	a0,24(s2)
    80004cae:	fffff097          	auipc	ra,0xfffff
    80004cb2:	ed2080e7          	jalr	-302(ra) # 80003b80 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004cb6:	8762                	mv	a4,s8
    80004cb8:	02092683          	lw	a3,32(s2)
    80004cbc:	01598633          	add	a2,s3,s5
    80004cc0:	4585                	li	a1,1
    80004cc2:	01893503          	ld	a0,24(s2)
    80004cc6:	fffff097          	auipc	ra,0xfffff
    80004cca:	266080e7          	jalr	614(ra) # 80003f2c <writei>
    80004cce:	84aa                	mv	s1,a0
    80004cd0:	00a05763          	blez	a0,80004cde <filewrite+0xc4>
        f->off += r;
    80004cd4:	02092783          	lw	a5,32(s2)
    80004cd8:	9fa9                	addw	a5,a5,a0
    80004cda:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cde:	01893503          	ld	a0,24(s2)
    80004ce2:	fffff097          	auipc	ra,0xfffff
    80004ce6:	f60080e7          	jalr	-160(ra) # 80003c42 <iunlock>
      end_op();
    80004cea:	00000097          	auipc	ra,0x0
    80004cee:	8e8080e7          	jalr	-1816(ra) # 800045d2 <end_op>

      if(r != n1){
    80004cf2:	009c1f63          	bne	s8,s1,80004d10 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004cf6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004cfa:	0149db63          	bge	s3,s4,80004d10 <filewrite+0xf6>
      int n1 = n - i;
    80004cfe:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d02:	84be                	mv	s1,a5
    80004d04:	2781                	sext.w	a5,a5
    80004d06:	f8fb5ce3          	bge	s6,a5,80004c9e <filewrite+0x84>
    80004d0a:	84de                	mv	s1,s7
    80004d0c:	bf49                	j	80004c9e <filewrite+0x84>
    int i = 0;
    80004d0e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d10:	013a1f63          	bne	s4,s3,80004d2e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d14:	8552                	mv	a0,s4
    80004d16:	60a6                	ld	ra,72(sp)
    80004d18:	6406                	ld	s0,64(sp)
    80004d1a:	74e2                	ld	s1,56(sp)
    80004d1c:	7942                	ld	s2,48(sp)
    80004d1e:	79a2                	ld	s3,40(sp)
    80004d20:	7a02                	ld	s4,32(sp)
    80004d22:	6ae2                	ld	s5,24(sp)
    80004d24:	6b42                	ld	s6,16(sp)
    80004d26:	6ba2                	ld	s7,8(sp)
    80004d28:	6c02                	ld	s8,0(sp)
    80004d2a:	6161                	addi	sp,sp,80
    80004d2c:	8082                	ret
    ret = (i == n ? n : -1);
    80004d2e:	5a7d                	li	s4,-1
    80004d30:	b7d5                	j	80004d14 <filewrite+0xfa>
    panic("filewrite");
    80004d32:	00004517          	auipc	a0,0x4
    80004d36:	a0650513          	addi	a0,a0,-1530 # 80008738 <syscalls+0x268>
    80004d3a:	ffffc097          	auipc	ra,0xffffc
    80004d3e:	804080e7          	jalr	-2044(ra) # 8000053e <panic>
    return -1;
    80004d42:	5a7d                	li	s4,-1
    80004d44:	bfc1                	j	80004d14 <filewrite+0xfa>
      return -1;
    80004d46:	5a7d                	li	s4,-1
    80004d48:	b7f1                	j	80004d14 <filewrite+0xfa>
    80004d4a:	5a7d                	li	s4,-1
    80004d4c:	b7e1                	j	80004d14 <filewrite+0xfa>

0000000080004d4e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d4e:	7179                	addi	sp,sp,-48
    80004d50:	f406                	sd	ra,40(sp)
    80004d52:	f022                	sd	s0,32(sp)
    80004d54:	ec26                	sd	s1,24(sp)
    80004d56:	e84a                	sd	s2,16(sp)
    80004d58:	e44e                	sd	s3,8(sp)
    80004d5a:	e052                	sd	s4,0(sp)
    80004d5c:	1800                	addi	s0,sp,48
    80004d5e:	84aa                	mv	s1,a0
    80004d60:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d62:	0005b023          	sd	zero,0(a1)
    80004d66:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d6a:	00000097          	auipc	ra,0x0
    80004d6e:	bf8080e7          	jalr	-1032(ra) # 80004962 <filealloc>
    80004d72:	e088                	sd	a0,0(s1)
    80004d74:	c551                	beqz	a0,80004e00 <pipealloc+0xb2>
    80004d76:	00000097          	auipc	ra,0x0
    80004d7a:	bec080e7          	jalr	-1044(ra) # 80004962 <filealloc>
    80004d7e:	00aa3023          	sd	a0,0(s4)
    80004d82:	c92d                	beqz	a0,80004df4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d84:	ffffc097          	auipc	ra,0xffffc
    80004d88:	d70080e7          	jalr	-656(ra) # 80000af4 <kalloc>
    80004d8c:	892a                	mv	s2,a0
    80004d8e:	c125                	beqz	a0,80004dee <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d90:	4985                	li	s3,1
    80004d92:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d96:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d9a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d9e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004da2:	00004597          	auipc	a1,0x4
    80004da6:	9a658593          	addi	a1,a1,-1626 # 80008748 <syscalls+0x278>
    80004daa:	ffffc097          	auipc	ra,0xffffc
    80004dae:	daa080e7          	jalr	-598(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004db2:	609c                	ld	a5,0(s1)
    80004db4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004db8:	609c                	ld	a5,0(s1)
    80004dba:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004dbe:	609c                	ld	a5,0(s1)
    80004dc0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004dc4:	609c                	ld	a5,0(s1)
    80004dc6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004dca:	000a3783          	ld	a5,0(s4)
    80004dce:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004dd2:	000a3783          	ld	a5,0(s4)
    80004dd6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004dda:	000a3783          	ld	a5,0(s4)
    80004dde:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004de2:	000a3783          	ld	a5,0(s4)
    80004de6:	0127b823          	sd	s2,16(a5)
  return 0;
    80004dea:	4501                	li	a0,0
    80004dec:	a025                	j	80004e14 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004dee:	6088                	ld	a0,0(s1)
    80004df0:	e501                	bnez	a0,80004df8 <pipealloc+0xaa>
    80004df2:	a039                	j	80004e00 <pipealloc+0xb2>
    80004df4:	6088                	ld	a0,0(s1)
    80004df6:	c51d                	beqz	a0,80004e24 <pipealloc+0xd6>
    fileclose(*f0);
    80004df8:	00000097          	auipc	ra,0x0
    80004dfc:	c26080e7          	jalr	-986(ra) # 80004a1e <fileclose>
  if(*f1)
    80004e00:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e04:	557d                	li	a0,-1
  if(*f1)
    80004e06:	c799                	beqz	a5,80004e14 <pipealloc+0xc6>
    fileclose(*f1);
    80004e08:	853e                	mv	a0,a5
    80004e0a:	00000097          	auipc	ra,0x0
    80004e0e:	c14080e7          	jalr	-1004(ra) # 80004a1e <fileclose>
  return -1;
    80004e12:	557d                	li	a0,-1
}
    80004e14:	70a2                	ld	ra,40(sp)
    80004e16:	7402                	ld	s0,32(sp)
    80004e18:	64e2                	ld	s1,24(sp)
    80004e1a:	6942                	ld	s2,16(sp)
    80004e1c:	69a2                	ld	s3,8(sp)
    80004e1e:	6a02                	ld	s4,0(sp)
    80004e20:	6145                	addi	sp,sp,48
    80004e22:	8082                	ret
  return -1;
    80004e24:	557d                	li	a0,-1
    80004e26:	b7fd                	j	80004e14 <pipealloc+0xc6>

0000000080004e28 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e28:	1101                	addi	sp,sp,-32
    80004e2a:	ec06                	sd	ra,24(sp)
    80004e2c:	e822                	sd	s0,16(sp)
    80004e2e:	e426                	sd	s1,8(sp)
    80004e30:	e04a                	sd	s2,0(sp)
    80004e32:	1000                	addi	s0,sp,32
    80004e34:	84aa                	mv	s1,a0
    80004e36:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e38:	ffffc097          	auipc	ra,0xffffc
    80004e3c:	dac080e7          	jalr	-596(ra) # 80000be4 <acquire>
  if(writable){
    80004e40:	02090d63          	beqz	s2,80004e7a <pipeclose+0x52>
    pi->writeopen = 0;
    80004e44:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e48:	21848513          	addi	a0,s1,536
    80004e4c:	ffffe097          	auipc	ra,0xffffe
    80004e50:	826080e7          	jalr	-2010(ra) # 80002672 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e54:	2204b783          	ld	a5,544(s1)
    80004e58:	eb95                	bnez	a5,80004e8c <pipeclose+0x64>
    release(&pi->lock);
    80004e5a:	8526                	mv	a0,s1
    80004e5c:	ffffc097          	auipc	ra,0xffffc
    80004e60:	e3c080e7          	jalr	-452(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004e64:	8526                	mv	a0,s1
    80004e66:	ffffc097          	auipc	ra,0xffffc
    80004e6a:	b92080e7          	jalr	-1134(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004e6e:	60e2                	ld	ra,24(sp)
    80004e70:	6442                	ld	s0,16(sp)
    80004e72:	64a2                	ld	s1,8(sp)
    80004e74:	6902                	ld	s2,0(sp)
    80004e76:	6105                	addi	sp,sp,32
    80004e78:	8082                	ret
    pi->readopen = 0;
    80004e7a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e7e:	21c48513          	addi	a0,s1,540
    80004e82:	ffffd097          	auipc	ra,0xffffd
    80004e86:	7f0080e7          	jalr	2032(ra) # 80002672 <wakeup>
    80004e8a:	b7e9                	j	80004e54 <pipeclose+0x2c>
    release(&pi->lock);
    80004e8c:	8526                	mv	a0,s1
    80004e8e:	ffffc097          	auipc	ra,0xffffc
    80004e92:	e0a080e7          	jalr	-502(ra) # 80000c98 <release>
}
    80004e96:	bfe1                	j	80004e6e <pipeclose+0x46>

0000000080004e98 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e98:	7159                	addi	sp,sp,-112
    80004e9a:	f486                	sd	ra,104(sp)
    80004e9c:	f0a2                	sd	s0,96(sp)
    80004e9e:	eca6                	sd	s1,88(sp)
    80004ea0:	e8ca                	sd	s2,80(sp)
    80004ea2:	e4ce                	sd	s3,72(sp)
    80004ea4:	e0d2                	sd	s4,64(sp)
    80004ea6:	fc56                	sd	s5,56(sp)
    80004ea8:	f85a                	sd	s6,48(sp)
    80004eaa:	f45e                	sd	s7,40(sp)
    80004eac:	f062                	sd	s8,32(sp)
    80004eae:	ec66                	sd	s9,24(sp)
    80004eb0:	1880                	addi	s0,sp,112
    80004eb2:	84aa                	mv	s1,a0
    80004eb4:	8aae                	mv	s5,a1
    80004eb6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004eb8:	ffffd097          	auipc	ra,0xffffd
    80004ebc:	e16080e7          	jalr	-490(ra) # 80001cce <myproc>
    80004ec0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ec2:	8526                	mv	a0,s1
    80004ec4:	ffffc097          	auipc	ra,0xffffc
    80004ec8:	d20080e7          	jalr	-736(ra) # 80000be4 <acquire>
  while(i < n){
    80004ecc:	0d405163          	blez	s4,80004f8e <pipewrite+0xf6>
    80004ed0:	8ba6                	mv	s7,s1
  int i = 0;
    80004ed2:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ed4:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ed6:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004eda:	21c48c13          	addi	s8,s1,540
    80004ede:	a08d                	j	80004f40 <pipewrite+0xa8>
      release(&pi->lock);
    80004ee0:	8526                	mv	a0,s1
    80004ee2:	ffffc097          	auipc	ra,0xffffc
    80004ee6:	db6080e7          	jalr	-586(ra) # 80000c98 <release>
      return -1;
    80004eea:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004eec:	854a                	mv	a0,s2
    80004eee:	70a6                	ld	ra,104(sp)
    80004ef0:	7406                	ld	s0,96(sp)
    80004ef2:	64e6                	ld	s1,88(sp)
    80004ef4:	6946                	ld	s2,80(sp)
    80004ef6:	69a6                	ld	s3,72(sp)
    80004ef8:	6a06                	ld	s4,64(sp)
    80004efa:	7ae2                	ld	s5,56(sp)
    80004efc:	7b42                	ld	s6,48(sp)
    80004efe:	7ba2                	ld	s7,40(sp)
    80004f00:	7c02                	ld	s8,32(sp)
    80004f02:	6ce2                	ld	s9,24(sp)
    80004f04:	6165                	addi	sp,sp,112
    80004f06:	8082                	ret
      wakeup(&pi->nread);
    80004f08:	8566                	mv	a0,s9
    80004f0a:	ffffd097          	auipc	ra,0xffffd
    80004f0e:	768080e7          	jalr	1896(ra) # 80002672 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f12:	85de                	mv	a1,s7
    80004f14:	8562                	mv	a0,s8
    80004f16:	ffffd097          	auipc	ra,0xffffd
    80004f1a:	5be080e7          	jalr	1470(ra) # 800024d4 <sleep>
    80004f1e:	a839                	j	80004f3c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f20:	21c4a783          	lw	a5,540(s1)
    80004f24:	0017871b          	addiw	a4,a5,1
    80004f28:	20e4ae23          	sw	a4,540(s1)
    80004f2c:	1ff7f793          	andi	a5,a5,511
    80004f30:	97a6                	add	a5,a5,s1
    80004f32:	f9f44703          	lbu	a4,-97(s0)
    80004f36:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f3a:	2905                	addiw	s2,s2,1
  while(i < n){
    80004f3c:	03495d63          	bge	s2,s4,80004f76 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004f40:	2204a783          	lw	a5,544(s1)
    80004f44:	dfd1                	beqz	a5,80004ee0 <pipewrite+0x48>
    80004f46:	0289a783          	lw	a5,40(s3)
    80004f4a:	fbd9                	bnez	a5,80004ee0 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f4c:	2184a783          	lw	a5,536(s1)
    80004f50:	21c4a703          	lw	a4,540(s1)
    80004f54:	2007879b          	addiw	a5,a5,512
    80004f58:	faf708e3          	beq	a4,a5,80004f08 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f5c:	4685                	li	a3,1
    80004f5e:	01590633          	add	a2,s2,s5
    80004f62:	f9f40593          	addi	a1,s0,-97
    80004f66:	0509b503          	ld	a0,80(s3)
    80004f6a:	ffffc097          	auipc	ra,0xffffc
    80004f6e:	794080e7          	jalr	1940(ra) # 800016fe <copyin>
    80004f72:	fb6517e3          	bne	a0,s6,80004f20 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004f76:	21848513          	addi	a0,s1,536
    80004f7a:	ffffd097          	auipc	ra,0xffffd
    80004f7e:	6f8080e7          	jalr	1784(ra) # 80002672 <wakeup>
  release(&pi->lock);
    80004f82:	8526                	mv	a0,s1
    80004f84:	ffffc097          	auipc	ra,0xffffc
    80004f88:	d14080e7          	jalr	-748(ra) # 80000c98 <release>
  return i;
    80004f8c:	b785                	j	80004eec <pipewrite+0x54>
  int i = 0;
    80004f8e:	4901                	li	s2,0
    80004f90:	b7dd                	j	80004f76 <pipewrite+0xde>

0000000080004f92 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f92:	715d                	addi	sp,sp,-80
    80004f94:	e486                	sd	ra,72(sp)
    80004f96:	e0a2                	sd	s0,64(sp)
    80004f98:	fc26                	sd	s1,56(sp)
    80004f9a:	f84a                	sd	s2,48(sp)
    80004f9c:	f44e                	sd	s3,40(sp)
    80004f9e:	f052                	sd	s4,32(sp)
    80004fa0:	ec56                	sd	s5,24(sp)
    80004fa2:	e85a                	sd	s6,16(sp)
    80004fa4:	0880                	addi	s0,sp,80
    80004fa6:	84aa                	mv	s1,a0
    80004fa8:	892e                	mv	s2,a1
    80004faa:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004fac:	ffffd097          	auipc	ra,0xffffd
    80004fb0:	d22080e7          	jalr	-734(ra) # 80001cce <myproc>
    80004fb4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004fb6:	8b26                	mv	s6,s1
    80004fb8:	8526                	mv	a0,s1
    80004fba:	ffffc097          	auipc	ra,0xffffc
    80004fbe:	c2a080e7          	jalr	-982(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fc2:	2184a703          	lw	a4,536(s1)
    80004fc6:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fca:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fce:	02f71463          	bne	a4,a5,80004ff6 <piperead+0x64>
    80004fd2:	2244a783          	lw	a5,548(s1)
    80004fd6:	c385                	beqz	a5,80004ff6 <piperead+0x64>
    if(pr->killed){
    80004fd8:	028a2783          	lw	a5,40(s4)
    80004fdc:	ebc1                	bnez	a5,8000506c <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fde:	85da                	mv	a1,s6
    80004fe0:	854e                	mv	a0,s3
    80004fe2:	ffffd097          	auipc	ra,0xffffd
    80004fe6:	4f2080e7          	jalr	1266(ra) # 800024d4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fea:	2184a703          	lw	a4,536(s1)
    80004fee:	21c4a783          	lw	a5,540(s1)
    80004ff2:	fef700e3          	beq	a4,a5,80004fd2 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ff6:	09505263          	blez	s5,8000507a <piperead+0xe8>
    80004ffa:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ffc:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004ffe:	2184a783          	lw	a5,536(s1)
    80005002:	21c4a703          	lw	a4,540(s1)
    80005006:	02f70d63          	beq	a4,a5,80005040 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000500a:	0017871b          	addiw	a4,a5,1
    8000500e:	20e4ac23          	sw	a4,536(s1)
    80005012:	1ff7f793          	andi	a5,a5,511
    80005016:	97a6                	add	a5,a5,s1
    80005018:	0187c783          	lbu	a5,24(a5)
    8000501c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005020:	4685                	li	a3,1
    80005022:	fbf40613          	addi	a2,s0,-65
    80005026:	85ca                	mv	a1,s2
    80005028:	050a3503          	ld	a0,80(s4)
    8000502c:	ffffc097          	auipc	ra,0xffffc
    80005030:	646080e7          	jalr	1606(ra) # 80001672 <copyout>
    80005034:	01650663          	beq	a0,s6,80005040 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005038:	2985                	addiw	s3,s3,1
    8000503a:	0905                	addi	s2,s2,1
    8000503c:	fd3a91e3          	bne	s5,s3,80004ffe <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005040:	21c48513          	addi	a0,s1,540
    80005044:	ffffd097          	auipc	ra,0xffffd
    80005048:	62e080e7          	jalr	1582(ra) # 80002672 <wakeup>
  release(&pi->lock);
    8000504c:	8526                	mv	a0,s1
    8000504e:	ffffc097          	auipc	ra,0xffffc
    80005052:	c4a080e7          	jalr	-950(ra) # 80000c98 <release>
  return i;
}
    80005056:	854e                	mv	a0,s3
    80005058:	60a6                	ld	ra,72(sp)
    8000505a:	6406                	ld	s0,64(sp)
    8000505c:	74e2                	ld	s1,56(sp)
    8000505e:	7942                	ld	s2,48(sp)
    80005060:	79a2                	ld	s3,40(sp)
    80005062:	7a02                	ld	s4,32(sp)
    80005064:	6ae2                	ld	s5,24(sp)
    80005066:	6b42                	ld	s6,16(sp)
    80005068:	6161                	addi	sp,sp,80
    8000506a:	8082                	ret
      release(&pi->lock);
    8000506c:	8526                	mv	a0,s1
    8000506e:	ffffc097          	auipc	ra,0xffffc
    80005072:	c2a080e7          	jalr	-982(ra) # 80000c98 <release>
      return -1;
    80005076:	59fd                	li	s3,-1
    80005078:	bff9                	j	80005056 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000507a:	4981                	li	s3,0
    8000507c:	b7d1                	j	80005040 <piperead+0xae>

000000008000507e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000507e:	df010113          	addi	sp,sp,-528
    80005082:	20113423          	sd	ra,520(sp)
    80005086:	20813023          	sd	s0,512(sp)
    8000508a:	ffa6                	sd	s1,504(sp)
    8000508c:	fbca                	sd	s2,496(sp)
    8000508e:	f7ce                	sd	s3,488(sp)
    80005090:	f3d2                	sd	s4,480(sp)
    80005092:	efd6                	sd	s5,472(sp)
    80005094:	ebda                	sd	s6,464(sp)
    80005096:	e7de                	sd	s7,456(sp)
    80005098:	e3e2                	sd	s8,448(sp)
    8000509a:	ff66                	sd	s9,440(sp)
    8000509c:	fb6a                	sd	s10,432(sp)
    8000509e:	f76e                	sd	s11,424(sp)
    800050a0:	0c00                	addi	s0,sp,528
    800050a2:	84aa                	mv	s1,a0
    800050a4:	dea43c23          	sd	a0,-520(s0)
    800050a8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050ac:	ffffd097          	auipc	ra,0xffffd
    800050b0:	c22080e7          	jalr	-990(ra) # 80001cce <myproc>
    800050b4:	892a                	mv	s2,a0

  begin_op();
    800050b6:	fffff097          	auipc	ra,0xfffff
    800050ba:	49c080e7          	jalr	1180(ra) # 80004552 <begin_op>

  if((ip = namei(path)) == 0){
    800050be:	8526                	mv	a0,s1
    800050c0:	fffff097          	auipc	ra,0xfffff
    800050c4:	276080e7          	jalr	630(ra) # 80004336 <namei>
    800050c8:	c92d                	beqz	a0,8000513a <exec+0xbc>
    800050ca:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800050cc:	fffff097          	auipc	ra,0xfffff
    800050d0:	ab4080e7          	jalr	-1356(ra) # 80003b80 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050d4:	04000713          	li	a4,64
    800050d8:	4681                	li	a3,0
    800050da:	e5040613          	addi	a2,s0,-432
    800050de:	4581                	li	a1,0
    800050e0:	8526                	mv	a0,s1
    800050e2:	fffff097          	auipc	ra,0xfffff
    800050e6:	d52080e7          	jalr	-686(ra) # 80003e34 <readi>
    800050ea:	04000793          	li	a5,64
    800050ee:	00f51a63          	bne	a0,a5,80005102 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800050f2:	e5042703          	lw	a4,-432(s0)
    800050f6:	464c47b7          	lui	a5,0x464c4
    800050fa:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800050fe:	04f70463          	beq	a4,a5,80005146 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005102:	8526                	mv	a0,s1
    80005104:	fffff097          	auipc	ra,0xfffff
    80005108:	cde080e7          	jalr	-802(ra) # 80003de2 <iunlockput>
    end_op();
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	4c6080e7          	jalr	1222(ra) # 800045d2 <end_op>
  }
  return -1;
    80005114:	557d                	li	a0,-1
}
    80005116:	20813083          	ld	ra,520(sp)
    8000511a:	20013403          	ld	s0,512(sp)
    8000511e:	74fe                	ld	s1,504(sp)
    80005120:	795e                	ld	s2,496(sp)
    80005122:	79be                	ld	s3,488(sp)
    80005124:	7a1e                	ld	s4,480(sp)
    80005126:	6afe                	ld	s5,472(sp)
    80005128:	6b5e                	ld	s6,464(sp)
    8000512a:	6bbe                	ld	s7,456(sp)
    8000512c:	6c1e                	ld	s8,448(sp)
    8000512e:	7cfa                	ld	s9,440(sp)
    80005130:	7d5a                	ld	s10,432(sp)
    80005132:	7dba                	ld	s11,424(sp)
    80005134:	21010113          	addi	sp,sp,528
    80005138:	8082                	ret
    end_op();
    8000513a:	fffff097          	auipc	ra,0xfffff
    8000513e:	498080e7          	jalr	1176(ra) # 800045d2 <end_op>
    return -1;
    80005142:	557d                	li	a0,-1
    80005144:	bfc9                	j	80005116 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005146:	854a                	mv	a0,s2
    80005148:	ffffd097          	auipc	ra,0xffffd
    8000514c:	c44080e7          	jalr	-956(ra) # 80001d8c <proc_pagetable>
    80005150:	8baa                	mv	s7,a0
    80005152:	d945                	beqz	a0,80005102 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005154:	e7042983          	lw	s3,-400(s0)
    80005158:	e8845783          	lhu	a5,-376(s0)
    8000515c:	c7ad                	beqz	a5,800051c6 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000515e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005160:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005162:	6c85                	lui	s9,0x1
    80005164:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005168:	def43823          	sd	a5,-528(s0)
    8000516c:	a42d                	j	80005396 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000516e:	00003517          	auipc	a0,0x3
    80005172:	5e250513          	addi	a0,a0,1506 # 80008750 <syscalls+0x280>
    80005176:	ffffb097          	auipc	ra,0xffffb
    8000517a:	3c8080e7          	jalr	968(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000517e:	8756                	mv	a4,s5
    80005180:	012d86bb          	addw	a3,s11,s2
    80005184:	4581                	li	a1,0
    80005186:	8526                	mv	a0,s1
    80005188:	fffff097          	auipc	ra,0xfffff
    8000518c:	cac080e7          	jalr	-852(ra) # 80003e34 <readi>
    80005190:	2501                	sext.w	a0,a0
    80005192:	1aaa9963          	bne	s5,a0,80005344 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005196:	6785                	lui	a5,0x1
    80005198:	0127893b          	addw	s2,a5,s2
    8000519c:	77fd                	lui	a5,0xfffff
    8000519e:	01478a3b          	addw	s4,a5,s4
    800051a2:	1f897163          	bgeu	s2,s8,80005384 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800051a6:	02091593          	slli	a1,s2,0x20
    800051aa:	9181                	srli	a1,a1,0x20
    800051ac:	95ea                	add	a1,a1,s10
    800051ae:	855e                	mv	a0,s7
    800051b0:	ffffc097          	auipc	ra,0xffffc
    800051b4:	ebe080e7          	jalr	-322(ra) # 8000106e <walkaddr>
    800051b8:	862a                	mv	a2,a0
    if(pa == 0)
    800051ba:	d955                	beqz	a0,8000516e <exec+0xf0>
      n = PGSIZE;
    800051bc:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800051be:	fd9a70e3          	bgeu	s4,s9,8000517e <exec+0x100>
      n = sz - i;
    800051c2:	8ad2                	mv	s5,s4
    800051c4:	bf6d                	j	8000517e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051c6:	4901                	li	s2,0
  iunlockput(ip);
    800051c8:	8526                	mv	a0,s1
    800051ca:	fffff097          	auipc	ra,0xfffff
    800051ce:	c18080e7          	jalr	-1000(ra) # 80003de2 <iunlockput>
  end_op();
    800051d2:	fffff097          	auipc	ra,0xfffff
    800051d6:	400080e7          	jalr	1024(ra) # 800045d2 <end_op>
  p = myproc();
    800051da:	ffffd097          	auipc	ra,0xffffd
    800051de:	af4080e7          	jalr	-1292(ra) # 80001cce <myproc>
    800051e2:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800051e4:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800051e8:	6785                	lui	a5,0x1
    800051ea:	17fd                	addi	a5,a5,-1
    800051ec:	993e                	add	s2,s2,a5
    800051ee:	757d                	lui	a0,0xfffff
    800051f0:	00a977b3          	and	a5,s2,a0
    800051f4:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051f8:	6609                	lui	a2,0x2
    800051fa:	963e                	add	a2,a2,a5
    800051fc:	85be                	mv	a1,a5
    800051fe:	855e                	mv	a0,s7
    80005200:	ffffc097          	auipc	ra,0xffffc
    80005204:	222080e7          	jalr	546(ra) # 80001422 <uvmalloc>
    80005208:	8b2a                	mv	s6,a0
  ip = 0;
    8000520a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000520c:	12050c63          	beqz	a0,80005344 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005210:	75f9                	lui	a1,0xffffe
    80005212:	95aa                	add	a1,a1,a0
    80005214:	855e                	mv	a0,s7
    80005216:	ffffc097          	auipc	ra,0xffffc
    8000521a:	42a080e7          	jalr	1066(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    8000521e:	7c7d                	lui	s8,0xfffff
    80005220:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005222:	e0043783          	ld	a5,-512(s0)
    80005226:	6388                	ld	a0,0(a5)
    80005228:	c535                	beqz	a0,80005294 <exec+0x216>
    8000522a:	e9040993          	addi	s3,s0,-368
    8000522e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005232:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005234:	ffffc097          	auipc	ra,0xffffc
    80005238:	c30080e7          	jalr	-976(ra) # 80000e64 <strlen>
    8000523c:	2505                	addiw	a0,a0,1
    8000523e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005242:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005246:	13896363          	bltu	s2,s8,8000536c <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000524a:	e0043d83          	ld	s11,-512(s0)
    8000524e:	000dba03          	ld	s4,0(s11)
    80005252:	8552                	mv	a0,s4
    80005254:	ffffc097          	auipc	ra,0xffffc
    80005258:	c10080e7          	jalr	-1008(ra) # 80000e64 <strlen>
    8000525c:	0015069b          	addiw	a3,a0,1
    80005260:	8652                	mv	a2,s4
    80005262:	85ca                	mv	a1,s2
    80005264:	855e                	mv	a0,s7
    80005266:	ffffc097          	auipc	ra,0xffffc
    8000526a:	40c080e7          	jalr	1036(ra) # 80001672 <copyout>
    8000526e:	10054363          	bltz	a0,80005374 <exec+0x2f6>
    ustack[argc] = sp;
    80005272:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005276:	0485                	addi	s1,s1,1
    80005278:	008d8793          	addi	a5,s11,8
    8000527c:	e0f43023          	sd	a5,-512(s0)
    80005280:	008db503          	ld	a0,8(s11)
    80005284:	c911                	beqz	a0,80005298 <exec+0x21a>
    if(argc >= MAXARG)
    80005286:	09a1                	addi	s3,s3,8
    80005288:	fb3c96e3          	bne	s9,s3,80005234 <exec+0x1b6>
  sz = sz1;
    8000528c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005290:	4481                	li	s1,0
    80005292:	a84d                	j	80005344 <exec+0x2c6>
  sp = sz;
    80005294:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005296:	4481                	li	s1,0
  ustack[argc] = 0;
    80005298:	00349793          	slli	a5,s1,0x3
    8000529c:	f9040713          	addi	a4,s0,-112
    800052a0:	97ba                	add	a5,a5,a4
    800052a2:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800052a6:	00148693          	addi	a3,s1,1
    800052aa:	068e                	slli	a3,a3,0x3
    800052ac:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800052b0:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800052b4:	01897663          	bgeu	s2,s8,800052c0 <exec+0x242>
  sz = sz1;
    800052b8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052bc:	4481                	li	s1,0
    800052be:	a059                	j	80005344 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800052c0:	e9040613          	addi	a2,s0,-368
    800052c4:	85ca                	mv	a1,s2
    800052c6:	855e                	mv	a0,s7
    800052c8:	ffffc097          	auipc	ra,0xffffc
    800052cc:	3aa080e7          	jalr	938(ra) # 80001672 <copyout>
    800052d0:	0a054663          	bltz	a0,8000537c <exec+0x2fe>
  p->trapframe->a1 = sp;
    800052d4:	058ab783          	ld	a5,88(s5)
    800052d8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800052dc:	df843783          	ld	a5,-520(s0)
    800052e0:	0007c703          	lbu	a4,0(a5)
    800052e4:	cf11                	beqz	a4,80005300 <exec+0x282>
    800052e6:	0785                	addi	a5,a5,1
    if(*s == '/')
    800052e8:	02f00693          	li	a3,47
    800052ec:	a039                	j	800052fa <exec+0x27c>
      last = s+1;
    800052ee:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800052f2:	0785                	addi	a5,a5,1
    800052f4:	fff7c703          	lbu	a4,-1(a5)
    800052f8:	c701                	beqz	a4,80005300 <exec+0x282>
    if(*s == '/')
    800052fa:	fed71ce3          	bne	a4,a3,800052f2 <exec+0x274>
    800052fe:	bfc5                	j	800052ee <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005300:	4641                	li	a2,16
    80005302:	df843583          	ld	a1,-520(s0)
    80005306:	158a8513          	addi	a0,s5,344
    8000530a:	ffffc097          	auipc	ra,0xffffc
    8000530e:	b28080e7          	jalr	-1240(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005312:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005316:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000531a:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000531e:	058ab783          	ld	a5,88(s5)
    80005322:	e6843703          	ld	a4,-408(s0)
    80005326:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005328:	058ab783          	ld	a5,88(s5)
    8000532c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005330:	85ea                	mv	a1,s10
    80005332:	ffffd097          	auipc	ra,0xffffd
    80005336:	af6080e7          	jalr	-1290(ra) # 80001e28 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000533a:	0004851b          	sext.w	a0,s1
    8000533e:	bbe1                	j	80005116 <exec+0x98>
    80005340:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005344:	e0843583          	ld	a1,-504(s0)
    80005348:	855e                	mv	a0,s7
    8000534a:	ffffd097          	auipc	ra,0xffffd
    8000534e:	ade080e7          	jalr	-1314(ra) # 80001e28 <proc_freepagetable>
  if(ip){
    80005352:	da0498e3          	bnez	s1,80005102 <exec+0x84>
  return -1;
    80005356:	557d                	li	a0,-1
    80005358:	bb7d                	j	80005116 <exec+0x98>
    8000535a:	e1243423          	sd	s2,-504(s0)
    8000535e:	b7dd                	j	80005344 <exec+0x2c6>
    80005360:	e1243423          	sd	s2,-504(s0)
    80005364:	b7c5                	j	80005344 <exec+0x2c6>
    80005366:	e1243423          	sd	s2,-504(s0)
    8000536a:	bfe9                	j	80005344 <exec+0x2c6>
  sz = sz1;
    8000536c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005370:	4481                	li	s1,0
    80005372:	bfc9                	j	80005344 <exec+0x2c6>
  sz = sz1;
    80005374:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005378:	4481                	li	s1,0
    8000537a:	b7e9                	j	80005344 <exec+0x2c6>
  sz = sz1;
    8000537c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005380:	4481                	li	s1,0
    80005382:	b7c9                	j	80005344 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005384:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005388:	2b05                	addiw	s6,s6,1
    8000538a:	0389899b          	addiw	s3,s3,56
    8000538e:	e8845783          	lhu	a5,-376(s0)
    80005392:	e2fb5be3          	bge	s6,a5,800051c8 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005396:	2981                	sext.w	s3,s3
    80005398:	03800713          	li	a4,56
    8000539c:	86ce                	mv	a3,s3
    8000539e:	e1840613          	addi	a2,s0,-488
    800053a2:	4581                	li	a1,0
    800053a4:	8526                	mv	a0,s1
    800053a6:	fffff097          	auipc	ra,0xfffff
    800053aa:	a8e080e7          	jalr	-1394(ra) # 80003e34 <readi>
    800053ae:	03800793          	li	a5,56
    800053b2:	f8f517e3          	bne	a0,a5,80005340 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800053b6:	e1842783          	lw	a5,-488(s0)
    800053ba:	4705                	li	a4,1
    800053bc:	fce796e3          	bne	a5,a4,80005388 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800053c0:	e4043603          	ld	a2,-448(s0)
    800053c4:	e3843783          	ld	a5,-456(s0)
    800053c8:	f8f669e3          	bltu	a2,a5,8000535a <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053cc:	e2843783          	ld	a5,-472(s0)
    800053d0:	963e                	add	a2,a2,a5
    800053d2:	f8f667e3          	bltu	a2,a5,80005360 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053d6:	85ca                	mv	a1,s2
    800053d8:	855e                	mv	a0,s7
    800053da:	ffffc097          	auipc	ra,0xffffc
    800053de:	048080e7          	jalr	72(ra) # 80001422 <uvmalloc>
    800053e2:	e0a43423          	sd	a0,-504(s0)
    800053e6:	d141                	beqz	a0,80005366 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800053e8:	e2843d03          	ld	s10,-472(s0)
    800053ec:	df043783          	ld	a5,-528(s0)
    800053f0:	00fd77b3          	and	a5,s10,a5
    800053f4:	fba1                	bnez	a5,80005344 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053f6:	e2042d83          	lw	s11,-480(s0)
    800053fa:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053fe:	f80c03e3          	beqz	s8,80005384 <exec+0x306>
    80005402:	8a62                	mv	s4,s8
    80005404:	4901                	li	s2,0
    80005406:	b345                	j	800051a6 <exec+0x128>

0000000080005408 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005408:	7179                	addi	sp,sp,-48
    8000540a:	f406                	sd	ra,40(sp)
    8000540c:	f022                	sd	s0,32(sp)
    8000540e:	ec26                	sd	s1,24(sp)
    80005410:	e84a                	sd	s2,16(sp)
    80005412:	1800                	addi	s0,sp,48
    80005414:	892e                	mv	s2,a1
    80005416:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005418:	fdc40593          	addi	a1,s0,-36
    8000541c:	ffffe097          	auipc	ra,0xffffe
    80005420:	bf2080e7          	jalr	-1038(ra) # 8000300e <argint>
    80005424:	04054063          	bltz	a0,80005464 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005428:	fdc42703          	lw	a4,-36(s0)
    8000542c:	47bd                	li	a5,15
    8000542e:	02e7ed63          	bltu	a5,a4,80005468 <argfd+0x60>
    80005432:	ffffd097          	auipc	ra,0xffffd
    80005436:	89c080e7          	jalr	-1892(ra) # 80001cce <myproc>
    8000543a:	fdc42703          	lw	a4,-36(s0)
    8000543e:	01a70793          	addi	a5,a4,26
    80005442:	078e                	slli	a5,a5,0x3
    80005444:	953e                	add	a0,a0,a5
    80005446:	611c                	ld	a5,0(a0)
    80005448:	c395                	beqz	a5,8000546c <argfd+0x64>
    return -1;
  if(pfd)
    8000544a:	00090463          	beqz	s2,80005452 <argfd+0x4a>
    *pfd = fd;
    8000544e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005452:	4501                	li	a0,0
  if(pf)
    80005454:	c091                	beqz	s1,80005458 <argfd+0x50>
    *pf = f;
    80005456:	e09c                	sd	a5,0(s1)
}
    80005458:	70a2                	ld	ra,40(sp)
    8000545a:	7402                	ld	s0,32(sp)
    8000545c:	64e2                	ld	s1,24(sp)
    8000545e:	6942                	ld	s2,16(sp)
    80005460:	6145                	addi	sp,sp,48
    80005462:	8082                	ret
    return -1;
    80005464:	557d                	li	a0,-1
    80005466:	bfcd                	j	80005458 <argfd+0x50>
    return -1;
    80005468:	557d                	li	a0,-1
    8000546a:	b7fd                	j	80005458 <argfd+0x50>
    8000546c:	557d                	li	a0,-1
    8000546e:	b7ed                	j	80005458 <argfd+0x50>

0000000080005470 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005470:	1101                	addi	sp,sp,-32
    80005472:	ec06                	sd	ra,24(sp)
    80005474:	e822                	sd	s0,16(sp)
    80005476:	e426                	sd	s1,8(sp)
    80005478:	1000                	addi	s0,sp,32
    8000547a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000547c:	ffffd097          	auipc	ra,0xffffd
    80005480:	852080e7          	jalr	-1966(ra) # 80001cce <myproc>
    80005484:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005486:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000548a:	4501                	li	a0,0
    8000548c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000548e:	6398                	ld	a4,0(a5)
    80005490:	cb19                	beqz	a4,800054a6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005492:	2505                	addiw	a0,a0,1
    80005494:	07a1                	addi	a5,a5,8
    80005496:	fed51ce3          	bne	a0,a3,8000548e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000549a:	557d                	li	a0,-1
}
    8000549c:	60e2                	ld	ra,24(sp)
    8000549e:	6442                	ld	s0,16(sp)
    800054a0:	64a2                	ld	s1,8(sp)
    800054a2:	6105                	addi	sp,sp,32
    800054a4:	8082                	ret
      p->ofile[fd] = f;
    800054a6:	01a50793          	addi	a5,a0,26
    800054aa:	078e                	slli	a5,a5,0x3
    800054ac:	963e                	add	a2,a2,a5
    800054ae:	e204                	sd	s1,0(a2)
      return fd;
    800054b0:	b7f5                	j	8000549c <fdalloc+0x2c>

00000000800054b2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054b2:	715d                	addi	sp,sp,-80
    800054b4:	e486                	sd	ra,72(sp)
    800054b6:	e0a2                	sd	s0,64(sp)
    800054b8:	fc26                	sd	s1,56(sp)
    800054ba:	f84a                	sd	s2,48(sp)
    800054bc:	f44e                	sd	s3,40(sp)
    800054be:	f052                	sd	s4,32(sp)
    800054c0:	ec56                	sd	s5,24(sp)
    800054c2:	0880                	addi	s0,sp,80
    800054c4:	89ae                	mv	s3,a1
    800054c6:	8ab2                	mv	s5,a2
    800054c8:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054ca:	fb040593          	addi	a1,s0,-80
    800054ce:	fffff097          	auipc	ra,0xfffff
    800054d2:	e86080e7          	jalr	-378(ra) # 80004354 <nameiparent>
    800054d6:	892a                	mv	s2,a0
    800054d8:	12050f63          	beqz	a0,80005616 <create+0x164>
    return 0;

  ilock(dp);
    800054dc:	ffffe097          	auipc	ra,0xffffe
    800054e0:	6a4080e7          	jalr	1700(ra) # 80003b80 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054e4:	4601                	li	a2,0
    800054e6:	fb040593          	addi	a1,s0,-80
    800054ea:	854a                	mv	a0,s2
    800054ec:	fffff097          	auipc	ra,0xfffff
    800054f0:	b78080e7          	jalr	-1160(ra) # 80004064 <dirlookup>
    800054f4:	84aa                	mv	s1,a0
    800054f6:	c921                	beqz	a0,80005546 <create+0x94>
    iunlockput(dp);
    800054f8:	854a                	mv	a0,s2
    800054fa:	fffff097          	auipc	ra,0xfffff
    800054fe:	8e8080e7          	jalr	-1816(ra) # 80003de2 <iunlockput>
    ilock(ip);
    80005502:	8526                	mv	a0,s1
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	67c080e7          	jalr	1660(ra) # 80003b80 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000550c:	2981                	sext.w	s3,s3
    8000550e:	4789                	li	a5,2
    80005510:	02f99463          	bne	s3,a5,80005538 <create+0x86>
    80005514:	0444d783          	lhu	a5,68(s1)
    80005518:	37f9                	addiw	a5,a5,-2
    8000551a:	17c2                	slli	a5,a5,0x30
    8000551c:	93c1                	srli	a5,a5,0x30
    8000551e:	4705                	li	a4,1
    80005520:	00f76c63          	bltu	a4,a5,80005538 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005524:	8526                	mv	a0,s1
    80005526:	60a6                	ld	ra,72(sp)
    80005528:	6406                	ld	s0,64(sp)
    8000552a:	74e2                	ld	s1,56(sp)
    8000552c:	7942                	ld	s2,48(sp)
    8000552e:	79a2                	ld	s3,40(sp)
    80005530:	7a02                	ld	s4,32(sp)
    80005532:	6ae2                	ld	s5,24(sp)
    80005534:	6161                	addi	sp,sp,80
    80005536:	8082                	ret
    iunlockput(ip);
    80005538:	8526                	mv	a0,s1
    8000553a:	fffff097          	auipc	ra,0xfffff
    8000553e:	8a8080e7          	jalr	-1880(ra) # 80003de2 <iunlockput>
    return 0;
    80005542:	4481                	li	s1,0
    80005544:	b7c5                	j	80005524 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005546:	85ce                	mv	a1,s3
    80005548:	00092503          	lw	a0,0(s2)
    8000554c:	ffffe097          	auipc	ra,0xffffe
    80005550:	49c080e7          	jalr	1180(ra) # 800039e8 <ialloc>
    80005554:	84aa                	mv	s1,a0
    80005556:	c529                	beqz	a0,800055a0 <create+0xee>
  ilock(ip);
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	628080e7          	jalr	1576(ra) # 80003b80 <ilock>
  ip->major = major;
    80005560:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005564:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005568:	4785                	li	a5,1
    8000556a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000556e:	8526                	mv	a0,s1
    80005570:	ffffe097          	auipc	ra,0xffffe
    80005574:	546080e7          	jalr	1350(ra) # 80003ab6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005578:	2981                	sext.w	s3,s3
    8000557a:	4785                	li	a5,1
    8000557c:	02f98a63          	beq	s3,a5,800055b0 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005580:	40d0                	lw	a2,4(s1)
    80005582:	fb040593          	addi	a1,s0,-80
    80005586:	854a                	mv	a0,s2
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	cec080e7          	jalr	-788(ra) # 80004274 <dirlink>
    80005590:	06054b63          	bltz	a0,80005606 <create+0x154>
  iunlockput(dp);
    80005594:	854a                	mv	a0,s2
    80005596:	fffff097          	auipc	ra,0xfffff
    8000559a:	84c080e7          	jalr	-1972(ra) # 80003de2 <iunlockput>
  return ip;
    8000559e:	b759                	j	80005524 <create+0x72>
    panic("create: ialloc");
    800055a0:	00003517          	auipc	a0,0x3
    800055a4:	1d050513          	addi	a0,a0,464 # 80008770 <syscalls+0x2a0>
    800055a8:	ffffb097          	auipc	ra,0xffffb
    800055ac:	f96080e7          	jalr	-106(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800055b0:	04a95783          	lhu	a5,74(s2)
    800055b4:	2785                	addiw	a5,a5,1
    800055b6:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800055ba:	854a                	mv	a0,s2
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	4fa080e7          	jalr	1274(ra) # 80003ab6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055c4:	40d0                	lw	a2,4(s1)
    800055c6:	00003597          	auipc	a1,0x3
    800055ca:	1ba58593          	addi	a1,a1,442 # 80008780 <syscalls+0x2b0>
    800055ce:	8526                	mv	a0,s1
    800055d0:	fffff097          	auipc	ra,0xfffff
    800055d4:	ca4080e7          	jalr	-860(ra) # 80004274 <dirlink>
    800055d8:	00054f63          	bltz	a0,800055f6 <create+0x144>
    800055dc:	00492603          	lw	a2,4(s2)
    800055e0:	00003597          	auipc	a1,0x3
    800055e4:	1a858593          	addi	a1,a1,424 # 80008788 <syscalls+0x2b8>
    800055e8:	8526                	mv	a0,s1
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	c8a080e7          	jalr	-886(ra) # 80004274 <dirlink>
    800055f2:	f80557e3          	bgez	a0,80005580 <create+0xce>
      panic("create dots");
    800055f6:	00003517          	auipc	a0,0x3
    800055fa:	19a50513          	addi	a0,a0,410 # 80008790 <syscalls+0x2c0>
    800055fe:	ffffb097          	auipc	ra,0xffffb
    80005602:	f40080e7          	jalr	-192(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005606:	00003517          	auipc	a0,0x3
    8000560a:	19a50513          	addi	a0,a0,410 # 800087a0 <syscalls+0x2d0>
    8000560e:	ffffb097          	auipc	ra,0xffffb
    80005612:	f30080e7          	jalr	-208(ra) # 8000053e <panic>
    return 0;
    80005616:	84aa                	mv	s1,a0
    80005618:	b731                	j	80005524 <create+0x72>

000000008000561a <sys_dup>:
{
    8000561a:	7179                	addi	sp,sp,-48
    8000561c:	f406                	sd	ra,40(sp)
    8000561e:	f022                	sd	s0,32(sp)
    80005620:	ec26                	sd	s1,24(sp)
    80005622:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005624:	fd840613          	addi	a2,s0,-40
    80005628:	4581                	li	a1,0
    8000562a:	4501                	li	a0,0
    8000562c:	00000097          	auipc	ra,0x0
    80005630:	ddc080e7          	jalr	-548(ra) # 80005408 <argfd>
    return -1;
    80005634:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005636:	02054363          	bltz	a0,8000565c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000563a:	fd843503          	ld	a0,-40(s0)
    8000563e:	00000097          	auipc	ra,0x0
    80005642:	e32080e7          	jalr	-462(ra) # 80005470 <fdalloc>
    80005646:	84aa                	mv	s1,a0
    return -1;
    80005648:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000564a:	00054963          	bltz	a0,8000565c <sys_dup+0x42>
  filedup(f);
    8000564e:	fd843503          	ld	a0,-40(s0)
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	37a080e7          	jalr	890(ra) # 800049cc <filedup>
  return fd;
    8000565a:	87a6                	mv	a5,s1
}
    8000565c:	853e                	mv	a0,a5
    8000565e:	70a2                	ld	ra,40(sp)
    80005660:	7402                	ld	s0,32(sp)
    80005662:	64e2                	ld	s1,24(sp)
    80005664:	6145                	addi	sp,sp,48
    80005666:	8082                	ret

0000000080005668 <sys_read>:
{
    80005668:	7179                	addi	sp,sp,-48
    8000566a:	f406                	sd	ra,40(sp)
    8000566c:	f022                	sd	s0,32(sp)
    8000566e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005670:	fe840613          	addi	a2,s0,-24
    80005674:	4581                	li	a1,0
    80005676:	4501                	li	a0,0
    80005678:	00000097          	auipc	ra,0x0
    8000567c:	d90080e7          	jalr	-624(ra) # 80005408 <argfd>
    return -1;
    80005680:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005682:	04054163          	bltz	a0,800056c4 <sys_read+0x5c>
    80005686:	fe440593          	addi	a1,s0,-28
    8000568a:	4509                	li	a0,2
    8000568c:	ffffe097          	auipc	ra,0xffffe
    80005690:	982080e7          	jalr	-1662(ra) # 8000300e <argint>
    return -1;
    80005694:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005696:	02054763          	bltz	a0,800056c4 <sys_read+0x5c>
    8000569a:	fd840593          	addi	a1,s0,-40
    8000569e:	4505                	li	a0,1
    800056a0:	ffffe097          	auipc	ra,0xffffe
    800056a4:	990080e7          	jalr	-1648(ra) # 80003030 <argaddr>
    return -1;
    800056a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056aa:	00054d63          	bltz	a0,800056c4 <sys_read+0x5c>
  return fileread(f, p, n);
    800056ae:	fe442603          	lw	a2,-28(s0)
    800056b2:	fd843583          	ld	a1,-40(s0)
    800056b6:	fe843503          	ld	a0,-24(s0)
    800056ba:	fffff097          	auipc	ra,0xfffff
    800056be:	49e080e7          	jalr	1182(ra) # 80004b58 <fileread>
    800056c2:	87aa                	mv	a5,a0
}
    800056c4:	853e                	mv	a0,a5
    800056c6:	70a2                	ld	ra,40(sp)
    800056c8:	7402                	ld	s0,32(sp)
    800056ca:	6145                	addi	sp,sp,48
    800056cc:	8082                	ret

00000000800056ce <sys_write>:
{
    800056ce:	7179                	addi	sp,sp,-48
    800056d0:	f406                	sd	ra,40(sp)
    800056d2:	f022                	sd	s0,32(sp)
    800056d4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056d6:	fe840613          	addi	a2,s0,-24
    800056da:	4581                	li	a1,0
    800056dc:	4501                	li	a0,0
    800056de:	00000097          	auipc	ra,0x0
    800056e2:	d2a080e7          	jalr	-726(ra) # 80005408 <argfd>
    return -1;
    800056e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056e8:	04054163          	bltz	a0,8000572a <sys_write+0x5c>
    800056ec:	fe440593          	addi	a1,s0,-28
    800056f0:	4509                	li	a0,2
    800056f2:	ffffe097          	auipc	ra,0xffffe
    800056f6:	91c080e7          	jalr	-1764(ra) # 8000300e <argint>
    return -1;
    800056fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056fc:	02054763          	bltz	a0,8000572a <sys_write+0x5c>
    80005700:	fd840593          	addi	a1,s0,-40
    80005704:	4505                	li	a0,1
    80005706:	ffffe097          	auipc	ra,0xffffe
    8000570a:	92a080e7          	jalr	-1750(ra) # 80003030 <argaddr>
    return -1;
    8000570e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005710:	00054d63          	bltz	a0,8000572a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005714:	fe442603          	lw	a2,-28(s0)
    80005718:	fd843583          	ld	a1,-40(s0)
    8000571c:	fe843503          	ld	a0,-24(s0)
    80005720:	fffff097          	auipc	ra,0xfffff
    80005724:	4fa080e7          	jalr	1274(ra) # 80004c1a <filewrite>
    80005728:	87aa                	mv	a5,a0
}
    8000572a:	853e                	mv	a0,a5
    8000572c:	70a2                	ld	ra,40(sp)
    8000572e:	7402                	ld	s0,32(sp)
    80005730:	6145                	addi	sp,sp,48
    80005732:	8082                	ret

0000000080005734 <sys_close>:
{
    80005734:	1101                	addi	sp,sp,-32
    80005736:	ec06                	sd	ra,24(sp)
    80005738:	e822                	sd	s0,16(sp)
    8000573a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000573c:	fe040613          	addi	a2,s0,-32
    80005740:	fec40593          	addi	a1,s0,-20
    80005744:	4501                	li	a0,0
    80005746:	00000097          	auipc	ra,0x0
    8000574a:	cc2080e7          	jalr	-830(ra) # 80005408 <argfd>
    return -1;
    8000574e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005750:	02054463          	bltz	a0,80005778 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005754:	ffffc097          	auipc	ra,0xffffc
    80005758:	57a080e7          	jalr	1402(ra) # 80001cce <myproc>
    8000575c:	fec42783          	lw	a5,-20(s0)
    80005760:	07e9                	addi	a5,a5,26
    80005762:	078e                	slli	a5,a5,0x3
    80005764:	97aa                	add	a5,a5,a0
    80005766:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000576a:	fe043503          	ld	a0,-32(s0)
    8000576e:	fffff097          	auipc	ra,0xfffff
    80005772:	2b0080e7          	jalr	688(ra) # 80004a1e <fileclose>
  return 0;
    80005776:	4781                	li	a5,0
}
    80005778:	853e                	mv	a0,a5
    8000577a:	60e2                	ld	ra,24(sp)
    8000577c:	6442                	ld	s0,16(sp)
    8000577e:	6105                	addi	sp,sp,32
    80005780:	8082                	ret

0000000080005782 <sys_fstat>:
{
    80005782:	1101                	addi	sp,sp,-32
    80005784:	ec06                	sd	ra,24(sp)
    80005786:	e822                	sd	s0,16(sp)
    80005788:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000578a:	fe840613          	addi	a2,s0,-24
    8000578e:	4581                	li	a1,0
    80005790:	4501                	li	a0,0
    80005792:	00000097          	auipc	ra,0x0
    80005796:	c76080e7          	jalr	-906(ra) # 80005408 <argfd>
    return -1;
    8000579a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000579c:	02054563          	bltz	a0,800057c6 <sys_fstat+0x44>
    800057a0:	fe040593          	addi	a1,s0,-32
    800057a4:	4505                	li	a0,1
    800057a6:	ffffe097          	auipc	ra,0xffffe
    800057aa:	88a080e7          	jalr	-1910(ra) # 80003030 <argaddr>
    return -1;
    800057ae:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057b0:	00054b63          	bltz	a0,800057c6 <sys_fstat+0x44>
  return filestat(f, st);
    800057b4:	fe043583          	ld	a1,-32(s0)
    800057b8:	fe843503          	ld	a0,-24(s0)
    800057bc:	fffff097          	auipc	ra,0xfffff
    800057c0:	32a080e7          	jalr	810(ra) # 80004ae6 <filestat>
    800057c4:	87aa                	mv	a5,a0
}
    800057c6:	853e                	mv	a0,a5
    800057c8:	60e2                	ld	ra,24(sp)
    800057ca:	6442                	ld	s0,16(sp)
    800057cc:	6105                	addi	sp,sp,32
    800057ce:	8082                	ret

00000000800057d0 <sys_link>:
{
    800057d0:	7169                	addi	sp,sp,-304
    800057d2:	f606                	sd	ra,296(sp)
    800057d4:	f222                	sd	s0,288(sp)
    800057d6:	ee26                	sd	s1,280(sp)
    800057d8:	ea4a                	sd	s2,272(sp)
    800057da:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057dc:	08000613          	li	a2,128
    800057e0:	ed040593          	addi	a1,s0,-304
    800057e4:	4501                	li	a0,0
    800057e6:	ffffe097          	auipc	ra,0xffffe
    800057ea:	86c080e7          	jalr	-1940(ra) # 80003052 <argstr>
    return -1;
    800057ee:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057f0:	10054e63          	bltz	a0,8000590c <sys_link+0x13c>
    800057f4:	08000613          	li	a2,128
    800057f8:	f5040593          	addi	a1,s0,-176
    800057fc:	4505                	li	a0,1
    800057fe:	ffffe097          	auipc	ra,0xffffe
    80005802:	854080e7          	jalr	-1964(ra) # 80003052 <argstr>
    return -1;
    80005806:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005808:	10054263          	bltz	a0,8000590c <sys_link+0x13c>
  begin_op();
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	d46080e7          	jalr	-698(ra) # 80004552 <begin_op>
  if((ip = namei(old)) == 0){
    80005814:	ed040513          	addi	a0,s0,-304
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	b1e080e7          	jalr	-1250(ra) # 80004336 <namei>
    80005820:	84aa                	mv	s1,a0
    80005822:	c551                	beqz	a0,800058ae <sys_link+0xde>
  ilock(ip);
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	35c080e7          	jalr	860(ra) # 80003b80 <ilock>
  if(ip->type == T_DIR){
    8000582c:	04449703          	lh	a4,68(s1)
    80005830:	4785                	li	a5,1
    80005832:	08f70463          	beq	a4,a5,800058ba <sys_link+0xea>
  ip->nlink++;
    80005836:	04a4d783          	lhu	a5,74(s1)
    8000583a:	2785                	addiw	a5,a5,1
    8000583c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005840:	8526                	mv	a0,s1
    80005842:	ffffe097          	auipc	ra,0xffffe
    80005846:	274080e7          	jalr	628(ra) # 80003ab6 <iupdate>
  iunlock(ip);
    8000584a:	8526                	mv	a0,s1
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	3f6080e7          	jalr	1014(ra) # 80003c42 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005854:	fd040593          	addi	a1,s0,-48
    80005858:	f5040513          	addi	a0,s0,-176
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	af8080e7          	jalr	-1288(ra) # 80004354 <nameiparent>
    80005864:	892a                	mv	s2,a0
    80005866:	c935                	beqz	a0,800058da <sys_link+0x10a>
  ilock(dp);
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	318080e7          	jalr	792(ra) # 80003b80 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005870:	00092703          	lw	a4,0(s2)
    80005874:	409c                	lw	a5,0(s1)
    80005876:	04f71d63          	bne	a4,a5,800058d0 <sys_link+0x100>
    8000587a:	40d0                	lw	a2,4(s1)
    8000587c:	fd040593          	addi	a1,s0,-48
    80005880:	854a                	mv	a0,s2
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	9f2080e7          	jalr	-1550(ra) # 80004274 <dirlink>
    8000588a:	04054363          	bltz	a0,800058d0 <sys_link+0x100>
  iunlockput(dp);
    8000588e:	854a                	mv	a0,s2
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	552080e7          	jalr	1362(ra) # 80003de2 <iunlockput>
  iput(ip);
    80005898:	8526                	mv	a0,s1
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	4a0080e7          	jalr	1184(ra) # 80003d3a <iput>
  end_op();
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	d30080e7          	jalr	-720(ra) # 800045d2 <end_op>
  return 0;
    800058aa:	4781                	li	a5,0
    800058ac:	a085                	j	8000590c <sys_link+0x13c>
    end_op();
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	d24080e7          	jalr	-732(ra) # 800045d2 <end_op>
    return -1;
    800058b6:	57fd                	li	a5,-1
    800058b8:	a891                	j	8000590c <sys_link+0x13c>
    iunlockput(ip);
    800058ba:	8526                	mv	a0,s1
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	526080e7          	jalr	1318(ra) # 80003de2 <iunlockput>
    end_op();
    800058c4:	fffff097          	auipc	ra,0xfffff
    800058c8:	d0e080e7          	jalr	-754(ra) # 800045d2 <end_op>
    return -1;
    800058cc:	57fd                	li	a5,-1
    800058ce:	a83d                	j	8000590c <sys_link+0x13c>
    iunlockput(dp);
    800058d0:	854a                	mv	a0,s2
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	510080e7          	jalr	1296(ra) # 80003de2 <iunlockput>
  ilock(ip);
    800058da:	8526                	mv	a0,s1
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	2a4080e7          	jalr	676(ra) # 80003b80 <ilock>
  ip->nlink--;
    800058e4:	04a4d783          	lhu	a5,74(s1)
    800058e8:	37fd                	addiw	a5,a5,-1
    800058ea:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058ee:	8526                	mv	a0,s1
    800058f0:	ffffe097          	auipc	ra,0xffffe
    800058f4:	1c6080e7          	jalr	454(ra) # 80003ab6 <iupdate>
  iunlockput(ip);
    800058f8:	8526                	mv	a0,s1
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	4e8080e7          	jalr	1256(ra) # 80003de2 <iunlockput>
  end_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	cd0080e7          	jalr	-816(ra) # 800045d2 <end_op>
  return -1;
    8000590a:	57fd                	li	a5,-1
}
    8000590c:	853e                	mv	a0,a5
    8000590e:	70b2                	ld	ra,296(sp)
    80005910:	7412                	ld	s0,288(sp)
    80005912:	64f2                	ld	s1,280(sp)
    80005914:	6952                	ld	s2,272(sp)
    80005916:	6155                	addi	sp,sp,304
    80005918:	8082                	ret

000000008000591a <sys_unlink>:
{
    8000591a:	7151                	addi	sp,sp,-240
    8000591c:	f586                	sd	ra,232(sp)
    8000591e:	f1a2                	sd	s0,224(sp)
    80005920:	eda6                	sd	s1,216(sp)
    80005922:	e9ca                	sd	s2,208(sp)
    80005924:	e5ce                	sd	s3,200(sp)
    80005926:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005928:	08000613          	li	a2,128
    8000592c:	f3040593          	addi	a1,s0,-208
    80005930:	4501                	li	a0,0
    80005932:	ffffd097          	auipc	ra,0xffffd
    80005936:	720080e7          	jalr	1824(ra) # 80003052 <argstr>
    8000593a:	18054163          	bltz	a0,80005abc <sys_unlink+0x1a2>
  begin_op();
    8000593e:	fffff097          	auipc	ra,0xfffff
    80005942:	c14080e7          	jalr	-1004(ra) # 80004552 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005946:	fb040593          	addi	a1,s0,-80
    8000594a:	f3040513          	addi	a0,s0,-208
    8000594e:	fffff097          	auipc	ra,0xfffff
    80005952:	a06080e7          	jalr	-1530(ra) # 80004354 <nameiparent>
    80005956:	84aa                	mv	s1,a0
    80005958:	c979                	beqz	a0,80005a2e <sys_unlink+0x114>
  ilock(dp);
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	226080e7          	jalr	550(ra) # 80003b80 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005962:	00003597          	auipc	a1,0x3
    80005966:	e1e58593          	addi	a1,a1,-482 # 80008780 <syscalls+0x2b0>
    8000596a:	fb040513          	addi	a0,s0,-80
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	6dc080e7          	jalr	1756(ra) # 8000404a <namecmp>
    80005976:	14050a63          	beqz	a0,80005aca <sys_unlink+0x1b0>
    8000597a:	00003597          	auipc	a1,0x3
    8000597e:	e0e58593          	addi	a1,a1,-498 # 80008788 <syscalls+0x2b8>
    80005982:	fb040513          	addi	a0,s0,-80
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	6c4080e7          	jalr	1732(ra) # 8000404a <namecmp>
    8000598e:	12050e63          	beqz	a0,80005aca <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005992:	f2c40613          	addi	a2,s0,-212
    80005996:	fb040593          	addi	a1,s0,-80
    8000599a:	8526                	mv	a0,s1
    8000599c:	ffffe097          	auipc	ra,0xffffe
    800059a0:	6c8080e7          	jalr	1736(ra) # 80004064 <dirlookup>
    800059a4:	892a                	mv	s2,a0
    800059a6:	12050263          	beqz	a0,80005aca <sys_unlink+0x1b0>
  ilock(ip);
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	1d6080e7          	jalr	470(ra) # 80003b80 <ilock>
  if(ip->nlink < 1)
    800059b2:	04a91783          	lh	a5,74(s2)
    800059b6:	08f05263          	blez	a5,80005a3a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059ba:	04491703          	lh	a4,68(s2)
    800059be:	4785                	li	a5,1
    800059c0:	08f70563          	beq	a4,a5,80005a4a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800059c4:	4641                	li	a2,16
    800059c6:	4581                	li	a1,0
    800059c8:	fc040513          	addi	a0,s0,-64
    800059cc:	ffffb097          	auipc	ra,0xffffb
    800059d0:	314080e7          	jalr	788(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059d4:	4741                	li	a4,16
    800059d6:	f2c42683          	lw	a3,-212(s0)
    800059da:	fc040613          	addi	a2,s0,-64
    800059de:	4581                	li	a1,0
    800059e0:	8526                	mv	a0,s1
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	54a080e7          	jalr	1354(ra) # 80003f2c <writei>
    800059ea:	47c1                	li	a5,16
    800059ec:	0af51563          	bne	a0,a5,80005a96 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059f0:	04491703          	lh	a4,68(s2)
    800059f4:	4785                	li	a5,1
    800059f6:	0af70863          	beq	a4,a5,80005aa6 <sys_unlink+0x18c>
  iunlockput(dp);
    800059fa:	8526                	mv	a0,s1
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	3e6080e7          	jalr	998(ra) # 80003de2 <iunlockput>
  ip->nlink--;
    80005a04:	04a95783          	lhu	a5,74(s2)
    80005a08:	37fd                	addiw	a5,a5,-1
    80005a0a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a0e:	854a                	mv	a0,s2
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	0a6080e7          	jalr	166(ra) # 80003ab6 <iupdate>
  iunlockput(ip);
    80005a18:	854a                	mv	a0,s2
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	3c8080e7          	jalr	968(ra) # 80003de2 <iunlockput>
  end_op();
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	bb0080e7          	jalr	-1104(ra) # 800045d2 <end_op>
  return 0;
    80005a2a:	4501                	li	a0,0
    80005a2c:	a84d                	j	80005ade <sys_unlink+0x1c4>
    end_op();
    80005a2e:	fffff097          	auipc	ra,0xfffff
    80005a32:	ba4080e7          	jalr	-1116(ra) # 800045d2 <end_op>
    return -1;
    80005a36:	557d                	li	a0,-1
    80005a38:	a05d                	j	80005ade <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a3a:	00003517          	auipc	a0,0x3
    80005a3e:	d7650513          	addi	a0,a0,-650 # 800087b0 <syscalls+0x2e0>
    80005a42:	ffffb097          	auipc	ra,0xffffb
    80005a46:	afc080e7          	jalr	-1284(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a4a:	04c92703          	lw	a4,76(s2)
    80005a4e:	02000793          	li	a5,32
    80005a52:	f6e7f9e3          	bgeu	a5,a4,800059c4 <sys_unlink+0xaa>
    80005a56:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a5a:	4741                	li	a4,16
    80005a5c:	86ce                	mv	a3,s3
    80005a5e:	f1840613          	addi	a2,s0,-232
    80005a62:	4581                	li	a1,0
    80005a64:	854a                	mv	a0,s2
    80005a66:	ffffe097          	auipc	ra,0xffffe
    80005a6a:	3ce080e7          	jalr	974(ra) # 80003e34 <readi>
    80005a6e:	47c1                	li	a5,16
    80005a70:	00f51b63          	bne	a0,a5,80005a86 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a74:	f1845783          	lhu	a5,-232(s0)
    80005a78:	e7a1                	bnez	a5,80005ac0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a7a:	29c1                	addiw	s3,s3,16
    80005a7c:	04c92783          	lw	a5,76(s2)
    80005a80:	fcf9ede3          	bltu	s3,a5,80005a5a <sys_unlink+0x140>
    80005a84:	b781                	j	800059c4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a86:	00003517          	auipc	a0,0x3
    80005a8a:	d4250513          	addi	a0,a0,-702 # 800087c8 <syscalls+0x2f8>
    80005a8e:	ffffb097          	auipc	ra,0xffffb
    80005a92:	ab0080e7          	jalr	-1360(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005a96:	00003517          	auipc	a0,0x3
    80005a9a:	d4a50513          	addi	a0,a0,-694 # 800087e0 <syscalls+0x310>
    80005a9e:	ffffb097          	auipc	ra,0xffffb
    80005aa2:	aa0080e7          	jalr	-1376(ra) # 8000053e <panic>
    dp->nlink--;
    80005aa6:	04a4d783          	lhu	a5,74(s1)
    80005aaa:	37fd                	addiw	a5,a5,-1
    80005aac:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ab0:	8526                	mv	a0,s1
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	004080e7          	jalr	4(ra) # 80003ab6 <iupdate>
    80005aba:	b781                	j	800059fa <sys_unlink+0xe0>
    return -1;
    80005abc:	557d                	li	a0,-1
    80005abe:	a005                	j	80005ade <sys_unlink+0x1c4>
    iunlockput(ip);
    80005ac0:	854a                	mv	a0,s2
    80005ac2:	ffffe097          	auipc	ra,0xffffe
    80005ac6:	320080e7          	jalr	800(ra) # 80003de2 <iunlockput>
  iunlockput(dp);
    80005aca:	8526                	mv	a0,s1
    80005acc:	ffffe097          	auipc	ra,0xffffe
    80005ad0:	316080e7          	jalr	790(ra) # 80003de2 <iunlockput>
  end_op();
    80005ad4:	fffff097          	auipc	ra,0xfffff
    80005ad8:	afe080e7          	jalr	-1282(ra) # 800045d2 <end_op>
  return -1;
    80005adc:	557d                	li	a0,-1
}
    80005ade:	70ae                	ld	ra,232(sp)
    80005ae0:	740e                	ld	s0,224(sp)
    80005ae2:	64ee                	ld	s1,216(sp)
    80005ae4:	694e                	ld	s2,208(sp)
    80005ae6:	69ae                	ld	s3,200(sp)
    80005ae8:	616d                	addi	sp,sp,240
    80005aea:	8082                	ret

0000000080005aec <sys_open>:

uint64
sys_open(void)
{
    80005aec:	7131                	addi	sp,sp,-192
    80005aee:	fd06                	sd	ra,184(sp)
    80005af0:	f922                	sd	s0,176(sp)
    80005af2:	f526                	sd	s1,168(sp)
    80005af4:	f14a                	sd	s2,160(sp)
    80005af6:	ed4e                	sd	s3,152(sp)
    80005af8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005afa:	08000613          	li	a2,128
    80005afe:	f5040593          	addi	a1,s0,-176
    80005b02:	4501                	li	a0,0
    80005b04:	ffffd097          	auipc	ra,0xffffd
    80005b08:	54e080e7          	jalr	1358(ra) # 80003052 <argstr>
    return -1;
    80005b0c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b0e:	0c054163          	bltz	a0,80005bd0 <sys_open+0xe4>
    80005b12:	f4c40593          	addi	a1,s0,-180
    80005b16:	4505                	li	a0,1
    80005b18:	ffffd097          	auipc	ra,0xffffd
    80005b1c:	4f6080e7          	jalr	1270(ra) # 8000300e <argint>
    80005b20:	0a054863          	bltz	a0,80005bd0 <sys_open+0xe4>

  begin_op();
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	a2e080e7          	jalr	-1490(ra) # 80004552 <begin_op>

  if(omode & O_CREATE){
    80005b2c:	f4c42783          	lw	a5,-180(s0)
    80005b30:	2007f793          	andi	a5,a5,512
    80005b34:	cbdd                	beqz	a5,80005bea <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b36:	4681                	li	a3,0
    80005b38:	4601                	li	a2,0
    80005b3a:	4589                	li	a1,2
    80005b3c:	f5040513          	addi	a0,s0,-176
    80005b40:	00000097          	auipc	ra,0x0
    80005b44:	972080e7          	jalr	-1678(ra) # 800054b2 <create>
    80005b48:	892a                	mv	s2,a0
    if(ip == 0){
    80005b4a:	c959                	beqz	a0,80005be0 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b4c:	04491703          	lh	a4,68(s2)
    80005b50:	478d                	li	a5,3
    80005b52:	00f71763          	bne	a4,a5,80005b60 <sys_open+0x74>
    80005b56:	04695703          	lhu	a4,70(s2)
    80005b5a:	47a5                	li	a5,9
    80005b5c:	0ce7ec63          	bltu	a5,a4,80005c34 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b60:	fffff097          	auipc	ra,0xfffff
    80005b64:	e02080e7          	jalr	-510(ra) # 80004962 <filealloc>
    80005b68:	89aa                	mv	s3,a0
    80005b6a:	10050263          	beqz	a0,80005c6e <sys_open+0x182>
    80005b6e:	00000097          	auipc	ra,0x0
    80005b72:	902080e7          	jalr	-1790(ra) # 80005470 <fdalloc>
    80005b76:	84aa                	mv	s1,a0
    80005b78:	0e054663          	bltz	a0,80005c64 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b7c:	04491703          	lh	a4,68(s2)
    80005b80:	478d                	li	a5,3
    80005b82:	0cf70463          	beq	a4,a5,80005c4a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b86:	4789                	li	a5,2
    80005b88:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b8c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b90:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b94:	f4c42783          	lw	a5,-180(s0)
    80005b98:	0017c713          	xori	a4,a5,1
    80005b9c:	8b05                	andi	a4,a4,1
    80005b9e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ba2:	0037f713          	andi	a4,a5,3
    80005ba6:	00e03733          	snez	a4,a4
    80005baa:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005bae:	4007f793          	andi	a5,a5,1024
    80005bb2:	c791                	beqz	a5,80005bbe <sys_open+0xd2>
    80005bb4:	04491703          	lh	a4,68(s2)
    80005bb8:	4789                	li	a5,2
    80005bba:	08f70f63          	beq	a4,a5,80005c58 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005bbe:	854a                	mv	a0,s2
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	082080e7          	jalr	130(ra) # 80003c42 <iunlock>
  end_op();
    80005bc8:	fffff097          	auipc	ra,0xfffff
    80005bcc:	a0a080e7          	jalr	-1526(ra) # 800045d2 <end_op>

  return fd;
}
    80005bd0:	8526                	mv	a0,s1
    80005bd2:	70ea                	ld	ra,184(sp)
    80005bd4:	744a                	ld	s0,176(sp)
    80005bd6:	74aa                	ld	s1,168(sp)
    80005bd8:	790a                	ld	s2,160(sp)
    80005bda:	69ea                	ld	s3,152(sp)
    80005bdc:	6129                	addi	sp,sp,192
    80005bde:	8082                	ret
      end_op();
    80005be0:	fffff097          	auipc	ra,0xfffff
    80005be4:	9f2080e7          	jalr	-1550(ra) # 800045d2 <end_op>
      return -1;
    80005be8:	b7e5                	j	80005bd0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005bea:	f5040513          	addi	a0,s0,-176
    80005bee:	ffffe097          	auipc	ra,0xffffe
    80005bf2:	748080e7          	jalr	1864(ra) # 80004336 <namei>
    80005bf6:	892a                	mv	s2,a0
    80005bf8:	c905                	beqz	a0,80005c28 <sys_open+0x13c>
    ilock(ip);
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	f86080e7          	jalr	-122(ra) # 80003b80 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c02:	04491703          	lh	a4,68(s2)
    80005c06:	4785                	li	a5,1
    80005c08:	f4f712e3          	bne	a4,a5,80005b4c <sys_open+0x60>
    80005c0c:	f4c42783          	lw	a5,-180(s0)
    80005c10:	dba1                	beqz	a5,80005b60 <sys_open+0x74>
      iunlockput(ip);
    80005c12:	854a                	mv	a0,s2
    80005c14:	ffffe097          	auipc	ra,0xffffe
    80005c18:	1ce080e7          	jalr	462(ra) # 80003de2 <iunlockput>
      end_op();
    80005c1c:	fffff097          	auipc	ra,0xfffff
    80005c20:	9b6080e7          	jalr	-1610(ra) # 800045d2 <end_op>
      return -1;
    80005c24:	54fd                	li	s1,-1
    80005c26:	b76d                	j	80005bd0 <sys_open+0xe4>
      end_op();
    80005c28:	fffff097          	auipc	ra,0xfffff
    80005c2c:	9aa080e7          	jalr	-1622(ra) # 800045d2 <end_op>
      return -1;
    80005c30:	54fd                	li	s1,-1
    80005c32:	bf79                	j	80005bd0 <sys_open+0xe4>
    iunlockput(ip);
    80005c34:	854a                	mv	a0,s2
    80005c36:	ffffe097          	auipc	ra,0xffffe
    80005c3a:	1ac080e7          	jalr	428(ra) # 80003de2 <iunlockput>
    end_op();
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	994080e7          	jalr	-1644(ra) # 800045d2 <end_op>
    return -1;
    80005c46:	54fd                	li	s1,-1
    80005c48:	b761                	j	80005bd0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c4a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c4e:	04691783          	lh	a5,70(s2)
    80005c52:	02f99223          	sh	a5,36(s3)
    80005c56:	bf2d                	j	80005b90 <sys_open+0xa4>
    itrunc(ip);
    80005c58:	854a                	mv	a0,s2
    80005c5a:	ffffe097          	auipc	ra,0xffffe
    80005c5e:	034080e7          	jalr	52(ra) # 80003c8e <itrunc>
    80005c62:	bfb1                	j	80005bbe <sys_open+0xd2>
      fileclose(f);
    80005c64:	854e                	mv	a0,s3
    80005c66:	fffff097          	auipc	ra,0xfffff
    80005c6a:	db8080e7          	jalr	-584(ra) # 80004a1e <fileclose>
    iunlockput(ip);
    80005c6e:	854a                	mv	a0,s2
    80005c70:	ffffe097          	auipc	ra,0xffffe
    80005c74:	172080e7          	jalr	370(ra) # 80003de2 <iunlockput>
    end_op();
    80005c78:	fffff097          	auipc	ra,0xfffff
    80005c7c:	95a080e7          	jalr	-1702(ra) # 800045d2 <end_op>
    return -1;
    80005c80:	54fd                	li	s1,-1
    80005c82:	b7b9                	j	80005bd0 <sys_open+0xe4>

0000000080005c84 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c84:	7175                	addi	sp,sp,-144
    80005c86:	e506                	sd	ra,136(sp)
    80005c88:	e122                	sd	s0,128(sp)
    80005c8a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c8c:	fffff097          	auipc	ra,0xfffff
    80005c90:	8c6080e7          	jalr	-1850(ra) # 80004552 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c94:	08000613          	li	a2,128
    80005c98:	f7040593          	addi	a1,s0,-144
    80005c9c:	4501                	li	a0,0
    80005c9e:	ffffd097          	auipc	ra,0xffffd
    80005ca2:	3b4080e7          	jalr	948(ra) # 80003052 <argstr>
    80005ca6:	02054963          	bltz	a0,80005cd8 <sys_mkdir+0x54>
    80005caa:	4681                	li	a3,0
    80005cac:	4601                	li	a2,0
    80005cae:	4585                	li	a1,1
    80005cb0:	f7040513          	addi	a0,s0,-144
    80005cb4:	fffff097          	auipc	ra,0xfffff
    80005cb8:	7fe080e7          	jalr	2046(ra) # 800054b2 <create>
    80005cbc:	cd11                	beqz	a0,80005cd8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cbe:	ffffe097          	auipc	ra,0xffffe
    80005cc2:	124080e7          	jalr	292(ra) # 80003de2 <iunlockput>
  end_op();
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	90c080e7          	jalr	-1780(ra) # 800045d2 <end_op>
  return 0;
    80005cce:	4501                	li	a0,0
}
    80005cd0:	60aa                	ld	ra,136(sp)
    80005cd2:	640a                	ld	s0,128(sp)
    80005cd4:	6149                	addi	sp,sp,144
    80005cd6:	8082                	ret
    end_op();
    80005cd8:	fffff097          	auipc	ra,0xfffff
    80005cdc:	8fa080e7          	jalr	-1798(ra) # 800045d2 <end_op>
    return -1;
    80005ce0:	557d                	li	a0,-1
    80005ce2:	b7fd                	j	80005cd0 <sys_mkdir+0x4c>

0000000080005ce4 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ce4:	7135                	addi	sp,sp,-160
    80005ce6:	ed06                	sd	ra,152(sp)
    80005ce8:	e922                	sd	s0,144(sp)
    80005cea:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005cec:	fffff097          	auipc	ra,0xfffff
    80005cf0:	866080e7          	jalr	-1946(ra) # 80004552 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cf4:	08000613          	li	a2,128
    80005cf8:	f7040593          	addi	a1,s0,-144
    80005cfc:	4501                	li	a0,0
    80005cfe:	ffffd097          	auipc	ra,0xffffd
    80005d02:	354080e7          	jalr	852(ra) # 80003052 <argstr>
    80005d06:	04054a63          	bltz	a0,80005d5a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d0a:	f6c40593          	addi	a1,s0,-148
    80005d0e:	4505                	li	a0,1
    80005d10:	ffffd097          	auipc	ra,0xffffd
    80005d14:	2fe080e7          	jalr	766(ra) # 8000300e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d18:	04054163          	bltz	a0,80005d5a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d1c:	f6840593          	addi	a1,s0,-152
    80005d20:	4509                	li	a0,2
    80005d22:	ffffd097          	auipc	ra,0xffffd
    80005d26:	2ec080e7          	jalr	748(ra) # 8000300e <argint>
     argint(1, &major) < 0 ||
    80005d2a:	02054863          	bltz	a0,80005d5a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d2e:	f6841683          	lh	a3,-152(s0)
    80005d32:	f6c41603          	lh	a2,-148(s0)
    80005d36:	458d                	li	a1,3
    80005d38:	f7040513          	addi	a0,s0,-144
    80005d3c:	fffff097          	auipc	ra,0xfffff
    80005d40:	776080e7          	jalr	1910(ra) # 800054b2 <create>
     argint(2, &minor) < 0 ||
    80005d44:	c919                	beqz	a0,80005d5a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d46:	ffffe097          	auipc	ra,0xffffe
    80005d4a:	09c080e7          	jalr	156(ra) # 80003de2 <iunlockput>
  end_op();
    80005d4e:	fffff097          	auipc	ra,0xfffff
    80005d52:	884080e7          	jalr	-1916(ra) # 800045d2 <end_op>
  return 0;
    80005d56:	4501                	li	a0,0
    80005d58:	a031                	j	80005d64 <sys_mknod+0x80>
    end_op();
    80005d5a:	fffff097          	auipc	ra,0xfffff
    80005d5e:	878080e7          	jalr	-1928(ra) # 800045d2 <end_op>
    return -1;
    80005d62:	557d                	li	a0,-1
}
    80005d64:	60ea                	ld	ra,152(sp)
    80005d66:	644a                	ld	s0,144(sp)
    80005d68:	610d                	addi	sp,sp,160
    80005d6a:	8082                	ret

0000000080005d6c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d6c:	7135                	addi	sp,sp,-160
    80005d6e:	ed06                	sd	ra,152(sp)
    80005d70:	e922                	sd	s0,144(sp)
    80005d72:	e526                	sd	s1,136(sp)
    80005d74:	e14a                	sd	s2,128(sp)
    80005d76:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d78:	ffffc097          	auipc	ra,0xffffc
    80005d7c:	f56080e7          	jalr	-170(ra) # 80001cce <myproc>
    80005d80:	892a                	mv	s2,a0
  
  begin_op();
    80005d82:	ffffe097          	auipc	ra,0xffffe
    80005d86:	7d0080e7          	jalr	2000(ra) # 80004552 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d8a:	08000613          	li	a2,128
    80005d8e:	f6040593          	addi	a1,s0,-160
    80005d92:	4501                	li	a0,0
    80005d94:	ffffd097          	auipc	ra,0xffffd
    80005d98:	2be080e7          	jalr	702(ra) # 80003052 <argstr>
    80005d9c:	04054b63          	bltz	a0,80005df2 <sys_chdir+0x86>
    80005da0:	f6040513          	addi	a0,s0,-160
    80005da4:	ffffe097          	auipc	ra,0xffffe
    80005da8:	592080e7          	jalr	1426(ra) # 80004336 <namei>
    80005dac:	84aa                	mv	s1,a0
    80005dae:	c131                	beqz	a0,80005df2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005db0:	ffffe097          	auipc	ra,0xffffe
    80005db4:	dd0080e7          	jalr	-560(ra) # 80003b80 <ilock>
  if(ip->type != T_DIR){
    80005db8:	04449703          	lh	a4,68(s1)
    80005dbc:	4785                	li	a5,1
    80005dbe:	04f71063          	bne	a4,a5,80005dfe <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005dc2:	8526                	mv	a0,s1
    80005dc4:	ffffe097          	auipc	ra,0xffffe
    80005dc8:	e7e080e7          	jalr	-386(ra) # 80003c42 <iunlock>
  iput(p->cwd);
    80005dcc:	15093503          	ld	a0,336(s2)
    80005dd0:	ffffe097          	auipc	ra,0xffffe
    80005dd4:	f6a080e7          	jalr	-150(ra) # 80003d3a <iput>
  end_op();
    80005dd8:	ffffe097          	auipc	ra,0xffffe
    80005ddc:	7fa080e7          	jalr	2042(ra) # 800045d2 <end_op>
  p->cwd = ip;
    80005de0:	14993823          	sd	s1,336(s2)
  return 0;
    80005de4:	4501                	li	a0,0
}
    80005de6:	60ea                	ld	ra,152(sp)
    80005de8:	644a                	ld	s0,144(sp)
    80005dea:	64aa                	ld	s1,136(sp)
    80005dec:	690a                	ld	s2,128(sp)
    80005dee:	610d                	addi	sp,sp,160
    80005df0:	8082                	ret
    end_op();
    80005df2:	ffffe097          	auipc	ra,0xffffe
    80005df6:	7e0080e7          	jalr	2016(ra) # 800045d2 <end_op>
    return -1;
    80005dfa:	557d                	li	a0,-1
    80005dfc:	b7ed                	j	80005de6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005dfe:	8526                	mv	a0,s1
    80005e00:	ffffe097          	auipc	ra,0xffffe
    80005e04:	fe2080e7          	jalr	-30(ra) # 80003de2 <iunlockput>
    end_op();
    80005e08:	ffffe097          	auipc	ra,0xffffe
    80005e0c:	7ca080e7          	jalr	1994(ra) # 800045d2 <end_op>
    return -1;
    80005e10:	557d                	li	a0,-1
    80005e12:	bfd1                	j	80005de6 <sys_chdir+0x7a>

0000000080005e14 <sys_exec>:

uint64
sys_exec(void)
{
    80005e14:	7145                	addi	sp,sp,-464
    80005e16:	e786                	sd	ra,456(sp)
    80005e18:	e3a2                	sd	s0,448(sp)
    80005e1a:	ff26                	sd	s1,440(sp)
    80005e1c:	fb4a                	sd	s2,432(sp)
    80005e1e:	f74e                	sd	s3,424(sp)
    80005e20:	f352                	sd	s4,416(sp)
    80005e22:	ef56                	sd	s5,408(sp)
    80005e24:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e26:	08000613          	li	a2,128
    80005e2a:	f4040593          	addi	a1,s0,-192
    80005e2e:	4501                	li	a0,0
    80005e30:	ffffd097          	auipc	ra,0xffffd
    80005e34:	222080e7          	jalr	546(ra) # 80003052 <argstr>
    return -1;
    80005e38:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e3a:	0c054a63          	bltz	a0,80005f0e <sys_exec+0xfa>
    80005e3e:	e3840593          	addi	a1,s0,-456
    80005e42:	4505                	li	a0,1
    80005e44:	ffffd097          	auipc	ra,0xffffd
    80005e48:	1ec080e7          	jalr	492(ra) # 80003030 <argaddr>
    80005e4c:	0c054163          	bltz	a0,80005f0e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e50:	10000613          	li	a2,256
    80005e54:	4581                	li	a1,0
    80005e56:	e4040513          	addi	a0,s0,-448
    80005e5a:	ffffb097          	auipc	ra,0xffffb
    80005e5e:	e86080e7          	jalr	-378(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e62:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e66:	89a6                	mv	s3,s1
    80005e68:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e6a:	02000a13          	li	s4,32
    80005e6e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e72:	00391513          	slli	a0,s2,0x3
    80005e76:	e3040593          	addi	a1,s0,-464
    80005e7a:	e3843783          	ld	a5,-456(s0)
    80005e7e:	953e                	add	a0,a0,a5
    80005e80:	ffffd097          	auipc	ra,0xffffd
    80005e84:	0f4080e7          	jalr	244(ra) # 80002f74 <fetchaddr>
    80005e88:	02054a63          	bltz	a0,80005ebc <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e8c:	e3043783          	ld	a5,-464(s0)
    80005e90:	c3b9                	beqz	a5,80005ed6 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e92:	ffffb097          	auipc	ra,0xffffb
    80005e96:	c62080e7          	jalr	-926(ra) # 80000af4 <kalloc>
    80005e9a:	85aa                	mv	a1,a0
    80005e9c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ea0:	cd11                	beqz	a0,80005ebc <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ea2:	6605                	lui	a2,0x1
    80005ea4:	e3043503          	ld	a0,-464(s0)
    80005ea8:	ffffd097          	auipc	ra,0xffffd
    80005eac:	11e080e7          	jalr	286(ra) # 80002fc6 <fetchstr>
    80005eb0:	00054663          	bltz	a0,80005ebc <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005eb4:	0905                	addi	s2,s2,1
    80005eb6:	09a1                	addi	s3,s3,8
    80005eb8:	fb491be3          	bne	s2,s4,80005e6e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ebc:	10048913          	addi	s2,s1,256
    80005ec0:	6088                	ld	a0,0(s1)
    80005ec2:	c529                	beqz	a0,80005f0c <sys_exec+0xf8>
    kfree(argv[i]);
    80005ec4:	ffffb097          	auipc	ra,0xffffb
    80005ec8:	b34080e7          	jalr	-1228(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ecc:	04a1                	addi	s1,s1,8
    80005ece:	ff2499e3          	bne	s1,s2,80005ec0 <sys_exec+0xac>
  return -1;
    80005ed2:	597d                	li	s2,-1
    80005ed4:	a82d                	j	80005f0e <sys_exec+0xfa>
      argv[i] = 0;
    80005ed6:	0a8e                	slli	s5,s5,0x3
    80005ed8:	fc040793          	addi	a5,s0,-64
    80005edc:	9abe                	add	s5,s5,a5
    80005ede:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ee2:	e4040593          	addi	a1,s0,-448
    80005ee6:	f4040513          	addi	a0,s0,-192
    80005eea:	fffff097          	auipc	ra,0xfffff
    80005eee:	194080e7          	jalr	404(ra) # 8000507e <exec>
    80005ef2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ef4:	10048993          	addi	s3,s1,256
    80005ef8:	6088                	ld	a0,0(s1)
    80005efa:	c911                	beqz	a0,80005f0e <sys_exec+0xfa>
    kfree(argv[i]);
    80005efc:	ffffb097          	auipc	ra,0xffffb
    80005f00:	afc080e7          	jalr	-1284(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f04:	04a1                	addi	s1,s1,8
    80005f06:	ff3499e3          	bne	s1,s3,80005ef8 <sys_exec+0xe4>
    80005f0a:	a011                	j	80005f0e <sys_exec+0xfa>
  return -1;
    80005f0c:	597d                	li	s2,-1
}
    80005f0e:	854a                	mv	a0,s2
    80005f10:	60be                	ld	ra,456(sp)
    80005f12:	641e                	ld	s0,448(sp)
    80005f14:	74fa                	ld	s1,440(sp)
    80005f16:	795a                	ld	s2,432(sp)
    80005f18:	79ba                	ld	s3,424(sp)
    80005f1a:	7a1a                	ld	s4,416(sp)
    80005f1c:	6afa                	ld	s5,408(sp)
    80005f1e:	6179                	addi	sp,sp,464
    80005f20:	8082                	ret

0000000080005f22 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f22:	7139                	addi	sp,sp,-64
    80005f24:	fc06                	sd	ra,56(sp)
    80005f26:	f822                	sd	s0,48(sp)
    80005f28:	f426                	sd	s1,40(sp)
    80005f2a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f2c:	ffffc097          	auipc	ra,0xffffc
    80005f30:	da2080e7          	jalr	-606(ra) # 80001cce <myproc>
    80005f34:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f36:	fd840593          	addi	a1,s0,-40
    80005f3a:	4501                	li	a0,0
    80005f3c:	ffffd097          	auipc	ra,0xffffd
    80005f40:	0f4080e7          	jalr	244(ra) # 80003030 <argaddr>
    return -1;
    80005f44:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f46:	0e054063          	bltz	a0,80006026 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f4a:	fc840593          	addi	a1,s0,-56
    80005f4e:	fd040513          	addi	a0,s0,-48
    80005f52:	fffff097          	auipc	ra,0xfffff
    80005f56:	dfc080e7          	jalr	-516(ra) # 80004d4e <pipealloc>
    return -1;
    80005f5a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f5c:	0c054563          	bltz	a0,80006026 <sys_pipe+0x104>
  fd0 = -1;
    80005f60:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f64:	fd043503          	ld	a0,-48(s0)
    80005f68:	fffff097          	auipc	ra,0xfffff
    80005f6c:	508080e7          	jalr	1288(ra) # 80005470 <fdalloc>
    80005f70:	fca42223          	sw	a0,-60(s0)
    80005f74:	08054c63          	bltz	a0,8000600c <sys_pipe+0xea>
    80005f78:	fc843503          	ld	a0,-56(s0)
    80005f7c:	fffff097          	auipc	ra,0xfffff
    80005f80:	4f4080e7          	jalr	1268(ra) # 80005470 <fdalloc>
    80005f84:	fca42023          	sw	a0,-64(s0)
    80005f88:	06054863          	bltz	a0,80005ff8 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f8c:	4691                	li	a3,4
    80005f8e:	fc440613          	addi	a2,s0,-60
    80005f92:	fd843583          	ld	a1,-40(s0)
    80005f96:	68a8                	ld	a0,80(s1)
    80005f98:	ffffb097          	auipc	ra,0xffffb
    80005f9c:	6da080e7          	jalr	1754(ra) # 80001672 <copyout>
    80005fa0:	02054063          	bltz	a0,80005fc0 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005fa4:	4691                	li	a3,4
    80005fa6:	fc040613          	addi	a2,s0,-64
    80005faa:	fd843583          	ld	a1,-40(s0)
    80005fae:	0591                	addi	a1,a1,4
    80005fb0:	68a8                	ld	a0,80(s1)
    80005fb2:	ffffb097          	auipc	ra,0xffffb
    80005fb6:	6c0080e7          	jalr	1728(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fba:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fbc:	06055563          	bgez	a0,80006026 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005fc0:	fc442783          	lw	a5,-60(s0)
    80005fc4:	07e9                	addi	a5,a5,26
    80005fc6:	078e                	slli	a5,a5,0x3
    80005fc8:	97a6                	add	a5,a5,s1
    80005fca:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005fce:	fc042503          	lw	a0,-64(s0)
    80005fd2:	0569                	addi	a0,a0,26
    80005fd4:	050e                	slli	a0,a0,0x3
    80005fd6:	9526                	add	a0,a0,s1
    80005fd8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005fdc:	fd043503          	ld	a0,-48(s0)
    80005fe0:	fffff097          	auipc	ra,0xfffff
    80005fe4:	a3e080e7          	jalr	-1474(ra) # 80004a1e <fileclose>
    fileclose(wf);
    80005fe8:	fc843503          	ld	a0,-56(s0)
    80005fec:	fffff097          	auipc	ra,0xfffff
    80005ff0:	a32080e7          	jalr	-1486(ra) # 80004a1e <fileclose>
    return -1;
    80005ff4:	57fd                	li	a5,-1
    80005ff6:	a805                	j	80006026 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005ff8:	fc442783          	lw	a5,-60(s0)
    80005ffc:	0007c863          	bltz	a5,8000600c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006000:	01a78513          	addi	a0,a5,26
    80006004:	050e                	slli	a0,a0,0x3
    80006006:	9526                	add	a0,a0,s1
    80006008:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000600c:	fd043503          	ld	a0,-48(s0)
    80006010:	fffff097          	auipc	ra,0xfffff
    80006014:	a0e080e7          	jalr	-1522(ra) # 80004a1e <fileclose>
    fileclose(wf);
    80006018:	fc843503          	ld	a0,-56(s0)
    8000601c:	fffff097          	auipc	ra,0xfffff
    80006020:	a02080e7          	jalr	-1534(ra) # 80004a1e <fileclose>
    return -1;
    80006024:	57fd                	li	a5,-1
}
    80006026:	853e                	mv	a0,a5
    80006028:	70e2                	ld	ra,56(sp)
    8000602a:	7442                	ld	s0,48(sp)
    8000602c:	74a2                	ld	s1,40(sp)
    8000602e:	6121                	addi	sp,sp,64
    80006030:	8082                	ret
	...

0000000080006040 <kernelvec>:
    80006040:	7111                	addi	sp,sp,-256
    80006042:	e006                	sd	ra,0(sp)
    80006044:	e40a                	sd	sp,8(sp)
    80006046:	e80e                	sd	gp,16(sp)
    80006048:	ec12                	sd	tp,24(sp)
    8000604a:	f016                	sd	t0,32(sp)
    8000604c:	f41a                	sd	t1,40(sp)
    8000604e:	f81e                	sd	t2,48(sp)
    80006050:	fc22                	sd	s0,56(sp)
    80006052:	e0a6                	sd	s1,64(sp)
    80006054:	e4aa                	sd	a0,72(sp)
    80006056:	e8ae                	sd	a1,80(sp)
    80006058:	ecb2                	sd	a2,88(sp)
    8000605a:	f0b6                	sd	a3,96(sp)
    8000605c:	f4ba                	sd	a4,104(sp)
    8000605e:	f8be                	sd	a5,112(sp)
    80006060:	fcc2                	sd	a6,120(sp)
    80006062:	e146                	sd	a7,128(sp)
    80006064:	e54a                	sd	s2,136(sp)
    80006066:	e94e                	sd	s3,144(sp)
    80006068:	ed52                	sd	s4,152(sp)
    8000606a:	f156                	sd	s5,160(sp)
    8000606c:	f55a                	sd	s6,168(sp)
    8000606e:	f95e                	sd	s7,176(sp)
    80006070:	fd62                	sd	s8,184(sp)
    80006072:	e1e6                	sd	s9,192(sp)
    80006074:	e5ea                	sd	s10,200(sp)
    80006076:	e9ee                	sd	s11,208(sp)
    80006078:	edf2                	sd	t3,216(sp)
    8000607a:	f1f6                	sd	t4,224(sp)
    8000607c:	f5fa                	sd	t5,232(sp)
    8000607e:	f9fe                	sd	t6,240(sp)
    80006080:	dc1fc0ef          	jal	ra,80002e40 <kerneltrap>
    80006084:	6082                	ld	ra,0(sp)
    80006086:	6122                	ld	sp,8(sp)
    80006088:	61c2                	ld	gp,16(sp)
    8000608a:	7282                	ld	t0,32(sp)
    8000608c:	7322                	ld	t1,40(sp)
    8000608e:	73c2                	ld	t2,48(sp)
    80006090:	7462                	ld	s0,56(sp)
    80006092:	6486                	ld	s1,64(sp)
    80006094:	6526                	ld	a0,72(sp)
    80006096:	65c6                	ld	a1,80(sp)
    80006098:	6666                	ld	a2,88(sp)
    8000609a:	7686                	ld	a3,96(sp)
    8000609c:	7726                	ld	a4,104(sp)
    8000609e:	77c6                	ld	a5,112(sp)
    800060a0:	7866                	ld	a6,120(sp)
    800060a2:	688a                	ld	a7,128(sp)
    800060a4:	692a                	ld	s2,136(sp)
    800060a6:	69ca                	ld	s3,144(sp)
    800060a8:	6a6a                	ld	s4,152(sp)
    800060aa:	7a8a                	ld	s5,160(sp)
    800060ac:	7b2a                	ld	s6,168(sp)
    800060ae:	7bca                	ld	s7,176(sp)
    800060b0:	7c6a                	ld	s8,184(sp)
    800060b2:	6c8e                	ld	s9,192(sp)
    800060b4:	6d2e                	ld	s10,200(sp)
    800060b6:	6dce                	ld	s11,208(sp)
    800060b8:	6e6e                	ld	t3,216(sp)
    800060ba:	7e8e                	ld	t4,224(sp)
    800060bc:	7f2e                	ld	t5,232(sp)
    800060be:	7fce                	ld	t6,240(sp)
    800060c0:	6111                	addi	sp,sp,256
    800060c2:	10200073          	sret
    800060c6:	00000013          	nop
    800060ca:	00000013          	nop
    800060ce:	0001                	nop

00000000800060d0 <timervec>:
    800060d0:	34051573          	csrrw	a0,mscratch,a0
    800060d4:	e10c                	sd	a1,0(a0)
    800060d6:	e510                	sd	a2,8(a0)
    800060d8:	e914                	sd	a3,16(a0)
    800060da:	6d0c                	ld	a1,24(a0)
    800060dc:	7110                	ld	a2,32(a0)
    800060de:	6194                	ld	a3,0(a1)
    800060e0:	96b2                	add	a3,a3,a2
    800060e2:	e194                	sd	a3,0(a1)
    800060e4:	4589                	li	a1,2
    800060e6:	14459073          	csrw	sip,a1
    800060ea:	6914                	ld	a3,16(a0)
    800060ec:	6510                	ld	a2,8(a0)
    800060ee:	610c                	ld	a1,0(a0)
    800060f0:	34051573          	csrrw	a0,mscratch,a0
    800060f4:	30200073          	mret
	...

00000000800060fa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060fa:	1141                	addi	sp,sp,-16
    800060fc:	e422                	sd	s0,8(sp)
    800060fe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006100:	0c0007b7          	lui	a5,0xc000
    80006104:	4705                	li	a4,1
    80006106:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006108:	c3d8                	sw	a4,4(a5)
}
    8000610a:	6422                	ld	s0,8(sp)
    8000610c:	0141                	addi	sp,sp,16
    8000610e:	8082                	ret

0000000080006110 <plicinithart>:

void
plicinithart(void)
{
    80006110:	1141                	addi	sp,sp,-16
    80006112:	e406                	sd	ra,8(sp)
    80006114:	e022                	sd	s0,0(sp)
    80006116:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006118:	ffffc097          	auipc	ra,0xffffc
    8000611c:	b84080e7          	jalr	-1148(ra) # 80001c9c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006120:	0085171b          	slliw	a4,a0,0x8
    80006124:	0c0027b7          	lui	a5,0xc002
    80006128:	97ba                	add	a5,a5,a4
    8000612a:	40200713          	li	a4,1026
    8000612e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006132:	00d5151b          	slliw	a0,a0,0xd
    80006136:	0c2017b7          	lui	a5,0xc201
    8000613a:	953e                	add	a0,a0,a5
    8000613c:	00052023          	sw	zero,0(a0)
}
    80006140:	60a2                	ld	ra,8(sp)
    80006142:	6402                	ld	s0,0(sp)
    80006144:	0141                	addi	sp,sp,16
    80006146:	8082                	ret

0000000080006148 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006148:	1141                	addi	sp,sp,-16
    8000614a:	e406                	sd	ra,8(sp)
    8000614c:	e022                	sd	s0,0(sp)
    8000614e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006150:	ffffc097          	auipc	ra,0xffffc
    80006154:	b4c080e7          	jalr	-1204(ra) # 80001c9c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006158:	00d5179b          	slliw	a5,a0,0xd
    8000615c:	0c201537          	lui	a0,0xc201
    80006160:	953e                	add	a0,a0,a5
  return irq;
}
    80006162:	4148                	lw	a0,4(a0)
    80006164:	60a2                	ld	ra,8(sp)
    80006166:	6402                	ld	s0,0(sp)
    80006168:	0141                	addi	sp,sp,16
    8000616a:	8082                	ret

000000008000616c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000616c:	1101                	addi	sp,sp,-32
    8000616e:	ec06                	sd	ra,24(sp)
    80006170:	e822                	sd	s0,16(sp)
    80006172:	e426                	sd	s1,8(sp)
    80006174:	1000                	addi	s0,sp,32
    80006176:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006178:	ffffc097          	auipc	ra,0xffffc
    8000617c:	b24080e7          	jalr	-1244(ra) # 80001c9c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006180:	00d5151b          	slliw	a0,a0,0xd
    80006184:	0c2017b7          	lui	a5,0xc201
    80006188:	97aa                	add	a5,a5,a0
    8000618a:	c3c4                	sw	s1,4(a5)
}
    8000618c:	60e2                	ld	ra,24(sp)
    8000618e:	6442                	ld	s0,16(sp)
    80006190:	64a2                	ld	s1,8(sp)
    80006192:	6105                	addi	sp,sp,32
    80006194:	8082                	ret

0000000080006196 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006196:	1141                	addi	sp,sp,-16
    80006198:	e406                	sd	ra,8(sp)
    8000619a:	e022                	sd	s0,0(sp)
    8000619c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000619e:	479d                	li	a5,7
    800061a0:	06a7c963          	blt	a5,a0,80006212 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800061a4:	0001d797          	auipc	a5,0x1d
    800061a8:	e5c78793          	addi	a5,a5,-420 # 80023000 <disk>
    800061ac:	00a78733          	add	a4,a5,a0
    800061b0:	6789                	lui	a5,0x2
    800061b2:	97ba                	add	a5,a5,a4
    800061b4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800061b8:	e7ad                	bnez	a5,80006222 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061ba:	00451793          	slli	a5,a0,0x4
    800061be:	0001f717          	auipc	a4,0x1f
    800061c2:	e4270713          	addi	a4,a4,-446 # 80025000 <disk+0x2000>
    800061c6:	6314                	ld	a3,0(a4)
    800061c8:	96be                	add	a3,a3,a5
    800061ca:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800061ce:	6314                	ld	a3,0(a4)
    800061d0:	96be                	add	a3,a3,a5
    800061d2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800061d6:	6314                	ld	a3,0(a4)
    800061d8:	96be                	add	a3,a3,a5
    800061da:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800061de:	6318                	ld	a4,0(a4)
    800061e0:	97ba                	add	a5,a5,a4
    800061e2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800061e6:	0001d797          	auipc	a5,0x1d
    800061ea:	e1a78793          	addi	a5,a5,-486 # 80023000 <disk>
    800061ee:	97aa                	add	a5,a5,a0
    800061f0:	6509                	lui	a0,0x2
    800061f2:	953e                	add	a0,a0,a5
    800061f4:	4785                	li	a5,1
    800061f6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800061fa:	0001f517          	auipc	a0,0x1f
    800061fe:	e1e50513          	addi	a0,a0,-482 # 80025018 <disk+0x2018>
    80006202:	ffffc097          	auipc	ra,0xffffc
    80006206:	470080e7          	jalr	1136(ra) # 80002672 <wakeup>
}
    8000620a:	60a2                	ld	ra,8(sp)
    8000620c:	6402                	ld	s0,0(sp)
    8000620e:	0141                	addi	sp,sp,16
    80006210:	8082                	ret
    panic("free_desc 1");
    80006212:	00002517          	auipc	a0,0x2
    80006216:	5de50513          	addi	a0,a0,1502 # 800087f0 <syscalls+0x320>
    8000621a:	ffffa097          	auipc	ra,0xffffa
    8000621e:	324080e7          	jalr	804(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006222:	00002517          	auipc	a0,0x2
    80006226:	5de50513          	addi	a0,a0,1502 # 80008800 <syscalls+0x330>
    8000622a:	ffffa097          	auipc	ra,0xffffa
    8000622e:	314080e7          	jalr	788(ra) # 8000053e <panic>

0000000080006232 <virtio_disk_init>:
{
    80006232:	1101                	addi	sp,sp,-32
    80006234:	ec06                	sd	ra,24(sp)
    80006236:	e822                	sd	s0,16(sp)
    80006238:	e426                	sd	s1,8(sp)
    8000623a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000623c:	00002597          	auipc	a1,0x2
    80006240:	5d458593          	addi	a1,a1,1492 # 80008810 <syscalls+0x340>
    80006244:	0001f517          	auipc	a0,0x1f
    80006248:	ee450513          	addi	a0,a0,-284 # 80025128 <disk+0x2128>
    8000624c:	ffffb097          	auipc	ra,0xffffb
    80006250:	908080e7          	jalr	-1784(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006254:	100017b7          	lui	a5,0x10001
    80006258:	4398                	lw	a4,0(a5)
    8000625a:	2701                	sext.w	a4,a4
    8000625c:	747277b7          	lui	a5,0x74727
    80006260:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006264:	0ef71163          	bne	a4,a5,80006346 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006268:	100017b7          	lui	a5,0x10001
    8000626c:	43dc                	lw	a5,4(a5)
    8000626e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006270:	4705                	li	a4,1
    80006272:	0ce79a63          	bne	a5,a4,80006346 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006276:	100017b7          	lui	a5,0x10001
    8000627a:	479c                	lw	a5,8(a5)
    8000627c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000627e:	4709                	li	a4,2
    80006280:	0ce79363          	bne	a5,a4,80006346 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006284:	100017b7          	lui	a5,0x10001
    80006288:	47d8                	lw	a4,12(a5)
    8000628a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000628c:	554d47b7          	lui	a5,0x554d4
    80006290:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006294:	0af71963          	bne	a4,a5,80006346 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006298:	100017b7          	lui	a5,0x10001
    8000629c:	4705                	li	a4,1
    8000629e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062a0:	470d                	li	a4,3
    800062a2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800062a4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800062a6:	c7ffe737          	lui	a4,0xc7ffe
    800062aa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800062ae:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800062b0:	2701                	sext.w	a4,a4
    800062b2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062b4:	472d                	li	a4,11
    800062b6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062b8:	473d                	li	a4,15
    800062ba:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800062bc:	6705                	lui	a4,0x1
    800062be:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800062c0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062c4:	5bdc                	lw	a5,52(a5)
    800062c6:	2781                	sext.w	a5,a5
  if(max == 0)
    800062c8:	c7d9                	beqz	a5,80006356 <virtio_disk_init+0x124>
  if(max < NUM)
    800062ca:	471d                	li	a4,7
    800062cc:	08f77d63          	bgeu	a4,a5,80006366 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062d0:	100014b7          	lui	s1,0x10001
    800062d4:	47a1                	li	a5,8
    800062d6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800062d8:	6609                	lui	a2,0x2
    800062da:	4581                	li	a1,0
    800062dc:	0001d517          	auipc	a0,0x1d
    800062e0:	d2450513          	addi	a0,a0,-732 # 80023000 <disk>
    800062e4:	ffffb097          	auipc	ra,0xffffb
    800062e8:	9fc080e7          	jalr	-1540(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800062ec:	0001d717          	auipc	a4,0x1d
    800062f0:	d1470713          	addi	a4,a4,-748 # 80023000 <disk>
    800062f4:	00c75793          	srli	a5,a4,0xc
    800062f8:	2781                	sext.w	a5,a5
    800062fa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800062fc:	0001f797          	auipc	a5,0x1f
    80006300:	d0478793          	addi	a5,a5,-764 # 80025000 <disk+0x2000>
    80006304:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006306:	0001d717          	auipc	a4,0x1d
    8000630a:	d7a70713          	addi	a4,a4,-646 # 80023080 <disk+0x80>
    8000630e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006310:	0001e717          	auipc	a4,0x1e
    80006314:	cf070713          	addi	a4,a4,-784 # 80024000 <disk+0x1000>
    80006318:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000631a:	4705                	li	a4,1
    8000631c:	00e78c23          	sb	a4,24(a5)
    80006320:	00e78ca3          	sb	a4,25(a5)
    80006324:	00e78d23          	sb	a4,26(a5)
    80006328:	00e78da3          	sb	a4,27(a5)
    8000632c:	00e78e23          	sb	a4,28(a5)
    80006330:	00e78ea3          	sb	a4,29(a5)
    80006334:	00e78f23          	sb	a4,30(a5)
    80006338:	00e78fa3          	sb	a4,31(a5)
}
    8000633c:	60e2                	ld	ra,24(sp)
    8000633e:	6442                	ld	s0,16(sp)
    80006340:	64a2                	ld	s1,8(sp)
    80006342:	6105                	addi	sp,sp,32
    80006344:	8082                	ret
    panic("could not find virtio disk");
    80006346:	00002517          	auipc	a0,0x2
    8000634a:	4da50513          	addi	a0,a0,1242 # 80008820 <syscalls+0x350>
    8000634e:	ffffa097          	auipc	ra,0xffffa
    80006352:	1f0080e7          	jalr	496(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006356:	00002517          	auipc	a0,0x2
    8000635a:	4ea50513          	addi	a0,a0,1258 # 80008840 <syscalls+0x370>
    8000635e:	ffffa097          	auipc	ra,0xffffa
    80006362:	1e0080e7          	jalr	480(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006366:	00002517          	auipc	a0,0x2
    8000636a:	4fa50513          	addi	a0,a0,1274 # 80008860 <syscalls+0x390>
    8000636e:	ffffa097          	auipc	ra,0xffffa
    80006372:	1d0080e7          	jalr	464(ra) # 8000053e <panic>

0000000080006376 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006376:	7159                	addi	sp,sp,-112
    80006378:	f486                	sd	ra,104(sp)
    8000637a:	f0a2                	sd	s0,96(sp)
    8000637c:	eca6                	sd	s1,88(sp)
    8000637e:	e8ca                	sd	s2,80(sp)
    80006380:	e4ce                	sd	s3,72(sp)
    80006382:	e0d2                	sd	s4,64(sp)
    80006384:	fc56                	sd	s5,56(sp)
    80006386:	f85a                	sd	s6,48(sp)
    80006388:	f45e                	sd	s7,40(sp)
    8000638a:	f062                	sd	s8,32(sp)
    8000638c:	ec66                	sd	s9,24(sp)
    8000638e:	e86a                	sd	s10,16(sp)
    80006390:	1880                	addi	s0,sp,112
    80006392:	892a                	mv	s2,a0
    80006394:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006396:	00c52c83          	lw	s9,12(a0)
    8000639a:	001c9c9b          	slliw	s9,s9,0x1
    8000639e:	1c82                	slli	s9,s9,0x20
    800063a0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800063a4:	0001f517          	auipc	a0,0x1f
    800063a8:	d8450513          	addi	a0,a0,-636 # 80025128 <disk+0x2128>
    800063ac:	ffffb097          	auipc	ra,0xffffb
    800063b0:	838080e7          	jalr	-1992(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800063b4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800063b6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800063b8:	0001db97          	auipc	s7,0x1d
    800063bc:	c48b8b93          	addi	s7,s7,-952 # 80023000 <disk>
    800063c0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800063c2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800063c4:	8a4e                	mv	s4,s3
    800063c6:	a051                	j	8000644a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800063c8:	00fb86b3          	add	a3,s7,a5
    800063cc:	96da                	add	a3,a3,s6
    800063ce:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800063d2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800063d4:	0207c563          	bltz	a5,800063fe <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800063d8:	2485                	addiw	s1,s1,1
    800063da:	0711                	addi	a4,a4,4
    800063dc:	25548063          	beq	s1,s5,8000661c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800063e0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800063e2:	0001f697          	auipc	a3,0x1f
    800063e6:	c3668693          	addi	a3,a3,-970 # 80025018 <disk+0x2018>
    800063ea:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800063ec:	0006c583          	lbu	a1,0(a3)
    800063f0:	fde1                	bnez	a1,800063c8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800063f2:	2785                	addiw	a5,a5,1
    800063f4:	0685                	addi	a3,a3,1
    800063f6:	ff879be3          	bne	a5,s8,800063ec <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800063fa:	57fd                	li	a5,-1
    800063fc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800063fe:	02905a63          	blez	s1,80006432 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006402:	f9042503          	lw	a0,-112(s0)
    80006406:	00000097          	auipc	ra,0x0
    8000640a:	d90080e7          	jalr	-624(ra) # 80006196 <free_desc>
      for(int j = 0; j < i; j++)
    8000640e:	4785                	li	a5,1
    80006410:	0297d163          	bge	a5,s1,80006432 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006414:	f9442503          	lw	a0,-108(s0)
    80006418:	00000097          	auipc	ra,0x0
    8000641c:	d7e080e7          	jalr	-642(ra) # 80006196 <free_desc>
      for(int j = 0; j < i; j++)
    80006420:	4789                	li	a5,2
    80006422:	0097d863          	bge	a5,s1,80006432 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006426:	f9842503          	lw	a0,-104(s0)
    8000642a:	00000097          	auipc	ra,0x0
    8000642e:	d6c080e7          	jalr	-660(ra) # 80006196 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006432:	0001f597          	auipc	a1,0x1f
    80006436:	cf658593          	addi	a1,a1,-778 # 80025128 <disk+0x2128>
    8000643a:	0001f517          	auipc	a0,0x1f
    8000643e:	bde50513          	addi	a0,a0,-1058 # 80025018 <disk+0x2018>
    80006442:	ffffc097          	auipc	ra,0xffffc
    80006446:	092080e7          	jalr	146(ra) # 800024d4 <sleep>
  for(int i = 0; i < 3; i++){
    8000644a:	f9040713          	addi	a4,s0,-112
    8000644e:	84ce                	mv	s1,s3
    80006450:	bf41                	j	800063e0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006452:	20058713          	addi	a4,a1,512
    80006456:	00471693          	slli	a3,a4,0x4
    8000645a:	0001d717          	auipc	a4,0x1d
    8000645e:	ba670713          	addi	a4,a4,-1114 # 80023000 <disk>
    80006462:	9736                	add	a4,a4,a3
    80006464:	4685                	li	a3,1
    80006466:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000646a:	20058713          	addi	a4,a1,512
    8000646e:	00471693          	slli	a3,a4,0x4
    80006472:	0001d717          	auipc	a4,0x1d
    80006476:	b8e70713          	addi	a4,a4,-1138 # 80023000 <disk>
    8000647a:	9736                	add	a4,a4,a3
    8000647c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006480:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006484:	7679                	lui	a2,0xffffe
    80006486:	963e                	add	a2,a2,a5
    80006488:	0001f697          	auipc	a3,0x1f
    8000648c:	b7868693          	addi	a3,a3,-1160 # 80025000 <disk+0x2000>
    80006490:	6298                	ld	a4,0(a3)
    80006492:	9732                	add	a4,a4,a2
    80006494:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006496:	6298                	ld	a4,0(a3)
    80006498:	9732                	add	a4,a4,a2
    8000649a:	4541                	li	a0,16
    8000649c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000649e:	6298                	ld	a4,0(a3)
    800064a0:	9732                	add	a4,a4,a2
    800064a2:	4505                	li	a0,1
    800064a4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800064a8:	f9442703          	lw	a4,-108(s0)
    800064ac:	6288                	ld	a0,0(a3)
    800064ae:	962a                	add	a2,a2,a0
    800064b0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800064b4:	0712                	slli	a4,a4,0x4
    800064b6:	6290                	ld	a2,0(a3)
    800064b8:	963a                	add	a2,a2,a4
    800064ba:	05890513          	addi	a0,s2,88
    800064be:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800064c0:	6294                	ld	a3,0(a3)
    800064c2:	96ba                	add	a3,a3,a4
    800064c4:	40000613          	li	a2,1024
    800064c8:	c690                	sw	a2,8(a3)
  if(write)
    800064ca:	140d0063          	beqz	s10,8000660a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800064ce:	0001f697          	auipc	a3,0x1f
    800064d2:	b326b683          	ld	a3,-1230(a3) # 80025000 <disk+0x2000>
    800064d6:	96ba                	add	a3,a3,a4
    800064d8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064dc:	0001d817          	auipc	a6,0x1d
    800064e0:	b2480813          	addi	a6,a6,-1244 # 80023000 <disk>
    800064e4:	0001f517          	auipc	a0,0x1f
    800064e8:	b1c50513          	addi	a0,a0,-1252 # 80025000 <disk+0x2000>
    800064ec:	6114                	ld	a3,0(a0)
    800064ee:	96ba                	add	a3,a3,a4
    800064f0:	00c6d603          	lhu	a2,12(a3)
    800064f4:	00166613          	ori	a2,a2,1
    800064f8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800064fc:	f9842683          	lw	a3,-104(s0)
    80006500:	6110                	ld	a2,0(a0)
    80006502:	9732                	add	a4,a4,a2
    80006504:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006508:	20058613          	addi	a2,a1,512
    8000650c:	0612                	slli	a2,a2,0x4
    8000650e:	9642                	add	a2,a2,a6
    80006510:	577d                	li	a4,-1
    80006512:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006516:	00469713          	slli	a4,a3,0x4
    8000651a:	6114                	ld	a3,0(a0)
    8000651c:	96ba                	add	a3,a3,a4
    8000651e:	03078793          	addi	a5,a5,48
    80006522:	97c2                	add	a5,a5,a6
    80006524:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006526:	611c                	ld	a5,0(a0)
    80006528:	97ba                	add	a5,a5,a4
    8000652a:	4685                	li	a3,1
    8000652c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000652e:	611c                	ld	a5,0(a0)
    80006530:	97ba                	add	a5,a5,a4
    80006532:	4809                	li	a6,2
    80006534:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006538:	611c                	ld	a5,0(a0)
    8000653a:	973e                	add	a4,a4,a5
    8000653c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006540:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006544:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006548:	6518                	ld	a4,8(a0)
    8000654a:	00275783          	lhu	a5,2(a4)
    8000654e:	8b9d                	andi	a5,a5,7
    80006550:	0786                	slli	a5,a5,0x1
    80006552:	97ba                	add	a5,a5,a4
    80006554:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006558:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000655c:	6518                	ld	a4,8(a0)
    8000655e:	00275783          	lhu	a5,2(a4)
    80006562:	2785                	addiw	a5,a5,1
    80006564:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006568:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000656c:	100017b7          	lui	a5,0x10001
    80006570:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006574:	00492703          	lw	a4,4(s2)
    80006578:	4785                	li	a5,1
    8000657a:	02f71163          	bne	a4,a5,8000659c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000657e:	0001f997          	auipc	s3,0x1f
    80006582:	baa98993          	addi	s3,s3,-1110 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006586:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006588:	85ce                	mv	a1,s3
    8000658a:	854a                	mv	a0,s2
    8000658c:	ffffc097          	auipc	ra,0xffffc
    80006590:	f48080e7          	jalr	-184(ra) # 800024d4 <sleep>
  while(b->disk == 1) {
    80006594:	00492783          	lw	a5,4(s2)
    80006598:	fe9788e3          	beq	a5,s1,80006588 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000659c:	f9042903          	lw	s2,-112(s0)
    800065a0:	20090793          	addi	a5,s2,512
    800065a4:	00479713          	slli	a4,a5,0x4
    800065a8:	0001d797          	auipc	a5,0x1d
    800065ac:	a5878793          	addi	a5,a5,-1448 # 80023000 <disk>
    800065b0:	97ba                	add	a5,a5,a4
    800065b2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800065b6:	0001f997          	auipc	s3,0x1f
    800065ba:	a4a98993          	addi	s3,s3,-1462 # 80025000 <disk+0x2000>
    800065be:	00491713          	slli	a4,s2,0x4
    800065c2:	0009b783          	ld	a5,0(s3)
    800065c6:	97ba                	add	a5,a5,a4
    800065c8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800065cc:	854a                	mv	a0,s2
    800065ce:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065d2:	00000097          	auipc	ra,0x0
    800065d6:	bc4080e7          	jalr	-1084(ra) # 80006196 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065da:	8885                	andi	s1,s1,1
    800065dc:	f0ed                	bnez	s1,800065be <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065de:	0001f517          	auipc	a0,0x1f
    800065e2:	b4a50513          	addi	a0,a0,-1206 # 80025128 <disk+0x2128>
    800065e6:	ffffa097          	auipc	ra,0xffffa
    800065ea:	6b2080e7          	jalr	1714(ra) # 80000c98 <release>
}
    800065ee:	70a6                	ld	ra,104(sp)
    800065f0:	7406                	ld	s0,96(sp)
    800065f2:	64e6                	ld	s1,88(sp)
    800065f4:	6946                	ld	s2,80(sp)
    800065f6:	69a6                	ld	s3,72(sp)
    800065f8:	6a06                	ld	s4,64(sp)
    800065fa:	7ae2                	ld	s5,56(sp)
    800065fc:	7b42                	ld	s6,48(sp)
    800065fe:	7ba2                	ld	s7,40(sp)
    80006600:	7c02                	ld	s8,32(sp)
    80006602:	6ce2                	ld	s9,24(sp)
    80006604:	6d42                	ld	s10,16(sp)
    80006606:	6165                	addi	sp,sp,112
    80006608:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000660a:	0001f697          	auipc	a3,0x1f
    8000660e:	9f66b683          	ld	a3,-1546(a3) # 80025000 <disk+0x2000>
    80006612:	96ba                	add	a3,a3,a4
    80006614:	4609                	li	a2,2
    80006616:	00c69623          	sh	a2,12(a3)
    8000661a:	b5c9                	j	800064dc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000661c:	f9042583          	lw	a1,-112(s0)
    80006620:	20058793          	addi	a5,a1,512
    80006624:	0792                	slli	a5,a5,0x4
    80006626:	0001d517          	auipc	a0,0x1d
    8000662a:	a8250513          	addi	a0,a0,-1406 # 800230a8 <disk+0xa8>
    8000662e:	953e                	add	a0,a0,a5
  if(write)
    80006630:	e20d11e3          	bnez	s10,80006452 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006634:	20058713          	addi	a4,a1,512
    80006638:	00471693          	slli	a3,a4,0x4
    8000663c:	0001d717          	auipc	a4,0x1d
    80006640:	9c470713          	addi	a4,a4,-1596 # 80023000 <disk>
    80006644:	9736                	add	a4,a4,a3
    80006646:	0a072423          	sw	zero,168(a4)
    8000664a:	b505                	j	8000646a <virtio_disk_rw+0xf4>

000000008000664c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000664c:	1101                	addi	sp,sp,-32
    8000664e:	ec06                	sd	ra,24(sp)
    80006650:	e822                	sd	s0,16(sp)
    80006652:	e426                	sd	s1,8(sp)
    80006654:	e04a                	sd	s2,0(sp)
    80006656:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006658:	0001f517          	auipc	a0,0x1f
    8000665c:	ad050513          	addi	a0,a0,-1328 # 80025128 <disk+0x2128>
    80006660:	ffffa097          	auipc	ra,0xffffa
    80006664:	584080e7          	jalr	1412(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006668:	10001737          	lui	a4,0x10001
    8000666c:	533c                	lw	a5,96(a4)
    8000666e:	8b8d                	andi	a5,a5,3
    80006670:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006672:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006676:	0001f797          	auipc	a5,0x1f
    8000667a:	98a78793          	addi	a5,a5,-1654 # 80025000 <disk+0x2000>
    8000667e:	6b94                	ld	a3,16(a5)
    80006680:	0207d703          	lhu	a4,32(a5)
    80006684:	0026d783          	lhu	a5,2(a3)
    80006688:	06f70163          	beq	a4,a5,800066ea <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000668c:	0001d917          	auipc	s2,0x1d
    80006690:	97490913          	addi	s2,s2,-1676 # 80023000 <disk>
    80006694:	0001f497          	auipc	s1,0x1f
    80006698:	96c48493          	addi	s1,s1,-1684 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000669c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066a0:	6898                	ld	a4,16(s1)
    800066a2:	0204d783          	lhu	a5,32(s1)
    800066a6:	8b9d                	andi	a5,a5,7
    800066a8:	078e                	slli	a5,a5,0x3
    800066aa:	97ba                	add	a5,a5,a4
    800066ac:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800066ae:	20078713          	addi	a4,a5,512
    800066b2:	0712                	slli	a4,a4,0x4
    800066b4:	974a                	add	a4,a4,s2
    800066b6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800066ba:	e731                	bnez	a4,80006706 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800066bc:	20078793          	addi	a5,a5,512
    800066c0:	0792                	slli	a5,a5,0x4
    800066c2:	97ca                	add	a5,a5,s2
    800066c4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800066c6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800066ca:	ffffc097          	auipc	ra,0xffffc
    800066ce:	fa8080e7          	jalr	-88(ra) # 80002672 <wakeup>

    disk.used_idx += 1;
    800066d2:	0204d783          	lhu	a5,32(s1)
    800066d6:	2785                	addiw	a5,a5,1
    800066d8:	17c2                	slli	a5,a5,0x30
    800066da:	93c1                	srli	a5,a5,0x30
    800066dc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066e0:	6898                	ld	a4,16(s1)
    800066e2:	00275703          	lhu	a4,2(a4)
    800066e6:	faf71be3          	bne	a4,a5,8000669c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800066ea:	0001f517          	auipc	a0,0x1f
    800066ee:	a3e50513          	addi	a0,a0,-1474 # 80025128 <disk+0x2128>
    800066f2:	ffffa097          	auipc	ra,0xffffa
    800066f6:	5a6080e7          	jalr	1446(ra) # 80000c98 <release>
}
    800066fa:	60e2                	ld	ra,24(sp)
    800066fc:	6442                	ld	s0,16(sp)
    800066fe:	64a2                	ld	s1,8(sp)
    80006700:	6902                	ld	s2,0(sp)
    80006702:	6105                	addi	sp,sp,32
    80006704:	8082                	ret
      panic("virtio_disk_intr status");
    80006706:	00002517          	auipc	a0,0x2
    8000670a:	17a50513          	addi	a0,a0,378 # 80008880 <syscalls+0x3b0>
    8000670e:	ffffa097          	auipc	ra,0xffffa
    80006712:	e30080e7          	jalr	-464(ra) # 8000053e <panic>

0000000080006716 <cas>:
    80006716:	100522af          	lr.w	t0,(a0)
    8000671a:	00b29563          	bne	t0,a1,80006724 <fail>
    8000671e:	18c5252f          	sc.w	a0,a2,(a0)
    80006722:	8082                	ret

0000000080006724 <fail>:
    80006724:	4505                	li	a0,1
    80006726:	8082                	ret
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
