#include "gtest/gtest.h"
#include "str_util.h"

TEST(TEST_BASE, case_01)
{
	char src[10] = "123456789";
	char dest[10];
	
	str_copy(dest, src);
	EXPECT_STREQ(dest, src);
}
