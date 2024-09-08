/*
 * Copyright (c) 2013-2023, ARM Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <string.h>

#include <platform_def.h>

#include <arch_helpers.h>
#include <common/bl_common.h>
#include <common/debug.h>
#include <drivers/arm/cci.h>
#include <lib/utils.h>
#include <lib/xlat_tables/xlat_tables_compat.h>
#if SPM_MM
#include <services/spm_mm_partition.h>
#endif

#include <plat/arm/common/arm_config.h>
#include <plat/arm/common/plat_arm.h>
#include <plat/common/platform.h>

#include <plat_private.h>

#ifndef BL32_PARAM_H
#define BL32_PARAM_H

/*******************************************************************************
 * Platform memory map related constants
 ******************************************************************************/
/* TF text, ro, rw, Size: 1MB */
#define TZRAM_BASE		(0x0)
#define TZRAM_SIZE		(0x100000)

/*******************************************************************************
 * BL32 specific defines.
 ******************************************************************************/
/*
 * Put BL32 at the top of the Trusted RAM
 */
#define BL32_BASE			(TZRAM_BASE + 0x40000)
#define BL32_LIMIT			(TZRAM_BASE + TZRAM_SIZE)

#endif /* BL32_PARAM_H */

#ifndef ARM_SPM_DEF_H
#define ARM_SPM_DEF_H

/*
 * If BL31 is placed in DRAM, place the Secure Partition in DRAM right after the
 * region used by BL31. If BL31 it is placed in SRAM, put the Secure Partition
 * at the base of DRAM.
 */
#define ARM_SP_IMAGE_BASE		BL32_BASE
#define ARM_SP_IMAGE_LIMIT		BL32_LIMIT
/* The maximum size of the S-EL0 payload can be 3MB */
#define ARM_SP_IMAGE_SIZE		ULL(0x300000)

#ifdef IMAGE_BL2
/* SPM Payload memory. Mapped as RW in BL2. */
#define ARM_SP_IMAGE_MMAP		MAP_REGION_FLAT(			\
						ARM_SP_IMAGE_BASE,		\
						ARM_SP_IMAGE_SIZE,		\
						MT_MEMORY | MT_RW | MT_SECURE)
#endif

#ifdef IMAGE_BL31
/* SPM Payload memory. Mapped as code in S-EL1 */
#define ARM_SP_IMAGE_MMAP		MAP_REGION2(				\
						ARM_SP_IMAGE_BASE,		\
						ARM_SP_IMAGE_BASE,		\
						ARM_SP_IMAGE_SIZE,		\
						MT_CODE | MT_SECURE | MT_USER,	\
						PAGE_SIZE)
#endif

/*
 * Memory shared between EL3 and S-EL0. It is used by EL3 to push data into
 * S-EL0, so it is mapped with RW permission from EL3 and with RO permission
 * from S-EL0. Placed after SPM Payload memory.
 */
#define PLAT_SPM_BUF_BASE		(ARM_SP_IMAGE_BASE + ARM_SP_IMAGE_SIZE)
#define PLAT_SPM_BUF_SIZE		ULL(0x100000)

#define ARM_SPM_BUF_EL3_MMAP		MAP_REGION_FLAT(			\
						PLAT_SPM_BUF_BASE,		\
						PLAT_SPM_BUF_SIZE,		\
						MT_RW_DATA | MT_SECURE)
#define ARM_SPM_BUF_EL0_MMAP		MAP_REGION2(			\
						PLAT_SPM_BUF_BASE,		\
						PLAT_SPM_BUF_BASE,		\
						PLAT_SPM_BUF_SIZE,		\
						MT_RO_DATA | MT_SECURE | MT_USER,\
						PAGE_SIZE)

/*
 * Memory shared between Normal world and S-EL0 for passing data during service
 * requests. Mapped as RW and NS. Placed after the shared memory between EL3 and
 * S-EL0.
 */
#define PLAT_SP_IMAGE_NS_BUF_BASE	(PLAT_SPM_BUF_BASE + PLAT_SPM_BUF_SIZE)
#define PLAT_SP_IMAGE_NS_BUF_SIZE	ULL(0x10000)
#define ARM_SP_IMAGE_NS_BUF_MMAP	MAP_REGION2(				\
						PLAT_SP_IMAGE_NS_BUF_BASE,	\
						PLAT_SP_IMAGE_NS_BUF_BASE,	\
						PLAT_SP_IMAGE_NS_BUF_SIZE,	\
						MT_RW_DATA | MT_NS | MT_USER,	\
						PAGE_SIZE)

/*
 * RW memory, which uses the remaining Trusted DRAM. Placed after the memory
 * shared between Secure and Non-secure worlds, or after the platform specific
 * buffers, if defined. First there is the stack memory for all CPUs and then
 * there is the common heap memory. Both are mapped with RW permissions.
 */
#define PLAT_ARM_SP_IMAGE_STACK_BASE	(PLAT_SP_IMAGE_NS_BUF_BASE +	\
					 PLAT_SP_IMAGE_NS_BUF_SIZE)

#define PLAT_SP_IMAGE_STACK_BASE	PLAT_ARM_SP_IMAGE_STACK_BASE
#define PLAT_SP_IMAGE_STACK_PCPU_SIZE	ULL(0x2000)
#define ARM_SP_IMAGE_STACK_TOTAL_SIZE	(PLATFORM_CORE_COUNT *			\
					 PLAT_SP_IMAGE_STACK_PCPU_SIZE)

#define ARM_SP_IMAGE_HEAP_BASE		(PLAT_SP_IMAGE_STACK_BASE +		\
					 ARM_SP_IMAGE_STACK_TOTAL_SIZE)
#define ARM_SP_IMAGE_HEAP_SIZE		(ARM_SP_IMAGE_LIMIT - ARM_SP_IMAGE_HEAP_BASE)

#define ARM_SP_IMAGE_RW_MMAP		MAP_REGION2(				\
						PLAT_SP_IMAGE_STACK_BASE,	\
						PLAT_SP_IMAGE_STACK_BASE,	\
						(ARM_SP_IMAGE_LIMIT -		\
						 PLAT_SP_IMAGE_STACK_BASE),	\
						MT_RW_DATA | MT_SECURE | MT_USER,\
						PAGE_SIZE)

/* Total number of memory regions with distinct properties */
#define ARM_SP_IMAGE_NUM_MEM_REGIONS	6

/* Cookies passed to the Secure Partition at boot. Not used by ARM platforms. */
#define PLAT_SPM_COOKIE_0		ULL(0)
#define PLAT_SPM_COOKIE_1		ULL(0)

#endif /* ARM_SPM_DEF_H */

#ifdef PLAT_RK_CCI_BASE
static const int cci_map[] = {
	PLAT_RK_CCI_CLUSTER0_SL_IFACE_IX,
	PLAT_RK_CCI_CLUSTER1_SL_IFACE_IX
};
#endif

/******************************************************************************
 * Macro generating the code for the function setting up the pagetables as per
 * the platform memory map & initialize the mmu, for the given exception level
 ******************************************************************************/
#define DEFINE_CONFIGURE_MMU_EL(_el)					\
	void plat_configure_mmu_el ## _el(unsigned long total_base,	\
					  unsigned long total_size,	\
					  unsigned long ro_start,	\
					  unsigned long ro_limit,	\
					  unsigned long coh_start,	\
					  unsigned long coh_limit)	\
	{								\
		mmap_add_region(total_base, total_base,			\
				total_size,				\
				MT_MEMORY | MT_RW | MT_SECURE);		\
		mmap_add_region(ro_start, ro_start,			\
				ro_limit - ro_start,			\
				MT_MEMORY | MT_RO | MT_SECURE);		\
		if ((coh_limit - coh_start) != 0)			\
			mmap_add_region(coh_start, coh_start,		\
					coh_limit - coh_start,		\
					MT_DEVICE | MT_RW | MT_SECURE);	\
		mmap_add(plat_rk_mmap);					\
		rockchip_plat_mmu_el##_el();				\
		init_xlat_tables();					\
									\
		enable_mmu_el ## _el(0);				\
	}

/* Define EL3 variants of the function initialising the MMU */
DEFINE_CONFIGURE_MMU_EL(3)

unsigned int plat_get_syscnt_freq2(void)
{
	return SYS_COUNTER_FREQ_IN_TICKS;
}

void plat_cci_init(void)
{
#ifdef PLAT_RK_CCI_BASE
	/* Initialize CCI driver */
	cci_init(PLAT_RK_CCI_BASE, cci_map, ARRAY_SIZE(cci_map));
#endif
}

void plat_cci_enable(void)
{
	/*
	 * Enable CCI coherency for this cluster.
	 * No need for locks as no other cpu is active at the moment.
	 */
#ifdef PLAT_RK_CCI_BASE
	cci_enable_snoop_dvm_reqs(MPIDR_AFFLVL1_VAL(read_mpidr()));
#endif
}

void plat_cci_disable(void)
{
#ifdef PLAT_RK_CCI_BASE
	cci_disable_snoop_dvm_reqs(MPIDR_AFFLVL1_VAL(read_mpidr()));
#endif
}

#if SPM_MM || SPMC_AT_EL3
	ARM_SP_IMAGE_MMAP
#endif

#if ARM_BL31_IN_DRAM
	ARM_MAP_BL31_SEC_DRAM
#endif

#if SPM_MM
	ARM_SPM_BUF_EL3_MMAP
#endif

#if SPM_MM
const mmap_region_t plat_arm_secure_partition_mmap[] = {
	V2M_MAP_IOFPGA_EL0, /* for the UART */
	V2M_MAP_SECURE_SYSTEMREG_EL0, /* for initializing flash */
#if PSA_FWU_SUPPORT
	V2M_MAP_FLASH0_RW_EL0, /* for firmware update service in standalone mm */
#endif
	V2M_MAP_FLASH1_RW_EL0, /* for secure variable service in standalone mm */
	MAP_REGION_FLAT(DEVICE0_BASE,
			DEVICE0_SIZE,
			MT_DEVICE | MT_RO | MT_SECURE | MT_USER),
	ARM_SP_IMAGE_MMAP,
	ARM_SP_IMAGE_NS_BUF_MMAP,
	ARM_SP_IMAGE_RW_MMAP,
	ARM_SPM_BUF_EL0_MMAP,
	{0}
};
/*
 * Boot information passed to a secure partition during initialisation. Linear
 * indices in MP information will be filled at runtime.
 */
static spm_mm_mp_info_t sp_mp_info[] = {
	[0] = {0x80000000, 0},
	[1] = {0x80000001, 0},
	[2] = {0x80000002, 0},
	[3] = {0x80000003, 0},
	[4] = {0x80000100, 0},
	[5] = {0x80000101, 0},
	[6] = {0x80000102, 0},
	[7] = {0x80000103, 0},
};

const spm_mm_boot_info_t plat_arm_secure_partition_boot_info = {
	.h.type              = PARAM_SP_IMAGE_BOOT_INFO,
	.h.version           = VERSION_1,
	.h.size              = sizeof(spm_mm_boot_info_t),
	.h.attr              = 0,
	.sp_mem_base         = ARM_SP_IMAGE_BASE,
	.sp_mem_limit        = ARM_SP_IMAGE_LIMIT,
	.sp_image_base       = ARM_SP_IMAGE_BASE,
	.sp_stack_base       = PLAT_SP_IMAGE_STACK_BASE,
	.sp_heap_base        = ARM_SP_IMAGE_HEAP_BASE,
	.sp_ns_comm_buf_base = PLAT_SP_IMAGE_NS_BUF_BASE,
	.sp_shared_buf_base  = PLAT_SPM_BUF_BASE,
	.sp_image_size       = ARM_SP_IMAGE_SIZE,
	.sp_pcpu_stack_size  = PLAT_SP_IMAGE_STACK_PCPU_SIZE,
	.sp_heap_size        = ARM_SP_IMAGE_HEAP_SIZE,
	.sp_ns_comm_buf_size = PLAT_SP_IMAGE_NS_BUF_SIZE,
	.sp_shared_buf_size  = PLAT_SPM_BUF_SIZE,
	.num_sp_mem_regions  = ARM_SP_IMAGE_NUM_MEM_REGIONS,
	.num_cpus            = PLATFORM_CORE_COUNT,
	.mp_info             = &sp_mp_info[0],
};

const struct mmap_region *plat_get_secure_partition_mmap(void *cookie)
{
	return plat_arm_secure_partition_mmap;
}

const struct spm_mm_boot_info *plat_get_secure_partition_boot_info(
		void *cookie)
{
	return &plat_arm_secure_partition_boot_info;
}
#endif