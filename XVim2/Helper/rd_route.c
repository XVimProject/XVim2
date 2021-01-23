// rd_route.c
// Copyright (c) 2014-2015 Dmitry Rodionov
//
// This software may be modified and distributed under the terms
// of the MIT license.  See the LICENSE file for details.

#include <stdlib.h>         // realloc()
#include <libgen.h>         // basename()
#include <assert.h>         // assert()
#include <stdio.h>          // fprintf()
#include <dlfcn.h>          // dladdr()

#include "TargetConditionals.h"
#if defined(__i386__) || defined(__x86_64__)
	#if !(TARGET_IPHONE_SIMULATOR)
		#include <mach/mach_vm.h> // mach_vm_*
	#else
		#include <mach/vm_map.h>  // vm_*
		#define mach_vm_address_t vm_address_t
		#define mach_vm_size_t vm_size_t
		#define mach_vm_allocate vm_allocate
		#define mach_vm_deallocate vm_deallocate
		#define mach_vm_write vm_write
		#define mach_vm_remap vm_remap
		#define mach_vm_protect vm_protect
		#define NSLookupSymbolInImage(...) ((void)0)
		#define NSAddressOfSymbol(...) ((void)0)
	#endif
#else
#endif

#include <mach-o/dyld.h>    // _dyld_*
#include <mach-o/nlist.h>   // nlist/nlist_64
#include <mach/mach_init.h> // mach_task_self()
#include "rd_route.h"

#define RDErrorLog(format, ...) fprintf(stderr, "%s:%d:\n\terror: "format"\n", \
	__FILE__, __LINE__, ##__VA_ARGS__)

#if defined(__x86_64__)
	typedef struct mach_header_64     mach_header_t;
	typedef struct segment_command_64 segment_command_t;
	#define LC_SEGMENT_ARCH_INDEPENDENT   LC_SEGMENT_64
	typedef struct nlist_64 nlist_t;
#else
	typedef struct mach_header        mach_header_t;
	typedef struct segment_command    segment_command_t;
	#define LC_SEGMENT_ARCH_INDEPENDENT   LC_SEGMENT
	typedef struct nlist nlist_t;
#endif

typedef struct rd_injection {
	mach_vm_address_t injected_mach_header;
	mach_vm_address_t target_address;
} rd_injection_t;

static void*          _function_ptr_within_image(const char *function_name, void *macho_image_header, uintptr_t vm_image_slide);

void* function_ptr_from_name(const char *function_name)
{
	assert(function_name);

	for (uint32_t i = 0; i < _dyld_image_count(); i++) {
		void *header = (void *)_dyld_get_image_header(i);
		uintptr_t vmaddr_slide = _dyld_get_image_vmaddr_slide(i);

		void *ptr = _function_ptr_within_image(function_name, header, vmaddr_slide);
		if (ptr) { return ptr; }
	}
	RDErrorLog("Failed to find symbol `%s` in the current address space.", function_name);

	return NULL;
}


static void* _function_ptr_within_image(const char *function_name, void *macho_image_header, uintptr_t vmaddr_slide)
{
	assert(function_name);
	assert(macho_image_header);
	/**
	 * Try the system NSLookup API to find out the function's pointer withing the specifed header.
	 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
	void *pointer_via_NSLookup = ({
		NSSymbol symbol = NSLookupSymbolInImage(macho_image_header, function_name,
			NSLOOKUPSYMBOLINIMAGE_OPTION_RETURN_ON_ERROR);
		NSAddressOfSymbol(symbol);
	});
#pragma clang diagnostic pop
	if (pointer_via_NSLookup) return pointer_via_NSLookup;

	return NULL;
}
