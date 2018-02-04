! BoundaryCommunicator_CLASS.f90
!
! Copyright 2018 Joseph Schoonover <joe@fluidnumerics.consulting>, Fluid Numerics LLC
! All rights reserved.
!
! //////////////////////////////////////////////////////////////////////////////////////////////// !

MODULE BoundaryCommunicator_CLASS

! src/COMMON/
  USE ModelPrecision
  USE ConstantsDictionary
  USE commonroutines


  IMPLICIT NONE

#ifdef HAVE_MPI
  INCLUDE 'mpif.h'
#endif


! BoundaryCommunicator
! The BoundaryCommunicator CLASS provides a convenient package of attributes for implementing
! boundary conditions.
!
! This structure was motivated by the need for a robust means of implementing boundary conditions
! on an unstructured mesh. This CLASS makes it trivial to implement message-passing for
! MPI parallelism.
!

  TYPE BoundaryCommunicator
    INTEGER                               :: nBoundaries
    INTEGER, ALLOCATABLE                  :: extProcIDs(:)
    INTEGER, ALLOCATABLE                  :: boundaryIDs(:)
    INTEGER, ALLOCATABLE                  :: unPackMap(:)

#ifdef HAVE_MPI
    INTEGER :: myRank, nProc, nNeighbors
    INTEGER :: maxBufferSize
    INTEGER :: MPI_COMM, MPI_PREC, mpiErr

    INTEGER, ALLOCATABLE :: bufferMap(:)
    INTEGER, ALLOCATABLE :: neighborRank(:)
    INTEGER, ALLOCATABLE :: bufferSize(:)
    INTEGER, ALLOCATABLE :: rankTable(:)

#ifdef HAVE_CUDA
    INTEGER, DEVICE, ALLOCATABLE :: myRank_dev, nProc_dev, nNeighbors_dev
    INTEGER, DEVICE, ALLOCATABLE :: bufferMap_dev(:)
    INTEGER, DEVICE, ALLOCATABLE :: neighborRank_dev(:)
    INTEGER, DEVICE, ALLOCATABLE :: bufferSize_dev(:)
    INTEGER, DEVICE, ALLOCATABLE :: rankTable_dev(:)
#endif

#endif

  CONTAINS

    PROCEDURE :: Build => Build_BoundaryCommunicator
    PROCEDURE :: Trash => Trash_BoundaryCommunicator

    PROCEDURE :: ReadPickup  => ReadPickup_BoundaryCommunicator
    PROCEDURE :: WritePickup => WritePickup_BoundaryCommunicator

#ifdef HAVE_MPI
    PROCEDURE :: ConstructCommTables
#endif

  END TYPE BoundaryCommunicator

CONTAINS
!
!
!==================================================================================================!
!------------------------------- Manual Constructors/Destructors ----------------------------------!
!==================================================================================================!
!
!
!> \addtogroup BoundaryCommunicator_CLASS
!! @{
! ================================================================================================ !
! S/R Build
!
!> \fn Build_BoundaryCommunicator
!! Allocates space for the BoundaryCommunicator structure and initializes all array values to zero.
!!
!! <H2> Usage : </H2>
!! <B>TYPE</B>(BoundaryCommunicator) :: this <BR>
!! <B>INTEGER</B>                    :: nBe <BR>
!!         .... <BR>
!!     <B>CALL</B> this % Build( nBe ) <BR>
!!
!!  <H2> Parameters : </H2>
!!  <table>
!!   <tr> <td> out <th> myComm <td> BoundaryCommunicator <td>
!!   <tr> <td> in <th> N <td> INTEGER <td> Polynomial degree for the solution storage
!!   <tr> <td> in <th> nBe <td> INTEGER <td> The number of boundary edges in the mesh
!!  </table>
!!
! ================================================================================================ !
!>@}
  SUBROUTINE Build_BoundaryCommunicator( myComm, nBe )

    IMPLICIT NONE
    CLASS(BoundaryCommunicator), INTENT(inout) :: myComm
    INTEGER, INTENT(in)                      :: nBe

    myComm % nBoundaries = nBe

    ALLOCATE( myComm % extProcIDs(1:nBe) )
    ALLOCATE( myComm % boundaryIDs(1:nBe) )
    ALLOCATE( myComm % unPackMap(1:nBe) )

    myComm % extProcIDs  = 0
    myComm % boundaryIDs = 0
    myComm % unPackMap   = 0

#ifdef HAVE_MPI

    myComm % MPI_COMM = MPI_COMM_WORLD

    IF( prec == sp )THEN
      myComm % MPI_PREC = MPI_FLOAT
    ELSE
      myComm % MPI_PREC = MPI_DOUBLE
    ENDIF

    CALL MPI_INIT( myComm % mpiErr )
    CALL MPI_COMM_RANK( myComm % MPI_COMM, myComm % myRank, myComm % mpiErr )
    CALL MPI_COMM_SIZE( myComm % MPI_COMM, myComm % nProc, myComm % mpiErr )

    PRINT*, '    S/R Build_CommunicationTable : Greetings from Process ', myComm % myRank+1, ' of ', myComm % nProc

    ALLOCATE( myComm % bufferMap(1:myComm % nBoundaries), &
      myComm % rankTable(0:myComm % nProc-1) )

#ifdef HAVE_CUDA

    ALLOCATE( myComm % bufferMap_dev(1:myComm % nBoundaries), &
      myComm % rankTable_dev(0:myComm % nProc-1) )

#endif

#ifdef HAVE_CUDA

    ALLOCATE( myComm % myRank_dev, &
      myComm % nProc_dev, &
      myComm % nNeighbors_dev )

    myComm % myRank_dev      = myComm % myRank
    myComm % nProc_dev       = myComm % nProc
    myComm % nNeighbors_dev  = myComm % nNeighbors

#endif
#endif


  END SUBROUTINE Build_BoundaryCommunicator
!
!> \addtogroup BoundaryCommunicator_CLASS
!! @{
! ================================================================================================ !
! S/R Trash
!
!> \fn Trash_BoundaryCommunicator
!! Frees memory associated with the attributes of the BoundaryCommunicator DATA structure.
!!
!! <H2> Usage : </H2>
!! <B>TYPE</B>(BoundaryCommunicator) :: this <BR>
!!         .... <BR>
!!     <B>CALL</B> this % Trash( ) <BR>
!!
!!  <H2> Parameters : </H2>
!!  <table>
!!   <tr> <td> in/out <th> myComm <td> BoundaryCommunicator <td>
!!  </table>
!!
! ================================================================================================ !
!>@}
  SUBROUTINE Trash_BoundaryCommunicator( myComm )

    IMPLICIT NONE
    CLASS(BoundaryCommunicator), INTENT(inout) :: myComm

    DEALLOCATE( myComm % unPackMap, myComm % extProcIDs, myComm % boundaryIDs )

#ifdef HAVE_MPI

    DEALLOCATE( myComm % neighborRank, &
      myComm % bufferSize, &
      myComm % bufferMap, &
      myComm % rankTable )

#ifdef HAVE_CUDA

    DEALLOCATE( myComm % neighborRank_dev, &
      myComm % bufferSize_dev, &
      myComm % bufferMap_dev, &
      myComm % rankTable_dev )

#endif

    CALL MPI_FINALIZE( myComm % mpiErr )

#endif

  END SUBROUTINE Trash_BoundaryCommunicator
!
!
!==================================================================================================!
!-------------------------------------- FILE I/O ROUTINES -----------------------------------------!
!==================================================================================================!
!
!
!> \addtogroup BoundaryCommunicator_CLASS
!! @{
! ================================================================================================ !
! S/R WritePickup
!
!> \fn WritePickup_BoundaryCommunicator
!! Writes pickup files for the BoundaryCommunicator DATA structure.
!!
!! Given a file-name base (e.g. "foo"), this routine generates "foo.bcm" (2)
!! The .bcm file CONTAINS the boundary edge, external element, and external process information.
!! The file is an ASCII file.
!!
!! <H2> Usage : </H2>
!! <B>TYPE</B>(BoundaryCommunicator) :: this <BR>
!! <B>CHARACTER</B>                  :: filename
!!         .... <BR>
!!     <B>CALL</B> this % WritePickup( filename ) <BR>
!!
!!  <H2> Parameters : </H2>
!!  <table>
!!   <tr> <td> in <th> myComm <td> BoundaryCommunicator <td> Previously constructed boundary-
!!                               communicator DATA structure
!!   <tr> <td> in <th> filename <td> CHARACTER <td> File base-name for the pickup files
!!  </table>
!!
! ================================================================================================ !
!>@}
  SUBROUTINE WritePickup_BoundaryCommunicator( myComm, filename )

    IMPLICIT NONE
    CLASS( BoundaryCommunicator ), INTENT(in) :: myComm
    CHARACTER(*), INTENT(in)                     :: filename
    ! LOCAL
    INTEGER       :: i, fUnit


    OPEN( UNIT   = NEWUNIT(fUnit), &
      FILE   = TRIM(filename)//'.bcm', &
      FORM   ='FORMATTED',&
      ACCESS ='SEQUENTIAL',&
      STATUS ='REPLACE',&
      ACTION ='WRITE' )

    WRITE( fUnit, * ) myComm % nBoundaries

    DO i = 1, myComm % nBoundaries

      WRITE( fUnit, * ) myComm % boundaryIDs(i), &
        myComm % extProcIDs(i), &
        myComm % unPackMap(i)

    ENDDO

    CLOSE(fUnit)


  END SUBROUTINE WritePickup_BoundaryCommunicator
!
!> \addtogroup BoundaryCommunicator_CLASS
!! @{
! ================================================================================================ !
! S/R ReadPickup
!
!> \fn ReadPickup_BoundaryCommunicator
!! Reads pickup files for the BoundaryCommunicator DATA structure.
!!
!! Given a file-name base (e.g. "foo"), this routine reads "foo.bcm"
!! The .bcm file CONTAINS the boundary edge, external element, and external process information.
!! The file is an ASCII file.
!!
!! <H2> Usage : </H2>
!! <B>TYPE</B>(BoundaryCommunicator) :: this <BR>
!! <B>CHARACTER</B>                     :: filename
!!         .... <BR>
!!     <B>CALL</B> this % ReadPickup( filename ) <BR>
!!
!!  <H2> Parameters : </H2>
!!  <table>
!!   <tr> <td> out <th> myComm <td> BoundaryCommunicator <td> Previously constructed boundary-
!!                               communicator DATA structure
!!   <tr> <td> in <th> filename <td> CHARACTER <td> File base-name for the pickup files
!!  </table>
!!
! ================================================================================================ !
!>@}
  SUBROUTINE ReadPickup_BoundaryCommunicator( myComm, filename )

    IMPLICIT NONE
    CLASS( BoundaryCommunicator ), INTENT(inout) :: myComm
    CHARACTER(*), INTENT(in)                     :: filename
    ! LOCAL
    INTEGER       :: i
    INTEGER       :: fUnit
    INTEGER       :: nBe


    !PRINT *, 'S/R ReadPickup : Reading "'//TRIM(filename)//'.bcm"'

    OPEN( UNIT   = NEWUNIT(fUnit), &
      FILE   = TRIM(filename)//'.bcm', &
      FORM   ='FORMATTED',&
      ACCESS ='SEQUENTIAL',&
      STATUS ='OLD',&
      ACTION ='READ' )

    READ( fUnit, * ) nBe

    CALL myComm % Build( nBe )

    DO i = 1, myComm % nBoundaries

      READ( fUnit, * ) myComm % boundaryIDs(i), &
        myComm % extProcIDs(i), &
        myComm % unPackMap(i)

    ENDDO

    CLOSE(fUnit)

  END SUBROUTINE ReadPickup_BoundaryCommunicator
!
#ifdef HAVE_MPI
  SUBROUTINE ConstructCommTables( myComm )

    IMPLICIT NONE
    CLASS( BoundaryCommunicator ), INTENT(inout) :: myComm
    ! Local
    INTEGER, ALLOCATABLE :: bufferCounter(:)
    INTEGER :: sharedFaceCount(0:myComm % nProc-1)
    INTEGER :: IFace, bID, iNeighbor
    INTEGER :: tag, ierror
    INTEGER :: e1, e2, s1, p2, nmsg, maxFaceCount
    INTEGER :: fUnit


    ! Count up the number of neighboring ranks
    myComm % rankTable = 0
    sharedFaceCount     = 0
    DO bID = 1, myComm % nBoundaries

      p2 = myComm % extProcIDS(bID)

      IF( p2 /= myComm % myRank )THEN

        myComm % rankTable(p2) = 1
        sharedFaceCount(p2) = sharedFaceCount(p2)+1

      ENDIF

    ENDDO


    myComm % nNeighbors = SUM( myComm % rankTable )
    PRINT*, '  S/R ConstructCommTables : Found', myComm % nNeighbors, 'neighbors for Rank', myComm % myRank+1

    ALLOCATE( myComm % neighborRank(1:myComm % nNeighbors), &
      myComm % bufferSize(1:myComm % nNeighbors), &
      bufferCounter(1:myComm % nNeighbors) )


    ! For each neighbor, set the neighbor's rank
    iNeighbor = 0
    DO p2 = 0, myComm % nProc-1

      IF( myComm % rankTable(p2) == 1 )THEN

        iNeighbor = iNeighbor + 1
        myComm % neighborRank(iNeighbor) = p2
        myComm % rankTable(p2) = iNeighbor

      ENDIF

    ENDDO


    maxFaceCount = MAXVAL( sharedFaceCount )
    DO iNeighbor = 1, myComm % nNeighbors

      p2 = myComm % neighborRank(iNeighbor)
      myComm % bufferSize(iNeighbor) = sharedFaceCount(p2)

    ENDDO


    myComm % maxBufferSize = maxFaceCount
    bufferCounter = 0



    myComm % bufferMap = 0

    DO bID = 1, myComm % nBoundaries

      p2 = myComm % extProcIDs(bID)

      ! In the event that the external process ID (p2) is identical to the current rank (p1),
      ! THEN this boundary edge involves a physical boundary condition and DOes not require a
      ! message exchange

      IF( p2 /= myComm % myRank )THEN

        iNeighbor = myComm % rankTable(p2)

        bufferCounter(iNeighbor) = bufferCounter(iNeighbor) + 1
        myComm % bufferMap(bID)   = bufferCounter(iNeighbor)

      ENDIF

    ENDDO

    DEALLOCATE( bufferCounter )

#ifdef HAVE_CUDA
    ALLOCATE( myComm % neighborRank_dev(1:myComm % nNeighbors), &
      myComm % bufferSize_dev(1:myComm % nNeighbors) )

    myComm % rankTable_dev    = myComm % rankTable
    myComm % neighborRank_dev = myComm % neighborRank
    myComm % bufferSize_dev   = myComm % bufferSize
    myComm % bufferMap_dev    = myComm % bufferMap
#endif

  END SUBROUTINE ConstructCommTables
#endif

END MODULE BoundaryCommunicator_CLASS
