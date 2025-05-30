!> @brief   Apply selected basis set library to the molecule
!> @details This module extracts the information about basis set from the library file.
!>               The library should be in GAMESS(US) basis set format. Then, it applies the selected
!>               basis to all atoms in the molecule.
!> @param infos(in,out)     Molecule information
!> @param abas(in)      [R] Basis set library file, GAMESS(US) format
module apply_basis_mod

  character(len=*), parameter :: module_name = "apply_basis_mod"

contains

  subroutine apply_basis_C(c_handle) bind(C, name="apply_basis")
    use c_interop, only: oqp_handle_t, oqp_handle_get_info
    use types, only: information
    type(oqp_handle_t) :: c_handle
    type(information), pointer :: inf
    inf => oqp_handle_get_info(c_handle)
    call oqp_apply_basis(inf)
  end subroutine apply_basis_C

  subroutine oqp_apply_basis(infos)
    use messages, only: with_abort
    use types, only: information
    use atomic_structure_m, only: atomic_structure
    use strings, only: fstring
    use oqp_tagarray_driver
    use iso_c_binding, only: c_char
    use parallel, only: par_env_t
    use basis_api, only: map_shell2basis_set, print_basis

    implicit none
    type(information), intent(inout) :: infos
    type(par_env_t) :: pe
    character(len=:), allocatable :: basis_file
    integer :: iw, i
    logical :: err
  !
  ! Section of Tagarray for the basis filename
  ! We are getting basis file name from Python via tagarray
  !
    character(len=1,kind=c_char), contiguous, pointer :: basis_filename(:)
    character(len=*), parameter :: subroutine_name = "oqp_apply_basis"
    character(len=*), parameter :: tags_general(1) = (/ character(len=80) :: &
          OQP_basis_filename /)
    call data_has_tags(infos%dat, tags_general, module_name, subroutine_name, with_abort)
    call tagarray_get_data(infos%dat, OQP_basis_filename, basis_filename)
    allocate(character(ubound(basis_filename,1)) :: basis_file)
    do i = 1, ubound(basis_filename,1)
       basis_file(i:i) = basis_filename(i)
    end do
!
!  ! Files open
!  ! 3. LOG: Write: Main output file
!  ! 5. BAS: read: Basis set library (internally)
!
    open (newunit=iw, file=infos%log_filename, position="append")
   !
    write(iw,'(/,20x,"++++++++++++++++++++++++++++++++++++++++")')
    write(iw,'(  22X,"MODULE: apply_basis ")')
    write(iw,'(  22X,"Setting up basis set information")')
    write(iw,'(20x,"++++++++++++++++++++++++++++++++++++++++")')
    call pe%init(infos%mpiinfo%comm, infos%mpiinfo%usempi)
    call map_shell2basis_set(infos)
!    if (pe%rank == 0) then
!      call infos%basis%from_file(basis_file, infos%atoms, err)
!      infos%control%basis_set_issue = err
!    endif

!    call infos%basis%basis_broadcast(infos%mpiinfo%comm, infos%mpiinfo%usempi)

    if (sum(infos%basis%ecp_zn_num)>0) then
      call pe%bcast(infos%mol_prop%nelec, 1)
      call pe%bcast(infos%mol_prop%nelec_A, 1)
      call pe%bcast(infos%mol_prop%nelec_B, 1)
      call pe%bcast(infos%mol_prop%nocc, 1)
    end if

! Checking error of basis set reading..
!    call pe%bcast(infos%control%basis_set_issue, 1)

    if (infos%control%active_basis == 0) then
      write(iw,'(/5X,"Basis Sets options"/&
                    &5X,18("-")/&
                    &5X,"Basis Sets: ",A/&
                    &5X,"Number of Shells  =",I8,5X,"Number of Primitives  =",I8/&
                    &5X,"Number of Basis Set functions  =",I8/&
                    &5X,"Maximum Angluar Momentum =",I8/)') &
                      trim(basis_file), &
                      infos%basis%nshell, infos%basis%nprim, &
                      infos%basis%nbf, infos%basis%mxam
    else
      write(iw,'(/5X,"Alternative Basis Set Options"/&
                    &5X,18("-")/&
                    &5X,"Basis Sets: ",A/&
                    &5X,"Number of Shells  =",I8,5X,"Number of Primitives  =",I8/&
                    &5X,"Number of Basis Set functions  =",I8/&
                    &5X,"Maximum Angluar Momentum =",I8/)') &
                      trim(basis_file), &
                      infos%alt_basis%nshell, infos%alt_basis%nprim, &
                      infos%alt_basis%nbf, infos%alt_basis%mxam
    endif
    close (iw)

    call print_basis(infos)


  end subroutine oqp_apply_basis

end module apply_basis_mod
