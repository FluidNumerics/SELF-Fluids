MODULE SELF_Mesh

  USE SELF_Constants
  USE SELF_Lagrange
  USE SELF_Data
  USE SELF_SupportRoutines

  USE ISO_C_BINDING

  IMPLICIT NONE

#include "SELF_Macros.h"
! ========================================================================= !
! Node, Edge, Face, Element and Connectivity Standard
! ========================================================================= !
!
! To define the element corner nodes, the side order and side connectivity,
! we follow the standard from CGNS SIDS (CFD General Notation System,
! Standard Interface Data Structures, http: //cgns.sourceforge.net/ ).
!
! Computational coordinate directions are defined as follows
!
! xi1 direction points from "West" (xi1=-1) to "East" (xi1=1)
! xi2 direction points from "South" (xi2=-1) to "North" (xi2=1)
! xi3 direction points from "Bottom" (xi3=-1) to "Top" (xi3=1)
!
! 2-D Hexahedreal Element sides are defined as
!
! Side 1 = South  (xi2 = -1) = [CN1, CN2]
! Side 2 = East   (xi1 = 1) = [CN2, CN3]
! Side 3 = North  (xi2 = 1) = [CN4, CN3]
! Side 4 = West   (xi1 = -1) = [CN1, CN4]
!
! 3-D Hexahedreal Element sides are defined as
!
! Side 1 = Bottom (xi3 = -1) = [CN1, CN4, CN3, CN2]
! Side 2 = South  (xi2 = -1) = [CN1, CN2, CN6, CN5]
! Side 3 = East   (xi1 = 1) = [CN2, CN3, CN7, CN6]
! Side 4 = North  (xi2 = 1) = [CN3, CN4, CN8, CN7]
! Side 5 = West   (xi1 = -1) = [CN1, CN5, CN8, CN4]
! Side 6 = Top    (xi3 = 1) = [CN5, CN6, CN7, CN8]
!
! In 2-D, corner nodes are order counter-clockwise (looking in the -xi3 direction).
!
! CornerNode 1 = South-West = (-1,-1)
! CornerNode 2 = South-East = ( 1,-1)
! CornerNode 3 = North-East = ( 1, 1)
! CornerNode 4 = North-West = (-1, 1)
!
! In 3-D, corner nodes are order counter-clockwise (looking in the -xi3 direction) from
! bottom to top.
!
! CornerNode 1 = Bottom-South-West = (-1,-1,-1)
! CornerNode 2 = Bottom-South-East = ( 1,-1,-1)
! CornerNode 3 = Bottom-North-East = ( 1, 1,-1)
! CornerNode 4 = Bottom-North-West = (-1, 1,-1)
! CornerNode 5 = Top-South-West = (-1,-1, 1)
! CornerNode 6 = Top-South-East = ( 1,-1, 1)
! CornerNode 7 = Top-North-East = ( 1, 1, 1)
! CornerNode 8 = Top-North-West = (-1, 1, 1)
!
!
! Notes:
!  * cornerNode attributes have not been implemented yet
!
!  * For line segments, quads, and hexes, Gauss-Lobatto quadrature is required
!
! ========================================================================= !

  ! Element Types - From Table 4.1 of https://www.hopr-project.org/externals/Meshformat.pdf
  INTEGER,PARAMETER :: selfLineLinear = 1
  INTEGER,PARAMETER :: selfLineNonlinear = 2
  INTEGER,PARAMETER :: selfTriangleLinear = 3
  INTEGER,PARAMETER :: selfQuadLinear = 4
  INTEGER,PARAMETER :: selfQuadBilinear = 14
  INTEGER,PARAMETER :: selfTriangleNonlinear = 23
  INTEGER,PARAMETER :: selfQuadNonlinear = 24
  INTEGER,PARAMETER :: selfTetrahedronLinear = 104
  INTEGER,PARAMETER :: selfPyramidLinear = 105
  INTEGER,PARAMETER :: selfPrismLinear = 106
  INTEGER,PARAMETER :: selfHexahedronLinear = 108
  INTEGER,PARAMETER :: selfPyramidBilinear = 115
  INTEGER,PARAMETER :: selfPrismBilinear = 116
  INTEGER,PARAMETER :: selfHexahedronBilinear = 118
  INTEGER,PARAMETER :: selfTetrahedronNonlinear = 204
  INTEGER,PARAMETER :: selfPyramidNonlinear = 205
  INTEGER,PARAMETER :: selfPrismNonlinear = 206
  INTEGER,PARAMETER :: selfHexahedronNonlinear = 208

  !
  INTEGER,PARAMETER :: selfMinNodalValence2D = 4
  INTEGER,PARAMETER :: selfMinNodalValence3D = 8
  INTEGER,PARAMETER :: selfMaxNodalValence2D = 6
  INTEGER,PARAMETER :: selfMaxNodalValence3D = 10
  ! Side Ordering
  INTEGER,PARAMETER :: selfSide2D_South = 1
  INTEGER,PARAMETER :: selfSide2D_East = 2
  INTEGER,PARAMETER :: selfSide2D_North = 3
  INTEGER,PARAMETER :: selfSide2D_West = 4
  INTEGER,PARAMETER :: selfSide3D_Bottom = 1
  INTEGER,PARAMETER :: selfSide3D_South = 2
  INTEGER,PARAMETER :: selfSide3D_East = 3
  INTEGER,PARAMETER :: selfSide3D_North = 4
  INTEGER,PARAMETER :: selfSide3D_West = 5
  INTEGER,PARAMETER :: selfSide3D_Top = 6

  TYPE,PUBLIC :: Mesh1D
    INTEGER :: nGeo
    INTEGER :: nElem
    INTEGER :: nNodes
    INTEGER :: nCornerNodes
    INTEGER :: nUniqueNodes
    INTEGER :: nBCs
    TYPE(hfInt32_r2) :: elemInfo
    TYPE(hfReal_r1) :: nodeCoords
    TYPE(hfReal_r1) :: globalNodeIDs
    TYPE(hfInt32_r2) :: BCType
    CHARACTER(LEN=255),ALLOCATABLE :: BCNames(:)

  CONTAINS
    PROCEDURE,PUBLIC :: Init => Init_Mesh1D
    PROCEDURE,PUBLIC :: Free => Free_Mesh1D
    PROCEDURE,PUBLIC :: UpdateHost => UpdateHost_Mesh1D
    PROCEDURE,PUBLIC :: UpdateDevice => UpdateDevice_Mesh1D
    PROCEDURE,PUBLIC :: UniformBlockMesh => UniformBlockMesh_Mesh1D

  END TYPE Mesh1D

  ! Mesh format is set up as the HOPr format
  ! See https://hopr-project.org/externals/MeshFormat.pdf

  TYPE,PUBLIC :: Mesh2D
    INTEGER :: nGeo
    INTEGER :: nElem
    INTEGER :: nNodes
    INTEGER :: nSides
    INTEGER :: nCornerNodes
    INTEGER :: nUniqueNodes
    INTEGER :: nUniqueSides
    INTEGER :: nBCs
    TYPE(hfInt32_r2) :: elemInfo
    TYPE(hfInt32_r2) :: sideInfo
    TYPE(hfReal_r2) :: nodeCoords
    TYPE(hfReal_r1) :: globalNodeIDs
    TYPE(hfInt32_r1) :: CGNSCornerMap
    TYPE(hfInt32_r2) :: CGNSSideMap
    TYPE(hfInt32_r2) :: curveNodeMap
    TYPE(hfInt32_r2) :: curveNodeMapInv
    TYPE(hfInt32_r2) :: BCType
    CHARACTER(LEN=255),ALLOCATABLE :: BCNames(:)

  CONTAINS
    PROCEDURE,PUBLIC :: Init => Init_Mesh2D
    PROCEDURE,PUBLIC :: Free => Free_Mesh2D
    PROCEDURE,PUBLIC :: UpdateHost => UpdateHost_Mesh2D
    PROCEDURE,PUBLIC :: UpdateDevice => UpdateDevice_Mesh2D
    PROCEDURE,PUBLIC :: UniformBlockMesh => UniformBlockMesh_Mesh2D

!    PROCEDURE, PUBLIC :: GenerateConnectivity => GenerateConnectivity_Mesh2D

  END TYPE Mesh2D

  TYPE,PUBLIC :: Mesh3D
    INTEGER :: nGeo
    INTEGER :: nElem
    INTEGER :: nNodes
    INTEGER :: nSides
    INTEGER :: nCornerNodes
    INTEGER :: nUniqueNodes
    INTEGER :: nUniqueSides
    INTEGER :: nBCs
    TYPE(hfInt32_r2) :: elemInfo
    TYPE(hfInt32_r2) :: sideInfo
    TYPE(hfReal_r2) :: nodeCoords
    TYPE(hfReal_r1) :: globalNodeIDs
    TYPE(hfInt32_r1) :: CGNSCornerMap
    TYPE(hfInt32_r2) :: CGNSSideMap
    TYPE(hfInt32_r2) :: curveNodeMap
    TYPE(hfInt32_r3) :: curveNodeMapInv
    TYPE(hfInt32_r2) :: BCType
    CHARACTER(LEN=255),ALLOCATABLE :: BCNames(:)

  CONTAINS

    PROCEDURE,PUBLIC :: Init => Init_Mesh3D
    PROCEDURE,PUBLIC :: Free => Free_Mesh3D
    PROCEDURE,PUBLIC :: UpdateHost => UpdateHost_Mesh3D
    PROCEDURE,PUBLIC :: UpdateDevice => UpdateDevice_Mesh3D
    PROCEDURE,PUBLIC :: UniformBlockMesh => UniformBlockMesh_Mesh3D

!      PROCEDURE, PUBLIC :: LoadHOPRMesh => LoadHOPRMesh_3D
!
!      PROCEDURE, PUBLIC :: Read_CGNSMesh
!      PROCEDURE, PUBLIC :: Read_UCDMesh
!      PROCEDURE, PUBLIC :: Read_TrellisUCDMesh
!
!    PROCEDURE, PUBLIC :: GenerateConnectivity => GenerateConnectivity_Mesh3D

  END TYPE Mesh3D

CONTAINS

  SUBROUTINE Init_Mesh1D(myMesh,nGeo,nElem,nNodes,nBCs)
    IMPLICIT NONE
    CLASS(Mesh1D),INTENT(out) :: myMesh
    INTEGER,INTENT(in) :: nGeo
    INTEGER,INTENT(in) :: nElem
    INTEGER,INTENT(in) :: nNodes
    INTEGER,INTENT(in) :: nBCs

    myMesh % nGeo = nGeo
    myMesh % nElem = nElem
    myMesh % nNodes = nNodes
    myMesh % nCornerNodes = nElem*2
    myMesh % nUniqueNodes = 0
    myMesh % nBCs = nBCs

    CALL myMesh % elemInfo % Alloc(loBound=(/1,1/), &
                                   upBound=(/4,nElem/))

    CALL myMesh % nodeCoords % Alloc(loBound=1, &
                                     upBound=nNodes)

    CALL myMesh % globalNodeIDs % Alloc(loBound=1, &
                                        upBound=nNodes)

    CALL myMesh % BCType % Alloc(loBound=(/1,1/), &
                                 upBound=(/4,nBCs/))

    ALLOCATE (myMesh % BCNames(1:nBCs))

  END SUBROUTINE Init_Mesh1D

  SUBROUTINE Free_Mesh1D(myMesh)
    IMPLICIT NONE
    CLASS(Mesh1D),INTENT(inout) :: myMesh

    myMesh % nElem = 0
    myMesh % nNodes = 0
    myMesh % nCornerNodes = 0
    myMesh % nUniqueNodes = 0
    myMesh % nBCs = 0

    CALL myMesh % elemInfo % Free()
    CALL myMesh % nodeCoords % Free()
    CALL myMesh % globalNodeIDs % Free()
    CALL myMesh % BCType % Free()

    DEALLOCATE (myMesh % BCNames)

  END SUBROUTINE Free_Mesh1D
  SUBROUTINE UpdateHost_Mesh1D(myMesh)
    IMPLICIT NONE
    CLASS(Mesh1D),INTENT(inout) :: myMesh

#ifdef GPU
    CALL myMesh % elemInfo % UpdateHost()
    CALL myMesh % nodeCoords % UpdateHost()
    CALL myMesh % globalNodeIDs % UpdateHost()
    CALL myMesh % BCType % UpdateHost()
#endif

  END SUBROUTINE UpdateHost_Mesh1D

  SUBROUTINE UpdateDevice_Mesh1D(myMesh)
    IMPLICIT NONE
    CLASS(Mesh1D),INTENT(inout) :: myMesh

#ifdef GPU
    CALL myMesh % elemInfo % UpdateDevice()
    CALL myMesh % nodeCoords % UpdateDevice()
    CALL myMesh % globalNodeIDs % UpdateDevice()
    CALL myMesh % BCType % UpdateDevice()
#endif

  END SUBROUTINE UpdateDevice_Mesh1D

  SUBROUTINE UniformBlockMesh_Mesh1D(myMesh,nGeo,nElem,x)
    IMPLICIT NONE
    CLASS(Mesh1D),INTENT(out) :: myMesh
    INTEGER,INTENT(in) :: nGeo
    INTEGER,INTENT(in) :: nElem
    REAL(prec),INTENT(in) :: x(1:2)
    ! Local
    INTEGER :: iel
    INTEGER :: nid,nNodes
    INTEGER :: i
    REAL(prec) :: xU(1:nElem + 1)
    TYPE(Scalar1D) :: xLinear
    TYPE(Scalar1D) :: xGeo

    nNodes = nElem*(nGeo + 1)
    CALL myMesh % Init(nGeo,nElem,nNodes,2)

    ! Set the nodeCoords
    xU = UniformPoints(x(1),x(2),1,nElem + 1)

    ! Create a linear interpolant to interpolate to nGeo grid
    CALL xLinear % Init(1,GAUSS_LOBATTO, &
                        nGeo,GAUSS_LOBATTO, &
                        1,nElem)

    CALL xGeo % Init(nGeo,GAUSS_LOBATTO, &
                     nGeo,GAUSS_LOBATTO, &
                     1,nElem)
    DO iel = 1,nElem
      xLinear % interior % hostData(0:1,1,iel) = xU(iel:iel + 1)
    END DO

    CALL xLinear % GridInterp(xGeo,.FALSE.)

    ! Set the element information
    nid = 1
    DO iel = 1,nElem
      myMesh % eleminfo % hostData(1,iel) = selfLineLinear ! Element Type
      myMesh % eleminfo % hostData(2,iel) = 1 ! Element Zone
      myMesh % eleminfo % hostData(3,iel) = nid ! Node Index Start
      DO i = 0,nGeo
        myMesh % nodeCoords % hostData(nid) = xGeo % interior % hostData(i,1,iel)
        nid = nid + 1
      END DO
      myMesh % eleminfo % hostData(4,iel) = nid - 1 ! Node Index End
    END DO

    CALL myMesh % UpdateDevice()

    CALL xLinear % Free()
    CALL xGeo % Free()

  END SUBROUTINE UniformBlockMesh_Mesh1D

  SUBROUTINE Init_Mesh2D(myMesh,nGeo,nElem,nSides,nNodes,nBCs)
    IMPLICIT NONE
    CLASS(Mesh2D),INTENT(out) :: myMesh
    INTEGER,INTENT(in) :: nGeo
    INTEGER,INTENT(in) :: nElem
    INTEGER,INTENT(in) :: nSides
    INTEGER,INTENT(in) :: nNodes
    INTEGER,INTENT(in) :: nBCs
    ! Local
    INTEGER :: i,j,l

    myMesh % nGeo = nGeo
    myMesh % nElem = nElem
    myMesh % nNodes = nNodes
    myMesh % nSides = nSides
    myMesh % nCornerNodes = 0
    myMesh % nUniqueNodes = 0
    myMesh % nUniqueSides = 0
    myMesh % nBCs = nBCs

    CALL myMesh % elemInfo % Alloc(loBound=(/1,1/), &
                                   upBound=(/6,nElem/))

    CALL myMesh % sideInfo % Alloc(loBound=(/1,1/), &
                                   upBound=(/5,nSides/))

    CALL myMesh % nodeCoords % Alloc(loBound=(/1,1/), &
                                     upBound=(/2,nNodes/))

    CALL myMesh % globalNodeIDs % Alloc(loBound=1, &
                                        upBound=nNodes)

    CALL myMesh % CGNSCornerMap % Alloc(loBound=1, &
                                        upBound=4)

    CALL myMesh % CGNSSideMap % Alloc(loBound=(/1,1/), &
                                      upBound=(/2,4/))

    CALL myMesh % curveNodeMap % Alloc(loBound=(/1,1/),&
                                       upBound=(/2,(nGeo+1)**2/))

    CALL myMesh % curveNodeMapInv % Alloc(loBound=(/0,0/), &
                                          upBound=(/nGeo,nGeo/))

    CALL myMesh % BCType % Alloc(loBound=(/1,1/), &
                                 upBound=(/4,nBCs/))

    ALLOCATE (myMesh % BCNames(1:nBCs))

    ! Create lookup tables to assist with connectivity generation
    myMesh % CGNSCornerMap % hostData(1) = 1
    myMesh % CGNSCornerMap % hostData(2) = nGeo+1
    myMesh % CGNSCornerMap % hostData(3) = (nGeo+1)**2
    myMesh % CGNSCornerMap % hostData(4) = nGeo*(nGeo+1)+1

    DO j = 0, nGeo
      DO i = 0, nGeo
        l = l+1
        myMesh % curveNodeMap % hostData(1:2,l) = (/i,j/)
        myMesh % curveNodeMapInv % hostData(i,j) = l
      ENDDO
    ENDDO

    ! Maps from local corner node id to CGNS side
    myMesh % CGNSSideMap % hostData(1:2,1) = (/1,2/)
    myMesh % CGNSSideMap % hostData(1:2,2) = (/2,3/)
    myMesh % CGNSSideMap % hostData(1:2,3) = (/4,3/)
    myMesh % CGNSSideMap % hostData(1:2,4) = (/1,4/)

  END SUBROUTINE Init_Mesh2D

  SUBROUTINE Free_Mesh2D(myMesh)
    IMPLICIT NONE
    CLASS(Mesh2D),INTENT(inout) :: myMesh

    myMesh % nElem = 0
    myMesh % nNodes = 0
    myMesh % nSides = 0
    myMesh % nCornerNodes = 0
    myMesh % nUniqueSides = 0
    myMesh % nUniqueNodes = 0
    myMesh % nBCs = 0

    CALL myMesh % elemInfo % Free()
    CALL myMesh % sideInfo % Free()
    CALL myMesh % nodeCoords % Free()
    CALL myMesh % CGNSCornerMap % Free()
    CALL myMesh % globalNodeIDs % Free()
    CALL myMesh % BCType % Free()

    DEALLOCATE (myMesh % BCNames)

  END SUBROUTINE Free_Mesh2D

  SUBROUTINE UpdateHost_Mesh2D(myMesh)
    IMPLICIT NONE
    CLASS(Mesh2D),INTENT(inout) :: myMesh

#ifdef GPU
    CALL myMesh % elemInfo % UpdateHost()
    CALL myMesh % sideInfo % UpdateHost()
    CALL myMesh % nodeCoords % UpdateHost()
    CALL myMesh % globalNodeIDs % UpdateHost()
    CALL myMesh % BCType % UpdateHost()
#endif

  END SUBROUTINE UpdateHost_Mesh2D

  SUBROUTINE UpdateDevice_Mesh2D(myMesh)
    IMPLICIT NONE
    CLASS(Mesh2D),INTENT(inout) :: myMesh

#ifdef GPU
    CALL myMesh % elemInfo % UpdateDevice()
    CALL myMesh % sideInfo % UpdateDevice()
    CALL myMesh % nodeCoords % UpdateDevice()
    CALL myMesh % globalNodeIDs % UpdateDevice()
    CALL myMesh % BCType % UpdateDevice()
#endif

  END SUBROUTINE UpdateDevice_Mesh2D

!  SUBROUTINE GenerateConnectivity_Mesh2D(myMesh)
!  ! Create the sideInfo information given eleminfo
!  !  > Assumes quadrilateral mesh in 2-D
!  !  > Assumes hexahedral mesh in 3-D
!    IMPLICIT NONE
!    CLASS(Mesh2D),INTENT(inout) :: myMesh
!
!    ! Find matching nodes
!    DO 
!    ! SideInfo
!    !
!    !  SideType : Side Type encoding. The number of corner nodes is the last digit.
!    !  GlobalSideID : Unique side ID global identifier
!    !
!    !  nbElemID : Neighbor Element ID
!    !
!    !  10*nbLocSide+Flip : first digit - local side of the connected neighbor element; last digit - Orientation between the sides
!    !  (flip in [0,2])
!    !
!    !  BCID : Refers to the row index of the Boundary Condition List in BCNames/BCType array (in [1,nBCs]); = 0 for inner sides
!
!    ! Nodes are assumed to be defined on gauss-lobatto points - This allows us to check if nodes are the same along boundary
!    ! edges/faces
!
!    ! Loop over elements,
!    !   > Loop over local nodes    
!    !     > Loop over elements up to current element minus 1
!    !       > Loop over local nodes
!    !         > Check for match with previous node
!    !         > IF MATCH
!    !           > Update Global Node ID to matched node Global Node ID
!    !         > ELSE
!    !           > Assign new global node id
!
!    ! Loop over elements,
!    !   > Loop over local sides
!    !     > Assign side type (Assume line in 2-D)
!    !     > Set nbElemID = current element ID
!    !     > Set "current local side" as nbLocalSideID, "0" orientiation 
!    !     > Set the BCID = 0
!    !     > Save nodelist for this side
!    !
!    !   > Loop over elements up to current element minus 1
!    !      > Check for match with previous side
!    !      > IF MATCH
!    !        > Update Global ID of secondary element
!    !        > Set nbElemID for both elements; nbElemID of primary element is secondary element ID and vice-versa.
!    !        > Set nbLocalSideID for local side of neighboring element (
!    !        > Update "Flip" of secondary element, relative to primary element
!
!
!  END SUBROUTINE GenerateConnectivity_Mesh2D

  SUBROUTINE UniformBlockMesh_Mesh2D(myMesh,nGeo,nElem,x)
    IMPLICIT NONE
    CLASS(Mesh2D),INTENT(out) :: myMesh
    INTEGER,INTENT(in) :: nGeo
    INTEGER,INTENT(in) :: nElem(1:2)
    REAL(prec),INTENT(in) :: x(1:4)
    ! Local
    INTEGER :: iel,jel,nEl,elid
    INTEGER :: sid,nid,nNodes
    INTEGER :: nSides
    INTEGER :: i,j
    REAL(prec) :: xU(1:nElem(1) + 1)
    REAL(prec) :: yU(1:nElem(2) + 1)
    TYPE(Vector2D) :: xLinear
    TYPE(Vector2D) :: xGeo

    nEl = nElem(1)*nElem(2)
    nNodes = nel*(nGeo + 1)*(nGeo + 1)
    nSides = (nElem(1) + 1)*nElem(2) + (nElem(2) + 1)*nElem(1)
    CALL myMesh % Init(nGeo,nEl,nSides,nNodes,1)

    ! Set the nodeCoords
    xU = UniformPoints(x(1),x(2),1,nElem(1) + 1)
    yU = UniformPoints(x(3),x(4),1,nElem(2) + 1)

    ! Create a linear interpolant to interpolate to nGeo grid
    CALL xLinear % Init(1,GAUSS_LOBATTO, &
                        nGeo,GAUSS_LOBATTO, &
                        1,nEl)

    CALL xGeo % Init(nGeo,GAUSS_LOBATTO, &
                     nGeo,GAUSS_LOBATTO, &
                     1,nEl)
    elid = 1
    DO jel = 1,nElem(2)
      DO iel = 1,nElem(1)
        ! x component
        xLinear % interior % hostData(1,0:1,0,1,elid) = xU(iel:iel + 1)
        xLinear % interior % hostData(1,0:1,1,1,elid) = xU(iel:iel + 1)
        ! y component
        xLinear % interior % hostData(2,0,0:1,1,elid) = yU(jel:jel + 1)
        xLinear % interior % hostData(2,1,0:1,1,elid) = yU(jel:jel + 1)
        ! Incremenent the element ID
        elid = elid + 1
      END DO
    END DO

    CALL xLinear % GridInterp(xGeo,.FALSE.)

    ! Set the element information
    nid = 1
    sid = 0
    elid = 1
    DO jel = 1,nElem(2)
      DO iel = 1,nElem(1)
        myMesh % eleminfo % hostData(1,iel) = selfQuadLinear ! Element Type
        myMesh % eleminfo % hostData(2,iel) = 1 ! Element Zone
        myMesh % eleminfo % hostData(3,iel) = sid ! Side Index Start
        sid = sid+4
        myMesh % eleminfo % hostData(4,iel) = sid ! Side Index End
        myMesh % eleminfo % hostData(5,iel) = nid-1 ! Node Index Start
        DO j = 0,nGeo
          DO i = 0,nGeo
            myMesh % nodeCoords % hostData(1:2,nid) = xGeo % interior % hostData(1:2,i,j,1,elid)
            nid = nid + 1
          END DO
        END DO
        myMesh % eleminfo % hostData(6,iel) = nid ! Node Index End
        elid = elid + 1
      END DO
    END DO


    CALL myMesh % UpdateDevice()

    CALL xLinear % Free()
    CALL xGeo % Free()

  END SUBROUTINE UniformBlockMesh_Mesh2D

  SUBROUTINE Init_Mesh3D(myMesh,nGeo,nElem,nSides,nNodes,nBCs)
    IMPLICIT NONE
    CLASS(Mesh3D),INTENT(out) :: myMesh
    INTEGER,INTENT(in) :: nGeo
    INTEGER,INTENT(in) :: nElem
    INTEGER,INTENT(in) :: nSides
    INTEGER,INTENT(in) :: nNodes
    INTEGER,INTENT(in) :: nBCs
    ! Local
    INTEGER :: i,j,k,l

    myMesh % nElem = nElem
    myMesh % nGeo = nGeo
    myMesh % nSides = nSides
    myMesh % nNodes = nNodes
    myMesh % nCornerNodes = 0
    myMesh % nUniqueSides = 0
    myMesh % nUniqueNodes = 0
    myMesh % nBCs = nBCs

    CALL myMesh % elemInfo % Alloc(loBound=(/1,1/), &
                                   upBound=(/6,nElem/))

    CALL myMesh % sideInfo % Alloc(loBound=(/1,1/), &
                                   upBound=(/5,nSides/))

    CALL myMesh % nodeCoords % Alloc(loBound=(/1,1/), &
                                     upBound=(/3,nNodes/))

    CALL myMesh % globalNodeIDs % Alloc(loBound=1, &
                                        upBound=nNodes)

    CALL myMesh % CGNSCornerMap % Alloc(loBound=1, &
                                        upBound=8)

    CALL myMesh % CGNSSideMap % Alloc(loBound=(/1,1/), &
                                      upBound=(/4,6/))

    CALL myMesh % curveNodeMap % Alloc(loBound=(/1,1/), &
                                       upBound=(/3,(nGeo+1)**3/))

    CALL myMesh % curveNodeMapInv % Alloc(loBound=(/0,0,0/), &
                                          upBound=(/nGeo,nGeo,nGeo/))

    CALL myMesh % BCType % Alloc(loBound=(/1,1/), &
                                 upBound=(/4,nBCs/))

    ALLOCATE (myMesh % BCNames(1:nBCs))

    ! Create lookup tables to assist with connectivity generation
    myMesh % CGNSCornerMap % hostData(1) = 1
    myMesh % CGNSCornerMap % hostData(2) = nGeo+1
    myMesh % CGNSCornerMap % hostData(3) = (nGeo+1)**2
    myMesh % CGNSCornerMap % hostData(4) = nGeo*(nGeo+1)+1
    myMesh % CGNSCornerMap % hostData(5) = nGeo*(nGeo+1)**2+1
    myMesh % CGNSCornerMap % hostData(6) = nGeo*(nGeo+1)**2+(nGeo+1)
    myMesh % CGNSCornerMap % hostData(7) = (nGeo+1)**3
    myMesh % CGNSCornerMap % hostData(8) = nGeo*(nGeo+1)*(nGeo+2)+1

    DO k = 0, nGeo
      DO j = 0, nGeo
        DO i = 0, nGeo
          l = l+1
          myMesh % curveNodeMap % hostData(1:3,l) = (/i,j,k/)
          myMesh % curveNodeMapInv % hostData(i,j,k) = l
        ENDDO
      ENDDO
    ENDDO

    ! Maps from local corner node id to CGNS side
    myMesh % CGNSSideMap % hostData(1:4,1) = (/1,4,3,2/)
    myMesh % CGNSSideMap % hostData(1:4,2) = (/1,2,6,5/)
    myMesh % CGNSSideMap % hostData(1:4,3) = (/2,3,7,6/)
    myMesh % CGNSSideMap % hostData(1:4,4) = (/3,4,8,7/)
    myMesh % CGNSSideMap % hostData(1:4,5) = (/1,5,8,4/)
    myMesh % CGNSSideMap % hostData(1:4,6) = (/5,6,7,8/)

  END SUBROUTINE Init_Mesh3D

  SUBROUTINE Free_Mesh3D(myMesh)
    IMPLICIT NONE
    CLASS(Mesh3D),INTENT(inout) :: myMesh

    myMesh % nElem = 0
    myMesh % nSides = 0
    myMesh % nNodes = 0
    myMesh % nCornerNodes = 0
    myMesh % nUniqueSides = 0
    myMesh % nUniqueNodes = 0
    myMesh % nBCs = 0

    CALL myMesh % elemInfo % Free()
    CALL myMesh % sideInfo % Free()
    CALL myMesh % nodeCoords % Free()
    CALL myMesh % CGNSCornerMap % Free()
    CALL myMesh % globalNodeIDs % Free()
    CALL myMesh % BCType % Free()

    DEALLOCATE (myMesh % BCNames)

  END SUBROUTINE Free_Mesh3D
  SUBROUTINE UpdateHost_Mesh3D(myMesh)
    IMPLICIT NONE
    CLASS(Mesh3D),INTENT(inout) :: myMesh

#ifdef GPU
    CALL myMesh % elemInfo % UpdateHost()
    CALL myMesh % sideInfo % UpdateHost()
    CALL myMesh % nodeCoords % UpdateHost()
    CALL myMesh % globalNodeIDs % UpdateHost()
    CALL myMesh % BCType % UpdateHost()
#endif

  END SUBROUTINE UpdateHost_Mesh3D

  SUBROUTINE UpdateDevice_Mesh3D(myMesh)
    IMPLICIT NONE
    CLASS(Mesh3D),INTENT(inout) :: myMesh

#ifdef GPU
    CALL myMesh % elemInfo % UpdateDevice()
    CALL myMesh % sideInfo % UpdateDevice()
    CALL myMesh % nodeCoords % UpdateDevice()
    CALL myMesh % globalNodeIDs % UpdateDevice()
    CALL myMesh % BCType % UpdateDevice()
#endif

  END SUBROUTINE UpdateDevice_Mesh3D

  SUBROUTINE UniformBlockMesh_Mesh3D(myMesh,nGeo,nElem,x)
    IMPLICIT NONE
    CLASS(Mesh3D),INTENT(out) :: myMesh
    INTEGER,INTENT(in) :: nGeo
    INTEGER,INTENT(in) :: nElem(1:3)
    REAL(prec),INTENT(in) :: x(1:6)
    ! Local
    INTEGER :: iel,jel,kel,nEl,elid
    INTEGER :: sid,nid,nNodes
    INTEGER :: nSides
    INTEGER :: i,j,k
    REAL(prec) :: xU(1:nElem(1) + 1)
    REAL(prec) :: yU(1:nElem(2) + 1)
    REAL(prec) :: zU(1:nElem(3) + 1)
    TYPE(Vector3D) :: xLinear
    TYPE(Vector3D) :: xGeo

    nEl = nElem(1)*nElem(2)*nElem(3)
    nNodes = nel*(nGeo + 1)*(nGeo + 1)*(nGeo + 1)
    nSides = (nElem(1) + 1)*nElem(2)*nElem(3) + &
             (nElem(2) + 1)*nElem(1)*nElem(3) + &
             (nElem(3) + 1)*nElem(1)*nElem(2)
    CALL myMesh % Init(nGeo,nEl,nSides,nNodes,1)

    ! Set the nodeCoords
    xU = UniformPoints(x(1),x(2),1,nElem(1) + 1)
    yU = UniformPoints(x(3),x(4),1,nElem(2) + 1)
    zU = UniformPoints(x(5),x(6),1,nElem(3) + 1)

    ! Create a linear interpolant to interpolate to nGeo grid
    CALL xLinear % Init(1,GAUSS_LOBATTO, &
                        nGeo,GAUSS_LOBATTO, &
                        1,nEl)

    CALL xGeo % Init(nGeo,GAUSS_LOBATTO, &
                     nGeo,GAUSS_LOBATTO, &
                     1,nEl)
    elid = 1
    DO kel = 1,nElem(3)
      DO jel = 1,nElem(2)
        DO iel = 1,nElem(1)
          ! x component
          xLinear % interior % hostData(1,0:1,0,0,1,elid) = xU(iel:iel + 1)
          xLinear % interior % hostData(1,0:1,1,0,1,elid) = xU(iel:iel + 1)
          xLinear % interior % hostData(1,0:1,0,1,1,elid) = xU(iel:iel + 1)
          xLinear % interior % hostData(1,0:1,1,1,1,elid) = xU(iel:iel + 1)
          ! y component
          xLinear % interior % hostData(2,0,0:1,0,1,elid) = yU(jel:jel + 1)
          xLinear % interior % hostData(2,1,0:1,0,1,elid) = yU(jel:jel + 1)
          xLinear % interior % hostData(2,0,0:1,1,1,elid) = yU(jel:jel + 1)
          xLinear % interior % hostData(2,1,0:1,1,1,elid) = yU(jel:jel + 1)
          ! z component
          xLinear % interior % hostData(3,0,0,0:1,1,elid) = zU(kel:kel + 1)
          xLinear % interior % hostData(3,1,0,0:1,1,elid) = zU(kel:kel + 1)
          xLinear % interior % hostData(3,0,1,0:1,1,elid) = zU(kel:kel + 1)
          xLinear % interior % hostData(3,1,1,0:1,1,elid) = zU(kel:kel + 1)
          ! Incremenent the element ID
          elid = elid + 1
        END DO
      END DO
    END DO

    CALL xLinear % GridInterp(xGeo,.FALSE.)

    ! Set the element information
    nid = 1
    sid = 0
    elid = 1
    DO kel = 1,nElem(3)
      DO jel = 1,nElem(2)
        DO iel = 1,nElem(1)
          myMesh % eleminfo % hostData(1,iel) = selfQuadLinear ! Element Type
          myMesh % eleminfo % hostData(2,iel) = 1 ! Element Zone
          myMesh % eleminfo % hostData(3,iel) = sid ! Side Index Start
          sid = sid + 6
          myMesh % eleminfo % hostData(4,iel) = sid ! Side Index End
          myMesh % eleminfo % hostData(5,iel) = nid-1 ! Node Index Start
          DO k = 0,nGeo
            DO j = 0,nGeo
              DO i = 0,nGeo
                myMesh % nodeCoords % hostData(1:3,nid) = xGeo % interior % hostData(1:3,i,j,k,1,elid)
                nid = nid + 1
              END DO
            END DO
          END DO
          myMesh % eleminfo % hostData(6,iel) = nid ! Node Index End
          elid = elid + 1
        END DO
      END DO
    END DO

    ! TO DO: Add Side information !

    CALL myMesh % UpdateDevice()

    CALL xLinear % Free()
    CALL xGeo % Free()

  END SUBROUTINE UniformBlockMesh_Mesh3D

END MODULE SELF_Mesh
