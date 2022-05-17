
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
    80000068:	0cc78793          	addi	a5,a5,204 # 80006130 <timervec>
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
    80000130:	860080e7          	jalr	-1952(ra) # 8000298c <either_copyin>
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
    800001c8:	b40080e7          	jalr	-1216(ra) # 80001d04 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	32e080e7          	jalr	814(ra) # 80002502 <sleep>
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
    80000214:	726080e7          	jalr	1830(ra) # 80002936 <either_copyout>
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
    800002f6:	6f0080e7          	jalr	1776(ra) # 800029e2 <procdump>
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
    8000044a:	25a080e7          	jalr	602(ra) # 800026a0 <wakeup>
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
    800008a4:	e00080e7          	jalr	-512(ra) # 800026a0 <wakeup>
    
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
    80000930:	bd6080e7          	jalr	-1066(ra) # 80002502 <sleep>
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
    80000b82:	164080e7          	jalr	356(ra) # 80001ce2 <mycpu>
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
    80000bb4:	132080e7          	jalr	306(ra) # 80001ce2 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	126080e7          	jalr	294(ra) # 80001ce2 <mycpu>
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
    80000bd8:	10e080e7          	jalr	270(ra) # 80001ce2 <mycpu>
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
    80000c18:	0ce080e7          	jalr	206(ra) # 80001ce2 <mycpu>
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
    80000c44:	0a2080e7          	jalr	162(ra) # 80001ce2 <mycpu>
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
    80000e9a:	e3c080e7          	jalr	-452(ra) # 80001cd2 <cpuid>
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
    80000eb6:	e20080e7          	jalr	-480(ra) # 80001cd2 <cpuid>
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
    80000ed8:	d3a080e7          	jalr	-710(ra) # 80002c0e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	294080e7          	jalr	660(ra) # 80006170 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	41c080e7          	jalr	1052(ra) # 80002300 <scheduler>
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
    80000f48:	c06080e7          	jalr	-1018(ra) # 80001b4a <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	c9a080e7          	jalr	-870(ra) # 80002be6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	cba080e7          	jalr	-838(ra) # 80002c0e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	1fe080e7          	jalr	510(ra) # 8000615a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	20c080e7          	jalr	524(ra) # 80006170 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	3e4080e7          	jalr	996(ra) # 80003350 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	a74080e7          	jalr	-1420(ra) # 800039e8 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	a1e080e7          	jalr	-1506(ra) # 8000499a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	30e080e7          	jalr	782(ra) # 80006292 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	0f8080e7          	jalr	248(ra) # 80002084 <userinit>
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
    80001244:	874080e7          	jalr	-1932(ra) # 80001ab4 <proc_mapstacks>
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
    8000185e:	f1c080e7          	jalr	-228(ra) # 80006776 <cas>
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

000000008000189c <set_prev_proc>:


void set_prev_proc(struct proc *p, int value){
    8000189c:	1141                	addi	sp,sp,-16
    8000189e:	e422                	sd	s0,8(sp)
    800018a0:	0800                	addi	s0,sp,16
  p->prev_proc = value; 
    800018a2:	16b52823          	sw	a1,368(a0)
}
    800018a6:	6422                	ld	s0,8(sp)
    800018a8:	0141                	addi	sp,sp,16
    800018aa:	8082                	ret

00000000800018ac <set_next_proc>:

void set_next_proc(struct proc *p, int value){
    800018ac:	1141                	addi	sp,sp,-16
    800018ae:	e422                	sd	s0,8(sp)
    800018b0:	0800                	addi	s0,sp,16
  p->next_proc = value; 
    800018b2:	16b52623          	sw	a1,364(a0)
}
    800018b6:	6422                	ld	s0,8(sp)
    800018b8:	0141                	addi	sp,sp,16
    800018ba:	8082                	ret

00000000800018bc <append>:

void 
append(struct linked_list *lst, struct proc *p){
    800018bc:	7139                	addi	sp,sp,-64
    800018be:	fc06                	sd	ra,56(sp)
    800018c0:	f822                	sd	s0,48(sp)
    800018c2:	f426                	sd	s1,40(sp)
    800018c4:	f04a                	sd	s2,32(sp)
    800018c6:	ec4e                	sd	s3,24(sp)
    800018c8:	e852                	sd	s4,16(sp)
    800018ca:	e456                	sd	s5,8(sp)
    800018cc:	0080                	addi	s0,sp,64
    800018ce:	84aa                	mv	s1,a0
    800018d0:	892e                	mv	s2,a1
  acquire(&lst->head_lock);
    800018d2:	00850993          	addi	s3,a0,8
    800018d6:	854e                	mv	a0,s3
    800018d8:	fffff097          	auipc	ra,0xfffff
    800018dc:	30c080e7          	jalr	780(ra) # 80000be4 <acquire>
  if(isEmpty(lst)){
    800018e0:	4098                	lw	a4,0(s1)
    800018e2:	57fd                	li	a5,-1
    800018e4:	04f71063          	bne	a4,a5,80001924 <append+0x68>
    lst->head = p->proc_ind;
    800018e8:	17492783          	lw	a5,372(s2) # 1174 <_entry-0x7fffee8c>
    800018ec:	c09c                	sw	a5,0(s1)
    release(&lst->head_lock);
    800018ee:	854e                	mv	a0,s3
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	3a8080e7          	jalr	936(ra) # 80000c98 <release>
    release(&lst->head_lock);
    set_next_proc(&proc[lst->tail], p->proc_ind);  // update next proc of the curr tail
    set_prev_proc(p, proc[lst->tail].proc_ind); // update the prev proc of the new proc
    release(&proc[lst->tail].list_lock);
  }
  acquire(&lst->head_lock);
    800018f8:	854e                	mv	a0,s3
    800018fa:	fffff097          	auipc	ra,0xfffff
    800018fe:	2ea080e7          	jalr	746(ra) # 80000be4 <acquire>
  lst->tail = p->proc_ind;
    80001902:	17492783          	lw	a5,372(s2)
    80001906:	c0dc                	sw	a5,4(s1)
  release(&lst->head_lock);
    80001908:	854e                	mv	a0,s3
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	38e080e7          	jalr	910(ra) # 80000c98 <release>
}
    80001912:	70e2                	ld	ra,56(sp)
    80001914:	7442                	ld	s0,48(sp)
    80001916:	74a2                	ld	s1,40(sp)
    80001918:	7902                	ld	s2,32(sp)
    8000191a:	69e2                	ld	s3,24(sp)
    8000191c:	6a42                	ld	s4,16(sp)
    8000191e:	6aa2                	ld	s5,8(sp)
    80001920:	6121                	addi	sp,sp,64
    80001922:	8082                	ret
    acquire(&proc[lst->tail].list_lock);
    80001924:	40c8                	lw	a0,4(s1)
    80001926:	19000a93          	li	s5,400
    8000192a:	03550533          	mul	a0,a0,s5
    8000192e:	17850513          	addi	a0,a0,376
    80001932:	00010a17          	auipc	s4,0x10
    80001936:	edea0a13          	addi	s4,s4,-290 # 80011810 <proc>
    8000193a:	9552                	add	a0,a0,s4
    8000193c:	fffff097          	auipc	ra,0xfffff
    80001940:	2a8080e7          	jalr	680(ra) # 80000be4 <acquire>
    release(&lst->head_lock);
    80001944:	854e                	mv	a0,s3
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	352080e7          	jalr	850(ra) # 80000c98 <release>
    set_next_proc(&proc[lst->tail], p->proc_ind);  // update next proc of the curr tail
    8000194e:	40dc                	lw	a5,4(s1)
    80001950:	17492703          	lw	a4,372(s2)
  p->next_proc = value; 
    80001954:	035787b3          	mul	a5,a5,s5
    80001958:	97d2                	add	a5,a5,s4
    8000195a:	16e7a623          	sw	a4,364(a5)
    set_prev_proc(p, proc[lst->tail].proc_ind); // update the prev proc of the new proc
    8000195e:	40dc                	lw	a5,4(s1)
    80001960:	035787b3          	mul	a5,a5,s5
    80001964:	97d2                	add	a5,a5,s4
    80001966:	1747a783          	lw	a5,372(a5)
  p->prev_proc = value; 
    8000196a:	16f92823          	sw	a5,368(s2)
    release(&proc[lst->tail].list_lock);
    8000196e:	40c8                	lw	a0,4(s1)
    80001970:	03550533          	mul	a0,a0,s5
    80001974:	17850513          	addi	a0,a0,376
    80001978:	9552                	add	a0,a0,s4
    8000197a:	fffff097          	auipc	ra,0xfffff
    8000197e:	31e080e7          	jalr	798(ra) # 80000c98 <release>
    80001982:	bf9d                	j	800018f8 <append+0x3c>

0000000080001984 <remove>:

void 
remove(struct linked_list *lst, struct proc *p){
    80001984:	7179                	addi	sp,sp,-48
    80001986:	f406                	sd	ra,40(sp)
    80001988:	f022                	sd	s0,32(sp)
    8000198a:	ec26                	sd	s1,24(sp)
    8000198c:	e84a                	sd	s2,16(sp)
    8000198e:	e44e                	sd	s3,8(sp)
    80001990:	e052                	sd	s4,0(sp)
    80001992:	1800                	addi	s0,sp,48
    80001994:	892a                	mv	s2,a0
    80001996:	84ae                	mv	s1,a1
  acquire(&lst->head_lock);
    80001998:	00850993          	addi	s3,a0,8
    8000199c:	854e                	mv	a0,s3
    8000199e:	fffff097          	auipc	ra,0xfffff
    800019a2:	246080e7          	jalr	582(ra) # 80000be4 <acquire>
  h = lst->head == -1;
    800019a6:	00092783          	lw	a5,0(s2)
  if(isEmpty(lst)){
    800019aa:	577d                	li	a4,-1
    800019ac:	0ae78263          	beq	a5,a4,80001a50 <remove+0xcc>
    release(&lst->head_lock);
    panic("list is empty\n");
  }

  if(lst->head == p->proc_ind){ // the required proc is the head
    800019b0:	1744a703          	lw	a4,372(s1)
    800019b4:	0af70b63          	beq	a4,a5,80001a6a <remove+0xe6>
      lst->tail = -1;
    }
    release(&lst->head_lock);
  }
  else{
    if (lst->tail == p->proc_ind) {
    800019b8:	00492783          	lw	a5,4(s2)
    800019bc:	0ee78763          	beq	a5,a4,80001aaa <remove+0x126>
      lst->tail = p->prev_proc;
    }
    release(&lst->head_lock); 
    800019c0:	854e                	mv	a0,s3
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	2d6080e7          	jalr	726(ra) # 80000c98 <release>
    acquire(&p->list_lock);
    800019ca:	17848993          	addi	s3,s1,376
    800019ce:	854e                	mv	a0,s3
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	214080e7          	jalr	532(ra) # 80000be4 <acquire>
    acquire(&proc[p->prev_proc].list_lock);
    800019d8:	1704a503          	lw	a0,368(s1)
    800019dc:	19000a13          	li	s4,400
    800019e0:	03450533          	mul	a0,a0,s4
    800019e4:	17850513          	addi	a0,a0,376
    800019e8:	00010917          	auipc	s2,0x10
    800019ec:	e2890913          	addi	s2,s2,-472 # 80011810 <proc>
    800019f0:	954a                	add	a0,a0,s2
    800019f2:	fffff097          	auipc	ra,0xfffff
    800019f6:	1f2080e7          	jalr	498(ra) # 80000be4 <acquire>
    set_next_proc(&proc[p->prev_proc], p->next_proc);
    800019fa:	1704a703          	lw	a4,368(s1)
    800019fe:	16c4a783          	lw	a5,364(s1)
  p->next_proc = value; 
    80001a02:	03470733          	mul	a4,a4,s4
    80001a06:	974a                	add	a4,a4,s2
    80001a08:	16f72623          	sw	a5,364(a4)
    set_prev_proc(&proc[p->next_proc], p->prev_proc);
    80001a0c:	1704a503          	lw	a0,368(s1)
  p->prev_proc = value; 
    80001a10:	034787b3          	mul	a5,a5,s4
    80001a14:	97ca                	add	a5,a5,s2
    80001a16:	16a7a823          	sw	a0,368(a5)
    release(&proc[p->prev_proc].list_lock);
    80001a1a:	03450533          	mul	a0,a0,s4
    80001a1e:	17850513          	addi	a0,a0,376
    80001a22:	954a                	add	a0,a0,s2
    80001a24:	fffff097          	auipc	ra,0xfffff
    80001a28:	274080e7          	jalr	628(ra) # 80000c98 <release>
    release(&p->list_lock);
    80001a2c:	854e                	mv	a0,s3
    80001a2e:	fffff097          	auipc	ra,0xfffff
    80001a32:	26a080e7          	jalr	618(ra) # 80000c98 <release>
  p->prev_proc = -1;
    80001a36:	57fd                	li	a5,-1
    80001a38:	16f4a823          	sw	a5,368(s1)
  p->next_proc = -1;
    80001a3c:	16f4a623          	sw	a5,364(s1)
  }
  initialize_proc(p);
}
    80001a40:	70a2                	ld	ra,40(sp)
    80001a42:	7402                	ld	s0,32(sp)
    80001a44:	64e2                	ld	s1,24(sp)
    80001a46:	6942                	ld	s2,16(sp)
    80001a48:	69a2                	ld	s3,8(sp)
    80001a4a:	6a02                	ld	s4,0(sp)
    80001a4c:	6145                	addi	sp,sp,48
    80001a4e:	8082                	ret
    release(&lst->head_lock);
    80001a50:	854e                	mv	a0,s3
    80001a52:	fffff097          	auipc	ra,0xfffff
    80001a56:	246080e7          	jalr	582(ra) # 80000c98 <release>
    panic("list is empty\n");
    80001a5a:	00006517          	auipc	a0,0x6
    80001a5e:	77e50513          	addi	a0,a0,1918 # 800081d8 <digits+0x198>
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	adc080e7          	jalr	-1316(ra) # 8000053e <panic>
    lst->head = p->next_proc;
    80001a6a:	16c4a783          	lw	a5,364(s1)
    80001a6e:	00f92023          	sw	a5,0(s2)
  p->prev_proc = value; 
    80001a72:	19000713          	li	a4,400
    80001a76:	02e787b3          	mul	a5,a5,a4
    80001a7a:	00010717          	auipc	a4,0x10
    80001a7e:	d9670713          	addi	a4,a4,-618 # 80011810 <proc>
    80001a82:	97ba                	add	a5,a5,a4
    80001a84:	577d                	li	a4,-1
    80001a86:	16e7a823          	sw	a4,368(a5)
    if(lst->tail == p->proc_ind){
    80001a8a:	00492703          	lw	a4,4(s2)
    80001a8e:	1744a783          	lw	a5,372(s1)
    80001a92:	00f70863          	beq	a4,a5,80001aa2 <remove+0x11e>
    release(&lst->head_lock);
    80001a96:	854e                	mv	a0,s3
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	200080e7          	jalr	512(ra) # 80000c98 <release>
    80001aa0:	bf59                	j	80001a36 <remove+0xb2>
      lst->tail = -1;
    80001aa2:	57fd                	li	a5,-1
    80001aa4:	00f92223          	sw	a5,4(s2)
    80001aa8:	b7fd                	j	80001a96 <remove+0x112>
      lst->tail = p->prev_proc;
    80001aaa:	1704a783          	lw	a5,368(s1)
    80001aae:	00f92223          	sw	a5,4(s2)
    80001ab2:	b739                	j	800019c0 <remove+0x3c>

0000000080001ab4 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001ab4:	7139                	addi	sp,sp,-64
    80001ab6:	fc06                	sd	ra,56(sp)
    80001ab8:	f822                	sd	s0,48(sp)
    80001aba:	f426                	sd	s1,40(sp)
    80001abc:	f04a                	sd	s2,32(sp)
    80001abe:	ec4e                	sd	s3,24(sp)
    80001ac0:	e852                	sd	s4,16(sp)
    80001ac2:	e456                	sd	s5,8(sp)
    80001ac4:	e05a                	sd	s6,0(sp)
    80001ac6:	0080                	addi	s0,sp,64
    80001ac8:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001aca:	00010497          	auipc	s1,0x10
    80001ace:	d4648493          	addi	s1,s1,-698 # 80011810 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001ad2:	8b26                	mv	s6,s1
    80001ad4:	00006a97          	auipc	s5,0x6
    80001ad8:	52ca8a93          	addi	s5,s5,1324 # 80008000 <etext>
    80001adc:	04000937          	lui	s2,0x4000
    80001ae0:	197d                	addi	s2,s2,-1
    80001ae2:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ae4:	00016a17          	auipc	s4,0x16
    80001ae8:	12ca0a13          	addi	s4,s4,300 # 80017c10 <tickslock>
    char *pa = kalloc();
    80001aec:	fffff097          	auipc	ra,0xfffff
    80001af0:	008080e7          	jalr	8(ra) # 80000af4 <kalloc>
    80001af4:	862a                	mv	a2,a0
    if(pa == 0)
    80001af6:	c131                	beqz	a0,80001b3a <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001af8:	416485b3          	sub	a1,s1,s6
    80001afc:	8591                	srai	a1,a1,0x4
    80001afe:	000ab783          	ld	a5,0(s5)
    80001b02:	02f585b3          	mul	a1,a1,a5
    80001b06:	2585                	addiw	a1,a1,1
    80001b08:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b0c:	4719                	li	a4,6
    80001b0e:	6685                	lui	a3,0x1
    80001b10:	40b905b3          	sub	a1,s2,a1
    80001b14:	854e                	mv	a0,s3
    80001b16:	fffff097          	auipc	ra,0xfffff
    80001b1a:	63a080e7          	jalr	1594(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b1e:	19048493          	addi	s1,s1,400
    80001b22:	fd4495e3          	bne	s1,s4,80001aec <proc_mapstacks+0x38>
  }
}
    80001b26:	70e2                	ld	ra,56(sp)
    80001b28:	7442                	ld	s0,48(sp)
    80001b2a:	74a2                	ld	s1,40(sp)
    80001b2c:	7902                	ld	s2,32(sp)
    80001b2e:	69e2                	ld	s3,24(sp)
    80001b30:	6a42                	ld	s4,16(sp)
    80001b32:	6aa2                	ld	s5,8(sp)
    80001b34:	6b02                	ld	s6,0(sp)
    80001b36:	6121                	addi	sp,sp,64
    80001b38:	8082                	ret
      panic("kalloc");
    80001b3a:	00006517          	auipc	a0,0x6
    80001b3e:	6ae50513          	addi	a0,a0,1710 # 800081e8 <digits+0x1a8>
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	9fc080e7          	jalr	-1540(ra) # 8000053e <panic>

0000000080001b4a <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001b4a:	711d                	addi	sp,sp,-96
    80001b4c:	ec86                	sd	ra,88(sp)
    80001b4e:	e8a2                	sd	s0,80(sp)
    80001b50:	e4a6                	sd	s1,72(sp)
    80001b52:	e0ca                	sd	s2,64(sp)
    80001b54:	fc4e                	sd	s3,56(sp)
    80001b56:	f852                	sd	s4,48(sp)
    80001b58:	f456                	sd	s5,40(sp)
    80001b5a:	f05a                	sd	s6,32(sp)
    80001b5c:	ec5e                	sd	s7,24(sp)
    80001b5e:	e862                	sd	s8,16(sp)
    80001b60:	e466                	sd	s9,8(sp)
    80001b62:	e06a                	sd	s10,0(sp)
    80001b64:	1080                	addi	s0,sp,96
  // Adding all processes to UNUSED list.
  struct proc *p;
  struct cpu *c;
  int i = 0;

  initlock(&sleeping_list.head_lock, "sleeping_list_head_lock");
    80001b66:	00006597          	auipc	a1,0x6
    80001b6a:	68a58593          	addi	a1,a1,1674 # 800081f0 <digits+0x1b0>
    80001b6e:	00007517          	auipc	a0,0x7
    80001b72:	d4a50513          	addi	a0,a0,-694 # 800088b8 <sleeping_list+0x8>
    80001b76:	fffff097          	auipc	ra,0xfffff
    80001b7a:	fde080e7          	jalr	-34(ra) # 80000b54 <initlock>
  initlock(&zombie_list.head_lock, "zombie_list_head_lock");
    80001b7e:	00006597          	auipc	a1,0x6
    80001b82:	68a58593          	addi	a1,a1,1674 # 80008208 <digits+0x1c8>
    80001b86:	00007517          	auipc	a0,0x7
    80001b8a:	d5250513          	addi	a0,a0,-686 # 800088d8 <zombie_list+0x8>
    80001b8e:	fffff097          	auipc	ra,0xfffff
    80001b92:	fc6080e7          	jalr	-58(ra) # 80000b54 <initlock>
  initlock(&unused_list.head_lock, "unused_list_head_lock");
    80001b96:	00006597          	auipc	a1,0x6
    80001b9a:	68a58593          	addi	a1,a1,1674 # 80008220 <digits+0x1e0>
    80001b9e:	00007517          	auipc	a0,0x7
    80001ba2:	d5a50513          	addi	a0,a0,-678 # 800088f8 <unused_list+0x8>
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	fae080e7          	jalr	-82(ra) # 80000b54 <initlock>
  initlock(&pid_lock, "nextpid");
    80001bae:	00006597          	auipc	a1,0x6
    80001bb2:	68a58593          	addi	a1,a1,1674 # 80008238 <digits+0x1f8>
    80001bb6:	00010517          	auipc	a0,0x10
    80001bba:	c2a50513          	addi	a0,a0,-982 # 800117e0 <pid_lock>
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	f96080e7          	jalr	-106(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001bc6:	00006597          	auipc	a1,0x6
    80001bca:	67a58593          	addi	a1,a1,1658 # 80008240 <digits+0x200>
    80001bce:	00010517          	auipc	a0,0x10
    80001bd2:	c2a50513          	addi	a0,a0,-982 # 800117f8 <wait_lock>
    80001bd6:	fffff097          	auipc	ra,0xfffff
    80001bda:	f7e080e7          	jalr	-130(ra) # 80000b54 <initlock>
  int i = 0;
    80001bde:	4901                	li	s2,0

  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be0:	00010497          	auipc	s1,0x10
    80001be4:	c3048493          	addi	s1,s1,-976 # 80011810 <proc>
      initlock(&p->lock, "proc");
    80001be8:	00006d17          	auipc	s10,0x6
    80001bec:	668d0d13          	addi	s10,s10,1640 # 80008250 <digits+0x210>
      initlock(&p->list_lock, "list_lock");
    80001bf0:	00006c97          	auipc	s9,0x6
    80001bf4:	668c8c93          	addi	s9,s9,1640 # 80008258 <digits+0x218>
      p->kstack = KSTACK((int) (p - proc));
    80001bf8:	8c26                	mv	s8,s1
    80001bfa:	00006b97          	auipc	s7,0x6
    80001bfe:	406b8b93          	addi	s7,s7,1030 # 80008000 <etext>
    80001c02:	04000a37          	lui	s4,0x4000
    80001c06:	1a7d                	addi	s4,s4,-1
    80001c08:	0a32                	slli	s4,s4,0xc
      p->proc_ind = i;
      i=i+1;
      p->prev_proc = -1;
    80001c0a:	59fd                	li	s3,-1
      p->next_proc = -1;
      append(&unused_list, p); 
    80001c0c:	00007b17          	auipc	s6,0x7
    80001c10:	ce4b0b13          	addi	s6,s6,-796 # 800088f0 <unused_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c14:	00016a97          	auipc	s5,0x16
    80001c18:	ffca8a93          	addi	s5,s5,-4 # 80017c10 <tickslock>
      initlock(&p->lock, "proc");
    80001c1c:	85ea                	mv	a1,s10
    80001c1e:	8526                	mv	a0,s1
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	f34080e7          	jalr	-204(ra) # 80000b54 <initlock>
      initlock(&p->list_lock, "list_lock");
    80001c28:	85e6                	mv	a1,s9
    80001c2a:	17848513          	addi	a0,s1,376
    80001c2e:	fffff097          	auipc	ra,0xfffff
    80001c32:	f26080e7          	jalr	-218(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001c36:	418487b3          	sub	a5,s1,s8
    80001c3a:	8791                	srai	a5,a5,0x4
    80001c3c:	000bb703          	ld	a4,0(s7)
    80001c40:	02e787b3          	mul	a5,a5,a4
    80001c44:	2785                	addiw	a5,a5,1
    80001c46:	00d7979b          	slliw	a5,a5,0xd
    80001c4a:	40fa07b3          	sub	a5,s4,a5
    80001c4e:	e0bc                	sd	a5,64(s1)
      p->proc_ind = i;
    80001c50:	1724aa23          	sw	s2,372(s1)
      i=i+1;
    80001c54:	2905                	addiw	s2,s2,1
      p->prev_proc = -1;
    80001c56:	1734a823          	sw	s3,368(s1)
      p->next_proc = -1;
    80001c5a:	1734a623          	sw	s3,364(s1)
      append(&unused_list, p); 
    80001c5e:	85a6                	mv	a1,s1
    80001c60:	855a                	mv	a0,s6
    80001c62:	00000097          	auipc	ra,0x0
    80001c66:	c5a080e7          	jalr	-934(ra) # 800018bc <append>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c6a:	19048493          	addi	s1,s1,400
    80001c6e:	fb5497e3          	bne	s1,s5,80001c1c <procinit+0xd2>
  }

  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001c72:	0000f497          	auipc	s1,0xf
    80001c76:	62e48493          	addi	s1,s1,1582 # 800112a0 <cpus>
    c->runnable_list = (struct linked_list){-1};
    80001c7a:	5a7d                	li	s4,-1
    initlock(&c->runnable_list.head_lock, "cpu_runnable_list_head_lock");
    80001c7c:	00006997          	auipc	s3,0x6
    80001c80:	5ec98993          	addi	s3,s3,1516 # 80008268 <digits+0x228>
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001c84:	00010917          	auipc	s2,0x10
    80001c88:	b5c90913          	addi	s2,s2,-1188 # 800117e0 <pid_lock>
    c->runnable_list = (struct linked_list){-1};
    80001c8c:	0804b423          	sd	zero,136(s1)
    80001c90:	0804b823          	sd	zero,144(s1)
    80001c94:	0804bc23          	sd	zero,152(s1)
    80001c98:	0a04b023          	sd	zero,160(s1)
    80001c9c:	0944a423          	sw	s4,136(s1)
    initlock(&c->runnable_list.head_lock, "cpu_runnable_list_head_lock");
    80001ca0:	85ce                	mv	a1,s3
    80001ca2:	09048513          	addi	a0,s1,144
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	eae080e7          	jalr	-338(ra) # 80000b54 <initlock>
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001cae:	0a848493          	addi	s1,s1,168
    80001cb2:	fd249de3          	bne	s1,s2,80001c8c <procinit+0x142>
  }
}
    80001cb6:	60e6                	ld	ra,88(sp)
    80001cb8:	6446                	ld	s0,80(sp)
    80001cba:	64a6                	ld	s1,72(sp)
    80001cbc:	6906                	ld	s2,64(sp)
    80001cbe:	79e2                	ld	s3,56(sp)
    80001cc0:	7a42                	ld	s4,48(sp)
    80001cc2:	7aa2                	ld	s5,40(sp)
    80001cc4:	7b02                	ld	s6,32(sp)
    80001cc6:	6be2                	ld	s7,24(sp)
    80001cc8:	6c42                	ld	s8,16(sp)
    80001cca:	6ca2                	ld	s9,8(sp)
    80001ccc:	6d02                	ld	s10,0(sp)
    80001cce:	6125                	addi	sp,sp,96
    80001cd0:	8082                	ret

0000000080001cd2 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001cd2:	1141                	addi	sp,sp,-16
    80001cd4:	e422                	sd	s0,8(sp)
    80001cd6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001cd8:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001cda:	2501                	sext.w	a0,a0
    80001cdc:	6422                	ld	s0,8(sp)
    80001cde:	0141                	addi	sp,sp,16
    80001ce0:	8082                	ret

0000000080001ce2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001ce2:	1141                	addi	sp,sp,-16
    80001ce4:	e422                	sd	s0,8(sp)
    80001ce6:	0800                	addi	s0,sp,16
    80001ce8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001cea:	2781                	sext.w	a5,a5
    80001cec:	0a800513          	li	a0,168
    80001cf0:	02a787b3          	mul	a5,a5,a0
  return c;
}
    80001cf4:	0000f517          	auipc	a0,0xf
    80001cf8:	5ac50513          	addi	a0,a0,1452 # 800112a0 <cpus>
    80001cfc:	953e                	add	a0,a0,a5
    80001cfe:	6422                	ld	s0,8(sp)
    80001d00:	0141                	addi	sp,sp,16
    80001d02:	8082                	ret

0000000080001d04 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001d04:	1101                	addi	sp,sp,-32
    80001d06:	ec06                	sd	ra,24(sp)
    80001d08:	e822                	sd	s0,16(sp)
    80001d0a:	e426                	sd	s1,8(sp)
    80001d0c:	1000                	addi	s0,sp,32
  push_off();
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	e8a080e7          	jalr	-374(ra) # 80000b98 <push_off>
    80001d16:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001d18:	2781                	sext.w	a5,a5
    80001d1a:	0a800713          	li	a4,168
    80001d1e:	02e787b3          	mul	a5,a5,a4
    80001d22:	0000f717          	auipc	a4,0xf
    80001d26:	57e70713          	addi	a4,a4,1406 # 800112a0 <cpus>
    80001d2a:	97ba                	add	a5,a5,a4
    80001d2c:	6384                	ld	s1,0(a5)
  pop_off();
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	f0a080e7          	jalr	-246(ra) # 80000c38 <pop_off>
  return p;
}
    80001d36:	8526                	mv	a0,s1
    80001d38:	60e2                	ld	ra,24(sp)
    80001d3a:	6442                	ld	s0,16(sp)
    80001d3c:	64a2                	ld	s1,8(sp)
    80001d3e:	6105                	addi	sp,sp,32
    80001d40:	8082                	ret

0000000080001d42 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001d42:	1141                	addi	sp,sp,-16
    80001d44:	e406                	sd	ra,8(sp)
    80001d46:	e022                	sd	s0,0(sp)
    80001d48:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001d4a:	00000097          	auipc	ra,0x0
    80001d4e:	fba080e7          	jalr	-70(ra) # 80001d04 <myproc>
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	f46080e7          	jalr	-186(ra) # 80000c98 <release>

  if (first) {
    80001d5a:	00007797          	auipc	a5,0x7
    80001d5e:	b467a783          	lw	a5,-1210(a5) # 800088a0 <first.1738>
    80001d62:	eb89                	bnez	a5,80001d74 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001d64:	00001097          	auipc	ra,0x1
    80001d68:	ec2080e7          	jalr	-318(ra) # 80002c26 <usertrapret>
}
    80001d6c:	60a2                	ld	ra,8(sp)
    80001d6e:	6402                	ld	s0,0(sp)
    80001d70:	0141                	addi	sp,sp,16
    80001d72:	8082                	ret
    first = 0;
    80001d74:	00007797          	auipc	a5,0x7
    80001d78:	b207a623          	sw	zero,-1236(a5) # 800088a0 <first.1738>
    fsinit(ROOTDEV);
    80001d7c:	4505                	li	a0,1
    80001d7e:	00002097          	auipc	ra,0x2
    80001d82:	bea080e7          	jalr	-1046(ra) # 80003968 <fsinit>
    80001d86:	bff9                	j	80001d64 <forkret+0x22>

0000000080001d88 <allocpid>:
allocpid() {
    80001d88:	1101                	addi	sp,sp,-32
    80001d8a:	ec06                	sd	ra,24(sp)
    80001d8c:	e822                	sd	s0,16(sp)
    80001d8e:	e426                	sd	s1,8(sp)
    80001d90:	e04a                	sd	s2,0(sp)
    80001d92:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001d94:	00007917          	auipc	s2,0x7
    80001d98:	b1090913          	addi	s2,s2,-1264 # 800088a4 <nextpid>
    80001d9c:	00092483          	lw	s1,0(s2)
  while (cas(&nextpid, pid, nextpid + 1));
    80001da0:	0014861b          	addiw	a2,s1,1
    80001da4:	85a6                	mv	a1,s1
    80001da6:	854a                	mv	a0,s2
    80001da8:	00005097          	auipc	ra,0x5
    80001dac:	9ce080e7          	jalr	-1586(ra) # 80006776 <cas>
    80001db0:	2501                	sext.w	a0,a0
    80001db2:	f56d                	bnez	a0,80001d9c <allocpid+0x14>
}
    80001db4:	8526                	mv	a0,s1
    80001db6:	60e2                	ld	ra,24(sp)
    80001db8:	6442                	ld	s0,16(sp)
    80001dba:	64a2                	ld	s1,8(sp)
    80001dbc:	6902                	ld	s2,0(sp)
    80001dbe:	6105                	addi	sp,sp,32
    80001dc0:	8082                	ret

0000000080001dc2 <proc_pagetable>:
{
    80001dc2:	1101                	addi	sp,sp,-32
    80001dc4:	ec06                	sd	ra,24(sp)
    80001dc6:	e822                	sd	s0,16(sp)
    80001dc8:	e426                	sd	s1,8(sp)
    80001dca:	e04a                	sd	s2,0(sp)
    80001dcc:	1000                	addi	s0,sp,32
    80001dce:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001dd0:	fffff097          	auipc	ra,0xfffff
    80001dd4:	56a080e7          	jalr	1386(ra) # 8000133a <uvmcreate>
    80001dd8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001dda:	c121                	beqz	a0,80001e1a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ddc:	4729                	li	a4,10
    80001dde:	00005697          	auipc	a3,0x5
    80001de2:	22268693          	addi	a3,a3,546 # 80007000 <_trampoline>
    80001de6:	6605                	lui	a2,0x1
    80001de8:	040005b7          	lui	a1,0x4000
    80001dec:	15fd                	addi	a1,a1,-1
    80001dee:	05b2                	slli	a1,a1,0xc
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	2c0080e7          	jalr	704(ra) # 800010b0 <mappages>
    80001df8:	02054863          	bltz	a0,80001e28 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001dfc:	4719                	li	a4,6
    80001dfe:	05893683          	ld	a3,88(s2)
    80001e02:	6605                	lui	a2,0x1
    80001e04:	020005b7          	lui	a1,0x2000
    80001e08:	15fd                	addi	a1,a1,-1
    80001e0a:	05b6                	slli	a1,a1,0xd
    80001e0c:	8526                	mv	a0,s1
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	2a2080e7          	jalr	674(ra) # 800010b0 <mappages>
    80001e16:	02054163          	bltz	a0,80001e38 <proc_pagetable+0x76>
}
    80001e1a:	8526                	mv	a0,s1
    80001e1c:	60e2                	ld	ra,24(sp)
    80001e1e:	6442                	ld	s0,16(sp)
    80001e20:	64a2                	ld	s1,8(sp)
    80001e22:	6902                	ld	s2,0(sp)
    80001e24:	6105                	addi	sp,sp,32
    80001e26:	8082                	ret
    uvmfree(pagetable, 0);
    80001e28:	4581                	li	a1,0
    80001e2a:	8526                	mv	a0,s1
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	70a080e7          	jalr	1802(ra) # 80001536 <uvmfree>
    return 0;
    80001e34:	4481                	li	s1,0
    80001e36:	b7d5                	j	80001e1a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e38:	4681                	li	a3,0
    80001e3a:	4605                	li	a2,1
    80001e3c:	040005b7          	lui	a1,0x4000
    80001e40:	15fd                	addi	a1,a1,-1
    80001e42:	05b2                	slli	a1,a1,0xc
    80001e44:	8526                	mv	a0,s1
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	430080e7          	jalr	1072(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001e4e:	4581                	li	a1,0
    80001e50:	8526                	mv	a0,s1
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	6e4080e7          	jalr	1764(ra) # 80001536 <uvmfree>
    return 0;
    80001e5a:	4481                	li	s1,0
    80001e5c:	bf7d                	j	80001e1a <proc_pagetable+0x58>

0000000080001e5e <proc_freepagetable>:
{
    80001e5e:	1101                	addi	sp,sp,-32
    80001e60:	ec06                	sd	ra,24(sp)
    80001e62:	e822                	sd	s0,16(sp)
    80001e64:	e426                	sd	s1,8(sp)
    80001e66:	e04a                	sd	s2,0(sp)
    80001e68:	1000                	addi	s0,sp,32
    80001e6a:	84aa                	mv	s1,a0
    80001e6c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e6e:	4681                	li	a3,0
    80001e70:	4605                	li	a2,1
    80001e72:	040005b7          	lui	a1,0x4000
    80001e76:	15fd                	addi	a1,a1,-1
    80001e78:	05b2                	slli	a1,a1,0xc
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	3fc080e7          	jalr	1020(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e82:	4681                	li	a3,0
    80001e84:	4605                	li	a2,1
    80001e86:	020005b7          	lui	a1,0x2000
    80001e8a:	15fd                	addi	a1,a1,-1
    80001e8c:	05b6                	slli	a1,a1,0xd
    80001e8e:	8526                	mv	a0,s1
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	3e6080e7          	jalr	998(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001e98:	85ca                	mv	a1,s2
    80001e9a:	8526                	mv	a0,s1
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	69a080e7          	jalr	1690(ra) # 80001536 <uvmfree>
}
    80001ea4:	60e2                	ld	ra,24(sp)
    80001ea6:	6442                	ld	s0,16(sp)
    80001ea8:	64a2                	ld	s1,8(sp)
    80001eaa:	6902                	ld	s2,0(sp)
    80001eac:	6105                	addi	sp,sp,32
    80001eae:	8082                	ret

0000000080001eb0 <freeproc>:
{
    80001eb0:	1101                	addi	sp,sp,-32
    80001eb2:	ec06                	sd	ra,24(sp)
    80001eb4:	e822                	sd	s0,16(sp)
    80001eb6:	e426                	sd	s1,8(sp)
    80001eb8:	1000                	addi	s0,sp,32
    80001eba:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001ebc:	6d28                	ld	a0,88(a0)
    80001ebe:	c509                	beqz	a0,80001ec8 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	b38080e7          	jalr	-1224(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001ec8:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001ecc:	68a8                	ld	a0,80(s1)
    80001ece:	c511                	beqz	a0,80001eda <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ed0:	64ac                	ld	a1,72(s1)
    80001ed2:	00000097          	auipc	ra,0x0
    80001ed6:	f8c080e7          	jalr	-116(ra) # 80001e5e <proc_freepagetable>
  p->pagetable = 0;
    80001eda:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ede:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ee2:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ee6:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001eea:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001eee:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ef2:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ef6:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001efa:	0004ac23          	sw	zero,24(s1)
  remove(&zombie_list, p); 
    80001efe:	85a6                	mv	a1,s1
    80001f00:	00007517          	auipc	a0,0x7
    80001f04:	9d050513          	addi	a0,a0,-1584 # 800088d0 <zombie_list>
    80001f08:	00000097          	auipc	ra,0x0
    80001f0c:	a7c080e7          	jalr	-1412(ra) # 80001984 <remove>
  append(&unused_list, p); 
    80001f10:	85a6                	mv	a1,s1
    80001f12:	00007517          	auipc	a0,0x7
    80001f16:	9de50513          	addi	a0,a0,-1570 # 800088f0 <unused_list>
    80001f1a:	00000097          	auipc	ra,0x0
    80001f1e:	9a2080e7          	jalr	-1630(ra) # 800018bc <append>
}
    80001f22:	60e2                	ld	ra,24(sp)
    80001f24:	6442                	ld	s0,16(sp)
    80001f26:	64a2                	ld	s1,8(sp)
    80001f28:	6105                	addi	sp,sp,32
    80001f2a:	8082                	ret

0000000080001f2c <allocproc>:
{
    80001f2c:	715d                	addi	sp,sp,-80
    80001f2e:	e486                	sd	ra,72(sp)
    80001f30:	e0a2                	sd	s0,64(sp)
    80001f32:	fc26                	sd	s1,56(sp)
    80001f34:	f84a                	sd	s2,48(sp)
    80001f36:	f44e                	sd	s3,40(sp)
    80001f38:	f052                	sd	s4,32(sp)
    80001f3a:	ec56                	sd	s5,24(sp)
    80001f3c:	e85a                	sd	s6,16(sp)
    80001f3e:	e45e                	sd	s7,8(sp)
    80001f40:	0880                	addi	s0,sp,80
    while(!(unused_list.head == -1)){
    80001f42:	00007917          	auipc	s2,0x7
    80001f46:	9ae92903          	lw	s2,-1618(s2) # 800088f0 <unused_list>
    80001f4a:	57fd                	li	a5,-1
    80001f4c:	12f90a63          	beq	s2,a5,80002080 <allocproc+0x154>
    80001f50:	19000a93          	li	s5,400
    p = &proc[unused_list.head];
    80001f54:	00010a17          	auipc	s4,0x10
    80001f58:	8bca0a13          	addi	s4,s4,-1860 # 80011810 <proc>
    while(!(unused_list.head == -1)){
    80001f5c:	00007b97          	auipc	s7,0x7
    80001f60:	954b8b93          	addi	s7,s7,-1708 # 800088b0 <sleeping_list>
    80001f64:	5b7d                	li	s6,-1
    p = &proc[unused_list.head];
    80001f66:	035909b3          	mul	s3,s2,s5
    80001f6a:	014984b3          	add	s1,s3,s4
    acquire(&p->lock);
    80001f6e:	8526                	mv	a0,s1
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	c74080e7          	jalr	-908(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001f78:	4c9c                	lw	a5,24(s1)
    80001f7a:	c79d                	beqz	a5,80001fa8 <allocproc+0x7c>
      release(&p->lock);
    80001f7c:	8526                	mv	a0,s1
    80001f7e:	fffff097          	auipc	ra,0xfffff
    80001f82:	d1a080e7          	jalr	-742(ra) # 80000c98 <release>
    while(!(unused_list.head == -1)){
    80001f86:	040ba903          	lw	s2,64(s7)
    80001f8a:	fd691ee3          	bne	s2,s6,80001f66 <allocproc+0x3a>
  return 0;
    80001f8e:	4481                	li	s1,0
}
    80001f90:	8526                	mv	a0,s1
    80001f92:	60a6                	ld	ra,72(sp)
    80001f94:	6406                	ld	s0,64(sp)
    80001f96:	74e2                	ld	s1,56(sp)
    80001f98:	7942                	ld	s2,48(sp)
    80001f9a:	79a2                	ld	s3,40(sp)
    80001f9c:	7a02                	ld	s4,32(sp)
    80001f9e:	6ae2                	ld	s5,24(sp)
    80001fa0:	6b42                	ld	s6,16(sp)
    80001fa2:	6ba2                	ld	s7,8(sp)
    80001fa4:	6161                	addi	sp,sp,80
    80001fa6:	8082                	ret
      remove(&unused_list, p); 
    80001fa8:	85a6                	mv	a1,s1
    80001faa:	00007517          	auipc	a0,0x7
    80001fae:	94650513          	addi	a0,a0,-1722 # 800088f0 <unused_list>
    80001fb2:	00000097          	auipc	ra,0x0
    80001fb6:	9d2080e7          	jalr	-1582(ra) # 80001984 <remove>
  p->pid = allocpid();
    80001fba:	00000097          	auipc	ra,0x0
    80001fbe:	dce080e7          	jalr	-562(ra) # 80001d88 <allocpid>
    80001fc2:	19000a13          	li	s4,400
    80001fc6:	034907b3          	mul	a5,s2,s4
    80001fca:	00010a17          	auipc	s4,0x10
    80001fce:	846a0a13          	addi	s4,s4,-1978 # 80011810 <proc>
    80001fd2:	9a3e                	add	s4,s4,a5
    80001fd4:	02aa2823          	sw	a0,48(s4)
  p->state = USED;
    80001fd8:	4785                	li	a5,1
    80001fda:	00fa2c23          	sw	a5,24(s4)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	b16080e7          	jalr	-1258(ra) # 80000af4 <kalloc>
    80001fe6:	8aaa                	mv	s5,a0
    80001fe8:	04aa3c23          	sd	a0,88(s4)
    80001fec:	c135                	beqz	a0,80002050 <allocproc+0x124>
  p->pagetable = proc_pagetable(p);
    80001fee:	8526                	mv	a0,s1
    80001ff0:	00000097          	auipc	ra,0x0
    80001ff4:	dd2080e7          	jalr	-558(ra) # 80001dc2 <proc_pagetable>
    80001ff8:	8a2a                	mv	s4,a0
    80001ffa:	19000793          	li	a5,400
    80001ffe:	02f90733          	mul	a4,s2,a5
    80002002:	00010797          	auipc	a5,0x10
    80002006:	80e78793          	addi	a5,a5,-2034 # 80011810 <proc>
    8000200a:	97ba                	add	a5,a5,a4
    8000200c:	eba8                	sd	a0,80(a5)
  if(p->pagetable == 0){
    8000200e:	cd29                	beqz	a0,80002068 <allocproc+0x13c>
  memset(&p->context, 0, sizeof(p->context));
    80002010:	06098513          	addi	a0,s3,96
    80002014:	0000f997          	auipc	s3,0xf
    80002018:	7fc98993          	addi	s3,s3,2044 # 80011810 <proc>
    8000201c:	07000613          	li	a2,112
    80002020:	4581                	li	a1,0
    80002022:	954e                	add	a0,a0,s3
    80002024:	fffff097          	auipc	ra,0xfffff
    80002028:	cbc080e7          	jalr	-836(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    8000202c:	19000793          	li	a5,400
    80002030:	02f90933          	mul	s2,s2,a5
    80002034:	994e                	add	s2,s2,s3
    80002036:	00000797          	auipc	a5,0x0
    8000203a:	d0c78793          	addi	a5,a5,-756 # 80001d42 <forkret>
    8000203e:	06f93023          	sd	a5,96(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002042:	04093783          	ld	a5,64(s2)
    80002046:	6705                	lui	a4,0x1
    80002048:	97ba                	add	a5,a5,a4
    8000204a:	06f93423          	sd	a5,104(s2)
  return p;
    8000204e:	b789                	j	80001f90 <allocproc+0x64>
    freeproc(p);
    80002050:	8526                	mv	a0,s1
    80002052:	00000097          	auipc	ra,0x0
    80002056:	e5e080e7          	jalr	-418(ra) # 80001eb0 <freeproc>
    release(&p->lock);
    8000205a:	8526                	mv	a0,s1
    8000205c:	fffff097          	auipc	ra,0xfffff
    80002060:	c3c080e7          	jalr	-964(ra) # 80000c98 <release>
    return 0;
    80002064:	84d6                	mv	s1,s5
    80002066:	b72d                	j	80001f90 <allocproc+0x64>
    freeproc(p);
    80002068:	8526                	mv	a0,s1
    8000206a:	00000097          	auipc	ra,0x0
    8000206e:	e46080e7          	jalr	-442(ra) # 80001eb0 <freeproc>
    release(&p->lock);
    80002072:	8526                	mv	a0,s1
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	c24080e7          	jalr	-988(ra) # 80000c98 <release>
    return 0;
    8000207c:	84d2                	mv	s1,s4
    8000207e:	bf09                	j	80001f90 <allocproc+0x64>
  return 0;
    80002080:	4481                	li	s1,0
    80002082:	b739                	j	80001f90 <allocproc+0x64>

0000000080002084 <userinit>:
{
    80002084:	1101                	addi	sp,sp,-32
    80002086:	ec06                	sd	ra,24(sp)
    80002088:	e822                	sd	s0,16(sp)
    8000208a:	e426                	sd	s1,8(sp)
    8000208c:	1000                	addi	s0,sp,32
  p = allocproc();
    8000208e:	00000097          	auipc	ra,0x0
    80002092:	e9e080e7          	jalr	-354(ra) # 80001f2c <allocproc>
    80002096:	84aa                	mv	s1,a0
  initproc = p;
    80002098:	00007797          	auipc	a5,0x7
    8000209c:	f8a7b823          	sd	a0,-112(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800020a0:	03400613          	li	a2,52
    800020a4:	00007597          	auipc	a1,0x7
    800020a8:	86c58593          	addi	a1,a1,-1940 # 80008910 <initcode>
    800020ac:	6928                	ld	a0,80(a0)
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	2ba080e7          	jalr	698(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    800020b6:	6785                	lui	a5,0x1
    800020b8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    800020ba:	6cb8                	ld	a4,88(s1)
    800020bc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800020c0:	6cb8                	ld	a4,88(s1)
    800020c2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800020c4:	4641                	li	a2,16
    800020c6:	00006597          	auipc	a1,0x6
    800020ca:	1c258593          	addi	a1,a1,450 # 80008288 <digits+0x248>
    800020ce:	15848513          	addi	a0,s1,344
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	d60080e7          	jalr	-672(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800020da:	00006517          	auipc	a0,0x6
    800020de:	1be50513          	addi	a0,a0,446 # 80008298 <digits+0x258>
    800020e2:	00002097          	auipc	ra,0x2
    800020e6:	2b4080e7          	jalr	692(ra) # 80004396 <namei>
    800020ea:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    800020ee:	478d                	li	a5,3
    800020f0:	cc9c                	sw	a5,24(s1)
  append(l, p);
    800020f2:	85a6                	mv	a1,s1
    800020f4:	0000f517          	auipc	a0,0xf
    800020f8:	23450513          	addi	a0,a0,564 # 80011328 <cpus+0x88>
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	7c0080e7          	jalr	1984(ra) # 800018bc <append>
  release(&p->lock);
    80002104:	8526                	mv	a0,s1
    80002106:	fffff097          	auipc	ra,0xfffff
    8000210a:	b92080e7          	jalr	-1134(ra) # 80000c98 <release>
}
    8000210e:	60e2                	ld	ra,24(sp)
    80002110:	6442                	ld	s0,16(sp)
    80002112:	64a2                	ld	s1,8(sp)
    80002114:	6105                	addi	sp,sp,32
    80002116:	8082                	ret

0000000080002118 <growproc>:
{
    80002118:	1101                	addi	sp,sp,-32
    8000211a:	ec06                	sd	ra,24(sp)
    8000211c:	e822                	sd	s0,16(sp)
    8000211e:	e426                	sd	s1,8(sp)
    80002120:	e04a                	sd	s2,0(sp)
    80002122:	1000                	addi	s0,sp,32
    80002124:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002126:	00000097          	auipc	ra,0x0
    8000212a:	bde080e7          	jalr	-1058(ra) # 80001d04 <myproc>
    8000212e:	892a                	mv	s2,a0
  sz = p->sz;
    80002130:	652c                	ld	a1,72(a0)
    80002132:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002136:	00904f63          	bgtz	s1,80002154 <growproc+0x3c>
  } else if(n < 0){
    8000213a:	0204cc63          	bltz	s1,80002172 <growproc+0x5a>
  p->sz = sz;
    8000213e:	1602                	slli	a2,a2,0x20
    80002140:	9201                	srli	a2,a2,0x20
    80002142:	04c93423          	sd	a2,72(s2)
  return 0;
    80002146:	4501                	li	a0,0
}
    80002148:	60e2                	ld	ra,24(sp)
    8000214a:	6442                	ld	s0,16(sp)
    8000214c:	64a2                	ld	s1,8(sp)
    8000214e:	6902                	ld	s2,0(sp)
    80002150:	6105                	addi	sp,sp,32
    80002152:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002154:	9e25                	addw	a2,a2,s1
    80002156:	1602                	slli	a2,a2,0x20
    80002158:	9201                	srli	a2,a2,0x20
    8000215a:	1582                	slli	a1,a1,0x20
    8000215c:	9181                	srli	a1,a1,0x20
    8000215e:	6928                	ld	a0,80(a0)
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	2c2080e7          	jalr	706(ra) # 80001422 <uvmalloc>
    80002168:	0005061b          	sext.w	a2,a0
    8000216c:	fa69                	bnez	a2,8000213e <growproc+0x26>
      return -1;
    8000216e:	557d                	li	a0,-1
    80002170:	bfe1                	j	80002148 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002172:	9e25                	addw	a2,a2,s1
    80002174:	1602                	slli	a2,a2,0x20
    80002176:	9201                	srli	a2,a2,0x20
    80002178:	1582                	slli	a1,a1,0x20
    8000217a:	9181                	srli	a1,a1,0x20
    8000217c:	6928                	ld	a0,80(a0)
    8000217e:	fffff097          	auipc	ra,0xfffff
    80002182:	25c080e7          	jalr	604(ra) # 800013da <uvmdealloc>
    80002186:	0005061b          	sext.w	a2,a0
    8000218a:	bf55                	j	8000213e <growproc+0x26>

000000008000218c <fork>:
{
    8000218c:	7139                	addi	sp,sp,-64
    8000218e:	fc06                	sd	ra,56(sp)
    80002190:	f822                	sd	s0,48(sp)
    80002192:	f426                	sd	s1,40(sp)
    80002194:	f04a                	sd	s2,32(sp)
    80002196:	ec4e                	sd	s3,24(sp)
    80002198:	e852                	sd	s4,16(sp)
    8000219a:	e456                	sd	s5,8(sp)
    8000219c:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    8000219e:	00000097          	auipc	ra,0x0
    800021a2:	b66080e7          	jalr	-1178(ra) # 80001d04 <myproc>
    800021a6:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    800021a8:	00000097          	auipc	ra,0x0
    800021ac:	d84080e7          	jalr	-636(ra) # 80001f2c <allocproc>
    800021b0:	14050663          	beqz	a0,800022fc <fork+0x170>
    800021b4:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800021b6:	04893603          	ld	a2,72(s2)
    800021ba:	692c                	ld	a1,80(a0)
    800021bc:	05093503          	ld	a0,80(s2)
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	3ae080e7          	jalr	942(ra) # 8000156e <uvmcopy>
    800021c8:	04054663          	bltz	a0,80002214 <fork+0x88>
  np->sz = p->sz;
    800021cc:	04893783          	ld	a5,72(s2)
    800021d0:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    800021d4:	05893683          	ld	a3,88(s2)
    800021d8:	87b6                	mv	a5,a3
    800021da:	0589b703          	ld	a4,88(s3)
    800021de:	12068693          	addi	a3,a3,288
    800021e2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800021e6:	6788                	ld	a0,8(a5)
    800021e8:	6b8c                	ld	a1,16(a5)
    800021ea:	6f90                	ld	a2,24(a5)
    800021ec:	01073023          	sd	a6,0(a4)
    800021f0:	e708                	sd	a0,8(a4)
    800021f2:	eb0c                	sd	a1,16(a4)
    800021f4:	ef10                	sd	a2,24(a4)
    800021f6:	02078793          	addi	a5,a5,32
    800021fa:	02070713          	addi	a4,a4,32
    800021fe:	fed792e3          	bne	a5,a3,800021e2 <fork+0x56>
  np->trapframe->a0 = 0;
    80002202:	0589b783          	ld	a5,88(s3)
    80002206:	0607b823          	sd	zero,112(a5)
    8000220a:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    8000220e:	15000a13          	li	s4,336
    80002212:	a03d                	j	80002240 <fork+0xb4>
    freeproc(np);
    80002214:	854e                	mv	a0,s3
    80002216:	00000097          	auipc	ra,0x0
    8000221a:	c9a080e7          	jalr	-870(ra) # 80001eb0 <freeproc>
    release(&np->lock);
    8000221e:	854e                	mv	a0,s3
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	a78080e7          	jalr	-1416(ra) # 80000c98 <release>
    return -1;
    80002228:	5afd                	li	s5,-1
    8000222a:	a87d                	j	800022e8 <fork+0x15c>
      np->ofile[i] = filedup(p->ofile[i]);
    8000222c:	00003097          	auipc	ra,0x3
    80002230:	800080e7          	jalr	-2048(ra) # 80004a2c <filedup>
    80002234:	009987b3          	add	a5,s3,s1
    80002238:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    8000223a:	04a1                	addi	s1,s1,8
    8000223c:	01448763          	beq	s1,s4,8000224a <fork+0xbe>
    if(p->ofile[i])
    80002240:	009907b3          	add	a5,s2,s1
    80002244:	6388                	ld	a0,0(a5)
    80002246:	f17d                	bnez	a0,8000222c <fork+0xa0>
    80002248:	bfcd                	j	8000223a <fork+0xae>
  np->cwd = idup(p->cwd);
    8000224a:	15093503          	ld	a0,336(s2)
    8000224e:	00002097          	auipc	ra,0x2
    80002252:	954080e7          	jalr	-1708(ra) # 80003ba2 <idup>
    80002256:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000225a:	4641                	li	a2,16
    8000225c:	15890593          	addi	a1,s2,344
    80002260:	15898513          	addi	a0,s3,344
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	bce080e7          	jalr	-1074(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    8000226c:	0309aa83          	lw	s5,48(s3)
  release(&np->lock);
    80002270:	854e                	mv	a0,s3
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	a26080e7          	jalr	-1498(ra) # 80000c98 <release>
  acquire(&wait_lock);
    8000227a:	0000fa17          	auipc	s4,0xf
    8000227e:	026a0a13          	addi	s4,s4,38 # 800112a0 <cpus>
    80002282:	0000f497          	auipc	s1,0xf
    80002286:	57648493          	addi	s1,s1,1398 # 800117f8 <wait_lock>
    8000228a:	8526                	mv	a0,s1
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	958080e7          	jalr	-1704(ra) # 80000be4 <acquire>
  np->parent = p;
    80002294:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80002298:	8526                	mv	a0,s1
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	9fe080e7          	jalr	-1538(ra) # 80000c98 <release>
  acquire(&np->lock);
    800022a2:	854e                	mv	a0,s3
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	940080e7          	jalr	-1728(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800022ac:	478d                	li	a5,3
    800022ae:	00f9ac23          	sw	a5,24(s3)
  np->last_cpu = p->last_cpu; // case BLNCFLG=OFF -> cpu = parent's cpu 
    800022b2:	16892483          	lw	s1,360(s2)
    800022b6:	1699a423          	sw	s1,360(s3)
  struct cpu *c = &cpus[np->last_cpu];
    800022ba:	0a800513          	li	a0,168
    800022be:	02a484b3          	mul	s1,s1,a0
  inc_cpu(c);
    800022c2:	009a0533          	add	a0,s4,s1
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	578080e7          	jalr	1400(ra) # 8000183e <inc_cpu>
  append(&(c->runnable_list), np); // admit the new process to the father’s current CPU’s ready list
    800022ce:	08848513          	addi	a0,s1,136
    800022d2:	85ce                	mv	a1,s3
    800022d4:	9552                	add	a0,a0,s4
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	5e6080e7          	jalr	1510(ra) # 800018bc <append>
  release(&np->lock);
    800022de:	854e                	mv	a0,s3
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	9b8080e7          	jalr	-1608(ra) # 80000c98 <release>
}
    800022e8:	8556                	mv	a0,s5
    800022ea:	70e2                	ld	ra,56(sp)
    800022ec:	7442                	ld	s0,48(sp)
    800022ee:	74a2                	ld	s1,40(sp)
    800022f0:	7902                	ld	s2,32(sp)
    800022f2:	69e2                	ld	s3,24(sp)
    800022f4:	6a42                	ld	s4,16(sp)
    800022f6:	6aa2                	ld	s5,8(sp)
    800022f8:	6121                	addi	sp,sp,64
    800022fa:	8082                	ret
    return -1;
    800022fc:	5afd                	li	s5,-1
    800022fe:	b7ed                	j	800022e8 <fork+0x15c>

0000000080002300 <scheduler>:
{
    80002300:	715d                	addi	sp,sp,-80
    80002302:	e486                	sd	ra,72(sp)
    80002304:	e0a2                	sd	s0,64(sp)
    80002306:	fc26                	sd	s1,56(sp)
    80002308:	f84a                	sd	s2,48(sp)
    8000230a:	f44e                	sd	s3,40(sp)
    8000230c:	f052                	sd	s4,32(sp)
    8000230e:	ec56                	sd	s5,24(sp)
    80002310:	e85a                	sd	s6,16(sp)
    80002312:	e45e                	sd	s7,8(sp)
    80002314:	e062                	sd	s8,0(sp)
    80002316:	0880                	addi	s0,sp,80
    80002318:	8712                	mv	a4,tp
  int id = r_tp();
    8000231a:	2701                	sext.w	a4,a4
  c->proc = 0;
    8000231c:	0000fa97          	auipc	s5,0xf
    80002320:	f84a8a93          	addi	s5,s5,-124 # 800112a0 <cpus>
    80002324:	0a800793          	li	a5,168
    80002328:	02f707b3          	mul	a5,a4,a5
    8000232c:	00fa86b3          	add	a3,s5,a5
    80002330:	0006b023          	sd	zero,0(a3)
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    80002334:	08878b13          	addi	s6,a5,136
    80002338:	9b56                	add	s6,s6,s5
          swtch(&c->context, &p->context);
    8000233a:	07a1                	addi	a5,a5,8
    8000233c:	9abe                	add	s5,s5,a5
  h = lst->head == -1;
    8000233e:	8936                	mv	s2,a3
      if(p->state == RUNNABLE) {
    80002340:	0000f997          	auipc	s3,0xf
    80002344:	4d098993          	addi	s3,s3,1232 # 80011810 <proc>
    80002348:	19000a13          	li	s4,400
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000234c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002350:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002354:	10079073          	csrw	sstatus,a5
    80002358:	4b8d                	li	s7,3
  h = lst->head == -1;
    8000235a:	08892783          	lw	a5,136(s2)
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    8000235e:	56fd                	li	a3,-1
      if(p->state == RUNNABLE) {
    80002360:	03478733          	mul	a4,a5,s4
    80002364:	974e                	add	a4,a4,s3
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    80002366:	fed783e3          	beq	a5,a3,8000234c <scheduler+0x4c>
      if(p->state == RUNNABLE) {
    8000236a:	4f10                	lw	a2,24(a4)
    8000236c:	ff761de3          	bne	a2,s7,80002366 <scheduler+0x66>
    80002370:	034784b3          	mul	s1,a5,s4
      p = &proc[c->runnable_list.head];
    80002374:	01348c33          	add	s8,s1,s3
        acquire(&p->lock);
    80002378:	8562                	mv	a0,s8
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	86a080e7          	jalr	-1942(ra) # 80000be4 <acquire>
          remove(&(c->runnable_list), p);
    80002382:	85e2                	mv	a1,s8
    80002384:	855a                	mv	a0,s6
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	5fe080e7          	jalr	1534(ra) # 80001984 <remove>
          p->state = RUNNING;
    8000238e:	4791                	li	a5,4
    80002390:	00fc2c23          	sw	a5,24(s8)
          c->proc = p;
    80002394:	01893023          	sd	s8,0(s2)
          p->last_cpu = c->cpu_id;
    80002398:	08492783          	lw	a5,132(s2)
    8000239c:	16fc2423          	sw	a5,360(s8)
          swtch(&c->context, &p->context);
    800023a0:	06048593          	addi	a1,s1,96
    800023a4:	95ce                	add	a1,a1,s3
    800023a6:	8556                	mv	a0,s5
    800023a8:	00000097          	auipc	ra,0x0
    800023ac:	7d4080e7          	jalr	2004(ra) # 80002b7c <swtch>
          c->proc = 0;
    800023b0:	00093023          	sd	zero,0(s2)
        release(&p->lock);
    800023b4:	8562                	mv	a0,s8
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	8e2080e7          	jalr	-1822(ra) # 80000c98 <release>
    800023be:	bf71                	j	8000235a <scheduler+0x5a>

00000000800023c0 <sched>:
{
    800023c0:	7179                	addi	sp,sp,-48
    800023c2:	f406                	sd	ra,40(sp)
    800023c4:	f022                	sd	s0,32(sp)
    800023c6:	ec26                	sd	s1,24(sp)
    800023c8:	e84a                	sd	s2,16(sp)
    800023ca:	e44e                	sd	s3,8(sp)
    800023cc:	e052                	sd	s4,0(sp)
    800023ce:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800023d0:	00000097          	auipc	ra,0x0
    800023d4:	934080e7          	jalr	-1740(ra) # 80001d04 <myproc>
    800023d8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800023da:	ffffe097          	auipc	ra,0xffffe
    800023de:	790080e7          	jalr	1936(ra) # 80000b6a <holding>
    800023e2:	c141                	beqz	a0,80002462 <sched+0xa2>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023e4:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800023e6:	2781                	sext.w	a5,a5
    800023e8:	0a800713          	li	a4,168
    800023ec:	02e787b3          	mul	a5,a5,a4
    800023f0:	0000f717          	auipc	a4,0xf
    800023f4:	eb070713          	addi	a4,a4,-336 # 800112a0 <cpus>
    800023f8:	97ba                	add	a5,a5,a4
    800023fa:	5fb8                	lw	a4,120(a5)
    800023fc:	4785                	li	a5,1
    800023fe:	06f71a63          	bne	a4,a5,80002472 <sched+0xb2>
  if(p->state == RUNNING)
    80002402:	4c98                	lw	a4,24(s1)
    80002404:	4791                	li	a5,4
    80002406:	06f70e63          	beq	a4,a5,80002482 <sched+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000240a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000240e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002410:	e3c9                	bnez	a5,80002492 <sched+0xd2>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002412:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002414:	0000f917          	auipc	s2,0xf
    80002418:	e8c90913          	addi	s2,s2,-372 # 800112a0 <cpus>
    8000241c:	2781                	sext.w	a5,a5
    8000241e:	0a800993          	li	s3,168
    80002422:	033787b3          	mul	a5,a5,s3
    80002426:	97ca                	add	a5,a5,s2
    80002428:	07c7aa03          	lw	s4,124(a5)
    8000242c:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    8000242e:	2581                	sext.w	a1,a1
    80002430:	033585b3          	mul	a1,a1,s3
    80002434:	05a1                	addi	a1,a1,8
    80002436:	95ca                	add	a1,a1,s2
    80002438:	06048513          	addi	a0,s1,96
    8000243c:	00000097          	auipc	ra,0x0
    80002440:	740080e7          	jalr	1856(ra) # 80002b7c <swtch>
    80002444:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002446:	2781                	sext.w	a5,a5
    80002448:	033787b3          	mul	a5,a5,s3
    8000244c:	993e                	add	s2,s2,a5
    8000244e:	07492e23          	sw	s4,124(s2)
}
    80002452:	70a2                	ld	ra,40(sp)
    80002454:	7402                	ld	s0,32(sp)
    80002456:	64e2                	ld	s1,24(sp)
    80002458:	6942                	ld	s2,16(sp)
    8000245a:	69a2                	ld	s3,8(sp)
    8000245c:	6a02                	ld	s4,0(sp)
    8000245e:	6145                	addi	sp,sp,48
    80002460:	8082                	ret
    panic("sched p->lock");
    80002462:	00006517          	auipc	a0,0x6
    80002466:	e3e50513          	addi	a0,a0,-450 # 800082a0 <digits+0x260>
    8000246a:	ffffe097          	auipc	ra,0xffffe
    8000246e:	0d4080e7          	jalr	212(ra) # 8000053e <panic>
    panic("sched locks");
    80002472:	00006517          	auipc	a0,0x6
    80002476:	e3e50513          	addi	a0,a0,-450 # 800082b0 <digits+0x270>
    8000247a:	ffffe097          	auipc	ra,0xffffe
    8000247e:	0c4080e7          	jalr	196(ra) # 8000053e <panic>
    panic("sched running");
    80002482:	00006517          	auipc	a0,0x6
    80002486:	e3e50513          	addi	a0,a0,-450 # 800082c0 <digits+0x280>
    8000248a:	ffffe097          	auipc	ra,0xffffe
    8000248e:	0b4080e7          	jalr	180(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002492:	00006517          	auipc	a0,0x6
    80002496:	e3e50513          	addi	a0,a0,-450 # 800082d0 <digits+0x290>
    8000249a:	ffffe097          	auipc	ra,0xffffe
    8000249e:	0a4080e7          	jalr	164(ra) # 8000053e <panic>

00000000800024a2 <yield>:
{
    800024a2:	1101                	addi	sp,sp,-32
    800024a4:	ec06                	sd	ra,24(sp)
    800024a6:	e822                	sd	s0,16(sp)
    800024a8:	e426                	sd	s1,8(sp)
    800024aa:	e04a                	sd	s2,0(sp)
    800024ac:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800024ae:	00000097          	auipc	ra,0x0
    800024b2:	856080e7          	jalr	-1962(ra) # 80001d04 <myproc>
    800024b6:	84aa                	mv	s1,a0
    800024b8:	8912                	mv	s2,tp
  acquire(&p->lock);
    800024ba:	ffffe097          	auipc	ra,0xffffe
    800024be:	72a080e7          	jalr	1834(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800024c2:	478d                	li	a5,3
    800024c4:	cc9c                	sw	a5,24(s1)
  append(&(c->runnable_list), p);
    800024c6:	2901                	sext.w	s2,s2
    800024c8:	0a800513          	li	a0,168
    800024cc:	02a90933          	mul	s2,s2,a0
    800024d0:	85a6                	mv	a1,s1
    800024d2:	0000f517          	auipc	a0,0xf
    800024d6:	e5650513          	addi	a0,a0,-426 # 80011328 <cpus+0x88>
    800024da:	954a                	add	a0,a0,s2
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	3e0080e7          	jalr	992(ra) # 800018bc <append>
  sched();
    800024e4:	00000097          	auipc	ra,0x0
    800024e8:	edc080e7          	jalr	-292(ra) # 800023c0 <sched>
  release(&p->lock);
    800024ec:	8526                	mv	a0,s1
    800024ee:	ffffe097          	auipc	ra,0xffffe
    800024f2:	7aa080e7          	jalr	1962(ra) # 80000c98 <release>
}
    800024f6:	60e2                	ld	ra,24(sp)
    800024f8:	6442                	ld	s0,16(sp)
    800024fa:	64a2                	ld	s1,8(sp)
    800024fc:	6902                	ld	s2,0(sp)
    800024fe:	6105                	addi	sp,sp,32
    80002500:	8082                	ret

0000000080002502 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002502:	7179                	addi	sp,sp,-48
    80002504:	f406                	sd	ra,40(sp)
    80002506:	f022                	sd	s0,32(sp)
    80002508:	ec26                	sd	s1,24(sp)
    8000250a:	e84a                	sd	s2,16(sp)
    8000250c:	e44e                	sd	s3,8(sp)
    8000250e:	1800                	addi	s0,sp,48
    80002510:	89aa                	mv	s3,a0
    80002512:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002514:	fffff097          	auipc	ra,0xfffff
    80002518:	7f0080e7          	jalr	2032(ra) # 80001d04 <myproc>
    8000251c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);
    8000251e:	ffffe097          	auipc	ra,0xffffe
    80002522:	6c6080e7          	jalr	1734(ra) # 80000be4 <acquire>
  release(lk);
    80002526:	854a                	mv	a0,s2
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	770080e7          	jalr	1904(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002530:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002534:	4789                	li	a5,2
    80002536:	cc9c                	sw	a5,24(s1)
  //printf("insert sleep sleep %d\n", p->index); //delete
  append(&sleeping_list, p);
    80002538:	85a6                	mv	a1,s1
    8000253a:	00006517          	auipc	a0,0x6
    8000253e:	37650513          	addi	a0,a0,886 # 800088b0 <sleeping_list>
    80002542:	fffff097          	auipc	ra,0xfffff
    80002546:	37a080e7          	jalr	890(ra) # 800018bc <append>

  sched();
    8000254a:	00000097          	auipc	ra,0x0
    8000254e:	e76080e7          	jalr	-394(ra) # 800023c0 <sched>

  // Tidy up.
  p->chan = 0;
    80002552:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002556:	8526                	mv	a0,s1
    80002558:	ffffe097          	auipc	ra,0xffffe
    8000255c:	740080e7          	jalr	1856(ra) # 80000c98 <release>
  acquire(lk);
    80002560:	854a                	mv	a0,s2
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	682080e7          	jalr	1666(ra) # 80000be4 <acquire>
}
    8000256a:	70a2                	ld	ra,40(sp)
    8000256c:	7402                	ld	s0,32(sp)
    8000256e:	64e2                	ld	s1,24(sp)
    80002570:	6942                	ld	s2,16(sp)
    80002572:	69a2                	ld	s3,8(sp)
    80002574:	6145                	addi	sp,sp,48
    80002576:	8082                	ret

0000000080002578 <wait>:
{
    80002578:	715d                	addi	sp,sp,-80
    8000257a:	e486                	sd	ra,72(sp)
    8000257c:	e0a2                	sd	s0,64(sp)
    8000257e:	fc26                	sd	s1,56(sp)
    80002580:	f84a                	sd	s2,48(sp)
    80002582:	f44e                	sd	s3,40(sp)
    80002584:	f052                	sd	s4,32(sp)
    80002586:	ec56                	sd	s5,24(sp)
    80002588:	e85a                	sd	s6,16(sp)
    8000258a:	e45e                	sd	s7,8(sp)
    8000258c:	e062                	sd	s8,0(sp)
    8000258e:	0880                	addi	s0,sp,80
    80002590:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002592:	fffff097          	auipc	ra,0xfffff
    80002596:	772080e7          	jalr	1906(ra) # 80001d04 <myproc>
    8000259a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000259c:	0000f517          	auipc	a0,0xf
    800025a0:	25c50513          	addi	a0,a0,604 # 800117f8 <wait_lock>
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	640080e7          	jalr	1600(ra) # 80000be4 <acquire>
    havekids = 0;
    800025ac:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800025ae:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800025b0:	00015997          	auipc	s3,0x15
    800025b4:	66098993          	addi	s3,s3,1632 # 80017c10 <tickslock>
        havekids = 1;
    800025b8:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025ba:	0000fc17          	auipc	s8,0xf
    800025be:	23ec0c13          	addi	s8,s8,574 # 800117f8 <wait_lock>
    havekids = 0;
    800025c2:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800025c4:	0000f497          	auipc	s1,0xf
    800025c8:	24c48493          	addi	s1,s1,588 # 80011810 <proc>
    800025cc:	a0bd                	j	8000263a <wait+0xc2>
          pid = np->pid;
    800025ce:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800025d2:	000b0e63          	beqz	s6,800025ee <wait+0x76>
    800025d6:	4691                	li	a3,4
    800025d8:	02c48613          	addi	a2,s1,44
    800025dc:	85da                	mv	a1,s6
    800025de:	05093503          	ld	a0,80(s2)
    800025e2:	fffff097          	auipc	ra,0xfffff
    800025e6:	090080e7          	jalr	144(ra) # 80001672 <copyout>
    800025ea:	02054563          	bltz	a0,80002614 <wait+0x9c>
          freeproc(np);
    800025ee:	8526                	mv	a0,s1
    800025f0:	00000097          	auipc	ra,0x0
    800025f4:	8c0080e7          	jalr	-1856(ra) # 80001eb0 <freeproc>
          release(&np->lock);
    800025f8:	8526                	mv	a0,s1
    800025fa:	ffffe097          	auipc	ra,0xffffe
    800025fe:	69e080e7          	jalr	1694(ra) # 80000c98 <release>
          release(&wait_lock);
    80002602:	0000f517          	auipc	a0,0xf
    80002606:	1f650513          	addi	a0,a0,502 # 800117f8 <wait_lock>
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	68e080e7          	jalr	1678(ra) # 80000c98 <release>
          return pid;
    80002612:	a09d                	j	80002678 <wait+0x100>
            release(&np->lock);
    80002614:	8526                	mv	a0,s1
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	682080e7          	jalr	1666(ra) # 80000c98 <release>
            release(&wait_lock);
    8000261e:	0000f517          	auipc	a0,0xf
    80002622:	1da50513          	addi	a0,a0,474 # 800117f8 <wait_lock>
    80002626:	ffffe097          	auipc	ra,0xffffe
    8000262a:	672080e7          	jalr	1650(ra) # 80000c98 <release>
            return -1;
    8000262e:	59fd                	li	s3,-1
    80002630:	a0a1                	j	80002678 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002632:	19048493          	addi	s1,s1,400
    80002636:	03348463          	beq	s1,s3,8000265e <wait+0xe6>
      if(np->parent == p){
    8000263a:	7c9c                	ld	a5,56(s1)
    8000263c:	ff279be3          	bne	a5,s2,80002632 <wait+0xba>
        acquire(&np->lock);
    80002640:	8526                	mv	a0,s1
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	5a2080e7          	jalr	1442(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000264a:	4c9c                	lw	a5,24(s1)
    8000264c:	f94781e3          	beq	a5,s4,800025ce <wait+0x56>
        release(&np->lock);
    80002650:	8526                	mv	a0,s1
    80002652:	ffffe097          	auipc	ra,0xffffe
    80002656:	646080e7          	jalr	1606(ra) # 80000c98 <release>
        havekids = 1;
    8000265a:	8756                	mv	a4,s5
    8000265c:	bfd9                	j	80002632 <wait+0xba>
    if(!havekids || p->killed){
    8000265e:	c701                	beqz	a4,80002666 <wait+0xee>
    80002660:	02892783          	lw	a5,40(s2)
    80002664:	c79d                	beqz	a5,80002692 <wait+0x11a>
      release(&wait_lock);
    80002666:	0000f517          	auipc	a0,0xf
    8000266a:	19250513          	addi	a0,a0,402 # 800117f8 <wait_lock>
    8000266e:	ffffe097          	auipc	ra,0xffffe
    80002672:	62a080e7          	jalr	1578(ra) # 80000c98 <release>
      return -1;
    80002676:	59fd                	li	s3,-1
}
    80002678:	854e                	mv	a0,s3
    8000267a:	60a6                	ld	ra,72(sp)
    8000267c:	6406                	ld	s0,64(sp)
    8000267e:	74e2                	ld	s1,56(sp)
    80002680:	7942                	ld	s2,48(sp)
    80002682:	79a2                	ld	s3,40(sp)
    80002684:	7a02                	ld	s4,32(sp)
    80002686:	6ae2                	ld	s5,24(sp)
    80002688:	6b42                	ld	s6,16(sp)
    8000268a:	6ba2                	ld	s7,8(sp)
    8000268c:	6c02                	ld	s8,0(sp)
    8000268e:	6161                	addi	sp,sp,80
    80002690:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002692:	85e2                	mv	a1,s8
    80002694:	854a                	mv	a0,s2
    80002696:	00000097          	auipc	ra,0x0
    8000269a:	e6c080e7          	jalr	-404(ra) # 80002502 <sleep>
    havekids = 0;
    8000269e:	b715                	j	800025c2 <wait+0x4a>

00000000800026a0 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800026a0:	7159                	addi	sp,sp,-112
    800026a2:	f486                	sd	ra,104(sp)
    800026a4:	f0a2                	sd	s0,96(sp)
    800026a6:	eca6                	sd	s1,88(sp)
    800026a8:	e8ca                	sd	s2,80(sp)
    800026aa:	e4ce                	sd	s3,72(sp)
    800026ac:	e0d2                	sd	s4,64(sp)
    800026ae:	fc56                	sd	s5,56(sp)
    800026b0:	f85a                	sd	s6,48(sp)
    800026b2:	f45e                	sd	s7,40(sp)
    800026b4:	f062                	sd	s8,32(sp)
    800026b6:	ec66                	sd	s9,24(sp)
    800026b8:	e86a                	sd	s10,16(sp)
    800026ba:	e46e                	sd	s11,8(sp)
    800026bc:	1880                	addi	s0,sp,112
  struct proc *p;
  struct cpu *c;

  int curr = sleeping_list.head;
    800026be:	00006917          	auipc	s2,0x6
    800026c2:	1f292903          	lw	s2,498(s2) # 800088b0 <sleeping_list>

  while(curr != -1) {
    800026c6:	57fd                	li	a5,-1
    800026c8:	08f90e63          	beq	s2,a5,80002764 <wakeup+0xc4>
    800026cc:	8c2a                	mv	s8,a0
    p = &proc[curr];
    800026ce:	19000a93          	li	s5,400
    800026d2:	0000fa17          	auipc	s4,0xf
    800026d6:	13ea0a13          	addi	s4,s4,318 # 80011810 <proc>
    curr = p->next_proc;
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800026da:	4b89                	li	s7,2
        remove(&sleeping_list, p);
        p->state = RUNNABLE;
    800026dc:	4d8d                	li	s11,3
    800026de:	0a800d13          	li	s10,168

        #ifdef ON
          p->last_cpu = min_cpu_process_count(); // case BLNCFLG=ON -> cpu = CPU with the lowest counter value
        #endif
        c = &cpus[p->last_cpu];
    800026e2:	0000fc97          	auipc	s9,0xf
    800026e6:	bbec8c93          	addi	s9,s9,-1090 # 800112a0 <cpus>
  while(curr != -1) {
    800026ea:	5b7d                	li	s6,-1
    800026ec:	a801                	j	800026fc <wakeup+0x5c>
        inc_cpu(c);

        append(&(c->runnable_list), p);
      }
      release(&p->lock);
    800026ee:	8526                	mv	a0,s1
    800026f0:	ffffe097          	auipc	ra,0xffffe
    800026f4:	5a8080e7          	jalr	1448(ra) # 80000c98 <release>
  while(curr != -1) {
    800026f8:	07690663          	beq	s2,s6,80002764 <wakeup+0xc4>
    p = &proc[curr];
    800026fc:	035904b3          	mul	s1,s2,s5
    80002700:	94d2                	add	s1,s1,s4
    curr = p->next_proc;
    80002702:	16c4a903          	lw	s2,364(s1)
    if(p != myproc()){
    80002706:	fffff097          	auipc	ra,0xfffff
    8000270a:	5fe080e7          	jalr	1534(ra) # 80001d04 <myproc>
    8000270e:	fea485e3          	beq	s1,a0,800026f8 <wakeup+0x58>
      acquire(&p->lock);
    80002712:	8526                	mv	a0,s1
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	4d0080e7          	jalr	1232(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000271c:	4c9c                	lw	a5,24(s1)
    8000271e:	fd7798e3          	bne	a5,s7,800026ee <wakeup+0x4e>
    80002722:	709c                	ld	a5,32(s1)
    80002724:	fd8795e3          	bne	a5,s8,800026ee <wakeup+0x4e>
        remove(&sleeping_list, p);
    80002728:	85a6                	mv	a1,s1
    8000272a:	00006517          	auipc	a0,0x6
    8000272e:	18650513          	addi	a0,a0,390 # 800088b0 <sleeping_list>
    80002732:	fffff097          	auipc	ra,0xfffff
    80002736:	252080e7          	jalr	594(ra) # 80001984 <remove>
        p->state = RUNNABLE;
    8000273a:	01b4ac23          	sw	s11,24(s1)
        c = &cpus[p->last_cpu];
    8000273e:	1684a983          	lw	s3,360(s1)
    80002742:	03a989b3          	mul	s3,s3,s10
        inc_cpu(c);
    80002746:	013c8533          	add	a0,s9,s3
    8000274a:	fffff097          	auipc	ra,0xfffff
    8000274e:	0f4080e7          	jalr	244(ra) # 8000183e <inc_cpu>
        append(&(c->runnable_list), p);
    80002752:	08898513          	addi	a0,s3,136
    80002756:	85a6                	mv	a1,s1
    80002758:	9566                	add	a0,a0,s9
    8000275a:	fffff097          	auipc	ra,0xfffff
    8000275e:	162080e7          	jalr	354(ra) # 800018bc <append>
    80002762:	b771                	j	800026ee <wakeup+0x4e>
    }
  }
}
    80002764:	70a6                	ld	ra,104(sp)
    80002766:	7406                	ld	s0,96(sp)
    80002768:	64e6                	ld	s1,88(sp)
    8000276a:	6946                	ld	s2,80(sp)
    8000276c:	69a6                	ld	s3,72(sp)
    8000276e:	6a06                	ld	s4,64(sp)
    80002770:	7ae2                	ld	s5,56(sp)
    80002772:	7b42                	ld	s6,48(sp)
    80002774:	7ba2                	ld	s7,40(sp)
    80002776:	7c02                	ld	s8,32(sp)
    80002778:	6ce2                	ld	s9,24(sp)
    8000277a:	6d42                	ld	s10,16(sp)
    8000277c:	6da2                	ld	s11,8(sp)
    8000277e:	6165                	addi	sp,sp,112
    80002780:	8082                	ret

0000000080002782 <reparent>:
{
    80002782:	7179                	addi	sp,sp,-48
    80002784:	f406                	sd	ra,40(sp)
    80002786:	f022                	sd	s0,32(sp)
    80002788:	ec26                	sd	s1,24(sp)
    8000278a:	e84a                	sd	s2,16(sp)
    8000278c:	e44e                	sd	s3,8(sp)
    8000278e:	e052                	sd	s4,0(sp)
    80002790:	1800                	addi	s0,sp,48
    80002792:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002794:	0000f497          	auipc	s1,0xf
    80002798:	07c48493          	addi	s1,s1,124 # 80011810 <proc>
      pp->parent = initproc;
    8000279c:	00007a17          	auipc	s4,0x7
    800027a0:	88ca0a13          	addi	s4,s4,-1908 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800027a4:	00015997          	auipc	s3,0x15
    800027a8:	46c98993          	addi	s3,s3,1132 # 80017c10 <tickslock>
    800027ac:	a029                	j	800027b6 <reparent+0x34>
    800027ae:	19048493          	addi	s1,s1,400
    800027b2:	01348d63          	beq	s1,s3,800027cc <reparent+0x4a>
    if(pp->parent == p){
    800027b6:	7c9c                	ld	a5,56(s1)
    800027b8:	ff279be3          	bne	a5,s2,800027ae <reparent+0x2c>
      pp->parent = initproc;
    800027bc:	000a3503          	ld	a0,0(s4)
    800027c0:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800027c2:	00000097          	auipc	ra,0x0
    800027c6:	ede080e7          	jalr	-290(ra) # 800026a0 <wakeup>
    800027ca:	b7d5                	j	800027ae <reparent+0x2c>
}
    800027cc:	70a2                	ld	ra,40(sp)
    800027ce:	7402                	ld	s0,32(sp)
    800027d0:	64e2                	ld	s1,24(sp)
    800027d2:	6942                	ld	s2,16(sp)
    800027d4:	69a2                	ld	s3,8(sp)
    800027d6:	6a02                	ld	s4,0(sp)
    800027d8:	6145                	addi	sp,sp,48
    800027da:	8082                	ret

00000000800027dc <exit>:
{
    800027dc:	7179                	addi	sp,sp,-48
    800027de:	f406                	sd	ra,40(sp)
    800027e0:	f022                	sd	s0,32(sp)
    800027e2:	ec26                	sd	s1,24(sp)
    800027e4:	e84a                	sd	s2,16(sp)
    800027e6:	e44e                	sd	s3,8(sp)
    800027e8:	e052                	sd	s4,0(sp)
    800027ea:	1800                	addi	s0,sp,48
    800027ec:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800027ee:	fffff097          	auipc	ra,0xfffff
    800027f2:	516080e7          	jalr	1302(ra) # 80001d04 <myproc>
    800027f6:	89aa                	mv	s3,a0
  if(p == initproc)
    800027f8:	00007797          	auipc	a5,0x7
    800027fc:	8307b783          	ld	a5,-2000(a5) # 80009028 <initproc>
    80002800:	0d050493          	addi	s1,a0,208
    80002804:	15050913          	addi	s2,a0,336
    80002808:	02a79363          	bne	a5,a0,8000282e <exit+0x52>
    panic("init exiting");
    8000280c:	00006517          	auipc	a0,0x6
    80002810:	adc50513          	addi	a0,a0,-1316 # 800082e8 <digits+0x2a8>
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	d2a080e7          	jalr	-726(ra) # 8000053e <panic>
      fileclose(f);
    8000281c:	00002097          	auipc	ra,0x2
    80002820:	262080e7          	jalr	610(ra) # 80004a7e <fileclose>
      p->ofile[fd] = 0;
    80002824:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002828:	04a1                	addi	s1,s1,8
    8000282a:	01248563          	beq	s1,s2,80002834 <exit+0x58>
    if(p->ofile[fd]){
    8000282e:	6088                	ld	a0,0(s1)
    80002830:	f575                	bnez	a0,8000281c <exit+0x40>
    80002832:	bfdd                	j	80002828 <exit+0x4c>
  begin_op();
    80002834:	00002097          	auipc	ra,0x2
    80002838:	d7e080e7          	jalr	-642(ra) # 800045b2 <begin_op>
  iput(p->cwd);
    8000283c:	1509b503          	ld	a0,336(s3)
    80002840:	00001097          	auipc	ra,0x1
    80002844:	55a080e7          	jalr	1370(ra) # 80003d9a <iput>
  end_op();
    80002848:	00002097          	auipc	ra,0x2
    8000284c:	dea080e7          	jalr	-534(ra) # 80004632 <end_op>
  p->cwd = 0;
    80002850:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002854:	0000f497          	auipc	s1,0xf
    80002858:	fa448493          	addi	s1,s1,-92 # 800117f8 <wait_lock>
    8000285c:	8526                	mv	a0,s1
    8000285e:	ffffe097          	auipc	ra,0xffffe
    80002862:	386080e7          	jalr	902(ra) # 80000be4 <acquire>
  reparent(p);
    80002866:	854e                	mv	a0,s3
    80002868:	00000097          	auipc	ra,0x0
    8000286c:	f1a080e7          	jalr	-230(ra) # 80002782 <reparent>
  wakeup(p->parent);
    80002870:	0389b503          	ld	a0,56(s3)
    80002874:	00000097          	auipc	ra,0x0
    80002878:	e2c080e7          	jalr	-468(ra) # 800026a0 <wakeup>
  acquire(&p->lock);
    8000287c:	854e                	mv	a0,s3
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	366080e7          	jalr	870(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002886:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000288a:	4795                	li	a5,5
    8000288c:	00f9ac23          	sw	a5,24(s3)
  append(&zombie_list, p); // exit to admit the exiting process to the ZOMBIE list
    80002890:	85ce                	mv	a1,s3
    80002892:	00006517          	auipc	a0,0x6
    80002896:	03e50513          	addi	a0,a0,62 # 800088d0 <zombie_list>
    8000289a:	fffff097          	auipc	ra,0xfffff
    8000289e:	022080e7          	jalr	34(ra) # 800018bc <append>
  release(&wait_lock);
    800028a2:	8526                	mv	a0,s1
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	3f4080e7          	jalr	1012(ra) # 80000c98 <release>
  sched();
    800028ac:	00000097          	auipc	ra,0x0
    800028b0:	b14080e7          	jalr	-1260(ra) # 800023c0 <sched>
  panic("zombie exit");
    800028b4:	00006517          	auipc	a0,0x6
    800028b8:	a4450513          	addi	a0,a0,-1468 # 800082f8 <digits+0x2b8>
    800028bc:	ffffe097          	auipc	ra,0xffffe
    800028c0:	c82080e7          	jalr	-894(ra) # 8000053e <panic>

00000000800028c4 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800028c4:	7179                	addi	sp,sp,-48
    800028c6:	f406                	sd	ra,40(sp)
    800028c8:	f022                	sd	s0,32(sp)
    800028ca:	ec26                	sd	s1,24(sp)
    800028cc:	e84a                	sd	s2,16(sp)
    800028ce:	e44e                	sd	s3,8(sp)
    800028d0:	1800                	addi	s0,sp,48
    800028d2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800028d4:	0000f497          	auipc	s1,0xf
    800028d8:	f3c48493          	addi	s1,s1,-196 # 80011810 <proc>
    800028dc:	00015997          	auipc	s3,0x15
    800028e0:	33498993          	addi	s3,s3,820 # 80017c10 <tickslock>
    acquire(&p->lock);
    800028e4:	8526                	mv	a0,s1
    800028e6:	ffffe097          	auipc	ra,0xffffe
    800028ea:	2fe080e7          	jalr	766(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800028ee:	589c                	lw	a5,48(s1)
    800028f0:	01278d63          	beq	a5,s2,8000290a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800028f4:	8526                	mv	a0,s1
    800028f6:	ffffe097          	auipc	ra,0xffffe
    800028fa:	3a2080e7          	jalr	930(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800028fe:	19048493          	addi	s1,s1,400
    80002902:	ff3491e3          	bne	s1,s3,800028e4 <kill+0x20>
  }
  return -1;
    80002906:	557d                	li	a0,-1
    80002908:	a829                	j	80002922 <kill+0x5e>
      p->killed = 1;
    8000290a:	4785                	li	a5,1
    8000290c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000290e:	4c98                	lw	a4,24(s1)
    80002910:	4789                	li	a5,2
    80002912:	00f70f63          	beq	a4,a5,80002930 <kill+0x6c>
      release(&p->lock);
    80002916:	8526                	mv	a0,s1
    80002918:	ffffe097          	auipc	ra,0xffffe
    8000291c:	380080e7          	jalr	896(ra) # 80000c98 <release>
      return 0;
    80002920:	4501                	li	a0,0
}
    80002922:	70a2                	ld	ra,40(sp)
    80002924:	7402                	ld	s0,32(sp)
    80002926:	64e2                	ld	s1,24(sp)
    80002928:	6942                	ld	s2,16(sp)
    8000292a:	69a2                	ld	s3,8(sp)
    8000292c:	6145                	addi	sp,sp,48
    8000292e:	8082                	ret
        p->state = RUNNABLE;
    80002930:	478d                	li	a5,3
    80002932:	cc9c                	sw	a5,24(s1)
    80002934:	b7cd                	j	80002916 <kill+0x52>

0000000080002936 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002936:	7179                	addi	sp,sp,-48
    80002938:	f406                	sd	ra,40(sp)
    8000293a:	f022                	sd	s0,32(sp)
    8000293c:	ec26                	sd	s1,24(sp)
    8000293e:	e84a                	sd	s2,16(sp)
    80002940:	e44e                	sd	s3,8(sp)
    80002942:	e052                	sd	s4,0(sp)
    80002944:	1800                	addi	s0,sp,48
    80002946:	84aa                	mv	s1,a0
    80002948:	892e                	mv	s2,a1
    8000294a:	89b2                	mv	s3,a2
    8000294c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000294e:	fffff097          	auipc	ra,0xfffff
    80002952:	3b6080e7          	jalr	950(ra) # 80001d04 <myproc>
  if(user_dst){
    80002956:	c08d                	beqz	s1,80002978 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002958:	86d2                	mv	a3,s4
    8000295a:	864e                	mv	a2,s3
    8000295c:	85ca                	mv	a1,s2
    8000295e:	6928                	ld	a0,80(a0)
    80002960:	fffff097          	auipc	ra,0xfffff
    80002964:	d12080e7          	jalr	-750(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002968:	70a2                	ld	ra,40(sp)
    8000296a:	7402                	ld	s0,32(sp)
    8000296c:	64e2                	ld	s1,24(sp)
    8000296e:	6942                	ld	s2,16(sp)
    80002970:	69a2                	ld	s3,8(sp)
    80002972:	6a02                	ld	s4,0(sp)
    80002974:	6145                	addi	sp,sp,48
    80002976:	8082                	ret
    memmove((char *)dst, src, len);
    80002978:	000a061b          	sext.w	a2,s4
    8000297c:	85ce                	mv	a1,s3
    8000297e:	854a                	mv	a0,s2
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	3c0080e7          	jalr	960(ra) # 80000d40 <memmove>
    return 0;
    80002988:	8526                	mv	a0,s1
    8000298a:	bff9                	j	80002968 <either_copyout+0x32>

000000008000298c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000298c:	7179                	addi	sp,sp,-48
    8000298e:	f406                	sd	ra,40(sp)
    80002990:	f022                	sd	s0,32(sp)
    80002992:	ec26                	sd	s1,24(sp)
    80002994:	e84a                	sd	s2,16(sp)
    80002996:	e44e                	sd	s3,8(sp)
    80002998:	e052                	sd	s4,0(sp)
    8000299a:	1800                	addi	s0,sp,48
    8000299c:	892a                	mv	s2,a0
    8000299e:	84ae                	mv	s1,a1
    800029a0:	89b2                	mv	s3,a2
    800029a2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029a4:	fffff097          	auipc	ra,0xfffff
    800029a8:	360080e7          	jalr	864(ra) # 80001d04 <myproc>
  if(user_src){
    800029ac:	c08d                	beqz	s1,800029ce <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800029ae:	86d2                	mv	a3,s4
    800029b0:	864e                	mv	a2,s3
    800029b2:	85ca                	mv	a1,s2
    800029b4:	6928                	ld	a0,80(a0)
    800029b6:	fffff097          	auipc	ra,0xfffff
    800029ba:	d48080e7          	jalr	-696(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800029be:	70a2                	ld	ra,40(sp)
    800029c0:	7402                	ld	s0,32(sp)
    800029c2:	64e2                	ld	s1,24(sp)
    800029c4:	6942                	ld	s2,16(sp)
    800029c6:	69a2                	ld	s3,8(sp)
    800029c8:	6a02                	ld	s4,0(sp)
    800029ca:	6145                	addi	sp,sp,48
    800029cc:	8082                	ret
    memmove(dst, (char*)src, len);
    800029ce:	000a061b          	sext.w	a2,s4
    800029d2:	85ce                	mv	a1,s3
    800029d4:	854a                	mv	a0,s2
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	36a080e7          	jalr	874(ra) # 80000d40 <memmove>
    return 0;
    800029de:	8526                	mv	a0,s1
    800029e0:	bff9                	j	800029be <either_copyin+0x32>

00000000800029e2 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    800029e2:	715d                	addi	sp,sp,-80
    800029e4:	e486                	sd	ra,72(sp)
    800029e6:	e0a2                	sd	s0,64(sp)
    800029e8:	fc26                	sd	s1,56(sp)
    800029ea:	f84a                	sd	s2,48(sp)
    800029ec:	f44e                	sd	s3,40(sp)
    800029ee:	f052                	sd	s4,32(sp)
    800029f0:	ec56                	sd	s5,24(sp)
    800029f2:	e85a                	sd	s6,16(sp)
    800029f4:	e45e                	sd	s7,8(sp)
    800029f6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800029f8:	00005517          	auipc	a0,0x5
    800029fc:	6d050513          	addi	a0,a0,1744 # 800080c8 <digits+0x88>
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	b88080e7          	jalr	-1144(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a08:	0000f497          	auipc	s1,0xf
    80002a0c:	f6048493          	addi	s1,s1,-160 # 80011968 <proc+0x158>
    80002a10:	00015917          	auipc	s2,0x15
    80002a14:	35890913          	addi	s2,s2,856 # 80017d68 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a18:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    80002a1a:	00006997          	auipc	s3,0x6
    80002a1e:	8ee98993          	addi	s3,s3,-1810 # 80008308 <digits+0x2c8>
    printf("%d %s %s", p->pid, state, p->name);
    80002a22:	00006a97          	auipc	s5,0x6
    80002a26:	8eea8a93          	addi	s5,s5,-1810 # 80008310 <digits+0x2d0>
    printf("\n");
    80002a2a:	00005a17          	auipc	s4,0x5
    80002a2e:	69ea0a13          	addi	s4,s4,1694 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a32:	00006b97          	auipc	s7,0x6
    80002a36:	916b8b93          	addi	s7,s7,-1770 # 80008348 <states.1777>
    80002a3a:	a00d                	j	80002a5c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002a3c:	ed86a583          	lw	a1,-296(a3)
    80002a40:	8556                	mv	a0,s5
    80002a42:	ffffe097          	auipc	ra,0xffffe
    80002a46:	b46080e7          	jalr	-1210(ra) # 80000588 <printf>
    printf("\n");
    80002a4a:	8552                	mv	a0,s4
    80002a4c:	ffffe097          	auipc	ra,0xffffe
    80002a50:	b3c080e7          	jalr	-1220(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a54:	19048493          	addi	s1,s1,400
    80002a58:	03248163          	beq	s1,s2,80002a7a <procdump+0x98>
    if(p->state == UNUSED)
    80002a5c:	86a6                	mv	a3,s1
    80002a5e:	ec04a783          	lw	a5,-320(s1)
    80002a62:	dbed                	beqz	a5,80002a54 <procdump+0x72>
      state = "???"; 
    80002a64:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a66:	fcfb6be3          	bltu	s6,a5,80002a3c <procdump+0x5a>
    80002a6a:	1782                	slli	a5,a5,0x20
    80002a6c:	9381                	srli	a5,a5,0x20
    80002a6e:	078e                	slli	a5,a5,0x3
    80002a70:	97de                	add	a5,a5,s7
    80002a72:	6390                	ld	a2,0(a5)
    80002a74:	f661                	bnez	a2,80002a3c <procdump+0x5a>
      state = "???"; 
    80002a76:	864e                	mv	a2,s3
    80002a78:	b7d1                	j	80002a3c <procdump+0x5a>
  }
}
    80002a7a:	60a6                	ld	ra,72(sp)
    80002a7c:	6406                	ld	s0,64(sp)
    80002a7e:	74e2                	ld	s1,56(sp)
    80002a80:	7942                	ld	s2,48(sp)
    80002a82:	79a2                	ld	s3,40(sp)
    80002a84:	7a02                	ld	s4,32(sp)
    80002a86:	6ae2                	ld	s5,24(sp)
    80002a88:	6b42                	ld	s6,16(sp)
    80002a8a:	6ba2                	ld	s7,8(sp)
    80002a8c:	6161                	addi	sp,sp,80
    80002a8e:	8082                	ret

0000000080002a90 <set_cpu>:

// assign current process to a different CPU. 
int
set_cpu(int cpu_num){
    80002a90:	1101                	addi	sp,sp,-32
    80002a92:	ec06                	sd	ra,24(sp)
    80002a94:	e822                	sd	s0,16(sp)
    80002a96:	e426                	sd	s1,8(sp)
    80002a98:	e04a                	sd	s2,0(sp)
    80002a9a:	1000                	addi	s0,sp,32
    80002a9c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a9e:	fffff097          	auipc	ra,0xfffff
    80002aa2:	266080e7          	jalr	614(ra) # 80001d04 <myproc>
  if(cpu_num >= 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL){
    80002aa6:	0004871b          	sext.w	a4,s1
    80002aaa:	479d                	li	a5,7
    80002aac:	02e7e963          	bltu	a5,a4,80002ade <set_cpu+0x4e>
    80002ab0:	892a                	mv	s2,a0
    acquire(&p->lock);
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	132080e7          	jalr	306(ra) # 80000be4 <acquire>
    p->last_cpu = cpu_num;
    80002aba:	16992423          	sw	s1,360(s2)
    release(&p->lock);
    80002abe:	854a                	mv	a0,s2
    80002ac0:	ffffe097          	auipc	ra,0xffffe
    80002ac4:	1d8080e7          	jalr	472(ra) # 80000c98 <release>

    yield();
    80002ac8:	00000097          	auipc	ra,0x0
    80002acc:	9da080e7          	jalr	-1574(ra) # 800024a2 <yield>

    return cpu_num;
    80002ad0:	8526                	mv	a0,s1
  }
  return -1;
}
    80002ad2:	60e2                	ld	ra,24(sp)
    80002ad4:	6442                	ld	s0,16(sp)
    80002ad6:	64a2                	ld	s1,8(sp)
    80002ad8:	6902                	ld	s2,0(sp)
    80002ada:	6105                	addi	sp,sp,32
    80002adc:	8082                	ret
  return -1;
    80002ade:	557d                	li	a0,-1
    80002ae0:	bfcd                	j	80002ad2 <set_cpu+0x42>

0000000080002ae2 <get_cpu>:

// return the current CPU id.
int
get_cpu(void){
    80002ae2:	1141                	addi	sp,sp,-16
    80002ae4:	e406                	sd	ra,8(sp)
    80002ae6:	e022                	sd	s0,0(sp)
    80002ae8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002aea:	fffff097          	auipc	ra,0xfffff
    80002aee:	21a080e7          	jalr	538(ra) # 80001d04 <myproc>
  return p->last_cpu;
}
    80002af2:	16852503          	lw	a0,360(a0)
    80002af6:	60a2                	ld	ra,8(sp)
    80002af8:	6402                	ld	s0,0(sp)
    80002afa:	0141                	addi	sp,sp,16
    80002afc:	8082                	ret

0000000080002afe <min_cpu>:

int
min_cpu(void){
    80002afe:	1141                	addi	sp,sp,-16
    80002b00:	e422                	sd	s0,8(sp)
    80002b02:	0800                	addi	s0,sp,16
  struct cpu *c, *min_cpu;
// should add an if to insure numberOfCpus>0
  min_cpu = cpus;
    80002b04:	0000e617          	auipc	a2,0xe
    80002b08:	79c60613          	addi	a2,a2,1948 # 800112a0 <cpus>
  for(c = cpus + 1; c < &cpus[NCPU] && c != NULL ; c++){
    80002b0c:	0000f797          	auipc	a5,0xf
    80002b10:	83c78793          	addi	a5,a5,-1988 # 80011348 <cpus+0xa8>
    80002b14:	0000f597          	auipc	a1,0xf
    80002b18:	ccc58593          	addi	a1,a1,-820 # 800117e0 <pid_lock>
    80002b1c:	a029                	j	80002b26 <min_cpu+0x28>
    80002b1e:	0a878793          	addi	a5,a5,168
    80002b22:	00b78a63          	beq	a5,a1,80002b36 <min_cpu+0x38>
    if (c->proc_cnt < min_cpu->proc_cnt)
    80002b26:	0807a683          	lw	a3,128(a5)
    80002b2a:	08062703          	lw	a4,128(a2)
    80002b2e:	fee6d8e3          	bge	a3,a4,80002b1e <min_cpu+0x20>
    80002b32:	863e                	mv	a2,a5
    80002b34:	b7ed                	j	80002b1e <min_cpu+0x20>
        min_cpu = c;
  }
  return min_cpu->cpu_id;   
}
    80002b36:	08462503          	lw	a0,132(a2)
    80002b3a:	6422                	ld	s0,8(sp)
    80002b3c:	0141                	addi	sp,sp,16
    80002b3e:	8082                	ret

0000000080002b40 <cpu_process_count>:

int
cpu_process_count(int cpu_num){
    80002b40:	1141                	addi	sp,sp,-16
    80002b42:	e422                	sd	s0,8(sp)
    80002b44:	0800                	addi	s0,sp,16
  if (cpu_num > 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL) 
    80002b46:	fff5071b          	addiw	a4,a0,-1
    80002b4a:	4799                	li	a5,6
    80002b4c:	02e7e063          	bltu	a5,a4,80002b6c <cpu_process_count+0x2c>
    return cpus[cpu_num].proc_cnt;
    80002b50:	0a800793          	li	a5,168
    80002b54:	02f50533          	mul	a0,a0,a5
    80002b58:	0000e797          	auipc	a5,0xe
    80002b5c:	74878793          	addi	a5,a5,1864 # 800112a0 <cpus>
    80002b60:	953e                	add	a0,a0,a5
    80002b62:	08052503          	lw	a0,128(a0)
  return -1;
}
    80002b66:	6422                	ld	s0,8(sp)
    80002b68:	0141                	addi	sp,sp,16
    80002b6a:	8082                	ret
  return -1;
    80002b6c:	557d                	li	a0,-1
    80002b6e:	bfe5                	j	80002b66 <cpu_process_count+0x26>

0000000080002b70 <steal_process>:




void
steal_process(struct cpu *curr_c){  /*
    80002b70:	1141                	addi	sp,sp,-16
    80002b72:	e422                	sd	s0,8(sp)
    80002b74:	0800                	addi	s0,sp,16
  }
  p = proc[stolen_process];
  append(&c->runnable_list, p);
  p->last_cpu = c->cpu_id;
  inc_cpu(c); */
    80002b76:	6422                	ld	s0,8(sp)
    80002b78:	0141                	addi	sp,sp,16
    80002b7a:	8082                	ret

0000000080002b7c <swtch>:
    80002b7c:	00153023          	sd	ra,0(a0)
    80002b80:	00253423          	sd	sp,8(a0)
    80002b84:	e900                	sd	s0,16(a0)
    80002b86:	ed04                	sd	s1,24(a0)
    80002b88:	03253023          	sd	s2,32(a0)
    80002b8c:	03353423          	sd	s3,40(a0)
    80002b90:	03453823          	sd	s4,48(a0)
    80002b94:	03553c23          	sd	s5,56(a0)
    80002b98:	05653023          	sd	s6,64(a0)
    80002b9c:	05753423          	sd	s7,72(a0)
    80002ba0:	05853823          	sd	s8,80(a0)
    80002ba4:	05953c23          	sd	s9,88(a0)
    80002ba8:	07a53023          	sd	s10,96(a0)
    80002bac:	07b53423          	sd	s11,104(a0)
    80002bb0:	0005b083          	ld	ra,0(a1)
    80002bb4:	0085b103          	ld	sp,8(a1)
    80002bb8:	6980                	ld	s0,16(a1)
    80002bba:	6d84                	ld	s1,24(a1)
    80002bbc:	0205b903          	ld	s2,32(a1)
    80002bc0:	0285b983          	ld	s3,40(a1)
    80002bc4:	0305ba03          	ld	s4,48(a1)
    80002bc8:	0385ba83          	ld	s5,56(a1)
    80002bcc:	0405bb03          	ld	s6,64(a1)
    80002bd0:	0485bb83          	ld	s7,72(a1)
    80002bd4:	0505bc03          	ld	s8,80(a1)
    80002bd8:	0585bc83          	ld	s9,88(a1)
    80002bdc:	0605bd03          	ld	s10,96(a1)
    80002be0:	0685bd83          	ld	s11,104(a1)
    80002be4:	8082                	ret

0000000080002be6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002be6:	1141                	addi	sp,sp,-16
    80002be8:	e406                	sd	ra,8(sp)
    80002bea:	e022                	sd	s0,0(sp)
    80002bec:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002bee:	00005597          	auipc	a1,0x5
    80002bf2:	78a58593          	addi	a1,a1,1930 # 80008378 <states.1777+0x30>
    80002bf6:	00015517          	auipc	a0,0x15
    80002bfa:	01a50513          	addi	a0,a0,26 # 80017c10 <tickslock>
    80002bfe:	ffffe097          	auipc	ra,0xffffe
    80002c02:	f56080e7          	jalr	-170(ra) # 80000b54 <initlock>
}
    80002c06:	60a2                	ld	ra,8(sp)
    80002c08:	6402                	ld	s0,0(sp)
    80002c0a:	0141                	addi	sp,sp,16
    80002c0c:	8082                	ret

0000000080002c0e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c0e:	1141                	addi	sp,sp,-16
    80002c10:	e422                	sd	s0,8(sp)
    80002c12:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c14:	00003797          	auipc	a5,0x3
    80002c18:	48c78793          	addi	a5,a5,1164 # 800060a0 <kernelvec>
    80002c1c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c20:	6422                	ld	s0,8(sp)
    80002c22:	0141                	addi	sp,sp,16
    80002c24:	8082                	ret

0000000080002c26 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002c26:	1141                	addi	sp,sp,-16
    80002c28:	e406                	sd	ra,8(sp)
    80002c2a:	e022                	sd	s0,0(sp)
    80002c2c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c2e:	fffff097          	auipc	ra,0xfffff
    80002c32:	0d6080e7          	jalr	214(ra) # 80001d04 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c36:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c3a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c3c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002c40:	00004617          	auipc	a2,0x4
    80002c44:	3c060613          	addi	a2,a2,960 # 80007000 <_trampoline>
    80002c48:	00004697          	auipc	a3,0x4
    80002c4c:	3b868693          	addi	a3,a3,952 # 80007000 <_trampoline>
    80002c50:	8e91                	sub	a3,a3,a2
    80002c52:	040007b7          	lui	a5,0x4000
    80002c56:	17fd                	addi	a5,a5,-1
    80002c58:	07b2                	slli	a5,a5,0xc
    80002c5a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c5c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c60:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c62:	180026f3          	csrr	a3,satp
    80002c66:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c68:	6d38                	ld	a4,88(a0)
    80002c6a:	6134                	ld	a3,64(a0)
    80002c6c:	6585                	lui	a1,0x1
    80002c6e:	96ae                	add	a3,a3,a1
    80002c70:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c72:	6d38                	ld	a4,88(a0)
    80002c74:	00000697          	auipc	a3,0x0
    80002c78:	13868693          	addi	a3,a3,312 # 80002dac <usertrap>
    80002c7c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c7e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c80:	8692                	mv	a3,tp
    80002c82:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c84:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c88:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c8c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c90:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c94:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c96:	6f18                	ld	a4,24(a4)
    80002c98:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c9c:	692c                	ld	a1,80(a0)
    80002c9e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002ca0:	00004717          	auipc	a4,0x4
    80002ca4:	3f070713          	addi	a4,a4,1008 # 80007090 <userret>
    80002ca8:	8f11                	sub	a4,a4,a2
    80002caa:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002cac:	577d                	li	a4,-1
    80002cae:	177e                	slli	a4,a4,0x3f
    80002cb0:	8dd9                	or	a1,a1,a4
    80002cb2:	02000537          	lui	a0,0x2000
    80002cb6:	157d                	addi	a0,a0,-1
    80002cb8:	0536                	slli	a0,a0,0xd
    80002cba:	9782                	jalr	a5
}
    80002cbc:	60a2                	ld	ra,8(sp)
    80002cbe:	6402                	ld	s0,0(sp)
    80002cc0:	0141                	addi	sp,sp,16
    80002cc2:	8082                	ret

0000000080002cc4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002cc4:	1101                	addi	sp,sp,-32
    80002cc6:	ec06                	sd	ra,24(sp)
    80002cc8:	e822                	sd	s0,16(sp)
    80002cca:	e426                	sd	s1,8(sp)
    80002ccc:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002cce:	00015497          	auipc	s1,0x15
    80002cd2:	f4248493          	addi	s1,s1,-190 # 80017c10 <tickslock>
    80002cd6:	8526                	mv	a0,s1
    80002cd8:	ffffe097          	auipc	ra,0xffffe
    80002cdc:	f0c080e7          	jalr	-244(ra) # 80000be4 <acquire>
  ticks++;
    80002ce0:	00006517          	auipc	a0,0x6
    80002ce4:	35050513          	addi	a0,a0,848 # 80009030 <ticks>
    80002ce8:	411c                	lw	a5,0(a0)
    80002cea:	2785                	addiw	a5,a5,1
    80002cec:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002cee:	00000097          	auipc	ra,0x0
    80002cf2:	9b2080e7          	jalr	-1614(ra) # 800026a0 <wakeup>
  release(&tickslock);
    80002cf6:	8526                	mv	a0,s1
    80002cf8:	ffffe097          	auipc	ra,0xffffe
    80002cfc:	fa0080e7          	jalr	-96(ra) # 80000c98 <release>
}
    80002d00:	60e2                	ld	ra,24(sp)
    80002d02:	6442                	ld	s0,16(sp)
    80002d04:	64a2                	ld	s1,8(sp)
    80002d06:	6105                	addi	sp,sp,32
    80002d08:	8082                	ret

0000000080002d0a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002d0a:	1101                	addi	sp,sp,-32
    80002d0c:	ec06                	sd	ra,24(sp)
    80002d0e:	e822                	sd	s0,16(sp)
    80002d10:	e426                	sd	s1,8(sp)
    80002d12:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d14:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002d18:	00074d63          	bltz	a4,80002d32 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002d1c:	57fd                	li	a5,-1
    80002d1e:	17fe                	slli	a5,a5,0x3f
    80002d20:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002d22:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002d24:	06f70363          	beq	a4,a5,80002d8a <devintr+0x80>
  }
}
    80002d28:	60e2                	ld	ra,24(sp)
    80002d2a:	6442                	ld	s0,16(sp)
    80002d2c:	64a2                	ld	s1,8(sp)
    80002d2e:	6105                	addi	sp,sp,32
    80002d30:	8082                	ret
     (scause & 0xff) == 9){
    80002d32:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002d36:	46a5                	li	a3,9
    80002d38:	fed792e3          	bne	a5,a3,80002d1c <devintr+0x12>
    int irq = plic_claim();
    80002d3c:	00003097          	auipc	ra,0x3
    80002d40:	46c080e7          	jalr	1132(ra) # 800061a8 <plic_claim>
    80002d44:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d46:	47a9                	li	a5,10
    80002d48:	02f50763          	beq	a0,a5,80002d76 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002d4c:	4785                	li	a5,1
    80002d4e:	02f50963          	beq	a0,a5,80002d80 <devintr+0x76>
    return 1;
    80002d52:	4505                	li	a0,1
    } else if(irq){
    80002d54:	d8f1                	beqz	s1,80002d28 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d56:	85a6                	mv	a1,s1
    80002d58:	00005517          	auipc	a0,0x5
    80002d5c:	62850513          	addi	a0,a0,1576 # 80008380 <states.1777+0x38>
    80002d60:	ffffe097          	auipc	ra,0xffffe
    80002d64:	828080e7          	jalr	-2008(ra) # 80000588 <printf>
      plic_complete(irq);
    80002d68:	8526                	mv	a0,s1
    80002d6a:	00003097          	auipc	ra,0x3
    80002d6e:	462080e7          	jalr	1122(ra) # 800061cc <plic_complete>
    return 1;
    80002d72:	4505                	li	a0,1
    80002d74:	bf55                	j	80002d28 <devintr+0x1e>
      uartintr();
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	c32080e7          	jalr	-974(ra) # 800009a8 <uartintr>
    80002d7e:	b7ed                	j	80002d68 <devintr+0x5e>
      virtio_disk_intr();
    80002d80:	00004097          	auipc	ra,0x4
    80002d84:	92c080e7          	jalr	-1748(ra) # 800066ac <virtio_disk_intr>
    80002d88:	b7c5                	j	80002d68 <devintr+0x5e>
    if(cpuid() == 0){
    80002d8a:	fffff097          	auipc	ra,0xfffff
    80002d8e:	f48080e7          	jalr	-184(ra) # 80001cd2 <cpuid>
    80002d92:	c901                	beqz	a0,80002da2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d94:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d98:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d9a:	14479073          	csrw	sip,a5
    return 2;
    80002d9e:	4509                	li	a0,2
    80002da0:	b761                	j	80002d28 <devintr+0x1e>
      clockintr();
    80002da2:	00000097          	auipc	ra,0x0
    80002da6:	f22080e7          	jalr	-222(ra) # 80002cc4 <clockintr>
    80002daa:	b7ed                	j	80002d94 <devintr+0x8a>

0000000080002dac <usertrap>:
{
    80002dac:	1101                	addi	sp,sp,-32
    80002dae:	ec06                	sd	ra,24(sp)
    80002db0:	e822                	sd	s0,16(sp)
    80002db2:	e426                	sd	s1,8(sp)
    80002db4:	e04a                	sd	s2,0(sp)
    80002db6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002db8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002dbc:	1007f793          	andi	a5,a5,256
    80002dc0:	e3ad                	bnez	a5,80002e22 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002dc2:	00003797          	auipc	a5,0x3
    80002dc6:	2de78793          	addi	a5,a5,734 # 800060a0 <kernelvec>
    80002dca:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002dce:	fffff097          	auipc	ra,0xfffff
    80002dd2:	f36080e7          	jalr	-202(ra) # 80001d04 <myproc>
    80002dd6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002dd8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dda:	14102773          	csrr	a4,sepc
    80002dde:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002de0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002de4:	47a1                	li	a5,8
    80002de6:	04f71c63          	bne	a4,a5,80002e3e <usertrap+0x92>
    if(p->killed)
    80002dea:	551c                	lw	a5,40(a0)
    80002dec:	e3b9                	bnez	a5,80002e32 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002dee:	6cb8                	ld	a4,88(s1)
    80002df0:	6f1c                	ld	a5,24(a4)
    80002df2:	0791                	addi	a5,a5,4
    80002df4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002df6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002dfa:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dfe:	10079073          	csrw	sstatus,a5
    syscall();
    80002e02:	00000097          	auipc	ra,0x0
    80002e06:	2e0080e7          	jalr	736(ra) # 800030e2 <syscall>
  if(p->killed)
    80002e0a:	549c                	lw	a5,40(s1)
    80002e0c:	ebc1                	bnez	a5,80002e9c <usertrap+0xf0>
  usertrapret();
    80002e0e:	00000097          	auipc	ra,0x0
    80002e12:	e18080e7          	jalr	-488(ra) # 80002c26 <usertrapret>
}
    80002e16:	60e2                	ld	ra,24(sp)
    80002e18:	6442                	ld	s0,16(sp)
    80002e1a:	64a2                	ld	s1,8(sp)
    80002e1c:	6902                	ld	s2,0(sp)
    80002e1e:	6105                	addi	sp,sp,32
    80002e20:	8082                	ret
    panic("usertrap: not from user mode");
    80002e22:	00005517          	auipc	a0,0x5
    80002e26:	57e50513          	addi	a0,a0,1406 # 800083a0 <states.1777+0x58>
    80002e2a:	ffffd097          	auipc	ra,0xffffd
    80002e2e:	714080e7          	jalr	1812(ra) # 8000053e <panic>
      exit(-1);
    80002e32:	557d                	li	a0,-1
    80002e34:	00000097          	auipc	ra,0x0
    80002e38:	9a8080e7          	jalr	-1624(ra) # 800027dc <exit>
    80002e3c:	bf4d                	j	80002dee <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002e3e:	00000097          	auipc	ra,0x0
    80002e42:	ecc080e7          	jalr	-308(ra) # 80002d0a <devintr>
    80002e46:	892a                	mv	s2,a0
    80002e48:	c501                	beqz	a0,80002e50 <usertrap+0xa4>
  if(p->killed)
    80002e4a:	549c                	lw	a5,40(s1)
    80002e4c:	c3a1                	beqz	a5,80002e8c <usertrap+0xe0>
    80002e4e:	a815                	j	80002e82 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e50:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e54:	5890                	lw	a2,48(s1)
    80002e56:	00005517          	auipc	a0,0x5
    80002e5a:	56a50513          	addi	a0,a0,1386 # 800083c0 <states.1777+0x78>
    80002e5e:	ffffd097          	auipc	ra,0xffffd
    80002e62:	72a080e7          	jalr	1834(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e66:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e6a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e6e:	00005517          	auipc	a0,0x5
    80002e72:	58250513          	addi	a0,a0,1410 # 800083f0 <states.1777+0xa8>
    80002e76:	ffffd097          	auipc	ra,0xffffd
    80002e7a:	712080e7          	jalr	1810(ra) # 80000588 <printf>
    p->killed = 1;
    80002e7e:	4785                	li	a5,1
    80002e80:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002e82:	557d                	li	a0,-1
    80002e84:	00000097          	auipc	ra,0x0
    80002e88:	958080e7          	jalr	-1704(ra) # 800027dc <exit>
  if(which_dev == 2)
    80002e8c:	4789                	li	a5,2
    80002e8e:	f8f910e3          	bne	s2,a5,80002e0e <usertrap+0x62>
    yield();
    80002e92:	fffff097          	auipc	ra,0xfffff
    80002e96:	610080e7          	jalr	1552(ra) # 800024a2 <yield>
    80002e9a:	bf95                	j	80002e0e <usertrap+0x62>
  int which_dev = 0;
    80002e9c:	4901                	li	s2,0
    80002e9e:	b7d5                	j	80002e82 <usertrap+0xd6>

0000000080002ea0 <kerneltrap>:
{
    80002ea0:	7179                	addi	sp,sp,-48
    80002ea2:	f406                	sd	ra,40(sp)
    80002ea4:	f022                	sd	s0,32(sp)
    80002ea6:	ec26                	sd	s1,24(sp)
    80002ea8:	e84a                	sd	s2,16(sp)
    80002eaa:	e44e                	sd	s3,8(sp)
    80002eac:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002eae:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002eb2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eb6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002eba:	1004f793          	andi	a5,s1,256
    80002ebe:	cb85                	beqz	a5,80002eee <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ec0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ec4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ec6:	ef85                	bnez	a5,80002efe <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ec8:	00000097          	auipc	ra,0x0
    80002ecc:	e42080e7          	jalr	-446(ra) # 80002d0a <devintr>
    80002ed0:	cd1d                	beqz	a0,80002f0e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ed2:	4789                	li	a5,2
    80002ed4:	06f50a63          	beq	a0,a5,80002f48 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ed8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002edc:	10049073          	csrw	sstatus,s1
}
    80002ee0:	70a2                	ld	ra,40(sp)
    80002ee2:	7402                	ld	s0,32(sp)
    80002ee4:	64e2                	ld	s1,24(sp)
    80002ee6:	6942                	ld	s2,16(sp)
    80002ee8:	69a2                	ld	s3,8(sp)
    80002eea:	6145                	addi	sp,sp,48
    80002eec:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002eee:	00005517          	auipc	a0,0x5
    80002ef2:	52250513          	addi	a0,a0,1314 # 80008410 <states.1777+0xc8>
    80002ef6:	ffffd097          	auipc	ra,0xffffd
    80002efa:	648080e7          	jalr	1608(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002efe:	00005517          	auipc	a0,0x5
    80002f02:	53a50513          	addi	a0,a0,1338 # 80008438 <states.1777+0xf0>
    80002f06:	ffffd097          	auipc	ra,0xffffd
    80002f0a:	638080e7          	jalr	1592(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002f0e:	85ce                	mv	a1,s3
    80002f10:	00005517          	auipc	a0,0x5
    80002f14:	54850513          	addi	a0,a0,1352 # 80008458 <states.1777+0x110>
    80002f18:	ffffd097          	auipc	ra,0xffffd
    80002f1c:	670080e7          	jalr	1648(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f20:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f24:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f28:	00005517          	auipc	a0,0x5
    80002f2c:	54050513          	addi	a0,a0,1344 # 80008468 <states.1777+0x120>
    80002f30:	ffffd097          	auipc	ra,0xffffd
    80002f34:	658080e7          	jalr	1624(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002f38:	00005517          	auipc	a0,0x5
    80002f3c:	54850513          	addi	a0,a0,1352 # 80008480 <states.1777+0x138>
    80002f40:	ffffd097          	auipc	ra,0xffffd
    80002f44:	5fe080e7          	jalr	1534(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f48:	fffff097          	auipc	ra,0xfffff
    80002f4c:	dbc080e7          	jalr	-580(ra) # 80001d04 <myproc>
    80002f50:	d541                	beqz	a0,80002ed8 <kerneltrap+0x38>
    80002f52:	fffff097          	auipc	ra,0xfffff
    80002f56:	db2080e7          	jalr	-590(ra) # 80001d04 <myproc>
    80002f5a:	4d18                	lw	a4,24(a0)
    80002f5c:	4791                	li	a5,4
    80002f5e:	f6f71de3          	bne	a4,a5,80002ed8 <kerneltrap+0x38>
    yield();
    80002f62:	fffff097          	auipc	ra,0xfffff
    80002f66:	540080e7          	jalr	1344(ra) # 800024a2 <yield>
    80002f6a:	b7bd                	j	80002ed8 <kerneltrap+0x38>

0000000080002f6c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f6c:	1101                	addi	sp,sp,-32
    80002f6e:	ec06                	sd	ra,24(sp)
    80002f70:	e822                	sd	s0,16(sp)
    80002f72:	e426                	sd	s1,8(sp)
    80002f74:	1000                	addi	s0,sp,32
    80002f76:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f78:	fffff097          	auipc	ra,0xfffff
    80002f7c:	d8c080e7          	jalr	-628(ra) # 80001d04 <myproc>
  switch (n) {
    80002f80:	4795                	li	a5,5
    80002f82:	0497e163          	bltu	a5,s1,80002fc4 <argraw+0x58>
    80002f86:	048a                	slli	s1,s1,0x2
    80002f88:	00005717          	auipc	a4,0x5
    80002f8c:	53070713          	addi	a4,a4,1328 # 800084b8 <states.1777+0x170>
    80002f90:	94ba                	add	s1,s1,a4
    80002f92:	409c                	lw	a5,0(s1)
    80002f94:	97ba                	add	a5,a5,a4
    80002f96:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002f98:	6d3c                	ld	a5,88(a0)
    80002f9a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f9c:	60e2                	ld	ra,24(sp)
    80002f9e:	6442                	ld	s0,16(sp)
    80002fa0:	64a2                	ld	s1,8(sp)
    80002fa2:	6105                	addi	sp,sp,32
    80002fa4:	8082                	ret
    return p->trapframe->a1;
    80002fa6:	6d3c                	ld	a5,88(a0)
    80002fa8:	7fa8                	ld	a0,120(a5)
    80002faa:	bfcd                	j	80002f9c <argraw+0x30>
    return p->trapframe->a2;
    80002fac:	6d3c                	ld	a5,88(a0)
    80002fae:	63c8                	ld	a0,128(a5)
    80002fb0:	b7f5                	j	80002f9c <argraw+0x30>
    return p->trapframe->a3;
    80002fb2:	6d3c                	ld	a5,88(a0)
    80002fb4:	67c8                	ld	a0,136(a5)
    80002fb6:	b7dd                	j	80002f9c <argraw+0x30>
    return p->trapframe->a4;
    80002fb8:	6d3c                	ld	a5,88(a0)
    80002fba:	6bc8                	ld	a0,144(a5)
    80002fbc:	b7c5                	j	80002f9c <argraw+0x30>
    return p->trapframe->a5;
    80002fbe:	6d3c                	ld	a5,88(a0)
    80002fc0:	6fc8                	ld	a0,152(a5)
    80002fc2:	bfe9                	j	80002f9c <argraw+0x30>
  panic("argraw");
    80002fc4:	00005517          	auipc	a0,0x5
    80002fc8:	4cc50513          	addi	a0,a0,1228 # 80008490 <states.1777+0x148>
    80002fcc:	ffffd097          	auipc	ra,0xffffd
    80002fd0:	572080e7          	jalr	1394(ra) # 8000053e <panic>

0000000080002fd4 <fetchaddr>:
{
    80002fd4:	1101                	addi	sp,sp,-32
    80002fd6:	ec06                	sd	ra,24(sp)
    80002fd8:	e822                	sd	s0,16(sp)
    80002fda:	e426                	sd	s1,8(sp)
    80002fdc:	e04a                	sd	s2,0(sp)
    80002fde:	1000                	addi	s0,sp,32
    80002fe0:	84aa                	mv	s1,a0
    80002fe2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002fe4:	fffff097          	auipc	ra,0xfffff
    80002fe8:	d20080e7          	jalr	-736(ra) # 80001d04 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002fec:	653c                	ld	a5,72(a0)
    80002fee:	02f4f863          	bgeu	s1,a5,8000301e <fetchaddr+0x4a>
    80002ff2:	00848713          	addi	a4,s1,8
    80002ff6:	02e7e663          	bltu	a5,a4,80003022 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ffa:	46a1                	li	a3,8
    80002ffc:	8626                	mv	a2,s1
    80002ffe:	85ca                	mv	a1,s2
    80003000:	6928                	ld	a0,80(a0)
    80003002:	ffffe097          	auipc	ra,0xffffe
    80003006:	6fc080e7          	jalr	1788(ra) # 800016fe <copyin>
    8000300a:	00a03533          	snez	a0,a0
    8000300e:	40a00533          	neg	a0,a0
}
    80003012:	60e2                	ld	ra,24(sp)
    80003014:	6442                	ld	s0,16(sp)
    80003016:	64a2                	ld	s1,8(sp)
    80003018:	6902                	ld	s2,0(sp)
    8000301a:	6105                	addi	sp,sp,32
    8000301c:	8082                	ret
    return -1;
    8000301e:	557d                	li	a0,-1
    80003020:	bfcd                	j	80003012 <fetchaddr+0x3e>
    80003022:	557d                	li	a0,-1
    80003024:	b7fd                	j	80003012 <fetchaddr+0x3e>

0000000080003026 <fetchstr>:
{
    80003026:	7179                	addi	sp,sp,-48
    80003028:	f406                	sd	ra,40(sp)
    8000302a:	f022                	sd	s0,32(sp)
    8000302c:	ec26                	sd	s1,24(sp)
    8000302e:	e84a                	sd	s2,16(sp)
    80003030:	e44e                	sd	s3,8(sp)
    80003032:	1800                	addi	s0,sp,48
    80003034:	892a                	mv	s2,a0
    80003036:	84ae                	mv	s1,a1
    80003038:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000303a:	fffff097          	auipc	ra,0xfffff
    8000303e:	cca080e7          	jalr	-822(ra) # 80001d04 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003042:	86ce                	mv	a3,s3
    80003044:	864a                	mv	a2,s2
    80003046:	85a6                	mv	a1,s1
    80003048:	6928                	ld	a0,80(a0)
    8000304a:	ffffe097          	auipc	ra,0xffffe
    8000304e:	740080e7          	jalr	1856(ra) # 8000178a <copyinstr>
  if(err < 0)
    80003052:	00054763          	bltz	a0,80003060 <fetchstr+0x3a>
  return strlen(buf);
    80003056:	8526                	mv	a0,s1
    80003058:	ffffe097          	auipc	ra,0xffffe
    8000305c:	e0c080e7          	jalr	-500(ra) # 80000e64 <strlen>
}
    80003060:	70a2                	ld	ra,40(sp)
    80003062:	7402                	ld	s0,32(sp)
    80003064:	64e2                	ld	s1,24(sp)
    80003066:	6942                	ld	s2,16(sp)
    80003068:	69a2                	ld	s3,8(sp)
    8000306a:	6145                	addi	sp,sp,48
    8000306c:	8082                	ret

000000008000306e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000306e:	1101                	addi	sp,sp,-32
    80003070:	ec06                	sd	ra,24(sp)
    80003072:	e822                	sd	s0,16(sp)
    80003074:	e426                	sd	s1,8(sp)
    80003076:	1000                	addi	s0,sp,32
    80003078:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000307a:	00000097          	auipc	ra,0x0
    8000307e:	ef2080e7          	jalr	-270(ra) # 80002f6c <argraw>
    80003082:	c088                	sw	a0,0(s1)
  return 0;
}
    80003084:	4501                	li	a0,0
    80003086:	60e2                	ld	ra,24(sp)
    80003088:	6442                	ld	s0,16(sp)
    8000308a:	64a2                	ld	s1,8(sp)
    8000308c:	6105                	addi	sp,sp,32
    8000308e:	8082                	ret

0000000080003090 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003090:	1101                	addi	sp,sp,-32
    80003092:	ec06                	sd	ra,24(sp)
    80003094:	e822                	sd	s0,16(sp)
    80003096:	e426                	sd	s1,8(sp)
    80003098:	1000                	addi	s0,sp,32
    8000309a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000309c:	00000097          	auipc	ra,0x0
    800030a0:	ed0080e7          	jalr	-304(ra) # 80002f6c <argraw>
    800030a4:	e088                	sd	a0,0(s1)
  return 0;
}
    800030a6:	4501                	li	a0,0
    800030a8:	60e2                	ld	ra,24(sp)
    800030aa:	6442                	ld	s0,16(sp)
    800030ac:	64a2                	ld	s1,8(sp)
    800030ae:	6105                	addi	sp,sp,32
    800030b0:	8082                	ret

00000000800030b2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800030b2:	1101                	addi	sp,sp,-32
    800030b4:	ec06                	sd	ra,24(sp)
    800030b6:	e822                	sd	s0,16(sp)
    800030b8:	e426                	sd	s1,8(sp)
    800030ba:	e04a                	sd	s2,0(sp)
    800030bc:	1000                	addi	s0,sp,32
    800030be:	84ae                	mv	s1,a1
    800030c0:	8932                	mv	s2,a2
  *ip = argraw(n);
    800030c2:	00000097          	auipc	ra,0x0
    800030c6:	eaa080e7          	jalr	-342(ra) # 80002f6c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800030ca:	864a                	mv	a2,s2
    800030cc:	85a6                	mv	a1,s1
    800030ce:	00000097          	auipc	ra,0x0
    800030d2:	f58080e7          	jalr	-168(ra) # 80003026 <fetchstr>
}
    800030d6:	60e2                	ld	ra,24(sp)
    800030d8:	6442                	ld	s0,16(sp)
    800030da:	64a2                	ld	s1,8(sp)
    800030dc:	6902                	ld	s2,0(sp)
    800030de:	6105                	addi	sp,sp,32
    800030e0:	8082                	ret

00000000800030e2 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    800030e2:	1101                	addi	sp,sp,-32
    800030e4:	ec06                	sd	ra,24(sp)
    800030e6:	e822                	sd	s0,16(sp)
    800030e8:	e426                	sd	s1,8(sp)
    800030ea:	e04a                	sd	s2,0(sp)
    800030ec:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800030ee:	fffff097          	auipc	ra,0xfffff
    800030f2:	c16080e7          	jalr	-1002(ra) # 80001d04 <myproc>
    800030f6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800030f8:	05853903          	ld	s2,88(a0)
    800030fc:	0a893783          	ld	a5,168(s2)
    80003100:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003104:	37fd                	addiw	a5,a5,-1
    80003106:	4751                	li	a4,20
    80003108:	00f76f63          	bltu	a4,a5,80003126 <syscall+0x44>
    8000310c:	00369713          	slli	a4,a3,0x3
    80003110:	00005797          	auipc	a5,0x5
    80003114:	3c078793          	addi	a5,a5,960 # 800084d0 <syscalls>
    80003118:	97ba                	add	a5,a5,a4
    8000311a:	639c                	ld	a5,0(a5)
    8000311c:	c789                	beqz	a5,80003126 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000311e:	9782                	jalr	a5
    80003120:	06a93823          	sd	a0,112(s2)
    80003124:	a839                	j	80003142 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003126:	15848613          	addi	a2,s1,344
    8000312a:	588c                	lw	a1,48(s1)
    8000312c:	00005517          	auipc	a0,0x5
    80003130:	36c50513          	addi	a0,a0,876 # 80008498 <states.1777+0x150>
    80003134:	ffffd097          	auipc	ra,0xffffd
    80003138:	454080e7          	jalr	1108(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000313c:	6cbc                	ld	a5,88(s1)
    8000313e:	577d                	li	a4,-1
    80003140:	fbb8                	sd	a4,112(a5)
  }
}
    80003142:	60e2                	ld	ra,24(sp)
    80003144:	6442                	ld	s0,16(sp)
    80003146:	64a2                	ld	s1,8(sp)
    80003148:	6902                	ld	s2,0(sp)
    8000314a:	6105                	addi	sp,sp,32
    8000314c:	8082                	ret

000000008000314e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000314e:	1101                	addi	sp,sp,-32
    80003150:	ec06                	sd	ra,24(sp)
    80003152:	e822                	sd	s0,16(sp)
    80003154:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003156:	fec40593          	addi	a1,s0,-20
    8000315a:	4501                	li	a0,0
    8000315c:	00000097          	auipc	ra,0x0
    80003160:	f12080e7          	jalr	-238(ra) # 8000306e <argint>
    return -1;
    80003164:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003166:	00054963          	bltz	a0,80003178 <sys_exit+0x2a>
  exit(n);
    8000316a:	fec42503          	lw	a0,-20(s0)
    8000316e:	fffff097          	auipc	ra,0xfffff
    80003172:	66e080e7          	jalr	1646(ra) # 800027dc <exit>
  return 0;  // not reached
    80003176:	4781                	li	a5,0
}
    80003178:	853e                	mv	a0,a5
    8000317a:	60e2                	ld	ra,24(sp)
    8000317c:	6442                	ld	s0,16(sp)
    8000317e:	6105                	addi	sp,sp,32
    80003180:	8082                	ret

0000000080003182 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003182:	1141                	addi	sp,sp,-16
    80003184:	e406                	sd	ra,8(sp)
    80003186:	e022                	sd	s0,0(sp)
    80003188:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000318a:	fffff097          	auipc	ra,0xfffff
    8000318e:	b7a080e7          	jalr	-1158(ra) # 80001d04 <myproc>
}
    80003192:	5908                	lw	a0,48(a0)
    80003194:	60a2                	ld	ra,8(sp)
    80003196:	6402                	ld	s0,0(sp)
    80003198:	0141                	addi	sp,sp,16
    8000319a:	8082                	ret

000000008000319c <sys_fork>:

uint64
sys_fork(void)
{
    8000319c:	1141                	addi	sp,sp,-16
    8000319e:	e406                	sd	ra,8(sp)
    800031a0:	e022                	sd	s0,0(sp)
    800031a2:	0800                	addi	s0,sp,16
  return fork();
    800031a4:	fffff097          	auipc	ra,0xfffff
    800031a8:	fe8080e7          	jalr	-24(ra) # 8000218c <fork>
}
    800031ac:	60a2                	ld	ra,8(sp)
    800031ae:	6402                	ld	s0,0(sp)
    800031b0:	0141                	addi	sp,sp,16
    800031b2:	8082                	ret

00000000800031b4 <sys_wait>:

uint64
sys_wait(void)
{
    800031b4:	1101                	addi	sp,sp,-32
    800031b6:	ec06                	sd	ra,24(sp)
    800031b8:	e822                	sd	s0,16(sp)
    800031ba:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800031bc:	fe840593          	addi	a1,s0,-24
    800031c0:	4501                	li	a0,0
    800031c2:	00000097          	auipc	ra,0x0
    800031c6:	ece080e7          	jalr	-306(ra) # 80003090 <argaddr>
    800031ca:	87aa                	mv	a5,a0
    return -1;
    800031cc:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800031ce:	0007c863          	bltz	a5,800031de <sys_wait+0x2a>
  return wait(p);
    800031d2:	fe843503          	ld	a0,-24(s0)
    800031d6:	fffff097          	auipc	ra,0xfffff
    800031da:	3a2080e7          	jalr	930(ra) # 80002578 <wait>
}
    800031de:	60e2                	ld	ra,24(sp)
    800031e0:	6442                	ld	s0,16(sp)
    800031e2:	6105                	addi	sp,sp,32
    800031e4:	8082                	ret

00000000800031e6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800031e6:	7179                	addi	sp,sp,-48
    800031e8:	f406                	sd	ra,40(sp)
    800031ea:	f022                	sd	s0,32(sp)
    800031ec:	ec26                	sd	s1,24(sp)
    800031ee:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800031f0:	fdc40593          	addi	a1,s0,-36
    800031f4:	4501                	li	a0,0
    800031f6:	00000097          	auipc	ra,0x0
    800031fa:	e78080e7          	jalr	-392(ra) # 8000306e <argint>
    800031fe:	87aa                	mv	a5,a0
    return -1;
    80003200:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003202:	0207c063          	bltz	a5,80003222 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003206:	fffff097          	auipc	ra,0xfffff
    8000320a:	afe080e7          	jalr	-1282(ra) # 80001d04 <myproc>
    8000320e:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003210:	fdc42503          	lw	a0,-36(s0)
    80003214:	fffff097          	auipc	ra,0xfffff
    80003218:	f04080e7          	jalr	-252(ra) # 80002118 <growproc>
    8000321c:	00054863          	bltz	a0,8000322c <sys_sbrk+0x46>
    return -1;
  return addr;
    80003220:	8526                	mv	a0,s1
}
    80003222:	70a2                	ld	ra,40(sp)
    80003224:	7402                	ld	s0,32(sp)
    80003226:	64e2                	ld	s1,24(sp)
    80003228:	6145                	addi	sp,sp,48
    8000322a:	8082                	ret
    return -1;
    8000322c:	557d                	li	a0,-1
    8000322e:	bfd5                	j	80003222 <sys_sbrk+0x3c>

0000000080003230 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003230:	7139                	addi	sp,sp,-64
    80003232:	fc06                	sd	ra,56(sp)
    80003234:	f822                	sd	s0,48(sp)
    80003236:	f426                	sd	s1,40(sp)
    80003238:	f04a                	sd	s2,32(sp)
    8000323a:	ec4e                	sd	s3,24(sp)
    8000323c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000323e:	fcc40593          	addi	a1,s0,-52
    80003242:	4501                	li	a0,0
    80003244:	00000097          	auipc	ra,0x0
    80003248:	e2a080e7          	jalr	-470(ra) # 8000306e <argint>
    return -1;
    8000324c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000324e:	06054563          	bltz	a0,800032b8 <sys_sleep+0x88>
  acquire(&tickslock);
    80003252:	00015517          	auipc	a0,0x15
    80003256:	9be50513          	addi	a0,a0,-1602 # 80017c10 <tickslock>
    8000325a:	ffffe097          	auipc	ra,0xffffe
    8000325e:	98a080e7          	jalr	-1654(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003262:	00006917          	auipc	s2,0x6
    80003266:	dce92903          	lw	s2,-562(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000326a:	fcc42783          	lw	a5,-52(s0)
    8000326e:	cf85                	beqz	a5,800032a6 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003270:	00015997          	auipc	s3,0x15
    80003274:	9a098993          	addi	s3,s3,-1632 # 80017c10 <tickslock>
    80003278:	00006497          	auipc	s1,0x6
    8000327c:	db848493          	addi	s1,s1,-584 # 80009030 <ticks>
    if(myproc()->killed){
    80003280:	fffff097          	auipc	ra,0xfffff
    80003284:	a84080e7          	jalr	-1404(ra) # 80001d04 <myproc>
    80003288:	551c                	lw	a5,40(a0)
    8000328a:	ef9d                	bnez	a5,800032c8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000328c:	85ce                	mv	a1,s3
    8000328e:	8526                	mv	a0,s1
    80003290:	fffff097          	auipc	ra,0xfffff
    80003294:	272080e7          	jalr	626(ra) # 80002502 <sleep>
  while(ticks - ticks0 < n){
    80003298:	409c                	lw	a5,0(s1)
    8000329a:	412787bb          	subw	a5,a5,s2
    8000329e:	fcc42703          	lw	a4,-52(s0)
    800032a2:	fce7efe3          	bltu	a5,a4,80003280 <sys_sleep+0x50>
  }
  release(&tickslock);
    800032a6:	00015517          	auipc	a0,0x15
    800032aa:	96a50513          	addi	a0,a0,-1686 # 80017c10 <tickslock>
    800032ae:	ffffe097          	auipc	ra,0xffffe
    800032b2:	9ea080e7          	jalr	-1558(ra) # 80000c98 <release>
  return 0;
    800032b6:	4781                	li	a5,0
}
    800032b8:	853e                	mv	a0,a5
    800032ba:	70e2                	ld	ra,56(sp)
    800032bc:	7442                	ld	s0,48(sp)
    800032be:	74a2                	ld	s1,40(sp)
    800032c0:	7902                	ld	s2,32(sp)
    800032c2:	69e2                	ld	s3,24(sp)
    800032c4:	6121                	addi	sp,sp,64
    800032c6:	8082                	ret
      release(&tickslock);
    800032c8:	00015517          	auipc	a0,0x15
    800032cc:	94850513          	addi	a0,a0,-1720 # 80017c10 <tickslock>
    800032d0:	ffffe097          	auipc	ra,0xffffe
    800032d4:	9c8080e7          	jalr	-1592(ra) # 80000c98 <release>
      return -1;
    800032d8:	57fd                	li	a5,-1
    800032da:	bff9                	j	800032b8 <sys_sleep+0x88>

00000000800032dc <sys_kill>:

uint64
sys_kill(void)
{
    800032dc:	1101                	addi	sp,sp,-32
    800032de:	ec06                	sd	ra,24(sp)
    800032e0:	e822                	sd	s0,16(sp)
    800032e2:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800032e4:	fec40593          	addi	a1,s0,-20
    800032e8:	4501                	li	a0,0
    800032ea:	00000097          	auipc	ra,0x0
    800032ee:	d84080e7          	jalr	-636(ra) # 8000306e <argint>
    800032f2:	87aa                	mv	a5,a0
    return -1;
    800032f4:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800032f6:	0007c863          	bltz	a5,80003306 <sys_kill+0x2a>
  return kill(pid);
    800032fa:	fec42503          	lw	a0,-20(s0)
    800032fe:	fffff097          	auipc	ra,0xfffff
    80003302:	5c6080e7          	jalr	1478(ra) # 800028c4 <kill>
}
    80003306:	60e2                	ld	ra,24(sp)
    80003308:	6442                	ld	s0,16(sp)
    8000330a:	6105                	addi	sp,sp,32
    8000330c:	8082                	ret

000000008000330e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000330e:	1101                	addi	sp,sp,-32
    80003310:	ec06                	sd	ra,24(sp)
    80003312:	e822                	sd	s0,16(sp)
    80003314:	e426                	sd	s1,8(sp)
    80003316:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003318:	00015517          	auipc	a0,0x15
    8000331c:	8f850513          	addi	a0,a0,-1800 # 80017c10 <tickslock>
    80003320:	ffffe097          	auipc	ra,0xffffe
    80003324:	8c4080e7          	jalr	-1852(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003328:	00006497          	auipc	s1,0x6
    8000332c:	d084a483          	lw	s1,-760(s1) # 80009030 <ticks>
  release(&tickslock);
    80003330:	00015517          	auipc	a0,0x15
    80003334:	8e050513          	addi	a0,a0,-1824 # 80017c10 <tickslock>
    80003338:	ffffe097          	auipc	ra,0xffffe
    8000333c:	960080e7          	jalr	-1696(ra) # 80000c98 <release>
  return xticks;
}
    80003340:	02049513          	slli	a0,s1,0x20
    80003344:	9101                	srli	a0,a0,0x20
    80003346:	60e2                	ld	ra,24(sp)
    80003348:	6442                	ld	s0,16(sp)
    8000334a:	64a2                	ld	s1,8(sp)
    8000334c:	6105                	addi	sp,sp,32
    8000334e:	8082                	ret

0000000080003350 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003350:	7179                	addi	sp,sp,-48
    80003352:	f406                	sd	ra,40(sp)
    80003354:	f022                	sd	s0,32(sp)
    80003356:	ec26                	sd	s1,24(sp)
    80003358:	e84a                	sd	s2,16(sp)
    8000335a:	e44e                	sd	s3,8(sp)
    8000335c:	e052                	sd	s4,0(sp)
    8000335e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003360:	00005597          	auipc	a1,0x5
    80003364:	22058593          	addi	a1,a1,544 # 80008580 <syscalls+0xb0>
    80003368:	00015517          	auipc	a0,0x15
    8000336c:	8c050513          	addi	a0,a0,-1856 # 80017c28 <bcache>
    80003370:	ffffd097          	auipc	ra,0xffffd
    80003374:	7e4080e7          	jalr	2020(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003378:	0001d797          	auipc	a5,0x1d
    8000337c:	8b078793          	addi	a5,a5,-1872 # 8001fc28 <bcache+0x8000>
    80003380:	0001d717          	auipc	a4,0x1d
    80003384:	b1070713          	addi	a4,a4,-1264 # 8001fe90 <bcache+0x8268>
    80003388:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000338c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003390:	00015497          	auipc	s1,0x15
    80003394:	8b048493          	addi	s1,s1,-1872 # 80017c40 <bcache+0x18>
    b->next = bcache.head.next;
    80003398:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000339a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000339c:	00005a17          	auipc	s4,0x5
    800033a0:	1eca0a13          	addi	s4,s4,492 # 80008588 <syscalls+0xb8>
    b->next = bcache.head.next;
    800033a4:	2b893783          	ld	a5,696(s2)
    800033a8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800033aa:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800033ae:	85d2                	mv	a1,s4
    800033b0:	01048513          	addi	a0,s1,16
    800033b4:	00001097          	auipc	ra,0x1
    800033b8:	4bc080e7          	jalr	1212(ra) # 80004870 <initsleeplock>
    bcache.head.next->prev = b;
    800033bc:	2b893783          	ld	a5,696(s2)
    800033c0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033c2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033c6:	45848493          	addi	s1,s1,1112
    800033ca:	fd349de3          	bne	s1,s3,800033a4 <binit+0x54>
  }
}
    800033ce:	70a2                	ld	ra,40(sp)
    800033d0:	7402                	ld	s0,32(sp)
    800033d2:	64e2                	ld	s1,24(sp)
    800033d4:	6942                	ld	s2,16(sp)
    800033d6:	69a2                	ld	s3,8(sp)
    800033d8:	6a02                	ld	s4,0(sp)
    800033da:	6145                	addi	sp,sp,48
    800033dc:	8082                	ret

00000000800033de <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800033de:	7179                	addi	sp,sp,-48
    800033e0:	f406                	sd	ra,40(sp)
    800033e2:	f022                	sd	s0,32(sp)
    800033e4:	ec26                	sd	s1,24(sp)
    800033e6:	e84a                	sd	s2,16(sp)
    800033e8:	e44e                	sd	s3,8(sp)
    800033ea:	1800                	addi	s0,sp,48
    800033ec:	89aa                	mv	s3,a0
    800033ee:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800033f0:	00015517          	auipc	a0,0x15
    800033f4:	83850513          	addi	a0,a0,-1992 # 80017c28 <bcache>
    800033f8:	ffffd097          	auipc	ra,0xffffd
    800033fc:	7ec080e7          	jalr	2028(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003400:	0001d497          	auipc	s1,0x1d
    80003404:	ae04b483          	ld	s1,-1312(s1) # 8001fee0 <bcache+0x82b8>
    80003408:	0001d797          	auipc	a5,0x1d
    8000340c:	a8878793          	addi	a5,a5,-1400 # 8001fe90 <bcache+0x8268>
    80003410:	02f48f63          	beq	s1,a5,8000344e <bread+0x70>
    80003414:	873e                	mv	a4,a5
    80003416:	a021                	j	8000341e <bread+0x40>
    80003418:	68a4                	ld	s1,80(s1)
    8000341a:	02e48a63          	beq	s1,a4,8000344e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000341e:	449c                	lw	a5,8(s1)
    80003420:	ff379ce3          	bne	a5,s3,80003418 <bread+0x3a>
    80003424:	44dc                	lw	a5,12(s1)
    80003426:	ff2799e3          	bne	a5,s2,80003418 <bread+0x3a>
      b->refcnt++;
    8000342a:	40bc                	lw	a5,64(s1)
    8000342c:	2785                	addiw	a5,a5,1
    8000342e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003430:	00014517          	auipc	a0,0x14
    80003434:	7f850513          	addi	a0,a0,2040 # 80017c28 <bcache>
    80003438:	ffffe097          	auipc	ra,0xffffe
    8000343c:	860080e7          	jalr	-1952(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003440:	01048513          	addi	a0,s1,16
    80003444:	00001097          	auipc	ra,0x1
    80003448:	466080e7          	jalr	1126(ra) # 800048aa <acquiresleep>
      return b;
    8000344c:	a8b9                	j	800034aa <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000344e:	0001d497          	auipc	s1,0x1d
    80003452:	a8a4b483          	ld	s1,-1398(s1) # 8001fed8 <bcache+0x82b0>
    80003456:	0001d797          	auipc	a5,0x1d
    8000345a:	a3a78793          	addi	a5,a5,-1478 # 8001fe90 <bcache+0x8268>
    8000345e:	00f48863          	beq	s1,a5,8000346e <bread+0x90>
    80003462:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003464:	40bc                	lw	a5,64(s1)
    80003466:	cf81                	beqz	a5,8000347e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003468:	64a4                	ld	s1,72(s1)
    8000346a:	fee49de3          	bne	s1,a4,80003464 <bread+0x86>
  panic("bget: no buffers");
    8000346e:	00005517          	auipc	a0,0x5
    80003472:	12250513          	addi	a0,a0,290 # 80008590 <syscalls+0xc0>
    80003476:	ffffd097          	auipc	ra,0xffffd
    8000347a:	0c8080e7          	jalr	200(ra) # 8000053e <panic>
      b->dev = dev;
    8000347e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003482:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003486:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000348a:	4785                	li	a5,1
    8000348c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000348e:	00014517          	auipc	a0,0x14
    80003492:	79a50513          	addi	a0,a0,1946 # 80017c28 <bcache>
    80003496:	ffffe097          	auipc	ra,0xffffe
    8000349a:	802080e7          	jalr	-2046(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000349e:	01048513          	addi	a0,s1,16
    800034a2:	00001097          	auipc	ra,0x1
    800034a6:	408080e7          	jalr	1032(ra) # 800048aa <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800034aa:	409c                	lw	a5,0(s1)
    800034ac:	cb89                	beqz	a5,800034be <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800034ae:	8526                	mv	a0,s1
    800034b0:	70a2                	ld	ra,40(sp)
    800034b2:	7402                	ld	s0,32(sp)
    800034b4:	64e2                	ld	s1,24(sp)
    800034b6:	6942                	ld	s2,16(sp)
    800034b8:	69a2                	ld	s3,8(sp)
    800034ba:	6145                	addi	sp,sp,48
    800034bc:	8082                	ret
    virtio_disk_rw(b, 0);
    800034be:	4581                	li	a1,0
    800034c0:	8526                	mv	a0,s1
    800034c2:	00003097          	auipc	ra,0x3
    800034c6:	f14080e7          	jalr	-236(ra) # 800063d6 <virtio_disk_rw>
    b->valid = 1;
    800034ca:	4785                	li	a5,1
    800034cc:	c09c                	sw	a5,0(s1)
  return b;
    800034ce:	b7c5                	j	800034ae <bread+0xd0>

00000000800034d0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800034d0:	1101                	addi	sp,sp,-32
    800034d2:	ec06                	sd	ra,24(sp)
    800034d4:	e822                	sd	s0,16(sp)
    800034d6:	e426                	sd	s1,8(sp)
    800034d8:	1000                	addi	s0,sp,32
    800034da:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034dc:	0541                	addi	a0,a0,16
    800034de:	00001097          	auipc	ra,0x1
    800034e2:	466080e7          	jalr	1126(ra) # 80004944 <holdingsleep>
    800034e6:	cd01                	beqz	a0,800034fe <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800034e8:	4585                	li	a1,1
    800034ea:	8526                	mv	a0,s1
    800034ec:	00003097          	auipc	ra,0x3
    800034f0:	eea080e7          	jalr	-278(ra) # 800063d6 <virtio_disk_rw>
}
    800034f4:	60e2                	ld	ra,24(sp)
    800034f6:	6442                	ld	s0,16(sp)
    800034f8:	64a2                	ld	s1,8(sp)
    800034fa:	6105                	addi	sp,sp,32
    800034fc:	8082                	ret
    panic("bwrite");
    800034fe:	00005517          	auipc	a0,0x5
    80003502:	0aa50513          	addi	a0,a0,170 # 800085a8 <syscalls+0xd8>
    80003506:	ffffd097          	auipc	ra,0xffffd
    8000350a:	038080e7          	jalr	56(ra) # 8000053e <panic>

000000008000350e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000350e:	1101                	addi	sp,sp,-32
    80003510:	ec06                	sd	ra,24(sp)
    80003512:	e822                	sd	s0,16(sp)
    80003514:	e426                	sd	s1,8(sp)
    80003516:	e04a                	sd	s2,0(sp)
    80003518:	1000                	addi	s0,sp,32
    8000351a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000351c:	01050913          	addi	s2,a0,16
    80003520:	854a                	mv	a0,s2
    80003522:	00001097          	auipc	ra,0x1
    80003526:	422080e7          	jalr	1058(ra) # 80004944 <holdingsleep>
    8000352a:	c92d                	beqz	a0,8000359c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000352c:	854a                	mv	a0,s2
    8000352e:	00001097          	auipc	ra,0x1
    80003532:	3d2080e7          	jalr	978(ra) # 80004900 <releasesleep>

  acquire(&bcache.lock);
    80003536:	00014517          	auipc	a0,0x14
    8000353a:	6f250513          	addi	a0,a0,1778 # 80017c28 <bcache>
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	6a6080e7          	jalr	1702(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003546:	40bc                	lw	a5,64(s1)
    80003548:	37fd                	addiw	a5,a5,-1
    8000354a:	0007871b          	sext.w	a4,a5
    8000354e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003550:	eb05                	bnez	a4,80003580 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003552:	68bc                	ld	a5,80(s1)
    80003554:	64b8                	ld	a4,72(s1)
    80003556:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003558:	64bc                	ld	a5,72(s1)
    8000355a:	68b8                	ld	a4,80(s1)
    8000355c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000355e:	0001c797          	auipc	a5,0x1c
    80003562:	6ca78793          	addi	a5,a5,1738 # 8001fc28 <bcache+0x8000>
    80003566:	2b87b703          	ld	a4,696(a5)
    8000356a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000356c:	0001d717          	auipc	a4,0x1d
    80003570:	92470713          	addi	a4,a4,-1756 # 8001fe90 <bcache+0x8268>
    80003574:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003576:	2b87b703          	ld	a4,696(a5)
    8000357a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000357c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003580:	00014517          	auipc	a0,0x14
    80003584:	6a850513          	addi	a0,a0,1704 # 80017c28 <bcache>
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	710080e7          	jalr	1808(ra) # 80000c98 <release>
}
    80003590:	60e2                	ld	ra,24(sp)
    80003592:	6442                	ld	s0,16(sp)
    80003594:	64a2                	ld	s1,8(sp)
    80003596:	6902                	ld	s2,0(sp)
    80003598:	6105                	addi	sp,sp,32
    8000359a:	8082                	ret
    panic("brelse");
    8000359c:	00005517          	auipc	a0,0x5
    800035a0:	01450513          	addi	a0,a0,20 # 800085b0 <syscalls+0xe0>
    800035a4:	ffffd097          	auipc	ra,0xffffd
    800035a8:	f9a080e7          	jalr	-102(ra) # 8000053e <panic>

00000000800035ac <bpin>:

void
bpin(struct buf *b) {
    800035ac:	1101                	addi	sp,sp,-32
    800035ae:	ec06                	sd	ra,24(sp)
    800035b0:	e822                	sd	s0,16(sp)
    800035b2:	e426                	sd	s1,8(sp)
    800035b4:	1000                	addi	s0,sp,32
    800035b6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035b8:	00014517          	auipc	a0,0x14
    800035bc:	67050513          	addi	a0,a0,1648 # 80017c28 <bcache>
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	624080e7          	jalr	1572(ra) # 80000be4 <acquire>
  b->refcnt++;
    800035c8:	40bc                	lw	a5,64(s1)
    800035ca:	2785                	addiw	a5,a5,1
    800035cc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035ce:	00014517          	auipc	a0,0x14
    800035d2:	65a50513          	addi	a0,a0,1626 # 80017c28 <bcache>
    800035d6:	ffffd097          	auipc	ra,0xffffd
    800035da:	6c2080e7          	jalr	1730(ra) # 80000c98 <release>
}
    800035de:	60e2                	ld	ra,24(sp)
    800035e0:	6442                	ld	s0,16(sp)
    800035e2:	64a2                	ld	s1,8(sp)
    800035e4:	6105                	addi	sp,sp,32
    800035e6:	8082                	ret

00000000800035e8 <bunpin>:

void
bunpin(struct buf *b) {
    800035e8:	1101                	addi	sp,sp,-32
    800035ea:	ec06                	sd	ra,24(sp)
    800035ec:	e822                	sd	s0,16(sp)
    800035ee:	e426                	sd	s1,8(sp)
    800035f0:	1000                	addi	s0,sp,32
    800035f2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035f4:	00014517          	auipc	a0,0x14
    800035f8:	63450513          	addi	a0,a0,1588 # 80017c28 <bcache>
    800035fc:	ffffd097          	auipc	ra,0xffffd
    80003600:	5e8080e7          	jalr	1512(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003604:	40bc                	lw	a5,64(s1)
    80003606:	37fd                	addiw	a5,a5,-1
    80003608:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000360a:	00014517          	auipc	a0,0x14
    8000360e:	61e50513          	addi	a0,a0,1566 # 80017c28 <bcache>
    80003612:	ffffd097          	auipc	ra,0xffffd
    80003616:	686080e7          	jalr	1670(ra) # 80000c98 <release>
}
    8000361a:	60e2                	ld	ra,24(sp)
    8000361c:	6442                	ld	s0,16(sp)
    8000361e:	64a2                	ld	s1,8(sp)
    80003620:	6105                	addi	sp,sp,32
    80003622:	8082                	ret

0000000080003624 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003624:	1101                	addi	sp,sp,-32
    80003626:	ec06                	sd	ra,24(sp)
    80003628:	e822                	sd	s0,16(sp)
    8000362a:	e426                	sd	s1,8(sp)
    8000362c:	e04a                	sd	s2,0(sp)
    8000362e:	1000                	addi	s0,sp,32
    80003630:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003632:	00d5d59b          	srliw	a1,a1,0xd
    80003636:	0001d797          	auipc	a5,0x1d
    8000363a:	cce7a783          	lw	a5,-818(a5) # 80020304 <sb+0x1c>
    8000363e:	9dbd                	addw	a1,a1,a5
    80003640:	00000097          	auipc	ra,0x0
    80003644:	d9e080e7          	jalr	-610(ra) # 800033de <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003648:	0074f713          	andi	a4,s1,7
    8000364c:	4785                	li	a5,1
    8000364e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003652:	14ce                	slli	s1,s1,0x33
    80003654:	90d9                	srli	s1,s1,0x36
    80003656:	00950733          	add	a4,a0,s1
    8000365a:	05874703          	lbu	a4,88(a4)
    8000365e:	00e7f6b3          	and	a3,a5,a4
    80003662:	c69d                	beqz	a3,80003690 <bfree+0x6c>
    80003664:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003666:	94aa                	add	s1,s1,a0
    80003668:	fff7c793          	not	a5,a5
    8000366c:	8ff9                	and	a5,a5,a4
    8000366e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003672:	00001097          	auipc	ra,0x1
    80003676:	118080e7          	jalr	280(ra) # 8000478a <log_write>
  brelse(bp);
    8000367a:	854a                	mv	a0,s2
    8000367c:	00000097          	auipc	ra,0x0
    80003680:	e92080e7          	jalr	-366(ra) # 8000350e <brelse>
}
    80003684:	60e2                	ld	ra,24(sp)
    80003686:	6442                	ld	s0,16(sp)
    80003688:	64a2                	ld	s1,8(sp)
    8000368a:	6902                	ld	s2,0(sp)
    8000368c:	6105                	addi	sp,sp,32
    8000368e:	8082                	ret
    panic("freeing free block");
    80003690:	00005517          	auipc	a0,0x5
    80003694:	f2850513          	addi	a0,a0,-216 # 800085b8 <syscalls+0xe8>
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	ea6080e7          	jalr	-346(ra) # 8000053e <panic>

00000000800036a0 <balloc>:
{
    800036a0:	711d                	addi	sp,sp,-96
    800036a2:	ec86                	sd	ra,88(sp)
    800036a4:	e8a2                	sd	s0,80(sp)
    800036a6:	e4a6                	sd	s1,72(sp)
    800036a8:	e0ca                	sd	s2,64(sp)
    800036aa:	fc4e                	sd	s3,56(sp)
    800036ac:	f852                	sd	s4,48(sp)
    800036ae:	f456                	sd	s5,40(sp)
    800036b0:	f05a                	sd	s6,32(sp)
    800036b2:	ec5e                	sd	s7,24(sp)
    800036b4:	e862                	sd	s8,16(sp)
    800036b6:	e466                	sd	s9,8(sp)
    800036b8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800036ba:	0001d797          	auipc	a5,0x1d
    800036be:	c327a783          	lw	a5,-974(a5) # 800202ec <sb+0x4>
    800036c2:	cbd1                	beqz	a5,80003756 <balloc+0xb6>
    800036c4:	8baa                	mv	s7,a0
    800036c6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036c8:	0001db17          	auipc	s6,0x1d
    800036cc:	c20b0b13          	addi	s6,s6,-992 # 800202e8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036d0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800036d2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036d4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800036d6:	6c89                	lui	s9,0x2
    800036d8:	a831                	j	800036f4 <balloc+0x54>
    brelse(bp);
    800036da:	854a                	mv	a0,s2
    800036dc:	00000097          	auipc	ra,0x0
    800036e0:	e32080e7          	jalr	-462(ra) # 8000350e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800036e4:	015c87bb          	addw	a5,s9,s5
    800036e8:	00078a9b          	sext.w	s5,a5
    800036ec:	004b2703          	lw	a4,4(s6)
    800036f0:	06eaf363          	bgeu	s5,a4,80003756 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800036f4:	41fad79b          	sraiw	a5,s5,0x1f
    800036f8:	0137d79b          	srliw	a5,a5,0x13
    800036fc:	015787bb          	addw	a5,a5,s5
    80003700:	40d7d79b          	sraiw	a5,a5,0xd
    80003704:	01cb2583          	lw	a1,28(s6)
    80003708:	9dbd                	addw	a1,a1,a5
    8000370a:	855e                	mv	a0,s7
    8000370c:	00000097          	auipc	ra,0x0
    80003710:	cd2080e7          	jalr	-814(ra) # 800033de <bread>
    80003714:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003716:	004b2503          	lw	a0,4(s6)
    8000371a:	000a849b          	sext.w	s1,s5
    8000371e:	8662                	mv	a2,s8
    80003720:	faa4fde3          	bgeu	s1,a0,800036da <balloc+0x3a>
      m = 1 << (bi % 8);
    80003724:	41f6579b          	sraiw	a5,a2,0x1f
    80003728:	01d7d69b          	srliw	a3,a5,0x1d
    8000372c:	00c6873b          	addw	a4,a3,a2
    80003730:	00777793          	andi	a5,a4,7
    80003734:	9f95                	subw	a5,a5,a3
    80003736:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000373a:	4037571b          	sraiw	a4,a4,0x3
    8000373e:	00e906b3          	add	a3,s2,a4
    80003742:	0586c683          	lbu	a3,88(a3)
    80003746:	00d7f5b3          	and	a1,a5,a3
    8000374a:	cd91                	beqz	a1,80003766 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000374c:	2605                	addiw	a2,a2,1
    8000374e:	2485                	addiw	s1,s1,1
    80003750:	fd4618e3          	bne	a2,s4,80003720 <balloc+0x80>
    80003754:	b759                	j	800036da <balloc+0x3a>
  panic("balloc: out of blocks");
    80003756:	00005517          	auipc	a0,0x5
    8000375a:	e7a50513          	addi	a0,a0,-390 # 800085d0 <syscalls+0x100>
    8000375e:	ffffd097          	auipc	ra,0xffffd
    80003762:	de0080e7          	jalr	-544(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003766:	974a                	add	a4,a4,s2
    80003768:	8fd5                	or	a5,a5,a3
    8000376a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000376e:	854a                	mv	a0,s2
    80003770:	00001097          	auipc	ra,0x1
    80003774:	01a080e7          	jalr	26(ra) # 8000478a <log_write>
        brelse(bp);
    80003778:	854a                	mv	a0,s2
    8000377a:	00000097          	auipc	ra,0x0
    8000377e:	d94080e7          	jalr	-620(ra) # 8000350e <brelse>
  bp = bread(dev, bno);
    80003782:	85a6                	mv	a1,s1
    80003784:	855e                	mv	a0,s7
    80003786:	00000097          	auipc	ra,0x0
    8000378a:	c58080e7          	jalr	-936(ra) # 800033de <bread>
    8000378e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003790:	40000613          	li	a2,1024
    80003794:	4581                	li	a1,0
    80003796:	05850513          	addi	a0,a0,88
    8000379a:	ffffd097          	auipc	ra,0xffffd
    8000379e:	546080e7          	jalr	1350(ra) # 80000ce0 <memset>
  log_write(bp);
    800037a2:	854a                	mv	a0,s2
    800037a4:	00001097          	auipc	ra,0x1
    800037a8:	fe6080e7          	jalr	-26(ra) # 8000478a <log_write>
  brelse(bp);
    800037ac:	854a                	mv	a0,s2
    800037ae:	00000097          	auipc	ra,0x0
    800037b2:	d60080e7          	jalr	-672(ra) # 8000350e <brelse>
}
    800037b6:	8526                	mv	a0,s1
    800037b8:	60e6                	ld	ra,88(sp)
    800037ba:	6446                	ld	s0,80(sp)
    800037bc:	64a6                	ld	s1,72(sp)
    800037be:	6906                	ld	s2,64(sp)
    800037c0:	79e2                	ld	s3,56(sp)
    800037c2:	7a42                	ld	s4,48(sp)
    800037c4:	7aa2                	ld	s5,40(sp)
    800037c6:	7b02                	ld	s6,32(sp)
    800037c8:	6be2                	ld	s7,24(sp)
    800037ca:	6c42                	ld	s8,16(sp)
    800037cc:	6ca2                	ld	s9,8(sp)
    800037ce:	6125                	addi	sp,sp,96
    800037d0:	8082                	ret

00000000800037d2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800037d2:	7179                	addi	sp,sp,-48
    800037d4:	f406                	sd	ra,40(sp)
    800037d6:	f022                	sd	s0,32(sp)
    800037d8:	ec26                	sd	s1,24(sp)
    800037da:	e84a                	sd	s2,16(sp)
    800037dc:	e44e                	sd	s3,8(sp)
    800037de:	e052                	sd	s4,0(sp)
    800037e0:	1800                	addi	s0,sp,48
    800037e2:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800037e4:	47ad                	li	a5,11
    800037e6:	04b7fe63          	bgeu	a5,a1,80003842 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800037ea:	ff45849b          	addiw	s1,a1,-12
    800037ee:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800037f2:	0ff00793          	li	a5,255
    800037f6:	0ae7e363          	bltu	a5,a4,8000389c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800037fa:	08052583          	lw	a1,128(a0)
    800037fe:	c5ad                	beqz	a1,80003868 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003800:	00092503          	lw	a0,0(s2)
    80003804:	00000097          	auipc	ra,0x0
    80003808:	bda080e7          	jalr	-1062(ra) # 800033de <bread>
    8000380c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000380e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003812:	02049593          	slli	a1,s1,0x20
    80003816:	9181                	srli	a1,a1,0x20
    80003818:	058a                	slli	a1,a1,0x2
    8000381a:	00b784b3          	add	s1,a5,a1
    8000381e:	0004a983          	lw	s3,0(s1)
    80003822:	04098d63          	beqz	s3,8000387c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003826:	8552                	mv	a0,s4
    80003828:	00000097          	auipc	ra,0x0
    8000382c:	ce6080e7          	jalr	-794(ra) # 8000350e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003830:	854e                	mv	a0,s3
    80003832:	70a2                	ld	ra,40(sp)
    80003834:	7402                	ld	s0,32(sp)
    80003836:	64e2                	ld	s1,24(sp)
    80003838:	6942                	ld	s2,16(sp)
    8000383a:	69a2                	ld	s3,8(sp)
    8000383c:	6a02                	ld	s4,0(sp)
    8000383e:	6145                	addi	sp,sp,48
    80003840:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003842:	02059493          	slli	s1,a1,0x20
    80003846:	9081                	srli	s1,s1,0x20
    80003848:	048a                	slli	s1,s1,0x2
    8000384a:	94aa                	add	s1,s1,a0
    8000384c:	0504a983          	lw	s3,80(s1)
    80003850:	fe0990e3          	bnez	s3,80003830 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003854:	4108                	lw	a0,0(a0)
    80003856:	00000097          	auipc	ra,0x0
    8000385a:	e4a080e7          	jalr	-438(ra) # 800036a0 <balloc>
    8000385e:	0005099b          	sext.w	s3,a0
    80003862:	0534a823          	sw	s3,80(s1)
    80003866:	b7e9                	j	80003830 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003868:	4108                	lw	a0,0(a0)
    8000386a:	00000097          	auipc	ra,0x0
    8000386e:	e36080e7          	jalr	-458(ra) # 800036a0 <balloc>
    80003872:	0005059b          	sext.w	a1,a0
    80003876:	08b92023          	sw	a1,128(s2)
    8000387a:	b759                	j	80003800 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000387c:	00092503          	lw	a0,0(s2)
    80003880:	00000097          	auipc	ra,0x0
    80003884:	e20080e7          	jalr	-480(ra) # 800036a0 <balloc>
    80003888:	0005099b          	sext.w	s3,a0
    8000388c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003890:	8552                	mv	a0,s4
    80003892:	00001097          	auipc	ra,0x1
    80003896:	ef8080e7          	jalr	-264(ra) # 8000478a <log_write>
    8000389a:	b771                	j	80003826 <bmap+0x54>
  panic("bmap: out of range");
    8000389c:	00005517          	auipc	a0,0x5
    800038a0:	d4c50513          	addi	a0,a0,-692 # 800085e8 <syscalls+0x118>
    800038a4:	ffffd097          	auipc	ra,0xffffd
    800038a8:	c9a080e7          	jalr	-870(ra) # 8000053e <panic>

00000000800038ac <iget>:
{
    800038ac:	7179                	addi	sp,sp,-48
    800038ae:	f406                	sd	ra,40(sp)
    800038b0:	f022                	sd	s0,32(sp)
    800038b2:	ec26                	sd	s1,24(sp)
    800038b4:	e84a                	sd	s2,16(sp)
    800038b6:	e44e                	sd	s3,8(sp)
    800038b8:	e052                	sd	s4,0(sp)
    800038ba:	1800                	addi	s0,sp,48
    800038bc:	89aa                	mv	s3,a0
    800038be:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800038c0:	0001d517          	auipc	a0,0x1d
    800038c4:	a4850513          	addi	a0,a0,-1464 # 80020308 <itable>
    800038c8:	ffffd097          	auipc	ra,0xffffd
    800038cc:	31c080e7          	jalr	796(ra) # 80000be4 <acquire>
  empty = 0;
    800038d0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038d2:	0001d497          	auipc	s1,0x1d
    800038d6:	a4e48493          	addi	s1,s1,-1458 # 80020320 <itable+0x18>
    800038da:	0001e697          	auipc	a3,0x1e
    800038de:	4d668693          	addi	a3,a3,1238 # 80021db0 <log>
    800038e2:	a039                	j	800038f0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038e4:	02090b63          	beqz	s2,8000391a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038e8:	08848493          	addi	s1,s1,136
    800038ec:	02d48a63          	beq	s1,a3,80003920 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038f0:	449c                	lw	a5,8(s1)
    800038f2:	fef059e3          	blez	a5,800038e4 <iget+0x38>
    800038f6:	4098                	lw	a4,0(s1)
    800038f8:	ff3716e3          	bne	a4,s3,800038e4 <iget+0x38>
    800038fc:	40d8                	lw	a4,4(s1)
    800038fe:	ff4713e3          	bne	a4,s4,800038e4 <iget+0x38>
      ip->ref++;
    80003902:	2785                	addiw	a5,a5,1
    80003904:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003906:	0001d517          	auipc	a0,0x1d
    8000390a:	a0250513          	addi	a0,a0,-1534 # 80020308 <itable>
    8000390e:	ffffd097          	auipc	ra,0xffffd
    80003912:	38a080e7          	jalr	906(ra) # 80000c98 <release>
      return ip;
    80003916:	8926                	mv	s2,s1
    80003918:	a03d                	j	80003946 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000391a:	f7f9                	bnez	a5,800038e8 <iget+0x3c>
    8000391c:	8926                	mv	s2,s1
    8000391e:	b7e9                	j	800038e8 <iget+0x3c>
  if(empty == 0)
    80003920:	02090c63          	beqz	s2,80003958 <iget+0xac>
  ip->dev = dev;
    80003924:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003928:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000392c:	4785                	li	a5,1
    8000392e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003932:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003936:	0001d517          	auipc	a0,0x1d
    8000393a:	9d250513          	addi	a0,a0,-1582 # 80020308 <itable>
    8000393e:	ffffd097          	auipc	ra,0xffffd
    80003942:	35a080e7          	jalr	858(ra) # 80000c98 <release>
}
    80003946:	854a                	mv	a0,s2
    80003948:	70a2                	ld	ra,40(sp)
    8000394a:	7402                	ld	s0,32(sp)
    8000394c:	64e2                	ld	s1,24(sp)
    8000394e:	6942                	ld	s2,16(sp)
    80003950:	69a2                	ld	s3,8(sp)
    80003952:	6a02                	ld	s4,0(sp)
    80003954:	6145                	addi	sp,sp,48
    80003956:	8082                	ret
    panic("iget: no inodes");
    80003958:	00005517          	auipc	a0,0x5
    8000395c:	ca850513          	addi	a0,a0,-856 # 80008600 <syscalls+0x130>
    80003960:	ffffd097          	auipc	ra,0xffffd
    80003964:	bde080e7          	jalr	-1058(ra) # 8000053e <panic>

0000000080003968 <fsinit>:
fsinit(int dev) {
    80003968:	7179                	addi	sp,sp,-48
    8000396a:	f406                	sd	ra,40(sp)
    8000396c:	f022                	sd	s0,32(sp)
    8000396e:	ec26                	sd	s1,24(sp)
    80003970:	e84a                	sd	s2,16(sp)
    80003972:	e44e                	sd	s3,8(sp)
    80003974:	1800                	addi	s0,sp,48
    80003976:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003978:	4585                	li	a1,1
    8000397a:	00000097          	auipc	ra,0x0
    8000397e:	a64080e7          	jalr	-1436(ra) # 800033de <bread>
    80003982:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003984:	0001d997          	auipc	s3,0x1d
    80003988:	96498993          	addi	s3,s3,-1692 # 800202e8 <sb>
    8000398c:	02000613          	li	a2,32
    80003990:	05850593          	addi	a1,a0,88
    80003994:	854e                	mv	a0,s3
    80003996:	ffffd097          	auipc	ra,0xffffd
    8000399a:	3aa080e7          	jalr	938(ra) # 80000d40 <memmove>
  brelse(bp);
    8000399e:	8526                	mv	a0,s1
    800039a0:	00000097          	auipc	ra,0x0
    800039a4:	b6e080e7          	jalr	-1170(ra) # 8000350e <brelse>
  if(sb.magic != FSMAGIC)
    800039a8:	0009a703          	lw	a4,0(s3)
    800039ac:	102037b7          	lui	a5,0x10203
    800039b0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800039b4:	02f71263          	bne	a4,a5,800039d8 <fsinit+0x70>
  initlog(dev, &sb);
    800039b8:	0001d597          	auipc	a1,0x1d
    800039bc:	93058593          	addi	a1,a1,-1744 # 800202e8 <sb>
    800039c0:	854a                	mv	a0,s2
    800039c2:	00001097          	auipc	ra,0x1
    800039c6:	b4c080e7          	jalr	-1204(ra) # 8000450e <initlog>
}
    800039ca:	70a2                	ld	ra,40(sp)
    800039cc:	7402                	ld	s0,32(sp)
    800039ce:	64e2                	ld	s1,24(sp)
    800039d0:	6942                	ld	s2,16(sp)
    800039d2:	69a2                	ld	s3,8(sp)
    800039d4:	6145                	addi	sp,sp,48
    800039d6:	8082                	ret
    panic("invalid file system");
    800039d8:	00005517          	auipc	a0,0x5
    800039dc:	c3850513          	addi	a0,a0,-968 # 80008610 <syscalls+0x140>
    800039e0:	ffffd097          	auipc	ra,0xffffd
    800039e4:	b5e080e7          	jalr	-1186(ra) # 8000053e <panic>

00000000800039e8 <iinit>:
{
    800039e8:	7179                	addi	sp,sp,-48
    800039ea:	f406                	sd	ra,40(sp)
    800039ec:	f022                	sd	s0,32(sp)
    800039ee:	ec26                	sd	s1,24(sp)
    800039f0:	e84a                	sd	s2,16(sp)
    800039f2:	e44e                	sd	s3,8(sp)
    800039f4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800039f6:	00005597          	auipc	a1,0x5
    800039fa:	c3258593          	addi	a1,a1,-974 # 80008628 <syscalls+0x158>
    800039fe:	0001d517          	auipc	a0,0x1d
    80003a02:	90a50513          	addi	a0,a0,-1782 # 80020308 <itable>
    80003a06:	ffffd097          	auipc	ra,0xffffd
    80003a0a:	14e080e7          	jalr	334(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a0e:	0001d497          	auipc	s1,0x1d
    80003a12:	92248493          	addi	s1,s1,-1758 # 80020330 <itable+0x28>
    80003a16:	0001e997          	auipc	s3,0x1e
    80003a1a:	3aa98993          	addi	s3,s3,938 # 80021dc0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a1e:	00005917          	auipc	s2,0x5
    80003a22:	c1290913          	addi	s2,s2,-1006 # 80008630 <syscalls+0x160>
    80003a26:	85ca                	mv	a1,s2
    80003a28:	8526                	mv	a0,s1
    80003a2a:	00001097          	auipc	ra,0x1
    80003a2e:	e46080e7          	jalr	-442(ra) # 80004870 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a32:	08848493          	addi	s1,s1,136
    80003a36:	ff3498e3          	bne	s1,s3,80003a26 <iinit+0x3e>
}
    80003a3a:	70a2                	ld	ra,40(sp)
    80003a3c:	7402                	ld	s0,32(sp)
    80003a3e:	64e2                	ld	s1,24(sp)
    80003a40:	6942                	ld	s2,16(sp)
    80003a42:	69a2                	ld	s3,8(sp)
    80003a44:	6145                	addi	sp,sp,48
    80003a46:	8082                	ret

0000000080003a48 <ialloc>:
{
    80003a48:	715d                	addi	sp,sp,-80
    80003a4a:	e486                	sd	ra,72(sp)
    80003a4c:	e0a2                	sd	s0,64(sp)
    80003a4e:	fc26                	sd	s1,56(sp)
    80003a50:	f84a                	sd	s2,48(sp)
    80003a52:	f44e                	sd	s3,40(sp)
    80003a54:	f052                	sd	s4,32(sp)
    80003a56:	ec56                	sd	s5,24(sp)
    80003a58:	e85a                	sd	s6,16(sp)
    80003a5a:	e45e                	sd	s7,8(sp)
    80003a5c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a5e:	0001d717          	auipc	a4,0x1d
    80003a62:	89672703          	lw	a4,-1898(a4) # 800202f4 <sb+0xc>
    80003a66:	4785                	li	a5,1
    80003a68:	04e7fa63          	bgeu	a5,a4,80003abc <ialloc+0x74>
    80003a6c:	8aaa                	mv	s5,a0
    80003a6e:	8bae                	mv	s7,a1
    80003a70:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a72:	0001da17          	auipc	s4,0x1d
    80003a76:	876a0a13          	addi	s4,s4,-1930 # 800202e8 <sb>
    80003a7a:	00048b1b          	sext.w	s6,s1
    80003a7e:	0044d593          	srli	a1,s1,0x4
    80003a82:	018a2783          	lw	a5,24(s4)
    80003a86:	9dbd                	addw	a1,a1,a5
    80003a88:	8556                	mv	a0,s5
    80003a8a:	00000097          	auipc	ra,0x0
    80003a8e:	954080e7          	jalr	-1708(ra) # 800033de <bread>
    80003a92:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a94:	05850993          	addi	s3,a0,88
    80003a98:	00f4f793          	andi	a5,s1,15
    80003a9c:	079a                	slli	a5,a5,0x6
    80003a9e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003aa0:	00099783          	lh	a5,0(s3)
    80003aa4:	c785                	beqz	a5,80003acc <ialloc+0x84>
    brelse(bp);
    80003aa6:	00000097          	auipc	ra,0x0
    80003aaa:	a68080e7          	jalr	-1432(ra) # 8000350e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003aae:	0485                	addi	s1,s1,1
    80003ab0:	00ca2703          	lw	a4,12(s4)
    80003ab4:	0004879b          	sext.w	a5,s1
    80003ab8:	fce7e1e3          	bltu	a5,a4,80003a7a <ialloc+0x32>
  panic("ialloc: no inodes");
    80003abc:	00005517          	auipc	a0,0x5
    80003ac0:	b7c50513          	addi	a0,a0,-1156 # 80008638 <syscalls+0x168>
    80003ac4:	ffffd097          	auipc	ra,0xffffd
    80003ac8:	a7a080e7          	jalr	-1414(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003acc:	04000613          	li	a2,64
    80003ad0:	4581                	li	a1,0
    80003ad2:	854e                	mv	a0,s3
    80003ad4:	ffffd097          	auipc	ra,0xffffd
    80003ad8:	20c080e7          	jalr	524(ra) # 80000ce0 <memset>
      dip->type = type;
    80003adc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ae0:	854a                	mv	a0,s2
    80003ae2:	00001097          	auipc	ra,0x1
    80003ae6:	ca8080e7          	jalr	-856(ra) # 8000478a <log_write>
      brelse(bp);
    80003aea:	854a                	mv	a0,s2
    80003aec:	00000097          	auipc	ra,0x0
    80003af0:	a22080e7          	jalr	-1502(ra) # 8000350e <brelse>
      return iget(dev, inum);
    80003af4:	85da                	mv	a1,s6
    80003af6:	8556                	mv	a0,s5
    80003af8:	00000097          	auipc	ra,0x0
    80003afc:	db4080e7          	jalr	-588(ra) # 800038ac <iget>
}
    80003b00:	60a6                	ld	ra,72(sp)
    80003b02:	6406                	ld	s0,64(sp)
    80003b04:	74e2                	ld	s1,56(sp)
    80003b06:	7942                	ld	s2,48(sp)
    80003b08:	79a2                	ld	s3,40(sp)
    80003b0a:	7a02                	ld	s4,32(sp)
    80003b0c:	6ae2                	ld	s5,24(sp)
    80003b0e:	6b42                	ld	s6,16(sp)
    80003b10:	6ba2                	ld	s7,8(sp)
    80003b12:	6161                	addi	sp,sp,80
    80003b14:	8082                	ret

0000000080003b16 <iupdate>:
{
    80003b16:	1101                	addi	sp,sp,-32
    80003b18:	ec06                	sd	ra,24(sp)
    80003b1a:	e822                	sd	s0,16(sp)
    80003b1c:	e426                	sd	s1,8(sp)
    80003b1e:	e04a                	sd	s2,0(sp)
    80003b20:	1000                	addi	s0,sp,32
    80003b22:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b24:	415c                	lw	a5,4(a0)
    80003b26:	0047d79b          	srliw	a5,a5,0x4
    80003b2a:	0001c597          	auipc	a1,0x1c
    80003b2e:	7d65a583          	lw	a1,2006(a1) # 80020300 <sb+0x18>
    80003b32:	9dbd                	addw	a1,a1,a5
    80003b34:	4108                	lw	a0,0(a0)
    80003b36:	00000097          	auipc	ra,0x0
    80003b3a:	8a8080e7          	jalr	-1880(ra) # 800033de <bread>
    80003b3e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b40:	05850793          	addi	a5,a0,88
    80003b44:	40c8                	lw	a0,4(s1)
    80003b46:	893d                	andi	a0,a0,15
    80003b48:	051a                	slli	a0,a0,0x6
    80003b4a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003b4c:	04449703          	lh	a4,68(s1)
    80003b50:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b54:	04649703          	lh	a4,70(s1)
    80003b58:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003b5c:	04849703          	lh	a4,72(s1)
    80003b60:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b64:	04a49703          	lh	a4,74(s1)
    80003b68:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b6c:	44f8                	lw	a4,76(s1)
    80003b6e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b70:	03400613          	li	a2,52
    80003b74:	05048593          	addi	a1,s1,80
    80003b78:	0531                	addi	a0,a0,12
    80003b7a:	ffffd097          	auipc	ra,0xffffd
    80003b7e:	1c6080e7          	jalr	454(ra) # 80000d40 <memmove>
  log_write(bp);
    80003b82:	854a                	mv	a0,s2
    80003b84:	00001097          	auipc	ra,0x1
    80003b88:	c06080e7          	jalr	-1018(ra) # 8000478a <log_write>
  brelse(bp);
    80003b8c:	854a                	mv	a0,s2
    80003b8e:	00000097          	auipc	ra,0x0
    80003b92:	980080e7          	jalr	-1664(ra) # 8000350e <brelse>
}
    80003b96:	60e2                	ld	ra,24(sp)
    80003b98:	6442                	ld	s0,16(sp)
    80003b9a:	64a2                	ld	s1,8(sp)
    80003b9c:	6902                	ld	s2,0(sp)
    80003b9e:	6105                	addi	sp,sp,32
    80003ba0:	8082                	ret

0000000080003ba2 <idup>:
{
    80003ba2:	1101                	addi	sp,sp,-32
    80003ba4:	ec06                	sd	ra,24(sp)
    80003ba6:	e822                	sd	s0,16(sp)
    80003ba8:	e426                	sd	s1,8(sp)
    80003baa:	1000                	addi	s0,sp,32
    80003bac:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bae:	0001c517          	auipc	a0,0x1c
    80003bb2:	75a50513          	addi	a0,a0,1882 # 80020308 <itable>
    80003bb6:	ffffd097          	auipc	ra,0xffffd
    80003bba:	02e080e7          	jalr	46(ra) # 80000be4 <acquire>
  ip->ref++;
    80003bbe:	449c                	lw	a5,8(s1)
    80003bc0:	2785                	addiw	a5,a5,1
    80003bc2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bc4:	0001c517          	auipc	a0,0x1c
    80003bc8:	74450513          	addi	a0,a0,1860 # 80020308 <itable>
    80003bcc:	ffffd097          	auipc	ra,0xffffd
    80003bd0:	0cc080e7          	jalr	204(ra) # 80000c98 <release>
}
    80003bd4:	8526                	mv	a0,s1
    80003bd6:	60e2                	ld	ra,24(sp)
    80003bd8:	6442                	ld	s0,16(sp)
    80003bda:	64a2                	ld	s1,8(sp)
    80003bdc:	6105                	addi	sp,sp,32
    80003bde:	8082                	ret

0000000080003be0 <ilock>:
{
    80003be0:	1101                	addi	sp,sp,-32
    80003be2:	ec06                	sd	ra,24(sp)
    80003be4:	e822                	sd	s0,16(sp)
    80003be6:	e426                	sd	s1,8(sp)
    80003be8:	e04a                	sd	s2,0(sp)
    80003bea:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003bec:	c115                	beqz	a0,80003c10 <ilock+0x30>
    80003bee:	84aa                	mv	s1,a0
    80003bf0:	451c                	lw	a5,8(a0)
    80003bf2:	00f05f63          	blez	a5,80003c10 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003bf6:	0541                	addi	a0,a0,16
    80003bf8:	00001097          	auipc	ra,0x1
    80003bfc:	cb2080e7          	jalr	-846(ra) # 800048aa <acquiresleep>
  if(ip->valid == 0){
    80003c00:	40bc                	lw	a5,64(s1)
    80003c02:	cf99                	beqz	a5,80003c20 <ilock+0x40>
}
    80003c04:	60e2                	ld	ra,24(sp)
    80003c06:	6442                	ld	s0,16(sp)
    80003c08:	64a2                	ld	s1,8(sp)
    80003c0a:	6902                	ld	s2,0(sp)
    80003c0c:	6105                	addi	sp,sp,32
    80003c0e:	8082                	ret
    panic("ilock");
    80003c10:	00005517          	auipc	a0,0x5
    80003c14:	a4050513          	addi	a0,a0,-1472 # 80008650 <syscalls+0x180>
    80003c18:	ffffd097          	auipc	ra,0xffffd
    80003c1c:	926080e7          	jalr	-1754(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c20:	40dc                	lw	a5,4(s1)
    80003c22:	0047d79b          	srliw	a5,a5,0x4
    80003c26:	0001c597          	auipc	a1,0x1c
    80003c2a:	6da5a583          	lw	a1,1754(a1) # 80020300 <sb+0x18>
    80003c2e:	9dbd                	addw	a1,a1,a5
    80003c30:	4088                	lw	a0,0(s1)
    80003c32:	fffff097          	auipc	ra,0xfffff
    80003c36:	7ac080e7          	jalr	1964(ra) # 800033de <bread>
    80003c3a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c3c:	05850593          	addi	a1,a0,88
    80003c40:	40dc                	lw	a5,4(s1)
    80003c42:	8bbd                	andi	a5,a5,15
    80003c44:	079a                	slli	a5,a5,0x6
    80003c46:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c48:	00059783          	lh	a5,0(a1)
    80003c4c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c50:	00259783          	lh	a5,2(a1)
    80003c54:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c58:	00459783          	lh	a5,4(a1)
    80003c5c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c60:	00659783          	lh	a5,6(a1)
    80003c64:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c68:	459c                	lw	a5,8(a1)
    80003c6a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c6c:	03400613          	li	a2,52
    80003c70:	05b1                	addi	a1,a1,12
    80003c72:	05048513          	addi	a0,s1,80
    80003c76:	ffffd097          	auipc	ra,0xffffd
    80003c7a:	0ca080e7          	jalr	202(ra) # 80000d40 <memmove>
    brelse(bp);
    80003c7e:	854a                	mv	a0,s2
    80003c80:	00000097          	auipc	ra,0x0
    80003c84:	88e080e7          	jalr	-1906(ra) # 8000350e <brelse>
    ip->valid = 1;
    80003c88:	4785                	li	a5,1
    80003c8a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c8c:	04449783          	lh	a5,68(s1)
    80003c90:	fbb5                	bnez	a5,80003c04 <ilock+0x24>
      panic("ilock: no type");
    80003c92:	00005517          	auipc	a0,0x5
    80003c96:	9c650513          	addi	a0,a0,-1594 # 80008658 <syscalls+0x188>
    80003c9a:	ffffd097          	auipc	ra,0xffffd
    80003c9e:	8a4080e7          	jalr	-1884(ra) # 8000053e <panic>

0000000080003ca2 <iunlock>:
{
    80003ca2:	1101                	addi	sp,sp,-32
    80003ca4:	ec06                	sd	ra,24(sp)
    80003ca6:	e822                	sd	s0,16(sp)
    80003ca8:	e426                	sd	s1,8(sp)
    80003caa:	e04a                	sd	s2,0(sp)
    80003cac:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003cae:	c905                	beqz	a0,80003cde <iunlock+0x3c>
    80003cb0:	84aa                	mv	s1,a0
    80003cb2:	01050913          	addi	s2,a0,16
    80003cb6:	854a                	mv	a0,s2
    80003cb8:	00001097          	auipc	ra,0x1
    80003cbc:	c8c080e7          	jalr	-884(ra) # 80004944 <holdingsleep>
    80003cc0:	cd19                	beqz	a0,80003cde <iunlock+0x3c>
    80003cc2:	449c                	lw	a5,8(s1)
    80003cc4:	00f05d63          	blez	a5,80003cde <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003cc8:	854a                	mv	a0,s2
    80003cca:	00001097          	auipc	ra,0x1
    80003cce:	c36080e7          	jalr	-970(ra) # 80004900 <releasesleep>
}
    80003cd2:	60e2                	ld	ra,24(sp)
    80003cd4:	6442                	ld	s0,16(sp)
    80003cd6:	64a2                	ld	s1,8(sp)
    80003cd8:	6902                	ld	s2,0(sp)
    80003cda:	6105                	addi	sp,sp,32
    80003cdc:	8082                	ret
    panic("iunlock");
    80003cde:	00005517          	auipc	a0,0x5
    80003ce2:	98a50513          	addi	a0,a0,-1654 # 80008668 <syscalls+0x198>
    80003ce6:	ffffd097          	auipc	ra,0xffffd
    80003cea:	858080e7          	jalr	-1960(ra) # 8000053e <panic>

0000000080003cee <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003cee:	7179                	addi	sp,sp,-48
    80003cf0:	f406                	sd	ra,40(sp)
    80003cf2:	f022                	sd	s0,32(sp)
    80003cf4:	ec26                	sd	s1,24(sp)
    80003cf6:	e84a                	sd	s2,16(sp)
    80003cf8:	e44e                	sd	s3,8(sp)
    80003cfa:	e052                	sd	s4,0(sp)
    80003cfc:	1800                	addi	s0,sp,48
    80003cfe:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d00:	05050493          	addi	s1,a0,80
    80003d04:	08050913          	addi	s2,a0,128
    80003d08:	a021                	j	80003d10 <itrunc+0x22>
    80003d0a:	0491                	addi	s1,s1,4
    80003d0c:	01248d63          	beq	s1,s2,80003d26 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d10:	408c                	lw	a1,0(s1)
    80003d12:	dde5                	beqz	a1,80003d0a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d14:	0009a503          	lw	a0,0(s3)
    80003d18:	00000097          	auipc	ra,0x0
    80003d1c:	90c080e7          	jalr	-1780(ra) # 80003624 <bfree>
      ip->addrs[i] = 0;
    80003d20:	0004a023          	sw	zero,0(s1)
    80003d24:	b7dd                	j	80003d0a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d26:	0809a583          	lw	a1,128(s3)
    80003d2a:	e185                	bnez	a1,80003d4a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d2c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d30:	854e                	mv	a0,s3
    80003d32:	00000097          	auipc	ra,0x0
    80003d36:	de4080e7          	jalr	-540(ra) # 80003b16 <iupdate>
}
    80003d3a:	70a2                	ld	ra,40(sp)
    80003d3c:	7402                	ld	s0,32(sp)
    80003d3e:	64e2                	ld	s1,24(sp)
    80003d40:	6942                	ld	s2,16(sp)
    80003d42:	69a2                	ld	s3,8(sp)
    80003d44:	6a02                	ld	s4,0(sp)
    80003d46:	6145                	addi	sp,sp,48
    80003d48:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d4a:	0009a503          	lw	a0,0(s3)
    80003d4e:	fffff097          	auipc	ra,0xfffff
    80003d52:	690080e7          	jalr	1680(ra) # 800033de <bread>
    80003d56:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d58:	05850493          	addi	s1,a0,88
    80003d5c:	45850913          	addi	s2,a0,1112
    80003d60:	a811                	j	80003d74 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003d62:	0009a503          	lw	a0,0(s3)
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	8be080e7          	jalr	-1858(ra) # 80003624 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003d6e:	0491                	addi	s1,s1,4
    80003d70:	01248563          	beq	s1,s2,80003d7a <itrunc+0x8c>
      if(a[j])
    80003d74:	408c                	lw	a1,0(s1)
    80003d76:	dde5                	beqz	a1,80003d6e <itrunc+0x80>
    80003d78:	b7ed                	j	80003d62 <itrunc+0x74>
    brelse(bp);
    80003d7a:	8552                	mv	a0,s4
    80003d7c:	fffff097          	auipc	ra,0xfffff
    80003d80:	792080e7          	jalr	1938(ra) # 8000350e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d84:	0809a583          	lw	a1,128(s3)
    80003d88:	0009a503          	lw	a0,0(s3)
    80003d8c:	00000097          	auipc	ra,0x0
    80003d90:	898080e7          	jalr	-1896(ra) # 80003624 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d94:	0809a023          	sw	zero,128(s3)
    80003d98:	bf51                	j	80003d2c <itrunc+0x3e>

0000000080003d9a <iput>:
{
    80003d9a:	1101                	addi	sp,sp,-32
    80003d9c:	ec06                	sd	ra,24(sp)
    80003d9e:	e822                	sd	s0,16(sp)
    80003da0:	e426                	sd	s1,8(sp)
    80003da2:	e04a                	sd	s2,0(sp)
    80003da4:	1000                	addi	s0,sp,32
    80003da6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003da8:	0001c517          	auipc	a0,0x1c
    80003dac:	56050513          	addi	a0,a0,1376 # 80020308 <itable>
    80003db0:	ffffd097          	auipc	ra,0xffffd
    80003db4:	e34080e7          	jalr	-460(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003db8:	4498                	lw	a4,8(s1)
    80003dba:	4785                	li	a5,1
    80003dbc:	02f70363          	beq	a4,a5,80003de2 <iput+0x48>
  ip->ref--;
    80003dc0:	449c                	lw	a5,8(s1)
    80003dc2:	37fd                	addiw	a5,a5,-1
    80003dc4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dc6:	0001c517          	auipc	a0,0x1c
    80003dca:	54250513          	addi	a0,a0,1346 # 80020308 <itable>
    80003dce:	ffffd097          	auipc	ra,0xffffd
    80003dd2:	eca080e7          	jalr	-310(ra) # 80000c98 <release>
}
    80003dd6:	60e2                	ld	ra,24(sp)
    80003dd8:	6442                	ld	s0,16(sp)
    80003dda:	64a2                	ld	s1,8(sp)
    80003ddc:	6902                	ld	s2,0(sp)
    80003dde:	6105                	addi	sp,sp,32
    80003de0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003de2:	40bc                	lw	a5,64(s1)
    80003de4:	dff1                	beqz	a5,80003dc0 <iput+0x26>
    80003de6:	04a49783          	lh	a5,74(s1)
    80003dea:	fbf9                	bnez	a5,80003dc0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003dec:	01048913          	addi	s2,s1,16
    80003df0:	854a                	mv	a0,s2
    80003df2:	00001097          	auipc	ra,0x1
    80003df6:	ab8080e7          	jalr	-1352(ra) # 800048aa <acquiresleep>
    release(&itable.lock);
    80003dfa:	0001c517          	auipc	a0,0x1c
    80003dfe:	50e50513          	addi	a0,a0,1294 # 80020308 <itable>
    80003e02:	ffffd097          	auipc	ra,0xffffd
    80003e06:	e96080e7          	jalr	-362(ra) # 80000c98 <release>
    itrunc(ip);
    80003e0a:	8526                	mv	a0,s1
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	ee2080e7          	jalr	-286(ra) # 80003cee <itrunc>
    ip->type = 0;
    80003e14:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e18:	8526                	mv	a0,s1
    80003e1a:	00000097          	auipc	ra,0x0
    80003e1e:	cfc080e7          	jalr	-772(ra) # 80003b16 <iupdate>
    ip->valid = 0;
    80003e22:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e26:	854a                	mv	a0,s2
    80003e28:	00001097          	auipc	ra,0x1
    80003e2c:	ad8080e7          	jalr	-1320(ra) # 80004900 <releasesleep>
    acquire(&itable.lock);
    80003e30:	0001c517          	auipc	a0,0x1c
    80003e34:	4d850513          	addi	a0,a0,1240 # 80020308 <itable>
    80003e38:	ffffd097          	auipc	ra,0xffffd
    80003e3c:	dac080e7          	jalr	-596(ra) # 80000be4 <acquire>
    80003e40:	b741                	j	80003dc0 <iput+0x26>

0000000080003e42 <iunlockput>:
{
    80003e42:	1101                	addi	sp,sp,-32
    80003e44:	ec06                	sd	ra,24(sp)
    80003e46:	e822                	sd	s0,16(sp)
    80003e48:	e426                	sd	s1,8(sp)
    80003e4a:	1000                	addi	s0,sp,32
    80003e4c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e4e:	00000097          	auipc	ra,0x0
    80003e52:	e54080e7          	jalr	-428(ra) # 80003ca2 <iunlock>
  iput(ip);
    80003e56:	8526                	mv	a0,s1
    80003e58:	00000097          	auipc	ra,0x0
    80003e5c:	f42080e7          	jalr	-190(ra) # 80003d9a <iput>
}
    80003e60:	60e2                	ld	ra,24(sp)
    80003e62:	6442                	ld	s0,16(sp)
    80003e64:	64a2                	ld	s1,8(sp)
    80003e66:	6105                	addi	sp,sp,32
    80003e68:	8082                	ret

0000000080003e6a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e6a:	1141                	addi	sp,sp,-16
    80003e6c:	e422                	sd	s0,8(sp)
    80003e6e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e70:	411c                	lw	a5,0(a0)
    80003e72:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e74:	415c                	lw	a5,4(a0)
    80003e76:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e78:	04451783          	lh	a5,68(a0)
    80003e7c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e80:	04a51783          	lh	a5,74(a0)
    80003e84:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e88:	04c56783          	lwu	a5,76(a0)
    80003e8c:	e99c                	sd	a5,16(a1)
}
    80003e8e:	6422                	ld	s0,8(sp)
    80003e90:	0141                	addi	sp,sp,16
    80003e92:	8082                	ret

0000000080003e94 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e94:	457c                	lw	a5,76(a0)
    80003e96:	0ed7e963          	bltu	a5,a3,80003f88 <readi+0xf4>
{
    80003e9a:	7159                	addi	sp,sp,-112
    80003e9c:	f486                	sd	ra,104(sp)
    80003e9e:	f0a2                	sd	s0,96(sp)
    80003ea0:	eca6                	sd	s1,88(sp)
    80003ea2:	e8ca                	sd	s2,80(sp)
    80003ea4:	e4ce                	sd	s3,72(sp)
    80003ea6:	e0d2                	sd	s4,64(sp)
    80003ea8:	fc56                	sd	s5,56(sp)
    80003eaa:	f85a                	sd	s6,48(sp)
    80003eac:	f45e                	sd	s7,40(sp)
    80003eae:	f062                	sd	s8,32(sp)
    80003eb0:	ec66                	sd	s9,24(sp)
    80003eb2:	e86a                	sd	s10,16(sp)
    80003eb4:	e46e                	sd	s11,8(sp)
    80003eb6:	1880                	addi	s0,sp,112
    80003eb8:	8baa                	mv	s7,a0
    80003eba:	8c2e                	mv	s8,a1
    80003ebc:	8ab2                	mv	s5,a2
    80003ebe:	84b6                	mv	s1,a3
    80003ec0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ec2:	9f35                	addw	a4,a4,a3
    return 0;
    80003ec4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ec6:	0ad76063          	bltu	a4,a3,80003f66 <readi+0xd2>
  if(off + n > ip->size)
    80003eca:	00e7f463          	bgeu	a5,a4,80003ed2 <readi+0x3e>
    n = ip->size - off;
    80003ece:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ed2:	0a0b0963          	beqz	s6,80003f84 <readi+0xf0>
    80003ed6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ed8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003edc:	5cfd                	li	s9,-1
    80003ede:	a82d                	j	80003f18 <readi+0x84>
    80003ee0:	020a1d93          	slli	s11,s4,0x20
    80003ee4:	020ddd93          	srli	s11,s11,0x20
    80003ee8:	05890613          	addi	a2,s2,88
    80003eec:	86ee                	mv	a3,s11
    80003eee:	963a                	add	a2,a2,a4
    80003ef0:	85d6                	mv	a1,s5
    80003ef2:	8562                	mv	a0,s8
    80003ef4:	fffff097          	auipc	ra,0xfffff
    80003ef8:	a42080e7          	jalr	-1470(ra) # 80002936 <either_copyout>
    80003efc:	05950d63          	beq	a0,s9,80003f56 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f00:	854a                	mv	a0,s2
    80003f02:	fffff097          	auipc	ra,0xfffff
    80003f06:	60c080e7          	jalr	1548(ra) # 8000350e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f0a:	013a09bb          	addw	s3,s4,s3
    80003f0e:	009a04bb          	addw	s1,s4,s1
    80003f12:	9aee                	add	s5,s5,s11
    80003f14:	0569f763          	bgeu	s3,s6,80003f62 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f18:	000ba903          	lw	s2,0(s7)
    80003f1c:	00a4d59b          	srliw	a1,s1,0xa
    80003f20:	855e                	mv	a0,s7
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	8b0080e7          	jalr	-1872(ra) # 800037d2 <bmap>
    80003f2a:	0005059b          	sext.w	a1,a0
    80003f2e:	854a                	mv	a0,s2
    80003f30:	fffff097          	auipc	ra,0xfffff
    80003f34:	4ae080e7          	jalr	1198(ra) # 800033de <bread>
    80003f38:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f3a:	3ff4f713          	andi	a4,s1,1023
    80003f3e:	40ed07bb          	subw	a5,s10,a4
    80003f42:	413b06bb          	subw	a3,s6,s3
    80003f46:	8a3e                	mv	s4,a5
    80003f48:	2781                	sext.w	a5,a5
    80003f4a:	0006861b          	sext.w	a2,a3
    80003f4e:	f8f679e3          	bgeu	a2,a5,80003ee0 <readi+0x4c>
    80003f52:	8a36                	mv	s4,a3
    80003f54:	b771                	j	80003ee0 <readi+0x4c>
      brelse(bp);
    80003f56:	854a                	mv	a0,s2
    80003f58:	fffff097          	auipc	ra,0xfffff
    80003f5c:	5b6080e7          	jalr	1462(ra) # 8000350e <brelse>
      tot = -1;
    80003f60:	59fd                	li	s3,-1
  }
  return tot;
    80003f62:	0009851b          	sext.w	a0,s3
}
    80003f66:	70a6                	ld	ra,104(sp)
    80003f68:	7406                	ld	s0,96(sp)
    80003f6a:	64e6                	ld	s1,88(sp)
    80003f6c:	6946                	ld	s2,80(sp)
    80003f6e:	69a6                	ld	s3,72(sp)
    80003f70:	6a06                	ld	s4,64(sp)
    80003f72:	7ae2                	ld	s5,56(sp)
    80003f74:	7b42                	ld	s6,48(sp)
    80003f76:	7ba2                	ld	s7,40(sp)
    80003f78:	7c02                	ld	s8,32(sp)
    80003f7a:	6ce2                	ld	s9,24(sp)
    80003f7c:	6d42                	ld	s10,16(sp)
    80003f7e:	6da2                	ld	s11,8(sp)
    80003f80:	6165                	addi	sp,sp,112
    80003f82:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f84:	89da                	mv	s3,s6
    80003f86:	bff1                	j	80003f62 <readi+0xce>
    return 0;
    80003f88:	4501                	li	a0,0
}
    80003f8a:	8082                	ret

0000000080003f8c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f8c:	457c                	lw	a5,76(a0)
    80003f8e:	10d7e863          	bltu	a5,a3,8000409e <writei+0x112>
{
    80003f92:	7159                	addi	sp,sp,-112
    80003f94:	f486                	sd	ra,104(sp)
    80003f96:	f0a2                	sd	s0,96(sp)
    80003f98:	eca6                	sd	s1,88(sp)
    80003f9a:	e8ca                	sd	s2,80(sp)
    80003f9c:	e4ce                	sd	s3,72(sp)
    80003f9e:	e0d2                	sd	s4,64(sp)
    80003fa0:	fc56                	sd	s5,56(sp)
    80003fa2:	f85a                	sd	s6,48(sp)
    80003fa4:	f45e                	sd	s7,40(sp)
    80003fa6:	f062                	sd	s8,32(sp)
    80003fa8:	ec66                	sd	s9,24(sp)
    80003faa:	e86a                	sd	s10,16(sp)
    80003fac:	e46e                	sd	s11,8(sp)
    80003fae:	1880                	addi	s0,sp,112
    80003fb0:	8b2a                	mv	s6,a0
    80003fb2:	8c2e                	mv	s8,a1
    80003fb4:	8ab2                	mv	s5,a2
    80003fb6:	8936                	mv	s2,a3
    80003fb8:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003fba:	00e687bb          	addw	a5,a3,a4
    80003fbe:	0ed7e263          	bltu	a5,a3,800040a2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003fc2:	00043737          	lui	a4,0x43
    80003fc6:	0ef76063          	bltu	a4,a5,800040a6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fca:	0c0b8863          	beqz	s7,8000409a <writei+0x10e>
    80003fce:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fd0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003fd4:	5cfd                	li	s9,-1
    80003fd6:	a091                	j	8000401a <writei+0x8e>
    80003fd8:	02099d93          	slli	s11,s3,0x20
    80003fdc:	020ddd93          	srli	s11,s11,0x20
    80003fe0:	05848513          	addi	a0,s1,88
    80003fe4:	86ee                	mv	a3,s11
    80003fe6:	8656                	mv	a2,s5
    80003fe8:	85e2                	mv	a1,s8
    80003fea:	953a                	add	a0,a0,a4
    80003fec:	fffff097          	auipc	ra,0xfffff
    80003ff0:	9a0080e7          	jalr	-1632(ra) # 8000298c <either_copyin>
    80003ff4:	07950263          	beq	a0,s9,80004058 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ff8:	8526                	mv	a0,s1
    80003ffa:	00000097          	auipc	ra,0x0
    80003ffe:	790080e7          	jalr	1936(ra) # 8000478a <log_write>
    brelse(bp);
    80004002:	8526                	mv	a0,s1
    80004004:	fffff097          	auipc	ra,0xfffff
    80004008:	50a080e7          	jalr	1290(ra) # 8000350e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000400c:	01498a3b          	addw	s4,s3,s4
    80004010:	0129893b          	addw	s2,s3,s2
    80004014:	9aee                	add	s5,s5,s11
    80004016:	057a7663          	bgeu	s4,s7,80004062 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000401a:	000b2483          	lw	s1,0(s6)
    8000401e:	00a9559b          	srliw	a1,s2,0xa
    80004022:	855a                	mv	a0,s6
    80004024:	fffff097          	auipc	ra,0xfffff
    80004028:	7ae080e7          	jalr	1966(ra) # 800037d2 <bmap>
    8000402c:	0005059b          	sext.w	a1,a0
    80004030:	8526                	mv	a0,s1
    80004032:	fffff097          	auipc	ra,0xfffff
    80004036:	3ac080e7          	jalr	940(ra) # 800033de <bread>
    8000403a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000403c:	3ff97713          	andi	a4,s2,1023
    80004040:	40ed07bb          	subw	a5,s10,a4
    80004044:	414b86bb          	subw	a3,s7,s4
    80004048:	89be                	mv	s3,a5
    8000404a:	2781                	sext.w	a5,a5
    8000404c:	0006861b          	sext.w	a2,a3
    80004050:	f8f674e3          	bgeu	a2,a5,80003fd8 <writei+0x4c>
    80004054:	89b6                	mv	s3,a3
    80004056:	b749                	j	80003fd8 <writei+0x4c>
      brelse(bp);
    80004058:	8526                	mv	a0,s1
    8000405a:	fffff097          	auipc	ra,0xfffff
    8000405e:	4b4080e7          	jalr	1204(ra) # 8000350e <brelse>
  }

  if(off > ip->size)
    80004062:	04cb2783          	lw	a5,76(s6)
    80004066:	0127f463          	bgeu	a5,s2,8000406e <writei+0xe2>
    ip->size = off;
    8000406a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000406e:	855a                	mv	a0,s6
    80004070:	00000097          	auipc	ra,0x0
    80004074:	aa6080e7          	jalr	-1370(ra) # 80003b16 <iupdate>

  return tot;
    80004078:	000a051b          	sext.w	a0,s4
}
    8000407c:	70a6                	ld	ra,104(sp)
    8000407e:	7406                	ld	s0,96(sp)
    80004080:	64e6                	ld	s1,88(sp)
    80004082:	6946                	ld	s2,80(sp)
    80004084:	69a6                	ld	s3,72(sp)
    80004086:	6a06                	ld	s4,64(sp)
    80004088:	7ae2                	ld	s5,56(sp)
    8000408a:	7b42                	ld	s6,48(sp)
    8000408c:	7ba2                	ld	s7,40(sp)
    8000408e:	7c02                	ld	s8,32(sp)
    80004090:	6ce2                	ld	s9,24(sp)
    80004092:	6d42                	ld	s10,16(sp)
    80004094:	6da2                	ld	s11,8(sp)
    80004096:	6165                	addi	sp,sp,112
    80004098:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000409a:	8a5e                	mv	s4,s7
    8000409c:	bfc9                	j	8000406e <writei+0xe2>
    return -1;
    8000409e:	557d                	li	a0,-1
}
    800040a0:	8082                	ret
    return -1;
    800040a2:	557d                	li	a0,-1
    800040a4:	bfe1                	j	8000407c <writei+0xf0>
    return -1;
    800040a6:	557d                	li	a0,-1
    800040a8:	bfd1                	j	8000407c <writei+0xf0>

00000000800040aa <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800040aa:	1141                	addi	sp,sp,-16
    800040ac:	e406                	sd	ra,8(sp)
    800040ae:	e022                	sd	s0,0(sp)
    800040b0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800040b2:	4639                	li	a2,14
    800040b4:	ffffd097          	auipc	ra,0xffffd
    800040b8:	d04080e7          	jalr	-764(ra) # 80000db8 <strncmp>
}
    800040bc:	60a2                	ld	ra,8(sp)
    800040be:	6402                	ld	s0,0(sp)
    800040c0:	0141                	addi	sp,sp,16
    800040c2:	8082                	ret

00000000800040c4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800040c4:	7139                	addi	sp,sp,-64
    800040c6:	fc06                	sd	ra,56(sp)
    800040c8:	f822                	sd	s0,48(sp)
    800040ca:	f426                	sd	s1,40(sp)
    800040cc:	f04a                	sd	s2,32(sp)
    800040ce:	ec4e                	sd	s3,24(sp)
    800040d0:	e852                	sd	s4,16(sp)
    800040d2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800040d4:	04451703          	lh	a4,68(a0)
    800040d8:	4785                	li	a5,1
    800040da:	00f71a63          	bne	a4,a5,800040ee <dirlookup+0x2a>
    800040de:	892a                	mv	s2,a0
    800040e0:	89ae                	mv	s3,a1
    800040e2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800040e4:	457c                	lw	a5,76(a0)
    800040e6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800040e8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ea:	e79d                	bnez	a5,80004118 <dirlookup+0x54>
    800040ec:	a8a5                	j	80004164 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800040ee:	00004517          	auipc	a0,0x4
    800040f2:	58250513          	addi	a0,a0,1410 # 80008670 <syscalls+0x1a0>
    800040f6:	ffffc097          	auipc	ra,0xffffc
    800040fa:	448080e7          	jalr	1096(ra) # 8000053e <panic>
      panic("dirlookup read");
    800040fe:	00004517          	auipc	a0,0x4
    80004102:	58a50513          	addi	a0,a0,1418 # 80008688 <syscalls+0x1b8>
    80004106:	ffffc097          	auipc	ra,0xffffc
    8000410a:	438080e7          	jalr	1080(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000410e:	24c1                	addiw	s1,s1,16
    80004110:	04c92783          	lw	a5,76(s2)
    80004114:	04f4f763          	bgeu	s1,a5,80004162 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004118:	4741                	li	a4,16
    8000411a:	86a6                	mv	a3,s1
    8000411c:	fc040613          	addi	a2,s0,-64
    80004120:	4581                	li	a1,0
    80004122:	854a                	mv	a0,s2
    80004124:	00000097          	auipc	ra,0x0
    80004128:	d70080e7          	jalr	-656(ra) # 80003e94 <readi>
    8000412c:	47c1                	li	a5,16
    8000412e:	fcf518e3          	bne	a0,a5,800040fe <dirlookup+0x3a>
    if(de.inum == 0)
    80004132:	fc045783          	lhu	a5,-64(s0)
    80004136:	dfe1                	beqz	a5,8000410e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004138:	fc240593          	addi	a1,s0,-62
    8000413c:	854e                	mv	a0,s3
    8000413e:	00000097          	auipc	ra,0x0
    80004142:	f6c080e7          	jalr	-148(ra) # 800040aa <namecmp>
    80004146:	f561                	bnez	a0,8000410e <dirlookup+0x4a>
      if(poff)
    80004148:	000a0463          	beqz	s4,80004150 <dirlookup+0x8c>
        *poff = off;
    8000414c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004150:	fc045583          	lhu	a1,-64(s0)
    80004154:	00092503          	lw	a0,0(s2)
    80004158:	fffff097          	auipc	ra,0xfffff
    8000415c:	754080e7          	jalr	1876(ra) # 800038ac <iget>
    80004160:	a011                	j	80004164 <dirlookup+0xa0>
  return 0;
    80004162:	4501                	li	a0,0
}
    80004164:	70e2                	ld	ra,56(sp)
    80004166:	7442                	ld	s0,48(sp)
    80004168:	74a2                	ld	s1,40(sp)
    8000416a:	7902                	ld	s2,32(sp)
    8000416c:	69e2                	ld	s3,24(sp)
    8000416e:	6a42                	ld	s4,16(sp)
    80004170:	6121                	addi	sp,sp,64
    80004172:	8082                	ret

0000000080004174 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004174:	711d                	addi	sp,sp,-96
    80004176:	ec86                	sd	ra,88(sp)
    80004178:	e8a2                	sd	s0,80(sp)
    8000417a:	e4a6                	sd	s1,72(sp)
    8000417c:	e0ca                	sd	s2,64(sp)
    8000417e:	fc4e                	sd	s3,56(sp)
    80004180:	f852                	sd	s4,48(sp)
    80004182:	f456                	sd	s5,40(sp)
    80004184:	f05a                	sd	s6,32(sp)
    80004186:	ec5e                	sd	s7,24(sp)
    80004188:	e862                	sd	s8,16(sp)
    8000418a:	e466                	sd	s9,8(sp)
    8000418c:	1080                	addi	s0,sp,96
    8000418e:	84aa                	mv	s1,a0
    80004190:	8b2e                	mv	s6,a1
    80004192:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004194:	00054703          	lbu	a4,0(a0)
    80004198:	02f00793          	li	a5,47
    8000419c:	02f70363          	beq	a4,a5,800041c2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041a0:	ffffe097          	auipc	ra,0xffffe
    800041a4:	b64080e7          	jalr	-1180(ra) # 80001d04 <myproc>
    800041a8:	15053503          	ld	a0,336(a0)
    800041ac:	00000097          	auipc	ra,0x0
    800041b0:	9f6080e7          	jalr	-1546(ra) # 80003ba2 <idup>
    800041b4:	89aa                	mv	s3,a0
  while(*path == '/')
    800041b6:	02f00913          	li	s2,47
  len = path - s;
    800041ba:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800041bc:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800041be:	4c05                	li	s8,1
    800041c0:	a865                	j	80004278 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800041c2:	4585                	li	a1,1
    800041c4:	4505                	li	a0,1
    800041c6:	fffff097          	auipc	ra,0xfffff
    800041ca:	6e6080e7          	jalr	1766(ra) # 800038ac <iget>
    800041ce:	89aa                	mv	s3,a0
    800041d0:	b7dd                	j	800041b6 <namex+0x42>
      iunlockput(ip);
    800041d2:	854e                	mv	a0,s3
    800041d4:	00000097          	auipc	ra,0x0
    800041d8:	c6e080e7          	jalr	-914(ra) # 80003e42 <iunlockput>
      return 0;
    800041dc:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800041de:	854e                	mv	a0,s3
    800041e0:	60e6                	ld	ra,88(sp)
    800041e2:	6446                	ld	s0,80(sp)
    800041e4:	64a6                	ld	s1,72(sp)
    800041e6:	6906                	ld	s2,64(sp)
    800041e8:	79e2                	ld	s3,56(sp)
    800041ea:	7a42                	ld	s4,48(sp)
    800041ec:	7aa2                	ld	s5,40(sp)
    800041ee:	7b02                	ld	s6,32(sp)
    800041f0:	6be2                	ld	s7,24(sp)
    800041f2:	6c42                	ld	s8,16(sp)
    800041f4:	6ca2                	ld	s9,8(sp)
    800041f6:	6125                	addi	sp,sp,96
    800041f8:	8082                	ret
      iunlock(ip);
    800041fa:	854e                	mv	a0,s3
    800041fc:	00000097          	auipc	ra,0x0
    80004200:	aa6080e7          	jalr	-1370(ra) # 80003ca2 <iunlock>
      return ip;
    80004204:	bfe9                	j	800041de <namex+0x6a>
      iunlockput(ip);
    80004206:	854e                	mv	a0,s3
    80004208:	00000097          	auipc	ra,0x0
    8000420c:	c3a080e7          	jalr	-966(ra) # 80003e42 <iunlockput>
      return 0;
    80004210:	89d2                	mv	s3,s4
    80004212:	b7f1                	j	800041de <namex+0x6a>
  len = path - s;
    80004214:	40b48633          	sub	a2,s1,a1
    80004218:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000421c:	094cd463          	bge	s9,s4,800042a4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004220:	4639                	li	a2,14
    80004222:	8556                	mv	a0,s5
    80004224:	ffffd097          	auipc	ra,0xffffd
    80004228:	b1c080e7          	jalr	-1252(ra) # 80000d40 <memmove>
  while(*path == '/')
    8000422c:	0004c783          	lbu	a5,0(s1)
    80004230:	01279763          	bne	a5,s2,8000423e <namex+0xca>
    path++;
    80004234:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004236:	0004c783          	lbu	a5,0(s1)
    8000423a:	ff278de3          	beq	a5,s2,80004234 <namex+0xc0>
    ilock(ip);
    8000423e:	854e                	mv	a0,s3
    80004240:	00000097          	auipc	ra,0x0
    80004244:	9a0080e7          	jalr	-1632(ra) # 80003be0 <ilock>
    if(ip->type != T_DIR){
    80004248:	04499783          	lh	a5,68(s3)
    8000424c:	f98793e3          	bne	a5,s8,800041d2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004250:	000b0563          	beqz	s6,8000425a <namex+0xe6>
    80004254:	0004c783          	lbu	a5,0(s1)
    80004258:	d3cd                	beqz	a5,800041fa <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000425a:	865e                	mv	a2,s7
    8000425c:	85d6                	mv	a1,s5
    8000425e:	854e                	mv	a0,s3
    80004260:	00000097          	auipc	ra,0x0
    80004264:	e64080e7          	jalr	-412(ra) # 800040c4 <dirlookup>
    80004268:	8a2a                	mv	s4,a0
    8000426a:	dd51                	beqz	a0,80004206 <namex+0x92>
    iunlockput(ip);
    8000426c:	854e                	mv	a0,s3
    8000426e:	00000097          	auipc	ra,0x0
    80004272:	bd4080e7          	jalr	-1068(ra) # 80003e42 <iunlockput>
    ip = next;
    80004276:	89d2                	mv	s3,s4
  while(*path == '/')
    80004278:	0004c783          	lbu	a5,0(s1)
    8000427c:	05279763          	bne	a5,s2,800042ca <namex+0x156>
    path++;
    80004280:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004282:	0004c783          	lbu	a5,0(s1)
    80004286:	ff278de3          	beq	a5,s2,80004280 <namex+0x10c>
  if(*path == 0)
    8000428a:	c79d                	beqz	a5,800042b8 <namex+0x144>
    path++;
    8000428c:	85a6                	mv	a1,s1
  len = path - s;
    8000428e:	8a5e                	mv	s4,s7
    80004290:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004292:	01278963          	beq	a5,s2,800042a4 <namex+0x130>
    80004296:	dfbd                	beqz	a5,80004214 <namex+0xa0>
    path++;
    80004298:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000429a:	0004c783          	lbu	a5,0(s1)
    8000429e:	ff279ce3          	bne	a5,s2,80004296 <namex+0x122>
    800042a2:	bf8d                	j	80004214 <namex+0xa0>
    memmove(name, s, len);
    800042a4:	2601                	sext.w	a2,a2
    800042a6:	8556                	mv	a0,s5
    800042a8:	ffffd097          	auipc	ra,0xffffd
    800042ac:	a98080e7          	jalr	-1384(ra) # 80000d40 <memmove>
    name[len] = 0;
    800042b0:	9a56                	add	s4,s4,s5
    800042b2:	000a0023          	sb	zero,0(s4)
    800042b6:	bf9d                	j	8000422c <namex+0xb8>
  if(nameiparent){
    800042b8:	f20b03e3          	beqz	s6,800041de <namex+0x6a>
    iput(ip);
    800042bc:	854e                	mv	a0,s3
    800042be:	00000097          	auipc	ra,0x0
    800042c2:	adc080e7          	jalr	-1316(ra) # 80003d9a <iput>
    return 0;
    800042c6:	4981                	li	s3,0
    800042c8:	bf19                	j	800041de <namex+0x6a>
  if(*path == 0)
    800042ca:	d7fd                	beqz	a5,800042b8 <namex+0x144>
  while(*path != '/' && *path != 0)
    800042cc:	0004c783          	lbu	a5,0(s1)
    800042d0:	85a6                	mv	a1,s1
    800042d2:	b7d1                	j	80004296 <namex+0x122>

00000000800042d4 <dirlink>:
{
    800042d4:	7139                	addi	sp,sp,-64
    800042d6:	fc06                	sd	ra,56(sp)
    800042d8:	f822                	sd	s0,48(sp)
    800042da:	f426                	sd	s1,40(sp)
    800042dc:	f04a                	sd	s2,32(sp)
    800042de:	ec4e                	sd	s3,24(sp)
    800042e0:	e852                	sd	s4,16(sp)
    800042e2:	0080                	addi	s0,sp,64
    800042e4:	892a                	mv	s2,a0
    800042e6:	8a2e                	mv	s4,a1
    800042e8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800042ea:	4601                	li	a2,0
    800042ec:	00000097          	auipc	ra,0x0
    800042f0:	dd8080e7          	jalr	-552(ra) # 800040c4 <dirlookup>
    800042f4:	e93d                	bnez	a0,8000436a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042f6:	04c92483          	lw	s1,76(s2)
    800042fa:	c49d                	beqz	s1,80004328 <dirlink+0x54>
    800042fc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042fe:	4741                	li	a4,16
    80004300:	86a6                	mv	a3,s1
    80004302:	fc040613          	addi	a2,s0,-64
    80004306:	4581                	li	a1,0
    80004308:	854a                	mv	a0,s2
    8000430a:	00000097          	auipc	ra,0x0
    8000430e:	b8a080e7          	jalr	-1142(ra) # 80003e94 <readi>
    80004312:	47c1                	li	a5,16
    80004314:	06f51163          	bne	a0,a5,80004376 <dirlink+0xa2>
    if(de.inum == 0)
    80004318:	fc045783          	lhu	a5,-64(s0)
    8000431c:	c791                	beqz	a5,80004328 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000431e:	24c1                	addiw	s1,s1,16
    80004320:	04c92783          	lw	a5,76(s2)
    80004324:	fcf4ede3          	bltu	s1,a5,800042fe <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004328:	4639                	li	a2,14
    8000432a:	85d2                	mv	a1,s4
    8000432c:	fc240513          	addi	a0,s0,-62
    80004330:	ffffd097          	auipc	ra,0xffffd
    80004334:	ac4080e7          	jalr	-1340(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004338:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000433c:	4741                	li	a4,16
    8000433e:	86a6                	mv	a3,s1
    80004340:	fc040613          	addi	a2,s0,-64
    80004344:	4581                	li	a1,0
    80004346:	854a                	mv	a0,s2
    80004348:	00000097          	auipc	ra,0x0
    8000434c:	c44080e7          	jalr	-956(ra) # 80003f8c <writei>
    80004350:	872a                	mv	a4,a0
    80004352:	47c1                	li	a5,16
  return 0;
    80004354:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004356:	02f71863          	bne	a4,a5,80004386 <dirlink+0xb2>
}
    8000435a:	70e2                	ld	ra,56(sp)
    8000435c:	7442                	ld	s0,48(sp)
    8000435e:	74a2                	ld	s1,40(sp)
    80004360:	7902                	ld	s2,32(sp)
    80004362:	69e2                	ld	s3,24(sp)
    80004364:	6a42                	ld	s4,16(sp)
    80004366:	6121                	addi	sp,sp,64
    80004368:	8082                	ret
    iput(ip);
    8000436a:	00000097          	auipc	ra,0x0
    8000436e:	a30080e7          	jalr	-1488(ra) # 80003d9a <iput>
    return -1;
    80004372:	557d                	li	a0,-1
    80004374:	b7dd                	j	8000435a <dirlink+0x86>
      panic("dirlink read");
    80004376:	00004517          	auipc	a0,0x4
    8000437a:	32250513          	addi	a0,a0,802 # 80008698 <syscalls+0x1c8>
    8000437e:	ffffc097          	auipc	ra,0xffffc
    80004382:	1c0080e7          	jalr	448(ra) # 8000053e <panic>
    panic("dirlink");
    80004386:	00004517          	auipc	a0,0x4
    8000438a:	42250513          	addi	a0,a0,1058 # 800087a8 <syscalls+0x2d8>
    8000438e:	ffffc097          	auipc	ra,0xffffc
    80004392:	1b0080e7          	jalr	432(ra) # 8000053e <panic>

0000000080004396 <namei>:

struct inode*
namei(char *path)
{
    80004396:	1101                	addi	sp,sp,-32
    80004398:	ec06                	sd	ra,24(sp)
    8000439a:	e822                	sd	s0,16(sp)
    8000439c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000439e:	fe040613          	addi	a2,s0,-32
    800043a2:	4581                	li	a1,0
    800043a4:	00000097          	auipc	ra,0x0
    800043a8:	dd0080e7          	jalr	-560(ra) # 80004174 <namex>
}
    800043ac:	60e2                	ld	ra,24(sp)
    800043ae:	6442                	ld	s0,16(sp)
    800043b0:	6105                	addi	sp,sp,32
    800043b2:	8082                	ret

00000000800043b4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043b4:	1141                	addi	sp,sp,-16
    800043b6:	e406                	sd	ra,8(sp)
    800043b8:	e022                	sd	s0,0(sp)
    800043ba:	0800                	addi	s0,sp,16
    800043bc:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800043be:	4585                	li	a1,1
    800043c0:	00000097          	auipc	ra,0x0
    800043c4:	db4080e7          	jalr	-588(ra) # 80004174 <namex>
}
    800043c8:	60a2                	ld	ra,8(sp)
    800043ca:	6402                	ld	s0,0(sp)
    800043cc:	0141                	addi	sp,sp,16
    800043ce:	8082                	ret

00000000800043d0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800043d0:	1101                	addi	sp,sp,-32
    800043d2:	ec06                	sd	ra,24(sp)
    800043d4:	e822                	sd	s0,16(sp)
    800043d6:	e426                	sd	s1,8(sp)
    800043d8:	e04a                	sd	s2,0(sp)
    800043da:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800043dc:	0001e917          	auipc	s2,0x1e
    800043e0:	9d490913          	addi	s2,s2,-1580 # 80021db0 <log>
    800043e4:	01892583          	lw	a1,24(s2)
    800043e8:	02892503          	lw	a0,40(s2)
    800043ec:	fffff097          	auipc	ra,0xfffff
    800043f0:	ff2080e7          	jalr	-14(ra) # 800033de <bread>
    800043f4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800043f6:	02c92683          	lw	a3,44(s2)
    800043fa:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800043fc:	02d05763          	blez	a3,8000442a <write_head+0x5a>
    80004400:	0001e797          	auipc	a5,0x1e
    80004404:	9e078793          	addi	a5,a5,-1568 # 80021de0 <log+0x30>
    80004408:	05c50713          	addi	a4,a0,92
    8000440c:	36fd                	addiw	a3,a3,-1
    8000440e:	1682                	slli	a3,a3,0x20
    80004410:	9281                	srli	a3,a3,0x20
    80004412:	068a                	slli	a3,a3,0x2
    80004414:	0001e617          	auipc	a2,0x1e
    80004418:	9d060613          	addi	a2,a2,-1584 # 80021de4 <log+0x34>
    8000441c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000441e:	4390                	lw	a2,0(a5)
    80004420:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004422:	0791                	addi	a5,a5,4
    80004424:	0711                	addi	a4,a4,4
    80004426:	fed79ce3          	bne	a5,a3,8000441e <write_head+0x4e>
  }
  bwrite(buf);
    8000442a:	8526                	mv	a0,s1
    8000442c:	fffff097          	auipc	ra,0xfffff
    80004430:	0a4080e7          	jalr	164(ra) # 800034d0 <bwrite>
  brelse(buf);
    80004434:	8526                	mv	a0,s1
    80004436:	fffff097          	auipc	ra,0xfffff
    8000443a:	0d8080e7          	jalr	216(ra) # 8000350e <brelse>
}
    8000443e:	60e2                	ld	ra,24(sp)
    80004440:	6442                	ld	s0,16(sp)
    80004442:	64a2                	ld	s1,8(sp)
    80004444:	6902                	ld	s2,0(sp)
    80004446:	6105                	addi	sp,sp,32
    80004448:	8082                	ret

000000008000444a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000444a:	0001e797          	auipc	a5,0x1e
    8000444e:	9927a783          	lw	a5,-1646(a5) # 80021ddc <log+0x2c>
    80004452:	0af05d63          	blez	a5,8000450c <install_trans+0xc2>
{
    80004456:	7139                	addi	sp,sp,-64
    80004458:	fc06                	sd	ra,56(sp)
    8000445a:	f822                	sd	s0,48(sp)
    8000445c:	f426                	sd	s1,40(sp)
    8000445e:	f04a                	sd	s2,32(sp)
    80004460:	ec4e                	sd	s3,24(sp)
    80004462:	e852                	sd	s4,16(sp)
    80004464:	e456                	sd	s5,8(sp)
    80004466:	e05a                	sd	s6,0(sp)
    80004468:	0080                	addi	s0,sp,64
    8000446a:	8b2a                	mv	s6,a0
    8000446c:	0001ea97          	auipc	s5,0x1e
    80004470:	974a8a93          	addi	s5,s5,-1676 # 80021de0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004474:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004476:	0001e997          	auipc	s3,0x1e
    8000447a:	93a98993          	addi	s3,s3,-1734 # 80021db0 <log>
    8000447e:	a035                	j	800044aa <install_trans+0x60>
      bunpin(dbuf);
    80004480:	8526                	mv	a0,s1
    80004482:	fffff097          	auipc	ra,0xfffff
    80004486:	166080e7          	jalr	358(ra) # 800035e8 <bunpin>
    brelse(lbuf);
    8000448a:	854a                	mv	a0,s2
    8000448c:	fffff097          	auipc	ra,0xfffff
    80004490:	082080e7          	jalr	130(ra) # 8000350e <brelse>
    brelse(dbuf);
    80004494:	8526                	mv	a0,s1
    80004496:	fffff097          	auipc	ra,0xfffff
    8000449a:	078080e7          	jalr	120(ra) # 8000350e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000449e:	2a05                	addiw	s4,s4,1
    800044a0:	0a91                	addi	s5,s5,4
    800044a2:	02c9a783          	lw	a5,44(s3)
    800044a6:	04fa5963          	bge	s4,a5,800044f8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044aa:	0189a583          	lw	a1,24(s3)
    800044ae:	014585bb          	addw	a1,a1,s4
    800044b2:	2585                	addiw	a1,a1,1
    800044b4:	0289a503          	lw	a0,40(s3)
    800044b8:	fffff097          	auipc	ra,0xfffff
    800044bc:	f26080e7          	jalr	-218(ra) # 800033de <bread>
    800044c0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800044c2:	000aa583          	lw	a1,0(s5)
    800044c6:	0289a503          	lw	a0,40(s3)
    800044ca:	fffff097          	auipc	ra,0xfffff
    800044ce:	f14080e7          	jalr	-236(ra) # 800033de <bread>
    800044d2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800044d4:	40000613          	li	a2,1024
    800044d8:	05890593          	addi	a1,s2,88
    800044dc:	05850513          	addi	a0,a0,88
    800044e0:	ffffd097          	auipc	ra,0xffffd
    800044e4:	860080e7          	jalr	-1952(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800044e8:	8526                	mv	a0,s1
    800044ea:	fffff097          	auipc	ra,0xfffff
    800044ee:	fe6080e7          	jalr	-26(ra) # 800034d0 <bwrite>
    if(recovering == 0)
    800044f2:	f80b1ce3          	bnez	s6,8000448a <install_trans+0x40>
    800044f6:	b769                	j	80004480 <install_trans+0x36>
}
    800044f8:	70e2                	ld	ra,56(sp)
    800044fa:	7442                	ld	s0,48(sp)
    800044fc:	74a2                	ld	s1,40(sp)
    800044fe:	7902                	ld	s2,32(sp)
    80004500:	69e2                	ld	s3,24(sp)
    80004502:	6a42                	ld	s4,16(sp)
    80004504:	6aa2                	ld	s5,8(sp)
    80004506:	6b02                	ld	s6,0(sp)
    80004508:	6121                	addi	sp,sp,64
    8000450a:	8082                	ret
    8000450c:	8082                	ret

000000008000450e <initlog>:
{
    8000450e:	7179                	addi	sp,sp,-48
    80004510:	f406                	sd	ra,40(sp)
    80004512:	f022                	sd	s0,32(sp)
    80004514:	ec26                	sd	s1,24(sp)
    80004516:	e84a                	sd	s2,16(sp)
    80004518:	e44e                	sd	s3,8(sp)
    8000451a:	1800                	addi	s0,sp,48
    8000451c:	892a                	mv	s2,a0
    8000451e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004520:	0001e497          	auipc	s1,0x1e
    80004524:	89048493          	addi	s1,s1,-1904 # 80021db0 <log>
    80004528:	00004597          	auipc	a1,0x4
    8000452c:	18058593          	addi	a1,a1,384 # 800086a8 <syscalls+0x1d8>
    80004530:	8526                	mv	a0,s1
    80004532:	ffffc097          	auipc	ra,0xffffc
    80004536:	622080e7          	jalr	1570(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000453a:	0149a583          	lw	a1,20(s3)
    8000453e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004540:	0109a783          	lw	a5,16(s3)
    80004544:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004546:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000454a:	854a                	mv	a0,s2
    8000454c:	fffff097          	auipc	ra,0xfffff
    80004550:	e92080e7          	jalr	-366(ra) # 800033de <bread>
  log.lh.n = lh->n;
    80004554:	4d3c                	lw	a5,88(a0)
    80004556:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004558:	02f05563          	blez	a5,80004582 <initlog+0x74>
    8000455c:	05c50713          	addi	a4,a0,92
    80004560:	0001e697          	auipc	a3,0x1e
    80004564:	88068693          	addi	a3,a3,-1920 # 80021de0 <log+0x30>
    80004568:	37fd                	addiw	a5,a5,-1
    8000456a:	1782                	slli	a5,a5,0x20
    8000456c:	9381                	srli	a5,a5,0x20
    8000456e:	078a                	slli	a5,a5,0x2
    80004570:	06050613          	addi	a2,a0,96
    80004574:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004576:	4310                	lw	a2,0(a4)
    80004578:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000457a:	0711                	addi	a4,a4,4
    8000457c:	0691                	addi	a3,a3,4
    8000457e:	fef71ce3          	bne	a4,a5,80004576 <initlog+0x68>
  brelse(buf);
    80004582:	fffff097          	auipc	ra,0xfffff
    80004586:	f8c080e7          	jalr	-116(ra) # 8000350e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000458a:	4505                	li	a0,1
    8000458c:	00000097          	auipc	ra,0x0
    80004590:	ebe080e7          	jalr	-322(ra) # 8000444a <install_trans>
  log.lh.n = 0;
    80004594:	0001e797          	auipc	a5,0x1e
    80004598:	8407a423          	sw	zero,-1976(a5) # 80021ddc <log+0x2c>
  write_head(); // clear the log
    8000459c:	00000097          	auipc	ra,0x0
    800045a0:	e34080e7          	jalr	-460(ra) # 800043d0 <write_head>
}
    800045a4:	70a2                	ld	ra,40(sp)
    800045a6:	7402                	ld	s0,32(sp)
    800045a8:	64e2                	ld	s1,24(sp)
    800045aa:	6942                	ld	s2,16(sp)
    800045ac:	69a2                	ld	s3,8(sp)
    800045ae:	6145                	addi	sp,sp,48
    800045b0:	8082                	ret

00000000800045b2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045b2:	1101                	addi	sp,sp,-32
    800045b4:	ec06                	sd	ra,24(sp)
    800045b6:	e822                	sd	s0,16(sp)
    800045b8:	e426                	sd	s1,8(sp)
    800045ba:	e04a                	sd	s2,0(sp)
    800045bc:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800045be:	0001d517          	auipc	a0,0x1d
    800045c2:	7f250513          	addi	a0,a0,2034 # 80021db0 <log>
    800045c6:	ffffc097          	auipc	ra,0xffffc
    800045ca:	61e080e7          	jalr	1566(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800045ce:	0001d497          	auipc	s1,0x1d
    800045d2:	7e248493          	addi	s1,s1,2018 # 80021db0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045d6:	4979                	li	s2,30
    800045d8:	a039                	j	800045e6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800045da:	85a6                	mv	a1,s1
    800045dc:	8526                	mv	a0,s1
    800045de:	ffffe097          	auipc	ra,0xffffe
    800045e2:	f24080e7          	jalr	-220(ra) # 80002502 <sleep>
    if(log.committing){
    800045e6:	50dc                	lw	a5,36(s1)
    800045e8:	fbed                	bnez	a5,800045da <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045ea:	509c                	lw	a5,32(s1)
    800045ec:	0017871b          	addiw	a4,a5,1
    800045f0:	0007069b          	sext.w	a3,a4
    800045f4:	0027179b          	slliw	a5,a4,0x2
    800045f8:	9fb9                	addw	a5,a5,a4
    800045fa:	0017979b          	slliw	a5,a5,0x1
    800045fe:	54d8                	lw	a4,44(s1)
    80004600:	9fb9                	addw	a5,a5,a4
    80004602:	00f95963          	bge	s2,a5,80004614 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004606:	85a6                	mv	a1,s1
    80004608:	8526                	mv	a0,s1
    8000460a:	ffffe097          	auipc	ra,0xffffe
    8000460e:	ef8080e7          	jalr	-264(ra) # 80002502 <sleep>
    80004612:	bfd1                	j	800045e6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004614:	0001d517          	auipc	a0,0x1d
    80004618:	79c50513          	addi	a0,a0,1948 # 80021db0 <log>
    8000461c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	67a080e7          	jalr	1658(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004626:	60e2                	ld	ra,24(sp)
    80004628:	6442                	ld	s0,16(sp)
    8000462a:	64a2                	ld	s1,8(sp)
    8000462c:	6902                	ld	s2,0(sp)
    8000462e:	6105                	addi	sp,sp,32
    80004630:	8082                	ret

0000000080004632 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004632:	7139                	addi	sp,sp,-64
    80004634:	fc06                	sd	ra,56(sp)
    80004636:	f822                	sd	s0,48(sp)
    80004638:	f426                	sd	s1,40(sp)
    8000463a:	f04a                	sd	s2,32(sp)
    8000463c:	ec4e                	sd	s3,24(sp)
    8000463e:	e852                	sd	s4,16(sp)
    80004640:	e456                	sd	s5,8(sp)
    80004642:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004644:	0001d497          	auipc	s1,0x1d
    80004648:	76c48493          	addi	s1,s1,1900 # 80021db0 <log>
    8000464c:	8526                	mv	a0,s1
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	596080e7          	jalr	1430(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004656:	509c                	lw	a5,32(s1)
    80004658:	37fd                	addiw	a5,a5,-1
    8000465a:	0007891b          	sext.w	s2,a5
    8000465e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004660:	50dc                	lw	a5,36(s1)
    80004662:	efb9                	bnez	a5,800046c0 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004664:	06091663          	bnez	s2,800046d0 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004668:	0001d497          	auipc	s1,0x1d
    8000466c:	74848493          	addi	s1,s1,1864 # 80021db0 <log>
    80004670:	4785                	li	a5,1
    80004672:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004674:	8526                	mv	a0,s1
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	622080e7          	jalr	1570(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000467e:	54dc                	lw	a5,44(s1)
    80004680:	06f04763          	bgtz	a5,800046ee <end_op+0xbc>
    acquire(&log.lock);
    80004684:	0001d497          	auipc	s1,0x1d
    80004688:	72c48493          	addi	s1,s1,1836 # 80021db0 <log>
    8000468c:	8526                	mv	a0,s1
    8000468e:	ffffc097          	auipc	ra,0xffffc
    80004692:	556080e7          	jalr	1366(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004696:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000469a:	8526                	mv	a0,s1
    8000469c:	ffffe097          	auipc	ra,0xffffe
    800046a0:	004080e7          	jalr	4(ra) # 800026a0 <wakeup>
    release(&log.lock);
    800046a4:	8526                	mv	a0,s1
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	5f2080e7          	jalr	1522(ra) # 80000c98 <release>
}
    800046ae:	70e2                	ld	ra,56(sp)
    800046b0:	7442                	ld	s0,48(sp)
    800046b2:	74a2                	ld	s1,40(sp)
    800046b4:	7902                	ld	s2,32(sp)
    800046b6:	69e2                	ld	s3,24(sp)
    800046b8:	6a42                	ld	s4,16(sp)
    800046ba:	6aa2                	ld	s5,8(sp)
    800046bc:	6121                	addi	sp,sp,64
    800046be:	8082                	ret
    panic("log.committing");
    800046c0:	00004517          	auipc	a0,0x4
    800046c4:	ff050513          	addi	a0,a0,-16 # 800086b0 <syscalls+0x1e0>
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	e76080e7          	jalr	-394(ra) # 8000053e <panic>
    wakeup(&log);
    800046d0:	0001d497          	auipc	s1,0x1d
    800046d4:	6e048493          	addi	s1,s1,1760 # 80021db0 <log>
    800046d8:	8526                	mv	a0,s1
    800046da:	ffffe097          	auipc	ra,0xffffe
    800046de:	fc6080e7          	jalr	-58(ra) # 800026a0 <wakeup>
  release(&log.lock);
    800046e2:	8526                	mv	a0,s1
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	5b4080e7          	jalr	1460(ra) # 80000c98 <release>
  if(do_commit){
    800046ec:	b7c9                	j	800046ae <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046ee:	0001da97          	auipc	s5,0x1d
    800046f2:	6f2a8a93          	addi	s5,s5,1778 # 80021de0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800046f6:	0001da17          	auipc	s4,0x1d
    800046fa:	6baa0a13          	addi	s4,s4,1722 # 80021db0 <log>
    800046fe:	018a2583          	lw	a1,24(s4)
    80004702:	012585bb          	addw	a1,a1,s2
    80004706:	2585                	addiw	a1,a1,1
    80004708:	028a2503          	lw	a0,40(s4)
    8000470c:	fffff097          	auipc	ra,0xfffff
    80004710:	cd2080e7          	jalr	-814(ra) # 800033de <bread>
    80004714:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004716:	000aa583          	lw	a1,0(s5)
    8000471a:	028a2503          	lw	a0,40(s4)
    8000471e:	fffff097          	auipc	ra,0xfffff
    80004722:	cc0080e7          	jalr	-832(ra) # 800033de <bread>
    80004726:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004728:	40000613          	li	a2,1024
    8000472c:	05850593          	addi	a1,a0,88
    80004730:	05848513          	addi	a0,s1,88
    80004734:	ffffc097          	auipc	ra,0xffffc
    80004738:	60c080e7          	jalr	1548(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000473c:	8526                	mv	a0,s1
    8000473e:	fffff097          	auipc	ra,0xfffff
    80004742:	d92080e7          	jalr	-622(ra) # 800034d0 <bwrite>
    brelse(from);
    80004746:	854e                	mv	a0,s3
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	dc6080e7          	jalr	-570(ra) # 8000350e <brelse>
    brelse(to);
    80004750:	8526                	mv	a0,s1
    80004752:	fffff097          	auipc	ra,0xfffff
    80004756:	dbc080e7          	jalr	-580(ra) # 8000350e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000475a:	2905                	addiw	s2,s2,1
    8000475c:	0a91                	addi	s5,s5,4
    8000475e:	02ca2783          	lw	a5,44(s4)
    80004762:	f8f94ee3          	blt	s2,a5,800046fe <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004766:	00000097          	auipc	ra,0x0
    8000476a:	c6a080e7          	jalr	-918(ra) # 800043d0 <write_head>
    install_trans(0); // Now install writes to home locations
    8000476e:	4501                	li	a0,0
    80004770:	00000097          	auipc	ra,0x0
    80004774:	cda080e7          	jalr	-806(ra) # 8000444a <install_trans>
    log.lh.n = 0;
    80004778:	0001d797          	auipc	a5,0x1d
    8000477c:	6607a223          	sw	zero,1636(a5) # 80021ddc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004780:	00000097          	auipc	ra,0x0
    80004784:	c50080e7          	jalr	-944(ra) # 800043d0 <write_head>
    80004788:	bdf5                	j	80004684 <end_op+0x52>

000000008000478a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000478a:	1101                	addi	sp,sp,-32
    8000478c:	ec06                	sd	ra,24(sp)
    8000478e:	e822                	sd	s0,16(sp)
    80004790:	e426                	sd	s1,8(sp)
    80004792:	e04a                	sd	s2,0(sp)
    80004794:	1000                	addi	s0,sp,32
    80004796:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004798:	0001d917          	auipc	s2,0x1d
    8000479c:	61890913          	addi	s2,s2,1560 # 80021db0 <log>
    800047a0:	854a                	mv	a0,s2
    800047a2:	ffffc097          	auipc	ra,0xffffc
    800047a6:	442080e7          	jalr	1090(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800047aa:	02c92603          	lw	a2,44(s2)
    800047ae:	47f5                	li	a5,29
    800047b0:	06c7c563          	blt	a5,a2,8000481a <log_write+0x90>
    800047b4:	0001d797          	auipc	a5,0x1d
    800047b8:	6187a783          	lw	a5,1560(a5) # 80021dcc <log+0x1c>
    800047bc:	37fd                	addiw	a5,a5,-1
    800047be:	04f65e63          	bge	a2,a5,8000481a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800047c2:	0001d797          	auipc	a5,0x1d
    800047c6:	60e7a783          	lw	a5,1550(a5) # 80021dd0 <log+0x20>
    800047ca:	06f05063          	blez	a5,8000482a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800047ce:	4781                	li	a5,0
    800047d0:	06c05563          	blez	a2,8000483a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047d4:	44cc                	lw	a1,12(s1)
    800047d6:	0001d717          	auipc	a4,0x1d
    800047da:	60a70713          	addi	a4,a4,1546 # 80021de0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800047de:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047e0:	4314                	lw	a3,0(a4)
    800047e2:	04b68c63          	beq	a3,a1,8000483a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800047e6:	2785                	addiw	a5,a5,1
    800047e8:	0711                	addi	a4,a4,4
    800047ea:	fef61be3          	bne	a2,a5,800047e0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800047ee:	0621                	addi	a2,a2,8
    800047f0:	060a                	slli	a2,a2,0x2
    800047f2:	0001d797          	auipc	a5,0x1d
    800047f6:	5be78793          	addi	a5,a5,1470 # 80021db0 <log>
    800047fa:	963e                	add	a2,a2,a5
    800047fc:	44dc                	lw	a5,12(s1)
    800047fe:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004800:	8526                	mv	a0,s1
    80004802:	fffff097          	auipc	ra,0xfffff
    80004806:	daa080e7          	jalr	-598(ra) # 800035ac <bpin>
    log.lh.n++;
    8000480a:	0001d717          	auipc	a4,0x1d
    8000480e:	5a670713          	addi	a4,a4,1446 # 80021db0 <log>
    80004812:	575c                	lw	a5,44(a4)
    80004814:	2785                	addiw	a5,a5,1
    80004816:	d75c                	sw	a5,44(a4)
    80004818:	a835                	j	80004854 <log_write+0xca>
    panic("too big a transaction");
    8000481a:	00004517          	auipc	a0,0x4
    8000481e:	ea650513          	addi	a0,a0,-346 # 800086c0 <syscalls+0x1f0>
    80004822:	ffffc097          	auipc	ra,0xffffc
    80004826:	d1c080e7          	jalr	-740(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000482a:	00004517          	auipc	a0,0x4
    8000482e:	eae50513          	addi	a0,a0,-338 # 800086d8 <syscalls+0x208>
    80004832:	ffffc097          	auipc	ra,0xffffc
    80004836:	d0c080e7          	jalr	-756(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000483a:	00878713          	addi	a4,a5,8
    8000483e:	00271693          	slli	a3,a4,0x2
    80004842:	0001d717          	auipc	a4,0x1d
    80004846:	56e70713          	addi	a4,a4,1390 # 80021db0 <log>
    8000484a:	9736                	add	a4,a4,a3
    8000484c:	44d4                	lw	a3,12(s1)
    8000484e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004850:	faf608e3          	beq	a2,a5,80004800 <log_write+0x76>
  }
  release(&log.lock);
    80004854:	0001d517          	auipc	a0,0x1d
    80004858:	55c50513          	addi	a0,a0,1372 # 80021db0 <log>
    8000485c:	ffffc097          	auipc	ra,0xffffc
    80004860:	43c080e7          	jalr	1084(ra) # 80000c98 <release>
}
    80004864:	60e2                	ld	ra,24(sp)
    80004866:	6442                	ld	s0,16(sp)
    80004868:	64a2                	ld	s1,8(sp)
    8000486a:	6902                	ld	s2,0(sp)
    8000486c:	6105                	addi	sp,sp,32
    8000486e:	8082                	ret

0000000080004870 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004870:	1101                	addi	sp,sp,-32
    80004872:	ec06                	sd	ra,24(sp)
    80004874:	e822                	sd	s0,16(sp)
    80004876:	e426                	sd	s1,8(sp)
    80004878:	e04a                	sd	s2,0(sp)
    8000487a:	1000                	addi	s0,sp,32
    8000487c:	84aa                	mv	s1,a0
    8000487e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004880:	00004597          	auipc	a1,0x4
    80004884:	e7858593          	addi	a1,a1,-392 # 800086f8 <syscalls+0x228>
    80004888:	0521                	addi	a0,a0,8
    8000488a:	ffffc097          	auipc	ra,0xffffc
    8000488e:	2ca080e7          	jalr	714(ra) # 80000b54 <initlock>
  lk->name = name;
    80004892:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004896:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000489a:	0204a423          	sw	zero,40(s1)
}
    8000489e:	60e2                	ld	ra,24(sp)
    800048a0:	6442                	ld	s0,16(sp)
    800048a2:	64a2                	ld	s1,8(sp)
    800048a4:	6902                	ld	s2,0(sp)
    800048a6:	6105                	addi	sp,sp,32
    800048a8:	8082                	ret

00000000800048aa <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800048aa:	1101                	addi	sp,sp,-32
    800048ac:	ec06                	sd	ra,24(sp)
    800048ae:	e822                	sd	s0,16(sp)
    800048b0:	e426                	sd	s1,8(sp)
    800048b2:	e04a                	sd	s2,0(sp)
    800048b4:	1000                	addi	s0,sp,32
    800048b6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048b8:	00850913          	addi	s2,a0,8
    800048bc:	854a                	mv	a0,s2
    800048be:	ffffc097          	auipc	ra,0xffffc
    800048c2:	326080e7          	jalr	806(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800048c6:	409c                	lw	a5,0(s1)
    800048c8:	cb89                	beqz	a5,800048da <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800048ca:	85ca                	mv	a1,s2
    800048cc:	8526                	mv	a0,s1
    800048ce:	ffffe097          	auipc	ra,0xffffe
    800048d2:	c34080e7          	jalr	-972(ra) # 80002502 <sleep>
  while (lk->locked) {
    800048d6:	409c                	lw	a5,0(s1)
    800048d8:	fbed                	bnez	a5,800048ca <acquiresleep+0x20>
  }
  lk->locked = 1;
    800048da:	4785                	li	a5,1
    800048dc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800048de:	ffffd097          	auipc	ra,0xffffd
    800048e2:	426080e7          	jalr	1062(ra) # 80001d04 <myproc>
    800048e6:	591c                	lw	a5,48(a0)
    800048e8:	d49c                	sw	a5,40(s1)
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

0000000080004900 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004900:	1101                	addi	sp,sp,-32
    80004902:	ec06                	sd	ra,24(sp)
    80004904:	e822                	sd	s0,16(sp)
    80004906:	e426                	sd	s1,8(sp)
    80004908:	e04a                	sd	s2,0(sp)
    8000490a:	1000                	addi	s0,sp,32
    8000490c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000490e:	00850913          	addi	s2,a0,8
    80004912:	854a                	mv	a0,s2
    80004914:	ffffc097          	auipc	ra,0xffffc
    80004918:	2d0080e7          	jalr	720(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000491c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004920:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004924:	8526                	mv	a0,s1
    80004926:	ffffe097          	auipc	ra,0xffffe
    8000492a:	d7a080e7          	jalr	-646(ra) # 800026a0 <wakeup>
  release(&lk->lk);
    8000492e:	854a                	mv	a0,s2
    80004930:	ffffc097          	auipc	ra,0xffffc
    80004934:	368080e7          	jalr	872(ra) # 80000c98 <release>
}
    80004938:	60e2                	ld	ra,24(sp)
    8000493a:	6442                	ld	s0,16(sp)
    8000493c:	64a2                	ld	s1,8(sp)
    8000493e:	6902                	ld	s2,0(sp)
    80004940:	6105                	addi	sp,sp,32
    80004942:	8082                	ret

0000000080004944 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004944:	7179                	addi	sp,sp,-48
    80004946:	f406                	sd	ra,40(sp)
    80004948:	f022                	sd	s0,32(sp)
    8000494a:	ec26                	sd	s1,24(sp)
    8000494c:	e84a                	sd	s2,16(sp)
    8000494e:	e44e                	sd	s3,8(sp)
    80004950:	1800                	addi	s0,sp,48
    80004952:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004954:	00850913          	addi	s2,a0,8
    80004958:	854a                	mv	a0,s2
    8000495a:	ffffc097          	auipc	ra,0xffffc
    8000495e:	28a080e7          	jalr	650(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004962:	409c                	lw	a5,0(s1)
    80004964:	ef99                	bnez	a5,80004982 <holdingsleep+0x3e>
    80004966:	4481                	li	s1,0
  release(&lk->lk);
    80004968:	854a                	mv	a0,s2
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	32e080e7          	jalr	814(ra) # 80000c98 <release>
  return r;
}
    80004972:	8526                	mv	a0,s1
    80004974:	70a2                	ld	ra,40(sp)
    80004976:	7402                	ld	s0,32(sp)
    80004978:	64e2                	ld	s1,24(sp)
    8000497a:	6942                	ld	s2,16(sp)
    8000497c:	69a2                	ld	s3,8(sp)
    8000497e:	6145                	addi	sp,sp,48
    80004980:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004982:	0284a983          	lw	s3,40(s1)
    80004986:	ffffd097          	auipc	ra,0xffffd
    8000498a:	37e080e7          	jalr	894(ra) # 80001d04 <myproc>
    8000498e:	5904                	lw	s1,48(a0)
    80004990:	413484b3          	sub	s1,s1,s3
    80004994:	0014b493          	seqz	s1,s1
    80004998:	bfc1                	j	80004968 <holdingsleep+0x24>

000000008000499a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000499a:	1141                	addi	sp,sp,-16
    8000499c:	e406                	sd	ra,8(sp)
    8000499e:	e022                	sd	s0,0(sp)
    800049a0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049a2:	00004597          	auipc	a1,0x4
    800049a6:	d6658593          	addi	a1,a1,-666 # 80008708 <syscalls+0x238>
    800049aa:	0001d517          	auipc	a0,0x1d
    800049ae:	54e50513          	addi	a0,a0,1358 # 80021ef8 <ftable>
    800049b2:	ffffc097          	auipc	ra,0xffffc
    800049b6:	1a2080e7          	jalr	418(ra) # 80000b54 <initlock>
}
    800049ba:	60a2                	ld	ra,8(sp)
    800049bc:	6402                	ld	s0,0(sp)
    800049be:	0141                	addi	sp,sp,16
    800049c0:	8082                	ret

00000000800049c2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800049c2:	1101                	addi	sp,sp,-32
    800049c4:	ec06                	sd	ra,24(sp)
    800049c6:	e822                	sd	s0,16(sp)
    800049c8:	e426                	sd	s1,8(sp)
    800049ca:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800049cc:	0001d517          	auipc	a0,0x1d
    800049d0:	52c50513          	addi	a0,a0,1324 # 80021ef8 <ftable>
    800049d4:	ffffc097          	auipc	ra,0xffffc
    800049d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049dc:	0001d497          	auipc	s1,0x1d
    800049e0:	53448493          	addi	s1,s1,1332 # 80021f10 <ftable+0x18>
    800049e4:	0001e717          	auipc	a4,0x1e
    800049e8:	4cc70713          	addi	a4,a4,1228 # 80022eb0 <ftable+0xfb8>
    if(f->ref == 0){
    800049ec:	40dc                	lw	a5,4(s1)
    800049ee:	cf99                	beqz	a5,80004a0c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049f0:	02848493          	addi	s1,s1,40
    800049f4:	fee49ce3          	bne	s1,a4,800049ec <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800049f8:	0001d517          	auipc	a0,0x1d
    800049fc:	50050513          	addi	a0,a0,1280 # 80021ef8 <ftable>
    80004a00:	ffffc097          	auipc	ra,0xffffc
    80004a04:	298080e7          	jalr	664(ra) # 80000c98 <release>
  return 0;
    80004a08:	4481                	li	s1,0
    80004a0a:	a819                	j	80004a20 <filealloc+0x5e>
      f->ref = 1;
    80004a0c:	4785                	li	a5,1
    80004a0e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a10:	0001d517          	auipc	a0,0x1d
    80004a14:	4e850513          	addi	a0,a0,1256 # 80021ef8 <ftable>
    80004a18:	ffffc097          	auipc	ra,0xffffc
    80004a1c:	280080e7          	jalr	640(ra) # 80000c98 <release>
}
    80004a20:	8526                	mv	a0,s1
    80004a22:	60e2                	ld	ra,24(sp)
    80004a24:	6442                	ld	s0,16(sp)
    80004a26:	64a2                	ld	s1,8(sp)
    80004a28:	6105                	addi	sp,sp,32
    80004a2a:	8082                	ret

0000000080004a2c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a2c:	1101                	addi	sp,sp,-32
    80004a2e:	ec06                	sd	ra,24(sp)
    80004a30:	e822                	sd	s0,16(sp)
    80004a32:	e426                	sd	s1,8(sp)
    80004a34:	1000                	addi	s0,sp,32
    80004a36:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a38:	0001d517          	auipc	a0,0x1d
    80004a3c:	4c050513          	addi	a0,a0,1216 # 80021ef8 <ftable>
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	1a4080e7          	jalr	420(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a48:	40dc                	lw	a5,4(s1)
    80004a4a:	02f05263          	blez	a5,80004a6e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a4e:	2785                	addiw	a5,a5,1
    80004a50:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a52:	0001d517          	auipc	a0,0x1d
    80004a56:	4a650513          	addi	a0,a0,1190 # 80021ef8 <ftable>
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	23e080e7          	jalr	574(ra) # 80000c98 <release>
  return f;
}
    80004a62:	8526                	mv	a0,s1
    80004a64:	60e2                	ld	ra,24(sp)
    80004a66:	6442                	ld	s0,16(sp)
    80004a68:	64a2                	ld	s1,8(sp)
    80004a6a:	6105                	addi	sp,sp,32
    80004a6c:	8082                	ret
    panic("filedup");
    80004a6e:	00004517          	auipc	a0,0x4
    80004a72:	ca250513          	addi	a0,a0,-862 # 80008710 <syscalls+0x240>
    80004a76:	ffffc097          	auipc	ra,0xffffc
    80004a7a:	ac8080e7          	jalr	-1336(ra) # 8000053e <panic>

0000000080004a7e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a7e:	7139                	addi	sp,sp,-64
    80004a80:	fc06                	sd	ra,56(sp)
    80004a82:	f822                	sd	s0,48(sp)
    80004a84:	f426                	sd	s1,40(sp)
    80004a86:	f04a                	sd	s2,32(sp)
    80004a88:	ec4e                	sd	s3,24(sp)
    80004a8a:	e852                	sd	s4,16(sp)
    80004a8c:	e456                	sd	s5,8(sp)
    80004a8e:	0080                	addi	s0,sp,64
    80004a90:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a92:	0001d517          	auipc	a0,0x1d
    80004a96:	46650513          	addi	a0,a0,1126 # 80021ef8 <ftable>
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	14a080e7          	jalr	330(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004aa2:	40dc                	lw	a5,4(s1)
    80004aa4:	06f05163          	blez	a5,80004b06 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004aa8:	37fd                	addiw	a5,a5,-1
    80004aaa:	0007871b          	sext.w	a4,a5
    80004aae:	c0dc                	sw	a5,4(s1)
    80004ab0:	06e04363          	bgtz	a4,80004b16 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004ab4:	0004a903          	lw	s2,0(s1)
    80004ab8:	0094ca83          	lbu	s5,9(s1)
    80004abc:	0104ba03          	ld	s4,16(s1)
    80004ac0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004ac4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004ac8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004acc:	0001d517          	auipc	a0,0x1d
    80004ad0:	42c50513          	addi	a0,a0,1068 # 80021ef8 <ftable>
    80004ad4:	ffffc097          	auipc	ra,0xffffc
    80004ad8:	1c4080e7          	jalr	452(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004adc:	4785                	li	a5,1
    80004ade:	04f90d63          	beq	s2,a5,80004b38 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ae2:	3979                	addiw	s2,s2,-2
    80004ae4:	4785                	li	a5,1
    80004ae6:	0527e063          	bltu	a5,s2,80004b26 <fileclose+0xa8>
    begin_op();
    80004aea:	00000097          	auipc	ra,0x0
    80004aee:	ac8080e7          	jalr	-1336(ra) # 800045b2 <begin_op>
    iput(ff.ip);
    80004af2:	854e                	mv	a0,s3
    80004af4:	fffff097          	auipc	ra,0xfffff
    80004af8:	2a6080e7          	jalr	678(ra) # 80003d9a <iput>
    end_op();
    80004afc:	00000097          	auipc	ra,0x0
    80004b00:	b36080e7          	jalr	-1226(ra) # 80004632 <end_op>
    80004b04:	a00d                	j	80004b26 <fileclose+0xa8>
    panic("fileclose");
    80004b06:	00004517          	auipc	a0,0x4
    80004b0a:	c1250513          	addi	a0,a0,-1006 # 80008718 <syscalls+0x248>
    80004b0e:	ffffc097          	auipc	ra,0xffffc
    80004b12:	a30080e7          	jalr	-1488(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004b16:	0001d517          	auipc	a0,0x1d
    80004b1a:	3e250513          	addi	a0,a0,994 # 80021ef8 <ftable>
    80004b1e:	ffffc097          	auipc	ra,0xffffc
    80004b22:	17a080e7          	jalr	378(ra) # 80000c98 <release>
  }
}
    80004b26:	70e2                	ld	ra,56(sp)
    80004b28:	7442                	ld	s0,48(sp)
    80004b2a:	74a2                	ld	s1,40(sp)
    80004b2c:	7902                	ld	s2,32(sp)
    80004b2e:	69e2                	ld	s3,24(sp)
    80004b30:	6a42                	ld	s4,16(sp)
    80004b32:	6aa2                	ld	s5,8(sp)
    80004b34:	6121                	addi	sp,sp,64
    80004b36:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b38:	85d6                	mv	a1,s5
    80004b3a:	8552                	mv	a0,s4
    80004b3c:	00000097          	auipc	ra,0x0
    80004b40:	34c080e7          	jalr	844(ra) # 80004e88 <pipeclose>
    80004b44:	b7cd                	j	80004b26 <fileclose+0xa8>

0000000080004b46 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b46:	715d                	addi	sp,sp,-80
    80004b48:	e486                	sd	ra,72(sp)
    80004b4a:	e0a2                	sd	s0,64(sp)
    80004b4c:	fc26                	sd	s1,56(sp)
    80004b4e:	f84a                	sd	s2,48(sp)
    80004b50:	f44e                	sd	s3,40(sp)
    80004b52:	0880                	addi	s0,sp,80
    80004b54:	84aa                	mv	s1,a0
    80004b56:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b58:	ffffd097          	auipc	ra,0xffffd
    80004b5c:	1ac080e7          	jalr	428(ra) # 80001d04 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b60:	409c                	lw	a5,0(s1)
    80004b62:	37f9                	addiw	a5,a5,-2
    80004b64:	4705                	li	a4,1
    80004b66:	04f76763          	bltu	a4,a5,80004bb4 <filestat+0x6e>
    80004b6a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b6c:	6c88                	ld	a0,24(s1)
    80004b6e:	fffff097          	auipc	ra,0xfffff
    80004b72:	072080e7          	jalr	114(ra) # 80003be0 <ilock>
    stati(f->ip, &st);
    80004b76:	fb840593          	addi	a1,s0,-72
    80004b7a:	6c88                	ld	a0,24(s1)
    80004b7c:	fffff097          	auipc	ra,0xfffff
    80004b80:	2ee080e7          	jalr	750(ra) # 80003e6a <stati>
    iunlock(f->ip);
    80004b84:	6c88                	ld	a0,24(s1)
    80004b86:	fffff097          	auipc	ra,0xfffff
    80004b8a:	11c080e7          	jalr	284(ra) # 80003ca2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b8e:	46e1                	li	a3,24
    80004b90:	fb840613          	addi	a2,s0,-72
    80004b94:	85ce                	mv	a1,s3
    80004b96:	05093503          	ld	a0,80(s2)
    80004b9a:	ffffd097          	auipc	ra,0xffffd
    80004b9e:	ad8080e7          	jalr	-1320(ra) # 80001672 <copyout>
    80004ba2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ba6:	60a6                	ld	ra,72(sp)
    80004ba8:	6406                	ld	s0,64(sp)
    80004baa:	74e2                	ld	s1,56(sp)
    80004bac:	7942                	ld	s2,48(sp)
    80004bae:	79a2                	ld	s3,40(sp)
    80004bb0:	6161                	addi	sp,sp,80
    80004bb2:	8082                	ret
  return -1;
    80004bb4:	557d                	li	a0,-1
    80004bb6:	bfc5                	j	80004ba6 <filestat+0x60>

0000000080004bb8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004bb8:	7179                	addi	sp,sp,-48
    80004bba:	f406                	sd	ra,40(sp)
    80004bbc:	f022                	sd	s0,32(sp)
    80004bbe:	ec26                	sd	s1,24(sp)
    80004bc0:	e84a                	sd	s2,16(sp)
    80004bc2:	e44e                	sd	s3,8(sp)
    80004bc4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004bc6:	00854783          	lbu	a5,8(a0)
    80004bca:	c3d5                	beqz	a5,80004c6e <fileread+0xb6>
    80004bcc:	84aa                	mv	s1,a0
    80004bce:	89ae                	mv	s3,a1
    80004bd0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bd2:	411c                	lw	a5,0(a0)
    80004bd4:	4705                	li	a4,1
    80004bd6:	04e78963          	beq	a5,a4,80004c28 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bda:	470d                	li	a4,3
    80004bdc:	04e78d63          	beq	a5,a4,80004c36 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004be0:	4709                	li	a4,2
    80004be2:	06e79e63          	bne	a5,a4,80004c5e <fileread+0xa6>
    ilock(f->ip);
    80004be6:	6d08                	ld	a0,24(a0)
    80004be8:	fffff097          	auipc	ra,0xfffff
    80004bec:	ff8080e7          	jalr	-8(ra) # 80003be0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004bf0:	874a                	mv	a4,s2
    80004bf2:	5094                	lw	a3,32(s1)
    80004bf4:	864e                	mv	a2,s3
    80004bf6:	4585                	li	a1,1
    80004bf8:	6c88                	ld	a0,24(s1)
    80004bfa:	fffff097          	auipc	ra,0xfffff
    80004bfe:	29a080e7          	jalr	666(ra) # 80003e94 <readi>
    80004c02:	892a                	mv	s2,a0
    80004c04:	00a05563          	blez	a0,80004c0e <fileread+0x56>
      f->off += r;
    80004c08:	509c                	lw	a5,32(s1)
    80004c0a:	9fa9                	addw	a5,a5,a0
    80004c0c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c0e:	6c88                	ld	a0,24(s1)
    80004c10:	fffff097          	auipc	ra,0xfffff
    80004c14:	092080e7          	jalr	146(ra) # 80003ca2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c18:	854a                	mv	a0,s2
    80004c1a:	70a2                	ld	ra,40(sp)
    80004c1c:	7402                	ld	s0,32(sp)
    80004c1e:	64e2                	ld	s1,24(sp)
    80004c20:	6942                	ld	s2,16(sp)
    80004c22:	69a2                	ld	s3,8(sp)
    80004c24:	6145                	addi	sp,sp,48
    80004c26:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c28:	6908                	ld	a0,16(a0)
    80004c2a:	00000097          	auipc	ra,0x0
    80004c2e:	3c8080e7          	jalr	968(ra) # 80004ff2 <piperead>
    80004c32:	892a                	mv	s2,a0
    80004c34:	b7d5                	j	80004c18 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c36:	02451783          	lh	a5,36(a0)
    80004c3a:	03079693          	slli	a3,a5,0x30
    80004c3e:	92c1                	srli	a3,a3,0x30
    80004c40:	4725                	li	a4,9
    80004c42:	02d76863          	bltu	a4,a3,80004c72 <fileread+0xba>
    80004c46:	0792                	slli	a5,a5,0x4
    80004c48:	0001d717          	auipc	a4,0x1d
    80004c4c:	21070713          	addi	a4,a4,528 # 80021e58 <devsw>
    80004c50:	97ba                	add	a5,a5,a4
    80004c52:	639c                	ld	a5,0(a5)
    80004c54:	c38d                	beqz	a5,80004c76 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c56:	4505                	li	a0,1
    80004c58:	9782                	jalr	a5
    80004c5a:	892a                	mv	s2,a0
    80004c5c:	bf75                	j	80004c18 <fileread+0x60>
    panic("fileread");
    80004c5e:	00004517          	auipc	a0,0x4
    80004c62:	aca50513          	addi	a0,a0,-1334 # 80008728 <syscalls+0x258>
    80004c66:	ffffc097          	auipc	ra,0xffffc
    80004c6a:	8d8080e7          	jalr	-1832(ra) # 8000053e <panic>
    return -1;
    80004c6e:	597d                	li	s2,-1
    80004c70:	b765                	j	80004c18 <fileread+0x60>
      return -1;
    80004c72:	597d                	li	s2,-1
    80004c74:	b755                	j	80004c18 <fileread+0x60>
    80004c76:	597d                	li	s2,-1
    80004c78:	b745                	j	80004c18 <fileread+0x60>

0000000080004c7a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c7a:	715d                	addi	sp,sp,-80
    80004c7c:	e486                	sd	ra,72(sp)
    80004c7e:	e0a2                	sd	s0,64(sp)
    80004c80:	fc26                	sd	s1,56(sp)
    80004c82:	f84a                	sd	s2,48(sp)
    80004c84:	f44e                	sd	s3,40(sp)
    80004c86:	f052                	sd	s4,32(sp)
    80004c88:	ec56                	sd	s5,24(sp)
    80004c8a:	e85a                	sd	s6,16(sp)
    80004c8c:	e45e                	sd	s7,8(sp)
    80004c8e:	e062                	sd	s8,0(sp)
    80004c90:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c92:	00954783          	lbu	a5,9(a0)
    80004c96:	10078663          	beqz	a5,80004da2 <filewrite+0x128>
    80004c9a:	892a                	mv	s2,a0
    80004c9c:	8aae                	mv	s5,a1
    80004c9e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ca0:	411c                	lw	a5,0(a0)
    80004ca2:	4705                	li	a4,1
    80004ca4:	02e78263          	beq	a5,a4,80004cc8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ca8:	470d                	li	a4,3
    80004caa:	02e78663          	beq	a5,a4,80004cd6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cae:	4709                	li	a4,2
    80004cb0:	0ee79163          	bne	a5,a4,80004d92 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004cb4:	0ac05d63          	blez	a2,80004d6e <filewrite+0xf4>
    int i = 0;
    80004cb8:	4981                	li	s3,0
    80004cba:	6b05                	lui	s6,0x1
    80004cbc:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004cc0:	6b85                	lui	s7,0x1
    80004cc2:	c00b8b9b          	addiw	s7,s7,-1024
    80004cc6:	a861                	j	80004d5e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004cc8:	6908                	ld	a0,16(a0)
    80004cca:	00000097          	auipc	ra,0x0
    80004cce:	22e080e7          	jalr	558(ra) # 80004ef8 <pipewrite>
    80004cd2:	8a2a                	mv	s4,a0
    80004cd4:	a045                	j	80004d74 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004cd6:	02451783          	lh	a5,36(a0)
    80004cda:	03079693          	slli	a3,a5,0x30
    80004cde:	92c1                	srli	a3,a3,0x30
    80004ce0:	4725                	li	a4,9
    80004ce2:	0cd76263          	bltu	a4,a3,80004da6 <filewrite+0x12c>
    80004ce6:	0792                	slli	a5,a5,0x4
    80004ce8:	0001d717          	auipc	a4,0x1d
    80004cec:	17070713          	addi	a4,a4,368 # 80021e58 <devsw>
    80004cf0:	97ba                	add	a5,a5,a4
    80004cf2:	679c                	ld	a5,8(a5)
    80004cf4:	cbdd                	beqz	a5,80004daa <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004cf6:	4505                	li	a0,1
    80004cf8:	9782                	jalr	a5
    80004cfa:	8a2a                	mv	s4,a0
    80004cfc:	a8a5                	j	80004d74 <filewrite+0xfa>
    80004cfe:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d02:	00000097          	auipc	ra,0x0
    80004d06:	8b0080e7          	jalr	-1872(ra) # 800045b2 <begin_op>
      ilock(f->ip);
    80004d0a:	01893503          	ld	a0,24(s2)
    80004d0e:	fffff097          	auipc	ra,0xfffff
    80004d12:	ed2080e7          	jalr	-302(ra) # 80003be0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d16:	8762                	mv	a4,s8
    80004d18:	02092683          	lw	a3,32(s2)
    80004d1c:	01598633          	add	a2,s3,s5
    80004d20:	4585                	li	a1,1
    80004d22:	01893503          	ld	a0,24(s2)
    80004d26:	fffff097          	auipc	ra,0xfffff
    80004d2a:	266080e7          	jalr	614(ra) # 80003f8c <writei>
    80004d2e:	84aa                	mv	s1,a0
    80004d30:	00a05763          	blez	a0,80004d3e <filewrite+0xc4>
        f->off += r;
    80004d34:	02092783          	lw	a5,32(s2)
    80004d38:	9fa9                	addw	a5,a5,a0
    80004d3a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d3e:	01893503          	ld	a0,24(s2)
    80004d42:	fffff097          	auipc	ra,0xfffff
    80004d46:	f60080e7          	jalr	-160(ra) # 80003ca2 <iunlock>
      end_op();
    80004d4a:	00000097          	auipc	ra,0x0
    80004d4e:	8e8080e7          	jalr	-1816(ra) # 80004632 <end_op>

      if(r != n1){
    80004d52:	009c1f63          	bne	s8,s1,80004d70 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d56:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d5a:	0149db63          	bge	s3,s4,80004d70 <filewrite+0xf6>
      int n1 = n - i;
    80004d5e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d62:	84be                	mv	s1,a5
    80004d64:	2781                	sext.w	a5,a5
    80004d66:	f8fb5ce3          	bge	s6,a5,80004cfe <filewrite+0x84>
    80004d6a:	84de                	mv	s1,s7
    80004d6c:	bf49                	j	80004cfe <filewrite+0x84>
    int i = 0;
    80004d6e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d70:	013a1f63          	bne	s4,s3,80004d8e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d74:	8552                	mv	a0,s4
    80004d76:	60a6                	ld	ra,72(sp)
    80004d78:	6406                	ld	s0,64(sp)
    80004d7a:	74e2                	ld	s1,56(sp)
    80004d7c:	7942                	ld	s2,48(sp)
    80004d7e:	79a2                	ld	s3,40(sp)
    80004d80:	7a02                	ld	s4,32(sp)
    80004d82:	6ae2                	ld	s5,24(sp)
    80004d84:	6b42                	ld	s6,16(sp)
    80004d86:	6ba2                	ld	s7,8(sp)
    80004d88:	6c02                	ld	s8,0(sp)
    80004d8a:	6161                	addi	sp,sp,80
    80004d8c:	8082                	ret
    ret = (i == n ? n : -1);
    80004d8e:	5a7d                	li	s4,-1
    80004d90:	b7d5                	j	80004d74 <filewrite+0xfa>
    panic("filewrite");
    80004d92:	00004517          	auipc	a0,0x4
    80004d96:	9a650513          	addi	a0,a0,-1626 # 80008738 <syscalls+0x268>
    80004d9a:	ffffb097          	auipc	ra,0xffffb
    80004d9e:	7a4080e7          	jalr	1956(ra) # 8000053e <panic>
    return -1;
    80004da2:	5a7d                	li	s4,-1
    80004da4:	bfc1                	j	80004d74 <filewrite+0xfa>
      return -1;
    80004da6:	5a7d                	li	s4,-1
    80004da8:	b7f1                	j	80004d74 <filewrite+0xfa>
    80004daa:	5a7d                	li	s4,-1
    80004dac:	b7e1                	j	80004d74 <filewrite+0xfa>

0000000080004dae <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004dae:	7179                	addi	sp,sp,-48
    80004db0:	f406                	sd	ra,40(sp)
    80004db2:	f022                	sd	s0,32(sp)
    80004db4:	ec26                	sd	s1,24(sp)
    80004db6:	e84a                	sd	s2,16(sp)
    80004db8:	e44e                	sd	s3,8(sp)
    80004dba:	e052                	sd	s4,0(sp)
    80004dbc:	1800                	addi	s0,sp,48
    80004dbe:	84aa                	mv	s1,a0
    80004dc0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004dc2:	0005b023          	sd	zero,0(a1)
    80004dc6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004dca:	00000097          	auipc	ra,0x0
    80004dce:	bf8080e7          	jalr	-1032(ra) # 800049c2 <filealloc>
    80004dd2:	e088                	sd	a0,0(s1)
    80004dd4:	c551                	beqz	a0,80004e60 <pipealloc+0xb2>
    80004dd6:	00000097          	auipc	ra,0x0
    80004dda:	bec080e7          	jalr	-1044(ra) # 800049c2 <filealloc>
    80004dde:	00aa3023          	sd	a0,0(s4)
    80004de2:	c92d                	beqz	a0,80004e54 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004de4:	ffffc097          	auipc	ra,0xffffc
    80004de8:	d10080e7          	jalr	-752(ra) # 80000af4 <kalloc>
    80004dec:	892a                	mv	s2,a0
    80004dee:	c125                	beqz	a0,80004e4e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004df0:	4985                	li	s3,1
    80004df2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004df6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004dfa:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004dfe:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e02:	00004597          	auipc	a1,0x4
    80004e06:	94658593          	addi	a1,a1,-1722 # 80008748 <syscalls+0x278>
    80004e0a:	ffffc097          	auipc	ra,0xffffc
    80004e0e:	d4a080e7          	jalr	-694(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004e12:	609c                	ld	a5,0(s1)
    80004e14:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e18:	609c                	ld	a5,0(s1)
    80004e1a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e1e:	609c                	ld	a5,0(s1)
    80004e20:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e24:	609c                	ld	a5,0(s1)
    80004e26:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e2a:	000a3783          	ld	a5,0(s4)
    80004e2e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e32:	000a3783          	ld	a5,0(s4)
    80004e36:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e3a:	000a3783          	ld	a5,0(s4)
    80004e3e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e42:	000a3783          	ld	a5,0(s4)
    80004e46:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e4a:	4501                	li	a0,0
    80004e4c:	a025                	j	80004e74 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e4e:	6088                	ld	a0,0(s1)
    80004e50:	e501                	bnez	a0,80004e58 <pipealloc+0xaa>
    80004e52:	a039                	j	80004e60 <pipealloc+0xb2>
    80004e54:	6088                	ld	a0,0(s1)
    80004e56:	c51d                	beqz	a0,80004e84 <pipealloc+0xd6>
    fileclose(*f0);
    80004e58:	00000097          	auipc	ra,0x0
    80004e5c:	c26080e7          	jalr	-986(ra) # 80004a7e <fileclose>
  if(*f1)
    80004e60:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e64:	557d                	li	a0,-1
  if(*f1)
    80004e66:	c799                	beqz	a5,80004e74 <pipealloc+0xc6>
    fileclose(*f1);
    80004e68:	853e                	mv	a0,a5
    80004e6a:	00000097          	auipc	ra,0x0
    80004e6e:	c14080e7          	jalr	-1004(ra) # 80004a7e <fileclose>
  return -1;
    80004e72:	557d                	li	a0,-1
}
    80004e74:	70a2                	ld	ra,40(sp)
    80004e76:	7402                	ld	s0,32(sp)
    80004e78:	64e2                	ld	s1,24(sp)
    80004e7a:	6942                	ld	s2,16(sp)
    80004e7c:	69a2                	ld	s3,8(sp)
    80004e7e:	6a02                	ld	s4,0(sp)
    80004e80:	6145                	addi	sp,sp,48
    80004e82:	8082                	ret
  return -1;
    80004e84:	557d                	li	a0,-1
    80004e86:	b7fd                	j	80004e74 <pipealloc+0xc6>

0000000080004e88 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e88:	1101                	addi	sp,sp,-32
    80004e8a:	ec06                	sd	ra,24(sp)
    80004e8c:	e822                	sd	s0,16(sp)
    80004e8e:	e426                	sd	s1,8(sp)
    80004e90:	e04a                	sd	s2,0(sp)
    80004e92:	1000                	addi	s0,sp,32
    80004e94:	84aa                	mv	s1,a0
    80004e96:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e98:	ffffc097          	auipc	ra,0xffffc
    80004e9c:	d4c080e7          	jalr	-692(ra) # 80000be4 <acquire>
  if(writable){
    80004ea0:	02090d63          	beqz	s2,80004eda <pipeclose+0x52>
    pi->writeopen = 0;
    80004ea4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ea8:	21848513          	addi	a0,s1,536
    80004eac:	ffffd097          	auipc	ra,0xffffd
    80004eb0:	7f4080e7          	jalr	2036(ra) # 800026a0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004eb4:	2204b783          	ld	a5,544(s1)
    80004eb8:	eb95                	bnez	a5,80004eec <pipeclose+0x64>
    release(&pi->lock);
    80004eba:	8526                	mv	a0,s1
    80004ebc:	ffffc097          	auipc	ra,0xffffc
    80004ec0:	ddc080e7          	jalr	-548(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004ec4:	8526                	mv	a0,s1
    80004ec6:	ffffc097          	auipc	ra,0xffffc
    80004eca:	b32080e7          	jalr	-1230(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004ece:	60e2                	ld	ra,24(sp)
    80004ed0:	6442                	ld	s0,16(sp)
    80004ed2:	64a2                	ld	s1,8(sp)
    80004ed4:	6902                	ld	s2,0(sp)
    80004ed6:	6105                	addi	sp,sp,32
    80004ed8:	8082                	ret
    pi->readopen = 0;
    80004eda:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ede:	21c48513          	addi	a0,s1,540
    80004ee2:	ffffd097          	auipc	ra,0xffffd
    80004ee6:	7be080e7          	jalr	1982(ra) # 800026a0 <wakeup>
    80004eea:	b7e9                	j	80004eb4 <pipeclose+0x2c>
    release(&pi->lock);
    80004eec:	8526                	mv	a0,s1
    80004eee:	ffffc097          	auipc	ra,0xffffc
    80004ef2:	daa080e7          	jalr	-598(ra) # 80000c98 <release>
}
    80004ef6:	bfe1                	j	80004ece <pipeclose+0x46>

0000000080004ef8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ef8:	7159                	addi	sp,sp,-112
    80004efa:	f486                	sd	ra,104(sp)
    80004efc:	f0a2                	sd	s0,96(sp)
    80004efe:	eca6                	sd	s1,88(sp)
    80004f00:	e8ca                	sd	s2,80(sp)
    80004f02:	e4ce                	sd	s3,72(sp)
    80004f04:	e0d2                	sd	s4,64(sp)
    80004f06:	fc56                	sd	s5,56(sp)
    80004f08:	f85a                	sd	s6,48(sp)
    80004f0a:	f45e                	sd	s7,40(sp)
    80004f0c:	f062                	sd	s8,32(sp)
    80004f0e:	ec66                	sd	s9,24(sp)
    80004f10:	1880                	addi	s0,sp,112
    80004f12:	84aa                	mv	s1,a0
    80004f14:	8aae                	mv	s5,a1
    80004f16:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f18:	ffffd097          	auipc	ra,0xffffd
    80004f1c:	dec080e7          	jalr	-532(ra) # 80001d04 <myproc>
    80004f20:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f22:	8526                	mv	a0,s1
    80004f24:	ffffc097          	auipc	ra,0xffffc
    80004f28:	cc0080e7          	jalr	-832(ra) # 80000be4 <acquire>
  while(i < n){
    80004f2c:	0d405163          	blez	s4,80004fee <pipewrite+0xf6>
    80004f30:	8ba6                	mv	s7,s1
  int i = 0;
    80004f32:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f34:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f36:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f3a:	21c48c13          	addi	s8,s1,540
    80004f3e:	a08d                	j	80004fa0 <pipewrite+0xa8>
      release(&pi->lock);
    80004f40:	8526                	mv	a0,s1
    80004f42:	ffffc097          	auipc	ra,0xffffc
    80004f46:	d56080e7          	jalr	-682(ra) # 80000c98 <release>
      return -1;
    80004f4a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f4c:	854a                	mv	a0,s2
    80004f4e:	70a6                	ld	ra,104(sp)
    80004f50:	7406                	ld	s0,96(sp)
    80004f52:	64e6                	ld	s1,88(sp)
    80004f54:	6946                	ld	s2,80(sp)
    80004f56:	69a6                	ld	s3,72(sp)
    80004f58:	6a06                	ld	s4,64(sp)
    80004f5a:	7ae2                	ld	s5,56(sp)
    80004f5c:	7b42                	ld	s6,48(sp)
    80004f5e:	7ba2                	ld	s7,40(sp)
    80004f60:	7c02                	ld	s8,32(sp)
    80004f62:	6ce2                	ld	s9,24(sp)
    80004f64:	6165                	addi	sp,sp,112
    80004f66:	8082                	ret
      wakeup(&pi->nread);
    80004f68:	8566                	mv	a0,s9
    80004f6a:	ffffd097          	auipc	ra,0xffffd
    80004f6e:	736080e7          	jalr	1846(ra) # 800026a0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f72:	85de                	mv	a1,s7
    80004f74:	8562                	mv	a0,s8
    80004f76:	ffffd097          	auipc	ra,0xffffd
    80004f7a:	58c080e7          	jalr	1420(ra) # 80002502 <sleep>
    80004f7e:	a839                	j	80004f9c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f80:	21c4a783          	lw	a5,540(s1)
    80004f84:	0017871b          	addiw	a4,a5,1
    80004f88:	20e4ae23          	sw	a4,540(s1)
    80004f8c:	1ff7f793          	andi	a5,a5,511
    80004f90:	97a6                	add	a5,a5,s1
    80004f92:	f9f44703          	lbu	a4,-97(s0)
    80004f96:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f9a:	2905                	addiw	s2,s2,1
  while(i < n){
    80004f9c:	03495d63          	bge	s2,s4,80004fd6 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004fa0:	2204a783          	lw	a5,544(s1)
    80004fa4:	dfd1                	beqz	a5,80004f40 <pipewrite+0x48>
    80004fa6:	0289a783          	lw	a5,40(s3)
    80004faa:	fbd9                	bnez	a5,80004f40 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004fac:	2184a783          	lw	a5,536(s1)
    80004fb0:	21c4a703          	lw	a4,540(s1)
    80004fb4:	2007879b          	addiw	a5,a5,512
    80004fb8:	faf708e3          	beq	a4,a5,80004f68 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fbc:	4685                	li	a3,1
    80004fbe:	01590633          	add	a2,s2,s5
    80004fc2:	f9f40593          	addi	a1,s0,-97
    80004fc6:	0509b503          	ld	a0,80(s3)
    80004fca:	ffffc097          	auipc	ra,0xffffc
    80004fce:	734080e7          	jalr	1844(ra) # 800016fe <copyin>
    80004fd2:	fb6517e3          	bne	a0,s6,80004f80 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004fd6:	21848513          	addi	a0,s1,536
    80004fda:	ffffd097          	auipc	ra,0xffffd
    80004fde:	6c6080e7          	jalr	1734(ra) # 800026a0 <wakeup>
  release(&pi->lock);
    80004fe2:	8526                	mv	a0,s1
    80004fe4:	ffffc097          	auipc	ra,0xffffc
    80004fe8:	cb4080e7          	jalr	-844(ra) # 80000c98 <release>
  return i;
    80004fec:	b785                	j	80004f4c <pipewrite+0x54>
  int i = 0;
    80004fee:	4901                	li	s2,0
    80004ff0:	b7dd                	j	80004fd6 <pipewrite+0xde>

0000000080004ff2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ff2:	715d                	addi	sp,sp,-80
    80004ff4:	e486                	sd	ra,72(sp)
    80004ff6:	e0a2                	sd	s0,64(sp)
    80004ff8:	fc26                	sd	s1,56(sp)
    80004ffa:	f84a                	sd	s2,48(sp)
    80004ffc:	f44e                	sd	s3,40(sp)
    80004ffe:	f052                	sd	s4,32(sp)
    80005000:	ec56                	sd	s5,24(sp)
    80005002:	e85a                	sd	s6,16(sp)
    80005004:	0880                	addi	s0,sp,80
    80005006:	84aa                	mv	s1,a0
    80005008:	892e                	mv	s2,a1
    8000500a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000500c:	ffffd097          	auipc	ra,0xffffd
    80005010:	cf8080e7          	jalr	-776(ra) # 80001d04 <myproc>
    80005014:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005016:	8b26                	mv	s6,s1
    80005018:	8526                	mv	a0,s1
    8000501a:	ffffc097          	auipc	ra,0xffffc
    8000501e:	bca080e7          	jalr	-1078(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005022:	2184a703          	lw	a4,536(s1)
    80005026:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000502a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000502e:	02f71463          	bne	a4,a5,80005056 <piperead+0x64>
    80005032:	2244a783          	lw	a5,548(s1)
    80005036:	c385                	beqz	a5,80005056 <piperead+0x64>
    if(pr->killed){
    80005038:	028a2783          	lw	a5,40(s4)
    8000503c:	ebc1                	bnez	a5,800050cc <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000503e:	85da                	mv	a1,s6
    80005040:	854e                	mv	a0,s3
    80005042:	ffffd097          	auipc	ra,0xffffd
    80005046:	4c0080e7          	jalr	1216(ra) # 80002502 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000504a:	2184a703          	lw	a4,536(s1)
    8000504e:	21c4a783          	lw	a5,540(s1)
    80005052:	fef700e3          	beq	a4,a5,80005032 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005056:	09505263          	blez	s5,800050da <piperead+0xe8>
    8000505a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000505c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000505e:	2184a783          	lw	a5,536(s1)
    80005062:	21c4a703          	lw	a4,540(s1)
    80005066:	02f70d63          	beq	a4,a5,800050a0 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000506a:	0017871b          	addiw	a4,a5,1
    8000506e:	20e4ac23          	sw	a4,536(s1)
    80005072:	1ff7f793          	andi	a5,a5,511
    80005076:	97a6                	add	a5,a5,s1
    80005078:	0187c783          	lbu	a5,24(a5)
    8000507c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005080:	4685                	li	a3,1
    80005082:	fbf40613          	addi	a2,s0,-65
    80005086:	85ca                	mv	a1,s2
    80005088:	050a3503          	ld	a0,80(s4)
    8000508c:	ffffc097          	auipc	ra,0xffffc
    80005090:	5e6080e7          	jalr	1510(ra) # 80001672 <copyout>
    80005094:	01650663          	beq	a0,s6,800050a0 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005098:	2985                	addiw	s3,s3,1
    8000509a:	0905                	addi	s2,s2,1
    8000509c:	fd3a91e3          	bne	s5,s3,8000505e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050a0:	21c48513          	addi	a0,s1,540
    800050a4:	ffffd097          	auipc	ra,0xffffd
    800050a8:	5fc080e7          	jalr	1532(ra) # 800026a0 <wakeup>
  release(&pi->lock);
    800050ac:	8526                	mv	a0,s1
    800050ae:	ffffc097          	auipc	ra,0xffffc
    800050b2:	bea080e7          	jalr	-1046(ra) # 80000c98 <release>
  return i;
}
    800050b6:	854e                	mv	a0,s3
    800050b8:	60a6                	ld	ra,72(sp)
    800050ba:	6406                	ld	s0,64(sp)
    800050bc:	74e2                	ld	s1,56(sp)
    800050be:	7942                	ld	s2,48(sp)
    800050c0:	79a2                	ld	s3,40(sp)
    800050c2:	7a02                	ld	s4,32(sp)
    800050c4:	6ae2                	ld	s5,24(sp)
    800050c6:	6b42                	ld	s6,16(sp)
    800050c8:	6161                	addi	sp,sp,80
    800050ca:	8082                	ret
      release(&pi->lock);
    800050cc:	8526                	mv	a0,s1
    800050ce:	ffffc097          	auipc	ra,0xffffc
    800050d2:	bca080e7          	jalr	-1078(ra) # 80000c98 <release>
      return -1;
    800050d6:	59fd                	li	s3,-1
    800050d8:	bff9                	j	800050b6 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050da:	4981                	li	s3,0
    800050dc:	b7d1                	j	800050a0 <piperead+0xae>

00000000800050de <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800050de:	df010113          	addi	sp,sp,-528
    800050e2:	20113423          	sd	ra,520(sp)
    800050e6:	20813023          	sd	s0,512(sp)
    800050ea:	ffa6                	sd	s1,504(sp)
    800050ec:	fbca                	sd	s2,496(sp)
    800050ee:	f7ce                	sd	s3,488(sp)
    800050f0:	f3d2                	sd	s4,480(sp)
    800050f2:	efd6                	sd	s5,472(sp)
    800050f4:	ebda                	sd	s6,464(sp)
    800050f6:	e7de                	sd	s7,456(sp)
    800050f8:	e3e2                	sd	s8,448(sp)
    800050fa:	ff66                	sd	s9,440(sp)
    800050fc:	fb6a                	sd	s10,432(sp)
    800050fe:	f76e                	sd	s11,424(sp)
    80005100:	0c00                	addi	s0,sp,528
    80005102:	84aa                	mv	s1,a0
    80005104:	dea43c23          	sd	a0,-520(s0)
    80005108:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000510c:	ffffd097          	auipc	ra,0xffffd
    80005110:	bf8080e7          	jalr	-1032(ra) # 80001d04 <myproc>
    80005114:	892a                	mv	s2,a0

  begin_op();
    80005116:	fffff097          	auipc	ra,0xfffff
    8000511a:	49c080e7          	jalr	1180(ra) # 800045b2 <begin_op>

  if((ip = namei(path)) == 0){
    8000511e:	8526                	mv	a0,s1
    80005120:	fffff097          	auipc	ra,0xfffff
    80005124:	276080e7          	jalr	630(ra) # 80004396 <namei>
    80005128:	c92d                	beqz	a0,8000519a <exec+0xbc>
    8000512a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000512c:	fffff097          	auipc	ra,0xfffff
    80005130:	ab4080e7          	jalr	-1356(ra) # 80003be0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005134:	04000713          	li	a4,64
    80005138:	4681                	li	a3,0
    8000513a:	e5040613          	addi	a2,s0,-432
    8000513e:	4581                	li	a1,0
    80005140:	8526                	mv	a0,s1
    80005142:	fffff097          	auipc	ra,0xfffff
    80005146:	d52080e7          	jalr	-686(ra) # 80003e94 <readi>
    8000514a:	04000793          	li	a5,64
    8000514e:	00f51a63          	bne	a0,a5,80005162 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005152:	e5042703          	lw	a4,-432(s0)
    80005156:	464c47b7          	lui	a5,0x464c4
    8000515a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000515e:	04f70463          	beq	a4,a5,800051a6 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005162:	8526                	mv	a0,s1
    80005164:	fffff097          	auipc	ra,0xfffff
    80005168:	cde080e7          	jalr	-802(ra) # 80003e42 <iunlockput>
    end_op();
    8000516c:	fffff097          	auipc	ra,0xfffff
    80005170:	4c6080e7          	jalr	1222(ra) # 80004632 <end_op>
  }
  return -1;
    80005174:	557d                	li	a0,-1
}
    80005176:	20813083          	ld	ra,520(sp)
    8000517a:	20013403          	ld	s0,512(sp)
    8000517e:	74fe                	ld	s1,504(sp)
    80005180:	795e                	ld	s2,496(sp)
    80005182:	79be                	ld	s3,488(sp)
    80005184:	7a1e                	ld	s4,480(sp)
    80005186:	6afe                	ld	s5,472(sp)
    80005188:	6b5e                	ld	s6,464(sp)
    8000518a:	6bbe                	ld	s7,456(sp)
    8000518c:	6c1e                	ld	s8,448(sp)
    8000518e:	7cfa                	ld	s9,440(sp)
    80005190:	7d5a                	ld	s10,432(sp)
    80005192:	7dba                	ld	s11,424(sp)
    80005194:	21010113          	addi	sp,sp,528
    80005198:	8082                	ret
    end_op();
    8000519a:	fffff097          	auipc	ra,0xfffff
    8000519e:	498080e7          	jalr	1176(ra) # 80004632 <end_op>
    return -1;
    800051a2:	557d                	li	a0,-1
    800051a4:	bfc9                	j	80005176 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800051a6:	854a                	mv	a0,s2
    800051a8:	ffffd097          	auipc	ra,0xffffd
    800051ac:	c1a080e7          	jalr	-998(ra) # 80001dc2 <proc_pagetable>
    800051b0:	8baa                	mv	s7,a0
    800051b2:	d945                	beqz	a0,80005162 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051b4:	e7042983          	lw	s3,-400(s0)
    800051b8:	e8845783          	lhu	a5,-376(s0)
    800051bc:	c7ad                	beqz	a5,80005226 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051be:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051c0:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800051c2:	6c85                	lui	s9,0x1
    800051c4:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800051c8:	def43823          	sd	a5,-528(s0)
    800051cc:	a42d                	j	800053f6 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800051ce:	00003517          	auipc	a0,0x3
    800051d2:	58250513          	addi	a0,a0,1410 # 80008750 <syscalls+0x280>
    800051d6:	ffffb097          	auipc	ra,0xffffb
    800051da:	368080e7          	jalr	872(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800051de:	8756                	mv	a4,s5
    800051e0:	012d86bb          	addw	a3,s11,s2
    800051e4:	4581                	li	a1,0
    800051e6:	8526                	mv	a0,s1
    800051e8:	fffff097          	auipc	ra,0xfffff
    800051ec:	cac080e7          	jalr	-852(ra) # 80003e94 <readi>
    800051f0:	2501                	sext.w	a0,a0
    800051f2:	1aaa9963          	bne	s5,a0,800053a4 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800051f6:	6785                	lui	a5,0x1
    800051f8:	0127893b          	addw	s2,a5,s2
    800051fc:	77fd                	lui	a5,0xfffff
    800051fe:	01478a3b          	addw	s4,a5,s4
    80005202:	1f897163          	bgeu	s2,s8,800053e4 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005206:	02091593          	slli	a1,s2,0x20
    8000520a:	9181                	srli	a1,a1,0x20
    8000520c:	95ea                	add	a1,a1,s10
    8000520e:	855e                	mv	a0,s7
    80005210:	ffffc097          	auipc	ra,0xffffc
    80005214:	e5e080e7          	jalr	-418(ra) # 8000106e <walkaddr>
    80005218:	862a                	mv	a2,a0
    if(pa == 0)
    8000521a:	d955                	beqz	a0,800051ce <exec+0xf0>
      n = PGSIZE;
    8000521c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000521e:	fd9a70e3          	bgeu	s4,s9,800051de <exec+0x100>
      n = sz - i;
    80005222:	8ad2                	mv	s5,s4
    80005224:	bf6d                	j	800051de <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005226:	4901                	li	s2,0
  iunlockput(ip);
    80005228:	8526                	mv	a0,s1
    8000522a:	fffff097          	auipc	ra,0xfffff
    8000522e:	c18080e7          	jalr	-1000(ra) # 80003e42 <iunlockput>
  end_op();
    80005232:	fffff097          	auipc	ra,0xfffff
    80005236:	400080e7          	jalr	1024(ra) # 80004632 <end_op>
  p = myproc();
    8000523a:	ffffd097          	auipc	ra,0xffffd
    8000523e:	aca080e7          	jalr	-1334(ra) # 80001d04 <myproc>
    80005242:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005244:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005248:	6785                	lui	a5,0x1
    8000524a:	17fd                	addi	a5,a5,-1
    8000524c:	993e                	add	s2,s2,a5
    8000524e:	757d                	lui	a0,0xfffff
    80005250:	00a977b3          	and	a5,s2,a0
    80005254:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005258:	6609                	lui	a2,0x2
    8000525a:	963e                	add	a2,a2,a5
    8000525c:	85be                	mv	a1,a5
    8000525e:	855e                	mv	a0,s7
    80005260:	ffffc097          	auipc	ra,0xffffc
    80005264:	1c2080e7          	jalr	450(ra) # 80001422 <uvmalloc>
    80005268:	8b2a                	mv	s6,a0
  ip = 0;
    8000526a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000526c:	12050c63          	beqz	a0,800053a4 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005270:	75f9                	lui	a1,0xffffe
    80005272:	95aa                	add	a1,a1,a0
    80005274:	855e                	mv	a0,s7
    80005276:	ffffc097          	auipc	ra,0xffffc
    8000527a:	3ca080e7          	jalr	970(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    8000527e:	7c7d                	lui	s8,0xfffff
    80005280:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005282:	e0043783          	ld	a5,-512(s0)
    80005286:	6388                	ld	a0,0(a5)
    80005288:	c535                	beqz	a0,800052f4 <exec+0x216>
    8000528a:	e9040993          	addi	s3,s0,-368
    8000528e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005292:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005294:	ffffc097          	auipc	ra,0xffffc
    80005298:	bd0080e7          	jalr	-1072(ra) # 80000e64 <strlen>
    8000529c:	2505                	addiw	a0,a0,1
    8000529e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800052a2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800052a6:	13896363          	bltu	s2,s8,800053cc <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800052aa:	e0043d83          	ld	s11,-512(s0)
    800052ae:	000dba03          	ld	s4,0(s11)
    800052b2:	8552                	mv	a0,s4
    800052b4:	ffffc097          	auipc	ra,0xffffc
    800052b8:	bb0080e7          	jalr	-1104(ra) # 80000e64 <strlen>
    800052bc:	0015069b          	addiw	a3,a0,1
    800052c0:	8652                	mv	a2,s4
    800052c2:	85ca                	mv	a1,s2
    800052c4:	855e                	mv	a0,s7
    800052c6:	ffffc097          	auipc	ra,0xffffc
    800052ca:	3ac080e7          	jalr	940(ra) # 80001672 <copyout>
    800052ce:	10054363          	bltz	a0,800053d4 <exec+0x2f6>
    ustack[argc] = sp;
    800052d2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800052d6:	0485                	addi	s1,s1,1
    800052d8:	008d8793          	addi	a5,s11,8
    800052dc:	e0f43023          	sd	a5,-512(s0)
    800052e0:	008db503          	ld	a0,8(s11)
    800052e4:	c911                	beqz	a0,800052f8 <exec+0x21a>
    if(argc >= MAXARG)
    800052e6:	09a1                	addi	s3,s3,8
    800052e8:	fb3c96e3          	bne	s9,s3,80005294 <exec+0x1b6>
  sz = sz1;
    800052ec:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052f0:	4481                	li	s1,0
    800052f2:	a84d                	j	800053a4 <exec+0x2c6>
  sp = sz;
    800052f4:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800052f6:	4481                	li	s1,0
  ustack[argc] = 0;
    800052f8:	00349793          	slli	a5,s1,0x3
    800052fc:	f9040713          	addi	a4,s0,-112
    80005300:	97ba                	add	a5,a5,a4
    80005302:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005306:	00148693          	addi	a3,s1,1
    8000530a:	068e                	slli	a3,a3,0x3
    8000530c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005310:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005314:	01897663          	bgeu	s2,s8,80005320 <exec+0x242>
  sz = sz1;
    80005318:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000531c:	4481                	li	s1,0
    8000531e:	a059                	j	800053a4 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005320:	e9040613          	addi	a2,s0,-368
    80005324:	85ca                	mv	a1,s2
    80005326:	855e                	mv	a0,s7
    80005328:	ffffc097          	auipc	ra,0xffffc
    8000532c:	34a080e7          	jalr	842(ra) # 80001672 <copyout>
    80005330:	0a054663          	bltz	a0,800053dc <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005334:	058ab783          	ld	a5,88(s5)
    80005338:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000533c:	df843783          	ld	a5,-520(s0)
    80005340:	0007c703          	lbu	a4,0(a5)
    80005344:	cf11                	beqz	a4,80005360 <exec+0x282>
    80005346:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005348:	02f00693          	li	a3,47
    8000534c:	a039                	j	8000535a <exec+0x27c>
      last = s+1;
    8000534e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005352:	0785                	addi	a5,a5,1
    80005354:	fff7c703          	lbu	a4,-1(a5)
    80005358:	c701                	beqz	a4,80005360 <exec+0x282>
    if(*s == '/')
    8000535a:	fed71ce3          	bne	a4,a3,80005352 <exec+0x274>
    8000535e:	bfc5                	j	8000534e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005360:	4641                	li	a2,16
    80005362:	df843583          	ld	a1,-520(s0)
    80005366:	158a8513          	addi	a0,s5,344
    8000536a:	ffffc097          	auipc	ra,0xffffc
    8000536e:	ac8080e7          	jalr	-1336(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005372:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005376:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000537a:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000537e:	058ab783          	ld	a5,88(s5)
    80005382:	e6843703          	ld	a4,-408(s0)
    80005386:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005388:	058ab783          	ld	a5,88(s5)
    8000538c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005390:	85ea                	mv	a1,s10
    80005392:	ffffd097          	auipc	ra,0xffffd
    80005396:	acc080e7          	jalr	-1332(ra) # 80001e5e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000539a:	0004851b          	sext.w	a0,s1
    8000539e:	bbe1                	j	80005176 <exec+0x98>
    800053a0:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800053a4:	e0843583          	ld	a1,-504(s0)
    800053a8:	855e                	mv	a0,s7
    800053aa:	ffffd097          	auipc	ra,0xffffd
    800053ae:	ab4080e7          	jalr	-1356(ra) # 80001e5e <proc_freepagetable>
  if(ip){
    800053b2:	da0498e3          	bnez	s1,80005162 <exec+0x84>
  return -1;
    800053b6:	557d                	li	a0,-1
    800053b8:	bb7d                	j	80005176 <exec+0x98>
    800053ba:	e1243423          	sd	s2,-504(s0)
    800053be:	b7dd                	j	800053a4 <exec+0x2c6>
    800053c0:	e1243423          	sd	s2,-504(s0)
    800053c4:	b7c5                	j	800053a4 <exec+0x2c6>
    800053c6:	e1243423          	sd	s2,-504(s0)
    800053ca:	bfe9                	j	800053a4 <exec+0x2c6>
  sz = sz1;
    800053cc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053d0:	4481                	li	s1,0
    800053d2:	bfc9                	j	800053a4 <exec+0x2c6>
  sz = sz1;
    800053d4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053d8:	4481                	li	s1,0
    800053da:	b7e9                	j	800053a4 <exec+0x2c6>
  sz = sz1;
    800053dc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053e0:	4481                	li	s1,0
    800053e2:	b7c9                	j	800053a4 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053e4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053e8:	2b05                	addiw	s6,s6,1
    800053ea:	0389899b          	addiw	s3,s3,56
    800053ee:	e8845783          	lhu	a5,-376(s0)
    800053f2:	e2fb5be3          	bge	s6,a5,80005228 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800053f6:	2981                	sext.w	s3,s3
    800053f8:	03800713          	li	a4,56
    800053fc:	86ce                	mv	a3,s3
    800053fe:	e1840613          	addi	a2,s0,-488
    80005402:	4581                	li	a1,0
    80005404:	8526                	mv	a0,s1
    80005406:	fffff097          	auipc	ra,0xfffff
    8000540a:	a8e080e7          	jalr	-1394(ra) # 80003e94 <readi>
    8000540e:	03800793          	li	a5,56
    80005412:	f8f517e3          	bne	a0,a5,800053a0 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005416:	e1842783          	lw	a5,-488(s0)
    8000541a:	4705                	li	a4,1
    8000541c:	fce796e3          	bne	a5,a4,800053e8 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005420:	e4043603          	ld	a2,-448(s0)
    80005424:	e3843783          	ld	a5,-456(s0)
    80005428:	f8f669e3          	bltu	a2,a5,800053ba <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000542c:	e2843783          	ld	a5,-472(s0)
    80005430:	963e                	add	a2,a2,a5
    80005432:	f8f667e3          	bltu	a2,a5,800053c0 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005436:	85ca                	mv	a1,s2
    80005438:	855e                	mv	a0,s7
    8000543a:	ffffc097          	auipc	ra,0xffffc
    8000543e:	fe8080e7          	jalr	-24(ra) # 80001422 <uvmalloc>
    80005442:	e0a43423          	sd	a0,-504(s0)
    80005446:	d141                	beqz	a0,800053c6 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005448:	e2843d03          	ld	s10,-472(s0)
    8000544c:	df043783          	ld	a5,-528(s0)
    80005450:	00fd77b3          	and	a5,s10,a5
    80005454:	fba1                	bnez	a5,800053a4 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005456:	e2042d83          	lw	s11,-480(s0)
    8000545a:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000545e:	f80c03e3          	beqz	s8,800053e4 <exec+0x306>
    80005462:	8a62                	mv	s4,s8
    80005464:	4901                	li	s2,0
    80005466:	b345                	j	80005206 <exec+0x128>

0000000080005468 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005468:	7179                	addi	sp,sp,-48
    8000546a:	f406                	sd	ra,40(sp)
    8000546c:	f022                	sd	s0,32(sp)
    8000546e:	ec26                	sd	s1,24(sp)
    80005470:	e84a                	sd	s2,16(sp)
    80005472:	1800                	addi	s0,sp,48
    80005474:	892e                	mv	s2,a1
    80005476:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005478:	fdc40593          	addi	a1,s0,-36
    8000547c:	ffffe097          	auipc	ra,0xffffe
    80005480:	bf2080e7          	jalr	-1038(ra) # 8000306e <argint>
    80005484:	04054063          	bltz	a0,800054c4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005488:	fdc42703          	lw	a4,-36(s0)
    8000548c:	47bd                	li	a5,15
    8000548e:	02e7ed63          	bltu	a5,a4,800054c8 <argfd+0x60>
    80005492:	ffffd097          	auipc	ra,0xffffd
    80005496:	872080e7          	jalr	-1934(ra) # 80001d04 <myproc>
    8000549a:	fdc42703          	lw	a4,-36(s0)
    8000549e:	01a70793          	addi	a5,a4,26
    800054a2:	078e                	slli	a5,a5,0x3
    800054a4:	953e                	add	a0,a0,a5
    800054a6:	611c                	ld	a5,0(a0)
    800054a8:	c395                	beqz	a5,800054cc <argfd+0x64>
    return -1;
  if(pfd)
    800054aa:	00090463          	beqz	s2,800054b2 <argfd+0x4a>
    *pfd = fd;
    800054ae:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800054b2:	4501                	li	a0,0
  if(pf)
    800054b4:	c091                	beqz	s1,800054b8 <argfd+0x50>
    *pf = f;
    800054b6:	e09c                	sd	a5,0(s1)
}
    800054b8:	70a2                	ld	ra,40(sp)
    800054ba:	7402                	ld	s0,32(sp)
    800054bc:	64e2                	ld	s1,24(sp)
    800054be:	6942                	ld	s2,16(sp)
    800054c0:	6145                	addi	sp,sp,48
    800054c2:	8082                	ret
    return -1;
    800054c4:	557d                	li	a0,-1
    800054c6:	bfcd                	j	800054b8 <argfd+0x50>
    return -1;
    800054c8:	557d                	li	a0,-1
    800054ca:	b7fd                	j	800054b8 <argfd+0x50>
    800054cc:	557d                	li	a0,-1
    800054ce:	b7ed                	j	800054b8 <argfd+0x50>

00000000800054d0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800054d0:	1101                	addi	sp,sp,-32
    800054d2:	ec06                	sd	ra,24(sp)
    800054d4:	e822                	sd	s0,16(sp)
    800054d6:	e426                	sd	s1,8(sp)
    800054d8:	1000                	addi	s0,sp,32
    800054da:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800054dc:	ffffd097          	auipc	ra,0xffffd
    800054e0:	828080e7          	jalr	-2008(ra) # 80001d04 <myproc>
    800054e4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054e6:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800054ea:	4501                	li	a0,0
    800054ec:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800054ee:	6398                	ld	a4,0(a5)
    800054f0:	cb19                	beqz	a4,80005506 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800054f2:	2505                	addiw	a0,a0,1
    800054f4:	07a1                	addi	a5,a5,8
    800054f6:	fed51ce3          	bne	a0,a3,800054ee <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800054fa:	557d                	li	a0,-1
}
    800054fc:	60e2                	ld	ra,24(sp)
    800054fe:	6442                	ld	s0,16(sp)
    80005500:	64a2                	ld	s1,8(sp)
    80005502:	6105                	addi	sp,sp,32
    80005504:	8082                	ret
      p->ofile[fd] = f;
    80005506:	01a50793          	addi	a5,a0,26
    8000550a:	078e                	slli	a5,a5,0x3
    8000550c:	963e                	add	a2,a2,a5
    8000550e:	e204                	sd	s1,0(a2)
      return fd;
    80005510:	b7f5                	j	800054fc <fdalloc+0x2c>

0000000080005512 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005512:	715d                	addi	sp,sp,-80
    80005514:	e486                	sd	ra,72(sp)
    80005516:	e0a2                	sd	s0,64(sp)
    80005518:	fc26                	sd	s1,56(sp)
    8000551a:	f84a                	sd	s2,48(sp)
    8000551c:	f44e                	sd	s3,40(sp)
    8000551e:	f052                	sd	s4,32(sp)
    80005520:	ec56                	sd	s5,24(sp)
    80005522:	0880                	addi	s0,sp,80
    80005524:	89ae                	mv	s3,a1
    80005526:	8ab2                	mv	s5,a2
    80005528:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000552a:	fb040593          	addi	a1,s0,-80
    8000552e:	fffff097          	auipc	ra,0xfffff
    80005532:	e86080e7          	jalr	-378(ra) # 800043b4 <nameiparent>
    80005536:	892a                	mv	s2,a0
    80005538:	12050f63          	beqz	a0,80005676 <create+0x164>
    return 0;

  ilock(dp);
    8000553c:	ffffe097          	auipc	ra,0xffffe
    80005540:	6a4080e7          	jalr	1700(ra) # 80003be0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005544:	4601                	li	a2,0
    80005546:	fb040593          	addi	a1,s0,-80
    8000554a:	854a                	mv	a0,s2
    8000554c:	fffff097          	auipc	ra,0xfffff
    80005550:	b78080e7          	jalr	-1160(ra) # 800040c4 <dirlookup>
    80005554:	84aa                	mv	s1,a0
    80005556:	c921                	beqz	a0,800055a6 <create+0x94>
    iunlockput(dp);
    80005558:	854a                	mv	a0,s2
    8000555a:	fffff097          	auipc	ra,0xfffff
    8000555e:	8e8080e7          	jalr	-1816(ra) # 80003e42 <iunlockput>
    ilock(ip);
    80005562:	8526                	mv	a0,s1
    80005564:	ffffe097          	auipc	ra,0xffffe
    80005568:	67c080e7          	jalr	1660(ra) # 80003be0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000556c:	2981                	sext.w	s3,s3
    8000556e:	4789                	li	a5,2
    80005570:	02f99463          	bne	s3,a5,80005598 <create+0x86>
    80005574:	0444d783          	lhu	a5,68(s1)
    80005578:	37f9                	addiw	a5,a5,-2
    8000557a:	17c2                	slli	a5,a5,0x30
    8000557c:	93c1                	srli	a5,a5,0x30
    8000557e:	4705                	li	a4,1
    80005580:	00f76c63          	bltu	a4,a5,80005598 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005584:	8526                	mv	a0,s1
    80005586:	60a6                	ld	ra,72(sp)
    80005588:	6406                	ld	s0,64(sp)
    8000558a:	74e2                	ld	s1,56(sp)
    8000558c:	7942                	ld	s2,48(sp)
    8000558e:	79a2                	ld	s3,40(sp)
    80005590:	7a02                	ld	s4,32(sp)
    80005592:	6ae2                	ld	s5,24(sp)
    80005594:	6161                	addi	sp,sp,80
    80005596:	8082                	ret
    iunlockput(ip);
    80005598:	8526                	mv	a0,s1
    8000559a:	fffff097          	auipc	ra,0xfffff
    8000559e:	8a8080e7          	jalr	-1880(ra) # 80003e42 <iunlockput>
    return 0;
    800055a2:	4481                	li	s1,0
    800055a4:	b7c5                	j	80005584 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800055a6:	85ce                	mv	a1,s3
    800055a8:	00092503          	lw	a0,0(s2)
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	49c080e7          	jalr	1180(ra) # 80003a48 <ialloc>
    800055b4:	84aa                	mv	s1,a0
    800055b6:	c529                	beqz	a0,80005600 <create+0xee>
  ilock(ip);
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	628080e7          	jalr	1576(ra) # 80003be0 <ilock>
  ip->major = major;
    800055c0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800055c4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800055c8:	4785                	li	a5,1
    800055ca:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055ce:	8526                	mv	a0,s1
    800055d0:	ffffe097          	auipc	ra,0xffffe
    800055d4:	546080e7          	jalr	1350(ra) # 80003b16 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800055d8:	2981                	sext.w	s3,s3
    800055da:	4785                	li	a5,1
    800055dc:	02f98a63          	beq	s3,a5,80005610 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800055e0:	40d0                	lw	a2,4(s1)
    800055e2:	fb040593          	addi	a1,s0,-80
    800055e6:	854a                	mv	a0,s2
    800055e8:	fffff097          	auipc	ra,0xfffff
    800055ec:	cec080e7          	jalr	-788(ra) # 800042d4 <dirlink>
    800055f0:	06054b63          	bltz	a0,80005666 <create+0x154>
  iunlockput(dp);
    800055f4:	854a                	mv	a0,s2
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	84c080e7          	jalr	-1972(ra) # 80003e42 <iunlockput>
  return ip;
    800055fe:	b759                	j	80005584 <create+0x72>
    panic("create: ialloc");
    80005600:	00003517          	auipc	a0,0x3
    80005604:	17050513          	addi	a0,a0,368 # 80008770 <syscalls+0x2a0>
    80005608:	ffffb097          	auipc	ra,0xffffb
    8000560c:	f36080e7          	jalr	-202(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005610:	04a95783          	lhu	a5,74(s2)
    80005614:	2785                	addiw	a5,a5,1
    80005616:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000561a:	854a                	mv	a0,s2
    8000561c:	ffffe097          	auipc	ra,0xffffe
    80005620:	4fa080e7          	jalr	1274(ra) # 80003b16 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005624:	40d0                	lw	a2,4(s1)
    80005626:	00003597          	auipc	a1,0x3
    8000562a:	15a58593          	addi	a1,a1,346 # 80008780 <syscalls+0x2b0>
    8000562e:	8526                	mv	a0,s1
    80005630:	fffff097          	auipc	ra,0xfffff
    80005634:	ca4080e7          	jalr	-860(ra) # 800042d4 <dirlink>
    80005638:	00054f63          	bltz	a0,80005656 <create+0x144>
    8000563c:	00492603          	lw	a2,4(s2)
    80005640:	00003597          	auipc	a1,0x3
    80005644:	14858593          	addi	a1,a1,328 # 80008788 <syscalls+0x2b8>
    80005648:	8526                	mv	a0,s1
    8000564a:	fffff097          	auipc	ra,0xfffff
    8000564e:	c8a080e7          	jalr	-886(ra) # 800042d4 <dirlink>
    80005652:	f80557e3          	bgez	a0,800055e0 <create+0xce>
      panic("create dots");
    80005656:	00003517          	auipc	a0,0x3
    8000565a:	13a50513          	addi	a0,a0,314 # 80008790 <syscalls+0x2c0>
    8000565e:	ffffb097          	auipc	ra,0xffffb
    80005662:	ee0080e7          	jalr	-288(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005666:	00003517          	auipc	a0,0x3
    8000566a:	13a50513          	addi	a0,a0,314 # 800087a0 <syscalls+0x2d0>
    8000566e:	ffffb097          	auipc	ra,0xffffb
    80005672:	ed0080e7          	jalr	-304(ra) # 8000053e <panic>
    return 0;
    80005676:	84aa                	mv	s1,a0
    80005678:	b731                	j	80005584 <create+0x72>

000000008000567a <sys_dup>:
{
    8000567a:	7179                	addi	sp,sp,-48
    8000567c:	f406                	sd	ra,40(sp)
    8000567e:	f022                	sd	s0,32(sp)
    80005680:	ec26                	sd	s1,24(sp)
    80005682:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005684:	fd840613          	addi	a2,s0,-40
    80005688:	4581                	li	a1,0
    8000568a:	4501                	li	a0,0
    8000568c:	00000097          	auipc	ra,0x0
    80005690:	ddc080e7          	jalr	-548(ra) # 80005468 <argfd>
    return -1;
    80005694:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005696:	02054363          	bltz	a0,800056bc <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000569a:	fd843503          	ld	a0,-40(s0)
    8000569e:	00000097          	auipc	ra,0x0
    800056a2:	e32080e7          	jalr	-462(ra) # 800054d0 <fdalloc>
    800056a6:	84aa                	mv	s1,a0
    return -1;
    800056a8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800056aa:	00054963          	bltz	a0,800056bc <sys_dup+0x42>
  filedup(f);
    800056ae:	fd843503          	ld	a0,-40(s0)
    800056b2:	fffff097          	auipc	ra,0xfffff
    800056b6:	37a080e7          	jalr	890(ra) # 80004a2c <filedup>
  return fd;
    800056ba:	87a6                	mv	a5,s1
}
    800056bc:	853e                	mv	a0,a5
    800056be:	70a2                	ld	ra,40(sp)
    800056c0:	7402                	ld	s0,32(sp)
    800056c2:	64e2                	ld	s1,24(sp)
    800056c4:	6145                	addi	sp,sp,48
    800056c6:	8082                	ret

00000000800056c8 <sys_read>:
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
    800056dc:	d90080e7          	jalr	-624(ra) # 80005468 <argfd>
    return -1;
    800056e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056e2:	04054163          	bltz	a0,80005724 <sys_read+0x5c>
    800056e6:	fe440593          	addi	a1,s0,-28
    800056ea:	4509                	li	a0,2
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	982080e7          	jalr	-1662(ra) # 8000306e <argint>
    return -1;
    800056f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056f6:	02054763          	bltz	a0,80005724 <sys_read+0x5c>
    800056fa:	fd840593          	addi	a1,s0,-40
    800056fe:	4505                	li	a0,1
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	990080e7          	jalr	-1648(ra) # 80003090 <argaddr>
    return -1;
    80005708:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000570a:	00054d63          	bltz	a0,80005724 <sys_read+0x5c>
  return fileread(f, p, n);
    8000570e:	fe442603          	lw	a2,-28(s0)
    80005712:	fd843583          	ld	a1,-40(s0)
    80005716:	fe843503          	ld	a0,-24(s0)
    8000571a:	fffff097          	auipc	ra,0xfffff
    8000571e:	49e080e7          	jalr	1182(ra) # 80004bb8 <fileread>
    80005722:	87aa                	mv	a5,a0
}
    80005724:	853e                	mv	a0,a5
    80005726:	70a2                	ld	ra,40(sp)
    80005728:	7402                	ld	s0,32(sp)
    8000572a:	6145                	addi	sp,sp,48
    8000572c:	8082                	ret

000000008000572e <sys_write>:
{
    8000572e:	7179                	addi	sp,sp,-48
    80005730:	f406                	sd	ra,40(sp)
    80005732:	f022                	sd	s0,32(sp)
    80005734:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005736:	fe840613          	addi	a2,s0,-24
    8000573a:	4581                	li	a1,0
    8000573c:	4501                	li	a0,0
    8000573e:	00000097          	auipc	ra,0x0
    80005742:	d2a080e7          	jalr	-726(ra) # 80005468 <argfd>
    return -1;
    80005746:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005748:	04054163          	bltz	a0,8000578a <sys_write+0x5c>
    8000574c:	fe440593          	addi	a1,s0,-28
    80005750:	4509                	li	a0,2
    80005752:	ffffe097          	auipc	ra,0xffffe
    80005756:	91c080e7          	jalr	-1764(ra) # 8000306e <argint>
    return -1;
    8000575a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000575c:	02054763          	bltz	a0,8000578a <sys_write+0x5c>
    80005760:	fd840593          	addi	a1,s0,-40
    80005764:	4505                	li	a0,1
    80005766:	ffffe097          	auipc	ra,0xffffe
    8000576a:	92a080e7          	jalr	-1750(ra) # 80003090 <argaddr>
    return -1;
    8000576e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005770:	00054d63          	bltz	a0,8000578a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005774:	fe442603          	lw	a2,-28(s0)
    80005778:	fd843583          	ld	a1,-40(s0)
    8000577c:	fe843503          	ld	a0,-24(s0)
    80005780:	fffff097          	auipc	ra,0xfffff
    80005784:	4fa080e7          	jalr	1274(ra) # 80004c7a <filewrite>
    80005788:	87aa                	mv	a5,a0
}
    8000578a:	853e                	mv	a0,a5
    8000578c:	70a2                	ld	ra,40(sp)
    8000578e:	7402                	ld	s0,32(sp)
    80005790:	6145                	addi	sp,sp,48
    80005792:	8082                	ret

0000000080005794 <sys_close>:
{
    80005794:	1101                	addi	sp,sp,-32
    80005796:	ec06                	sd	ra,24(sp)
    80005798:	e822                	sd	s0,16(sp)
    8000579a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000579c:	fe040613          	addi	a2,s0,-32
    800057a0:	fec40593          	addi	a1,s0,-20
    800057a4:	4501                	li	a0,0
    800057a6:	00000097          	auipc	ra,0x0
    800057aa:	cc2080e7          	jalr	-830(ra) # 80005468 <argfd>
    return -1;
    800057ae:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057b0:	02054463          	bltz	a0,800057d8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800057b4:	ffffc097          	auipc	ra,0xffffc
    800057b8:	550080e7          	jalr	1360(ra) # 80001d04 <myproc>
    800057bc:	fec42783          	lw	a5,-20(s0)
    800057c0:	07e9                	addi	a5,a5,26
    800057c2:	078e                	slli	a5,a5,0x3
    800057c4:	97aa                	add	a5,a5,a0
    800057c6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800057ca:	fe043503          	ld	a0,-32(s0)
    800057ce:	fffff097          	auipc	ra,0xfffff
    800057d2:	2b0080e7          	jalr	688(ra) # 80004a7e <fileclose>
  return 0;
    800057d6:	4781                	li	a5,0
}
    800057d8:	853e                	mv	a0,a5
    800057da:	60e2                	ld	ra,24(sp)
    800057dc:	6442                	ld	s0,16(sp)
    800057de:	6105                	addi	sp,sp,32
    800057e0:	8082                	ret

00000000800057e2 <sys_fstat>:
{
    800057e2:	1101                	addi	sp,sp,-32
    800057e4:	ec06                	sd	ra,24(sp)
    800057e6:	e822                	sd	s0,16(sp)
    800057e8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057ea:	fe840613          	addi	a2,s0,-24
    800057ee:	4581                	li	a1,0
    800057f0:	4501                	li	a0,0
    800057f2:	00000097          	auipc	ra,0x0
    800057f6:	c76080e7          	jalr	-906(ra) # 80005468 <argfd>
    return -1;
    800057fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057fc:	02054563          	bltz	a0,80005826 <sys_fstat+0x44>
    80005800:	fe040593          	addi	a1,s0,-32
    80005804:	4505                	li	a0,1
    80005806:	ffffe097          	auipc	ra,0xffffe
    8000580a:	88a080e7          	jalr	-1910(ra) # 80003090 <argaddr>
    return -1;
    8000580e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005810:	00054b63          	bltz	a0,80005826 <sys_fstat+0x44>
  return filestat(f, st);
    80005814:	fe043583          	ld	a1,-32(s0)
    80005818:	fe843503          	ld	a0,-24(s0)
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	32a080e7          	jalr	810(ra) # 80004b46 <filestat>
    80005824:	87aa                	mv	a5,a0
}
    80005826:	853e                	mv	a0,a5
    80005828:	60e2                	ld	ra,24(sp)
    8000582a:	6442                	ld	s0,16(sp)
    8000582c:	6105                	addi	sp,sp,32
    8000582e:	8082                	ret

0000000080005830 <sys_link>:
{
    80005830:	7169                	addi	sp,sp,-304
    80005832:	f606                	sd	ra,296(sp)
    80005834:	f222                	sd	s0,288(sp)
    80005836:	ee26                	sd	s1,280(sp)
    80005838:	ea4a                	sd	s2,272(sp)
    8000583a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000583c:	08000613          	li	a2,128
    80005840:	ed040593          	addi	a1,s0,-304
    80005844:	4501                	li	a0,0
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	86c080e7          	jalr	-1940(ra) # 800030b2 <argstr>
    return -1;
    8000584e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005850:	10054e63          	bltz	a0,8000596c <sys_link+0x13c>
    80005854:	08000613          	li	a2,128
    80005858:	f5040593          	addi	a1,s0,-176
    8000585c:	4505                	li	a0,1
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	854080e7          	jalr	-1964(ra) # 800030b2 <argstr>
    return -1;
    80005866:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005868:	10054263          	bltz	a0,8000596c <sys_link+0x13c>
  begin_op();
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	d46080e7          	jalr	-698(ra) # 800045b2 <begin_op>
  if((ip = namei(old)) == 0){
    80005874:	ed040513          	addi	a0,s0,-304
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	b1e080e7          	jalr	-1250(ra) # 80004396 <namei>
    80005880:	84aa                	mv	s1,a0
    80005882:	c551                	beqz	a0,8000590e <sys_link+0xde>
  ilock(ip);
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	35c080e7          	jalr	860(ra) # 80003be0 <ilock>
  if(ip->type == T_DIR){
    8000588c:	04449703          	lh	a4,68(s1)
    80005890:	4785                	li	a5,1
    80005892:	08f70463          	beq	a4,a5,8000591a <sys_link+0xea>
  ip->nlink++;
    80005896:	04a4d783          	lhu	a5,74(s1)
    8000589a:	2785                	addiw	a5,a5,1
    8000589c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058a0:	8526                	mv	a0,s1
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	274080e7          	jalr	628(ra) # 80003b16 <iupdate>
  iunlock(ip);
    800058aa:	8526                	mv	a0,s1
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	3f6080e7          	jalr	1014(ra) # 80003ca2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058b4:	fd040593          	addi	a1,s0,-48
    800058b8:	f5040513          	addi	a0,s0,-176
    800058bc:	fffff097          	auipc	ra,0xfffff
    800058c0:	af8080e7          	jalr	-1288(ra) # 800043b4 <nameiparent>
    800058c4:	892a                	mv	s2,a0
    800058c6:	c935                	beqz	a0,8000593a <sys_link+0x10a>
  ilock(dp);
    800058c8:	ffffe097          	auipc	ra,0xffffe
    800058cc:	318080e7          	jalr	792(ra) # 80003be0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800058d0:	00092703          	lw	a4,0(s2)
    800058d4:	409c                	lw	a5,0(s1)
    800058d6:	04f71d63          	bne	a4,a5,80005930 <sys_link+0x100>
    800058da:	40d0                	lw	a2,4(s1)
    800058dc:	fd040593          	addi	a1,s0,-48
    800058e0:	854a                	mv	a0,s2
    800058e2:	fffff097          	auipc	ra,0xfffff
    800058e6:	9f2080e7          	jalr	-1550(ra) # 800042d4 <dirlink>
    800058ea:	04054363          	bltz	a0,80005930 <sys_link+0x100>
  iunlockput(dp);
    800058ee:	854a                	mv	a0,s2
    800058f0:	ffffe097          	auipc	ra,0xffffe
    800058f4:	552080e7          	jalr	1362(ra) # 80003e42 <iunlockput>
  iput(ip);
    800058f8:	8526                	mv	a0,s1
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	4a0080e7          	jalr	1184(ra) # 80003d9a <iput>
  end_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	d30080e7          	jalr	-720(ra) # 80004632 <end_op>
  return 0;
    8000590a:	4781                	li	a5,0
    8000590c:	a085                	j	8000596c <sys_link+0x13c>
    end_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	d24080e7          	jalr	-732(ra) # 80004632 <end_op>
    return -1;
    80005916:	57fd                	li	a5,-1
    80005918:	a891                	j	8000596c <sys_link+0x13c>
    iunlockput(ip);
    8000591a:	8526                	mv	a0,s1
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	526080e7          	jalr	1318(ra) # 80003e42 <iunlockput>
    end_op();
    80005924:	fffff097          	auipc	ra,0xfffff
    80005928:	d0e080e7          	jalr	-754(ra) # 80004632 <end_op>
    return -1;
    8000592c:	57fd                	li	a5,-1
    8000592e:	a83d                	j	8000596c <sys_link+0x13c>
    iunlockput(dp);
    80005930:	854a                	mv	a0,s2
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	510080e7          	jalr	1296(ra) # 80003e42 <iunlockput>
  ilock(ip);
    8000593a:	8526                	mv	a0,s1
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	2a4080e7          	jalr	676(ra) # 80003be0 <ilock>
  ip->nlink--;
    80005944:	04a4d783          	lhu	a5,74(s1)
    80005948:	37fd                	addiw	a5,a5,-1
    8000594a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000594e:	8526                	mv	a0,s1
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	1c6080e7          	jalr	454(ra) # 80003b16 <iupdate>
  iunlockput(ip);
    80005958:	8526                	mv	a0,s1
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	4e8080e7          	jalr	1256(ra) # 80003e42 <iunlockput>
  end_op();
    80005962:	fffff097          	auipc	ra,0xfffff
    80005966:	cd0080e7          	jalr	-816(ra) # 80004632 <end_op>
  return -1;
    8000596a:	57fd                	li	a5,-1
}
    8000596c:	853e                	mv	a0,a5
    8000596e:	70b2                	ld	ra,296(sp)
    80005970:	7412                	ld	s0,288(sp)
    80005972:	64f2                	ld	s1,280(sp)
    80005974:	6952                	ld	s2,272(sp)
    80005976:	6155                	addi	sp,sp,304
    80005978:	8082                	ret

000000008000597a <sys_unlink>:
{
    8000597a:	7151                	addi	sp,sp,-240
    8000597c:	f586                	sd	ra,232(sp)
    8000597e:	f1a2                	sd	s0,224(sp)
    80005980:	eda6                	sd	s1,216(sp)
    80005982:	e9ca                	sd	s2,208(sp)
    80005984:	e5ce                	sd	s3,200(sp)
    80005986:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005988:	08000613          	li	a2,128
    8000598c:	f3040593          	addi	a1,s0,-208
    80005990:	4501                	li	a0,0
    80005992:	ffffd097          	auipc	ra,0xffffd
    80005996:	720080e7          	jalr	1824(ra) # 800030b2 <argstr>
    8000599a:	18054163          	bltz	a0,80005b1c <sys_unlink+0x1a2>
  begin_op();
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	c14080e7          	jalr	-1004(ra) # 800045b2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800059a6:	fb040593          	addi	a1,s0,-80
    800059aa:	f3040513          	addi	a0,s0,-208
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	a06080e7          	jalr	-1530(ra) # 800043b4 <nameiparent>
    800059b6:	84aa                	mv	s1,a0
    800059b8:	c979                	beqz	a0,80005a8e <sys_unlink+0x114>
  ilock(dp);
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	226080e7          	jalr	550(ra) # 80003be0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800059c2:	00003597          	auipc	a1,0x3
    800059c6:	dbe58593          	addi	a1,a1,-578 # 80008780 <syscalls+0x2b0>
    800059ca:	fb040513          	addi	a0,s0,-80
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	6dc080e7          	jalr	1756(ra) # 800040aa <namecmp>
    800059d6:	14050a63          	beqz	a0,80005b2a <sys_unlink+0x1b0>
    800059da:	00003597          	auipc	a1,0x3
    800059de:	dae58593          	addi	a1,a1,-594 # 80008788 <syscalls+0x2b8>
    800059e2:	fb040513          	addi	a0,s0,-80
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	6c4080e7          	jalr	1732(ra) # 800040aa <namecmp>
    800059ee:	12050e63          	beqz	a0,80005b2a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800059f2:	f2c40613          	addi	a2,s0,-212
    800059f6:	fb040593          	addi	a1,s0,-80
    800059fa:	8526                	mv	a0,s1
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	6c8080e7          	jalr	1736(ra) # 800040c4 <dirlookup>
    80005a04:	892a                	mv	s2,a0
    80005a06:	12050263          	beqz	a0,80005b2a <sys_unlink+0x1b0>
  ilock(ip);
    80005a0a:	ffffe097          	auipc	ra,0xffffe
    80005a0e:	1d6080e7          	jalr	470(ra) # 80003be0 <ilock>
  if(ip->nlink < 1)
    80005a12:	04a91783          	lh	a5,74(s2)
    80005a16:	08f05263          	blez	a5,80005a9a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a1a:	04491703          	lh	a4,68(s2)
    80005a1e:	4785                	li	a5,1
    80005a20:	08f70563          	beq	a4,a5,80005aaa <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a24:	4641                	li	a2,16
    80005a26:	4581                	li	a1,0
    80005a28:	fc040513          	addi	a0,s0,-64
    80005a2c:	ffffb097          	auipc	ra,0xffffb
    80005a30:	2b4080e7          	jalr	692(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a34:	4741                	li	a4,16
    80005a36:	f2c42683          	lw	a3,-212(s0)
    80005a3a:	fc040613          	addi	a2,s0,-64
    80005a3e:	4581                	li	a1,0
    80005a40:	8526                	mv	a0,s1
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	54a080e7          	jalr	1354(ra) # 80003f8c <writei>
    80005a4a:	47c1                	li	a5,16
    80005a4c:	0af51563          	bne	a0,a5,80005af6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a50:	04491703          	lh	a4,68(s2)
    80005a54:	4785                	li	a5,1
    80005a56:	0af70863          	beq	a4,a5,80005b06 <sys_unlink+0x18c>
  iunlockput(dp);
    80005a5a:	8526                	mv	a0,s1
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	3e6080e7          	jalr	998(ra) # 80003e42 <iunlockput>
  ip->nlink--;
    80005a64:	04a95783          	lhu	a5,74(s2)
    80005a68:	37fd                	addiw	a5,a5,-1
    80005a6a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a6e:	854a                	mv	a0,s2
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	0a6080e7          	jalr	166(ra) # 80003b16 <iupdate>
  iunlockput(ip);
    80005a78:	854a                	mv	a0,s2
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	3c8080e7          	jalr	968(ra) # 80003e42 <iunlockput>
  end_op();
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	bb0080e7          	jalr	-1104(ra) # 80004632 <end_op>
  return 0;
    80005a8a:	4501                	li	a0,0
    80005a8c:	a84d                	j	80005b3e <sys_unlink+0x1c4>
    end_op();
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	ba4080e7          	jalr	-1116(ra) # 80004632 <end_op>
    return -1;
    80005a96:	557d                	li	a0,-1
    80005a98:	a05d                	j	80005b3e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a9a:	00003517          	auipc	a0,0x3
    80005a9e:	d1650513          	addi	a0,a0,-746 # 800087b0 <syscalls+0x2e0>
    80005aa2:	ffffb097          	auipc	ra,0xffffb
    80005aa6:	a9c080e7          	jalr	-1380(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005aaa:	04c92703          	lw	a4,76(s2)
    80005aae:	02000793          	li	a5,32
    80005ab2:	f6e7f9e3          	bgeu	a5,a4,80005a24 <sys_unlink+0xaa>
    80005ab6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005aba:	4741                	li	a4,16
    80005abc:	86ce                	mv	a3,s3
    80005abe:	f1840613          	addi	a2,s0,-232
    80005ac2:	4581                	li	a1,0
    80005ac4:	854a                	mv	a0,s2
    80005ac6:	ffffe097          	auipc	ra,0xffffe
    80005aca:	3ce080e7          	jalr	974(ra) # 80003e94 <readi>
    80005ace:	47c1                	li	a5,16
    80005ad0:	00f51b63          	bne	a0,a5,80005ae6 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005ad4:	f1845783          	lhu	a5,-232(s0)
    80005ad8:	e7a1                	bnez	a5,80005b20 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ada:	29c1                	addiw	s3,s3,16
    80005adc:	04c92783          	lw	a5,76(s2)
    80005ae0:	fcf9ede3          	bltu	s3,a5,80005aba <sys_unlink+0x140>
    80005ae4:	b781                	j	80005a24 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005ae6:	00003517          	auipc	a0,0x3
    80005aea:	ce250513          	addi	a0,a0,-798 # 800087c8 <syscalls+0x2f8>
    80005aee:	ffffb097          	auipc	ra,0xffffb
    80005af2:	a50080e7          	jalr	-1456(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005af6:	00003517          	auipc	a0,0x3
    80005afa:	cea50513          	addi	a0,a0,-790 # 800087e0 <syscalls+0x310>
    80005afe:	ffffb097          	auipc	ra,0xffffb
    80005b02:	a40080e7          	jalr	-1472(ra) # 8000053e <panic>
    dp->nlink--;
    80005b06:	04a4d783          	lhu	a5,74(s1)
    80005b0a:	37fd                	addiw	a5,a5,-1
    80005b0c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b10:	8526                	mv	a0,s1
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	004080e7          	jalr	4(ra) # 80003b16 <iupdate>
    80005b1a:	b781                	j	80005a5a <sys_unlink+0xe0>
    return -1;
    80005b1c:	557d                	li	a0,-1
    80005b1e:	a005                	j	80005b3e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b20:	854a                	mv	a0,s2
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	320080e7          	jalr	800(ra) # 80003e42 <iunlockput>
  iunlockput(dp);
    80005b2a:	8526                	mv	a0,s1
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	316080e7          	jalr	790(ra) # 80003e42 <iunlockput>
  end_op();
    80005b34:	fffff097          	auipc	ra,0xfffff
    80005b38:	afe080e7          	jalr	-1282(ra) # 80004632 <end_op>
  return -1;
    80005b3c:	557d                	li	a0,-1
}
    80005b3e:	70ae                	ld	ra,232(sp)
    80005b40:	740e                	ld	s0,224(sp)
    80005b42:	64ee                	ld	s1,216(sp)
    80005b44:	694e                	ld	s2,208(sp)
    80005b46:	69ae                	ld	s3,200(sp)
    80005b48:	616d                	addi	sp,sp,240
    80005b4a:	8082                	ret

0000000080005b4c <sys_open>:

uint64
sys_open(void)
{
    80005b4c:	7131                	addi	sp,sp,-192
    80005b4e:	fd06                	sd	ra,184(sp)
    80005b50:	f922                	sd	s0,176(sp)
    80005b52:	f526                	sd	s1,168(sp)
    80005b54:	f14a                	sd	s2,160(sp)
    80005b56:	ed4e                	sd	s3,152(sp)
    80005b58:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b5a:	08000613          	li	a2,128
    80005b5e:	f5040593          	addi	a1,s0,-176
    80005b62:	4501                	li	a0,0
    80005b64:	ffffd097          	auipc	ra,0xffffd
    80005b68:	54e080e7          	jalr	1358(ra) # 800030b2 <argstr>
    return -1;
    80005b6c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b6e:	0c054163          	bltz	a0,80005c30 <sys_open+0xe4>
    80005b72:	f4c40593          	addi	a1,s0,-180
    80005b76:	4505                	li	a0,1
    80005b78:	ffffd097          	auipc	ra,0xffffd
    80005b7c:	4f6080e7          	jalr	1270(ra) # 8000306e <argint>
    80005b80:	0a054863          	bltz	a0,80005c30 <sys_open+0xe4>

  begin_op();
    80005b84:	fffff097          	auipc	ra,0xfffff
    80005b88:	a2e080e7          	jalr	-1490(ra) # 800045b2 <begin_op>

  if(omode & O_CREATE){
    80005b8c:	f4c42783          	lw	a5,-180(s0)
    80005b90:	2007f793          	andi	a5,a5,512
    80005b94:	cbdd                	beqz	a5,80005c4a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b96:	4681                	li	a3,0
    80005b98:	4601                	li	a2,0
    80005b9a:	4589                	li	a1,2
    80005b9c:	f5040513          	addi	a0,s0,-176
    80005ba0:	00000097          	auipc	ra,0x0
    80005ba4:	972080e7          	jalr	-1678(ra) # 80005512 <create>
    80005ba8:	892a                	mv	s2,a0
    if(ip == 0){
    80005baa:	c959                	beqz	a0,80005c40 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005bac:	04491703          	lh	a4,68(s2)
    80005bb0:	478d                	li	a5,3
    80005bb2:	00f71763          	bne	a4,a5,80005bc0 <sys_open+0x74>
    80005bb6:	04695703          	lhu	a4,70(s2)
    80005bba:	47a5                	li	a5,9
    80005bbc:	0ce7ec63          	bltu	a5,a4,80005c94 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	e02080e7          	jalr	-510(ra) # 800049c2 <filealloc>
    80005bc8:	89aa                	mv	s3,a0
    80005bca:	10050263          	beqz	a0,80005cce <sys_open+0x182>
    80005bce:	00000097          	auipc	ra,0x0
    80005bd2:	902080e7          	jalr	-1790(ra) # 800054d0 <fdalloc>
    80005bd6:	84aa                	mv	s1,a0
    80005bd8:	0e054663          	bltz	a0,80005cc4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005bdc:	04491703          	lh	a4,68(s2)
    80005be0:	478d                	li	a5,3
    80005be2:	0cf70463          	beq	a4,a5,80005caa <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005be6:	4789                	li	a5,2
    80005be8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005bec:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005bf0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005bf4:	f4c42783          	lw	a5,-180(s0)
    80005bf8:	0017c713          	xori	a4,a5,1
    80005bfc:	8b05                	andi	a4,a4,1
    80005bfe:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c02:	0037f713          	andi	a4,a5,3
    80005c06:	00e03733          	snez	a4,a4
    80005c0a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c0e:	4007f793          	andi	a5,a5,1024
    80005c12:	c791                	beqz	a5,80005c1e <sys_open+0xd2>
    80005c14:	04491703          	lh	a4,68(s2)
    80005c18:	4789                	li	a5,2
    80005c1a:	08f70f63          	beq	a4,a5,80005cb8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c1e:	854a                	mv	a0,s2
    80005c20:	ffffe097          	auipc	ra,0xffffe
    80005c24:	082080e7          	jalr	130(ra) # 80003ca2 <iunlock>
  end_op();
    80005c28:	fffff097          	auipc	ra,0xfffff
    80005c2c:	a0a080e7          	jalr	-1526(ra) # 80004632 <end_op>

  return fd;
}
    80005c30:	8526                	mv	a0,s1
    80005c32:	70ea                	ld	ra,184(sp)
    80005c34:	744a                	ld	s0,176(sp)
    80005c36:	74aa                	ld	s1,168(sp)
    80005c38:	790a                	ld	s2,160(sp)
    80005c3a:	69ea                	ld	s3,152(sp)
    80005c3c:	6129                	addi	sp,sp,192
    80005c3e:	8082                	ret
      end_op();
    80005c40:	fffff097          	auipc	ra,0xfffff
    80005c44:	9f2080e7          	jalr	-1550(ra) # 80004632 <end_op>
      return -1;
    80005c48:	b7e5                	j	80005c30 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c4a:	f5040513          	addi	a0,s0,-176
    80005c4e:	ffffe097          	auipc	ra,0xffffe
    80005c52:	748080e7          	jalr	1864(ra) # 80004396 <namei>
    80005c56:	892a                	mv	s2,a0
    80005c58:	c905                	beqz	a0,80005c88 <sys_open+0x13c>
    ilock(ip);
    80005c5a:	ffffe097          	auipc	ra,0xffffe
    80005c5e:	f86080e7          	jalr	-122(ra) # 80003be0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c62:	04491703          	lh	a4,68(s2)
    80005c66:	4785                	li	a5,1
    80005c68:	f4f712e3          	bne	a4,a5,80005bac <sys_open+0x60>
    80005c6c:	f4c42783          	lw	a5,-180(s0)
    80005c70:	dba1                	beqz	a5,80005bc0 <sys_open+0x74>
      iunlockput(ip);
    80005c72:	854a                	mv	a0,s2
    80005c74:	ffffe097          	auipc	ra,0xffffe
    80005c78:	1ce080e7          	jalr	462(ra) # 80003e42 <iunlockput>
      end_op();
    80005c7c:	fffff097          	auipc	ra,0xfffff
    80005c80:	9b6080e7          	jalr	-1610(ra) # 80004632 <end_op>
      return -1;
    80005c84:	54fd                	li	s1,-1
    80005c86:	b76d                	j	80005c30 <sys_open+0xe4>
      end_op();
    80005c88:	fffff097          	auipc	ra,0xfffff
    80005c8c:	9aa080e7          	jalr	-1622(ra) # 80004632 <end_op>
      return -1;
    80005c90:	54fd                	li	s1,-1
    80005c92:	bf79                	j	80005c30 <sys_open+0xe4>
    iunlockput(ip);
    80005c94:	854a                	mv	a0,s2
    80005c96:	ffffe097          	auipc	ra,0xffffe
    80005c9a:	1ac080e7          	jalr	428(ra) # 80003e42 <iunlockput>
    end_op();
    80005c9e:	fffff097          	auipc	ra,0xfffff
    80005ca2:	994080e7          	jalr	-1644(ra) # 80004632 <end_op>
    return -1;
    80005ca6:	54fd                	li	s1,-1
    80005ca8:	b761                	j	80005c30 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005caa:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005cae:	04691783          	lh	a5,70(s2)
    80005cb2:	02f99223          	sh	a5,36(s3)
    80005cb6:	bf2d                	j	80005bf0 <sys_open+0xa4>
    itrunc(ip);
    80005cb8:	854a                	mv	a0,s2
    80005cba:	ffffe097          	auipc	ra,0xffffe
    80005cbe:	034080e7          	jalr	52(ra) # 80003cee <itrunc>
    80005cc2:	bfb1                	j	80005c1e <sys_open+0xd2>
      fileclose(f);
    80005cc4:	854e                	mv	a0,s3
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	db8080e7          	jalr	-584(ra) # 80004a7e <fileclose>
    iunlockput(ip);
    80005cce:	854a                	mv	a0,s2
    80005cd0:	ffffe097          	auipc	ra,0xffffe
    80005cd4:	172080e7          	jalr	370(ra) # 80003e42 <iunlockput>
    end_op();
    80005cd8:	fffff097          	auipc	ra,0xfffff
    80005cdc:	95a080e7          	jalr	-1702(ra) # 80004632 <end_op>
    return -1;
    80005ce0:	54fd                	li	s1,-1
    80005ce2:	b7b9                	j	80005c30 <sys_open+0xe4>

0000000080005ce4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ce4:	7175                	addi	sp,sp,-144
    80005ce6:	e506                	sd	ra,136(sp)
    80005ce8:	e122                	sd	s0,128(sp)
    80005cea:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005cec:	fffff097          	auipc	ra,0xfffff
    80005cf0:	8c6080e7          	jalr	-1850(ra) # 800045b2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005cf4:	08000613          	li	a2,128
    80005cf8:	f7040593          	addi	a1,s0,-144
    80005cfc:	4501                	li	a0,0
    80005cfe:	ffffd097          	auipc	ra,0xffffd
    80005d02:	3b4080e7          	jalr	948(ra) # 800030b2 <argstr>
    80005d06:	02054963          	bltz	a0,80005d38 <sys_mkdir+0x54>
    80005d0a:	4681                	li	a3,0
    80005d0c:	4601                	li	a2,0
    80005d0e:	4585                	li	a1,1
    80005d10:	f7040513          	addi	a0,s0,-144
    80005d14:	fffff097          	auipc	ra,0xfffff
    80005d18:	7fe080e7          	jalr	2046(ra) # 80005512 <create>
    80005d1c:	cd11                	beqz	a0,80005d38 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d1e:	ffffe097          	auipc	ra,0xffffe
    80005d22:	124080e7          	jalr	292(ra) # 80003e42 <iunlockput>
  end_op();
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	90c080e7          	jalr	-1780(ra) # 80004632 <end_op>
  return 0;
    80005d2e:	4501                	li	a0,0
}
    80005d30:	60aa                	ld	ra,136(sp)
    80005d32:	640a                	ld	s0,128(sp)
    80005d34:	6149                	addi	sp,sp,144
    80005d36:	8082                	ret
    end_op();
    80005d38:	fffff097          	auipc	ra,0xfffff
    80005d3c:	8fa080e7          	jalr	-1798(ra) # 80004632 <end_op>
    return -1;
    80005d40:	557d                	li	a0,-1
    80005d42:	b7fd                	j	80005d30 <sys_mkdir+0x4c>

0000000080005d44 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d44:	7135                	addi	sp,sp,-160
    80005d46:	ed06                	sd	ra,152(sp)
    80005d48:	e922                	sd	s0,144(sp)
    80005d4a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d4c:	fffff097          	auipc	ra,0xfffff
    80005d50:	866080e7          	jalr	-1946(ra) # 800045b2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d54:	08000613          	li	a2,128
    80005d58:	f7040593          	addi	a1,s0,-144
    80005d5c:	4501                	li	a0,0
    80005d5e:	ffffd097          	auipc	ra,0xffffd
    80005d62:	354080e7          	jalr	852(ra) # 800030b2 <argstr>
    80005d66:	04054a63          	bltz	a0,80005dba <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d6a:	f6c40593          	addi	a1,s0,-148
    80005d6e:	4505                	li	a0,1
    80005d70:	ffffd097          	auipc	ra,0xffffd
    80005d74:	2fe080e7          	jalr	766(ra) # 8000306e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d78:	04054163          	bltz	a0,80005dba <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d7c:	f6840593          	addi	a1,s0,-152
    80005d80:	4509                	li	a0,2
    80005d82:	ffffd097          	auipc	ra,0xffffd
    80005d86:	2ec080e7          	jalr	748(ra) # 8000306e <argint>
     argint(1, &major) < 0 ||
    80005d8a:	02054863          	bltz	a0,80005dba <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d8e:	f6841683          	lh	a3,-152(s0)
    80005d92:	f6c41603          	lh	a2,-148(s0)
    80005d96:	458d                	li	a1,3
    80005d98:	f7040513          	addi	a0,s0,-144
    80005d9c:	fffff097          	auipc	ra,0xfffff
    80005da0:	776080e7          	jalr	1910(ra) # 80005512 <create>
     argint(2, &minor) < 0 ||
    80005da4:	c919                	beqz	a0,80005dba <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005da6:	ffffe097          	auipc	ra,0xffffe
    80005daa:	09c080e7          	jalr	156(ra) # 80003e42 <iunlockput>
  end_op();
    80005dae:	fffff097          	auipc	ra,0xfffff
    80005db2:	884080e7          	jalr	-1916(ra) # 80004632 <end_op>
  return 0;
    80005db6:	4501                	li	a0,0
    80005db8:	a031                	j	80005dc4 <sys_mknod+0x80>
    end_op();
    80005dba:	fffff097          	auipc	ra,0xfffff
    80005dbe:	878080e7          	jalr	-1928(ra) # 80004632 <end_op>
    return -1;
    80005dc2:	557d                	li	a0,-1
}
    80005dc4:	60ea                	ld	ra,152(sp)
    80005dc6:	644a                	ld	s0,144(sp)
    80005dc8:	610d                	addi	sp,sp,160
    80005dca:	8082                	ret

0000000080005dcc <sys_chdir>:

uint64
sys_chdir(void)
{
    80005dcc:	7135                	addi	sp,sp,-160
    80005dce:	ed06                	sd	ra,152(sp)
    80005dd0:	e922                	sd	s0,144(sp)
    80005dd2:	e526                	sd	s1,136(sp)
    80005dd4:	e14a                	sd	s2,128(sp)
    80005dd6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	f2c080e7          	jalr	-212(ra) # 80001d04 <myproc>
    80005de0:	892a                	mv	s2,a0
  
  begin_op();
    80005de2:	ffffe097          	auipc	ra,0xffffe
    80005de6:	7d0080e7          	jalr	2000(ra) # 800045b2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005dea:	08000613          	li	a2,128
    80005dee:	f6040593          	addi	a1,s0,-160
    80005df2:	4501                	li	a0,0
    80005df4:	ffffd097          	auipc	ra,0xffffd
    80005df8:	2be080e7          	jalr	702(ra) # 800030b2 <argstr>
    80005dfc:	04054b63          	bltz	a0,80005e52 <sys_chdir+0x86>
    80005e00:	f6040513          	addi	a0,s0,-160
    80005e04:	ffffe097          	auipc	ra,0xffffe
    80005e08:	592080e7          	jalr	1426(ra) # 80004396 <namei>
    80005e0c:	84aa                	mv	s1,a0
    80005e0e:	c131                	beqz	a0,80005e52 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e10:	ffffe097          	auipc	ra,0xffffe
    80005e14:	dd0080e7          	jalr	-560(ra) # 80003be0 <ilock>
  if(ip->type != T_DIR){
    80005e18:	04449703          	lh	a4,68(s1)
    80005e1c:	4785                	li	a5,1
    80005e1e:	04f71063          	bne	a4,a5,80005e5e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e22:	8526                	mv	a0,s1
    80005e24:	ffffe097          	auipc	ra,0xffffe
    80005e28:	e7e080e7          	jalr	-386(ra) # 80003ca2 <iunlock>
  iput(p->cwd);
    80005e2c:	15093503          	ld	a0,336(s2)
    80005e30:	ffffe097          	auipc	ra,0xffffe
    80005e34:	f6a080e7          	jalr	-150(ra) # 80003d9a <iput>
  end_op();
    80005e38:	ffffe097          	auipc	ra,0xffffe
    80005e3c:	7fa080e7          	jalr	2042(ra) # 80004632 <end_op>
  p->cwd = ip;
    80005e40:	14993823          	sd	s1,336(s2)
  return 0;
    80005e44:	4501                	li	a0,0
}
    80005e46:	60ea                	ld	ra,152(sp)
    80005e48:	644a                	ld	s0,144(sp)
    80005e4a:	64aa                	ld	s1,136(sp)
    80005e4c:	690a                	ld	s2,128(sp)
    80005e4e:	610d                	addi	sp,sp,160
    80005e50:	8082                	ret
    end_op();
    80005e52:	ffffe097          	auipc	ra,0xffffe
    80005e56:	7e0080e7          	jalr	2016(ra) # 80004632 <end_op>
    return -1;
    80005e5a:	557d                	li	a0,-1
    80005e5c:	b7ed                	j	80005e46 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e5e:	8526                	mv	a0,s1
    80005e60:	ffffe097          	auipc	ra,0xffffe
    80005e64:	fe2080e7          	jalr	-30(ra) # 80003e42 <iunlockput>
    end_op();
    80005e68:	ffffe097          	auipc	ra,0xffffe
    80005e6c:	7ca080e7          	jalr	1994(ra) # 80004632 <end_op>
    return -1;
    80005e70:	557d                	li	a0,-1
    80005e72:	bfd1                	j	80005e46 <sys_chdir+0x7a>

0000000080005e74 <sys_exec>:

uint64
sys_exec(void)
{
    80005e74:	7145                	addi	sp,sp,-464
    80005e76:	e786                	sd	ra,456(sp)
    80005e78:	e3a2                	sd	s0,448(sp)
    80005e7a:	ff26                	sd	s1,440(sp)
    80005e7c:	fb4a                	sd	s2,432(sp)
    80005e7e:	f74e                	sd	s3,424(sp)
    80005e80:	f352                	sd	s4,416(sp)
    80005e82:	ef56                	sd	s5,408(sp)
    80005e84:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e86:	08000613          	li	a2,128
    80005e8a:	f4040593          	addi	a1,s0,-192
    80005e8e:	4501                	li	a0,0
    80005e90:	ffffd097          	auipc	ra,0xffffd
    80005e94:	222080e7          	jalr	546(ra) # 800030b2 <argstr>
    return -1;
    80005e98:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e9a:	0c054a63          	bltz	a0,80005f6e <sys_exec+0xfa>
    80005e9e:	e3840593          	addi	a1,s0,-456
    80005ea2:	4505                	li	a0,1
    80005ea4:	ffffd097          	auipc	ra,0xffffd
    80005ea8:	1ec080e7          	jalr	492(ra) # 80003090 <argaddr>
    80005eac:	0c054163          	bltz	a0,80005f6e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005eb0:	10000613          	li	a2,256
    80005eb4:	4581                	li	a1,0
    80005eb6:	e4040513          	addi	a0,s0,-448
    80005eba:	ffffb097          	auipc	ra,0xffffb
    80005ebe:	e26080e7          	jalr	-474(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ec2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ec6:	89a6                	mv	s3,s1
    80005ec8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005eca:	02000a13          	li	s4,32
    80005ece:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ed2:	00391513          	slli	a0,s2,0x3
    80005ed6:	e3040593          	addi	a1,s0,-464
    80005eda:	e3843783          	ld	a5,-456(s0)
    80005ede:	953e                	add	a0,a0,a5
    80005ee0:	ffffd097          	auipc	ra,0xffffd
    80005ee4:	0f4080e7          	jalr	244(ra) # 80002fd4 <fetchaddr>
    80005ee8:	02054a63          	bltz	a0,80005f1c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005eec:	e3043783          	ld	a5,-464(s0)
    80005ef0:	c3b9                	beqz	a5,80005f36 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ef2:	ffffb097          	auipc	ra,0xffffb
    80005ef6:	c02080e7          	jalr	-1022(ra) # 80000af4 <kalloc>
    80005efa:	85aa                	mv	a1,a0
    80005efc:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f00:	cd11                	beqz	a0,80005f1c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f02:	6605                	lui	a2,0x1
    80005f04:	e3043503          	ld	a0,-464(s0)
    80005f08:	ffffd097          	auipc	ra,0xffffd
    80005f0c:	11e080e7          	jalr	286(ra) # 80003026 <fetchstr>
    80005f10:	00054663          	bltz	a0,80005f1c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005f14:	0905                	addi	s2,s2,1
    80005f16:	09a1                	addi	s3,s3,8
    80005f18:	fb491be3          	bne	s2,s4,80005ece <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f1c:	10048913          	addi	s2,s1,256
    80005f20:	6088                	ld	a0,0(s1)
    80005f22:	c529                	beqz	a0,80005f6c <sys_exec+0xf8>
    kfree(argv[i]);
    80005f24:	ffffb097          	auipc	ra,0xffffb
    80005f28:	ad4080e7          	jalr	-1324(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f2c:	04a1                	addi	s1,s1,8
    80005f2e:	ff2499e3          	bne	s1,s2,80005f20 <sys_exec+0xac>
  return -1;
    80005f32:	597d                	li	s2,-1
    80005f34:	a82d                	j	80005f6e <sys_exec+0xfa>
      argv[i] = 0;
    80005f36:	0a8e                	slli	s5,s5,0x3
    80005f38:	fc040793          	addi	a5,s0,-64
    80005f3c:	9abe                	add	s5,s5,a5
    80005f3e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005f42:	e4040593          	addi	a1,s0,-448
    80005f46:	f4040513          	addi	a0,s0,-192
    80005f4a:	fffff097          	auipc	ra,0xfffff
    80005f4e:	194080e7          	jalr	404(ra) # 800050de <exec>
    80005f52:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f54:	10048993          	addi	s3,s1,256
    80005f58:	6088                	ld	a0,0(s1)
    80005f5a:	c911                	beqz	a0,80005f6e <sys_exec+0xfa>
    kfree(argv[i]);
    80005f5c:	ffffb097          	auipc	ra,0xffffb
    80005f60:	a9c080e7          	jalr	-1380(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f64:	04a1                	addi	s1,s1,8
    80005f66:	ff3499e3          	bne	s1,s3,80005f58 <sys_exec+0xe4>
    80005f6a:	a011                	j	80005f6e <sys_exec+0xfa>
  return -1;
    80005f6c:	597d                	li	s2,-1
}
    80005f6e:	854a                	mv	a0,s2
    80005f70:	60be                	ld	ra,456(sp)
    80005f72:	641e                	ld	s0,448(sp)
    80005f74:	74fa                	ld	s1,440(sp)
    80005f76:	795a                	ld	s2,432(sp)
    80005f78:	79ba                	ld	s3,424(sp)
    80005f7a:	7a1a                	ld	s4,416(sp)
    80005f7c:	6afa                	ld	s5,408(sp)
    80005f7e:	6179                	addi	sp,sp,464
    80005f80:	8082                	ret

0000000080005f82 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f82:	7139                	addi	sp,sp,-64
    80005f84:	fc06                	sd	ra,56(sp)
    80005f86:	f822                	sd	s0,48(sp)
    80005f88:	f426                	sd	s1,40(sp)
    80005f8a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f8c:	ffffc097          	auipc	ra,0xffffc
    80005f90:	d78080e7          	jalr	-648(ra) # 80001d04 <myproc>
    80005f94:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f96:	fd840593          	addi	a1,s0,-40
    80005f9a:	4501                	li	a0,0
    80005f9c:	ffffd097          	auipc	ra,0xffffd
    80005fa0:	0f4080e7          	jalr	244(ra) # 80003090 <argaddr>
    return -1;
    80005fa4:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005fa6:	0e054063          	bltz	a0,80006086 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005faa:	fc840593          	addi	a1,s0,-56
    80005fae:	fd040513          	addi	a0,s0,-48
    80005fb2:	fffff097          	auipc	ra,0xfffff
    80005fb6:	dfc080e7          	jalr	-516(ra) # 80004dae <pipealloc>
    return -1;
    80005fba:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005fbc:	0c054563          	bltz	a0,80006086 <sys_pipe+0x104>
  fd0 = -1;
    80005fc0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005fc4:	fd043503          	ld	a0,-48(s0)
    80005fc8:	fffff097          	auipc	ra,0xfffff
    80005fcc:	508080e7          	jalr	1288(ra) # 800054d0 <fdalloc>
    80005fd0:	fca42223          	sw	a0,-60(s0)
    80005fd4:	08054c63          	bltz	a0,8000606c <sys_pipe+0xea>
    80005fd8:	fc843503          	ld	a0,-56(s0)
    80005fdc:	fffff097          	auipc	ra,0xfffff
    80005fe0:	4f4080e7          	jalr	1268(ra) # 800054d0 <fdalloc>
    80005fe4:	fca42023          	sw	a0,-64(s0)
    80005fe8:	06054863          	bltz	a0,80006058 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fec:	4691                	li	a3,4
    80005fee:	fc440613          	addi	a2,s0,-60
    80005ff2:	fd843583          	ld	a1,-40(s0)
    80005ff6:	68a8                	ld	a0,80(s1)
    80005ff8:	ffffb097          	auipc	ra,0xffffb
    80005ffc:	67a080e7          	jalr	1658(ra) # 80001672 <copyout>
    80006000:	02054063          	bltz	a0,80006020 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006004:	4691                	li	a3,4
    80006006:	fc040613          	addi	a2,s0,-64
    8000600a:	fd843583          	ld	a1,-40(s0)
    8000600e:	0591                	addi	a1,a1,4
    80006010:	68a8                	ld	a0,80(s1)
    80006012:	ffffb097          	auipc	ra,0xffffb
    80006016:	660080e7          	jalr	1632(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000601a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000601c:	06055563          	bgez	a0,80006086 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006020:	fc442783          	lw	a5,-60(s0)
    80006024:	07e9                	addi	a5,a5,26
    80006026:	078e                	slli	a5,a5,0x3
    80006028:	97a6                	add	a5,a5,s1
    8000602a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000602e:	fc042503          	lw	a0,-64(s0)
    80006032:	0569                	addi	a0,a0,26
    80006034:	050e                	slli	a0,a0,0x3
    80006036:	9526                	add	a0,a0,s1
    80006038:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000603c:	fd043503          	ld	a0,-48(s0)
    80006040:	fffff097          	auipc	ra,0xfffff
    80006044:	a3e080e7          	jalr	-1474(ra) # 80004a7e <fileclose>
    fileclose(wf);
    80006048:	fc843503          	ld	a0,-56(s0)
    8000604c:	fffff097          	auipc	ra,0xfffff
    80006050:	a32080e7          	jalr	-1486(ra) # 80004a7e <fileclose>
    return -1;
    80006054:	57fd                	li	a5,-1
    80006056:	a805                	j	80006086 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006058:	fc442783          	lw	a5,-60(s0)
    8000605c:	0007c863          	bltz	a5,8000606c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006060:	01a78513          	addi	a0,a5,26
    80006064:	050e                	slli	a0,a0,0x3
    80006066:	9526                	add	a0,a0,s1
    80006068:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000606c:	fd043503          	ld	a0,-48(s0)
    80006070:	fffff097          	auipc	ra,0xfffff
    80006074:	a0e080e7          	jalr	-1522(ra) # 80004a7e <fileclose>
    fileclose(wf);
    80006078:	fc843503          	ld	a0,-56(s0)
    8000607c:	fffff097          	auipc	ra,0xfffff
    80006080:	a02080e7          	jalr	-1534(ra) # 80004a7e <fileclose>
    return -1;
    80006084:	57fd                	li	a5,-1
}
    80006086:	853e                	mv	a0,a5
    80006088:	70e2                	ld	ra,56(sp)
    8000608a:	7442                	ld	s0,48(sp)
    8000608c:	74a2                	ld	s1,40(sp)
    8000608e:	6121                	addi	sp,sp,64
    80006090:	8082                	ret
	...

00000000800060a0 <kernelvec>:
    800060a0:	7111                	addi	sp,sp,-256
    800060a2:	e006                	sd	ra,0(sp)
    800060a4:	e40a                	sd	sp,8(sp)
    800060a6:	e80e                	sd	gp,16(sp)
    800060a8:	ec12                	sd	tp,24(sp)
    800060aa:	f016                	sd	t0,32(sp)
    800060ac:	f41a                	sd	t1,40(sp)
    800060ae:	f81e                	sd	t2,48(sp)
    800060b0:	fc22                	sd	s0,56(sp)
    800060b2:	e0a6                	sd	s1,64(sp)
    800060b4:	e4aa                	sd	a0,72(sp)
    800060b6:	e8ae                	sd	a1,80(sp)
    800060b8:	ecb2                	sd	a2,88(sp)
    800060ba:	f0b6                	sd	a3,96(sp)
    800060bc:	f4ba                	sd	a4,104(sp)
    800060be:	f8be                	sd	a5,112(sp)
    800060c0:	fcc2                	sd	a6,120(sp)
    800060c2:	e146                	sd	a7,128(sp)
    800060c4:	e54a                	sd	s2,136(sp)
    800060c6:	e94e                	sd	s3,144(sp)
    800060c8:	ed52                	sd	s4,152(sp)
    800060ca:	f156                	sd	s5,160(sp)
    800060cc:	f55a                	sd	s6,168(sp)
    800060ce:	f95e                	sd	s7,176(sp)
    800060d0:	fd62                	sd	s8,184(sp)
    800060d2:	e1e6                	sd	s9,192(sp)
    800060d4:	e5ea                	sd	s10,200(sp)
    800060d6:	e9ee                	sd	s11,208(sp)
    800060d8:	edf2                	sd	t3,216(sp)
    800060da:	f1f6                	sd	t4,224(sp)
    800060dc:	f5fa                	sd	t5,232(sp)
    800060de:	f9fe                	sd	t6,240(sp)
    800060e0:	dc1fc0ef          	jal	ra,80002ea0 <kerneltrap>
    800060e4:	6082                	ld	ra,0(sp)
    800060e6:	6122                	ld	sp,8(sp)
    800060e8:	61c2                	ld	gp,16(sp)
    800060ea:	7282                	ld	t0,32(sp)
    800060ec:	7322                	ld	t1,40(sp)
    800060ee:	73c2                	ld	t2,48(sp)
    800060f0:	7462                	ld	s0,56(sp)
    800060f2:	6486                	ld	s1,64(sp)
    800060f4:	6526                	ld	a0,72(sp)
    800060f6:	65c6                	ld	a1,80(sp)
    800060f8:	6666                	ld	a2,88(sp)
    800060fa:	7686                	ld	a3,96(sp)
    800060fc:	7726                	ld	a4,104(sp)
    800060fe:	77c6                	ld	a5,112(sp)
    80006100:	7866                	ld	a6,120(sp)
    80006102:	688a                	ld	a7,128(sp)
    80006104:	692a                	ld	s2,136(sp)
    80006106:	69ca                	ld	s3,144(sp)
    80006108:	6a6a                	ld	s4,152(sp)
    8000610a:	7a8a                	ld	s5,160(sp)
    8000610c:	7b2a                	ld	s6,168(sp)
    8000610e:	7bca                	ld	s7,176(sp)
    80006110:	7c6a                	ld	s8,184(sp)
    80006112:	6c8e                	ld	s9,192(sp)
    80006114:	6d2e                	ld	s10,200(sp)
    80006116:	6dce                	ld	s11,208(sp)
    80006118:	6e6e                	ld	t3,216(sp)
    8000611a:	7e8e                	ld	t4,224(sp)
    8000611c:	7f2e                	ld	t5,232(sp)
    8000611e:	7fce                	ld	t6,240(sp)
    80006120:	6111                	addi	sp,sp,256
    80006122:	10200073          	sret
    80006126:	00000013          	nop
    8000612a:	00000013          	nop
    8000612e:	0001                	nop

0000000080006130 <timervec>:
    80006130:	34051573          	csrrw	a0,mscratch,a0
    80006134:	e10c                	sd	a1,0(a0)
    80006136:	e510                	sd	a2,8(a0)
    80006138:	e914                	sd	a3,16(a0)
    8000613a:	6d0c                	ld	a1,24(a0)
    8000613c:	7110                	ld	a2,32(a0)
    8000613e:	6194                	ld	a3,0(a1)
    80006140:	96b2                	add	a3,a3,a2
    80006142:	e194                	sd	a3,0(a1)
    80006144:	4589                	li	a1,2
    80006146:	14459073          	csrw	sip,a1
    8000614a:	6914                	ld	a3,16(a0)
    8000614c:	6510                	ld	a2,8(a0)
    8000614e:	610c                	ld	a1,0(a0)
    80006150:	34051573          	csrrw	a0,mscratch,a0
    80006154:	30200073          	mret
	...

000000008000615a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000615a:	1141                	addi	sp,sp,-16
    8000615c:	e422                	sd	s0,8(sp)
    8000615e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006160:	0c0007b7          	lui	a5,0xc000
    80006164:	4705                	li	a4,1
    80006166:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006168:	c3d8                	sw	a4,4(a5)
}
    8000616a:	6422                	ld	s0,8(sp)
    8000616c:	0141                	addi	sp,sp,16
    8000616e:	8082                	ret

0000000080006170 <plicinithart>:

void
plicinithart(void)
{
    80006170:	1141                	addi	sp,sp,-16
    80006172:	e406                	sd	ra,8(sp)
    80006174:	e022                	sd	s0,0(sp)
    80006176:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006178:	ffffc097          	auipc	ra,0xffffc
    8000617c:	b5a080e7          	jalr	-1190(ra) # 80001cd2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006180:	0085171b          	slliw	a4,a0,0x8
    80006184:	0c0027b7          	lui	a5,0xc002
    80006188:	97ba                	add	a5,a5,a4
    8000618a:	40200713          	li	a4,1026
    8000618e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006192:	00d5151b          	slliw	a0,a0,0xd
    80006196:	0c2017b7          	lui	a5,0xc201
    8000619a:	953e                	add	a0,a0,a5
    8000619c:	00052023          	sw	zero,0(a0)
}
    800061a0:	60a2                	ld	ra,8(sp)
    800061a2:	6402                	ld	s0,0(sp)
    800061a4:	0141                	addi	sp,sp,16
    800061a6:	8082                	ret

00000000800061a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800061a8:	1141                	addi	sp,sp,-16
    800061aa:	e406                	sd	ra,8(sp)
    800061ac:	e022                	sd	s0,0(sp)
    800061ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061b0:	ffffc097          	auipc	ra,0xffffc
    800061b4:	b22080e7          	jalr	-1246(ra) # 80001cd2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800061b8:	00d5179b          	slliw	a5,a0,0xd
    800061bc:	0c201537          	lui	a0,0xc201
    800061c0:	953e                	add	a0,a0,a5
  return irq;
}
    800061c2:	4148                	lw	a0,4(a0)
    800061c4:	60a2                	ld	ra,8(sp)
    800061c6:	6402                	ld	s0,0(sp)
    800061c8:	0141                	addi	sp,sp,16
    800061ca:	8082                	ret

00000000800061cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061cc:	1101                	addi	sp,sp,-32
    800061ce:	ec06                	sd	ra,24(sp)
    800061d0:	e822                	sd	s0,16(sp)
    800061d2:	e426                	sd	s1,8(sp)
    800061d4:	1000                	addi	s0,sp,32
    800061d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800061d8:	ffffc097          	auipc	ra,0xffffc
    800061dc:	afa080e7          	jalr	-1286(ra) # 80001cd2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800061e0:	00d5151b          	slliw	a0,a0,0xd
    800061e4:	0c2017b7          	lui	a5,0xc201
    800061e8:	97aa                	add	a5,a5,a0
    800061ea:	c3c4                	sw	s1,4(a5)
}
    800061ec:	60e2                	ld	ra,24(sp)
    800061ee:	6442                	ld	s0,16(sp)
    800061f0:	64a2                	ld	s1,8(sp)
    800061f2:	6105                	addi	sp,sp,32
    800061f4:	8082                	ret

00000000800061f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800061f6:	1141                	addi	sp,sp,-16
    800061f8:	e406                	sd	ra,8(sp)
    800061fa:	e022                	sd	s0,0(sp)
    800061fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800061fe:	479d                	li	a5,7
    80006200:	06a7c963          	blt	a5,a0,80006272 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006204:	0001d797          	auipc	a5,0x1d
    80006208:	dfc78793          	addi	a5,a5,-516 # 80023000 <disk>
    8000620c:	00a78733          	add	a4,a5,a0
    80006210:	6789                	lui	a5,0x2
    80006212:	97ba                	add	a5,a5,a4
    80006214:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006218:	e7ad                	bnez	a5,80006282 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000621a:	00451793          	slli	a5,a0,0x4
    8000621e:	0001f717          	auipc	a4,0x1f
    80006222:	de270713          	addi	a4,a4,-542 # 80025000 <disk+0x2000>
    80006226:	6314                	ld	a3,0(a4)
    80006228:	96be                	add	a3,a3,a5
    8000622a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000622e:	6314                	ld	a3,0(a4)
    80006230:	96be                	add	a3,a3,a5
    80006232:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006236:	6314                	ld	a3,0(a4)
    80006238:	96be                	add	a3,a3,a5
    8000623a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000623e:	6318                	ld	a4,0(a4)
    80006240:	97ba                	add	a5,a5,a4
    80006242:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006246:	0001d797          	auipc	a5,0x1d
    8000624a:	dba78793          	addi	a5,a5,-582 # 80023000 <disk>
    8000624e:	97aa                	add	a5,a5,a0
    80006250:	6509                	lui	a0,0x2
    80006252:	953e                	add	a0,a0,a5
    80006254:	4785                	li	a5,1
    80006256:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000625a:	0001f517          	auipc	a0,0x1f
    8000625e:	dbe50513          	addi	a0,a0,-578 # 80025018 <disk+0x2018>
    80006262:	ffffc097          	auipc	ra,0xffffc
    80006266:	43e080e7          	jalr	1086(ra) # 800026a0 <wakeup>
}
    8000626a:	60a2                	ld	ra,8(sp)
    8000626c:	6402                	ld	s0,0(sp)
    8000626e:	0141                	addi	sp,sp,16
    80006270:	8082                	ret
    panic("free_desc 1");
    80006272:	00002517          	auipc	a0,0x2
    80006276:	57e50513          	addi	a0,a0,1406 # 800087f0 <syscalls+0x320>
    8000627a:	ffffa097          	auipc	ra,0xffffa
    8000627e:	2c4080e7          	jalr	708(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006282:	00002517          	auipc	a0,0x2
    80006286:	57e50513          	addi	a0,a0,1406 # 80008800 <syscalls+0x330>
    8000628a:	ffffa097          	auipc	ra,0xffffa
    8000628e:	2b4080e7          	jalr	692(ra) # 8000053e <panic>

0000000080006292 <virtio_disk_init>:
{
    80006292:	1101                	addi	sp,sp,-32
    80006294:	ec06                	sd	ra,24(sp)
    80006296:	e822                	sd	s0,16(sp)
    80006298:	e426                	sd	s1,8(sp)
    8000629a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000629c:	00002597          	auipc	a1,0x2
    800062a0:	57458593          	addi	a1,a1,1396 # 80008810 <syscalls+0x340>
    800062a4:	0001f517          	auipc	a0,0x1f
    800062a8:	e8450513          	addi	a0,a0,-380 # 80025128 <disk+0x2128>
    800062ac:	ffffb097          	auipc	ra,0xffffb
    800062b0:	8a8080e7          	jalr	-1880(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062b4:	100017b7          	lui	a5,0x10001
    800062b8:	4398                	lw	a4,0(a5)
    800062ba:	2701                	sext.w	a4,a4
    800062bc:	747277b7          	lui	a5,0x74727
    800062c0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800062c4:	0ef71163          	bne	a4,a5,800063a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062c8:	100017b7          	lui	a5,0x10001
    800062cc:	43dc                	lw	a5,4(a5)
    800062ce:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062d0:	4705                	li	a4,1
    800062d2:	0ce79a63          	bne	a5,a4,800063a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062d6:	100017b7          	lui	a5,0x10001
    800062da:	479c                	lw	a5,8(a5)
    800062dc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062de:	4709                	li	a4,2
    800062e0:	0ce79363          	bne	a5,a4,800063a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800062e4:	100017b7          	lui	a5,0x10001
    800062e8:	47d8                	lw	a4,12(a5)
    800062ea:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062ec:	554d47b7          	lui	a5,0x554d4
    800062f0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800062f4:	0af71963          	bne	a4,a5,800063a6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062f8:	100017b7          	lui	a5,0x10001
    800062fc:	4705                	li	a4,1
    800062fe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006300:	470d                	li	a4,3
    80006302:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006304:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006306:	c7ffe737          	lui	a4,0xc7ffe
    8000630a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000630e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006310:	2701                	sext.w	a4,a4
    80006312:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006314:	472d                	li	a4,11
    80006316:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006318:	473d                	li	a4,15
    8000631a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000631c:	6705                	lui	a4,0x1
    8000631e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006320:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006324:	5bdc                	lw	a5,52(a5)
    80006326:	2781                	sext.w	a5,a5
  if(max == 0)
    80006328:	c7d9                	beqz	a5,800063b6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000632a:	471d                	li	a4,7
    8000632c:	08f77d63          	bgeu	a4,a5,800063c6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006330:	100014b7          	lui	s1,0x10001
    80006334:	47a1                	li	a5,8
    80006336:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006338:	6609                	lui	a2,0x2
    8000633a:	4581                	li	a1,0
    8000633c:	0001d517          	auipc	a0,0x1d
    80006340:	cc450513          	addi	a0,a0,-828 # 80023000 <disk>
    80006344:	ffffb097          	auipc	ra,0xffffb
    80006348:	99c080e7          	jalr	-1636(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000634c:	0001d717          	auipc	a4,0x1d
    80006350:	cb470713          	addi	a4,a4,-844 # 80023000 <disk>
    80006354:	00c75793          	srli	a5,a4,0xc
    80006358:	2781                	sext.w	a5,a5
    8000635a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000635c:	0001f797          	auipc	a5,0x1f
    80006360:	ca478793          	addi	a5,a5,-860 # 80025000 <disk+0x2000>
    80006364:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006366:	0001d717          	auipc	a4,0x1d
    8000636a:	d1a70713          	addi	a4,a4,-742 # 80023080 <disk+0x80>
    8000636e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006370:	0001e717          	auipc	a4,0x1e
    80006374:	c9070713          	addi	a4,a4,-880 # 80024000 <disk+0x1000>
    80006378:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000637a:	4705                	li	a4,1
    8000637c:	00e78c23          	sb	a4,24(a5)
    80006380:	00e78ca3          	sb	a4,25(a5)
    80006384:	00e78d23          	sb	a4,26(a5)
    80006388:	00e78da3          	sb	a4,27(a5)
    8000638c:	00e78e23          	sb	a4,28(a5)
    80006390:	00e78ea3          	sb	a4,29(a5)
    80006394:	00e78f23          	sb	a4,30(a5)
    80006398:	00e78fa3          	sb	a4,31(a5)
}
    8000639c:	60e2                	ld	ra,24(sp)
    8000639e:	6442                	ld	s0,16(sp)
    800063a0:	64a2                	ld	s1,8(sp)
    800063a2:	6105                	addi	sp,sp,32
    800063a4:	8082                	ret
    panic("could not find virtio disk");
    800063a6:	00002517          	auipc	a0,0x2
    800063aa:	47a50513          	addi	a0,a0,1146 # 80008820 <syscalls+0x350>
    800063ae:	ffffa097          	auipc	ra,0xffffa
    800063b2:	190080e7          	jalr	400(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800063b6:	00002517          	auipc	a0,0x2
    800063ba:	48a50513          	addi	a0,a0,1162 # 80008840 <syscalls+0x370>
    800063be:	ffffa097          	auipc	ra,0xffffa
    800063c2:	180080e7          	jalr	384(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800063c6:	00002517          	auipc	a0,0x2
    800063ca:	49a50513          	addi	a0,a0,1178 # 80008860 <syscalls+0x390>
    800063ce:	ffffa097          	auipc	ra,0xffffa
    800063d2:	170080e7          	jalr	368(ra) # 8000053e <panic>

00000000800063d6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063d6:	7159                	addi	sp,sp,-112
    800063d8:	f486                	sd	ra,104(sp)
    800063da:	f0a2                	sd	s0,96(sp)
    800063dc:	eca6                	sd	s1,88(sp)
    800063de:	e8ca                	sd	s2,80(sp)
    800063e0:	e4ce                	sd	s3,72(sp)
    800063e2:	e0d2                	sd	s4,64(sp)
    800063e4:	fc56                	sd	s5,56(sp)
    800063e6:	f85a                	sd	s6,48(sp)
    800063e8:	f45e                	sd	s7,40(sp)
    800063ea:	f062                	sd	s8,32(sp)
    800063ec:	ec66                	sd	s9,24(sp)
    800063ee:	e86a                	sd	s10,16(sp)
    800063f0:	1880                	addi	s0,sp,112
    800063f2:	892a                	mv	s2,a0
    800063f4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800063f6:	00c52c83          	lw	s9,12(a0)
    800063fa:	001c9c9b          	slliw	s9,s9,0x1
    800063fe:	1c82                	slli	s9,s9,0x20
    80006400:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006404:	0001f517          	auipc	a0,0x1f
    80006408:	d2450513          	addi	a0,a0,-732 # 80025128 <disk+0x2128>
    8000640c:	ffffa097          	auipc	ra,0xffffa
    80006410:	7d8080e7          	jalr	2008(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006414:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006416:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006418:	0001db97          	auipc	s7,0x1d
    8000641c:	be8b8b93          	addi	s7,s7,-1048 # 80023000 <disk>
    80006420:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006422:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006424:	8a4e                	mv	s4,s3
    80006426:	a051                	j	800064aa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006428:	00fb86b3          	add	a3,s7,a5
    8000642c:	96da                	add	a3,a3,s6
    8000642e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006432:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006434:	0207c563          	bltz	a5,8000645e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006438:	2485                	addiw	s1,s1,1
    8000643a:	0711                	addi	a4,a4,4
    8000643c:	25548063          	beq	s1,s5,8000667c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006440:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006442:	0001f697          	auipc	a3,0x1f
    80006446:	bd668693          	addi	a3,a3,-1066 # 80025018 <disk+0x2018>
    8000644a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000644c:	0006c583          	lbu	a1,0(a3)
    80006450:	fde1                	bnez	a1,80006428 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006452:	2785                	addiw	a5,a5,1
    80006454:	0685                	addi	a3,a3,1
    80006456:	ff879be3          	bne	a5,s8,8000644c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000645a:	57fd                	li	a5,-1
    8000645c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000645e:	02905a63          	blez	s1,80006492 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006462:	f9042503          	lw	a0,-112(s0)
    80006466:	00000097          	auipc	ra,0x0
    8000646a:	d90080e7          	jalr	-624(ra) # 800061f6 <free_desc>
      for(int j = 0; j < i; j++)
    8000646e:	4785                	li	a5,1
    80006470:	0297d163          	bge	a5,s1,80006492 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006474:	f9442503          	lw	a0,-108(s0)
    80006478:	00000097          	auipc	ra,0x0
    8000647c:	d7e080e7          	jalr	-642(ra) # 800061f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006480:	4789                	li	a5,2
    80006482:	0097d863          	bge	a5,s1,80006492 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006486:	f9842503          	lw	a0,-104(s0)
    8000648a:	00000097          	auipc	ra,0x0
    8000648e:	d6c080e7          	jalr	-660(ra) # 800061f6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006492:	0001f597          	auipc	a1,0x1f
    80006496:	c9658593          	addi	a1,a1,-874 # 80025128 <disk+0x2128>
    8000649a:	0001f517          	auipc	a0,0x1f
    8000649e:	b7e50513          	addi	a0,a0,-1154 # 80025018 <disk+0x2018>
    800064a2:	ffffc097          	auipc	ra,0xffffc
    800064a6:	060080e7          	jalr	96(ra) # 80002502 <sleep>
  for(int i = 0; i < 3; i++){
    800064aa:	f9040713          	addi	a4,s0,-112
    800064ae:	84ce                	mv	s1,s3
    800064b0:	bf41                	j	80006440 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800064b2:	20058713          	addi	a4,a1,512
    800064b6:	00471693          	slli	a3,a4,0x4
    800064ba:	0001d717          	auipc	a4,0x1d
    800064be:	b4670713          	addi	a4,a4,-1210 # 80023000 <disk>
    800064c2:	9736                	add	a4,a4,a3
    800064c4:	4685                	li	a3,1
    800064c6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064ca:	20058713          	addi	a4,a1,512
    800064ce:	00471693          	slli	a3,a4,0x4
    800064d2:	0001d717          	auipc	a4,0x1d
    800064d6:	b2e70713          	addi	a4,a4,-1234 # 80023000 <disk>
    800064da:	9736                	add	a4,a4,a3
    800064dc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800064e0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800064e4:	7679                	lui	a2,0xffffe
    800064e6:	963e                	add	a2,a2,a5
    800064e8:	0001f697          	auipc	a3,0x1f
    800064ec:	b1868693          	addi	a3,a3,-1256 # 80025000 <disk+0x2000>
    800064f0:	6298                	ld	a4,0(a3)
    800064f2:	9732                	add	a4,a4,a2
    800064f4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800064f6:	6298                	ld	a4,0(a3)
    800064f8:	9732                	add	a4,a4,a2
    800064fa:	4541                	li	a0,16
    800064fc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064fe:	6298                	ld	a4,0(a3)
    80006500:	9732                	add	a4,a4,a2
    80006502:	4505                	li	a0,1
    80006504:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006508:	f9442703          	lw	a4,-108(s0)
    8000650c:	6288                	ld	a0,0(a3)
    8000650e:	962a                	add	a2,a2,a0
    80006510:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006514:	0712                	slli	a4,a4,0x4
    80006516:	6290                	ld	a2,0(a3)
    80006518:	963a                	add	a2,a2,a4
    8000651a:	05890513          	addi	a0,s2,88
    8000651e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006520:	6294                	ld	a3,0(a3)
    80006522:	96ba                	add	a3,a3,a4
    80006524:	40000613          	li	a2,1024
    80006528:	c690                	sw	a2,8(a3)
  if(write)
    8000652a:	140d0063          	beqz	s10,8000666a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000652e:	0001f697          	auipc	a3,0x1f
    80006532:	ad26b683          	ld	a3,-1326(a3) # 80025000 <disk+0x2000>
    80006536:	96ba                	add	a3,a3,a4
    80006538:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000653c:	0001d817          	auipc	a6,0x1d
    80006540:	ac480813          	addi	a6,a6,-1340 # 80023000 <disk>
    80006544:	0001f517          	auipc	a0,0x1f
    80006548:	abc50513          	addi	a0,a0,-1348 # 80025000 <disk+0x2000>
    8000654c:	6114                	ld	a3,0(a0)
    8000654e:	96ba                	add	a3,a3,a4
    80006550:	00c6d603          	lhu	a2,12(a3)
    80006554:	00166613          	ori	a2,a2,1
    80006558:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000655c:	f9842683          	lw	a3,-104(s0)
    80006560:	6110                	ld	a2,0(a0)
    80006562:	9732                	add	a4,a4,a2
    80006564:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006568:	20058613          	addi	a2,a1,512
    8000656c:	0612                	slli	a2,a2,0x4
    8000656e:	9642                	add	a2,a2,a6
    80006570:	577d                	li	a4,-1
    80006572:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006576:	00469713          	slli	a4,a3,0x4
    8000657a:	6114                	ld	a3,0(a0)
    8000657c:	96ba                	add	a3,a3,a4
    8000657e:	03078793          	addi	a5,a5,48
    80006582:	97c2                	add	a5,a5,a6
    80006584:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006586:	611c                	ld	a5,0(a0)
    80006588:	97ba                	add	a5,a5,a4
    8000658a:	4685                	li	a3,1
    8000658c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000658e:	611c                	ld	a5,0(a0)
    80006590:	97ba                	add	a5,a5,a4
    80006592:	4809                	li	a6,2
    80006594:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006598:	611c                	ld	a5,0(a0)
    8000659a:	973e                	add	a4,a4,a5
    8000659c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800065a0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800065a4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800065a8:	6518                	ld	a4,8(a0)
    800065aa:	00275783          	lhu	a5,2(a4)
    800065ae:	8b9d                	andi	a5,a5,7
    800065b0:	0786                	slli	a5,a5,0x1
    800065b2:	97ba                	add	a5,a5,a4
    800065b4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800065b8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065bc:	6518                	ld	a4,8(a0)
    800065be:	00275783          	lhu	a5,2(a4)
    800065c2:	2785                	addiw	a5,a5,1
    800065c4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065c8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065cc:	100017b7          	lui	a5,0x10001
    800065d0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065d4:	00492703          	lw	a4,4(s2)
    800065d8:	4785                	li	a5,1
    800065da:	02f71163          	bne	a4,a5,800065fc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800065de:	0001f997          	auipc	s3,0x1f
    800065e2:	b4a98993          	addi	s3,s3,-1206 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800065e6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800065e8:	85ce                	mv	a1,s3
    800065ea:	854a                	mv	a0,s2
    800065ec:	ffffc097          	auipc	ra,0xffffc
    800065f0:	f16080e7          	jalr	-234(ra) # 80002502 <sleep>
  while(b->disk == 1) {
    800065f4:	00492783          	lw	a5,4(s2)
    800065f8:	fe9788e3          	beq	a5,s1,800065e8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800065fc:	f9042903          	lw	s2,-112(s0)
    80006600:	20090793          	addi	a5,s2,512
    80006604:	00479713          	slli	a4,a5,0x4
    80006608:	0001d797          	auipc	a5,0x1d
    8000660c:	9f878793          	addi	a5,a5,-1544 # 80023000 <disk>
    80006610:	97ba                	add	a5,a5,a4
    80006612:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006616:	0001f997          	auipc	s3,0x1f
    8000661a:	9ea98993          	addi	s3,s3,-1558 # 80025000 <disk+0x2000>
    8000661e:	00491713          	slli	a4,s2,0x4
    80006622:	0009b783          	ld	a5,0(s3)
    80006626:	97ba                	add	a5,a5,a4
    80006628:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000662c:	854a                	mv	a0,s2
    8000662e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006632:	00000097          	auipc	ra,0x0
    80006636:	bc4080e7          	jalr	-1084(ra) # 800061f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000663a:	8885                	andi	s1,s1,1
    8000663c:	f0ed                	bnez	s1,8000661e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000663e:	0001f517          	auipc	a0,0x1f
    80006642:	aea50513          	addi	a0,a0,-1302 # 80025128 <disk+0x2128>
    80006646:	ffffa097          	auipc	ra,0xffffa
    8000664a:	652080e7          	jalr	1618(ra) # 80000c98 <release>
}
    8000664e:	70a6                	ld	ra,104(sp)
    80006650:	7406                	ld	s0,96(sp)
    80006652:	64e6                	ld	s1,88(sp)
    80006654:	6946                	ld	s2,80(sp)
    80006656:	69a6                	ld	s3,72(sp)
    80006658:	6a06                	ld	s4,64(sp)
    8000665a:	7ae2                	ld	s5,56(sp)
    8000665c:	7b42                	ld	s6,48(sp)
    8000665e:	7ba2                	ld	s7,40(sp)
    80006660:	7c02                	ld	s8,32(sp)
    80006662:	6ce2                	ld	s9,24(sp)
    80006664:	6d42                	ld	s10,16(sp)
    80006666:	6165                	addi	sp,sp,112
    80006668:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000666a:	0001f697          	auipc	a3,0x1f
    8000666e:	9966b683          	ld	a3,-1642(a3) # 80025000 <disk+0x2000>
    80006672:	96ba                	add	a3,a3,a4
    80006674:	4609                	li	a2,2
    80006676:	00c69623          	sh	a2,12(a3)
    8000667a:	b5c9                	j	8000653c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000667c:	f9042583          	lw	a1,-112(s0)
    80006680:	20058793          	addi	a5,a1,512
    80006684:	0792                	slli	a5,a5,0x4
    80006686:	0001d517          	auipc	a0,0x1d
    8000668a:	a2250513          	addi	a0,a0,-1502 # 800230a8 <disk+0xa8>
    8000668e:	953e                	add	a0,a0,a5
  if(write)
    80006690:	e20d11e3          	bnez	s10,800064b2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006694:	20058713          	addi	a4,a1,512
    80006698:	00471693          	slli	a3,a4,0x4
    8000669c:	0001d717          	auipc	a4,0x1d
    800066a0:	96470713          	addi	a4,a4,-1692 # 80023000 <disk>
    800066a4:	9736                	add	a4,a4,a3
    800066a6:	0a072423          	sw	zero,168(a4)
    800066aa:	b505                	j	800064ca <virtio_disk_rw+0xf4>

00000000800066ac <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800066ac:	1101                	addi	sp,sp,-32
    800066ae:	ec06                	sd	ra,24(sp)
    800066b0:	e822                	sd	s0,16(sp)
    800066b2:	e426                	sd	s1,8(sp)
    800066b4:	e04a                	sd	s2,0(sp)
    800066b6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800066b8:	0001f517          	auipc	a0,0x1f
    800066bc:	a7050513          	addi	a0,a0,-1424 # 80025128 <disk+0x2128>
    800066c0:	ffffa097          	auipc	ra,0xffffa
    800066c4:	524080e7          	jalr	1316(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800066c8:	10001737          	lui	a4,0x10001
    800066cc:	533c                	lw	a5,96(a4)
    800066ce:	8b8d                	andi	a5,a5,3
    800066d0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800066d2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800066d6:	0001f797          	auipc	a5,0x1f
    800066da:	92a78793          	addi	a5,a5,-1750 # 80025000 <disk+0x2000>
    800066de:	6b94                	ld	a3,16(a5)
    800066e0:	0207d703          	lhu	a4,32(a5)
    800066e4:	0026d783          	lhu	a5,2(a3)
    800066e8:	06f70163          	beq	a4,a5,8000674a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066ec:	0001d917          	auipc	s2,0x1d
    800066f0:	91490913          	addi	s2,s2,-1772 # 80023000 <disk>
    800066f4:	0001f497          	auipc	s1,0x1f
    800066f8:	90c48493          	addi	s1,s1,-1780 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800066fc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006700:	6898                	ld	a4,16(s1)
    80006702:	0204d783          	lhu	a5,32(s1)
    80006706:	8b9d                	andi	a5,a5,7
    80006708:	078e                	slli	a5,a5,0x3
    8000670a:	97ba                	add	a5,a5,a4
    8000670c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000670e:	20078713          	addi	a4,a5,512
    80006712:	0712                	slli	a4,a4,0x4
    80006714:	974a                	add	a4,a4,s2
    80006716:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000671a:	e731                	bnez	a4,80006766 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000671c:	20078793          	addi	a5,a5,512
    80006720:	0792                	slli	a5,a5,0x4
    80006722:	97ca                	add	a5,a5,s2
    80006724:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006726:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000672a:	ffffc097          	auipc	ra,0xffffc
    8000672e:	f76080e7          	jalr	-138(ra) # 800026a0 <wakeup>

    disk.used_idx += 1;
    80006732:	0204d783          	lhu	a5,32(s1)
    80006736:	2785                	addiw	a5,a5,1
    80006738:	17c2                	slli	a5,a5,0x30
    8000673a:	93c1                	srli	a5,a5,0x30
    8000673c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006740:	6898                	ld	a4,16(s1)
    80006742:	00275703          	lhu	a4,2(a4)
    80006746:	faf71be3          	bne	a4,a5,800066fc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000674a:	0001f517          	auipc	a0,0x1f
    8000674e:	9de50513          	addi	a0,a0,-1570 # 80025128 <disk+0x2128>
    80006752:	ffffa097          	auipc	ra,0xffffa
    80006756:	546080e7          	jalr	1350(ra) # 80000c98 <release>
}
    8000675a:	60e2                	ld	ra,24(sp)
    8000675c:	6442                	ld	s0,16(sp)
    8000675e:	64a2                	ld	s1,8(sp)
    80006760:	6902                	ld	s2,0(sp)
    80006762:	6105                	addi	sp,sp,32
    80006764:	8082                	ret
      panic("virtio_disk_intr status");
    80006766:	00002517          	auipc	a0,0x2
    8000676a:	11a50513          	addi	a0,a0,282 # 80008880 <syscalls+0x3b0>
    8000676e:	ffffa097          	auipc	ra,0xffffa
    80006772:	dd0080e7          	jalr	-560(ra) # 8000053e <panic>

0000000080006776 <cas>:
    80006776:	100522af          	lr.w	t0,(a0)
    8000677a:	00b29563          	bne	t0,a1,80006784 <fail>
    8000677e:	18c5252f          	sc.w	a0,a2,(a0)
    80006782:	8082                	ret

0000000080006784 <fail>:
    80006784:	4505                	li	a0,1
    80006786:	8082                	ret
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
