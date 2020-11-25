

FC=/opt/hipfort/bin/hipfc
CXX=/opt/rocm/bin/hipcc
FFLAGS=-DGPU -ffree-line-length-none
FLIBS=-L/apps/flap/lib/ -lFLAP -lFACE -lPENF -L/opt/feqparse/lib -lfeqparse
INC=-I/apps/flap/include/FLAP -I/apps/flap/include/PENF -I/apps/flap/include/FACE -I/opt/feqparse/include
CXXFLAGS=
PREFIX=/apps/self

install: libSELF.a self
	mkdir -p ${PREFIX}/bin
	mkdir -p ${PREFIX}/lib
	mkdir -p ${PREFIX}/include
	mv libSELF.a ${PREFIX}/lib/
	mv *.mod ${PREFIX}/include/
	cp src/*.h ${PREFIX}/include/
	mv self ${PREFIX}/bin/
	rm *.o

self: SELF.o
	${FC} ${FFLAGS} ${INC} -I./src/ *.o  ${FLIBS} -o $@

SELF.o: libSELF.a
	${FC} -c ${FFLAGS} ${INC} -I./src/ ${FLIBS} src/SELF.F90 -o $@

libSELF.a: SELF_Constants.o SELF_Data.o SELF_Lagrange_HIP.o SELF_Lagrange.o SELF_MappedData_HIP.o SELF_MappedData.o SELF_Memory.o SELF_Mesh.o SELF_Quadrature.o SELF_SupportRoutines.o SELF_Tests.o
	ar rcs $@ SELF_Constants.o SELF_Data.o SELF_Lagrange_HIP.o SELF_Lagrange.o SELF_MappedData_HIP.o SELF_MappedData.o SELF_Memory.o SELF_Mesh.o SELF_Quadrature.o SELF_SupportRoutines.o SELF_Tests.o

SELF_Tests.o: SELF_Constants.o SELF_Data.o SELF_Lagrange_HIP.o SELF_Lagrange.o SELF_MappedData_HIP.o SELF_MappedData.o SELF_Memory.o SELF_Mesh.o SELF_Quadrature.o SELF_SupportRoutines.o
	${FC} -c ${FFLAGS} ${INC} ${FLIBS} src/SELF_Tests.F90 -o $@

#SELF_MPILayer.o: SELF_MPILayer.F90

SELF_MappedData.o: SELF_Mesh.o SELF_Data.o
	${FC} -c ${FFLAGS} ${INC} ${FLIBS} src/SELF_MappedData.F90 -o $@

SELF_MappedData_HIP.o:
	${CXX} -c ${CXXFLAGS} src/SELF_MappedData_HIP.cpp -o $@

SELF_Mesh.o: SELF_Data.o SELF_Lagrange.o
	${FC} -c ${FFLAGS} ${INC} ${FLIBS} src/SELF_Mesh.F90 -o $@

SELF_Data.o: SELF_Lagrange.o SELF_Constants.o
	${FC} -c ${FFLAGS} ${INC} ${FLIBS} src/SELF_Data.F90 -o $@

SELF_Lagrange.o: SELF_Memory.o SELF_Quadrature.o SELF_Constants.o SELF_SupportRoutines.o
	${FC} -c ${FFLAGS} ${INC} ${FLIBS} src/SELF_Lagrange.F90 -o $@

SELF_Lagrange_HIP.o:
	${CXX} -c ${CXXFLAGS} src/SELF_Lagrange_HIP.cpp -o $@

SELF_Quadrature.o: SELF_Constants.o
	${FC} -c ${FFLAGS} ${INC} ${FLIBS} src/SELF_Quadrature.F90 -o $@

SELF_Memory.o:
	${FC} -c ${FFLAGS} ${INC} ${FLIBS} src/SELF_Memory.F90 -o $@

SELF_SupportRoutines.o: SELF_Constants.o
	${FC} -c ${FFLAGS} ${INC} ${FLIBS} src/SELF_SupportRoutines.F90 -o $@

SELF_Constants.o:
	${FC} -c ${FFLAGS} ${INC} ${FLIBS} src/SELF_Constants.F90 -o $@
