WORK_PATH=${HOME}/workdir
LIB_PATH=${WORK_PATH}/lib
INCLUDE_PATH=${WORK_PATH}/include
OBJ_PATH=${WORK_PATH}/obj

CXXFLAGS += -g -Wall -Wextra

TESTS=test_01

all : ${TESTS}

clean :
	rm -fr *.o ${TESTS}

test_01.o :
	$(CXX) -I$(INCLUDE_PATH) $(CXXFLAGS) -c test_01.cpp

test_01 : ${OBJ_PATH}/str_util.o ${OBJ_PATH}/gtest_main.o test_01.o
	$(CXX) -I$(INCLUDE_PATH) $(CXXFLAGS) $^ -o $@ -lpthread ${LIB_PATH}/libgtest.a
