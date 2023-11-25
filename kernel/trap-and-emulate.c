#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"


#define U_MODE 0
#define S_MODE 1
#define M_MODE 2
#define PMP_ADDR_NUM 64
#define PMP_CFG_NUM 16

// Struct to keep VM registers (Sample; feel free to change.)
struct vm_reg {
    int     code;
    int     mode;
    uint64  val;
    char name[30];
};

struct isa {
    uint32 opcode;
    uint32 rd;
    uint32 funct3;
    uint32 rs1;
    uint32 imm;
};
// Keep the virtual state of the VM's privileged registers
struct vm_virtual_state {
    // struct vm_reg registers[114];
    // Machine Trap Handling
    int current_mode;
    struct vm_reg mscratch;
    struct vm_reg mepc;
    struct vm_reg mcause;
    struct vm_reg mtval;
    struct vm_reg mip;
    struct vm_reg mtinst;
    struct vm_reg mtval2;

    // Machine Trap setup
    struct vm_reg mstatus;
    struct vm_reg misa;
    struct vm_reg medeleg;
    struct vm_reg mideleg;
    struct vm_reg mie;
    struct vm_reg mtvec;
    struct vm_reg mcounteren;
    struct vm_reg mstatush;

    // Machine information state registers
    struct vm_reg mvendorid;
    struct vm_reg marchid;
    struct vm_reg mimpid;
    struct vm_reg mhartid;
    struct vm_reg mconfigptr;

    // Machine physical memory protection
    struct vm_reg pmpcfg[PMP_CFG_NUM];

    struct vm_reg pmpaddr[PMP_ADDR_NUM];

    // Supervisor Page table registers
    struct vm_reg satp;

    // Supervisor Trap setup registers
    struct vm_reg sstatus;

    struct vm_reg sedeleg;

    struct vm_reg sie;
    struct vm_reg stvec;
    struct vm_reg scounteren;

    //super visor trap handling
    struct vm_reg sepc;

    // User trap handling registers
    struct vm_reg uscratch;
    struct vm_reg uepc;
    struct vm_reg ucause;
    struct vm_reg ubadaddr;
    struct vm_reg uip;

    // User trap set-up registers
    struct vm_reg ustatus;
    struct vm_reg uie;
    struct vm_reg utvec;
    struct vm_reg tmp;
};

struct vm_virtual_state *vm_state;

// In your ECALL, add the following for prints
// struct proc* p = myproc();
// printf("(EC at %p)\n", p->trapframe->epc);

// struct vm_reg* get_register_by_code(uint32 code) {
//     for (int i = 0; i < 113; ++i){
//         if(vm_state->registers[i].code == code) {

//             return &(vm_state->registers[i]);
//         }
//     }
//     printf("\nget_register_by_code: found nothing %x \n", code);
//     return NULL;
// };

struct vm_reg* check_status_registers(uint32 code){
    switch(code) {
        case 0x302:
            return &(vm_state->mstatus);
        case 0x102:
            return &(vm_state->sstatus);
        default:
            return 0;
    }       
}

struct vm_reg* get_register_by_code(uint32 code) {
    switch(code) {
        case 0xf14:
            return &(vm_state->mhartid);
        case 0x300:
            return &(vm_state->mstatus);
        case 0x180:
            return &(vm_state->satp);
        case 0x341:
            return &(vm_state->mepc);
        case 0x302:
            return &(vm_state->medeleg);
        case 0x303:
            return &(vm_state->mideleg);
        case 0x104:
            return &(vm_state->sie);
        case 0x105:
            return &(vm_state->stvec);
        case 0x100:
            return &(vm_state->sstatus);
        case 0x141:
            printf("sepc called");
            return &(vm_state->sepc);
        case 0x102:
            return &(vm_state->sedeleg);
        default:
            return 0;
    }
}

void write_to_vm_register(uint32 code, uint64 value) {
    switch(code) {
        case 0xf14:
            printf("\nvalue %x -> mhartid\n", value);
            vm_state->mhartid.val = value;
            break;
        case 0x300:
            printf("\nvalue %x -> mstatus\n", value);
            vm_state->mstatus.val = value ;
            break;
        case 0x180:
            printf("\nvalue %x -> satp\n", value);
            vm_state->satp.val = value;
            break;
        case 0x341:
            printf("\nvalue %x -> mepc\n", value);
            vm_state->mepc.val = value;
            break;
        case 0x302:
            printf("\nvalue %x -> medeleg\n", value);
            vm_state->medeleg.val = value;
            break;
        case 0x303:
            printf("\nvalue %x -> mideleg\n", value);
            vm_state->mideleg.val = value;
            break;
        case 0x104:
            printf("\nvalue %x -> sie\n", value);
            vm_state->sie.val = value;
            break;
        case 0x105:
            printf("\nvalue %x -> stvec\n", value);
            vm_state->stvec.val = value;
            break;
        case 0x100:
            printf("\nvalue %x -> sstatus\n", value);
            vm_state->sstatus.val = value;
            break;
        case 0x141:
            printf("\nvalue %x -> sepc\n", value);
            printf("sepc called");
            vm_state->sepc.val = value;
            break;
        case 0x102:
            printf("\nvalue %x -> sedeleg\n", value);
            vm_state->sedeleg.val = value;
            break;
        default:
            break;
    }
}

uint64 get_trapframe_register(uint64 code){
    struct proc* p = myproc();
    switch(code) {
        case 0xa:
            return (p->trapframe->a0);
        case 0xb:
            return (p->trapframe->a1);
        case 0xc:
            return (p->trapframe->a2);
        case 0xd:
            return (p->trapframe->a3);
        case 0xe:
            return (p->trapframe->a4);
        case 0xf:
        case 0x1:
            return (p->trapframe->a5);
        default:
            return 0;
    }
}

void write_to_trapframe_register(uint32 code, uint64 value) {
    struct proc* p = myproc();
    printf("\nstarting write\n");
    switch(code) {
        case 0xa:
            printf("\nvalue %x -> a0\n", value);
            p->trapframe->a0 = value;
            break;
        case 0xb:
            printf("\nvalue %x -> a1\n", value);
            p->trapframe->a1 = value;
            break;
        case 0xc:
            printf("\nvalue %x -> a2\n", value);
            p->trapframe->a2 = value;
            break;
        case 0xd:
            printf("\nvalue %x -> a3\n", value);
            p->trapframe->a3 = value;
            break;
        case 0xe:
            printf("\nvalue %x -> a4\n", value);
            p->trapframe->a4 = value;
            break;
        case 0xf:
        // case 0x1:
            printf("\nvalue %x -> a5\n", value);
            p->trapframe->a5 = value;
            break;
        default:
            printf("\ngoing to break\n");
            break;
    }
}

void trap_and_emulate(void) {
    /* Comes here when a VM tries to execute a supervisor instruction. */
    struct proc* p = myproc();
    /* Retrieve all required values from the instruction */
    // struct isa *isa_temp = (struct isa*) p->trapframe->epc;
    // uint32 instr = *(uint32*)(myproc()->trapframe->epc + KERNBASE);
    uint64 instr = r_stval();
    uint64 addr     = p->trapframe->epc;
    uint32 op       = instr & 0x7F;
    uint32 rd       = (instr >> 7) & 0x1F;
    uint32 funct3   = (instr >> 12) & 0x7;
    uint32 rs1      = (instr >> 15) & 0x1F;
    uint32 uimm     = (instr >> 20) & 0xFFF;
    /* Print the statement */
    printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", 
                addr, op, rd, funct3, rs1, uimm);
    if(rs1 ==0 && rd == 0) {
        printf("\n current mode %d \n  important state register values\n mepc %x, mstatus %x, medeleg %x, mideleg %x, satp %x, sie %x\n", vm_state->current_mode,vm_state->mepc.val, vm_state->mstatus.val, vm_state->medeleg.val, vm_state->mideleg.val, vm_state->satp.val, vm_state->sie.val);
        if(vm_state->current_mode == M_MODE){
            struct vm_reg *reg = check_status_registers(uimm);
            printf("\n reg value  %x %x\n", reg->val, vm_state);
            vm_state->current_mode = S_MODE;
        } else if (vm_state->current_mode == S_MODE){

        }
        p->trapframe->epc+=4;
        //not sure yet
    } else if ( rs1 == 0)
    { 
        // csrr instruction
        // printf("\n entered else if %x and %x\n", p->trapframe->a1, vm_state->mhartid.val);

        struct vm_reg *priveleged_register = get_register_by_code(uimm);
        
        printf("\nCSRR: %x %x %d\n", priveleged_register->val, priveleged_register->code, vm_state->current_mode);
        // p->trapframe->a1 = priveleged_register->val;
        write_to_trapframe_register(rd, priveleged_register->val);
        p->trapframe->epc+=4;
        // p->trapframe->a0 = vm_state->mhartid.val;
    } else if(rd == 0) {
        //csrw instruction
        // struct vm_reg *priveleged_register = get_register_by_code(uimm);
        uint64 reg_value = get_trapframe_register(rs1);
        printf("\n CSRW: %x %d\n", reg_value, vm_state->current_mode);
        write_to_vm_register(uimm, reg_value);
        p->trapframe->epc+=4;
    }
    
    // printf("\n finished else if\n");
    return;
}

void trap_and_emulate_init(void) {
    /* Create and initialize all state for the VM */
    printf("INIT: called");
    
    vm_state = (struct vm_virtual_state*)kalloc();
    
    vm_state->current_mode = M_MODE;

    vm_state->mscratch.val = 0;
    vm_state->mscratch.code = 0x340;
    vm_state->mscratch.mode = M_MODE;

    vm_state->mepc.val = 0;
    vm_state->mepc.code = 0x341;
    vm_state->mepc.mode = M_MODE;

    vm_state->mcause.val = 0;
    vm_state->mcause.code = 0x342;
    vm_state->mcause.mode = M_MODE;

    vm_state->mtval.val = 0;
    vm_state->mtval.code = 0x343;
    vm_state->mtval.mode = M_MODE;

    vm_state->mip.val = 0;
    vm_state->mip.code = 0x344;
    vm_state->mip.mode = M_MODE;

    vm_state->mtinst.val = 0;
    vm_state->mtinst.code = 0x34A;
    vm_state->mtinst.mode = M_MODE;
    
    vm_state->mtval2.val = 0;
    vm_state->mtval2.code = 0x34B;
    vm_state->mtval2.mode = M_MODE;

    // Initializing Machine Trap setup registers

    vm_state->mstatus.val = 0;
    vm_state->mstatus.code = 0x300;
    vm_state->mstatus.mode = M_MODE;

    vm_state->misa.val = 0;
    vm_state->misa.code = 0x301;
    vm_state->misa.mode = M_MODE;

    vm_state->medeleg.val = 0;
    vm_state->medeleg.code = 0x302;
    vm_state->medeleg.mode = M_MODE;

    vm_state->mideleg.val = 0;
    vm_state->mideleg.code = 0x303;
    vm_state->mideleg.mode = M_MODE;

    vm_state->mie.val = 0;
    vm_state->mie.code = 0x304;
    vm_state->mie.mode = M_MODE;

    vm_state->mtvec.val = 0;
    vm_state->mtvec.code = 0x305;
    vm_state->mtvec.mode = M_MODE;
    
    vm_state->mcounteren.val = 0;
    vm_state->mcounteren.code = 0x306;
    vm_state->mcounteren.mode = M_MODE;

    vm_state->mstatush.val = 0;
    vm_state->mstatush.code = 0x310;
    vm_state->mstatush.mode = M_MODE;    

    // Initializing Machine information state registers
    
    vm_state->mvendorid.val = 0;
    vm_state->mvendorid.code = 0xf11;
    vm_state->mvendorid.mode = M_MODE;
    
    vm_state->marchid.val = 0;
    vm_state->marchid.code = 0xf12;
    vm_state->marchid.mode = M_MODE;

    vm_state->mimpid.val = 0;
    vm_state->mimpid.code = 0xf13;
    vm_state->mimpid.mode = M_MODE;

    vm_state->mhartid.val = 0;
    vm_state->mhartid.code = 0xf14;
    vm_state->mhartid.mode = M_MODE;

    vm_state->mconfigptr.val = 0;
    vm_state->mconfigptr.code = 0xf15;
    vm_state->mconfigptr.mode = M_MODE;

    // // // Initializing Machine physical memory protection

    for (int i = 0; i < PMP_CFG_NUM; ++i) {
        vm_state->pmpcfg[i].code = 0x3a0 + i;
        vm_state->pmpcfg[i].val = 0;
        vm_state->pmpcfg[i].mode = M_MODE;
    }

    // for(int i = 0; i < PMP_ADDR_NUM; ++i) {
    //     vm_state->pmpaddr[i].code = 0x3b0 + i;
    //     vm_state->pmpaddr[i].val = 0;
    //     vm_state->pmpaddr[i].mode = M_MODE;
    // }

    // Initialize Supervisor Page table registers
    // vm_state->satp.val = 0;
    // vm_state->satp.code = 0x180;
    // vm_state->satp.mode = S_MODE;

    // Supervisor Trap setup registers
    vm_state->sstatus.val = 0;
    vm_state->sstatus.code = 0x100;
    vm_state->sstatus.mode = S_MODE;

    vm_state->sedeleg.val = 0;
    vm_state->sedeleg.code = 0x102;
    vm_state->sedeleg.mode = S_MODE;

    vm_state->sie.val = 0;
    vm_state->sie.code = 0x104;
    vm_state->sie.mode = S_MODE;

    vm_state->stvec.val = 0;
    vm_state->stvec.code = 0; // 0x105
    vm_state->stvec.mode = S_MODE;

    vm_state->scounteren.val = 0;
    vm_state->scounteren.code = 0x106;
    vm_state->scounteren.mode = S_MODE;

    // supervisor trap handling

    vm_state->sepc.val = 0;
    vm_state->sepc.code = 0; 
    vm_state->sepc.mode = S_MODE;

    // User trap handling registers

    vm_state->scounteren.val = 0;
    vm_state->scounteren.code = 0;
    vm_state->scounteren.mode = U_MODE;

    // vm_state->uepc.val = 0;
    // vm_state->uepc.code = 0x41;
    // vm_state->uepc.mode = U_MODE;

    vm_state->ucause.val = 0;
    vm_state->ucause.code = 0x42;
    vm_state->ucause.mode = U_MODE;

    vm_state->ubadaddr.val = 0;
    vm_state->ubadaddr.code = 0;
    vm_state->ubadaddr.mode = U_MODE;

    vm_state->uip.val = 0;
    vm_state->uip.code = 0x044;
    vm_state->uip.mode = U_MODE;

    // // Initialization User trap set-up registers

    vm_state->ustatus.val = 0;
    vm_state->ustatus.code = 0;
    vm_state->ustatus.mode = U_MODE;

    vm_state->uie.val = 0;
    vm_state->uie.code = 0;
    vm_state->uie.mode = U_MODE;

    vm_state->utvec.val = 0;
    vm_state->utvec.code = 0;
    vm_state->utvec.mode = U_MODE;

    // initialize 
    printf("\n current mode - %d %x\n", vm_state->current_mode, vm_state);
}