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
    int current_mode;
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
            return (p->trapframe->a5);
        default:
            return 0;
    }
}

void write_to_trapframe_register(uint32 code, uint64 value) {
    struct proc* p = myproc();
    switch(code) {
        case 0xa:
            p->trapframe->a0 = value;
            break;
        case 0xb:
            p->trapframe->a1 = value;
            break;
        case 0xc:
            p->trapframe->a2 = value;
            break;
        case 0xd:
            p->trapframe->a3 = value;
            break;
        case 0xe:
            p->trapframe->a4 = value;
            break;
        case 0xf:
            p->trapframe->a5 = value;
            break;
        default:
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
    uint32 rs1      = (instr >> 15) & 0x1;
    uint32 uimm     = (instr >> 20);
    printf("\n%x\n", instr);
    /* Print the statement */
    printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", 
                addr, op, rd, funct3, rs1, uimm);
    
    if(rs1 ==0 && rd == 0) {
        //not sure yet
    } else if ( rs1 == 0)
    { 
        // csrr instruction
        // printf("\n entered else if %x and %x\n", p->trapframe->a1, vm_state->mhartid.val);

        struct vm_reg *priveleged_register = get_register_by_code(uimm);
        
        printf("\nFetched_register: %s %x\n", priveleged_register->val, priveleged_register->code);
        // p->trapframe->a1 = priveleged_register->val;
        write_to_trapframe_register(rd, priveleged_register->val);
        // p->trapframe->a0 = vm_state->mhartid.val;
    } else if(rd == 0) {
        //csrw instruction

    }
    p->trapframe->epc+=4;
    // printf("\n finished else if\n");
    return;
}

void trap_and_emulate_init(void) {
    /* Create and initialize all state for the VM */
    printf("INIT: called");
    
    vm_state = (struct vm_virtual_state*)kalloc();
    
//     // Initializing Machine Trap Handling registers
//     vm_state->registers[0].val = 0;
//     // strncpy(vm_state->registers[0].name, "mscratch", strlen("mscratch"));
//     vm_state->registers[0].code = 0x340;
//     vm_state->registers[0].mode = M_MODE;
//     printf("INIT: called");

//     vm_state->registers[1].val = 0;
//     // strncpy(vm_state->registers[1].name, "mepc", strlen("mepc"));
//     vm_state->registers[1].code = 0x341;
//     vm_state->registers[1].mode = M_MODE;

//     vm_state->registers[2].val = 0;
//     // strncpy(vm_state->registers[2].name, "mcause", strlen("mcause"));
//     vm_state->registers[2].code = 0x342;
//     vm_state->registers[2].mode = M_MODE;

//     vm_state->registers[3].val = 0;
//     // strncpy(vm_state->registers[3].name, "mtval", strlen("mtval"));
//     vm_state->registers[3].code = 0x343;
//     vm_state->registers[3].mode = M_MODE;

//     vm_state->registers[4].val = 0;
//     // strncpy(vm_state->registers[4].name, "mip", strlen("mip"));
//     vm_state->registers[4].code = 0x344;
//     vm_state->registers[4].mode = M_MODE;

//     vm_state->registers[5].val = 0;
//     // strncpy(vm_state->registers[5].name, "mtinst", strlen("mtinst"));
//     vm_state->registers[5].code = 0x34A;
//     vm_state->registers[5].mode = M_MODE;
    
//     vm_state->registers[6].val = 0;
//     // strncpy(vm_state->registers[6].name, "mtval2", strlen("mtval2"));
//     vm_state->registers[6].code = 0x34B;
//     vm_state->registers[6].mode = M_MODE;

// // Initializing Machine Trap setup registers
//     printf("\nINIT: called");

//     vm_state->registers[7].val = 0;
//     // strncpy(vm_state->registers[7].name, "mstatus", strlen("mstatus"));
//     vm_state->registers[7].code = 0x300;
//     vm_state->registers[7].mode = M_MODE;

//     vm_state->registers[8].val = 0;
//     // strncpy(vm_state->registers[8].name, "misa", strlen("misa"));    
//     vm_state->registers[8].code = 0x301;
//     vm_state->registers[8].mode = M_MODE;

//     vm_state->registers[9].val = 0;
//     // strncpy(vm_state->registers[9].name, "medeleg", strlen("medeleg"));
//     vm_state->registers[9].code = 0x302;
//     vm_state->registers[9].mode = M_MODE;

//     vm_state->registers[10].val = 0;
//     // strncpy(vm_state->registers[10].name, "mideleg", strlen("mideleg"));
//     vm_state->registers[10].code = 0x303;
//     vm_state->registers[10].mode = M_MODE;

//     vm_state->registers[11].val = 0;
//     // strncpy(vm_state->registers[11].name, "mie", strlen("mie"));
//     vm_state->registers[11].code = 0x304;
//     vm_state->registers[11].mode = M_MODE;

//     vm_state->registers[12].val = 0;
//     // strncpy(vm_state->registers[12].name, "mtvec", strlen("mtvec"));
//     vm_state->registers[12].code = 0x305;
//     vm_state->registers[12].mode = M_MODE;
    
//     vm_state->registers[13].val = 0;
//     // strncpy(vm_state->registers[13].name, "mcounteren", strlen("mcounteren"));
//     vm_state->registers[13].code = 0x306;
//     vm_state->registers[13].mode = M_MODE;

//     vm_state->registers[14].val = 0;
//     // strncpy(vm_state->registers[14].name, "mstatush", strlen("mstatush"));
//     vm_state->registers[14].code = 0x310;
//     vm_state->registers[14].mode = M_MODE;

// // Initializing Machine information state registers

//     vm_state->registers[15].val = 0;
//     // strncpy(vm_state->registers[15].name, "mvendorid", strlen("mvendorid"));
//     vm_state->registers[15].code = 0xf11;
//     vm_state->registers[15].mode = M_MODE;
    
//     vm_state->registers[16].val = 0;
//     // strncpy(vm_state->registers[16].name, "marchid", strlen("marchid"));
//     vm_state->registers[16].code = 0xf12;
//     vm_state->registers[16].mode = M_MODE;

//     vm_state->registers[17].val = 0;
//     // strncpy(vm_state->registers[17].name, "mimpid", strlen("mimpid"));
//     vm_state->registers[17].code = 0xf13;
//     vm_state->registers[17].mode = M_MODE;

//     vm_state->registers[18].val = 0;
//     // strncpy(vm_state->registers[18].name, "mhartid", strlen("mhartid"));
//     vm_state->registers[18].code = 0xf14;
//     vm_state->registers[18].mode = M_MODE;

//     vm_state->registers[19].val = 0;
//     // strncpy(vm_state->registers[19].name, "mconfigptr", strlen("mconfigptr"));
//     vm_state->registers[19].code = 0xf15;
//     vm_state->registers[19].mode = M_MODE;

//     // Initializing Machine physical memory protection
// printf("\nINIT: called");
//     for (int i = 20; i < 20 + PMP_CFG_NUM; ++i) {
//         vm_state->registers[i].code = 0x3a0 + (i-20);
//         // sprintf(vm_state->registers[i].name, "%s%d", "pmpcfg", i-20);
//         // strncpy(vm_state->registers[i].name, "pmpcfg", strlen("pmpcfg"));
//         vm_state->registers[i].val = 0;
//         vm_state->registers[i].mode = M_MODE;
//     }
// printf("\nINIT: called");
//     for(int i = 36; i < PMP_ADDR_NUM + 36; ++i) {
//         vm_state->registers[i].code = 0x3b0 + (i-36);
//         // sprintf(vm_state->registers[i].name, "%s%d", "pmpaddr", i-36);
//         // strncpy(vm_state->registers[i].name, "pmpaddr", strlen("pmpaddr"));
//         vm_state->registers[i].val = 0;
//         vm_state->registers[i].mode = M_MODE;
//     }
// printf("\nINIT: called new border");
//     // Initialize Supervisor Page table registers
//     vm_state->registers[100].val = 0;
//     // strncpy(vm_state->registers[100].name, "satp", strlen("satp"));
//     vm_state->registers[100].code = 0x180;
//     vm_state->registers[100].mode = S_MODE;

//     // Supervisor Trap setup registers
//     vm_state->registers[101].val = 0;
//     // strncpy(vm_state->registers[101].name, "sstatus", strlen("sstatus"));
//     vm_state->registers[101].code = 0x100;
//     vm_state->registers[101].mode = S_MODE;

//     vm_state->registers[102].val = 0;
//     // strncpy(vm_state->registers[102].name, "sie", strlen("sie"));
//     vm_state->registers[102].code = 0x104;
//     vm_state->registers[102].mode = S_MODE;

//     vm_state->registers[103].val = 0;
//     // strncpy(vm_state->registers[103].name, "stvec", strlen("stvec"));
//     vm_state->registers[103].code = 0x105;
//     vm_state->registers[103].mode = S_MODE;

//     vm_state->registers[104].val = 0;
//     // strncpy(vm_state->registers[104].name, "scounteren", strlen("scounteren"));
//     vm_state->registers[104].code = 0x106;
//     vm_state->registers[104].mode = S_MODE;

//     // User trap handling registers

//     vm_state->registers[105].val = 0;
//     // strncpy(vm_state->registers[105].name, "uscratch", strlen("uscratch"));
//     vm_state->registers[105].code = 0x040;
//     vm_state->registers[105].mode = U_MODE;

//     vm_state->registers[106].val = 0;
//     // strncpy(vm_state->registers[106].name, "uepc", strlen("uepc"));
//     vm_state->registers[106].code = 0x041;
//     vm_state->registers[106].mode = U_MODE;

//     vm_state->registers[107].val = 0;
//         // strncpy(vm_state->registers[107].name, "ucause", strlen("ucause"));
//     vm_state->registers[107].code = 0x042;
//     vm_state->registers[107].mode = U_MODE;

//     vm_state->registers[108].val = 0;
//         // strncpy(vm_state->registers[108].name, "ubadaddr", strlen("ubadaddr"));
//     vm_state->registers[108].code = 0x043;
//     vm_state->registers[108].mode = U_MODE;

//     vm_state->registers[109].val = 0;
//         // strncpy(vm_state->registers[109].name, "uip", strlen("uip"));
//     vm_state->registers[109].code = 0x044;
//     vm_state->registers[109].mode = U_MODE;
// printf("\nINIT: called new border");

//     // Initialization User trap set-up registers

//     vm_state->registers[110].val = 0;
//         // strncpy(vm_state->registers[110].name, "ustatus", strlen("ustatus"));
//     vm_state->registers[110].code = 0x000;
//     vm_state->registers[110].mode = U_MODE;

//     vm_state->registers[111].val = 0;
//     // strncpy(vm_state->registers[111].name, "uie", strlen("uie"));
//     vm_state->registers[111].code = 0x004;
//     vm_state->registers[111].mode = U_MODE;

//     vm_state->registers[112].val = 0;
//     // strncpy(vm_state->registers[112].name, "utvec", strlen("utvec"));
//     vm_state->registers[112].code = 0x005;
//     vm_state->registers[112].mode = U_MODE;



printf("\nINIT: called new border");











    // for(int i = 0; i < 113; ++i){

    // }
    // Initializing Machine Trap Handling registers


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

    // // Initializing Machine Trap setup registers

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

    // // Initializing Machine information state registers
    
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

    // // Initializing Machine physical memory protection

    for (int i = 0; i < PMP_CFG_NUM; ++i) {
        vm_state->pmpcfg[i].code = 0x3a0 + i;
        vm_state->pmpcfg[i].val = 0;
        vm_state->pmpcfg[i].mode = M_MODE;
    }

    for(int i = 0; i < PMP_ADDR_NUM; ++i) {
        vm_state->pmpaddr[i].code = 0x3b0 + i;
        vm_state->pmpaddr[i].val = 0;
        vm_state->pmpaddr[i].mode = M_MODE;
    }

    // Initialize Supervisor Page table registers
    vm_state->satp.val = 0;
    vm_state->satp.code = 0x180;
    vm_state->satp.mode = S_MODE;

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
    vm_state->stvec.code = 0x105;
    vm_state->stvec.mode = S_MODE;

    vm_state->scounteren.val = 0;
    vm_state->scounteren.code = 0x106;
    vm_state->scounteren.mode = S_MODE;

    // supervisor trap handling

    vm_state->sepc.val = 0;
    vm_state->sepc.code = 0x141;
    vm_state->sepc.mode = S_MODE;

    // User trap handling registers

    vm_state->scounteren.val = 0;
    vm_state->scounteren.code = 0x040;
    vm_state->scounteren.mode = U_MODE;

    vm_state->uepc.val = 0;
    vm_state->uepc.code = 0x041;
    vm_state->uepc.mode = U_MODE;

    vm_state->ucause.val = 0;
    vm_state->ucause.code = 0x042;
    vm_state->ucause.mode = U_MODE;

    vm_state->ubadaddr.val = 0;
    vm_state->ubadaddr.code = 0x043;
    vm_state->ubadaddr.mode = U_MODE;

    vm_state->uip.val = 0;
    vm_state->uip.code = 0x044;
    vm_state->uip.mode = U_MODE;

    // Initialization User trap set-up registers

    vm_state->ustatus.val = 0;
    vm_state->ustatus.code = 0x000;
    vm_state->ustatus.mode = U_MODE;

    vm_state->uie.val = 0;
    vm_state->uie.code = 0x004;
    vm_state->uie.mode = U_MODE;

    vm_state->utvec.val = 0;
    vm_state->utvec.code = 0x005;
    vm_state->utvec.mode = U_MODE;

    // initialize 
    vm_state->current_mode = M_MODE;

}





//     // Initializing Machine Trap Handling registers
//     vm_state->registers[0].val = 0;
//     // strncpy(vm_state->registers[0].name, "mscratch", strlen("mscratch"));
//     vm_state->registers[0].code = 0x340;
//     vm_state->registers[0].mode = M_MODE;
//     printf("INIT: called");

//     vm_state->registers[1].val = 0;
//     // strncpy(vm_state->registers[1].name, "mepc", strlen("mepc"));
//     vm_state->registers[1].code = 0x341;
//     vm_state->registers[1].mode = M_MODE;

//     vm_state->registers[2].val = 0;
//     // strncpy(vm_state->registers[2].name, "mcause", strlen("mcause"));
//     vm_state->registers[2].code = 0x342;
//     vm_state->registers[2].mode = M_MODE;

//     vm_state->registers[3].val = 0;
//     // strncpy(vm_state->registers[3].name, "mtval", strlen("mtval"));
//     vm_state->registers[3].code = 0x343;
//     vm_state->registers[3].mode = M_MODE;

//     vm_state->registers[4].val = 0;
//     // strncpy(vm_state->registers[4].name, "mip", strlen("mip"));
//     vm_state->registers[4].code = 0x344;
//     vm_state->registers[4].mode = M_MODE;

//     vm_state->registers[5].val = 0;
//     // strncpy(vm_state->registers[5].name, "mtinst", strlen("mtinst"));
//     vm_state->registers[5].code = 0x34A;
//     vm_state->registers[5].mode = M_MODE;
    
//     vm_state->registers[6].val = 0;
//     // strncpy(vm_state->registers[6].name, "mtval2", strlen("mtval2"));
//     vm_state->registers[6].code = 0x34B;
//     vm_state->registers[6].mode = M_MODE;

// // Initializing Machine Trap setup registers
//     printf("\nINIT: called");

//     vm_state->registers[7].val = 0;
//     // strncpy(vm_state->registers[7].name, "mstatus", strlen("mstatus"));
//     vm_state->registers[7].code = 0x300;
//     vm_state->registers[7].mode = M_MODE;

//     vm_state->registers[8].val = 0;
//     // strncpy(vm_state->registers[8].name, "misa", strlen("misa"));    
//     vm_state->registers[8].code = 0x301;
//     vm_state->registers[8].mode = M_MODE;

//     vm_state->registers[9].val = 0;
//     // strncpy(vm_state->registers[9].name, "medeleg", strlen("medeleg"));
//     vm_state->registers[9].code = 0x302;
//     vm_state->registers[9].mode = M_MODE;

//     vm_state->registers[10].val = 0;
//     // strncpy(vm_state->registers[10].name, "mideleg", strlen("mideleg"));
//     vm_state->registers[10].code = 0x303;
//     vm_state->registers[10].mode = M_MODE;

//     vm_state->registers[11].val = 0;
//     // strncpy(vm_state->registers[11].name, "mie", strlen("mie"));
//     vm_state->registers[11].code = 0x304;
//     vm_state->registers[11].mode = M_MODE;

//     vm_state->registers[12].val = 0;
//     // strncpy(vm_state->registers[12].name, "mtvec", strlen("mtvec"));
//     vm_state->registers[12].code = 0x305;
//     vm_state->registers[12].mode = M_MODE;
    
//     vm_state->registers[13].val = 0;
//     // strncpy(vm_state->registers[13].name, "mcounteren", strlen("mcounteren"));
//     vm_state->registers[13].code = 0x306;
//     vm_state->registers[13].mode = M_MODE;

//     vm_state->registers[14].val = 0;
//     // strncpy(vm_state->registers[14].name, "mstatush", strlen("mstatush"));
//     vm_state->registers[14].code = 0x310;
//     vm_state->registers[14].mode = M_MODE;

// // Initializing Machine information state registers

//     vm_state->registers[15].val = 0;
//     // strncpy(vm_state->registers[15].name, "mvendorid", strlen("mvendorid"));
//     vm_state->registers[15].code = 0xf11;
//     vm_state->registers[15].mode = M_MODE;
    
//     vm_state->registers[16].val = 0;
//     // strncpy(vm_state->registers[16].name, "marchid", strlen("marchid"));
//     vm_state->registers[16].code = 0xf12;
//     vm_state->registers[16].mode = M_MODE;

//     vm_state->registers[17].val = 0;
//     // strncpy(vm_state->registers[17].name, "mimpid", strlen("mimpid"));
//     vm_state->registers[17].code = 0xf13;
//     vm_state->registers[17].mode = M_MODE;

//     vm_state->registers[18].val = 0;
//     // strncpy(vm_state->registers[18].name, "mhartid", strlen("mhartid"));
//     vm_state->registers[18].code = 0xf14;
//     vm_state->registers[18].mode = M_MODE;

//     vm_state->registers[19].val = 0;
//     // strncpy(vm_state->registers[19].name, "mconfigptr", strlen("mconfigptr"));
//     vm_state->registers[19].code = 0xf15;
//     vm_state->registers[19].mode = M_MODE;

//     // Initializing Machine physical memory protection
// printf("\nINIT: called");
//     for (int i = 20; i < 20 + PMP_CFG_NUM; ++i) {
//         vm_state->registers[i].code = 0x3a0 + (i-20);
//         // sprintf(vm_state->registers[i].name, "%s%d", "pmpcfg", i-20);
//         // strncpy(vm_state->registers[i].name, "pmpcfg", strlen("pmpcfg"));
//         vm_state->registers[i].val = 0;
//         vm_state->registers[i].mode = M_MODE;
//     }
// printf("\nINIT: called");
//     for(int i = 36; i < PMP_ADDR_NUM + 36; ++i) {
//         vm_state->registers[i].code = 0x3b0 + (i-36);
//         // sprintf(vm_state->registers[i].name, "%s%d", "pmpaddr", i-36);
//         // strncpy(vm_state->registers[i].name, "pmpaddr", strlen("pmpaddr"));
//         vm_state->registers[i].val = 0;
//         vm_state->registers[i].mode = M_MODE;
//     }
// printf("\nINIT: called new border");
//     // Initialize Supervisor Page table registers
//     vm_state->registers[100].val = 0;
//     // strncpy(vm_state->registers[100].name, "satp", strlen("satp"));
//     vm_state->registers[100].code = 0x180;
//     vm_state->registers[100].mode = S_MODE;

//     // Supervisor Trap setup registers
//     vm_state->registers[101].val = 0;
//     // strncpy(vm_state->registers[101].name, "sstatus", strlen("sstatus"));
//     vm_state->registers[101].code = 0x100;
//     vm_state->registers[101].mode = S_MODE;

//     vm_state->registers[102].val = 0;
//     // strncpy(vm_state->registers[102].name, "sie", strlen("sie"));
//     vm_state->registers[102].code = 0x104;
//     vm_state->registers[102].mode = S_MODE;

//     vm_state->registers[103].val = 0;
//     // strncpy(vm_state->registers[103].name, "stvec", strlen("stvec"));
//     vm_state->registers[103].code = 0x105;
//     vm_state->registers[103].mode = S_MODE;

//     vm_state->registers[104].val = 0;
//     // strncpy(vm_state->registers[104].name, "scounteren", strlen("scounteren"));
//     vm_state->registers[104].code = 0x106;
//     vm_state->registers[104].mode = S_MODE;

//     // User trap handling registers

//     vm_state->registers[105].val = 0;
//     // strncpy(vm_state->registers[105].name, "uscratch", strlen("uscratch"));
//     vm_state->registers[105].code = 0x040;
//     vm_state->registers[105].mode = U_MODE;

//     vm_state->registers[106].val = 0;
//     // strncpy(vm_state->registers[106].name, "uepc", strlen("uepc"));
//     vm_state->registers[106].code = 0x041;
//     vm_state->registers[106].mode = U_MODE;

//     vm_state->registers[107].val = 0;
//         // strncpy(vm_state->registers[107].name, "ucause", strlen("ucause"));
//     vm_state->registers[107].code = 0x042;
//     vm_state->registers[107].mode = U_MODE;

//     vm_state->registers[108].val = 0;
//         // strncpy(vm_state->registers[108].name, "ubadaddr", strlen("ubadaddr"));
//     vm_state->registers[108].code = 0x043;
//     vm_state->registers[108].mode = U_MODE;

//     vm_state->registers[109].val = 0;
//         // strncpy(vm_state->registers[109].name, "uip", strlen("uip"));
//     vm_state->registers[109].code = 0x044;
//     vm_state->registers[109].mode = U_MODE;
// printf("\nINIT: called new border");

//     // Initialization User trap set-up registers

//     vm_state->registers[110].val = 0;
//         // strncpy(vm_state->registers[110].name, "ustatus", strlen("ustatus"));
//     vm_state->registers[110].code = 0x000;
//     vm_state->registers[110].mode = U_MODE;

//     vm_state->registers[111].val = 0;
//     // strncpy(vm_state->registers[111].name, "uie", strlen("uie"));
//     vm_state->registers[111].code = 0x004;
//     vm_state->registers[111].mode = U_MODE;

//     vm_state->registers[112].val = 0;
//     // strncpy(vm_state->registers[112].name, "utvec", strlen("utvec"));
//     vm_state->registers[112].code = 0x005;
//     vm_state->registers[112].mode = U_MODE;


