#include <inttypes.h>
#include <stdio.h>

#include "answer.h"

int
main(const int argc, const char *argv[])
{
	uint_fast16_t u16 = 42;
	int ret = answer();
	if (ret == u16) {
		printf("%" PRIdFAST32 " == %d\n", u16, ret);
	}
	return ret;
}
