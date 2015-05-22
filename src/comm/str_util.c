#include "str_util.h"

void str_copy(char *dest, char *src)
{
	while(*src != '\0')
		*dest++ = *src++;
	*dest = '\0';
}
