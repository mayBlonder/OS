#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include <limits.h>


int rate = 5;
int pause_flag = 0;
uint wake_up_time;
uint sleeping_processes_mean = 0;
uint running_processes_mean= 0;
uint runnable_processes_mean = 0;
int p_counter = 0;
uint program_time;
uint start_time;
int cpu_utilization;

// Ass2
int sleeping_list_head = -1;
int sleeping_list_tail = -1;
int unused_list_head = -1;
int unused_list_tail = -1;
int zombie_list_head = -1;
int zombie_list_tail = -1;


struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
// int nextcpuid = 0;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

// Ass2
extern uint64 cas( volatile void *addr, int expected, int newval);

// Ass2
int
add_proc_to_list(int tail, struct proc *p)
{
  // if (tail == p->pid)
    // return 0;
  printf("&&&&&&&&&&&&&&&adding: %d,     prev:   %d,   next:  %d\n", p->proc_ind, p->prev_proc, p->next_proc);
  int p_before = proc[tail].next_proc;
  if (cas(&proc[tail].next_proc, p_before, p->proc_ind) == 0)
  {
    p->prev_proc = tail;
    p->next_proc = -1;
    printf("&&&&&&&&&&&&&&&adding: %d,     prev:   %d,   next:  %d\n", p->proc_ind, p->prev_proc, p->next_proc);
    return 0;
  }
  return -1;
}

// Ass2
int
remove_proc_from_list(int ind)
{
  struct proc *p = &proc[ind];

  printf("######### remove cur: %d,    prev: %d, next: %d   \n", ind, p->prev_proc, p->next_proc);

  if (p->prev_proc == -1 && p->next_proc == -1)
    return 1;  // Need to change head & tail.
  
  if (p->prev_proc == -1)
    return 2;  // Need to change head.

  if (p->next_proc == -1)
    return 3;  // Need to change tail.

  int prev = proc[p->prev_proc].next_proc;
  if (cas(&proc[p->prev_proc].next_proc, prev, p->next_proc) == 0)
  {
    proc[p->next_proc].prev_proc = p->prev_proc;

    printf("######### remove cur: %d,    prev: %d, next: %d   \n", ind, p->prev_proc, p->next_proc);
    return 0;
  }
  return -1;
}

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}


// initialize the proc table at boot time.
	void
	procinit(void)
	{
	  struct proc *p;
    int i = 0;
	  
	  initlock(&pid_lock, "nextpid");
	  initlock(&wait_lock, "wait_lock");
	  for(p = proc; p < &proc[NPROC]; p++) {
	      initlock(&p->lock, "proc");
	      p->kstack = KSTACK((int) (p - proc));

        p->proc_ind = i;                               // Set index to process.
        p->prev_proc = -1;
        p->next_proc = -1;
        if (i != 0)
        {
          printf("unused");
          add_proc_to_list(unused_list_tail, p);
          if (unused_list_head == -1)
          {
            unused_list_head = p->proc_ind;
          }
            unused_list_tail = p->proc_ind;             // After adding to list, updating tail.
        }
        i ++;
      }
  struct cpu *c;
  for(c = cpus; c < &cpus[NCPU]; c++)
  {
    c->runnable_list_head = -1;
    c->runnable_list_tail = -1;
  }
}
// void
// procinit(void)
// {
//   // Added
//   program_time = 0;
//   cpu_utilization = 0;
//   start_time = ticks;
//   // int i = 0;

//   // TODO: add all to UNUSED.

//   struct proc *p;
  
//   initlock(&pid_lock, "nextpid");
//   initlock(&wait_lock, "wait_lock");

//   unused_list_head = proc->proc_ind;
//   proc->prev_proc = -1;
//   unused_list_tail = proc->proc_ind;
//   for(p = proc; p < &proc[NPROC]; p++) {
//       initlock(&p->lock, "proc");
//       p->kstack = KSTACK((int) (p - proc));

//       //Ass2
//       p->proc_ind = i;                               // Set index to process.
//       p->prev_proc = -1;
//       p->next_proc = -1;
//       if (i != 0)
//       {
//         printf("unused");
//         add_proc_to_list(unused_list_tail, p);
//          if (unused_list_head == -1)
//         {
//           unused_list_head = p->proc_ind;
//         }
//           unused_list_tail = p->proc_ind;             // After adding to list, updating tail.
//       }
//       i ++;
//   }
//   struct cpu *c;
//   for(c = cpus; c < &cpus[NCPU]; c++)
//   {
//     c->runnable_list_head = -1;
//     c->runnable_list_tail = -1;
//   }

// }

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
  int id = cpuid();
  struct cpu *c = &cpus[id];
  c->cpu_id = id;
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}


// Changed !

// int
// allocpid() {
//   int pid;
  
//   acquire(&pid_lock);
//   pid = nextpid;
//   nextpid = nextpid + 1;
//   release(&pid_lock);

//   return pid;
// }

int
allocpid() {
  int pid;
  
  pid = nextpid;
  // printf("pid: %d, nextpid: %d\n", pid, nextpid);

  if (cas(&nextpid, pid, (nextpid + 1)) == 0)
  {
    return pid;
  }
  return allocpid();
}


// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc*
allocproc(void)
{
  // TODO: choose UNUSED process.
  struct proc *p;

  // Ass2
  // printf("unused_list_head: %d\n", unused_list_head);
  if (unused_list_head > -1)
  {
    p = &proc[unused_list_head];
    acquire(&p->lock);
    printf("unused");
    int res = remove_proc_from_list(unused_list_head); 

    if (res == 1)
    {
      unused_list_head = -1;
      unused_list_tail = -1;
      printf("1 no head & tail");
    }
    if (res == 2)
    {
      unused_list_head = p->next_proc;      // Update head.
      if (proc[p->next_proc].next_proc == -1)
        unused_list_tail = p->next_proc;
      proc[p->next_proc].prev_proc = -1;    // Remove head's prev.
      printf("1 no head");
    }
    if (res == 3)
    {
      unused_list_tail = p->prev_proc;      // Update tail.
       if (proc[p->prev_proc].prev_proc == -1)
        unused_list_head = p->prev_proc;
      proc[p->prev_proc].next_proc = -1;    // Remove tail's next.
      printf("1 no tail");
    }

    p->prev_proc = -1;
    p->next_proc = -1;

    // printf("the new unused_list_head: %d\n", unused_list_head);
    goto found;
  }
  return 0;

  // for(p = proc; p < &proc[NPROC]; p++) {
  //   acquire(&p->lock);
  //   if(p->state == UNUSED) {
  //     goto found;
  //   } else {
  //     release(&p->lock);
  //   }
  // }
  // return 0;

found:
  p->pid = allocpid();

  p->state = USED;

  // added
  p->mean_ticks = 0;
  p->last_ticks = 0;
  p->paused = 0;

  p->sleeping_time = 0;
  p->running_time = 0;
  p->runnable_time = 0;


  // int i=0;


  // Allocate a trapframe page.
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    freeproc(p);
    release(&p->lock);
    // i++;
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if(p->pagetable == 0){
    freeproc(p);
    release(&p->lock);
    // i++;
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;

  // if (i == 0)
  //   release(&p->lock);
  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  // TODO: remove from ZOMBIE list and add to UNUSED.
  if(p->trapframe)
    kfree((void*)p->trapframe);
  p->trapframe = 0;
  if(p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;

  // Ass2
  printf("zombie");
  int res = remove_proc_from_list(p->proc_ind); 
  if (res == 1)
  {
    zombie_list_head = -1;
    zombie_list_tail = -1;
    printf("2 no head & tail");
  }
  if (res == 2)
  {
    zombie_list_head = p->next_proc;
    if (proc[p->next_proc].next_proc == -1)
      zombie_list_tail = p->next_proc;
    proc[p->next_proc].prev_proc = -1;
    printf("1 no head ");
  }
  if (res == 3){
    zombie_list_tail = p->prev_proc;
     if (proc[p->prev_proc].prev_proc == -1)
      zombie_list_head = p->prev_proc;
    proc[p->prev_proc].next_proc = -1;
    printf("1 no tail");
  }

  p->next_proc = -1;
  p->prev_proc = -1;

  if (unused_list_tail != -1){
    printf("unused");
    add_proc_to_list(unused_list_tail, p);
    if (unused_list_head == -1)
  {
    unused_list_head = p->proc_ind;
  }
    unused_list_tail = p->proc_ind;
  }
  else{
    unused_list_tail = unused_list_head = p->proc_ind;
  }
}

// Create a user page table for a given process,
// with no user memory, but with trampoline pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if(pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
              (uint64)trampoline, PTE_R | PTE_X) < 0){
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe just below TRAMPOLINE, for trampoline.S.
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
              (uint64)(p->trapframe), PTE_R | PTE_W) < 0){
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// od -t xC initcode
uchar initcode[] = {
  0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
  0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
  0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
  0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
  0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
  0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00
};


int
str_compare(const char *p1, const char *p2)
{
  const unsigned char *s1 = (const unsigned char *) p1;
  const unsigned char *s2 = (const unsigned char *) p2;
  unsigned char c1, c2;
  do
    {
      c1 = (unsigned char) *s1++;
      c2 = (unsigned char) *s2++;
      if (c1 == '\0')
        return c1 - c2;
    }
  while (c1 == c2);
  return c1 - c2;
}

// Set up first user process.
void
userinit(void)
{
  // TODO: add init to 1st cpu list - V
  struct proc *p;

  p = allocproc();
  initproc = p;
  
  // allocate one user page and copy init's instructions
  // and data into it.
  uvminit(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;      // user program counter
  p->trapframe->sp = PGSIZE;  // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;
  // added
  p->last_runnable_time = ticks;
  
  //Ass2
  if (mycpu()->runnable_list_head == -1)
  {
    printf("init runnable: %d            1\n", p->proc_ind);
    mycpu()->runnable_list_head = p->proc_ind;
    mycpu()->runnable_list_tail = p->proc_ind;
  }
  else
  {
    printf("runnable1");
    add_proc_to_list(mycpu()->runnable_list_tail, p);
    mycpu()->runnable_list_tail = p->proc_ind;
  }

  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint sz;
  struct proc *p = myproc();

  sz = p->sz;
  if(n > 0){
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
      return -1;
    }
  } else if(n < 0){
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void)
{

  // TODO: add to RUNNABLE list.
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if((np = allocproc()) == 0){
    return -1;
  }

  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  // added
  np->last_runnable_time = ticks;

  // Ass2
  if (mycpu()->runnable_list_head == -1)
  {
    printf("init runnable %d                 2\n", p->proc_ind);
    mycpu()->runnable_list_head = np->proc_ind;
    mycpu()->runnable_list_tail = np->proc_ind;
  }
  else
  {
    printf("runnable2");
    add_proc_to_list(mycpu()->runnable_list_tail, np);
    mycpu()->runnable_list_tail = np->proc_ind;
  }

  release(&np->lock);

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void
reparent(struct proc *p)
{
  struct proc *pp;

  for(pp = proc; pp < &proc[NPROC]; pp++){
    if(pp->parent == p){
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status)
{
  // TODO: remove from RUNNABLE list and add to ZOMBIE
  struct proc *p = myproc();

  if(p == initproc)
    panic("init exiting");

  // Close all open files.
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  

  if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) 
  {
    // Update
    sleeping_processes_mean = ((sleeping_processes_mean * p_counter)+ p->sleeping_time)/(p_counter+1);
    running_processes_mean = ((running_processes_mean * p_counter)+ p->running_time)/(p_counter+1);
    runnable_processes_mean = ((runnable_processes_mean * p_counter)+ p->runnable_time)/(p_counter+1);
    p_counter += 1;
    program_time += p->running_time;
    cpu_utilization = (program_time* 100) / (ticks - start_time) ;
  }
  //

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);
  
  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;

  // added
  p->running_time += ticks - p->start_running_time;

  //Ass2 
  printf("runnable ");
  int res = remove_proc_from_list(p->proc_ind); 
  if (res == 1)
  {
    mycpu()->runnable_list_head = -1;
    mycpu()->runnable_list_tail = -1;
    printf("3 no head & tail");
  }
  if (res == 2)
  {
    mycpu()->runnable_list_head = p->next_proc;
    if (proc[p->next_proc].next_proc == -1)
      mycpu()->runnable_list_tail = p->next_proc;
    proc[p->next_proc].prev_proc = -1;
    printf("3 no head");
  }
  if (res == 3){
    mycpu()->runnable_list_tail = p->prev_proc;
    if (proc[p->prev_proc].prev_proc == -1)
      mycpu()->runnable_list_head = p->prev_proc;
    proc[p->prev_proc].next_proc = -1;
    printf("3 no tail");
  }

  p->next_proc = -1;
  p->prev_proc = -1;

  if (zombie_list_tail != -1){
    printf("zombie");
    add_proc_to_list(zombie_list_tail, p);
     if (zombie_list_head == -1)
      {
        zombie_list_head = p->proc_ind;
      }
    zombie_list_tail = p->proc_ind;
  }
  else{
    zombie_list_tail = zombie_list_head = p->proc_ind;
  }
  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(np = proc; np < &proc[NPROC]; np++){
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
          // Found one.
          pid = np->pid;
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                  sizeof(np->xstate)) < 0) {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || p->killed){
      release(&wait_lock);
      return -1;
    }

    // added
    if (p->state == RUNNING)
    {
      p->running_time += ticks - p->start_running_time;
    }
     if (p->state == RUNNABLE)
    {
      p->runnable_time += ticks - p->last_runnable_time;
    }
    if (p->state == SLEEPING)
    {
      p->sleeping_time += ticks - p->start_sleeping_time;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
  }
}

void
unpause_system(void)
{
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++) 
  {
      acquire(&p->lock);
      if(p->paused == 1) 
      {
        p->paused = 0;
      }
      release(&p->lock);
  }
} 

void
SJF_scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();
 
  c->proc = 0;

  for(;;){

    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();
   
    uint min = INT_MAX;
    struct proc* p_of_min = proc;
    int should_switch = 0;

    // for to find the runnable with min mean ticks
    for(p = proc; p < &proc[NPROC]; p++) {
         
       if(p->state == RUNNABLE) {
         if (p->mean_ticks < min)
         {
           p_of_min = p;
           min = p->mean_ticks;
           should_switch = 1;
         }
       }
    }

    // Switch to chosen process.  It is the process's job
    // to release its lock and then reacquire it
    // before jumping back to us.

    acquire(&p_of_min->lock);
    if (should_switch == 1 && p_of_min->state == RUNNABLE && p_of_min->paused == 0){
      should_switch = 0;
      p_of_min->state = RUNNING;
      p_of_min->start_running_time = ticks;
      p_of_min->runnable_time += ticks - p_of_min->last_runnable_time;
      c->proc = p_of_min;
      uint before_swtch = ticks;
      swtch(&c->context, &p_of_min->context);
      p_of_min->last_ticks= ticks - before_swtch;
      p_of_min->mean_ticks=((10 - rate) * p->mean_ticks + p->last_ticks * (rate)) / 10 ;
      
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      c->proc = 0;
    }
    release(&p_of_min->lock);

    if (pause_flag == 1) 
    {
      if (wake_up_time <= ticks) 
      {
        pause_flag = 0;
        unpause_system();
      }
    }
  }
}


void
FCFS_scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();
  
 
  int should_switch = 0;
  
  c->proc = 0;
  for(;;)
  {
    // Avoiding deadlock by ensuring that devices can interrupt.
    intr_on();

    uint minlast_runnable = INT_MAX;
    struct proc *p_of_min = proc;

    // Checking which process has the lowest mean_ticks
    for(p = proc; p < &proc[NPROC]; p++) 
    {
      acquire(&p->lock);
      if(p->state == RUNNABLE && p->paused == 0) 
      {
        if(p->last_runnable_time <= minlast_runnable)
        {
          minlast_runnable = p->mean_ticks;
          p_of_min = p;
          should_switch = 1;
        }
      }
      release(&p->lock);
    }

    // Switch to chosen process.  It is the process's job
    // to release its lock and then reacquire it
    // before jumping back to us.
    
    acquire(&p_of_min->lock);
    if (p_of_min->paused == 0)
    {
      if (should_switch == 1 && p_of_min->pid > -1)
      {
        p_of_min->state = RUNNING;
        p_of_min->start_running_time = ticks;
        p_of_min->runnable_time += ticks - p_of_min->last_runnable_time;
        c->proc = p_of_min;
        swtch(&c->context, &p_of_min->context);

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
        should_switch = 0;
      }
    }
    release(&p_of_min->lock);

    if (pause_flag == 1) 
    {
      if (wake_up_time <= ticks) 
      {
        pause_flag = 0;
        unpause_system();
      }
    }
  }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.


void
scheduler(void)
{
  // TODO: pick first process from list.
  struct proc *p;
  struct cpu *c = mycpu();
  
  c->proc = 0;
  for(;;)
  {
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();

    printf("start sched\n");
    if (c->runnable_list_head != -1)
    {
      p = &proc[c->runnable_list_head];
      printf("proc ind: %d\n", c->runnable_list_head);

      //Ass2
      printf("runnable3");
      int res = remove_proc_from_list(p->proc_ind); 
      if (res == 1)
      {
        c->runnable_list_head = -1;
        c->runnable_list_tail = -1;
        printf("No head & tail");
      }
      if (res == 2)
      {
        c->runnable_list_head = p->next_proc;
        if (proc[p->next_proc].next_proc == -1)
          c->runnable_list_tail = p->next_proc;
        proc[p->next_proc].prev_proc = -1;
        printf("New head: %d\n", c->runnable_list_head);
      }
      if (res == 3){
        c->runnable_list_tail = p->prev_proc;
        if (proc[p->prev_proc].prev_proc == -1)
          c->runnable_list_head = p->prev_proc;
        proc[p->prev_proc].next_proc = -1;
        printf("No tail");
      }

      acquire(&p->lock);
      p->prev_proc = -1;
      p->next_proc = -1;
      p->state = RUNNING;
      p->cpu_num = c->cpu_id;
      c->proc = p;
      swtch(&c->context, &p->context);

      
      if (c->runnable_list_head == -1)
      {
        printf("init runnable %d  , prev: %d, next: %d                           7\n", p->proc_ind, p->prev_proc, p->next_proc);
        c->runnable_list_head = p->proc_ind;
        c->runnable_list_tail = p->proc_ind;
      }
      else
      {
        printf("runnable7");
        add_proc_to_list(c->runnable_list_tail, p);
        c->runnable_list_tail = p->proc_ind;
        printf("added back: %d, prev: %d, next: %d\n", c->runnable_list_tail, proc[c->runnable_list_tail].prev_proc, proc[c->runnable_list_tail].next_proc);
      }
     
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      c->proc = 0;
      release(&p->lock);

      printf("end sched\n");
    }
  }
}

// void
// scheduler(void)
// // default_scheduler(void)
// {
//   // TODO: pick first process from list.
//   struct proc *p;
//   struct cpu *c = mycpu();
  
//   c->proc = 0;
//   for(;;){
//     // Avoid deadlock by ensuring that devices can interrupt.
//     intr_on();

//     for(p = proc; p < &proc[NPROC]; p++) {
//       acquire(&p->lock);
//       if(p->state == RUNNABLE && p->paused == 0) {

//         // Switch to chosen process.  It is the process's job
//         // to release its lock and then reacquire it
//         // before jumping back to us.

//         p->runnable_time += ticks - p->last_runnable_time;

//         p->state = RUNNING;

//         p->start_running_time = ticks;

//         c->proc = p;
//         swtch(&c->context, &p->context);

//         // Process is done running for now.
//         // It should have changed its p->state before coming back.
//         c->proc = 0;
//       }
//       release(&p->lock);
//     }
//     if (pause_flag == 1) 
//     {
//       if (wake_up_time <= ticks) 
//       {
//         pause_flag = 0;
//         unpause_system();
//       }
//     }
//   }
// }

//added
// void 
// scheduler(void)
// {
//   #ifdef FCFS
//     FCFS_scheduler();
//   #endif

//   #ifdef SJF
//     SJF_scheduler();
//   #endif
  
//   #ifdef RR
//     default_scheduler();
//   #endif
  
  
// }

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
  int intena;
  struct proc *p = myproc();

  if(!holding(&p->lock))
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    panic("sched locks");
  if(p->state == RUNNING)
    panic("sched running");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
  // TODOL add to RUNNABLE list.
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;
  // added
  p->last_runnable_time = ticks;

  //Ass2
   if (mycpu()->runnable_list_head == -1)
   {
     printf("init runnable : %d                   8\n", p->proc_ind);
    mycpu()->runnable_list_head = p->proc_ind;
    mycpu()->runnable_list_tail = p->proc_ind;
   }
  else
  {
    printf("runnable8");
    add_proc_to_list(mycpu()->runnable_list_tail, p);
    mycpu()->runnable_list_tail = p->proc_ind;
  }
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first) {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  // TODO: remove from RUNNABLE and add to SLEEPING
  struct proc *p = myproc();
  
  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
  release(lk);

  //Ass2
  printf("runnable ");
  int res = remove_proc_from_list(p->proc_ind); 
  if (res == 1)
  {
    mycpu()->runnable_list_head = -1;
    mycpu()->runnable_list_tail = -1;
    printf("4 no head & tail");
  }
  if (res == 2)
  {
    mycpu()->runnable_list_head = p->next_proc;
    if (proc[p->next_proc].next_proc == -1)
      mycpu()->runnable_list_tail = p->next_proc;
    proc[p->next_proc].prev_proc = -1;
    printf("4 no head ");
  }
  if (res == 3){
    mycpu()->runnable_list_tail = p->prev_proc;
    if (proc[p->prev_proc].prev_proc == -1)
      mycpu()->runnable_list_head = p->prev_proc;
    proc[p->prev_proc].next_proc = -1;
    printf("4 no tail");
  }

  p->next_proc = -1;
  p->prev_proc = -1;

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;
  p->start_sleeping_time = ticks;

  if (sleeping_list_tail != -1){
    printf("sleeping");
    add_proc_to_list(sleeping_list_tail, p);
    if (sleeping_list_head == -1)
      {
        sleeping_list_head = p->proc_ind;
      }
    sleeping_list_tail = p->proc_ind;
  }
  else{
    printf("head in sleeping\n");
    sleeping_list_tail =  p->proc_ind;
    sleeping_list_head = p->proc_ind;
  }

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
  // TODO: go threw all SLEEPING and pick one to wake up- remove from SLEEPING and add to RUNNABLE.
  struct proc *p;
  
  while (sleeping_list_head != -1)
  {
    p = &proc[sleeping_list_head];
    if (p->chan == chan)
    {
      printf("wakeup\n"); 
      printf("sleeping");
      int res = remove_proc_from_list(p->proc_ind); 
        if (res == 1)
        {
          sleeping_list_head = -1;
          sleeping_list_tail = -1;
          printf("5 no head & tail");
        }
        if (res == 2)
        {
          sleeping_list_head = p->next_proc;
          if (proc[p->next_proc].next_proc == -1)
            sleeping_list_tail = p->next_proc;
          proc[p->next_proc].prev_proc = -1;
          printf("5 no head ");
        }
        if (res == 3){
          sleeping_list_tail = p->prev_proc;
          if (proc[p->prev_proc].prev_proc == -1)
            sleeping_list_head = p->prev_proc;
          proc[p->prev_proc].next_proc = -1;
          printf("5 no tail");
        }

        acquire(&p->lock);
        p->state = RUNNABLE;
        p->prev_proc = -1;
        p->next_proc = -1;
        release(&p->lock);

        
        if (cpus[p->cpu_num].runnable_list_head == -1)
        {
          printf("init runnable %d                  4\n", p->proc_ind);
          cpus[p->cpu_num].runnable_list_head = p->proc_ind;
          cpus[p->cpu_num].runnable_list_tail = p->proc_ind;
        }
        else
        {
          printf("runnable4");
          add_proc_to_list(cpus[p->cpu_num].runnable_list_tail, p);
          cpus[p->cpu_num].runnable_list_tail = p->proc_ind;
        }
    }

    // printf("tail: %d\n", cpus[p->cpu_num].runnable_list_tail);
    // printf("end wakeup\n");


  // for(p = proc; p < &proc[NPROC]; p++) {
  //   if(p != myproc()){
  //     acquire(&p->lock);
  //     if(p->state == SLEEPING && p->chan == chan) {
  //       p->state = RUNNABLE;
  //       p->sleeping_time += ticks - p->start_sleeping_time;
  //       // added
  //       p->last_runnable_time = ticks;
  //     }
  //     release(&p->lock);
  //   }
  // }
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->pid == pid){
      p->killed = 1;
      if(p->state == SLEEPING){
        // Wake process from sleep().
        p->state = RUNNABLE;
        p->sleeping_time += ticks - p->start_sleeping_time;
        // added
        p->last_runnable_time = ticks;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

int 
print_stats(void)
{
  printf("sleeping_processes_mean: %d\n", sleeping_processes_mean);
  printf("runnable_processes_mean: %d\n", runnable_processes_mean);
  printf("running_processes_mean: %d\n", running_processes_mean);
  printf("program_time: %d\n", program_time);
  printf("cpu_utilization: %d\n", cpu_utilization);
  printf("ticks: %d\n", ticks);
  return 0;
}

// Ass2
int
set_cpu(int cpu_num)
{
  // TODO
  if (cpu_num > NCPU)
    return -1;

  struct cpu* c;
  for(c = cpus; c < &cpus[NCPU]; c++)
  {
    if (c->cpu_id == cpu_num)
    {
      
      
      if (c->runnable_list_head == -1)
      {
        printf("init runnable %d                   5\n", proc->proc_ind);
        c->runnable_list_tail = myproc()->proc_ind;
        c->runnable_list_head = myproc()->proc_ind;
      }
      else
      {
        printf("runnable5");
        add_proc_to_list(c->runnable_list_tail, myproc());
        c->runnable_list_tail = myproc()->proc_ind;
      }
      
      return 0;
    }
  }
  return -1;
}


int
get_cpu()
{
  // TODO
  return cpuid();
}


int
pause_system(int seconds)
{
  struct proc *p;
  struct proc *myProcess = myproc();

  pause_flag = 1;

  wake_up_time = ticks + (seconds * 10);

  for(p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if(p->state == RUNNING)
    {
      if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
        if (p != myProcess) {
          p->paused = 1;
          p->running_time += ticks - p->start_running_time;
          yield();
        }
      }
    }
    release(&p->lock);
  }
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) 
  {
    acquire(&myProcess->lock);
    myProcess->paused = 1;
    myProcess->running_time += ticks - myProcess->start_running_time;
    release(&myProcess->lock);
    yield();
  }
  return 0;
}


// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.

int
kill_system(void) 
{
  struct proc *p;
  struct proc *myProcess = myproc();

  for (p = proc; p < &proc[NPROC]; p++) {
    if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
      if (p != myProcess) {
        kill(p->pid);      
      }
    }
  }
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) {
    kill(myProcess->pid);
  }
  return 0;
}

int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if(user_dst){
    return copyout(p->pagetable, dst, src, len);
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if(user_src){
    return copyin(p->pagetable, dst, src, len);
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  static char *states[] = {
  [UNUSED]    "unused",
  [SLEEPING]  "sleep ",
  [RUNNABLE]  "runble",
  [RUNNING]   "run   ",
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
  for(p = proc; p < &proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}
