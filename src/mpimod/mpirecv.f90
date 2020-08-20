submodule (mpimod) mpirecv

implicit none !(type, external)

contains

module procedure gather_recv2D_23
!! THIS SUBROUTINE GATHERS DATA FROM ALL WORKERS ONTO
!! A FULL-GRID ARRAY ON THE ROOT PROCESS (PRESUMABLY FOR
!! OUTPUT OR SOME ELECTRODYNAMIC CALCULATION, PERHAPS.
!!
!! THIS SUBROUTINE IS TO BE CALLED BY ROOT TO DO GATHER
!!
!! THIS VERSION WORKS ON 2D ARRAYS WHICH DO NOT INCLUDE ANY GHOST CELLS!!!!

integer :: ierr
integer :: lx1,lx2,lx3,lsp,lx2all,lx3all
integer :: iid
integer, dimension(4) :: inds
real(wp), dimension(1:size(paramtrim,1),1:size(paramtrim,2)) :: paramtmp

lx2=size(paramtrim,1)    !note here that paramtrim does not have ghost cells
lx3=size(paramtrim,2)


!PATCH DATA TOGETHER FOR OUTPUT STARTING WITH ROOT'S SLAB
paramtrimall(1:lx2,1:lx3)=paramtrim   !copy root's data into full-grid array

do iid=1,lid-1
  call mpi_recv(paramtmp,lx2*lx3, &
                mpi_realprec,iid,tag,MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)
  inds=slabinds(iid,lx2,lx3)
  paramtrimall(inds(1):inds(2),inds(3):inds(4))=paramtmp    !note the exclusion of the ghost cells
end do

end procedure gather_recv2D_23


module procedure gather_recv3D_23

!! THIS SUBROUTINE GATHERS DATA FROM ALL WORKERS ONTO
!! A FULL-GRID ARRAY ON THE ROOT PROCESS (PRESUMABLY FOR
!! OUTPUT OR SOME ELECTRODYNAMIC CALCULATION, PERHAPS.
!!
!! THIS SUBROUTINE IS TO BE CALLED BY ROOT TO DO GATHER
!!
!! THIS VERSION WORKS ON 3D ARRAYS WHICH DO NOT INCLUDE
!! ANY GHOST CELLS!!!!
!! THIS VERION ALSO WORKS ON A PROCESS GRID

integer :: ierr
integer :: lx1,lx2,lx3,lx2all,lx3all
integer :: iid
integer, dimension(4) :: inds
real(wp), dimension(1:size(paramtrim,1),1:size(paramtrim,2),1:size(paramtrim,3)) :: paramtmp
!! buffer space for mpi receive, includes only x1 ghost cells


lx1=size(paramtrim,1)
lx2=size(paramtrim,2)
lx3=size(paramtrim,3)


!Originally the outer loop was over worker number, which cycles the 3rd dimension
!slower than 4th (backward from what would be most efficient memory access pattern)
!Since the gathering operation is root-limited probably, I'm guessing it's better
!to give root an efficient memory access pattern here, but I haven't tested this
!theory.
paramtrimall(:,1:lx2,1:lx3)=paramtrim(:,1:lx2,1:lx3)    !store root's piece of data
do iid=1,lid-1        !must loop over all processes in the grid, don't enter loop if only root is present
  call mpi_recv(paramtmp,lx1*lx2*lx3, &          !note no ghost cells!!!
                mpi_realprec,iid,tag,MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)    !recieve chunk of data into buffer
  inds=slabinds(iid,lx2,lx3)
  paramtrimall(1:lx1,inds(1):inds(2),inds(3):inds(4))=paramtmp    !note the exclusion of the ghost cells
end do

end procedure gather_recv3D_23


module procedure gather_recv4D_23

!------------------------------------------------------------
!-------THIS SUBROUTINE GATHERS DATA FROM ALL WORKERS ONTO
!-------A FULL-GRID ARRAY ON THE ROOT PROCESS (PRESUMABLY FOR
!-------OUTPUT OR SOME ELECTRODYNAMIC CALCULATION, PERHAPS.
!-------
!-------THIS SUBROUTINE IS TO BE CALLED BY ROOT TO DO GATHER
!-------
!-------THIS VERSION WORKS ON 4D ARRAYS WHICH INCLUDE
!-------GHOST CELLS!
!------------------------------------------------------------

integer :: ierr
integer :: lx1,lx2,lx3,isp,lx2all,lx3all
integer :: iid
integer, dimension(4) :: inds
real(wp), dimension(-1:size(param,1)-2,1:size(param,2)-4,1:size(param,3)-4) :: paramtmp
!! buffer space for mpi receive, includes only x1 ghost cells


lx1=size(param,1)-4
lx2=size(param,2)-4
lx3=size(param,3)-4

!Originally the outer loop was over worker number, which cycles the 3rd dimension
!slower than 4th (backward from what would be most efficient memory access pattern)
!Since the gathering operation is root-limited probably, I'm guessing it's better
!to give root an efficient memory access pattern here, but I haven't tested this
!theory.
do isp=1,lsp
  paramall(-1:lx1+2,1:lx2,1:lx3,isp)=param(-1:lx1+2,1:lx2,1:lx3,isp)
  !! root records his own piece of the grid into full grid variable

  do iid=1,lid-1        !must loop over all processes in the grid, don't enter loop if only root is present
    call mpi_recv(paramtmp,(lx1+4)*lx2*lx3, &
                  mpi_realprec,iid,tag,MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)    !recieve chunk of data into buffer
    inds=slabinds(iid,lx2,lx3)
    paramall(-1:lx1+2,inds(1):inds(2),inds(3):inds(4),isp)=paramtmp(-1:lx1+2,1:lx2,1:lx3)    !note the inclusion of x1 ghost cells
  end do
end do

end procedure gather_recv4D_23


module procedure bcast_recv1D_old3
!! THIS SUBROUTINE RECEIVES BROADCAST DATA FROM A FULL
!! GRID ARRAY ON ROOT PROCESS TO WORKERS' SUB-GRID ARRAYS.
!!
!! SUBROUTINE IS TO BE CALLED BY WORKERS TO DO A BROADCAST
!!
!! THIS VERSION WORKS ON 1D ARRAYS WHICH DO NOT INCLUDE
!! GHOST CELLS!

integer :: ierr
integer :: lx


lx=size(param,1)-4

!> WORKERS RECEIVE THE IC DATA FROM ROOT
call mpi_recv(param,(lx+4), &
  mpi_realprec,0,tag,MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)

end procedure bcast_recv1D_old3


module procedure bcast_recv1D_23_2
!! THIS SUBROUTINE RECEIVES BROADCAST DATA FROM A FULL
!! GRID ARRAY ON ROOT PROCESS TO WORKERS' SUB-GRID ARRAYS.
!!
!! SUBROUTINE IS TO BE CALLED BY WORKERS TO DO A BROADCAST
!!
!! THIS VERSION WORKS ON 1D ARRAYS WHICH DO NOT INCLUDE
!! GHOST CELLS!

integer :: ierr
integer :: lx
integer :: iid


lx=size(param,1)-4

!> WORKERS RECEIVE THE IC DATA FROM ROOT
call mpi_recv(param,(lx+4), &
  mpi_realprec,0,tag,MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)

end procedure bcast_recv1D_23_2


module procedure bcast_recv1D_23_3
!! THIS SUBROUTINE RECEIVES BROADCAST DATA FROM A FULL
!! GRID ARRAY ON ROOT PROCESS TO WORKERS' SUB-GRID ARRAYS.
!!
!! SUBROUTINE IS TO BE CALLED BY WORKERS TO DO A BROADCAST
!!
!! THIS VERSION WORKS ON 1D ARRAYS WHICH DO NOT INCLUDE
!! GHOST CELLS!

integer :: ierr
integer :: lx


lx=size(param,1)-4

!> WORKERS RECEIVE THE IC DATA FROM ROOT
call mpi_recv(param,(lx+4), &
  mpi_realprec,0,tag,MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)

end procedure bcast_recv1D_23_3


module procedure bcast_recv2D_23
!! THIS SUBROUTINE RECEIVES BROADCAST DATA FROM A FULL
!! GRID ARRAY ON ROOT PROCESS TO WORKERS' SUB-GRID ARRAYS.
!!
!! SUBROUTINE IS TO BE CALLED BY WORKERS TO DO A BROADCAST
!!
!! THIS VERSION WORKS ON 3D ARRAYS WHICH DO NOT INCLUDE
!! GHOST CELLS!

integer :: ierr
integer :: lx2,lx3

lx2=size(paramtrim,1)
lx3=size(paramtrim,2)


!> WORKERS RECEIVE THE IC DATA FROM ROOT
call mpi_recv(paramtrim,lx2*lx3, &
  mpi_realprec,0,tag,MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)

end procedure bcast_recv2D_23


module procedure bcast_recv3D_23
!! THIS SUBROUTINE RECEIVES BROADCAST DATA FROM A FULL
!! GRID ARRAY ON ROOT PROCESS TO WORKERS' SUB-GRID ARRAYS.
!!
!! SUBROUTINE IS TO BE CALLED BY WORKERS TO DO A BROADCAST
!!
!! THIS VERSION WORKS ON 3D ARRAYS WHICH DO NOT INCLUDE
!! GHOST CELLS!

integer :: ierr
integer :: lx1,lx2,lx3

!> note here that paramtrim does not have ghost cells
lx1=size(paramtrim,1)
lx2=size(paramtrim,2)
lx3=size(paramtrim,3)


!> WORKERS RECEIVE THE IC DATA FROM ROOT
call mpi_recv(paramtrim,lx1*lx2*lx3, &
               mpi_realprec,0,tag,MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)

end procedure bcast_recv3D_23


module procedure bcast_recv3D_x3i_23
!! THIS SUBROUTINE RECEIVES BROADCAST DATA FROM A FULL
!! GRID ARRAY ON ROOT PROCESS TO WORKERS' SUB-GRID ARRAYS.
!!
!! SUBROUTINE IS TO BE CALLED BY WORKERS TO DO A BROADCAST
!!
!! THIS VERSION WORKS ON 3D ARRAYS WHICH DO NOT INCLUDE
!! GHOST CELLS!

integer :: ierr
integer :: lx1,lx2,lx3

!>note here that paramtrim does not have ghost cells
lx1=size(paramtrim,1)
lx2=size(paramtrim,2)
lx3=size(paramtrim,3)-1  ! `lx3` is an interfaced quantity

!> WORKERS RECEIVE THE IC DATA FROM ROOT
call mpi_recv(paramtrim,lx1*lx2*(lx3+1), &
               mpi_realprec,0,tag,MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)

end procedure bcast_recv3D_x3i_23


module procedure bcast_recv3D_x2i_23
!! THIS SUBROUTINE RECEIVES BROADCAST DATA FROM A FULL
!! GRID ARRAY ON ROOT PROCESS TO WORKERS' SUB-GRID ARRAYS.
!!
!! SUBROUTINE IS TO BE CALLED BY WORKERS TO DO A BROADCAST
!!
!! THIS VERSION WORKS ON 3D ARRAYS WHICH DO NOT INCLUDE
!! GHOST CELLS!

integer :: ierr
integer :: lx1,lx2,lx3
integer :: iid

!>note here that paramtrim does not have ghost cells
lx1=size(paramtrim,1)
lx2=size(paramtrim,2)-1    !x2 is the interfaced direction here
lx3=size(paramtrim,3)

!> WORKERS RECEIVE THE IC DATA FROM ROOT
call mpi_recv(paramtrim,lx1*(lx2+1)*lx3, &
               mpi_realprec,0,tag,MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)

end procedure bcast_recv3D_x2i_23


module procedure bcast_recv3D_ghost_23
!! THIS SUBROUTINE RECEIVES BROADCAST DATA FROM A FULL
!! GRID ARRAY ON ROOT PROCESS TO WORKERS' SUB-GRID ARRAYS.
!!
!! SUBROUTINE IS TO BE CALLED BY WORKERS TO DO A BROADCAST
!!
!! THIS VERSION WORKS ON 3D ARRAYS WHICH DO NOT INCLUDE
!! GHOST CELLS!

integer :: ierr
integer :: lx1,lx2,lx3

!> note here that param has ghost cells
lx1=size(param,1)-4
lx2=size(param,2)-4
lx3=size(param,3)-4


!> WORKERS RECEIVE THE IC DATA FROM ROOT
call mpi_recv(param,(lx1+4)*(lx2+4)*(lx3+4), &
               mpi_realprec,0,tag,MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)

end procedure bcast_recv3D_ghost_23



module procedure bcast_recv4D_23
!! THIS SUBROUTINE RECEIVES BROADCAST DATA FROM A FULL
!! GRID ARRAY ON ROOT PROCESS TO WORKERS' SUB-GRID ARRAYS.
!-------
!-------SUBROUTINE IS TO BE CALLED BY WORKERS TO DO A BROADCAST
!-------
!-------THIS VERSION WORKS ON 4D ARRAYS WHICH INCLUDE
!-------GHOST CELLS!
!------------------------------------------------------------

integer :: ierr
integer :: lx1,lx2,lx3,isp
real(wp), dimension(-1:size(param,1)-2,1:size(param,2)-4,1:size(param,3)-4) :: paramtmp

lx1=size(param,1)-4
lx2=size(param,2)-4
lx3=size(param,3)-4


!WORKERS RECEIVE THE IC DATA FROM ROOT
do isp=1,lsp
  call mpi_recv(paramtmp,(lx1+4)*lx2*lx3, &
                 mpi_realprec,0,tag,MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)
  param(-1:lx1+2,1:lx2,1:lx3,isp)=paramtmp(-1:lx1+2,1:lx2,1:lx3)
end do

end procedure bcast_recv4D_23



end submodule mpirecv
