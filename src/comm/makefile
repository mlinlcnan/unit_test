WORK_PATH=${HOME}/workdir
INCLUDE_PATH=${WORK_PATH}/include
OBJ_PATH=${WORK_PATH}/obj

CXXFLAGS += -g -Wall -Wextra

str_util.o : str_util.c $(INCLUDE_PATH)/str_util.h
	$(CXX) -I$(INCLUDE_PATH) $(CXXFLAGS) -c str_util.c

clean :
	rm -fr *.o
